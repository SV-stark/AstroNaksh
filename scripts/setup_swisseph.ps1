param(
    [switch]$Force
)

Write-Host "Setting up Swiss Ephemeris assets..." -ForegroundColor Cyan

# 1. Define paths
$TEMP_DIR = "swisseph_temp"
$ANDROID_CPP_DIR = "android/app/src/main/cpp/swisseph"
$ASSETS_EPHE_DIR = "assets/ephe"
$DLL_NAME = "swisseph.dll"

# 2. Check if we need to do anything
if (-not $Force -and (Test-Path $DLL_NAME) -and (Test-Path $ANDROID_CPP_DIR) -and (Test-Path $ASSETS_EPHE_DIR)) {
    Write-Host "✅ Swiss Ephemeris assets already present. Use -Force to re-setup." -ForegroundColor Green
    exit 0
}

# 3. Create target directories
if (-not (Test-Path $ANDROID_CPP_DIR)) { New-Item -ItemType Directory -Path $ANDROID_CPP_DIR -Force | Out-Null }
if (-not (Test-Path $ASSETS_EPHE_DIR)) { New-Item -ItemType Directory -Path $ASSETS_EPHE_DIR -Force | Out-Null }

# 4. Clone official repo (shallow)
if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
Write-Host "Cloning official Swiss Ephemeris repository..." -ForegroundColor Yellow
git clone --depth 1 https://github.com/aloistr/swisseph.git $TEMP_DIR

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to clone repository."
    exit $LASTEXITCODE
}

# 5. Get swisseph.dll from the official Windows zip package
Write-Host "Downloading official Windows DLL package..." -ForegroundColor Cyan
$zipUrl = "https://raw.githubusercontent.com/aloistr/swisseph/master/windows/sweph.zip"
$zipPath = "$TEMP_DIR/sweph.zip"
$zipExtract = "$TEMP_DIR/sweph_win"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
Expand-Archive -LiteralPath $zipPath -DestinationPath $zipExtract -Force

# The zip contains swedll64.dll (64-bit) and swedll32.dll (32-bit)
# We need the 64-bit version renamed to swisseph.dll
$dll64 = Get-ChildItem -Path $zipExtract -Recurse -Filter "swedll64.dll" | Select-Object -First 1
if ($dll64) {
    Copy-Item $dll64.FullName -Destination "swisseph.dll" -Force
    Write-Host "📦 Extracted 64-bit swisseph.dll from sweph.zip" -ForegroundColor Green
}
else {
    # Try any .dll file as fallback
    $anyDll = Get-ChildItem -Path $zipExtract -Recurse -Filter "*.dll" | Select-Object -First 1
    if ($anyDll) {
        Copy-Item $anyDll.FullName -Destination "swisseph.dll" -Force
        Write-Host "📦 Extracted $($anyDll.Name) → swisseph.dll" -ForegroundColor Yellow
    }
    else {
        Write-Warning "No DLL found in sweph.zip. swisseph.dll will not be available."
    }
}

# 6. Copy C sources to Android
Write-Host "Copying C source files..." -ForegroundColor Cyan
Copy-Item "$TEMP_DIR/swe*.c" -Destination $ANDROID_CPP_DIR -Force
Copy-Item "$TEMP_DIR/swe*.h" -Destination $ANDROID_CPP_DIR -Force

# 7. Copy Ephemeris Data (.se1)
Write-Host "Copying ephemeris data..." -ForegroundColor Cyan
$required_ephe = @("seas_18.se1", "semo_18.se1", "sepl_18.se1")
foreach ($file in $required_ephe) {
    if (Test-Path "$TEMP_DIR/ephe/$file") {
        Copy-Item "$TEMP_DIR/ephe/$file" -Destination $ASSETS_EPHE_DIR -Force
    }
    else {
        Write-Warning "Missing $file in source repo!"
    }
}

# 8. Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item $TEMP_DIR -Recurse -Force

Write-Host "✅ Swiss Ephemeris setup complete!" -ForegroundColor Green
