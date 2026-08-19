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

-- Đứng phía trên target một chút
local FLY_ABOVE_TARGET = true
local TARGET_HEIGHT_OFFSET = 2

-- Khi tới target sẽ giữ vị trí một lúc
-- để TouchInterest / ProximityPrompt có cơ hội nhận
local TARGET_HOLD_TIME = 0.5

-- Không dùng cùng một Part cho nhiều Stage
local ALLOW_DUPLICATE_TARGET = false

-- Tên Structure chính
local STRUCTURE_NAME = "Structure"

-- Chỉ fallback Workspace scan nếu không tìm được container Stage
local ENABLE_GLOBAL_FALLBACK = true

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
	StageTargetCache = {},

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

			if suffix == "k"
				or suffix == "K"
			then
				return n * 1000
			end

			if suffix == "m"
				or suffix == "M"
			then
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

	if not humanoid
		or not humanoid.Parent
	then
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
			UserInputService.JumpRequest:Connect(
				function()

					if not State.InfiniteJump then
						return
					end

					local humanoid = getHumanoid()

					if humanoid
						and humanoid.Parent
					then

						pcall(function()

							humanoid:ChangeState(
								Enum.HumanoidStateType.Jumping
							)

						end)
					end
				end
			)
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

	for _, object in ipairs(
		character:GetDescendants()
	) do

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

	for object, original in pairs(
		OriginalCollision
	) do

		if object
			and object.Parent
		then

			pcall(function()

				object.CanCollide =
					original

			end)
		end
	end

	table.clear(OriginalCollision)
end

function Module.SetNoClip(enabled)

	State.NoClip =
		enabled == true

	local character =
		getCharacter()

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

	table.insert(
		texts,
		tostring(object.Name)
	)

	local parent = object.Parent

	for _ = 1, 12 do

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
			then

				table.insert(
					texts,
					tostring(text)
				)
			end
		end
	end

	return table.concat(
		texts,
		" "
	)
end

--========================================================
-- INTERACTIVE CHECK
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

	if part:FindFirstChild(
		"TouchInterest"
	) then
		return true
	end

	return false
end

--========================================================
-- NAME CHECK
--========================================================

local function isBadNPCName(name)

	name = string.lower(
		name or ""
	)

	return name:find(
		"npc",
		1,
		true
	)
	or name:find(
		"ballerina",
		1,
		true
	)
	or name:find(
		"chocolita",
		1,
		true
	)
	or name:find(
		"enemy",
		1,
		true
	)
	or name:find(
		"dummy",
		1,
		true
	)
	or name == "character"
end

local function isHitboxName(name)

	name = string.lower(
		name or ""
	)

	return name == "hitbox"
		or name:find(
			"hitbox",
			1,
			true
		)
end

--========================================================
-- STRONG TARGET NAME
--========================================================

local function getNameScore(name)

	name = string.lower(
		name or ""
	)

	local score = 0

	-- Cực kỳ ưu tiên
	if name == "getwinbutton" then
		score += 30000
	end

	if name == "claimwinbutton" then
		score += 30000
	end

	if name == "winbutton" then
		score += 28000
	end

	if name == "winblock" then
		score += 26000
	end

	if name == "winblock1" then
		score += 26000
	end

	-- Các tên phổ biến
	if name:find(
		"getwin",
		1,
		true
	) then
		score += 18000
	end

	if name:find(
		"claimwin",
		1,
		true
	) then
		score += 18000
	end

	if name:find(
		"winbutton",
		1,
		true
	) then
		score += 17000
	end

	if name:find(
		"winblock",
		1,
		true
	) then
		score += 16000
	end

	if name:find(
		"win_button",
		1,
		true
	) then
		score += 16000
	end

	if name:find(
		"win_block",
		1,
		true
	) then
		score += 16000
	end

	if name:find(
		"claim",
		1,
		true
	) then
		score += 10000
	end

	if name:find(
		"getwin",
		1,
		true
	) then
		score += 10000
	end

	if name:find(
		"finish",
		1,
		true
	) then
		score += 9000
	end

	if name:find(
		"award",
		1,
		true
	) then
		score += 9000
	end

	if name:find(
		"button",
		1,
		true
	) then
		score += 7000
	end

	if name == "win" then
		score += 8000
	end

	if name:find(
		"win",
		1,
		true
	) then
		score += 5000
	end

	return score
