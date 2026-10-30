local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("LPT Hub: LocalPlayer is unavailable.")
    return
end

local playerGui = player:WaitForChild("PlayerGui")

local GET_KEY_LINK = "https://work.ink/34tV/lpt-hub-script-key-mission"
local DISCORD_LINK = "https://discord.gg/gyZ27Hw9qu"
local YOUTUBE_LINK = "https://youtube.com/@lyphucthien1803"
local KEY_API_URL = "https://lyphucthien.vercel.app/api/get-key"
local RAW_LINK = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/main/"

local UNIVERSAL_SCRIPT = RAW_LINK .. "Script%20Supports%20All%20Games.lua"

local GAME_HO_TRO = {
    ["+1 Speed Keyboard Escape"] = {
        Name = "+1 Speed Keyboard Escape",
        PlaceId = {95082159892680},
        UniverseId = {9584852943},
        WaitForDataLoaded = false,
        MainUI = RAW_LINK .. "%2B1%20Speed%20Keyboard%20Escape/Main.lua",
    },

    ["Blox Fruits"] = {
        Name = "Blox Fruits",
        PlaceId = {85211729168715},
        UniverseId = {994732206},
        WaitForDataLoaded = false,
        MainUI = RAW_LINK .. "Blox%20Fruits/Main.lua",
    },
}

local LPT_HUB_FOLDER = "LPT Hub"
local KEY_FILE = LPT_HUB_FOLDER .. "/LPT_Hub_Key.json"
local KEY_DURATION = 3 * 60 * 60
local USE_EDITABLE_IMAGE = true

--============================================================
-- HALLOWEEN THEME
--============================================================

local COLORS = {
    Background = Color3.fromRGB(12, 8, 18),
    Surface = Color3.fromRGB(26, 18, 34),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(160, 145, 175),
    Border = Color3.fromRGB(70, 45, 90),
    Danger = Color3.fromRGB(255, 92, 108),
    Success = Color3.fromRGB(132, 255, 90),
    Info = Color3.fromRGB(190, 140, 255),
    Warning = Color3.fromRGB(250, 204, 21),
    Pumpkin = Color3.fromRGB(255, 130, 30),
    PumpkinLight = Color3.fromRGB(255, 170, 70),
    Purple = Color3.fromRGB(150, 80, 230),
    PurpleLight = Color3.fromRGB(190, 140, 255),
    Moon = Color3.fromRGB(255, 236, 190),
}

local State = {
    Key = nil,
    GameKey = nil,
    ExpiresAt = nil,
    Watching = false,
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

local function makeShape(parent, size, position, color, radius, zIndex)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position or UDim2.fromOffset(0, 0)
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.ZIndex = zIndex or 13
    frame.Parent = parent
    if radius then
        makeCorner(frame, radius)
    end
    return frame
end

local function buildKeyIcon(parent, color)
    local holder = Instance.new("Frame")
    holder.Name = "KeyGlyph"
    holder.Size = UDim2.fromOffset(18, 18)
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.BackgroundTransparency = 1
    holder.Rotation = -45
    holder.ZIndex = 13
    holder.Parent = parent

    local ring = makeShape(holder, UDim2.fromOffset(6, 6), UDim2.fromOffset(2, 6), color, 99)
    ring.BackgroundTransparency = 1
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = color
    ringStroke.Thickness = 2
    ringStroke.Parent = ring

    makeShape(holder, UDim2.fromOffset(8, 2), UDim2.fromOffset(10, 8), color, 1)
    makeShape(holder, UDim2.fromOffset(2, 3), UDim2.fromOffset(13, 10), color, 1)
    makeShape(holder, UDim2.fromOffset(2, 3), UDim2.fromOffset(16, 10), color, 1)
end

--============================================================
-- FILE / CLIPBOARD / HTTP
--============================================================

local function ensureLPTFolder()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return
    end

    local ok, exists = pcall(isfolder, LPT_HUB_FOLDER)
    if ok and not exists then
        pcall(makefolder, LPT_HUB_FOLDER)
    end
end

local function copyToClipboard(text)
    if type(setclipboard) ~= "function" then
        return false
    end
    local ok = pcall(setclipboard, text)
    return ok
end

local function httpGet(url, retries)
    local lastErr
    for i = 1, (retries or 3) do
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and type(res) == "string" and res ~= "" then
            return res
        end
        lastErr = res
        task.wait(0.5 * i)
    end
    return nil, tostring(lastErr)
end

local function getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)

    if not ok or type(id) ~= "string" or id == "" then
        return nil
    end

    return id
end

local DISCORD_RGB = {88 / 255, 101 / 255, 242 / 255}

