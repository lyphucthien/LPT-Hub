local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MOVEMENT_MODULE_URL = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/%2B1%20Speed%20Keyboard%20Escape/ChucNang.lua"

local Movement = nil
local movementLoadError = nil

local LOCAL_MOVEMENT_SOURCE = [[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Module = {}

local WIN_STAGES = {
	{stage = 1, value = 1, text = "Stage 1 (+1 Win)"},
	{stage = 2, value = 3, text = "Stage 2 (+3 Wins)"},
	{stage = 3, value = 10, text = "Stage 3 (+10 Wins)"},
	{stage = 4, value = 20, text = "Stage 4 (+20 Wins)"},
	{stage = 5, value = 60, text = "Stage 5 (+60 Wins)"},
	{stage = 6, value = 100, text = "Stage 6 (+100 Wins)"},
	{stage = 7, value = 150, text = "Stage 7 (+150 Wins)"},
	{stage = 8, value = 300, text = "Stage 8 (+300 Wins)"},
	{stage = 9, value = 500, text = "Stage 9 (+500 Wins)"},
	{stage = 10, value = 1000, text = "Stage 10 (+1K Wins)"},
	{stage = 11, value = 2500, text = "Stage 11 (+2.5K Wins)"},
	{stage = 12, value = 10000, text = "Stage 12 (+10K Wins)"},
	{stage = 13, value = 25000, text = "Stage 13 (+25K Wins)"},
	{stage = 14, value = 50000, text = "Stage 14 (+50K Wins)"},
	{stage = 15, value = 150000, text = "Stage 15 (+150K Wins)"},
}

local State = {
	WalkSpeed = 16,
	JumpPower = 50,
	InfiniteJump = false,
	NoClip = false,
	Flying = false,
	FlySpeed = 90,
	FlyHeight = 5,
	CurrentTarget = nil,
	CurrentStage = nil,
	TargetCache = {},
	StageTargetCache = {},
	StageContainerCache = {},
	Scanning = false,
	AutoNextStage = false,
	AutoNextCurrentStage = nil,
}

local Connections = {}
local OriginalCollision = {}

--========================================================
-- BASIC
--========================================================

local function disconnect(name)
	local connection = Connections[name]

	if connection then
		pcall(function()
			connection:Disconnect()
		end)

		Connections[name] = nil
	end
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isBasePart(object)
	return object and object:IsA("BasePart") and object.Parent ~= nil
end

local function lower(value)
	return string.lower(tostring(value or ""))
end

local function getNumber(value, min, max, fallback)
	value = tonumber(value)

	if value == nil then
		return fallback
	end

	return math.clamp(value, min, max)
end

local function applyCharacterSettings()
	local humanoid = getHumanoid()

	if not humanoid then
		return
	end

	pcall(function()
		humanoid.UseJumpPower = true
		humanoid.WalkSpeed = State.WalkSpeed
		humanoid.JumpPower = State.JumpPower
	end)
end

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
	for object, original in pairs(OriginalCollision) do
		if object and object.Parent then
			pcall(function()
				object.CanCollide = original
			end)
		end
	end

	table.clear(OriginalCollision)
end

--========================================================
-- STAGE SCANNER
--========================================================

local function getStageNumberFromName(name)
	name = lower(name)

	local number = name:match("^stage(%d+)$")
		or name:match("^stage%-(%d+)$")
		or name:match("^stage_(%d+)$")
		or name:match("^stage%s+(%d+)$")
		or name:match("^(%d+)stage$")

	return number and tonumber(number) or nil
end

local function belongsToStage(part, stageNumber)
	local current = part

	for _ = 1, 20 do
		if not current then
			break
		end

		if getStageNumberFromName(current.Name) == stageNumber then
			return true
		end

		current = current.Parent
	end

	return false
end

local function findStructure()
	local structure = workspace:FindFirstChild("Structure")

	if structure then
		return structure
	end

	structure = workspace:FindFirstChild("Structure", true)

	if structure then
		return structure
	end

	for _, object in ipairs(workspace:GetDescendants()) do
		if lower(object.Name) == "structure" then
			return object
		end
	end

	return nil
end

local function findStageContainer(stageNumber)
	local cached = State.StageContainerCache[stageNumber]

	if cached and cached.Parent then
		return cached
	end

	local structure = findStructure()

	if not structure then
		return nil
	end

	for _, child in ipairs(structure:GetChildren()) do
		if getStageNumberFromName(child.Name) == stageNumber then
			State.StageContainerCache[stageNumber] = child
			return child
		end
	end

	for _, object in ipairs(structure:GetDescendants()) do
		if getStageNumberFromName(object.Name) == stageNumber then
			State.StageContainerCache[stageNumber] = object
			return object
		end
	end

	return nil
end

local function hasInteractiveObject(part)
	return part:FindFirstChild("TouchInterest")
		or part:FindFirstChildOfClass("ProximityPrompt")
		or part:FindFirstChildOfClass("ClickDetector")
end

local function isBadName(name)
	name = lower(name)

	return name:find("npc", 1, true)
		or name:find("enemy", 1, true)
		or name:find("dummy", 1, true)
		or name:find("ballerina", 1, true)
		or name:find("chocolita", 1, true)
		or name == "character"
end

local function getNameScore(name)
	name = lower(name)

	local score = 0

	if name == "getwinbutton" or name == "claimwinbutton" then
		score += 100000
	elseif name == "winbutton" then
		score += 90000
	elseif name == "getwin" then
		score += 85000
	elseif name == "claimwin" then
		score += 80000
	elseif name == "winblock" then
		score += 75000
	elseif name == "win" then
		score += 70000
	end

	if name:find("getwin", 1, true) then
		score += 50000
	end

	if name:find("claimwin", 1, true) then
		score += 50000
	end

	if name:find("winbutton", 1, true) then
		score += 45000
	end

	if name:find("claim", 1, true) then
		score += 30000
	end

	if name:find("finish", 1, true) then
		score += 25000
	end

	if name:find("award", 1, true) then
		score += 25000
	end

	if name:find("button", 1, true) then
		score += 20000
	end

	if name:find("win", 1, true) then
		score += 15000
	end

	return score
end

local function scoreTarget(part, stageNumber)
	if not isBasePart(part) then
		return -math.huge
	end

	local score = getNameScore(part.Name)
	local parent = part.Parent

	for _ = 1, 6 do
		if not parent then
			break
		end

		local parentName = lower(parent.Name)

		if parentName:find("win", 1, true) then
			score += 25000
		end

		if parentName:find("button", 1, true) then
			score += 15000
		end

		if parentName:find("claim", 1, true) then
			score += 20000
		end

		parent = parent.Parent
	end

	score += belongsToStage(part, stageNumber) and 30000 or -30000

	if hasInteractiveObject(part) then
		score += 30000
	end

	if isBadName(part.Name) then
		score -= 100000
	end

	local name = lower(part.Name)

	if name == "hitbox" or name:find("hitbox", 1, true) then
		score -= hasInteractiveObject(part) and 5000 or 50000
	end

	if part.Transparency >= 0.99 then
		score += hasInteractiveObject(part) and 5000 or -10000
	end

	return score
end

local function findTargetInStage(container, stageNumber)
	if not container then
		return nil
	end

	local bestTarget = nil
	local bestScore = -math.huge

	for _, object in ipairs(container:GetDescendants()) do
		if object:IsA("BasePart") then
			local score = scoreTarget(object, stageNumber)

			if score > bestScore then
				bestScore = score
				bestTarget = object
			end
		end
	end

	if container:IsA("BasePart") then
		local score = scoreTarget(container, stageNumber)

		if score > bestScore then
			bestScore = score
			bestTarget = container
		end
	end

	return bestTarget and bestScore > 0 and bestTarget or nil
end

local function scanStage(stageNumber)
	local container = findStageContainer(stageNumber)

	if not container then
		return nil
	end

	local target = findTargetInStage(container, stageNumber)

	if isBasePart(target) then
		State.StageTargetCache[stageNumber] = target

		for _, info in ipairs(WIN_STAGES) do
			if info.stage == stageNumber then
				State.TargetCache[info.value] = target
				break
			end
		end

		return target
	end

	return nil
end

function Module.RefreshStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	return scanStage(stageNumber)
end

function Module.ScanStageUntilFound(stageNumber, maxAttempts, delay)
	stageNumber = tonumber(stageNumber)
	maxAttempts = math.max(1, tonumber(maxAttempts) or 8)
	delay = math.max(0.05, tonumber(delay) or 0.5)

	if not stageNumber then
		return nil
	end

	for attempt = 1, maxAttempts do
		local target = scanStage(stageNumber)

		if isBasePart(target) then
			return target
		end

		if attempt < maxAttempts then
			task.wait(delay)
		end
	end

	return nil
end

function Module.RefreshTargets()
	if State.Scanning then
		return State.TargetCache
	end

	State.Scanning = true

	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)

	for _, info in ipairs(WIN_STAGES) do
		scanStage(info.stage)
		task.wait()
	end

	State.Scanning = false

	return State.TargetCache
end

function Module.GetTarget(value)
	value = tonumber(value)

	if not value then
		return nil
	end

	local target = State.TargetCache[value]

	if isBasePart(target) then
		return target
	end

	for _, info in ipairs(WIN_STAGES) do
		if info.value == value then
			return Module.ScanStageUntilFound(info.stage, 6, 0.4)
		end
	end

	return nil
end

function Module.GetTargets()
	return Module.RefreshTargets()
end

function Module.GetStageTarget(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	local target = State.StageTargetCache[stageNumber]

	if isBasePart(target) then
		return target
	end

	return Module.ScanStageUntilFound(stageNumber, 6, 0.4)
end

function Module.GetStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	for _, info in ipairs(WIN_STAGES) do
		if info.stage == stageNumber then
			return info
		end
	end

	return nil
end

function Module.GetStages()
	return WIN_STAGES
end

--========================================================
-- FLY
--========================================================

local function getTargetPosition(part)
	if not isBasePart(part) then
		return nil
	end

	return Vector3.new(
		part.Position.X,
		part.Position.Y + part.Size.Y / 2 + 2 + State.FlyHeight,
		part.Position.Z
	)
end

function Module.StopFlying()
	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil
end

function Module.IsFlying()
	return State.Flying
end

function Module.FlyToPart(part, stageNumber)
	if not isBasePart(part) then
		return false, "Invalid target"
	end

	if State.Flying then
		return false, "Already flying"
	end

	local root = getRoot()
	local humanoid = getHumanoid()

	if not root or not humanoid then
		return false, "Character not ready"
	end

	State.Flying = true
	State.CurrentTarget = part
	State.CurrentStage = stageNumber

	local oldAutoRotate = humanoid.AutoRotate
	local oldPlatformStand = humanoid.PlatformStand

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local started = os.clock()
	local reached = false

	while State.Flying and root.Parent and part.Parent and os.clock() - started < 45 do
		local destination = getTargetPosition(part)

		if not destination then
			break
		end

		local difference = destination - root.Position
		local distance = difference.Magnitude

		if distance <= 4 then
			reached = true
			break
		end

		local dt = RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		local speed = math.max(10, State.FlySpeed)
		local step = math.min(distance, speed * dt)

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.new(root.Position + difference.Unit * step)

		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
	end

	if reached and State.Flying and root.Parent and part.Parent then
		local destination = getTargetPosition(part)

		if destination then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = CFrame.new(destination)

			local holdStart = os.clock()

			while State.Flying and root.Parent and part.Parent and os.clock() - holdStart < 0.8 do
				local finalPosition = getTargetPosition(part)

				if finalPosition then
					root.CFrame = CFrame.new(finalPosition)
				end

				RunService.Heartbeat:Wait()
			end
		end
	end

	local stopped = not State.Flying

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = oldAutoRotate
		humanoid.PlatformStand = oldPlatformStand
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		humanoid.WalkSpeed = State.WalkSpeed
		humanoid.JumpPower = State.JumpPower
	end

	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

	if reached then
		return true
	end

	if stopped then
		return false, "Stopped"
	end

	return false, "Could not reach target"
end

function Module.FlyToStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	local info = Module.GetStage(stageNumber)

	if not info then
		return false, "Invalid stage"
	end

	local target = State.StageTargetCache[stageNumber]

	if not isBasePart(target) then
		target = Module.ScanStageUntilFound(stageNumber, 8, 0.5)
	end

	if not isBasePart(target) then
		return false, ("No target for Stage %d"):format(stageNumber)
	end

	return Module.FlyToPart(target, stageNumber)
end

function Module.FlyToWin(winAmount)
	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount"
	end

	for _, info in ipairs(WIN_STAGES) do
		if info.value == winAmount then
			return Module.FlyToStage(info.stage)
		end
	end

	return false, "No matching Stage"
end

--========================================================
-- MOVEMENT SETTINGS
--========================================================

function Module.SetWalkSpeed(value)
	State.WalkSpeed = getNumber(value, 0, 500, State.WalkSpeed)
	applyCharacterSettings()
	return true
end

function Module.GetWalkSpeed()
	return State.WalkSpeed
end

function Module.SetJumpPower(value)
	State.JumpPower = getNumber(value, 0, 500, State.JumpPower)
	applyCharacterSettings()
	return true
end

function Module.GetJumpPower()
	return State.JumpPower
end

function Module.SetFlySpeed(value)
	State.FlySpeed = getNumber(value, 10, 500, State.FlySpeed)
	return true
end

function Module.GetFlySpeed()
	return State.FlySpeed
end

function Module.SetFlyHeight(value)
	State.FlyHeight = getNumber(value, 0, 100, State.FlyHeight)
	return true
end

function Module.GetFlyHeight()
	return State.FlyHeight
end

--========================================================
-- INFINITE JUMP
--========================================================

function Module.SetInfiniteJump(enabled)
	State.InfiniteJump = enabled == true

	disconnect("InfiniteJump")

	if State.InfiniteJump then
		Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
			if not State.InfiniteJump then
				return
			end

			local humanoid = getHumanoid()

			if humanoid then
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end)
			end
		end)
	end

	return true
