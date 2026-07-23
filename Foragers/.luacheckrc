-- luacheck config for LÖVE2D project
-- max std includes all Lua globals (require, table, math, etc.)
std = "max"
-- Add LÖVE globals not in standard Lua
globals = {
  "love", "Source", "Content"
}
-- Ignore: unused params in component interface callbacks (update/dt, draw/x/y, self/event)
ignore = { "212/self", "212/event", "212/...", "212/dt", "212/x", "212/y" }
-- Ignore external debugger library
exclude_files = { "lldebugger.lua" }