-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local Network = ReplicatedStorage:WaitForChild("Network")
local CombatAction = Network:WaitForChild("CombatAction")
local CombatUpdate = Network:WaitForChild("CombatUpdate")

local ActiveBattles = {}

local function GetEnemyTemplate(partIndex, templateName)
	local partData = EnemyData.Parts[partIndex]
	if not partData then return nil end
	if partData.Templates and partData.Templates[templateName] then return partData.Templates[templateName] end
	if partData.Mobs then
		for _, mob in ipairs(partData.Mobs) do
			if mob.Name == templateName then return mob end
		end
	end
	return { Name = "Glitch Entity", Health = 10, Strength = 1, Defense = 0, Speed = 1, Willpower = 1, TitanStats = {Power="None", Speed="None", Hardening="None", Precision="None"}, Skills = {"Basic Slash"}, Drops = { Yen = 0, XP = 0 } }
end

local function GenerateNPCEntity(template, isAlly, prestige, uniModStr, currentPart)
	local scaleHP, scaleStr, scaleDef, scaleSpd, scaleWill, xpScale = 1, 1, 1, 1, 1, 1

	if prestige and prestige > 0 then
		local b = 1 + (prestige * 0.15)
		scaleHP = b; scaleStr = b; scaleDef = b; scaleSpd = 1 + (prestige * 0.05); scaleWill = 1 + (prestige * 0.05)
		xpScale = 1 + (prestige * 0.25)
	end

	local sStats = template.TitanStats or {Power="None", Speed="None", Hardening="None", Precision="None"}

	return {
		IsPlayer = false, IsAlly = isAlly, Name = template.Name, Trait = "None",
		IsBoss = template.IsBoss or false,
		HP = template.Health * scaleHP, MaxHP = template.Health * scaleHP,
		TotalStrength = (template.Strength + (GameData.TitanRanks and GameData.TitanRanks[sStats.Power] or 0)) * scaleStr,
		TotalDefense = (template.Defense + (GameData.TitanRanks and GameData.TitanRanks[sStats.Hardening] or 0)) * scaleDef,
		TotalSpeed = (template.Speed + (GameData.TitanRanks and GameData.TitanRanks[sStats.Speed] or 0)) * scaleSpd,
		TotalWillpower = (template.Willpower or 1) * scaleWill,
		TotalPrecision = (GameData.TitanRanks and GameData.TitanRanks[sStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {},
		Skills = template.Skills or {"Basic Slash"},
		ScaledDrops = { XP = math.floor((template.Drops and template.Drops.XP or 0) * xpScale), Yen = math.floor((template.Drops and template.Drops.Yen or 0)) }
	}
end

local function StartBattle(player, encounterType)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	local partData = EnemyData.Parts[currentPart]
	if not partData then return end

	local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:WaitForChild("Prestige", 5)
	local prestige = prestigeObj and prestigeObj.Value or 0
	local uniModStr = player:GetAttribute("UniverseModifier") or "None"

	local enemyTemplate
	local battleContext = { IsStoryMission = false, MissionIndex = 0, CurrentWave = 1, TotalWaves = 1, MissionData = nil }
	local initialLogMsg = ""

	if encounterType == "Random" then
		enemyTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		local flavorPool = partData.RandomFlavor or {"You encounter a %s!"}
		initialLogMsg = string.format(flavorPool[math.random(1, #flavorPool)], enemyTemplate.Name)
	elseif encounterType == "Story" then
		local currentMission = player:GetAttribute("CurrentMission") or 1
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		if currentMission > #missionTable then currentMission = 1; player:SetAttribute("CurrentMission", 1) end

		local missionData = missionTable[currentMission]
		battleContext.IsStoryMission = true; battleContext.MissionIndex = currentMission; battleContext.MissionData = missionData; battleContext.TotalWaves = #missionData.Waves
		enemyTemplate = GetEnemyTemplate(currentPart, missionData.Waves[1].Template)
		initialLogMsg = "<font color='#FFD700'>[Mission: " .. missionData.Name .. " - Wave 1]</font>\n" .. missionData.Waves[1].Flavor
	end

	local pTitan = player:GetAttribute("Titan") or "None"
	local tPow = (pTitan ~= "None") and (player:GetAttribute("Titan_Power_Val") or 0) or 0
	local tDur = (pTitan ~= "None") and (player:GetAttribute("Titan_Hardening_Val") or 0) or 0
	local tSpd = (pTitan ~= "None") and (player:GetAttribute("Titan_Speed_Val") or 0) or 0
	local tPre = (pTitan ~= "None") and (player:GetAttribute("Titan_Precision_Val") or 0) or 0

	local pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
	local pStr = (player:GetAttribute("Strength") or 1) + tPow + CombatCore.GetEquipBonus(player, "Strength") + CombatCore.GetEquipBonus(player, "Titan_Power")
	local pDef = (player:GetAttribute("Defense") or 1) + tDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Titan_Hardening")
	local pSpd = (player:GetAttribute("Speed") or 1) + tSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Titan_Speed")
	local pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")

	local activeBoosts = CombatCore.GetPlayerBoosts(player)
	local generatedEnemy = GenerateNPCEntity(enemyTemplate, false, prestige, uniModStr, currentPart)

	ActiveBattles[player.UserId] = {
		EncounterType = encounterType, Context = battleContext, IsProcessing = false, Boosts = activeBoosts,
		Player = {
			IsPlayer = true, IsAlly = false, Name = player.Name, GlobalDmgBoost = activeBoosts.Damage, PlayerObj = player,
			Titan = pTitan, Style = player:GetAttribute("FightingStyle") or "None", Clan = player:GetAttribute("Clan") or "None",
			HP = pHP * 10, MaxHP = pHP * 10,
			TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd, TotalWillpower = pWill, TotalPrecision = tPre,
			BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0, Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0 }, Cooldowns = {}
		},
		Enemy = generatedEnemy, Drops = generatedEnemy.ScaledDrops, TurnCounter = 1
	}

	CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = initialLogMsg })
end

CombatAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "EngageStory" or actionType == "EngageRandom" then StartBattle(player, actionType == "EngageStory" and "Story" or "Random"); return end

	local battle = ActiveBattles[player.UserId]
	if not battle or battle.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData.SkillName
	local skill = SkillData.Skills[skillName]

	if battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0 then return end
	battle.IsProcessing = true
	local waitMultiplier = player:GetAttribute("Has2xBattleSpeed") and 0.6 or 1.2

	local function DispatchStrike(attacker, defender, strikeSkill)
		if not attacker or not defender or attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function()
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, "None", attacker.IsPlayer and "You" or attacker.Name, defender.IsPlayer and "you" or defender.Name, attacker.IsPlayer and "#FFFFFF" or "#FF5555", defender.IsPlayer and "#FFFFFF" or "#FF5555")
		end)

		if success then
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
			task.wait(waitMultiplier)
		else 
			warn("Combat Strike Error: ", msg) 
			-- FORCES THE ERROR TO SHOW ON SCREEN IF IT CRASHES
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>SERVER CRASH: " .. tostring(msg) .. "</font>", DidHit = false, ShakeType = "None"})
			battle.IsProcessing = false
			return
		end
	end

	local combatants = { battle.Player, battle.Enemy }
	table.sort(combatants, function(a, b) return (a.TotalSpeed or 1) > (b.TotalSpeed or 1) end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>You fled from the battle!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier); CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return
			end
			DispatchStrike(battle.Player, battle.Enemy, skillName)
		else
			DispatchStrike(battle.Enemy, battle.Player, CombatCore.ChooseAISkill(combatant))
		end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then
		local fXP = math.floor(battle.Drops.XP * battle.Boosts.XP)
		local fYen = math.floor(battle.Drops.Yen * battle.Boosts.Yen)
		player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
		player.leaderstats.Yen.Value += fYen

		if battle.Context.IsStoryMission and battle.Context.CurrentWave < battle.Context.TotalWaves then
			battle.Context.CurrentWave += 1
			local nextWaveData = battle.Context.MissionData.Waves[battle.Context.CurrentWave]
			local newEnemy = GenerateNPCEntity(GetEnemyTemplate(player:GetAttribute("CurrentPart") or 1, nextWaveData.Template), false, 0, "None", player:GetAttribute("CurrentPart") or 1)
			battle.Enemy = newEnemy; battle.Drops = newEnemy.ScaledDrops; battle.TurnCounter = 1; battle.IsProcessing = false
			CombatUpdate:FireClient(player, "WaveComplete", { Battle = battle, LogMsg = "<font color='#FFD700'>[Wave " .. battle.Context.CurrentWave .. "]</font>\n" .. nextWaveData.Flavor, XP = fXP, Yen = fYen })
			return
		end
		CombatUpdate:FireClient(player, "Victory", {Battle = battle, XP = fXP, Yen = fYen, Items = {}})
		ActiveBattles[player.UserId] = nil
	else
		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)