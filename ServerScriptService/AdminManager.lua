-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Network = ReplicatedStorage:WaitForChild("Network")

local NotificationEvent = Network:FindFirstChild("NotificationEvent")
if not NotificationEvent then
	NotificationEvent = Instance.new("RemoteEvent")
	NotificationEvent.Name = "NotificationEvent"
	NotificationEvent.Parent = Network
end

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local GangStore = DataStoreService:GetDataStore("Jojo_Gangs_V3")

local ADMIN_IDS = {
	[342662401] = true
}

local ANNOUNCER_IDS = {
	[1182272211] = true
}

local GLOBAL_TOPIC = "AdminGlobalCommands"

local function GetDictSize(d)
	local c = 0
	if d then for _ in pairs(d) do c += 1 end end
	return c
end

local function FindPlayer(nameStr)
	if not nameStr then return nil end
	local search = string.lower(nameStr)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(p.Name), 1, #search) == search then
			return p
		end
	end
	return nil
end

local function GetProperItemName(inputStr)
	local search = string.lower(inputStr)
	for key, _ in pairs(ItemData.Equipment) do
		if string.lower(key) == search then return key end
	end
	for key, _ in pairs(ItemData.Consumables) do
		if string.lower(key) == search then return key end
	end
	return nil
end

local function GetProperStandName(inputStr)
	local search = string.lower(inputStr)
	for key, _ in pairs(StandData.Stands) do
		if string.lower(key) == search then return key end
	end
	return nil
end

local function GetProperStyleName(inputStr)
	local search = string.lower(inputStr)
	if search == "none" then return "None" end
	for key, _ in pairs(GameData.StyleBonuses) do
		if string.lower(key) == search then return key end
	end
	return nil
end

local function GetProperTraitName(inputStr)
	local search = string.lower(inputStr)
	local validTraits = {
		"None", 
		"Swift", "Tough", "Fierce", "Focused", "Lucky",
		"Armored", "Brutal", "Vigorous", "Evasive",
		"Indomitable", "Relentless", "Flaming", "Toxic", "Electric", "Frozen", "Serrated", "Disorienting",
		"Lethal", "Vampiric", "Overwhelming", "Gambler", "Gloomy", "Cheerful", "Blessed", 
		"Perseverance", "Requiem", "Overheaven"
	}

	for _, t in ipairs(validTraits) do
		if string.lower(t) == search then return t end
	end
	return nil
end

