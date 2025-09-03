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

echo [INFO] Searching for ComfyUI installations...
set "COMFYUI_FOUND=0"
set "COMFYUI_PATHS="

rem Check default location first
if exist "%COMFYUI_ROOT%" (
    echo [INFO] Found ComfyUI at default location: %COMFYUI_ROOT%
    set "COMFYUI_PATHS=%COMFYUI_ROOT%"
    set "COMFYUI_FOUND=1"
)

rem Comprehensive system-wide search for ComfyUI installations
echo [INFO] Performing comprehensive system-wide search for ComfyUI...
echo [INFO] This may take a few minutes depending on your system size...

rem Search all drives for ComfyUI installations
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        echo [INFO] Scanning drive %%d:\ for ComfyUI installations...
        for /f "delims=" %%f in ('dir /s /b "%%d:\*ComfyUI*" 2^>nul') do (
            if exist "%%f\main.py" if exist "%%f\comfy" (
                echo [INFO] Found ComfyUI installation: %%f
                if defined COMFYUI_PATHS (
                    set "COMFYUI_PATHS=%COMFYUI_PATHS%;%%f"
                ) else (
                    set "COMFYUI_PATHS=%%f"
                )
                set "COMFYUI_FOUND=1"
            )
        )
    )
)

rem Also search for any main.py files that might be ComfyUI (fallback method)
echo [INFO] Performing fallback search for ComfyUI main.py files...
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        for /f "delims=" %%f in ('dir /s /b "%%d:\main.py" 2^>nul') do (
            set "PARENT_DIR=%%~dpf"
            set "PARENT_DIR=!PARENT_DIR:~0,-1!"
            set "SKIP_FILE=0"
            
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "python" >nul && set "SKIP_FILE=1"
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "appdata" >nul && set "SKIP_FILE=1"
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "temp" >nul && set "SKIP_FILE=1"
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "recycle" >nul && set "SKIP_FILE=1"
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "windows" >nul && set "SKIP_FILE=1"
            echo !PARENT_DIR! | "%SystemRoot%\System32\find.exe" /i "program files" >nul && set "SKIP_FILE=1"
            
            if "!SKIP_FILE!"=="0" (
                if exist "!PARENT_DIR!\comfy" (
                    echo [INFO] Found potential ComfyUI via main.py: !PARENT_DIR!
                    if defined COMFYUI_PATHS (
                        set "COMFYUI_PATHS=%COMFYUI_PATHS%;!PARENT_DIR!"
                    ) else (
                        set "COMFYUI_PATHS=!PARENT_DIR!"
                    )
                    set "COMFYUI_FOUND=1"
                )
            )
        )
    )
)

