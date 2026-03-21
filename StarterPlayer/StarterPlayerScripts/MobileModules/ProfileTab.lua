-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local InheritTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))

local EffectsManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("EffectsManager"))
local NotificationManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("NotificationManager"))

local player = Players.LocalPlayer
local MainFrame
local isRolling = { Titan = false, Clan = false }

local RarityColors = { ["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5555FF", ["Epic"] = "#AA00FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333" }
local RarityOrder = { Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function InheritTab.Init(parentFrame, tooltipMgr)
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	MainFrame.Name = "InheritFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
	MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local mainLayout = Instance.new("UIListLayout", MainFrame)
	mainLayout.Padding = UDim.new(0, 15)
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 24; Title.Text = "THE PATHS"
	Title.LayoutOrder = 1
	ApplyGradient(Title, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	-- [[ THE FIX: Stacked UI Framework ]]
	local function CreateGachaPanel(gType, layoutOrder)
		local Panel = Instance.new("Frame", MainFrame)
		Panel.Size = UDim2.new(0.95, 0, 0, 0) 
		Panel.AutomaticSize = Enum.AutomaticSize.Y
		Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18) 
		Panel.LayoutOrder = layoutOrder
		Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Panel).Color = Color3.fromRGB(120, 100, 60)

		local panelLayout = Instance.new("UIListLayout", Panel)
		panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
		panelLayout.Padding = UDim.new(0, 10)
		panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local pad = Instance.new("UIPadding", Panel); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 15)

		local PTitle = Instance.new("TextLabel", Panel)
		PTitle.Size = UDim2.new(1, 0, 0, 30); PTitle.BackgroundTransparency = 1; PTitle.Font = Enum.Font.GothamBlack; PTitle.TextColor3 = Color3.fromRGB(255, 255, 255); PTitle.TextSize = 18; PTitle.Text = (gType == "Titan") and "TITAN INHERITANCE" or "CLAN LINEAGE"
		PTitle.LayoutOrder = 1

		local ListContainer = Instance.new("ScrollingFrame", Panel)
		ListContainer.Size = UDim2.new(0.95, 0, 0, 200); ListContainer.BackgroundTransparency = 1; ListContainer.ScrollBarThickness = 2; ListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListContainer.LayoutOrder = 2
		local SList = Instance.new("UIListLayout", ListContainer); SList.Padding = UDim.new(0, 4)

		if gType == "Titan" then
			local sortedTitans = {}
			for tName, tData in pairs(TitanData.Titans) do table.insert(sortedTitans, tData) end
			table.sort(sortedTitans, function(a, b) return RarityOrder[a.Rarity] < RarityOrder[b.Rarity] end)
			for _, drop in ipairs(sortedTitans) do
				local row = Instance.new("Frame", ListContainer); row.Size = UDim2.new(1, 0, 0, 35); row.BackgroundTransparency = 1 
				local cColor = RarityColors[drop.Rarity] or "#FFFFFF"
				local glow = Instance.new("Frame", row); glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 0, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", "")); Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)
				local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1, -15, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextScaled = true
				lbl.Text = "<b><font color='" .. cColor .. "'>[" .. drop.Rarity .. "] " .. drop.Name .. "</font></b>"
				Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 12
			end
		else
			local sortedClans = {}
			for cName, weight in pairs(TitanData.ClanWeights) do table.insert(sortedClans, {Name = cName, Weight = weight}) end
			table.sort(sortedClans, function(a, b) return a.Weight < b.Weight end)
			for _, drop in ipairs(sortedClans) do
				local row = Instance.new("Frame", ListContainer); row.Size = UDim2.new(1, 0, 0, 35); row.BackgroundTransparency = 1
				local rarityTag = "Common"; if drop.Weight <= 1.5 then rarityTag = "Mythical" elseif drop.Weight <= 4.0 then rarityTag = "Legendary" elseif drop.Weight <= 8.0 then rarityTag = "Epic" elseif drop.Weight <= 15.0 then rarityTag = "Rare" end
				local cColor = RarityColors[rarityTag] or "#FFFFFF"
				local glow = Instance.new("Frame", row); glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 0, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", "")); Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)
				local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1, -15, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextScaled = true
				lbl.Text = "<b><font color='" .. cColor .. "'>[" .. rarityTag .. "] " .. drop.Name .. "</font></b>"
				Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 12
			end
		end

		local ResultLbl = Instance.new("TextLabel", Panel)
		ResultLbl.Size = UDim2.new(1, 0, 0, 25); ResultLbl.BackgroundTransparency = 1; ResultLbl.Font = Enum.Font.GothamBlack; ResultLbl.TextColor3 = Color3.fromRGB(255, 255, 255); ResultLbl.TextSize = 16; ResultLbl.RichText = true; ResultLbl.Text = "Current: None"
		ResultLbl.LayoutOrder = 3

		local StorageArea = Instance.new("Frame", Panel)
		StorageArea.Size = UDim2.new(0.95, 0, 0, 35); StorageArea.BackgroundTransparency = 1
		StorageArea.LayoutOrder = 4
		local sg = Instance.new("UIListLayout", StorageArea); sg.FillDirection = Enum.FillDirection.Horizontal; sg.HorizontalAlignment = Enum.HorizontalAlignment.Center; sg.Padding = UDim.new(0.02, 0)

		local storageBtns = {}
		for i = 1, 6 do
			local sBtn = Instance.new("TextButton", StorageArea)
			sBtn.Size = UDim2.new(0.15, 0, 1, 0); sBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); sBtn.Font = Enum.Font.GothamBold; sBtn.TextColor3 = Color3.fromRGB(200, 200, 200); sBtn.TextScaled = true; sBtn.Text = "Empty"
			Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", sBtn).Color = Color3.fromRGB(60, 60, 70); Instance.new("UITextSizeConstraint", sBtn).MaxTextSize = 10
			sBtn.MouseButton1Click:Connect(function() Network.ManageStorage:FireServer(gType, i) end)
			storageBtns[i] = sBtn
		end

		local PityLbl = Instance.new("TextLabel", Panel)
		PityLbl.Size = UDim2.new(1, 0, 0, 20); PityLbl.BackgroundTransparency = 1; PityLbl.Font = Enum.Font.GothamBold; PityLbl.TextColor3 = Color3.fromRGB(200, 150, 255); PityLbl.TextSize = 14; PityLbl.Text = "PITY: 0 / 100"
		PityLbl.LayoutOrder = 5

		local RollActions = Instance.new("Frame", Panel)
		RollActions.Size = UDim2.new(0.95, 0, 0, 40); RollActions.BackgroundTransparency = 1
		RollActions.LayoutOrder = 6
		local raLayout = Instance.new("UIListLayout", RollActions); raLayout.FillDirection = Enum.FillDirection.Horizontal; raLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; raLayout.Padding = UDim.new(0.02, 0)

		local RollBtn = Instance.new("TextButton", RollActions)
		RollBtn.Size = UDim2.new(0.48, 0, 1, 0); RollBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60); RollBtn.Font = Enum.Font.GothamBold; RollBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RollBtn.TextScaled = true
		Instance.new("UITextSizeConstraint", RollBtn).MaxTextSize = 10; Instance.new("UICorner", RollBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", RollBtn).Color = Color3.fromRGB(80, 150, 80)

		local AutoRollBtn = Instance.new("TextButton", RollActions)
		AutoRollBtn.Size = UDim2.new(0.48, 0, 1, 0); AutoRollBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 120); AutoRollBtn.Font = Enum.Font.GothamBold; AutoRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255); AutoRollBtn.TextScaled = true; AutoRollBtn.Text = "ROLL TILL LEGENDARY+"
		Instance.new("UITextSizeConstraint", AutoRollBtn).MaxTextSize = 10; Instance.new("UICorner", AutoRollBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", AutoRollBtn).Color = Color3.fromRGB(150, 80, 150)

		RollBtn.MouseButton1Click:Connect(function() if not isRolling[gType] then isRolling[gType] = true; Network.GachaRoll:FireServer(gType, false) end end)
		AutoRollBtn.MouseButton1Click:Connect(function() if not isRolling[gType] then isRolling[gType] = true; Network.GachaRollAuto:FireServer(gType) end end)

		return ResultLbl, PityLbl, RollBtn, nil, AutoRollBtn, storageBtns
	end

	local tResult, tPity, tRoll, _, tAuto, tStores = CreateGachaPanel("Titan", 2)
	local cResult, cPity, cRoll, _, cAuto, cStores = CreateGachaPanel("Clan", 3)

	local function UpdateUI()
		if not isRolling.Titan then tResult.Text = "Current: " .. (player:GetAttribute("Titan") or "None") end
		if not isRolling.Clan then cResult.Text = "Current: " .. (player:GetAttribute("Clan") or "None") end

		for i = 1, 6 do
			tStores[i].Text = (player:GetAttribute("Titan_Slot"..i) or "None") == "None" and "Empty" or player:GetAttribute("Titan_Slot"..i)
			cStores[i].Text = (player:GetAttribute("Clan_Slot"..i) or "None") == "None" and "Empty" or player:GetAttribute("Clan_Slot"..i)
		end

		tPity.Text = "PITY: " .. (player:GetAttribute("TitanPity") or 0) .. " / 100"
		cPity.Text = "PITY: " .. (player:GetAttribute("ClanPity") or 0) .. " / 100"
		tRoll.Text = "ROLL (1x Serum)\nOwned: " .. (player:GetAttribute("StandardTitanSerumCount") or 0)
		cRoll.Text = "ROLL (1x Vial)\nOwned: " .. (player:GetAttribute("ClanBloodVialCount") or 0)
	end

	player.AttributeChanged:Connect(UpdateUI); UpdateUI()

	Network.GachaResult.OnClientEvent:Connect(function(gType, resultName, resultRarity)
		local targetLbl = (gType == "Titan") and tResult or cResult
		local names = {}
		if gType == "Titan" then for tName, _ in pairs(TitanData.Titans) do table.insert(names, tName) end else for cName, _ in pairs(TitanData.ClanWeights) do table.insert(names, cName) end end

		for i = 1, 20 do EffectsManager.PlaySFX("Spin", 1 + (i/25)); targetLbl.Text = names[math.random(1, #names)]; task.wait(0.05) end
		local cColor = RarityColors[resultRarity] or "#FFFFFF"
		targetLbl.Text = "<b><font color='" .. cColor .. "'>" .. resultName:upper() .. "!</font></b>"
		EffectsManager.PlaySFX("Reveal", 1); task.wait(1.5); isRolling[gType] = false; UpdateUI()
	end)
end

function InheritTab.Show() if MainFrame then MainFrame.Visible = true end end
return InheritTab