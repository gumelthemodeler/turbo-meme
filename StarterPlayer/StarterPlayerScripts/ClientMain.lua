-- @ScriptType: LocalScript
-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local oldMenu = playerGui:FindFirstChild("JJBIMenu")
if oldMenu then
	oldMenu:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JJBIMenu"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local UIModules = script.Parent:WaitForChild("UIModules")
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local TooltipManager = require(UIModules:WaitForChild("TooltipManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local CombatTab = require(UIModules:WaitForChild("CombatTab"))
local InventoryTab = require(UIModules:WaitForChild("InventoryTab"))

SFXManager.Init()
TooltipManager.Init(screenGui)
NotificationManager.Init(screenGui)

local Network = ReplicatedStorage:WaitForChild("Network")
local NotificationEvent = Network:WaitForChild("NotificationEvent")
local CombatUpdate = Network:WaitForChild("CombatUpdate")
local DungeonUpdate = Network:WaitForChild("DungeonUpdate")

NotificationEvent.OnClientEvent:Connect(function(msg)
	NotificationManager.Show(msg)
end)

CombatUpdate.OnClientEvent:Connect(function(action, data)
	if action == "SystemMessage" then
		CombatTab.SystemMessage(data)
	else
		CombatTab.UpdateCombat(action, data)
	end
end)

DungeonUpdate.OnClientEvent:Connect(function(action, data)
	if CombatTab.UpdateDungeon then
		CombatTab.UpdateDungeon(action, data)
	end
end)

local function applyDoubleGoldBorder(parent)
	local parentCorner = parent:FindFirstChildOfClass("UICorner")

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Rotation = -45
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		if parentCorner.CornerRadius.Scale > 0 then
			innerCorner.CornerRadius = parentCorner.CornerRadius
		else
			local offset = math.max(0, parentCorner.CornerRadius.Offset - 3)
			innerCorner.CornerRadius = UDim.new(0, offset)
		end
		innerCorner.Parent = innerFrame
	end
	innerFrame.Parent = parent

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Rotation = 45
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 180)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 60))
}
mainGrad.Rotation = 90
mainGrad.Parent = mainFrame

local bgDecor = Instance.new("Frame")
bgDecor.Name = "BgDecor"
bgDecor.Size = UDim2.new(1, 0, 1, 0)
bgDecor.BackgroundTransparency = 1
bgDecor.ClipsDescendants = true
bgDecor.Parent = mainFrame

local bgPattern = Instance.new("ImageLabel")
bgPattern.Name = "JoJoPattern"
bgPattern.Image = "rbxassetid://134215233122387"
bgPattern.ImageColor3 = Color3.fromRGB(200, 150, 255)
bgPattern.ImageTransparency = 0.8
bgPattern.BackgroundTransparency = 1
bgPattern.ScaleType = Enum.ScaleType.Tile
bgPattern.TileSize = UDim2.new(0, 1600, 0, 900)
bgPattern.Size = UDim2.new(1.2, 0, 1.2, 0)
bgPattern.Position = UDim2.new(-0.1, 0, -0.1, 0)
bgPattern.ZIndex = 1
bgPattern.Parent = bgDecor

local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function()
	local vp = camera.ViewportSize
	if vp.X > 0 and vp.Y > 0 then
		local offsetX = (mouse.X / vp.X) - 0.5
		local offsetY = (mouse.Y / vp.Y) - 0.5
		local targetPos = UDim2.new(-0.1 - (offsetX * 0.05), 0, -0.1 - (offsetY * 0.05), 0)
		bgPattern.Position = bgPattern.Position:Lerp(targetPos, 0.064)
	end
end)

