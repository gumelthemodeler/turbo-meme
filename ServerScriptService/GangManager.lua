-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local GangStore = DataStoreService:GetDataStore("Jojo_Gangs_V3") 

local ODS_GangRep = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Rep_V3")
local ODS_GangTreasury = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Yen_V3")
local ODS_GangPrestige = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Prestige_V3")
local ODS_GangElo = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Elo_V3")
local ODS_GangRaids = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Raids_V3")

local GangAction = Network:WaitForChild("GangAction")
local GangUpdate = Network:WaitForChild("GangUpdate")

local ActiveGangs = {}
local CachedBrowserList = {} 
local RolePower = { ["Grunt"] = 1, ["Caporegime"] = 2, ["Consigliere"] = 3, ["Boss"] = 4 }

local AdminWipeEvent = ReplicatedStorage:WaitForChild("AdminForceWipeGang")
local ProgressOrderEvent = Instance.new("BindableEvent")
ProgressOrderEvent.Name = "AddGangOrderProgress"
ProgressOrderEvent.Parent = Network

local function GetDictSize(d)
	local c = 0
	if d then for _ in pairs(d) do c += 1 end end
	return c
end

local function GetGangLevel(rep)
	if rep >= 100000 then return 5 end
	if rep >= 50000 then return 4 end
	if rep >= 10000 then return 3 end
	if rep >= 5000 then return 2 end
	if rep >= 1000 then return 1 end
	return 0
end

local function ApplyGangBuffs(player, gangData)
	if not gangData then
		player:SetAttribute("GangYenBoost", 1.0)
		player:SetAttribute("GangXPBoost", 1.0)
		player:SetAttribute("GangLuckBoost", 1.0)
		player:SetAttribute("GangInvBoost", 0)
		player:SetAttribute("GangDmgBoost", 1.0)
		return
	end

	local b = gangData.Buildings or {}
	local yB = 1.0 + ((b.Vault or 0) * 0.05)
	local xB = 1.0 + ((b.Dojo or 0) * 0.05)
	local lB = 1.0 + (b.Shrine or 0)
	local iB = (b.Market or 0) * 5
	local dB = 1.0 + ((b.Armory or 0) * 0.05)

	player:SetAttribute("GangYenBoost", yB)
	player:SetAttribute("GangXPBoost", xB)
	player:SetAttribute("GangLuckBoost", lB)
	player:SetAttribute("GangInvBoost", iB)
	player:SetAttribute("GangDmgBoost", dB)
end

