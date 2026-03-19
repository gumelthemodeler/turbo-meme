-- @ScriptType: ModuleScript
local TooltipManager = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local tooltip, tooltipText, sizeConstraint

function TooltipManager.Init(screenGui)
	tooltip = Instance.new("Frame")
	tooltip.Name = "TooltipFrame"
	tooltip.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
	tooltip.BackgroundTransparency = 0.05
	tooltip.BorderSizePixel = 0
	tooltip.AutomaticSize = Enum.AutomaticSize.XY
	tooltip.ZIndex = 100
	tooltip.Visible = false
	tooltip.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tooltip

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 50)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = tooltip

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = tooltip

	sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.Parent = tooltip

	tooltipText = Instance.new("TextLabel")
	tooltipText.Name = "TooltipText"
	tooltipText.BackgroundTransparency = 1
	tooltipText.RichText = true
	tooltipText.Font = Enum.Font.GothamMedium
	tooltipText.TextColor3 = Color3.fromRGB(220, 220, 220)
	tooltipText.TextSize = 14 
	tooltipText.TextWrapped = true
	tooltipText.TextXAlignment = Enum.TextXAlignment.Left
	tooltipText.TextYAlignment = Enum.TextYAlignment.Top
	tooltipText.AutomaticSize = Enum.AutomaticSize.XY
	tooltipText.ZIndex = 101
	tooltipText.Parent = tooltip

	game:GetService("RunService").RenderStepped:Connect(function()
		if tooltip.Visible then
			local viewport = workspace.CurrentCamera.ViewportSize

			local maxW = math.min(300, viewport.X * 0.85)
			sizeConstraint.MaxSize = Vector2.new(maxW, viewport.Y * 0.9)

			local tWidth = tooltip.AbsoluteSize.X
			local tHeight = tooltip.AbsoluteSize.Y

			local targetX = mouse.X + 15
			local targetY = mouse.Y + 15

			if targetX + tWidth > viewport.X then
				targetX = mouse.X - tWidth - 15
			end
			if targetY + tHeight > viewport.Y then
				targetY = mouse.Y - tHeight - 15
			end

			local maxX = math.max(5, viewport.X - tWidth - 5)
			local maxY = math.max(5, viewport.Y - tHeight - 5)

			targetX = math.clamp(targetX, 5, maxX)
			targetY = math.clamp(targetY, 5, maxY)

			tooltip.Position = UDim2.new(0, targetX, 0, targetY)
		end
	end)
end

function TooltipManager.Show(textStr)
	tooltipText.Text = textStr or ""
	tooltip.Visible = true
end

function TooltipManager.Hide()
	tooltip.Visible = false
end

function TooltipManager.GetItemTooltip(itemName)
	if ItemData.Equipment[itemName] then
		local eq = ItemData.Equipment[itemName]
		local text = "<b><font color='#FFD700'>" .. itemName .. "</font></b>\n<i>" .. eq.Slot .. "</i> | <font color='#AAAAAA'>" .. (eq.Rarity or "Common") .. "</font>\n"
		text ..= "____________________\n\n"
		for stat, val in pairs(eq.Bonus) do
			text ..= "<font color='#55FF55'>+" .. val .. " " .. stat:gsub("_", " ") .. "</font>\n"
		end
		return text
	elseif ItemData.Consumables[itemName] then
		local cons = ItemData.Consumables[itemName]
		local desc = type(cons) == "table" and cons.Description or tostring(cons)
		local rarity = type(cons) == "table" and cons.Rarity or "Common"
		return "<b><font color='#FFD700'>" .. itemName .. "</font></b> | <font color='#AAAAAA'>" .. rarity .. "</font>\n____________________\n\n" .. desc
	end
	return "Unknown item."
end

function TooltipManager.GetSkillTooltip(skillName)
	local skill = SkillData.Skills[skillName]
	if skill then
		local text = "<b><font color='#FFD700'>" .. skillName .. "</font></b> (" .. skill.Type .. ")\n"
		text = text .. "" .. (skill.Description or "No description.") .. "\n\n"
		if skill.Mult > 0 then text = text .. "Multiplier: " .. skill.Mult .. "x\n" end

		text = text .. "Cost: "
		if skill.StaminaCost == 0 and skill.EnergyCost == 0 then
			text = text .. "<font color='#55FF55'>Free</font>"
		else
			if skill.StaminaCost > 0 then text = text .. "<font color='#FFD700'>" .. skill.StaminaCost .. " Stamina </font>" end
			if skill.EnergyCost > 0 then text = text .. "<font color='#55FFFF'>" .. skill.EnergyCost .. " Energy</font>" end
		end

		if skill.Cooldown and skill.Cooldown > 0 then
			text = text .. "\nCooldown: <font color='#FF5555'>" .. skill.Cooldown .. " turns</font>"
		end

		return text
	end
	return "Unknown skill."
end

return TooltipManager