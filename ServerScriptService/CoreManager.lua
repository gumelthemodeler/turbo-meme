-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

-- NEW DATASTORE FOR THE AOT REWORK
local GameDataStore = DataStoreService:GetDataStore("AoT_Incremental_V1")

-- Prevent UI Infinite Yields from missing folders
local UITemplates = ReplicatedStorage:FindFirstChild("UITemplates")
if not UITemplates then
	UITemplates = Instance.new("Folder")
	UITemplates.Name = "UITemplates"
	UITemplates.Parent = ReplicatedStorage
end

local RemotesFolder = ReplicatedStorage:FindFirstChild("Network")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Network"
	RemotesFolder.Parent = ReplicatedStorage
end

-- Updated Remote Events (Swapped Gang for Clan, Removed Trade if unneeded, etc.)
local requiredRemotes = {
	"ToggleMute",
	"TutorialAction",
	"CombatAction",
	"CombatUpdate",
	"DungeonAction", -- (Expeditions)
	"DungeonUpdate",
	"ArenaAction",
	"ArenaUpdate",
	"ShopAction",
	"ShopUpdate",
	"BoostAction",
	"ClanAction", -- Formerly Gang
	"ClanUpdate",
	"InventoryAction",
	"TrainingAction",
	"MultiplayerAction",
	"NotificationEvent",
	"AutoSellToggle",
	"PrestigeEvent"
}

for _, remoteName in ipairs(requiredRemotes) do
	if not RemotesFolder:FindFirstChild(remoteName) then
		local re = Instance.new("RemoteEvent")
		re.Name = remoteName
		re.Parent = RemotesFolder
	end
end

local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
if not saveEvent then
	saveEvent = Instance.new("BindableEvent")
	saveEvent.Name = "ForcePlayerSave"
	saveEvent.Parent = ReplicatedStorage
end

local ToggleMuteRemote = RemotesFolder:WaitForChild("ToggleMute")
ToggleMuteRemote.OnServerEvent:Connect(function(player, state)
	if type(state) == "boolean" then
		player:SetAttribute("IsMuted", state)
	end
end)

-- FULLY OVERHAULED DEFAULT DATA
local DefaultData = {
	Prestige = 0, CurrentPart = 1, CurrentMission = 1, XP = 0, Yen = 0, Elo = 1000, TutorialStep = 0, PlayTime = 0,
	EndlessHighScore = 0, EndlessMaxMilestone = 0, RaidWins = 0, 
	CampaignClear_Part1 = false, CampaignClear_Part2 = false, CampaignClear_Part3 = false,
	CampaignClear_Part4 = false, CampaignClear_Part5 = false, CampaignClear_Part6 = false, CampaignClear_Part7 = false,

	AutoSell_Common = false, AutoSell_Uncommon = false, AutoSell_Rare = false, AutoSell_Legendary = false, AutoSell_Mythical = false,

	BattleCondition = "Clear Weather", TitanPity = 0, TraitPity = 0, ShopPity = 0, ClaimedSupporterReward = false,

	Clan = "None", ClanRole = "None", LastOnline = os.time(),

	LastWorldBossHour = -1,

	TitanLocked = false, StyleLocked = false, IsMuted = false, LockedItems = "",

	Has2xBattleSpeed = false, HasAutoTraining = false, Has2xInventory = false,
	Has2xDropChance = false, HasTitanSlot2 = false, HasTitanSlot3 = false,
	HasAutoRoll = false,

	HasStyleSlot2 = false, HasStyleSlot3 = false,

	Stats = { Health = 1, Strength = 1, Defense = 1, Speed = 1, Stamina = 1, Willpower = 1 },
	EquippedWeapon = "None", EquippedAccessory = "None",

	TitanStats = {Power="None", Speed="None", Hardening="None", Endurance="None", Precision="None", Potential="None"},
	TitanStatsVal = {Power=0, Speed=0, Hardening=0, Endurance=0, Precision=0, Potential=0},

	ShopStock = "", ShopRefreshTime = 0, RedeemedCodes = "",

	StoredTitan1 = "None", StoredTitan1_Trait = "None",
	StoredTitan2 = "None", StoredTitan2_Trait = "None",
	StoredTitan3 = "None", StoredTitan3_Trait = "None",
	StoredTitan4 = "None", StoredTitan4_Trait = "None",
	StoredTitan5 = "None", StoredTitan5_Trait = "None",

	StoredStyle1 = "None",
	StoredStyle2 = "None",
	StoredStyle3 = "None",
}

