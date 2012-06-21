@echo off
if "%1" == "" goto debug
if "%1" == "debug" goto debug
if "%1" == "staging" goto staging

:debug
powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\build.ps1 -properties @{configuration='Debug'}" "Default" "4.0"
goto done

:staging
powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\build.ps1 -properties @{configuration='Release'; environment='Staging'}" "Staging" "4.0"
goto done

:done
echo "Build done!"