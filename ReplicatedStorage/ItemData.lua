-- @ScriptType: ModuleScript
local ItemData = {}

ItemData.Equipment = {
	["Brass Knuckles"] = { Slot = "Weapon", Bonus = { Strength = 5, Stamina = 5 }, Rarity = "Common", Cost = 100 },
	["Wooden Bat"] = { Slot = "Weapon", Bonus = { Strength = 8, Speed = -2 }, Rarity = "Common", Cost = 150 },
	["Steel Pipe"] = { Slot = "Weapon", Bonus = { Strength = 12, Defense = 2 }, Rarity = "Common", Cost = 200 },
	["Combat Knife"] = { Slot = "Weapon", Bonus = { Strength = 10, Speed = 5 }, Rarity = "Uncommon", Cost = 1500 },
	["Hamon Clackers"] = { Slot = "Weapon", Bonus = { Strength = 8, Stamina = 10, Speed = 5 }, Rarity = "Uncommon", Cost = 2000 },
	["Heavy Revolver"] = { Slot = "Weapon", Bonus = { Strength = 15, Stand_Precision = 10 }, Rarity = "Uncommon", Cost = 3500 },
	["Luck Sword"] = { Slot = "Weapon", Bonus = { Strength = 15, Speed = 10 }, Rarity = "Rare", Cost = 15000 },
	["Tommy Gun"] = { Slot = "Weapon", Bonus = { Strength = 20, Speed = 15 }, Rarity = "Rare", Cost = 25000 },
	["Road Roller"] = { Slot = "Weapon", Bonus = { Strength = 80, Defense = 20, Speed = -10 }, Rarity = "Legendary", Cost = 120000 },

	["Dio's Throwing Knives"] = { Slot = "Weapon", Bonus = { Strength = 15, Stand_Speed = 20 }, Rarity = "Uncommon", Cost = 4000 },
	["Jolyne's String"] = { Slot = "Weapon", Bonus = { Stand_Range = 25, Stand_Speed = 15 }, Rarity = "Rare", Cost = 28000 },
	["Mista's Pistol"] = { Slot = "Weapon", Bonus = { Stand_Precision = 35, Stand_Speed = 15 }, Rarity = "Rare", Cost = 28000 },
	["Anubis Sword"] = { Slot = "Weapon", Bonus = { Stand_Power = 30, Stand_Speed = 20 }, Rarity = "Rare", Cost = 30000 },
	["Emperor Gun"] = { Slot = "Weapon", Bonus = { Stand_Precision = 40, Stand_Range = 20 }, Rarity = "Rare", Cost = 30000 },
	["Bite the Dust Detonator"] = { Slot = "Weapon", Bonus = { Stand_Power = 60, Defense = 10 }, Rarity = "Legendary", Cost = 100000 },

	["Tinted Sunglasses"] = { Slot = "Accessory", Bonus = { Willpower = 10, Defense = 2 }, Rarity = "Common", Cost = 100 },
	["Heart Memento"] = { Slot = "Accessory", Bonus = { Health = 8, Defense = 10 }, Rarity = "Common", Cost = 100 },
	["Leather Jacket"] = { Slot = "Accessory", Bonus = { Defense = 8, Health = 5 }, Rarity = "Common", Cost = 150 },
	["Breathing Mask"] = { Slot = "Accessory", Bonus = { Health = 5, Defense = 12, Stamina = 15 }, Rarity = "Common", Cost = 150 },
	["Running Shoes"] = { Slot = "Accessory", Bonus = { Speed = 10, Stamina = 15 }, Rarity = "Common", Cost = 200 },
	["Iggy's Coffee Gum"] = { Slot = "Accessory", Bonus = { Stamina = 25, Speed = 10 }, Rarity = "Uncommon", Cost = 1500 },
	["Aja Stone Amulet"] = { Slot = "Accessory", Bonus = { Health = 2, Defense = 5 }, Rarity = "Uncommon", Cost = 1800 },
	["Iron Ring"] = { Slot = "Accessory", Bonus = { Defense = 12, Strength = 5 }, Rarity = "Uncommon", Cost = 2000 },
	["Zeppeli's Scarf"] = { Slot = "Accessory", Bonus = { Stamina = 25, Health = 5 }, Rarity = "Uncommon", Cost = 2500 },
	["Vampire Cape"] = { Slot = "Accessory", Bonus = { Strength = 40, Health = 20, Speed = 20 }, Rarity = "Rare", Cost = 35000 },
	["Red Stone of Aja"] = { Slot = "Accessory", Bonus = { Health = 10, Stamina = 20, Strength = 15 }, Rarity = "Legendary", Cost = 125000 },

	["Kakyoin's Sunglasses"] = { Slot = "Accessory", Bonus = { Stand_Precision = 15, Defense = 8 }, Rarity = "Uncommon", Cost = 2500 },
	["Polnareff's Earrings"] = { Slot = "Accessory", Bonus = { Stand_Speed = 15, Defense = 5 }, Rarity = "Uncommon", Cost = 3000 },
	["Arrow Shard"] = { Slot = "Accessory", Bonus = { Stand_Potential = 15, Stand_Power = 10 }, Rarity = "Uncommon", Cost = 3500 },
	["Rohan's Headband"] = { Slot = "Accessory", Bonus = { Stand_Precision = 20, Stand_Potential = 15 }, Rarity = "Rare", Cost = 28000 },
	["Jotaro's Hat"] = { Slot = "Accessory", Bonus = { Stand_Durability = 20, Stand_Power = 15 }, Rarity = "Rare", Cost = 30000 },
	["Kira's Tie"] = { Slot = "Accessory", Bonus = { Stand_Speed = 30, Stand_Power = 15 }, Rarity = "Rare", Cost = 32000 },
	["Josuke's Peace Badge"] = { Slot = "Accessory", Bonus = { Stand_Durability = 25, Health = 15 }, Rarity = "Rare", Cost = 32000 },
	["Giorno's Ladybug Brooch"] = { Slot = "Accessory", Bonus = { Stand_Potential = 30, Health = 20 }, Rarity = "Rare", Cost = 35000 },
	["Pucci's Disc"] = { Slot = "Accessory", Bonus = { Stand_Speed = 50, Stand_Potential = 40 }, Rarity = "Legendary", Cost = 150000 },

	["Luck and Pluck"] = { Slot = "Weapon", Bonus = { Strength = 35, Willpower = 40, Health = 25 }, Rarity = "Mythical", Cost = 500000 },
	["Kars' Arm Blade"] = { Slot = "Weapon", Bonus = { Strength = 45, Speed = 45, Stand_Range = 15 }, Rarity = "Mythical", Cost = 550000 },
	["DIO's Road Sign"] = { Slot = "Weapon", Bonus = { Strength = 100, Defense = 30, Stand_Power = 20 }, Rarity = "Mythical", Cost = 750000 },
	["Stray Cat"] = { Slot = "Weapon", Bonus = { Stand_Speed = 80, Speed = 40 }, Rarity = "Mythical", Cost = 800000 },
	["Doppio's Phone"] = { Slot = "Weapon", Bonus = { Stand_Precision = 100, Stand_Potential = 50 }, Rarity = "Mythical", Cost = 900000 },
	["DIO's Bone"] = { Slot = "Weapon", Bonus = { Stand_Potential = 150, Willpower = 100 }, Rarity = "Mythical", Cost = 1250000 },
	["Valentine's Revolver"] = { Slot = "Weapon", Bonus = { Stand_Precision = 150, Stand_Power = 100, Speed = 80 }, Rarity = "Mythical", Cost = 1500000 },

	["Dio's Head Jar"] = { Slot = "Accessory", Bonus = { Defense = 60, Willpower = 40 }, Rarity = "Mythical", Cost = 500000 },
	["Kars' Horn"] = { Slot = "Accessory", Bonus = { Stand_Range = 60, Stand_Precision = 40, Speed = 20 }, Rarity = "Mythical", Cost = 550000 },
	["DIO's Headband"] = { Slot = "Accessory", Bonus = { Stand_Power = 60, Strength = 40, Willpower = 20 }, Rarity = "Mythical", Cost = 750000 },
	["Kira's Wristwatch"] = { Slot = "Accessory", Bonus = { Stand_Durability = 50, Defense = 50, Willpower = 40 }, Rarity = "Mythical", Cost = 800000 },
	["Passione Badge"] = { Slot = "Accessory", Bonus = { Stand_Power = 50, Stand_Potential = 50, Health = 40 }, Rarity = "Mythical", Cost = 900000 },
	["Priest's Rosary"] = { Slot = "Accessory", Bonus = { Stand_Durability = 100, Willpower = 50, Defense = 30 }, Rarity = "Mythical", Cost = 1250000 },
	["The First Napkin"] = { Slot = "Accessory", Bonus = { Stand_Power = 100, Stand_Durability = 100, Defense = 80 }, Rarity = "Mythical", Cost = 1500000 },

	["Steel Pipe (x400)"] = { Slot = "Weapon", Bonus = { Strength = -9999 }, Rarity = "Unique", Cost = 1 },
	["Trusty Steel Pipe"] = { Slot = "Weapon", Bonus = { Strength = 99 }, Rarity = "Unique", Cost = 1 },
}