task.spawn(function()
	while true do
		local symbol = Instance.new("ImageLabel")
		symbol.Image = "rbxassetid://117109537400764"
		symbol.BackgroundTransparency = 1
		symbol.ImageColor3 = Color3.fromRGB(180, 80, 255)
		symbol.ImageTransparency = 0.5
		symbol.ScaleType = Enum.ScaleType.Fit

		local absSize = math.random(80, 160)
		symbol.Size = UDim2.new(0, absSize, 0, absSize)
		symbol.Position = UDim2.new(math.random(5, 95)/100, 0, 1.1, 0)
		symbol.Rotation = math.random(-30, 30)
		symbol.ZIndex = 1
		symbol.Parent = bgDecor

		local tInfo = TweenInfo.new(math.random(7, 14), Enum.EasingStyle.Linear)
		local tween = TweenService:Create(symbol, tInfo, {
			Position = UDim2.new(symbol.Position.X.Scale + (math.random(-15, 15)/100), 0, -0.2, 0),
			ImageTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function() symbol:Destroy() end)
		task.wait(math.random(5, 15)/10)
	end
end)

local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.BackgroundTransparency = 1
contentContainer.AnchorPoint = Vector2.new(0.5, 0.5)
contentContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
contentContainer.ZIndex = 5
contentContainer.Parent = mainFrame

local navBar = Instance.new("Frame")
navBar.Name = "NavBar"
navBar.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
navBar.AnchorPoint = Vector2.new(0.5, 1)
navBar.Position = UDim2.new(0.5, 0, 1, -25)
navBar.BorderSizePixel = 0
navBar.ZIndex = 10
navBar.Parent = mainFrame

local navCorner = Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 12)
navCorner.Parent = navBar

applyDoubleGoldBorder(navBar)

local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(1, -20, 1, -10)
navContainer.Position = UDim2.new(0, 10, 0, 5)
navContainer.BackgroundTransparency = 1
navContainer.ZIndex = 11
navContainer.Parent = navBar

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Padding = UDim.new(0, 10)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = navContainer

local topRightFrame = Instance.new("Frame")
topRightFrame.Name = "TopRightFrame"
topRightFrame.Size = UDim2.new(0, 200, 0, 60)
topRightFrame.AnchorPoint = Vector2.new(1, 0)
topRightFrame.Position = UDim2.new(1, -20, 0, 20)
topRightFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
topRightFrame.BorderSizePixel = 0
topRightFrame.ZIndex = 10
topRightFrame.Parent = mainFrame

local trFrameCorner = Instance.new("UICorner")
trFrameCorner.CornerRadius = UDim.new(0, 12)
trFrameCorner.Parent = topRightFrame

applyDoubleGoldBorder(topRightFrame)

local topRightContainer = Instance.new("Frame")
topRightContainer.Name = "TopRightContainer"
topRightContainer.Size = UDim2.new(1, 0, 1, 0)
topRightContainer.BackgroundTransparency = 1
topRightContainer.ZIndex = 11
topRightContainer.Parent = topRightFrame

local topRightLayout = Instance.new("UIListLayout")
topRightLayout.FillDirection = Enum.FillDirection.Horizontal
topRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
topRightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topRightLayout.Padding = UDim.new(0, 10)
topRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
topRightLayout.Parent = topRightContainer

local boostBtn = Instance.new("TextButton")
boostBtn.Name = "BoostBtn"
boostBtn.Size = UDim2.new(0, 40, 0, 40)
boostBtn.Text = "⚡"
boostBtn.TextScaled = true
boostBtn.Font = Enum.Font.GothamBold
boostBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
boostBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
boostBtn.BorderSizePixel = 0
boostBtn.LayoutOrder = 1
boostBtn.ZIndex = 12
boostBtn.Parent = topRightContainer

local boostBtnUic = Instance.new("UITextSizeConstraint")
boostBtnUic.MaxTextSize = 35
boostBtnUic.MinTextSize = 1
boostBtnUic.Parent = boostBtn

local boostCorner = Instance.new("UICorner")
boostCorner.CornerRadius = UDim.new(0, 8)
boostCorner.Parent = boostBtn

local boostStroke = Instance.new("UIStroke")
boostStroke.Color = Color3.fromRGB(90, 50, 120)
boostStroke.Thickness = 1
boostStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
boostStroke.Parent = boostBtn

local muteBtn = Instance.new("TextButton")
muteBtn.Name = "MuteBtn"
muteBtn.Size = UDim2.new(0, 40, 0, 40)
muteBtn.Text = "🔊"
muteBtn.TextScaled = true
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
muteBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
muteBtn.BorderSizePixel = 0
muteBtn.LayoutOrder = 2
muteBtn.ZIndex = 12
muteBtn.Parent = topRightContainer

