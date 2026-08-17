local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MOVEMENT_MODULE_URL = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/ChucNang.luau"

local Movement = nil
local movementLoadError = nil

local function loadMovementModule()
	if Movement then
		return Movement
	end

	local ok, result = pcall(function()
		return loadstring(game:HttpGet(MOVEMENT_MODULE_URL))()
	end)

	if ok and type(result) == "table" then
		Movement = result
		return Movement
	end

	movementLoadError = tostring(result)
	warn("[LPT Hub] Movement module failed to load:", movementLoadError)
	return nil
end

loadMovementModule()

--// PALETTE (more vibrant)
local COLORS = {
	Background = Color3.fromRGB(10, 11, 16),
	Surface = Color3.fromRGB(14, 15, 21),
	SurfaceLight = Color3.fromRGB(40, 44, 58),
	Card = Color3.fromRGB(34, 38, 50),
	Accent = Color3.fromRGB(168, 105, 245),   -- purple
	AccentB = Color3.fromRGB(236, 72, 153),   -- pink (gradient partner)
	Text = Color3.fromRGB(240, 241, 245),
	TextDim = Color3.fromRGB(150, 157, 170),
	Border = Color3.fromRGB(52, 56, 70),
	Danger = Color3.fromRGB(255, 92, 108),
	Online = Color3.fromRGB(52, 211, 153), -- xanh lá cho chấm trạng thái

	-- per-page accent colors
	PageServer = Color3.fromRGB(96, 165, 250),   -- blue
	PageHop = Color3.fromRGB(168, 105, 245),     -- purple
	PageFarm = Color3.fromRGB(74, 222, 128),     -- green
	PageSettings = Color3.fromRGB(251, 146, 60), -- orange
}

local function tween(obj, props, time, style)
	TweenService:Create(obj, TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad), props):Play()
end

local function applyGradient(guiObject, colorA, colorB, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 45
	gradient.Parent = guiObject
	return gradient
end

--// ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThienHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2147483647 -- số DisplayOrder cực lớn: luôn vẽ đè lên mọi ScreenGui khác

-- Ưu tiên parent vào layer ẩn của executor (không bị game Destroy/che),
-- nếu executor không hỗ trợ thì fallback qua CoreGui, cuối cùng mới PlayerGui.
local hiddenLayer = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())

if hiddenLayer then
	screenGui.Parent = hiddenLayer
else
	local placedInCoreGui = pcall(function()
		screenGui.Parent = game:GetService("CoreGui")
	end)

	if not placedInCoreGui then
		screenGui.Parent = playerGui
	end
end

if protect_gui then
	protect_gui(screenGui)
elseif syn and syn.protect_gui then
	syn.protect_gui(screenGui)
end

--// Main Window
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 780, 0, 500)
main.Position = UDim2.new(0.5, -390, 0.5, -250)
main.BackgroundColor3 = COLORS.Background
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Border
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.2
mainStroke.Parent = main
applyGradient(mainStroke, COLORS.Accent, COLORS.AccentB, 45)

--// Top Bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = COLORS.Surface
topBar.BorderSizePixel = 0
topBar.Parent = main

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 20)
topBarCorner.Parent = topBar

local topBarMask = Instance.new("Frame")
topBarMask.Name = "BottomMask"
topBarMask.Size = UDim2.new(1, 0, 0, 20)
topBarMask.Position = UDim2.new(0, 0, 1, -20)
topBarMask.BackgroundColor3 = COLORS.Surface
topBarMask.BorderSizePixel = 0
topBarMask.ZIndex = topBar.ZIndex
topBarMask.Parent = topBar

--// Title
local titleDot = Instance.new("Frame")
titleDot.Size = UDim2.new(0, 8, 0, 8)
titleDot.Position = UDim2.new(0, 20, 0.5, -4)
titleDot.BackgroundColor3 = COLORS.Online
titleDot.BorderSizePixel = 0
titleDot.ZIndex = 2
titleDot.Parent = topBar

