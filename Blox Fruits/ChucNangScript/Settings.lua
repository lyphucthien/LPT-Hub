local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local CoreGui=game:GetService("CoreGui")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local SettingsModule={}

--========================================================
-- STATE
--========================================================

local Settings={
	WhiteScreen=false,
	BlackScreen=false,
	RemoveNotifications=false,
	AutoRejoin=false,
	AutoLoadScript=false,
	BoostFPS=false,
	Webhook=false
}

local Connections={}
local CreatedObjects={}

--========================================================
-- CONNECTION HELPERS
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

--========================================================
-- SCREEN OVERLAY
--========================================================

local screenGui=nil
local overlay=nil

local function getScreenGui()
	if screenGui and screenGui.Parent then
		return screenGui
	end

	screenGui=Instance.new("ScreenGui")
	screenGui.Name="LPT_Settings_Screen"
	screenGui.ResetOnSpawn=false
	screenGui.IgnoreGuiInset=true
	screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Global
	screenGui.DisplayOrder=999998
	screenGui.Parent=playerGui

	table.insert(CreatedObjects,screenGui)

	return screenGui
end

local function updateScreen()
	local gui=getScreenGui()

	if not overlay or not overlay.Parent then
		overlay=Instance.new("Frame")
		overlay.Name="ScreenOverlay"
		overlay.Size=UDim2.fromScale(1,1)
		overlay.Position=UDim2.fromScale(0,0)
		overlay.BorderSizePixel=0
		overlay.ZIndex=999999
		overlay.Parent=gui

		table.insert(CreatedObjects,overlay)
	end

	if Settings.WhiteScreen then
		overlay.BackgroundColor3=Color3.new(1,1,1)
		overlay.BackgroundTransparency=0
		overlay.Visible=true

	elseif Settings.BlackScreen then
		overlay.BackgroundColor3=Color3.new(0,0,0)
		overlay.BackgroundTransparency=0
		overlay.Visible=true

	else
		overlay.Visible=false
	end
end

--========================================================
-- WHITE SCREEN
--========================================================

local function setWhiteScreen(enabled)
	Settings.WhiteScreen=enabled==true

	if Settings.WhiteScreen then
		Settings.BlackScreen=false
	end

	updateScreen()
end

--========================================================
-- BLACK SCREEN
--========================================================

local function setBlackScreen(enabled)
	Settings.BlackScreen=enabled==true

	if Settings.BlackScreen then
		Settings.WhiteScreen=false
	end

	updateScreen()
end

--========================================================
-- REMOVE NOTIFICATIONS
--========================================================

local notificationConnection=nil
local notificationNames={
	"Notifications",
	"Notification",
	"TopNotifications",
	"NotificationGui",
	"RobloxNotification",
	"CoreNotifications"
}

local function hideNotifications(root)
	if not root then
		return
	end

	for _,name in ipairs(notificationNames) do
		local object=root:FindFirstChild(name,true)

		if object and object:IsA("GuiObject") then
			object.Visible=false
		end
	end
end

local function setRemoveNotifications(enabled)
	Settings.RemoveNotifications=enabled==true

	if notificationConnection then
		disconnect(notificationConnection)
		notificationConnection=nil
	end

	if not Settings.RemoveNotifications then
		return
	end

	pcall(function()
		hideNotifications(playerGui)
		hideNotifications(CoreGui)
	end)

	notificationConnection=playerGui.DescendantAdded:Connect(function(object)
		if not Settings.RemoveNotifications then
			return
		end

		if object:IsA("GuiObject") then
			for _,name in ipairs(notificationNames) do
				if string.lower(object.Name)==string.lower(name) then
					object.Visible=false
					break
				end
			end
		end
	end)

	table.insert(Connections,notificationConnection)
end

--========================================================
-- BOOST FPS
--========================================================

