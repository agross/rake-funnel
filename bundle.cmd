@echo off
setlocal

set LANG=en_US.UTF-8

call gem.bat which bundler > NUL 2>&1
if errorlevel 1 (
  echo Installing bundler...
  call gem.bat install bundler --no-ri --no-rdoc
)

call bundle.bat %*
exit /b %errorlevel%
