-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ItemData = {}

ItemData.Equipment = {
	-- // WEAPONS (Determines Combat Style) //
	["Training Dummy Sword"] = { Type = "Weapon", Style = "None", Rarity = "Common", Cost = 250, Bonus = { Strength = 1 }, Desc = "A blunt wooden sword. Practically useless." },
	["Cadet Training Blade"] = { Type = "Weapon", Style = "None", Rarity = "Common", Cost = 500, Bonus = { Strength = 2, Speed = 2 }, Desc = "Standard issue cadet blade." },

	["Garrison Standard Blades"] = { Type = "Weapon", Style = "Ultrahard Steel Blades", Rarity = "Uncommon", Cost = 1200, Bonus = { Strength = 6, Speed = 4 }, Desc = "Standard blades used by the Garrison Regiment." },
	["Marleyan Rifle"] = { Type = "Weapon", Style = "Anti-Personnel", Rarity = "Uncommon", Cost = 1500, Bonus = { Strength = 25, Defense = 5 }, Desc = "Standard Marleyan military rifle." },

	["Ultrahard Steel Blades"] = { Type = "Weapon", Style = "Ultrahard Steel Blades", Rarity = "Rare", Cost = 2500, Bonus = { Strength = 15, Speed = 10 }, Desc = "The staple weapon of the Scout Regiment." },
	["Anti-Personnel Pistols"] = { Type = "Weapon", Style = "Anti-Personnel", Rarity = "Rare", Cost = 3000, Bonus = { Speed = 20, Strength = 10 }, Desc = "Designed to kill humans, not titans." },
	["Prototype Thunder Spear"] = { Type = "Weapon", Style = "Thunder Spears", Rarity = "Rare", Cost = 3500, Bonus = { Strength = 20, Speed = -2 }, Desc = "An early, unstable version of the Thunder Spear." },

	["Veteran Scout Blades"] = { Type = "Weapon", Style = "Ultrahard Steel Blades", Rarity = "Epic", Cost = 7500, Bonus = { Strength = 25, Speed = 15, Resolve = 10 }, Desc = "Perfectly honed blades used by surviving veterans." },
	["Thunder Spear"] = { Type = "Weapon", Style = "Thunder Spears", Rarity = "Epic", Cost = 8000, Bonus = { Strength = 35, Speed = -5 }, Desc = "High-explosive anti-armor weaponry." },

	["Iceburst Steel Blades"] = { Type = "Weapon", Style = "Ultrahard Steel Blades", Rarity = "Legendary", Cost = 30000, Bonus = { Strength = 50, Speed = 35, Gas = 20 }, Desc = "Forged from rare Iceburst stone. Never dulls." },
	["Titan-Killer Artillery"] = { Type = "Weapon", Style = "Anti-Personnel", Rarity = "Legendary", Cost = 35000, Bonus = { Strength = 65, Defense = 10, Speed = -10 }, Desc = "A portable anti-titan cannon. Devastating power." },
	["Kenny's Custom Pistols"] = { Type = "Weapon", Style = "Anti-Personnel", Rarity = "Legendary", Cost = 45000, Bonus = { Speed = 50, Strength = 40 }, Desc = "The legendary weapons of Kenny the Ripper." },

	-- // ACCESSORIES (Passive Stat Boosts) //
	["Worn Trainee Badge"] = { Type = "Accessory", Rarity = "Common", Cost = 300, Bonus = { Resolve = 2, Health = 2 }, Desc = "A badge worn by new recruits." },
	["Scout Training Manual"] = { Type = "Accessory", Rarity = "Common", Cost = 500, Bonus = { Resolve = 5 }, Desc = "Basic training guidelines." },

	["Garrison Hip Flask"] = { Type = "Accessory", Rarity = "Uncommon", Cost = 1200, Bonus = { Health = 10, Resolve = 5 }, Desc = "Liquid courage for the wall guards." },
	["Marleyan Armband"] = { Type = "Accessory", Rarity = "Uncommon", Cost = 1500, Bonus = { Defense = 5, Strength = 5 }, Desc = "An armband worn by Marleyan forces." },

	["Scout Regiment Cloak"] = { Type = "Accessory", Rarity = "Rare", Cost = 2500, Bonus = { Defense = 10, Resolve = 15 }, Desc = "The Wings of Freedom." },
	["Marleyan Combat Manual"] = { Type = "Accessory", Rarity = "Rare", Cost = 3000, Bonus = { Strength = 15, Resolve = 10 }, Desc = "Advanced military tactics." },

	["Commander's Bolo Tie"] = { Type = "Accessory", Rarity = "Epic", Cost = 8000, Bonus = { Resolve = 30, Defense = 15 }, Desc = "Worn by the commander of the Scouts." },
	["Hardened Titan Crystal"] = { Type = "Accessory", Rarity = "Epic", Cost = 12000, Bonus = { Defense = 35, Health = 20 }, Desc = "A chunk of dense Titan hardening." },
	["Hange's Goggles"] = { Type = "Accessory", Rarity = "Epic", Cost = 15000, Bonus = { Speed = 25, Gas = 20 }, Desc = "Protects the eyes during high-speed maneuvers." },

	["Mikasa's Scarf"] = { Type = "Accessory", Rarity = "Legendary", Cost = 40000, Bonus = { Strength = 30, Speed = 30, Resolve = 25 }, Desc = "A warm, red scarf. Fills you with a burning resolve." },
	["Erwin's Pendant"] = { Type = "Accessory", Rarity = "Legendary", Cost = 45000, Bonus = { Resolve = 60, Defense = 30, Health = 30 }, Desc = "A symbol of absolute, unwavering leadership." },

	["Coordinate's Sand"] = { Type = "Accessory", Rarity = "Mythical", Cost = 250000, Bonus = { Strength = 50, Defense = 50, Speed = 50, Resolve = 50, Gas = 50, Health = 50 }, Desc = "A handful of sand from the Paths. Godlike power." }
}

