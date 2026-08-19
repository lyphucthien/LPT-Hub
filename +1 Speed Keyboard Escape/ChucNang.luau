local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Module = {}

--========================================================
-- CONFIG
--========================================================

local ENABLE_FLY_TO_WIN = true

local ARRIVAL_DISTANCE = 3
local FLY_TIMEOUT = 60

local FLY_ABOVE_TARGET = true
local TARGET_HEIGHT_OFFSET = 3

-- Không cho dùng cùng 1 Part cho nhiều Stage
local ALLOW_DUPLICATE_TARGET = false

--========================================================
-- STATE
--========================================================

local State = {
	WalkSpeed = 16,
	JumpPower = 50,

	InfiniteJump = false,
	NoClip = false,

	Flying = false,

	FlySpeed = 90,
	FlyHeight = 0,

	CurrentTarget = nil,
	CurrentStage = nil,

	TargetCache = {},

	Scanning = false,
}

local Connections = {}
local OriginalCollision = {}

--========================================================
-- WIN STAGES
--========================================================

local WIN_STAGES = {
	{stage = 1, value = 1, text = "Stage 1 (+1 Win)"},
	{stage = 2, value = 3, text = "Stage 2 (+3 Wins)"},
	{stage = 3, value = 10, text = "Stage 3 (+10 Wins)"},
	{stage = 4, value = 20, text = "Stage 4 (+20 Wins)"},
	{stage = 5, value = 60, text = "Stage 5 (+60 Wins)"},
	{stage = 6, value = 100, text = "Stage 6 (+100 Wins)"},
	{stage = 7, value = 150, text = "Stage 7 (+150 Wins)"},
	{stage = 8, value = 300, text = "Stage 8 (+300 Wins)"},
	{stage = 9, value = 500, text = "Stage 9 (+500 Wins)"},
	{stage = 10, value = 1000, text = "Stage 10 (+1K Wins)"},
	{stage = 11, value = 2500, text = "Stage 11 (+2.5K Wins)"},
	{stage = 12, value = 10000, text = "Stage 12 (+10K Wins)"},
	{stage = 13, value = 25000, text = "Stage 13 (+25K Wins)"},
	{stage = 14, value = 50000, text = "Stage 14 (+50K Wins)"},
	{stage = 15, value = 150000, text = "Stage 15 (+150K Wins)"},
}

--========================================================
-- UTILITY
--========================================================

local function disconnect(name)
	local connection = Connections[name]

	if connection then
		connection:Disconnect()
		Connections[name] = nil
	end
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getNumber(value, minimum, maximum, fallback)
	value = tonumber(value)

	if not value then
		return fallback
	end

	return math.clamp(value, minimum, maximum)
end

local function isBasePart(object)
	return object
		and object:IsA("BasePart")
		and object.Parent ~= nil
end

local function containsText(text, phrase)
	if not text then
		return false
	end

	return string.find(
		string.lower(tostring(text)),
		string.lower(phrase),
		1,
		true
	) ~= nil
end

--========================================================
-- PARSE WIN VALUE
--========================================================

local function parseWinValue(text)
	if not text then
		return nil
	end

	local s = tostring(text)
		:gsub(",", "")
		:gsub("%s+", "")

	local number, suffix = s:match(
		"(%d+%.?%d*)([kKmM])"
	)

	if number then
		local n = tonumber(number)

		if n then
			if suffix == "k" or suffix == "K" then
				return n * 1000
			end

			if suffix == "m" or suffix == "M" then
				return n * 1000000
			end
		end
	end

	local plain = s:match("(%d+)")

	if plain then
		return tonumber(plain)
	end

	return nil
end

--========================================================
-- CHARACTER SETTINGS
--========================================================

local function applyCharacterSettings()
	local humanoid = getHumanoid()

	if not humanoid or not humanoid.Parent then
		return
	end

	pcall(function()
		humanoid.UseJumpPower = true
		humanoid.WalkSpeed = State.WalkSpeed
		humanoid.JumpPower = State.JumpPower
	end)
