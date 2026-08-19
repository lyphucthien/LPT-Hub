local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")

local LocalPlayer=Players.LocalPlayer
local Module={}

--========================================================
-- CONFIG
--========================================================

local ENABLE_FLY_TO_WIN=true
local ARRIVAL_DISTANCE=3
local FLY_TIMEOUT=45
local DEFAULT_FLY_SPEED=90
local CONTACT_OFFSET=0.15
local CONTACT_HOLD_TIME=1
local STRUCTURE_NAME="Structure"
local MAX_PARENT_SEARCH_DEPTH=20

--========================================================
-- WIN STAGES
--========================================================

local WIN_STAGES={
	{stage=1,value=1,text="Stage 1 (+1 Win)"},
	{stage=2,value=3,text="Stage 2 (+3 Wins)"},
	{stage=3,value=10,text="Stage 3 (+10 Wins)"},
	{stage=4,value=20,text="Stage 4 (+20 Wins)"},
	{stage=5,value=60,text="Stage 5 (+60 Wins)"},
	{stage=6,value=100,text="Stage 6 (+100 Wins)"},
	{stage=7,value=150,text="Stage 7 (+150 Wins)"},
	{stage=8,value=300,text="Stage 8 (+300 Wins)"},
	{stage=9,value=500,text="Stage 9 (+500 Wins)"},
	{stage=10,value=1000,text="Stage 10 (+1K Wins)"},
	{stage=11,value=2500,text="Stage 11 (+2.5K Wins)"},
	{stage=12,value=10000,text="Stage 12 (+10K Wins)"},
	{stage=13,value=25000,text="Stage 13 (+25K Wins)"},
	{stage=14,value=50000,text="Stage 14 (+50K Wins)"},
	{stage=15,value=150000,text="Stage 15 (+150K Wins)"},
}

--========================================================
-- STATE
--========================================================

local State={
	WalkSpeed=16,
	JumpPower=50,
	InfiniteJump=false,
	NoClip=false,
	Flying=false,
	FlySpeed=DEFAULT_FLY_SPEED,
	FlyHeight=0,
	CurrentTarget=nil,
	CurrentStage=nil,
	TargetCache={},
	StageTargetCache={},
	StageContainerCache={},
	Scanning=false,
}

local Connections={}
local OriginalCollision={}

--========================================================
-- UTILITY
--========================================================

local function disconnect(name)
	local connection=Connections[name]
	if connection then
		pcall(function() connection:Disconnect() end)
		Connections[name]=nil
	end
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character=getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character=getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isBasePart(object)
	return object and object:IsA("BasePart") and object.Parent~=nil
end

local function lower(value)
	return string.lower(tostring(value or ""))
end

local function getNumber(value,minimum,maximum,fallback)
	value=tonumber(value)
	if value==nil then return fallback end
	return math.clamp(value,minimum,maximum)
end

--========================================================
-- CHARACTER SETTINGS
--========================================================

local function applyCharacterSettings()
	local humanoid=getHumanoid()
	if not humanoid then return end

	pcall(function()
		humanoid.UseJumpPower=true
		humanoid.WalkSpeed=State.WalkSpeed
		humanoid.JumpPower=State.JumpPower
	end)
end

function Module.SetWalkSpeed(value)
	State.WalkSpeed=getNumber(value,0,500,State.WalkSpeed)
	if not State.Flying then applyCharacterSettings() end
	return true
end

function Module.GetWalkSpeed()
	return State.WalkSpeed
end

function Module.SetJumpPower(value)
	State.JumpPower=getNumber(value,0,500,State.JumpPower)
	if not State.Flying then applyCharacterSettings() end
	return true
end

function Module.GetJumpPower()
	return State.JumpPower
end

function Module.SetFlySpeed(value)
	State.FlySpeed=getNumber(value,10,500,State.FlySpeed)
	return true
end

function Module.GetFlySpeed()
	return State.FlySpeed
end

function Module.SetFlyHeight(value)
	State.FlyHeight=getNumber(value,0,100,State.FlyHeight)
	return true
end

function Module.GetFlyHeight()
	return State.FlyHeight
end

