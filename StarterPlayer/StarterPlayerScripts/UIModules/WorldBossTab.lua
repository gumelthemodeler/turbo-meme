-- @ScriptType: ModuleScript
local WorldBossTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))

local menuContainer, infoCard
local bossNameLabel, timerLabel, engageBtn
local combatUI
local activeFighters = {}
local rootFrame, forceTabFocus, cachedTooltipMgr
local resourceLabel, turnLabel

local inBattle = false
local BOSS_ACTIVE_MINUTES = 30

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-"
}

local StatusDescs = {
	Stun = "Cannot move or act.",
	Poison = "Takes damage every turn.",
	Burn = "Takes damage every turn.",
	Bleed = "Takes damage every turn.",
	Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.",
	Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.",
	Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.",
	Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.",
	Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance."
}

local currentLog = ""
local function AddLog(text, append)
	if append then
		currentLog = currentLog .. "\n" .. text
	else
		currentLog = text
	end
	if combatUI then combatUI:Log(currentLog) end
end

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		if f.InfoArea and f.InfoArea:FindFirstChild("NameLabel") then
			f.InfoArea.NameLabel.Text = name
		end
	end
	local f = activeFighters[fKey]
	f:UpdateHealth(hp, maxHp)

	local currentStatuses = {}
	if statuses then
		for eff, duration in pairs(statuses) do
			if duration and duration > 0 then
				currentStatuses[eff] = true
				f:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
			end
		end
	end
	for eff, _ in pairs(StatusIcons) do
		if not currentStatuses[eff] then
			f:RemoveStatus(eff)
		end
	end

	local hasStunImmunity = (immunities and immunities.Stun and immunities.Stun > 0)
	if hasStunImmunity then
		f:SetCooldown("StunImmunity", "STN", tostring(immunities.Stun), "Immune to Stun effects.")
	else
		f:RemoveCooldown("StunImmunity")
	end

	local hasConfImmunity = (immunities and immunities.Confusion and immunities.Confusion > 0)
	if hasConfImmunity then
		f:SetCooldown("ConfImmunity", "CNF", tostring(immunities.Confusion), "Immune to Confusion effects.")
	else
		f:RemoveCooldown("ConfImmunity")
	end
end

function WorldBossTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	if not WorldBossTab.Listener then
		local wbUpdate = Network:WaitForChild("WorldBossUpdate")
		WorldBossTab.Listener = wbUpdate.OnClientEvent:Connect(function(action, data)
			WorldBossTab.UpdateWorldBoss(action, data)
		end)
	end

	menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.95, 0, 0.95, 0)
	menuContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	menuContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	menuContainer.ZIndex = 30
	menuContainer.Parent = parentFrame

	local mcCorner = Instance.new("UICorner")
	mcCorner.CornerRadius = UDim.new(0, 12)
	mcCorner.Parent = menuContainer

	local mcStroke = Instance.new("UIStroke")
	mcStroke.Color = Color3.fromRGB(90, 50, 120)
	mcStroke.Thickness = 2
	mcStroke.Parent = menuContainer

	infoCard = Instance.new("Frame")
	infoCard.Name = "InfoCard"
	infoCard.Size = UDim2.new(0.8, 0, 0.65, 0)
	infoCard.Position = UDim2.new(0.5, 0, 0.5, 0)
	infoCard.AnchorPoint = Vector2.new(0.5, 0.5)
	infoCard.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
	infoCard.ClipsDescendants = true
	infoCard.ZIndex = 31
	infoCard.Parent = menuContainer

	local icCorner = Instance.new("UICorner")
	icCorner.CornerRadius = UDim.new(0, 16)
	icCorner.Parent = infoCard

	local icStroke = Instance.new("UIStroke")
	icStroke.Color = Color3.fromRGB(255, 215, 50)
	icStroke.Thickness = 3
	icStroke.Parent = infoCard

	local icGrad = Instance.new("UIGradient")
	icGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 20, 75)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 5, 30))
	}
	icGrad.Rotation = 45
	icGrad.Parent = infoCard

	local icPattern = Instance.new("ImageLabel")
	icPattern.Size = UDim2.new(1, 0, 1, 0)
	icPattern.BackgroundTransparency = 1
	icPattern.Image = "rbxassetid://79623015802180"
	icPattern.ImageColor3 = Color3.fromRGB(150, 50, 200)
	icPattern.ImageTransparency = 0.85
	icPattern.ScaleType = Enum.ScaleType.Tile
	icPattern.TileSize = UDim2.new(0, 300, 0, 150)
	icPattern.ZIndex = 31
	icPattern.Parent = infoCard

	local icCornerPat = Instance.new("UICorner")
	icCornerPat.CornerRadius = UDim.new(0, 16)
	icCornerPat.Parent = icPattern

	local warningHeader = Instance.new("TextLabel")
	warningHeader.Size = UDim2.new(1, 0, 0.1, 0)
	warningHeader.Position = UDim2.new(0, 0, 0.08, 0)
	warningHeader.BackgroundTransparency = 1
	warningHeader.Font = Enum.Font.GothamBlack
	warningHeader.TextColor3 = Color3.fromRGB(255, 50, 50)
	warningHeader.TextScaled = true
	warningHeader.Text = "⚠ GLOBAL RAID EVENT ⚠"
	warningHeader.ZIndex = 32
	warningHeader.Parent = infoCard

	local whUic = Instance.new("UITextSizeConstraint")
	whUic.MaxTextSize = 28
	whUic.MinTextSize = 14
	whUic.Parent = warningHeader

	bossNameLabel = Instance.new("TextLabel")
	bossNameLabel.Name = "BossNameLabel"
	bossNameLabel.Size = UDim2.new(1, 0, 0.2, 0)
	bossNameLabel.Position = UDim2.new(0, 0, 0.2, 0)
	bossNameLabel.BackgroundTransparency = 1
	bossNameLabel.Font = Enum.Font.GothamBlack
	bossNameLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	bossNameLabel.TextScaled = true
	bossNameLabel.Text = "UNKNOWN THREAT"
	bossNameLabel.ZIndex = 32
	bossNameLabel.Parent = infoCard

	local bnStroke = Instance.new("UIStroke")
	bnStroke.Color = Color3.fromRGB(0, 0, 0)
	bnStroke.Thickness = 2
	bnStroke.Parent = bossNameLabel

	local bnUic = Instance.new("UITextSizeConstraint")
	bnUic.MaxTextSize = 50
	bnUic.MinTextSize = 20
	bnUic.Parent = bossNameLabel

	local lineDivider = Instance.new("Frame")
	lineDivider.Size = UDim2.new(0.8, 0, 0, 2)
	lineDivider.Position = UDim2.new(0.5, 0, 0.45, 0)
	lineDivider.AnchorPoint = Vector2.new(0.5, 0.5)
	lineDivider.BackgroundColor3 = Color3.fromRGB(90, 40, 120)
	lineDivider.BorderSizePixel = 0
	lineDivider.ZIndex = 32
	lineDivider.Parent = infoCard

	local bossDescLabel = Instance.new("TextLabel")
	bossDescLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	bossDescLabel.Position = UDim2.new(0.5, 0, 0.55, 0)
	bossDescLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	bossDescLabel.BackgroundTransparency = 1
	bossDescLabel.Font = Enum.Font.GothamMedium
	bossDescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	bossDescLabel.TextScaled = true
	bossDescLabel.RichText = true
	bossDescLabel.Text = "Deal as much damage as possible within 10 turns. High damage yields higher drop rates for rare loot!"
	bossDescLabel.ZIndex = 32
	bossDescLabel.Parent = infoCard

	local bdUic = Instance.new("UITextSizeConstraint")
	bdUic.MaxTextSize = 18
	bdUic.MinTextSize = 10
	bdUic.Parent = bossDescLabel

	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0.15, 0)
	timerLabel.Position = UDim2.new(0, 0, 0.65, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	timerLabel.TextScaled = true
	timerLabel.Text = "WAITING..."
	timerLabel.ZIndex = 32
	timerLabel.Parent = infoCard

	local tmUic = Instance.new("UITextSizeConstraint")
	tmUic.MaxTextSize = 24
	tmUic.MinTextSize = 10
	tmUic.Parent = timerLabel

	engageBtn = Instance.new("TextButton")
	engageBtn.Name = "EngageBtn"
	engageBtn.Size = UDim2.new(0.6, 0, 0.18, 0)
	engageBtn.Position = UDim2.new(0.5, 0, 0.88, 0)
	engageBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	engageBtn.Font = Enum.Font.GothamBold
	engageBtn.TextColor3 = Color3.new(1, 1, 1)
	engageBtn.TextScaled = true
	engageBtn.Text = "WAITING..."
	engageBtn.ZIndex = 32
	engageBtn.Parent = infoCard

	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7))
	}
	btnGrad.Rotation = 90
	btnGrad.Parent = engageBtn

	local ebCorner = Instance.new("UICorner")
	ebCorner.CornerRadius = UDim.new(0, 8)
	ebCorner.Parent = engageBtn

	local ebStroke = Instance.new("UIStroke")
	ebStroke.Color = Color3.fromRGB(255, 215, 50)
	ebStroke.Thickness = 2
	ebStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ebStroke.Parent = engageBtn

	local ebUic = Instance.new("UITextSizeConstraint")
	ebUic.MaxTextSize = 30
	ebUic.MinTextSize = 14
	ebUic.Parent = engageBtn

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.Visible = false
	combatUI.MainFrame.ZIndex = 40

	turnLabel = Instance.new("TextLabel")
	turnLabel.Name = "TurnLabel"
	turnLabel.Size = UDim2.new(0.3, 0, 0, 20)
	turnLabel.Position = UDim2.new(0.5, 0, 0, -22)
	turnLabel.AnchorPoint = Vector2.new(0.5, 0)
	turnLabel.BackgroundTransparency = 1
	turnLabel.Font = Enum.Font.GothamBlack
	turnLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	turnLabel.TextScaled = true
	turnLabel.TextXAlignment = Enum.TextXAlignment.Center
	turnLabel.Text = "Turns Remaining: 10/10"
	turnLabel.ZIndex = 42
	turnLabel.Parent = combatUI.MainFrame

	local tUic = Instance.new("UITextSizeConstraint")
	tUic.MaxTextSize = 18
	tUic.MinTextSize = 10
	tUic.Parent = turnLabel

	resourceLabel = Instance.new("TextLabel")
	resourceLabel.Name = "ResourceLabel"
	resourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Font = Enum.Font.GothamBold
	resourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	resourceLabel.TextScaled = true
	resourceLabel.Text = ""
	resourceLabel.LayoutOrder = 2
	resourceLabel.ZIndex = 42
	resourceLabel.Parent = combatUI.ContentContainer

	local resUic = Instance.new("UITextSizeConstraint")
	resUic.MaxTextSize = 18
	resUic.MinTextSize = 10
	resUic.Parent = resourceLabel

	engageBtn.MouseButton1Click:Connect(function()
		if engageBtn.Text == "ENGAGE BOSS" then
			SFXManager.Play("Click")
			Network.WorldBossAction:FireServer("Engage")
		end
	end)

	task.delay(0.5, function()
		Network.WorldBossAction:FireServer("RequestSync")
	end)

	task.spawn(function()
		local RunService = game:GetService("RunService")
		while task.wait(1) do
			if inBattle then continue end

			local utc = os.date("!*t")
			local mins = utc.min
			local secs = utc.sec
			local currentHour = utc.hour
			local lastFought = player:GetAttribute("LastWorldBossHour")
			local isStudio = RunService:IsStudio()

			local endTime = ReplicatedStorage:GetAttribute("WorldBossEndTime") or 0
			local timeRemaining = endTime - os.time()

			if lastFought == currentHour and not isStudio then
				local secondsLeft = (60 * 60) - ((mins * 60) + secs)
				timerLabel.Text = "NEXT IN: " .. FormatTime(secondsLeft)
				timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				engageBtn.Text = "ALREADY FOUGHT"
				engageBtn.AutoButtonColor = false
			elseif timeRemaining > 0 then
				timerLabel.Text = "DESPAWNS IN: " .. FormatTime(math.floor(timeRemaining))
				timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				engageBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
				engageBtn.Text = "ENGAGE BOSS"
				engageBtn.AutoButtonColor = true
			else
				local secondsLeft = (60 * 60) - ((mins * 60) + secs)
				timerLabel.Text = "SPAWNS IN: " .. FormatTime(secondsLeft)
				timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				engageBtn.Text = "WAITING..."
				engageBtn.AutoButtonColor = false
			end
		end
	end)
