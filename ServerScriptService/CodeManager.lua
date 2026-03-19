-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local RedeemCode = Network:WaitForChild("RedeemCode")

local ActiveCodes = {
	["BIZARRE"] = {Yen = 1000, XP = 2500, Items = {["Stand Arrow"] = 1}},
	["250KVISITS"] = {Items = {["Stand Arrow"] = 250, ["Rokakaka"] = 250, ["Saint's Corpse Part"] = 100}},
	["2KFAVS"] = {Items = {["Stand Arrow"] = 20, ["Rokakaka"] = 20, ["Saint's Corpse Part"] = 2}},
	["1KLIKES"] = {Items = {["Legendary Giftbox"] = 10, ["Mythical Giftbox"] = 1}},
	["INVFIX"] = {Items = {["Legendary Giftbox"] = 10, ["Mythical Giftbox"] = 1}},
	["GANGSUPD"] = {Items = {["Stand Arrow"] = 10, ["Rokakaka"] = 5, ["Saint's Corpse Part"] = 3}},
	["STEEL PIPE"] = {Items = {["Steel Pipe (x400)"] = 1}}
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
		local yenReward = reward.Yen or 0

		if yenReward > 0 then
			player.leaderstats.Yen.Value += yenReward
		end
		if xpReward > 0 then
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpReward)
		end

		local rewardStrings = {}
		if xpReward > 0 then table.insert(rewardStrings, "+" .. xpReward .. " XP") end
		if yenReward > 0 then table.insert(rewardStrings, "+" .. yenReward .. " Yen") end

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