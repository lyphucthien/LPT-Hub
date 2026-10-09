local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
local UserInputService=game:GetService("UserInputService")
local MarketplaceService=game:GetService("MarketplaceService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local GET_KEY_LINK="https://link4sub.com/owycAYxKdu"

local UNIVERSAL_SCRIPT="https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Script%20Cho%20Game%20Ko%20H%E1%BB%97%20Tr%E1%BB%A3/Script.lua"

local GAME_HO_TRO={
	["+1 Speed Keyboard Escape"]={
		Name="+1 Speed Keyboard Escape",
		PlaceId={95082159892680},
		UniverseId={9584852943},
		WaitForDataLoaded=false,
		MainUI="https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/%2B1%20Speed%20Keyboard%20Escape/MainUI.lua",
	},
	["Blox Fruits"]={
		Name="Blox Fruits",
		PlaceId={85211729168715},
		UniverseId={994732206},
		WaitForDataLoaded=false,
		MainUI="https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/Blox%20Fruits/Main.lua",
	},
}

local State={
	KeyValid=false,
	PlaceId=nil,
	UniverseId=nil,
	GameName="Unknown Game",
	RobloxGameName=nil,
	GameSupported=false,
	GameConfig=nil,
	MainUI=nil,
	Loading=false,
	Submitting=false,
}

local COLORS={
	Background=Color3.fromRGB(8,18,32),
	SurfaceLight=Color3.fromRGB(40,44,58),
	Card=Color3.fromRGB(34,38,50),
	Accent=Color3.fromRGB(168,105,245),
	AccentB=Color3.fromRGB(236,72,153),
	Text=Color3.fromRGB(240,241,245),
	TextDim=Color3.fromRGB(145,153,168),
	Border=Color3.fromRGB(52,56,70),
	Danger=Color3.fromRGB(255,92,108),
	Success=Color3.fromRGB(74,222,128),
	Info=Color3.fromRGB(96,165,250),
	Warning=Color3.fromRGB(250,204,21),
}

--============================================================
-- HELPERS
--============================================================

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
	gradient.Rotation=rotation or 0
	gradient.Parent=obj
	return gradient
end

--============================================================
-- KEY FILE
--============================================================

local LPT_HUB_FOLDER="LPT Hub"
local KEY_FILE=LPT_HUB_FOLDER.."/LPT_Hub_Key.json"

local KEY_DURATION=3*60*60

local function ensureLPTFolder()
	if type(isfolder)=="function" and type(makefolder)=="function" then
		local ok,exists=pcall(function()
			return isfolder(LPT_HUB_FOLDER)
		end)

		if ok and not exists then
			pcall(function()
				makefolder(LPT_HUB_FOLDER)
			end)
		end
	end
end

ensureLPTFolder()

local function getSavedKey()
	if type(isfile)~="function" then
		return nil
	end

	ensureLPTFolder()

	local ok,result=pcall(function()
		if not isfile(KEY_FILE) then
			return nil
		end

		local data=readfile(KEY_FILE)

		if data and data~="" then
			return tostring(data)
		end

		return nil
	end)

	return ok and result or nil
end

local function saveKey(key)
	if type(writefile)~="function" then
		return
	end

	ensureLPTFolder()

	pcall(function()
		writefile(KEY_FILE,tostring(key))
	end)
end

local oldGui=playerGui:FindFirstChild("LPTKeyUI")

if oldGui then
	oldGui:Destroy()
end

local screenGui=Instance.new("ScreenGui")
screenGui.Name="LPTKeyUI"
screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset=true
screenGui.DisplayOrder=999999
screenGui.Parent=playerGui

local function showNotification(titleText,messageText,notificationType)
    return
end

local keyFrame=Instance.new("Frame")
keyFrame.Name="KeyUI"
keyFrame.Size=UDim2.fromOffset(610,340)
keyFrame.Position=UDim2.new(.5,-305,.5,-170)
keyFrame.BackgroundColor3=Color3.fromRGB(5,5,5)
keyFrame.BackgroundTransparency=.02
keyFrame.BorderSizePixel=0
keyFrame.ClipsDescendants=true
keyFrame.ZIndex=10
keyFrame.Parent=screenGui

local frameCorner=Instance.new("UICorner")
frameCorner.CornerRadius=UDim.new(0,7)
frameCorner.Parent=keyFrame

local frameStroke=Instance.new("UIStroke")
frameStroke.Color=Color3.fromRGB(42,42,46)
frameStroke.Thickness=1
frameStroke.Transparency=.1
frameStroke.Parent=keyFrame

local leftPanel=Instance.new("Frame")
leftPanel.Name="LeftPanel"
leftPanel.Size=UDim2.new(0,357,1,0)
leftPanel.BackgroundTransparency=1
leftPanel.BorderSizePixel=0
leftPanel.ZIndex=10
leftPanel.Parent=keyFrame

local rightPanel=Instance.new("Frame")
rightPanel.Name="RightPanel"
rightPanel.Position=UDim2.fromOffset(358,0)
rightPanel.Size=UDim2.new(1,-358,1,0)
rightPanel.BackgroundTransparency=1
rightPanel.BorderSizePixel=0
rightPanel.ZIndex=10
rightPanel.Parent=keyFrame

local divider=Instance.new("Frame")
divider.Name="Divider"
divider.Position=UDim2.fromOffset(357,29)
divider.Size=UDim2.new(0,1,1,-58)
divider.BackgroundColor3=Color3.fromRGB(43,43,43)
divider.BorderSizePixel=0
divider.ZIndex=11
divider.Parent=keyFrame

local function makeLabel(parent,name,text,size,pos,font,textSize,color)
	local label=Instance.new("TextLabel")
	label.Name=name
	label.Size=size
	label.Position=pos
	label.BackgroundTransparency=1
	label.BorderSizePixel=0
	label.Text=text
	label.TextColor3=color or Color3.fromRGB(240,240,240)
	label.TextSize=textSize or 13
	label.Font=font or Enum.Font.Gotham
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.TextYAlignment=Enum.TextYAlignment.Center
	label.ZIndex=12
	label.Parent=parent
	return label
end

local function makeCorner(object,radius)
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,radius or 6)
	corner.Parent=object
	return corner
