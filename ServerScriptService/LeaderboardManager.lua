-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local LeaderboardAction = Network:WaitForChild("LeaderboardAction")
local LeaderboardUpdate = Network:WaitForChild("LeaderboardUpdate")

-- NEW AOT DATASTORES
local GameDataStore = DataStoreService:GetDataStore("AoT_Incremental_V1")
local ClanStore = DataStoreService:GetDataStore("AoT_Clans_V1") 

local ODS_Prestige = DataStoreService:GetOrderedDataStore("AoT_LB_Prestige")
local ODS_Endless = DataStoreService:GetOrderedDataStore("AoT_LB_Endless")
local ODS_PlayTime = DataStoreService:GetOrderedDataStore("AoT_LB_PlayTime")
local ODS_Elo = DataStoreService:GetOrderedDataStore("AoT_LB_Elo")
local ODS_Power = DataStoreService:GetOrderedDataStore("AoT_LB_TotalPower")
local ODS_RaidWins = DataStoreService:GetOrderedDataStore("AoT_LB_RaidWins")

local ODS_ClanRep = DataStoreService:GetOrderedDataStore("AoT_ClanLB_Rep_V1")
local ODS_ClanTreasury = DataStoreService:GetOrderedDataStore("AoT_ClanLB_Dews_V1")
local ODS_ClanPrestige = DataStoreService:GetOrderedDataStore("AoT_ClanLB_Prestige_V1")
local ODS_ClanElo = DataStoreService:GetOrderedDataStore("AoT_ClanLB_Elo_V1")
local ODS_ClanRaids = DataStoreService:GetOrderedDataStore("AoT_ClanLB_Raids_V1")

local Cache = { 
	Prestige = {}, Endless = {}, PlayTime = {}, Elo = {}, Power = {}, RaidWins = {},
	ClanRep = {}, ClanTreasury = {}, ClanPrestige = {}, ClanElo = {}, ClanRaids = {}
}
local nameCache = {}

local PlayerProfileCache = {}
local ClanProfileCache = {}
local ProfileQueue = {}
local InQueue = {}

local function GetPlayerName(userId)
	if nameCache[userId] then return nameCache[userId] end
	local success, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	if success then 
		nameCache[userId] = name
		return name 
	else 
		return "Player_" .. userId 
	end
end