ItemData.Consumables = {
	["Standard Titan Serum"] = { Rarity = "Rare", Cost = 5000, Desc = "Used in the Inherit tab to roll for a Titan." },
	["Spinal Fluid Syringe"] = { Rarity = "Legendary", Cost = 25000, Desc = "Premium item. Guarantees a Legendary or Mythical Titan." },
	["Clan Blood Vial"] = { Rarity = "Epic", Cost = 10000, Desc = "Used to roll for Clan Lineages." },

	["Ackerman Awakening Pill"] = { Rarity = "Mythical", Cost = 150000, Action = "AwakenClan", Desc = "Awakens the true power of the Ackerman bloodline." },
	["Ymir's Clay Fragment"] = { Rarity = "Mythical", Cost = 150000, Action = "AwakenTitan", Desc = "Allows the Attack Titan to reach the Coordinate." }
}

ItemData.Gamepasses = {
	{ ID = 1749846514, Name = "Auto Train", Desc = "Passively generates Training XP in the background.", Key = "AutoTrain" },
	{ ID = 1748534838, Name = "2x XP & Funds", Desc = "Doubles all XP and Dews gained from combat and training.", Key = "DoubleXP" },
	{ ID = 1748263337, Name = "Titan Vault Expansion", Desc = "Unlocks slots 4, 5, and 6 in the Titan vault.", Key = "TitanVault" },
	{ ID = 1760797262, Name = "Clan Vault Expansion", Desc = "Unlocks slots 4, 5, and 6 in the Clan vault.", Key = "ClanVault" },
	{ ID = 1747847881, Name = "VIP Pass", Desc = "Exclusive Golden Chat Tag, 1 Free Daily Shop Reroll, and +25% Auto-Train Synergy!", Key = "VIP" }
}

ItemData.Products = {
	{ ID = 3557925572, Name = "Shop Reroll", Desc = "Instantly restocks the Military Supply with new items.", IsReroll = true },
	{ ID = 3557909080, Name = "5,000 Dews", Desc = "A small injection of military funds.", Reward = "Dews", Amount = 5000 },
	{ ID = 3557908989, Name = "15,000 Dews", Desc = "A healthy supply of military funds.", Reward = "Dews", Amount = 15000 },
	{ ID = 3557908863, Name = "50,000 Dews", Desc = "A massive vault of military funds.", Reward = "Dews", Amount = 50000 },
	{ ID = 3557909565, Name = "1x Titan Serum", Desc = "Grants one Standard Titan Serum.", Reward = "Item", ItemName = "Standard Titan Serum", Amount = 1 },
	{ ID = 3557909698, Name = "5x Titan Serums", Desc = "Grants five Standard Titan Serums.", Reward = "Item", ItemName = "Standard Titan Serum", Amount = 5 },
	{ ID = 3557938597, Name = "1x Clan Vial", Desc = "Grants one Clan Blood Vial.", Reward = "Item", ItemName = "Clan Blood Vial", Amount = 1 },
	{ ID = 3557938636, Name = "5x Clan Vials", Desc = "Grants five Clan Blood Vials.", Reward = "Item", ItemName = "Clan Blood Vial", Amount = 5 }
}

return ItemData