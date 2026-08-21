local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local MarketplaceService=game:GetService("MarketplaceService")
local HttpService=game:GetService("HttpService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

--========================================================
-- STATE
--========================================================

local State={
	WalkSpeed=16,
	JumpPower=50,
	FlySpeed=90,
	WalkSpeedEnabled=false,
	JumpPowerEnabled=false,
	NoClip=false,
	Fly=false,
}

local Connections={}
local OriginalCollision={}
local FlyConnection=nil

--========================================================
-- SETTINGS STORAGE
--========================================================

local SETTINGS_FILE="LPT_Hub_Settings.json"

local function loadSettings()
	if type(isfile)~="function" or type(readfile)~="function" then return end

	local ok,exists=pcall(function()
		return isfile(SETTINGS_FILE)
	end)

	if not ok or not exists then return end

	local success,data=pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_FILE))
	end)

	if not success or type(data)~="table" then return end

	State.WalkSpeed=tonumber(data.WalkSpeed) or State.WalkSpeed
	State.JumpPower=tonumber(data.JumpPower) or State.JumpPower
	State.FlySpeed=tonumber(data.FlySpeed) or State.FlySpeed
	State.WalkSpeedEnabled=data.WalkSpeedEnabled==true
	State.JumpPowerEnabled=data.JumpPowerEnabled==true
	State.NoClip=data.NoClip==true
	State.Fly=false
end

local function saveSettings()
	if type(writefile)~="function" then return end

	local data={
		WalkSpeed=State.WalkSpeed,
		JumpPower=State.JumpPower,
		FlySpeed=State.FlySpeed,
		WalkSpeedEnabled=State.WalkSpeedEnabled,
		JumpPowerEnabled=State.JumpPowerEnabled,
		NoClip=State.NoClip,
		Fly=false,
	}

	pcall(function()
		writefile(SETTINGS_FILE,HttpService:JSONEncode(data))
	end)
end

loadSettings()

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
	Info=Color3.fromRGB(96,165,250),
}

local SIDEBAR_ACCENT=Color3.fromRGB(96,165,250)

--========================================================
-- HELPERS
--========================================================

local function tween(obj,props,time,style)
	if not obj or not obj.Parent then return end

	local t=TweenService:Create(
		obj,
		TweenInfo.new(
			time or .18,
			style or Enum.EasingStyle.Quad
		),
		props
	)

	t:Play()
	return t
end

local function applyGradient(obj,a,b,rotation)
	local gradient=Instance.new("UIGradient")
	gradient.Color=ColorSequence.new(a,b)
	gradient.Rotation=rotation or 45
	gradient.Parent=obj
	return gradient
end

local function getCharacter()
	return player.Character
end

local function getHumanoid()
	local character=getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character=getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

--========================================================
-- MOVEMENT
--========================================================

local function applyMovement()
	local humanoid=getHumanoid()
	if not humanoid then return end

	pcall(function()
		humanoid.UseJumpPower=true
		humanoid.WalkSpeed=State.WalkSpeedEnabled and State.WalkSpeed or 16
		humanoid.JumpPower=State.JumpPowerEnabled and State.JumpPower or 50
	end)
end

--========================================================
-- FORCE WALK SPEED / JUMP POWER
--========================================================

Connections.MovementEnforce=RunService.Heartbeat:Connect(function()
	local humanoid=getHumanoid()
	if not humanoid then return end

	if State.WalkSpeedEnabled and humanoid.WalkSpeed~=State.WalkSpeed then
		pcall(function()
			humanoid.WalkSpeed=State.WalkSpeed
		end)
	end

	if State.JumpPowerEnabled and humanoid.JumpPower~=State.JumpPower then
		pcall(function()
			humanoid.JumpPower=State.JumpPower
		end)
	end
end)

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

local function restoreCollision()
	for object,original in pairs(OriginalCollision) do
		if object and object.Parent then
			pcall(function()
				object.CanCollide=original
			end)
		end
	end

	table.clear(OriginalCollision)
end

Connections.NoClip=RunService.Stepped:Connect(function()
	if not State.NoClip then return end

	local character=getCharacter()
	if not character then return end

	rememberCollision(character)

	for _,object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			pcall(function()
				object.CanCollide=false
			end)
		end
	end
end)

--========================================================
-- FLY
--========================================================

local function stopFly()
	State.Fly=false

	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection=nil
	end

	local humanoid=getHumanoid()
	local root=getRoot()

	if humanoid then
		humanoid.PlatformStand=false
		humanoid.AutoRotate=true
	end

	if root then
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
	end
end