end

function Module.GetInfiniteJump()
	return State.InfiniteJump
end

--========================================================
-- NO CLIP
--========================================================

function Module.SetNoClip(enabled)
	State.NoClip = enabled == true

	local character = getCharacter()

	if State.NoClip then
		if character then
			rememberCollision(character)
		end
	else
		restoreCollision()
	end

	return true
end

function Module.GetNoClip()
	return State.NoClip
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
-- AUTO NEXT STATE
--========================================================

function Module.SetAutoNextStage(enabled)
	State.AutoNextStage = enabled == true

	if not State.AutoNextStage then
		State.AutoNextCurrentStage = nil
	end

	return true
end

function Module.GetAutoNextStage()
	return State.AutoNextStage
end

function Module.SetAutoNextCurrentStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		State.AutoNextCurrentStage = nil
		return true
	end

	State.AutoNextCurrentStage = math.clamp(math.floor(stageNumber), 1, #WIN_STAGES)

	return true
end

function Module.GetAutoNextCurrentStage()
	return State.AutoNextCurrentStage
end

--========================================================
-- CHARACTER
--========================================================

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

	table.clear(OriginalCollision)
	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)

	local humanoid = character:WaitForChild("Humanoid", 10)

	if humanoid then
		task.wait(0.15)
		applyCharacterSettings()

		if State.NoClip then
			rememberCollision(character)
		end
	end
