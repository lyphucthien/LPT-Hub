local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Module = {}

--========================================================
-- CONFIG
--========================================================

local ENABLE_FLY_TO_WIN = true

local ARRIVAL_DISTANCE = 4
local FLY_TIMEOUT = 45
local FLY_SPEED = 90

local TARGET_HEIGHT_OFFSET = 2
local TARGET_HOLD_TIME = 0.8

local STRUCTURE_NAME = "Structure"

-- Scanner tìm Stage rộng hơn
local MAX_STAGE_SEARCH_DEPTH = 20
local MAX_PARENT_SEARCH_DEPTH = 20

--========================================================
-- WIN STAGES
--========================================================

local WIN_STAGES = {
	{stage = 1, value = 1},
	{stage = 2, value = 3},
	{stage = 3, value = 10},
	{stage = 4, value = 20},
	{stage = 5, value = 60},
	{stage = 6, value = 100},
	{stage = 7, value = 150},
	{stage = 8, value = 300},
	{stage = 9, value = 500},
	{stage = 10, value = 1000},
	{stage = 11, value = 2500},
	{stage = 12, value = 10000},
	{stage = 13, value = 25000},
	{stage = 14, value = 50000},
	{stage = 15, value = 150000},
}

--========================================================
-- STATE
--========================================================

local State = {
	WalkSpeed = 16,
	JumpPower = 50,

	InfiniteJump = false,
	NoClip = false,

	Flying = false,
	AutoFlying = false,

	FlySpeed = FLY_SPEED,
	FlyHeight = 0,

	CurrentTarget = nil,
	CurrentStage = nil,

	TargetCache = {},
	StageTargetCache = {},

	StageContainerCache = {},

	Scanning = false,
}

local Connections = {}
local OriginalCollision = {}

--========================================================
-- UTILITY
--========================================================

local function disconnect(name)
	if Connections[name] then
		pcall(function()
			Connections[name]:Disconnect()
		end)

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

local function isBasePart(object)
	return object
		and object:IsA("BasePart")
		and object.Parent ~= nil
end

local function getNumber(value, min, max, fallback)
	value = tonumber(value)

	if value == nil then
		return fallback
	end

	return math.clamp(value, min, max)
end

local function lower(value)
	return string.lower(tostring(value or ""))
end

local function containsText(text, search)
	return string.find(
		lower(text),
		lower(search),
		1,
		true
	) ~= nil
end

--========================================================
-- CHARACTER
--========================================================

local function applyCharacterSettings()
	local humanoid = getHumanoid()

	if not humanoid then
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

	if not State.Flying then
		applyCharacterSettings()
	end

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

	if not State.Flying then
		applyCharacterSettings()
	end

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

				if humanoid then
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
				OriginalCollision[object] =
					object.CanCollide
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
-- OBJECT TEXT
--========================================================

local function collectObjectText(object)
	if not object then
		return ""
	end

	local texts = {}

	table.insert(
		texts,
		tostring(object.Name)
	)

	local parent = object.Parent

	for _ = 1, MAX_PARENT_SEARCH_DEPTH do
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

			local success, text =
				pcall(function()
					return descendant.Text
				end)

			if success
				and text
				and text ~= ""
			then

				table.insert(
					texts,
					tostring(text)
				)
			end
		end
	end

	return table.concat(texts, " ")
end

--========================================================
-- INTERACTIVE
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
-- BAD OBJECT
--========================================================

local function isBadName(name)
	name = lower(name)

	return name:find("npc", 1, true)
		or name:find("enemy", 1, true)
		or name:find("dummy", 1, true)
		or name:find("ballerina", 1, true)
		or name:find("chocolita", 1, true)
		or name == "character"
end

--========================================================
-- STAGE NAME
--========================================================

local function getStageNumberFromName(name)
	name = lower(name)

	-- Stage15
	local number =
		name:match("^stage(%d+)$")

	if number then
		return tonumber(number)
	end

	-- Stage-15
	number =
		name:match("^stage%-(%d+)$")

	if number then
		return tonumber(number)
	end

	-- Stage_15
	number =
		name:match("^stage_(%d+)$")

	if number then
		return tonumber(number)
	end

	-- Stage 15
	number =
		name:match("^stage%s+(%d+)$")

	if number then
		return tonumber(number)
	end

	-- 15Stage
	number =
		name:match("^(%d+)stage$")

	if number then
		return tonumber(number)
	end

	return nil
