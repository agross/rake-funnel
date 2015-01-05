@echo off
setlocal

set LANG=en_US.UTF-8
set PATH=%~dp0tools\Git\bin;%path%
set DOWNLOAD_CA_BUNDLE="require 'net/http'; Net::HTTP.start('curl.haxx.se') { |http| resp = http.get('/ca/cacert.pem'); abort 'Error downloading CA bundle: ' + resp.code unless resp.code == '200'; open('cacert.pem', 'wb') { |file| file.write(resp.body) }; }"

if not exist cacert.pem (
  echo Downloading latest CA bundle...
  ruby -e %DOWNLOAD_CA_BUNDLE%

  if errorlevel 1 (
    exit /b %errorlevel%
  )
)

set SSL_CERT_FILE=%cd%\cacert.pem

call gem.bat which bundler > NUL 2>&1
if errorlevel 1 (
  echo Installing bundler...
  call gem.bat install bundler --no-ri --no-rdoc
)

call bundle.bat %*
exit /b %errorlevel%
