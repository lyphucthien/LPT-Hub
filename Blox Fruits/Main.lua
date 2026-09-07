local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local oldESPGui=playerGui:FindFirstChild("LPT_ESP_Screen")
if oldESPGui then
	oldESPGui:Destroy()
end

local espGui=Instance.new("ScreenGui")
espGui.Name="LPT_ESP_Screen"
espGui.ResetOnSpawn=false
espGui.IgnoreGuiInset=true
espGui.ZIndexBehavior=Enum.ZIndexBehavior.Global
espGui.DisplayOrder=999999
espGui.Parent=playerGui

local oldGui=playerGui:FindFirstChild("LPTHub")
if oldGui then oldGui:Destroy() end

--========================================================
-- COLORS
--========================================================

local COLORS={
	Background=Color3.fromRGB(10,11,16),
	Surface=Color3.fromRGB(14,15,21),
	SurfaceLight=Color3.fromRGB(40,44,58),
	Card=Color3.fromRGB(34,38,50),
	CardHover=Color3.fromRGB(40,44,58),
	Accent=Color3.fromRGB(168,105,245),
	AccentB=Color3.fromRGB(236,72,153),
	Text=Color3.fromRGB(240,241,245),
	TextDim=Color3.fromRGB(150,157,170),
	Border=Color3.fromRGB(52,56,70),
	Success=Color3.fromRGB(74,222,128),
	Danger=Color3.fromRGB(255,92,108),
	Info=Color3.fromRGB(96,165,250)
}

local SIDEBAR_ACCENT=Color3.fromRGB(96,165,250)

--========================================================
-- HELPERS
--========================================================

local function tween(obj,props,time,style,direction)
	if not obj or not obj.Parent then return end

	local t=TweenService:Create(
		obj,
		TweenInfo.new(
			time or .18,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		props
	)

	t:Play()
	return t
end

local function gradient(obj,a,b,rotation)
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new(a,b)
	g.Rotation=rotation or 45
	g.Parent=obj
	return g
end

local function createCorner(obj,radius)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,radius or 10)
	c.Parent=obj
	return c
end

local function createStroke(obj,color,transparency,thickness)
	local s=Instance.new("UIStroke")
	s.Color=color or COLORS.Border
	s.Transparency=transparency or 0
	s.Thickness=thickness or 1
	s.Parent=obj
	return s
end

local function createLabel(parent,text,size,position,font,textSize,color,alignment)
	local label=Instance.new("TextLabel")
	label.Size=size
	label.Position=position
	label.BackgroundTransparency=1
	label.Text=text
	label.Font=font or Enum.Font.Gotham
	label.TextSize=textSize or 14
	label.TextColor3=color or COLORS.Text
	label.TextXAlignment=alignment or Enum.TextXAlignment.Left
	label.TextYAlignment=Enum.TextYAlignment.Center
	label.Parent=parent
	return label
end

--========================================================
-- FARM ENGINE
-- Stable Auto Farm
-- Roblox Studio / game bạn kiểm soát
--========================================================

local FarmState={
	Running=false,
	State="Idle",
	Level=0,
	Quest=nil,
	Target=nil,
	Session=0,
	LastQuestAction=0,
	LastAttack=0,
	LastTargetScan=0
}

local FarmConfig={
	AttackDistance=7,
	SearchDistance=5000,

	-- Tốc độ bay
	FlySpeed=100,
	FlyHeight=18,

	-- Chu kỳ
	LoopDelay=.12,
	SearchDelay=.25,

	-- Chống spam
	QuestActionCooldown=.8,
	AttackCooldown=.10,

	MoveOffset=Vector3.new(0,0,6)
}

--========================================================
-- BASIC HELPERS
--========================================================

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

local function getCharacterRoot()
	local character=getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getLevel()
	local containers={
		player:FindFirstChild("leaderstats"),
		player:FindFirstChild("Data"),
		player
	}

	for _,container in ipairs(containers) do
		if container then
			local levelObject=
				container:FindFirstChild("Level")
				or container:FindFirstChild("Lv")
				or container:FindFirstChild("level")

			if levelObject then
				local value=tonumber(levelObject.Value)

				if value then
					return value
				end
			end

			for _,object in ipairs(container:GetDescendants()) do
				if object.Name=="Level"
					or object.Name=="Lv"
					or object.Name=="level" then

					local value=tonumber(object.Value)

					if value then
						return value
					end
				end
			end
		end
	end

	return 0
end

local function getRoot(object)
	if not object then
		return nil
	end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then
		return object:FindFirstChild("HumanoidRootPart",true)
			or object.PrimaryPart
			or object:FindFirstChildWhichIsA("BasePart",true)
	end

	return object:FindFirstChildWhichIsA("BasePart",true)
end

local function getHumanoidFrom(object)
	if not object then
		return nil
	end

	return object:FindFirstChildOfClass("Humanoid")
		or object:FindFirstChildWhichIsA("Humanoid",true)
end

local function isAlive(object)
	if not object or not object.Parent then
		return false
	end

	local humanoid=getHumanoidFrom(object)

	return humanoid
		and humanoid.Health>0
end

--========================================================
-- FARM DATA CONTAINER
--========================================================

local function findFarmContainer()
	local direct=workspace:FindFirstChild("LPT_Farm")

	if direct then
		return direct
	end

	local replicated=game:GetService("ReplicatedStorage"):FindFirstChild("LPT_Farm")

	if replicated then
		return replicated
	end

	local playerData=player:FindFirstChild("LPT_Farm")

	if playerData then
		return playerData
	end

	local playerGuiData=playerGui:FindFirstChild("LPT_Farm")

	if playerGuiData then
		return playerGuiData
	end

	return nil
end

--========================================================
-- VALUE READER
--========================================================

local function readValue(container,names)
	if not container then
		return nil
	end

	for _,name in ipairs(names) do
		local object=container:FindFirstChild(name,true)

		if object then

			if object:IsA("StringValue")
				or object:IsA("IntValue")
				or object:IsA("NumberValue")
				or object:IsA("BoolValue") then

				return object.Value
			end

			local attribute=object:GetAttribute("Value")

			if attribute~=nil then
				return attribute
			end
		end

		local attribute=container:GetAttribute(name)

		if attribute~=nil then
			return attribute
		end
	end

	return nil
end

--========================================================
-- QUEST CACHE
--========================================================

local QuestDiscovery={
	Cache=nil,
	LastUpdate=0,
	CacheTime=.1
}

local function invalidateQuest()
	QuestDiscovery.Cache=nil
	QuestDiscovery.LastUpdate=0
end

--========================================================
-- QUEST DISCOVERY
--========================================================

local function discoverQuest()
	if QuestDiscovery.Cache
		and os.clock()-QuestDiscovery.LastUpdate<QuestDiscovery.CacheTime then

		return QuestDiscovery.Cache
	end

	local hooks=findFarmContainer()

	if not hooks then
		QuestDiscovery.Cache=nil
		QuestDiscovery.LastUpdate=os.clock()

		return nil
	end

	local questId=readValue(
		hooks,
		{
			"CurrentQuestId",
			"QuestId",
			"QuestID",
			"QuestName",
			"CurrentQuest"
		}
	)

	local enemyName=readValue(
		hooks,
		{
			"CurrentEnemyName",
			"EnemyName",
			"TargetEnemy",
			"Enemy",
			"Target"
		}
	)

	local kills=readValue(
		hooks,
		{
			"QuestKills",
			"Kills",
			"CurrentKills",
			"Progress",
			"KillCount"
		}
	)

	local required=readValue(
		hooks,
		{
			"QuestRequired",
			"RequiredKills",
			"MaxKills",
			"Required",
			"Goal",
			"KillGoal"
		}
	)

	local active=readValue(
		hooks,
		{
			"QuestActive",
			"Active",
			"HasQuest",
			"IsQuestActive"
		}
	)

	local completed=readValue(
		hooks,
		{
			"QuestCompleted",
			"Completed",
			"IsCompleted"
		}
	)

	local quest={
		Id=questId,
		EnemyName=typeof(enemyName)=="string" and enemyName or nil,

		Kills=tonumber(kills) or 0,
		Required=tonumber(required) or 0,

		Active=active==true,
		Completed=completed==true,

		Container=hooks
	}

	QuestDiscovery.Cache=quest
	QuestDiscovery.LastUpdate=os.clock()

	return quest
