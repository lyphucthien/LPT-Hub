local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local MOVEMENT_MODULE_URL = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/%2B1%20Speed%20Keyboard%20Escape/ChucNang.luau"

local Movement = nil
local movementLoadError = nil

--========================================================
-- LOCAL FALLBACK MOVEMENT MODULE
--========================================================

local LOCAL_MOVEMENT_SOURCE = [[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Module = {}

local WIN_STAGES = {
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

local State = {
	WalkSpeed=16,
	JumpPower=50,
	InfiniteJump=false,
	NoClip=false,
	Flying=false,
	FlySpeed=90,
	FlyHeight=5,
	CurrentTarget=nil,
	CurrentStage=nil,
	TargetCache={},
	StageTargetCache={},
	StageContainerCache={},
	Scanning=false,
}

local Connections = {}
local OriginalCollision = {}

local function disconnect(name)
	local connection = Connections[name]
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

local function getNumber(value,min,max,fallback)
	value=tonumber(value)
	if value==nil then return fallback end
	return math.clamp(value,min,max)
end

local function applyCharacterSettings()
	local humanoid=getHumanoid()
	if not humanoid then return end
	pcall(function()
		humanoid.UseJumpPower=true
		humanoid.WalkSpeed=State.WalkSpeed
		humanoid.JumpPower=State.JumpPower
	end)
end

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

local function getStageNumberFromName(name)
	name=lower(name)
	local number=name:match("^stage(%d+)$") or name:match("^stage%-(%d+)$") or name:match("^stage_(%d+)$") or name:match("^stage%s+(%d+)$") or name:match("^(%d+)stage$")
	return number and tonumber(number) or nil
end

local function belongsToStage(part,stageNumber)
	local current=part
	for _=1,20 do
		if not current then break end
		if getStageNumberFromName(current.Name)==stageNumber then return true end
		current=current.Parent
	end
	return false
end

local function findStructure()
	local structure=workspace:FindFirstChild("Structure")
	if structure then return structure end
	structure=workspace:FindFirstChild("Structure",true)
	if structure then return structure end
	for _,object in ipairs(workspace:GetDescendants()) do
		if lower(object.Name)=="structure" then return object end
	end
	return nil
end

local function findStageContainer(stageNumber)
	local cached=State.StageContainerCache[stageNumber]
	if cached and cached.Parent then return cached end

	local structure=findStructure()
	if not structure then return nil end

	for _,child in ipairs(structure:GetChildren()) do
		if getStageNumberFromName(child.Name)==stageNumber then
			State.StageContainerCache[stageNumber]=child
			return child
		end
	end

	for _,object in ipairs(structure:GetDescendants()) do
		if getStageNumberFromName(object.Name)==stageNumber then
			State.StageContainerCache[stageNumber]=object
			return object
		end
	end

	return nil
end

local function hasInteractiveObject(part)
	return part:FindFirstChild("TouchInterest") or part:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ClickDetector")
end

local function isBadName(name)
	name=lower(name)
	return name:find("npc",1,true) or name:find("enemy",1,true) or name:find("dummy",1,true) or name:find("ballerina",1,true) or name:find("chocolita",1,true) or name=="character"
end

local function getNameScore(name)
	name=lower(name)
	local score=0
	if name=="getwinbutton" or name=="claimwinbutton" then
		score+=100000
	elseif name=="winbutton" then
		score+=90000
	elseif name=="getwin" then
		score+=85000
	elseif name=="claimwin" then
		score+=80000
	elseif name=="winblock" then
		score+=75000
	elseif name=="win" then
		score+=70000
	end
	if name:find("getwin",1,true) then score+=50000 end
	if name:find("claimwin",1,true) then score+=50000 end
	if name:find("winbutton",1,true) then score+=45000 end
	if name:find("claim",1,true) then score+=30000 end
	if name:find("finish",1,true) then score+=25000 end
	if name:find("award",1,true) then score+=25000 end
	if name:find("button",1,true) then score+=20000 end
	if name:find("win",1,true) then score+=15000 end
	return score
end

local function scoreTarget(part,stageNumber)
	if not isBasePart(part) then return -math.huge end

	local score=getNameScore(part.Name)
	local parent=part.Parent

	for _=1,6 do
		if not parent then break end
		local parentName=lower(parent.Name)
		if parentName:find("win",1,true) then score+=25000 end
		if parentName:find("button",1,true) then score+=15000 end
		if parentName:find("claim",1,true) then score+=20000 end
		parent=parent.Parent
	end

	score+=belongsToStage(part,stageNumber) and 30000 or -30000

	if hasInteractiveObject(part) then score+=30000 end
	if isBadName(part.Name) then score-=100000 end

	local name=lower(part.Name)
	if name=="hitbox" or name:find("hitbox",1,true) then
		score-=hasInteractiveObject(part) and 5000 or 50000
	end

	if part.Transparency>=0.99 then
		score+=hasInteractiveObject(part) and 5000 or -10000
	end

	return score
end

local function findTargetInStage(container,stageNumber)
	if not container then return nil end

	local bestTarget
	local bestScore=-math.huge

	for _,object in ipairs(container:GetDescendants()) do
		if object:IsA("BasePart") then
			local score=scoreTarget(object,stageNumber)
			if score>bestScore then
				bestScore=score
				bestTarget=object
			end
		end
	end

	if container:IsA("BasePart") then
		local score=scoreTarget(container,stageNumber)
		if score>bestScore then
			bestScore=score
			bestTarget=container
		end
	end

	return bestTarget and bestScore>0 and bestTarget or nil
end

function Module.RefreshTargets()
	if State.Scanning then return State.TargetCache end
	State.Scanning=true

	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(State.StageContainerCache)

	for _,info in ipairs(WIN_STAGES) do
		local container=findStageContainer(info.stage)
		if container then
			local target=findTargetInStage(container,info.stage)
			if isBasePart(target) then
				State.StageTargetCache[info.stage]=target
				State.TargetCache[info.value]=target
			end
		end
		task.wait()
	end

	State.Scanning=false
	return State.TargetCache
end

function Module.GetTarget(value)
	value=tonumber(value)
	if not value then return nil end

	local target=State.TargetCache[value]
	if isBasePart(target) then return target end

	Module.RefreshTargets()
	return State.TargetCache[value]
end

function Module.GetTargets()
	Module.RefreshTargets()
	return State.TargetCache
end

function Module.GetStageTarget(stageNumber)
	stageNumber=tonumber(stageNumber)
	if not stageNumber then return nil end

	local target=State.StageTargetCache[stageNumber]
	if isBasePart(target) then return target end

	Module.RefreshTargets()
	return State.StageTargetCache[stageNumber]
end

function Module.GetStage(stageNumber)
	stageNumber=tonumber(stageNumber)
	if not stageNumber then return nil end

	for _,info in ipairs(WIN_STAGES) do
		if info.stage==stageNumber then return info end
	end
	return nil
end

function Module.GetStages()
	return WIN_STAGES
end

local function getTargetPosition(part)
	if not isBasePart(part) then return nil end
	return Vector3.new(part.Position.X,part.Position.Y+part.Size.Y/2+2+State.FlyHeight,part.Position.Z)
end

function Module.StopFlying()
	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil
end

function Module.IsFlying()
	return State.Flying
end

function Module.FlyToPart(part,stageNumber)
	if not isBasePart(part) then return false,"Invalid target" end
	if State.Flying then return false,"Already flying" end

	local root=getRoot()
	local humanoid=getHumanoid()
	if not root or not humanoid then return false,"Character not ready" end

	State.Flying=true
	State.CurrentTarget=part
	State.CurrentStage=stageNumber

	local oldAutoRotate=humanoid.AutoRotate
	local oldPlatformStand=humanoid.PlatformStand
	humanoid.AutoRotate=false
	humanoid.PlatformStand=true

	local started=os.clock()
	local reached=false

	while State.Flying and root.Parent and part.Parent and os.clock()-started<45 do
		local destination=getTargetPosition(part)
		if not destination then break end

		local difference=destination-root.Position
		local distance=difference.Magnitude

		if distance<=4 then
			reached=true
			break
		end

		local dt=RunService.Heartbeat:Wait()
		if not State.Flying then break end

		local speed=math.max(10,State.FlySpeed)
		local step=math.min(distance,speed*dt)

		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=CFrame.new(root.Position+difference.Unit*step)
		humanoid.PlatformStand=true
		humanoid.AutoRotate=false
	end

	if reached and State.Flying and root.Parent and part.Parent then
		local destination=getTargetPosition(part)
		if destination then
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=CFrame.new(destination)

			local holdStart=os.clock()
			while State.Flying and root.Parent and part.Parent and os.clock()-holdStart<0.8 do
				local finalPosition=getTargetPosition(part)
				if finalPosition then root.CFrame=CFrame.new(finalPosition) end
				RunService.Heartbeat:Wait()
			end
		end
	end

	local stopped=not State.Flying

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate=oldAutoRotate
		humanoid.PlatformStand=oldPlatformStand
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		humanoid.WalkSpeed=State.WalkSpeed
		humanoid.JumpPower=State.JumpPower
	end

	State.Flying=false
	State.CurrentTarget=nil
	State.CurrentStage=nil

	if reached then return true end
	if stopped then return false,"Stopped" end
	return false,"Could not reach target"
end

function Module.FlyToStage(stageNumber)
	stageNumber=tonumber(stageNumber)
	local info=Module.GetStage(stageNumber)
	if not info then return false,"Invalid stage" end

	local target=State.StageTargetCache[stageNumber]
	if not isBasePart(target) then
		Module.RefreshTargets()
		target=State.StageTargetCache[stageNumber]
	end

	if not isBasePart(target) then
		return false,("No target for Stage %d"):format(stageNumber)
	end

	return Module.FlyToPart(target,stageNumber)
end

function Module.FlyToWin(winAmount)
	winAmount=tonumber(winAmount)
	if not winAmount then return false,"Invalid Win amount" end

	for _,info in ipairs(WIN_STAGES) do
		if info.value==winAmount then
			return Module.FlyToStage(info.stage)
		end
	end

	return false,"No matching Stage"
end

function Module.SetWalkSpeed(value)
	State.WalkSpeed=getNumber(value,0,500,State.WalkSpeed)
	applyCharacterSettings()
	return true
end

function Module.GetWalkSpeed()
	return State.WalkSpeed
end

function Module.SetJumpPower(value)
	State.JumpPower=getNumber(value,0,500,State.JumpPower)
	applyCharacterSettings()
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

function Module.SetInfiniteJump(enabled)
	State.InfiniteJump=enabled==true
	disconnect("InfiniteJump")

	if State.InfiniteJump then
		Connections.InfiniteJump=UserInputService.JumpRequest:Connect(function()
			if not State.InfiniteJump then return end
			local humanoid=getHumanoid()
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
		if State.NoClip then rememberCollision(character) end
	end
end)

task.defer(function()
	task.wait(0.5)
	applyCharacterSettings()
end)

function Module.GetState()
	local found=0
	for _,info in ipairs(WIN_STAGES) do
		if isBasePart(State.StageTargetCache[info.stage]) then found+=1 end
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
		FoundTargetCount=found,
		FoundTargets=State.StageTargetCache,
	}
end

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
	if character then restoreCollision(character) end

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
	if type(module)~="table" then return false end

	local requiredFunctions={
		"SetWalkSpeed","SetJumpPower","SetFlySpeed","SetFlyHeight",
		"SetInfiniteJump","SetNoClip","RefreshTargets","GetTarget",
		"FlyToWin","StopFlying","IsFlying",
	}

	for _,name in ipairs(requiredFunctions) do
		if type(module[name])~="function" then return false end
	end

	return true
end

local function loadMovementModule()
	if Movement and moduleIsValid(Movement) then return Movement end

	local remoteOK,remoteResult=pcall(function()
		return loadstring(game:HttpGet(MOVEMENT_MODULE_URL))()
	end)

	if remoteOK and moduleIsValid(remoteResult) then
		Movement=remoteResult
		return Movement
	end

	movementLoadError=remoteOK and "Remote movement module is missing required functions." or tostring(remoteResult)

	local fallbackOK,fallbackResult=pcall(function()
		return loadstring(LOCAL_MOVEMENT_SOURCE)()
	end)

	if fallbackOK and moduleIsValid(fallbackResult) then
		Movement=fallbackResult
		return Movement
	end

	return nil
end

loadMovementModule()

--========================================================
-- PALETTE
--========================================================

local COLORS={
	Background=Color3.fromRGB(10,11,16),
	Surface=Color3.fromRGB(14,15,21),
	SurfaceLight=Color3.fromRGB(40,44,58),
	Card=Color3.fromRGB(34,38,50),
	Accent=Color3.fromRGB(168,105,245),
	AccentB=Color3.fromRGB(236,72,153),
	Text=Color3.fromRGB(240,241,245),
	TextDim=Color3.fromRGB(150,157,170),
	Border=Color3.fromRGB(52,56,70),
	Danger=Color3.fromRGB(255,92,108),
	Online=Color3.fromRGB(52,211,153),
	PageServer=Color3.fromRGB(96,165,250),
	PageFarm=Color3.fromRGB(74,222,128),
}

local function tween(obj,props,time,style)
	local tweenObject=TweenService:Create(obj,TweenInfo.new(time or 0.18,style or Enum.EasingStyle.Quad),props)
	tweenObject:Play()
	return tweenObject
end

local function applyGradient(guiObject,colorA,colorB,rotation)
	local gradient=Instance.new("UIGradient")
	gradient.Color=ColorSequence.new(colorA,colorB)
	gradient.Rotation=rotation or 45
	gradient.Parent=guiObject
	return gradient
end

--========================================================
-- SCREEN GUI
--========================================================

local screenGui=Instance.new("ScreenGui")
screenGui.Name="LPTHub"
screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder=2147483647

local hiddenLayer=(gethui and gethui()) or (get_hidden_gui and get_hidden_gui())

if hiddenLayer then
	screenGui.Parent=hiddenLayer
else
	local placedInCoreGui=pcall(function()
		screenGui.Parent=game:GetService("CoreGui")
	end)
	if not placedInCoreGui then screenGui.Parent=playerGui end
end

if protect_gui then
	pcall(function() protect_gui(screenGui) end)
elseif syn and syn.protect_gui then
	pcall(function() syn.protect_gui(screenGui) end)
end

--========================================================
-- MAIN WINDOW
--========================================================

local main=Instance.new("Frame")
main.Name="MainWindow"
main.Size=UDim2.new(0,780,0,500)
main.Position=UDim2.new(0.5,-390,0.5,-250)
main.BackgroundColor3=COLORS.Background
main.BorderSizePixel=0
main.ClipsDescendants=true
main.Parent=screenGui

local mainCorner=Instance.new("UICorner")
mainCorner.CornerRadius=UDim.new(0,20)
mainCorner.Parent=main

local mainStroke=Instance.new("UIStroke")
mainStroke.Color=COLORS.Border
mainStroke.Thickness=1.5
mainStroke.Transparency=0.2
mainStroke.Parent=main
applyGradient(mainStroke,COLORS.Accent,COLORS.AccentB,45)

--========================================================
-- TOP BAR
--========================================================

local topBar=Instance.new("Frame")
topBar.Name="TopBar"
topBar.Size=UDim2.new(1,0,0,38)
topBar.BackgroundColor3=COLORS.Surface
topBar.BorderSizePixel=0
topBar.Parent=main

local topBarCorner=Instance.new("UICorner")
topBarCorner.CornerRadius=UDim.new(0,20)
topBarCorner.Parent=topBar

local topBarMask=Instance.new("Frame")
topBarMask.Size=UDim2.new(1,0,0,20)
topBarMask.Position=UDim2.new(0,0,1,-20)
topBarMask.BackgroundColor3=COLORS.Surface
topBarMask.BorderSizePixel=0
topBarMask.Parent=topBar

--========================================================
-- TITLE
--========================================================

local titleDot=Instance.new("Frame")
titleDot.Size=UDim2.new(0,8,0,8)
titleDot.Position=UDim2.new(0,20,0.5,-4)
titleDot.BackgroundColor3=COLORS.Online
titleDot.BorderSizePixel=0
titleDot.ZIndex=2
titleDot.Parent=topBar

local titleDotCorner=Instance.new("UICorner")
titleDotCorner.CornerRadius=UDim.new(1,0)
titleDotCorner.Parent=titleDot

local titleDotPulse=Instance.new("Frame")
titleDotPulse.Size=UDim2.new(0,8,0,8)
titleDotPulse.Position=UDim2.new(0.5,-4,0.5,-4)
titleDotPulse.BackgroundColor3=COLORS.Online
titleDotPulse.BackgroundTransparency=0.3
titleDotPulse.BorderSizePixel=0
titleDotPulse.ZIndex=1
titleDotPulse.Parent=titleDot

local titleDotPulseCorner=Instance.new("UICorner")
titleDotPulseCorner.CornerRadius=UDim.new(1,0)
titleDotPulseCorner.Parent=titleDotPulse

task.spawn(function()
	while titleDotPulse.Parent do
		titleDotPulse.Size=UDim2.new(0,8,0,8)
		titleDotPulse.Position=UDim2.new(0.5,-4,0.5,-4)
		titleDotPulse.BackgroundTransparency=0.3
		tween(titleDotPulse,{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0.5,-11),BackgroundTransparency=1},1.1)
		task.wait(1.1)
	end
end)

local title=Instance.new("TextLabel")
title.Size=UDim2.new(0,105,1,0)
title.Position=UDim2.new(0,36,0,0)
title.BackgroundTransparency=1
title.Text="LPT Hub"
title.TextColor3=COLORS.Text
title.TextSize=17
title.Font=Enum.Font.GothamBold
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=topBar
applyGradient(title,COLORS.Accent,COLORS.AccentB,0)

local author=Instance.new("TextLabel")
author.Size=UDim2.new(0,170,1,0)
author.Position=UDim2.new(0,120,0,0)
author.BackgroundTransparency=1
author.Text="by Ly Phuc Thien"
author.TextColor3=COLORS.TextDim
author.TextSize=11
author.Font=Enum.Font.Gotham
author.TextXAlignment=Enum.TextXAlignment.Left
author.Parent=topBar

local separator=Instance.new("Frame")
separator.Size=UDim2.new(1,0,0,1)
separator.Position=UDim2.new(0,0,1,-1)
separator.BackgroundColor3=COLORS.Border
separator.BorderSizePixel=0
separator.Parent=topBar

--========================================================
-- TOP BUTTONS
--========================================================

local function topButton(name,xOffset,text,textSize)
	local button=Instance.new("TextButton")
	button.Name=name
	button.Size=UDim2.new(0,30,0,26)
	button.Position=UDim2.new(1,xOffset,0.5,-13)
	button.BackgroundColor3=COLORS.SurfaceLight
	button.BackgroundTransparency=1
	button.BorderSizePixel=0
	button.Text=text
	button.TextColor3=COLORS.TextDim
	button.TextSize=textSize
	button.Font=Enum.Font.GothamMedium
	button.AutoButtonColor=false
	button.Parent=topBar

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,10)
	corner.Parent=button
	return button
