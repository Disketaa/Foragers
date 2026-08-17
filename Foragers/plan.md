# Split Main.lua — Plan

## Goal
Break `Main.lua` (1463 lines, the LÖVE2D root chunk) into focused modules in the
correct `Source/` folders, and eliminate the 7 `ModuleSingleton` warnings by moving
reassigned module-level singletons into a single shared state table.

## Architecture decision
- **Shared state hub:** `Source/Helpers/Systems/GameState.lua` — one module-level
  table, created once, mutated by fields (never reassigned). Every module
  (including `Main`) `require`s it and reads/writes `GameState.field`. This
  removes the `local x = nil` reassignment pattern the linter flags, and gives
  extracted modules a single source of truth without rewriting every function
  signature (avoids the 60-upvalue cap by moving logic OUT of `love.update`).
- `love.load/update/draw/resize/keypressed/.../quit` stay in `Main.lua` as thin
  dispatchers that call into the extracted modules.
- Restart: `Reset.all()` clears module-owned pools; `GameState` fields are
  re-initialized by `initGame()` (and a `GameState.reset()` clears transient
  fields). No window recreation.

## Module layout (folders per AGENTS.md §VI)
- `Source/Helpers/Systems/GameState.lua` — shared mutable state + `reset()`.
- `Source/Helpers/Graphics/Camera.lua` — `updateCamera`, `screenToWorld`,
  `worldToScreen`, `computeZoomPivot`, `canvasBlitOrigin`, `cullVisible`.
- `Source/Helpers/Graphics/PostProcess.lua` — `updateReveal`, `updateStartDarken`,
  `easeZoom` (screen post-process transitions: Zoom + u_saturation/u_posterize/
  u_noise/u_circleRadius/u_darken). Name matches the project's existing
  "postprocess" shader terminology (the ScreenPost program).
- `Source/Helpers/Debug/Chat.lua` — `handleChatTab`, `resetChatCompletion`,
  `startChatRepeat`, chat-repeat state, `bindingMatches`, `commandsCtx`.
- `Source/UI/UILayout.lua` — `positionUI`.
- `Source/Helpers/Systems/Lifecycle.lua` — full game lifecycle: `initGame`,
  `resetGame`, `destroySprite`, `clearProps`, `spawnDrop`, `timeIt`, `updateHold`,
  `handleRestartPress/Release`, `triggerLoading`, `startLoadingHold`,
  `cancelLoadingHold`. Absorbs the old death-sequence + restart-input phases.

## Phases (each: implement → `Tools/check.ps1` → in-game checks → pause)
0. Write this plan.
1. [DONE] Create `GameState.lua`; migrate the 7 flagged singletons
   (`playerSprite`, `loadingSprite`, `loadingSheet`, `terrainBatch`,
   `completionBase`, `chatRepeatKey`, `chatRepeatAction`) to `GameState.*`.
2. [DONE] Extract `Camera.lua`; move camera state into `GameState`; wire
   `updateCamera`, `screenToWorld`, `worldToScreen`, `computeZoomPivot`,
   `canvasBlitOrigin`, `cullVisible`.
3. [DONE] Extract `PostProcess.lua` (`updateReveal`, `updateStartDarken`, `easeZoom`)
   and `Lifecycle.lua` (`resetGame`, `triggerLoading`, `startLoadingHold`,
   `cancelLoadingHold`, `handleRestartPress/Release`, `updateHold`). Merges the old
   death-sequence + restart-input phases into one coherent lifecycle module;
   `PostProcess` owns the graphics transitions. Move relevant state into
   `GameState`. Fixed `Easing` require path (`Tween.Easing`).
4. Extract `Chat.lua`; move chat/completion/repeat state into `GameState`; wire
   `handleChatTab`, `resetChatCompletion`, `startChatRepeat`, `bindingMatches`,
   `commandsCtx`.
5. Extract `UILayout.lua` (`positionUI`).
6. Extract `InputBindings.lua` (non-restart input bindings; restart press/release
   already live in `Lifecycle`).
7. Final trim of `Main.lua` to dispatchers; full `check.ps1`; final in-game plan.

## Risk controls
- Behavior must stay byte-for-byte identical (no logic changes, only relocation).
- `check.ps1` must stay at 0 errors after every phase.
- Each phase is independently revertable; in-game checks confirm no regression.
- No new dependencies; folders match existing conventions.
