local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Module = {}

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
	FlyHeight = 5,

	CurrentTarget = nil,
	TargetCache = {},

	Scanning = false,
}

local Connections = {}
local OriginalCollision = {}

--========================================================
-- 15 WIN STAGES
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

local WIN_VALUES = {}

for _, info in ipairs(WIN_STAGES) do
	WIN_VALUES[info.stage] = info.value
end

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

--========================================================
-- PARSE NUMBER
--========================================================

local function parseNumberFromName(name)
	if not name then
		return nil
	end

	local s = tostring(name)
		:gsub(",", "")
		:gsub("%s+", "")

	-- Ưu tiên số có K/M
	local number, suffix = s:match("(%d+%.?%d*)([kKmM])")

	if number then
		local n = tonumber(number)

		if not n then
			return nil
		end

		if suffix == "k" or suffix == "K" then
			return n * 1000
		elseif suffix == "m" or suffix == "M" then
			return n * 1000000
		end
	end

	-- Số thường
	local plain = s:match("%d+")

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
		humanoid.WalkSpeed = State.WalkSpeed
		humanoid.UseJumpPower = true
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
-- FIND TARGET PART
--========================================================

local function findTargetPart(container)
	if not container then
		return nil
	end

	if container:IsA("BasePart") then
		return container
	end

	if container:IsA("Model") then
		if container.PrimaryPart then
			return container.PrimaryPart
		end
	end

	local preferredNames = {
		"Button",
		"Hitbox",
		"Win",
		"Finish",
		"Award",
		"Trophy",
	}

	for _, name in ipairs(preferredNames) do
		local object = container:FindFirstChild(name, true)

		if object and object:IsA("BasePart") then
			return object
		end
	end

	for _, object in ipairs(container:GetDescendants()) do
		if object:IsA("BasePart") then
			local name = object.Name:lower()

			if name:find("win", 1, true)
				or name:find("award", 1, true)
				or name:find("button", 1, true)
				or name:find("hitbox", 1, true)
				or name:find("finish", 1, true)
				or name:find("trophy", 1, true)
			then
				return object
			end
		end
	end

	return container:FindFirstChildWhichIsA(
		"BasePart",
		true
	)
end

--========================================================
-- FIND STAGE CONTAINER
--========================================================

local function findStageContainer(stageNumber, winValue)
	local possibleNames = {
		"Stage" .. stageNumber,
		"Stage-" .. stageNumber,
		"Stage_" .. stageNumber,

		"stage" .. stageNumber,
		"stage-" .. stageNumber,
		"stage_" .. stageNumber,

		"Win" .. winValue,
		"Win-" .. winValue,
		"Win_" .. winValue,

		"+" .. winValue .. " Win",
		"+" .. winValue .. " Wins",

		"Win " .. winValue,
		"Wins " .. winValue,
	}

	for _, name in ipairs(possibleNames) do
		local object = workspace:FindFirstChild(name, true)

		if object then
			return object
		end
	end

	return nil
end

--========================================================
-- FIND BY WIN VALUE
--========================================================