end

--========================================================
-- CHECK STAGE
--========================================================

local function belongsToStage(part, stageNumber)
	if not part then
		return false
	end

	local current = part

	for _ = 1, MAX_PARENT_SEARCH_DEPTH do

		if not current then
			break
		end

		local detected =
			getStageNumberFromName(
				current.Name
			)

		if detected == stageNumber then
			return true
		end

		current = current.Parent
	end

	return false
end

--========================================================
-- FIND STRUCTURE
--========================================================

local function findStructure()

	local direct =
		workspace:FindFirstChild(
			STRUCTURE_NAME
		)

	if direct then
		return direct
	end

	local recursive =
		workspace:FindFirstChild(
			STRUCTURE_NAME,
			true
		)

	if recursive then
		return recursive
	end

	-- fallback tìm case-insensitive
	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if lower(object.Name)
			== lower(STRUCTURE_NAME)
		then
			return object
		end
	end

	return nil
end

--========================================================
-- FIND STAGE CONTAINER
--========================================================

local function findStageContainer(stageNumber)

	if State.StageContainerCache[
		stageNumber
	] then

		local cached =
			State.StageContainerCache[
				stageNumber
			]

		if cached and cached.Parent then
			return cached
		end
	end

	local structure =
		findStructure()

	if not structure then
		return nil
	end

	--====================================================
	-- METHOD 1
	-- Exact child
	--====================================================

	for _, child in ipairs(
		structure:GetChildren()
	) do

		local detected =
			getStageNumberFromName(
				child.Name
			)

		if detected == stageNumber then

			State.StageContainerCache[
				stageNumber
			] = child

			return child
		end
	end

	--====================================================
	-- METHOD 2
	-- Recursive descendants
	--====================================================

	for _, object in ipairs(
		structure:GetDescendants()
	) do

		local detected =
			getStageNumberFromName(
				object.Name
			)

		if detected == stageNumber then

			State.StageContainerCache[
				stageNumber
			] = object

			return object
		end
	end

	--====================================================
	-- METHOD 3
	-- Container contains Stage number in name
	--====================================================

	for _, object in ipairs(
		structure:GetDescendants()
	) do

		local name = lower(object.Name)

		if name:find("stage", 1, true) then

			local number =
				name:match("(%d+)")

			if number
				and tonumber(number)
					== stageNumber
			then

				State.StageContainerCache[
					stageNumber
				] = object

				return object
			end
		end
	end

	return nil
end

--========================================================
-- NAME SCORE
--========================================================

local function getNameScore(name)
	name = lower(name)

	local score = 0

	if name == "getwinbutton" then
		score += 100000
	elseif name == "claimwinbutton" then
		score += 100000
	elseif name == "winbutton" then
		score += 90000
	elseif name == "getwin" then
		score += 85000
	elseif name == "claimwin" then
		score += 80000
	elseif name == "winblock" then
		score += 75000
	elseif name == "win" then
		score += 70000
	end

	if name:find("getwin", 1, true) then
		score += 50000
	end

	if name:find("claimwin", 1, true) then
		score += 50000
	end

	if name:find("winbutton", 1, true) then
		score += 45000
	end

	if name:find("win_button", 1, true) then
		score += 45000
	end

	if name:find("claim", 1, true) then
		score += 30000
	end

	if name:find("finish", 1, true) then
		score += 25000
	end

	if name:find("award", 1, true) then
		score += 25000
	end

	if name:find("button", 1, true) then
		score += 20000
	end

	if name == "win" then
		score += 20000
	end

	if name:find("win", 1, true) then
		score += 15000
	end

	return score
end

--========================================================
-- TARGET SCORE
--========================================================

