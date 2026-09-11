local ShopModule={}

local Players=game:GetService("Players")

local player=Players.LocalPlayer

--========================================================
-- CONFIG
--========================================================

local ShopConfig={

	-- Misc Shop
	["Reroll Race"]={
		Type="Button",
		Cost=2500,
		Currency="Fragments"
	},

	["Reset Stats"]={
		Type="Button",
		Cost=3000,
		Currency="Fragments"
	},

	["Buy Race Cyborg"]={
		Type="Button",
		Cost=3000,
		Currency="Fragments"
	},

	["Buy Race Ghoul"]={
		Type="Button",
		Cost=3000,
		Currency="Fragments"
	},

	-- Fighting Shop
	["Dark Step"]={
		Type="Toggle"
	},

	["Electric"]={
		Type="Toggle"
	},

	["Water Kung Fu"]={
		Type="Toggle"
	},

	["Dragon Breath"]={
		Type="Toggle"
	},

	["Superhuman"]={
		Type="Toggle"
	},

	["Death Step"]={
		Type="Toggle"
	},

	["Sharkman Karate"]={
		Type="Toggle"
	},

	["Electric Claw"]={
		Type="Toggle"
	},

	["Dragon Talon"]={
		Type="Toggle"
	},

	["God Human"]={
		Type="Toggle"
	},

	["Sanguine Art"]={
		Type="Toggle"
	},

	-- Abilities Shop
	["Sky Jump"]={
		Type="Button",
		Cost=10000,
		Currency="Beli"
	},

	["Buso Haki"]={
		Type="Button",
		Cost=25000,
		Currency="Beli"
	},

	["Flash Step"]={
		Type="Button",
		Cost=100000,
		Currency="Beli"
	},

	["Observation Haki"]={
		Type="Button",
		Cost=750000,
		Currency="Beli"
	}
}

--========================================================
-- STATE
--========================================================

local State={

	RedeemCode="",

	FightingStyleEnabled={

		["Dark Step"]=false,
		["Electric"]=false,
		["Water Kung Fu"]=false,
		["Dragon Breath"]=false,
		["Superhuman"]=false,
		["Death Step"]=false,
		["Sharkman Karate"]=false,
		["Electric Claw"]=false,
		["Dragon Talon"]=false,
		["God Human"]=false,
		["Sanguine Art"]=false

	}

}

local destroyed=false

--========================================================
-- CALLBACKS
--========================================================

local Callbacks={

	Buy=nil,

	RedeemCode=nil,

	Toggle=nil,

	Notification=nil

}

--========================================================
-- HELPERS
--========================================================

local function isDestroyed()

	return destroyed

end

local function notify(message)

	if isDestroyed() then
		return
	end

	if type(Callbacks.Notification)=="function" then

		pcall(
			Callbacks.Notification,
			tostring(message)
		)

	else

		print(
			"[LPT Hub Shop]",
			tostring(message)
		)

	end

end

local function validName(name)

	return type(name)=="string"
		and ShopConfig[name]~=nil

end

--========================================================
-- SET CALLBACK
--========================================================

function ShopModule:SetCallback(callbackName,callback)

	if isDestroyed() then
		return false
	end

	if type(callbackName)~="string" then
		return false
	end

	if callback~=nil
		and type(callback)~="function" then

		return false
	end

	if Callbacks[callbackName]==nil then
		return false
	end

	Callbacks[callbackName]=callback

	return true
end

--========================================================
-- GET SHOP ITEM
--========================================================

function ShopModule:Get(name)

	if isDestroyed() then
		return nil
	end

	if not validName(name) then
		return nil
	end

	local data=ShopConfig[name]

	local result={}

	for key,value in pairs(data) do
		result[key]=value
	end

	if data.Type=="Toggle" then
		result.Enabled=
			State.FightingStyleEnabled[name]==true
	end

	return result
end

--========================================================
-- GET STATE
--========================================================

function ShopModule:GetState(name)

	if isDestroyed() then
		return nil
	end

	if not validName(name) then
		return nil
	end

	local data=ShopConfig[name]

	if data.Type=="Toggle" then

		return State.FightingStyleEnabled[name]==true

	end

	return nil
end

--========================================================
-- SET STATE
--========================================================

