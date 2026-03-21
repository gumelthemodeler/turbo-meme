-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local BountyData = require(ReplicatedStorage:WaitForChild("BountyData"))

local GameDataStore = DataStoreService:GetDataStore("AoT_Data_V2") 

local RemotesFolder = ReplicatedStorage:FindFirstChild("Network")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Network"
	RemotesFolder.Parent = ReplicatedStorage
end

local requiredRemotes = {
	"ToggleMute", "CombatAction", "CombatUpdate", "PrestigeEvent",
	"NotificationEvent", "DungeonUpdate", "WorldBossUpdate", "WorldBossAction", 
	"RaidAction", "RaidUpdate", "ToggleTraining", "ShopAction", "ShopUpdate",
	"UpgradeStat", "TrainAction", "EquipItem", "SellItem", "AutoSell", "AdminCommand",
	"GachaRoll", "GachaRollAuto", "GachaResult", "AwakenAction", "ManageStorage", "VIPFreeReroll", "RedeemCode", "ClaimBounty"
}

for _, remoteName in ipairs(requiredRemotes) do
	if not RemotesFolder:FindFirstChild(remoteName) then
		local re = Instance.new("RemoteEvent")
		re.Name = remoteName
		re.Parent = RemotesFolder
	end
end

if not RemotesFolder:FindFirstChild("GetShopData") then
	local rf = Instance.new("RemoteFunction")
	rf.Name = "GetShopData"
	rf.Parent = RemotesFolder
end

-- [[ BOUNTY CLAIM LOGIC ]]
RemotesFolder.ClaimBounty.OnServerEvent:Connect(function(player, bType)
	local claimedAttr = bType .. "_Claimed"
	if player:GetAttribute(claimedAttr) then return end

	local prog = player:GetAttribute(bType .. "_Prog") or 0
	local max = player:GetAttribute(bType .. "_Max") or 1

	if prog >= max then
		player:SetAttribute(claimedAttr, true)
		if string.sub(bType, 1, 1) == "D" then
			local dews = player:GetAttribute(bType .. "_Reward") or 500
			player.leaderstats.Dews.Value += dews
		else
			local rType = player:GetAttribute(bType .. "_RewardType")
			local rAmt = player:GetAttribute(bType .. "_RewardAmt")
			local safeName = rType:gsub("[^%w]", "") .. "Count"
			player:SetAttribute(safeName, (player:GetAttribute(safeName) or 0) + rAmt)
		end
	end
end)

local ActiveCodes = {
	["RELEASE"] = { Dews = 5000 },
	["GIRTHBENDER"] = { Item = "Spinal Fluid Syringe", Amount = 1 },
	["TITAN"] = { Item = "Standard Titan Serum", Amount = 3 }
}

RemotesFolder.RedeemCode.OnServerEvent:Connect(function(player, codeStr)
	local codeKey = string.upper(codeStr)
	local codeData = ActiveCodes[codeKey]
	if not codeData then return end
	local redeemedStr = player:GetAttribute("RedeemedCodes") or ""
	if string.find(redeemedStr, "%[" .. codeKey .. "%]") then return end 
	player:SetAttribute("RedeemedCodes", redeemedStr .. "[" .. codeKey .. "]")
	if codeData.Dews then player.leaderstats.Dews.Value += codeData.Dews end
	if codeData.Item then
		local safeName = codeData.Item:gsub("[^%w]", "") .. "Count"
		player:SetAttribute(safeName, (player:GetAttribute(safeName) or 0) + codeData.Amount)
	end
end)

RemotesFolder.PrestigeEvent.OnServerEvent:Connect(function(player)
	if player.leaderstats.Prestige.Value >= 10 then return end
	if (player:GetAttribute("CurrentPart") or 1) > 7 then
		player.leaderstats.Prestige.Value += 1
		player:SetAttribute("CurrentPart", 1); player:SetAttribute("CurrentWave", 1); player:SetAttribute("XP", 0)
		local resetStats = {"Health", "Strength", "Defense", "Speed", "Gas", "Resolve"}
		for _, s in ipairs(resetStats) do player:SetAttribute(s, 10) end
	end
end)

