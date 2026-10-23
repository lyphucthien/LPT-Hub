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
    [85211729168715] = {
        ["Dark Step"] = {
            Name = "Dark Step Teacher",
            Position = Vector3.new(-990.73, 26.03, 4025.69),
        },
        ["Electric"] = {
            Name = "Mad Scientist",
            Position = Vector3.new(-4628.89, 12.13, -355.72),
        },
        ["Water Kung Fu"] = {
            Name = "Water Kung-fu Teacher",
            Position = Vector3.new(61715.23, 53.00, 871.93),
        },
        ["Dragon Breath"] = {
            Name = "Sabi",
            Position = Vector3.new(699.03, 185.66, 654.90),
        },
        ["Superhuman"] = {
            Name = "Martial Arts Master",
            Position = Vector3.new(1377.12, 246.54, -5189.95),
        },
        ["Death Step"] = {
            Name = "Phoeyu, the Reformed",
            Position = Vector3.new(6356.47, 296.10, -6762.77),
        },
        ["Sharkman Karate"] = {
            Name = "Sharkman Teacher",
            Position = Vector3.new(-2599.62, 238.20, -10316.00),
        },
        ["Electric Claw"] = {
            Name = "Previous Hero",
            Position = Vector3.new(-10371.47, 330.76, -10131.42),
        },
        ["Dragon Talon"] = {
            Name = "Uzoth",
            Position = Vector3.new(5661.90, 1210.88, 863.18),
        },
        ["God Human"] = {
            Name = "Ancient Monk",
            Position = Vector3.new(-13774.09, 333.73, -9879.91),
        },
        ["Sanguine Art"] = {
            Name = "Shafi",
            Position = Vector3.new(-16515.07, 22.81, -188.57),
        },
    },
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
    FightingStyleTargets = {},
    TriangleOrbitTokens = {},
    TriangleOrbitNPCs = {},
    StyleOperationTokens = {},
    ActiveFightingStyle = nil,
    NoClipEnabled = false,
}

local function isValidFightingStyleTarget(target)
    if typeof(target) == "Vector3" then
        return true
    end

    return typeof(target) == "Instance"
        and target.Parent ~= nil
end

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
    StateChanged = nil,
}

--========================================================
-- HELPERS
--========================================================

local notify
local shouldCancelOperation

notify = function(message)
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

shouldCancelOperation = function(callback)
    if destroyed then
        return true
    end

    if type(callback) == "function" then
        local ok, result = pcall(callback)
        return not ok or result == true
    end

    return false
end

local function publishFightingStyleStates()
    if type(Callbacks.StateChanged) ~= "function" then
        return
    end

    for styleName in pairs(FightingStyleKeywords) do
        pcall(
            Callbacks.StateChanged,
            styleName,
            State.FightingStyleEnabled[styleName] == true
        )
    end
end

local function invalidateStyleOperation(styleName)
    State.StyleOperationTokens[styleName] = (State.StyleOperationTokens[styleName] or 0) + 1
    State.TriangleOrbitTokens[styleName] = (State.TriangleOrbitTokens[styleName] or 0) + 1
    State.TriangleOrbitNPCs[styleName] = nil
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

local function waitForIslandTransition(route, startPosition, timeout, label, shouldCancel)
    local deadline = os.clock() + (timeout or 4)

    repeat
        if shouldCancelOperation(shouldCancel) then
            return false
        end

        local root = getCurrentRoot()
        if root then
            local distanceToDestination = (root.Position - route.IslandCenter).Magnitude
            local displacement = (root.Position - startPosition).Magnitude

            if distanceToDestination <= 1450 and displacement >= 250 then
                notify("Đã vào khu vực " .. tostring(label or route.Name or "đích đến") .. " bằng cổng trong game")
                task.wait(0.35)
                return not shouldCancelOperation(shouldCancel)
            end
        end

        task.wait(0.1)
    until os.clock() >= deadline

    return false
end

