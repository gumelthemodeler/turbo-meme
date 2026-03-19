-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local UseItemRemote = Network:FindFirstChild("UseItem") or Instance.new("RemoteEvent", Network)
UseItemRemote.Name = "UseItem"

local UnequipItemRemote = Network:FindFirstChild("UnequipItem") or Instance.new("RemoteEvent", Network)
UnequipItemRemote.Name = "UnequipItem"

local ToggleLockRemote = Network:FindFirstChild("ToggleLock") or Instance.new("RemoteEvent", Network)
ToggleLockRemote.Name = "ToggleLock"

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

UnequipItemRemote.OnServerEvent:Connect(function(player, slot)
	if slot == "Weapon" or slot == "Accessory" or slot == "Head" or slot == "Torso" or slot == "Legs" then
		local currentEq = player:GetAttribute("Equipped" .. slot)
		if currentEq and currentEq ~= "None" then
			player:SetAttribute("Equipped" .. slot, "None")
			local notif = Network:FindFirstChild("NotificationEvent")
			if notif then notif:FireClient(player, "<font color='#FF5555'>Unequipped " .. currentEq .. "!</font>") end
		end
	end
end)

ToggleLockRemote.OnServerEvent:Connect(function(player, lockType, extraData)
	if lockType == "Titan" then
		player:SetAttribute("TitanLocked", not player:GetAttribute("TitanLocked"))
	elseif lockType == "Style" then
		player:SetAttribute("StyleLocked", not player:GetAttribute("StyleLocked"))
	elseif lockType == "Item" and extraData then
		local itemName = tostring(extraData)
		local lockedItems = player:GetAttribute("LockedItems") or ""
		local itemsList = string.split(lockedItems, ",")

		local foundIndex = table.find(itemsList, itemName)
		if foundIndex then
			table.remove(itemsList, foundIndex)
		else
			table.insert(itemsList, itemName)
		end

		local cleanList = {}
		for _, v in ipairs(itemsList) do if v ~= "" then table.insert(cleanList, v) end end
		player:SetAttribute("LockedItems", table.concat(cleanList, ","))
	end
end)

local function GetPlayerBoosts(player)
	local boosts = { Luck = 0 }
	if player:GetAttribute("IsSupporter") then boosts.Luck += 1 end
	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 3000 then boosts.Luck += 1 end
	local cLuck = player:GetAttribute("ClanLuckBoost") or 1.0
	if cLuck > 1.0 then boosts.Luck += 1 end 
	return boosts
end

local AutoRollRemote = Network:FindFirstChild("AutoRoll") or Instance.new("RemoteEvent", Network)
AutoRollRemote.Name = "AutoRoll"

