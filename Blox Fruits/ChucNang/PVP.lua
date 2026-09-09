local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local PVPModule = {}

local State = {
    WalkSpeed = 16,
    JumpPower = 50,

    ChangeWalkSpeed = false,
    ChangeJumpPower = false,
    WalkOnWater = true
}

local Connections = {}

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function disconnectAll()
    for i, connection in pairs(Connections) do
        disconnect(connection)
        Connections[i] = nil
    end
end

local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

--============================================================
-- WALK SPEED
--============================================================

local function applyWalkSpeed()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    if State.ChangeWalkSpeed then
        humanoid.WalkSpeed = State.WalkSpeed
    else
        humanoid.WalkSpeed = 16
    end
end

--============================================================
-- JUMP POWER
--============================================================

local function applyJumpPower()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    humanoid.UseJumpPower = true

    if State.ChangeJumpPower then
        humanoid.JumpPower = State.JumpPower
    else
        humanoid.JumpPower = 50
    end
end

--============================================================
-- CHARACTER RESPAWN
--============================================================

local characterConnection = player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 5)

    if not humanoid then
        return
    end

    task.wait(0.1)

    applyWalkSpeed()
    applyJumpPower()
end)

table.insert(Connections, characterConnection)

--============================================================
-- WALK ON WATER
--============================================================

local waterConnection = nil
local waterPlatform = nil

local function removeWaterPlatform()
    if waterPlatform then
        pcall(function()
            waterPlatform:Destroy()
        end)

        waterPlatform = nil
    end
end

local function createWaterPlatform()
    removeWaterPlatform()

    local root = getRoot()

    if not root then
        return
    end

    local part = Instance.new("Part")

    part.Name = "LPT_WaterWalk"
    part.Size = Vector3.new(8, 1, 8)
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 1

    part.Parent = workspace

    waterPlatform = part
end

local function updateWaterPlatform()
    if not State.WalkOnWater then
        removeWaterPlatform()
        return
    end

    local root = getRoot()

    if not root then
        removeWaterPlatform()
        return
    end

    if not waterPlatform or not waterPlatform.Parent then
        createWaterPlatform()
    end

    if not waterPlatform then
        return
    end

    waterPlatform.CFrame = CFrame.new(
        root.Position.X,
        root.Position.Y - 3,
        root.Position.Z
    )
end

local function setupWaterWalk()
    disconnect(waterConnection)
    waterConnection = nil

    removeWaterPlatform()

    if not State.WalkOnWater then
        return
    end

    createWaterPlatform()

    waterConnection = RunService.Heartbeat:Connect(function()
        updateWaterPlatform()
    end)

    table.insert(Connections, waterConnection)
end

--============================================================
-- SET
--============================================================

function PVPModule:Set(name, value)

    if name == "WalkSpeed" then

        local number = tonumber(value)

        if not number then
            return false
        end

        State.WalkSpeed = math.clamp(number, 0, 500)

        if State.ChangeWalkSpeed then
            applyWalkSpeed()
        end

        return true
    end

    if name == "JumpPower" then

        local number = tonumber(value)

        if not number then
            return false
        end

        State.JumpPower = math.clamp(number, 0, 500)

        if State.ChangeJumpPower then
            applyJumpPower()
        end

        return true
    end

    if name == "ChangeWalkSpeed" then

        State.ChangeWalkSpeed = value == true

        applyWalkSpeed()

        return true
    end

    if name == "ChangeJumpPower" then

        State.ChangeJumpPower = value == true

        applyJumpPower()

        return true
    end

    if name == "WalkOnWater" then

        State.WalkOnWater = value == true

        setupWaterWalk()

        return true
    end

    warn("[LPT PVP] Unknown setting:", name)

    return false
end

--============================================================
-- GET
--============================================================

function PVPModule:Get(name)
    return State[name]
end

function PVPModule:GetAll()
    local result = {}

    for name, value in pairs(State) do
        result[name] = value
    end

    return result
end

--============================================================
-- DESTROY
--============================================================

function PVPModule:Destroy()

    disconnectAll()

    waterConnection = nil

    removeWaterPlatform()

    -- Reset character
    local humanoid = getHumanoid()

    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50
    end

    State.WalkSpeed = 16
    State.JumpPower = 50
    State.ChangeWalkSpeed = false
    State.ChangeJumpPower = false
    State.WalkOnWater = false
end

return PVPModule