local function moveThroughPhysicalPortal(module, portalPosition, portalLabel, destinationRoute, destinationName, shouldCancel)
    if shouldCancelOperation(shouldCancel) or not portalPosition or not destinationRoute then
        return false
    end

    local root = getCurrentRoot()
    if not root then
        return false
    end

    local startPosition = root.Position
    if not module:FlyToPosition(portalPosition, portalLabel, 2, shouldCancel) then
        return false
    end

    if shouldCancelOperation(shouldCancel) then
        return false
    end

    local character = getCharacter()
    root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        if not module:FlyToPosition(portalPosition + Vector3.new(0, 3, 0), portalLabel, 2, shouldCancel) then
            return false
        end
    end

    if shouldCancelOperation(shouldCancel) then
        return false
    end

    if waitForIslandTransition(destinationRoute, startPosition, 3.5, destinationName, shouldCancel) then
        return true
    end

    if not shouldCancelOperation(shouldCancel) then
        notify("Đã tới " .. portalLabel .. " nhưng cổng chưa dịch chuyển; có thể chưa mở khóa hoặc điểm vào đã đổi")
    end
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
        if not portalRoot and (
            string.find(lowerName, "portal", 1, true)
            or string.find(lowerName, "indra", 1, true)
            or lowerName == "entrance"
        ) then
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

local function findWhirlpoolEntrancePart()
    local reference = Vector3.new(3865, 5, -1926)
    local bestPart = nil
    local bestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Entrance" then
            local distance = (obj.Position - reference).Magnitude

            if distance < bestDistance then
                bestDistance = distance
                bestPart = obj
            end
        end
    end

    if bestPart then
        print(string.format(
            "[LPT WHIRLPOOL] Entrance thật: (%.2f, %.2f, %.2f) | Lệch %.0f studs",
            bestPart.Position.X,
            bestPart.Position.Y,
            bestPart.Position.Z,
            bestDistance
        ))

        if bestDistance <= 6000 then
            return bestPart
        end
    end

    warn("[LPT WHIRLPOOL] Không xác định được Entrance gần vị trí dự kiến")
    return nil
end

