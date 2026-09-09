local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer

local PVPModule={}

local PVP={
	WalkSpeed=16,
	JumpPower=50,

	ChangeWalkSpeed=false,
	ChangeJumpPower=false,

	WalkOnWater=false
}

local Connections={}
local CreatedObjects={}

local function disconnect(connection)

	if connection then

		pcall(function()
			connection:Disconnect()
		end)

	end

end

local function disconnectAll()

	for i=#Connections,1,-1 do

		local connection=Connections[i]

		disconnect(connection)

		Connections[i]=nil

	end

	table.clear(Connections)

end

local function destroyObject(object)

	if object then

		pcall(function()
			object:Destroy()
		end)

	end

end

local function destroyCreatedObjects()

	for i=#CreatedObjects,1,-1 do

		local object=CreatedObjects[i]

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

		return
			value=="true"
			or value=="1"
			or value=="yes"

	end

	return false

end

--========================================================
-- MOVEMENT
--========================================================

local movementConnection=nil
local walkSpeedChangedConnection=nil
local jumpPowerChangedConnection=nil

--========================================================
-- WALK SPEED
--========================================================

local function applyWalkSpeed()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	if PVP.ChangeWalkSpeed then

		humanoid.WalkSpeed=getWalkSpeed()

	else

		humanoid.WalkSpeed=16

	end

end

local function resetWalkSpeed()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	humanoid.WalkSpeed=16

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

	if PVP.ChangeJumpPower then

		humanoid.JumpPower=getJumpPower()

	else

		humanoid.JumpPower=50

	end

end

local function resetJumpPower()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	humanoid.UseJumpPower=true
	humanoid.JumpPower=50

end

local function applyMovement()

	applyWalkSpeed()
	applyJumpPower()

end

--========================================================
-- HUMANOID PROPERTY WATCH
--========================================================

local function disconnectHumanoidConnections()

	if walkSpeedChangedConnection then

		disconnect(
			walkSpeedChangedConnection
		)

		walkSpeedChangedConnection=nil

	end

	if jumpPowerChangedConnection then

		disconnect(
			jumpPowerChangedConnection
		)

		jumpPowerChangedConnection=nil

	end

end

local function connectHumanoid(humanoid)

	disconnectHumanoidConnections()

	if not humanoid then
		return
	end

	--============================================
	-- WATCH WALKSPEED
	--============================================

	walkSpeedChangedConnection=
		humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(function()

			if not PVP.ChangeWalkSpeed then
				return
			end

			local target=getWalkSpeed()

			if humanoid.WalkSpeed~=target then

				humanoid.WalkSpeed=target

			end

		end)

	table.insert(
		Connections,
		walkSpeedChangedConnection
	)

	--============================================
	-- WATCH JUMPPOWER
	--============================================

	jumpPowerChangedConnection=
		humanoid:GetPropertyChangedSignal(
			"JumpPower"
		):Connect(function()

			if not PVP.ChangeJumpPower then
				return
			end

			humanoid.UseJumpPower=true

			local target=getJumpPower()

			if humanoid.JumpPower~=target then

				humanoid.JumpPower=target

			end

		end)

	table.insert(
		Connections,
		jumpPowerChangedConnection
	)

	applyMovement()

end

--========================================================
-- FORCE MOVEMENT
--========================================================

