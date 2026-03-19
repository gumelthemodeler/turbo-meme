-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local GameDataStore = DataStoreService:GetDataStore("JojoRPG_Alpha_V8")

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

local requiredRemotes = {
	"ToggleMute",
	"TutorialAction",
	"CombatAction",
	"CombatUpdate",
	"DungeonAction",
	"DungeonUpdate",
	"ArenaAction",
	"ArenaUpdate",
	"TradeAction",
	"TradeUpdate",
	"ShopAction",
	"ShopUpdate",
	"BoostAction",
	"GangAction",
	"GangUpdate",
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

local DefaultData = {
	Prestige = 0, CurrentPart = 1, CurrentMission = 1, XP = 0, Yen = 0, Elo = 1000, TutorialStep = 0, PlayTime = 0,
	EndlessHighScore = 0, EndlessMaxMilestone = 0, RaidWins = 0, 
	DungeonClear_Part1 = false, DungeonClear_Part2 = false, DungeonClear_Part3 = false,
	DungeonClear_Part4 = false, DungeonClear_Part5 = false, DungeonClear_Part6 = false,

	AutoSell_Common = false, AutoSell_Uncommon = false, AutoSell_Rare = false, AutoSell_Legendary = false, AutoSell_Mythical = false,

	UniverseModifier = "None", StandPity = 0, TraitPity = 0, ShopPity = 0, ClaimedSupporterReward = false,

	Gang = "None", GangRole = "None", LastOnline = os.time(),

	LastWorldBossHour = -1,

	StandLocked = false, StyleLocked = false, IsMuted = false, LockedItems = "",

	Has2xBattleSpeed = false, HasAutoTraining = false, Has2xInventory = false,
	Has2xDropChance = false, HasStandSlot2 = false, HasStandSlot3 = false,
	HasAutoRoll = false, HasHorseNamePass = false,

	HasStyleSlot2 = false, HasStyleSlot3 = false,

	Stats = { Health = 1, Strength = 1, Defense = 1, Speed = 1, Stamina = 1, Willpower = 1 },
	EquippedWeapon = "None", EquippedAccessory = "None",
	StandStats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"},
	StandStatsVal = {Power=0, Speed=0, Range=0, Durability=0, Precision=0, Potential=0},
	ShopStock = "", ShopRefreshTime = 0, RedeemedCodes = "",

	StoredStand1 = "None", StoredStand1_Trait = "None",
	StoredStand2 = "None", StoredStand2_Trait = "None",
	StoredStand3 = "None", StoredStand3_Trait = "None",
	StoredStand4 = "None", StoredStand4_Trait = "None",
	StoredStand5 = "None", StoredStand5_Trait = "None",

	StoredStyle1 = "None",
	StoredStyle2 = "None",
	StoredStyle3 = "None",

	HorseName = "", HorseSpeed = 1, HorseEndurance = 1, HorseTrait = "None",
	HorseUpgradeEnd = 0, HorseUpgradeStat = "None"
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
	for standStat, rank in pairs(savedData.StandStats) do player:SetAttribute("Stand_"..standStat, rank) end
	for standStatVal, val in pairs(savedData.StandStatsVal) do player:SetAttribute("Stand_"..standStatVal.."_Val", val) end

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
		DungeonClear_Part1 = player:GetAttribute("DungeonClear_Part1") or false,
		DungeonClear_Part2 = player:GetAttribute("DungeonClear_Part2") or false,
		DungeonClear_Part3 = player:GetAttribute("DungeonClear_Part3") or false,
		DungeonClear_Part4 = player:GetAttribute("DungeonClear_Part4") or false,
		DungeonClear_Part5 = player:GetAttribute("DungeonClear_Part5") or false,
		DungeonClear_Part6 = player:GetAttribute("DungeonClear_Part6") or false,

		AutoSell_Common = player:GetAttribute("AutoSell_Common") or false,
		AutoSell_Uncommon = player:GetAttribute("AutoSell_Uncommon") or false,
		AutoSell_Rare = player:GetAttribute("AutoSell_Rare") or false,
		AutoSell_Legendary = player:GetAttribute("AutoSell_Legendary") or false,
		AutoSell_Mythical = player:GetAttribute("AutoSell_Mythical") or false,

		UniverseModifier = player:GetAttribute("UniverseModifier") or "None",
		StandPity = player:GetAttribute("StandPity") or 0,
		TraitPity = player:GetAttribute("TraitPity") or 0,
		ShopPity = player:GetAttribute("ShopPity") or 0,
		ClaimedSupporterReward = player:GetAttribute("ClaimedSupporterReward") or false,

		Gang = player:GetAttribute("Gang") or "None",
		GangRole = player:GetAttribute("GangRole") or "None",
		LastOnline = player:GetAttribute("LastOnline"), 

		LastWorldBossHour = player:GetAttribute("LastWorldBossHour") or -1,

		StandLocked = player:GetAttribute("StandLocked") or false,
		StyleLocked = player:GetAttribute("StyleLocked") or false,
		IsMuted = player:GetAttribute("IsMuted") or false,
		LockedItems = player:GetAttribute("LockedItems") or "",

		Has2xBattleSpeed = player:GetAttribute("Has2xBattleSpeed") or false,
		HasAutoTraining = player:GetAttribute("HasAutoTraining") or false,
		Has2xInventory = player:GetAttribute("Has2xInventory") or false,
		Has2xDropChance = player:GetAttribute("Has2xDropChance") or false,
		HasStandSlot2 = player:GetAttribute("HasStandSlot2") or false,
		HasStandSlot3 = player:GetAttribute("HasStandSlot3") or false,
		HasAutoRoll = player:GetAttribute("HasAutoRoll") or false,
		HasHorseNamePass = player:GetAttribute("HasHorseNamePass") or false,

		HasStyleSlot2 = player:GetAttribute("HasStyleSlot2") or false,
		HasStyleSlot3 = player:GetAttribute("HasStyleSlot3") or false,

		Stand = player:GetAttribute("Stand"), StandTrait = player:GetAttribute("StandTrait") or "None",
		FightingStyle = player:GetAttribute("FightingStyle"),
		EquippedWeapon = player:GetAttribute("EquippedWeapon"), EquippedAccessory = player:GetAttribute("EquippedAccessory"),
		ShopStock = player:GetAttribute("ShopStock"), ShopRefreshTime = player:GetAttribute("ShopRefreshTime"),
		RedeemedCodes = player:GetAttribute("RedeemedCodes") or "",

		StoredStand1 = player:GetAttribute("StoredStand1") or "None",
		StoredStand1_Trait = player:GetAttribute("StoredStand1_Trait") or "None",
		StoredStand2 = player:GetAttribute("StoredStand2") or "None",
		StoredStand2_Trait = player:GetAttribute("StoredStand2_Trait") or "None",
		StoredStand3 = player:GetAttribute("StoredStand3") or "None",
		StoredStand3_Trait = player:GetAttribute("StoredStand3_Trait") or "None",
		StoredStand4 = player:GetAttribute("StoredStand4") or "None",
		StoredStand4_Trait = player:GetAttribute("StoredStand4_Trait") or "None",
		StoredStand5 = player:GetAttribute("StoredStand5") or "None",
		StoredStand5_Trait = player:GetAttribute("StoredStand5_Trait") or "None",

		StoredStyle1 = player:GetAttribute("StoredStyle1") or "None",
		StoredStyle2 = player:GetAttribute("StoredStyle2") or "None",
		StoredStyle3 = player:GetAttribute("StoredStyle3") or "None",

		HorseName = player:GetAttribute("HorseName") or "",
		HorseSpeed = player:GetAttribute("HorseSpeed") or 1,
		HorseEndurance = player:GetAttribute("HorseEndurance") or 1,
		HorseTrait = player:GetAttribute("HorseTrait") or "None",
		HorseUpgradeEnd = player:GetAttribute("HorseUpgradeEnd") or 0,
		HorseUpgradeStat = player:GetAttribute("HorseUpgradeStat") or "None",

		Stats = { Health=player:GetAttribute("Health"), Strength=player:GetAttribute("Strength"), Defense=player:GetAttribute("Defense"), Speed=player:GetAttribute("Speed"), Stamina=player:GetAttribute("Stamina"), Willpower=player:GetAttribute("Willpower") },
		StandStats = { Power=player:GetAttribute("Stand_Power"), Speed=player:GetAttribute("Stand_Speed"), Range=player:GetAttribute("Stand_Range"), Durability=player:GetAttribute("Stand_Durability"), Precision=player:GetAttribute("Stand_Precision"), Potential=player:GetAttribute("Stand_Potential") },
		StandStatsVal = { Power=player:GetAttribute("Stand_Power_Val"), Speed=player:GetAttribute("Stand_Speed_Val"), Range=player:GetAttribute("Stand_Range_Val"), Durability=player:GetAttribute("Stand_Durability_Val"), Precision=player:GetAttribute("Stand_Precision_Val"), Potential=player:GetAttribute("Stand_Potential_Val") }
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
	local clampStats = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", "Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}

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
	VerifyPass(1733160695, "HasStandSlot2")
	VerifyPass(1732844091, "HasStandSlot3")
	VerifyPass(1746853452, "HasStyleSlot2") 
	VerifyPass(1745969849, "HasStyleSlot3")
	VerifyPass(1749484465, "HasAutoRoll")
	VerifyPass(1749586333, "HasHorseNamePass")

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