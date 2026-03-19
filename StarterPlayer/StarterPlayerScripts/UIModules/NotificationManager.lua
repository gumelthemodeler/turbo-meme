-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local NotificationManager = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notificationContainer

function NotificationManager.Init(parentGui)
	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0.8, 0, 0.8, 0)
	notificationContainer.Position = UDim2.new(0.5, 0, 0.05, 0)
	notificationContainer.AnchorPoint = Vector2.new(0.5, 0)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.ZIndex = 50
	notificationContainer.Parent = parentGui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(350, math.huge)
	sizeConstraint.Parent = notificationContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = notificationContainer
end

function NotificationManager.Show(message)
	if not notificationContainer then return end

	local notifFrame = Instance.new("Frame")
	notifFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	notifFrame.BackgroundTransparency = 1
	notifFrame.Size = UDim2.new(1, 0, 0, 0)
	notifFrame.ClipsDescendants = true
	notifFrame.ZIndex = 51
	notifFrame.Parent = notificationContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notifFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 50)
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = notifFrame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.RichText = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 16
	textLabel.TextWrapped = true
	textLabel.TextTransparency = 1
	textLabel.Text = message
	textLabel.ZIndex = 52
	textLabel.Parent = notifFrame

	local textPad = Instance.new("UIPadding")
	textPad.PaddingLeft = UDim.new(0, 8)
	textPad.PaddingRight = UDim.new(0, 8)
	textPad.Parent = textLabel

	local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundTransparency = 0.05
	})
	local strokeIn = TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0})
	local textIn = TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 0})

	tweenIn:Play()
	strokeIn:Play()
	textIn:Play()

	task.delay(4, function()
		if not notifFrame or not notifFrame.Parent then return end

		local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		})
		local strokeOut = TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1})
		local textOut = TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1})

		tweenOut:Play()
		strokeOut:Play()
		textOut:Play()

		tweenOut.Completed:Connect(function()
			notifFrame:Destroy()
		end)
	end)
end

return NotificationManager