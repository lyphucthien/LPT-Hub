local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local GET_KEY_LINK = "https://link4sub.com/owycAYxKdu"
local KEY_FILE = "LPT_Hub_Key.txt"

local VALID_KEYS = {
	["LPT-HUB"] = true,
}

local GAME_CONFIG = {
	["+1 Speed Keyboard Escape"] = {
		Name = "+1 Speed Keyboard Escape",
		PlaceId = {95082159892680},
		UniverseId = {9584852943},
		WaitForDataLoaded = false,
		MainUI = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/%2B1%20Speed%20Keyboard%20Escape/MainUI.luau",
	},
}

--============================================================
-- STATE
--============================================================

local State = {
	KeyValid = false,
	PlaceId = nil,
	UniverseId = nil,
	GameName = "Unknown Game",
	GameSupported = false,
	GameConfig = nil,
	MainUI = nil,
	Loading = false,
	Submitting = false,
}

--============================================================
-- COLORS
--============================================================

local COLORS = {
	Background = Color3.fromRGB(8,18,32),
	SurfaceLight = Color3.fromRGB(40,44,58),
	Card = Color3.fromRGB(34,38,50),
	Accent = Color3.fromRGB(168,105,245),
	AccentB = Color3.fromRGB(236,72,153),
	Text = Color3.fromRGB(240,241,245),
	TextDim = Color3.fromRGB(145,153,168),
	Border = Color3.fromRGB(52,56,70),
	Danger = Color3.fromRGB(255,92,108),
	Success = Color3.fromRGB(74,222,128),
	Info = Color3.fromRGB(96,165,250),
	Warning = Color3.fromRGB(250,204,21),
}

--============================================================
-- HELPERS
--============================================================

local function tween(obj, props, time, style)
	if not obj or not obj.Parent then return end
	local t = TweenService:Create(obj, TweenInfo.new(time or .18, style or Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

local function applyGradient(obj, a, b, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(a, b)
	gradient.Rotation = rotation or 0
	gradient.Parent = obj
	return gradient
end

--============================================================
-- KEY STORAGE
--============================================================

local function getSavedKey()
	if type(isfile) ~= "function" then return nil end

	local ok, result = pcall(function()
		if not isfile(KEY_FILE) then return nil end
		local data = readfile(KEY_FILE)
		return data and data ~= "" and tostring(data) or nil
	end)

	return ok and result or nil
end

local function saveKey(key)
	if type(writefile) ~= "function" then return end
	pcall(function() writefile(KEY_FILE, tostring(key)) end)
end

local function checkKey(key)
	return VALID_KEYS[key] == true
end

--============================================================
-- SCREEN GUI
--============================================================

local oldGui = playerGui:FindFirstChild("LPTKeyUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LPTKeyUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

--============================================================
-- NOTIFICATION SYSTEM
--============================================================

local notificationHolder = Instance.new("Frame")
notificationHolder.Name = "NotificationHolder"
notificationHolder.Size = UDim2.fromScale(1,1)
notificationHolder.BackgroundTransparency = 1
notificationHolder.BorderSizePixel = 0
notificationHolder.ZIndex = 100
notificationHolder.Parent = screenGui

local activeNotifications = {}
local NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT, NOTIFICATION_GAP = 310, 74, 10
local RIGHT_MARGIN, BOTTOM_MARGIN = 20, 20

local function notificationPosition(index)
	return UDim2.new(1, -RIGHT_MARGIN, 1, -BOTTOM_MARGIN - ((index - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_GAP)))
end

local function updateNotifications()
	for i, notification in ipairs(activeNotifications) do
		if notification and notification.Parent then
			tween(notification, {Position = notificationPosition(i)}, .25, Enum.EasingStyle.Quart)
		end
	end
end

local function showNotification(titleText, messageText, notificationType)
	local accent, iconText = COLORS.Success, "✓"

	if notificationType == "error" then
		accent, iconText = COLORS.Danger, "!"
	elseif notificationType == "info" then
		accent, iconText = COLORS.Info, "i"
	elseif notificationType == "warning" then
		accent, iconText = COLORS.Warning, "!"
	end

	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.AnchorPoint = Vector2.new(1,1)
	notification.Size = UDim2.fromOffset(NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT)
	notification.Position = UDim2.new(1, NOTIFICATION_WIDTH + 50, 1, -BOTTOM_MARGIN)
	notification.BackgroundColor3 = Color3.fromRGB(10,18,30)
	notification.BackgroundTransparency = .04
	notification.BorderSizePixel = 0
	notification.ZIndex = 101
	notification.Parent = notificationHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,12)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = .15
	stroke.Parent = notification

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0,4,1,-18)
	bar.Position = UDim2.new(0,0,.5,0)
	bar.AnchorPoint = Vector2.new(0,.5)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 102
	bar.Parent = notification

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1,0)
	barCorner.Parent = bar

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(30,30)
	icon.Position = UDim2.fromOffset(13,12)
	icon.BackgroundColor3 = accent
	icon.BackgroundTransparency = .82
	icon.BorderSizePixel = 0
	icon.Text = iconText
	icon.TextColor3 = accent
	icon.TextSize = 15
	icon.Font = Enum.Font.GothamBold
	icon.ZIndex = 102
	icon.Parent = notification

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1,0)
	iconCorner.Parent = icon

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-62,0,21)
	title.Position = UDim2.fromOffset(55,10)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = COLORS.Text
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 102
	title.Parent = notification

	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1,-62,0,30)
	message.Position = UDim2.fromOffset(55,32)
	message.BackgroundTransparency = 1
	message.Text = messageText
	message.TextColor3 = COLORS.TextDim
	message.TextSize = 11
	message.Font = Enum.Font.Gotham
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.ZIndex = 102
	message.Parent = notification

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1,0,0,2)
	progress.Position = UDim2.new(0,0,1,-2)
	progress.BackgroundColor3 = accent
	progress.BorderSizePixel = 0
	progress.ZIndex = 103
	progress.Parent = notification

	table.insert(activeNotifications, 1, notification)
	updateNotifications()

	tween(notification, {Position = notificationPosition(1)}, .3, Enum.EasingStyle.Quart)
	tween(progress, {Size = UDim2.new(0,0,0,2)}, 3, Enum.EasingStyle.Linear)

	task.delay(3, function()
		if not notification.Parent then return end

		tween(notification, {
			Position = UDim2.new(1,-RIGHT_MARGIN,1,NOTIFICATION_HEIGHT + 30)
		}, .35, Enum.EasingStyle.Quart)

		task.wait(.4)

		if notification.Parent then notification:Destroy() end

		for i, item in ipairs(activeNotifications) do
			if item == notification then
				table.remove(activeNotifications, i)
				break
			end
		end

		updateNotifications()
	end)
