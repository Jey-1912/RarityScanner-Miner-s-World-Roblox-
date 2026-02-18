-- CounterWidget.lua (ENGLISH)
local UserInputService = game:GetService("UserInputService")

local Widget = {}
Widget.__index = Widget

function Widget.new()
	local self = setmetatable({}, Widget)
	self.Gui = nil
	self.Minimized = false
	self.Dragging = false
	self.DragStart = nil
	self.StartPos = nil
	return self
end

local function makeGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BlocksFoundWidget"
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, 220, 0, 70)
	frame.Position = UDim2.new(0, 20, 0, 120)
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -80, 0, 24)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Blocks Found"
	title.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(1, -20, 0, 24)
	value.Position = UDim2.new(0, 10, 0, 34)
	value.Font = Enum.Font.Gotham
	value.TextSize = 16
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Text = "0"
	value.Parent = frame

	local minimize = Instance.new("TextButton")
	minimize.Name = "Minimize"
	minimize.Size = UDim2.new(0, 28, 0, 28)
	minimize.Position = UDim2.new(1, -36, 0, 8)
	minimize.Font = Enum.Font.GothamBold
	minimize.TextSize = 16
	minimize.Text = "_"
	minimize.Parent = frame

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.new(0, 28, 0, 28)
	close.Position = UDim2.new(1, -68, 0, 8)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.Text = "X"
	close.Parent = frame

	return gui
end

function Widget:Create(parentGui: PlayerGui)
	if self.Gui then return end
	self.Gui = makeGui()
	self.Gui.Parent = parentGui

	local frame = self.Gui.Main
	local minimize = frame.Minimize
	local close = frame.Close

	-- Minimize
	minimize.MouseButton1Click:Connect(function()
		self.Minimized = not self.Minimized
		if self.Minimized then
			frame.Size = UDim2.new(0, 220, 0, 40)
			frame.Value.Visible = false
			minimize.Text = "+"
		else
			frame.Size = UDim2.new(0, 220, 0, 70)
			frame.Value.Visible = true
			minimize.Text = "_"
		end
	end)

	-- Close (destroy widget)
	close.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	-- Dragging (drag by clicking anywhere on the frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.Dragging = true
			self.DragStart = input.Position
			self.StartPos = frame.Position
		end
	end)

	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.Dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not self.Dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - self.DragStart
			frame.Position = UDim2.new(
				self.StartPos.X.Scale, self.StartPos.X.Offset + delta.X,
				self.StartPos.Y.Scale, self.StartPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Widget:SetCount(n: number)
	if not self.Gui then return end
	self.Gui.Main.Value.Text = tostring(n)
end

function Widget:Destroy()
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
end

return Widget