end

local minimize=topButton("MinimizeButton",-110,"—",13)
local maximize=topButton("MaximizeButton",-76,"",0)
local close=topButton("CloseButton",-40,"×",17)

--========================================================
-- MAX ICON
--========================================================

local maxIcon=Instance.new("Frame")
maxIcon.Size=UDim2.new(0,20,0,20)
maxIcon.Position=UDim2.new(0.5,-10,0.5,-10)
maxIcon.BackgroundTransparency=1
maxIcon.BorderSizePixel=0
maxIcon.Parent=maximize

local normalIcon=Instance.new("Frame")
normalIcon.Size=UDim2.new(0,13,0,13)
normalIcon.Position=UDim2.new(0.5,-6,0.5,-6)
normalIcon.BackgroundTransparency=1
normalIcon.BorderSizePixel=0
normalIcon.Parent=maxIcon

local normalCorner=Instance.new("UICorner")
normalCorner.CornerRadius=UDim.new(0,3)
normalCorner.Parent=normalIcon

local normalStroke=Instance.new("UIStroke")
normalStroke.Thickness=1.5
normalStroke.Color=COLORS.TextDim
normalStroke.Parent=normalIcon

local restoreBack=Instance.new("Frame")
restoreBack.Size=UDim2.new(0,11,0,11)
restoreBack.Position=UDim2.new(0,6,0,2)
restoreBack.BackgroundTransparency=1
restoreBack.BorderSizePixel=0
restoreBack.Visible=false
restoreBack.ZIndex=2
restoreBack.Parent=maxIcon

