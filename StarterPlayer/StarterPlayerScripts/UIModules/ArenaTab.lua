-- @ScriptType: ModuleScript
local ArenaTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local hostCard, lobbyCard, activeMatchesCard, combatCard
local viewDefault, viewSetup, viewHosting
local eloLabel, hostingLbl
local lobbyContainer, matchesContainer
local allyContainer, enemyContainer
local activeHPBars = {} 
local selectedTargetId = nil
local isCurrentlySpectating = false

local resourceLabel, logScroll, skillsContainer, spectatorPanel, waitingLabel, turnTimerLabel
local rootFrame, cachedTooltipMgr, forceTabFocus
local currentDeadline = 0

local pool1Lbl, pool2Lbl, betAmountBox, betT1Btn, betT2Btn, leaveSpecBtn

local function CreateHPBarRef(template, parent, isEnemy, isMe)
	local clone = template:Clone()
	clone.Parent = parent

	local bg = clone:WaitForChild("Bg")
	local fill = bg:WaitForChild("Fill")
	local stroke = bg:WaitForChild("UIStroke")

	if isMe then
		fill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	end

	return {
		Wrapper = clone,
		Fill = fill,
		Txt = bg:WaitForChild("HpText"),
		Label = clone:WaitForChild("NameLabel"),
		Stroke = stroke,
		DefaultColor = stroke.Color,
		Immunity = clone:WaitForChild("Immunity"),
		CImmunity = clone:WaitForChild("CImmunity"),
		Status = clone:WaitForChild("StatusLbl")
	}
end

