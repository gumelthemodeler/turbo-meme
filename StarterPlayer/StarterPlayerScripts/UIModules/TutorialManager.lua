-- @ScriptType: ModuleScript
local TutorialManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Network = ReplicatedStorage:WaitForChild("Network")
local player = game.Players.LocalPlayer

local SFXManager = require(script.Parent:WaitForChild("SFXManager")) 

local guiRoot
local switchTabFuncRef
local tutorialContainer
local topMask, bottomMask, leftMask, rightMask
local dialogueFrame
local dialogueText
local nextButton
local highlightFrame
local highlightConn

local isSkipped = false
local skipEvent = Instance.new("BindableEvent")

local function LinkUI()
	tutorialContainer = player.PlayerGui:WaitForChild("TutorialGui")

	topMask = tutorialContainer:WaitForChild("TopMask")
	bottomMask = tutorialContainer:WaitForChild("BottomMask")
	leftMask = tutorialContainer:WaitForChild("LeftMask")
	rightMask = tutorialContainer:WaitForChild("RightMask")

	dialogueFrame = tutorialContainer:WaitForChild("DialogueFrame")
	dialogueText = dialogueFrame:WaitForChild("DialogueText")
	nextButton = dialogueFrame:WaitForChild("NextBtn")

	highlightFrame = tutorialContainer:WaitForChild("HighlightFrame")
	local skipBtn = tutorialContainer:WaitForChild("SkipBtn")

	skipBtn.MouseButton1Click:Connect(function()
		if isSkipped then return end
		isSkipped = true
		pcall(function() SFXManager.Play("Click") end)
		Network:WaitForChild("TutorialAction"):FireServer("Complete")
		skipEvent:Fire()
		if tutorialContainer then tutorialContainer:Destroy() end
	end)

	task.spawn(function()
		while highlightFrame and highlightFrame.Parent do
			local tw = TweenService:Create(highlightFrame, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.2})
			tw:Play()
			task.wait(1.5)
		end
	end)
end

local function GetCleanText(txt)
	return string.upper(string.gsub(txt, "<[^>]+>", ""))
end