local function tryFirstSeaUnderwaterEntrance(module, styleName, shouldCancel)
    if shouldCancelOperation(shouldCancel) then
        return false
    end

    if game.PlaceId ~= 2753915549
        and game.PlaceId ~= 85211729168715 then
        return nil
    end

    local underwaterCity = Vector3.new(61163.85, 11.68, 1819.78)
    local entrancePart = findWhirlpoolEntrancePart()

    if not entrancePart then
        notify("Không xác định được Entrance; đã dừng để tránh bay sai vị trí")
        return false
    end

    local whirlpoolCenter = entrancePart.Position

    local function getPosition(object)
        if object:IsA("BasePart") then
            return object.Position
        elseif object:IsA("Model") then
            local ok, pivot = pcall(function()
                return object:GetPivot()
            end)

            if ok then
                return pivot.Position
            end
        end

        return nil
    end

    local function isInsideUnderwaterCity()
        local root = getCurrentRoot()

        return root ~= nil
            and (root.Position - underwaterCity).Magnitude <= 3200
    end

    --====================================================
    -- ĐANG Ở UNDERWATER CITY: TÌM CỔNG ĐỂ RA
    --====================================================

    if isInsideUnderwaterCity() then
        if styleName == "Water Kung Fu" then
            notify("Đang ở Underwater City; bỏ qua đường vào Whirlpool")
            return true
        end

        local root = getCurrentRoot()
        if not root then
            return false
        end

        local bestPortal = nil
        local bestPosition = nil
        local bestDistance = math.huge
        local seen = {}

        for _, object in ipairs(workspace:GetDescendants()) do
            if not object:IsA("BasePart")
                and not object:IsA("Model") then
                continue
            end

            local objectPosition = getPosition(object)

            if not objectPosition
                or (objectPosition - underwaterCity).Magnitude > 4000 then
                continue
            end

            local metadata, portalRoot = getPortalMetadata(object)
            metadata = normalizeName(metadata)

            local looksLikePortal =
                string.find(metadata, "portal", 1, true) ~= nil
                or string.find(metadata, "whirlpool", 1, true) ~= nil
                or string.find(metadata, "exit", 1, true) ~= nil

            if not looksLikePortal then
                continue
            end

            local candidate = portalRoot or object

            if seen[candidate] then
                continue
            end
            seen[candidate] = true

            local candidatePosition = getPosition(candidate)

            if candidatePosition
                and (candidatePosition - underwaterCity).Magnitude <= 4000 then

                local distance =
                    (root.Position - candidatePosition).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    bestPortal = candidate
                    bestPosition = candidatePosition
                end
            end
        end

        if not bestPosition then
            notify(
                "Không tìm thấy cổng trong Underwater City. "
                .. "Đã dừng để tránh bay thẳng xuyên bản đồ."
            )

            print(
                "[LPT ROUTE DEBUG] Không tìm thấy portal"
                .. " | PlaceId=" .. tostring(game.PlaceId)
                .. " | Style=" .. tostring(styleName)
            )

            return false
        end

        local portalName = bestPortal.Name or "Portal"

        notify(
            "Đang bay tới cổng trong Underwater City: "
            .. portalName
        )

        print(string.format(
            "[LPT ROUTE DEBUG] Portal=%s | Position=(%.2f, %.2f, %.2f)",
            tostring(portalName),
            bestPosition.X,
            bestPosition.Y,
            bestPosition.Z
        ))

        local function hasExitedCity()
            local currentRoot = getCurrentRoot()

            return currentRoot ~= nil
                and (currentRoot.Position - underwaterCity).Magnitude > 4000
        end

        local function cancelPortalFlight()
            return shouldCancelOperation(shouldCancel)
                or hasExitedCity()
        end

        module:FlyToPosition(
            bestPosition + Vector3.new(0, 2, 0),
            "Cổng ra Underwater City",
            5,
            cancelPortalFlight
        )

        if shouldCancelOperation(shouldCancel) then
            return false
        end

        local deadline = os.clock() + 5

        repeat
            if shouldCancelOperation(shouldCancel) then
                return false
            end

            if hasExitedCity() then
                notify("Đã rời Underwater City; tiếp tục tới " .. styleName)
                return nil
            end

            task.wait(0.1)
        until os.clock() >= deadline

        notify(
            "Đã tới cổng nhưng chưa xác nhận được dịch chuyển. "
            .. "Không bay thẳng tới NPC để tránh đi sai tuyến."
        )

        return false
    end

    if styleName ~= "Water Kung Fu" then
        return nil
    end

    --====================================================
    -- WATER KUNG FU: ĐI VÀO UNDERWATER CITY
    --====================================================

    local fallback = getFightingStyleFallback(styleName)

    if not fallback
        or typeof(fallback.Position) ~= "Vector3"
        or fallback.Position.X < 50000 then
        return nil
    end

    local root = getCurrentRoot()

    if not root then
        notify("Không tìm thấy nhân vật để đi tới Whirlpool")
        return false
    end

    local startPosition = root.Position

    local function enteredUnderwaterCity()
        local currentRoot = getCurrentRoot()

        return currentRoot ~= nil
            and (currentRoot.Position - underwaterCity).Magnitude <= 3200
            and (currentRoot.Position - startPosition).Magnitude >= 250
    end

    local function cancelPortalFlight()
        return shouldCancelOperation(shouldCancel)
            or enteredUnderwaterCity()
    end

    local entryPoints = {
        whirlpoolCenter,
        whirlpoolCenter + Vector3.new(0, -5, 0),
        whirlpoolCenter + Vector3.new(0, -12, 0),
        whirlpoolCenter + Vector3.new(0, 2, 0),
    }

    for attempt, entryPosition in ipairs(entryPoints) do
        if shouldCancelOperation(shouldCancel) then
            return false
        end

        if isInsideUnderwaterCity() then
            return true
        end

        notify(string.format(
            "Đang tiếp cận Whirlpool lần %d/%d",
            attempt,
            #entryPoints
        ))

        module:FlyToPosition(
            entryPosition,
            "Whirlpool — lối vào Underwater City",
            1.5,
            cancelPortalFlight
        )

        if shouldCancelOperation(shouldCancel) then
            return false
        end

        if enteredUnderwaterCity() then
            notify("Đã vào Underwater City; tiếp tục tới Water Kung Fu Teacher")
            return true
        end

        local deadline = os.clock() + 3.5

        repeat
            if shouldCancelOperation(shouldCancel) then
                return false
            end

            if enteredUnderwaterCity() then
                notify("Đã vào Underwater City; tiếp tục tới Water Kung Fu Teacher")
                return true
            end

            task.wait(0.1)
        until os.clock() >= deadline
    end

    notify("Whirlpool chưa kích hoạt; dừng tuyến vào")
    return false
