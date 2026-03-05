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

# 5. Copy DLL to root
if (Test-Path "$TEMP_DIR/$DLL_NAME") {
    Write-Host "Copying $DLL_NAME..." -ForegroundColor Cyan
    Copy-Item "$TEMP_DIR/$DLL_NAME" -Destination "." -Force
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