AutoRollRemote.OnServerEvent:Connect(function(player, rollType, targetTitan, targetTrait)
	if player:GetAttribute("IsAutoRolling") then return end
	player:SetAttribute("IsAutoRolling", true)

	local itemReq = ""
	local expectedPool = "Serum"

	if rollType == "Serum" then 
		itemReq = "Standard Titan Serum"; expectedPool = "Serum"
	elseif rollType == "Syringe" then 
		itemReq = "Spinal Fluid Syringe" 
	end

	local attr = itemReq:gsub("[^%w]", "") .. "Count"
	local count = player:GetAttribute(attr) or 0

	if count <= 0 then 
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You do not have any " .. itemReq .. "s!</font>")
		player:SetAttribute("IsAutoRolling", false)
		return 
	end

	if targetTitan ~= "Any" and rollType == "Serum" then
		local tData = TitanData.Titans[targetTitan]
		if tData then
			if tData.Rarity == "Evolution" or tData.Rarity == "Unique" or tData.Rarity == "Mythical" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. targetTitan .. " cannot be rolled from items!</font>")
				player:SetAttribute("IsAutoRolling", false)
				return
			end
		end
	end

	local newTitan = player:GetAttribute("Titan") or "None"
	local newTrait = player:GetAttribute("TitanTrait") or "None"

	if player:GetAttribute("TitanLocked") then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Titan is locked! Unlock it before Auto-Rolling.</font>")
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	if rollType == "Syringe" and newTitan == "None" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You don't have a Titan to inject fluid into!</font>")
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	local pBoosts = GetPlayerBoosts(player)
	local tPity = player:GetAttribute("TitanPity") or 0
	local trPity = player:GetAttribute("TraitPity") or 0
	local rollsDone = 0
	local hit = false

	while count > 0 do
		count -= 1
		rollsDone += 1

		if rollType == "Serum" then
			newTitan = TitanData.RollTitan(tPity)
			newTrait = TitanData.RollTrait()
		elseif rollType == "Syringe" then
			newTrait = TitanData.RollTrait()
		end

		if TitanData.Titans[newTitan] and TitanData.Titans[newTitan].Rarity == "Legendary" then tPity = 0 else tPity += 1 end
		-- Simulated trait rarity checks (Assuming Transcendent/Awakened are Mythical/Legendary equivalents)
		if newTrait == "Transcendent" or newTrait == "Awakened" then trPity = 0 else trPity += 1 end

		local wantTitan = targetTitan ~= "Any"
		local wantTrait = targetTrait ~= "Any"
		local titanMatch = (wantTitan and newTitan == targetTitan)
		local traitMatch = (wantTrait and newTrait == targetTrait)

		if wantTitan and wantTrait then
			if titanMatch and traitMatch then hit = true; break end
		elseif wantTitan then
			if titanMatch then hit = true; break end
		elseif wantTrait then
			if traitMatch then hit = true; break end
		else
			hit = true; break
		end

		if rollsDone % 100 == 0 then task.wait() end
	end

	player:SetAttribute(attr, count)
	player:SetAttribute("Titan", newTitan)
	player:SetAttribute("TitanTrait", newTrait)
	player:SetAttribute("TitanPity", tPity)
	player:SetAttribute("TraitPity", trPity)

	if newTitan ~= "None" and TitanData.Titans[newTitan] then
		for statName, rank in pairs(TitanData.Titans[newTitan].Stats) do player:SetAttribute("Titan_"..statName, rank) end
	end

	local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
	if hit then
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Auto-Roll successful! Used " .. rollsDone .. "x " .. itemReq .. ".\nGot: " .. newTitan .. traitTag .. "</font>")
	else
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Ran out of " .. itemReq .. "s! Used " .. rollsDone .. ".\nEnded with: " .. newTitan .. traitTag .. "</font>")
	end

	player:SetAttribute("IsAutoRolling", false)
end)

