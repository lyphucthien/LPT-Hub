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
}

local Connections = {}
local OriginalCollision = {}

--========================================================
-- 15 WIN STAGES
--========================================================

local WIN_STAGES = {
	{
		stage = 1,
		value = 1,
		text = "Stage 1 (+1 Win)",
	},

	{
		stage = 2,
		value = 3,
		text = "Stage 2 (+3 Wins)",
	},

	{
		stage = 3,
		value = 10,
		text = "Stage 3 (+10 Wins)",
	},

	{
		stage = 4,
		value = 20,
		text = "Stage 4 (+20 Wins)",
	},

	{
		stage = 5,
		value = 60,
		text = "Stage 5 (+60 Wins)",
	},

	{
		stage = 6,
		value = 100,
		text = "Stage 6 (+100 Wins)",
	},

	{
		stage = 7,
		value = 150,
		text = "Stage 7 (+150 Wins)",
	},

	{
		stage = 8,
		value = 300,
		text = "Stage 8 (+300 Wins)",
	},

	{
		stage = 9,
		value = 500,
		text = "Stage 9 (+500 Wins)",
	},

	{
		stage = 10,
		value = 1000,
		text = "Stage 10 (+1K Wins)",
	},

	{
		stage = 11,
		value = 2500,
		text = "Stage 11 (+2.5K Wins)",
	},

	{
		stage = 12,
		value = 10000,
		text = "Stage 12 (+10K Wins)",
	},

	{
		stage = 13,
		value = 25000,
		text = "Stage 13 (+25K Wins)",
	},

	{
		stage = 14,
		value = 50000,
		text = "Stage 14 (+50K Wins)",
	},

	{
		stage = 15,
		value = 150000,
		text = "Stage 15 (+150K Wins)",
	},
}

--========================================================
-- LOOKUP TABLE
--========================================================

local WIN_VALUES = {}

for _, stageInfo in ipairs(WIN_STAGES) do
	WIN_VALUES[stageInfo.stage] = stageInfo.value
end

--========================================================
-- PARSE NUMBER FROM NAME (supports K/M abbreviations)
-- Defined early so other functions can call it safely
--========================================================

local function parseNumberFromName(name)

	if not name then
		return nil
	end

	-- Normalize: remove commas and trim spaces
	local s = tostring(name):gsub(",", ""):gsub("%s+", "")

	-- Try to find number tokens like 1, 1000, 1K, 2.5K, 1M
	for num, suffix in s:gmatch("(%d+%.?%d*)([kKmM]?)") do

		local n = tonumber(num)

		if n then

			if suffix == "k" or suffix == "K" then
				n = n * 1000
			elseif suffix == "m" or suffix == "M" then
				n = n * 1000000
			end

			return n
		end
	end

	return nil
end

--========================================================
-- CONNECTION
--========================================================

local function disconnect(name)
	local connection = Connections[name]

	if connection then
		connection:Disconnect()
		Connections[name] = nil
	end
end

--========================================================
-- CHARACTER
--========================================================

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

--========================================================
-- NUMBER
--========================================================

local function getNumber(value, minimum, maximum, fallback)
	value = tonumber(value)

	if not value then
		return fallback
	end

	return math.clamp(value, minimum, maximum)
end

--========================================================
-- CHARACTER SETTINGS
--========================================================

