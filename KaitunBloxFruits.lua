local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ENV = (getgenv and getgenv()) or _G

-- Configuration
local DEFAULTS = {
    FlySpeed = 172,
    CruiseHeight = 55,
    ChestWait = 6,
    MaxChestAttempts = 2,
    ServerPages = 1000,
    HopRetryDelay = 10,
    ScanInterval = 1.5,
    ScriptURL = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/KaitunBloxFruits.lua",
}

local CONFIG = {}
for key, value in pairs(DEFAULTS) do
    CONFIG[key] = value
end

ENV.LPTChestKaitun = ENV.LPTChestKaitun or {}
local State = ENV.LPTChestKaitun
State.VisitedServers = State.VisitedServers or {}
if game.JobId ~= "" then
    State.VisitedServers[game.JobId] = true
end

local VisitedChests, ChestAttempts, SkippedChests = {}, {}, {}
local Running, Paused, Stopped = false, false, false
local WorkerId = 0
local StartedAt = 0
local Connections = {}
local Logs = {}
local SettingsInputs = {}

local Stats = { Chests = 0, Servers = 0, Beli = 0, StartBeli = 0 }

local COLORS = {
    Background = Color3.fromRGB(8, 15, 25),
    Panel = Color3.fromRGB(15, 28, 42),
    Card = Color3.fromRGB(20, 35, 51),
    Border = Color3.fromRGB(51, 72, 94),
    Gold = Color3.fromRGB(255, 199, 35),
    GoldDark = Color3.fromRGB(202, 140, 14),
    White = Color3.fromRGB(240, 245, 255),
    Muted = Color3.fromRGB(153, 174, 199),
    Green = Color3.fromRGB(82, 235, 123),
    Red = Color3.fromRGB(255, 87, 100),
    Blue = Color3.fromRGB(76, 173, 255),
}

-- UI references
local ScreenGui, Main, Header, Nav, Content, DynamicIsland
local StatusLabel, IslandStatus, IslandChestCount, ChestValue, ServerValue, BeliValue, RuntimeValue
local LogList, CurrentPage = nil, "Tổng quan"
local Pages, NavButtons = {}, {}
local IsIslandMode, IsDragging, IsReflowing = false, false, false
local DragStart, DragPosition

local function addConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function safeDisconnectAll()
    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)
end

local function formatNumber(number)
    local s = tostring(math.floor(tonumber(number) or 0))
    local reversed = s:reverse():gsub("(%d%d%d)", "%1,")
    return reversed:reverse():gsub("^,", "")
end

local function elapsedText()
    local seconds = math.max(0, math.floor(os.clock() - StartedAt))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

local function getRoot()
    local character = Player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getBeliFrom(container)
    if not container then return nil end
    local value = container:FindFirstChild("Beli") or container:FindFirstChild("Money")
    if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
        return tonumber(value.Value)
    end
end

local function getBeli()
    return getBeliFrom(Player:FindFirstChild("Data"))
        or getBeliFrom(Player:FindFirstChild("leaderstats"))
        or getBeliFrom(Player)
end

local function isActive(id)
    return Running and not Paused and not Stopped and id == WorkerId
end

local function waitUntilUnpaused(id)
    while Paused and Running and not Stopped and id == WorkerId do
        task.wait(0.15)
    end
    return isActive(id)
end

local function log(message, kind)
    table.insert(Logs, 1, { Time = os.date("%H:%M:%S"), Message = tostring(message), Kind = kind or "info" })
    while #Logs > 80 do table.remove(Logs) end
    print("[LPT Chest] " .. tostring(message))
end

-- Important-item watcher. Detection is safe, but boss summon/combat remotes are game-specific
-- and are intentionally not guessed. The UI log tells the user when either item is detected.
local SeenSpecialItems = {}
local SPECIAL_ITEMS = {
    ["God's Chalice"] = "Chén Thánh (Sea 3)",
    ["God's Chalice"] = "Chén Thánh (Sea 3)",
    ["Fist of Darkness"] = "Fist of Darkness (Sea 2)",
    ["Blackbeard's Key"] = "Key Râu Đen (nếu game/mod hiển thị tên này)",
}