--========================================================
-- INFINITE JUMP
--========================================================

function Module.SetInfiniteJump(enabled)
	State.InfiniteJump=enabled==true
	disconnect("InfiniteJump")

	if State.InfiniteJump then
		Connections.InfiniteJump=UserInputService.JumpRequest:Connect(function()
			if not State.InfiniteJump then return end
			local humanoid=getHumanoid()
			if humanoid then
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
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

local function rememberCollision(character)
	if not character then return end

	for _,object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") and OriginalCollision[object]==nil then
			OriginalCollision[object]=object.CanCollide
		end
	end
end

local function restoreCollision(character)
	for object,original in pairs(OriginalCollision) do
		if object and object.Parent then
			pcall(function() object.CanCollide=original end)
		end
	end

	table.clear(OriginalCollision)
end

function Module.SetNoClip(enabled)
	State.NoClip=enabled==true

	local character=getCharacter()

	if State.NoClip then
		if character then rememberCollision(character) end
	else
		restoreCollision(character)
	end

	return true
end

function Module.GetNoClip()
	return State.NoClip
end

--========================================================
-- STAGE NAME
--========================================================

local function getStageNumberFromName(name)
	name=lower(name)

	local number=name:match("^stage(%d+)$")
	if number then return tonumber(number) end

	number=name:match("^stage%-(%d+)$")
	if number then return tonumber(number) end

	number=name:match("^stage_(%d+)$")
	if number then return tonumber(number) end

	number=name:match("^stage%s+(%d+)$")
	if number then return tonumber(number) end

	number=name:match("^(%d+)stage$")
	if number then return tonumber(number) end

	return nil
end

--========================================================
-- STRUCTURE
--========================================================

local function findStructure()
	local structure=workspace:FindFirstChild(STRUCTURE_NAME)
	if structure then return structure end

	structure=workspace:FindFirstChild(STRUCTURE_NAME,true)
	if structure then return structure end

	return nil
end

--========================================================
-- EXACT STAGE CONTAINER
--========================================================

local function findStageContainer(stageNumber)
	local cached=State.StageContainerCache[stageNumber]
	if cached and cached.Parent then return cached end

	local structure=findStructure()
	if not structure then return nil end

	local exactNames={
		"Stage"..stageNumber,
		"Stage-"..stageNumber,
		"Stage_"..stageNumber,
		"Stage "..stageNumber,
		"stage"..stageNumber,
		"stage-"..stageNumber,
		"stage_"..stageNumber,
		"stage "..stageNumber,
	}

	for _,name in ipairs(exactNames) do
		local object=structure:FindFirstChild(name)
		if object then
			State.StageContainerCache[stageNumber]=object
			return object
		end
	end

	for _,object in ipairs(structure:GetDescendants()) do
		local detected=getStageNumberFromName(object.Name)
		if detected==stageNumber then
			State.StageContainerCache[stageNumber]=object
			return object
		end
	end

	return nil
end

--========================================================
-- INTERACTIVE
--========================================================

local function hasInteractiveObject(part)
	if not part then return false end
	if part:FindFirstChild("TouchInterest") then return true end
	if part:FindFirstChildOfClass("ProximityPrompt") then return true end
	if part:FindFirstChildOfClass("ClickDetector") then return true end
	return false
end

--========================================================
-- BAD OBJECT
--========================================================

local function isBadName(name)
	name=lower(name)

	return name:find("npc",1,true)
		or name:find("enemy",1,true)
		or name:find("dummy",1,true)
		or name:find("ballerina",1,true)
		or name:find("chocolita",1,true)
		or name=="character"
end

--========================================================
-- NAME SCORE
--========================================================

local function getNameScore(name)
	name=lower(name)
	local score=0

	if name=="getwinbutton" or name=="claimwinbutton" then score+=100000
	elseif name=="winbutton" then score+=90000
	elseif name=="getwin" then score+=85000
	elseif name=="claimwin" then score+=80000
	elseif name=="winblock" then score+=75000
	elseif name=="win" then score+=70000
	end

	if name:find("getwin",1,true) then score+=50000 end
	if name:find("claimwin",1,true) then score+=50000 end
	if name:find("winbutton",1,true) then score+=45000 end
	if name:find("win_button",1,true) then score+=45000 end
	if name:find("claim",1,true) then score+=30000 end
	if name:find("finish",1,true) then score+=25000 end
	if name:find("award",1,true) then score+=25000 end
	if name:find("button",1,true) then score+=20000 end
	if name=="win" then score+=20000 end
	if name:find("win",1,true) then score+=15000 end

	return score
end

--========================================================
-- TEXT
--========================================================

local function collectObjectText(object)
	if not object then return "" end

	local texts={tostring(object.Name)}
	local parent=object.Parent

	for _=1,MAX_PARENT_SEARCH_DEPTH do
		if not parent then break end
		table.insert(texts,tostring(parent.Name))
		parent=parent.Parent
	end

	for _,descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			local success,text=pcall(function() return descendant.Text end)

			if success and text and text~="" then
				table.insert(texts,tostring(text))
			end
		end
	end

	return table.concat(texts," ")
end

--========================================================
-- WIN VALUE MATCH
--========================================================

local function matchesWinText(text,winValue)
	text=lower(text):gsub(",",""):gsub("%s+","")
	local value=tostring(winValue)

	return text:find("+"..value.."win",1,true)~=nil
		or text:find("+"..value.."wins",1,true)~=nil
		or text:find(value.."win",1,true)~=nil
		or text:find(value.."wins",1,true)~=nil
end

--========================================================
-- TARGET SCORE
--========================================================

local function scoreTarget(part,stageNumber,winValue)
	if not isBasePart(part) then
		return -math.huge
	end

	local score=getNameScore(part.Name)
	local text=collectObjectText(part)

	-- Strong stage restriction.
	if findStageContainer(stageNumber) then
		local container=findStageContainer(stageNumber)

		if not part:IsDescendantOf(container) and part~=container then
			return -math.huge
		end

		score+=100000
	end

	if matchesWinText(text,winValue) then
		score+=100000
	end

	if hasInteractiveObject(part) then
		score+=50000
	end

	if part:FindFirstChild("TouchInterest") then
		score+=20000
	end

	if part:FindFirstChildOfClass("ProximityPrompt") then
		score+=15000
	end

	if part:FindFirstChildOfClass("ClickDetector") then
		score+=10000
	end

	if isBadName(part.Name) then
		score-=150000
	end

	local name=lower(part.Name)

	if name=="hitbox" or name:find("hitbox",1,true) then
		if hasInteractiveObject(part) then
			score-=10000
		else
			score-=80000
		end
	end

	if part.Transparency>=0.99 and not hasInteractiveObject(part) then
		score-=30000
	end

	return score
end

--========================================================
-- FIND TARGET INSIDE EXACT STAGE
--========================================================

local function findTargetInStage(container,stageNumber,winValue)
	if not container then return nil end

	local bestTarget=nil
	local bestScore=-math.huge

	for _,object in ipairs(container:GetDescendants()) do
		if object:IsA("BasePart") then
			local score=scoreTarget(object,stageNumber,winValue)

			if score>bestScore then
				bestScore=score
				bestTarget=object
			end
		end
	end

	if container:IsA("BasePart") then
		local score=scoreTarget(container,stageNumber,winValue)

		if score>bestScore then
			bestScore=score
			bestTarget=container
		end
	end

	if bestTarget and bestScore>0 then
		return bestTarget
	end

	return nil
end

--========================================================
-- REFRESH TARGETS
--========================================================

function Module.RefreshTargets()
	if State.Scanning then
		return State.StageTargetCache
	end

	State.Scanning=true

	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)

	-- Find all stage containers first.
	for _,info in ipairs(WIN_STAGES) do
		findStageContainer(info.stage)
	end

	-- Find exactly one target inside each exact Stage.
	for _,info in ipairs(WIN_STAGES) do
		local container=State.StageContainerCache[info.stage]

		if container then
			local target=findTargetInStage(
				container,
				info.stage,
				info.value
			)

			if isBasePart(target) then
				State.StageTargetCache[info.stage]=target
				State.TargetCache[info.value]=target
			end
		end
	end

	State.Scanning=false

	return State.StageTargetCache