local function HandleGiftboxDrop(player, targetRarity)
	local pool = {}
	for name, data in pairs(ItemData.Equipment) do 
		if data.Rarity == targetRarity then table.insert(pool, name) end 
	end
	for name, data in pairs(ItemData.Consumables) do 
		if data.Rarity == targetRarity then table.insert(pool, name) end 
	end

	if #pool > 0 then
		local itemName = pool[math.random(#pool)]
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]

		if player:GetAttribute("AutoSell_" .. targetRarity) then
			local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Yen") then
				leaderstats.Yen.Value += sellVal -- Kept leaderstats key as 'Yen' so old saves don't break, but displays as Dews
			end
			return "You opened the box and found a " .. itemName .. ", but it was Auto-Sold for " .. sellVal .. " Dews!"
		else
			local currentInv = GameData.GetInventoryCount(player)
			local maxInv = GameData.GetMaxInventory(player)
			local attr = itemName:gsub("[^%w]", "") .. "Count"
			player:SetAttribute(attr, (player:GetAttribute(attr) or 0) + 1)
			return "You opened the box and received a " .. itemName .. "!"
		end
	end
	return "The box was empty..."
end

UseItemRemote.OnServerEvent:Connect(function(player, itemName)
	local attrName = itemName:gsub("[^%w]", "") .. "Count"
	local itemCount = player:GetAttribute(attrName) or 0

	if itemCount > 0 then
		local message = ""
		local prestige = player.leaderstats.Prestige.Value
		local statCap = GameData.GetStatCap(prestige)
		local myTitan = player:GetAttribute("Titan") or "None"
		local itemConsumed = true

		if ItemData.Equipment[itemName] then
			local equipSlot = ItemData.Equipment[itemName].Slot
			player:SetAttribute("Equipped" .. equipSlot, itemName)
			message = "Equipped " .. itemName .. " as " .. equipSlot .. "!"
			NotificationEvent:FireClient(player, "<font color='#55FF55'>" .. message .. "</font>")
			return
		end

		local isTitanItem = (itemName == "Standard Titan Serum" or itemName == "Founder's Memory Wipe" or itemName == "Spinal Fluid Syringe" or itemName == "Ymir's Clay Fragment")
		local isStyleItem = (itemName == "Scout Training Manual" or itemName == "Marleyan Combat Manual" or itemName == "Thunder Spear Crate" or itemName == "Anti-Personnel Blueprint")

		if isTitanItem and player:GetAttribute("TitanLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Titan is locked! Unlock it to use this item.</font>")
			return
		end

		if isStyleItem and player:GetAttribute("StyleLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Combat Style is locked! Unlock it to use this item.</font>")
			return
		end

		local function EvolveTitan(newTitan)
			player:SetAttribute("Titan", newTitan)
			-- If the evolved Titan doesn't natively exist in TitanData, we can hardcode fallback stats here
			local tData = TitanData.Titans[newTitan]
			if tData then
				for statName, rank in pairs(tData.Stats) do player:SetAttribute("Titan_"..statName, rank) end
			else
				-- Hardcoded stats for "Awakened Attack Titan" if not strictly registered in TitanData yet
				player:SetAttribute("Titan_Power", "S")
				player:SetAttribute("Titan_Speed", "S")
				player:SetAttribute("Titan_Hardening", "A")
				player:SetAttribute("Titan_Endurance", "S")
				player:SetAttribute("Titan_Precision", "A")
				player:SetAttribute("Titan_Potential", "S")
			end
		end

		if itemName == "Legendary Giftbox" then
			message = HandleGiftboxDrop(player, "Legendary")
		elseif itemName == "Mythical Giftbox" then
			message = HandleGiftboxDrop(player, "Mythical")

			-- [[ GAMEPASSES ]]
		elseif itemName == "2x Battle Speed Pass" then
			if player:GetAttribute("Has2xBattleSpeed") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xBattleSpeed", true); message = "Unlocked 2x Battle Speed!" end
		elseif itemName == "2x Inventory Pass" then
			if player:GetAttribute("Has2xInventory") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xInventory", true); message = "Unlocked 2x Inventory Space!" end
		elseif itemName == "2x Drop Chance Pass" then
			if player:GetAttribute("Has2xDropChance") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xDropChance", true); message = "Unlocked 2x Drop Chance!" end
		elseif itemName == "Auto Training Pass" then
			if player:GetAttribute("HasAutoTraining") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoTraining", true); message = "Unlocked Auto Training!" end
		elseif itemName == "Titan Storage Slot 2" then
			if player:GetAttribute("HasTitanSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasTitanSlot2", true); message = "Unlocked Titan Storage Slot 2!" end
		elseif itemName == "Titan Storage Slot 3" then
			if player:GetAttribute("HasTitanSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasTitanSlot3", true); message = "Unlocked Titan Storage Slot 3!" end
		elseif itemName == "Style Storage Slot 2" then
			if player:GetAttribute("HasStyleSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot2", true); message = "Unlocked Style Storage Slot 2!" end
		elseif itemName == "Style Storage Slot 3" then
			if player:GetAttribute("HasStyleSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot3", true); message = "Unlocked Style Storage Slot 3!" end
		elseif itemName == "Auto-Roll Pass" then
			if player:GetAttribute("HasAutoRoll") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoRoll", true); message = "Unlocked Auto-Roll!" end

			-- [[ TITAN CONSUMABLES ]]
		elseif itemName == "Standard Titan Serum" then
			local currentTitanPity = player:GetAttribute("TitanPity") or 0
			local newTitan = TitanData.RollTitan(currentTitanPity)
			local newTrait = TitanData.RollTrait()

			if TitanData.Titans[newTitan] and TitanData.Titans[newTitan].Rarity == "Legendary" then player:SetAttribute("TitanPity", 0)
			else player:SetAttribute("TitanPity", currentTitanPity + 1) end

			-- Also roll Clan if the player doesn't have one
			if player:GetAttribute("Clan") == "None" or not player:GetAttribute("Clan") then
				local newClan = TitanData.RollClan()
				player:SetAttribute("Clan", newClan)
				NotificationEvent:FireClient(player, "<font color='#FFD700'>Lineage Discovered: " .. newClan .. "!</font>")
			end

			player:SetAttribute("Titan", newTitan)
			player:SetAttribute("TitanTrait", newTrait)

			if TitanData.Titans[newTitan] then
				for statName, rank in pairs(TitanData.Titans[newTitan].Stats) do player:SetAttribute("Titan_"..statName, rank) end
			end

			local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
			message = "You injected the Serum! Awakened Titan: " .. newTitan .. traitTag .. "!"

		elseif itemName == "Spinal Fluid Syringe" then
			if myTitan == "None" then
				message = "You don't have a Titan to mutate!"; itemConsumed = false
			else
				local currentTraitPity = player:GetAttribute("TraitPity") or 0
				local newTrait = TitanData.RollTrait()

				player:SetAttribute("TitanTrait", newTrait)
				if newTrait == "Transcendent" or newTrait == "Awakened" then player:SetAttribute("TraitPity", 0) else player:SetAttribute("TraitPity", currentTraitPity + 1) end

				local traitDisplay = newTrait ~= "None" and "<font color='#FFFF55'>["..newTrait.."]</font>" or "None"
				message = "You injected the Spinal Fluid! Your Titan's trait mutated into: " .. traitDisplay .. "!"
			end

		elseif itemName == "Founder's Memory Wipe" then
			if myTitan == "None" and player:GetAttribute("FightingStyle") == "None" then
				message = "You have no memories or powers to wipe!"; itemConsumed = false
			else
				player:SetAttribute("Titan", "None")
				player:SetAttribute("TitanTrait", "None")
				player:SetAttribute("FightingStyle", "None")
				local titanStatsList = {"Power", "Speed", "Hardening", "Endurance", "Precision", "Potential"}
				for _, s in ipairs(titanStatsList) do player:SetAttribute("Titan_" .. s, "None") end
				message = "Your memories fade. You are a blank slate once again."
			end

		elseif itemName == "Ymir's Clay Fragment" then
			-- The "Solo Leveling" Diamond in the Rough Feature
			if myTitan == "Attack Titan" then 
				EvolveTitan("Awakened Attack Titan") 
				message = "Ymir's memory floods your mind! Your Attack Titan has evolved into the Awakened Attack Titan!"
			else 
				message = "The fragment has no reaction to this Titan."; itemConsumed = false 
			end

			-- [[ COMBAT STYLES & CLANS ]]
		elseif itemName == "Ackerman Awakening Pill" then
			player:SetAttribute("Clan", "Ackerman")
			message = "A surge of violent instinct takes over! You have awakened the Ackerman Lineage!"
		elseif itemName == "Scout Training Manual" then
			player:SetAttribute("FightingStyle", "Ultrahard Steel Blades"); message = "You read the manual. Gained Ultrahard Steel Blades Combat Style."
		elseif itemName == "Marleyan Combat Manual" then
			player:SetAttribute("FightingStyle", "Marleyan Rifle"); message = "You studied Marleyan tactics. Gained Marleyan Rifle Combat Style."
		elseif itemName == "Thunder Spear Crate" then
			player:SetAttribute("FightingStyle", "Thunder Spears"); message = "You acquired explosive payloads. Gained Thunder Spears Combat Style."
		elseif itemName == "Anti-Personnel Blueprint" then
			player:SetAttribute("FightingStyle", "Anti-Personnel Firearms"); message = "You learned urban combat techniques. Gained Anti-Personnel Firearms Style."
		else
			itemConsumed = false
		end

		if itemConsumed then
			player:SetAttribute(attrName, itemCount - 1)
			NotificationEvent:FireClient(player, "<font color='#FF55FF'>" .. message .. "</font>")
		end
	end
end)