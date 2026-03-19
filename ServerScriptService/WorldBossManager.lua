-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local WorldBossUpdate = Network:WaitForChild("WorldBossUpdate")
local WorldBossAction = Network:WaitForChild("WorldBossAction")
local AdminForceSpawn = Network:FindFirstChild("AdminForceSpawnWB") or Instance.new("BindableEvent", Network)
AdminForceSpawn.Name = "AdminForceSpawnWB"

local ActiveWorldBoss = nil
local BossState = nil
local Participants = {} 
local TotalDamageDealt = 0

local SPAWN_INTERVAL_HOURS = 4

local function BuildBossStruct(bossKey)
	local template = EnemyData.WorldBosses[bossKey]
	if not template then return nil end

	return {
		IsPlayer = false, Name = template.Name, Trait = "None", IsBoss = true,
		HP = template.Health, MaxHP = template.Health,
		TotalStrength = template.Strength, TotalDefense = template.Defense, TotalSpeed = template.Speed,
		TotalWillpower = template.Willpower, TotalPrecision = (GameData.TitanRanks[template.TitanStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0 },
		Cooldowns = {}, Skills = template.Skills or {"Basic Slash"},
		Drops = template.Drops
	}
end

local function BuildPlayerStruct(player)
	local pHP = (player:GetAttribute("Health") or 1) * 10
	local pStr = player:GetAttribute("Strength") or 1
	local pDef = player:GetAttribute("Defense") or 1
	local pSpd = player:GetAttribute("Speed") or 1
	local pWill = player:GetAttribute("Willpower") or 1

	local tPow = (player:GetAttribute("Titan_Power_Val") or 0)
	local tDur = (player:GetAttribute("Titan_Hardening_Val") or 0)
	local tSpd = (player:GetAttribute("Titan_Speed_Val") or 0)
	local tPre = (player:GetAttribute("Titan_Precision_Val") or 0)

	pStr += tPow + CombatCore.GetEquipBonus(player, "Strength") + CombatCore.GetEquipBonus(player, "Titan_Power")
	pDef += tDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Titan_Hardening")
	pSpd += tSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Titan_Speed")
	pWill += CombatCore.GetEquipBonus(player, "Willpower")

	local clan = player:GetAttribute("Clan") or "None"
	if clan == "Ackerman" then pStr *= 1.15; pSpd *= 1.15
	elseif clan == "Yeager" then pWill *= 1.25; pStr *= 1.05
	elseif clan == "Tybur" then pDef *= 1.15; tDur += 10
	elseif clan == "Reiss" then pHP *= 1.20
	elseif clan == "Braun" then pDef *= 1.25 end

	return {
		IsPlayer = true, Player = player, Name = player.Name, UserId = player.UserId,
		Titan = player:GetAttribute("Titan") or "None", Style = player:GetAttribute("FightingStyle") or "None", Clan = clan, Trait = player:GetAttribute("TitanTrait") or "None",
		HP = pHP, MaxHP = pHP, TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd, TotalWillpower = pWill, TotalPrecision = tPre,
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0 },
		Cooldowns = {}, DamageDealt = 0
	}
end

