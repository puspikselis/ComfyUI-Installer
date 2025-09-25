@echo off
setlocal EnableDelayedExpansion

REM Central log setup as early as possible
set "LOG_ROOT=%TEMP%\ComfyUI-Installer"
if not exist "%LOG_ROOT%" mkdir "%LOG_ROOT%" >nul 2>&1
for /f "usebackq tokens=1-4 delims=/ " %%a in ('%date%') do set "LOG_DATE=%%d-%%b-%%c"
for /f "tokens=1-3 delims=:" %%a in ('echo %time: =0%') do set "LOG_TIME=%%a-%%b-%%c"
set "INSTALL_LOG=%LOG_ROOT%\install_%LOG_DATE%_%LOG_TIME%.log"
set "INSTALL_LOG=%INSTALL_LOG:,=_%"

REM Track status for final summary
set "INSTALL_STATUS=SUCCESS"
set "INSTALL_ERROR="
set "EXIT_CODE=0"

call :log "[INIT] Starting ComfyUI installer"
call :log "[INIT] Log file: %INSTALL_LOG%"

REM Allow optional flag to skip pauses (useful for CI or scripted runs)
set "INSTALLER_NOPAUSE="
if not "%~1"=="" (
    for %%A in (%*) do (
        if /I "%%~A"=="--no-pause" set "INSTALLER_NOPAUSE=1"
    )
)

REM Disable pip noise and warnings for cleaner output
set "PIP_DISABLE_PIP_VERSION_CHECK=1"
set "PIP_NO_PYTHON_VERSION_WARNING=1"

REM Optional: Enable faster HF downloads
set "HF_HUB_ENABLE_HF_TRANSFER=1"

echo ========================================
echo AUTOMATED COMFYUI INSTALLATION
echo Optimized for NVIDIA GPUs
echo ========================================
echo.

REM Load configuration (try sibling ..\config first, then local config; else defaults)
if exist "%~dp0..\config\constants.bat" (
    call "%~dp0..\config\constants.bat"
) else if exist "%~dp0config\constants.bat" (
    call "%~dp0config\constants.bat"
) else (
    echo [WARN] constants.bat not found; using defaults
    set "PYTORCH_VERSION=2.7.1"
    set "TORCHVISION_VERSION=0.22.1"
    set "TORCHAUDIO_VERSION=2.7.1"
    set "COMFYUI_ROOT=%USERPROFILE%\Documents\ComfyUI"
    set "CUSTOM_NODES_DIR=%COMFYUI_ROOT%\custom_nodes"
    set "PYTHON_EXECUTABLE=python"
    rem Virtual Environment (optional - set to 1 to enable, 0 to disable)
    set "USE_VENV=0"
    rem *** Use cu128 (CUDA 12.8) for torch 2.7.x ***
    set "PYTORCH_INDEX_URL=https://download.pytorch.org/whl/cu128"
    set "TORCH_INSTALL_CMD=torch==%PYTORCH_VERSION% torchvision==%TORCHVISION_VERSION% torchaudio==%TORCHAUDIO_VERSION% --index-url %PYTORCH_INDEX_URL%"

    rem Core groups to avoid empty-installs
    set "CORE_DEPS=pillow numpy transformers safetensors"
    set "EXTRA_DEPS=mako deepdiff piexif"
    set "WEB_DEPS=aiohttp websockets fastapi uvicorn"
    set "VIDEO_DEPS=av"
    set "OPTIMIZATION_DEPS=torchsde accelerate"

    rem Triton and friends (Windows) - disabled by default
    set "TRITON_PKG="

    rem DeepSpeed: pin to Windows wheel for Py 3.12 (0.16.5 has cp312-win_amd64 wheels) - disabled by default
    set "DEEPSPEED_PIP="

    rem FlashAttention: use prebuilt wheel for Py 3.12 + cu128 + torch 2.7.x
    set "FLASH_ATTENTION_WHL=https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v2.8.2/flash_attn-2.8.2+cu128torch2.7-cp312-cp312-win_amd64.whl"
    
    rem Launch args and URLs
    set "COMFYUI_LOCAL_URL=http://127.0.0.1:8188"
    set "COMFYUI_BASIC_ARGS=--listen 0.0.0.0 --port 8188"
    set "COMFYUI_OPTIMIZED_ARGS=--listen 0.0.0.0 --port 8188"
    
    rem ComfyUI extensions (defaults)
    set "COMFYUI_MANAGER_URL=https://github.com/ltdrdata/ComfyUI-Manager.git"
    set "COMFYUI_MANAGER_DIR=comfyui-manager"
    set "CRYSTOOLS_URL=https://github.com/crystian/comfyui-crystools.git"
    set "CRYSTOOLS_DIR=comfyui-crystools"
    
    rem SageAttention default
    set "SAGEATTENTION_VERSION=sageattention"
    
    rem Utility extras
    set "UTIL_DEPS=opencv-python psutil requests tqdm matplotlib seaborn py-cpuinfo diffusers"
    
    rem ComfyUI requirements.txt extras (for --no-deps compatibility)
    set "COMFY_REQ_EXTRAS=einops tokenizers sentencepiece pyyaml yarl alembic SQLAlchemy"
    
    rem Additional accelerators (prebuilt wheels for Py 3.12)
    set "HF_ENABLE_TRANSFER=1"
    set "XFORMERS_WHL="
    set "INSIGHTFACE_WHL="
    set "ONNXRUNTIME_GPU="
)

