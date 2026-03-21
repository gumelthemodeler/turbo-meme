-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatCore = require(script.Parent:WaitForChild("CombatCore"))

local Network = ReplicatedStorage:FindFirstChild("Network") or Instance.new("Folder", ReplicatedStorage)
Network.Name = "Network"

local function GetRemote(name)
	local r = Network:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Network end
	return r
end

local CombatAction = GetRemote("CombatAction")
local CombatUpdate = GetRemote("CombatUpdate")

local ActiveBattles = {}

local function UpdateBountyProgress(plr, taskType, amt)
	for i = 1, 3 do
		if plr:GetAttribute("D"..i.."_Task") == taskType and not plr:GetAttribute("D"..i.."_Claimed") then
			local p = plr:GetAttribute("D"..i.."_Prog") or 0
			local m = plr:GetAttribute("D"..i.."_Max") or 1
			plr:SetAttribute("D"..i.."_Prog", math.min(p + amt, m))
		end
	end
	if plr:GetAttribute("W1_Task") == taskType and not plr:GetAttribute("W1_Claimed") then
		local p = plr:GetAttribute("W1_Prog") or 0
		local m = plr:GetAttribute("W1_Max") or 1
		plr:SetAttribute("W1_Prog", math.min(p + amt, m))
	end
end

local function GetTemplate(partData, templateName)
	if partData.Templates and partData.Templates[templateName] then return partData.Templates[templateName] end
	for _, mob in ipairs(partData.Mobs) do if mob.Name == templateName then return mob end end
	return partData.Mobs[1] 
end

local function GetHPScale(plr)
	local totalStats = (plr:GetAttribute("Strength") or 10) + (plr:GetAttribute("Defense") or 10) + (plr:GetAttribute("Speed") or 10) + (plr:GetAttribute("Resolve") or 10)
	local scale = 1 + ((totalStats - 40) / 400)
	if scale > 15 then scale = 15 + math.sqrt(scale - 15) end 
	return math.max(1, scale)
end
local function GetDmgScale(plr)
	local totalStats = (plr:GetAttribute("Strength") or 10) + (plr:GetAttribute("Defense") or 10) + (plr:GetAttribute("Speed") or 10) + (plr:GetAttribute("Resolve") or 10)
	local scale = 1 + ((totalStats - 40) / 600)
	if scale > 10 then scale = 10 + math.sqrt(scale - 10) end
	return math.max(1, scale)
end

local function GetActualStyle(plr)
	local eqWpn = plr:GetAttribute("EquippedWeapon") or "None"
	if ItemData.Equipment[eqWpn] and ItemData.Equipment[eqWpn].Style then return ItemData.Equipment[eqWpn].Style end
	return "None"
end