end

--========================================================
-- REMOTE FINDER
--========================================================

local function findRemote(names)
	local containers={
		findFarmContainer(),
		game:GetService("ReplicatedStorage"),
		workspace,
		player
	}

	for _,container in ipairs(containers) do
		if container then
			for _,name in ipairs(names) do
				local object=container:FindFirstChild(name,true)

				if object then
					if object:IsA("RemoteEvent")
						or object:IsA("RemoteFunction")
						or object:IsA("BindableEvent")
						or object:IsA("BindableFunction") then

						return object
					end
				end
			end
		end
	end

	return nil
end

--========================================================
-- SAFE REMOTE CALL
--========================================================

local function invokeRemote(remote,...)
	if not remote then
		return false
	end

	local args={...}

	local success,result=pcall(function()

		if remote:IsA("RemoteEvent") then
			remote:FireServer(table.unpack(args))
			return true
		end

		if remote:IsA("RemoteFunction") then
			remote:InvokeServer(table.unpack(args))
			return true
		end

		if remote:IsA("BindableEvent") then
			remote:Fire(table.unpack(args))
			return true
		end

		if remote:IsA("BindableFunction") then
			remote:Invoke(table.unpack(args))
			return true
		end

		return false
	end)

	return success and result==true
end

--========================================================
-- QUEST ACCEPT
--========================================================

local function acceptQuest()
	local now=os.clock()

	if now-FarmState.LastQuestAction<FarmConfig.QuestActionCooldown then
		return false
	end

	local remote=findRemote({
		"AcceptQuest",
		"StartQuest",
		"TakeQuest",
		"GetQuest",
		"QuestAccept",
		"Accept"
	})

	if not remote then
		return false
	end

	FarmState.LastQuestAction=now

	local quest=discoverQuest()

	local success=false

	if quest and quest.Id~=nil then
		success=invokeRemote(remote,quest.Id)
	end

	if not success then
		success=invokeRemote(remote)
	end

	if success then
		invalidateQuest()
	end

	return success
end

--========================================================
-- QUEST TURN IN
--========================================================

local function turnInQuest()
	local now=os.clock()

	if now-FarmState.LastQuestAction<FarmConfig.QuestActionCooldown then
		return false
	end

	local remote=findRemote({
		"TurnInQuest",
		"CompleteQuest",
		"FinishQuest",
		"QuestComplete",
		"TurnQuest",
		"Complete"
	})

	if not remote then
		return false
	end

	FarmState.LastQuestAction=now

	local quest=discoverQuest()

	local success=false

	if quest and quest.Id~=nil then
		success=invokeRemote(remote,quest.Id)
	end

	if not success then
		success=invokeRemote(remote)
	end

	if success then
		invalidateQuest()
	end

	return success
end

--========================================================
-- ATTACK
--========================================================

local function attackTarget(target)
	if not target then
		return false
	end

	if not isAlive(target) then
		return false
	end

	local now=os.clock()

	if now-FarmState.LastAttack<FarmConfig.AttackCooldown then
		return false
	end

	local remote=findRemote({
		"Attack",
		"AttackEnemy",
		"Combat",
		"Hit",
		"Damage",
		"M1",
		"BasicAttack"
	})

	if not remote then
		return false
	end

	FarmState.LastAttack=now

	local success=false

	-- Cách 1: truyền enemy
	success=invokeRemote(remote,target)

	-- Cách 2: truyền Model + humanoid nếu game yêu cầu
	if not success then
		local humanoid=getHumanoidFrom(target)

		if humanoid then
			success=invokeRemote(
				remote,
				target,
				humanoid
			)
		end
	end

	return success
end

--========================================================
-- FIND ENEMY
--========================================================

local function findEnemy(quest)
	if not quest then
		return nil
	end

	local enemyName=quest.EnemyName

	if not enemyName
		or enemyName=="" then

		return nil
	end

	local characterRoot=getCharacterRoot()

	if not characterRoot then
		return nil
	end

	local enemiesFolder=
		workspace:FindFirstChild("Enemies")
		or workspace:FindFirstChild("Enemy")

	if not enemiesFolder then
		return nil
	end

	local nearest=nil
	local nearestDistance=math.huge

	for _,enemy in ipairs(enemiesFolder:GetDescendants()) do

		if enemy:IsA("Model") then

			local nameMatch=
				enemy.Name==enemyName
				or string.lower(enemy.Name)==string.lower(enemyName)

			if nameMatch then

				local humanoid=getHumanoidFrom(enemy)
				local enemyRoot=getRoot(enemy)

				if humanoid
					and humanoid.Health>0
					and enemyRoot then

					local distance=
						(characterRoot.Position-enemyRoot.Position).Magnitude

					if distance<=FarmConfig.SearchDistance
						and distance<nearestDistance then

						nearest=enemy
						nearestDistance=distance
					end
				end
			end
		end
	end

	return nearest
end

--========================================================
-- FLY SYSTEM
--========================================================

local FlyState={
	Enabled=false,

	Attachment=nil,
	LinearVelocity=nil,
	AlignOrientation=nil
}

local function cleanupFly()
	if FlyState.LinearVelocity then
		FlyState.LinearVelocity:Destroy()
		FlyState.LinearVelocity=nil
	end

	if FlyState.AlignOrientation then
		FlyState.AlignOrientation:Destroy()
		FlyState.AlignOrientation=nil
	end

	if FlyState.Attachment then
		FlyState.Attachment:Destroy()
		FlyState.Attachment=nil
	end

	local root=getCharacterRoot()

	if root then
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
	end

	local humanoid=getHumanoid()

	if humanoid then
		humanoid.PlatformStand=false
		humanoid.AutoRotate=true
	end
end

local function setupFly()
	cleanupFly()

	local root=getCharacterRoot()
	local humanoid=getHumanoid()

	if not root or not humanoid then
		return false
	end

	local attachment=Instance.new("Attachment")

	attachment.Name="LPT_FlyAttachment"
	attachment.Parent=root

	local velocity=Instance.new("LinearVelocity")

	velocity.Name="LPT_FlyVelocity"
	velocity.Attachment0=attachment
	velocity.RelativeTo=Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity=Vector3.zero
	velocity.MaxForce=math.huge
	velocity.Parent=root

	local orientation=Instance.new("AlignOrientation")

	orientation.Name="LPT_FlyOrientation"
	orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0=attachment
	orientation.MaxTorque=math.huge
	orientation.Responsiveness=40
	orientation.RigidityEnabled=false
	orientation.Parent=root

	FlyState.Attachment=attachment
	FlyState.LinearVelocity=velocity
	FlyState.AlignOrientation=orientation

	humanoid.PlatformStand=true
	humanoid.AutoRotate=false

	return true
end

local function setFly(enabled)
	FlyState.Enabled=enabled==true

	if not FlyState.Enabled then
		cleanupFly()
		return
	end

	setupFly()
end

--========================================================
-- FLY TO TARGET
--========================================================

