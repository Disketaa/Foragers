# Single entry point: run all three code gates.
#   - luacheck (lua correctness)
#   - LuaAnalyzer check (Lua Language Server diagnostics)
#   - StructureCheck (project architecture rules)
# Exit code reflects StructureCheck's error count so it can gate CI / pre-commit.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameRoot = Split-Path $root
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Reformat a tool's "Total: W warnings / E errors in F files" summary into the
# project's "Done: W violation(s), E error(s) across F file(s)." line; pass
# every other line through unchanged.
function Format-Summary {
    param([string[]]$Lines)
    foreach ($line in $Lines) {
        if ($line -match '^Total:\s*(\d+)\s*warnings\s*/\s*(\d+)\s*errors\s*in\s*(\d+)\s*files?') {
            $w = [int]$Matches[1]
            $e = [int]$Matches[2]
            $f = [int]$Matches[3]
            Write-Host "Done: $w violation(s), $e error(s) across $f file(s)."
        } else {
            Write-Host $line
        }
    }
}

Write-Host "`n- Lua Check:" -ForegroundColor Cyan
$luaCheck = & "$root\luacheck.exe" -q "$gameRoot\Source" "$gameRoot\Content" 2>&1
Format-Summary $luaCheck

Write-Host "`n- Lua Analyzer:" -ForegroundColor Cyan
$luaAnalyzer = powershell -File "$root\LuaAnalyzer\check.ps1" 2>&1
Format-Summary $luaAnalyzer

Write-Host "`n- Lua Structurizer:" -ForegroundColor Cyan
$structurizer = python "$root\LuaStructurizer\Structurizer.py" 2>&1
Format-Summary $structurizer
exit $LASTEXITCODE