local function EndWorldBoss(success)
	if not ActiveWorldBoss then return end
	ActiveWorldBoss = nil

	local sortedParticipants = {}
	for _, pData in pairs(Participants) do table.insert(sortedParticipants, pData) end
	table.sort(sortedParticipants, function(a,b) return a.DamageDealt > b.DamageDealt end)

	if success then
		local logMsg = "<font color='#55FF55'>The World Boss has been defeated!</font>\nTop Contributors:\n"
		for i = 1, math.min(3, #sortedParticipants) do logMsg = logMsg .. i .. ". " .. sortedParticipants[i].Name .. " (" .. sortedParticipants[i].DamageDealt .. " Dmg)\n" end

		local drops = BossState.Drops
		for rank, pData in ipairs(sortedParticipants) do
			if pData.Player and pData.Player.Parent then
				local pBoosts = CombatCore.GetPlayerBoosts(pData.Player)
				local rankMult = rank <= 3 and 1.5 or (rank <= 10 and 1.2 or 1.0)
				local fXP = math.floor(drops.XP * pBoosts.XP * rankMult)
				local fYen = math.floor(drops.Yen * pBoosts.Dews * rankMult)

				pData.Player:SetAttribute("XP", (pData.Player:GetAttribute("XP") or 0) + fXP)
				pData.Player.leaderstats.Yen.Value += fYen

				local itemLogs = {}
				for itemName, chance in pairs(drops.ItemChance) do
					local realChance = chance * rankMult
					if math.random(1, 100) <= realChance then
						local attrName = itemName:gsub("[^%w]", "") .. "Count"
						pData.Player:SetAttribute(attrName, (pData.Player:GetAttribute(attrName) or 0) + 1)
						table.insert(itemLogs, itemName)
					end
				end

				local pLog = logMsg .. "\n<font color='#55FF55'>Rewards: +" .. fXP .. " XP, +" .. fYen .. " Dews</font>"
				if #itemLogs > 0 then pLog = pLog .. "\n<font color='#FFFF55'>Loot: " .. table.concat(itemLogs, ", ") .. "</font>" end

				WorldBossUpdate:FireClient(pData.Player, "BossDefeated", pLog)
			end
		end
	else
		WorldBossUpdate:FireAllClients("BossEscaped", "<font color='#FF5555'>The World Boss has retreated!</font>")
	end

	BossState = nil
	Participants = {}
end

local function SpawnWorldBoss(bossKey)
	if ActiveWorldBoss then return end

	local keys = {}
	for k, _ in pairs(EnemyData.WorldBosses) do table.insert(keys, k) end
	local chosenKey = bossKey or keys[math.random(1, #keys)]

	BossState = BuildBossStruct(chosenKey)
	if not BossState then return end

	ActiveWorldBoss = chosenKey
	Participants = {}
	TotalDamageDealt = 0

	local announceMsg = "\n<font color='#FF0000' size='18'><b>[GLOBAL THREAT DETECTED]</b></font>\n"
	announceMsg = announceMsg .. "<font color='#FFFFFF'>A massive threat has appeared: <b>" .. BossState.Name .. "</b>!</font>\n"
	announceMsg = announceMsg .. "<font color='#AAAAAA'>Join forces to repel the invasion!</font>\n"

	for _, p in ipairs(game.Players:GetPlayers()) do
		Network:WaitForChild("NotificationEvent"):FireClient(p, announceMsg)
		WorldBossUpdate:FireClient(p, "BossSpawned", { Name = BossState.Name, HP = BossState.HP, MaxHP = BossState.MaxHP })
	end

	-- Boss escapes after 30 minutes
	task.delay(1800, function()
		if ActiveWorldBoss == chosenKey then EndWorldBoss(false) end
	end)
end

AdminForceSpawn.Event:Connect(function(bossKey) SpawnWorldBoss(bossKey) end)

WorldBossAction.OnServerEvent:Connect(function(player, action, data)
	if action == "Attack" and ActiveWorldBoss and BossState then
		local pData = Participants[player.UserId]
		if not pData then
			pData = BuildPlayerStruct(player)
			Participants[player.UserId] = pData
		end

		if os.time() - (pData.LastAttack or 0) < 3 then return end
		pData.LastAttack = os.time()

		local s, msg, hit, shake = pcall(function() return CombatCore.ExecuteStrike(pData, BossState, data, "None", pData.Name, BossState.Name, "#55FF55", "#FF5555") end)

		if s and hit then
			local dmgDealt = math.floor(CombatCore.CalculateDamage(pData, BossState, SkillData.Skills[data].Mult or 1.0, false, "None"))
			pData.DamageDealt += dmgDealt
			TotalDamageDealt += dmgDealt
			WorldBossUpdate:FireAllClients("UpdateHP", { HP = BossState.HP, MaxHP = BossState.MaxHP })
			WorldBossUpdate:FireClient(player, "HitConfirm", {Log = msg, Shake = shake})

			if BossState.HP <= 0 then EndWorldBoss(true) end
		end
	end
end)