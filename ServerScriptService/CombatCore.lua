-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatCore = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

function CombatCore.CalculateDamage(attacker, defender, skillMult)
	local atkBuff = (attacker.Statuses and (attacker.Statuses.Buff_Strength or 0) > 0) and 1.5 or 1.0
	local defBuff = (defender.Statuses and (defender.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0

	local baseDmg = (attacker.TotalStrength or 10) * atkBuff * skillMult

	if attacker.IsPlayer then
		baseDmg *= 4.0 
		if attacker.Clan == "Ackerman" or attacker.Clan == "Awakened Ackerman" then baseDmg *= 1.25 end
		if attacker.Clan == "Yeager" and (attacker.Titan == "Attack Titan" or attacker.Titan == "Founding Titan") then baseDmg *= 1.30 end
	else
		baseDmg *= 0.5
	end

	local effectiveArmor = (defender.TotalDefense or 10) * defBuff
	if defender.IsPlayer and defender.Clan == "Braun" then effectiveArmor *= 1.25 end

	local defenseMultiplier = 1.0
	if defender.IsPlayer then
		defenseMultiplier = 150 / (150 + (effectiveArmor * 4))
	else
		defenseMultiplier = 200 / (200 + effectiveArmor)
	end

	local finalDmg = baseDmg * defenseMultiplier

	return math.max(1, finalDmg)
end

function CombatCore.TakeDamage(combatant, damage, attackerStyle)
	local actualDmg = damage
	local hitGate = false
	local gateBroken = false
	local gateName = combatant.GateType or "Shield"

	if combatant.GateHP and combatant.GateHP > 0 then
		hitGate = true
		if combatant.GateType == "Steam" then
			actualDmg = 0 
		else
			if combatant.GateType == "Reinforced Skin" and attackerStyle == "Thunder Spears" then
				damage *= 3.0
			end

			if damage >= combatant.GateHP then
				actualDmg = damage - combatant.GateHP
				combatant.GateHP = 0
				gateBroken = true
			else
				combatant.GateHP = combatant.GateHP - damage
				actualDmg = 0
			end
		end
	end

	local survivalTriggered = false
	if actualDmg > 0 then
		if (combatant.HP - actualDmg) < 1 then

			local survivalChance = math.clamp((combatant.TotalResolve or 10) * 0.7, 0, 45)
			local maxSurvivals = 1

			if combatant.IsPlayer and (combatant.Clan == "Ackerman" or combatant.Clan == "Awakened Ackerman") then
				survivalChance = 100
				maxSurvivals = 3
			end

			if (combatant.ResolveSurvivals or 0) < maxSurvivals and math.random(1, 100) <= survivalChance then
				combatant.HP = 1
				combatant.ResolveSurvivals = (combatant.ResolveSurvivals or 0) + 1
				survivalTriggered = true 
			else
				combatant.HP = combatant.HP - actualDmg
			end
		else
			combatant.HP = combatant.HP - actualDmg
		end
	end

	return survivalTriggered, hitGate, gateBroken, actualDmg, gateName
end

function CombatCore.ExecuteStrike(attacker, defender, skillName, logName, defName, logColor, defColor)
	local fallbackSkill = { Mult = 1.0, Cooldown = 0, Hits = 1, Effect = "None", Description = "A basic attack." }
	local skill = SkillData.Skills[skillName] or SkillData.Skills["Brutal Swipe"] or fallbackSkill

	local fLogName = "<font color='" .. (logColor or "#FFFFFF") .. "'>" .. logName .. "</font>"
	local fDefName = "<font color='" .. (defColor or "#FF5555") .. "'>" .. defName .. "</font>"

	if attacker.Cooldowns then attacker.Cooldowns[skillName] = skill.Cooldown or 0 end

	if skillName == "Maneuver" and defender.GateType == "Steam" and (defender.GateHP or 0) > 0 then
		if attacker.Cooldowns then attacker.Cooldowns[skillName] = 0 end
	end

	local isSequenceCombo = false
	local comboMult = 1.0
	if skill.ComboReq and attacker.LastSkill == skill.ComboReq then
		isSequenceCombo = true
		comboMult = skill.ComboMult or 1.5
	end

	if skill.Effect == "Block" or skillName == "Maneuver" then
		if not attacker.Statuses then attacker.Statuses = {} end
		attacker.Statuses["Dodge"] = 1
		attacker.LastSkill = skillName 
		return fLogName .. " used <b>" .. skillName .. "</b>! " .. fLogName .. " maneuvers rapidly, dodging the next attack.", false, "None"
	elseif skill.Effect == "Rest" or skillName == "Recover" then
		local healAmount = (attacker.MaxHP or 100) * 0.30
		attacker.HP = math.min(attacker.MaxHP, attacker.HP + healAmount)
		attacker.LastSkill = skillName

		-- THE FIX: "You regroup" vs "The Titan regroups"
		local regroupWord = attacker.IsPlayer and "regroup" or "regroups"
		return fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. fLogName .. " " .. regroupWord .. ", recovering HP and Gas.</font>", false, "None"

	elseif skill.Effect == "Transform" then
		if not attacker.Statuses then attacker.Statuses = {} end
		attacker.Statuses["Transformed"] = 999
		attacker.LastSkill = skillName
		return fLogName .. " used <b>" .. skillName .. "</b>! Lightning strikes as " .. fLogName .. " shifts into a Titan!", false, "Heavy"
	elseif skill.Effect == "Eject" then
		if attacker.Statuses then attacker.Statuses["Transformed"] = nil end
		attacker.LastSkill = skillName
		return fLogName .. " used <b>" .. skillName .. "</b>! " .. fLogName .. " cuts themselves out of the nape, returning to human form.", false, "None"
	elseif skill.Effect == "TitanRest" or skillName == "Titan Recover" then
		local healAmount = (attacker.MaxHP or 100) * 0.60
		attacker.HP = math.min(attacker.MaxHP, attacker.HP + healAmount)
		attacker.LastSkill = skillName
		return fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. fLogName .. " uses immense steam to regenerate " .. math.floor(healAmount) .. " HP.</font>", false, "None"
	end

	local hitsToDo = skill.Hits or 1
	local hitLogs = {}
	local didHitAtAll = false
	local overallShake = "None"
	local synergyTag = isSequenceCombo and " <font color='#FFD700'>[SYNERGY: " .. attacker.LastSkill .. " -> " .. skillName .. "]</font>" or ""

	for i = 1, hitsToDo do
		if defender.HP < 1 and i > 1 then break end 

		local isDodging = defender.Statuses and defender.Statuses.Dodge and defender.Statuses.Dodge > 0
		local atkSpd = (attacker.TotalSpeed or 10)
		local defSpd = (defender.TotalSpeed or 10)
		local dodgeChance = math.clamp(5 + (defSpd - atkSpd) * 0.2, 5, 50)

		if isDodging then dodgeChance = 100 end

		if math.random(1, 100) <= dodgeChance then
			if hitsToDo == 1 then 
				local dodgeMsg = isDodging and " (Maneuvered)" or ""
				table.insert(hitLogs, fLogName .. " used <b>" .. skillName .. "</b>, but " .. fDefName .. " dodged!" .. dodgeMsg)
			else 
				table.insert(hitLogs, "<font color='#AAAAAA'>- Hit " .. i .. " missed!</font>") 
			end
			continue
		end

		didHitAtAll = true
		local isCrit = math.random(1, 100) <= math.clamp(5 + ((attacker.TotalResolve or 10) * 0.5), 5, 75)
		local mult = skill.Mult * (isCrit and 1.5 or 1.0) * comboMult
		local baseDmg = CombatCore.CalculateDamage(attacker, defender, mult)

		local survivalTriggered, hitGate, gateBroken, hpDmg, gateName = CombatCore.TakeDamage(defender, baseDmg, attacker.Style)

		if isCrit or survivalTriggered then overallShake = "Heavy" elseif overallShake == "None" then overallShake = "Normal" end

		local hitMsg = hitsToDo == 1 and (fLogName .. " used <b>" .. skillName .. "</b>" .. synergyTag .. " and dealt " .. math.floor(baseDmg) .. " damage to " .. fDefName .. "!") or ("- Hit " .. i .. " dealt " .. math.floor(baseDmg) .. " damage")

		if isCrit then hitMsg = hitMsg .. " <font color='#FFAA00'>(CRIT!)</font>" end
		if defender.GateType == "Steam" and hitGate then hitMsg = hitMsg .. " <font color='#FFAAAA'>(Repelled by Steam!)</font>"
		elseif hitGate then hitMsg = hitMsg .. " <font color='#DDDDDD'>[Hit " .. gateName .. "!]</font>" end

		if gateBroken then hitMsg = hitMsg .. " <font color='#FFFFFF'><b>[" .. gateName:upper() .. " SHATTERED!]</b></font>" end
		if survivalTriggered then hitMsg = hitMsg .. " <font color='#FF55FF'>...TATAKAE! (Refused to yield!)</font>" end

		table.insert(hitLogs, hitMsg)
	end

	local finalMsg = ""
	if hitsToDo > 1 then
		if not didHitAtAll then finalMsg = fLogName .. " used <b>" .. skillName .. "</b>, but " .. fDefName .. " dodged completely!"
		else finalMsg = fLogName .. " used <b>" .. skillName .. "</b>!" .. synergyTag .. "\n" .. table.concat(hitLogs, "\n") end
	else
		finalMsg = hitLogs[1] or ""
	end

	attacker.LastSkill = skillName
	return finalMsg, didHitAtAll, overallShake
end

return CombatCore