-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local InheritTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local MainFrame

local RarityColors = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(85, 255, 85),
	Rare = Color3.fromRGB(85, 255, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
	Mythical = Color3.fromRGB(255, 85, 85)
}

local ClansInfo = {
	{Name = "Ackerman", Rarity = "Mythical", Rate = "0.5%", Desc = "Awakened Instincts: +25% DMG w/ Blades/Spears, +30% Speed."},
	{Name = "Yeager", Rarity = "Legendary", Rate = "3%", Desc = "Tenacity: +25% Willpower, +5% Strength. Missing HP heavily boosts DMG."},
	{Name = "Reiss", Rarity = "Legendary", Rate = "1.5%", Desc = "Royal Blood: +20% Maximum HP."},
	{Name = "Tybur", Rarity = "Rare", Rate = "4%", Desc = "Structural Mastery: +15% Defense, +10 Hardening."},
	{Name = "Arlert", Rarity = "Rare", Rate = "5%", Desc = "Strategic Mind: +25% Titan Energy Regeneration."},
	{Name = "Braun", Rarity = "Uncommon", Rate = "8%", Desc = "Thick Skinned: +25% Armor Effectiveness."},
	{Name = "Galliard", Rarity = "Uncommon", Rate = "8%", Desc = "Agile Striker: +20% Combat Speed."},
	{Name = "Braus", Rarity = "Common", Rate = "15%", Desc = "Standard military lineage. (No bloodline mutations)"},
	{Name = "Springer", Rarity = "Common", Rate = "15%", Desc = "Standard military lineage. (No bloodline mutations)"}
}

local TitansInfo = {
	{Name = "Founding Titan", Rarity = "Mythical", Rate = "0.5%", Desc = "The Coordinate. S-Rank in all domains except Speed."},
	{Name = "Beast Titan", Rarity = "Legendary", Rate = "0.6%", Desc = "Devastating force. S-Rank Power & A-Rank Precision."},
	{Name = "War Hammer Titan", Rarity = "Legendary", Rate = "0.6%", Desc = "Weapon manifestations. S-Rank Hardening & A-Rank Power."},
	{Name = "Colossal Titan", Rarity = "Legendary", Rate = "0.6%", Desc = "God of Destruction. S-Rank Power & Endurance, E-Rank Speed."},
	{Name = "Armored Titan", Rarity = "Legendary", Rate = "0.6%", Desc = "Unbreakable plating. S-Rank Hardening & A-Rank Endurance."},
	{Name = "Female Titan", Rarity = "Legendary", Rate = "0.6%", Desc = "Perfectly balanced. A-Rank in Power, Speed, and Hardening."},
	{Name = "Jaw Titan", Rarity = "Rare", Rate = "7.5%", Desc = "Lethal assassin. S-Rank Speed & A-Rank Precision."},
	{Name = "Cart Titan", Rarity = "Rare", Rate = "7.5%", Desc = "Relentless stamina. S-Rank Endurance & A-Rank Speed."},
	{Name = "Attack Titan", Rarity = "Common", Rate = "81.5%", Desc = "WARNING: DATA [REDACTED] BY ORDER OF THE KING", IsRedacted = true}
}

