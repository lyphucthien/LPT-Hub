local Progress = {}
local API

function Progress:Init(api)
    API = api
end

function Progress:GetAll()
    if not API or type(API.GetStats) ~= "function" then return {} end
    local ok, result = pcall(API.GetStats)
    if ok and type(result) == "table" then return result end
    return {}
end

function Progress:Destroy() end

return Progress
