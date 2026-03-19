-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local TradeAction = Network:WaitForChild("TradeAction")
local TradeUpdate = Network:WaitForChild("TradeUpdate")

local OpenLobbies = {} 
local IncomingRequests = {} 
local ActiveTrades = {} 
local PlayerSettings = {} 

local function IsKeyItem(name)
	if name == "Stand Arrow" or name == "Rokakaka" or name == "Heavenly Stand Disc" or name == "Saint's Corpse Part" then
		return true
	end

	local itemInfo = ItemData.Equipment[name] or ItemData.Consumables[name]
	if itemInfo and itemInfo.Rarity == "Unique" then
		return true
	end

	return false
end

local function CanTrade(plr)
	if not plr then return false end
	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Prestige") then
		return ls.Prestige.Value >= 1
	end
	return false
end

local function GetBrowserDataForPlayer(player)
	local lobbiesList = {}
	for host, data in pairs(OpenLobbies) do
		table.insert(lobbiesList, { HostId = host.UserId, HostName = host.Name, LF = data.LF, Offering = data.Offering })
	end

	local requestsList = {}
	if IncomingRequests[player] then
		for sender, _ in pairs(IncomingRequests[player]) do
			table.insert(requestsList, { SenderId = sender.UserId, SenderName = sender.Name })
		end
	end
	return { Lobbies = lobbiesList, Requests = requestsList }
end

local function UpdateAllBrowsers()
	for _, plr in ipairs(Players:GetPlayers()) do
		if CanTrade(plr) then
			TradeUpdate:FireClient(plr, "BrowserUpdate", GetBrowserDataForPlayer(plr))
		end
	end
end

local function FindPlayerByName(partialName)
	local lowerTarget = string.lower(partialName)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == lowerTarget or string.lower(p.DisplayName) == lowerTarget then return p end
	end
	return nil
end

local function GetTradeStateForClient(session, requestingPlayer)
	local myOffer = (session.P1 == requestingPlayer) and session.P1Offer or session.P2Offer
	local oppOffer = (session.P1 == requestingPlayer) and session.P2Offer or session.P1Offer
	local oppName = (session.P1 == requestingPlayer) and session.P2.Name or session.P1.Name

	return {
		OpponentName = oppName,
		Me = { Items = myOffer.Items, Stand = myOffer.Stand, Style = myOffer.Style, Yen = myOffer.Yen, Locked = myOffer.Locked, Confirmed = myOffer.Confirmed },
		Opp = { Items = oppOffer.Items, Stand = oppOffer.Stand, Style = oppOffer.Style, Yen = oppOffer.Yen, Locked = oppOffer.Locked, Confirmed = oppOffer.Confirmed }
	}
end

local function SyncTrade(session)
	if session.P1.Parent then TradeUpdate:FireClient(session.P1, "TradeUpdateState", GetTradeStateForClient(session, session.P1)) end
	if session.P2.Parent then TradeUpdate:FireClient(session.P2, "TradeUpdateState", GetTradeStateForClient(session, session.P2)) end
end

local function EndTrade(session, reasonMsg)
	ActiveTrades[session.P1] = nil
	ActiveTrades[session.P2] = nil

	if session.P1.Parent then TradeUpdate:FireClient(session.P1, "TradeEnd") end
	if session.P2.Parent then TradeUpdate:FireClient(session.P2, "TradeEnd") end

	if reasonMsg then
		if session.P1.Parent then Network.CombatUpdate:FireClient(session.P1, "SystemMessage", reasonMsg) end
		if session.P2.Parent then Network.CombatUpdate:FireClient(session.P2, "SystemMessage", reasonMsg) end
	end
end