end

--========================================================
-- TARGET API
--========================================================

function Module.GetTarget(value)
	value=tonumber(value)

	if not value then return nil end

	local target=State.TargetCache[value]

	if isBasePart(target) then
		return target
	end

	Module.RefreshTargets()
	return State.TargetCache[value]
end

function Module.GetStageTarget(stageNumber)
	stageNumber=tonumber(stageNumber)

	if not stageNumber then return nil end

	local target=State.StageTargetCache[stageNumber]

	if isBasePart(target) then
		return target
	end

	Module.RefreshTargets()
	return State.StageTargetCache[stageNumber]
end

function Module.GetTargets()
	return State.TargetCache
end

function Module.GetStage(stageNumber)
	stageNumber=tonumber(stageNumber)

	if not stageNumber then return nil end

	for _,info in ipairs(WIN_STAGES) do
		if info.stage==stageNumber then
			return info
		end
	end

	return nil
end

function Module.GetStages()
	return WIN_STAGES
end

--========================================================
-- CONTACT POSITION
--========================================================

local function getContactPosition(part)
	if not isBasePart(part) then
		return nil
	end

	-- Put the HumanoidRootPart almost directly on the top of the target.
	-- This is much lower than the old position and allows the character
	-- to actually intersect/touch the win part.
	return Vector3.new(
		part.Position.X,
		part.Position.Y+(part.Size.Y/2)+CONTACT_OFFSET+State.FlyHeight,
		part.Position.Z
	)
