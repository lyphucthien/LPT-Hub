local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[LPT Stone Skipping] LocalPlayer is unavailable.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GUI_NAME = "LPTStoneSkippingHub"
local CONFIG_FOLDER = "LPT Hub"
local CONFIG_FILE = CONFIG_FOLDER .. "/StoneSkipping.json"

local RAW_BASE = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/%2B1%20Stone%20Skipping/ChucNang/"
local ModuleURLs = {
    Farm = RAW_BASE .. "Farm.lua",
    Stones = RAW_BASE .. "Stones.lua",
    Pets = RAW_BASE .. "Pets.lua",
    Progress = RAW_BASE .. "Progress.lua",
    Settings = RAW_BASE .. "Settings.lua",
}

local Defaults = {
    AutoTrain = false,
    AutoThrow = false,
    AutoRebirth = false,
    AutoHatch = false,
    PerformanceMode = false,
}
local Config = {}
for key, value in pairs(Defaults) do Config[key] = value end

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not ok or not exists then return end
    local readOk, raw = pcall(readfile, CONFIG_FILE)
    if not readOk or type(raw) ~= "string" or raw == "" then return end
    local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if decodeOk and type(decoded) == "table" then
        for key, default in pairs(Defaults) do
            if type(decoded[key]) == type(default) then Config[key] = decoded[key] end
        end
    end
end

local function saveConfig()
    if type(writefile) ~= "function" then return end
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, CONFIG_FOLDER)
        if ok and not exists then pcall(makefolder, CONFIG_FOLDER) end
    end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
end
loadConfig()

--============================================================
-- STYLE
--============================================================
local C = {
    Background = Color3.fromRGB(15, 17, 24),
    Surface = Color3.fromRGB(21, 24, 33),
    Surface2 = Color3.fromRGB(29, 33, 44),
    Border = Color3.fromRGB(49, 55, 71),
    Accent = Color3.fromRGB(76, 174, 255),
    Accent2 = Color3.fromRGB(143, 99, 255),
    Text = Color3.fromRGB(239, 243, 250),
    Muted = Color3.fromRGB(151, 161, 181),
    Good = Color3.fromRGB(87, 214, 153),
    Bad = Color3.fromRGB(255, 105, 122),
}

local function corner(instance, radius)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius or 8)
    ui.Parent = instance
    return ui
end

local function stroke(instance, color, transparency, thickness)
    local ui = Instance.new("UIStroke")
    ui.Color = color or C.Border
    ui.Transparency = transparency or 0
    ui.Thickness = thickness or 1
    ui.Parent = instance
    return ui
end

local function label(parent, text, size, position, textSize, color, font, align)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Size = size
    item.Position = position
    item.Font = font or Enum.Font.Gotham
    item.Text = text or ""
    item.TextColor3 = color or C.Text
    item.TextSize = textSize or 14
    item.TextXAlignment = align or Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.TextWrapped = true
    item.Parent = parent
    return item
end

local function makeButton(parent, text, height)
    local b = Instance.new("TextButton")
    b.Name = "ActionButton"
    b.Size = UDim2.new(1, 0, 0, height or 42)
    b.BackgroundColor3 = C.Surface2
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = text
    b.TextColor3 = C.Text
    b.TextSize = 13
    b.Font = Enum.Font.GothamSemibold
    b.Parent = parent
    corner(b, 8)
    stroke(b, C.Border, 0.2, 1)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(39, 47, 64)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = C.Surface2}):Play()
    end)
    return b
end

--============================================================
-- SCREEN GUI
--============================================================
local old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "MainWindow"
Main.Size = UDim2.fromOffset(780, 520)
Main.Position = UDim2.new(0.5, -390, 0.5, -260)
Main.BackgroundColor3 = C.Background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
corner(Main, 12)
stroke(Main, C.Border, 0.1, 1.4)

