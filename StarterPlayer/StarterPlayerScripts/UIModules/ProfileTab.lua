-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ProfileTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local player = Players.LocalPlayer
local MainFrame
local InvGrid
local wpnLabel, accLabel, titanLabel, clanLabel
local titanAwakenBtn, clanAwakenBtn, prestigeBtn

local RadarContainer
local toggleStatsBtn
local isShowingTitanStats = false

local RarityColors = {
	["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5555FF",
	["Epic"] = "#AA00FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333"
}
local RarityOrder = { Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }
local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500 }

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

local function DrawLineScale(parent, p1x, p1y, p2x, p2y, color, thickness, zindex)
	local dx = p2x - p1x; local dy = p2y - p1y; local dist = math.sqrt(dx*dx + dy*dy)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(0, dist, 0, thickness); frame.Position = UDim2.new(0, (p1x + p2x)/2, 0, (p1y + p2y)/2)
	frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Rotation = math.deg(math.atan2(dy, dx))
	frame.BackgroundColor3 = color; frame.BorderSizePixel = 0; frame.ZIndex = zindex or 1
	return frame
end

local function DrawUITriangle(parent, p1, p2, p3, color, transp, zIndex)
	local edges = { {p1, p2}, {p2, p3}, {p3, p1} }
	table.sort(edges, function(a, b) return (a[1]-a[2]).Magnitude > (b[1]-b[2]).Magnitude end)
	local a, b = edges[1][1], edges[1][2]
	local c = edges[2][1] == a and edges[2][2] or edges[2][1]
	if c == b then c = edges[3][1] == a and edges[3][2] or edges[3][1] end

	local ab = b - a; local ac = c - a; local dir = ab.Unit
	local projLen = ac:Dot(dir); local proj = dir * projLen; local h = (ac - proj).Magnitude
	local w1 = projLen; local w2 = ab.Magnitude - projLen
	local rot1 = math.deg(math.atan2(dir.Y, dir.X)); local rot2 = math.deg(math.atan2(-dir.Y, -dir.X))

	local t1 = Instance.new("ImageLabel")
	t1.BackgroundTransparency = 1; t1.Image = "rbxassetid://319692171"; t1.ImageColor3 = color; t1.ImageTransparency = transp; t1.ZIndex = zIndex; t1.BorderSizePixel = 0; t1.AnchorPoint = Vector2.new(0.5, 0.5)
	local t2 = t1:Clone()

	t1.Size = UDim2.new(0, w1, 0, h); t2.Size = UDim2.new(0, w2, 0, h)
	t1.Position = UDim2.new(0, a.X + proj.X/2, 0, a.Y + proj.Y/2)
	t2.Position = UDim2.new(0, b.X + (proj.X - ab.X)/2, 0, b.Y + (proj.Y - ab.Y)/2)
	t1.Rotation = rot1; t2.Rotation = rot2

	local cross = ab.X * ac.Y - ab.Y * ac.X
	if cross < 0 then
		t1.ImageRectOffset = Vector2.new(1024, 1024); t1.ImageRectSize = Vector2.new(-1024, -1024)
		t2.ImageRectOffset = Vector2.new(1024, 1024); t2.ImageRectSize = Vector2.new(-1024, -1024)
	end
	t1.Parent = parent; t2.Parent = parent
end

