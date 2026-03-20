-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatCore = require(script.Parent:WaitForChild("CombatCore"))

local GameDataStore = DataStoreService:GetDataStore("AoT_Data_V1")

local Network = ReplicatedStorage:FindFirstChild("Network") or Instance.new("Folder", ReplicatedStorage)
Network.Name = "Network"

local reqRemotes = {
	"CombatAction", "CombatUpdate", "ToggleMute", "PrestigeEvent",
	"NotificationEvent", "DungeonUpdate", "WorldBossUpdate", "WorldBossAction", 
	"RaidAction", "RaidUpdate", "ToggleTraining", "ShopAction", "ShopUpdate"
}
for _, rName in ipairs(reqRemotes) do
	if not Network:FindFirstChild(rName) then 
		local r = Instance.new("RemoteEvent", Network)
		r.Name = rName 
	end
end

local CombatAction = Network:WaitForChild("CombatAction")
local CombatUpdate = Network:WaitForChild("CombatUpdate")

local DefaultData = {
	Prestige = 0, CurrentPart = 1, CurrentMission = 1, XP = 0, Yen = 0, Elo = 1000,
	Titan = "None", FightingStyle = "Ultrahard Steel Blades", Clan = "None",
	Health = 10, Strength = 10, Defense = 10, Speed = 10, Willpower = 10
}

Players.PlayerAdded:Connect(function(player)
	local success, savedData = pcall(function() return GameDataStore:GetAsync(player.UserId) end)
	local data = {}
	for key, defaultVal in pairs(DefaultData) do
		if success and savedData and savedData[key] ~= nil then
			data[key] = savedData[key]
		else
			data[key] = defaultVal
		end
	end

	local ls = Instance.new("Folder", player)
	ls.Name = "leaderstats"
	local p = Instance.new("IntValue", ls); p.Name = "Prestige"; p.Value = data.Prestige
	local y = Instance.new("IntValue", ls); y.Name = "Yen"; y.Value = data.Yen
	local e = Instance.new("IntValue", ls); e.Name = "Elo"; e.Value = data.Elo

	for key, val in pairs(DefaultData) do
		if key ~= "Prestige" and key ~= "Yen" and key ~= "Elo" then
			player:SetAttribute(key, data[key])
		end
	end
end)

local ActiveBattles = {}

local function GetTemplate(partData, templateName)
	if partData.Templates and partData.Templates[templateName] then return partData.Templates[templateName] end
	for _, mob in ipairs(partData.Mobs) do if mob.Name == templateName then return mob end end
	return partData.Mobs[1]
end

local function StartBattle(player, encounterType)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	local partData = EnemyData.Parts[currentPart]
	if not partData then return end

	local eTemplate, logFlavor
	local isStory = (encounterType == "EngageStory")

	if isStory then
		local currentMission = player:GetAttribute("CurrentMission") or 1
		local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		if currentMission > #missionTable then currentMission = 1; player:SetAttribute("CurrentMission", 1) end

		local waveData = missionTable[currentMission].Waves[1]
		eTemplate = GetTemplate(partData, waveData.Template)
		logFlavor = "<font color='#FFD700'>[Mission: " .. missionTable[currentMission].Name .. "]</font>\n" .. waveData.Flavor
	else
		eTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		local flavors = partData.RandomFlavor or {"You encounter a %s!"}
		logFlavor = string.format(flavors[math.random(1, #flavors)], eTemplate.Name)
	end

	ActiveBattles[player.UserId] = {
		IsProcessing = false,
		Context = { IsStoryMission = isStory, CurrentWave = 1, TotalWaves = 1 },
		Player = {
			IsPlayer = true, Name = player.Name, PlayerObj = player,
			Titan = player:GetAttribute("Titan") or "None",
			Style = player:GetAttribute("FightingStyle") or "None",
			Clan = player:GetAttribute("Clan") or "None",
			HP = (player:GetAttribute("Health") or 10) * 10, MaxHP = (player:GetAttribute("Health") or 10) * 10,

			TitanEnergy = 100, MaxTitanEnergy = 100, 
			Stamina = 100, MaxStamina = 100, StandEnergy = 100, MaxStandEnergy = 100, 

			TotalStrength = player:GetAttribute("Strength") or 10,
			TotalDefense = player:GetAttribute("Defense") or 10,
			TotalSpeed = player:GetAttribute("Speed") or 10,
			TotalWillpower = player:GetAttribute("Willpower") or 10,
			BlockTurns = 0, Statuses = {}, Cooldowns = {}
		},
		Enemy = {
			IsPlayer = false, Name = eTemplate.Name,
			HP = eTemplate.Health, MaxHP = eTemplate.Health,
			TotalStrength = eTemplate.Strength, TotalDefense = eTemplate.Defense, TotalSpeed = eTemplate.Speed,
			BlockTurns = 0, Statuses = {}, Cooldowns = {}, Skills = eTemplate.Skills or {"Basic Slash"},
			Drops = { XP = eTemplate.Drops and eTemplate.Drops.XP or 10, Yen = eTemplate.Drops and eTemplate.Drops.Yen or 5 }
		}
	}

	print("[SERVER] Starting battle for " .. player.Name .. " against " .. eTemplate.Name)
	CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor })
end

CombatAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "EngageRandom" or actionType == "EngageStory" then StartBattle(player, actionType); return end

	local battle = ActiveBattles[player.UserId]
	if not battle or battle.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData.SkillName
	local skill = SkillData.Skills[skillName]

	if battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0 then return end
	if (battle.Player.TitanEnergy or 0) < (skill.EnergyCost or 0) then return end

	battle.IsProcessing = true
	print("[SERVER] " .. player.Name .. " used " .. skillName)

	local function DispatchStrike(attacker, defender, strikeSkill)
		if attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function()
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, attacker.IsPlayer and "You" or attacker.Name, defender.IsPlayer and "you" or defender.Name, attacker.IsPlayer and "#FFFFFF" or "#FF5555", defender.IsPlayer and "#FFFFFF" or "#FF5555")
		end)

		if success then
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
			task.wait(1.2)
		else 
			warn("[SERVER COMBAT ERROR]:", msg)
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>SERVER ERROR: " .. tostring(msg) .. "</font>", DidHit = false, ShakeType = "None"})
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
				CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return
			end
			DispatchStrike(battle.Player, battle.Enemy, skillName)
		else
			local aiSkill = combatant.Skills[math.random(1, #combatant.Skills)]
			DispatchStrike(battle.Enemy, battle.Player, aiSkill)
		end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then
		player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + battle.Enemy.Drops.XP)
		player.leaderstats.Yen.Value += battle.Enemy.Drops.Yen
		CombatUpdate:FireClient(player, "Victory", {Battle = battle, XP = battle.Enemy.Drops.XP, Yen = battle.Enemy.Drops.Yen, Items = {}})
		ActiveBattles[player.UserId] = nil
	else
		battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 15)
		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)