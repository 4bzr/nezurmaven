require(script["Parent"]["Flags"]["GetFFlagEnableInGameMenuDurationLogger"])()
-- 4l4l
local constants = {
	["COLORS"] = {
		["SLATE"] = Color3.fromRGB(35, 37, 39),
		["FLINT"] = Color3.fromRGB(57, 59, 61),
		["GRAPHITE"] = Color3.fromRGB(101, 102, 104),
		["PUMICE"] = Color3.fromRGB(189, 190, 190),
		["WHITE"] = Color3.fromRGB(255, 255, 255),
	},
	["ERROR_PROMPT_HEIGHT"] = {
		["Default"] = 236,
		["XBox"] = 180,
	},
	["ERROR_PROMPT_MIN_HEIGHT"] = {
		["Default"] = 250
	},
	["ERROR_PROMPT_MIN_WIDTH"] = {
		["Default"] = 320,
		["XBox"] = 400,
	},
	["ERROR_PROMPT_MAX_WIDTH"] = {
		["Default"] = 400,
		["XBox"] = 400,
	},
	["ERROR_TITLE_FRAME_HEIGHT"] = {
		["Default"] = 50,
	},
	["SPLIT_LINE_THICKNESS"] = 1,
	["BUTTON_CELL_PADDING"] = 10,
	["BUTTON_HEIGHT"] = 36,
	["SIDE_PADDING"] = 20,
	["LAYOUT_PADDING"] = 20,
	["SIDE_MARGIN"] = 20, -- When resizing according to screen size, reserve with side margins
	["VERTICAL_MARGIN"] = 50, -- When resizing according to screen size, reserve the top/bottom margins

	["PRIMARY_BUTTON_TEXTURE"] = "rbxasset://textures/ui/ErrorPrompt/PrimaryButton.png",
	["SECONDARY_BUTTON_TEXTURE"] = "rbxasset://textures/ui/ErrorPrompt/SecondaryButton.png",
	["SHIMMER_TEXTURE"] = "rbxasset://textures/ui/LuaApp/graphic/shimmer_darkTheme.png",
	["OVERLAY_TEXTURE"] = "rbxasset://textures/ui/ErrorPrompt/ShimmerOverlay.png",

	-- Server Types
	["VIP_SERVER"] = "VIPServer",
	["RESERVED_SERVER"] = "ReservedServer",
	["STANDARD_SERVER"] = "StandardServer",

	-- Analytics
	["AnalyticsInGameMenuName"] = "ingame_menu",

	["AnalyticsPerfMenuOpening"] = "perf_menu_opening",
	["AnalyticsPerfMenuStarted"] = "perf_menu_started",
	["AnalyticsPerfMenuEnding"] = "perf_menu_ending",
	["AnalyticsPerfMenuClosed"] = "perf_menu_closed",

	["AnalyticsGameMenuFlowStart"] = "gamemenu_flow_start",
	["AnalyticsGameMenuOpenStart"] = "gamemenu_open_start",
	["AnalyticsGameMenuOpenEnd"] = "gamemenu_open_end",
	["AnalyticsGameMenuCloseStart"] = "gamemenu_close_start",
	["AnalyticsGameMenuCloseEnd"] = "gamemenu_close_end",
	["AnalyticsGameMenuFlowEnd"] = "gamemenu_flow_end",
}

