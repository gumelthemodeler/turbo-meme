-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local TradeAction = Network:WaitForChild("TradeAction")
local TradeUpdate = Network:WaitForChild("TradeUpdate")
local NotificationEvent = Network:WaitForChild("NotificationEvent")

local ActiveTrades = {}
local TradeInvites = {}

local function SendMsg(player, msg, color)
	NotificationEvent:FireClient(player, "<font color='" .. (color or "#FF5555") .. "'>" .. msg .. "</font>")
end

local function CancelTrade(tradeId)
	local trade = ActiveTrades[tradeId]
	if not trade then return end

	if trade.P1 and trade.P1.Parent then TradeUpdate:FireClient(trade.P1, "TradeCancelled") end
	if trade.P2 and trade.P2.Parent then TradeUpdate:FireClient(trade.P2, "TradeCancelled") end

	ActiveTrades[tradeId] = nil
end

local function ExecuteTrade(tradeId)
	local trade = ActiveTrades[tradeId]
	if not trade then return end

	local p1, p2 = trade.P1, trade.P2
	local off1, off2 = trade.Offer1, trade.Offer2

	-- 1. Validate Dews (Replaces Yen)
	if p1.leaderstats.Yen.Value < off1.Dews or p2.leaderstats.Yen.Value < off2.Dews then
		SendMsg(p1, "Trade failed: Someone does not have enough Dews."); SendMsg(p2, "Trade failed: Someone does not have enough Dews.")
		CancelTrade(tradeId); return
	end

	-- 2. Validate Items
	for itemName, amount in pairs(off1.Items) do
		local attr = itemName:gsub("[^%w]", "") .. "Count"
		if (p1:GetAttribute(attr) or 0) < amount then SendMsg(p1, "Trade failed: Missing items."); CancelTrade(tradeId); return end
	end
	for itemName, amount in pairs(off2.Items) do
		local attr = itemName:gsub("[^%w]", "") .. "Count"
		if (p2:GetAttribute(attr) or 0) < amount then SendMsg(p2, "Trade failed: Missing items."); CancelTrade(tradeId); return end
	end

	-- 3. Execute Dews Exchange
	p1.leaderstats.Yen.Value = p1.leaderstats.Yen.Value - off1.Dews + off2.Dews
	p2.leaderstats.Yen.Value = p2.leaderstats.Yen.Value - off2.Dews + off1.Dews

	-- 4. Execute Item Exchange
	for itemName, amount in pairs(off1.Items) do
		local attr = itemName:gsub("[^%w]", "") .. "Count"
		p1:SetAttribute(attr, p1:GetAttribute(attr) - amount)
		p2:SetAttribute(attr, (p2:GetAttribute(attr) or 0) + amount)
	end
	for itemName, amount in pairs(off2.Items) do
		local attr = itemName:gsub("[^%w]", "") .. "Count"
		p2:SetAttribute(attr, p2:GetAttribute(attr) - amount)
		p1:SetAttribute(attr, (p1:GetAttribute(attr) or 0) + amount)
	end

	-- 5. Execute Titan Exchange (Replaces Stands)
	if off1.OfferingTitan and off2.OfferingTitan then
		local t1 = p1:GetAttribute("Titan"); local tr1 = p1:GetAttribute("TitanTrait")
		local t2 = p2:GetAttribute("Titan"); local tr2 = p2:GetAttribute("TitanTrait")

		-- Swap Base Powers & Traits
		p1:SetAttribute("Titan", t2); p1:SetAttribute("TitanTrait", tr2)
		p2:SetAttribute("Titan", t1); p2:SetAttribute("TitanTrait", tr1)

		-- Swap Titan Stats
		local statsToSwap = {"Titan_Power", "Titan_Speed", "Titan_Hardening", "Titan_Endurance", "Titan_Precision", "Titan_Potential", "Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}
		for _, s in ipairs(statsToSwap) do
			local val1 = p1:GetAttribute(s); local val2 = p2:GetAttribute(s)
			p1:SetAttribute(s, val2); p2:SetAttribute(s, val1)
		end
	end

	TradeUpdate:FireClient(p1, "TradeSuccess")
	TradeUpdate:FireClient(p2, "TradeSuccess")
	SendMsg(p1, "Trade completed successfully!", "#55FF55")
	SendMsg(p2, "Trade completed successfully!", "#55FF55")

	ActiveTrades[tradeId] = nil
end

TradeAction.OnServerEvent:Connect(function(player, action, data)
	if action == "SendInvite" then
		local target = game.Players:FindFirstChild(data)
		if target and target ~= player then
			TradeInvites[target.UserId] = player.UserId
			TradeUpdate:FireClient(target, "ReceiveInvite", player.Name)
			SendMsg(player, "Trade request sent to " .. target.Name, "#55FF55")
		end

	elseif action == "AcceptInvite" then
		local hostId = TradeInvites[player.UserId]
		local host = hostId and game.Players:GetPlayerByUserId(hostId) or nil
		if host then
			local tradeId = player.UserId .. "_" .. host.UserId
			ActiveTrades[tradeId] = {
				P1 = host, P2 = player,
				Offer1 = { Dews = 0, Items = {}, OfferingTitan = false },
				Offer2 = { Dews = 0, Items = {}, OfferingTitan = false },
				P1Ready = false, P2Ready = false,
				P1Confirm = false, P2Confirm = false
			}
			TradeUpdate:FireClient(host, "StartTrade", { TradeId = tradeId, OpponentName = player.Name })
			TradeUpdate:FireClient(player, "StartTrade", { TradeId = tradeId, OpponentName = host.Name })
		end
		TradeInvites[player.UserId] = nil

	elseif action == "DeclineInvite" then
		TradeInvites[player.UserId] = nil

	elseif action == "UpdateOffer" then
		local tradeId = data.TradeId
		local trade = ActiveTrades[tradeId]
		if not trade then return end

		local isP1 = (player == trade.P1)
		local myOffer = isP1 and trade.Offer1 or trade.Offer2

		if trade.P1Ready or trade.P2Ready then return end -- Locked while ready

		if data.UpdateType == "Dews" then
			local amount = math.max(0, math.floor(tonumber(data.Amount) or 0))
			if player.leaderstats.Yen.Value >= amount then
				myOffer.Dews = amount
			end
		elseif data.UpdateType == "AddItem" then
			local itemName = data.ItemName
			local attr = itemName:gsub("[^%w]", "") .. "Count"
			local hasCount = player:GetAttribute(attr) or 0
			local currentOffered = myOffer.Items[itemName] or 0

			if currentOffered < hasCount then
				myOffer.Items[itemName] = currentOffered + 1
			end
		elseif data.UpdateType == "RemoveItem" then
			local itemName = data.ItemName
			if myOffer.Items[itemName] and myOffer.Items[itemName] > 0 then
				myOffer.Items[itemName] -= 1
				if myOffer.Items[itemName] == 0 then myOffer.Items[itemName] = nil end
			end
		elseif data.UpdateType == "ToggleTitan" then
			if player:GetAttribute("TitanLocked") then
				SendMsg(player, "Your Titan is locked! Unlock it to trade.")
				return
			end
			if (player:GetAttribute("Titan") or "None") == "None" then return end
			myOffer.OfferingTitan = not myOffer.OfferingTitan
		end

		TradeUpdate:FireClient(trade.P1, "OfferUpdated", { Offer1 = trade.Offer1, Offer2 = trade.Offer2 })
		TradeUpdate:FireClient(trade.P2, "OfferUpdated", { Offer1 = trade.Offer1, Offer2 = trade.Offer2 })

	elseif action == "ToggleReady" then
		local tradeId = data
		local trade = ActiveTrades[tradeId]
		if not trade then return end

		if player == trade.P1 then trade.P1Ready = not trade.P1Ready
		elseif player == trade.P2 then trade.P2Ready = not trade.P2Ready end

		TradeUpdate:FireClient(trade.P1, "ReadyUpdated", { P1Ready = trade.P1Ready, P2Ready = trade.P2Ready })
		TradeUpdate:FireClient(trade.P2, "ReadyUpdated", { P1Ready = trade.P1Ready, P2Ready = trade.P2Ready })

	elseif action == "ConfirmTrade" then
		local tradeId = data
		local trade = ActiveTrades[tradeId]
		if not trade or not trade.P1Ready or not trade.P2Ready then return end

		if player == trade.P1 then trade.P1Confirm = true
		elseif player == trade.P2 then trade.P2Confirm = true end

		if trade.P1Confirm and trade.P2Confirm then
			ExecuteTrade(tradeId)
		end

	elseif action == "CancelTrade" then
		CancelTrade(data)
	end
end)	