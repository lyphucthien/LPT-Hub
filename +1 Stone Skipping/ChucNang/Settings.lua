local Settings = {}
local API
local destroyed = false
local performanceEnabled = false
local originalProperties = {}

local function remember(instance, property)
    originalProperties[instance] = originalProperties[instance] or {}
    if originalProperties[instance][property] == nil then
        local ok, value = pcall(function() return instance[property] end)
        if ok then originalProperties[instance][property] = value end
    end
end

local function setProperty(instance, property, value)
    remember(instance, property)
    pcall(function() instance[property] = value end)
end

local function applyPerformance()
    local workspaceService = game:GetService("Workspace")
    local lighting = game:GetService("Lighting")
    setProperty(lighting, "GlobalShadows", false)

    for _, instance in ipairs(workspaceService:GetDescendants()) do
        if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
            or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
            setProperty(instance, "Enabled", false)
        elseif instance:IsA("PostEffect") then
            setProperty(instance, "Enabled", false)
        end
    end
end

local function restorePerformance()
    for instance, properties in pairs(originalProperties) do
        if instance and instance.Parent then
            for property, value in pairs(properties) do
                pcall(function() instance[property] = value end)
            end
        end
    end
    table.clear(originalProperties)
end

function Settings:Init(api)
    API = api
end

function Settings:Set(name, value)
    if destroyed or name ~= "PerformanceMode" then return false end
    performanceEnabled = value == true
    if performanceEnabled then
        applyPerformance()
        if API then API.SetStatus("Performance Mode enabled (client-side effects reduced)", true) end
    else
        restorePerformance()
        if API then API.SetStatus("Performance Mode disabled; saved effect settings restored", true) end
    end
    return true
end

function Settings:Action(name)
    if destroyed then return false end
    if name == "RestorePerformance" then
        restorePerformance()
        performanceEnabled = false
        if API then API.SetStatus("Restored saved lighting and effect settings", true) end
        return true
    end
    return false
end

function Settings:Get(name)
    if name == "PerformanceMode" then return performanceEnabled end
    return false
end

function Settings:Destroy()
    if destroyed then return end
    destroyed = true
    restorePerformance()
end

return Settings
