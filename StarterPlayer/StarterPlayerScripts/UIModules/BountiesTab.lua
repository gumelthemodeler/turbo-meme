-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BountiesTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local MainFrame
local DailiesList, WeekliesList

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function BountiesTab.Init(parentFrame, tooltipMgr)
	-- Automatically attach a button to the existing TopBar!
	local topGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
	local topBar = topGui and topGui:FindFirstChild("TopBar")

	if topBar then
		local openBtn = Instance.new("TextButton", topBar)
		openBtn.Name = "BountiesOpenBtn"
		openBtn.Size = UDim2.new(0, 160, 0, 35)
		openBtn.BackgroundColor3 = Color3.fromRGB(150, 110, 40)
		openBtn.Font = Enum.Font.GothamBlack; openBtn.TextColor3 = Color3.fromRGB(255, 255, 255); openBtn.TextSize = 14; openBtn.Text = "📜 BOUNTIES"
		Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", openBtn).Color = Color3.fromRGB(200, 150, 50)

		openBtn.MouseButton1Click:Connect(function()
			if MainFrame then MainFrame.Visible = not MainFrame.Visible end
		end)
	end

	-- Floating UI Window
	MainFrame = Instance.new("Frame", parentFrame.Parent)
	MainFrame.Name = "BountiesFrame"; MainFrame.Size = UDim2.new(0, 650, 0, 500); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); MainFrame.Visible = false; MainFrame.ZIndex = 150
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(80, 80, 90)

	local CloseBtn = Instance.new("TextButton", MainFrame)
	CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -10, 0, -10); CloseBtn.AnchorPoint = Vector2.new(1, 0); CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.TextSize = 14; CloseBtn.Text = "X"; CloseBtn.ZIndex = 155
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)
	CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 50); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 26; Title.Text = "REGIMENT CONTRACTS"
	ApplyGradient(Title, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local Divider = Instance.new("Frame", MainFrame)
	Divider.Size = UDim2.new(0.9, 0, 0, 2); Divider.Position = UDim2.new(0.05, 0, 0, 50); Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70); Divider.BorderSizePixel = 0

	DailiesList = Instance.new("Frame", MainFrame)
	DailiesList.Size = UDim2.new(0.9, 0, 0.5, 0); DailiesList.Position = UDim2.new(0.05, 0, 0, 60); DailiesList.BackgroundTransparency = 1
	local dLayout = Instance.new("UIListLayout", DailiesList); dLayout.Padding = UDim.new(0, 8)

	local dHeader = Instance.new("TextLabel", DailiesList)
	dHeader.Size = UDim2.new(1, 0, 0, 30); dHeader.BackgroundTransparency = 1; dHeader.Font = Enum.Font.GothamBlack; dHeader.TextColor3 = Color3.fromRGB(200, 200, 200); dHeader.TextSize = 16; dHeader.TextXAlignment = Enum.TextXAlignment.Left; dHeader.Text = "DAILY BOUNTIES (Resets at Midnight)"

	WeekliesList = Instance.new("Frame", MainFrame)
	WeekliesList.Size = UDim2.new(0.9, 0, 0.3, 0); WeekliesList.Position = UDim2.new(0.05, 0, 0.65, 0); WeekliesList.BackgroundTransparency = 1
	local wLayout = Instance.new("UIListLayout", WeekliesList); wLayout.Padding = UDim.new(0, 8)

	local wHeader = Instance.new("TextLabel", WeekliesList)
	wHeader.Size = UDim2.new(1, 0, 0, 30); wHeader.BackgroundTransparency = 1; wHeader.Font = Enum.Font.GothamBlack; wHeader.TextColor3 = Color3.fromRGB(200, 150, 255); wHeader.TextSize = 16; wHeader.TextXAlignment = Enum.TextXAlignment.Left; wHeader.Text = "WEEKLY DIRECTIVE (Resets on Sunday)"

	local function CreateBountyRow(parent, idKey, isWeekly)
		local row = Instance.new("Frame", parent)
		row.Name = idKey; row.Size = UDim2.new(1, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local infoLbl = Instance.new("TextLabel", row)
		infoLbl.Name = "Info"; infoLbl.Size = UDim2.new(0.7, 0, 0, 25); infoLbl.Position = UDim2.new(0, 15, 0, 5); infoLbl.BackgroundTransparency = 1; infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextColor3 = Color3.fromRGB(255, 255, 255); infoLbl.TextSize = 14; infoLbl.TextXAlignment = Enum.TextXAlignment.Left; infoLbl.RichText = true

		local barCont = Instance.new("Frame", row)
		barCont.Size = UDim2.new(0.7, 0, 0, 15); barCont.Position = UDim2.new(0, 15, 0, 35); barCont.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Instance.new("UICorner", barCont).CornerRadius = UDim.new(0, 4)

		local fill = Instance.new("Frame", barCont)
		fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(80, 200, 80); Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

		local btn = Instance.new("TextButton", row)
		btn.Name = "ActionBtn"; btn.Size = UDim2.new(0, 120, 0, 40); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -10, 0.5, 0); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); btn.Font = Enum.Font.GothamBlack; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.TextSize = 14; btn.Text = "IN PROGRESS"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			local prog = player:GetAttribute(idKey .. "_Prog") or 0
			local max = player:GetAttribute(idKey .. "_Max") or 1
			local claimed = player:GetAttribute(idKey .. "_Claimed")
			if prog >= max and not claimed then Network.ClaimBounty:FireServer(idKey) end
		end)
	end

	CreateBountyRow(DailiesList, "D1", false)
	CreateBountyRow(DailiesList, "D2", false)
	CreateBountyRow(DailiesList, "D3", false)
	CreateBountyRow(WeekliesList, "W1", true)

	local function UpdateUI()
		local function UpdateRow(row, idKey, isWeekly)
			local desc = player:GetAttribute(idKey .. "_Desc") or "Loading..."
			local prog = player:GetAttribute(idKey .. "_Prog") or 0
			local max = player:GetAttribute(idKey .. "_Max") or 1
			local claimed = player:GetAttribute(idKey .. "_Claimed") or false

			local rewardStr = ""
			if isWeekly then
				local rType = player:GetAttribute(idKey .. "_RewardType") or "Item"
				local rAmt = player:GetAttribute(idKey .. "_RewardAmt") or 1
				rewardStr = " <font color='#FF55FF'>[Reward: " .. rAmt .. "x " .. rType .. "]</font>"
			else
				local dews = player:GetAttribute(idKey .. "_Reward") or 0
				rewardStr = " <font color='#55FF55'>[Reward: " .. dews .. " Dews]</font>"
			end

			row.Info.Text = desc .. " (" .. prog .. "/" .. max .. ")" .. rewardStr
			TweenService:Create(row.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.new(math.clamp(prog / max, 0, 1), 0, 1, 0)}):Play()

			local btn = row.ActionBtn
			if claimed then
				btn.Text = "CLAIMED"; btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
			elseif prog >= max then
				btn.Text = "CLAIM"; btn.BackgroundColor3 = Color3.fromRGB(200, 150, 40); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				local pulse = TweenService:Create(btn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3 = Color3.fromRGB(255, 200, 80)})
				pulse:Play(); btn:SetAttribute("PulseAnim", pulse)
			else
				btn.Text = "IN PROGRESS"; btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
				if btn:GetAttribute("PulseAnim") then btn:GetAttribute("PulseAnim"):Cancel(); btn:SetAttribute("PulseAnim", nil) end
			end
		end

		UpdateRow(DailiesList.D1, "D1", false)
		UpdateRow(DailiesList.D2, "D2", false)
		UpdateRow(DailiesList.D3, "D3", false)
		UpdateRow(WeekliesList.W1, "W1", true)
	end

	player.AttributeChanged:Connect(UpdateUI)
	UpdateUI()
end

function BountiesTab.Show() end

return BountiesTab