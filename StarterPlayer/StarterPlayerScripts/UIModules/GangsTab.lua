-- @ScriptType: ModuleScript
local GangsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local mainContainer, createContainer, activeContainer, pagesContainer
local infoPage, upgPage, ordPage
local titleLabel, mottoLabel, emblemImage, repLabel, treasuryLabel, levelLabel, joinModeBtn
local membersList, browserList, requestsList, buildingScroll, ordersScroll
local membersCard, requestsCard, settingsCard
local leaveBtn, boostsBtn, donateInput, donateBtn, ordersTimerLbl
local reqInput, reqBtn

local pendingLeave = false
local currentBoostText = "Loading boosts..."
local cachedTooltipMgr = nil
local lastOrderResetTime = 0

local activeUpgradeFinishTime = 0
local activeUpgradeBtnRef = nil

local RolePower = { ["Grunt"] = 1, ["Caporegime"] = 2, ["Consigliere"] = 3, ["Boss"] = 4 }
local RoleColors = { ["Grunt"] = "#AAAAAA", ["Caporegime"] = "#55FF55", ["Consigliere"] = "#FF55FF", ["Boss"] = "#FFD700" }

local function GetGangLevel(rep)
	if rep >= 100000 then return 5 end
	if rep >= 50000 then return 4 end
	if rep >= 10000 then return 3 end
	if rep >= 5000 then return 2 end
	if rep >= 1000 then return 1 end
	return 0
end

local function GetBoostText(buildings)
	local b = buildings or {}
	local v = b.Vault or 0
	local d = b.Dojo or 0
	local m = b.Market or 0
	local s = b.Shrine or 0
	local a = b.Armory or 0

	return "<b><font color='#FFD700'>GANG BUILDING BOOSTS</font></b>\n____________________\n\n" ..
		"<font color='#55FF55'>Vault (Lv."..v.."): +"..(v*5).."% Yen</font>\n" ..
		"<font color='#55FFFF'>Training Hall (Lv."..d.."): +"..(d*5).."% XP</font>\n" ..
		"<font color='#AA00AA'>Black Market (Lv."..m.."): +"..(m*5).." Inv Slots</font>\n" ..
		"<font color='#FFD700'>Saint's Church (Lv."..s.."): +"..(s).." Luck</font>\n" ..
		"<font color='#FF5555'>Armory (Lv."..a.."): +"..(a*5).."% Damage</font>"
end

local function FormatTimeAgo(timestamp)
	if not timestamp then return "<font color='#AAAAAA'>Offline: Unknown</font>" end
	local diff = os.time() - timestamp
	if diff < 300 then return "<font color='#55FF55'>Online</font>" end 
	if diff < 3600 then return "<font color='#AAAAAA'>Offline: " .. math.floor(diff / 60) .. "m</font>"
	elseif diff < 86400 then return "<font color='#AAAAAA'>Offline: " .. math.floor(diff / 3600) .. "h</font>"
	else
		local days = math.floor(diff / 86400)
		local color = days >= 3 and "#FF5555" or "#AAAAAA" 
		return "<font color='" .. color .. "'>Offline: " .. days .. "d</font>"
	end
end

local function FormatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function FormatPlayTime(seconds)
	local s = tonumber(seconds) or 0
	local hours = math.floor(s / 3600)
	local mins = math.floor((s % 3600) / 60)
	return hours .. "h " .. mins .. "m"
end