local function scoreTarget(part, stageNumber)
	if not isBasePart(part) then
		return -math.huge
	end

	local score = 0

	-- Name
	score += getNameScore(part.Name)

	-- Text
	local text =
		collectObjectText(part)

	if containsText(text, "lấy win")
		or containsText(text, "lay win")
		or containsText(text, "get win")
		or containsText(text, "claim win")
		or containsText(text, "getwin")
		or containsText(text, "claimwin")
		or containsText(text, "take win")
		or containsText(text, "win")
	then
		score += 50000
	end

	-- Interactive
	if part:FindFirstChild("TouchInterest") then
		score += 35000
	end

	if part:FindFirstChildOfClass(
		"ProximityPrompt"
	) then
		score += 30000
	end

	if part:FindFirstChildOfClass(
		"ClickDetector"
	) then
		score += 25000
	end

	-- Stage
	if belongsToStage(
		part,
		stageNumber
	) then
		score += 30000
	else
		score -= 30000
	end

	-- Parent names
	local parent = part.Parent

	for _ = 1, 5 do

		if not parent then
			break
		end

		local parentName =
			lower(parent.Name)

		if parentName:find(
			"win",
			1,
			true
		) then
			score += 25000
		end

		if parentName:find(
			"button",
			1,
			true
		) then
			score += 15000
		end

		if parentName:find(
			"claim",
			1,
			true
		) then
			score += 20000
		end

		parent = parent.Parent
	end

	-- Bad objects
	if isBadName(part.Name) then
		score -= 100000
	end

	-- Hitbox
	local name = lower(part.Name)

	if name == "hitbox"
		or name:find("hitbox", 1, true)
	then

		if hasInteractiveObject(part) then
			score -= 5000
		else
			score -= 50000
		end
	end

	-- Transparent
	if part.Transparency >= 0.99 then

		if hasInteractiveObject(part) then
			score += 5000
		else
			score -= 10000
		end
	end

	return score
end

--========================================================
-- FIND TARGET IN STAGE
--========================================================

local function findTargetInStage(
	container,
	stageNumber
)

	if not container then
		return nil
	end

	local bestTarget = nil
	local bestScore = -math.huge
	local scanned = 0

	--====================================================
	-- Search every BasePart
	--====================================================

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			scanned += 1

			local score =
				scoreTarget(
					object,
					stageNumber
				)

			if score > bestScore then
				bestScore = score
				bestTarget = object
			end
		end
	end

	--====================================================
	-- Container itself
	--====================================================

	if container:IsA("BasePart") then

		local score =
			scoreTarget(
				container,
				stageNumber
			)

		if score > bestScore then
			bestScore = score
			bestTarget = container
		end
	end

	print(
		(
			"[SCAN] Stage %d | Parts scanned: %d | Best score: %d"
		):format(
			stageNumber,
			scanned,
			bestScore
		)
	)

	if bestTarget
		and bestScore > 0
	then

		print(
			(
				"[SCAN] Stage %d target -> %s"
			):format(
				stageNumber,
				bestTarget:GetFullName()
			)
		)

		print(
			(
				"[SCAN] Stage %d position -> %s"
			):format(
				stageNumber,
				tostring(
					bestTarget.Position
				)
			)
		)

		return bestTarget
	end

	return nil
end

--========================================================
-- REFRESH TARGETS
--========================================================

