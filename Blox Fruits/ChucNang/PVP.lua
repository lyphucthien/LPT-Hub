local Players=game:GetService("Players")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer

local PVPModule={}

local PVP={
	WalkSpeed=16,
	JumpPower=50,

	ChangeWalkSpeed=false,
	ChangeJumpPower=false,

	WalkOnWater=true
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
-- WALKSPEED
--========================================================

local function applyWalkSpeed()

	local humanoid=getHumanoid()

	if not humanoid then
		return
	end

	if PVP.ChangeWalkSpeed then

		humanoid.WalkSpeed=
			math.clamp(
				tonumber(PVP.WalkSpeed) or 16,
				0,
				500
			)

	else

		humanoid.WalkSpeed=16

	end

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

		humanoid.JumpPower=
			math.clamp(
				tonumber(PVP.JumpPower) or 50,
				0,
				500
			)

	else

		humanoid.JumpPower=50

	end

end

local function applyMovement()

	applyWalkSpeed()
	applyJumpPower()

end

--========================================================
-- WALK ON WATER
--========================================================

local waterConnection=nil
local waterPlatform=nil

local WATER_SIZE=Vector3.new(12,1,12)

local function removeWaterPlatform()

	if waterPlatform then

		local oldPlatform=waterPlatform
		waterPlatform=nil

		pcall(function()
			oldPlatform:Destroy()
		end)

		for i,object in ipairs(CreatedObjects) do

			if object==oldPlatform then
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

--========================================================
-- FIND WATER LEVEL
--========================================================

local function findWaterLevel()

	local map=workspace:FindFirstChild("Map")

	if map then

		local waterBase=map:FindFirstChild("WaterBase-Plane")

		if waterBase and waterBase:IsA("BasePart") then

			return waterBase.Position.Y+(waterBase.Size.Y/2)

		end

	end

	return nil

end

--========================================================
-- UPDATE
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

	local waterY=findWaterLevel()

	if not waterY then

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
	-- WALK SPEED VALUE
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
	-- JUMP POWER VALUE
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
			value==true

		applyWalkSpeed()

		return true

	--====================================================
	-- CHANGE JUMP POWER
	--====================================================

	elseif name=="ChangeJumpPower" then

		PVP.ChangeJumpPower=
			value==true

		applyJumpPower()

		return true

	--====================================================
	-- WALK ON WATER
	--====================================================

	elseif name=="WalkOnWater" then

		PVP.WalkOnWater=
			value==true

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
