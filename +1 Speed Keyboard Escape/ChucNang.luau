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
				UserInputService.JumpRequest:Connect(function()

					if not State.InfiniteJump then
						return
					end

					local humanoid = getHumanoid()

					if humanoid then
						humanoid:ChangeState(
							Enum.HumanoidStateType.Jumping
						)
					end
				end)
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
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then

			local original = OriginalCollision[object]

			if original ~= nil then
				object.CanCollide = original
				OriginalCollision[object] = nil
			else
				object.CanCollide = true
			end
		end
	end
end

function Module.SetNoClip(enabled)
	State.NoClip = enabled == true

	local character = getCharacter()

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
-- WIN PARSER
--========================================================

local function cleanText(text)
	text = tostring(text or "")

	text = text
		:gsub(",", "")
		:gsub("％", "%")
		:gsub("%s+", " ")

	return text:lower()
end

local function extractWinValue(text)
	local normalized = cleanText(text)

	-- Hỗ trợ:
	-- +1 Win
	-- +1 Wins
	-- +1
	-- +1K Win
	-- +1M Win

	local number, suffix =
		normalized:match(
			"%+%s*([%d%.]+)%s*([km]?)%s*[wW][iI][nN][sS]?"
		)

	-- Nếu không có chữ Win/Wins,
	-- vẫn nhận +1 / +3
	if not number then
		number, suffix =
			normalized:match(
				"%+%s*([%d%.]+)%s*([km]?)"
			)
	end

	if not number then
		return nil
	end

	local value = tonumber(number)

	if not value then
		return nil
	end

	suffix = suffix or ""

	if suffix == "k" then
		value = value * 1000
	elseif suffix == "m" then
		value = value * 1000000
	end

	return math.floor(value + 0.5)
end

--========================================================
-- FIND BEST PART IN CONTAINER
--========================================================

local function findBestPart(container)

	if not container then
		return nil
	end

	-- Nếu chính nó là Part
	if container:IsA("BasePart") then
		return container
	end

	-- Model
	if container:IsA("Model") then

		-- Ưu tiên Hitbox
		local hitbox = container:FindFirstChild(
			"Hitbox",
			true
		)

		if hitbox and hitbox:IsA("BasePart") then
			return hitbox
		end

		-- Ưu tiên Button
		local button = container:FindFirstChild(
			"Button",
			true
		)

		if button and button:IsA("BasePart") then
			return button
		end

		-- PrimaryPart
		if container.PrimaryPart then
			return container.PrimaryPart
		end

		-- Tìm part có tên liên quan
		for _, object in ipairs(
			container:GetDescendants()
		) do

			if object:IsA("BasePart") then

				local name =
					object.Name:lower()

				if name:find("button")
					or name:find("hitbox")
					or name:find("win")
				then
					return object
				end
			end
		end

		-- Cuối cùng lấy BasePart đầu tiên
		return container:FindFirstChildWhichIsA(
			"BasePart",
			true
		)
	end

	return nil
end

--========================================================
-- FIND PART FROM GUI
--========================================================

local function findPartFromGui(gui)

	if not gui:IsA("TextLabel")
		and not gui:IsA("TextButton")
	then
		return nil
	end

	local value =
		extractWinValue(gui.Text)

	if not value then
		return nil
	end

	--====================================================
	-- 1. GUI trong BillboardGui / SurfaceGui
	--====================================================

	local current = gui

	while current and current ~= workspace do

		if current:IsA("BillboardGui")
			or current:IsA("SurfaceGui")
		then

			-- Adornee
			local adornee =
				current.Adornee

			if adornee then

				local part =
					findBestPart(adornee)

				if part then
					return part, value
				end
			end

			-- Parent của GUI
			local parent =
				current.Parent

			local part =
				findBestPart(parent)

			if part then
				return part, value
			end
		end

		current = current.Parent
	end

	--====================================================
	-- 2. Leo ngược Parent
	--====================================================

	current = gui.Parent

	while current and current ~= workspace do

		local part =
			findBestPart(current)

		if part then
			return part, value
		end

		current = current.Parent
	end

	return nil
end