RemotesFolder.UpgradeStat.OnServerEvent:Connect(function(player, statName, amount)
	local prestige = player.leaderstats.Prestige.Value
	local statCap = GameData.GetStatCap(prestige)
	local currentStat = player:GetAttribute(statName) or 1
	local currentXP = player:GetAttribute("XP") or 0
	local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
	local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)
	local targetAdd = (amount == "MAX") and 9999 or amount
	local added, cost = 0, 0
	for i = 0, targetAdd - 1 do
		if currentStat + added >= statCap then break end
		local stepCost = GameData.CalculateStatCost(currentStat + added, base, prestige)
		if currentXP >= stepCost then currentXP -= stepCost; cost += stepCost; added += 1 else break end
	end
	if added > 0 then player:SetAttribute("XP", currentXP); player:SetAttribute(statName, currentStat + added) end
end)

RemotesFolder.TrainAction.OnServerEvent:Connect(function(player, comboBonus)
	local prestige = player.leaderstats.Prestige.Value
	local totalStats = (player:GetAttribute("Strength") or 10) + (player:GetAttribute("Defense") or 10) + (player:GetAttribute("Speed") or 10) + (player:GetAttribute("Resolve") or 10)
	local baseXP = math.floor(1 + math.sqrt(totalStats) + (prestige * 2))
	local xpGain = math.floor(baseXP * (1 + (comboBonus or 0)))
	if player:GetAttribute("HasDoubleXP") then xpGain *= 2 end
	player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)
end)

task.spawn(function()
	while true do
		task.wait(1.5) 
		for _, player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("HasAutoTrain") then
				local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
				local totalStats = (player:GetAttribute("Strength") or 10) + (player:GetAttribute("Defense") or 10) + (player:GetAttribute("Speed") or 10) + (player:GetAttribute("Resolve") or 10)
				local baseXP = math.max(1, math.floor((1 + math.sqrt(totalStats) + (prestige * 2)) * 0.25))
				if player:GetAttribute("HasDoubleXP") then baseXP *= 2 end
				if player:GetAttribute("HasVIP") then baseXP = math.floor(baseXP * 1.25) end
				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + baseXP)
			end
		end
	end
end)

RemotesFolder.VIPFreeReroll.OnServerEvent:Connect(function(player)
	if not player:GetAttribute("HasVIP") then return end
	local lastRoll = player:GetAttribute("LastFreeReroll") or 0
	local now = os.time()
	if now - lastRoll >= 86400 then
		player:SetAttribute("LastFreeReroll", now)
		player:SetAttribute("PersonalShopSeed", math.random(1, 9999999))
		player:SetAttribute("ShopSeedTime", math.floor(os.time() / 600))
	end
end)

RemotesFolder.EquipItem.OnServerEvent:Connect(function(player, itemName)
	local safeName = itemName:gsub("[^%w]", "") .. "Count"
	if (player:GetAttribute(safeName) or 0) > 0 then
		local itemInfo = ItemData.Equipment[itemName]
		if itemInfo then
			if itemInfo.Type == "Weapon" then player:SetAttribute("EquippedWeapon", itemName); player:SetAttribute("FightingStyle", itemInfo.Style or "None")
			elseif itemInfo.Type == "Accessory" then player:SetAttribute("EquippedAccessory", itemName) end
		end
	end
end)

local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500 }

RemotesFolder.SellItem.OnServerEvent:Connect(function(player, itemName)
	local safeName = itemName:gsub("[^%w]", "") .. "Count"
	local count = player:GetAttribute(safeName) or 0
	if count > 0 then
		local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		if iData then
			local val = SellValues[iData.Rarity or "Common"] or 10
			player:SetAttribute(safeName, count - 1)
			player.leaderstats.Dews.Value += val
			if (count - 1) == 0 then
				if player:GetAttribute("EquippedWeapon") == itemName then player:SetAttribute("EquippedWeapon", "None"); player:SetAttribute("FightingStyle", "None") end
				if player:GetAttribute("EquippedAccessory") == itemName then player:SetAttribute("EquippedAccessory", "None") end
			end
		end
	end
end)

