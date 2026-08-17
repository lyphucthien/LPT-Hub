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
				UserInputService.JumpRequest:Connect(
					function()

						if not State.InfiniteJump then
							return
						end

						local humanoid = getHumanoid()

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
				object.CanCollide = original
			end
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

	local normalized =
		cleanText(text)

	-- Common formats:
	-- +1 Win
	-- +3 Wins
	-- +10 Win
	-- +1K Win
	-- +1M Win
	-- 1 Win
	-- Win 1
	-- 1.5k wins
	-- win +1

	local patterns = {
		"%+%s*([%d%.]+)%s*([km]?)%s*wins?",
		"([%d%.]+)%s*([km]?)%s*wins?",
		"wins?%s*[%+%-]*%s*([%d%.]+)%s*([km]?)",
		"[%+%-]?%s*([%d%.]+)%s*([km]?)%s*win",
	}

	for _, pattern in ipairs(patterns) do
		local number, suffix =
			normalized:match(pattern)

		if number then
			local value =
				tonumber(number)

			if value then
				suffix = suffix or ""

				if suffix == "k" then
					value *= 1000
				elseif suffix == "m" then
					value *= 1000000
				end

				return math.floor(value + 0.5)
			end
		end
	end

	return nil
end

--========================================================
-- GET CLOSEST PART
--========================================================

local function getClosestPart(position, container)

	if not position or not container then
		return nil
	end

	local closest = nil
	local closestDistance = math.huge

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local distance =
				(object.Position - position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closest = object
			end
		end
	end

	return closest
end

--========================================================
-- FIND PART DIRECTLY AROUND GUI
--========================================================

local function findDirectPart(gui)

	if not gui then
		return nil
	end

	--====================================================
	-- 1. GUI Parent
	--====================================================

	local parent = gui.Parent

	if parent and parent:IsA("BasePart") then
		return parent
	end

	--====================================================
	-- 2. Parent Model
	--====================================================

	if parent and parent:IsA("Model") then

		-- Nếu parent có đúng 1 BasePart
		local parts = {}

		for _, object in ipairs(
			parent:GetDescendants()
		) do

			if object:IsA("BasePart") then
				table.insert(parts, object)
			end
		end

		if #parts == 1 then
			return parts[1]
		end
	end

	--====================================================
	-- 3. BillboardGui / SurfaceGui
	--====================================================

	local current = gui

	while current and current ~= workspace do

		if current:IsA("BillboardGui")
			or current:IsA("SurfaceGui")
		then

			-- Adornee là chính xác nhất
			if current.Adornee then

				local adornee =
					current.Adornee

				if adornee:IsA("BasePart") then
					return adornee
				end

				if adornee:IsA("Model") then

					-- Ưu tiên part có tên Button
					local button =
						adornee:FindFirstChild(
							"Button",
							true
						)

					if button
						and button:IsA("BasePart")
					then
						return button
					end

					-- Hitbox
					local hitbox =
						adornee:FindFirstChild(
							"Hitbox",
							true
						)

					if hitbox
						and hitbox:IsA("BasePart")
					then
						return hitbox
					end

					-- Nếu model chỉ có 1 part
					local parts = {}

					for _, object in ipairs(
						adornee:GetDescendants()
					) do

						if object:IsA("BasePart") then
							table.insert(
								parts,
								object
							)
						end
					end

					if #parts == 1 then
						return parts[1]
					end
				end
			end

			-- Parent của BillboardGui
			local guiParent =
				current.Parent

			if guiParent then

				if guiParent:IsA("BasePart") then
					return guiParent
				end
			end
		end

		current = current.Parent
	end

	return nil
end

--========================================================
-- FIND GUI TARGET
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
	-- FIRST: direct / exact target
	--====================================================

	local direct =
		findDirectPart(gui)

	if direct then
		return direct, value
	end

	--====================================================
	-- FIND BILLBOARD / SURFACE GUI
	--====================================================

	local current = gui

	while current
		and current ~= workspace
	do

		if current:IsA("BillboardGui")
			or current:IsA("SurfaceGui")
		then

			-- Adornee
			if current.Adornee then

				local adornee =
					current.Adornee

				if adornee:IsA("BasePart") then
					return adornee, value
				end

				if adornee:IsA("Model") then

					local position =
						adornee:GetPivot().Position

					local closest =
						getClosestPart(
							position,
							adornee
						)

					if closest then
						return closest, value
					end
				end
			end

			-- Parent của GUI
			local parent =
				current.Parent

			if parent then

				if parent:IsA("BasePart") then
					return parent, value
				end

				if parent:IsA("Model") then

					local closest =
						getClosestPart(
							parent:GetPivot().Position,
							parent
						)

					if closest then
						return closest, value
					end
				end
			end
		end

		current = current.Parent
	end

	return nil
end

--========================================================
-- FIND TARGET BY INSTANCE NAME
--========================================================

local function findTargetByName(object)

	if not object then
		return nil
	end

	local value =
		extractWinValue(object.Name)

	if not value then
		return nil
	end

	if object:IsA("BasePart") then
		return value, object
	end

	if object:IsA("Model") then

		-- Button
		local button =
			object:FindFirstChild(
				"Button",
				true
			)

		if button
			and button:IsA("BasePart")
		then
			return value, button
		end

		-- Hitbox
		local hitbox =
			object:FindFirstChild(
				"Hitbox",
				true
			)

		if hitbox
			and hitbox:IsA("BasePart")
		then
			return value, hitbox
		end

		-- Part tên Win
		for _, part in ipairs(
			object:GetDescendants()
		) do

			if part:IsA("BasePart") then

				local name =
					part.Name:lower()

				if name:find("win")
					or name:find("button")
					or name:find("hitbox")
				then
					return value, part
				end
			end
		end

		-- Chỉ dùng PrimaryPart nếu thực sự cần
		if object.PrimaryPart then
			return value, object.PrimaryPart
		end
	end

	return nil
end

--========================================================
-- REFRESH TARGETS
--========================================================

function Module.RefreshTargets()

	local targets = {}

	--====================================================
	-- PASS 1
	-- MODEL / PART NAME
	--====================================================

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("Model")
			or object:IsA("BasePart")
		then

			local value, part =
				findTargetByName(object)

			if value and part then

				-- Chỉ nhận target hợp lệ
				if not targets[value] then
					targets[value] = part
				end
			end
		end
	end

	--====================================================
	-- PASS 2
	-- GUI
	--====================================================

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("TextLabel")
			or object:IsA("TextButton")
		then

			local part, value =
				findPartFromGui(object)

			if part
				and value
				and part:IsA("BasePart")
			then

				-- GUI có thể chính xác hơn
				-- target lấy từ tên.
				targets[value] = part
			end
		end
	end

	--====================================================
	-- CLEAN INVALID
	--====================================================

	for value, part in pairs(targets) do

		if not part
			or not part.Parent
			or not part:IsA("BasePart")
		then

			targets[value] = nil
		end
	end

	State.TargetCache = targets

	--====================================================
	-- DEBUG
	--====================================================

	print("")
	print("===== WIN TARGETS =====")

	local count = 0

	local sortedValues = {}

	for value in pairs(targets) do
		table.insert(
			sortedValues,
			value
		)
	end

	table.sort(
		sortedValues,
		function(a, b)
			return a < b
		end
	)

	for _, value in ipairs(
		sortedValues
	) do

		local part =
			targets[value]

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
-- TARGET POSITION
--========================================================

local function targetPosition(part)

	if not part
		or not part.Parent
		or not part:IsA("BasePart")
	then
		return nil
	end

	--====================================================
	-- QUAN TRỌNG:
	-- Không cộng Size.Y của award model.
	-- Chỉ lấy vị trí chính xác của part target.
	--====================================================

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

		-- Đã tới
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

			-- Xóa physics
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
	-- SNAP ĐÚNG TARGET
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

	-- Refresh target
	Module.RefreshTargets()

	local target =
		State.TargetCache[winAmount]

	if not target then

		return false,
			("No +%d Win target was detected.")
				:format(winAmount)
	end

	print(
		("[FlyToWin] +%d -> %s")
			:format(
				winAmount,
				target:GetFullName()
			)
	)

	task.spawn(
		function()

			local success, reason =
				Module.FlyToPart(
					target
				)

			print(
				("[FlyToWin] Finished +%d | success=%s | reason=%s")
					:format(
						winAmount,
						tostring(success),
						tostring(reason or "")
					)
			)
		end
	)

	return true
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