end

--========================================================
-- WALK SPEED
--========================================================

function Module.SetWalkSpeed(value)
	State.WalkSpeed = getNumber(
		value,
		0,
		500,
		State.WalkSpeed
	)

	applyCharacterSettings()

	return State.WalkSpeed
end

function Module.GetWalkSpeed()
	return State.WalkSpeed
end

--========================================================
-- JUMP POWER
--========================================================

function Module.SetJumpPower(value)
	State.JumpPower = getNumber(
		value,
		0,
		500,
		State.JumpPower
	)

	applyCharacterSettings()

	return State.JumpPower
end

function Module.GetJumpPower()
	return State.JumpPower
end

--========================================================
-- FLY SPEED
--========================================================

function Module.SetFlySpeed(value)
	State.FlySpeed = getNumber(
		value,
		10,
		500,
		State.FlySpeed
	)

	return State.FlySpeed
end

function Module.GetFlySpeed()
	return State.FlySpeed
end

--========================================================
-- FLY HEIGHT
--========================================================

function Module.SetFlyHeight(value)
	State.FlyHeight = getNumber(
		value,
		0,
		100,
		State.FlyHeight
	)

	return State.FlyHeight
end

function Module.GetFlyHeight()
	return State.FlyHeight
end

--========================================================
-- INFINITE JUMP
--========================================================

function Module.SetInfiniteJump(enabled)
	State.InfiniteJump = enabled == true

	disconnect("InfiniteJump")

	if State.InfiniteJump then
		Connections.InfiniteJump =
			UserInputService.JumpRequest:Connect(function()

				if not State.InfiniteJump then
					return
				end

				local humanoid = getHumanoid()

				if humanoid and humanoid.Parent then
					pcall(function()
						humanoid:ChangeState(
							Enum.HumanoidStateType.Jumping
						)
					end)
				end
			end)
	end

	return State.InfiniteJump
end

function Module.GetInfiniteJump()
	return State.InfiniteJump
end

--========================================================
-- NO CLIP
--========================================================

local function rememberCollision(character)
	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			if OriginalCollision[object] == nil then
				OriginalCollision[object] = object.CanCollide
			end
		end
	end
end

local function restoreCollision(character)
	if not character then
		table.clear(OriginalCollision)
		return
	end

	for object, original in pairs(OriginalCollision) do
		if object and object.Parent then
			pcall(function()
				object.CanCollide = original
			end)
		end
	end

	table.clear(OriginalCollision)
end

function Module.SetNoClip(enabled)
	State.NoClip = enabled == true

	local character = getCharacter()

	if State.NoClip then
		if character then
			rememberCollision(character)
		end
	else
		restoreCollision(character)
	end

	return State.NoClip
end

function Module.GetNoClip()
	return State.NoClip
end

--========================================================
-- COLLECT TEXT
--========================================================

local function collectObjectText(object)
	if not object then
		return ""
	end

	local texts = {}

	table.insert(texts, tostring(object.Name))

	local parent = object.Parent

	for _ = 1, 10 do
		if not parent then
			break
		end

		table.insert(
			texts,
			tostring(parent.Name)
		)

		parent = parent.Parent
	end

	for _, descendant in ipairs(
		object:GetDescendants()
	) do

		if descendant:IsA("TextLabel")
			or descendant:IsA("TextButton")
			or descendant:IsA("TextBox")
		then

			table.insert(
				texts,
				tostring(descendant.Text)
			)
		end
	end

	return table.concat(texts, " ")
end

--========================================================
-- CHECK INTERACTIVE
--========================================================

local function hasInteractiveObject(part)
	if not part then
		return false
	end

	if part:FindFirstChildOfClass(
		"ClickDetector"
	) then
		return true
	end

	if part:FindFirstChildOfClass(
		"ProximityPrompt"
	) then
		return true
	end

	if part:FindFirstChild("TouchInterest") then
		return true
	end

	return false
