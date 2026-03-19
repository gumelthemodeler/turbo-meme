-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local ShopAction = Network:WaitForChild("ShopAction")
local ShopUpdate = Network:WaitForChild("ShopUpdate")
local NotificationEvent = Network:WaitForChild("NotificationEvent")

-- Fixed Items (Always available)
local FixedStock = {
	"Scout Training Manual",
	"Cadet Training Blade"
}

-- Rotating Items (Randomly selected every hour)
local RotatingPool = {
	"Standard Titan Serum",
	"Founder's Memory Wipe",
	"Ultrahard Steel Blades",
	"Marleyan Combat Manual",
	"Anti-Personnel Pistols",
	"Scout Regiment Cloak",
	"Marleyan Armband"
}

local function GenerateShopStock()
	local stock = {}
	for _, item in ipairs(FixedStock) do table.insert(stock, item) end

	-- Pick 4 random items for the rotating slot
	local tempPool = {table.unpack(RotatingPool)}
	for i = 1, 4 do
		if #tempPool > 0 then
			local rIdx = math.random(1, #tempPool)
			table.insert(stock, table.remove(tempPool, rIdx))
		end
	end
	return table.concat(stock, ",")
end

-- Refresh shops for all players if their timer expires
task.spawn(function()
	while task.wait(10) do
		local currentTime = os.time()
		for _, player in ipairs(Players:GetPlayers()) do
			local refreshTime = player:GetAttribute("ShopRefreshTime") or 0
			if currentTime >= refreshTime then
				player:SetAttribute("ShopStock", GenerateShopStock())
				player:SetAttribute("ShopRefreshTime", currentTime + 3600) -- 1 Hour
				ShopUpdate:FireClient(player, "Restock")
			end
		end
	end
end)

ShopAction.OnServerEvent:Connect(function(player, action, itemName)
	if action == "BuyItem" then
		local currentStock = player:GetAttribute("ShopStock") or ""
		local stockList = string.split(currentStock, ",")

		if not table.find(stockList, itemName) then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>The merchant does not have this in stock.</font>")
			return
		end

		local itemInfo = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		if not itemInfo then return end

		local cost = itemInfo.Cost or 999999
		if player.leaderstats.Yen.Value < cost then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You lack the necessary Dews (" .. cost .. ").</font>")
			return
		end

		-- Transaction
		player.leaderstats.Yen.Value -= cost
		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)

		NotificationEvent:FireClient(player, "<font color='#55FF55'>Procured " .. itemName .. " for " .. cost .. " Dews.</font>")
	end
end)