local titleDotCorner = Instance.new("UICorner")
titleDotCorner.CornerRadius = UDim.new(1, 0)
titleDotCorner.Parent = titleDot

local titleDotPulse = Instance.new("Frame")
titleDotPulse.Size = UDim2.new(0, 8, 0, 8)
titleDotPulse.Position = UDim2.new(0.5, -4, 0.5, -4)
titleDotPulse.BackgroundColor3 = COLORS.Online
titleDotPulse.BackgroundTransparency = 0.3
titleDotPulse.BorderSizePixel = 0
titleDotPulse.ZIndex = 1
titleDotPulse.Parent = titleDot

local titleDotPulseCorner = Instance.new("UICorner")
titleDotPulseCorner.CornerRadius = UDim.new(1, 0)
titleDotPulseCorner.Parent = titleDotPulse

task.spawn(function()
	while titleDotPulse.Parent do
		titleDotPulse.Size = UDim2.new(0, 8, 0, 8)
		titleDotPulse.Position = UDim2.new(0.5, -4, 0.5, -4)
		titleDotPulse.BackgroundTransparency = 0.3
		tween(titleDotPulse, {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0.5, -11, 0.5, -11),
			BackgroundTransparency = 1,
		}, 1.1, Enum.EasingStyle.Quad)
		task.wait(1.1)
	end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 105, 1, 0)
title.Position = UDim2.new(0, 36, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LPT Hub"
title.TextColor3 = COLORS.Text
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

applyGradient(title, COLORS.Accent, COLORS.AccentB, 0)

--// Author
local author = Instance.new("TextLabel")
author.Size = UDim2.new(0, 170, 1, 0)
author.Position = UDim2.new(0, 120, 0, 0)
author.BackgroundTransparency = 1
author.Text = "by Ly Phuc Thien"
author.TextColor3 = COLORS.TextDim
author.TextSize = 11
author.Font = Enum.Font.Gotham
author.TextXAlignment = Enum.TextXAlignment.Left
author.Parent = topBar

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 1, -1)
separator.BackgroundColor3 = COLORS.Border
separator.BorderSizePixel = 0
separator.Parent = topBar

--// TOP RIGHT BUTTONS
local function topButton(name, xOffset, text, textSize)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 30, 0, 26)
	button.Position = UDim2.new(1, xOffset, 0.5, -13)
	button.BackgroundColor3 = COLORS.SurfaceLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.TextDim
	button.TextSize = textSize
	button.Font = Enum.Font.GothamMedium
	button.AutoButtonColor = false
	button.Parent = topBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local minimize = topButton("MinimizeButton", -110, "—", 13)
local maximize = topButton("MaximizeButton", -76, "", 0)
local close = topButton("CloseButton", -40, "×", 17)

local maxIcon = Instance.new("Frame")
maxIcon.Name = "MaxIcon"
maxIcon.Size = UDim2.new(0, 20, 0, 20)
maxIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
maxIcon.BackgroundTransparency = 1
maxIcon.BorderSizePixel = 0
maxIcon.Parent = maximize

local normalIcon = Instance.new("Frame")
normalIcon.Name = "NormalIcon"
normalIcon.Size = UDim2.new(0, 13, 0, 13)
normalIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
normalIcon.BackgroundTransparency = 1
normalIcon.BorderSizePixel = 0
normalIcon.Parent = maxIcon

local normalCorner = Instance.new("UICorner")
normalCorner.CornerRadius = UDim.new(0, 3)
normalCorner.Parent = normalIcon

local normalStroke = Instance.new("UIStroke")
normalStroke.Thickness = 1.5
normalStroke.Color = COLORS.TextDim
normalStroke.Parent = normalIcon

local restoreBack = Instance.new("Frame")
restoreBack.Name = "RestoreBack"
restoreBack.Size = UDim2.new(0, 11, 0, 11)
restoreBack.Position = UDim2.new(0, 6, 0, 2)
restoreBack.BackgroundTransparency = 1
restoreBack.BorderSizePixel = 0
restoreBack.Visible = false
restoreBack.ZIndex = 2
restoreBack.Parent = maxIcon

