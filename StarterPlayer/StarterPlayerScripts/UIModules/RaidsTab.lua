-- @ScriptType: ModuleScript
local RaidsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local RaidAction = Network:WaitForChild("RaidAction")
local RaidUpdate = Network:WaitForChild("RaidUpdate")
local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local menuFrame, matchmakingFrame, combatCard
local raidTitleLabel
local hostCard, lobbyCard
local viewDefault, viewSetup, viewHosting
local hostingLbl, cancelLobbyBtn, startRaidBtn
local lobbyContainer

local partyContainer, bossContainer
local activeHPBars = {}
local bossHPBar = nil
local resourceLabel, turnTimerLabel, logScroll, skillsContainer, waitingLabel

local selectedRaidId = nil
local isFriendsOnly = false
local currentDeadline = 0
local cachedTooltipMgr, forceTabFocus

local raidBosses = {
	{ Id = "Raid_Part1", Name = "Vampire King", Req = 1, Desc = "A deadly raid against the progenitor of the stone mask." },
	{ Id = "Raid_Part2", Name = "Ultimate Lifeform", Req = 2, Desc = "Face the pinnacle of evolution. Bring Hamon!" },
	{ Id = "Raid_Part3", Name = "Time Stop Vampire", Req = 3, Desc = "He has conquered time itself. Good luck." },
	{ Id = "Raid_Part4", Name = "Serial Killer", Req = 4, Desc = "An elusive murderer with explosive tendencies." },
	{ Id = "Raid_Part5", Name = "Mafia Boss", Req = 5, Desc = "The boss of Passione. Time will erase." },
	{ Id = "Raid_Part6", Name = "Gravity Priest", Req = 6, Desc = "Gravity is shifting. The universe accelerates." },
	{ Id = "Raid_Part7", Name = "23rd President", Req = 7, Desc = "He has taken the first napkin. Beware his dimensional shifts." }
}

local function CreateHPBarRef(template, parent, isMe)
	local clone = template:Clone()
	clone.Parent = parent
	local bg = clone:WaitForChild("Bg")
	local fill = bg:WaitForChild("Fill")

	if isMe then 
		fill.BackgroundColor3 = Color3.fromRGB(50, 150, 255) 
	end

	return {
		Wrapper = clone,
		Fill = fill,
		Txt = bg:WaitForChild("HpText"),
		Label = clone:WaitForChild("NameLabel"),
		Status = clone:WaitForChild("StatusLbl"),
		Immunity = clone:WaitForChild("Immunity"),
		CImmunity = clone:WaitForChild("CImmunity")
	}
end

local function BuildStatusString(statuses)
	if not statuses then return "" end
	local active = {}
	local colors = {
		Stun = "#FFFF55", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000", Freeze = "#00FFFF", Confusion = "#FF55FF",
		Buff_Strength = "#55FF55", Buff_Defense = "#55FF55", Buff_Speed = "#55FF55", Buff_Willpower = "#55FF55",
		Debuff_Strength = "#FF5555", Debuff_Defense = "#FF5555", Debuff_Speed = "#FF5555", Debuff_Willpower = "#FF5555"
	}
	local names = {
		Buff_Strength = "Str+", Buff_Defense = "Def+", Buff_Speed = "Spd+", Buff_Willpower = "Will+",
		Debuff_Strength = "Str-", Debuff_Defense = "Def-", Debuff_Speed = "Spd-", Debuff_Willpower = "Will-"
	}
	local order = {"Stun", "Freeze", "Confusion", "Bleed", "Poison", "Burn", "Buff_Strength", "Buff_Defense", "Buff_Speed", "Buff_Willpower", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower"}

	for _, eff in ipairs(order) do
		local duration = statuses[eff]
		if duration and duration > 0 then
			local color = colors[eff] or "#FFFFFF"
			local name = names[eff] or eff
			table.insert(active, "<font color='" .. color .. "'>" .. name .. " (" .. duration .. ")</font>")
		end
	end
	return table.concat(active, " | ")
end

local function AddLog(text)
	local logTemplate = uiTemplates:WaitForChild("LogLineTemplate")
	local line = logTemplate:Clone()
	line.Text = text
	line.Parent = logScroll
	task.defer(function() logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y) end)
end

