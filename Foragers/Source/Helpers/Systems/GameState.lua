--- Shared, mutable game state. A single module-level table, created once and
--- mutated by fields (never reassigned), so extracted modules and Main share one
--- source of truth without a function-signature refactor. Required by every
--- module that needs game state; `require` returns the same table to all.
--- Reset on restart is handled by `initGame()` reassigning the relevant fields
--- (and `Reset.all()` clearing module-owned pools). Read fields at runtime, never
--- cache them in a module-local.
local GameState = {}

--- Only valid while state=="game". Set/cleared by CardSelect.
GameState.showingCards = false

--- Queued level-ups waiting for a card pick. Incremented on LEVEL_UP,
--- decremented when a card is chosen; re-shows cards while > 0.
GameState.pendingLevelUps = 0

--- Card-select darken fade (owns u_darken only while state=="cardselect").
GameState.cardDarkenActive = false
GameState.cardDarkenTimer = 0
GameState.cardDarkenFrom = 0
GameState.cardDarkenTo = 0
GameState.cardDarkenDuration = 0
GameState.cardDarkenCurve = "Linear"

return GameState
