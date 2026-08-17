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

-- Lưu trạng thái collision gốc của character
local OriginalCollision = {}

--========================================================
-- CONNECTION HELPERS
--========================================================

local function disconnect(name)
	local connection = Connections[name]

	if connection then
		connection:Disconnect()
		Connections[name] = nil
	end
end

--========================================================
-- CHARACTER HELPERS
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
-- WALK SPEED / JUMP POWER
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

-- NO CLIP
local function rememberCollision(character)
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
				-- Part mới không có trạng thái cũ
				-- nên dùng mặc định an toàn.
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

-- WIN TARGET DETECTION
local function normalize(text)
	return tostring(text or "")
		:lower()
		:gsub(",", "")
end

local function extractWinValue(text)
	local normalized = normalize(text)

	normalized = normalized:gsub(",", "")

	local number, suffix = normalized:match(
		"%+%s*([%d%.]+)%s*([km]?)%s*win"
	)

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

-- FIND PART FROM GUI
local function findPartFromGui(gui)
	if not gui:IsA("TextLabel")
		and not gui:IsA("TextButton")
	then
		return nil
	end

	local value = extractWinValue(gui.Text)

	if not value then
		return nil
	end

	local current = gui

	while current and current ~= workspace do

		if current:IsA("SurfaceGui")
			or current:IsA("BillboardGui")
		then

			local adornee = current.Adornee

			if adornee then

				if adornee:IsA("BasePart") then
					return adornee, value
				end

				if adornee:IsA("Model") then
					local part =
						adornee.PrimaryPart
						or adornee:FindFirstChild(
							"Hitbox",
							true
						)
						or adornee:FindFirstChild(
							"Button",
							true
						)
						or adornee:FindFirstChildWhichIsA(
							"BasePart",
							true
						)

					if part and part:IsA("BasePart") then
						return part, value
					end
				end
			end

			local guiParent = current.Parent

			if guiParent then

				if guiParent:IsA("BasePart") then
					return guiParent, value
				end

				if guiParent:IsA("Model") then
					local part =
						guiParent.PrimaryPart
						or guiParent:FindFirstChild(
							"Hitbox",
							true
						)
						or guiParent:FindFirstChild(
							"Button",
							true
						)
						or guiParent:FindFirstChildWhichIsA(
							"BasePart",
							true
						)

					if part and part:IsA("BasePart") then
						return part, value
					end
				end
			end
		end

		current = current.Parent
	end

	local parent = gui.Parent

	while parent and parent ~= workspace do

		if parent:IsA("BasePart") then
			return parent, value
		end

		if parent:IsA("Model") then

			local hitbox =
				parent:FindFirstChild(
					"Hitbox",
					true
				)

			if hitbox and hitbox:IsA("BasePart") then
				return hitbox, value
			end

			local button =
				parent:FindFirstChild(
					"Button",
					true
				)

			if button and button:IsA("BasePart") then
				return button, value
			end

			local primary =
				parent.PrimaryPart

			if primary then
				return primary, value
			end

			local part =
				parent:FindFirstChildWhichIsA(
					"BasePart",
					true
				)

			if part then
				return part, value
			end
		end

		parent = parent.Parent
	end

	local guiParent = gui.Parent

	if guiParent then

		local nearestPart = nil

		for _, object in ipairs(
			guiParent:GetDescendants()
		) do

			if object:IsA("BasePart") then
				nearestPart = object
				break
			end
		end

		if nearestPart then
			return nearestPart, value
		end
	end

	return nil
end

-- REFRESH TARGETS
function Module.RefreshTargets()
	local targets = {}

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") then

			local value =
				extractWinValue(object.Name)

			if value then
				targets[value] = object
			end

		elseif object:IsA("TextLabel")
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

	return targets
end

print("===== WIN TARGETS =====")

for value, part in pairs(targets) do
	print(
		"+"
			.. tostring(value)
			.. " Win ->",
		part:GetFullName(),
		part.Position
	)
end

print("=======================")

-- GET TARGET
function Module.GetTarget(value)
	value = tonumber(value)

	if not value then
		return nil
	end

	if not State.TargetCache[value] then
		Module.RefreshTargets()
	end

	return State.TargetCache[value]
end

function Module.GetTargets()

	if next(State.TargetCache) == nil then
		Module.RefreshTargets()
	end

	return State.TargetCache
end

-- TARGET POSITION
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

-- STOP FLYING
function Module.StopFlying()
	State.Flying = false
	State.CurrentTarget = nil
end

function Module.IsFlying()
	return State.Flying
end

-- FLY TO PART
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

	-- Nếu đang bay thì không tạo chuyến bay thứ hai.
	if State.Flying then
		return false, "Already flying."
	end

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate = humanoid.AutoRotate
	local previousPlatformStand = humanoid.PlatformStand

	humanoid.AutoRotate = false

	-- Giảm ảnh hưởng physics trong lúc di chuyển.
	humanoid.PlatformStand = true

	local started = os.clock()
	local timeout = 20

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

		local current = root.Position
		local offset = destination - current
		local distance = offset.Magnitude

		-- Đã tới gần target.
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

		-- Tính tốc độ bay.
		local step =
			math.min(
				distance,
				State.FlySpeed * deltaTime
			)

		if offset.Magnitude > 0 then

			local nextPosition =
				current
				+ offset.Unit * step

			-- Xoá vận tốc physics còn sót lại.
			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			root.CFrame =
				CFrame.new(nextPosition)
		end
	end

	-- Chỉ snap nếu thực sự đã tới target.
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

	-- Khôi phục Humanoid.
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

-- FLY TO WIN
function Module.FlyToWin(winAmount)

	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount."
	end

	local target =
		Module.GetTarget(winAmount)

	if not target then

		-- Refresh lại một lần nữa để đảm bảo
		-- target mới xuất hiện được tìm thấy.
		Module.RefreshTargets()

		target =
			State.TargetCache[winAmount]
	end

	if not target then
		return false,
			("No +%d Win target was detected.")
			:format(winAmount)
	end

	if State.Flying then
		return false, "Already flying."
	end

	task.spawn(function()
		Module.FlyToPart(target)
	end)

	return true
end

-- CHARACTER LIFECYCLE
Connections.CharacterAdded =
	LocalPlayer.CharacterAdded:Connect(
		function(character)

			-- Dừng chuyến bay cũ.
			State.Flying = false
			State.CurrentTarget = nil

			-- Xoá collision cache của character cũ.
			table.clear(OriginalCollision)

			local humanoid =
				character:WaitForChild(
					"Humanoid",
					10
				)

			if humanoid then

				task.wait()

				applyCharacterSettings()

				-- Nếu No Clip đang bật thì áp dụng
				-- cho character mới.
				if State.NoClip then
					rememberCollision(character)
				end
			end
		end
	)

-- NO CLIP LOOP
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

		-- Lưu trạng thái collision trước.
		rememberCollision(character)

		for _, object in
			ipairs(character:GetDescendants())
		do

			if object:IsA("BasePart") then
				object.CanCollide = false
			end
		end
	end)

-- INITIAL SETTINGS
task.defer(function()
	applyCharacterSettings()

	if State.NoClip then
		local character = getCharacter()

		if character then
			rememberCollision(character)
		end
	end
end)

-- PUBLIC STATE
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
