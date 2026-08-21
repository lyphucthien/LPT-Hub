local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local State={
	WalkSpeed=16,
	JumpPower=50,
	WalkSpeedEnabled=false,
	JumpPowerEnabled=false,
	NoClip=false,
	Fly=false,
}

local Connections={}
local OriginalCollision={}

local COLORS={
	Background=Color3.fromRGB(10,11,16),
	Surface=Color3.fromRGB(15,16,23),
	Card=Color3.fromRGB(31,34,45),
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

local function tween(object,properties,time,style)
	if not object or not object.Parent then return end
	local t=TweenService:Create(object,TweenInfo.new(time or .18,style or Enum.EasingStyle.Quad),properties)
	t:Play()
	return t
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

local function applyMovement()
	local humanoid=getHumanoid()
	if not humanoid then return end

	if State.WalkSpeedEnabled then
		humanoid.WalkSpeed=State.WalkSpeed
	else
		humanoid.WalkSpeed=16
	end

	if State.JumpPowerEnabled then
		humanoid.UseJumpPower=true
		humanoid.JumpPower=State.JumpPower
	else
		humanoid.UseJumpPower=true
		humanoid.JumpPower=50
	end
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

local function restoreCollision()
	for object,canCollide in pairs(OriginalCollision) do
		if object and object.Parent then
			pcall(function()
				object.CanCollide=canCollide
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
			object.CanCollide=false
		end
	end
end)

--========================================================
-- FLY
--========================================================

local FlyConnection=nil

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
	end

	if root then
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
	end
end

local function startFly()
	if FlyConnection then
		FlyConnection:Disconnect()
	end

	State.Fly=true

	FlyConnection=RunService.Heartbeat:Connect(function()
		if not State.Fly then return end

		local root=getRoot()
		local humanoid=getHumanoid()
		if not root or not humanoid then return end

		local camera=workspace.CurrentCamera
		if not camera then return end

		humanoid.PlatformStand=true

		local direction=Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction+=camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction-=camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction+=camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction-=camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction+=Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction-=Vector3.yAxis
		end

		if direction.Magnitude>0 then
			direction=direction.Unit
		end

		root.AssemblyLinearVelocity=direction*90
		root.AssemblyAngularVelocity=Vector3.zero
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
	end

	if State.Fly then
		stopFly()
	end
end)

--========================================================
-- GUI
--========================================================

local oldGui=playerGui:FindFirstChild("LPTHub")

if oldGui then
	oldGui:Destroy()
end

local screenGui=Instance.new("ScreenGui")
screenGui.Name="LPTHub"
screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder=999999
screenGui.Parent=playerGui

local main=Instance.new("Frame")
main.Name="Main"
main.Size=UDim2.fromOffset(650,420)
main.Position=UDim2.new(.5,-325,.5,-210)
main.BackgroundColor3=COLORS.Background
main.BorderSizePixel=0
main.ClipsDescendants=true
main.Parent=screenGui

local mainCorner=Instance.new("UICorner")
mainCorner.CornerRadius=UDim.new(0,14)
mainCorner.Parent=main

local mainStroke=Instance.new("UIStroke")
mainStroke.Color=COLORS.Border
mainStroke.Thickness=1.5
mainStroke.Parent=main

local gradient=Instance.new("UIGradient")
gradient.Color=ColorSequence.new(COLORS.Accent,COLORS.AccentB)
gradient.Rotation=45
gradient.Parent=mainStroke

--========================================================
-- TOP BAR
--========================================================

local topBar=Instance.new("Frame")
topBar.Size=UDim2.new(1,0,0,46)
topBar.BackgroundColor3=COLORS.Surface
topBar.BorderSizePixel=0
topBar.Parent=main

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-30,1,0)
title.Position=UDim2.fromOffset(18,0)
title.BackgroundTransparency=1
title.Text="LPT Hub"
title.TextColor3=COLORS.Text
title.TextSize=18
title.Font=Enum.Font.GothamBold
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=topBar

local subtitle=Instance.new("TextLabel")
subtitle.Size=UDim2.new(0,180,1,0)
subtitle.Position=UDim2.new(1,-195,0,0)
subtitle.BackgroundTransparency=1
subtitle.Text="by Ly Phuc Thien"
subtitle.TextColor3=COLORS.TextDim
subtitle.TextSize=11
subtitle.Font=Enum.Font.Gotham
subtitle.TextXAlignment=Enum.TextXAlignment.Right
subtitle.Parent=topBar

--========================================================
-- SIDEBAR
--========================================================

