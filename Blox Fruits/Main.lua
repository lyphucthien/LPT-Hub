local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ESPModule = nil
local SettingsModule = nil
local PVPModule = nil
local ShopModule = nil
local ShopFightingStyleCheckboxes = {}

local ModuleLoaded = {
	Shop = false,
	Farming = true,
	PVP = false,
	ESP = false,
	Settings = false
}

local ModuleFailed = {
	Shop = false,
	PVP = false,
	ESP = false,
	Settings = false
}

local ModuleURL = {
	Shop = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Blox%20Fruits/ChucNang/Shop.lua",
	PVP = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Blox%20Fruits/ChucNang/PVP.lua",
	ESP = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Blox%20Fruits/ChucNang/ESP.lua",
	Settings = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Blox%20Fruits/ChucNang/Settings.lua"
}

local HttpService = game:GetService("HttpService")

local CONFIG_FOLDER = "LPT Hub"

local function ensureLPTFolder()
	if type(isfolder)~="function" or type(makefolder)~="function" then
		return false
	end

	local success,exists=pcall(function()
		return isfolder(CONFIG_FOLDER)
	end)

	if not success then
		return false
	end

	if not exists then
		pcall(function()
			makefolder(CONFIG_FOLDER)
		end)
	end

	local checkSuccess,folderExists=pcall(function()
		return isfolder(CONFIG_FOLDER)
	end)

	return checkSuccess and folderExists
end

ensureLPTFolder()

local function sanitizeFileName(name)
	return tostring(name or "Unknown")
		:gsub("[\\/:*?\"<>|]","_")
		:gsub("[\r\n]","")
		:gsub("%s+","_")
end

local playerName = sanitizeFileName(player.Name)
local safeGameName = "BloxFruits"
local CONFIG_FILE = CONFIG_FOLDER .."/" ..playerName .."-" ..safeGameName ..".json"

--========================================================
-- DEFAULT CONFIG
--========================================================

local DefaultConfig={
	-- FARMING
    FarmMethod = "Level Farm",
    FarmDistance = 300,
    IgnoreAttackKatakuri = false,
    HopFindKatakuri = false,
    AutoQuestKatakuriBoneTyrant = true,
    StartFarm = false,

	--ESP
	Island = false,
	Fruit = false,
	Player = false,

	--PVP
	WalkSpeed = 16,
	JumpPower = 50,
	ChangeWalkSpeed = false,
	ChangeJumpPower = false,
	WalkOnWater = false,

	--Settings
	WhiteScreen = false,
	BlackScreen = false,
	RemoveNotifications = false,
	AutoLoadScript = false,
	BoostFPS = false,

	WebhookURL = "",
	WebhookPing = "",
	WebhookPingEnabled = false,
	WebhookNotiProfile = false,
	WebhookStoreFruit = false,
	WebhookFindPrehistoricIsland = false,
	WebhookFindLeviathan = false,
	WebhookDestroyIDK = false,
	WebhookFindMirage = false,
	WebhookRarity = "Common"
}

local Config={}

local function deepCopy(tbl)
	local result = {}

	for key,value in pairs(tbl) do
		if type(value) == "table" then
			result[key] = deepCopy(value)
		else
			result[key] = value
		end
	end

	return result
end

Config = deepCopy(DefaultConfig)

--========================================================
-- LOAD CONFIG
--========================================================

local function loadConfig()

	ensureLPTFolder()

	if type(isfile) ~= "function" then
		return
	end

	local exists = 	false

	local checkSuccess,checkResult=pcall(function()
		return isfile(CONFIG_FILE)
	end)

	if checkSuccess then
		exists=checkResult
	end

	if not exists then
		return
	end

	local success,data=pcall(function()
		return readfile(CONFIG_FILE)
	end)

	if not success
		or type(data) ~= "string"
		or data == "" then

		return
	end

	local decodeSuccess,decoded=pcall(function()
		return HttpService:JSONDecode(data)
	end)

	if not decodeSuccess
		or type(decoded) ~= "table" then

		return
	end

	for key in pairs(DefaultConfig) do
		if decoded[key] ~= nil then
			Config[key] = decoded[key]
		end
	end
end

--========================================================
-- SAVE CONFIG
--========================================================

local saveQueued = false

local function saveConfig()

	if saveQueued then
		return
	end

	saveQueued=true

	task.delay(.1,function()

		saveQueued=false

		ensureLPTFolder()

		if type(writefile) ~= "function" then
			return
		end

		local success,json=pcall(function()
			return HttpService:JSONEncode(Config)
		end)

		if not success then
			warn("[LPT Hub] Config encode failed:",json)

			return
		end

		local writeSuccess,writeError=pcall(function()
			writefile(CONFIG_FILE,json)
		end)

		if not writeSuccess then
			warn("[LPT Hub] Config save failed:",writeError)
		end
	end)
end

loadConfig()

local oldGui=playerGui:FindFirstChild("LPTHub")
if oldGui then oldGui:Destroy() end

--========================================================
-- MODULE LOADER
--========================================================

local refreshSidebar=nil

local function assignModule(name,module)

	if name == "Shop" then
    ShopModule = module

    if ShopModule and type(ShopModule.SetCallback) == "function" then
        ShopModule:SetCallback("StateChanged", function(styleName, enabled)
            local setCheckbox = ShopFightingStyleCheckboxes[styleName]

            if setCheckbox then
                setCheckbox(enabled, false)
            end
        end)
    end

	elseif name == "ESP" then
		ESPModule=module

	elseif name == "PVP" then
		PVPModule=module

	elseif name == "Settings" then
		SettingsModule=module
	end

end

