-- @ScriptType: ModuleScript
local SBREventTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local isStudio = RunService:IsStudio()
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local NotificationManager = require(script.Parent:WaitForChild("NotificationManager"))
local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local REROLL_ROBUX_PRODUCT_ID = 3554941196

local mainContainer
local lobbyContainer, raceContainer
local timerLbl, queueBtn, queueCountLbl
local horseNameLbl, speedValLbl, endValLbl, traitLbl
local upgSpeedBtn, upgEndBtn, upgTimerLbl
local rerollYenBtn, rerollRobuxBtn

local rRegionLbl, rDistLbl, rLogScroll
local pHPFill, pHPTxt, pName, _pWrap, pImmunity, pCImmunity, pStatus
local eHPFill, eHPTxt, eName, _eWrap, eImmunity, eCImmunity, eStatus
local combatResourceLabel, turnTimerLabel
local actionContainer, skillContainer, stamWrap, stamFill, stamTxt, rootRaceFrame
local pathBtns, safeBtn, restBtn, riskyBtn

local cachedTooltipMgr = nil
local currentDeadline = 0

local targetName1 = "Select"
local targetName2 = "Select"

local Names1 = {
	"Silver","Black","Golden","Midnight","Red","White","Blue","Crimson","Azure","Onyx","Ivory","Ruby","Sapphire","Emerald","Bronze","Copper","Scarlet","Violet",
	"Fast","Swift","Rapid","Lightning","Thunder","Storm","Wild","Blazing","Flying","Charging","Raging","Dashing","Soaring",
	"Brave","Noble","Savage","Fierce","Proud","Grand","Royal","Legendary","Mighty","Valiant","Heroic","Fearless",
	"Fire","Ice","Frost","Solar","Lunar","Iron","Steel","Ghost","Mystic","Holy","Dark","Light","Radiant","Cursed","Blessed","Cosmic","Astral","Arcane","Ancient",
	"Dire","Great","Alpha","Prime","Stormborn","Sunset","Dawn","Dusk","Mountain","Desert","Prairie",
	"Big","Tiny","Massive","Heavy","Thicc","Mini","Giga","Maximum","Ultra","Mega",
	"Slow","Fat","Angry","Derpy","Lazy","Confused","Suspicious","Goofy","Unhinged","Greasy","Wobbly","Crusty","Spicy","Bald","Dank","Certified", "Stupid"
}

local Names2 = {
	"Stallion","Mustang","Bronco","Hoof","Trotter","Galloper","Racer","Trailblazer",
	"Bullet","Runner","Dasher","Sprinter","Chaser","Hunter","Striker","Blade","Arrow","Spear","Crusher","Breaker",
	"Eagle","Falcon","Hawk","Wolf","Tiger","Lion","Bear","Dragon","Cobra","Panther",
	"Comet","Meteor","Nova","Eclipse","Hurricane","Cyclone","Blizzard","Tornado","Storm","Tempest",
	"Knight","Rider","Champ","Hero","Legend","Master","King","Outlaw","Bandit","Marshal",
	"Valkyrie","Phantom","Specter","Wanderer","Drifter","Seeker","Spirit","Fury","Flash",
	"Boi","Unit","Potato","Nugget","Goblin","Meatball","Gremlin","Grandpa","Chungus","Mogger","Goober","Creature","Thing","Lad","Beast", "Idiot", "Chud"
}

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

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local function AddRaceLog(msg)
	local logTemplate = uiTemplates:WaitForChild("LogLineTemplate")
	local line = logTemplate:Clone()
	line.Text = msg
	line.Parent = rLogScroll
	task.defer(function() rLogScroll.CanvasPosition = Vector2.new(0, rLogScroll.AbsoluteCanvasSize.Y) end)
end

local function BuildDropdownList(parentBtn, listFrame, dataTable)
	for _, c in ipairs(listFrame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("UIListLayout") then c:Destroy() end
	end

	local layout = Instance.new("UIListLayout", listFrame)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local options = {}
	for _, name in ipairs(dataTable) do table.insert(options, name) end
	table.sort(options)

	for i, opt in ipairs(options) do
		local b = Instance.new("TextButton", listFrame)
		b.Size = UDim2.new(1, -8, 0, 30)
		b.Position = UDim2.new(0, 4, 0, (i-1)*30)
		b.BackgroundTransparency = 1
		b.TextColor3 = Color3.new(1,1,1)
		b.Text = opt
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 12
		b.ZIndex = 51

		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			if parentBtn.Name == "Name1Drop" then targetName1 = opt else targetName2 = opt end
			parentBtn.Text = opt
			listFrame.Visible = false
		end)
	end

	listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 30)

	parentBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		listFrame.Visible = not listFrame.Visible
	end)