local restoreBackCorner = Instance.new("UICorner")
restoreBackCorner.CornerRadius = UDim.new(0, 2)
restoreBackCorner.Parent = restoreBack

local restoreBackStroke = Instance.new("UIStroke")
restoreBackStroke.Thickness = 1.5
restoreBackStroke.Color = COLORS.TextDim
restoreBackStroke.Parent = restoreBack

local restoreFront = Instance.new("Frame")
restoreFront.Name = "RestoreFront"
restoreFront.Size = UDim2.new(0, 11, 0, 11)
restoreFront.Position = UDim2.new(0, 2, 0, 6)
restoreFront.BackgroundColor3 = COLORS.Surface
restoreFront.BorderSizePixel = 0
restoreFront.Visible = false
restoreFront.ZIndex = 3
restoreFront.Parent = maxIcon

local restoreFrontCorner = Instance.new("UICorner")
restoreFrontCorner.CornerRadius = UDim.new(0, 2)
restoreFrontCorner.Parent = restoreFront

local restoreFrontStroke = Instance.new("UIStroke")
restoreFrontStroke.Thickness = 1.5
restoreFrontStroke.Color = COLORS.TextDim
restoreFrontStroke.Parent = restoreFront

local function setupTopButton(button, hoverColor, hoverBg)
	button.MouseEnter:Connect(function()
		tween(button, {TextColor3 = hoverColor, BackgroundTransparency = 0})
		tween(button, {BackgroundColor3 = hoverBg or COLORS.SurfaceLight})
	end)
	button.MouseLeave:Connect(function()
		tween(button, {TextColor3 = COLORS.TextDim, BackgroundTransparency = 1})
	end)
end

setupTopButton(minimize, COLORS.Text)
setupTopButton(close, Color3.new(1, 1, 1), COLORS.Danger)

maximize.MouseEnter:Connect(function()
	tween(maximize, {BackgroundTransparency = 0})
	tween(normalStroke, {Color = COLORS.Text})
	tween(restoreBackStroke, {Color = COLORS.Text})
	tween(restoreFrontStroke, {Color = COLORS.Text})
end)

maximize.MouseLeave:Connect(function()
	tween(maximize, {BackgroundTransparency = 1})
	tween(normalStroke, {Color = COLORS.TextDim})
	tween(restoreBackStroke, {Color = COLORS.TextDim})
	tween(restoreFrontStroke, {Color = COLORS.TextDim})
end)

--// SIDEBAR
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 220, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = COLORS.Surface
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 20)
sidebarCorner.Parent = sidebar

local sidebarTopMask = Instance.new("Frame")
sidebarTopMask.Size = UDim2.new(1, 0, 0, 20)
sidebarTopMask.Position = UDim2.new(0, 0, 0, 0)
sidebarTopMask.BackgroundColor3 = COLORS.Surface
sidebarTopMask.BorderSizePixel = 0
sidebarTopMask.Parent = sidebar

local sidebarInnerMask = Instance.new("Frame")
sidebarInnerMask.Size = UDim2.new(0, 20, 0, 20)
sidebarInnerMask.Position = UDim2.new(1, -20, 1, -20)
sidebarInnerMask.BackgroundColor3 = COLORS.Surface
sidebarInnerMask.BorderSizePixel = 0
sidebarInnerMask.Parent = sidebar

local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = COLORS.Border
sideLine.BorderSizePixel = 0
sideLine.Parent = sidebar

--// Content
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -220, 1, -38)
content.Position = UDim2.new(0, 220, 0, 38)
content.BackgroundTransparency = 1
content.Parent = main

--// PAGES
local pages = {}

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = COLORS.Accent
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = content

	pages[name] = page
	return page
end

local serverPage = createPage("Server")
local movementPage = createPage("Movement")
local settingsPage = createPage("Settings")