end

--============================================================
-- KEY UI
--============================================================

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyUI"
keyFrame.Size = UDim2.fromOffset(340,330)
keyFrame.Position = UDim2.new(.5,-170,.5,-165)
keyFrame.BackgroundColor3 = COLORS.Background
keyFrame.BackgroundTransparency = .15
keyFrame.BorderSizePixel = 0
keyFrame.ClipsDescendants = true
keyFrame.ZIndex = 10
keyFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0,18)
frameCorner.Parent = keyFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = COLORS.Border
frameStroke.Thickness = 1.5
frameStroke.Transparency = .2
frameStroke.Parent = keyFrame
applyGradient(frameStroke, COLORS.Accent, COLORS.AccentB, 45)

--============================================================
-- LOGO / HEADER
--============================================================

local logo = Instance.new("ImageLabel")
logo.Name = "KeyLogo"
logo.Size = UDim2.fromOffset(54,54)
logo.Position = UDim2.fromOffset(24,24)
logo.BackgroundColor3 = Color3.fromRGB(8,8,10)
logo.BorderSizePixel = 0
logo.Image = "rbxassetid://86498268964550"
logo.ScaleType = Enum.ScaleType.Crop
logo.ZIndex = 11
logo.Parent = keyFrame

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1,0)
logoCorner.Parent = logo

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = COLORS.Border
logoStroke.Thickness = 1
logoStroke.Transparency = .15
logoStroke.Parent = logo

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(250,28)
title.Position = UDim2.fromOffset(92,20)
title.BackgroundTransparency = 1
title.Text = "LPT HUB KEY SYSTEM"
title.TextColor3 = COLORS.Text
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11
title.Parent = keyFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.fromOffset(250,14)
subtitle.Position = UDim2.fromOffset(92,47)
subtitle.BackgroundTransparency = 1
subtitle.Text = "THE AUTHENTICATE SYSTEM"
subtitle.TextColor3 = COLORS.TextDim
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 11
subtitle.Parent = keyFrame

