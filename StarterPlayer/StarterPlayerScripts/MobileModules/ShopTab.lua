-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ShopTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local NotificationManager
pcall(function() NotificationManager = require(script.Parent:WaitForChild("NotificationManager")) end)
if not NotificationManager then NotificationManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("NotificationManager")) end

local player = Players.LocalPlayer
local MainFrame
local SupplyPanel, PremiumPanel, CodePanel
local TimeLabel, RRBtn

local currentShopData = nil
local isFetching = false
local REROLL_ID = 3557925572 

for _, dp in ipairs(ItemData.Products) do if dp.IsReroll then REROLL_ID = dp.ID; break end end

local RarityColors = { ["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5555FF", ["Epic"] = "#AA00FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333" }

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

local function FormatTime(seconds)
	local m = math.floor(seconds / 60); local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

function ShopTab.Init(parentFrame, tooltipMgr)
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	if not MainFrame:IsA("ScrollingFrame") then MainFrame = Instance.new("Frame", parentFrame) end
	MainFrame.Name = "ShopFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	local isMobile = MainFrame:IsA("ScrollingFrame")
	local mainLayout
	if isMobile then
		MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		mainLayout = Instance.new("UIListLayout", MainFrame); mainLayout.Padding = UDim.new(0, 15); mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 24; Title.Text = "MARKETPLACE & SUPPLY"
	ApplyGradient(Title, Color3.fromRGB(150, 200, 255), Color3.fromRGB(50, 150, 255))

	PremiumPanel = Instance.new("Frame", MainFrame)
	PremiumPanel.Size = isMobile and UDim2.new(0.95, 0, 0, 350) or UDim2.new(0.48, 0, 0.75, 0); 
	if not isMobile then PremiumPanel.Position = UDim2.new(0.01, 0, 0.1, 0) end
	PremiumPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", PremiumPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", PremiumPanel).Color = Color3.fromRGB(80, 80, 90)

	local PTitle = Instance.new("TextLabel", PremiumPanel)
	PTitle.Size = UDim2.new(1, 0, 0, 40); PTitle.BackgroundTransparency = 1; PTitle.Font = Enum.Font.GothamBlack; PTitle.TextColor3 = Color3.fromRGB(255, 215, 100); PTitle.TextSize = 18; PTitle.Text = "PREMIUM STORE"

	local PremList = Instance.new("ScrollingFrame", PremiumPanel)
	PremList.Size = UDim2.new(1, -20, 1, -50); PremList.Position = UDim2.new(0, 10, 0, 40); PremList.BackgroundTransparency = 1; PremList.BorderSizePixel = 0; PremList.ScrollBarThickness = 4
	local pLayout = Instance.new("UIListLayout", PremList); pLayout.Padding = UDim.new(0, 10)

	for _, gp in ipairs(ItemData.Gamepasses) do
		local row = Instance.new("Frame", PremList)
		row.Size = UDim2.new(1, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(40, 30, 50); Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(150, 100, 200)
		local rTitle = Instance.new("TextLabel", row); rTitle.Size = UDim2.new(0.7, 0, 0, 20); rTitle.Position = UDim2.new(0, 10, 0, 5); rTitle.BackgroundTransparency = 1; rTitle.Font = Enum.Font.GothamBlack; rTitle.TextColor3 = Color3.fromRGB(255, 215, 100); rTitle.TextSize = 14; rTitle.TextXAlignment = Enum.TextXAlignment.Left; rTitle.Text = gp.Name
		local rDesc = Instance.new("TextLabel", row); rDesc.Size = UDim2.new(0.7, 0, 0, 30); rDesc.Position = UDim2.new(0, 10, 0, 25); rDesc.BackgroundTransparency = 1; rDesc.Font = Enum.Font.GothamMedium; rDesc.TextColor3 = Color3.fromRGB(200, 200, 200); rDesc.TextSize = 11; rDesc.TextWrapped = true; rDesc.TextXAlignment = Enum.TextXAlignment.Left; rDesc.Text = gp.Desc
		local btn = Instance.new("TextButton", row); btn.Size = UDim2.new(0, 80, 0, 35); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -10, 0.5, 0); btn.BackgroundColor3 = Color3.fromRGB(120, 80, 150); btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 12; btn.Text = "BUY"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
		btn.MouseButton1Click:Connect(function() MarketplaceService:PromptGamePassPurchase(player, gp.ID) end)
	end

	for _, dp in ipairs(ItemData.Products) do
		if dp.IsReroll then continue end 
		local row = Instance.new("Frame", PremList)
		row.Size = UDim2.new(1, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(30, 40, 30); Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", row).Color = Color3.fromRGB(100, 150, 100)
		local rTitle = Instance.new("TextLabel", row); rTitle.Size = UDim2.new(0.7, 0, 0, 20); rTitle.Position = UDim2.new(0, 10, 0, 5); rTitle.BackgroundTransparency = 1; rTitle.Font = Enum.Font.GothamBlack; rTitle.TextColor3 = Color3.fromRGB(150, 255, 150); rTitle.TextSize = 14; rTitle.TextXAlignment = Enum.TextXAlignment.Left; rTitle.Text = dp.Name
		local rDesc = Instance.new("TextLabel", row); rDesc.Size = UDim2.new(0.7, 0, 0, 30); rDesc.Position = UDim2.new(0, 10, 0, 25); rDesc.BackgroundTransparency = 1; rDesc.Font = Enum.Font.GothamMedium; rDesc.TextColor3 = Color3.fromRGB(200, 200, 200); rDesc.TextSize = 11; rDesc.TextWrapped = true; rDesc.TextXAlignment = Enum.TextXAlignment.Left; rDesc.Text = dp.Desc
		local btn = Instance.new("TextButton", row); btn.Size = UDim2.new(0, 80, 0, 35); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -10, 0.5, 0); btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60); btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 12; btn.Text = "BUY"
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
		btn.MouseButton1Click:Connect(function() MarketplaceService:PromptProductPurchase(player, dp.ID) end)
	end
	task.delay(0.1, function() PremList.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 20) end)

	SupplyPanel = Instance.new("Frame", MainFrame)
	SupplyPanel.Size = isMobile and UDim2.new(0.95, 0, 0, 350) or UDim2.new(0.48, 0, 0.75, 0); 
	if not isMobile then SupplyPanel.Position = UDim2.new(0.51, 0, 0.1, 0) end
	SupplyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", SupplyPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", SupplyPanel).Color = Color3.fromRGB(80, 80, 90)

	local Header = Instance.new("Frame", SupplyPanel)
	Header.Size = UDim2.new(1, 0, 0, 50); Header.BackgroundTransparency = 1

	TimeLabel = Instance.new("TextLabel", Header)
	TimeLabel.Size = UDim2.new(0.5, 0, 1, 0); TimeLabel.Position = UDim2.new(0.05, 0, 0, 0); TimeLabel.BackgroundTransparency = 1; TimeLabel.Font = Enum.Font.GothamBlack; TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TimeLabel.TextScaled = true; TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UITextSizeConstraint", TimeLabel).MaxTextSize = 16
	ApplyGradient(TimeLabel, Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 200, 100))

	RRBtn = Instance.new("TextButton", Header)
	RRBtn.Size = UDim2.new(0, 120, 0, 30); RRBtn.AnchorPoint = Vector2.new(1, 0.5); RRBtn.Position = UDim2.new(1, -10, 0.5, 0); RRBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30)
	RRBtn.Font = Enum.Font.GothamBold; RRBtn.TextColor3 = Color3.fromRGB(255,255,255); RRBtn.TextSize = 10; RRBtn.Text = "REROLL (15 R$)"
	Instance.new("UICorner", RRBtn).CornerRadius = UDim.new(0, 4)

	local function CheckVIPReroll()
		local hasVIP = player:GetAttribute("HasVIP")
		local lastRoll = player:GetAttribute("LastFreeReroll") or 0
		if hasVIP and os.time() - lastRoll >= 86400 then
			RRBtn.Text = "FREE REROLL"; RRBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 40); return true
		else
			RRBtn.Text = "REROLL (15 R$)"; RRBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30); return false
		end
	end

	local ShopGrid = Instance.new("ScrollingFrame", SupplyPanel)
	ShopGrid.Size = UDim2.new(1, -20, 1, -60); ShopGrid.Position = UDim2.new(0, 10, 0, 50); ShopGrid.BackgroundTransparency = 1; ShopGrid.BorderSizePixel = 0; ShopGrid.ScrollBarThickness = 4
	local sgLayout = Instance.new("UIListLayout", ShopGrid); sgLayout.Padding = UDim.new(0, 10)

	local function FetchAndRenderShop()
		if isFetching then return end
		isFetching = true
		currentShopData = Network.GetShopData:InvokeServer()
		isFetching = false
		if not currentShopData then return end

		CheckVIPReroll()
		for _, child in ipairs(ShopGrid:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

		for _, item in ipairs(currentShopData.Items) do
			local iData = ItemData.Equipment[item.Name] or ItemData.Consumables[item.Name]
			local rarityTag = iData and iData.Rarity or "Common"
			local cColor = RarityColors[rarityTag] or "#FFFFFF"

			local row = Instance.new("Frame", ShopGrid)
			row.Size = UDim2.new(1, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(25, 25, 30); Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
			local glow = Instance.new("Frame", row); glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 2, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", "")); Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)

			local nLbl = Instance.new("TextLabel", row); nLbl.Size = UDim2.new(0.6, 0, 0, 25); nLbl.Position = UDim2.new(0, 15, 0, 5); nLbl.BackgroundTransparency = 1; nLbl.Font = Enum.Font.GothamBold; nLbl.TextColor3 = Color3.fromRGB(255,255,255); nLbl.TextXAlignment = Enum.TextXAlignment.Left; nLbl.RichText = true; nLbl.TextScaled = true
			nLbl.Text = "<b><font color='" .. cColor .. "'>[" .. rarityTag .. "]</font></b> " .. item.Name
			Instance.new("UITextSizeConstraint", nLbl).MaxTextSize = 13

			local cLbl = Instance.new("TextLabel", row); cLbl.Size = UDim2.new(0.6, 0, 0, 20); cLbl.Position = UDim2.new(0, 15, 0, 30); cLbl.BackgroundTransparency = 1; cLbl.Font = Enum.Font.GothamMedium; cLbl.TextColor3 = Color3.fromRGB(150, 255, 150); cLbl.TextXAlignment = Enum.TextXAlignment.Left; cLbl.TextSize = 12
			cLbl.Text = "Cost: " .. item.Cost .. " Dews"

			local bBtn = Instance.new("TextButton", row); bBtn.Size = UDim2.new(0, 70, 0, 35); bBtn.AnchorPoint = Vector2.new(1, 0.5); bBtn.Position = UDim2.new(1, -10, 0.5, 0); 
			Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0,4)
			bBtn.Font = Enum.Font.GothamBold; bBtn.TextColor3 = Color3.new(1,1,1); bBtn.TextSize = 12

			if item.SoldOut then
				bBtn.Text = "SOLD"
				bBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				bBtn.Active = false
			else
				bBtn.Text = "BUY"
				bBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
				bBtn.Active = true
				bBtn.MouseButton1Click:Connect(function()
					if player.leaderstats and player.leaderstats:FindFirstChild("Dews") and player.leaderstats.Dews.Value >= item.Cost then
						Network.ShopAction:FireServer(item.Name)
						NotificationManager.Show("Purchased " .. item.Name .. "! Sent to inventory.", "Success")
						bBtn.Text = "SOLD"; bBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
						bBtn.Active = false
					else
						NotificationManager.Show("Not enough Dews! Complete Bounties to earn more.", "Error")
					end
				end)
			end
		end
		task.delay(0.1, function() ShopGrid.CanvasSize = UDim2.new(0, 0, 0, sgLayout.AbsoluteContentSize.Y + 20) end)
	end

	RRBtn.MouseButton1Click:Connect(function()
		if CheckVIPReroll() then
			Network.VIPFreeReroll:FireServer()
			RRBtn.Text = "REROLLING..."; task.wait(0.5)
			FetchAndRenderShop()
		else
			MarketplaceService:PromptProductPurchase(player, REROLL_ID)
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		if isPurchased and productId == REROLL_ID then
			RRBtn.Text = "REROLLING..."
			task.wait(1.5)
			FetchAndRenderShop()
		end
	end)

	-- [[ CODES PANEL ]]
	CodePanel = Instance.new("Frame", MainFrame)
	CodePanel.Size = isMobile and UDim2.new(0.95, 0, 0, 80) or UDim2.new(0.98, 0, 0.12, 0); 
	if not isMobile then CodePanel.Position = UDim2.new(0.01, 0, 0.865, 0) end
	CodePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", CodePanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", CodePanel).Color = Color3.fromRGB(60, 60, 70)

	local cTitle = Instance.new("TextLabel", CodePanel)
	cTitle.Size = isMobile and UDim2.new(0.9, 0, 0, 25) or UDim2.new(0.2, 0, 1, 0); 
	cTitle.Position = isMobile and UDim2.new(0.05, 0, 0, 5) or UDim2.new(0.02, 0, 0, 0); 
	cTitle.BackgroundTransparency = 1; cTitle.Font = Enum.Font.GothamBlack; cTitle.TextColor3 = Color3.fromRGB(200, 200, 200); cTitle.TextSize = isMobile and 14 or 16; cTitle.TextXAlignment = Enum.TextXAlignment.Left; cTitle.Text = "ENTER CODE:"

	local cInput = Instance.new("TextBox", CodePanel)
	cInput.Size = isMobile and UDim2.new(0.65, 0, 0, 35) or UDim2.new(0.5, 0, 0.6, 0); 
	cInput.Position = isMobile and UDim2.new(0.05, 0, 0, 35) or UDim2.new(0.25, 0, 0.2, 0); 
	cInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18); cInput.Font = Enum.Font.GothamBold; cInput.TextColor3 = Color3.fromRGB(255, 255, 255); cInput.TextSize = isMobile and 13 or 14; cInput.PlaceholderText = "Type code here..."
	Instance.new("UICorner", cInput).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", cInput).Color = Color3.fromRGB(80, 80, 90)

	local cBtn = Instance.new("TextButton", CodePanel)
	cBtn.Size = isMobile and UDim2.new(0.25, 0, 0, 35) or UDim2.new(0.2, 0, 0.6, 0); 
	cBtn.Position = isMobile and UDim2.new(0.72, 0, 0, 35) or UDim2.new(0.78, 0, 0.2, 0); 
	cBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180); cBtn.Font = Enum.Font.GothamBlack; cBtn.TextColor3 = Color3.fromRGB(255, 255, 255); cBtn.TextSize = isMobile and 13 or 14; cBtn.Text = "REDEEM"
	Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)

	-- THE FIX: Removed the false "APPLIED" text logic, relies on NotificationManager to display success/failure!
	cBtn.MouseButton1Click:Connect(function()
		local codeStr = cInput.Text
		if codeStr ~= "" then
			Network.RedeemCode:FireServer(codeStr)
			cBtn.Text = "..."
			task.delay(1, function() cBtn.Text = "REDEEM"; cInput.Text = "" end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			if MainFrame.Visible then
				if currentShopData then
					currentShopData.TimeLeft -= 1
					if currentShopData.TimeLeft <= 0 then FetchAndRenderShop()
					else TimeLabel.Text = "RESTOCKS IN: " .. FormatTime(currentShopData.TimeLeft) end
				else
					FetchAndRenderShop()
				end
			end
		end
	end)
end

function ShopTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return ShopTab