end

--========================================================
-- STAGE CHECK
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

		local name =
			string.lower(
				tostring(current.Name)
			)

		for _, pattern in ipairs(
			wanted
		) do

			if name == pattern then
				return true
			end
		end

		current = current.Parent
	end

	return false
end

--========================================================
-- STAGE NAME CHECK
--========================================================

local function isStageContainer(
	object,
	stageNumber
)

	if not object then
		return false
	end

	local name =
		string.lower(
			tostring(object.Name)
		)

	local n =
		tostring(stageNumber)

	return name == "stage" .. n
		or name == "stage-" .. n
		or name == "stage_" .. n
		or name == "stage " .. n
end

--========================================================
-- SCORE TARGET
--========================================================

local function scoreTarget(
	part,
	stageNumber,
	winValue
)

	if not isBasePart(part) then
		return -math.huge
	end

	local score = 0

	local name =
		string.lower(
			part.Name
		)

	--====================================================
	-- NAME
	--====================================================

	score += getNameScore(
		part.Name
	)

	--====================================================
	-- INTERACTIVE
	--====================================================

	if hasInteractiveObject(part) then

		-- TouchInterest đặc biệt quan trọng
		if part:FindFirstChild(
			"TouchInterest"
		) then
			score += 15000
		end

		if part:FindFirstChildOfClass(
			"ProximityPrompt"
		) then
			score += 14000
		end

		if part:FindFirstChildOfClass(
			"ClickDetector"
		) then
			score += 12000
		end
	end

	--====================================================
	-- TEXT
	--====================================================

	local text =
		collectObjectText(part)

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
	or containsText(
		text,
		"GetWin"
	)
	or containsText(
		text,
		"ClaimWin"
	)
	then

		score += 25000
	end

	--====================================================
	-- WIN VALUE
	--====================================================

	if parseWinValue(
		part.Name
	) == winValue then

		score += 10000
	end

	if parseWinValue(
		text
	) == winValue then

		score += 12000
	end

	--====================================================
	-- STAGE
	--====================================================

	if belongsToStage(
		part,
		stageNumber
	) then

		score += 8000
	end

	--====================================================
	-- BAD OBJECT
	--====================================================

	if isBadNPCName(
		part.Name
	) then

		score -= 30000
	end

	if isHitboxName(
		part.Name
	) then

		-- Hitbox chỉ được dùng nếu nó thực sự interactive
		if hasInteractiveObject(part) then
			score -= 5000
		else
			score -= 25000
		end
	end

	--====================================================
	-- TRANSPARENCY
	--====================================================

	-- Không loại transparency vì nhiều nút dùng
	-- part trong suốt làm trigger.
	if part.Transparency >= 0.99 then
		if hasInteractiveObject(part) then
			score += 3000
		else
			score -= 2000
		end
	end

	return score
end

--========================================================
-- FIND STRUCTURE
--========================================================

local function findStructure()

	-- Ưu tiên Workspace.Structure
	local structure =
		workspace:FindFirstChild(
			STRUCTURE_NAME
		)

	if structure then
		return structure
	end

	-- Fallback recursive
	structure =
		workspace:FindFirstChild(
			STRUCTURE_NAME,
			true
		)

	return structure
end

--========================================================
-- FIND STAGE CONTAINER
--========================================================

local function findStageContainer(
	stageNumber
)

	local structure =
		findStructure()

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

	--====================================================
	-- CHỈ TÌM TRONG STRUCTURE
	--====================================================

	for _, name in ipairs(
		names
	) do

		local direct =
			structure:FindFirstChild(
				name
			)

		if direct then
			return direct
		end
	end

	--====================================================
	-- Nếu Stage nằm sâu hơn trong Structure
	--====================================================

	for _, name in ipairs(
		names
	) do

		local recursive =
			structure:FindFirstChild(
				name,
				true
			)

		if recursive then
			return recursive
		end
	end

	return nil
