Write-Host "Building AstroNaksh Portable..." -ForegroundColor Cyan

# 1. Clean & Build
Write-Host "[1/4] Cleaning and building..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Flutter clean failed"
    exit $LASTEXITCODE
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Flutter pub get failed"
    exit $LASTEXITCODE
}

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Flutter build failed"
    exit $LASTEXITCODE
}

# 2. Create portable structure
Write-Host "[2/4] Organizing files..." -ForegroundColor Yellow
if (Test-Path "AstroNaksh") {
    Remove-Item "AstroNaksh" -Recurse -Force
}
New-Item -ItemType Directory -Path "AstroNaksh" | Out-Null

$RELEASE_DIR = "build\windows\x64\runner\Release"

# Copy all .exe and .dll files
Get-ChildItem -Path "$RELEASE_DIR\*.exe" | ForEach-Object { Copy-Item $_.FullName -Destination "AstroNaksh\" }
Get-ChildItem -Path "$RELEASE_DIR\*.dll" | ForEach-Object { Copy-Item $_.FullName -Destination "AstroNaksh\" }

# Copy swisseph.dll (Prefer source version as it is newer)
if (Test-Path "swisseph_src\swisseph.dll") {
    Write-Host "Copying swisseph.dll from swisseph_src..." -ForegroundColor Cyan
    Copy-Item "swisseph_src\swisseph.dll" -Destination "AstroNaksh\"
} elseif (Test-Path "swisseph.dll") {
    Write-Host "Copying swisseph.dll from root (fallback)..." -ForegroundColor Yellow
    Copy-Item "swisseph.dll" -Destination "AstroNaksh\"
} else {
    Write-Warning "⚠️ swisseph.dll not found!"
}

# Copy data folder
if (Test-Path "$RELEASE_DIR\data") {
    Copy-Item "$RELEASE_DIR\data" -Destination "AstroNaksh\" -Recurse
}

# Pre-populate Ephemeris Data to avoid runtime copying/crash
# Target: AstroNaksh\user_data\ephe
# Source: AstroNaksh\data\flutter_assets\assets\ephe
$EPHE_SOURCE = "AstroNaksh\data\flutter_assets\assets\ephe"
$EPHE_DEST = "AstroNaksh\user_data\ephe"

if (Test-Path $EPHE_SOURCE) {
    Write-Host "Pre-populating ephemeris data..." -ForegroundColor Cyan
    if (-not (Test-Path $EPHE_DEST)) {
        New-Item -ItemType Directory -Path $EPHE_DEST -Force | Out-Null
    }
    Copy-Item "$EPHE_SOURCE\*" -Destination $EPHE_DEST -Force
} else {
    Write-Warning "⚠️ Ephemeris assets not found in build output at $EPHE_SOURCE"
}

# 3. Create portable flag and user folders
Write-Host "[3/4] Setting up portable environment..." -ForegroundColor Yellow
New-Item -Path "AstroNaksh\.portable" -ItemType File -Force | Out-Null
New-Item -ItemType Directory -Path "AstroNaksh\user_data" -Force | Out-Null
New-Item -ItemType Directory -Path "AstroNaksh\settings" -Force | Out-Null

# 4. Create zip file
Write-Host "[4/4] Creating ZIP archive..." -ForegroundColor Yellow
$zipFile = "AstroNaksh_Portable.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}
Compress-Archive -Path "AstroNaksh" -DestinationPath $zipFile -Force

if ($?) {
    Write-Host "`n✅ Portable build complete!" -ForegroundColor Green
    Write-Host "Zip File: $zipFile"
    Write-Host "Folder: AstroNaksh\"
} else {
    Write-Error "❌ Failed to create zip archive."
    exit 1
}