local function GetTabButton(tabName)
	local targetText = string.upper(tabName)
	local result = nil
	local function search(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then
				if GetCleanText(child.Text) == targetText and child:FindFirstChild("ButtonStar") then
					result = child
					return
				end
			end
			search(child)
			if result then return end
		end
	end
	search(guiRoot)
	return result
end

local function FindContentButton(partialText)
	local targetText = string.upper(partialText)
	local results = {}
	local function search(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then
				if not child:FindFirstChild("ButtonStar") and string.find(GetCleanText(child.Text), targetText, 1, true) then
					table.insert(results, child)
				end
			end
			search(child)
		end
	end
	search(guiRoot)
	return results
end

local function FindStrengthPlus5Button()
	local result = nil
	local function search(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextLabel") and string.find(string.upper(child.Text), "STRENGTH") then
				local parentRow = child.Parent
				if parentRow then
					for _, sibling in ipairs(parentRow:GetChildren()) do
						if sibling:IsA("Frame") then
							for _, btn in ipairs(sibling:GetChildren()) do
								if btn:IsA("TextButton") and btn.Text == "+5" then
									result = btn
									return
								end
							end
						end
					end
				end
			end
			search(child)
			if result then return end
		end
	end
	search(guiRoot)
	return result
end

local function FindItemUseButton(itemName)
	local search = string.upper(itemName)
	local result = nil
	local function searchTree(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextLabel") and child.Text and string.find(string.upper(child.Text), search, 1, true) then
				local parentRow = child.Parent
				if parentRow and parentRow.Name ~= "DialogueFrame" then
					local useBtn = parentRow:FindFirstChild("UseBtn")
					if useBtn and useBtn.Visible and useBtn:IsA("TextButton") then
						result = useBtn
						return
					end
				end
			end
			searchTree(child)
			if result then return end
		end
	end
	searchTree(guiRoot)
	return result
end

local function AutoScrollTo(targetBtn)
	if not targetBtn then return end

	local sfList = {}
	local curr = targetBtn
	while curr do
		local sf = curr:FindFirstAncestorOfClass("ScrollingFrame")
		if sf then
			table.insert(sfList, sf)
			curr = sf
		else
			break
		end
	end

	for _, sf in ipairs(sfList) do
		RunService.Heartbeat:Wait()
		local targetY = targetBtn.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
		local newPos = targetY - (sf.AbsoluteSize.Y / 2) + (targetBtn.AbsoluteSize.Y / 2)
		sf.CanvasPosition = Vector2.new(0, math.max(0, newPos))
	end
end

local function ShowDialogue(text, showNext)
	if isSkipped then return end
	dialogueText.Text = ""
	nextButton.Visible = false

	for i = 1, #text do
		if isSkipped then return end
		dialogueText.Text = string.sub(text, 1, i)
		task.wait(0.015)
	end

	if showNext and not isSkipped then
		nextButton.Visible = true
	end
end

local function ClearHighlight()
	if not highlightFrame or not highlightFrame.Parent then return end
	highlightFrame.Visible = false
	if highlightConn then
		highlightConn:Disconnect()
		highlightConn = nil
	end

	topMask.Size = UDim2.new(1, 0, 1, 0); topMask.Position = UDim2.new(0, 0, 0, 0)
	bottomMask.Size = UDim2.new(0, 0, 0, 0)
	leftMask.Size = UDim2.new(0, 0, 0, 0)
	rightMask.Size = UDim2.new(0, 0, 0, 0)
end

local function HighlightDynamicTarget(findFunc, allowScrolling)
	ClearHighlight()
	if isSkipped then return end

	if allowScrolling then
		topMask.Visible = false; bottomMask.Visible = false
		leftMask.Visible = false; rightMask.Visible = false
	else
		topMask.Visible = true; bottomMask.Visible = true
		leftMask.Visible = true; rightMask.Visible = true
	end

	highlightConn = RunService.RenderStepped:Connect(function()
		local targetBtn = findFunc()
		if targetBtn and targetBtn.Parent then

			local isClipped = false
			local current = targetBtn.Parent
			while current and current:IsA("GuiObject") do
				if current:IsA("ScrollingFrame") then
					local sfTop = current.AbsolutePosition.Y
					local sfBottom = sfTop + current.AbsoluteSize.Y
					local btnTop = targetBtn.AbsolutePosition.Y
					local btnBottom = btnTop + targetBtn.AbsoluteSize.Y
					if btnBottom < sfTop or btnTop > sfBottom then
						isClipped = true
						break
					end
				end
				current = current.Parent
			end

			if isClipped then
				highlightFrame.Visible = false
			else
				highlightFrame.Visible = true
				local inset = GuiService:GetGuiInset()
				local tX = targetBtn.AbsolutePosition.X - 5
				local tY = targetBtn.AbsolutePosition.Y + inset.Y - 5
				local tW = targetBtn.AbsoluteSize.X + 10
				local tH = targetBtn.AbsoluteSize.Y + 10

				highlightFrame.Size = UDim2.new(0, tW, 0, tH)
				highlightFrame.Position = UDim2.new(0, tX, 0, tY)

				if not allowScrolling then
					topMask.Size = UDim2.new(1, 0, 0, tY)
					topMask.Position = UDim2.new(0, 0, 0, 0)

					bottomMask.Size = UDim2.new(1, 0, 1, -(tY + tH))
					bottomMask.Position = UDim2.new(0, 0, 0, tY + tH)

					leftMask.Size = UDim2.new(0, tX, 0, tH)
					leftMask.Position = UDim2.new(0, 0, 0, tY)

					rightMask.Size = UDim2.new(1, -(tX + tW), 0, tH)
					rightMask.Position = UDim2.new(0, tX + tW, 0, tY)
				end
			end
		else
			highlightFrame.Visible = false
			if not allowScrolling then
				topMask.Size = UDim2.new(1, 0, 1, 0); topMask.Position = UDim2.new(0, 0, 0, 0)
				bottomMask.Size = UDim2.new(0, 0, 0, 0); leftMask.Size = UDim2.new(0, 0, 0, 0); rightMask.Size = UDim2.new(0, 0, 0, 0)
			end
		end
	end)
end

local function SetUIHidden(isHidden)
	if isSkipped or not dialogueFrame or not dialogueFrame.Parent then return end
	dialogueFrame.Visible = not isHidden
	topMask.Visible = not isHidden
	bottomMask.Visible = not isHidden
	leftMask.Visible = not isHidden
	rightMask.Visible = not isHidden
end

local function WaitNext()
	if isSkipped then return end
	local bindable = Instance.new("BindableEvent")
	local conn, skipConn

	conn = nextButton.MouseButton1Click:Connect(function()
		pcall(function() SFXManager.Play("Click") end)
		if conn then conn:Disconnect() end
		if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	skipConn = skipEvent.Event:Connect(function()
		if conn then conn:Disconnect() end
		if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	bindable.Event:Wait()
end

local function WaitForRealClick(findFunc)
	if isSkipped then return end
	local targetBtn = findFunc()
	if not targetBtn then 
		task.wait(2)
		return 
	end

	local clicked = false
	local conn = targetBtn.MouseButton1Click:Connect(function()
		clicked = true
	end)

	local skipConn = skipEvent.Event:Connect(function()
		clicked = true
	end)

	repeat task.wait(0.2) until clicked or isSkipped

	if conn then conn:Disconnect() end
	if skipConn then skipConn:Disconnect() end
	ClearHighlight()
end

local function RunTutorial()
	task.wait(2)
	if isSkipped then return end

	ShowDialogue("Welcome to Bizarre Incremental! Let's get you ready for your bizarre adventure.", true)
	WaitNext(); if isSkipped then return end

	ShowDialogue("Your journey begins in the COMBAT tab. Click it to open the combat menu!", false)
	local function getCombatTab() return GetTabButton("COMBAT") end
	HighlightDynamicTarget(getCombatTab, false)
	WaitForRealClick(getCombatTab); if isSkipped then return end

	ShowDialogue("Click an ENCOUNTER button to start your first fight!", true)
	WaitNext(); if isSkipped then return end

	SetUIHidden(true)
	local function getEncBtn() return FindContentButton("ENCOUNTER")[1] end
	HighlightDynamicTarget(getEncBtn, true)
	WaitForRealClick(getEncBtn); if isSkipped then return end
	SetUIHidden(false)

	ShowDialogue("Defeat the enemy by clicking your skills! I'll step back while you fight.", false)
	task.wait(3.5); if isSkipped then return end
	SetUIHidden(true)

	local combatDone = false
	local c = Network.CombatUpdate.OnClientEvent:Connect(function(status)
		if status == "Defeat" or status == "Victory" or status == "End" then
			combatDone = true
		end
	end)

	local timer = 0
	while not combatDone and timer < 45 and not isSkipped do
		task.wait(1)
		timer += 1
	end
	c:Disconnect()
	if isSkipped then return end
	SetUIHidden(false)

	ShowDialogue("Ouch, that was tough! You need more stats to win. Click the TRAINING tab.", false)
	local function getTrainTab() return GetTabButton("TRAINING") end
	HighlightDynamicTarget(getTrainTab, false)
	WaitForRealClick(getTrainTab); if isSkipped then return end

	ShowDialogue("Click the 'TRAIN' button to start passively gaining XP!", true)
	WaitNext(); if isSkipped then return end

	SetUIHidden(true)
	local function getTrainBtn() return FindContentButton("TRAIN")[1] end
	HighlightDynamicTarget(getTrainBtn, true)
	WaitForRealClick(getTrainBtn); if isSkipped then return end
	SetUIHidden(false)

	ShowDialogue("While you train, let's use some free XP I'm giving you to upgrade immediately!", true)
	Network:WaitForChild("TutorialAction"):FireServer("GiveXP")
	WaitNext(); if isSkipped then return end

	ShowDialogue("Click the INVENTORY tab to view your stats.", false)
	local function getInvTab() return GetTabButton("INVENTORY") end
	HighlightDynamicTarget(getInvTab, false)
	WaitForRealClick(getInvTab); if isSkipped then return end

	ShowDialogue("Click the '+5' button next to STRENGTH to spend your XP! I'll wait.", false)

	task.wait(0.5) 
	HighlightDynamicTarget(FindStrengthPlus5Button, false)

	local startStrength = player:GetAttribute("Strength") or 1
	while (player:GetAttribute("Strength") or 1) < startStrength + 5 and not isSkipped do
		task.wait(0.2)
	end
	ClearHighlight()
	if isSkipped then return end

	ShowDialogue("Awesome! You're getting stronger. Let's return to the battle.", false)
	HighlightDynamicTarget(getCombatTab, false)
	WaitForRealClick(getCombatTab); if isSkipped then return end

	local wonSecondBattle = false
	while not wonSecondBattle and not isSkipped do
		ShowDialogue("Click ENCOUNTER and defeat this enemy! If you lose, try again.", true)
		WaitNext(); if isSkipped then return end

		SetUIHidden(true)
		HighlightDynamicTarget(getEncBtn, true)
		WaitForRealClick(getEncBtn); if isSkipped then return end

		local c2Done = false
		local c2Result = "End"
		local c2 = Network.CombatUpdate.OnClientEvent:Connect(function(status)
			if status == "Defeat" or status == "Victory" or status == "End" then
				c2Done = true
				c2Result = status
			end
		end)

		while not c2Done and not isSkipped do
			task.wait(0.5)
		end
		c2:Disconnect()
		if isSkipped then return end

		SetUIHidden(false)

		if c2Result == "Victory" then
			wonSecondBattle = true
		else
			ShowDialogue("You lost! That's okay, let's try that again.", true)
			WaitNext(); if isSkipped then return end
		end
	end

	if isSkipped then return end

	ShowDialogue("Great job! As a reward, you got a Stand Arrow from the enemy.", true)
	WaitNext(); if isSkipped then return end

	ShowDialogue("Click the INVENTORY tab to view your items.", false)
	HighlightDynamicTarget(getInvTab, false)
	WaitForRealClick(getInvTab); if isSkipped then return end

	ShowDialogue("Scroll down to find your 'Stand Arrow' and click to use it! If a confirmation appears, click Yes.", true)
	WaitNext(); if isSkipped then return end

	SetUIHidden(true)

	local arrowBtn = nil
	local findArrowTimeout = 0
	repeat
		arrowBtn = FindItemUseButton("STAND ARROW") or FindItemUseButton("ARROW")
		task.wait(0.5)
		findArrowTimeout += 0.5
	until arrowBtn or isSkipped or findArrowTimeout >= 5

	if isSkipped then return end

	if arrowBtn then
		AutoScrollTo(arrowBtn)
		HighlightDynamicTarget(function()
			return FindItemUseButton("STAND ARROW") or FindItemUseButton("ARROW")
		end, true)
	end

	local waitTimer = 0
	while waitTimer < 6 and not isSkipped do
		task.wait(1)
		waitTimer += 1
	end

	ClearHighlight()
	SetUIHidden(false)

	if isSkipped then return end

	ShowDialogue("Whoa... you feel a new power awakening!", true)
	WaitNext(); if isSkipped then return end

	ShowDialogue("Let's head back to the COMBAT tab one last time.", false)
	HighlightDynamicTarget(getCombatTab, false)
	WaitForRealClick(getCombatTab); if isSkipped then return end

	ShowDialogue("Now that you have a Stand, you are ready for Story Missions!", true)
	WaitNext(); if isSkipped then return end

	ShowDialogue("Attempt the 'Story Encounter' when you feel ready. Good luck on your Bizarre Adventure!", true)
	local function getStoryBtn() return FindContentButton("STORY")[1] end
	HighlightDynamicTarget(getStoryBtn, false)

	WaitNext(); if isSkipped then return end

	ClearHighlight()
	Network:WaitForChild("TutorialAction"):FireServer("Complete")

	if tutorialContainer then
		tutorialContainer:Destroy()
	end
end

function TutorialManager.Init(parentGui, switchTabFunc)
	local ls = player:WaitForChild("leaderstats", 15)
	if not ls then return end 
	task.wait(1) 

	if (player:GetAttribute("TutorialStep") or 0) > 0 then return end

	guiRoot = parentGui
	switchTabFuncRef = switchTabFunc
	isSkipped = false 

	LinkUI()

	tutorialContainer.Enabled = true
	task.spawn(RunTutorial)
end

return TutorialManager