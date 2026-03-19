-- @ScriptType: ModuleScript
local GameData = {}

GameData.StandRanks = {
	["E"] = 5, ["D"] = 10, ["C"] = 15,
	["B"] = 20, ["A"] = 25, ["S"] = 30,
	["None"] = 0
}

GameData.BaseStats = { Health = 1, Strength = 1, Defense = 1, Speed = 1, Stamina = 1, Willpower = 1 }

GameData.StandStats = { "Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val" }

GameData.StyleBonuses = {
	["Boxing"] = { Stamina = 20, Strength = 10 },
	["Vampirism"] = { Health = 25, Strength = 15 },
	["Hamon"] = { Stamina = 30, Health = 15 },
	["Cyborg"] = { Health = 30, Defense = 20 },
	["Pillarman"] = { Health = 40, Strength = 20 },
	["Ultimate Lifeform"] = { Health = 85, Defense = 55 },
	["Spin"] = { Strength = 45, Speed = 35 },
	["Golden Spin"] = { Strength = 85, Willpower = 55 }, 
	["Man of Steel"] = { Defense = 50, Health = 50 },
}

GameData.StatDescriptions = {
	Health = "Increases your Maximum HP. Essential for surviving heavy hits.",
	Strength = "Increases the base damage of your physical and style-based attacks.",
	Defense = "Reduces the amount of damage you take from all incoming attacks.",
	Speed = "Determines turn order and increases your chance to dodge incoming attacks.",
	Stamina = "Required to perform physical skills and attacks. Regenerates slowly.",
	Willpower = "Increases critical hit chance and the probability of surviving a fatal blow with 1 HP.",
	Stand_Power = "Increases the overall damage dealt by your Stand's skills.",
	Stand_Speed = "Boosts your overall combat speed and dodge chance when using a Stand.",
	Stand_Range = "Increases Accuracy (reduces enemy dodge chance).",
	Stand_Durability = "Provides additional damage reduction and defense in combat.",
	Stand_Precision = "Vastly increases your critical hit chance.",
	Stand_Potential = "Increases your Maximum Stand Energy, allowing for more frequent Stand skills."
}

GameData.UniverseModifiers = {
	["None"] = { Description = "The universe is normal.", Color = "#FFFFFF" },
	["Vampiric Night"] = { Description = "Enemies have 5% Lifesteal, but drop +25% Yen.", Color = "#AA00AA" },
	["Heavy Gravity"] = { Description = "Your Speed is reduced by 25%, but Strength is +25%.", Color = "#8B4513" },
	["Fragile Mortality"] = { Description = "Everyone (Player and Enemies) takes +50% damage.", Color = "#FF0000" },
	["Endless Stamina"] = { Description = "Skills cost 50% less Stamina/Energy, but your Max HP is -25%.", Color = "#00FFFF" },
	["Lethal Precision"] = { Description = "Critical hits deal 2.0x damage instead of 1.5x.", Color = "#FFAA00" },
	["Glass Cannon"] = { Description = "Your Strength is +50%, but your Defense is -25%.", Color = "#FF5555" },
	["Iron Skin"] = { Description = "All damage taken by anyone is reduced by 25%.", Color = "#AAAAAA" },
	["Speed of Light"] = { Description = "Your Speed is +50%, but Stamina/Energy costs are +50%.", Color = "#FFFF55" },
	["Wealthy Foes"] = { Description = "Enemies have +25% HP, but drop +50% Yen.", Color = "#55FF55" },
	["Experience Surge"] = { Description = "Enemies have +25% Strength, but drop +50% XP.", Color = "#55FFFF" },
	["Cursed Wounds"] = { Description = "Poison and Burn effects deal 7% Max HP damage instead of 5%.", Color = "#800080" },
	["Desperate Struggle"] = { Description = "When your HP is below 30%, you deal +50% Damage.", Color = "#FF0055" },
	["Lucky Star"] = { Description = "You gain +1 Luck for all rolls.", Color = "#FFD700" },
	["Unlucky Aura"] = { Description = "You suffer -1 Luck for all rolls.", Color = "#555555" },
	["Minor Fortitude"] = { Description = "Your Max HP is increased by 10%.", Color = "#55FF55" },
	["Minor Lethargy"] = { Description = "Your Max HP is reduced by 10%.", Color = "#FF5555" },
	["Brisk Pace"] = { Description = "Your Speed is increased by 10%.", Color = "#00FFFF" },
	["Sluggish"] = { Description = "Your Speed is reduced by 10%.", Color = "#555555" },
	["Sharpened Weapons"] = { Description = "Your Strength is increased by 10%.", Color = "#FF5555" },
	["Dull Blades"] = { Description = "Your Strength is reduced by 10%.", Color = "#555555" },
	["Hardened Armor"] = { Description = "Your Defense is increased by 10%.", Color = "#AAAAAA" },
	["Brittle Armor"] = { Description = "Your Defense is reduced by 10%.", Color = "#555555" },
	["Determined"] = { Description = "Your Willpower is increased by 10%.", Color = "#FF55FF" },
	["Faltering"] = { Description = "Your Willpower is reduced by 10%.", Color = "#555555" }
}

GameData.HorseTraits = {
	["None"] = "A standard horse with no particular strengths or weaknesses.",
	["Swift"] = "Provides +15% distance gained on all paths.",
	["Sturdy"] = "Reduces stamina cost on Safe and Risky paths.",
	["Enduring"] = "Recover +30% extra stamina when Resting.",
	["Lucky"] = "Increases your chance to avoid hazards and obtain rare items on the Risky path.",
	["Desert Walker"] = "Grants +30% distance while racing in the Arizona Desert.",
	["Mountain Goat"] = "Grants +30% distance while racing in the Rocky Mountains.",
	["City Sprinter"] = "Grants +30% distance while racing in Chicago or Philadelphia."
}

function GameData.GetStatCap(prestige)
	return 100 + ((prestige or 0) * 10)
end

function GameData.CalculateStatCost(currentStat, baseStat, prestige)
	local baseCost = 10
	local growthFactor = 1.05
	local prestigeMultiplier = math.max(0.1, 1 - (prestige * 0.03))
	local statDifference = math.max(0, currentStat - baseStat)
	return math.floor(baseCost * (growthFactor ^ statDifference) * prestigeMultiplier)
end

function GameData.GetMaxInventory(player)
	if not player then return 15 end
	local baseMax = 15
	local gangBoost = player:GetAttribute("GangInvBoost") or 0

	local ls = player:FindFirstChild("leaderstats")
	local elo = ls and ls:FindFirstChild("Elo") and ls.Elo.Value or 1000

	local eloBoost = elo >= 4000 and 5 or 0

	local totalCapacity = baseMax + gangBoost + eloBoost

	if player:GetAttribute("Has2xInventory") then
		totalCapacity = totalCapacity * 2
	end

	return totalCapacity
end

function GameData.GetInventoryCount(player)
	if not player then return 0 end
	local count = 0

	local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemData"))

	local ignoredKeys = {}

	for itemName, data in pairs(ItemData.Consumables) do
		ignoredKeys[itemName:gsub("[^%w]", "") .. "Count"] = true
	end

	for itemName, data in pairs(ItemData.Equipment) do
		if data.Rarity == "Unique" then
			ignoredKeys[itemName:gsub("[^%w]", "") .. "Count"] = true
		end
	end

	local attrs = player:GetAttributes()
	for key, val in pairs(attrs) do
		if type(val) == "number" and val > 0 and string.sub(key, -5) == "Count" then
			if not ignoredKeys[key] then
				count += val
			end
		end
	end
	return count
end

return GameData