--// PAGE TITLE
local function createPageTitle(parent, text, subtitle)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 0, 38)
	label.Position = UDim2.new(0, 28, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	if subtitle then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -50, 0, 20)
		sub.Position = UDim2.new(0, 28, 0, 54)
		sub.BackgroundTransparency = 1
		sub.Text = subtitle
		sub.TextColor3 = COLORS.TextDim
		sub.TextSize = 14
		sub.Font = Enum.Font.Gotham
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Parent = parent
	end

	return label
end

--// GENERIC CARD
local function createCard(parent, yPos, titleText, bodyText, height, accentColor)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -56, 0, height or 90)
	card.Position = UDim2.new(0, 28, 0, yPos)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = card

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, -20)
	accentBar.Position = UDim2.new(0, 0, 0.5, 0)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.BackgroundColor3 = accentColor or COLORS.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accentBar

	applyGradient(accentBar, accentColor or COLORS.Accent, COLORS.AccentB, 90)

	local cardTitle = Instance.new("TextLabel")
	cardTitle.Size = UDim2.new(1, -40, 0, 22)
	cardTitle.Position = UDim2.new(0, 18, 0, 12)
	cardTitle.BackgroundTransparency = 1
	cardTitle.Text = titleText
	cardTitle.TextColor3 = COLORS.Text
	cardTitle.TextSize = 15
	cardTitle.Font = Enum.Font.GothamBold
	cardTitle.TextXAlignment = Enum.TextXAlignment.Left
	cardTitle.Parent = card

	local cardBody = Instance.new("TextLabel")
	cardBody.Size = UDim2.new(1, -40, 1, -40)
	cardBody.Position = UDim2.new(0, 18, 0, 36)
	cardBody.BackgroundTransparency = 1
	cardBody.Text = bodyText
	cardBody.TextColor3 = COLORS.TextDim
	cardBody.TextSize = 13
	cardBody.Font = Enum.Font.Gotham
	cardBody.TextXAlignment = Enum.TextXAlignment.Left
	cardBody.TextYAlignment = Enum.TextYAlignment.Top
	cardBody.TextWrapped = true
	cardBody.Parent = card

	return card
end

--// TOGGLE
local function createToggle(parent, text, yPos, default, accentColor)
	accentColor = accentColor or COLORS.Accent

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -56, 0, 56)
	row.Position = UDim2.new(0, 28, 0, yPos)
	row.BackgroundColor3 = COLORS.Card
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -90, 1, 0)
	label.Position = UDim2.new(0, 18, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 50, 0, 26)
	toggle.Position = UDim2.new(1, -68, 0.5, -13)
	toggle.BackgroundColor3 = default and accentColor or COLORS.SurfaceLight
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.Parent = row

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	local toggleGradient = applyGradient(toggle, accentColor, COLORS.AccentB, 0)
	toggleGradient.Enabled = default

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 20, 0, 20)
	circle.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = toggle

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local enabled = default

	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled

		if enabled then
			toggleGradient.Enabled = true
			tween(toggle, {BackgroundColor3 = accentColor})
			tween(circle, {Position = UDim2.new(1, -23, 0.5, -10)})
		else
			tween(toggle, {BackgroundColor3 = COLORS.SurfaceLight})
			tween(circle, {Position = UDim2.new(0, 3, 0.5, -10)})
			task.delay(0.18, function()
				if not enabled then toggleGradient.Enabled = false end
			end)
		end
	end)

	return row, function() return enabled end
end

--// SERVER PAGE
createPageTitle(serverPage, "Server", "Server info & tools")
createCard(serverPage, 95, "Server", "Manage server information here.", 90, COLORS.PageServer)

--// SETTINGS PAGE
createPageTitle(settingsPage, "Settings", "Customize your experience")
createToggle(settingsPage, "UI Blur", 95, false, COLORS.PageSettings)
createToggle(settingsPage, "Notifications", 163, true, COLORS.PageSettings)


--// MOVEMENT PAGE
createPageTitle(
	movementPage,
	"Movement",
	"Controls for movement, jumping and automatic Win target navigation"
)

