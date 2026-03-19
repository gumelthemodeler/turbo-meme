-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local GROUP_ID = 11280027

local function CheckSupporterStatus(player, isManualCheck)
	local success, inGroup = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)

	if success and inGroup then
		player:SetAttribute("IsSupporter", true)

		if player:GetAttribute("ClaimedSupporterReward") == false then
			player:SetAttribute("ClaimedSupporterReward", true)

			player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + 5)
			player:SetAttribute("RokakakaCount", (player:GetAttribute("RokakakaCount") or 0) + 3)

			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFD700'><b>SUPPORTER REWARD:</b> +5 Stand Arrows, +3 Rokakakas!</font>")
		elseif isManualCheck then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Supporter status verified! Boosts active.</font>")
		end
		return true
	end

	player:SetAttribute("IsSupporter", false)
	if isManualCheck then
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Verification failed. Please join Group 11280027!</font>")
	end
	return false
end

local function UpdateFriendCounts()
	local currentPlayers = Players:GetPlayers()
	for _, p in ipairs(currentPlayers) do
		local friendCount = 0
		for _, otherPlayer in ipairs(currentPlayers) do
			if p ~= otherPlayer then
				local s, isFriend = pcall(function() return p:IsFriendsWithAsync(otherPlayer.UserId) end)
				if s and isFriend then
					friendCount += 1
				end
			end
		end
		p:SetAttribute("ServerFriends", friendCount)
	end
end

task.spawn(function()
	while task.wait(15) do
		UpdateFriendCounts()
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local success, inGroup = pcall(function() return player:IsInGroupAsync(GROUP_ID) end)
		if success and inGroup then
			player:SetAttribute("IsSupporter", true)
		else
			player:SetAttribute("IsSupporter", false)
		end
	end)

	task.spawn(function()
		player:WaitForChild("leaderstats", 15)
		if player and player.Parent then
			CheckSupporterStatus(player, false)
			UpdateFriendCounts()
		end
	end)
end)

Players.PlayerRemoving:Connect(UpdateFriendCounts)

Network:WaitForChild("BoostAction").OnServerEvent:Connect(function(player, action)
	if action == "CheckSupporter" then
		CheckSupporterStatus(player, true)
	end
end)