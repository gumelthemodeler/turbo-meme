-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local ShopAction = Network:WaitForChild("ShopAction")
local ShopUpdate = Network:WaitForChild("ShopUpdate")

local function RollItem(forcedRarity)
	local targetRarity = "Common"
	if forcedRarity then
		targetRarity = forcedRarity
	else
		local rng = math.random(1, 100)
		if rng <= 5 then targetRarity = "Legendary"
		elseif rng <= 20 then targetRarity = "Rare"
		elseif rng <= 50 then targetRarity = "Uncommon"
		end
	end

	local validItems = {}
	for itemName, itemInfo in pairs(ItemData.Equipment) do
		if (itemInfo.Rarity or "Common") == targetRarity then table.insert(validItems, itemName) end
	end
	for itemName, itemInfo in pairs(ItemData.Consumables) do
		if (itemInfo.Rarity or "Common") == targetRarity then table.insert(validItems, itemName) end
	end

	if #validItems > 0 then return validItems[math.random(1, #validItems)] end
	return "Wooden Bat"
end

local function GenerateShopStock(player)
	local shopPity = (player:GetAttribute("ShopPity") or 0) + 1
	local hasLegendary = false
	local newStock = {}

	for i = 1, 6 do
		local item = RollItem()
		local itemInfo = ItemData.Equipment[item] or ItemData.Consumables[item]
		if itemInfo and itemInfo.Rarity == "Legendary" then hasLegendary = true end
		table.insert(newStock, item)
	end

	if shopPity >= 10 then
		if not hasLegendary then newStock[math.random(1, 6)] = RollItem("Legendary") end
		shopPity = 0 
	elseif hasLegendary then
		shopPity = 0 
	end

	player:SetAttribute("ShopPity", shopPity)
	player:SetAttribute("ShopStock", table.concat(newStock, ","))
	player:SetAttribute("ShopRefreshTime", os.time() + 900) 
	ShopUpdate:FireClient(player, "Refresh", newStock)
end

task.spawn(function()
	while task.wait(1) do
		for _, player in ipairs(game.Players:GetPlayers()) do
			local refreshTime = player:GetAttribute("ShopRefreshTime")
			if refreshTime and os.time() >= refreshTime then GenerateShopStock(player) end
		end
	end
end)

game.Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("ShopRefreshTime"):Connect(function()
		local rt = player:GetAttribute("ShopRefreshTime")
		if rt and rt < os.time() then GenerateShopStock(player) end
	end)
end)