end)

task.defer(function()
	task.wait(0.5)
	applyCharacterSettings()
end)

--========================================================
-- STATE
--========================================================

function Module.GetState()
	local found = 0

	for _, info in ipairs(WIN_STAGES) do
		if isBasePart(State.StageTargetCache[info.stage]) then
			found += 1
		end
	end

	return {
		WalkSpeed = State.WalkSpeed,
		JumpPower = State.JumpPower,
		InfiniteJump = State.InfiniteJump,
		NoClip = State.NoClip,
		Flying = State.Flying,
		FlySpeed = State.FlySpeed,
		FlyHeight = State.FlyHeight,
		CurrentTarget = State.CurrentTarget,
		CurrentStage = State.CurrentStage,
		AutoNextStage = State.AutoNextStage,
		AutoNextCurrentStage = State.AutoNextCurrentStage,
		TargetCount = #WIN_STAGES,
		FoundTargetCount = found,
		FoundTargets = State.StageTargetCache,
	}
end

--========================================================
-- DESTROY
--========================================================

function Module.Destroy()
	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil
	State.AutoNextStage = false
	State.AutoNextCurrentStage = nil

	for name, connection in pairs(Connections) do
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end

		Connections[name] = nil
	end

	restoreCollision()
	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)
	table.clear(OriginalCollision)
end

return Module
]]

--========================================================
-- LOAD MOVEMENT MODULE
--========================================================

local function moduleIsValid(module)
	if type(module) ~= "table" then
		return false
	end

	local requiredFunctions = {
		"SetWalkSpeed",
		"SetJumpPower",
		"SetFlySpeed",
		"SetFlyHeight",
		"SetInfiniteJump",
		"SetNoClip",
		"RefreshTargets",
		"RefreshStage",
		"ScanStageUntilFound",
		"GetTarget",
		"GetStageTarget",
		"FlyToWin",
		"FlyToStage",
		"StopFlying",
		"IsFlying",
		"SetAutoNextStage",
		"GetAutoNextStage",
	}

	for _, name in ipairs(requiredFunctions) do
		if type(module[name]) ~= "function" then
			return false
		end
	end

	return true
end

local function loadMovementModule()
	if Movement and moduleIsValid(Movement) then
		return Movement
	end

	local remoteOK, remoteResult = pcall(function()
		return loadstring(game:HttpGet(MOVEMENT_MODULE_URL))()
	end)

	if remoteOK and moduleIsValid(remoteResult) then
		Movement = remoteResult
		return Movement
	end

	movementLoadError = remoteOK
		and "Remote movement module is missing required functions."
		or tostring(remoteResult)

	local fallbackOK, fallbackResult = pcall(function()
		return loadstring(LOCAL_MOVEMENT_SOURCE)()
	end)

	if fallbackOK and moduleIsValid(fallbackResult) then
		Movement = fallbackResult
		return Movement
	end

	return nil
end

loadMovementModule()

--========================================================
-- PALETTE
--========================================================

local COLORS = {
	Background = Color3.fromRGB(10, 11, 16),
	Surface = Color3.fromRGB(14, 15, 21),
	SurfaceLight = Color3.fromRGB(40, 44, 58),
	Card = Color3.fromRGB(34, 38, 50),

	Accent = Color3.fromRGB(168, 105, 245),
	AccentB = Color3.fromRGB(236, 72, 153),

	Text = Color3.fromRGB(240, 241, 245),
	TextDim = Color3.fromRGB(150, 157, 170),
	Border = Color3.fromRGB(52, 56, 70),

	Danger = Color3.fromRGB(255, 92, 108),
	Online = Color3.fromRGB(52, 211, 153),

	PageServer = Color3.fromRGB(96, 165, 250),
	PageFarm = Color3.fromRGB(74, 222, 128),
	PageSettings = Color3.fromRGB(251, 146, 60),
}

