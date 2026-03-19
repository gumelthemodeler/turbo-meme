-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local PrestigeEvent = Network:WaitForChild("PrestigeEvent")
local CombatUpdate = Network:WaitForChild("CombatUpdate")

PrestigeEvent.OnServerEvent:Connect(function(player)
	print("[DEBUG] PrestigeManager received request from: " .. player.Name)

	local currentPart = player:GetAttribute("CurrentPart") or 1

	-- AoT Campaign has 7 parts now
	if currentPart > 7 then
		print("[DEBUG] Player is eligible! Executing Prestige...")
		local currentPrestige = player.leaderstats.Prestige.Value
		local newPrestige = currentPrestige + 1

		player.leaderstats.Prestige.Value = newPrestige

		player:SetAttribute("CurrentPart", 1)
		player:SetAttribute("CurrentMission", 1) 
		player:SetAttribute("XP", 0)

		-- Yen -> Dews
		local dewsObj = player.leaderstats:FindFirstChild("Yen") -- Kept 'Yen' for leaderstats backend compatibility if needed, but displays as Dews
		if dewsObj then dewsObj.Value = 0 end

		for statName, _ in pairs(GameData.BaseStats) do
			player:SetAttribute(statName, newPrestige * 5)
		end

		-- StandStats -> TitanStats
		local titanStatsList = {"Power", "Speed", "Hardening", "Endurance", "Precision", "Potential"}
		for _, s in ipairs(titanStatsList) do
			player:SetAttribute("Titan_" .. s .. "_Val", newPrestige * 5)
		end

		-- Rokakaka -> Founder's Memory Wipe
		local wipeCount = player:GetAttribute("FoundersMemoryWipeCount") or 0
		player:SetAttribute("FoundersMemoryWipeCount", wipeCount + 1)

		-- Heavenly Stand Disc -> Spinal Fluid Syringe
		local syringeCount = player:GetAttribute("SpinalFluidSyringeCount") or 0
		player:SetAttribute("SpinalFluidSyringeCount", syringeCount + 1)

		local modCount = math.floor(newPrestige / 5)
		local modPool = {}
		for key, _ in pairs(GameData.BattleConditions) do
			if key ~= "Clear Weather" then table.insert(modPool, key) end
		end

		local rolledMods = {}
		for i = 1, math.min(modCount, #modPool) do
			local rIndex = math.random(1, #modPool)
			table.insert(rolledMods, table.remove(modPool, rIndex))
		end

		local rolledModStr = table.concat(rolledMods, ",")
		player:SetAttribute("BattleCondition", rolledModStr)

		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF55FF'>Titan Marks Reset! Reached Prestige " .. newPrestige .. "!</font>")
		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF55FF'>You were rewarded with 1x Founder's Memory Wipe, and 1x Spinal Fluid Syringe!</font>")
		CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFFF55'>Battle Conditions applied: " .. rolledModStr .. "!</font>")
	else
		print("[DEBUG] Prestige rejected. CurrentPart is only: " .. currentPart)
	end
end)