--========================================================
-- FIND WIN FROM PART / MODEL NAME
--========================================================

local function findWinFromInstance(object)

	if not object then
		return nil
	end

	local value =
		extractWinValue(object.Name)

	if value then
		return value
	end

	return nil
end

--========================================================
-- REFRESH TARGETS
--========================================================

function Module.RefreshTargets()

	local targets = {}

	--====================================================
	-- PASS 1:
	-- Scan Models
	--====================================================

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("Model") then

			local value =
				findWinFromInstance(object)

			if value then

				local part =
					findBestPart(object)

				if part then
					targets[value] = part
				end
			end
		end
	end

	--====================================================
	-- PASS 2:
	-- Scan Parts
	--====================================================

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local value =
				findWinFromInstance(object)

			if value then
				targets[value] = object
			end
		end
	end

	--====================================================
	-- PASS 3:
	-- Scan GUI
	--====================================================

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("TextLabel")
			or object:IsA("TextButton")
		then

			local part, value =
				findPartFromGui(object)

			if part and value then
				targets[value] = part
			end
		end
	end

	State.TargetCache = targets

	--====================================================
	-- DEBUG
	--====================================================

	print("===== WIN TARGETS =====")

	local count = 0

	for value, part in pairs(targets) do

		count += 1

		print(
			("Target +%s Win -> %s | Position: %s")
				:format(
					tostring(value),
					part:GetFullName(),
					tostring(part.Position)
				)
		)
	end

	print(
		"Total targets:",
		count
	)

	print("=======================")

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

	-- Luôn refresh nếu target chưa có
	if not State.TargetCache[value] then
		Module.RefreshTargets()
	end

	return State.TargetCache[value]
end

--========================================================
-- GET ALL TARGETS
--========================================================

function Module.GetTargets()

	-- Refresh mỗi lần gọi để bắt
	-- những button mới spawn
	Module.RefreshTargets()

	return State.TargetCache
end

--========================================================
-- TARGET POSITION
--========================================================

local function targetPosition(part)

	if not part then
		return nil
	end

	if not part.Parent then
		return nil
	end

	if not part:IsA("BasePart") then
		return nil
	end

	-- Bay tới phía trên target
	local topY =
		part.Position.Y
		+ (part.Size.Y / 2)
		+ State.FlyHeight

	return Vector3.new(
		part.Position.X,
		topY,
		part.Position.Z
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
		return false, "Invalid target part."
	end

	local root = getRoot()
	local humanoid = getHumanoid()

	if not root or not humanoid then
		return false, "Character is not ready."
	end

	if State.Flying then
		return false, "Already flying."
	end

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate =
		humanoid.AutoRotate

	local previousPlatformStand =
		humanoid.PlatformStand

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

		-- Đã tới target
		if distance <= 3 then
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

		local step =
			math.min(
				distance,
				State.FlySpeed * deltaTime
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
				CFrame.new(nextPosition)
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
				CFrame.new(destination)
		end
	end

	--====================================================
	-- RESTORE
	--====================================================

	if humanoid and humanoid.Parent then

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

	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount."
	end

	-- Refresh trước khi tìm
	Module.RefreshTargets()

	local target =
		State.TargetCache[winAmount]

	if not target then

		return false,
			("No +%d Win target was detected.")
				:format(winAmount)
	end

	if State.Flying then
		return false, "Already flying."
	end

	task.spawn(function()

		local success, reason =
			Module.FlyToPart(target)

		print(
			"FlyToWin:",
			winAmount,
			success,
			reason or ""
		)
	end)

	return true
end

--========================================================
-- CHARACTER LIFECYCLE
--========================================================

Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(
		function(character)

			State.Flying = false
			State.CurrentTarget = nil

			table.clear(
				OriginalCollision
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
					rememberCollision(character)
				end
			end
		end
	)

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
-- INITIAL
--========================================================

task.defer(function()

	applyCharacterSettings()

	if State.NoClip then

		local character =
			getCharacter()

		if character then
			rememberCollision(character)
		end
	end
end)

--========================================================
-- PUBLIC STATE
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
	}
end

return Module
