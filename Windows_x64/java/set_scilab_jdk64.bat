@echo off

:: Cache some environment variables.
set CURRENT_PATH=%~dp0
:: Set the default arguments
set TARGET_ARCH=64

:: main actions
if exist "%CURRENT_PATH%set_scilab_jdk.bat" @call "%CURRENT_PATH%set_scilab_jdk.bat" %TARGET_ARCH%
exit /B 0