end

function WorldBossTab.RenderSkills(battleData)
	if not battleData then return end
	combatUI:ClearAbilities()

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then table.insert(valid, {Name = n, Data = s}) end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))

		local currentCooldown = battleData.Player.Cooldowns and battleData.Player.Cooldowns[sk.Name] or 0
		local disabled = battleData.Player.Stamina < (sk.Data.StaminaCost or 0) or battleData.Player.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0

		local btnText = (currentCooldown > 0) and (sk.Name .. " (" .. currentCooldown .. ")") or sk.Name

		local cb = function()
			if disabled then return end
			SFXManager.Play("Click")
			cachedTooltipMgr.Hide()
			Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name})
		end

		if sk.Name == "Flee" then cb = nil end

		local btn = combatUI:AddAbility(btnText, disabled and Color3.fromRGB(35, 25, 45) or c, cb)

		if disabled then
			btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
		else
			if sk.Name == "Flee" then
				local isConfirmingFlee = false
				btn.MouseButton1Click:Connect(function() 
					if not disabled then
						SFXManager.Play("Click")
						if not isConfirmingFlee then
							isConfirmingFlee = true
							btn.Text = "Confirm Flee?"
							btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
							task.delay(3, function()
								if isConfirmingFlee and btn and btn.Parent then
									isConfirmingFlee = false
									btn.Text = sk.Name
									btn.BackgroundColor3 = c
								end
							end)
						else
							cachedTooltipMgr.Hide()
							Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name}) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function WorldBossTab.UpdateWorldBoss(status, data)
	if status == "SyncBoss" then
		if bossNameLabel then
			bossNameLabel.Text = data and string.upper(data) or "UNKNOWN THREAT"
		end
		return
	end

	if status == "Start" then
		inBattle = true
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		menuContainer.Visible = false
		combatUI.MainFrame.Visible = true
		combatUI.AbilitiesArea.Visible = true

		AddLog(data.LogMsg or "", false)
		WorldBossTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

		if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
		elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
		elseif data.DidHit then SFXManager.Play("CombatHit")
		else SFXManager.Play("CombatUtility") end

		task.spawn(function()
			task.wait(0.05) 
			if string.find(data.LogMsg, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
			if string.find(data.LogMsg, "(Stunned!)", 1, true) or string.find(data.LogMsg, "stunning") or string.find(data.LogMsg, "halt") then SFXManager.Play("CombatStun") end
			if string.find(string.lower(data.LogMsg), "survived on willpower") then SFXManager.Play("CombatWillpower") end
		end)

		if data.DidHit then
			task.spawn(function()
				local p = data.ShakeType == "Heavy" and 18 or (data.ShakeType == "Light" and 3 or 8)
				for i = 1, 6 do 
					local offsetX = math.random(-p, p)
					local offsetY = math.random(-p, p)
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
			end)
		end

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		WorldBossTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			f.Frame:Destroy()
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>WORLD BOSS " .. status:upper() .. "!</font>", true)

		if data.CustomLog then AddLog(data.CustomLog, true) end

		if status == "Victory" and data.Drops then
			AddLog("<font color='#55FF55'>+" .. (data.Drops.XP or 0) .. " XP, +¥" .. (data.Drops.Yen or 0) .. ".</font>", true)
			if data.Drops.Items and #data.Drops.Items > 0 then 
				AddLog("<font color='#FFFF55'>Loot Secured: " .. table.concat(data.Drops.Items, ", ") .. "</font>", true) 
			end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You fled the battle.</font>", true)
		end

		task.delay(4, function() 
			inBattle = false
			combatUI.MainFrame.Visible = false
			menuContainer.Visible = true
		end)
	end

	if data and data.Battle then
		local battle = data.Battle
		resourceLabel.Text = "STAMINA: " .. math.floor(battle.Player.Stamina) .. " | ENERGY: " .. math.floor(battle.Player.StandEnergy)

		local turnsLeft = 11 - (battle.TurnCounter or 1)
		turnLabel.Text = "Turns Remaining: " .. math.max(0, turnsLeft) .. "/10"

		SyncFighter("Player", true, "Player", battle.Player.Name, player.UserId, battle.Player.HP, battle.Player.MaxHP, battle.Player.Statuses, {Stun=battle.Player.StunImmunity, Confusion=battle.Player.ConfusionImmunity})
		if battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Player.Name .. " (KO)"
		end

		if battle.Enemy then
			SyncFighter("Enemy", false, "Enemy", battle.Enemy.Name, "", battle.Enemy.HP, battle.Enemy.MaxHP, battle.Enemy.Statuses, {Stun=battle.Enemy.StunImmunity, Confusion=battle.Enemy.ConfusionImmunity})
			if battle.Enemy.HP <= 0 and activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Enemy.Name .. " (KO)"
			end
		else
			if activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:Destroy()
				activeFighters["Enemy"] = nil
			end
		end

		if battle.Ally then
			SyncFighter("Ally", true, "Ally", battle.Ally.Name, "", battle.Ally.HP, battle.Ally.MaxHP, battle.Ally.Statuses, {Stun=battle.Ally.StunImmunity, Confusion=battle.Ally.ConfusionImmunity})
			if battle.Ally.HP <= 0 and activeFighters["Ally"] then
				activeFighters["Ally"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Ally.Name .. " (KO)"
			end
		else
			if activeFighters["Ally"] then
				activeFighters["Ally"].Frame:Destroy()
				activeFighters["Ally"] = nil
			end
		end
	end
end

function WorldBossTab.SystemMessage(msg) AddLog("" .. msg .. "", true) end

return WorldBossTab