local function ExecuteTrade(session)
	if session.IsExecuting then return end
	session.IsExecuting = true

	local p1, p2 = session.P1, session.P2
	local o1, o2 = session.P1Offer, session.P2Offer

	if not p1 or not p2 or not p1.Parent or not p2.Parent then
		EndTrade(session, "<font color='#FF5555'>Trade failed: A player disconnected.</font>")
		return
	end

	if p1.leaderstats.Yen.Value < o1.Yen or p2.leaderstats.Yen.Value < o2.Yen then
		EndTrade(session, "<font color='#FF5555'>Trade failed: Someone didn't have enough Yen!</font>")
		return
	end

	local function VerifyItems(plr, offer)
		for item, amt in pairs(offer.Items) do
			local actual = plr:GetAttribute(item:gsub("[^%w]", "") .. "Count") or 0
			if actual < amt then return false end
		end
		return true
	end

	local function VerifyStand(plr, offer)
		if not offer.Stand then return true end
		local slot = offer.Stand.Slot
		local expectedName = offer.Stand.Name
		local actual = "None"

		if slot == "Active" then actual = plr:GetAttribute("Stand") or "None"
		elseif slot == "Slot1" then actual = plr:GetAttribute("StoredStand1") or "None"
		elseif slot == "Slot2" then actual = plr:GetAttribute("StoredStand2") or "None"
		elseif slot == "Slot3" then actual = plr:GetAttribute("StoredStand3") or "None"
		elseif slot == "Slot4" then actual = plr:GetAttribute("StoredStand4") or "None"
		elseif slot == "Slot5" then actual = plr:GetAttribute("StoredStand5") or "None" end

		return actual == expectedName
	end

	local function VerifyStyle(plr, offer)
		if not offer.Style then return true end
		local slot = offer.Style.Slot
		local expectedName = offer.Style.Name
		local actual = "None"

		if slot == "Active" then actual = plr:GetAttribute("FightingStyle") or "None"
		elseif slot == "Slot1" then actual = plr:GetAttribute("StoredStyle1") or "None"
		elseif slot == "Slot2" then actual = plr:GetAttribute("StoredStyle2") or "None"
		elseif slot == "Slot3" then actual = plr:GetAttribute("StoredStyle3") or "None" end

		return actual == expectedName
	end

	if not VerifyItems(p1, o1) or not VerifyItems(p2, o2) or not VerifyStand(p1, o1) or not VerifyStand(p2, o2) or not VerifyStyle(p1, o1) or not VerifyStyle(p2, o2) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: Inventory mismatched offer.</font>")
		return
	end

	local function GetOfferSpaceNeeded(offer)
		local space = 0
		for item, amt in pairs(offer.Items) do
			if not IsKeyItem(item) then
				space += amt
			end
		end
		return space
	end

	local p1Given = GetOfferSpaceNeeded(o1)
	local p1Received = GetOfferSpaceNeeded(o2)
	local p2Given = GetOfferSpaceNeeded(o2)
	local p2Received = GetOfferSpaceNeeded(o1)

	if GameData.GetInventoryCount(p1) - p1Given + p1Received > GameData.GetMaxInventory(p1) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: " .. p1.Name .. " does not have enough inventory space!</font>")
		return
	end

	if GameData.GetInventoryCount(p2) - p2Given + p2Received > GameData.GetMaxInventory(p2) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: " .. p2.Name .. " does not have enough inventory space!</font>")
		return
	end

	p1.leaderstats.Yen.Value = p1.leaderstats.Yen.Value - o1.Yen + o2.Yen
	p2.leaderstats.Yen.Value = p2.leaderstats.Yen.Value - o2.Yen + o1.Yen

	local function ProcessItems(giver, receiver, offer)
		for itemName, amt in pairs(offer.Items) do
			local cleanName = itemName:gsub("[^%w]", "") .. "Count"
			local currentCount = giver:GetAttribute(cleanName) or 0

			if currentCount - amt == 0 then
				local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
				if itemData and itemData.Slot then
					if giver:GetAttribute("Equipped" .. itemData.Slot) == itemName then
						giver:SetAttribute("Equipped" .. itemData.Slot, "None")
					end
				end
			end

			giver:SetAttribute(cleanName, currentCount - amt)
			receiver:SetAttribute(cleanName, (receiver:GetAttribute(cleanName) or 0) + amt)
		end
	end

	ProcessItems(p1, p2, o1)
	ProcessItems(p2, p1, o2)

	local function WipeStand(plr, slot)
		if slot == "Active" then
			plr:SetAttribute("Stand", "None")
			plr:SetAttribute("StandTrait", "None")
		elseif slot == "Slot1" then
			plr:SetAttribute("StoredStand1", "None")
			plr:SetAttribute("StoredStand1_Trait", "None")
		elseif slot == "Slot2" then
			plr:SetAttribute("StoredStand2", "None")
			plr:SetAttribute("StoredStand2_Trait", "None")
		elseif slot == "Slot3" then
			plr:SetAttribute("StoredStand3", "None")
			plr:SetAttribute("StoredStand3_Trait", "None")
		elseif slot == "Slot4" then
			plr:SetAttribute("StoredStand4", "None")
			plr:SetAttribute("StoredStand4_Trait", "None")
		elseif slot == "Slot5" then
			plr:SetAttribute("StoredStand5", "None")
			plr:SetAttribute("StoredStand5_Trait", "None")
		end
	end

	local function WipeStyle(plr, slot)
		if slot == "Active" then
			plr:SetAttribute("FightingStyle", "None")
		elseif slot == "Slot1" then
			plr:SetAttribute("StoredStyle1", "None")
		elseif slot == "Slot2" then
			plr:SetAttribute("StoredStyle2", "None")
		elseif slot == "Slot3" then
			plr:SetAttribute("StoredStyle3", "None")
		end
	end

	if o1.Stand then WipeStand(p1, o1.Stand.Slot) end
	if o2.Stand then WipeStand(p2, o2.Stand.Slot) end
	if o1.Style then WipeStyle(p1, o1.Style.Slot) end
	if o2.Style then WipeStyle(p2, o2.Style.Slot) end

	if o1.Stand then
		p2:SetAttribute("PendingStand_Name", o1.Stand.Name)
		p2:SetAttribute("PendingStand_Trait", o1.Stand.Trait)
		TradeUpdate:FireClient(p2, "ShowClaimPrompt", {
			Name = o1.Stand.Name,
			Active = p2:GetAttribute("Stand") or "None",
			Slot1 = p2:GetAttribute("StoredStand1") or "None",
			Slot2 = p2:GetAttribute("StoredStand2") or "None",
			Slot3 = p2:GetAttribute("StoredStand3") or "None",
			Slot4 = p2:GetAttribute("StoredStand4") or "None",
			Slot5 = p2:GetAttribute("StoredStand5") or "None"
		})
	end
	if o2.Stand then
		p1:SetAttribute("PendingStand_Name", o2.Stand.Name)
		p1:SetAttribute("PendingStand_Trait", o2.Stand.Trait)
		TradeUpdate:FireClient(p1, "ShowClaimPrompt", {
			Name = o2.Stand.Name,
			Active = p1:GetAttribute("Stand") or "None",
			Slot1 = p1:GetAttribute("StoredStand1") or "None",
			Slot2 = p1:GetAttribute("StoredStand2") or "None",
			Slot3 = p1:GetAttribute("StoredStand3") or "None",
			Slot4 = p1:GetAttribute("StoredStand4") or "None",
			Slot5 = p1:GetAttribute("StoredStand5") or "None"
		})
	end

	if o1.Style then
		p2:SetAttribute("PendingStyle_Name", o1.Style.Name)
		TradeUpdate:FireClient(p2, "ShowStyleClaimPrompt", {
			Name = o1.Style.Name,
			Active = p2:GetAttribute("FightingStyle") or "None",
			Slot1 = p2:GetAttribute("StoredStyle1") or "None",
			Slot2 = p2:GetAttribute("StoredStyle2") or "None",
			Slot3 = p2:GetAttribute("StoredStyle3") or "None"
		})
	end
	if o2.Style then
		p1:SetAttribute("PendingStyle_Name", o2.Style.Name)
		TradeUpdate:FireClient(p1, "ShowStyleClaimPrompt", {
			Name = o2.Style.Name,
			Active = p1:GetAttribute("FightingStyle") or "None",
			Slot1 = p1:GetAttribute("StoredStyle1") or "None",
			Slot2 = p1:GetAttribute("StoredStyle2") or "None",
			Slot3 = p1:GetAttribute("StoredStyle3") or "None"
		})
	end

	local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
	if saveEvent then
		saveEvent:Fire(p1)
		saveEvent:Fire(p2)
	end

	EndTrade(session, "<font color='#55FF55'>Trade successfully completed!</font>")
