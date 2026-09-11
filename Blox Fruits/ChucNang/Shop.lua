local ShopModule={}

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

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
-- FIGHTING STYLE SCAN CONFIG
--========================================================

local FightingStyleKeywords={

	["Dark Step"]={
		"dark step",
		"darkstep",
		"dark step teacher"
	},

	["Electric"]={
		"electric",
		"mad scientist"
	},

	["Water Kung Fu"]={
		"water kung fu",
		"water kung fu teacher",
		"water fighter"
	},

	["Dragon Breath"]={
		"dragon breath",
		"sabi"
	},

	["Superhuman"]={
		"superhuman",
		"martial arts master"
	},

	["Death Step"]={
		"death step",
		"phoeyu",
		"reformed"
	},

	["Sharkman Karate"]={
		"sharkman karate",
		"sharkman",
		"daigrock"
	},

	["Electric Claw"]={
		"electric claw",
		"previous hero"
	},

	["Dragon Talon"]={
		"dragon talon",
		"uzoth"
	},

	["God Human"]={
		"god human",
		"ancient monk"
	},

	["Sanguine Art"]={
		"sanguine art",
		"shafi"
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

	message=tostring(message)

	if type(Callbacks.Notification)=="function" then
		pcall(
			Callbacks.Notification,
			message
		)
	else
		print(
			"[LPT Hub Shop]",
			message
		)
	end
end

local function validItem(name)

	return type(name)=="string"
		and ShopConfig[name]~=nil

end

local function getCharacter()

	if destroyed then
		return nil
	end

	return player.Character
end

local function getRoot(model)

	if not model then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart

end

local function normalizeName(name)

	return tostring(name or "")
		:lower()
		:gsub("[%p_]+"," ")
		:gsub("%s+"," ")
		:match("^%s*(.-)%s*$")
		or ""

end

local function nameMatchesKeywords(name,keywords)

	local normalized=normalizeName(name)

	for _,keyword in ipairs(keywords) do

		local normalizedKeyword=
			normalizeName(keyword)

		if normalizedKeyword~=""
			and string.find(
				normalized,
				normalizedKeyword,
				1,
				true
			) then

			return true
		end
	end

	return false
end

--========================================================
-- FIND NPC MODEL
--========================================================

local function isNPCModel(obj)

	if not obj:IsA("Model") then
		return false
	end

	if not obj:FindFirstChildOfClass("Humanoid") then
		return false
	end

	local root=
		obj:FindFirstChild("HumanoidRootPart")
		or obj.PrimaryPart

	if not root then
		return false
	end

	return true
end

--========================================================
-- FIND FIGHTING STYLE NPC
--========================================================

function ShopModule:FindFightingStyleNPC(styleName)

	if destroyed then
		return nil
	end

	local keywords=
		FightingStyleKeywords[styleName]

	if not keywords then
		notify(
			"Không có dữ liệu quét NPC cho: "
			..tostring(styleName)
		)

		return nil
	end

	local character=getCharacter()

	if not character then
		return nil
	end

	local playerRoot=
		character:FindFirstChild("HumanoidRootPart")

	if not playerRoot then
		return nil
	end

	local bestNPC=nil
	local bestScore=-math.huge
	local bestDistance=math.huge

	for _,obj in ipairs(workspace:GetDescendants()) do

		if isNPCModel(obj) then

			local npcRoot=getRoot(obj)

			if npcRoot then

				local score=0
				local normalized=
					normalizeName(obj.Name)

				-- Exact keyword matching
				for _,keyword in ipairs(keywords) do

					local normalizedKeyword=
						normalizeName(keyword)

					if normalized==normalizedKeyword then
						score+=1000
					elseif string.find(
						normalized,
						normalizedKeyword,
						1,
						true
					) then
						score+=500
					end
				end

				-- Teacher-like name bonus
				if string.find(
					normalized,
					"teacher",
					1,
					true
				) then
					score+=100
				end

				-- NPC bonus
				if string.find(
					normalized,
					"npc",
					1,
					true
				) then
					score+=10
				end

				if score>0 then

					local distance=
						(playerRoot.Position
						-npcRoot.Position).Magnitude

					-- Ưu tiên score cao.
					-- Nếu score bằng nhau thì ưu tiên gần hơn.
					if score>bestScore
						or (
							score==bestScore
							and distance<bestDistance
						) then

						bestNPC=obj
						bestScore=score
						bestDistance=distance
					end
				end
			end
		end
	end

	if bestNPC then

		notify(
			"Đã tìm thấy NPC "
			..bestNPC.Name
			.." | Distance: "
			..math.floor(bestDistance)
		)

	else

		notify(
			"Không tìm thấy NPC cho "
			..tostring(styleName)
		)

	end

	return bestNPC
end

--========================================================
-- MOVE TO NPC
--========================================================

function ShopModule:MoveToNPC(npc)

	if destroyed then
		return false
	end

	if not npc then
		return false
	end

	local character=getCharacter()

	if not character then
		return false
	end

	local humanoid=
		character:FindFirstChildOfClass("Humanoid")

	local root=
		character:FindFirstChild("HumanoidRootPart")

	local npcRoot=getRoot(npc)

	if not humanoid
		or not root
		or not npcRoot then

		return false
	end

	local targetPosition=
		npcRoot.Position
		-(
			npcRoot.CFrame.LookVector*3
		)

	targetPosition+=Vector3.new(0,1.5,0)

	notify(
		"Đang di chuyển tới "
		..npc.Name
	)

	--====================================================
	-- ƯU TIÊN MOVETO
	--====================================================

	local finished=false

	local moveConnection

	moveConnection=humanoid.MoveToFinished:Connect(
		function(success)

			finished=true

			if moveConnection then
				moveConnection:Disconnect()
				moveConnection=nil
			end

		end
	)

	pcall(function()
		humanoid:MoveTo(targetPosition)
	end)

	local startTime=os.clock()

	while not finished
		and not destroyed
		and os.clock()-startTime<8 do

		task.wait(.1)

		local currentRoot=
			character:FindFirstChild("HumanoidRootPart")

		if not currentRoot then
			break
		end

		if (
			currentRoot.Position
			-targetPosition
		).Magnitude<=5 then

			finished=true
			break
		end
	end

	if moveConnection then
		moveConnection:Disconnect()
		moveConnection=nil
	end

	--====================================================
	-- FALLBACK: CFrame
	--====================================================

	local currentRoot=
		character:FindFirstChild("HumanoidRootPart")

	if currentRoot then

		local distance=
			(currentRoot.Position
			-targetPosition).Magnitude

		if distance>8 then

			pcall(function()

				currentRoot.CFrame=
					CFrame.new(targetPosition)
					* CFrame.Angles(
						0,
						math.rad(
							npcRoot.Orientation.Y
						),
						0
					)

			end)

			task.wait(.25)
		end
	end

	return true
end

--========================================================
-- INTERACT WITH NPC
--========================================================

function ShopModule:InteractNPC(npc)

	if destroyed then
		return false
	end

	if not npc then
		return false
	end

	--====================================================
	-- PROXIMITY PROMPT
	--====================================================

	for _,obj in ipairs(npc:GetDescendants()) do

		if obj:IsA("ProximityPrompt") then

			local triggered=false

			pcall(function()

				if type(
					fireproximityprompt
				)=="function" then

					fireproximityprompt(obj)
					triggered=true

				end

			end)

			if triggered then

				notify(
					"Đã tương tác với "
					..npc.Name
				)

				return true
			end
		end
	end

	--====================================================
	-- CLICK DETECTOR
	--====================================================

	for _,obj in ipairs(npc:GetDescendants()) do

		if obj:IsA("ClickDetector") then

			local clicked=false

			pcall(function()

				if type(
					fireclickdetector
				)=="function" then

					fireclickdetector(obj)
					clicked=true

				end

			end)

			if clicked then

				notify(
					"Đã click "
					..npc.Name
				)

				return true
			end
		end
	end

	notify(
		"Không tìm thấy ProximityPrompt/ClickDetector tại "
		..npc.Name
	)

	return false
end

--========================================================
-- GET FIGHTING STYLE
--========================================================

function ShopModule:GetFightingStyle(styleName)

	if destroyed then
		return false
	end

	if not validItem(styleName) then

		notify(
			"Unknown Fighting Style: "
			..tostring(styleName)
		)

		return false
	end

	if ShopConfig[styleName].Type~="Toggle" then

		notify(
			"Không phải Fighting Style: "
			..styleName
		)

		return false
	end

	local npc=
		self:FindFightingStyleNPC(
			styleName
		)

	if not npc then
		return false
	end

	if not self:MoveToNPC(npc) then
		notify(
			"Không thể đến NPC "
			..npc.Name
		)
		return false
	end

	task.wait(.25)

	self:InteractNPC(npc)

	return true
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
			"Unknown item: "
			..tostring(name)
		)

		return false
	end

	local config=ShopConfig[name]

	if config.Type~="Button" then

		notify(
			"Item này không phải Button: "
			..name
		)

		return false
	end

	local success,result=pcall(function()

		return BuyItemRemote:InvokeServer(
			name
		)

	end)

	if not success then

		notify(
			"Không thể gửi yêu cầu mua: "
			..name
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
			"Mua thành công: "
			..name
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
		"Mua thất bại: "
		..name
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
-- SET FIGHTING STYLE
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

	--====================================================
	-- DISABLE
	--====================================================

	if not enabled then

		State.FightingStyleEnabled[name]=false

		notify(
			"Đã tắt: "
			..name
		)

		return true
	end

	--====================================================
	-- ALREADY ENABLED
	--====================================================

	if State.FightingStyleEnabled[name]==true then
		return true
	end

	--====================================================
	-- FIND / GO / INTERACT
	--====================================================

	local success=self:GetFightingStyle(name)

	if not success then

		State.FightingStyleEnabled[name]=false

		if type(Callbacks.Failed)=="function" then

			pcall(
				Callbacks.Failed,
				name
			)

		end

		return false
	end

	--====================================================
	-- SERVER REQUEST
	--====================================================

	local remoteSuccess,result=pcall(function()

		return BuyItemRemote:InvokeServer(
			name,
			"Toggle",
			true
		)

	end)

	if not remoteSuccess then

		State.FightingStyleEnabled[name]=false

		notify(
			"Không thể gửi yêu cầu: "
			..name
		)

		if type(Callbacks.Failed)=="function" then

			pcall(
				Callbacks.Failed,
				name
			)

		end

		return false
	end

	if result~=true then

		State.FightingStyleEnabled[name]=false

		notify(
			"Server từ chối: "
			..name
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

	State.FightingStyleEnabled[name]=true

	notify(
		"Đã bật: "
		..name
	)

	if type(Callbacks.Success)=="function" then

		pcall(
			Callbacks.Success,
			name
		)

	end

	return true
end

--========================================================
-- TOGGLE FIGHTING STYLE
--========================================================

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

	local current=
		State.FightingStyleEnabled[name]==true

	return self:Set(
		name,
		not current
	)
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

		if type(Callbacks.Success)=="function" then

			pcall(
				Callbacks.Success,
				"RedeemCode"
			)

		end

		return true
	end

	notify(
		"Code không hợp lệ hoặc đã được sử dụng"
	)

	if type(Callbacks.Failed)=="function" then

		pcall(
			Callbacks.Failed,
			"RedeemCode",
			result
		)

	end

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

	table.clear(
		State.FightingStyleEnabled
	)

	for key in pairs(Callbacks) do
		Callbacks[key]=nil
	end

end

return ShopModule
