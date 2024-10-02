@echo off

where svgcleaner >nul 2>nul
if %errorlevel% neq 0 (
    echo "this script requires svgcleaner.exe"
    pause
    exit /b 1
)

set ICONS_PATH="..\addons\DVs_behavior_tree\icons"
set DEBUGGER_ICONS_PATH="..\addons\DVs_behavior_tree\icons\debugger"

for %%f in (%ICONS_PATH%\*.svg %DEBUGGER_ICONS_PATH%\*.svg) do (
    if exist %%f (
        svgcleaner --multipass %%f %%f
    )
)

pause