end

--========================================================
-- FLY STATE
--========================================================

function Module.StopFlying()
	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil
end

function Module.IsFlying()
	return State.Flying
end

--========================================================
-- FLY TO PART
--========================================================

function Module.FlyToPart(part,stageNumber)
	if not ENABLE_FLY_TO_WIN then
		return false,"Fly disabled"
	end

	if not isBasePart(part) then
		return false,"Invalid target"
	end

	if State.Flying then
		return false,"Already flying"
	end

	local character=getCharacter()
	local root=getRoot()
	local humanoid=getHumanoid()

	if not character then return false,"Character nil" end
	if not root then return false,"HumanoidRootPart nil" end
	if not humanoid then return false,"Humanoid nil" end
	if not part.Parent then return false,"Target disappeared" end

	State.Flying=true
	State.CurrentTarget=part
	State.CurrentStage=stageNumber

	local oldAutoRotate=humanoid.AutoRotate
	local oldPlatformStand=humanoid.PlatformStand

	pcall(function()
		humanoid.AutoRotate=false
		humanoid.PlatformStand=true
	end)

	local startTime=os.clock()
	local reached=false

	while State.Flying
		and character.Parent
		and root.Parent
		and part.Parent
		and os.clock()-startTime<FLY_TIMEOUT
	do
		local destination=getContactPosition(part)

		if not destination then
			break
		end

		local current=root.Position
		local difference=destination-current
		local distance=difference.Magnitude

		if distance<=ARRIVAL_DISTANCE then
			reached=true
			break
		end

		local dt=RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		local speed=math.max(10,State.FlySpeed)
		local step=math.min(distance,speed*dt)
		local nextPosition=current+difference.Unit*step

		pcall(function()
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=CFrame.new(nextPosition)
			humanoid.PlatformStand=true
			humanoid.AutoRotate=false
		end)
	end

	-- CONTACT PHASE
	if reached and State.Flying and root.Parent and part.Parent then
		local holdStart=os.clock()

		while State.Flying
			and root.Parent
			and part.Parent
			and os.clock()-holdStart<CONTACT_HOLD_TIME
		do
			local contactPosition=getContactPosition(part)

			if contactPosition then
				pcall(function()
					root.AssemblyLinearVelocity=Vector3.zero
					root.AssemblyAngularVelocity=Vector3.zero
					root.CFrame=CFrame.new(contactPosition)
					humanoid.PlatformStand=true
					humanoid.AutoRotate=false
				end)
			end

			RunService.Heartbeat:Wait()
		end
	end

	local stopped=not State.Flying

	pcall(function()
		humanoid.AutoRotate=oldAutoRotate
		humanoid.PlatformStand=oldPlatformStand
	end)

	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil

	if reached then
		return true
	end

	if stopped then
		return false,"Stopped"
	end

	return false,"Could not reach target"
