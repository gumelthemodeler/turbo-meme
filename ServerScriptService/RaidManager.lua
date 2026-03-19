-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local Network = ReplicatedStorage:WaitForChild("Network")
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local RaidAction = Network:WaitForChild("RaidAction")
local RaidUpdate = Network:WaitForChild("RaidUpdate")

local OpenRaidLobbies = {}
local ActiveRaids = {}
local RaidRegistry = {}

local function GetLobbiesForRaid(raidId)
	local list = {}
	for hostId, data in pairs(OpenRaidLobbies) do
		if data.RaidId == raidId then
			local memberNames = {}
			for _, p in ipairs(data.Queue) do table.insert(memberNames, p.Name) end
			table.insert(list, {
				HostId = hostId, HostName = data.Host.Name,
				FriendsOnly = data.FriendsOnly, PlayerCount = #data.Queue, Members = memberNames
			})
		end
	end
	return list
end

local function BuildPlayerStruct(player)
	local playerTrait = player:GetAttribute("TitanTrait") or "None"
	local hasTitan = (player:GetAttribute("Titan") or "None") ~= "None"

	local tPow = hasTitan and (player:GetAttribute("Titan_Power_Val") or 0) or 0
	local tDur = hasTitan and (player:GetAttribute("Titan_Hardening_Val") or 0) or 0
	local tSpd = hasTitan and (player:GetAttribute("Titan_Speed_Val") or 0) or 0
	local tPot = hasTitan and (player:GetAttribute("Titan_Potential_Val") or 0) or 0
	local tPre = hasTitan and (player:GetAttribute("Titan_Precision_Val") or 0) or 0

	local pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
	local pStr = (player:GetAttribute("Strength") or 1) + tPow + CombatCore.GetEquipBonus(player, "Strength") + CombatCore.GetEquipBonus(player, "Titan_Power")
	local pDef = (player:GetAttribute("Defense") or 1) + tDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Titan_Hardening")
	local pSpd = (player:GetAttribute("Speed") or 1) + tSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Titan_Speed")
	local pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")

	if playerTrait == "Tough" then pHP *= 1.1 end
	if playerTrait == "Fierce" then pStr *= 1.1 end
	if playerTrait == "Perseverance" then pHP *= 1.5; pWill *= 1.5 end

	local pStamina = (player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina")
	local pTitanEnergy = 10 + tPot + CombatCore.GetEquipBonus(player, "Titan_Potential")

	if playerTrait == "Focused" then pStamina *= 1.1; pTitanEnergy *= 1.1 end

	local clan = player:GetAttribute("Clan") or "None"
	if clan == "Ackerman" then pStr *= 1.15; pSpd *= 1.15
	elseif clan == "Yeager" then pWill *= 1.25; pStr *= 1.05
	elseif clan == "Tybur" then pDef *= 1.15; tDur += 10
	elseif clan == "Arlert" then pTitanEnergy *= 1.25
	elseif clan == "Reiss" then pHP *= 1.20
	elseif clan == "Braun" then pDef *= 1.25
	elseif clan == "Galliard" then pSpd *= 1.20 end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	local eloDmgBoost = elo >= 5000 and 1.05 or 1.0

	return {
		IsPlayer = true, Player = player, PlayerObj = player, UserId = player.UserId, Name = player.Name,
		Trait = playerTrait, GlobalDmgBoost = eloDmgBoost,
		Titan = player:GetAttribute("Titan") or "None", Style = player:GetAttribute("FightingStyle") or "None", Clan = clan,
		HP = pHP * 10, MaxHP = pHP * 10, Stamina = pStamina, MaxStamina = pStamina, TitanEnergy = pTitanEnergy, MaxTitanEnergy = pTitanEnergy,
		TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd, TotalWillpower = pWill,
		TotalPrecision = tPre + CombatCore.GetEquipBonus(player, "Titan_Precision"),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {}, SelectedSkill = nil
	}
end

local function GenerateRaidBoss(raidId)
	local bossTemplate = EnemyData.RaidBosses[raidId]
	if not bossTemplate then return nil end

	local scaleMult = 1.0 
	return {
		IsPlayer = false, Name = bossTemplate.Name, Trait = "None", IsBoss = true,
		HP = bossTemplate.Health, MaxHP = bossTemplate.Health,
		TotalStrength = bossTemplate.Strength, TotalDefense = bossTemplate.Defense, TotalSpeed = bossTemplate.Speed,
		TotalWillpower = bossTemplate.Willpower, TotalPrecision = (GameData.TitanRanks[bossTemplate.TitanStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {}, Skills = bossTemplate.Skills or {"Basic Slash"},
		RawDrops = bossTemplate.Drops
	}
end

local function GetClientState(raid, requestingPlayer)
	local state = { Party = {}, Boss = nil, MyId = requestingPlayer.UserId, RaidId = raid.Id }

	for _, p in ipairs(raid.Party) do
		table.insert(state.Party, { UserId = p.UserId, Name = p.Name, HP = p.HP, MaxHP = p.MaxHP, Stamina = p.Stamina, TitanEnergy = p.TitanEnergy, Cooldowns = p.Cooldowns, BlockTurns = p.BlockTurns, StunImmunity = p.StunImmunity, ConfusionImmunity = p.ConfusionImmunity, Titan = p.Titan, Style = p.Style, Clan = p.Clan, Statuses = p.Statuses })
	end

	local b = raid.Boss
	state.Boss = { Name = b.Name, HP = b.HP, MaxHP = b.MaxHP, StunImmunity = b.StunImmunity, ConfusionImmunity = b.ConfusionImmunity, Statuses = b.Statuses }

	return state
end

local function ProcessRaidTurn(raid)
	raid.IsProcessing = true
	local logMessages = {}
	local allCombatants = {raid.Boss}
	for _, p in ipairs(raid.Party) do table.insert(allCombatants, p) end

	table.sort(allCombatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	local didHit, shakeType = false, "None"
	local partyDead = true

	for _, attacker in ipairs(allCombatants) do
		if raid.Boss.HP < 1 then break end

		partyDead = true
		for _, p in ipairs(raid.Party) do if p.HP > 0 then partyDead = false; break end end
		if partyDead then break end
		if attacker.HP < 1 then continue end

		if attacker.StunImmunity and attacker.StunImmunity > 0 then attacker.StunImmunity -= 1 end
		if attacker.ConfusionImmunity and attacker.ConfusionImmunity > 0 then attacker.ConfusionImmunity -= 1 end

		local freezeResult = CombatCore.ApplyStatusDamage(attacker, "None", RaidUpdate, raid.Party[1].Player, raid, 0)
		if freezeResult == "Frozen" then continue end
		if attacker.HP < 1 then continue end

		if attacker.Statuses.Stun > 0 then
			attacker.Statuses.Stun -= 1
			table.insert(logMessages, "<font color='#AAAAAA'>"..attacker.Name.." is Stunned and skips their turn!</font>")
			if attacker.IsPlayer then
				attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + 5)
				attacker.TitanEnergy = math.min(attacker.MaxTitanEnergy, attacker.TitanEnergy + 5)
				attacker.SelectedSkill = nil 
			end
			continue
		end

		if attacker.IsPlayer then
			local skillName = attacker.SelectedSkill
			local skill = SkillData.Skills[skillName]
			if skill and (skillName == "Retreat" or skill.Effect == "Flee") then 
				attacker.HP = 0; table.insert(logMessages, "<font color='#FF5555'>"..attacker.Name.." fired a smoke signal and retreated!</font>"); continue 
			end

			local s, msg, hit, shake = pcall(function() return CombatCore.ExecuteStrike(attacker, raid.Boss, skillName, "None", attacker.Name, raid.Boss.Name, "#55FF55", "#FF5555") end)
			if s then
				table.insert(logMessages, msg)
				if hit then didHit = true end
				if shake == "Heavy" then shakeType = "Heavy" elseif shake == "Light" and shakeType == "None" then shakeType = "Light" end
			end
		else
			local aliveTargets = {}
			for _, p in ipairs(raid.Party) do if p.HP > 0 then table.insert(aliveTargets, p) end end
			if #aliveTargets > 0 then
				local target = aliveTargets[math.random(1, #aliveTargets)]
				local eSkill = CombatCore.ChooseAISkill(attacker)
				local s, msg, hit, shake = pcall(function() return CombatCore.ExecuteStrike(attacker, target, eSkill, "None", attacker.Name, target.Name, "#FF5555", "#FFFFFF") end)
				if s then
					table.insert(logMessages, msg)
					if hit then didHit = true end
					if shake == "Heavy" then shakeType = "Heavy" elseif shake == "Light" and shakeType == "None" then shakeType = "Light" end
				end
			end
		end

		if attacker.Statuses.Confusion > 0 then attacker.Statuses.Confusion -= 1 end
	end

	for _, combatant in ipairs(allCombatants) do
		if combatant.HP < 1 then continue end
		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		if combatant.Statuses then for sName, sVal in pairs(combatant.Statuses) do if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end end end
		if combatant.BlockTurns > 0 then combatant.BlockTurns -= 1 end

		if combatant.IsPlayer then
			local sk = SkillData.Skills[combatant.SelectedSkill]
			if sk then
				if sk.StaminaCost == 0 then combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5) end
				if sk.EnergyCost == 0 then combatant.TitanEnergy = math.min(combatant.MaxTitanEnergy, combatant.TitanEnergy + 5) end
			end
			combatant.SelectedSkill = nil
		end
	end

	local logStr = table.concat(logMessages, "\n")

	if raid.Boss.HP < 1 or partyDead then
		local result = raid.Boss.HP < 1 and "Win" or "Loss"
		local fMsg = result == "Win" and "<font color='#55FF55'>The Raid Boss was defeated!</font>" or "<font color='#FF5555'>The party was wiped out...</font>"

		if result == "Win" then
			local drops = raid.Boss.RawDrops
			for _, pData in ipairs(raid.Party) do
				local pBoosts = CombatCore.GetPlayerBoosts(pData.Player)
				local fXP = math.floor(drops.XP * pBoosts.XP)
				local fYen = math.floor(drops.Yen * pBoosts.Dews)

				pData.Player:SetAttribute("XP", (pData.Player:GetAttribute("XP") or 0) + fXP)
				pData.Player.leaderstats.Yen.Value += fYen
				pData.Player:SetAttribute("RaidWins", (pData.Player:GetAttribute("RaidWins") or 0) + 1)

				local droppedItems = {}
				local dropMultiplier = pData.Player:GetAttribute("Has2xDropChance") and 2 or 1
				for itemName, chance in pairs(drops.ItemChance) do
					if math.random(1, 100) <= ((chance + pBoosts.Luck) * dropMultiplier) then
						local attrName = itemName:gsub("[^%w]", "") .. "Count"
						pData.Player:SetAttribute(attrName, (pData.Player:GetAttribute(attrName) or 0) + 1)
						table.insert(droppedItems, itemName)
					end
				end

				local clanEvent = Network:FindFirstChild("AddClanOrderProgress")
				if clanEvent then clanEvent:Fire(pData.Clan, "Raids", 1) end

				local lootStr = #droppedItems > 0 and ("\n<font color='#FFFF55'>Loot: " .. table.concat(droppedItems, ", ") .. "</font>") or ""
				RaidUpdate:FireClient(pData.Player, "MatchOver", {Result = "Win", LogMsg = logStr .. "\n\n" .. fMsg .. "\n<font color='#55FF55'>+"..fXP.." XP, +"..fYen.." Dews</font>" .. lootStr})
				ActiveRaids[pData.Player] = nil
			end
		else
			for _, pData in ipairs(raid.Party) do
				RaidUpdate:FireClient(pData.Player, "MatchOver", {Result = "Loss", LogMsg = logStr .. "\n\n" .. fMsg})
				ActiveRaids[pData.Player] = nil
			end
		end
		RaidRegistry[raid.Id] = nil
	else
		raid.IsProcessing = false
		raid.TurnDeadline = os.time() + 20

		for _, pData in ipairs(raid.Party) do
			RaidUpdate:FireClient(pData.Player, "TurnResult", {LogMsg = logStr, State = GetClientState(raid, pData.Player), DidHit = didHit, ShakeType = shakeType, Deadline = raid.TurnDeadline})
			if pData.HP > 0 and pData.Statuses.Stun > 0 then pData.SelectedSkill = "Stunned" end
		end

		local allReady = true
		for _, p in ipairs(raid.Party) do if p.HP > 0 and not p.SelectedSkill then allReady = false; break end end
		if allReady then task.defer(function() ProcessRaidTurn(raid) end) end
	end
end

local function StartRaidGame(hostId)
	local lobby = OpenRaidLobbies[hostId]
	if not lobby then return end

	local party = {}
	for _, p in ipairs(lobby.Queue) do table.insert(party, BuildPlayerStruct(p)) end

	local boss = GenerateRaidBoss(lobby.RaidId)
	local raidId = HttpService:GenerateGUID(false)

	local raid = { Id = raidId, Boss = boss, Party = party, IsProcessing = false, TurnDeadline = os.time() + 20 }
	RaidRegistry[raidId] = raid

	for _, pData in ipairs(party) do ActiveRaids[pData.Player] = raid end

	for _, pData in ipairs(party) do 
		RaidUpdate:FireClient(pData.Player, "MatchStart", { State = GetClientState(raid, pData.Player), LogMsg = "The Raid Boss descends!", Deadline = raid.TurnDeadline }) 
	end

	OpenRaidLobbies[hostId] = nil
	RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = lobby.RaidId, Lobbies = GetLobbiesForRaid(lobby.RaidId)})
end

task.spawn(function()
	while task.wait(1) do
		for _, raid in pairs(RaidRegistry) do
			if not raid.IsProcessing and raid.TurnDeadline and os.time() >= raid.TurnDeadline then
				for _, p in ipairs(raid.Party) do if p.HP > 0 and not p.SelectedSkill then p.SelectedSkill = "Basic Slash" end end
				task.defer(function() ProcessRaidTurn(raid) end)
			end
		end
	end
end)

RaidAction.OnServerEvent:Connect(function(player, action, data)
	if action == "RequestLobbies" then
		RaidUpdate:FireClient(player, "LobbiesUpdate", {RaidId = data, Lobbies = GetLobbiesForRaid(data)})
	elseif action == "CreateLobby" then
		if ActiveRaids[player] or OpenRaidLobbies[player.UserId] then return end
		OpenRaidLobbies[player.UserId] = { Host = player, RaidId = data.RaidId, Queue = {player}, FriendsOnly = data.FriendsOnly }
		RaidUpdate:FireClient(player, "LobbyStatus", {IsHosting = true, IsLobbyOwner = true, PlayerCount = 1})
		RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = data.RaidId, Lobbies = GetLobbiesForRaid(data.RaidId)})
	elseif action == "JoinLobby" then
		if ActiveRaids[player] then return end
		local lobby = OpenRaidLobbies[data.HostId]
		if not lobby then return end
		if #lobby.Queue >= 4 then return end
		if lobby.FriendsOnly then
			local success, isFriend = pcall(function() return player:IsFriendsWith(data.HostId) end)
			if not success or not isFriend then return end
		end
		for _, qp in ipairs(lobby.Queue) do if qp == player then return end end

		table.insert(lobby.Queue, player)

		if #lobby.Queue == 4 then
			StartRaidGame(data.HostId)
		else
			for _, qp in ipairs(lobby.Queue) do RaidUpdate:FireClient(qp, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (qp.UserId == data.HostId), PlayerCount = #lobby.Queue}) end
			RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = lobby.RaidId, Lobbies = GetLobbiesForRaid(lobby.RaidId)})
		end
	elseif action == "CancelLobby" then
		if OpenRaidLobbies[player.UserId] then
			local raidId = OpenRaidLobbies[player.UserId].RaidId
			for _, qp in ipairs(OpenRaidLobbies[player.UserId].Queue) do RaidUpdate:FireClient(qp, "LobbyStatus", {IsHosting = false}) end
			OpenRaidLobbies[player.UserId] = nil
			RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = raidId, Lobbies = GetLobbiesForRaid(raidId)})
		else
			for hostId, lobby in pairs(OpenRaidLobbies) do
				local found = false
				for i, qp in ipairs(lobby.Queue) do if qp == player then table.remove(lobby.Queue, i); found = true; break end end
				if found then
					RaidUpdate:FireClient(player, "LobbyStatus", {IsHosting = false})
					for _, qp in ipairs(lobby.Queue) do RaidUpdate:FireClient(qp, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (qp.UserId == hostId), PlayerCount = #lobby.Queue}) end
					RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = lobby.RaidId, Lobbies = GetLobbiesForRaid(lobby.RaidId)})
					break
				end
			end
		end
	elseif action == "ForceStartRaid" then
		if OpenRaidLobbies[player.UserId] then StartRaidGame(player.UserId) end
	elseif action == "Attack" then
		local raid = ActiveRaids[player]
		if not raid or raid.IsProcessing then return end

		local combatant = nil
		for _, p in ipairs(raid.Party) do if p.Player == player then combatant = p break end end
		if not combatant then return end

		local skill = SkillData.Skills[data]
		if skill and skill.Requirement ~= "None" then
			if skill.Requirement == "AnyTitan" then if combatant.Titan == "None" then return end
			elseif skill.Requirement ~= combatant.Titan and skill.Requirement ~= combatant.Style then return end
		end

		if not skill or combatant.Stamina < (skill.StaminaCost or 0) or combatant.TitanEnergy < (skill.EnergyCost or 0) or (combatant.Cooldowns[data] and combatant.Cooldowns[data] > 0) then return end

		combatant.SelectedSkill = data
		RaidUpdate:FireClient(player, "Waiting")

		local allReady = true
		for _, p in ipairs(raid.Party) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
		if allReady then ProcessRaidTurn(raid) end
	end
end)