local restoreBackCorner=Instance.new("UICorner")
restoreBackCorner.CornerRadius=UDim.new(0,2)
restoreBackCorner.Parent=restoreBack

local restoreBackStroke=Instance.new("UIStroke")
restoreBackStroke.Thickness=1.5
restoreBackStroke.Color=COLORS.TextDim
restoreBackStroke.Parent=restoreBack

local restoreFront=Instance.new("Frame")
restoreFront.Size=UDim2.new(0,11,0,11)
restoreFront.Position=UDim2.new(0,2,0,6)
restoreFront.BackgroundColor3=COLORS.Surface
restoreFront.BorderSizePixel=0
restoreFront.Visible=false
restoreFront.ZIndex=3
restoreFront.Parent=maxIcon

local restoreFrontCorner=Instance.new("UICorner")
restoreFrontCorner.CornerRadius=UDim.new(0,2)
restoreFrontCorner.Parent=restoreFront

local restoreFrontStroke=Instance.new("UIStroke")
restoreFrontStroke.Thickness=1.5
restoreFrontStroke.Color=COLORS.TextDim
restoreFrontStroke.Parent=restoreFront

local function setupTopButton(button,hoverColor,hoverBg)
	button.MouseEnter:Connect(function()
		tween(button,{TextColor3=hoverColor,BackgroundTransparency=0})
		tween(button,{BackgroundColor3=hoverBg or COLORS.SurfaceLight})
	end)
	button.MouseLeave:Connect(function()
		tween(button,{TextColor3=COLORS.TextDim,BackgroundTransparency=1})
	end)
