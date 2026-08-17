# Compact LuaAnalyzer CLI check: one line per diagnostic, run from the game root.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$gameRoot = Split-Path (Split-Path $PSScriptRoot)
Set-Location $gameRoot

$exe = Join-Path $PSScriptRoot "bin\lua-language-server.exe"
$cfg = Join-Path $gameRoot ".luarc.json"
# Scan only game source/content, not Tools/LuaAnalyzer/meta (huge, ~1200 files -> hangs).
$out1 = & $exe --check Source --configpath $cfg 2>&1 | Out-String
$out2 = & $exe --check Content --configpath $cfg 2>&1 | Out-String
$raw = $out1 + "`n" + $out2

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
$warnings = ($diag | Where-Object { $_ -match '^\[WARN\]' }).Count
$errors = ($diag | Where-Object { $_ -match '^\[ERROR\]' }).Count
$files = (Get-ChildItem -Path $gameRoot\Source, $gameRoot\Content -Recurse -Filter *.lua -File).Count
Write-Host "Total: $warnings warnings / $errors errors in $files files"

# Always exit 0 so F5 still launches the game alongside the report.
exit 0
