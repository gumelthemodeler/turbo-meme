-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local SkillData = {}

SkillData.Skills = {
	-- // BASE MOVES //
	["Basic Slash"] = { Requirement = "None", Type = "Basic", Mult = 1.0, EnergyCost = 0, Order = 1, Description = "A standard strike to the target." },
	["Maneuver"] = { Requirement = "None", Type = "Basic", Mult = 0, EnergyCost = 0, Effect = "Block", Cooldown = 2, Order = 2, Description = "Evade incoming damage, reducing it by 50% for 2 turns." },
	["Recover"] = { Requirement = "None", Type = "Basic", Mult = 0, EnergyCost = 0, Effect = "Rest", Cooldown = 3, Order = 3, Description = "Skip your turn to recover health." },
	["Retreat"] = { Requirement = "None", Type = "Basic", Mult = 0, EnergyCost = 0, Effect = "Flee", Order = 4, Description = "Fire a smoke signal and escape." },

	-- // UNARMED / CADET BRAWLING //
	["Disarm"] = { Requirement = "Unarmed", Type = "Style", Mult = 1.2, Effect = "Debuff_Strength", Duration = 2, Cooldown = 4, Order = 6, Description = "Grapple the enemy, reducing their Strength for 2 turns." },
	["Leg Sweep"] = { Requirement = "Unarmed", Type = "Style", Mult = 1.3, Effect = "Stun", Duration = 1, Cooldown = 5, Order = 7, Description = "Knock the enemy off balance, stunning them briefly." },

	-- // ULTRAHARD STEEL BLADES (ODM Gear) //
	["Spinning Slash"] = { Requirement = "Ultrahard Steel Blades", Type = "Style", Mult = 0.5, Hits = 3, Order = 6, Description = "Use gas to rapidly spin and slash the target 3 times." },
	["Nape Strike"] = { Requirement = "Ultrahard Steel Blades", Type = "Style", Mult = 2.2, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 7, Description = "A precise, lethal strike to the vital point. Causes Bleed." },

	-- // THUNDER SPEARS //
	["Spear Volley"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 2.5, Effect = "Burn", Duration = 2, Cooldown = 4, Order = 6, Description = "Fire a highly explosive payload that burns the enemy." },
	["Armor Piercer"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 1.8, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 7, Description = "A shaped charge that shreds the enemy's Defense for 4 turns." },
	["Reckless Barrage"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 0.8, Hits = 4, Cooldown = 7, Order = 8, Description = "Unleash all your spears at once." },

	-- // TITAN SHIFTER ABILITIES //
	["Titan Roar"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 0, Effect = "Confusion", Duration = 2, EnergyCost = 20, Cooldown = 5, Order = 10, Description = "A terrifying roar that confuses and disorients the enemy." },
	["Hardened Punch"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 2.0, Effect = "Debuff_Defense", Duration = 2, EnergyCost = 30, Cooldown = 4, Order = 11, Description = "Focus crystal hardening into your knuckles to shatter enemy armor." },
	["Nape Guard"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 0, Effect = "Buff_Defense", Duration = 3, EnergyCost = 40, Cooldown = 6, Order = 12, Description = "Harden the nape of your neck, massively increasing Defense." },

	-- // SPECIFIC TITAN MOVES //
	["Colossal Steam"] = { Requirement = "Colossal Titan", Type = "Titan", Mult = 1.5, Hits = 2, Effect = "Burn", Duration = 3, EnergyCost = 50, Cooldown = 7, Order = 13, Description = "Emit waves of scorching steam, burning anyone nearby." },
	["Armored Tackle"] = { Requirement = "Armored Titan", Type = "Titan", Mult = 2.5, Effect = "Stun", Duration = 2, EnergyCost = 40, Cooldown = 5, Order = 13, Description = "A devastating, unstoppable charge that stuns the target." },
	["War Hammer Spike"] = { Requirement = "War Hammer Titan", Type = "Titan", Mult = 2.8, Effect = "Bleed", Duration = 4, EnergyCost = 45, Cooldown = 5, Order = 13, Description = "Manifest a massive crystal spike from the ground to impale the enemy." },
	["Coordinate Command"] = { Requirement = "Founding Titan", Type = "Titan", Mult = 3.5, Effect = "Stun", Duration = 3, EnergyCost = 80, Cooldown = 8, Order = 13, Description = "Command pure titans to swarm and crush the enemy completely." }
}

return SkillData