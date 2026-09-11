local ShopModule={}

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer

local RemotesFolder=ReplicatedStorage:WaitForChild("ShopRemotes")

local BuyItemRemote=RemotesFolder:WaitForChild("BuyItem")
local RedeemCodeRemote=RemotesFolder:WaitForChild("RedeemCode")

--========================================================
-- CONFIG
--========================================================

local ShopConfig={

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
	FightingStyleEnabled={}
}

local destroyed=false

--========================================================
-- CALLBACKS
--========================================================

local Callbacks={
	Success=nil,
	Failed=nil,
	Notification=nil
}

--========================================================
-- HELPERS
--========================================================

local function notify(message)

	if destroyed then
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

local function validItem(name)

	return type(name)=="string"
		and ShopConfig[name]~=nil

end

--========================================================
-- CALLBACK
--========================================================

function ShopModule:SetCallback(name,callback)

	if destroyed then
		return false
	end

	if Callbacks[name]==nil then
		return false
	end

	if callback~=nil
		and type(callback)~="function" then

		return false
	end

	Callbacks[name]=callback

	return true
end

--========================================================
-- GET
--========================================================

function ShopModule:Get(name)

	if destroyed then
		return nil
	end

	if not validItem(name) then
		return nil
	end

	local config=ShopConfig[name]

	local result={}

	for key,value in pairs(config) do
		result[key]=value
	end

	if config.Type=="Toggle" then
		result.Enabled=
			State.FightingStyleEnabled[name]==true
	end

	return result
end

--========================================================
-- GET STATE
--========================================================

function ShopModule:GetState(name)

	if destroyed then
		return nil
	end

	if not validItem(name) then
		return nil
	end

	if ShopConfig[name].Type~="Toggle" then
		return nil
	end

	return State.FightingStyleEnabled[name]==true
end

--========================================================
-- BUY ITEM
--========================================================

function ShopModule:Buy(name)

	if destroyed then
		return false
	end

	if not validItem(name) then

		notify(
			"Unknown item: "..tostring(name)
		)

		return false
	end

	local config=ShopConfig[name]

	if config.Type~="Button" then

		notify(
			"Item này không phải Button: "..name
		)

		return false
	end

	-- Client requests the server.
	-- The server must perform all validation:
	-- money, fragments, requirements, ownership, etc.

	local success,result=pcall(function()

		return BuyItemRemote:InvokeServer(
			name
		)

	end)

	if not success then

		notify(
			"Không thể gửi yêu cầu mua: "..name
		)

		if type(Callbacks.Failed)=="function" then
			pcall(
				Callbacks.Failed,
				name
			)
		end

		return false
	end

	if result==true then

		notify(
			"Mua thành công: "..name
		)

		if type(Callbacks.Success)=="function" then
			pcall(
				Callbacks.Success,
				name
			)
		end

		return true
	end

	notify(
		"Mua thất bại: "..name
	)

	if type(Callbacks.Failed)=="function" then
		pcall(
			Callbacks.Failed,
			name,
			result
		)
	end

	return false
end

--========================================================
-- TOGGLE FIGHTING STYLE
--========================================================

function ShopModule:Set(name,enabled)

	if destroyed then
		return false
	end

	if not validItem(name) then
		return false
	end

	if ShopConfig[name].Type~="Toggle" then
		return false
	end

	enabled=enabled==true

	State.FightingStyleEnabled[name]=enabled

	return true
end

function ShopModule:Toggle(name)

	if destroyed then
		return false
	end

	if not validItem(name) then
		return false
	end

	if ShopConfig[name].Type~="Toggle" then
		return false
	end

	local enabled=
		not State.FightingStyleEnabled[name]

	State.FightingStyleEnabled[name]=enabled

	-- For an owned game, this can request the server
	-- to equip/activate the selected fighting style.

	local success,result=pcall(function()

		return BuyItemRemote:InvokeServer(
			name,
			"Toggle",
			enabled
		)

	end)

	if not success then

		State.FightingStyleEnabled[name]=not enabled

		notify(
			"Không thể gửi yêu cầu: "..name
		)

		return false
	end

	if result~=true then

		State.FightingStyleEnabled[name]=not enabled

		notify(
			"Không thể bật: "..name
		)

		return false
	end

	return true
end

--========================================================
-- REDEEM CODE
--========================================================

function ShopModule:RedeemCode(code)

	if destroyed then
		return false
	end

	code=tostring(code or "")

	code=code:gsub(
		"^%s+",
		""
	)

	code=code:gsub(
		"%s+$",
		""
	)

	if code=="" then

		notify(
			"Code không được để trống"
		)

		return false
	end

	local success,result=pcall(function()

		return RedeemCodeRemote:InvokeServer(
			code
		)

	end)

	if not success then

		notify(
			"Không thể redeem code"
		)

		return false
	end

	if result==true then

		notify(
			"Redeem thành công"
		)

		return true
	end

	notify(
		"Code không hợp lệ hoặc đã được sử dụng"
	)

	return false
end

--========================================================
-- GET ALL
--========================================================

function ShopModule:GetAll()

	if destroyed then
		return {}
	end

	local result={}

	for name in pairs(ShopConfig) do
		result[name]=self:Get(name)
	end

	return result
end

--========================================================
-- DESTROY
--========================================================

function ShopModule:Destroy()

	if destroyed then
		return
	end

	destroyed=true

	table.clear(State.FightingStyleEnabled)

	for key in pairs(Callbacks) do
		Callbacks[key]=nil
	end

end

return ShopModule