local function scanSpecialItems()
    local containers = { Player:FindFirstChild("Backpack"), Player.Character }
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and SPECIAL_ITEMS[item.Name] and not SeenSpecialItems[item.Name] then
                    SeenSpecialItems[item.Name] = true
                    log("Phát hiện vật phẩm: " .. SPECIAL_ITEMS[item.Name] .. ". Cần cấu hình cơ chế triệu hồi boss đúng với phiên bản game để tự spawn/đánh.", "success")
                end
            end
        end
    end
end

-- Chest collection logic
local function isChestName(name)
    return string.lower(name):match("^chest%d*$") ~= nil
end

local function hasChestModelAncestor(object)
    local parent = object.Parent
    while parent and parent ~= workspace do
        if parent:IsA("Model") and isChestName(parent.Name) then return true end
        parent = parent.Parent
    end
    return false
end

local function getChestPart(object)
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
    end
end

local function chestKey(object, part)
    local p = part.Position
    return string.format("%s:%.1f:%.1f:%.1f", string.lower(object.Name), p.X, p.Y, p.Z)
end

local function findChests(id)
    local chests, seen = {}, {}
    for _, object in ipairs(workspace:GetDescendants()) do
        if not isActive(id) then break end
        local chestModel = object:IsA("Model") and isChestName(object.Name)
        local chestPart = object:IsA("BasePart") and isChestName(object.Name) and not hasChestModelAncestor(object)
        if chestModel or chestPart then
            local part = getChestPart(object)
            if part and part:IsDescendantOf(workspace) then
                local key = chestKey(object, part)
                if not seen[key] then
                    seen[key] = true
                    table.insert(chests, { Object = object, Part = part, Key = key })
                end
            end
        end
    end
    return chests
end

local function beginFlight()
    local character, root = Player.Character, getRoot()
    if not character or not root then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local state = { Humanoid = humanoid, AutoRotate = humanoid and humanoid.AutoRotate, Parts = {} }
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            state.Parts[object] = object.CanCollide
            object.CanCollide = false
        end
    end
    if humanoid then
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    return state
end

local function endFlight(state)
    if not state then return end
    for part, canCollide in pairs(state.Parts) do
        if part and part.Parent then part.CanCollide = canCollide end
    end
    if state.Humanoid and state.Humanoid.Parent then
        state.Humanoid.AutoRotate = state.AutoRotate
        state.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function moveRootTo(position, id)
    local root = getRoot()
    if not root then return false end
    local origin, distance = root.Position, (position - root.Position).Magnitude
    local duration, elapsed = math.max(distance / math.max(1, CONFIG.FlySpeed), 0.2), 0
    while elapsed < duration do
        if not waitUntilUnpaused(id) or getRoot() ~= root or not root.Parent then return false end
        elapsed += RunService.Heartbeat:Wait()
        root.CFrame = CFrame.new(origin:Lerp(position, math.clamp(elapsed / duration, 0, 1)))
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    end
    if getRoot() ~= root or not root.Parent then return false end
    root.CFrame = CFrame.new(position)
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    return isActive(id)
end

local function flyToChest(part, id)
    if not part or not part:IsDescendantOf(workspace) then return false end
    local root, flight = getRoot(), beginFlight()
    if not root or not flight then return false end
    local function finish(result) endFlight(flight); return result end
    local target = part.Position
    local horizontal = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z).Magnitude
    if horizontal > 60 then
        local altitude = math.max(root.Position.Y, target.Y + CONFIG.CruiseHeight)
        if root.Position.Y < altitude - 3 and not moveRootTo(Vector3.new(root.Position.X, altitude, root.Position.Z), id) then return finish(false) end
        if not moveRootTo(Vector3.new(target.X, altitude, target.Z), id) then return finish(false) end
    end
    if not part:IsDescendantOf(workspace) then return finish(false) end
    return finish(moveRootTo(part.Position + Vector3.new(0, 2, 0), id))
end

local function verifyChest(chest, previousBeli, id)
    local disappeared, deadline = false, os.clock() + CONFIG.ChestWait
    while os.clock() < deadline and isActive(id) do
        if not waitUntilUnpaused(id) then return false end
        local currentBeli = getBeli()
        if previousBeli and currentBeli and currentBeli > previousBeli then return true end
        if not chest.Object:IsDescendantOf(workspace) or not chest.Part:IsDescendantOf(workspace) then disappeared = true end
        task.wait(0.15)
    end
    local currentBeli = getBeli()
    return previousBeli and currentBeli and currentBeli > previousBeli or (not previousBeli and disappeared)
