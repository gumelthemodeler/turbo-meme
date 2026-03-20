-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BattleTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local MainFrame

local expeditionList = {
	{ Id = 1, Name = "The Fall of Shiganshina", Req = 0, Desc = "The breach of Wall Maria. Survival is the only objective." },
	{ Id = 2, Name = "Clash of the Titans", Req = 1, Desc = "Battle at Utgard Castle and the treacherous betrayal." },
	{ Id = 3, Name = "The Uprising", Req = 2, Desc = "Fight the Interior MP and uncover the royal bloodline." },
	{ Id = 4, Name = "Marleyan Assault", Req = 3, Desc = "Infiltrate Liberio. Strike at the heart of the enemy." },
	{ Id = 5, Name = "Return to Shiganshina", Req = 4, Desc = "Reclaim Wall Maria. Beware the beast's pitch." },
	{ Id = 6, Name = "War for Paradis", Req = 5, Desc = "Marley's counterattack. A desperate struggle for the Founder." },
	{ Id = 7, Name = "The Rumbling", Req = 6, Desc = "March of the Wall Titans. The end of all things." },
	{ Id = "Endless", Name = "Endless Expedition", Req = 2, Desc = "Venture beyond the walls. Survive as long as possible for massive rewards." }
}

local raidList = {
	{ Id = "Raid_Part1", Name = "Female Titan", Req = 1, Desc = "A deadly raid against a highly intelligent shifter." },
	{ Id = "Raid_Part2", Name = "Armored Titan", Req = 2, Desc = "Pierce the Bastion's armor. Bring Thunder Spears!" },
	{ Id = "Raid_Part3", Name = "Beast Titan", Req = 3, Desc = "Avoid the crushed boulders. A terrifying intellect." },
	{ Id = "Raid_Part5", Name = "Founding Titan (Eren)", Req = 5, Desc = "The Coordinate commands all. Survive the Rumbling." }
}