local function flyToTarget(target)
	if not FlyState.Enabled then
		return false
	end

	if not target or not target.Parent then
		return false
	end

	local root=getCharacterRoot()
	local targetRoot=getRoot(target)

	if not root or not targetRoot then
		return false
	end

	if not FlyState.LinearVelocity
		or not FlyState.LinearVelocity.Parent
		or not FlyState.AlignOrientation
		or not FlyState.AlignOrientation.Parent then

		if not setupFly() then
			return false
		end
	end

	local targetPosition=
		targetRoot.Position+
		Vector3.new(
			FarmConfig.MoveOffset.X,
			FarmConfig.FlyHeight,
			FarmConfig.MoveOffset.Z
		)

	local offset=targetPosition-root.Position
	local distance=offset.Magnitude

	if distance<=FarmConfig.AttackDistance then

		FlyState.LinearVelocity.VectorVelocity=Vector3.zero

		FlyState.AlignOrientation.CFrame=
			CFrame.lookAt(
				root.Position,
				targetRoot.Position
			)

		return true
	end

	if distance<=0.01 then
		return true
	end

	local direction=offset.Unit

	FlyState.LinearVelocity.VectorVelocity=
		direction*FarmConfig.FlySpeed

	FlyState.AlignOrientation.CFrame=
		CFrame.lookAt(
			root.Position,
			targetRoot.Position
		)

	return false
end

--========================================================
-- TARGET VALIDATION
--========================================================

local function targetStillValid(target,quest)
	if not target then
		return false
	end

	if not target.Parent then
		return false
	end

	if not isAlive(target) then
		return false
	end

	if quest
		and quest.EnemyName
		and target.Name~=quest.EnemyName then

		return false
	end

	return true
end

--========================================================
-- STOP
--========================================================

local function stopFarm()
	FarmState.Running=false
	FarmState.State="Idle"
	FarmState.Level=0
	FarmState.Quest=nil
	FarmState.Target=nil

	FarmState.Session+=1
	FarmState.LastQuestAction=0
	FarmState.LastAttack=0
	FarmState.LastTargetScan=0

	invalidateQuest()

	setFly(false)
end

--========================================================
-- CHARACTER RESPAWN
--========================================================

player.CharacterAdded:Connect(function()
	if not FarmState.Running then
		return
	end

	FarmState.State="Waiting Character"
	FarmState.Target=nil
	FarmState.Quest=nil

	invalidateQuest()

	task.wait(.7)

	if FarmState.Running then
		setFly(true)
	end
end)

--========================================================
-- START FARM
--========================================================

local gui

local function startFarm()
	if FarmState.Running then
		return
	end

	FarmState.Running=true
	FarmState.Session+=1

	local session=FarmState.Session

	FarmState.State="Starting"

	setFly(true)

	task.spawn(function()

		while
			FarmState.Running
			and FarmState.Session==session
			and gui
			and gui.Parent
		do

			--================================================
			-- CHARACTER CHECK
			--================================================

			local character=getCharacter()
			local humanoid=getHumanoid()
			local root=getCharacterRoot()

			if not character
				or not humanoid
				or not root
				or humanoid.Health<=0 then

				FarmState.State="Waiting Character"

				task.wait(.35)

				continue
			end

			--================================================
			-- LEVEL
			--================================================

			FarmState.State="Reading Level"

			local level=getLevel()

			FarmState.Level=level

			if level<=0 then
				task.wait(FarmConfig.SearchDelay)
				continue
			end

			--================================================
			-- QUEST
			--================================================

			FarmState.State="Detecting Quest"

			local quest=discoverQuest()

			-- Không có quest dữ liệu
			if not quest then

				FarmState.State="Searching Quest"

				local accepted=acceptQuest()

				if accepted then
					task.wait(.35)
				else
					task.wait(FarmConfig.SearchDelay)
				end

				continue
			end

			FarmState.Quest=quest

			--================================================
			-- COMPLETED CHECK
			--================================================

			local completed=
				quest.Completed
				or (
					quest.Required>0
					and quest.Kills>=quest.Required
				)

			if completed then

				FarmState.State="Turning In Quest"

				local turnedIn=turnInQuest()

				if turnedIn then
					FarmState.Target=nil
					FarmState.Quest=nil
					invalidateQuest()

					task.wait(.35)
				else
					task.wait(FarmConfig.SearchDelay)
				end

				continue
			end

			--================================================
			-- ACTIVE QUEST CHECK
			--================================================

			if not quest.Active then

				FarmState.State="Accepting Quest"

				local accepted=acceptQuest()

				if accepted then
					FarmState.Target=nil
					invalidateQuest()

					task.wait(.35)
				else
					task.wait(FarmConfig.SearchDelay)
				end

				continue
			end

			--================================================
			-- ENEMY NAME CHECK
			--================================================

			if not quest.EnemyName
				or quest.EnemyName=="" then

				FarmState.State="Waiting Quest Target"

				task.wait(FarmConfig.SearchDelay)

				continue
			end

			--================================================
			-- CURRENT TARGET
			--================================================

			local target=FarmState.Target

			if not targetStillValid(target,quest) then

				local now=os.clock()

				if now-FarmState.LastTargetScan>=FarmConfig.SearchDelay then

					FarmState.LastTargetScan=now

					FarmState.State=
						"Searching "..tostring(quest.EnemyName)

					target=findEnemy(quest)

					FarmState.Target=target
				end
			end

			--================================================
			-- NO TARGET
			--================================================

			if not targetStillValid(target,quest) then

				FarmState.State=
					"Waiting "..tostring(quest.EnemyName)

				task.wait(FarmConfig.SearchDelay)

				continue
			end

			--================================================
			-- FLY
			--================================================

			FarmState.Target=target
			FarmState.State="Flying"

			local reached=flyToTarget(target)

			--================================================
			-- ATTACK
			--================================================

			if reached
				and targetStillValid(target,quest) then

				FarmState.State="Combat"

				attackTarget(target)
			end

			--================================================
			-- TARGET DEAD
			--================================================

			if not isAlive(target) then

				FarmState.Target=nil

				invalidateQuest()
			end

			task.wait(FarmConfig.LoopDelay)
		end

		setFly(false)

		if FarmState.Session==session then
			FarmState.State="Idle"
			FarmState.Target=nil
		end
	end)
end

--========================================================
-- GUI
--========================================================

gui=Instance.new("ScreenGui")
gui.Name="LPTHub"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=2147483647
gui.Parent=playerGui

local main=Instance.new("Frame")
main.Name="MainWindow"
main.Size=UDim2.fromOffset(780,500)
main.Position=UDim2.new(.5,-390,.5,-250)
main.BackgroundColor3=COLORS.Background
main.BorderSizePixel=0
main.ClipsDescendants=true
main.Parent=gui

createCorner(main,8)

local mainStroke=createStroke(main,COLORS.Border,.1,2)
gradient(mainStroke,COLORS.Accent,COLORS.AccentB,45)

--========================================================
-- TOP BAR
--========================================================

local topBar=Instance.new("Frame")
topBar.Name="TopBar"
topBar.Size=UDim2.new(1,0,0,38)
topBar.BackgroundColor3=COLORS.Surface
topBar.BorderSizePixel=0
topBar.Parent=main

createCorner(topBar,20)

local topMask=Instance.new("Frame")
topMask.Size=UDim2.new(1,0,0,20)
topMask.Position=UDim2.new(0,0,1,-20)
topMask.BackgroundColor3=COLORS.Surface
topMask.BorderSizePixel=0
topMask.Parent=topBar

local dot=Instance.new("Frame")
dot.Size=UDim2.fromOffset(8,8)
dot.Position=UDim2.new(0,20,.5,-4)
dot.BackgroundColor3=COLORS.Success
dot.BorderSizePixel=0
dot.ZIndex=2
dot.Parent=topBar

createCorner(dot,50)

local dotPulse=Instance.new("Frame")
dotPulse.Size=UDim2.fromOffset(8,8)
dotPulse.Position=UDim2.new(.5,-4,.5,-4)
dotPulse.BackgroundColor3=COLORS.Success
dotPulse.BackgroundTransparency=.3
dotPulse.BorderSizePixel=0
dotPulse.Parent=dot