local function tween(obj, props, time, style)
	local tweenObject = TweenService:Create(obj, TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad), props)
	tweenObject:Play()
	return tweenObject
end

local function applyGradient(guiObject, colorA, colorB, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 45
	gradient.Parent = guiObject
	return gradient
end

--========================================================
-- SETTINGS STORAGE
--========================================================

local SETTINGS_FILE = "LPT_Hub_Settings.json"

local DEFAULT_SETTINGS = {
	WalkSpeed = 16,
	JumpPower = 50,
	FlySpeed = 90,
	FlyHeight = 5,
	InfiniteJump = false,
	NoClip = false,
	PlayerESP = false,
}

local function loadSavedSettings()
	local settings = {}

	for key, value in pairs(DEFAULT_SETTINGS) do
		settings[key] = value
	end

	if not (isfile and readfile) then
		return settings
	end

	local ok, exists = pcall(function()
		return isfile(SETTINGS_FILE)
	end)

	if not ok or not exists then
		return settings
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_FILE))
	end)

	if success and type(result) == "table" then
		for key in pairs(DEFAULT_SETTINGS) do
			if result[key] ~= nil then
				settings[key] = result[key]
			end
		end
	end

	return settings
end

local Loaded = loadSavedSettings()

local speedValue = tonumber(Loaded.WalkSpeed) or 16
local jumpValue = tonumber(Loaded.JumpPower) or 50
local flySpeedValue = tonumber(Loaded.FlySpeed) or 90
local flyHeightValue = tonumber(Loaded.FlyHeight) or 5

local infiniteJumpEnabled
local noClipEnabled
local autoNextEnabled
local saveSettings

--========================================================
-- SCREEN GUI
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
	local placedInCoreGui = pcall(function()
		screenGui.Parent = game:GetService("CoreGui")
	end)

	if not placedInCoreGui then
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

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 20)
topBarCorner.Parent = topBar

local topBarMask = Instance.new("Frame")
topBarMask.Size = UDim2.new(1, 0, 0, 20)
topBarMask.Position = UDim2.new(0, 0, 1, -20)
topBarMask.BackgroundColor3 = COLORS.Surface
topBarMask.BorderSizePixel = 0
topBarMask.Parent = topBar

--========================================================
-- TITLE
--========================================================

local titleDot = Instance.new("Frame")
titleDot.Size = UDim2.new(0, 8, 0, 8)
titleDot.Position = UDim2.new(0, 20, 0.5, -4)
titleDot.BackgroundColor3 = COLORS.Online
titleDot.BorderSizePixel = 0
titleDot.ZIndex = 2
titleDot.Parent = topBar

local titleDotCorner = Instance.new("UICorner")
titleDotCorner.CornerRadius = UDim.new(1, 0)
titleDotCorner.Parent = titleDot

local titleDotPulse = Instance.new("Frame")
titleDotPulse.Size = UDim2.new(0, 8, 0, 8)
titleDotPulse.Position = UDim2.new(0.5, -4, 0.5, -4)
titleDotPulse.BackgroundColor3 = COLORS.Online
titleDotPulse.BackgroundTransparency = 0.3
titleDotPulse.BorderSizePixel = 0
titleDotPulse.ZIndex = 1
titleDotPulse.Parent = titleDot

local titleDotPulseCorner = Instance.new("UICorner")
titleDotPulseCorner.CornerRadius = UDim.new(1, 0)
titleDotPulseCorner.Parent = titleDotPulse

task.spawn(function()
	while titleDotPulse.Parent do
		titleDotPulse.Size = UDim2.new(0, 8, 0, 8)
		titleDotPulse.Position = UDim2.new(0.5, -4, 0.5, -4)
		titleDotPulse.BackgroundTransparency = 0.3

		tween(titleDotPulse, {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0.5, -11, 0.5, -11),
			BackgroundTransparency = 1,
		}, 1.1)

		task.wait(1.1)
	end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 105, 1, 0)
title.Position = UDim2.new(0, 36, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LPT Hub"
title.TextColor3 = COLORS.Text
title.TextSize = 18.5
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

applyGradient(title, COLORS.Accent, COLORS.AccentB, 0)

local author = Instance.new("TextLabel")
author.Size = UDim2.new(0, 170, 1, 0)
author.Position = UDim2.new(0, 113, 0, 0)
author.BackgroundTransparency = 1
author.Text = "by Ly Phuc Thien"
author.TextColor3 = COLORS.TextDim
author.TextSize = 11
author.Font = Enum.Font.Gotham
author.TextXAlignment = Enum.TextXAlignment.Left
author.Parent = topBar

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 1, -1)
separator.BackgroundColor3 = COLORS.Border
separator.BorderSizePixel = 0
separator.Parent = topBar

--========================================================
-- TOP BUTTONS
--========================================================

local function topButton(name, xOffset, text, textSize)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 30, 0, 26)
	button.Position = UDim2.new(1, xOffset, 0.5, -13)
	button.BackgroundColor3 = COLORS.SurfaceLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.TextDim
	button.TextSize = textSize
	button.Font = Enum.Font.GothamMedium
	button.AutoButtonColor = false
	button.Parent = topBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local minimize = topButton("MinimizeButton", -110, "—", 13)
local maximize = topButton("MaximizeButton", -76, "", 0)
local close = topButton("CloseButton", -40, "×", 17)

--========================================================
-- MAX ICON
--========================================================

local maxIcon = Instance.new("Frame")
maxIcon.Size = UDim2.new(0, 20, 0, 20)
maxIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
maxIcon.BackgroundTransparency = 1
maxIcon.BorderSizePixel = 0
maxIcon.Parent = maximize

local normalIcon = Instance.new("Frame")
normalIcon.Size = UDim2.new(0, 13, 0, 13)
normalIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
normalIcon.BackgroundTransparency = 1
normalIcon.BorderSizePixel = 0
normalIcon.Parent = maxIcon

local normalCorner = Instance.new("UICorner")
normalCorner.CornerRadius = UDim.new(0, 3)
normalCorner.Parent = normalIcon

local normalStroke = Instance.new("UIStroke")
normalStroke.Thickness = 1.5
normalStroke.Color = COLORS.TextDim
normalStroke.Parent = normalIcon