local NUMBER_ROW_HEIGHT = 78

-- Thanh trượt (slider) kéo thả: bên trái luôn hiện "0" làm mốc,
-- bên phải hiện đúng số đang được kéo trên thanh, kéo tới đâu áp dụng tới đó.
local function createNumberControl(parent, titleText, yPos, defaultValue, minValue, maxValue, accentColor, onChanged)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -56, 0, NUMBER_ROW_HEIGHT)
	row.Position = UDim2.new(0, 28, 0, yPos)
	row.BackgroundColor3 = COLORS.Card
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = row

	-- Chỉ còn tên tính năng, không hiện khoảng giá trị (vd "1–500") nữa
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -36, 0, 18)
	label.Position = UDim2.new(0, 18, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local sliderZone = Instance.new("Frame")
	sliderZone.Size = UDim2.new(1, -36, 0, 30)
	sliderZone.Position = UDim2.new(0, 18, 0, 38)
	sliderZone.BackgroundTransparency = 1
	sliderZone.Parent = row

	-- Nhãn bên trái: luôn luôn là "0"
	local minLabel = Instance.new("TextLabel")
	minLabel.Size = UDim2.new(0, 20, 1, 0)
	minLabel.Position = UDim2.new(0, 0, 0, 0)
	minLabel.BackgroundTransparency = 1
	minLabel.Text = "0"
	minLabel.TextColor3 = COLORS.TextDim
	minLabel.TextSize = 12
	minLabel.Font = Enum.Font.GothamMedium
	minLabel.TextXAlignment = Enum.TextXAlignment.Left
	minLabel.Parent = sliderZone

	-- Nhãn bên phải: số hiện tại, cập nhật realtime khi kéo
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 46, 1, 0)
	valueLabel.Position = UDim2.new(1, -46, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(defaultValue)
	valueLabel.TextColor3 = accentColor
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = sliderZone

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -76, 0, 6)
	track.Position = UDim2.new(0, 28, 0.5, -3)
	track.BackgroundColor3 = COLORS.SurfaceLight
	track.BorderSizePixel = 0
	track.Active = true -- QUAN TRỌNG: Frame mặc định Active=false nên sẽ không nhận InputBegan
	track.Parent = sliderZone

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = accentColor
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.ZIndex = 2
	knob.Active = true -- cùng lý do: Frame cần Active=true mới bắt InputBegan
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local knobStroke = Instance.new("UIStroke")
	knobStroke.Color = accentColor
	knobStroke.Thickness = 2
	knobStroke.Parent = knob

	local function updateVisual(value)
		local fraction = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
		fill.Size = UDim2.new(fraction, 0, 1, 0)
		knob.Position = UDim2.new(fraction, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
	end

	local function setValue(value, fireCallback)
		value = math.clamp(math.floor(value + 0.5), minValue, maxValue)
		updateVisual(value)

		if fireCallback ~= false and onChanged then
			onChanged(value)
		end

		return value
	end

	updateVisual(math.clamp(defaultValue, minValue, maxValue))

	local dragging = false

	local function updateFromInputPosition(inputPosition)
		local relativeX = inputPosition.X - track.AbsolutePosition.X
		local fraction = math.clamp(relativeX / track.AbsoluteSize.X, 0, 1)
		setValue(minValue + fraction * (maxValue - minValue))
	end

	local function beginDrag(input)
		dragging = true
		updateFromInputPosition(input.Position)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInputPosition(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
		end
	end)

	return row, valueLabel, setValue
end

local speedValue = 16
local jumpValue = 50
local flySpeedValue = 90
local flyHeightValue = 5

local _, speedBox, applySpeed = createNumberControl(
	movementPage,
	"Walk Speed",
	95,
	speedValue,
	1,
	500,
	COLORS.PageFarm,
	function(value)
		speedValue = value
		local module = loadMovementModule()
		if module and module.SetWalkSpeed then
			module.SetWalkSpeed(value)
		end
	end
)

local _, jumpBox, applyJump = createNumberControl(
	movementPage,
	"Jump Power",
	183,
	jumpValue,
	1,
	500,
	COLORS.PageFarm,
	function(value)
		jumpValue = value
		local module = loadMovementModule()
		if module and module.SetJumpPower then
			module.SetJumpPower(value)
		end
	end
)

local _, flySpeedBox, applyFlySpeed = createNumberControl(
	movementPage,
	"Auto-Fly Speed",
	271,
	flySpeedValue,
	10,
	500,
	COLORS.PageServer,
	function(value)
		flySpeedValue = value
		local module = loadMovementModule()
		if module and module.SetFlySpeed then
			module.SetFlySpeed(value)
		end
	end
)

local _, flyHeightBox, applyFlyHeight = createNumberControl(
	movementPage,
	"Fly Height Offset",
	359,
	flyHeightValue,
	0,
	100,
	COLORS.PageServer,
	function(value)
		flyHeightValue = value
		local module = loadMovementModule()
		if module and module.SetFlyHeight then
			module.SetFlyHeight(value)
		end
	end
)

local _, infiniteJumpEnabled = createToggle(
	movementPage,
	"Infinite Jump",
	447,
	false,
	COLORS.PageFarm
)

local _, autoFlyEnabled = createToggle(
	movementPage,
	"Auto-Fly Mode",
	515,
	false,
	COLORS.PageServer
)

local winTitle = Instance.new("TextLabel")
winTitle.Size = UDim2.new(1, -56, 0, 26)
winTitle.Position = UDim2.new(0, 28, 0, 585)
winTitle.BackgroundTransparency = 1
winTitle.Text = "WIN TARGETS"
winTitle.TextColor3 = COLORS.Text
winTitle.TextSize = 15
winTitle.Font = Enum.Font.GothamBold
winTitle.TextXAlignment = Enum.TextXAlignment.Left
winTitle.Parent = movementPage

local winHint = Instance.new("TextLabel")
winHint.Size = UDim2.new(1, -56, 0, 32)
winHint.Position = UDim2.new(0, 28, 0, 613)
winHint.BackgroundTransparency = 1
winHint.Text = "Flip a switch to continuously auto-fly to that target — no need to also enable Auto-Fly Mode."
winHint.TextColor3 = COLORS.TextDim
winHint.TextSize = 12
winHint.TextXAlignment = Enum.TextXAlignment.Left
winHint.TextWrapped = true
winHint.Parent = movementPage

-- Công tắc kiểu radio: giống createToggle nhưng thêm forceState() để
-- các mục Win Target khác tự tắt khi 1 mục được bật (chỉ chọn 1 tại 1 thời điểm).
local function createRadioToggle(parent, text, yPos, accentColor, onToggle)
	accentColor = accentColor or COLORS.Accent

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -56, 0, 56)
	row.Position = UDim2.new(0, 28, 0, yPos)
	row.BackgroundColor3 = COLORS.Card
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -90, 1, 0)
	label.Position = UDim2.new(0, 18, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 50, 0, 26)
	toggle.Position = UDim2.new(1, -68, 0.5, -13)
	toggle.BackgroundColor3 = COLORS.SurfaceLight
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.Parent = row

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	local toggleGradient = applyGradient(toggle, accentColor, COLORS.AccentB, 0)
	toggleGradient.Enabled = false

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 20, 0, 20)
	circle.Position = UDim2.new(0, 3, 0.5, -10)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = toggle

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local enabled = false

	local function applyVisual()
		if enabled then
			toggleGradient.Enabled = true
			tween(toggle, {BackgroundColor3 = accentColor})
			tween(circle, {Position = UDim2.new(1, -23, 0.5, -10)})
		else
			tween(toggle, {BackgroundColor3 = COLORS.SurfaceLight})
			tween(circle, {Position = UDim2.new(0, 3, 0.5, -10)})
			task.delay(0.18, function()
				if not enabled then toggleGradient.Enabled = false end
			end)
		end
	end

	-- Bật/tắt bằng code (không gọi lại onToggle) — dùng khi mục khác được chọn.
	local function forceState(newState)
		if enabled == newState then
			return
		end
		enabled = newState
		applyVisual()
	end

	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		applyVisual()

		if onToggle then
			onToggle(enabled)
		end
	end)

	return row, function() return enabled end, forceState