local function startFly()
	stopFly()
	State.Fly=true

	local lockedPosition=nil

	FlyConnection=RunService.Heartbeat:Connect(function()
		if not State.Fly then return end

		local root=getRoot()
		local humanoid=getHumanoid()
		local camera=workspace.CurrentCamera

		if not root or not humanoid or not camera then return end

		humanoid.PlatformStand=true
		humanoid.AutoRotate=false

		if not lockedPosition then
			lockedPosition=root.Position
		end

		local lookVector=camera.CFrame.LookVector
		local rightVector=camera.CFrame.RightVector
		local direction=Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction+=lookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction-=lookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction+=rightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction-=rightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction+=Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction-=Vector3.yAxis
		end

		if direction.Magnitude>0 then
			direction=direction.Unit
			root.AssemblyLinearVelocity=direction*State.FlySpeed
			root.AssemblyAngularVelocity=Vector3.zero
			lockedPosition=root.Position

			local flatLook=Vector3.new(lookVector.X,0,lookVector.Z)

			if flatLook.Magnitude>0.001 then
				root.CFrame=CFrame.lookAt(
					root.Position,
					root.Position+flatLook.Unit
				)
			end
		else
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero

			local flatLook=Vector3.new(lookVector.X,0,lookVector.Z)

			if flatLook.Magnitude>0.001 then
				root.CFrame=CFrame.lookAt(
					lockedPosition,
					lockedPosition+flatLook.Unit
				)
			else
				root.CFrame=CFrame.new(lockedPosition)*root.CFrame.Rotation
			end
		end
	end)
end

--========================================================
-- CHARACTER
--========================================================

Connections.CharacterAdded=player.CharacterAdded:Connect(function(character)
	table.clear(OriginalCollision)

	local humanoid=character:WaitForChild("Humanoid",10)

	if humanoid then
		task.wait(.15)
		applyMovement()

		if State.NoClip then
			rememberCollision(character)
		end
	end

	if State.Fly then
		stopFly()
	end
end)

--========================================================
-- SCREEN GUI
--========================================================

local oldGui=playerGui:FindFirstChild("LPTHub")
if oldGui then oldGui:Destroy() end

local screenGui=Instance.new("ScreenGui")
screenGui.Name="LPTHub"
screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder=2147483647

local hiddenLayer=(gethui and gethui()) or (get_hidden_gui and get_hidden_gui())

if hiddenLayer then
	screenGui.Parent=hiddenLayer
else
	local ok=pcall(function()
		screenGui.Parent=game:GetService("CoreGui")
	end)

	if not ok then
		screenGui.Parent=playerGui
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

local main=Instance.new("Frame")
main.Name="MainWindow"
main.Size=UDim2.new(0,780,0,500)
main.Position=UDim2.new(.5,-390,.5,-250)
main.BackgroundColor3=COLORS.Background
main.BorderSizePixel=0
main.ClipsDescendants=true
main.Parent=screenGui

local mainCorner=Instance.new("UICorner")
mainCorner.CornerRadius=UDim.new(0,8)
mainCorner.Parent=main

local mainStroke=Instance.new("UIStroke")
mainStroke.Color=COLORS.Border
mainStroke.Thickness=2
mainStroke.Transparency=.1
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

local titleDot=Instance.new("Frame")
titleDot.Size=UDim2.fromOffset(8,8)
titleDot.Position=UDim2.new(0,20,.5,-4)
titleDot.BackgroundColor3=COLORS.Success
titleDot.BorderSizePixel=0
titleDot.ZIndex=2
titleDot.Parent=topBar

local titleDotCorner=Instance.new("UICorner")
titleDotCorner.CornerRadius=UDim.new(1,0)
titleDotCorner.Parent=titleDot

local titleDotPulse=Instance.new("Frame")
titleDotPulse.Size=UDim2.fromOffset(8,8)
titleDotPulse.Position=UDim2.new(.5,-4,.5,-4)
titleDotPulse.BackgroundColor3=COLORS.Success
titleDotPulse.BackgroundTransparency=.3
titleDotPulse.BorderSizePixel=0
titleDotPulse.Parent=titleDot

local titleDotPulseCorner=Instance.new("UICorner")
titleDotPulseCorner.CornerRadius=UDim.new(1,0)
titleDotPulseCorner.Parent=titleDotPulse

task.spawn(function()
	while titleDotPulse.Parent do
		titleDotPulse.Size=UDim2.fromOffset(8,8)
		titleDotPulse.Position=UDim2.new(.5,-4,.5,-4)
		titleDotPulse.BackgroundTransparency=.3

		tween(titleDotPulse,{
			Size=UDim2.fromOffset(22,22),
			Position=UDim2.new(.5,-11,.5,-11),
			BackgroundTransparency=1
		},1.1)

		task.wait(1.1)
	end
end)

