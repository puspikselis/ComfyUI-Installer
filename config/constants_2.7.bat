@echo off

:: ===========================================
:: ComfyUI Setup Constants
:: ===========================================

:: Core Python - Improved detection
set "PYTHON_VERSION=3.12"
:: Try multiple Python detection methods
set "PYTHON_EXECUTABLE="

:: Method 1: Try 'python' command first (most reliable)
python --version >nul 2>&1 && (
  set "PYTHON_EXECUTABLE=python"
  echo [INFO] Using 'python' command
) || (
  :: Method 2: Try 'py' launcher
  py -3.12 --version >nul 2>&1 && (
    set "PYTHON_EXECUTABLE=py -3.12"
    echo [INFO] Using 'py -3.12' launcher
  ) || (
    :: Method 3: Try direct path to Python 3.12
    if exist "C:\Program Files\Python312\python.exe" (
      set "PYTHON_EXECUTABLE=C:\Program Files\Python312\python.exe"
      echo [INFO] Using direct path to Python 3.12
    ) else if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\python.exe" (
      set "PYTHON_EXECUTABLE=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\python.exe"
      echo [INFO] Using user-installed Python 3.12
    ) else (
      echo [ERROR] Python 3.12 not found. Please install Python 3.12 and ensure it's in PATH.
      exit /b 1
    )
  )
)

:: Add Python Scripts to PATH to avoid "scripts not on PATH" warnings (tqdm, transformers, uvicorn, etc.)
:: Try to detect Python Scripts directory automatically
%PYTHON_EXECUTABLE% -c "import sys; import os; print(os.path.join(os.path.dirname(sys.executable), 'Scripts'))" > temp_scripts_path.txt 2>nul
if exist temp_scripts_path.txt (
  set /p PYTHON_SCRIPTS_PATH=<temp_scripts_path.txt
  del temp_scripts_path.txt
  if exist "%PYTHON_SCRIPTS_PATH%" (
    set "PATH=%PATH%;%PYTHON_SCRIPTS_PATH%"
    echo [INFO] Added Python Scripts to PATH: %PYTHON_SCRIPTS_PATH%
  )
) else (
  :: Fallback to common locations
  set "PATH=%PATH%;C:\Program Files\Python312\Scripts"
  set "PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\Scripts"
)

:: Virtual Environment (optional - set to 1 to enable, 0 to disable)
set "USE_VENV=0"
set "VENV_DIR=%USERPROFILE%\Documents\ComfyUI\venv"

:: Paths
set "COMFYUI_ROOT=%USERPROFILE%\Documents\ComfyUI"
set "COMFYUI_REPO=%COMFYUI_ROOT%"
set "CUSTOM_NODES_DIR=%COMFYUI_ROOT%\custom_nodes"

:: ===== PyTorch (official cu128 wheels) =====
set "PYTORCH_VERSION=2.7.1"
set "TORCHVISION_VERSION=0.22.1"
set "TORCHAUDIO_VERSION=2.7.1"
set "PYTORCH_INDEX_URL=https://download.pytorch.org/whl/cu128"
set "TORCH_INSTALL_CMD=torch==%PYTORCH_VERSION% torchvision==%TORCHVISION_VERSION% torchaudio==%TORCHAUDIO_VERSION% --index-url %PYTORCH_INDEX_URL%"

:: Core deps (let pip resolve unless you hit an issue)
set "TORCHSDE_VERSION="
set "SAFETENSORS_VERSION="
set "NUMPY_VERSION="
set "PILLOW_VERSION="
set "SCIPY_VERSION="

:: ===== Performance / kernels =====
:: FlashAttention on Windows: use prebuilt wheel for Py 3.12 + cu128 + torch 2.7.x
set "FLASH_ATTENTION_WHL=https://huggingface.co/MonsterMMORPG/SECourses_Premium_Flash_Attention/resolve/main/flash_attn-2.7.4.post1-cp312-cp312-win_amd64.whl"
set "SKIP_FLASH_ATTN=0"
:: DeepSpeed via PyPI (Windows subset) - pin to 0.16.5 for Py 3.12 wheels
set "DEEPSPEED_PIP=https://files.pythonhosted.org/packages/d4/59/fd251661b78b049eed7ee46f0d8d51c69ae7fbb710716a1ebcc796a6b0fd/deepspeed-0.16.4-cp312-cp312-win_amd64.whl"
:: Triton for Windows (Torch 2.7.x compatible)
set "TRITON_PKG=triton-windows==3.3.0.post19"
:: SageAttention (v1) via PyPI
set "SAGEATTENTION_VERSION=sageattention"
:: accelerate / bnb / torchao
set "ACCELERATE_VERSION=accelerate"
set "BITSANDBYTES_VERSION="
set "TORCHAO_VERSION="

