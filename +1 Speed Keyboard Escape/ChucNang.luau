local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Module = {}

--========================================================
-- CONFIG
--========================================================

local ENABLE_FLY_TO_WIN = true

local ARRIVAL_DISTANCE = 5
local FLY_TIMEOUT = 45
local FLY_SPEED = 90

local TARGET_HEIGHT_OFFSET = 2
local TARGET_HOLD_TIME = 0.8

local STRUCTURE_NAME = "Structure"

local ENABLE_GLOBAL_FALLBACK = false

--========================================================
-- STATE
--========================================================

local State = {
	WalkSpeed = 16,
	JumpPower = 50,

	InfiniteJump = false,
	NoClip = false,

	Flying = false,

	FlySpeed = FLY_SPEED,
	FlyHeight = 0,

	CurrentTarget = nil,
	CurrentStage = nil,

	TargetCache = {},
	StageTargetCache = {},

	Scanning = false,

	AutoFlying = false,
}

local Connections = {}
local OriginalCollision = {}

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
-- UTILITY
--========================================================

local function disconnect(name)
	if Connections[name] then
		Connections[name]:Disconnect()
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

	if not value then
		return fallback
	end

	return math.clamp(value, min, max)
end

local function containsText(text, search)
	if not text then
		return false
	end

	return string.find(
		string.lower(tostring(text)),
		string.lower(search),
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
-- OBJECT TEXT
--========================================================

local function collectObjectText(object)
	if not object then
		return ""
	end

	local texts = {}

	table.insert(texts, tostring(object.Name))

	local parent = object.Parent

	for _ = 1, 12 do
		if not parent then
			break
		end

		table.insert(texts, tostring(parent.Name))
		parent = parent.Parent
	end

	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("TextLabel")
			or descendant:IsA("TextButton")
			or descendant:IsA("TextBox")
		then
			local success, text = pcall(function()
				return descendant.Text
			end)

			if success and text and text ~= "" then
				table.insert(texts, tostring(text))
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

	if part:FindFirstChildOfClass("ClickDetector") then
		return true
	end

	if part:FindFirstChildOfClass("ProximityPrompt") then
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
	name = string.lower(name or "")

	return name:find("npc", 1, true)
		or name:find("enemy", 1, true)
		or name:find("dummy", 1, true)
		or name:find("ballerina", 1, true)
		or name:find("chocolita", 1, true)
		or name == "character"
end

--========================================================
-- NAME SCORE
--========================================================

local function getNameScore(name)
	name = string.lower(name or "")

	local score = 0

	if name == "getwinbutton" then
		score += 50000
	elseif name == "claimwinbutton" then
		score += 50000
	elseif name == "winbutton" then
		score += 45000
	elseif name == "winblock" then
		score += 40000
	end

	if name:find("getwin", 1, true) then
		score += 30000
	end

	if name:find("claimwin", 1, true) then
		score += 30000
	end

	if name:find("winbutton", 1, true) then
		score += 28000
	end

	if name:find("winblock", 1, true) then
		score += 25000
	end

	if name:find("win_button", 1, true) then
		score += 25000
	end

	if name:find("win_block", 1, true) then
		score += 25000
	end

	if name:find("claim", 1, true) then
		score += 18000
	end

	if name:find("finish", 1, true) then
		score += 15000
	end

	if name:find("award", 1, true) then
		score += 15000
	end

	if name:find("button", 1, true) then
		score += 10000
	end

	if name == "win" then
		score += 12000
	end

	if name:find("win", 1, true) then
		score += 8000
	end

	return score
end

--========================================================
-- STAGE CHECK
--========================================================

local function belongsToStage(part, stageNumber)
	if not part then
		return false
	end

	local wanted = {
		"stage" .. stageNumber,
		"stage-" .. stageNumber,
		"stage_" .. stageNumber,
		"stage " .. stageNumber,
	}

	local current = part

	for _ = 1, 15 do
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
-- TARGET SCORE
--========================================================

local function scoreTarget(part, stageNumber)
	if not isBasePart(part) then
		return -math.huge
	end

	local score = 0

	score += getNameScore(part.Name)

	local text = collectObjectText(part)

	--====================================================
	-- TEXT
	--====================================================

	if containsText(text, "Lấy Win")
		or containsText(text, "Lay Win")
		or containsText(text, "Get Win")
		or containsText(text, "Claim Win")
		or containsText(text, "GetWin")
		or containsText(text, "ClaimWin")
	then
		score += 40000
	end

	--====================================================
	-- INTERACTIVE
	--====================================================

	if part:FindFirstChild("TouchInterest") then
		score += 30000
	end

	if part:FindFirstChildOfClass("ProximityPrompt") then
		score += 25000
	end

	if part:FindFirstChildOfClass("ClickDetector") then
		score += 20000
	end

	--====================================================
	-- STAGE
	--====================================================

	if belongsToStage(part, stageNumber) then
		score += 20000
	else
		score -= 10000
	end

	--====================================================
	-- BAD
	--====================================================

	if isBadName(part.Name) then
		score -= 50000
	end

	--====================================================
	-- HITBOX
	--====================================================

	local lowerName = string.lower(part.Name)

	if lowerName == "hitbox"
		or lowerName:find("hitbox", 1, true)
	then
		if hasInteractiveObject(part) then
			score -= 5000
		else
			score -= 40000
		end
	end

	--====================================================
	-- TRANSPARENT
	--====================================================

	if part.Transparency >= 0.99 then
		if hasInteractiveObject(part) then
			score += 5000
		else
			score -= 5000
		end
	end

	return score
end

--========================================================
-- FIND STRUCTURE
--========================================================

local function findStructure()
	local structure = workspace:FindFirstChild(
		STRUCTURE_NAME
	)

	if structure then
		return structure
	end

	return workspace:FindFirstChild(
		STRUCTURE_NAME,
		true
	)
end

--========================================================
-- FIND STAGE
--========================================================

local function findStageContainer(stageNumber)
	local structure = findStructure()

	if not structure then
		return nil
	end

	local names = {
		"Stage" .. stageNumber,
		"Stage-" .. stageNumber,
		"Stage_" .. stageNumber,
		"Stage " .. stageNumber,

		"stage" .. stageNumber,
		"stage-" .. stageNumber,
		"stage_" .. stageNumber,
		"stage " .. stageNumber,
	}

	for _, name in ipairs(names) do
		local child = structure:FindFirstChild(name)

		if child then
			return child
		end
	end

	for _, name in ipairs(names) do
		local child = structure:FindFirstChild(
			name,
			true
		)

		if child then
			return child
		end
	end

	return nil
end

--========================================================
-- FIND TARGET
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

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			scanned += 1

			local score = scoreTarget(
				object,
				stageNumber
			)

			-- Parent tên Win
			local parent = object.Parent

			if parent then

				local parentName =
					string.lower(
						tostring(parent.Name)
					)

				if parentName:find(
					"win",
					1,
					true
				) then
					score += 15000
				end

				if parentName:find(
					"button",
					1,
					true
				) then
					score += 10000
				end
			end

			if score > bestScore then
				bestScore = score
				bestTarget = object
			end
		end
	end

	print(
		("[SCAN] Stage %d parts scanned: %d")
			:format(
				stageNumber,
				scanned
			)
	)

	if bestTarget and bestScore > 0 then

		print(
			("[SCAN] Stage %d best score: %d")
				:format(
					stageNumber,
					bestScore
				)
		)

		print(
			("[SCAN] Stage %d target -> %s")
				:format(
					stageNumber,
					bestTarget:GetFullName()
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

	table.clear(State.StageTargetCache)
	table.clear(State.TargetCache)

	print("")
	print("========================================")
	print("       LPT HUB - WIN TARGET SCAN")
	print("========================================")

	local structure = findStructure()

	if not structure then

		warn(
			"[SCAN] Workspace.Structure NOT FOUND"
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
	-- SCAN 1 -> 15
	--====================================================

	for _, info in ipairs(WIN_STAGES) do

		local stageNumber = info.stage
		local winValue = info.value

		print(
			("[SCAN] Stage %d container -> searching...")
				:format(stageNumber)
		)

		local container =
			findStageContainer(
				stageNumber
			)

		if container then

			print(
				("[SCAN] Stage %d container -> %s")
					:format(
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

		else

			warn(
				("[MISSING] Stage %d container")
					:format(stageNumber)
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
		("Found %d / %d Win targets")
			:format(
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

	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	local target =
		State.StageTargetCache[stageNumber]

	if isBasePart(target) then
		return target
	end

	Module.RefreshTargets()

	return State.StageTargetCache[stageNumber]
end

--========================================================
-- GET STAGE
--========================================================

function Module.GetStage(stageNumber)

	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	for _, info in ipairs(WIN_STAGES) do

		if info.stage == stageNumber then
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

	-- Quan trọng:
	-- Không dùng FlyHeight làm Y mặc định.
	-- Lấy đúng vị trí Part rồi đứng phía trên nó.

	return Vector3.new(
		part.Position.X,
		part.Position.Y
			+ (part.Size.Y / 2)
			+ TARGET_HEIGHT_OFFSET
			+ State.FlyHeight,
		part.Position.Z
	)
end

--========================================================
-- STOP FLY
--========================================================

function Module.StopFlying()

	State.Flying = false
	State.AutoFlying = false

	State.CurrentTarget = nil
	State.CurrentStage = nil

	print("[FLY] STOP")

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

		warn(
			"[FLY] Invalid target"
		)

		return false, "Invalid target"
	end

	if State.Flying then

		warn(
			"[FLY] Already flying"
		)

		return false, "Already flying"
	end

	local character = getCharacter()
	local root = getRoot()
	local humanoid = getHumanoid()

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

	local startPosition = root.Position
	local targetPosition = getTargetPosition(part)

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
		"[FLY] Start:",
		tostring(startPosition)
	)
	print(
		"[FLY] Destination:",
		tostring(targetPosition)
	)
	print(
		"[FLY] Distance:",
		string.format(
			"%.2f",
			(startPosition - targetPosition).Magnitude
		)
	)
	print(
		"[FLY] Speed:",
		State.FlySpeed
	)
	print("========================================")

	--====================================================
	-- SAVE HUMANOID
	--====================================================

	local oldAutoRotate =
		humanoid.AutoRotate

	local oldPlatformStand =
		humanoid.PlatformStand

	pcall(function()
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end)

	local startTime = os.clock()
	local lastPrint = 0

	local reached = false

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

		targetPosition =
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
				"[FLY] Arrived! Distance:",
				string.format(
					"%.2f",
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

		--================================================
		-- MOVEMENT
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

		local nextPosition =
			current
			+ difference.Unit * step

		--================================================
		-- MOVE
		--================================================

		pcall(function()

			root.CFrame =
				CFrame.new(
					nextPosition
				)

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			humanoid.PlatformStand =
				true

			humanoid.AutoRotate =
				false

		end)

		--================================================
		-- DEBUG
		--================================================

		if os.clock() - lastPrint >= 0.5 then

			lastPrint = os.clock()

			print(
				(
					"[FLY] MOVING | Stage %s | Distance %.2f"
				):format(
					tostring(
						stageNumber or "?"
					),
					(root.Position - targetPosition).Magnitude
				)
			)
		end
	end

	--====================================================
	-- HOLD
	--====================================================

	if reached
		and State.Flying
		and root.Parent
		and part.Parent
	then

		print(
			"[FLY] Holding target..."
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

					root.CFrame =
						CFrame.new(
							finalPosition
						)

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

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

		humanoid.WalkSpeed =
			State.WalkSpeed

		humanoid.JumpPower =
			State.JumpPower

	end)

	State.Flying = false
	State.CurrentTarget = nil
	State.CurrentStage = nil

	if reached then

		print(
			(
				"[FLY] SUCCESS | Stage %s | Time %.2fs"
			):format(
				tostring(
					stageNumber or "?"
				),
				elapsed
			)
		)

		print("")

		return true
	end

	warn(
		(
			"[FLY] FAILED | Stage %s | Time %.2fs"
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

	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return false, "Invalid stage"
	end

	local stageInfo =
		Module.GetStage(stageNumber)

	if not stageInfo then
		return false, "Stage does not exist"
	end

	--====================================================
	-- TARGET CACHE
	--====================================================

	local target =
		State.StageTargetCache[
			stageNumber
		]

	--====================================================
	-- RESCAN IF NEEDED
	--====================================================

	if not isBasePart(target) then

		print(
			(
				"[FLY] Stage %d target not cached. Scanning..."
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
	-- FAIL
	--====================================================

	if not isBasePart(target) then

		warn(
			(
				"[FLY] No target for Stage %d"
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
	-- LOG
	--====================================================

	print("")
	print(
		(
			"[FLY] Request Stage %d | +%s Win"
		):format(
			stageNumber,
			tostring(stageInfo.value)
		)
	)

	print(
		"[FLY] Target:",
		target:GetFullName()
	)

	--====================================================
	-- FLY
	--====================================================

	return Module.FlyToPart(
		target,
		stageNumber
	)
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(winAmount)

	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount"
	end

	local stageNumber = nil

	for _, info in ipairs(WIN_STAGES) do

		if info.value == winAmount then

			stageNumber =
				info.stage

			break
		end
	end

	if not stageNumber then

		return false,
			(
				"No stage for +%s Win"
			):format(
				tostring(winAmount)
			)
	end

	print(
		(
			"[FlyToWin] +%s Win -> Stage %d"
		):format(
			tostring(winAmount),
			stageNumber
		)
	)

	return Module.FlyToStage(
		stageNumber
	)
end

--========================================================
-- AUTO FLY ALL STAGES
--========================================================

function Module.AutoFlyAllStages()

	if State.AutoFlying then

		warn(
			"[AUTO FLY] Already running"
		)

		return false,
			"Already running"
	end

	if State.Flying then

		warn(
			"[AUTO FLY] Player is already flying"
		)

		return false,
			"Already flying"
	end

	--====================================================
	-- SCAN FIRST
	--====================================================

	print("")
	print("========================================")
	print("[AUTO FLY] START")
	print("========================================")

	Module.RefreshTargets()

	--====================================================
	-- CHECK
	--====================================================

	local found = 0

	for stage = 1, #WIN_STAGES do

		if isBasePart(
			State.StageTargetCache[stage]
		) then
			found += 1
		end
	end

	print(
		("[AUTO FLY] Targets: %d / %d")
			:format(
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
	-- RUN
	--====================================================

	State.AutoFlying = true

	task.spawn(function()

		for _, info in ipairs(WIN_STAGES) do

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

			if isBasePart(target) then

				print("")
				print(
					(
						"[AUTO FLY] >>> Stage %d | +%s Win"
					):format(
						stage,
						tostring(info.value)
					)
				)

				local success =
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
							"[AUTO FLY] Stage %d FAILED"
						):format(
							stage
						)
					)
				end

				task.wait(0.5)

			else

				warn(
					(
						"[AUTO FLY] Stage %d MISSING - SKIP"
					):format(
						stage
					)
				)
			end
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

	State.AutoFlying = false

	if State.Flying then
		Module.StopFlying()
	end

	print(
		"[AUTO FLY] STOP REQUESTED"
	)
end

--========================================================
-- HEARTBEAT CHARACTER SETTINGS
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
			) > 0.01
			then

				pcall(function()
					humanoid.WalkSpeed =
						State.WalkSpeed
				end)

			end
		end

		if humanoid.UseJumpPower ~= true then

			pcall(function()
				humanoid.UseJumpPower = true
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

				object.CanCollide = false

			end
		end
	end)

--========================================================
-- CHARACTER ADDED
--========================================================

Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(function(character)

		State.Flying = false
		State.AutoFlying = false

		State.CurrentTarget = nil
		State.CurrentStage = nil

		table.clear(OriginalCollision)

		table.clear(State.TargetCache)
		table.clear(State.StageTargetCache)

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

			if State.NoClip then
				rememberCollision(character)
			end
		end
	end)

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

	return {

		WalkSpeed = State.WalkSpeed,
		JumpPower = State.JumpPower,

		InfiniteJump = State.InfiniteJump,
		NoClip = State.NoClip,

		Flying = State.Flying,

		AutoFlying = State.AutoFlying,
		FlySpeed = State.FlySpeed,
		FlyHeight = State.FlyHeight,

		CurrentTarget = State.CurrentTarget,
		CurrentStage = State.CurrentStage,

		TargetCount = #WIN_STAGES,
		FoundTargets = State.StageTargetCache,
		Scanning = State.Scanning,
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
			connection:Disconnect()
		end

		Connections[name] = nil
	end

	local character =
		getCharacter()

	if character then
		restoreCollision(character)
	end

	table.clear(State.TargetCache)
	table.clear(State.StageTargetCache)
	table.clear(OriginalCollision)
end

return Module
