@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

rem Tcl file in the same directory as this bat file
set "TCL_FILE=%SCRIPT_DIR%rebuild_project.tcl"

set "RUN_LOG=%SCRIPT_DIR%vivado_run.log"
set "RUN_JOU=%SCRIPT_DIR%vivado_run.jou"

set "USER_VIVADO_BAT=%VIVADO_BAT%"
set "VIVADO_BAT="
set "REQUIRED_VIVADO_VERSION=2022.1"

rem ============================================================
rem Vivado search order:
rem 1. Command argument:
rem    run_tcl.bat "D:\Xilinx\Vivado\2022.1\bin\vivado.bat"
rem 2. Environment variable: VIVADO_BAT or VIVADO_HOME
rem 3. Exact Vivado %REQUIRED_VIVADO_VERSION% path on C/D/E/F drives
rem 4. vivado.bat from system PATH
rem 5. Manual input when Vivado is not found
rem ============================================================

rem 1. Command argument
if not "%~1"=="" (
    if exist "%~1" (
        set "VIVADO_BAT=%~1"
    ) else (
        echo [ERROR] Vivado path from argument does not exist:
        echo         %~1
        goto :fail
    )
)

rem 2. Environment variable VIVADO_BAT
if not defined VIVADO_BAT (
    if defined USER_VIVADO_BAT (
        if exist "%USER_VIVADO_BAT%" (
            set "VIVADO_BAT=%USER_VIVADO_BAT%"
        )
    )
)

rem 2. Environment variable VIVADO_HOME
if not defined VIVADO_BAT (
    if defined VIVADO_HOME (
        if exist "%VIVADO_HOME%\bin\vivado.bat" (
            set "VIVADO_BAT=%VIVADO_HOME%\bin\vivado.bat"
        )
    )
)

rem 3. Exact Vivado version path on common drives
if not defined VIVADO_BAT (
    for %%D in (C D E F) do (
        if not defined VIVADO_BAT (
            if exist "%%D:\Xilinx\Vivado\%REQUIRED_VIVADO_VERSION%\bin\vivado.bat" (
                set "VIVADO_BAT=%%D:\Xilinx\Vivado\%REQUIRED_VIVADO_VERSION%\bin\vivado.bat"
            )
        )
    )
)

rem 4. Vivado from system PATH
if not defined VIVADO_BAT (
    for /f "delims=" %%I in ('where vivado.bat 2^>nul') do (
        if not defined VIVADO_BAT (
            set "VIVADO_BAT=%%I"
        )
    )
)

rem 5. Manual input
if not defined VIVADO_BAT (
    echo [WARN] Vivado was not found automatically.
    set /p "MANUAL_VIVADO_BAT=Please input full path to vivado.bat: "
    set "MANUAL_VIVADO_BAT=%MANUAL_VIVADO_BAT:"=%"

    if exist "%MANUAL_VIVADO_BAT%" (
        set "VIVADO_BAT=%MANUAL_VIVADO_BAT%"
    ) else (
        echo [ERROR] Input Vivado path does not exist:
        echo         %MANUAL_VIVADO_BAT%
        goto :fail
    )
)

rem Check Tcl file
if not exist "%TCL_FILE%" (
    echo [ERROR] Tcl file does not exist:
    echo         %TCL_FILE%
    goto :fail
)

cd /d "%SCRIPT_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to enter script directory:
    echo         %SCRIPT_DIR%
    goto :fail
)

echo ============================================================
echo Run Vivado Tcl
echo ============================================================
echo Vivado : %VIVADO_BAT%
echo Tcl    : %TCL_FILE%
echo Log    : %RUN_LOG%
echo Jou    : %RUN_JOU%
echo ============================================================

call "%VIVADO_BAT%" ^
    -mode batch ^
    -source "%TCL_FILE%" ^
    -log "%RUN_LOG%" ^
    -journal "%RUN_JOU%"

if errorlevel 1 (
    echo.
    echo [ERROR] Vivado Tcl run failed.
    echo         Please check log:
    echo         %RUN_LOG%
    goto :fail
)

echo.
echo [OK] Vivado Tcl run finished successfully.
goto :success

:success
echo.
pause
exit /b 0

:fail
echo.
echo [FAILED]
echo.
pause
exit /b 1