local function loadModule(name)

	local url = ModuleURL[name]

	if not url then
		ModuleFailed[name] = true
		return
	end

	task.spawn(function()

		local success,result = pcall(function()

			local source = game:HttpGet(url)

			local compiled = loadstring(source)

			if type(compiled) ~= "function" then
				error("loadstring failed")
			end

			local module = compiled()

			if not module then
				error("module returned nil")
			end

			return module

		end)

		if success and result then

			assignModule(name,result)

			ModuleLoaded[name] = true

			if name == "ESP" and ESPModule then

				ESPModule:Set("Island",Config.Island)
				ESPModule:Set("Fruit",Config.Fruit)
				ESPModule:Set("Player",Config.Player)

			elseif name == "PVP" and PVPModule then

				PVPModule:Set("WalkSpeed",Config.WalkSpeed)
				PVPModule:Set("JumpPower",Config.JumpPower)
				PVPModule:Set("ChangeWalkSpeed",Config.ChangeWalkSpeed)
				PVPModule:Set("ChangeJumpPower",Config.ChangeJumpPower)
				PVPModule:Set("WalkOnWater",Config.WalkOnWater)

			elseif name == "Settings" and SettingsModule then

				SettingsModule:Set("WhiteScreen",Config.WhiteScreen)
				SettingsModule:Set("BlackScreen",Config.BlackScreen)
				SettingsModule:Set("RemoveNotifications",Config.RemoveNotifications)
				SettingsModule:Set("AutoLoadScript",Config.AutoLoadScript)
				SettingsModule:Set("BoostFPS",Config.BoostFPS)

			end

			task.defer(function()

				if refreshSidebar then
					refreshSidebar()
				end

			end)

		else

			ModuleFailed[name] = true

			warn("[LPT Hub] Failed to load "..name..": ",result)

			task.defer(function()

				if refreshSidebar then
					refreshSidebar()
				end

			end)
		end
	end)
end

--========================================================
-- COLORS
--========================================================

local COLORS = {
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

local SIDEBAR_ACCENT = Color3.fromRGB(96,165,250)

--========================================================
-- HELPERS
--========================================================

local function tween(obj,props,time,style,direction)
	if not obj or not obj.Parent then return end

	local t = TweenService:Create(
		obj,
		TweenInfo.new(time or .18,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),
		props
	)

	t:Play()
	return t
end

local function gradient(obj,a,b,rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a,b)
	g.Rotation = rotation or 45
	g.Parent = obj
	return g
end

local function createCorner(obj,radius)
	local c=Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,radius or 10)
	c.Parent = obj
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
-- GUI
--========================================================

local gui=Instance.new("ScreenGui")
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
			BackgroundTransparency=1},1.1)

		task.wait(1.1)
	end
end)

local title=createLabel(
	topBar,"LPT Hub",
	UDim2.fromOffset(105,38),UDim2.fromOffset(36,0),
	Enum.Font.GothamBold,18.5,COLORS.Text
)

gradient(title,COLORS.Accent,COLORS.AccentB,0)