local muteBtnUic = Instance.new("UITextSizeConstraint")
muteBtnUic.MaxTextSize = 35
muteBtnUic.MinTextSize = 1
muteBtnUic.Parent = muteBtn

local muteCorner = Instance.new("UICorner")
muteCorner.CornerRadius = UDim.new(0, 8)
muteCorner.Parent = muteBtn

local muteStroke = Instance.new("UIStroke")
muteStroke.Color = Color3.fromRGB(90, 50, 120)
muteStroke.Thickness = 1
muteStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
muteStroke.Parent = muteBtn

local navToggleBtn = Instance.new("TextButton")
navToggleBtn.Name = "NavToggleBtn"
navToggleBtn.Size = UDim2.new(0, 40, 0, 40)
navToggleBtn.Text = "⬇"
navToggleBtn.TextScaled = true
navToggleBtn.Font = Enum.Font.GothamBold
navToggleBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
navToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
navToggleBtn.BorderSizePixel = 0
navToggleBtn.LayoutOrder = 3
navToggleBtn.ZIndex = 12
navToggleBtn.Parent = topRightContainer

local toggleBtnUic = Instance.new("UITextSizeConstraint")
toggleBtnUic.MaxTextSize = 35
toggleBtnUic.MinTextSize = 1
toggleBtnUic.Parent = navToggleBtn

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = navToggleBtn

local toggleBtnStroke = Instance.new("UIStroke")
toggleBtnStroke.Color = Color3.fromRGB(90, 50, 120)
toggleBtnStroke.Thickness = 1
toggleBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
toggleBtnStroke.Parent = navToggleBtn

local isMuted = player:GetAttribute("IsMuted") or false
muteBtn.Text = isMuted and "🔈" or "🔊"

task.spawn(function()
	local bgm = SoundService:WaitForChild("BizarreBGM", 5)
	if bgm then
		bgm.Volume = isMuted and 0 or 0.4
	end
end)

muteBtn.MouseButton1Click:Connect(function()
	SFXManager.Play("Click")
	isMuted = not isMuted
	muteBtn.Text = isMuted and "🔈" or "🔊"

	local bgm = SoundService:FindFirstChild("BizarreBGM")
	if bgm then
		bgm.Volume = isMuted and 0 or 0.4
	end

	Network:WaitForChild("ToggleMute"):FireServer(isMuted)
end)

boostBtn.MouseButton1Click:Connect(function()
	SFXManager.Play("Click")
end)

local TabFrames = {}
local tabs = {"Singleplayer", "Inventory", "Shop", "Multiplayer", "Training", "Updates"}

local genericIcons = {
	"rbxassetid://133872443057434",
	"rbxassetid://131461796289216", 
	"rbxassetid://124294007761753", 
	"rbxassetid://84309428370700", 
	"rbxassetid://122351196100525", 
	"rbxassetid://119375458206372"
}

for i, tabName in ipairs(tabs) do
	local frameName = tabName .. "Frame"
	local frame = Instance.new("Frame")
	frame.Name = frameName
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.ZIndex = 5
	frame.Parent = contentContainer

	local tempLabel = Instance.new("TextLabel")
	tempLabel.Size = UDim2.new(1, 0, 1, 0)
	tempLabel.BackgroundTransparency = 1
	tempLabel.Text = tabName .. " View"
	tempLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	tempLabel.TextScaled = true
	tempLabel.Font = Enum.Font.GothamBold
	tempLabel.ZIndex = 6
	tempLabel.Parent = frame

	local uic = Instance.new("UITextSizeConstraint")
	uic.MaxTextSize = 50
	uic.Parent = tempLabel

	TabFrames[tabName] = frame

	local btn = Instance.new("TextButton")
	btn.Name = tabName .. "Button"
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.ZIndex = 12
	btn.Parent = navContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(90, 50, 120)
	btnStroke.Thickness = 1
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = btn

	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0.8, 0, 0.8, 0)
	iconContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	iconContainer.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	iconContainer.BorderSizePixel = 0
	iconContainer.ZIndex = 13
	iconContainer.Parent = btn

	local iconAspect = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
	iconAspect.DominantAxis = Enum.DominantAxis.Height
	iconAspect.Parent = iconContainer

	local iconContainerCorner = Instance.new("UICorner")
	iconContainerCorner.CornerRadius = UDim.new(0, 6)
	iconContainerCorner.Parent = iconContainer

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(90, 50, 120)
	iconStroke.Thickness = 1
	iconStroke.Parent = iconContainer

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = genericIcons[i]
	icon.ImageColor3 = Color3.new(1, 1, 1)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 14
	icon.Parent = iconContainer

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Text = tabName:upper()
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(220, 220, 220)
	title.TextScaled = false
	title.TextWrapped = false
	title.Size = UDim2.new(1, -60, 0.85, 0)
	title.Position = UDim2.new(0, 55, 0.5, 0)
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 13
	title.Parent = btn
