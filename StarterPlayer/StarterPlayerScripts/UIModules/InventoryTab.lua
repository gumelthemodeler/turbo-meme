-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local InventoryTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))

local player = Players.LocalPlayer
local MainFrame
local ItemGrid
local DetailsPanel
local AutoRollModal

local selectedItem = nil

-- Helper to create stylized buttons
local function CreateButton(parent, name, text, bgColor, pos, size)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size or UDim2.new(1, 0, 0, 40)
	btn.Position = pos or UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = bgColor
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.Text = text
	btn.Parent = parent

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 65)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(bgColor.R * 1.2, bgColor.G * 1.2, bgColor.B * 1.2)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = bgColor}):Play()
	end)

	return btn
end

function InventoryTab.Init(parentFrame)
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "InventoryFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = false
	MainFrame.Parent = parentFrame

	-- [[ ITEM GRID - LEFT ]]
	local GridContainer = Instance.new("Frame")
	GridContainer.Size = UDim2.new(0.65, 0, 1, 0)
	GridContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	GridContainer.Parent = MainFrame

	Instance.new("UICorner", GridContainer).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", GridContainer).Color = Color3.fromRGB(80, 80, 90)

	local GridTitle = Instance.new("TextLabel")
	GridTitle.Size = UDim2.new(1, 0, 0, 40)
	GridTitle.BackgroundTransparency = 1
	GridTitle.Font = Enum.Font.GothamBlack
	GridTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
	GridTitle.TextSize = 20
	GridTitle.Text = "SUPPLIES & ARMORY"
	GridTitle.Parent = GridContainer

	ItemGrid = Instance.new("ScrollingFrame")
	ItemGrid.Size = UDim2.new(1, -20, 1, -50)
	ItemGrid.Position = UDim2.new(0, 10, 0, 40)
	ItemGrid.BackgroundTransparency = 1
	ItemGrid.BorderSizePixel = 0
	ItemGrid.ScrollBarThickness = 6
	ItemGrid.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
	ItemGrid.Parent = GridContainer

	local uigrid = Instance.new("UIGridLayout")
	uigrid.CellSize = UDim2.new(0, 100, 0, 120)
	uigrid.CellPadding = UDim2.new(0, 10, 0, 10)
	uigrid.SortOrder = Enum.SortOrder.LayoutOrder
	uigrid.Parent = ItemGrid

	local uipad = Instance.new("UIPadding")
	uipad.PaddingTop = UDim.new(0, 10)
	uipad.PaddingLeft = UDim.new(0, 10)
	uipad.Parent = ItemGrid

	-- [[ DETAILS PANEL - RIGHT ]]
	DetailsPanel = Instance.new("Frame")
	DetailsPanel.Size = UDim2.new(0.33, 0, 1, 0)
	DetailsPanel.Position = UDim2.new(0.67, 0, 0, 0)
	DetailsPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	DetailsPanel.Parent = MainFrame

	Instance.new("UICorner", DetailsPanel).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", DetailsPanel).Color = Color3.fromRGB(80, 80, 90)

	local dTitle = Instance.new("TextLabel")
	dTitle.Name = "ItemName"
	dTitle.Size = UDim2.new(1, -20, 0, 30)
	dTitle.Position = UDim2.new(0, 10, 0, 10)
	dTitle.BackgroundTransparency = 1
	dTitle.Font = Enum.Font.GothamBold
	dTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	dTitle.TextSize = 18
	dTitle.TextWrapped = true
	dTitle.Text = "Select an Item"
	dTitle.Parent = DetailsPanel

	local dDesc = Instance.new("TextLabel")
	dDesc.Name = "ItemDesc"
	dDesc.Size = UDim2.new(1, -20, 0, 100)
	dDesc.Position = UDim2.new(0, 10, 0, 50)
	dDesc.BackgroundTransparency = 1
	dDesc.Font = Enum.Font.GothamMedium
	dDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	dDesc.TextSize = 14
	dDesc.TextWrapped = true
	dDesc.TextYAlignment = Enum.TextYAlignment.Top
	dDesc.Text = ""
	dDesc.Parent = DetailsPanel

	local useBtn = CreateButton(DetailsPanel, "UseBtn", "USE / EQUIP", Color3.fromRGB(40, 80, 40), UDim2.new(0, 10, 1, -150), UDim2.new(1, -20, 0, 40))
	local unequipBtn = CreateButton(DetailsPanel, "UnequipBtn", "UNEQUIP GEAR", Color3.fromRGB(80, 40, 40), UDim2.new(0, 10, 1, -100), UDim2.new(1, -20, 0, 40))
	local autoRollBtn = CreateButton(DetailsPanel, "AutoRollBtn", "AUTO-ROLL", Color3.fromRGB(80, 60, 20), UDim2.new(0, 10, 1, -50), UDim2.new(1, -20, 0, 40))
	autoRollBtn.Visible = false

	-- [[ AUTO-ROLL MODAL ]]
	AutoRollModal = Instance.new("Frame")
	AutoRollModal.Size = UDim2.new(0, 300, 0, 250)
	AutoRollModal.Position = UDim2.new(0.5, -150, 0.5, -125)
	AutoRollModal.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	AutoRollModal.ZIndex = 50
	AutoRollModal.Visible = false
	AutoRollModal.Parent = MainFrame

	Instance.new("UICorner", AutoRollModal).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", AutoRollModal).Color = Color3.fromRGB(120, 100, 60)

	local arTitle = Instance.new("TextLabel")
	arTitle.Size = UDim2.new(1, 0, 0, 40)
	arTitle.BackgroundTransparency = 1
	arTitle.Font = Enum.Font.GothamBlack
	arTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
	arTitle.TextSize = 18
	arTitle.Text = "AUTO-ROLL SETTINGS"
	arTitle.Parent = AutoRollModal

	local tInput = Instance.new("TextBox")
	tInput.Size = UDim2.new(0.8, 0, 0, 40)
	tInput.Position = UDim2.new(0.1, 0, 0, 60)
	tInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	tInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	tInput.Font = Enum.Font.GothamMedium
	tInput.TextSize = 14
	tInput.PlaceholderText = "Target Titan (or 'Any')"
	tInput.Text = "Any"
	tInput.Parent = AutoRollModal
	Instance.new("UICorner", tInput).CornerRadius = UDim.new(0, 6)

	local trInput = Instance.new("TextBox")
	trInput.Size = UDim2.new(0.8, 0, 0, 40)
	trInput.Position = UDim2.new(0.1, 0, 0, 110)
	trInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	trInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	trInput.Font = Enum.Font.GothamMedium
	trInput.TextSize = 14
	trInput.PlaceholderText = "Target Trait (or 'Any')"
	trInput.Text = "Any"
	trInput.Parent = AutoRollModal
	Instance.new("UICorner", trInput).CornerRadius = UDim.new(0, 6)

	local startRollBtn = CreateButton(AutoRollModal, "StartRollBtn", "START ROLLING", Color3.fromRGB(40, 80, 40), UDim2.new(0.1, 0, 0, 170), UDim2.new(0.35, 0, 0, 40))
	local cancelRollBtn = CreateButton(AutoRollModal, "CancelRollBtn", "CANCEL", Color3.fromRGB(80, 40, 40), UDim2.new(0.55, 0, 0, 170), UDim2.new(0.35, 0, 0, 40))

	-- [[ EVENT CONNECTIONS ]]
	useBtn.MouseButton1Click:Connect(function()
		if selectedItem then
			Network:WaitForChild("UseItem"):FireServer(selectedItem)
		end
	end)

	unequipBtn.MouseButton1Click:Connect(function()
		if selectedItem and ItemData.Equipment[selectedItem] then
			Network:WaitForChild("UnequipItem"):FireServer(ItemData.Equipment[selectedItem].Slot)
		end
	end)

	autoRollBtn.MouseButton1Click:Connect(function()
		if selectedItem == "Standard Titan Serum" or selectedItem == "Spinal Fluid Syringe" then
			AutoRollModal.Visible = true
		end
	end)

	cancelRollBtn.MouseButton1Click:Connect(function()
		AutoRollModal.Visible = false
	end)

	startRollBtn.MouseButton1Click:Connect(function()
		local rollType = (selectedItem == "Standard Titan Serum") and "Serum" or "Syringe"
		local targetT = (tInput.Text == "" or tInput.Text == "Any") and "Any" or tInput.Text
		local targetTr = (trInput.Text == "" or trInput.Text == "Any") and "Any" or trInput.Text

		Network:WaitForChild("AutoRoll"):FireServer(rollType, targetT, targetTr)
		AutoRollModal.Visible = false
	end)

	-- [[ UPDATE LOGIC ]]
	local function RenderInventory()
		for _, child in ipairs(ItemGrid:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local function CreateItemCard(itemName, itemInfo, count)
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0, 100, 0, 120)
			card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			card.Parent = ItemGrid

			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
			Instance.new("UIStroke", card).Color = Color3.fromRGB(80, 80, 90)

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -10, 0, 40)
			title.Position = UDim2.new(0, 5, 0, 5)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBold
			title.TextColor3 = Color3.fromRGB(255, 215, 100)
			title.TextSize = 12
			title.TextWrapped = true
			title.Text = itemName
			title.Parent = card

			local countLbl = Instance.new("TextLabel")
			countLbl.Size = UDim2.new(1, 0, 0, 20)
			countLbl.Position = UDim2.new(0, 0, 1, -25)
			countLbl.BackgroundTransparency = 1
			countLbl.Font = Enum.Font.GothamMedium
			countLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			countLbl.TextSize = 14
			countLbl.Text = "x" .. count
			countLbl.Parent = card

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Parent = card

			btn.MouseButton1Click:Connect(function()
				selectedItem = itemName
				dTitle.Text = itemName
				dDesc.Text = itemInfo.Desc or "No description."

				if itemInfo.Slot then
					dDesc.Text = dDesc.Text .. "\n\nSlot: " .. itemInfo.Slot
					unequipBtn.Visible = true
				else
					unequipBtn.Visible = false
				end

				if itemName == "Standard Titan Serum" or itemName == "Spinal Fluid Syringe" then
					if player:GetAttribute("HasAutoRoll") then
						autoRollBtn.Visible = true
					else
						autoRollBtn.Visible = false
					end
				else
					autoRollBtn.Visible = false
				end
			end)
		end

		for itemName, data in pairs(ItemData.Equipment) do
			local attr = itemName:gsub("[^%w]", "") .. "Count"
			local c = player:GetAttribute(attr) or 0
			if c > 0 then CreateItemCard(itemName, data, c) end
		end
		for itemName, data in pairs(ItemData.Consumables) do
			local attr = itemName:gsub("[^%w]", "") .. "Count"
			local c = player:GetAttribute(attr) or 0
			if c > 0 then CreateItemCard(itemName, data, c) end
		end
	end

	player.AttributeChanged:Connect(function(attr)
		if string.match(attr, "Count$") then RenderInventory() end
	end)
	RenderInventory()
end

function InventoryTab.Show()
	if MainFrame then
		MainFrame.Visible = true
	end
end

return InventoryTab