@echo off
setlocal

set LANG=en_US.UTF-8
set PATH=%~dp0tools\Ruby\bin;%~dp0tools\Git\bin;%path%
set RUBY_BIN=tools\Ruby\bin\ruby.exe

if exist %RUBY_BIN% (
  %RUBY_BIN% "tools\Ruby\bin\bundle" %*
) else (
  rem Fall back to global Ruby installation.
  bundle.bat %*
)

exit /b %errorlevel%
