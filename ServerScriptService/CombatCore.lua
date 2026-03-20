-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatCore = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

function CombatCore.CalculateDamage(attacker, defender, skillMult, isDefenderBlocking)
	local atkBuff = (attacker.Statuses and (attacker.Statuses.Buff_Strength or 0) > 0) and 1.5 or 1.0
	local defBuff = (defender.Statuses and (defender.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0

	local baseDmg = (attacker.TotalStrength or 10) * atkBuff * skillMult

	if attacker.IsPlayer then
		if attacker.Clan == "Ackerman" and (attacker.Style == "Ultrahard Steel Blades" or attacker.Style == "Thunder Spears") then baseDmg *= 1.25 end
		if attacker.Clan == "Yeager" and attacker.Titan == "Attack Titan" then baseDmg *= 1.30 end
	end

	local effectiveArmor = (defender.TotalDefense or 10) * defBuff
	if defender.IsPlayer and defender.Clan == "Braun" then effectiveArmor *= 1.25 end

	local defenseMultiplier = 100 / (100 + math.max(0, effectiveArmor))
	local finalDmg = baseDmg * defenseMultiplier

	if isDefenderBlocking then finalDmg *= 0.5 end
	return math.max(1, finalDmg)
end

function CombatCore.TakeDamageWithWillpower(combatant, damage)
	if (combatant.HP - damage) < 1 then
		local defWill = (combatant.TotalWillpower or 10)
		local survivalChance = math.clamp(defWill * 0.7, 0, 45)
		if (combatant.WillpowerSurvivals or 0) < 1 and math.random(1, 100) <= survivalChance then
			combatant.HP = 1
			combatant.WillpowerSurvivals = (combatant.WillpowerSurvivals or 0) + 1
			return true 
		end
	end
	combatant.HP -= damage
	return false
end

function CombatCore.ExecuteStrike(attacker, defender, skillName, logName, defName, logColor, defColor)
	local skill = SkillData.Skills[skillName] or SkillData.Skills["Basic Slash"]
	local fLogName = "<font color='" .. (logColor or "#FFFFFF") .. "'>" .. logName .. "</font>"
	local fDefName = "<font color='" .. (defColor or "#FF5555") .. "'>" .. defName .. "</font>"

	if attacker.Cooldowns then attacker.Cooldowns[skillName] = skill.Cooldown or 0 end

	if skill.Effect == "Block" or skillName == "Maneuver" then
		attacker.BlockTurns = 2
		return fLogName .. " used <b>" .. skillName .. "</b>! " .. fLogName .. " maneuvers defensively, reducing incoming damage.", false, "None"
	elseif skill.Effect == "Rest" or skillName == "Recover" then
		local healAmount = (attacker.MaxHP or 100) * 0.15
		attacker.HP = math.min(attacker.MaxHP, attacker.HP + healAmount)
		return fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. fLogName .. " regroups, recovering " .. math.floor(healAmount) .. " HP.</font>", false, "None"
	end

	local hitsToDo = skill.Hits or 1
	local hitLogs = {}
	local didHitAtAll = false
	local overallShake = "None"

	for i = 1, hitsToDo do
		if defender.HP < 1 and i > 1 then break end 

		local atkSpd = (attacker.TotalSpeed or 10)
		local defSpd = (defender.TotalSpeed or 10)
		local dodgeChance = math.clamp(5 + (defSpd - atkSpd) * 0.2, 5, 50)

		if math.random(1, 100) <= dodgeChance then
			if hitsToDo == 1 then 
				table.insert(hitLogs, fLogName .. " used <b>" .. skillName .. "</b>, but " .. fDefName .. " dodged!")
			else 
				table.insert(hitLogs, "<font color='#AAAAAA'>- Hit " .. i .. " missed!</font>") 
			end
			continue
		end

		didHitAtAll = true
		local isCrit = math.random(1, 100) <= math.clamp(5 + ((attacker.TotalWillpower or 10) * 0.5), 5, 75)
		local mult = skill.Mult * (isCrit and 1.5 or 1.0)
		local isBlocking = (defender.BlockTurns or 0) > 0

		local damage = CombatCore.CalculateDamage(attacker, defender, mult, isBlocking)
		local survivalTriggered = CombatCore.TakeDamageWithWillpower(defender, damage)

		if isCrit or survivalTriggered then overallShake = "Heavy" elseif overallShake == "None" then overallShake = "Normal" end

		local hitMsg = hitsToDo == 1 and (fLogName .. " used <b>" .. skillName .. "</b> and dealt " .. math.floor(damage) .. " damage to " .. fDefName .. "!") or ("- Hit " .. i .. " dealt " .. math.floor(damage) .. " damage")
		if isBlocking then hitMsg = hitMsg .. " <font color='#AAAAAA'>(Maneuvered)</font>" end
		if isCrit then hitMsg = hitMsg .. " <font color='#FFAA00'>(CRIT!)</font>" end
		if survivalTriggered then hitMsg = hitMsg .. " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>" end

		-- THE FIX: ALWAYS insert the message so it doesn't get deleted
		table.insert(hitLogs, hitMsg)
	end

	local finalMsg = ""
	if hitsToDo > 1 then
		if not didHitAtAll then finalMsg = fLogName .. " used <b>" .. skillName .. "</b>, but " .. fDefName .. " dodged completely!"
		else finalMsg = fLogName .. " used <b>" .. skillName .. "</b>!\n" .. table.concat(hitLogs, "\n") end
	else
		finalMsg = hitLogs[1] or ""
	end

	return finalMsg, didHitAtAll, overallShake
end

return CombatCore