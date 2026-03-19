-- @ScriptType: ModuleScript
local UpdatesTab = {}

function UpdatesTab.Init(parentFrame, tooltipMgr)
	local mainScroll = parentFrame:WaitForChild("MainScroll")
	local mainList = mainScroll:WaitForChild("MainList")
	local logCard = mainScroll:WaitForChild("LogCard")
	local logText = logCard:WaitForChild("LogText")

	local separator = "\n\n<font color='#777777'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</font>\n\n"

	local v1_8 = [[
	<b><font color='#FFD700'>v1.8 - Gangs & QoL Update (March 16th)</font></b>

	<font color='#55FF55'>[+]</font> <b>Gang Overhaul:</b> Added Gang Emblems, Mottos, and collaborative Orders for loot, treasury, and rep rewards.
	<font color='#55FF55'>[+]</font> <b>Gang Infrastructure:</b> Buildings (Armory, HQ, etc.) now provide passive bonuses and are unlocked via Gang Level.
	<font color='#55FF55'>[+]</font> <b>Gang Management:</b> Redesigned menu (Info/Upgrades/Orders) and added recruitment Prestige requirements.
	<font color='#55FF55'>[+]</font> <b>Roll Security:</b> Added Stand/Trait Locking to prevent rolling past targets. New Auto-Roll gamepass added.
	<font color='#55FF55'>[+]</font> <b>Physical Gamepasses:</b> Gamepasses can now be purchased as tradeable items via the Gift Menu.
	<font color='#55FF55'>[+]</font> <b>New Stand:</b> Added King Crimson Requiem as an evolvable stand.
	<font color='#55FF55'>[+]</font> <b>SBR Scaling:</b> SBR rewards now scale by player count. Servers with 5 or fewer players receive reduced rewards.
	<font color='#55FF55'>[+]</font> <b>QoL & Fixes:</b> Added stat breakdowns to leaderboard hover, fixed renaming bugs, and enforced stat caps.
	
	Use code <b><font color='#FF55FF'>GANGSUPD</font></b> and <b><font color='#FF55FF'>250KVISITS</font></b> for free rewards!]]
	
	local v1_7 = [[
	<b><font color='#FFD700'>v1.7 - Steel Ball Run Update PART 2 (March 13th)</font></b>

	<font color='#55FF55'>[+]</font> <b>New Gamemode:</b> The Steel Ball Run hourly gamemode is here! Participate to earn massive free rewards, including mythical items.
	<font color='#55FF55'>[+]</font> <b>Roster Expansion:</b> Added The World: High Voltage and 7 more unique Part-7 Stands!
	<font color='#55FF55'>[+]</font> <b>Rebalances:</b> The World & Star Platinum have been promoted to Mythical/Boss Stand tier.
	<font color='#55FF55'>[+]</font> <b>Style Economy:</b> Added Fighting Style Storage slots (Starts with 1 slot). Styles can now be securely traded, and claiming them from shops/gifts now features a dedicated slot menu.]]

	local v1_6 = [[
	<b><font color='#FFD700'>v1.6 - Steel Ball Run Update PART 1 (March 10th)</font></b>

	<font color='#55FF55'>[+]</font> <b>Part 7 Expanded:</b> Added a new PART 7 extension to story mode featuring harder enemies!
	<font color='#55FF55'>[+]</font> <b>New Stands:</b> Added 16 NEW stands from Part 7, obtainable exclusively through the Saint's Corpse Part.
	<font color='#55FF55'>[+]</font> <b>Heaven & Requiem:</b> Added The World: Over Heaven and Star Platinum: Over Heaven.
	<font color='#55FF55'>[+]</font> <b>New Combat Styles:</b> Added Spin, Golden Spin, and the Ultimate Lifeform styles.]]

	local v1_5 = [[
	<b><font color='#FFD700'>v1.5 - Requiem Update (March 7th)</font></b>

	<font color='#55FF55'>[+]</font> <b>World Boss System:</b> A massive threat now spawns every hour at XX:00! Engage in a 10-turn damage race to earn rewards scaled by your performance (+1% Drop Chance per 100k Damage).
	<font color='#55FF55'>[+]</font> <b>Requiem Arrives:</b> Gold Experience Requiem and Silver Chariot Requiem have been added!
	<font color='#55FF55'>[+]</font> <b>15 New Stands:</b> The roster has expanded significantly with 15 new playable Stands, each with unique skill sets!]]

	local v1_4 = [[
	<b><font color='#FFD700'>v1.4 - Combat Overhaul (March 5th)</font></b>

	<font color='#55FF55'>[+]</font> <b>Combat Rework:</b> Completely rebuilt the combat engine for smoother, more dynamic battles!
	<font color='#55FF55'>[+]</font> <b>Abilities Overhauled:</b> All Stand abilities have been completely overhauled. Barrages are now true multi-hit attacks!
	<font color='#55FF55'>[+]</font> <b>New Traits & Statuses:</b> Added multiple new Stand Traits and diverse Status Effects (Debuffs, Freeze, Bleed, etc.) to spice up gameplay.]]

	local v1_3 = [[
	<b><font color='#FFD700'>v1.3 - Multiplayer Update (March 4th)</font></b>

	<font color='#55FF55'>[+]</font> <b>Raid Bosses:</b> Party up with up to 4 players to challenge massive bosses! Featuring dynamic scaling, Mythical drops, and a new Raid Wins leaderboard.
	<font color='#55FF55'>[+]</font> <b>Gangs System:</b> Form a Gang for 500k Yen! Includes a Reputation system with global bonuses, a shared Treasury, and exclusive Gang leaderboards.
	<font color='#55FF55'>[+]</font> <b>New Arena Modes:</b> 2v2 and 4v4 group combat is now live!]]

	local v1_2 = [[
	<b><font color='#FFD700'>v1.2 - Prestige Update (March 3rd)</font></b>

	<font color='#55FF55'>[+]</font> <b>Dungeons & Endless Mode:</b> Reaching Prestige 5+ unlocks new Gauntlet Dungeons and Endless mode.
	<font color='#55FF55'>[+]</font> <b>Player Trading:</b> Securely trade items, Stands, and Yen.
	<font color='#55FF55'>[+]</font> <b>Universe Modifiers:</b> Prestiging applies random buffs/debuffs to your next run.]]

	logText.Text = v1_8 .. separator .. v1_7 .. separator .. v1_6 .. separator .. v1_5 .. separator .. v1_4 .. separator .. v1_3 .. separator .. v1_2

	mainList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		mainScroll.CanvasSize = UDim2.new(0, 0, 0, mainList.AbsoluteContentSize.Y + 30)
	end)
end

return UpdatesTab