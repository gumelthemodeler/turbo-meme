-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ForgeTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EffectsManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("EffectsManager"))

local player = Players.LocalPlayer
local MainFrame
local RecipeList
local AnvilView
local ActiveRecipe = nil

local RarityColors = {
	["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5555FF",
	["Epic"] = "#AA00FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333"
}

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function ForgeTab.Init(parentFrame, tooltipMgr)
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	MainFrame.Name = "ForgeFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
	MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	-- THE FIX: Added FillDirection.Vertical so they stack!
	local layout = Instance.new("UIListLayout", MainFrame)
	layout.Padding = UDim.new(0, 15); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.FillDirection = Enum.FillDirection.Vertical

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 24; Title.Text = "THE BLACKSMITH"
	ApplyGradient(Title, Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100))

	local LeftPanel = Instance.new("Frame", MainFrame)
	LeftPanel.Size = UDim2.new(0.95, 0, 0, 400)
	LeftPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", LeftPanel).Color = Color3.fromRGB(80, 80, 90)

	local LTitle = Instance.new("TextLabel", LeftPanel)
	LTitle.Size = UDim2.new(1, 0, 0, 40); LTitle.BackgroundTransparency = 1; LTitle.Font = Enum.Font.GothamBlack; LTitle.TextColor3 = Color3.fromRGB(200, 200, 200); LTitle.TextSize = 16; LTitle.Text = "AVAILABLE BLUEPRINTS"

	RecipeList = Instance.new("ScrollingFrame", LeftPanel)
	RecipeList.Size = UDim2.new(1, -20, 1, -50); RecipeList.Position = UDim2.new(0, 10, 0, 40); RecipeList.BackgroundTransparency = 1; RecipeList.BorderSizePixel = 0; RecipeList.ScrollBarThickness = 4
	local rLayout = Instance.new("UIListLayout", RecipeList); rLayout.Padding = UDim.new(0, 8)

	AnvilView = Instance.new("Frame", MainFrame)
	AnvilView.Size = UDim2.new(0.95, 0, 0, 400)
	AnvilView.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	Instance.new("UICorner", AnvilView).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", AnvilView).Color = Color3.fromRGB(150, 100, 50)

	local ATitle = Instance.new("TextLabel", AnvilView)
	ATitle.Size = UDim2.new(1, 0, 0, 40); ATitle.BackgroundTransparency = 1; ATitle.Font = Enum.Font.GothamBlack; ATitle.TextColor3 = Color3.fromRGB(255, 215, 100); ATitle.TextSize = 18; ATitle.Text = "THE ANVIL"

	local BaseLbl = Instance.new("TextLabel", AnvilView)
	BaseLbl.Name = "BaseLbl"; BaseLbl.Size = UDim2.new(0.8, 0, 0, 40); BaseLbl.Position = UDim2.new(0.1, 0, 0.2, 0); BaseLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 35); BaseLbl.Font = Enum.Font.GothamBold; BaseLbl.TextColor3 = Color3.fromRGB(200, 200, 200); BaseLbl.TextSize = 14; BaseLbl.RichText = true; BaseLbl.Text = "Select a Blueprint"
	Instance.new("UICorner", BaseLbl).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", BaseLbl).Color = Color3.fromRGB(60, 60, 70)

	local PlusLbl = Instance.new("TextLabel", AnvilView)
	PlusLbl.Size = UDim2.new(1, 0, 0, 30); PlusLbl.Position = UDim2.new(0, 0, 0.35, 0); PlusLbl.BackgroundTransparency = 1; PlusLbl.Font = Enum.Font.GothamBlack; PlusLbl.TextColor3 = Color3.fromRGB(200, 200, 200); PlusLbl.TextSize = 24; PlusLbl.Text = "+"

	local CostLbl = Instance.new("TextLabel", AnvilView)
	CostLbl.Name = "CostLbl"; CostLbl.Size = UDim2.new(0.6, 0, 0, 40); CostLbl.Position = UDim2.new(0.2, 0, 0.45, 0); CostLbl.BackgroundColor3 = Color3.fromRGB(20, 30, 20); CostLbl.Font = Enum.Font.GothamBold; CostLbl.TextColor3 = Color3.fromRGB(150, 255, 150); CostLbl.TextSize = 14; CostLbl.Text = "Cost: -- Dews"
	Instance.new("UICorner", CostLbl).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", CostLbl).Color = Color3.fromRGB(60, 100, 60)

	local ArrowLbl = Instance.new("TextLabel", AnvilView)
	ArrowLbl.Size = UDim2.new(1, 0, 0, 30); ArrowLbl.Position = UDim2.new(0, 0, 0.6, 0); ArrowLbl.BackgroundTransparency = 1; ArrowLbl.Font = Enum.Font.GothamBlack; ArrowLbl.TextColor3 = Color3.fromRGB(255, 215, 100); ArrowLbl.TextSize = 24; ArrowLbl.Text = "↓"

	local ResultLbl = Instance.new("TextLabel", AnvilView)
	ResultLbl.Name = "ResultLbl"; ResultLbl.Size = UDim2.new(0.8, 0, 0, 40); ResultLbl.Position = UDim2.new(0.1, 0, 0.7, 0); ResultLbl.BackgroundColor3 = Color3.fromRGB(40, 30, 50); ResultLbl.Font = Enum.Font.GothamBold; ResultLbl.TextColor3 = Color3.fromRGB(255, 255, 255); ResultLbl.TextSize = 14; ResultLbl.RichText = true; ResultLbl.Text = "Result: --"
	Instance.new("UICorner", ResultLbl).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", ResultLbl).Color = Color3.fromRGB(150, 100, 200)

	local ForgeBtn = Instance.new("TextButton", AnvilView)
	ForgeBtn.Name = "ForgeBtn"; ForgeBtn.Size = UDim2.new(0.6, 0, 0, 40); ForgeBtn.Position = UDim2.new(0.2, 0, 0.85, 0); ForgeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60); ForgeBtn.Font = Enum.Font.GothamBlack; ForgeBtn.TextColor3 = Color3.fromRGB(150, 150, 150); ForgeBtn.TextSize = 16; ForgeBtn.Text = "FORGE"
	Instance.new("UICorner", ForgeBtn).CornerRadius = UDim.new(0, 6)

	local function RenderAnvil()
		if not ActiveRecipe then return end
		local recipe = ItemData.ForgeRecipes[ActiveRecipe]
		if not recipe then return end

		local bData = ItemData.Equipment[ActiveRecipe] or ItemData.Consumables[ActiveRecipe]
		local rData = ItemData.Equipment[recipe.Result] or ItemData.Consumables[recipe.Result]

		local bColor = RarityColors[bData and bData.Rarity or "Common"] or "#FFFFFF"
		local rColor = RarityColors[rData and rData.Rarity or "Common"] or "#FFFFFF"

		local safeName = ActiveRecipe:gsub("[^%w]", "") .. "Count"
		local owned = player:GetAttribute(safeName) or 0

		BaseLbl.Text = string.format("<b><font color='%s'>%s</font></b> (%d / %d)", bColor, ActiveRecipe, owned, recipe.ReqAmt)
		CostLbl.Text = "Cost: " .. recipe.DewCost .. " Dews"
		ResultLbl.Text = string.format("<b><font color='%s'>%s</font></b>", rColor, recipe.Result)

		if owned >= recipe.ReqAmt and player.leaderstats.Dews.Value >= recipe.DewCost then
			ForgeBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30); ForgeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			ForgeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60); ForgeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end

	local function BuildRecipeList()
		for _, child in ipairs(RecipeList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

		for baseName, recipeData in pairs(ItemData.ForgeRecipes) do
			local safeName = baseName:gsub("[^%w]", "") .. "Count"
			local owned = player:GetAttribute(safeName) or 0

			local btn = Instance.new("TextButton", RecipeList)
			btn.Size = UDim2.new(1, 0, 0, 40); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); local strk = Instance.new("UIStroke", btn); strk.Color = Color3.fromRGB(60, 60, 70)

			local lbl = Instance.new("TextLabel", btn)
			lbl.Size = UDim2.new(1, -20, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true

			local bData = ItemData.Equipment[baseName] or ItemData.Consumables[baseName]
			local bColor = RarityColors[bData and bData.Rarity or "Common"] or "#FFFFFF"

			lbl.Text = string.format("<b><font color='%s'>%s</font></b> ➔ %s", bColor, baseName, recipeData.Result)

			if owned >= recipeData.ReqAmt then strk.Color = Color3.fromRGB(150, 200, 150) end

			btn.MouseButton1Click:Connect(function()
				ActiveRecipe = baseName
				RenderAnvil()
			end)
		end

		task.delay(0.1, function() RecipeList.CanvasSize = UDim2.new(0, 0, 0, rLayout.AbsoluteContentSize.Y + 20) end)
	end

	ForgeBtn.MouseButton1Click:Connect(function()
		if not ActiveRecipe then return end
		local recipe = ItemData.ForgeRecipes[ActiveRecipe]
		local safeName = ActiveRecipe:gsub("[^%w]", "") .. "Count"
		local owned = player:GetAttribute(safeName) or 0

		if owned >= recipe.ReqAmt and player.leaderstats.Dews.Value >= recipe.DewCost then
			EffectsManager.PlaySFX("HeavySlash", 0.5) 
			Network.ForgeItem:FireServer(ActiveRecipe)
			ForgeBtn.Text = "FORGED!"; task.delay(1, function() ForgeBtn.Text = "FORGE" end)
		else
			EffectsManager.PlaySFX("Block", 1)
		end
	end)

	player.AttributeChanged:Connect(function(attr)
		if attr:match("Count") or attr == "Dews" then 
			BuildRecipeList()
			RenderAnvil()
		end
	end)

	BuildRecipeList()
end

function ForgeTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return ForgeTab