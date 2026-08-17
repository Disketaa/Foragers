# Single entry point: run all three code gates.
#   - luacheck (lua correctness)
#   - lua-ls-check (Lua Language Server diagnostics)
#   - StructureCheck (project architecture rules)
# Exit code reflects StructureCheck's error count so it can gate CI / pre-commit.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== luacheck ===" -ForegroundColor Cyan
& "$root\luacheck.exe" Source/ Content/ 2>&1 | Write-Host

Write-Host "`n=== lua language server ===" -ForegroundColor Cyan
powershell -File "$root\lua-ls-check.ps1" 2>&1 | Write-Host

Write-Host "`n=== structure check ===" -ForegroundColor Cyan
python "$root\LuaStructurizer\Structurizer.py"
exit $LASTEXITCODE
