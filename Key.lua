local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
if not player then
    warn("LPT Hub: LocalPlayer is unavailable.")
    return
end

local playerGui = player:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local RAW = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/"
local GET_KEY_LINK = "https://link4sub.com/owycAYxKdu"
local DISCORD_LINK = "https://discord.gg/gyZ27Hw9qu"
local WEBSITE_LINK = "https://youtube.com/@lyphucthien1803"
local KEY_API_URL = "https://lyphucthien.vercel.app/api/get-key"

local UNIVERSAL_SCRIPT = RAW .. "Script%20Cho%20Game%20Ko%20H%E1%BB%97%20Tr%E1%BB%A3/Script.lua"

local GAME_HO_TRO = {
    ["+1 Speed Keyboard Escape"] = {
        Name = "+1 Speed Keyboard Escape",
        PlaceId = {95082159892680},
        UniverseId = {9584852943},
        WaitForDataLoaded = false,
        MainUI = RAW .. "%2B1%20Speed%20Keyboard%20Escape/MainUI.lua",
    },
    ["Blox Fruits"] = {
        Name = "Blox Fruits",
        PlaceId = {85211729168715},
        UniverseId = {994732206},
        WaitForDataLoaded = false,
        MainUI = RAW .. "Blox%20Fruits/Main.lua",
    },
}

local LPT_HUB_FOLDER = "LPT Hub"
local KEY_FILE = LPT_HUB_FOLDER .. "/LPT_Hub_Key.json"
local KEY_DURATION = 3 * 60 * 60

local COLORS = {
    Background = Color3.fromRGB(5, 5, 5),
    Surface = Color3.fromRGB(20, 20, 20),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(145, 145, 150),
    Border = Color3.fromRGB(45, 45, 45),
    Danger = Color3.fromRGB(255, 92, 108),
    Success = Color3.fromRGB(74, 222, 128),
    Info = Color3.fromRGB(96, 165, 250),
    Warning = Color3.fromRGB(250, 204, 21),
}

local ICON_URLS = {
    Key = "https://img.icons8.com/ios-filled/50/969696/key.png",
    Discord = "https://img.icons8.com/color/96/discord-new-logo.png",
    YouTube = "https://img.icons8.com/color/96/youtube-play.png",
}

local State = {
    KeyValid = false,
    PlaceId = nil,
    UniverseId = nil,
    GameName = "Unknown Game",
    RobloxGameName = nil,
    GameSupported = false,
    GameConfig = nil,
    MainUI = nil,
    Loading = false,
    Submitting = false,
}

--============================================================
-- HELPERS
--============================================================

local function safeCall(callback, ...)
    local args = table.pack(...)
    return pcall(function()
        return callback(table.unpack(args, 1, args.n))
    end)
end

local function tween(object, properties, duration, style)
    if not object or not object.Parent then
        return nil
    end

    local ok, result = pcall(function()
        local animation = TweenService:Create(
            object,
            TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad),
            properties
        )
        animation:Play()
        return animation
    end)

    return ok and result or nil
end

