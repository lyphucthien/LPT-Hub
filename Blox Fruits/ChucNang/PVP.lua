local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer

local PVPModule={}

--========================================================
-- CONFIG
--========================================================

local PVP={
	WalkSpeed=16,
	JumpPower=50,

	ChangeWalkSpeed=false,
	ChangeJumpPower=false,

	WalkOnWater=false
}

local Connections={}
local CreatedObjects={}

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

	for i,connection in ipairs(Connections) do

		disconnect(connection)

		Connections[i]=nil

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

	for i,object in ipairs(CreatedObjects) do

		destroyObject(object)

		CreatedObjects[i]=nil

	end

	table.clear(CreatedObjects)

end

local function getCharacter()

	return player.Character

end

local function getHumanoid()

	local character=getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")

end

local function getRoot()

	local character=getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")

end

--========================================================
-- VALUE HELPERS
--========================================================

local function getWalkSpeed()

	return math.clamp(
		tonumber(PVP.WalkSpeed) or 16,
		0,
		500
	)

end

local function getJumpPower()

	return math.clamp(
		tonumber(PVP.JumpPower) or 50,
		0,
		500
	)

end

local function toBoolean(value)

	if typeof(value)=="boolean" then
		return value
	end

	if typeof(value)=="number" then
		return value~=0
	end

	if typeof(value)=="string" then

		value=value:lower()

		return value=="true"
			or value=="1"
			or value=="yes"

	end

	return false

end

--========================================================
-- WALK SPEED
--========================================================

local function applyWalkSpeed()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	local target=16

	if PVP.ChangeWalkSpeed then
		target=getWalkSpeed()
	end

	humanoid.WalkSpeed=target

end

--========================================================
-- JUMP POWER
--========================================================

local function applyJumpPower()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	humanoid.UseJumpPower=true

	local target=50

	if PVP.ChangeJumpPower then
		target=getJumpPower()
	end

	humanoid.JumpPower=target

end

local function applyMovement()

	applyWalkSpeed()
	applyJumpPower()

end

--========================================================
-- MOVEMENT LOOP
--========================================================

local movementConnection=

RunService.Heartbeat:Connect(function()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	-- WalkSpeed

	if PVP.ChangeWalkSpeed then

		local target=getWalkSpeed()

		if humanoid.WalkSpeed~=target then
			humanoid.WalkSpeed=target
		end

	end

	-- JumpPower

	if PVP.ChangeJumpPower then

		humanoid.UseJumpPower=true

		local target=getJumpPower()

		if humanoid.JumpPower~=target then
			humanoid.JumpPower=target
		end

	end

end)

table.insert(
	Connections,
	movementConnection
)

--========================================================
-- WALK ON WATER
--========================================================

local waterConnection=nil
local waterPlatform=nil

local WATER_SIZE=Vector3.new(12,1,12)

--========================================================
-- REMOVE WATER PLATFORM
--========================================================

local function removeWaterPlatform()

	if not waterPlatform then
		return
	end

	local oldPlatform=waterPlatform

	waterPlatform=nil

	pcall(function()
		oldPlatform:Destroy()
	end)

	for i=#CreatedObjects,1,-1 do

		if CreatedObjects[i]==oldPlatform then
			table.remove(CreatedObjects,i)
			break
		end

	end

end

--========================================================
-- CREATE WATER PLATFORM
--========================================================

local function createWaterPlatform()

	removeWaterPlatform()

	local root=getRoot()

	if not root then
		return nil
	end

	local part=Instance.new("Part")

	part.Name="LPT_WaterWalk"
	part.Size=WATER_SIZE

	part.Anchored=true
	part.CanCollide=true
	part.CanTouch=false
	part.CanQuery=false

	part.Transparency=1

	part.Parent=workspace

	waterPlatform=part

	table.insert(
		CreatedObjects,
		part
	)

	return part

end

--========================================================
-- FIND WATER
--========================================================

local function findWaterBase()

	local map=workspace:FindFirstChild("Map")

	if not map then
		return nil
	end

	local waterBase=map:FindFirstChild("WaterBase-Plane")

	if waterBase
		and waterBase:IsA("BasePart") then

		return waterBase

	end

	return nil

end

local function findWaterLevel()

	local waterBase=findWaterBase()

	if not waterBase then
		return nil
	end

	return waterBase.Position.Y+
		(waterBase.Size.Y/2)