createCorner(dotPulse,50)

task.spawn(function()
	while dotPulse.Parent do
		dotPulse.Size=UDim2.fromOffset(8,8)
		dotPulse.Position=UDim2.new(.5,-4,.5,-4)
		dotPulse.BackgroundTransparency=.3

		tween(dotPulse,{
			Size=UDim2.fromOffset(22,22),
			Position=UDim2.new(.5,-11,.5,-11),
			BackgroundTransparency=1
		},1.1)

		task.wait(1.1)
	end
end)

local title=createLabel(
	topBar,
	"LPT Hub",
	UDim2.fromOffset(105,38),
	UDim2.fromOffset(36,0),
	Enum.Font.GothamBold,
	18.5,
	COLORS.Text
)

gradient(title,COLORS.Accent,COLORS.AccentB,0)

local author=createLabel(
	topBar,
	"by Ly Phuc Thien",
	UDim2.fromOffset(170,38),
	UDim2.fromOffset(113,0),
	Enum.Font.Gotham,
	11,
	COLORS.TextDim
)

local separator=Instance.new("Frame")
separator.Size=UDim2.new(1,0,0,1)
separator.Position=UDim2.new(0,0,1,-1)
separator.BackgroundColor3=COLORS.Border
separator.BorderSizePixel=0
separator.Parent=topBar

--========================================================
-- WINDOW BUTTONS
--========================================================

local function topButton(name,x,text,size)
	local b=Instance.new("TextButton")
	b.Name=name
	b.Size=UDim2.fromOffset(30,26)
	b.Position=UDim2.new(1,x,.5,-13)
	b.BackgroundColor3=COLORS.SurfaceLight
	b.BackgroundTransparency=1
	b.BorderSizePixel=0
	b.Text=text
	b.TextColor3=COLORS.TextDim
	b.TextSize=size
	b.Font=Enum.Font.GothamMedium
	b.AutoButtonColor=false
	b.Parent=topBar

	createCorner(b,10)

	return b
end

local minimize=topButton("MinimizeButton", -110, "—", 13)
local maximize=topButton("MaximizeButton", -76, "", 0)
local close=topButton("CloseButton", -40, "×", 17)

local maxIcon=Instance.new("Frame")
maxIcon.Size=UDim2.fromOffset(20,20)
maxIcon.Position=UDim2.new(.5,-10,.5,-10)
maxIcon.BackgroundTransparency=1
maxIcon.Parent=maximize

local normalIcon=Instance.new("Frame")
normalIcon.Size=UDim2.fromOffset(13,13)
normalIcon.Position=UDim2.new(.5,-6,.5,-6)
normalIcon.BackgroundTransparency=1
normalIcon.Parent=maxIcon

createCorner(normalIcon,3)

local normalStroke=createStroke(
	normalIcon,
	COLORS.TextDim,
	0,
	1.5
)

local restoreBack=Instance.new("Frame")
restoreBack.Size=UDim2.fromOffset(11,11)
restoreBack.Position=UDim2.fromOffset(6,2)
restoreBack.BackgroundTransparency=1
restoreBack.Visible=false
restoreBack.Parent=maxIcon

createCorner(restoreBack,2)

local restoreBackStroke=createStroke(
	restoreBack,
	COLORS.TextDim,
	0,
	1.5
)

local restoreFront=Instance.new("Frame")
restoreFront.Size=UDim2.fromOffset(11,11)
restoreFront.Position=UDim2.fromOffset(2,6)
restoreFront.BackgroundColor3=COLORS.Surface
restoreFront.BorderSizePixel=0
restoreFront.Visible=false
restoreFront.Parent=maxIcon

createCorner(restoreFront,2)

local restoreFrontStroke=createStroke(
	restoreFront,
	COLORS.TextDim,
	0,
	1.5
)

local function setupTopButton(button,color,bg)
	button.MouseEnter:Connect(function()
		tween(button,{
			TextColor3=color,
			BackgroundTransparency=0,
			BackgroundColor3=bg or COLORS.SurfaceLight
		},.15)
	end)

	button.MouseLeave:Connect(function()
		tween(button,{
			TextColor3=COLORS.TextDim,
			BackgroundTransparency=1
		},.15)
	end)
end

setupTopButton(minimize,COLORS.Text)
setupTopButton(close,Color3.new(1,1,1),COLORS.Danger)

maximize.MouseEnter:Connect(function()
	tween(maximize,{BackgroundTransparency=0},.15)
	tween(normalStroke,{Color=COLORS.Text},.15)
	tween(restoreBackStroke,{Color=COLORS.Text},.15)
	tween(restoreFrontStroke,{Color=COLORS.Text},.15)
end)

maximize.MouseLeave:Connect(function()
	tween(maximize,{BackgroundTransparency=1},.15)
	tween(normalStroke,{Color=COLORS.TextDim},.15)
	tween(restoreBackStroke,{Color=COLORS.TextDim},.15)
	tween(restoreFrontStroke,{Color=COLORS.TextDim},.15)
end)

--========================================================
-- SIDEBAR
--========================================================

local sidebar=Instance.new("Frame")
sidebar.Name="Sidebar"
sidebar.Size=UDim2.new(0,220,1,-38)
sidebar.Position=UDim2.fromOffset(0,38)
sidebar.BackgroundColor3=COLORS.Surface
sidebar.BorderSizePixel=0
sidebar.ClipsDescendants=true
sidebar.Parent=main

createCorner(sidebar,20)

local sidebarMask=Instance.new("Frame")
sidebarMask.Size=UDim2.new(1,0,0,20)
sidebarMask.BackgroundColor3=COLORS.Surface
sidebarMask.BorderSizePixel=0
sidebarMask.Parent=sidebar

local sideLine=Instance.new("Frame")
sideLine.Size=UDim2.new(0,1,1,0)
sideLine.Position=UDim2.new(1,-1,0,0)
sideLine.BackgroundColor3=COLORS.Border
sideLine.BorderSizePixel=0
sideLine.Parent=sidebar

local sidebarContainer=Instance.new("Frame")
sidebarContainer.Name="SidebarButtons"
sidebarContainer.Size=UDim2.new(1,-8,1,-8)
sidebarContainer.Position=UDim2.fromOffset(0,4)
sidebarContainer.BackgroundTransparency=1
sidebarContainer.BorderSizePixel=0
sidebarContainer.Parent=sidebar

--========================================================
-- CONTENT
--========================================================

local content=Instance.new("Frame")
content.Name="Content"
content.Size=UDim2.new(1,-220,1,-38)
content.Position=UDim2.fromOffset(220,38)
content.BackgroundTransparency=1
content.Parent=main

local pages={}

local function createPage(name,titleText,description)
	local page=Instance.new("ScrollingFrame")
	page.Name=name
	page.Size=UDim2.fromScale(1,1)
	page.BackgroundTransparency=1
	page.BorderSizePixel=0
	page.ScrollBarThickness=3
	page.ScrollBarImageColor3=SIDEBAR_ACCENT
	page.ScrollBarImageTransparency=.2
	page.CanvasSize=UDim2.fromOffset(0,650)
	page.Visible=false
	page.Parent=content

	pages[name]=page

	createLabel(
		page,
		titleText,
		UDim2.new(1,-56,0,38),
		UDim2.fromOffset(28,18),
		Enum.Font.GothamBold,
		28,
		COLORS.Text
	)

	if description then
		createLabel(
			page,
			description,
			UDim2.new(1,-56,0,20),
			UDim2.fromOffset(28,52),
			Enum.Font.Gotham,
			13,
			COLORS.TextDim
		)
	end

	return page
end

local shopPage=createPage(
	"Shop",
	"Shop",
	"Shop and available items."
)

local statusPage=createPage(
	"StatusAndServer",
	"Status And Server",
	"Server information and status."
)