function Module.RefreshTargets()

	if State.Scanning then
		return State.StageTargetCache
	end

	State.Scanning = true

	table.clear(
		State.TargetCache
	)

	table.clear(
		State.StageTargetCache
	)

	table.clear(
		State.StageContainerCache
	)

	print("")
	print("========================================")
	print("       LPT HUB - WIN TARGET SCAN")
	print("========================================")

	local structure =
		findStructure()

	if not structure then

		warn(
			"[SCAN] Structure NOT FOUND"
		)

		State.Scanning = false

		return State.StageTargetCache
	end

	print(
		"[SCAN] Structure -> "
			.. structure:GetFullName()
	)

	print("")

	--====================================================
	-- Scan all stages
	--====================================================

	for _, info in ipairs(
		WIN_STAGES
	) do

		local stageNumber =
			info.stage

		local winValue =
			info.value

		print(
			(
				"[SCAN] Stage %d -> searching..."
			):format(
				stageNumber
			)
		)

		local container =
			findStageContainer(
				stageNumber
			)

		if container then

			print(
				(
					"[SCAN] Stage %d container -> %s"
				):format(
					stageNumber,
					container:GetFullName()
				)
			)

			local target =
				findTargetInStage(
					container,
					stageNumber
				)

			if isBasePart(target) then

				State.StageTargetCache[
					stageNumber
				] = target

				State.TargetCache[
					winValue
				] = target

				print(
					(
						"[FOUND] Stage %d | +%s Win | %s"
					):format(
						stageNumber,
						tostring(winValue),
						target:GetFullName()
					)
				)

			else

				warn(
					(
						"[MISSING] Stage %d target"
					):format(
						stageNumber
					)
				)
			end

		else

			warn(
				(
					"[MISSING] Stage %d container"
				):format(
					stageNumber
				)
			)
		end

		task.wait()
	end

	State.Scanning = false

	local found = 0

	for stage = 1, #WIN_STAGES do

		if isBasePart(
			State.StageTargetCache[stage]
		) then

			found += 1
		end
	end

	print("")
	print("----------------------------------------")

	print(
		(
			"Found %d / %d Win targets"
		):format(
			found,
			#WIN_STAGES
		)
	)

	print("----------------------------------------")
	print("")

	return State.StageTargetCache
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
-- GET STAGE TARGET
--========================================================

function Module.GetStageTarget(stageNumber)

	stageNumber =
		tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	local target =
		State.StageTargetCache[
			stageNumber
		]

	if isBasePart(target) then
		return target
	end

	Module.RefreshTargets()

	return State.StageTargetCache[
		stageNumber
	]
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

	for _, info in ipairs(
		WIN_STAGES
	) do

		if info.stage
			== stageNumber
		then
			return info
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

	return Vector3.new(
		part.Position.X,
		part.Position.Y
			+ part.Size.Y / 2
			+ TARGET_HEIGHT_OFFSET
			+ State.FlyHeight,
		part.Position.Z
	)
end

--========================================================
-- STOP ONLY CURRENT FLY
--========================================================

function Module.StopFlying()

	if not State.Flying then
		return
	end

	print("[FLY] STOP REQUESTED")

	State.Flying = false

	-- KHÔNG tắt AutoFlying ở đây.
	--
	-- Đây là điểm quan trọng của bản sửa.
	--
	-- FlyToPart() kết thúc sẽ tự xử lý CurrentTarget.
	-- AutoFlyAllStages() vẫn kiểm soát AutoFlying riêng.

	State.CurrentTarget = nil
	State.CurrentStage = nil
end

function Module.IsFlying()
	return State.Flying
end

function Module.IsAutoFlying()
	return State.AutoFlying
end

--========================================================
-- FLY TO PART
--========================================================

