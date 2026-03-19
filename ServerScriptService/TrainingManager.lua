-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ToggleTraining = Network:WaitForChild("ToggleTraining")

local ActiveTrainers = {}

-- Scales up to 7 for the 7 AoT Campaign Arcs
local TrainingRates = {
	[1] = {XP = 50, Dews = 1},
	[2] = {XP = 100, Dews = 5},
	[3] = {XP = 250, Dews = 10},
	[4] = {XP = 500, Dews = 15},
	[5] = {XP = 1000, Dews = 25},
	[6] = {XP = 1500, Dews = 50},
	[7] = {XP = 2500, Dews = 75}
}

local function GetPlayerBoosts(player)
	local boosts = { XP = 1.0, Dews = 1.0 }

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	boosts.XP += (friends * 0.05)
	boosts.Dews += (friends * 0.05)

	if player.MembershipType == Enum.MembershipType.Premium then boosts.XP += 0.05 end

	if player:GetAttribute("IsSupporter") then
		boosts.XP += 0.05
	end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 1500 then boosts.Dews += 0.05 end
	if elo >= 2000 then boosts.XP += 0.05 end

	-- Updated to read Clan boosts instead of Gang boosts
	boosts.Dews *= (player:GetAttribute("ClanDewsBoost") or 1.0)
	boosts.XP *= (player:GetAttribute("ClanXPBoost") or 1.0)

	return boosts
end

ToggleTraining.OnServerEvent:Connect(function(player, isTraining)
	if isTraining then ActiveTrainers[player] = true else ActiveTrainers[player] = nil end
end)

task.spawn(function()
	while task.wait(5) do
		for player, _ in pairs(ActiveTrainers) do
			if player and player.Parent and player:FindFirstChild("leaderstats") then
				local prestige = player.leaderstats.Prestige.Value
				local currentPart = player:GetAttribute("CurrentPart") or 1

				-- Clamped to 7 to match our new Raid and Campaign structures
				local safePart = math.clamp(currentPart, 1, 7)

				local baseRates = TrainingRates[safePart]

				local xpGain = baseRates.XP * (1 + prestige)
				local dewsGain = baseRates.Dews * (1 + prestige)

				local pBoosts = GetPlayerBoosts(player)
				xpGain = math.floor(xpGain * pBoosts.XP)
				dewsGain = math.floor(dewsGain * pBoosts.Dews)

				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)

				-- Still uses Yen internally so data saves don't break, but is mathematically Dews
				player.leaderstats.Yen.Value += dewsGain

				-- Firing back Dews instead of Yen for the UI to read
				Network.CombatUpdate:FireClient(player, "TrainingTick", {XP = xpGain, Dews = dewsGain, Part = safePart})
			else
				ActiveTrainers[player] = nil
			end
		end
	end
end)