local Top = Instance.new("Frame")
Top.Name = "TopBar"
Top.Size = UDim2.new(1, 0, 0, 48)
Top.BackgroundColor3 = C.Surface
Top.BorderSizePixel = 0
Top.Parent = Main
label(Top, "LPT HUB", UDim2.fromOffset(100, 48), UDim2.fromOffset(18, 0), 18, C.Accent, Enum.Font.GothamBold)
label(Top, "+1 STONE SKIPPING", UDim2.fromOffset(230, 48), UDim2.fromOffset(112, 0), 12, C.Muted, Enum.Font.GothamSemibold)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(7, 7)
statusDot.Position = UDim2.new(1, -120, 0, 20)
statusDot.BackgroundColor3 = C.Good
statusDot.BorderSizePixel = 0
statusDot.Parent = Top
corner(statusDot, 10)
label(Top, "MODULE LOADER", UDim2.fromOffset(95, 22), UDim2.new(1, -108, 0, 13), 9, C.Muted, Enum.Font.GothamSemibold)

local Minimize = makeButton(Top, "—", 28)
Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(30, 28)
Minimize.Position = UDim2.new(1, -76, 0, 10)
Minimize.BackgroundColor3 = C.Surface2
Minimize.TextSize = 15
local Close = makeButton(Top, "×", 28)
Close.Name = "Close"
Close.Size = UDim2.fromOffset(30, 28)
Close.Position = UDim2.new(1, -39, 0, 10)
Close.BackgroundColor3 = C.Surface2
Close.TextSize = 18

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 176, 1, -48)
Sidebar.Position = UDim2.fromOffset(0, 48)
Sidebar.BackgroundColor3 = C.Surface
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

label(Sidebar, "GAME TOOLS", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 12), 10, C.Muted, Enum.Font.GothamBold)
local TabButtons = Instance.new("Frame")
TabButtons.BackgroundTransparency = 1
TabButtons.Size = UDim2.new(1, 0, 1, -50)
TabButtons.Position = UDim2.fromOffset(0, 43)
TabButtons.Parent = Sidebar
local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabButtons
local TabPad = Instance.new("UIPadding")
TabPad.PaddingLeft = UDim.new(0, 10)
TabPad.PaddingRight = UDim.new(0, 10)
TabPad.PaddingTop = UDim.new(0, 4)
TabPad.Parent = TabButtons

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -176, 1, -48)
Content.Position = UDim2.fromOffset(176, 48)
Content.BackgroundTransparency = 1
Content.Parent = Main

local StatusBar = Instance.new("TextLabel")
StatusBar.Name = "Status"
StatusBar.Size = UDim2.new(1, -24, 0, 24)
StatusBar.Position = UDim2.new(0, 12, 1, -29)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "Loading modules..."
StatusBar.TextColor3 = C.Muted
StatusBar.TextSize = 10
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = Content

local function setStatus(text, good)
    StatusBar.Text = tostring(text or "")
    StatusBar.TextColor3 = good == false and C.Bad or C.Muted
    statusDot.BackgroundColor3 = good == false and C.Bad or C.Good
end

local pages = {}
local tabInfo = {}
local currentTab = nil

local function createPage(name, heading, subtitle)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -24, 1, -50)
    page.Position = UDim2.fromOffset(12, 10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.Accent
    page.CanvasSize = UDim2.fromOffset(0, 620)
    page.Visible = false
    page.Parent = Content
    pages[name] = page

    label(page, heading, UDim2.new(1, -8, 0, 34), UDim2.fromOffset(4, 0), 23, C.Text, Enum.Font.GothamBold)
    label(page, subtitle, UDim2.new(1, -8, 0, 34), UDim2.fromOffset(4, 34), 11, C.Muted, Enum.Font.Gotham)
    return page
end

local function createSection(parent, titleText, top, height)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -8, 0, height)
    box.Position = UDim2.fromOffset(4, top)
    box.BackgroundColor3 = C.Surface
    box.BorderSizePixel = 0
    box.Parent = parent
    corner(box, 10)
    stroke(box, C.Border, 0.35, 1)
    label(box, titleText, UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 5), 13, C.Accent, Enum.Font.GothamBold)
    return box