function BattleTab.Init(parentFrame)
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "BattleFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = false
	MainFrame.Parent = parentFrame

	-- [[ CAMPAIGN SECTION - LEFT ]]
	local CampFrame = Instance.new("Frame")
	CampFrame.Size = UDim2.new(0.48, 0, 1, 0)
	CampFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	CampFrame.Parent = MainFrame
	Instance.new("UICorner", CampFrame).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", CampFrame).Color = Color3.fromRGB(80, 80, 90)

	local CampTitle = Instance.new("TextLabel")
	CampTitle.Size = UDim2.new(1, 0, 0, 40)
	CampTitle.BackgroundTransparency = 1
	CampTitle.Font = Enum.Font.GothamBlack
	CampTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
	CampTitle.TextSize = 20
	CampTitle.Text = "CAMPAIGN & ENDLESS"
	CampTitle.Parent = CampFrame

	local CampScroll = Instance.new("ScrollingFrame")
	CampScroll.Size = UDim2.new(1, -20, 1, -50)
	CampScroll.Position = UDim2.new(0, 10, 0, 40)
	CampScroll.BackgroundTransparency = 1
	CampScroll.BorderSizePixel = 0
	CampScroll.ScrollBarThickness = 6
	CampScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
	CampScroll.Parent = CampFrame

	local cLayout = Instance.new("UIListLayout")
	cLayout.Padding = UDim.new(0, 10)
	cLayout.Parent = CampScroll

	local cButtons = {}

	for _, dInfo in ipairs(expeditionList) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 90)
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		row.Parent = CampScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", row).Color = Color3.fromRGB(60, 60, 65)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.65, 0, 0, 25)
		title.Position = UDim2.new(0, 10, 0, 5)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = dInfo.Name
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.65, 0, 0, 40)
		desc.Position = UDim2.new(0, 10, 0, 30)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.TextColor3 = Color3.fromRGB(180, 180, 180)
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Text = dInfo.Desc
		desc.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.3, 0, 0, 40)
		btn.Position = UDim2.new(0.68, 0, 0.5, -20)
		btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 14
		btn.Text = "DEPLOY"
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if btn.Active then
				Network:WaitForChild("CombatAction"):FireServer("EngageStory") -- Or map to Dungeons based on backend setup
			end
		end)

		cButtons[dInfo.Id] = { Btn = btn, Req = dInfo.Req }
	end

	-- [[ RAIDS SECTION - RIGHT ]]
	local RaidFrame = Instance.new("Frame")
	RaidFrame.Size = UDim2.new(0.48, 0, 1, 0)
	RaidFrame.Position = UDim2.new(0.52, 0, 0, 0)
	RaidFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	RaidFrame.Parent = MainFrame
	Instance.new("UICorner", RaidFrame).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", RaidFrame).Color = Color3.fromRGB(80, 80, 90)

	local RaidTitle = Instance.new("TextLabel")
	RaidTitle.Size = UDim2.new(1, 0, 0, 40)
	RaidTitle.BackgroundTransparency = 1
	RaidTitle.Font = Enum.Font.GothamBlack
	RaidTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
	RaidTitle.TextSize = 20
	RaidTitle.Text = "MULTIPLAYER RAIDS"
	RaidTitle.Parent = RaidFrame

	local RaidScroll = Instance.new("ScrollingFrame")
	RaidScroll.Size = UDim2.new(1, -20, 1, -50)
	RaidScroll.Position = UDim2.new(0, 10, 0, 40)
	RaidScroll.BackgroundTransparency = 1
	RaidScroll.BorderSizePixel = 0
	RaidScroll.ScrollBarThickness = 6
	RaidScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
	RaidScroll.Parent = RaidFrame

	local rLayout = Instance.new("UIListLayout")
	rLayout.Padding = UDim.new(0, 10)
	rLayout.Parent = RaidScroll

	local rButtons = {}

	for _, rInfo in ipairs(raidList) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 90)
		row.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
		row.Parent = RaidScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", row).Color = Color3.fromRGB(90, 40, 40)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.65, 0, 0, 25)
		title.Position = UDim2.new(0, 10, 0, 5)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = Color3.fromRGB(255, 100, 100)
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = rInfo.Name
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.65, 0, 0, 40)
		desc.Position = UDim2.new(0, 10, 0, 30)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.TextColor3 = Color3.fromRGB(180, 180, 180)
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Text = rInfo.Desc
		desc.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.3, 0, 0, 40)
		btn.Position = UDim2.new(0.68, 0, 0.5, -20)
		btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 14
		btn.Text = "HOST LOBBY"
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if btn.Active then
				Network:WaitForChild("RaidAction"):FireServer("CreateLobby", {RaidId = rInfo.Id, FriendsOnly = false})
			end
		end)

		rButtons[rInfo.Id] = { Btn = btn, Req = rInfo.Req }
	end

	-- Lock Updates
	local function UpdateLocks()
		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		for _, data in pairs(cButtons) do
			if prestige < data.Req then
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
				data.Btn.Text = "LOCKED"
				data.Btn.Active = false
			else
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
				data.Btn.Text = "DEPLOY"
				data.Btn.Active = true
			end
		end

		for _, data in pairs(rButtons) do
			if prestige < data.Req then
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
				data.Btn.Text = "LOCKED"
				data.Btn.Active = false
			else
				data.Btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
				data.Btn.Text = "HOST LOBBY"
				data.Btn.Active = true
			end
		end
	end

	player.AttributeChanged:Connect(UpdateLocks)
	task.spawn(function()
		local prestigeObj = player:WaitForChild("leaderstats", 10) and player.leaderstats:WaitForChild("Prestige", 10)
		if prestigeObj then prestigeObj.Changed:Connect(UpdateLocks) end
		UpdateLocks()
	end)
end

function BattleTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return BattleTab