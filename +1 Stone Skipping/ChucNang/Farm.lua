local Farm = {}
local API
local destroyed = false
local state = {
    AutoTrain = false,
    AutoThrow = false,
    AutoRebirth = false,
}
local warningAt = {}

local function statusOnce(key, message)
    local now = os.clock()
    if not warningAt[key] or now - warningAt[key] > 8 then
        warningAt[key] = now
        if API and API.SetStatus then API.SetStatus(message, false) end
    end
end

local function doTrain()
    if not API then return false end

    local trainButton = API.FindButton({"start training", "train now", "train", "training"})
    if trainButton and API.ClickButton(trainButton) then
        API.SetStatus("Pressed the visible Train control", true)
        return true
    end

    local part = API.FindTrainingPart()
    local character = API.Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if part and root then
        local target = part.Position + Vector3.new(0, math.max(part.Size.Y / 2, 1) + 3, 0)
        if (root.Position - target).Magnitude > 7 then
            local ok = pcall(function()
                character:PivotTo(CFrame.new(target, target + part.CFrame.LookVector))
            end)
            if ok then
                API.SetStatus("Moved to a part named like a training area; stand there to train", true)
                return true
            end
        end
        API.SetStatus("Training area found; remain on the pad to gain Skill", true)
        return true
    end

    statusOnce("train", "No training pad or visible Train button found. Stand on the game's training pool/pad manually.")
    return false
end

local function doThrow()
    if not API then return false end
    local button = API.FindButton({"throw stone", "throw", "skip stone", "start throw", "launch stone"})
    if button and API.ClickButton(button) then
        API.SetStatus("Pressed the visible Throw control", true)
        return true
    end
    statusOnce("throw", "No visible Throw button found. Open the throwing screen or throw manually once.")
    return false
end

local function isRebirthReady()
    if not API then return false end

    local hasReadyText = API.TextExists({"ready to rebirth", "rebirth ready", "rebirth available"})
    if hasReadyText then return true end

    local button = API.FindButton({"rebirth"})
    if button then
        local context = API.GetButtonContext and API.GetButtonContext(button) or string.lower(button.Text or "")
        if string.find(context, "100", 1, true)
            or string.find(context, "ready", 1, true)
            or string.find(context, "available", 1, true) then
            return true
        end
    end
    return false
end

local function doRebirth()
    if not API then return false end
    if not isRebirthReady() then
        statusOnce("rebirthwait", "Auto Rebirth is waiting for the game's UI to show 100% / Ready.")
        return false
    end
    local button = API.FindButton({"rebirth"})
    if not button then
        statusOnce("rebirthbutton", "Rebirth appears ready, but no visible Rebirth button was found.")
        return false
    end
    if API.ClickButton(button) then
        task.wait(0.35)
        local confirm = API.FindButton({"confirm rebirth", "rebirth now", "confirm"}, {"rebirth", "confirm"})
        if confirm then API.ClickButton(confirm) end
        API.SetStatus("Sent the visible Rebirth UI action", true)
        return true
    end
    return false
end

local function runLoop(key, interval, action)
    task.spawn(function()
        while not destroyed and state[key] do
            local ok, err = pcall(action)
            if not ok then statusOnce(key .. "error", key .. " stopped for an error: " .. tostring(err)) end
            task.wait(interval)
        end
    end)
end

function Farm:Init(api)
    API = api
end

function Farm:Set(name, value)
    if destroyed or state[name] == nil then return false end
    state[name] = value == true
    if state[name] then
        if name == "AutoTrain" then runLoop(name, 2.0, doTrain)
        elseif name == "AutoThrow" then runLoop(name, 1.25, doThrow)
        elseif name == "AutoRebirth" then runLoop(name, 4.0, doRebirth) end
    end
    if API and API.SetStatus then
        API.SetStatus(name .. (state[name] and " enabled" or " disabled"), true)
    end
    return true
end

function Farm:Action(name)
    if destroyed then return false end
    if name == "TrainOnce" then return doTrain() end
    if name == "ThrowOnce" then return doThrow() end
    return false
end

function Farm:Get(name)
    return state[name] == true
end

function Farm:Destroy()
    destroyed = true
    for key in pairs(state) do state[key] = false end
end

return Farm