local function BuildStatusString(statuses)
	if not statuses then return "" end
	local active = {}
	local colors = {
		Stun = "#FFFF55", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000",
		Freeze = "#00FFFF", Confusion = "#FF55FF",
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

local function GetEloBoostText(elo)
	local str = "<b><font color='#FFD700'>ELO MILESTONES</font></b>\n____________________\n\n"
	local boosts = {
		{req = 1500, text = "1.5k: +5% Yen Boost"},
		{req = 2000, text = "2k: +5% XP Boost"},
		{req = 3000, text = "3k: +1% Luck Boost"},
		{req = 4000, text = "4k: +5 Inventory Space"},
		{req = 5000, text = "5k: 5% Increased Global Damage"}
	}

	for i, b in ipairs(boosts) do
		if elo >= b.req then
			str = str .. "<font color='#55FF55'>" .. b.text .. "</font>"
		else
			str = str .. "<font color='#888888'>" .. b.text .. "</font>"
		end
		if i < #boosts then str = str .. "\n" end
	end
	return str
end

function ArenaTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc

	local mainScroll = parentFrame:WaitForChild("MainScroll")

	hostCard = mainScroll:WaitForChild("HostCard")
	viewDefault = hostCard:WaitForChild("ViewDefault")
	eloLabel = viewDefault:WaitForChild("EloLabel")

	local activeBoostsBtn = viewDefault:WaitForChild("ActiveBoostsBtn")
	activeBoostsBtn.MouseEnter:Connect(function()
		local pObj = player:FindFirstChild("leaderstats")
		local elo = pObj and pObj:FindFirstChild("Elo") and pObj.Elo.Value or 1000
		if cachedTooltipMgr and cachedTooltipMgr.Show then cachedTooltipMgr.Show(GetEloBoostText(elo)) end
	end)
	activeBoostsBtn.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

	local openSetupBtn = viewDefault:WaitForChild("OpenSetupBtn")

	viewSetup = hostCard:WaitForChild("ViewSetup")
	local friendsToggleBtn = viewSetup:WaitForChild("FriendsToggleBtn")
	local casualToggleBtn = viewSetup:WaitForChild("CasualToggleBtn")
	local capacityBtn = viewSetup:WaitForChild("CapacityBtn")
	local confirmSetupBtn = viewSetup:WaitForChild("ConfirmSetupBtn")
	local cancelSetupBtn = viewSetup:WaitForChild("CancelSetupBtn")

	viewHosting = hostCard:WaitForChild("ViewHosting")
	hostingLbl = viewHosting:WaitForChild("HostingLbl")
	local cancelLobbyBtn = viewHosting:WaitForChild("CancelLobbyBtn")

	local isFriendsOnly = false
	local isCasual = false
	local currentCapacity = 2

	openSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewDefault.Visible = false; viewSetup.Visible = true end)
	cancelSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewSetup.Visible = false; viewDefault.Visible = true end)

	friendsToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isFriendsOnly = not isFriendsOnly
		friendsToggleBtn.Text = isFriendsOnly and "[X] Friends" or "[ ] Friends"
		friendsToggleBtn.TextColor3 = isFriendsOnly and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	casualToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isCasual = not isCasual
		casualToggleBtn.Text = isCasual and "[X] Casual" or "[ ] Casual"
		casualToggleBtn.TextColor3 = isCasual and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	capacityBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentCapacity == 2 then currentCapacity = 4; capacityBtn.Text = "Mode: 2v2"
		elseif currentCapacity == 4 then currentCapacity = 8; capacityBtn.Text = "Mode: 4v4"
		else currentCapacity = 2; capacityBtn.Text = "Mode: 1v1" end
	end)

	confirmSetupBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); Network.ArenaAction:FireServer("CreateLobby", {FriendsOnly = isFriendsOnly, Casual = isCasual, Capacity = currentCapacity}) 
	end)

	cancelLobbyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.ArenaAction:FireServer("CancelLobby") end)

	lobbyCard = mainScroll:WaitForChild("LobbyCard")
	lobbyContainer = lobbyCard:WaitForChild("LobbyContainer")

	activeMatchesCard = mainScroll:WaitForChild("ActiveMatchesCard")
	matchesContainer = activeMatchesCard:WaitForChild("MatchesContainer")

	combatCard = mainScroll:WaitForChild("CombatCard")
	local topArea = combatCard:WaitForChild("TopArea")

	turnTimerLabel = topArea:WaitForChild("TurnTimerLabel")
	allyContainer = topArea:WaitForChild("AllyContainer")
	enemyContainer = topArea:WaitForChild("EnemyContainer")
	resourceLabel = topArea:WaitForChild("ResourceLabel")

	logScroll = combatCard:WaitForChild("LogScroll")
	waitingLabel = combatCard:WaitForChild("WaitingLabel")
	skillsContainer = combatCard:WaitForChild("SkillsContainer")
	spectatorPanel = combatCard:WaitForChild("SpectatorPanel")

	pool1Lbl = spectatorPanel:WaitForChild("Pool1Lbl")
	pool2Lbl = spectatorPanel:WaitForChild("Pool2Lbl")
	betAmountBox = spectatorPanel:WaitForChild("BetAmountBox")
	betT1Btn = spectatorPanel:WaitForChild("BetT1Btn")
	betT2Btn = spectatorPanel:WaitForChild("BetT2Btn")
	leaveSpecBtn = spectatorPanel:WaitForChild("LeaveSpecBtn")

	betT1Btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.ArenaAction:FireServer("PlaceBet", {Team = 1, Amount = betAmountBox.Text}) end)
	betT2Btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.ArenaAction:FireServer("PlaceBet", {Team = 2, Amount = betAmountBox.Text}) end)
	leaveSpecBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.ArenaAction:FireServer("LeaveSpectate") end)

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

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 5)
		if pObj then
			local elo = pObj:WaitForChild("Elo", 5)
			if elo then eloLabel.Text = "Your Elo: " .. elo.Value; elo.Changed:Connect(function(val) eloLabel.Text = "Your Elo: " .. val end) end
		end
	end)

	Network.ArenaAction:FireServer("RequestLobbies")
end

