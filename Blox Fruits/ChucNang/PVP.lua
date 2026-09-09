local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer

local PVPModule={}

local State={
	WalkSpeed=16,
	JumpPower=50,

	ChangeWalkSpeed=false,
	ChangeJumpPower=false,
	WalkOnWater=true
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

local function destroyObjects()

	for i,object in ipairs(CreatedObjects) do

		destroyObject(object)
		CreatedObjects[i]=nil

	end

end

--========================================================
-- CHARACTER
--========================================================

local characterConnection=nil

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
-- APPLY WALK SPEED
--========================================================

local function applyWalkSpeed()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	if State.ChangeWalkSpeed then

		humanoid.WalkSpeed=State.WalkSpeed

	else

		humanoid.WalkSpeed=16

	end

end

--========================================================
-- APPLY JUMP POWER
--========================================================

local function applyJumpPower()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	humanoid.UseJumpPower=true

	if State.ChangeJumpPower then

		humanoid.JumpPower=State.JumpPower

	else

		humanoid.JumpPower=50

	end

end

--========================================================
-- CHARACTER RESPAWN
--========================================================

local function setupCharacterListener()

	if characterConnection then
		disconnect(characterConnection)
		characterConnection=nil
	end

	characterConnection=player.CharacterAdded:Connect(function(character)

		local humanoid=character:WaitForChild(
			"Humanoid",
			5
		)

		if not humanoid then
			return
		end

		task.wait(.1)

		applyWalkSpeed()
		applyJumpPower()

	end)

	table.insert(
		Connections,
		characterConnection
	)

end

--========================================================
-- WALK ON WATER
--========================================================

local waterConnection=nil
local waterPlatform=nil

local function removeWaterPlatform()

	if waterPlatform then

		destroyObject(waterPlatform)
		waterPlatform=nil

	end

end

local function createWaterPlatform()

	removeWaterPlatform()

	local root=getRoot()

	if not root then
		return
	end

	local part=Instance.new("Part")

	part.Name="LPT_WaterWalk"
	part.Size=Vector3.new(8,1,8)
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

end

local function updateWaterPlatform()

	if not State.WalkOnWater then

		removeWaterPlatform()
		return

	end

	local root=getRoot()

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

	waterPlatform.CFrame=CFrame.new(
		root.Position.X,
		root.Position.Y-3,
		root.Position.Z
	)

end

local function setupWaterWalk()

	if waterConnection then

		disconnect(waterConnection)
		waterConnection=nil

	end

	removeWaterPlatform()

	if not State.WalkOnWater then
		return
	end

	createWaterPlatform()

	waterConnection=RunService.Heartbeat:Connect(function()

		if not State.WalkOnWater then
			return
		end

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

function PVPModule:Set(name,value)

	if name=="WalkSpeed" then

		local number=tonumber(value)

		if not number then
			return false
		end

		State.WalkSpeed=math.clamp(
			number,
			0,
			500
		)

		if State.ChangeWalkSpeed then
			applyWalkSpeed()
		end

		return true

	elseif name=="JumpPower" then

		local number=tonumber(value)

		if not number then
			return false
		end

		State.JumpPower=math.clamp(
			number,
			0,
			500
		)

		if State.ChangeJumpPower then
			applyJumpPower()
		end

		return true

	elseif name=="ChangeWalkSpeed" then

		State.ChangeWalkSpeed=value==true

		applyWalkSpeed()

		return true

	elseif name=="ChangeJumpPower" then

		State.ChangeJumpPower=value==true

		applyJumpPower()

		return true

	elseif name=="WalkOnWater" then

		State.WalkOnWater=value==true

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

	if State[name]~=nil then
		return State[name]
	end

	return nil

end

function PVPModule:GetAll()

	local result={}

	for name,value in pairs(State) do
		result[name]=value
	end

	return result

end

setupCharacterListener()

function PVPModule:Destroy()

	disconnectAll()

	characterConnection=nil
	waterConnection=nil

	removeWaterPlatform()
	destroyObjects()

	State.WalkSpeed=16
	State.JumpPower=50

	State.ChangeWalkSpeed=false
	State.ChangeJumpPower=false
	State.WalkOnWater=false

end

return PVPModule