local function CreateStatLine(parent, labelText, valueText, layoutOrder)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, 0, 0, 25); frame.BackgroundTransparency = 1; frame.LayoutOrder = layoutOrder

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(0.4, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextColor3 = Color3.fromRGB(180, 180, 180); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = labelText

	local val = Instance.new("TextLabel", frame)
	val.Size = UDim2.new(0.6, 0, 1, 0); val.Position = UDim2.new(0.4, 0, 0, 0); val.BackgroundTransparency = 1; val.Font = Enum.Font.GothamBold; val.TextColor3 = Color3.fromRGB(255, 255, 255); val.TextSize = 14; val.TextXAlignment = Enum.TextXAlignment.Right; val.Text = valueText

	return val
end

function InheritTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "InheritFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	-- [[ LEFT PANEL: CURRENT STATS & STORAGE ]]
	local LeftPanel = Instance.new("Frame", MainFrame)
	LeftPanel.Size = UDim2.new(0.45, 0, 1, 0); LeftPanel.BackgroundTransparency = 1

	local InfoBox = Instance.new("Frame", LeftPanel)
	InfoBox.Size = UDim2.new(1, 0, 0.65, 0); InfoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", InfoBox).Color = Color3.fromRGB(80, 80, 90)

	local InfoTitle = Instance.new("TextLabel", InfoBox)
	InfoTitle.Size = UDim2.new(1, 0, 0, 40); InfoTitle.BackgroundTransparency = 1; InfoTitle.Font = Enum.Font.GothamBlack; InfoTitle.TextColor3 = Color3.fromRGB(255, 215, 100); InfoTitle.TextSize = 20; InfoTitle.Text = "YOUR INHERITANCE"

	local InfoLayout = Instance.new("UIListLayout", InfoBox)
	InfoLayout.Padding = UDim.new(0, 5); InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local InfoPad = Instance.new("UIPadding", InfoBox)
	InfoPad.PaddingTop = UDim.new(0, 45); InfoPad.PaddingLeft = UDim.new(0, 15); InfoPad.PaddingRight = UDim.new(0, 15)

	local clanVal = CreateStatLine(InfoBox, "Bloodline:", "None", 1)
	local tNameVal = CreateStatLine(InfoBox, "Titan Form:", "None", 2)
	local tTraitVal = CreateStatLine(InfoBox, "Mutation:", "None", 3)
	CreateStatLine(InfoBox, "", "", 4) 
	local tPowVal = CreateStatLine(InfoBox, "Power:", "None", 5)
	local tSpdVal = CreateStatLine(InfoBox, "Speed:", "None", 6)
	local tHardVal = CreateStatLine(InfoBox, "Hardening:", "None", 7)
	local tEndVal = CreateStatLine(InfoBox, "Endurance:", "None", 8)

	-- STORAGE BOX REDESIGN
	local StorageBox = Instance.new("Frame", LeftPanel)
	StorageBox.Size = UDim2.new(1, 0, 0.32, 0); StorageBox.Position = UDim2.new(0, 0, 0.68, 0); StorageBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	Instance.new("UICorner", StorageBox).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", StorageBox).Color = Color3.fromRGB(60, 60, 65)

	local STitle = Instance.new("TextLabel", StorageBox)
	STitle.Size = UDim2.new(1, 0, 0.3, 0); STitle.BackgroundTransparency = 1; STitle.Font = Enum.Font.GothamBold; STitle.TextColor3 = Color3.fromRGB(200, 200, 200); STitle.TextSize = 14; STitle.Text = "SPINAL FLUID STORAGE"

	-- A dedicated container purely for the slots prevents overlap with the title
	local SlotContainer = Instance.new("Frame", StorageBox)
	SlotContainer.Size = UDim2.new(1, 0, 0.7, 0)
	SlotContainer.Position = UDim2.new(0, 0, 0.3, 0)
	SlotContainer.BackgroundTransparency = 1

	local SLayout = Instance.new("UIListLayout", SlotContainer)
	SLayout.FillDirection = Enum.FillDirection.Horizontal; SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; SLayout.VerticalAlignment = Enum.VerticalAlignment.Center; SLayout.Padding = UDim.new(0.04, 0)

	local function CreateSlot(slotNum)
		local btn = Instance.new("TextButton", SlotContainer)
		-- Size scales perfectly to fit the container without overflowing
		btn.Size = UDim2.new(0.28, 0, 0.7, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.Font = Enum.Font.GothamMedium; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextScaled = true; btn.RichText = true; btn.Text = "<b>Slot " .. slotNum .. "</b>\nEmpty"

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", btn).Color = Color3.fromRGB(80, 80, 90)

		local uic = Instance.new("UITextSizeConstraint", btn)
		uic.MaxTextSize = 14
		uic.MinTextSize = 8

		btn.MouseButton1Click:Connect(function() Network:WaitForChild("StorageAction"):FireServer("StoreTitan", slotNum) end)
		return btn
	end
	local slots = { CreateSlot(1), CreateSlot(2), CreateSlot(3) }

	-- [[ RIGHT PANEL: ENCYCLOPEDIA (TWO TABLES) ]]
	local IndexBox = Instance.new("Frame", MainFrame)
	IndexBox.Size = UDim2.new(0.52, 0, 1, 0); IndexBox.Position = UDim2.new(0.48, 0, 0, 0); IndexBox.BackgroundTransparency = 1

	local function CreateTableSection(yPos, ySize, titleText, btnText, btnColor, btnAction)
		local section = Instance.new("Frame", IndexBox)
		section.Size = UDim2.new(1, 0, ySize, 0); section.Position = UDim2.new(0, 0, yPos, 0); section.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", section).Color = Color3.fromRGB(80, 80, 90)

		local header = Instance.new("Frame", section)
		header.Size = UDim2.new(1, 0, 0, 40); header.BackgroundTransparency = 1

		local title = Instance.new("TextLabel", header)
		title.Size = UDim2.new(0.6, 0, 1, 0); title.Position = UDim2.new(0, 15, 0, 0); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextColor3 = Color3.fromRGB(255, 215, 100); title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = titleText

		local btn = Instance.new("TextButton", header)
		btn.Size = UDim2.new(0.35, 0, 0.7, 0); btn.Position = UDim2.new(0.97, 0, 0.5, 0); btn.AnchorPoint = Vector2.new(1, 0.5); btn.BackgroundColor3 = btnColor; btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12; btn.Text = btnText
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		btn.MouseButton1Click:Connect(btnAction)

		local list = Instance.new("ScrollingFrame", section)
		list.Size = UDim2.new(1, -20, 1, -45); list.Position = UDim2.new(0, 10, 0, 40); list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 4; list.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 60)
		local lLayout = Instance.new("UIListLayout", list); lLayout.Padding = UDim.new(0, 8); lLayout.SortOrder = Enum.SortOrder.LayoutOrder
		Instance.new("UIPadding", list).PaddingTop = UDim.new(0, 5)

		return list
	end

	local ClanScroll = CreateTableSection(0, 0.48, "KNOWN BLOODLINES", "USE BLOOD VIAL", Color3.fromRGB(140, 40, 40), function()
		Network:WaitForChild("UseItem"):FireServer("Clan Blood Vial")
	end)

	local TitanScroll = CreateTableSection(0.52, 0.48, "NINE TITANS", "USE SERUM", Color3.fromRGB(40, 80, 40), function()
		Network:WaitForChild("UseItem"):FireServer("Standard Titan Serum")
	end)

	local function PopulateTable(targetScroll, dataTable)
		for i, data in ipairs(dataTable) do
			local entry = Instance.new("Frame", targetScroll)
			entry.Size = UDim2.new(1, -10, 0, 55); entry.BackgroundColor3 = Color3.fromRGB(30, 30, 35); entry.LayoutOrder = i
			Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)
			Instance.new("UIStroke", entry).Color = Color3.fromRGB(60, 60, 65)

			local rColorObj = RarityColors[data.Rarity] or Color3.fromRGB(255, 255, 255)
			-- Convert Color3 to Hex for RichText
			local rColor = string.format("#%02X%02X%02X", rColorObj.R*255, rColorObj.G*255, rColorObj.B*255)

			local eTitle = Instance.new("TextLabel", entry)
			eTitle.Size = UDim2.new(0.6, -10, 0, 20); eTitle.Position = UDim2.new(0, 10, 0, 5); eTitle.BackgroundTransparency = 1; eTitle.Font = Enum.Font.GothamBold; eTitle.TextColor3 = Color3.fromRGB(240, 240, 240); eTitle.TextSize = 15; eTitle.TextXAlignment = Enum.TextXAlignment.Left
			eTitle.Text = data.Name

			local rTag = Instance.new("TextLabel", entry)
			rTag.Size = UDim2.new(0.35, 0, 0, 16); rTag.Position = UDim2.new(1, -10, 0, 7); rTag.AnchorPoint = Vector2.new(1, 0); rTag.BackgroundColor3 = rColorObj; rTag.Font = Enum.Font.GothamBold; rTag.TextColor3 = Color3.fromRGB(20, 20, 25); rTag.TextSize = 11; rTag.Text = data.Rarity:upper() .. " (" .. data.Rate .. ")"
			Instance.new("UICorner", rTag).CornerRadius = UDim.new(0, 4)

			local eDesc = Instance.new("TextLabel", entry)
			eDesc.Size = UDim2.new(1, -20, 0, 20); eDesc.Position = UDim2.new(0, 10, 0, 28); eDesc.BackgroundTransparency = 1; eDesc.Font = data.IsRedacted and Enum.Font.SciFi or Enum.Font.GothamMedium; eDesc.TextColor3 = data.IsRedacted and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(170, 170, 170); eDesc.TextSize = 12; eDesc.TextXAlignment = Enum.TextXAlignment.Left
			eDesc.Text = data.Desc
		end
	end

	PopulateTable(ClanScroll, ClansInfo)
	PopulateTable(TitanScroll, TitansInfo)

	local function UpdateData()
		clanVal.Text = player:GetAttribute("Clan") or "None"
		tNameVal.Text = player:GetAttribute("Titan") or "None"
		tTraitVal.Text = player:GetAttribute("TitanTrait") or "None"
		tPowVal.Text = player:GetAttribute("Titan_Power") or "None"
		tSpdVal.Text = player:GetAttribute("Titan_Speed") or "None"
		tHardVal.Text = player:GetAttribute("Titan_Hardening") or "None"
		tEndVal.Text = player:GetAttribute("Titan_Endurance") or "None"

		for i, btn in ipairs(slots) do
			local sName = player:GetAttribute("StoredTitan" .. i) or "None"
			if i > 1 and not player:GetAttribute("HasTitanSlot" .. i) then
				btn.Text = "<font color='#AAAAAA'><b>Slot " .. i .. "</b>\n[LOCKED]</font>"
				btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
			else
				local displayName = (sName == "None") and "Empty" or sName
				btn.Text = "<b>Slot " .. i .. "</b>\n<font color='#FFFFFF'>" .. displayName .. "</font>"
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			end
		end
	end

	player.AttributeChanged:Connect(UpdateData)
	UpdateData()
end

function InheritTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return InheritTab