end

local function collectChests(id)
    local root = getRoot()
    if not root then return false end
    local chests = findChests(id)
    table.sort(chests, function(a, b)
        local current = getRoot()
        if not current then return false end
        return (a.Part.Position - current.Position).Magnitude < (b.Part.Position - current.Position).Magnitude
    end)
    local found = false
    for _, chest in ipairs(chests) do
        if not isActive(id) then break end
        local key = chest.Key
        if not VisitedChests[key] and not SkippedChests[key] and chest.Part:IsDescendantOf(workspace) then
            found = true
            ChestAttempts[key] = (ChestAttempts[key] or 0) + 1
            log("Đang đến rương: " .. chest.Object.Name, "info")
            local before = getBeli()
            if flyToChest(chest.Part, id) then
                task.wait(0.35)
                if verifyChest(chest, before, id) then
                    VisitedChests[key], ChestAttempts[key] = true, nil
                    Stats.Chests += 1
                    Stats.Beli = math.max(0, (getBeli() or Stats.StartBeli) - Stats.StartBeli)
                    log("Đã xác nhận rương thưởng.", "success")
                elseif ChestAttempts[key] >= CONFIG.MaxChestAttempts then
                    SkippedChests[key] = true
                    log("Bỏ qua rương sau " .. CONFIG.MaxChestAttempts .. " lần thử.", "warn")
                else
                    log("Chưa xác nhận phần thưởng, sẽ thử lại.", "warn")
                end
            end
        end
    end
    return found
end

local function requestServerPage(cursor)
    local url = "https://games.roblox.com/v1/games/"
        .. tostring(game.PlaceId)
        .. "/servers/Public?sortOrder=Asc&limit=100"

    if cursor and cursor ~= "" then
        url ..= "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local ok, result = pcall(function()
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)

    if not ok or type(result) ~= "table" then
        return nil
    end

    return result
end

local function queueContinuation()
    local url = CONFIG.ScriptURL

    if not url:match("^https://raw%.githubusercontent%.com/")
        or url:find("USERNAME", 1, true)
        or url:find("REPOSITORY", 1, true) then
        log("Chưa hop: hãy đặt ScriptURL thành GitHub Raw URL hợp lệ.", "error")
        return false
    end

    -- Script chỉ được tải lại sau khi client đã vào server đích.
    local queue = (type(queue_on_teleport) == "function" and queue_on_teleport)
        or (type(queueonteleport) == "function" and queueonteleport)
        or (type(syn) == "table" and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
        or (type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)

    if type(queue) ~= "function" then
        log("Executor không hỗ trợ queue_on_teleport; không thể tự chạy lại sau khi vào server mới.", "error")
        return false
    end

    local code = ("task.wait(3); loadstring(game:HttpGet(%q))()") :format(url)
    local ok, err = pcall(queue, code)

    if not ok then
        log("Không thể xếp script chạy sau teleport: " .. tostring(err), "error")
        return false
    end

    return true
end

local function getEligiblePublicServers(id)
    local candidates = {}
    local seen = {}
    local cursor = nil
    local pageNumber = 0
    local maxPages = math.max(1, math.floor(tonumber(CONFIG.ServerPages) or 1000))

    log("Đang quét danh sách server công khai của sea hiện tại...", "info")

    repeat
        if id and not isActive(id) then
            return candidates
        end

        pageNumber += 1
        local page = requestServerPage(cursor)

        if not page then
            log("Không đọc được trang server số " .. pageNumber .. ". Có thể API đang giới hạn yêu cầu.", "warn")
            break
        end

        for _, server in ipairs(page.data or {}) do
            local serverId = server.id
            local players = tonumber(server.playing)

            -- Chỉ chọn server có ít hơn 12 người; server đủ 12 người bị loại.
            if serverId
                and serverId ~= game.JobId
                and players ~= nil
                and players < 12
                and not State.VisitedServers[serverId]
                and not seen[serverId] then
                seen[serverId] = true
                table.insert(candidates, {
                    Id = serverId,
                    Players = players,
                })
            end
        end

        cursor = page.nextPageCursor
    until not cursor or pageNumber >= maxPages

    log(string.format(
        "Đã quét %d trang; tìm thấy %d server chưa ghé có dưới 12 người.",
        pageNumber,
        #candidates
    ), "info")

    return candidates
end

local function tryTeleportToServer(serverId)
    if not queueContinuation() then
        return false
    end

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, Player)
    end)

    if not ok then
        log("Không vào được server " .. tostring(serverId) .. ": " .. tostring(err), "warn")
        return false
    end

    State.VisitedServers[serverId] = true
    Stats.Servers += 1
    log("Đang kết nối server đích (script sẽ tải sau khi vào server)...", "success")
    return true