end

local function StartTrade(p1, p2)
	if OpenLobbies[p1] then OpenLobbies[p1] = nil end
	if OpenLobbies[p2] then OpenLobbies[p2] = nil end
	if IncomingRequests[p1] then IncomingRequests[p1][p2] = nil end
	if IncomingRequests[p2] then IncomingRequests[p2][p1] = nil end

	local tradeMatch = { 
		P1 = p1, P2 = p2,
		IsExecuting = false,
		P1Offer = { Items = {}, Stand = nil, Style = nil, Yen = 0, Locked = false, Confirmed = false },
		P2Offer = { Items = {}, Stand = nil, Style = nil, Yen = 0, Locked = false, Confirmed = false }
	}
	ActiveTrades[p1] = tradeMatch
	ActiveTrades[p2] = tradeMatch

	TradeUpdate:FireClient(p1, "TradeStart", { OpponentName = p2.Name })
	TradeUpdate:FireClient(p2, "TradeStart", { OpponentName = p1.Name })

	SyncTrade(tradeMatch)
	UpdateAllBrowsers()
end

TradeAction.OnServerEvent:Connect(function(player, action, data)
	local session = ActiveTrades[player]

	if not session then
		if action == "RequestData" then
			if CanTrade(player) then
				TradeUpdate:FireClient(player, "BrowserUpdate", GetBrowserDataForPlayer(player))
			end

		elseif action == "ClaimStand" then
			local pName = player:GetAttribute("PendingStand_Name")
			local pTrait = player:GetAttribute("PendingStand_Trait")
			if not pName or pName == "" or pName == "None" then return end

			local slot = data
			if slot == "Active" then
				player:SetAttribute("Stand", pName)
				player:SetAttribute("StandTrait", pTrait)

				local stats = StandData.Stands[pName] and StandData.Stands[pName].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}
				for statName, rank in pairs(stats) do
					player:SetAttribute("Stand_"..statName, rank)
				end
			elseif slot == "Slot1" then
				player:SetAttribute("StoredStand1", pName)
				player:SetAttribute("StoredStand1_Trait", pTrait)
			elseif slot == "Slot2" then
				player:SetAttribute("StoredStand2", pName)
				player:SetAttribute("StoredStand2_Trait", pTrait)
			elseif slot == "Slot3" then
				player:SetAttribute("StoredStand3", pName)
				player:SetAttribute("StoredStand3_Trait", pTrait)
			elseif slot == "Slot4" then
				player:SetAttribute("StoredStand4", pName)
				player:SetAttribute("StoredStand4_Trait", pTrait)
			elseif slot == "Slot5" then
				player:SetAttribute("StoredStand5", pName)
				player:SetAttribute("StoredStand5_Trait", pTrait)
			end

			player:SetAttribute("PendingStand_Name", "None")
			player:SetAttribute("PendingStand_Trait", "None")
			TradeUpdate:FireClient(player, "HideClaimPrompt")
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#A020F0'>Stand safely stored!</font>")

		elseif action == "ClaimStyle" then
			local pName = player:GetAttribute("PendingStyle_Name")
			if not pName or pName == "" or pName == "None" then return end

			local slot = data
			if slot == "Active" then
				player:SetAttribute("FightingStyle", pName)
			elseif slot == "Slot1" then
				player:SetAttribute("StoredStyle1", pName)
			elseif slot == "Slot2" then
				player:SetAttribute("StoredStyle2", pName)
			elseif slot == "Slot3" then
				player:SetAttribute("StoredStyle3", pName)
			end

			player:SetAttribute("PendingStyle_Name", "None")
			TradeUpdate:FireClient(player, "HideStyleClaimPrompt")
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF8C00'>Style safely stored!</font>")

		elseif action == "ToggleRequests" then
			if not CanTrade(player) then return end
			if not PlayerSettings[player] then PlayerSettings[player] = {} end
			PlayerSettings[player].RequestsEnabled = data

		elseif action == "CreateLobby" then
			if not CanTrade(player) then return end
			local lfStr = data.LF or "Any / Offers"
			local offStr = data.Offering or "Any / Open"
			if string.len(lfStr) > 60 then lfStr = string.sub(lfStr, 1, 60) .. "..." end
			if string.len(offStr) > 60 then offStr = string.sub(offStr, 1, 60) .. "..." end

			OpenLobbies[player] = { LF = lfStr, Offering = offStr }
			TradeUpdate:FireClient(player, "LobbyStatus", {IsHosting = true})
			UpdateAllBrowsers()

		elseif action == "CancelLobby" then
			if OpenLobbies[player] then
				OpenLobbies[player] = nil
				TradeUpdate:FireClient(player, "LobbyStatus", {IsHosting = false})
				UpdateAllBrowsers()
			end

		elseif action == "JoinLobby" then
			if not CanTrade(player) then return end
			local targetHost = nil
			for host, _ in pairs(OpenLobbies) do if host.UserId == data then targetHost = host; break end end
			if targetHost and targetHost ~= player then
				StartTrade(targetHost, player)
				TradeUpdate:FireClient(targetHost, "LobbyStatus", {IsHosting = false})
			end

		elseif action == "SendRequest" then
			if not CanTrade(player) then return end
			local targetPlayer = FindPlayerByName(data)
			if not targetPlayer or targetPlayer == player then return end

			if not CanTrade(targetPlayer) then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>" .. targetPlayer.Name .. " must reach Prestige 1 to unlock trading!</font>")
				return
			end

			if PlayerSettings[targetPlayer] and PlayerSettings[targetPlayer].RequestsEnabled == false then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>That player is not accepting trade requests right now.</font>")
				return
			end

			if not IncomingRequests[targetPlayer] then IncomingRequests[targetPlayer] = {} end
			IncomingRequests[targetPlayer][player] = true

			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Trade request sent to " .. targetPlayer.Name .. "!</font>")
			TradeUpdate:FireClient(targetPlayer, "TradeAlert", player.Name)
			TradeUpdate:FireClient(targetPlayer, "BrowserUpdate", GetBrowserDataForPlayer(targetPlayer))

		elseif action == "AcceptRequest" then
			if not CanTrade(player) then return end
			local targetSender = nil
			for sender, _ in pairs(IncomingRequests[player] or {}) do if sender.UserId == data then targetSender = sender; break end end
			if targetSender then StartTrade(player, targetSender) end

		elseif action == "DeclineRequest" then
			if IncomingRequests[player] then
				local targetSender = nil
				for sender, _ in pairs(IncomingRequests[player]) do if sender.UserId == data then targetSender = sender; break end end
				if targetSender then
					IncomingRequests[player][targetSender] = nil
					TradeUpdate:FireClient(player, "BrowserUpdate", GetBrowserDataForPlayer(player))
				end
			end
		end

	else
		if session.IsExecuting then return end

		local myOffer = (session.P1 == player) and session.P1Offer or session.P2Offer
		local oppOffer = (session.P1 == player) and session.P2Offer or session.P1Offer

		local function UnlockTrade()
			session.P1Offer.Locked = false; session.P1Offer.Confirmed = false
			session.P2Offer.Locked = false; session.P2Offer.Confirmed = false
		end

		if action == "CancelTrade" then
			EndTrade(session, "<font color='#FF5555'>"..player.Name.." cancelled the trade.</font>")

		elseif action == "AddStand" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Stand then return end 

			if player:GetAttribute("StandLocked") and data == "Active" then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You cannot trade a locked Stand!</font>")
				return
			end

			local slot = data
			local sName, sTrait = "None", "None"

			if slot == "Active" then
				sName = player:GetAttribute("Stand") or "None"
				sTrait = player:GetAttribute("StandTrait") or "None"
			elseif slot == "Slot1" then
				sName = player:GetAttribute("StoredStand1") or "None"
				sTrait = player:GetAttribute("StoredStand1_Trait") or "None"
			elseif slot == "Slot2" then
				sName = player:GetAttribute("StoredStand2") or "None"
				sTrait = player:GetAttribute("StoredStand2_Trait") or "None"
			elseif slot == "Slot3" then
				sName = player:GetAttribute("StoredStand3") or "None"
				sTrait = player:GetAttribute("StoredStand3_Trait") or "None"
			elseif slot == "Slot4" then
				sName = player:GetAttribute("StoredStand4") or "None"
				sTrait = player:GetAttribute("StoredStand4_Trait") or "None"
			elseif slot == "Slot5" then
				sName = player:GetAttribute("StoredStand5") or "None"
				sTrait = player:GetAttribute("StoredStand5_Trait") or "None"
			end

			if sName ~= "None" then
				myOffer.Stand = { Slot = slot, Name = sName, Trait = sTrait }
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "RemoveStand" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Stand then
				myOffer.Stand = nil
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "AddStyle" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Style then return end 

			if player:GetAttribute("StyleLocked") and data == "Active" then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You cannot trade a locked Style!</font>")
				return
			end

			local slot = data
			local sName = "None"

			if slot == "Active" then sName = player:GetAttribute("FightingStyle") or "None"
			elseif slot == "Slot1" then sName = player:GetAttribute("StoredStyle1") or "None"
			elseif slot == "Slot2" then sName = player:GetAttribute("StoredStyle2") or "None"
			elseif slot == "Slot3" then sName = player:GetAttribute("StoredStyle3") or "None" end

			if sName ~= "None" then
				myOffer.Style = { Slot = slot, Name = sName }
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "RemoveStyle" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Style then
				myOffer.Style = nil
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "AddItem" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local itemName = tostring(data)

			local lockedItems = player:GetAttribute("LockedItems") or ""
			if table.find(string.split(lockedItems, ","), itemName) then
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You cannot trade a locked item!</font>")
				return
			end

			local countInInv = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0
			local countInOffer = myOffer.Items[itemName] or 0

			local isEquipped = false
			local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			if itemData and itemData.Slot then
				if player:GetAttribute("Equipped" .. itemData.Slot) == itemName then
					isEquipped = true
				end
			end

			local availableToTrade = isEquipped and (countInInv - 1) or countInInv

			if availableToTrade > countInOffer then
				myOffer.Items[itemName] = countInOffer + 1
				UnlockTrade()
				SyncTrade(session)
			else
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You cannot trade equipped items. Unequip it first!</font>")
			end

		elseif action == "RemoveItem" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local itemName = tostring(data)
			if myOffer.Items[itemName] then
				myOffer.Items[itemName] -= 1
				if myOffer.Items[itemName] <= 0 then myOffer.Items[itemName] = nil end
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "SetYen" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local amt = tonumber(data)
			if amt and amt >= 0 then
				local maxYen = player.leaderstats.Yen.Value
				myOffer.Yen = math.clamp(math.floor(amt), 0, maxYen)
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "ToggleLock" then
			if myOffer.Confirmed then return end 

			if not myOffer.Locked then
				myOffer.Locked = true
			elseif myOffer.Locked and oppOffer.Locked then
				myOffer.Confirmed = true
			else
				myOffer.Locked = false
			end

			SyncTrade(session)

			if session.P1Offer.Confirmed and session.P2Offer.Confirmed then
				ExecuteTrade(session)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if OpenLobbies[player] then OpenLobbies[player] = nil end

	IncomingRequests[player] = nil
	for target, reqs in pairs(IncomingRequests) do
		if reqs[player] then reqs[player] = nil end
	end

	PlayerSettings[player] = nil

	local match = ActiveTrades[player]
	if match and not match.IsExecuting then
		EndTrade(match, "<font color='#FF5555'>Trade cancelled: Partner disconnected.</font>")
	end

	UpdateAllBrowsers()
end)