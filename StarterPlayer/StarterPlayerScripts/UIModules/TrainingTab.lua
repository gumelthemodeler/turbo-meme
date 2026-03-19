-- @ScriptType: ModuleScript
local TrainingTab = {}

local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local trainLog, trainBarFill, currentTween, toggleTrainBtn, spinningStar, spinConnection
local isTraining = false
local trainTweenInfo = TweenInfo.new(4.8, Enum.EasingStyle.Linear)

local function PlayTrainingTween()
	if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then return end
	trainBarFill.Size = UDim2.new(0, 0, 1, 0)
	currentTween = TweenService:Create(trainBarFill, trainTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	currentTween:Play()
end

function TrainingTab.Init(parentFrame, tooltipMgr)
	local centerContainer = parentFrame:WaitForChild("CenterContainer")

	spinningStar = centerContainer:WaitForChild("SpinningStar")
	trainLog = centerContainer:WaitForChild("TrainLog")

	local trainBarBg = centerContainer:WaitForChild("TrainBarBg")
	trainBarFill = trainBarBg:WaitForChild("TrainBarFill")

	local btnContainer = centerContainer:WaitForChild("BtnContainer")
	toggleTrainBtn = btnContainer:WaitForChild("ToggleTrainBtn")

	toggleTrainBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		isTraining = not isTraining
		game.Players.LocalPlayer:SetAttribute("IsTraining", isTraining)

		if isTraining then
			toggleTrainBtn.Text = "Stop Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			trainLog.Text = "<font color='#55FF55'>Training started... Pushing limits!</font>"
			PlayTrainingTween()
			spinConnection = RunService.RenderStepped:Connect(function() spinningStar.Rotation = spinningStar.Rotation + 0.5 end)
		else
			toggleTrainBtn.Text = "Start Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
			trainLog.Text = "Resting. Start training to gain passive XP/Yen."
			trainBarFill.Size = UDim2.new(0, 0, 1, 0)
			if currentTween then currentTween:Cancel() end
			if spinConnection then spinConnection:Disconnect() end
		end
		Network.ToggleTraining:FireServer(isTraining)
	end)

	task.spawn(function()
		while task.wait(5) do
			if isTraining then PlayTrainingTween() end
		end
	end)

	task.spawn(function()
		task.wait(2)
		if game.Players.LocalPlayer:GetAttribute("HasAutoTraining") and not isTraining then
			isTraining = true
			game.Players.LocalPlayer:SetAttribute("IsTraining", isTraining)
			toggleTrainBtn.Text = "Stop Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			trainLog.Text = "<font color='#55FF55'>Training started... Pushing limits!</font>"
			PlayTrainingTween()
			spinConnection = RunService.RenderStepped:Connect(function() spinningStar.Rotation = spinningStar.Rotation + 0.5 end)
			Network.ToggleTraining:FireServer(isTraining)
		end
	end)
end

function TrainingTab.OnTick(data)
	if isTraining then
		trainLog.Text = "<font color='#55FFFF'>Gained +" .. data.XP .. " XP</font> and <font color='#55FF55'>+" .. data.Yen .. " Yen</font>. (Part " .. data.Part .. " Multiplier!)"
	end
end

return TrainingTab