local function applyCharacterSettings()
	local humanoid = getHumanoid()

	if not humanoid then
		return
	end

	humanoid.WalkSpeed = State.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = State.JumpPower
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

	if State.InfiniteJump then

		if not Connections.InfiniteJump then

			Connections.InfiniteJump =
				UserInputService.JumpRequest:Connect(
					function()

						if not State.InfiniteJump then
							return
						end

						local humanoid =
							getHumanoid()

						if humanoid then

							humanoid:ChangeState(
								Enum.HumanoidStateType.Jumping
							)

						end
					end
				)
		end

	else

		disconnect("InfiniteJump")

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
		return
	end

	for _, object in ipairs(
		character:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local original =
				OriginalCollision[object]

			if original ~= nil then

				object.CanCollide =
					original

			end
		end
	end

	table.clear(OriginalCollision)
end

function Module.SetNoClip(enabled)

	State.NoClip = enabled == true

	local character =
		getCharacter()

	if State.NoClip then

		if character then
			rememberCollision(character)
		end

	else

		if character then
			restoreCollision(character)
		end

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

	-- Direct BasePart
	if container:IsA("BasePart") then
		return container
	end

	-- PrimaryPart
	if container:IsA("Model") then

		if container.PrimaryPart then
			return container.PrimaryPart
		end
	end

	-- Ưu tiên Button
	local button =
		container:FindFirstChild(
			"Button",
			true
		)

	if button
		and button:IsA("BasePart")
	then
		return button
	end

	-- Ưu tiên Hitbox
	local hitbox =
		container:FindFirstChild(
			"Hitbox",
			true
		)

	if hitbox
		and hitbox:IsA("BasePart")
	then
		return hitbox
	end

	-- Tìm part có tên liên quan
	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local name =
				object.Name:lower()

			if name:find("win")
				or name:find("award")
				or name:find("button")
				or name:find("hitbox")
				or name:find("finish")
				or name:find("trophy")
			then

				return object

			end
		end
	end

	-- Fallback
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

		"Win" .. winValue,
		"Win-" .. winValue,

		"+" .. winValue .. " Win",
		"+" .. winValue .. " Wins",
	}

	--====================================================
	-- SEARCH WORKSPACE
	--====================================================

	for _, name in ipairs(possibleNames) do

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

local function findByWinValue(winValue)

	local possiblePatterns = {
		"+" .. tostring(winValue),
		tostring(winValue) .. " Win",
		tostring(winValue) .. " Wins",
		"Win" .. tostring(winValue),
		"Win-" .. tostring(winValue),
		"Win_" .. tostring(winValue),
	}

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

			-- 1) Try numeric in the object's own name (1K/25K/etc)
			local numericMatch = parseNumberFromName(object.Name)
			if numericMatch and numericMatch == winValue then
				local part = findTargetPart(object)
				if part then return part end
			end

			-- 2) Try ancestor names (some devs put the value on parent models)
			local anc = object.Parent
			while anc do
				local ancNum = parseNumberFromName(anc.Name)
				if ancNum and ancNum == winValue then
					local part = findTargetPart(anc)
					if part then return part end
				end
				anc = anc.Parent
			end

			-- 3) Try to read text from any GUI/Text descendants (SurfaceGui, BillboardGui)
			for _, desc in ipairs(object:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
					local txt = tostring(desc.Text)
					local txtNum = parseNumberFromName(txt)
					if txtNum and txtNum == winValue then
						local part = findTargetPart(object)
						if part then return part end
					end
				end
			end

			-- 4) Fallback: simple name pattern matching (existing)
			local name = object.Name:lower()
			for _, pattern in ipairs(possiblePatterns) do
				if name:find(pattern:lower(), 1, true) then
					local part = findTargetPart(object)
					if part then return part end
				end
			end
	end

	return nil
end

function Module.RefreshTargets()

	local targets = {}

	print("")
	print("========================================")
	print("        LPT HUB - WIN TARGET SCAN")
	print("========================================")

	for _, stageInfo in ipairs(WIN_STAGES) do

		local stageNumber =
			stageInfo.stage

		local winValue =
			stageInfo.value

		local target = nil

		local stageContainer =
			findStageContainer(
				stageNumber,
				winValue
			)

		if stageContainer then

			target =
				findTargetPart(
					stageContainer
				)

		end

		if not target then

			target =
				findByWinValue(
					winValue
				)

		end

		if target then

			targets[winValue] =
				target

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

	--====================================================
	-- CACHE
	--====================================================

	State.TargetCache = targets

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

	value =
		tonumber(value)

	if not value then
		return nil
	end

	local target =
		State.TargetCache[value]

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

	Module.RefreshTargets()

	return State.TargetCache
end

--========================================================
-- GET STAGE INFO
--========================================================

function Module.GetStage(stageNumber)

	stageNumber =
		tonumber(stageNumber)

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