function ProfileTab.Init(parentFrame, tooltipMgr)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "ProfileFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	local LeftPanel = Instance.new("Frame", MainFrame)
	LeftPanel.Size = UDim2.new(0.35, 0, 1, 0); LeftPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", LeftPanel).Color = Color3.fromRGB(80, 80, 90)

	local AvatarBox = Instance.new("ImageLabel", LeftPanel)
	AvatarBox.Size = UDim2.new(0, 100, 0, 100); AvatarBox.Position = UDim2.new(0.5, -50, 0, 15); AvatarBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	AvatarBox.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	Instance.new("UICorner", AvatarBox).CornerRadius = UDim.new(0, 50); Instance.new("UIStroke", AvatarBox).Color = Color3.fromRGB(120, 100, 60)

	local NameLabel = Instance.new("TextLabel", LeftPanel)
	NameLabel.Size = UDim2.new(1, 0, 0, 25); NameLabel.Position = UDim2.new(0, 0, 0, 125); NameLabel.BackgroundTransparency = 1
	NameLabel.Font = Enum.Font.GothamBlack; NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255); NameLabel.TextSize = 20; NameLabel.Text = player.Name
	ApplyGradient(NameLabel, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local idenFrame = Instance.new("Frame", LeftPanel)
	idenFrame.Size = UDim2.new(0.9, 0, 0, 110); idenFrame.Position = UDim2.new(0.05, 0, 0, 150); idenFrame.BackgroundTransparency = 1
	local idenLayout = Instance.new("UIListLayout", idenFrame); idenLayout.Padding = UDim.new(0, 4)

	local function CreateInfoLabel(parent)
		local l = Instance.new("TextLabel", parent)
		l.Size = UDim2.new(1, 0, 0, 22); l.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.fromRGB(200, 200, 200); l.TextSize = 13; l.TextXAlignment = Enum.TextXAlignment.Left
		local pad = Instance.new("UIPadding", l); pad.PaddingLeft = UDim.new(0, 10); Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)
		return l
	end

	local titanRow = Instance.new("Frame", idenFrame); titanRow.Size = UDim2.new(1, 0, 0, 22); titanRow.BackgroundTransparency = 1
	titanLabel = CreateInfoLabel(titanRow); titanLabel.Size = UDim2.new(1, 0, 1, 0)
	titanAwakenBtn = Instance.new("TextButton", titanRow); titanAwakenBtn.Size = UDim2.new(0.3, 0, 0.8, 0); titanAwakenBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
	titanAwakenBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); titanAwakenBtn.Font = Enum.Font.GothamBold; titanAwakenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); titanAwakenBtn.TextSize = 10; titanAwakenBtn.Text = "AWAKEN"
	Instance.new("UICorner", titanAwakenBtn).CornerRadius = UDim.new(0, 4); titanAwakenBtn.Visible = false

	local clanRow = Instance.new("Frame", idenFrame); clanRow.Size = UDim2.new(1, 0, 0, 22); clanRow.BackgroundTransparency = 1
	clanLabel = CreateInfoLabel(clanRow); clanLabel.Size = UDim2.new(1, 0, 1, 0)
	clanAwakenBtn = Instance.new("TextButton", clanRow); clanAwakenBtn.Size = UDim2.new(0.3, 0, 0.8, 0); clanAwakenBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
	clanAwakenBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); clanAwakenBtn.Font = Enum.Font.GothamBold; clanAwakenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); clanAwakenBtn.TextSize = 10; clanAwakenBtn.Text = "AWAKEN"
	Instance.new("UICorner", clanAwakenBtn).CornerRadius = UDim.new(0, 4); clanAwakenBtn.Visible = false

	titanAwakenBtn.MouseButton1Click:Connect(function() Network.AwakenAction:FireServer("Titan") end)
	clanAwakenBtn.MouseButton1Click:Connect(function() Network.AwakenAction:FireServer("Clan") end)

	wpnLabel = CreateInfoLabel(idenFrame)
	accLabel = CreateInfoLabel(idenFrame)

	prestigeBtn = Instance.new("TextButton", LeftPanel)
	prestigeBtn.Size = UDim2.new(0.9, 0, 0, 30); prestigeBtn.Position = UDim2.new(0.05, 0, 0, 260)
	prestigeBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 40); prestigeBtn.Font = Enum.Font.GothamBlack; prestigeBtn.TextColor3 = Color3.fromRGB(40, 20, 20); prestigeBtn.TextSize = 12; prestigeBtn.Text = "PRESTIGE (RESET CAMPAIGN)"
	Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", prestigeBtn).Color = Color3.fromRGB(255, 215, 100); prestigeBtn.Visible = false
	prestigeBtn.MouseButton1Click:Connect(function() Network.PrestigeEvent:FireServer() end)

	toggleStatsBtn = Instance.new("TextButton", LeftPanel)
	toggleStatsBtn.Size = UDim2.new(0.8, 0, 0, 35); toggleStatsBtn.AnchorPoint = Vector2.new(0.5, 1); toggleStatsBtn.Position = UDim2.new(0.5, 0, 1, -15)
	toggleStatsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); toggleStatsBtn.Font = Enum.Font.GothamBold; toggleStatsBtn.TextColor3 = Color3.fromRGB(200, 200, 255); toggleStatsBtn.TextSize = 12; toggleStatsBtn.Text = "VIEW TITAN STATS"
	Instance.new("UICorner", toggleStatsBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", toggleStatsBtn).Color = Color3.fromRGB(100, 100, 150)

	RadarContainer = Instance.new("Frame", LeftPanel)
	RadarContainer.Size = UDim2.new(0.65, 0, 0.65, 0)
	local ar = Instance.new("UIAspectRatioConstraint", RadarContainer); ar.AspectRatio = 1.0; ar.DominantAxis = Enum.DominantAxis.Width 
	RadarContainer.AnchorPoint = Vector2.new(0.5, 0); RadarContainer.Position = UDim2.new(0.5, 0, 0, 300); RadarContainer.BackgroundTransparency = 1

	local RightPanel = Instance.new("Frame", MainFrame)
	RightPanel.Size = UDim2.new(0.63, 0, 1, 0); RightPanel.Position = UDim2.new(0.37, 0, 0, 0); RightPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", RightPanel).Color = Color3.fromRGB(80, 80, 90)

	local InvTitle = Instance.new("TextLabel", RightPanel)
	InvTitle.Size = UDim2.new(1, 0, 0, 40); InvTitle.BackgroundTransparency = 1; InvTitle.Font = Enum.Font.GothamBlack; InvTitle.TextColor3 = Color3.fromRGB(255, 215, 100); InvTitle.TextSize = 20; InvTitle.Text = "INVENTORY (CLICK TO EQUIP)"
	ApplyGradient(InvTitle, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local AutoSellFrame = Instance.new("Frame", RightPanel)
	AutoSellFrame.Size = UDim2.new(1, -20, 0, 30); AutoSellFrame.Position = UDim2.new(0, 10, 0, 40); AutoSellFrame.BackgroundTransparency = 1
	local asLabel = Instance.new("TextLabel", AutoSellFrame)
	asLabel.Size = UDim2.new(0.2, 0, 1, 0); asLabel.BackgroundTransparency = 1; asLabel.Font = Enum.Font.GothamBold; asLabel.TextColor3 = Color3.fromRGB(180, 180, 180); asLabel.TextSize = 12; asLabel.TextXAlignment = Enum.TextXAlignment.Left; asLabel.Text = "Auto-Sell Gear:"

	local function CreateAutoSell(rarity, posX, color)
		local asBtn = Instance.new("TextButton", AutoSellFrame)
		asBtn.Size = UDim2.new(0.2, 0, 0.8, 0); asBtn.Position = UDim2.new(posX, 0, 0.1, 0); asBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		asBtn.Font = Enum.Font.GothamBold; asBtn.TextColor3 = color; asBtn.TextSize = 11; asBtn.Text = "All " .. rarity
		Instance.new("UICorner", asBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", asBtn).Color = Color3.fromRGB(60, 60, 70)
		asBtn.MouseButton1Click:Connect(function() Network.AutoSell:FireServer(rarity) end)
	end
	CreateAutoSell("Common", 0.25, Color3.fromRGB(180, 180, 180))
	CreateAutoSell("Uncommon", 0.48, Color3.fromRGB(100, 255, 100))
	CreateAutoSell("Rare", 0.71, Color3.fromRGB(100, 100, 255))

	InvGrid = Instance.new("ScrollingFrame", RightPanel)
	InvGrid.Size = UDim2.new(1, -20, 1, -80); InvGrid.Position = UDim2.new(0, 10, 0, 75); InvGrid.BackgroundTransparency = 1; InvGrid.BorderSizePixel = 0; InvGrid.ScrollBarThickness = 4
	local gl = Instance.new("UIGridLayout", InvGrid); gl.CellSize = UDim2.new(0.49, 0, 0, 80); gl.CellPadding = UDim2.new(0.02, 0, 0, 10)

	local function RenderRadarChart()
		local w = RadarContainer.AbsoluteSize.X; local h = RadarContainer.AbsoluteSize.Y
		if w == 0 then return end 

		-- THE FIX: Synchronous, safe clear. No yields means no race conditions.
		for _, child in ipairs(RadarContainer:GetChildren()) do
			if not child:IsA("UIAspectRatioConstraint") then child:Destroy() end
		end

		local ls = player:FindFirstChild("leaderstats")
		local p = ls and ls:FindFirstChild("Prestige")
		local maxVal = GameData.GetStatCap(p and p.Value or 0)

		local stats
		if isShowingTitanStats then
			toggleStatsBtn.Text = "VIEW HUMAN STATS"
			stats = {
				{Name = "POW", Val = player:GetAttribute("Titan_Power_Val") or 1}, {Name = "SPD", Val = player:GetAttribute("Titan_Speed_Val") or 1},
				{Name = "HRD", Val = player:GetAttribute("Titan_Hardening_Val") or 1}, {Name = "END", Val = player:GetAttribute("Titan_Endurance_Val") or 1},
				{Name = "GAS", Val = player:GetAttribute("Titan_Precision_Val") or 1}, {Name = "POT", Val = player:GetAttribute("Titan_Potential_Val") or 1}
			}
		else
			toggleStatsBtn.Text = "VIEW TITAN STATS"
			stats = {
				{Name = "HP", Val = player:GetAttribute("Health") or 1}, {Name = "STR", Val = player:GetAttribute("Strength") or 1},
				{Name = "DEF", Val = player:GetAttribute("Defense") or 1}, {Name = "SPD", Val = player:GetAttribute("Speed") or 1},
				{Name = "GAS", Val = player:GetAttribute("Gas") or 1}, {Name = "RES", Val = player:GetAttribute("Resolve") or 1}
			}
		end

		local angles = {-90, -30, 30, 90, 150, 210}
		local centerX, centerY = w/2, h/2
		local maxRadius = w * 0.28 

		for ring = 1, 3 do
			local r = maxRadius * (ring / 3)
			for i = 1, 6 do
				local nextI = i % 6 + 1
				local a1 = math.rad(angles[i]); local a2 = math.rad(angles[nextI])
				DrawLineScale(RadarContainer, centerX + r*math.cos(a1), centerY + r*math.sin(a1), centerX + r*math.cos(a2), centerY + r*math.sin(a2), Color3.fromRGB(60, 60, 70), 1, 1)
			end
		end

		for i = 1, 6 do
			local rad = math.rad(angles[i])
			local px = centerX + maxRadius * math.cos(rad); local py = centerY + maxRadius * math.sin(rad)
			DrawLineScale(RadarContainer, centerX, centerY, px, py, Color3.fromRGB(60, 60, 70), 1, 1)

			local lbl = Instance.new("TextLabel", RadarContainer)
			lbl.Size = UDim2.new(0, 40, 0, 20); lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.new(0, centerX + (maxRadius + 20) * math.cos(rad), 0, centerY + (maxRadius + 20) * math.sin(rad))
			lbl.AnchorPoint = Vector2.new(0.5, 0.5); lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.TextSize = 11
			lbl.Text = stats[i].Name .. "\n" .. stats[i].Val
		end

		local statColor = isShowingTitanStats and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
		local pointVecs = {}

		for i = 1, 6 do
			local v1 = math.clamp(stats[i].Val / maxVal, 0.05, 1)
			local a1 = math.rad(angles[i]); local r1 = maxRadius * v1
			local px = centerX + r1 * math.cos(a1); local py = centerY + r1 * math.sin(a1)
			table.insert(pointVecs, Vector2.new(px, py))
		end

		for i = 1, 6 do
			local nextI = i % 6 + 1
			DrawLineScale(RadarContainer, pointVecs[i].X, pointVecs[i].Y, pointVecs[nextI].X, pointVecs[nextI].Y, statColor, 3, 5)
		end

		local centerVec = Vector2.new(centerX, centerY)
		for i = 1, 6 do
			local nextI = i % 6 + 1
			DrawUITriangle(RadarContainer, centerVec, pointVecs[i], pointVecs[nextI], statColor, 0.5, 3)
		end
	end

	RadarContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(RenderRadarChart)
	toggleStatsBtn.MouseButton1Click:Connect(function() isShowingTitanStats = not isShowingTitanStats; RenderRadarChart() end)

	local function RefreshProfile()
		local tName = player:GetAttribute("Titan") or "None"
		local cName = player:GetAttribute("Clan") or "None"
		local cPart = player:GetAttribute("CurrentPart") or 1

		titanLabel.Text = "Titan: <font color='#FF5555'>" .. tName .. "</font>"; titanLabel.RichText = true
		clanLabel.Text = "Clan: <font color='#55FF55'>" .. cName .. "</font>"; clanLabel.RichText = true
		wpnLabel.Text = "Weapon: " .. (player:GetAttribute("EquippedWeapon") or "None")
		accLabel.Text = "Accessory: " .. (player:GetAttribute("EquippedAccessory") or "None")

		if tName == "Attack Titan" and (player:GetAttribute("YmirsClayFragmentCount") or 0) > 0 then titanAwakenBtn.Visible = true else titanAwakenBtn.Visible = false end
		if cName == "Ackerman" and (player:GetAttribute("AckermanAwakeningPillCount") or 0) > 0 then clanAwakenBtn.Visible = true else clanAwakenBtn.Visible = false end

		-- Adjusts height based on Prestige Button visibility
		if cPart > 7 then prestigeBtn.Visible = true; RadarContainer.Position = UDim2.new(0.5, 0, 0, 300)
		else prestigeBtn.Visible = false; RadarContainer.Position = UDim2.new(0.5, 0, 0, 260) end

		RenderRadarChart()

		for _, child in ipairs(InvGrid:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

		local inventoryItems = {}
		for iName, iData in pairs(ItemData.Equipment) do table.insert(inventoryItems, {Name = iName, Data = iData}) end
		for iName, iData in pairs(ItemData.Consumables) do table.insert(inventoryItems, {Name = iName, Data = iData}) end

		table.sort(inventoryItems, function(a, b)
			local rA = RarityOrder[a.Data.Rarity or "Common"] or 6
			local rB = RarityOrder[b.Data.Rarity or "Common"] or 6
			if rA == rB then return a.Name < b.Name else return rA < rB end
		end)

		for _, item in ipairs(inventoryItems) do
			local itemName = item.Name
			local itemInfo = item.Data
			local safeName = itemName:gsub("[^%w]", "") .. "Count"
			local count = player:GetAttribute(safeName) or 0

			if count > 0 then
				local card = Instance.new("Frame", InvGrid)
				card.BackgroundColor3 = Color3.fromRGB(25, 25, 30); Instance.new("UICorner", card).CornerRadius = UDim.new(0, 4)

				local rarityKey = itemInfo.Rarity or "Common"
				local cColor = RarityColors[rarityKey] or "#FFFFFF"

				local glow = Instance.new("Frame", card)
				glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 2, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", ""))
				Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)

				local nameLbl = Instance.new("TextLabel", card)
				nameLbl.Size = UDim2.new(1, -80, 0.4, 0); nameLbl.Position = UDim2.new(0, 15, 0, 5); nameLbl.BackgroundTransparency = 1
				nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextColor3 = Color3.fromRGB(230, 230, 230); nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.RichText = true
				nameLbl.Text = "<b><font color='" .. cColor .. "'>[" .. rarityKey .. "]</font></b> " .. itemName
				nameLbl.TextSize = 15 

				local buffStr = "No Combat Buffs"
				if itemInfo.Bonus then
					local bList = {}
					for k, v in pairs(itemInfo.Bonus) do table.insert(bList, "+" .. v .. " " .. string.sub(k, 1, 3):upper()) end
					buffStr = "<font color='#55FF55'>" .. table.concat(bList, " | ") .. "</font>"
				elseif itemInfo.Desc then
					buffStr = "<font color='#AAAAAA'>" .. itemInfo.Desc .. "</font>"
				end

				local buffLbl = Instance.new("TextLabel", card)
				buffLbl.Size = UDim2.new(1, -80, 0.3, 0); buffLbl.Position = UDim2.new(0, 15, 0.4, 0); buffLbl.BackgroundTransparency = 1
				buffLbl.Font = Enum.Font.GothamMedium; buffLbl.TextColor3 = Color3.fromRGB(180, 180, 180); buffLbl.TextXAlignment = Enum.TextXAlignment.Left; buffLbl.RichText = true
				buffLbl.Text = buffStr; buffLbl.TextSize = 11

				local countLbl = Instance.new("TextLabel", card)
				countLbl.Size = UDim2.new(1, -80, 0.3, 0); countLbl.Position = UDim2.new(0, 15, 0.7, 0); countLbl.BackgroundTransparency = 1
				countLbl.Font = Enum.Font.GothamMedium; countLbl.TextColor3 = Color3.fromRGB(150, 150, 150); countLbl.TextXAlignment = Enum.TextXAlignment.Left
				countLbl.Text = "Owned: " .. count; countLbl.TextSize = 12

				local isEquipable = itemInfo.Type ~= nil
				local isUsable = itemInfo.Action ~= nil

				local equipBtn = Instance.new("TextButton", card)
				equipBtn.AnchorPoint = Vector2.new(1, 0)
				equipBtn.Size = UDim2.new(0, 60, 0, 26); equipBtn.Position = UDim2.new(1, -10, 0, 8)
				equipBtn.Font = Enum.Font.GothamBold; equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255); equipBtn.TextSize = 11
				Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 4)

				local sellVal = SellValues[rarityKey] or 10
				local sellBtn = Instance.new("TextButton", card)
				sellBtn.AnchorPoint = Vector2.new(1, 0)
				sellBtn.Size = UDim2.new(0, 60, 0, 26); sellBtn.Position = UDim2.new(1, -10, 0, 42); sellBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
				sellBtn.Font = Enum.Font.GothamBold; sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255); sellBtn.TextSize = 11; sellBtn.Text = "SELL"
				Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 4)

				if isEquipable then
					equipBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40); equipBtn.Text = "EQUIP"
					equipBtn.MouseButton1Click:Connect(function() Network.EquipItem:FireServer(itemName) end)
				elseif isUsable then
					equipBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 120); equipBtn.Text = "USE"
					equipBtn.MouseButton1Click:Connect(function() 
						if itemInfo.Action == "AwakenTitan" then Network.AwakenAction:FireServer("Titan")
						elseif itemInfo.Action == "AwakenClan" then Network.AwakenAction:FireServer("Clan") end
					end)
				else
					equipBtn.Visible = false
					sellBtn.Position = UDim2.new(1, -10, 0.5, 0)
					sellBtn.AnchorPoint = Vector2.new(1, 0.5)
				end

				sellBtn.MouseButton1Click:Connect(function()
					Network.SellItem:FireServer(itemName)
					if count <= 1 then tooltipMgr.Hide() end
				end)
				sellBtn.MouseEnter:Connect(function() tooltipMgr.Show("Sell for <font color='#55FFFF'>+" .. sellVal .. " Dews</font>") end)
				sellBtn.MouseLeave:Connect(function() tooltipMgr.Hide() end)
			end
		end

		task.delay(0.05, function() InvGrid.CanvasSize = UDim2.new(0, 0, 0, gl.AbsoluteContentSize.Y + 20) end)
	end

	player.AttributeChanged:Connect(RefreshProfile)
	RefreshProfile()
end

function ProfileTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return ProfileTab