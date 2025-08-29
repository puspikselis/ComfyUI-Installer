@echo off
setlocal enabledelayedexpansion

call "%~dp0..\config\constants.bat"

set "auto_mode=false"
set "remove_python=false"

if "%~1"=="--auto" (
    set "auto_mode=true"
    set "remove_python=false"
    echo [INFO] Auto mode enabled - ComfyUI only uninstall
) else if "%~1"=="--full" (
    set "auto_mode=true"
    set "remove_python=true"
    echo [INFO] Full cleanup mode enabled - Complete system cleanup
) else if "%~1"=="--help" (
    echo Usage: uninstall.bat [--auto ^| --full ^| --help]
    echo   --auto  : ComfyUI only uninstall
    echo   --full  : Complete system cleanup
    echo   --help  : Show this help message
    exit /b 0
)

echo.
echo ========================================
echo UNINSTALL COMFYUI
echo ========================================
echo.

if "%auto_mode%"=="false" (
    echo Choose uninstall option:
    echo 1. ComfyUI Only
    echo 2. Complete Cleanup
    set /p choice="Select (1-2): "
    if "!choice!"=="1" set "remove_python=false"
    if "!choice!"=="2" set "remove_python=true"
)

echo Starting uninstall process...

echo [INFO] Stopping ComfyUI processes...
set "TASKLIST=%SystemRoot%\System32\tasklist.exe"
set "TASKKILL=%SystemRoot%\System32\taskkill.exe"
for /f "tokens=2" %%p in ('"%TASKLIST%" /fi "imagename eq python.exe" /fo list ^| find "PID:"') do (
  for /f "tokens=*" %%c in ('wmic process where "ProcessId=%%p" get CommandLine ^| find "main.py"') do (
    "%TASKKILL%" /pid %%p /f >nul 2>&1
  )
)
echo [OK] Targeted processes stopped

if exist "%COMFYUI_ROOT%" (
    echo [INFO] Removing ComfyUI directory: %COMFYUI_ROOT%
    
    rem Remove virtual environment if it exists (use VENV_DIR if defined)
    if not defined VENV_DIR set "VENV_DIR=%COMFYUI_ROOT%\venv"
    if exist "%VENV_DIR%\Scripts\python.exe" (
        echo [INFO] Removing virtual environment at %VENV_DIR%...
        rd /s /q "%VENV_DIR%" 2>nul
        if exist "%VENV_DIR%" (
            echo [WARN] Failed to remove virtual environment
        ) else (
            echo [OK] Virtual environment removed
        )
    )
    
    rd /s /q "%COMFYUI_ROOT%" 2>nul
    if exist "%COMFYUI_ROOT%" (
        echo [ERROR] Failed to remove ComfyUI directory
    ) else (
        echo [OK] ComfyUI directory removed
    )
) else (
    echo [INFO] ComfyUI directory not found
)

echo [INFO] Cleaning caches...
if exist "%USERPROFILE%\.cache\huggingface" rd /s /q "%USERPROFILE%\.cache\huggingface" 2>nul
if exist "%USERPROFILE%\.cache\torch" rd /s /q "%USERPROFILE%\.cache\torch" 2>nul
if exist "%USERPROFILE%\.cache\transformers" rd /s /q "%USERPROFILE%\.cache\transformers" 2>nul
if exist "%LOCALAPPDATA%\pip\Cache" rd /s /q "%LOCALAPPDATA%\pip\Cache" 2>nul
if exist "%TEMP%\comfy" rd /s /q "%TEMP%\comfy" 2>nul
if exist "%TEMP%\huggingface" rd /s /q "%TEMP%\huggingface" 2>nul
if exist "%TEMP%\triton" rd /s /q "%TEMP%\triton" 2>nul
if exist "%TEMP%\flash_attn" rd /s /q "%TEMP%\flash_attn" 2>nul
if exist "%TEMP%\sageattention" rd /s /q "%TEMP%\sageattention" 2>nul
if exist "%USERPROFILE%\.triton" rd /s /q "%USERPROFILE%\.triton" 2>nul
echo [OK] Caches cleaned

echo [INFO] Running comprehensive cache cleanup...
echo [INFO] Cleaning Triton cache thoroughly...
if exist "%USERPROFILE%\.triton" (
    echo [INFO] Found Triton cache, cleaning contents...
    for /f "delims=" %%i in ('dir /b /a "%USERPROFILE%\.triton\*" 2^>nul') do (
        if exist "%USERPROFILE%\.triton\%%i" (
            rd /s /q "%USERPROFILE%\.triton\%%i" 2>nul
            if not exist "%USERPROFILE%\.triton\%%i" (
                echo [OK] Removed: %%i
            ) else (
                echo [WARN] Could not remove: %%i (may be in use)
            )
        )
    )
    echo [OK] Triton cache cleanup completed
) else (
    echo [INFO] Triton cache not found
)