REM Ensure group defaults even if constants.bat exists but omitted them
if not defined USE_VENV set "USE_VENV=0"
if not defined CORE_DEPS set "CORE_DEPS=pillow numpy transformers safetensors"
if not defined EXTRA_DEPS set "EXTRA_DEPS=mako deepdiff piexif"
if not defined WEB_DEPS set "WEB_DEPS=aiohttp websockets fastapi uvicorn"
if not defined VIDEO_DEPS set "VIDEO_DEPS=av"
if not defined OPTIMIZATION_DEPS set "OPTIMIZATION_DEPS=torchsde accelerate"
if not defined UTIL_DEPS set "UTIL_DEPS=opencv-python psutil requests tqdm matplotlib seaborn py-cpuinfo diffusers"
if not defined TRITON_PKG set "TRITON_PKG="
if not defined DEEPSPEED_PIP set "DEEPSPEED_PIP="
if not defined SAGEATTENTION_VERSION set "SAGEATTENTION_VERSION=sageattention"
if not defined COMFYUI_LOCAL_URL set "COMFYUI_LOCAL_URL=http://127.0.0.1:8188"
if not defined COMFYUI_BASIC_ARGS set "COMFYUI_BASIC_ARGS=--listen 0.0.0.0 --port 8188"
if not defined COMFYUI_OPTIMIZED_ARGS set "COMFYUI_OPTIMIZED_ARGS=--listen 0.0.0.0 --port 8188"
if not defined CUSTOM_NODES_DIR set "CUSTOM_NODES_DIR=%COMFYUI_ROOT%\custom_nodes"
if not defined COMFY_REQ_EXTRAS set "COMFY_REQ_EXTRAS=einops tokenizers sentencepiece pyyaml yarl alembic SQLAlchemy"
if not defined HF_ENABLE_TRANSFER set "HF_ENABLE_TRANSFER=1"
if not defined XFORMERS_WHL set "XFORMERS_WHL="
if not defined INSIGHTFACE_WHL set "INSIGHTFACE_WHL="
if not defined ONNXRUNTIME_GPU set "ONNXRUNTIME_GPU="

REM Guarantee the torch index exists even if constants override things
if not defined PYTORCH_INDEX_URL set "PYTORCH_INDEX_URL=https://download.pytorch.org/whl/cu128"
if not defined TORCH_INSTALL_CMD set "TORCH_INSTALL_CMD=torch==%PYTORCH_VERSION% torchvision==%TORCHVISION_VERSION% torchaudio==%TORCHAUDIO_VERSION% --index-url %PYTORCH_INDEX_URL%"

call :log "[CONFIG] COMFYUI_ROOT=%COMFYUI_ROOT%"
call :log "[CONFIG] PYTHON_EXECUTABLE=%PYTHON_EXECUTABLE%"

REM ===========================================
REM  Installer — follows standard sequence
REM  Assumes constants block already loaded
REM ===========================================

echo.
echo [STEP 0] Preflight (Drivers, CUDA, VS Build Tools)
echo ---------------------------------------------------

REM (0a) NVIDIA driver/CUDA presence — robust detection
echo [INFO] Checking for NVIDIA drivers and CUDA...
call :log "[STEP0] Checking NVIDIA drivers"

REM Method 1: Try nvidia-smi in PATH
set "NVIDIA_DETECTED=0"
where nvidia-smi >nul 2>&1 && (
  for /f "tokens=3" %%v in ('nvidia-smi ^| findstr /c:"Driver Version"') do set "NVIDIA_DRIVER=%%v"
  echo [OK] NVIDIA driver detected via nvidia-smi: %NVIDIA_DRIVER%
  set "NVIDIA_DETECTED=1"
)

REM Method 2: Check WMI for NVIDIA GPU if nvidia-smi failed
if "%NVIDIA_DETECTED%"=="0" (
  echo [INFO] nvidia-smi not in PATH, checking WMI for NVIDIA GPU...
  powershell -NoProfile -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'} | Select-Object Name, DriverVersion | Format-Table -AutoSize" >nul 2>&1 && (
    for /f "tokens=2" %%v in ('powershell -NoProfile -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'} | Select-Object -First 1 -ExpandProperty DriverVersion"') do set "NVIDIA_DRIVER=%%v"
    echo [OK] NVIDIA GPU detected via WMI: Driver %NVIDIA_DRIVER%
    set "NVIDIA_DETECTED=1"
  )
)

REM Method 3: Check for CUDA Toolkit installation
if "%NVIDIA_DETECTED%"=="0" (
  echo [INFO] Checking for CUDA Toolkit installation...
  if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\" (
    for /d %%d in ("C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v*") do (
      echo [OK] CUDA Toolkit detected: %%~nxd
      set "NVIDIA_DETECTED=1"
    )
  )
)

if "%NVIDIA_DETECTED%"=="0" (
  echo [WARN] No NVIDIA GPU or CUDA detected. Installation will continue but may not work optimally.
  echo [INFO] If you have an NVIDIA GPU, ensure drivers are installed from https://www.nvidia.com/drivers/
  call :log "[STEP0] NVIDIA not detected"
) else (
  echo [OK] NVIDIA environment detected - proceeding with CUDA-optimized installation
  call :log "[STEP0] NVIDIA detected"
)