ItemData.Consumables = {
	["Boxing Manual"] = { Description = "Learn the fundamentals. Grants the Boxing style.", Rarity = "Common", Cost = 250 },
	["Memory Disc"] = { Description = "Wipes your memory. Removes your current Fighting Style.", Rarity = "Common", Cost = 5000 },
	["Hamon Manual"] = { Description = "Master your breathing. Grants the Hamon style.", Rarity = "Uncommon", Cost = 4000 },
	["Cyborg Blueprints"] = { Description = "German science is the best! Grants the Cyborg style.", Rarity = "Uncommon", Cost = 5000 },
	["Vampire Mask"] = { Description = "I REJECT MY HUMANITY! Grants the Vampirism style.", Rarity = "Rare", Cost = 25000 },
	["Stand Arrow"] = { Description = "Pierce yourself to awaken a random Stand.", Rarity = "Uncommon", Cost = 35000 },
	["Stand Disc"] = { Description = "Wipes your soul. Removes your current Stand and Trait.", Rarity = "Uncommon", Cost = 15000 },
	["Dio's Diary"] = { Description = "Read the path to heaven. Grants massive XP or Evolves certain Stands.", Rarity = "Legendary", Cost = 80000 },
	["Ancient Mask"] = { Description = "Awaken ancient biology. Grants the Pillarman style.", Rarity = "Legendary", Cost = 100000 },
	["Green Baby"] = { Description = "Fuse with the Green Baby. Evolves Whitesnake or gives massive stats.", Rarity = "Legendary", Cost = 120000 },
	["Strange Arrow"] = { Description = "A mysterious arrow. Evolves your Stand's potential beyond limits!", Rarity = "Legendary", Cost = 150000 },

	["Saint's Left Arm"] = { Description = "A mummified left arm. Evolves Tusk Act 1 into Act 2.", Rarity = "Legendary", Cost = 150000 },
	["Saint's Right Eye"] = { Description = "A mummified right eye. Evolves Tusk Act 2 into Act 3.", Rarity = "Legendary", Cost = 250000 },

	["Weather Report Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},
	["Heaven's Door Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},
	["The Hand Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},
	["Metallica Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},
	["The World Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},
	["Star Platinum Disc"] = { Description = "This disc hums with a menacing power.", Rarity = "Mythical", Cost = 300000},

	["Rokakaka"] = { Description = "An equivalent exchange fruit. Rerolls your Stand's trait.", Rarity = "Mythical", Cost = 300000 },
	["Heavenly Stand Disc"] = { Description = "Call upon the powers of Made in Heaven to reset the universe and its modifiers.", Rarity = "Mythical", Cost = 350000},
	["Steel Ball"] = { Description = "A perfect sphere. Unlocks the Spin fighting style.", Rarity = "Mythical", Cost = 400000 },
	["Perfect Aja Mask"] = { Description = "A stone mask with the Red Stone embedded. Evolves Pillarman into the Ultimate Lifeform.", Rarity = "Mythical", Cost = 450000 },
	["Golden Spin Scroll"] = { Description = "The secret of infinite rotation. Evolves the Spin style into Golden Spin.", Rarity = "Mythical", Cost = 450000 },

	["Saint's Pelvis"] = { Description = "A mummified pelvis. Evolves Tusk Act 3 into Act 4.", Rarity = "Mythical", Cost = 500000 },
	["Saint's Heart"] = { Description = "A mummified heart. Evolves Dirty Deeds Done Dirt Cheap into Love Train.", Rarity = "Mythical", Cost = 500000 },
	["Saint's Spine"] = { Description = "A mummified spine. Evolves The World and Star Platinum into Over Heaven!", Rarity = "Mythical", Cost = 500000 },

	["Saint's Corpse Part"] = { Description = "A holy relic. Rolls a Stand from an alternate universe.", Rarity = "Mythical", Cost = 500000 },
	["Requiem Arrow"] = { Description = "An arrow with a bizzare beetle design. Pushes your stand beyond anything ever seen.", Rarity = "Mythical", Cost = 500000},
	
	["Legendary Giftbox"] = { Description = "Supplies you with a random Legendary-tier item!", Rarity = "Unique", Cost = 30000 },
	["Mythical Giftbox"] = { Description = "Supplies you with a random Mythical-tier item!", Rarity = "Unique", Cost = 50000 },
	
	["2x Battle Speed Pass"] = { Description = "Consumable gamepass. Unlocks 2x Battle Speed.", Rarity = "Unique", Cost = 0 },
	["2x Inventory Pass"] = { Description = "Consumable gamepass. Doubles your inventory capacity.", Rarity = "Unique", Cost = 0 },
	["2x Drop Chance Pass"] = { Description = "Consumable gamepass. Doubles all item drop rates.", Rarity = "Unique", Cost = 0 },
	["Auto Training Pass"] = { Description = "Consumable gamepass. Unlocks Auto Training.", Rarity = "Unique", Cost = 0 },
	["Stand Storage Slot 2"] = { Description = "Consumable gamepass. Unlocks Stand Storage Slot 2.", Rarity = "Unique", Cost = 0 },
	["Stand Storage Slot 3"] = { Description = "Consumable gamepass. Unlocks Stand Storage Slot 3.", Rarity = "Unique", Cost = 0 },
	["Style Storage Slot 2"] = { Description = "Consumable gamepass. Unlocks Style Storage Slot 2.", Rarity = "Unique", Cost = 0 },
	["Style Storage Slot 3"] = { Description = "Consumable gamepass. Unlocks Style Storage Slot 3.", Rarity = "Unique", Cost = 0 },
	["Auto-Roll Pass"] = { Description = "Consumable gamepass. Unlocks the Auto-Roll feature.", Rarity = "Unique", Cost = 0 },
	["Custom Horse Name"] = { Description = "Consumable gamepass. Unlocks the Custom Horse Name feature.", Rarity = "Unique", Cost = 0 },
}

return ItemData