end

--========================================================
-- NAME HELPERS
--========================================================

local function isBadNPCName(name)
	name = string.lower(name or "")

	return name:find("npc", 1, true)
		or name:find("ballerina", 1, true)
		or name:find("chocolita", 1, true)
		or name:find("enemy", 1, true)
		or name:find("dummy", 1, true)
		or name:find("character", 1, true)
end

local function isStrongWinName(name)
	name = string.lower(name or "")

	return name == "winblock"
		or name == "winblock1"
		or name == "winbutton"
		or name == "getwinbutton"
		or name == "claimwinbutton"
		or name == "button"
		or name:find("winblock", 1, true)
		or name:find("winbutton", 1, true)
		or name:find("getwin", 1, true)
		or name:find("claimwin", 1, true)
		or name:find("win_button", 1, true)
		or name:find("win_block", 1, true)
end

--========================================================
-- SCORE PART
--========================================================

local function scorePart(part, stageNumber, winValue)
	if not isBasePart(part) then
		return -math.huge
	end

	local name = part.Name:lower()
	local text = collectObjectText(part)

	local score = 0

	--====================================================
	-- STRONG TARGET NAMES
	--====================================================

	if name == "winblock" then
		score += 10000
	end

	if name == "winblock1" then
		score += 10000
	end

	if name == "winbutton" then
		score += 11000
	end

	if name == "getwinbutton" then
		score += 12000
	end

	if name == "claimwinbutton" then
		score += 12000
	end

	if name == "button" then
		score += 8000
	end

	if name:find("winblock", 1, true) then
		score += 7000
	end

	if name:find("winbutton", 1, true) then
		score += 7000
	end

	if name:find("getwin", 1, true) then
		score += 7000
	end

	if name:find("claimwin", 1, true) then
		score += 7000
	end

	--====================================================
	-- NORMAL KEYWORDS
	--====================================================

	if name:find("win", 1, true) then
		score += 3000
	end

	if name:find("claim", 1, true) then
		score += 2500
	end

	if name:find("finish", 1, true) then
		score += 2000
	end

	if name:find("award", 1, true) then
		score += 2000
	end

	if name:find("button", 1, true) then
		score += 2500
	end

	--====================================================
	-- INTERACTIVE
	--====================================================

	if hasInteractiveObject(part) then
		score += 3000
	end

	--====================================================
	-- GUI TEXT
	--====================================================

	if containsText(text, "Lấy Win")
		or containsText(text, "Lay Win")
		or containsText(text, "Get Win")
		or containsText(text, "Claim Win")
	then
		score += 15000
	end

	--====================================================
	-- WIN VALUE
	--====================================================

	if parseWinValue(part.Name) == winValue then
		score += 5000
	end

	--====================================================
	-- STAGE NUMBER
	--====================================================

	local allText = string.lower(
		collectObjectText(part)
	)

	if stageNumber then

		if allText:find(
			"stage" .. tostring(stageNumber),
			1,
			true
		) then
			score += 5000
		end

		if allText:find(
			"stage " .. tostring(stageNumber),
			1,
			true
		) then
			score += 5000
		end
	end

	--====================================================
	-- NPC PENALTY
	--====================================================

	if isBadNPCName(part.Name) then
		score -= 15000
	end

	local parent = part.Parent

	for _ = 1, 8 do

		if not parent then
			break
		end

		if isBadNPCName(parent.Name) then
			score -= 12000
		end

		parent = parent.Parent
	end

	--====================================================
	-- HITBOX PENALTY
	--====================================================

	if name == "hitbox" then
		score -= 5000
	end

	return score
end

--========================================================
-- CHECK PART BELONGS TO STAGE
--========================================================

