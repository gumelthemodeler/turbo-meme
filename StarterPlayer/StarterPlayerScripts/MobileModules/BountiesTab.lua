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

local activeTweens = {}

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function BountiesTab.Init(parentFrame, tooltipMgr)
	-- THE FIX: It is now a normal tab inside the ContentFrame! No TopBar overlaps.
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	MainFrame.Name = "BountiesFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
	MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local mainLayout = Instance.new("UIListLayout", MainFrame); mainLayout.SortOrder = Enum.SortOrder.LayoutOrder; mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; mainLayout.Padding = UDim.new(0, 10)

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 50); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 26; Title.Text = "REGIMENT CONTRACTS"
	Title.LayoutOrder = 0
	ApplyGradient(Title, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local Divider = Instance.new("Frame", MainFrame)
	Divider.Size = UDim2.new(0.95, 0, 0, 2); Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70); Divider.BorderSizePixel = 0; Divider.LayoutOrder = 1

	DailiesList = Instance.new("Frame", MainFrame)
	DailiesList.Size = UDim2.new(0.95, 0, 0, 250); DailiesList.BackgroundColor3 = Color3.fromRGB(20, 20, 25); DailiesList.LayoutOrder = 2
	Instance.new("UICorner", DailiesList).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", DailiesList).Color = Color3.fromRGB(80, 80, 90)
	local dLayout = Instance.new("UIListLayout", DailiesList); dLayout.Padding = UDim.new(0, 8); dLayout.SortOrder = Enum.SortOrder.LayoutOrder; dLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local dHeader = Instance.new("TextLabel", DailiesList)
	dHeader.Size = UDim2.new(0.95, 0, 0, 35); dHeader.BackgroundTransparency = 1; dHeader.Font = Enum.Font.GothamBlack; dHeader.TextColor3 = Color3.fromRGB(200, 200, 200); dHeader.TextScaled = true; dHeader.TextXAlignment = Enum.TextXAlignment.Left; dHeader.Text = "DAILY BOUNTIES (Resets at Midnight)"
	dHeader.LayoutOrder = 0; Instance.new("UITextSizeConstraint", dHeader).MaxTextSize = 16

	WeekliesList = Instance.new("Frame", MainFrame)
	WeekliesList.Size = UDim2.new(0.95, 0, 0, 150); WeekliesList.BackgroundColor3 = Color3.fromRGB(20, 20, 25); WeekliesList.LayoutOrder = 3
	Instance.new("UICorner", WeekliesList).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", WeekliesList).Color = Color3.fromRGB(80, 80, 90)
	local wLayout = Instance.new("UIListLayout", WeekliesList); wLayout.Padding = UDim.new(0, 8); wLayout.SortOrder = Enum.SortOrder.LayoutOrder; wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local wHeader = Instance.new("TextLabel", WeekliesList)
	wHeader.Size = UDim2.new(0.95, 0, 0, 35); wHeader.BackgroundTransparency = 1; wHeader.Font = Enum.Font.GothamBlack; wHeader.TextColor3 = Color3.fromRGB(200, 150, 255); wHeader.TextScaled = true; wHeader.TextXAlignment = Enum.TextXAlignment.Left; wHeader.Text = "WEEKLY DIRECTIVE (Resets on Sunday)"
	wHeader.LayoutOrder = 0; Instance.new("UITextSizeConstraint", wHeader).MaxTextSize = 16

	local function CreateBountyRow(parent, idKey, isWeekly, order)
		local row = Instance.new("Frame", parent)
		row.Name = idKey; row.Size = UDim2.new(0.95, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		row.LayoutOrder = order
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local infoLbl = Instance.new("TextLabel", row)
		infoLbl.Name = "Info"; infoLbl.Size = UDim2.new(0.65, 0, 0, 25); infoLbl.Position = UDim2.new(0, 15, 0, 5); infoLbl.BackgroundTransparency = 1; infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextColor3 = Color3.fromRGB(255, 255, 255); infoLbl.TextScaled = true; infoLbl.TextXAlignment = Enum.TextXAlignment.Left; infoLbl.RichText = true
		infoLbl.Text = "Loading contract data..."; Instance.new("UITextSizeConstraint", infoLbl).MaxTextSize = 14

		local barCont = Instance.new("Frame", row)
		barCont.Size = UDim2.new(0.65, 0, 0, 15); barCont.Position = UDim2.new(0, 15, 0, 35); barCont.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Instance.new("UICorner", barCont).CornerRadius = UDim.new(0, 4)

		local fill = Instance.new("Frame", barCont)
		fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(80, 200, 80); Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

		local btn = Instance.new("TextButton", row)
		btn.Name = "ActionBtn"; btn.Size = UDim2.new(0.28, 0, 0, 40); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -10, 0.5, 0); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); btn.Font = Enum.Font.GothamBlack; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.TextScaled = true; btn.Text = "IN PROGRESS"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6); Instance.new("UITextSizeConstraint", btn).MaxTextSize = 12

		btn.MouseButton1Click:Connect(function()
			local prog = player:GetAttribute(idKey .. "_Prog") or 0
			local max = player:GetAttribute(idKey .. "_Max") or 1
			local claimed = player:GetAttribute(idKey .. "_Claimed")
			if prog >= max and not claimed then Network.ClaimBounty:FireServer(idKey) end
		end)
	end

	CreateBountyRow(DailiesList, "D1", false, 1)
	CreateBountyRow(DailiesList, "D2", false, 2)
	CreateBountyRow(DailiesList, "D3", false, 3)
	CreateBountyRow(WeekliesList, "W1", true, 1)

	local function UpdateUI()
		local function UpdateRow(row, idKey, isWeekly)
			if not row then return end
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

			if row:FindFirstChild("Info") then
				row.Info.Text = desc .. " (" .. prog .. "/" .. max .. ")" .. rewardStr
			end

			if row:FindFirstChild("Fill") then
				TweenService:Create(row.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.new(math.clamp(prog / max, 0, 1), 0, 1, 0)}):Play()
			end

			local btn = row:FindFirstChild("ActionBtn")
			if btn then
				if claimed then
					btn.Text = "CLAIMED"; btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
					if activeTweens[btn] then activeTweens[btn]:Cancel(); activeTweens[btn] = nil end
				elseif prog >= max then
					btn.Text = "CLAIM"; btn.BackgroundColor3 = Color3.fromRGB(200, 150, 40); btn.TextColor3 = Color3.fromRGB(255, 255, 255)

					if not activeTweens[btn] then
						local pulse = TweenService:Create(btn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3 = Color3.fromRGB(255, 200, 80)})
						pulse:Play()
						activeTweens[btn] = pulse
					end
				else
					btn.Text = "IN PROGRESS"; btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
					if activeTweens[btn] then 
						activeTweens[btn]:Cancel()
						activeTweens[btn] = nil 
					end
				end
			end
		end

		UpdateRow(DailiesList:FindFirstChild("D1"), "D1", false)
		UpdateRow(DailiesList:FindFirstChild("D2"), "D2", false)
		UpdateRow(DailiesList:FindFirstChild("D3"), "D3", false)
		UpdateRow(WeekliesList:FindFirstChild("W1"), "W1", true)
	end

	player.AttributeChanged:Connect(UpdateUI)
	UpdateUI()
	task.spawn(function() task.wait(1); UpdateUI(); task.wait(2); UpdateUI() end)
end

function BountiesTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return BountiesTab