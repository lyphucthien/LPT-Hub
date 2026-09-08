local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ESPModule = {}

local oldESPGui = playerGui:FindFirstChild("LPT_ESP_Screen")

if oldESPGui then
	oldESPGui:Destroy()
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "LPT_ESP_Screen"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
espGui.DisplayOrder = 999999
espGui.Parent = playerGui

local ESP = {
	Player = false,
	Island = false,
	Fruit = false
}

local ESPObjects = {}

local ESP_COLORS = {
	Player = Color3.fromRGB(56,189,248),
	Island = Color3.fromRGB(168,105,245),
	Fruit = Color3.fromRGB(74,222,128)
}

local islandConnections = {}
local fruitWatchers = {}
local playerConnections = {}

local renderConnection = nil
local workspaceChildAddedConnection = nil
local workspaceDescendantAddedConnection = nil
local workspaceDescendantRemovingConnection = nil

local function safeDisconnect(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

local function safeDestroy(object)
	if object then
		pcall(function()
			object:Destroy()
		end)
	end
end

local function getCharacterRoot()
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoidFrom(object)
	if not object then
		return nil
	end

	return object:FindFirstChildOfClass("Humanoid")
		or object:FindFirstChildWhichIsA("Humanoid", true)
end

--========================================================
-- WORLD ROOT
--========================================================

local function getESPModelPart(object)
	if not object or not object.Parent then
		return nil
	end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then
		return object:FindFirstChild("HumanoidRootPart", true)
			or object:FindFirstChild("Head", true)
			or object:FindFirstChild("Handle", true)
			or object:FindFirstChild("RootPart", true)
			or object.PrimaryPart
			or object:FindFirstChildWhichIsA("BasePart", true)
	end

	return object:FindFirstChildWhichIsA("BasePart", true)
end

local function getESPAdornee(object)
	if not object or not object.Parent then
		return nil
	end

	if object:IsA("Model") then
		return object
	end

	if object:IsA("BasePart") then
		return object
	end

	return getESPModelPart(object)
end

--========================================================
-- FRUIT DETECTION
--========================================================

local function isFruitObject(object)
	if not object or not object:IsA("Tool") then
		return false
	end

	return string.find(
		string.lower(object.Name),
		"fruit",
		1,
		true
	) ~= nil
end

local function isFruitHeld(object)
	if not object or not object:IsA("Tool") then
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")

	if backpack and object:IsDescendantOf(backpack) then
		return true
	end

	local character = player.Character

	if character and object:IsDescendantOf(character) then
		return true
	end

	return false
end

local function shouldESPFloatFruit(object)
	return isFruitObject(object)
		and object:IsDescendantOf(workspace)
		and not isFruitHeld(object)
end

--========================================================
-- REMOVE ESP
--========================================================

local function removeESP(object)
	local data = ESPObjects[object]

	if not data then
		return
	end

	safeDestroy(data.Highlight)
	safeDestroy(data.Label)

	ESPObjects[object] = nil
end

local function clearESPType(typeName)
	local toRemove = {}

	for object, data in pairs(ESPObjects) do
		if data.Type == typeName then
			table.insert(toRemove, object)
		end
	end

	for _, object in ipairs(toRemove) do
		removeESP(object)
	end
end

--========================================================
-- CREATE ESP
--========================================================

local function createESP(object, typeName, displayName)
	if not object or not object.Parent then
		return false
	end

	if not ESP[typeName] then
		return false
	end

	-- Fruit chỉ ESP khi nằm ngoài Character / Backpack
	if typeName == "Fruit"
		and not shouldESPFloatFruit(object) then

		removeESP(object)
		return false
	end

	if ESPObjects[object] then
		return true
	end

	local adornee = getESPAdornee(object)
	local worldPart = getESPModelPart(object)

	if not adornee or not worldPart then
		return false
	end

	local color = ESP_COLORS[typeName]

	--====================================================
	-- HIGHLIGHT
	--====================================================

	local highlight = nil

	if typeName ~= "Island" then
		local h = Instance.new("Highlight")

		h.Name = "LPT_ESP_Highlight"
		h.Adornee = adornee
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = 0.78
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Enabled = true

		h.Parent = espGui

		highlight = h
	end

	--====================================================
	-- LABEL
	--====================================================

	local label = Instance.new("TextLabel")

	label.Name = "LPT_ESP_Label"
	label.Size = UDim2.fromOffset(240,44)
	label.AnchorPoint = Vector2.new(0.5,0.5)
	label.BackgroundTransparency = 1

	label.Text = displayName or object.Name

	label.TextColor3 =
		typeName == "Island"
		and Color3.fromRGB(255,255,255)
		or color

	label.TextStrokeColor3 = Color3.new(0,0,0)
	label.TextStrokeTransparency = 0.1
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	label.Visible = false
	label.ZIndex = 100

	label.Parent = espGui

	ESPObjects[object] = {
		Type = typeName,
		Highlight = highlight,
		Label = label,
		WorldPart = worldPart,
		Name = displayName or object.Name
	}

	return true
end

--========================================================
-- PLAYER ESP
--========================================================

local function addPlayerESP(targetPlayer)
	if targetPlayer == player then
		return
	end

	if not ESP.Player then
		return
	end

	local character = targetPlayer.Character

	if not character or not character.Parent then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	for _ = 1, 10 do
		if getESPModelPart(character) then
			break
		end

		task.wait(0.1)
	end

	if not ESP.Player then
		return
	end

	if not targetPlayer.Parent then
		return
	end

	if not character.Parent then
		return
	end

	createESP(
		character,
		"Player",
		targetPlayer.DisplayName
	)
end

local function refreshPlayerESP()
	clearESPType("Player")

	if not ESP.Player then
		return
	end

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then
			task.spawn(function()
				addPlayerESP(target)
			end)
		end
	end
end

local function watchPlayer(target)
	if target == player then
		return
	end

	if playerConnections[target] then
		for _, connection in pairs(playerConnections[target]) do
			safeDisconnect(connection)
		end
	end

	playerConnections[target] = {}

	--====================================================
	-- CHARACTER ADDED
	--====================================================

	playerConnections[target].CharacterAdded =
		target.CharacterAdded:Connect(function(character)

			removeESP(character)

			local humanoid =
				character:WaitForChild("Humanoid", 10)

			if not humanoid then
				return
			end

			task.wait(0.15)

			if ESP.Player then
				addPlayerESP(target)
			end
		end)

	--====================================================
	-- CHARACTER REMOVING
	--====================================================

	playerConnections[target].CharacterRemoving =
		target.CharacterRemoving:Connect(function(character)

			removeESP(character)

		end)

	--====================================================
	-- PLAYER REMOVING
	--====================================================

	playerConnections[target].AncestryChanged =
		target.AncestryChanged:Connect(function(_, parent)

			if not parent then
				if target.Character then
					removeESP(target.Character)
				end
			end
		end)

	--====================================================
	-- DISPLAY NAME
	--====================================================

	playerConnections[target].DisplayName =
		target:GetPropertyChangedSignal("DisplayName"):Connect(function()

			local character = target.Character

			if not character then
				return
			end

			local data = ESPObjects[character]

			if data
				and data.Label
				and data.Label.Parent then

				data.Name = target.DisplayName
				data.Label.Text = target.DisplayName
			end
		end)

	--====================================================
	-- TEAM
	--====================================================

	playerConnections[target].Team =
		target:GetPropertyChangedSignal("Team"):Connect(function()

			if not ESP.Player then
				return
			end

			addPlayerESP(target)

		end)

	if target.Character and ESP.Player then
		task.defer(function()
			addPlayerESP(target)
		end)
	end
end

--========================================================
-- INITIAL PLAYER WATCHERS
--========================================================

for _, target in ipairs(Players:GetPlayers()) do
	if target ~= player then
		watchPlayer(target)
	end
end

--========================================================
-- PLAYER ADDED / REMOVING
--========================================================

playerConnections.PlayerAdded =
	Players.PlayerAdded:Connect(function(target)

		watchPlayer(target)

		if ESP.Player then
			task.defer(function()
				addPlayerESP(target)
			end)
		end
	end)

playerConnections.PlayerRemoving =
	Players.PlayerRemoving:Connect(function(target)

		if target.Character then
			removeESP(target.Character)
		end

		if playerConnections[target] then

			for _, connection in pairs(playerConnections[target]) do
				safeDisconnect(connection)
			end

			playerConnections[target] = nil
		end
	end)

--========================================================
-- ISLAND ESP
--========================================================

local function scanIslandESP()
	if not ESP.Island then
		return
	end

	local map = workspace:FindFirstChild("Map")

	if not map then
		return
	end

	for _, island in ipairs(map:GetChildren()) do

		if island:IsA("Model") then

			createESP(
				island,
				"Island",
				island.Name
			)

		end
	end
end

local function setupIslandESPWatcher()
	if islandConnections.Setup then
		return
	end

	local map = workspace:FindFirstChild("Map")

	if not map then
		return
	end

	islandConnections.Setup = true

	islandConnections.Added =
		map.ChildAdded:Connect(function(object)

			if not ESP.Island then
				return
			end

			if object:IsA("Model") then

				task.wait(0.1)

				if object.Parent
					and ESP.Island then

					createESP(
						object,
						"Island",
						object.Name
					)

				end
			end
		end)

	islandConnections.Removed =
		map.ChildRemoved:Connect(function(object)

			removeESP(object)

		end)
end

--========================================================
-- MAP LOAD WATCHER
--========================================================

workspaceChildAddedConnection =
	workspace.ChildAdded:Connect(function(object)

		if object.Name == "Map"
			and (
				object:IsA("Folder")
				or object:IsA("Model")
			) then

			task.defer(function()

				if not object.Parent then
					return
				end

				islandConnections.Setup = nil

				setupIslandESPWatcher()

				if ESP.Island then

					clearESPType("Island")
					scanIslandESP()

				end
			end)
		end
	end)

--========================================================
-- FRUIT ESP
--========================================================

local function refreshOneFruit(object)
	if not object
		or not object.Parent
		or not isFruitObject(object) then

		return
	end

	if not ESP.Fruit then
		removeESP(object)
		return
	end

	if not shouldESPFloatFruit(object) then
		removeESP(object)
		return
	end

	for _ = 1, 12 do

		if not object.Parent
			or not shouldESPFloatFruit(object)
			or not ESP.Fruit then

			return
		end

		if getESPModelPart(object) then

			createESP(
				object,
				"Fruit",
				object.Name
			)

			return
		end

		task.wait(0.1)
	end
end

local function watchFruit(object)
	if not object
		or not object:IsA("Tool")
		or not isFruitObject(object) then

		return
	end

	if fruitWatchers[object] then
		return
	end

	local connection

	connection =
		object.AncestryChanged:Connect(function()

			if not object.Parent then

				safeDisconnect(connection)

				fruitWatchers[object] = nil

				removeESP(object)

				return
			end

			task.defer(function()
				refreshOneFruit(object)
			end)
		end)

	fruitWatchers[object] = connection

	task.defer(function()
		refreshOneFruit(object)
	end)
end

local function scanAllFruits()
	if not ESP.Fruit then
		clearESPType("Fruit")
		return
	end

	for _, object in ipairs(workspace:GetDescendants()) do

		if object:IsA("Tool")
			and isFruitObject(object) then

			watchFruit(object)

		end
	end
end

--========================================================
-- WORKSPACE FRUIT WATCHER
--========================================================

workspaceDescendantAddedConnection =
	workspace.DescendantAdded:Connect(function(object)

		if object:IsA("Tool")
			and isFruitObject(object) then

			watchFruit(object)
			return
		end

		local parent = object.Parent

		if parent
			and parent:IsA("Tool")
			and isFruitObject(parent) then

			watchFruit(parent)

			task.defer(function()
				refreshOneFruit(parent)
			end)
		end
	end)

workspaceDescendantRemovingConnection =
	workspace.DescendantRemoving:Connect(function(object)

		if object and isFruitObject(object) then
			removeESP(object)
		end
	end)

--========================================================
-- RENDER UPDATE
--========================================================

renderConnection =
	RunService.RenderStepped:Connect(function()

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local root = getCharacterRoot()

		if not root then
			return
		end

		local toRemove = {}

		for object, data in pairs(ESPObjects) do

			if not object
				or not object.Parent
				or not data.WorldPart
				or not data.WorldPart.Parent
				or not data.Label
				or not data.Label.Parent then

				table.insert(toRemove, object)
				continue
			end

			--============================================
			-- FRUIT VALIDATION
			--============================================

			if data.Type == "Fruit"
				and not shouldESPFloatFruit(object) then

				table.insert(toRemove, object)
				continue
			end

			--============================================
			-- WORLD PART UPDATE
			--============================================

			local worldPart = data.WorldPart

			if not worldPart
				or not worldPart.Parent then

				worldPart = getESPModelPart(object)

				if worldPart then

					data.WorldPart = worldPart

				else

					table.insert(toRemove, object)
					continue
				end
			end

			local position = worldPart.Position

			local distance = math.floor((root.Position-position).Magnitude + 0.5)

			local screenPosition, onScreen =
				camera:WorldToViewportPoint(
					position + Vector3.new(0,3,0)
				)

			if onScreen and screenPosition.Z > 0 then

				data.Label.Position =
					UDim2.fromOffset(
						screenPosition.X,
						screenPosition.Y
					)

				data.Label.Visible = true

			else

				data.Label.Visible = false

			end

			--============================================
			-- PLAYER INFO
			--============================================

			if data.Type == "Player" then

				local targetPlayer =
					Players:GetPlayerFromCharacter(object)

				local humanoid =
					targetPlayer
					and targetPlayer.Character
					and targetPlayer.Character:FindFirstChildOfClass("Humanoid")

				local healthText = "N/A / N/A"

				if humanoid then

					healthText =
						string.format(
							"%d / %d",

							math.max(
								0,
								math.floor(
									humanoid.Health + 0.5
								)
							),

							math.floor(
								humanoid.MaxHealth + 0.5
							)
						)

				end

				data.Label.Text =
					string.format(
						"%s [%dm]\n%s",
						data.Name,
						distance,
						healthText
					)

			else

				data.Label.Text =
					string.format(
						"%s [%dm]",
						data.Name,
						distance
					)

			end
		end

		for _, object in ipairs(toRemove) do
			removeESP(object)
		end
	end)

--========================================================
-- PERIODIC REFRESH
--========================================================

task.spawn(function()

	while espGui
		and espGui.Parent do

		task.wait(0.5)

		if ESP.Fruit then
			scanAllFruits()
		end

		if ESP.Island then

			setupIslandESPWatcher()

			if workspace:FindFirstChild("Map") then
				scanIslandESP()
			end
		end
	end
end)

--========================================================
-- PUBLIC API
--========================================================

function ESPModule:Set(typeName, enabled)

	if ESP[typeName] == nil then
		return
	end

	ESP[typeName] = enabled == true

	if typeName == "Player" then

		refreshPlayerESP()

	elseif typeName == "Fruit" then

		clearESPType("Fruit")

		if ESP.Fruit then
			scanAllFruits()
		end

	elseif typeName == "Island" then

		clearESPType("Island")

		if ESP.Island then
			setupIslandESPWatcher()
			scanIslandESP()
		end
	end
end

function ESPModule:Get(typeName)

	return ESP[typeName] == true
end

function ESPModule:Clear()

	clearESPType("Player")
	clearESPType("Island")
	clearESPType("Fruit")

end

--========================================================
-- DESTROY
--========================================================

function ESPModule:Destroy()

	self:Clear()

	for key, connection in pairs(islandConnections) do

		if connection then
			safeDisconnect(connection)
		end

		islandConnections[key] = nil
	end

	for object, connection in pairs(fruitWatchers) do

		safeDisconnect(connection)

		fruitWatchers[object] = nil
	end

	for target, connections in pairs(playerConnections) do

		if type(connections) == "table" then

			for key, connection in pairs(connections) do
				safeDisconnect(connection)
				connections[key] = nil
			end
		else

			safeDisconnect(connections)

		end

		playerConnections[target] = nil
	end

	safeDisconnect(workspaceChildAddedConnection)
	safeDisconnect(workspaceDescendantAddedConnection)
	safeDisconnect(workspaceDescendantRemovingConnection)

	workspaceChildAddedConnection = nil
	workspaceDescendantAddedConnection = nil
	workspaceDescendantRemovingConnection = nil

	safeDisconnect(renderConnection)
	renderConnection = nil

	safeDestroy(espGui)
	espGui = nil
end

return ESPModule