--============================================================
-- INPUT
--============================================================

local inputBox = Instance.new("Frame")
inputBox.Size = UDim2.new(1,-40,0,44)
inputBox.Position = UDim2.fromOffset(20,100)
inputBox.BackgroundColor3 = COLORS.Card
inputBox.BorderSizePixel = 0
inputBox.ZIndex = 11
inputBox.Parent = keyFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0,12)
inputCorner.Parent = inputBox

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = COLORS.Border
inputStroke.Thickness = 1
inputStroke.Transparency = .15
inputStroke.Parent = inputBox

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1,-32,1,0)
keyInput.Position = UDim2.fromOffset(16,0)
keyInput.BackgroundTransparency = 1
keyInput.PlaceholderText = "Enter Key..."
keyInput.PlaceholderColor3 = COLORS.TextDim
keyInput.Text = ""
keyInput.TextColor3 = COLORS.Text
keyInput.TextSize = 14
keyInput.Font = Enum.Font.Gotham
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 12
keyInput.Parent = inputBox

keyInput.Focused:Connect(function()
	tween(inputStroke, {Color = COLORS.Accent, Transparency = 0})
end)

keyInput.FocusLost:Connect(function()
	tween(inputStroke, {Color = COLORS.Border, Transparency = .15})
end)

--============================================================
-- GET KEY
--============================================================

local getKeyButton = Instance.new("TextButton")
getKeyButton.Size = UDim2.new(1,-40,0,40)
getKeyButton.Position = UDim2.fromOffset(20,154)
getKeyButton.BackgroundColor3 = COLORS.SurfaceLight
getKeyButton.BorderSizePixel = 0
getKeyButton.Text = "GET KEY"
getKeyButton.TextColor3 = COLORS.Text
getKeyButton.TextSize = 13
getKeyButton.Font = Enum.Font.GothamBold
getKeyButton.AutoButtonColor = false
getKeyButton.ZIndex = 11
getKeyButton.Parent = keyFrame

local getCorner = Instance.new("UICorner")
getCorner.CornerRadius = UDim.new(0,12)
getCorner.Parent = getKeyButton

local getStroke = Instance.new("UIStroke")
getStroke.Color = COLORS.Border
getStroke.Thickness = 1
getStroke.Transparency = .2
getStroke.Parent = getKeyButton

getKeyButton.MouseEnter:Connect(function()
	tween(getKeyButton, {BackgroundColor3 = COLORS.Card})
end)

getKeyButton.MouseLeave:Connect(function()
	tween(getKeyButton, {BackgroundColor3 = COLORS.SurfaceLight})
end)

getKeyButton.MouseButton1Click:Connect(function()
	if type(setclipboard) == "function" then
		setclipboard(GET_KEY_LINK)
		showNotification("Link Copied!", "Link lấy KEY đã được copy.", "success")
		getKeyButton.Text = "LINK COPIED!"

		task.delay(1.2, function()
			if getKeyButton.Parent then getKeyButton.Text = "GET KEY" end
		end)
	else
		showNotification("Copy Failed", "Không thể copy link.", "error")
	end
end)

--============================================================
-- SUBMIT
--============================================================

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1,-40,0,44)
submitButton.Position = UDim2.fromOffset(20,208)
submitButton.BackgroundColor3 = COLORS.Accent
submitButton.BorderSizePixel = 0
submitButton.Text = "Submit Key"
submitButton.TextColor3 = Color3.fromRGB(255,255,255)
submitButton.TextSize = 14
submitButton.Font = Enum.Font.GothamBold
submitButton.AutoButtonColor = false
submitButton.ZIndex = 11
submitButton.Parent = keyFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0,12)
submitCorner.Parent = submitButton
applyGradient(submitButton, COLORS.Accent, COLORS.AccentB, 0)

submitButton.MouseEnter:Connect(function()
	tween(submitButton, {Size = UDim2.new(1,-36,0,44)}, .12)
end)

submitButton.MouseLeave:Connect(function()
	tween(submitButton, {Size = UDim2.new(1,-40,0,44)}, .12)
end)

--============================================================
-- STATUS
--============================================================

