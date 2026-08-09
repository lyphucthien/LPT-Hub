local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThienHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--// Main Window
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 780, 0, 500)
main.Position = UDim2.new(0.5, -390, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(27, 33, 39)
main.BackgroundTransparency = 0.05
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

--// Top Bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Color3.fromRGB(24, 29, 34)
topBar.BackgroundTransparency = 0.08
topBar.BorderSizePixel = 0
topBar.Parent = main

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 105, 1, 0)
title.Position = UDim2.new(0, 22, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LPT Hub"
title.TextColor3 = Color3.fromRGB(225, 225, 225)
title.TextSize = 18
title.Font = Enum.Font.GothamMedium
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

--// Author
local author = Instance.new("TextLabel")
author.Size = UDim2.new(0, 170, 1, 0)
author.Position = UDim2.new(0, 110, 0, 0)
author.BackgroundTransparency = 1
author.Text = "by Ly Phuc Thien"
author.TextColor3 = Color3.fromRGB(135, 142, 150)
author.TextSize = 13
author.Font = Enum.Font.Gotham
author.TextXAlignment = Enum.TextXAlignment.Left
author.Parent = topBar

--// Top separator
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 1, -1)
separator.BackgroundColor3 = Color3.fromRGB(60, 67, 74)
separator.BackgroundTransparency = 0.5
separator.BorderSizePixel = 0
separator.Parent = topBar

--// Minimize
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 45, 0, 40)
minimize.Position = UDim2.new(1, -145, 0, 10)
minimize.BackgroundTransparency = 1
minimize.Text = "—"
minimize.TextColor3 = Color3.fromRGB(180, 185, 190)
minimize.TextSize = 20
minimize.Font = Enum.Font.Gotham
minimize.Parent = topBar

--// Maximize
local maximize = Instance.new("TextButton")
maximize.Size = UDim2.new(0, 45, 0, 40)
maximize.Position = UDim2.new(1, -100, 0, 10)
maximize.BackgroundTransparency = 1
maximize.Text = "□"
maximize.TextColor3 = Color3.fromRGB(180, 185, 190)
maximize.TextSize = 18
maximize.Font = Enum.Font.Gotham
maximize.Parent = topBar

--// Close
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 45, 0, 40)
close.Position = UDim2.new(1, -55, 0, 10)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextColor3 = Color3.fromRGB(210, 215, 220)
close.TextSize = 25
close.Font = Enum.Font.Gotham
close.Parent = topBar

--// Sidebar
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 220, 1, -60)
sidebar.Position = UDim2.new(0, 0, 0, 60)
sidebar.BackgroundColor3 = Color3.fromRGB(23, 29, 34)
sidebar.BackgroundTransparency = 0.08
sidebar.BorderSizePixel = 0
sidebar.Parent = main

--// Sidebar right line
local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = Color3.fromRGB(55, 62, 69)
sideLine.BackgroundTransparency = 0.5
sideLine.BorderSizePixel = 0
sideLine.Parent = sidebar

--// Content
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -220, 1, -60)
content.Position = UDim2.new(0, 220, 0, 60)
content.BackgroundTransparency = 1
content.Parent = main

--// Pages
local pages = {}

local function createPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content

	pages[name] = page

	return page
end

local farmPage = createPage("Farm")
local serverPage = createPage("Server")
local hopPage = createPage("HopAuto")
local settingsPage = createPage("Settings")

--// Page title function
local function createPageTitle(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 0, 55)
	label.Position = UDim2.new(0, 25, 0, 15)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextSize = 34
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

--// Farm title
createPageTitle(farmPage, "Farm")

--// Trick card
local trick = Instance.new("Frame")
trick.Size = UDim2.new(1, -50, 0, 90)
trick.Position = UDim2.new(0, 25, 0, 75)
trick.BackgroundColor3 = Color3.fromRGB(48, 55, 62)
trick.BackgroundTransparency = 0.12
trick.BorderSizePixel = 0
trick.Parent = farmPage

local trickCorner = Instance.new("UICorner")
trickCorner.CornerRadius = UDim.new(0, 8)
trickCorner.Parent = trick

