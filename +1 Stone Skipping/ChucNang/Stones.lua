local Stones = {}
local API
local destroyed = false

function Stones:Init(api)
    API = api
end

local function click(aliases, contexts, successText, failureText)
    if destroyed or not API then return false end
    local button = API.FindButton(aliases, contexts)
    if button and API.ClickButton(button) then
        API.SetStatus(successText, true)
        return true
    end
    API.SetStatus(failureText, false)
    return false
end

function Stones:Action(name)
    if destroyed then return false end
    if name == "OpenStoneShop" then
        return click(
            {"stone shop", "throwable shop", "stones", "throwables", "shop"},
            {"stone", "throwable"},
            "Opened a visible stone/throwable shop control",
            "Stone shop button not found. Open the shop from the game UI first."
        )
    elseif name == "EquipBestStone" then
        return click(
            {"equip best stone", "equip best throwable", "best stone", "best throwable"},
            {"stone", "throwable"},
            "Pressed the visible best-stone control",
            "No explicit Equip Best Stone/Throwable control found. Equip it manually in the stone inventory."
        )
    elseif name == "BuyNextStone" then
        return click(
            {"buy next stone", "buy best stone", "buy next throwable", "buy stone", "purchase stone", "buy"},
            {"stone", "throwable", "throwing object"},
            "Pressed a visible stone-related Buy control",
            "No stone-related Buy button found. Open the stone shop and check the selected item manually."
        )
    end
    return false
end

function Stones:Destroy()
    destroyed = true
end

return Stones