end

local activeTab = "Updates"
local currentLayoutState = "Large"

local function refreshButtons()
	local vp = camera.ViewportSize
	local btnCount = #tabs

	local navWidthLarge = vp.X * 0.85
	local btnWidthLarge = (navWidthLarge / btnCount) - 15
	local textSpaceLarge = btnWidthLarge - 60
	local uniformTextSize = math.clamp(math.floor(textSpaceLarge / 7.5), 10, 45)

	local navWidthMed = vp.X * 0.95
	local activeBtnWidthMed = navWidthMed * 0.40
	local textSpaceMed = activeBtnWidthMed - 60
	local mediumTextSize = math.clamp(math.floor(textSpaceMed / 7.5), 10, 35)

	for _, btn in pairs(navContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			local tabName = string.gsub(btn.Name, "Button", "")
			local isActive = (tabName == activeTab)

			local titleLbl = btn:FindFirstChild("Title")
			local iconCont = btn:FindFirstChild("IconContainer")
			local btnStroke = btn:FindFirstChildOfClass("UIStroke")
			local icnStroke = iconCont and iconCont:FindFirstChildOfClass("UIStroke")

			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = isActive and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)}):Play()
			if titleLbl then titleLbl.TextColor3 = isActive and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220) end
			if iconCont then iconCont.BackgroundColor3 = isActive and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(15, 5, 25) end
			if btnStroke then 
				btnStroke.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
				btnStroke.Thickness = isActive and 2 or 1
			end
			if icnStroke then icnStroke.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120) end

			if currentLayoutState == "Large" then
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new((1/#tabs) - 0.015, 0, 0.8, 0)}):Play()
				if titleLbl then 
					titleLbl.Visible = true 
					titleLbl.TextSize = uniformTextSize
				end
				if iconCont then 
					TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 10, 0.5, 0)}):Play()
					iconCont.AnchorPoint = Vector2.new(0, 0.5)
				end
				btn.BackgroundTransparency = 0
				if btnStroke then btnStroke.Enabled = true end

			elseif currentLayoutState == "Medium" then
				local targetWidth = isActive and 0.40 or ((0.60 / (#tabs - 1)) - 0.015)
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(targetWidth, 0, 0.8, 0)}):Play()

				if titleLbl then 
					titleLbl.Visible = isActive 
					titleLbl.TextSize = mediumTextSize
				end
				if iconCont then 
					if isActive then
						TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 10, 0.5, 0)}):Play()
						iconCont.AnchorPoint = Vector2.new(0, 0.5)
					else
						TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
						iconCont.AnchorPoint = Vector2.new(0.5, 0.5)
					end
				end
				btn.BackgroundTransparency = 0
				if btnStroke then btnStroke.Enabled = true end

			elseif currentLayoutState == "Small" then
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new((1/#tabs) - 0.015, 0, 0.8, 0)}):Play()
				if titleLbl then titleLbl.Visible = false end
				if iconCont then 
					TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0.85, 0, 0.85, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					iconCont.AnchorPoint = Vector2.new(0.5, 0.5)
				end
				btn.BackgroundTransparency = 1
				if btnStroke then btnStroke.Enabled = false end
			end
		end
	end
end

local function SwitchTab(targetTabName)
	activeTab = targetTabName
	for tName, f in pairs(TabFrames) do
		f.Visible = (tName == targetTabName)
	end
	refreshButtons()
end

for _, tabName in ipairs(tabs) do
	local btn = navContainer:FindFirstChild(tabName .. "Button")
	btn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		SwitchTab(tabName)
	end)
end

local isNavOpen = true

local function ToggleNav()
	isNavOpen = not isNavOpen
	navToggleBtn.Text = isNavOpen and "⬇" or "⬆"

	local targetY = isNavOpen and UDim2.new(0.5, 0, 1, -25) or UDim2.new(0.5, 0, 1, 100)
	TweenService:Create(navBar, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = targetY
	}):Play()

	local currentWidth = 0.8
	if currentLayoutState == "Medium" then
		currentWidth = 0.85
	elseif currentLayoutState == "Small" then
		currentWidth = 0.95
	end

	local targetSize = isNavOpen and UDim2.new(currentWidth, 0, 0.75, 0) or UDim2.new(currentWidth, 0, 0.9, 0)
	local targetPos = isNavOpen and UDim2.new(0.5, 0, 0.45, 0) or UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(contentContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPos
	}):Play()
