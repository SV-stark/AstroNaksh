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

Copy-Item "$RELEASE_DIR\astronaksh.exe" -Destination "AstroNaksh\"
Copy-Item "$RELEASE_DIR\flutter_windows.dll" -Destination "AstroNaksh\"

# Check if sqlite3.dll exists
if (Test-Path "$RELEASE_DIR\sqlite3.dll") {
    Copy-Item "$RELEASE_DIR\sqlite3.dll" -Destination "AstroNaksh\"
}

# Copy swisseph.dll from root
if (Test-Path "swisseph.dll") {
    Copy-Item "swisseph.dll" -Destination "AstroNaksh\"
} else {
    Write-Warning "⚠️ swisseph.dll not found in root directory!"
}

# Copy data folder
if (Test-Path "$RELEASE_DIR\data") {
    Copy-Item "$RELEASE_DIR\data" -Destination "AstroNaksh\" -Recurse
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
