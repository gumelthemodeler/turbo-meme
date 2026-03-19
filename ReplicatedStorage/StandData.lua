-- @ScriptType: ModuleScript
local StandData = {}

StandData.Rarities = {
	Common = 50,
	Uncommon = 30,
	Rare = 15,
	Legendary = 5
}

StandData.Traits = {
	["None"] = { Rarity = "None", Color = "#FFFFFF", Desc = "No special traits." },

	["Swift"] = { Rarity = "Common", Color = "#55FFFF", Desc = "+10% Dodge Chance." },
	["Tough"] = { Rarity = "Common", Color = "#888888", Desc = "+10% Max Health." },
	["Fierce"] = { Rarity = "Common", Color = "#FF8888", Desc = "+10% Physical Strength." },
	["Focused"] = { Rarity = "Common", Color = "#88FF88", Desc = "+10% Max Stamina & Energy." },
	["Lucky"] = { Rarity = "Common", Color = "#FFFF55", Desc = "+5% Crit Chance & Dodge Chance." },

	["Armored"] = { Rarity = "Rare", Color = "#AAAAAA", Desc = "Take 15% less damage." },
	["Brutal"] = { Rarity = "Rare", Color = "#FF5555", Desc = "+15% Crit Chance." },
	["Vigorous"] = { Rarity = "Rare", Color = "#55FF55", Desc = "Recover extra Stamina/Energy per turn." },
	["Evasive"] = { Rarity = "Rare", Color = "#55FFFF", Desc = "+20% Dodge Chance." },

	["Indomitable"] = { Rarity = "Legendary", Color = "#55FFFF", Desc = "Take 25% less damage when below 30% HP." },
	["Relentless"] = { Rarity = "Legendary", Color = "#FF0055", Desc = "All base damage is increased by 15%." },
	["Flaming"] = { Rarity = "Legendary", Color = "#FF5500", Desc = "Attacks have a 10% chance to apply Burn for 3 turns." },
	["Toxic"] = { Rarity = "Legendary", Color = "#AA00AA", Desc = "Attacks have a 10% chance to apply Poison for 3 turns." },
	["Electric"] = { Rarity = "Legendary", Color = "#FFFF55", Desc = "Attacks have a 10% chance to apply Stun for 1 turn." },
	["Frozen"] = { Rarity = "Legendary", Color = "#00FFFF", Desc = "Attacks have a 10% chance to apply Freeze for 1 turn." },
	["Serrated"] = { Rarity = "Legendary", Color = "#FF0000", Desc = "Attacks have a 10% chance to apply Bleed for 3 turns." },
	["Disorienting"] = { Rarity = "Legendary", Color = "#FF55FF", Desc = "Attacks have a 10% chance to apply Confusion for 1 turn." },

	["Lethal"] = { Rarity = "Mythical", Color = "#FF0000", Desc = "Critical hits deal 3.0x damage instead of 1.5x." },
	["Vampiric"] = { Rarity = "Mythical", Color = "#AA00AA", Desc = "Heal for 20% of all damage dealt." },
	["Overwhelming"] = { Rarity = "Mythical", Color = "#FFD700", Desc = "Attacks bypass 30% of enemy defense." },
	["Gambler"] = { Rarity = "Mythical", Color = "#FF55FF", Desc = "Attacks have a 10% chance to apply a random status effect for 2 turns." },
	["Gloomy"] = { Rarity = "Mythical", Color = "#888888", Desc = "Attacks have a 10% chance to apply a random debuff for 3 turns." },
	["Cheerful"] = { Rarity = "Mythical", Color = "#FFFF55", Desc = "Attacks have a 10% chance to apply a random buff for 3 turns." },
	["Blessed"] = { Rarity = "Mythical", Color = "#FFFF55", Desc = "+25% Dodge Chance and +25% Crit Chance." },

	["Perseverance"] = { Rarity = "Unique", Color = "#AAAAAA", Desc = "+50% HP & Willpower, Fatal damage now heals you for 25%." },
	["Requiem"] = { Rarity = "Unique", Color = "#F5AA3D", Desc = "All base damage is increase by 50%" },
	["Overheaven"] = { Rarity = "Unique", Color = "#FAE5C7", Desc = "All base damage is increase by 30%" },
}