function ArenaTab.HandleUpdate(action, data)
	if action == "LobbyStatus" then
		if data.IsHosting then
			viewDefault.Visible = false
			viewSetup.Visible = false
			viewHosting.Visible = true

			local cap = data.Capacity or 2
			local maxPerTeam = cap / 2
			local modeStr = (cap == 2 and "1v1") or (cap == 4 and "2v2") or "4v4"
			hostingLbl.Text = "Team 1: " .. (data.T1Count or 1) .. "/" .. maxPerTeam .. " | Team 2: " .. (data.T2Count or 0) .. "/" .. maxPerTeam .. " [" .. modeStr .. "]"

			local cancelLobbyBtn = viewHosting:FindFirstChild("CancelLobbyBtn")
			if cancelLobbyBtn then
				if data.IsLobbyOwner then
					cancelLobbyBtn.Text = "Cancel Lobby"
					cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
				else
					cancelLobbyBtn.Text = "Leave Queue"
					cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
				end
			end
		else
			viewDefault.Visible = true; viewSetup.Visible = false; viewHosting.Visible = false
		end

	elseif action == "LobbiesUpdate" then
		for _, child in pairs(lobbyContainer:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
		if #data == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No open lobbies found."; empty.TextColor3 = Color3.fromRGB(150, 150, 150)
			empty.Font = Enum.Font.GothamMedium; empty.TextSize = 14; empty.Parent = lobbyContainer
			return
		end

		local lobbyTemplate = uiTemplates:WaitForChild("ArenaLobbyRowTemplate")

		for _, lobby in ipairs(data) do
			local row = lobbyTemplate:Clone()
			row.Parent = lobbyContainer

			local modeStr = (lobby.Capacity == 2 and "1v1") or (lobby.Capacity == 4 and "2v2") or "4v4"
			local infoText = "<b>" .. lobby.HostName .. "</b> | " .. modeStr .. " | Elo: " .. lobby.Elo
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			if lobby.Casual then infoText = infoText .. " <font color='#55FFFF'>[Casual]</font>" end

			local lbl = row:WaitForChild("InfoLabel")
			lbl.Text = infoText

			local maxPerTeam = lobby.Capacity / 2
			local hostBtn = row:WaitForChild("HostBtn")
			local joinBtn = row:WaitForChild("JoinBtn")
			local t1Btn = row:WaitForChild("T1Btn")
			local t2Btn = row:WaitForChild("T2Btn")

			if lobby.HostId == player.UserId then
				hostBtn.Visible = true
				joinBtn.Visible = false; t1Btn.Visible = false; t2Btn.Visible = false
			elseif lobby.Capacity == 2 then
				joinBtn.Visible = true
				hostBtn.Visible = false; t1Btn.Visible = false; t2Btn.Visible = false

				joinBtn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)
			else
				t1Btn.Visible = true; t2Btn.Visible = true
				hostBtn.Visible = false; joinBtn.Visible = false

				t1Btn.Text = "T1 (" .. lobby.T1Count .. "/" .. maxPerTeam .. ")"
				t1Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 1}) 
				end)

				t2Btn.Text = "T2 (" .. lobby.T2Count .. "/" .. maxPerTeam .. ")"
				t2Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)
			end
		end

	elseif action == "ActiveMatchesUpdate" then
		for _, child in pairs(matchesContainer:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
		if #data == 0 then
			local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No active battles."; empty.TextColor3 = Color3.fromRGB(150, 150, 150); empty.Font = Enum.Font.GothamMedium; empty.TextSize = 14; empty.Parent = matchesContainer
			return
		end

		local matchTemplate = uiTemplates:WaitForChild("ArenaMatchRowTemplate")

		for _, match in ipairs(data) do
			local row = matchTemplate:Clone()
			row.Parent = matchesContainer

			local infoText = "<b>" .. match.HostName .. "'s Match</b> | " .. match.Mode .. "\n<font color='#AAAAAA' size='12'>Pool: ¥" .. (match.Pool1 + match.Pool2) .. " | Spectators: " .. match.SpectatorCount .. "</font>"
			local lbl = row:WaitForChild("InfoLabel")
			lbl.Text = infoText

			local specBtn = row:WaitForChild("SpecBtn")
			specBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click")
				Network.ArenaAction:FireServer("SpectateMatch", {MatchId = match.MatchId}) 
			end)
		end

	elseif action == "MatchStart" then
		if forceTabFocus then forceTabFocus() end 
		currentDeadline = data.Deadline or 0
		hostCard.Visible = false; lobbyCard.Visible = false; activeMatchesCard.Visible = false
		combatCard.Visible = true; waitingLabel.Visible = false

		isCurrentlySpectating = data.State.IsSpectator
		if isCurrentlySpectating then
			skillsContainer.Visible = false
			spectatorPanel.Visible = true
			pool1Lbl.Text = "Pool 1: ¥" .. data.State.Pool1
			pool2Lbl.Text = "Pool 2: ¥" .. data.State.Pool2
		else
			skillsContainer.Visible = true
			spectatorPanel.Visible = false
		end

		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		AddLog("<font color='#FFD700'>" .. data.LogMsg .. "</font>")
		selectedTargetId = nil
		ArenaTab.UpdateCombatState(data.State)
		if not isCurrentlySpectating then ArenaTab.RenderSkills(data.State) end

	elseif action == "Waiting" then
		skillsContainer.Visible = false; waitingLabel.Visible = true

	elseif action == "BetUpdate" then
		pool1Lbl.Text = "Pool 1: ¥" .. data.Pool1
		pool2Lbl.Text = "Pool 2: ¥" .. data.Pool2

	elseif action == "TurnResult" then
		currentDeadline = data.Deadline or 0

		if data.LogMsg and data.LogMsg ~= "" then
			skillsContainer.Visible = false
			waitingLabel.Text = "Combat is playing out..."
			waitingLabel.Visible = true

			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do if line ~= "" then AddLog(line) end end

			ArenaTab.UpdateCombatState(data.State)

			task.spawn(function()
				for _, line in ipairs(lines) do
					if string.find(line, "used <b>") or string.find(line, "%- Hit ") then
						if string.find(line, "dodged!") or string.find(line, "missed!") then SFXManager.Play("CombatDodge")
						elseif string.find(line, "Blocked") then SFXManager.Play("CombatBlock")
						elseif string.find(line, "damage to") or string.find(line, "dealt") then SFXManager.Play("CombatHit")
						else SFXManager.Play("CombatUtility") end

						task.spawn(function()
							task.wait(0.05)
							if string.find(line, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
							if string.find(line, "(Stunned!)", 1, true) or string.find(line, "stunning") or string.find(line, "halt") then SFXManager.Play("CombatStun") end
							if string.find(string.lower(line), "survived on willpower") then SFXManager.Play("CombatWillpower") end
						end)

						if string.find(line, "damage to") or string.find(line, "dealt") then
							task.spawn(function()
								local p = string.find(line, "(CRIT!)", 1, true) and 18 or 8
								local orig = UDim2.new(0.025, 0, 0, 0)
								for i = 1, 6 do 
									if rootFrame then
										local sf = rootFrame:FindFirstChildOfClass("ScrollingFrame")
										if sf then sf.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)) end
									end
									task.wait(0.04) 
								end
								if rootFrame then
									local sf = rootFrame:FindFirstChildOfClass("ScrollingFrame")
									if sf then sf.Position = orig end
								end
							end)
						end
						task.wait(0.3)
					elseif string.find(line, "Poison damage") or string.find(line, "Burn damage") or string.find(line, "bled for") or string.find(line, "Freeze damage") then
						SFXManager.Play("CombatHit")
						task.wait(0.3)
					end
				end

				if not isCurrentlySpectating then
					waitingLabel.Visible = false
					skillsContainer.Visible = true
					ArenaTab.RenderSkills(data.State)
				end
			end)
		else
			ArenaTab.UpdateCombatState(data.State)
			if not isCurrentlySpectating then
				waitingLabel.Visible = false
				skillsContainer.Visible = true
				ArenaTab.RenderSkills(data.State)
			end
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Match Over!"
		skillsContainer.Visible = false; spectatorPanel.Visible = false; waitingLabel.Visible = false; AddLog(data.LogMsg)

		if data.Result == "Win" then SFXManager.Play("CombatVictory") elseif data.Result == "Loss" then SFXManager.Play("CombatDefeat") end

		task.delay(4, function()
			viewDefault.Visible = true; viewSetup.Visible = false; viewHosting.Visible = false
			hostCard.Visible = true; lobbyCard.Visible = true; activeMatchesCard.Visible = true
			combatCard.Visible = false
			Network.ArenaAction:FireServer("RequestLobbies")
		end)
	end
