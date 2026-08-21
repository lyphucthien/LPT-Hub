local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- STATE
--========================================================

local State = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 90,

    WalkSpeedEnabled = false,
    JumpPowerEnabled = false,

    NoClip = false,
    Fly = false,

    AutoFarm = false,
    AutoHarvest = false,
    AutoBuySeed = false,
    AutoPlant = false,
    AutoRebirth = false,
    AutoCollect = false,
    AutoRoute = false,

    RouteTarget = nil,
    HarvestTarget = nil,
}

local Connections = {}
local OriginalCollision = {}
local FlyConnection = nil

--========================================================
-- SETTINGS
--========================================================

local SETTINGS_FILE = "LPT_Hub_Settings.json"

local function loadSettings()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return
    end

    local ok, exists = pcall(function()
        return isfile(SETTINGS_FILE)
    end)

    if not ok or not exists then
        return
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)

    if not success or type(data) ~= "table" then
        return
    end

    for key, value in pairs(data) do
        if State[key] ~= nil and typeof(State[key]) == typeof(value) then
            State[key] = value
        end
    end

    -- Không tự bật Fly khi load lại
    State.Fly = false
end

local function saveSettings()
    if type(writefile) ~= "function"
        or type(readfile) ~= "function"
        or type(isfile) ~= "function" then
        return
    end

    local data = {}

    local ok, exists = pcall(function()
        return isfile(SETTINGS_FILE)
    end)

    if ok and exists then
        local readOK, current = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end)

        if readOK and type(current) == "table" then
            data = current
        end
    end

    for key, value in pairs(State) do
        if key ~= "RouteTarget"
            and key ~= "HarvestTarget"
            and key ~= "Fly"
            and (
                type(value) == "boolean"
                or type(value) == "number"
                or type(value) == "string"
            ) then
            data[key] = value
        end
    end

    data.Fly = false

    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
    end)
end

loadSettings()

--========================================================
-- COLORS
--========================================================

local COLORS = {
    Background = Color3.fromRGB(10, 11, 16),
    Surface = Color3.fromRGB(14, 15, 21),
    SurfaceLight = Color3.fromRGB(40, 44, 58),
    Card = Color3.fromRGB(34, 38, 50),
    CardHover = Color3.fromRGB(40, 44, 58),

    Accent = Color3.fromRGB(168, 105, 245),
    AccentB = Color3.fromRGB(236, 72, 153),

    Text = Color3.fromRGB(240, 241, 245),
    TextDim = Color3.fromRGB(150, 157, 170),
    Border = Color3.fromRGB(52, 56, 70),

    Success = Color3.fromRGB(74, 222, 128),
    Danger = Color3.fromRGB(255, 92, 108),
    Info = Color3.fromRGB(96, 165, 250),
    Warning = Color3.fromRGB(250, 180, 70),
}

local SIDEBAR_ACCENT = Color3.fromRGB(96, 165, 250)

--========================================================
-- HELPERS
--========================================================

local function tween(obj, props, time, style)
    if not obj or not obj.Parent then
        return
    end

    local tweenInfo = TweenInfo.new(
        time or 0.18,
        style or Enum.EasingStyle.Quad
    )

    local tweenObject = TweenService:Create(obj, tweenInfo, props)
    tweenObject:Play()

    return tweenObject
end

local function applyGradient(obj, colorA, colorB, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colorA, colorB)
    gradient.Rotation = rotation or 45
    gradient.Parent = obj

    return gradient
end

local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

--========================================================
-- MOVEMENT
--========================================================

local function applyMovement()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    pcall(function()
        humanoid.UseJumpPower = true
        humanoid.WalkSpeed = State.WalkSpeedEnabled and State.WalkSpeed or 16
        humanoid.JumpPower = State.JumpPowerEnabled and State.JumpPower or 50
    end)
end

Connections.Movement = RunService.Heartbeat:Connect(function()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    if State.WalkSpeedEnabled and humanoid.WalkSpeed ~= State.WalkSpeed then
        pcall(function()
            humanoid.WalkSpeed = State.WalkSpeed
        end)
    end

    if State.JumpPowerEnabled and humanoid.JumpPower ~= State.JumpPower then
        pcall(function()
            humanoid.JumpPower = State.JumpPower
        end)
    end
end)

--========================================================
-- NO CLIP
--========================================================

local function rememberCollision(character)
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") and OriginalCollision[object] == nil then
            OriginalCollision[object] = object.CanCollide
        end
    end