echo [INFO] Cleaning additional temp directories...
for %%d in (huggingface triton flash_attn sageattention comfy) do (
    if exist "%TEMP%\%%d" (
        rd /s /q "%TEMP%\%%d" 2>nul
        if not exist "%TEMP%\%%d" (
            echo [OK] Removed temp: %%d
        ) else (
            echo [WARN] Could not remove temp: %%d (may be in use)
        )
    )
)
echo [OK] Comprehensive cache cleanup completed

echo [INFO] Cleaning downloaded models and datasets...
if exist "%COMFYUI_ROOT%\models" rd /s /q "%COMFYUI_ROOT%\models" 2>nul
if exist "%COMFYUI_ROOT%\ReActor" rd /s /q "%COMFYUI_ROOT%\ReActor" 2>nul
if exist "%COMFYUI_ROOT%\SECourses_Patreon_Rocks" rd /s /q "%COMFYUI_ROOT%\SECourses_Patreon_Rocks" 2>nul
if exist "%COMFYUI_ROOT%\custom_nodes" rd /s /q "%COMFYUI_ROOT%\custom_nodes" 2>nul
if exist "%COMFYUI_ROOT%\temp_swarm" rd /s /q "%COMFYUI_ROOT%\temp_swarm" 2>nul
echo [OK] Models and custom nodes cleaned

echo [INFO] Cleaning environment variables...
set HF_HUB_ENABLE_HF_TRANSFER= 2>nul
set HF_XET_CHUNK_CACHE_SIZE_BYTES= 2>nul
echo [OK] Environment variables cleaned

echo [INFO] Cleaning browser caches...

echo [INFO] Cleaning Microsoft Edge cache...
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
    echo [OK] Edge cache cleaned
) else (
    echo [INFO] Edge cache not found
)
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache" 2>nul
    echo [OK] Edge code cache cleaned
)
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\GPUCache" 2>nul
    echo [OK] Edge GPU cache cleaned
)

echo [INFO] Cleaning Google Chrome cache...
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
    echo [OK] Chrome cache cleaned
) else (
    echo [INFO] Chrome cache not found
)
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" 2>nul
    echo [OK] Chrome code cache cleaned
)
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\GPUCache" 2>nul
    echo [OK] Chrome GPU cache cleaned
)

echo [INFO] Cleaning Brave Browser cache...
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" 2>nul
    echo [OK] Brave cache cleaned
) else (
    echo [INFO] Brave cache not found
)
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Code Cache" 2>nul
    echo [OK] Brave code cache cleaned
)
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\GPUCache" 2>nul
    echo [OK] Brave GPU cache cleaned
)

echo [INFO] Cleaning Mozilla Firefox cache...
if exist "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2" 2>nul
            echo [OK] Firefox cache cleaned: %%~nxp
        )
        if exist "%%p\startupCache" (
            rd /s /q "%%p\startupCache" 2>nul
            echo [OK] Firefox startup cache cleaned: %%~nxp
        )
    )
) else (
    echo [INFO] Firefox cache not found
)

echo [INFO] Cleaning Opera cache...
if exist "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\Cache" 2>nul
    echo [OK] Opera cache cleaned
) else (
    echo [INFO] Opera cache not found
)
if exist "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\Code Cache" 2>nul
    echo [OK] Opera code cache cleaned
)
if exist "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\Opera Software\Opera Stable\User Data\Default\GPUCache" 2>nul
    echo [OK] Opera GPU cache cleaned
)

echo [INFO] Cleaning Vivaldi cache...
if exist "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache" 2>nul
    echo [OK] Vivaldi cache cleaned
) else (
    echo [INFO] Vivaldi cache not found
)
if exist "%LOCALAPPDATA%\Vivaldi\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\Vivaldi\User Data\Default\Code Cache" 2>nul
    echo [OK] Vivaldi code cache cleaned
)
if exist "%LOCALAPPDATA%\Vivaldi\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\Vivaldi\User Data\Default\GPUCache" 2>nul
    echo [OK] Vivaldi GPU cache cleaned
)

echo [INFO] Cleaning Microsoft Internet Explorer cache...
if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache" 2>nul
    echo [OK] Internet Explorer cache cleaned
) else (
    echo [INFO] Internet Explorer cache not found
)

echo [INFO] Cleaning Microsoft Edge (Legacy) cache...
if exist "%LOCALAPPDATA%\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\User\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\User\Default\Cache" 2>nul
    echo [OK] Edge Legacy cache cleaned
) else (
    echo [INFO] Edge Legacy cache not found
)