local title=Instance.new("TextLabel")
title.Size=UDim2.fromOffset(105,38)
title.Position=UDim2.fromOffset(36,0)
title.BackgroundTransparency=1
title.Text="LPT Hub"
title.TextColor3=COLORS.Text
title.TextSize=18.5
title.Font=Enum.Font.GothamBold
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=topBar

applyGradient(title,COLORS.Accent,COLORS.AccentB,0)

local author=Instance.new("TextLabel")
author.Size=UDim2.fromOffset(170,38)
author.Position=UDim2.fromOffset(113,0)
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
	button.Size=UDim2.fromOffset(30,26)
	button.Position=UDim2.new(1,xOffset,.5,-13)
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
maxIcon.Size=UDim2.fromOffset(20,20)
maxIcon.Position=UDim2.new(.5,-10,.5,-10)
maxIcon.BackgroundTransparency=1
maxIcon.Parent=maximize

local normalIcon=Instance.new("Frame")
normalIcon.Size=UDim2.fromOffset(13,13)
normalIcon.Position=UDim2.new(.5,-6,.5,-6)
normalIcon.BackgroundTransparency=1
normalIcon.Parent=maxIcon

local normalCorner=Instance.new("UICorner")
normalCorner.CornerRadius=UDim.new(0,3)
normalCorner.Parent=normalIcon

local normalStroke=Instance.new("UIStroke")
normalStroke.Thickness=1.5
normalStroke.Color=COLORS.TextDim
normalStroke.Parent=normalIcon

local restoreBack=Instance.new("Frame")
restoreBack.Size=UDim2.fromOffset(11,11)
restoreBack.Position=UDim2.fromOffset(6,2)
restoreBack.BackgroundTransparency=1
restoreBack.Visible=false
restoreBack.Parent=maxIcon

local restoreBackCorner=Instance.new("UICorner")
restoreBackCorner.CornerRadius=UDim.new(0,2)
restoreBackCorner.Parent=restoreBack

local restoreBackStroke=Instance.new("UIStroke")
restoreBackStroke.Thickness=1.5
restoreBackStroke.Color=COLORS.TextDim
restoreBackStroke.Parent=restoreBack

local restoreFront=Instance.new("Frame")
restoreFront.Size=UDim2.fromOffset(11,11)
restoreFront.Position=UDim2.fromOffset(2,6)
restoreFront.BackgroundColor3=COLORS.Surface
restoreFront.BorderSizePixel=0
restoreFront.Visible=false
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
		tween(button,{
			TextColor3=hoverColor,
			BackgroundTransparency=0,
			BackgroundColor3=hoverBg or COLORS.SurfaceLight
		})
	end)

	button.MouseLeave:Connect(function()
		tween(button,{
			TextColor3=COLORS.TextDim,
			BackgroundTransparency=1
		})
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
-- SIDEBAR / CONTENT
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

local sideLine=Instance.new("Frame")
sideLine.Size=UDim2.new(0,1,1,0)
sideLine.Position=UDim2.new(1,-1,0,0)
sideLine.BackgroundColor3=COLORS.Border
sideLine.BorderSizePixel=0
sideLine.Parent=sidebar

local content=Instance.new("Frame")
content.Name="Content"
content.Size=UDim2.new(1,-220,1,-38)
content.Position=UDim2.fromOffset(220,38)
content.BackgroundTransparency=1
content.Parent=main

local pages={}

local function createPage(name)
	local page=Instance.new("ScrollingFrame")
	page.Name=name
	page.Size=UDim2.fromScale(1,1)
	page.BackgroundTransparency=1
	page.BorderSizePixel=0
	page.ScrollBarThickness=3
	page.ScrollBarImageColor3=COLORS.Accent
	page.CanvasSize=UDim2.new()
	page.Visible=false
	page.Parent=content
	pages[name]=page
	return page
end

local informationPage=createPage("Information")
local mainPage=createPage("Main")
local settingsPage=createPage("Settings")

--========================================================
-- PAGE TITLE
--========================================================

local function createPageTitle(parent,text,description)
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-50,0,38)
	label.Position=UDim2.fromOffset(28,20)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=28
	label.Font=Enum.Font.GothamBold
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=parent

	if description then
		local sub=Instance.new("TextLabel")
		sub.Size=UDim2.new(1,-50,0,20)
		sub.Position=UDim2.fromOffset(28,54)
		sub.BackgroundTransparency=1
		sub.Text=description
		sub.TextColor3=COLORS.TextDim
		sub.TextSize=14
		sub.Font=Enum.Font.Gotham
		sub.TextXAlignment=Enum.TextXAlignment.Left
		sub.Parent=parent
	end