local function bezier(p, steps, out)
    for i = 1, steps do
        local t = i / steps
        local u = 1 - t
        local x, y
        if #p == 3 then
            x = u * u * p[1][1] + 2 * u * t * p[2][1] + t * t * p[3][1]
            y = u * u * p[1][2] + 2 * u * t * p[2][2] + t * t * p[3][2]
        else
            x = u ^ 3 * p[1][1] + 3 * u * u * t * p[2][1] + 3 * u * t * t * p[3][1] + t ^ 3 * p[4][1]
            y = u ^ 3 * p[1][2] + 3 * u * u * t * p[2][2] + 3 * u * t * t * p[3][2] + t ^ 3 * p[4][2]
        end
        out[#out + 1] = {x, y}
    end
end

local DISCORD_POLY = {{433, 328}}
do
    local right = {{560, 303}, {661, 334}}
    bezier({{661, 334}, {712, 410}, {742, 500}, {733, 613}}, 20, right)
    bezier({{733, 613}, {685, 652}, {609, 677}}, 8, right)
    right[#right + 1] = {583, 634}
    right[#right + 1] = {623, 614}
    right[#right + 1] = {615, 606}

    bezier({{433, 328}, {490, 322}, {546, 328}}, 12, DISCORD_POLY)
    for _, p in ipairs(right) do
        DISCORD_POLY[#DISCORD_POLY + 1] = p
    end
    bezier({{615, 606}, {490, 662}, {365, 606}}, 20, DISCORD_POLY)
    for i = #right - 1, 1, -1 do
        DISCORD_POLY[#DISCORD_POLY + 1] = {980 - right[i][1], right[i][2]}
    end
    for _, p in ipairs(DISCORD_POLY) do
        p[1] = (p[1] - 245) / 490
        p[2] = (p[2] - 303) / 374
    end
end

local DISCORD_EYES = {{0.3327, 0.5481, 0.0898, 0.1337},{0.6653, 0.5481, 0.0898, 0.1337},}

local function discordIntervals(y)
    local xs = {}
    local n = #DISCORD_POLY
    for i = 1, n do
        local a = DISCORD_POLY[i]
        local b = DISCORD_POLY[i % n + 1]
        if (a[2] <= y) ~= (b[2] <= y) then
            xs[#xs + 1] = a[1] + (y - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
        end
    end
    table.sort(xs)

    local intervals = {}
    for i = 1, #xs - 1, 2 do
        intervals[#intervals + 1] = {xs[i], xs[i + 1]}
    end

    for _, eye in ipairs(DISCORD_EYES) do
        local cx, cy, rx, ry = eye[1], eye[2], eye[3], eye[4]
        local d = 1 - ((y - cy) / ry) ^ 2
        if d > 0 then
            local half = rx * math.sqrt(d)
            local out = {}
            for _, seg in ipairs(intervals) do
                local a, b = seg[1], seg[2]
                if b <= cx - half or a >= cx + half then
                    out[#out + 1] = seg
                else
                    if a < cx - half then
                        out[#out + 1] = {a, cx - half}
                    end
                    if b > cx + half then
                        out[#out + 1] = {cx + half, b}
                    end
                end
            end
            intervals = out
        end
    end
    return intervals
end

local function renderDiscordPixels(w, h)
    local SUB = 4
    local px = table.create(w * h * 4, 0)
    local cov = table.create(w, 0)

    for row = 0, h - 1 do
        for x = 1, w do
            cov[x] = 0
        end
        for s = 0, SUB - 1 do
            local y = (row + (s + 0.5) / SUB) / h
            for _, seg in ipairs(discordIntervals(y)) do
                local a, b = seg[1] * w, seg[2] * w
                local x1 = math.max(1, math.floor(a) + 1)
                local x2 = math.min(w, math.ceil(b))
                for x = x1, x2 do
                    local overlap = math.min(b, x) - math.max(a, x - 1)
                    if overlap > 0 then
                        cov[x] = cov[x] + overlap
                    end
                end
            end
        end
        for x = 1, w do
            local i = (row * w + (x - 1)) * 4
            px[i + 1] = DISCORD_RGB[1]
            px[i + 2] = DISCORD_RGB[2]
            px[i + 3] = DISCORD_RGB[3]
            px[i + 4] = math.clamp(cov[x] / SUB, 0, 1)
        end
    end
    return px
end

local YT_TRI = {{0.409, 0.278}, {0.409, 0.722}, {0.683, 0.5}}
local YT_RADIUS = 0.29

local function pointInTriangle(px, py, a, b, c)
    local function sign(p1x, p1y, p2x, p2y, p3x, p3y)
        return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y)
    end
    local d1 = sign(px, py, a[1], a[2], b[1], b[2])
    local d2 = sign(px, py, b[1], b[2], c[1], c[2])
    local d3 = sign(px, py, c[1], c[2], a[1], a[2])
    local hasNeg = d1 < 0 or d2 < 0 or d3 < 0
    local hasPos = d1 > 0 or d2 > 0 or d3 > 0
    return not (hasNeg and hasPos)
end

local function renderYouTubePixels(w, h)
    local SUB = 4
    local r = h * YT_RADIUS
    local tri = {}
    for i, p in ipairs(YT_TRI) do
        tri[i] = {p[1] * w, p[2] * h}
    end

    local px = table.create(w * h * 4, 0)
    for row = 0, h - 1 do
        for col = 0, w - 1 do
            local rectCount, triCount = 0, 0
            for sy = 0, SUB - 1 do
                for sx = 0, SUB - 1 do
                    local x = col + (sx + 0.5) / SUB
                    local y = row + (sy + 0.5) / SUB
                    local dx = math.max(math.abs(x - w / 2) - (w / 2 - r), 0)
                    local dy = math.max(math.abs(y - h / 2) - (h / 2 - r), 0)
                    if dx * dx + dy * dy <= r * r then
                        rectCount = rectCount + 1
                        if pointInTriangle(x, y, tri[1], tri[2], tri[3]) then
                            triCount = triCount + 1
                        end
                    end
                end
            end
            local i = (row * w + col) * 4
            local t = rectCount > 0 and triCount / rectCount or 0
            px[i + 1] = 1
            px[i + 2] = t
            px[i + 3] = t
            px[i + 4] = rectCount / (SUB * SUB)
        end
    end
    return px
end

--============================================================
-- ICON BUILDERS
--============================================================

local DISCORD_BLUE = Color3.fromRGB(88, 101, 242)

local function buildDiscordFrames(holder)
    local rows = 28
    for r = 0, rows - 1 do
        local y = (r + 0.5) / rows
        for _, seg in ipairs(discordIntervals(y)) do
            local f = Instance.new("Frame")
            f.BackgroundColor3 = DISCORD_BLUE
            f.BorderSizePixel = 0
            f.Position = UDim2.fromScale(seg[1], r / rows)
            f.Size = UDim2.fromScale(seg[2] - seg[1], 1 / rows + 0.003)
            f.ZIndex = 13
            f.Parent = holder
        end
    end
end

local function buildYouTubeFrames(holder)
    local body = Instance.new("Frame")
    body.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    body.BorderSizePixel = 0
    body.Size = UDim2.fromScale(1, 1)
    body.ZIndex = 13
    body.Parent = holder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(YT_RADIUS, 0)
    corner.Parent = body

    local left, right = YT_TRI[1][1], YT_TRI[3][1]
    local top, bottom = YT_TRI[1][2], YT_TRI[2][2]
    local columns = 14
    local step = (right - left) / columns
    for i = 0, columns - 1 do
        local h = (bottom - top) * (1 - (i + 0.5) / columns)
        local strip = Instance.new("Frame")
        strip.BackgroundColor3 = Color3.new(1, 1, 1)
        strip.BorderSizePixel = 0
        strip.Position = UDim2.fromScale(left + i * step, 0.5 - h / 2)
        strip.Size = UDim2.fromScale(step + 0.004, h)
        strip.ZIndex = 14
        strip.Parent = holder
    end
end

local function makeEditableImage(w, h, pixels)
    local img
    local ok = pcall(function()
        img = game:GetService("AssetService"):CreateEditableImage({Size = Vector2.new(w, h)})
    end)
    if not ok or not img then
        ok = pcall(function()
            img = Instance.new("EditableImage")
            img.Size = Vector2.new(w, h)
        end)
        if not ok or not img then
            return nil
        end
    end

    local wrote = pcall(function()
        img:WritePixels(Vector2.new(0, 0), Vector2.new(w, h), pixels)
    end)
    if not wrote then
        wrote = pcall(function()
            local buf = buffer.create(w * h * 4)
            for i = 1, #pixels do
                buffer.writeu8(buf, i - 1, math.floor(pixels[i] * 255 + 0.5))
            end
            img:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(w, h), buf)
        end)
    end
    if not wrote then
        pcall(function() img:Destroy() end)
        return nil
    end
    return img
end

local function applyEditableImage(label, img)
    local ok = pcall(function()
        label.ImageContent = Content.fromObject(img)
    end)
    if not ok then
        ok = pcall(function()
            img.Parent = label
        end)
    end
    return ok
end

local function applyIcon(holder, texW, texH, buildFrames, renderPixels)
    buildFrames(holder)
    if not USE_EDITABLE_IMAGE then
        return
    end

    task.spawn(function()
        local okPixels, pixels = pcall(renderPixels, texW, texH)
        if not okPixels or type(pixels) ~= "table" then
            return
        end
        local img = makeEditableImage(texW, texH, pixels)
        if not img or not holder.Parent then
            return
        end

        local label = Instance.new("ImageLabel")
        label.Name = "SmoothIcon"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.ScaleType = Enum.ScaleType.Stretch
        label.ZIndex = 13
        label.Visible = false
        label.Parent = holder

        if applyEditableImage(label, img) then
            for _, child in ipairs(holder:GetChildren()) do
                if child ~= label then
                    child:Destroy()
                end
            end
            label.Visible = true
        else
            label:Destroy()
            pcall(function() img:Destroy() end)
        end
    end)
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

        if savedAt and savedAt > os.time() + 60 then
            if type(delfile) == "function" then
                pcall(delfile, KEY_FILE)
            end
            return nil
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

local function deleteSavedKey()
    if type(delfile) ~= "function" then
        warn("LPT Hub: Executor không hỗ trợ delfile.")
        return false
    end

    local ok = pcall(function()
        if type(isfile) ~= "function" or isfile(KEY_FILE) then
            delfile(KEY_FILE)
        end
    end)

    return ok
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

local function alive()
    return screenGui ~= nil and screenGui.Parent ~= nil
end

local expiredShown = false

local function showExpiredOverlay()
    if expiredShown or not screenGui or not screenGui.Parent then
        return
    end
    expiredShown = true

    local canClose = false

    local overlay = Instance.new("TextButton")
    overlay.Name = "ExpiredOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.Active = true
    overlay.ZIndex = 100
    overlay.Parent = screenGui
    tween(overlay, {BackgroundTransparency = 0.4}, 0.25)

    local title = makeLabel(overlay, "Title", "💀 Key Đã Hết Hạn 💀", UDim2.fromOffset(600, 50), UDim2.new(0.5, -300, 0.5, -40), Enum.Font.GothamBold, 36, COLORS.Pumpkin)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 101

    local countdown = makeLabel(overlay, "Countdown", "5s", UDim2.fromOffset(600, 30), UDim2.new(0.5, -300, 0.5, 20), Enum.Font.GothamMedium, 22, COLORS.Text)
    countdown.TextXAlignment = Enum.TextXAlignment.Center
    countdown.ZIndex = 101

    overlay.Activated:Connect(function()
        if canClose and overlay.Parent then
            overlay:Destroy()
        end
    end)

    task.spawn(function()
        for i = 5, 1, -1 do
            if not overlay.Parent then
                return
            end
            countdown.Text = tostring(i) .. "s"
            task.wait(1)
        end
        if overlay.Parent then
            canClose = true
            countdown.Text = "Nhấn để đóng"
            countdown.TextColor3 = COLORS.TextDim
        end
    end)
end

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyUI"
keyFrame.Size = UDim2.fromOffset(357, 310)
keyFrame.Position = UDim2.new(0.5, -178, 0.5, -155)
keyFrame.BackgroundColor3 = Color3.new(1, 1, 1)
keyFrame.BackgroundTransparency = 0.02
keyFrame.BorderSizePixel = 0
keyFrame.ClipsDescendants = true
keyFrame.ZIndex = 10
keyFrame.Parent = screenGui
makeCorner(keyFrame, 8)

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 18, 62)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(19, 10, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 5, 13)),
})
bgGradient.Rotation = 90
bgGradient.Parent = keyFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.new(1, 1, 1)
frameStroke.Thickness = 2
frameStroke.Transparency = 0
frameStroke.Parent = keyFrame

local frameStrokeGradient = Instance.new("UIGradient")
frameStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.Pumpkin),
    ColorSequenceKeypoint.new(0.5, COLORS.Purple),
    ColorSequenceKeypoint.new(1, COLORS.Pumpkin),
})
frameStrokeGradient.Rotation = 0
frameStrokeGradient.Parent = frameStroke

task.spawn(function()
    while alive() do
        frameStrokeGradient.Rotation = 0
        tween(frameStrokeGradient, {Rotation = 360}, 6, Enum.EasingStyle.Linear)
        task.wait(6)
    end
end)

local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 357, 1, 0)
leftPanel.BackgroundTransparency = 1
leftPanel.BorderSizePixel = 0
leftPanel.ZIndex = 10
leftPanel.Parent = keyFrame

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

local headerTitle = makeLabel(leftPanel, "HeaderTitle", "LPT Hub", UDim2.fromOffset(210, 28), UDim2.fromOffset(108, 23), Enum.Font.GothamBold, 24, Color3.fromRGB(255, 255, 255))

local headerTitleGradient = Instance.new("UIGradient")
headerTitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.Pumpkin),
    ColorSequenceKeypoint.new(0.5, COLORS.PurpleLight),
    ColorSequenceKeypoint.new(1, COLORS.Pumpkin),
})
headerTitleGradient.Offset = Vector2.new(-1, 0)
headerTitleGradient.Parent = headerTitle

