-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))

local StorageAction = Network:FindFirstChild("StorageAction") or Instance.new("RemoteEvent", Network)
StorageAction.Name = "StorageAction"

local NotificationEvent = Network:FindFirstChild("NotificationEvent")

local function SendMsg(player, msg, color)
	if NotificationEvent then
		NotificationEvent:FireClient(player, "<font color='" .. (color or "#FF5555") .. "'>" .. msg .. "</font>")
	end
end

StorageAction.OnServerEvent:Connect(function(player, action, slotNum)
	if type(slotNum) ~= "number" then return end

	if action == "StoreTitan" then
		if player:GetAttribute("TitanLocked") then
			SendMsg(player, "Your Titan is locked! Unlock it before swapping.")
			return
		end

		if slotNum == 2 and not player:GetAttribute("HasTitanSlot2") then
			SendMsg(player, "You need the Titan Storage Slot 2 Gamepass!")
			return
		elseif slotNum == 3 and not player:GetAttribute("HasTitanSlot3") then
			SendMsg(player, "You need the Titan Storage Slot 3 Gamepass!")
			return
		elseif slotNum > 3 and slotNum <= 5 then
			-- Slots 4 and 5 are handled by data but restricted for future use or VIPs
			SendMsg(player, "This high-capacity storage slot is currently restricted.")
			return
		elseif slotNum > 5 then
			return
		end

		local currentTitan = player:GetAttribute("Titan") or "None"
		local currentTrait = player:GetAttribute("TitanTrait") or "None"
		local storedTitan = player:GetAttribute("StoredTitan" .. slotNum) or "None"
		local storedTrait = player:GetAttribute("StoredTitan" .. slotNum .. "_Trait") or "None"

		if currentTitan == "None" and storedTitan == "None" then
			SendMsg(player, "There are no Titans to swap!")
			return
		end

		-- Swap the Titan and Trait
		player:SetAttribute("Titan", storedTitan)
		player:SetAttribute("TitanTrait", storedTrait)

		player:SetAttribute("StoredTitan" .. slotNum, currentTitan)
		player:SetAttribute("StoredTitan" .. slotNum .. "_Trait", currentTrait)

		-- Update the Titan Stats based on the newly equipped Titan
		local titanStatsList = {"Power", "Speed", "Hardening", "Endurance", "Precision", "Potential"}
		if storedTitan ~= "None" and TitanData.Titans[storedTitan] then
			local stats = TitanData.Titans[storedTitan].Stats
			for statName, rank in pairs(stats) do
				player:SetAttribute("Titan_"..statName, rank)
			end
		else
			for _, s in ipairs(titanStatsList) do
				player:SetAttribute("Titan_"..s, "None")
			end
		end

		SendMsg(player, "Successfully swapped Titans!", "#55FF55")

	elseif action == "StoreStyle" then
		if player:GetAttribute("StyleLocked") then
			SendMsg(player, "Your Combat Style is locked! Unlock it before swapping.")
			return
		end

		if slotNum == 2 and not player:GetAttribute("HasStyleSlot2") then
			SendMsg(player, "You need the Style Storage Slot 2 Gamepass!")
			return
		elseif slotNum == 3 and not player:GetAttribute("HasStyleSlot3") then
			SendMsg(player, "You need the Style Storage Slot 3 Gamepass!")
			return
		elseif slotNum > 3 then
			SendMsg(player, "This storage slot is unavailable.")
			return
		end

		local currentStyle = player:GetAttribute("FightingStyle") or "None"
		local storedStyle = player:GetAttribute("StoredStyle" .. slotNum) or "None"

		if currentStyle == "None" and storedStyle == "None" then
			SendMsg(player, "There is no Combat Style to swap!")
			return
		end

		-- Swap the Combat Style
		player:SetAttribute("FightingStyle", storedStyle)
		player:SetAttribute("StoredStyle" .. slotNum, currentStyle)

		SendMsg(player, "Successfully swapped Combat Styles!", "#55FF55")
	end
end)