end

local function serverHop(id)
    if not isActive(id) then
        return false
    end

    local candidates = getEligiblePublicServers(id)

    -- Thử lần lượt mọi ứng viên đã lấy được; nếu lời gọi teleport lỗi,
    -- chuyển sang server kế tiếp thay vì dừng ở ứng viên đầu tiên.
    for _, server in ipairs(candidates) do
        if not isActive(id) then
            return false
        end

        if not State.VisitedServers[server.Id] then
            log(string.format(
                "Đang thử server có %d/12 người...",
                server.Players
            ), "info")

            if tryTeleportToServer(server.Id) then
                return true
            end

            -- Đánh dấu ứng viên lỗi trong phiên này để tránh lặp lại liên tục.
            State.VisitedServers[server.Id] = true
            task.wait(0.25)
        end
    end

    log("Đã thử hết các server phù hợp tìm được. Sẽ làm mới danh sách để thử lại.", "warn")

    -- Làm mới danh sách đã ghé, nhưng giữ server hiện tại để không hop ngược ngay.
    table.clear(State.VisitedServers)
    if game.JobId ~= "" then
        State.VisitedServers[game.JobId] = true
    end

    candidates = getEligiblePublicServers(id)

    for _, server in ipairs(candidates) do
        if not isActive(id) then
            return false
        end

        log(string.format(
            "Thử lại server có %d/12 người...",
            server.Players
        ), "info")

        if tryTeleportToServer(server.Id) then
            return true
        end

        State.VisitedServers[server.Id] = true
        task.wait(0.25)
    end

    log("Không thể vào server phù hợp nào trong danh sách hiện có. Thử lại sau.", "error")
    return false
end

-- UI construction helpers
local function create(class, properties, parent)
    local instance = Instance.new(class)
    for key, value in pairs(properties or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local function round(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, object)
end

local function outline(object, color, thickness)
    return create("UIStroke", { Color = color or COLORS.Border, Thickness = thickness or 1 }, object)
end

local function text(parent, value, size, color, font)
    return create("TextLabel", { BackgroundTransparency = 1, Text = value or "", TextSize = size or 14, TextColor3 = color or COLORS.White, Font = font or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.new(1, 0, 0, 24) }, parent)
end

local function addButton(parent, title, callback, color)
    local button = create("TextButton", { BackgroundColor3 = color or COLORS.Card, Text = title, TextColor3 = COLORS.White, TextSize = 14, Font = Enum.Font.GothamSemibold, AutoButtonColor = true, Size = UDim2.new(1, 0, 0, 42) }, parent)
    round(button, 8); outline(button)
    addConnection(button.Activated:Connect(function() if callback then callback() end end))
    return button
end

local function makePage(name)
    local page = create("ScrollingFrame", { Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = COLORS.Gold, Visible = false }, Content)
    create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, page)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    Pages[name] = page
    return page
end

local function makeCard(parent, titleValue, height)
    local card = create("Frame", { BackgroundColor3 = COLORS.Card, Size = UDim2.new(1, 0, 0, height) }, parent)
    round(card, 10); outline(card)
    local title = text(card, titleValue, 14, COLORS.Gold, Enum.Font.GothamBold)
    title.Position, title.Size = UDim2.fromOffset(14, 7), UDim2.new(1, -28, 0, 26)
    return card
end