function ShopModule:Set(name,value,silent)

	if isDestroyed() then
		return false
	end

	if not validName(name) then
		return false
	end

	local data=ShopConfig[name]

	if data.Type~="Toggle" then
		return false
	end

	local enabled=value==true

	State.FightingStyleEnabled[name]=enabled

	if not silent
		and type(Callbacks.Toggle)=="function" then

		local success=pcall(
			Callbacks.Toggle,
			name,
			enabled
		)

		if not success then
			notify(
				"Toggle callback failed: "..name
			)
		end

	end

	return true
end

--========================================================
-- TOGGLE FIGHTING STYLE
--========================================================

function ShopModule:Toggle(name)

	if isDestroyed() then
		return false
	end

	if not validName(name) then
		return false
	end

	local data=ShopConfig[name]

	if data.Type~="Toggle" then
		return false
	end

	local newValue=
		not State.FightingStyleEnabled[name]

	return self:Set(
		name,
		newValue
	)
end

--========================================================
-- BUY
--========================================================

function ShopModule:Buy(name)

	if isDestroyed() then
		return false
	end

	if not validName(name) then
		notify("Unknown shop item: "..tostring(name))
		return false
	end

	local data=ShopConfig[name]

	if data.Type~="Button" then
		notify(
			"Item này là Toggle: "..name
		)
		return false
	end

	if type(Callbacks.Buy)~="function" then

		notify(
			"Chưa gắn Buy callback: "..name
		)

		return false
	end

	local success,result=pcall(
		Callbacks.Buy,
		name,
		data.Cost,
		data.Currency
	)

	if not success then

		notify(
			"Buy callback failed: "..name
		)

		return false
	end

	return result~=false
end

--========================================================
-- REDEEM CODE
--========================================================

function ShopModule:RedeemCode(code)

	if isDestroyed() then
		return false
	end

	code=tostring(code or "")
	code=code:gsub("^%s+","")
	code=code:gsub("%s+$","")

	if code=="" then

		notify("Code không được để trống")

		return false
	end

	State.RedeemCode=code

	if type(Callbacks.RedeemCode)~="function" then

		notify(
			"Chưa gắn RedeemCode callback"
		)

		return false
	end

	local success,result=pcall(
		Callbacks.RedeemCode,
		code
	)

	if not success then

		notify(
			"Redeem callback failed"
		)

		return false
	end

	return result~=false
end

--========================================================
-- SET REDEEM CODE
--========================================================

function ShopModule:SetRedeemCode(code)

	if isDestroyed() then
		return false
	end

	State.RedeemCode=tostring(code or "")

	return true
end

--========================================================
-- GET REDEEM CODE
--========================================================

function ShopModule:GetRedeemCode()

	if isDestroyed() then
		return ""
	end

	return State.RedeemCode
end

--========================================================
-- GET ALL ITEMS
--========================================================

function ShopModule:GetAll()

	if isDestroyed() then
		return {}
	end

	local result={}

	for name,data in pairs(ShopConfig) do

		result[name]=self:Get(name)

	end

	return result
end

--========================================================
-- RESET TOGGLES
--========================================================

function ShopModule:Reset()

	if isDestroyed() then
		return false
	end

	for name in pairs(State.FightingStyleEnabled) do

		State.FightingStyleEnabled[name]=false

	end

	return true
end

--========================================================
-- DESTROY
--========================================================

function ShopModule:Destroy()

	if destroyed then
		return
	end

	destroyed=true

	for name in pairs(State.FightingStyleEnabled) do
		State.FightingStyleEnabled[name]=false
	end

	State.RedeemCode=""

	for key in pairs(Callbacks) do
		Callbacks[key]=nil
	end

	ShopConfig=nil
	State=nil

end

--========================================================
-- MODULE INFO
--========================================================

function ShopModule:GetInfo()

	return {

		Name="ShopModule",

		Version="1.0.0",

		Player=player and player.Name or "Unknown",

		MiscShop={

			"Reroll Race",

			"Reset Stats",

			"Buy Race Cyborg",

			"Buy Race Ghoul"

		},

		FightingShop={

			"Dark Step",

			"Electric",

			"Water Kung Fu",

			"Dragon Breath",

			"Superhuman",

			"Death Step",

			"Sharkman Karate",

			"Electric Claw",

			"Dragon Talon",

			"God Human",

			"Sanguine Art"

		},

		AbilitiesShop={

			"Sky Jump",

			"Buso Haki",

			"Flash Step",

			"Observation Haki"

		}

	}

end

return ShopModule