# Single entry point: run all three code gates.
#   - luacheck (lua correctness)
#   - LuaAnalyzer check (Lua Language Server diagnostics)
#   - StructureCheck (project architecture rules)
# Exit code reflects StructureCheck's error count so it can gate CI / pre-commit.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameRoot = Split-Path $root

# ANSI 24-bit colors: 38;2;R;G;B (use [char]27 for PS 5.1 compatibility)
$Esc = [char]27
$ErrorColor = "$Esc[38;2;210;113;102m"
$WarnColor = "$Esc[38;2;204;167;0m"
$SectionColor = "$Esc[38;2;70;134;210m"
$DoneColor = "$Esc[38;2;129;184;139m"
$Reset = "$Esc[0m"

# Reformat a tool's "Total: W warnings / E errors in F files" summary into the
# project's "Done: W violation(s), E error(s) across F file(s)." line; pass
# every other line through unchanged.
# Also reformat individual diagnostic lines to colored relative-path format.
function Format-Summary {
    param([string[]]$Lines, [string]$GameRoot)

    foreach ($line in $lines) {
        # Summary line
        if ($line -match '^Total:\s*(\d+)\s*warnings\s*/\s*(\d+)\s*errors\s*in\s*(\d+)\s*files?') {
            $w = [int]$Matches[1]
            $e = [int]$Matches[2]
            $f = [int]$Matches[3]
            Write-Host "${DoneColor}> Done: $w violation(s), $e error(s) across $f file(s).${Reset}"
            continue
        }

        # Checking header line
        if ($line -match '^Checking\s+(.+)\s+(\d+)\s+(warning|error)') {
            continue  # skip, we show only diagnostics
        }

        # Blank line (from file headers)

        if ($line.Trim() -eq "") {
            continue
        }

        # Diagnostic line: "path:line:col - message" or "path:line:col: message"
        if ($line -match '^(.+):(\d+):(\d+)\s*[-:]\s*(.+)$') {
            $fullPath = $Matches[1].Trim()
            $ln = $Matches[2]
            $col = $Matches[3]
            $msg = $Matches[4].Trim()

            # Normalize to relative path (case-insensitive)
            $relPath = $fullPath
            $normalizedRoot = $GameRoot.TrimEnd('\')
            $normalizedFull = $fullPath
            if ($normalizedFull.StartsWith($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
                $relPath = $normalizedFull.Substring($normalizedRoot.Length).TrimStart('\', '/')
            }

            # Determine color based on message content
            $isError = $msg -match '\berror\b|\bunreachable\b|\bprint\s*\('
            $color = if ($isError) { $ErrorColor } else { $WarnColor }
            Write-Host "$color$relPath`:$ln`:$col - $msg$Reset"
            continue
        }

        Write-Host $line
    }
}

function Get-ErrorCount {
    param([string[]]$Lines)
    $count = -1
    foreach ($line in $Lines) {
        if ($line -match '^Total:\s*\d+\s*warnings\s*/\s*(\d+)\s*errors') {
            $count = [int]$Matches[1]
        }
    }
    return $count
}

function Invoke-Gate {
    param([string]$Name, [scriptblock]$Cmd, [string]$GameRoot)
    Write-Host "${SectionColor}`n$Name`:${Reset}"
    $out = & $Cmd 2>&1
    Format-Summary $out $GameRoot
    $err = Get-ErrorCount $out
    if ($err -lt 0) {
        Write-Host "Warning: could not parse $Name output" -ForegroundColor Yellow
        $err = 1
    }
    return $err
}

$LuaCheckErrors    = Invoke-Gate "Lua Check"       { & "$root\luacheck.exe" -q "$gameRoot\Main.lua" "$gameRoot\Source" "$gameRoot\Content" } $gameRoot
$LuaAnalyzerErrors = Invoke-Gate "Lua Analyzer"    { powershell -File "$root\LuaAnalyzer\check.ps1" } $gameRoot
$StructurizerErrors= Invoke-Gate "Lua Structurizer" { python "$root\LuaStructurizer\Structurizer.py" } $gameRoot

$TotalErrors = $LuaCheckErrors + $LuaAnalyzerErrors + $StructurizerErrors
Write-Host "${SectionColor}`nAggregated: $TotalErrors error(s) across all gates.${Reset}"
exit $TotalErrors
