@echo off
echo ========================================
echo COMFYUI-MANAGER CACHE CLEARER
echo ========================================
echo.

set "COMFYUI_ROOT=%USERPROFILE%\Documents\ComfyUI"
echo ComfyUI Root: %COMFYUI_ROOT%
echo.

if not exist "%COMFYUI_ROOT%" (
    echo ERROR: ComfyUI directory not found!
    echo Please run the install script first.
    pause
    exit /b 1
)

set "CACHE_DIR=%COMFYUI_ROOT%\user\default\ComfyUI-Manager\cache"
echo Looking for cache at: %CACHE_DIR%
echo.

if exist "%CACHE_DIR%" (
    echo Found cache directory. Clearing files...
    echo.
    
    echo Current cache files:
    dir "%CACHE_DIR%\*.json" 2>nul
    echo.
    
    echo Creating backup...
    set "BACKUP_DIR=%CACHE_DIR%_backup"
    xcopy "%CACHE_DIR%" "%BACKUP_DIR%" /E /I /Y >nul 2>&1
    if exist "%BACKUP_DIR%" (
        echo Backup created at: %BACKUP_DIR%
    ) else (
        echo Warning: Failed to create backup
    )
    echo.
    
    echo Clearing cache files...
    del "%CACHE_DIR%\*.json" 2>nul
    echo Cache cleared!
    echo.
) else (
    echo Cache directory not found.
    echo This is normal if ComfyUI-Manager hasn't been used yet.
    echo.
)

set "STARTUP_DIR=%COMFYUI_ROOT%\user\default\ComfyUI-Manager\startup-scripts"
if exist "%STARTUP_DIR%\install-scripts.txt" (
    echo Clearing install scripts...
    del "%STARTUP_DIR%\install-scripts.txt" 2>nul
    echo Install scripts cleared!
    echo.
)

echo ========================================
echo CACHE CLEARING COMPLETED
echo ========================================
echo.
echo Next steps:
echo 1. Start ComfyUI normally
echo 2. ComfyUI-Manager will rebuild its cache
echo 3. PR reference errors should be resolved
echo.

echo Press any key to exit...
pause
