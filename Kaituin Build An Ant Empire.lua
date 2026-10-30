local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
if not player then
    warn("Pumpkin Chest Helper: LocalPlayer is unavailable.")
    return
end

local TeleportService = game:GetService("TeleportService")

local AUTO_START = false

pcall(function()
    local env = getgenv()
    AUTO_START = env.PumpkinChestAutoStart == true
    env.PumpkinChestAutoStart = false
end)

local running = false
local workerToken = 0
local currentTarget = nil

local GUI_NAME = "PumpkinChestHelper"

pcall(function()
    local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
    if oldGui then
        oldGui:Destroy()
    end
end)

local function getCharacter()
    return player.Character
end

local function getRoot(character)
    return character and (
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
    )
end

local function getChestPosition(instance)
    if not instance or not instance.Parent then
        return nil
    end

    if instance:IsA("BasePart") then
        return instance.Position
    elseif instance:IsA("Model") then
        local part = instance.PrimaryPart
            or instance:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end

    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function isChestName(name)
    return string.lower(name) == "treasure"
end

local function findChests()
    local results = {}
    local seen = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isChestName(obj.Name) then
            local candidate = obj
            if not candidate:IsA("Model") then
                local parentModel = candidate:FindFirstAncestorOfClass("Model")
                if parentModel and isChestName(parentModel.Name) then
                    candidate = parentModel
                end
            end

            if not seen[candidate] and getChestPosition(candidate) then
                seen[candidate] = true
                table.insert(results, candidate)
            end
        end
    end

    return results
end

local function findPrompt(chest)
    if not chest then
        return nil
    end

    if chest:IsA("ProximityPrompt") then
        return chest
    end

    for _, obj in ipairs(chest:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            return obj
        end
    end

    return nil
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(280, 155)
main.Position = UDim2.new(0.5, -140, 0.35, 0)
main.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 174, 60)
stroke.Thickness = 1.5
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "Auto Farm Pumpkin Chest"
title.TextColor3 = Color3.fromRGB(255, 190, 80)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.new(1, -24, 0, 42)
toggle.Position = UDim2.fromOffset(12, 43)
toggle.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
toggle.BorderSizePixel = 0
toggle.Text = "OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 16
toggle.Font = Enum.Font.GothamBold
toggle.Parent = main

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -24, 0, 43)
status.Position = UDim2.fromOffset(12, 94)
status.BackgroundTransparency = 1
status.Text = "Status: Off"
status.TextColor3 = Color3.fromRGB(220, 220, 225)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local dragging = false
local dragInput, dragStart, startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input == dragInput
        or input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

local function setStatus(text)
    if status and status.Parent then
        status.Text = "Status: " .. text
    end
end

local hopToNewServer

local function setEnabled(enabled)
    running = enabled
    workerToken += 1
    local myToken = workerToken

    if running then
        toggle.Text = "ON"
        toggle.BackgroundColor3 = Color3.fromRGB(45, 145, 80)
        setStatus("Searching for Pumpkin Chest...")
        task.spawn(function()
            local visited = {}
            local emptyScans = 0

            while running and workerToken == myToken do
                local character = getCharacter()
                local root = getRoot(character)

                if not character or not root then
                    setStatus("Waiting for character...")
                    task.wait(1)
                else
                    local target = nil
                    local targetDistance = math.huge
                    local chests = findChests()

                    for _, chest in ipairs(chests) do
                        if not visited[chest] then
                            local pos = getChestPosition(chest)
                            if pos then
                                local distance = (root.Position - pos).Magnitude
                                if distance < targetDistance then
                                    targetDistance = distance
                                    target = chest
                                end
                            end
                        end
                    end

                    if not target then
                        if #chests > 0 then
                            hopToNewServer()
                            break
                        else
                            emptyScans += 1

                            setStatus("No chest found (" .. emptyScans .. "/5)")

                            if emptyScans >= 5 then
                                hopToNewServer()
                                break
                            end

                            task.wait(2)
                        end
                    else
                        emptyScans = 0
                        currentTarget = target
                        local position = getChestPosition(target)

                        if not position then
                            visited[target] = true
                        else
                            setStatus("Moving to " .. target.Name .. "...")
                            local destination = position + Vector3.new(0, 4, 0)
                            local ok = pcall(function()
                                root.CFrame = CFrame.new(destination)
                            end)

                            if not ok then
                                setStatus("Could not move to chest.")
                                task.wait(1)
                            else
                                task.wait(0.5)

                                if not running or workerToken ~= myToken then
                                    break
                                end

                                local prompt = findPrompt(target)
                                if prompt then
                                    local activated = false
                                    local success = pcall(function()
                                        if prompt.Enabled then
                                            prompt:InputHoldBegin()
                                            task.wait(math.max(0.15, prompt.HoldDuration))
                                            prompt:InputHoldEnd()
                                            activated = true
                                        end
                                    end)

                                    if not success or not activated then
                                        setStatus("At chest; press E if needed.")
                                        task.wait(1.5)
                                    else
                                        setStatus("Tried interaction; checking next chest...")
                                        task.wait(1)
                                    end
                                else
                                    setStatus("At chest; no ProximityPrompt found.")
                                    task.wait(1.5)
                                end

                                visited[target] = true
                            end
                        end
                    end
                end
            end
        end)
    else
        toggle.Text = "OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
        currentTarget = nil
        setStatus("Off")
    end
end

local hopping = false

hopToNewServer = function()
    if hopping then return end
    hopping = true

    local maxRetries = 3
    local attempt = 0

    local queueCode = [[
        task.spawn(function()
            if not game:IsLoaded() then
                game.Loaded:Wait()
            end

            local player = game:GetService("Players").LocalPlayer

            if not player.Character then
                player.CharacterAdded:Wait()
            end

            task.wait(2)

            getgenv().PumpkinChestAutoStart = true

            loadstring(game:HttpGet("https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Kaituin%20Build%20An%20Ant%20Empire.lua"))()
        end)
    ]]

    local queueFunction = queue_on_teleport or queueonteleport

    if not queueFunction then
        setStatus("Teleport queue unavailable!")
        hopping = false
        return
    end

    while attempt < maxRetries do
        attempt += 1
        setStatus("Fast Hop: Attempt " .. attempt .. "/" .. maxRetries)

        local queued = pcall(function()
            queueFunction(queueCode)
        end)

        if not queued then
            setStatus("Queue failed. Retrying...")
            task.wait(1)
        else
            local success = pcall(function()
                TeleportService:Teleport(game.PlaceId, player)
            end)

            if success then
                setStatus("Teleport requested. Waiting...")
                return
            end

            setStatus("Teleport failed. Retrying...")
            task.wait(1)
        end
    end

    hopping = false
    setStatus("Hop failed after 3 attempts. Try again manually.")
end

toggle.Activated:Connect(function()
    setEnabled(not running)
end)

if AUTO_START then
    task.delay(3, function()
        if gui.Parent then
            setEnabled(true)
        end
    end)
end

player.CharacterAdded:Connect(function()
    if running then
        setStatus("Character respawned; continuing...")
    end
end)
