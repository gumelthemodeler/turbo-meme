-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local StoryTab = require(script.Parent:WaitForChild("StoryTab"))
local EffectsManager = require(script.Parent:WaitForChild("EffectsManager"))

local player = Players.LocalPlayer
local MainFrame
local LogText, ActionGrid
local PlayerHPBar, PlayerHPText, PlayerNameText, PlayerStatusBox, PlayerGasBar, PlayerGasText
local EnemyHPBar, EnemyHPText, EnemyNameText, EnemyStatusBox, EnemyShieldBar
local PlayerNrgBar, PlayerNrgText, PlayerNrgContainer
local WaveLabel, LeaveBtn
local pAvatarBox, eAvatarBox

local isBattleActive = false
local inputLocked = false
local logMessages = {}
local MAX_LOG_MESSAGES = 2 

local function AddLogMessage(msgText, append)
	if not msgText or msgText == "" then return end
	if append then table.insert(logMessages, msgText); if #logMessages > MAX_LOG_MESSAGES then table.remove(logMessages, 1) end
	else logMessages = {msgText} end
	LogText.Text = table.concat(logMessages, "\n\n")
end

local function ShakeUI(intensity)
	if not intensity or intensity == "None" then return end
	local amount = (intensity == "Heavy") and 15 or 6
	local originalPos = UDim2.new(0.5, 0, 0.48, 0)
	task.spawn(function()
		for i = 1, 10 do
			if not MainFrame.Visible then break end
			local xOffset = math.random(-amount, amount); local yOffset = math.random(-amount, amount)
			MainFrame.Position = originalPos + UDim2.new(0, xOffset, 0, yOffset)
			task.wait(0.03)
		end
		MainFrame.Position = originalPos
	end)
end

local function CreateBar(parent, color1, color2, size, labelText)
	local container = Instance.new("Frame", parent)
	container.Size = size; container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", container).Color = Color3.fromRGB(80, 80, 90)

	local fill = Instance.new("Frame", container)
	fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	local grad = Instance.new("UIGradient", fill); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}; grad.Rotation = 90

	local text = Instance.new("TextLabel", container)
	text.Size = UDim2.new(1, -10, 1, 0); text.Position = UDim2.new(0, 5, 0, 0); text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold; text.TextColor3 = Color3.fromRGB(255, 255, 255); text.TextSize = 13; text.TextStrokeTransparency = 0.5; text.Text = labelText
	return fill, text, container
end