end

--========================================================
-- FIND TARGET INSIDE STAGE
--========================================================

local function findTargetInStage(
	container,
	stageNumber,
	winValue
)

	if not container then
		return nil, 0
	end

	local bestTarget = nil
	local bestScore = -math.huge

	local scanned = 0

	--====================================================
	-- CONTAINER ITSELF
	--====================================================

	if container:IsA("BasePart") then

		scanned += 1

		local score =
			scoreTarget(
				container,
				stageNumber,
				winValue
			)

		if score > bestScore then

			bestScore = score
			bestTarget = container

		end
	end

	--====================================================
	-- DESCENDANTS
	--====================================================

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			scanned += 1

			local score =
				scoreTarget(
					object,
					stageNumber,
					winValue
				)

			-- Nếu Part nằm trực tiếp trong model
			-- có tên Win thì ưu tiên thêm
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

					score += 7000
				end

				if parentName:find(
					"button",
					1,
					true
				) then

					score += 6000
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

	if bestTarget
		and bestScore > 0
	then

		print(
			("[SCAN] Stage %d best score: %d")
			:format(
				stageNumber,
				bestScore
			)
		)

		return bestTarget, scanned
	end

	return nil, scanned
end

--========================================================
-- GLOBAL FALLBACK
--========================================================

local function globalFallback(
	stageNumber,
	winValue,
	usedTargets
)

	if not ENABLE_GLOBAL_FALLBACK then
		return nil
	end

	print(
		("[FALLBACK] Stage %d global search")
		:format(stageNumber)
	)

	local bestTarget = nil
	local bestScore = -math.huge

	local scanned = 0

	-- Không dùng GetDescendants nhiều lần
	-- Chỉ 1 lần duy nhất cho fallback
	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("BasePart") then

			scanned += 1

			if not ALLOW_DUPLICATE_TARGET
				and usedTargets[object]
			then
				continue
			end

			local score =
				scoreTarget(
					object,
					stageNumber,
					winValue
				)

			if score > bestScore then

				bestScore = score
				bestTarget = object

			end
		end
	end

	print(
		("[FALLBACK] Stage %d scanned: %d")
		:format(
			stageNumber,
			scanned
		)
	)

	if bestTarget
		and bestScore > 0
	then
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

	local targetsByStage = {}
	local targetsByValue = {}

	local usedTargets = {}

	print("")
	print("========================================")
	print("       LPT HUB - WIN TARGET SCAN")
	print("========================================")

	local structure =
		findStructure()

	if structure then

		print(
			"[SCAN] Structure -> "
			.. structure:GetFullName()
		)

	else

		warn(
			"[SCAN] Structure not found"
		)

	end

	--====================================================
	-- SCAN TỪNG STAGE
	--====================================================

	for _, stageInfo in ipairs(
		WIN_STAGES
	) do

		local stageNumber =
			stageInfo.stage

		local winValue =
			stageInfo.value

		local target = nil

		--================================================
		-- FIND CONTAINER
		--================================================

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

			--============================================
			-- CHỈ SCAN TRONG STAGE
			--============================================

			target =
				findTargetInStage(
					container,
					stageNumber,
					winValue
				)

		else

			warn(
				("[SCAN] Stage %d container not found")
				:format(
					stageNumber
				)
			)

		end

		--================================================
		-- FALLBACK
		--================================================

		if not target
			and ENABLE_GLOBAL_FALLBACK
		then

			target =
				globalFallback(
					stageNumber,
					winValue,
					usedTargets
				)

		end

		--================================================
		-- VALIDATE
		--================================================

		if isBasePart(target) then

			if not ALLOW_DUPLICATE_TARGET
				and usedTargets[target]
			then

				target = nil

			end
		end

		--================================================
		-- SAVE
		--================================================

		if isBasePart(target) then

			targetsByStage[
				stageNumber
			] = target

			targetsByValue[
				winValue
			] = target

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
					tostring(
						target.Position
					)
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

	State.StageTargetCache =
		targetsByStage

	State.TargetCache =
		targetsByValue

	State.Scanning = false

	local count = 0

	for _, target in pairs(
		targetsByStage
	) do

		if isBasePart(target) then
			count += 1
		end
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

	return State.StageTargetCache