local function makeCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function makeLabel(parent, name, text, size, position, font, textSize, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = text or ""
    label.TextColor3 = color or COLORS.Text
    label.TextSize = textSize or 13
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 12
    label.Parent = parent
    return label
end

local function ensureLPTFolder()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return
    end

    local ok, exists = pcall(isfolder, LPT_HUB_FOLDER)
    if ok and not exists then
        pcall(makefolder, LPT_HUB_FOLDER)
    end
end

local function getWebImage(url, fileName)
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then
        return nil
    end

    ensureLPTFolder()
    local path = LPT_HUB_FOLDER .. "/" .. fileName

    local ok, asset = pcall(function()
        local needsDownload = true
        if type(isfile) == "function" then
            local checkOK, exists = pcall(isfile, path)
            needsDownload = not (checkOK and exists)
        end

        if needsDownload then
            local response = game:HttpGet(url)
            if type(response) ~= "string" or response == "" then
                error("Empty image response")
            end
            writefile(path, response)
        end

        return getAsset(path)
    end)

    return ok and asset or nil
end

local function copyToClipboard(text)
    if type(setclipboard) ~= "function" then
        return false
    end
    local ok = pcall(setclipboard, text)
    return ok
end

--============================================================
-- KEY FILE
--============================================================

ensureLPTFolder()

local function getSavedKey()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end

    ensureLPTFolder()
    local ok, content = pcall(function()
        if not isfile(KEY_FILE) then
            return nil
        end
        return readfile(KEY_FILE)
    end)

    if not ok or type(content) ~= "string" or content == "" then
        return nil
    end

    local decoded, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if decoded and type(data) == "table" then
        local key = data.key
        local savedAt = tonumber(data.savedAt)

        if type(key) ~= "string" or key == "" then
            return nil
        end

        if savedAt then
            local now = os.time()
            if savedAt > now + 60 or now - savedAt > KEY_DURATION then
                if type(delfile) == "function" then
                    pcall(delfile, KEY_FILE)
                end
                return nil
            end
        end
        return key
    end

    return content
end

local function saveKey(key)
    if type(writefile) ~= "function" or type(key) ~= "string" or key == "" then
        return false
    end

    ensureLPTFolder()
    local encodeOK, content = pcall(function()
        return HttpService:JSONEncode({key = key, savedAt = os.time()})
    end)
    if not encodeOK then
        return false
    end

    local writeOK = pcall(function()
        writefile(KEY_FILE, content)
    end)
    return writeOK
end

--============================================================
-- GUI CREATION
--============================================================

local oldGui = playerGui:FindFirstChild("LPTKeyUI")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LPTKeyUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local function showNotification(titleText, messageText, notificationType)
    if not screenGui or not screenGui.Parent then
        return
    end

    local tint = COLORS.Info
    if notificationType == "success" then
        tint = COLORS.Success
    elseif notificationType == "error" then
        tint = COLORS.Danger
    elseif notificationType == "warning" then
        tint = COLORS.Warning
    end

    local toast = Instance.new("Frame")
    toast.Name = "LPTToast"
    toast.Size = UDim2.fromOffset(300, 68)
    toast.Position = UDim2.new(1, -316, 0, 18)
    toast.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    toast.BorderSizePixel = 0
    toast.ZIndex = 50
    toast.Parent = screenGui
    makeCorner(toast, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = tint
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = toast

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -16)
    accent.Position = UDim2.fromOffset(8, 8)
    accent.BackgroundColor3 = tint
    accent.BorderSizePixel = 0
    accent.ZIndex = 51
    accent.Parent = toast
    makeCorner(accent, 2)

    local title = makeLabel(toast, "Title", tostring(titleText or "LPT Hub"), UDim2.new(1, -30, 0, 22), UDim2.fromOffset(20, 8), Enum.Font.GothamBold, 13, COLORS.Text)
    title.ZIndex = 52

    local message = makeLabel(toast, "Message", tostring(messageText or ""), UDim2.new(1, -30, 0, 30), UDim2.fromOffset(20, 30), Enum.Font.Gotham, 11, COLORS.TextDim)
    message.TextWrapped = true
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.ZIndex = 52

    toast.BackgroundTransparency = 1
    toast.Position = UDim2.new(1, 10, 0, 18)
    tween(toast, {BackgroundTransparency = 0, Position = UDim2.new(1, -316, 0, 18)}, 0.2)

    task.delay(3, function()
        if toast and toast.Parent then
            tween(toast, {BackgroundTransparency = 1, Position = UDim2.new(1, 10, 0, 18)}, 0.2)
            task.delay(0.25, function()
                if toast and toast.Parent then
                    toast:Destroy()
                end
            end)
        end
    end)
end

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyUI"
keyFrame.Size = UDim2.fromOffset(610, 270)
keyFrame.Position = UDim2.new(0.5, -305, 0.5, -135)
keyFrame.BackgroundColor3 = COLORS.Background
keyFrame.BackgroundTransparency = 0.02
keyFrame.BorderSizePixel = 0
keyFrame.ClipsDescendants = true
keyFrame.ZIndex = 10
keyFrame.Parent = screenGui
makeCorner(keyFrame, 7)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(42, 42, 46)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.1
frameStroke.Parent = keyFrame

local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 357, 1, 0)
leftPanel.BackgroundTransparency = 1
leftPanel.BorderSizePixel = 0
leftPanel.ZIndex = 10
leftPanel.Parent = keyFrame

local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Position = UDim2.fromOffset(358, 0)
rightPanel.Size = UDim2.new(1, -358, 1, 0)
rightPanel.BackgroundTransparency = 1
rightPanel.BorderSizePixel = 0
rightPanel.ZIndex = 10
rightPanel.Parent = keyFrame

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Position = UDim2.fromOffset(357, 29)
divider.Size = UDim2.new(0, 1, 1, -58)
divider.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
divider.BorderSizePixel = 0
divider.ZIndex = 11
divider.Parent = keyFrame

