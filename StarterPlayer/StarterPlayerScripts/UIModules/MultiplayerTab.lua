-- @ScriptType: ModuleScript
local MultiplayerTab = {}

local player = game.Players.LocalPlayer
local UIModules = script.Parent
local GangsTab = require(UIModules:WaitForChild("GangsTab"))
local ArenaTab = require(UIModules:WaitForChild("ArenaTab"))
local RaidsTab = require(UIModules:WaitForChild("RaidsTab"))
local TradingTab = require(UIModules:WaitForChild("TradingTab"))
local LeaderboardTab = require(UIModules:WaitForChild("LeaderboardTab"))
local SBREventTab = require(UIModules:WaitForChild("SBREventTab"))

local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

function MultiplayerTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	local subNav = parentFrame:WaitForChild("SubNav")

	local gangsFrame = parentFrame:WaitForChild("GangsFrame")
	local arenaFrame = parentFrame:WaitForChild("ArenaFrame")
	local raidsFrame = parentFrame:WaitForChild("RaidsFrame")
	local tradeFrame = parentFrame:WaitForChild("TradeFrame")
	local lbFrame = parentFrame:WaitForChild("LbFrame")
	local sbrFrame = parentFrame:WaitForChild("SbrFrame")

	local sbrBtn = subNav:WaitForChild("SbrBtn")
	local sStroke = sbrBtn:WaitForChild("UIStroke")
	local gangBtn = subNav:WaitForChild("GangBtn")
	local gStroke = gangBtn:WaitForChild("UIStroke")
	local arenaBtn = subNav:WaitForChild("ArenaBtn")
	local aStroke = arenaBtn:WaitForChild("UIStroke")
	local raidBtn = subNav:WaitForChild("RaidBtn")
	local rStroke = raidBtn:WaitForChild("UIStroke")
	local tradeBtn = subNav:WaitForChild("TradeBtn")
	local tStroke = tradeBtn:WaitForChild("UIStroke")
	local lbBtn = subNav:WaitForChild("LbBtn")
	local lStroke = lbBtn:WaitForChild("UIStroke")

	local function ForceSubTabFocus(target)
		if switchTabFunc then switchTabFunc("Multiplayer") end

		gangsFrame.Visible = (target == "Gangs")
		arenaFrame.Visible = (target == "Arena")
		raidsFrame.Visible = (target == "Raids")
		tradeFrame.Visible = (target == "Trading")
		lbFrame.Visible = (target == "Leaderboards")
		sbrFrame.Visible = (target == "Event")

		local function toggleBtn(btn, stroke, isActive)
			btn.BackgroundColor3 = isActive and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
			btn.TextColor3 = isActive and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
			stroke.Color = isActive and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)
		end

		toggleBtn(gangBtn, gStroke, target == "Gangs")
		toggleBtn(arenaBtn, aStroke, target == "Arena")
		toggleBtn(raidBtn, rStroke, target == "Raids")
		toggleBtn(tradeBtn, tStroke, target == "Trading")
		toggleBtn(lbBtn, lStroke, target == "Leaderboards")
		toggleBtn(sbrBtn, sStroke, target == "Event")

		local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local pVal = pObj and pObj.Value or 0
		if pVal < 1 then
			if target ~= "Trading" then tradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150); tStroke.Color = Color3.fromRGB(80, 40, 100) end
			if target ~= "Raids" then raidBtn.TextColor3 = Color3.fromRGB(150, 150, 150); rStroke.Color = Color3.fromRGB(80, 40, 100) end
		end
	end

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local prestige = leaderstats:WaitForChild("Prestige", 10)
			if prestige then
				local function updateLocks()
					if prestige.Value < 1 then
						tradeBtn.Text = "🔒 TRADING"
						raidBtn.Text = "🔒 RAIDS"
						if not tradeFrame.Visible then tradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150); tStroke.Color = Color3.fromRGB(80, 40, 100) end
						if not raidsFrame.Visible then raidBtn.TextColor3 = Color3.fromRGB(150, 150, 150); rStroke.Color = Color3.fromRGB(80, 40, 100) end
					else
						tradeBtn.Text = "TRADING"
						raidBtn.Text = "RAIDS"
						if not tradeFrame.Visible then tradeBtn.TextColor3 = Color3.new(1,1,1); tStroke.Color = Color3.fromRGB(120, 60, 180) end
						if not raidsFrame.Visible then raidBtn.TextColor3 = Color3.new(1,1,1); rStroke.Color = Color3.fromRGB(120, 60, 180) end
					end
				end
				prestige.Changed:Connect(updateLocks)
				updateLocks()
			end
		end
	end)

	sbrBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Event") end)
	gangBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Gangs") end)
	arenaBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Arena") end)
	lbBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Leaderboards") end)

	local function TryOpenLockedTab(tabName)
		SFXManager.Play("Click") 
		local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		if not pObj or pObj.Value < 1 then
			NotificationManager.Show("<font color='#FF5555'>You must be Prestige 1 to unlock " .. tabName .. "!</font>")
			return
		end
		ForceSubTabFocus(tabName) 
	end

	raidBtn.MouseButton1Click:Connect(function() TryOpenLockedTab("Raids") end)
	tradeBtn.MouseButton1Click:Connect(function() TryOpenLockedTab("Trading") end)

	GangsTab.Init(gangsFrame, tooltipMgr)
	ArenaTab.Init(arenaFrame, tooltipMgr, function() ForceSubTabFocus("Arena") end)
	RaidsTab.Init(raidsFrame, tooltipMgr, function() ForceSubTabFocus("Raids") end)
	TradingTab.Init(tradeFrame, tooltipMgr, function() ForceSubTabFocus("Trading") end)
	LeaderboardTab.Init(lbFrame, tooltipMgr)
	SBREventTab.Init(sbrFrame, tooltipMgr, function() ForceSubTabFocus("Event") end)

	MultiplayerTab.HandleGangUpdate = GangsTab.HandleUpdate
	MultiplayerTab.HandleArenaUpdate = ArenaTab.HandleUpdate
	MultiplayerTab.HandleTradeUpdate = TradingTab.HandleUpdate
	MultiplayerTab.HandleRaidUpdate = RaidsTab.HandleUpdate
end

return MultiplayerTab