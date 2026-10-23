@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

REM ===========================================================================
REM  VoiceStudio Lab - ponto de entrada
REM
REM  Este .bat nao faz nada sozinho: ele chama lab\tools\collect-windows.ps1,
REM  que e o script auditavel de verdade. Manter a logica la fora facilita
REM  revisar e evita a fragilidade de Batch puro com JSON/HTTP.
REM
REM  O que ele NAO faz:
REM    - nao instala nada
REM    - nao altera variaveis de ambiente do sistema
REM    - nao abre portas na rede
REM    - nao executa nada baixado da internet
REM ===========================================================================

chcp 65001 >nul 2>&1
title VoiceStudio Lab

echo.
echo  ============================================================
echo   VoiceStudio Lab - coleta para Windows + AMD
echo  ============================================================
echo.

set "SCRIPT=%~dp0lab\tools\collect-windows.ps1"

if not exist "%SCRIPT%" (
    echo  ERRO: script nao encontrado:
    echo        %SCRIPT%
    echo.
    echo  Rode este .bat a partir da raiz do repositorio clonado.
    echo.
    pause
    exit /b 1
)

REM ---- confere se estamos na raiz do repositorio -----------------------------
if not exist "%~dp0lab\reports" (
    echo  AVISO: pasta lab\reports nao encontrada.
    echo         O clone parece incompleto. Os relatorios vao falhar.
    echo.
)

REM ---- PowerShell disponivel? ------------------------------------------------
set "PS=powershell"
where powershell >nul 2>&1
if errorlevel 1 (
    where pwsh >nul 2>&1
    if errorlevel 1 (
        echo  ERRO: PowerShell nao encontrado neste sistema.
        echo        Windows 10 e 11 trazem powershell.exe por padrao.
        echo.
        pause
        exit /b 1
    )
    set "PS=pwsh"
)

REM ---- traduz argumentos /x para -X do PowerShell ----------------------------
set "PS_ARGS="
set "NOPAUSE="

:parse
if "%~1"=="" goto run
set "A=%~1"

if /i "%A%"=="/?"        goto help
if /i "%A%"=="-h"        goto help
if /i "%A%"=="--help"    goto help

if /i "%A%"=="/voice"    ( set "PS_ARGS=!PS_ARGS! -Voice" & shift & goto parse )
if /i "%A%"=="/full"     ( set "PS_ARGS=!PS_ARGS! -Full"  & shift & goto parse )
if /i "%A%"=="/nogit"    ( set "PS_ARGS=!PS_ARGS! -NoGit" & shift & goto parse )
if /i "%A%"=="/nopause"  ( set "NOPAUSE=1"                & shift & goto parse )

echo %A% | findstr /b /i "/engine:" >nul
if not errorlevel 1 (
    set "PS_ARGS=!PS_ARGS! -Engine %A:/engine:=%"
    shift
    goto parse
)

echo %A% | findstr /b /i "/url:" >nul
if not errorlevel 1 (
    set "PS_ARGS=!PS_ARGS! -BaseUrl %A:/url:=%"
    shift
    goto parse
)

echo  AVISO: argumento desconhecido ignorado: %A%
shift
goto parse

:help
echo  Uso:
echo.
echo    run-lab.bat                    coleta rapida (ambiente + API + 1 frase)
echo    run-lab.bat /voice             corpus completo pt-BR (C1..C10)
echo    run-lab.bat /full              corpus + 4 repeticoes de C7 (mede CPU vs Vulkan)
echo    run-lab.bat /engine:audiocpp   forca um motor especifico
echo    run-lab.bat /url:http://127.0.0.1:3900
echo    run-lab.bat /nogit             coleta sem commit/push
echo    run-lab.bat /nopause           nao espera tecla no final
echo.
echo  Combinacoes:
echo    run-lab.bat /full /engine:audiocpp    mede o caminho Vulkan/AMD
echo    run-lab.bat /full /engine:omnivoice   mede o motor padrao em CPU
echo.
echo  Saida:
echo    lab\reports\evidence\windows\AAAA-MM-DD-HHMMSS\
echo.
echo  Depois do /full, compare os RTF das duas pastas geradas.
echo.
if not defined NOPAUSE pause
exit /b 0

:run
echo  Script : %SCRIPT%
echo  Motor  : %PS_ARGS%
echo.
echo  Isso pode levar alguns minutos. Nao feche a janela.
echo.

"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" !PS_ARGS!

set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
    echo  O script terminou com codigo %RC%.
    echo  Veja o run.log na pasta gerada para o detalhe.
) else (
    echo  Concluido com sucesso.
)

if not defined NOPAUSE (
    echo.
    pause
)
exit /b %RC%
