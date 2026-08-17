--- Shared, mutable game state. A single module-level table, created once and
--- mutated by fields (never reassigned), so extracted modules and Main share one
--- source of truth without a function-signature refactor. Required by every
--- module that needs game state; `require` returns the same table to all.
--- Reset on restart is handled by `initGame()` reassigning the relevant fields
--- (and `Reset.all()` clearing module-owned pools). Read fields at runtime, never
--- cache them in a module-local.
local GameState = {}

return GameState
