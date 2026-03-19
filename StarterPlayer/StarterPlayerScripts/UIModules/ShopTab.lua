-- @ScriptType: ModuleScript
local ShopTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local MarketplaceService = game:GetService("MarketplaceService")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local PREMIUM_RESTOCK_PRODUCT_ID = 3548843760

local shopContainer, timerLabel, yenLabel
local giftModal, giftContainer, giftTitle, giftList
local cachedTooltipMgr = nil

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50)
}

local premiumItems = {
	{ Type = "Product", Id = 3553771635, Name = "Saint's Corpse Part (x10)", Price = 400, Desc = "<b><font color='#FFD700'>Saint's Corpse Part (x10)</font></b>\nGives you <font color='#55FF55'>x10 Saint's Corpse Parts</font>, to roll for Part 7 stands." },
	{ Type = "Product", Id = 3550862625, Name = "Stand Arrow (x25)", Price = 250, Desc = "<b><font color='#FFD700'>Stand Arrow (x25)</font></b>\nGives you <font color='#55FF55'>x25 Stand Arrows</font>, to roll for Part 1-6 stands." },
	{ Type = "Product", Id = 3550862858, Name = "Rokakaka (x5)", Price = 100, Desc = "<b><font color='#FFD700'>Rokakaka (x5)</font></b>\nGives you <font color='#55FF55'>x5 Rokakakas</font>, to roll for stand traits." },

	{ Type = "Product", Id = 3553767064, Name = "Johnny Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Johnny Bundle</font></b>\nGives <b>Tusk Act 1</b> <font color='#FF55FF'>[Mythical Trait: Cheerful]</font>, Saint's Left Arm, and Saint's Right Eye." },
	{ Type = "Product", Id = 3547646706, Name = "DIO Pack", Price = 1500, Desc = "<b><font color='#FFD700'>DIO Bundle</font></b>\nGives <b>The World</b> <font color='#FF55FF'>[Mythical Trait: Vampiric]</font>, Vampire Cape, Vampire Style, and Dio's Throwing Knives." },
	{ Type = "Product", Id = 3550839948, Name = "Pucci Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Pucci Bundle</font></b>\nGives <b>Whitesnake</b> <font color='#FF55FF'>[Mythical Trait: Blessed]</font>, Green Baby, and Dio's Diary." },
	{ Type = "Product", Id = 3547646703, Name = "Jotaro Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Jotaro Bundle</font></b>\nGives <b>Star Platinum</b> <font color='#FF55FF'>[Mythical Trait: Overwhelming]</font>, Jotaro's Hat, and Dio's Diary." },

	{ Type = "Product", Id = 3553764779, Name = "Spin Pack", Price = 200, Desc = "<b><font color='#FFD700'>Spin Bundle</font></b>\nGives <font color='#5FE625'>Spin Style</font> and Saint's Right Eye." },
	{ Type = "Product", Id = 3548207626, Name = "Hamon Pack", Price = 200, Desc = "<b><font color='#FFD700'>Hamon Bundle</font></b>\nGives <font color='#FF8855'>Hamon Style</font>, Hamon Clackers, and Breathing Mask." },
	{ Type = "Product", Id = 3548207336, Name = "Vampire Pack", Price = 200, Desc = "<b><font color='#FFD700'>Vampire Bundle</font></b>\nGives <font color='#AA00AA'>Vampire Style</font> and Vampire Cape." },
	{ Type = "Product", Id = 3548207175, Name = "Pillarman Pack", Price = 200, Desc = "<b><font color='#FFD700'>Pillarman Bundle</font></b>\nGives <font color='#FF5555'>Pillarman Style</font> and Red Stone of Aja." },

	{ Type = "Pass", Id = 1731694181, GiftId = 3552102461, Name = "2x Speed", Price = 200, Desc = "<b><font color='#55FFFF'>2x Battle Speed</font></b>\nBattles play out <font color='#55FF55'>twice as fast!</font>", Attr = "Has2xBattleSpeed" },
	{ Type = "Pass", Id = 1732900742, GiftId = 3552102647, Name = "2x Inventory", Price = 100, Desc = "<b><font color='#55FFFF'>2x Inventory Space</font></b>\nIncreases inventory space from <font color='#FF5555'>15</font> to <font color='#55FF55'>30</font>.", Attr = "Has2xInventory" },
	{ Type = "Pass", Id = 1732842877, GiftId = 3552103016, Name = "2x Drops", Price = 400, Desc = "<b><font color='#55FFFF'>2x Drop Chance</font></b>\n<font color='#55FF55'>Doubles</font> the chance of an enemy dropping an item.", Attr = "Has2xDropChance" },
	{ Type = "Pass", Id = 1749484465, GiftId = 3557500443, Name = "Auto-Roll", Price = 400, Desc = "<b><font color='#55FFFF'>Auto-Roll</font></b>\nInstantly rolls batches of Arrows and Rokas until you get your desired Stand/Trait!", Attr = "HasAutoRoll" },
	{ Type = "Pass", Id = 1733160695, GiftId = 3552103567, Name = "Stand Slot 2", Price = 150, Desc = "<b><font color='#55FFFF'>Stand Storage 2</font></b>\nUnlocks the <font color='#FFD700'>second</font> stand storage slot.", Attr = "HasStandSlot2" },
	{ Type = "Pass", Id = 1732844091, GiftId = 3552103754, Name = "Stand Slot 3", Price = 300, Desc = "<b><font color='#55FFFF'>Stand Storage 3</font></b>\nUnlocks the <font color='#FFD700'>third</font> stand storage slot.", Attr = "HasStandSlot3" },
	{ Type = "Pass", Id = 1746853452, GiftId = 3554936785, Name = "Style Slot 2", Price = 50, Desc = "<b><font color='#FF8C00'>Style Storage 2</font></b>\nUnlocks the <font color='#55FF55'>second</font> style storage slot.", Attr = "HasStyleSlot2" },
	{ Type = "Pass", Id = 1745969849, GiftId = 3554936823, Name = "Style Slot 3", Price = 100, Desc = "<b><font color='#FF8C00'>Style Storage 3</font></b>\nUnlocks the <font color='#55FF55'>third</font> style storage slot.", Attr = "HasStyleSlot3" },
	{ Type = "Pass", Id = 1732129582, GiftId = 3552103397, Name = "Auto Train", Price = 40, Desc = "<b><font color='#55FFFF'>Auto Training</font></b>\nAutomatically starts training when you join the game!", Attr = "HasAutoTraining" },
	{ Type = "Pass", Id = 1749586333, GiftId = 3557535781, Name = "Custom Horse Name", Price = 40, Desc = "<b><font color='#55FFFF'>Custom Horse Name</font></b>\nUnlock the ability to <font color='#55FF55'>choose your horse's name</font> from the available lists!", Attr = "HasHorseNamePass" },

}

