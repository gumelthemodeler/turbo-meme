-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatCore = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

function CombatCore.HasModifier(modStr, modName)
	if not modStr or modStr == "None" or modStr == "" then return false end
	for _, m in ipairs(string.split(modStr, ",")) do
		if m == modName then return true end
	end
	return false
end

function CombatCore.GetEquipBonus(player, statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0

	if ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.WeaponBonuses and GameData.WeaponBonuses[style] and GameData.WeaponBonuses[style][statName] then bonus += GameData.WeaponBonuses[style][statName] end

	return bonus
end

function CombatCore.GetPlayerBoosts(player)
	local boosts = { XP = 1.0, Dews = 1.0, Luck = 0, Damage = 1.0 }
	if not player then return boosts end

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	boosts.XP += (friends * 0.05)
	boosts.Dews += (friends * 0.05)

	if player.MembershipType == Enum.MembershipType.Premium then boosts.XP += 0.05 end
	if player:GetAttribute("IsSupporter") then boosts.XP += 0.05; boosts.Luck += 1 end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 1500 then boosts.Dews += 0.05 end
	if elo >= 2000 then boosts.XP += 0.05 end
	if elo >= 3000 then boosts.Luck += 1 end
	if elo >= 5000 then boosts.Damage *= 1.05 end

	boosts.Dews *= (player:GetAttribute("ClanDewsBoost") or 1.0)
	boosts.XP *= (player:GetAttribute("ClanXPBoost") or 1.0)
	local cLuck = player:GetAttribute("ClanLuckBoost") or 1.0
	if cLuck > 1.0 then boosts.Luck += 1 end 
	boosts.Damage *= (player:GetAttribute("ClanDmgBoost") or 1.0)

	local uniModStr = player:GetAttribute("BattleCondition") or "None"
	if CombatCore.HasModifier(uniModStr, "Lucky Star") then boosts.Luck += 1 end
	if CombatCore.HasModifier(uniModStr, "Unlucky Aura") then boosts.Luck -= 1 end

	return boosts
end

function CombatCore.CalculateDamage(attacker, defender, skillMult, isDefenderBlocking, uniModStr)
	local atkBuff = (attacker.Statuses and (attacker.Statuses.Buff_Strength or 0) > 0) and 1.5 or 1.0
	local atkDebuff = (attacker.Statuses and (attacker.Statuses.Debuff_Strength or 0) > 0) and 0.5 or 1.0

	local defBuff = (defender.Statuses and (defender.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
	local defDebuff = (defender.Statuses and (defender.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0

	local baseDmg = (attacker.TotalStrength or 1) * atkBuff * atkDebuff * skillMult

	if attacker.IsPlayer then
		if attacker.Clan == "Ackerman" and (attacker.Style == "Ultrahard Steel Blades" or attacker.Style == "Thunder Spears") then
			baseDmg *= 1.25
		end
		if attacker.Clan == "Yeager" and attacker.Titan == "Attack Titan" and attacker.IsTransformed then
			local missingHP = 1 - (attacker.HP / attacker.MaxHP)
			baseDmg *= (1 + (missingHP * 0.5))
		end
		if attacker.Clan == "Tybur" and attacker.Titan == "War Hammer Titan" then
			baseDmg *= 1.15
		end
	end

	if attacker.IsPlayer then
		if CombatCore.HasModifier(uniModStr, "Forest of Giant Trees") then baseDmg *= 1.15 end
		if CombatCore.HasModifier(uniModStr, "Flimsy Blades") then baseDmg *= 1.50 end
		if CombatCore.HasModifier(uniModStr, "Desperate Struggle") and (attacker.HP / attacker.MaxHP) <= 0.3 then baseDmg *= 1.50 end
	else
		if CombatCore.HasModifier(uniModStr, "Veteran Experience") then baseDmg *= 1.25 end
	end

	local defBypass = attacker.Trait == "Overwhelming" and 0.30 or 0
	local effectiveArmor = ((defender.TotalDefense or 0) * defBuff * defDebuff) * (1 - defBypass)

	if defender.IsPlayer and defender.Clan == "Braun" then
		effectiveArmor *= 1.25 
	end

	if defender.IsPlayer then
		if CombatCore.HasModifier(uniModStr, "Flimsy Blades") then effectiveArmor *= 0.75 end
		if CombatCore.HasModifier(uniModStr, "Hardened Skin") then effectiveArmor *= 1.10 end
		if CombatCore.HasModifier(uniModStr, "Open Plains") then effectiveArmor *= 0.90 end
	end

	local armorPen = (attacker.TotalPrecision or 0) * 0.5 
	local effectiveDefense = math.max(0, effectiveArmor - armorPen)

	local defenseMultiplier = 100 / (100 + effectiveDefense)
	local finalDmg = baseDmg * defenseMultiplier

	if defender.Trait == "Armored" then finalDmg *= 0.85 end
	if defender.Trait == "Indomitable" and (defender.HP / defender.MaxHP) <= 0.3 then finalDmg *= 0.75 end

	if CombatCore.HasModifier(uniModStr, "The Rumbling") then finalDmg *= 1.50 end

	if isDefenderBlocking then finalDmg *= 0.5 end
	if attacker.GlobalDmgBoost then finalDmg *= attacker.GlobalDmgBoost end

	return math.max(1, finalDmg)
end

function CombatCore.ChooseAISkill(combatant)
	local validSkills = {}
	if combatant.Skills then
		for _, sName in ipairs(combatant.Skills) do
			local cd = combatant.Cooldowns and combatant.Cooldowns[sName] or 0
			if cd > 0 then continue end
			local sData = SkillData.Skills[sName]
			if sData and sData.Effect == "Block" and combatant.BlockTurns > 0 then continue end
			table.insert(validSkills, sName)
		end
	end
	if #validSkills > 0 then return validSkills[math.random(1, #validSkills)] else return "Basic Slash" end
end

function CombatCore.TakeDamageWithWillpower(combatant, damage)
	if (combatant.HP - damage) < 1 then
		local defWillBuff = (((combatant.Statuses and combatant.Statuses.Buff_Willpower or 0) > 0) and 1.5 or 1.0) * (((combatant.Statuses and combatant.Statuses.Debuff_Willpower or 0) > 0) and 0.5 or 1.0)
		local defWill = (combatant.TotalWillpower or 1) * defWillBuff

		if combatant.IsPlayer then
			local uniModStr = combatant.PlayerObj and combatant.PlayerObj:GetAttribute("BattleCondition") or "None"
			if CombatCore.HasModifier(uniModStr, "Paths Connection") then defWill *= 1.2 end
		end

		local survivalChance = math.clamp(defWill * 0.7, 0, 45)

		if (combatant.WillpowerSurvivals or 0) < 1 and math.random(1, 100) <= survivalChance then
			if combatant.Trait == "Perseverance" then
				combatant.HP = math.max(1, combatant.MaxHP * 0.25)
			else
				combatant.HP = 1
			end
			combatant.WillpowerSurvivals = (combatant.WillpowerSurvivals or 0) + 1
			return true 
		end
	end
	combatant.HP -= damage
	return false
end

function CombatCore.ApplyStatusDamage(combatant, uniModStr, CombatUpdate, player, battle, waitMultiplier)
	local statusDmgMod = CombatCore.HasModifier(uniModStr, "Cursed Wounds") and 0.07 or 0.05 

	if combatant.IsBoss then statusDmgMod = statusDmgMod * 0.85 end

	if combatant.Statuses.Bleed > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Bleed -= 1
		local svMsg = survived and (combatant.Trait == "Perseverance" and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>"..combatant.Name.." bled for "..math.floor(dmg).." damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Poison > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Poison -= 1
		local svMsg = survived and (combatant.Trait == "Perseverance" and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AA00AA'>"..combatant.Name.." took "..math.floor(dmg).." Poison damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Burn > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Burn -= 1
		local svMsg = survived and (combatant.Trait == "Perseverance" and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF5500'>"..combatant.Name.." took "..math.floor(dmg).." Burn damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Freeze > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Freeze -= 1
		local svMsg = survived and (combatant.Trait == "Perseverance" and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#00FFFF'>"..combatant.Name.." took "..math.floor(dmg).." damage and is crystallized!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
		if combatant.HP < 1 then return end

		if combatant.IsPlayer and not CombatCore.HasModifier(uniModStr, "Paths Connection") then
			combatant.TitanEnergy = math.min(100, (combatant.TitanEnergy or 0) + 5)
		end
		return "Frozen"
	end
end

function CombatCore.ExecuteStrike(attacker, defender, skillName, uniModStr, logName, defName, logColor, defColor)
	local skill = SkillData.Skills[skillName] or SkillData.Skills["Basic Slash"]
	uniModStr = uniModStr or "None"

	local fLogName = "<font color='" .. (logColor or "#FFFFFF") .. "'>" .. logName .. "</font>"
	local fDefName = "<font color='" .. (defColor or "#FF5555") .. "'>" .. defName .. "</font>"
	local msgPrefix = ""

	local t = defender
	local tName = fDefName
	local b = attacker
	local bName = fLogName

	if attacker.Statuses and (attacker.Statuses.Confusion or 0) > 0 then
		msgPrefix = "<font color='#FF55FF'>[CONFUSED] </font>"
		t = attacker
		tName = fLogName
		b = defender
		bName = fDefName
	end

	if skill.Effect ~= "Flee" then
		if attacker.IsPlayer then
			local nrgCost = skill.EnergyCost or 0
			if CombatCore.HasModifier(uniModStr, "ODM Surge") then nrgCost *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Paths Connection") then nrgCost *= 0.5 end
			if attacker.TitanEnergy then attacker.TitanEnergy = math.max(0, attacker.TitanEnergy - nrgCost) end
		end
		if attacker.Cooldowns then attacker.Cooldowns[skillName] = skill.Cooldown or 0 end
	end

	local function ApplyCC(effectName, duration, tgt, colorHex, overrideMsg)
		if effectName == "Stun" or effectName == "Freeze" then
			if tgt.StunImmunity and tgt.StunImmunity > 0 then
				return " <font color='#AAAAAA'>(" .. (overrideMsg or effectName) .. " Resisted!)</font>"
			else
				tgt.Statuses[effectName] = duration
				tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end
		elseif effectName == "Confusion" then
			if tgt.ConfusionImmunity and tgt.ConfusionImmunity > 0 then
				return " <font color='#AAAAAA'>(Confusion Resisted!)</font>"
			else
				tgt.Statuses[effectName] = duration
				tgt.ConfusionImmunity = duration + (tgt.IsBoss and 6 or 3)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end
		else
			tgt.Statuses[effectName] = duration
			return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
		end
	end

	-- Utility & Healing Effects
	if skill.Effect == "Block" or skillName == "Maneuver" then
		b.BlockTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! " .. bName .. " maneuvers defensively, reducing incoming damage.", false, "None"
	elseif skill.Effect == "Rest" or skillName == "Recover" then
		local healAmount = (b.MaxHP or 100) * 0.12
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. bName .. " regroups, recovering " .. math.floor(healAmount) .. " HP.</font>", false, "None"
	elseif skill.Effect == "Heal" then
		local healAmount = (b.MaxHP or 100) * (skill.HealPercent or 0.25)
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and recovered <font color='#55FF55'>" .. math.floor(healAmount) .. " HP</font> for " .. bName .. "!", false, "None"
	elseif skill.Effect == "Buff_Random" then
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		b.Statuses["Buff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. s .. " is boosted!</font>", false, "None"
	elseif skill.Effect and string.sub(skill.Effect, 1, 5) == "Buff_" then
		local statName = string.sub(skill.Effect, 6); b.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. statName .. " is boosted!</font>", false, "None"
	elseif skill.Effect == "Debuff_Random" then
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		t.Statuses["Debuff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. s .. " is reduced!</font>", false, "None"
	elseif skill.Effect and string.sub(skill.Effect, 1, 7) == "Debuff_" then
		local statName = string.sub(skill.Effect, 8); t.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. statName .. " is reduced!</font>", false, "None"
	end

	local hitsToDo = skill.Hits or 1
	local isUnavoidable = (skillName == "Titan Roar" or skillName == "Coordinate Command")

	local msg = ""
	msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>" .. (hitsToDo == 1 and "" or "!")

	local hitLogs = {}
	local didHitAtAll = false
	local overallShake = "None"
	local effectApplied = false

	for i = 1, hitsToDo do
		if t.HP < 1 and i > 1 then break end 

		local atkSpdBuff = (((attacker.Statuses and attacker.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((attacker.Statuses and attacker.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local defSpdBuff = (((t.Statuses and t.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((t.Statuses and t.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local atkSpd = (attacker.TotalSpeed or 1) * atkSpdBuff
		local defSpd = (t.TotalSpeed or 1) * defSpdBuff

		if attacker.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "ODM Surge") then atkSpd *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Rainstorm") then atkSpd *= 0.85 end
			if attacker.Clan == "Ackerman" and attacker.Style == "Ultrahard Steel Blades" then atkSpd *= 1.3 end
		end
		if t.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "ODM Surge") then defSpd *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Rainstorm") then defSpd *= 0.85 end
			if t.Clan == "Ackerman" and t.Style == "Ultrahard Steel Blades" then defSpd *= 1.3 end
		end

		local dodgeChance = math.clamp(5 + (defSpd - atkSpd) * 0.2, 5, 50)
		dodgeChance = math.max(0, dodgeChance - ((attacker.TotalPrecision or 0) * 0.1))

		if t.Trait == "Swift" then dodgeChance += 10 end
		if t.Trait == "Evasive" then dodgeChance += 20 end
		if t.Trait == "Lucky" then dodgeChance += 5 end
		if t.Trait == "Blessed" then dodgeChance += 25 end

		local dodged = false
		if not isUnavoidable and (t.Statuses and t.Statuses.Stun or 0) == 0 and (t.Statuses and t.Statuses.Freeze or 0) == 0 and math.random(1, 100) <= dodgeChance then
			dodged = true
		end

		if dodged then
			if hitsToDo == 1 then return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>, but " .. tName .. " dodged!", false, "None"
			else table.insert(hitLogs, "<font color='#AAAAAA'>- Hit " .. i .. " missed!</font>") end
			continue
		end

		didHitAtAll = true
		local atkWillBuff = (((attacker.Statuses and attacker.Statuses.Buff_Willpower or 0) > 0) and 1.5 or 1.0) * (((attacker.Statuses and attacker.Statuses.Debuff_Willpower or 0) > 0) and 0.5 or 1.0)
		local atkWill = (attacker.TotalWillpower or 1) * atkWillBuff

		local critChance = math.clamp(5 + (atkWill * 0.5) + ((attacker.TotalPrecision or 0) * 0.2), 5, 75)
		if attacker.Trait == "Brutal" then critChance += 15 end
		if attacker.Trait == "Lucky" then critChance += 5 end
		if attacker.Trait == "Blessed" then critChance += 25 end

		local isCrit = math.random(1, 100) <= critChance
		local critMult = 1.5
		if attacker.Trait == "Lethal" then critMult += 1.5 end 
		if attacker.IsPlayer and CombatCore.HasModifier(uniModStr, "Ackerman Awakening") then critMult += 0.5 end

		local mult = skill.Mult * (isCrit and critMult or 1.0)
		if attacker.Trait == "Relentless" then mult *= 1.15 end

		if attacker.Trait == "Awakened" then mult *= 1.30 end
		if attacker.Trait == "Transcendent" then mult *= 1.50 end

		local isBlocking = (t.BlockTurns or 0) > 0
		local damage = CombatCore.CalculateDamage(attacker, t, mult, isBlocking, uniModStr)
		local survivalTriggered = CombatCore.TakeDamageWithWillpower(t, damage)

		if isCrit or survivalTriggered then overallShake = "Heavy" elseif isBlocking and overallShake == "None" then overallShake = "Light" elseif overallShake == "None" then overallShake = "Normal" end

		local hitMsg = hitsToDo == 1 and (msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and dealt " .. math.floor(damage) .. " damage to " .. tName .. "!") or ("- Hit " .. i .. " dealt " .. math.floor(damage) .. " damage")
		if isBlocking then hitMsg = hitMsg .. " <font color='#AAAAAA'>(Blocked)</font>" end
		if isCrit then hitMsg = hitMsg .. " <font color='#FFAA00'>(CRIT!)</font>" end
		if survivalTriggered then 
			if t.Trait == "Perseverance" then
				hitMsg = hitMsg .. " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED! (+25% HP)</font>"
			else
				hitMsg = hitMsg .. " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>"
			end
		end

		local postMsg = ""

		if attacker.Trait == "Bloodthirsty" and damage > 0 then
			local vHeal = damage * 0.20; attacker.HP = math.min(attacker.MaxHP, attacker.HP + vHeal)
			postMsg = postMsg .. " <font color='#AA00AA'>(Healed " .. math.floor(vHeal) .. ")</font>"
		end

		if damage > 0 and not isBlocking then
			if attacker.Trait == "Concussive" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Stun", 1, t, "#FFFF55", "Concussed")
			elseif attacker.Trait == "Crystalline" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Freeze", 1, t, "#00FFFF", "Crystallized")
			elseif attacker.Trait == "Incendiary" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Burn", 3, t, "#FF5500", "Scorched")
			elseif attacker.Trait == "Toxic" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Poison", 3, t, "#AA00AA", "Infected")
			elseif attacker.Trait == "Serrated" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Bleed", 3, t, "#FF0000", "Bled")
			elseif attacker.Trait == "Terrifying" and math.random(1, 100) <= 10 then postMsg = postMsg .. ApplyCC("Confusion", 1, t, "#FF55FF", "Terrified")
			elseif attacker.Trait == "Unpredictable" and math.random(1, 100) <= 10 then
				local pick = ({{ "Bleed", "#FF0000" }, { "Poison", "#AA00AA" }, { "Burn", "#FF5500" }, { "Confusion", "#FF55FF" }, { "Stun", "#FFFF55" }, { "Freeze", "#00FFFF" }})[math.random(1, 6)]
				postMsg = postMsg .. ApplyCC(pick[1], 2, t, pick[2], "Unpredictable: " .. pick[1])
			end
		end

		if skill.Effect == "Lifesteal" then
			local heal = damage * 0.5; attacker.HP = math.min(attacker.MaxHP, attacker.HP + heal)
			postMsg = postMsg .. " <font color='#55FF55'>(Lifesteal)</font>"
		end

		if not effectApplied then
			local eff = skill.Effect
			local statColors = { Stun = "#FFFF55", Freeze = "#00FFFF", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000", Confusion = "#FF55FF" }

			if statColors[eff] then
				postMsg = postMsg .. ApplyCC(eff, skill.Duration or 2, t, statColors[eff])
				effectApplied = true
			elseif eff == "Status_Random" then
				local effs = { {"Bleed", "#FF0000"}, {"Poison", "#AA00AA"}, {"Burn", "#FF5500"}, {"Confusion", "#FF55FF"}, {"Stun", "#FFFF55"}, {"Freeze", "#00FFFF"} }
				local pick = effs[math.random(1, #effs)]
				postMsg = postMsg .. ApplyCC(pick[1], skill.Duration or 2, t, pick[2])
				effectApplied = true
			end
		end

		if hitsToDo == 1 then msg = hitMsg .. postMsg else table.insert(hitLogs, hitMsg .. postMsg) end
	end

	if hitsToDo > 1 then
		if not didHitAtAll then msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>, but " .. tName .. " dodged completely!"
		else msg = msg .. "\n" .. table.concat(hitLogs, "\n") end
	end

	return msg, didHitAtAll, overallShake
end

return CombatCore