local restoreBack = Instance.new("Frame")
restoreBack.Size = UDim2.new(0, 11, 0, 11)
restoreBack.Position = UDim2.new(0, 6, 0, 2)
restoreBack.BackgroundTransparency = 1
restoreBack.BorderSizePixel = 0
restoreBack.Visible = false
restoreBack.ZIndex = 2
restoreBack.Parent = maxIcon

local restoreBackCorner = Instance.new("UICorner")
restoreBackCorner.CornerRadius = UDim.new(0, 2)
restoreBackCorner.Parent = restoreBack

local restoreBackStroke = Instance.new("UIStroke")
restoreBackStroke.Thickness = 1.5
restoreBackStroke.Color = COLORS.TextDim
restoreBackStroke.Parent = restoreBack

local restoreFront = Instance.new("Frame")
restoreFront.Size = UDim2.new(0, 11, 0, 11)
restoreFront.Position = UDim2.new(0, 2, 0, 6)
restoreFront.BackgroundColor3 = COLORS.Surface
restoreFront.BorderSizePixel = 0
restoreFront.Visible = false
restoreFront.ZIndex = 3
restoreFront.Parent = maxIcon

local restoreFrontCorner = Instance.new("UICorner")
restoreFrontCorner.CornerRadius = UDim.new(0, 2)
restoreFrontCorner.Parent = restoreFront

local restoreFrontStroke = Instance.new("UIStroke")
restoreFrontStroke.Thickness = 1.5
restoreFrontStroke.Color = COLORS.TextDim
restoreFrontStroke.Parent = restoreFront

local function setupTopButton(button, hoverColor, hoverBg)
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

setupTopButton(minimize, COLORS.Text)
setupTopButton(close, Color3.new(1, 1, 1), COLORS.Danger)

maximize.MouseEnter:Connect(function()
	tween(maximize, {BackgroundTransparency = 0})
	tween(normalStroke, {Color = COLORS.Text})
	tween(restoreBackStroke, {Color = COLORS.Text})
	tween(restoreFrontStroke, {Color = COLORS.Text})
end)

maximize.MouseLeave:Connect(function()
	tween(maximize, {BackgroundTransparency = 1})
	tween(normalStroke, {Color = COLORS.TextDim})
	tween(restoreBackStroke, {Color = COLORS.TextDim})
	tween(restoreFrontStroke, {Color = COLORS.TextDim})
end)

--========================================================
-- SIDEBAR
--========================================================

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 220, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = COLORS.Surface
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 20)
sidebarCorner.Parent = sidebar

local sidebarTopMask = Instance.new("Frame")
sidebarTopMask.Size = UDim2.new(1, 0, 0, 20)
sidebarTopMask.BackgroundColor3 = COLORS.Surface
sidebarTopMask.BorderSizePixel = 0
sidebarTopMask.Parent = sidebar

local sidebarInnerMask = Instance.new("Frame")
sidebarInnerMask.Size = UDim2.new(0, 20, 0, 20)
sidebarInnerMask.Position = UDim2.new(1, -20, 1, -20)
sidebarInnerMask.BackgroundColor3 = COLORS.Surface
sidebarInnerMask.BorderSizePixel = 0
sidebarInnerMask.Parent = sidebar

local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = COLORS.Border
sideLine.BorderSizePixel = 0
sideLine.Parent = sidebar

--========================================================
-- CONTENT
--========================================================

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -220, 1, -38)
content.Position = UDim2.new(0, 220, 0, 38)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = COLORS.Accent
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

local informationPage = createPage("Information")
local autoWinPage = createPage("AutoWin")
local espPage = createPage("ESP")
local settingsPage = createPage("Settings")

--========================================================
-- PAGE TITLE
--========================================================

local function createPageTitle(parent, text, subtitle)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 0, 38)
	label.Position = UDim2.new(0, 28, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	if subtitle then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -50, 0, 20)
		sub.Position = UDim2.new(0, 28, 0, 54)
		sub.BackgroundTransparency = 1
		sub.Text = subtitle
		sub.TextColor3 = COLORS.TextDim
		sub.TextSize = 14
		sub.Font = Enum.Font.Gotham
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Parent = parent
	end

	return label
end

--========================================================
-- UI HELPERS
--========================================================

local function createCard(parent, y, titleText, bodyText, height, accent)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -56, 0, height or 90)
	card.Position = UDim2.fromOffset(28, y)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = card

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, -20)
	bar.Position = UDim2.new(0, 0, 0.5, 0)
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.BackgroundColor3 = accent or COLORS.Accent
	bar.BorderSizePixel = 0
	bar.Parent = card

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local cardTitle = Instance.new("TextLabel")
	cardTitle.Size = UDim2.new(1, -40, 0, 22)
	cardTitle.Position = UDim2.fromOffset(18, 12)
	cardTitle.BackgroundTransparency = 1
	cardTitle.Text = titleText
	cardTitle.TextColor3 = COLORS.Text
	cardTitle.TextSize = 15
	cardTitle.Font = Enum.Font.GothamBold
	cardTitle.TextXAlignment = Enum.TextXAlignment.Left
	cardTitle.Parent = card

	local cardBody = Instance.new("TextLabel")
	cardBody.Size = UDim2.new(1, -40, 1, -40)
	cardBody.Position = UDim2.fromOffset(18, 36)
	cardBody.BackgroundTransparency = 1
	cardBody.Text = bodyText
	cardBody.TextColor3 = COLORS.TextDim
	cardBody.TextSize = 13
	cardBody.Font = Enum.Font.Gotham
	cardBody.TextXAlignment = Enum.TextXAlignment.Left
	cardBody.TextYAlignment = Enum.TextYAlignment.Top
	cardBody.TextWrapped = true
	cardBody.Parent = card

	return card
end

