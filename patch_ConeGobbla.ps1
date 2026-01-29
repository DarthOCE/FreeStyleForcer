$script:content = $null
$script:patchesApplied = 0

function Apply-Patch {
    param(
        [string]$Name,
        [string]$Pattern,
        [string]$Replacement
    )
    
    Write-Host "[$Name] " -NoNewline
    
    if ($script:content -match $Pattern) {
        $script:content = $script:content -replace $Pattern, $Replacement
        Write-Host "Applied" -ForegroundColor Green
        $script:patchesApplied++
    } else {
        Write-Host "Patch failed (file already patched, pattern changed, or not present)" -ForegroundColor Yellow
    }
}

# Locate NVIDIA App installation
$entries = Get-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NvApp" -ErrorAction SilentlyContinue
if ($entries.Installed -ne 1) {
    Write-Host "NVIDIA App is not installed" -ForegroundColor Red
    exit 1
}

$nvidiaApp = (Get-Item -Path $entries.FullPath).Directory.Parent.FullName
$mainJs = Get-ChildItem -Path "$nvidiaApp\osc" -Filter "main.*.js" -File | Select-Object -First 1

if (-not $mainJs) {
    Write-Host "Could not find main.*.js in $nvidiaApp\osc" -ForegroundColor Red
    exit 1
}

Write-Host "Found main JS file @ $($mainJs.FullName)" -ForegroundColor Green

$script:content = Get-Content -Path $mainJs.FullName -Raw -Encoding UTF8

# Create backup if it doesn't exist yet
$backupPath = "$($mainJs.FullName).bak"
if (-not (Test-Path $backupPath)) {
    Copy-Item -Path $mainJs.FullName -Destination $backupPath
    Write-Host "Backup created @ $backupPath" -ForegroundColor Green
}

# ────────────────────────────────────────────────
# Existing patch: Force FREESTYLE (Game Filters base)
# ────────────────────────────────────────────────
Apply-Patch -Name "Force Freestyle via ChromaDB" `
    -Pattern 'this\.currentGameChromaInfo=(\w+),this\.currentGameChromaInfo\?\.nvidiaTech\?\.FREESTYLE' `
    -Replacement 'this.currentGameChromaInfo=$1,$1?.nvidiaTech&&($1.nvidiaTech.FREESTYLE=!0),this.currentGameChromaInfo?.nvidiaTech?.FREESTYLE'

# ────────────────────────────────────────────────
# New: Force Ansel / Photo Mode
# ────────────────────────────────────────────────
Apply-Patch -Name "Force Ansel / PHOTO_MODE" `
    -Pattern 'this\.currentGameChromaInfo=(\w+),this\.currentGameChromaInfo\?\.nvidiaTech\?\.PHOTO_MODE' `
    -Replacement 'this.currentGameChromaInfo=$1,$1?.nvidiaTech&&($1.nvidiaTech.PHOTO_MODE=!0),this.currentGameChromaInfo?.nvidiaTech?.PHOTO_MODE'

# ────────────────────────────────────────────────
# New: Force Ansel flags / predefined usage override
# (some builds check a separate or aliased flag)
# ────────────────────────────────────────────────
Apply-Patch -Name "Force Ansel flags / Predefined Usage" `
    -Pattern '(?:ANSEL|ansel| Ansel|photo| AnselEnabled|predefinedAnsel)[^\{]*nvidiaTech[^\{]*(\w+)[^\}]*\1\?\.nvidiaTech\?\.(?:ANSEL|PHOTO_MODE|ENABLED|ALLOW)' `
    -Replacement '$&;$1?.nvidiaTech&&($1.nvidiaTech.PHOTO_MODE=!0,$1.nvidiaTech.ANSEL=!0)'

# ────────────────────────────────────────────────
# New: Force overall Game Filters toggle
# (sometimes a separate flag or alias exists)
# ────────────────────────────────────────────────
Apply-Patch -Name "Force Game Filters overall enable" `
    -Pattern 'this\.currentGameChromaInfo=(\w+),.*?filtersEnabled|gameFilters|freestyleEnabled|overlayFilters|nvidiaTech\?\.GAMEFILTERS?|FREESTYLE.*?=.*?false' `
    -Replacement 'this.currentGameChromaInfo=$1,$1?.nvidiaTech&&($1.nvidiaTech.FREESTYLE=!0,$1.nvidiaTech.GAMEFILTERS=!0),true'

Write-Host ""

# Write changes if anything was patched
if ($script:patchesApplied -gt 0) {
    Set-Content -Path $mainJs.FullName -Value $script:content -NoNewline -Encoding UTF8
    Write-Host "$script:patchesApplied patch(es) applied and written to file." -ForegroundColor Green
} else {
    Write-Host "No patches were applied — file may already be patched or patterns no longer match." -ForegroundColor Yellow
}

# Restart prompt
Get-Process -Name "NVIDIA Overlay*", "NVIDIA App*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "`nPlease restart the NVIDIA Overlay / App:" -ForegroundColor Yellow
Write-Host "  → Open NVIDIA App → toggle Overlay off → wait a few seconds → toggle back on" -ForegroundColor Yellow
Write-Host "  (or completely restart the NVIDIA App if needed)" -ForegroundColor Yellow
Write-Host ""
Write-Host "To undo changes: replace main.*.js with the .bak file" -ForegroundColor Yellow
Write-Host ""

$null = Read-Host "Press ENTER to exit"