local author=createLabel(
	topBar,"by Ly Phuc Thien",
	UDim2.fromOffset(170,38),UDim2.fromOffset(113,0),
	Enum.Font.Gotham,11,COLORS.TextDim
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
	local b = Instance.new("TextButton")
	b.Name = name
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
	b.Parent = topBar

	createCorner(b,10)

	return b
end

local minimize=topButton("MinimizeButton",-110,"—",13)
local maximize=topButton("MaximizeButton",-76,"",0)
local close=topButton("CloseButton",-40,"×",17)

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

	--========================================================
	-- PAGE TITLE
	--========================================================

	createLabel(
		page,titleText,
		UDim2.new(1,-56,0,32),UDim2.fromOffset(28,6),
		Enum.Font.GothamBold,20,
		COLORS.Text,
		Enum.TextXAlignment.Left
	)

	--========================================================
	-- PAGE DESCRIPTION
	--========================================================

	if description then
		createLabel(
			page,description,
			UDim2.new(1,-56,0,20),UDim2.fromOffset(28,52),
			Enum.Font.Gotham,13,
			COLORS.TextDim
		)
	end

	--========================================================
	-- PAGE SEPARATOR
	--========================================================

	local pageSeparator=Instance.new("Frame")
	pageSeparator.Name="PageSeparator"
	pageSeparator.Size=UDim2.new(1,-56,0,1)
	pageSeparator.Position=UDim2.fromOffset(28,44)
	pageSeparator.BackgroundColor3=COLORS.Border
	pageSeparator.BorderSizePixel=0
	pageSeparator.Parent=page

	return page
end

local shopPage = createPage("Shop","Tab Shop")
local farmingPage = createPage("Farming","Tab Farming")
local espPage = createPage("ESP","Tab ESP")
local pvpPage = createPage("PVP","Tab PVP")
local settingsPage = createPage("Settings","Tab Settings")

--========================================================
-- CARD / TOGGLE / CHECKBOX
--========================================================

local function createCard(parent, text, y, height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -56, 0, height or 44)
	frame.Position = UDim2.fromOffset(28, y)
	frame.BackgroundColor3 = COLORS.Card
	frame.BorderSizePixel = 0
	frame.Parent = parent

	createCorner(frame, 10)
	createStroke(frame, COLORS.Border, .15, 1)
	createLabel(frame,text,
		UDim2.new(1, -64, 1, 0),UDim2.fromOffset(16, 0),
		Enum.Font.GothamMedium,13,COLORS.Text
	)

	frame.MouseEnter:Connect(function()
		tween(frame, {BackgroundColor3 = COLORS.CardHover}, .15)
	end)

	frame.MouseLeave:Connect(function()
		tween(frame, {BackgroundColor3 = COLORS.Card}, .15)
	end)

	return frame
end

local function createRightShopButton(parent, callback)
    local button = Instance.new("TextButton")
    button.Name = "RightShopButton"
    button.Size = UDim2.fromOffset(20, 20)
    button.Position = UDim2.new(1, -36, 0.5, -10)
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 10
    button.Parent = parent

    createCorner(button, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Color = SIDEBAR_ACCENT
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button

    button.MouseEnter:Connect(function()
        tween(stroke, {Thickness = 2.6}, 0.12)
    end)

    button.MouseLeave:Connect(function()
        tween(stroke, {Thickness = 2}, 0.12)
    end)

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return button
end

--========================================================
-- TOGGLE UI
--========================================================

local function createToggleUI(parent,default,callback)

	local toggleFrame=Instance.new("Frame")
	toggleFrame.Name="ToggleButton"
	toggleFrame.Size=UDim2.fromOffset(20,20)
	toggleFrame.Position=UDim2.new(1,-36,.5,-10)
	toggleFrame.BackgroundColor3=Color3.fromRGB(20,20,25)
	toggleFrame.BorderSizePixel=0
	toggleFrame.Parent=parent

	createCorner(toggleFrame,4)

	local stroke=Instance.new("UIStroke")
	stroke.Color=SIDEBAR_ACCENT
	stroke.Thickness=2
	stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	stroke.Parent=toggleFrame

	local fill=Instance.new("Frame")
	fill.Name="Fill"
	fill.AnchorPoint=Vector2.new(.5,.5)
	fill.Position=UDim2.new(.5,0,.5,0)
	fill.Size=UDim2.fromOffset(0,0)
	fill.BackgroundColor3=SIDEBAR_ACCENT
	fill.BorderSizePixel=0
	fill.ZIndex=2
	fill.Parent=toggleFrame

	createCorner(fill,2)

	local clickButton=Instance.new("TextButton")
	clickButton.Name="ClickButton"
	clickButton.Size=UDim2.fromScale(1,1)
	clickButton.BackgroundTransparency=1
	clickButton.BorderSizePixel=0
	clickButton.AutoButtonColor=false
	clickButton.Text=""
	clickButton.ZIndex=3
	clickButton.Parent=toggleFrame

	local enabled=default==true

	local function updateVisual()

		local goalSize=
			enabled
			and UDim2.new(1,-4,1,-4)
			or UDim2.fromOffset(0,0)

		tween(
			fill,
			{Size=goalSize},
			.18,
			Enum.EasingStyle.Quad
		)

	end

	local function setEnabled(value,fire)

		enabled=value==true

		updateVisual()

		if fire~=false and callback then
			callback(enabled)
		end

	end

	clickButton.MouseButton1Click:Connect(function()

		setEnabled(
			not enabled,
			true
		)

	end)

	clickButton.MouseEnter:Connect(function()

		tween(
			stroke,
			{Thickness=2.6},
			.12
		)

	end)

	clickButton.MouseLeave:Connect(function()

		tween(
			stroke,
			{Thickness=2},
			.12
		)

	end)

	setEnabled(enabled,false)

	return setEnabled
end

local function createUnifiedToggle(parent,text,y,default,callback)

	local row=createCard(parent,text,y,44)

	return createToggleUI(row,default,callback)

end

local createToggle=createUnifiedToggle
local createCheckbox=createUnifiedToggle

--========================================================
-- VALUE SLIDER (dùng chung cho Farming và PVP)
--========================================================

local function createValueSlider(
	parent,titleText,y,
	minValue,maxValue,
	defaultValue,callback
)

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-56,0,70)
	card.Position=UDim2.fromOffset(28,y)
	card.BackgroundColor3=COLORS.Card
	card.BorderSizePixel=0
	card.Parent=parent

	createCorner(card,10)
	createStroke(card,COLORS.Border,.15,1)

	createLabel(
		card,
		titleText,
		UDim2.new(1,-100,0,22),
		UDim2.fromOffset(16,6),
		Enum.Font.GothamMedium,
		13,
		COLORS.Text
	)

	local valueBox=Instance.new("TextBox")
	valueBox.Size=UDim2.fromOffset(64,24)
	valueBox.Position=UDim2.new(1,-80,0,6)
	valueBox.BackgroundColor3=Color3.fromRGB(29,30,38)
	valueBox.BorderSizePixel=0
	valueBox.Text=tostring(defaultValue)
	valueBox.PlaceholderText=tostring(defaultValue)
	valueBox.TextColor3=COLORS.Text
	valueBox.TextSize=12
	valueBox.Font=Enum.Font.GothamBold
	valueBox.ClearTextOnFocus=false
	valueBox.TextXAlignment=Enum.TextXAlignment.Center
	valueBox.Parent=card

	createCorner(valueBox,7)
	createStroke(valueBox,COLORS.Border,.25,1)

	local slider=Instance.new("Frame")
	slider.Size=UDim2.new(1,-32,0,6)
	slider.Position=UDim2.fromOffset(16,48)
	slider.BackgroundColor3=Color3.fromRGB(24,26,34)
	slider.BorderSizePixel=0
	slider.Parent=card

	createCorner(slider,20)

	local fill=Instance.new("Frame")
	fill.Size=UDim2.fromScale(0,1)
	fill.BackgroundColor3=SIDEBAR_ACCENT
	fill.BorderSizePixel=0
	fill.Parent=slider

	createCorner(fill,20)

	local knob=Instance.new("Frame")
	knob.Size=UDim2.fromOffset(12,12)
	knob.AnchorPoint=Vector2.new(.5,.5)
	knob.Position=UDim2.new(0,0,.5,0)
	knob.BackgroundColor3=SIDEBAR_ACCENT
	knob.BorderSizePixel=0
	knob.Parent=slider

	createCorner(knob,50)

	local dragButton=Instance.new("TextButton")
	dragButton.Size=UDim2.new(1,20,1,20)
	dragButton.Position=UDim2.fromOffset(-10,-10)
	dragButton.BackgroundTransparency=1
	dragButton.BorderSizePixel=0
	dragButton.Text=""
	dragButton.AutoButtonColor=false
	dragButton.Parent=slider

	local value=math.clamp(
		tonumber(defaultValue) or minValue,
		minValue,
		maxValue
	)

	local dragging=false

	local function updateVisual()

		local alpha=
			(value-minValue)
			/
			(maxValue-minValue)

		alpha=math.clamp(alpha,0,1)

		fill.Size=UDim2.new(alpha,0,1,0)
		knob.Position=UDim2.new(alpha,0,.5,0)
		valueBox.Text=tostring(value)

	end

	local function setValue(newValue,fire)

		newValue=tonumber(newValue)

		if not newValue then
			updateVisual()
			return
		end

		newValue=math.clamp(
			newValue,
			minValue,
			maxValue
		)

		newValue=math.floor(newValue+0.5)

		value=newValue

		updateVisual()

		if fire~=false and callback then
			callback(value)
		end

	end

	local function setFromMouse(x)

		local startX=slider.AbsolutePosition.X
		local width=slider.AbsoluteSize.X

		if width<=0 then
			return
		end

		local alpha=(x-startX)/width
		alpha=math.clamp(alpha,0,1)

		local newValue=
			minValue+
			(maxValue-minValue)*alpha

		setValue(newValue,true)

	end

	dragButton.InputBegan:Connect(function(input)

		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then

			dragging=true
			setFromMouse(input.Position.X)

		end

	end)

	dragButton.InputEnded:Connect(function(input)

		if input.UserInputType==Enum.UserInputType.MouseButton1
			or input.UserInputType==Enum.UserInputType.Touch then

			dragging=false

		end

	end)

	UserInputService.InputChanged:Connect(function(input)

		if not dragging then
			return
		end

		if input.UserInputType~=Enum.UserInputType.MouseMovement
			and input.UserInputType~=Enum.UserInputType.Touch then

			return
		end

		setFromMouse(input.Position.X)

	end)

	valueBox.FocusLost:Connect(function()

		local number=tonumber(valueBox.Text)

		if number then
			setValue(number,true)
		else
			updateVisual()
		end

	end)

	updateVisual()

	return setValue
end

--========================================================
-- SHOP PAGE
--========================================================

local shopTitle=createLabel(
	shopPage,
	"Misc Shop",
	UDim2.new(1,-56,0,28),
	UDim2.fromOffset(28,58),
	Enum.Font.GothamBold,
	18,
	COLORS.Text,
	Enum.TextXAlignment.Center
)

local shopSeparator=Instance.new("Frame")
shopSeparator.Size=UDim2.new(1,-56,0,1)
shopSeparator.Position=UDim2.fromOffset(28,88)
shopSeparator.BackgroundColor3=COLORS.Border
shopSeparator.BorderSizePixel=0
shopSeparator.Parent=shopPage

-- MISC SHOP
local redeemCard = createCard(shopPage, "Redeem Code", 100, 44)

createRightShopButton(redeemCard, function()
    if ShopModule then
        ShopModule:RedeemCode()
    end
end)

local rerollCard = createCard(shopPage, "Reroll Race [2,500 Fragments]", 152, 44)

createRightShopButton(rerollCard, function()
    if ShopModule then
        ShopModule:Buy("Reroll Race")
    end
end)

local resetStatsCard = createCard(shopPage, "Reset Stats [3,000 Fragments]", 204, 44)

createRightShopButton(resetStatsCard, function()
    if ShopModule then
        ShopModule:Buy("Reset Stats")
    end
end)

local cyborgCard = createCard(shopPage, "Buy Race Cyborg [3,000 Fragments]", 256, 44)

createRightShopButton(cyborgCard, function()
    if ShopModule then
        ShopModule:Buy("Buy Race Cyborg")
    end
end)

local ghoulCard = createCard(shopPage, "Buy Race Ghoul [3,000 Fragments]", 308, 44)

createRightShopButton(ghoulCard, function()
    if ShopModule then
        ShopModule:Buy("Buy Race Ghoul")
    end
end)

-- FIGHTING SHOP
local fightingTitle=createLabel(
	shopPage,"Fighting Shop",
	UDim2.new(1,-56,0,28),UDim2.fromOffset(28,368),
	Enum.Font.GothamBold,18,COLORS.Text,
	Enum.TextXAlignment.Center
)

local fightingSeparator=Instance.new("Frame")
fightingSeparator.Size=UDim2.new(1,-56,0,1)
fightingSeparator.Position=UDim2.fromOffset(28,398)
fightingSeparator.BackgroundColor3=COLORS.Border
fightingSeparator.BorderSizePixel=0
fightingSeparator.Parent=shopPage

ShopFightingStyleCheckboxes["Dark Step"] = createCheckbox(
	shopPage,"Dark Step",410,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Dark Step",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Electric"] = createCheckbox(
	shopPage,"Electric",462,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Electric",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Water Kung Fu"] = createCheckbox(
	shopPage,"Water Kung Fu",514,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Water Kung Fu",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Dragon Breath"] = createCheckbox(
	shopPage,"Dragon Breath",566,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Dragon Breath",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Superhuman"] = createCheckbox(
	shopPage,"Superhuman",618,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Superhuman",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Death Step"] = createCheckbox(
	shopPage,"Death Step",670,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Death Step",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Sharkman Karate"] = createCheckbox(
	shopPage,"Sharkman Karate",722,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Sharkman Karate",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Electric Claw"] = createCheckbox(
	shopPage,"Electric Claw",774,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Electric Claw",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Dragon Talon"] = createCheckbox(
	shopPage,"Dragon Talon",826,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Dragon Talon",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["God Human"] = createCheckbox(
	shopPage,"God Human",878,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("God Human",enabled)
		end
	end
)

ShopFightingStyleCheckboxes["Sanguine Art"] = createCheckbox(
	shopPage,"Sanguine Art",930,false,
	function(enabled)
		if ShopModule then
			ShopModule:Set("Sanguine Art",enabled)
		end
	end
)

-- ABILITIES SHOP
local abilitiesTitle = createLabel(
    shopPage,"Abilities Shop",
    UDim2.new(1,-56,0,28),UDim2.fromOffset(28, 990),
    Enum.Font.GothamBold,18,COLORS.Text,
    Enum.TextXAlignment.Center
)

local abilitiesSeparator = Instance.new("Frame")
abilitiesSeparator.Size = UDim2.new(1, -56, 0, 1)
abilitiesSeparator.Position = UDim2.fromOffset(28, 1020)
abilitiesSeparator.BackgroundColor3 = COLORS.Border
abilitiesSeparator.BorderSizePixel = 0
abilitiesSeparator.Parent = shopPage

local skyJumpCard = createCard(shopPage, "Sky Jump [10,000 Beli]", 1032, 44)

createRightShopButton(skyJumpCard, function()
    if ShopModule then
        ShopModule:Buy("Sky Jump")
    end
end)

local busoCard = createCard(shopPage, "Buso Haki [25,000 Beli]", 1084, 44)

createRightShopButton(busoCard, function()
    if ShopModule then
        ShopModule:Buy("Buso Haki")
    end
end)

local flashStepCard = createCard(shopPage, "Flash Step [100,000 Beli]", 1136, 44)

createRightShopButton(flashStepCard, function()
    if ShopModule then
        ShopModule:Buy("Flash Step")
    end
end)

local observationCard = createCard(shopPage, "Observation Haki [750,000 Beli]", 1188, 44)

createRightShopButton(observationCard, function()
    if ShopModule then
        ShopModule:Buy("Observation Haki")
    end
end)

shopPage.CanvasSize = UDim2.fromOffset(0, 1256)

--========================================================
-- FARMING PAGE
--========================================================

local FARM_UI = {
    Background = Color3.fromRGB(24, 24, 30),
    Border = Color3.fromRGB(39, 40, 48),
    Input = Color3.fromRGB(37, 38, 46),
    Accent = Color3.fromRGB(255, 199, 55),
    Divider = Color3.fromRGB(75, 76, 53),
}

local function createFarmingRow(name, y, height)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, -56, 0, height)
    row.Position = UDim2.fromOffset(28, y)
    row.BackgroundColor3 = COLORS.Card
    row.BorderSizePixel = 0
    row.Parent = farmingPage
    row.ZIndex = 2

    createCorner(row, 14)
    createStroke(row, COLORS.Border, 0.15, 1)

    return row