local function GetProperStatName(inputStr)
	local search = string.lower(inputStr)
	local validStats = {"Yen", "Prestige", "Elo", "Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}
	for _, s in ipairs(validStats) do
		if string.lower(s) == search then return s end
	end
	return nil
end

local function GetProperWorldBossName(inputStr)
	if not inputStr then return nil end
	local search = string.lower(inputStr)
	for key, _ in pairs(EnemyData.WorldBosses) do
		if string.lower(key) == search then return key end
	end
	return nil
end

local function GetProperPassAttr(inputStr)
	local search = string.gsub(string.lower(inputStr), " ", "")
	local passMap = {
		["2xspeed"] = "Has2xBattleSpeed", 
		["2xinventory"] = "Has2xInventory",
		["2xdrops"] = "Has2xDropChance",
		["autotrain"] = "HasAutoTraining",
		["styleslot2"] = "HasStyleSlot2", ["standslot2"] = "HasStandSlot2",
		["styleslot3"] = "HasStyleSlot3", ["standslot3"] = "HasStandSlot3",
		["autoroll"] = "HasAutoRoll",
		["horsename"] = "HasHorseNamePass"
	}
	return passMap[search]
end

local function GrantStand(playerObj, standName)
	if not StandData.Stands[standName] then return false end

	playerObj:SetAttribute("Stand", standName)

	local prestigeObj = playerObj:WaitForChild("leaderstats") and playerObj.leaderstats:WaitForChild("Prestige")
	local prestige = prestigeObj and prestigeObj.Value or 0
	local stats = StandData.Stands[standName].Stats

	for sName, sRank in pairs(stats) do
		local baseVal = (prestige == 0) and (GameData.StandRanks[sRank] or 0) or (prestige * 5)
		playerObj:SetAttribute("Stand_" .. sName, sRank)
		playerObj:SetAttribute("Stand_" .. sName .. "_Val", baseVal)
	end

	return true
end

local function SendAdminNotice(targetPlayer, message)
	if not targetPlayer then return end
	Network.CombatUpdate:FireClient(targetPlayer, "SystemMessage", message)
	NotificationEvent:FireClient(targetPlayer, message)
end

local function ExecuteCommandLocally(cmd, parts, adminPlayer, isFromCrossServer, senderName)
	local targetStr = string.lower(parts[2] or "")
	local targets = {}
	local displayTarget = ""
	local actualSenderName = senderName or (adminPlayer and adminPlayer.Name) or "System"

	if cmd ~= "!deletegang" and cmd ~= "!announcement" and cmd ~= "!addrep" and cmd ~= "!spawnwb" then
		if targetStr == "@all" then
			targets = Players:GetPlayers()
			displayTarget = "everyone in the game"
		elseif targetStr == "@server" then
			targets = Players:GetPlayers()
			displayTarget = "everyone in the server"
		elseif targetStr == "@self" or targetStr == "@me" then
			if adminPlayer then
				table.insert(targets, adminPlayer)
				displayTarget = "yourself"
			end
		else
			if isFromCrossServer then return end 
			local p = FindPlayer(parts[2])
			if p then
				table.insert(targets, p)
				displayTarget = p.Name
			end
		end

		if #targets == 0 then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Player not found.</font>") end
			return
		end
	end

	local isMassEvent = (targetStr == "@all" or targetStr == "@server" or isFromCrossServer)
	local eventTag = (isFromCrossServer or targetStr == "@all") and "GLOBAL EVENT" or "SERVER EVENT"

	if cmd == "!announcement" then
		local announcementText = table.concat(parts, " ", 2)
		for _, p in ipairs(Players:GetPlayers()) do
			SendAdminNotice(p, "\n<font color='#FF55FF' size='16'><b>[GLOBAL ANNOUNCEMENT - " .. actualSenderName .. "]</b></font>\n<font color='#FFFFFF'>" .. announcementText .. "</font>\n")
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Global announcement broadcasted!</font>") end

	elseif cmd == "!spawnwb" then
		local forceEvent = Network:FindFirstChild("AdminForceSpawnWB")
		if forceEvent then
			local rawBossName = parts[2] and table.concat(parts, " ", 2) or nil
			local properBossName = GetProperWorldBossName(rawBossName)

			forceEvent:Fire(properBossName)

			if adminPlayer then 
				if properBossName then
					SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Force-spawned specific World Boss ("..properBossName..") globally!</font>") 
				else
					SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Force-spawned a random World Boss globally!</font>") 
				end
			end
		end

	elseif cmd == "!additem" then
		local amount = tonumber(parts[3])
		local itemStartIndex = 3
		if amount then itemStartIndex = 4 else amount = 1 end
		local rawName = table.concat(parts, " ", itemStartIndex)
		local properName = GetProperItemName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				local attrName = properName:gsub("[^%w]", "") .. "Count"
				target:SetAttribute(attrName, (target:GetAttribute(attrName) or 0) + amount)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> You received " .. amount .. "x " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Gave " .. amount .. "x " .. properName .. " to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Item '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!addpass" then
		local rawName = table.concat(parts, " ", 3)
		local properAttr = GetProperPassAttr(rawName)

		if properAttr then
			for _, target in ipairs(targets) do
				target:SetAttribute(properAttr, true)
				SendAdminNotice(target, "<font color='#55FF55'>🎁 An Admin has granted you the " .. properAttr .. " GamePass!</font>")
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Gave GamePass '" .. properAttr .. "' to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Invalid Pass. Try: speed, inventory, drops, autotrain, slot2, slot3.</font>") end
		end

	elseif cmd == "!setstand" then
		local rawName = table.concat(parts, " ", 3)
		local properName = GetProperStandName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				GrantStand(target, properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Stand was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Set Stand " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Stand '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!setstyle" then
		local rawName = table.concat(parts, " ", 3)
		local properName = GetProperStyleName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				target:SetAttribute("FightingStyle", properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Fighting Style was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Set Fighting Style " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Fighting Style '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!settrait" then
		local rawName = parts[3] or ""
		local properName = GetProperTraitName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				target:SetAttribute("StandTrait", properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Stand Trait was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Set Stand Trait " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Trait '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!addstat" then
		local rawStat = parts[3]
		local properStat = GetProperStatName(rawStat)
		local amount = tonumber(parts[4]) or 1

		if properStat then
			for _, target in ipairs(targets) do
				if properStat == "Yen" or properStat == "Prestige" or properStat == "Elo" then
					local leaderstats = target:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild(properStat) then
						leaderstats[properStat].Value += amount
					end
				else
					local current = target:GetAttribute(properStat) or 0
					target:SetAttribute(properStat, current + amount)
				end

				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> You received " .. amount .. " " .. properStat .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Added " .. amount .. " " .. properStat .. " to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Stat '" .. rawStat .. "' does not exist.</font>") end
		end

	elseif cmd == "!joingang" then
		local rawGangName = table.concat(parts, " ", 3)
		local gangKey = string.lower(rawGangName)
		local success, gangData = pcall(function() return GangStore:GetAsync(gangKey) end)

		if success and gangData then
			for _, target in ipairs(targets) do
				local uidStr = tostring(target.UserId)
				local prestigeVal = target:WaitForChild("leaderstats") and target.leaderstats:WaitForChild("Prestige").Value or 0

				local oldGangKey = target:GetAttribute("Gang")
				if oldGangKey and oldGangKey ~= "None" then
					GangStore:UpdateAsync(oldGangKey, function(oldData)
						if oldData then
							oldData.Members[uidStr] = nil
							oldData.MemberCount = GetDictSize(oldData.Members)
						end
						return oldData
					end)
				end

				GangStore:UpdateAsync(gangKey, function(newData)
					if newData then
						newData.Members[uidStr] = { Name = target.Name, Role = "Grunt", Prestige = prestigeVal, LastOnline = os.time() }
						newData.MemberCount = GetDictSize(newData.Members)
					end
					return newData
				end)

				target:SetAttribute("Gang", gangKey)
				target:SetAttribute("GangRole", "Grunt")
				SendAdminNotice(target, "<font color='#FFD700'>Admin force-joined you to " .. gangData.Name .. "!</font>")
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Force-joined " .. displayTarget .. " to " .. gangData.Name .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Gang '" .. rawGangName .. "' not found in DataStore.</font>") end
		end

	elseif cmd == "!addrep" then
		local amount = tonumber(parts[2])
		local rawGangName = table.concat(parts, " ", 3)
		local gangKey = string.lower(rawGangName)

		if not amount or not gangKey then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Usage: !addrep [Amount] [GangName]</font>") end
			return
		end

		local s, d = pcall(function() return GangStore:GetAsync(gangKey) end)
		if s and d then
			pcall(function()
				GangStore:UpdateAsync(gangKey, function(oldData)
					if oldData then oldData.Rep = (oldData.Rep or 0) + amount end
					return oldData
				end)
			end)
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Added " .. amount .. " Rep to " .. d.Name .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Gang '" .. rawGangName .. "' not found.</font>") end
		end

	elseif cmd == "!promote" then
		local rankNum = tonumber(parts[3])
		local roles = { [1] = "Grunt", [2] = "Caporegime", [3] = "Consigliere", [4] = "Boss" }
		local newRole = roles[rankNum]

		if not newRole then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Admin Error: Rank must be 1-4.</font>") end
			return
		end

		for _, target in ipairs(targets) do
			local gangKey = target:GetAttribute("Gang")
			if gangKey and gangKey ~= "None" then
				local success, gangData = pcall(function() return GangStore:GetAsync(gangKey) end)
				if success and gangData then
					local uidStr = tostring(target.UserId)
					if gangData.Members[uidStr] then
						if newRole == "Boss" or newRole == "Consigliere" then
							for u, m in pairs(gangData.Members) do
								if m.Role == newRole and u ~= uidStr then
									m.Role = "Grunt"
									local oldMember = Players:GetPlayerByUserId(tonumber(u))
									if oldMember then 
										oldMember:SetAttribute("GangRole", "Grunt")
										SendAdminNotice(oldMember, "<font color='#FF5555'>Admin demoted your Gang Rank.</font>")
									end
								end
							end
						end
						gangData.Members[uidStr].Role = newRole
						pcall(function() GangStore:UpdateAsync(gangKey, function(oldData) 
								if oldData then oldData.Members = gangData.Members end
								return oldData 
							end) end)

						target:SetAttribute("GangRole", newRole)
						SendAdminNotice(target, "<font color='#FFD700'>Admin set your Gang Rank to " .. newRole .. "!</font>")
					end
				end
			end
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Promoted " .. displayTarget .. " to " .. newRole .. ".</font>") end

	elseif cmd == "!kickgang" then
		for _, target in ipairs(targets) do
			local gangKey = target:GetAttribute("Gang")
			if gangKey and gangKey ~= "None" then
				pcall(function() 
					GangStore:UpdateAsync(gangKey, function(oldData)
						if oldData and oldData.Members[tostring(target.UserId)] then
							oldData.Members[tostring(target.UserId)] = nil
							oldData.MemberCount = GetDictSize(oldData.Members)
						end
						return oldData
					end) 
				end)
				target:SetAttribute("Gang", "None")
				target:SetAttribute("GangRole", "None")
				SendAdminNotice(target, "<font color='#FF5555'>Admin forcefully kicked you from your gang.</font>")
			end
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Kicked " .. displayTarget .. " from their gang.</font>") end

	elseif cmd == "!deletegang" then
		local rawGangName = table.concat(parts, " ", 2)
		local gangKey = string.lower(rawGangName)

		local wipeEvent = ReplicatedStorage:FindFirstChild("AdminForceWipeGang")
		if wipeEvent then
			wipeEvent:Fire(gangKey)
		end

		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>Admin: Obliterated gang '" .. rawGangName .. "' from all servers and leaderboards.</font>") end
	end
end

pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(message)
		local data = message.Data
		if data.ServerId == game.JobId then return end 

		ExecuteCommandLocally(data.Cmd, data.Parts, nil, true, data.SenderName)
	end)