local trickTitle = Instance.new("TextLabel")
trickTitle.Size = UDim2.new(1, -30, 0, 25)
trickTitle.Position = UDim2.new(0, 15, 0, 12)
trickTitle.BackgroundTransparency = 1
trickTitle.Text = "Trick"
trickTitle.TextColor3 = Color3.fromRGB(220, 225, 230)
trickTitle.TextSize = 16
trickTitle.Font = Enum.Font.GothamMedium
trickTitle.TextXAlignment = Enum.TextXAlignment.Left
trickTitle.Parent = trick

local trickDescription = Instance.new("TextLabel")
trickDescription.Size = UDim2.new(1, -30, 0, 40)
trickDescription.Position = UDim2.new(0, 15, 0, 38)
trickDescription.BackgroundTransparency = 1
trickDescription.Text = "You find Auto Hop Boss or Auto Farm Boss?\nAuto Hop and Auto Farm Boss in Hop Auto Tab"
trickDescription.TextColor3 = Color3.fromRGB(140, 148, 156)
trickDescription.TextSize = 13
trickDescription.Font = Enum.Font.Gotham
trickDescription.TextXAlignment = Enum.TextXAlignment.Left
trickDescription.TextYAlignment = Enum.TextYAlignment.Top
trickDescription.Parent = trick

--// Toggle function
local function createToggle(parent, text, position, default)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -50, 0, 60)
	row.Position = position
	row.BackgroundColor3 = Color3.fromRGB(48, 55, 62)
	row.BackgroundTransparency = 0.12
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.new(0, 15, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 225, 230)
	label.TextSize = 15
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	-- Toggle background
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 54, 0, 28)
	toggle.Position = UDim2.new(1, -68, 0.5, -14)
	toggle.BackgroundColor3 = default
		and Color3.fromRGB(75, 190, 245)
		or Color3.fromRGB(65, 72, 78)
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.Parent = row

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	-- Circle
	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 22, 0, 22)
	circle.Position = default
		and UDim2.new(1, -25, 0.5, -11)
		or UDim2.new(0, 3, 0.5, -11)
	circle.BackgroundColor3 = Color3.fromRGB(220, 225, 230)
	circle.BorderSizePixel = 0
	circle.Parent = toggle

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local enabled = default

	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled

		if enabled then
			toggle.BackgroundColor3 = Color3.fromRGB(75, 190, 245)
			circle.Position = UDim2.new(1, -25, 0.5, -11)
		else
			toggle.BackgroundColor3 = Color3.fromRGB(65, 72, 78)
			circle.Position = UDim2.new(0, 3, 0.5, -11)
		end
	end)

	return row
end

--// Farm toggles
createToggle(
	farmPage,
	"Teleport to Fruits",
	UDim2.new(0, 25, 0, 175),
	false
)

createToggle(
	farmPage,
	"Teleport to Berry",
	UDim2.new(0, 25, 0, 245),
	true
)

--// Server Page
createPageTitle(serverPage, "Server")

local serverCard = Instance.new("Frame")
serverCard.Size = UDim2.new(1, -50, 0, 90)
serverCard.Position = UDim2.new(0, 25, 0, 85)
serverCard.BackgroundColor3 = Color3.fromRGB(48, 55, 62)
serverCard.BackgroundTransparency = 0.12
serverCard.BorderSizePixel = 0
serverCard.Parent = serverPage

local serverCorner = Instance.new("UICorner")
serverCorner.CornerRadius = UDim.new(0, 8)
serverCorner.Parent = serverCard

local serverText = Instance.new("TextLabel")
serverText.Size = UDim2.new(1, -30, 1, 0)
serverText.Position = UDim2.new(0, 15, 0, 0)
serverText.BackgroundTransparency = 1
serverText.Text = "Server\nManage server information here."
serverText.TextColor3 = Color3.fromRGB(210, 215, 220)
serverText.TextSize = 15
serverText.Font = Enum.Font.GothamMedium
serverText.TextXAlignment = Enum.TextXAlignment.Left
serverText.Parent = serverCard

--// Hop Auto Page
createPageTitle(hopPage, "Hop Auto")

createToggle(
	hopPage,
	"Auto Hop",
	UDim2.new(0, 25, 0, 85),
	false
)