end

local function tryThirdSeaPhysicalPortal(module, styleName, shouldCancel)
    if shouldCancelOperation(shouldCancel) or game.PlaceId ~= 7449423635 then
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

    local castleRoute = ThirdSeaPortalRoutes["Castle on the Sea"]
    local directDistance = (root.Position - destinationRoute.IslandCenter).Magnitude
    if directDistance <= 1100 then
        return false
    end

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

    local function flyDirectFromCurrentPosition(reason)
        if reason then
            notify(reason)
        end

        return false
    end

    local function tryFromCastleToDestination()
        if shouldCancelOperation(shouldCancel) then
            return false
        end

        local currentRoot = getCurrentRoot()
        if not currentRoot then
            return false
        end

        local portalPosition = findCastlePortalFor(destinationName)
        if not portalPosition then
            return flyDirectFromCurrentPosition(
                "Chưa tìm thấy cổng Castle tới " .. destinationName .. "; chọn bay thẳng nếu đó là đường khả dụng."
            )
        end

        local distanceToPortal = (currentRoot.Position - portalPosition).Magnitude
        local distanceDirect = (currentRoot.Position - destinationRoute.IslandCenter).Magnitude
        local finalDestinationLeg = (destinationRoute.Entrance - destinationRoute.IslandCenter).Magnitude
        local portalRouteDistance = distanceToPortal + finalDestinationLeg
        if portalRouteDistance + 100 >= distanceDirect then
            return flyDirectFromCurrentPosition(string.format(
                "Đường ngắn nhất từ Castle tới %s: bay thẳng (%.0f studs), qua cổng ước tính %.0f studs.",
                destinationName,
                distanceDirect,
                portalRouteDistance
            ))
        end

        notify(string.format(
            "Đường ngắn nhất tới %s: qua cổng Castle (ước tính %.0f studs thay vì %.0f studs bay thẳng).",
            destinationName,
            portalRouteDistance,
            distanceDirect
        ))
        return moveThroughPhysicalPortal(
            module,
            portalPosition,
            "Portal tới " .. destinationName,
            destinationRoute,
            destinationName,
            shouldCancel
        )
    end

    local distanceFromCastle = (root.Position - castleRoute.IslandCenter).Magnitude
    local isAtCastle = distanceFromCastle <= 1450

    if destinationName == "Castle on the Sea" then
        if isAtCastle then
            return false
        end

        local portal, portalDistance = nearestReturnPortal(root.Position)
        if not portal then
            return false
        end

        if portalDistance + 100 >= directDistance then
            return flyDirectFromCurrentPosition(string.format(
                "Đường ngắn nhất tới Castle on the Sea: bay thẳng (%.0f studs), cổng gần nhất là %.0f studs.",
                directDistance,
                portalDistance
            ))
        end

        notify(string.format(
            "Đường ngắn nhất tới Castle on the Sea: qua %s (%.0f studs thay vì %.0f studs bay thẳng).",
            portal.Name,
            portalDistance,
            directDistance
        ))
        return moveThroughPhysicalPortal(
            module,
            portal.Position,
            portal.Name,
            castleRoute,
            "Castle on the Sea",
            shouldCancel
        )
    end

    if isAtCastle then
        return tryFromCastleToDestination()
    end

    local returnPortal, returnDistance = nearestReturnPortal(root.Position)
    if not returnPortal then
        return false
    end

    local outboundPortalPosition = findCastlePortalFor(destinationName)
    local castleToOutboundDistance = outboundPortalPosition
        and (outboundPortalPosition - castleRoute.IslandCenter).Magnitude
        or 900
    local finalDestinationLeg = (destinationRoute.Entrance - destinationRoute.IslandCenter).Magnitude
    local estimatedPortalRoute = returnDistance + castleToOutboundDistance + finalDestinationLeg

    if estimatedPortalRoute + 100 >= directDistance then
        return flyDirectFromCurrentPosition(string.format(
            "Đường ngắn nhất tới %s: bay thẳng (%.0f studs), tuyến qua cổng ước tính %.0f studs.",
            destinationName,
            directDistance,
            estimatedPortalRoute
        ))
    end

    notify(string.format(
        "Đã chọn tuyến ngắn nhất tới %s: %s -> Castle -> cổng tới đích (ước tính %.0f studs, bay thẳng %.0f studs).",
        destinationName,
        returnPortal.Name,
        estimatedPortalRoute,
        directDistance
    ))

    local reachedCastle = moveThroughPhysicalPortal(
        module,
        returnPortal.Position,
        returnPortal.Name,
        castleRoute,
        "Castle on the Sea",
        shouldCancel
    )
    if not reachedCastle or shouldCancelOperation(shouldCancel) then
        return false
    end

    task.wait(0.35)
    if shouldCancelOperation(shouldCancel) then
        return false
    end

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

