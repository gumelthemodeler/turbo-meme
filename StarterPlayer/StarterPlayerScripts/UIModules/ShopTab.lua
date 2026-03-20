-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ShopTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local player = Players.LocalPlayer
local MainFrame
local GridContainer
local TimerLabel

function ShopTab.Init(parentFrame)
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "ShopFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = false
	MainFrame.Parent = parentFrame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(0.5, 0, 0, 40)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBlack
	Title.TextColor3 = Color3.fromRGB(255, 215, 100)
	Title.TextSize = 24
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Text = "MERCHANT SUPPLY"
	Title.Parent = MainFrame

	TimerLabel = Instance.new("TextLabel")
	TimerLabel.Size = UDim2.new(0.5, 0, 0, 40)
	TimerLabel.Position = UDim2.new(0.5, 0, 0, 0)
	TimerLabel.BackgroundTransparency = 1
	TimerLabel.Font = Enum.Font.GothamMedium
	TimerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	TimerLabel.TextSize = 16
	TimerLabel.TextXAlignment = Enum.TextXAlignment.Right
	TimerLabel.Text = "Next Restock: Loading..."
	TimerLabel.Parent = MainFrame

	GridContainer = Instance.new("ScrollingFrame")
	GridContainer.Size = UDim2.new(1, 0, 1, -50)
	GridContainer.Position = UDim2.new(0, 0, 0, 50)
	GridContainer.BackgroundTransparency = 1
	GridContainer.BorderSizePixel = 0
	GridContainer.ScrollBarThickness = 6
	GridContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
	GridContainer.Parent = MainFrame

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 200, 0, 240)
	layout.CellPadding = UDim2.new(0, 15, 0, 15)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = GridContainer

	local function FormatTime(seconds)
		local m = math.floor(seconds / 60)
		local s = seconds % 60
		return string.format("%02d:%02d", m, s)
	end

	-- Timer Loop
	task.spawn(function()
		while task.wait(1) do
			if not MainFrame.Visible then continue end
			local refreshTime = player:GetAttribute("ShopRefreshTime") or 0
			local timeLeft = refreshTime - os.time()
			if timeLeft > 0 then
				TimerLabel.Text = "Next Restock in: " .. FormatTime(timeLeft)
			else
				TimerLabel.Text = "Restocking..."
			end
		end
	end)

	local function RenderShop()
		for _, child in ipairs(GridContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local stockStr = player:GetAttribute("ShopStock") or ""
		if stockStr == "" then return end

		local items = string.split(stockStr, ",")

		for _, itemName in ipairs(items) do
			if itemName == "" then continue end
			local itemInfo = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			if not itemInfo then continue end

			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
			card.Parent = GridContainer

			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
			Instance.new("UIStroke", card).Color = Color3.fromRGB(80, 80, 90)

			local nLabel = Instance.new("TextLabel")
			nLabel.Size = UDim2.new(1, -10, 0, 40)
			nLabel.Position = UDim2.new(0, 5, 0, 5)
			nLabel.BackgroundTransparency = 1
			nLabel.Font = Enum.Font.GothamBold
			nLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nLabel.TextSize = 14
			nLabel.TextWrapped = true
			nLabel.Text = itemName
			nLabel.Parent = card

			local dLabel = Instance.new("TextLabel")
			dLabel.Size = UDim2.new(1, -20, 0, 80)
			dLabel.Position = UDim2.new(0, 10, 0, 50)
			dLabel.BackgroundTransparency = 1
			dLabel.Font = Enum.Font.GothamMedium
			dLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			dLabel.TextSize = 12
			dLabel.TextWrapped = true
			dLabel.TextYAlignment = Enum.TextYAlignment.Top
			dLabel.Text = itemInfo.Desc or "No description."
			dLabel.Parent = card

			local cost = itemInfo.Cost or 999999
			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0.8, 0, 0, 40)
			buyBtn.Position = UDim2.new(0.1, 0, 1, -50)
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			buyBtn.TextSize = 14
			buyBtn.Text = cost .. " DEWS"
			buyBtn.Parent = card

			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

			buyBtn.MouseButton1Click:Connect(function()
				Network:WaitForChild("ShopAction"):FireServer("BuyItem", itemName)
			end)
		end
	end

	player.AttributeChanged:Connect(function(attr)
		if attr == "ShopStock" then RenderShop() end
	end)

	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(action)
		if action == "Restock" then RenderShop() end
	end)

	RenderShop()
end

function ShopTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return ShopTab