local localPlayerPage=createPage(
	"LocalPlayer",
	"LocalPlayer",
	"Player movement and character settings."
)

local settingFarmPage=createPage(
	"SettingFarm",
	"Setting Farm",
	"Farm configuration."
)

local holdSkillPage=createPage(
	"HoldAndSelectSkill",
	"Hold and Select Skill",
	"Skill selection and hold settings."
)

local farmingPage=createPage(
	"Farming",
	"Farming",
	"Main farming functions."
)

local espPage=createPage(
	"ESP",
	"ESP"
)

--========================================================
-- CARD / TOGGLE / CHECKBOX
--========================================================

local function createCard(parent,text,y,height)
	local frame=Instance.new("Frame")
	frame.Size=UDim2.new(1,-56,0,height or 58)
	frame.Position=UDim2.fromOffset(28,y)
	frame.BackgroundColor3=COLORS.Card
	frame.BorderSizePixel=0
	frame.Parent=parent

	createCorner(frame,14)
	createStroke(frame,COLORS.Border,.15,1)

	createLabel(
		frame,
		text,
		UDim2.new(1,-36,1,0),
		UDim2.fromOffset(18,0),
		Enum.Font.GothamMedium,
		14,
		COLORS.Text
	)

	frame.MouseEnter:Connect(function()
		tween(frame,{BackgroundColor3=COLORS.CardHover},.15)
	end)

	frame.MouseLeave:Connect(function()
		tween(frame,{BackgroundColor3=COLORS.Card},.15)
	end)

	return frame
end

local function createToggle(parent,text,y,default,callback)
	local row=createCard(parent,text,y,58)

	local button=Instance.new("TextButton")
	button.Size=UDim2.fromOffset(48,24)
	button.Position=UDim2.new(1,-68,.5,-12)
	button.BackgroundColor3=Color3.fromRGB(80,84,95)
	button.BackgroundTransparency=.15
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=row

	createCorner(button,50)

	local knob=Instance.new("Frame")
	knob.Size=UDim2.fromOffset(20,20)
	knob.Position=UDim2.fromOffset(2,2)
	knob.BackgroundColor3=Color3.fromRGB(225,227,232)
	knob.BorderSizePixel=0
	knob.Parent=button

	createCorner(knob,50)

	local enabled=default==true

	local function setEnabled(value,fire)
		enabled=value==true

		tween(button,{
			BackgroundColor3=enabled and SIDEBAR_ACCENT or Color3.fromRGB(80,84,95),
			BackgroundTransparency=enabled and 0 or .15
		},.18)

		tween(knob,{
			Position=enabled and UDim2.new(1,-22,0,2) or UDim2.fromOffset(2,2)
		},.18)

		if fire~=false and callback then
			callback(enabled)
		end
	end

	button.MouseButton1Click:Connect(function()
		setEnabled(not enabled,true)
	end)

	setEnabled(enabled,false)

	return setEnabled
end

local function createCheckbox(parent,text,y,default,callback)
	local row=createCard(parent,text,y,58)

	local button=Instance.new("TextButton")
	button.Size=UDim2.fromOffset(28,28)
	button.Position=UDim2.new(1,-48,.5,-14)
	button.BackgroundColor3=COLORS.Card
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=row

	createCorner(button,7)

	-- Luôn có viền xanh dương ở cả trạng thái bật và tắt.
	local stroke=createStroke(
		button,
		SIDEBAR_ACCENT,
		0,
		1.5
	)

	local check=Instance.new("TextLabel")
	check.Size=UDim2.fromScale(1,1)
	check.BackgroundTransparency=1
	check.Text="✓"
	check.Font=Enum.Font.GothamBold
	check.TextSize=18
	check.TextColor3=Color3.new(1,1,1)
	check.TextTransparency=1
	check.Visible=false
	check.Parent=button

	local enabled=default==true

	local function setEnabled(value,fire)
		enabled=value==true

		if enabled then
			tween(button,{
				BackgroundColor3=SIDEBAR_ACCENT
			},.15)

			tween(stroke,{
				Color=SIDEBAR_ACCENT,
				Transparency=0
			},.15)

			check.Visible=true

			tween(check,{
				TextTransparency=0
			},.12)
		else
			tween(button,{
				BackgroundColor3=COLORS.Card
			},.15)

			tween(stroke,{
				Color=SIDEBAR_ACCENT,
				Transparency=0
			},.15)

			tween(check,{
				TextTransparency=1
			},.12)

			task.delay(.12,function()
				if not enabled then
					check.Visible=false
				end
			end)
		end

		if fire~=false and callback then
			callback(enabled)
		end
	end

	button.MouseButton1Click:Connect(function()
		setEnabled(not enabled,true)
	end)


	setEnabled(enabled,false)

	return setEnabled
end

--========================================================
-- PAGES CONTENT
--========================================================

createCard(shopPage,"Shop",95)
createCard(shopPage,"Available Items",161)

shopPage.CanvasSize=UDim2.fromOffset(0,250)

local serverCard=createCard(statusPage,"Server Status",95,105)

createLabel(serverCard,"STATUS",UDim2.fromOffset(100,18),UDim2.fromOffset(18,8),Enum.Font.GothamBold,11,COLORS.TextDim)
createLabel(serverCard,"Online",UDim2.fromOffset(180,24),UDim2.fromOffset(18,31),Enum.Font.GothamBold,17,COLORS.Success)
createLabel(serverCard,"SERVER",UDim2.fromOffset(100,18),UDim2.fromOffset(220,8),Enum.Font.GothamBold,11,COLORS.TextDim)
createLabel(serverCard,"Connected",UDim2.fromOffset(180,24),UDim2.fromOffset(220,31),Enum.Font.GothamMedium,15,COLORS.Text)

createCard(statusPage,"Server Information",218)
createCard(statusPage,"Players / Server",284)

statusPage.CanvasSize=UDim2.fromOffset(0,370)

createToggle(localPlayerPage,"WalkSpeed",95,false)
createToggle(localPlayerPage,"JumpPower",161,false)
createToggle(localPlayerPage,"No Clip",227,false)
createToggle(localPlayerPage,"Fly",293,false)

localPlayerPage.CanvasSize=UDim2.fromOffset(0,390)

createToggle(settingFarmPage,"Auto Farm Settings",95,false)
createToggle(settingFarmPage,"Auto Collect",161,false)
createToggle(settingFarmPage,"Auto Buy",227,false)
createToggle(settingFarmPage,"Auto Plant",293,false)

settingFarmPage.CanvasSize=UDim2.fromOffset(0,360)

createCard(holdSkillPage,"Select Skill",95)
createToggle(holdSkillPage,"Hold Skill",161,false)
createToggle(holdSkillPage,"Auto Select Skill",227,false)
createToggle(holdSkillPage,"Use Selected Skill",293,false)

holdSkillPage.CanvasSize=UDim2.fromOffset(0,360)

createToggle(
	farmingPage,
	"Auto Farm",
	95,
	false,
	function(enabled)
		if enabled then
			startFarm()
		else
			stopFarm()
		end
	end
)

farmingPage.CanvasSize=UDim2.fromOffset(0,190)

--========================================================
-- ESP SYSTEM
--========================================================

local ESP={
	Player=false,
	Island=false,
	Fruit=false,
	Berry=false
}

local ESPObjects={}

local ESP_COLORS={
	Player=Color3.fromRGB(56,189,248),
	Island=Color3.fromRGB(168,105,245),
	Fruit=Color3.fromRGB(74,222,128),
	Berry=Color3.fromRGB(236,72,153)
}

local function isFruitObject(object)
	if not object or not object:IsA("Tool") then
		return false
	end

	return string.find(
		string.lower(object.Name),
		"fruit",
		1,
		true
	) ~= nil
end

