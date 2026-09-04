--- Discord Rich Presence over Discord's local IPC (Method C: pure-Lua, no
--- bundled binary). Talks the raw RPC protocol (8-byte header + JSON frame)
--- over a Windows named pipe or a Unix domain socket via LuaJIT FFI.
---
--- Failure isolation is the only hard requirement: if Discord isn't running,
--- the handshake fails, or any FFI/JSON call throws, every public call
--- no-ops. `init`/`update` never throw and never block love.load/love.update.
local DiscordRPC = {}

local Config = require("Content.Data.DiscordRPC")
local bit = require("bit")
local JSON = require("Source.Helpers.Core.JSON")

DiscordRPC.connected = false

-- Opcodes (Discord RPC IPC).
local OP_HANDSHAKE = 0
local OP_FRAME = 1
local OP_CLOSE = 2
local OP_PING = 3
local OP_PONG = 4

-- Transport state (module-private; never exposed as an array field so
-- Reset.all() can't wipe it).
---@type any
local ffi = nil
---@type any
local lib = nil
local ffiOk = false
local isWindows = false
local open = false
local handle = nil -- Windows HANDLE (void*)
local sockfd = nil -- Unix fd (number)
local pid = 0
local readBuf = ""
local desiredActivity = nil
local startTimestamp = 0
local reconnectTimer = 0
local RECONNECT_INTERVAL = 10 -- seconds between reconnect attempts while disconnected

local MSG_DONTWAIT = 0x40 -- Linux; macOS uses 0x80

pcall(function()
	ffi = require("ffi")
	local jit = require("jit")
	isWindows = (jit.os == "Windows")
	MSG_DONTWAIT = (jit.os == "OSX") and 0x80 or 0x40
	if isWindows then
		ffi.cdef([[
			void* CreateFileA(const char* lpFileName, unsigned long dwDesiredAccess,
				unsigned long dwShareMode, void* lpSecurityAttributes,
				unsigned long dwCreationDisposition, unsigned long dwFlagsAndAttributes,
				void* hTemplateFile);
			int CloseHandle(void* hObject);
			int WriteFile(void* hFile, const void* lpBuffer, unsigned long nNumberOfBytesToWrite,
				unsigned long* lpNumberOfBytesWritten, void* lpOverlapped);
			int ReadFile(void* hFile, void* lpBuffer, unsigned long nNumberOfBytesToRead,
				unsigned long* lpNumberOfBytesRead, void* lpOverlapped);
			int PeekNamedPipe(void* hNamedPipe, void* lpBuffer, unsigned long nBufferSize,
				unsigned long* lpBytesRead, unsigned long* lpTotalBytesAvail,
				unsigned long* lpBytesLeftThisMessage);
			unsigned long GetCurrentProcessId();
		]])
		lib = ffi.load("kernel32")
	else
		ffi.cdef([[
			int socket(int domain, int type, int protocol);
			int connect(int sockfd, const void* addr, unsigned int addrlen);
			int send(int sockfd, const void* buf, size_t len, int flags);
			int recv(int sockfd, void* buf, size_t len, int flags);
			int close(int sockfd);
			int getpid();
		]])
		lib = ffi.C
	end
	ffiOk = true
end)

local function u32le(s, off)
	return bit.bor(
		s:byte(off),
		bit.lshift(s:byte(off + 1), 8),
		bit.lshift(s:byte(off + 2), 16),
		bit.lshift(s:byte(off + 3), 24)
	)
end

local function putU32LE(arr, off, v)
	arr[off] = bit.band(v, 0xFF)
	arr[off + 1] = bit.band(bit.rshift(v, 8), 0xFF)
	arr[off + 2] = bit.band(bit.rshift(v, 16), 0xFF)
	arr[off + 3] = bit.band(bit.rshift(v, 24), 0xFF)
end

local function connectWindows()
	local GENERIC_READ = 0x80000000
	local GENERIC_WRITE = 0x40000000
	local OPEN_EXISTING = 3
	local INVALID = ffi.cast("void*", -1)
	for i = 0, 9 do
		local name = "\\\\.\\pipe\\discord-ipc-" .. i
		local h = lib.CreateFileA(name, bit.bor(GENERIC_READ, GENERIC_WRITE), 0, nil, OPEN_EXISTING, 0, nil)
		if h ~= INVALID then
			return h
		end
	end
	return nil
end

local function connectUnix()
	local AF_UNIX = 1
	local SOCK_STREAM = 1
	local paths = {}
	local xdg = os.getenv("XDG_RUNTIME_DIR")
	for i = 0, 9 do
		if xdg and xdg ~= "" then
			paths[#paths + 1] = xdg .. "/discord-ipc-" .. i
		end
		paths[#paths + 1] = "/tmp/discord-ipc-" .. i
	end
	for _, p in ipairs(paths) do
		local fd = lib.socket(AF_UNIX, SOCK_STREAM, 0)
		if fd >= 0 then
		local sa = ffi.new("char[110]")
		-- Linux sockaddr_un: sun_family is a 2-byte LE value at offset 0. macOS/BSD
		-- prepend an 8-bit sun_len before sun_family, so this layout is Linux-only.
		ffi.cast("unsigned short*", sa)[0] = AF_UNIX
			for j = 0, #p - 1 do
				sa[2 + j] = p:byte(j + 1)
			end
			sa[2 + #p] = 0
			if lib.connect(fd, sa, 2 + #p + 1) == 0 then
				return fd
			end
			lib.close(fd)
		end
	end
	return nil
end

local function writeRaw(buf, len)
	if isWindows then
		local written = ffi.new("unsigned long[1]")
		return lib.WriteFile(handle, buf, len, written, nil) ~= 0
	else
		return lib.send(sockfd, buf, len, 0) == len
	end
end

local function readRaw()
	if isWindows then
		local avail = ffi.new("unsigned long[1]")
		if lib.PeekNamedPipe(handle, nil, 0, nil, avail, nil) == 0 or avail[0] == 0 then
			return nil
		end
		local buf = ffi.new("char[?]", avail[0])
		local read = ffi.new("unsigned long[1]")
		if lib.ReadFile(handle, buf, avail[0], read, nil) == 0 then
			return nil
		end
		return ffi.string(buf, read[0])
	else
		local buf = ffi.new("char[?]", 4096)
		local n = lib.recv(sockfd, buf, 4096, MSG_DONTWAIT)
		if n <= 0 then
			return nil
		end
		return ffi.string(buf, n)
	end
end

local function sendFrame(opcode, payloadJson)
	if not open then
		return false
	end
	local data = payloadJson or ""
	local len = #data
	local header = ffi.new("unsigned char[8]")
	putU32LE(header, 0, opcode)
	putU32LE(header, 4, len)
	if not writeRaw(header, 8) then
		return false
	end
	if len > 0 then
		local buf = ffi.new("char[?]", len)
		ffi.copy(buf, data, len)
		return writeRaw(buf, len)
	end
	return true
end

local function sendHandshake()
	return sendFrame(OP_HANDSHAKE, string.format('{"v":1,"client_id":"%s"}', Config.clientId))
end

local function sendActivity(activity)
	local payload = {
		cmd = "SET_ACTIVITY",
		args = { pid = pid, activity = activity },
		nonce = tostring(os.time()),
	}
	local ok, json = pcall(JSON.encode, payload)
	if not ok then
		return false
	end
	return sendFrame(OP_FRAME, json)
end

local function handleFrame(op, jsonStr)
	if op == OP_PING then
		sendFrame(OP_PONG, jsonStr)
	elseif op == OP_CLOSE then
		open = false
		DiscordRPC.connected = false
	elseif op == OP_FRAME then
		local ok, tbl = pcall(JSON.decode, jsonStr)
		if ok and tbl and tbl.evt == "READY" then
			DiscordRPC.connected = true
			if desiredActivity then
				sendActivity(desiredActivity)
			end
		end
	end
end

local function pump()
	local chunk = readRaw()
	while chunk do
		readBuf = readBuf .. chunk
		while #readBuf >= 8 do
			local op = u32le(readBuf, 1)
			local len = u32le(readBuf, 5)
			if #readBuf < 8 + len then
				break
			end
			local jsonStr = readBuf:sub(9, 8 + len)
			readBuf = readBuf:sub(9 + len)
			handleFrame(op, jsonStr)
		end
		chunk = readRaw()
	end
end

--- Connect + handshake. No-op unless Config.enabled and FFI is usable. Never
--- throws; any failure leaves the module disconnected and silent.
function DiscordRPC.init()
	if not Config.enabled or DiscordRPC.connected or open then
		return
	end
	if not ffiOk then
		return
	end
	local ok = pcall(function()
		pid = isWindows and lib.GetCurrentProcessId() or lib.getpid()
		if startTimestamp == 0 then
			startTimestamp = os.time()
		end
		if isWindows then
			handle = connectWindows()
			if handle then
				open = true
			end
		else
			sockfd = connectUnix()
			if sockfd then
				open = true
			end
		end
		if open then
			sendHandshake()
			pump()
		end
	end)
	if not ok then
		if isWindows and handle then
			lib.CloseHandle(handle)
		elseif sockfd then
			lib.close(sockfd)
		end
		open = false
		DiscordRPC.connected = false
		handle = nil
		sockfd = nil
	end
end

--- Pump inbound frames (respond to PING, detect READY/CLOSE). Also retries
--- `init()` on a cooldown while disconnected, so opening Discord mid-session
--- connects. Cheap; call once per frame from love.update with the frame dt.
function DiscordRPC.update(dt)
	if open then
		local ok = pcall(pump)
		if not ok then
			open = false
			DiscordRPC.connected = false
		end
		return
	end
	if not Config.enabled then
		return
	end
	reconnectTimer = reconnectTimer + (dt or 0)
	if reconnectTimer >= RECONNECT_INTERVAL then
		reconnectTimer = 0
		DiscordRPC.init()
	end
end

--- Update presence from the game's scene state. Stores the desired activity so
--- it is (re)sent once the connection is READY. No-op unless enabled.
function DiscordRPC.setScene(scene)
	if not Config.enabled then
		return
	end
	local stateStr = (Config.stateByScene and Config.stateByScene[scene]) or scene
	local activity = {
		details = Config.details,
		state = stateStr,
		assets = {
			large_image = Config.largeImageKey,
			large_text = Config.largeImageText,
		},
		timestamps = { start = startTimestamp },
	}
	desiredActivity = activity
	if open then
		pcall(sendActivity, activity)
	end
end

--- Close the IPC connection. Safe to call even when never connected.
function DiscordRPC.shutdown()
	if not open then
		return
	end
	pcall(function()
		sendFrame(OP_CLOSE, "")
		if isWindows and handle then
			lib.CloseHandle(handle)
		elseif sockfd then
			lib.close(sockfd)
		end
	end)
	open = false
	DiscordRPC.connected = false
	handle = nil
	sockfd = nil
end

return DiscordRPC