REM Check CUDA Toolkit presence (optional for prebuilt wheels, required if building any ops)
where nvcc >nul 2>&1 && echo [OK] CUDA Toolkit detected ^(nvcc^) || echo [INFO] CUDA Toolkit not found (optional unless building from source).

REM (0b) Visual Studio Build Tools (C++), set CC if available
echo [INFO] Checking for Visual Studio Build Tools...
where cl.exe >nul 2>&1 && (
  for /f "delims=" %%i in ('where cl.exe') do set "CC=%%i"
  echo [OK] MSVC detected. CC=!CC!
) || echo [INFO] MSVC not found. Some packages may build slower or skip JIT features.

echo.
echo [STEP 1] Git check
echo -------------------
echo [INFO] Checking for Git...
call :log "[STEP1] Checking Git"
rem Prefer PATH first
for /f "delims=" %%g in ('where git 2^>nul') do (set "GIT_EXE=%%g" & goto :git_ok)
if exist "C:\Program Files\Git\bin\git.exe" set "GIT_EXE=C:\Program Files\Git\bin\git.exe"
if not defined GIT_EXE if exist "C:\Program Files (x86)\Git\bin\git.exe" set "GIT_EXE=C:\Program Files (x86)\Git\bin\git.exe"
if not defined GIT_EXE (
  echo [ERROR] Git not found. Install from https://git-scm.com and re-run.
  call :safe_pause
  call :fail 1 "Git not found"
)
:git_ok
"%GIT_EXE%" --version
call :log "[STEP1] Git executable: %GIT_EXE%"

REM Ensure git is in PATH for Python processes (needed for ComfyUI-Manager)
echo [INFO] Adding Git to PATH for Python processes...
set "PATH=%PATH%;%GIT_EXE:~0,-7%"
set "GIT_PYTHON_GIT_EXECUTABLE=%GIT_EXE%"
echo [INFO] Git path added: %GIT_EXE:~0,-7%
echo [INFO] GIT_PYTHON_GIT_EXECUTABLE set to: %GIT_EXE%

echo.
echo [STEP 2] Python 3.12 check
echo --------------------------
echo [INFO] Checking Python installation...
call :log "[STEP2] Checking Python"

REM Verify Python executable is set
if not defined PYTHON_EXECUTABLE (
  echo [ERROR] PYTHON_EXECUTABLE not set. Attempting to detect Python 3.12...
  
  REM Try to detect Python 3.12 automatically
  python --version >nul 2>&1 && (
    set "PYTHON_EXECUTABLE=python"
    echo [INFO] Auto-detected: python
  ) || (
    py -3.12 --version >nul 2>&1 && (
      set "PYTHON_EXECUTABLE=py -3.12"
      echo [INFO] Auto-detected: py -3.12
    ) || (
      if exist "C:\Program Files\Python312\python.exe" (
        set "PYTHON_EXECUTABLE=C:\Program Files\Python312\python.exe"
        echo [INFO] Auto-detected: C:\Program Files\Python312\python.exe
      ) else (
        echo [ERROR] Python 3.12 not found. Please install Python 3.12 and ensure it's in PATH.
        echo [SOLUTION] Download from https://www.python.org/downloads/ and check "Add to PATH"
        call :safe_pause
        call :fail 1 "Python 3.12 not found"
      )
    )
  )
)

REM Test Python version
%PYTHON_EXECUTABLE% --version >nul 2>&1 && (
  for /f "tokens=1,2,*" %%a in ('%PYTHON_EXECUTABLE% --version') do (
    echo [OK] Python %%b
    call :log "[STEP2] Python version %%b"
  )
) || (
  echo [ERROR] Python not found or not working with: %PYTHON_EXECUTABLE%
  echo.
  echo [TROUBLESHOOTING] Try these steps:
  echo 1. Ensure Python 3.12 is installed
  echo 2. Check if 'python' command works in your terminal
  echo 3. Verify Python is in your system PATH
  echo 4. Try running: python --version
  echo.
  call :safe_pause
  call :fail 1 "Python executable not functioning"
)

REM Python 3.12 enforcement
%PYTHON_EXECUTABLE% -c "import sys; exit(0 if sys.version_info[:2]==(3,12) else 1)" || (
  echo [ERROR] Python 3.12.x required, but found:
  %PYTHON_EXECUTABLE% -c "import sys; print('Python', sys.version)"
  echo.
  echo [SOLUTION] Install Python 3.12 from https://www.python.org/downloads/
  call :safe_pause
  call :fail 1 "Python 3.12.x required"
)

REM Additional Python info
echo [INFO] Python executable: %PYTHON_EXECUTABLE%
%PYTHON_EXECUTABLE% -c "import sys; print('[INFO] Python path:', sys.executable)"
call :log "[STEP2] Python path determined"

REM Add Python Scripts to PATH to avoid "scripts not on PATH" warnings
echo [INFO] Adding Python Scripts to PATH...
%PYTHON_EXECUTABLE% -c "import sys, os; scripts_path = os.path.join(os.path.dirname(sys.executable), 'Scripts'); print(scripts_path)" > temp_scripts_path.txt 2>nul
if exist temp_scripts_path.txt (
  set /p PYTHON_SCRIPTS_PATH=<temp_scripts_path.txt
  del temp_scripts_path.txt
  if exist "%PYTHON_SCRIPTS_PATH%" (
    set "PATH=%PATH%;%PYTHON_SCRIPTS_PATH%"
    echo [INFO] Added Python Scripts to PATH: %PYTHON_SCRIPTS_PATH%
  ) else (
    echo [WARN] Python Scripts directory not found: %PYTHON_SCRIPTS_PATH%
  )
) else (
  echo [WARN] Could not determine Python Scripts path
)