function Module.FlyToPart(
	part,
	stageNumber
)

	if not ENABLE_FLY_TO_WIN then
		return false, "Fly disabled"
	end

	if not isBasePart(part) then
		return false, "Invalid target"
	end

	if State.Flying then
		return false, "Already flying"
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
		return false, "HumanoidRootPart nil"
	end

	if not humanoid then
		return false, "Humanoid nil"
	end

	if not part.Parent then
		return false, "Target disappeared"
	end

	--====================================================
	-- START
	--====================================================

	State.Flying = true
	State.CurrentTarget = part
	State.CurrentStage = stageNumber

	local oldAutoRotate =
		humanoid.AutoRotate

	local oldPlatformStand =
		humanoid.PlatformStand

	pcall(function()
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end)

	local startTime =
		os.clock()

	local reached = false
	local lastPrint = 0

	print("")
	print("========================================")
	print("[FLY] START")
	print(
		"[FLY] Stage:",
		stageNumber or "?"
	)
	print(
		"[FLY] Target:",
		part:GetFullName()
	)
	print(
		"[FLY] Target Position:",
		tostring(part.Position)
	)
	print("========================================")

	--====================================================
	-- FLY LOOP
	--====================================================

	while
		State.Flying
		and character.Parent
		and root.Parent
		and part.Parent
		and os.clock() - startTime < FLY_TIMEOUT
	do

		local targetPosition =
			getTargetPosition(part)

		if not targetPosition then
			break
		end

		local current =
			root.Position

		local difference =
			targetPosition - current

		local distance =
			difference.Magnitude

		--================================================
		-- ARRIVED
		--================================================

		if distance <= ARRIVAL_DISTANCE then

			reached = true

			print(
				(
					"[FLY] ARRIVED | Stage %s | Distance %.2f"
				):format(
					tostring(
						stageNumber or "?"
					),
					distance
				)
			)

			break
		end

		--================================================
		-- HEARTBEAT
		--================================================

		local dt =
			RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		if not root.Parent then
			break
		end

		--================================================
		-- SPEED
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

		local direction =
			difference.Unit

		local nextPosition =
			current
				+ direction * step

		--================================================
		-- MOVE
		--================================================

		pcall(function()

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			root.CFrame =
				CFrame.new(
					nextPosition
				)

			humanoid.PlatformStand =
				true

			humanoid.AutoRotate =
				false

		end)

		--================================================
		-- DEBUG
		--================================================

		if os.clock() - lastPrint >= 0.5 then

			lastPrint =
				os.clock()

			print(
				(
					"[FLY] MOVING | Stage %s | Distance %.2f"
				):format(
					tostring(
						stageNumber or "?"
					),
					(
						root.Position
							- targetPosition
					).Magnitude
				)
			)
		end
	end

	--====================================================
	-- HOLD TARGET
	--====================================================

	if reached
		and State.Flying
		and root.Parent
		and part.Parent
	then

		print(
			"[FLY] HOLDING TARGET"
		)

		local holdStart =
			os.clock()

		while
			State.Flying
			and root.Parent
			and part.Parent
			and os.clock() - holdStart
				< TARGET_HOLD_TIME
		do

			local finalPosition =
				getTargetPosition(part)

			if finalPosition then

				pcall(function()

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

					root.CFrame =
						CFrame.new(
							finalPosition
						)

				end)
			end

			RunService.Heartbeat:Wait()
		end
	end

	--====================================================
	-- RESULT
	--====================================================

	local elapsed =
		os.clock() - startTime

	pcall(function()

		humanoid.AutoRotate =
			oldAutoRotate

		humanoid.PlatformStand =
			oldPlatformStand

		if not State.Flying then
			humanoid.WalkSpeed =
				State.WalkSpeed

			humanoid.JumpPower =
				State.JumpPower
		end

	end)

	local wasStopped =
		not State.Flying

	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

	if reached then

		print(
			(
				"[FLY] SUCCESS | Stage %s | %.2fs"
			):format(
				tostring(
					stageNumber or "?"
				),
				elapsed
			)
		)

		return true
	end

	if wasStopped then

		warn(
			(
				"[FLY] STOPPED | Stage %s"
			):format(
				tostring(
					stageNumber or "?"
				)
			)
		)

		return false, "Stopped"
	end

	warn(
		(
			"[FLY] FAILED | Stage %s | %.2fs"
		):format(
			tostring(
				stageNumber or "?"
			),
			elapsed
		)
	)

	return false,
		"Could not reach target"
end

--========================================================
-- FLY TO STAGE
--========================================================