function RaidsTab.Init(parentFrame, tooltipMgr, focusFunc)
	cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc

	menuFrame = parentFrame:WaitForChild("MenuFrame")

	local uiElements = {}
	local raidRowTemplate = uiTemplates:WaitForChild("RaidRowTemplate")

	for _, rInfo in ipairs(raidBosses) do
		local row = raidRowTemplate:Clone()
		row.Parent = menuFrame

		local title = row:WaitForChild("TitleLabel")
		title.Text = "RAID: " .. rInfo.Name

		local desc = row:WaitForChild("DescLabel")
		desc.Text = rInfo.Desc

		local status = row:WaitForChild("StatusLabel")
		local playBtn = row:WaitForChild("PlayBtn")

		playBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
			if pObj and pObj.Value >= rInfo.Req then
				selectedRaidId = rInfo.Id
				raidTitleLabel.Text = "MATCHMAKING: " .. string.upper(rInfo.Name)
				menuFrame.Visible = false
				matchmakingFrame.Visible = true
				RaidAction:FireServer("RequestLobbies", selectedRaidId)
			end
		end)

		uiElements[rInfo.Id] = {Row = row, Status = status, Btn = playBtn, Info = rInfo}
	end

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10)
		if pObj then
			local prestige = pObj:WaitForChild("Prestige", 10)
			local function updateLocks()
				local pVal = prestige.Value
				for id, data in pairs(uiElements) do
					if pVal >= data.Info.Req then
						data.Btn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
						data.Btn.Text = "SELECT"; data.Btn.TextColor3 = Color3.new(1,1,1)
						data.Status.Text = "<font color='#55FF55'>Unlocked</font>"
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "??"; data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Status.Text = "<font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
					end
				end
			end
			prestige.Changed:Connect(updateLocks)
			updateLocks()
		end
	end)

	matchmakingFrame = parentFrame:WaitForChild("MatchmakingFrame")
	local topBar = matchmakingFrame:WaitForChild("TopBar")

	local backBtn = topBar:WaitForChild("BackBtn")
	backBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		matchmakingFrame.Visible = false
		menuFrame.Visible = true
		selectedRaidId = nil
		RaidAction:FireServer("CancelLobby")
	end)

	raidTitleLabel = topBar:WaitForChild("RaidTitleLabel")

	hostCard = matchmakingFrame:WaitForChild("HostCard")
	viewDefault = hostCard:WaitForChild("ViewDefault")
	local openSetupBtn = viewDefault:WaitForChild("OpenSetupBtn")

	viewSetup = hostCard:WaitForChild("ViewSetup")
	local friendsToggleBtn = viewSetup:WaitForChild("FriendsToggleBtn")
	local confirmSetupBtn = viewSetup:WaitForChild("ConfirmSetupBtn")
	local cancelSetupBtn = viewSetup:WaitForChild("CancelSetupBtn")

	viewHosting = hostCard:WaitForChild("ViewHosting")
	hostingLbl = viewHosting:WaitForChild("HostingLbl")
	startRaidBtn = viewHosting:WaitForChild("StartRaidBtn")
	cancelLobbyBtn = viewHosting:WaitForChild("CancelLobbyBtn")

	openSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewDefault.Visible = false; viewSetup.Visible = true end)
	cancelSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewSetup.Visible = false; viewDefault.Visible = true end)

	friendsToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isFriendsOnly = not isFriendsOnly
		friendsToggleBtn.Text = isFriendsOnly and "[X] Friends Only" or "[ ] Friends Only"
		friendsToggleBtn.TextColor3 = isFriendsOnly and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	confirmSetupBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		RaidAction:FireServer("CreateLobby", {RaidId = selectedRaidId, FriendsOnly = isFriendsOnly})
	end)

	cancelLobbyBtn.MouseButton1Click:Connect(function() 
		SFXManager.Play("Click")
		RaidAction:FireServer("CancelLobby")
	end)

	startRaidBtn.MouseButton1Click:Connect(function() 
		SFXManager.Play("Click")
		RaidAction:FireServer("ForceStartRaid")
	end)

	lobbyCard = matchmakingFrame:WaitForChild("LobbyCard")
	lobbyContainer = lobbyCard:WaitForChild("LobbyContainer")

	combatCard = parentFrame:WaitForChild("CombatCard")
	local topArea = combatCard:WaitForChild("TopArea")

	partyContainer = topArea:WaitForChild("PartyContainer")
	turnTimerLabel = topArea:WaitForChild("TurnTimerLabel")
	bossContainer = topArea:WaitForChild("BossContainer")
	resourceLabel = topArea:WaitForChild("ResourceLabel")

	logScroll = combatCard:WaitForChild("LogScroll")
	waitingLabel = combatCard:WaitForChild("WaitingLabel")
	skillsContainer = combatCard:WaitForChild("SkillsContainer")

	task.spawn(function()
		while task.wait(0.2) do
			if combatCard.Visible and currentDeadline > 0 then
				local remain = math.max(0, currentDeadline - os.time())
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	RaidUpdate.OnClientEvent:Connect(function(action, data)
		RaidsTab.HandleUpdate(action, data)
	end)
end

function RaidsTab.UpdateCombatState(state)
	for _, c in pairs(partyContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, c in pairs(bossContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	local playerHpTemplate = uiTemplates:WaitForChild("RaidPlayerHPBarTemplate")

	for _, pData in ipairs(state.Party) do
		local barInfo = CreateHPBarRef(playerHpTemplate, partyContainer, pData.UserId == state.MyId)
		barInfo.Label.Text = pData.Name .. (pData.HP <= 0 and " (DEAD)" or "")
		barInfo.Fill.Size = UDim2.new(math.clamp(pData.HP / pData.MaxHP, 0, 1), 0, 1, 0)
		barInfo.Txt.Text = math.floor(pData.HP) .. "/" .. math.floor(pData.MaxHP)

		barInfo.Status.Text = BuildStatusString(pData.Statuses)

		if pData.StunImmunity and pData.StunImmunity > 0 then
			barInfo.Immunity.Text = "Stun Immune: " .. pData.StunImmunity .. " Turns"
		else
			barInfo.Immunity.Text = ""
		end

		if pData.ConfusionImmunity and pData.ConfusionImmunity > 0 then
			barInfo.CImmunity.Text = "Confuse Immune: " .. pData.ConfusionImmunity .. " Turns"
		else
			barInfo.CImmunity.Text = ""
		end

		if pData.UserId == state.MyId then
			resourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		end
	end

	local bossHpTemplate = uiTemplates:WaitForChild("RaidBossHPBarTemplate")
	bossHPBar = CreateHPBarRef(bossHpTemplate, bossContainer, false)

	bossHPBar.Label.Text = state.Boss.Name
	bossHPBar.Fill.Size = UDim2.new(math.clamp(state.Boss.HP / state.Boss.MaxHP, 0, 1), 0, 1, 0)
	bossHPBar.Txt.Text = math.floor(state.Boss.HP) .. " / " .. math.floor(state.Boss.MaxHP)

	bossHPBar.Status.Text = BuildStatusString(state.Boss.Statuses)

	if state.Boss.StunImmunity and state.Boss.StunImmunity > 0 then
		bossHPBar.Immunity.Text = "Stun Immune: " .. state.Boss.StunImmunity .. " Turns"
	else
		bossHPBar.Immunity.Text = ""
	end

	if state.Boss.ConfusionImmunity and state.Boss.ConfusionImmunity > 0 then
		bossHPBar.CImmunity.Text = "Confuse Immune: " .. state.Boss.ConfusionImmunity .. " Turns"
	else
		bossHPBar.CImmunity.Text = ""
	end
end

function RaidsTab.RenderSkills(state)
	for _, child in pairs(skillsContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	local myState = nil
	for _, p in ipairs(state.Party) do if p.UserId == state.MyId then myState = p break end end
	if not myState then return end

	local myStand, myStyle = myState.Stand or "None", myState.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then table.insert(valid, {Name = n, Data = s}) end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	local skillTemplate = uiTemplates:WaitForChild("SkillButtonTemplate")

	for _, sk in ipairs(valid) do
		local btn = skillTemplate:Clone()
		btn.Text = sk.Name
		btn.Parent = skillsContainer

		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		btn.BackgroundColor3 = c

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)

		local currentCooldown = myState.Cooldowns and myState.Cooldowns[sk.Name] or 0

		if myState.Stamina < (sk.Data.StaminaCost or 0) or myState.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45); btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
			if currentCooldown > 0 then btn.Text = sk.Name .. " (" .. currentCooldown .. ")" end
		else
			if sk.Name == "Flee" then
				local isConfirmingFlee = false
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					if not isConfirmingFlee then
						isConfirmingFlee = true
						btn.Text = "Confirm Flee?"
						btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
						task.delay(3, function()
							if isConfirmingFlee then
								isConfirmingFlee = false
								if btn and btn.Parent then
									btn.Text = sk.Name
									btn.BackgroundColor3 = c
								end
							end
						end)
					else
						cachedTooltipMgr.Hide()
						RaidAction:FireServer("Attack", sk.Name) 
					end
				end)
			else
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					cachedTooltipMgr.Hide()
					RaidAction:FireServer("Attack", sk.Name) 
				end)
			end
		end
	end