local sidebar=Instance.new("Frame")
sidebar.Size=UDim2.new(0,165,1,-46)
sidebar.Position=UDim2.fromOffset(0,46)
sidebar.BackgroundColor3=COLORS.Surface
sidebar.BorderSizePixel=0
sidebar.Parent=main

local content=Instance.new("Frame")
content.Size=UDim2.new(1,-165,1,-46)
content.Position=UDim2.fromOffset(165,46)
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

local function pageTitle(parent,text,description)
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-40,0,34)
	label.Position=UDim2.fromOffset(20,18)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=25
	label.Font=Enum.Font.GothamBold
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=parent

	local sub=Instance.new("TextLabel")
	sub.Size=UDim2.new(1,-40,0,22)
	sub.Position=UDim2.fromOffset(20,53)
	sub.BackgroundTransparency=1
	sub.Text=description
	sub.TextColor3=COLORS.TextDim
	sub.TextSize=12
	sub.Font=Enum.Font.Gotham
	sub.TextXAlignment=Enum.TextXAlignment.Left
	sub.Parent=parent
end

pageTitle(informationPage,"Information","Thông tin về LPT Hub.")
pageTitle(mainPage,"Main","Điều khiển các chức năng chính.")
pageTitle(settingsPage,"Settings","Điều chỉnh thông số chuyển động.")

--========================================================
-- TOGGLE
--========================================================

local function createToggle(parent,text,y,callback)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-40,0,52)
	row.Position=UDim2.fromOffset(20,y)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,11)
	corner.Parent=row

	local stroke=Instance.new("UIStroke")
	stroke.Color=COLORS.Border
	stroke.Transparency=.2
	stroke.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-85,1,0)
	label.Position=UDim2.fromOffset(16,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local button=Instance.new("TextButton")
	button.Size=UDim2.fromOffset(48,25)
	button.Position=UDim2.new(1,-64,.5,-12)
	button.BackgroundColor3=Color3.fromRGB(75,78,88)
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=row

	local buttonCorner=Instance.new("UICorner")
	buttonCorner.CornerRadius=UDim.new(1,0)
	buttonCorner.Parent=button

	local knob=Instance.new("Frame")
	knob.Size=UDim2.fromOffset(19,19)
	knob.Position=UDim2.fromOffset(3,3)
	knob.BackgroundColor3=Color3.fromRGB(235,235,240)
	knob.BorderSizePixel=0
	knob.Parent=button

	local knobCorner=Instance.new("UICorner")
	knobCorner.CornerRadius=UDim.new(1,0)
	knobCorner.Parent=knob

	local enabled=false

	local function setEnabled(value,fire)
		enabled=value==true

		tween(button,{
			BackgroundColor3=enabled and COLORS.Success or Color3.fromRGB(75,78,88)
		},.18)

		tween(knob,{
			Position=enabled and UDim2.new(1,-22,0,3) or UDim2.fromOffset(3,3),
			BackgroundColor3=enabled and Color3.fromRGB(15,20,18) or Color3.fromRGB(235,235,240)
		},.18)

		if fire~=false and callback then
			callback(enabled)
		end
	end

	button.MouseButton1Click:Connect(function()
		setEnabled(not enabled)
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

local function createSlider(parent,text,y,default,min,max,callback)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-40,0,75)
	row.Position=UDim2.fromOffset(20,y)
	row.BackgroundColor3=COLORS.Card
	row.BorderSizePixel=0
	row.Parent=parent

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,11)
	corner.Parent=row

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-35,0,22)
	label.Position=UDim2.fromOffset(16,9)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.Text
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=row

	local valueLabel=Instance.new("TextLabel")
	valueLabel.Size=UDim2.fromOffset(55,22)
	valueLabel.Position=UDim2.new(1,-72,0,9)
	valueLabel.BackgroundTransparency=1
	valueLabel.Text=tostring(default)
	valueLabel.TextColor3=COLORS.Accent
	valueLabel.TextSize=14
	valueLabel.Font=Enum.Font.GothamBold
	valueLabel.TextXAlignment=Enum.TextXAlignment.Right
	valueLabel.Parent=row

	local track=Instance.new("Frame")
	track.Size=UDim2.new(1,-32,0,6)
	track.Position=UDim2.fromOffset(16,49)
	track.BackgroundColor3=COLORS.Surface
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
	knob.Size=UDim2.fromOffset(15,15)
	knob.AnchorPoint=Vector2.new(.5,.5)
	knob.BackgroundColor3=Color3.new(1,1,1)
	knob.BorderSizePixel=0
	knob.Active=true
	knob.Parent=track

	local knobCorner=Instance.new("UICorner")
	knobCorner.CornerRadius=UDim.new(1,0)
	knobCorner.Parent=knob

	local dragging=false

	local function setValue(value,fire)
		value=math.clamp(math.floor(value+.5),min,max)

		local fraction=(value-min)/(max-min)
		fill.Size=UDim2.new(fraction,0,1,0)
		knob.Position=UDim2.new(fraction,0,.5,0)
		valueLabel.Text=tostring(value)

		if fire~=false and callback then
			callback(value)
		end

		return value
	end

	local function update(input)
		local x=input.Position.X-track.AbsolutePosition.X
		local fraction=math.clamp(x/track.AbsoluteSize.X,0,1)
		setValue(min+fraction*(max-min))
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			update(input)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			update(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
			or input.UserInputType==Enum.UserInputType.Touch) then
			update(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		end
	end)

	setValue(default,false)

	return setValue