function Module.FlyToStage(stageNumber)

	stageNumber =
		tonumber(stageNumber)

	if not stageNumber then
		return false, "Invalid stage"
	end

	local stageInfo =
		Module.GetStage(
			stageNumber
		)

	if not stageInfo then
		return false, "Stage does not exist"
	end

	--====================================================
	-- GET CACHE
	--====================================================

	local target =
		State.StageTargetCache[
			stageNumber
		]

	--====================================================
	-- VALID CACHE?
	--====================================================

	if not isBasePart(target) then

		print(
			(
				"[FLY] Stage %d target missing -> RESCAN"
			):format(
				stageNumber
			)
		)

		Module.RefreshTargets()

		target =
			State.StageTargetCache[
				stageNumber
			]
	end

	--====================================================
	-- STILL MISSING
	--====================================================

	if not isBasePart(target) then

		warn(
			(
				"[FLY] Stage %d has NO target"
			):format(
				stageNumber
			)
		)

		return false,
			(
				"No target for Stage %d"
			):format(
				stageNumber
			)
	end

	--====================================================
	-- FLY
	--====================================================

	print("")
	print(
		(
			"[FLY] REQUEST | Stage %d | +%s Win"
		):format(
			stageNumber,
			tostring(
				stageInfo.value
			)
		)
	)

	print(
		"[FLY] Target:",
		target:GetFullName()
	)

	return Module.FlyToPart(
		target,
		stageNumber
	)
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(winAmount)

	winAmount =
		tonumber(winAmount)

	if not winAmount then
		return false,
			"Invalid Win amount"
	end

	for _, info in ipairs(
		WIN_STAGES
	) do

		if info.value
			== winAmount
		then

			return Module.FlyToStage(
				info.stage
			)
		end
	end

	return false,
		(
			"No stage for +%s Win"
		):format(
			tostring(winAmount)
		)
end

--========================================================
-- AUTO FLY ALL STAGES
--========================================================

function Module.AutoFlyAllStages()

	if State.AutoFlying then
		return false,
			"Already running"
	end

	if State.Flying then
		return false,
			"Already flying"
	end

	print("")
	print("========================================")
	print("[AUTO FLY] START")
	print("========================================")

	--====================================================
	-- SCAN
	--====================================================

	Module.RefreshTargets()

	local found = 0

	for _, info in ipairs(
		WIN_STAGES
	) do

		if isBasePart(
			State.StageTargetCache[
				info.stage
			]
		) then

			found += 1
		end
	end

	print(
		(
			"[AUTO FLY] Targets found: %d / %d"
		):format(
			found,
			#WIN_STAGES
		)
	)

	if found == 0 then

		warn(
			"[AUTO FLY] No targets found"
		)

		return false,
			"No targets found"
	end

	--====================================================
	-- START AUTO STATE
	--====================================================

	State.AutoFlying = true

	task.spawn(function()

		for _, info in ipairs(
			WIN_STAGES
		) do

			--================================================
			-- STOP CHECK
			--================================================

			if not State.AutoFlying then

				print(
					"[AUTO FLY] STOPPED"
				)

				break
			end

			local stage =
				info.stage

			local target =
				State.StageTargetCache[
					stage
				]

			--================================================
			-- MISSING TARGET
			--================================================

			if not isBasePart(target) then

				warn(
					(
						"[AUTO FLY] Stage %d missing -> SKIP"
					):format(
						stage
					)
				)

				continue
			end

			print("")
			print(
				(
					"[AUTO FLY] >>> Stage %d | +%s Win"
				):format(
					stage,
					tostring(info.value)
				)
			)

			--================================================
			-- FLY
			--================================================

			local success, reason =
				Module.FlyToPart(
					target,
					stage
				)

			if success then

				print(
					(
						"[AUTO FLY] Stage %d SUCCESS"
					):format(
						stage
					)
				)

			else

				warn(
					(
						"[AUTO FLY] Stage %d FAILED: %s"
					):format(
						stage,
						tostring(reason)
					)
				)

				-- Nếu user bấm Stop thì thoát
				if not State.AutoFlying then
					break
				end
			end

			task.wait(0.5)
		end

		State.AutoFlying = false

		print("")
		print("========================================")
		print("[AUTO FLY] FINISHED")
		print("========================================")
		print("")
	end)

	return true
end

--========================================================
-- STOP AUTO FLY
--========================================================

function Module.StopAutoFly()

	if not State.AutoFlying
		and not State.Flying
	then
		return
	end

	print(
		"[AUTO FLY] STOP REQUESTED"
	)

	-- Chỉ AutoFly bị tắt
	State.AutoFlying = false

	-- Nếu đang bay thì dừng fly
	if State.Flying then
		State.Flying = false
	end

	State.CurrentTarget = nil
	State.CurrentStage = nil
end

--========================================================
-- CHARACTER SETTINGS LOOP
--========================================================

