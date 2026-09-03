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

--- Per-group chosen-card counts; CardSelect reads this to label each card's
--- level and increments it on pick. Reset on new game (see initGame).
GameState.cardGroupCounts = {}

--- Card-select darken fade (owns u_darken only while state=="cardselect").
GameState.selectionDarkenActive = false
GameState.selectionDarkenTimer = 0
GameState.selectionDarkenFrom = 0
GameState.selectionDarkenTo = 0
GameState.selectionDarkenDuration = 0
GameState.selectionDarkenDelay = 0
GameState.selectionDarkenCurve = "Linear"

return GameState
