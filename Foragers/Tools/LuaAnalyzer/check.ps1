# Compact LuaAnalyzer CLI check: one line per diagnostic, run from the game root.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$gameRoot = Split-Path (Split-Path $PSScriptRoot)
Set-Location $gameRoot

$exe = Join-Path $PSScriptRoot "bin\lua-language-server.exe"
$raw = & $exe --check . 2>&1 | Out-String

# Strip ANSI color codes, split into lines.
$clean = $raw -replace '\x1b\[[0-9;]*m', ''
$lines = $clean -split "`n"

# Keep only diagnostic header lines (file:line:col [Level] message (type)),
# rewriting the severity tag to ASCII-safe [WARN]/[ERROR].
$diag = $lines | Where-Object { $_ -match '^\S+?\.lua:\d+:\d+ \[' } | ForEach-Object {
    if ($_ -match '^(.+?\.lua:\d+:\d+) \[(Warning|Error)\] (.+)$') {
        $loc = $Matches[1]
        $tag = if ($Matches[2] -eq 'Warning') { '[WARN]' } else { '[ERROR]' }
        "$tag $loc - $($Matches[3])"
    } else {
        $_.Trim()
    }
}

$diag
$summary = $lines | Where-Object { $_ -match 'problems found' } | Select-Object -Last 1
if ($summary) { $summary.Trim() }

# Always exit 0 so F5 still launches the game alongside the report.
exit 0
