-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local DungeonAction = Network:WaitForChild("DungeonAction")
local DungeonUpdate = Network:WaitForChild("DungeonUpdate")

local ActiveDungeons = {}

local EndlessPool = {}
for p = 1, 6 do
	if EnemyData.Parts[p] then
		if EnemyData.Parts[p].Templates then for _, t in pairs(EnemyData.Parts[p].Templates) do table.insert(EndlessPool, t) end end
		if EnemyData.Parts[p].Mobs then for _, m in pairs(EnemyData.Parts[p].Mobs) do table.insert(EndlessPool, m) end end
	end
end

local function GenerateDungeonEnemy(template, dungeonId)
	local fixedPrestige = tonumber(dungeonId) and (tonumber(dungeonId) + 4) or 5
	local scaleMult = 1 + (fixedPrestige * 0.15)
	local minorScaleMult = 1 + ((scaleMult - 1) * 0.33) 

	local eHP = template.Health * scaleMult
	local eStr = (template.Strength + (GameData.StandRanks[template.StandStats.Power] or 0)) * scaleMult
	local eDef = (template.Defense + (GameData.StandRanks[template.StandStats.Durability] or 0)) * scaleMult
	local eSpd = (template.Speed + (GameData.StandRanks[template.StandStats.Speed] or 0)) * minorScaleMult

	local dYen = math.floor((template.Drops and template.Drops.Yen or 0) * scaleMult)
	local dXP = math.floor((template.Drops and template.Drops.XP or 0) * scaleMult)

	return {
		IsPlayer = false, Name = template.Name, Trait = "None",
		IsBoss = template.IsBoss or false,
		HP = eHP, MaxHP = eHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd,
		TotalWillpower = (template.Willpower or 1) * minorScaleMult,
		TotalRange = (GameData.StandRanks[template.StandStats.Range] or 0),
		TotalPrecision = (GameData.StandRanks[template.StandStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {}, Skills = template.Skills or {"Basic Attack"},
		RawDrops = { Yen = dYen, XP = dXP, ItemChance = template.Drops and template.Drops.ItemChance or {} }
	}
end

local function GenerateRandomEndlessEnemy(floor)
	local FirstNames = {"Crazed", "Menacing", "Wandering", "Furious", "Stoic", "Bizarre", "Ruthless", "Phantom", "Savage", "Silent"}
	local LastNames = {"Thug", "Brawler", "Stand User", "Delinquent", "Fighter", "Vampire", "Warrior", "Assassin", "Mercenary"}
	local Styles = {"Boxing", "Hamon", "Vampirism", "Pillarman", "Cyborg", "None"}

	local isBossFloor = (floor % 10 == 0)
	local eName = FirstNames[math.random(#FirstNames)] .. " " .. LastNames[math.random(#LastNames)]
	if isBossFloor then eName = "Floor " .. floor .. " Guardian" end

	local hasStand = math.random(1, 100) <= 70
	local eStand = hasStand and StandData.RollStand() or "None"
	local eTrait = hasStand and StandData.RollTrait() or "None"
	local eStyle = Styles[math.random(#Styles)]

	local standardScale = (math.floor(1 + (floor/10))) * 0.5
	local utilityScale = (math.floor(1 + (floor/10))) * 0.05

	local bHP, bStr, bDef, bSpd, bWill = math.random(250, 2000), math.random(15, 150), math.random(10, 100), math.random(15, 150), math.random(10, 100)
	local standPower, standSpeed, standDur, standRan, standPre = "None", "None", "None", "None", "None"

	if hasStand and StandData.Stands[eStand] then
		local sStats = StandData.Stands[eStand].Stats
		standPower, standSpeed, standDur, standRan, standPre = sStats.Power, sStats.Speed, sStats.Durability, sStats.Range, sStats.Precision
		bStr += GameData.StandRanks[sStats.Power] or 0
		bSpd += GameData.StandRanks[sStats.Speed] or 0
		bDef += GameData.StandRanks[sStats.Durability] or 0
	end

	local bossMult = isBossFloor and 2 or 1
	local eHP = math.floor(bHP + (bHP * standardScale)) * bossMult
	local eStr = math.floor(bStr + (bStr * standardScale)) * bossMult
	local eDef = math.floor(bDef + (bDef * standardScale)) * bossMult
	local eSpd = math.floor(bSpd + (bSpd * utilityScale)) * bossMult
	local finalWill = math.floor(bWill + (bWill * utilityScale)) * bossMult
	local dYen = math.floor((15 + (bHP * 0.1)) * (1 + standardScale)) * bossMult
	local dXP = math.floor((50 + (bHP * 0.4)) * (1 + standardScale)) * bossMult

	local eSkills = {"Basic Attack", "Heavy Strike", "Block"}
	for skillName, skillInfo in pairs(SkillData.Skills) do
		local req = skillInfo.Requirement
		if (req == "AnyStand" and hasStand) or (req == eStand and eStand ~= "None") or (req == eStyle and eStyle ~= "None") then table.insert(eSkills, skillName) end
	end

	local displayTrait = eTrait ~= "None" and " [" .. eTrait .. "]" or ""
	local fullName = eName
	if hasStand then fullName = fullName .. " (" .. eStand .. ")" .. displayTrait end

	return {
		IsPlayer = false, Name = fullName, Trait = eTrait,
		IsBoss = isBossFloor,
		HP = eHP, MaxHP = eHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd, TotalWillpower = finalWill,
		TotalRange = (GameData.StandRanks[standRan] or 0), TotalPrecision = (GameData.StandRanks[standPre] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {}, Skills = eSkills, RawDrops = { Yen = dYen, XP = dXP, ItemChance = {} }
	}
end

local function CompilePartWaves(partId)
	local waves = {}
	local pData = EnemyData.Parts[partId]
	if not pData then return waves end

	if pData.Mobs and #pData.Mobs > 0 then
		for i = 1, 5 do table.insert(waves, pData.Mobs[math.random(1, #pData.Mobs)]) end
	end

	local templateList = {}
	if pData.Templates then for _, t in pairs(pData.Templates) do table.insert(templateList, t) end end
	table.sort(templateList, function(a,b) return (a.Health or 0) < (b.Health or 0) end)
	for _, t in ipairs(templateList) do table.insert(waves, t) end

	return waves
end

local function StartDungeon(player, dungeonId)
	local isEndless = (dungeonId == "Endless")
	local waves = {}
	if not isEndless then
		waves = CompilePartWaves(dungeonId)
		if #waves == 0 then return end
	end

	local hasStand = (player:GetAttribute("Stand") or "None") ~= "None"
	local sPow = hasStand and (player:GetAttribute("Stand_Power_Val") or 0) or 0
	local sDur = hasStand and (player:GetAttribute("Stand_Durability_Val") or 0) or 0
	local sSpd = hasStand and (player:GetAttribute("Stand_Speed_Val") or 0) or 0
	local sPot = hasStand and (player:GetAttribute("Stand_Potential_Val") or 0) or 0
	local sRan = hasStand and (player:GetAttribute("Stand_Range_Val") or 0) or 0
	local sPre = hasStand and (player:GetAttribute("Stand_Precision_Val") or 0) or 0

	local pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
	local pStr = (player:GetAttribute("Strength") or 1) + sPow + CombatCore.GetEquipBonus(player, "Strength") + CombatCore.GetEquipBonus(player, "Stand_Power")
	local pDef = (player:GetAttribute("Defense") or 1) + sDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Stand_Durability")
	local pSpd = (player:GetAttribute("Speed") or 1) + sSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Stand_Speed")
	local pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")

	local playerTrait = player:GetAttribute("StandTrait") or "None"
	if playerTrait == "Tough" then pHP *= 1.1 end
	if playerTrait == "Fierce" then pStr *= 1.1 end
	if playerTrait == "Perseverance" then pHP *= 1.5; pWill *= 1.5 end

	local pStamina = (player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina")
	local pStandEnergy = 10 + sPot + CombatCore.GetEquipBonus(player, "Stand_Potential")

	if playerTrait == "Focused" then
		pStamina *= 1.1; pStandEnergy *= 1.1
	end

	local firstEnemy = isEndless and GenerateRandomEndlessEnemy(1) or GenerateDungeonEnemy(waves[1], dungeonId)
	local activeBoosts = CombatCore.GetPlayerBoosts(player)

	ActiveDungeons[player.UserId] = {
		DungeonId = dungeonId, IsEndless = isEndless, CurrentWave = 1, TotalWaves = isEndless and "8" or #waves, Waves = waves,
		MasterDrops = { Yen = 0, XP = 0, ItemChance = {} }, IsProcessing = false, Boosts = activeBoosts, 
		Player = {
			IsPlayer = true, Name = player.Name, Trait = playerTrait, GlobalDmgBoost = activeBoosts.Damage, PlayerObj = player,
			Stand = player:GetAttribute("Stand") or "None", Style = player:GetAttribute("FightingStyle") or "None",
			HP = pHP * 10, MaxHP = pHP * 10, Stamina = pStamina, MaxStamina = pStamina, StandEnergy = pStandEnergy, MaxStandEnergy = pStandEnergy,
			TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd, TotalWillpower = pWill,
			TotalRange = sRan + CombatCore.GetEquipBonus(player, "Stand_Range"), TotalPrecision = sPre + CombatCore.GetEquipBonus(player, "Stand_Precision"),
			BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0, Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 }, Cooldowns = {}
		},
		Enemy = firstEnemy
	}

	if not isEndless then
		local fixedPrestige = tonumber(dungeonId) and (tonumber(dungeonId) + 4) or 5
		local scaleMult = 1 + (fixedPrestige * 0.15)
		for _, waveTemplate in ipairs(waves) do
			if waveTemplate.Drops then
				ActiveDungeons[player.UserId].MasterDrops.Yen += math.floor((waveTemplate.Drops.Yen or 0) * scaleMult)
				ActiveDungeons[player.UserId].MasterDrops.XP += math.floor((waveTemplate.Drops.XP or 0) * scaleMult)
				if waveTemplate.Drops.ItemChance then
					for item, ch in pairs(waveTemplate.Drops.ItemChance) do ActiveDungeons[player.UserId].MasterDrops.ItemChance[item] = math.min(100, (ActiveDungeons[player.UserId].MasterDrops.ItemChance[item] or 0) + ch) end
				end
			end
		end
	end

	local startMsg = isEndless and "<font color='#FFD700'>Descending into the Endless Dungeon...</font>" or "<font color='#FFD700'>Starting Part " .. dungeonId .. " Gauntlet!</font>"
	local waveStr = isEndless and "Floor 1" or "Wave 1/" .. #waves
	DungeonUpdate:FireClient(player, "Start", { Battle = ActiveDungeons[player.UserId], LogMsg = startMsg, WaveStr = waveStr })
end

DungeonAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "StartDungeon" then StartDungeon(player, actionData); return end

	local dungeon = ActiveDungeons[player.UserId]
	if not dungeon or dungeon.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData
	local skill = SkillData.Skills[skillName]

	if dungeon.IsEndless and skill and skill.Effect == "Flee" then
		return
	end

	if skill and skill.Requirement ~= "None" then
		if skill.Requirement == "AnyStand" then
			if dungeon.Player.Stand == "None" then return end
		elseif skill.Requirement ~= dungeon.Player.Stand and skill.Requirement ~= dungeon.Player.Style then
			return
		end
	end

	if not skill or dungeon.Player.Stamina < (skill.StaminaCost or 0) or dungeon.Player.StandEnergy < (skill.EnergyCost or 0) then return end
	if dungeon.Player.Cooldowns[skillName] and dungeon.Player.Cooldowns[skillName] > 0 then return end

	dungeon.IsProcessing = true
	local waitMultiplier = player:GetAttribute("Has2xBattleSpeed") and 0.6 or 1.2

	local function DispatchStrike(attacker, defender, strikeSkill)
		if not attacker or not defender or attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function() 
			local lColor = attacker.IsPlayer and "#FFFFFF" or "#FF5555"
			local dColor = defender.IsPlayer and "#FFFFFF" or "#FF5555"
			local lName = attacker.IsPlayer and "You" or attacker.Name
			local dName = defender.IsPlayer and "you" or defender.Name
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, "None", lName, dName, lColor, dColor) 
		end)
		if success then
			DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
			task.wait(waitMultiplier)
		end
	end

	local combatants = { dungeon.Player, dungeon.Enemy }
	table.sort(combatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	for _, combatant in ipairs(combatants) do
		if dungeon.Player.HP < 1 or dungeon.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		for sName, sVal in pairs(combatant.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end
		if combatant.StunImmunity and combatant.StunImmunity > 0 then combatant.StunImmunity -= 1 end
		if combatant.ConfusionImmunity and combatant.ConfusionImmunity > 0 then combatant.ConfusionImmunity -= 1 end
		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, "None", DungeonUpdate, player, dungeon, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			if combatant.IsPlayer then
				combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5)
				combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5)
			end
			DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned and cannot move!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = "<font color='#AAAAAA'>You fled the dungeon!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier)
				DungeonUpdate:FireClient(player, "Fled", {Battle = dungeon})
				ActiveDungeons[player.UserId] = nil
				return
			end
			DispatchStrike(dungeon.Player, dungeon.Enemy, skillName)
		else
			local eSkill = CombatCore.ChooseAISkill(combatant)
			DispatchStrike(dungeon.Enemy, dungeon.Player, eSkill)
		end

		if combatant.Statuses.Confusion > 0 then combatant.Statuses.Confusion -= 1 end
	end

	if dungeon.Player.HP < 1 then
		local dropPack = { XP = 0, Yen = 0, Items = {} }
		if dungeon.IsEndless then
			local hs = player:GetAttribute("EndlessHighScore") or 0
			local clearedFloors = dungeon.CurrentWave - 1
			if clearedFloors > hs then player:SetAttribute("EndlessHighScore", clearedFloors) end
			local clearedTens = math.floor(clearedFloors / 10)
			if clearedTens > 0 then
				local bonusArrows = math.random(0, clearedTens)
				if bonusArrows > 0 then
					player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + bonusArrows)
					table.insert(dropPack.Items, "<font color='#55FFFF'>" .. bonusArrows .. "x Bonus Stand Arrow(s)</font>")
				end
			end
		end
		DungeonUpdate:FireClient(player, "Defeat", {Battle = dungeon, Drops = dropPack})
		ActiveDungeons[player.UserId] = nil

	elseif dungeon.Enemy.HP < 1 then
		local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
		if gangEvent then gangEvent:Fire(player:GetAttribute("Gang"), "Dungeons", 1) end

		if dungeon.IsEndless then
			local fXP = math.floor(dungeon.Enemy.RawDrops.XP * dungeon.Boosts.XP)
			local fYen = math.floor(dungeon.Enemy.RawDrops.Yen * dungeon.Boosts.Yen)
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
			player.leaderstats.Yen.Value += fYen

			local droppedItems = {}
			if dungeon.CurrentWave % 10 == 0 then
				player:SetAttribute("RokakakaCount", (player:GetAttribute("RokakakaCount") or 0) + 1)
				table.insert(droppedItems, "<font color='#FF55FF'>[MILESTONE REWARD] Rokakaka</font>")
				player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + 1)
				table.insert(droppedItems, "<font color='#55FFFF'>1x Stand Arrow</font>")
			end

			local hs = player:GetAttribute("EndlessHighScore") or 0
			if dungeon.CurrentWave > hs then player:SetAttribute("EndlessHighScore", dungeon.CurrentWave) end
			local maxMilestone = player:GetAttribute("EndlessMaxMilestone") or 0
			if dungeon.CurrentWave > maxMilestone then player:SetAttribute("EndlessMaxMilestone", dungeon.CurrentWave) end

			dungeon.CurrentWave += 1
			dungeon.Enemy = GenerateRandomEndlessEnemy(dungeon.CurrentWave)
			dungeon.IsProcessing = false

			local descendMsg = "<font color='#FFD700'>Descending to Floor " .. dungeon.CurrentWave .. "...</font>\n<font color='#55FF55'>Gained " .. fXP .. " XP and ¥" .. fYen .. "!</font>"
			if #droppedItems > 0 then descendMsg = descendMsg .. "\n<font color='#FFFF55'>Loot Secured: " .. table.concat(droppedItems, ", ") .. "</font>" end
			DungeonUpdate:FireClient(player, "WaveComplete", { Battle = dungeon, LogMsg = descendMsg, WaveStr = "Floor " .. dungeon.CurrentWave })
			return
		else
			if dungeon.CurrentWave < dungeon.TotalWaves then
				dungeon.CurrentWave += 1
				local nextTemplate = dungeon.Waves[dungeon.CurrentWave]
				dungeon.Enemy = GenerateDungeonEnemy(nextTemplate, dungeon.DungeonId)
				dungeon.IsProcessing = false
				DungeonUpdate:FireClient(player, "WaveComplete", { Battle = dungeon, LogMsg = "<font color='#FFD700'>A new enemy approaches!</font>", WaveStr = "Wave " .. dungeon.CurrentWave .. "/" .. dungeon.TotalWaves })
				return
			else
				local fXP = math.floor(dungeon.MasterDrops.XP * dungeon.Boosts.XP)
				local fYen = math.floor(dungeon.MasterDrops.Yen * dungeon.Boosts.Yen)
				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
				player.leaderstats.Yen.Value += fYen

				local dropMultiplier = player:GetAttribute("Has2xDropChance") and 2 or 1
				local currentInv = GameData.GetInventoryCount(player)
				local maxInv = GameData.GetMaxInventory(player)
				local droppedItems = {}

				for itemName, chance in pairs(dungeon.MasterDrops.ItemChance) do
					local boostedChance = (chance + dungeon.Boosts.Luck) * dropMultiplier
					if math.random(1, 100) <= boostedChance then
						local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
						local itemRarity = itemData and itemData.Rarity or "Common"
						local isIgnored = (itemName == "Stand Arrow" or itemName == "Rokakaka" or itemName == "Heavenly Stand Disc" or itemName == "Saint's Corpse Part")

						if player:GetAttribute("AutoSell_" .. itemRarity) and not isIgnored then
							local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
							player.leaderstats.Yen.Value += sellVal
							table.insert(droppedItems, itemName .. " <font color='#AAAAAA'>(Auto-Sold: ¥" .. sellVal .. ")</font>")
						else
							if isIgnored then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
								table.insert(droppedItems, itemName)
							elseif currentInv < maxInv then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
								table.insert(droppedItems, itemName)
								currentInv += 1
							else
								Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Inventory Full! " .. itemName .. " was lost.</font>")
							end
						end
					end
				end

				local clearAttr = "DungeonClear_Part" .. dungeon.DungeonId
				if not player:GetAttribute(clearAttr) then
					player:SetAttribute(clearAttr, true)
					player:SetAttribute("RokakakaCount", (player:GetAttribute("RokakakaCount") or 0) + 1)
					table.insert(droppedItems, "<font color='#FF55FF'>[FIRST CLEAR] Rokakaka</font>")
				end

				local finalPack = { XP = fXP, Yen = fYen, Items = droppedItems }
				DungeonUpdate:FireClient(player, "Victory", {Battle = dungeon, Drops = finalPack})
				ActiveDungeons[player.UserId] = nil
			end
		end
	else
		if skill.StaminaCost == 0 then dungeon.Player.Stamina = math.min(dungeon.Player.MaxStamina, dungeon.Player.Stamina + 5) end
		if skill.EnergyCost == 0 then dungeon.Player.StandEnergy = math.min(dungeon.Player.MaxStandEnergy, dungeon.Player.StandEnergy + 5) end
		if dungeon.Player.Trait == "Vigorous" then
			dungeon.Player.Stamina = math.min(dungeon.Player.MaxStamina, dungeon.Player.Stamina + 10)
			dungeon.Player.StandEnergy = math.min(dungeon.Player.MaxStandEnergy, dungeon.Player.StandEnergy + 10)
		end

		dungeon.IsProcessing = false
		DungeonUpdate:FireClient(player, "Update", {Battle = dungeon})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	ActiveDungeons[player.UserId] = nil
end)