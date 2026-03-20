-- @ScriptType: LocalScript
-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

local AOT_Interface = Instance.new("ScreenGui")
AOT_Interface.Name = "AOT_Interface"
AOT_Interface.ResetOnSpawn = false
AOT_Interface.IgnoreGuiInset = true
AOT_Interface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AOT_Interface.Parent = playerGui

local WorldBlocker = Instance.new("Frame")
WorldBlocker.Size = UDim2.new(1, 0, 1, 0)
WorldBlocker.BackgroundColor3 = Color3.fromRGB(10, 10, 12) 
WorldBlocker.BorderSizePixel = 0
WorldBlocker.ZIndex = -10
WorldBlocker.Parent = AOT_Interface

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.Position = UDim2.new(0, 0, 0, -50) 
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 100
TopBar.Parent = AOT_Interface

Instance.new("UIStroke", TopBar).Color = Color3.fromRGB(120, 100, 60); TopBar.UIStroke.Thickness = 2; TopBar.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local tbl = Instance.new("UIListLayout", TopBar); tbl.FillDirection = Enum.FillDirection.Horizontal; tbl.HorizontalAlignment = Enum.HorizontalAlignment.Right; tbl.VerticalAlignment = Enum.VerticalAlignment.Center; tbl.Padding = UDim.new(0, 20)
local tbp = Instance.new("UIPadding", TopBar); tbp.PaddingRight = UDim.new(0, 20)

local function CreateStatDisplay(name, prefixText, color)
	local container = Instance.new("Frame")
	container.Name = name .. "Container"
	container.Size = UDim2.new(0, 160, 0, 35)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	container.Parent = TopBar
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
	Instance.new("UIStroke", container).Color = Color3.fromRGB(60, 60, 65)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -15, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Text = prefixText .. " 0"
	label.Parent = container

	local uic = Instance.new("UITextSizeConstraint", label); uic.MaxTextSize = 16; uic.MinTextSize = 10
	return label
end

local dewsLabel = CreateStatDisplay("Dews", "DEWS:", Color3.fromRGB(180, 220, 255))
local xpLabel = CreateStatDisplay("XP", "XP:", Color3.fromRGB(255, 215, 100))
local prestigeLabel = CreateStatDisplay("Prestige", "PRESTIGE:", Color3.fromRGB(255, 100, 100))

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -100, 1, -70)
ContentFrame.Position = UDim2.new(0, 100, 0, 60)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = AOT_Interface

local NavBar = Instance.new("Frame")
NavBar.Name = "NavBar"
NavBar.Size = UDim2.new(0, 80, 1, -50)
NavBar.Position = UDim2.new(0, -80, 0, 50) 
NavBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
NavBar.BorderSizePixel = 0
NavBar.ZIndex = 100
NavBar.Parent = AOT_Interface

Instance.new("UIStroke", NavBar).Color = Color3.fromRGB(120, 100, 60); NavBar.UIStroke.Thickness = 2; NavBar.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local nbl = Instance.new("UIListLayout", NavBar); nbl.FillDirection = Enum.FillDirection.Vertical; nbl.HorizontalAlignment = Enum.HorizontalAlignment.Center; nbl.VerticalAlignment = Enum.VerticalAlignment.Top; nbl.Padding = UDim.new(0, 10)
local nbp = Instance.new("UIPadding", NavBar); nbp.PaddingTop = UDim.new(0, 15)

local NavButtons = {}

local function CreateNavButton(name, text)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Btn"
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	btn.Font = Enum.Font.GothamBlack
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = NavBar

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 65)
	Instance.new("UITextSizeConstraint", btn).MaxTextSize = 11

	btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 50, 40), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
	btn.MouseLeave:Connect(function()
		if not btn:GetAttribute("IsActive") then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play() end
	end)

	NavButtons[name] = btn
	return btn
end

-- Removed Training Tab, it's now embedded in Stats!
CreateNavButton("Inherit", "INHERIT")
CreateNavButton("Stats", "STATS")
CreateNavButton("Inventory", "ITEMS")
CreateNavButton("Battle", "BATTLE")
CreateNavButton("Shop", "SHOP")

task.spawn(function()
	task.wait(0.5)
	TweenService:Create(TopBar, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	task.wait(0.2)
	TweenService:Create(NavBar, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 50)}):Play()
end)

local function UpdateStats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		if leaderstats:FindFirstChild("Yen") then dewsLabel.Text = "DEWS: " .. leaderstats.Yen.Value end
		if leaderstats:FindFirstChild("Prestige") then prestigeLabel.Text = "PRESTIGE: " .. leaderstats.Prestige.Value end
	end
	xpLabel.Text = "XP: " .. (player:GetAttribute("XP") or 0)
end

player.AttributeChanged:Connect(UpdateStats)
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		for _, child in ipairs(leaderstats:GetChildren()) do
			if child:IsA("IntValue") then child.Changed:Connect(UpdateStats) end
		end
	end
	UpdateStats()
end)

local ActiveTab = nil
local TabModules = {}
local TooltipManager = nil

local function SwitchTab(tabName)
	if ActiveTab == tabName then return end
	ActiveTab = tabName

	for name, btn in pairs(NavButtons) do
		if name == tabName then
			btn:SetAttribute("IsActive", true)
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 100, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		else
			btn:SetAttribute("IsActive", false)
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
		end
	end

	for _, child in ipairs(ContentFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ScrollingFrame") then child.Visible = false end
	end

	if TabModules[tabName] and TabModules[tabName].Show then TabModules[tabName].Show() end
end

for name, btn in pairs(NavButtons) do
	btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end

task.spawn(function()
	local uiModulesFolder = script.Parent:WaitForChild("UIModules", 5)
	if uiModulesFolder then
		TooltipManager = require(uiModulesFolder:WaitForChild("TooltipManager"))
		TooltipManager.Init(AOT_Interface)

		TabModules["Inherit"] = require(uiModulesFolder:WaitForChild("InheritTab"))
		TabModules["Inherit"].Init(ContentFrame, TooltipManager)

		TabModules["Stats"] = require(uiModulesFolder:WaitForChild("StatsTab"))
		TabModules["Stats"].Init(ContentFrame, TooltipManager)

		TabModules["Inventory"] = require(uiModulesFolder:WaitForChild("InventoryTab"))
		TabModules["Inventory"].Init(ContentFrame, TooltipManager)

		TabModules["Battle"] = require(uiModulesFolder:WaitForChild("BattleTab"))
		TabModules["Battle"].Init(ContentFrame, TooltipManager)

		TabModules["Combat"] = require(uiModulesFolder:WaitForChild("CombatTab"))
		TabModules["Combat"].Init(ContentFrame)

		TabModules["Shop"] = require(uiModulesFolder:WaitForChild("ShopTab"))
		TabModules["Shop"].Init(ContentFrame, TooltipManager)

		SwitchTab("Inherit")
	end
end)