local function belongsToStage(
	part,
	stageNumber
)

	if not part then
		return false
	end

	local wanted = {
		"stage" .. tostring(stageNumber),
		"stage-" .. tostring(stageNumber),
		"stage_" .. tostring(stageNumber),
		"stage " .. tostring(stageNumber),
	}

	local current = part

	for _ = 1, 12 do

		if not current then
			break
		end

		local name = string.lower(
			tostring(current.Name)
		)

		for _, pattern in ipairs(wanted) do

			if name == pattern then
				return true
			end
		end

		current = current.Parent
	end

	return false
end

--========================================================
-- FIND TARGET PART
--========================================================

local function findTargetPart(
	container,
	stageNumber,
	winValue
)

	if not container then
		return nil
	end

	--====================================================
	-- Nếu container chính là Part
	--====================================================

	if container:IsA("BasePart") then

		local score =
			scorePart(
				container,
				stageNumber,
				winValue
			)

		if score > 0 then
			return container
		end

		return nil
	end

	--====================================================
	-- PrimaryPart
	--====================================================

	if container:IsA("Model") then

		local primary =
			container.PrimaryPart

		if primary
			and primary.Parent
		then

			local score =
				scorePart(
					primary,
					stageNumber,
					winValue
				)

			if score > 0 then
				return primary
			end
		end
	end

	--====================================================
	-- Search descendants
	--====================================================

	local bestPart = nil
	local bestScore = -math.huge

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if not object:IsA("BasePart") then
			continue
		end

		local score =
			scorePart(
				object,
				stageNumber,
				winValue
			)

		-- Part nằm đúng Stage được cộng điểm
		if belongsToStage(
			object,
			stageNumber
		) then
			score += 6000
		end

		if score > bestScore then
			bestScore = score
			bestPart = object
		end
	end

	if bestPart
		and bestScore > 0
	then
		return bestPart
	end

	return nil
end

--========================================================
-- FIND STAGE CONTAINER
--========================================================

local function findStageContainer(
	stageNumber,
	winValue
)

	local names = {
		"Stage" .. stageNumber,
		"Stage-" .. stageNumber,
		"Stage_" .. stageNumber,
		"Stage " .. stageNumber,

		"stage" .. stageNumber,
		"stage-" .. stageNumber,
		"stage_" .. stageNumber,
		"stage " .. stageNumber,

		"Win" .. winValue,
		"Win-" .. winValue,
		"Win_" .. winValue,

		"Win " .. winValue,
		"Wins " .. winValue,

		"+" .. winValue .. " Win",
		"+" .. winValue .. " Wins",
	}

	for _, name in ipairs(names) do

		local object =
			workspace:FindFirstChild(
				name,
				true
			)

		if object then
			return object
		end
	end

	return nil
end

--========================================================
-- FIND BY WIN VALUE
--========================================================

