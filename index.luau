local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Test UI"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0, 40)
button.Position = UDim2.new(0.1, 0, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
button.Text = "Bấm vào đây"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Parent = frame

button.MouseButton1Click:Connect(function()
	button.Text = "Đã bấm!"
end)