local function getESPModelPart(object)
	if not object or not object.Parent then
		return nil
	end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then
		return object:FindFirstChild("HumanoidRootPart",true)
			or object:FindFirstChild("Head",true)
			or object:FindFirstChild("Handle",true)
			or object:FindFirstChild("RootPart",true)
			or object.PrimaryPart
			or object:FindFirstChildWhichIsA("BasePart",true)
	end

	return object:FindFirstChildWhichIsA("BasePart",true)
end

local function getESPAdornee(object)
	if not object or not object.Parent then
		return nil
	end

	if object:IsA("Model") then
		return object
	end

	if object:IsA("BasePart") then
		return object
	end

	return getESPModelPart(object)
end

local function getESPPosition(object)
	local part=getESPModelPart(object)
	return part and part.Position or nil
end

local function removeESP(object)
	local data=ESPObjects[object]

	if not data then
		return
	end

	if data.highlight then
		data.highlight:Destroy()
	end

	if data.label then
		data.label:Destroy()
	end

	ESPObjects[object]=nil
end

local function clearESPType(typeName)
	local toRemove={}

	for object,data in pairs(ESPObjects) do
		if data.type==typeName then
			table.insert(toRemove,object)
		end
	end

	for _,object in ipairs(toRemove) do
		removeESP(object)
	end
end

--========================================================
-- CREATE ESP
--========================================================

local function createESP(object,typeName,displayName)
	if not object or not object.Parent then
		return false
	end

	if not ESP[typeName] then
		return false
	end

	if ESPObjects[object] then
		return true
	end

	local adornee=getESPAdornee(object)
	local worldPart=getESPModelPart(object)

	if not adornee or not worldPart then
		return false
	end

	local color=ESP_COLORS[typeName]

	local highlight=nil

	if typeName~="Island" then
		highlight=Instance.new("Highlight")
		highlight.Name="LPT_ESP_Highlight"
		highlight.Adornee=adornee
		highlight.FillColor=color
		highlight.OutlineColor=color
		highlight.FillTransparency=.78
		highlight.OutlineTransparency=0
		highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent=object
	end

	local label=Instance.new("TextLabel")
	label.Name="LPT_ESP_Label"
	label.Size=UDim2.fromOffset(240,44)
	label.AnchorPoint=Vector2.new(.5,.5)
	label.BackgroundTransparency=1
	label.Text=displayName or object.Name

	label.TextColor3=typeName=="Island"
		and Color3.fromRGB(255,255,255)
		or color

	label.TextStrokeColor3=Color3.new(0,0,0)
	label.TextStrokeTransparency=.1
	label.TextSize=15
	label.Font=Enum.Font.GothamBold
	label.TextXAlignment=Enum.TextXAlignment.Center
	label.TextYAlignment=Enum.TextYAlignment.Center
	label.Visible=false
	label.ZIndex=100

	label.Parent=espGui

	ESPObjects[object]={
		type=typeName,
		highlight=highlight,
		label=label,
		worldPart=worldPart,
		name=displayName or object.Name
	}

	return true
end

--========================================================
-- WORLD FOLDER FINDER
--========================================================

local WORLD_FOLDER_NAMES={
	Berry={"Berries","Berry"},
	Island={"Map"}
}

local function findWorldFolder(typeName)
	local names=WORLD_FOLDER_NAMES[typeName]

	if not names then
		return nil
	end

	for _,name in ipairs(names) do
		local direct=workspace:FindFirstChild(name)

		if direct then
			return direct
		end
	end

	for _,name in ipairs(names) do
		for _,object in ipairs(workspace:GetDescendants()) do
			if object.Name==name
				and (object:IsA("Folder") or object:IsA("Model")) then

				return object
			end
		end
	end

	return nil
end

--========================================================
-- ISLAND ESP
--========================================================

local islandConnections={}

local function scanIslandESP()
	if not ESP.Island then
		return
	end

	local map=workspace:FindFirstChild("Map")

	if not map then
		return
	end

	for _,island in ipairs(map:GetChildren()) do
		if island:IsA("Model") then
			createESP(
				island,
				"Island",
				island.Name
			)
		end
	end
end

local function setupIslandESPWatcher()
	if islandConnections.setup then
		return
	end

	local map=workspace:FindFirstChild("Map")

	if not map then
		return
	end

	islandConnections.setup=true

	islandConnections.added=map.ChildAdded:Connect(function(object)
		if not ESP.Island then
			return
		end

		if object:IsA("Model") then
			task.wait(.1)

			if object.Parent and ESP.Island then
				createESP(
					object,
					"Island",
					object.Name
				)
			end
		end
	end)

	islandConnections.removed=map.ChildRemoved:Connect(function(object)
		removeESP(object)
	end)
end

setupIslandESPWatcher()

--========================================================
-- FRUIT ESP
--========================================================

local function scanFruitESP()
	if not ESP.Fruit then
		return
	end

	for _,object in ipairs(workspace:GetDescendants()) do
		if isFruitObject(object) then
			createESP(object,"Fruit",object.Name)
		end
	end
end

--========================================================
-- PLAYER ESP
--========================================================

local function addPlayerESP(target)
	if target==player or not ESP.Player then
		return
	end

	local character=target.Character
	if not character or not character.Parent then
		return
	end

	local humanoid=character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health<=0 then
		return
	end

	for _=1,10 do
		if getESPModelPart(character) then
			break
		end
		task.wait(.1)
	end

	if ESP.Player and target.Parent and character.Parent then
		createESP(character,"Player",target.DisplayName)
	end
end

local function refreshPlayerESP()
	clearESPType("Player")

	if not ESP.Player then
		return
	end

	for _,target in ipairs(Players:GetPlayers()) do
		if target~=player then
			task.spawn(addPlayerESP,target)
		end
	end
end

--========================================================
-- BERRY ESP
--========================================================

local BerryCache={}
local BerryESPObjects={}

--========================================================
-- BERRY NAME READER
--========================================================

local function getBerryNames(config)
	local names={}

	if not config then
		return names
	end

	for i=1,4 do
		local value=config:GetAttribute("_BerryCFrame"..i)

		if typeof(value)=="string" and value~="" then
			names[i]=value
		end
	end

	return names
end

--========================================================
-- CACHE BERRY BUSH
--========================================================

local function cacheBerryBush(config)
	if not config
		or not config:IsA("Configuration")
		or config.Name~="Berries" then
		return
	end

	local bush=config.Parent

	if not bush or not bush:IsA("Model") then
		return
	end

	local entry=BerryCache[config]

	if not entry then
		entry={
			config=config,
			bush=bush,
			slots={}
		}

		BerryCache[config]=entry
	end

	local bushCFrame=bush:GetPivot()

	entry.bush=bush
	entry.bushCFrame=bushCFrame

	local names=getBerryNames(config)

	-- Reset slot data để tránh dữ liệu cũ
	entry.slots={}

	for _,berry in ipairs(config:GetChildren()) do
		if berry:IsA("Model") then

			local berryCFrame=berry:GetPivot()

			local relative=
				bushCFrame:ToObjectSpace(
					berryCFrame
				)

			local slotIndex=#entry.slots+1

			if slotIndex<=4 then
				entry.slots[slotIndex]={
					name=names[slotIndex] or berry.Name or "Berry",
					relative=relative
				}
			end
		end
	end
end

--========================================================
-- SCAN BERRY CACHE
--========================================================

local function scanBerryCache()
	local map=workspace:FindFirstChild("Map")

	if not map then
		return
	end

	for _,object in ipairs(map:GetDescendants()) do
		if object.Name=="Berries"
			and object:IsA("Configuration") then

			cacheBerryBush(object)
		end
	end
end

--========================================================
-- CREATE BERRY ESP
--========================================================