end

local function restoreCollision()
    for object, value in pairs(OriginalCollision) do
        if object and object.Parent then
            pcall(function()
                object.CanCollide = value
            end)
        end
    end

    table.clear(OriginalCollision)
end

Connections.NoClip = RunService.Stepped:Connect(function()
    if not State.NoClip then
        return
    end

    local character = getCharacter()

    if not character then
        return
    end

    rememberCollision(character)

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            pcall(function()
                object.CanCollide = false
            end)
        end
    end
end)

--========================================================
-- FLY
--========================================================

local function stopFly()
    State.Fly = false

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    local humanoid = getHumanoid()
    local root = getRoot()

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function startFly()
    stopFly()

    State.Fly = true

    local lockedPosition

    FlyConnection = RunService.Heartbeat:Connect(function()
        if not State.Fly then
            return
        end

        local root = getRoot()
        local humanoid = getHumanoid()
        local camera = workspace.CurrentCamera

        if not root or not humanoid or not camera then
            return
        end

        humanoid.PlatformStand = true
        humanoid.AutoRotate = false

        if not lockedPosition then
            lockedPosition = root.Position
        end

        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += look
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= look
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += right
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= right
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
            root.AssemblyLinearVelocity = direction * State.FlySpeed
            root.AssemblyAngularVelocity = Vector3.zero
            lockedPosition = root.Position
        else
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(lockedPosition) * root.CFrame.Rotation
        end
    end)
end

--========================================================
-- FARM OBJECT DETECTION
--========================================================

local function hasAttribute(object, name)
    return name ~= "" and object:GetAttribute(name) ~= nil
end

local function isPlant(object)
    if not object then
        return false
    end

    local name = lower(object.Name)

    return name:find("plant", 1, true)
        or name:find("crop", 1, true)
        or name:find("tree", 1, true)
        or name:find("seedling", 1, true)
        or hasAttribute(object, "Plant")
        or hasAttribute(object, "Crop")
end