--========================================================
-- GET ALL STAGES
--========================================================

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

	local position =
		part.Position

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
	then

		return false,
			"Invalid target part."
	end

	local root =
		getRoot()

	local humanoid =
		getHumanoid()

	if not root
		or not humanoid
	then

		return false,
			"Character is not ready."
	end

	if State.Flying then

		return false,
			"Already flying."
	end

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate =
		humanoid.AutoRotate

	local previousPlatformStand =
		humanoid.PlatformStand

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local started =
		os.clock()

	local timeout =
		30

	local reached =
		false

	--====================================================
	-- FLY LOOP
	--====================================================

	while State.Flying
		and root.Parent
		and part.Parent
		and os.clock() - started < timeout
	do

		local destination =
			targetPosition(part)

		if not destination then
			break
		end

		local current =
			root.Position

		local offset =
			destination - current

		local distance =
			offset.Magnitude

		-- ĐÃ TỚI
		if distance <= 2.5 then

			reached = true

			break
		end

		local deltaTime =
			RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		if not root.Parent
			or not part.Parent
		then

			break
		end

		local speed =
			State.FlySpeed

		local step =
			math.min(
				distance,
				speed * deltaTime
			)

		if offset.Magnitude > 0 then

			local nextPosition =
				current
				+ offset.Unit * step

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			root.CFrame =
				CFrame.new(
					nextPosition
				)
		end
	end

	--====================================================
	-- SNAP
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
				CFrame.new(
					destination
				)
		end
	end

	--====================================================
	-- RESTORE
	--====================================================

	if humanoid
		and humanoid.Parent
	then

		humanoid.AutoRotate =
			previousAutoRotate

		humanoid.PlatformStand =
			previousPlatformStand

		humanoid:ChangeState(
			Enum.HumanoidStateType.GettingUp
		)
	end

	State.Flying = false
	State.CurrentTarget = nil

	return reached
end

--========================================================
-- FLY TO WIN
--========================================================

function Module.FlyToWin(winAmount)

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
	-- REFRESH
	--====================================================

	Module.RefreshTargets()

	local target =
		State.TargetCache[winAmount]

	if not target then

		return false,
			("No +%d Win target was detected.")
				:format(
					winAmount
				)
	end

	print(
		("[FlyToWin] +%d -> %s")
			:format(
				winAmount,
			tostring((type(target) == "userdata" and target.GetFullName and target:GetFullName()) or tostring(target))
			)
	)

	--====================================================
	-- FLY
	--====================================================

	-- Defensive checks + pcall to capture errors
	if type(target) ~= "userdata" or not target.Parent then

		print(("[FlyToWin] Invalid target object: %s | type=%s | parent=%s")
			:format(tostring(target), type(target), tostring(target and target.Parent)))

		return false, "Invalid target object"
	end

	task.spawn(function()

		local ok, res = pcall(function()
			return Module.FlyToPart(target)
		end)

		if not ok then
			warn(("[FlyToWin] ERROR while flying +%d -> %s")
				:format(winAmount, tostring(res)))

			-- Extra debug: print target class and properties
			if type(target) == "userdata" then
				pcall(function()
					print("[FlyToWin] target.ClassName=", target.ClassName)
					print("[FlyToWin] target.Name=", target.Name)
					print("[FlyToWin] target:IsA('BasePart')=", target:IsA("BasePart"))
				end)
			return
		end

		local success, reason = res

		print(("[FlyToWin] Finished +%d | success=%s | reason=%s")
			:format(winAmount, tostring(success), tostring(reason or "")))
	end)

	return true
end

--========================================================
-- FLY TO STAGE
--========================================================

function Module.FlyToStage(stageNumber)

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

			State.Flying = false
			State.CurrentTarget = nil

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

				task.wait()

				applyCharacterSettings()

				if State.NoClip then

					rememberCollision(
						character
					)

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

			rememberCollision(
				character
			)

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
-- INITIAL
--========================================================

task.defer(
	function()

		applyCharacterSettings()

		local character =
			getCharacter()

		if State.NoClip
			and character
		then

			rememberCollision(
				character
			)
		end
	end
)

function Module.GetState()

	return {
		WalkSpeed = State.WalkSpeed,
		JumpPower = State.JumpPower,

		InfiniteJump = State.InfiniteJump,
		NoClip = State.NoClip,

		Flying = State.Flying,

		FlySpeed = State.FlySpeed,
		FlyHeight = State.FlyHeight,

		CurrentTarget =
			State.CurrentTarget,

		TargetCount =
			#WIN_STAGES,
	}
end

return Module