end

function RaidsTab.HandleUpdate(action, data)
	if action == "LobbyStatus" then
		if data.IsHosting then
			viewDefault.Visible = false
			viewSetup.Visible = false
			viewHosting.Visible = true

			local count = data.PlayerCount or 1
			hostingLbl.Text = "Party: " .. count .. "/4 Players"

			if data.IsLobbyOwner then
				startRaidBtn.Visible = true
				startRaidBtn.Text = count > 1 and "Start Raid" or "Start Solo"
				cancelLobbyBtn.Size = UDim2.new(0.42, 0, 0.4, 0)
				cancelLobbyBtn.Position = UDim2.new(0.53, 0, 0.5, 0)
				cancelLobbyBtn.Text = "Disband Party"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				startRaidBtn.Visible = false
				cancelLobbyBtn.Size = UDim2.new(0.6, 0, 0.4, 0)
				cancelLobbyBtn.Position = UDim2.new(0.2, 0, 0.5, 0)
				cancelLobbyBtn.Text = "Leave Party"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
			end
		else
			viewDefault.Visible = true
			viewSetup.Visible = false
			viewHosting.Visible = false
		end

	elseif action == "LobbiesUpdate" then
		if data.RaidId ~= selectedRaidId then return end
		local lobbies = data.Lobbies

		for _, child in pairs(lobbyContainer:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end

		if #lobbies == 0 then
			local empty = Instance.new("TextLabel", lobbyContainer)
			empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1
			empty.Text = "No open parties found for this Raid."; empty.TextColor3 = Color3.fromRGB(150, 150, 150)
			empty.Font = Enum.Font.GothamMedium; empty.TextSize = 14
			return
		end

		local lobbyTemplate = uiTemplates:WaitForChild("LobbyRowTemplate")

		for _, lobby in ipairs(lobbies) do
			local row = lobbyTemplate:Clone()
			row.Parent = lobbyContainer

			local infoText = "<b>" .. lobby.HostName .. "'s Party</b>"
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			infoText = infoText .. "\n<font color='#AAAAAA' size='12'>Members: " .. table.concat(lobby.Members, ", ") .. "</font>"

			local lbl = row:WaitForChild("InfoLabel")
			lbl.Text = infoText

			local countLbl = row:WaitForChild("CountLabel")
			countLbl.Text = (lobby.PlayerCount or 1) .. "/4"

			local joinBtn = row:WaitForChild("JoinBtn")

			if lobby.HostId == player.UserId then
				joinBtn.Text = "Hosting"
				joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
				joinBtn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					RaidAction:FireServer("JoinLobby", {HostId = lobby.HostId})
				end)
			end
		end

	elseif action == "MatchStart" then
		if forceTabFocus then forceTabFocus() end 
		menuFrame.Visible = false
		matchmakingFrame.Visible = false
		combatCard.Visible = true

		currentDeadline = data.Deadline or 0
		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		AddLog("<font color='#FFD700'>" .. data.LogMsg .. "</font>")
		skillsContainer.Visible = true
		waitingLabel.Visible = false

		RaidsTab.UpdateCombatState(data.State)
		RaidsTab.RenderSkills(data.State)

	elseif action == "Waiting" then
		skillsContainer.Visible = false
		waitingLabel.Text = "Waiting for other players..."
		waitingLabel.Visible = true

	elseif action == "TurnResult" then
		currentDeadline = data.Deadline or 0

		if data.LogMsg and data.LogMsg ~= "" then
			skillsContainer.Visible = false
			waitingLabel.Text = "Combat is playing out..."
			waitingLabel.Visible = true

			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do if line ~= "" then AddLog(line) end end

			if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
			elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
			elseif data.DidHit then SFXManager.Play("CombatHit")
			elseif string.find(data.LogMsg, "used <b>") then SFXManager.Play("CombatUtility") end

			task.spawn(function()
				task.wait(0.05)
				if string.find(data.LogMsg, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
				if string.find(data.LogMsg, "(Stunned!)", 1, true) or string.find(data.LogMsg, "stunning") or string.find(data.LogMsg, "halt") then SFXManager.Play("CombatStun") end
				if string.find(string.lower(data.LogMsg), "survived on willpower") then SFXManager.Play("CombatWillpower") end
			end)

			if data.DidHit then
				task.spawn(function()
					local p = data.ShakeType == "Heavy" and 18 or (data.ShakeType == "Light" and 3 or 8)
					local orig = UDim2.new(0.025, 0, 0, 0)
					for i = 1, 6 do 
						if combatCard then
							combatCard.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p))
						end
						task.wait(0.04) 
					end
					if combatCard then
						combatCard.Position = orig
					end
				end)
			end
		else
			waitingLabel.Visible = false
			skillsContainer.Visible = true
		end

		RaidsTab.UpdateCombatState(data.State)

		if data.LogMsg == "" then
			RaidsTab.RenderSkills(data.State)
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Raid Over!"
		skillsContainer.Visible = false
		waitingLabel.Visible = false
		AddLog(data.LogMsg)

		if data.Result == "Win" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		task.delay(5, function()
			viewDefault.Visible = true; viewSetup.Visible = false; viewHosting.Visible = false
			hostCard.Visible = true; lobbyCard.Visible = true
			combatCard.Visible = false
			menuFrame.Visible = true
			RaidAction:FireServer("RequestLobbies", selectedRaidId)
		end)
	end
end

return RaidsTab