end

createPageTitle(informationPage,"Thông Tin","Thông tin Owner, Tên Game, Chức năng và trạng thái.")
createPageTitle(mainPage,"Main")
createPageTitle(settingsPage,"Settings")

--========================================================
-- TOGGLE
--========================================================

local function createToggle(parent,text,y,callback)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-56,0,56)
	row.Position=UDim2.fromOffset(28,y)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=.15
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-90,1,0)
	label.Position=UDim2.fromOffset(18,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local button=Instance.new("TextButton")
	button.Name="Toggle"
	button.Size=UDim2.fromOffset(50,26)
	button.Position=UDim2.new(1,-68,.5,-13)
	button.BackgroundColor3=Color3.fromRGB(120,120,125)
	button.BackgroundTransparency=.35
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=row

	local buttonCorner=Instance.new("UICorner")
	buttonCorner.CornerRadius=UDim.new(1,0)
	buttonCorner.Parent=button

	local knob=Instance.new("Frame")
	knob.Size=UDim2.fromOffset(22,22)
	knob.Position=UDim2.fromOffset(3,2)
	knob.BackgroundColor3=Color3.fromRGB(230,230,235)
	knob.BorderSizePixel=0
	knob.Parent=button

	local knobCorner=Instance.new("UICorner")
	knobCorner.CornerRadius=UDim.new(1,0)
	knobCorner.Parent=knob

	local enabled=false

	local function setEnabled(value,fire)
		enabled=value==true

		tween(button,{
			BackgroundColor3=enabled and COLORS.Success or Color3.fromRGB(120,120,125),
			BackgroundTransparency=enabled and 0 or .35
		},.2)

		tween(knob,{
			Position=enabled and UDim2.new(1,-25,0,2) or UDim2.fromOffset(3,2),
			BackgroundColor3=enabled and Color3.fromRGB(15,20,18) or Color3.fromRGB(230,230,235)
		},.2)

		if fire~=false and callback then
			callback(enabled)
		end
	end

	button.MouseButton1Click:Connect(function()
		setEnabled(not enabled,true)
	end)

	row.MouseEnter:Connect(function()
		if not enabled then
			tween(row,{BackgroundColor3=COLORS.CardHover},.15)
		end
	end)

	row.MouseLeave:Connect(function()
		if not enabled then
			tween(row,{BackgroundColor3=COLORS.Card},.15)
		end
	end)

	return setEnabled,function()
		return enabled
	end
end

--========================================================
-- SLIDER
--========================================================

local function createSlider(parent,text,y,defaultValue,minValue,maxValue,callback)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-56,0,78)
	row.Position=UDim2.fromOffset(28,y)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,14)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Thickness=1
	stroke.Transparency=.15
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-36,0,20)
	label.Position=UDim2.fromOffset(18,10)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local valueLabel=Instance.new("TextLabel")
	valueLabel.Size=UDim2.fromOffset(50,20)
	valueLabel.Position=UDim2.new(1,-68,0,10)
	valueLabel.BackgroundTransparency=1
	valueLabel.Text=tostring(defaultValue)
	valueLabel.TextColor3=COLORS.Accent
	valueLabel.TextSize=14
	valueLabel.Font=Enum.Font.GothamBold
	valueLabel.TextXAlignment=Enum.TextXAlignment.Right
	valueLabel.Parent=row

	local track=Instance.new("Frame")
	track.Size=UDim2.new(1,-36,0,6)
	track.Position=UDim2.fromOffset(18,50)
	track.BackgroundColor3=COLORS.SurfaceLight
	track.BorderSizePixel=0
	track.Active=true
	track.Parent=row

	local trackCorner=Instance.new("UICorner")
	trackCorner.CornerRadius=UDim.new(1,0)
	trackCorner.Parent=track

	local fill=Instance.new("Frame")
	fill.BackgroundColor3=COLORS.Accent
	fill.BorderSizePixel=0
	fill.Parent=track

	local fillCorner=Instance.new("UICorner")
	fillCorner.CornerRadius=UDim.new(1,0)
	fillCorner.Parent=fill

	local knob=Instance.new("Frame")
	knob.Size=UDim2.fromOffset(16,16)
	knob.AnchorPoint=Vector2.new(.5,.5)
	knob.BackgroundColor3=Color3.new(1,1,1)
	knob.BorderSizePixel=0
	knob.Active=true
	knob.Parent=track

	local knobCorner=Instance.new("UICorner")
	knobCorner.CornerRadius=UDim.new(1,0)
	knobCorner.Parent=knob

	local knobStroke=Instance.new("UIStroke")
	knobStroke.Color=COLORS.Accent
	knobStroke.Thickness=2
	knobStroke.Parent=knob

	local dragging=false

	local function setValue(value,fire)
		value=math.clamp(math.floor(value+.5),minValue,maxValue)

		local fraction=(value-minValue)/(maxValue-minValue)

		fill.Size=UDim2.new(fraction,0,1,0)
		knob.Position=UDim2.new(fraction,0,.5,0)
		valueLabel.Text=tostring(value)

		if fire~=false and callback then
			callback(value)
		end

		return value
	end

	local function updateFromInput(input)
		local x=input.Position.X-track.AbsolutePosition.X
		local fraction=math.clamp(x/track.AbsoluteSize.X,0,1)
		setValue(minValue+fraction*(maxValue-minValue),true)
	end

	local function beginDrag(input)
		dragging=true
		updateFromInput(input)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging
			and (input.UserInputType==Enum.UserInputType.MouseMovement
			or input.UserInputType==Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		end
	end)

	setValue(defaultValue,false)
	return setValue