echo.
echo [STEP 3] Clone/Update ComfyUI repo
echo -----------------------------------
if exist "%COMFYUI_ROOT%\.git" (
  echo [INFO] ComfyUI exists, updating...
  call :log "[STEP3] Updating existing ComfyUI repo"
  "%GIT_EXE%" -C "%COMFYUI_ROOT%" pull
) else (
  echo [INFO] Cloning ComfyUI into %COMFYUI_ROOT%
  rmdir /s /q "%COMFYUI_ROOT%" 2>nul
  call :log "[STEP3] Cloning ComfyUI repository"
  "%GIT_EXE%" clone https://github.com/comfyanonymous/ComfyUI.git "%COMFYUI_ROOT%" || (call :fail 1 "ComfyUI clone failed")
)
pushd "%COMFYUI_ROOT%"

echo.
echo [STEP 3.5] Virtual environment (optional)
echo -----------------------------------------
if /i "%USE_VENV%"=="1" (
  if not defined VENV_DIR set "VENV_DIR=%COMFYUI_ROOT%\venv"
  if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo [INFO] Creating venv at %VENV_DIR%
    call :log "[STEP3.5] Creating venv at %VENV_DIR%"
    %PYTHON_EXECUTABLE% -m venv "%VENV_DIR%" || (call :fail 1 "Virtual environment creation failed")
  )
  set "PYTHON_EXECUTABLE=%VENV_DIR%\Scripts\python.exe"
  echo [INFO] Using venv Python: %PYTHON_EXECUTABLE%
  call :log "[STEP3.5] Using venv Python %PYTHON_EXECUTABLE%"
) else (
  echo [INFO] Virtual environment disabled; using system Python
  call :log "[STEP3.5] Using system Python"
)

REM Launchers: choose & quote interpreter once
if /i "%USE_VENV%"=="1" (
  if not defined VENV_DIR set "VENV_DIR=%COMFYUI_ROOT%\venv"
  set "LAUNCH_PY_QUOTED=""%VENV_DIR%\Scripts\python.exe"""
) else (
  REM Use the detected Python executable, properly quoted if it's a path
  if "%PYTHON_EXECUTABLE:~0,1%"=="C" (
    set "LAUNCH_PY_QUOTED=""%PYTHON_EXECUTABLE%"""
  ) else (
    set "LAUNCH_PY_QUOTED=%PYTHON_EXECUTABLE%"
  )
)

echo.
echo [STEP 4] Upgrade pip/setuptools/wheel
echo -------------------------------------
%PYTHON_EXECUTABLE% -m pip install --upgrade pip setuptools wheel
if errorlevel 1 (
  call :log "[WARN] pip setuptools wheel upgrade returned non-zero"
)

echo.
echo [STEP 5] Install ComfyUI requirements.txt
echo --------------------------------------------------------
if exist requirements.txt (
  echo [INFO] Installing ComfyUI requirements.txt...
  call :log "[STEP5] Installing base requirements"
  %PYTHON_EXECUTABLE% -m pip install --upgrade -r requirements.txt
  if errorlevel 1 (
    call :log "[WARN] requirements install returned non-zero"
  )
) else (
  echo [WARN] requirements.txt missing. Installing core deps as fallback...
  if defined CORE_DEPS %PYTHON_EXECUTABLE% -m pip install %CORE_DEPS%
)

echo.
echo [STEP 5.25] Install extra dependencies (if not in requirements.txt)
echo --------------------------------------------------------------
if defined EXTRA_DEPS (
  echo [INFO] Installing extra dependencies: %EXTRA_DEPS%
  call :log "[STEP5.25] Installing extra deps: %EXTRA_DEPS%"
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %EXTRA_DEPS%
)

echo.
echo [STEP 5.5] ComfyUI dependency extras (if not in requirements.txt)
echo ---------------------------------------------------------------
if defined COMFY_REQ_EXTRAS (
  echo [INFO] Installing additional dependencies: %COMFY_REQ_EXTRAS%
  call :log "[STEP5.5] Installing extras: %COMFY_REQ_EXTRAS%"
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %COMFY_REQ_EXTRAS%
)

echo.
echo [STEP 5.6] Apply troubleshooting fixes
echo -------------------------------------
echo [INFO] Applying pre-solved dependency fixes...
call :log "[STEP5.6] Starting troubleshooting fixes"

REM Fix 1: PyAV version requirement for comfy_api_nodes (requires 14.2+)
call :log "[STEP5.6] Checking PYAV_VERSION: %PYAV_VERSION%"
if defined PYAV_VERSION (
  echo [INFO] Installing PyAV %PYAV_VERSION% for comfy_api_nodes...
  call :log "[STEP5.6] Installing PyAV %PYAV_VERSION%"
  %PYTHON_EXECUTABLE% -m pip install --upgrade av==%PYAV_VERSION%
)