local logo = Instance.new("ImageLabel")
logo.Name = "KeyLogo"
logo.Size = UDim2.fromOffset(52, 52)
logo.Position = UDim2.fromOffset(32, 16)
logo.BackgroundTransparency = 1
logo.BorderSizePixel = 0
logo.Image = "rbxassetid://86498268964550"
logo.ScaleType = Enum.ScaleType.Fit
logo.ZIndex = 12
logo.Parent = leftPanel

makeLabel(leftPanel, "HeaderTitle", "LPT Hub", UDim2.fromOffset(210, 28), UDim2.fromOffset(108, 23), Enum.Font.GothamBold, 24, Color3.fromRGB(245, 245, 245))
makeLabel(leftPanel, "HeaderSubtitle", "Key system", UDim2.fromOffset(210, 18), UDim2.fromOffset(109, 49), Enum.Font.Gotham, 12, Color3.fromRGB(105, 105, 105))

local dragHandle = Instance.new("Frame")
dragHandle.Name = "DragHandle"
dragHandle.Size = UDim2.fromOffset(357, 86)
dragHandle.BackgroundTransparency = 1
dragHandle.BorderSizePixel = 0
dragHandle.Active = true
dragHandle.ZIndex = 11
dragHandle.Parent = keyFrame

local dragging = false
local dragStart = nil
local startPosition = nil
local dragEndConnection = nil

local function beginWindowDrag(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    dragging = true
    dragStart = input.Position
    startPosition = keyFrame.Position

    if dragEndConnection then
        dragEndConnection:Disconnect()
    end
    dragEndConnection = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
            if dragEndConnection then
                dragEndConnection:Disconnect()
                dragEndConnection = nil
            end
        end
    end)
end

dragHandle.InputBegan:Connect(beginWindowDrag)
logo.InputBegan:Connect(beginWindowDrag)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not startPosition then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    keyFrame.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

makeLabel(leftPanel, "LicenseLabel", "License key", UDim2.fromOffset(300, 20), UDim2.fromOffset(29, 88), Enum.Font.GothamMedium, 14, Color3.fromRGB(165, 165, 170))

local inputBox = Instance.new("Frame")
inputBox.Name = "KeyInputBox"
inputBox.Size = UDim2.fromOffset(300, 40)
inputBox.Position = UDim2.fromOffset(29, 112)
inputBox.BackgroundColor3 = COLORS.Surface
inputBox.BorderSizePixel = 0
inputBox.ZIndex = 11
inputBox.Parent = leftPanel
makeCorner(inputBox, 6)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = COLORS.Border
inputStroke.Thickness = 1
inputStroke.Transparency = 0.12
inputStroke.Parent = inputBox

local keyIcon = Instance.new("ImageLabel")
keyIcon.Name = "KeyIcon"
keyIcon.Size = UDim2.fromOffset(16, 16)
keyIcon.Position = UDim2.new(0, 9, 0.5, -8)
keyIcon.BackgroundTransparency = 1
keyIcon.ScaleType = Enum.ScaleType.Fit
keyIcon.ZIndex = 12
keyIcon.Parent = inputBox

task.spawn(function()
    local image = getWebImage(ICON_URLS.Key, "icon_key.png")
    if image and keyIcon.Parent then
        keyIcon.Image = image
    end
end)

local keyInput = Instance.new("TextBox")
keyInput.Name = "LicenseInput"
keyInput.Size = UDim2.new(1, -39, 1, 0)
keyInput.Position = UDim2.fromOffset(31, 0)
keyInput.BackgroundTransparency = 1
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Paste your key here"
keyInput.PlaceholderColor3 = Color3.fromRGB(94, 94, 94)
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(245, 245, 245)
keyInput.TextSize = 14
keyInput.Font = Enum.Font.Gotham
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 12
keyInput.Parent = inputBox

keyInput.Focused:Connect(function()
    tween(inputStroke, {Color = Color3.fromRGB(100, 100, 100), Transparency = 0}, 0.15)
end)
keyInput.FocusLost:Connect(function()
    tween(inputStroke, {Color = COLORS.Border, Transparency = 0.12}, 0.15)
end)

local getKeyButton = Instance.new("TextButton")
getKeyButton.Name = "GetKeyButton"
getKeyButton.Size = UDim2.fromOffset(144, 40)
getKeyButton.Position = UDim2.fromOffset(29, 166)
getKeyButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
getKeyButton.BorderSizePixel = 0
getKeyButton.Text = "Get a key"
getKeyButton.TextColor3 = COLORS.Text
getKeyButton.TextSize = 13
getKeyButton.Font = Enum.Font.GothamMedium
getKeyButton.AutoButtonColor = true
getKeyButton.ZIndex = 11
getKeyButton.Parent = leftPanel
makeCorner(getKeyButton, 6)
local getStroke = Instance.new("UIStroke")
getStroke.Color = Color3.fromRGB(42, 42, 42)
getStroke.Thickness = 1
getStroke.Parent = getKeyButton

