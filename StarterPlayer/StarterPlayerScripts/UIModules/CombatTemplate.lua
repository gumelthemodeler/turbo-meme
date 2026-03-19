-- @ScriptType: ModuleScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local CombatTemplate = {}

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

function CombatTemplate.Create(parentGui, tooltipMgr)
	local combatUI = {}

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "CombatMainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.ZIndex = 20
	mainFrame.Parent = parentGui

	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, 0, 1, 0)
	contentContainer.BackgroundTransparency = 1
	contentContainer.ZIndex = 22
	contentContainer.Parent = mainFrame

	local uiLayout = Instance.new("UIListLayout")
	uiLayout.FillDirection = Enum.FillDirection.Vertical
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 6)
	uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiLayout.Parent = contentContainer

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 10)
	uiPadding.PaddingBottom = UDim.new(0, 10)
	uiPadding.PaddingLeft = UDim.new(0, 15)
	uiPadding.PaddingRight = UDim.new(0, 15)
	uiPadding.Parent = contentContainer

	local healthbarArea = Instance.new("Frame")
	healthbarArea.Name = "HealthbarArea"
	healthbarArea.Size = UDim2.new(1, 0, 0.42, 0)
	healthbarArea.BackgroundTransparency = 1
	healthbarArea.LayoutOrder = 1
	healthbarArea.ZIndex = 22
	healthbarArea.Parent = contentContainer

	local hbLayout = Instance.new("UIListLayout")
	hbLayout.FillDirection = Enum.FillDirection.Horizontal
	hbLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hbLayout.Padding = UDim.new(0, 15)
	hbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hbLayout.Parent = healthbarArea

	local alliesContainer = Instance.new("Frame")
	alliesContainer.Name = "AlliesContainer"
	alliesContainer.Size = UDim2.new(0.48, 0, 1, 0)
	alliesContainer.BackgroundTransparency = 1
	alliesContainer.LayoutOrder = 1
	alliesContainer.ZIndex = 22
	alliesContainer.Parent = healthbarArea

	local alliesLayout = Instance.new("UIGridLayout")
	alliesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	alliesLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	alliesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	alliesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	alliesLayout.Parent = alliesContainer

	local enemiesContainer = Instance.new("Frame")
	enemiesContainer.Name = "EnemiesContainer"
	enemiesContainer.Size = UDim2.new(0.48, 0, 1, 0)
	enemiesContainer.BackgroundTransparency = 1
	enemiesContainer.LayoutOrder = 2
	enemiesContainer.ZIndex = 22
	enemiesContainer.Parent = healthbarArea

	local enemiesLayout = Instance.new("UIGridLayout")
	enemiesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	enemiesLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	enemiesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	enemiesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	enemiesLayout.Parent = enemiesContainer

	local chatboxArea = Instance.new("Frame")
	chatboxArea.Name = "ChatboxArea"
	chatboxArea.Size = UDim2.new(1, 0, 0.16, 0)
	chatboxArea.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	chatboxArea.BackgroundTransparency = 0.2
	chatboxArea.BorderSizePixel = 0
	chatboxArea.LayoutOrder = 3
	chatboxArea.ZIndex = 22
	chatboxArea.Parent = contentContainer

	local cbCorner = Instance.new("UICorner")
	cbCorner.CornerRadius = UDim.new(0, 8)
	cbCorner.Parent = chatboxArea

	local cbStroke = Instance.new("UIStroke")
	cbStroke.Color = Color3.fromRGB(90, 50, 120)
	cbStroke.Thickness = 1
	cbStroke.Parent = chatboxArea

	local chatPadding = Instance.new("UIPadding")
	chatPadding.PaddingTop = UDim.new(0, 8)
	chatPadding.PaddingBottom = UDim.new(0, 8)
	chatPadding.PaddingLeft = UDim.new(0, 12)
	chatPadding.PaddingRight = UDim.new(0, 12)
	chatPadding.Parent = chatboxArea

	local chatScroll = Instance.new("ScrollingFrame")
	chatScroll.Name = "ChatScroll"
	chatScroll.Size = UDim2.new(1, 0, 1, 0)
	chatScroll.BackgroundTransparency = 1
	chatScroll.BorderSizePixel = 0
	chatScroll.ScrollBarThickness = 4
	chatScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	chatScroll.ZIndex = 23
	chatScroll.Parent = chatboxArea

	local chatText = Instance.new("TextLabel")
	chatText.Name = "LogText"
	chatText.Size = UDim2.new(1, -8, 0, 0)
	chatText.AutomaticSize = Enum.AutomaticSize.Y
	chatText.BackgroundTransparency = 1
	chatText.Font = Enum.Font.GothamMedium
	chatText.TextColor3 = Color3.fromRGB(220, 220, 220)
	chatText.TextSize = 14
	chatText.RichText = true
	chatText.TextWrapped = true
	chatText.Text = ""
	chatText.TextXAlignment = Enum.TextXAlignment.Left
	chatText.TextYAlignment = Enum.TextYAlignment.Bottom
	chatText.ZIndex = 24
	chatText.Parent = chatScroll

	local abilitiesArea = Instance.new("Frame")
	abilitiesArea.Name = "AbilitiesArea"
	abilitiesArea.Size = UDim2.new(1, 0, 0.35, 0)
	abilitiesArea.BackgroundTransparency = 1
	abilitiesArea.LayoutOrder = 4
	abilitiesArea.ZIndex = 22
	abilitiesArea.ClipsDescendants = true
	abilitiesArea.Parent = contentContainer

	local abLayout = Instance.new("UIGridLayout")
	abLayout.SortOrder = Enum.SortOrder.LayoutOrder
	abLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	abLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	abLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	abLayout.Parent = abilitiesArea

	local function updateAbilitiesGrid()
		local vp = workspace.CurrentCamera.ViewportSize
		local isPortrait = vp.Y > vp.X
		local isMedium = not isPortrait and vp.X < 1050

		local columns = isPortrait and 5 or (isMedium and 6 or 7)
		local rows = isPortrait and 3 or 2

		local totalPaddingX = 6 * (columns - 1)
		local totalPaddingY = 6 * (rows - 1)

		local cellW = math.floor((abilitiesArea.AbsoluteSize.X - totalPaddingX - 12) / columns)
		local maxCellH = math.floor((abilitiesArea.AbsoluteSize.Y - totalPaddingY - 16) / rows)

		cellW = math.max(10, math.min(cellW, 180))
		local cellH = math.max(10, math.min(maxCellH, 50))

		abLayout.CellSize = UDim2.new(0, cellW, 0, cellH)
	end

	local function formatGrid(layout, container, count)
		if count <= 0 then count = 1 end

		local cols = math.min(count, 2)
		local rows = math.ceil(count / cols)

		local padX = 6 * (cols - 1)
		local padY = 6 * (rows - 1)

		local w = math.floor((container.AbsoluteSize.X - padX) / cols)
		local h = math.floor((container.AbsoluteSize.Y - padY) / rows)

		layout.CellSize = UDim2.new(0, math.max(10, w), 0, math.max(10, h))
	end

	local function updateAllGrids()
		local aCount = 0
		for _, c in pairs(alliesContainer:GetChildren()) do if c:IsA("Frame") and c.Name:match("Fighter") then aCount += 1 end end
		local eCount = 0
		for _, c in pairs(enemiesContainer:GetChildren()) do if c:IsA("Frame") and c.Name:match("Fighter") then eCount += 1 end end

		formatGrid(alliesLayout, alliesContainer, aCount)
		formatGrid(enemiesLayout, enemiesContainer, eCount)
		updateAbilitiesGrid()
	end

	abilitiesArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAllGrids)
	abilitiesArea.ChildAdded:Connect(updateAllGrids)
	abilitiesArea.ChildRemoved:Connect(updateAllGrids)

	local camera = workspace.CurrentCamera
	local resizeConn

	local function updateLayout()
		local vp = camera.ViewportSize
		local isPortrait = vp.Y > vp.X

		if isPortrait then
			healthbarArea.Size = UDim2.new(1, 0, 0.48, 0)
			chatboxArea.Size = UDim2.new(1, 0, 0.15, 0)
			abilitiesArea.Size = UDim2.new(1, 0, 0.28, 0)

			hbLayout.FillDirection = Enum.FillDirection.Vertical
			hbLayout.Padding = UDim.new(0, 8) 

			alliesContainer.LayoutOrder = 1
			enemiesContainer.LayoutOrder = 2

			alliesContainer.Size = UDim2.new(1, 0, 0.45, 0)
			enemiesContainer.Size = UDim2.new(1, 0, 0.45, 0)
		else
			healthbarArea.Size = UDim2.new(1, 0, 0.42, 0)
			chatboxArea.Size = UDim2.new(1, 0, 0.18, 0)
			abilitiesArea.Size = UDim2.new(1, 0, 0.30, 0)

			hbLayout.FillDirection = Enum.FillDirection.Horizontal
			hbLayout.Padding = UDim.new(0, 10)

			alliesContainer.LayoutOrder = 1
			enemiesContainer.LayoutOrder = 2

			alliesContainer.Size = UDim2.new(0.48, 0, 1, 0)
			enemiesContainer.Size = UDim2.new(0.48, 0, 1, 0)
		end

		updateAllGrids()
	end

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not mainFrame.Parent then
			resizeConn:Disconnect()
			return
		end
		updateLayout()
	end)

	alliesContainer.ChildAdded:Connect(function() updateLayout() end)
	enemiesContainer.ChildAdded:Connect(function() updateLayout() end)
	alliesContainer.ChildRemoved:Connect(function() updateLayout() end)
	enemiesContainer.ChildRemoved:Connect(function() updateLayout() end)

	updateLayout()

	combatUI.MainFrame = mainFrame
	combatUI.ContentContainer = contentContainer
	combatUI.AlliesContainer = alliesContainer
	combatUI.EnemiesContainer = enemiesContainer
	combatUI.ChatText = chatText
	combatUI.ChatScroll = chatScroll
	combatUI.AbilitiesArea = abilitiesArea

	function combatUI:Log(message)
		self.ChatText.Text = message
		task.defer(function()
			self.ChatScroll.CanvasPosition = Vector2.new(0, self.ChatText.AbsoluteSize.Y + 200)
		end)
	end

	function combatUI:ClearAbilities()
		for _, child in pairs(self.AbilitiesArea:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	function combatUI:AddAbility(name, color, callback)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 50)
		btn.Text = name
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextScaled = true
		btn.ZIndex = 24
		btn.Parent = self.AbilitiesArea

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(90, 50, 120)
		btnStroke.Thickness = 2
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnStroke.Parent = btn

		local btnPad = Instance.new("UIPadding")
		btnPad.PaddingTop = UDim.new(0, 4)
		btnPad.PaddingBottom = UDim.new(0, 4)
		btnPad.PaddingLeft = UDim.new(0, 4)
		btnPad.PaddingRight = UDim.new(0, 4)
		btnPad.Parent = btn

		local uic = Instance.new("UITextSizeConstraint")
		uic.MaxTextSize = 20
		uic.MinTextSize = 6
		uic.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
		end)

		updateAllGrids()
		return btn
	end

	function combatUI:AddFighter(isAlly, id, name, iconId, initialHp, maxHp)
		local container = isAlly and self.AlliesContainer or self.EnemiesContainer

		local fFrame = Instance.new("Frame")
		fFrame.Name = "Fighter_" .. id
		fFrame.BackgroundTransparency = 1
		fFrame.ZIndex = 23
		fFrame.Parent = container

		local fLayout = Instance.new("UIListLayout")
		fLayout.FillDirection = Enum.FillDirection.Horizontal
		fLayout.SortOrder = Enum.SortOrder.LayoutOrder
		fLayout.Padding = UDim.new(0, 6) 
		fLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		fLayout.Parent = fFrame

		local iconBox = Instance.new("Frame")
		iconBox.Name = "IconBox"
		iconBox.Size = UDim2.new(0.25, 0, 0.85, 0)
		iconBox.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		iconBox.LayoutOrder = 1
		iconBox.ZIndex = 24
		iconBox.Parent = fFrame

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = iconBox

		local icCorner = Instance.new("UICorner")
		icCorner.CornerRadius = UDim.new(0, 8)
		icCorner.Parent = iconBox

		local icStroke = Instance.new("UIStroke")
		icStroke.Color = Color3.fromRGB(255, 215, 50)
		icStroke.Thickness = 2
		icStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		icStroke.Parent = iconBox

		if isAlly and iconId and iconId ~= "" then
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. iconId .. "&w=150&h=150"
			img.ScaleType = Enum.ScaleType.Crop
			img.ZIndex = 25
			img.Parent = iconBox

			local imgCorner = Instance.new("UICorner")
			imgCorner.CornerRadius = UDim.new(0, 8)
			imgCorner.Parent = img
		else
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Text = "?"
			txt.Font = Enum.Font.GothamBold
			txt.TextColor3 = Color3.fromRGB(255, 215, 50)
			txt.TextScaled = true
			txt.ZIndex = 25
			txt.Parent = iconBox
		end

		local infoArea = Instance.new("Frame")
		infoArea.Name = "InfoArea"
		infoArea.Size = UDim2.new(0.70, 0, 0.95, 0)
		infoArea.BackgroundTransparency = 1
		infoArea.LayoutOrder = 2
		infoArea.ZIndex = 24
		infoArea.Parent = fFrame

		local infoLayout = Instance.new("UIListLayout")
		infoLayout.FillDirection = Enum.FillDirection.Vertical
		infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
		infoLayout.Padding = UDim.new(0, 2)
		infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		infoLayout.Parent = infoArea

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(1, 0, 0.25, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = name
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextScaled = true
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.LayoutOrder = 1
		nameLbl.ZIndex = 24
		nameLbl.Parent = infoArea

		local nameUic = Instance.new("UITextSizeConstraint")
		nameUic.MaxTextSize = 16
		nameUic.MinTextSize = 8
		nameUic.Parent = nameLbl

		local hpContainer = Instance.new("Frame")
		hpContainer.Name = "HpContainer"
		hpContainer.Size = UDim2.new(0.95, 0, 0.20, 0)
		hpContainer.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
		hpContainer.LayoutOrder = 2
		hpContainer.ZIndex = 24
		hpContainer.Parent = infoArea

		local hpCorner = Instance.new("UICorner")
		hpCorner.CornerRadius = UDim.new(1, 0)
		hpCorner.Parent = hpContainer

		local hpStroke = Instance.new("UIStroke")
		hpStroke.Color = Color3.fromRGB(255, 215, 50)
		hpStroke.Thickness = 2
		hpStroke.Parent = hpContainer

		local hpFill = Instance.new("Frame")
		hpFill.Name = "HpFill"
		local pct = math.clamp(initialHp / maxHp, 0, 1)
		hpFill.Size = UDim2.new(pct, 0, 1, 0)
		hpFill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		hpFill.ZIndex = 25
		hpFill.Parent = hpContainer

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = hpFill

		local hpText = Instance.new("TextLabel")
		hpText.Name = "HpText"
		hpText.Size = UDim2.new(1, 0, 1, 0)
		hpText.BackgroundTransparency = 1
		hpText.Text = math.floor(initialHp) .. " / " .. math.floor(maxHp)
		hpText.Font = Enum.Font.GothamBold
		hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
		hpText.TextSize = 11
		hpText.ZIndex = 26
		hpText.Parent = hpContainer

		local hpTextStroke = Instance.new("UIStroke")
		hpTextStroke.Thickness = 1
		hpTextStroke.Color = Color3.fromRGB(0, 0, 0)
		hpTextStroke.Parent = hpText

		local statusContainer = Instance.new("ScrollingFrame")
		statusContainer.Name = "StatusContainer"
		statusContainer.Size = UDim2.new(1, 0, 0.50, 0)
		statusContainer.BackgroundTransparency = 1
		statusContainer.ScrollBarThickness = 0
		statusContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		statusContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		statusContainer.LayoutOrder = 3
		statusContainer.ZIndex = 24
		statusContainer.Parent = infoArea

		local statusPadding = Instance.new("UIPadding")
		statusPadding.PaddingTop = UDim.new(0, 2)
		statusPadding.PaddingLeft = UDim.new(0, 2)
		statusPadding.PaddingRight = UDim.new(0, 2)
		statusPadding.PaddingBottom = UDim.new(0, 8) 
		statusPadding.Parent = statusContainer

		local statusLayout = Instance.new("UIGridLayout")
		statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
		statusLayout.CellPadding = UDim2.new(0, 4, 0, 4)
		statusLayout.CellSize = UDim2.new(0, 20, 0, 20)
		statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		statusLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		statusLayout.Parent = statusContainer

		local fighterObj = {
			Frame = fFrame,
			InfoArea = infoArea,
			HpFill = hpFill,
			HpText = hpText,
			StatusContainer = statusContainer,
			MaxHp = maxHp
		}

		function fighterObj:UpdateHealth(newHp, newMax)
			if newMax then self.MaxHp = newMax end
			local newPct = math.clamp(newHp / self.MaxHp, 0, 1)
			self.HpText.Text = math.floor(newHp) .. " / " .. math.floor(self.MaxHp)
			TweenService:Create(self.HpFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(newPct, 0, 1, 0)
			}):Play()
		end

		function fighterObj:SetStatus(statusId, iconString, durationText, descText, isImmunity)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if not existing then
				existing = Instance.new("Frame")
				existing.Name = statusId
				existing.BackgroundColor3 = isImmunity and Color3.fromRGB(20, 10, 30) or Color3.fromRGB(30, 20, 50)
				existing.BackgroundTransparency = isImmunity and 0.5 or 0
				existing.LayoutOrder = isImmunity and 1 or 2
				existing.ZIndex = 25
				existing.Parent = self.StatusContainer

				local sCorner = Instance.new("UICorner")
				sCorner.CornerRadius = UDim.new(0, 4)
				sCorner.Parent = existing

				local sStroke = Instance.new("UIStroke")
				sStroke.Color = isImmunity and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 215, 50)
				sStroke.Thickness = 1
				sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				sStroke.Parent = existing

				local sIcon = Instance.new("TextLabel")
				sIcon.Name = "Icon"
				sIcon.Size = UDim2.new(1, 0, 1, 0)
				sIcon.BackgroundTransparency = 1
				sIcon.Text = iconString
				sIcon.Font = Enum.Font.GothamBold
				sIcon.TextColor3 = isImmunity and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255)
				sIcon.TextScaled = true
				sIcon.ZIndex = 26
				sIcon.Parent = existing

				local durLbl = Instance.new("TextLabel")
				durLbl.Name = "Duration"
				durLbl.Size = UDim2.new(1, 6, 0.5, 0)
				durLbl.Position = UDim2.new(0, -3, 0.7, 0)
				durLbl.BackgroundTransparency = 1
				durLbl.Text = durationText or ""
				durLbl.Font = Enum.Font.GothamBlack
				durLbl.TextColor3 = isImmunity and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 50, 50)
				durLbl.TextScaled = true
				durLbl.ZIndex = 27
				durLbl.Parent = existing

				local strokeTxt = Instance.new("UIStroke")
				strokeTxt.Color = Color3.fromRGB(0, 0, 0)
				strokeTxt.Thickness = 1
				strokeTxt.Parent = durLbl

				local hoverBtn = Instance.new("TextButton")
				hoverBtn.Name = "TooltipHover"
				hoverBtn.Size = UDim2.new(1, 0, 1, 0)
				hoverBtn.BackgroundTransparency = 1
				hoverBtn.Text = ""
				hoverBtn.ZIndex = 30
				hoverBtn.Parent = existing

				hoverBtn.MouseEnter:Connect(function()
					if tooltipMgr then
						local t = existing:GetAttribute("TooltipTitle")
						local d = existing:GetAttribute("TooltipDesc")
						local dur = existing:GetAttribute("TooltipDur")
						tooltipMgr.Show("<b><font color='#FFD700'>"..t.."</font></b>\n<font color='#AAAAAA'>"..d.."</font>\nDuration: <font color='#FF5555'>"..dur.."</font>")
					end
				end)
				hoverBtn.MouseLeave:Connect(function() if tooltipMgr then tooltipMgr.Hide() end end)
			end

			existing:SetAttribute("TooltipTitle", statusId)
			existing:SetAttribute("TooltipDesc", descText or "Active effect.")
			existing:SetAttribute("TooltipDur", durationText)

			local durLbl = existing:FindFirstChild("Duration")
			if durLbl then durLbl.Text = durationText or "" end
		end

		function fighterObj:RemoveStatus(statusId)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if existing then
				existing:Destroy()
			end
		end

		function fighterObj:SetCooldown(cdId, iconString, durationText, descText)
			self:SetStatus(cdId, iconString, durationText, descText, true)
		end

		function fighterObj:RemoveCooldown(cdId)
			self:RemoveStatus(cdId)
		end

		updateAllGrids()
		return fighterObj
	end

	function combatUI:Destroy()
		if resizeConn then resizeConn:Disconnect() end
		self.MainFrame:Destroy()
	end

	return combatUI
end

return CombatTemplate