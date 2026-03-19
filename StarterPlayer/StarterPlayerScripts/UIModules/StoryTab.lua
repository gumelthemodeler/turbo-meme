-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local StoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))

local combatUI
local activeFighters = {}
local buttonContainer
local randomEncounterBtn, storyEncounterBtn, prestigeBtn
local rootFrame, forceTabFocus
local modifierBubble
local cachedTooltipMgr = nil
local resourceLabel

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

function StoryTab.Init(parentFrame, tooltipMgr, focusFunc, passedModifierBubble)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc
	modifierBubble = passedModifierBubble

	if modifierBubble then
		modifierBubble.MouseEnter:Connect(function()
			local modStr = player:GetAttribute("UniverseModifier") or "None"
			local tooltipStr = "<b><font color='#FFFFFF'>Active Modifiers</font></b>\n____________________\n\n"

			if modStr == "None" or modStr == "" then
				tooltipStr = tooltipStr .. "<b><font color='#FFFFFF'>None</font></b>\nThe universe is normal.\n"
			else
				local mods = string.split(modStr, ",")
				for _, m in ipairs(mods) do
					local mData = GameData.UniverseModifiers[m]
					if mData then
						tooltipStr = tooltipStr .. "<b><font color='"..(mData.Color or "#FFFFFF").."'>"..m.."</font></b>\n" .. mData.Description .. "\n\n"
					end
				end
			end
			cachedTooltipMgr.Show(tooltipStr)
		end)
		modifierBubble.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
	end

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.LayoutOrder = 1
	combatUI.AbilitiesArea.Visible = false

	resourceLabel = Instance.new("TextLabel")
	resourceLabel.Name = "ResourceLabel"
	resourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Font = Enum.Font.GothamBold
	resourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	resourceLabel.TextScaled = true
	resourceLabel.Text = ""
	resourceLabel.LayoutOrder = 2 
	resourceLabel.ZIndex = 22
	resourceLabel.Parent = combatUI.ContentContainer

	local resUic = Instance.new("UITextSizeConstraint")
	resUic.MaxTextSize = 18
	resUic.MinTextSize = 10
	resUic.Parent = resourceLabel

	buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, 0, 0.31, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.LayoutOrder = 4 
	buttonContainer.ZIndex = 22
	buttonContainer.Parent = combatUI.ContentContainer

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Padding = UDim.new(0, 15)
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Parent = buttonContainer

	local function makeBtn(name, text)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0.28, 0, 0.5, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 235, 130)
		btn.TextScaled = true
		btn.ZIndex = 23
		btn.Parent = buttonContainer

		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0, 8)
		uic.Parent = btn

		local str = Instance.new("UIStroke")
		str.Color = Color3.fromRGB(90, 50, 120)
		str.Thickness = 2
		str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		str.Parent = btn

		local ts = Instance.new("UITextSizeConstraint")
		ts.MaxTextSize = 22
		ts.MinTextSize = 10
		ts.Parent = btn

		return btn
	end

	prestigeBtn = makeBtn("PrestigeBtn", "Prestige")
	prestigeBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	prestigeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
	prestigeBtn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(200, 50, 50)
	prestigeBtn.LayoutOrder = 0
	prestigeBtn.Visible = false

	randomEncounterBtn = makeBtn("RandomEncounterBtn", "Random Encounter")
	randomEncounterBtn.LayoutOrder = 1

	storyEncounterBtn = makeBtn("StoryEncounterBtn", "Story Encounter")
	storyEncounterBtn.LayoutOrder = 2

	randomEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageRandom") end)
	storyEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageStory") end)
	prestigeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.PrestigeEvent:FireServer() end)

	local function UpdateStoryUI()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		local currentMission = player:GetAttribute("CurrentMission") or 1

		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		if modifierBubble then
			if prestige > 0 and parentFrame.Visible then modifierBubble.Visible = true else modifierBubble.Visible = false end
		end

		if currentPart >= 8 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = false
			prestigeBtn.Visible = true
		elseif currentPart == 7 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = true
		else
			randomEncounterBtn.Visible = true
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = false
		end

		local partData = EnemyData.Parts[currentPart]
		if partData then
			local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
			if currentMission > #missionTable then
				storyEncounterBtn.Text = "Story Encounter"
			elseif missionTable and missionTable[currentMission] then 
				storyEncounterBtn.Text = "Story: " .. missionTable[currentMission].Name 
			else 
				storyEncounterBtn.Text = "Story Encounter" 
			end
		end
	end

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("CurrentPart"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("CurrentMission"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("UniverseModifier"):Connect(UpdateStoryUI)

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 5)
		if pObj then pObj:WaitForChild("Prestige", 5).Changed:Connect(UpdateStoryUI) end
	end)

	UpdateStoryUI()