end

--========================================================
-- INFORMATION
--========================================================

local informationContainer=Instance.new("Frame")
informationContainer.Size=UDim2.new(1,-56,0,430)
informationContainer.Position=UDim2.new(0,28,0,95)
informationContainer.BackgroundTransparency=1
informationContainer.Parent=informationPage

local informationCard=Instance.new("Frame")
informationCard.Size=UDim2.new(1,0,0,350)
informationCard.BackgroundColor3=Color3.fromRGB(26,25,31)
informationCard.BorderSizePixel=0
informationCard.Parent=informationContainer

local informationCorner=Instance.new("UICorner")
informationCorner.CornerRadius=UDim.new(0,20)
informationCorner.Parent=informationCard

local informationStroke=Instance.new("UIStroke")
informationStroke.Color=Color3.fromRGB(255,255,255)
informationStroke.Transparency=.9
informationStroke.Thickness=1
informationStroke.Parent=informationCard

local ownerText=Instance.new("TextLabel")
ownerText.Size=UDim2.new(0,100,0,20)
ownerText.Position=UDim2.new(0,15,0,15)
ownerText.BackgroundTransparency=1
ownerText.Text="OWNER"
ownerText.Font=Enum.Font.GothamBold
ownerText.TextSize=25
ownerText.TextColor3=Color3.fromRGB(200,200,200)
ownerText.TextXAlignment=Enum.TextXAlignment.Left
ownerText.Parent=informationCard

local informationList=Instance.new("Frame")
informationList.Size=UDim2.new(1,-48,1,-75)
informationList.Position=UDim2.new(0,24,0,60)
informationList.BackgroundTransparency=1
informationList.Parent=informationCard

local informationLayout=Instance.new("UIListLayout")
informationLayout.FillDirection=Enum.FillDirection.Vertical
informationLayout.Padding=UDim.new(0,16)
informationLayout.SortOrder=Enum.SortOrder.LayoutOrder
informationLayout.Parent=informationList

local function createInformationRow(order,labelText,valueText,valueColor)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,0,0,44)
	row.BackgroundTransparency=1
	row.LayoutOrder=order
	row.Parent=informationList

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,0,0,16)
	label.BackgroundTransparency=1
	label.Text=labelText
	label.Font=Enum.Font.Gotham
	label.TextSize=13
	label.TextColor3=Color3.fromRGB(150,148,155)
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local value=Instance.new("TextLabel")
	value.Size=UDim2.new(1,0,0,22)
	value.Position=UDim2.new(0,0,0,20)
	value.BackgroundTransparency=1
	value.Text=valueText
	value.Font=Enum.Font.GothamMedium
	value.TextSize=17
	value.TextColor3=valueColor or Color3.fromRGB(240,240,240)
	value.TextXAlignment=Enum.TextXAlignment.Left
	value.Parent=row
end

createInformationRow(1,"Họ và Tên","Lý Phúc Thiện")
createInformationRow(2,"Ngày sinh","18/3")
createInformationRow(3,"Tuổi","15")
createInformationRow(4,"Trạng Thái","Online",Color3.fromRGB(80,220,120))

local gameCard=Instance.new("Frame")
gameCard.Size=UDim2.new(1,0,0,60)
gameCard.Position=UDim2.new(0,0,0,370)
gameCard.BackgroundColor3=Color3.fromRGB(30,28,35)
gameCard.BorderSizePixel=0
gameCard.Parent=informationContainer

local gameCorner=Instance.new("UICorner")
gameCorner.CornerRadius=UDim.new(0,20)
gameCorner.Parent=gameCard