if "%COMFYUI_FOUND%"=="1" (
    echo [INFO] Removing ComfyUI installations...
    for %%p in ("%COMFYUI_PATHS:;=" "%") do (
        if exist "%%~p" (
            echo [INFO] Removing ComfyUI directory: %%~p
            
            rem Remove virtual environment if it exists
            if exist "%%~p\venv\Scripts\python.exe" (
                echo [INFO] Removing virtual environment at %%~p\venv...
                rd /s /q "%%~p\venv" 2>nul
                if exist "%%~p\venv" (
                    echo [WARN] Failed to remove virtual environment at %%~p\venv
                ) else (
                    echo [OK] Virtual environment removed from %%~p
                )
            )
            
            rem Remove the main ComfyUI directory
            rd /s /q "%%~p" 2>nul
            if exist "%%~p" (
                echo [ERROR] Failed to remove ComfyUI directory: %%~p
                echo [INFO] Attempting to remove individual files...
                del /s /q "%%~p\*.*" 2>nul
                for /d %%d in ("%%~p\*") do rd /s /q "%%d" 2>nul
            ) else (
                echo [OK] ComfyUI directory removed: %%~p
            )
        )
    )
) else (
    echo [INFO] No ComfyUI installations found
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

echo [INFO] Cleaning downloaded models and datasets from discovered installations...
if defined COMFYUI_PATHS (
    for %%p in ("%COMFYUI_PATHS:;=" "%") do (
        if exist "%%~p\models" (
            echo [INFO] Cleaning models from: %%~p\models
            rd /s /q "%%~p\models" 2>nul
        )
        if exist "%%~p\ReActor" rd /s /q "%%~p\ReActor" 2>nul
        if exist "%%~p\SECourses_Patreon_Rocks" rd /s /q "%%~p\SECourses_Patreon_Rocks" 2>nul
        if exist "%%~p\custom_nodes" rd /s /q "%%~p\custom_nodes" 2>nul
        if exist "%%~p\temp_swarm" rd /s /q "%%~p\temp_swarm" 2>nul
    )
)
echo [OK] Models and custom nodes cleaned from all installations

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
    echo [INFO] Performing comprehensive system-wide Python removal...
    
    echo [INFO] Stopping all Python processes...
    taskkill /f /im python.exe /t 2>nul
    taskkill /f /im pythonw.exe /t 2>nul
    taskkill /f /im pip.exe /t 2>nul
    
    echo [INFO] Uninstalling Python via winget...
    winget uninstall Python --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python 3.13" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python 3.12" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python 3.11" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python 3.10" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python 3.9" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python Launcher" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python.Python.3.10" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python.Python.3.11" --accept-source-agreements --disable-interactivity 2>nul
    winget uninstall "Python.Python.3.12" --accept-source-agreements --disable-interactivity 2>nul
    
    echo [INFO] Uninstalling Microsoft Store Python packages...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "Get-AppxPackage *Python* | Remove-AppxPackage" 2>nul
    
    echo [INFO] Running Python uninstallers from common locations...
    for %%v in (38 39 310 311 312 313) do (
        if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python%%v\unins000.exe" (
            echo [INFO] Uninstalling Python %%v...
            "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python%%v\unins000.exe" /SILENT /SUPPRESSMSGBOXES
        )
    )
    
    for %%v in (3.8 3.9 3.10 3.11 3.12 3.13) do (
        if exist "C:\Program Files\Python%%v\unins000.exe" (
            echo [INFO] Uninstalling Python %%v from Program Files...
            "C:\Program Files\Python%%v\unins000.exe" /SILENT /SUPPRESSMSGBOXES
        )
    )
    
    echo [INFO] Removing Python Launcher specifically...
    for %%v in (38 39 310 311 312 313) do (
        if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Launcher\unins000.exe" (
            echo [INFO] Uninstalling Python Launcher...
            "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Launcher\unins000.exe" /SILENT /SUPPRESSMSGBOXES
        )
    )
    
    echo [INFO] Performing system-wide Python directory search and removal...
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\" (
            echo [INFO] Scanning drive %%d:\ for Python installations...
            
            rem Search for Python directories
            for /f "delims=" %%p in ('dir /s /b "%%d:\Python*" 2^>nul') do (
                if exist "%%p\python.exe" (
                    echo [INFO] Found Python installation: %%p
                    echo [INFO] Attempting to remove: %%p
                    rmdir /s /q "%%p" 2>nul
                    if exist "%%p" (
                        echo [WARN] Could not remove: %%p (may be in use)
                    ) else (
                        echo [OK] Removed: %%p
                    )
                )
            )
            
            rem Search for pip directories
            for /f "delims=" %%p in ('dir /s /b "%%d:\pip*" 2^>nul') do (
                if exist "%%p\pip.exe" (
                    echo [INFO] Found pip installation: %%p
                    rmdir /s /q "%%p" 2>nul
                )
            )
        )
    )
    
    echo [INFO] Cleaning Python data directories...
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\" (
            if exist "%%d:\Users\%USERNAME%\AppData\Local\Programs\Python" (
                echo [INFO] Removing user Python from drive %%d:
                rmdir /s /q "%%d:\Users\%USERNAME%\AppData\Local\Programs\Python" 2>nul
            )
            if exist "%%d:\Users\%USERNAME%\AppData\Roaming\Python" (
                rmdir /s /q "%%d:\Users\%USERNAME%\AppData\Roaming\Python" 2>nul
            )
            if exist "%%d:\Users\%USERNAME%\AppData\Local\pip" (
                rmdir /s /q "%%d:\Users\%USERNAME%\AppData\Local\pip" 2>nul
            )
        )
    )
    
    echo [INFO] Cleaning Python cache directories...
    if exist "%LOCALAPPDATA%\pip\Cache" rmdir /s /q "%LOCALAPPDATA%\pip\Cache" 2>nul
    if exist "%USERPROFILE%\.cache\pip" rmdir /s /q "%USERPROFILE%\.cache\pip" 2>nul
    
    echo [INFO] Cleaning Windows registry entries...
    reg delete "HKEY_CURRENT_USER\Software\Python" /f 2>nul
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Python" /f 2>nul
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Python" /f 2>nul
    
    echo [INFO] Removing Python from PATH...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Python|pip' }) -join ';'; [Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'User')" 2>nul
    
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "$path = [Environment]::GetEnvironmentVariable('PATH', 'Machine'); $newPath = ($path -split ';' | Where-Object { $_ -notmatch 'Python|pip' }) -join ';'; [Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')" 2>nul
    
    echo [INFO] Removing Python file associations...
    reg delete "HKEY_CURRENT_USER\Software\Classes\.py" /f 2>nul
    reg delete "HKEY_CURRENT_USER\Software\Classes\.pyw" /f 2>nul
    reg delete "HKEY_CURRENT_USER\Software\Classes\.pyc" /f 2>nul
    reg delete "HKEY_CURRENT_USER\Software\Classes\.pyo" /f 2>nul
    
    echo [INFO] Performing aggressive cleanup of remaining Python installations...
    
    rem Kill any remaining Python processes more aggressively
    echo [INFO] Aggressively stopping all Python-related processes...
    taskkill /f /im python.exe /t 2>nul
    taskkill /f /im pythonw.exe /t 2>nul
    taskkill /f /im pip.exe /t 2>nul
    taskkill /f /im idle.exe /t 2>nul
    taskkill /f /im py.exe /t 2>nul
    timeout /t 3 /nobreak >nul
    
    rem Stop Windows Installer service temporarily to unlock files
    echo [INFO] Temporarily stopping Windows Installer service...
    net stop msiserver 2>nul
    timeout /t 2 /nobreak >nul
    
    rem Uninstall via Programs and Features using msiexec
    echo [INFO] Attempting MSI uninstall of Python installations...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Python" 2^>nul ^| find "UninstallString"') do (
        if not "%%b"=="" (
            echo [INFO] Running uninstaller: %%b
            %%b /quiet /norestart 2>nul
        )
    )
    
    rem Force remove stubborn Python directories with enhanced permissions
    for %%v in (310 311 312 313) do (
        if exist "C:\Program Files\Python%%v" (
            echo [INFO] Force removing Python %%v installation...
            
            rem Take ownership and grant full permissions
            takeown /f "C:\Program Files\Python%%v" /r /d y 2>nul
            icacls "C:\Program Files\Python%%v" /grant administrators:F /t 2>nul
            icacls "C:\Program Files\Python%%v" /grant "%USERNAME%":F /t 2>nul
            
            rem Remove read-only attributes
            attrib -r "C:\Program Files\Python%%v\*.*" /s /d 2>nul
            
            rem Try different removal methods
            rmdir /s /q "C:\Program Files\Python%%v" 2>nul
            if exist "C:\Program Files\Python%%v" (
                echo [INFO] Trying alternative removal method...
                rd /s /q "C:\Program Files\Python%%v" 2>nul
            )
            if exist "C:\Program Files\Python%%v" (
                echo [INFO] Trying PowerShell removal method...
                "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Remove-Item 'C:\Program Files\Python%%v' -Recurse -Force" 2>nul
            )
            if exist "C:\Program Files\Python%%v" (
                echo [WARN] Python %%v directory still exists - scheduling for removal at next reboot
                "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Move-Item 'C:\Program Files\Python%%v' 'C:\Program Files\Python%%v.delete' -Force" 2>nul
                echo 'Remove-Item "C:\Program Files\Python%%v.delete" -Recurse -Force' >> "%TEMP%\cleanup_python.ps1"
            ) else (
                echo [OK] Python %%v force removed successfully
            )
        )
    )
    
    rem Restart Windows Installer service
    echo [INFO] Restarting Windows Installer service...
    net start msiserver 2>nul
    
    rem Remove any remaining Python registry entries more thoroughly
    echo [INFO] Deep cleaning Python registry entries...
    for /f "tokens=*" %%k in ('reg query "HKLM\SOFTWARE" /k /f "Python" 2^>nul') do (
        echo [INFO] Removing registry key: %%k
        reg delete "%%k" /f 2>nul
    )
    for /f "tokens=*" %%k in ('reg query "HKCU\SOFTWARE" /k /f "Python" 2^>nul') do (
        echo [INFO] Removing registry key: %%k
        reg delete "%%k" /f 2>nul
    )
    
    rem Remove Python from Windows App list using PowerShell
    echo [INFO] Removing Python from Windows Apps list...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*Python*' } | ForEach-Object { $_.Uninstall() }" 2>nul
    
    echo [INFO] Cleaning Python installer files and caches...
    if exist "%USERPROFILE%\Downloads\python-*.exe" (
        echo [INFO] Removing Python installer from Downloads...
        del /q "%USERPROFILE%\Downloads\python-*.exe" 2>nul
        echo [OK] Python installer removed from Downloads
    )
    
    echo [INFO] Cleaning Package Cache...
    for /f "delims=" %%d in ('dir /s /b "%LOCALAPPDATA%\Package Cache\*python*" 2^>nul') do (
        echo [INFO] Removing package cache: %%d
        rd /s /q "%%d" 2>nul
        if not exist "%%d" (
            echo [OK] Removed: %%d
        )
    )
    
    echo [INFO] Removing Windows Apps aliases...
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe" (
        del /q "%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe" 2>nul
        echo [OK] Removed python.exe alias
    )
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\python3.exe" (
        del /q "%LOCALAPPDATA%\Microsoft\WindowsApps\python3.exe" 2>nul
        echo [OK] Removed python3.exe alias
    )
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\py.exe" (
        del /q "%LOCALAPPDATA%\Microsoft\WindowsApps\py.exe" 2>nul
        echo [OK] Removed py.exe alias
    )
    
    echo [INFO] Cleaning Microsoft Store Python package directory...
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" (
        for /f "delims=" %%f in ('dir /b "%LOCALAPPDATA%\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\python*" 2^>nul') do (
            echo [INFO] Removing Store Python: %%f
            del /q "%LOCALAPPDATA%\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\%%f" 2>nul
        )
    )
    
    echo [INFO] Cleaning Python installation logs...
    del /q "%LOCALAPPDATA%\Temp\Python*.log" 2>nul
    del /q "%TEMP%\Python*.log" 2>nul
    echo [OK] Python logs cleaned
    
    echo [INFO] Removing Python from Start Menu...
    if exist "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Python*" (
        rd /s /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Python*" 2>nul
        echo [OK] Python Start Menu entries removed
    )
    if exist "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Python*" (
        rd /s /q "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Python*" 2>nul
        echo [OK] User Python Start Menu entries removed
    )
    
    echo [INFO] Force refreshing Apps list using PowerShell...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "try { Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Python*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } catch { }"
    
    echo [INFO] Cleaning Windows Installer cache...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "try { Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.GetValue('DisplayName') -like '*Python*' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }"
    
    echo [INFO] Removing stubborn Python WMI/MSI entries...
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
    "$registryPaths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F007E8E2-B4A7-4559-BB78-7AC533822431}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{59ED0114-0C86-4B18-83E2-929AD7D232AD}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{0DDDDA24-0876-4BEF-AC9B-26D8B78DCCC9}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1F097B66-81E9-46FB-BBAC-315C5F50CF94}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{92CFA54C-9CE5-4284-83FD-1D0B8AB2AB69}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{067C6FFC-0FD1-4F3A-8E94-58F091BCC0D5}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{E2BC2EBD-7260-458B-A42C-3322DCB0B82F}', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{0CBB496F-1D15-42F1-AA45-C01C95196EC8}'); foreach ($regPath in $registryPaths) { if (Test-Path $regPath) { Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue } }"
    
    echo [INFO] Clearing Windows Store cache to refresh apps list...
    start /min wsreset.exe
    timeout /t 5 /nobreak >nul 2>&1
    taskkill /f /im WinStore.App.exe 2>nul
    
    echo [OK] Comprehensive system-wide Python removal completed
)