end

--========================================================
-- INFORMATION
--========================================================

local infoCard=Instance.new("Frame")
infoCard.Size=UDim2.new(1,-40,0,220)
infoCard.Position=UDim2.fromOffset(20,95)
infoCard.BackgroundColor3=COLORS.Card
infoCard.BorderSizePixel=0
infoCard.Parent=informationPage

local infoCorner=Instance.new("UICorner")
infoCorner.CornerRadius=UDim.new(0,14)
infoCorner.Parent=infoCard

local infoTitle=Instance.new("TextLabel")
infoTitle.Size=UDim2.new(1,-30,0,30)
infoTitle.Position=UDim2.fromOffset(15,15)
infoTitle.BackgroundTransparency=1
infoTitle.Text="LPT Hub"
infoTitle.TextColor3=COLORS.Text
infoTitle.TextSize=21
infoTitle.Font=Enum.Font.GothamBold
infoTitle.TextXAlignment=Enum.TextXAlignment.Left
infoTitle.Parent=infoCard

local infoText=Instance.new("TextLabel")
infoText.Size=UDim2.new(1,-30,1,-60)
infoText.Position=UDim2.fromOffset(15,50)
infoText.BackgroundTransparency=1
infoText.Text="LPT Hub\n\nMovement utility với WalkSpeed, JumpPower,\nNo Clip, Fly và công cụ Fix Lag.\n\nCreated by Ly Phuc Thien"
infoText.TextColor3=COLORS.TextDim
infoText.TextSize=14
infoText.Font=Enum.Font.Gotham
infoText.TextXAlignment=Enum.TextXAlignment.Left
infoText.TextYAlignment=Enum.TextYAlignment.Top
infoText.Parent=infoCard

informationPage.CanvasSize=UDim2.new(0,0,0,340)

--========================================================
-- MAIN
--========================================================

local setWalkSpeedUI,setWalkSpeedState=createToggle(
	mainPage,
	"WalkSpeed",
	95,
	function(enabled)
		State.WalkSpeedEnabled=enabled
		applyMovement()
	end
)

local setJumpPowerUI,setJumpPowerState=createToggle(
	mainPage,
	"JumpPower",
	157,
	function(enabled)
		State.JumpPowerEnabled=enabled
		applyMovement()
	end
)

local setNoClipUI,setNoClipState=createToggle(
	mainPage,
	"No Clip",
	219,
	function(enabled)
		State.NoClip=enabled

		if enabled then
			rememberCollision(getCharacter())
		else
			restoreCollision()
		end
	end
)

local setFlyUI,setFlyState=createToggle(
	mainPage,
	"Fly",
	281,
	function(enabled)
		if enabled then
			startFly()
		else
			stopFly()
		end
	end
)

mainPage.CanvasSize=UDim2.new(0,0,0,370)

--========================================================
-- SETTINGS
--========================================================

createSlider(
	settingsPage,
	"WalkSpeed",
	95,
	State.WalkSpeed,
	1,
	500,
	function(value)
		State.WalkSpeed=value
		if State.WalkSpeedEnabled then
			applyMovement()
		end
	end
)

createSlider(
	settingsPage,
	"JumpPower",
	180,
	State.JumpPower,
	1,
	500,
	function(value)
		State.JumpPower=value
		if State.JumpPowerEnabled then
			applyMovement()
		end
	end
)

--========================================================
-- FIX LAG
--========================================================

local fixLag=Instance.new("TextButton")
fixLag.Size=UDim2.new(1,-40,0,50)
fixLag.Position=UDim2.fromOffset(20,270)
fixLag.BackgroundColor3=COLORS.Info
fixLag.BorderSizePixel=0
fixLag.Text="FIX LAG"
fixLag.TextColor3=Color3.new(1,1,1)
fixLag.TextSize=14
fixLag.Font=Enum.Font.GothamBold
fixLag.AutoButtonColor=false
fixLag.Parent=settingsPage