local function StartBattle(player, encounterType, requestedPartId)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	local eTemplate, logFlavor
	local isStory = false
	local isEndless = false
	local activeMissionData = nil
	local totalWaves = 1
	local startingWave = 1
	local targetPart = currentPart
	local hpScale = GetHPScale(player)
	local dmgScale = GetDmgScale(player)

	if encounterType == "EngageStory" then
		isStory = true
		targetPart = requestedPartId or currentPart
		if type(targetPart) == "number" and targetPart > currentPart then targetPart = currentPart end

		local partData = EnemyData.Parts[targetPart]
		if not partData then return end

		if targetPart == currentPart then startingWave = player:GetAttribute("CurrentWave") or 1 else startingWave = 1 end

		local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		activeMissionData = missionTable[1]
		totalWaves = #activeMissionData.Waves

		if startingWave > totalWaves then startingWave = totalWaves end
		local waveData = activeMissionData.Waves[startingWave]
		eTemplate = GetTemplate(partData, waveData.Template)
		logFlavor = "<font color='#FFD700'>[Mission: " .. activeMissionData.Name .. "]</font>\n" .. waveData.Flavor

	elseif encounterType == "EngageEndless" then
		isEndless = true
		local maxPart = math.min(7, currentPart)
		local randomPart = math.random(1, maxPart)
		local partData = EnemyData.Parts[randomPart]
		eTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		logFlavor = "<font color='#AA55FF'>[ENDLESS EXPEDITION]</font>\nYou have encountered a " .. eTemplate.Name .. "!"
		hpScale *= 1.2; dmgScale *= 1.2

	elseif encounterType == "EngageWorldBoss" then
		eTemplate = EnemyData.WorldBosses[requestedPartId]
		if not eTemplate then return end
		logFlavor = "<font color='#FFAA00'>[WORLD EVENT]</font>\n" .. eTemplate.Name .. " has appeared!"
		hpScale = 1.0; dmgScale = 1.0
	else
		local partData = EnemyData.Parts[math.min(7, currentPart)]
		eTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		local flavors = partData.RandomFlavor or {"You encounter a %s!"}
		logFlavor = string.format(flavors[math.random(1, #flavors)], eTemplate.Name)
	end

	ActiveBattles[player.UserId] = {
		IsProcessing = false,
		Context = { IsStoryMission = isStory, IsEndless = isEndless, TargetPart = targetPart, CurrentWave = startingWave, TotalWaves = totalWaves, MissionData = activeMissionData },
		Player = {
			IsPlayer = true, Name = player.Name, PlayerObj = player, Titan = player:GetAttribute("Titan") or "None",
			Style = GetActualStyle(player), Clan = player:GetAttribute("Clan") or "None",
			HP = (player:GetAttribute("Health") or 10) * 10, MaxHP = (player:GetAttribute("Health") or 10) * 10,
			TitanEnergy = 100, MaxTitanEnergy = 100, Gas = (player:GetAttribute("Gas") or 10) * 10, MaxGas = (player:GetAttribute("Gas") or 10) * 10,
			TotalStrength = player:GetAttribute("Strength") or 10, TotalDefense = player:GetAttribute("Defense") or 10,
			TotalSpeed = player:GetAttribute("Speed") or 10, TotalResolve = player:GetAttribute("Resolve") or 10,
			Statuses = {}, Cooldowns = {}, LastSkill = "None"
		},
		Enemy = {
			IsPlayer = false, Name = eTemplate.Name,
			HP = math.floor(eTemplate.Health * hpScale), MaxHP = math.floor(eTemplate.Health * hpScale),
			GateType = eTemplate.GateType, GateHP = math.floor((eTemplate.GateHP or 0) * (eTemplate.GateType == "Steam" and 1 or hpScale)), MaxGateHP = math.floor((eTemplate.GateHP or 0) * (eTemplate.GateType == "Steam" and 1 or hpScale)),
			TotalStrength = math.floor(eTemplate.Strength * dmgScale), TotalDefense = math.floor(eTemplate.Defense * dmgScale), TotalSpeed = math.floor(eTemplate.Speed * dmgScale),
			Statuses = {}, Cooldowns = {}, Skills = eTemplate.Skills or {"Brutal Swipe"},
			Drops = { XP = math.floor((eTemplate.Drops and eTemplate.Drops.XP or 10) * hpScale), Dews = math.floor((eTemplate.Drops and eTemplate.Drops.Dews or 5) * hpScale), ItemChance = eTemplate.Drops and eTemplate.Drops.ItemChance or {} },
			LastSkill = "None"
		}
	}
	CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor })
end

CombatAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "EngageRandom" or actionType == "EngageStory" or actionType == "EngageEndless" or actionType == "EngageWorldBoss" then 
		local pId = actionData and (actionData.PartId or actionData.BossId) or nil; StartBattle(player, actionType, pId); return 
	end

	local battle = ActiveBattles[player.UserId]
	if not battle or battle.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData.SkillName
	local skill = SkillData.Skills[skillName]
	if not skill then return end
	if battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0 then return end
	if (battle.Player.TitanEnergy or 0) < (skill.EnergyCost or 0) then return end
	if (battle.Player.Gas or 0) < (skill.GasCost or 0) then return end
	battle.IsProcessing = true

	if skillName == "Maneuver" then UpdateBountyProgress(player, "Maneuver", 1) end
	if skillName == "Transform" then UpdateBountyProgress(player, "Transform", 1) end

	local function DispatchStrike(attacker, defender, strikeSkill)
		if attacker.HP <= 0 or defender.HP <= 0 then return end
		if type(CombatCore.ExecuteStrike) ~= "function" then
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>CRITICAL ERROR: CombatCore.ExecuteStrike is missing.</font>", DidHit = false, ShakeType = "None"}); return
		end

		local success, msg, didHit, shakeType = pcall(function() return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, attacker.IsPlayer and "You" or attacker.Name, defender.IsPlayer and "you" or defender.Name, attacker.IsPlayer and "#FFFFFF" or "#FF5555", defender.IsPlayer and "#FFFFFF" or "#FF5555") end)

		if success then 
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType, SkillUsed = strikeSkill, IsPlayerAttacking = attacker.IsPlayer})
			task.wait(1.2)
		else 
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>SERVER LOGIC ERROR: " .. tostring(msg) .. "</font>", DidHit = false, ShakeType = "None"}) 
		end
	end

	local combatants = { battle.Player, battle.Enemy }
	table.sort(combatants, function(a, b) return (a.TotalSpeed or 1) > (b.TotalSpeed or 1) end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end
		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		if combatant.Statuses then for sName, duration in pairs(combatant.Statuses) do if duration > 0 then combatant.Statuses[sName] = duration - 1; if combatant.Statuses[sName] <= 0 then combatant.Statuses[sName] = nil end end end end
		if combatant.GateType == "Steam" and combatant.GateHP and combatant.GateHP > 0 then combatant.GateHP = math.max(0, combatant.GateHP - 1) end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return end
			if skill.GasCost then combatant.Gas = math.max(0, combatant.Gas - skill.GasCost) end
			if skill.Effect == "Rest" or skillName == "Recover" then combatant.Gas = math.min(combatant.MaxGas, combatant.Gas + (combatant.MaxGas * 0.40)) end
			if skill.EnergyCost then combatant.TitanEnergy = math.max(0, combatant.TitanEnergy - skill.EnergyCost) end
			DispatchStrike(battle.Player, battle.Enemy, skillName)
			if combatant.Statuses and combatant.Statuses["Transformed"] then if combatant.TitanEnergy <= 0 then combatant.Statuses["Transformed"] = nil end end
		else
			local aiSkill = combatant.Skills[math.random(1, #combatant.Skills)] or "Brutal Swipe"
			DispatchStrike(battle.Enemy, battle.Player, aiSkill)
		end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle})
		ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then

		UpdateBountyProgress(player, "Kill", 1)
		UpdateBountyProgress(player, "Clear", 1)

		local xpGain = battle.Enemy.Drops.XP; local dewsGain = battle.Enemy.Drops.Dews
		if player:GetAttribute("HasDoubleXP") then xpGain *= 2; dewsGain *= 2 end
		player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)
		player.leaderstats.Dews.Value += dewsGain

		local droppedItems = {}
		if battle.Enemy.Drops.ItemChance then
			for itemName, baseChance in pairs(battle.Enemy.Drops.ItemChance) do
				local finalChance = baseChance
				if battle.Context.IsEndless then
					local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
					if iData and iData.Rarity ~= "Legendary" and iData.Rarity ~= "Mythical" then finalChance = finalChance * 2.0 end
				end
				if math.random(1, 100) <= finalChance then
					table.insert(droppedItems, itemName)
					local attrName = itemName:gsub("[^%w]", "") .. "Count"
					player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
				end
			end
		end

		if battle.Context.IsStoryMission and battle.Context.CurrentWave < battle.Context.TotalWaves then
			battle.Context.CurrentWave += 1
			if battle.Context.TargetPart == (player:GetAttribute("CurrentPart") or 1) then player:SetAttribute("CurrentWave", battle.Context.CurrentWave) end

			local hpScale = GetHPScale(player); local dmgScale = GetDmgScale(player)
			local currentPart = battle.Context.TargetPart
			local partData = EnemyData.Parts[currentPart]
			local waveData = battle.Context.MissionData.Waves[battle.Context.CurrentWave]
			local nextEnemyTemplate = GetTemplate(partData, waveData.Template)

			battle.Enemy = {
				IsPlayer = false, Name = nextEnemyTemplate.Name,
				HP = math.floor(nextEnemyTemplate.Health * hpScale), MaxHP = math.floor(nextEnemyTemplate.Health * hpScale),
				GateType = nextEnemyTemplate.GateType, GateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpScale)), MaxGateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpScale)),
				TotalStrength = math.floor(nextEnemyTemplate.Strength * dmgScale), TotalDefense = math.floor(nextEnemyTemplate.Defense * dmgScale), TotalSpeed = math.floor(nextEnemyTemplate.Speed * dmgScale),
				Statuses = {}, Cooldowns = {}, Skills = nextEnemyTemplate.Skills or {"Brutal Swipe"},
				Drops = { XP = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.XP or 10) * hpScale), Dews = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.Dews or 5) * hpScale), ItemChance = nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.ItemChance or {} },
				LastSkill = "None"
			}

			battle.Player.Cooldowns = {} 
			battle.Player.HP = battle.Player.MaxHP; battle.Player.Gas = battle.Player.MaxGas; battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 30); battle.Player.LastSkill = "None"
			CombatUpdate:FireClient(player, "WaveComplete", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. waveData.Flavor, XP = xpGain, Dews = dewsGain, Items = droppedItems})
			battle.IsProcessing = false
		else
			if battle.Context.IsStoryMission then
				local playerCurrentPart = player:GetAttribute("CurrentPart") or 1
				if battle.Context.TargetPart == playerCurrentPart then
					local nextPart = playerCurrentPart + 1
					if EnemyData.Parts[nextPart] then
						player:SetAttribute("CurrentPart", nextPart)
						player:SetAttribute("CurrentWave", 1) 
					end
				end
			end
			CombatUpdate:FireClient(player, "Victory", {Battle = battle, XP = xpGain, Dews = dewsGain, Items = droppedItems})
			ActiveBattles[player.UserId] = nil
		end
	else
		if not battle.Player.Statuses or not battle.Player.Statuses["Transformed"] then battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 15) end
		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)