local function createToggle(parent, text, y, default, callback, accent)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -56, 0, 56)
	row.Position = UDim2.fromOffset(28, y)
	row.BackgroundColor3 = COLORS.Card
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

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
	button.Size = UDim2.fromOffset(50, 26)
	button.Position = UDim2.new(1, -68, 0.5, -13)
	button.BackgroundColor3 = default and (accent or COLORS.Accent) or COLORS.SurfaceLight
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(1, 0)
	buttonCorner.Parent = button

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(20, 20)
	knob.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = button

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local enabled = default == true
	local color = accent or COLORS.Accent

	local function setEnabled(value, fire)
		enabled = value == true

		tween(button, {
			BackgroundColor3 = enabled and color or COLORS.SurfaceLight,
		}, 0.18)

		tween(knob, {
			Position = enabled and UDim2.new(1, -23, 0.5, -10) or UDim2.fromOffset(3, 3),
		}, 0.18)

		if fire ~= false and callback then
			callback(enabled)
		end
	end

	button.MouseButton1Click:Connect(function()
		setEnabled(not enabled, true)
	end)

	row.MouseEnter:Connect(function()
		if not enabled then
			tween(row, {BackgroundColor3 = Color3.fromRGB(40, 44, 58)}, 0.15)
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

local function createInput(parent, text, y, value, minValue, maxValue, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -56, 0, 58)
	row.Position = UDim2.fromOffset(28, y)
	row.BackgroundColor3 = COLORS.Card
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -145, 1, 0)
	label.Position = UDim2.fromOffset(18, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(105, 34)
	box.Position = UDim2.new(1, -123, 0.5, -17)
	box.BackgroundColor3 = COLORS.SurfaceLight
	box.BorderSizePixel = 0
	box.Text = tostring(value)
	box.TextColor3 = COLORS.Text
	box.TextSize = 14
	box.Font = Enum.Font.GothamMedium
	box.ClearTextOnFocus = false
	box.Parent = row

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 9)
	boxCorner.Parent = box

	local function apply()
		local number = tonumber(box.Text)

		if not number then
			box.Text = tostring(value)
			return
		end

		number = math.clamp(number, minValue, maxValue)
		box.Text = tostring(number)
		callback(number)
	end

	box.FocusLost:Connect(apply)

	return box
end

--========================================================
-- INFORMATION
--========================================================

createPageTitle(informationPage, "Information", "LPT Hub movement and stage tools")

createCard(
	informationPage,
	95,
	"Movement Module",
	Movement and "Movement module loaded successfully." or "Movement module failed to load.",
	90,
	COLORS.PageServer
)

createCard(
	informationPage,
	197,
	"Remote Module",
	movementLoadError and ("Fallback used: " .. movementLoadError) or "Remote module is available.",
	90,
	COLORS.PageFarm
)

createCard(
	informationPage,
	299,
	"Win Stages",
	"15 stages are available from +1 Win up to +150K Wins.",
	90,
	COLORS.Accent
)

informationPage.CanvasSize = UDim2.new(0, 0, 0, 405)

--========================================================
-- AUTO WIN
--========================================================

createPageTitle(autoWinPage, "AutoWin", "Scan stages and fly to the selected Win target")

local stageButtonsFrame = Instance.new("Frame")
stageButtonsFrame.Size = UDim2.new(1, -56, 0, 300)
stageButtonsFrame.Position = UDim2.fromOffset(28, 95)
stageButtonsFrame.BackgroundTransparency = 1
stageButtonsFrame.Parent = autoWinPage

local stageGrid = Instance.new("UIGridLayout")
stageGrid.CellSize = UDim2.new(0.31, -4, 0, 42)
stageGrid.CellPadding = UDim2.new(0.02, 0, 0, 8)
stageGrid.Parent = stageButtonsFrame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.fromOffset(120, 34)
scanButton.Position = UDim2.new(1, -148, 0, 52)
scanButton.BackgroundColor3 = COLORS.PageServer
scanButton.BorderSizePixel = 0
scanButton.Text = "SCAN"
scanButton.TextColor3 = Color3.new(1, 1, 1)
scanButton.TextSize = 12
scanButton.Font = Enum.Font.GothamBold
scanButton.AutoButtonColor = false
scanButton.Parent = autoWinPage

local scanCorner = Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 9)
scanCorner.Parent = scanButton

local autoNextSetter, autoNextGetter = createToggle(
	autoWinPage,
	"Auto Next Stage",
	415,
	Loaded.AutoNextStage == true,
	function(value)
		autoNextEnabled = value

		if Movement then
			Movement.SetAutoNextStage(value)
		end

		if saveSettings then
			saveSettings()
		end
	end,
	COLORS.PageFarm
)

local stageStatus = Instance.new("TextLabel")
stageStatus.Size = UDim2.new(1, -56, 0, 40)
stageStatus.Position = UDim2.fromOffset(28, 485)
stageStatus.BackgroundTransparency = 1
stageStatus.Text = "Ready."
stageStatus.TextColor3 = COLORS.TextDim
stageStatus.TextSize = 12
stageStatus.Font = Enum.Font.GothamMedium
stageStatus.TextXAlignment = Enum.TextXAlignment.Left
stageStatus.Parent = autoWinPage

local function updateStageStatus(text)
	if stageStatus and stageStatus.Parent then
		stageStatus.Text = text
	end
end