local submitButton = Instance.new("TextButton")
submitButton.Name = "SubmitButton"
submitButton.Size = UDim2.fromOffset(144, 40)
submitButton.Position = UDim2.fromOffset(185, 166)
submitButton.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
submitButton.BorderSizePixel = 0
submitButton.Text = "Submit"
submitButton.TextColor3 = Color3.fromRGB(15, 15, 15)
submitButton.TextSize = 13
submitButton.Font = Enum.Font.GothamBold
submitButton.AutoButtonColor = true
submitButton.ZIndex = 11
submitButton.Parent = leftPanel
makeCorner(submitButton, 6)

local keyStatus = makeLabel(leftPanel, "KeyStatus", "", UDim2.fromOffset(300, 30), UDim2.fromOffset(29, 216), Enum.Font.Gotham, 12, COLORS.Danger)
keyStatus.TextWrapped = true
keyStatus.TextYAlignment = Enum.TextYAlignment.Top

makeLabel(rightPanel, "DetectedLabel", "Detected game", UDim2.fromOffset(196, 20), UDim2.fromOffset(28, 20), Enum.Font.GothamMedium, 13, Color3.fromRGB(165, 165, 170))

local gameCard = Instance.new("Frame")
gameCard.Name = "DetectedGameCard"
gameCard.Size = UDim2.fromOffset(196, 60)
gameCard.Position = UDim2.fromOffset(28, 44)
gameCard.BackgroundColor3 = COLORS.Surface
gameCard.BorderSizePixel = 0
gameCard.ZIndex = 11
gameCard.Parent = rightPanel
makeCorner(gameCard, 6)
local gameCardStroke = Instance.new("UIStroke")
gameCardStroke.Color = Color3.fromRGB(40, 40, 40)
gameCardStroke.Thickness = 1
gameCardStroke.Parent = gameCard

local gameIcon = Instance.new("ImageLabel")
gameIcon.Name = "GameIcon"
gameIcon.Size = UDim2.fromOffset(39, 39)
gameIcon.Position = UDim2.fromOffset(10, 10)
gameIcon.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
gameIcon.BorderSizePixel = 0
gameIcon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId or game.PlaceId) .. "&w=150&h=150"
gameIcon.ScaleType = Enum.ScaleType.Crop
gameIcon.ZIndex = 12
gameIcon.Parent = gameCard
makeCorner(gameIcon, 5)

local detectedGameName = makeLabel(gameCard, "GameName", tostring(game.Name or "Current game"), UDim2.new(1, -58, 0, 30), UDim2.fromOffset(57, 7), Enum.Font.GothamMedium, 12, Color3.fromRGB(238, 238, 238))
detectedGameName.TextWrapped = true
detectedGameName.TextTruncate = Enum.TextTruncate.AtEnd
local detectedGameSub = makeLabel(gameCard, "GameSubtitle", "Universal script", UDim2.new(1, -58, 0, 18), UDim2.fromOffset(57, 35), Enum.Font.Gotham, 10, Color3.fromRGB(110, 110, 110))
detectedGameSub.TextTruncate = Enum.TextTruncate.AtEnd

makeLabel(rightPanel, "ExecutorLabel", "Executor", UDim2.fromOffset(85, 18), UDim2.fromOffset(28, 114), Enum.Font.GothamMedium, 13, Color3.fromRGB(165, 165, 170))
local executorValue = makeLabel(rightPanel, "ExecutorValue", "Detecting...", UDim2.fromOffset(108, 18), UDim2.fromOffset(116, 114), Enum.Font.GothamMedium, 13, Color3.fromRGB(210, 210, 215))
executorValue.TextXAlignment = Enum.TextXAlignment.Right
executorValue.TextTruncate = Enum.TextTruncate.AtEnd