function ShopModule:FlyToNPC(npc, shouldCancel)
    if destroyed or shouldCancelOperation(shouldCancel) or not npc or not npc.Parent then
        return false
    end

    local npcRoot = getRoot(npc)
    if not npcRoot then
        return false
    end

    local targetPosition = npcRoot.Position
        - npcRoot.CFrame.LookVector * 4
        + Vector3.new(0, 2, 0)

    local moved = self:FlyToPosition(targetPosition, npc.Name, 5, shouldCancel)
    if not moved or shouldCancelOperation(shouldCancel) then
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

    return not shouldCancelOperation(shouldCancel)
        and (root.Position - npcRoot.Position).Magnitude <= 12
end

function ShopModule:StartTriangleOrbit(styleName, target, targetLabel)
    if destroyed then
        return false
    end

    local function getOrbitCenter()
        if typeof(target) == "Vector3" then
            return target
        end

        if typeof(target) == "Instance"
            and target:IsA("Model")
            and target.Parent then

            local targetRoot = getRoot(target)
            return targetRoot and targetRoot.Position or nil
        end

        return nil
    end

    local orbitLabel = targetLabel

    if type(orbitLabel) ~= "string" or orbitLabel == "" then
        if typeof(target) == "Instance" then
            orbitLabel = target.Name
        else
            local fallback = getFightingStyleFallback(styleName)
            orbitLabel = fallback and fallback.Name or styleName
        end
    end

    local initialCenter = getOrbitCenter()
    if not initialCenter then
        return false
    end

    if State.TriangleOrbitNPCs[styleName] == target
        and State.FightingStyleEnabled[styleName] == true
        and State.ActiveFightingStyle == styleName then
        return true
    end

    local character = getCharacter()
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end

    State.TriangleOrbitTokens[styleName] =
        (State.TriangleOrbitTokens[styleName] or 0) + 1

    local token = State.TriangleOrbitTokens[styleName]
    State.TriangleOrbitNPCs[styleName] = target

    local orbitRadius = 6
    local orbitSpeed = 55
    local offset = root.Position - initialCenter
    local startAngle = math.atan2(offset.Z, offset.X)
    local vertexIndex = 0

    local function shouldStop()
        return destroyed
            or State.FightingStyleEnabled[styleName] ~= true
            or State.ActiveFightingStyle ~= styleName
            or State.TriangleOrbitTokens[styleName] ~= token
            or getOrbitCenter() == nil
    end

    task.spawn(function()
        notify(
            "Đang bay tam giác liên tục quanh "
            .. orbitLabel
            .. ". Tắt "
            .. styleName
            .. " để dừng."
        )

        while not shouldStop() do
            local center = getOrbitCenter()

            character = getCharacter()
            root = character
                and character:FindFirstChild("HumanoidRootPart")

            if not center or not root or not root.Parent then
                task.wait(0.15)
            else
                local angle = startAngle
                    + vertexIndex * 2 * math.pi / 3

                local destination = Vector3.new(
                    center.X + math.cos(angle) * orbitRadius,
                    center.Y + 2,
                    center.Z + math.sin(angle) * orbitRadius
                )

                local callOK, moved = pcall(function()
                    return self:FlyToPosition(
                        destination,
                        "tam giác quanh " .. orbitLabel,
                        1.5,
                        shouldStop,
                        orbitSpeed,
                        true
                    )
                end)

                if shouldStop() then
                    break
                end

                if callOK and moved then
                    vertexIndex = (vertexIndex + 1) % 3
                else
                    task.wait(0.1)
                end
            end
        end

        if State.TriangleOrbitTokens[styleName] == token then
            State.TriangleOrbitNPCs[styleName] = nil
        end

        if not destroyed then
            notify("Đã dừng bay tam giác quanh " .. orbitLabel)
        end
    end)

    return true