end

local function createToggle(parent, titleText, description, defaultValue, callback, y)
    local row = Instance.new("Frame")
    row.Name = "Toggle_" .. titleText:gsub("%W", "")
    row.Size = UDim2.new(1, -24, 0, 52)
    row.Position = UDim2.fromOffset(12, y)
    row.BackgroundColor3 = C.Surface2
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 8)

    label(row, titleText, UDim2.new(1, -92, 0, 24), UDim2.fromOffset(11, 5), 12, C.Text, Enum.Font.GothamSemibold)
    label(row, description or "", UDim2.new(1, -92, 0, 18), UDim2.fromOffset(11, 28), 9, C.Muted, Enum.Font.Gotham)

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.fromOffset(48, 25)
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
    toggle.BackgroundColor3 = defaultValue and C.Accent or C.Border
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = row
    corner(toggle, 14)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(19, 19)
    knob.Position = defaultValue and UDim2.new(1, -22, 0.5, -9) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    corner(knob, 12)

    local enabled = defaultValue == true
    local function updateVisual()
        toggle.BackgroundColor3 = enabled and C.Accent or C.Border
        knob.Position = enabled and UDim2.new(1, -22, 0.5, -9) or UDim2.fromOffset(3, 3)
    end
    local function setEnabled(value, fire)
        enabled = value == true
        updateVisual()
        if fire ~= false and callback then callback(enabled) end
    end
    toggle.MouseButton1Click:Connect(function() setEnabled(not enabled, true) end)
    return setEnabled
end

local function createAction(parent, titleText, description, callback, y)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -24, 0, 48)
    row.Position = UDim2.fromOffset(12, y)
    row.BackgroundColor3 = C.Surface2
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 8)
    label(row, titleText, UDim2.new(1, -150, 0, 23), UDim2.fromOffset(11, 3), 12, C.Text, Enum.Font.GothamSemibold)
    label(row, description or "", UDim2.new(1, -150, 0, 17), UDim2.fromOffset(11, 25), 9, C.Muted, Enum.Font.Gotham)
    local action = makeButton(row, "Run", 30)
    action.Size = UDim2.fromOffset(106, 30)
    action.Position = UDim2.new(1, -118, 0.5, -15)
    action.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then setStatus("Action failed: " .. tostring(err), false) end
    end)
    return action
end

local function createStat(parent, titleText, y)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.5, -10, 0, 72)
    card.Position = UDim2.fromOffset(4 + (y % 2) * 0, 0)
    card.BackgroundColor3 = C.Surface
    card.BorderSizePixel = 0
    card.Parent = parent
    corner(card, 9)
    stroke(card, C.Border, 0.35, 1)
    label(card, titleText, UDim2.new(1, -18, 0, 24), UDim2.fromOffset(9, 7), 10, C.Muted, Enum.Font.GothamSemibold)
    local value = label(card, "—", UDim2.new(1, -18, 0, 28), UDim2.fromOffset(9, 32), 17, C.Text, Enum.Font.GothamBold)
    return value
end

--============================================================
-- MODULE LOADER AND PUBLIC API
--============================================================
local Modules = {}
local ModuleState = {}

local function isGuiVisible(guiObject)
    if not guiObject or not guiObject.Parent then return false end
    local current = guiObject
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local function normalize(text)
    return string.lower(tostring(text or "")):gsub("[%p%c]", " "):gsub("%s+", " ")
end

local function buttonText(button)
    local parts = {}
    if button:IsA("TextButton") then table.insert(parts, button.Text) end
    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            if child.Text and child.Text ~= "" then table.insert(parts, child.Text) end
        end
    end
    return table.concat(parts, " ")
end