end

-- Danh sách Win Target: gạt công tắc là tự động bay liên tục tới đó,
-- không cần bấm nút hay bật riêng "Auto-Fly Mode".
local WIN_TARGET_VALUES = {1, 3, 10, 25, 50, 100}
local WIN_TARGET_ROW_HEIGHT = 56
local WIN_TARGET_ROW_GAP = 10

local winTargetRows = {}
local selectedWinTarget = nil

for index, value in ipairs(WIN_TARGET_VALUES) do
	local rowY = 648 + (index - 1) * (WIN_TARGET_ROW_HEIGHT + WIN_TARGET_ROW_GAP)

	local _, _, forceState = createRadioToggle(
		movementPage,
		"+" .. tostring(value) .. " Win",
		rowY,
		COLORS.PageServer,
		function(isEnabled)
			if isEnabled then
				selectedWinTarget = value

				-- Chỉ cho phép chọn 1 target tại 1 thời điểm: tắt các mục còn lại.
				for _, entry in ipairs(winTargetRows) do
					if entry.value ~= value then
						entry.forceState(false)
					end
				end
			elseif selectedWinTarget == value then
				selectedWinTarget = nil
			end
		end
	)

	table.insert(winTargetRows, {value = value, forceState = forceState})
end

local winTargetsBottom = 648 + (#WIN_TARGET_VALUES * (WIN_TARGET_ROW_HEIGHT + WIN_TARGET_ROW_GAP))

local refreshTargets = Instance.new("TextButton")
refreshTargets.Size = UDim2.new(0, 125, 0, 34)
refreshTargets.Position = UDim2.new(1, -153, 0, 579)
refreshTargets.BackgroundColor3 = COLORS.PageServer
refreshTargets.BorderSizePixel = 0
refreshTargets.Text = "Refresh"
refreshTargets.TextColor3 = Color3.new(1, 1, 1)
refreshTargets.TextSize = 12
refreshTargets.Font = Enum.Font.GothamBold
refreshTargets.AutoButtonColor = false
refreshTargets.Parent = movementPage

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 9)
refreshCorner.Parent = refreshTargets

