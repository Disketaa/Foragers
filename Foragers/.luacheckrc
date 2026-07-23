-- luacheck config for LÖVE2D project
-- max std includes all Lua globals (require, table, math, etc.)
std = "max"
-- Add LÖVE globals not in standard Lua
globals = {
  "love", "Source", "Content"
}
-- Ignore: unused dt in update functions (component interface requirement)
-- Ignore: unused self/event in callbacks
ignore = { "212/self", "212/event", "212/...", "212/dt" }
-- Ignore external debugger library
exclude_files = { "lldebugger.lua" }