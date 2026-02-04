@echo off
setlocal enabledelayedexpansion

echo Building AstroNaksh Portable...

:: 1. Clean & Build
echo [1/4] Cleaning and building...
call flutter clean
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter clean failed
    exit /b %ERRORLEVEL%
)

call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter pub get failed
    exit /b %ERRORLEVEL%
)

call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter build failed
    exit /b %ERRORLEVEL%
)

:: 2. Create portable structure
echo [2/4] Organizing files...
if exist "AstroNaksh" rd /s /q "AstroNaksh"
mkdir "AstroNaksh"

set RELEASE_DIR=build\windows\x64\runner\Release

copy "%RELEASE_DIR%\astronaksh.exe" "AstroNaksh\"
copy "%RELEASE_DIR%\flutter_windows.dll" "AstroNaksh\"

:: Check if sqlite3.dll exists (could be a plugin dependency)
if exist "%RELEASE_DIR%\sqlite3.dll" (
    copy "%RELEASE_DIR%\sqlite3.dll" "AstroNaksh\"
)

:: Copy swisseph.dll from root
if exist "swisseph.dll" (
    copy "swisseph.dll" "AstroNaksh\"
) else (
    echo ⚠️ swisseph.dll not found in root directory!
)

:: Copy data folder
xcopy /E /I /Y "%RELEASE_DIR%\data" "AstroNaksh\data"

:: 3. Create portable flag and user folders
echo [3/4] Setting up portable environment...
echo. > "AstroNaksh\.portable"
mkdir "AstroNaksh\user_data"
mkdir "AstroNaksh\settings"

:: 4. Create zip file
echo [4/4] Creating ZIP archive...
powershell -Command "Expand-Archive -Path 'AstroNaksh' -DestinationPath '.' " >nul 2>&1
:: Wait, Expand-Archive is for unzipping. I need Compress-Archive.
powershell -Command "Compress-Archive -Path 'AstroNaksh' -DestinationPath 'AstroNaksh_Portable.zip' -Force"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ✅ Portable build complete!
    echo Zip File: AstroNaksh_Portable.zip
    echo Folder: AstroNaksh\
) else (
    echo ❌ Failed to create zip archive.
)

pause
