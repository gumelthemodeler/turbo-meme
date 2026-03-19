-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local SkillData = {}

SkillData.Skills = {
	-- // BASE MOVES (Available to everyone) //
	["Basic Slash"] = { Requirement = "None", Type = "Basic", Mult = 1.0, StaminaCost = 0, EnergyCost = 0, Order = 1, Description = "A standard strike. Regenerates 5 Stamina and 5 Energy." },
	["Heavy Slash"] = { Requirement = "None", Type = "Basic", Mult = 1.4, StaminaCost = 5, EnergyCost = 0, Order = 2, Description = "A powerful, stamina-consuming attack." },
	["Block"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 5, EnergyCost = 0, Effect = "Block", Cooldown = 3, Order = 3, Description = "Brace yourself, reducing incoming damage by 50% for the next 2 turns." },
	["Regroup"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 0, EnergyCost = 0, Effect = "Rest", Order = 4, Description = "Skip your turn to rapidly recover 20 Stamina and 20 Energy." },
	["Retreat"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 0, EnergyCost = 0, Effect = "Flee", Order = 5, Description = "Fire a smoke signal and escape from the current battle." },

	-- // UNARMED / CADET BRAWLING //
	["Disarm"] = { Requirement = "Unarmed", Type = "Style", Mult = 1.2, StaminaCost = 6, EnergyCost = 0, Effect = "Debuff_Strength", Duration = 2, Cooldown = 4, Order = 6, Description = "Grapple the enemy, reducing their Strength for 2 turns." },
	["Leg Sweep"] = { Requirement = "Unarmed", Type = "Style", Mult = 1.3, StaminaCost = 8, EnergyCost = 0, Effect = "Stun", Duration = 1, Cooldown = 5, Order = 7, Description = "Knock the enemy off balance, stunning them briefly." },

	-- // ULTRAHARD STEEL BLADES (ODM Gear) //
	["Spinning Slash"] = { Requirement = "Ultrahard Steel Blades", Type = "Style", Mult = 0.5, Hits = 3, StaminaCost = 10, EnergyCost = 0, Order = 6, Description = "Use gas to rapidly spin and slash the target 3 times." },
	["Nape Strike"] = { Requirement = "Ultrahard Steel Blades", Type = "Style", Mult = 2.2, StaminaCost = 15, EnergyCost = 0, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 7, Description = "A precise, lethal strike to the vital point. Causes Bleed." },
	["Evasive Maneuver"] = { Requirement = "Ultrahard Steel Blades", Type = "Style", Mult = 0, StaminaCost = 8, EnergyCost = 0, Effect = "Buff_Speed", Duration = 3, Cooldown = 5, Order = 8, Description = "Burn gas to wildly change trajectory, vastly increasing Speed and evasion." },

	-- // THUNDER SPEARS //
	["Spear Volley"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 2.5, StaminaCost = 12, EnergyCost = 0, Effect = "Burn", Duration = 2, Cooldown = 4, Order = 6, Description = "Fire a highly explosive payload that burns the enemy." },
	["Armor Piercer"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 1.8, StaminaCost = 15, EnergyCost = 0, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 7, Description = "A shaped charge that shreds the enemy's Defense for 4 turns." },
	["Reckless Barrage"] = { Requirement = "Thunder Spears", Type = "Style", Mult = 0.8, Hits = 4, StaminaCost = 25, EnergyCost = 0, Cooldown = 7, Order = 8, Description = "Unleash all your spears at once. Devastating damage, but consumes massive Stamina." },

	-- // ANTI-PERSONNEL FIREARMS //
	["Grapple Shot"] = { Requirement = "Anti-Personnel Firearms", Type = "Style", Mult = 1.5, StaminaCost = 8, EnergyCost = 0, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 6, Description = "Shoot an ODM hook into the enemy to root them in place." },
	["Buckshot Spread"] = { Requirement = "Anti-Personnel Firearms", Type = "Style", Mult = 1.8, StaminaCost = 10, EnergyCost = 0, Effect = "Bleed", Duration = 2, Cooldown = 3, Order = 7, Description = "Fire a wide spread of shrapnel." },
	["Smoke Screen"] = { Requirement = "Anti-Personnel Firearms", Type = "Style", Mult = 0, StaminaCost = 5, EnergyCost = 0, Effect = "Buff_Defense", Duration = 3, Cooldown = 5, Order = 8, Description = "Deploy a smoke canister to obscure vision, raising your Defense." },

	-- // MARLEYAN RIFLE / ARTILLERY //
	["Knee Capper"] = { Requirement = "Marleyan Rifle", Type = "Style", Mult = 1.6, StaminaCost = 6, EnergyCost = 0, Effect = "Debuff_Speed", Duration = 3, Cooldown = 4, Order = 6, Description = "A precise shot to the legs, severely crippling enemy Speed." },
	["Anti-Titan Round"] = { Requirement = "Heavy Artillery", Type = "Style", Mult = 3.0, StaminaCost = 15, EnergyCost = 0, Cooldown = 6, Order = 7, Description = "Fire a devastating armor-piercing shell." },

	-- // TITAN SHIFTER ABILITIES (Uses 'Energy' instead of Stamina) //
	["Titan Roar"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 10, Description = "A terrifying roar that confuses and disorients the enemy." },
	["Hardened Punch"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 2.0, StaminaCost = 0, EnergyCost = 15, Effect = "Debuff_Defense", Duration = 2, Cooldown = 4, Order = 11, Description = "Focus crystal hardening into your knuckles to shatter enemy armor." },
	["Nape Guard"] = { Requirement = "AnyTitan", Type = "Titan", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Buff_Defense", Duration = 3, Cooldown = 6, Order = 12, Description = "Harden the nape of your neck, massively increasing Defense." },

	-- // SPECIFIC TITAN MOVES //
	["Colossal Steam"] = { Requirement = "Colossal Titan", Type = "Titan", Mult = 1.5, Hits = 2, StaminaCost = 0, EnergyCost = 25, Effect = "Burn", Duration = 3, Cooldown = 7, Order = 13, Description = "Emit waves of scorching steam, burning anyone nearby." },
	["Armored Tackle"] = { Requirement = "Armored Titan", Type = "Titan", Mult = 2.5, StaminaCost = 0, EnergyCost = 15, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 13, Description = "A devastating, unstoppable charge that stuns the target." },
	["War Hammer Spike"] = { Requirement = "War Hammer Titan", Type = "Titan", Mult = 2.8, StaminaCost = 0, EnergyCost = 20, Effect = "Bleed", Duration = 4, Cooldown = 5, Order = 13, Description = "Manifest a massive crystal spike from the ground to impale the enemy." },
	["Coordinate Command"] = { Requirement = "Founding Titan", Type = "Titan", Mult = 3.5, StaminaCost = 0, EnergyCost = 30, Effect = "Stun", Duration = 3, Cooldown = 8, Order = 13, Description = "Command pure titans to swarm and crush the enemy completely." }
}

return SkillData