-- @ScriptType: ModuleScript
local GiftManager = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local standClaimModal, styleClaimModal
local btnScActive, btnScSlot1, btnScSlot2, btnScSlot3, btnScSlot4, btnScSlot5, btnScDeny
local btnStyleActive, btnStyleSlot1, btnStyleSlot2, btnStyleSlot3, btnStyleDeny
local scTitle, styleTitle

local promptQueue = {}
local isPromptShowing = false

local function FormatSlotLabel(title, occupantName)
	local safeName = (occupantName == "None" or not occupantName or occupantName == "") and "Empty" or occupantName
	return title .. "\n[" .. safeName .. "]"
end

local processQueue

function GiftManager.Init(parentGui)
	standClaimModal = parentGui:WaitForChild("StandClaimModal")
	local scContainer = standClaimModal:WaitForChild("ScContainer")
	local scBtnGrid = scContainer:WaitForChild("ScBtnGrid")
	scTitle = scContainer:WaitForChild("ScTitle")

	btnScActive = scBtnGrid:WaitForChild("BtnScActive")
	btnScSlot1 = scBtnGrid:WaitForChild("BtnScSlot1")
	btnScSlot2 = scBtnGrid:WaitForChild("BtnScSlot2")
	btnScSlot3 = scBtnGrid:WaitForChild("BtnScSlot3")
	btnScSlot4 = scBtnGrid:WaitForChild("BtnScSlot4")
	btnScSlot5 = scBtnGrid:WaitForChild("BtnScSlot5")
	btnScDeny = scBtnGrid:WaitForChild("BtnScDeny")

	local function SendClaimStand(slot)
		SFXManager.Play("Click")
		Network.ShopAction:FireServer("ClaimShopStand", slot)
		standClaimModal.Visible = false
		isPromptShowing = false
		processQueue()
	end

	btnScActive.MouseButton1Click:Connect(function() SendClaimStand("Active") end)
	btnScSlot1.MouseButton1Click:Connect(function() SendClaimStand("Slot1") end)
	btnScSlot2.MouseButton1Click:Connect(function() SendClaimStand("Slot2") end)
	btnScSlot3.MouseButton1Click:Connect(function() SendClaimStand("Slot3") end)
	btnScSlot4.MouseButton1Click:Connect(function() SendClaimStand("Slot4") end)
	btnScSlot5.MouseButton1Click:Connect(function() SendClaimStand("Slot5") end)
	btnScDeny.MouseButton1Click:Connect(function() SendClaimStand("Deny") end)

	styleClaimModal = parentGui:WaitForChild("StyleClaimModal")
	local styleContainer = styleClaimModal:WaitForChild("StyleContainer")
	local styleBtnGrid = styleContainer:WaitForChild("StyleBtnGrid")
	styleTitle = styleContainer:WaitForChild("StyleTitle")

	btnStyleActive = styleBtnGrid:WaitForChild("BtnStyleActive")
	btnStyleSlot1 = styleBtnGrid:WaitForChild("BtnStyleSlot1")
	btnStyleSlot2 = styleBtnGrid:WaitForChild("BtnStyleSlot2")
	btnStyleSlot3 = styleBtnGrid:WaitForChild("BtnStyleSlot3")
	btnStyleDeny = styleBtnGrid:WaitForChild("BtnStyleDeny")

	local function SendClaimStyle(slot)
		SFXManager.Play("Click")
		Network.ShopAction:FireServer("ClaimShopStyle", slot)
		styleClaimModal.Visible = false
		isPromptShowing = false
		processQueue()
	end

	btnStyleActive.MouseButton1Click:Connect(function() SendClaimStyle("Active") end)
	btnStyleSlot1.MouseButton1Click:Connect(function() SendClaimStyle("Slot1") end)
	btnStyleSlot2.MouseButton1Click:Connect(function() SendClaimStyle("Slot2") end)
	btnStyleSlot3.MouseButton1Click:Connect(function() SendClaimStyle("Slot3") end)
	btnStyleDeny.MouseButton1Click:Connect(function() SendClaimStyle("Deny") end)
end

processQueue = function()
	if isPromptShowing or #promptQueue == 0 then return end

	local nextData = table.remove(promptQueue, 1)
	isPromptShowing = true

	local ls = player:FindFirstChild("leaderstats")
	local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

	if nextData.StandName then
		scTitle.Text = "GIFT RECEIVED: " .. nextData.StandName
		btnScActive.Text = FormatSlotLabel("Active", nextData.Active)
		btnScSlot1.Text = FormatSlotLabel("Slot 1", nextData.Slot1)
		btnScSlot2.Text = FormatSlotLabel("Slot 2", nextData.Slot2)
		btnScSlot3.Text = FormatSlotLabel("Slot 3", nextData.Slot3)
		btnScSlot4.Text = FormatSlotLabel("Slot 4 (Pres. 15)", nextData.Slot4)
		btnScSlot5.Text = FormatSlotLabel("Slot 5 (Pres. 30)", nextData.Slot5)

		btnScSlot2.Visible = player:GetAttribute("HasStandSlot2") == true
		btnScSlot3.Visible = player:GetAttribute("HasStandSlot3") == true
		btnScSlot4.Visible = prestige >= 15
		btnScSlot5.Visible = prestige >= 30

		standClaimModal.Visible = true
		SFXManager.Play("BuyPass")

	elseif nextData.StyleName then
		styleTitle.Text = "GIFT RECEIVED: " .. nextData.StyleName
		btnStyleActive.Text = FormatSlotLabel("Active", nextData.Active)
		btnStyleSlot1.Text = FormatSlotLabel("Slot 1", nextData.Slot1)
		btnStyleSlot2.Text = FormatSlotLabel("Slot 2", nextData.Slot2)
		btnStyleSlot3.Text = FormatSlotLabel("Slot 3", nextData.Slot3)

		btnStyleSlot2.Visible = player:GetAttribute("HasStyleSlot2") == true
		btnStyleSlot3.Visible = player:GetAttribute("HasStyleSlot3") == true

		styleClaimModal.Visible = true
		SFXManager.Play("BuyPass")
	end
end

function GiftManager.ShowClaimPrompt(data)
	if data.StandName and data.StyleName then
		local standData = table.clone(data)
		standData.StyleName = nil

		local styleData = table.clone(data)
		styleData.StandName = nil

		table.insert(promptQueue, standData)
		table.insert(promptQueue, styleData)
	else
		table.insert(promptQueue, data)
	end

	processQueue()
end

return GiftManager