local function createBerryESP(id,position,name)
	if not ESP.Berry then
		return
	end

	local data=BerryESPObjects[id]

	if not data then
		local label=Instance.new("TextLabel")

		label.Name="LPT_BerryESP_"..tostring(id)
		label.Size=UDim2.fromOffset(240,28)
		label.AnchorPoint=Vector2.new(.5,.5)
		label.BackgroundTransparency=1
		label.TextColor3=ESP_COLORS.Berry
		label.TextStrokeColor3=Color3.new(0,0,0)
		label.TextStrokeTransparency=.1
		label.TextSize=15
		label.Font=Enum.Font.GothamBold
		label.TextXAlignment=Enum.TextXAlignment.Center
		label.TextYAlignment=Enum.TextYAlignment.Center
		label.Visible=false
		label.ZIndex=100
		label.Parent=espGui

		data={
			type="Berry",
			label=label,
			position=nil,
			name="Berry"
		}

		BerryESPObjects[id]=data
	end

	data.position=position
	data.name=name or "Berry"
	data.label.Text=data.name
end

--========================================================
-- CLEAR BERRY ESP
--========================================================

local function clearBerryESP()
	for _,data in pairs(BerryESPObjects) do
		if data and data.label then
			data.label:Destroy()
		end
	end

	table.clear(BerryESPObjects)
end

--========================================================
-- REFRESH BERRY ESP
--========================================================

local function refreshBerryESP()
	clearBerryESP()

	if not ESP.Berry then
		return
	end

	scanBerryCache()

	local id=0

	for _,entry in pairs(BerryCache) do
		local bush=entry.bush

		if bush and bush.Parent then
			local bushCFrame=bush:GetPivot()

			for _,slot in ipairs(entry.slots) do
				if slot and slot.relative then

					id+=1

					local worldCFrame=
						bushCFrame*slot.relative

					createBerryESP(
						id,
						worldCFrame.Position,
						slot.name or "Berry"
					)
				end
			end
		end
	end
end

--========================================================
-- BERRY LIVE UPDATE
--========================================================

workspace.DescendantAdded:Connect(function(object)

	if object.Name=="Berries"
		and object:IsA("Configuration") then

		task.defer(function()
			if object.Parent then
				cacheBerryBush(object)

				if ESP.Berry then
					refreshBerryESP()
				end
			end
		end)

		return
	end

	if object:IsA("Model") then

		local parent=object.Parent

		if parent
			and parent.Name=="Berries"
			and parent:IsA("Configuration") then

			task.defer(function()
				if parent.Parent then
					cacheBerryBush(parent)

					if ESP.Berry then
						refreshBerryESP()
					end
				end
			end)
		end
	end
end)

workspace.DescendantRemoving:Connect(function(object)

	if not object then
		return
	end

	if object:IsA("Configuration")
		and object.Name=="Berries" then

		BerryCache[object]=nil

		if ESP.Berry then
			task.defer(refreshBerryESP)
		end

		return
	end

	if object:IsA("Model") then
		local parent=object.Parent

		if parent
			and parent:IsA("Configuration")
			and parent.Name=="Berries" then

			task.defer(function()

				if parent.Parent then
					cacheBerryBush(parent)
				end

				if ESP.Berry then
					refreshBerryESP()
				end
			end)
		end
	end
end)

--========================================================
-- WORLD ESP REFRESH
--========================================================

local function refreshWorldESP()

	-- Island / Fruit
	clearESPType("Island")
	clearESPType("Fruit")

	-- Berry
	if ESP.Berry then
		refreshBerryESP()
	else
		clearBerryESP()
	end

	-- Island
	if ESP.Island then
		scanIslandESP()
	end

	-- Fruit
	if ESP.Fruit then
		scanFruitESP()
	end
end

--========================================================
-- FULL ESP REFRESH
--========================================================

local function refreshESP()
	refreshPlayerESP()
	refreshWorldESP()
end

--========================================================
-- SET ESP
--========================================================

local function setESP(typeName,enabled)

	ESP[typeName]=enabled==true

	if typeName=="Player" then
		refreshPlayerESP()
	else
		refreshWorldESP()
	end
end

--========================================================
-- ESP SCREEN UPDATE
-- Không bám mép màn hình
--========================================================

RunService.RenderStepped:Connect(function()

	local camera=workspace.CurrentCamera

	if not camera then
		return
	end

	local character=player.Character
	local root=
		character
		and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local toRemove={}

	--====================================================
	-- PLAYER / ISLAND / FRUIT
	--====================================================

	for object,data in pairs(ESPObjects) do

		if not object
			or not object.Parent
			or not data.worldPart
			or not data.worldPart.Parent
			or not data.label
			or not data.label.Parent then

			table.insert(toRemove,object)
			continue
		end

		local position=data.worldPart.Position

		local distance=math.floor(
			(root.Position-position).Magnitude+.5
		)

		local screenPosition,onScreen=
			camera:WorldToViewportPoint(
				position+Vector3.new(0,3,0)
			)

		-- Chỉ hiện trong màn hình.
		-- Không clamp vào cạnh.
		if onScreen and screenPosition.Z>0 then

			data.label.Position=
				UDim2.fromOffset(
					screenPosition.X,
					screenPosition.Y
				)

			data.label.Visible=true

		else
			data.label.Visible=false
		end

		--================================================
		-- PLAYER TEXT
		--================================================

		if data.type=="Player" then

			local targetPlayer=
				Players:GetPlayerFromCharacter(object)

			local humanoid=
				targetPlayer
				and targetPlayer.Character
				and targetPlayer.Character:FindFirstChildOfClass("Humanoid")

			local healthText="N/A / N/A"

			if humanoid then
				healthText=string.format(
					"%d / %d",
					math.max(
						0,
						math.floor(humanoid.Health+.5)
					),
					math.floor(humanoid.MaxHealth+.5)
				)
			end

			data.label.Text=string.format(
				"%s [%dm]\n%s",
				data.name,
				distance,
				healthText
			)

		else

			data.label.Text=string.format(
				"%s [%dm]",
				data.name,
				distance
			)

		end
	end

	-- Xóa ESP object lỗi
	for _,object in ipairs(toRemove) do
		removeESP(object)
	end

	--====================================================
	-- BERRY TEXT
	--====================================================

	if ESP.Berry then

		for id,data in pairs(BerryESPObjects) do

			if not data
				or not data.label
				or not data.label.Parent
				or not data.position then

				if data and data.label then
					data.label:Destroy()
				end

				BerryESPObjects[id]=nil
				continue
			end

			local position=data.position

			local screenPosition,onScreen=
				camera:WorldToViewportPoint(
					position+Vector3.new(0,3,0)
				)

			if onScreen and screenPosition.Z>0 then

				data.label.Position=
					UDim2.fromOffset(
						screenPosition.X,
						screenPosition.Y
					)

				data.label.Visible=true

				local distance=math.floor(
					(root.Position-position).Magnitude+.5
				)

				data.label.Text=string.format(
					"%s [%dm]",
					data.name,
					distance
				)

			else
				data.label.Visible=false
			end
		end

	else

		for _,data in pairs(BerryESPObjects) do
			if data.label then
				data.label.Visible=false
			end
		end

	end
end)

--========================================================
-- PLAYER AUTO UPDATE
--========================================================

local function watchESPPlayer(target)
	if target==player then
		return
	end

	target.CharacterAdded:Connect(function()
		if ESP.Player then
			task.spawn(function()
				addPlayerESP(target)
			end)
		end
	end)

	target.CharacterRemoving:Connect(function(character)
		removeESP(character)
	end)
end

for _,target in ipairs(Players:GetPlayers()) do
	watchESPPlayer(target)
end

