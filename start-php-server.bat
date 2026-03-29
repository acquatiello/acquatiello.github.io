@echo off
setlocal
set PORT=5173
set "DOCROOT=%~dp0"
set "PHP_BIN=%~dp0php\php.exe"
if exist "%PHP_BIN%" (
  set "PHP_CMD=%PHP_BIN%"
) else (
  where php >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    set "PHP_CMD=php"
  ) else (
    echo PHP nao encontrado
    echo Baixe o ZIP do PHP para Windows e extraia em: "%~dp0php"
    echo Depois execute novamente este arquivo
    pause
    exit /b 1
  )
)
echo Iniciando servidor em 0.0.0.0:%PORT%
start "" "%PHP_CMD%" -S 0.0.0.0:%PORT% -t "%DOCROOT%"
timeout /t 2 >nul
start "" "http://127.0.0.1:%PORT%/index.php"
echo PC: http://127.0.0.1:%PORT%/index.php
echo Celular na mesma rede: http://SEU_IP:%PORT%/index.php
echo Descubra SEU_IP com: ipconfig