RemotesFolder.AutoSell.OnServerEvent:Connect(function(player, targetRarity)
	if targetRarity == "Legendary" or targetRarity == "Mythical" then return end
	local totalEarned = 0
	for iName, iData in pairs(ItemData.Equipment) do
		if (iData.Rarity or "Common") == targetRarity then
			local safeName = iName:gsub("[^%w]", "") .. "Count"
			local count = player:GetAttribute(safeName) or 0
			if count > 0 then
				totalEarned += count * (SellValues[targetRarity] or 10)
				player:SetAttribute(safeName, 0)
				if player:GetAttribute("EquippedWeapon") == iName then player:SetAttribute("EquippedWeapon", "None"); player:SetAttribute("FightingStyle", "None") end
				if player:GetAttribute("EquippedAccessory") == iName then player:SetAttribute("EquippedAccessory", "None") end
			end
		end
	end
	if totalEarned > 0 then player.leaderstats.Dews.Value += totalEarned end
end)

RemotesFolder.AwakenAction.OnServerEvent:Connect(function(player, aType)
	if aType == "Titan" then
		if player:GetAttribute("Titan") == "Attack Titan" and (player:GetAttribute("YmirsClayFragmentCount") or 0) > 0 then
			player:SetAttribute("YmirsClayFragmentCount", player:GetAttribute("YmirsClayFragmentCount") - 1)
			player:SetAttribute("Titan", "Founding Titan")
		end
	elseif aType == "Clan" then
		if player:GetAttribute("Clan") == "Ackerman" and (player:GetAttribute("AckermanAwakeningPillCount") or 0) > 0 then
			player:SetAttribute("AckermanAwakeningPillCount", player:GetAttribute("AckermanAwakeningPillCount") - 1)
			player:SetAttribute("Clan", "Awakened Ackerman")
		end
	end
end)

RemotesFolder.ManageStorage.OnServerEvent:Connect(function(player, gType, slotNum)
	if type(slotNum) ~= "number" or slotNum < 1 or slotNum > 6 then return end
	if slotNum > 3 then
		if gType == "Titan" and not player:GetAttribute("HasTitanVault") then return end
		if gType == "Clan" and not player:GetAttribute("HasClanVault") then return end
	end
	local current = player:GetAttribute(gType) or "None"
	local slotKey = gType .. "_Slot" .. slotNum
	local stored = player:GetAttribute(slotKey) or "None"
	player:SetAttribute(gType, stored); player:SetAttribute(slotKey, current)
end)

-- (GachaRoll & GachaRollAuto omitted here for length, keep your existing ones!)