Connections.CharacterSettings =
	RunService.Heartbeat:Connect(function()

		local humanoid =
			getHumanoid()

		if not humanoid then
			return
		end

		if not State.Flying then

			if math.abs(
				humanoid.WalkSpeed
					- State.WalkSpeed
			) > 0.01 then

				pcall(function()
					humanoid.WalkSpeed =
						State.WalkSpeed
				end)
			end
		end

		if humanoid.UseJumpPower ~= true then

			pcall(function()
				humanoid.UseJumpPower =
					true
			end)
		end

		if not State.Flying then

			if math.abs(
				humanoid.JumpPower
					- State.JumpPower
			) > 0.01 then

				pcall(function()
					humanoid.JumpPower =
						State.JumpPower
				end)
			end
		end
	end)

--========================================================
-- NO CLIP LOOP
--========================================================

Connections.NoClip =
	RunService.Stepped:Connect(function()

		if not State.NoClip then
			return
		end

		local character =
			getCharacter()

		if not character then
			return
		end

		rememberCollision(character)

		for _, object in ipairs(
			character:GetDescendants()
		) do

			if object:IsA("BasePart") then

				pcall(function()
					object.CanCollide = false
				end)

			end
		end
	end)

--========================================================
-- CHARACTER ADDED
--========================================================

Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(
		function(character)

			-- Reset movement
			State.Flying = false
			State.AutoFlying = false

			State.CurrentTarget = nil
			State.CurrentStage = nil

			table.clear(
				OriginalCollision
			)

			table.clear(
				State.TargetCache
			)

			table.clear(
				State.StageTargetCache
			)

			table.clear(
				State.StageContainerCache
			)

			local humanoid =
				character:WaitForChild(
					"Humanoid",
					10
				)

			if humanoid then

				task.wait(0.15)

				applyCharacterSettings()

				disconnect(
					"HumanoidSettings"
				)

				Connections.HumanoidSettings =
					humanoid:GetPropertyChangedSignal(
						"WalkSpeed"
					):Connect(function()

						if State.Flying then
							return
						end

						if math.abs(
							humanoid.WalkSpeed
								- State.WalkSpeed
						) > 0.01 then

							pcall(function()

								humanoid.WalkSpeed =
									State.WalkSpeed

							end)
						end
					end)

				if State.NoClip then
					rememberCollision(
						character
					)
				end
			end
		end
	)

--========================================================
-- INITIAL
--========================================================

task.defer(function()

	task.wait(0.5)

	applyCharacterSettings()

	local humanoid =
		getHumanoid()

	if humanoid then

		pcall(function()
			humanoid.UseJumpPower = true
		end)
	end
end)

--========================================================
-- GET STATE
--========================================================

function Module.GetState()

	local foundTargets = 0

	for _, info in ipairs(
		WIN_STAGES
	) do

		if isBasePart(
			State.StageTargetCache[
				info.stage
			]
		) then

			foundTargets += 1
		end
	end

	return {

		WalkSpeed =
			State.WalkSpeed,

		JumpPower =
			State.JumpPower,

		InfiniteJump =
			State.InfiniteJump,

		NoClip =
			State.NoClip,

		Flying =
			State.Flying,

		AutoFlying =
			State.AutoFlying,

		FlySpeed =
			State.FlySpeed,

		FlyHeight =
			State.FlyHeight,

		CurrentTarget =
			State.CurrentTarget,

		CurrentStage =
			State.CurrentStage,

		TargetCount =
			#WIN_STAGES,

		FoundTargetCount =
			foundTargets,

		FoundTargets =
			State.StageTargetCache,

		StageContainers =
			State.StageContainerCache,

		Scanning =
			State.Scanning,
	}
end

--========================================================
-- DESTROY
--========================================================

function Module.Destroy()

	State.Flying = false
	State.AutoFlying = false

	State.CurrentTarget = nil
	State.CurrentStage = nil

	for name, connection in pairs(
		Connections
	) do

		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end

		Connections[name] = nil
	end

	local character =
		getCharacter()

	if character then
		restoreCollision(character)
	end

	table.clear(
		State.TargetCache
	)

	table.clear(
		State.StageTargetCache
	)

	table.clear(
		State.StageContainerCache
	)

	table.clear(
		OriginalCollision
	)
end

return Module