end

local logo=Instance.new("ImageLabel")
logo.Name="KeyLogo"
logo.Size=UDim2.fromOffset(52,52)
logo.Position=UDim2.fromOffset(32,16)
logo.BackgroundTransparency=1
logo.BorderSizePixel=0
logo.Image="rbxassetid://86498268964550"
logo.ScaleType=Enum.ScaleType.Fit
logo.ZIndex=12
logo.Parent=leftPanel

local title=makeLabel(leftPanel,"HeaderTitle","LPT Hub",UDim2.fromOffset(210,28),UDim2.fromOffset(108,23),Enum.Font.GothamBold,24,Color3.fromRGB(245,245,245))
local subtitle=makeLabel(leftPanel,"HeaderSubtitle","Key system",UDim2.fromOffset(210,18),UDim2.fromOffset(109,49),Enum.Font.Gotham,12,Color3.fromRGB(105,105,105))

local dragHandle=Instance.new("Frame")
dragHandle.Name="DragHandle"
dragHandle.Size=UDim2.fromOffset(357,86)
dragHandle.Position=UDim2.fromOffset(0,0)
dragHandle.BackgroundTransparency=1
dragHandle.BorderSizePixel=0
dragHandle.Active=true
dragHandle.ZIndex=11
dragHandle.Parent=keyFrame

local dragging=false
local dragStart=nil
local startPosition=nil

local function beginWindowDrag(input)
	if input.UserInputType~=Enum.UserInputType.MouseButton1
		and input.UserInputType~=Enum.UserInputType.Touch then
		return
	end

	dragging=true
	dragStart=input.Position
	startPosition=keyFrame.Position

	local endedConnection
	endedConnection=input.Changed:Connect(function()
		if input.UserInputState==Enum.UserInputState.End then
			dragging=false
			if endedConnection then endedConnection:Disconnect() end
		end
	end)
end

for _,target in ipairs({dragHandle,logo,title,subtitle}) do
	target.InputBegan:Connect(beginWindowDrag)
end

UserInputService.InputChanged:Connect(function(input)
	if not dragging or not dragStart or not startPosition then return end
	if input.UserInputType~=Enum.UserInputType.MouseMovement
		and input.UserInputType~=Enum.UserInputType.Touch then
		return
	end

	local delta=input.Position-dragStart
	keyFrame.Position=UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset+delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset+delta.Y
	)
end)

makeLabel(leftPanel,"LicenseLabel","License key",UDim2.fromOffset(300,18),UDim2.fromOffset(29,98),Enum.Font.Gotham,12,Color3.fromRGB(105,105,105))

local inputBox=Instance.new("Frame")
inputBox.Name="KeyInputBox"
inputBox.Size=UDim2.fromOffset(300,40)
inputBox.Position=UDim2.fromOffset(29,120)
inputBox.BackgroundColor3=Color3.fromRGB(20,20,20)
inputBox.BorderSizePixel=0
inputBox.ZIndex=11
inputBox.Parent=leftPanel
makeCorner(inputBox,6)