Players.PlayerAdded:Connect(function(target)
	watchESPPlayer(target)

	if ESP.Player then
		task.spawn(function()
			addPlayerESP(target)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(target)
	if target.Character then
		removeESP(target.Character)
	end
end)

--========================================================
-- ESP INITIAL SCAN
--========================================================

refreshESP()

createCheckbox(
	espPage,
	"ESP Berry",
	60,
	false,
	function(enabled)
		setESP("Berry",enabled)
	end
)

createCheckbox(
	espPage,
	"ESP Island",
	126,
	false,
	function(enabled)
		setESP("Island",enabled)
	end
)

createCheckbox(
	espPage,
	"ESP Fruit",
	192,
	false,
	function(enabled)
		setESP("Fruit",enabled)
	end
)

createCheckbox(
	espPage,
	"ESP Player",
	258,
	false,
	function(enabled)
		setESP("Player",enabled)
	end
)

espPage.CanvasSize=UDim2.fromOffset(0,325)

--========================================================
-- SIDEBAR
--========================================================

local menuItems={
	{"Shop","Shop"},
	{"Status And Server","StatusAndServer"},
	{"LocalPlayer","LocalPlayer"},
	{"Setting Farm","SettingFarm"},
	{"Hold and Select Skill","HoldAndSelectSkill"},
	{"Farming","Farming"},
	{"ESP","ESP"}
}

local sidebarButtons={}
local currentPage=nil
local indicator=nil

local function selectPage(name)
	if not pages[name] then return end
	if currentPage==name then return end

	for pageName,page in pairs(pages) do
		page.Visible=pageName==name
	end

	for pageName,data in pairs(sidebarButtons) do
		local active=pageName==name

		tween(data.button,{
			BackgroundTransparency=active and .12 or 1
		},.16)

		tween(data.label,{
			TextColor3=active and COLORS.Text or COLORS.TextDim
		},.16)
	end

	local data=sidebarButtons[name]

	if data then
		local targetY=data.button.Position.Y.Offset+7

		if not indicator then
			indicator=Instance.new("Frame")
			indicator.Name="ActiveIndicator"
			indicator.Size=UDim2.fromOffset(4,28)
			indicator.Position=UDim2.fromOffset(12,targetY)
			indicator.BackgroundColor3=SIDEBAR_ACCENT
			indicator.BorderSizePixel=0
			indicator.ZIndex=20
			indicator.Parent=sidebarContainer

			createCorner(indicator,50)
		else
			tween(indicator,{Position=UDim2.fromOffset(12,targetY)},.28,Enum.EasingStyle.Quint)
		end
	end

	currentPage=name
end

local function createSidebarButton(text,order,pageName)
	local button=Instance.new("TextButton")
	button.Name=pageName.."Button"
	button.Size=UDim2.new(1,-24,0,42)
	button.Position=UDim2.fromOffset(12,12+(order-1)*49)
	button.BackgroundColor3=COLORS.SurfaceLight
	button.BackgroundTransparency=1
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.ZIndex=5
	button.Parent=sidebarContainer

	createCorner(button,7)

	local label=createLabel(button,text,UDim2.new(1,-32,1,0),UDim2.fromOffset(18,0),Enum.Font.GothamBold,14,COLORS.TextDim)

	label.ZIndex=6

	sidebarButtons[pageName]={button=button,label=label}

	button.MouseEnter:Connect(function()
		if currentPage~=pageName then
			tween(button,{BackgroundTransparency=.72},.15)
			tween(label,{TextColor3=COLORS.Text},.15)
		end
	end)

	button.MouseLeave:Connect(function()
		if currentPage~=pageName then
			tween(button,{BackgroundTransparency=1},.15)
			tween(label,{TextColor3=COLORS.TextDim},.15)
		end
	end)

	button.MouseButton1Click:Connect(function()
		selectPage(pageName)
	end)
end

for order,item in ipairs(menuItems) do
	createSidebarButton(item[1],order,item[2])
end

--========================================================
-- WINDOW STATE
--========================================================

local maximized=false
local minimized=false
local minimizedHover=false

local normalSize=UDim2.fromOffset(780,500)
local normalPosition=UDim2.new(.5,-390,.5,-250)

local maximizedSize=UDim2.new(1,-40,1,-40)
local maximizedPosition=UDim2.fromOffset(20,20)

local minimizedSize=UDim2.fromOffset(300,38)
local minimizedPosition=UDim2.new(.5,-150,0,15)

local savedSize=nil
local savedPosition=nil

local function updateButtons()
	if not minimized then
		minimize.Visible=true
		maximize.Visible=true
		close.Visible=true

		minimize.Active=true
		maximize.Active=true
		close.Active=true

		close.BackgroundTransparency=1
		close.TextTransparency=0

		normalIcon.Visible=not maximized
		restoreBack.Visible=maximized
		restoreFront.Visible=maximized
		return
	end

	minimize.Visible=false
	maximize.Visible=false
	close.Visible=true

	minimize.Active=false
	maximize.Active=false

	normalIcon.Visible=false
	restoreBack.Visible=false
	restoreFront.Visible=false

	close.Active=minimizedHover
	close.BackgroundTransparency=minimizedHover and 0 or 1
	close.TextTransparency=minimizedHover and 0 or 1
end

local function restoreMinimized()
	if not minimized then return end

	minimized=false
	minimizedHover=false

	sidebar.Visible=true
	content.Visible=true
	author.Visible=true

	local size=savedSize or (maximized and maximizedSize or normalSize)
	local position=savedPosition or (maximized and maximizedPosition or normalPosition)

	updateButtons()

	tween(main,{
		Size=size,
		Position=position
	},.28,Enum.EasingStyle.Quint)
end

maximize.MouseButton1Click:Connect(function()
	if minimized then
		restoreMinimized()
		task.wait(.28)
	end

	maximized=not maximized

	if maximized then
		tween(main,{
			Size=maximizedSize,
			Position=maximizedPosition
		},.25,Enum.EasingStyle.Quint)
	else
		tween(main,{
			Size=normalSize,
			Position=normalPosition
		},.25,Enum.EasingStyle.Quint)
	end

	updateButtons()
end)

minimize.MouseButton1Click:Connect(function()
	if minimized then
		restoreMinimized()
		return
	end

	savedSize=main.Size
	savedPosition=main.Position

	minimized=true
	minimizedHover=false

	sidebar.Visible=false
	content.Visible=false
	author.Visible=false

	updateButtons()

	tween(main,{
		Size=minimizedSize,
		Position=minimizedPosition
	},.28,Enum.EasingStyle.Quint)
end)

topBar.MouseEnter:Connect(function()
	if not minimized then return end

	minimizedHover=true
	updateButtons()
end)

topBar.MouseLeave:Connect(function()
	if not minimized then return end

	minimizedHover=false
	updateButtons()
end)

topBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 and minimized then
		restoreMinimized()
	end
end)

--========================================================
-- DRAG
--========================================================

local dragging=false
local dragStart=nil
local startPosition=nil

topBar.InputBegan:Connect(function(input)
	if minimized then return end

	if input.UserInputType==Enum.UserInputType.MouseButton1
		or input.UserInputType==Enum.UserInputType.Touch then

		dragging=true
		dragStart=input.Position
		startPosition=main.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1
		or input.UserInputType==Enum.UserInputType.Touch then

		dragging=false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging or minimized then return end

	if input.UserInputType~=Enum.UserInputType.MouseMovement
		and input.UserInputType~=Enum.UserInputType.Touch then
		return
	end

	if not dragStart or not startPosition then return end

	local delta=input.Position-dragStart

	main.Position=UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset+delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset+delta.Y
	)
end)

--========================================================
-- CLOSE
--========================================================

local function clearAllESP()
	local objects={}

	for object in pairs(ESPObjects) do
		table.insert(objects,object)
	end

	for _,object in ipairs(objects) do
		removeESP(object)
	end
end

close.MouseButton1Click:Connect(function()
	stopFarm()
	clearAllESP()
	gui:Destroy()
end)

selectPage("Shop")
updateButtons()