local function getObjectPosition(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object.Position
    end

    if object:IsA("Model") then
        local root = object.PrimaryPart or object:FindFirstChild("HumanoidRootPart")
        return root and root.Position
    end

    return nil
end

local function isReadyPlant(object)
    for _, attribute in ipairs({
        "Ready",
        "Harvestable",
        "CanHarvest",
        "Mature",
        "FullyGrown",
    }) do
        if object:GetAttribute(attribute) == true then
            return true
        end
    end

    for _, attribute in ipairs({
        "Growth",
        "GrowPercent",
        "Maturity",
        "Progress",
    }) do
        local value = tonumber(object:GetAttribute(attribute))

        if value and value >= 100 then
            return true
        end
    end

    return false
end

local function isLightningDanger(object)
    if not object then
        return false
    end

    for _, keyword in ipairs({
        "lightning",
        "thunder",
        "storm",
        "strike",
        "warning",
        "danger",
    }) do
        if lower(object.Name):find(keyword, 1, true) then
            return true
        end
    end

    for _, attribute in ipairs({
        "Lightning",
        "LightningWarning",
        "Thunder",
        "Storm",
        "BeingStruck",
        "StrikeIncoming",
        "LightningIncoming",
    }) do
        local value = object:GetAttribute(attribute)

        if value == true
            or lower(value) == "true"
            or lower(value) == "warning"
            or (type(value) == "number" and value <= 1) then
            return true
        end
    end

    return false
end

local function harvestScore(object)
    if not object or not object.Parent or not isPlant(object) then
        return -math.huge
    end

    local score = 0

    if isLightningDanger(object) then
        score += 1000000
    end

    if isReadyPlant(object) then
        score += 100000
    end

    for _, attribute in ipairs({
        "Growth",
        "GrowPercent",
        "Maturity",
        "Progress",
    }) do
        local value = tonumber(object:GetAttribute(attribute))

        if value then
            score += math.floor(value * 100)
        end
    end

    return score
end

local function findBestPlant()
    local best
    local bestScore = -math.huge

    for _, object in ipairs(workspace:GetDescendants()) do
        if isPlant(object) then
            local score = harvestScore(object)

            if score > bestScore then
                bestScore = score
                best = object
            end
        end
    end

    return best
end

local function findNearestPlant()
    local root = getRoot()

    if not root then
        return nil
    end

    local best
    local bestDistance = math.huge

    for _, object in ipairs(workspace:GetDescendants()) do
        if isPlant(object) then
            local position = getObjectPosition(object)

            if position then
                local distance = (position - root.Position).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    best = object
                end
            end
        end
    end

    return best
end

local function routeToObject(object)
    local root = getRoot()
    local position = getObjectPosition(object)

    if not root or not position then
        return false
    end

    State.RouteTarget = object

    if State.Fly then
        local direction = position - root.Position

        if direction.Magnitude > 2 then
            root.CFrame = CFrame.lookAt(root.Position, position)
        end
    else
        local humanoid = getHumanoid()

        if humanoid then
            humanoid:MoveTo(position)
        end
    end

    return true
end

--========================================================
-- GAME HOOKS
--========================================================

local function tryAction(name, target)
    local hooks = workspace:FindFirstChild("LPT_Hooks")

    if not hooks then
        return false
    end

    local event = hooks:FindFirstChild(name)

    if event and event:IsA("BindableEvent") then
        event:Fire(target)
        return true
    end

    local func = hooks:FindFirstChild(name)

    if func and func:IsA("BindableFunction") then
        pcall(function()
            func:Invoke(target)
        end)

        return true
    end

    return false
end

--========================================================
-- FARM ACTIONS
--========================================================

local lastHarvestTarget = nil
local lastHarvestTime = 0

local function autoHarvestStep()
    local plant = findBestPlant()

    if not plant then
        return
    end

    State.HarvestTarget = plant

    if State.AutoRoute then
        routeToObject(plant)
    end

    local danger = isLightningDanger(plant)
    local ready = isReadyPlant(plant)

    if (danger or ready)
        and (
            plant ~= lastHarvestTarget
            or os.clock() - lastHarvestTime >= 0.2
        ) then

        if tryAction("Harvest", plant) then
            lastHarvestTarget = plant
            lastHarvestTime = os.clock()
        end
    end
end

local function autoFarmStep()
    if State.AutoHarvest then
        autoHarvestStep()
    end

    if State.AutoBuySeed then
        tryAction("BuySeed")
    end

    if State.AutoPlant then
        tryAction("Plant")
    end

    if State.AutoCollect then
        tryAction("Collect")
    end

    if State.AutoRebirth then
        tryAction("Rebirth")
    end

    if State.AutoRoute and State.RouteTarget and State.RouteTarget.Parent then
        routeToObject(State.RouteTarget)
    end

    if State.AutoRoute and not State.RouteTarget then
        local target = findNearestPlant()

        if target then
            routeToObject(target)
        end
    end
end

--========================================================
-- GUI
--========================================================

local oldGui = playerGui:FindFirstChild("LPTHub")

if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LPTHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2147483647

local hiddenLayer = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())

if hiddenLayer then
    screenGui.Parent = hiddenLayer
else
    local ok = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)

    if not ok then
        screenGui.Parent = playerGui
    end
end

if protect_gui then
    pcall(function()
        protect_gui(screenGui)
    end)
elseif syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(screenGui)
    end)
end

--========================================================
-- MAIN WINDOW
--========================================================

local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 780, 0, 500)
main.Position = UDim2.new(0.5, -390, 0.5, -250)
main.BackgroundColor3 = COLORS.Background
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Border
mainStroke.Thickness = 2
mainStroke.Transparency = 0.1
mainStroke.Parent = main

applyGradient(mainStroke, COLORS.Accent, COLORS.AccentB, 45)

--========================================================
-- TOP BAR
--========================================================

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = COLORS.Surface
topBar.BorderSizePixel = 0
topBar.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 20)
topCorner.Parent = topBar

local topMask = Instance.new("Frame")
topMask.Size = UDim2.new(1, 0, 0, 20)
topMask.Position = UDim2.new(0, 0, 1, -20)
topMask.BackgroundColor3 = COLORS.Surface
topMask.BorderSizePixel = 0
topMask.Parent = topBar

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(8, 8)
dot.Position = UDim2.new(0, 20, 0.5, -4)
dot.BackgroundColor3 = COLORS.Success
dot.BorderSizePixel = 0
dot.Parent = topBar

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(105, 38)
title.Position = UDim2.fromOffset(36, 0)
title.BackgroundTransparency = 1
title.Text = "LPT Hub"
title.TextColor3 = COLORS.Text
title.TextSize = 18.5
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

applyGradient(title, COLORS.Accent, COLORS.AccentB, 0)

