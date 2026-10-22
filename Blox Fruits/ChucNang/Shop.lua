local ShopModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local FLY_SPEED = 172

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
    ["NoClip"] = { Type = "Toggle" },

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

local FightingStyleFallbackPositions = {
    -- Blox Fruits First Sea
    [2753915549] = {
        ["Dark Step"] = { Name = "Pirate Village", Position = Vector3.new(-1152, 25, 3826) },
        ["Electric"] = { Name = "lower Skylands", Position = Vector3.new(-4851, 400, -2561) },
        ["Water Kung Fu"] = { Name = "Underwater City", Position = Vector3.new(61000, 25, 1800) },
    },

    [4442272183] = {
        ["Dark Step"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Electric"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Water Kung Fu"] = { Name = "Hot and Cold", Position = Vector3.new(-6224, 60, -4902) },
        ["Dragon Breath"] = { Name = "Kingdom of Rose", Position = Vector3.new(-2247, 100, -1671) },
        ["Superhuman"] = { Name = "Snow Mountain", Position = Vector3.new(609, 400, -5258) },
        ["Death Step"] = { Name = "Ice Castle", Position = Vector3.new(6170, 290, -6734) },
        ["Sharkman Karate"] = { Name = "Forgotten Island", Position = Vector3.new(-3053, 240, -10112) },
    },

    [7449423635] = {
        ["Dark Step"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Electric"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Water Kung Fu"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Dragon Breath"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Superhuman"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Death Step"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Sharkman Karate"] = { Name = "Castle on the Sea", Position = Vector3.new(-5097, 330, -3177) },
        ["Electric Claw"] = { Name = "Floating Turtle", Position = Vector3.new(-12164, 380, -8454) },
        ["Dragon Talon"] = { Name = "Hydra Island - Dragon Dojo", Position = Vector3.new(5660, 610, -280) },
        ["God Human"] = { Name = "Floating Turtle", Position = Vector3.new(-12164, 380, -8454) },
        ["Sanguine Art"] = { Name = "Tiki Outpost", Position = Vector3.new(-16200, 50, 450) },
    },
}

local function getFightingStyleFallback(styleName)
    local seaFallbacks = FightingStyleFallbackPositions[game.PlaceId]
    return seaFallbacks and seaFallbacks[styleName] or nil
end


local ThirdSeaPortalRoutes = {
    ["Castle on the Sea"] = {
        IslandCenter = Vector3.new(-5097, 315, -3130),
        Entrance = Vector3.new(-5092, 315, -3130),
    },
    ["Floating Turtle"] = {
        IslandCenter = Vector3.new(-12164, 380, -8454),
        Entrance = Vector3.new(-12471.17, 374.94, -7551.68),
    },
    ["Hydra Island"] = {
        IslandCenter = Vector3.new(5229, 610, 345),
        Entrance = Vector3.new(5756, 610, -282),
    },
    ["Tiki Outpost"] = {
        IslandCenter = Vector3.new(-16500, 50, 450),
        Entrance = Vector3.new(-16218.68, 9.09, 445.62),
    },
}

local ThirdSeaStyleDestinations = {
    ["Dark Step"] = "Castle on the Sea",
    ["Electric"] = "Castle on the Sea",
    ["Water Kung Fu"] = "Castle on the Sea",
    ["Dragon Breath"] = "Castle on the Sea",
    ["Superhuman"] = "Castle on the Sea",
    ["Death Step"] = "Castle on the Sea",
    ["Sharkman Karate"] = "Castle on the Sea",
    ["Electric Claw"] = "Floating Turtle",
    ["Dragon Talon"] = "Hydra Island",
    ["God Human"] = "Floating Turtle",
    ["Sanguine Art"] = "Tiki Outpost",
}

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
    FightingStyleNPCs = {},
    TriangleOrbitTokens = {},
    NoClipEnabled = false,
}