local function detectExecutorName()
    local env = _G
    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            env = result
        end
    end

    for _, detectorName in ipairs({"identifyexecutor", "getexecutorname", "get_executor_name"}) do
        local detector = env[detectorName] or _G[detectorName]
        if type(detector) == "function" then
            local ok, name = pcall(detector)
            if ok and type(name) == "string" and name ~= "" then
                return name
            end
        end
    end

    local markers = {
        {"KRNL_LOADED", "KRNL"}, {"syn", "Synapse X"},
        {"fluxus", "Fluxus"}, {"Fluxus", "Fluxus"},
        {"DELTA_LOADED", "Delta"}, {"delta", "Delta"},
        {"Electron", "Electron"}, {"electron", "Electron"},
        {"SIRHURT_LOADED", "SirHurt"},
    }

    for _, marker in ipairs(markers) do
        local value = env[marker[1]] or _G[marker[1]]
        if value ~= nil and value ~= false then
            return marker[2]
        end
    end

    if type(env.is_sirhurt_closure) == "function"
        or type(_G.is_sirhurt_closure) == "function" then
        return "SirHurt"
    end

    return "Unknown"
end

executorValue.Text = detectExecutorName()

makeLabel(rightPanel, "StatusTitle", "Status", UDim2.fromOffset(85, 18), UDim2.fromOffset(28, 136), Enum.Font.GothamMedium, 13, Color3.fromRGB(165, 165, 170))
local statusValue = makeLabel(rightPanel, "StatusValue", "Key required", UDim2.fromOffset(108, 18), UDim2.fromOffset(116, 136), Enum.Font.GothamMedium, 13, Color3.fromRGB(210, 210, 215))
statusValue.TextXAlignment = Enum.TextXAlignment.Right

local statusDivider = Instance.new("Frame")
statusDivider.Position = UDim2.fromOffset(28, 164)
statusDivider.Size = UDim2.fromOffset(196, 1)
statusDivider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusDivider.BorderSizePixel = 0
statusDivider.ZIndex = 11
statusDivider.Parent = rightPanel

local function makeIconButton(name, posX, labelText, fallbackText, fallbackColor, fallbackSize)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(94, 40)
    button.Position = UDim2.fromOffset(posX, 176)
    button.BackgroundColor3 = COLORS.Surface
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = true
    button.ZIndex = 11
    button.Parent = rightPanel
    makeCorner(button, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 40)
    stroke.Thickness = 1
    stroke.Parent = button

    local row = Instance.new("Frame")
    row.Name = "Row"
    row.Size = UDim2.fromScale(1, 1)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.Parent = button

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = row

    local image = Instance.new("ImageLabel")
    image.Name = "Icon"
    image.Size = UDim2.fromOffset(22, 22)
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Fit
    image.Visible = false
    image.LayoutOrder = 1
    image.ZIndex = 12
    image.Parent = row

    local fallback = makeLabel(row, "Fallback", fallbackText, UDim2.fromOffset(22, 22), UDim2.fromOffset(0, 0), Enum.Font.GothamBold, fallbackSize, fallbackColor)
    fallback.TextXAlignment = Enum.TextXAlignment.Center
    fallback.LayoutOrder = 1

    local nameLabel = makeLabel(row, "Name", labelText, UDim2.fromOffset(0, 22), UDim2.fromOffset(0, 0), Enum.Font.GothamMedium, 12, Color3.fromRGB(235, 235, 235))
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.LayoutOrder = 2

    return button, stroke, image, fallback
end

local discordButton, discordStroke, discordImg, discordFallback = makeIconButton("DiscordCard", 28, "Discord", "◉", Color3.fromRGB(130, 145, 255), 18)
local websiteButton, websiteStroke, youtubeImg, youtubeFallback = makeIconButton("WebsiteCard", 130, "YouTube", "▶", Color3.fromRGB(255, 60, 60), 16)

task.spawn(function()
    local image = getWebImage(ICON_URLS.Discord, "icon_discord.png")
    if image and discordImg.Parent then
        discordImg.Image = image
        discordImg.Visible = true
        discordFallback.Visible = false
    end
end)

task.spawn(function()
    local image = getWebImage(ICON_URLS.YouTube, "icon_youtube.png")
    if image and youtubeImg.Parent then
        youtubeImg.Image = image
        youtubeImg.Visible = true
        youtubeFallback.Visible = false
    end
end)

--============================================================
-- STATUS AND GAME DETECTION
--============================================================

local function updateDetectedGame(name, subtitleText, iconId)
    detectedGameName.Text = tostring(name or "Unknown game")
    detectedGameSub.Text = tostring(subtitleText or "Universal script")
    local id = tonumber(iconId) or tonumber(game.GameId) or tonumber(game.PlaceId)
    if id then
        gameIcon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(id) .. "&w=150&h=150"
    end
end