:: ===== Additional accelerators (prebuilt wheels for Py 3.12) =====
set "XFORMERS_WHL=https://huggingface.co/MonsterMMORPG/SECourses_Premium_Flash_Attention/resolve/main/xformers-0.0.30+3abeaa9e.d20250426-cp312-cp312-win_amd64.whl"
set "INSIGHTFACE_WHL=https://huggingface.co/MonsterMMORPG/SECourses_Premium_Flash_Attention/resolve/main/insightface-0.7.3-cp312-cp312-win_amd64.whl"
set "ONNXRUNTIME_GPU=onnxruntime-gpu"

:: ===== Addons toggles =====
set "INSTALL_GGUF=1"

:: ===== Addon repositories =====
set "GGUF_URL=https://github.com/city96/ComfyUI-GGUF.git"

:: ===== Enable faster HuggingFace downloads =====
set "HF_ENABLE_TRANSFER=1"

:: Custom Node deps
set "CPUINFO_PACKAGE=py-cpuinfo"
set "DIFFUSERS_VERSION="
set "TRANSFORMERS_VERSION="

:: ===== TROUBLESHOOTING FIXES - Pre-solve common issues =====
:: Fix 1: PyAV version requirement for comfy_api_nodes (requires 14.2+)
set "PYAV_VERSION=15.0.0"
:: Fix 2: SAM2 for Impact Pack (optional but recommended)
set "INSTALL_SAM2=1"
set "SAM2_VERSION=1.1.0"
:: Fix 3: Tokenizers version conflict resolution
set "TOKENIZERS_VERSION=0.21.4"
:: Fix 4: Setuptools version to avoid pkg_resources deprecation warnings
set "SETUPTOOLS_VERSION=80.0.0"

:: Utilities
set "OPENCV_PACKAGE=opencv-python"
set "PSUTIL_VERSION="
set "REQUESTS_VERSION="
set "TQDM_VERSION="
set "MATPLOTLIB_VERSION="
set "SEABORN_VERSION="

:: Web
set "AIOHTTP_VERSION="
set "WEBSOCKETS_VERSION="
set "FASTAPI_VERSION="
set "UVICORN_VERSION="

:: ComfyUI Extensions
set "COMFYUI_MANAGER_URL=https://github.com/ltdrdata/ComfyUI-Manager.git"
set "COMFYUI_MANAGER_DIR=comfyui-manager"
set "CRYSTOOLS_URL=https://github.com/crystian/comfyui-crystools.git"
set "CRYSTOOLS_DIR=comfyui-crystools"

:: Groups
set "EXTRA_DEPS=mako deepdiff piexif"
set "CORE_DEPS=pillow numpy transformers safetensors"
set "OPTIMIZATION_DEPS=torchsde accelerate"
set "WEB_DEPS=aiohttp websockets fastapi uvicorn"
set "VIDEO_DEPS=av"
set "UTIL_DEPS=opencv-python psutil requests tqdm matplotlib seaborn py-cpuinfo diffusers"

:: ComfyUI requirements.txt extras (for --no-deps compatibility)
set "COMFY_REQ_EXTRAS=einops tokenizers sentencepiece pyyaml yarl alembic SQLAlchemy"

:: Runtime env
set "PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
set "CUDA_LAUNCH_BLOCKING=0"
set "TORCH_CUDNN_V8_API_ENABLED=1"
set "COMFYUI_USE_SAGE_ATTENTION=1"
set "TORCH_CUDA_ARCH_LIST=8.6+PTX"

:: Launch args
set "COMFYUI_BASIC_ARGS=--listen 0.0.0.0 --port 8188"
set "COMFYUI_OPTIMIZED_ARGS=--listen 0.0.0.0 --port 8188 --enable-cors-header --disable-xformers --windows-standalone-build --use-sage-attention"
set "COMFYUI_CRYSTOOLS_ARGS=--listen 0.0.0.0 --port 8188 --enable-cors-header"

:: Info
set "COMFYUI_LOCAL_URL=http://127.0.0.1:8188"
set "COMFYUI_PUBLIC_URL=http://0.0.0.0:8188"
set "SCRIPT_VERSION=1.1.5"
set "LAST_UPDATED=2025-08-29"

echo [INFO] Constants loaded (Torch %PYTORCH_VERSION% cu128)
echo [INFO] Script Version: %SCRIPT_VERSION%
echo [INFO] Python: %PYTHON_VERSION%
echo [INFO] ComfyUI Root: %COMFYUI_ROOT%
echo [INFO] Troubleshooting fixes enabled: PyAV %PYAV_VERSION%, SAM2 %SAM2_VERSION%, Tokenizers %TOKENIZERS_VERSION%