local function findByWinValue(
	winValue,
	stageNumber,
	usedTargets
)

	local bestPart = nil
	local bestScore = -math.huge

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if not object:IsA("BasePart") then
			continue
		end

		-- Không dùng target đã được stage khác lấy
		if not ALLOW_DUPLICATE_TARGET
			and usedTargets[object]
		then
			continue
		end

		local score =
			scorePart(
				object,
				stageNumber,
				winValue
			)

		--================================================
		-- Object name
		--================================================

		if parseWinValue(
			object.Name
		) == winValue then
			score += 5000
		end

		--================================================
		-- Ancestors
		--================================================

		local parent =
			object.Parent

		for _ = 1, 10 do

			if not parent then
				break
			end

			if parseWinValue(
				parent.Name
			) == winValue
			then
				score += 5000
			end

			local parentName =
				string.lower(
					tostring(parent.Name)
				)

			if parentName == (
				"stage"
				.. tostring(stageNumber)
			) then
				score += 7000
			end

			parent = parent.Parent
		end

		--================================================
		-- GUI text
		--================================================

		for _, descendant in ipairs(
			object:GetDescendants()
		) do

			if descendant:IsA(
				"TextLabel"
			)
			or descendant:IsA(
				"TextButton"
			)
			or descendant:IsA(
				"TextBox"
			)
			then

				local text =
					tostring(
						descendant.Text
					)

				if parseWinValue(text)
					== winValue
				then
					score += 6000
				end

				if containsText(
					text,
					"Lấy Win"
				)
				or containsText(
					text,
					"Lay Win"
				)
				or containsText(
					text,
					"Get Win"
				)
				or containsText(
					text,
					"Claim Win"
				)
				then
					score += 12000
				end
			end
		end

		--================================================
		-- Must belong to correct stage if possible
		--================================================

		if belongsToStage(
			object,
			stageNumber
		) then
			score += 7000
		end

		--================================================
		-- Reject NPC target
		--================================================

		if isBadNPCName(
			object.Name
		) then
			score -= 15000
		end

		if object.Name:lower()
			== "hitbox"
		then
			score -= 5000
		end

		--================================================
		-- Best
		--================================================

		if score > bestScore then
			bestScore = score
			bestPart = object
		end
	end

	if not bestPart
		or bestScore <= 0
	then
		return nil
	end

	return bestPart
end

--========================================================
-- REFRESH TARGETS
--========================================================

function Module.RefreshTargets()

	if State.Scanning then
		return State.TargetCache
	end

	State.Scanning = true

	local targets = {}
	local usedTargets = {}

	print("")
	print("========================================")
	print("       LPT HUB - WIN TARGET SCAN")
	print("========================================")

	for _, stageInfo in ipairs(
		WIN_STAGES
	) do

		local stageNumber =
			stageInfo.stage

		local winValue =
			stageInfo.value

		local target = nil

		--================================================
		-- 1. FIND STAGE CONTAINER
		--================================================

		local container =
			findStageContainer(
				stageNumber,
				winValue
			)

		if container then

			print(
				("[SCAN] Stage %d container -> %s")
				:format(
					stageNumber,
					container:GetFullName()
				)
			)

			target =
				findTargetPart(
					container,
					stageNumber,
					winValue
				)
		end

		--================================================
		-- 2. GLOBAL SEARCH
		--================================================

		if not target then

			target =
				findByWinValue(
					winValue,
					stageNumber,
					usedTargets
				)
		end

		--================================================
		-- 3. VALIDATE
		--================================================

		if isBasePart(target) then

			if not ALLOW_DUPLICATE_TARGET
				and usedTargets[target]
			then

				target = nil

			end
		end

		if isBasePart(target) then

			targets[winValue] =
				target

			usedTargets[target] =
				true

			print(
				("[FOUND] Stage %d | +%s Win | %s")
				:format(
					stageNumber,
					tostring(winValue),
					target:GetFullName()
				)
			)

			print(
				("        Position: %s")
				:format(
					tostring(target.Position)
				)
			)

		else

			warn(
				("[MISSING] Stage %d | +%s Win")
				:format(
					stageNumber,
					tostring(winValue)
				)
			)
		end
	end

	State.TargetCache =
		targets

	State.Scanning = false

	local count = 0

	for _, _ in pairs(targets) do
		count += 1
	end

	print("----------------------------------------")

	print(
		("Found %d / %d Win targets")
		:format(
			count,
			#WIN_STAGES
		)
	)

	print("========================================")
	print("")

	return targets
end

--========================================================
-- GET TARGET
--========================================================

function Module.GetTarget(value)

	value = tonumber(value)

	if not value then
		return nil
	end

	local target =
		State.TargetCache[value]

	if isBasePart(target) then
		return target
	end

	Module.RefreshTargets()

	return State.TargetCache[value]
end

--========================================================
-- GET TARGETS
--========================================================

function Module.GetTargets()

	if next(
		State.TargetCache
	) == nil then

		Module.RefreshTargets()
	end

	return State.TargetCache