local function updateKeyStatus(message, color)
    local lower = string.lower(tostring(message or ""))
    if color == COLORS.Success or lower:find("hợp lệ", 1, true)
        or lower:find("đã tải", 1, true) or lower:find("valid", 1, true) then
        statusValue.Text = "Key valid"
        statusValue.TextColor3 = COLORS.Success
    elseif color == COLORS.Info or lower:find("đang", 1, true)
        or lower:find("checking", 1, true) or lower:find("loading", 1, true) then
        statusValue.Text = "Checking..."
        statusValue.TextColor3 = COLORS.Info
    elseif color == COLORS.Danger or lower:find("không đúng", 1, true)
        or lower:find("không thể", 1, true) or lower:find("lỗi", 1, true)
        or lower:find("error", 1, true) then
        statusValue.Text = "Invalid / error"
        statusValue.TextColor3 = COLORS.Danger
    else
        statusValue.Text = "Key required"
        statusValue.TextColor3 = COLORS.Warning
    end
end

local function setStatus(message, color)
    keyStatus.Text = tostring(message or "")
    keyStatus.TextColor3 = color or COLORS.Text
    updateKeyStatus(message, color)
end

local function getUniverseId(placeId)
    if not placeId then
        return nil
    end

    local url = "https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe"
    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(response) ~= "string" or response == "" then
        return nil
    end

    local decodeOK, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not decodeOK or type(data) ~= "table" then
        return nil
    end

    return tonumber(data.universeId)
end

local function containsId(list, id)
    if not id or type(list) ~= "table" then
        return false
    end
    local target = tonumber(id)
    for _, value in ipairs(list) do
        if tonumber(value) == target then
            return true
        end
    end
    return false
end

local function findGameConfig(placeId, universeId)
    for configKey, config in pairs(GAME_HO_TRO) do
        if type(config) == "table" then
            if containsId(config.PlaceId, placeId) then
                return config, "PlaceId", configKey
            end
            if containsId(config.UniverseId, universeId) then
                return config, "UniverseId", configKey
            end
        end
    end
    return nil, nil, nil
end

local function fetchRobloxGameName()
    local placeId = tonumber(game.PlaceId)
    local universeId = tonumber(game.GameId)

    for _, config in pairs(GAME_HO_TRO) do
        if containsId(config.PlaceId, placeId) or containsId(config.UniverseId, universeId) then
            return config.Name
        end
    end

    if universeId and universeId > 0 then
        local ok, response = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(universeId))
        end)
        if ok and type(response) == "string" then
            local decodeOK, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            if decodeOK and type(data) == "table" and type(data.data) == "table" then
                local info = data.data[1]
                if info and type(info.name) == "string" and info.name ~= "" then
                    local upperName = string.upper(info.name)
                    if not upperName:find("TITLE UNAVAILABLE", 1, true) then
                        return info.name
                    end
                end
            end
        end
    end

    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(placeId, Enum.InfoType.Asset)
    end)
    if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
        return info.Name
    end

    return "Place ID " .. tostring(placeId or "Unknown")
end

local function resolveGame()
    State.PlaceId = tonumber(game.PlaceId)
    if not State.PlaceId or State.PlaceId <= 0 then
        return false, "Không lấy được PlaceId."
    end

    setStatus("PlaceId: " .. tostring(State.PlaceId) .. " • Đang nhận diện...", COLORS.Info)
    task.wait(0.15)

    State.UniverseId = getUniverseId(State.PlaceId) or tonumber(game.GameId)
    local config, matchType, configKey = findGameConfig(State.PlaceId, State.UniverseId)

    if not config then
        State.GameSupported = false
        State.GameConfig = nil
        State.MainUI = nil
        updateDetectedGame(State.RobloxGameName or ("Place ID " .. tostring(State.PlaceId)), "Universal mode", game.GameId or State.PlaceId)
        return false, "Game không được hỗ trợ."
    end

    local mainUI = config.MainUI or config.mainUI or config.URL or config.url
    if type(mainUI) ~= "string" or mainUI == "" then
        return false, "Game đã nhận diện nhưng chưa có MainUI."
    end

    State.GameName = tostring(config.Name or config.name or configKey or "Unknown Game")
    State.GameConfig = config
    State.MainUI = mainUI
    State.GameSupported = true

    local iconId = (type(config.UniverseId) == "table" and config.UniverseId[1]) or game.GameId or State.PlaceId
    updateDetectedGame(State.RobloxGameName or State.GameName, "Supported game", iconId)
    setStatus("Đã nhận diện: " .. State.GameName .. " (" .. tostring(matchType) .. ")", COLORS.Success)
    return true