end

navToggleBtn.MouseButton1Click:Connect(function()
	SFXManager.Play("Click")
	ToggleNav()
end)

local keyMap = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6 }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Backquote then
		SFXManager.Play("Click")
		ToggleNav()
	end
	local tabIndex = keyMap[input.KeyCode]
	if tabIndex and tabs[tabIndex] then
		if not isNavOpen then ToggleNav() end 
		SFXManager.Play("Click")
		SwitchTab(tabs[tabIndex])
	end
end)

local function UpdateLayoutForScreen()
	local vp = camera.ViewportSize

	if vp.X >= 1050 then
		currentLayoutState = "Large"
		navBar.Size = UDim2.new(0.85, 0, 0, 75)
		topRightFrame.Size = UDim2.new(0, 180, 0, 65)
		topRightFrame.Position = UDim2.new(1, -20, 0, 20)
		contentContainer.Size = isNavOpen and UDim2.new(0.8, 0, 0.75, 0) or UDim2.new(0.8, 0, 0.9, 0)
		uiListLayout.Padding = UDim.new(0, 10)
		boostBtn.Size = UDim2.new(0, 45, 0, 45)
		muteBtn.Size = UDim2.new(0, 45, 0, 45)
		navToggleBtn.Size = UDim2.new(0, 45, 0, 45)
	elseif vp.X >= 600 and vp.X < 1050 then
		currentLayoutState = "Medium"
		navBar.Size = UDim2.new(0.95, 0, 0, 70)
		topRightFrame.Size = UDim2.new(0, 170, 0, 60)
		topRightFrame.Position = UDim2.new(1, -15, 0, 15)
		contentContainer.Size = isNavOpen and UDim2.new(0.85, 0, 0.75, 0) or UDim2.new(0.85, 0, 0.9, 0)
		uiListLayout.Padding = UDim.new(0, 8)
		boostBtn.Size = UDim2.new(0, 40, 0, 40)
		muteBtn.Size = UDim2.new(0, 40, 0, 40)
		navToggleBtn.Size = UDim2.new(0, 40, 0, 40)
	else
		currentLayoutState = "Small"
		navBar.Size = UDim2.new(0.95, 0, 0, 65)
		topRightFrame.Size = UDim2.new(0, 160, 0, 55)
		topRightFrame.Position = UDim2.new(1, -10, 0, 10)
		contentContainer.Size = isNavOpen and UDim2.new(0.95, 0, 0.75, 0) or UDim2.new(0.95, 0, 0.9, 0)
		uiListLayout.Padding = UDim.new(0, 5)
		boostBtn.Size = UDim2.new(0, 35, 0, 35)
		muteBtn.Size = UDim2.new(0, 35, 0, 35)
		navToggleBtn.Size = UDim2.new(0, 35, 0, 35)
	end

	navBar.Position = isNavOpen and UDim2.new(0.5, 0, 1, -25) or UDim2.new(0.5, 0, 1, 100)
	refreshButtons()
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
UpdateLayoutForScreen()

CombatTab.Init(TabFrames["Singleplayer"], TooltipManager, SwitchTab)
InventoryTab.Init(TabFrames["Inventory"], TooltipManager)

SwitchTab("Updates")