local author = Instance.new("TextLabel")
author.Size = UDim2.fromOffset(180, 38)
author.Position = UDim2.fromOffset(113, 0)
author.BackgroundTransparency = 1
author.Text = "Greedy Growers"
author.TextColor3 = COLORS.TextDim
author.TextSize = 11
author.Font = Enum.Font.Gotham
author.TextXAlignment = Enum.TextXAlignment.Left
author.Parent = topBar

local close = Instance.new("TextButton")
close.Name = "CloseButton"
close.Size = UDim2.fromOffset(30, 26)
close.Position = UDim2.new(1, -40, 0.5, -13)
close.BackgroundColor3 = COLORS.SurfaceLight
close.BackgroundTransparency = 1
close.BorderSizePixel = 0
close.Text = "×"
close.TextSize = 17
close.TextColor3 = COLORS.TextDim
close.Font = Enum.Font.GothamMedium
close.AutoButtonColor = false
close.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = close

close.MouseEnter:Connect(function()
    tween(close, {
        BackgroundTransparency = 0,
        BackgroundColor3 = COLORS.Danger,
        TextColor3 = Color3.new(1, 1, 1),
    })
end)

close.MouseLeave:Connect(function()
    tween(close, {
        BackgroundTransparency = 1,
        TextColor3 = COLORS.TextDim,
    })
end)

--========================================================
-- SIDEBAR / CONTENT
--========================================================

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 220, 1, -38)
sidebar.Position = UDim2.fromOffset(0, 38)
sidebar.BackgroundColor3 = COLORS.Surface
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 20)
sidebarCorner.Parent = sidebar

local sidebarMask = Instance.new("Frame")
sidebarMask.Size = UDim2.new(1, 0, 0, 20)
sidebarMask.BackgroundColor3 = COLORS.Surface
sidebarMask.BorderSizePixel = 0
sidebarMask.Parent = sidebar

local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = COLORS.Border
sideLine.BorderSizePixel = 0
sideLine.Parent = sidebar

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -220, 1, -38)
content.Position = UDim2.fromOffset(220, 38)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.Accent
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = content

    pages[name] = page

    return page
end

local mainPage = createPage("Main")
local farmPage = createPage("Farm")
local settingsPage = createPage("Settings")

--========================================================
-- PAGE TITLE
--========================================================

local function pageTitle(page, text, sub)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 38)
    label.Position = UDim2.fromOffset(28, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextSize = 28
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page

    if sub then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -50, 0, 20)
        desc.Position = UDim2.fromOffset(28, 54)
        desc.BackgroundTransparency = 1
        desc.Text = sub
        desc.TextColor3 = COLORS.TextDim
        desc.TextSize = 14
        desc.Font = Enum.Font.Gotham
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = page
    end
end

pageTitle(mainPage, "Main", "Điều khiển nhân vật.")
pageTitle(farmPage, "Farm", "Automation và harvest.")
pageTitle(settingsPage, "Settings", "Điều chỉnh và tự động lưu thiết lập.")

--========================================================
-- UI HELPERS
--========================================================

