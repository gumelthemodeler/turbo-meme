-- @ScriptType: ModuleScript
local TradingTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local NotificationManager = require(script.Parent:WaitForChild("NotificationManager"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local topCard, bottomCard, activeTradeCard
local reqView, hostView, browserLobbyView, browserInboxView
local requestsEnabled = true
local isHosting = false

local forceTabFocus

local myOfferGrid, oppOfferGrid, myInvList, myStandList, myStyleList
local myYenLbl, oppYenLbl, tradeStatusLbl
local addYenInput, lockBtn, confirmBtn
local claimModal, claimContainer, claimTitle
local btnActive, btnSlot1, btnSlot2, btnSlot3, btnSlot4, btnSlot5

local styleClaimModal, styleClaimContainer, styleClaimTitle
local btnStyleActive, btnStyleSlot1, btnStyleSlot2, btnStyleSlot3

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5, Unique = 6 }

local KnownItems = {"Any / Offers"}

for itemName, data in pairs(ItemData.Consumables) do 
	table.insert(KnownItems, itemName) 
end
for eqName, data in pairs(ItemData.Equipment) do 
	table.insert(KnownItems, eqName) 
end

table.sort(KnownItems, function(a, b)
	if a == "Any / Offers" then return true end
	if b == "Any / Offers" then return false end

	local dataA = ItemData.Consumables[a] or ItemData.Equipment[a]
	local dataB = ItemData.Consumables[b] or ItemData.Equipment[b]
	local rA = dataA and dataA.Rarity or "Common"
	local rB = dataB and dataB.Rarity or "Common"
	local orderA = rarityOrder[rA] or 1
	local orderB = rarityOrder[rB] or 1

	if orderA == orderB then return a < b else return orderA < orderB end
end)

local function InitDropdown(frame, getOptionsFunc)
	local mainBtn = frame:WaitForChild("MainBtn")
	local listFrame = frame:WaitForChild("ListFrame")
	local template = uiTemplates:WaitForChild("DropdownItemTemplate")

	local selectedValue = ""

	mainBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		listFrame.Visible = not listFrame.Visible
		if listFrame.Visible then
			for _, c in pairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local options = getOptionsFunc()

			if #options == 0 then
				local empty = template:Clone()
				empty.Text = "No options available"
				empty.TextColor3 = Color3.fromRGB(150, 150, 150)
				empty.Parent = listFrame
				return
			end

			for i, opt in ipairs(options) do
				local btn = template:Clone()
				btn.BackgroundTransparency = (i%2==0) and 0.5 or 1
				btn.Text = opt
				btn.Parent = listFrame

				btn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					selectedValue = opt
					mainBtn.Text = opt
					listFrame.Visible = false
				end)
			end
		end
	end)

	return function() return selectedValue end, function(txt) mainBtn.Text = txt; selectedValue = "" end
end

local function InitMultiSelectGrid(frame, defaultText, itemsList)
	local mainBtn = frame:WaitForChild("MainBtn")
	local listFrame = frame:WaitForChild("ListFrame")
	local template = uiTemplates:WaitForChild("MultiSelectItemTemplate")

	local selectedItems = {}

	local function UpdateMainText()
		if #selectedItems == 0 then mainBtn.Text = defaultText else mainBtn.Text = table.concat(selectedItems, ", ") end
	end

	mainBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); listFrame.Visible = not listFrame.Visible end)

	for _, itemName in ipairs(itemsList) do
		local btn = template:Clone()
		btn.Text = itemName
		btn.Parent = listFrame

		local iStroke = btn:WaitForChild("UIStroke")
		if itemName == "Any / Offers" then 
			iStroke.Color = Color3.fromRGB(255, 255, 255) 
		else
			local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
			local rarity = iData and iData.Rarity or "Common"
			iStroke.Color = rarityColors[rarity] or rarityColors.Common
		end

		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")

			if itemName == "Any / Offers" then
				selectedItems = {}
				for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 20, 40) end end
				listFrame.Visible = false
			else
				local idx = table.find(selectedItems, itemName)
				if idx then
					table.remove(selectedItems, idx)
					btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
				elseif #selectedItems < 3 then
					table.insert(selectedItems, itemName)
					btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				end
			end
			UpdateMainText()
		end)
	end

	return function() 
		if #selectedItems == 0 then return defaultText end return table.concat(selectedItems, ", ") 
	end, function()
		selectedItems = {}
		for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 20, 40) end end
		UpdateMainText()
	end
end

