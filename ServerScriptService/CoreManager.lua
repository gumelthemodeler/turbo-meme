-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameDataStore = DataStoreService:GetDataStore("AoT_Data_V1")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Network")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Network"
	RemotesFolder.Parent = ReplicatedStorage
end

local requiredRemotes = {
	"ToggleMute", "CombatAction", "CombatUpdate", "PrestigeEvent",
	"NotificationEvent", "DungeonUpdate", "WorldBossUpdate", "WorldBossAction", 
	"RaidAction", "RaidUpdate", "ToggleTraining", "ShopAction", "ShopUpdate"
}

for _, remoteName in ipairs(requiredRemotes) do
	if not RemotesFolder:FindFirstChild(remoteName) then
		local re = Instance.new("RemoteEvent")
		re.Name = remoteName
		re.Parent = RemotesFolder
	end
end

local DefaultData = {
	Prestige = 0, CurrentPart = 1, CurrentMission = 1, XP = 0, Yen = 0,
	BattleCondition = "Clear Weather", 
	Titan = "None", TitanTrait = "None",
	FightingStyle = "Ultrahard Steel Blades",
	Clan = "None",
	Health = 10, Strength = 10, Defense = 10, Speed = 10, Willpower = 10
}

local function SetupLeaderstats(player, savedData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local prestige = Instance.new("IntValue")
	prestige.Name = "Prestige"
	prestige.Value = savedData.Prestige or DefaultData.Prestige
	prestige.Parent = leaderstats

	local yen = Instance.new("IntValue")
	yen.Name = "Yen"
	yen.Value = savedData.Yen or DefaultData.Yen
	yen.Parent = leaderstats

	local elo = Instance.new("IntValue")
	elo.Name = "Elo"
	elo.Value = 1000
	elo.Parent = leaderstats

	for key, val in pairs(DefaultData) do
		if key ~= "Prestige" and key ~= "Yen" and key ~= "Elo" then
			player:SetAttribute(key, savedData[key] or val)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local success, savedData = pcall(function() return GameDataStore:GetAsync(player.UserId) end)
	SetupLeaderstats(player, (success and savedData) and savedData or DefaultData)
end)

Players.PlayerRemoving:Connect(function(player)
	if not player:FindFirstChild("leaderstats") then return end
	local dataToSave = {
		Prestige = player.leaderstats.Prestige.Value,
		Yen = player.leaderstats.Yen.Value,
		CurrentPart = player:GetAttribute("CurrentPart"),
		CurrentMission = player:GetAttribute("CurrentMission"),
		XP = player:GetAttribute("XP"),
		Titan = player:GetAttribute("Titan"),
		FightingStyle = player:GetAttribute("FightingStyle"),
		Clan = player:GetAttribute("Clan"),
		Health = player:GetAttribute("Health"),
		Strength = player:GetAttribute("Strength"),
		Defense = player:GetAttribute("Defense"),
		Speed = player:GetAttribute("Speed"),
		Willpower = player:GetAttribute("Willpower")
	}
	pcall(function() GameDataStore:SetAsync(player.UserId, dataToSave) end)
end)