-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local UpgradeRemote = Network:FindFirstChild("UpgradeStat")
if not UpgradeRemote then
	UpgradeRemote = Instance.new("RemoteEvent")
	UpgradeRemote.Name = "UpgradeStat"
	UpgradeRemote.Parent = Network
end

UpgradeRemote.OnServerEvent:Connect(function(player, statToUpgrade, amount)
	local isBaseStat = GameData.BaseStats[statToUpgrade] ~= nil
	local isStandStat = table.find(GameData.StandStats, statToUpgrade) ~= nil

	if not isBaseStat and not isStandStat then return end

	local prestige = player.leaderstats.Prestige.Value
	local statCap = GameData.GetStatCap(prestige)
	local currentStat = player:GetAttribute(statToUpgrade) or 0

	if currentStat >= statCap then return end

	local currentXP = player:GetAttribute("XP") or 0
	local baseVal = 0

	if prestige == 0 then
		if isBaseStat then
			baseVal = GameData.BaseStats[statToUpgrade]
		else
			baseVal = 0 
		end
	else
		baseVal = prestige * 5
	end

	local upgradesToAttempt = 1
	if type(amount) == "number" then
		upgradesToAttempt = amount
	elseif amount == "MAX" then
		upgradesToAttempt = 9999
	end

	local upgradesDone = 0

	while upgradesDone < upgradesToAttempt and currentStat < statCap do
		local cost = GameData.CalculateStatCost(currentStat, baseVal, prestige)

		if currentXP >= cost then
			currentXP -= cost
			currentStat += 1
			upgradesDone += 1
		else
			break
		end
	end

	if upgradesDone > 0 then
		player:SetAttribute("XP", currentXP)
		player:SetAttribute(statToUpgrade, currentStat)
	end
end)