end

setupTopButton(minimize,COLORS.Text)
setupTopButton(close,Color3.new(1,1,1),COLORS.Danger)

maximize.MouseEnter:Connect(function()
	tween(maximize,{BackgroundTransparency=0})
	tween(normalStroke,{Color=COLORS.Text})
	tween(restoreBackStroke,{Color=COLORS.Text})
	tween(restoreFrontStroke,{Color=COLORS.Text})
end)

maximize.MouseLeave:Connect(function()
	tween(maximize,{BackgroundTransparency=1})
	tween(normalStroke,{Color=COLORS.TextDim})
	tween(restoreBackStroke,{Color=COLORS.TextDim})
	tween(restoreFrontStroke,{Color=COLORS.TextDim})
end)

--========================================================
-- SIDEBAR
--========================================================

local sidebar=Instance.new("Frame")
sidebar.Name="Sidebar"
sidebar.Size=UDim2.new(0,220,1,-38)
sidebar.Position=UDim2.new(0,0,0,38)
sidebar.BackgroundColor3=COLORS.Surface
sidebar.BorderSizePixel=0
sidebar.Parent=main

local sidebarCorner=Instance.new("UICorner")
sidebarCorner.CornerRadius=UDim.new(0,20)
sidebarCorner.Parent=sidebar

local sidebarTopMask=Instance.new("Frame")
sidebarTopMask.Size=UDim2.new(1,0,0,20)
sidebarTopMask.BackgroundColor3=COLORS.Surface
sidebarTopMask.BorderSizePixel=0
sidebarTopMask.Parent=sidebar

local sidebarInnerMask=Instance.new("Frame")
sidebarInnerMask.Size=UDim2.new(0,20,0,20)
sidebarInnerMask.Position=UDim2.new(1,-20,1,-20)
sidebarInnerMask.BackgroundColor3=COLORS.Surface
sidebarInnerMask.BorderSizePixel=0
sidebarInnerMask.Parent=sidebar

local sideLine=Instance.new("Frame")
sideLine.Size=UDim2.new(0,1,1,0)
sideLine.Position=UDim2.new(1,-1,0,0)
sideLine.BackgroundColor3=COLORS.Border
sideLine.BorderSizePixel=0
sideLine.Parent=sidebar

--========================================================
-- CONTENT / PAGES
--========================================================

local content=Instance.new("Frame")
content.Name="Content"
content.Size=UDim2.new(1,-220,1,-38)
content.Position=UDim2.new(0,220,0,38)
content.BackgroundTransparency=1
content.Parent=main

local pages={}

local function createPage(name)
	local page=Instance.new("ScrollingFrame")
	page.Name=name
	page.Size=UDim2.new(1,0,1,0)
	page.BackgroundTransparency=1
	page.BorderSizePixel=0
	page.ScrollBarThickness=3
	page.ScrollBarImageColor3=COLORS.Accent
	page.CanvasSize=UDim2.new(0,0,0,0)
	page.Visible=false
	page.Parent=content
	pages[name]=page
	return page