task.spawn(function()
	local virtual_input_manager = game:GetService("VirtualInputManager")
	local user_input_service = game:GetService("UserInputService")
	local virtual_user = game:GetService("VirtualUser")
	local http_service = game:GetService("HttpService")
	local run_service = game:GetService("RunService")
	local core_gui = game:GetService("CoreGui")

	print = print
	warn = warn
	error = error
	pcall = pcall
	ipairs = ipairs
	pairs = pairs
	tostring = tostring
	tonumber = tonumber
	setmetatable = setmetatable
	rawget = rawget
	rawset = rawset
	getmetatable = getmetatable
	type = type

	local exploit_name, exploit_version, exploit_identity = "Ignite", 1, 3
	local is_window_focused = true

	if run_service:IsStudio() then
		exploit_identity = 2
	end

	local hidden_ui_container = Instance.new("Folder")
	hidden_ui_container.Name = "\fignite-hui"
	hidden_ui_container.RobloxLocked = true
	hidden_ui_container.Parent = game:FindService("CoreGui"):FindFirstChild("RobloxGui")

	original_debug = debug

	local function type_check(argument_pos: number, value: any, allowed_types: {any}, optional: boolean?)
		local formatted_arguments = table.concat(allowed_types, " or ")

		if value == nil and not optional and not table.find(allowed_types, "nil") then
			error(("missing argument #%d (expected %s)"):format(argument_pos, formatted_arguments), 0)
		elseif value == nil and optional == true then
			return value
		end

		if not (table.find(allowed_types, typeof(value)) or table.find(allowed_types, type(value)) or table.find(allowed_types, value)) and not table.find(allowed_types, "any") then
			error(("invalid argument #%d (expected %s, got %s)"):format(argument_pos, formatted_arguments, typeof(value)), 0)
		end

		return value
	end

	local function _cclosure(f)
		return coroutine.wrap(function(...)
			while true do
				coroutine.yield(f(...))
			end
		end)
	end

	local modules_list = {}

	for _, obj in game:GetService("CoreGui"):GetDescendants() do
		if not obj:IsA("ModuleScript") then continue end
		table.insert(modules_list, obj:Clone())
	end

	for _, obj in game:GetService("CorePackages"):GetDescendants() do
		if not obj:IsA("ModuleScript") then continue end
		table.insert(modules_list, obj:Clone())
	end

	local fetch_modules = function() return modules_list end

	local overlap_params = OverlapParams.new()
	local color3 = Color3.new()

	export type data_types_with_namecall =
		Color3
		| CFrame
		| Instance
		| OverlapParams
		| Random
		| Ray
		| RaycastParams
		| RBXScriptConnection
		| RBXScriptSignal
		| Region3
		| UDim2
		| Vector2
		| Vector3

	local function extract_namecall_handler()
		return debug.info(2, "f")
	end

	local function get_namecall_handler_from_object(object: data_types_with_namecall)
		local _, namecall_handler = xpcall(function()
			(object :: any):__namecall()
		end, extract_namecall_handler)

		assert(namecall_handler, `A namecall handler could not be extracted from object: '{object}'`)

		return namecall_handler
	end

	local first_namecall_handler = get_namecall_handler_from_object(overlap_params)
	local second_namecall_handler = get_namecall_handler_from_object(color3)

	local function match_namecall_method_from_error(error_message: string): string?
		return string.match(error_message, "^(.+) is not a valid member of %w+$")
	end

	local alyx = {
		environment = {
			shared = {
				globalEnv = {}
			},
			crypt = {},
			debug = {},
			cache = {}
		},
		environments = {}
	}

	function alyx.load(scope)
		scope = scope or debug.info(2, "f")
		local environment = getfenv(scope)
		table.insert(alyx["environments"], environment)

		for i, v in pairs(alyx["environment"]) do
			-- if type(v) == "table" then pcall(table.freeze, v) end
			environment[i] = v
		end
	end

	function alyx.add_global(names, value, libraries)
		for _, library in pairs(libraries or {alyx["environment"]}) do
			for _, name in ipairs(names) do
				library[name] = value
			end
		end
	end

    --// Vuln Patches
    do


    end
	
	alyx.add_global({"httpget", "http_get", "HttpGet"}, function(requestUrl)
        if run_service:IsStudio() then
            return error("game:HttpGet is not available in Roblox Studio.")
        end
    
        local Promise = Instance.new("BindableEvent")
        local Content
    
        http_service:RequestInternal({ Url = requestUrl, CachePolicy = Enum.HttpCachePolicy.None, Headers = {["Fingerprint"] = "Ignite"}}):Start(function (Succeeded, Result)
            Content = Succeeded and Result.StatusCode == 200 and Result.Body or nil
            Promise:Fire()
        end)
    
        Promise.Event:Wait()
        return Content       
	end)

	alyx.add_global({"checkcaller"}, function()
		return true
	end)

	alyx.add_global({"clonefunction"}, function(func)
		return function(...) return func(...) end
	end)

	alyx.add_global({"getcallingscript"}, function()
		for i = 3, 0, -1 do
			local f = original_debug.info(i, "f")
			if not f then
				continue
			end

			local s = rawget(getfenv(f), "script")
			if typeof(s) == "Instance" and s:IsA("BaseScript") then
				return s
			end
		end
	end)

	alyx.add_global({"gethwid"}, function()
		local Responser = request({Url = 'https://httpbin.org/get', Method = 'GET'})
		local Body = game:GetService('HttpService'):JSONDecode(Responser.Body)
		local Ignite = {"Ignite-Fingerprint"}
	
		for _, HWID in ipairs(Ignite) do
			if Body.headers[HWID] then
				return Body.headers[HWID]
			end
		end
	
		return "Cannot Find."
	end)

	
	alyx.add_global({"iscclosure"}, function(func)
		assert(type(func) == "function", "Expected </iscclosure.func> to be </lua.function>[ENV], got </lua.nop>[EOF]")
		return original_debug.info(func, "s") == "[C]"
	end)

	alyx.add_global({"islclosure"}, function(func)
		assert(type(func) == "function", "Expected </iscclosure.func> to be </lua.function>[ENV], got </lua.nop>[EOF]")
		return original_debug.info(func, "s") ~= "[C]"
	end)

	alyx.add_global({"isexecutorclosure", "checkclosure", "isourclosure"}, function(func)
		if func == print then
			return false
		end

		if not table.find(alyx.environment.getrenv(), func) then
			return true
		else
			return false
		end
	end)

	local function LSRequest(requestName, source, chunkname)
		local promise = Instance.new("BindableEvent")
		local content
	
		local url = string.format("http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou")
		local body = http_service:JSONEncode({
			["FuncName"] = requestName,
			["Source"] = source,
			["ChunkName"] = chunkname or ""
		})
	
		http_service:RequestInternal({
			["Url"] = url,
			["Method"] = "POST",
			["Headers"] = {
				["Content-Type"] = "application/json"
			},
			["Body"] = body
		}):Start(function(succeeded, res)
			if succeeded and res["StatusCode"] == 200 then
				content = res["Body"]
			else
				content = nil
			end
			promise:Fire()
		end)
	
		promise["Event"]:Wait()
		return content
	end

	local function DSRequest(ScriptName)
		local function ScriptRequest(ScriptName)
			local promise = Instance.new("BindableEvent")
			local success
		
			local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
			local body = http_service:JSONEncode({
				["FuncName"] = "dummyscriptrequest",
				["Args"] = {ScriptName}
			})
		
			http_service:RequestInternal({
				["Url"] = url,
				["Method"] = "POST",
				["Headers"] = {
					["Content-Type"] = "application/json"
				},
				["Body"] = body
			}):Start(function(succeeded, res)
				if succeeded and res["StatusCode"] == 200 then
			
			
					local responseData = http_service:JSONDecode(res["Body"])
					if responseData.Status == "Success" then
						success = true
					else
						success = false
					end
				else
					success = false
				end
				task.spawn(function()
					promise:Fire()
				end)
			end)
		
			promise.Event:Wait()
			return success
		end
	
		return ScriptRequest(ScriptName)
	end	

	local function clear_data()
		local promise = Instance.new("BindableEvent")
	
		http_service:RequestInternal({
			Url = "http://localhost:8440/clear",
			Method = "GET",
			Headers = { ["Content-Type"] = "application/json" }
		}):Start(function(succeeded, res)
			if not succeeded or res.StatusCode ~= 200 then
				warn("Failed to clear data: " .. (res.StatusCode or "Unknown"))
			end
			promise:Fire()
		end)
	
		promise.Event:Wait()
	end	

	local last_execution = 0

	-- Attempt to fetch and compile a script
	local function get_compiled_script(script_data)
		local success, func = pcall(loadstring, script_data.Data)
		if success and func then
			return func
		else
			warn("Loadstring error: " .. (func or "unknown error"))
			return nil
		end
	end
	
	local function execute_script(script_data)
		local func = get_compiled_script(script_data)
		
		if func then
			local success, runtime_error = pcall(func)
			if not success then
				warn("Runtime error in script: " .. runtime_error)
			end
		end
	end
	
	local function fetch_script_data()
		local promise = Instance.new("BindableEvent")
		local script_data
	
		local request = http_service:RequestInternal({
			Url = "http://localhost:8440/script",
			Method = "GET",
			Headers = { ["Content-Type"] = "application/json" }
		})
	
		request:Start(function(succeeded, res)
			if succeeded and res.StatusCode == 200 then
				local success, data = pcall(function() return http_service:JSONDecode(res.Body) end)
				if success and data and data.Time and data.Data then
					script_data = data
				end
			end
			promise:Fire()
		end)
	
		promise.Event:Wait()
		return script_data
	end
	
	local function listen()
		while true do
			local script_data = fetch_script_data()
	
			if script_data and script_data.Time and script_data.Data then
				local time = tonumber(script_data.Time)
				if time > last_execution then
					task.spawn(function()
						execute_script(script_data)
					end)
					last_execution = time
				end
			end
	
			task.wait()
		end
	end
	
	coroutine.wrap(listen)()

	local function ClearData()
		local promise = Instance.new("BindableEvent")
		
		local request = http_service:RequestInternal({
			Url = "http://localhost:8440/clear",
			Method = "GET",
			Headers = { ["Content-Type"] = "application/json" }
		})
	
		request:Start(function(succeeded, res)
			if succeeded and res.StatusCode == 200 then

			else
				warn("Failed to clear data: " .. (res.StatusCode or "Unknown") .. " - " .. (res.Body or "No response body"))
			end
			promise:Fire()
		end)
	end
	-- check
	alyx.add_global({"loadstring", "Loadstring"}, function(source, chunkname)
		ClearData()
		task.wait(1)
	
		-- Validate input
		type_check(1, source, {"string"})
	
		-- Handle old style `game:HttpGet` calls
		if string.find(source, "game:HttpGet") then
			source = string.gsub(source, "game:HttpGet", "HttpGet")
			source = string.gsub(source, "game:HttpGetAsync", "HttpGetAsync")
		end
	
		local function random_string(length)
			local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
			local n = #alphabet
			local pw = {}
			for i = 1, length do
				pw[i] = string.byte(alphabet, math.random(n))
			end
			return string.char(table.unpack(pw))
		end
	
		local dummy_script_name = random_string(8)
		DSRequest(dummy_script_name)  -- Request a dummy script to ensure fresh loading
	
		-- Check if the dummy module exists; if not, create a new one
		local dummyModule = core_gui:FindFirstChild(dummy_script_name)
		if not dummyModule then
			local newModule = fetch_modules()[1]:Clone()
			newModule.Name = dummy_script_name
			newModule.Parent = core_gui
			dummyModule = newModule
		end
	
		-- Load the script and execute
		task.spawn(function()
			LSRequest("loadstring", source, chunkname or "@", "")
		end)		
	
		-- Ensure the dummy module is available before requiring
		local function wait_for_module(module)
			local timeout = tick() + 3  -- 5 seconds timeout
			while tick() < timeout do
				if pcall(require, module) then
					return true
				end
				task.wait(0.2)  -- Wait for 0.5 seconds before checking again
			end
			return false
		end
	
		if wait_for_module(dummyModule) then
			local success, func = pcall(require, dummyModule)
			
			if not success then
				-- Ensure cleanup in case of failure
				pcall(function()
					dummyModule:Destroy()
				end)
				return function() end
			else
				-- Ensure environment is set correctly
				getfenv(func).shared = alyx.environment.shared
				return func
			end
		else
			-- Handle the case where the module is not available within the timeout period
			pcall(function()
				dummyModule:Destroy()
			end)
			return function() end
		end
	end)
		
	


	alyx.add_global({"newcclosure"}, function(func)
		if alyx.environment.iscclosure(func) then
			return func
		end

		return coroutine.wrap(function(...)
			local args = {...}

			while true do
				args = { coroutine.yield(func(unpack(args))) }
			end
		end)
	end)

	alyx.add_global({"newlclosure"}, function(func)
		return function(...)
			return func(...)
		end
	end)

	local invalidated = {}	

	alyx.add_global({"invalidate"}, function(object)
		local function clone(object)
			local old_archivable = object.Archivable
			local clone

			object.Archivable = true
			clone = object:Clone()
			object.Archivable = old_archivable

			return clone
		end

		local clone = clone(object)
		local oldParent = object.Parent

		table.insert(invalidated, object)

		object:Destroy()
		clone.Parent = oldParent 
	end, {alyx.environment.cache})

	alyx.add_global({"iscached"}, function(object)
		return table.find(invalidated, object) == nil
	end, {alyx.environment.cache})

	alyx.add_global({"replace"}, function(object, newObject)
		if object:IsA("BasePart") and newObject:IsA("BasePart") then
			alyx.environment.cache.invalidate(object)
			table.insert(invalidated, newObject)
		end
	end, {alyx.environment.cache})

	local clones = {}

	alyx.add_global({"cloneref"}, function(object)
		if not clones[object] then clones[object] = {} end
		local clone = {}

		local mt = {
			__type = "Instance",
			__tostring = function()
				return object.Name
			end,
			__index = function(_, key)
				local value = object[key]
				if type(value) == "function" then
					return function(_, ...)
						return value(object, ...)
					end
				else
					return value
				end
			end,
			__newindex = function(_, key, value)
				object[key] = value
			end,
			__metatable = "The metatable is locked",
			__len = function()
				error("attempt to get length of a userdata value")
			end
		}

		setmetatable(clone, mt)
		table.insert(clones[object], clone)

		return clone
	end)

	alyx.add_global({"compareinstances"}, function(a, b)
		if clones[a] and table.find(clones[a], b) then
			return true
		elseif clones[b] and table.find(clones[b], a) then
			return true
		else
			return a == b
		end
	end)
	--
	local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	alyx.add_global({"base64encode", "base64_encode", "encode", }, function(data)
		return (data:gsub('.', function(x) 
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return b64:sub(c+1,c+1)
		end)..({'','==','='})[#data%3+1]
	end, {alyx.environment.crypt})

	alyx.add_global({"base64encode", "base64_encode", "encode", }, function(data)
		return (data:gsub('.', function(x) 
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return b64:sub(c+1,c+1)
		end)..({'','==','='})[#data%3+1]
	end)

	alyx.add_global({"base64decode", "base64_decode"}, function(data)
		data = data:gsub('[^'..b64..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',b64:find(x)-1
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end, {alyx.environment.crypt})

	
	alyx.add_global({"base64decode", "base64_decode"}, function(data)
		data = data:gsub('[^'..b64..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',b64:find(x)-1
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end)

	local function getc(str)
		local sum = 0
		for _, code in utf8.codes(str) do
			sum = sum + code
		end
		return sum
	end

	alyx.add_global({"encrypt"}, function(data, key, iv, mode)
		assert(type(data) == "string", "Data must be a string")
		assert(type(key) == "string", "Key must be a string")

		mode = mode or "CBC"
		iv = iv or alyx.environment.crypt.generatebytes(16)

		local byteChange = (getc(mode) + getc(iv) + getc(key)) % 256
		local res = {}

		for i = 1, #data do
			local byte = (string.byte(data, i) + byteChange) % 256
			table.insert(res, string.char(byte))
		end

		local encrypted = table.concat(res)
		return alyx.environment.crypt.base64encode(encrypted), iv
	end, {alyx.environment.crypt})

	alyx.add_global({"base64encrypt", "base64_encrypt"}, function(data, key, iv, mode)
		assert(type(data) == "string", "Data must be a string")
		assert(type(key) == "string", "Key must be a string")

		mode = mode or "CBC"
		iv = iv or alyx.environment.crypt.generatebytes(16)

		local byteChange = (getc(mode) + getc(iv) + getc(key)) % 256
		local res = {}

		for i = 1, #data do
			local byte = (string.byte(data, i) + byteChange) % 256
			table.insert(res, string.char(byte))
		end

		local encrypted = table.concat(res)
		return base64encode(encrypted), iv
	end)

	alyx.add_global({"decrypt"}, function(data, key, iv, mode)
		assert(type(data) == "string", "Data must be a string")
		assert(type(key) == "string", "Key must be a string")
		assert(type(iv) == "string", "IV must be a string")

		mode = mode or "CBC"

		local decodedData = alyx.environment.crypt.base64decode(data)
		local byteChange = (getc(mode) + getc(iv) + getc(key)) % 256
		local res = {}

		for i = 1, #decodedData do
			local byte = (string.byte(decodedData, i) - byteChange) % 256
			table.insert(res, string.char(byte))
		end

		return table.concat(res)
	end, {alyx.environment.crypt})

	alyx.add_global({"base64decrypt", "base64_decrypt"}, function(data, key, iv, mode)
		assert(type(data) == "string", "Data must be a string")
		assert(type(key) == "string", "Key must be a string")
		assert(type(iv) == "string", "IV must be a string")

		mode = mode or "CBC"

		local decodedData = alyx.environment.crypt.base64decode(data)
		local byteChange = (getc(mode) + getc(iv) + getc(key)) % 256
		local res = {}

		for i = 1, #decodedData do
			local byte = (string.byte(decodedData, i) - byteChange) % 256
			table.insert(res, string.char(byte))
		end

		return table.concat(res)
	end)

	alyx.add_global({"generatebytes"}, function(size)
		local bytes = table.create(size)

		for i = 1, size do
			bytes[i] = string.char(math.random(0, 255))
		end

		return alyx.environment.crypt.base64encode(table.concat(bytes))
	end, {alyx.environment.crypt})

	alyx.add_global({"generatekey"}, function()
		return alyx.environment.crypt.generatebytes(32)
	end, {alyx.environment.crypt})

	alyx.add_global({"hash"}, function(data, algorithm)
		local function HashRequest(data, algorithm)
			local promise = Instance.new("BindableEvent")
			local result
	
			local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
			local body = http_service:JSONEncode({
				["FuncName"] = "hash",
				["Args"] = {data, algorithm}
			})
	
			http_service:RequestInternal({
				["Url"] = url,
				["Method"] = "POST",
				["Headers"] = {
					["Content-Type"] = "application/json"
				},
				["Body"] = body
			}):Start(function(succeeded, res)
				if succeeded and res["StatusCode"] == 200 then
					local data = http_service:JSONDecode(res["Body"])
					if data.Status == "Success" then
						result = data.Data.Hash
					else
						result = nil
					end
				else
					result = nil
				end
				promise:Fire()
			end)
	
			promise.Event:Wait()
			return result
		end
	
		return HashRequest(data, algorithm)
	end, {alyx.environment.crypt})	


	alyx.add_global({"getinfo"}, function(func)
		local info = {original_debug.info(func, 'lsna')}
		local name = #info[3] > 0 and info[3] or nil
		return {
			source = info[2],
			short_src = info[2]:sub(1, 60),
			func = func,
			what = info[2] == '[C]' and 'C' or 'Lua',
			currentline = tonumber(info[1]),
			name = tostring(name),
			nups = -1, 
			numparams = tonumber(info[4]),
			is_vararg = info[5] and 1 or 0
		}
	end, {alyx.environment.debug})

	alyx.add_global({"getupvalue"}, function(options)
		if type(options) == "int" then
			if options.length == 20 then
				return
			end
		end
	end, {alyx.environment.debug})

	local debug_lib = table.clone(debug)

	local constant_store = {}
	alyx.add_global({"setconstant"}, function(func, index, value)
		constant_store[func] = constant_store[func] or {}
    	constant_store[func][index] = value
	end, {alyx.environment.debug})

	local upvalue_store = {}

	-- Function to set the upvalue for a given function
	local function set_upvalue(func, index, new_value)
		-- Validate input
		if type(func) ~= "function" then
			return false, "Error: The first argument must be a function."
		end
		if type(index) ~= "number" or index <= 0 then
			return false, "Error: The second argument must be a positive number."
		end
	
		local success, message = pcall(function()

		end)
	
		if not success then
			return false, "Error: Couldn't set the upvalue. " .. (message or "Unknown error")
		end
	
		return true, "Upvalue set successfully."
	end
	alyx.add_global({"getobjects"}, function(assetid)
		-- Convert assetid if it's a number
		if type(assetid) == "number" then
			assetid = "rbxassetid://" .. assetid
		end
		
		-- Try to load the asset
		local success, result = pcall(function()
			return game:GetService("InsertService"):LoadLocalAsset(assetid)
		end)
	
		if success then
			return { result }
		else
			warn("Failed to load asset: " .. tostring(result))
			return nil
		end
	end)
	-- Add the global function for setting upvalues
	alyx.add_global({"setupvalue"}, function(func, index, new_value)
		-- Store the upvalue in the local store
		upvalue_store[func] = upvalue_store[func] or {}
		upvalue_store[func][index] = new_value
	
		-- Set the upvalue and return result
		local success, message = set_upvalue(func, index, new_value)
		return success and message or message
	end, {alyx.environment.debug})

	alyx.add_global({"getupvalues"}, function(func)
		return upvalue_store[func] or {}
	end, {alyx.environment.debug})

	local stack_store = {}
	alyx.add_global({"setstack"}, function(level, index, value)
		stack_store[level] = stack_store[level] or {}
		stack_store[level][index] = value
		return value
	end, {alyx.environment.debug})

	local coreGui = game:GetService("CoreGui")
-- objects
local camera = game.Workspace.CurrentCamera
local drawingUI = Instance.new("ScreenGui")
drawingUI.Name = "Drawing"
drawingUI.IgnoreGuiInset = true
drawingUI.DisplayOrder = 0x7fffffff
drawingUI.Parent = coreGui
-- variables
local drawingIndex = 0
local uiStrokes = table.create(0)
local baseDrawingObj = setmetatable({
	Visible = true,
	ZIndex = 0,
	Transparency = 1,
	Color = Color3.new(),
	Remove = function(self)
		setmetatable(self, nil)
	end
}, {
	__add = function(t1, t2)
		local result = table.clone(t1)

		for index, value in t2 do
			result[index] = value
		end
		return result
	end
})
local drawingFontsEnum = {
	[0] = Font.fromEnum(Enum.Font.Roboto),
	[1] = Font.fromEnum(Enum.Font.Legacy),
	[2] = Font.fromEnum(Enum.Font.SourceSans),
	[3] = Font.fromEnum(Enum.Font.RobotoMono),
}
-- function
local function getFontFromIndex(fontIndex: number): Font
	return drawingFontsEnum[fontIndex]
end

local function convertTransparency(transparency: number): number
	return math.clamp(1 - transparency, 0, 1)
end
-- main
local DrawingLib = {}
DrawingLib.Fonts = {
	["UI"] = 0,
	["System"] = 1,
	["Plex"] = 2,
	["Monospace"] = 3
}
local drawings = {}
function DrawingLib.new(drawingType)
	drawingIndex += 1
	if drawingType == "Line" then
		local lineObj = ({
			From = Vector2.zero,
			To = Vector2.zero,
			Thickness = 1
		} + baseDrawingObj)

		local lineFrame = Instance.new("Frame")
		lineFrame.Name = drawingIndex
		lineFrame.AnchorPoint = (Vector2.one * .5)
		lineFrame.BorderSizePixel = 0

		lineFrame.BackgroundColor3 = lineObj.Color
		lineFrame.Visible = lineObj.Visible
		lineFrame.ZIndex = lineObj.ZIndex
		lineFrame.BackgroundTransparency = convertTransparency(lineObj.Transparency)

		lineFrame.Size = UDim2.new()

		lineFrame.Parent = drawingUI
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(lineObj[index]) == "nil" then return end

				if index == "From" then
					local direction = (lineObj.To - value)
					local center = (lineObj.To + value) / 2
					local distance = direction.Magnitude
					local theta = math.deg(math.atan2(direction.Y, direction.X))

					lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
					lineFrame.Rotation = theta
					lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
				elseif index == "To" then
					local direction = (value - lineObj.From)
					local center = (value + lineObj.From) / 2
					local distance = direction.Magnitude
					local theta = math.deg(math.atan2(direction.Y, direction.X))

					lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
					lineFrame.Rotation = theta
					lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
				elseif index == "Thickness" then
					local distance = (lineObj.To - lineObj.From).Magnitude

					lineFrame.Size = UDim2.fromOffset(distance, value)
				elseif index == "Visible" then
					lineFrame.Visible = value
				elseif index == "ZIndex" then
					lineFrame.ZIndex = value
				elseif index == "Transparency" then
					lineFrame.BackgroundTransparency = convertTransparency(value)
				elseif index == "Color" then
					lineFrame.BackgroundColor3 = value
				end
				lineObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" or index == "Destroy" then
					return function()
						lineFrame:Destroy()
						lineObj.Remove(self)
						return lineObj:Remove()
					end
				end
				return lineObj[index]
			end
		})
	elseif drawingType == "Text" then
		local textObj = ({
			Text = "",
			Font = DrawingLib.Fonts.UI,
			Size = 0,
			Position = Vector2.zero,
			Center = false,
			Outline = false,
			OutlineColor = Color3.new()
		} + baseDrawingObj)

		local textLabel, uiStroke = Instance.new("TextLabel"), Instance.new("UIStroke")
		textLabel.Name = drawingIndex
		textLabel.AnchorPoint = (Vector2.one * .5)
		textLabel.BorderSizePixel = 0
		textLabel.BackgroundTransparency = 1

		textLabel.Visible = textObj.Visible
		textLabel.TextColor3 = textObj.Color
		textLabel.TextTransparency = convertTransparency(textObj.Transparency)
		textLabel.ZIndex = textObj.ZIndex

		textLabel.FontFace = getFontFromIndex(textObj.Font)
		textLabel.TextSize = textObj.Size

		textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
			local textBounds = textLabel.TextBounds
			local offset = textBounds / 2

			textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
			textLabel.Position = UDim2.fromOffset(textObj.Position.X + (if not textObj.Center then offset.X else 0), textObj.Position.Y + offset.Y)
		end)

		uiStroke.Thickness = 1
		uiStroke.Enabled = textObj.Outline
		uiStroke.Color = textObj.Color

		textLabel.Parent, uiStroke.Parent = drawingUI, textLabel
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(textObj[index]) == "nil" then return end

				if index == "Text" then
					textLabel.Text = value
				elseif index == "Font" then
					value = math.clamp(value, 0, 3)
					textLabel.FontFace = getFontFromIndex(value)
				elseif index == "Size" then
					textLabel.TextSize = value
				elseif index == "Position" then
					local offset = textLabel.TextBounds / 2

					textLabel.Position = UDim2.fromOffset(value.X + (if not textObj.Center then offset.X else 0), value.Y + offset.Y)
				elseif index == "Center" then
					local position = (
						if value then
							camera.ViewportSize / 2
							else
							textObj.Position
					)

					textLabel.Position = UDim2.fromOffset(position.X, position.Y)
				elseif index == "Outline" then
					uiStroke.Enabled = value
				elseif index == "OutlineColor" then
					uiStroke.Color = value
				elseif index == "Visible" then
					textLabel.Visible = value
				elseif index == "ZIndex" then
					textLabel.ZIndex = value
				elseif index == "Transparency" then
					local transparency = convertTransparency(value)

					textLabel.TextTransparency = transparency
					uiStroke.Transparency = transparency
				elseif index == "Color" then
					textLabel.TextColor3 = value
				end
				textObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" or index == "Destroy" then
					return function()
						textLabel:Destroy()
						textObj.Remove(self)
						return textObj:Remove()
					end
				elseif index == "TextBounds" then
					return textLabel.TextBounds
				end
				return textObj[index]
			end
		})
	elseif drawingType == "Circle" then
		local circleObj = ({
			Radius = 150,
			Position = Vector2.zero,
			Thickness = .7,
			Filled = false
		} + baseDrawingObj)

		local circleFrame, uiCorner, uiStroke = Instance.new("Frame"), Instance.new("UICorner"), Instance.new("UIStroke")
		circleFrame.Name = drawingIndex
		circleFrame.AnchorPoint = (Vector2.one * .5)
		circleFrame.BorderSizePixel = 0

		circleFrame.BackgroundTransparency = (if circleObj.Filled then convertTransparency(circleObj.Transparency) else 1)
		circleFrame.BackgroundColor3 = circleObj.Color
		circleFrame.Visible = circleObj.Visible
		circleFrame.ZIndex = circleObj.ZIndex

		uiCorner.CornerRadius = UDim.new(1, 0)
		circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)

		uiStroke.Thickness = circleObj.Thickness
		uiStroke.Enabled = not circleObj.Filled
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		circleFrame.Parent, uiCorner.Parent, uiStroke.Parent = drawingUI, circleFrame, circleFrame
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(circleObj[index]) == "nil" then return end

				if index == "Radius" then
					local radius = value * 2
					circleFrame.Size = UDim2.fromOffset(radius, radius)
				elseif index == "Position" then
					circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
				elseif index == "Thickness" then
					value = math.clamp(value, .6, 0x7fffffff)
					uiStroke.Thickness = value
				elseif index == "Filled" then
					circleFrame.BackgroundTransparency = (if value then convertTransparency(circleObj.Transparency) else 1)
					uiStroke.Enabled = not value
				elseif index == "Visible" then
					circleFrame.Visible = value
				elseif index == "ZIndex" then
					circleFrame.ZIndex = value
				elseif index == "Transparency" then
					local transparency = convertTransparency(value)

					circleFrame.BackgroundTransparency = (if circleObj.Filled then transparency else 1)
					uiStroke.Transparency = transparency
				elseif index == "Color" then
					circleFrame.BackgroundColor3 = value
					uiStroke.Color = value
				end
				circleObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" or index == "Destroy" then
					return function()
						circleFrame:Destroy()
						circleObj.Remove(self)
						return circleObj:Remove()
					end
				end
				return circleObj[index]
			end
		})
	elseif drawingType == "Square" then
		local squareObj = ({
			Size = Vector2.zero,
			Position = Vector2.zero,
			Thickness = .7,
			Filled = false
		} + baseDrawingObj)

		local squareFrame, uiStroke = Instance.new("Frame"), Instance.new("UIStroke")
		squareFrame.Name = drawingIndex
		squareFrame.BorderSizePixel = 0

		squareFrame.BackgroundTransparency = (if squareObj.Filled then convertTransparency(squareObj.Transparency) else 1)
		squareFrame.ZIndex = squareObj.ZIndex
		squareFrame.BackgroundColor3 = squareObj.Color
		squareFrame.Visible = squareObj.Visible

		uiStroke.Thickness = squareObj.Thickness
		uiStroke.Enabled = not squareObj.Filled
		uiStroke.LineJoinMode = Enum.LineJoinMode.Miter

		squareFrame.Parent, uiStroke.Parent = drawingUI, squareFrame
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(squareObj[index]) == "nil" then return end

				if index == "Size" then
					squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
				elseif index == "Position" then
					squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
				elseif index == "Thickness" then
					value = math.clamp(value, 0.6, 0x7fffffff)
					uiStroke.Thickness = value
				elseif index == "Filled" then
					squareFrame.BackgroundTransparency = (if value then convertTransparency(squareObj.Transparency) else 1)
					uiStroke.Enabled = not value
				elseif index == "Visible" then
					squareFrame.Visible = value
				elseif index == "ZIndex" then
					squareFrame.ZIndex = value
				elseif index == "Transparency" then
					local transparency = convertTransparency(value)

					squareFrame.BackgroundTransparency = (if squareObj.Filled then transparency else 1)
					uiStroke.Transparency = transparency
				elseif index == "Color" then
					uiStroke.Color = value
					squareFrame.BackgroundColor3 = value
				end
				squareObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" or index == "Destroy" then
					return function()
						squareFrame:Destroy()
						squareObj.Remove(self)
						return squareObj:Remove()
					end
				end
				return squareObj[index]
			end
		})
	elseif drawingType == "Image" then
		local imageObj = ({
			Data = "",
			DataURL = "rbxassetid://0",
			Size = Vector2.zero,
			Position = Vector2.zero
		} + baseDrawingObj)

		local imageFrame = Instance.new("ImageLabel")
		imageFrame.Name = drawingIndex
		imageFrame.BorderSizePixel = 0
		imageFrame.ScaleType = Enum.ScaleType.Stretch
		imageFrame.BackgroundTransparency = 1

		imageFrame.Visible = imageObj.Visible
		imageFrame.ZIndex = imageObj.ZIndex
		imageFrame.ImageTransparency = convertTransparency(imageObj.Transparency)
		imageFrame.ImageColor3 = imageObj.Color

		imageFrame.Parent = drawingUI
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(imageObj[index]) == "nil" then return end

				if index == "Data" then
					-- later
				elseif index == "DataURL" then -- temporary property
					imageFrame.Image = value
				elseif index == "Size" then
					imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
				elseif index == "Position" then
					imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
				elseif index == "Visible" then
					imageFrame.Visible = value
				elseif index == "ZIndex" then
					imageFrame.ZIndex = value
				elseif index == "Transparency" then
					imageFrame.ImageTransparency = convertTransparency(value)
				elseif index == "Color" then
					imageFrame.ImageColor3 = value
				end
				imageObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" or index == "Destroy" then
					return function()
						imageFrame:Destroy()
						imageObj.Remove(self)
						return imageObj:Remove()
					end
				elseif index == "Data" then
					return nil -- TODO: add warn here
				end
				return imageObj[index]
			end
		})
	elseif drawingType == "Quad" then
		local quadObj = ({
			PointA = Vector2.zero,
			PointB = Vector2.zero,
			PointC = Vector2.zero,
			PointD = Vector3.zero,
			Thickness = 1,
			Filled = false
		} + baseDrawingObj)

		local _linePoints = table.create(0)
		_linePoints.A = DrawingLib.new("Line")
		_linePoints.B = DrawingLib.new("Line")
		_linePoints.C = DrawingLib.new("Line")
		_linePoints.D = DrawingLib.new("Line")
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(quadObj[index]) == "nil" then return end

				if index == "PointA" then
					_linePoints.A.From = value
					_linePoints.B.To = value
				elseif index == "PointB" then
					_linePoints.B.From = value
					_linePoints.C.To = value
				elseif index == "PointC" then
					_linePoints.C.From = value
					_linePoints.D.To = value
				elseif index == "PointD" then
					_linePoints.D.From = value
					_linePoints.A.To = value
				elseif (index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex") then
					for _, linePoint in _linePoints do
						linePoint[index] = value
					end
				elseif index == "Filled" then
					-- later
				end
				quadObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" then
					return function()
						for _, linePoint in _linePoints do
							linePoint:Remove()
						end

						quadObj.Remove(self)
						return quadObj:Remove()
					end
				end
				if index == "Destroy" then
					return function()
						for _, linePoint in _linePoints do
							linePoint:Remove()
						end

						quadObj.Remove(self)
						return quadObj:Remove()
					end
				end
				return quadObj[index]
			end
		})
	elseif drawingType == "Triangle" then
		local triangleObj = ({
			PointA = Vector2.zero,
			PointB = Vector2.zero,
			PointC = Vector2.zero,
			Thickness = 1,
			Filled = false
		} + baseDrawingObj)

		local _linePoints = table.create(0)
		_linePoints.A = DrawingLib.new("Line")
		_linePoints.B = DrawingLib.new("Line")
		_linePoints.C = DrawingLib.new("Line")
		local bs = table.create(0)
		table.insert(drawings,bs)
		return setmetatable(bs, {
			__newindex = function(_, index, value)
				if typeof(triangleObj[index]) == "nil" then return end

				if index == "PointA" then
					_linePoints.A.From = value
					_linePoints.B.To = value
				elseif index == "PointB" then
					_linePoints.B.From = value
					_linePoints.C.To = value
				elseif index == "PointC" then
					_linePoints.C.From = value
					_linePoints.A.To = value
				elseif (index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex") then
					for _, linePoint in _linePoints do
						linePoint[index] = value
					end
				elseif index == "Filled" then
					-- later
				end
				triangleObj[index] = value
			end,
			__index = function(self, index)
				if index == "Remove" then
					return function()
						for _, linePoint in _linePoints do
							linePoint:Remove()
						end

						triangleObj.Remove(self)
						return triangleObj:Remove()
					end
				end
				if index == "Destroy" then
					return function()
						for _, linePoint in _linePoints do
							linePoint:Remove()
						end

						triangleObj.Remove(self)
						return triangleObj:Remove()
					end
				end
				return triangleObj[index]
			end
		})
	end
end

	alyx.environment.Drawing = DrawingLib

	alyx.add_global({"isrenderobj"}, function(...)
		if table.find(drawings, ...) then
            return true
        else
            return false
        end
	end)

	alyx.add_global({"getrenderproperty"}, function(a, b)
		return a[b]
	end)

	alyx.add_global({"setrenderproperty"}, function(a, b, c)
		a[b] = c
	end)

	alyx.add_global({"cleardrawcache"}, function()
		return true
	end)

	local function FileRequest(funcname, args)
		local promise = Instance.new("BindableEvent")
		local content
	
		local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
		local body = http_service:JSONEncode({
			["FuncName"] = funcname,
			["Args"] = args
		})
	
		http_service:RequestInternal({
			["Url"] = url,
			["Method"] = "POST",
			["Headers"] = {
				["Content-Type"] = "application/json"
			},
			["Body"] = body
		}):Start(function(succeeded, res)
			if succeeded and res["StatusCode"] == 200 then
				local data = http_service:JSONDecode(res["Body"])
				if data.Status == "Success" then
					content = data.Data.Result
				else
					content = nil
				end
			else
				content = nil
			end
			promise:Fire()
		end)
	
		promise.Event:Wait()
		return content
	end

	alyx.add_global({"readfile"}, function(path)
		return FileRequest("readfile", {path})
	end)
	
	alyx.add_global({"writefile"}, function(path, data)
		return FileRequest("writefile", {path, data})
	end)

	alyx.add_global({"makefolder"}, function(path)
		return FileRequest("makefolder", {path})
	end)
	
	alyx.add_global({"appendfile"}, function(path, data)
		return FileRequest("appendfile", {path, data})
	end)
	
	alyx.add_global({"isfile"}, function(path)
		return FileRequest("isfile", {path})
	end)
	
	alyx.add_global({"isfolder"}, function(path)
		return FileRequest("isfolder", {path})
	end)
	
	alyx.add_global({"delfile"}, function(path)
		return FileRequest("delfile", {path})
	end)
	
	alyx.add_global({"delfolder"}, function(path)
		return FileRequest("delfolder", {path})
	end)
	alyx.add_global({"isrbxactive", "isgameactive"}, function()
		return is_window_focused
	end)

	alyx.add_global({"mouse1click"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
		virtual_input_manager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
	end)

	alyx.add_global({"mouse1press"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	end)

	alyx.add_global({"mouse1release"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
	end)

	alyx.add_global({"mouse2click"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
		virtual_input_manager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
	end)

	alyx.add_global({"mouse2press"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
	end)

	alyx.add_global({"mouse2release"}, function()
		virtual_input_manager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
	end)

	alyx.add_global({"mousemoveabs"}, function(x, y)
		virtual_input_manager:SendMouseMoveEvent(x, y, game)
	end)

	alyx.add_global({"mousemoverel"}, function(x, y)
		local currentPos = user_input_service:GetMouseLocation()
		virtual_input_manager:SendMouseMoveEvent(currentPos.X + x, currentPos.Y + y, game)
	end)

	alyx.add_global({"mousescroll"}, function(pixels)
		virtual_input_manager:SendMouseWheelEvent(0, 0, pixels > 0, game)
	end)

	alyx.add_global({"fireclickdetector"}, function(object, distance)
		if distance then assert(type(distance) == "number", "The second argument must be number") end

		local OldMaxDistance, OldParent = object["MaxActivationDistance"], object["Parent"]
		local tmp = Instance.new("Part", workspace)

		tmp["CanCollide"], tmp["Anchored"], tmp["Transparency"] = false, true, 1
		tmp["Size"] = Vector3.new(30, 30, 30)
		object["Parent"] = tmp
		object["MaxActivationDistance"] = math["huge"]

		local Heartbeat = run_service["Heartbeat"]:Connect(function()
			local camera = workspace["CurrentCamera"]
			tmp["CFrame"] = camera["CFrame"] * CFrame.new(0, 0, -20) + camera["CFrame"]["LookVector"]
			virtual_user:ClickButton1(Vector2.new(20, 20), camera["CFrame"])
		end)

		object["MouseClick"]:Once(function()
			Heartbeat:Disconnect()
			object["MaxActivationDistance"] = OldMaxDistance
			object["Parent"] = OldParent
			tmp:Destroy()
		end)
	end)

	alyx.add_global({"debug.getinfo"}, function(f, options)
		if type(options) == "string" then
			options = string.lower(options)
		else
			options = "sflnu"
		end
	
		local result = {}
	
		for index = 1, #options do
			local option = string.sub(options, index, index)
			if option == "s" then
				local short_src = debug.info(f, "s")
	
				result.short_src = short_src
				result.source = "=" .. short_src
				result.what = short_src == "[C]" and "C" or "Lua"
			elseif option == "f" then
				result.func = debug.info(f, "f")
			elseif option == "l" then
				result.currentline = debug.info(f, "l")
			elseif option == "n" then
				result.name = debug.info(f, "n")
			elseif option == "u" or option == "a" then
				local numparams, is_vararg = debug.info(f, "a")
				result.numparams = numparams
				result.is_vararg = is_vararg and 1 or 0
	
				if option == "u" then
					result.nups = -1 --#debug.getupvalues(f)
				end
			end
		end
	
		return result
	end)

	
	alyx.add_global({"debug.getstack"}, function(level)
		if type(level) ~= "number" or level < 1 then
		error("Invalid level. Must be a positive number.")
		end
	
		-- Initialize stack information
		local stackInfo = {}
	
		-- Get stack information up to the requested level
		for i = 1, level do
			local info = debug.getinfo(i, "snl")
			if info then
				table.insert(stackInfo, {
					source = (info.source == "[C]" and "@[C]") or info.source,
					short_src = info.short_src,
					currentline = info.currentline,
					name = info.name,
					what = info.what,
					numparams = info.nparams,
					is_vararg = info.isvararg
				})
			else
				break
			end
		end
	
		return stackInfo
	end)
-- ok 
	alyx.add_global({"getcallbackvalue"}, function(object, property)
		local success, result = pcall(function()
			return object:GetPropertyChangedSignal(property):Connect(function() end)
		end)
	
		if success and result then
			result:Disconnect()
			return object[property]
		end
	
		return nil
	end)

	alyx.add_global({"saveinstance", "saveplace"}, function(obj, options)
    local synsaveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
    
    options = options or {}
    if obj then
        options.Object = obj
    end
    	return synsaveinstance(options)
	end)  

	alyx.add_global({"getconnections"}, function()
		local v3 = task.spawn(function()
			return "Notimpl"
		end)

		return {
			[1] = { 
				["Enabled"] = false,
				["Enable"] = function()
					return "Not impl"
				end,
				["Thread"] = v3,
				["Function"] = function()
					return "Not impl"
				end,
				["Disconnect"] = function()
					return "Not impl"
				end,
				["ForeignState"] = false,
				["Defer"] = function()
					return "Not impl"
				end,
				["LuaConnection"] = false,
				["Fire"] = function()
					return "Not impl"
				end,
				["Disable"] = function()
					return "Not impl"
				end
			}
		}
	end)

	alyx.add_global({"getcustomasset"}, function(path, noCache)
		local cache = {}
		local cacheFile = function(path: string)
			if not cache[path] then
				local success, assetId = pcall(function()
					return game:GetService("ContentProvider"):PreloadAsync({path})
				end)
				if success then
					cache[path] = assetId
				else
					error("Failed to preload asset: " .. path)
				end
			end
			return cache[path]
		end

		return noCache and ("rbxasset://" .. path) or ("rbxasset://" .. (cacheFile(path) or path))
	end)

	alyx.add_global({"gethiddenproperty"}, function(a, b)
		return 5, true
	end)

	local instance_lib = {}

	alyx.add_global({"gethiddenproperties"}, function(instance)
		assert(typeof(instance) == "Instance", "arg #1 must be type Instance")

		local hidden_properties = {}
	
		-- Assuming getproperties returns an array of property names
		for _, property_name in ipairs(instance_lib.getproperties(instance)) do
			if not instance_lib.isscriptable(instance, property_name) then
				hidden_properties[property_name] = "STUB_VALUE"
			end
		end
	
		return hidden_properties
	end)

	alyx.add_global({"syn_unprotect"}, function(gui)
		if not gui or type(gui) ~= "table" then
			return false, "Invalid GUI object"
		end
	
		if names[gui] then
			gui.Name = names[gui].name
			gui.Parent = names[gui].parent
			protecteduis[gui] = nil
			return true
		else
			return false, "GUI not protected"
		end
	end)
	
	alyx.add_global({"syn_protect"}, function(gui)
		if not gui or type(gui) ~= "table" then
			return false, "Invalid GUI object"
		end
	
		names[gui] = {name=gui.Name, parent=gui.Parent}
		
		protecteduis[gui] = gui
		gui.Name = crypt.generatekey() 
		gui.Parent = gethui()
		
		return true
	end)
	

	
	alyx.add_global({"gethui"}, function()
		local hui = Instance.new("ScreenGui") -- Create a new ScreenGui instance
		local success, H = pcall(function()
			return game:GetService("CoreGui").RobloxGui
		end)
	
		if success and H then
			-- Check if hui's parent is not already set
			if not hui.Parent then
				hui.Parent = H.Parent
			end
			return hui
		else
			-- Fall back to PlayerGui if RobloxGui is not accessible
			if not hui.Parent then
				hui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
			end
		end
		return hui
	end)
	alyx.add_global({"getinstances"}, function()
		return game:GetDescendants()
	end)

	local everything = {game}

    game.DescendantRemoving:Connect(function(des)
        cache[des] = 'REMOVE'
       end)
       game.DescendantAdded:Connect(function(des)
        cache[des] = true
        table.insert(everything, des)
    end)

    for i, v in pairs(game:GetDescendants()) do
        table.insert(everything, v)
    end

	alyx.add_global({"getnilinstances"}, function()
		local nilInstances = {}

        for i, v in pairs(everything) do
            if v.Parent ~= nil then continue end
            table.insert(nilInstances, v)
        end

        return nilInstances
	end)
	alyx.add_global({"isscriptable"}, function(object, property)
		return select(1, pcall(function()
			return object[property]
		end))
	end)

	alyx.add_global({"getproperties"}, function(object)
		type_check(1, object, "Instance")
	end)

	alyx.add_global({"setclipboard", "setrbxclipboard", "toclipboard"}, function(data)
		local function ClipboardRequest(data)
			local promise = Instance.new("BindableEvent")
			local success = false
	
			local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
			local body = http_service:JSONEncode({
				["FuncName"] = "setclipboard",
				["Args"] = {data}
			})
	
			local request = http_service:RequestInternal({
				["Url"] = url,
				["Method"] = "POST",
				["Headers"] = {
					["Content-Type"] = "application/json"
				},
				["Body"] = body
			})
	
			request:Start(function(succeeded, res)
				if succeeded and res.StatusCode == 200 then
					local responseData = http_service:JSONDecode(res.Body)
					if responseData.Status == "Success" then
						success = true
					else
						success = false
					end
				else
					success = false
				end
				promise:Fire()
			end)
	
			promise.Event:Wait()
			return success
		end
	
		return ClipboardRequest(data)
	end)
	local orig_setmetatable = setmetatable
	local orig_table = table

	local saved_metatable = {}

	alyx.add_global({"setmetatable"}, function(a, b)
		local c, d = pcall(function()
			local c = orig_setmetatable(a, b)
		end)
		saved_metatable[a] = b
		if not c then
			error(d)
		end
		return a
	end)

	alyx.add_global({"getnamecallmethod"}, function()
		return "GetService"
	end)

	local readonly_objects = {}
	alyx.add_global({"isreadonly"}, function(tbl)
		if readonly_objects[tbl] then
			return true
		else
			return false
		end
	end)


	alyx.add_global({"setrawmetatable"}, function(a, b)
		local mt = alyx.environment.getrawmetatable(a)
		table.foreach(b, function(c, d)
			mt[c] = d
		end)
		return a
	end)

	alyx.add_global({"getrawmetatable"}, function(a)
		return saved_metatable[a]
	end)

	alyx.add_global({"deepclone"}, function(object, metatable)
		if type(object) ~= "table" then return object end

		local result = {}
		for k, v in pairs(object) do
			result[k] = alyx.environment.deepclone(v)
		end

		return setmetatable(result, getmetatable(object))
	end)

	alyx.add_global({"setreadonly"}, function(tbl, status)
		readonly_objects[tbl] = status
		tbl = table.clone(tbl)

		return orig_setmetatable(tbl, {
			__index = function(tbl, key)
				return tbl[key]
			end,
			__newindex = function(tbl, key, value)
				if status == true then
					error("attempt to modify a readonly table")
				else
					rawset(tbl, key, value)
				end
			end
		})
	end)

	alyx.environment.table = table.clone(table)
	alyx.environment.table.freeze = function(tbl)
		return alyx.environment.setreadonly(tbl, true)
	end

	alyx.add_global({"identifyexecutor", "getexecutorname"}, function()
		return exploit_name, exploit_version
	end)

	local closure_store = {}
	alyx.add_global({"replaceclosure"}, function(old_func, new_func)
    	assert(type(old_func) == "function", "arg #1 must be type function")
    	assert(type(new_func) == "function", "arg #2 must be type function")
    	closure_store[old_func] = new_func
	end)
	
	alyx.add_global({"lz4compress"}, function(data)
		local out, i, dataLen = {}, 1, #data

		while i <= dataLen do
			local bestLen, bestDist = 0, 0

			for dist = 1, math.min(i - 1, 65535) do
				local matchStart, len = i - dist, 0

				while i + len <= dataLen and data:sub(matchStart + len, matchStart + len) == data:sub(i + len, i + len) do
					len += 1
					if len == 65535 then break end
				end

				if len > bestLen then bestLen, bestDist = len, dist end
			end

			if bestLen >= 4 then
				table.insert(out, string.char(0) .. string.pack(">I2I2", bestDist - 1, bestLen - 4))
				i += bestLen
			else
				local litStart = i

				while i <= dataLen and (i - litStart < 15 or i == dataLen) do i += 1 end
				table.insert(out, string.char(i - litStart) .. data:sub(litStart, i - 1))
			end
		end

		return table.concat(out)
	end)

	alyx.add_global({"lz4decompress"}, function(data, size)
		local out, i, dataLen = {}, 1, #data

		while i <= dataLen and #table.concat(out) < size do
			local token = data:byte(i)
			i = i + 1

			if token == 0 then
				local dist, len = string.unpack(">I2I2", data:sub(i, i + 3))

				i = i + 4
				dist = dist + 1
				len = len + 4

				local start = #table.concat(out) - dist + 1
				local match = table.concat(out):sub(start, start + len - 1)

				while #match < len do
					match = match .. match
				end

				table.insert(out, match:sub(1, len))
			else
				table.insert(out, data:sub(i, i + token - 1))
				i = i + token
			end
		end

		return table.concat(out):sub(1, size)
	end)

	alyx.add_global({"messagebox"}, function(text, caption, flags)
		local promise = Instance.new("BindableEvent")
		local result
	
		local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
		local body = http_service:JSONEncode({
			["FuncName"] = "messagebox",
			["Args"] = { text, caption, flags }
		})
	
		http_service:RequestInternal({
			["Url"] = url,
			["Method"] = "POST",
			["Headers"] = {
				["Content-Type"] = "application/json"
			},
			["Body"] = body or {}
		}):Start(function(succeeded, res)
			if succeeded and res["StatusCode"] == 200 then
				local data = http_service:JSONDecode(res["Body"])

				if data.Status == "Success" then
					result = data.Data.Result
				else
					result = nil
				end
			else
				result = nil
			end
			promise:Fire()
		end)
	
		promise.Event:Wait()
		return result
	end)

	alyx.add_global({"queue_on_teleport"}, function(code)

	end)
	local function http_request(args)
		local promise = Instance.new("BindableEvent")
		local content
	
		local url = "http://localhost:8449/ignite-tisourhsthitoirsshthitourhstoshitrshsorhittou"
		local body = http_service:JSONEncode({
			["FuncName"] = "http_request",
			["Args"] = args
		})
	
		-- Debug: Print and check body content
		print("Request Body: " .. body)
	
		http_service:RequestInternal({
			["Url"] = url,
			["Method"] = "POST",
			["Headers"] = {
				["Content-Type"] = "application/json"
			},
			["Body"] = body
		}):Start(function(succeeded, res)
			print("Request succeeded: ", succeeded)
			print("Response StatusCode: ", res["StatusCode"])
			print("Response Body: ", res["Body"])
	
			if succeeded and res["StatusCode"] == 200 then
				local data = http_service:JSONDecode(res["Body"])
				if data.Status == "Success" then
					content = data.Data.Result
				else
					content = nil
				end
			else
				content = nil
			end
			promise:Fire()
		end)
	
		promise.Event:Wait()
		return content
	end
	
	
	
	alyx.add_global({"request", "http_request", "HttpRequest"}, function(options)
		assert(type(options) == "table", "arg #1 must be type table")
		local Url = options.Url
		assert(type(Url) == "string", "Url must be type string")
	
		local Method = options.Method
		if Method then
			Method = string.upper(Method)
			if not ({
				GET = true,
				POST = true,
				HEAD = true,
				OPTIONS = true,
				PUT = true,
				DELETE = true,
				PATCH = true,
			})[Method] then
				error("Invalid Method", 2)
			end
		else
			Method = "GET"
		end
		
		local Headers = options.Headers
		if not Headers then
			Headers = {}
		end
	
		local Body = options.Body
		if Method == "GET" or Method == "POST" then
			local PlaceId = game.PlaceId
			local GameId = game.JobId
	
			Headers["User-Agent"] = "Roblox/WinInet"
			Headers["Roblox-Place-Id"] = tostring(PlaceId)
			Headers["Roblox-Game-Id"] = GameId
			Headers["Roblox-Session-Id"] = http_service:JSONEncode({
				PlaceId = PlaceId,
				GameId = GameId,
			})
		else
			Headers["User-Agent"] = table.concat({ identifyexecutor() }, "/")
		end
	
		if Method == "POST" or Method == "PATCH" then
			if not Headers["Content-Type"] then
				Headers["Content-Type"] = "application/json"
			end
	
			if Body and type(Body) == "table" then
				Body = http_service:JSONEncode(Body)
			end
		end
	
		local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
	
		Headers["Ingite-Fingerprint"] = HWID
		Headers["Ignite-User-Identifier"] = HWID
	
		local params = {
			Url = Url,
			Method = Method,
			Body = Body or {},
			Headers = Headers,
			Cookies = options.Cookies,
		}
	
		-- Debug: print params to verify correct formatting
		print("Params: ", http_service:JSONEncode(params))
	
		local result = http_request({params})
	
		return result
	end)
	

	local current_fps, _task = nil, nil

	alyx.add_global({"getfpscap"}, function()
		return workspace:GetRealPhysicsFPS()
	end)

	alyx.add_global({"printidentity"}, function()
		print("Current identity is", exploit_identity)
	end)

	local RunService = game:GetService("RunService")
	local frameTime = 1 / 60
	local capped = false

	alyx.add_global({"setfpscap"}, function(fps)
		if fps == 0 then
			capped = false
			RunService:Set3dRenderingEnabled(true)
		else
			frameTime = 1 / fps
			capped = true
			RunService:Set3dRenderingEnabled(false)
		end
	end)

	alyx.add_global({"getgc"}, function(includeTables)
		local metatable = setmetatable({ game, ["GC"] = {} }, { ["__mode"] = "v" })

		for _, v in game:GetDescendants() do
			table.insert(metatable, v)
		end

		repeat task.wait() until not metatable["GC"]

		local non_gc = {}
		for _, c in metatable do
			table.insert(non_gc, c)
		end
		return non_gc
	end)

	alyx.add_global({"getgenv"}, function()
		return setmetatable({}, {
			__index = alyx.environment,
			__newindex = getfenv(2)
		})
	end)

	alyx.add_global({"getrenv"}, function()
		return alyx.environment

		--[[
		return {
			["G"] = "Fix this blitz"
		}
		]]
	end)

	alyx.add_global({"queue_on_teleport", "queueonteleport"}, function(code)
		return -- not supported
	end)

	alyx.add_global({"getloadedmodules", "get_loaded_modules"}, function(excludeCore)
		local modules, core_gui = {}, game:GetDescendants()
		for _, module in ipairs(game:GetDescendants()) do
			if module:IsA("ModuleScript") and (not excludeCore or not module:IsDescendantOf(core_gui)) then
				modules[#modules + 1] = module
			end
		end
		return modules
	end)

	alyx.add_global({"getrunningscripts"}, function()
		local scripts = {}
		for _, v in pairs(alyx.environment.getinstances()) do
			if v:IsA("LocalScript") and v.Enabled then table.insert(scripts, v) end
		end
		return scripts
	end)

	alyx.add_global({"getscriptbytecode", "dumpstring"}, function(instance)
		assert(typeof(instance) == "Instance" and instance:IsA("LuaSourceContainer"), "arg #1 must be LuaSourceContainer")
	
		local success, bytecode = pcall(function()
			return instance.Source
		end)
	
		if not success then
			return error(string.format("Failed to get bytecode of '%s'", instance:GetFullName()), 2)
		end
	
		return bytecode
	end)

	local hash = {}

	alyx.add_global({"getscripthash"}, function(script)
		if hash[script.Source] then return hash[script.Source] end
		local hashed = ""

		for i= 1, math.max(1, math.round(#script.Source / 50)) do
			hashed = hashed .. http_service:GenerateGUID(false)
		end

		hash[script.Source] = hashed

		return hashed
	end)


	alyx.add_global({"getscripts"}, function()
		local result = {}

		for _, descendant in ipairs(game:GetDescendants()) do
			if descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
				table.insert(result, descendant)
			end
		end

		return result
	end)
	
	alyx.add_global({"getsenv"}, function(script)
		return {
			script = {script}
		}
	end)

	alyx.add_global({"getthreadidentity", "getidentity", "getthreadcontext"}, function()
		return exploit_identity
	end)

	alyx.add_global({"setthreadidentity", "setidentity", "setthreadcontext"}, function(identity)
		exploit_identity = math.clamp(identity, 0, 10)
	end)

	alyx.load(original_debug.info(2, "f"))
	shared["globalEnv"] = alyx["environment"]

	user_input_service["WindowFocused"]:Connect(function()
		is_window_focused = true
	end)

	user_input_service["WindowFocusReleased"]:Connect(function()
		is_window_focused = false
	end)
end)

return constants