end

local function createFarmingToggle(labelText, y, configKey)
    local row = createFarmingRow("FarmToggle_" .. configKey, y, 31)

    local label = createLabel(
        row,
        labelText,
        UDim2.new(1, -48, 1, 0),
        UDim2.fromOffset(10, 0),
        Enum.Font.GothamBold,
        13,
        COLORS.Text,
        Enum.TextXAlignment.Left
    )
    label.ZIndex = 3

    local toggle = Instance.new("Frame")
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.fromOffset(22, 22)
    toggle.Position = UDim2.new(1, -10, 0.5, -11)
    toggle.AnchorPoint = Vector2.new(1, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    toggle.ZIndex = 4
    createCorner(toggle, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Name = "ToggleStroke"
    stroke.Color = FARM_UI.Accent
    stroke.Thickness = 1.8
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = toggle

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Position = UDim2.fromOffset(3, 3)
    fill.Size = UDim2.new(1, -6, 1, -6)
    fill.BackgroundColor3 = FARM_UI.Accent
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.ZIndex = 5
    fill.Parent = toggle
    createCorner(fill, 2)

    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.fromScale(1, 1)
    clickButton.BackgroundTransparency = 1
    clickButton.BorderSizePixel = 0
    clickButton.Text = ""
    clickButton.AutoButtonColor = false
    clickButton.ZIndex = 6
    clickButton.Parent = toggle

    local enabled = Config[configKey] == true

    local function updateVisual()
        fill.Visible = enabled
        if enabled then
            fill.Size = UDim2.new(1, -6, 1, -6)
        end
    end

    local function setEnabled(value, fireCallback)
        enabled = value == true
        updateVisual()
        if fireCallback ~= false then
            Config[configKey] = enabled
            saveConfig()
        end
    end

    clickButton.MouseButton1Click:Connect(function()
        setEnabled(not enabled, true)
    end)

    clickButton.MouseEnter:Connect(function()
        tween(stroke, {Thickness = 2.4}, 0.1)
    end)

    clickButton.MouseLeave:Connect(function()
        tween(stroke, {Thickness = 1.8}, 0.1)
    end)


	row.MouseEnter:Connect(function()
		tween(row, {BackgroundColor3 = COLORS.CardHover}, 0.15)
	end)

	row.MouseLeave:Connect(function()
		tween(row, {BackgroundColor3 = COLORS.Card}, 0.15)
	end)

    setEnabled(enabled, false)
    return setEnabled
end

local farmSettingsTitle = createLabel(
	farmingPage,
	"Settings Farm",
	UDim2.new(1,-56,0,28),
	UDim2.fromOffset(28,58),
	Enum.Font.GothamBold,
	18,
	COLORS.Text,
	Enum.TextXAlignment.Center
)

local farmSettingsSeparator = Instance.new("Frame")
farmSettingsSeparator.Size = UDim2.new(1,-56,0,1)
farmSettingsSeparator.Position = UDim2.fromOffset(28,88)
farmSettingsSeparator.BackgroundColor3 = COLORS.Border
farmSettingsSeparator.BorderSizePixel = 0
farmSettingsSeparator.Parent = farmingPage

local methodRow = createCard(farmingPage, "", 100, 44)
methodRow.Name = "FarmMethodRow"
methodRow.ZIndex = 2

local methodLabel = methodRow:FindFirstChildWhichIsA("TextLabel")
methodLabel.Position = UDim2.fromOffset(16, 0)
methodLabel.Size = UDim2.new(1, -(16 + 48), 1, 0)
methodLabel.Font = Enum.Font.GothamMedium
methodLabel.TextSize = 13
methodLabel.ZIndex = 3

local methodArrow = createLabel(
    methodRow,
    "›",
    UDim2.new(0, 24, 1, 0),
    UDim2.new(1, -40, 0, 0),
    Enum.Font.GothamBold,
    20,
    COLORS.Text,
    Enum.TextXAlignment.Center
)
methodArrow.ZIndex = 3

local methodClick = Instance.new("TextButton")
methodClick.Name = "MethodClickArea"
methodClick.Size = UDim2.fromScale(1, 1)
methodClick.BackgroundTransparency = 1
methodClick.BorderSizePixel = 0
methodClick.Text = ""
methodClick.AutoButtonColor = false
methodClick.ZIndex = 5
methodClick.Parent = methodRow

local METHOD_OPTION_HEIGHT = 28
local methodOptions = {"Level Farm", "Katakuri Farm", "Bone Farm", "Tyrant Farm"}
local methodMenu = Instance.new("Frame")
methodMenu.Name = "FarmMethodDropdown"
methodMenu.Size = UDim2.new(1, -56, 0, #methodOptions * METHOD_OPTION_HEIGHT)
methodMenu.Position = UDim2.fromOffset(28, 148)
methodMenu.BackgroundColor3 = COLORS.Surface
methodMenu.BorderSizePixel = 0
methodMenu.Visible = false
methodMenu.ClipsDescendants = true
methodMenu.ZIndex = 20
methodMenu.Parent = farmingPage
createCorner(methodMenu, 12)
createStroke(methodMenu, COLORS.Border, 0, 1)

local function updateMethodLabel()
    methodLabel.Text = "Select Method Farm: " .. tostring(Config.FarmMethod or "Level Farm")
end

for index, methodName in ipairs(methodOptions) do
    local option = Instance.new("TextButton")
    option.Name = "MethodOption" .. index
    option.Size = UDim2.new(1, 0, 0, METHOD_OPTION_HEIGHT)
    option.Position = UDim2.fromOffset(0, (index - 1) * METHOD_OPTION_HEIGHT)
    option.BackgroundColor3 = COLORS.Card
    option.BackgroundTransparency = 1
    option.BorderSizePixel = 0
    option.Text = methodName
    option.TextColor3 = COLORS.TextDim
    option.TextSize = 12
    option.Font = Enum.Font.GothamMedium
    option.TextXAlignment = Enum.TextXAlignment.Left
    option.AutoButtonColor = false
    option.ZIndex = 21
    option.Parent = methodMenu

    local optionPadding = Instance.new("UIPadding")
    optionPadding.PaddingLeft = UDim.new(0, 16)
    optionPadding.Parent = option

    option.MouseEnter:Connect(function()
        tween(option, {BackgroundTransparency = 0.3, TextColor3 = COLORS.Text}, 0.1)
    end)
    option.MouseLeave:Connect(function()
        local selected = Config.FarmMethod == methodName
        tween(option, {
            BackgroundTransparency = 1,
            TextColor3 = selected and COLORS.Text or COLORS.TextDim
        }, 0.1)
    end)
    option.MouseButton1Click:Connect(function()
        Config.FarmMethod = methodName
        updateMethodLabel()
        methodMenu.Visible = false
        saveConfig()
    end)
end

methodClick.MouseButton1Click:Connect(function()
    methodMenu.Visible = not methodMenu.Visible

    for _, option in ipairs(methodMenu:GetChildren()) do
        if option:IsA("TextButton") then
            option.TextColor3 = (option.Text == Config.FarmMethod) and COLORS.Text or COLORS.TextDim
        end
    end
end)

createValueSlider(
    farmingPage,
    "Distance Farm",
    152,
    0,
    1000,
    Config.FarmDistance or 300,
    function(value)
        Config.FarmDistance = value
        saveConfig()
    end
)

local function createFarmCheckbox(text, y, default, callback)
    return createCheckbox(farmingPage, text, y, default, callback)
end

createFarmCheckbox(
    "Ignore Attack Katakuri",
    230,
    Config.IgnoreAttackKatakuri,
    function(enabled)
        Config.IgnoreAttackKatakuri = enabled
        saveConfig()
    end
)

createFarmCheckbox(
    "Auto Quest",
    282,
    Config.AutoQuestKatakuriBoneTyrant,
    function(enabled)
        Config.AutoQuestKatakuriBoneTyrant = enabled
        saveConfig()
    end
)

createFarmCheckbox(
    "Start Farm",
    334,
    Config.StartFarm,
    function(enabled)
        Config.StartFarm = enabled
        saveConfig()
    end
)

updateMethodLabel()
farmingPage.CanvasSize = UDim2.fromOffset(0, 402)

--========================================================
-- ESP PAGE
--========================================================

createCheckbox(
	espPage,
	"ESP Island",
	58,
	Config.Island,
	function(enabled)
		Config.Island=enabled

		if ESPModule then
			ESPModule:Set("Island",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	espPage,
	"ESP Fruit",
	110,
	Config.Fruit,
	function(enabled)
		Config.Fruit=enabled

		if ESPModule then
			ESPModule:Set("Fruit",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	espPage,
	"ESP Player",
	162,
	Config.Player,
	function(enabled)
		Config.Player=enabled

		if ESPModule then
			ESPModule:Set("Player",enabled)
		end

		saveConfig()
	end
)

espPage.CanvasSize=UDim2.fromOffset(0,230)

--========================================================
-- PVP PAGE
--========================================================

local otherTitle=createLabel(
	pvpPage,
	"Other",
	UDim2.new(1,-56,0,28),
	UDim2.fromOffset(28,58),
	Enum.Font.GothamBold,
	18,
	COLORS.Text,
	Enum.TextXAlignment.Center
)

local otherSeparator=Instance.new("Frame")
otherSeparator.Size=UDim2.new(1,-56,0,1)
otherSeparator.Position=UDim2.fromOffset(28,88)
otherSeparator.BackgroundColor3=COLORS.Border
otherSeparator.BorderSizePixel=0
otherSeparator.Parent=pvpPage

createValueSlider(
	pvpPage,
	"Input WalkSpeed",
	100,
	0,
	500,
	Config.WalkSpeed,
	function(value)

		Config.WalkSpeed=value

		if PVPModule then
			PVPModule:Set(
				"WalkSpeed",
				value
			)
		end

		saveConfig()
	end
)

createValueSlider(
	pvpPage,
	"Input JumpPower",
	178,
	0,
	500,
	Config.JumpPower,
	function(value)

		Config.JumpPower=value

		if PVPModule then
			PVPModule:Set(
				"JumpPower",
				value
			)
		end

		saveConfig()
	end
)

createCheckbox(
	pvpPage,
	"Change WalkSpeed",
	256,
	Config.ChangeWalkSpeed,
	function(enabled)

		Config.ChangeWalkSpeed=enabled

		if PVPModule then
			PVPModule:Set(
				"ChangeWalkSpeed",
				enabled
			)
		end

		saveConfig()
	end
)

createCheckbox(
	pvpPage,
	"Change JumpPower",
	308,
	Config.ChangeJumpPower,
	function(enabled)

		Config.ChangeJumpPower=enabled

		if PVPModule then
			PVPModule:Set(
				"ChangeJumpPower",
				enabled
			)
		end

		saveConfig()
	end
)

createCheckbox(
	pvpPage,
	"Walk On Water",
	360,
	Config.WalkOnWater,
	function(enabled)

		Config.WalkOnWater=enabled

		if PVPModule then
			PVPModule:Set(
				"WalkOnWater",
				enabled
			)
		end

		saveConfig()
	end
)

pvpPage.CanvasSize=UDim2.fromOffset(0,428)

--========================================================
-- SETTINGS PAGE
--========================================================

createCheckbox(
	settingsPage,
	"White Screen",
	58,
	Config.WhiteScreen,
	function(enabled)
		Config.WhiteScreen=enabled

		if SettingsModule then
			SettingsModule:Set("WhiteScreen",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Black Screen",
	110,
	Config.BlackScreen,
	function(enabled)
		Config.BlackScreen=enabled

		if SettingsModule then
			SettingsModule:Set("BlackScreen",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Remove Notifications",
	162,
	Config.RemoveNotifications,
	function(enabled)
		Config.RemoveNotifications=enabled

		if SettingsModule then
			SettingsModule:Set("RemoveNotifications",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Auto Load Script",
	214,
	Config.AutoLoadScript,
	function(enabled)
		Config.AutoLoadScript=enabled

		if SettingsModule then
			SettingsModule:Set("AutoLoadScript",enabled)
		end

		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Boost FPS",
	266,
	Config.BoostFPS,
	function(enabled)
		Config.BoostFPS=enabled

		if SettingsModule then
			SettingsModule:Set("BoostFPS",enabled)
		end

		saveConfig()
	end
)

--========================================================
-- WEBHOOK TITLE
--========================================================

createLabel(
	settingsPage,
	"Webhook",
	UDim2.new(1,-56,0,28),
	UDim2.fromOffset(28,326),
	Enum.Font.GothamBold,
	18,
	COLORS.Text,
	Enum.TextXAlignment.Center
)

local webhookSeparator=Instance.new("Frame")
webhookSeparator.Size=UDim2.new(1,-56,0,1)
webhookSeparator.Position=UDim2.fromOffset(28,356)
webhookSeparator.BackgroundColor3=COLORS.Border
webhookSeparator.BorderSizePixel=0
webhookSeparator.Parent=settingsPage

--========================================================
-- INPUT CARD
--========================================================

local function createInputCard(parent,text,y,value,callback,showToggle,toggleDefault,toggleCallback)

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-56,0,62)
	card.Position=UDim2.fromOffset(28,y)
	card.BackgroundColor3=COLORS.Card
	card.BorderSizePixel=0
	card.Parent=parent

	createCorner(card,10)
	createStroke(card,COLORS.Border,.15,1)

	createLabel(
		card,
		text,
		UDim2.new(1,-60,0,20),
		UDim2.fromOffset(16,5),
		Enum.Font.GothamMedium,
		13,
		COLORS.Text
	)

	local input=Instance.new("TextBox")
	input.Size=UDim2.new(1,showToggle and -66 or -32,0,26)
	input.Position=UDim2.fromOffset(16,28)
	input.BackgroundColor3=Color3.fromRGB(29,30,38)
	input.BorderSizePixel=0
	input.Text=value or ""
	input.PlaceholderText="Type here"
	input.PlaceholderColor3=COLORS.TextDim
	input.TextColor3=COLORS.Text
	input.TextSize=12
	input.Font=Enum.Font.Gotham
	input.ClearTextOnFocus=false
	input.TextXAlignment=Enum.TextXAlignment.Left
	input.Parent=card

	createCorner(input,6)
	createStroke(input,COLORS.Border,.3,1)

	input.FocusLost:Connect(function()
		if callback then
			callback(input.Text)
		end
	end)

	if showToggle then
		createToggleUI(
			card,
			toggleDefault,
			function(enabled)
				if toggleCallback then
					toggleCallback(enabled)
				end
			end
		)
	end

	return input
end

--========================================================
-- WEBHOOK INPUT
--========================================================

local webhookUrlInput=createInputCard(
	settingsPage,
	"Input Url Webhook",
	368,
	Config.WebhookURL,
	function(text)
		Config.WebhookURL=text
		saveConfig()
	end
)

local webhookPingInput=createInputCard(
	settingsPage,
	"Input Discord Ping (Everyone/ID Role)",
	438,
	Config.WebhookPing,
	function(text)
		Config.WebhookPing=text
		saveConfig()
	end,
	true,
	Config.WebhookPingEnabled,
	function(enabled)
		Config.WebhookPingEnabled=enabled
		saveConfig()
	end
)

--========================================================
-- WEBHOOK OPTIONS
--========================================================

createCheckbox(
	settingsPage,
	"Noti Profile",
	512,
	Config.WebhookNotiProfile,
	function(enabled)
		Config.WebhookNotiProfile=enabled
		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Webhook Store Fruit",
	564,
	Config.WebhookStoreFruit,
	function(enabled)
		Config.WebhookStoreFruit=enabled
		saveConfig()
	end
)

--========================================================
-- SELECT RARITY
--========================================================

local rarities={
	"Common",
	"Uncommon",
	"Rare",
	"Legendary",
	"Mythical"
}

local rarityCard=createCard(
	settingsPage,
	"Select Rarity Fruit: "..tostring(Config.WebhookRarity or "Common"),
	616,
	44
)

local rarityLabel=rarityCard:FindFirstChildWhichIsA("TextLabel")

local rarityArrow=createLabel(
	rarityCard,
	"›",
	UDim2.new(0,24,1,0),
	UDim2.new(1,-40,0,0),
	Enum.Font.GothamBold,
	20,
	COLORS.Text,
	Enum.TextXAlignment.Center
)

local rarityButton=Instance.new("TextButton")
rarityButton.Size=UDim2.fromScale(1,1)
rarityButton.BackgroundTransparency=1
rarityButton.BorderSizePixel=0
rarityButton.Text=""
rarityButton.Parent=rarityCard

rarityButton.MouseButton1Click:Connect(function()

	local current=Config.WebhookRarity or "Common"
	local index=1

	for i,name in ipairs(rarities) do
		if name==current then
			index=i
			break
		end
	end

	index=index+1

	if index>#rarities then
		index=1
	end

	Config.WebhookRarity=rarities[index]

	if rarityLabel then
		rarityLabel.Text="Select Rarity Fruit: "..Config.WebhookRarity
	end

	saveConfig()
end)

createCheckbox(
	settingsPage,
	"Webhook Find Prehistoric Island",
	668,
	Config.WebhookFindPrehistoricIsland,
	function(enabled)
		Config.WebhookFindPrehistoricIsland=enabled
		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Webhook Find Leviathan",
	720,
	Config.WebhookFindLeviathan,
	function(enabled)
		Config.WebhookFindLeviathan=enabled
		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Webhook Destroy IDK",
	772,
	Config.WebhookDestroyIDK,
	function(enabled)
		Config.WebhookDestroyIDK=enabled
		saveConfig()
	end
)

createCheckbox(
	settingsPage,
	"Webhook Find Mirage",
	824,
	Config.WebhookFindMirage,
	function(enabled)
		Config.WebhookFindMirage=enabled
		saveConfig()
	end
)

settingsPage.CanvasSize=UDim2.fromOffset(0,892)

--========================================================
-- SIDEBAR MENU
--========================================================

local menuItems = {
	{"Shop","Shop"},
	{"Farming","Farming"},
	{"ESP","ESP"},
	{"PVP","PVP"},
	{"Settings","Settings"}
}

local sidebarButtons={}
local currentPage=nil
local indicator=nil

local function moduleAvailable(name)
	return ModuleLoaded[name]==true
end

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

refreshSidebar=function()

	local oldCurrent=currentPage

	for _,data in pairs(sidebarButtons) do

		if data.button
			and data.button.Parent then

			data.button:Destroy()

		end
	end

	table.clear(sidebarButtons)

	if indicator and indicator.Parent then

		indicator:Destroy()

	end

	indicator=nil

	local order=0

	for _,item in ipairs(menuItems) do

		local pageName=item[1]
		local title=item[2]

		if ModuleLoaded[pageName] then

			order+=1

			createSidebarButton(title,order,pageName)

		end
	end

	local targetPage=nil

	if oldCurrent
		and ModuleLoaded[oldCurrent] then

		targetPage=oldCurrent

	else

		for _,item in ipairs(menuItems) do

			if ModuleLoaded[item[1]] then

				targetPage=item[1]
				break

			end
		end
	end

	if targetPage then

		currentPage=nil
		selectPage(targetPage)

	else

		for _,page in pairs(pages) do
			page.Visible=false
		end

		currentPage=nil

	end
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
local minimizedPosition=UDim2.new(.5,-150,-.060,15)

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
		tween(main,{Size=maximizedSize,Position=maximizedPosition},.25,Enum.EasingStyle.Quint)
	else
		tween(main,{Size=normalSize,Position=normalPosition},.25,Enum.EasingStyle.Quint)
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

	tween(main,{Size=minimizedSize,Position=minimizedPosition},.28,Enum.EasingStyle.Quint)
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

close.MouseButton1Click:Connect(function()

	saveConfig()

	if ShopModule then
		if ShopModule.Destroy then
			ShopModule:Destroy()
		end

		ShopModule=nil
	end

	if ESPModule then
		ESPModule:Destroy()
		ESPModule=nil
	end

	if PVPModule then
		if PVPModule.Destroy then
			PVPModule:Destroy()
		end

		PVPModule=nil
	end

	if SettingsModule then
		SettingsModule:Destroy()
		SettingsModule=nil
	end

	if gui and gui.Parent then
		gui:Destroy()
	end
end)

loadModule("Shop")
loadModule("PVP")
loadModule("ESP")
loadModule("Settings")

refreshSidebar()
updateButtons()