StandData.Stands = {
	["Hermit Purple"] = { Rarity = "Common", Stats = {Power="D", Speed="C", Range="D", Durability="A", Precision="D", Potential="E"} },
	["Beach Boy"] = { Rarity = "Common", Stats = {Power="C", Speed="B", Range="B", Durability="C", Precision="C", Potential="A"} },
	["Aerosmith"] = { Rarity = "Common", Stats = {Power="B", Speed="B", Range="B", Durability="C", Precision="E", Potential="C"} },
	["Tower of Gray"] = { Rarity = "Common", Stats = {Power="E", Speed="A", Range="A", Durability="C", Precision="E", Potential="E"} },
	["Emperor"] = { Rarity = "Common", Stats = {Power="B", Speed="B", Range="B", Durability="C", Precision="E", Potential="E"} },
	["Harvest"] = { Rarity = "Common", Stats = {Power="E", Speed="B", Range="A", Durability="A", Precision="E", Potential="C"} },
	["Soft Machine"] = { Rarity = "Common", Stats = {Power="A", Speed="C", Range="E", Durability="A", Precision="E", Potential="E"} },
	["Little Feet"] = { Rarity = "Common", Stats = {Power="D", Speed="B", Range="E", Durability="A", Precision="D", Potential="C"} },
	["Goo Goo Dolls"] = { Rarity = "Common", Stats = {Power="D", Speed="C", Range="B", Durability="D", Precision="B", Potential="B"} },
	["Manhattan Transfer"] = { Rarity = "Common", Stats = {Power="E", Speed="E", Range="A", Durability="A", Precision="A", Potential="C"} },
	["Survivor"] = { Rarity = "Common", Stats = {Power="E", Speed="E", Range="E", Durability="C", Precision="E", Potential="E"} },
	["Tohth"] = { Rarity = "Common", Stats = {Power="E", Speed="E", Range="E", Durability="A", Precision="E", Potential="E"} },
	["Six Pistols"] = { Rarity = "Common", Stats = {Power="E", Speed="C", Range="A", Durability="A", Precision="A", Potential="B"} },
	["Marilyn Manson"] = { Rarity = "Common", Stats = {Power="E", Speed="A", Range="A", Durability="A", Precision="A", Potential="C"} },

	["Hierophant Green"] = { Rarity = "Uncommon", Stats = {Power="C", Speed="B", Range="A", Durability="B", Precision="C", Potential="D"} },
	["Magician's Red"] = { Rarity = "Uncommon", Stats = {Power="B", Speed="B", Range="C", Durability="B", Precision="C", Potential="D"} },
	["Echoes Act 1"] = { Rarity = "Uncommon", Stats = {Power="E", Speed="E", Range="A", Durability="C", Precision="D", Potential="A"} },
	["Ebony Devil"] = { Rarity = "Uncommon", Stats = {Power="D", Speed="D", Range="A", Durability="B", Precision="D", Potential="B"} },
	["Lovers"] = { Rarity = "Uncommon", Stats = {Power="E", Speed="D", Range="A", Durability="A", Precision="D", Potential="E"} },
	["Aqua Necklace"] = { Rarity = "Uncommon", Stats = {Power="C", Speed="C", Range="A", Durability="A", Precision="C", Potential="E"} },
	["Enigma"] = { Rarity = "Uncommon", Stats = {Power="E", Speed="E", Range="C", Durability="A", Precision="C", Potential="C"} },
	["Man in the Mirror"] = { Rarity = "Uncommon", Stats = {Power="C", Speed="C", Range="C", Durability="D", Precision="C", Potential="E"} },
	["Jumping Jack Flash"] = { Rarity = "Uncommon", Stats = {Power="B", Speed="C", Range="B", Durability="A", Precision="D", Potential="B"} },
	["Limp Bizkit"] = { Rarity = "Uncommon", Stats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"} },
	["The Fool"] = { Rarity = "Uncommon", Stats = {Power="B", Speed="C", Range="D", Durability="A", Precision="D", Potential="C"} },
	["The Sun"] = { Rarity = "Uncommon", Stats = {Power="B", Speed="E", Range="A", Durability="A", Precision="E", Potential="E"} },
	["Moody Blues"] = { Rarity = "Uncommon", Stats = {Power="C", Speed="C", Range="A", Durability="A", Precision="C", Potential="C"} },

	["Silver Chariot"] = { Rarity = "Rare", Stats = {Power="C", Speed="A", Range="C", Durability="B", Precision="B", Potential="C"} },
	["Sticky Fingers"] = { Rarity = "Rare", Stats = {Power="A", Speed="A", Range="E", Durability="D", Precision="C", Potential="D"} },
	["Purple Haze"] = { Rarity = "Rare", Stats = {Power="A", Speed="B", Range="C", Durability="E", Precision="E", Potential="B"} },
	["Stone Free"] = { Rarity = "Rare", Stats = {Power="A", Speed="B", Range="C", Durability="A", Precision="C", Potential="A"} },
	["Cream"] = { Rarity = "Rare", Stats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="D"} },
	["Death 13"] = { Rarity = "Rare", Stats = {Power="C", Speed="C", Range="E", Durability="B", Precision="D", Potential="B"} },
	["Geb"] = { Rarity = "Rare", Stats = {Power="C", Speed="B", Range="A", Durability="B", Precision="A", Potential="D"} },
	["Horus"] = { Rarity = "Rare", Stats = {Power="B", Speed="B", Range="A", Durability="C", Precision="E", Potential="C"} },
	["Red Hot Chili Pepper"] = { Rarity = "Rare", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="C", Potential="A"} },
	["The Grateful Dead"] = { Rarity = "Rare", Stats = {Power="C", Speed="C", Range="A", Durability="A", Precision="E", Potential="C"} },
	["White Album"] = { Rarity = "Rare", Stats = {Power="A", Speed="C", Range="C", Durability="A", Precision="E", Potential="E"} },
	["Green Day"] = { Rarity = "Rare", Stats = {Power="A", Speed="C", Range="A", Durability="A", Precision="E", Potential="A"} },
	["Planet Waves"] = { Rarity = "Rare", Stats = {Power="A", Speed="B", Range="A", Durability="A", Precision="E", Potential="E"} },
	["Jail House Lock"] = { Rarity = "Rare", Stats = {Power="None", Speed="C", Range="A", Durability="A", Precision="None", Potential="None"} },
	["Anubis"] = { Rarity = "Rare", Stats = {Power="B", Speed="B", Range="E", Durability="A", Precision="E", Potential="C"} },
	["Spice Girl"] = { Rarity = "Rare", Stats = {Power="A", Speed="A", Range="C", Durability="B", Precision="D", Potential="C"} },
	["Diver Down"] = { Rarity = "Rare", Stats = {Power="A", Speed="A", Range="E", Durability="A", Precision="B", Potential="B"} },
	["Kiss"] = { Rarity = "Rare", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="C", Potential="A"} },
	["Bad Company"] = { Rarity = "Rare", Stats = {Power="B", Speed="B", Range="C", Durability="B", Precision="C", Potential="C"} },

	["Killer Queen"] = { Rarity = "Legendary", Stats = {Power="A", Speed="B", Range="D", Durability="B", Precision="B", Potential="A"} },
	["King Crimson"] = { Rarity = "Legendary", Stats = {Power="A", Speed="A", Range="E", Durability="E", Precision="B", Potential="A"} },
	["Crazy Diamond"] = { Rarity = "Legendary", Stats = {Power="A", Speed="A", Range="D", Durability="B", Precision="B", Potential="C"} },
	["Gold Experience"] = { Rarity = "Legendary", Stats = {Power="C", Speed="A", Range="C", Durability="D", Precision="C", Potential="A"} },
	["Whitesnake"] = { Rarity = "Legendary", Stats = {Power="B", Speed="D", Range="C", Durability="A", Precision="None", Potential="None"} },

	["Star Platinum: The World"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="C"} },
	["Killer Queen BTD"] = { Rarity = "Evolution", Stats = {Power="A", Speed="B", Range="D", Durability="B", Precision="B", Potential="A"} },
	["C-Moon"] = { Rarity = "Evolution", Stats = {Power="None", Speed="B", Range="B", Durability="None", Precision="C", Potential="None"} },
	["Made in Heaven"] = { Rarity = "Evolution", Stats = {Power="B", Speed="A", Range="C", Durability="A", Precision="C", Potential="A"} },
	["Echoes Act 2"] = { Rarity = "Evolution", Stats = {Power="C", Speed="C", Range="B", Durability="C", Precision="C", Potential="C"} },
	["Echoes Act 3"] = { Rarity = "Evolution", Stats = {Power="B", Speed="B", Range="C", Durability="B", Precision="C", Potential="D"} },
	["Gold Experience Requiem"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },
	["Chariot Requiem"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },
	["The World: High Voltage"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="B", Potential="B"} },
	["Star Platinum: Over Heaven"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },
	["The World: Over Heaven"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },
	["King Crimson Requiem"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },

	["Star Platinum"] = { Rarity = "Mythical", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="A"} },
	["The World"] = { Rarity = "Mythical", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="B", Potential="B"} },
	["Weather Report"] = { Rarity = "Mythical", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="E", Potential="A"} },
	["Heaven's Door"] = { Rarity = "Mythical", Stats = {Power="D", Speed="B", Range="B", Durability="D", Precision="C", Potential="A"} },
	["Metallica"] = { Rarity = "Mythical", Stats = {Power="C", Speed="C", Range="C", Durability="A", Precision="C", Potential="C"} },
	["The Hand"] = { Rarity = "Mythical", Stats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="C"} },

	["Steel Platinum"] = { Rarity = "Unique", Stats = {Power="A", Speed="C", Range="D", Durability="A", Precision="A", Potential="A"} },

	["TATOO YOU!"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="None", Speed="E", Range="C", Durability="B", Precision="E", Potential="E"} },
	["Tubular Bells"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="D", Speed="D", Range="D", Durability="A", Precision="E", Potential="B"} },
	["Hey Ya!"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="E", Speed="E", Range="E", Durability="B", Precision="E", Potential="E"} },
	["Tomb of the Boom"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="C", Speed="C", Range="C", Durability="B", Precision="C", Potential="C"} },
	["Wired"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="D", Speed="B", Range="B", Durability="B", Precision="D", Potential="D"} },
	["Oh! Lonesome Me"] = { Rarity = "Common", Pool = "Corpse", Stats = {Power="E", Speed="C", Range="C", Durability="B", Precision="C", Potential="D"} },

	["Cream Starter"] = { Rarity = "Uncommon", Pool = "Corpse", Stats = {Power="D", Speed="C", Range="C", Durability="A", Precision="E", Potential="B"} },
	["In a Silent Way"] = { Rarity = "Uncommon", Pool = "Corpse", Stats = {Power="C", Speed="C", Range="D", Durability="A", Precision="D", Potential="B"} },
	["Boku no Rhythm wo Kiitekure"] = { Rarity = "Uncommon", Pool = "Corpse", Stats = {Power="B", Speed="C", Range="C", Durability="B", Precision="E", Potential="C"} },
	["Chocolate Disco"] = { Rarity = "Uncommon", Pool = "Corpse", Stats = {Power="None", Speed="C", Range="C", Durability="B", Precision="A", Potential="D"} },

	["20th Century Boy"] = { Rarity = "Rare", Pool = "Corpse", Stats = {Power="None", Speed="C", Range="None", Durability="A", Precision="D", Potential="C"} },
	["Catch the Rainbow"] = { Rarity = "Rare", Pool = "Corpse", Stats = {Power="C", Speed="C", Range="B", Durability="B", Precision="B", Potential="D"} },
	["Civil War"] = { Rarity = "Rare", Pool = "Corpse", Stats = {Power="None", Speed="C", Range="C", Durability="B", Precision="C", Potential="None"} },
	["Ticket to Ride"] = { Rarity = "Rare", Pool = "Corpse", Stats = {Power="E", Speed="E", Range="E", Durability="C", Precision="E", Potential="C"} },
	["Sugar Mountain"] = { Rarity = "Rare", Pool = "Corpse", Stats = {Power="E", Speed="E", Range="E", Durability="A", Precision="E", Potential="E"} },

	["Mandom"] = { Rarity = "Legendary", Pool = "Corpse", Stats = {Power="None", Speed="A", Range="None", Durability="E", Precision="None", Potential="C"} },
	["Dirty Deeds Done Dirt Cheap"] = { Rarity = "Legendary", Pool = "Corpse", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="A"} },
	["Scary Monsters"] = { Rarity = "Legendary", Pool = "Corpse", Stats = {Power="B", Speed="B", Range="B", Durability="A", Precision="C", Potential="B"} },
	["Tusk Act 1"] = { Rarity = "Legendary", Pool = "Corpse", Stats = {Power="E", Speed="E", Range="D", Durability="B", Precision="E", Potential="A"} },

	["Tusk Act 2"] = { Rarity = "Evolution", Stats = {Power="D", Speed="D", Range="B", Durability="C", Precision="C", Potential="A"} },
	["Tusk Act 3"] = { Rarity = "Evolution", Stats = {Power="D", Speed="D", Range="B", Durability="D", Precision="C", Potential="A"} },
	["Tusk Act 4"] = { Rarity = "Evolution", Stats = {Power="A", Speed="B", Range="A", Durability="A", Precision="B", Potential="E"} },
	["D4C Love Train"] = { Rarity = "Evolution", Stats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="C"} },

	["Wonder of U"] = { Rarity = "Unique", Stats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"} },
}

