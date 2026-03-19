-- @ScriptType: ModuleScript
local SFXManager = {}
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local sounds = {
	Click = 125296945528316,
	BuyItem = 118326705311058,
	BuyPass = 118678332722931,
	CombatHit = 139582343979763,
	CombatBlock = 122940429448056,
	CombatDodge = 135315310485417,
	CombatUtility = 127579210330639,
	CombatVictory = 102844356541414,
	CombatDefeat = 87047730068459,
	CombatCrit = 127379530739313,
	CombatStun = 126172750038425,
	CombatWillpower = 104414731133846
}

local customVolumes = {
	CombatVictory = 0.8,
	CombatDefeat = 0.6,
	CombatCrit = 0.3,
	CombatStun = 0.3,
	CombatWillpower = 0.15
}

local soundObjects = {}
local sfxFolder = nil

function SFXManager.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	sfxFolder = Instance.new("Folder")
	sfxFolder.Name = "GameSFX"
	sfxFolder.Parent = playerGui

	for name, id in pairs(sounds) do
		local snd = Instance.new("Sound")
		snd.Name = name
		snd.SoundId = "rbxassetid://" .. tostring(id)

		snd.Volume = customVolumes[name] or 0.5 

		snd.Parent = sfxFolder
		soundObjects[name] = snd
	end
end

function SFXManager.Play(name)
	if soundObjects[name] and sfxFolder then
		local clone = soundObjects[name]:Clone()
		clone.Parent = sfxFolder
		clone:Play()
		Debris:AddItem(clone, 6)
	end
end

return SFXManager