end

--========================================================
-- UPDATE WATER PLATFORM
--========================================================

local function updateWaterPlatform()

	if not PVP.WalkOnWater then

		removeWaterPlatform()

		return

	end

	local root=getRoot()

	if not root then

		removeWaterPlatform()

		return

	end

	local waterBase=findWaterBase()

	if not waterBase then

		removeWaterPlatform()

		return

	end

	local waterY=
		waterBase.Position.Y+
		(waterBase.Size.Y/2)

	-- Chỉ tạo platform khi nhân vật đang nằm
	-- trong phạm vi của WaterBase-Plane

	local halfX=waterBase.Size.X/2
	local halfZ=waterBase.Size.Z/2

	local dx=
		math.abs(
			root.Position.X-
			waterBase.Position.X
		)

	local dz=
		math.abs(
			root.Position.Z-
			waterBase.Position.Z
		)

	if dx>halfX or dz>halfZ then

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

	waterPlatform.CFrame=
		CFrame.new(
			root.Position.X,
			waterY-0.5,
			root.Position.Z
		)

end

--========================================================
-- SETUP WATER WALK
--========================================================

local function setupWaterWalk()

	disconnect(waterConnection)

	waterConnection=nil

	removeWaterPlatform()

	if not PVP.WalkOnWater then
		return
	end

	waterConnection=

		RunService.Heartbeat:Connect(function()

			updateWaterPlatform()

		end)

	table.insert(
		Connections,
		waterConnection
	)

end

--========================================================
-- CHARACTER
--========================================================

local characterConnection=

	player.CharacterAdded:Connect(function(character)

		local humanoid=
			character:WaitForChild(
				"Humanoid",
				10
			)

		if not humanoid then
			return
		end

		task.wait(.1)

		applyMovement()

		if PVP.WalkOnWater then
			setupWaterWalk()
		end

	end)

table.insert(
	Connections,
	characterConnection
)

--========================================================
-- PUBLIC SET
--========================================================

function PVPModule:Set(name,value)

	--====================================================
	-- WALK SPEED
	--====================================================

	if name=="WalkSpeed" then

		local number=tonumber(value)

		if not number then
			return false
		end

		PVP.WalkSpeed=
			math.clamp(
				number,
				0,
				500
			)

		if PVP.ChangeWalkSpeed then
			applyWalkSpeed()
		end

		return true

	--====================================================
	-- JUMP POWER
	--====================================================

	elseif name=="JumpPower" then

		local number=tonumber(value)

		if not number then
			return false
		end

		PVP.JumpPower=
			math.clamp(
				number,
				0,
				500
			)

		if PVP.ChangeJumpPower then
			applyJumpPower()
		end

		return true

	--====================================================
	-- CHANGE WALK SPEED
	--====================================================

	elseif name=="ChangeWalkSpeed" then

		PVP.ChangeWalkSpeed=
			toBoolean(value)

		applyWalkSpeed()

		return true

	--====================================================
	-- CHANGE JUMP POWER
	--====================================================

	elseif name=="ChangeJumpPower" then

		PVP.ChangeJumpPower=
			toBoolean(value)

		applyJumpPower()

		return true

	--====================================================
	-- WALK ON WATER
	--====================================================

	elseif name=="WalkOnWater" then

		PVP.WalkOnWater=
			toBoolean(value)

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

	if PVP[name]~=nil then
		return PVP[name]
	end

	return false

end

--========================================================
-- GET ALL
--========================================================

function PVPModule:GetAll()

	local result={}

	for name,value in pairs(PVP) do

		result[name]=value

	end

	return result

end

--========================================================
-- DESTROY
--========================================================

function PVPModule:Destroy()

	PVP.WalkSpeed=16
	PVP.JumpPower=50

	PVP.ChangeWalkSpeed=false
	PVP.ChangeJumpPower=false
	PVP.WalkOnWater=false

	disconnectAll()

	movementConnection=nil
	waterConnection=nil

	removeWaterPlatform()

	local humanoid=getHumanoid()

	if humanoid then

		humanoid.WalkSpeed=16

		humanoid.UseJumpPower=true
		humanoid.JumpPower=50

	end

	destroyCreatedObjects()

end

return PVPModule