end

function StoryTab.RenderSkills(battleData)
	if not battleData then return end
	combatUI:ClearAbilities()

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then table.insert(valid, {Name = n, Data = s}) end
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
			Network.CombatAction:FireServer("Attack", {SkillName = sk.Name})
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
							Network.CombatAction:FireServer("Attack", {SkillName = sk.Name}) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function StoryTab.UpdateCombat(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		buttonContainer.Visible = false
		combatUI.AbilitiesArea.Visible = true
		resourceLabel.Visible = true

		AddLog(data.LogMsg or "", false)
		StoryTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

		if string.find(data.LogMsg, "dodged!") then 
			SFXManager.Play("CombatDodge")
		elseif string.find(data.LogMsg, "Blocked") then 
			SFXManager.Play("CombatBlock")
		elseif data.DidHit then 
			SFXManager.Play("CombatHit")
		else 
			SFXManager.Play("CombatUtility") 
		end

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
					-- Absolute pixel offset applied safely 
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
			end)
		end

	elseif status == "WaveComplete" then
		buttonContainer.Visible = false
		combatUI.AbilitiesArea.Visible = true
		StoryTab.RenderSkills(data.Battle)

		AddLog("<font color='#55FF55'>WAVE CLEARED! +" .. (data.XP or 0) .. " XP, +¥" .. (data.Yen or 0) .. ".</font>", true)
		if data.Items and #data.Items > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(data.Items, ", ") .. "</font>", true) end
		AddLog("\n" .. (data.LogMsg or ""), true)

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		StoryTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false
		resourceLabel.Visible = false

		for fKey, f in pairs(activeFighters) do
			f.Frame:Destroy()
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>" .. status:upper() .. "!</font>", true)

		if status == "Victory" then
			AddLog("<font color='#55FF55'>+" .. (data.XP or 0) .. " XP, +¥" .. (data.Yen or 0) .. ".</font>", true)
			if data.Items and #data.Items > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(data.Items, ", ") .. "</font>", true) end
			if data.Battle and data.Battle.Context and data.Battle.Context.IsStoryMission then AddLog("<font color='#FFD700'>MISSION COMPLETE!</font>", true) end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You safely escaped.</font>", true)
		end
		task.delay(1.5, function() buttonContainer.Visible = true end)
	end

	if data and data.Battle then
		resourceLabel.Text = "STAMINA: " .. math.floor(data.Battle.Player.Stamina) .. " | ENERGY: " .. math.floor(data.Battle.Player.StandEnergy)

		SyncFighter("Player", true, "Player", data.Battle.Player.Name, player.UserId, data.Battle.Player.HP, data.Battle.Player.MaxHP, data.Battle.Player.Statuses, {Stun=data.Battle.Player.StunImmunity, Confusion=data.Battle.Player.ConfusionImmunity})
		if data.Battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Player.Name .. " (KO)"
		end

		SyncFighter("Enemy", false, "Enemy", data.Battle.Enemy.Name, "", data.Battle.Enemy.HP, data.Battle.Enemy.MaxHP, data.Battle.Enemy.Statuses, {Stun=data.Battle.Enemy.StunImmunity, Confusion=data.Battle.Enemy.ConfusionImmunity})

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

function StoryTab.SystemMessage(msg) AddLog("" .. msg .. "", true) end

return StoryTab