local function contextText(button, levels)
    local parts = {buttonText(button)}
    local node = button.Parent
    local remaining = levels or 3
    while node and node ~= PlayerGui and remaining > 0 do
        if node:IsA("GuiObject") and node ~= ScreenGui then
            if node.Name and node.Name ~= "" then table.insert(parts, node.Name) end
            for _, child in ipairs(node:GetChildren()) do
                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                    table.insert(parts, child.Text)
                end
            end
        end
        node = node.Parent
        remaining -= 1
    end
    return normalize(table.concat(parts, " "))
end

local function matchesAny(haystack, aliases)
    for _, alias in ipairs(aliases or {}) do
        local needle = normalize(alias)
        if needle ~= "" and string.find(haystack, needle, 1, true) then return true end
    end
    return false
end

local function findButton(aliases, contextAliases)
    local candidates = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and isGuiVisible(obj) then
            local rootScreen = obj:FindFirstAncestorOfClass("ScreenGui")
            if rootScreen and rootScreen.Name ~= GUI_NAME then
                local direct = normalize(buttonText(obj))
                local context = contextText(obj, 4)
                local directMatch = matchesAny(direct, aliases)
                local contextMatch = matchesAny(context, aliases)
                local contextOk = not contextAliases or matchesAny(context, contextAliases)
                if contextOk and (directMatch or contextMatch) then
                    local score = directMatch and 100 or 35
                    for _, alias in ipairs(aliases or {}) do
                        local n = normalize(alias)
                        if n ~= "" and direct == n then score += 60 end
                        if n ~= "" and string.find(direct, n, 1, true) then score += 10 end
                    end
                    table.insert(candidates, {button = obj, score = score})
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1] and candidates[1].button or nil
end

local function clickButton(button)
    if not button or not button.Parent or not isGuiVisible(button) then return false end
    local center = button.AbsolutePosition + button.AbsoluteSize / 2
    local clicked = false

    -- Prefer real input so the game's normal UI callbacks are used.
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        task.wait(0.06)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
        clicked = true
    end)
    if clicked then return true end

    -- Executor-only signal fallbacks, used only on an already-visible UI button.
    if type(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(button.Activated)
            firesignal(button.MouseButton1Click)
        end)
        if ok then return true end
    end
    local ok = pcall(function() button:Activate() end)
    return ok
end