local gameRow=Instance.new("TextLabel")
gameRow.Size=UDim2.new(1,-48,1,0)
gameRow.Position=UDim2.new(0,24,0,0)
gameRow.BackgroundTransparency=1
gameRow.Font=Enum.Font.GothamMedium
gameRow.TextSize=18
gameRow.TextXAlignment=Enum.TextXAlignment.Left
gameRow.TextYAlignment=Enum.TextYAlignment.Center
gameRow.TextColor3=Color3.fromRGB(240,240,240)
gameRow.RichText=true
gameRow.Parent=gameCard

local gameName="Unknown Game"

local gameInfoOK,gameInfo=pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId)
end)

if gameInfoOK and type(gameInfo)=="table" and gameInfo.Name then
	gameName=tostring(gameInfo.Name)
end

gameRow.Text=string.format(
	'<font color="rgb(160,158,165)">Tên Game: </font><font color="rgb(240,240,240)">%s</font>',
	gameName
)

informationPage.CanvasSize=UDim2.new(0,0,0,540)

--========================================================
-- MAIN PAGE
--========================================================

local setWalkSpeedUI=createToggle(mainPage,"WalkSpeed",95,function(enabled)
	State.WalkSpeedEnabled=enabled
	applyMovement()
	saveSettings()
end)

local setJumpPowerUI=createToggle(mainPage,"JumpPower",161,function(enabled)
	State.JumpPowerEnabled=enabled
	applyMovement()
	saveSettings()
end)

local setNoClipUI=createToggle(mainPage,"No Clip",227,function(enabled)
	State.NoClip=enabled

	if enabled then
		rememberCollision(getCharacter())
	else
		restoreCollision()
	end

	saveSettings()
end)

local setFlyUI=createToggle(mainPage,"Fly",293,function(enabled)
	if enabled then
		startFly()
	else
		stopFly()
	end
end)

mainPage.CanvasSize=UDim2.new(0,0,0,420)

--========================================================
-- SETTINGS
--========================================================

createSlider(settingsPage,"Walk Speed",95,State.WalkSpeed,1,500,function(value)
	State.WalkSpeed=value

	if State.WalkSpeedEnabled then
		applyMovement()
	end

	saveSettings()
end)

createSlider(settingsPage,"Jump Power",183,State.JumpPower,1,500,function(value)
	State.JumpPower=value

	if State.JumpPowerEnabled then
		applyMovement()
	end

	saveSettings()
end)

createSlider(settingsPage,"Fly Speed",271,State.FlySpeed,1,500,function(value)
	State.FlySpeed=value
	saveSettings()
end)

--========================================================
-- FIX LAG
--========================================================

local fixLag=Instance.new("TextButton")
fixLag.Name="FixLag"
fixLag.Size=UDim2.new(1,-56,0,52)
fixLag.Position=UDim2.fromOffset(28,363)
fixLag.BackgroundColor3=COLORS.Info
fixLag.BorderSizePixel=0
fixLag.Text="FIX LAG"
fixLag.TextColor3=Color3.new(1,1,1)
fixLag.TextSize=14
fixLag.Font=Enum.Font.GothamBold
fixLag.AutoButtonColor=false
fixLag.Parent=settingsPage

local fixCorner=Instance.new("UICorner")
fixCorner.CornerRadius=UDim.new(0,14)
fixCorner.Parent=fixLag

fixLag.MouseEnter:Connect(function()
	tween(fixLag,{BackgroundColor3=Color3.fromRGB(120,185,255)},.15)
end)

fixLag.MouseLeave:Connect(function()
	tween(fixLag,{BackgroundColor3=COLORS.Info},.15)
end)