local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1,-40,0,18)
keyStatus.Position = UDim2.fromOffset(20,260)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = COLORS.Danger
keyStatus.TextSize = 12
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextXAlignment = Enum.TextXAlignment.Left
keyStatus.ZIndex = 11
keyStatus.Parent = keyFrame

local function setStatus(text, color)
	keyStatus.Text = tostring(text or "")
	keyStatus.TextColor3 = color or COLORS.Text
end

--============================================================
-- GAME DETECTION
--============================================================

local function getUniverseId(placeId)
	if not placeId then return nil end

	local ok, result = pcall(function()
		local url = "https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe"
		local response = game:HttpGet(url)
		if not response or response == "" then error("Empty response") end

		local data = HttpService:JSONDecode(response)
		if not data then error("Invalid JSON") end

		return tonumber(data.universeId)
	end)

	if ok and result then return result end

	warn("[LPT HUB] UniverseId Error:", tostring(result))
	return nil
end

local function containsId(list, id)
	if not id or type(list) ~= "table" then return false end

	local target = tonumber(id)

	for _, value in ipairs(list) do
		if tonumber(value) == target then return true end
	end

	return false
end

local function findGameConfig(placeId, universeId)
	for configKey, config in pairs(GAME_CONFIG) do
		if type(config) ~= "table" then continue end

		if containsId(config.PlaceId, placeId) then
			return config, "PlaceId", configKey
		end

		if containsId(config.UniverseId, universeId) then
			return config, "UniverseId", configKey
		end
	end

	return nil, nil, nil
end

local function resolveGame()
	State.PlaceId = tonumber(game.PlaceId)

	if not State.PlaceId or State.PlaceId <= 0 then
		return false, "Không lấy được PlaceId."
	end

	setStatus("PlaceId: " .. tostring(State.PlaceId) .. " • Đang nhận diện...", COLORS.Info)
	showNotification("Detecting Game", "Đang lấy PlaceId và UniverseId...", "info")

	task.wait(.25)

	State.UniverseId = getUniverseId(State.PlaceId)

	if State.UniverseId then
		setStatus("UniverseId: " .. tostring(State.UniverseId) .. " • Đang tìm game...", COLORS.Info)
	else
		setStatus("Không lấy được UniverseId • Kiểm tra PlaceId...", COLORS.Warning)
	end

	task.wait(.2)

	local gameConfig, matchType, configKey = findGameConfig(State.PlaceId, State.UniverseId)

	if not gameConfig then
		State.GameSupported = false
		State.GameConfig = nil
		State.MainUI = nil
		return false, "Game không được hỗ trợ."
	end

	if type(gameConfig) ~= "table" then
		return false, "Config game không hợp lệ."
	end

	local gameName = gameConfig.Name or gameConfig.name or configKey or "Unknown Game"
	local mainUI = gameConfig.MainUI or gameConfig.mainUI or gameConfig.URL or gameConfig.url

	if type(mainUI) ~= "string" or mainUI == "" then
		return false, "Game đã nhận diện nhưng chưa có MainUI."
	end

	State.GameName = tostring(gameName)
	State.GameConfig = gameConfig
	State.MainUI = mainUI
	State.GameSupported = true

	setStatus("Đã nhận diện: " .. State.GameName, COLORS.Success)
	showNotification("Game Detected", State.GameName .. " • " .. tostring(matchType), "success")

	print("[LPT HUB] Game:", State.GameName)
	print("[LPT HUB] Match:", matchType)
	print("[LPT HUB] PlaceId:", State.PlaceId)
	print("[LPT HUB] UniverseId:", State.UniverseId)

	return true
end

--============================================================
-- DATA LOADED
--============================================================

local function waitForGameData(config)
	if type(config) ~= "table" or config.WaitForDataLoaded ~= true then
		print("[LPT HUB] DataLoaded: Not Required")
		return true
	end

	print("[LPT HUB] DataLoaded: Waiting...")
	setStatus("Đang chờ dữ liệu game...", COLORS.Info)

	local dataLoaded = player:FindFirstChild("DataLoaded")

	if not dataLoaded then
		local ok, result = pcall(function()
			return player:WaitForChild("DataLoaded", 30)
		end)

		if not ok or not result then
			warn("[LPT HUB] DataLoaded không tồn tại.")
			return false
		end

		dataLoaded = result
	end

	if dataLoaded:IsA("BoolValue") then
		local timeout = os.clock() + 30

		while not dataLoaded.Value and os.clock() < timeout do
			task.wait(.2)
		end

		if dataLoaded.Value then
			print("[LPT HUB] DataLoaded = true")
			return true
		end

		warn("[LPT HUB] DataLoaded timeout.")
		return false
	end

	warn("[LPT HUB] DataLoaded không phải BoolValue:", dataLoaded.ClassName)
	return true
