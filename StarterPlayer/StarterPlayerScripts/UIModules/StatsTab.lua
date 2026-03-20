-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local StatsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local player = Players.LocalPlayer
local MainFrame
local cachedTooltipMgr

local playerStatsList = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}
local titanStatsList = {"Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}
local statRowRefs = {}

local isTraining = false
local trainBarFill, trainLog, toggleTrainBtn
local currentTween
local trainTweenInfo = TweenInfo.new(4.8, Enum.EasingStyle.Linear)

local function GetCombinedBonus(statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0
	if ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.WeaponBonuses and GameData.WeaponBonuses[style] and GameData.WeaponBonuses[style][statName] then bonus += GameData.WeaponBonuses[style][statName] end
	return bonus
end

local function GetUpgradeCosts(currentStat, baseVal, prestige, maxCap)
	local cost1 = GameData.CalculateStatCost(currentStat, baseVal, prestige)
	local cost5, cost10 = 0, 0
	for i = 0, 4 do if currentStat + i >= maxCap then break end cost5 += GameData.CalculateStatCost(currentStat + i, baseVal, prestige) end
	for i = 0, 9 do if currentStat + i >= maxCap then break end cost10 += GameData.CalculateStatCost(currentStat + i, baseVal, prestige) end
	return cost1, cost5, cost10
end

local function ShowUpgradeTooltip(statName, amt)
	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
	local statCap = GameData.GetStatCap(prestige)
	local currentStat = player:GetAttribute(statName) or 1
	local currentXP = player:GetAttribute("XP") or 0
	local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
	local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)

	if currentStat >= statCap then
		cachedTooltipMgr.Show("<font color='#FF5555'>Stat is MAXED!</font>")
		return
	end

	local cost, added, simulatedXP = 0, 0, currentXP
	local target = (amt == "MAX") and 9999 or amt

	for i = 0, target - 1 do
		if currentStat + added >= statCap then break end
		local stepCost = GameData.CalculateStatCost(currentStat + added, base, prestige)
		if simulatedXP >= stepCost then
			simulatedXP -= stepCost; cost += stepCost; added += 1
		else break end
	end

	if added == 0 then
		local stepCost = GameData.CalculateStatCost(currentStat, base, prestige)
		cachedTooltipMgr.Show("<b>UPGRADE " .. cleanName:upper() .. "</b>\n<font color='#FF5555'>Not enough XP!</font>\n<font color='#AAAAAA'>Next level costs: " .. stepCost .. " XP</font>")
	else
		cachedTooltipMgr.Show("<b>UPGRADE " .. cleanName:upper() .. " (+" .. added .. ")</b>\n<font color='#55FFFF'>Cost: " .. cost .. " XP</font>\n<font color='#55FF55'>New Level: " .. (currentStat + added) .. "</font>")
	end
end

local function CreateStatRow(statName, parent, isTitan)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 0, 35)
	row.BackgroundTransparency = 1

	local statLabel = Instance.new("TextLabel", row)
	statLabel.Size = UDim2.new(0.38, 0, 1, 0)
	statLabel.BackgroundTransparency = 1
	statLabel.Font = Enum.Font.GothamBold
	statLabel.TextColor3 = isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
	statLabel.TextXAlignment = Enum.TextXAlignment.Left
	statLabel.TextScaled = true
	statLabel.RichText = true
	Instance.new("UITextSizeConstraint", statLabel).MaxTextSize = 14

	local btnContainer = Instance.new("Frame", row)
	btnContainer.Size = UDim2.new(0.62, 0, 1, 0); btnContainer.Position = UDim2.new(1, 0, 0, 0); btnContainer.AnchorPoint = Vector2.new(1, 0)
	btnContainer.BackgroundTransparency = 1
	local blL = Instance.new("UIListLayout", btnContainer); blL.FillDirection = Enum.FillDirection.Horizontal; blL.HorizontalAlignment = Enum.HorizontalAlignment.Right; blL.VerticalAlignment = Enum.VerticalAlignment.Center; blL.Padding = UDim.new(0.02, 0)

	local function makeBtn(text, scaleW)
		local b = Instance.new("TextButton", btnContainer)
		b.Size = UDim2.new(scaleW, 0, 0.85, 0); b.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
		b.Text = text; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1); b.TextScaled = true
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		Instance.new("UIStroke", b).Color = Color3.fromRGB(80, 100, 80)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 11
		return b
	end

	local b1 = makeBtn("+1", 0.15)
	local b5 = makeBtn("+5", 0.15)
	local b10 = makeBtn("+10", 0.22)
	local bMax = makeBtn("MAX", 0.30)

	local function hookHover(btn, amt)
		btn.MouseEnter:Connect(function() ShowUpgradeTooltip(statName, amt) end)
		btn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
	end
	hookHover(b1, 1); hookHover(b5, 5); hookHover(b10, 10); hookHover(bMax, "MAX")

	b1.MouseButton1Click:Connect(function() Network:WaitForChild("UpgradeStat"):FireServer(statName, 1) end)
	b5.MouseButton1Click:Connect(function() Network:WaitForChild("UpgradeStat"):FireServer(statName, 5) end)
	b10.MouseButton1Click:Connect(function() Network:WaitForChild("UpgradeStat"):FireServer(statName, 10) end)
	bMax.MouseButton1Click:Connect(function() Network:WaitForChild("UpgradeStat"):FireServer(statName, "MAX") end)

	statRowRefs[statName] = { Label = statLabel, Btn1 = b1, Btn5 = b5, Btn10 = b10, BtnMax = bMax }
