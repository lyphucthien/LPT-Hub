local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// ============================================================
--// CONFIG
--// ============================================================

local MAIN_UI = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/MainUI.luau"

local VALID_KEYS = {
	["LPT-HUB"] = true,
}

local GET_KEY_LINK = "https://link4sub.com/owycAYxKdu"

--// ============================================================
--// PALETTE
--// ============================================================

local COLORS = {
	Background = Color3.fromRGB(8, 18, 32),
	SurfaceLight = Color3.fromRGB(40, 44, 58),
	Card = Color3.fromRGB(34, 38, 50),

	Accent = Color3.fromRGB(168, 105, 245),
	AccentB = Color3.fromRGB(236, 72, 153),

	Text = Color3.fromRGB(240, 241, 245),
	TextDim = Color3.fromRGB(145, 153, 168),
	Border = Color3.fromRGB(52, 56, 70),

	Danger = Color3.fromRGB(255, 92, 108),
	Success = Color3.fromRGB(74, 222, 128),
}

--// ============================================================
--// HELPERS
--// ============================================================

local function tween(obj, props, time, style)
	local tweenInfo = TweenInfo.new(
		time or 0.18,
		style or Enum.EasingStyle.Quad
	)

	TweenService:Create(obj, tweenInfo, props):Play()
end

