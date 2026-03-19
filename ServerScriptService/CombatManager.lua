-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local Network = ReplicatedStorage:WaitForChild("Network")
local CombatAction = Network:WaitForChild("CombatAction")
local CombatUpdate = Network:WaitForChild("CombatUpdate")

local AutoSellToggle = Network:FindFirstChild("AutoSellToggle")
if not AutoSellToggle then
	AutoSellToggle = Instance.new("RemoteEvent")
	AutoSellToggle.Name = "AutoSellToggle"
	AutoSellToggle.Parent = Network
end

local ActiveBattles = {}

AutoSellToggle.OnServerEvent:Connect(function(player, rarity)
	local current = player:GetAttribute("AutoSell_" .. rarity)
	player:SetAttribute("AutoSell_" .. rarity, not current)
end)

local function GetEnemyTemplate(partIndex, templateName)
	local partData = EnemyData.Parts[partIndex]
	if not partData then return nil end
	if partData.Templates and partData.Templates[templateName] then return partData.Templates[templateName] end
	if partData.Mobs then
		for _, mob in ipairs(partData.Mobs) do
			if mob.Name == templateName then return mob end
		end
	end
	return { Name = "Glitch Entity", Health = 10, Strength = 1, Defense = 0, Speed = 1, Willpower = 1, StandStats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}, Skills = {"Basic Attack"}, Drops = { Yen = 0, XP = 0 } }
end

local function GetAllyTemplate(allyName)
	if EnemyData.Allies and EnemyData.Allies[allyName] then return EnemyData.Allies[allyName] end
	for _, partData in pairs(EnemyData.Parts) do
		if partData.Allies and partData.Allies[allyName] then return partData.Allies[allyName] end
		if partData.Templates and partData.Templates[allyName] then return partData.Templates[allyName] end
		if partData.Mobs then
			for _, mob in ipairs(partData.Mobs) do
				if mob.Name == allyName then return mob end
			end
		end
	end
	return { Name = allyName, Health = 150, Strength = 5, Defense = 5, Speed = 5, Willpower = 5, StandStats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}, Skills = {"Basic Attack"}, Drops = { Yen = 0, XP = 0 } }
end

