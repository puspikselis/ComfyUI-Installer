@echo off
setlocal EnableDelayedExpansion

echo Testing troubleshooting section...

REM Load constants
call "config\constants_2.7.bat"

echo PYAV_VERSION=%PYAV_VERSION%
echo INSTALL_SAM2=%INSTALL_SAM2%
echo SAM2_VERSION=%SAM2_VERSION%
echo TOKENIZERS_VERSION=%TOKENIZERS_VERSION%
echo SETUPTOOLS_VERSION=%SETUPTOOLS_VERSION%

echo Testing each fix individually...

REM Fix 1: PyAV version requirement for comfy_api_nodes (requires 14.2+)
if defined PYAV_VERSION (
  echo [INFO] Installing PyAV %PYAV_VERSION% (required for comfy_api_nodes)...
  echo python -m pip install --upgrade av==%PYAV_VERSION%
)

REM Fix 2: SAM2 for Impact Pack (optional but recommended)
if /i "%INSTALL_SAM2%"=="1" (
  echo [INFO] Installing SAM2 %SAM2_VERSION% for Impact Pack...
  echo python -m pip install sam2==%SAM2_VERSION%
)

REM Fix 3: Tokenizers version conflict resolution
if defined TOKENIZERS_VERSION (
  echo [INFO] Fixing tokenizers version to be compatible with transformers...
  echo python -m pip install --force-reinstall tokenizers==%TOKENIZERS_VERSION%
)

REM Fix 4: Setuptools version to avoid pkg_resources deprecation warnings
if defined SETUPTOOLS_VERSION (
  echo [INFO] Installing setuptools %SETUPTOOLS_VERSION% to avoid deprecation warnings...
  echo python -m pip install --upgrade setuptools==%SETUPTOOLS_VERSION%
)

echo Test completed.
pause
