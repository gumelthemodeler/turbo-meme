-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local player = Players.LocalPlayer
local MainFrame
local LogScroll, LogText, ActionGrid
local PlayerHPBar, PlayerHPText, PlayerNameText
local EnemyHPBar, EnemyHPText, EnemyNameText
local PlayerNrgBar, PlayerNrgText, PlayerNrgContainer
local WaveLabel, LeaveBtn

local isBattleActive = false
local inputLocked = false
local currentLog = ""

local function ShakeUI(intensity)
	if not intensity or intensity == "None" then return end
	local amount = (intensity == "Heavy") and 15 or 6
	local originalPos = UDim2.new(0, 0, 0, 0)

	task.spawn(function()
		for i = 1, 10 do
			if not MainFrame.Visible then break end
			local xOffset = math.random(-amount, amount)
			local yOffset = math.random(-amount, amount)
			MainFrame.Position = originalPos + UDim2.new(0, xOffset, 0, yOffset)
			task.wait(0.03)
		end
		MainFrame.Position = originalPos
	end)
end

local function CreateBar(parent, color, yPos, size, labelText)
	local container = Instance.new("Frame", parent)
	container.Size = size
	container.Position = UDim2.new(0, 0, 0, yPos)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
	Instance.new("UIStroke", container).Color = Color3.fromRGB(80, 80, 90)

	local fill = Instance.new("Frame", container)
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local text = Instance.new("TextLabel", container)
	text.Size = UDim2.new(1, -10, 1, 0)
	text.Position = UDim2.new(0, 5, 0, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 14
	text.TextStrokeTransparency = 0.5
	text.Text = labelText

	return fill, text, container
end

local function AddLogMessage(msgText, append)
	if not msgText or msgText == "" then return end
	if append then
		currentLog = currentLog .. "\n" .. msgText
	else
		currentLog = msgText
	end

	LogText.Text = currentLog

	task.defer(function()
		LogScroll.CanvasPosition = Vector2.new(0, LogText.AbsoluteSize.Y + 99999)
	end)
end

function CombatTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame.Parent)
	MainFrame.Name = "CombatFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	MainFrame.Visible = false
	MainFrame.ZIndex = 200

	WaveLabel = Instance.new("TextLabel", MainFrame)
	WaveLabel.Size = UDim2.new(1, 0, 0, 40)
	WaveLabel.Position = UDim2.new(0, 0, 0.02, 0)
	WaveLabel.BackgroundTransparency = 1
	WaveLabel.Font = Enum.Font.GothamBlack
	WaveLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
	WaveLabel.TextSize = 22
	WaveLabel.Text = "WAVE 1/1"

	local CenterArea = Instance.new("Frame", MainFrame)
	CenterArea.Size = UDim2.new(0.9, 0, 0.85, 0)
	CenterArea.Position = UDim2.new(0.05, 0, 0.1, 0)
	CenterArea.BackgroundTransparency = 1

	-- [[ PLAYER STATS ]]
	local PlayerPanel = Instance.new("Frame", CenterArea)
	PlayerPanel.Size = UDim2.new(0.4, 0, 0.2, 0)
	PlayerPanel.Position = UDim2.new(0, 0, 0, 0)
	PlayerPanel.BackgroundTransparency = 1

	PlayerNameText = Instance.new("TextLabel", PlayerPanel)
	PlayerNameText.Size = UDim2.new(1, 0, 0, 25); PlayerNameText.BackgroundTransparency = 1; PlayerNameText.Font = Enum.Font.GothamBlack; PlayerNameText.TextColor3 = Color3.fromRGB(255, 255, 255); PlayerNameText.TextSize = 18; PlayerNameText.TextXAlignment = Enum.TextXAlignment.Left
	PlayerNameText.Text = player.Name

	PlayerHPBar, PlayerHPText = CreateBar(PlayerPanel, Color3.fromRGB(60, 180, 60), 30, UDim2.new(1, 0, 0, 25), "HP: 100/100")
	PlayerNrgBar, PlayerNrgText, PlayerNrgContainer = CreateBar(PlayerPanel, Color3.fromRGB(255, 120, 40), 60, UDim2.new(0.8, 0, 0, 18), "TITAN HEAT: 0/100")

	-- [[ ENEMY STATS ]]
	local EnemyPanel = Instance.new("Frame", CenterArea)
	EnemyPanel.Size = UDim2.new(0.4, 0, 0.2, 0)
	EnemyPanel.Position = UDim2.new(0.6, 0, 0, 0)
	EnemyPanel.BackgroundTransparency = 1

	EnemyNameText = Instance.new("TextLabel", EnemyPanel)
	EnemyNameText.Size = UDim2.new(1, 0, 0, 25); EnemyNameText.BackgroundTransparency = 1; EnemyNameText.Font = Enum.Font.GothamBlack; EnemyNameText.TextColor3 = Color3.fromRGB(255, 80, 80); EnemyNameText.TextSize = 18; EnemyNameText.TextXAlignment = Enum.TextXAlignment.Right
	EnemyNameText.Text = "Enemy Target"

	EnemyHPBar, EnemyHPText = CreateBar(EnemyPanel, Color3.fromRGB(200, 60, 60), 30, UDim2.new(1, 0, 0, 25), "HP: 100/100")

	-- [[ COMBAT FEED ]]
	local FeedBox = Instance.new("Frame", CenterArea)
	FeedBox.Size = UDim2.new(1, 0, 0.45, 0)
	FeedBox.Position = UDim2.new(0, 0, 0.25, 0)
	FeedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", FeedBox).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", FeedBox).Color = Color3.fromRGB(120, 100, 60)

	LogScroll = Instance.new("ScrollingFrame", FeedBox)
	LogScroll.Size = UDim2.new(1, -20, 1, -20)
	LogScroll.Position = UDim2.new(0, 10, 0, 10)
	LogScroll.BackgroundTransparency = 1
	LogScroll.BorderSizePixel = 0
	LogScroll.ScrollBarThickness = 6
	LogScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
	LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y 

	-- Centralized Single TextLabel (Guarantees Text Shows)
	LogText = Instance.new("TextLabel", LogScroll)
	LogText.Size = UDim2.new(1, -5, 0, 0)
	LogText.AutomaticSize = Enum.AutomaticSize.Y
	LogText.BackgroundTransparency = 1
	LogText.Font = Enum.Font.GothamMedium
	LogText.TextColor3 = Color3.fromRGB(230, 230, 230)
	LogText.TextSize = 15
	LogText.TextXAlignment = Enum.TextXAlignment.Left
	LogText.TextYAlignment = Enum.TextYAlignment.Top
	LogText.TextWrapped = true
	LogText.RichText = true
	LogText.Text = ""

	-- [[ ACTION GRID ]]
	ActionGrid = Instance.new("Frame", CenterArea)
	ActionGrid.Size = UDim2.new(1, 0, 0.25, 0)
	ActionGrid.Position = UDim2.new(0, 0, 0.75, 0)
	ActionGrid.BackgroundTransparency = 1

	local gridLayout = Instance.new("UIGridLayout", ActionGrid)
	gridLayout.CellSize = UDim2.new(0.31, 0, 0, 45) -- Fits 3 columns nicely
	gridLayout.CellPadding = UDim2.new(0.02, 0, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- [[ LEAVE BATTLE BUTTON ]]
	LeaveBtn = Instance.new("TextButton", MainFrame)
	LeaveBtn.Size = UDim2.new(0.3, 0, 0, 50)
	LeaveBtn.Position = UDim2.new(0.35, 0, 0.9, 0)
	LeaveBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
	LeaveBtn.Font = Enum.Font.GothamBlack; LeaveBtn.TextColor3 = Color3.fromRGB(25, 25, 30); LeaveBtn.TextSize = 18; LeaveBtn.Text = "RETURN TO BASE"
	LeaveBtn.Visible = false
	Instance.new("UICorner", LeaveBtn).CornerRadius = UDim.new(0, 6)

	LeaveBtn.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
		isBattleActive = false
		parentFrame.Parent.TopBar.Visible = true
		parentFrame.Parent.NavBar.Visible = true
	end)

	-- [[ DYNAMIC SKILL POPULATION & LOCKING ]]
	local function LockGrid()
		inputLocked = true
		for _, btn in ipairs(ActionGrid:GetChildren()) do
			if btn:IsA("TextButton") then
				btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
				btn.UIStroke.Color = Color3.fromRGB(30, 30, 35)
				btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			end
		end
	end

	local function UpdateActionGrid(battleState)
		inputLocked = false
		for _, child in ipairs(ActionGrid:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		local p = battleState.Player
		local pStyle = p.Style or "None"
		local pTitan = p.Titan or "None"

		local function CreateBtn(sName, color, order)
			local sData = SkillData.Skills[sName]
			if not sData then return end

			local cd = p.Cooldowns and p.Cooldowns[sName] or 0
			local isReady = (cd == 0)

			local btn = Instance.new("TextButton", ActionGrid)
			btn.BackgroundColor3 = isReady and (color or Color3.fromRGB(30, 30, 35)) or Color3.fromRGB(20, 20, 25)
			btn.Font = Enum.Font.GothamBold
			btn.TextColor3 = isReady and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
			btn.TextSize = 15
			btn.LayoutOrder = order or 10
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			Instance.new("UIStroke", btn).Color = isReady and Color3.fromRGB(120, 100, 60) or Color3.fromRGB(50, 50, 55)

			local cdStr = isReady and "READY" or "CD: " .. cd
			btn.Text = sName:upper() .. "\n<font size='11' color='" .. (isReady and "#AAAAAA" or "#FF5555") .. "'>[" .. cdStr .. "]</font>"
			btn.RichText = true

			btn.MouseButton1Click:Connect(function()
				if isBattleActive and not inputLocked and isReady then
					LockGrid() 
					Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = sName})
				end
			end)
		end

		CreateBtn("Basic Slash", Color3.fromRGB(120, 40, 40), 1)
		CreateBtn("Maneuver", Color3.fromRGB(40, 80, 140), 2)
		CreateBtn("Recover", Color3.fromRGB(40, 140, 80), 3)
		CreateBtn("Retreat", Color3.fromRGB(60, 60, 70), 4)

		local orderIndex = 5
		for sName, sData in pairs(SkillData.Skills) do
			if sName == "Basic Slash" or sName == "Maneuver" or sName == "Recover" or sName == "Retreat" or sName == "Block" or sName == "Regroup" then continue end
			local req = sData.Requirement
			if req == pStyle or req == pTitan or (req == "AnyTitan" and pTitan ~= "None") then
				CreateBtn(sName, Color3.fromRGB(45, 40, 60), sData.Order or orderIndex)
				orderIndex += 1
			end
		end
	end

	-- [[ EVENT LISTENERS ]]
	local function SyncBars(battleState)
		local p = battleState.Player
		local e = battleState.Enemy
		local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

		TweenService:Create(PlayerHPBar, tInfo, {Size = UDim2.new(math.clamp(p.HP / p.MaxHP, 0, 1), 0, 1, 0)}):Play()
		PlayerHPText.Text = "HP: " .. math.floor(p.HP) .. " / " .. math.floor(p.MaxHP)

		-- Only show Titan Heat if they are a shifter
		if p.Titan and p.Titan ~= "None" then
			PlayerNrgContainer.Visible = true
			local pNrg = p.TitanEnergy or p.TitanHeat or 0
			local pMaxNrg = 100
			TweenService:Create(PlayerNrgBar, tInfo, {Size = UDim2.new(math.clamp(pNrg / pMaxNrg, 0, 1), 0, 1, 0)}):Play()
			PlayerNrgText.Text = "TITAN HEAT: " .. math.floor(pNrg) .. " / " .. math.floor(pMaxNrg)
		else
			PlayerNrgContainer.Visible = false
		end

		EnemyNameText.Text = e.Name:upper()
		TweenService:Create(EnemyHPBar, tInfo, {Size = UDim2.new(math.clamp(e.HP / e.MaxHP, 0, 1), 0, 1, 0)}):Play()
		EnemyHPText.Text = "HP: " .. math.floor(e.HP) .. " / " .. math.floor(e.MaxHP)

		if battleState.Context.IsStoryMission then
			WaveLabel.Text = "WAVE " .. battleState.Context.CurrentWave .. " / " .. battleState.Context.TotalWaves
		else
			WaveLabel.Text = "RANDOM ENCOUNTER"
		end
	end

	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Start" then
			currentLog = ""
			LogText.Text = ""
			MainFrame.Visible = true
			parentFrame.Parent.TopBar.Visible = false
			parentFrame.Parent.NavBar.Visible = false
			LeaveBtn.Visible = false
			isBattleActive = true

			SyncBars(data.Battle)
			UpdateActionGrid(data.Battle)
			AddLogMessage(data.LogMsg, false)

		elseif action == "TurnStrike" then
			ShakeUI(data.ShakeType)
			SyncBars(data.Battle)
			AddLogMessage(data.LogMsg, true)

		elseif action == "Update" then
			SyncBars(data.Battle)
			UpdateActionGrid(data.Battle)

		elseif action == "WaveComplete" then
			SyncBars(data.Battle)
			AddLogMessage(data.LogMsg, true)
			AddLogMessage("<font color='#55FF55'>Rewards: +" .. data.XP .. " XP | +" .. data.Yen .. " Dews</font>", true)
			UpdateActionGrid(data.Battle)

		elseif action == "Victory" then
			SyncBars(data.Battle)
			isBattleActive = false
			LockGrid()
			LeaveBtn.Visible = true
			LeaveBtn.Text = "VICTORY - RETURN"
			LeaveBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)

			AddLogMessage("\n<b><font color='#55FF55'>ENEMY DEFEATED!</font></b>", true)
			AddLogMessage("<font color='#55FF55'>Rewards: +" .. data.XP .. " XP | +" .. data.Yen .. " Dews</font>", true)

		elseif action == "Defeat" then
			SyncBars(data.Battle)
			isBattleActive = false
			LockGrid()
			LeaveBtn.Visible = true
			LeaveBtn.Text = "DEFEAT - RETREAT"
			LeaveBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)

			AddLogMessage("\n<b><font color='#FF5555'>YOU WERE SLAUGHTERED.</font></b>", true)

		elseif action == "Fled" then
			isBattleActive = false
			LockGrid()
			LeaveBtn.Visible = true
			LeaveBtn.Text = "COWARD - RETURN"
			LeaveBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)
end

return CombatTab