end

function ArenaTab.UpdateCombatState(state)
	if state.EnemyTeam and #state.EnemyTeam == 1 then
		selectedTargetId = state.EnemyTeam[1].UserId
	end

	local allyTemplate = uiTemplates:WaitForChild("ArenaAllyHPBarTemplate")
	local enemyTemplate = uiTemplates:WaitForChild("ArenaEnemyHPBarTemplate")

	local function ProcessHPBar(pData, container, isEnemy)
		local barId = tostring(pData.UserId)
		if not activeHPBars[barId] then
			local tpl = isEnemy and enemyTemplate or allyTemplate
			local barInfo = CreateHPBarRef(tpl, container, isEnemy, pData.UserId == state.MyId)

			activeHPBars[barId] = barInfo

			if isEnemy and not isCurrentlySpectating then
				barInfo.Wrapper.MouseButton1Click:Connect(function()
					if (tonumber(pData.HP) or 0) > 0 then
						SFXManager.Play("Click")
						selectedTargetId = pData.UserId
						ArenaTab.UpdateCombatState(state)
					end
				end)
			end
		end

		local bar = activeHPBars[barId]

		local hp = tonumber(pData.HP) or 0
		local maxHp = tonumber(pData.MaxHP) or 1
		local stam = tonumber(pData.Stamina) or 0
		local nrg = tonumber(pData.StandEnergy) or 0
		local imm = tonumber(pData.StunImmunity) or 0
		local cImm = tonumber(pData.ConfusionImmunity) or 0

		bar.Label.Text = (pData.Name or "Unknown") .. (hp <= 0 and " (DEAD)" or "")
		bar.Fill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
		bar.Txt.Text = math.floor(hp) .. "/" .. math.floor(maxHp)

		bar.Status.Text = BuildStatusString(pData.Statuses)
		bar.Status.Visible = true

		if imm > 0 then
			bar.Immunity.Text = "Stun Immune: " .. imm .. " Turns"
			bar.Immunity.Visible = true
		else
			bar.Immunity.Visible = false
		end

		if cImm > 0 then
			bar.CImmunity.Text = "Confuse Immune: " .. cImm .. " Turns"
			bar.CImmunity.Visible = true
		else
			bar.CImmunity.Visible = false
		end

		if isEnemy then
			if pData.UserId == selectedTargetId then
				bar.Stroke.Color = Color3.fromRGB(255, 215, 0); bar.Stroke.Thickness = 2
			else
				bar.Stroke.Color = bar.DefaultColor; bar.Stroke.Thickness = 1
			end
		end

		if pData.UserId == state.MyId then
			resourceLabel.Text = "STAMINA: " .. math.floor(stam) .. " | ENERGY: " .. math.floor(nrg)
		end
	end

	local validIds = {}
	for _, p in ipairs(state.MyTeam) do validIds[tostring(p.UserId)] = true; ProcessHPBar(p, allyContainer, false) end
	for _, p in ipairs(state.EnemyTeam) do validIds[tostring(p.UserId)] = true; ProcessHPBar(p, enemyContainer, true) end

	if isCurrentlySpectating then resourceLabel.Text = "SPECTATOR MODE" end

	for barId, barData in pairs(activeHPBars) do
		if not validIds[barId] then
			barData.Wrapper:Destroy(); activeHPBars[barId] = nil
		end
	end