end

function SBREventTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame; cachedTooltipMgr = tooltipMgr

	lobbyContainer = mainContainer:WaitForChild("LobbyContainer")
	local dualContainer = lobbyContainer:WaitForChild("DualContainer")

	local stableCard = dualContainer:WaitForChild("StableCard")
	local queueCard = dualContainer:WaitForChild("QueueCard")

	local customNameFrame = stableCard:WaitForChild("CustomNameFrame")
	local n1Drop = customNameFrame:WaitForChild("Name1Drop")
	local n2Drop = customNameFrame:WaitForChild("Name2Drop")
	local setNameBtn = customNameFrame:WaitForChild("SetNameBtn")

	BuildDropdownList(n1Drop, n1Drop:WaitForChild("List"), Names1)
	BuildDropdownList(n2Drop, n2Drop:WaitForChild("List"), Names2)

	local function UpdatePassUI()
		if player:GetAttribute("HasHorseNamePass") then
			setNameBtn.Text = "Set Name"
			setNameBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			setNameBtn.Text = "Buy Pass (40 R$)"
			setNameBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		end
	end
	player:GetAttributeChangedSignal("HasHorseNamePass"):Connect(UpdatePassUI)
	UpdatePassUI()

	setNameBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if not player:GetAttribute("HasHorseNamePass") then
			MarketplaceService:PromptGamePassPurchase(player, 1749586333)
			return
		end

		if targetName1 == "Select" or targetName2 == "Select" then
			NotificationManager.Show("<font color='#FF5555'>Please select both name parts first!</font>")
			return
		end
		Network.SBRAction:FireServer("SetHorseName", {Name1 = targetName1, Name2 = targetName2})
	end)

	horseNameLbl = stableCard:WaitForChild("HorseNameLbl")
	traitLbl = stableCard:WaitForChild("TraitLbl")

	traitLbl.MouseEnter:Connect(function()
		local t = player:GetAttribute("HorseTrait") or "None"
		local desc = GameData.HorseTraits[t] or "No description available."
		local color = (t == "None") and "#AAAAAA" or "#FFD700"
		cachedTooltipMgr.Show("<b><font color='"..color.."'>" .. t .. "</font></b>\n____________________\n\n" .. desc)
	end)
	traitLbl.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	rerollYenBtn = stableCard:WaitForChild("RerollYenBtn")
	rerollRobuxBtn = stableCard:WaitForChild("RerollRobuxBtn")
	speedValLbl = stableCard:WaitForChild("SpeedValLbl")
	endValLbl = stableCard:WaitForChild("EndValLbl")
	upgSpeedBtn = stableCard:WaitForChild("UpgSpeedBtn")
	upgEndBtn = stableCard:WaitForChild("UpgEndBtn")
	upgTimerLbl = stableCard:WaitForChild("UpgTimerLbl")

	upgSpeedBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("UpgradeHorse", "Speed") end)
	upgEndBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("UpgradeHorse", "Endurance") end)
	rerollYenBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("RerollHorseYen") end)
	rerollRobuxBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); MarketplaceService:PromptProductPurchase(player, REROLL_ROBUX_PRODUCT_ID) end)

	timerLbl = queueCard:WaitForChild("TimerLbl")
	queueCountLbl = queueCard:WaitForChild("QueueCountLbl")
	queueBtn = queueCard:WaitForChild("QueueBtn")

	local inQueue = false
	queueBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); inQueue = not inQueue; queueBtn.Text = inQueue and "Leave Queue" or "Join Event Queue"; queueBtn.BackgroundColor3 = inQueue and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 150, 50); Network.SBRAction:FireServer("ToggleQueue")
	end)

	local function UpdateStableUI()
		horseNameLbl.Text = player:GetAttribute("HorseName") or "Unknown"
		traitLbl.Text = "Trait: " .. (player:GetAttribute("HorseTrait") or "None")

		local spd = player:GetAttribute("HorseSpeed") or 1
		local endur = player:GetAttribute("HorseEndurance") or 1
		speedValLbl.Text = "Speed: " .. spd .. "/100"
		endValLbl.Text = "Endurance: " .. endur .. "/100"

		local upgEnd = player:GetAttribute("HorseUpgradeEnd") or 0
		local isUpgrading = upgEnd > os.time()

		if spd >= 100 or isUpgrading then upgSpeedBtn.Visible = false else upgSpeedBtn.Visible = true end
		if endur >= 100 or isUpgrading then upgEndBtn.Visible = false else upgEndBtn.Visible = true end
	end

	player:GetAttributeChangedSignal("HorseName"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseSpeed"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseEndurance"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseTrait"):Connect(UpdateStableUI)
	UpdateStableUI()

	raceContainer = mainContainer:WaitForChild("RaceContainer")
	rootRaceFrame = raceContainer

	local rcv = raceContainer:WaitForChild("RaceCombatView")
	local topArea = rcv:WaitForChild("TopArea")

	rRegionLbl = topArea:WaitForChild("RegionLbl")
	rDistLbl = topArea:WaitForChild("DistLbl")

	_pWrap = topArea:WaitForChild("PlayerHPWrapper")
	pName = _pWrap:WaitForChild("NameLabel")
	local pBg = _pWrap:WaitForChild("Bg")
	pHPFill = pBg:WaitForChild("Fill")
	pHPTxt = pBg:WaitForChild("HpText")
	pStatus = _pWrap:WaitForChild("StatusLbl")
	pImmunity = _pWrap:WaitForChild("Immunity")
	pCImmunity = _pWrap:WaitForChild("CImmunity")

	_eWrap = topArea:WaitForChild("EnemyHPWrapper")
	_eWrap.Visible = false
	eName = _eWrap:WaitForChild("NameLabel")
	local eBg = _eWrap:WaitForChild("Bg")
	eHPFill = eBg:WaitForChild("Fill")
	eHPTxt = eBg:WaitForChild("HpText")
	eStatus = _eWrap:WaitForChild("StatusLbl")
	eImmunity = _eWrap:WaitForChild("Immunity")
	eCImmunity = _eWrap:WaitForChild("CImmunity")

	combatResourceLabel = topArea:WaitForChild("ResourceLabel")
	turnTimerLabel = topArea:FindFirstChild("TurnTimerLabel")
	if not turnTimerLabel then
		turnTimerLabel = Instance.new("TextLabel")
		turnTimerLabel.Name = "TurnTimerLabel"
		turnTimerLabel.Size = UDim2.new(1, -20, 0, 20)
		turnTimerLabel.Position = UDim2.new(0, 10, 0.05, 0)
		turnTimerLabel.BackgroundTransparency = 1
		turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		turnTimerLabel.Font = Enum.Font.GothamBlack
		turnTimerLabel.TextSize = 16
		turnTimerLabel.TextXAlignment = Enum.TextXAlignment.Right
		turnTimerLabel.Text = "Time Remaining: 15s"
		turnTimerLabel.Visible = false
		turnTimerLabel.Parent = topArea
	end

	pathBtns = rcv:WaitForChild("PathBtns")
	safeBtn = pathBtns:WaitForChild("SafeBtn")
	restBtn = pathBtns:WaitForChild("RestBtn")
	riskyBtn = pathBtns:WaitForChild("RiskyBtn")

	stamWrap = rcv:WaitForChild("StamWrap")
	local sBg = stamWrap:WaitForChild("Bg")
	stamFill = sBg:WaitForChild("Fill")
	stamTxt = sBg:WaitForChild("StamTxt")

	rLogScroll = rcv:WaitForChild("LogScroll")
	skillContainer = rcv:WaitForChild("SkillsContainer")

	local function SyncPlayerBox(pData, boxNum)
		if boxNum == 1 then
			pName.Text = pData.Name; pHPTxt.Text = math.floor(pData.HP) .. "/" .. math.floor(pData.MaxHP)
			pHPFill.Size = UDim2.new(math.clamp(pData.HP / pData.MaxHP, 0, 1), 0, 1, 0)
			pStatus.Text = BuildStatusString(pData.Statuses); pStatus.Visible = true
			pImmunity.Visible = (pData.StunImmunity or 0) > 0; pImmunity.Text = "Stun Immune: " .. (pData.StunImmunity or 0) .. " Turns"
			pCImmunity.Visible = (pData.ConfusionImmunity or 0) > 0; pCImmunity.Text = "Confuse Immune: " .. (pData.ConfusionImmunity or 0) .. " Turns"
			combatResourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		else
			_eWrap.Visible = true
			eName.Text = pData.Name; eHPTxt.Text = math.floor(pData.HP) .. "/" .. math.floor(pData.MaxHP)
			eHPFill.Size = UDim2.new(math.clamp(pData.HP / pData.MaxHP, 0, 1), 0, 1, 0)
			eStatus.Text = BuildStatusString(pData.Statuses); eStatus.Visible = true
			eImmunity.Visible = (pData.StunImmunity or 0) > 0; eImmunity.Text = "Stun Immune: " .. (pData.StunImmunity or 0) .. " Turns"
			eCImmunity.Visible = (pData.ConfusionImmunity or 0) > 0; eCImmunity.Text = "Confuse Immune: " .. (pData.ConfusionImmunity or 0) .. " Turns"
		end
	end

	local function RenderSkills(pData)
		for _, c in pairs(skillContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local valid = {}
		for n, s in pairs(SkillData.Skills) do
			if s.Requirement == "None" or s.Requirement == pData.Stand or s.Requirement == pData.Style or (s.Requirement == "AnyStand" and pData.Stand ~= "None") then table.insert(valid, {Name = n, Data = s}) end
		end
		table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

		local skillTemplate = uiTemplates:WaitForChild("SkillButtonTemplate")

		for _, sk in ipairs(valid) do
			local btn = skillTemplate:Clone()
			btn.Text = sk.Name
			btn.Parent = skillContainer

			local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
			btn.BackgroundColor3 = c

			btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
			btn.MouseLeave:Connect(cachedTooltipMgr.Hide)

			local cd = pData.Cooldowns and pData.Cooldowns[sk.Name] or 0
			if pData.Stamina < (sk.Data.StaminaCost or 0) or pData.StandEnergy < (sk.Data.EnergyCost or 0) or cd > 0 then
				btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45); btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
				if cd > 0 then btn.Text = sk.Name .. " ("..cd..")" end
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
								if isConfirmingFlee and btn and btn.Parent then
									isConfirmingFlee = false
									btn.Text = sk.Name
									btn.BackgroundColor3 = c
								end
							end)
						else
							cachedTooltipMgr.Hide()
							skillContainer.Visible = false 
							Network.SBRAction:FireServer("CombatAttack", sk.Name) 
						end
					end)
				else
					btn.MouseButton1Click:Connect(function() 
						SFXManager.Play("Click")
						cachedTooltipMgr.Hide()
						skillContainer.Visible = false 
						Network.SBRAction:FireServer("CombatAttack", sk.Name) 
					end)
				end
			end
		end
	end

	safeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("TakePath", "Safe") end)
	restBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("TakePath", "Rest") end)
	riskyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("TakePath", "Risky") end)

	local currentCycleTime = 1800
	task.spawn(function()
		while task.wait(1) do
			currentCycleTime = (currentCycleTime + 1) % 3600

			local upgEnd = player:GetAttribute("HorseUpgradeEnd") or 0
			if upgEnd > 0 then
				local left = upgEnd - os.time()
				if left > 0 then
					upgTimerLbl.Text = "Upgrading... " .. FormatTime(left)
					UpdateStableUI()
				else
					upgTimerLbl.Text = ""; UpdateStableUI()
				end
			else
				upgTimerLbl.Text = ""; UpdateStableUI()
			end

			if currentCycleTime < 1800 then
				timerLbl.Text = "RACE IN PROGRESS\n<font color='#FF5555'>" .. FormatTime(1800 - currentCycleTime) .. "</font> Left!"
				queueCountLbl.Text = "Event is currently active."

				if isStudio then
					queueBtn.Visible = true
					queueBtn.Text = "Force Join (Studio)"
					queueBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
				else
					queueBtn.Visible = false
				end
			else
				timerLbl.Text = "NEXT RACE IN\n<font color='#55FF55'>" .. FormatTime(3600 - currentCycleTime) .. "</font>"
				queueBtn.Visible = true
				queueBtn.Text = inQueue and "Leave Queue" or "Join Event Queue"
				queueBtn.BackgroundColor3 = inQueue and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 150, 50)
			end
		end
	end)

	task.spawn(function()
		while task.wait(0.2) do
			if currentDeadline > 0 and raceContainer.Visible then
				turnTimerLabel.Visible = true
				local remain = math.max(0, currentDeadline - os.time())
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			else
				turnTimerLabel.Visible = false
			end
		end
	end)

	Network.SBRUpdate.OnClientEvent:Connect(function(action, data)
		if action == "SyncTimer" then
			currentCycleTime = data
		elseif action == "SyncQueue" then
			queueCountLbl.Text = "Players in Queue: " .. data
		elseif action == "RaceStarted" then
			if focusFunc then focusFunc() end
			lobbyContainer.Visible = false; raceContainer.Visible = true
			currentDeadline = 0
			for _, c in pairs(rLogScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
			AddRaceLog("<font color='#FFD700'><b>THE RACE HAS BEGUN!</b></font>")
			rDistLbl.Text = "Distance: 0 / 10000m"
			rRegionLbl.Text = "Region: San Diego Beach"
			stamTxt.Text = "Horse Stamina: " .. data.MaxStamina .. "/" .. data.MaxStamina
			stamFill.Size = UDim2.new(1, 0, 1, 0)
			pName.Text = player.Name; pHPTxt.Text = "100%"; pHPFill.Size = UDim2.new(1,0,1,0)
			pStatus.Visible = false; pImmunity.Visible = false; pCImmunity.Visible = false
			_eWrap.Visible = false; pathBtns.Visible = true; skillContainer.Visible = false
			combatResourceLabel.Visible = false
			stamWrap.Visible = true

		elseif action == "PathResult" then
			AddRaceLog(data.Log)
			rDistLbl.Text = "Distance: " .. data.Dist .. " / 10000m"
			rRegionLbl.Text = "Region: " .. data.Region
			local maxS = stamTxt.Text:split("/")[2]
			stamTxt.Text = "Horse Stamina: " .. math.floor(data.Stam) .. "/" .. maxS
			stamFill.Size = UDim2.new(math.clamp(data.Stam / tonumber(maxS), 0, 1), 0, 1, 0)

		elseif action == "CombatStart" then
			AddRaceLog(data.LogMsg)
			currentDeadline = data.Deadline or 0
			pathBtns.Visible = false; skillContainer.Visible = true; combatResourceLabel.Visible = true
			stamWrap.Visible = false
			SyncPlayerBox(data.P1, 1); SyncPlayerBox(data.P2, 2)
			RenderSkills(data.P1)

		elseif action == "CombatTurn" then
			skillContainer.Visible = false
			currentDeadline = data.Deadline or 0
			AddRaceLog(data.LogMsg)
			SyncPlayerBox(data.P1, 1); SyncPlayerBox(data.P2, 2)

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
					local orig = UDim2.new(0.025, 0, 0, 0)
					for i = 1, 6 do rootRaceFrame.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)); task.wait(0.04) end
					rootRaceFrame.Position = orig
				end)
			end

		elseif action == "CombatUpdateState" then
			currentDeadline = data.Deadline or 0
			SyncPlayerBox(data.P1, 1); SyncPlayerBox(data.P2, 2)
			skillContainer.Visible = true; RenderSkills(data.P1)

		elseif action == "CombatEnd" then
			SFXManager.Play("CombatVictory")
			currentDeadline = 0
			AddRaceLog("<font color='#55FF55'><b>" .. data .. "</b></font>")
			pathBtns.Visible = true; skillContainer.Visible = false; _eWrap.Visible = false
			combatResourceLabel.Visible = false
			stamWrap.Visible = true

		elseif action == "Eliminated" then
			SFXManager.Play("CombatDefeat")
			currentDeadline = 0
			AddRaceLog("<font color='#FF5555'><b>" .. data .. " YOU HAVE BEEN ELIMINATED!</b></font>")
			pathBtns.Visible = false; skillContainer.Visible = false; _eWrap.Visible = false
			combatResourceLabel.Visible = false
			stamWrap.Visible = false
			inQueue = false
			task.delay(4, function() lobbyContainer.Visible = true; raceContainer.Visible = false end)

		elseif action == "Finished" then
			SFXManager.Play("CombatVictory")
			currentDeadline = 0
			AddRaceLog("<font color='#55FFFF'><b>YOU CROSSED THE FINISH LINE IN " .. data .. " PLACE!</b></font>")
			pathBtns.Visible = false; skillContainer.Visible = false; _eWrap.Visible = false
			combatResourceLabel.Visible = false
			stamWrap.Visible = false
			inQueue = false

		elseif action == "RaceEnded" then
			currentDeadline = 0
			AddRaceLog("<font color='#FFD700'><b>THE RACE IS OVER!</b></font>")
			pathBtns.Visible = false; skillContainer.Visible = false; _eWrap.Visible = false
			combatResourceLabel.Visible = false
			stamWrap.Visible = false
			inQueue = false
			task.delay(6, function() lobbyContainer.Visible = true; raceContainer.Visible = false end)
		end
	end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible then Network.SBRAction:FireServer("RequestSync") end
	end)
end

return SBREventTab