local function applyGradient(guiObject, colorA, colorB, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 0
	gradient.Parent = guiObject
	return gradient
end

local function checkKey(key)
	return VALID_KEYS[key] == true
end

--// ============================================================
--// SCREEN GUI
--// ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LPTKeyUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--// ============================================================
--// KEY UI
--// ============================================================

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyUI"
keyFrame.Size = UDim2.new(0, 340, 0, 330)
keyFrame.Position = UDim2.new(0.5, -170, 0.5, -165)
keyFrame.BackgroundColor3 = COLORS.Background
keyFrame.BackgroundTransparency = 0.08
keyFrame.BorderSizePixel = 0
keyFrame.ClipsDescendants = true
keyFrame.ZIndex = 10
keyFrame.Parent = screenGui

local keyFrameCorner = Instance.new("UICorner")
keyFrameCorner.CornerRadius = UDim.new(0, 18)
keyFrameCorner.Parent = keyFrame

local keyFrameStroke = Instance.new("UIStroke")
keyFrameStroke.Color = COLORS.Border
keyFrameStroke.Thickness = 1.5
keyFrameStroke.Transparency = 0.2
keyFrameStroke.Parent = keyFrame

applyGradient(
	keyFrameStroke,
	COLORS.Accent,
	COLORS.AccentB,
	45
)

--// ============================================================
--// LOGO
--// ============================================================

local keyLogo = Instance.new("Frame")
keyLogo.Name = "KeyLogo"
keyLogo.Size = UDim2.new(0, 54, 0, 54)
keyLogo.Position = UDim2.new(0, 24, 0, 24)
keyLogo.BackgroundColor3 = COLORS.SurfaceLight
keyLogo.BorderSizePixel = 0
keyLogo.ZIndex = 11
keyLogo.Parent = keyFrame

local keyLogoCorner = Instance.new("UICorner")
keyLogoCorner.CornerRadius = UDim.new(1, 0)
keyLogoCorner.Parent = keyLogo

local keyLogoStroke = Instance.new("UIStroke")
keyLogoStroke.Color = COLORS.Border
keyLogoStroke.Thickness = 1
keyLogoStroke.Transparency = 0.15
keyLogoStroke.Parent = keyLogo

local keyLogoText = Instance.new("TextLabel")
keyLogoText.Name = "LogoText"
keyLogoText.Size = UDim2.new(1, 0, 1, 0)
keyLogoText.BackgroundTransparency = 1
keyLogoText.Text = "L"
keyLogoText.TextColor3 = COLORS.Text
keyLogoText.TextSize = 24
keyLogoText.Font = Enum.Font.GothamBold
keyLogoText.TextXAlignment = Enum.TextXAlignment.Center
keyLogoText.TextYAlignment = Enum.TextYAlignment.Center
keyLogoText.ZIndex = 12
keyLogoText.Parent = keyLogo

--// ============================================================
--// HEADER
--// ============================================================

local keyTitle = Instance.new("TextLabel")
keyTitle.Name = "KeyTitle"
keyTitle.Size = UDim2.new(0, 250, 0, 28)
keyTitle.Position = UDim2.new(0, 92, 0, 20)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "LPT HUB KEY SYSTEM"
keyTitle.TextColor3 = Color3.fromRGB(245, 245, 248)
keyTitle.TextSize = 22
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.TextYAlignment = Enum.TextYAlignment.Center
keyTitle.ZIndex = 11
keyTitle.Parent = keyFrame

local keySubtitle = Instance.new("TextLabel")
keySubtitle.Name = "KeySubtitle"
keySubtitle.Size = UDim2.new(0, 250, 0, 14)
keySubtitle.Position = UDim2.new(0, 92, 0, 47)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "THE AUTHENTICATE SYSTEM"
keySubtitle.TextColor3 = COLORS.TextDim
keySubtitle.TextSize = 9
keySubtitle.Font = Enum.Font.Gotham
keySubtitle.TextXAlignment = Enum.TextXAlignment.Left
keySubtitle.TextYAlignment = Enum.TextYAlignment.Center
keySubtitle.ZIndex = 11
keySubtitle.Parent = keyFrame

--// ============================================================
--// INPUT
--// ============================================================

local keyInputBox = Instance.new("Frame")
keyInputBox.Name = "KeyInputBox"
keyInputBox.Size = UDim2.new(1, -40, 0, 44)
keyInputBox.Position = UDim2.new(0, 20, 0, 100)
keyInputBox.BackgroundColor3 = COLORS.Card
keyInputBox.BorderSizePixel = 0
keyInputBox.ZIndex = 11
keyInputBox.Parent = keyFrame

local keyInputCorner = Instance.new("UICorner")
keyInputCorner.CornerRadius = UDim.new(0, 12)
keyInputCorner.Parent = keyInputBox

local keyInputStroke = Instance.new("UIStroke")
keyInputStroke.Color = COLORS.Border
keyInputStroke.Thickness = 1
keyInputStroke.Transparency = 0.15
keyInputStroke.Parent = keyInputBox

local keyInput = Instance.new("TextBox")
keyInput.Name = "KeyInput"
keyInput.Size = UDim2.new(1, -32, 1, 0)
keyInput.Position = UDim2.new(0, 16, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.PlaceholderText = "Enter Key..."
keyInput.PlaceholderColor3 = COLORS.TextDim
keyInput.Text = ""
keyInput.TextColor3 = COLORS.Text
keyInput.TextSize = 14
keyInput.Font = Enum.Font.Gotham
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.TextYAlignment = Enum.TextYAlignment.Center
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 12
keyInput.Parent = keyInputBox

keyInput.Focused:Connect(function()
	tween(keyInputStroke, {
		Color = COLORS.Accent,
		Transparency = 0,
	})
end)

keyInput.FocusLost:Connect(function()
	tween(keyInputStroke, {
		Color = COLORS.Border,
		Transparency = 0.15,
	})
end)

--// ============================================================
--// GET KEY
--// ============================================================

local getKeyButton = Instance.new("TextButton")
getKeyButton.Name = "GetKeyButton"
getKeyButton.Size = UDim2.new(1, -40, 0, 40)
getKeyButton.Position = UDim2.new(0, 20, 0, 154)
getKeyButton.BackgroundColor3 = COLORS.SurfaceLight
getKeyButton.BorderSizePixel = 0
getKeyButton.Text = "GET KEY"
getKeyButton.TextColor3 = COLORS.Text
getKeyButton.TextSize = 13
getKeyButton.Font = Enum.Font.GothamBold
getKeyButton.AutoButtonColor = false
getKeyButton.ZIndex = 11
getKeyButton.Parent = keyFrame

local getKeyCorner = Instance.new("UICorner")
getKeyCorner.CornerRadius = UDim.new(0, 12)
getKeyCorner.Parent = getKeyButton

local getKeyStroke = Instance.new("UIStroke")
getKeyStroke.Color = COLORS.Border
getKeyStroke.Thickness = 1
getKeyStroke.Transparency = 0.2
getKeyStroke.Parent = getKeyButton

getKeyButton.MouseEnter:Connect(function()
	tween(getKeyButton, {
		BackgroundColor3 = COLORS.Card,
	})
end)

getKeyButton.MouseLeave:Connect(function()
	tween(getKeyButton, {
		BackgroundColor3 = COLORS.SurfaceLight,
	})
end)

getKeyButton.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(GET_KEY_LINK)

		getKeyButton.Text = "LINK COPIED!"

		task.delay(1.2, function()
			if getKeyButton.Parent then
				getKeyButton.Text = "GET KEY"
			end
		end)
	end
end)

--// ============================================================
--// SUBMIT
--// ============================================================

local submitButton = Instance.new("TextButton")
submitButton.Name = "SubmitButton"
submitButton.Size = UDim2.new(1, -40, 0, 44)
submitButton.Position = UDim2.new(0, 20, 0, 208)
submitButton.BackgroundColor3 = COLORS.Accent
submitButton.BorderSizePixel = 0
submitButton.Text = "Submit Key"
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.TextSize = 14
submitButton.Font = Enum.Font.GothamBold
submitButton.AutoButtonColor = false
submitButton.ZIndex = 11
submitButton.Parent = keyFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 12)
submitCorner.Parent = submitButton