end

--============================================================
-- LOAD MAIN UI
--============================================================

local function loadMainUI()
	if State.Loading then return end

	State.Loading = true
	keyFrame.Visible = true

	setStatus("KEY hợp lệ • Đang nhận diện game...", COLORS.Success)
	task.wait(.25)

	local resolved, resolveError = resolveGame()

	if not resolved then
		keyFrame.Visible = true
		setStatus(resolveError, COLORS.Danger)
		showNotification("Game Not Supported", resolveError, "error")
		State.Loading = false
		return
	end

	task.wait(.4)

	if not waitForGameData(State.GameConfig) then
		keyFrame.Visible = true
		setStatus("Game chưa sẵn sàng.", COLORS.Danger)
		showNotification("Game Loading", "DataLoaded chưa hoàn tất.", "error")
		State.Loading = false
		return
	end

	setStatus("Đang tải MainUI...", COLORS.Info)
	showNotification("Loading UI", "Đang tải " .. State.GameName .. "...", "info")
	task.wait(.25)

	local ok, result = pcall(function()
		local response = game:HttpGet(State.MainUI)

		if not response or response == "" then
			error("MainUI trả về dữ liệu rỗng.")
		end

		local mainFunction = loadstring(response)

		if type(mainFunction) ~= "function" then
			error("MainUI không trả về function.")
		end

		return mainFunction()
	end)

	if not ok then
		keyFrame.Visible = true
		setStatus("Không thể tải MainUI.", COLORS.Danger)
		showNotification("MainUI Error", tostring(result), "error")
		warn("[LPT HUB] MainUI Error:", result)
		State.Loading = false
		return
	end

	setStatus("Đã tải " .. State.GameName, COLORS.Success)
	showNotification("LPT HUB", "Đã tải UI: " .. State.GameName, "success")

	task.wait(.25)

	keyFrame.Visible = false
	State.Loading = false

	print("[LPT HUB] MainUI loaded:", State.GameName)
end

--============================================================
-- SUBMIT KEY
--============================================================

local function attemptSubmit()
	if State.Submitting or State.Loading then return end

	State.Submitting = true

	local key = tostring(keyInput.Text or "")
	key = key:gsub("^%s+", ""):gsub("%s+$", "")

	if key == "" then
		setStatus("Vui lòng nhập KEY.", COLORS.Danger)
		State.Submitting = false
		return
	end

	setStatus("Đang xác thực KEY...", COLORS.Info)
	task.wait(.2)

	if not checkKey(key) then
		setStatus("KEY không đúng, thử lại.", COLORS.Danger)
		showNotification("Invalid Key", "KEY không hợp lệ.", "error")

		tween(inputStroke, {Color = COLORS.Danger, Transparency = 0}, .1)
		task.wait(.15)
		tween(inputStroke, {Color = COLORS.Border, Transparency = .15}, .2)

		State.Submitting = false
		return
	end

	State.KeyValid = true
	saveKey(key)

	showNotification("Key Valid!", "KEY hợp lệ. Đang nhận diện game...", "success")
	setStatus("KEY hợp lệ! Đang nhận diện game...", COLORS.Success)

	State.Submitting = false
	loadMainUI()
end

--============================================================
-- EVENTS
--============================================================

submitButton.MouseButton1Click:Connect(attemptSubmit)

keyInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then attemptSubmit() end
end)

--============================================================
-- LOAD SAVED KEY
--============================================================

task.spawn(function()
	local savedKey = getSavedKey()

	if not savedKey or savedKey == "" then
		print("[LPT HUB] No saved key.")
		return
	end

	task.wait(.4)

	keyInput.Text = savedKey
	setStatus("Đang xác thực KEY đã lưu...", COLORS.Info)

	task.wait(.4)
	attemptSubmit()
end)

print("[LPT HUB] KeyUI started.")
print("[LPT HUB] PlaceId:", game.PlaceId)
print("[LPT HUB] Waiting for valid key...")