local noClipConnection = nil
local noClipDescendantConnection = nil
local noClipCharacter = nil
local noClipOriginalCollisions = {}

local function restoreNoClipCollisions()
    if noClipDescendantConnection then
        noClipDescendantConnection:Disconnect()
        noClipDescendantConnection = nil
    end

    for part, originalCanCollide in pairs(noClipOriginalCollisions) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = originalCanCollide
            end)
        end
    end

    table.clear(noClipOriginalCollisions)
    noClipCharacter = nil
end

local function applyNoClipToPart(object)
    if not object or not object:IsA("BasePart") then
        return
    end

    if noClipOriginalCollisions[object] == nil then
        noClipOriginalCollisions[object] = object.CanCollide
    end

    if object.CanCollide then
        object.CanCollide = false
    end
end

local function applyNoClipToCharacter()
    local character = player.Character

    if character ~= noClipCharacter then
        restoreNoClipCollisions()
        noClipCharacter = character

        -- Newly added body parts/accessory handles are made non-collidable immediately,
        -- without waiting for the next Stepped update.
        if character then
            noClipDescendantConnection = character.DescendantAdded:Connect(function(object)
                if not State.NoClipEnabled or player.Character ~= character then
                    return
                end

                local ok, err = pcall(applyNoClipToPart, object)
                if not ok then
                    warn("[LPT Hub Shop] NoClip descendant error: " .. tostring(err))
                end
            end)
        end
    end

    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        applyNoClipToPart(object)
    end
end

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

local function getCurrentRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function waitForIslandTransition(route, startPosition, timeout, label)
    local deadline = os.clock() + (timeout or 4)

    repeat
        if destroyed then
            return false
        end

        local root = getCurrentRoot()
        if root then
            local distanceToDestination = (root.Position - route.IslandCenter).Magnitude
            local displacement = (root.Position - startPosition).Magnitude

            if distanceToDestination <= 1450 and displacement >= 250 then
                notify("Đã vào khu vực " .. tostring(label or route.Name or "đích đến") .. " bằng cổng trong game")
                task.wait(0.35)
                return true
            end
        end

        task.wait(0.1)
    until os.clock() >= deadline

    return false
end

local function moveThroughPhysicalPortal(module, portalPosition, portalLabel, destinationRoute, destinationName)
    if destroyed or not portalPosition or not destinationRoute then
        return false
    end

    local root = getCurrentRoot()
    if not root then
        return false
    end

    local startPosition = root.Position
    if not module:FlyToPosition(portalPosition, portalLabel, 2) then
        return false
    end

    local character = getCharacter()
    root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        module:FlyToPosition(portalPosition + Vector3.new(0, 3, 0), portalLabel, 2)
    end

    if waitForIslandTransition(destinationRoute, startPosition, 3.5, destinationName) then
        return true
    end

    notify("Đã tới " .. portalLabel .. " nhưng cổng chưa dịch chuyển; có thể chưa mở khóa hoặc điểm vào đã đổi")
    return false
end

local PortalDestinationKeywords = {
    ["Floating Turtle"] = { "mansion", "floating turtle" },
    ["Hydra Island"] = { "hydra" },
    ["Tiki Outpost"] = { "tiki" },
}

