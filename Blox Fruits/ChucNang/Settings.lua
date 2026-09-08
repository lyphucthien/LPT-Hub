local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local CoreGui=game:GetService("CoreGui")
local HttpService=game:GetService("HttpService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local SettingsModule={}

--========================================================
-- SETTINGS
--========================================================

local Settings={
	WhiteScreen=false,
	BlackScreen=false,
	RemoveNotifications=false,
	AutoLoadScript=false,
	BoostFPS=false,

	-- WEBHOOK
	WebhookURL="",
	WebhookPing="",
	WebhookPingEnabled=false,

	WebhookNotiProfile=false,
	WebhookStoreFruit=false,
	WebhookFindPrehistoricIsland=false,
	WebhookFindLeviathan=false,
	WebhookDestroyIDK=false,
	WebhookFindMirage=false,

	-- Rarity tối thiểu
	WebhookRarity="Common"
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

local function safeString(value,default)
	if value==nil then
		return default or ""
	end

	return tostring(value)
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

		if not object:IsA("GuiObject") then
			return
		end

		for _,name in ipairs(notificationNames) do

			if string.lower(object.Name)==string.lower(name) then
				object.Visible=false
				break
			end
		end
	end)

	table.insert(
		Connections,
		notificationConnection
	)
end

--========================================================
-- BOOST FPS
--========================================================

local originalLighting={
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

local function restoreLighting()

	pcall(function()

		Lighting.GlobalShadows=
			originalLighting.GlobalShadows

		Lighting.FogEnd=
			originalLighting.FogEnd

		Lighting.FogStart=
			originalLighting.FogStart

		Lighting.EnvironmentDiffuseScale=
			originalLighting.EnvironmentDiffuseScale

		Lighting.EnvironmentSpecularScale=
			originalLighting.EnvironmentSpecularScale

	end)
end

local function setBoostFPS(enabled)

	Settings.BoostFPS=enabled==true

	if fpsConnection then
		disconnect(fpsConnection)
		fpsConnection=nil
	end

	if not Settings.BoostFPS then
		restoreLighting()
		return
	end

	optimizeLighting()

	fpsConnection=RunService.RenderStepped:Connect(function()

		if Settings.BoostFPS then
			optimizeLighting()
		end

	end)

	table.insert(
		Connections,
		fpsConnection
	)
end

--========================================================
-- AUTO LOAD SCRIPT
--========================================================

local AutoLoadCallback=nil

local function setAutoLoadScript(enabled)
	Settings.AutoLoadScript=enabled==true
end

function SettingsModule:RegisterAutoLoad(callback)
	if type(callback)=="function" then
		AutoLoadCallback=callback
	end
end

function SettingsModule:RunAutoLoad()

	if not Settings.AutoLoadScript then
		return false
	end

	if type(AutoLoadCallback)~="function" then
		return false
	end

	local success,result=pcall(AutoLoadCallback)

	if not success then
		warn("[LPT Settings] Auto Load failed:",result)
		return false
	end

	return true
end

--========================================================
-- WEBHOOK REQUEST
--========================================================

local function getRequestFunction()

	if type(syn)=="table" and type(syn.request)=="function" then
		return syn.request
	end

	if type(request)=="function" then
		return request
	end

	if type(http_request)=="function" then
		return http_request
	end

	if type(http)=="table" and type(http.request)=="function" then
		return http.request
	end

	return nil
end

local function sendHttpRequest(url,body)

	local requestFunction=getRequestFunction()

	if not requestFunction then
		return false,"Request function not available"
	end

	local success,response=pcall(function()
		return requestFunction({
			Url=url,
			Method="POST",
			Headers={
				["Content-Type"]="application/json"
			},
			Body=body
		})
	end)

	if not success then
		return false,response
	end

	if type(response)=="table" then

		local status=response.StatusCode

		if status then
			if status>=200 and status<300 then
				return true,response
			end

			return false,"HTTP "..tostring(status)
		end
	end

	return true,response
end

--========================================================
-- WEBHOOK PING
--========================================================

local function getPingData()

	if not Settings.WebhookPingEnabled then
		return nil,nil
	end

	local ping=safeString(Settings.WebhookPing)

	if ping=="" then
		return nil,nil
	end

	local lower=string.lower(ping)

	if lower=="everyone"
		or lower=="@everyone" then

		return "@everyone",{
			parse={"everyone"}
		}
	end

	local id=ping:match("(%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d)$")

	if id then

		return "<@"..id..">",{
			users={id}
		}
	end

	local mentionId=ping:match("<@!?([0-9]+)>")

	if mentionId then

		return "<@"..mentionId..">",{
			users={mentionId}
		}
	end

	return ping,nil
end

--========================================================
-- SEND WEBHOOK
--========================================================

function SettingsModule:SendWebhook(title,description,fields)

	if not Settings.WebhookURL
		or Settings.WebhookURL=="" then

		return false,"Webhook URL empty"
	end

	local ping,allowedMentions=getPingData()

	local embed={
		title=safeString(title,"LPT Hub"),
		description=safeString(description,""),
		color=5793266,
		fields={},
		footer={
			text="LPT Hub • "..player.Name
		},
		timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	if type(fields)=="table" then
		for _,field in ipairs(fields) do
			if type(field)=="table" then
				table.insert(embed.fields,{
					name=safeString(field.name,"Info"),
					value=safeString(field.value,"N/A"),
					inline=field.inline==true
				})
			end
		end
	end

	local payload={
		username="LPT Hub",
		embeds={embed}
	}

	if ping then
		payload.content=ping
	end

	if allowedMentions then
		payload.allowed_mentions=allowedMentions
	end

	local success,json=pcall(function()
		return HttpService:JSONEncode(payload)
	end)

	if not success then
		return false,json
	end

	return sendHttpRequest(Settings.WebhookURL,json)
end

--========================================================
-- RARITY
--========================================================

local rarityPower={
	Common=1,
	Uncommon=2,
	Rare=3,
	Legendary=4,
	Mythical=5
}

function SettingsModule:IsRarityAllowed(rarity)

	rarity=safeString(rarity,"Common")

	local selected=Settings.WebhookRarity or "Common"

	local fruitPower=rarityPower[rarity] or 1
	local selectedPower=rarityPower[selected] or 1

	return fruitPower>=selectedPower
end

function SettingsModule:SetRarity(rarity)

	rarity=safeString(rarity,"Common")

	if rarityPower[rarity] then
		Settings.WebhookRarity=rarity
		return true
	end

	return false
end

function SettingsModule:GetRarity()
	return Settings.WebhookRarity
end

--========================================================
-- PROFILE
--========================================================

function SettingsModule:NotifyProfile(data)

	if not Settings.WebhookNotiProfile then
		return false
	end

	data=data or {}

	local name=safeString(data.Name,player.Name)
	local level=safeString(data.Level,"Unknown")
	local race=safeString(data.Race,"Unknown")
	local bounty=safeString(data.Bounty,"Unknown")
	local money=safeString(data.Money,"Unknown")

	return self:SendWebhook(
		"👤 Profile",
		"Profile information detected.",
		{
			{
				name="Player",
				value=name,
				inline=true
			},
			{
				name="Level",
				value=level,
				inline=true
			},
			{
				name="Race",
				value=race,
				inline=true
			},
			{
				name="Bounty",
				value=bounty,
				inline=true
			},
			{
				name="Money",
				value=money,
				inline=true
			}
		}
	)
end

--========================================================
-- STORE FRUIT
--========================================================

function SettingsModule:NotifyStoreFruit(data)

	if not Settings.WebhookStoreFruit then
		return false
	end

	data=data or {}

	local fruitName=safeString(data.FruitName,data.Name)
	local rarity=safeString(data.Rarity,"Common")
	local location=safeString(data.Location,"Unknown")

	if fruitName=="" then
		fruitName="Unknown Fruit"
	end

	if not self:IsRarityAllowed(rarity) then
		return false,"Rarity filtered"
	end

	return self:SendWebhook(
		"🍎 Fruit Stored",
		"A fruit matching your webhook filter was stored.",
		{
			{
				name="Fruit",
				value=fruitName,
				inline=true
			},
			{
				name="Rarity",
				value=rarity,
				inline=true
			},
			{
				name="Location",
				value=location,
				inline=true
			}
		}
	)
end

--========================================================
-- PREHISTORIC ISLAND
--========================================================

function SettingsModule:NotifyPrehistoricIsland(data)

	if not Settings.WebhookFindPrehistoricIsland then
		return false
	end

	data=data or {}

	local islandName=safeString(data.Name,"Prehistoric Island")
	local location=safeString(data.Location,"Unknown")

	return self:SendWebhook(
		"🏝️ Prehistoric Island",
		"Prehistoric Island detected.",
		{
			{
				name="Island",
				value=islandName,
				inline=true
			},
			{
				name="Location",
				value=location,
				inline=true
			}
		}
	)
end

--========================================================
-- LEVIATHAN
--========================================================

function SettingsModule:NotifyLeviathan(data)

	if not Settings.WebhookFindLeviathan then
		return false
	end

	data=data or {}

	local name=safeString(data.Name,"Leviathan")
	local location=safeString(data.Location,"Unknown")
	local health=safeString(data.Health,"Unknown")

	return self:SendWebhook(
		"🐋 Leviathan",
		"Leviathan detected.",
		{
			{
				name="Target",
				value=name,
				inline=true
			},
			{
				name="Health",
				value=health,
				inline=true
			},
			{
				name="Location",
				value=location,
				inline=true
			}
		}
	)
end

--========================================================
-- DESTROY IDK
--========================================================

function SettingsModule:NotifyDestroyIDK(data)

	if not Settings.WebhookDestroyIDK then
		return false
	end

	data=data or {}

	local name=safeString(data.Name,"Unknown")
	local location=safeString(data.Location,"Unknown")

	return self:SendWebhook(
		"💥 Destroy IDK",
		"Destroy IDK event detected.",
		{
			{
				name="Object",
				value=name,
				inline=true
			},
			{
				name="Location",
				value=location,
				inline=true
			}
		}
	)
end

--========================================================
-- MIRAGE
--========================================================

function SettingsModule:NotifyMirage(data)

	if not Settings.WebhookFindMirage then
		return false
	end

	data=data or {}

	local name=safeString(data.Name,"Mirage Island")
	local location=safeString(data.Location,"Unknown")

	return self:SendWebhook(
		"🌌 Mirage Island",
		"Mirage Island detected.",
		{
			{
				name="Island",
				value=name,
				inline=true
			},
			{
				name="Location",
				value=location,
				inline=true
			}
		}
	)
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

	elseif name=="AutoLoadScript" then

		setAutoLoadScript(enabled)
		return

	elseif name=="BoostFPS" then

		setBoostFPS(enabled)
		return

	elseif Settings[name]~=nil then

		Settings[name]=enabled
		return

	end

	warn(
		"[LPT Settings] Unknown setting:",
		name
	)
end

function SettingsModule:Get(name)

	if Settings[name]~=nil then
		return Settings[name]
	end

	return false
end

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
	Settings.AutoLoadScript=false
	Settings.BoostFPS=false

	Settings.WebhookURL=""
	Settings.WebhookPing=""
	Settings.WebhookPingEnabled=false

	Settings.WebhookNotiProfile=false
	Settings.WebhookStoreFruit=false
	Settings.WebhookFindPrehistoricIsland=false
	Settings.WebhookFindLeviathan=false
	Settings.WebhookDestroyIDK=false
	Settings.WebhookFindMirage=false
	Settings.WebhookRarity="Common"

	AutoLoadCallback=nil

	disconnectAll()

	if notificationConnection then
		disconnect(notificationConnection)
		notificationConnection=nil
	end

	if fpsConnection then
		disconnect(fpsConnection)
		fpsConnection=nil
	end

	restoreLighting()
	destroyCreatedObjects()

	screenGui=nil
	overlay=nil
end

return SettingsModule