local inputStroke=Instance.new("UIStroke")
inputStroke.Color=Color3.fromRGB(45,45,45)
inputStroke.Thickness=1
inputStroke.Transparency=.12
inputStroke.Parent=inputBox

local keyInput=Instance.new("TextBox")
keyInput.Name="LicenseInput"
keyInput.Size=UDim2.new(1,-27,1,0)
keyInput.Position=UDim2.fromOffset(13,0)
keyInput.BackgroundTransparency=1
keyInput.BorderSizePixel=0
keyInput.PlaceholderText="Paste your key here"
keyInput.PlaceholderColor3=Color3.fromRGB(94,94,94)
keyInput.Text=""
keyInput.TextColor3=Color3.fromRGB(245,245,245)
keyInput.TextSize=14
keyInput.Font=Enum.Font.Gotham
keyInput.TextXAlignment=Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus=false
keyInput.ZIndex=12
keyInput.Parent=inputBox

local keyIcon=makeLabel(inputBox,"KeyIcon","⚿",UDim2.fromOffset(17,40),UDim2.fromOffset(8,0),Enum.Font.Gotham,17,Color3.fromRGB(95,95,95))
keyIcon.TextXAlignment=Enum.TextXAlignment.Center
keyInput.Position=UDim2.fromOffset(31,0)
keyInput.Size=UDim2.new(1,-39,1,0)

keyInput.Focused:Connect(function()
	tween(inputStroke,{Color=Color3.fromRGB(100,100,100),Transparency=0},.15)
end)
keyInput.FocusLost:Connect(function()
	tween(inputStroke,{Color=Color3.fromRGB(45,45,45),Transparency=.12},.15)
end)

local getKeyButton=Instance.new("TextButton")
getKeyButton.Name="GetKeyButton"
getKeyButton.Size=UDim2.fromOffset(144,40)
getKeyButton.Position=UDim2.fromOffset(29,177)
getKeyButton.BackgroundColor3=Color3.fromRGB(22,22,22)
getKeyButton.BorderSizePixel=0
getKeyButton.Text="Get a key"
getKeyButton.TextColor3=Color3.fromRGB(242,242,242)
getKeyButton.TextSize=13
getKeyButton.Font=Enum.Font.GothamMedium
getKeyButton.AutoButtonColor=true
getKeyButton.ZIndex=11
getKeyButton.Parent=leftPanel
makeCorner(getKeyButton,6)
local getStroke=Instance.new("UIStroke")
getStroke.Color=Color3.fromRGB(42,42,42)
getStroke.Thickness=1
getStroke.Parent=getKeyButton

local submitButton=Instance.new("TextButton")
submitButton.Name="SubmitButton"
submitButton.Size=UDim2.fromOffset(144,40)
submitButton.Position=UDim2.fromOffset(185,177)
submitButton.BackgroundColor3=Color3.fromRGB(245,245,245)
submitButton.BorderSizePixel=0
submitButton.Text="Submit"
submitButton.TextColor3=Color3.fromRGB(15,15,15)
submitButton.TextSize=13
submitButton.Font=Enum.Font.GothamBold
submitButton.AutoButtonColor=true
submitButton.ZIndex=11
submitButton.Parent=leftPanel
makeCorner(submitButton,6)

local keyStatus=makeLabel(leftPanel,"KeyStatus","",UDim2.fromOffset(300,30),UDim2.fromOffset(29,222),Enum.Font.Gotham,12,COLORS.Danger)
keyStatus.TextWrapped=true
keyStatus.TextYAlignment=Enum.TextYAlignment.Top

local getKeyHint=makeLabel(leftPanel,"GetKeyHint","Need a key? Click Get a key above.",UDim2.fromOffset(300,18),UDim2.fromOffset(29,265),Enum.Font.Gotham,11,Color3.fromRGB(100,170,255))

local savedHint=makeLabel(leftPanel,"SavedHint","Your key is saved for next time",UDim2.fromOffset(300,18),UDim2.fromOffset(29,297),Enum.Font.Gotham,11,Color3.fromRGB(78,78,78))

makeLabel(rightPanel,"DetectedLabel","Detected game",UDim2.fromOffset(188,18),UDim2.fromOffset(28,28),Enum.Font.Gotham,11,Color3.fromRGB(100,100,100))

local gameCard=Instance.new("Frame")
gameCard.Name="DetectedGameCard"
gameCard.Size=UDim2.fromOffset(188,60)
gameCard.Position=UDim2.fromOffset(28,50)
gameCard.BackgroundColor3=Color3.fromRGB(20,20,20)
gameCard.BorderSizePixel=0
gameCard.ZIndex=11
gameCard.Parent=rightPanel
makeCorner(gameCard,6)
local gameCardStroke=Instance.new("UIStroke")
gameCardStroke.Color=Color3.fromRGB(40,40,40)
gameCardStroke.Thickness=1
gameCardStroke.Parent=gameCard