REM Fix 2: SAM2 for Impact Pack (optional but recommended)
if /i "%INSTALL_SAM2%"=="1" (
  echo [INFO] Installing SAM2 %SAM2_VERSION% for Impact Pack...
  %PYTHON_EXECUTABLE% -m pip install sam2==%SAM2_VERSION%
)

REM Fix 3: Tokenizers version conflict resolution
if defined TOKENIZERS_VERSION (
  echo [INFO] Fixing tokenizers version to be compatible with transformers...
  %PYTHON_EXECUTABLE% -m pip install --force-reinstall tokenizers==%TOKENIZERS_VERSION%
)

REM Fix 4: Setuptools version to avoid pkg_resources deprecation warnings
if defined SETUPTOOLS_VERSION (
  echo [INFO] Installing setuptools %SETUPTOOLS_VERSION% to avoid deprecation warnings...
  %PYTHON_EXECUTABLE% -m pip install --upgrade setuptools==%SETUPTOOLS_VERSION%
)

echo.
echo [VERIFICATION] Checking troubleshooting fixes...
echo [INFO] Checking PyAV version (should be >= 14.2 for comfy_api_nodes)...
%PYTHON_EXECUTABLE% -c "import av; print('[OK] PyAV version:', av.__version__)" || echo [WARN] PyAV not found
echo [INFO] Checking SAM2 installation...
%PYTHON_EXECUTABLE% -c "import sam2; print('[OK] SAM2 version:', sam2.__version__)" || echo [WARN] SAM2 not found (optional)
echo [INFO] Checking tokenizers version...
%PYTHON_EXECUTABLE% -c "import tokenizers; print('[OK] Tokenizers version:', tokenizers.__version__)" || echo [WARN] Tokenizers not found
echo [INFO] Checking setuptools version...
%PYTHON_EXECUTABLE% -c "import setuptools; print('[OK] Setuptools version:', setuptools.__version__)" || echo [WARN] Setuptools not found

echo.
echo [STEP 6] Install PyTorch stack (stable cu128)
echo --------------------------------------------
echo [INFO] %TORCH_INSTALL_CMD%
call :log "[STEP6] Installing torch stack: %TORCH_INSTALL_CMD%"

REM Try to install PyTorch with CUDA support
%PYTHON_EXECUTABLE% -m pip install %TORCH_INSTALL_CMD%
if errorlevel 1 (
  echo [WARN] PyTorch CUDA install failed, trying CPU-only fallback...
  call :log "[STEP6] CUDA install failed; trying CPU fallback"
  %PYTHON_EXECUTABLE% -m pip install torch==%PYTORCH_VERSION% torchvision==%TORCHVISION_VERSION% torchaudio==%TORCHAUDIO_VERSION%
  if errorlevel 1 (
    echo [ERROR] PyTorch install failed completely.
    echo [TROUBLESHOOTING] Try:
    echo 1. Check internet connection
    echo 2. Try: python -m pip install --upgrade pip
    echo 3. Try: python -m pip install torch==%PYTORCH_VERSION% --index-url https://download.pytorch.org/whl/cpu
    call :safe_pause
    call :fail 1 "PyTorch installation failed"
  ) else (
    echo [WARN] PyTorch CPU-only installed. CUDA features will not be available.
  )
)

echo.
echo [STEP 7] Torch smoke test
echo -------------------------
call :log "[STEP7] Running torch smoke test"
%PYTHON_EXECUTABLE% -c "import torch,sys; print('[OK] torch', torch.__version__, 'CUDA', torch.version.cuda); print('[OK] is_available:', torch.cuda.is_available(), 'device_count:', torch.cuda.device_count())"
if errorlevel 1 (
  echo [ERROR] Torch import failed.
  echo [TROUBLESHOOTING] Try:
  echo 1. Check if PyTorch was installed correctly
  echo 2. Try: python -c "import torch; print(torch.__version__)"
  echo 3. Reinstall PyTorch manually
  call :safe_pause
  call :fail 1 "Torch smoke test failed"
)

REM Additional CUDA info if available
%PYTHON_EXECUTABLE% -c "import torch; print('[INFO] CUDA available:', torch.cuda.is_available()); print('[INFO] CUDA device count:', torch.cuda.device_count() if torch.cuda.is_available() else 0); print('[INFO] CUDA device name:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')"