refreshTargets.MouseButton1Click:Connect(function()
	local module = loadMovementModule()
	if module and module.RefreshTargets then
		module.RefreshTargets()
	end
end)

-- Toggle state is read by the UI and passed to the external module.
-- The existing createToggle intentionally exposes a getter.
task.spawn(function()
	while movementPage.Parent do
		task.wait(0.1)

		local module = Movement
		if not module then
			continue
		end

		if module.SetInfiniteJump then
			module.SetInfiniteJump(infiniteJumpEnabled())
		end

		if selectedWinTarget then
			-- Có Win Target được chọn: luôn bật Auto-Fly và tự bay lại
			-- ngay khi chuyến bay trước kết thúc (tới nơi / hết giờ / mục tiêu di chuyển).
			if module.SetAutoFlyEnabled then
				module.SetAutoFlyEnabled(true)
			end

			if module.FlyToWin and module.IsFlying and not module.IsFlying() then
				module.FlyToWin(selectedWinTarget)
			end
		else
			if module.SetAutoFlyEnabled then
				module.SetAutoFlyEnabled(autoFlyEnabled())
			end
		end
	end
end)

movementPage.CanvasSize = UDim2.new(0, 0, 0, winTargetsBottom + 30)


--// SIDEBAR BUTTONS
local currentPage = nil
local buttons = {}

