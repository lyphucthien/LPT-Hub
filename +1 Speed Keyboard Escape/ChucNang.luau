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
	FlyHeight = 0,

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

local function isBasePart(object)
	return object
		and object:IsA("BasePart")
		and object.Parent
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

	-- 2.5K / 10K / 1M
	local number, suffix =
		s:match("(%d+%.?%d*)([kKmM])")

	if number then
		local n = tonumber(number)

		if n then
			if suffix == "k" or suffix == "K" then
				return n * 1000
			elseif suffix == "m" or suffix == "M" then
				return n * 1000000
			end
		end
	end

	-- Số thường
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
-- TARGET SCORING
--========================================================

local function collectObjectText(object)
	local texts = {}

	if not object then
		return ""
	end

	table.insert(texts, tostring(object.Name))

	local current = object.Parent

	for _ = 1, 5 do
		if not current then
			break
		end

		table.insert(texts, tostring(current.Name))

		current = current.Parent
	end

	for _, descendant in ipairs(object:GetDescendants()) do
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
-- FIND PART FROM GUI
--========================================================

local function findPartFromGui(gui)
	if not gui then
		return nil
	end

	-- BillboardGui / SurfaceGui can have Adornee
	if gui:IsA("BillboardGui")
		or gui:IsA("SurfaceGui")
	then
		if gui.Adornee
			and gui.Adornee:IsA("BasePart")
		then
			return gui.Adornee
		end
	end

	-- Walk parents
	local current = gui.Parent

	while current do
		if current:IsA("BasePart") then
			return current
		end

		if current:IsA("Model") then
			local primary =
				current.PrimaryPart

			if primary
				and primary:IsA("BasePart")
			then
				return primary
			end

			local button =
				current:FindFirstChild(
					"Button",
					true
				)

			if button
				and button:IsA("BasePart")
			then
				return button
			end

			return current:FindFirstChildWhichIsA(
				"BasePart",
				true
			)
		end

		current = current.Parent
	end

	return nil
end

--========================================================
-- FIND "LAY WIN" TARGET
--========================================================

local function findGetWinTarget()
	local bestPart = nil
	local bestScore = -math.huge

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		-- Text GUI
		if object:IsA("TextLabel")
			or object:IsA("TextButton")
			or object:IsA("TextBox")
		then

			local text =
				tostring(object.Text)

			local isWinButton =
				containsText(text, "Lấy Win")
				or containsText(text, "Lay Win")
				or containsText(text, "Get Win")
				or containsText(text, "Claim Win")
				or containsText(text, "Claim")

			if isWinButton then
				local part =
					findPartFromGui(object)

				if isBasePart(part) then
					local score = 1000

					if hasInteractiveObject(part) then
						score += 500
					end

					if containsText(
						part.Name,
						"button"
					) then
						score += 100
					end

					if score > bestScore then
						bestScore = score
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart
end

--========================================================
-- FIND TARGET PART INSIDE CONTAINER
--========================================================