movementConnection=
	RunService.RenderStepped:Connect(function()

		local humanoid=getHumanoid()

		if not humanoid then
			return
		end

		--============================================
		-- WALK SPEED
		--============================================

		if PVP.ChangeWalkSpeed then

			local target=getWalkSpeed()

			if humanoid.WalkSpeed~=target then

				humanoid.WalkSpeed=target

			end

		end

		--============================================
		-- JUMP POWER
		--============================================

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
-- CHARACTER
--========================================================

local characterConnection=

	player.CharacterAdded:Connect(function(character)

		disconnectHumanoidConnections()

		local humanoid=
			character:WaitForChild(
				"Humanoid",
				10
			)

		if not humanoid then
			return
		end

		task.wait(0.15)

		connectHumanoid(humanoid)

		-- Re-enable water walk after respawn
		if PVP.WalkOnWater then

			setupWaterWalk()

		end

	end)

table.insert(
	Connections,
	characterConnection
)

--========================================================
-- INITIAL HUMANOID
--========================================================

task.spawn(function()

	local character=player.Character

	if not character then
		return
	end

	local humanoid=
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid then

		humanoid=
			character:WaitForChild(
				"Humanoid",
				10
			)

	end

	if humanoid then

		connectHumanoid(humanoid)

	end

end)

--========================================================
-- WALK ON WATER
--========================================================

local waterConnection=nil
local waterPlatform=nil

local WATER_SIZE=Vector3.new(30,1,30)
local WATER_Y_OFFSET=0

local function findWaterBase()

	local map=workspace:FindFirstChild("Map")

	if not map then
		return nil
	end

	local waterBase=map:FindFirstChild("WaterBase-Plane")

	if waterBase and waterBase:IsA("BasePart") then
		return waterBase
	end

	return nil
end

local function getWaterTop()

	local waterBase=findWaterBase()

	if not waterBase then
		return nil
	end

	return waterBase.Position.Y + waterBase.Size.Y/2
end

local function removeWaterPlatform()

	if waterPlatform then

		local old=waterPlatform
		waterPlatform=nil

		pcall(function()
			old:Destroy()
		end)

		for i=#CreatedObjects,1,-1 do

			if CreatedObjects[i]==old then
				table.remove(CreatedObjects,i)
				break
			end

		end

	end

end

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

	table.insert(CreatedObjects,part)

	return part
end

local function updateWaterPlatform()

	if not PVP.WalkOnWater then
		removeWaterPlatform()
		return
	end

	local root=getRoot()
	local humanoid=getHumanoid()

	if not root or not humanoid then
		removeWaterPlatform()
		return
	end

	local waterBase=findWaterBase()

	if not waterBase then
		removeWaterPlatform()
		return
	end

	local halfX=waterBase.Size.X/2
	local halfZ=waterBase.Size.Z/2
	local dx=math.abs(root.Position.X-waterBase.Position.X)
	local dz=math.abs(root.Position.Z-waterBase.Position.Z)

	if dx>halfX or dz>halfZ then
		removeWaterPlatform()
		return
	end

	if not waterPlatform or not waterPlatform.Parent then

		createWaterPlatform()

	end

	if not waterPlatform then
		return
	end

	local targetY=root.Position.Y-3

	waterPlatform.CFrame=CFrame.new(root.Position.X,targetY,root.Position.Z)

	if humanoid:GetState()==Enum.HumanoidStateType.Swimming then

		humanoid:ChangeState(Enum.HumanoidStateType.Running)

	end

end

--========================================================
-- SETUP
--========================================================

local function setupWaterWalk()

	disconnect(waterConnection)

	waterConnection=nil

	removeWaterPlatform()

	if not PVP.WalkOnWater then
		return
	end

	waterConnection=RunService.RenderStepped:Connect(function()

				updateWaterPlatform()

			end
		)

	table.insert(Connections,waterConnection)

end

--========================================================
-- PUBLIC SET
--========================================================

function PVPModule:Set(name,value)

	--====================================================
	-- WALK SPEED
	--====================================================

	if name=="WalkSpeed" then

		local number=
			tonumber(value)

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

		local number=
			tonumber(value)

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

		if PVP.ChangeWalkSpeed then

			applyWalkSpeed()

		else

			resetWalkSpeed()

		end

		return true

	--====================================================
	-- CHANGE JUMP POWER
	--====================================================

	elseif name=="ChangeJumpPower" then

		PVP.ChangeJumpPower=
			toBoolean(value)

		if PVP.ChangeJumpPower then

			applyJumpPower()

		else

			resetJumpPower()

		end

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

function PVPModule:Get(name)

	if PVP[name]~=nil then

		return PVP[name]

	end

	return false

end

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

	disconnectHumanoidConnections()

	disconnectAll()

	movementConnection=nil
	waterConnection=nil

	removeWaterPlatform()

	local humanoid=
		getHumanoid()

	if humanoid then

		humanoid.WalkSpeed=16

		humanoid.UseJumpPower=true
		humanoid.JumpPower=50

	end

	destroyCreatedObjects()

end

return PVPModule