end

local serverPage=createPage("Server")
local autoWinPage=createPage("AutoWin")
local movementPage=createPage("Movement")

--========================================================
-- PAGE TITLE
--========================================================

local function createPageTitle(parent,text,subtitle)
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-50,0,38)
	label.Position=UDim2.new(0,28,0,20)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=28
	label.Font=Enum.Font.GothamBold
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=parent

	if subtitle then
		local sub=Instance.new("TextLabel")
		sub.Size=UDim2.new(1,-50,0,20)
		sub.Position=UDim2.new(0,28,0,54)
		sub.BackgroundTransparency=1
		sub.Text=subtitle
		sub.TextColor3=COLORS.TextDim
		sub.TextSize=14
		sub.Font=Enum.Font.Gotham
		sub.TextXAlignment=Enum.TextXAlignment.Left
		sub.Parent=parent
	end

	return label
end

--========================================================
-- CARD
--========================================================

local function createCard(parent,yPos,titleText,bodyText,height,accentColor)
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-56,0,height or 90)
	card.Position=UDim2.new(0,28,0,yPos)
	card.BackgroundColor3=COLORS.Card
	card.BorderSizePixel=0
	card.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=card

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=0.15
	stroke.Parent=card

	local accentBar=Instance.new("Frame")
	accentBar.Size=UDim2.new(0,4,1,-20)
	accentBar.Position=UDim2.new(0,0,0.5,0)
	accentBar.AnchorPoint=Vector2.new(0,0.5)
	accentBar.BackgroundColor3=accentColor or COLORS.Accent
	accentBar.BorderSizePixel=0
	accentBar.Parent=card

	local accentCorner=Instance.new("UICorner")
	accentCorner.CornerRadius=UDim.new(1,0)
	accentCorner.Parent=accentBar
	applyGradient(accentBar,accentColor or COLORS.Accent,COLORS.AccentB,90)

	local cardTitle=Instance.new("TextLabel")
	cardTitle.Size=UDim2.new(1,-40,0,22)
	cardTitle.Position=UDim2.new(0,18,0,12)
	cardTitle.BackgroundTransparency=1
	cardTitle.Text=titleText
	cardTitle.TextColor3=COLORS.Text
	cardTitle.TextSize=15
	cardTitle.Font=Enum.Font.GothamBold
	cardTitle.TextXAlignment=Enum.TextXAlignment.Left
	cardTitle.Parent=card

	local cardBody=Instance.new("TextLabel")
	cardBody.Size=UDim2.new(1,-40,1,-40)
	cardBody.Position=UDim2.new(0,18,0,36)
	cardBody.BackgroundTransparency=1
	cardBody.Text=bodyText
	cardBody.TextColor3=COLORS.TextDim
	cardBody.TextSize=13
	cardBody.Font=Enum.Font.Gotham
	cardBody.TextXAlignment=Enum.TextXAlignment.Left
	cardBody.TextYAlignment=Enum.TextYAlignment.Top
	cardBody.TextWrapped=true
	cardBody.Parent=card

	return card
end

--========================================================
-- SLIDER TOGGLE - AUTO WIN
--========================================================