createToggle(
	hopPage,
	"Auto Farm Boss",
	UDim2.new(0, 25, 0, 155),
	false
)

--// Settings Page
createPageTitle(settingsPage, "Settings")

createToggle(
	settingsPage,
	"UI Blur",
	UDim2.new(0, 25, 0, 85),
	false
)

createToggle(
	settingsPage,
	"Notifications",
	UDim2.new(0, 25, 0, 155),
	true
)

--// Sidebar button function
local currentPage = nil

local buttons = {}

local function createSidebarButton(text, icon, order, pageName)
	local button = Instance.new("TextButton")
	button.Name = pageName .. "Button"
	button.Size = UDim2.new(1, -20, 0, 52)
	button.Position = UDim2.new(0, 10, 0, 15 + ((order - 1) * 58))
	button.BackgroundColor3 = Color3.fromRGB(45, 52, 60)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = sidebar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 35, 1, 0)
	iconLabel.Position = UDim2.new(0, 12, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = Color3.fromRGB(175, 182, 188)
	iconLabel.TextSize = 19
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Parent = button

	-- Text
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -55, 1, 0)
	textLabel.Position = UDim2.new(0, 48, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(190, 195, 200)
	textLabel.TextSize = 15
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = button

	-- Blue indicator
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 3, 0, 32)
	indicator.Position = UDim2.new(0, 0, 0.5, -16)
	indicator.BackgroundColor3 = Color3.fromRGB(75, 190, 245)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = button

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator

	button.MouseEnter:Connect(function()
		if currentPage ~= pageName then
			button.BackgroundTransparency = 0.75
		end
	end)

	button.MouseLeave:Connect(function()
		if currentPage ~= pageName then
			button.BackgroundTransparency = 1
		end
	end)

	button.MouseButton1Click:Connect(function()

		for name, data in pairs(buttons) do
			data.button.BackgroundTransparency = 1
			data.indicator.Visible = false
			data.icon.TextColor3 = Color3.fromRGB(175, 182, 188)
			data.label.TextColor3 = Color3.fromRGB(190, 195, 200)
		end

		for name, page in pairs(pages) do
			page.Visible = false
		end

		currentPage = pageName

		button.BackgroundTransparency = 0.15
		indicator.Visible = true
		iconLabel.TextColor3 = Color3.fromRGB(220, 230, 235)
		textLabel.TextColor3 = Color3.fromRGB(235, 240, 245)

		pages[pageName].Visible = true
	end)

	buttons[pageName] = {
		button = button,
		indicator = indicator,
		icon = iconLabel,
		label = textLabel
	}

	return button
end

--// Sidebar buttons
createSidebarButton("Server", "▣", 1, "Server")
createSidebarButton("Hop Auto", "⌂", 2, "HopAuto")
createSidebarButton("Farm", "▱", 3, "Farm")
createSidebarButton("Settings", "⚙", 4, "Settings")

--// Default page = Farm
currentPage = "Farm"
farmPage.Visible = true

buttons["Farm"].button.BackgroundTransparency = 0.15
buttons["Farm"].indicator.Visible = true
buttons["Farm"].icon.TextColor3 = Color3.fromRGB(220, 230, 235)
buttons["Farm"].label.TextColor3 = Color3.fromRGB(235, 240, 245)

--// Close
close.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

--// Maximize
local maximized = false
local normalSize = UDim2.new(0, 780, 0, 500)
local normalPosition = UDim2.new(0.5, -390, 0.5, -250)

maximize.MouseButton1Click:Connect(function()
	maximized = not maximized

	if maximized then
		main.Size = UDim2.new(1, -40, 1, -40)
		main.Position = UDim2.new(0, 20, 0, 20)
	else
		main.Size = normalSize
		main.Position = normalPosition
	end
end)

--// Minimize
local minimized = false

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	sidebar.Visible = not minimized
	content.Visible = not minimized

	if minimized then
		main.Size = UDim2.new(0, 780, 0, 60)
	else
		if maximized then
			main.Size = UDim2.new(1, -40, 1, -40)
		else
			main.Size = normalSize
		end
	end
end)

--// Drag window
local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

topBar.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
