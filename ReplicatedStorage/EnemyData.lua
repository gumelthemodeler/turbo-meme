-- @ScriptType: ModuleScript
local EnemyData = {}

local emptyTitans = {Power="None", Speed="None", Hardening="None",
	Endurance="None", Precision="None", Potential="None"}

EnemyData.Allies = {
	["Armin Arlert"] = { Name = "Armin Arlert", Health = 80, Strength = 12, Defense = 5, Speed = 8, Willpower = 25, TitanStats = emptyTitans, Skills = {"Spinning Slash", "Regroup", "Basic Slash"} },
	["Mikasa Ackerman"] = { Name = "Mikasa Ackerman", Health = 150, Strength = 40, Defense = 10, Speed = 35, Willpower = 15, TitanStats = emptyTitans, Skills = {"Nape Strike", "Spinning Slash", "Basic Slash"} },
	["Levi Ackerman"] = { Name = "Levi Ackerman", Health = 250, Strength = 65, Defense = 15, Speed = 55, Willpower = 30, TitanStats = emptyTitans, Skills = {"Nape Strike", "Evasive Maneuver", "Spinning Slash"} },
	["Hange Zoe"] = { Name = "Hange Zoe", Health = 200, Strength = 30, Defense = 20, Speed = 25, Willpower = 25, TitanStats = emptyTitans, Skills = {"Spear Volley", "Evasive Maneuver", "Basic Slash"} },
	["Erwin Smith"] = { Name = "Erwin Smith", Health = 400, Strength = 35, Defense = 30, Speed = 20, Willpower = 100, Skills = {"Heavy Slash", "Regroup", "Basic Slash"} }
}

EnemyData.RaidBosses = {
	["Raid_Part1"] = { 
		IsBoss = true, Name = "Female Titan", Req = 1, 
		Health = 5000, Strength = 60, Defense = 50, Speed = 65, Willpower = 60, TitanStats = {Power="A", Speed="A", Hardening="A", Endurance="B", Precision="B", Potential="B"}, 
		Skills = {"Hardened Punch", "Nape Guard", "Leg Sweep", "Block"}, 
		Drops = { Yen = 1000, XP = 2500, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 5, ["Scout Regiment Cloak"] = 25, ["Scout Training Manual"] = 15 } } 
	},
	["Raid_Part2"] = { 
		IsBoss = true, Name = "Armored Titan", Req = 1, 
		Health = 12000, Strength = 80, Defense = 100, Speed = 30, Willpower = 70, TitanStats = {Power="B", Speed="C", Hardening="S", Endurance="A", Precision="C", Potential="C"}, 
		Skills = {"Armored Tackle", "Hardened Punch", "Heavy Slash", "Block"}, 
		Drops = { Yen = 2500, XP = 5000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 6, ["Advanced ODM Gear"] = 15, ["Ultrahard Steel Blades"] = 25 } } 
	},
	["Raid_Part3"] = { 
		IsBoss = true, Name = "Beast Titan", Req = 1, 
		Health = 15000, Strength = 100, Defense = 60, Speed = 40, Willpower = 85, TitanStats = {Power="S", Speed="C", Hardening="B", Endurance="A", Precision="A", Potential="A"}, 
		Skills = {"Titan Roar", "Hardened Punch", "Heavy Slash", "Block"}, 
		Drops = { Yen = 5000, XP = 10000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 7, ["Spinal Fluid Syringe"] = 5, ["Marleyan Armband"] = 25 } } 
	},
	["Raid_Part4"] = { 
		IsBoss = true, Name = "War Hammer Titan", Req = 1, 
		Health = 20000, Strength = 150, Defense = 80, Speed = 60, Willpower = 100, TitanStats = {Power="A", Speed="B", Hardening="S", Endurance="B", Precision="A", Potential="A"}, 
		Skills = {"War Hammer Spike", "Hardened Punch", "Block"}, 
		Drops = { Yen = 8000, XP = 15000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 8, ["Spinal Fluid Syringe"] = 10, ["Marleyan Combat Manual"] = 25 } } 
	},
	["Raid_Part5"] = { 
		IsBoss = true, Name = "Founding Titan (Eren)", Req = 1, 
		Health = 35000, Strength = 300, Defense = 150, Speed = 20, Willpower = 250, TitanStats = {Power="S", Speed="E", Hardening="S", Endurance="S", Precision="A", Potential="S"}, 
		Skills = {"Coordinate Command", "Colossal Steam", "Block"}, 
		Drops = { Yen = 30000, XP = 50000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 15, ["Spinal Fluid Syringe"] = 25, ["Ymir's Clay Fragment"] = 5 } } 
	},
	["Raid_Part6"] = { 
		IsBoss = true, Name = "Jaw Titan", Req = 1, 
		Health = 18000, Strength = 140, Defense = 60, Speed = 120, Willpower = 80, TitanStats = {Power="A", Speed="S", Hardening="B", Endurance="C", Precision="A", Potential="B"}, 
		Skills = {"Spinning Slash", "Nape Strike", "Block"}, -- Simulating the Jaw's speed and bite
		Drops = { Yen = 6500, XP = 12000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 8 } } 
	},
	["Raid_Part7"] = { 
		IsBoss = true, Name = "Cart Titan (Panzer Unit)", Req = 1, 
		Health = 22000, Strength = 120, Defense = 90, Speed = 90, Willpower = 95, TitanStats = {Power="B", Speed="A", Hardening="C", Endurance="S", Precision="B", Potential="A"}, 
		Skills = {"Buckshot Spread", "Anti-Titan Round", "Evasive Maneuver", "Block"}, 
		Drops = { Yen = 7500, XP = 14000, ItemChance = { ["Standard Titan Serum"] = 100, ["Advanced ODM Gear"] = 15, ["Marleyan Combat Manual"] = 25 } } 
	},
	["Raid_Part8"] = { 
		IsBoss = true, Name = "Colossal Titan", Req = 1, 
		Health = 45000, Strength = 400, Defense = 120, Speed = 10, Willpower = 150, TitanStats = {Power="S", Speed="E", Hardening="C", Endurance="S", Precision="E", Potential="S"}, 
		Skills = {"Colossal Steam", "Heavy Slash", "Block"}, 
		Drops = { Yen = 15000, XP = 25000, ItemChance = { ["Standard Titan Serum"] = 100, ["Spinal Fluid Syringe"] = 10, ["Ymir's Clay Fragment"] = 2 } } 
	}
}