local function createSliderToggle(parent,text,yPos,accentColor,onChanged)
	accentColor=accentColor or COLORS.Accent

	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-56,0,56)
	row.Position=UDim2.new(0,28,0,yPos)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=0.15
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-90,1,0)
	label.Position=UDim2.new(0,18,0,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local toggle=Instance.new("TextButton")
	toggle.Size=UDim2.new(0,50,0,26)
	toggle.Position=UDim2.new(1,-68,0.5,-13)
	toggle.BackgroundColor3=COLORS.SurfaceLight
	toggle.BorderSizePixel=0
	toggle.Text=""
	toggle.AutoButtonColor=false
	toggle.Parent=row

	local toggleCorner=Instance.new("UICorner")
	toggleCorner.CornerRadius=UDim.new(1,0)
	toggleCorner.Parent=toggle

	local gradient=applyGradient(toggle,accentColor,COLORS.AccentB,0)
	gradient.Enabled=false

	local circle=Instance.new("Frame")
	circle.Size=UDim2.new(0,20,0,20)
	circle.Position=UDim2.new(0,3,0.5,-10)
	circle.BackgroundColor3=Color3.new(1,1,1)
	circle.BorderSizePixel=0
	circle.Parent=toggle

	local circleCorner=Instance.new("UICorner")
	circleCorner.CornerRadius=UDim.new(1,0)
	circleCorner.Parent=circle

	local enabled=false

	local function setState(state,fireCallback)
		enabled=state==true

		if enabled then
			gradient.Enabled=true
			tween(toggle,{BackgroundColor3=accentColor})
			tween(circle,{Position=UDim2.new(1,-23,0.5,-10)})
		else
			tween(toggle,{BackgroundColor3=COLORS.SurfaceLight})
			tween(circle,{Position=UDim2.new(0,3,0.5,-10)})
			task.delay(0.18,function()
				if not enabled then gradient.Enabled=false end
			end)
		end

		if fireCallback~=false and onChanged then
			onChanged(enabled)
		end
	end

	toggle.MouseButton1Click:Connect(function()
		setState(not enabled,true)
	end)

	return row,toggle,setState,function() return enabled end
end

--========================================================
-- CHECKBOX - MOVEMENT
--========================================================

local function createCheckbox(parent,text,yPos,accentColor,onChanged)
	accentColor=accentColor or COLORS.Accent

	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-56,0,56)
	row.Position=UDim2.new(0,28,0,yPos)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=0.15
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-80,1,0)
	label.Position=UDim2.new(0,18,0,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local checkbox=Instance.new("TextButton")
	checkbox.Name="Checkbox"
	checkbox.Size=UDim2.new(0,26,0,26)
	checkbox.Position=UDim2.new(1,-50,0.5,-13)
	checkbox.BackgroundColor3=COLORS.SurfaceLight
	checkbox.BorderSizePixel=0
	checkbox.Text=""
	checkbox.AutoButtonColor=false
	checkbox.Parent=row

	local checkboxCorner=Instance.new("UICorner")
	checkboxCorner.CornerRadius=UDim.new(0,7)
	checkboxCorner.Parent=checkbox

	local checkboxStroke=Instance.new("UIStroke")
	checkboxStroke.Color=COLORS.Border
	checkboxStroke.Thickness=1.5
	checkboxStroke.Parent=checkbox

	local check=Instance.new("TextLabel")
	check.Size=UDim2.new(1,0,1,0)
	check.BackgroundTransparency=1
	check.Text="✓"
	check.TextColor3=Color3.new(1,1,1)
	check.TextSize=18
	check.Font=Enum.Font.GothamBold
	check.TextXAlignment=Enum.TextXAlignment.Center
	check.TextYAlignment=Enum.TextYAlignment.Center
	check.Visible=false
	check.Parent=checkbox

	local checked=false

	local function setState(state,fireCallback)
		checked=state==true

		if checked then
			check.Visible=true
			tween(checkbox,{BackgroundColor3=accentColor})
			tween(checkboxStroke,{Color=accentColor})
		else
			check.Visible=false
			tween(checkbox,{BackgroundColor3=COLORS.SurfaceLight})
			tween(checkboxStroke,{Color=COLORS.Border})
		end

		if fireCallback~=false and onChanged then
			onChanged(checked)
		end
	end

	checkbox.MouseButton1Click:Connect(function()
		setState(not checked,true)
	end)

	return row,checkbox,setState,function() return checked end
end

--========================================================
-- NUMBER CONTROL
--========================================================

local function createNumberControl(parent,titleText,yPos,defaultValue,minValue,maxValue,accentColor,onChanged)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-56,0,78)
	row.Position=UDim2.new(0,28,0,yPos)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=0.15
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-36,0,18)
	label.Position=UDim2.new(0,18,0,10)
	label.BackgroundTransparency=1
	label.Text=titleText
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local sliderZone=Instance.new("Frame")
	sliderZone.Size=UDim2.new(1,-36,0,30)
	sliderZone.Position=UDim2.new(0,18,0,38)
	sliderZone.BackgroundTransparency=1
	sliderZone.Parent=row

	local minLabel=Instance.new("TextLabel")
	minLabel.Size=UDim2.new(0,20,1,0)
	minLabel.BackgroundTransparency=1
	minLabel.Text="0"
	minLabel.TextColor3=COLORS.TextDim
	minLabel.TextSize=12
	minLabel.Font=Enum.Font.GothamMedium
	minLabel.TextXAlignment=Enum.TextXAlignment.Left
	minLabel.Parent=sliderZone

	local valueLabel=Instance.new("TextLabel")
	valueLabel.Size=UDim2.new(0,46,1,0)
	valueLabel.Position=UDim2.new(1,-46,0,0)
	valueLabel.BackgroundTransparency=1
	valueLabel.Text=tostring(defaultValue)
	valueLabel.TextColor3=accentColor
	valueLabel.TextSize=14
	valueLabel.Font=Enum.Font.GothamBold
	valueLabel.TextXAlignment=Enum.TextXAlignment.Right
	valueLabel.Parent=sliderZone

	local track=Instance.new("Frame")
	track.Size=UDim2.new(1,-76,0,6)
	track.Position=UDim2.new(0,28,0.5,-3)
	track.BackgroundColor3=COLORS.SurfaceLight
	track.BorderSizePixel=0
	track.Active=true
	track.Parent=sliderZone

	local trackCorner=Instance.new("UICorner")
	trackCorner.CornerRadius=UDim.new(1,0)
	trackCorner.Parent=track

	local fill=Instance.new("Frame")
	fill.BackgroundColor3=accentColor
	fill.BorderSizePixel=0
	fill.Parent=track

	local fillCorner=Instance.new("UICorner")
	fillCorner.CornerRadius=UDim.new(1,0)
	fillCorner.Parent=fill

	local knob=Instance.new("Frame")
	knob.Size=UDim2.new(0,16,0,16)
	knob.AnchorPoint=Vector2.new(0.5,0.5)
	knob.BackgroundColor3=Color3.new(1,1,1)
	knob.BorderSizePixel=0
	knob.ZIndex=2
	knob.Active=true
	knob.Parent=track

	local knobCorner=Instance.new("UICorner")
	knobCorner.CornerRadius=UDim.new(1,0)
	knobCorner.Parent=knob

	local knobStroke=Instance.new("UIStroke")
	knobStroke.Color=accentColor
	knobStroke.Thickness=2
	knobStroke.Parent=knob

	local function updateVisual(value)
		local fraction=math.clamp((value-minValue)/(maxValue-minValue),0,1)
		fill.Size=UDim2.new(fraction,0,1,0)
		knob.Position=UDim2.new(fraction,0,0.5,0)
		valueLabel.Text=tostring(value)
	end

	local function setValue(value,fireCallback)
		value=math.clamp(math.floor(value+0.5),minValue,maxValue)
		updateVisual(value)
		if fireCallback~=false and onChanged then onChanged(value) end
		return value
	end

	updateVisual(math.clamp(defaultValue,minValue,maxValue))

	local dragging=false

	local function updateFromInputPosition(inputPosition)
		local relativeX=inputPosition.X-track.AbsolutePosition.X
		local fraction=math.clamp(relativeX/track.AbsoluteSize.X,0,1)
		setValue(minValue+fraction*(maxValue-minValue))
	end

	local function beginDrag(input)
		dragging=true
		updateFromInputPosition(input.Position)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then beginDrag(input) end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then beginDrag(input) end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			updateFromInputPosition(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
			dragging=false
		end
	end)

	return row,valueLabel,setValue
end

--========================================================
-- SERVER PAGE
--========================================================

createPageTitle(serverPage,"Server","Server info & tools")
createCard(serverPage,95,"Server","Manage server information here.",90,COLORS.PageServer)
serverPage.CanvasSize=UDim2.new(0,0,0,220)

--========================================================
-- AUTO WIN PAGE
--========================================================

createPageTitle(autoWinPage,"Auto Win","Chọn Stage để tự động bay tới nút Win tương ứng.")

local refreshTargets=Instance.new("TextButton")
refreshTargets.Name="RefreshTargets"
refreshTargets.Size=UDim2.new(0,125,0,32)
refreshTargets.Position=UDim2.new(1,-153,0,23)
refreshTargets.BackgroundColor3=COLORS.PageServer
refreshTargets.BorderSizePixel=0
refreshTargets.Text="Refresh"
refreshTargets.TextColor3=Color3.new(1,1,1)
refreshTargets.TextSize=12
refreshTargets.Font=Enum.Font.GothamBold
refreshTargets.AutoButtonColor=false
refreshTargets.Parent=autoWinPage