end

--============================================================
-- GAME DATA WAIT AND REMOTE SCRIPT LOADER
--============================================================

local function waitForGameData(config)
    if type(config) ~= "table" or config.WaitForDataLoaded ~= true then
        return true
    end

    setStatus("Đang chờ dữ liệu game...", COLORS.Info)
    local dataLoaded = player:FindFirstChild("DataLoaded")
    if not dataLoaded then
        local ok, result = pcall(function()
            return player:WaitForChild("DataLoaded", 30)
        end)
        if not ok or not result then
            return false
        end
        dataLoaded = result
    end

    if dataLoaded:IsA("BoolValue") then
        local timeoutAt = os.clock() + 30
        while not dataLoaded.Value and os.clock() < timeoutAt do
            task.wait(0.2)
        end
        return dataLoaded.Value
    end
    return true
end

local function executeScript(url, scriptName)
    scriptName = tostring(scriptName or "Script")
    if type(url) ~= "string" or url == "" or not url:match("^https://") then
        error(scriptName .. ": URL không hợp lệ.")
    end

    local requestOK, code = pcall(function()
        return game:HttpGet(url)
    end)
    if not requestOK then
        error(scriptName .. ": Lỗi tải dữ liệu: " .. tostring(code))
    end
    if type(code) ~= "string" or code:match("^%s*$") then
        error(scriptName .. ": Nội dung tải về rỗng.")
    end

    local prefix = string.lower(code:sub(1, 512))
    if prefix:match("^%s*<!doctype") or prefix:match("^%s*<html") then
        error(scriptName .. ": Máy chủ trả về HTML thay vì mã Luau.")
    end
    if type(loadstring) ~= "function" then
        error(scriptName .. ": Môi trường hiện tại không hỗ trợ loadstring.")
    end

    local compileCallOK, chunk, compileError = pcall(loadstring, code)
    if not compileCallOK then
        error(scriptName .. ": Lỗi biên dịch: " .. tostring(chunk))
    end
    if type(chunk) ~= "function" then
        error(scriptName .. ": Mã Luau không hợp lệ: " .. tostring(compileError))
    end

    local runOK, runError = pcall(chunk)
    if not runOK then
        error(scriptName .. ": Lỗi khi chạy: " .. tostring(runError))
    end
    return true
end

local function loadMainUI()
    if State.Loading then
        return
    end

    State.Loading = true
    keyFrame.Visible = true
    setStatus("KEY hợp lệ • Đang nhận diện game...", COLORS.Success)

    local success, fatalError = pcall(function()
        task.wait(0.2)
        local resolved, resolveError = resolveGame()

        if not resolved then
            if resolveError ~= "Game không được hỗ trợ." then
                error(resolveError or "Không nhận diện được game.")
            end

            setStatus("Universal Mode • Đang tải...", COLORS.Warning)
            showNotification("Universal Mode", "Game chưa có script riêng. Đang khởi chạy Universal...", "warning")
            task.wait(0.25)
            executeScript(UNIVERSAL_SCRIPT, "Universal Script")
            setStatus("Universal đã được tải.", COLORS.Success)
            showNotification("Universal Mode", "Universal Script đã được tải thành công.", "success")
            task.wait(0.2)
            keyFrame.Visible = false
            return
        end

        task.wait(0.25)
        if not waitForGameData(State.GameConfig) then
            error("Game chưa sẵn sàng: DataLoaded chưa hoàn tất.")
        end

        setStatus("Đang tải MainUI...", COLORS.Info)
        showNotification("Loading UI", "Đang tải " .. State.GameName .. "...", "info")
        task.wait(0.15)
        executeScript(State.MainUI, "MainUI")
        setStatus("Đã tải " .. State.GameName, COLORS.Success)
        showNotification("LPT Hub", "Đã tải UI: " .. State.GameName, "success")
        task.wait(0.2)
        keyFrame.Visible = false
    end)

    if not success then
        keyFrame.Visible = true
        setStatus("Không thể tải script: " .. tostring(fatalError), COLORS.Danger)
        showNotification("Load Error", tostring(fatalError), "error")
    end

    State.Loading = false
end

--============================================================
-- KEY VERIFICATION
--============================================================

