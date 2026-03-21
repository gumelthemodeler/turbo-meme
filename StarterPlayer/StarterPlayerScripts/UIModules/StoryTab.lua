-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local StoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local randomEncounterBtn, storyEncounterBtn, prestigeBtn

function StoryTab.Init(parentFrame, tooltipMgr, focusFunc, passedModifierBubble)
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "EncounterButtons"
	buttonContainer.Size = UDim2.new(1, 0, 0.4, 0)
	buttonContainer.Position = UDim2.new(0, 0, 0.3, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = parentFrame

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Padding = UDim.new(0, 20)
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Parent = buttonContainer

	local function makeBtn(name, text, color)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0.28, 0, 0.6, 0)
		btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 50)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 235, 130)
		btn.TextScaled = true
		btn.Parent = buttonContainer

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local str = Instance.new("UIStroke", btn)
		str.Color = Color3.fromRGB(90, 50, 120)
		str.Thickness = 2
		str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local ts = Instance.new("UITextSizeConstraint", btn)
		ts.MaxTextSize = 24
		ts.MinTextSize = 10

		return btn
	end

	prestigeBtn = makeBtn("PrestigeBtn", "Prestige", Color3.fromRGB(120, 30, 30))
	prestigeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
	prestigeBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(200, 50, 50)
	prestigeBtn.LayoutOrder = 0
	prestigeBtn.Visible = false

	randomEncounterBtn = makeBtn("RandomEncounterBtn", "Random Encounter")
	randomEncounterBtn.LayoutOrder = 1

	storyEncounterBtn = makeBtn("StoryEncounterBtn", "Story Encounter")
	storyEncounterBtn.LayoutOrder = 2

	randomEncounterBtn.MouseButton1Click:Connect(function() 
		Network.CombatAction:FireServer("EngageRandom") 
	end)

	storyEncounterBtn.MouseButton1Click:Connect(function() 
		Network.CombatAction:FireServer("EngageStory") 
	end)

	prestigeBtn.MouseButton1Click:Connect(function() 
		Network.PrestigeEvent:FireServer() 
	end)

	local function UpdateStoryUI()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		if currentPart >= 8 then 
			randomEncounterBtn.Visible = false; storyEncounterBtn.Visible = false; prestigeBtn.Visible = true
		elseif currentPart == 7 then 
			randomEncounterBtn.Visible = false; storyEncounterBtn.Visible = true; prestigeBtn.Visible = true
		else 
			randomEncounterBtn.Visible = true; storyEncounterBtn.Visible = true; prestigeBtn.Visible = false 
		end

		local partData = EnemyData.Parts[currentPart]
		if partData then
			local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
			storyEncounterBtn.Text = "Story: " .. missionTable[1].Name
		end
	end

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("CurrentPart"):Connect(UpdateStoryUI)
	UpdateStoryUI()
end

return StoryTab