local function makeStat(parent, titleValue, value)
    local card = create("Frame", { BackgroundColor3 = COLORS.Panel, Size = UDim2.new(0.5, -5, 0, 76) }, parent)
    round(card, 8); outline(card, COLORS.Border)
    local labelTitle = text(card, titleValue, 11, COLORS.Muted, Enum.Font.Gotham)
    labelTitle.Position, labelTitle.Size = UDim2.fromOffset(12, 9), UDim2.new(1, -24, 0, 20)
    local labelValue = text(card, value, 22, COLORS.White, Enum.Font.GothamBold)
    labelValue.Position, labelValue.Size = UDim2.fromOffset(12, 29), UDim2.new(1, -24, 0, 32)
    return labelValue
end

local function addSetting(parent, titleValue, key, min, max, decimals)
    local row = create("Frame", { BackgroundColor3 = COLORS.Panel, Size = UDim2.new(1, 0, 0, 52) }, parent)
    round(row, 7)
    local title = text(row, titleValue, 12, COLORS.Muted)
    title.Position, title.Size = UDim2.fromOffset(10, 0), UDim2.new(1, -105, 1, 0)
    local input = create("TextBox", { BackgroundColor3 = COLORS.Background, Position = UDim2.new(1, -88, 0.5, -16), Size = UDim2.fromOffset(76, 32), Text = tostring(CONFIG[key]), TextColor3 = COLORS.Gold, TextSize = 13, Font = Enum.Font.GothamBold, ClearTextOnFocus = false }, row)
    round(input, 6); outline(input)
    SettingsInputs[key] = input
    addConnection(input.FocusLost:Connect(function()
        local number = tonumber(input.Text)
        if number then
            number = math.clamp(number, min, max)
            if decimals == 0 then number = math.floor(number) end
            CONFIG[key], input.Text = number, tostring(number)
            log("Đã cập nhật " .. titleValue .. ": " .. input.Text)
        else
            input.Text = tostring(CONFIG[key])
        end
    end))
end

local function resetSettings()
    for key, value in pairs(DEFAULTS) do
        CONFIG[key] = value
        if SettingsInputs[key] then SettingsInputs[key].Text = tostring(value) end
    end
    log("Đã khôi phục cài đặt mặc định.", "success")
end

local function showPage(name)
    CurrentPage = name
    for pageName, page in pairs(Pages) do page.Visible = pageName == name end
    for pageName, button in pairs(NavButtons) do
        button.BackgroundColor3 = pageName == name and COLORS.GoldDark or COLORS.Panel
        button.TextColor3 = pageName == name and COLORS.White or COLORS.Muted
    end
end