local fixCorner=Instance.new("UICorner")
fixCorner.CornerRadius=UDim.new(0,12)
fixCorner.Parent=fixLag

fixLag.MouseEnter:Connect(function()
	tween(fixLag,{BackgroundColor3=Color3.fromRGB(120,185,255)},.15)
end)

fixLag.MouseLeave:Connect(function()
	tween(fixLag,{BackgroundColor3=COLORS.Info},.15)
end)

fixLag.MouseButton1Click:Connect(function()
	local oldText=fixLag.Text
	fixLag.Text="FIXING..."

	pcall(function()
		local terrain=workspace:FindFirstChildOfClass("Terrain")
		if terrain then
			terrain.WaterWaveSize=0
			terrain.WaterWaveSpeed=0
			terrain.WaterReflectance=0
			terrain.WaterTransparency=1
		end
	end)

	pcall(function()
		local lighting=game:GetService("Lighting")

		for _,object in ipairs(lighting:GetChildren()) do
			if object:IsA("PostEffect") then
				object.Enabled=false
			end
		end
	end)

	pcall(function()
		for _,object in ipairs(workspace:GetDescendants()) do
			if object:IsA("ParticleEmitter")
				or object:IsA("Trail")
				or object:IsA("Beam") then
				object.Enabled=false
			end
		end
	end)

	task.wait(.35)

	fixLag.Text="FIXED ✓"

	task.wait(1)

	if fixLag.Parent then
		fixLag.Text=oldText
	end
end)

settingsPage.CanvasSize=UDim2.new(0,0,0,355)

--========================================================
-- SIDEBAR BUTTONS
--========================================================

local currentPage=nil
local sidebarButtons={}

local function selectPage(name)
	if not pages[name] then return end

	for pageName,page in pairs(pages) do
		page.Visible=pageName==name
	end

	for pageName,data in pairs(sidebarButtons) do
		local active=pageName==name

		tween(
			data.button,
			{
				BackgroundTransparency=active and .1 or 1
			},
			.15
		)

		tween(
			data.label,
			{
				TextColor3=active and COLORS.Text or COLORS.TextDim
			},
			.15
		)

		data.indicator.Visible=active
	end

	currentPage=name
end

local function createSidebarButton(text,order,pageName)
	local button=Instance.new("TextButton")
	button.Size=UDim2.new(1,-20,0,46)
	button.Position=UDim2.fromOffset(10,15+(order-1)*55)
	button.BackgroundColor3=COLORS.Card
	button.BackgroundTransparency=1
	button.BorderSizePixel=0
	button.Text=""
	button.AutoButtonColor=false
	button.Parent=sidebar

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,9)
	corner.Parent=button

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,-25,1,0)
	label.Position=UDim2.fromOffset(16,0)
	label.BackgroundTransparency=1
	label.Text=text
	label.TextColor3=COLORS.TextDim
	label.TextSize=14
	label.Font=Enum.Font.GothamMedium
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=button

	local indicator=Instance.new("Frame")
	indicator.Size=UDim2.fromOffset(3,25)
	indicator.Position=UDim2.new(0,0,.5,-12)
	indicator.BackgroundColor3=COLORS.Accent
	indicator.BorderSizePixel=0
	indicator.Visible=false
	indicator.Parent=button

	local indicatorCorner=Instance.new("UICorner")
	indicatorCorner.CornerRadius=UDim.new(1,0)
	indicatorCorner.Parent=indicator

	sidebarButtons[pageName]={
		button=button,
		label=label,
		indicator=indicator,
	}

	button.MouseEnter:Connect(function()
		if currentPage~=pageName then
			tween(button,{BackgroundTransparency=.65},.15)
		end
	end)

	button.MouseLeave:Connect(function()
		if currentPage~=pageName then
			tween(button,{BackgroundTransparency=1},.15)
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
-- DRAG
--========================================================

local dragging=false
local dragStart
local startPosition

topBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1
		or input.UserInputType==Enum.UserInputType.Touch then

		dragging=true
		dragStart=input.Position
		startPosition=main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end

	if input.UserInputType==Enum.UserInputType.MouseMovement
		or input.UserInputType==Enum.UserInputType.Touch then

		local delta=input.Position-dragStart

		main.Position=UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset+delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset+delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1
		or input.UserInputType==Enum.UserInputType.Touch then
		dragging=false
	end
end)

--========================================================
-- INITIAL
--========================================================

applyMovement()
