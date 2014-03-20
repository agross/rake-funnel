@echo off
setlocal

set LANG=en_US.UTF-8

:build
cls

set CI=
if defined TEAMCITY_PROJECT_NAME set CI=--without development

call bundle.cmd check
if errorlevel 1 call bundle.cmd install %CI%
if errorlevel 1 goto wait

cls

call bundle.cmd exec rake %*

:wait
rem Bail if we're running a TeamCity build.
if defined TEAMCITY_PROJECT_NAME goto quit

rem Loop the build script.
set choice=nothing
echo (Q)uit, (Enter) runs the build again
set /P choice=
if /i "%choice%"=="Q" goto quit

goto build

:quit
exit /b %errorlevel%