local gameIcon=Instance.new("ImageLabel")
gameIcon.Name="GameIcon"
gameIcon.Size=UDim2.fromOffset(39,39)
gameIcon.Position=UDim2.fromOffset(10,10)
gameIcon.BackgroundColor3=Color3.fromRGB(34,34,34)
gameIcon.BorderSizePixel=0
gameIcon.Image="rbxthumb://type=GameIcon&id="..tostring(game.GameId or game.PlaceId).."&w=150&h=150"
gameIcon.ScaleType=Enum.ScaleType.Crop
gameIcon.ZIndex=12
gameIcon.Parent=gameCard
makeCorner(gameIcon,5)

local detectedGameName=makeLabel(gameCard,"GameName",tostring(game.Name or "Current game"),UDim2.new(1,-58,0,30),UDim2.fromOffset(57,7),Enum.Font.GothamMedium,12,Color3.fromRGB(238,238,238))
detectedGameName.TextWrapped=true
detectedGameName.TextTruncate=Enum.TextTruncate.AtEnd

local detectedGameSub=makeLabel(gameCard,"GameSubtitle","Universal script",UDim2.new(1,-58,0,18),UDim2.fromOffset(57,35),Enum.Font.Gotham,10,Color3.fromRGB(90,90,90))
detectedGameSub.TextTruncate=Enum.TextTruncate.AtEnd

local executorLabel=makeLabel(rightPanel,"ExecutorLabel","Executor",UDim2.fromOffset(85,18),UDim2.fromOffset(28,120),Enum.Font.Gotham,11,Color3.fromRGB(95,95,95))
local executorValue=makeLabel(rightPanel,"ExecutorValue","Detecting...",UDim2.fromOffset(100,18),UDim2.fromOffset(116,120),Enum.Font.Gotham,11,Color3.fromRGB(235,235,235))
executorValue.TextXAlignment=Enum.TextXAlignment.Right
executorValue.TextTruncate=Enum.TextTruncate.AtEnd

local function detectExecutorName()
	local env=_G
	if type(getgenv)=="function" then
		local ok,result=pcall(getgenv)
		if ok and type(result)=="table" then env=result end
	end

	local detectorNames={"identifyexecutor","getexecutorname","get_executor_name"}
	for _,detectorName in ipairs(detectorNames) do
		local detector=env[detectorName] or _G[detectorName]
		if type(detector)=="function" then
			local ok,name=pcall(detector)
			if ok and type(name)=="string" and name~="" then
				return name
			end
		end
	end

	local markers={
		{"KRNL_LOADED","KRNL"},
		{"syn","Synapse X"},
		{"fluxus","Fluxus"},
		{"Fluxus","Fluxus"},
		{"DELTA_LOADED","Delta"},
		{"delta","Delta"},
		{"Electron","Electron"},
		{"electron","Electron"},
		{"SIRHURT_LOADED","SirHurt"},
	}
	for _,marker in ipairs(markers) do
		local value=env[marker[1]] or _G[marker[1]]
		if value~=nil and value~=false then
			return marker[2]
		end
	end
	if type(env.is_sirhurt_closure)=="function" or type(_G.is_sirhurt_closure)=="function" then
		return "SirHurt"
	end
	return "Unknown"
end

executorValue.Text=detectExecutorName()

local statusTitle=makeLabel(rightPanel,"StatusTitle","Status",UDim2.fromOffset(85,18),UDim2.fromOffset(28,142),Enum.Font.Gotham,11,Color3.fromRGB(95,95,95))
local statusValue=makeLabel(rightPanel,"StatusValue","Key required",UDim2.fromOffset(100,18),UDim2.fromOffset(116,142),Enum.Font.Gotham,11,Color3.fromRGB(255,200,65))
statusValue.TextXAlignment=Enum.TextXAlignment.Right

local statusDivider=Instance.new("Frame")
statusDivider.Position=UDim2.fromOffset(28,171)
statusDivider.Size=UDim2.fromOffset(188,1)
statusDivider.BackgroundColor3=Color3.fromRGB(40,40,40)
statusDivider.BorderSizePixel=0
statusDivider.ZIndex=11
statusDivider.Parent=rightPanel