end

--========================================================
-- GET STAGE
--========================================================

function Module.GetStage(stageNumber)

	stageNumber =
		tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	for _, stageInfo in ipairs(
		WIN_STAGES
	) do

		if stageInfo.stage
			== stageNumber
		then
			return stageInfo
		end
	end

	return nil
end

function Module.GetStages()
	return WIN_STAGES
end

--========================================================
-- TARGET POSITION
--========================================================

local function getTargetPosition(part)

	if not isBasePart(part) then
		return nil
	end

	local position =
		part.Position

	if FLY_ABOVE_TARGET then

		return Vector3.new(
			position.X,

			position.Y
				+ (part.Size.Y / 2)
				+ TARGET_HEIGHT_OFFSET
				+ State.FlyHeight,

			position.Z
		)
	end

	return Vector3.new(
		position.X,
		position.Y + State.FlyHeight,
		position.Z
	)
end

--========================================================
-- STOP FLYING
--========================================================

function Module.StopFlying()

	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

end

function Module.IsFlying()
	return State.Flying
end

--========================================================
-- FLY TO PART
--========================================================

function Module.FlyToPart(
	part,
	stageNumber
)

	if not isBasePart(part) then

		warn(
			"[FLY] Invalid target"
		)

		return false,
			"Invalid target"
	end

	if State.Flying then

		warn(
			"[FLY] Already flying"
		)

		return false,
			"Already flying"
	end

	local character =
		getCharacter()

	local root =
		getRoot()

	local humanoid =
		getHumanoid()

	if not character then
		return false, "Character nil"
	end

	if not root then
		return false, "Root nil"
	end

	if not humanoid then
		return false, "Humanoid nil"
	end

	if not part.Parent then
		return false,
			"Target disappeared"
	end

	State.Flying = true
	State.CurrentTarget = part
	State.CurrentStage = stageNumber

	print("========================================")
	print("[FLY] START")
	print("[FLY] Stage:", stageNumber or "?")
	print("[FLY] Target:", part:GetFullName())
	print("[FLY] Player:", root.Position)
	print("[FLY] Target:", part.Position)
	print(
		"[FLY] Distance:",
		(root.Position - part.Position).Magnitude
	)
	print("[FLY] Speed:", State.FlySpeed)
	print("========================================")

	local oldAutoRotate =
		humanoid.AutoRotate

	local oldPlatformStand =
		humanoid.PlatformStand

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local started =
		os.clock()

	local reached =
		false

	while
		State.Flying
		and character.Parent
		and root.Parent
		and part.Parent
		and os.clock() - started < FLY_TIMEOUT
	do

		local destination =
			getTargetPosition(part)

		if not destination then
			break
		end

		local current =
			root.Position

		local offset =
			destination - current

		local distance =
			offset.Magnitude

		--================================================
		-- ARRIVED
		--================================================

		if distance <= ARRIVAL_DISTANCE then

			reached = true
			break
		end

		local dt =
			RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		if not root.Parent
			or not character.Parent
			or not part.Parent
		then
			break
		end

		--================================================
		-- MOVE
		--================================================

		local speed =
			math.max(
				10,
				State.FlySpeed
			)

		local step =
			math.min(
				distance,
				speed * dt
			)

		if offset.Magnitude > 0 then

			local nextPosition =
				current
				+ offset.Unit
				* step

			local lookCFrame =
				CFrame.lookAt(
					nextPosition,
					destination
				)

			pcall(function()

				root.CFrame =
					lookCFrame

				root.AssemblyLinearVelocity =
					Vector3.zero

				root.AssemblyAngularVelocity =
					Vector3.zero

			end)
		end
	end

	--====================================================
	-- FINAL POSITION
	--====================================================

	if reached
		and State.Flying
		and root.Parent
		and part.Parent
	then

		local finalPosition =
			getTargetPosition(part)

		if finalPosition then

			print(
				"[FLY] Locking final position:",
				finalPosition
			)

			for _ = 1, 12 do

				if not State.Flying then
					break
				end

				if not root.Parent
					or not part.Parent
				then
					break
				end

				pcall(function()

					root.CFrame =
						CFrame.new(
							finalPosition
						)

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

				end)

				RunService.Heartbeat:Wait()
			end
		end
	end

	--====================================================
	-- RESTORE HUMANOID
	--====================================================

	if humanoid.Parent then

		pcall(function()

			humanoid.AutoRotate =
				oldAutoRotate

			humanoid.PlatformStand =
				oldPlatformStand

			humanoid:ChangeState(
				Enum.HumanoidStateType.GettingUp
			)

		end)
	end

	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

	if reached then

		print(
			"[FLY] SUCCESS"
		)

		return true
	end

	warn(
		"[FLY] FAILED"
	)

	return false,
		"Could not reach target"
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(
	winAmount
)

	if not ENABLE_FLY_TO_WIN then

		return false,
			"FlyToWin is disabled."
	end

	winAmount =
		tonumber(winAmount)

	if not winAmount then

		return false,
			"Invalid Win amount."
	end

	if State.Flying then

		return false,
			"Already flying."
	end

	--====================================================
	-- CACHE
	--====================================================

	local target =
		State.TargetCache[winAmount]

	--====================================================
	-- REFRESH IF MISSING
	--====================================================

	if not isBasePart(target) then

		print(
			"[FlyToWin] Target missing, rescanning..."
		)

		Module.RefreshTargets()

		target =
			State.TargetCache[winAmount]
	end

	if not isBasePart(target) then

		warn(
			("[FlyToWin] No target for +%s")
			:format(
				tostring(winAmount)
			)
		)

		return false,
			("No +%s Win target.")
			:format(
				tostring(winAmount)
			)
	end

	--====================================================
	-- FIND STAGE
	--====================================================

	local stageNumber = nil

	for _, info in ipairs(
		WIN_STAGES
	) do

		if info.value == winAmount then

			stageNumber = info.stage

			break
		end
	end

	print(
		("[FlyToWin] Stage %s | +%s -> %s")
		:format(
			tostring(stageNumber or "?"),
			tostring(winAmount),
			target:GetFullName()
		)
	)

	return Module.FlyToPart(
		target,
		stageNumber
	)