local function RollSingleOrder()
	local pools = {
		{Type = "Kills", Desc = "Defeat 500 Enemies", Target = 500, RewardT = 500000, RewardR = 250},
		{Type = "Dungeons", Desc = "Clear 100 Dungeon Floors", Target = 100, RewardT = 1000000, RewardR = 500},
		{Type = "Raids", Desc = "Defeat 15 Raid Bosses", Target = 15, RewardT = 2000000, RewardR = 1000},
		{Type = "Arena", Desc = "Win 20 Arena Matches", Target = 20, RewardT = 1000000, RewardR = 400},
		{Type = "Yen", Desc = "Spend ¥10,000,000 Total", Target = 10000000, RewardT = 4000000, RewardR = 800}
	}
	local t = pools[math.random(1, #pools)]
	return {Type = t.Type, Desc = t.Desc, Target = t.Target, Progress = 0, RewardT = t.RewardT, RewardR = t.RewardR, Completed = false}
end

local function GenerateRandomOrders()
	local chosen = {}
	for i = 1, 5 do table.insert(chosen, RollSingleOrder()) end
	return chosen
end

local function DistributeOrderLoot(gangData, rarity)
	local pool = {}
	for name, data in pairs(ItemData.Equipment) do if data.Rarity == rarity then table.insert(pool, name) end end
	for name, data in pairs(ItemData.Consumables) do if data.Rarity == rarity then table.insert(pool, name) end end

	if #pool == 0 then return end
	local item = pool[math.random(#pool)]

	for uidStr, _ in pairs(gangData.Members) do
		local p = Players:GetPlayerByUserId(tonumber(uidStr))
		if p then
			local attr = item:gsub("[^%w]", "") .. "Count"
			p:SetAttribute(attr, (p:GetAttribute(attr) or 0) + 1)
			Network.CombatUpdate:FireClient(p, "SystemMessage", "<font color='#FFD700'><b>Gang Order Completed!</b> You received 1x " .. item .. "!</font>")
		end
	end
end

AdminWipeEvent.Event:Connect(function(gangKey)
	local displayToWipe = gangKey
	local gangData = ActiveGangs[gangKey]

	if not gangData then
		local s, d = pcall(function() return GangStore:GetAsync(gangKey) end)
		if s and d and d.Name then displayToWipe = d.Name end
	else
		displayToWipe = gangData.Name
	end

	ActiveGangs[gangKey] = nil 

	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Gang") == gangKey then
			p:SetAttribute("Gang", "None")
			p:SetAttribute("GangRole", "None")
			ApplyGangBuffs(p, nil)
			Network.CombatUpdate:FireClient(p, "SystemMessage", "<font color='#FF5555'>Your gang was completely erased by an Admin.</font>")
			GangUpdate:FireClient(p, "Sync", nil)
		end
	end

	pcall(function()
		GangStore:RemoveAsync(gangKey)
		ODS_GangRep:RemoveAsync(displayToWipe)
		ODS_GangTreasury:RemoveAsync(displayToWipe)
		ODS_GangPrestige:RemoveAsync(displayToWipe)
		ODS_GangElo:RemoveAsync(displayToWipe)
		ODS_GangRaids:RemoveAsync(displayToWipe)
	end)
end)

local function LoadGangData(gangName)
	if not gangName or gangName == "None" then return nil end
	local key = string.lower(gangName)
	if ActiveGangs[key] then return ActiveGangs[key] end
	local success, data = pcall(function() return GangStore:GetAsync(key) end)
	if success and data then
		if data.RenamedTo then return LoadGangData(data.RenamedTo) end

		if not data.Buildings then data.Buildings = { Vault = 0, Dojo = 0, Armory = 0, Shrine = 0, Market = 0 } end
		if not data.Orders then data.Orders = GenerateRandomOrders() end
		if not data.LastOrderReset then data.LastOrderReset = os.time() end
		if not data.PrestigeReq then data.PrestigeReq = 0 end
		if not data.ActiveUpgrade then data.ActiveUpgrade = nil end

		-- FIX: Make sure older gangs have the Requests table properly initialized to prevent client errors
		if not data.Requests then data.Requests = {} end

		ActiveGangs[key] = data
		return data
	end
	return nil
end

local function SaveGangData(gangName, optionalCallback)
	if not gangName or gangName == "None" then return end
	local key = string.lower(gangName)
	local finalDataToSave = nil

	local success, err = pcall(function()
		GangStore:UpdateAsync(key, function(oldData)
			if oldData and oldData.RenamedTo then
				finalDataToSave = oldData
				return oldData
			end

			local dataToSave = oldData or ActiveGangs[key]
			if not dataToSave then return nil end

			if optionalCallback then
				dataToSave = optionalCallback(dataToSave)
			else
				if ActiveGangs[key] then
					dataToSave.TotalPrestige = ActiveGangs[key].TotalPrestige
					dataToSave.TotalElo = ActiveGangs[key].TotalElo
					dataToSave.RaidWins = ActiveGangs[key].RaidWins
				end
			end

			if dataToSave.ActiveUpgrade and os.time() >= dataToSave.ActiveUpgrade.FinishTime then
				local bId = dataToSave.ActiveUpgrade.Id
				dataToSave.Buildings[bId] = (dataToSave.Buildings[bId] or 0) + 1
				dataToSave.ActiveUpgrade = nil
			end

			dataToSave.MemberCount = GetDictSize(dataToSave.Members)

			finalDataToSave = dataToSave
			return dataToSave
		end)
	end)

	if success and finalDataToSave then
		if finalDataToSave.RenamedTo then
			local newKey = finalDataToSave.RenamedTo
			ActiveGangs[key] = nil
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("Gang") == key then p:SetAttribute("Gang", newKey) end
			end
			return
		end

		ActiveGangs[key] = finalDataToSave

		task.spawn(function()
			pcall(function()
				ODS_GangRep:SetAsync(finalDataToSave.Name, finalDataToSave.Rep or 0)
				ODS_GangTreasury:SetAsync(finalDataToSave.Name, finalDataToSave.Treasury or 0)
				ODS_GangPrestige:SetAsync(finalDataToSave.Name, finalDataToSave.TotalPrestige or 0)
				ODS_GangElo:SetAsync(finalDataToSave.Name, finalDataToSave.TotalElo or 0)
				ODS_GangRaids:SetAsync(finalDataToSave.Name, finalDataToSave.RaidWins or 0)
			end)
		end)
	else
		if err then warn("Failed to UpdateAsync Gang Data: ", err) end
	end
end

local function SyncGangToMembers(gangName)
	local key = string.lower(gangName)
	local gang = ActiveGangs[key]
	if not gang then return end
	for userIdStr, _ in pairs(gang.Members) do
		local p = Players:GetPlayerByUserId(tonumber(userIdStr))
		if p then GangUpdate:FireClient(p, "Sync", gang) end
	end
end

local function ElectNewBoss(gangData)
	local bestId = nil; local bestPwr = -1; local bestPrest = -1
	for uId, mem in pairs(gangData.Members) do
		local pwr = RolePower[mem.Role] or 1
		local prest = mem.Prestige or 0
		if pwr > bestPwr then bestPwr = pwr; bestPrest = prest; bestId = uId
		elseif pwr == bestPwr and prest > bestPrest then bestPrest = prest; bestId = uId end
	end
	if bestId then
		gangData.Members[bestId].Role = "Boss"
		local newBoss = Players:GetPlayerByUserId(tonumber(bestId))
		if newBoss then
			newBoss:SetAttribute("GangRole", "Boss")
			Network.CombatUpdate:FireClient(newBoss, "SystemMessage", "<font color='#FFD700'>You have been promoted to Gang Boss!</font>")
		end
		return true
	end
	return false
end

local function RefreshBrowserCache()
	pcall(function()
		local pages = ODS_GangRep:GetSortedAsync(false, 100)
		local data = pages:GetCurrentPage()
		local newList = {}
		for _, entry in ipairs(data) do table.insert(newList, entry.key) end
		CachedBrowserList = newList
	end)
end

task.spawn(function()
	while true do RefreshBrowserCache(); task.wait(60) end
end)

task.spawn(function()
	while task.wait(300) do 
		for gangKey, _ in pairs(ActiveGangs) do
			SaveGangData(gangKey, function(gangData)
				local totalPrestige = 0; local totalElo = 0; local totalRaids = 0

				if not gangData.LastOrderReset or os.time() - gangData.LastOrderReset >= 86400 then
					gangData.Orders = GenerateRandomOrders()
					gangData.LastOrderReset = os.time()
				end

				for uIdStr, memData in pairs(gangData.Members) do
					local livePlayer = Players:GetPlayerByUserId(tonumber(uIdStr))
					if livePlayer then
						local pObj = livePlayer:FindFirstChild("leaderstats")
						if pObj then
							memData.Prestige = pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or memData.Prestige or 0
							memData.Elo = pObj:FindFirstChild("Elo") and pObj.Elo.Value or memData.Elo or 1000
						end
						memData.RaidWins = livePlayer:GetAttribute("RaidWins") or memData.RaidWins or 0
						memData.PlayTime = livePlayer:GetAttribute("PlayTime") or memData.PlayTime or 0
						memData.LastOnline = os.time() 
					end

					memData.Contribution = memData.Contribution or 0
					memData.PlayTime = memData.PlayTime or 0

					totalPrestige += (memData.Prestige or 0)
					totalElo += (memData.Elo or 1000)
					totalRaids += (memData.RaidWins or 0)
				end

				gangData.TotalPrestige = totalPrestige
				gangData.TotalElo = totalElo
				gangData.RaidWins = totalRaids

				return gangData
			end)
		end
	end
end)

ProgressOrderEvent.Event:Connect(function(gangKey, orderType, amount)
	if not gangKey or gangKey == "None" then return end
	local key = string.lower(gangKey)
	local gang = ActiveGangs[key]
	if not gang then return end

	local completedAny = false
	SaveGangData(key, function(gangData)
		for _, ord in ipairs(gangData.Orders) do
			if ord.Type == orderType and not ord.Completed then
				ord.Progress = math.min(ord.Target, ord.Progress + amount)
				if ord.Progress >= ord.Target then
					ord.Completed = true
					gangData.Treasury = (gangData.Treasury or 0) + ord.RewardT
					gangData.Rep = (gangData.Rep or 0) + ord.RewardR
					completedAny = true
					DistributeOrderLoot(gangData, "Legendary") 
				end
			end
		end
		return gangData
	end)
	if completedAny then SyncGangToMembers(key) end
end)

local GangRepEvent = ReplicatedStorage:WaitForChild("AwardGangReputation")
GangRepEvent.Event:Connect(function(userId, amount)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local pGangName = player:GetAttribute("Gang")
	if not pGangName or pGangName == "None" then return end

	SaveGangData(pGangName, function(gangData)
		gangData.Rep = (gangData.Rep or 0) + amount
		return gangData
	end)

	SyncGangToMembers(pGangName)
	ApplyGangBuffs(player, ActiveGangs[string.lower(pGangName)])
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(2) 
		local gName = player:GetAttribute("Gang")
		if gName and gName ~= "None" then
			local data = LoadGangData(gName)
			if data then
				local actualKey = string.lower(data.Name)
				if actualKey ~= string.lower(gName) then
					player:SetAttribute("Gang", actualKey)
					return
				end

				if data.Members[tostring(player.UserId)] then
					local serverRole = data.Members[tostring(player.UserId)].Role
					player:SetAttribute("GangRole", serverRole)
					ApplyGangBuffs(player, data)
					GangUpdate:FireClient(player, "Sync", data)
				else
					player:SetAttribute("Gang", "None")
					player:SetAttribute("GangRole", "None")
					ApplyGangBuffs(player, nil)
					GangUpdate:FireClient(player, "Sync", nil)
				end
			else
				player:SetAttribute("Gang", "None")
				player:SetAttribute("GangRole", "None")
				ApplyGangBuffs(player, nil)
				GangUpdate:FireClient(player, "Sync", nil)
			end
		else
			ApplyGangBuffs(player, nil)
		end
	end)

	player:GetAttributeChangedSignal("Gang"):Connect(function()
		local gName = player:GetAttribute("Gang")
		if gName and gName ~= "None" then
			local data = LoadGangData(gName)
			if data then
				local actualKey = string.lower(data.Name)
				if actualKey ~= string.lower(gName) then
					player:SetAttribute("Gang", actualKey)
					return
				end

				if data.Members[tostring(player.UserId)] then
					local serverRole = data.Members[tostring(player.UserId)].Role
					player:SetAttribute("GangRole", serverRole)
					ApplyGangBuffs(player, data)
					GangUpdate:FireClient(player, "Sync", data)
				else
					player:SetAttribute("Gang", "None")
					player:SetAttribute("GangRole", "None")
					ApplyGangBuffs(player, nil)
					GangUpdate:FireClient(player, "Sync", nil)
					Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You are no longer in a gang.</font>")
				end
			end
		else
			ApplyGangBuffs(player, nil)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local pGangName = player:GetAttribute("Gang")
	if pGangName and pGangName ~= "None" then
		SaveGangData(pGangName, function(gangData)
			if gangData.Members[tostring(player.UserId)] then
				gangData.Members[tostring(player.UserId)].LastOnline = os.time()
				gangData.Members[tostring(player.UserId)].PlayTime = player:GetAttribute("PlayTime") or gangData.Members[tostring(player.UserId)].PlayTime or 0
			end
			return gangData
		end)
	end
end)

GangAction.OnServerEvent:Connect(function(player, action, value, extraValue)
	local pIdStr = tostring(player.UserId)
	local pGangName = player:GetAttribute("Gang")
	local pRole = player:GetAttribute("GangRole")

	if action == "Create" then
		if pGangName ~= "None" then return end
		local yen = player.leaderstats.Yen
		if yen.Value < 500000 then return end

		local displayGangName = tostring(value)
		local gangKey = string.lower(displayGangName)

		if string.len(displayGangName) < 3 or string.len(displayGangName) > 15 then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Name must be 3 to 15 characters long!</font>")
			return
		end
		if not string.match(displayGangName, "^[a-zA-Z0-9 ]+$") then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Alphanumeric characters only!</font>")
			return
		end

		if LoadGangData(gangKey) then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>That gang name is taken!</font>")
			return 
		end

		yen.Value -= 500000

		local newGang = {
			Name = displayGangName, 
			Motto = "We are " .. displayGangName .. "!",
			Emblem = "",
			JoinMode = "Open",
			PrestigeReq = 0,
			OwnerId = player.UserId, OwnerName = player.Name,
			Members = { [pIdStr] = {Name = player.Name, Role = "Boss", Prestige = player.leaderstats.Prestige.Value, LastOnline = os.time(), Contribution = 0, PlayTime = player:GetAttribute("PlayTime") or 0} },
			Requests = {}, MemberCount = 1,
			CustomRoles = { Boss = "Boss", Consigliere = "Consigliere", Caporegime = "Caporegime", Grunt = "Grunt" },
			Rep = 0, Treasury = 0, TotalPrestige = player.leaderstats.Prestige.Value, TotalElo = player.leaderstats.Elo.Value, RaidWins = 0,
			Buildings = { Vault = 0, Dojo = 0, Armory = 0, Shrine = 0, Market = 0 },
			Orders = GenerateRandomOrders(), LastOrderReset = os.time(),
			ActiveUpgrade = nil
		}

		ActiveGangs[gangKey] = newGang
		SaveGangData(gangKey)
		player:SetAttribute("Gang", gangKey)
		player:SetAttribute("GangRole", "Boss")
		SyncGangToMembers(gangKey)

	elseif action == "Rename" then
		if pRole ~= "Boss" then return end
		local yen = player.leaderstats.Yen
		if yen.Value < 500000 then return end

		local displayGangName = tostring(value)
		local newKey = string.lower(displayGangName)
		local oldKey = pGangName

		if string.len(displayGangName) < 3 or string.len(displayGangName) > 15 or not string.match(displayGangName, "^[a-zA-Z0-9 ]+$") then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Invalid name! 3-15 alphanumeric characters only.</font>")
			return
		end

		if LoadGangData(newKey) then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>That gang name is already taken!</font>")
			return 
		end

		yen.Value -= 500000

		local oldData = ActiveGangs[oldKey]
		local oldDisplayName = oldData.Name
		oldData.Name = displayGangName

		local success, err = pcall(function()
			GangStore:SetAsync(newKey, oldData)
			GangStore:SetAsync(oldKey, { RenamedTo = newKey }) 

			ODS_GangRep:RemoveAsync(oldDisplayName)
			ODS_GangTreasury:RemoveAsync(oldDisplayName)
			ODS_GangPrestige:RemoveAsync(oldDisplayName)
			ODS_GangElo:RemoveAsync(oldDisplayName)
			ODS_GangRaids:RemoveAsync(oldDisplayName)
		end)

		if success then
			ActiveGangs[newKey] = oldData
			ActiveGangs[oldKey] = nil

			for uIdStr, _ in pairs(oldData.Members) do
				local mem = Players:GetPlayerByUserId(tonumber(uIdStr))
				if mem then mem:SetAttribute("Gang", newKey) end
			end

			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Successfully renamed Gang to " .. displayGangName .. "!</font>")
			SaveGangData(newKey) 
			SyncGangToMembers(newKey)
		else
			oldData.Name = oldDisplayName
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Database Error while renaming.</font>")
		end

	elseif action == "UpdateMotto" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local newMotto = tostring(value)
		if string.len(newMotto) > 60 then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Motto must be 60 characters or less.</font>")
			return
		end

		SaveGangData(pGangName, function(gangData)
			gangData.Motto = newMotto
			return gangData
		end)
		SyncGangToMembers(pGangName)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Gang Motto successfully updated!</font>")

	elseif action == "UpdateEmblem" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local rawId = tostring(value)
		local digits = string.match(rawId, "%d+")

		if not digits then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Invalid ID! Please provide a valid Roblox Asset ID.</font>")
			return
		end

		local newEmblem = "rbxthumb://type=Asset&id=" .. digits .. "&w=150&h=150"
		SaveGangData(pGangName, function(gangData)
			gangData.Emblem = newEmblem
			return gangData
		end)
		SyncGangToMembers(pGangName)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Gang Emblem successfully updated!</font>")

	elseif action == "UpdatePrestigeReq" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local newReq = tonumber(value)
		if not newReq or newReq < 0 then return end

		SaveGangData(pGangName, function(gangData)
			gangData.PrestigeReq = newReq
			return gangData
		end)
		SyncGangToMembers(pGangName)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Prestige requirement updated to " .. newReq .. ".</font>")

	elseif action == "UpgradeBuilding" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local bId = tostring(value)
		local bConfigs = {
			Vault = {Max = 10, ReqLevel = 1},
			Dojo = {Max = 10, ReqLevel = 2},
			Market = {Max = 3, ReqLevel = 3},
			Shrine = {Max = 3, ReqLevel = 4},
			Armory = {Max = 5, ReqLevel = 5}
		}
		local cfg = bConfigs[bId]
		if not cfg then return end

		local started = false
		local errReason = ""

		SaveGangData(pGangName, function(gangData)
			if gangData.ActiveUpgrade then
				if os.time() < gangData.ActiveUpgrade.FinishTime then
					errReason = "An upgrade is already in progress!"
					return gangData
				else
					local oldId = gangData.ActiveUpgrade.Id
					gangData.Buildings[oldId] = (gangData.Buildings[oldId] or 0) + 1
					gangData.ActiveUpgrade = nil
				end
			end

			if GetGangLevel(gangData.Rep or 0) < cfg.ReqLevel then return gangData end

			local curLvl = gangData.Buildings[bId] or 0
			if curLvl >= cfg.Max then return gangData end

			local cost = 100000000 
			if (gangData.Treasury or 0) >= cost then
				gangData.Treasury -= cost
				gangData.ActiveUpgrade = { Id = bId, FinishTime = os.time() + 1800 }
				started = true
			else
				errReason = "Not enough Treasury funds (Requires ¥100M)!"
			end
			return gangData
		end)

		if started then
			SyncGangToMembers(pGangName)
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Started upgrading the " .. bId .. "!</font>")
		else
			if errReason ~= "" then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>" .. errReason .. "</font>")
			end
		end

	elseif action == "RerollOrder" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local orderIndex = tonumber(value)
		if not orderIndex then return end

		local rerolled = false
		SaveGangData(pGangName, function(gangData)
			if not gangData.Orders or not gangData.Orders[orderIndex] then return gangData end
			if gangData.Orders[orderIndex].Completed then return gangData end

			if (gangData.Treasury or 0) >= 1000000 then
				gangData.Treasury -= 1000000
				gangData.Orders[orderIndex] = RollSingleOrder()
				rerolled = true
			end
			return gangData
		end)

		if rerolled then
			SyncGangToMembers(pGangName)
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Order successfully rerolled!</font>")
		else
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Cannot reroll this order. (Requires ¥1M or already completed)</font>")
		end

	elseif action == "RenameRole" then
		if pRole ~= "Boss" then return end
		local targetRole = tostring(value)
		local newRoleName = tostring(extraValue)

		if not RolePower[targetRole] then return end
		if string.len(newRoleName) < 3 or string.len(newRoleName) > 15 or not string.match(newRoleName, "^[a-zA-Z ]+$") then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Role names must be 3-15 letters only!</font>")
			return 
		end

		SaveGangData(pGangName, function(gangData)
			if not gangData.CustomRoles then gangData.CustomRoles = {} end
			gangData.CustomRoles[targetRole] = newRoleName
			return gangData
		end)
		SyncGangToMembers(pGangName)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Successfully renamed " .. targetRole .. " to " .. newRoleName .. "!</font>")

	elseif action == "BrowseGangs" then
		if #CachedBrowserList == 0 then RefreshBrowserCache() end
		local shuffled = table.clone(CachedBrowserList)
		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		local resultList = {}
		local count = 0
		for _, gName in ipairs(shuffled) do
			if count >= 15 then break end
			local gData = LoadGangData(gName)
			if gData then
				table.insert(resultList, {
					Name = gData.Name, 
					Level = GetGangLevel(gData.Rep or 0), 
					Members = gData.MemberCount, 
					Mode = gData.JoinMode, 
					Req = gData.PrestigeReq or 0,
					Motto = gData.Motto,
					Emblem = gData.Emblem
				})
				count += 1
			end
		end
		GangUpdate:FireClient(player, "BrowserSync", resultList)

	elseif action == "SearchGang" then
		local searchName = tostring(value)
		if string.len(searchName) < 3 then return end

		local gData = LoadGangData(searchName)
		if gData then
			GangUpdate:FireClient(player, "BrowserSync", {{
				Name = gData.Name, 
				Level = GetGangLevel(gData.Rep or 0), 
				Members = gData.MemberCount, 
				Mode = gData.JoinMode, 
				Req = gData.PrestigeReq or 0,
				Motto = gData.Motto,
				Emblem = gData.Emblem
			}})
		else
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Gang not found!</font>")
		end

	elseif action == "ToggleJoinMode" then
		if pRole ~= "Boss" then return end
		SaveGangData(pGangName, function(gangData)
			gangData.JoinMode = (gangData.JoinMode == "Open") and "Request" or "Open"
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "RequestJoin" then
		if pGangName ~= "None" then return end
		local targetGangKey = string.lower(tostring(value))
		local gangCache = LoadGangData(targetGangKey)
		if not gangCache then return end

		if gangCache.Members[pIdStr] then return end
		if GetDictSize(gangCache.Members) >= 30 then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Gang is full (30/30)!</font>")
			return
		end

		local pPres = player.leaderstats.Prestige.Value
		local req = gangCache.PrestigeReq or 0
		if pPres < req then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You do not meet the Prestige requirement for this gang ("..req..").</font>")
			return
		end

		if gangCache.JoinMode == "Open" then
			local actuallyJoined = false

			SaveGangData(targetGangKey, function(gangData)
				actuallyJoined = false
				if GetDictSize(gangData.Members) < 30 and not gangData.Members[pIdStr] then
					gangData.Members[pIdStr] = {Name = player.Name, Role = "Grunt", Prestige = player.leaderstats.Prestige.Value, LastOnline = os.time(), Contribution = 0, PlayTime = player:GetAttribute("PlayTime") or 0}
					actuallyJoined = true
				end
				return gangData
			end)

			if actuallyJoined then
				player:SetAttribute("Gang", targetGangKey)
				player:SetAttribute("GangRole", "Grunt")
				ApplyGangBuffs(player, ActiveGangs[targetGangKey])
				SyncGangToMembers(targetGangKey)
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Joined " .. gangCache.Name .. "!</font>")
			else
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Gang is full (30/30)!</font>")
			end
		else
			SaveGangData(targetGangKey, function(gangData)
				-- FIX: Added safety check to ensure Requests table exists before assigning
				if not gangData.Requests then gangData.Requests = {} end
				gangData.Requests[pIdStr] = player.Name
				return gangData
			end)
			SyncGangToMembers(targetGangKey)
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFFF55'>Request sent to " .. gangCache.Name .. "!</font>")
		end

	elseif action == "AcceptRequest" or action == "DenyRequest" then
		if RolePower[pRole] < RolePower["Caporegime"] then return end
		local targetIdStr = tostring(value)
		local targetPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
		local accepted = false

		SaveGangData(pGangName, function(gangData)
			accepted = false
			if gangData.Requests and gangData.Requests[targetIdStr] then
				if action == "AcceptRequest" then
					if GetDictSize(gangData.Members) < 30 then
						if targetPlayer and targetPlayer:GetAttribute("Gang") == "None" then
							gangData.Members[targetIdStr] = {Name = targetPlayer.Name, Role = "Grunt", Prestige = targetPlayer.leaderstats.Prestige.Value, LastOnline = os.time(), Contribution = 0, PlayTime = targetPlayer:GetAttribute("PlayTime") or 0}
							accepted = true
						end
					end
				end
				gangData.Requests[targetIdStr] = nil
			end
			return gangData
		end)

		if accepted and targetPlayer then
			targetPlayer:SetAttribute("Gang", pGangName)
			targetPlayer:SetAttribute("GangRole", "Grunt")
			ApplyGangBuffs(targetPlayer, ActiveGangs[pGangName])
			Network.CombatUpdate:FireClient(targetPlayer, "SystemMessage", "<font color='#55FF55'>Your request to join " .. ActiveGangs[pGangName].Name .. " was accepted!</font>")
		elseif action == "AcceptRequest" and not accepted then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Could not accept. Gang is full (30/30) or player is offline.</font>")
		end
		SyncGangToMembers(pGangName)

	elseif action == "Kick" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local targetIdStr = tostring(value)

		SaveGangData(pGangName, function(gangData)
			local targetMember = gangData.Members[targetIdStr]
			if targetMember and targetIdStr ~= pIdStr and RolePower[pRole] > (RolePower[targetMember.Role] or 1) then
				gangData.Members[targetIdStr] = nil

				local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
				if tPlayer then
					tPlayer:SetAttribute("Gang", "None")
					tPlayer:SetAttribute("GangRole", "None")
					ApplyGangBuffs(tPlayer, nil)
					Network.CombatUpdate:FireClient(tPlayer, "SystemMessage", "<font color='#FF5555'>You were kicked from the gang.</font>")
					GangUpdate:FireClient(tPlayer, "Sync", nil)
				end
			end
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "Promote" or action == "Demote" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local targetIdStr = tostring(value)

		SaveGangData(pGangName, function(gangData)
			local targetMember = gangData.Members[targetIdStr]
			if targetMember and targetIdStr ~= pIdStr and RolePower[pRole] > (RolePower[targetMember.Role] or 1) then
				local curRole = targetMember.Role
				local newRole = curRole

				if action == "Promote" then
					if curRole == "Grunt" then newRole = "Caporegime"
					elseif curRole == "Caporegime" and pRole == "Boss" then newRole = "Consigliere"
					elseif curRole == "Consigliere" and pRole == "Boss" then
						targetMember.Role = "Boss"
						gangData.Members[pIdStr].Role = "Consigliere"

						player:SetAttribute("GangRole", "Consigliere")
						Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFFF55'>You have passed the Boss title to " .. targetMember.Name .. "!</font>")

						local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
						if tPlayer then
							tPlayer:SetAttribute("GangRole", "Boss")
							Network.CombatUpdate:FireClient(tPlayer, "SystemMessage", "<font color='#FFD700'>You have been promoted to Gang Boss!</font>")
						end
						return gangData
					end
				elseif action == "Demote" then
					if curRole == "Consigliere" then newRole = "Caporegime"
					elseif curRole == "Caporegime" then newRole = "Grunt" end
				end

				if newRole == "Caporegime" and action == "Promote" then
					local capoCount = 0
					for _, m in pairs(gangData.Members) do if m.Role == "Caporegime" then capoCount += 1 end end
					if capoCount >= 5 then return gangData end
				elseif newRole == "Consigliere" and action == "Promote" then
					local conCount = 0
					for _, m in pairs(gangData.Members) do if m.Role == "Consigliere" then conCount += 1 end end
					if conCount >= 1 then return gangData end
				end

				targetMember.Role = newRole
				local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
				if tPlayer then
					tPlayer:SetAttribute("GangRole", newRole)
					Network.CombatUpdate:FireClient(tPlayer, "SystemMessage", "<font color='#FFFF55'>Your gang role was updated to: " .. newRole .. "</font>")
				end
			end
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "Donate" then
		local amount = tonumber(value)
		if not amount or amount < 1000 or pGangName == "None" then return end

		local yen = player.leaderstats.Yen
		if yen.Value >= amount then
			yen.Value -= amount
			SaveGangData(pGangName, function(gangData)
				gangData.Treasury = (gangData.Treasury or 0) + amount
				gangData.Rep = (gangData.Rep or 0) + math.floor(amount / 1000)

				if gangData.Members[pIdStr] then
					gangData.Members[pIdStr].Contribution = (gangData.Members[pIdStr].Contribution or 0) + amount
				end

				return gangData
			end)

			ProgressOrderEvent:Fire(pGangName, "Yen", amount)
			ApplyGangBuffs(player, ActiveGangs[pGangName])
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Donated ¥" .. amount .. " to the Gang!</font>")
			SyncGangToMembers(pGangName)
		end

	elseif action == "Leave" then
		if pGangName == "None" or pRole == "Boss" then return end

		SaveGangData(pGangName, function(gangData)
			if gangData.Members[pIdStr] then
				gangData.Members[pIdStr] = nil
			end
			return gangData
		end)

		player:SetAttribute("Gang", "None")
		player:SetAttribute("GangRole", "None")
		ApplyGangBuffs(player, nil)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#AAAAAA'>You left the gang.</font>")
		GangUpdate:FireClient(player, "Sync", nil)
		SyncGangToMembers(pGangName)

	elseif action == "Disband" then
		if pGangName == "None" or pRole ~= "Boss" then return end
		local gang = ActiveGangs[pGangName]
		if not gang then return end

		local displayToWipe = gang.Name

		for uIdStr, _ in pairs(gang.Members) do
			local mem = Players:GetPlayerByUserId(tonumber(uIdStr))
			if mem then
				mem:SetAttribute("Gang", "None")
				mem:SetAttribute("GangRole", "None")
				ApplyGangBuffs(mem, nil)
				Network.CombatUpdate:FireClient(mem, "SystemMessage", "<font color='#FF5555'>Your gang was disbanded.</font>")
				GangUpdate:FireClient(mem, "Sync", nil)
			end
		end

		ActiveGangs[pGangName] = nil
		pcall(function()
			GangStore:RemoveAsync(pGangName)
			ODS_GangRep:RemoveAsync(displayToWipe)
			ODS_GangTreasury:RemoveAsync(displayToWipe)
			ODS_GangPrestige:RemoveAsync(displayToWipe)
			ODS_GangElo:RemoveAsync(displayToWipe)
			ODS_GangRaids:RemoveAsync(displayToWipe)
		end)

	elseif action == "RequestSync" then
		if pGangName ~= "None" then
			local data = LoadGangData(pGangName)
			if data then 
				SaveGangData(pGangName, function(gangData)
					if not gangData.Buildings then gangData.Buildings = { Vault = 0, Dojo = 0, Armory = 0, Shrine = 0, Market = 0 } end
					if not gangData.Orders then gangData.Orders = GenerateRandomOrders() end
					if not gangData.LastOrderReset then gangData.LastOrderReset = os.time() end
					if not gangData.PrestigeReq then gangData.PrestigeReq = 0 end

					-- FIX: Initializing Requests table during Sync for legacy gangs
					if not gangData.Requests then gangData.Requests = {} end

					if gangData.ActiveUpgrade and os.time() >= gangData.ActiveUpgrade.FinishTime then
						local bId = gangData.ActiveUpgrade.Id
						gangData.Buildings[bId] = (gangData.Buildings[bId] or 0) + 1
						gangData.ActiveUpgrade = nil
					end

					for uIdStr, memData in pairs(gangData.Members) do
						local livePlayer = Players:GetPlayerByUserId(tonumber(uIdStr))
						if livePlayer then
							local pObj = livePlayer:FindFirstChild("leaderstats")
							if pObj and pObj:FindFirstChild("Prestige") then
								memData.Prestige = pObj.Prestige.Value
							end
							memData.LastOnline = os.time()
							memData.PlayTime = livePlayer:GetAttribute("PlayTime") or memData.PlayTime or 0
						end

						memData.Contribution = memData.Contribution or 0
						memData.PlayTime = memData.PlayTime or 0
					end

					local hasBoss = false
					for _, m in pairs(gangData.Members) do
						if m.Role == "Boss" then hasBoss = true; break end
					end

					if not hasBoss then ElectNewBoss(gangData) end
					return gangData
				end)

				GangUpdate:FireClient(player, "Sync", ActiveGangs[pGangName]) 
			else
				player:SetAttribute("Gang", "None")
				player:SetAttribute("GangRole", "None")
				GangUpdate:FireClient(player, "Sync", nil)
			end
		end
	end
end)