task.spawn(function()
    while alive() do
        headerTitleGradient.Offset = Vector2.new(-1, 0)
        tween(headerTitleGradient, {Offset = Vector2.new(1, 0)}, 2.6, Enum.EasingStyle.Sine)
        task.wait(3.4)
    end
end)

makeLabel(leftPanel, "HeaderSubtitle", "Key system • Halloween 🎃", UDim2.fromOffset(160, 18), UDim2.fromOffset(109, 49), Enum.Font.Gotham, 12, Color3.fromRGB(185, 150, 140))

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

makeLabel(leftPanel, "LicenseLabel", "License key", UDim2.fromOffset(300, 20), UDim2.fromOffset(29, 88), Enum.Font.GothamMedium, 14, Color3.fromRGB(200, 180, 215))

local inputBox = Instance.new("Frame")
inputBox.Name = "KeyInputBox"
inputBox.Size = UDim2.fromOffset(300, 40)
inputBox.Position = UDim2.fromOffset(29, 112)
inputBox.BackgroundColor3 = COLORS.Surface
inputBox.BackgroundTransparency = 0.1
inputBox.BorderSizePixel = 0
inputBox.ZIndex = 11
inputBox.Parent = leftPanel
makeCorner(inputBox, 6)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = COLORS.Border
inputStroke.Thickness = 1
inputStroke.Transparency = 0.12
inputStroke.Parent = inputBox