local function FormatTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

function ShopTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	giftModal = parentFrame:WaitForChild("GiftModal")
	giftContainer = giftModal:WaitForChild("GiftContainer")
	giftTitle = giftContainer:WaitForChild("GiftTitle")

	local closeGiftBtn = giftContainer:WaitForChild("CloseGiftBtn")
	closeGiftBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); giftModal.Visible = false end)

	giftList = giftContainer:WaitForChild("GiftList")

	local function OpenGiftModal(pInfo)
		giftTitle.Text = "Gift: " .. pInfo.Name
		for _, c in pairs(giftList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

		local playersFound = false
		local giftTemplate = uiTemplates:WaitForChild("PlayerGiftTemplate")

		if pInfo.Type == "Pass" then
			local selfBtn = giftTemplate:Clone()
			selfBtn.Text = "Buy as Tradable Item"
			selfBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
			selfBtn.Parent = giftList

			selfBtn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				giftModal.Visible = false
				Network.ShopAction:FireServer("SetGiftTarget", -1) 
				task.wait(0.1)
				MarketplaceService:PromptProductPurchase(player, pInfo.GiftId)
			end)
		end

		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= player then
				if pInfo.Type == "Pass" and pInfo.Attr and p:GetAttribute(pInfo.Attr) == true then
					continue
				end

				playersFound = true
				local btn = giftTemplate:Clone()
				btn.Text = "Gift to: " .. p.Name
				btn.Parent = giftList

				btn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					giftModal.Visible = false
					Network.ShopAction:FireServer("SetGiftTarget", p.UserId)
					task.wait(0.1)

					if pInfo.Type == "Pass" then
						MarketplaceService:PromptProductPurchase(player, pInfo.GiftId)
					else
						MarketplaceService:PromptProductPurchase(player, pInfo.Id)
					end
				end)
			end
		end

		if not playersFound and pInfo.Type ~= "Pass" then
			local empty = giftTemplate:Clone()
			empty.Text = "No eligible players found!"
			empty.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			empty.Parent = giftList
		end

		giftModal.Visible = true
	end

	local mainScroll = parentFrame:WaitForChild("MainScroll")
	local mainList = mainScroll:WaitForChild("MainList")

	local infoCard = mainScroll:WaitForChild("InfoCard")
	timerLabel = infoCard:WaitForChild("TimerLabel")
	yenLabel = infoCard:WaitForChild("YenLabel")

	local restockBtn = infoCard:WaitForChild("RestockBtn")
	restockBtn.MouseButton1Click:Connect(function()
		pcall(function() SFXManager.Play("Click") end)
		Network.ShopAction:FireServer("SetGiftTarget", 0)
		task.wait(0.1)
		MarketplaceService:PromptProductPurchase(player, PREMIUM_RESTOCK_PRODUCT_ID)
	end)

	local yenRestockBtn = infoCard:WaitForChild("YenRestockBtn")
	yenRestockBtn.MouseButton1Click:Connect(function()
		pcall(function() SFXManager.Play("Click") end)
		Network.ShopAction:FireServer("RestockYen")
	end)

	local stockCard = mainScroll:WaitForChild("StockCard")
	shopContainer = stockCard:WaitForChild("ShopContainer")

	local ratesCard = mainScroll:WaitForChild("RatesCard")
	local rSplitFrame = ratesCard:WaitForChild("RSplitFrame")
	local standRatesScroll = rSplitFrame:WaitForChild("StandRatesScroll")
	local standRatesCol = standRatesScroll:WaitForChild("StandRatesCol")
	local traitRatesScroll = rSplitFrame:WaitForChild("TraitRatesScroll")
	local traitRatesCol = traitRatesScroll:WaitForChild("TraitRatesCol")

	local function RefreshDropRatesText()
		local currentStand = player:GetAttribute("Stand") or "None"
		local currentTrait = player:GetAttribute("StandTrait") or "None"

		local function BuildPoolString(dataTable, isTrait, currentEquipped)
			local pools = { Common = {}, Uncommon = {}, Rare = {}, Legendary = {}, Mythical = {}, Evolution = {}, Boss = {} }

			local rates = {}
			if isTrait then
				rates = { Common = "35%", Rare = "16%", Legendary = "6%", Mythical = "1%" }
			else
				rates = { Common = "50%", Uncommon = "30%", Rare = "15%", Legendary = "5%", Mythical = "1% WORLD BOSS DROP ONLY" }
			end

			for name, data in pairs(dataTable) do
				if pools[data.Rarity] then table.insert(pools[data.Rarity], name) end
			end

			local str = ""
			local order = {"Common", "Uncommon", "Rare", "Legendary", "Mythical"}
			local hexes = { Common = "#AAAAAA", Uncommon = "#55FF55", Rare = "#55FFFF", Legendary = "#FFD700", Mythical = "#FF55FF" }

			for _, rarity in ipairs(order) do
				if #pools[rarity] > 0 and rates[rarity] then
					table.sort(pools[rarity])
					str = str .. "<b><font color='"..hexes[rarity].."'>"..rarity.." ("..rates[rarity]..")</font></b>\n"
					local formattedNames = {}
					for _, name in ipairs(pools[rarity]) do
						if name == currentEquipped then table.insert(formattedNames, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
						else table.insert(formattedNames, name) end
					end
					str = str .. table.concat(formattedNames, ", ") .. "\n\n"
				end
			end

			if not isTrait and #pools["Evolution"] > 0 then
				table.sort(pools["Evolution"])
				str = str .. "<b><font color='#AA00AA'>Evolution</font></b>\n"
				local formattedEvos = {}
				for _, name in ipairs(pools["Evolution"]) do
					if name == currentEquipped then table.insert(formattedEvos, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
					else table.insert(formattedEvos, name) end
				end
				str = str .. table.concat(formattedEvos, ", ") .. "\n\n"
			end
			return str
		end

		standRatesCol.Text = "<b><font size='14'>STAND ARROW RATES</font></b>\n<i><font color='#888888'>Guarantees Rare+ every 25 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Stands, false, currentStand)
		traitRatesCol.Text = "<b><font size='14'>ROKAKAKA RATES</font></b>\n<i><font color='#888888'>Guarantees Legendary+ every 5 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Traits, true, currentTrait)
	end

	player:GetAttributeChangedSignal("Stand"):Connect(RefreshDropRatesText)
	player:GetAttributeChangedSignal("StandTrait"):Connect(RefreshDropRatesText)
	RefreshDropRatesText()

	local robuxCard = mainScroll:WaitForChild("RobuxCard")
	local leftCol = robuxCard:WaitForChild("LeftCol")
	local rightCol = robuxCard:WaitForChild("RightCol")

	local premLabels = {}
	local premTemplate = uiTemplates:WaitForChild("PremItemTemplate")

	for _, pInfo in ipairs(premiumItems) do
		local isPass = (pInfo.Type == "Pass")
		local targetCol = isPass and leftCol or rightCol

		local row = premTemplate:Clone()
		row.Parent = targetCol

		local nLbl = row:WaitForChild("NameLabel")
		nLbl.Text = pInfo.Name

		local dLbl = row:WaitForChild("DescLabel")
		dLbl.Text = pInfo.Desc

		local giftBtn = row:WaitForChild("GiftBtn")
		local rBtn = row:WaitForChild("BuyBtn")
		rBtn.Text = tostring(pInfo.Price) .. " R$"

		if pInfo.Type == "Product" or pInfo.GiftId then
			giftBtn.Visible = true
			giftBtn.Size = UDim2.new(0.43, 0, 0, 28)
			giftBtn.Position = UDim2.new(0.05, 0, 1, -38)

			rBtn.Size = UDim2.new(0.45, 0, 0, 28)
			rBtn.Position = UDim2.new(0.5, 0, 1, -38)
		else
			giftBtn.Visible = false
			rBtn.Size = UDim2.new(0.9, 0, 0, 28)
			rBtn.Position = UDim2.new(0.05, 0, 1, -38)
		end

		giftBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			OpenGiftModal(pInfo)
		end)

		rBtn.MouseButton1Click:Connect(function()
			if pInfo.Attr and player:GetAttribute(pInfo.Attr) then return end 
			SFXManager.Play("Click")

			Network.ShopAction:FireServer("SetGiftTarget", 0)
			task.wait(0.1) 

			if isPass then 
				MarketplaceService:PromptGamePassPurchase(player, pInfo.Id)
			else 
				MarketplaceService:PromptProductPurchase(player, pInfo.Id) 
			end
		end)

		if pInfo.Attr then premLabels[pInfo.Attr] = {Btn = rBtn, Price = pInfo.Price} end
	end

	local codesCard = mainScroll:WaitForChild("CodesCard")
	local codeInput = codesCard:WaitForChild("CodeInput")
	local redeemBtn = codesCard:WaitForChild("RedeemBtn")

	redeemBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if codeInput.Text ~= "" then
			Network.RedeemCode:FireServer(codeInput.Text)
			codeInput.Text = ""
		end
	end)

	local function UpdateRobuxUI()
		for attrName, data in pairs(premLabels) do
			if player:GetAttribute(attrName) then
				data.Btn.Text = "OWNED"
				data.Btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				data.Btn.Text = tostring(data.Price) .. " R$"
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
			end
		end
	end

	for attrName, _ in pairs(premLabels) do
		player:GetAttributeChangedSignal(attrName):Connect(UpdateRobuxUI)
	end
	UpdateRobuxUI()

	local shopItemTemplate = uiTemplates:WaitForChild("ShopItemTemplate")

	local function RefreshShopItems(stockStr)
		for _, child in pairs(shopContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		if not stockStr or stockStr == "" then return end

		local stockData = {}
		if string.sub(stockStr, 1, 1) == "[" then
			local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(stockStr) end)
			if success and decoded then stockData = decoded end
		else
			local items = string.split(stockStr, ",")
			for _, name in ipairs(items) do
				if name ~= "" then
					local data = ItemData.Equipment[name] or ItemData.Consumables[name]
					if data then
						table.insert(stockData, {
							Name = name,
							Cost = data.Cost or data.Price or 50,
							Rarity = data.Rarity or "Common",
							IsEquipment = (ItemData.Equipment[name] ~= nil)
						})
					end
				end
			end
		end

		for _, item in ipairs(stockData) do
			local itemFrame = shopItemTemplate:Clone()
			itemFrame.Parent = shopContainer

			local itemStroke = itemFrame:WaitForChild("UIStroke")
			itemStroke.Color = rarityColors[item.Rarity or "Common"]

			itemFrame.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(item.Name)) end)
			itemFrame.MouseLeave:Connect(cachedTooltipMgr.Hide)

			local nameLabel = itemFrame:WaitForChild("NameLabel")
			nameLabel.Text = item.Name .. " - <font color='#55FF55'>¥" .. (item.Cost or 0) .. "</font>"

			local buyBtn = itemFrame:WaitForChild("BuyBtn")
			buyBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click")
				Network.ShopAction:FireServer("Buy", item.Name) 
			end)
		end
	end

	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Refresh" then 
			RefreshShopItems(table.concat(data, ",")) 
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(passPlayer, passId, wasPurchased)
		if passPlayer == player and wasPurchased then 
			SFXManager.Play("BuyPass") 
			for _, pItem in ipairs(premiumItems) do
				if pItem.Id == passId and pItem.Attr then
					player:SetAttribute(pItem.Attr, true)
				end
			end
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if userId == player.UserId and wasPurchased then SFXManager.Play("BuyPass") end
	end)

	player:GetAttributeChangedSignal("ShopStock"):Connect(function() RefreshShopItems(player:GetAttribute("ShopStock")) end)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 5)
		if leaderstats then
			local yen = leaderstats:WaitForChild("Yen", 5)
			if yen then
				yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. yen.Value .. "</font>"
				yen.Changed:Connect(function(val) yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. val .. "</font>" end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local rt = player:GetAttribute("ShopRefreshTime") or 0
			local remain = rt - os.time()
			if remain > 0 then
				timerLabel.Text = "Restocks in: " .. FormatTime(remain)
			else
				timerLabel.Text = "Restocking..."
			end
		end
	end)

	task.delay(1, function() RefreshShopItems(player:GetAttribute("ShopStock")) end)
end

return ShopTab