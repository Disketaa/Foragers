# The script needs one thing it cannot invent (it will tell you if missing):
#   love.exe 64-bit 11.5   (default C:\Program Files\LOVE\love.exe, or -LoveExePath)
#
# The exe's Windows shell icon comes from Icon.ico, injected into love.exe via
# rcedit before fusing (verified: host grows 387072 -> 436736, fuse stays byte-exact).
# The in-game/title-bar icon comes from conf.lua (t.window.icon = Icon.png).

param(
    [string]$LoveExePath     = "C:\Program Files\LOVE\love.exe",
    [string]$ProductName     = "Foragers",
    [string]$ProductVersion  = "1.0.0"
)

$ErrorActionPreference = "Stop"

# Compress-Archive races with real-time antivirus (Defender) which briefly locks
# freshly-written files; retry a few times so a transient lock doesn't fail the build.
function Compress-ArchiveWithRetry {
	param($Path, $DestinationPath, $MaxTries = 8)
	$attempt = 0
	while ($true) {
		$attempt++
		try {
			Compress-Archive -Path $Path -DestinationPath $DestinationPath -Force
			return
		} catch {
			if ($attempt -ge $MaxTries) { throw }
			Start-Sleep -Seconds 1
		}
	}
}

$ScriptDir   = $PSScriptRoot
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$BuildDir    = Join-Path $ScriptDir "Output_tmp_$(Get-Date -Format HHmmss)"
$StageDir    = Join-Path $BuildDir "_stage"
$OutDir      = Join-Path $ScriptDir "Output"
$Timestamp   = "Foragers_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# --- Pre-flight ---
if (-not (Test-Path $LoveExePath)) {
    Write-Error "love.exe not found at '$LoveExePath'. Install LÖVE 11.5 (64-bit) or pass -LoveExePath."
    exit 1
}

try {
    $ver = & $LoveExePath --version 2>$null
    if ($ver -notmatch "11\.5") {
        Write-Warning "love.exe reports '$ver' - expected 11.5 to match your dev version."
    }
} catch {
    Write-Warning "Could not run '$LoveExePath --version'; continuing anyway."
}

# --- Idempotent: wipe and recreate Output/ ---
# Remove-Item races with Defender/Explorer holding handles on Output/; retry so a
# transient lock doesn't abort the whole build.
function Remove-ItemWithRetry {
	param($Path, $MaxTries = 8)
	$attempt = 0
	while (Test-Path $Path) {
		$attempt++
		try {
			Remove-Item $Path -Recurse -Force -ErrorAction Stop
			return
		} catch {
			if ($attempt -ge $MaxTries) { throw }
			Start-Sleep -Seconds 1
		}
	}
}
if (Test-Path $BuildDir) { Remove-ItemWithRetry $BuildDir }
New-Item $StageDir -ItemType Directory -Force | Out-Null

# --- Phase 2: stage project so conf.lua etc. land at the zip root (not nested) ---
$ExcludeDirs  = @(".git", ".kilo", "Tools", "Build", ".vscode", "node_modules")
$ExcludeFiles = @("*.bat", "*.ps1", "*.love", "*.ico")   # build scripts + generated love/ico artifacts

foreach ($item in Get-ChildItem -Path $ProjectRoot -Force) {
    if ($item.PSIsContainer) {
        if ($ExcludeDirs -contains $item.Name) { continue }
        Copy-Item -Path $item.FullName -Destination $StageDir -Recurse -Force
    } else {
        $skip = $false
        foreach ($pat in $ExcludeFiles) {
            if ($item.Name -like $pat) { $skip = $true; break }
        }
        if ($skip) { continue }
        Copy-Item -Path $item.FullName -Destination $StageDir -Force
    }
}

if (-not (Test-Path (Join-Path $StageDir "conf.lua"))) {
    Write-Error "Staging produced no conf.lua - aborting (nothing would be packaged)."
    exit 1
}

# Zip the staged contents, then rename .zip -> .love (a .love is just a renamed zip, per LÖVE docs)
$LoveZip  = Join-Path $BuildDir "Foragers.zip"
$LoveFile = Join-Path $BuildDir "Foragers.love"
if (Test-Path $LoveZip)  { Remove-Item $LoveZip -Force }
if (Test-Path $LoveFile) { Remove-Item $LoveFile -Force }
Compress-ArchiveWithRetry -Path (Join-Path $StageDir "*") -DestinationPath $LoveZip
Move-Item $LoveZip $LoveFile