local discordButton=Instance.new("TextButton")
discordButton.Name="DiscordCard"
discordButton.Size=UDim2.fromOffset(188,48)
discordButton.Position=UDim2.fromOffset(28,190)
discordButton.BackgroundColor3=Color3.fromRGB(20,20,20)
discordButton.BorderSizePixel=0
discordButton.Text=""
discordButton.AutoButtonColor=true
discordButton.ZIndex=11
discordButton.Parent=rightPanel
makeCorner(discordButton,6)
local discordStroke=Instance.new("UIStroke")
discordStroke.Color=Color3.fromRGB(40,40,40)
discordStroke.Thickness=1
discordStroke.Parent=discordButton
makeLabel(discordButton,"DiscordIcon","◉",UDim2.fromOffset(26,30),UDim2.fromOffset(10,8),Enum.Font.GothamBold,19,Color3.fromRGB(130,145,255))
makeLabel(discordButton,"DiscordTitle","Discord",UDim2.fromOffset(130,16),UDim2.fromOffset(43,8),Enum.Font.GothamMedium,12,Color3.fromRGB(240,240,240))
makeLabel(discordButton,"DiscordSub","discord.gg/gyZ27Hw9qu",UDim2.fromOffset(135,15),UDim2.fromOffset(43,24),Enum.Font.Gotham,11,Color3.fromRGB(100,170,255))

local websiteButton=Instance.new("TextButton")
websiteButton.Name="WebsiteCard"
websiteButton.Size=UDim2.fromOffset(188,48)
websiteButton.Position=UDim2.fromOffset(28,246)
websiteButton.BackgroundColor3=Color3.fromRGB(20,20,20)
websiteButton.BorderSizePixel=0
websiteButton.Text=""
websiteButton.AutoButtonColor=true
websiteButton.ZIndex=11
websiteButton.Parent=rightPanel
makeCorner(websiteButton,6)
local websiteStroke=Instance.new("UIStroke")
websiteStroke.Color=Color3.fromRGB(40,40,40)
websiteStroke.Thickness=1
websiteStroke.Parent=websiteButton
makeLabel(websiteButton,"WebsiteIcon","◎",UDim2.fromOffset(26,30),UDim2.fromOffset(10,8),Enum.Font.Gotham,19,Color3.fromRGB(115,145,255))
makeLabel(websiteButton,"WebsiteTitle","Website",UDim2.fromOffset(130,16),UDim2.fromOffset(43,8),Enum.Font.GothamMedium,12,Color3.fromRGB(240,240,240))
makeLabel(websiteButton,"WebsiteSub","lyphucthien.vercel.app",UDim2.fromOffset(135,15),UDim2.fromOffset(43,24),Enum.Font.Gotham,11,Color3.fromRGB(100,170,255))

local function updateDetectedGame(name,subtitleText,iconId)
	detectedGameName.Text=tostring(name or "Unknown game")
	detectedGameSub.Text=tostring(subtitleText or "Universal script")
	local id=tonumber(iconId) or tonumber(game.GameId) or tonumber(game.PlaceId)
	if id then
		gameIcon.Image="rbxthumb://type=GameIcon&id="..tostring(id).."&w=150&h=150"
	end
end

local function fetchRobloxGameName()
	local placeId = tonumber(game.PlaceId)
	local universeId = tonumber(game.GameId)

	local function validName(name)
		return type(name) == "string"
			and name ~= "" and not string.find(string.upper(name),"TITLE UNAVAILABLE",1,true)
	end

	for _, config in pairs(GAME_HO_TRO) do
		for _, id in ipairs(config.PlaceId or {}) do
			if tonumber(id) == placeId then
				return config.Name
			end
		end

		for _, id in ipairs(config.UniverseId or {}) do
			if tonumber(id) == universeId then
				return config.Name
			end
		end
	end

	if universeId and universeId > 0 then
		local ok, response = pcall(function()
			return game:HttpGet("https://games.roblox.com/v1/games?universeIds=".. universeId)
		end)

		if ok and type(response) == "string" then
			local decoded, data = pcall(function()
				return HttpService:JSONDecode(response)
			end)

			if decoded and type(data.data) == "table" then
				local info = data.data[1]

				if info and validName(info.name) then
					return info.name
				end
			end
		end
	end

	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(
			placeId,
			Enum.InfoType.Asset
		)
	end)

	if ok and type(info) == "table" and validName(info.Name) then
		return info.Name
	end

	return "Place ID " .. tostring(placeId or "Unknown")
end

local initialGameConfig=nil
for configKey,config in pairs(GAME_HO_TRO) do
	local matched=false
	for _,id in ipairs(config.PlaceId or {}) do
		if tonumber(id)==tonumber(game.PlaceId) then matched=true break end
	end
	if not matched then
		for _,id in ipairs(config.UniverseId or {}) do
			if tonumber(id)==tonumber(game.GameId) then matched=true break end
		end
	end
	if matched then
		initialGameConfig=config
		break
	end