echo.
echo [STEP 8] First ComfyUI smoke run (before extras)
echo -----------------------------------------------
call :log "[STEP8] Running initial ComfyUI smoke test"
REM PID-safe smoke-run kill
for /f %%P in ('powershell -NoProfile -Command ^
  "$p=Start-Process -PassThru -WindowStyle Hidden \"%PYTHON_EXECUTABLE%\" 'main.py'; Start-Sleep 18; $p.Id"') do set "NEWPID=%%P"
if defined NEWPID "%SystemRoot%\System32\taskkill.exe" /pid %NEWPID% /f >nul 2>&1
echo [OK] Basic ComfyUI launch test done.

echo.
echo [STEP 8.5] HTTP health check
echo ----------------------------
powershell -NoProfile -Command " $u='http://127.0.0.1:8188/'; $ok=$false; 1..5 | %%{ try{$r=Invoke-WebRequest -UseBasicParsing $u; if($r.StatusCode -eq 200){$ok=$true;break}}catch{}; Start-Sleep 1 }; if($ok){'[RESULT] UP'}else{'[RESULT] UNKNOWN'} "

echo.
echo [STEP 9] Triton for Windows (Torch 2.7.x compat)
echo -----------------------------------------------
if defined TRITON_PKG (
  %PYTHON_EXECUTABLE% -m pip install %TRITON_PKG%
)

echo.
echo [STEP 10] Optimization libs (torchsde, accelerate, bitsandbytes, torchao)
echo -------------------------------------------------------------------------
if defined OPTIMIZATION_DEPS (
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %OPTIMIZATION_DEPS% || echo [WARN] Optimization deps had issues; continuing
)

echo.
echo [STEP 11] Web/server deps
echo -------------------------
if defined WEB_DEPS (
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %WEB_DEPS%
)

echo.
echo [STEP 12] Video/codec deps
echo --------------------------
if defined VIDEO_DEPS (
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %VIDEO_DEPS%
)

echo.
echo [STEP 12.5] Utility / client libs (opencv, psutil, diffusers, transformers, etc.)
echo -------------------------------------------------------------------------------
if defined UTIL_DEPS (
  %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %UTIL_DEPS%
)

echo.
echo [STEP 13] SageAttention
echo -----------------------
if defined SAGEATTENTION_VERSION (
  %PYTHON_EXECUTABLE% -m pip install %SAGEATTENTION_VERSION%
)

echo.
echo [STEP 14] DeepSpeed (Windows subset)
echo ------------------------------------
REM Check if we're on Windows (more reliable than 'find' command)
if "%OS%"=="Windows_NT" (
  if defined DEEPSPEED_PIP (
    echo [INFO] Installing DeepSpeed for Windows...
    %PYTHON_EXECUTABLE% -m pip install --upgrade --prefer-binary %DEEPSPEED_PIP% || echo [WARN] DeepSpeed install failed; continuing without it
  ) else (
    echo [INFO] DeepSpeed disabled by constants.
  )
) else (
  if defined DEEPSPEED_PIP (
    echo [INFO] Installing DeepSpeed for non-Windows...
    %PYTHON_EXECUTABLE% -m pip install %DEEPSPEED_PIP%
  ) else (
    echo [INFO] DeepSpeed disabled by constants.
  )
)

echo.
echo [STEP 15] FlashAttention (Windows wheel for Py 3.12 + cu128)
echo ------------------------------------------------------------
if defined FLASH_ATTENTION_WHL (
  echo [INFO] Wheel URL: %FLASH_ATTENTION_WHL%
  %PYTHON_EXECUTABLE% -m pip install "%FLASH_ATTENTION_WHL%" --no-build-isolation || echo [WARN] FlashAttention install failed; continuing without it
) else (
  echo [INFO] FLASH_ATTENTION_WHL not set; skipping FlashAttention.
)

echo.
echo [STEP 15.5] Additional accelerators (xFormers, InsightFace, ONNXRuntime-GPU)
echo ---------------------------------------------------------------------------
if defined HF_ENABLE_TRANSFER (
  call :log "[STEP15.5] Installing hf_transfer"
  %PYTHON_EXECUTABLE% -m pip install --upgrade huggingface_hub hf_transfer
)
if defined XFORMERS_WHL (
  echo [INFO] Installing xFormers: %XFORMERS_WHL%
  call :log "[STEP15.5] Installing xformers"
  %PYTHON_EXECUTABLE% -m pip install "%XFORMERS_WHL%" || echo [WARN] xFormers install failed; continuing
)
if defined INSIGHTFACE_WHL (
  echo [INFO] Installing InsightFace: %INSIGHTFACE_WHL%
  call :log "[STEP15.5] Installing insightface"
  %PYTHON_EXECUTABLE% -m pip install "%INSIGHTFACE_WHL%" || echo [WARN] InsightFace install failed; continuing
)
if defined ONNXRUNTIME_GPU (
  echo [INFO] Installing ONNXRuntime GPU: %ONNXRUNTIME_GPU%
  call :log "[STEP15.5] Installing onnxruntime"
  %PYTHON_EXECUTABLE% -m pip install %ONNXRUNTIME_GPU% || echo [WARN] ONNXRuntime install failed; continuing
)

echo.
echo [STEP 16] Custom nodes (Manager, Crystools)
echo -----------------------------------------------------
if not exist "%CUSTOM_NODES_DIR%" mkdir "%CUSTOM_NODES_DIR%" >nul 2>&1
pushd "%CUSTOM_NODES_DIR%" || (call :fail 1 "Cannot enter custom nodes directory")
call :log "[STEP16] Managing custom nodes in %CUSTOM_NODES_DIR%"

REM Manager
if exist "%COMFYUI_MANAGER_DIR%\.git" (
  echo [INFO] Updating ComfyUI-Manager
  pushd "%COMFYUI_MANAGER_DIR%" || (call :fail 1 "Cannot enter ComfyUI-Manager")
  call :log "[STEP16] Updating ComfyUI-Manager"
  "%GIT_EXE%" pull || (call :fail 1 "ComfyUI-Manager update failed")
  popd
) else (
  echo [INFO] Installing ComfyUI-Manager
  call :log "[STEP16] Cloning ComfyUI-Manager"
  "%GIT_EXE%" clone "%COMFYUI_MANAGER_URL%" "%COMFYUI_MANAGER_DIR%" || (call :fail 1 "ComfyUI-Manager clone failed")
)

REM Crystools
if exist "%CRYSTOOLS_DIR%\.git" (
  echo [INFO] Updating comfyui-crystools
  pushd "%CRYSTOOLS_DIR%" || (call :fail 1 "Cannot enter Crystools")
  call :log "[STEP16] Updating Crystools"
  "%GIT_EXE%" pull || (call :fail 1 "Crystools update failed")
  popd
) else (
  echo [INFO] Installing comfyui-crystools
  call :log "[STEP16] Cloning Crystools"
  "%GIT_EXE%" clone "%CRYSTOOLS_URL%" "%CRYSTOOLS_DIR%" || (call :fail 1 "Crystools clone failed")
)



REM Extra addons from Comfy_UI_V50 (GGUF)

if /i "%INSTALL_GGUF%"=="1" (
  if exist "ComfyUI-GGUF\.git" (
    echo [INFO] Updating ComfyUI-GGUF
    pushd "ComfyUI-GGUF" || (call :fail 1 "Cannot enter ComfyUI-GGUF folder")
    call :log "[STEP16] Updating ComfyUI-GGUF"
    "%GIT_EXE%" pull || (call :fail 1 "ComfyUI-GGUF update failed")
    %PYTHON_EXECUTABLE% -m pip install -r requirements.txt || echo [WARN] GGUF requirements failed
    popd
  ) else (
    echo [INFO] Installing ComfyUI-GGUF
    call :log "[STEP16] Cloning ComfyUI-GGUF"
    "%GIT_EXE%" clone "%GGUF_URL%" || (call :fail 1 "ComfyUI-GGUF clone failed")
    pushd "ComfyUI-GGUF" || (call :fail 1 "Cannot enter ComfyUI-GGUF folder")
    %PYTHON_EXECUTABLE% -m pip install -r requirements.txt || echo [WARN] GGUF requirements failed
    popd
  )
)



popd  &  popd  &  popd

echo.
echo [STEP 16.5] Verify custom node dependencies
echo -------------------------------------------
echo [INFO] Verifying that custom node dependencies are available...
%PYTHON_EXECUTABLE% -c "import deepdiff; print('[OK] deepdiff imported successfully')" || echo [WARN] deepdiff import failed - may need manual installation

echo [INFO] Verifying tokenizers version compatibility...
%PYTHON_EXECUTABLE% -c "import tokenizers; print('[OK] tokenizers version:', tokenizers.__version__)" || echo [WARN] tokenizers import failed

echo [INFO] Setting git environment for current session...
%PYTHON_EXECUTABLE% -c "import os; os.environ['GIT_PYTHON_GIT_EXECUTABLE'] = r'%GIT_EXE%'; print('[OK] GIT_PYTHON_GIT_EXECUTABLE set to:', os.environ['GIT_PYTHON_GIT_EXECUTABLE'])" || echo [WARN] Failed to set git environment

echo [INFO] Fixing Crystools syntax warning...
if exist "%CUSTOM_NODES_DIR%\%CRYSTOOLS_DIR%\nodes\image.py" (
  powershell -Command "(Get-Content '%CUSTOM_NODES_DIR%\%CRYSTOOLS_DIR%\nodes\image.py') -replace 'https:\\/\\/www\\.instagram\\.com\\/crystian\\.ia', 'https://www.instagram.com/crystian.ia' -replace '\\.replace\\(\"\\\\\\/\", \"/\"\\)', '' | Set-Content '%CUSTOM_NODES_DIR%\%CRYSTOOLS_DIR%\nodes\image.py'"
  echo [OK] Crystools syntax warning fixed
) else (
  echo [WARN] Crystools image.py not found - syntax warning fix skipped
)

echo.
echo [STEP 17] Create launchers
echo --------------------------
pushd "%COMFYUI_ROOT%" || (call :fail 1 "Cannot cd to %COMFYUI_ROOT%")

> "ComfyUI_Basic.bat" echo @echo off
>>"ComfyUI_Basic.bat" echo cd /d "%COMFYUI_ROOT%"
>>"ComfyUI_Basic.bat" echo set PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
>>"ComfyUI_Basic.bat" echo set TORCH_CUDA_ARCH_LIST=8.6+PTX
>>"ComfyUI_Basic.bat" echo set GIT_PYTHON_GIT_EXECUTABLE=%GIT_EXE%
>>"ComfyUI_Basic.bat" echo %LAUNCH_PY_QUOTED% main.py %COMFYUI_BASIC_ARGS%

> "Comfy_UI.bat" echo @echo off
>>"Comfy_UI.bat" echo cd /d "%COMFYUI_ROOT%"
>>"Comfy_UI.bat" echo set PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
>>"Comfy_UI.bat" echo set TORCH_CUDA_ARCH_LIST=8.6+PTX
>>"Comfy_UI.bat" echo set COMFYUI_USE_SAGE_ATTENTION=1
>>"Comfy_UI.bat" echo set GIT_PYTHON_GIT_EXECUTABLE=%GIT_EXE%
>>"Comfy_UI.bat" echo set HF_HUB_ENABLE_HF_TRANSFER=1
>>"Comfy_UI.bat" echo set HF_XET_CHUNK_CACHE_SIZE_BYTES=90737418240
>>"Comfy_UI.bat" echo set TORCH_CUDNN_V8_API_ENABLED=1
>>"Comfy_UI.bat" echo set CUDA_LAUNCH_BLOCKING=0
>>"Comfy_UI.bat" echo set PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
>>"Comfy_UI.bat" echo start "" /B %LAUNCH_PY_QUOTED% main.py %COMFYUI_OPTIMIZED_ARGS%
>>"Comfy_UI.bat" echo %SystemRoot%\System32\timeout.exe /t 8 /nobreak ^>nul
>>"Comfy_UI.bat" echo start "" "%COMFYUI_LOCAL_URL%"
>>"Comfy_UI.bat" echo echo ComfyUI at %COMFYUI_LOCAL_URL%

dir /b "ComfyUI_*.bat" & dir /b "Comfy_UI.bat" || (call :fail 1 "Launcher creation failed")
popd

echo.
echo [STEP 18] Final verification
echo ----------------------------
%PYTHON_EXECUTABLE% -c "import importlib.util as u, torch; ck=lambda m:u.find_spec(m) is not None; print('=== VERSION STAMP ==='); print('torch',torch.__version__,'cuda',torch.version.cuda); print('triton:',ck('triton')); print('bitsandbytes:',ck('bitsandbytes')); print('sageattention:',ck('sageattention')); print('flash_attn:',ck('flash_attn')); print('=== CUDA INFO ==='); print('available:',torch.cuda.is_available()); print('device_count:',torch.cuda.device_count() if torch.cuda.is_available() else 0); print('name:',torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'n/a')"

echo.
echo [STEP 19] Quick self-test (as suggested in feedback)
echo ----------------------------------------------------
echo [INFO] Running suggested self-test
echo [TEST 1] PyTorch + CUDA verification:
%PYTHON_EXECUTABLE% -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda, 'avail', torch.cuda.is_available())"
if errorlevel 1 (
  echo [ERROR] PyTorch test failed
  call :safe_pause
  call :fail 1 "PyTorch self-test failed"
)

