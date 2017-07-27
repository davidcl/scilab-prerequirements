@echo off

setlocal

:ArchStep
::get OS arch
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set ARCH=32
) else (
    set ARCH=64
)

:ParseStep
:: Parse the incoming arguments
if /i "%1"==""     goto RegStep
if /i "%1"=="64"   (set SCILAB_TARGET=64) & shift & goto ParseStep
if /i "%1"=="32"   (set SCILAB_TARGET=32) & shift & goto ParseStep
goto Error_Args

:RegStep

if "%SCILAB_TARGET%"=="" (
    goto Error_Args
)

:: set registry key
if %ARCH% EQU %SCILAB_TARGET% (
    rem 32 on 32 or 64 on 64
    set KEY_ROOT=HKLM\SOFTWARE\JavaSoft\Java Development Kit
) else (
    if %ARCH EQU 32 (
        goto Error
    ) else (
        rem OS 64 and Scilab 32
        set KEY_ROOT=HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Development Kit
    )
)

:: Get the Java Version
set KEY="%KEY_ROOT%"
set VALUE=CurrentVersion
reg query %KEY% /v %VALUE% >nul 2>&1 || (
    goto Error
)
set JDK_VERSION=
for /f "tokens=2,*" %%a in ('reg query %KEY% /v %VALUE% ^| findstr %VALUE%') do (
    set JDK_VERSION=%%b
)

:: Get the JavaHome
set KEY="%KEY_ROOT%\%JDK_VERSION%"
set VALUE=JavaHome
reg query %KEY% /v %VALUE% >nul 2>&1 || (
    goto Error
)

for /f "tokens=2,*" %%a in ('reg query %KEY% /v %VALUE% ^| findstr %VALUE%') do (
    set SCILAB_JDK=%%b
)

:: update local and global SCILAB_JDK env var ( user variables )
endlocal& ^
set SCILAB_JDK%SCILAB_TARGET%=%SCILAB_JDK%& ^
setx SCILAB_JDK%SCILAB_TARGET% "%SCILAB_JDK%" >nul 2>&1
exit /B 0

:Error
echo.
echo JDK not set
exit /B 1

:Error_Args
echo Syntax:
echo    %~nx0 ^<arch^>
echo.
echo    ^<arch^> must be one of the following
echo        32  : Setup for Scilab 32 bits architecture
echo        64  : Setup for Scilab 64 bits architecture
exit /B 1