end
State.GameSupported=initialGameConfig~=nil
if initialGameConfig then
	updateDetectedGame("Detecting game...","Supported game",(type(initialGameConfig.UniverseId)=="table" and initialGameConfig.UniverseId[1]) or game.GameId or game.PlaceId)
else
	updateDetectedGame("Detecting game...","Universal mode",game.GameId or game.PlaceId)
end

task.spawn(function()
	local actualName=fetchRobloxGameName()
	State.RobloxGameName=actualName
	if detectedGameName and detectedGameName.Parent then
		detectedGameName.Text=actualName
	end
end)

local function updateKeyStatus(text,color)
	local value=tostring(text or "")
	local lower=string.lower(value)
	if string.find(lower,"xác thực") or string.find(lower,"nhận diện") or string.find(lower,"đang tải") or string.find(lower,"loading") then
		statusValue.Text="Checking..."
		statusValue.TextColor3=Color3.fromRGB(130,180,255)
	elseif string.find(lower,"hợp lệ") or string.find(lower,"đã tải") or string.find(lower,"valid") then
		statusValue.Text="Key valid"
		statusValue.TextColor3=Color3.fromRGB(90,220,145)
	elseif string.find(lower,"không đúng") or string.find(lower,"không thể") or string.find(lower,"lỗi") or string.find(lower,"error") then
		statusValue.Text="Invalid / error"
		statusValue.TextColor3=Color3.fromRGB(255,100,100)
	elseif string.find(lower,"vui lòng") or string.find(lower,"chưa có key") or string.find(lower,"required") then
		statusValue.Text="Key required"
		statusValue.TextColor3=Color3.fromRGB(255,200,65)
	end
end

local function setStatus(text,color)
	keyStatus.Text=tostring(text or "")
	keyStatus.TextColor3=color or Color3.fromRGB(230,230,230)
	updateKeyStatus(text,color)
end

getKeyButton.MouseButton1Click:Connect(function()
    if type(setclipboard) ~= "function" then
        getKeyButton.Text = "Copy Failed"
        task.delay(1.2, function()
            if getKeyButton.Parent then
                getKeyButton.Text = "Get a key"
            end
        end)
        return
    end

    local ok = pcall(function()
        setclipboard(GET_KEY_LINK)
    end)

    getKeyButton.Text = ok and "Link Copied..." or "Copy Failed"

    task.delay(1.2, function()
        if getKeyButton.Parent then
            getKeyButton.Text = "Get a key"
        end
    end)
end)

local DISCORD_LINK = "https://discord.gg/gyZ27Hw9qu"
local WEBSITE_LINK = "https://lyphucthien.vercel.app"

local function copyButtonLink(button, link, titleText, subText)
    local titleLabel = button:FindFirstChild(
        button == discordButton and "DiscordTitle" or "WebsiteTitle"
    )
    local subLabel = button:FindFirstChild(
        button == discordButton and "DiscordSub" or "WebsiteSub"
    )

    local ok = false

    if type(setclipboard) == "function" then
        ok = pcall(function()
            setclipboard(link)
        end)
    end

    if titleLabel then
        titleLabel.Text = ok and "Link Copied..." or "Copy Failed"
    end

    if subLabel then
        subLabel.Text = ok and "Copied to clipboard" or "Clipboard unavailable"
    end

    task.delay(1.2, function()
        if button.Parent then
            if titleLabel then titleLabel.Text = titleText end
            if subLabel then subLabel.Text = subText end
        end
    end)
end

discordButton.MouseButton1Click:Connect(function()
    copyButtonLink(discordButton,DISCORD_LINK,"Discord","discord.gg/gyZ27Hw9qu")
end)

websiteButton.MouseButton1Click:Connect(function()
    copyButtonLink(websiteButton,WEBSITE_LINK,"Website","lyphucthien.vercel.app")
end)

--============================================================
-- GAME DETECTION
--============================================================

local function getUniverseId(placeId)
	if not placeId then return nil end

	local ok,result=pcall(function()
		local url="https://apis.roblox.com/universes/v1/places/"..tostring(placeId).."/universe"

		local response=game:HttpGet(url)

		if not response or response=="" then
			error("Empty response")
		end

		local data=HttpService:JSONDecode(response)

		if not data then
			error("Invalid JSON")
		end

		return tonumber(data.universeId)
	end)

	if ok and result then
		return result
	end

	return nil
end

local function containsId(list,id)
	if not id or type(list)~="table" then return false end

	local target=tonumber(id)

	for _,value in ipairs(list) do
		if tonumber(value)==target then
			return true
		end
	end

	return false
