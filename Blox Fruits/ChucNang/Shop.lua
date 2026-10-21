local ShopModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local BuyItemRemote = nil
local RedeemCodeRemote = nil

local function refreshRemotes()
    local remotesFolder = ReplicatedStorage:FindFirstChild("ShopRemotes")

    if not remotesFolder then
        BuyItemRemote = nil
        RedeemCodeRemote = nil
        return false
    end

    BuyItemRemote = remotesFolder:FindFirstChild("BuyItem")
    RedeemCodeRemote = remotesFolder:FindFirstChild("RedeemCode")

    return true
end

refreshRemotes()

--========================================================
-- CONFIG
--========================================================

local LIGHT_BLUE = Color3.fromRGB(135, 206, 250)

local ShopConfig = {
    ["Reroll Race"] = {
        Type = "Button",
        Cost = 2500,
        Currency = "Fragments",
        Color = LIGHT_BLUE,
    },

    ["Reset Stats"] = {
        Type = "Button",
        Cost = 3000,
        Currency = "Fragments",
        Color = LIGHT_BLUE,
    },

    ["Buy Race Cyborg"] = {
        Type = "Button",
        Cost = 3000,
        Currency = "Fragments",
        Color = LIGHT_BLUE,
    },

    ["Buy Race Ghoul"] = {
        Type = "Button",
        Cost = 3000,
        Currency = "Fragments",
        Color = LIGHT_BLUE,
    },

    ["Dark Step"] = { Type = "Toggle" },
    ["Electric"] = { Type = "Toggle" },
    ["Water Kung Fu"] = { Type = "Toggle" },
    ["Dragon Breath"] = { Type = "Toggle" },
    ["Superhuman"] = { Type = "Toggle" },
    ["Death Step"] = { Type = "Toggle" },
    ["Sharkman Karate"] = { Type = "Toggle" },
    ["Electric Claw"] = { Type = "Toggle" },
    ["Dragon Talon"] = { Type = "Toggle" },
    ["God Human"] = { Type = "Toggle" },
    ["Sanguine Art"] = { Type = "Toggle" },

    ["Sky Jump"] = {
        Type = "Button",
        Cost = 10000,
        Currency = "Beli",
        Color = LIGHT_BLUE,
    },

    ["Buso Haki"] = {
        Type = "Button",
        Cost = 25000,
        Currency = "Beli",
        Color = LIGHT_BLUE,
    },

    ["Flash Step"] = {
        Type = "Button",
        Cost = 100000,
        Currency = "Beli",
        Color = LIGHT_BLUE,
    },

    ["Observation Haki"] = {
        Type = "Button",
        Cost = 750000,
        Currency = "Beli",
        Color = LIGHT_BLUE,
    },
}

--========================================================
-- FIGHTING STYLE NPC SCAN CONFIG
--========================================================

local FightingStyleKeywords = {
    ["Dark Step"] = { "dark step teacher" },
    ["Electric"] = { "mad scientist" },
    ["Water Kung Fu"] = { "water kung fu teacher" },
    ["Dragon Breath"] = { "sabi" },
    ["Superhuman"] = { "martial arts master" },
    ["Death Step"] = { "phoeyu", "reformed" },
    ["Sharkman Karate"] = { "sharkman teacher", "daigrock" },
    ["Electric Claw"] = { "previous hero" },
    ["Dragon Talon"] = { "uzoth" },
    ["God Human"] = { "ancient monk" },
    ["Sanguine Art"] = { "shafi" },
}