fixLag.MouseButton1Click:Connect(function()
	fixLag.Text="FIXING..."

	local changedParts=0

	--====================================================
	-- TERRAIN
	--====================================================

	pcall(function()
		local terrain=workspace:FindFirstChildOfClass("Terrain")

		if terrain then
			terrain.WaterWaveSize=0
			terrain.WaterWaveSpeed=0
			terrain.WaterReflectance=0
			terrain.WaterTransparency=1
		end
	end)

	--====================================================
	-- LIGHTING
	--====================================================

	pcall(function()
		local lighting=game:GetService("Lighting")

		for _,object in ipairs(lighting:GetChildren()) do
			if object:IsA("PostEffect")
				or object:IsA("Atmosphere")
				or object:IsA("Sky") then

				if object:IsA("PostEffect") then
					object.Enabled=false
				end
			end
		end

		lighting.GlobalShadows=false
		lighting.EnvironmentDiffuseScale=0
		lighting.EnvironmentSpecularScale=0
	end)

	--====================================================
	-- WORKSPACE OBJECTS
	--====================================================

	pcall(function()
		for _,object in ipairs(workspace:GetDescendants()) do

			-- PART
			if object:IsA("BasePart") then
				changedParts+=1

				pcall(function()
					object.Material=Enum.Material.SmoothPlastic
					object.Reflectance=0
				end)
			end

			-- TEXTURE / DECAL
			if object:IsA("Decal") or object:IsA("Texture") then
				pcall(function()
					object.Transparency=1
				end)
			end

			-- SPECIAL MESH
			if object:IsA("SpecialMesh") then
				pcall(function()
					object.TextureId=""
				end)
			end

			-- PARTICLE
			if object:IsA("ParticleEmitter") then
				pcall(function()
					object.Enabled=false
				end)
			end

			-- TRAIL
			if object:IsA("Trail") then
				pcall(function()
					object.Enabled=false
				end)
			end

			-- BEAM
			if object:IsA("Beam") then
				pcall(function()
					object.Enabled=false
				end)
			end

			-- SMOKE / FIRE / SPARKLES
			if object:IsA("Smoke")
				or object:IsA("Fire")
				or object:IsA("Sparkles") then
				pcall(function()
					object.Enabled=false
				end)
			end

			-- SURFACE APPEARANCE
			if object:IsA("SurfaceAppearance") then
				pcall(function()
					object:Destroy()
				end)
			end
		end
	end)

	--====================================================
	-- CHARACTER APPEARANCE
	--====================================================

	pcall(function()
		local character=player.Character

		if character then
			for _,object in ipairs(character:GetDescendants()) do
				if object:IsA("Decal")
					or object:IsA("Texture")
					or object:IsA("SurfaceAppearance") then

					pcall(function()
						object.Transparency=1
					end)
				end
			end
		end
	end)

	task.wait(.35)

	fixLag.Text="FIXED ✓"

	task.wait(1)

	if fixLag.Parent then
		fixLag.Text="FIX LAG"
	end
end)

settingsPage.CanvasSize=UDim2.new(0,0,0,445)

--========================================================
-- SIDEBAR
--========================================================

local currentPage=nil
local sidebarButtons={}
local sidebarIndicator=nil

local function selectPage(name)
	if not pages[name] then return end
	if currentPage==name then return end

	local newData=sidebarButtons[name]

	for pageName,page in pairs(pages) do
		page.Visible=pageName==name
	end

	for pageName,data in pairs(sidebarButtons) do
		local active=pageName==name

		tween(
			data.button,
			{BackgroundTransparency=active and .12 or 1},
			.16,
			Enum.EasingStyle.Quad
		)

		tween(
			data.label,
			{TextColor3=active and COLORS.Text or COLORS.TextDim},
			.16,
			Enum.EasingStyle.Quad
		)
	end

	if newData then
		local targetY=newData.button.Position.Y.Offset+(newData.button.Size.Y.Offset/2)-14

		if sidebarIndicator then
			sidebarIndicator.Visible=true

			tween(
				sidebarIndicator,
				{Position=UDim2.new(0,12,0,targetY)},
				.28,
				Enum.EasingStyle.Quint
			)
		else
			sidebarIndicator=Instance.new("Frame")
			sidebarIndicator.Name="ActiveIndicator"
			sidebarIndicator.Size=UDim2.fromOffset(4,28)
			sidebarIndicator.Position=UDim2.new(0,12,0,targetY)
			sidebarIndicator.BackgroundColor3=SIDEBAR_ACCENT
			sidebarIndicator.BorderSizePixel=0
			sidebarIndicator.ZIndex=10
			sidebarIndicator.Parent=sidebar

			local indicatorCorner=Instance.new("UICorner")
			indicatorCorner.CornerRadius=UDim.new(1,0)
			indicatorCorner.Parent=sidebarIndicator
		end

		sidebarIndicator.BackgroundColor3=SIDEBAR_ACCENT
	end

	currentPage=name
end