echo [INFO] Cleaning ComfyUI registry entries...
reg delete "HKEY_CURRENT_USER\Software\ComfyUI" /f 2>nul
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\ComfyUI" /f 2>nul

echo [INFO] Cleaning additional temporary files...
del /q "%TEMP%\comfyui_*.log" 2>nul
del /q "%TEMP%\pytorch_*.tmp" 2>nul
del /q "%USERPROFILE%\comfyui_*.log" 2>nul

echo [INFO] Final cleanup verification...
set "CLEANUP_SUCCESS=1"
if defined COMFYUI_PATHS (
    for %%p in ("%COMFYUI_PATHS:;=" "%") do (
        if exist "%%p" (
            echo [WARN] ComfyUI directory still exists: %%p
            set "CLEANUP_SUCCESS=0"
        )
    )
)

echo.
echo ========================================
if "%CLEANUP_SUCCESS%"=="1" (
    echo UNINSTALL COMPLETED SUCCESSFULLY!
) else (
    echo UNINSTALL COMPLETED WITH WARNINGS!
    echo Some directories could not be removed - check above for details
)
echo ========================================
echo.

if "%remove_python%"=="true" (
    echo Complete system cleanup finished!
    if defined COMFYUI_PATHS (
        echo - ComfyUI installations found and removed from:
        for %%p in ("%COMFYUI_PATHS:;=" "%") do echo   * %%p
    ) else (
        echo - No ComfyUI installations found
    )
    echo - Python completely removed from system
    echo - All caches and temporary files cleaned
    echo - Registry entries cleaned
    echo - PATH environment variables cleaned
) else (
    echo ComfyUI uninstallation finished!
    if defined COMFYUI_PATHS (
        echo - ComfyUI installations found and removed from:
        for %%p in ("%COMFYUI_PATHS:;=" "%") do echo   * %%p
    ) else (
        echo - No ComfyUI installations found
    )
    echo - Python packages uninstalled
    echo - Caches and temporary files cleaned
    echo - Python preserved on system
)

echo.
pause
exit /b 0