local function findTrainingPart()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local bestPart, bestScore = nil, -math.huge
    local workspaceService = game:GetService("Workspace")
    local keywords = {
        {"training", 80}, {"train", 65}, {"skill", 55},
        {"afk", 45}, {"practice", 40}, {"pool", 25},
    }
    for _, obj in ipairs(workspaceService:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Size.Magnitude >= 2 and obj.Size.Magnitude <= 120 then
            local names = {normalize(obj.Name)}
            local ancestor = obj.Parent
            for _ = 1, 4 do
                if not ancestor or ancestor == workspaceService then break end
                table.insert(names, normalize(ancestor.Name))
                ancestor = ancestor.Parent
            end
            local nameText = table.concat(names, " ")
            local keywordScore = 0
            for _, entry in ipairs(keywords) do
                if string.find(nameText, entry[1], 1, true) then
                    keywordScore = math.max(keywordScore, entry[2])
                end
            end
            if keywordScore > 0 then
                local distancePenalty = 0
                if root then distancePenalty = math.min((root.Position - obj.Position).Magnitude / 12, 55) end
                local score = keywordScore - distancePenalty + math.min(obj.Size.Magnitude / 15, 5)
                if score > bestScore then bestScore, bestPart = score, obj end
            end
        end
    end
    return bestPart
end

local API = {
    SetStatus = setStatus,
    FindButton = findButton,
    ClickButton = clickButton,
    GetButtonContext = function(button) return contextText(button, 4) end,
    FindTrainingPart = findTrainingPart,
    TextExists = function(aliases)
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and isGuiVisible(obj) then
                local rootScreen = obj:FindFirstAncestorOfClass("ScreenGui")
                if rootScreen and rootScreen.Name ~= GUI_NAME and matchesAny(normalize(obj.Text), aliases) then
                    return true, obj.Text
                end
            end
        end
        return false, nil
    end,
    Player = LocalPlayer,
    Workspace = game:GetService("Workspace"),
    GetStats = function()
        local wanted = {
            Skill = {"skill", "skills"},
            Wins = {"wins", "win"},
            Rebirths = {"rebirths", "rebirth"},
            Level = {"level", "levels"},
            LongestThrow = {"longest throw", "best throw", "distance", "longestdistance"},
        }
        local result = {}
        local function readContainer(container)
            if not container then return end
            for _, child in ipairs(container:GetChildren()) do
                local n = normalize(child.Name)
                local valueObj = child
                if child:IsA("IntValue") or child:IsA("NumberValue") or child:IsA("StringValue") then
                    for key, aliases in pairs(wanted) do
                        if matchesAny(n, aliases) and result[key] == nil then result[key] = valueObj.Value end
                    end
                end
            end
        end
        readContainer(LocalPlayer:FindFirstChild("leaderstats"))
        for key, aliases in pairs(wanted) do
            if result[key] == nil then
                for attributeName, attributeValue in pairs(LocalPlayer:GetAttributes()) do
                    if matchesAny(normalize(attributeName), aliases) then result[key] = attributeValue break end
                end
            end
        end
        return result
    end,
}

local function loadModule(name, url)
    ModuleState[name] = "Loading"
    task.spawn(function()
        local ok, moduleOrError = pcall(function()
            local source = game:HttpGet(url)
            local chunk = loadstring(source)
            assert(type(chunk) == "function", "loadstring did not return a function")
            local module = chunk()
            assert(type(module) == "table", "module must return a table")
            if type(module.Init) == "function" then module:Init(API) end
            return module
        end)
        if ok then
            Modules[name] = moduleOrError
            ModuleState[name] = "Loaded"
            for key, value in pairs(Config) do
                if type(moduleOrError.Set) == "function" then
                    pcall(function() moduleOrError:Set(key, value) end)
                end
            end
            setStatus(name .. " module loaded", true)
        else
            ModuleState[name] = "Failed"
            warn("[LPT Stone Skipping] Could not load " .. name .. ": " .. tostring(moduleOrError))
            setStatus(name .. " module failed to load; check Raw URL", false)
        end
    end)
end

--============================================================
-- PAGES
--============================================================
local home = createPage("Home", "Automation", "Controls for the core train → throw → progress loop.")
local homeSection = createSection(home, "CORE LOOP", 82, 306)

local stonePage = createPage("Stones", "Stones & Wins", "Stone actions only click game UI controls that are currently visible.")
local stoneSection = createSection(stonePage, "STONE MANAGEMENT", 82, 246)

local petPage = createPage("Pets", "Pets & Eggs", "Egg and pet controls use the game's visible UI when available.")
local petSection = createSection(petPage, "PET MANAGEMENT", 82, 246)

local progressPage = createPage("Progress", "Progress Tracker", "Reads local leaderstats and player attributes exposed by the game.")
local progressSection = createSection(progressPage, "CURRENT STATS", 82, 310)

local settingsPage = createPage("Settings", "Settings", "Client-side interface and performance options.")
local settingsSection = createSection(settingsPage, "PREFERENCES", 82, 180)

local function toggleConfig(configKey, moduleName, defaultValue, titleText, description, parent, y)
    local set = createToggle(parent, titleText, description, Config[configKey] == true or (Config[configKey] == nil and defaultValue), function(enabled)
        Config[configKey] = enabled
        saveConfig()
        local module = Modules[moduleName]
        if module and type(module.Set) == "function" then
            local ok, err = pcall(function() module:Set(configKey, enabled) end)
            if not ok then setStatus(titleText .. " failed: " .. tostring(err), false) end
        else
            setStatus(titleText .. " saved; module is not loaded yet", false)
        end
    end, y)
    return set
end

local HomeAutoTrain = toggleConfig("AutoTrain", "Farm", false, "Auto Train", "Find a named training pad; otherwise use a visible Train button.", homeSection, 42)
local HomeAutoThrow = toggleConfig("AutoThrow", "Farm", false, "Auto Throw", "Press the game's visible Throw control at intervals.", homeSection, 101)
local HomeAutoRebirth = toggleConfig("AutoRebirth", "Farm", false, "Auto Rebirth", "Only attempts rebirth when the UI indicates it is ready.", homeSection, 160)
createAction(homeSection, "Train once", "Find a nearby training area or Train control.", function()
    local module = Modules.Farm
    if module and module.Action then module:Action("TrainOnce") else setStatus("Farm module is not loaded", false) end
end, 219)
createAction(homeSection, "Throw once", "Press the visible throw control once.", function()
    local module = Modules.Farm
    if module and module.Action then module:Action("ThrowOnce") else setStatus("Farm module is not loaded", false) end
end, 273)
home.CanvasSize = UDim2.fromOffset(0, 420)

createAction(stoneSection, "Open stone shop", "Open a visible Stone / Throwable shop button.", function()
    local module = Modules.Stones
    if module and module.Action then module:Action("OpenStoneShop") else setStatus("Stones module is not loaded", false) end
end, 42)
createAction(stoneSection, "Equip best stone", "Uses an explicit Equip Best Stone control when present.", function()
    local module = Modules.Stones
    if module and module.Action then module:Action("EquipBestStone") else setStatus("Stones module is not loaded", false) end
end, 96)
createAction(stoneSection, "Buy next stone", "Will not click a generic Buy button unless its card looks stone-related.", function()
    local module = Modules.Stones
    if module and module.Action then module:Action("BuyNextStone") else setStatus("Stones module is not loaded", false) end
end, 150)
stonePage.CanvasSize = UDim2.fromOffset(0, 360)

toggleConfig("AutoHatch", "Pets", false, "Auto Hatch", "Repeats the visible Hatch / Open Egg action.", petSection, 42)
createAction(petSection, "Equip best pets", "Uses an explicit pet-related Equip Best control.", function()
    local module = Modules.Pets
    if module and module.Action then module:Action("EquipBestPets") else setStatus("Pets module is not loaded", false) end
end, 101)
createAction(petSection, "Open egg shop", "Open a visible Eggs / Pets shop control.", function()
    local module = Modules.Pets
    if module and module.Action then module:Action("OpenEggShop") else setStatus("Pets module is not loaded", false) end
end, 155)
createAction(petSection, "Hatch once", "Press the visible Hatch control once.", function()
    local module = Modules.Pets
    if module and module.Action then module:Action("HatchOnce") else setStatus("Pets module is not loaded", false) end
end, 209)
petPage.CanvasSize = UDim2.fromOffset(0, 360)

local statNames = {"Skill", "Wins", "Rebirths", "Level", "LongestThrow"}
local statLabels = {}
for index, statName in ipairs(statNames) do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.5, -18, 0, 58)
    card.Position = UDim2.fromOffset(12 + column * 245, 42 + row * 66)
    card.BackgroundColor3 = C.Surface2
    card.BorderSizePixel = 0
    card.Parent = progressSection
    corner(card, 8)
    label(card, statName == "LongestThrow" and "Longest Throw" or statName, UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 4), 10, C.Muted, Enum.Font.GothamSemibold)
    statLabels[statName] = label(card, "Not exposed", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 26), 15, C.Text, Enum.Font.GothamBold)
