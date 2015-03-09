@echo off
setlocal

set LANG=en_US.UTF-8
set SSL_CERT_FILE=%TEMP%\cacert.pem
set DOWNLOAD_CA_BUNDLE="require 'net/http'; Net::HTTP.start('curl.haxx.se') { |http| resp = http.get('/ca/cacert.pem'); abort 'Error downloading CA bundle: ' + resp.code unless resp.code == '200'; open(ENV['SSL_CERT_FILE'], 'wb') { |file| file.write(resp.body) }; }"

if not exist "%SSL_CERT_FILE%" (
  echo Downloading latest CA bundle...
  ruby -e %DOWNLOAD_CA_BUNDLE%

  if errorlevel 1 (
    exit /b %errorlevel%
  )
)

call gem.bat which bundler > NUL 2>&1
if errorlevel 1 (
  echo Installing bundler...
  call gem.bat install bundler --no-ri --no-rdoc
)

call bundle.bat %*
exit /b %errorlevel%