local function DrawTradeItems(container, itemsTable, standData, styleData, isMyOffer)
	for _, c in pairs(container:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	local btnTemplate = uiTemplates:WaitForChild("TradeItemBtnTemplate")

	for itemName, count in pairs(itemsTable) do
		local btn = btnTemplate:Clone()
		btn.Text = itemName .. (count > 1 and " (x"..count..")" or "")
		btn.Parent = container

		local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
		local rarity = iData and iData.Rarity or "Common"
		local stroke = btn:WaitForChild("UIStroke")
		stroke.Color = rarityColors[rarity] or rarityColors.Common

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveItem", itemName)
			end)
		end
	end

	if standData then
		local btn = btnTemplate:Clone()
		btn.BackgroundColor3 = Color3.fromRGB(50, 15, 60)
		btn.RichText = true

		local tColor = StandData.Traits[standData.Trait] and StandData.Traits[standData.Trait].Color or "#FFFFFF"
		local tStr = standData.Trait ~= "None" and " <font color='"..tColor.."'>["..standData.Trait.."]</font>" or ""
		btn.Text = "<b>[STAND]</b>\n" .. standData.Name .. tStr
		btn.Parent = container

		local stroke = btn:WaitForChild("UIStroke")
		stroke.Color = Color3.fromRGB(200, 50, 255)
		stroke.Thickness = 2

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveStand")
			end)
		end
	end

	if styleData then
		local btn = btnTemplate:Clone()
		btn.BackgroundColor3 = Color3.fromRGB(80, 40, 15)
		btn.RichText = true
		btn.Text = "<b>[STYLE]</b>\n" .. styleData.Name
		btn.Parent = container

		local stroke = btn:WaitForChild("UIStroke")
		stroke.Color = Color3.fromRGB(255, 140, 0)
		stroke.Thickness = 2

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveStyle")
			end)
		end
	end
end