echo [INFO] Cleaning Chromium cache...
if exist "%LOCALAPPDATA%\Chromium\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Chromium\User Data\Default\Cache" 2>nul
    echo [OK] Chromium cache cleaned
) else (
    echo [INFO] Chromium cache not found
)
if exist "%LOCALAPPDATA%\Chromium\User Data\Default\Code Cache" (
    rd /s /q "%LOCALAPPDATA%\Chromium\User Data\Default\Code Cache" 2>nul
    echo [OK] Chromium code cache cleaned
)
if exist "%LOCALAPPDATA%\Chromium\User Data\Default\GPUCache" (
    rd /s /q "%LOCALAPPDATA%\Chromium\User Data\Default\GPUCache" 2>nul
    echo [OK] Chromium GPU cache cleaned
)

echo [INFO] Cleaning Waterfox cache...
if exist "%LOCALAPPDATA%\Waterfox\Profiles" (
    for /d %%p in ("%LOCALAPPDATA%\Waterfox\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2" 2>nul
            echo [OK] Waterfox cache cleaned: %%~nxp
        )
    )
) else (
    echo [INFO] Waterfox cache not found
)

echo [INFO] Cleaning Pale Moon cache...
if exist "%LOCALAPPDATA%\Moonchild Productions\Pale Moon\Profiles" (
    for /d %%p in ("%LOCALAPPDATA%\Moonchild Productions\Pale Moon\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2" 2>nul
            echo [OK] Pale Moon cache cleaned: %%~nxp
        )
    )
) else (
    echo [INFO] Pale Moon cache not found
)

echo [INFO] Cleaning SeaMonkey cache...
if exist "%LOCALAPPDATA%\Mozilla\SeaMonkey\Profiles" (
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\SeaMonkey\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2" 2>nul
            echo [OK] SeaMonkey cache cleaned: %%~nxp
        )
    )
) else (
    echo [INFO] SeaMonkey cache not found
)

echo [OK] All browser caches cleaned

echo [INFO] Detecting Python...
set "python_cmd="
python --version >nul 2>&1
if not errorlevel 1 (
    set "python_cmd=python"
) else (
    py --version >nul 2>&1
    if not errorlevel 1 (
        set "python_cmd=py"
    ) else (
        echo [WARNING] No Python found - skipping package uninstall
        goto :skip_packages
    )
)

echo [INFO] Using Python: !python_cmd!
echo [INFO] Uninstalling packages...
!python_cmd! -m pip uninstall -y torch torchvision torchaudio torchsde 2>nul
!python_cmd! -m pip uninstall -y sageattention flash-attn deepspeed triton-windows 2>nul
!python_cmd! -m pip uninstall -y accelerate bitsandbytes torchao 2>nul
!python_cmd! -m pip uninstall -y py-cpuinfo diffusers transformers 2>nul
!python_cmd! -m pip uninstall -y opencv-python psutil requests tqdm 2>nul
!python_cmd! -m pip uninstall -y matplotlib seaborn aiohttp websockets 2>nul
!python_cmd! -m pip uninstall -y fastapi uvicorn safetensors numpy pillow scipy 2>nul
!python_cmd! -m pip uninstall -y onnxruntime-gpu hf_transfer hf_xet huggingface_hub 2>nul
!python_cmd! -m pip uninstall -y insightface xformers peft piexif 2>nul
!python_cmd! -m pip cache purge 2>nul
echo [OK] Packages uninstalled

:skip_packages

if "%remove_python%"=="true" (
    echo [INFO] Removing Python installation...
    winget uninstall Python --accept-source-agreements --disable-interactivity 2>nul
    
    for %%v in (3.8 3.9 3.10 3.11 3.12 3.13) do (
        if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python%%v\unins000.exe" (
            echo [INFO] Uninstalling Python %%v...
            "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python%%v\unins000.exe" /SILENT
        )
    )
    
    if exist "%USERPROFILE%\AppData\Local\Programs\Python" (
        rmdir /s /q "%USERPROFILE%\AppData\Local\Programs\Python" 2>nul
    )
    
    for /d %%d in ("C:\Python*") do rmdir /s /q "%%d" 2>nul
    
    if exist "%USERPROFILE%\AppData\Roaming\Python" (
        rmdir /s /q "%USERPROFILE%\AppData\Roaming\Python" 2>nul
    )
    
    if exist "%USERPROFILE%\AppData\Local\pip" (
        rmdir /s /q "%USERPROFILE%\AppData\Local\pip" 2>nul
    )
    
    echo [OK] Python removal completed
)

echo.
echo ========================================
echo UNINSTALL COMPLETED SUCCESSFULLY!
echo ========================================
echo.

if "%remove_python%"=="true" (
    echo Complete system cleanup finished!
    echo - ComfyUI removed
    echo - Python removed
    echo - All caches cleaned
) else (
    echo ComfyUI uninstallation finished!
    echo - ComfyUI removed
    echo - Packages uninstalled  
    echo - Caches cleaned
    echo - Python preserved
)

echo.
pause
exit /b 0