local function checkKey(key)
    if type(key) ~= "string" or key == "" then
        return false, "Vui lòng nhập KEY."
    end

    local requestOK, response = pcall(function()
        return game:HttpGet(
            KEY_API_URL .. "?type=lpthub&key=" .. HttpService:UrlEncode(key)
        )
    end)
    if not requestOK or type(response) ~= "string" then
        return false, "Không kết nối được máy chủ xác thực."
    end

    local decodeOK, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not decodeOK or type(data) ~= "table" then
        return false, "Phản hồi xác thực không hợp lệ."
    end
    if data.valid ~= true then
        return false, "KEY không đúng hoặc không còn hợp lệ."
    end
    return true
end

--============================================================
-- BUTTON ACTIONS
--============================================================

getKeyButton.MouseButton1Click:Connect(function()
    local ok = copyToClipboard(GET_KEY_LINK)
    getKeyButton.Text = ok and "Link Copied!" or "Copy Failed"
    if not ok then
        showNotification("Clipboard Error", "Executor không hỗ trợ sao chép clipboard.", "error")
    end
    task.delay(1.2, function()
        if getKeyButton and getKeyButton.Parent then
            getKeyButton.Text = "Get a key"
        end
    end)
end)

local function copyButtonLink(button, link, stroke)
    local ok = copyToClipboard(link)
    stroke.Color = ok and COLORS.Success or COLORS.Danger
    stroke.Thickness = 2
    if not ok then
        showNotification("Clipboard Error", "Không thể sao chép link trong môi trường hiện tại.", "error")
    end

    task.delay(1.2, function()
        if button and button.Parent and stroke and stroke.Parent then
            stroke.Color = Color3.fromRGB(40, 40, 40)
            stroke.Thickness = 1
        end
    end)
end

discordButton.MouseButton1Click:Connect(function()
    copyButtonLink(discordButton, DISCORD_LINK, discordStroke)
end)
websiteButton.MouseButton1Click:Connect(function()
    copyButtonLink(websiteButton, WEBSITE_LINK, websiteStroke)
end)

local function attemptSubmit()
    if State.Submitting or State.Loading then
        return
    end

    State.Submitting = true
    local key = tostring(keyInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        setStatus("Vui lòng nhập KEY.", COLORS.Danger)
        State.Submitting = false
        return
    end

    setStatus("Đang xác thực KEY...", COLORS.Info)
    task.wait(0.1)

    local keyIsValid, verifyError = checkKey(key)
    if not keyIsValid then
        setStatus(verifyError or "Xác thực KEY thất bại.", COLORS.Danger)
        showNotification("Key Verification Failed", verifyError or "Xác thực KEY thất bại.", "error")
        tween(inputStroke, {Color = COLORS.Danger, Transparency = 0}, 0.1)
        task.wait(0.15)
        tween(inputStroke, {Color = COLORS.Border, Transparency = 0.15}, 0.2)
        State.Submitting = false
        return
    end

    State.KeyValid = true
    local saved = saveKey(key)
    if not saved then
        showNotification("Key Valid", "KEY hợp lệ nhưng không thể lưu vào file trên môi trường này.", "warning")
    else
        showNotification("Key Valid", "KEY hợp lệ. Đang nhận diện game...", "success")
    end
    setStatus("KEY hợp lệ! Đang nhận diện game...", COLORS.Success)
    State.Submitting = false
    loadMainUI()
end

submitButton.MouseButton1Click:Connect(attemptSubmit)
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        attemptSubmit()
    end
end)

--============================================================
-- INITIAL GAME INFO AND AUTO-VERIFY SAVED KEY
--============================================================

task.spawn(function()
    local initialConfig = nil
    for _, config in pairs(GAME_HO_TRO) do
        if containsId(config.PlaceId, game.PlaceId)
            or containsId(config.UniverseId, game.GameId) then
            initialConfig = config
            break
        end
    end

    State.GameSupported = initialConfig ~= nil
    if initialConfig then
        updateDetectedGame("Detecting game...", "Supported game", initialConfig.UniverseId and initialConfig.UniverseId[1] or game.GameId or game.PlaceId)
    else
        updateDetectedGame("Detecting game...", "Universal mode", game.GameId or game.PlaceId)
    end

    local actualName = fetchRobloxGameName()
    State.RobloxGameName = actualName
    if detectedGameName and detectedGameName.Parent then
        detectedGameName.Text = actualName
    end
end)

task.spawn(function()
    local savedKey = getSavedKey()
    if type(savedKey) ~= "string" or savedKey == "" then
        return
    end

    task.wait(0.4)
    if not keyInput or not keyInput.Parent then
        return
    end
    keyInput.Text = savedKey
    setStatus("Đang xác thực KEY đã lưu...", COLORS.Info)
    task.wait(0.2)
    attemptSubmit()
end)