function GangsTab.Init(parentFrame, tooltipMgr)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr

	createContainer = mainContainer:WaitForChild("CreateContainer")
	local createCard = createContainer:WaitForChild("CreateCard")
	local nameInput = createCard:WaitForChild("NameInput")
	local createBtn = createCard:WaitForChild("CreateBtn")

	createBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if nameInput.Text and string.len(nameInput.Text) >= 3 then Network.GangAction:FireServer("Create", nameInput.Text) end
	end)

	local browseCard = createContainer:WaitForChild("BrowseCard")
	local refreshBtn = browseCard:WaitForChild("RefreshBtn")
	local searchBtn = browseCard:WaitForChild("SearchBtn")
	local searchInput = browseCard:WaitForChild("SearchInput")
	browserList = browseCard:WaitForChild("BrowserList")

	refreshBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("BrowseGangs") end)
	searchBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if searchInput.Text and string.len(searchInput.Text) >= 3 then Network.GangAction:FireServer("SearchGang", searchInput.Text) end
	end)

	activeContainer = mainContainer:WaitForChild("ActiveContainer")
	local tabContainer = activeContainer:WaitForChild("TabContainer")
	pagesContainer = activeContainer:WaitForChild("PagesContainer")

	infoPage = pagesContainer:WaitForChild("InfoPage")
	upgPage = pagesContainer:WaitForChild("UpgradesPage")
	ordPage = pagesContainer:WaitForChild("OrdersPage")

	local function SwitchTab(tabName)
		SFXManager.Play("Click")
		infoPage.Visible = (tabName == "Info")
		upgPage.Visible = (tabName == "Upgrades")
		ordPage.Visible = (tabName == "Orders")

		for _, btn in ipairs(tabContainer:GetChildren()) do
			if btn:IsA("TextButton") then
				local isMatched = (btn.Name == tabName .. "TabBtn")
				btn.BackgroundColor3 = isMatched and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
				btn.TextColor3 = isMatched and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
			end
		end
	end

	tabContainer:WaitForChild("InfoTabBtn").MouseButton1Click:Connect(function() SwitchTab("Info") end)
	tabContainer:WaitForChild("UpgradesTabBtn").MouseButton1Click:Connect(function() SwitchTab("Upgrades") end)
	tabContainer:WaitForChild("OrdersTabBtn").MouseButton1Click:Connect(function() SwitchTab("Orders") end)
	SwitchTab("Info")

	local infoCard = infoPage:WaitForChild("InfoCard")

	-- Bind with recursive search to find elements inside our new grouped frames
	titleLabel = infoCard:FindFirstChild("TitleLabel", true)
	mottoLabel = infoCard:FindFirstChild("MottoLabel", true)
	emblemImage = infoCard:FindFirstChild("EmblemImage", true)
	repLabel = infoCard:FindFirstChild("RepLabel", true)

	local levelContainer = infoCard:WaitForChild("LevelContainer")
	levelLabel = levelContainer:WaitForChild("LevelLabel")
	boostsBtn = levelContainer:WaitForChild("BoostsBtn")

	local donationCard = upgPage:WaitForChild("DonationCard")
	treasuryLabel = donationCard:WaitForChild("TreasuryLabel")
	donateInput = donationCard:WaitForChild("DonateInput")
	donateBtn = donationCard:WaitForChild("DonateBtn")
	buildingScroll = upgPage:WaitForChild("BuildingScroll")

	ordersScroll = ordPage:WaitForChild("OrdersScroll")
	ordersTimerLbl = ordPage:WaitForChild("OrdersTimerLbl")

	boostsBtn.MouseEnter:Connect(function() if tooltipMgr and tooltipMgr.Show then tooltipMgr.Show(currentBoostText) end end)
	boostsBtn.MouseLeave:Connect(function() if tooltipMgr and tooltipMgr.Hide then tooltipMgr.Hide() end end)

	donateBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(donateInput.Text)
		if amt and amt >= 1000 then Network.GangAction:FireServer("Donate", amt); donateInput.Text = "" end
	end)

	local dualContainer = infoPage:WaitForChild("DualContainer")
	membersCard = dualContainer:WaitForChild("MembersCard")
	membersList = membersCard:WaitForChild("MembersList")
	requestsCard = dualContainer:WaitForChild("RequestsCard")
	requestsList = requestsCard:WaitForChild("RequestsList")

	settingsCard = infoPage:WaitForChild("SettingsCard")
	local settingsContent = settingsCard:WaitForChild("SettingsContent")

	joinModeBtn = settingsContent:WaitForChild("JoinModeBtn")
	joinModeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("ToggleJoinMode") end)

	local reqRow = settingsContent:WaitForChild("PrestigeReqRow")
	reqInput = reqRow:WaitForChild("ReqInput")
	reqBtn = reqRow:WaitForChild("ReqBtn")
	reqBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local val = tonumber(reqInput.Text)
		if val then Network.GangAction:FireServer("UpdatePrestigeReq", val); reqInput.Text = "" end
	end)

	settingsContent:WaitForChild("RgRow"):WaitForChild("RgBtn").MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); local t = settingsContent.RgRow.RgInput.Text
		if t ~= "" then Network.GangAction:FireServer("Rename", t); settingsContent.RgRow.RgInput.Text = "" end
	end)
	settingsContent:WaitForChild("MottoRow"):WaitForChild("MottoBtn").MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); local t = settingsContent.MottoRow.MottoInput.Text
		if t ~= "" then Network.GangAction:FireServer("UpdateMotto", t); settingsContent.MottoRow.MottoInput.Text = "" end
	end)
	settingsContent:WaitForChild("EmblemRow"):WaitForChild("EmblemBtn").MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); local t = settingsContent.EmblemRow.EmblemInput.Text
		if t ~= "" then Network.GangAction:FireServer("UpdateEmblem", t); settingsContent.EmblemRow.EmblemInput.Text = "" end
	end)

	leaveBtn = infoCard:WaitForChild("LeaveBtn")
	leaveBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local isBoss = (player:GetAttribute("GangRole") == "Boss" or player:GetAttribute("GangRole") == "Owner")
		local origText = isBoss and "Disband Gang" or "Leave Gang"
		if pendingLeave then
			pendingLeave = false; leaveBtn.Text = origText
			if isBoss then Network.GangAction:FireServer("Disband") else Network.GangAction:FireServer("Leave") end
		else
			pendingLeave = true; leaveBtn.Text = isBoss and "Confirm Disband?" or "Confirm Leave?"
			task.delay(3, function() if pendingLeave then pendingLeave = false; leaveBtn.Text = origText end end)
		end
	end)

	local rolesGridFrame = settingsContent:WaitForChild("RolesGridFrame")
	local function BindRoleUI(roleId)
		local frame = rolesGridFrame:WaitForChild("RoleSet_" .. roleId)
		local rInput = frame:WaitForChild("Input"); local rBtn = frame:WaitForChild("Btn")
		rBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			if rInput.Text ~= "" then Network.GangAction:FireServer("RenameRole", roleId, rInput.Text); rInput.Text = "" end
		end)
	end
	BindRoleUI("Boss"); BindRoleUI("Consigliere"); BindRoleUI("Caporegime"); BindRoleUI("Grunt")

	local function UpdateViewState()
		local gName = player:GetAttribute("Gang") or "None"
		if gName == "None" then
			activeContainer.Visible = false; createContainer.Visible = true
			Network.GangAction:FireServer("BrowseGangs")
		else
			activeContainer.Visible = true; createContainer.Visible = false
			if titleLabel then titleLabel.Text = gName:upper() end
			Network.GangAction:FireServer("RequestSync")
		end
	end

	player:GetAttributeChangedSignal("Gang"):Connect(UpdateViewState)
	player:GetAttributeChangedSignal("GangRole"):Connect(function()
		local myRole = player:GetAttribute("GangRole") or "Grunt"
		settingsCard.Visible = (myRole == "Boss" or myRole == "Consigliere")
	end)

	UpdateViewState()

	Network:WaitForChild("GangUpdate").OnClientEvent:Connect(function(action, data)
		GangsTab.HandleUpdate(action, data)
	end)

	task.spawn(function()
		while task.wait(60) do
			if mainContainer and mainContainer.Visible then
				local gName = player:GetAttribute("Gang") or "None"
				if gName == "None" and createContainer.Visible then Network.GangAction:FireServer("BrowseGangs")
				elseif gName ~= "None" and activeContainer.Visible then Network.GangAction:FireServer("RequestSync") end
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			if ordPage.Visible and lastOrderResetTime > 0 then
				local timeLeft = math.max(0, (lastOrderResetTime + 86400) - os.time())
				if timeLeft <= 0 then
					ordersTimerLbl.Text = "Generating new orders..."
				else
					local h = math.floor(timeLeft / 3600)
					local m = math.floor((timeLeft % 3600) / 60)
					local s = timeLeft % 60
					ordersTimerLbl.Text = string.format("Next Orders in: %02d:%02d:%02d", h, m, s)
				end
			end

			if upgPage.Visible and activeUpgradeFinishTime > 0 and activeUpgradeBtnRef then
				local timeLeft = math.max(0, activeUpgradeFinishTime - os.time())
				if timeLeft <= 0 then
					activeUpgradeBtnRef.Text = "Finishing..."
				else
					local m = math.floor(timeLeft / 60)
					local s = timeLeft % 60
					activeUpgradeBtnRef.Text = string.format("Upgrading (%02d:%02d)", m, s)
				end
			end
		end
	end)