end

--========================================================
-- GET / EQUIP FIGHTING STYLE
--========================================================

function ShopModule:GetFightingStyle(styleName, shouldCancel)
    local function cancelled()
        return shouldCancelOperation(shouldCancel)
    end

    if cancelled() then
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

    local fallback = getFightingStyleFallback(styleName)

    if not fallback or typeof(fallback.Position) ~= "Vector3" then
        notify(
            "Không có tọa độ cho "
            .. styleName
            .. " ở PlaceId "
            .. tostring(game.PlaceId)
        )
        return false
    end

    local underwaterRouteResult =
        tryFirstSeaUnderwaterEntrance(self, styleName, shouldCancel)

    if cancelled() or underwaterRouteResult == false then
        return false
    end

    tryThirdSeaPhysicalPortal(self, styleName, shouldCancel)

    if cancelled() then
        return false
    end

    local targetPosition = fallback.Position
    local targetName = fallback.Name or styleName

    notify(
        "Đang bay thẳng tới tọa độ "
        .. targetName
        .. " (không quét NPC)"
    )

    if not self:FlyToPosition(
        targetPosition,
        targetName,
        8,
        shouldCancel
    ) then
        if not cancelled() then
            notify("Không thể tới tọa độ " .. targetName)
        end

        return false
    end

    if cancelled() then
        return false
    end

    State.FightingStyleTargets[styleName] = targetPosition

    print(string.format(
        "[LPT TARGET DEBUG] Style=%s | Target=%s | Position=(%.2f, %.2f, %.2f)",
        tostring(styleName),
        tostring(targetName),
        targetPosition.X,
        targetPosition.Y,
        targetPosition.Z
    ))

    local orbitStarted = self:StartTriangleOrbit(
        styleName,
        targetPosition,
        targetName
    )

    if not orbitStarted then
        notify("Chưa khởi động được vòng tam giác quanh " .. targetName)
    end

    local requestOK, requestResult = invokeFightingStyleCommands(styleName)

    if cancelled() then
        return false
    end

    if not requestOK then
        notify("Không thể gửi yêu cầu cho " .. styleName .. ": " .. tostring(requestResult))
        return false
    end

    local deadline = os.clock() + 5

    repeat
        if cancelled() then
            return false
        end

        local character = getCharacter()
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        local tool = findFightingStyleTool(styleName)

        if tool and humanoid and character then
            local equipOK = pcall(function()
                humanoid:EquipTool(tool)
            end)

            if equipOK then
                task.wait(0.1)

                if cancelled() then
                    return false
                end

                if tool.Parent == character then
                    return true
                end
            end
        end

        task.wait(0.1)
    until os.clock() >= deadline

    if cancelled() then
        return false
    end

    local resultText = type(requestResult) == "string" and requestResult or ""

    if resultText ~= "" then
        notify("Chưa xác nhận được " .. styleName .. ". Phản hồi: " .. resultText)
    else
        notify("Chưa xác nhận được " .. styleName .. ". Có thể thiếu tiền, điều kiện hoặc Remote đã thay đổi.")
    end

    return false