local refreshCorner=Instance.new("UICorner")
refreshCorner.CornerRadius=UDim.new(0,9)
refreshCorner.Parent=refreshTargets

local refreshStroke=Instance.new("UIStroke")
refreshStroke.Color=COLORS.Border
refreshStroke.Thickness=1
refreshStroke.Transparency=0.2
refreshStroke.Parent=refreshTargets

refreshTargets.MouseEnter:Connect(function()
	tween(refreshTargets,{BackgroundColor3=Color3.fromRGB(120,180,255)},0.15)
end)

refreshTargets.MouseLeave:Connect(function()
	tween(refreshTargets,{BackgroundColor3=COLORS.PageServer},0.15)
end)

refreshTargets.MouseButton1Click:Connect(function()
	local module=loadMovementModule()
	if module and module.RefreshTargets then module.RefreshTargets() end
end)

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

local WIN_TARGET_ROW_HEIGHT=56
local WIN_TARGET_ROW_GAP=10
local WIN_TARGET_START_Y=95
local winTargetRows={}
local selectedWinTarget=nil

for index,stageData in ipairs(WIN_STAGES) do
	local rowY=WIN_TARGET_START_Y+(index-1)*(WIN_TARGET_ROW_HEIGHT+WIN_TARGET_ROW_GAP)

	local _,_,setStageState=createSliderToggle(autoWinPage,stageData.text,rowY,COLORS.PageServer,function(isEnabled)
		if isEnabled then
			selectedWinTarget=stageData.value

			for _,entry in ipairs(winTargetRows) do
				if entry.index~=index then entry.setState(false,false) end
			end

			local module=loadMovementModule()
			if module and module.RefreshTargets then module.RefreshTargets() end
		elseif selectedWinTarget==stageData.value then
			selectedWinTarget=nil

			local module=loadMovementModule()
			if module and module.StopFlying then module.StopFlying() end
		end
	end)

	table.insert(winTargetRows,{index=index,stage=stageData.stage,value=stageData.value,setState=setStageState})
end

local winTargetsBottom=WIN_TARGET_START_Y+(#WIN_STAGES*WIN_TARGET_ROW_HEIGHT)+((#WIN_STAGES-1)*WIN_TARGET_ROW_GAP)
autoWinPage.CanvasSize=UDim2.new(0,0,0,winTargetsBottom+25)

--========================================================
-- MOVEMENT PAGE
--========================================================

createPageTitle(movementPage,"Chức Năng","Các điều khiển việc di chuyển, nhảy và điều hướng.")

local SETTINGS_FILE="LPT_Hub_Settings.json"

local DEFAULT_SETTINGS={
	WalkSpeed=16,
	JumpPower=50,
	FlySpeed=90,
	FlyHeight=5,
	InfiniteJump=false,
	NoClip=false,
}

local function loadSavedSettings()
	local settings={}
	for key,value in pairs(DEFAULT_SETTINGS) do settings[key]=value end

	if not (isfile and readfile) then return settings end

	local ok,exists=pcall(function() return isfile(SETTINGS_FILE) end)
	if not ok or not exists then return settings end

	local success,result=pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_FILE))
	end)

	if success and type(result)=="table" then
		for key in pairs(DEFAULT_SETTINGS) do
			if result[key]~=nil then settings[key]=result[key] end
		end
	end

	return settings
end

local Loaded=loadSavedSettings()
local speedValue=tonumber(Loaded.WalkSpeed) or 16
local jumpValue=tonumber(Loaded.JumpPower) or 50
local flySpeedValue=tonumber(Loaded.FlySpeed) or 90
local flyHeightValue=tonumber(Loaded.FlyHeight) or 5

local infiniteJumpEnabled
local noClipEnabled

local function saveSettings()
	if not (writefile and HttpService) then return end

	local settings={
		WalkSpeed=speedValue,
		JumpPower=jumpValue,
		FlySpeed=flySpeedValue,
		FlyHeight=flyHeightValue,
		InfiniteJump=infiniteJumpEnabled and infiniteJumpEnabled() or false,
		NoClip=noClipEnabled and noClipEnabled() or false,
	}

	pcall(function()
		writefile(SETTINGS_FILE,HttpService:JSONEncode(settings))
	end)
end

createNumberControl(movementPage,"Walk Speed",95,speedValue,0,500,COLORS.PageFarm,function(value)
	speedValue=value
	local module=loadMovementModule()
	if module and module.SetWalkSpeed then module.SetWalkSpeed(value) end
	task.defer(saveSettings)
end)

createNumberControl(movementPage,"Jump Power",183,jumpValue,0,500,COLORS.PageFarm,function(value)
	jumpValue=value
	local module=loadMovementModule()
	if module and module.SetJumpPower then module.SetJumpPower(value) end
	task.defer(saveSettings)
end)

createNumberControl(movementPage,"Auto-Fly Speed",271,flySpeedValue,10,500,COLORS.PageServer,function(value)
	flySpeedValue=value
	local module=loadMovementModule()
	if module and module.SetFlySpeed then module.SetFlySpeed(value) end
	task.defer(saveSettings)
end)

createNumberControl(movementPage,"Fly Height Offset",359,flyHeightValue,0,100,COLORS.PageServer,function(value)
	flyHeightValue=value
	local module=loadMovementModule()
	if module and module.SetFlyHeight then module.SetFlyHeight(value) end
	task.defer(saveSettings)
end)

local _,_,setInfiniteJumpUI,getInfiniteJumpState=createCheckbox(movementPage,"Infinite Jump",447,COLORS.PageFarm,function(enabled)
	local module=loadMovementModule()
	if module and module.SetInfiniteJump then module.SetInfiniteJump(enabled) end
	task.defer(saveSettings)
end)

infiniteJumpEnabled=getInfiniteJumpState

local _,_,setNoClipUI,getNoClipState=createCheckbox(movementPage,"No Clip",515,COLORS.PageServer,function(enabled)
	local module=loadMovementModule()
	if module and module.SetNoClip then module.SetNoClip(enabled) end
	task.defer(saveSettings)
end)