-- Each style uses the game's usual server command to buy/relearn it.
-- Some styles need a short command sequence rather than one command.
local FightingStyleCommands = {
    ["Dark Step"] = {
        { "BuyBlackLeg" },
    },
    ["Electric"] = {
        { "BuyElectro" },
    },
    ["Water Kung Fu"] = {
        { "BuyFishmanKarate" },
    },
    ["Dragon Breath"] = {
        { "BlackbeardReward", "DragonClaw", "1" },
        { "BlackbeardReward", "DragonClaw", "2" },
    },
    ["Superhuman"] = {
        { "BuySuperhuman" },
    },
    ["Death Step"] = {
        { "BuyDeathStep" },
    },
    ["Sharkman Karate"] = {
        { "BuySharkmanKarate", true },
        { "BuySharkmanKarate" },
    },
    ["Electric Claw"] = {
        { "BuyElectricClaw" },
    },
    ["Dragon Talon"] = {
        { "BuyDragonTalon" },
    },
    ["God Human"] = {
        { "BuyGodhuman" },
    },
    ["Sanguine Art"] = {
        { "BuySanguineArt" },
    },
}

-- Fallback landmarks are used when StreamingEnabled means the target NPC
-- is not yet replicated into Workspace. These are island-area coordinates,
-- not exact NPC coordinates; after arriving, the module scans again for the rig.
local FightingStyleFallbackPositions = {
    -- Blox Fruits First Sea
    [2753915549] = {
        ["Dark Step"] = { Name = "Pirate Village", Position = Vector3.new(-1152, 25, 3826) },
        ["Electric"] = { Name = "lower Skylands", Position = Vector3.new(-4851, 400, -2561) },
        ["Water Kung Fu"] = { Name = "Underwater City", Position = Vector3.new(61000, 25, 1800) },
    },

    -- Blox Fruits Second Sea
    [4442272183] = {
        ["Dark Step"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Electric"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Water Kung Fu"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Dragon Breath"] = { Name = "Kingdom of Rose", Position = Vector3.new(-2247, 100, -1671) },
        ["Superhuman"] = { Name = "Snow Mountain", Position = Vector3.new(609, 400, -5258) },
        ["Death Step"] = { Name = "Ice Castle", Position = Vector3.new(6170, 290, -6734) },
        ["Sharkman Karate"] = { Name = "Forgotten Island", Position = Vector3.new(-3053, 240, -10112) },
    },

    -- Blox Fruits Third Sea. First- and Second-Sea teachers are also present
    -- at Castle on the Sea in this Sea.
    [7449423635] = {
        ["Dark Step"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Electric"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Water Kung Fu"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Dragon Breath"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Superhuman"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Death Step"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Sharkman Karate"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Electric Claw"] = { Name = "Floating Turtle", Position = Vector3.new(-12164, 380, -8454) },
        ["Dragon Talon"] = { Name = "Haunted Castle", Position = Vector3.new(-9512, 160, 5548) },
        ["God Human"] = { Name = "Floating Turtle", Position = Vector3.new(-12164, 380, -8454) },
        ["Sanguine Art"] = { Name = "Tiki Outpost", Position = Vector3.new(-16200, 50, 450) },
    },
}

local function getFightingStyleFallback(styleName)
    local seaFallbacks = FightingStyleFallbackPositions[game.PlaceId]
    return seaFallbacks and seaFallbacks[styleName] or nil
end

-- Tool names used by the game can differ slightly from the UI labels.
local FightingStyleToolNames = {
    ["Dark Step"] = { "Black Leg", "Dark Step" },
    ["Electric"] = { "Electro", "Electric" },
    ["Water Kung Fu"] = { "Fishman Karate", "Water Kung Fu" },
    ["Dragon Breath"] = { "Dragon Breath", "Dragon Claw" },
    ["Superhuman"] = { "Superhuman" },
    ["Death Step"] = { "Death Step" },
    ["Sharkman Karate"] = { "Sharkman Karate" },
    ["Electric Claw"] = { "Electric Claw" },
    ["Dragon Talon"] = { "Dragon Talon" },
    ["God Human"] = { "Godhuman", "God Human" },
    ["Sanguine Art"] = { "Sanguine Art" },
}

local State = {
    FightingStyleEnabled = {},
}

local destroyed = false
local Callbacks = {
    Success = nil,
    Failed = nil,
    Notification = nil,
}

--========================================================
-- HELPERS
--========================================================

local function notify(message)
    if destroyed then
        return
    end

    message = tostring(message)

    if type(Callbacks.Notification) == "function" then
        pcall(Callbacks.Notification, message)
    else
        print("[LPT Hub Shop]", message)
    end
end

local function validItem(name)
    return type(name) == "string" and ShopConfig[name] ~= nil
end

local function getCharacter()
    if destroyed then
        return nil
    end

    return player.Character
end

local function getRoot(model)
    if not model then
        return nil
    end

    -- NPCs can have nested model structures, so search recursively too.
    return model:FindFirstChild("HumanoidRootPart", true)
        or model.PrimaryPart
end

local function normalizeName(name)
    return tostring(name or "")
        :lower()
        :gsub("[%p_]+", " ")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
        or ""
end

local function getRemote(name)
    if destroyed then
        return nil
    end

    refreshRemotes()

    if name == "BuyItem" then
        return BuyItemRemote
    elseif name == "RedeemCode" then
        return RedeemCodeRemote
    end

    return nil
end

local function getFightingStyleRemote()
    if destroyed then
        return nil
    end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        return nil
    end

    local remote = remotesFolder:FindFirstChild("CommF_")
        or remotesFolder:FindFirstChild("CommF")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function findFightingStyleTool(styleName)
    local aliases = FightingStyleToolNames[styleName] or { styleName }
    local character = getCharacter()
    local backpack = player:FindFirstChildOfClass("Backpack")

    for _, toolName in ipairs(aliases) do
        local tool = (character and character:FindFirstChild(toolName))
            or (backpack and backpack:FindFirstChild(toolName))

        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    return nil
end

local function invokeFightingStyleCommands(styleName)
    local remote = getFightingStyleRemote()
    local commands = FightingStyleCommands[styleName]

    if remote and commands then
        local lastResult = nil

        for _, args in ipairs(commands) do
            if destroyed then
                return false, "Module đã bị hủy"
            end

            local ok, result = pcall(function()
                return remote:InvokeServer(table.unpack(args))
            end)

            if not ok then
                return false, result
            end

            lastResult = result
            task.wait(0.15)
        end

        -- The game may return text instead of boolean true. Tool verification
        -- after this function determines whether equipping actually succeeded.
        return true, lastResult
    end

    -- Optional fallback for environments that provide the custom ShopRemotes.
    local shopRemote = getRemote("BuyItem")
    if shopRemote and shopRemote:IsA("RemoteFunction") then
        local ok, result = pcall(function()
            return shopRemote:InvokeServer(styleName, "Toggle", true)
        end)

        if ok then
            return true, result
        end

        return false, result
    end

    return false, "Không tìm thấy Remote mua võ (CommF_ hoặc ShopRemotes.BuyItem)"
end

--========================================================
-- FIND NPC MODEL
--========================================================

local function isNPCModel(obj)
    if not obj or not obj:IsA("Model") then
        return false
    end

    -- Use recursive lookups to support NPC rigs with nested models.
    local humanoid = obj:FindFirstChildWhichIsA("Humanoid", true)
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    return getRoot(obj) ~= nil
end

--========================================================
-- FIND FIGHTING STYLE NPC
--========================================================

function ShopModule:FindFightingStyleNPC(styleName, silent)
    if destroyed then
        return nil
    end

    local keywords = FightingStyleKeywords[styleName]
    if not keywords then
        if not silent then
            notify("Không có dữ liệu quét NPC cho: " .. tostring(styleName))
        end
        return nil
    end

    local character = getCharacter()
    local playerRoot = character and getRoot(character)
    if not playerRoot then
        if not silent then
            notify("Chưa tìm được nhân vật hoặc HumanoidRootPart của bạn")
        end
        return nil
    end

    local bestNPC = nil
    local bestScore = -math.huge
    local bestDistance = math.huge
    local scannedModels = 0
    local matchedNames = {}
    local matchedNameSet = {}

    local function scoreName(rawName)
        local normalized = normalizeName(rawName)
        local score = 0

        for _, keyword in ipairs(keywords) do
            local normalizedKeyword = normalizeName(keyword)
            if normalizedKeyword ~= "" then
                if normalized == normalizedKeyword then
                    score = math.max(score, 1000)
                elseif string.find(normalized, normalizedKeyword, 1, true) then
                    score = math.max(score, 600)
                end
            end
        end

        return score, normalized
    end

    local function findNPCAncestor(instance)
        local current = instance
        while current and current ~= workspace do
            if current:IsA("Model") and isNPCModel(current) then
                return current
            end
            current = current.Parent
        end
        return nil
    end

    local function considerCandidate(npc, score, matchedName)
        if matchedName and not matchedNameSet[matchedName] then
            matchedNameSet[matchedName] = true
            table.insert(matchedNames, matchedName)
        end

        if not npc then
            return
        end

        local npcRoot = getRoot(npc)
        if not npcRoot then
            return
        end

        local normalized = normalizeName(npc.Name)
        if string.find(normalized, "teacher", 1, true) then
            score += 100
        end

        local distance = (playerRoot.Position - npcRoot.Position).Magnitude
        if score > bestScore or (score == bestScore and distance < bestDistance) then
            bestNPC = npc
            bestScore = score
            bestDistance = distance
        end
    end

    -- Scan all currently replicated descendants. Match both Model names and
    -- overhead UI text, then climb to the nearest valid NPC rig. This handles
    -- nested rigs and NPCs whose visible name differs from the container name.
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            scannedModels += 1
        end

        local rawName = nil
        if obj:IsA("Model") then
            rawName = obj.Name
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            rawName = obj.Text
        end

        if rawName then
            local score = scoreName(rawName)
            if score > 0 then
                local npc = findNPCAncestor(obj)
                considerCandidate(npc, score, tostring(rawName))
            end
        end
    end

    if not bestNPC then
        if not silent then
            if #matchedNames > 0 then
                notify(
                    "Có tên khớp NPC " .. styleName
                    .. " nhưng không tìm được rig hợp lệ: "
                    .. table.concat(matchedNames, ", ")
                )
            else
                notify(
                    "Không tìm thấy NPC bán " .. styleName
                    .. " trong Workspace hiện tại (đã quét "
                    .. tostring(scannedModels) .. " Model)."
                    .. " Có thể NPC chưa tải, ở Sea khác, hoặc tên NPC không khớp."
                )
            end
        end
        return nil
    end

    notify(
        "Đã tìm thấy NPC " .. bestNPC.Name
        .. " (khoảng cách " .. tostring(math.floor(bestDistance)) .. ")"
    )

    return bestNPC
end

--========================================================
-- LONG-DISTANCE FLIGHT
--========================================================

local FLY_SPEED = 200

function ShopModule:FlyToPosition(destination, label, tolerance)
    if destroyed or typeof(destination) ~= "Vector3" then
        return false
    end

    local character = getCharacter()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not character or not root or not humanoid or humanoid.Health <= 0 then
        notify("Không thể bay: nhân vật chưa sẵn sàng")
        return false
    end

    tolerance = tolerance or 8
    local initialDistance = (root.Position - destination).Magnitude
    if initialDistance <= tolerance then
        return true
    end

    local deadline = os.clock() + math.max(initialDistance / FLY_SPEED * 2.5, 25)
    local cruiseY = math.max(root.Position.Y, destination.Y, 250) + 140
    local liftPoint = Vector3.new(root.Position.X, cruiseY, root.Position.Z)
    local cruisePoint = Vector3.new(destination.X, cruiseY, destination.Z)

    notify("Bay đường dài tới " .. tostring(label or "điểm đến")
        .. " • " .. tostring(math.floor(initialDistance)) .. " studs")

    local function moveLeg(target)
        while not destroyed and os.clock() < deadline do
            if player.Character ~= character
                or not root.Parent
                or humanoid.Health <= 0 then
                return false
            end

            local delta = target - root.Position
            local distance = delta.Magnitude
            if distance <= tolerance then
                return true
            end

            local dt = RunService.Heartbeat:Wait()
            if not dt or dt <= 0 then
                dt = 1 / 60
            end

            local step = math.min(distance, FLY_SPEED * dt)
            local nextPosition = root.Position + delta.Unit * step

            -- Preserve current rotation so the character doesn't spin wildly.
            root.CFrame = CFrame.new(nextPosition) * root.CFrame.Rotation
            root.AssemblyLinearVelocity = Vector3.zero
        end

        return false
    end

    if not moveLeg(liftPoint) then
        notify("Không thể rời vị trí hiện tại để bay tới " .. tostring(label or "điểm đến"))
        return false
    end

    if not moveLeg(cruisePoint) then
        notify("Không thể bay đường dài tới " .. tostring(label or "điểm đến"))
        return false
    end

    if not moveLeg(destination) then
        notify("Không thể hạ xuống tại " .. tostring(label or "điểm đến"))
        return false
    end

    return player.Character == character
        and root.Parent ~= nil
        and (root.Position - destination).Magnitude <= math.max(tolerance * 2, 16)
end

-- Final approach to the NPC. Re-read its live position because the NPC rig may
-- stream in after reaching the fallback landmark.
function ShopModule:FlyToNPC(npc)
    if destroyed or not npc or not npc.Parent then
        return false
    end

    local npcRoot = getRoot(npc)
    if not npcRoot then
        return false
    end

    local targetPosition = npcRoot.Position
        - npcRoot.CFrame.LookVector * 4
        + Vector3.new(0, 2, 0)

    local moved = self:FlyToPosition(targetPosition, npc.Name, 5)
    if not moved then
        return false
    end

    -- Confirm the NPC still exists and we actually arrived close enough.
    if not npc.Parent then
        return false
    end

    npcRoot = getRoot(npc)
    local character = getCharacter()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not npcRoot or not root then
        return false
    end

    return (root.Position - npcRoot.Position).Magnitude <= 12
end

--========================================================
-- INTERACT WITH NPC
--========================================================

function ShopModule:InteractNPC(npc)
    if destroyed or not npc or not npc.Parent then
        return false
    end

    -- Try a ProximityPrompt when the runtime supports it.
    for _, obj in ipairs(npc:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local triggered = false

            pcall(function()
                if type(fireproximityprompt) == "function" then
                    fireproximityprompt(obj)
                    triggered = true
                end
            end)

            if triggered then
                notify("Đã tương tác với " .. npc.Name)
                return true
            end
        end
    end

    -- Try a ClickDetector when supported.
    for _, obj in ipairs(npc:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local clicked = false

            pcall(function()
                if type(fireclickdetector) == "function" then
                    fireclickdetector(obj)
                    clicked = true
                end
            end)

            if clicked then
                notify("Đã click " .. npc.Name)
                return true
            end
        end
    end

    -- Some game versions handle these NPCs entirely through CommF_, so a
    -- missing prompt/click detector should not prevent the server request.
    return false
end

--========================================================
-- GET / EQUIP FIGHTING STYLE
--========================================================

function ShopModule:GetFightingStyle(styleName)
    if destroyed then
        return false
    end

    if not validItem(styleName) then
        notify("Unknown Fighting Style: " .. tostring(styleName))
        return false
    end

    if ShopConfig[styleName].Type ~= "Toggle" then
        notify("Không phải Fighting Style: " .. styleName)
        return false
    end

    if not FightingStyleCommands[styleName] then
        notify("Chưa có lệnh cho: " .. styleName)
        return false
    end

    -- First try the currently streamed world.
    local npc = self:FindFightingStyleNPC(styleName, true)

    -- If not present, move to the known region for the current Sea so Roblox
    -- has a chance to stream that island and NPC into Workspace.
    if not npc then
        local fallback = getFightingStyleFallback(styleName)
        if not fallback then
            notify(
                "Không có điểm dự phòng cho " .. styleName
                .. " ở Sea hiện tại (PlaceId " .. tostring(game.PlaceId) .. ")."
                .. " Hãy vào Sea có NPC này rồi bật lại."
            )
            return false
        end

        notify("NPC chưa được tải; đang bay tới khu vực " .. fallback.Name)
        if not self:FlyToPosition(fallback.Position, fallback.Name, 40) then
            return false
        end

        -- Give StreamingEnabled a moment, then rescan repeatedly.
        task.wait(1)
        for attempt = 1, 10 do
            if destroyed then
                return false
            end

            npc = self:FindFightingStyleNPC(styleName, true)
            if npc then
                break
            end

            task.wait(0.5)
        end
    end

    if not npc then
        notify(
            "Đã tới khu vực dự phòng nhưng chưa tìm thấy NPC " .. styleName
            .. ". Tọa độ khu vực có thể đã thay đổi hoặc NPC chưa được tải."
        )
        return false
    end

    notify("Tìm thấy NPC " .. npc.Name .. "; đang bay tới đúng vị trí")
    if not self:FlyToNPC(npc) then
        notify("Không thể tới gần NPC " .. npc.Name)
        return false
    end

    task.wait(0.25)
    self:InteractNPC(npc)
    task.wait(0.15)

    -- Buy/relearn through the game's normal server command. The game decides
    -- whether this is a first purchase or a re-equip of a previously learned style.
    local requestOK, requestResult = invokeFightingStyleCommands(styleName)
    if not requestOK then
        notify("Không thể gửi yêu cầu cho " .. styleName .. ": " .. tostring(requestResult))
        return false
    end

    -- Confirm that the fighting-style Tool appeared, then equip it.
    local deadline = os.clock() + 5
    repeat
        if destroyed then
            return false
        end

        local character = getCharacter()
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local tool = findFightingStyleTool(styleName)

        if tool and humanoid and character then
            local equipOK = pcall(function()
                humanoid:EquipTool(tool)
            end)

            if equipOK then
                task.wait(0.1)
                if tool.Parent == character then
                    return true
                end
            end
        end

        task.wait(0.1)
    until os.clock() >= deadline

    local resultText = type(requestResult) == "string" and requestResult or ""
    if resultText ~= "" then
        notify("Chưa xác nhận được " .. styleName .. ". Phản hồi: " .. resultText)
    else
        notify("Chưa xác nhận được " .. styleName .. ". Có thể thiếu tiền, điều kiện hoặc Remote đã thay đổi.")
    end

    return false
end

--========================================================
-- CALLBACKS
--========================================================

function ShopModule:SetCallback(name, callback)
    if destroyed or Callbacks[name] == nil then
        return false
    end

    if callback ~= nil and type(callback) ~= "function" then
        return false
    end

    Callbacks[name] = callback
    return true
end

--========================================================
-- GET ITEM CONFIG
--========================================================

function ShopModule:Get(name)
    if destroyed or not validItem(name) then
        return nil
    end

    local config = ShopConfig[name]
    local result = {}

    for key, value in pairs(config) do
        result[key] = value
    end

    if config.Type == "Toggle" then
        result.Enabled = State.FightingStyleEnabled[name] == true
    end

    return result
end

--========================================================
-- GET STATE
--========================================================

function ShopModule:GetState(name)
    if destroyed or not validItem(name) then
        return nil
    end

    if ShopConfig[name].Type ~= "Toggle" then
        return nil
    end

    return State.FightingStyleEnabled[name] == true
end

--========================================================
-- BUY ITEM BUTTON
--========================================================

function ShopModule:Buy(name)
    if destroyed then
        return false
    end

    if not validItem(name) then
        notify("Unknown item: " .. tostring(name))
        return false
    end

    local config = ShopConfig[name]
    if config.Type ~= "Button" then
        notify("Item này không phải Button: " .. name)
        return false
    end

    local remote = getRemote("BuyItem")
    if not remote then
        notify("BuyItem remote chưa sẵn sàng")
        return false
    end

    if not remote:IsA("RemoteFunction") then
        notify("BuyItem không phải RemoteFunction")
        return false
    end

    local success, result = pcall(function()
        return remote:InvokeServer(name)
    end)

    if not success then
        notify("Không thể gửi yêu cầu mua: " .. name)

        if type(Callbacks.Failed) == "function" then
            pcall(Callbacks.Failed, name)
        end

        return false
    end

    if result == true then
        notify("Mua thành công: " .. name)

        if type(Callbacks.Success) == "function" then
            pcall(Callbacks.Success, name)
        end

        return true
    end

    notify("Mua thất bại: " .. name)
    if type(Callbacks.Failed) == "function" then
        pcall(Callbacks.Failed, name, result)
    end

    return false
end

--========================================================
-- SET FIGHTING STYLE TOGGLE
--========================================================

function ShopModule:Set(name, enabled)
    if destroyed then
        return false
    end

    if not validItem(name) or ShopConfig[name].Type ~= "Toggle" then
        return false
    end

    enabled = enabled == true

    if not enabled then
        State.FightingStyleEnabled[name] = false
        notify("Đã tắt: " .. name)
        return true
    end

    if State.FightingStyleEnabled[name] == true then
        return true
    end

    local styleSuccess = self:GetFightingStyle(name)
    if not styleSuccess then
        State.FightingStyleEnabled[name] = false

        if type(Callbacks.Failed) == "function" then
            pcall(Callbacks.Failed, name)
        end

        return false
    end

    -- Only one fighting style can be equipped at a time, so keep the UI state
    -- consistent with the style that was successfully equipped.
    for styleName in pairs(FightingStyleKeywords) do
        State.FightingStyleEnabled[styleName] = styleName == name
    end

    notify("Đã trang bị: " .. name)
    if type(Callbacks.Success) == "function" then
        pcall(Callbacks.Success, name)
    end

    return true
end

--========================================================
-- TOGGLE FIGHTING STYLE
--========================================================

function ShopModule:Toggle(name)
    if destroyed or not validItem(name) then
        return false
    end

    if ShopConfig[name].Type ~= "Toggle" then
        return false
    end

    local current = State.FightingStyleEnabled[name] == true
    return self:Set(name, not current)
end

--========================================================
-- REDEEM CODE
--========================================================

local RedeemCodes = {
    "EASTEREXP",
    "KITT_RESET",
    "SUB2GAMERROBOT_EXP1",
    "SUB2GAMERROBOT_RESET1",
    "Bluxxy",
    "Sub2UncleKizaru",
    "Bignews",
    "Enyu_is_Pro",
    "JCWK",
    "Kittgaming",
    "Magicbus",
    "Starcodeheo",
    "StrawHatMaine",
    "Sub2CaptainMaui",
    "Sub2Daigrock",
    "Sub2Fer999",
    "Sub2NoobMaster123",
    "Sub2OfficialNoobie",
    "TantaiGaming",
    "TheGreatAce",
    "Axiore",
    "Chandler",
    "Fudd10",
    "Fudd10_v2",
}

function ShopModule:RedeemCode()
    if destroyed then
        return false
    end

    local remote = getRemote("RedeemCode")
    if not remote or not remote:IsA("RemoteFunction") then
        notify("RedeemCode remote chưa sẵn sàng")
        return false
    end

    local anySuccess = false

    for _, code in ipairs(RedeemCodes) do
        if destroyed then
            break
        end

        local success, result = pcall(function()
            return remote:InvokeServer(code)
        end)

        if success and result == true then
            anySuccess = true
        end

        task.wait(0.15)
    end

    if anySuccess then
        notify("Đã đổi được ít nhất một code")
    else
        notify("Không đổi được code nào; có thể code đã hết hạn hoặc đã dùng")
    end

    return anySuccess
end

--========================================================
-- GET ALL ITEMS
--========================================================

function ShopModule:GetAll()
    if destroyed then
        return {}
    end

    local result = {}
    for name in pairs(ShopConfig) do
        result[name] = self:Get(name)
    end

    return result
end

--========================================================
-- DESTROY
--========================================================

function ShopModule:Destroy()
    if destroyed then
        return
    end

    destroyed = true

    BuyItemRemote = nil
    RedeemCodeRemote = nil

    table.clear(State.FightingStyleEnabled)

    for key in pairs(Callbacks) do
        Callbacks[key] = nil
    end
end

return ShopModule
