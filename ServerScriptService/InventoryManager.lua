-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
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
	if lockType == "Stand" then
		player:SetAttribute("StandLocked", not player:GetAttribute("StandLocked"))
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
	local gLuck = player:GetAttribute("GangLuckBoost") or 1.0
	if gLuck > 1.0 then boosts.Luck += 1 end 
	return boosts
end

local AutoRollRemote = Network:FindFirstChild("AutoRoll") or Instance.new("RemoteEvent", Network)
AutoRollRemote.Name = "AutoRoll"

AutoRollRemote.OnServerEvent:Connect(function(player, rollType, targetStand, targetTrait)
	if player:GetAttribute("IsAutoRolling") then return end
	player:SetAttribute("IsAutoRolling", true)

	local itemReq = ""
	local expectedPool = "Arrow"

	if rollType == "Arrow" then 
		itemReq = "Stand Arrow"; expectedPool = "Arrow"
	elseif rollType == "Corpse" then 
		itemReq = "Saint's Corpse Part"; expectedPool = "Corpse"
	elseif rollType == "Roka" then 
		itemReq = "Rokakaka" 
	end

	local attr = itemReq:gsub("[^%w]", "") .. "Count"
	local count = player:GetAttribute(attr) or 0

	if count <= 0 then 
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You do not have any " .. itemReq .. "s!</font>")
		player:SetAttribute("IsAutoRolling", false)
		return 
	end

	if targetStand ~= "Any" and (rollType == "Arrow" or rollType == "Corpse") then
		local sData = StandData.Stands[targetStand]
		if sData then
			if sData.Rarity == "Evolution" or sData.Rarity == "Unique" or sData.Rarity == "Mythical" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. targetStand .. " cannot be rolled from items!</font>")
				player:SetAttribute("IsAutoRolling", false)
				return
			end
			local reqPool = sData.Pool or "Arrow"
			if reqPool ~= expectedPool then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>You cannot get " .. targetStand .. " from a " .. itemReq .. "!</font>")
				player:SetAttribute("IsAutoRolling", false)
				return
			end
		end
	end

	local newStand = player:GetAttribute("Stand") or "None"
	local newTrait = player:GetAttribute("StandTrait") or "None"

	if player:GetAttribute("StandLocked") then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Stand is locked! Unlock it before Auto-Rolling.</font>")
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	if rollType == "Roka" and newStand == "None" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You don't have a Stand to reroll!</font>")
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	local pBoosts = GetPlayerBoosts(player)
	local sPity = player:GetAttribute("StandPity") or 0
	local tPity = player:GetAttribute("TraitPity") or 0
	local rollsDone = 0
	local hit = false

	while count > 0 do
		count -= 1
		rollsDone += 1

		if rollType == "Arrow" or rollType == "Corpse" then
			local isCorpse = (rollType == "Corpse")
			newStand = StandData.RollStand(pBoosts.Luck, sPity, isCorpse and "Corpse" or "Arrow")
			newTrait = StandData.RollTrait(pBoosts.Luck, tPity)
		elseif rollType == "Roka" then
			newTrait = StandData.RollTrait(pBoosts.Luck, tPity)
		end

		if StandData.Stands[newStand] and StandData.Stands[newStand].Rarity == "Legendary" then sPity = 0 else sPity += 1 end
		if StandData.Traits[newTrait] and (StandData.Traits[newTrait].Rarity == "Mythical" or StandData.Traits[newTrait].Rarity == "Legendary") then tPity = 0 else tPity += 1 end

		local wantStand = targetStand ~= "Any"
		local wantTrait = targetTrait ~= "Any"
		local standMatch = (wantStand and newStand == targetStand)
		local traitMatch = (wantTrait and newTrait == targetTrait)

		if wantStand and wantTrait then
			if standMatch and traitMatch then hit = true; break end
		elseif wantStand then
			if standMatch then hit = true; break end
		elseif wantTrait then
			if traitMatch then hit = true; break end
		else
			hit = true; break
		end

		if rollsDone % 100 == 0 then task.wait() end
	end

	player:SetAttribute(attr, count)
	player:SetAttribute("Stand", newStand)
	player:SetAttribute("StandTrait", newTrait)
	player:SetAttribute("StandPity", sPity)
	player:SetAttribute("TraitPity", tPity)

	if newStand ~= "None" and StandData.Stands[newStand] then
		for statName, rank in pairs(StandData.Stands[newStand].Stats) do player:SetAttribute("Stand_"..statName, rank) end
	end

	local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
	if hit then
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Auto-Roll successful! Used " .. rollsDone .. "x " .. itemReq .. ".\nGot: " .. newStand .. traitTag .. "</font>")
	else
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Ran out of " .. itemReq .. "s! Used " .. rollsDone .. ".\nEnded with: " .. newStand .. traitTag .. "</font>")
	end

	player:SetAttribute("IsAutoRolling", false)
