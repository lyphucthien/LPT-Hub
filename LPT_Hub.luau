local Loader_Key = "https://raw.githubusercontent.com/lyphucthien/LPT-Hub/refs/heads/main/KeyUI.luau"

local function loadRaw(url)
	local success, result = pcall(function()
		local source = game:HttpGet(url)

		if type(source) ~= "string" or source == "" then
			error("HTTPGet không trả về source hợp lệ.")
		end

		if type(loadstring) ~= "function" then
			error("loadstring không tồn tại trong môi trường hiện tại.")
		end

		local func, compileError = loadstring(source)

		if type(func) ~= "function" then
			error("Không compile được KeyUI.luau:\n" .. tostring(compileError))
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
