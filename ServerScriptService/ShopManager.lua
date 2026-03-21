-- @ScriptType: Script
-- @ScriptType: Script
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local Network = ReplicatedStorage:WaitForChild("Network")
local GetShopData = Network:WaitForChild("GetShopData")
local BuyAction = Network:FindFirstChild("ShopAction") or Instance.new("RemoteEvent", Network)
BuyAction.Name = "ShopAction"

local function GenerateShopItems(seed)
	local rng = Random.new(seed)
	local shopItems = {}

	local validItems = {}
	for k, v in pairs(ItemData.Equipment) do if v.Rarity ~= "Legendary" and v.Rarity ~= "Mythical" then table.insert(validItems, {Name=k, Cost=v.Cost or 1000}) end end
	for k, v in pairs(ItemData.Consumables) do if v.Rarity ~= "Legendary" and v.Rarity ~= "Mythical" then table.insert(validItems, {Name=k, Cost=v.Cost or 1000}) end end

	for i = 1, 6 do
		if #validItems == 0 then break end
		local idx = rng:NextInteger(1, #validItems)
		table.insert(shopItems, validItems[idx])
		table.remove(validItems, idx)
	end
	return shopItems
end

GetShopData.OnServerInvoke = function(player)
	local globalSeed = math.floor(os.time() / 600)
	local personalSeed = player:GetAttribute("PersonalShopSeed") or 0

	if player:GetAttribute("ShopSeedTime") ~= globalSeed then
		player:SetAttribute("PersonalShopSeed", nil)
		personalSeed = globalSeed
	end

	local activeSeed = player:GetAttribute("PersonalShopSeed") or globalSeed
	if player:GetAttribute("ShopPurchases_Seed") ~= activeSeed then
		player:SetAttribute("ShopPurchases_Seed", activeSeed)
		player:SetAttribute("ShopPurchases_Data", "") -- Reset bought items on new shop rotation
	end

	local timeRemaining = 600 - (os.time() % 600)
	local items = GenerateShopItems(personalSeed)

	-- Mark items as sold out if the player already bought them in this rotation
	local boughtStr = player:GetAttribute("ShopPurchases_Data") or ""
	for _, item in ipairs(items) do
		if string.find(boughtStr, "%[" .. item.Name .. "%]") then
			item.SoldOut = true
		end
	end

	return { Items = items, TimeLeft = timeRemaining }
end

BuyAction.OnServerEvent:Connect(function(player, itemName)
	local globalSeed = math.floor(os.time() / 600)
	local activeSeed = player:GetAttribute("PersonalShopSeed") or globalSeed
	local availableItems = GenerateShopItems(activeSeed)

	local targetItem = nil
	for _, item in ipairs(availableItems) do
		if item.Name == itemName then targetItem = item; break end
	end

	if targetItem then
		local boughtStr = player:GetAttribute("ShopPurchases_Data") or ""
		if string.find(boughtStr, "%[" .. targetItem.Name .. "%]") then return end -- Block double purchase!

		if player.leaderstats.Dews.Value >= targetItem.Cost then
			player.leaderstats.Dews.Value -= targetItem.Cost
			local attrName = itemName:gsub("[^%w]", "") .. "Count"
			player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)

			player:SetAttribute("ShopPurchases_Data", boughtStr .. "[" .. targetItem.Name .. "]")
		end
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	for _, prod in ipairs(ItemData.Products) do
		if prod.ID == receiptInfo.ProductId then
			if prod.IsReroll then
				player:SetAttribute("PersonalShopSeed", math.random(1, 9999999))
				player:SetAttribute("ShopSeedTime", math.floor(os.time() / 600))
			elseif prod.Reward == "Dews" then
				player.leaderstats.Dews.Value += prod.Amount
			elseif prod.Reward == "Item" then
				local attrName = prod.ItemName:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + prod.Amount)
			end
			break
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end