local function updateLogs()
    if not LogList or not LogList.Parent then return end
    for _, child in ipairs(LogList:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    for _, item in ipairs(Logs) do
        local color = item.Kind == "success" and COLORS.Green or item.Kind == "error" and COLORS.Red or item.Kind == "warn" and COLORS.Gold or COLORS.Muted
        local line = text(LogList, "[" .. item.Time .. "]  " .. item.Message, 11, color)
        line.Size, line.TextWrapped = UDim2.new(1, 0, 0, 24), true
    end
end

local function statusInfo()
    if Stopped then return "ĐÃ DỪNG", COLORS.Red end
    if Paused then return "ĐANG TẠM DỪNG", COLORS.Gold end
    if Running then return "ĐANG NHẶT RƯƠNG", COLORS.Green end
    return "● ĐANG CHỜ", COLORS.Muted
end

local function updateUI()
    if not ScreenGui or not ScreenGui.Parent then return end
    local status, color = statusInfo()
    if StatusLabel then StatusLabel.Text, StatusLabel.TextColor3 = status, color end
    if IslandStatus then IslandStatus.Text, IslandStatus.TextColor3 = status, color end
    if IslandChestCount then IslandChestCount.Text = "Rương: " .. formatNumber(Stats.Chests) end
    if ChestValue then ChestValue.Text = formatNumber(Stats.Chests) end
    if ServerValue then ServerValue.Text = formatNumber(Stats.Servers) end
    if BeliValue then BeliValue.Text = "$" .. formatNumber(Stats.Beli) end
    if RuntimeValue then RuntimeValue.Text = (Running or Paused) and elapsedText() or "00:00:00" end
    updateLogs()
end

local function getLayout()
    Camera = workspace.CurrentCamera or Camera
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local narrow = viewport.X < 700
    local width = math.clamp(math.floor(viewport.X * (narrow and 0.94 or 0.82)), 310, 1060)
    local height = math.clamp(math.floor(viewport.Y * (narrow and 0.86 or 0.78)), 370, 720)
    return viewport, width, height, narrow
end

local function clampMainPosition()
    if not Main or not Camera then return end
    local viewport, width, height = getLayout()
    local x, y = Main.Position.X.Offset, Main.Position.Y.Offset
    local halfW, halfH = width / 2, height / 2
    x = math.clamp(x, halfW + 8, viewport.X - halfW - 8)
    y = math.clamp(y, halfH + 8, viewport.Y - halfH - 8)
    Main.Position = UDim2.fromOffset(x, y)
end

local function reflowUI()
    if not Main or IsIslandMode then return end
    IsReflowing = true
    local _, width, height, narrow = getLayout()
    Main.Size = UDim2.fromOffset(width, height)
    if not IsDragging then Main.Position = UDim2.fromScale(0.5, 0.5) else clampMainPosition() end
    Header.Size = UDim2.new(1, 0, 0, narrow and 70 or 76)
    local headerTitle = Header:FindFirstChild("Title")
    local headerSubtitle = Header:FindFirstChild("Subtitle")
    if headerTitle then
        headerTitle.TextSize = narrow and 15 or 20
        headerTitle.Size = narrow and UDim2.new(1, -118, 0, 34) or UDim2.new(1, -205, 0, 28)
    end
    if headerSubtitle then headerSubtitle.Visible = not narrow end
    if StatusLabel then StatusLabel.Visible = not narrow end
    Nav.Size = narrow and UDim2.new(1, -20, 0, 44) or UDim2.new(0, 156, 1, -96)
    Nav.Position = narrow and UDim2.fromOffset(10, 78) or UDim2.fromOffset(10, 86)
    Content.Position = narrow and UDim2.fromOffset(10, 128) or UDim2.fromOffset(176, 86)
    Content.Size = narrow and UDim2.new(1, -20, 1, -138) or UDim2.new(1, -186, 1, -96)
    local layout = Nav:FindFirstChildOfClass("UIListLayout")
    if layout then layout.FillDirection = narrow and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical end
    for _, button in pairs(NavButtons) do button.Size = narrow and UDim2.new(0.25, -5, 1, 0) or UDim2.new(1, 0, 0, 40) end
    IsReflowing = false
end

local function minimizeToIsland()
    if IsIslandMode or not Main then return end
    IsIslandMode = true
    Nav.Visible, Content.Visible = false, false
    Main.ClipsDescendants = true
    local _, width = getLayout()
    local collapse = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.fromOffset(math.min(width, 320), 70), Position = UDim2.fromOffset((workspace.CurrentCamera.ViewportSize.X) / 2, 42) })
    collapse:Play()
    task.delay(0.22, function()
        if not IsIslandMode or not Main or not Main.Parent then return end
        Main.Visible, DynamicIsland.Visible = false, true
        DynamicIsland.Position = UDim2.new(0.5, 0, 0, -64)
        TweenService:Create(DynamicIsland, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 12) }):Play()
    end)
end

local function restoreFromIsland()
    if not IsIslandMode or not Main then return end
    IsIslandMode = false
    TweenService:Create(DynamicIsland, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -64) }):Play()
    task.delay(0.18, function()
        if IsIslandMode or not Main or not Main.Parent then return end
        DynamicIsland.Visible, Main.Visible = false, true
        Main.Position = UDim2.fromScale(0.5, 0.5)
        reflowUI()
        Nav.Visible, Content.Visible, Main.ClipsDescendants = true, true, true
    end)
end