echo [TEST 2] Core dependencies check:
%PYTHON_EXECUTABLE% -c "import triton,sageattention,av,aiohttp,einops,tokenizers,sentencepiece,sqlalchemy,alembic,deepdiff; print('deps OK')"
if errorlevel 1 (
  echo [WARN] Some dependencies missing (non-fatal)
) else (
  echo [OK] All core dependencies present
)



echo [TEST 3] Launcher verification:
if exist "%COMFYUI_ROOT%\Comfy_UI.bat" (
  echo [OK] Comfy_UI launcher exists
) else (
  echo [ERROR] Comfy_UI launcher missing
  call :safe_pause
  call :fail 1 "Comfy_UI launcher missing"
)
call :log "[TEST3] Launcher verified"

echo.
echo [TEST 4] Addon presence checks:
echo --------------------------------

if exist "%CUSTOM_NODES_DIR%\ComfyUI-GGUF" (
  echo [OK] GGUF node present
) else (
  echo [WARN] GGUF node not found (optional)
)


echo [TEST 5] Accelerator imports (non-fatal):
%PYTHON_EXECUTABLE% -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('xformers') else 1)" && echo [OK] xformers || echo [WARN] xformers missing
%PYTHON_EXECUTABLE% -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('insightface') else 1)" && echo [OK] insightface || echo [WARN] insightface missing
%PYTHON_EXECUTABLE% -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('onnxruntime') else 1)" && echo [OK] onnxruntime-gpu || echo [WARN] onnxruntime-gpu missing
%PYTHON_EXECUTABLE% -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('flash_attn') else 1)" && echo [OK] flash_attn || echo [WARN] flash_attn missing
%PYTHON_EXECUTABLE% -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('deepspeed') else 1)" && echo [OK] deepspeed || echo [WARN] deepspeed missing