# --- Phase 3: stage love.exe for fusing, inject the exe shell icon via rcedit ---
# The icon resource lives in the PE, so it must be set on the host BEFORE fusing
# (fusing appends the .love zip after the PE; branding after fuse would corrupt it).
# rcedit grows the host 387072 -> 436736 on the current Icon.ico; Phase 4b verifies
# the fuse stays byte-exact so a truncated/shrunk host can never ship.
$RceditExe   = Join-Path $ScriptDir "Rcedit.exe"
$IconPath    = Join-Path $ScriptDir "Icon.ico"
$UnbrandedLove = Join-Path $BuildDir "_love_host.exe"
Copy-Item $LoveExePath $UnbrandedLove -Force
& $RceditExe "$UnbrandedLove" --set-icon "$IconPath"
$HostSize = (Get-Item $UnbrandedLove).Length

# --- Phase 4: fuse love.exe + Foragers.love -> Foragers.exe ---
$ExeFile  = Join-Path $BuildDir "Foragers.exe"
$copyCmd  = "copy /b `"$UnbrandedLove`" + `"$LoveFile`" `"$ExeFile`""
& cmd /c $copyCmd
Remove-Item $UnbrandedLove -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $ExeFile)) {
    Write-Error "Fuse failed: Foragers.exe was not created."
    exit 1
}

# --- Phase 4b: verify the fuse is byte-exact (catches silent PE corruption) ---
# A tool can exit 0 while producing a wrong-size / mis-fused exe (rcedit did).
# Fail loudly here so a broken host never ships as a 761,107-byte trap.
$expectedSize = $HostSize + (Get-Item $LoveFile).Length
$actualSize   = (Get-Item $ExeFile).Length
if ($actualSize -ne $expectedSize) {
    Write-Error "Fuse size mismatch: expected $expectedSize, got $actualSize. Host PE may be corrupted."
    exit 1
}
$bytes = [System.IO.File]::ReadAllBytes($ExeFile)
if (-not ($bytes[$HostSize] -eq 0x50 -and $bytes[$HostSize+1] -eq 0x4B)) {
    Write-Error "Fuse offset wrong: expected PK zip signature at offset $HostSize, not found. Host size or fuse order is broken."
    exit 1
}
Write-Host "Fuse verified: $actualSize bytes, PK at $HostSize." -ForegroundColor Green

# --- Phase 5: bundle LÖVE runtime DLLs + license (required to run on clean machines) ---
# The fused exe is still love.exe under the hood and dynamically loads these at runtime.
$LoveDir = Split-Path -Parent $LoveExePath
foreach ($dll in Get-ChildItem -Path $LoveDir -Filter "*.dll" -File) {
    Copy-Item -Path $dll.FullName -Destination $BuildDir -Force
}
$license = Join-Path $LoveDir "license.txt"
if (Test-Path $license) {
    Copy-Item -Path $license -Destination $BuildDir -Force
} else {
    Write-Warning "license.txt not found in '$LoveDir' - LÖVE's license requires it be included in distribution."
}

# --- Cleanup intermediate stage ---
Remove-Item $StageDir -Recurse -Force

# --- Phase 6: package distributable as a single zip (not a loose folder) ---
if (-not (Test-Path $OutDir)) { New-Item $OutDir -ItemType Directory -Force | Out-Null }
$ZipFile = Join-Path $OutDir "$Timestamp.zip"
if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }
Compress-ArchiveWithRetry -Path (Join-Path $BuildDir "*") -DestinationPath $ZipFile
# Remove the loose intermediate files from the temp build dir (best-effort; ignore lock)
Remove-Item $BuildDir -Recurse -Force -ErrorAction SilentlyContinue

# --- Phase 7: checklist reminder ---
Write-Host ""
Write-Host "Build complete: $ZipFile" -ForegroundColor Green
Write-Host "Distribute $ZipFile (contains Foragers.exe + LÖVE DLLs + license.txt)." -ForegroundColor Green
Write-Host "Verify before distributing:" -ForegroundColor Cyan
Write-Host "  [ ] Title-bar icon shows your Icon.png (t.window.icon in conf.lua)"
Write-Host "  [ ] Exe shell icon shows Icon.ico (rcedit branding applied to host before fuse)"
Write-Host "  [ ] Saves land in %APPDATA%\Foragers (fused mode)"
Write-Host "  [ ] $Timestamp.zip contains the LÖVE DLLs + license.txt (runs on a clean machine)"
Write-Host "  [ ] No missing-asset errors (Build/ excludes only dev/internal dirs)"