end

local function findGameConfig(placeId,universeId)
	for configKey,config in pairs(GAME_HO_TRO) do
		if type(config)~="table" then
			continue
		end

		if containsId(config.PlaceId,placeId) then
			return config,"PlaceId",configKey
		end

		if containsId(config.UniverseId,universeId) then
			return config,"UniverseId",configKey
		end
	end

	return nil,nil,nil
end

local function resolveGame()
	State.PlaceId=tonumber(game.PlaceId)

	if not State.PlaceId or State.PlaceId<=0 then
		return false,"Không lấy được PlaceId."
	end

	setStatus("PlaceId: "..tostring(State.PlaceId).." • Đang nhận diện...",COLORS.Info)
	showNotification("Detecting Game","Đang lấy PlaceId và UniverseId...","info")

	task.wait(.25)

	State.UniverseId=getUniverseId(State.PlaceId) or tonumber(game.GameId)

	if State.UniverseId then
		setStatus("UniverseId: "..tostring(State.UniverseId).." • Đang tìm game...",COLORS.Info)
	else
		setStatus("Không lấy được UniverseId • Kiểm tra PlaceId...",COLORS.Warning)
	end

	task.wait(.2)

	local gameConfig,matchType,configKey=
		findGameConfig(
			State.PlaceId,
			State.UniverseId
		)

	if not gameConfig then
		State.GameSupported=false
		State.GameConfig=nil
		State.MainUI=nil
		updateDetectedGame(State.RobloxGameName or ("Place ID "..tostring(game.PlaceId)),"Universal mode",game.GameId or game.PlaceId)
		return false,"Game không được hỗ trợ."
	end

	if type(gameConfig)~="table" then
		return false,"Config game không hợp lệ."
	end

	local gameName=
		gameConfig.Name
		or gameConfig.name
		or configKey
		or "Unknown Game"

	local mainUI=
		gameConfig.MainUI
		or gameConfig.mainUI
		or gameConfig.URL
		or gameConfig.url

	if type(mainUI)~="string" or mainUI=="" then
		return false,"Game đã nhận diện nhưng chưa có MainUI."
	end

	State.GameName=tostring(gameName)
	State.GameConfig=gameConfig
	State.MainUI=mainUI
	State.GameSupported=true
	local iconId=(type(gameConfig.UniverseId)=="table" and gameConfig.UniverseId[1]) or game.GameId or State.PlaceId
	updateDetectedGame(State.RobloxGameName or State.GameName,"Supported game",iconId)

	setStatus("Đã nhận diện: "..State.GameName,COLORS.Success)
	showNotification("Game Detected",State.GameName.." • "..tostring(matchType),"success")

	return true
end

--============================================================
-- DATA LOADED
--============================================================

local function waitForGameData(config)
	if type(config)~="table"
		or config.WaitForDataLoaded~=true then
		return true
	end

	setStatus("Đang chờ dữ liệu game...",COLORS.Info)

	local dataLoaded=player:FindFirstChild("DataLoaded")

	if not dataLoaded then
		local ok,result=pcall(function()
			return player:WaitForChild("DataLoaded",30)
		end)

		if not ok or not result then
			return false
		end

		dataLoaded=result
	end

	if dataLoaded:IsA("BoolValue") then
		local timeout=os.clock()+30

		while not dataLoaded.Value and os.clock()<timeout do
			task.wait(.2)
		end

		return dataLoaded.Value
	end

	return true
end

--============================================================
-- EXECUTE REMOTE SCRIPT
--============================================================

local function executeScript(url,scriptName)
	if type(url)~="string" or url=="" then
		error(tostring(scriptName).." URL không hợp lệ.")
	end

	local response,requestError=pcall(function()
		return game:HttpGet(url)
	end)

	if not response then
		error(tostring(scriptName).." HttpGet lỗi: "..tostring(requestError))
	end

	if type(requestError)~="string" or requestError=="" then
		error(tostring(scriptName).." trả về dữ liệu rỗng.")
	end

	local code=requestError

	if code:match("^%s*<!DOCTYPE")
		or code:match("^%s*<html")
		or code:match("^%s*<HTML") then
		error(tostring(scriptName).." URL không trả về Luau. Có thể URL đang trả HTML.")
	end

	local chunk,compileError=loadstring(code)

	if type(chunk)~="function" then
		error(tostring(scriptName).." compile lỗi:\n"..tostring(compileError))
	end

	local ok,runError=pcall(chunk)

	if not ok then
		error(tostring(scriptName).." runtime lỗi:\n"..tostring(runError))
	end

	return true
end

--============================================================
-- LOAD MAIN UI
--============================================================

