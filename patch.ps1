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
        Write-Host "Patch failed (file already patched or pattern changed)" -ForegroundColor Yellow
    }
}

# Find the app itself, should always be in C:\Program Files\NVIDIA Corporation\NVIDIA App, but just incase..
$entries = Get-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NvApp" -ErrorAction SilentlyContinue
if ($entries.Installed -ne 1) {
    Write-Host "NVIDIA App not installed" -ForegroundColor Red
    exit 1
}

# Get parent directory of the path, the registry key returns the CEF directory.
# Then find the main.js file inside the 'osc' directory.
$nvidiaApp = (Get-Item -Path $entries.FullPath).Directory.Parent.FullName
$mainJs = Get-ChildItem -Path "$nvidiaApp\osc" -Filter "main.*.js" -File | Select-Object -First 1

if (-not $mainJs) {
    Write-Host "Could not find main.js in $nvidiaApp\osc" -ForegroundColor Red
    exit 1
}

Write-Host "Found main.js @ $($mainJs.FullName)" -ForegroundColor Green
$script:content = Get-Content -Path $mainJs.FullName -Raw -Encoding UTF8

# Backup..
$backupPath = "$($mainJs.FullName).bak"
if (-not (Test-Path $backupPath)) {
    Copy-Item -Path $mainJs.FullName -Destination $backupPath
    Write-Host "Backup created @ $backupPath" -ForegroundColor Green
}

# The overlay queries NVIDIA's ChromaDB API for game metadata before initializing support, this takes precedence over the support values in DRS and is the main culprit for why filters don't work on certain games despite using profileInspector.
# The return from the API describes these values for allowed technologies (example game: Arc Raiders, after forced filter disabling):
#
# {
#    "id": "dfdbc357-7f61-45cc-bf64-ae7117da12d5",
#    "title": "ARC Raiders",
#    "nvidiaTech": {
#        "PHOTO_MODE": false,
#        "FREESTYLE": false,
#        "RTXDVC": false,
#        "REFLEX": false,
#        "REFLEXFLASHINDICATOR": false,
#        "REFLEXFIAUTO": false,
#        "REFLEXSTATS": false,
#        "GAMEASSIST": false
#    }
# } 
#
# This patch replaces the ChromaDB response assignment inside 'ensureChromaDataIsAvailableForGame' for the freestyle class. We force nvidiaTech['FREESTYLE'] to always be true.
#
Apply-Patch `
    -Name "ChromaDB" `
    -Pattern 'this\.currentGameChromaInfo=tt,this\.currentGameChromaInfo\?\.nvidiaTech\?\.FREESTYLE' `
    -Replacement 'this.currentGameChromaInfo=tt,tt?.nvidiaTech&&(tt.nvidiaTech.FREESTYLE=!0),this.currentGameChromaInfo?.nvidiaTech?.FREESTYLE'

# Risky patch, this will override what the driver store returns and essentially enable freestyle support for every application.
# Uncomment only if you know what you're doing.
# In a normal system, this will return false in these scenarios:
#   The game has a mutex named 'NVIDIA/FreeStyleDisallow/{..}' in which case it means the game developers blacklisted freestyle explicitly.
#   Setting 0x105E2A1D is set to 0. This setting is usually 4 which means Restricted usage, it may also be 1 which means Unrestricted usage. The only games where it is 0 are MSFS2024, FIFA 18, Fortnite & Rust.
#   In the case of restricted usage, Ansel refers to setting 0x100D51F7 which describes the deny list for the shaders. Common values are 'Buffers=(Depth)'.
#
#Apply-Patch `
#    -Name "DRS" `
#    -Pattern 'GetFreestyleWhitelisted,\{profileName:tt\}\)\}' `
#    -Replacement 'GetFreestyleWhitelisted,{profileName:tt}).pipe((0,B.T)(r=>(r.freestyleWhitelisted=!0,r)))}'

# Write patched content if any patches were applied
if ($script:patchesApplied -gt 0) {
    Set-Content -Path $mainJs.FullName -Value $script:content -NoNewline -Encoding UTF8
    Write-Host "$script:patchesApplied patch(es) written to file." -ForegroundColor Green
}

# Kill the overlay and prompt user to restart it.
Get-Process -Name "NVIDIA Overlay*" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Restart the overlay from NVIDIA App by toggling it on and off" -Foreground Yellow
Write-Host "If you want to revert the patches, replace main.js with the .bak file" -Foreground Yellow
$null = Read-Host "Press ENTER to exit this script"

# The overlay is started with specific parameters by the app, this could work but GPU accel might be off? -- Prompt user instead.
# Start-Process "$nvidiaApp\CEF\NVIDIA Overlay.exe"