end)

local validCmds = {
	["!additem"] = true, ["!setstand"] = true, ["!setstyle"] = true, ["!addstat"] = true,
	["!joingang"] = true, ["!promote"] = true, ["!deletegang"] = true, ["!spawnwb"] = true,
	["!kickgang"] = true, ["!settrait"] = true, ["!announcement"] = true,
	["!addpass"] = true, ["!addrep"] = true
}

local function OnPlayerAdded(player)
	player.Chatted:Connect(function(message)
		local isStudio = RunService:IsStudio()
		local isFullAdmin = ADMIN_IDS[player.UserId] or isStudio
		local isAnnouncer = ANNOUNCER_IDS[player.UserId] or isStudio

		if not isFullAdmin and not isAnnouncer then return end

		local parts = string.split(message, " ")
		local cmd = string.lower(parts[1])

		if not validCmds[cmd] then return end

		if isAnnouncer and not isFullAdmin and cmd ~= "!announcement" then return end

		if #parts < 2 and cmd ~= "!spawnwb" then return end

		local targetStr = parts[2] and string.lower(parts[2]) or ""
		local isGlobal = (targetStr == "@all") or (cmd == "!announcement") or (cmd == "!spawnwb") or (cmd == "!deletegang")

		if isGlobal then
			pcall(function()
				MessagingService:PublishAsync(GLOBAL_TOPIC, {
					Cmd = cmd,
					Parts = parts,
					ServerId = game.JobId,
					SenderName = player.Name
				})
			end)
		end

		ExecuteCommandLocally(cmd, parts, player, false, player.Name)
	end)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end