local function GetEquipBonus(player, statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0

	if ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.WeaponBonuses and GameData.WeaponBonuses[style] and GameData.WeaponBonuses[style][statName] then bonus += GameData.WeaponBonuses[style][statName] end

	return bonus
end

local function UpdatePlayerOnLeaderboards(player)
	local userId = player.UserId
	pcall(function()
		if player:FindFirstChild("leaderstats") then
			ODS_Prestige:SetAsync(userId, player.leaderstats.Prestige.Value)
			ODS_Elo:SetAsync(userId, player.leaderstats.Elo.Value)
		end
		ODS_Endless:SetAsync(userId, player:GetAttribute("EndlessHighScore") or 0)
		ODS_PlayTime:SetAsync(userId, player:GetAttribute("PlayTime") or 0)
		ODS_RaidWins:SetAsync(userId, player:GetAttribute("RaidWins") or 0)

		local baseStr = player:GetAttribute("Strength") or 1
		local baseTitanPower = player:GetAttribute("Titan_Power_Val") or 0
		local bonusStr = GetEquipBonus(player, "Strength")
		local bonusTitanPower = GetEquipBonus(player, "Titan_Power")

		local totalPower = math.floor(baseStr + baseTitanPower + bonusStr + bonusTitanPower)
		ODS_Power:SetAsync(userId, totalPower)
	end)
end

task.spawn(function()
	while task.wait(300) do 
		for _, player in ipairs(Players:GetPlayers()) do
			UpdatePlayerOnLeaderboards(player)
			task.wait(0.5) 
		end
	end
end)

Players.PlayerRemoving:Connect(UpdatePlayerOnLeaderboards)

local function GetPlayerProfile(userId)
	if PlayerProfileCache[userId] and os.time() - PlayerProfileCache[userId].LastUpdate < 1800 then
		return PlayerProfileCache[userId]
	end

	local p = Players:GetPlayerByUserId(userId)
	local data

	if p and p:FindFirstChild("leaderstats") then
		data = {
			Prestige = p.leaderstats.Prestige.Value,
			Endless = p:GetAttribute("EndlessHighScore") or 0,
			PlayTime = p:GetAttribute("PlayTime") or 0,
			Elo = p.leaderstats.Elo.Value,
			Power = math.floor((p:GetAttribute("Strength") or 1) + (p:GetAttribute("Titan_Power_Val") or 0) + GetEquipBonus(p, "Strength") + GetEquipBonus(p, "Titan_Power")),
			RaidWins = p:GetAttribute("RaidWins") or 0,
			Icon = "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=150&h=150"
		}
	else
		local s, d = pcall(function() return GameDataStore:GetAsync(userId) end)
		if s and d then
			local pwr = (d.Stats and d.Stats.Strength or 1) + (d.TitanStatsVal and d.TitanStatsVal.Power or 0)
			data = {
				Prestige = d.Prestige or 0, Endless = d.EndlessHighScore or 0, PlayTime = d.PlayTime or 0,
				Elo = d.Elo or 1000, Power = pwr, RaidWins = d.RaidWins or 0,
				Icon = "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=150&h=150"
			}
		else
			data = { Prestige=0, Endless=0, PlayTime=0, Elo=1000, Power=1, RaidWins=0, Icon="rbxthumb://type=AvatarHeadShot&id="..userId.."&w=150&h=150" }
		end
	end

	data.LastUpdate = os.time()
	PlayerProfileCache[userId] = data
	return data
end

local function GetClanProfile(clanName)
	local key = string.lower(clanName)
	if ClanProfileCache[key] and os.time() - ClanProfileCache[key].LastUpdate < 1800 then
		return ClanProfileCache[key]
	end

	local s, d = pcall(function() return ClanStore:GetAsync(key) end)
	local data

	if s and d then
		data = {
			Emblem = d.Emblem or "", Motto = d.Motto or "No motto set.",
			Rep = d.Rep or 0, Treasury = d.Treasury or 0, Prestige = d.TotalPrestige or 0,
			Elo = d.TotalElo or 0, RaidWins = d.RaidWins or 0
		}
	else
		data = { Emblem="", Motto="No motto set.", Rep=0, Treasury=0, Prestige=0, Elo=0, RaidWins=0 }
	end

	data.LastUpdate = os.time()
	ClanProfileCache[key] = data
	return data
end

local function EnqueueProfile(id, isClan)
	local keyStr = tostring(id) .. (isClan and "_C" or "_P")
	if not InQueue[keyStr] then
		InQueue[keyStr] = true
		table.insert(ProfileQueue, {Id = id, IsClan = isClan})
	end
end

task.spawn(function()
	while task.wait(1) do
		if #ProfileQueue > 0 then
			local job = table.remove(ProfileQueue, 1)
			InQueue[tostring(job.Id) .. (job.IsClan and "_C" or "_P")] = nil
			pcall(function()
				if job.IsClan then GetClanProfile(job.Id) else GetPlayerProfile(job.Id) end
			end)
		end
	end
end)

local function RefreshCache()
	local function fetch(ods, category, isClan)
		local success, pages = pcall(function() return ods:GetSortedAsync(false, 100) end)
		if success and pages then
			local data = pages:GetCurrentPage()
			local formatted = {}
			for rank, entry in ipairs(data) do
				local displayName = isClan and entry.key or GetPlayerName(entry.key)
				table.insert(formatted, { Rank = rank, Id = entry.key, Name = displayName, Value = entry.value })

				local cacheTable = isClan and ClanProfileCache or PlayerProfileCache
				local cacheKey = isClan and string.lower(entry.key) or entry.key
				if not cacheTable[cacheKey] or os.time() - cacheTable[cacheKey].LastUpdate > 1800 then
					EnqueueProfile(entry.key, isClan)
				end
			end
			Cache[category] = formatted
		end
	end

	fetch(ODS_Prestige, "Prestige", false)
	fetch(ODS_Endless, "Endless", false)
	fetch(ODS_PlayTime, "PlayTime", false)
	fetch(ODS_Elo, "Elo", false)
	fetch(ODS_Power, "Power", false)
	fetch(ODS_RaidWins, "RaidWins", false)

	fetch(ODS_ClanRep, "ClanRep", true)
	fetch(ODS_ClanTreasury, "ClanTreasury", true)
	fetch(ODS_ClanPrestige, "ClanPrestige", true)
	fetch(ODS_ClanElo, "ClanElo", true)
	fetch(ODS_ClanRaids, "ClanRaids", true)
end

task.spawn(function()
	while true do
		RefreshCache()
		task.wait(600) 
	end
end)

LeaderboardAction.OnServerEvent:Connect(function(player, category)
	if Cache[category] then
		local isClan = string.match(category, "^Clan") ~= nil
		local payload = {}

		for _, entry in ipairs(Cache[category]) do
			local enriched = { Rank = entry.Rank, Name = entry.Name, Value = entry.Value, Id = entry.Id }
			local cacheKey = isClan and string.lower(entry.Id) or entry.Id
			local profile = (isClan and ClanProfileCache[cacheKey]) or (not isClan and PlayerProfileCache[cacheKey])

			if profile then
				enriched.Profile = profile
			else
				if isClan then
					enriched.Profile = { Emblem="", Motto="Loading...", Rep=0, Treasury=0, Prestige=0, Elo=0, RaidWins=0 }
				else
					enriched.Profile = { Icon="rbxthumb://type=AvatarHeadShot&id="..entry.Id.."&w=150&h=150", Prestige=0, Endless=0, PlayTime=0, Elo=1000, Power=0, RaidWins=0 }
				end
			end
			table.insert(payload, enriched)
		end

		LeaderboardUpdate:FireClient(player, category, payload)
	end
end)