local keyIcon = Instance.new("Frame")
keyIcon.Name = "KeyIcon"
keyIcon.Size = UDim2.fromOffset(18, 18)
keyIcon.Position = UDim2.new(0, 8, 0.5, -9)
keyIcon.BackgroundTransparency = 1
keyIcon.ZIndex = 12
keyIcon.Parent = inputBox

buildKeyIcon(keyIcon, COLORS.Pumpkin)

local keyInput = Instance.new("TextBox")
keyInput.Name = "LicenseInput"
keyInput.Size = UDim2.new(1, -44, 1, 0)
keyInput.Position = UDim2.fromOffset(31, 0)
keyInput.BackgroundTransparency = 1
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Paste your key here"
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 100, 135)
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(245, 245, 245)
keyInput.TextSize = 14
keyInput.Font = Enum.Font.GothamMedium
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.ClipsDescendants = true
keyInput.ZIndex = 12
keyInput.Parent = inputBox

keyInput.Focused:Connect(function()
    tween(inputStroke, {Color = COLORS.Pumpkin, Transparency = 0}, 0.15)
end)
keyInput.FocusLost:Connect(function()
    tween(inputStroke, {Color = COLORS.Border, Transparency = 0.12}, 0.15)
end)

local keyStatus = makeLabel(leftPanel, "KeyStatus", "", UDim2.fromOffset(300, 28), UDim2.fromOffset(29, 155), Enum.Font.GothamMedium, 12, COLORS.Danger)
keyStatus.TextWrapped = true
keyStatus.TextYAlignment = Enum.TextYAlignment.Top