local function createToggle(parent, text, y, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -56, 0, 56)
    row.Position = UDim2.fromOffset(28, y)
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
    label.Position = UDim2.fromOffset(18, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.Size = UDim2.fromOffset(50, 26)
    button.Position = UDim2.new(1, -68, 0.5, -13)
    button.BackgroundColor3 = Color3.fromRGB(120, 120, 125)
    button.BackgroundTransparency = 0.35
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = row

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(22, 22)
    knob.Position = UDim2.fromOffset(3, 2)
    knob.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
    knob.BorderSizePixel = 0
    knob.Parent = button

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local enabled = false

    local function setEnabled(value, fire)
        enabled = value == true

        tween(button, {
            BackgroundColor3 = enabled and COLORS.Success or Color3.fromRGB(120, 120, 125),
            BackgroundTransparency = enabled and 0 or 0.35,
        }, 0.2)

        tween(knob, {
            Position = enabled and UDim2.new(1, -25, 0, 2) or UDim2.fromOffset(3, 2),
            BackgroundColor3 = enabled and Color3.fromRGB(15, 20, 18) or Color3.fromRGB(230, 230, 235),
        }, 0.2)

        if fire ~= false and callback then
            callback(enabled)
        end
    end

    button.MouseButton1Click:Connect(function()
        setEnabled(not enabled, true)
    end)

    row.MouseEnter:Connect(function()
        if not enabled then
            tween(row, {BackgroundColor3 = COLORS.CardHover}, 0.15)
        end
    end)

    row.MouseLeave:Connect(function()
        if not enabled then
            tween(row, {BackgroundColor3 = COLORS.Card}, 0.15)
        end
    end)

    return setEnabled, function()
        return enabled
    end
end

local function createSlider(parent, text, y, defaultValue, minValue, maxValue, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -56, 0, 78)
    row.Position = UDim2.fromOffset(28, y)
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
    label.Size = UDim2.new(1, -80, 0, 20)
    label.Position = UDim2.fromOffset(18, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(50, 20)
    valueLabel.Position = UDim2.new(1, -68, 0, 10)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = COLORS.Accent
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -36, 0, 6)
    track.Position = UDim2.fromOffset(18, 50)
    track.BackgroundColor3 = COLORS.SurfaceLight
    track.BorderSizePixel = 0
    track.Active = true
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = COLORS.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Active = true
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = COLORS.Accent
    knobStroke.Thickness = 2
    knobStroke.Parent = knob

    local dragging = false

    local function setValue(value, fire)
        value = math.clamp(math.floor(value + 0.5), minValue, maxValue)

        local progress = (value - minValue) / (maxValue - minValue)

        fill.Size = UDim2.new(progress, 0, 1, 0)
        knob.Position = UDim2.new(progress, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        if fire ~= false and callback then
            callback(value)
        end

        return value
    end

    local function update(input)
        local x = input.Position.X - track.AbsolutePosition.X
        local progress = math.clamp(x / track.AbsoluteSize.X, 0, 1)

        setValue(
            minValue + progress * (maxValue - minValue),
            true
        )
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    setValue(defaultValue, false)

    return setValue
end

--========================================================
-- MAIN
--========================================================

local setWalkUI = createToggle(
    mainPage,
    "WalkSpeed",
    95,
    function(value)
        State.WalkSpeedEnabled = value
        applyMovement()
        saveSettings()
    end
)

local setJumpUI = createToggle(
    mainPage,
    "JumpPower",
    161,
    function(value)
        State.JumpPowerEnabled = value
        applyMovement()
        saveSettings()
    end
)

local setFlyUI = createToggle(
    mainPage,
    "Fly",
    227,
    function(value)
        if value then
            startFly()
        else
            stopFly()
        end
    end
)

local setNoClipUI = createToggle(
    mainPage,
    "No Clip",
    293,
    function(value)
        State.NoClip = value

        if value then
            rememberCollision(getCharacter())
        else
            restoreCollision()
        end

        saveSettings()
    end
)

mainPage.CanvasSize = UDim2.new(0, 0, 0, 365)

--========================================================
-- FARM
--========================================================

local farmSetters = {}

farmSetters.AutoFarm = createToggle(
    farmPage,
    "Auto Farm",
    95,
    function(value)
        State.AutoFarm = value
        saveSettings()
    end
)

farmSetters.AutoHarvest = createToggle(
    farmPage,
    "Auto Harvest",
    161,
    function(value)
        State.AutoHarvest = value
        saveSettings()
    end
)

farmSetters.AutoBuySeed = createToggle(
    farmPage,
    "Auto Buy Seed",
    227,
    function(value)
        State.AutoBuySeed = value
        saveSettings()
    end
)

farmSetters.AutoPlant = createToggle(
    farmPage,
    "Auto Plant",
    293,
    function(value)
        State.AutoPlant = value
        saveSettings()
    end
)

farmSetters.AutoRebirth = createToggle(
    farmPage,
    "Auto Rebirth",
    359,
    function(value)
        State.AutoRebirth = value
        saveSettings()
    end
)

farmSetters.AutoCollect = createToggle(
    farmPage,
    "Auto Collect",
    425,
    function(value)
        State.AutoCollect = value
        saveSettings()
    end
)

farmSetters.AutoRoute = createToggle(
    farmPage,
    "Auto Route",
    491,
    function(value)
        State.AutoRoute = value
        saveSettings()
    end
)

local harvestStatus = Instance.new("TextLabel")
harvestStatus.Size = UDim2.new(1, -56, 0, 42)
harvestStatus.Position = UDim2.fromOffset(28, 557)
harvestStatus.BackgroundTransparency = 1
harvestStatus.Text = "Harvest: cây sắp bị sét đánh > cây chín > cây đang lớn"
harvestStatus.TextColor3 = COLORS.Warning
harvestStatus.TextSize = 12
harvestStatus.Font = Enum.Font.GothamMedium
harvestStatus.TextXAlignment = Enum.TextXAlignment.Left
harvestStatus.Parent = farmPage

farmPage.CanvasSize = UDim2.new(0, 0, 0, 615)

--========================================================
-- SETTINGS
--========================================================

createSlider(
    settingsPage,
    "Walk Speed",
    95,
    State.WalkSpeed,
    1,
    500,
    function(value)
        State.WalkSpeed = value

        if State.WalkSpeedEnabled then
            applyMovement()
        end

        saveSettings()
    end
)

createSlider(
    settingsPage,
    "Jump Power",
    183,
    State.JumpPower,
    1,
    500,
    function(value)
        State.JumpPower = value

        if State.JumpPowerEnabled then
            applyMovement()
        end

        saveSettings()
    end
)

createSlider(
    settingsPage,
    "Fly Speed",
    271,
    State.FlySpeed,
    1,
    500,
    function(value)
        State.FlySpeed = value
        saveSettings()
    end
)

local fixLag = Instance.new("TextButton")
fixLag.Name = "FixLag"
fixLag.Size = UDim2.new(1, -56, 0, 52)
fixLag.Position = UDim2.fromOffset(28, 363)
fixLag.BackgroundColor3 = COLORS.Info
fixLag.BorderSizePixel = 0
fixLag.Text = "FIX LAG"
fixLag.TextColor3 = Color3.new(1, 1, 1)
fixLag.TextSize = 14
fixLag.Font = Enum.Font.GothamBold
fixLag.AutoButtonColor = false
fixLag.Parent = settingsPage

local fixCorner = Instance.new("UICorner")
fixCorner.CornerRadius = UDim.new(0, 14)
fixCorner.Parent = fixLag

fixLag.MouseEnter:Connect(function()
    tween(fixLag, {
        BackgroundColor3 = Color3.fromRGB(120, 185, 255),
    }, 0.15)
end)

fixLag.MouseLeave:Connect(function()
    tween(fixLag, {
        BackgroundColor3 = COLORS.Info,
    }, 0.15)
end)

fixLag.MouseButton1Click:Connect(function()
    fixLag.Text = "FIXING..."

    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")

        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end
    end)

    pcall(function()
        local lighting = game:GetService("Lighting")

        for _, object in ipairs(lighting:GetChildren()) do
            if object:IsA("PostEffect") then
                object.Enabled = false
            end
        end

        lighting.GlobalShadows = false
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
    end)

    pcall(function()
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("BasePart") then
                pcall(function()
                    object.Material = Enum.Material.SmoothPlastic
                    object.Reflectance = 0
                end)
            elseif object:IsA("Decal") or object:IsA("Texture") then
                pcall(function()
                    object.Transparency = 1
                end)
            elseif object:IsA("SpecialMesh") then
                pcall(function()
                    object.TextureId = ""
                end)
            elseif object:IsA("ParticleEmitter")
                or object:IsA("Trail")
                or object:IsA("Beam")
                or object:IsA("Smoke")
                or object:IsA("Fire")
                or object:IsA("Sparkles") then

                pcall(function()
                    object.Enabled = false
                end)
            elseif object:IsA("SurfaceAppearance") then
                pcall(function()
                    object:Destroy()
                end)
            end
        end
    end)

    task.wait(0.35)

    fixLag.Text = "FIXED ✓"

    task.wait(1)

    if fixLag.Parent then
        fixLag.Text = "FIX LAG"
    end
end)

settingsPage.CanvasSize = UDim2.new(0, 0, 0, 445)

--========================================================
-- SIDEBAR
--========================================================

local currentPage = nil
local sidebarButtons = {}
local sidebarIndicator = nil

local function selectPage(name)
    if not pages[name] then
        return
    end

    if currentPage == name then
        return
    end

    local data = sidebarButtons[name]

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for pageName, buttonData in pairs(sidebarButtons) do
        local active = pageName == name

        tween(buttonData.button, {
            BackgroundTransparency = active and 0.12 or 1,
        }, 0.16)

        tween(buttonData.label, {
            TextColor3 = active and COLORS.Text or COLORS.TextDim,
        }, 0.16)
    end

    if data then
        local targetY = data.button.Position.Y.Offset + (data.button.Size.Y.Offset / 2) - 14

        if sidebarIndicator then
            tween(
                sidebarIndicator,
                {Position = UDim2.new(0, 12, 0, targetY)},
                0.28,
                Enum.EasingStyle.Quint
            )
        else
            sidebarIndicator = Instance.new("Frame")
            sidebarIndicator.Name = "ActiveIndicator"
            sidebarIndicator.Size = UDim2.fromOffset(4, 28)
            sidebarIndicator.Position = UDim2.new(0, 12, 0, targetY)
            sidebarIndicator.BackgroundColor3 = SIDEBAR_ACCENT
            sidebarIndicator.BorderSizePixel = 0

            local indicatorCorner = Instance.new("UICorner")
            indicatorCorner.CornerRadius = UDim.new(1, 0)
            indicatorCorner.Parent = sidebarIndicator

            sidebarIndicator.Parent = sidebar
        end
    end

    currentPage = name
end

local function createSidebarButton(text, order, name)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, -24, 0, 48)
    button.Position = UDim2.fromOffset(12, 16 + (order - 1) * 54)
    button.BackgroundColor3 = COLORS.SurfaceLight
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.fromOffset(18, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.TextDim
    label.TextSize = 16
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    sidebarButtons[name] = {
        button = button,
        label = label,
    }

    button.MouseEnter:Connect(function()
        if currentPage ~= name then
            tween(button, {
                BackgroundTransparency = 0.72,
            }, 0.15)

            tween(label, {
                TextColor3 = COLORS.Text,
            }, 0.15)
        end
    end)

    button.MouseLeave:Connect(function()
        if currentPage ~= name then
            tween(button, {
                BackgroundTransparency = 1,
            }, 0.15)

            tween(label, {
                TextColor3 = COLORS.TextDim,
            }, 0.15)
        end
    end)

    button.MouseButton1Click:Connect(function()
        selectPage(name)
    end)
end

createSidebarButton("Main", 1, "Main")
createSidebarButton("Farm", 2, "Farm")
createSidebarButton("Settings", 3, "Settings")

selectPage("Main")

--========================================================
-- RESTORE SAVED UI STATE
--========================================================

task.defer(function()
    applyMovement()

    setWalkUI(State.WalkSpeedEnabled, false)
    setJumpUI(State.JumpPowerEnabled, false)
    setNoClipUI(State.NoClip, false)

    if State.NoClip then
        rememberCollision(getCharacter())
    end

    for key, setter in pairs(farmSetters) do
        setter(State[key] == true, false)
    end

    applyMovement()
end)

--========================================================
-- FARM ENGINE
--========================================================

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.15)

        if State.AutoFarm then
            autoFarmStep()
        elseif State.AutoHarvest then
            autoHarvestStep()
        elseif State.AutoRoute and State.RouteTarget then
            routeToObject(State.RouteTarget)
        end
    end
