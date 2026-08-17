--- Chat input UX: tab-completion, key auto-repeat, and the repeat timer loop.
--- Reads/writes the chat-repeat fields in GameState; completion cycle state is
--- local (transient per chat session, not game state).
local GameState = require("Source.Helpers.Systems.GameState")
local Debug = require("Source.Helpers.Debug.Debug")
local Commands = require("Source.Helpers.Debug.Commands")

local completionCandidates = {}
local completionIndex = 0
local completionActive = false

local chatRepeatTimer = 0
local chatRepeatRepeating = false

local Chat = {}

function Chat.resetChatCompletion()
	GameState.completionBase = nil
	completionCandidates = {}
	completionIndex = 0
	completionActive = false
end

--- First press fills the first candidate; subsequent presses cycle through the
--- remaining ones. A fresh edit (different base/candidates) restarts from the
--- first candidate. No-op with no matches. `backwards` (shift+tab) cycles in reverse.
function Chat.handleChatTab(backwards)
	if not completionActive then
		local base, candidates = Commands.complete(Debug.chatText())
		if #candidates == 0 then
			return
		end
		GameState.completionBase = base
		completionCandidates = candidates
		completionActive = true
		completionIndex = backwards and #candidates or 1
	else
		local n = #completionCandidates
		if n == 0 then
			return
		end
		if backwards then
			completionIndex = completionIndex - 1
			if completionIndex < 1 then
				completionIndex = n
			end
		else
			completionIndex = completionIndex % n + 1
		end
	end
	Debug.setChatText(GameState.completionBase .. completionCandidates[completionIndex])
end

--- Shared by backspace, the up/down history arrows, and Tab so holding any of
--- them repeats.
function Chat.startChatRepeat(key, action)
	action()
	GameState.chatRepeatKey = key
	chatRepeatTimer = 0
	chatRepeatRepeating = false
	GameState.chatRepeatAction = action
end

--- LÖVE only repeats keypressed when setKeyRepeat is on, which would also repeat
--- the HUD/restart toggles, so the repeat is driven manually here. Mirrors the
--- Windows model — one action on press, then a fixed delay before repeats at a
--- steady rate.
function Chat.updateRepeat(dt)
	if GameState.chatRepeatKey and Debug.chatActive() then
		chatRepeatTimer = chatRepeatTimer + dt
		local delay = Debug.chatRepeatDelay()
		local interval = Debug.chatRepeatInterval()
		if not chatRepeatRepeating then
			if chatRepeatTimer >= delay then
				if GameState.chatRepeatAction then GameState.chatRepeatAction() end
				chatRepeatTimer = 0
				chatRepeatRepeating = true
			end
		else
			if chatRepeatTimer >= interval then
				if GameState.chatRepeatAction then GameState.chatRepeatAction() end
				chatRepeatTimer = 0
			end
		end
	else
		GameState.chatRepeatKey = nil
		chatRepeatTimer = 0
		chatRepeatRepeating = false
		GameState.chatRepeatAction = nil
	end
end

function Chat.cancelRepeat(key)
	if key == GameState.chatRepeatKey then
		GameState.chatRepeatKey = nil
		chatRepeatRepeating = false
		GameState.chatRepeatAction = nil
	end
end

return Chat
