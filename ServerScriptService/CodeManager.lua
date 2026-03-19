-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local RedeemCode = Network:WaitForChild("RedeemCode")

local ActiveCodes = {
	["SHIGANSHINA"] = {Dews = 1000, XP = 2500, Items = {["Standard Titan Serum"] = 1}},
	["250KVISITS"] = {Items = {["Standard Titan Serum"] = 50, ["Founder's Memory Wipe"] = 50, ["Spinal Fluid Syringe"] = 10}},
	["2KFAVS"] = {Items = {["Standard Titan Serum"] = 10, ["Founder's Memory Wipe"] = 10, ["Spinal Fluid Syringe"] = 2}},
	["1KLIKES"] = {Items = {["Legendary Giftbox"] = 10, ["Mythical Giftbox"] = 1}},
	["INVFIX"] = {Items = {["Legendary Giftbox"] = 10, ["Mythical Giftbox"] = 1}},
	["CLANSUPD"] = {Items = {["Standard Titan Serum"] = 10, ["Founder's Memory Wipe"] = 5, ["Ymir's Clay Fragment"] = 1}},
	["THUNDERSPEAR"] = {Items = {["Thunder Spear"] = 1}}
}

RedeemCode.OnServerEvent:Connect(function(player, codeStr)
	if type(codeStr) ~= "string" then return end

	codeStr = string.upper(string.match(codeStr, "^%s*(.-)%s*$"))

	local redeemedStr = player:GetAttribute("RedeemedCodes") or ""
	local redeemedList = string.split(redeemedStr, ",")

	if table.find(redeemedList, codeStr) then
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Code '" .. codeStr .. "' has already been redeemed!</font>")
		return
	end

	local reward = ActiveCodes[codeStr]
	if reward then
		local xpReward = reward.XP or 0
		local dewsReward = reward.Dews or 0

		if dewsReward > 0 then
			player.leaderstats.Yen.Value += dewsReward -- Still uses Yen internally for backward compat, displays as Dews
		end
		if xpReward > 0 then
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpReward)
		end

		local rewardStrings = {}
		if xpReward > 0 then table.insert(rewardStrings, "+" .. xpReward .. " XP") end
		if dewsReward > 0 then table.insert(rewardStrings, "+" .. dewsReward .. " Dews") end

		if reward.Items then
			for itemName, amount in pairs(reward.Items) do
				local attrName = itemName:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + amount)
				table.insert(rewardStrings, "+" .. amount .. " " .. itemName)
			end
		end

		table.insert(redeemedList, codeStr)
		player:SetAttribute("RedeemedCodes", table.concat(redeemedList, ","))

		local currentInv = GameData.GetInventoryCount(player)
		local maxInv = player:GetAttribute("Has2xInventory") and 30 or 15
		local capNotice = (reward.Items and currentInv > maxInv) and " <font color='#AAAAAA'>(Bypassed Inventory Cap)</font>" or ""

		local finalMsg = "<font color='#55FF55'>Code '" .. codeStr .. "' redeemed!</font>"
		if #rewardStrings > 0 then
			finalMsg = finalMsg .. " <font color='#FFFF55'>(" .. table.concat(rewardStrings, ", ") .. ")</font>"
		end

		Network.CombatUpdate:FireClient(player, "SystemMessage", finalMsg .. capNotice)
	else
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Invalid or expired code!</font>")
	end
end)