function StandData.RollStand(luckBoost, pityCount, targetPool)
	luckBoost = luckBoost or 0
	pityCount = pityCount or 0
	targetPool = targetPool or "Arrow"

	local isGuaranteed = (pityCount >= 25)
	local rng = math.max(1, math.random(1, 100) - luckBoost)

	local selectedRarity = "Common"

	if rng <= 5 or (isGuaranteed and math.random(1,2) == 1) then selectedRarity = "Legendary"
	elseif rng <= 20 or isGuaranteed then selectedRarity = "Rare"
	elseif rng <= 50 then selectedRarity = "Uncommon"
	end

	local pool = {}
	for name, data in pairs(StandData.Stands) do
		local standPool = data.Pool or "Arrow"
		if data.Rarity == selectedRarity and standPool == targetPool then
			table.insert(pool, name)
		end
	end

	if #pool == 0 then
		for name, data in pairs(StandData.Stands) do
			local standPool = data.Pool or "Arrow"
			if data.Rarity == "Common" and standPool == targetPool then
				table.insert(pool, name)
			end
		end
	end

	return pool[math.random(1, #pool)]
end

function StandData.RollTrait(luckBoost, pityCount)
	luckBoost = luckBoost or 0
	pityCount = pityCount or 0

	local isGuaranteed = (pityCount >= 5)
	local rng = math.max(1, math.random(1, 100) - luckBoost)

	local selectedRarity = "None"

	if rng <= 1 or (isGuaranteed and math.random(1,3) == 1) then selectedRarity = "Mythical"
	elseif rng <= 6 or (isGuaranteed and math.random(1,2) == 1) then selectedRarity = "Legendary"
	elseif rng <= 16 or isGuaranteed then selectedRarity = "Rare"
	elseif rng <= 35 then selectedRarity = "Common"
	end

	if selectedRarity == "None" then return "None" end

	local pool = {}
	for name, data in pairs(StandData.Traits) do
		if data.Rarity == selectedRarity then
			table.insert(pool, name)
		end
	end

	return pool[math.random(1, #pool)]
end

return StandData