local function RenderStatuses(container, combatant)
	for _, child in ipairs(container:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local function addIcon(iconTxt, bgColor, strokeColor)
		local f = Instance.new("Frame", container)
		f.Size = UDim2.new(0, 22, 0, 22); f.BackgroundColor3 = bgColor; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", f).Color = strokeColor
		local t = Instance.new("TextLabel", f)
		t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.Text = iconTxt; t.TextColor3 = Color3.fromRGB(255,255,255); t.TextScaled = true
	end

	if combatant.Statuses then
		if combatant.Statuses.Dodge and combatant.Statuses.Dodge > 0 then addIcon("💨", Color3.fromRGB(30, 60, 120), Color3.fromRGB(60, 100, 200)) end
		if combatant.Statuses.Transformed and combatant.Statuses.Transformed > 0 then addIcon("💀", Color3.fromRGB(150, 40, 40), Color3.fromRGB(200, 60, 60)) end
		for sName, duration in pairs(combatant.Statuses) do
			if duration > 0 then
				if sName == "Bleed" then addIcon("🩸", Color3.fromRGB(120, 20, 20), Color3.fromRGB(200, 40, 40))
				elseif sName == "Stun" then addIcon("⚡", Color3.fromRGB(120, 120, 20), Color3.fromRGB(200, 200, 40))
				elseif sName == "Burn" then addIcon("🔥", Color3.fromRGB(150, 60, 10), Color3.fromRGB(220, 100, 20))
				elseif sName == "Buff_Strength" or sName == "Buff_Defense" then addIcon("🔺", Color3.fromRGB(20, 120, 20), Color3.fromRGB(40, 200, 40))
				elseif sName == "Debuff_Strength" or sName == "Debuff_Defense" then addIcon("🔻", Color3.fromRGB(120, 40, 20), Color3.fromRGB(200, 60, 40))
				end
			end
		end
	end
end

function CombatTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	StoryTab.Init(parentFrame, tooltipMgr, nil, nil)
	EffectsManager.Init()

	MainFrame = Instance.new("Frame", parentFrame.Parent)
	MainFrame.Name = "CombatFrame"; MainFrame.Size = UDim2.new(0.75, 0, 0.75, 0); MainFrame.Position = UDim2.new(0.5, 0, 0.48, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); MainFrame.Visible = false; MainFrame.ZIndex = 200
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
	local outerStroke = Instance.new("UIStroke", MainFrame); outerStroke.Thickness = 3; outerStroke.Color = Color3.fromRGB(255, 210, 60)

	WaveLabel = Instance.new("TextLabel", MainFrame); WaveLabel.Size = UDim2.new(0.3, 0, 0, 30); WaveLabel.Position = UDim2.new(0.5, 0, 0.02, 0); WaveLabel.AnchorPoint = Vector2.new(0.5, 0); WaveLabel.BackgroundTransparency = 1; WaveLabel.Font = Enum.Font.GothamBlack; WaveLabel.TextColor3 = Color3.fromRGB(255, 215, 100); WaveLabel.TextSize = 18; WaveLabel.Text = "WAVE 1/1"; WaveLabel.ZIndex = 205

	local TopArea = Instance.new("Frame", MainFrame); TopArea.Size = UDim2.new(0.96, 0, 0.28, 0); TopArea.Position = UDim2.new(0.02, 0, 0.04, 0); TopArea.BackgroundTransparency = 1

	local PlayerPanel = Instance.new("Frame", TopArea); PlayerPanel.Size = UDim2.new(0.45, 0, 1, 0); PlayerPanel.BackgroundTransparency = 1
	pAvatarBox = Instance.new("Frame", PlayerPanel); pAvatarBox.Size = UDim2.new(0.25, 0, 1, 0); pAvatarBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15); Instance.new("UIStroke", pAvatarBox).Color = Color3.fromRGB(255, 255, 255); Instance.new("UIStroke", pAvatarBox).Thickness = 2
	local pAspect = Instance.new("UIAspectRatioConstraint", pAvatarBox); pAspect.AspectRatio = 1; pAspect.DominantAxis = Enum.DominantAxis.Height
	local pAvatarImg = Instance.new("ImageLabel", pAvatarBox); pAvatarImg.Size = UDim2.new(1, 0, 1, 0); pAvatarImg.BackgroundTransparency = 1; pAvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"

	local pStatsArea = Instance.new("Frame", PlayerPanel); pStatsArea.Size = UDim2.new(0.7, 0, 1, 0); pStatsArea.Position = UDim2.new(0.3, 0, 0, 0); pStatsArea.BackgroundTransparency = 1
	local pLayout = Instance.new("UIListLayout", pStatsArea); pLayout.SortOrder = Enum.SortOrder.LayoutOrder; pLayout.Padding = UDim.new(0, 4)

	PlayerNameText = Instance.new("TextLabel", pStatsArea); PlayerNameText.Size = UDim2.new(1, 0, 0, 20); PlayerNameText.BackgroundTransparency = 1; PlayerNameText.Font = Enum.Font.GothamBlack; PlayerNameText.TextColor3 = Color3.fromRGB(255, 255, 255); PlayerNameText.TextSize = 16; PlayerNameText.TextXAlignment = Enum.TextXAlignment.Left; PlayerNameText.Text = player.Name

	PlayerHPBar, PlayerHPText = CreateBar(pStatsArea, Color3.fromRGB(220, 40, 40), Color3.fromRGB(120, 20, 20), UDim2.new(1, 0, 0, 22), "HP: 100/100")
	PlayerGasBar, PlayerGasText = CreateBar(pStatsArea, Color3.fromRGB(150, 220, 255), Color3.fromRGB(60, 140, 200), UDim2.new(0.8, 0, 0, 14), "GAS: 100/100")
	PlayerNrgBar, PlayerNrgText, PlayerNrgContainer = CreateBar(pStatsArea, Color3.fromRGB(255, 150, 50), Color3.fromRGB(180, 80, 20), UDim2.new(0.8, 0, 0, 14), "TITAN HEAT: 0/100")
	PlayerNrgContainer.Visible = false

	PlayerStatusBox = Instance.new("Frame", pStatsArea); PlayerStatusBox.Size = UDim2.new(1, 0, 0, 25); PlayerStatusBox.BackgroundTransparency = 1; local pStatusLayout = Instance.new("UIListLayout", PlayerStatusBox); pStatusLayout.FillDirection = Enum.FillDirection.Horizontal; pStatusLayout.Padding = UDim.new(0, 5)

	local EnemyPanel = Instance.new("Frame", TopArea); EnemyPanel.Size = UDim2.new(0.45, 0, 1, 0); EnemyPanel.Position = UDim2.new(0.55, 0, 0, 0); EnemyPanel.BackgroundTransparency = 1
	eAvatarBox = Instance.new("Frame", EnemyPanel); eAvatarBox.Size = UDim2.new(0.25, 0, 1, 0); eAvatarBox.Position = UDim2.new(1, 0, 0, 0); eAvatarBox.AnchorPoint = Vector2.new(1, 0); eAvatarBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0); Instance.new("UIStroke", eAvatarBox).Color = Color3.fromRGB(255, 255, 255); Instance.new("UIStroke", eAvatarBox).Thickness = 2
	local eAspect = Instance.new("UIAspectRatioConstraint", eAvatarBox); eAspect.AspectRatio = 1; eAspect.DominantAxis = Enum.DominantAxis.Height
	local eAvatarIcon = Instance.new("TextLabel", eAvatarBox); eAvatarIcon.Size = UDim2.new(1, 0, 1, 0); eAvatarIcon.BackgroundTransparency = 1; eAvatarIcon.Font = Enum.Font.GothamBlack; eAvatarIcon.TextColor3 = Color3.fromRGB(255, 0, 0); eAvatarIcon.TextScaled = true; eAvatarIcon.Text = "?"

	local eStatsArea = Instance.new("Frame", EnemyPanel); eStatsArea.Size = UDim2.new(0.7, 0, 1, 0); eStatsArea.BackgroundTransparency = 1; local eLayout = Instance.new("UIListLayout", eStatsArea); eLayout.SortOrder = Enum.SortOrder.LayoutOrder; eLayout.Padding = UDim.new(0, 4)

	EnemyNameText = Instance.new("TextLabel", eStatsArea); EnemyNameText.Size = UDim2.new(1, 0, 0, 20); EnemyNameText.BackgroundTransparency = 1; EnemyNameText.Font = Enum.Font.GothamBlack; EnemyNameText.TextColor3 = Color3.fromRGB(255, 80, 80); EnemyNameText.TextSize = 16; EnemyNameText.TextXAlignment = Enum.TextXAlignment.Right

	local eHpCont
	EnemyHPBar, EnemyHPText, eHpCont = CreateBar(eStatsArea, Color3.fromRGB(220, 40, 40), Color3.fromRGB(120, 20, 20), UDim2.new(1, 0, 0, 22), "HP: 100/100")
	EnemyShieldBar = Instance.new("Frame", eHpCont); EnemyShieldBar.Size = UDim2.new(0, 0, 1, 0); EnemyShieldBar.BackgroundColor3 = Color3.fromRGB(220, 230, 240); Instance.new("UICorner", EnemyShieldBar).CornerRadius = UDim.new(0, 4); EnemyShieldBar.ZIndex = 5; EnemyHPText.ZIndex = 6

	EnemyStatusBox = Instance.new("Frame", eStatsArea); EnemyStatusBox.Size = UDim2.new(1, 0, 0, 25); EnemyStatusBox.BackgroundTransparency = 1; local eStatusLayout = Instance.new("UIListLayout", EnemyStatusBox); eStatusLayout.FillDirection = Enum.FillDirection.Horizontal; eStatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; eStatusLayout.Padding = UDim.new(0, 5)

	local FeedBox = Instance.new("Frame", MainFrame); FeedBox.Size = UDim2.new(0.96, 0, 0.18, 0); FeedBox.Position = UDim2.new(0.02, 0, 0.35, 0); FeedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25); FeedBox.ClipsDescendants = true; Instance.new("UICorner", FeedBox).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", FeedBox).Color = Color3.fromRGB(0, 0, 0); Instance.new("UIStroke", FeedBox).Thickness = 2
	LogText = Instance.new("TextLabel", FeedBox); LogText.Size = UDim2.new(1, -20, 1, -10); LogText.Position = UDim2.new(0, 10, 0, 5); LogText.BackgroundTransparency = 1; LogText.Font = Enum.Font.GothamMedium; LogText.TextColor3 = Color3.fromRGB(230, 230, 230); LogText.TextSize = 14; LogText.TextXAlignment = Enum.TextXAlignment.Left; LogText.TextYAlignment = Enum.TextYAlignment.Bottom; LogText.TextWrapped = true; LogText.RichText = true; LogText.Text = ""

	local BottomArea = Instance.new("Frame", MainFrame); BottomArea.Size = UDim2.new(0.96, 0, 0.40, 0); BottomArea.Position = UDim2.new(0.02, 0, 0.56, 0); BottomArea.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Instance.new("UICorner", BottomArea).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BottomArea).Color = Color3.fromRGB(0, 0, 0); Instance.new("UIStroke", BottomArea).Thickness = 2

	ActionGrid = Instance.new("ScrollingFrame", BottomArea); ActionGrid.Size = UDim2.new(1, -20, 1, -20); ActionGrid.Position = UDim2.new(0, 10, 0, 10); ActionGrid.BackgroundTransparency = 1; ActionGrid.ScrollBarThickness = 6; ActionGrid.BorderSizePixel = 0; ActionGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y; ActionGrid.CanvasSize = UDim2.new(0,0,0,0)
	local gridLayout = Instance.new("UIGridLayout", ActionGrid); gridLayout.CellSize = UDim2.new(0.31, 0, 0, 40); gridLayout.CellPadding = UDim2.new(0.02, 0, 0, 10); gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	LeaveBtn = Instance.new("TextButton", MainFrame); LeaveBtn.Size = UDim2.new(0.4, 0, 0, 50); LeaveBtn.Position = UDim2.new(0.3, 0, 0.65, 0); LeaveBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 80); LeaveBtn.Font = Enum.Font.GothamBlack; LeaveBtn.TextColor3 = Color3.fromRGB(25, 25, 30); LeaveBtn.TextSize = 18; LeaveBtn.Text = "RETURN TO BASE"; LeaveBtn.Visible = false; Instance.new("UICorner", LeaveBtn).CornerRadius = UDim.new(0, 6)

	LeaveBtn.MouseButton1Click:Connect(function()
		EffectsManager.PlaySFX("Click")
		MainFrame.Visible = false; isBattleActive = false
		parentFrame.Visible = true -- THE FIX: Shows the background menus again!

		local topGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
		if topGui then
			if topGui:FindFirstChild("TopBar") then topGui.TopBar.Visible = true end
			if topGui:FindFirstChild("NavBar") then topGui.NavBar.Visible = true end
		end
	end)

	local function LockGrid()
		inputLocked = true
		for _, btn in ipairs(ActionGrid:GetChildren()) do
			if btn:IsA("TextButton") then
				btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20); btn.UIStroke.Color = Color3.fromRGB(30, 30, 35); btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			end
		end
	end

	local function UpdateActionGrid(battleState)
		inputLocked = false
		for _, child in ipairs(ActionGrid:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

		local p = battleState.Player
		local pStyle = p.Style or "None"
		local pTitan = p.Titan or "None"
		local pClan = p.Clan or "None"
		local isTransformed = p.Statuses and p.Statuses["Transformed"]
		local isODM = (pStyle == "Ultrahard Steel Blades" or pStyle == "Thunder Spears" or pStyle == "Anti-Personnel")

		local function CreateBtn(sName, color, order)
			local sData = SkillData.Skills[sName]
			if not sData then return end

			if sName == "Transform" and (pClan == "Ackerman" or pClan == "Awakened Ackerman") then return end

			local cd = p.Cooldowns and p.Cooldowns[sName] or 0
			local energyCost = sData.EnergyCost or 0
			local gasCost = sData.GasCost or 0

			local hasGas = (p.Gas or 0) >= gasCost
			local hasEnergy = (p.TitanEnergy or 0) >= energyCost
			local isReady = (cd == 0) and hasGas and hasEnergy

			local btn = Instance.new("TextButton", ActionGrid)
			btn.BackgroundColor3 = isReady and (color or Color3.fromRGB(30, 30, 35)) or Color3.fromRGB(20, 20, 25)
			btn.Font = Enum.Font.GothamBold; btn.TextColor3 = isReady and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120); btn.TextSize = 13; btn.LayoutOrder = order or 10
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			Instance.new("UIStroke", btn).Color = isReady and Color3.fromRGB(120, 100, 60) or Color3.fromRGB(50, 50, 55)

			local cdStr = isReady and "READY" or "CD: " .. cd
			if cd == 0 then
				if not hasGas then cdStr = "NO GAS" elseif not hasEnergy then cdStr = "NO HEAT" end
			end

			btn.Text = sName:upper() .. "\n<font size='10' color='" .. (isReady and "#AAAAAA" or "#FF5555") .. "'>[" .. cdStr .. "]</font>"; btn.RichText = true

			btn.MouseButton1Click:Connect(function()
				if isBattleActive and not inputLocked and isReady then
					if tooltipMgr then tooltipMgr.Hide() end
					LockGrid() 
					Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = sName})
				end
			end)
			btn.MouseEnter:Connect(function() if tooltipMgr then tooltipMgr.Show(sData.Description or sName) end end)
			btn.MouseLeave:Connect(function() if tooltipMgr then tooltipMgr.Hide() end end)
		end

		if isTransformed then
			CreateBtn("Titan Recover", Color3.fromRGB(40, 140, 80), 1)
			CreateBtn("Titan Punch", Color3.fromRGB(120, 40, 40), 2)
			CreateBtn("Titan Kick", Color3.fromRGB(140, 60, 40), 3)
			CreateBtn("Eject", Color3.fromRGB(140, 40, 40), 4)

			local orderIndex = 5
			for sName, sData in pairs(SkillData.Skills) do
				if sName == "Titan Recover" or sName == "Eject" or sName == "Titan Punch" or sName == "Titan Kick" then continue end
				if sData.Requirement == pTitan or sData.Requirement == "AnyTitan" or sData.Requirement == "Transformed" then
					CreateBtn(sName, Color3.fromRGB(60, 40, 60), sData.Order or orderIndex)
					orderIndex += 1
				end
			end
		else
			CreateBtn("Basic Slash", Color3.fromRGB(120, 40, 40), 1)
			CreateBtn("Maneuver", Color3.fromRGB(40, 80, 140), 2)
			CreateBtn("Recover", Color3.fromRGB(40, 140, 80), 3)
			CreateBtn("Retreat", Color3.fromRGB(60, 60, 70), 4)

			if pTitan ~= "None" and pClan ~= "Ackerman" and pClan ~= "Awakened Ackerman" then
				CreateBtn("Transform", Color3.fromRGB(200, 150, 50), 5)
			end

			local orderIndex = 6
			for sName, sData in pairs(SkillData.Skills) do
				if sName == "Basic Slash" or sName == "Maneuver" or sName == "Recover" or sName == "Retreat" or sName == "Transform" then continue end
				local req = sData.Requirement
				if req == pStyle or req == pClan or (req == "Ackerman" and pClan == "Awakened Ackerman") or (req == "ODM" and isODM) then
					CreateBtn(sName, Color3.fromRGB(45, 40, 60), sData.Order or orderIndex)
					orderIndex += 1
				end
			end
		end

		task.delay(0.05, function() ActionGrid.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20) end)
	end

	local function SyncBars(battleState)
		local p = battleState.Player
		local e = battleState.Enemy
		local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

		TweenService:Create(PlayerHPBar, tInfo, {Size = UDim2.new(math.clamp(p.HP / p.MaxHP, 0, 1), 0, 1, 0)}):Play()
		PlayerHPText.Text = "HP: " .. math.floor(p.HP) .. " / " .. math.floor(p.MaxHP)
		PlayerNameText.Text = player.Name

		TweenService:Create(PlayerGasBar, tInfo, {Size = UDim2.new(math.clamp(p.Gas / p.MaxGas, 0, 1), 0, 1, 0)}):Play()
		PlayerGasText.Text = "GAS: " .. math.floor(p.Gas) .. " / " .. math.floor(p.MaxGas)

		if p.Titan and p.Titan ~= "None" then
			PlayerNrgContainer.Visible = true
			local pNrg = p.TitanEnergy or 0
			TweenService:Create(PlayerNrgBar, tInfo, {Size = UDim2.new(math.clamp(pNrg / 100, 0, 1), 0, 1, 0)}):Play()
			PlayerNrgText.Text = "TITAN HEAT: " .. math.floor(pNrg) .. " / 100"
		else
			PlayerNrgContainer.Visible = false
		end

		EnemyNameText.Text = e.Name:upper()

		if e.MaxGateHP and e.MaxGateHP > 0 then
			EnemyShieldBar.Visible = true
			TweenService:Create(EnemyShieldBar, tInfo, {Size = UDim2.new(math.clamp(e.GateHP / e.MaxGateHP, 0, 1), 0, 1, 0)}):Play()
			if e.GateHP > 0 then
				if e.GateType == "Steam" then EnemyHPText.Text = e.GateType:upper() .. ": " .. math.floor(e.GateHP) .. " TURNS LEFT"
				else EnemyHPText.Text = e.GateType:upper() .. ": " .. math.floor(e.GateHP) .. " / " .. math.floor(e.MaxGateHP) end
			else EnemyHPText.Text = "HP: " .. math.floor(e.HP) .. " / " .. math.floor(e.MaxHP) end
		else
			EnemyShieldBar.Visible = false
			EnemyHPText.Text = "HP: " .. math.floor(e.HP) .. " / " .. math.floor(e.MaxHP)
		end

		TweenService:Create(EnemyHPBar, tInfo, {Size = UDim2.new(math.clamp(e.HP / e.MaxHP, 0, 1), 0, 1, 0)}):Play()

		RenderStatuses(PlayerStatusBox, p)
		RenderStatuses(EnemyStatusBox, e)

		if battleState.Context.IsStoryMission then WaveLabel.Text = "WAVE " .. battleState.Context.CurrentWave .. " / " .. battleState.Context.TotalWaves
		else WaveLabel.Text = "RANDOM ENCOUNTER" end
	end

	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Start" then
			MainFrame.Visible = true
			parentFrame.Visible = false -- THE FIX: Hides the background menus during combat!

			local topGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
			if topGui then
				if topGui:FindFirstChild("TopBar") then topGui.TopBar.Visible = false end
				if topGui:FindFirstChild("NavBar") then topGui.NavBar.Visible = false end
			end
			LeaveBtn.Visible = false; BottomArea.Visible = true; isBattleActive = true

			SyncBars(data.Battle); UpdateActionGrid(data.Battle); AddLogMessage(data.LogMsg, false)

		elseif action == "TurnStrike" then
			ShakeUI(data.ShakeType); SyncBars(data.Battle); AddLogMessage(data.LogMsg, true)

			if data.SkillUsed then
				EffectsManager.PlayCombatEffect(data.SkillUsed, data.IsPlayerAttacking, pAvatarBox, eAvatarBox, data.DidHit)
			end

		elseif action == "Update" then
			SyncBars(data.Battle); UpdateActionGrid(data.Battle)

		elseif action == "WaveComplete" then
			SyncBars(data.Battle); AddLogMessage(data.LogMsg, false)
			local xpAmt = data.XP or 0; local dewsAmt = data.Dews or 0
			local rewardStr = "<font color='#55FF55'>Rewards: +" .. xpAmt .. " XP | +" .. dewsAmt .. " Dews</font>"
			if data.Items and #data.Items > 0 then rewardStr = rewardStr .. "<br/><font color='#AA55FF'>Drops: " .. table.concat(data.Items, ", ") .. "</font>" end
			AddLogMessage(rewardStr, true); UpdateActionGrid(data.Battle)

		elseif action == "Victory" then
			-- THE FIX: Play Victory SFX
			EffectsManager.PlaySFX("Victory", 1)

			SyncBars(data.Battle); isBattleActive = false; LockGrid()
			BottomArea.Visible = false; LeaveBtn.Visible = true; LeaveBtn.Text = "VICTORY - RETURN"; LeaveBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			AddLogMessage("<b><font color='#55FF55'>ENEMY DEFEATED!</font></b>", false)
			local xpAmt = data.XP or 0; local dewsAmt = data.Dews or 0
			local rewardStr = "<font color='#55FF55'>Rewards: +" .. xpAmt .. " XP | +" .. dewsAmt .. " Dews</font>"
			if data.Items and #data.Items > 0 then rewardStr = rewardStr .. "<br/><font color='#AA55FF'>Drops: " .. table.concat(data.Items, ", ") .. "</font>" end
			AddLogMessage(rewardStr, true)

		elseif action == "Defeat" then
			-- THE FIX: Play Defeat SFX
			EffectsManager.PlaySFX("Defeat", 1)

			SyncBars(data.Battle); isBattleActive = false; LockGrid()
			BottomArea.Visible = false; LeaveBtn.Visible = true; LeaveBtn.Text = "DEFEAT - RETREAT"; LeaveBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
			AddLogMessage("<b><font color='#FF5555'>YOU WERE SLAUGHTERED.</font></b>", false)

		elseif action == "Fled" then
			EffectsManager.PlaySFX("Flee", 1)
			isBattleActive = false; LockGrid()
			BottomArea.Visible = false; LeaveBtn.Visible = true; LeaveBtn.Text = "COWARD - RETURN"; LeaveBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			AddLogMessage("<b><font color='#AAAAAA'>You fired a smoke signal and fled.</font></b>", false)
		end
	end)
end

function CombatTab.Show()
end

return CombatTab