end)

local function RollModifiers(count)
	if count <= 0 then return "None" end
	local available = {}
	for modName, _ in pairs(GameData.UniverseModifiers) do
		if modName ~= "None" then table.insert(available, modName) end
	end
	local rolled = {}
	for i = 1, count do
		if #available == 0 then break end
		local idx = math.random(1, #available)
		table.insert(rolled, available[idx])
		table.remove(available, idx)
	end
	return table.concat(rolled, ",")
end

local function HandleGiftboxDrop(player, targetRarity)
	local pool = {}
	for name, data in pairs(ItemData.Equipment) do 
		if data.Rarity == targetRarity then 
			if not string.find(string.lower(name), "disc") then
				table.insert(pool, name) 
			end
		end 
	end
	for name, data in pairs(ItemData.Consumables) do 
		if data.Rarity == targetRarity then 
			if not string.find(string.lower(name), "disc") then
				table.insert(pool, name) 
			end
		end 
	end

	if #pool > 0 then
		local itemName = pool[math.random(#pool)]
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]

		if player:GetAttribute("AutoSell_" .. targetRarity) then
			local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Yen") then
				leaderstats.Yen.Value += sellVal
			end
			return "You opened the box and found a " .. itemName .. ", but it was Auto-Sold for ¥" .. sellVal .. "!"
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
		local myStand = player:GetAttribute("Stand") or "None"
		local itemConsumed = true

		if ItemData.Equipment[itemName] then
			local equipSlot = ItemData.Equipment[itemName].Slot
			player:SetAttribute("Equipped" .. equipSlot, itemName)
			message = "Equipped " .. itemName .. " as " .. equipSlot .. "!"
			NotificationEvent:FireClient(player, "<font color='#55FF55'>" .. message .. "</font>")
			return
		end

		local isStandItem = (itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" or itemName == "Stand Disc" or itemName == "Requiem Arrow" or itemName == "Dio's Diary" or itemName == "Saint's Left Arm" or itemName == "Saint's Right Eye" or itemName == "Saint's Pelvis" or itemName == "Saint's Heart" or itemName == "Saint's Spine" or itemName == "Strange Arrow" or itemName == "Green Baby" or itemName == "Rokakaka" or (string.find(itemName, "Disc") and itemName ~= "Memory Disc" and itemName ~= "Heavenly Stand Disc"))
		local isStyleItem = (itemName == "Memory Disc" or itemName == "Boxing Manual" or itemName == "Vampire Mask" or itemName == "Hamon Manual" or itemName == "Cyborg Blueprints" or itemName == "Ancient Mask" or itemName == "Steel Ball" or itemName == "Perfect Aja Mask" or itemName == "Golden Spin Scroll")

		if isStandItem and player:GetAttribute("StandLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Stand is locked! Unlock it to use this item.</font>")
			return
		end

		if isStyleItem and player:GetAttribute("StyleLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Fighting Style is locked! Unlock it to use this item.</font>")
			return
		end

		local function EvolveStand(newStand)
			player:SetAttribute("Stand", newStand)
			local stats = StandData.Stands[newStand].Stats
			for statName, rank in pairs(stats) do
				player:SetAttribute("Stand_"..statName, rank)
			end
		end

		if itemName == "Legendary Giftbox" then
			message = HandleGiftboxDrop(player, "Legendary")

		elseif itemName == "Mythical Giftbox" then
			message = HandleGiftboxDrop(player, "Mythical")

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
		elseif itemName == "Stand Storage Slot 2" then
			if player:GetAttribute("HasStandSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStandSlot2", true); message = "Unlocked Stand Storage Slot 2!" end
		elseif itemName == "Stand Storage Slot 3" then
			if player:GetAttribute("HasStandSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStandSlot3", true); message = "Unlocked Stand Storage Slot 3!" end
		elseif itemName == "Style Storage Slot 2" then
			if player:GetAttribute("HasStyleSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot2", true); message = "Unlocked Style Storage Slot 2!" end
		elseif itemName == "Style Storage Slot 3" then
			if player:GetAttribute("HasStyleSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot3", true); message = "Unlocked Style Storage Slot 3!" end
		elseif itemName == "Auto-Roll Pass" then
			if player:GetAttribute("HasAutoRoll") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoRoll", true); message = "Unlocked Auto-Roll!" end
		elseif itemName == "Custom Horse Name" then
			if player:GetAttribute("HasHorseNamePass") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasHorseNamePass", true); message = "Unlocked Custom Horse Names!" end

		elseif itemName == "Stand Arrow" then
			local pBoosts = GetPlayerBoosts(player)
			local currentStandPity = player:GetAttribute("StandPity") or 0
			local currentTraitPity = player:GetAttribute("TraitPity") or 0

			local newStand = StandData.RollStand(pBoosts.Luck, currentStandPity)
			local newTrait = StandData.RollTrait(pBoosts.Luck, currentTraitPity)

			if StandData.Stands[newStand].Rarity == "Legendary" then player:SetAttribute("StandPity", 0)
			else player:SetAttribute("StandPity", currentStandPity + 1) end

			local traitData = StandData.Traits[newTrait]
			if traitData and traitData.Rarity == "Mythical" then player:SetAttribute("TraitPity", 0)
			else player:SetAttribute("TraitPity", currentTraitPity + 1) end

			player:SetAttribute("Stand", newStand)
			player:SetAttribute("StandTrait", newTrait)

			local stats = StandData.Stands[newStand].Stats
			for statName, rank in pairs(stats) do player:SetAttribute("Stand_"..statName, rank) end

			local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
			message = "You were pierced by the arrow! Awakened Stand: " .. newStand .. traitTag .. "!"

		elseif itemName == "Saint's Corpse Part" then
			local pBoosts = GetPlayerBoosts(player)
			local currentStandPity = player:GetAttribute("StandPity") or 0
			local currentTraitPity = player:GetAttribute("TraitPity") or 0

			local newStand = StandData.RollStand(pBoosts.Luck, currentStandPity, "Corpse")
			local newTrait = StandData.RollTrait(pBoosts.Luck, currentTraitPity)

			if StandData.Stands[newStand].Rarity == "Legendary" then player:SetAttribute("StandPity", 0)
			else player:SetAttribute("StandPity", currentStandPity + 1) end

			local traitData = StandData.Traits[newTrait]
			if traitData and traitData.Rarity == "Mythical" then player:SetAttribute("TraitPity", 0)
			else player:SetAttribute("TraitPity", currentTraitPity + 1) end

			player:SetAttribute("Stand", newStand)
			player:SetAttribute("StandTrait", newTrait)

			local stats = StandData.Stands[newStand].Stats
			for statName, rank in pairs(stats) do player:SetAttribute("Stand_"..statName, rank) end

			local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
			message = "The corpse part fuses with you! Awakened Stand: " .. newStand .. traitTag .. "!"	

		elseif itemName == "Memory Disc" then
			if player:GetAttribute("FightingStyle") == "None" then
				message = "You don't have a Fighting Style to forget!"
				itemConsumed = false
			else
				player:SetAttribute("FightingStyle", "None")
				message = "Your memory fades. Fighting Style removed."
			end

		elseif itemName == "Stand Disc" then
			if myStand == "None" then
				message = "You don't have a Stand to extract!"
				itemConsumed = false
			else
				player:SetAttribute("Stand", "None")
				player:SetAttribute("StandTrait", "None")
				local standStatsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
				for _, s in ipairs(standStatsList) do player:SetAttribute("Stand_" .. s, "None") end
				message = "Your Stand and Trait have been extracted!"
			end

		elseif itemName == "Heavenly Stand Disc" then
			if prestige >= 5 then
				local rollCount = math.floor(prestige/5)
				local newMods = RollModifiers(rollCount)
				player:SetAttribute("UniverseModifier", newMods)
				message = "A heavenly glow surrounds you. Your Universe Modifiers have been rerolled!"
			else
				message = "You must be at least Prestige 5 to have Universe Modifiers!"
				itemConsumed = false
			end

		elseif itemName == "Boxing Manual" then
			player:SetAttribute("FightingStyle", "Boxing"); message = "You read the manual. Gained Boxing Style."
		elseif itemName == "Vampire Mask" then
			player:SetAttribute("FightingStyle", "Vampirism"); message = "I REJECT MY HUMANITY! Gained Vampirism Style."
		elseif itemName == "Hamon Manual" then
			player:SetAttribute("FightingStyle", "Hamon"); message = "Your breathing stabilized. Gained Hamon Style."
		elseif itemName == "Cyborg Blueprints" then
			player:SetAttribute("FightingStyle", "Cyborg"); message = "German science is the best! Gained Cyborg Style."
		elseif itemName == "Ancient Mask" then
			player:SetAttribute("FightingStyle", "Pillarman"); message = "Awakened ancient biology! Gained Pillarman Style."
		elseif itemName == "Steel Ball" then
			player:SetAttribute("FightingStyle", "Spin"); message = "You grasped the rotation! Gained Spin Style."
		elseif itemName == "Perfect Aja Mask" then
			if player:GetAttribute("FightingStyle") == "Pillarman" then
				player:SetAttribute("FightingStyle", "Ultimate Lifeform")
				message = "The mask pierces your brain! You have evolved into the Ultimate Lifeform!"
			else
				message = "You must be a Pillarman to survive using this mask!"
				itemConsumed = false
			end
		elseif itemName == "Golden Spin Scroll" then
			if player:GetAttribute("FightingStyle") == "Spin" then
				player:SetAttribute("FightingStyle", "Golden Spin")
				message = "You comprehend the golden ratio! Your Spin has evolved into the Golden Spin!"
			else
				message = "You must master the base Spin style to understand this scroll!"
				itemConsumed = false
			end

		elseif itemName == "Weather Report Disc" then
			player:SetAttribute("Stand", "Weather Report"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Weather Report!"
		elseif itemName == "Heaven's Door Disc" then
			player:SetAttribute("Stand", "Heaven's Door"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Heaven's Door!"
		elseif itemName == "The Hand Disc" then
			player:SetAttribute("Stand", "The Hand"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken The Hand!"
		elseif itemName == "Metallica Disc" then
			player:SetAttribute("Stand", "Metallica"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Metallica!"
		elseif itemName == "The World Disc" then
			player:SetAttribute("Stand", "The World"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken The World!"
		elseif itemName == "Star Platinum Disc" then
			player:SetAttribute("Stand", "Star Platinum"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Star Platinum!"

		elseif itemName == "Requiem Arrow" then
			if prestige >= 5 then
				if myStand == "Gold Experience" then EvolveStand("Gold Experience Requiem"); message = "Your stand evolved into Gold Experience Requiem!"
				elseif myStand == "Silver Chariot" then EvolveStand("Chariot Requiem"); message = "Your stand evolved into Chariot Requiem!"
				elseif myStand == "King Crimson" then EvolveStand("King Crimson Requiem"); message = "Your stand evolved into King Crimson Requiem!"
				elseif (myStand ~= "Chariot Requiem" and myStand ~= "Gold Experience Requiem" and myStand ~= "King Crimson Requiem" and myStand ~= "None") then
					player:SetAttribute("StandTrait", "Requiem"); message = "The arrow accepts you, greedily worming it's way into your stand's body..."
				else	
					message = "The arrow falls through your graps, rejecting you."; itemConsumed = false
				end
			else
				message = "You must be at least Prestige 5 to use this!"; itemConsumed = false
			end

		elseif itemName == "Dio's Diary" then
			if myStand == "Star Platinum" then EvolveStand("Star Platinum: The World"); message = "Your Stand evolved into Star Platinum: The World!"
			elseif myStand == "C-Moon" then EvolveStand("Made in Heaven"); message = "Your Stand evolved into Made in Heaven!"
			else
				local bonusXP = math.floor((3000 * (1 + prestige)))
				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + bonusXP)
				message = "You read the diary. Gained " .. bonusXP .. " XP!"
				if (myStand ~= "Star Platinum: The World" and myStand ~= "Star Platinum: Over Heaven" and myStand ~= "The World" and myStand ~= "The World: Over Heaven" and myStand ~= "None") then
					if (math.random(1,100) <= 5) then
						player:SetAttribute("StandTrait", "Overheaven")
						message = "You begin to understand the writing, you unlock forbidden knowledge... Your stand has evolved into Over Heaven!"
					end
				end
			end

		elseif itemName == "Saint's Left Arm" then
			if myStand == "Tusk Act 1" then EvolveStand("Tusk Act 2"); message = "You fuse with the Left Arm! Your Stand evolved into Tusk Act 2!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Right Eye" then
			if myStand == "Tusk Act 2" then EvolveStand("Tusk Act 3"); message = "You fuse with the Right Eye! Your Stand evolved into Tusk Act 3!"
			elseif myStand == "The World" then EvolveStand("The World: High Voltage"); message = "You fuse with the Right Eye! Your Stand evolved into The World: High Voltage!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Pelvis" then
			if myStand == "Tusk Act 3" then EvolveStand("Tusk Act 4"); message = "You fuse with the Pelvis and master the infinite rotation! Your Stand evolved into Tusk Act 4!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Heart" then
			if myStand == "Dirty Deeds Done Dirt Cheap" then EvolveStand("D4C Love Train"); message = "The holy light of the Heart protects you! Your Stand evolved into D4C Love Train!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Spine" then
			if myStand == "The World" then EvolveStand("The World: Over Heaven"); message = "Your stand has evolved into The World: Over Heaven!"
			elseif myStand == "Star Platinum: The World" then EvolveStand("Star Platinum: Over Heaven"); message = "Your stand has evolved into Star Platinum: Over Heaven!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Strange Arrow" then
			if myStand == "Killer Queen" then EvolveStand("Killer Queen BTD"); message = "Your Stand evolved into Killer Queen BTD!"
			elseif myStand == "Echoes Act 1" then EvolveStand("Echoes Act 2"); message = "Your Stand evolved into Echoes Act 2!"
			elseif myStand == "Echoes Act 2" then EvolveStand("Echoes Act 3"); message = "Your Stand evolved into Echoes Act 3!"
			else
				player:SetAttribute("Stand_Power", "S"); player:SetAttribute("Stand_Power_Val", math.min(statCap, (player:GetAttribute("Stand_Power_Val") or 0) + 30))
				player:SetAttribute("Stand_Potential", "S"); player:SetAttribute("Stand_Potential_Val", math.min(statCap, (player:GetAttribute("Stand_Potential_Val") or 0) + 30))
				message = "Your Stand's Power and Potential evolved to Rank S!"
			end

		elseif itemName == "Green Baby" then
			if myStand == "Whitesnake" then EvolveStand("C-Moon"); message = "Your Stand evolved into C-Moon!"
			else
				player:SetAttribute("Speed", math.min(statCap, (player:GetAttribute("Speed") or 5) + 25))
				player:SetAttribute("Defense", math.min(statCap, (player:GetAttribute("Defense") or 5) + 25))
				message = "You fused with the Green Baby. Massive Speed/Defense boost!"
			end

		elseif itemName == "Rokakaka" then
			if myStand == "None" then
				message = "You don't have a Stand to reroll!"; itemConsumed = false
			else
				local pBoosts = GetPlayerBoosts(player)
				local currentTraitPity = player:GetAttribute("TraitPity") or 0
				local newTrait = StandData.RollTrait(pBoosts.Luck, currentTraitPity)

				player:SetAttribute("StandTrait", newTrait)

				local traitData = StandData.Traits[newTrait]
				if traitData and (traitData.Rarity == "Mythical" or traitData.Rarity == "Legendary") then player:SetAttribute("TraitPity", 0) else player:SetAttribute("TraitPity", currentTraitPity + 1) end

				local traitColor = StandData.Traits[newTrait] and StandData.Traits[newTrait].Color or "#FFFFFF"
				local traitDisplay = newTrait ~= "None" and "<font color='"..traitColor.."'>["..newTrait.."]</font>" or "None"
				message = "You consumed the Rokakaka! Your Stand's trait is now: " .. traitDisplay .. "!"
			end
		else
			itemConsumed = false
		end

		if itemConsumed then
			player:SetAttribute(attrName, itemCount - 1)
			NotificationEvent:FireClient(player, "<font color='#FF55FF'>" .. message .. "</font>")
		end
	end
end)