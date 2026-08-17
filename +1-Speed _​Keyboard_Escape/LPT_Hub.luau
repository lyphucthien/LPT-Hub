local Loader_Key = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/KeyUI.luau"

local function loadRaw(url)
	local success, result = pcall(function()
		local source = game:HttpGet(url)
		local func = loadstring(source)

		if type(func) ~= "function" then
			error("Raw file không trả về code hợp lệ.")
		end

		return func
	end)

	if not success then
		warn("[LPT Loader] Load error:", result)
		return nil
	end

	return result
end

local keyUI = loadRaw(Loader_Key)

if keyUI then
	local success, err = pcall(keyUI)

	if not success then
		warn("[LPT Loader] KeyUI error:", err)
	end
end
