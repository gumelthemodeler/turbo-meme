-- @ScriptType: ModuleScript
local ItemData = {}

ItemData.Consumables = {
	["Standard Titan Serum"] = { 
		Description = "Inject this to inherit a random Titan shifting power.", 
		Rarity = "Rare", Cost = 5000, SellPrice = 2500 
	},
	["Founder's Memory Wipe"] = { 
		Description = "Erases your current Titan power and combat tactics, letting you start fresh.", 
		Rarity = "Uncommon", Cost = 2000, SellPrice = 1000 
	},
	["Spinal Fluid Syringe"] = { 
		Description = "A potent dose of royal spinal fluid. Awakens the true potential of your Titan.", 
		Rarity = "Legendary", Cost = 25000, SellPrice = 12500 
	},
	["Ymir's Clay Fragment"] = { 
		Description = "A piece of the original coordinate. Grants immense universal power.", 
		Rarity = "Mythical", Cost = 100000, SellPrice = 50000 
	},
	["Scout Training Manual"] = { 
		Description = "Learn the basics of ODM maneuverability and blade combat.", 
		Rarity = "Common", Cost = 500, SellPrice = 250 
	},
	["Marleyan Combat Manual"] = { 
		Description = "Learn advanced military rifle and artillery tactics.", 
		Rarity = "Uncommon", Cost = 1000, SellPrice = 500 
	},
	["Ackerman Awakening Pill"] = {
		Description = "Triggers dormant genetic modification, enhancing combat instincts.",
		Rarity = "Legendary", Cost = 30000, SellPrice = 15000
	},
	["Clan Blood Vial"] = { 
		Description = "A preserved vial of blood. Consume it to awaken a dormant lineage.", 
		Rarity = "Rare", Cost = 10000, SellPrice = 5000 
	}
}

ItemData.Equipment = {
	["Cadet Training Blade"] = { 
		Slot = "Weapon", Bonus = { Strength = 5 }, 
		Rarity = "Common", Cost = 300, SellPrice = 150 
	},
	["Ultrahard Steel Blades"] = { 
		Slot = "Weapon", Bonus = { Strength = 25, Speed = 10 }, 
		Rarity = "Rare", Cost = 4000, SellPrice = 2000 
	},
	["Anti-Personnel Pistols"] = { 
		Slot = "Weapon", Bonus = { Precision = 30, Speed = 15 }, 
		Rarity = "Rare", Cost = 5000, SellPrice = 2500 
	},
	["Thunder Spear"] = { 
		Slot = "Weapon", Bonus = { Strength = 50, Defense = -10 }, 
		Rarity = "Legendary", Cost = 15000, SellPrice = 7500 
	},
	["Scout Regiment Cloak"] = { 
		Slot = "Accessory", Bonus = { Defense = 10, Willpower = 15 }, 
		Rarity = "Uncommon", Cost = 1500, SellPrice = 750 
	},
	["Commander's Bolo Tie"] = { 
		Slot = "Accessory", Bonus = { Willpower = 30, Health = 20 }, 
		Rarity = "Legendary", Cost = 20000, SellPrice = 10000 
	},
	["Advanced ODM Gear"] = { 
		Slot = "Accessory", Bonus = { Speed = 35, Stamina = 25 }, 
		Rarity = "Legendary", Cost = 25000, SellPrice = 12500 
	},
	["Marleyan Armband"] = { 
		Slot = "Accessory", Bonus = { Defense = 25, Health = 25 }, 
		Rarity = "Rare", Cost = 8000, SellPrice = 4000 
	}
}

return ItemData