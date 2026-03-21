-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local EffectsManager = {}
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local SFX_Folder = Instance.new("Folder")
SFX_Folder.Name = "CombatSFX"
SFX_Folder.Parent = SoundService

local Sounds = {
	-- // UI & GACHA //
	["Click"] = "rbxassetid://6895086653",
	["Hover"] = "rbxassetid://6895054232",
	["Spin"] = "rbxassetid://7047602360",
	["Reveal"] = "rbxassetid://3031855627",

	-- THE FIX: Victory and Defeat Sounds!
	["Victory"] = "rbxassetid://5854721956",
	["Defeat"] = "rbxassetid://131015669",

	-- // ODM & BLADES //
	["LightSlash"] = "rbxassetid://6808798991",
	["HeavySlash"] = "rbxassetid://6808801089",
	["DualSlash"] = "rbxassetid://6808805561",
	["SpinSlash"] = "rbxassetid://6808808000",
	["Dash"] = "rbxassetid://6042054665",
	["Grapple"] = "rbxassetid://6042052445",

	-- // GUNS & EXPLOSIVES //
	["Gun"] = "rbxassetid://6363016462",
	["Sniper"] = "rbxassetid://5854817109",
	["Explosion"] = "rbxassetid://142070127",
	["BigExplosion"] = "rbxassetid://287390697",

	-- // TITAN PHYSICAL //
	["Punch"] = "rbxassetid://5887343542",
	["HeavyPunch"] = "rbxassetid://5887344158",
	["Kick"] = "rbxassetid://5887344336",
	["Stomp"] = "rbxassetid://3086708605",
	["Bite"] = "rbxassetid://223594258",

	-- // TITAN ABILITIES //
	["Roar"] = "rbxassetid://1493282245",
	["Steam"] = "rbxassetid://4612450379",
	["Transform"] = "rbxassetid://1681729440",
	["Spike"] = "rbxassetid://1786650424",

	-- // UTILITY //
	["Block"] = "rbxassetid://5169562725",
	["Heal"] = "rbxassetid://131068212",
	["Flee"] = "rbxassetid://288641615"
}

local Images = {
	["SlashMark"] = "rbxassetid://7335198083",
	["ClawMark"] = "rbxassetid://11684347313",
	["ExplosionMark"] = "rbxassetid://6284617513",
	["HealMark"] = "rbxassetid://7403332463",
	["BlockMark"] = "rbxassetid://7047604313",
	["Blood"] = "rbxassetid://3366838379"
}

function EffectsManager.Init()
	for name, id in pairs(Sounds) do
		local s = Instance.new("Sound")
		s.Name = name; s.SoundId = id
		s.Volume = (name == "Hover") and 0.15 or 0.5 
		s.Parent = SFX_Folder
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function hookButton(btn)
		if btn:IsA("TextButton") or btn:IsA("ImageButton") then
			if not btn:GetAttribute("HasAudioHook") then
				btn:SetAttribute("HasAudioHook", true)
				btn.MouseEnter:Connect(function() EffectsManager.PlaySFX("Hover", 1.0) end)
				btn.MouseButton1Click:Connect(function() EffectsManager.PlaySFX("Click", 1.0) end)
			end
		end
	end

	for _, child in ipairs(PlayerGui:GetDescendants()) do hookButton(child) end
	PlayerGui.DescendantAdded:Connect(hookButton)
end

function EffectsManager.PlaySFX(sfxName, pitchMod)
	local s = SFX_Folder:FindFirstChild(sfxName)
	if s then
		local clone = s:Clone()
		-- Pitch modulation makes rapid hits sound dynamic and visceral
		clone.PlaybackSpeed = pitchMod or (1 + math.random(-10, 10)/100)
		clone.Parent = SFX_Folder
		clone:Play()
		game.Debris:AddItem(clone, 3)
	end
end

function EffectsManager.PlayVFX(vfxName, targetFrame, customColor)
	local imgId = Images[vfxName]
	if not imgId or not targetFrame then return end

	local vfx = Instance.new("ImageLabel")
	vfx.BackgroundTransparency = 1; vfx.Image = imgId; vfx.ImageColor3 = customColor or Color3.fromRGB(255, 255, 255)

	local randX = math.random(20, 80) / 100
	local randY = math.random(20, 80) / 100
	vfx.Position = UDim2.new(randX, 0, randY, 0); vfx.AnchorPoint = Vector2.new(0.5, 0.5)
	vfx.Size = UDim2.new(0, 0, 0, 0); vfx.Rotation = math.random(-45, 45); vfx.ZIndex = 50
	vfx.Parent = targetFrame

	local tweenIn = TweenService:Create(vfx, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1.2, 0, 1.2, 0)})
	tweenIn:Play()

	task.delay(0.15, function()
		local tweenOut = TweenService:Create(vfx, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1.5, 0, 1.5, 0), ImageTransparency = 1})
		tweenOut:Play()
		game.Debris:AddItem(vfx, 0.4)
	end)
end

function EffectsManager.PlayCombatEffect(skillName, isPlayerAttacking, pAvatarBox, eAvatarBox, didHit)
	local skillInfo = SkillData.Skills[skillName]
	if not skillInfo then return end

	local targetBox = isPlayerAttacking and eAvatarBox or pAvatarBox
	local userBox = isPlayerAttacking and pAvatarBox or eAvatarBox

	if skillInfo.Effect == "Rest" or skillInfo.Effect == "TitanRest" or skillInfo.Effect == "Block" or skillInfo.Effect == "Transform" then
		targetBox = userBox
	end

	-- If it completely missed, play one block/evade effect and stop
	if not didHit and skillInfo.Type ~= "Basic" and skillInfo.Effect == "None" then
		EffectsManager.PlaySFX("Dash", 1.2)
		EffectsManager.PlayVFX("BlockMark", targetBox, Color3.fromRGB(200, 200, 200))
		return
	end

	local sName = skillInfo.SFX or "Punch"
	local vName = skillInfo.VFX or "SlashMark"

	-- THE FIX: Check for multi-hit moves!
	local hitsToPlay = 1
	if didHit and skillInfo.Hits and skillInfo.Hits > 1 then
		hitsToPlay = skillInfo.Hits
	end

	-- Spawn a rapid-fire loop for multi-hit moves
	task.spawn(function()
		for i = 1, hitsToPlay do
			-- Slightly shift pitch per hit so it doesn't sound robotic
			EffectsManager.PlaySFX(sName, 1 + (math.random(-15, 15)/100))
			EffectsManager.PlayVFX(vName, targetBox)

			if didHit and skillInfo.Effect ~= "Rest" and skillInfo.Effect ~= "Block" and skillInfo.Effect ~= "Transform" then
				task.delay(0.05, function() EffectsManager.PlayVFX("Blood", targetBox, Color3.fromRGB(150, 0, 0)) end)
			end

			if i < hitsToPlay then
				task.wait(0.15) -- Tiny delay for the rapid barrage
			end
		end
	end)
end

return EffectsManager