end

function ArenaTab.RenderSkills(state)
	for _, child in pairs(skillsContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	local myState = nil
	for _, p in ipairs(state.MyTeam) do if p.UserId == state.MyId then myState = p break end end
	if not myState then return end

	if myState.HP <= 0 then
		skillsContainer.Visible = false
		waitingLabel.Text = "You have been defeated. Spectating..."
		waitingLabel.Visible = true
		return
	end

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

		local origStroke = btn:WaitForChild("UIStroke")

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
						isConfirmingFlee = true; btn.Text = "Confirm Flee?"; btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
						task.delay(3, function() if isConfirmingFlee and btn and btn.Parent then isConfirmingFlee = false; btn.Text = sk.Name; btn.BackgroundColor3 = c end end)
					else
						cachedTooltipMgr.Hide(); Network.ArenaAction:FireServer("Attack", {SkillName = sk.Name}) 
					end
				end)
			else
				local isWarning = false
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					if not selectedTargetId and sk.Data.Effect ~= "Heal" and sk.Data.Effect ~= "Buff_Random" and string.sub(sk.Data.Effect or "", 1, 5) ~= "Buff_" and sk.Data.Effect ~= "Block" and sk.Data.Effect ~= "Rest" then
						if not isWarning then
							isWarning = true; local oldText = btn.Text; btn.Text = "Select Target First!"; origStroke.Color = Color3.fromRGB(255, 50, 50)
							task.delay(1.5, function() if btn and btn.Parent then isWarning = false; btn.Text = oldText; origStroke.Color = Color3.fromRGB(255, 215, 0) end end)
						end
					else
						cachedTooltipMgr.Hide(); Network.ArenaAction:FireServer("Attack", {SkillName = sk.Name, TargetUserId = selectedTargetId}) 
					end
				end)
			end
		end
	end
end

return ArenaTab