end)

--========================================================
-- CHARACTER
--========================================================

Connections.CharacterAdded = player.CharacterAdded:Connect(function(character)
    table.clear(OriginalCollision)

    if State.Fly then
        stopFly()
    end

    local humanoid = character:WaitForChild("Humanoid", 10)

    if humanoid then
        task.wait(0.15)
        applyMovement()

        if State.NoClip then
            rememberCollision(character)
        end
    end
end)

--========================================================
-- MAXIMIZE / MINIMIZE / DRAG
--========================================================

local maximized = false
local minimized = false

local savedBeforeMinimizeSize = nil
local savedBeforeMinimizePosition = nil

local normalSize = UDim2.new(0, 780, 0, 500)
local normalPosition = UDim2.new(0.5, -390, 0.5, -250)

local maximizedSize = UDim2.new(1, -40, 1, -40)
local maximizedPosition = UDim2.new(0, 20, 0, 20)

local minimizedSize = UDim2.new(0, 300, 0, 38)
local minimizedPosition = UDim2.new(0.5, -150, -0.060, 15)

local minimizedHover = false

local minimize = Instance.new("TextButton")
minimize.Name = "MinimizeButton"
minimize.Size = UDim2.fromOffset(30, 26)
minimize.Position = UDim2.new(1, -110, 0.5, -13)
minimize.BackgroundColor3 = COLORS.SurfaceLight
minimize.BackgroundTransparency = 1
minimize.BorderSizePixel = 0
minimize.Text = "—"
minimize.TextColor3 = COLORS.TextDim
minimize.TextSize = 13
minimize.Font = Enum.Font.GothamMedium
minimize.AutoButtonColor = false
minimize.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 10)
minCorner.Parent = minimize