RemotesFolder.AdminCommand.OnServerEvent:Connect(function(player, command, targetName, args)
	if player.UserId ~= 4068160397 then player:Kick("Unauthorized Admin Access"); return end
	local targetPlayer = player
	if targetName and targetName ~= "" and targetName:lower() ~= "me" then
		targetPlayer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if string.find(p.Name:lower(), "^" .. targetName:lower()) then targetPlayer = p; break end
		end
	end
	if not targetPlayer then return end

	if command == "SetXP" then targetPlayer:SetAttribute("XP", tonumber(args) or 0)
	elseif command == "SetDews" then targetPlayer.leaderstats.Dews.Value = tonumber(args) or 0
	elseif command == "UnlockAllParts" then targetPlayer:SetAttribute("CurrentPart", 7); targetPlayer:SetAttribute("CurrentWave", 1)
	elseif command == "GiveItem" then
		local safeName = args.Item:gsub("[^%w]", "") .. "Count"
		targetPlayer:SetAttribute(safeName, (targetPlayer:GetAttribute(safeName) or 0) + (tonumber(args.Amount) or 1))
	elseif command == "MaxStats" then
		local p = targetPlayer.leaderstats.Prestige.Value; local c = GameData.GetStatCap(p)
		local statsToMax = {"Health", "Strength", "Defense", "Speed", "Gas", "Resolve", "Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}
		for _, s in ipairs(statsToMax) do targetPlayer:SetAttribute(s, c) end
	elseif command == "MaxPrestige" then targetPlayer.leaderstats.Prestige.Value = 10
	elseif command == "SetTitan" then targetPlayer:SetAttribute("Titan", tostring(args))
	elseif command == "SetClan" then targetPlayer:SetAttribute("Clan", tostring(args))
	elseif command == "WipePlayer" then
		targetPlayer.leaderstats.Prestige.Value = 0; targetPlayer.leaderstats.Dews.Value = 0; targetPlayer.leaderstats.Elo.Value = 1000
		for k, _ in pairs(targetPlayer:GetAttributes()) do targetPlayer:SetAttribute(k, nil) end
		local DefaultData = { Prestige = 0, CurrentPart = 1, CurrentMission = 1, CurrentWave = 1, XP = 0, Dews = 0, Elo = 1000, Titan = "None", FightingStyle = "None", Clan = "None", TitanPity = 0, ClanPity = 0, EquippedWeapon = "None", EquippedAccessory = "None", Health = 10, Strength = 10, Defense = 10, Speed = 10, Gas = 10, Resolve = 10, LastFreeReroll = 0, RedeemedCodes = "" }
		for k, v in pairs(DefaultData) do if k ~= "Prestige" and k ~= "Dews" and k ~= "Elo" then targetPlayer:SetAttribute(k, v) end end
	end
end)

local DefaultData = {
	Prestige = 0, CurrentPart = 1, CurrentMission = 1, CurrentWave = 1, XP = 0, Dews = 0, Elo = 1000,
	Titan = "None", FightingStyle = "None", Clan = "None", TitanPity = 0, ClanPity = 0,
	EquippedWeapon = "None", EquippedAccessory = "None",
	Health = 10, Strength = 10, Defense = 10, Speed = 10, Gas = 10, Resolve = 10, LastFreeReroll = 0, RedeemedCodes = "",

	-- Default Bounties init values
	LastDailyReset = 0, LastWeeklyReset = 0,
	D1_Task = "None", D1_Desc = "None", D1_Prog = 0, D1_Max = 1, D1_Reward = 0, D1_Claimed = false,
	D2_Task = "None", D2_Desc = "None", D2_Prog = 0, D2_Max = 1, D2_Reward = 0, D2_Claimed = false,
	D3_Task = "None", D3_Desc = "None", D3_Prog = 0, D3_Max = 1, D3_Reward = 0, D3_Claimed = false,
	W1_Task = "None", W1_Desc = "None", W1_Prog = 0, W1_Max = 1, W1_RewardType = "None", W1_RewardAmt = 1, W1_Claimed = false
}

local function SetupLeaderstats(player, savedData)
	local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player
	local prestige = Instance.new("IntValue"); prestige.Name = "Prestige"; prestige.Value = savedData.Prestige or DefaultData.Prestige; prestige.Parent = leaderstats
	local dews = Instance.new("IntValue"); dews.Name = "Dews"; dews.Value = savedData.Dews or DefaultData.Dews; dews.Parent = leaderstats
	local elo = Instance.new("IntValue"); elo.Name = "Elo"; elo.Value = savedData.Elo or DefaultData.Elo; elo.Parent = leaderstats

	for key, val in pairs(DefaultData) do
		if key ~= "Prestige" and key ~= "Dews" and key ~= "Elo" then player:SetAttribute(key, savedData[key] or val) end
	end
	for i = 1, 6 do
		player:SetAttribute("Titan_Slot" .. i, savedData["Titan_Slot"..i] or "None")
		player:SetAttribute("Clan_Slot" .. i, savedData["Clan_Slot"..i] or "None")
	end

	-- Dynamically load all saved bounty attributes
	for k, v in pairs(savedData) do
		if string.sub(k, 1, 2) == "D1" or string.sub(k, 1, 2) == "D2" or string.sub(k, 1, 2) == "D3" or string.sub(k, 1, 2) == "W1" or string.match(k, "Reset") then
			player:SetAttribute(k, v)
		end
	end

	if player:GetAttribute("EquippedWeapon") == "None" and (player:GetAttribute("UltrahardSteelBladesCount") or 0) > 0 then
		player:SetAttribute("EquippedWeapon", "Ultrahard Steel Blades"); player:SetAttribute("FightingStyle", "Ultrahard Steel Blades")
	end
end

local function RollBounties(player)
	local now = os.time()
	local currentDay = math.floor(now / 86400)
	local currentWeek = math.floor(now / 604800)

	if player:GetAttribute("LastDailyReset") ~= currentDay then
		player:SetAttribute("LastDailyReset", currentDay)

		local available = {}
		for _, v in ipairs(BountyData.Dailies) do table.insert(available, v) end

		for i = 1, 3 do
			if #available == 0 then break end
			local idx = math.random(1, #available)
			local b = available[idx]
			table.remove(available, idx)

			local target = math.random(b.Min, b.Max)
			player:SetAttribute("D"..i.."_Task", b.Task)
			player:SetAttribute("D"..i.."_Desc", string.format(b.Desc, target))
			player:SetAttribute("D"..i.."_Prog", 0)
			player:SetAttribute("D"..i.."_Max", target)
			player:SetAttribute("D"..i.."_Reward", b.Reward)
			player:SetAttribute("D"..i.."_Claimed", false)
		end
	end

	if player:GetAttribute("LastWeeklyReset") ~= currentWeek then
		player:SetAttribute("LastWeeklyReset", currentWeek)
		local b = BountyData.Weeklies[math.random(1, #BountyData.Weeklies)]
		local target = math.random(b.Min, b.Max)

		player:SetAttribute("W1_Task", b.Task)
		player:SetAttribute("W1_Desc", string.format(b.Desc, target))
		player:SetAttribute("W1_Prog", 0)
		player:SetAttribute("W1_Max", target)
		player:SetAttribute("W1_RewardType", b.RewardType)
		player:SetAttribute("W1_RewardAmt", b.RewardAmt)
		player:SetAttribute("W1_Claimed", false)
	end
end

local function LoadPlayer(player)
	local success, savedData = pcall(function() return GameDataStore:GetAsync(player.UserId) end)

	for _, gp in ipairs(ItemData.Gamepasses) do
		local hasPass = false
		pcall(function() hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.ID) end)
		if player.UserId == 4068160397 then hasPass = true end
		player:SetAttribute("Has" .. gp.Key, hasPass)
	end

	SetupLeaderstats(player, (success and savedData) and savedData or DefaultData)
	RollBounties(player) -- Checks and assigns bounties on load!
end

Players.PlayerAdded:Connect(LoadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() LoadPlayer(player) end) end

Players.PlayerRemoving:Connect(function(player)
	if not player:FindFirstChild("leaderstats") then return end
	local dataToSave = {
		Prestige = player.leaderstats.Prestige.Value, Dews = player.leaderstats.Dews.Value, Elo = player.leaderstats.Elo.Value,
		CurrentPart = player:GetAttribute("CurrentPart"), CurrentMission = player:GetAttribute("CurrentMission"), CurrentWave = player:GetAttribute("CurrentWave"),
		XP = player:GetAttribute("XP"), Titan = player:GetAttribute("Titan"), Clan = player:GetAttribute("Clan"),
		TitanPity = player:GetAttribute("TitanPity"), ClanPity = player:GetAttribute("ClanPity"), LastFreeReroll = player:GetAttribute("LastFreeReroll"),
		FightingStyle = player:GetAttribute("FightingStyle"), EquippedWeapon = player:GetAttribute("EquippedWeapon"), EquippedAccessory = player:GetAttribute("EquippedAccessory"),
		Health = player:GetAttribute("Health"), Strength = player:GetAttribute("Strength"), Defense = player:GetAttribute("Defense"), Speed = player:GetAttribute("Speed"), Gas = player:GetAttribute("Gas"), Resolve = player:GetAttribute("Resolve"),
		RedeemedCodes = player:GetAttribute("RedeemedCodes")
	}
	for i = 1, 6 do dataToSave["Titan_Slot"..i] = player:GetAttribute("Titan_Slot"..i); dataToSave["Clan_Slot"..i] = player:GetAttribute("Clan_Slot"..i) end

	-- Dynamically save all bounty progress
	for k, v in pairs(player:GetAttributes()) do
		if string.sub(k, 1, 2) == "D1" or string.sub(k, 1, 2) == "D2" or string.sub(k, 1, 2) == "D3" or string.sub(k, 1, 2) == "W1" or string.match(k, "Reset") then
			dataToSave[k] = v
		end
	end

	pcall(function() GameDataStore:SetAsync(player.UserId, dataToSave) end)
end)