end

--========================================================
-- FLY TO STAGE
--========================================================

function Module.FlyToStage(stageNumber)
	stageNumber=tonumber(stageNumber)

	if not stageNumber then
		return false,"Invalid stage"
	end

	local stageInfo=Module.GetStage(stageNumber)

	if not stageInfo then
		return false,"Stage does not exist"
	end

	local target=State.StageTargetCache[stageNumber]

	if not isBasePart(target) then
		target=Module.GetTarget(stageInfo.value)
	end

	if not isBasePart(target) then
		return false,("No target for Stage %d"):format(stageNumber)
	end

	return Module.FlyToPart(target,stageNumber)
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(winAmount)
	winAmount=tonumber(winAmount)

	if not winAmount then
		return false,"Invalid Win amount"
	end

	for _,info in ipairs(WIN_STAGES) do
		if info.value==winAmount then
			return Module.FlyToStage(info.stage)
		end
	end

	return false,("No stage for +%s Win"):format(tostring(winAmount))
end

--========================================================
-- CHARACTER SETTINGS LOOP
--========================================================

Connections.CharacterSettings=RunService.Heartbeat:Connect(function()
	local humanoid=getHumanoid()

	if not humanoid then return end

	if humanoid.UseJumpPower~=true then
		pcall(function() humanoid.UseJumpPower=true end)
	end

	if not State.Flying then
		if math.abs(humanoid.WalkSpeed-State.WalkSpeed)>0.01 then
			pcall(function() humanoid.WalkSpeed=State.WalkSpeed end)
		end

		if math.abs(humanoid.JumpPower-State.JumpPower)>0.01 then
			pcall(function() humanoid.JumpPower=State.JumpPower end)
		end
	end
end)

--========================================================
-- NO CLIP LOOP
--========================================================

Connections.NoClip=RunService.Stepped:Connect(function()
	if not State.NoClip then return end

	local character=getCharacter()
	if not character then return end

	rememberCollision(character)

	for _,object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			pcall(function() object.CanCollide=false end)
		end
	end
end)

--========================================================
-- CHARACTER ADDED
--========================================================

Connections.CharacterAdded=LocalPlayer.CharacterAdded:Connect(function(character)
	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil

	table.clear(OriginalCollision)
	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)

	local humanoid=character:WaitForChild("Humanoid",10)

	if humanoid then
		task.wait(0.15)
		applyCharacterSettings()

		if State.NoClip then
			rememberCollision(character)
		end
	end
end)

--========================================================
-- INITIAL
--========================================================

task.defer(function()
	task.wait(0.5)
	applyCharacterSettings()

	if State.NoClip then
		local character=getCharacter()
		if character then rememberCollision(character) end
	end
end)

--========================================================
-- STATE
--========================================================

function Module.GetState()
	local foundTargets=0

	for _,info in ipairs(WIN_STAGES) do
		if isBasePart(State.StageTargetCache[info.stage]) then
			foundTargets+=1
		end
	end

	return {
		WalkSpeed=State.WalkSpeed,
		JumpPower=State.JumpPower,
		InfiniteJump=State.InfiniteJump,
		NoClip=State.NoClip,
		Flying=State.Flying,
		FlySpeed=State.FlySpeed,
		FlyHeight=State.FlyHeight,
		CurrentTarget=State.CurrentTarget,
		CurrentStage=State.CurrentStage,
		TargetCount=#WIN_STAGES,
		FoundTargetCount=foundTargets,
		FoundTargets=State.StageTargetCache,
		StateContainers=State.StageContainerCache,
		Scanning=State.Scanning,
	}
end

--========================================================
-- DESTROY
--========================================================

function Module.Destroy()
	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil

	for name,connection in pairs(Connections) do
		if connection then
			pcall(function() connection:Disconnect() end)
		end
		Connections[name]=nil
	end

	local character=getCharacter()

	if character then
		restoreCollision(character)
	end

	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)
	table.clear(OriginalCollision)
end

return Module