end

--========================================================
-- FLY TO STAGE
--========================================================

function Module.FlyToStage(
	stageNumber
)

	stageNumber =
		tonumber(stageNumber)

	if not stageNumber then

		return false,
			"Invalid stage."
	end

	local stageInfo =
		Module.GetStage(
			stageNumber
		)

	if not stageInfo then

		return false,
			(
				"Stage %d does not exist."
			):format(
				stageNumber
			)
	end

	return Module.FlyToWin(
		stageInfo.value
	)
end

--========================================================
-- WALK SPEED / JUMP POWER MAINTAIN
--========================================================

Connections.CharacterSettings =
	RunService.Heartbeat:Connect(
		function()

			local humanoid = getHumanoid()

			if not humanoid
				or not humanoid.Parent
			then
				return
			end

			--============================================
			-- WALK SPEED
			--============================================

			if math.abs(
				humanoid.WalkSpeed
				- State.WalkSpeed
			) > 0.01
			then

				pcall(function()

					humanoid.WalkSpeed =
						State.WalkSpeed

				end)
			end

			--============================================
			-- JUMP POWER
			--============================================

			if humanoid.UseJumpPower
				~= true
			then

				pcall(function()

					humanoid.UseJumpPower =
						true

				end)
			end

			if math.abs(
				humanoid.JumpPower
				- State.JumpPower
			) > 0.01
			then

				pcall(function()

					humanoid.JumpPower =
						State.JumpPower

				end)
			end
		end
	)

--========================================================
-- WALK SPEED CHANGE DETECTOR
--========================================================