local function GenerateNPCEntity(template, isAlly, prestige, uniModStr, currentPart)
	local scaleHP, scaleStr, scaleDef, scaleSpd, scaleWill, xpScale = 1, 1, 1, 1, 1, 1

	if prestige and prestige > 0 then
		local statMult = (currentPart == 7) and 0.10 or 0.15
		local minorMult = (currentPart == 7) and 0.03 or 0.05 

		local b = 1 + (prestige * statMult)
		local minorB = 1 + (prestige * minorMult) 
		scaleHP = b; scaleStr = b; scaleDef = b; scaleSpd = minorB; scaleWill = minorB

		xpScale = 1 + (prestige * 0.25)
	end

	local yenScale = 1.0
	if CombatCore.HasModifier(uniModStr, "Vampiric Night") then yenScale *= 1.25 end

	if not isAlly then
		if CombatCore.HasModifier(uniModStr, "Wealthy Foes") then yenScale *= 1.5; scaleHP *= 1.25 end
		if CombatCore.HasModifier(uniModStr, "Experience Surge") then xpScale *= 1.5; scaleStr *= 1.25 end
	end

	local scaledDrops = {
		XP = math.floor((template.Drops and template.Drops.XP or 0) * xpScale),
		Yen = math.floor((template.Drops and template.Drops.Yen or 0) * yenScale), 
		ItemChance = template.Drops and template.Drops.ItemChance or {}
	}

	local sStats = template.StandStats or {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}

	return {
		IsPlayer = false, IsAlly = isAlly, Name = template.Name, Trait = "None",
		IsBoss = template.IsBoss or false,
		HP = template.Health * scaleHP, MaxHP = template.Health * scaleHP,
		TotalStrength = (template.Strength + (GameData.StandRanks[sStats.Power] or 0)) * scaleStr,
		TotalDefense = (template.Defense + (GameData.StandRanks[sStats.Durability] or 0)) * scaleDef,
		TotalSpeed = (template.Speed + (GameData.StandRanks[sStats.Speed] or 0)) * scaleSpd,
		TotalWillpower = (template.Willpower or 1) * scaleWill,
		TotalRange = (GameData.StandRanks[sStats.Range] or 0),
		TotalPrecision = (GameData.StandRanks[sStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {},
		Skills = template.Skills or {"Basic Attack"},
		ScaledDrops = scaledDrops
	}
end

local function StartBattle(player, encounterType)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	local partData = EnemyData.Parts[currentPart]
	if not partData then return end

	local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:WaitForChild("Prestige", 5)
	local prestige = prestigeObj and prestigeObj.Value or 0
	local uniModStr = player:GetAttribute("UniverseModifier") or "None"

	local enemyTemplate, allyTemplate = nil, nil
	local battleContext = { IsStoryMission = false, MissionIndex = 0, CurrentWave = 1, TotalWaves = 1, MissionData = nil }
	local initialLogMsg = ""

	if encounterType == "Random" then
		local isTutorial = (player:GetAttribute("TutorialStep") or 0) == 0

		if isTutorial and currentPart == 1 then
			for _, mob in ipairs(partData.Mobs) do
				if mob.Name == "Street Thug" then
					enemyTemplate = mob
					break
				end
			end
			if not enemyTemplate then enemyTemplate = partData.Mobs[1] end 
		else
			enemyTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		end

		local flavorPool = partData.RandomFlavor or {"You encounter a %s!"}
		initialLogMsg = string.format(flavorPool[math.random(1, #flavorPool)], enemyTemplate.Name)
	elseif encounterType == "Story" then
		local currentMission = player:GetAttribute("CurrentMission") or 1
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		local totalMissions = missionTable and #missionTable or 1

		if currentMission > totalMissions then 
			currentMission = 1; player:SetAttribute("CurrentMission", 1)
		end

		local missionData = missionTable[currentMission]
		if not missionData then return end

		battleContext.IsStoryMission = true; battleContext.MissionIndex = currentMission
		battleContext.MissionData = missionData; battleContext.TotalWaves = #missionData.Waves

		local firstWave = missionData.Waves[1]
		enemyTemplate = GetEnemyTemplate(currentPart, firstWave.Template)
		if firstWave.Ally then allyTemplate = GetAllyTemplate(firstWave.Ally) end

		initialLogMsg = "<font color='#FFD700'>[Mission: " .. missionData.Name .. " - Wave 1]</font>\n" .. firstWave.Flavor
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

	if CombatCore.HasModifier(uniModStr, "Endless Stamina") then pHP *= 0.75 end
	if CombatCore.HasModifier(uniModStr, "Heavy Gravity") then pSpd *= 0.75; pStr *= 1.25 end
	if CombatCore.HasModifier(uniModStr, "Glass Cannon") then pStr *= 1.5; pDef *= 0.75 end
	if CombatCore.HasModifier(uniModStr, "Speed of Light") then pSpd *= 1.5 end
	if CombatCore.HasModifier(uniModStr, "Minor Fortitude") then pHP *= 1.1 end
	if CombatCore.HasModifier(uniModStr, "Minor Lethargy") then pHP *= 0.9 end
	if CombatCore.HasModifier(uniModStr, "Brisk Pace") then pSpd *= 1.1 end
	if CombatCore.HasModifier(uniModStr, "Sluggish") then pSpd *= 0.9 end

	local pStamina = (player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina")
	local pStandEnergy = 10 + sPot + CombatCore.GetEquipBonus(player, "Stand_Potential")

	if playerTrait == "Focused" then pStamina *= 1.1; pStandEnergy *= 1.1 end

	local generatedEnemy = GenerateNPCEntity(enemyTemplate, false, prestige, uniModStr, currentPart)
	local activeBoosts = CombatCore.GetPlayerBoosts(player)

	ActiveBattles[player.UserId] = {
		EncounterType = encounterType, Context = battleContext, IsProcessing = false, Boosts = activeBoosts,
		Player = {
			IsPlayer = true, IsAlly = false, Name = player.Name, Trait = playerTrait, GlobalDmgBoost = activeBoosts.Damage, PlayerObj = player,
			Stand = player:GetAttribute("Stand") or "None", Style = player:GetAttribute("FightingStyle") or "None",
			HP = pHP * 10, MaxHP = pHP * 10, Stamina = pStamina, MaxStamina = pStamina, StandEnergy = pStandEnergy, MaxStandEnergy = pStandEnergy,
			TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd, TotalWillpower = pWill,
			TotalRange = sRan + CombatCore.GetEquipBonus(player, "Stand_Range"), TotalPrecision = sPre + CombatCore.GetEquipBonus(player, "Stand_Precision"),
			BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0, Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 }, Cooldowns = {}
		},
		Enemy = generatedEnemy,
		Ally = allyTemplate and GenerateNPCEntity(allyTemplate, true, prestige, uniModStr, currentPart) or nil,
		Drops = generatedEnemy.ScaledDrops, TurnCounter = 1
	}

	CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = initialLogMsg })
end

CombatAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "EngageStory" or actionType == "EngageRandom" then StartBattle(player, actionType == "EngageStory" and "Story" or "Random"); return end

	local battle = ActiveBattles[player.UserId]
	if not battle or battle.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData.SkillName
	local skill = SkillData.Skills[skillName]
	local uniModStr = player:GetAttribute("UniverseModifier") or "None"

	if skill and skill.Requirement ~= "None" then
		if skill.Requirement == "AnyStand" then
			if battle.Player.Stand == "None" then return end
		elseif skill.Requirement ~= battle.Player.Stand and skill.Requirement ~= battle.Player.Style then
			return
		end
	end

	local stamCost, nrgCost = skill.StaminaCost or 0, skill.EnergyCost or 0
	if CombatCore.HasModifier(uniModStr, "Speed of Light") then stamCost *= 1.5; nrgCost *= 1.5 end
	if CombatCore.HasModifier(uniModStr, "Endless Stamina") then stamCost *= 0.5; nrgCost *= 0.5 end

	if not skill or battle.Player.Stamina < stamCost or battle.Player.StandEnergy < nrgCost then return end
	if battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0 then return end

	battle.IsProcessing = true
	local waitMultiplier = player:GetAttribute("Has2xBattleSpeed") and 0.6 or 1.2

	local function DispatchStrike(attacker, defender, strikeSkill)
		if not attacker or not defender or attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function()
			local lColor = attacker.IsPlayer and "#FFFFFF" or (attacker.IsAlly and "#55FFFF" or "#FF5555")
			local dColor = defender.IsPlayer and "#FFFFFF" or "#FF5555"
			local lName = attacker.IsPlayer and "You" or attacker.Name
			local dName = defender.IsPlayer and "you" or defender.Name
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, uniModStr, lName, dName, lColor, dColor)
		end)

		if success then
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
			task.wait(waitMultiplier)
		else warn("Combat Strike Error: ", msg) end
	end

	local combatants = { battle.Player }
	if battle.Ally and battle.Ally.HP > 0 then table.insert(combatants, battle.Ally) end
	if battle.Enemy and battle.Enemy.HP > 0 then table.insert(combatants, battle.Enemy) end
	table.sort(combatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		for sName, sVal in pairs(combatant.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end
		if combatant.StunImmunity and combatant.StunImmunity > 0 then combatant.StunImmunity -= 1 end
		if combatant.ConfusionImmunity and combatant.ConfusionImmunity > 0 then combatant.ConfusionImmunity -= 1 end
		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, uniModStr, CombatUpdate, player, battle, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			if combatant.IsPlayer and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then
				combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5)
				combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5)
			end
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned and cannot move!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>You fled from the battle!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier); CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return
			end
			DispatchStrike(battle.Player, battle.Enemy, skillName)
		elseif combatant.IsAlly then
			local aSkill = CombatCore.ChooseAISkill(combatant)
			DispatchStrike(battle.Ally, battle.Enemy, aSkill)
		else
			local targets = {}
			if battle.Player.HP > 0 then table.insert(targets, battle.Player) end
			if battle.Ally and battle.Ally.HP > 0 then table.insert(targets, battle.Ally) end
			if #targets > 0 then
				local target = targets[math.random(1, #targets)]
				local eSkill = CombatCore.ChooseAISkill(combatant)
				DispatchStrike(battle.Enemy, target, eSkill)
			end
		end

		if combatant.Statuses.Confusion > 0 then combatant.Statuses.Confusion -= 1 end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then
		local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
		if gangEvent then gangEvent:Fire(player:GetAttribute("Gang"), "Kills", 1) end

		local fXP = math.floor(battle.Drops.XP * battle.Boosts.XP)
		local fYen = math.floor(battle.Drops.Yen * battle.Boosts.Yen)
		player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
		player.leaderstats.Yen.Value += fYen

		local dropMultiplier = player:GetAttribute("Has2xDropChance") and 2 or 1
		local currentInv = GameData.GetInventoryCount(player)
		local maxInv = GameData.GetMaxInventory(player)
		local droppedItems = {}

		if (player:GetAttribute("TutorialStep") or 0) == 0 then
			player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + 1)
			table.insert(droppedItems, "Stand Arrow <font color='#FFD700'>(Tutorial Reward)</font>")
		end

		if battle.Drops.ItemChance then
			for itemName, chance in pairs(battle.Drops.ItemChance) do
				local boostedChance = (chance + battle.Boosts.Luck) * dropMultiplier
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
		end

		if battle.Context.IsStoryMission then
			if battle.Context.CurrentWave < battle.Context.TotalWaves then
				battle.Context.CurrentWave += 1
				local nextWaveData = battle.Context.MissionData.Waves[battle.Context.CurrentWave]
				local currentPart = player:GetAttribute("CurrentPart") or 1
				local nextTemplate = GetEnemyTemplate(currentPart, nextWaveData.Template)
				local nextAllyTemplate = nextWaveData.Ally and GetAllyTemplate(nextWaveData.Ally) or nil

				local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:WaitForChild("Prestige", 5)
				local prestige = prestigeObj and prestigeObj.Value or 0

				local newEnemy = GenerateNPCEntity(nextTemplate, false, prestige, uniModStr, currentPart)
				battle.Enemy = newEnemy
				if nextAllyTemplate then battle.Ally = GenerateNPCEntity(nextAllyTemplate, true, prestige, uniModStr, currentPart) end
				battle.Drops = newEnemy.ScaledDrops; battle.TurnCounter = 1; battle.IsProcessing = false

				local waveMsg = "<font color='#FFD700'>[Wave " .. battle.Context.CurrentWave .. "]</font>\n" .. nextWaveData.Flavor
				CombatUpdate:FireClient(player, "WaveComplete", { Battle = battle, LogMsg = waveMsg, XP = fXP, Yen = fYen, Items = droppedItems })
				return
			else
				local currentPart = player:GetAttribute("CurrentPart") or 1
				local partData = EnemyData.Parts[currentPart]
				local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:WaitForChild("Prestige", 5)
				local prestige = prestigeObj and prestigeObj.Value or 0
				local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
				local totalMissions = #missionTable
				local currMission = battle.Context.MissionIndex

				if currMission >= totalMissions then
					if currentPart < 8 then 
						player:SetAttribute("CurrentPart", currentPart + 1)
						player:SetAttribute("CurrentMission", 1)
					end
				else
					player:SetAttribute("CurrentMission", currMission + 1)
				end
			end
		end
		CombatUpdate:FireClient(player, "Victory", {Battle = battle, XP = fXP, Yen = fYen, Items = droppedItems})
		ActiveBattles[player.UserId] = nil
	else
		if stamCost == 0 and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then battle.Player.Stamina = math.min(battle.Player.MaxStamina, battle.Player.Stamina + 5) end
		if nrgCost == 0 and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then battle.Player.StandEnergy = math.min(battle.Player.MaxStandEnergy, battle.Player.StandEnergy + 5) end
		if battle.Player.Trait == "Vigorous" then battle.Player.Stamina = math.min(battle.Player.MaxStamina, battle.Player.Stamina + 10); battle.Player.StandEnergy = math.min(battle.Player.MaxStandEnergy, battle.Player.StandEnergy + 10) end

		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)