local function findTargetPart(container)
	if not container then
		return nil
	end

	-- Nếu chính nó là part
	if isBasePart(container) then
		return container
	end

	local candidates = {}

	--====================================================
	-- COLLECT PARTS
	--====================================================

	for _, object in ipairs(
		container:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local score = 0
			local name = string.lower(
				object.Name
			)

			-- Interactive
			if hasInteractiveObject(object) then
				score += 300
			end

			-- Exact button naming
			if name == "button" then
				score += 250
			end

			if name == "winbutton" then
				score += 350
			end

			if name == "getwinbutton" then
				score += 400
			end

			if name == "claimwinbutton" then
				score += 400
			end

			-- Name keywords
			if name:find("button", 1, true) then
				score += 150
			end

			if name:find("win", 1, true) then
				score += 150
			end

			if name:find("claim", 1, true) then
				score += 180
			end

			if name:find("get", 1, true) then
				score += 100
			end

			if name:find("finish", 1, true) then
				score += 80
			end

			if name:find("award", 1, true) then
				score += 80
			end

			-- Text inside this part/model
			local allText =
				collectObjectText(object)

			if containsText(
				allText,
				"Lấy Win"
			)
			or containsText(
				allText,
				"Lay Win"
			)
			or containsText(
				allText,
				"Get Win"
			)
			or containsText(
				allText,
				"Claim Win"
			)
			then
				score += 1000
			end

			table.insert(
				candidates,
				{
					part = object,
					score = score,
				}
			)
		end
	end

	table.sort(
		candidates,
		function(a, b)
			return a.score > b.score
		end
	)

	if candidates[1] then
		return candidates[1].part
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

		"stage" .. stageNumber,
		"stage-" .. stageNumber,
		"stage_" .. stageNumber,

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

local function findByWinValue(winValue)
	local bestPart = nil
	local bestScore = -math.huge

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local text =
				collectObjectText(object)

			local score = 0

			-- Exact win value
			local ownNumber =
				parseWinValue(object.Name)

			if ownNumber == winValue then
				score += 500
			end

			-- Win number in ancestor names
			local parent =
				object.Parent

			for _ = 1, 5 do
				if not parent then
					break
				end

				local parentNumber =
					parseWinValue(
						parent.Name
					)

				if parentNumber == winValue then
					score += 400
				end

				parent = parent.Parent
			end

			-- GUI text
			for _, descendant in ipairs(
				object:GetDescendants()
			) do

				if descendant:IsA("TextLabel")
					or descendant:IsA("TextButton")
					or descendant:IsA("TextBox")
				then

					local textNumber =
						parseWinValue(
							descendant.Text
						)

					if textNumber == winValue then
						score += 700
					end
				end
			end

			-- Strong preference to actual button
			local lowerName =
				string.lower(object.Name)

			if lowerName:find(
				"button",
				1,
				true
			) then
				score += 200
			end

			if lowerName:find(
				"win",
				1,
				true
			) then
				score += 200
			end

			if hasInteractiveObject(object) then
				score += 300
			end

			-- "Lấy Win" has highest priority
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
				score += 1000
			end

			if score > bestScore then
				bestScore = score
				bestPart = object
			end
		end
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

	print("")
	print("========================================")
	print("      LPT HUB - WIN TARGET SCAN")
	print("========================================")

	--====================================================
	-- FIRST: LOOK FOR GLOBAL "LAY WIN" BUTTON
	--====================================================

	local globalGetWin =
		findGetWinTarget()

	if globalGetWin then

		print(
			"[FOUND] Global Lấy Win button -> "
				.. globalGetWin:GetFullName()
		)
	end

	--====================================================
	-- SCAN EACH STAGE
	--====================================================

	for _, stageInfo in ipairs(WIN_STAGES) do

		local stageNumber =
			stageInfo.stage

		local winValue =
			stageInfo.value

		local target = nil

		--================================================
		-- METHOD 1
		--================================================

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

		--================================================
		-- METHOD 2
		--================================================

		if not target then

			target =
				findByWinValue(
					winValue
				)

		end

		--================================================
		-- METHOD 3
		--================================================

		if not target
			and globalGetWin
		then

			-- Chỉ dùng global target nếu
			-- thực sự có cấu trúc stage/win phù hợp.
			local text =
				collectObjectText(
					globalGetWin
				)

			local parsed =
				parseWinValue(text)

			if parsed == winValue then
				target =
					globalGetWin
			end
		end

		--================================================
		-- SAVE
		--================================================

		if isBasePart(target) then

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
	if next(State.TargetCache) == nil then
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

local function getTargetPosition(part)
	if not isBasePart(part) then
		return nil
	end

	-- QUAN TRỌNG:
	-- không cộng FlyHeight ở đây.
	-- dừng đúng tâm của target.

	return part.Position
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

	if not isBasePart(part) then
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

	--====================================================
	-- STATE
	--====================================================

	State.Flying = true
	State.CurrentTarget = part

	local previousAutoRotate =
		humanoid.AutoRotate

	local previousPlatformStand =
		humanoid.PlatformStand

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	--====================================================
	-- FLY
	--====================================================

	local started =
		os.clock()

	local timeout =
		30

	local reached =
		false

	while
		State.Flying
		and root.Parent
		and part.Parent
		and os.clock() - started < timeout
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

		if distance <= 1 then

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
			math.max(
				10,
				State.FlySpeed
			)

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

			-- Không set rotation của target.
			-- Chỉ thay đổi vị trí.
			root.CFrame =
				CFrame.new(
					nextPosition
				)
		end
	end

	--====================================================
	-- FINAL SNAP
	--====================================================

	if reached
		and State.Flying
		and root.Parent
		and part.Parent
	then

		local finalPosition =
			getTargetPosition(part)

		if finalPosition then

			root.AssemblyLinearVelocity =
				Vector3.zero

			root.AssemblyAngularVelocity =
				Vector3.zero

			-- SNAP ĐÚNG TARGET
			root.CFrame =
				CFrame.new(
					finalPosition
				)

			-- Giữ tại target một chút.
			-- Giúp TouchInterest / ClickDetector / trigger
			-- có thời gian xử lý.
			for _ = 1, 4 do

				RunService.Heartbeat:Wait()

				if not State.Flying then
					break
				end

				if root.Parent
					and part.Parent
				then

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

					root.CFrame =
						CFrame.new(
							finalPosition
						)

				else
					break
				end
			end
		end
	end

	--====================================================
	-- RESTORE HUMANOID
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
	-- VALIDATE
	--====================================================

	if not isBasePart(target) then

		Module.RefreshTargets()

		target =
			State.TargetCache[winAmount]
	end

	if not isBasePart(target) then

		return false,
			("No +%s Win target was detected.")
				:format(
					tostring(winAmount)
				)

	end

	print(
		("[FlyToWin] +%s -> %s")
			:format(
				tostring(winAmount),
				target:GetFullName()
			)
	)

	print(
		("[FlyToWin] Target Position -> %s")
			:format(
				tostring(
					target.Position
				)
			)
	)

	--====================================================
	-- FLY
	--====================================================

	local success, reason =
		Module.FlyToPart(
			target
		)

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
		("[FlyToWin] Reached +%s exactly")
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
				:format(
					stageNumber
				)
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

			-- Stop fly
			State.Flying = false
			State.CurrentTarget = nil

			-- Clear collision
			table.clear(
				OriginalCollision
			)

			-- Old targets invalid
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

					object.CanCollide =
						false

				end
			end
		end
	)

--========================================================
-- CHARACTER APPEARANCE
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

				rememberCollision(
					character
				)

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

--========================================================
-- DESTROY
--========================================================

function Module.Destroy()

	State.Flying = false
	State.CurrentTarget = nil

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
		restoreCollision(
			character
		)
	end

	table.clear(
		State.TargetCache
	)

end

return Module
