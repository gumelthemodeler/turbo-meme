-- @ScriptType: ModuleScript
local DungeonTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))

local menuContainer, menuFrame
local combatUI
local activeFighters = {}
local rootFrame, forceTabFocus, cachedTooltipMgr
local resourceLabel, waveLabel

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-"
}

local StatusDescs = {
	Stun = "Cannot move or act.",
	Poison = "Takes damage every turn.",
	Burn = "Takes damage every turn.",
	Bleed = "Takes damage every turn.",
	Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.",
	Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.",
	Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.",
	Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.",
	Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance."
}

local dungeonList = {
	{ Id = 1, Name = "Phantom Blood Dungeon", Req = 5 },
	{ Id = 2, Name = "Battle Tendency Dungeon", Req = 6 },
	{ Id = 3, Name = "Stardust Crusaders Dungeon", Req = 7 },
	{ Id = 4, Name = "Diamond is Unbreakable Dungeon", Req = 8 },
	{ Id = 5, Name = "Golden Wind Dungeon", Req = 9 },
	{ Id = 6, Name = "Stone Ocean Dungeon", Req = 10 },
	{ Id = "Endless", Name = "Endless Dungeon", Req = 15 }
}

local currentLog = ""
local function AddLog(text, append)
	if append then
		currentLog = currentLog .. "\n" .. text
	else
		currentLog = text
	end
	if combatUI then combatUI:Log(currentLog) end
end

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		if f.InfoArea and f.InfoArea:FindFirstChild("NameLabel") then
			f.InfoArea.NameLabel.Text = name
		end
	end
	local f = activeFighters[fKey]
	f:UpdateHealth(hp, maxHp)

	local currentStatuses = {}
	if statuses then
		for eff, duration in pairs(statuses) do
			if duration and duration > 0 then
				currentStatuses[eff] = true
				f:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
			end
		end
	end
	for eff, _ in pairs(StatusIcons) do
		if not currentStatuses[eff] then
			f:RemoveStatus(eff)
		end
	end

	local hasStunImmunity = (immunities and immunities.Stun and immunities.Stun > 0)
	if hasStunImmunity then
		f:SetCooldown("StunImmunity", "STN", tostring(immunities.Stun), "Immune to Stun effects.")
	else
		f:RemoveCooldown("StunImmunity")
	end

	local hasConfImmunity = (immunities and immunities.Confusion and immunities.Confusion > 0)
	if hasConfImmunity then
		f:SetCooldown("ConfImmunity", "CNF", tostring(immunities.Confusion), "Immune to Confusion effects.")
	else
		f:RemoveCooldown("ConfImmunity")
	end
end

function DungeonTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0.95, 0, 0.95, 0)
	menuContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	menuContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	menuContainer.ZIndex = 30
	menuContainer.Parent = parentFrame

	local mcCorner = Instance.new("UICorner")
	mcCorner.CornerRadius = UDim.new(0, 12)
	mcCorner.Parent = menuContainer

	local mcStroke = Instance.new("UIStroke")
	mcStroke.Color = Color3.fromRGB(90, 50, 120)
	mcStroke.Thickness = 2
	mcStroke.Parent = menuContainer

	menuFrame = Instance.new("ScrollingFrame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 1, 0)
	menuFrame.BackgroundTransparency = 1
	menuFrame.BorderSizePixel = 0
	menuFrame.ScrollBarThickness = 6
	menuFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	menuFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	menuFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	menuFrame.ZIndex = 31
	menuFrame.Parent = menuContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 15)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = menuFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 15)
	listPadding.PaddingBottom = UDim.new(0, 15)
	listPadding.Parent = menuFrame

	local dungeonUIElements = {}

	for _, dInfo in ipairs(dungeonList) do
		local row = Instance.new("Frame")
		row.Name = dInfo.Name
		row.Size = UDim2.new(0.95, 0, 0, 100)
		row.BackgroundColor3 = Color3.fromRGB(45, 25, 65)
		row.ZIndex = 32
		row.Parent = menuFrame

		local rowGrad = Instance.new("UIGradient")
		rowGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 85)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 15, 50))
		}
		rowGrad.Rotation = 45
		rowGrad.Parent = row

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(255, 215, 50)
		rowStroke.Thickness = 2
		rowStroke.Parent = row

		local strokeGrad = Instance.new("UIGradient")
		strokeGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
		}
		strokeGrad.Rotation = 45
		strokeGrad.Parent = rowStroke

		local infoContainer = Instance.new("Frame")
		infoContainer.Size = UDim2.new(0.7, 0, 1, 0)
		infoContainer.BackgroundTransparency = 1
		infoContainer.ZIndex = 33
		infoContainer.Parent = row

		local infoLayout = Instance.new("UIListLayout")
		infoLayout.FillDirection = Enum.FillDirection.Vertical
		infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
		infoLayout.Padding = UDim.new(0, 4)
		infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		infoLayout.Parent = infoContainer

		local infoPadding = Instance.new("UIPadding")
		infoPadding.PaddingLeft = UDim.new(0, 15)
		infoPadding.Parent = infoContainer

		local title = Instance.new("TextLabel")
		title.Name = "TitleLabel"
		title.Size = UDim2.new(1, 0, 0.35, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = Color3.fromRGB(255, 220, 80)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = dInfo.Name
		title.ZIndex = 34
		title.Parent = infoContainer

		local titleUic = Instance.new("UITextSizeConstraint")
		titleUic.MaxTextSize = 22
		titleUic.MinTextSize = 14
		titleUic.Parent = title

		local status = Instance.new("TextLabel")
		status.Name = "StatusLabel"
		status.Size = UDim2.new(1, 0, 0.25, 0)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamMedium
		status.TextColor3 = Color3.fromRGB(200, 200, 200)
		status.RichText = true
		status.TextScaled = true
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.Text = "<font color='#AAAAAA'>Status:</font> Checking Requirements..."
		status.ZIndex = 34
		status.Parent = infoContainer

		local statusUic = Instance.new("UITextSizeConstraint")
		statusUic.MaxTextSize = 16
		statusUic.MinTextSize = 10
		statusUic.Parent = status

		local reward = Instance.new("TextLabel")
		reward.Name = "RewardLabel"
		reward.Size = UDim2.new(1, 0, 0.25, 0)
		reward.BackgroundTransparency = 1
		reward.Font = Enum.Font.GothamMedium
		reward.TextColor3 = Color3.fromRGB(180, 180, 180)
		reward.RichText = true
		reward.TextScaled = true
		reward.TextXAlignment = Enum.TextXAlignment.Left
		reward.Text = "<font color='#AAAAAA'>Rewards:</font> Loading..."
		reward.ZIndex = 34
		reward.Parent = infoContainer

		local rewardUic = Instance.new("UITextSizeConstraint")
		rewardUic.MaxTextSize = 14
		rewardUic.MinTextSize = 10
		rewardUic.Parent = reward

		local playBtn = Instance.new("TextButton")
		playBtn.Name = "PlayBtn"
		playBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
		playBtn.Position = UDim2.new(0.96, 0, 0.5, 0)
		playBtn.AnchorPoint = Vector2.new(1, 0.5)
		playBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
		playBtn.Font = Enum.Font.GothamBold
		playBtn.TextColor3 = Color3.new(1, 1, 1)
		playBtn.TextScaled = true
		playBtn.Text = "PLAY"
		playBtn.ZIndex = 34
		playBtn.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = playBtn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(255, 215, 50)
		btnStroke.Thickness = 2
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnStroke.Parent = playBtn

		local btnUic = Instance.new("UITextSizeConstraint")
		btnUic.MaxTextSize = 24
		btnUic.MinTextSize = 12
		btnUic.Parent = playBtn

		playBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
			if pObj and pObj.Value >= dInfo.Req then
				Network:WaitForChild("DungeonAction"):FireServer("StartDungeon", dInfo.Id)
			end
		end)

		dungeonUIElements[dInfo.Id] = {Row = row, Title = title, Status = status, Reward = reward, Btn = playBtn, Info = dInfo}
	end

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10)
		if pObj then
			local prestige = pObj:WaitForChild("Prestige", 10)
			local function updateLocks()
				local pVal = prestige and prestige.Value or 0
				for id, data in pairs(dungeonUIElements) do
					data.Title.Text = data.Info.Name

					if data.Info.Id == "Endless" then
						local hs = player:GetAttribute("EndlessHighScore") or 0
						data.Status.Text = "<font color='#AAAAAA'>High Score:</font> <font color='#55FF55'>Floor " .. hs .. "</font>"
						data.Reward.Text = "<font color='#AAAAAA'>Milestone Reward:</font> <font color='#FF55FF'>Rokakaka</font> every 10 floors."
					else
						local cleared = player:GetAttribute("DungeonClear_Part" .. data.Info.Id)
						if cleared then
							data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#55FF55'>Cleared</font>"
							data.Reward.Text = "<font color='#AAAAAA'>Rewards:</font> Massive Item Pool & XP/Yen"
						else
							data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#FF5555'>Uncleared</font>"
							data.Reward.Text = "<font color='#AAAAAA'>First Time Clear:</font> <font color='#FF55FF'>Rokakaka</font>"
						end
					end

					if pVal >= data.Info.Req then
						data.Btn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
						data.Btn.Text = "PLAY"
						data.Btn.TextColor3 = Color3.new(1,1,1)
						data.Btn.Active = true
						data.Btn.AutoButtonColor = true
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "??"
						data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Btn.Active = false
						data.Btn.AutoButtonColor = false
						data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
					end
				end
			end

			if prestige then
				prestige.Changed:Connect(updateLocks)
			end
			player:GetAttributeChangedSignal("EndlessHighScore"):Connect(updateLocks)
			for i = 1, 6 do player:GetAttributeChangedSignal("DungeonClear_Part" .. i):Connect(updateLocks) end
			updateLocks()
		end
	end)

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.Visible = false
	combatUI.MainFrame.ZIndex = 40

	waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveLabel"
	waveLabel.Size = UDim2.new(0.3, 0, 0, 20)
	waveLabel.Position = UDim2.new(0.5, 0, 0, -22)
	waveLabel.AnchorPoint = Vector2.new(0.5, 0)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Font = Enum.Font.GothamBlack
	waveLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	waveLabel.TextScaled = true
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center
	waveLabel.Text = "Floor 1"
	waveLabel.ZIndex = 42
	waveLabel.Parent = combatUI.MainFrame

	local wUic = Instance.new("UITextSizeConstraint")
	wUic.MaxTextSize = 18
	wUic.MinTextSize = 10
	wUic.Parent = waveLabel

	resourceLabel = Instance.new("TextLabel")
	resourceLabel.Name = "ResourceLabel"
	resourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Font = Enum.Font.GothamBold
	resourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	resourceLabel.TextScaled = true
	resourceLabel.Text = ""
	resourceLabel.LayoutOrder = 2
	resourceLabel.ZIndex = 42
	resourceLabel.Parent = combatUI.ContentContainer

	local resUic = Instance.new("UITextSizeConstraint")
	resUic.MaxTextSize = 18
	resUic.MinTextSize = 10
	resUic.Parent = resourceLabel
