-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local PrestigeEvent = Network:WaitForChild("PrestigeEvent")
local CombatUpdate = Network:WaitForChild("CombatUpdate")

PrestigeEvent.OnServerEvent:Connect(function(player)
	print("[DEBUG] PrestigeManager received request from: " .. player.Name)

	local currentPart = player:GetAttribute("CurrentPart") or 1

	if currentPart > 6 then
		print("[DEBUG] Player is eligible! Executing Prestige...")
		local currentPrestige = player.leaderstats.Prestige.Value
		local newPrestige = currentPrestige + 1

		player.leaderstats.Prestige.Value = newPrestige

		player:SetAttribute("CurrentPart", 1)
		player:SetAttribute("CurrentMission", 1) 
		player:SetAttribute("XP", 0)

		local yenObj = player.leaderstats:FindFirstChild("Yen")
		if yenObj then yenObj.Value = 0 end

		for statName, _ in pairs(GameData.BaseStats) do
			player:SetAttribute(statName, newPrestige * 5)
		end

		local standStatsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
		for _, s in ipairs(standStatsList) do
			player:SetAttribute("Stand_" .. s .. "_Val", newPrestige * 5)
		end

		local rokaCount = player:GetAttribute("RokakakaCount") or 0
		player:SetAttribute("RokakakaCount", rokaCount + 1)
		
		local discCount = player:GetAttribute("HeavenlyStandDiscCount") or 0
		player:SetAttribute("HeavenlyStandDiscCount", discCount + 1)

		local modCount = math.floor(newPrestige / 5)
		local modPool = {}
		for key, _ in pairs(GameData.UniverseModifiers) do
			if key ~= "None" then table.insert(modPool, key) end
		end

		local rolledMods = {}
		for i = 1, math.min(modCount, #modPool) do
			local rIndex = math.random(1, #modPool)
			table.insert(rolledMods, table.remove(modPool, rIndex))
		end

		local rolledModStr = table.concat(rolledMods, ",")
		player:SetAttribute("UniverseModifier", rolledModStr)

		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF55FF'>Universe Reset! Reached Prestige " .. newPrestige .. "!</font>")
		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF55FF'>You were rewarded with 1x Rokakaka, and 1x Heavenly Stand Disc!</font>")
		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFFF55'>Modifiers applied: " .. rolledModStr .. "!</font>")
	else
		print("[DEBUG] Prestige rejected. CurrentPart is only: " .. currentPart)
	end
end)