function TradingTab.Init(parentFrame, tooltipMgr, focusFunc)
	forceTabFocus = focusFunc

	local mainScroll = parentFrame:WaitForChild("MainScroll")

	topCard = mainScroll:WaitForChild("TopCard")
	local toggleReqsBtn = topCard:WaitForChild("ToggleReqsBtn")

	toggleReqsBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		requestsEnabled = not requestsEnabled
		toggleReqsBtn.Text = requestsEnabled and "Requests: ON" or "Requests: OFF"
		toggleReqsBtn.BackgroundColor3 = requestsEnabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(140, 40, 40)
		Network.TradeAction:FireServer("ToggleRequests", requestsEnabled)
	end)

	local actNav = topCard:WaitForChild("ActNav")
	local tabReqBtn = actNav:WaitForChild("TabReqBtn")
	local tabHostBtn = actNav:WaitForChild("TabHostBtn")

	reqView = topCard:WaitForChild("ReqView")
	hostView = topCard:WaitForChild("HostView")

	tabReqBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); reqView.Visible = true; hostView.Visible = false
		tabReqBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabReqBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabReqBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(255, 215, 0)
		tabHostBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabHostBtn.TextColor3 = Color3.new(1, 1, 1)
		tabHostBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
	end)

	tabHostBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); reqView.Visible = false; hostView.Visible = true
		tabHostBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabHostBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabHostBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(255, 215, 0)
		tabReqBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabReqBtn.TextColor3 = Color3.new(1, 1, 1)
		tabReqBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
	end)

	local reqDropdownObj = reqView:WaitForChild("ReqDropdown")
	local getReqVal, resetReqVal = InitDropdown(reqDropdownObj, function()
		local list = {}
		for _, p in ipairs(game.Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end
		return list
	end)

	local sendReqBtn = reqView:WaitForChild("SendReqBtn")
	sendReqBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local selected = getReqVal()
		if selected ~= "" and selected ~= "Select a Player..." then
			Network.TradeAction:FireServer("SendRequest", selected)
			resetReqVal("Select a Player...")
		end
	end)

	local lfDropdownObj = hostView:WaitForChild("LfDropdown")
	local getLfVal, resetLfVal = InitMultiSelectGrid(lfDropdownObj, "Any / Offers", KnownItems)

	local offDropdownObj = hostView:WaitForChild("OffDropdown")
	local getOffVal, resetOffVal = InitMultiSelectGrid(offDropdownObj, "Any / Open", KnownItems)

	local hostBtn = hostView:WaitForChild("HostBtn")
	hostBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if not isHosting then
			local selectedLF = getLfVal()
			if selectedLF == "" then selectedLF = "Any / Offers" end
			local selectedOff = getOffVal()
			if selectedOff == "" then selectedOff = "Any / Open" end
			Network.TradeAction:FireServer("CreateLobby", {LF = selectedLF, Offering = selectedOff})
		else
			Network.TradeAction:FireServer("CancelLobby")
		end
	end)

	bottomCard = mainScroll:WaitForChild("BottomCard")
	local browsNav = bottomCard:WaitForChild("BrowsNav")
	local tabLobbyBtn = browsNav:WaitForChild("TabLobbyBtn")
	local tabInboxBtn = browsNav:WaitForChild("TabInboxBtn")

	browserLobbyView = bottomCard:WaitForChild("BrowserLobbyView")
	browserInboxView = bottomCard:WaitForChild("BrowserInboxView")

	tabLobbyBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); browserLobbyView.Visible = true; browserInboxView.Visible = false
		tabLobbyBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabLobbyBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabLobbyBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(255, 215, 0)
		tabInboxBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabInboxBtn.TextColor3 = Color3.new(1, 1, 1)
		tabInboxBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
	end)

	tabInboxBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); browserLobbyView.Visible = false; browserInboxView.Visible = true
		tabInboxBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabInboxBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabInboxBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(255, 215, 0)
		tabLobbyBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabLobbyBtn.TextColor3 = Color3.new(1, 1, 1)
		tabLobbyBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
	end)

	activeTradeCard = mainScroll:WaitForChild("ActiveTradeCard")
	tradeStatusLbl = activeTradeCard:WaitForChild("TradeStatusLbl")
	local cancelTradeBtn = activeTradeCard:WaitForChild("CancelTradeBtn")

	local offersFrame = activeTradeCard:WaitForChild("OffersFrame")
	local mySide = offersFrame:WaitForChild("MySide")
	local oppSide = offersFrame:WaitForChild("OppSide")

	myYenLbl = mySide:WaitForChild("MyYenLbl")
	oppYenLbl = oppSide:WaitForChild("OppYenLbl")
	myOfferGrid = mySide:WaitForChild("MyOfferGrid")
	oppOfferGrid = oppSide:WaitForChild("OppOfferGrid")

	myInvList = activeTradeCard:WaitForChild("MyInvList")
	myStandList = activeTradeCard:WaitForChild("MyStandList")
	myStyleList = activeTradeCard:WaitForChild("MyStyleList")

	local ctrlFrame = activeTradeCard:WaitForChild("CtrlFrame")
	addYenInput = ctrlFrame:WaitForChild("AddYenInput")
	local setYenBtn = ctrlFrame:WaitForChild("SetYenBtn")
	lockBtn = ctrlFrame:WaitForChild("LockBtn")

	cancelTradeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("CancelTrade") end)

	setYenBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(addYenInput.Text)
		if amt and amt >= 0 then Network.TradeAction:FireServer("SetYen", math.floor(amt)) end
		addYenInput.Text = ""
	end)

	lockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ToggleLock") end)

	claimModal = parentFrame:WaitForChild("ClaimModal")
	claimContainer = claimModal:WaitForChild("ClaimContainer")
	claimTitle = claimContainer:WaitForChild("ClaimTitle")

	local claimBtnGrid = claimContainer:WaitForChild("ClaimBtnGrid")
	btnActive = claimBtnGrid:WaitForChild("BtnActive")
	btnSlot1 = claimBtnGrid:WaitForChild("BtnSlot1")
	btnSlot2 = claimBtnGrid:WaitForChild("BtnSlot2")
	btnSlot3 = claimBtnGrid:WaitForChild("BtnSlot3")
	btnSlot4 = claimBtnGrid:WaitForChild("BtnSlot4")
	btnSlot5 = claimBtnGrid:WaitForChild("BtnSlot5")

	btnActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Active") end)
	btnSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot1") end)
	btnSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot2") end)
	btnSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot3") end)
	btnSlot4.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot4") end)
	btnSlot5.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot5") end)

	styleClaimModal = parentFrame:WaitForChild("StyleClaimModal")
	styleClaimContainer = styleClaimModal:WaitForChild("StyleClaimContainer")
	styleClaimTitle = styleClaimContainer:WaitForChild("StyleClaimTitle")

	local styleClaimBtnGrid = styleClaimContainer:WaitForChild("StyleClaimBtnGrid")
	btnStyleActive = styleClaimBtnGrid:WaitForChild("BtnStyleActive")
	btnStyleSlot1 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot1")
	btnStyleSlot2 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot2")
	btnStyleSlot3 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot3")

	btnStyleActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Active") end)
	btnStyleSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot1") end)
	btnStyleSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot2") end)
	btnStyleSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot3") end)

	local function RefreshPickers()
		local btnTemplate = uiTemplates:WaitForChild("TradeItemBtnTemplate")

		for _, c in pairs(myInvList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _, itemName in ipairs(KnownItems) do
			if itemName == "Any / Offers" or itemName == "Stands" then continue end
			local count = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0

			local isEquipped = ItemData.Equipment[itemName] and player:GetAttribute("Equipped" .. ItemData.Equipment[itemName].Slot) == itemName
			local visualCount = isEquipped and (count - 1) or count

			if visualCount > 0 then
				local btn = btnTemplate:Clone()
				btn.Text = itemName .. " (x"..visualCount..")"
				btn.Parent = myInvList

				local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
				local rarity = iData and iData.Rarity or "Common"
				local stroke = btn:WaitForChild("UIStroke")
				stroke.Color = rarityColors[rarity] or rarityColors.Common

				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddItem", itemName) end)
			end
		end

		for _, c in pairs(myStandList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local function AddStandBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local btn = btnTemplate:Clone()
				btn.BackgroundColor3 = Color3.fromRGB(50, 15, 60)
				btn.Text = sName
				btn.Parent = myStandList

				local stroke = btn:WaitForChild("UIStroke")
				stroke.Color = Color3.fromRGB(200, 50, 255)

				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStand", slotId) end)
			end
		end

		AddStandBtn("Active", "Stand")
		AddStandBtn("Slot1", "StoredStand1")

		if player:GetAttribute("HasStandSlot2") then AddStandBtn("Slot2", "StoredStand2") end
		if player:GetAttribute("HasStandSlot3") then AddStandBtn("Slot3", "StoredStand3") end

		local ls = player:FindFirstChild("leaderstats")
		local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0
		if prestige >= 15 then AddStandBtn("Slot4", "StoredStand4") end
		if prestige >= 30 then AddStandBtn("Slot5", "StoredStand5") end

		for _, c in pairs(myStyleList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local function AddStyleBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local btn = btnTemplate:Clone()
				btn.BackgroundColor3 = Color3.fromRGB(80, 40, 15)
				btn.Text = sName
				btn.Parent = myStyleList

				local stroke = btn:WaitForChild("UIStroke")
				stroke.Color = Color3.fromRGB(255, 140, 0)

				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStyle", slotId) end)
			end
		end

		AddStyleBtn("Active", "FightingStyle")
		AddStyleBtn("Slot1", "StoredStyle1")
		if player:GetAttribute("HasStyleSlot2") then AddStyleBtn("Slot2", "StoredStyle2") end
		if player:GetAttribute("HasStyleSlot3") then AddStyleBtn("Slot3", "StoredStyle3") end
	end

	Network.TradeAction:FireServer("RequestData")

	Network:WaitForChild("TradeUpdate").OnClientEvent:Connect(function(action, data)
		if action == "TradeAlert" then
			NotificationManager.Show("<font color='#55FF55'>New Trade Request from " .. data .. "!</font>")

		elseif action == "ShowClaimPrompt" then
			if forceTabFocus then forceTabFocus() end 
			claimTitle.Text = "You received " .. (data.Name or "Unknown") .. "!"

			local function FormatSlotText(title, standName)
				local safeName = standName or "None"
				if safeName == "None" or safeName == "" then return title .. "\n[Empty]" end
				return title .. "\n[" .. safeName .. "]"
			end

			btnActive.Text = FormatSlotText("Active Stand", data.Active)
			btnSlot1.Text = FormatSlotText("Storage 1", data.Slot1)
			btnSlot2.Text = FormatSlotText("Storage 2", data.Slot2)
			btnSlot3.Text = FormatSlotText("Storage 3", data.Slot3)
			btnSlot4.Text = FormatSlotText("Storage 4", data.Slot4)
			btnSlot5.Text = FormatSlotText("Storage 5", data.Slot5)

			local ls = player:FindFirstChild("leaderstats")
			local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

			btnSlot2.Visible = player:GetAttribute("HasStandSlot2") == true
			btnSlot3.Visible = player:GetAttribute("HasStandSlot3") == true
			btnSlot4.Visible = prestige >= 15
			btnSlot5.Visible = prestige >= 30

			claimModal.Visible = true

		elseif action == "HideClaimPrompt" then
			claimModal.Visible = false

		elseif action == "ShowStyleClaimPrompt" then
			if forceTabFocus then forceTabFocus() end 
			styleClaimTitle.Text = "You received " .. (data.Name or "Unknown") .. "!"

			local function FormatSlotText(title, styleName)
				local safeName = styleName or "None"
				if safeName == "None" or safeName == "" then return title .. "\n[Empty]" end
				return title .. "\n[" .. safeName .. "]"
			end

			btnStyleActive.Text = FormatSlotText("Active Style", data.Active)
			btnStyleSlot1.Text = FormatSlotText("Storage 1", data.Slot1)
			btnStyleSlot2.Text = FormatSlotText("Storage 2", data.Slot2)
			btnStyleSlot3.Text = FormatSlotText("Storage 3", data.Slot3)

			btnStyleSlot2.Visible = player:GetAttribute("HasStyleSlot2") == true
			btnStyleSlot3.Visible = player:GetAttribute("HasStyleSlot3") == true

			styleClaimModal.Visible = true

		elseif action == "HideStyleClaimPrompt" then
			styleClaimModal.Visible = false

		elseif action == "LobbyStatus" then
			isHosting = data.IsHosting
			if isHosting then
				hostBtn.Text = "Cancel"; hostBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				hostBtn.Text = "Create"; hostBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			end

		elseif action == "BrowserUpdate" then
			for _, c in pairs(browserLobbyView:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			local bLobbyTemplate = uiTemplates:WaitForChild("TradeBrowserRowTemplate")

			for _, lobby in ipairs(data.Lobbies) do
				local row = bLobbyTemplate:Clone()
				row.Parent = browserLobbyView

				local txt = row:WaitForChild("InfoLabel")
				local safeLF = lobby.LF ~= "" and lobby.LF or "Any"
				local safeOff = lobby.Offering ~= "" and lobby.Offering or "Any"
				txt.Text = "<b>" .. lobby.HostName .. "</b>\n<font color='#AAAAAA'>LF: " .. safeLF .. "\nOFF: " .. safeOff .. "</font>"

				local joinBtn = row:WaitForChild("JoinBtn")

				if lobby.HostId == player.UserId then
					joinBtn.Text = "Hosting"
					joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else
					joinBtn.Text = "Join"
					joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
					joinBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("JoinLobby", lobby.HostId) end)
				end
			end

			for _, c in pairs(browserInboxView:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			local bInboxTemplate = uiTemplates:WaitForChild("TradeInboxRowTemplate")

			for _, req in ipairs(data.Requests) do
				local row = bInboxTemplate:Clone()
				row.Parent = browserInboxView

				local txt = row:WaitForChild("InfoLabel")
				txt.Text = "From: <b>" .. req.SenderName .. "</b>"

				local accBtn = row:WaitForChild("AcceptBtn")
				accBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AcceptRequest", req.SenderId) end)

				local decBtn = row:WaitForChild("DeclineBtn")
				decBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("DeclineRequest", req.SenderId) end)
			end

		elseif action == "TradeStart" then
			if forceTabFocus then forceTabFocus() end 
			topCard.Visible = false; bottomCard.Visible = false; activeTradeCard.Visible = true
			tradeStatusLbl.Text = "Trading with <b>" .. data.OpponentName .. "</b>"
			RefreshPickers()

		elseif action == "TradeUpdateState" then
			myYenLbl.Text = "Yen: ¥" .. data.Me.Yen
			oppYenLbl.Text = "Yen: ¥" .. data.Opp.Yen

			DrawTradeItems(myOfferGrid, data.Me.Items, data.Me.Stand, data.Me.Style, true)
			DrawTradeItems(oppOfferGrid, data.Opp.Items, data.Opp.Stand, data.Opp.Style, false)

			if data.Me.Confirmed and data.Opp.Confirmed then
				tradeStatusLbl.Text = "<font color='#55FF55'><b>Trade Processing...</b></font>"
				lockBtn.Text = "Processing..."; lockBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif data.Me.Locked and data.Opp.Locked then
				tradeStatusLbl.Text = "<font color='#FFFF55'><b>Both Locked! Ready to Confirm.</b></font>"
				lockBtn.Text = "Confirm Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
			elseif data.Me.Locked then
				tradeStatusLbl.Text = "<font color='#AAAAAA'>Waiting for Opponent to lock...</font>"
				lockBtn.Text = "Unlock"; lockBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
			elseif data.Opp.Locked then
				tradeStatusLbl.Text = "<font color='#FFFF55'>Opponent Locked! Lock to proceed.</font>"
				lockBtn.Text = "Lock In Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
			else
				tradeStatusLbl.Text = "Trading with <b>" .. data.OpponentName .. "</b>"
				lockBtn.Text = "Lock In Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
			end

		elseif action == "TradeEnd" then
			topCard.Visible = true; bottomCard.Visible = true; activeTradeCard.Visible = false
			Network.TradeAction:FireServer("RequestData")
		end
	end)
end

return TradingTab