applyGradient(
	submitButton,
	COLORS.Accent,
	COLORS.AccentB,
	0
)

submitButton.MouseEnter:Connect(function()
	tween(
		submitButton,
		{Size = UDim2.new(1, -36, 0, 44)},
		0.12
	)
end)

submitButton.MouseLeave:Connect(function()
	tween(
		submitButton,
		{Size = UDim2.new(1, -40, 0, 44)},
		0.12
	)
end)

--// ============================================================
--// STATUS
--// ============================================================

local keyStatus = Instance.new("TextLabel")
keyStatus.Name = "KeyStatus"
keyStatus.Size = UDim2.new(1, -40, 0, 18)
keyStatus.Position = UDim2.new(0, 20, 0, 260)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = COLORS.Danger
keyStatus.TextSize = 12
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextXAlignment = Enum.TextXAlignment.Left
keyStatus.ZIndex = 11
keyStatus.Parent = keyFrame

--// ============================================================
--// LOAD MAIN UI
--// ============================================================

local loadingMain = false

local function openMainUI()
	if loadingMain then
		return
	end

	loadingMain = true

	keyStatus.TextColor3 = COLORS.Success
	keyStatus.Text = "Key hợp lệ! Đang mở..."

	task.wait(0.4)

	keyFrame.Visible = false

	local success, result = pcall(function()
		local response = game:HttpGet(MAIN_UI)
		local mainFunction = loadstring(response)

		if type(mainFunction) ~= "function" then
			error("MainUI.lua không trả về một function hợp lệ.")
		end

		return mainFunction()
	end)

	if not success then
		keyFrame.Visible = true
		keyStatus.TextColor3 = COLORS.Danger
		keyStatus.Text = "Không thể tải Main UI."

		warn("[LPT KeyUI] MainUI error:", result)
		loadingMain = false
	end
end

--// ============================================================
--// SUBMIT FUNCTION
--// ============================================================

local submitting = false

local function attemptSubmit()
	if submitting then
		return
	end

	submitting = true

	local key = keyInput.Text

	if key == "" then
		keyStatus.TextColor3 = COLORS.Danger
		keyStatus.Text = "Vui lòng nhập key."
		submitting = false
		return
	end

	if checkKey(key) then
		openMainUI()
	else
		keyStatus.TextColor3 = COLORS.Danger
		keyStatus.Text = "Key không đúng, thử lại."

		tween(
			keyInputStroke,
			{
				Color = COLORS.Danger,
				Transparency = 0,
			},
			0.1
		)

		task.wait(0.15)

		tween(
			keyInputStroke,
			{
				Color = COLORS.Border,
				Transparency = 0.15,
			},
			0.2
		)

		submitting = false
	end
end

submitButton.MouseButton1Click:Connect(attemptSubmit)

keyInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		attemptSubmit()
	end
end)