local function buildUI()
    safeDisconnectAll()
    local playerGui = Player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("LPTChestKaitunUI")
    if old then old:Destroy() end
    ScreenGui = create("ScreenGui", { Name = "LPTChestKaitunUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 }, playerGui)
    Main = create("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = COLORS.Background, ClipsDescendants = true }, ScreenGui)
    round(Main, 14); outline(Main, COLORS.Gold, 1.3)
    Header = create("Frame", { BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 76) }, Main)
    local logo = text(Header, "▣", 31, COLORS.Gold, Enum.Font.GothamBlack); logo.Position, logo.Size = UDim2.fromOffset(14, 10), UDim2.fromOffset(42, 48); logo.TextXAlignment = Enum.TextXAlignment.Center
    local title = text(Header, "LPT CHEST KAITUN", 20, COLORS.Gold, Enum.Font.GothamBlack); title.Name, title.Position, title.Size = "Title", UDim2.fromOffset(64, 9), UDim2.new(1, -205, 0, 28)
    local subtitle = text(Header, "BLOX FRUITS • CHEST COLLECTOR", 10, COLORS.Muted); subtitle.Name, subtitle.Position, subtitle.Size = "Subtitle", UDim2.fromOffset(65, 38), UDim2.new(1, -205, 0, 20)
    StatusLabel = text(Header, "● ĐANG CHỜ", 10, COLORS.Muted, Enum.Font.GothamBold); StatusLabel.AnchorPoint, StatusLabel.Position, StatusLabel.Size, StatusLabel.TextXAlignment = Vector2.new(1, .5), UDim2.new(1, -52, .5, 0), UDim2.fromOffset(135, 28), Enum.TextXAlignment.Right
    local minimize = addButton(Header, "—", minimizeToIsland, COLORS.Panel); minimize.Position, minimize.Size = UDim2.new(1, -42, 0, 19), UDim2.fromOffset(30, 32)
    Nav = create("Frame", { BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0 }, Main)
    round(Nav, 10); outline(Nav)
    create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, Nav)
    create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, Nav)
    Content = create("Frame", { BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0 }, Main)
    round(Content, 10); outline(Content)

    local overview, settings, logs = makePage("Tổng quan"), makePage("Cài đặt"), makePage("Nhật ký")
    local statsCard = makeCard(overview, "THỐNG KÊ PHIÊN", 174)
    local grid = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 1, -54) }, statsCard)
    create("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 76), CellPadding = UDim2.fromOffset(10, 10), FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder }, grid)
    ChestValue = makeStat(grid, "RƯƠNG ĐÃ NHẶT", "0")
    ServerValue = makeStat(grid, "SERVER ĐÃ HOP", "0")
    BeliValue = makeStat(grid, "BELI NHẬN ĐƯỢC", "$0")
    RuntimeValue = makeStat(grid, "THỜI GIAN", "00:00:00")
    local info = makeCard(overview, "TRẠNG THÁI & MỤC TIÊU", 100)
    local infoText = text(info, "Tự quét rương và xác minh Beli khi có thể. Tính năng tự triệu hồi/đánh boss cần xác định đúng cơ chế game trước khi bật.", 11, COLORS.Muted)
    infoText.Position, infoText.Size, infoText.TextWrapped, infoText.TextYAlignment = UDim2.fromOffset(14, 38), UDim2.new(1, -28, 0, 52), true, Enum.TextYAlignment.Top

    local settingsCard = makeCard(settings, "THÔNG SỐ BAY & QUÉT", 405)
    local settingsList = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 1, -52) }, settingsCard)
    create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, settingsList)
    addSetting(settingsList, "Tốc độ bay", "FlySpeed", 10, 1000, 0)
    addSetting(settingsList, "Độ cao bay", "CruiseHeight", 1, 500, 0)
    addSetting(settingsList, "Chờ xác minh (giây)", "ChestWait", 1, 60, 1)
    addSetting(settingsList, "Số lần thử mỗi rương", "MaxChestAttempts", 1, 10, 0)
    addSetting(settingsList, "Số trang server tối đa", "ServerPages", 1, 1000, 0)
    addSetting(settingsList, "Chu kỳ quét (giây)", "ScanInterval", 0.5, 30, 1)
    local reset = addButton(settings, "Khôi phục cài đặt mặc định", resetSettings, COLORS.GoldDark); reset.Position, reset.Size = UDim2.new(0, 245, 1, -52), UDim2.fromOffset(245, 38)

    local logCard = makeCard(logs, "NHẬT KÝ HOẠT ĐỘNG", 390)
    LogList = create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 1, -52), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.Gold }, logCard)
    create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, LogList)

    local controlCard = makeCard(overview, "ĐIỀU KHIỂN NHANH", 238)
    local controlsList = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 1, -54) }, controlCard)
    create("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 48), CellPadding = UDim2.fromOffset(10, 9), FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder }, controlsList)
    addButton(controlsList, "▶  BẮT ĐẦU", function()
        if Running then log("Script đã chạy.", "warn"); return end
        Stopped, Paused, Running = false, false, true
        WorkerId += 1; local id = WorkerId
        StartedAt, Stats.StartBeli, Stats.Beli = os.clock(), getBeli() or 0, 0
        log("Đã bắt đầu quét rương.", "success")
        task.spawn(function()
            while isActive(id) do
                scanSpecialItems()
                local found = collectChests(id)
                if isActive(id) and not found then serverHop(id) end
                local untilTime = os.clock() + CONFIG.ScanInterval
                while os.clock() < untilTime and Running and not Stopped and id == WorkerId do task.wait(.1) end
            end
        end)
    end, COLORS.Green)
    addButton(controlsList, "Ⅱ  TẠM DỪNG / TIẾP TỤC", function()
        if not Running then log("Hãy bắt đầu trước.", "warn"); return end
        Paused = not Paused; log(Paused and "Đã tạm dừng." or "Đã tiếp tục.", Paused and "warn" or "success")
    end, COLORS.GoldDark)
    addButton(controlsList, "■  DỪNG & DỌN DẸP", function()
        Running, Paused, Stopped = false, false, true; WorkerId += 1; log("Đã dừng script an toàn.", "error")
    end, COLORS.Red)
    addButton(controlsList, "↻  HOP SERVER NGAY", function()
        if Running then task.spawn(function() serverHop(WorkerId) end) else log("Hãy bắt đầu trước để hop server.", "warn") end
    end, COLORS.Blue)

    for _, name in ipairs({ "Tổng quan", "Cài đặt", "Nhật ký" }) do
        NavButtons[name] = addButton(Nav, name, function() showPage(name) end, COLORS.Panel)
    end

    DynamicIsland = create("Frame", { Name = "DynamicIsland", AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, -64), Size = UDim2.fromOffset(224, 52), BackgroundColor3 = COLORS.Background, Visible = false, ZIndex = 50 }, ScreenGui)
    round(DynamicIsland, 26); outline(DynamicIsland, COLORS.Gold, 1.3)
    local islandButton = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 51 }, DynamicIsland)
    local icon = text(DynamicIsland, "▣", 21, COLORS.Gold, Enum.Font.GothamBlack); icon.Position, icon.Size, icon.ZIndex = UDim2.fromOffset(13, 0), UDim2.fromOffset(28, 52), 52
    IslandStatus = text(DynamicIsland, "● ĐANG CHỜ", 11, COLORS.Muted, Enum.Font.GothamBold); IslandStatus.Position, IslandStatus.Size, IslandStatus.ZIndex = UDim2.fromOffset(48, 5), UDim2.new(1, -60, 0, 21), 52
    IslandChestCount = text(DynamicIsland, "Rương: 0", 10, COLORS.Muted); IslandChestCount.Position, IslandChestCount.Size, IslandChestCount.ZIndex = UDim2.fromOffset(48, 25), UDim2.new(1, -60, 0, 18), 52
    addConnection(islandButton.Activated:Connect(restoreFromIsland))
    addConnection(Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsDragging, DragStart, DragPosition = true, input.Position, Main.Position end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(input)
        if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and DragStart then
            local delta = input.Position - DragStart
            Main.Position = UDim2.fromOffset(DragPosition.X.Offset + delta.X, DragPosition.Y.Offset + delta.Y)
            clampMainPosition()
        end
    end))
    addConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsDragging = false end
    end))
    if Camera then addConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(reflowUI)) end
    addConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera
        if Camera then addConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(reflowUI)) end
        reflowUI()
    end))
    showPage("Tổng quan")
    reflowUI()
    log("Giao diện sẵn sàng.", "success")
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do updateUI(); task.wait(.25) end
    end)
end

buildUI()

task.spawn(function()
    while ScreenGui and ScreenGui.Parent and not Stopped do
        scanSpecialItems()
        task.wait(1)
    end
end)