end

--========================================================
-- GET TARGET BY VALUE
--========================================================

function Module.GetTarget(
	value
)

	value =
		tonumber(value)

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
-- GET TARGET BY STAGE
--========================================================

function Module.GetStageTarget(
	stageNumber
)

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
-- GET TARGETS
--========================================================

function Module.GetTargets()

	if next(
		State.StageTargetCache
	) == nil
	then

		Module.RefreshTargets()

	end

	return State.StageTargetCache
end

--========================================================
-- GET STAGE
--========================================================

function Module.GetStage(
	stageNumber
)

	stageNumber =
		tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	for _, info in ipairs(
		WIN_STAGES
	) do

		if info.stage ==
			stageNumber
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

local function getTargetPosition(
	part
)

	if not isBasePart(part) then
		return nil
	end

	local position =
		part.Position

	if FLY_ABOVE_TARGET then

		return Vector3.new(

			position.X,

			position.Y
				+ part.Size.Y / 2
				+ TARGET_HEIGHT_OFFSET
				+ State.FlyHeight,

			position.Z

		)
	end

	return Vector3.new(

		position.X,

		position.Y
			+ State.FlyHeight,

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
		return false, "Target disappeared"
	end

	State.Flying = true
	State.CurrentTarget = part
	State.CurrentStage = stageNumber

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
		"[FLY] Player:",
		root.Position
	)
	print(
		"[FLY] Target:",
		part.Position
	)
	print(
		"[FLY] Distance:",
		(root.Position - part.Position).Magnitude
	)
	print("========================================")

	local oldAutoRotate =
		humanoid.AutoRotate

	local oldPlatformStand =
		humanoid.PlatformStand

	local started =
		os.clock()

	local reached = false

	local stuckTime = 0
	local lastDistance = math.huge

	--====================================================
	-- FLY LOOP
	--====================================================

	pcall(function()

		humanoid.AutoRotate = false
		humanoid.PlatformStand = true

	end)

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

			print(
				("[FLY] Arrived. Distance: %.2f")
				:format(distance)
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

		--================================================
		-- MOVE
		--================================================

		if offset.Magnitude > 0.001 then

			local nextPosition =
				current
				+ offset.Unit * step

			-- Không đổi hướng theo camera
			root.CFrame =
				CFrame.new(
					nextPosition
				)

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

		end

		--================================================
		-- MAINTAIN
		--================================================

		pcall(function()

			humanoid.PlatformStand =
				true

			humanoid.AutoRotate =
				false

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

		end)

		--================================================
		-- STUCK CHECK
		--================================================

		local newDistance =
			(root.Position - destination).Magnitude

		if newDistance >=
			lastDistance - 0.05
		then

			stuckTime += dt

		else

			stuckTime = 0

		end

		lastDistance =
			newDistance

		--================================================
		-- SERVER RESET
		--================================================

		if stuckTime > 1.5 then

			warn(
				"[FLY] Movement appears stuck. Retrying..."
			)

			-- Không teleport hẳn vào nút.
			-- Đặt lại cách target 8 studs.
			local direction =
				destination
				- root.Position

			if direction.Magnitude > 0.01 then

				local retryPosition =
					destination
					- direction.Unit * 8

				pcall(function()

					root.CFrame =
						CFrame.new(
							retryPosition
						)

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

				end)
			end

			stuckTime = 0
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

		local finalPosition =
			getTargetPosition(part)

		if finalPosition then

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

				root.CFrame =
					CFrame.new(
						finalPosition
					)

				root.AssemblyLinearVelocity =
					Vector3.zero

				root.AssemblyAngularVelocity =
					Vector3.zero

				RunService.Heartbeat:Wait()

			end
		end
	end

	--====================================================
	-- RESTORE
	--====================================================

	if humanoid
		and humanoid.Parent
	then

		pcall(function()

			humanoid.AutoRotate =
				oldAutoRotate

			humanoid.PlatformStand =
				oldPlatformStand

			humanoid.WalkSpeed =
				State.WalkSpeed

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
	-- FIND STAGE FIRST
	--====================================================

	local stageNumber = nil

	for _, info in ipairs(
		WIN_STAGES
	) do

		if info.value == winAmount then

			stageNumber =
				info.stage

			break
		end
	end

	--====================================================
	-- IMPORTANT:
	-- ƯU TIÊN TARGET THEO STAGE
	--====================================================

	local target = nil

	if stageNumber then

		target =
			State.StageTargetCache[
				stageNumber
			]
	end

	--====================================================
	-- CACHE VALUE
	--====================================================

	if not isBasePart(target) then

		target =
			State.TargetCache[
				winAmount
			]

	end

	--====================================================
	-- RESCAN
	--====================================================

	if not isBasePart(target) then

		print(
			("[FlyToWin] Target Stage %s missing, rescanning...")
			:format(
				tostring(
					stageNumber or "?"
				)
			)
		)

		Module.RefreshTargets()

		if stageNumber then

			target =
				State.StageTargetCache[
					stageNumber
				]

		end

		if not isBasePart(target) then

			target =
				State.TargetCache[
					winAmount
				]

		end
	end

	--====================================================
	-- FAIL
	--====================================================

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

	print(
		("[FlyToWin] Stage %s | +%s -> %s")
		:format(
			tostring(
				stageNumber or "?"
			),
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

	--====================================================
	-- LẤY TARGET TRỰC TIẾP THEO STAGE
	--====================================================

	local target =
		State.StageTargetCache[
			stageNumber
		]

	if not isBasePart(target) then

		print(
			("[FlyToStage] Stage %d target missing, scanning stage...")
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

			target =
				findTargetInStage(
					container,
					stageNumber,
					stageInfo.value
				)

			if isBasePart(target) then

				State.StageTargetCache[
					stageNumber
				] = target

				State.TargetCache[
					stageInfo.value
				] = target

			end
		end
	end

	--====================================================
	-- LAST FALLBACK
	--====================================================

	if not isBasePart(target) then

		Module.RefreshTargets()

		target =
			State.StageTargetCache[
				stageNumber
			]

	end

	if not isBasePart(target) then

		return false,
			(
				"No target for Stage %d."
			):format(
				stageNumber
			)

	end

	print(
		("[FlyToStage] Stage %d -> %s")
		:format(
			stageNumber,
			target:GetFullName()
		)
	)

	return Module.FlyToPart(
		target,
		stageNumber
	)
end

--========================================================
-- WALK SPEED / JUMP POWER MAINTAIN
--========================================================

Connections.CharacterSettings =
	RunService.Heartbeat:Connect(
		function()

			local humanoid =
				getHumanoid()

			if not humanoid
				or not humanoid.Parent
			then
				return
			end

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
-- HUMANOID SETTINGS
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

			State.Flying = false
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

			local humanoid =
				getHumanoid()

			if humanoid then

				connectHumanoidSettings(
					humanoid
				)

			end

			local character =
				getCharacter()

			if State.NoClip
				and character
			then

				rememberCollision(
					character
				)

			end
		end)

--========================================================
-- INITIAL
--========================================================

task.defer(function()

	task.wait(0.2)

	applyCharacterSettings()

	local humanoid =
		getHumanoid()

	if humanoid then

		connectHumanoidSettings(
			humanoid
		)

	end

	local character =
		getCharacter()

	if State.NoClip
		and character
	then

		rememberCollision(
			character
		)

	end
end)

--========================================================
-- GET STATE
--========================================================

function Module.GetState()

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

		FoundTargets =
			State.StageTargetCache,

		FlyToWinEnabled =
			ENABLE_FLY_TO_WIN,

		Scanning =
			State.Scanning,
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
		OriginalCollision
	)
end

return Module
