# Compact LuaAnalyzer CLI check: one line per diagnostic, run from the game root.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$gameRoot = Split-Path (Split-Path $PSScriptRoot)
Set-Location $gameRoot

$exe = Join-Path $PSScriptRoot "bin\lua-language-server.exe"
$cfg = Join-Path $gameRoot ".luarc.json"
$selene = Join-Path $PSScriptRoot "selene.exe"
$seleneCfg = Join-Path $PSScriptRoot "selene.toml"

$checkOut1 = Join-Path $env:TEMP "llscheck_source.json"
$checkOut2 = Join-Path $env:TEMP "llscheck_content.json"
Remove-Item $checkOut1 -Force -ErrorAction SilentlyContinue
Remove-Item $checkOut2 -Force -ErrorAction SilentlyContinue

# Scan only game source/content, not Tools/LuaAnalyzer/meta (huge, ~1200 files -> hangs).
# Use call operator & to preserve working directory, not Start-Process.
& $exe --check (Join-Path $gameRoot "Source") --configpath $cfg --check_format=json --check_out_path=$checkOut1 --checklevel=Warning | Out-Null
& $exe --check (Join-Path $gameRoot "Content") --configpath $cfg --check_format=json --check_out_path=$checkOut2 --checklevel=Warning | Out-Null
$out3 = & $selene --config $seleneCfg Source/ Content/ 2>&1 | Out-String

$diag = @()

# Parse lua-language-server JSON check reports
foreach ($report in @($checkOut1, $checkOut2)) {
    if (-not (Test-Path $report)) { continue }
    $content = Get-Content $report -Raw
    if ($content -eq '[]' -or $content -eq '{}') { continue }

    $json = $content | ConvertFrom-Json
    # Iterate over all properties, skip built-in ones
    foreach ($prop in $json.PSObject.Properties) {
        $filePath = $prop.Name
        # Decode URL-encoded path: file:///c%3A/... -> C:/...
        if ($filePath -match '^file:///(.+)$') {
            $decoded = [System.Uri]::UnescapeDataString($Matches[1])
            $filePath = $decoded -replace '/', '\'
        }

        $diagnostics = $prop.Value
        if ($diagnostics -is [System.Array]) {
            foreach ($d in $diagnostics) {
                if ($d.severity -eq $null) { continue }
                $sev = switch ($d.severity) { 1 {'ERROR'} 2 {'WARN'} 4 {'HINT'} default {'WARN'} }
                $line = $d.range.start.line + 1
                $col  = $d.range.start.character + 1
                $msg = ($d.message -replace '\r?\n', ' | ')
                $icon = if ($sev -eq 'WARN') { 'WARN' } else { 'ERROR' }
                $diag += "[$icon] ${filePath}:${line}:${col} - $msg"
            }
        }
    }
}

# Parse selene output
$clean = $out3 -replace '\x1b\[[0-9;]*m', ''
$lines = $clean -split "`n"
$pendingSeverity = $null
$pendingMessage = $null

foreach ($line in $lines) {
    # selene severity line: warning[rule]: message
    if ($line -match '^(warning|error)\[[^\]]+\]:\s*(.+)$') {
        $pendingSeverity = $Matches[1]
        $pendingMessage = $Matches[2]
        continue
    }

    # selene location line: contains file.lua:line:col after severity
    if ($pendingSeverity -and $line -match '([A-Za-z0-9_\-\\/\.]+\.lua):(\d+):(\d+)') {
        $icon = if ($pendingSeverity -eq 'warning') { 'WARN' } else { 'ERROR' }
        $msg = ($pendingMessage -replace '\r?\n', ' | ')
        $diag += "[$icon] $($Matches[1]):$($Matches[2]):$($Matches[3]) - $msg"
        $pendingSeverity = $null
        $pendingMessage = $null
    }
}

$errIcon = [char]0x26D4 + [char]0xFE0F  # ⛔ + variation selector
$warnIcon = [char]0x26A0 + [char]0xFE0F  # ⚠️ (with variation selector for color)
if ($diag.Count -gt 0) {
    foreach ($d in $diag) {
        $line = $d -replace '^\[ERROR\]', "$errIcon" -replace '^\[WARN\]', "$warnIcon"
        Write-Host $line
    }
}
$warnings = ($diag | Where-Object { $_ -match '^\[WARN\]' }).Count
$errors = ($diag | Where-Object { $_ -match '^\[ERROR\]' }).Count
$files = (Get-ChildItem -Path $gameRoot\Source, $gameRoot\Content -Recurse -Filter *.lua -File).Count
Write-Host "Total: $warnings warnings / $errors errors in $files files"

# Always exit 0 so F5 still launches the game alongside the report.
exit 0
