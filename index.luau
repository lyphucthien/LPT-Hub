local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThienHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Window
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 780, 0, 500)
main.Position = UDim2.new(0.5, -390, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

-- Top bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 100, 1, 0)
title.Position = UDim2.new(0, 22, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LPT Hub"
title.TextColor3 = Color3.fromRGB(225, 225, 225)
title.TextSize = 18
title.Font = Enum.Font.GothamMedium
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- By Ly Phuc Thien
local author = Instance.new("TextLabel")
author.Size = UDim2.new(0, 180, 1, 0)
author.Position = UDim2.new(0, 122, 0, 0)
author.BackgroundTransparency = 1author.Text = "by Ly Phuc Thien"
author.TextColor3 = Color3.fromRGB(145, 150, 155)
author.TextSize = 13
author.Font = Enum.Font.Gotham
author.TextXAlignment = Enum.TextXAlignment.Left
author.Parent = topBar

-- Minimize
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 45, 0, 40)
minimize.Position = UDim2.new(1, -145, 0, 10)
minimize.BackgroundTransparency = 1
minimize.Text = "—"
minimize.TextColor3 = Color3.fromRGB(200, 200, 200)
minimize.TextSize = 22
minimize.Font = Enum.Font.Gotham
minimize.Parent = topBar

-- Maximize
local maximize = Instance.new("TextButton")
maximize.Size = UDim2.new(0, 45, 0, 40)
maximize.Position = UDim2.new(1, -100, 0, 10)
maximize.BackgroundTransparency = 1
maximize.Text = "□"
maximize.TextColor3 = Color3.fromRGB(200, 200, 200)
maximize.TextSize = 20
maximize.Font = Enum.Font.Gotham
maximize.Parent = topBar

-- Close
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 45, 0, 40)
close.Position = UDim2.new(1, -55, 0, 10)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextColor3 = Color3.fromRGB(220, 220, 220)
close.TextSize = 26
close.Font = Enum.Font.Gotham
close.Parent = topBar

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 220, 1, -60)
sidebar.Position = UDim2.new(0, 0, 0, 60)
sidebar.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
sidebar.BackgroundTransparency = 0.15
sidebar.BorderSizePixel = 0
sidebar.Parent = main

-- Menu button
local menuButton = Instance.new("TextButton")
menuButton.Size = UDim2.new(1, -20, 0, 55)
menuButton.Position = UDim2.new(0, 10, 0, 20)
menuButton.BackgroundColor3 = Color3.fromRGB(45, 52, 60)
menuButton.BackgroundTransparency = 0.15
menuButton.BorderSizePixel = 0
menuButton.Text = "☰   Menu"
menuButton.TextColor3 = Color3.fromRGB(235, 235, 235)
menuButton.TextSize = 16
menuButton.Font = Enum.Font.GothamMedium
menuButton.TextXAlignment = Enum.TextXAlignment.Left
menuButton.Parent = sidebar

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuButton

-- Blue indicator
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 3, 0, 35)
indicator.Position = UDim2.new(0, 0, 0.5, -17)
indicator.BackgroundColor3 = Color3.fromRGB(80, 190, 255)
indicator.BorderSizePixel = 0
indicator.Parent = menuButton

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = indicator

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -220, 1, -60)
content.Position = UDim2.new(0, 220, 0, 60)
content.BackgroundTransparency = 1
content.Parent = main

-- Page title
local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -40, 0, 60)
pageTitle.Position = UDim2.new(0, 25, 0, 20)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "Menu"
pageTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
pageTitle.TextSize = 34
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = content

-- Card
local card = Instance.new("Frame")
card.Size = UDim2.new(1, -50, 0, 90)
card.Position = UDim2.new(0, 25, 0, 90)
card.BackgroundColor3 = Color3.fromRGB(48, 55, 62)
card.BackgroundTransparency = 0.15
card.BorderSizePixel = 0
card.Parent = content

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 8)
cardCorner.Parent = card

-- Card text
local cardTitle = Instance.new("TextLabel")
cardTitle.Size = UDim2.new(1, -30, 0, 30)
cardTitle.Position = UDim2.new(0, 15, 0, 12)
cardTitle.BackgroundTransparency = 1
cardTitle.Text = "Welcome"
cardTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
cardTitle.TextSize = 18
cardTitle.Font = Enum.Font.GothamMedium
cardTitle.TextXAlignment = Enum.TextXAlignment.Left
cardTitle.Parent = card

local cardDescription = Instance.new("TextLabel")
cardDescription.Size = UDim2.new(1, -30, 0, 25)
cardDescription.Position = UDim2.new(0, 15, 0, 45)
cardDescription.BackgroundTransparency = 1
cardDescription.Text = "Welcome to Thiện Hub"
cardDescription.TextColor3 = Color3.fromRGB(160, 165, 170)
cardDescription.TextSize = 14
cardDescription.Font = Enum.Font.Gotham
cardDescription.TextXAlignment = Enum.TextXAlignment.Left
cardDescription.Parent = card

-- Close button
close.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Minimize
local minimized = false

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	for _, child in ipairs(main:GetChildren()) do
		if child ~= topBar then
			child.Visible = not minimized
		end
	end

	if minimized then
		main.Size = UDim2.new(0, 780, 0, 60)
	else
		main.Size = UDim2.new(0, 780, 0, 500)
	end
end)
