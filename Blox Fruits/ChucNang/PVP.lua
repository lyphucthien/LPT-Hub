local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local PVPModule = {}

--========================================================
-- PVP
--========================================================

local PVP = {
	WalkSpeed = 16,
	JumpPower = 50,

	ChangeWalkSpeed = false,
	ChangeJumpPower = false,

	WalkOnWater = true
}

local Connections = {}
local CreatedObjects = {}

--========================================================
-- HELPERS
--========================================================

local function disconnect(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

local function disconnectAll()
	for i, connection in ipairs(Connections) do
		disconnect(connection)
		Connections[i] = nil
	end
end

local function destroyObject(object)
	if object then
		pcall(function()
			object:Destroy()
		end)
	end
end

local function destroyCreatedObjects()
	for i, object in ipairs(CreatedObjects) do
		destroyObject(object)
		CreatedObjects[i] = nil
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

--========================================================
-- WALKSPEED
--========================================================

local function applyWalkSpeed()

	local humanoid = getHumanoid()

	if not humanoid then
		return
	end

	if PVP.ChangeWalkSpeed then
		humanoid.WalkSpeed = PVP.WalkSpeed
	else
		humanoid.WalkSpeed = 16
	end
end

--========================================================
-- JUMP POWER
--========================================================

local function applyJumpPower()

	local humanoid = getHumanoid()

	if not humanoid then
		return
	end

	humanoid.UseJumpPower = true

	if PVP.ChangeJumpPower then
		humanoid.JumpPower = PVP.JumpPower
	else
		humanoid.JumpPower = 50
	end
end

--========================================================
-- CHARACTER
--========================================================

local characterConnection =
	player.CharacterAdded:Connect(function(character)

		local humanoid =
			character:WaitForChild("Humanoid", 10)

		if not humanoid then
			return
		end

		task.wait(0.1)

		applyWalkSpeed()
		applyJumpPower()

		if PVP.WalkOnWater then
			setupWaterWalk()
		end
	end)

table.insert(
	Connections,
	characterConnection
)

--========================================================
-- WALK ON WATER
--========================================================

local waterConnection = nil
local waterPlatform = nil

local function removeWaterPlatform()

	if waterPlatform then

		destroyObject(waterPlatform)

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

	table.insert(
		CreatedObjects,
		part
	)
end

local function updateWaterPlatform()

	if not PVP.WalkOnWater then
		removeWaterPlatform()
		return
	end

	local root = getRoot()

	if not root then
		removeWaterPlatform()
		return
	end

	if not waterPlatform
		or not waterPlatform.Parent then

		createWaterPlatform()
	end

	if not waterPlatform then
		return
	end

	waterPlatform.CFrame =
		CFrame.new(
			root.Position.X,
			root.Position.Y - 3,
			root.Position.Z
		)
end

function setupWaterWalk()

	disconnect(waterConnection)

	waterConnection = nil

	removeWaterPlatform()

	if not PVP.WalkOnWater then
		return
	end

	createWaterPlatform()

	waterConnection =
		RunService.Heartbeat:Connect(function()

			updateWaterPlatform()

		end)

	table.insert(
		Connections,
		waterConnection
	)
end

--========================================================
-- PUBLIC SET
--========================================================

function PVPModule:Set(name, value)

	if name == "WalkSpeed" then

		local number = tonumber(value)

		if not number then
			return false
		end

		PVP.WalkSpeed =
			math.clamp(
				number,
				0,
				500
			)

		if PVP.ChangeWalkSpeed then
			applyWalkSpeed()
		end

		return true

	elseif name == "JumpPower" then

		local number = tonumber(value)

		if not number then
			return false
		end

		PVP.JumpPower =
			math.clamp(
				number,
				0,
				500
			)

		if PVP.ChangeJumpPower then
			applyJumpPower()
		end

		return true

	elseif name == "ChangeWalkSpeed" then

		PVP.ChangeWalkSpeed =
			value == true

		applyWalkSpeed()

		return true

	elseif name == "ChangeJumpPower" then

		PVP.ChangeJumpPower =
			value == true

		applyJumpPower()

		return true

	elseif name == "WalkOnWater" then

		PVP.WalkOnWater =
			value == true

		setupWaterWalk()

		return true

	end

	warn(
		"[LPT PVP] Unknown setting:",
		name
	)

	return false
end

--========================================================
-- GET
--========================================================

function PVPModule:Get(name)

	if PVP[name] ~= nil then
		return PVP[name]
	end

	return false
end

function PVPModule:GetAll()

	local result = {}

	for name, value in pairs(PVP) do
		result[name] = value
	end

	return result
end

--========================================================
-- DESTROY
--========================================================

function PVPModule:Destroy()

	PVP.WalkSpeed = 16
	PVP.JumpPower = 50

	PVP.ChangeWalkSpeed = false
	PVP.ChangeJumpPower = false
	PVP.WalkOnWater = false

	disconnectAll()

	waterConnection = nil

	removeWaterPlatform()

	local humanoid = getHumanoid()

	if humanoid then

		humanoid.WalkSpeed = 16

		humanoid.UseJumpPower = true
		humanoid.JumpPower = 50
	end

	destroyCreatedObjects()
end

return PVPModule