EnemyData.WorldBosses = {
	["Rod Reiss Titan"] = {
		Name = "Rod Reiss (Abnormal)", IsBoss = true, 
		Health = 1000000, Strength = 500, Defense = 300, Speed = 10, Willpower = 500, TitanStats = {Power="S", Speed="E", Hardening="C", Endurance="S", Precision="E", Potential="E"},
		Skills = {"Colossal Steam", "Heavy Slash", "Block"},
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 5, ["Spinal Fluid Syringe"] = 5 } 
		}
	},
	["Kenny Ackerman"] = {
		Name = "Kenny Ackerman", IsBoss = true, 
		Health = 500000, Strength = 400, Defense = 150, Speed = 400, Willpower = 500, TitanStats = emptyTitans,
		Skills = {"Buckshot Spread", "Grapple Shot", "Smoke Screen", "Block"},
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Standard Titan Serum"] = 100, ["Ackerman Awakening Pill"] = 5, ["Anti-Personnel Pistols"] = 15 } 
		}
	},
	["Berserk Attack Titan"] = {
		Name = "Attack Titan (Berserk)", IsBoss = true, 
		Health = 800000, Strength = 600, Defense = 200, Speed = 100, Willpower = 1000, TitanStats = {Power="S", Speed="A", Hardening="B", Endurance="A", Precision="A", Potential="S"},
		Skills = {"Hardened Punch", "Titan Roar", "Heavy Slash", "Block"},
		Drops = { 
			XP = 30000, Yen = 12000, 
			ItemChance = { ["Standard Titan Serum"] = 100, ["Spinal Fluid Syringe"] = 10, ["Ymir's Clay Fragment"] = 5 } 
		}
	},
	["Lara Tybur"] = {
		Name = "Lara Tybur (War Hammer)", IsBoss = true, 
		Health = 900000, Strength = 550, Defense = 400, Speed = 80, Willpower = 600, TitanStats = {Power="S", Speed="B", Hardening="S", Endurance="S", Precision="A", Potential="A"},
		Skills = {"War Hammer Spike", "Armor Piercer", "Nape Guard", "Block"},
		Drops = { 
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Standard Titan Serum"] = 100, ["Spinal Fluid Syringe"] = 15, ["Marleyan Combat Manual"] = 50 } 
		}
	}
}