end

local function PlayTrainingTween()
	if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then return end
	trainBarFill.Size = UDim2.new(0, 0, 1, 0)
	currentTween = TweenService:Create(trainBarFill, trainTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	currentTween:Play()
end

function StatsTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	-- [[ TOP HALF: STATS (60% Height) ]]
	local StatsArea = Instance.new("Frame", MainFrame)
	StatsArea.Size = UDim2.new(1, 0, 0.6, 0); StatsArea.BackgroundTransparency = 1

	local leftPanel = Instance.new("Frame", StatsArea)
	leftPanel.Size = UDim2.new(0.48, 0, 1, 0); leftPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", leftPanel).Color = Color3.fromRGB(80, 80, 90)

	local rightPanel = Instance.new("Frame", StatsArea)
	rightPanel.Size = UDim2.new(0.48, 0, 1, 0); rightPanel.Position = UDim2.new(0.52, 0, 0, 0); rightPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", rightPanel).Color = Color3.fromRGB(80, 80, 90)

	local function SetupPanel(panel, titleTxt, statList, isTitan)
		local title = Instance.new("TextLabel", panel)
		title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 20; title.Text = titleTxt
		title.TextColor3 = isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 220)

		local list = Instance.new("ScrollingFrame", panel)
		list.Size = UDim2.new(1, -20, 1, -50); list.Position = UDim2.new(0, 10, 0, 40); list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 4
		local lLayout = Instance.new("UIListLayout", list); lLayout.Padding = UDim.new(0, 10)
		for _, s in ipairs(statList) do CreateStatRow(s, list, isTitan) end
	end

	SetupPanel(leftPanel, "SOLDIER VITALITY", playerStatsList, false)
	SetupPanel(rightPanel, "TITAN POTENTIAL", titanStatsList, true)

	-- [[ BOTTOM HALF: TRAINING (35% Height) ]]
	local TrainArea = Instance.new("Frame", MainFrame)
	TrainArea.Size = UDim2.new(1, 0, 0.35, 0); TrainArea.Position = UDim2.new(0, 0, 0.65, 0); TrainArea.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", TrainArea).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", TrainArea).Color = Color3.fromRGB(80, 80, 90)

	local tTitle = Instance.new("TextLabel", TrainArea)
	tTitle.Size = UDim2.new(1, 0, 0, 40); tTitle.Position = UDim2.new(0, 0, 0, 5); tTitle.BackgroundTransparency = 1
	tTitle.Font = Enum.Font.GothamBlack; tTitle.TextColor3 = Color3.fromRGB(255, 215, 100); tTitle.TextSize = 20; tTitle.Text = "MILITARY TRAINING GROUNDS"

	local trainBarBg = Instance.new("Frame", TrainArea)
	trainBarBg.Size = UDim2.new(0.6, 0, 0, 20); trainBarBg.Position = UDim2.new(0.2, 0, 0.35, 0); trainBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Instance.new("UICorner", trainBarBg).CornerRadius = UDim.new(1, 0)
	trainBarFill = Instance.new("Frame", trainBarBg)
	trainBarFill.Size = UDim2.new(0, 0, 1, 0); trainBarFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	Instance.new("UICorner", trainBarFill).CornerRadius = UDim.new(1, 0)

	trainLog = Instance.new("TextLabel", TrainArea)
	trainLog.Size = UDim2.new(1, 0, 0, 30); trainLog.Position = UDim2.new(0, 0, 0.5, 0)
	trainLog.BackgroundTransparency = 1; trainLog.Font = Enum.Font.GothamMedium; trainLog.TextColor3 = Color3.fromRGB(180, 180, 180); trainLog.TextSize = 14; trainLog.RichText = true
	trainLog.Text = "Resting. Start training to gain passive XP and Dews."

	toggleTrainBtn = Instance.new("TextButton", TrainArea)
	toggleTrainBtn.Size = UDim2.new(0.3, 0, 0, 40); toggleTrainBtn.Position = UDim2.new(0.35, 0, 0.7, 0)
	toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40); toggleTrainBtn.Font = Enum.Font.GothamBold; toggleTrainBtn.TextColor3 = Color3.new(1,1,1); toggleTrainBtn.TextSize = 16; toggleTrainBtn.Text = "START TRAINING"
	Instance.new("UICorner", toggleTrainBtn).CornerRadius = UDim.new(0, 6)

	toggleTrainBtn.MouseButton1Click:Connect(function()
		isTraining = not isTraining
		if isTraining then
			toggleTrainBtn.Text = "STOP TRAINING"; toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
			trainLog.Text = "<font color='#55FF55'>Drills started... Pushing limits!</font>"
			PlayTrainingTween()
		else
			toggleTrainBtn.Text = "START TRAINING"; toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
			trainLog.Text = "Resting. Start training to gain passive XP and Dews."
			trainBarFill.Size = UDim2.new(0, 0, 1, 0)
			if currentTween then currentTween:Cancel() end
		end
		Network.ToggleTraining:FireServer(isTraining)
	end)

	task.spawn(function() while task.wait(5) do if isTraining then PlayTrainingTween() end end end)

	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		if action == "TrainingTick" and isTraining then
			trainLog.Text = "<font color='#55FFFF'>Gained +" .. data.XP .. " XP</font> and <font color='#55FF55'>+" .. data.Dews .. " Dews</font>."
		end
	end)

	local function UpdateStats()
		local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0
		local currentXP = player:GetAttribute("XP") or 0
		local statCap = GameData.GetStatCap(prestige)

		local allStats = {}
		for _, s in ipairs(playerStatsList) do table.insert(allStats, s) end
		for _, s in ipairs(titanStatsList) do table.insert(allStats, s) end

		for _, statName in ipairs(allStats) do
			local val = player:GetAttribute(statName) or 1
			local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
			local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)
			local cost1, cost5, cost10 = GetUpgradeCosts(val, base, prestige, statCap)
			local bonusAmount = GetCombinedBonus(cleanName)
			local bonusText = bonusAmount > 0 and " <font color='#55FF55'>(+" .. bonusAmount .. ")</font>" or ""

			local data = statRowRefs[statName]
			if val >= statCap then
				data.Label.Text = cleanName .. ": " .. val .. bonusText .. " <font color='#FF5555'>[MAX]</font>"
				data.Btn1.BackgroundColor3 = Color3.fromRGB(30, 30, 35); data.Btn1.TextColor3 = Color3.fromRGB(100, 100, 100)
				data.Btn5.BackgroundColor3 = Color3.fromRGB(30, 30, 35); data.Btn5.TextColor3 = Color3.fromRGB(100, 100, 100)
				data.Btn10.BackgroundColor3 = Color3.fromRGB(30, 30, 35); data.Btn10.TextColor3 = Color3.fromRGB(100, 100, 100)
				data.BtnMax.BackgroundColor3 = Color3.fromRGB(30, 30, 35); data.BtnMax.TextColor3 = Color3.fromRGB(100, 100, 100)
			else
				data.Label.Text = cleanName .. ": " .. val .. bonusText
				local function toggle(btn, canAfford)
					btn.BackgroundColor3 = canAfford and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(30, 30, 35)
					btn.TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
				end
				toggle(data.Btn1, currentXP >= cost1)
				toggle(data.Btn5, currentXP >= cost5)
				toggle(data.Btn10, currentXP >= cost10)
				toggle(data.BtnMax, currentXP >= cost1)
			end
		end
	end

	player.AttributeChanged:Connect(function(attr)
		if table.find(playerStatsList, attr) or table.find(titanStatsList, attr) or attr == "XP" then UpdateStats() end
	end)
	UpdateStats()
end

function StatsTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return StatsTab