local function getPortalMetadata(instance)
    local pieces = {}
    local current = instance
    local portalRoot = nil

    for _ = 1, 5 do
        if not current or current == workspace then
            break
        end

        table.insert(pieces, tostring(current.Name or ""))
        local lowerName = normalizeName(current.Name)
        if not portalRoot and (string.find(lowerName, "portal", 1, true)
            or string.find(lowerName, "indra", 1, true)) then
            portalRoot = current
        end
        current = current.Parent
    end

    if portalRoot and portalRoot:IsA("BasePart") then
        local ancestorModel = portalRoot:FindFirstAncestorOfClass("Model")
        if ancestorModel then
            portalRoot = ancestorModel
        end
    end

    if portalRoot and portalRoot:IsA("Model") then
        for _, descendant in ipairs(portalRoot:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                if descendant.Text and descendant.Text ~= "" then
                    table.insert(pieces, descendant.Text)
                end
            end
        end
    end

    return normalizeName(table.concat(pieces, " ")), portalRoot
end

local function findCastlePortalFor(destinationName)
    local keywords = PortalDestinationKeywords[destinationName]
    if not keywords then
        return nil
    end

    local castleCenter = ThirdSeaPortalRoutes["Castle on the Sea"].IslandCenter
    local bestPosition = nil
    local bestDistance = math.huge
    local seenRoots = {}

    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("BasePart") or instance:IsA("Model") then
            local position
            if instance:IsA("BasePart") then
                position = instance.Position
            else
                position = instance:GetPivot().Position
            end

            if (position - castleCenter).Magnitude <= 1450 then
                local metadata, portalRoot = getPortalMetadata(instance)
                local isPortal = string.find(metadata, "portal", 1, true)
                    or string.find(metadata, "indra", 1, true)

                if isPortal then
                    local matchesDestination = false
                    for _, keyword in ipairs(keywords) do
                        if string.find(metadata, normalizeName(keyword), 1, true) then
                            matchesDestination = true
                            break
                        end
                    end

                    if matchesDestination then
                        local candidate = portalRoot or instance
                        if not seenRoots[candidate] then
                            seenRoots[candidate] = true
                            local candidatePosition
                            if candidate:IsA("BasePart") then
                                candidatePosition = candidate.Position
                            elseif candidate:IsA("Model") then
                                candidatePosition = candidate:GetPivot().Position
                            end

                            if candidatePosition then
                                local distance = (candidatePosition - castleCenter).Magnitude
                                if distance < bestDistance then
                                    bestDistance = distance
                                    bestPosition = candidatePosition
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPosition
end

local function tryFirstSeaUnderwaterEntrance(module, styleName)
    if destroyed or game.PlaceId ~= 2753915549 or styleName ~= "Water Kung Fu" then
        return nil
    end

    local underwaterCity = Vector3.new(61163.85, 11.68, 1819.78)
    local root = getCurrentRoot()
    if not root then
        notify("Chưa tìm được nhân vật để đi tới Underwater City")
        return false
    end

    if (root.Position - underwaterCity).Magnitude <= 2600 then
        return true
    end

    local whirlpoolFallback = Vector3.new(3865, 5, -1926)
    local whirlpoolPosition = nil
    local bestDistance = math.huge

    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("BasePart") or instance:IsA("Model") then
            local normalized = normalizeName(instance.Name)
            if string.find(normalized, "whirlpool", 1, true) then
                local position = instance:IsA("BasePart") and instance.Position
                    or instance:GetPivot().Position
                local distance = (position - whirlpoolFallback).Magnitude
                if distance < bestDistance and distance <= 1800 then
                    bestDistance = distance
                    whirlpoolPosition = position
                end
            end
        end
    end

    whirlpoolPosition = whirlpoolPosition or whirlpoolFallback
    notify("Đang tới xoáy nước vào Underwater City")

    if not module:FlyToPosition(whirlpoolPosition, "Whirlpool — Underwater City", 3) then
        return false
    end

    local deadline = os.clock() + 5
    repeat
        if destroyed then
            return false
        end

        root = getCurrentRoot()
        if root and (root.Position - underwaterCity).Magnitude <= 2600 then
            notify("Đã vào Underwater City qua xoáy nước")
            task.wait(0.35)
            return true
        end

        task.wait(0.1)
    until os.clock() >= deadline

    notify("Đã tới xoáy nước nhưng chưa được đưa vào Underwater City. Hãy kiểm tra vị trí xoáy nước trong game hoặc điều kiện khu vực.")
    return false
end

local function tryThirdSeaPhysicalPortal(module, styleName)
    if destroyed or game.PlaceId ~= 7449423635 then
        return false
    end

    local destinationName = ThirdSeaStyleDestinations[styleName]
    local destinationRoute = destinationName and ThirdSeaPortalRoutes[destinationName]
    if not destinationRoute then
        return false
    end

    local root = getCurrentRoot()
    if not root then
        return false
    end

    local targetDistance = (root.Position - destinationRoute.IslandCenter).Magnitude
    if targetDistance <= 1100 then
        return false
    end

    local castleRoute = ThirdSeaPortalRoutes["Castle on the Sea"]
    local returnPortals = {
        {
            Name = "Mansion Portal",
            Island = "Floating Turtle",
            Position = ThirdSeaPortalRoutes["Floating Turtle"].Entrance,
        },
        {
            Name = "Hydra Island Portal",
            Island = "Hydra Island",
            Position = ThirdSeaPortalRoutes["Hydra Island"].Entrance,
        },
        {
            Name = "Tiki Outpost Portal",
            Island = "Tiki Outpost",
            Position = ThirdSeaPortalRoutes["Tiki Outpost"].Entrance,
        },
    }

    local function nearestReturnPortal(position)
        local selected = nil
        local distance = math.huge
        for _, portal in ipairs(returnPortals) do
            local currentDistance = (position - portal.Position).Magnitude
            if currentDistance < distance then
                distance = currentDistance
                selected = portal
            end
        end
        return selected, distance
    end

    local function tryFromCastleToDestination()
        local portalPosition = findCastlePortalFor(destinationName)
        if not portalPosition then
            notify("Chưa nhận diện được cổng đi tới " .. destinationName .. " ở Castle on the Sea; sẽ dùng đường bay thẳng nếu cần")
            return false
        end

        return moveThroughPhysicalPortal(
            module,
            portalPosition,
            "Portal tới " .. destinationName,
            destinationRoute,
            destinationName
        )
    end

    if destinationName == "Castle on the Sea" then
        local portal, portalDistance = nearestReturnPortal(root.Position)
        if portal and portalDistance + 500 < targetDistance then
            return moveThroughPhysicalPortal(
                module,
                portal.Position,
                portal.Name,
                castleRoute,
                "Castle on the Sea"
            )
        end
        return false
    end

    if (root.Position - castleRoute.IslandCenter).Magnitude <= 1450 then
        return tryFromCastleToDestination()
    end

    local portal, portalDistance = nearestReturnPortal(root.Position)
    if not portal or portalDistance + 1200 >= targetDistance then
        return false
    end

    local reachedCastle = moveThroughPhysicalPortal(
        module,
        portal.Position,
        portal.Name,
        castleRoute,
        "Castle on the Sea"
    )
    if not reachedCastle then
        return false
    end

    task.wait(0.35)
    return tryFromCastleToDestination()
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

        return true, lastResult
    end

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

    if not silent then
        notify(
            "Đã tìm thấy NPC " .. bestNPC.Name
            .. " (khoảng cách " .. tostring(math.floor(bestDistance)) .. ")"
        )
    end

    return bestNPC
end

--========================================================
-- DIRECT FLIGHT (SHORTEST STRAIGHT-LINE ROUTE)
--========================================================

function ShopModule:FlyToPosition(destination, label, tolerance, shouldCancel, speedOverride, suppressNotification)
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

    local function cancelled()
        return type(shouldCancel) == "function" and shouldCancel() == true
    end

    if cancelled() then
        return false
    end

    tolerance = tolerance or 8
    local initialDistance = (root.Position - destination).Magnitude
    if initialDistance <= tolerance then
        return true
    end

    local moveSpeed = (type(speedOverride) == "number" and speedOverride > 0) and speedOverride or FLY_SPEED
    local deadline = os.clock() + math.max(initialDistance / moveSpeed * 2.5, 20)
    if not suppressNotification then
        notify("Bay thẳng tới " .. tostring(label or "điểm đến")
            .. " • " .. tostring(math.floor(initialDistance)) .. " studs")
    end

    while not destroyed and not cancelled() and os.clock() < deadline do
        if player.Character ~= character
            or not root.Parent
            or humanoid.Health <= 0 then
            return false
        end

        local delta = destination - root.Position
        local distance = delta.Magnitude
        if distance <= tolerance then
            return true
        end

        local dt = RunService.Heartbeat:Wait()
        if cancelled() then
            return false
        end
        if not dt or dt <= 0 then
            dt = 1 / 60
        end

        -- Recheck after yielding; the character may have respawned during Heartbeat.
        if player.Character ~= character or not root.Parent or humanoid.Health <= 0 then
            return false
        end

        local step = math.min(distance, moveSpeed * dt)
        local nextPosition = root.Position + delta.Unit * step

        root.CFrame = CFrame.new(nextPosition) * root.CFrame.Rotation
        root.AssemblyLinearVelocity = Vector3.zero
    end

    if not destroyed and not cancelled() and not suppressNotification then
        notify("Hết thời gian di chuyển tới " .. tostring(label or "điểm đến"))
    end

    return not destroyed
        and not cancelled()
        and player.Character == character
        and root.Parent ~= nil
        and (root.Position - destination).Magnitude <= math.max(tolerance * 2, 16)
end

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

-- Fly toward the island landmark only while the NPC is not yet streamed in.
-- During the flight, periodically rescan Workspace; if the NPC appears, cancel
-- the landmark route and return the NPC so the caller can fly directly to it.
function ShopModule:FlyToFallbackOrNPC(styleName, fallback)
    if destroyed or type(fallback) ~= "table" or typeof(fallback.Position) ~= "Vector3" then
        return nil
    end

    local foundNPC = nil
    local lastScan = 0
    local scanInterval = 0.45

    local function scanForNPC(force)
        if foundNPC and foundNPC.Parent then
            return foundNPC
        end

        local now = os.clock()
        if force or now - lastScan >= scanInterval then
            lastScan = now
            local candidate = self:FindFightingStyleNPC(styleName, true)
            if candidate and candidate.Parent then
                foundNPC = candidate
            end
        end

        return foundNPC
    end

    local function shouldCancelRoute()
        if destroyed then
            return true
        end
        return scanForNPC(false) ~= nil
    end

    notify("Chưa thấy NPC " .. styleName .. "; đang bay về khu vực " .. fallback.Name .. " và quét NPC trên đường")
    self:FlyToPosition(fallback.Position, fallback.Name, 40, shouldCancelRoute)

    if destroyed then
        return nil
    end

    -- If the NPC streamed in while flying, do not continue toward the landmark.
    local npc = scanForNPC(true)
    if npc and npc.Parent then
        notify("Đã phát hiện " .. npc.Name .. " trên đường; đổi hướng bay thẳng tới NPC")
        return npc
    end

    -- On arrival, allow StreamingEnabled a short period to replicate the NPC.
    for attempt = 1, 16 do
        if destroyed then
            return nil
        end

        npc = scanForNPC(false)
        if npc and npc.Parent then
            notify("Đã tải NPC " .. npc.Name .. " gần " .. fallback.Name .. "; đang bay thẳng tới NPC")
            return npc
        end

        task.wait(0.35)
    end

    return nil
end

function ShopModule:StartTriangleOrbit(styleName, npc)
    if destroyed or not npc or not npc.Parent then
        return false
    end

    local npcRoot = getRoot(npc)
    local character = getCharacter()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not npcRoot or not root then
        return false
    end

    State.TriangleOrbitTokens[styleName] = (State.TriangleOrbitTokens[styleName] or 0) + 1
    local token = State.TriangleOrbitTokens[styleName]
    local orbitRadius = 6
    local orbitSpeed = 55 -- Slower than the long-distance flight speed, so each side is visible.
    local offset = root.Position - npcRoot.Position
    local startAngle = math.atan2(offset.Z, offset.X)

    -- The token is the authoritative stop signal. Set(false) and switching to
    -- another style both increment it; relying on the UI/state flag here can
    -- stop the orbit prematurely if that flag is refreshed externally.
    local function shouldStop()
        return destroyed
            or State.TriangleOrbitTokens[styleName] ~= token
            or not npc.Parent
    end

    task.spawn(function()
        notify("Đang bay tam giác liên tục quanh " .. npc.Name .. " (bán kính 6 studs). Tắt " .. styleName .. " để dừng.")
        local vertexIndex = 0

        while not shouldStop() do
            npcRoot = getRoot(npc)
            character = getCharacter()
            root = character and character:FindFirstChild("HumanoidRootPart")

            if not npcRoot or not root or not root.Parent then
                task.wait(0.15)
            else
                local angle = startAngle + (vertexIndex * 2 * math.pi / 3)
                local center = npcRoot.Position
                local destination = Vector3.new(
                    center.X + math.cos(angle) * orbitRadius,
                    center.Y + 2,
                    center.Z + math.sin(angle) * orbitRadius
                )

                -- Protect the orbit worker from a transient character/root error;
                -- retry the same vertex instead of silently killing the whole loop.
                local callOK, moved = pcall(function()
                    return self:FlyToPosition(
                        destination,
                        "tam giác quanh " .. npc.Name,
                        1.5,
                        shouldStop,
                        orbitSpeed,
                        true -- Avoid a notification for every triangle edge.
                    )
                end)

                if shouldStop() then
                    break
                end

                if callOK and moved then
                    vertexIndex = (vertexIndex + 1) % 3
                    task.wait(0.03)
                else
                    task.wait(0.1)
                end
            end
        end

        if not destroyed then
            notify("Đã dừng bay tam giác quanh " .. npc.Name)
        end
    end)

    return true
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

    local underwaterRouteResult = tryFirstSeaUnderwaterEntrance(self, styleName)
    if underwaterRouteResult == false then
        return false
    end

    tryThirdSeaPhysicalPortal(self, styleName)

    local npc = self:FindFightingStyleNPC(styleName, true)

    if not npc then
        for attempt = 1, 5 do
            if destroyed then
                return false
            end

            task.wait(0.3)
            npc = self:FindFightingStyleNPC(styleName, true)
            if npc then
                break
            end
        end
    end

    if not npc then
        local fallback = getFightingStyleFallback(styleName)
        if not fallback then
            notify(
                "Không có tọa độ khu vực dự phòng cho " .. styleName
                .. " ở Sea hiện tại (PlaceId " .. tostring(game.PlaceId) .. ")."
                .. " Hãy vào Sea có NPC này rồi bật lại."
            )
            return false
        end

        -- This route is only a fallback for StreamingEnabled: if the NPC appears
        -- before reaching the landmark, immediately redirect to the NPC instead.
        npc = self:FlyToFallbackOrNPC(styleName, fallback)
        if not npc then
            notify(
                "Đã kiểm tra khu vực " .. fallback.Name .. " nhưng chưa tìm thấy NPC "
                .. styleName .. ". NPC có thể chưa tải hoặc tọa độ khu vực đã thay đổi."
            )
            return false
        end
    end

    State.FightingStyleNPCs[styleName] = npc
    notify("Tìm thấy NPC " .. npc.Name .. "; đang bay thẳng tới NPC")
    if not self:FlyToNPC(npc) then
        State.FightingStyleNPCs[styleName] = nil
        notify("Không thể tới gần NPC " .. npc.Name)
        return false
    end

    task.wait(0.25)
    self:InteractNPC(npc)
    task.wait(0.15)

    local requestOK, requestResult = invokeFightingStyleCommands(styleName)
    if not requestOK then
        notify("Không thể gửi yêu cầu cho " .. styleName .. ": " .. tostring(requestResult))
        return false
    end

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
        if name == "NoClip" then
            result.Enabled = State.NoClipEnabled == true
        else
            result.Enabled = State.FightingStyleEnabled[name] == true
        end
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

    if name == "NoClip" then
        return State.NoClipEnabled == true
    end

    return State.FightingStyleEnabled[name] == true
end

--========================================================
-- NOCLIP TOGGLE
--========================================================

function ShopModule:SetNoClip(enabled)
    if destroyed then
        return false
    end

    enabled = enabled == true

    if enabled then
        State.NoClipEnabled = true

        if not noClipConnection then
            noClipConnection = RunService.Stepped:Connect(function()
                if destroyed or not State.NoClipEnabled then
                    return
                end

                local ok, err = pcall(applyNoClipToCharacter)
                if not ok then
                    warn("[LPT Hub Shop] NoClip error: " .. tostring(err))
                end
            end)
        end

        local ok, err = pcall(applyNoClipToCharacter)
        if not ok then
            State.NoClipEnabled = false
            if noClipConnection then
                noClipConnection:Disconnect()
                noClipConnection = nil
            end
            restoreNoClipCollisions()
            notify("Không thể bật NoClip: " .. tostring(err))
            return false
        end

        notify("NoClip đã bật: nhân vật có thể đi xuyên vật cản")
        return true
    end

    State.NoClipEnabled = false

    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end

    restoreNoClipCollisions()
    notify("NoClip đã tắt; va chạm ban đầu đã được khôi phục")
    return true
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

    if name == "NoClip" then
        return self:SetNoClip(enabled)
    end

    if not enabled then
        State.FightingStyleEnabled[name] = false
        State.TriangleOrbitTokens[name] = (State.TriangleOrbitTokens[name] or 0) + 1
        State.FightingStyleNPCs[name] = nil
        notify("Đã tắt: " .. name .. " (đã dừng bay tam giác)")
        return true
    end

    if State.FightingStyleEnabled[name] == true then
        return true
    end

    for otherStyle in pairs(FightingStyleKeywords) do
        if otherStyle ~= name then
            State.FightingStyleEnabled[otherStyle] = false
            State.TriangleOrbitTokens[otherStyle] = (State.TriangleOrbitTokens[otherStyle] or 0) + 1
            State.FightingStyleNPCs[otherStyle] = nil
        end
    end

    local styleSuccess = self:GetFightingStyle(name)
    if not styleSuccess then
        State.FightingStyleEnabled[name] = false

        if type(Callbacks.Failed) == "function" then
            pcall(Callbacks.Failed, name)
        end

        return false
    end

    for styleName in pairs(FightingStyleKeywords) do
        State.FightingStyleEnabled[styleName] = styleName == name
        if styleName ~= name then
            State.TriangleOrbitTokens[styleName] = (State.TriangleOrbitTokens[styleName] or 0) + 1
            State.FightingStyleNPCs[styleName] = nil
        end
    end

    local orbitNPC = State.FightingStyleNPCs[name]
    if orbitNPC and orbitNPC.Parent then
        self:StartTriangleOrbit(name, orbitNPC)
    else
        notify("Đã trang bị " .. name .. " nhưng không có NPC hợp lệ để bay vòng")
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

    local current = self:GetState(name) == true
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

    State.NoClipEnabled = false
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
    restoreNoClipCollisions()

    destroyed = true

    BuyItemRemote = nil
    RedeemCodeRemote = nil

    table.clear(State.FightingStyleEnabled)
    table.clear(State.FightingStyleNPCs)
    table.clear(State.TriangleOrbitTokens)

    for key in pairs(Callbacks) do
        Callbacks[key] = nil
    end
end

return ShopModule