local getKeyButton = Instance.new("TextButton")
getKeyButton.Name = "GetKeyButton"
getKeyButton.Size = UDim2.fromOffset(144, 40)
getKeyButton.Position = UDim2.fromOffset(29, 188)
getKeyButton.BackgroundColor3 = Color3.fromRGB(34, 22, 44)
getKeyButton.BorderSizePixel = 0
getKeyButton.Text = "Get a key"
getKeyButton.TextColor3 = Color3.fromRGB(200, 170, 225)
getKeyButton.TextSize = 13
getKeyButton.Font = Enum.Font.GothamMedium
getKeyButton.AutoButtonColor = false
getKeyButton.ZIndex = 11
getKeyButton.Parent = leftPanel
makeCorner(getKeyButton, 6)
local getStroke = Instance.new("UIStroke")
getStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
getStroke.Color = Color3.fromRGB(85, 55, 110)
getStroke.Thickness = 1
getStroke.Parent = getKeyButton

local submitButton = Instance.new("TextButton")
submitButton.Name = "SubmitButton"
submitButton.Size = UDim2.fromOffset(144, 40)
submitButton.Position = UDim2.fromOffset(185, 188)
submitButton.BackgroundColor3 = COLORS.Pumpkin
submitButton.TextColor3 = Color3.fromRGB(30, 10, 0)
submitButton.BorderSizePixel = 0
submitButton.Text = "Submit"
submitButton.TextSize = 13
submitButton.Font = Enum.Font.GothamBold
submitButton.AutoButtonColor = false
submitButton.ZIndex = 11
submitButton.Parent = leftPanel
makeCorner(submitButton, 6)

local function makeIconButton(name, posX, labelText, iconW, iconH)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(144, 40)
    button.Position = UDim2.fromOffset(posX, 238)
    button.BackgroundColor3 = COLORS.Surface
    button.BackgroundTransparency = 0.1
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 11
    button.Parent = leftPanel
    makeCorner(button, 6)

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(70, 48, 92)
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
    layout.Padding = UDim.new(0, 8)
    layout.Parent = row

    local holder = Instance.new("Frame")
    holder.Name = "Icon"
    holder.Size = UDim2.fromOffset(iconW, iconH)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = 1
    holder.ZIndex = 12
    holder.Parent = row

    local nameLabel = makeLabel(row, "Name", labelText, UDim2.fromOffset(0, 22), UDim2.fromOffset(0, 0), Enum.Font.GothamMedium, 12, Color3.fromRGB(235, 235, 235))
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.LayoutOrder = 2

    return button, stroke, holder
end

local function addHoverGlow(button, stroke, glowColor, hoverBg)
    local hovering = false

    local baseBackground = button.BackgroundColor3
    local baseStrokeColor = stroke.Color
    local baseThickness = stroke.Thickness
    local baseTransparency = stroke.Transparency
    hoverBg = hoverBg or Color3.fromRGB(44, 30, 58)

    local function showGlow()
        tween(button, {BackgroundColor3 = hoverBg}, 0.15)
        tween(stroke, {Color = glowColor, Thickness = 2, Transparency = 0}, 0.15)
    end

    local function hideGlow()
        tween(button, {BackgroundColor3 = baseBackground}, 0.15)
        tween(stroke, {Color = baseStrokeColor, Thickness = baseThickness, Transparency = baseTransparency}, 0.15)
    end

    button.MouseEnter:Connect(function()
        hovering = true
        showGlow()
    end)

    button.MouseLeave:Connect(function()
        hovering = false
        hideGlow()
    end)

    return function()
        if hovering then
            showGlow()
        else
            hideGlow()
        end
    end
end

local DISCORD_W, DISCORD_H = 29, 22
local YOUTUBE_W, YOUTUBE_H = 33, 22

local discordButton, discordStroke, discordHolder = makeIconButton("DiscordCard", 29, "Discord", DISCORD_W, DISCORD_H)
local youtubeButton, youtubeStroke, youtubeHolder = makeIconButton("YoutubeCard", 185, "YouTube", YOUTUBE_W, YOUTUBE_H)

applyIcon(discordHolder, DISCORD_W * 2, DISCORD_H * 2, buildDiscordFrames, renderDiscordPixels)
applyIcon(youtubeHolder, YOUTUBE_W * 2, YOUTUBE_H * 2, buildYouTubeFrames, renderYouTubePixels)

local restoreDiscordHover = addHoverGlow(discordButton, discordStroke, Color3.fromRGB(130, 145, 255))
local restoreYoutubeHover = addHoverGlow(youtubeButton, youtubeStroke, Color3.fromRGB(255, 60, 60))

addHoverGlow(getKeyButton, getStroke, COLORS.Purple, Color3.fromRGB(46, 30, 60))

