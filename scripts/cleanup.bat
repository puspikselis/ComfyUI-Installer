@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Simple System Cleanup Script
echo ========================================
echo.

echo [INFO] This script will clean temporary files and common leftover folders
echo [WARNING] Make sure to close all programs before running this cleanup
echo.

set /p confirm="Do you want to continue? (y/N): "
if /i not "%confirm%"=="y" (
    echo [INFO] Operation cancelled
    pause
    exit /b 0
)

echo.
echo [STEP 1] Cleaning Windows temporary files...
echo ------------------------------------------
echo [INFO] Cleaning user temp directory...
del /s /q "%TEMP%\*.*" 2>nul
for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" 2>nul
echo [OK] User temp cleaned

echo [INFO] Cleaning Windows temp directory...
del /s /q "%SystemRoot%\Temp\*.*" 2>nul
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" 2>nul
echo [OK] Windows temp cleaned

echo.
echo [STEP 2] Cleaning browser caches...
echo ----------------------------------

echo [INFO] Cleaning Edge cache...
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
    echo [OK] Edge cache cleaned
) else (
    echo [INFO] Edge cache not found
)

echo [INFO] Cleaning Chrome cache...
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
    echo [OK] Chrome cache cleaned
) else (
    echo [INFO] Chrome cache not found
)

echo [INFO] Cleaning Firefox cache...
if exist "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2" 2>nul
            echo [OK] Firefox cache cleaned: %%~nxp
        )
    )
) else (
    echo [INFO] Firefox cache not found
)

echo.
echo [STEP 3] Cleaning Windows prefetch...
echo ------------------------------------
if exist "%SystemRoot%\Prefetch" (
    del /s /q "%SystemRoot%\Prefetch\*.*" 2>nul
    echo [OK] Prefetch cleaned
) else (
    echo [INFO] Prefetch not accessible (need admin rights)
)

echo.
echo [STEP 4] Cleaning common leftover folders...
echo -------------------------------------------

echo [INFO] Looking for empty application folders in Program Files...
if exist "%ProgramFiles%" (
    for /d %%d in ("%ProgramFiles%\*") do (
        dir /b "%%d" 2>nul | findstr /r ".*" >nul
        if errorlevel 1 (
            echo [INFO] Found empty folder: %%d
            rd "%%d" 2>nul
            if not exist "%%d" echo [OK] Removed: %%d
        )
    )
)

echo [INFO] Looking for empty application folders in Program Files (x86)...
if exist "%ProgramFiles(x86)%" (
    for /d %%d in ("%ProgramFiles(x86)%\*") do (
        dir /b "%%d" 2>nul | findstr /r ".*" >nul
        if errorlevel 1 (
            echo [INFO] Found empty folder: %%d
            rd "%%d" 2>nul
            if not exist "%%d" echo [OK] Removed: %%d
        )
    )
)

echo.
echo [STEP 5] Cleaning pip and Python caches...
echo -----------------------------------------
if exist "%LOCALAPPDATA%\pip\Cache" (
    rd /s /q "%LOCALAPPDATA%\pip\Cache" 2>nul
    echo [OK] Pip cache cleaned
)

if exist "%USERPROFILE%\.cache" (
    rd /s /q "%USERPROFILE%\.cache" 2>nul
    echo [OK] User cache directory cleaned
)

echo.
echo [STEP 6] Emptying Recycle Bin...
echo -------------------------------
echo [INFO] Emptying Recycle Bin on all drives...
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul
if %errorlevel% equ 0 (
    echo [OK] Recycle Bin emptied
) else (
    echo [INFO] Attempting alternative method...
    rd /s /q "%SystemDrive%\$Recycle.Bin" 2>nul
    echo [OK] Recycle Bin cleanup attempted
)

echo.
echo [STEP 6] Running system file cleanup...
echo --------------------------------------
echo [INFO] Running Windows Disk Cleanup utility...
start /wait cleanmgr /sagerun:1
echo [OK] Disk cleanup completed

echo.
echo ========================================
echo CLEANUP COMPLETED!
echo ========================================
echo.

echo [SUMMARY] Cleaned:
echo - Windows temporary files
echo - Browser caches
echo - Windows prefetch
echo - Empty application folders
echo - Python/pip caches
echo - Recycle Bin (all drives)
echo - System files (via Disk Cleanup)

echo.
echo [RECOMMENDATION] Restart your computer to complete the cleanup
echo.

echo Press any key to exit...
pause >nul
exit /b 0