end

function DungeonTab.RenderSkills(battleData)
	if not battleData then return end
	combatUI:ClearAbilities()

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then
			if battleData.IsEndless and s.Effect == "Flee" then continue end
			table.insert(valid, {Name = n, Data = s}) 
		end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))

		local currentCooldown = battleData.Player.Cooldowns and battleData.Player.Cooldowns[sk.Name] or 0
		local disabled = battleData.Player.Stamina < (sk.Data.StaminaCost or 0) or battleData.Player.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0

		local btnText = (currentCooldown > 0) and (sk.Name .. " (" .. currentCooldown .. ")") or sk.Name

		local cb = function()
			if disabled then return end
			SFXManager.Play("Click")
			cachedTooltipMgr.Hide()
			Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name)
		end

		if sk.Name == "Flee" then cb = nil end

		local btn = combatUI:AddAbility(btnText, disabled and Color3.fromRGB(35, 25, 45) or c, cb)

		if disabled then
			btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
		else
			if sk.Name == "Flee" then
				local isConfirmingFlee = false
				btn.MouseButton1Click:Connect(function() 
					if not disabled then
						SFXManager.Play("Click")
						if not isConfirmingFlee then
							isConfirmingFlee = true
							btn.Text = "Confirm Flee?"
							btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
							task.delay(3, function()
								if isConfirmingFlee and btn and btn.Parent then
									isConfirmingFlee = false
									btn.Text = sk.Name
									btn.BackgroundColor3 = c
								end
							end)
						else
							cachedTooltipMgr.Hide()
							Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function DungeonTab.UpdateDungeon(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		menuContainer.Visible = false
		combatUI.MainFrame.Visible = true
		combatUI.AbilitiesArea.Visible = true

		AddLog(data.LogMsg or "", false)
		waveLabel.Text = data.WaveStr or "Floor 1"
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

		if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
		elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
		elseif data.DidHit then SFXManager.Play("CombatHit")
		else SFXManager.Play("CombatUtility") end

		task.spawn(function()
			task.wait(0.05) 
			if string.find(data.LogMsg, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
			if string.find(data.LogMsg, "(Stunned!)", 1, true) or string.find(data.LogMsg, "stunning") or string.find(data.LogMsg, "halt") then SFXManager.Play("CombatStun") end
			if string.find(string.lower(data.LogMsg), "survived on willpower") then SFXManager.Play("CombatWillpower") end
		end)

		if data.DidHit then
			task.spawn(function()
				local p = data.ShakeType == "Heavy" and 18 or (data.ShakeType == "Light" and 3 or 8)
				for i = 1, 6 do 
					local offsetX = math.random(-p, p)
					local offsetY = math.random(-p, p)
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
			end)
		end

	elseif status == "WaveComplete" then
		combatUI.AbilitiesArea.Visible = true
		waveLabel.Text = data.WaveStr or "Floor ?"
		AddLog("<font color='#55FF55'>Enemy Defeated!</font>\n" .. (data.LogMsg or ""), true)
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			f.Frame:Destroy()
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>DUNGEON " .. status:upper() .. "!</font>", true)

		if status == "Victory" and data.Drops then
			AddLog("<font color='#55FF55'>+" .. (data.Drops.XP or 0) .. " XP, +¥" .. (data.Drops.Yen or 0) .. ".</font>", true)
			if data.Drops.Items and #data.Drops.Items > 0 then 
				AddLog("<font color='#FFFF55'>Loot Secured: " .. table.concat(data.Drops.Items, ", ") .. "</font>", true) 
			end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You fled the dungeon, forfeiting all progress.</font>", true)
		end

		task.delay(4, function() 
			combatUI.MainFrame.Visible = false
			menuContainer.Visible = true
		end)
	end

	if data and data.Battle then
		resourceLabel.Text = "STAMINA: " .. math.floor(data.Battle.Player.Stamina) .. " | ENERGY: " .. math.floor(data.Battle.Player.StandEnergy)

		SyncFighter("Player", true, "Player", data.Battle.Player.Name, player.UserId, data.Battle.Player.HP, data.Battle.Player.MaxHP, data.Battle.Player.Statuses, {Stun=data.Battle.Player.StunImmunity, Confusion=data.Battle.Player.ConfusionImmunity})
		if data.Battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Player.Name .. " (KO)"
		end

		if data.Battle.Enemy then
			SyncFighter("Enemy", false, "Enemy", data.Battle.Enemy.Name, "", data.Battle.Enemy.HP, data.Battle.Enemy.MaxHP, data.Battle.Enemy.Statuses, {Stun=data.Battle.Enemy.StunImmunity, Confusion=data.Battle.Enemy.ConfusionImmunity})
			if data.Battle.Enemy.HP <= 0 and activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Enemy.Name .. " (KO)"
			end
		else
			if activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:Destroy()
				activeFighters["Enemy"] = nil
			end
		end

		if data.Battle.Ally then
			SyncFighter("Ally", true, "Ally", data.Battle.Ally.Name, "", data.Battle.Ally.HP, data.Battle.Ally.MaxHP, data.Battle.Ally.Statuses, {Stun=data.Battle.Ally.StunImmunity, Confusion=data.Battle.Ally.ConfusionImmunity})
			if data.Battle.Ally.HP <= 0 and activeFighters["Ally"] then
				activeFighters["Ally"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Ally.Name .. " (KO)"
			end
		else
			if activeFighters["Ally"] then
				activeFighters["Ally"].Frame:Destroy()
				activeFighters["Ally"] = nil
			end
		end
	end
end

function DungeonTab.SystemMessage(msg) AddLog("" .. msg .. "", true) end

return DungeonTab