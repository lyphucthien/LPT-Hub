local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Module = {}

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
-- SETTINGS API
--========================================================

function Module.SetWalkSpeed(value)
	State.WalkSpeed = getNumber(value, 1, 500, State.WalkSpeed)
	applyCharacterSettings()

	return State.WalkSpeed
end

function Module.GetWalkSpeed()
	return State.WalkSpeed
end

function Module.SetJumpPower(value)
	State.JumpPower = getNumber(value, 1, 500, State.JumpPower)
	applyCharacterSettings()

	return State.JumpPower
end

function Module.GetJumpPower()
	return State.JumpPower
end

function Module.SetFlySpeed(value)
	State.FlySpeed = getNumber(value, 10, 500, State.FlySpeed)
	return State.FlySpeed
end

function Module.GetFlySpeed()
	return State.FlySpeed
end

function Module.SetFlyHeight(value)
	State.FlyHeight = getNumber(value, 0, 100, State.FlyHeight)
	return State.FlyHeight
end

function Module.GetFlyHeight()
	return State.FlyHeight
end

function Module.SetInfiniteJump(enabled)
	State.InfiniteJump = enabled == true

	if State.InfiniteJump then
		if not Connections.InfiniteJump then
			Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
				if not State.InfiniteJump then
					return
				end

				local humanoid = getHumanoid()
				if humanoid then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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

function Module.SetNoClip(enabled)
	State.NoClip = enabled == true

	if not State.NoClip then
		local character = getCharacter()

		if character then
			for _, object in ipairs(character:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CanCollide = true
				end
			end
		end
	end

	return State.NoClip
end

function Module.GetNoClip()
	return State.NoClip
end

--========================================================
-- WIN TARGET DETECTION
--========================================================

local function normalize(text)
	return tostring(text or "")
		:lower()
		:gsub(",", "")
end

local function extractWinValue(text)
	local normalized = normalize(text)

	-- +1 Win
	-- +3 Win
	-- +10 Wins
	local value = normalized:match("%+%s*(%d+)%s*win")

	if value then
		return tonumber(value)
	end

	return nil
end

local function findPartFromGui(gui)
	if not gui:IsA("TextLabel") and not gui:IsA("TextButton") then
		return nil
	end

	local value = extractWinValue(gui.Text)
	if not value then
		return nil
	end

	local parent = gui.Parent

	while parent and parent ~= workspace do
		if parent:IsA("BasePart") then
			return parent, value
		end

		if parent:IsA("Model") then
			local primary = parent.PrimaryPart

			if primary then
				return primary, value
			end

			local hitbox = parent:FindFirstChild("Hitbox")
			if hitbox and hitbox:IsA("BasePart") then
				return hitbox, value
			end

			local anyPart = parent:FindFirstChildWhichIsA("BasePart", true)
			if anyPart then
				return anyPart, value
			end
		end

		parent = parent.Parent
	end

	return nil
end

function Module.RefreshTargets()
	local targets = {}

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") then
			local value = extractWinValue(object.Name)

			if value then
				targets[value] = object
			end

		elseif object:IsA("TextLabel") or object:IsA("TextButton") then
			local part, value = findPartFromGui(object)

			if part and value then
				targets[value] = part
			end
		end
	end

	State.TargetCache = targets

	return targets
end

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

local function targetPosition(part)
	if not part or not part.Parent or not part:IsA("BasePart") then
		return nil
	end

	return part.Position + Vector3.new(0, State.FlyHeight, 0)
end

--========================================================
-- AUTO FLY
--========================================================

function Module.StopFlying()
	State.Flying = false
	State.CurrentTarget = nil
end

function Module.IsFlying()
	return State.Flying
end

function Module.FlyToPart(part)
	if not part or not part:IsA("BasePart") then
		return false, "Invalid target part."
	end

	local root = getRoot()
	local humanoid = getHumanoid()

	if not root or not humanoid then
		return false, "Character is not ready."
	end

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	local started = os.clock()
	local timeout = 20
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

		if distance <= 3 then
			reached = true
			break
		end

		local deltaTime = RunService.Heartbeat:Wait()

		if not State.Flying then
			break
		end

		local step = math.min(
			distance,
			State.FlySpeed * deltaTime
		)

		local nextPosition = current + offset.Unit * step

		root.CFrame = CFrame.new(nextPosition)
	end

	-- Chỉ snap tới target nếu chuyến bay thực sự vẫn đang hoạt động.
	if reached and State.Flying and root.Parent and part.Parent then
		local destination = targetPosition(part)

		if destination then
			root.CFrame = CFrame.new(destination)
		end
	end

	humanoid.AutoRotate = previousAutoRotate

	State.Flying = false
	State.CurrentTarget = nil

	return reached
end

function Module.FlyToWin(winAmount)
	winAmount = tonumber(winAmount)

	if not winAmount then
		return false, "Invalid Win amount."
	end

	local target = Module.GetTarget(winAmount)

	if not target then
		return false, ("No +%d Win target was detected."):format(winAmount)
	end

	if State.Flying then
		return false, "Already flying."
	end

	task.spawn(function()
		Module.FlyToPart(target)
	end)

	return true
end

--========================================================
-- CHARACTER LIFECYCLE
--========================================================

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid", 10)

	if humanoid then
		task.wait()
		applyCharacterSettings()
	end

	State.Flying = false
	State.CurrentTarget = nil
end)

Connections.NoClip = RunService.Stepped:Connect(function()
	if not State.NoClip then
		return
	end

	local character = getCharacter()

	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.CanCollide = false
		end
	end
end)

-- Apply settings immediately if the character already exists.
task.defer(applyCharacterSettings)

-- Public state accessor for debugging/UI integrations.
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