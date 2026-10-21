local ShopModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
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

    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
    return root ~= nil
end

--========================================================
-- FIND FIGHTING STYLE NPC
--========================================================

function ShopModule:FindFightingStyleNPC(styleName)
    if destroyed then
        return nil
    end

    local keywords = FightingStyleKeywords[styleName]
    if not keywords then
        notify("Không có dữ liệu quét NPC cho: " .. tostring(styleName))
        return nil
    end

    local character = getCharacter()
    if not character then
        return nil
    end

    local playerRoot = character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        return nil
    end

    local bestNPC = nil
    local bestScore = -math.huge
    local bestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPCModel(obj) then
            local npcRoot = getRoot(obj)
            if npcRoot then
                local score = 0
                local normalized = normalizeName(obj.Name)

                for _, keyword in ipairs(keywords) do
                    local normalizedKeyword = normalizeName(keyword)

                    if normalized == normalizedKeyword then
                        score += 1000
                    elseif string.find(normalized, normalizedKeyword, 1, true) then
                        score += 500
                    end
                end

                if string.find(normalized, "teacher", 1, true) then
                    score += 100
                end

                if string.find(normalized, "npc", 1, true) then
                    score += 10
                end

                if score > 0 then
                    local distance = (playerRoot.Position - npcRoot.Position).Magnitude

                    if score > bestScore or (score == bestScore and distance < bestDistance) then
                        bestNPC = obj
                        bestScore = score
                        bestDistance = distance
                    end
                end
            end
        end
    end

    return bestNPC
end

--========================================================
-- FLY TO NPC
--========================================================

local FLY_SPEED = 250

function ShopModule:FlyToNPC(npc)
    if destroyed or not npc or not npc.Parent then
        return false
    end

    local character = getCharacter()
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local npcRoot = getRoot(npc)

    if not humanoid or humanoid.Health <= 0 or not root or not npcRoot then
        return false
    end

    local targetPosition = npcRoot.Position
        - npcRoot.CFrame.LookVector * 4
        + Vector3.new(0, 2, 0)

    local distance = (root.Position - targetPosition).Magnitude
    if distance <= 5 then
        return true
    end

    local duration = math.max(distance / FLY_SPEED, 0.15)
    local targetCFrame = CFrame.lookAt(targetPosition, npcRoot.Position)

    notify("Đang bay tới " .. npc.Name)

    local tween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = targetCFrame }
    )

    local finished = false
    local reached = false

    local connection = tween.Completed:Connect(function(playbackState)
        finished = true
        reached = playbackState == Enum.PlaybackState.Completed
    end)

    tween:Play()

    local deadline = os.clock() + duration + 2
    while not finished and not destroyed and os.clock() < deadline do
        if player.Character ~= character
            or not root.Parent
            or not npc.Parent
            or humanoid.Health <= 0 then
            tween:Cancel()
            break
        end

        task.wait(0.05)
    end

    if not finished then
        tween:Cancel()
    end

    connection:Disconnect()

    if destroyed or player.Character ~= character or not root.Parent then
        return false
    end

    return reached and (root.Position - targetPosition).Magnitude <= 10
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

    local npc = self:FindFightingStyleNPC(styleName)
    if not npc then
        notify("Không tìm thấy NPC bán võ: " .. styleName)
        return false
    end

    if not self:FlyToNPC(npc) then
        notify("Không thể bay tới NPC " .. npc.Name)
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