local function clearStageButtons()
	for _, child in ipairs(stageButtonsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function buildStageButtons()
	clearStageButtons()

	local stages = Movement and Movement.GetStages() or {}

	for _, info in ipairs(stages) do
		local button = Instance.new("TextButton")
		button.Name = "Stage_" .. info.stage
		button.BackgroundColor3 = COLORS.Card
		button.BorderSizePixel = 0
		button.Text = "+" .. tostring(info.value) .. " WIN"
		button.TextColor3 = COLORS.Text
		button.TextSize = 12
		button.Font = Enum.Font.GothamBold
		button.AutoButtonColor = false
		button.Parent = stageButtonsFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.PageServer
		stroke.Transparency = 0.25
		stroke.Parent = button

		button.MouseEnter:Connect(function()
			tween(button, {BackgroundColor3 = COLORS.SurfaceLight}, 0.15)
		end)

		button.MouseLeave:Connect(function()
			tween(button, {BackgroundColor3 = COLORS.Card}, 0.15)
		end)

		button.MouseButton1Click:Connect(function()
			if not Movement then
				return
			end

			updateStageStatus("Scanning Stage " .. info.stage .. "...")

			task.spawn(function()
				local target = Movement.ScanStageUntilFound(info.stage, 8, 0.5)

				if not target then
					updateStageStatus("Stage " .. info.stage .. " target not found.")
					return
				end

				updateStageStatus("Flying to Stage " .. info.stage .. "...")

				local success, reason = Movement.FlyToStage(info.stage)

				if success then
					updateStageStatus("Reached Stage " .. info.stage .. ".")
				else
					updateStageStatus("Stage " .. info.stage .. ": " .. tostring(reason))
				end
			end)
		end)
	end

	autoWinPage.CanvasSize = UDim2.new(0, 0, 0, math.max(550, 110 + math.ceil(#stages / 3) * 50))
end

scanButton.MouseButton1Click:Connect(function()
	if not Movement then
		updateStageStatus("Movement module unavailable.")
		return
	end

	scanButton.Text = "SCANNING..."

	task.spawn(function()
		local targets = Movement.RefreshTargets()
		local count = 0

		for _, target in pairs(targets) do
			if target and target.Parent then
				count += 1
			end
		end

		scanButton.Text = "SCAN"
		updateStageStatus(("Found %d / 15 stage targets."):format(count))
	end)
end)

buildStageButtons()

--========================================================
-- ESP
--========================================================

createPageTitle(espPage, "ESP", "Local player and stage target visualization")

local espObjects = {}

local function clearESP()
	for playerObject, object in pairs(espObjects) do
		if object then
			pcall(function()
				object:Destroy()
			end)
		end

		espObjects[playerObject] = nil
	end
end

local function createPlayerESP(targetPlayer)
	if targetPlayer == player then
		return
	end

	local character = targetPlayer.Character

	if not character then
		return
	end

	if espObjects[targetPlayer] then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "LPT_ESP"
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	espObjects[targetPlayer] = highlight
end

local function refreshESP()
	clearESP()

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		createPlayerESP(targetPlayer)
	end
end

local espSetter, espGetter = createToggle(
	espPage,
	"Player ESP",
	95,
	Loaded.PlayerESP == true,
	function(value)
		if value then
			refreshESP()
		else
			clearESP()
		end

		Loaded.PlayerESP = value

		if saveSettings then
			saveSettings()
		end
	end,
	COLORS.PageServer
)

createCard(
	espPage,
	167,
	"ESP Info",
	"Highlights other players locally. This setting is saved.",
	90,
	COLORS.PageServer
)

espPage.CanvasSize = UDim2.new(0, 0, 0, 280)

Players.PlayerAdded:Connect(function(targetPlayer)
	if espGetter and espGetter() then
		task.wait(0.5)
		createPlayerESP(targetPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(targetPlayer)
	local object = espObjects[targetPlayer]

	if object then
		pcall(function()
			object:Destroy()
		end)
	end

	espObjects[targetPlayer] = nil
end)

--========================================================
-- SETTINGS
--========================================================

createPageTitle(settingsPage, "Settings", "Movement configuration and saved preferences")

local walkBox = createInput(
	settingsPage,
	"Walk Speed",
	95,
	speedValue,
	1,
	500,
	function(value)
		speedValue = value

		if Movement then
			Movement.SetWalkSpeed(value)
		end

		saveSettings()
	end
)

local jumpBox = createInput(
	settingsPage,
	"Jump Power",
	163,
	jumpValue,
	1,
	500,
	function(value)
		jumpValue = value

		if Movement then
			Movement.SetJumpPower(value)
		end

		saveSettings()
	end
)

local flySpeedBox = createInput(
	settingsPage,
	"Fly Speed",
	231,
	flySpeedValue,
	10,
	500,
	function(value)
		flySpeedValue = value

		if Movement then
			Movement.SetFlySpeed(value)
		end

		saveSettings()
	end
)

local flyHeightBox = createInput(
	settingsPage,
	"Fly Height",
	299,
	flyHeightValue,
	0,
	100,
	function(value)
		flyHeightValue = value

		if Movement then
			Movement.SetFlyHeight(value)
		end

		saveSettings()
	end
)

local setInfiniteJump

setInfiniteJump, infiniteJumpEnabled = createToggle(
	settingsPage,
	"Infinite Jump",
	367,
	Loaded.InfiniteJump == true,
	function(value)
		if Movement then
			Movement.SetInfiniteJump(value)
		end

		saveSettings()
	end,
	COLORS.PageFarm
)

local setNoClip

setNoClip, noClipEnabled = createToggle(
	settingsPage,
	"No Clip",
	433,
	Loaded.NoClip == true,
	function(value)
		if Movement then
			Movement.SetNoClip(value)
		end

		saveSettings()
	end,
	COLORS.PageFarm
)

settingsPage.CanvasSize = UDim2.new(0, 0, 0, 515)

--========================================================
-- SAVING
--========================================================

saveSettings = function()
	if type(writefile) ~= "function" then
		return
	end

	local data = {}

	data.WalkSpeed = speedValue
	data.JumpPower = jumpValue
	data.FlySpeed = flySpeedValue
	data.FlyHeight = flyHeightValue
	data.InfiniteJump = infiniteJumpEnabled and infiniteJumpEnabled() or false
	data.NoClip = noClipEnabled and noClipEnabled() or false
	data.PlayerESP = espGetter and espGetter() or false
	data.AutoNextStage = autoNextGetter and autoNextGetter() or false

	pcall(function()
		writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
	end)
end

--========================================================
-- SIDEBAR
--========================================================

local currentPage = nil
local sidebarButtons = {}
local sidebarIndicator = nil

local PAGE_CONFIG = {
	Information = {text = "Information", icon = "▣", accent = COLORS.PageServer},
	AutoWin = {text = "AutoWin", icon = "✦", accent = COLORS.Accent},
	ESP = {text = "ESP", icon = "◉", accent = COLORS.PageServer},
	Settings = {text = "Settings", icon = "⚙", accent = COLORS.PageSettings},
}

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

		tween(buttonData.icon, {
			TextColor3 = active and buttonData.accent or COLORS.TextDim,
		}, 0.16)
	end

	if data then
		local targetY = data.button.Position.Y.Offset + (data.button.Size.Y.Offset / 2) - 14

		if sidebarIndicator then
			tween(sidebarIndicator, {
				Position = UDim2.new(0, 12, 0, targetY),
				BackgroundColor3 = data.accent,
			}, 0.25, Enum.EasingStyle.Quint)
		else
			sidebarIndicator = Instance.new("Frame")
			sidebarIndicator.Name = "ActiveIndicator"
			sidebarIndicator.Size = UDim2.fromOffset(4, 28)
			sidebarIndicator.Position = UDim2.new(0, 12, 0, targetY)
			sidebarIndicator.BackgroundColor3 = data.accent
			sidebarIndicator.BorderSizePixel = 0
			sidebarIndicator.Parent = sidebar

			local indicatorCorner = Instance.new("UICorner")
			indicatorCorner.CornerRadius = UDim.new(1, 0)
			indicatorCorner.Parent = sidebarIndicator
		end
	end

	currentPage = name
end

local function createSidebarButton(name, order)
	local config = PAGE_CONFIG[name]
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
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local textLabel=Instance.new("TextLabel")
	textLabel.Size=UDim2.new(1,-32,1,0)
	textLabel.Position=UDim2.fromOffset(18,0)
	textLabel.BackgroundTransparency=1
	textLabel.Text=config.text
	textLabel.TextColor3=COLORS.Text
	textLabel.TextSize=14
	textLabel.Font=Enum.Font.GothamBold
	textLabel.TextXAlignment=Enum.TextXAlignment.Left
	textLabel.TextYAlignment=Enum.TextYAlignment.Center
	textLabel.Parent=button

	sidebarButtons[name]={
		button=button,
		label=textLabel,
		accent=config.accent,
	}
	
	button.MouseEnter:Connect(function()
		if currentPage ~= name then
			tween(button, {BackgroundTransparency = 0.72}, 0.15)
			tween(iconLabel, {TextColor3 = COLORS.Text}, 0.15)
			tween(textLabel, {TextColor3 = COLORS.Text}, 0.15)
		end
	end)

	button.MouseLeave:Connect(function()
		if currentPage ~= name then
			tween(button, {BackgroundTransparency = 1}, 0.15)
			tween(iconLabel, {TextColor3 = COLORS.TextDim}, 0.15)
			tween(textLabel, {TextColor3 = COLORS.TextDim}, 0.15)
		end
	end)

	button.MouseButton1Click:Connect(function()
		selectPage(name)
	end)
end

createSidebarButton("Information", 1)
createSidebarButton("AutoWin", 2)
createSidebarButton("ESP", 3)
createSidebarButton("Settings", 4)

selectPage("Information")

--========================================================
-- APPLY SAVED MOVEMENT
--========================================================

if Movement then
	Movement.SetWalkSpeed(speedValue)
	Movement.SetJumpPower(jumpValue)
	Movement.SetFlySpeed(flySpeedValue)
	Movement.SetFlyHeight(flyHeightValue)
	Movement.SetInfiniteJump(infiniteJumpEnabled and infiniteJumpEnabled() or false)
	Movement.SetNoClip(noClipEnabled and noClipEnabled() or false)
	Movement.SetAutoNextStage(autoNextGetter and autoNextGetter() or false)
end

if espGetter and espGetter() then
	refreshESP()
end

--========================================================
-- CHARACTER RESPAWN
--========================================================

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)

	if Movement then
		Movement.SetWalkSpeed(speedValue)
		Movement.SetJumpPower(jumpValue)
		Movement.SetFlySpeed(flySpeedValue)
		Movement.SetFlyHeight(flyHeightValue)
		Movement.SetInfiniteJump(infiniteJumpEnabled and infiniteJumpEnabled() or false)
		Movement.SetNoClip(noClipEnabled and noClipEnabled() or false)
	end

	if espGetter and espGetter() then
		refreshESP()
	end
end)

--========================================================
-- AUTO NEXT STAGE ENGINE
--========================================================

task.spawn(function()
	while screenGui.Parent do
		task.wait(0.3)

		if not Movement then
			continue
		end

		if not autoNextGetter or not autoNextGetter() then
			continue
		end

		if Movement.IsFlying() then
			continue
		end

		local currentStage = Movement.GetAutoNextCurrentStage()

		if not currentStage then
			currentStage = 1
			Movement.SetAutoNextCurrentStage(currentStage)
		end

		if currentStage > 15 then
			continue
		end

		local success = Movement.FlyToStage(currentStage)

		if success then
			Movement.SetAutoNextCurrentStage(currentStage + 1)
			updateStageStatus(("AutoNext reached Stage %d"):format(currentStage))
		end

		saveSettings()
	end
end)

--========================================================
-- WINDOW CONTROLS
--========================================================

local maximized = false
local minimized = false
local savedSize = nil
local savedPosition = nil

local normalSize = UDim2.new(0, 780, 0, 500)
local normalPosition = UDim2.new(0.5, -390, 0.5, -250)

local maximizedSize = UDim2.new(1, -40, 1, -40)
local maximizedPosition = UDim2.new(0, 20, 0, 20)

local minimizedSize = UDim2.new(0, 300, 0, 38)
local minimizedPosition = UDim2.new(0.5, -150, -0.060, 15)

local minimizedHover = false

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

		normalIcon.Visible = not maximized
		restoreBack.Visible = maximized
		restoreFront.Visible = maximized

		return
	end

	minimize.Visible = false
	maximize.Visible = false
	close.Visible = true

	minimize.Active = false
	maximize.Active = false
	close.Active = minimizedHover

	close.BackgroundTransparency = minimizedHover and 0 or 1
	close.TextTransparency = minimizedHover and 0 or 1

	normalIcon.Visible = false
	restoreBack.Visible = false
	restoreFront.Visible = false
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
	separator.Visible = true

	local restoreSize = savedSize or (maximized and maximizedSize or normalSize)
	local restorePosition = savedPosition or (maximized and maximizedPosition or normalPosition)

	updateMinimizedButtons()

	tween(main, {
		Size = restoreSize,
		Position = restorePosition,
	}, 0.28, Enum.EasingStyle.Quint)
end

maximize.MouseButton1Click:Connect(function()
	if minimized then
		restoreFromMinimized()
		task.wait(0.28)
	end

	maximized = not maximized

	if maximized then
		tween(main, {
			Size = maximizedSize,
			Position = maximizedPosition,
		}, 0.25, Enum.EasingStyle.Quint)
	else
		tween(main, {
			Size = normalSize,
			Position = normalPosition,
		}, 0.25, Enum.EasingStyle.Quint)
	end

	updateMinimizedButtons()
end)

minimize.MouseButton1Click:Connect(function()
	if minimized then
		restoreFromMinimized()
		return
	end

	savedSize = main.Size
	savedPosition = main.Position

	minimized = true
	minimizedHover = false

	sidebar.Visible = false
	content.Visible = false
	author.Visible = false
	separator.Visible = false

	updateMinimizedButtons()

	tween(main, {
		Size = minimizedSize,
		Position = minimizedPosition,
	}, 0.28, Enum.EasingStyle.Quint)
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

--========================================================
-- DRAG WINDOW
--========================================================

local dragging = false
local dragStart = nil
local startPosition = nil

topBar.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if minimized then
		restoreFromMinimized()
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
	clearESP()

	if Movement then
		pcall(function()
			Movement.StopFlying()
			Movement.SetNoClip(false)
			Movement.Destroy()
		end)
	end

	if screenGui.Parent then
		screenGui:Destroy()
	end
end)

saveSettings()