EnemyData.Parts = {
	[1] = {
		Boss = { IsBoss = true, Name = "Abnormal Titan", Health = 150, Strength = 15, Defense = 8, Speed = 10, Willpower = 12, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Block", "Basic Slash"}, Drops = { Yen = 80, XP = 150, ItemChance={["Cadet Training Blade"]=15} } },
		RandomFlavor = {"You wander the streets of Trost, and encounter a %s!", "A %s steps out from the ruins!", "You are ambushed by a %s!"},
		Mobs = {
			{ Name = "3-Meter Pure Titan",  
				Health = 40, Strength = 5, Defense = 2, Speed = 3, Willpower = 2, TitanStats = emptyTitans, 
				Skills = {"Basic Slash", "Block"}, 
				Drops = { Yen = 5, XP = 10, ItemChance = { ["Cadet Training Blade"] = 5 } } },
			{ Name = "7-Meter Pure Titan", 
				Health = 80, Strength = 8, Defense = 4, Speed = 5, Willpower = 3, TitanStats = emptyTitans, 
				Skills = {"Heavy Slash", "Basic Slash"}, 
				Drops = { Yen = 8, XP = 20, ItemChance = { ["Scout Training Manual"] = 2 } } }
		},
		Templates = {
			["Crawler Titan"] = { Name = "Crawler Titan", 
				Health = 50, Strength = 6, Defense = 2, Speed = 8, Willpower = 2, TitanStats = emptyTitans, 
				Skills = {"Heavy Slash", "Block"}, 
				Drops = { Yen = 5, XP = 10 } },
			["Abnormal"] = { Name = "Abnormal Titan", 
				Health = 120, Strength = 12, Defense = 5, Speed = 12, Willpower = 5, TitanStats = emptyTitans, 
				Skills = {"Spinning Slash", "Heavy Slash", "Block"}, 
				Drops = { Yen = 20, XP = 40, ItemChance={["Scout Regiment Cloak"]=5} } }
		},
		Missions = {
			[1] = { Name = "Fall of Shiganshina", Waves = { { Template = "3-Meter Pure Titan", Flavor = "The wall has been breached! Pure titans flood in." } } },
			[2] = { Name = "Trost District", Waves = { { Template = "7-Meter Pure Titan", Flavor = "You run out of gas and are cornered by a 7-meter class!" } } },
			[3] = { Name = "Supply Depot", Waves = { { Template = "Crawler Titan", Flavor = "A crawler titan blocks the path to the gas resupply." }, { Template = "Abnormal", Flavor = "An abnormal approaches rapidly!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Veteran Retake", Waves = { { Template = "Abnormal", Flavor = "You easily dispatch the first wave, but an Abnormal spots you." } } }
		}
	},

	[2] = {
		Boss = { IsBoss = true, Name = "Beast's Pure Titan", Health = 350, Strength = 32, Defense = 22, Speed = 28, Willpower = 30, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Titan Roar", "Block"}, Drops = { Yen = 150, XP = 300, ItemChance = { ["Scout Regiment Cloak"] = 20, ["Ultrahard Steel Blades"] = 15 } } },
		RandomFlavor = {"You encounter a %s in the fields!", "A %s jumps out from the trees!"},
		Mobs = {
			{ Name = "Nighttime Pure Titan", 
				Health = 100, Strength = 12, Defense = 8, Speed = 15, Willpower = 8, TitanStats = emptyTitans, 
				Skills = {"Basic Slash", "Block", "Heavy Slash"}, 
				Drops = { Yen = 15, XP = 40 } },
			{ Name = "Moonlight Abnormal", 
				Health = 150, Strength = 16, Defense = 10, Speed = 20, Willpower = 12, TitanStats = emptyTitans, 
				Skills = {"Heavy Slash", "Titan Roar", "Block"}, 
				Drops = { Yen = 25, XP = 60, ItemChance = { ["Ultrahard Steel Blades"] = 5 } } }
		},
		Templates = {
			["Utgard Titan"] = { Name = "Utgard Castle Titan", 
				Health = 200, Strength = 20, Defense = 15, Speed = 12, Willpower = 18, TitanStats = emptyTitans, 
				Skills = {"Heavy Slash", "Block"}, 
				Drops = { Yen = 50, XP = 120 } }
		},
		Missions = {
			[1] = { Name = "Wall Rose Breach", Waves = { { Template = "Nighttime Pure Titan", Flavor = "Titans are moving at night? Impossible!" } } },
			[2] = { Name = "Utgard Castle", Waves = { { Template = "Utgard Titan", Flavor = "They are tearing the tower apart! Defend the perimeter!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Castle Defense", Waves = { { Template = "Moonlight Abnormal", Flavor = "You lead the charge from the tower." } } }
		}
	},

	[3] = {
		Boss = { IsBoss = true, Name = "Kenny's Lieutenant", Health = 600, Strength = 60, Defense = 35, Speed = 50, Willpower = 45, TitanStats = emptyTitans, Skills = {"Grapple Shot", "Buckshot Spread", "Smoke Screen", "Block"}, Drops = { Yen = 400, XP = 800, ItemChance = { ["Anti-Personnel Pistols"] = 25, ["Commander's Bolo Tie"] = 5 } } },
		RandomFlavor = {"An %s attacks you in the Crystal Caverns!", "An enemy, %s, blocks the path!"},
		Mobs = {
			{ Name = "Anti-Personnel MP", 
				Health = 200, Strength = 25, Defense = 15, Speed = 30, Willpower = 18, TitanStats = emptyTitans, 
				Skills = {"Buckshot Spread", "Evasive Maneuver", "Block"}, 
				Drops = { Yen = 40, XP = 150, ItemChance = { ["Anti-Personnel Pistols"] = 5 } } }
		},
		Templates = {
			["Interior MP"] = { Name = "Interior MP Grunt", 
				Health = 220, Strength = 28, Defense = 16, Speed = 25, Willpower = 20, TitanStats = emptyTitans, 
				Skills = {"Grapple Shot", "Basic Slash"}, 
				Drops = { Yen = 60, XP = 180 } }
		},
		Missions = {
			[1] = { Name = "Stohess Ambush", Waves = { { Template = "Interior MP", Flavor = "The Military Police are targeting the Scouts!" } } },
			[2] = { Name = "Crystal Caverns", Waves = { { Template = "Anti-Personnel MP", Flavor = "They have guns instead of blades! Take cover!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Cavern Shootout", Waves = { { Template = "Anti-Personnel MP", Flavor = "You dodge the buckshot and close the distance." } } }
		}
	},

	[4] = {
		Boss = { IsBoss = true, Name = "Marleyan Warrior Candidate", Health = 1100, Strength = 90, Defense = 50, Speed = 75, Willpower = 65, TitanStats = emptyTitans, Skills = {"Knee Capper", "Anti-Titan Round", "Block"}, Drops = { Yen = 600, XP = 1200, ItemChance = { ["Marleyan Combat Manual"] = 15, ["Marleyan Armband"] = 25 } } },
		RandomFlavor = {"You run into a %s in Liberio!"},
		Mobs = { { Name = "Marleyan Guard", 
			Health = 350, Strength = 40, Defense = 25, Speed = 35, Willpower = 25, TitanStats = emptyTitans, 
			Skills = {"Basic Slash", "Block"}, 
			Drops = { Yen = 60, XP = 200, ItemChance = { ["Marleyan Armband"] = 5 } } } },
		Templates = {
			["Marleyan Sniper"] = { Name = "Marleyan Sniper", 
				Health = 400, Strength = 60, Defense = 20, Speed = 45, Willpower = 28, TitanStats = emptyTitans, 
				Skills = {"Knee Capper", "Smoke Screen"}, 
				Drops = { Yen = 70, XP = 250 } }
		},
		Missions = {
			[1] = { Name = "Liberio Internment Zone", Waves = { { Template = "Marleyan Guard", Flavor = "Marleyan soldiers have spotted you!" } } },
			[2] = { Name = "Rooftop Snipers", Waves = { { Template = "Marleyan Sniper", Flavor = "Taking fire from the rooftops!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Declaration of War", Waves = { { Template = "Marleyan Guard", Flavor = "You strike first before the speech ends." } } }
		}
	},
	
	[5] = {
		Boss = { IsBoss = true, Name = "Armored Titan (Reiner)", Health = 1500, Strength = 120, Defense = 150, Speed = 45, Willpower = 90, TitanStats = {Power="B", Speed="C", Hardening="S", Endurance="A", Precision="C", Potential="C"}, Skills = {"Armored Tackle", "Hardened Punch", "Block"}, Drops = { Yen = 1000, XP = 2500, ItemChance = { ["Spinal Fluid Syringe"] = 2, ["Thunder Spear"] = 5 } } },
		RandomFlavor = {"You are ambushed in the ruins of Shiganshina!"},
		Mobs = { { Name = "Zeke's Controlled Titan", 
			Health = 450, Strength = 50, Defense = 20, Speed = 40, Willpower = 20, TitanStats = emptyTitans, 
			Skills = {"Heavy Slash", "Block"}, 
			Drops = { Yen = 80, XP = 300, ItemChance = { ["Ultrahard Steel Blades"] = 10 } } } },
		Templates = {
			["Beast Titan Pitcher"] = { Name = "Beast Titan (Rock Throw)", 
				Health = 800, Strength = 150, Defense = 60, Speed = 30, Willpower = 80, TitanStats = emptyTitans, 
				Skills = {"Buckshot Spread", "Titan Roar"}, 
				Drops = { Yen = 200, XP = 600 } }
		},
		Missions = {
			[1] = { Name = "Return to Shiganshina", Waves = { { Template = "Zeke's Controlled Titan", Flavor = "The Beast Titan has trapped the Scouts!" } } },
			[2] = { Name = "Perfect Game", Waves = { { Template = "Beast Titan Pitcher", Flavor = "A barrage of crushed boulders obliterates the front lines!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Suicide Charge", Waves = { { Template = "Beast Titan Pitcher", Flavor = "You lead the charge through the flying rocks!" } } }
		}
	},

	[6] = {
		Boss = { IsBoss = true, Name = "Jaw Titan (Porco)", Health = 2200, Strength = 160, Defense = 80, Speed = 150, Willpower = 100, TitanStats = {Power="A", Speed="S", Hardening="B", Endurance="C", Precision="A", Potential="B"}, Skills = {"Nape Strike", "Spinning Slash", "Evasive Maneuver", "Block"}, Drops = { Yen = 1500, XP = 4000, ItemChance = { ["Standard Titan Serum"] = 20, ["Advanced ODM Gear"] = 10 } } },
		RandomFlavor = {"Marleyan forces are dropping from the sky!"},
		Mobs = { { Name = "Marleyan Paratrooper", 
			Health = 600, Strength = 70, Defense = 40, Speed = 60, Willpower = 50, TitanStats = emptyTitans, 
			Skills = {"Buckshot Spread", "Smoke Screen", "Block"}, 
			Drops = { Yen = 120, XP = 500, ItemChance = { ["Marleyan Rifle"] = 10 } } } },
		Templates = {
			["Anti-Titan Artillery"] = { Name = "Anti-Titan Artillery", 
				Health = 500, Strength = 200, Defense = 100, Speed = 10, Willpower = 100, TitanStats = emptyTitans, 
				Skills = {"Anti-Titan Round", "Block"}, 
				Drops = { Yen = 300, XP = 800 } }
		},
		Missions = {
			[1] = { Name = "Surprise Attack", Waves = { { Template = "Marleyan Paratrooper", Flavor = "Marleyan forces invade Paradis Island!" } } },
			[2] = { Name = "Wall Defenses", Waves = { { Template = "Anti-Titan Artillery", Flavor = "They've mounted cannons on the walls! Take them out!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Two-Front War", Waves = { { Template = "Anti-Titan Artillery", Flavor = "You grapple onto the cannons before they can fire." } } }
		}
	},

	[7] = {
		Boss = { IsBoss = true, Name = "Doomsday Titan (Eren)", Health = 10000, Strength = 500, Defense = 500, Speed = 15, Willpower = 500, TitanStats = {Power="S", Speed="E", Hardening="S", Endurance="S", Precision="S", Potential="S"}, Skills = {"Coordinate Command", "Colossal Steam", "War Hammer Spike", "Block"}, Drops = { Yen = 5000, XP = 15000, ItemChance = { ["Ymir's Clay Fragment"] = 5, ["Spinal Fluid Syringe"] = 25 } } },
		RandomFlavor = {"The ground shakes violently. The Rumbling has begun!"},
		Mobs = { { Name = "Wall Titan", 
			Health = 1500, Strength = 250, Defense = 150, Speed = 20, Willpower = 100, TitanStats = emptyTitans, 
			Skills = {"Colossal Steam", "Heavy Slash", "Block"}, 
			Drops = { Yen = 400, XP = 1200, ItemChance = { ["Thunder Spear"] = 5 } } } },
		Templates = {
			["Ancient Shifter"] = { Name = "Ancient Nine Titan Husk", 
				Health = 2000, Strength = 200, Defense = 120, Speed = 100, Willpower = 150, TitanStats = emptyTitans, 
				Skills = {"Armored Tackle", "War Hammer Spike", "Nape Strike", "Block"}, 
				Drops = { Yen = 600, XP = 2000 } }
		},
		Missions = {
			[1] = { Name = "The Rumbling", Waves = { { Template = "Wall Titan", Flavor = "Millions of Colossal Titans march forward." } } },
			[2] = { Name = "Battle of Heaven and Earth", Waves = { { Template = "Ancient Shifter", Flavor = "Ymir is summoning Titans from past generations!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Stopping the Advance", Waves = { { Template = "Wall Titan", Flavor = "You detonate Thunder Spears on the nape!" } } }
		}
	}
}

return EnemyData