noClipEnabled=getNoClipState
movementPage.CanvasSize=UDim2.new(0,0,0,610)

--========================================================
-- APPLY SAVED SETTINGS
--========================================================

task.defer(function()
	local module=loadMovementModule()

	if module then
		if module.SetWalkSpeed then module.SetWalkSpeed(speedValue) end
		if module.SetJumpPower then module.SetJumpPower(jumpValue) end
		if module.SetFlySpeed then module.SetFlySpeed(flySpeedValue) end
		if module.SetFlyHeight then module.SetFlyHeight(flyHeightValue) end
	end

	if Loaded.InfiniteJump==true then setInfiniteJumpUI(true,true) end
	if Loaded.NoClip==true then setNoClipUI(true,true) end
end)

--========================================================
-- AUTO WIN LOOP
--========================================================

task.spawn(function()
	while screenGui.Parent do
		task.wait(0.1)

		local module=Movement
		if not module then continue end

		if selectedWinTarget then
			local target=module.GetTarget and module.GetTarget(selectedWinTarget)

			if not target and module.RefreshTargets then
				module.RefreshTargets()
			end

			if module.IsFlying and module.FlyToWin and not module.IsFlying() then
				module.FlyToWin(selectedWinTarget)
			end
		elseif module.IsFlying and module.IsFlying() then
			if module.StopFlying then module.StopFlying() end
		end
	end
end)

--========================================================
-- SIDEBAR
--========================================================

local currentPage=nil
local buttons={}

local function createSidebarButton(text,order,pageName,accentColor)
	accentColor=accentColor or COLORS.Accent

	local button=Instance.new("TextButton")
	button.Name=pageName.."Button"
	button.Size=UDim2.new(1,-24,0,48)
	button.Position=UDim2.new(0,12,0,16+(order-1)*54)
	button.BackgroundColor3=COLORS.SurfaceLight
	button.BackgroundTransparency=1
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=sidebar

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,12)
	corner.Parent=button

	local textLabel=Instance.new("TextLabel")
	textLabel.Size=UDim2.new(1,-32,1,0)
	textLabel.Position=UDim2.new(0,18,0,0)
	textLabel.BackgroundTransparency=1
	textLabel.Text=text
	textLabel.TextColor3=COLORS.TextDim
	textLabel.TextSize=14
	textLabel.Font=Enum.Font.GothamMedium
	textLabel.TextXAlignment=Enum.TextXAlignment.Left
	textLabel.Parent=button

	local indicator=Instance.new("Frame")
	indicator.Size=UDim2.new(0,4,0,28)
	indicator.Position=UDim2.new(0,0,0.5,-14)
	indicator.BackgroundColor3=accentColor
	indicator.BorderSizePixel=0
	indicator.Visible=false
	indicator.Parent=button

	local indicatorCorner=Instance.new("UICorner")
	indicatorCorner.CornerRadius=UDim.new(1,0)
	indicatorCorner.Parent=indicator

	button.MouseEnter:Connect(function()
		if currentPage~=pageName then tween(button,{BackgroundTransparency=0.7}) end
	end)

	button.MouseLeave:Connect(function()
		if currentPage~=pageName then tween(button,{BackgroundTransparency=1}) end
	end)

	button.MouseButton1Click:Connect(function()
		for _,data in pairs(buttons) do
			tween(data.button,{BackgroundTransparency=1})
			data.indicator.Visible=false
			tween(data.label,{TextColor3=COLORS.TextDim})
		end

		for _,page in pairs(pages) do page.Visible=false end

		currentPage=pageName
		tween(button,{BackgroundTransparency=0.1})
		indicator.Visible=true
		tween(textLabel,{TextColor3=COLORS.Text})
		pages[pageName].Visible=true
	end)

	buttons[pageName]={button=button,indicator=indicator,label=textLabel,accent=accentColor}
	return button
end

createSidebarButton("Server",1,"Server",COLORS.PageServer)
createSidebarButton("Auto Win",2,"AutoWin",COLORS.PageServer)
createSidebarButton("Movement",3,"Movement",COLORS.PageFarm)

currentPage="Server"
serverPage.Visible=true
autoWinPage.Visible=false
movementPage.Visible=false

buttons["Server"].button.BackgroundTransparency=0.1
buttons["Server"].indicator.Visible=true
buttons["Server"].label.TextColor3=COLORS.Text

--========================================================
-- CLOSE
--========================================================

close.MouseButton1Click:Connect(function()
	saveSettings()
	selectedWinTarget=nil

	local module=loadMovementModule()

	if module then
		if module.StopFlying then module.StopFlying() end
		if module.SetInfiniteJump then module.SetInfiniteJump(false) end
		if module.SetNoClip then module.SetNoClip(false) end
	end

	tween(main,{BackgroundTransparency=1},0.15)
	task.wait(0.15)

	if screenGui.Parent then screenGui:Destroy() end
end)

--========================================================
-- MAXIMIZE
--========================================================

local maximized=false
local minimized=false
local normalSize=UDim2.new(0,780,0,500)
local normalPosition=UDim2.new(0.5,-390,0.5,-250)

maximize.MouseButton1Click:Connect(function()
	if minimized then
		minimized=false
		sidebar.Visible=true
		content.Visible=true
	end

	maximized=not maximized

	if maximized then
		tween(main,{Size=UDim2.new(1,-40,1,-40),Position=UDim2.new(0,20,0,20)},0.25)
		normalIcon.Visible=false
		restoreBack.Visible=true
		restoreFront.Visible=true
	else
		tween(main,{Size=normalSize,Position=normalPosition},0.25)
		normalIcon.Visible=true
		restoreBack.Visible=false
		restoreFront.Visible=false
	end
end)

--========================================================
-- MINIMIZE
--========================================================

minimize.MouseButton1Click:Connect(function()
	minimized=not minimized

	if minimized then
		sidebar.Visible=false
		content.Visible=false
		tween(main,{Size=UDim2.new(0,780,0,38)},0.2)
	else
		sidebar.Visible=true
		content.Visible=true
		tween(main,{
			Size=maximized and UDim2.new(1,-40,1,-40) or normalSize
		},0.2)
	end
end)

--========================================================
-- DRAG WINDOW
--========================================================

local dragging=false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=true
		dragStart=input.Position
		startPos=main.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
		local delta=input.Position-dragStart
		main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
	end
end)