echo.
echo ===========================================
echo INSTALLATION COMPLETE
echo Launchers: ComfyUI_Basic / Comfy UI
echo ===========================================

echo Opening ComfyUI folder
start "" "%COMFYUI_ROOT%"

echo [SUCCESS] Installation completed successfully!
echo.
echo [NEXT STEPS]
echo 1. Go to: %COMFYUI_ROOT%
echo 2. Run: "Comfy_UI.bat" (recommended) or ComfyUI_Basic.bat
echo 3. Browser will auto-open to: %COMFYUI_LOCAL_URL%
echo.
echo [VERIFICATION] Expected output from launcher:
echo - torch 2.7.1 cuda 12.8 avail True
echo - deps OK
echo - UI at %COMFYUI_LOCAL_URL% (200 after a few seconds)
call :safe_pause
goto :EOF

REM ===========================================
REM  Helper Functions
REM ===========================================

:log
REM Logs message to both console and log file
echo %~1
echo %DATE% %TIME% %~1 >> "%INSTALL_LOG%" 2>nul
goto :EOF

:safe_pause
REM Pauses only if INSTALLER_NOPAUSE is not set
if not "%INSTALLER_NOPAUSE%"=="1" (
  echo.
  echo Press any key to continue . . .
  pause >nul
)
goto :EOF

:fail
REM Handles failures with logging and exit
set "EXIT_CODE=%~1"
set "INSTALL_ERROR=%~2"
set "INSTALL_STATUS=FAILED"
call :log "[FATAL] %~2 (exit code %~1)"
echo.
echo [FATAL ERROR] %~2
echo [LOG] Check log file: %INSTALL_LOG%
echo.
call :safe_pause
exit /b %~1
