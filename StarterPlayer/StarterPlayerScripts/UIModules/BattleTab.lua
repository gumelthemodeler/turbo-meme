-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BattleTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local player = Players.LocalPlayer
local MainFrame
local ContentArea
local SubTabs = {}
local SubBtns = {}

local expeditionList = {
	{ Id = 1, Name = "The Fall of Shiganshina", Req = 0, Desc = "The breach of Wall Maria. Survival is the only objective." },
	{ Id = 2, Name = "Clash of the Titans", Req = 1, Desc = "Battle at Utgard Castle and the treacherous betrayal." },
	{ Id = 3, Name = "The Uprising", Req = 2, Desc = "Fight the Interior MP and uncover the royal bloodline." },
	{ Id = 4, Name = "Marleyan Assault", Req = 3, Desc = "Infiltrate Liberio. Strike at the heart of the enemy." },
	{ Id = 5, Name = "Return to Shiganshina", Req = 4, Desc = "Reclaim Wall Maria. Beware the beast's pitch." },
	{ Id = 6, Name = "War for Paradis", Req = 5, Desc = "Marley's counterattack. A desperate struggle for the Founder." },
	{ Id = 7, Name = "The Rumbling", Req = 6, Desc = "March of the Wall Titans. The end of all things." }
}

local raidList = {
	{ Id = "Raid_Part1", Name = "Female Titan", Req = 1, Desc = "A deadly raid against a highly intelligent shifter." },
	{ Id = "Raid_Part2", Name = "Armored Titan", Req = 2, Desc = "Pierce the Bastion's armor. Bring Thunder Spears!" },
	{ Id = "Raid_Part3", Name = "Beast Titan", Req = 3, Desc = "Avoid the crushed boulders. A terrifying intellect." },
	{ Id = "Raid_Part5", Name = "Founding Titan (Eren)", Req = 5, Desc = "The Coordinate commands all. Survive the Rumbling." }
}

function BattleTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "BattleFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	-- [[ SUB-NAVIGATION BAR ]]
	local TopNav = Instance.new("Frame", MainFrame)
	TopNav.Size = UDim2.new(1, 0, 0, 50); TopNav.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	Instance.new("UICorner", TopNav).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", TopNav).Color = Color3.fromRGB(120, 100, 60)
	local navLayout = Instance.new("UIListLayout", TopNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 20)

	ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(1, 0, 1, -70); ContentArea.Position = UDim2.new(0, 0, 0, 70); ContentArea.BackgroundTransparency = 1

	local function CreateSubNavBtn(name, text)
		local btn = Instance.new("TextButton", TopNav)
		btn.Size = UDim2.new(0, 180, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextSize = 14; btn.Text = text
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 65)

		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do TweenService:Create(v, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play() end
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 100, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			for k, frame in pairs(SubTabs) do frame.Visible = (k == name) end
		end)
		SubBtns[name] = btn
		return btn
	end

	CreateSubNavBtn("Campaign", "CAMPAIGN")
	CreateSubNavBtn("Endless", "ENDLESS EXPEDITION")
	CreateSubNavBtn("Raids", "MULTIPLAYER RAIDS")
	CreateSubNavBtn("World", "WORLD BOSSES")

	-- [[ 1. CAMPAIGN TAB ]]
	SubTabs["Campaign"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["Campaign"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Campaign"].BackgroundTransparency = 1; SubTabs["Campaign"].BorderSizePixel = 0; SubTabs["Campaign"].ScrollBarThickness = 6; SubTabs["Campaign"].Visible = true
	local cLayout = Instance.new("UIListLayout", SubTabs["Campaign"]); cLayout.Padding = UDim.new(0, 10); cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local cBtns = {}

	for _, dInfo in ipairs(expeditionList) do
		local row = Instance.new("Frame", SubTabs["Campaign"])
		row.Size = UDim2.new(0.7, 0, 0, 80); row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(60, 60, 65)

		local title = Instance.new("TextLabel", row)
		title.Size = UDim2.new(0.65, 0, 0, 25); title.Position = UDim2.new(0, 10, 0, 5); title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = dInfo.Name

		local desc = Instance.new("TextLabel", row)
		desc.Size = UDim2.new(0.65, 0, 0, 40); desc.Position = UDim2.new(0, 10, 0, 30); desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium; desc.TextColor3 = Color3.fromRGB(180, 180, 180); desc.TextSize = 12; desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top; desc.Text = dInfo.Desc

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.25, 0, 0, 40); btn.Position = UDim2.new(0.72, 0, 0.5, -20); btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 14; btn.Text = "DEPLOY"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if btn.Active then Network:WaitForChild("CombatAction"):FireServer("EngageStory", {PartId = dInfo.Id}) end
		end)
		cBtns[dInfo.Id] = { Btn = btn }
	end

	-- [[ 2. ENDLESS EXPEDITION TAB ]]
	SubTabs["Endless"] = Instance.new("Frame", ContentArea)
	SubTabs["Endless"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Endless"].BackgroundTransparency = 1; SubTabs["Endless"].Visible = false

	local eBox = Instance.new("Frame", SubTabs["Endless"])
	eBox.Size = UDim2.new(0.6, 0, 0.6, 0); eBox.Position = UDim2.new(0.2, 0, 0.1, 0); eBox.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
	Instance.new("UICorner", eBox).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", eBox).Color = Color3.fromRGB(100, 60, 120)

	local eTitle = Instance.new("TextLabel", eBox)
	eTitle.Size = UDim2.new(1, 0, 0, 50); eTitle.BackgroundTransparency = 1; eTitle.Font = Enum.Font.GothamBlack; eTitle.TextColor3 = Color3.fromRGB(220, 150, 255); eTitle.TextSize = 28; eTitle.Text = "ENDLESS EXPEDITION"

	local eDesc = Instance.new("TextLabel", eBox)
	eDesc.Size = UDim2.new(0.8, 0, 0, 100); eDesc.Position = UDim2.new(0.1, 0, 0, 60); eDesc.BackgroundTransparency = 1
	eDesc.Font = Enum.Font.GothamMedium; eDesc.TextColor3 = Color3.fromRGB(200, 200, 200); eDesc.TextSize = 16; eDesc.TextWrapped = true; eDesc.Text = "Venture beyond the walls continuously. You will fight random enemies matching your highest unlocked Campaign Part. Drops are permanently multiplied by 1.2x. How long can you survive?"

	local eBtn = Instance.new("TextButton", eBox)
	eBtn.Size = UDim2.new(0.5, 0, 0, 60); eBtn.Position = UDim2.new(0.25, 0, 0.7, 0); eBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 140)
	eBtn.Font = Enum.Font.GothamBlack; eBtn.TextColor3 = Color3.fromRGB(255, 255, 255); eBtn.TextSize = 20; eBtn.Text = "DEPART"
	Instance.new("UICorner", eBtn).CornerRadius = UDim.new(0, 8)
	eBtn.MouseButton1Click:Connect(function() Network:WaitForChild("CombatAction"):FireServer("EngageEndless") end)


	-- [[ 3. RAIDS TAB ]]
	SubTabs["Raids"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["Raids"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Raids"].BackgroundTransparency = 1; SubTabs["Raids"].BorderSizePixel = 0; SubTabs["Raids"].ScrollBarThickness = 6; SubTabs["Raids"].Visible = false
	local rLayout = Instance.new("UIListLayout", SubTabs["Raids"]); rLayout.Padding = UDim.new(0, 10); rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local rBtns = {}

	for _, rInfo in ipairs(raidList) do
		local row = Instance.new("Frame", SubTabs["Raids"])
		row.Size = UDim2.new(0.7, 0, 0, 80); row.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(90, 40, 40)

		local title = Instance.new("TextLabel", row)
		title.Size = UDim2.new(0.65, 0, 0, 25); title.Position = UDim2.new(0, 10, 0, 5); title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(255, 100, 100); title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = rInfo.Name

		local desc = Instance.new("TextLabel", row)
		desc.Size = UDim2.new(0.65, 0, 0, 40); desc.Position = UDim2.new(0, 10, 0, 30); desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium; desc.TextColor3 = Color3.fromRGB(180, 180, 180); desc.TextSize = 12; desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top; desc.Text = rInfo.Desc

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.25, 0, 0, 40); btn.Position = UDim2.new(0.72, 0, 0.5, -20); btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 14; btn.Text = "HOST LOBBY"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if btn.Active then Network:WaitForChild("RaidAction"):FireServer("CreateLobby", {RaidId = rInfo.Id, FriendsOnly = false}) end
		end)
		rBtns[rInfo.Id] = { Btn = btn, Req = rInfo.Req }
	end


	-- [[ 4. WORLD EVENTS TAB ]]
	SubTabs["World"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["World"].Size = UDim2.new(1, 0, 1, 0); SubTabs["World"].BackgroundTransparency = 1; SubTabs["World"].BorderSizePixel = 0; SubTabs["World"].ScrollBarThickness = 6; SubTabs["World"].Visible = false
	local wLayout = Instance.new("UIListLayout", SubTabs["World"]); wLayout.Padding = UDim.new(0, 10); wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	for bId, bData in pairs(EnemyData.WorldBosses) do
		local row = Instance.new("Frame", SubTabs["World"])
		row.Size = UDim2.new(0.7, 0, 0, 80); row.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(120, 80, 40)

		local title = Instance.new("TextLabel", row)
		title.Size = UDim2.new(0.65, 0, 0, 25); title.Position = UDim2.new(0, 10, 0, 5); title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(255, 180, 50); title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = bData.Name

		local desc = Instance.new("TextLabel", row)
		desc.Size = UDim2.new(0.65, 0, 0, 40); desc.Position = UDim2.new(0, 10, 0, 30); desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium; desc.TextColor3 = Color3.fromRGB(180, 180, 180); desc.TextSize = 12; desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top; desc.Text = "A massive world boss event. Extremely dangerous."

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.25, 0, 0, 40); btn.Position = UDim2.new(0.72, 0, 0.5, -20); btn.BackgroundColor3 = Color3.fromRGB(120, 80, 30)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 14; btn.Text = "ENGAGE"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			Network:WaitForChild("CombatAction"):FireServer("EngageWorldBoss", {BossId = bId})
		end)
	end


	local function UpdateLocks()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		-- THE FIX: Supports marking Part 7 as COMPLETED!
		for id, data in pairs(cBtns) do
			if currentPart > id then
				data.Btn.BackgroundColor3 = Color3.fromRGB(30, 80, 120) 
				data.Btn.TextSize = 14; data.Btn.Text = "COMPLETED ✔"; data.Btn.Active = false 
			elseif currentPart == id then
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40) 
				data.Btn.TextSize = 14; data.Btn.Text = "DEPLOY"; data.Btn.Active = true
			else
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
				data.Btn.TextSize = 14; data.Btn.Text = "LOCKED"; data.Btn.Active = false
			end
		end

		for _, data in pairs(rBtns) do
			if prestige < data.Req then
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); data.Btn.Text = "LOCKED"; data.Btn.Active = false
			else
				data.Btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40); data.Btn.Text = "HOST LOBBY"; data.Btn.Active = true
			end
		end

		task.delay(0.05, function() SubTabs["Campaign"].CanvasSize = UDim2.new(0, 0, 0, cLayout.AbsoluteContentSize.Y + 20) end)
		task.delay(0.05, function() SubTabs["Raids"].CanvasSize = UDim2.new(0, 0, 0, rLayout.AbsoluteContentSize.Y + 20) end)
		task.delay(0.05, function() SubTabs["World"].CanvasSize = UDim2.new(0, 0, 0, wLayout.AbsoluteContentSize.Y + 20) end)
	end

	player.AttributeChanged:Connect(UpdateLocks)
	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10) and player.leaderstats:WaitForChild("Prestige", 10)
		if pObj then pObj.Changed:Connect(UpdateLocks) end
		UpdateLocks()
		-- Set initial active tab
		TweenService:Create(SubBtns["Campaign"], TweenInfo.new(0), {BackgroundColor3 = Color3.fromRGB(120, 100, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

function BattleTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return BattleTab