end
createAction(progressSection, "Refresh stats", "Re-read leaderstats and attributes now.", function()
    local values = API.GetStats()
    for _, name in ipairs(statNames) do statLabels[name].Text = tostring(values[name] ~= nil and values[name] or "Not exposed") end
    setStatus("Stats refreshed", true)
end, 242)
progressPage.CanvasSize = UDim2.fromOffset(0, 420)

toggleConfig("PerformanceMode", "Settings", false, "Performance Mode", "Locally reduces particle and post-processing effects.", settingsSection, 42)
createAction(settingsSection, "Reset performance changes", "Restore effects changed by this module.", function()
    local module = Modules.Settings
    if module and module.Action then module:Action("RestorePerformance") else setStatus("Settings module is not loaded", false) end
end, 101)
createAction(settingsSection, "Recheck module status", "Show which Raw URL modules loaded.", function()
    local bits = {}
    for name in pairs(ModuleURLs) do table.insert(bits, name .. ": " .. tostring(ModuleState[name] or "Waiting")) end
    setStatus(table.concat(bits, " | "), true)
end, 155)
settingsPage.CanvasSize = UDim2.fromOffset(0, 360)

--============================================================
-- TAB NAVIGATION
--============================================================
local menu = {
    {Name = "Home", Text = "Automation", Page = home},
    {Name = "Stones", Text = "Stones & Wins", Page = stonePage},
    {Name = "Pets", Text = "Pets & Eggs", Page = petPage},
    {Name = "Progress", Text = "Progress", Page = progressPage},
    {Name = "Settings", Text = "Settings", Page = settingsPage},
}