ShopAction.OnServerEvent:Connect(function(player, action, data)
	if action == "SetGiftTarget" then
		local targetId = tonumber(data)
		if targetId and targetId ~= 0 then 
			player:SetAttribute("GiftTarget", targetId)
		else
			player:SetAttribute("GiftTarget", nil)
		end
		return
	end

	if action == "ClaimShopStand" then
		local pendingStand = player:GetAttribute("PendingShopStand")
		local pendingTrait = player:GetAttribute("PendingShopTrait") or "None"
		if not pendingStand or pendingStand == "" then return end

		if data == "Deny" then
			player:SetAttribute("PendingShopStand", nil)
			player:SetAttribute("PendingShopTrait", nil)
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You declined the gifted Stand.</font>")
			return
		end

		local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
		local stats = StandData.Stands[pendingStand] and StandData.Stands[pendingStand].Stats

		if data == "Active" then
			player:SetAttribute("Stand", pendingStand)
			player:SetAttribute("StandTrait", pendingTrait)
			if stats then
				for sName, sRank in pairs(stats) do
					local rankVal = GameData.StandRanks[sRank] or 0
					player:SetAttribute("Stand_" .. sName .. "_Val", rankVal + (prestige * 5))
				end
			end
		elseif data == "Slot1" then
			player:SetAttribute("StoredStand1", pendingStand)
			player:SetAttribute("StoredStand1_Trait", pendingTrait)
		elseif data == "Slot2" and player:GetAttribute("HasStandSlot2") then
			player:SetAttribute("StoredStand2", pendingStand)
			player:SetAttribute("StoredStand2_Trait", pendingTrait)
		elseif data == "Slot3" and player:GetAttribute("HasStandSlot3") then
			player:SetAttribute("StoredStand3", pendingStand)
			player:SetAttribute("StoredStand3_Trait", pendingTrait)
		elseif data == "Slot4" and prestige >= 15 then
			player:SetAttribute("StoredStand4", pendingStand)
			player:SetAttribute("StoredStand4_Trait", pendingTrait)
		elseif data == "Slot5" and prestige >= 30 then
			player:SetAttribute("StoredStand5", pendingStand)
			player:SetAttribute("StoredStand5_Trait", pendingTrait)
		end

		player:SetAttribute("PendingShopStand", nil)
		player:SetAttribute("PendingShopTrait", nil)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Successfully claimed " .. pendingStand .. " to " .. data .. "!</font>")
		return
	end

	if action == "ClaimShopStyle" then
		local pendingStyle = player:GetAttribute("PendingShopStyle")
		if not pendingStyle or pendingStyle == "" then return end

		if data == "Deny" then
			player:SetAttribute("PendingShopStyle", nil)
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You declined the gifted Style.</font>")
			return
		end

		if data == "Active" then
			player:SetAttribute("FightingStyle", pendingStyle)
		elseif data == "Slot1" then
			player:SetAttribute("StoredStyle1", pendingStyle)
		elseif data == "Slot2" and player:GetAttribute("HasStyleSlot2") then
			player:SetAttribute("StoredStyle2", pendingStyle)
		elseif data == "Slot3" and player:GetAttribute("HasStyleSlot3") then
			player:SetAttribute("StoredStyle3", pendingStyle)
		end

		player:SetAttribute("PendingShopStyle", nil)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF8C00'>Successfully claimed " .. pendingStyle .. " to " .. data .. "!</font>")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local yen = leaderstats:FindFirstChild("Yen")
	if not yen then return end

	if action == "Buy" then
		local itemName = data
		local stockStr = player:GetAttribute("ShopStock") or ""
		local stockList = string.split(stockStr, ",")
		local itemIndex = table.find(stockList, itemName)
		if not itemIndex then return end

		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		if not itemData then return end

		local isIgnored = (itemName == "Stand Arrow" or itemName == "Rokakaka" or itemName == "Heavenly Stand Disc")
		if not isIgnored and GameData.GetInventoryCount(player) >= GameData.GetMaxInventory(player) then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Inventory Full!</font>")
			return
		end

		local cost = itemData.Cost or 0
		if yen.Value >= cost then
			yen.Value -= cost
			local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
			if gangEvent then gangEvent:Fire(player:GetAttribute("Gang"), "Yen", cost) end

			local attrName = itemName:gsub("[^%w]", "") .. "Count"
			player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
			table.remove(stockList, itemIndex)
			player:SetAttribute("ShopStock", table.concat(stockList, ","))
			Network.CombatUpdate:FireClient(player, "SystemMessage", "Purchased " .. itemName .. "!")
		else
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Not enough Yen!</font>")
		end

	elseif action == "RestockYen" then
		local cost = 50000
		if yen.Value >= cost then
			yen.Value -= cost
			local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
			if gangEvent then gangEvent:Fire(player:GetAttribute("Gang"), "Yen", cost) end

			player:SetAttribute("ShopRefreshTime", 0) 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Restocked Shop for 50k Yen!</font>")
		else
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Not enough Yen to restock!</font>")
		end

	elseif action == "Sell" then
		local itemName = data

		local lockedItems = player:GetAttribute("LockedItems") or ""
		local isLocked = table.find(string.split(lockedItems, ","), itemName) ~= nil
		if isLocked then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Cannot sell a locked item!</font>")
			return
		end

		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		local count = player:GetAttribute(attrName) or 0
		if count > 0 then
			local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			if not itemData then return end

			local sellPrice = math.floor((itemData.Cost or 50) * 0.5)
			player:SetAttribute(attrName, count - 1)

			if count - 1 == 0 and itemData.Slot then
				if player:GetAttribute("Equipped" .. itemData.Slot) == itemName then
					player:SetAttribute("Equipped" .. itemData.Slot, "None")
				end
			end
			yen.Value += sellPrice
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Sold " .. itemName .. " for ¥" .. sellPrice .. "!</font>")
		end
	end
end)