local function createSidebarButton(text,order,pageName)
	local button=Instance.new("TextButton")
	button.Name=pageName.."Button"
	button.Size=UDim2.new(1,-24,0,48)
	button.Position=UDim2.fromOffset(12,16+(order-1)*54)
	button.BackgroundColor3=COLORS.SurfaceLight
	button.BackgroundTransparency=1
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=sidebar

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,7)
	corner.Parent=button

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-32,1,0)
	label.Position=UDim2.fromOffset(18,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.TextDim
	label.TextSize=16
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=button

	sidebarButtons[pageName]={
		button=button,
		label=label,
	}

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

createSidebarButton("Information",1,"Information")
createSidebarButton("Main",2,"Main")
createSidebarButton("Settings",3,"Settings")

selectPage("Information")

--========================================================
-- RESTORE SAVED STATE
--========================================================

task.defer(function()
	applyMovement()
	setWalkSpeedUI(State.WalkSpeedEnabled,false)
	setJumpPowerUI(State.JumpPowerEnabled,false)
	setNoClipUI(State.NoClip,false)

	if State.NoClip then
		rememberCollision(getCharacter())
	end

	applyMovement()
end)

--========================================================
-- MAXIMIZE / MINIMIZE
--========================================================

local maximized=false
local minimized=false
local savedBeforeMinimizeSize=nil
local savedBeforeMinimizePosition=nil

local normalSize=UDim2.new(0,780,0,500)
local normalPosition=UDim2.new(.5,-390,.5,-250)
local maximizedSize=UDim2.new(1,-40,1,-40)
local maximizedPosition=UDim2.new(0,20,0,20)
local minimizedSize=UDim2.new(0,300,0,38)
local minimizedPosition=UDim2.new(.5,-150,-.060,15)
local minimizedHover=false

local function updateMinimizedButtons()
	if not minimized then
		minimize.Visible=true
		maximize.Visible=true
		close.Visible=true

		minimize.Active=true
		maximize.Active=true
		close.Active=true

		minimize.BackgroundTransparency=1
		maximize.BackgroundTransparency=1
		close.BackgroundTransparency=1

		normalStroke.Transparency=0
		restoreBackStroke.Transparency=0
		restoreFrontStroke.Transparency=0

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
	close.Active=minimizedHover

	local transparency=minimizedHover and 0 or 1

	close.BackgroundTransparency=transparency
	close.TextTransparency=transparency
	normalStroke.Transparency=minimizedHover and .1 or 1

	normalIcon.Visible=false
	restoreBack.Visible=false
	restoreFront.Visible=false
end

local function restoreFromMinimized()
	if not minimized then return end

	minimized=false
	minimizedHover=false

	sidebar.Visible=true
	content.Visible=true
	author.Visible=true

	local restoreSize=savedBeforeMinimizeSize or (maximized and maximizedSize or normalSize)
	local restorePosition=savedBeforeMinimizePosition or (maximized and maximizedPosition or normalPosition)

	updateMinimizedButtons()

	normalIcon.Visible=not maximized
	restoreBack.Visible=maximized
	restoreFront.Visible=maximized

	tween(
		main,
		{Size=restoreSize,Position=restorePosition},
		.28,
		Enum.EasingStyle.Quint
	)
end

maximize.MouseButton1Click:Connect(function()
	if minimized then
		restoreFromMinimized()
		task.wait(.28)
	end

	maximized=not maximized

	if maximized then
		tween(
			main,
			{Size=maximizedSize,Position=maximizedPosition},
			.25,
			Enum.EasingStyle.Quint
		)

		normalIcon.Visible=false
		restoreBack.Visible=true
		restoreFront.Visible=true
	else
		tween(
			main,
			{Size=normalSize,Position=normalPosition},
			.25,
			Enum.EasingStyle.Quint
		)

		normalIcon.Visible=true
		restoreBack.Visible=false
		restoreFront.Visible=false
	end

	updateMinimizedButtons()
end)

minimize.MouseButton1Click:Connect(function()
	if minimized then
		restoreFromMinimized()
		return
	end

	savedBeforeMinimizeSize=main.Size
	savedBeforeMinimizePosition=main.Position

	minimized=true
	minimizedHover=false

	sidebar.Visible=false
	content.Visible=false
	author.Visible=false

	updateMinimizedButtons()

	tween(
		main,
		{Size=minimizedSize,Position=minimizedPosition},
		.28,
		Enum.EasingStyle.Quint
	)
end)

topBar.MouseEnter:Connect(function()
	if not minimized then return end
	minimizedHover=true
	updateMinimizedButtons()
end)

topBar.MouseLeave:Connect(function()
	if not minimized then return end
	minimizedHover=false
	updateMinimizedButtons()
end)

topBar.InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
	if minimized then restoreFromMinimized() end
end)

--========================================================
-- DRAG
--========================================================

local dragging=false
local dragStart=nil
local startPosition=nil

topBar.InputBegan:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.MouseButton1
		and input.UserInputType~=Enum.UserInputType.Touch then
		return
	end

	if minimized then return end

	dragging=true
	dragStart=input.Position
	startPosition=main.Position
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

close.MouseButton1Click:Connect(function()
	saveSettings()
	stopFly()

	State.NoClip=false
	restoreCollision()

	for name,connection in pairs(Connections) do
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end

		Connections[name]=nil
	end

	if screenGui.Parent then
		screenGui:Destroy()
	end
end)

applyMovement()