local function selectTab(name)
    currentTab = name
    for _, item in ipairs(menu) do
        local active = item.Name == name
        item.Page.Visible = active
        local data = tabInfo[item.Name]
        if data then
            data.Button.BackgroundColor3 = active and Color3.fromRGB(36, 51, 73) or C.Surface
            data.Button.TextColor3 = active and C.Text or C.Muted
            data.Indicator.Visible = active
        end
    end
end

for index, item in ipairs(menu) do
    local b = Instance.new("TextButton")
    b.Name = item.Name .. "Tab"
    b.Size = UDim2.new(1, 0, 0, 39)
    b.LayoutOrder = index
    b.BackgroundColor3 = C.Surface
    b.BorderSizePixel = 0
    b.Text = "  " .. item.Text
    b.TextColor3 = C.Muted
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false
    b.Parent = TabButtons
    corner(b, 7)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 1, -12)
    indicator.Position = UDim2.fromOffset(0, 6)
    indicator.BackgroundColor3 = C.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = b
    corner(indicator, 5)
    tabInfo[item.Name] = {Button = b, Indicator = indicator}
    b.MouseButton1Click:Connect(function() selectTab(item.Name) end)
end
selectTab("Home")

-- Drag window from top bar.
do
    local dragging = false
    local dragStart, startPos
    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local minimized = false
local reopen = Instance.new("TextButton")
reopen.Name = "ReopenButton"
reopen.Size = UDim2.fromOffset(108, 34)
reopen.Position = UDim2.new(0, 18, 0.5, -17)
reopen.BackgroundColor3 = C.Surface
reopen.BorderSizePixel = 0
reopen.Text = "LPT • OPEN"
reopen.TextColor3 = C.Text
reopen.TextSize = 11
reopen.Font = Enum.Font.GothamBold
reopen.Visible = false
reopen.Parent = ScreenGui
corner(reopen, 8)
stroke(reopen, C.Accent, 0.2, 1)
reopen.MouseButton1Click:Connect(function() minimized = false Main.Visible = true reopen.Visible = false end)
Minimize.MouseButton1Click:Connect(function() minimized = true Main.Visible = false reopen.Visible = true end)
Close.MouseButton1Click:Connect(function()
    for _, module in pairs(Modules) do
        if module and type(module.Destroy) == "function" then pcall(function() module:Destroy() end) end
    end
    ScreenGui:Destroy()
end)

-- Apply persisted toggle settings after page controls exist.
-- Toggles start in the saved state; module load applies the same config.

-- Keep progress cards fresh without altering game state.
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(1)
        local values = API.GetStats()
        for _, name in ipairs(statNames) do
            if statLabels[name] and statLabels[name].Parent then
                statLabels[name].Text = tostring(values[name] ~= nil and values[name] or "Not exposed")
            end
        end
    end
end)

for name, url in pairs(ModuleURLs) do loadModule(name, url) end
setStatus("Loading Raw URL modules...", true)
print("[LPT Stone Skipping] UI ready. Modules are loaded from: " .. RAW_BASE)