local function loadMainUI()
	if State.Loading then return end

	State.Loading=true
	keyFrame.Visible=true

	setStatus("KEY hợp lệ • Đang nhận diện game...",COLORS.Success)

	task.wait(.25)

	local resolved,resolveError=resolveGame()

	if not resolved then
		if resolveError=="Game không được hỗ trợ." then
			setStatus("Universal Mode • Đang tải...",COLORS.Warning)
			showNotification("Universal Mode","Game chưa có script riêng. Đang khởi chạy Universal...","warning")

			task.wait(.5)

			local ok,result=pcall(function()
				return executeScript(
					UNIVERSAL_SCRIPT,
					"Universal Script"
				)
			end)

			if not ok then
				keyFrame.Visible=true

				setStatus("Không thể tải Universal.",COLORS.Danger)
				showNotification("Universal Error",tostring(result),"error")

				State.Loading=false
				return
			end

			setStatus("Universal đã được tải.",COLORS.Success)
			showNotification("Universal Mode","Universal Script đã được tải thành công.","success")

			task.wait(.25)

			keyFrame.Visible=false
			State.Loading=false
			return
		end

		keyFrame.Visible=true

		setStatus(tostring(resolveError),COLORS.Danger)
		showNotification("Game Detection Error",tostring(resolveError),"error")

		State.Loading=false
		return
	end

	task.wait(.4)

	if not waitForGameData(State.GameConfig) then
		keyFrame.Visible=true

		setStatus("Game chưa sẵn sàng.",COLORS.Danger)
		showNotification("Game Loading","DataLoaded chưa hoàn tất.","error")

		State.Loading=false
		return
	end

	setStatus("Đang tải MainUI...",COLORS.Info)
	showNotification("Loading UI","Đang tải "..State.GameName.."...","info")

	task.wait(.25)

	local ok,result=pcall(function()
		return executeScript(
			State.MainUI,
			"MainUI"
		)
	end)

	if not ok then
		keyFrame.Visible=true

		setStatus("Không thể tải MainUI.",COLORS.Danger)
		showNotification("MainUI Error",tostring(result),"error")

		State.Loading=false
		return
	end

	setStatus("Đã tải "..State.GameName,COLORS.Success)
	showNotification("LPT HUB","Đã tải UI: "..State.GameName,"success")

	task.wait(.25)

	keyFrame.Visible=false
	State.Loading=false
end

--============================================================
-- KEY VERIFICATION
--============================================================

local KEY_API_URL="https://lyphucthien.vercel.app/api/get-key"

function checkKey(key)
	if type(key)~="string" or key=="" then
		return false
	end

	local ok,response=pcall(function()
		return game:HttpGet(KEY_API_URL.."?type=lpthub&key="..HttpService:UrlEncode(key))
	end)

	if not ok or not response then
		showNotification("Server Error","Không kết nối được server xác thực.","error")
		return false
	end

	local decodeOk,data=pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not decodeOk or type(data)~="table" then
		return false
	end

	return data.valid==true
end

--============================================================
-- SUBMIT KEY
--============================================================

local function attemptSubmit()
	if State.Submitting or State.Loading then
		return
	end

	State.Submitting=true

	local key=tostring(keyInput.Text or "")
	key=key:gsub("^%s+",""):gsub("%s+$","")

	if key=="" then
		setStatus("Vui lòng nhập KEY.",COLORS.Danger)

		State.Submitting=false
		return
	end

	setStatus("Đang xác thực KEY...",COLORS.Info)

	task.wait(.2)

	if not checkKey(key) then
		setStatus("KEY không đúng, thử lại.",COLORS.Danger)
		showNotification("Invalid Key","KEY không hợp lệ.","error")

		tween(inputStroke,{Color=COLORS.Danger,Transparency=0},.1)

		task.wait(.15)

		tween(inputStroke,{Color=COLORS.Border,Transparency=.15},.2)

		State.Submitting=false
		return
	end

	State.KeyValid=true
	saveKey(key)

	showNotification("Key Valid!","KEY hợp lệ. Đang nhận diện game...","success")
	setStatus("KEY hợp lệ! Đang nhận diện game...",COLORS.Success)

	State.Submitting=false
	loadMainUI()
end

submitButton.MouseButton1Click:Connect(attemptSubmit)

keyInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		attemptSubmit()
	end
end)

task.spawn(function()
	local savedKey=getSavedKey()

	if not savedKey or savedKey=="" then
		return
	end

	task.wait(.4)

	keyInput.Text=savedKey

	setStatus("Đang xác thực KEY đã lưu...",COLORS.Info)
	task.wait(.4)

	attemptSubmit()
end)