local function connectHumanoidSettings(
	humanoid
)

	if not humanoid then
		return
	end

	disconnect(
		"WalkSpeedChanged"
	)

	Connections.WalkSpeedChanged =
		humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(function()

			if math.abs(
				humanoid.WalkSpeed
				- State.WalkSpeed
			) > 0.01
			then

				pcall(function()

					humanoid.WalkSpeed =
						State.WalkSpeed

				end)
			end
		end)

	disconnect(
		"JumpPowerChanged"
	)

	Connections.JumpPowerChanged =
		humanoid:GetPropertyChangedSignal(
			"JumpPower"
		):Connect(function()

			if math.abs(
				humanoid.JumpPower
				- State.JumpPower
			) > 0.01
			then

				pcall(function()

					humanoid.JumpPower =
						State.JumpPower

				end)
			end
		end)
end

--========================================================
-- NO CLIP LOOP
--========================================================

Connections.NoClip =
	RunService.Stepped:Connect(
		function()

			if not State.NoClip then
				return
			end

			local character =
				getCharacter()

			if not character then
				return
			end

			rememberCollision(
				character
			)

			for _, object in ipairs(
				character:GetDescendants()
			) do

				if object:IsA(
					"BasePart"
				) then

					object.CanCollide =
						false
				end
			end
		end
	)

--========================================================
-- CHARACTER ADDED
--========================================================

Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(
		function(character)

			State.Flying =
				false

			State.CurrentTarget =
				nil

			State.CurrentStage =
				nil

			table.clear(
				OriginalCollision
			)

			table.clear(
				State.TargetCache
			)

			local humanoid =
				character:WaitForChild(
					"Humanoid",
					10
				)

			if humanoid then

				task.wait(0.15)

				applyCharacterSettings()

				connectHumanoidSettings(
					humanoid
				)

				if State.NoClip then

					rememberCollision(
						character
					)
				end
			end
		end
	)

--========================================================
-- CHARACTER APPEARANCE
--========================================================

Connections.CharacterAppearance =
	LocalPlayer.CharacterAppearanceLoaded:
		Connect(function()

			task.wait(0.1)

			applyCharacterSettings()

			local humanoid = getHumanoid()

			if humanoid then

				connectHumanoidSettings(humanoid)
			end

			local character = getCharacter()

			if State.NoClip
				and character
			then

				rememberCollision(character)
			end
		end)

--========================================================
-- INITIAL
--========================================================

task.defer(function()

	task.wait(0.2)

	applyCharacterSettings()

	local humanoid = getHumanoid()

	if humanoid then

		connectHumanoidSettings(humanoid)
	end

	local character = getCharacter()

	if State.NoClip
		and character
	then

		rememberCollision(character)
	end
end)

--========================================================
-- GET STATE
--========================================================

function Module.GetState()

	return {

		WalkSpeed = State.WalkSpeed,
		JumpPower = State.JumpPower,

		InfiniteJump = State.InfiniteJump,
		NoClip = State.NoClip,

		Flying = State.Flying,
		FlySpeed = State.FlySpeed,
		FlyHeight = State.FlyHeight,

		CurrentTarget = State.CurrentTarget,
		CurrentStage = State.CurrentStage,
		TargetCount = #WIN_STAGES,
		FoundTargets = State.TargetCache,
		FlyToWinEnabled = ENABLE_FLY_TO_WIN,
	}
end

--========================================================
-- DESTROY
--========================================================

function Module.Destroy()

	State.Flying = false

	State.CurrentTarget = nil

	State.CurrentStage = nil

	for name, connection in pairs(
		Connections
	) do

		if connection then
			connection:Disconnect()
		end

		Connections[name] = nil
	end

	local character = getCharacter()

	if character then restoreCollision(character)
	end

	table.clear(State.TargetCache)
	table.clear(OriginalCollision)
end

return Module