end

local ValidCallbackNames = {
    Success = true,
    Failed = true,
    Notification = true,
    StateChanged = true,
}

function ShopModule:SetCallback(name, callback)
    if destroyed or not ValidCallbackNames[name] then
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
            noClipConnection = RunService.PreSimulation:Connect(function()
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
        invalidateStyleOperation(name)
        State.FightingStyleTargets[name] = nil

        if State.ActiveFightingStyle == name then
            State.ActiveFightingStyle = nil
        end

        publishFightingStyleStates()
        notify("Đã tắt: " .. name .. " (đã dừng mọi chuyển động của Fighting Style)")
        return true
    end

    if State.FightingStyleEnabled[name] == true and State.ActiveFightingStyle == name then
        return true
    end

    for otherStyle in pairs(FightingStyleKeywords) do
        if otherStyle ~= name then
            State.FightingStyleEnabled[otherStyle] = false
            invalidateStyleOperation(otherStyle)
            State.FightingStyleTargets[otherStyle] = nil
        end
    end

    State.StyleOperationTokens[name] = (State.StyleOperationTokens[name] or 0) + 1
    local operationToken = State.StyleOperationTokens[name]
    State.FightingStyleTargets[name] = nil
    State.ActiveFightingStyle = name
    State.FightingStyleEnabled[name] = true
    publishFightingStyleStates()

    local function shouldCancel()
        return destroyed
            or State.ActiveFightingStyle ~= name
            or State.FightingStyleEnabled[name] ~= true
            or State.StyleOperationTokens[name] ~= operationToken
    end

    local styleSuccess = self:GetFightingStyle(name, shouldCancel)
    if shouldCancel() then
        return false
    end

    if not styleSuccess then
        local orbitTarget = State.FightingStyleTargets[name]

        if isValidFightingStyleTarget(orbitTarget) then
            State.FightingStyleEnabled[name] = true
            State.ActiveFightingStyle = name
            publishFightingStyleStates()

            local started = self:StartTriangleOrbit(name, orbitTarget)

            if not started then
                notify(
                    "Chưa xác nhận được "
                    .. name
                    .. " và chưa khởi động được vòng tam giác."
                )
            else
                notify(
                    "Chưa xác nhận được "
                    .. name
                    .. "; vẫn tiếp tục bay tam giác quanh tọa độ đã lưu."
                )
            end

            return true
        end

        State.FightingStyleEnabled[name] = false

        if State.ActiveFightingStyle == name then
            State.ActiveFightingStyle = nil
        end

        invalidateStyleOperation(name)
        State.FightingStyleTargets[name] = nil
        publishFightingStyleStates()

        if type(Callbacks.Failed) == "function" then
            pcall(Callbacks.Failed, name)
        end

        return false
    end

    for styleName in pairs(FightingStyleKeywords) do
        State.FightingStyleEnabled[styleName] = styleName == name
    end
    publishFightingStyleStates()

    local orbitTarget = State.FightingStyleTargets[name]

    if isValidFightingStyleTarget(orbitTarget) then
        self:StartTriangleOrbit(name, orbitTarget)
    else
        notify(
            "Đã trang bị "
            .. name
            .. " nhưng chưa có tọa độ để bay vòng."
        )
    end

    notify("Đã trang bị: " .. name)
    if type(Callbacks.Success) == "function" then
        pcall(Callbacks.Success, name)
    end

    return true
end

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

    State.ActiveFightingStyle = nil
    table.clear(State.FightingStyleEnabled)
    table.clear(State.FightingStyleTargets)
    table.clear(State.TriangleOrbitTokens)
    table.clear(State.TriangleOrbitNPCs)
    table.clear(State.StyleOperationTokens)

    for key in pairs(Callbacks) do
        Callbacks[key] = nil
    end
end

return ShopModule
