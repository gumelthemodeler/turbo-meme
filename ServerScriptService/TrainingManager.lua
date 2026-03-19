-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ToggleTraining = Network:WaitForChild("ToggleTraining")

local ActiveTrainers = {}

local TrainingRates = {
	[1] = {XP = 50, Yen = 1},
	[2] = {XP = 100, Yen = 5},
	[3] = {XP = 250, Yen = 10},
	[4] = {XP = 500, Yen = 15},
	[5] = {XP = 1000, Yen = 25},
	[6] = {XP = 1500, Yen = 50},
	[7] = {XP = 2500, Yen = 75}
}

local function GetPlayerBoosts(player)
	local boosts = { XP = 1.0, Yen = 1.0 }

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	boosts.XP += (friends * 0.05)
	boosts.Yen += (friends * 0.05)

	if player.MembershipType == Enum.MembershipType.Premium then boosts.XP += 0.05 end

	if player:GetAttribute("IsSupporter") then
		boosts.XP += 0.05
	end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 1500 then boosts.Yen += 0.05 end
	if elo >= 2000 then boosts.XP += 0.05 end

	boosts.Yen *= (player:GetAttribute("GangYenBoost") or 1.0)
	boosts.XP *= (player:GetAttribute("GangXPBoost") or 1.0)

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
				local safePart = math.clamp(currentPart, 1, 6)

				local baseRates = TrainingRates[safePart]

				local xpGain = baseRates.XP * (1 + prestige)
				local yenGain = baseRates.Yen * (1 + prestige)

				local pBoosts = GetPlayerBoosts(player)
				xpGain = math.floor(xpGain * pBoosts.XP)
				yenGain = math.floor(yenGain * pBoosts.Yen)

				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)
				player.leaderstats.Yen.Value += yenGain

				Network.CombatUpdate:FireClient(player, "TrainingTick", {XP = xpGain, Yen = yenGain, Part = safePart})
			else
				ActiveTrainers[player] = nil
			end
		end
	end
end)