local function createSidebarButton(text, icon, order, pageName, accentColor)
	accentColor = accentColor or COLORS.Accent

	local button = Instance.new("TextButton")
	button.Name = pageName .. "Button"
	button.Size = UDim2.new(1, -24, 0, 48)
	button.Position = UDim2.new(0, 12, 0, 16 + ((order - 1) * 54))
	button.BackgroundColor3 = COLORS.SurfaceLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = sidebar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 32, 1, 0)
	iconLabel.Position = UDim2.new(0, 14, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = COLORS.TextDim
	iconLabel.TextSize = 17
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Parent = button

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -55, 1, 0)
	textLabel.Position = UDim2.new(0, 48, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = COLORS.TextDim
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = button

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 4, 0, 28)
	indicator.Position = UDim2.new(0, 0, 0.5, -14)
	indicator.BackgroundColor3 = accentColor
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = button

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator

	button.MouseEnter:Connect(function()
		if currentPage ~= pageName then
			tween(button, {BackgroundTransparency = 0.7})
		end
	end)

	button.MouseLeave:Connect(function()
		if currentPage ~= pageName then
			tween(button, {BackgroundTransparency = 1})
		end
	end)

	button.MouseButton1Click:Connect(function()
		for _, data in pairs(buttons) do
			tween(data.button, {BackgroundTransparency = 1})
			data.indicator.Visible = false
			tween(data.icon, {TextColor3 = COLORS.TextDim})
			tween(data.label, {TextColor3 = COLORS.TextDim})
		end

		for _, page in pairs(pages) do
			page.Visible = false
		end

		currentPage = pageName

		tween(button, {BackgroundTransparency = 0.1})
		indicator.Visible = true
		tween(iconLabel, {TextColor3 = accentColor})
		tween(textLabel, {TextColor3 = COLORS.Text})

		pages[pageName].Visible = true
	end)

	buttons[pageName] = {
		button = button,
		indicator = indicator,
		icon = iconLabel,
		label = textLabel,
		accent = accentColor
	}

	return button
end

createSidebarButton("Server", "▣", 1, "Server", COLORS.PageServer)
createSidebarButton("Movement", "✦", 2, "Movement", COLORS.PageFarm)
createSidebarButton("Settings", "⚙", 3, "Settings", COLORS.PageSettings)

--// DEFAULT PAGE = SERVER
currentPage = "Server"
serverPage.Visible = true
buttons["Server"].button.BackgroundTransparency = 0.1
buttons["Server"].indicator.Visible = true
buttons["Server"].icon.TextColor3 = COLORS.PageServer
buttons["Server"].label.TextColor3 = COLORS.Text

--// CLOSE
close.MouseButton1Click:Connect(function()
	tween(main, {BackgroundTransparency = 1}, 0.15)
	task.wait(0.15)
	screenGui:Destroy()
end)

--// MAXIMIZE
local maximized = false
local minimized = false

local normalSize = UDim2.new(0, 780, 0, 500)
local normalPosition = UDim2.new(0.5, -390, 0.5, -250)

maximize.MouseButton1Click:Connect(function()
	if minimized then
		minimized = false
		sidebar.Visible = true
		content.Visible = true
	end

	maximized = not maximized

	if maximized then
		tween(main, {
			Size = UDim2.new(1, -40, 1, -40),
			Position = UDim2.new(0, 20, 0, 20)
		}, 0.25)

		normalIcon.Visible = false
		restoreBack.Visible = true
		restoreFront.Visible = true
	else
		tween(main, {
			Size = normalSize,
			Position = normalPosition
		}, 0.25)

		normalIcon.Visible = true
		restoreBack.Visible = false
		restoreFront.Visible = false
	end
end)

--// MINIMIZE
minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		sidebar.Visible = false
		content.Visible = false
		tween(main, {Size = UDim2.new(0, 780, 0, 38)}, 0.2)
	else
		sidebar.Visible = true
		content.Visible = true

		tween(
			main,
			{Size = maximized and UDim2.new(1, -40, 1, -40) or normalSize},
			0.2
		)
	end
end)

--// DRAG WINDOW
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