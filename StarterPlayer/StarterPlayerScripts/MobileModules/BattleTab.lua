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
	{ Id = 1, Name = "The Fall of Shiganshina", Req = 0, Desc = "The breach of Wall Maria." },
	{ Id = 2, Name = "Clash of the Titans", Req = 1, Desc = "Battle at Utgard Castle." },
	{ Id = 3, Name = "The Uprising", Req = 2, Desc = "Fight the Interior MP." },
	{ Id = 4, Name = "Marleyan Assault", Req = 3, Desc = "Infiltrate Liberio." },
	{ Id = 5, Name = "Return to Shiganshina", Req = 4, Desc = "Reclaim Wall Maria." },
	{ Id = 6, Name = "War for Paradis", Req = 5, Desc = "Marley's counterattack." },
	{ Id = 7, Name = "The Rumbling", Req = 6, Desc = "The end of all things." }
}

function BattleTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "BattleFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	local TopNav = Instance.new("ScrollingFrame", MainFrame)
	TopNav.Size = UDim2.new(1, 0, 0, 50); TopNav.BackgroundColor3 = Color3.fromRGB(15, 15, 18); TopNav.ScrollBarThickness = 0
	TopNav.ScrollingDirection = Enum.ScrollingDirection.X 
	TopNav.AutomaticCanvasSize = Enum.AutomaticSize.X
	Instance.new("UICorner", TopNav).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", TopNav).Color = Color3.fromRGB(120, 100, 60)
	local navLayout = Instance.new("UIListLayout", TopNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 10)
	local nPad = Instance.new("UIPadding", TopNav); nPad.PaddingLeft = UDim.new(0, 10); nPad.PaddingRight = UDim.new(0, 10)

	ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(1, 0, 1, -60); ContentArea.Position = UDim2.new(0, 0, 0, 60); ContentArea.BackgroundTransparency = 1

	local function CreateSubNavBtn(name, text)
		local btn = Instance.new("TextButton", TopNav)
		btn.Size = UDim2.new(0, 150, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextScaled = true; btn.Text = text
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 13
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
	CreateSubNavBtn("Raids", "RAIDS")

	SubTabs["Campaign"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["Campaign"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Campaign"].BackgroundTransparency = 1; SubTabs["Campaign"].BorderSizePixel = 0; SubTabs["Campaign"].ScrollBarThickness = 0; SubTabs["Campaign"].Visible = true
	local cLayout = Instance.new("UIListLayout", SubTabs["Campaign"]); cLayout.Padding = UDim.new(0, 10); cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local cBtns = {}

	for _, dInfo in ipairs(expeditionList) do
		local row = Instance.new("Frame", SubTabs["Campaign"])
		row.Size = UDim2.new(0.95, 0, 0, 100); row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(60, 60, 65)

		local title = Instance.new("TextLabel", row)
		title.Size = UDim2.new(0.9, 0, 0, 25); title.Position = UDim2.new(0, 10, 0, 5); title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextScaled = true; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = dInfo.Name
		Instance.new("UITextSizeConstraint", title).MaxTextSize = 16

		local desc = Instance.new("TextLabel", row)
		desc.Size = UDim2.new(0.9, 0, 0, 25); desc.Position = UDim2.new(0, 10, 0, 30); desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium; desc.TextColor3 = Color3.fromRGB(180, 180, 180); desc.TextScaled = true; desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top; desc.Text = dInfo.Desc
		Instance.new("UITextSizeConstraint", desc).MaxTextSize = 12

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.9, 0, 0, 35); btn.Position = UDim2.new(0.05, 0, 0, 60); btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextScaled = true; btn.Text = "DEPLOY"
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 14
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if btn.Active then Network:WaitForChild("CombatAction"):FireServer("EngageStory", {PartId = dInfo.Id}) end
		end)
		cBtns[dInfo.Id] = { Btn = btn }
	end

	SubTabs["Endless"] = Instance.new("Frame", ContentArea)
	SubTabs["Endless"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Endless"].BackgroundTransparency = 1; SubTabs["Endless"].Visible = false

	local eBox = Instance.new("Frame", SubTabs["Endless"])
	eBox.Size = UDim2.new(0.95, 0, 0.95, 0); eBox.AnchorPoint = Vector2.new(0.5, 0.5); eBox.Position = UDim2.new(0.5, 0, 0.5, 0); eBox.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
	Instance.new("UICorner", eBox).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", eBox).Color = Color3.fromRGB(100, 60, 120)

	local eLayout = Instance.new("UIListLayout", eBox); eLayout.Padding = UDim.new(0, 20); eLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; eLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local eTitle = Instance.new("TextLabel", eBox)
	eTitle.Size = UDim2.new(0.9, 0, 0, 50); eTitle.BackgroundTransparency = 1; eTitle.Font = Enum.Font.GothamBlack; eTitle.TextColor3 = Color3.fromRGB(220, 150, 255); eTitle.TextScaled = true; eTitle.Text = "ENDLESS EXPEDITION"
	Instance.new("UITextSizeConstraint", eTitle).MaxTextSize = 24

	local eBtn = Instance.new("TextButton", eBox)
	eBtn.Size = UDim2.new(0.8, 0, 0, 60); eBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 140)
	eBtn.Font = Enum.Font.GothamBlack; eBtn.TextColor3 = Color3.fromRGB(255, 255, 255); eBtn.TextScaled = true; eBtn.Text = "DEPART"
	Instance.new("UICorner", eBtn).CornerRadius = UDim.new(0, 8); Instance.new("UITextSizeConstraint", eBtn).MaxTextSize = 20
	eBtn.MouseButton1Click:Connect(function() Network:WaitForChild("CombatAction"):FireServer("EngageEndless") end)

	SubTabs["Raids"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["Raids"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Raids"].BackgroundTransparency = 1; SubTabs["Raids"].BorderSizePixel = 0; SubTabs["Raids"].ScrollBarThickness = 0; SubTabs["Raids"].Visible = false
	local rLayout = Instance.new("UIListLayout", SubTabs["Raids"]); rLayout.Padding = UDim.new(0, 10); rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function UpdateLocks()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		for id, data in pairs(cBtns) do
			if currentPart > id then data.Btn.BackgroundColor3 = Color3.fromRGB(30, 80, 120); data.Btn.Text = "COMPLETED ✔"; data.Btn.Active = false 
			elseif currentPart == id then data.Btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40); data.Btn.Text = "DEPLOY"; data.Btn.Active = true
			else data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); data.Btn.Text = "LOCKED"; data.Btn.Active = false end
		end
		task.delay(0.05, function() SubTabs["Campaign"].CanvasSize = UDim2.new(0, 0, 0, cLayout.AbsoluteContentSize.Y + 20) end)
	end

	player.AttributeChanged:Connect(UpdateLocks)
	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10) and player.leaderstats:WaitForChild("Prestige", 10)
		if pObj then pObj.Changed:Connect(UpdateLocks) end
		UpdateLocks()
		TweenService:Create(SubBtns["Campaign"], TweenInfo.new(0), {BackgroundColor3 = Color3.fromRGB(120, 100, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

function BattleTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return BattleTab