getKeyButton.MouseEnter:Connect(function()
    tween(getKeyButton, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
end)
getKeyButton.MouseLeave:Connect(function()
    tween(getKeyButton, {TextColor3 = Color3.fromRGB(200, 170, 225)}, 0.15)
end)

local submitStroke = Instance.new("UIStroke")
submitStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
submitStroke.Color = COLORS.Pumpkin
submitStroke.Thickness = 1
submitStroke.Transparency = 1
submitStroke.Parent = submitButton
addHoverGlow(submitButton, submitStroke, Color3.fromRGB(255, 210, 120), COLORS.PumpkinLight)

local submitPulse = Instance.new("UIStroke")
submitPulse.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
submitPulse.Color = COLORS.PumpkinLight
submitPulse.Thickness = 3
submitPulse.Transparency = 0.85
submitPulse.Parent = submitButton

task.spawn(function()
    while alive() do
        tween(submitPulse, {Transparency = 0.45}, 1, Enum.EasingStyle.Sine)
        task.wait(1)
        tween(submitPulse, {Transparency = 0.85}, 1, Enum.EasingStyle.Sine)
        task.wait(1)
    end
end)

--============================================================
-- HALLOWEEN DECORATIONS
--============================================================

local rng = Random.new()

local decor = Instance.new("Frame")
decor.Name = "HalloweenDecor"
decor.Size = UDim2.fromScale(1, 1)
decor.BackgroundTransparency = 1
decor.BorderSizePixel = 0
decor.ZIndex = 9
decor.Parent = keyFrame

local function makeEmoji(name, emoji, size, position, textSize, transparency)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = emoji
    label.TextSize = textSize
    label.TextTransparency = transparency or 0
    label.Font = Enum.Font.Gotham
    label.ZIndex = 9
    label.Parent = decor
    return label
end

local fog = Instance.new("Frame")
fog.Name = "Fog"
fog.Size = UDim2.new(1, 0, 0, 80)
fog.Position = UDim2.new(0, 0, 1, -80)
fog.BackgroundColor3 = Color3.fromRGB(130, 70, 200)
fog.BorderSizePixel = 0
fog.ZIndex = 9
fog.Parent = decor

local fogGradient = Instance.new("UIGradient")
fogGradient.Rotation = 90
fogGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(1, 0.7),
})
fogGradient.Parent = fog

local moonGlow = makeShape(decor, UDim2.fromOffset(58, 58), UDim2.fromOffset(292, 0), COLORS.Moon, 99, 9)
moonGlow.Name = "MoonGlow"
moonGlow.BackgroundTransparency = 0.88

local moon = makeShape(decor, UDim2.fromOffset(32, 32), UDim2.fromOffset(305, 13), COLORS.Moon, 99, 9)
moon.Name = "Moon"

local moonGradient = Instance.new("UIGradient")
moonGradient.Color = ColorSequence.new(Color3.fromRGB(255, 248, 220), Color3.fromRGB(235, 205, 150))
moonGradient.Rotation = 45
moonGradient.Parent = moon

local craters = {
    {313, 21, 7}, {324, 30, 5}, {318, 36, 4},
}
for _, c in ipairs(craters) do
    local crater = makeShape(decor, UDim2.fromOffset(c[3], c[3]), UDim2.fromOffset(c[1], c[2]), Color3.fromRGB(220, 190, 135), 99, 9)
    crater.BackgroundTransparency = 0.45
end

task.spawn(function()
    while alive() do
        tween(moonGlow, {BackgroundTransparency = 0.78}, 2, Enum.EasingStyle.Sine)
        task.wait(2)
        tween(moonGlow, {BackgroundTransparency = 0.9}, 2, Enum.EasingStyle.Sine)
        task.wait(2)
    end
end)

local spiderLine = Instance.new("Frame")
spiderLine.Name = "SpiderThread"
spiderLine.Size = UDim2.fromOffset(1, 22)
spiderLine.Position = UDim2.fromOffset(283, 0)
spiderLine.BackgroundColor3 = Color3.fromRGB(210, 210, 225)
spiderLine.BackgroundTransparency = 0.45
spiderLine.BorderSizePixel = 0
spiderLine.ZIndex = 9
spiderLine.Parent = decor

local spider = makeEmoji("Spider", "🕷️", UDim2.fromOffset(22, 22), UDim2.fromOffset(272, 20), 18, 0)

task.spawn(function()
    while alive() do
        tween(spiderLine, {Size = UDim2.fromOffset(1, 44)}, 1.6, Enum.EasingStyle.Sine)
        tween(spider, {Position = UDim2.fromOffset(272, 42)}, 1.6, Enum.EasingStyle.Sine)
        task.wait(1.7)
        tween(spiderLine, {Size = UDim2.fromOffset(1, 22)}, 1.6, Enum.EasingStyle.Sine)
        tween(spider, {Position = UDim2.fromOffset(272, 20)}, 1.6, Enum.EasingStyle.Sine)
        task.wait(1.7)
    end
end)

local emberColors = {COLORS.Pumpkin, COLORS.PumpkinLight, COLORS.Purple, COLORS.PurpleLight}