end

function GangsTab.HandleUpdate(action, data)
	if action == "Sync" then
		if not data then 
			if titleLabel then titleLabel.Text = "LOADING..." end
			if mottoLabel then mottoLabel.Text = "<i>...</i>" end
			if emblemImage then emblemImage.Image = "" end
			lastOrderResetTime = 0
			activeUpgradeFinishTime = 0
			activeUpgradeBtnRef = nil
			for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			for _, c in pairs(buildingScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			for _, c in pairs(ordersScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			return
		end

		-- PURE DATA UPDATES: UI layout is handled natively by the grouped LeftInfoFrame containers
		if titleLabel then titleLabel.Text = data.Name:upper() .. " <font size='16' color='#AAAAAA'>(" .. (data.MemberCount or 1) .. "/30)</font>" end
		if mottoLabel then mottoLabel.Text = "<i>" .. (data.Motto or "No motto set.") .. "</i>" end
		if repLabel then repLabel.Text = "Reputation: <b><font color='#A020F0'>" .. (data.Rep or 0) .. "</font></b>" end

		if reqInput then reqInput.PlaceholderText = "Current Req: " .. tostring(data.PrestigeReq or 0) end
		lastOrderResetTime = data.LastOrderReset or 0

		if emblemImage then
			if data.Emblem and data.Emblem ~= "" then
				emblemImage.Image = data.Emblem
				emblemImage.Visible = true
			else
				emblemImage.Visible = false
			end
		end

		local level = GetGangLevel(data.Rep or 0)
		currentBoostText = GetBoostText(data.Buildings)
		if levelLabel then levelLabel.Text = "<b>Level " .. level .. "</b>" end
		if treasuryLabel then treasuryLabel.Text = "Treasury: <b>¥" .. FormatNumber(data.Treasury or 0) .. "</b>" end

		if data.JoinMode == "Open" then 
			joinModeBtn.Text = "Join: Open"; joinModeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else 
			joinModeBtn.Text = "Join: Request"; joinModeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0) 
		end

		local myRole = player:GetAttribute("GangRole") or "Grunt"
		local myPower = RolePower[myRole] or 1
		settingsCard.Visible = (myRole == "Boss" or myRole == "Consigliere")

		local shouldShowRequests = (myPower >= RolePower["Caporegime"]) and (data.JoinMode == "Request")
		if shouldShowRequests then 
			requestsCard.Visible = true; membersCard.Size = UDim2.new(0.58, 0, 1, 0)
		else 
			requestsCard.Visible = false; membersCard.Size = UDim2.new(1, 0, 1, 0) 
		end

		for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local memArray = {}
		for uId, mem in pairs(data.Members) do table.insert(memArray, {Id = uId, Data = mem}) end
		table.sort(memArray, function(a, b) 
			local pa = RolePower[a.Data.Role] or 1; local pb = RolePower[b.Data.Role] or 1
			if pa == pb then return a.Data.Name < b.Data.Name else return pa > pb end
		end)

		local customRoles = data.CustomRoles or {}
		local memTemplate = uiTemplates:WaitForChild("GangMemberRowTemplate")
		for _, mData in ipairs(memArray) do
			local uId = mData.Id; local mem = mData.Data
			local row = memTemplate:Clone(); row.Parent = membersList
			local displayRoleName = customRoles[mem.Role] or mem.Role
			row:WaitForChild("NameLabel").Text = mem.Name .. " <b><font color='" .. (RoleColors[mem.Role] or "#FFFFFF") .. "'>(" .. displayRoleName .. ")</font></b>"
			row:WaitForChild("TimeLabel").Text = FormatTimeAgo(mem.LastOnline)

			row.MouseEnter:Connect(function()
				if cachedTooltipMgr and cachedTooltipMgr.Show then
					cachedTooltipMgr.Show(string.format("<b>%s</b>, %s\n<font color='#55FFFF'>Prestige %d</font>, <font color='#AAAAAA'>%s</font>\n<font color='#55FF55'>Treasury Contribution: ¥%s</font>", mem.Name, FormatTimeAgo(mem.LastOnline), mem.Prestige or 0, FormatPlayTime(mem.PlayTime or 0), FormatNumber(mem.Contribution or 0)))
				end
			end)
			row.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

			local targetPower = RolePower[mem.Role] or 1
			local kBtn = row:WaitForChild("KickBtn"); local pBtn = row:WaitForChild("PromoteBtn"); local dBtn = row:WaitForChild("DemoteBtn")
			if uId ~= tostring(player.UserId) and myPower >= RolePower["Consigliere"] and myPower > targetPower then
				kBtn.Visible = true; pBtn.Visible = true; dBtn.Visible = true
				local pk = false
				kBtn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					if pk then Network.GangAction:FireServer("Kick", uId)
					else pk = true; kBtn.Text = "Sure?"; task.delay(3, function() if pk then pk = false; kBtn.Text = "Kick" end end) end
				end)
				pBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Promote", uId) end)
				dBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Demote", uId) end)
			end
		end

		for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		if shouldShowRequests and data.Requests then
			local reqTemplate = uiTemplates:WaitForChild("GangRequestRowTemplate")
			for uId, reqName in pairs(data.Requests) do
				local row = reqTemplate:Clone()
				row.Visible = true -- FIX: Ensure the cloned row is visible
				row.Parent = requestsList
				row:WaitForChild("NameLabel").Text = reqName
				row:WaitForChild("YesBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("AcceptRequest", uId) end)
				row:WaitForChild("NoBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("DenyRequest", uId) end)
			end
		end

		for _, c in pairs(buildingScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local buildTpl = uiTemplates:WaitForChild("BuildingRowTemplate")
		local bConfigs = {
			{Id = "Vault", Name = "The Vault", Desc = "+5% Yen Gain per level.", Max = 10, ReqLevel = 1},
			{Id = "Dojo", Name = "Training Hall", Desc = "+5% XP Gain per level.", Max = 10, ReqLevel = 2},
			{Id = "Market", Name = "Black Market", Desc = "+5 Inventory Slots per level.", Max = 3, ReqLevel = 3},
			{Id = "Shrine", Name = "Saint's Church", Desc = "+1 Luck per level.", Max = 3, ReqLevel = 4},
			{Id = "Armory", Name = "Armory", Desc = "+5% Damage per level.", Max = 5, ReqLevel = 5}
		}

		activeUpgradeFinishTime = data.ActiveUpgrade and data.ActiveUpgrade.FinishTime or 0
		local activeUpgradeId = data.ActiveUpgrade and data.ActiveUpgrade.Id or nil
		activeUpgradeBtnRef = nil

		for _, conf in ipairs(bConfigs) do
			local row = buildTpl:Clone(); row.Parent = buildingScroll
			local cLvl = (data.Buildings and data.Buildings[conf.Id]) or 0
			row:WaitForChild("NameLabel").Text = conf.Name .. " <font color='#FFFFFF'>(Lv."..cLvl.."/"..conf.Max..")</font>"
			row:WaitForChild("DescLbl").Text = conf.Desc
			local uBtn = row:WaitForChild("UpgradeBtn")
			if activeUpgradeId == conf.Id then activeUpgradeBtnRef = uBtn; uBtn.Text = "Starting..."; uBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
			elseif activeUpgradeId ~= nil then uBtn.Text = "Busy"; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif level < conf.ReqLevel then uBtn.Text = "Requires Gang Lv." .. conf.ReqLevel; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif cLvl >= conf.Max then uBtn.Text = "MAXED"; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else uBtn.Text = "Upgrade (¥100M)"; uBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("UpgradeBuilding", conf.Id) end) end
			if myPower < RolePower["Consigliere"] then uBtn.Visible = false end
		end

		for _, c in pairs(ordersScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		if data.Orders then
			local ordTpl = uiTemplates:WaitForChild("OrderRowTemplate")
			for i, ord in ipairs(data.Orders) do
				local row = ordTpl:Clone()
				row.Visible = true -- Ensuring visibility here as well
				row.Parent = ordersScroll
				row:WaitForChild("ProgBg"):WaitForChild("Fill").Size = UDim2.new(math.clamp(ord.Progress / ord.Target, 0, 1), 0, 1, 0)
				row:WaitForChild("ProgBg"):WaitForChild("ProgTxt").Text = FormatNumber(ord.Progress) .. " / " .. FormatNumber(ord.Target)

				local taskLbl = row:WaitForChild("TaskLbl")
				local rBtn = row:FindFirstChild("RerollBtn")

				if ord.Completed then
					taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='12' color='#55FF55'>[COMPLETED!]</font>"
					if rBtn then rBtn.Visible = false end
				else
					taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='11' color='#AAAAAA'>Rewards:</font> <font size='11' color='#55FF55'>¥" .. FormatNumber(ord.RewardT) .. "</font> <font size='11' color='#AAAAAA'>|</font> <font size='11' color='#A020F0'>+" .. ord.RewardR .. " Rep</font>"

					-- FIX: Restored Reroll Button functionality
					if rBtn then
						if myPower >= RolePower["Consigliere"] then
							rBtn.Visible = true
							rBtn.MouseButton1Click:Connect(function()
								SFXManager.Play("Click")
								Network.GangAction:FireServer("RerollOrder", i)
							end)
						else
							rBtn.Visible = false
						end
					end
				end
			end
		end

	elseif action == "BrowserSync" then
		for _, c in pairs(browserList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local brTemplate = uiTemplates:WaitForChild("GangBrowserRowTemplate")
		for _, g in ipairs(data) do
			local row = brTemplate:Clone()
			row.Visible = true
			row.Parent = browserList
			local reqText = (g.Req and g.Req > 0) and " <font color='#FFAA00'>[Pres " .. g.Req .. "+]</font>" or ""
			row:WaitForChild("NameLabel").Text = g.Name .. reqText
			row:WaitForChild("LevelLabel").Text = "Lv." .. g.Level .. " | " .. g.Members .. "/30"

			local mottoLbl = row:FindFirstChild("MottoLabel")
			if mottoLbl then mottoLbl.Text = "<i>" .. (g.Motto or "No motto set.") .. "</i>" end

			local embImg = row:FindFirstChild("EmblemImage")
			if embImg then
				if g.Emblem and g.Emblem ~= "" then
					embImg.Image = g.Emblem; embImg.Visible = true
				else
					embImg.Visible = false
				end
			end

			local jBtn = row:WaitForChild("JoinBtn")
			jBtn.Text = g.Mode == "Open" and "Join" or "Request"
			jBtn.BackgroundColor3 = g.Mode == "Open" and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(200, 150, 0)
			jBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("RequestJoin", g.Name) end)
		end
	end
end

return GangsTab