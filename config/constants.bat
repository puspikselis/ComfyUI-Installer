@echo off

:: ===========================================
:: Default Constants - Points to 2.7 Full Setup
:: ===========================================

:: This file defaults to the main 2.7 full setup
:: To use a different configuration, rename this file and copy your preferred one as constants.bat

set "PROFILE=%~dp0constants_2.7.bat"
if not exist "%PROFILE%" (
  echo [ERROR] Couldn't find %PROFILE%
  echo        Make sure the constants_2.7.bat file is in the same folder.
  exit /b 1
)
call "%PROFILE%"
