local Pets = {}
local API
local destroyed = false
local state = { AutoHatch = false }
local lastWarning = 0

local function hatchOnce()
    if destroyed or not API then return false end
    local button = API.FindButton({"hatch egg", "hatch 1", "hatch", "open egg", "open"}, {"egg", "hatch", "pet"})
    if button and API.ClickButton(button) then
        API.SetStatus("Pressed the visible Hatch/Open Egg control", true)
        return true
    end
    if os.clock() - lastWarning > 8 then
        lastWarning = os.clock()
        API.SetStatus("No visible Hatch/Open Egg button found. Open an egg panel first.", false)
    end
    return false
end

function Pets:Init(api)
    API = api
end

function Pets:Set(name, value)
    if destroyed or name ~= "AutoHatch" then return false end
    state.AutoHatch = value == true
    if state.AutoHatch then
        task.spawn(function()
            while not destroyed and state.AutoHatch do
                pcall(hatchOnce)
                task.wait(2.2)
            end
        end)
    end
    if API then API.SetStatus("Auto Hatch " .. (state.AutoHatch and "enabled" or "disabled"), true) end
    return true
end

function Pets:Action(name)
    if destroyed or not API then return false end
    if name == "HatchOnce" then return hatchOnce() end
    if name == "EquipBestPets" then
        local button = API.FindButton({"equip best pets", "equip best"}, {"pet", "pets", "equipped"})
        if button and API.ClickButton(button) then
            API.SetStatus("Pressed the visible Equip Best Pets control", true)
            return true
        end
        API.SetStatus("No pet-related Equip Best button found. Equip pets manually in the inventory.", false)
        return false
    elseif name == "OpenEggShop" then
        local button = API.FindButton({"egg shop", "pet shop", "eggs", "pets"}, {"egg", "pet"})
        if button and API.ClickButton(button) then
            API.SetStatus("Opened a visible egg/pet shop control", true)
            return true
        end
        API.SetStatus("No visible Egg/Pet Shop button found", false)
        return false
    end
    return false
end

function Pets:Destroy()
    destroyed = true
    state.AutoHatch = false
end

return Pets