local function SetupLeaderstats(player, savedData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "Prestige"
	level.Value = savedData.Prestige or DefaultData.Prestige
	level.Parent = leaderstats

	local yen = Instance.new("IntValue")
	yen.Name = "Yen"
	yen.Value = savedData.Yen or DefaultData.Yen
	yen.Parent = leaderstats

	local elo = Instance.new("IntValue")
	elo.Name = "Elo"
	elo.Value = savedData.Elo or DefaultData.Elo
	elo.Parent = leaderstats

	player:SetAttribute("ShopStock", savedData.ShopStock or DefaultData.ShopStock)
	player:SetAttribute("ShopRefreshTime", savedData.ShopRefreshTime or DefaultData.ShopRefreshTime)
	player:SetAttribute("RedeemedCodes", savedData.RedeemedCodes or DefaultData.RedeemedCodes)
	player:SetAttribute("LastOnline", savedData.LastOnline or os.time())

	for key, val in pairs(savedData) do
		if type(val) ~= "table" and key ~= "Prestige" and key ~= "Yen" and key ~= "Elo" and key ~= "ShopStock" and key ~= "ShopRefreshTime" and key ~= "RedeemedCodes" and key ~= "LastOnline" then
			player:SetAttribute(key, val)
		end
	end

	for statName, statVal in pairs(savedData.Stats) do player:SetAttribute(statName, statVal) end
	for titanStat, rank in pairs(savedData.TitanStats) do player:SetAttribute("Titan_"..titanStat, rank) end
	for titanStatVal, val in pairs(savedData.TitanStatsVal) do player:SetAttribute("Titan_"..titanStatVal.."_Val", val) end

	local function LoadItems(itemTable)
		for itemName, _ in pairs(itemTable) do
			local attrName = itemName:gsub("[^%w]", "") .. "Count"
			if savedData[attrName] then player:SetAttribute(attrName, savedData[attrName]) end
		end
	end
	LoadItems(ItemData.Equipment)
	LoadItems(ItemData.Consumables)
end

local function SavePlayerData(player)
	if not player:FindFirstChild("leaderstats") then return end

	local dataToSave = {
		Prestige = player.leaderstats.Prestige.Value, CurrentPart = player:GetAttribute("CurrentPart"),
		CurrentMission = player:GetAttribute("CurrentMission"), XP = player:GetAttribute("XP"), 
		Yen = player.leaderstats.Yen.Value, Elo = player.leaderstats.Elo.Value,
		TutorialStep = player:GetAttribute("TutorialStep"), PlayTime = player:GetAttribute("PlayTime") or 0,

		EndlessHighScore = player:GetAttribute("EndlessHighScore") or 0,
		EndlessMaxMilestone = player:GetAttribute("EndlessMaxMilestone") or 0,
		RaidWins = player:GetAttribute("RaidWins") or 0, 

		CampaignClear_Part1 = player:GetAttribute("CampaignClear_Part1") or false,
		CampaignClear_Part2 = player:GetAttribute("CampaignClear_Part2") or false,
		CampaignClear_Part3 = player:GetAttribute("CampaignClear_Part3") or false,
		CampaignClear_Part4 = player:GetAttribute("CampaignClear_Part4") or false,
		CampaignClear_Part5 = player:GetAttribute("CampaignClear_Part5") or false,
		CampaignClear_Part6 = player:GetAttribute("CampaignClear_Part6") or false,
		CampaignClear_Part7 = player:GetAttribute("CampaignClear_Part7") or false,

		AutoSell_Common = player:GetAttribute("AutoSell_Common") or false,
		AutoSell_Uncommon = player:GetAttribute("AutoSell_Uncommon") or false,
		AutoSell_Rare = player:GetAttribute("AutoSell_Rare") or false,
		AutoSell_Legendary = player:GetAttribute("AutoSell_Legendary") or false,
		AutoSell_Mythical = player:GetAttribute("AutoSell_Mythical") or false,

		BattleCondition = player:GetAttribute("BattleCondition") or "Clear Weather",
		TitanPity = player:GetAttribute("TitanPity") or 0,
		TraitPity = player:GetAttribute("TraitPity") or 0,
		ShopPity = player:GetAttribute("ShopPity") or 0,
		ClaimedSupporterReward = player:GetAttribute("ClaimedSupporterReward") or false,

		Clan = player:GetAttribute("Clan") or "None",
		ClanRole = player:GetAttribute("ClanRole") or "None",
		LastOnline = player:GetAttribute("LastOnline"), 

		LastWorldBossHour = player:GetAttribute("LastWorldBossHour") or -1,

		TitanLocked = player:GetAttribute("TitanLocked") or false,
		StyleLocked = player:GetAttribute("StyleLocked") or false,
		IsMuted = player:GetAttribute("IsMuted") or false,
		LockedItems = player:GetAttribute("LockedItems") or "",

		Has2xBattleSpeed = player:GetAttribute("Has2xBattleSpeed") or false,
		HasAutoTraining = player:GetAttribute("HasAutoTraining") or false,
		Has2xInventory = player:GetAttribute("Has2xInventory") or false,
		Has2xDropChance = player:GetAttribute("Has2xDropChance") or false,
		HasTitanSlot2 = player:GetAttribute("HasTitanSlot2") or false,
		HasTitanSlot3 = player:GetAttribute("HasTitanSlot3") or false,
		HasAutoRoll = player:GetAttribute("HasAutoRoll") or false,

		HasStyleSlot2 = player:GetAttribute("HasStyleSlot2") or false,
		HasStyleSlot3 = player:GetAttribute("HasStyleSlot3") or false,

		Titan = player:GetAttribute("Titan"), TitanTrait = player:GetAttribute("TitanTrait") or "None",
		FightingStyle = player:GetAttribute("FightingStyle"),
		EquippedWeapon = player:GetAttribute("EquippedWeapon"), EquippedAccessory = player:GetAttribute("EquippedAccessory"),
		ShopStock = player:GetAttribute("ShopStock"), ShopRefreshTime = player:GetAttribute("ShopRefreshTime"),
		RedeemedCodes = player:GetAttribute("RedeemedCodes") or "",

		StoredTitan1 = player:GetAttribute("StoredTitan1") or "None",
		StoredTitan1_Trait = player:GetAttribute("StoredTitan1_Trait") or "None",
		StoredTitan2 = player:GetAttribute("StoredTitan2") or "None",
		StoredTitan2_Trait = player:GetAttribute("StoredTitan2_Trait") or "None",
		StoredTitan3 = player:GetAttribute("StoredTitan3") or "None",
		StoredTitan3_Trait = player:GetAttribute("StoredTitan3_Trait") or "None",
		StoredTitan4 = player:GetAttribute("StoredTitan4") or "None",
		StoredTitan4_Trait = player:GetAttribute("StoredTitan4_Trait") or "None",
		StoredTitan5 = player:GetAttribute("StoredTitan5") or "None",
		StoredTitan5_Trait = player:GetAttribute("StoredTitan5_Trait") or "None",

		StoredStyle1 = player:GetAttribute("StoredStyle1") or "None",
		StoredStyle2 = player:GetAttribute("StoredStyle2") or "None",
		StoredStyle3 = player:GetAttribute("StoredStyle3") or "None",

		Stats = { Health=player:GetAttribute("Health"), Strength=player:GetAttribute("Strength"), Defense=player:GetAttribute("Defense"), Speed=player:GetAttribute("Speed"), Stamina=player:GetAttribute("Stamina"), Willpower=player:GetAttribute("Willpower") },
		TitanStats = { Power=player:GetAttribute("Titan_Power"), Speed=player:GetAttribute("Titan_Speed"), Hardening=player:GetAttribute("Titan_Hardening"), Endurance=player:GetAttribute("Titan_Endurance"), Precision=player:GetAttribute("Titan_Precision"), Potential=player:GetAttribute("Titan_Potential") },
		TitanStatsVal = { Power=player:GetAttribute("Titan_Power_Val"), Speed=player:GetAttribute("Titan_Speed_Val"), Hardening=player:GetAttribute("Titan_Hardening_Val"), Endurance=player:GetAttribute("Titan_Endurance_Val"), Precision=player:GetAttribute("Titan_Precision_Val"), Potential=player:GetAttribute("Titan_Potential_Val") }
	}

	local function SaveItems(itemTable, saveTarget)
		for itemName, _ in pairs(itemTable) do
			local attrName = itemName:gsub("[^%w]", "") .. "Count"
			saveTarget[attrName] = player:GetAttribute(attrName) or 0
		end
	end

	SaveItems(ItemData.Equipment, dataToSave)
	SaveItems(ItemData.Consumables, dataToSave)

	local success, err = pcall(function() GameDataStore:SetAsync(player.UserId, dataToSave) end)
	if not success then warn("Failed to save data for " .. player.Name .. ": ", err) end
end

Players.PlayerAdded:Connect(function(player)
	local success, savedData = pcall(function() return GameDataStore:GetAsync(player.UserId) end)
	if success and savedData then
		for k, v in pairs(DefaultData) do if savedData[k] == nil then savedData[k] = v end end
		SetupLeaderstats(player, savedData)
	else
		SetupLeaderstats(player, DefaultData)
	end

	local currentPrestige = player.leaderstats.Prestige.Value
	local statCap = GameData.GetStatCap(currentPrestige)
	local clampStats = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", "Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}

	for _, statName in ipairs(clampStats) do
		local val = player:GetAttribute(statName)
		if val and val > statCap then
			player:SetAttribute(statName, statCap)
		end
	end

	local function VerifyPass(id, attr)
		local ownsFromGift = player:GetAttribute(attr) or false 

		if not ownsFromGift then
			local ownsFromWeb = false
			pcall(function() ownsFromWeb = MarketplaceService:UserOwnsGamePassAsync(player.UserId, id) end)
			player:SetAttribute(attr, ownsFromWeb)
		else
			player:SetAttribute(attr, true)
		end
	end

	VerifyPass(1731694181, "Has2xBattleSpeed")
	VerifyPass(1732129582, "HasAutoTraining")
	VerifyPass(1732900742, "Has2xInventory")
	VerifyPass(1732842877, "Has2xDropChance")
	VerifyPass(1733160695, "HasTitanSlot2")
	VerifyPass(1732844091, "HasTitanSlot3")
	VerifyPass(1746853452, "HasStyleSlot2") 
	VerifyPass(1745969849, "HasStyleSlot3")
	VerifyPass(1749484465, "HasAutoRoll")
	-- Horse Name pass removed entirely.

	task.spawn(function()
		while player and player.Parent do
			task.wait(60)
			player:SetAttribute("PlayTime", (player:GetAttribute("PlayTime") or 0) + 60)
		end
	end)
end)

saveEvent.Event:Connect(function(player)
	if player and player.Parent then
		SavePlayerData(player)
	end
end)

RemotesFolder:WaitForChild("TutorialAction").OnServerEvent:Connect(function(player, action)
	if action == "GiveXP" and player:GetAttribute("TutorialStep") == 0 then
		player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + 100)
	elseif action == "Complete" then
		player:SetAttribute("TutorialStep", 1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	player:SetAttribute("LastOnline", os.time())
	SavePlayerData(player)
end)

task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("LastOnline") then
				player:SetAttribute("LastOnline", os.time())
			end
			SavePlayerData(player)

			local notifUpdate = RemotesFolder:FindFirstChild("NotificationEvent")
			if notifUpdate then
				notifUpdate:FireClient(player, "<b><font color='#55FF55'>Game Auto-Saved</font></b>")
			end
		end
	end
end)