local function findByWinValue(winValue)
	local possiblePatterns = {
		"+" .. tostring(winValue),
		tostring(winValue) .. " Win",
		tostring(winValue) .. " Wins",
		"Win" .. tostring(winValue),
		"Win-" .. tostring(winValue),
		"Win_" .. tostring(winValue),
	}

	for _, object in ipairs(workspace:GetDescendants()) do
		local name = object.Name

		-- Name
		local numericMatch = parseNumberFromName(name)

		if numericMatch == winValue then
			local part = findTargetPart(object)

			if part then
				return part
			end
		end

		-- Pattern
		local lowerName = name:lower()

		for _, pattern in ipairs(possiblePatterns) do
			if lowerName:find(
				pattern:lower(),
				1,
				true
			) then
				local part = findTargetPart(object)

				if part then
					return part
				end
			end
		end

		-- GUI text
		for _, desc in ipairs(object:GetDescendants()) do
			if desc:IsA("TextLabel")
				or desc:IsA("TextButton")
				or desc:IsA("TextBox")
			then
				local text = tostring(desc.Text)
				local textNumber = parseNumberFromName(text)

				if textNumber == winValue then
					local part = findTargetPart(object)

					if part then
						return part
					end
				end
			end
		end
	end

	return nil
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

	print("")
	print("========================================")
	print("        LPT HUB - WIN TARGET SCAN")
	print("========================================")

	for _, stageInfo in ipairs(WIN_STAGES) do
		local stageNumber = stageInfo.stage
		local winValue = stageInfo.value

		local target

		-- Method 1
		local stageContainer =
			findStageContainer(
				stageNumber,
				winValue
			)

		if stageContainer then
			target = findTargetPart(stageContainer)
		end

		-- Method 2
		if not target then
			target = findByWinValue(winValue)
		end

		if target
			and target:IsA("BasePart")
			and target.Parent
		then
			targets[winValue] = target

			print(
				("[FOUND] Stage %d | +%s Win | %s")
					:format(
						stageNumber,
						tostring(winValue),
						target:GetFullName()
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

	State.TargetCache = targets
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

	local target = State.TargetCache[value]

	if target
		and target.Parent
		and target:IsA("BasePart")
	then
		return target
	end

	Module.RefreshTargets()

	return State.TargetCache[value]
end

--========================================================
-- GET ALL TARGETS
--========================================================

function Module.GetTargets()
	if next(State.TargetCache) == nil then
		Module.RefreshTargets()
	end

	return State.TargetCache
end

--========================================================
-- GET STAGE
--========================================================

function Module.GetStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return nil
	end

	for _, stageInfo in ipairs(WIN_STAGES) do
		if stageInfo.stage == stageNumber then
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

local function targetPosition(part)
	if not part
		or not part.Parent
		or not part:IsA("BasePart")
	then
		return nil
	end

	-- Đứng phía trên target một khoảng nhỏ.
	return part.Position + Vector3.new(
		0,
		State.FlyHeight,
		0
	)
end

--========================================================
-- STOP FLYING
--========================================================

function Module.StopFlying()
	State.Flying = false
	State.CurrentTarget = nil
end

function Module.IsFlying()
	return State.Flying
end

--========================================================
-- FLY TO PART
--========================================================

function Module.FlyToPart(part)
	if not part
		or not part:IsA("BasePart")
		or not part.Parent
	then
		return false, "Invalid target part."
	end

	if State.Flying then
		return false, "Already flying."
	end

	local root = getRoot()
	local humanoid = getHumanoid()

	if not root
		or not root.Parent
		or not humanoid
		or not humanoid.Parent
	then
		return false, "Character is not ready."
	end

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate = humanoid.AutoRotate
	local previousPlatformStand = humanoid.PlatformStand

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local started = os.clock()
	local timeout = 30
	local reached = false

	while State.Flying
		and root.Parent
		and part.Parent
		and os.clock() - started < timeout
	do
		local destination = targetPosition(part)

		if not destination then
			break
		end

		local current = root.Position
		local offset = destination - current
		local distance = offset.Magnitude

		if distance <= 2.5 then
			reached = true
			break
		end

		local deltaTime = RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		if not root.Parent
			or not part.Parent
		then
			break
		end

		local speed = math.max(
			10,
			State.FlySpeed
		)

		local step = math.min(
			distance,
			speed * deltaTime
		)

		if offset.Magnitude > 0 then
			local nextPosition =
				current + offset.Unit * step

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			root.CFrame =
				CFrame.new(nextPosition)
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
		local destination =
			targetPosition(part)

		if destination then
			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			root.CFrame =
				CFrame.new(destination)
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
				previousAutoRotate

			humanoid.PlatformStand =
				previousPlatformStand

			humanoid:ChangeState(
				Enum.HumanoidStateType.GettingUp
			)
		end)
	end

	State.Flying = false
	State.CurrentTarget = nil

	return reached
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(winAmount)
	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount."
	end

	if State.Flying then
		return false, "Already flying."
	end

	-- Cache trước
	local target = State.TargetCache[winAmount]

	-- Chỉ scan nếu target chưa có
	if not target
		or not target.Parent
		or not target:IsA("BasePart")
	then
		Module.RefreshTargets()
		target = State.TargetCache[winAmount]
	end

	if not target
		or not target.Parent
		or not target:IsA("BasePart")
	then
		return false,
			("No +%s Win target was detected.")
				:format(tostring(winAmount))
	end

	print(
		("[FlyToWin] +%s -> %s")
			:format(
				tostring(winAmount),
				target:GetFullName()
			)
	)

	--====================================================
	-- FLY DIRECTLY
	--====================================================

	local success, reason =
		Module.FlyToPart(target)

	if not success then
		warn(
			("[FlyToWin] Failed +%s | %s")
				:format(
					tostring(winAmount),
					tostring(reason)
				)
		)

		return false, reason
	end

	print(
		("[FlyToWin] Finished +%s")
			:format(
				tostring(winAmount)
			)
	)

	return true
end

--========================================================
-- FLY TO STAGE
--========================================================

function Module.FlyToStage(stageNumber)
	stageNumber = tonumber(stageNumber)

	if not stageNumber then
		return false, "Invalid stage."
	end

	local stageInfo =
		Module.GetStage(stageNumber)

	if not stageInfo then
		return false,
			("Stage %d does not exist.")
				:format(stageNumber)
	end

	print(
		("[FlyToStage] Stage %d -> +%d Win")
			:format(
				stageInfo.stage,
				stageInfo.value
			)
	)

	return Module.FlyToWin(
		stageInfo.value
	)
end

--========================================================
-- CHARACTER ADDED
--========================================================

Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(
		function(character)

			-- Dừng fly cũ
			State.Flying = false
			State.CurrentTarget = nil

			-- Xóa collision cũ
			table.clear(
				OriginalCollision
			)

			-- Target cũ không còn đáng tin
			table.clear(
				State.TargetCache
			)

			local humanoid =
				character:WaitForChild(
					"Humanoid",
					10
				)

			if humanoid then
				task.wait(0.1)

				applyCharacterSettings()

				if State.NoClip then
					rememberCollision(character)
				end
			end
		end
	)

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

			rememberCollision(character)

			for _, object in ipairs(
				character:GetDescendants()
			) do
				if object:IsA("BasePart") then
					object.CanCollide = false
				end
			end
		end
	)

--========================================================
-- CHARACTER RESPAWN SETTINGS
--========================================================

Connections.CharacterAppearance =
	LocalPlayer.CharacterAppearanceLoaded:Connect(
		function()
			task.wait(0.1)

			applyCharacterSettings()

			local character =
				getCharacter()

			if State.NoClip
				and character
			then
				rememberCollision(character)
			end
		end
	)

--========================================================
-- INITIAL
--========================================================

task.defer(function()
	task.wait(0.1)

	applyCharacterSettings()

	local character =
		getCharacter()

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
		TargetCount = #WIN_STAGES,
		FoundTargets = State.TargetCache,
	}
end

function Module.Destroy()
	State.Flying = false
	State.CurrentTarget = nil

	for name, connection in pairs(Connections) do
		if connection then
			connection:Disconnect()
		end

		Connections[name] = nil
	end

	local character = getCharacter()

	if character then
		restoreCollision(character)
	end

	table.clear(State.TargetCache)
end

return Module
