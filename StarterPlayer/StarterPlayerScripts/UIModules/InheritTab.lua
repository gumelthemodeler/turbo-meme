-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local InheritTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local EffectsManager = require(script.Parent:WaitForChild("EffectsManager"))

local player = Players.LocalPlayer
local MainFrame
local isRolling = { Titan = false, Clan = false }

local RarityColors = {
	["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5555FF",
	["Epic"] = "#AA00FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333"
}

local RarityOrder = { Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }

local ClanVisualBuffs = {
	["None"] = "No inherent abilities.", ["Braus"] = "+10% Speed", ["Springer"] = "+15% Evasion",
	["Galliard"] = "+15% Speed, +5% Power", ["Braun"] = "+20% Defense", ["Arlert"] = "+15% Resolve",
	["Tybur"] = "+20% Titan Power", ["Yeager"] = "+25% Titan Damage", ["Reiss"] = "+50% Base Health",
	["Ackerman"] = "+25% Weapon Damage, Immune to Memory Wipes", ["Awakened Ackerman"] = "+25% Weapon Damage, Exteme Agility"
}

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function InheritTab.Init(parentFrame, tooltipMgr)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "InheritFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 24; Title.Text = "THE PATHS (INHERITANCE)"
	ApplyGradient(Title, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local function CreateGachaPanel(gType, posX)
		local Panel = Instance.new("Frame", MainFrame)
		Panel.Size = UDim2.new(0.48, 0, 0.85, 0); Panel.Position = UDim2.new(posX, 0, 0.1, 0); Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18) 
		Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", Panel).Color = Color3.fromRGB(120, 100, 60)

		local PTitle = Instance.new("TextLabel", Panel)
		PTitle.Size = UDim2.new(1, 0, 0, 30); PTitle.BackgroundTransparency = 1; PTitle.Font = Enum.Font.GothamBlack; PTitle.TextColor3 = Color3.fromRGB(255, 255, 255); PTitle.TextSize = 18; PTitle.Text = (gType == "Titan") and "TITAN INHERITANCE" or "CLAN LINEAGE"

		local ListContainer = Instance.new("Frame", Panel)
		ListContainer.Size = UDim2.new(1, -20, 0.55, 0); ListContainer.Position = UDim2.new(0, 10, 0, 35); ListContainer.BackgroundTransparency = 1
		local SList = Instance.new("UIListLayout", ListContainer); SList.Padding = UDim.new(0, 4)

		if gType == "Titan" then
			local sortedTitans = {}
			for tName, tData in pairs(TitanData.Titans) do table.insert(sortedTitans, tData) end
			table.sort(sortedTitans, function(a, b) return RarityOrder[a.Rarity] < RarityOrder[b.Rarity] end)

			for _, drop in ipairs(sortedTitans) do
				local row = Instance.new("Frame", ListContainer); row.Size = UDim2.new(1, 0, 0.1, 0); row.BackgroundTransparency = 1 
				local cColor = RarityColors[drop.Rarity] or "#FFFFFF"
				local glow = Instance.new("Frame", row); glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 0, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", ""))
				Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)

				local countInRarity = 0
				for _, t in pairs(TitanData.Titans) do if t.Rarity == drop.Rarity then countInRarity += 1 end end
				local pct = (TitanData.Rarities[drop.Rarity] / countInRarity)
				local s = drop.Stats
				local statString = string.format("POW:%s SPD:%s HRD:%s END:%s PRE:%s POT:%s", s.Power, s.Speed, s.Hardening, s.Endurance, s.Precision, s.Potential)

				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1, -15, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextScaled = true
				lbl.Text = "<b><font color='" .. cColor .. "'>[" .. drop.Rarity .. "] " .. drop.Name .. " (" .. string.format("%.1f", pct) .. "%)</font></b>  |  <font color='#888888'>" .. statString .. "</font>"
				Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 13
			end
		else
			local sortedClans = {}
			for cName, weight in pairs(TitanData.ClanWeights) do table.insert(sortedClans, {Name = cName, Weight = weight}) end
			table.sort(sortedClans, function(a, b) return a.Weight < b.Weight end)

			for _, drop in ipairs(sortedClans) do
				local row = Instance.new("Frame", ListContainer); row.Size = UDim2.new(1, 0, 0.09, 0); row.BackgroundTransparency = 1
				local rarityTag = "Common"
				if drop.Weight <= 1.5 then rarityTag = "Mythical" elseif drop.Weight <= 4.0 then rarityTag = "Legendary" elseif drop.Weight <= 8.0 then rarityTag = "Epic" elseif drop.Weight <= 15.0 then rarityTag = "Rare" end
				local cColor = RarityColors[rarityTag] or "#FFFFFF"
				local glow = Instance.new("Frame", row); glow.Size = UDim2.new(0, 4, 1, -4); glow.Position = UDim2.new(0, 0, 0, 2); glow.BackgroundColor3 = Color3.fromHex(cColor:gsub("#", ""))
				Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 2)
				local buffText = ClanVisualBuffs[drop.Name] or "Unknown"

				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1, -15, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextScaled = true
				lbl.Text = "<b><font color='" .. cColor .. "'>[" .. rarityTag .. "] " .. drop.Name .. " (" .. string.format("%.1f", drop.Weight) .. "%)</font></b>  |  <font color='#888888'>" .. buffText .. "</font>"
				Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 13
			end
		end

		local BottomArea = Instance.new("Frame", Panel)
		BottomArea.Size = UDim2.new(1, 0, 0.35, 0); BottomArea.Position = UDim2.new(0, 0, 0.65, 0); BottomArea.BackgroundTransparency = 1

		local ResultLbl = Instance.new("TextLabel", BottomArea)
		ResultLbl.Size = UDim2.new(1, 0, 0, 25); ResultLbl.Position = UDim2.new(0, 0, 0, 0); ResultLbl.BackgroundTransparency = 1; ResultLbl.Font = Enum.Font.GothamBlack; ResultLbl.TextColor3 = Color3.fromRGB(255, 255, 255); ResultLbl.TextSize = 18; ResultLbl.RichText = true; ResultLbl.Text = "Current: None"

		local StorageArea = Instance.new("Frame", BottomArea)
		StorageArea.Size = UDim2.new(0.9, 0, 0, 35); StorageArea.Position = UDim2.new(0.05, 0, 0.25, 0); StorageArea.BackgroundTransparency = 1
		local sg = Instance.new("UIGridLayout", StorageArea); sg.CellSize = UDim2.new(0.15, 0, 1, 0); sg.CellPadding = UDim2.new(0.02, 0, 0, 0); sg.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local storageBtns = {}
		for i = 1, 6 do
			local sBtn = Instance.new("TextButton", StorageArea)
			sBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); sBtn.Font = Enum.Font.GothamBold; sBtn.TextColor3 = Color3.fromRGB(200, 200, 200); sBtn.TextSize = 10; sBtn.Text = "Empty"
			Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", sBtn).Color = Color3.fromRGB(60, 60, 70)

			sBtn.MouseButton1Click:Connect(function()
				if i > 3 and not player:GetAttribute("Has" .. gType .. "Vault") then
					tooltipMgr.Show("<font color='#FF5555'>Locked. Requires Vault Expansion Gamepass!</font>")
					task.delay(1.5, function() tooltipMgr.Hide() end)
					return
				end
				Network.ManageStorage:FireServer(gType, i)
			end)

			sBtn.MouseEnter:Connect(function() tooltipMgr.Show("Swap Active " .. gType .. " with Slot " .. i) end)
			sBtn.MouseLeave:Connect(function() tooltipMgr.Hide() end)
			storageBtns[i] = sBtn
		end

		local PityLbl = Instance.new("TextLabel", BottomArea)
		PityLbl.Size = UDim2.new(1, 0, 0, 20); PityLbl.Position = UDim2.new(0, 0, 0.5, 0); PityLbl.BackgroundTransparency = 1; PityLbl.Font = Enum.Font.GothamBold; PityLbl.TextColor3 = Color3.fromRGB(200, 150, 255); PityLbl.TextSize = 14; PityLbl.Text = "PITY: 0 / 100"

		local RollBtn = Instance.new("TextButton", BottomArea)
		RollBtn.Size = UDim2.new(0.28, 0, 0, 35); RollBtn.Position = UDim2.new(0.04, 0, 0.65, 0); RollBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60); RollBtn.Font = Enum.Font.GothamBold; RollBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RollBtn.TextSize = 10
		local labelPrefix = (gType == "Titan") and "Serum" or "Vial"
		RollBtn.Text = "ROLL (1x " .. labelPrefix .. ")\nOwned: 0"
		Instance.new("UICorner", RollBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", RollBtn).Color = Color3.fromRGB(80, 150, 80)

		local PremiumRollBtn = Instance.new("TextButton", BottomArea)
		PremiumRollBtn.Size = UDim2.new(0.28, 0, 0, 35); PremiumRollBtn.Position = UDim2.new(0.36, 0, 0.65, 0); PremiumRollBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 40); PremiumRollBtn.Font = Enum.Font.GothamBold; PremiumRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PremiumRollBtn.TextSize = 10
		Instance.new("UICorner", PremiumRollBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", PremiumRollBtn).Color = Color3.fromRGB(200, 150, 50)
		if gType == "Titan" then PremiumRollBtn.Text = "PREMIUM (1x Syringe)\nOwned: 0" else PremiumRollBtn.Text = "N/A"; PremiumRollBtn.Visible = false end

		local AutoRollBtn = Instance.new("TextButton", BottomArea)
		AutoRollBtn.Size = UDim2.new(0.28, 0, 0, 35); AutoRollBtn.Position = UDim2.new(0.68, 0, 0.65, 0); AutoRollBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 120); AutoRollBtn.Font = Enum.Font.GothamBold; AutoRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255); AutoRollBtn.TextSize = 10; AutoRollBtn.Text = "ROLL TILL LEGENDARY+"
		Instance.new("UICorner", AutoRollBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", AutoRollBtn).Color = Color3.fromRGB(150, 80, 150)

		local attrReq = (gType == "Titan") and "StandardTitanSerumCount" or "ClanBloodVialCount"

		RollBtn.MouseButton1Click:Connect(function()
			if isRolling[gType] then return end
			local count = player:GetAttribute(attrReq) or 0
			if count > 0 then
				isRolling[gType] = true
				Network.GachaRoll:FireServer(gType, false)
			else
				ResultLbl.Text = "<font color='#FF5555'>Not enough items!</font>"
				EffectsManager.PlaySFX("Error", 1)
				task.delay(1.5, function() if not isRolling[gType] then ResultLbl.Text = "Current: " .. (player:GetAttribute(gType) or "None") end end)
			end
		end)

		PremiumRollBtn.MouseButton1Click:Connect(function()
			if isRolling[gType] then return end
			local count = player:GetAttribute("SpinalFluidSyringeCount") or 0
			if count > 0 then
				isRolling[gType] = true
				Network.GachaRoll:FireServer(gType, true)
			else
				ResultLbl.Text = "<font color='#FF5555'>Not enough items!</font>"
				EffectsManager.PlaySFX("Error", 1)
				task.delay(1.5, function() if not isRolling[gType] then ResultLbl.Text = "Current: " .. (player:GetAttribute(gType) or "None") end end)
			end
		end)

		AutoRollBtn.MouseButton1Click:Connect(function()
			if isRolling[gType] then return end
			local count = player:GetAttribute(attrReq) or 0
			if count > 0 then
				isRolling[gType] = true
				ResultLbl.Text = "<i>Auto-Rolling...</i>"
				Network.GachaRollAuto:FireServer(gType)
			else
				ResultLbl.Text = "<font color='#FF5555'>Not enough items!</font>"
				EffectsManager.PlaySFX("Error", 1)
				task.delay(1.5, function() if not isRolling[gType] then ResultLbl.Text = "Current: " .. (player:GetAttribute(gType) or "None") end end)
			end
		end)

		return ResultLbl, PityLbl, RollBtn, PremiumRollBtn, AutoRollBtn, storageBtns
	end

	local tResult, tPity, tRoll, tPrem, tAuto, tStores = CreateGachaPanel("Titan", 0.01)
	local cResult, cPity, cRoll, cPrem, cAuto, cStores = CreateGachaPanel("Clan", 0.51)

	local function UpdateUI()
		if not isRolling.Titan then tResult.Text = "Current: " .. (player:GetAttribute("Titan") or "None") end
		if not isRolling.Clan then cResult.Text = "Current: " .. (player:GetAttribute("Clan") or "None") end

		for i = 1, 6 do
			local tStoreName = player:GetAttribute("Titan_Slot"..i) or "None"
			local cStoreName = player:GetAttribute("Clan_Slot"..i) or "None"

			local tBtn = tStores[i]
			if i > 3 and not player:GetAttribute("HasTitanVault") then tBtn.Text = "🔒"; tBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20); tBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
			else tBtn.Text = (tStoreName == "None" and "Empty" or tStoreName); tBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); tBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end

			local cBtn = cStores[i]
			if i > 3 and not player:GetAttribute("HasClanVault") then cBtn.Text = "🔒"; cBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20); cBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
			else cBtn.Text = (cStoreName == "None" and "Empty" or cStoreName); cBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); cBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end
		end

		tPity.Text = "PITY: " .. (player:GetAttribute("TitanPity") or 0) .. " / 100"
		cPity.Text = "PITY: " .. (player:GetAttribute("ClanPity") or 0) .. " / 100"

		tRoll.Text = "ROLL (1x Serum)\nOwned: " .. (player:GetAttribute("StandardTitanSerumCount") or 0)
		tPrem.Text = "PREMIUM (1x Syringe)\nOwned: " .. (player:GetAttribute("SpinalFluidSyringeCount") or 0)

		cRoll.Text = "ROLL (1x Vial)\nOwned: " .. (player:GetAttribute("ClanBloodVialCount") or 0)
	end

	player.AttributeChanged:Connect(UpdateUI)
	UpdateUI()

	Network.GachaResult.OnClientEvent:Connect(function(gType, resultName, resultRarity)
		local targetLbl = (gType == "Titan") and tResult or cResult
		local names = {}
		if gType == "Titan" then for tName, _ in pairs(TitanData.Titans) do table.insert(names, tName) end
		else for cName, _ in pairs(TitanData.ClanWeights) do table.insert(names, cName) end end

		-- THE FIX: Plays the Spin Sound with pitch modulation!
		for i = 1, 20 do 
			EffectsManager.PlaySFX("Spin", 1 + (i/25)) 
			targetLbl.Text = names[math.random(1, #names)]
			task.wait(0.05) 
		end

		local cColor = RarityColors[resultRarity] or "#FFFFFF"
		targetLbl.Text = "<b><font color='" .. cColor .. "'>" .. resultName:upper() .. "!</font></b>"

		-- THE FIX: Plays the massive Reveal Sound!
		EffectsManager.PlaySFX("Reveal", 1)

		task.wait(1.5); isRolling[gType] = false; UpdateUI()
	end)
end

function InheritTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return InheritTab