local function spawnEmber(startDelay)
    local size = rng:NextInteger(2, 4)
    local ember = makeShape(decor, UDim2.fromOffset(size, size), UDim2.fromOffset(0, 320), emberColors[rng:NextInteger(1, #emberColors)], 99, 9)
    ember.Name = "Ember"
    ember.BackgroundTransparency = 1

    task.spawn(function()
        task.wait(startDelay)
        while alive() do
            if not keyFrame.Visible then
                task.wait(1)
            else
                local duration = rng:NextNumber(5, 9)
                local startX = rng:NextInteger(6, 350)
                local endX = math.clamp(startX + rng:NextInteger(-40, 40), 0, 354)

                ember.BackgroundTransparency = 1
                ember.Position = UDim2.fromOffset(startX, 318)
                tween(ember, {Position = UDim2.fromOffset(endX, -10)}, duration, Enum.EasingStyle.Linear)
                tween(ember, {BackgroundTransparency = 0.15}, duration * 0.3, Enum.EasingStyle.Sine)
                task.wait(duration * 0.6)
                tween(ember, {BackgroundTransparency = 1}, duration * 0.4, Enum.EasingStyle.Sine)
                task.wait(duration * 0.4)
            end
        end
    end)
end

for i = 1, 16 do
    spawnEmber(rng:NextNumber(0, 7))
end

local function spawnBats(startDelay, yPos, duration, textSize)
    task.spawn(function()
        task.wait(startDelay)
        while alive() do
            if not keyFrame.Visible then
                task.wait(1)
            else
                local bat = makeEmoji("Bat", "🦇", UDim2.fromOffset(30, 30), UDim2.fromOffset(-34, yPos), textSize, 0.05)
                local endY = yPos + rng:NextInteger(-14, 14)
                tween(bat, {Position = UDim2.fromOffset(372, endY)}, duration, Enum.EasingStyle.Linear)
                task.wait(duration)
                bat:Destroy()
                task.wait(rng:NextInteger(2, 5))
            end
        end
    end)
end

spawnBats(1, 22, 7, 20)
spawnBats(4, 276, 9, 16)

local ghost = makeEmoji("Ghost", "👻", UDim2.fromOffset(26, 26), UDim2.fromOffset(311, 283), 20, 0.1)

task.spawn(function()
    while alive() do
        tween(ghost, {Position = UDim2.fromOffset(307, 276)}, 1.3, Enum.EasingStyle.Sine)
        task.wait(1.3)
        tween(ghost, {Position = UDim2.fromOffset(315, 283)}, 1.3, Enum.EasingStyle.Sine)
        task.wait(1.3)
    end
end)

local footer = makeLabel(leftPanel, "HalloweenFooter", "🎃  Happy Halloween  🎃", UDim2.fromOffset(270, 18), UDim2.fromOffset(29, 284), Enum.Font.GothamMedium, 11, COLORS.Pumpkin)
footer.TextXAlignment = Enum.TextXAlignment.Center

task.spawn(function()
    while alive() do
        tween(footer, {TextColor3 = COLORS.PumpkinLight}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
        tween(footer, {TextColor3 = COLORS.Pumpkin}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
    end
end)

--============================================================
-- STATUS AND GAME DETECTION
--============================================================

local function setStatus(message, color)
    keyStatus.Text = tostring(message or "")
    keyStatus.TextColor3 = color or COLORS.Text
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

local function resolveGame()
    State.PlaceId = tonumber(game.PlaceId)
    if not State.PlaceId or State.PlaceId <= 0 then
        return false, "Không lấy được PlaceId."
    end

    State.UniverseId = getUniverseId(State.PlaceId) or tonumber(game.GameId)
    local config, matchType, configKey = findGameConfig(State.PlaceId, State.UniverseId)

    if not config then
        State.GameSupported = false
        State.GameConfig = nil
        State.MainUI = nil
        State.GameKey = nil
        return false, "Game không được hỗ trợ."
    end

    local mainUI = config.MainUI or config.mainUI or config.URL or config.url
    if type(mainUI) ~= "string" or mainUI == "" then
        return false, "Game đã nhận diện nhưng chưa có MainUI."
    end

    State.GameName = tostring(config.Name or config.name or configKey or "Unknown Game")
    State.GameConfig = config
    State.MainUI = mainUI
    State.GameKey = configKey
    State.GameSupported = true

    return true
end

--============================================================
-- GAME DATA WAIT AND REMOTE SCRIPT LOADER
--============================================================

local function waitForGameData(config)
    if type(config) ~= "table" or config.WaitForDataLoaded ~= true then
        return true
    end
    
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

--============================================================
-- LOCAL SCRIPT LOADERS
--============================================================

local function executeScript(scriptUrl, scriptName)
    scriptName = tostring(scriptName or "LPT Hub")

    if not State.KeyValid or not State.Key then
        error(scriptName .. ": KEY chưa được xác thực.", 0)
    end

    if type(scriptUrl) ~= "string"
        or scriptUrl:sub(1, #RAW_LINK) ~= RAW_LINK then
        error(scriptName .. ": URL raw không hợp lệ.", 0)
    end

    local code, err = httpGet(scriptUrl, 3)

    if not code then
        error(scriptName .. ": Không tải được script: " .. tostring(err),0)
    end

    local trimmed = code:gsub("^%s+", ""):gsub("%s+$", "")

    if trimmed == "" then
        error(scriptName .. ": File raw rỗng.", 0)
    end

    local prefix = string.lower(code:sub(1, 512))

    if prefix:match("^%s*<!doctype")
        or prefix:match("^%s*<html") then
        error(scriptName .. ": URL trả về HTML thay vì mã Luau.", 0)
    end

    if trimmed == "404: Not Found" then
        error(scriptName .. ": Không tìm thấy file trên GitHub.", 0)
    end

    if type(loadstring) ~= "function" then
        error(scriptName .. ": Môi trường không hỗ trợ loadstring.", 0)
    end

    local compileOK, chunk, compileError = pcall(loadstring, code)

    if not compileOK then
        error(scriptName .. ": Lỗi biên dịch: " .. tostring(chunk), 0)
    end

    if type(chunk) ~= "function" then
        error(scriptName .. ": Mã Luau không hợp lệ: " .. tostring(compileError),0)
    end

    local runOK, runError = pcall(chunk)

    if not runOK then
        error(scriptName .. ": Lỗi khi chạy: " .. tostring(runError), 0)
    end

    return true
end

local function startExpiryWatcher()
    if State.Watching then
        return
    end
    State.Watching = true

    task.spawn(function()
        while screenGui and screenGui.Parent do
            task.wait(1)
            if State.ExpiresAt and State.ExpiresAt - os.time() <= 0 then
                showExpiredOverlay()
                break
            end
        end
    end)
end

local function loadMainUI()
    if State.Loading then
        return
    end

    State.Loading = true
    keyFrame.Visible = true
    setStatus("Đang Tải Script...", COLORS.Info)

    local success, fatalError = pcall(function()
        local resolved, resolveError = resolveGame()

        if not resolved then
            if resolveError ~= "Game không được hỗ trợ." then
                error(resolveError or "Không nhận diện được game.", 0)
            end

            executeScript(UNIVERSAL_SCRIPT, "Universal Script")
            keyFrame.Visible = false
            return
        end

        if not waitForGameData(State.GameConfig) then
            error("Game chưa sẵn sàng: DataLoaded chưa hoàn tất.", 0)
        end

        executeScript(State.MainUI, "MainUI")
        keyFrame.Visible = false
    end)

    if not success then
        keyFrame.Visible = true
        setStatus("Không thể tải script: " .. tostring(fatalError), COLORS.Danger)
    end

    State.Loading = false
end

--============================================================
-- KEY VERIFICATION
--============================================================

local function checkKey(key)
    if type(key) ~= "string" or key == "" then
        return false, "Vui lòng nhập KEY", false
    end

    local hwid = getHWID()

    if not hwid then
        return false, "Không lấy được HWID của thiết bị", false
    end

    local url = KEY_API_URL .. "?type=lpthub" .. "&key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)

    local response, err = httpGet(url)

    if not response then
        return false, "Không đọc được phản hồi xác thực từ máy chủ", false
    end

    local decodeOK, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeOK or type(data) ~= "table" then
        return false, "Phản hồi xác thực không hợp lệ", false
    end

    if data.expired == true then
        return false, "Key Đã Hết Hạn", true
    end

    if data.valid ~= true then
        return false, tostring(data.error or "KEY Không Hợp Lệ"), false
    end

    local expiresAt = tonumber(data.expiresAt)

    if expiresAt then
        if expiresAt > 100000000000 then
            expiresAt = math.floor(expiresAt / 1000)
        end

        State.ExpiresAt = expiresAt

        if expiresAt <= os.time() then
            return false, "Key Đã Hết Hạn", true
        end
    else
        State.ExpiresAt = nil
    end

    return true, nil, false
end

--============================================================
-- BUTTON ACTIONS
--============================================================

getKeyButton.MouseButton1Click:Connect(function()
    local ok = copyToClipboard(GET_KEY_LINK)
    getKeyButton.Text = ok and "Link Copied!" or "Copy Failed"
    task.delay(1.2, function()
        if getKeyButton and getKeyButton.Parent then
            getKeyButton.Text = "Get a key"
        end
    end)
end)

local function copyButtonLink(button, link, stroke, restoreHover)
    local row = button:FindFirstChild("Row")
    local nameLabel = row and row:FindFirstChild("Name")

    if nameLabel and not button:GetAttribute("OrigText") then
        button:SetAttribute("OrigText", nameLabel.Text)
    end
    local origText = button:GetAttribute("OrigText")

    local ok = copyToClipboard(link)
    stroke.Color = ok and COLORS.Success or COLORS.Danger
    stroke.Thickness = 2

    if nameLabel then
        nameLabel.Text = ok and "Copied!" or "Failed"
    end

    task.delay(1.2, function()
        if button and button.Parent and stroke and stroke.Parent then
            if nameLabel and origText then
                nameLabel.Text = origText
            end

            if restoreHover then
                restoreHover()
            else
                stroke.Color = Color3.fromRGB(70, 48, 92)
                stroke.Thickness = 1
            end
        end
    end)
end

discordButton.MouseButton1Click:Connect(function()
    copyButtonLink(discordButton, DISCORD_LINK, discordStroke, restoreDiscordHover)
end)

youtubeButton.MouseButton1Click:Connect(function()
    copyButtonLink(youtubeButton, YOUTUBE_LINK, youtubeStroke, restoreYoutubeHover)
end)
    
local function attemptSubmit()
    if State.Submitting or State.Loading then
        return
    end

    State.Submitting = true
    local key = tostring(keyInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        setStatus("Vui Lòng Nhập Key", COLORS.Danger)
        State.Submitting = false
        return
    end

    local keyIsValid, keyError, keyExpired = checkKey(key)

    if not keyIsValid then
        if keyExpired then
            State.KeyValid = false
            State.Key = nil
            State.ExpiresAt = nil

            setStatus("Key Đã Hết Hạn", COLORS.Danger)
            showExpiredOverlay()
            deleteSavedKey()

            keyInput.Text = ""
        else
            setStatus(keyError or "KEY Không Hợp Lệ", COLORS.Danger)
        end

        tween(inputStroke, {Color = COLORS.Danger,Transparency = 0}, 0.1)
        task.wait(0.15)
        tween(inputStroke, {Color = COLORS.Border,Transparency = 0.15}, 0.2)

        State.Submitting = false
        return
    end

    State.KeyValid = true
    State.Key = key
    saveKey(key)
    setStatus("Key Hợp Lệ 🎃", COLORS.Success)
    State.Submitting = false
    task.wait(0.7)
    loadMainUI()
end

submitButton.MouseButton1Click:Connect(attemptSubmit)
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        attemptSubmit()
    end
end)

--============================================================
-- AUTO-VERIFY SAVED KEY
--============================================================

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
    setStatus("Đang Load KEY...", COLORS.Info)
    task.wait(0.7)
    attemptSubmit()
end)