local originalSettings={
	GlobalShadows=Lighting.GlobalShadows,
	FogEnd=Lighting.FogEnd,
	FogStart=Lighting.FogStart,
	EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale
}

local fpsConnection=nil

local function optimizeLighting()
	pcall(function()
		Lighting.GlobalShadows=false
		Lighting.EnvironmentDiffuseScale=0
		Lighting.EnvironmentSpecularScale=0

		if Lighting.FogEnd>100000 then
			Lighting.FogEnd=100000
		end
	end)
end

local function setBoostFPS(enabled)
	Settings.BoostFPS=enabled==true

	if fpsConnection then
		disconnect(fpsConnection)
		fpsConnection=nil
	end

	if not Settings.BoostFPS then
		pcall(function()
			Lighting.GlobalShadows=originalSettings.GlobalShadows
			Lighting.FogEnd=originalSettings.FogEnd
			Lighting.FogStart=originalSettings.FogStart
			Lighting.EnvironmentDiffuseScale=
				originalSettings.EnvironmentDiffuseScale
			Lighting.EnvironmentSpecularScale=
				originalSettings.EnvironmentSpecularScale
		end)

		return
	end

	optimizeLighting()

	fpsConnection=RunService.RenderStepped:Connect(function()
		if Settings.BoostFPS then
			optimizeLighting()
		end
	end)

	table.insert(Connections,fpsConnection)
end

--========================================================
-- AUTO REJOIN
--========================================================

local function setAutoRejoin(enabled)
	Settings.AutoRejoin=enabled==true
end

--========================================================
-- AUTO LOAD SCRIPT
--========================================================

local function setAutoLoadScript(enabled)
	Settings.AutoLoadScript=enabled==true
end

--========================================================
-- WEBHOOK
--========================================================

local function setWebhook(enabled)
	Settings.Webhook=enabled==true
end

--========================================================
-- PUBLIC SET
--========================================================

function SettingsModule:Set(name,enabled)

	if name=="WhiteScreen" then
		setWhiteScreen(enabled)
		return

	elseif name=="BlackScreen" then
		setBlackScreen(enabled)
		return

	elseif name=="RemoveNotifications" then
		setRemoveNotifications(enabled)
		return

	elseif name=="AutoRejoin" then
		setAutoRejoin(enabled)
		return

	elseif name=="AutoLoadScript" then
		setAutoLoadScript(enabled)
		return

	elseif name=="BoostFPS" then
		setBoostFPS(enabled)
		return

	elseif name=="Webhook" then
		setWebhook(enabled)
		return
	end

	warn("[LPT Settings] Unknown setting:",name)
end

--========================================================
-- PUBLIC GET
--========================================================

function SettingsModule:Get(name)

	if Settings[name]~=nil then
		return Settings[name]
	end

	return false
end

--========================================================
-- GET ALL
--========================================================

function SettingsModule:GetAll()

	local result={}

	for name,value in pairs(Settings) do
		result[name]=value
	end

	return result
end

--========================================================
-- DESTROY
--========================================================

function SettingsModule:Destroy()

	Settings.WhiteScreen=false
	Settings.BlackScreen=false
	Settings.RemoveNotifications=false
	Settings.AutoRejoin=false
	Settings.AutoLoadScript=false
	Settings.BoostFPS=false
	Settings.Webhook=false

	disconnectAll()

	if notificationConnection then
		disconnect(notificationConnection)
		notificationConnection=nil
	end

	if fpsConnection then
		disconnect(fpsConnection)
		fpsConnection=nil
	end

	pcall(function()
		Lighting.GlobalShadows=originalSettings.GlobalShadows
		Lighting.FogEnd=originalSettings.FogEnd
		Lighting.FogStart=originalSettings.FogStart
		Lighting.EnvironmentDiffuseScale=
			originalSettings.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale=
			originalSettings.EnvironmentSpecularScale
	end)

	destroyCreatedObjects()

	screenGui=nil
	overlay=nil
end

return SettingsModule