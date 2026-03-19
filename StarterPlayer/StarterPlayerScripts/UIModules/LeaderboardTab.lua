-- @ScriptType: ModuleScript
local LeaderboardTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local playerCategories = {
	{Id = "Prestige", Name = "Prestiges"},
	{Id = "Endless", Name = "Endless Dungeon"},
	{Id = "PlayTime", Name = "Time Played"},
	{Id = "Elo", Name = "Arena Elo"},
	{Id = "Power", Name = "Power"},
	{Id = "RaidWins", Name = "Raid Bosses"} 
}

local gangCategories = {
	{Id = "GangRep", Name = "Reputation"},
	{Id = "GangTreasury", Name = "Treasury"},
	{Id = "GangPrestige", Name = "Total Prestige"},
	{Id = "GangElo", Name = "Total Elo"},
	{Id = "GangRaids", Name = "Raid Bosses"}
}

local currentMode = "Players"
local currentCategory = "Prestige"
local listContainer, catScroll
local cachedTooltipMgr
local hoveredLbEntry = nil -- State tracking for tooltip safety

local function FormatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function FormatValue(cat, val)
	if cat == "PlayTime" then
		local hours = math.floor(val / 3600)
		local minutes = math.floor((val % 3600) / 60)
		return hours .. "h " .. minutes .. "m"
	elseif cat == "Endless" then
		return "Floor " .. val
	elseif cat == "GangTreasury" then
		return "¥" .. FormatNumber(val)
	end
	return FormatNumber(val)
end

function LeaderboardTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	local mainScroll = parentFrame:WaitForChild("MainScroll")
	local mainList = mainScroll:WaitForChild("UIListLayout")

	local catCard = mainScroll:WaitForChild("CatCard")
	catScroll = catCard:WaitForChild("CatScroll")

	local lbCard = mainScroll:WaitForChild("LbCard")
	local lbTitle = lbCard:WaitForChild("TitleLabel")
	local modeBtn = lbCard:WaitForChild("ModeBtn")
	listContainer = lbCard:WaitForChild("ListContainer")
	local listLayout = listContainer:WaitForChild("UIListLayout")

	local catBtnTemplate = uiTemplates:WaitForChild("LbCategoryBtnTemplate")

	local function RequestLeaderboard(catId)
		currentCategory = catId

		-- Safety clear tooltip when swapping boards
		hoveredLbEntry = nil
		if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end

		for _, child in pairs(listContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local loadingLbl = Instance.new("TextLabel")
		loadingLbl.Size = UDim2.new(1, 0, 0, 40)
		loadingLbl.BackgroundTransparency = 1; loadingLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		loadingLbl.Font = Enum.Font.GothamMedium; loadingLbl.TextSize = 16
		loadingLbl.Text = "Fetching data..."; loadingLbl.Parent = listContainer

		Network.LeaderboardAction:FireServer(catId)
	end

	local function RenderCategoryButtons()
		for _, child in pairs(catScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		local catsToRender = (currentMode == "Players") and playerCategories or gangCategories

		for _, cat in ipairs(catsToRender) do
			local btn = catBtnTemplate:Clone()
			btn.Text = cat.Name
			local stroke = btn:WaitForChild("UIStroke")
			btn.Parent = catScroll

			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				for _, child in pairs(catScroll:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
						child.TextColor3 = Color3.new(1,1,1)
						child:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
					end
				end
				btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
				btn.TextColor3 = Color3.fromRGB(255, 215, 0)
				stroke.Color = Color3.fromRGB(255, 215, 0)
				RequestLeaderboard(cat.Id)
			end)

			if cat.Id == currentCategory then
				btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
				btn.TextColor3 = Color3.fromRGB(255, 215, 0)
				stroke.Color = Color3.fromRGB(255, 215, 0)
			else
				btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
				btn.TextColor3 = Color3.new(1,1,1)
				stroke.Color = Color3.fromRGB(120, 60, 180)
			end
		end
	end

	modeBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentMode == "Players" then
			currentMode = "Gangs"
			modeBtn.Text = "SWITCH TO PLAYERS"
			currentCategory = "GangRep"
			lbTitle.Text = "TOP 100 GANGS"
		else
			currentMode = "Players"
			modeBtn.Text = "SWITCH TO GANGS"
			currentCategory = "Prestige"
			lbTitle.Text = "TOP 100 PLAYERS"
		end
		RenderCategoryButtons()
		RequestLeaderboard(currentCategory)
	end)

	mainList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		mainScroll.CanvasSize = UDim2.new(0, 0, 0, mainList.AbsoluteContentSize.Y + 30)
	end)

	local rowTemplate = uiTemplates:WaitForChild("LbRowTemplate")

	Network:WaitForChild("LeaderboardUpdate").OnClientEvent:Connect(function(catId, data)
		if catId ~= currentCategory then return end

		for _, child in pairs(listContainer:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end

		local myRankStr = "Unranked"
		local targetName = (currentMode == "Players") and player.Name or (player:GetAttribute("Gang") or "None")

		for _, entry in ipairs(data) do
			if string.lower(entry.Name) == string.lower(targetName) and targetName ~= "None" then
				myRankStr = "#" .. entry.Rank
				break
			end
		end

		if lbTitle then
			local titlePrefix = (currentMode == "Players") and "TOP 100 PLAYERS" or "TOP 100 GANGS"
			lbTitle.Text = titlePrefix .. " <font color='#AAAAAA' size='14'>(Your Rank: " .. myRankStr .. ")</font>"
		end

		if #data == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 0, 40)
			emptyLbl.BackgroundTransparency = 1; emptyLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			emptyLbl.Font = Enum.Font.GothamMedium; emptyLbl.TextSize = 16
			emptyLbl.Text = "No data yet."; emptyLbl.Parent = listContainer
			return
		end

		for i, entry in ipairs(data) do
			local row = rowTemplate:Clone()
			row.BackgroundTransparency = (i%2==0) and 0.8 or 1
			row.Parent = listContainer

			local rankColor = Color3.new(0.9, 0.9, 0.9)
			if entry.Rank == 1 then rankColor = Color3.fromRGB(255, 215, 0)
			elseif entry.Rank == 2 then rankColor = Color3.fromRGB(192, 192, 192)
			elseif entry.Rank == 3 then rankColor = Color3.fromRGB(205, 127, 50) end

			local rowRank = row:WaitForChild("RowRank")
			rowRank.Text = "#" .. entry.Rank
			rowRank.TextColor3 = rankColor

			local rowName = row:WaitForChild("RowName")
			rowName.Text = entry.Name
			rowName.TextColor3 = rankColor

			local rowVal = row:WaitForChild("RowVal")
			rowVal.Text = FormatValue(catId, entry.Value)

			local iconImg = row:FindFirstChild("IconImage")
			if iconImg then
				if currentMode == "Players" then
					iconImg.Image = entry.Profile and entry.Profile.Icon or ""
					iconImg.Visible = true
				else
					if entry.Profile and entry.Profile.Emblem and entry.Profile.Emblem ~= "" then
						iconImg.Image = entry.Profile.Emblem
						iconImg.Visible = true
					else
						iconImg.Visible = false
					end
				end
			end

			row.MouseEnter:Connect(function()
				if not entry.Profile then return end
				hoveredLbEntry = entry.Name

				local desc = ""

				if currentMode == "Players" then
					desc = string.format("<b><font color='#A020F0'>%s</font></b>\n____________________\n\n", entry.Name)
					desc ..= "<font color='#FFD700'>Prestige:</font> " .. FormatNumber(entry.Profile.Prestige) .. "\n"
					desc ..= "<font color='#55FF55'>Power Level:</font> " .. FormatNumber(entry.Profile.Power) .. "\n"
					desc ..= "<font color='#FF5555'>Arena Elo:</font> " .. FormatNumber(entry.Profile.Elo) .. "\n"
					desc ..= "<font color='#55FFFF'>Endless Floor:</font> " .. FormatNumber(entry.Profile.Endless) .. "\n"
					desc ..= "<font color='#FF8C00'>Raid Bosses:</font> " .. FormatNumber(entry.Profile.RaidWins) .. "\n"
					desc ..= "<font color='#AAAAAA'>Playtime:</font> " .. FormatValue("PlayTime", entry.Profile.PlayTime)
				else
					local cleanMotto = entry.Profile.Motto or "No motto set."
					desc = string.format("<b><font color='#A020F0'>%s</font></b>\n<i>%s</i>\n____________________\n\n", entry.Name, cleanMotto)
					desc ..= "<font color='#A020F0'>Reputation:</font> " .. FormatNumber(entry.Profile.Rep) .. "\n"
					desc ..= "<font color='#55FF55'>Treasury:</font> ¥" .. FormatNumber(entry.Profile.Treasury) .. "\n"
					desc ..= "<font color='#FFD700'>Total Prestige:</font> " .. FormatNumber(entry.Profile.Prestige) .. "\n"
					desc ..= "<font color='#FF5555'>Total Elo:</font> " .. FormatNumber(entry.Profile.Elo) .. "\n"
					desc ..= "<font color='#FF8C00'>Raid Bosses:</font> " .. FormatNumber(entry.Profile.RaidWins)
				end

				cachedTooltipMgr.Show(desc)
			end)

			row.MouseLeave:Connect(function()
				if hoveredLbEntry == entry.Name then
					hoveredLbEntry = nil
					if cachedTooltipMgr and cachedTooltipMgr.Hide then
						cachedTooltipMgr.Hide()
					end
				end
			end)
		end
	end)

	RenderCategoryButtons()
	task.delay(1, function() RequestLeaderboard(currentCategory) end)
end

return LeaderboardTab