local maximize = Instance.new("TextButton")
maximize.Name = "MaximizeButton"
maximize.Size = UDim2.fromOffset(30, 26)
maximize.Position = UDim2.new(1, -76, 0.5, -13)
maximize.BackgroundColor3 = COLORS.SurfaceLight
maximize.BackgroundTransparency = 1
maximize.BorderSizePixel = 0
maximize.Text = "□"
maximize.TextColor3 = COLORS.TextDim
maximize.TextSize = 14
maximize.Font = Enum.Font.GothamMedium
maximize.AutoButtonColor = false
maximize.Parent = topBar

local maxCorner = Instance.new("UICorner")
maxCorner.CornerRadius = UDim.new(0, 10)
maxCorner.Parent = maximize

local function topHover(button, hoverColor, hoverBg)
    button.MouseEnter:Connect(function()
        tween(button, {
            TextColor3 = hoverColor,
            BackgroundTransparency = 0,
            BackgroundColor3 = hoverBg or COLORS.SurfaceLight,
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, {
            TextColor3 = COLORS.TextDim,
            BackgroundTransparency = 1,
        })
    end)
end

topHover(minimize, COLORS.Text)
topHover(maximize, COLORS.Text)

local function updateMinimizedButtons()
    if not minimized then
        minimize.Visible = true
        maximize.Visible = true
        close.Visible = true

        minimize.Active = true
        maximize.Active = true
        close.Active = true

        minimize.BackgroundTransparency = 1
        maximize.BackgroundTransparency = 1
        close.BackgroundTransparency = 1

        return
    end

    minimize.Visible = false
    maximize.Visible = false
    close.Visible = true

    close.Active = minimizedHover
    close.BackgroundTransparency = minimizedHover and 0 or 1
    close.TextTransparency = minimizedHover and 0 or 1
end

local function restoreFromMinimized()
    if not minimized then
        return
    end

    minimized = false
    minimizedHover = false

    sidebar.Visible = true
    content.Visible = true
    author.Visible = true

    updateMinimizedButtons()

    local restoreSize = savedBeforeMinimizeSize or (maximized and maximizedSize or normalSize)
    local restorePosition = savedBeforeMinimizePosition or (maximized and maximizedPosition or normalPosition)

    tween(
        main,
        {
            Size = restoreSize,
            Position = restorePosition,
        },
        0.28,
        Enum.EasingStyle.Quint
    )
end

maximize.MouseButton1Click:Connect(function()
    if minimized then
        restoreFromMinimized()
        task.wait(0.28)
    end

    maximized = not maximized

    if maximized then
        tween(
            main,
            {
                Size = maximizedSize,
                Position = maximizedPosition,
            },
            0.25,
            Enum.EasingStyle.Quint
        )
    else
        tween(
            main,
            {
                Size = normalSize,
                Position = normalPosition,
            },
            0.25,
            Enum.EasingStyle.Quint
        )
    end

    updateMinimizedButtons()
end)

minimize.MouseButton1Click:Connect(function()
    if minimized then
        restoreFromMinimized()
        return
    end

    savedBeforeMinimizeSize = main.Size
    savedBeforeMinimizePosition = main.Position

    minimized = true
    minimizedHover = false

    sidebar.Visible = false
    content.Visible = false
    author.Visible = false

    updateMinimizedButtons()

    tween(
        main,
        {
            Size = minimizedSize,
            Position = minimizedPosition,
        },
        0.28,
        Enum.EasingStyle.Quint
    )
end)

topBar.MouseEnter:Connect(function()
    if minimized then
        minimizedHover = true
        updateMinimizedButtons()
    end
end)

topBar.MouseLeave:Connect(function()
    if minimized then
        minimizedHover = false
        updateMinimizedButtons()
    end
end)

local dragging = false
local dragStart = nil
local startPosition = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if minimized then
        return
    end

    dragging = true
    dragStart = input.Position
    startPosition = main.Position
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or minimized then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

--========================================================
-- CLOSE
--========================================================

close.MouseButton1Click:Connect(function()
    saveSettings()
    stopFly()

    State.NoClip = false
    restoreCollision()

    for name, connection in pairs(Connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        Connections[name] = nil
    end

    if screenGui.Parent then
        screenGui:Destroy()
    end
end)

applyMovement()