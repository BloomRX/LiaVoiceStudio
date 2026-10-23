@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
chcp 65001 >nul 2>&1
title VoiceStudio Lab

REM ===========================================================================
REM  VoiceStudio Lab - arquivo unico
REM
REM  Este .bat contem TUDO: o tradutor de argumentos, o codigo da coleta e o
REM  envio para o git. Nao existe arquivo auxiliar para voce instalar, copiar
REM  ou esquecer.
REM
REM  Como funciona: o bloco Batch (esta parte) extrai o bloco PowerShell que
REM  esta no fim do mesmo arquivo, roda e apaga o temporario. A linguagem
REM  interna e PowerShell porque Batch puro nao le JSON, nao consulta CIM e
REM  nao monta multipart com seguranca - mas voce so ve e so executa UM
REM  arquivo.
REM
REM  O que ele faz:
REM    - verifica pre-requisitos e coleta o hardware
REM    - baixa o instalador oficial do VoiceStudio (v0.5.6), confere o
REM      SHA-256 e instala em modo silencioso
REM    - abre o app e espera a API local responder
REM    - pede o download do modelo OmniVoice (~2.4 GB) pelo proprio app
REM    - gera as frases do corpus pt-BR e mede tempo, duracao e RTF
REM    - escreve os relatorios e faz commit/push na branch do fork
REM
REM  O que ele NAO faz:
REM    - nao altera variaveis de ambiente do sistema
REM    - nao instala driver
REM    - nao abre portas na rede (a API escuta so em 127.0.0.1)
REM    - nao executa binario de origem duvidosa: o unico baixado e o
REM      instalador do release oficial, e so roda se o SHA-256 conferir
REM ===========================================================================

set "VS_LAB_ROOT=%~dp0"
if "%VS_LAB_ROOT:~-1%"=="\" set "VS_LAB_ROOT=%VS_LAB_ROOT:~0,-1%"

REM ATENCAO: "shift" renumera os parametros, e %0 passa a ser o primeiro
REM argumento (/gguf, /voice...). Por isso %~f0 NAO pode ser lido depois do
REM parse: guardamos o caminho real do .bat aqui, antes de qualquer shift.
set "VS_SELF=%~f0"
if not defined VS_SELF set "VS_SELF=%~dp0%~nx0"

set "VS_TEMP_PS=%TEMP%\voicestudio-lab.ps1"
set "PWSH_ARGS="
set "NOPAUSE="

echo.
echo  ============================================================
echo   VoiceStudio Lab - instala, testa e coleta (Windows + AMD)
echo  ============================================================
echo.

if not exist "%VS_LAB_ROOT%\lab\reports" (
    echo  ERRO: pasta lab\reports nao encontrada em:
    echo        %VS_LAB_ROOT%
    echo.
    echo  Rode este .bat a partir da raiz do repositorio clonado.
    echo.
    pause
    exit /b 1
)

set "PS="
where powershell >nul 2>&1
if not errorlevel 1 set "PS=powershell"
if not defined PS (
    where pwsh >nul 2>&1
    if not errorlevel 1 set "PS=pwsh"
)
if not defined PS (
    echo  ERRO: PowerShell nao encontrado.
    echo        Windows 10 e 11 trazem powershell.exe por padrao.
    echo.
    pause
    exit /b 1
)

REM ---- traduz /voice -> -Voice, etc. ----------------------------------------
REM  Labels em vez de blocos: "shift" dentro de parenteses e uma armadilha
REM  conhecida do cmd, e este caminho precisa funcionar com argumentos.
:parse
if "%~1"=="" goto run
set "A=%~1"

if /i "%A%"=="/?"       goto help
if /i "%A%"=="-h"       goto help
if /i "%A%"=="--help"   goto help

if /i "%A%"=="/voice"   goto arg_voice
if /i "%A%"=="/full"    goto arg_full
if /i "%A%"=="/nogit"   goto arg_nogit
if /i "%A%"=="/nopause" goto arg_nopause
if /i "%A%"=="/noinstall" goto arg_noinstall
if /i "%A%"=="/nomodel" goto arg_nomodel
if /i "%A%"=="/gguf" goto arg_gguf
if /i "%A%"=="/gpu"      goto arg_gpu

echo %A% | findstr /b /i "/engine:" >nul
if not errorlevel 1 goto arg_engine

echo %A% | findstr /b /i "/url:" >nul
if not errorlevel 1 goto arg_url

echo  AVISO: argumento desconhecido ignorado: %A%
shift
goto parse

:arg_voice
set "PWSH_ARGS=!PWSH_ARGS! -Voice"
shift
goto parse

:arg_full
set "PWSH_ARGS=!PWSH_ARGS! -Full"
shift
goto parse

:arg_nogit
set "PWSH_ARGS=!PWSH_ARGS! -NoGit"
shift
goto parse

:arg_nopause
set "NOPAUSE=1"
shift
goto parse

:arg_noinstall
set "PWSH_ARGS=!PWSH_ARGS! -NoInstall"
shift
goto parse

:arg_nomodel
set "PWSH_ARGS=!PWSH_ARGS! -NoModel"
shift
goto parse

:arg_gguf
set "PWSH_ARGS=!PWSH_ARGS! -Gguf"
shift
goto parse

:arg_gpu
set "PWSH_ARGS=!PWSH_ARGS! -Gpu"
shift
goto parse

:arg_engine
set "PWSH_ARGS=!PWSH_ARGS! -Engine %A:/engine:=%"
shift
goto parse

:arg_url
set "PWSH_ARGS=!PWSH_ARGS! -BaseUrl %A:/url:=%"
shift
goto parse

:help
echo  Uso:
echo.
echo    run-lab.bat                    instala o app, baixa o modelo, gera 1 frase
echo    run-lab.bat /voice             corpus completo pt-BR (C1..C10)
echo    run-lab.bat /full              corpus + 4 repeticoes de C7
echo    run-lab.bat /engine:audiocpp   forca um motor especifico
echo    run-lab.bat /url:http://127.0.0.1:3900
echo    run-lab.bat /noinstall         nao baixa/instala o app (so coleta)
echo    run-lab.bat /nomodel           nao baixa o modelo OmniVoice
echo    run-lab.bat /gguf              testa o motor GGUF (caminho Vulkan)
echo    run-lab.bat /gpu               mede a GPU de verdade (Vulkan/audio.cpp)
echo    run-lab.bat /nogit             coleta sem commit/push
echo    run-lab.bat /nopause           nao espera tecla no final
echo.
echo  Saida: lab\reports\evidence\windows\AAAA-MM-DD-HHMMSS\
echo.
if not defined NOPAUSE pause
exit /b 0

:run
echo  Extraindo o script interno...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$l = Get-Content -LiteralPath '%VS_SELF%'; $i = -1; for ($k = 0; $k -lt $l.Count; $k++) { if ($l[$k].Trim() -eq '#<PS_BEGIN>') { $i = $k; break } }; if ($i -lt 0) { exit 2 }; $l[$i..($l.Count - 1)] | Set-Content -LiteralPath '%VS_TEMP_PS%' -Encoding UTF8"

if errorlevel 1 (
    echo.
    echo  ERRO: nao foi possivel extrair o script interno deste .bat.
    echo        Se voce passou um argumento como /gguf ou /voice, esta copia
    echo        do .bat e antiga e tem um bug conhecido na leitura dos
    echo        argumentos. Atualize:
    echo            git pull
    echo        Caso contrario, o arquivo foi editado ou corrompido.
    echo.
    del "%VS_TEMP_PS%" >nul 2>&1
    pause
    exit /b 2
)

echo  Rodando a coleta (nao feche a janela)...
echo.
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%VS_TEMP_PS%" !PWSH_ARGS!
set "RC=%ERRORLEVEL%"

del "%VS_TEMP_PS%" >nul 2>&1

echo.
if not "%RC%"=="0" (
    echo  Terminou com codigo %RC%. Veja o run.log na pasta gerada.
) else (
    echo  Concluido com sucesso.
)

if not defined NOPAUSE (
    echo.
    pause
)
exit /b %RC%
#<PS_BEGIN>
#Requires -Version 5.1
<#
.SYNOPSIS
    Coletor do VoiceStudio Lab para Windows + AMD.

.DESCRIPTION
    Roda a Fase B/C/D/E do laboratorio na maquina real e empacota tudo em
    lab/reports/evidence/windows/<timestamp>/ para ser commitado e enviado.

    Instala o app (se preciso, com SHA-256 conferido) e baixa o modelo
    OmniVoice pelo proprio app. NAO altera variaveis de ambiente do sistema,
    NAO abre portas na rede e NAO muda configuracao fora do app.

.PARAMETER NoGit
    Coleta tudo mas nao faz commit/push.

.PARAMETER NoInstall
    Nao baixa nem instala o app; so coleta o que ja existe.

.PARAMETER NoModel
    Nao pede o download do modelo OmniVoice.

.PARAMETER Gguf
    Modo diagnostico do motor omnivoice-gguf (runtime omnivoice.cpp/GGML).
    Verifica se o binario existe e se ele traz o backend Vulkan, e tenta uma
    geracao com esse motor. Nao baixa nada alem dos quants que o motor pedir.

.PARAMETER Gpu
    Mede a GPU de verdade. Le a VRAM real (o WMI satura em 4 GB), instala o
    runtime nativo audio.cpp (binario Vulkan, 57 MB) e lista os dispositivos
    Vulkan da placa. So baixa o modelo Breeze-TTS-2 (4,98 GB) se a GPU for
    realmente enumerada - e entao gera uma frase e mede o RTF em Vulkan.
    O modelo e en/zh: serve para medir a PLACA, nao para julgar o portugues.

.PARAMETER AppWaitSeconds
    Quanto esperar a API subir depois de abrir o app. Padrao 1800.

.PARAMETER Model
    repo_id do modelo a garantir. Padrao k2-fsa/OmniVoice.

.PARAMETER Voice
    Roda o corpus completo pt-BR (C1..C10), uma vez cada. Demora mais.

.PARAMETER Full
    Corpus completo + 4 repeticoes de C7 (medicao pareada CPU/Vulkan).
    Implica -Voice.

.PARAMETER Engine
    Id do motor TTS (ex: omnivoice, voxcpm2, audiocpp). Vazio = motor ativo.

.PARAMETER BaseUrl
    Endereco do backend. Padrao http://127.0.0.1:3900

.EXAMPLE
    run-lab.bat
    run-lab.bat /voice
    run-lab.bat /full /engine:audiocpp
    run-lab.bat /nogit
#>
[CmdletBinding()]
param(
    [switch]$NoGit,
    [switch]$Voice,
    [switch]$Full,
    [switch]$NoInstall,
    [switch]$NoModel,
    [switch]$Gguf,
    [switch]$Gpu,
    [int]$AppWaitSeconds = 1800,
    [string]$Model = 'k2-fsa/OmniVoice',
    [string]$GgufModel = 'Serveurperso/OmniVoice-GGUF',
    [string]$Engine = "",
    [string]$BaseUrl = "http://127.0.0.1:3900",
    [string]$OutDir = ""
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# ---------------------------------------------------------------- constantes
$ScriptVersion = '1.0.0'
# A raiz vem do .bat (VS_LAB_ROOT). $PSScriptRoot apontaria para %TEMP%,
# porque o script e extraido para la antes de rodar.
$RepoRoot      = $env:VS_LAB_ROOT
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$Stamp         = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not $OutDir) {
    $OutDir = Join-Path $RepoRoot "lab\reports\evidence\windows\$Stamp"
}
$ApiDir   = Join-Path $OutDir 'api'
$AudioDir = Join-Path $OutDir 'audio'
$CsvPath  = Join-Path $OutDir 'measurements.csv'

New-Item -ItemType Directory -Force -Path $OutDir, $ApiDir, $AudioDir | Out-Null

$script:Problems = New-Object System.Collections.ArrayList
$script:Steps    = New-Object System.Collections.ArrayList
$script:Rows     = New-Object System.Collections.ArrayList

# ------------------------------------------------------------------- helpers
function Write-Step {
    param([string]$Id, [string]$Text)
    Write-Host ""
    Write-Host "[$Id] $Text" -ForegroundColor Cyan
    [void]$script:Steps.Add("$Id $Text")
}
function Write-Ok   { param([string]$m) Write-Host "     OK    $m" -ForegroundColor Green }
function Write-Warn2{ param([string]$m) Write-Host "     AVISO $m" -ForegroundColor Yellow; [void]$script:Problems.Add($m) }
function Write-Fail { param([string]$m) Write-Host "     FALHA $m" -ForegroundColor Red;    [void]$script:Problems.Add($m) }
function Write-Info { param([string]$m) Write-Host "     $m" -ForegroundColor Gray }

function Test-Cmd {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Api {
    <# GET com timeout curto; devolve objeto ou $null e grava o erro.
       -Tolerant: 404/405 e "nao existe nesta versao", nao falha de contrato. #>
    param([string]$Path, [string]$SaveAs, [int]$TimeoutSec = 10, [switch]$Tolerant)
    $url = "$BaseUrl$Path"
    try {
        $r = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $TimeoutSec -ErrorAction Stop
        if ($SaveAs) { $r | ConvertTo-Json -Depth 8 | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8 }
        return $r
    } catch {
        $msg  = $_.Exception.Message
        $code = $null
        try { $code = [int]$_.Exception.Response.StatusCode } catch { }
        if ($SaveAs) {
            $rec = [ordered]@{ path = $Path; http = $code; error = $msg; at = (Get-Date).ToString('o') }
            if ($Tolerant -and ($code -eq 404 -or $code -eq 405)) {
                $rec.note = 'endpoint nao existe nesta versao - nao e falha'
            }
            $rec | ConvertTo-Json | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8
        }
        return $null
    }
}

function Invoke-Post {
    <# POST JSON; devolve objeto ou $null e grava o erro. #>
    param([string]$Path, [object]$Body, [string]$SaveAs, [int]$TimeoutSec = 30)
    $url = "$BaseUrl$Path"
    $json = $Body | ConvertTo-Json -Depth 6 -Compress
    try {
        $r = Invoke-RestMethod -Uri $url -Method Post -Body $json `
             -ContentType 'application/json' -TimeoutSec $TimeoutSec -ErrorAction Stop
        if ($SaveAs) { $r | ConvertTo-Json -Depth 8 | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8 }
        return $r
    } catch {
        $msg = $_.Exception.Message
        $body = ''
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $body = $sr.ReadToEnd()
        } catch { }
        if ($SaveAs) {
            @{ path = $Path; error = $msg; body = $body; at = (Get-Date).ToString('o') } |
                ConvertTo-Json | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8
        }
        return $null
    }
}

function Find-VoiceStudioExe {
    <# Procura o executavel instalado por registro, caminhos padrao e varredura. #>
    $direct = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\VoiceStudio\VoiceStudio.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\OmniVoice Studio\OmniVoice Studio.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\omnivoice-studio\omnivoice-studio.exe')
    )
    foreach ($p in $direct) { if (Test-Path $p) { return $p } }

    $roots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($r in $roots) {
        try {
            $entries = Get-ItemProperty $r -ErrorAction SilentlyContinue |
                       Where-Object { $_.DisplayName -match 'VoiceStudio|OmniVoice' }
            foreach ($e in $entries) {
                if ($e.InstallLocation -and (Test-Path $e.InstallLocation)) {
                    $hit = Get-ChildItem -Path $e.InstallLocation -Filter '*.exe' -ErrorAction SilentlyContinue |
                           Where-Object { $_.Name -match 'VoiceStudio|OmniVoice' } | Select-Object -First 1
                    if ($hit) { return $hit.FullName }
                }
                if ($e.DisplayIcon) {
                    $icon = ($e.DisplayIcon -split ',')[0].Trim().Trim('"')
                    if (Test-Path $icon) { return $icon }
                }
            }
        } catch { }
    }

    $base = Join-Path $env:LOCALAPPDATA 'Programs'
    if (Test-Path $base) {
        $hit = Get-ChildItem -Path $base -Recurse -Depth 2 -Filter '*.exe' -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '^(VoiceStudio|OmniVoice).*\.exe$' } | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Get-Sha256 {
    param([string]$Path)
    try { return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower() } catch { return '' }
}

# =========================================================== INICIO DO LOG
$TranscriptPath = Join-Path $OutDir 'run.log'
try { Start-Transcript -Path $TranscriptPath -Force | Out-Null } catch { }

Write-Host ""
Write-Host "================================================================" -ForegroundColor White
Write-Host " VoiceStudio Lab - instala, testa e coleta (Windows + AMD)" -ForegroundColor White
Write-Host " Versao do coletor: $ScriptVersion" -ForegroundColor DarkGray
Write-Host " Inicio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host " Saida:  $OutDir" -ForegroundColor DarkGray
Write-Host "================================================================" -ForegroundColor White
if ($Full) { Write-Host " Modo: COMPLETO (corpus + repeticoes)" -ForegroundColor Magenta }
elseif ($Voice) { Write-Host " Modo: VOZ (corpus completo)" -ForegroundColor Magenta }
else { Write-Host " Modo: RAPIDO (ambiente + API + 2 frases)" -ForegroundColor Magenta }

# Eco das opcoes: se um argumento nao chegar, aparece aqui em vez de virar
# um "pulou sem avisar". (Acredite: ja aconteceu.)
Write-Host (" Opcoes: gguf={0} gpu={1} voice={2} full={3} noinstall={4} nomodel={5} engine='{6}'" -f `
    [bool]$Gguf, [bool]$Gpu, [bool]$Voice, [bool]$Full, [bool]$NoInstall, [bool]$NoModel, $Engine) `
    -ForegroundColor DarkGray

# ---------------------------------------------------------------- [1/10] preflight
Write-Step '1/10' 'Verificando pre-requisitos'

$psv = $PSVersionTable.PSVersion.ToString()
Write-Info "PowerShell $psv"

$curl = 'curl.exe'
if (-not (Test-Cmd $curl)) {
    if (Test-Cmd 'curl') { $curl = 'curl' } else { $curl = $null }
}
if ($curl) { Write-Ok "curl disponivel ($curl)" } else {
    Write-Warn2 'curl nao encontrado. A geracao de audio e as sondagens de erro serao puladas.'
}

if (Test-Cmd 'git') {
    Write-Ok "git $((git --version) -replace 'git version ','')"
} else {
    Write-Warn2 'git nao encontrado. Nada sera commitado.'
    $NoGit = $true
}

$isRepo = $false
if (Test-Cmd 'git') {
    try {
        Push-Location $RepoRoot
        $inside = (& git rev-parse --is-inside-work-tree 2>$null)
        if ($inside -eq 'true') {
            $isRepo = $true
            $branch = (& git rev-parse --abbrev-ref HEAD 2>$null)
            Write-Ok "repositorio git, branch '$branch'"
        }
        Pop-Location
    } catch { Pop-Location -ErrorAction SilentlyContinue }
}
if (-not $isRepo) { Write-Warn2 'Este diretorio nao e um repositorio git; o commit sera pulado.' }

# --------------------------------------------------------------- [2/10] hardware
Write-Step '2/10' 'Coletando hardware e sistema'

$hw = [ordered]@{
    collected_at   = (Get-Date).ToString('o')
    collector      = $ScriptVersion
    powershell     = $psv
    computer       = $env:COMPUTERNAME
    user           = $env:USERNAME
    is_admin       = $false
    os             = $null
    cpu            = $null
    gpus           = @()
    ram_gb         = $null
    ram_free_gb    = $null
    disks          = @()
    vulkaninfo     = $null
    dotnet         = $null
}

try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $hw.is_admin = (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { }

try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $hw.os = [ordered]@{
        caption    = $os.Caption
        version    = $os.Version
        build      = $os.BuildNumber
        arch       = $os.OSArchitecture
        installed  = $os.InstallDate
        last_boot  = $os.LastBootUpTime
    }
    $hw.ram_gb      = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $hw.ram_free_gb = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    Write-Ok "$($os.Caption) build $($os.BuildNumber) ($($os.OSArchitecture))"
} catch { Write-Fail "Nao foi possivel ler o sistema operacional: $($_.Exception.Message)" }

try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $hw.cpu = [ordered]@{
        name          = $cpu.Name
        manufacturer  = $cpu.Manufacturer
        cores         = $cpu.NumberOfCores
        logical       = $cpu.NumberOfLogicalProcessors
        max_clock_mhz = $cpu.MaxClockSpeed
        l3_cache_kb   = $cpu.L3CacheSize
    }
    $vendor = if ($cpu.Manufacturer -match 'AMD') { 'AMD' } else { $cpu.Manufacturer }
    Write-Ok "CPU: $($cpu.Name.Trim()) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T, $vendor)"
} catch { Write-Fail "Nao foi possivel ler a CPU: $($_.Exception.Message)" }

try {
    $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
    foreach ($g in $gpus) {
        $vramGb = $null
        if ($g.AdapterRAM -and $g.AdapterRAM -gt 0) {
            $vramGb = [math]::Round($g.AdapterRAM / 1GB, 2)
        }
        $hw.gpus += [ordered]@{
            name           = $g.Name
            vendor         = $g.AdapterCompatibility
            driver_version = $g.DriverVersion
            driver_date    = $g.DriverDate
            vram_gb_cim    = $vramGb      # Win32 limita a ~4GB; ver gpu-report
            video_mode     = $g.VideoModeDescription
            status         = $g.Status
        }
        Write-Ok "GPU: $($g.Name) (driver $($g.DriverVersion))"
    }
    if ($gpus.Count -eq 0) { Write-Warn2 'Nenhuma GPU enumerada pelo Windows.' }
} catch { Write-Fail "Nao foi possivel ler as GPUs: $($_.Exception.Message)" }

try {
    foreach ($d in (Get-CimInstance Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DriveType -eq 3 })) {
        $hw.disks += [ordered]@{
            drive    = $d.DeviceID
            label    = $d.VolumeName
            total_gb = [math]::Round($d.Size / 1GB, 2)
            free_gb  = [math]::Round($d.FreeSpace / 1GB, 2)
        }
        Write-Info "$($d.DeviceID) $([math]::Round($d.FreeSpace/1GB,1)) GB livres de $([math]::Round($d.Size/1GB,1)) GB"
    }
} catch { Write-Warn2 "Nao foi possivel ler os discos: $($_.Exception.Message)" }

if (Test-Cmd 'vulkaninfo') {
    try {
        $vk = (& vulkaninfo --summary 2>&1 | Out-String)
        $hw.vulkaninfo = ($vk -split "`n" | Select-Object -First 40) -join "`n"
        Write-Ok 'vulkaninfo encontrado; resumo salvo'
    } catch { Write-Info 'vulkaninfo existe mas falhou ao executar' }
} else {
    $hw.vulkaninfo = 'vulkaninfo ausente (normal sem Vulkan SDK; nao indica ausencia de Vulkan no driver)'
    Write-Info 'vulkaninfo ausente - normal, o driver AMD expoe Vulkan sem o SDK'
}

# J: e o diretorio sugerido pela missao
$hw.j_drive = Test-Path 'J:\'
if ($hw.j_drive) { Write-Ok 'Unidade J: presente' } else { Write-Info 'Unidade J: ausente' }

$hw | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $OutDir 'machine.json') -Encoding UTF8

# Grava tambem um resumo legivel
$hwLines = @()
$hwLines += "Sistema : $($hw.os.caption) build $($hw.os.build) ($($hw.os.arch))"
$hwLines += "CPU     : $($hw.cpu.name) - $($hw.cpu.cores)C/$($hw.cpu.logical)T"
$hwLines += "RAM     : $($hw.ram_gb) GB total, $($hw.ram_free_gb) GB livre"
foreach ($g in $hw.gpus) { $hwLines += "GPU     : $($g.name) - driver $($g.driver_version)" }
foreach ($d in $hw.disks) { $hwLines += "Disco   : $($d.drive) $($d.free_gb) GB livres de $($d.total_gb) GB" }
$hwLines += "Admin   : $($hw.is_admin)"
$hwLines | Out-File -FilePath (Join-Path $OutDir 'hardware.txt') -Encoding UTF8

# ------------------------------------------------- [3/10] app, processos, porta
Write-Step '3/10' 'Procurando a instalacao do VoiceStudio'

$appInfo = [ordered]@{
    data_dirs_found = @()
    processes       = @()
    port_3900       = @()
    version_file    = $null
}

$candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\VoiceStudio'),
    (Join-Path $env:APPDATA 'omnivoice'),
    (Join-Path $env:USERPROFILE '.config\omnivoice'),
    (Join-Path $env:LOCALAPPDATA 'omnivoice'),
    (Join-Path $env:LOCALAPPDATA 'Programs\OmniVoice Studio')
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $appInfo.data_dirs_found += $c
        Write-Ok "encontrado: $c"
    }
}
if ($appInfo.data_dirs_found.Count -eq 0) { Write-Info 'nenhum diretorio padrao encontrado (pode estar em outro drive)' }

try {
    $procs = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match 'VoiceStudio|OmniVoice|python' } |
        Select-Object Id, ProcessName, @{n='RAM_MB';e={[math]::Round($_.WorkingSet64/1MB,1)}}, StartTime
    foreach ($p in $procs) {
        $appInfo.processes += [ordered]@{
            pid=$p.Id; name=$p.ProcessName; ram_mb=$p.RAM_MB; started=$p.StartTime
        }
    }
    if ($appInfo.processes.Count -gt 0) { Write-Ok "$($appInfo.processes.Count) processo(s) relacionado(s)" }
    else { Write-Info 'nenhum processo VoiceStudio/python rodando' }
} catch { Write-Warn2 "falha ao listar processos: $($_.Exception.Message)" }

if (Test-Cmd 'Get-NetTCPConnection') {
    try {
        $conns = Get-NetTCPConnection -LocalPort 3900 -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            $appInfo.port_3900 += [ordered]@{
                local_address = $c.LocalAddress
                local_port    = $c.LocalPort
                owning_pid    = $c.OwningProcess
                loopback_only = ($c.LocalAddress -in @('127.0.0.1','::1'))
            }
            if ($c.LocalAddress -in @('127.0.0.1','::1')) {
                Write-Ok "porta 3900 escutando em $($c.LocalAddress) (loopback - correto)"
            } else {
                Write-Warn2 "porta 3900 escutando em $($c.LocalAddress) - NAO e loopback, verifique compartilhamento de rede"
            }
        }
        if ($conns.Count -eq 0) { Write-Info 'porta 3900 nao esta escutando (app fechado?)' }
    } catch { Write-Info 'nao foi possivel consultar a porta 3900' }
}

$appInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $OutDir 'app.json') -Encoding UTF8

# ------------------------------------------------------ [4/10] instalar app
Write-Step '4/10' 'Instalando o VoiceStudio'

# Pin da versao estavel. O SHA-256 foi lido da API do GitHub para a release
# v0.5.6; o asset tem 214.447.484 bytes. Se a release mudar, o hash falha e
# a instalacao e abortada em vez de executar outro binario.
$ReleaseTag  = 'v0.5.6'
$AssetName   = 'VoiceStudio-Electron-0.5.6-win-x64.exe'
$AssetSha256 = '3d7ac1d6b54e7854ca7fff4dda838e402d1c5d31acc9656b1838432e29a97624'
$AssetBytes  = 214447484

$appExe   = $null
$appState = 'nao encontrado'
try { $appExe = Find-VoiceStudioExe } catch { }

if ($appExe) {
    $appState = 'ja instalado'
    Write-Ok "VoiceStudio ja instalado: $appExe"
    Write-Info 'instalacao pulada'
} elseif ($NoInstall) {
    $appState = 'pulado por /noinstall'
    Write-Info 'instalacao pulada por /noinstall'
} else {
    Write-Info "release : $ReleaseTag"
    Write-Info "arquivo : $AssetName (~204 MB)"
    Write-Info "destino : %TEMP%\voicestudio-lab"

    $dlDir   = Join-Path $env:TEMP 'voicestudio-lab'
    New-Item -ItemType Directory -Force -Path $dlDir | Out-Null
    $exePath = Join-Path $dlDir $AssetName
    $url     = "https://github.com/debpalash/VoiceStudio/releases/download/$ReleaseTag/$AssetName"

    $needDownload = $true
    if (Test-Path $exePath) {
        $sz = (Get-Item $exePath).Length
        if ($sz -eq $AssetBytes) { $needDownload = $false; Write-Info 'instalador ja baixado, reaproveitando' }
    }

    if ($needDownload) {
        Write-Info 'baixando... (pode levar alguns minutos)'
        $ok = $false
        if (Test-Cmd 'curl.exe') {
            & curl.exe -sS -L --fail --retry 2 --connect-timeout 30 -o $exePath $url 2>$null
            if ($LASTEXITCODE -eq 0) { $ok = $true }
        }
        if (-not $ok) {
            try {
                $oldPref = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $url -OutFile $exePath -UseBasicParsing -ErrorAction Stop
                $ProgressPreference = $oldPref
                $ok = $true
            } catch {
                Write-Fail "download falhou: $($_.Exception.Message)"
            }
        }
        if (-not $ok) {
            $appState = 'falha no download'
            Write-Fail 'nao foi possivel baixar o instalador; siga sem instalar'
        }
    }

    if ((Test-Path $exePath) -and $appState -ne 'falha no download') {
        Write-Info 'conferindo SHA-256...'
        $actual = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $AssetSha256) {
            Write-Fail "SHA-256 nao confere. esperado $AssetSha256, obtido $actual"
            $appState = 'hash invalido'
            Write-Fail 'instalador descartado por seguranca; nada foi executado'
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        } else {
            Write-Ok 'SHA-256 confere'
            Write-Info 'executando instalador silencioso (/S)...'
            try {
                Start-Process -FilePath $exePath -ArgumentList '/S' -Wait -ErrorAction Stop
            } catch {
                Write-Warn2 "o instalador retornou erro: $($_.Exception.Message)"
            }

            $deadline = (Get-Date).AddSeconds(180)
            while ((Get-Date) -lt $deadline) {
                Start-Sleep -Seconds 3
                try { $appExe = Find-VoiceStudioExe } catch { }
                if ($appExe) { break }
            }
            if ($appExe) {
                $appState = 'instalado agora'
                Write-Ok "instalado em: $appExe"
            } else {
                $appState = 'instalador rodou, executavel nao localizado'
                Write-Warn2 'instalador executou mas nao achei o .exe. Procure no Menu Iniciar.'
            }
        }
    }
}

[ordered]@{
    state          = $appState
    exe            = $appExe
    release        = $ReleaseTag
    asset          = $AssetName
    asset_bytes    = $AssetBytes
    sha256_expected = $AssetSha256
    silent_flag    = '/S'
    at             = (Get-Date).ToString('o')
} | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $OutDir 'app-install.json') -Encoding UTF8

# ------------------------------------------------- diagnostico da subida do app
function Write-LaunchDiagnostics {
    <# Quando a API nao sobe, o relatorio precisa dizer POR QUE. Sem isso a
       unica saida e esperar 30 min e adivinhar. #>
    param([string]$Quando)

    Write-Warn2 "diagnostico ($Quando): a API nao respondeu"

    $vsProc = @(Get-Process -Name 'VoiceStudio' -ErrorAction SilentlyContinue)
    if ($vsProc.Count -eq 0) { Write-Info '  app VoiceStudio: NAO esta rodando (abriu e fechou?)' }
    else { Write-Info ("  app VoiceStudio: rodando (pid {0}, {1} MB)" -f $vsProc[0].Id, [int]($vsProc[0].WorkingSet64 / 1MB)) }

    $pys = @(Get-Process -Name 'python','pythonw' -ErrorAction SilentlyContinue)
    if ($pys.Count -eq 0) { Write-Info '  backend python: nenhum processo' }
    else {
        foreach ($py in $pys) { Write-Info ("  backend python: pid {0}, {1} MB" -f $py.Id, [int]($py.WorkingSet64 / 1MB)) }
    }

    $acs = @(Get-Process -Name 'audiocpp_server' -ErrorAction SilentlyContinue)
    if ($acs.Count -gt 0) {
        foreach ($a in $acs) { Write-Warn2 ("  audiocpp_server ORFAO: pid {0}, {1} MB - segura o modelo na RAM e pode impedir o app de subir" -f $a.Id, [int]($a.WorkingSet64 / 1MB)) }
        Write-Info '  para encerrar:  taskkill /IM audiocpp_server.exe /F'
    }

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $freeMb = [int]($os.FreePhysicalMemory / 1KB)
        $totalMb = [int]($os.TotalVisibleMemorySize / 1KB)
        Write-Info "  RAM: $freeMb MB livres de $totalMb MB"
        if ($freeMb -lt 1500) { Write-Warn2 '  memoria livre abaixo de 1,5 GB: o backend do app (PyTorch) dificilmente sobe assim' }
    } catch { }

    Write-Info '  maiores consumidores de memoria:'
    try {
        Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 8 | ForEach-Object {
            Write-Info ("    {0,-28} {1,7} MB" -f $_.ProcessName, [int]($_.WorkingSet64 / 1MB))
        }
    } catch { }

    # logs do proprio app
    $logRoots = @(
        (Join-Path $env:APPDATA 'omnivoice'),
        (Join-Path $env:APPDATA 'OmniVoice'),
        (Join-Path $env:LOCALAPPDATA 'omnivoice'),
        (Join-Path $env:LOCALAPPDATA 'OmniVoice'),
        (Join-Path $env:APPDATA 'VoiceStudio')
    )
    $destDir = Join-Path $OutDir 'app-logs'
    $copied = 0
    foreach ($lr in $logRoots) {
        if (-not (Test-Path $lr)) { continue }
        $logs = @(Get-ChildItem -Path $lr -Recurse -Include '*.log','*.txt' -ErrorAction SilentlyContinue |
                  Where-Object { $_.Length -gt 0 -and $_.LastWriteTime -gt (Get-Date).AddHours(-3) } |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 3)
        foreach ($lg in $logs) {
            if ($copied -ge 5) { break }
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            $safe = ($lg.FullName -replace '[^A-Za-z0-9._-]','_')
            Copy-Item -LiteralPath $lg.FullName -Destination (Join-Path $destDir $safe) -Force -ErrorAction SilentlyContinue
            if ($copied -eq 0) {
                Write-Info "  ultimas linhas de $($lg.FullName):"
                Get-Content -LiteralPath $lg.FullName -Tail 8 -ErrorAction SilentlyContinue | ForEach-Object { Write-Info "    $_" }
            }
            $copied++
        }
    }
    if ($copied -eq 0) { Write-Info '  nenhum log do app modificado na ultima hora' }
    else { Write-Info "  $copied log(s) copiados para app-logs/" }
}

# ------------------------------------------- [5/10] iniciar app e esperar API
Write-Step '5/10' 'Iniciando o VoiceStudio'

if (-not $appExe) {
    try { $appExe = Find-VoiceStudioExe } catch { }
}

$apiReady = $false
if ($appExe) {
    $procName = [System.IO.Path]::GetFileNameWithoutExtension($appExe)
    $running = $false
    try {
        if (Get-Process -Name $procName -ErrorAction SilentlyContinue) { $running = $true }
    } catch { }

    if (-not $running) {
        Write-Info "iniciando: $appExe"
        try {
            Start-Process -FilePath $appExe -ErrorAction Stop
        } catch {
            Write-Warn2 "nao consegui iniciar o app: $($_.Exception.Message)"
        }
    } else {
        Write-Ok 'o app ja esta rodando'
    }

    # em /gpu a espera e curta de proposito: o [7c]/[7d] medem a placa falando
    # direto com o audiocpp_server, sem API. Esperar 30 min por um app que nao
    # sobe so atrasaria a unica medicao que ainda depende dele.
    $waitBudget = $AppWaitSeconds
    if ($Gpu) { $waitBudget = [math]::Min($AppWaitSeconds, 420) }
    if ($waitBudget -lt $AppWaitSeconds) {
        Write-Info "modo /gpu: espera limitada a $waitBudget s (a medicao da placa nao depende da API)"
    }
    Write-Info "esperando /health responder (ate $waitBudget s)..."
    Write-Info ''
    Write-Info 'ATENCAO - existe UM passo que so pode ser feito na janela do app:'
    Write-Info '  1. na primeira execucao o VoiceStudio mostra "Instalar ambiente local"'
    Write-Info '     (Python + dependencias, varios GB). Clique nesse botao.'
    Write-Info '  2. quando a API subir, este script continua sozinho.'
    Write-Info '  Nao feche esta janela do cmd.'
    Write-Info ''

    $deadline = (Get-Date).AddSeconds($waitBudget)
    $lastLabel = ''
    $waited    = 0
    while ((Get-Date) -lt $deadline) {
        # curl em vez de Invoke-RestMethod no polling: durante ~2 min o
        # backend ainda nao escuta, e cada recusa de conexao do .NET vira um
        # bloco "TerminatingError" no run.log. O curl devolve so o codigo.
        if ($curl) {
            $code = (& $curl -s -o NUL -w '%{http_code}' --max-time 3 "$BaseUrl/health" 2>$null | Out-String).Trim()
            if ($code -eq '200') { $apiReady = $true; break }
            if ($code -eq '503') {
                $spRaw = (& $curl -s --max-time 3 "$BaseUrl/startup/progress" 2>$null | Out-String).Trim()
                if ($spRaw) {
                    $sp = $null
                    try { $sp = $spRaw | ConvertFrom-Json } catch { }
                    if ($sp -and $sp.step) {
                        $lbl = "$($sp.step) $($sp.label)"
                        if ($lbl -ne $lastLabel) { Write-Info "backend subindo: $lbl"; $lastLabel = $lbl }
                    }
                }
            }
        } else {
            try {
                $h = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
                if ($h -and $h.status -eq 'ok') { $apiReady = $true; break }
            } catch { }
        }

        Start-Sleep -Seconds 5
        $waited += 5
        if ($waited % 60 -eq 0) {
            Write-Info "aguardando a API... ${waited}s. Se a janela do app pedir, clique em 'Instalar ambiente local'."
        }
        # diagnostico cedo: nao vale passar 30 min sem saber o motivo
        if ($waited -eq 120 -or $waited -eq 420) {
            Write-LaunchDiagnostics -Quando "${waited}s"
        }
        # se o app ja fechou e nao ha python algum, nao adianta esperar
        if ($waited -ge 150) {
            $vsAlive = @(Get-Process -Name 'VoiceStudio' -ErrorAction SilentlyContinue).Count -gt 0
            $pyAlive = @(Get-Process -Name 'python','pythonw' -ErrorAction SilentlyContinue).Count -gt 0
            if (-not $vsAlive -and -not $pyAlive) {
                Write-Warn2 'o app nao esta mais rodando e nao ha backend: encerrando a espera'
                Write-LaunchDiagnostics -Quando 'app ausente'
                break
            }
        }
    }

    if ($apiReady) {
        Write-Ok 'API respondeu: o app esta pronto'
    } else {
        Write-Warn2 'timeout esperando a API. Motivos comuns:'
        Write-Info '  - ninguem clicou em "Instalar ambiente local" na janela do app'
        Write-Info '  - o download do ambiente Python ainda esta em andamento'
        Write-Info '  - o app abriu e fechou por algum erro (veja o log dele)'
        Write-LaunchDiagnostics -Quando 'final'
        Write-Info 'Deixe o app aberto e rode o .bat de novo: ele reaproveita o que ja baixou.'
    }
} else {
    Write-Warn2 'app nao encontrado; seguindo sem iniciar (as fases de API e voz serao puladas)'
}

# ---------------------------------------------------------------- [6/10] API
Write-Step '6/10' 'Sondando a API local'

$apiStatus = [ordered]@{ reachable = $false; version = $null; device = $null }

$health = Invoke-Api -Path '/health' -SaveAs 'health.json' -TimeoutSec 5
if ($health -and $health.status) {
    $apiStatus.reachable = $true
    $apiStatus.version   = $health.version
    $apiStatus.device    = $health.device
    Write-Ok "/health -> status=$($health.status) device=$($health.device) version=$($health.version)"
} else {
    Write-Warn2 "API nao respondeu em $BaseUrl. Abra o VoiceStudio e rode de novo para as fases C/D."
}

$engines = $null
if ($apiStatus.reachable) {
    [void](Invoke-Api -Path '/startup/progress' -SaveAs 'startup-progress.json')
    [void](Invoke-Api -Path '/system/info'      -SaveAs 'system-info.json')
    [void](Invoke-Api -Path '/system/diagnose'  -SaveAs 'diagnose.json' -TimeoutSec 30)
    [void](Invoke-Api -Path '/model/status' -SaveAs 'model-status.json' -TimeoutSec 20)
    [void](Invoke-Api -Path '/api/settings/performance-profile' -SaveAs 'performance-profile.json' -TimeoutSec 20)
    # /generate/budget so existe em versoes mais novas que a 0.5.6; o erro
    # fica registrado mas nao conta como problema.
    [void](Invoke-Api -Path '/generate/budget' -SaveAs 'budget.json' -TimeoutSec 10 -Tolerant)
    [void](Invoke-Api -Path '/v1/audio/voices'  -SaveAs 'voices.json')

    $engines = Invoke-Api -Path '/engines/tts' -SaveAs 'engines.json' -TimeoutSec 20
    if ($engines -and $engines.backends) {
        $avail = @($engines.backends | Where-Object { $_.available })
        Write-Ok "$($engines.backends.Count) motores; $($avail.Count) disponivel(is); ativo='$($engines.active)'"
        foreach ($e in $avail) {
            Write-Info "  $($e.id) -> device=$($e.effective_device) clone=$($e.supports_cloning) design=$($e.supports_voice_design)"
        }
    }

    # Sondagens de erro: provam que o contrato de falha e o esperado
    if ($curl) {
        try {
            $errBody = & $curl -s -o NUL -w "%{http_code}" -X POST "$BaseUrl/generate" `
                -F "text=teste" -F "engine=nao-existe" 2>$null
            "unknown engine -> HTTP $errBody" | Out-File (Join-Path $ApiDir 'error-unknown-engine.txt') -Encoding UTF8
            Write-Info "motor inexistente -> HTTP $errBody (esperado 400)"
        } catch { }
        try {
            $errBody2 = & $curl -s -o NUL -w "%{http_code}" -X POST "$BaseUrl/v1/audio/speech" `
                -H "Content-Type: application/json" `
                -d '{"model":"nao-existe","voice":"alloy","input":"teste","response_format":"wav"}' 2>$null
            "unknown model -> HTTP $errBody2" | Out-File (Join-Path $ApiDir 'error-unknown-model.txt') -Encoding UTF8
            Write-Info "modelo inexistente -> HTTP $errBody2 (esperado 400)"
        } catch { }
    }
}

# ------------------------------------------------------ [7/10] modelo TTS
Write-Step '7/10' "Garantindo o modelo TTS ($Model)"

$modelState = 'nao avaliado'
if ($NoModel) {
    $modelState = 'pulado por /nomodel'
    Write-Info 'download de modelo pulado por /nomodel'
} elseif (-not $apiStatus.reachable) {
    $modelState = 'api indisponivel'
    Write-Warn2 'API indisponivel - modelo nao pode ser garantido'
} else {
    Write-Info "modelo  : $Model"
    Write-Info 'tamanho : ~2.4 GB no primeiro download'
    Write-Info 'origem  : Hugging Face, via o proprio app'

    # Idempotente quando os pesos ja estao completos: o hf_hub reaproveita o cache.
    $start = Invoke-Post -Path '/models/install' -Body @{ repo_id = $Model; target = 'local' } -SaveAs 'model-install-start.json' -TimeoutSec 30
    if ($null -eq $start) {
        $modelState = 'pedido de instalacao falhou'
        Write-Warn2 'o pedido de download falhou; veja api/model-install-start.json'
    } else {
        Write-Info 'download iniciado; acompanhando /models/install/status'

        $deadline = (Get-Date).AddSeconds(2700)
        $started  = Get-Date
        $lastNote = ''
        $failed   = $false
        $done     = $false
        $seen     = $false
        $absent   = 0
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 5
            $st = Invoke-Api -Path '/models/install/status' -SaveAs 'model-install-status.json' -TimeoutSec 20
            if (-not $st) { continue }

            $job = $null
            if ($st.jobs) {
                $job = @($st.jobs | Where-Object { $_.repo_id -eq $Model }) | Select-Object -First 1
            }

            if ($job) {
                $seen   = $true
                $absent = 0
                $note = "estado=$($job.state)"
                if ($job.total_bytes -and ($null -ne $job.bytes_done)) {
                    $mb  = [math]::Round([double]$job.bytes_done / 1MB, 0)
                    $tot = [math]::Round([double]$job.total_bytes / 1MB, 0)
                    $note = "$note ${mb}/${tot} MB"
                }
                if ($job.files_total) {
                    $note = "$note arquivos=$($job.files_done)/$($job.files_total)"
                }
                if ($job.eta_seconds) {
                    $note = "$note eta=$([math]::Round([double]$job.eta_seconds,0))s"
                }
                if ($note -ne $lastNote) { Write-Info $note; $lastNote = $note }

                if ($job.state -eq 'failed') {
                    $failed = $true
                    if ($job.error) { Write-Fail "motivo: $($job.error)" }
                    break
                }
            } else {
                # O job sai da lista quando termina - e tambem pode ainda nao
                # ter aparecido. So concluimos apos algum tempo e duas leituras
                # seguidas sem job.
                $absent++
                $elapsed = ((Get-Date) - $started).TotalSeconds
                if ($elapsed -gt 20 -and $absent -ge 2) { $done = $true; break }
                if (-not $seen -and $elapsed -gt 120) { $done = $true; break }
            }
        }

        if ($failed) {
            $modelState = 'falhou'
            Write-Fail 'o download do modelo falhou; veja api/model-install-status.json'
        } elseif ($done) {
            $modelState = 'concluido'
            Write-Ok 'download do modelo concluido'
        } else {
            $modelState = 'timeout'
            Write-Warn2 'timeout acompanhando o download (45 min). Pode continuar em segundo plano.'
        }
    }

    $eng2 = Invoke-Api -Path '/engines/tts' -SaveAs 'engines-after-install.json' -TimeoutSec 20
    if ($eng2 -and $eng2.backends) {
        $om = @($eng2.backends | Where-Object { $_.id -eq 'omnivoice' }) | Select-Object -First 1
        if ($om) {
            if ($om.available) { Write-Ok "omnivoice disponivel (device=$($om.effective_device))" }
            else { Write-Warn2 "omnivoice ainda indisponivel: $($om.reason)" }
        }
    }
}

# A v0.5.6 NAO tem gate de licenca (o codigo daquela versao nao contem
# ensure_engine_licence). Em versoes mais novas o app pede um aceite antes de
# gerar; se o endpoint existir, registramos o mesmo aceite que o botao da
# interface registraria. Nunca e fatal.
if ($apiStatus.reachable) {
    # Na 0.5.6 o aceite e por MOTOR (settings_store), em
    # GET/POST /settings/license. O gate por modelo (/models/licenses) nao
    # existe nesta versao e /generate nao verifica aceite nenhum - por isso a
    # geracao funciona sem ninguem clicar em nada.
    $lic = Invoke-Api -Path '/settings/license/omnivoice' -SaveAs 'licence-state.json' -TimeoutSec 10 -Tolerant
    if ($null -eq $lic) {
        Write-Info 'sem endpoint de aceite de licenca (nada a fazer)'
    } elseif ($lic.accepted) {
        Write-Ok 'aceite de licenca do omnivoice registrado no app'
    } else {
        # Nao aceitamos por voce: aceitar CC-BY-NC e uma decisao sua.
        Write-Info 'aceite do omnivoice NAO registrado no app (nao bloqueia a geracao na 0.5.6)'
    }
}

# --------------------------------------------- [7b] motor GGUF (caminho Vulkan)
# Por que este passo existe: o motor padrao e PyTorch, e PyTorch nao tem
# backend Vulkan. O omnivoice-gguf roda omnivoice.cpp (GGML) - a mesma familia
# do llama.cpp - e o backend dele diz que o binario faz dlopen de ggml-vulkan
# "quando presente". Se esse for o caso no Windows, existe um caminho de GPU
# para portugues nesta placa. Este passo mede isso em vez de supor.
$ggufInfo = $null
if ($Gguf) {
    Write-Step '7b' 'Motor GGUF e backend Vulkan'

    $ggufInfo = [ordered]@{
        binary_found     = $false
        binary           = $null
        binary_bytes     = 0
        placeholders     = @()
        ggml_libs        = @()
        engine_available = $false
        engine_reason    = $null
        generated        = $false
        http             = $null
        gen_s            = $null
        audio_s          = $null
        rtf              = $null
        vulkan_lines     = @()
        verdict          = ''
    }

    # O binario fica em <raiz>\bin\omnivoice-tts-<slug>.exe (o modulo resolvel
    # assim: _REPO_ROOT = engines/omnivoice_gguf/../../..). No app empacotado
    # a raiz e a pasta resources.
    $binDirs = @()
    if ($appExe) {
        $appRoot = Split-Path -Parent $appExe
        $binDirs += (Join-Path $appRoot 'resources\bin')
        $binDirs += (Join-Path $appRoot 'resources\backend\engines\omnivoice_gguf\bin')
        $binDirs += (Join-Path $appRoot 'bin')
    }
    $binDirs += (Join-Path $RepoRoot 'lab\VoiceStudio\bin')

    foreach ($d in $binDirs) {
        if (-not (Test-Path $d)) { continue }
        Write-Info "procurando binario em $d"
        $files = @(Get-ChildItem -Path $d -File -ErrorAction SilentlyContinue)
        foreach ($f in $files) {
            if ($f.Name -like 'omnivoice-tts*') {
                $ggufInfo.binary       = $f.FullName
                $ggufInfo.binary_bytes = $f.Length
                if ($f.Length -gt 0) { $ggufInfo.binary_found = $true }
                else { $ggufInfo.placeholders += $f.FullName }
            }
            if ($f.Name -like 'ggml*') {
                $ggufInfo.ggml_libs += "$($f.Name) ($($f.Length) B)"
            }
        }
    }

    if ($ggufInfo.binary_found) {
        Write-Ok "binario: $($ggufInfo.binary) ($([math]::Round($ggufInfo.binary_bytes/1MB,1)) MB)"
    } elseif ($ggufInfo.binary) {
        Write-Warn2 'o binario existe mas tem 0 byte (placeholder de source checkout)'
    } else {
        Write-Warn2 'binario omnivoice-tts NAO encontrado neste build'
    }

    if ($ggufInfo.ggml_libs.Count -gt 0) {
        Write-Info ("bibliotecas ggml ao lado do binario: " + ($ggufInfo.ggml_libs -join '; '))
        $vk = @($ggufInfo.ggml_libs | Where-Object { $_ -like '*vulkan*' })
        if ($vk.Count -gt 0) { $ggufInfo.vulkan_hint = 'ggml-vulkan presente: ' + ($vk -join '; ') }
        else { $ggufInfo.vulkan_hint = 'nenhuma biblioteca ggml-vulkan ao lado do binario' }
    } else {
        $ggufInfo.vulkan_hint = 'nenhuma biblioteca ggml* encontrada'
        Write-Info $ggufInfo.vulkan_hint
    }

    $gg = $null
    if ($engines -and $engines.backends) {
        $gg = @($engines.backends | Where-Object { $_.id -eq 'omnivoice-gguf' }) | Select-Object -First 1
    }
    if ($gg) {
        $ggufInfo.engine_available = [bool]$gg.available
        $ggufInfo.engine_reason    = $gg.reason
        if ($gg.available) { Write-Ok 'o app considera o omnivoice-gguf disponivel' }
        else { Write-Warn2 "o app considera indisponivel: $($gg.reason)" }
    }

    # Tentativa de geracao. Sem a frase pronta, nao ha o que medir.
    $gCorpus = Join-Path $RepoRoot 'lab\reports\corpus\C6.txt'
    if ($ggufInfo.engine_available -and $apiStatus.reachable -and $curl -and (Test-Path $gCorpus)) {
        Write-Info 'gerando uma frase com engine=omnivoice-gguf (baixa os quants na 1a vez)'
        $gText = (Get-Content -Path $gCorpus -Raw -Encoding UTF8).Trim()
        $gTxtFile = Join-Path $AudioDir 'C6-gguf.text.txt'
        $utf8NoBomG = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($gTxtFile, $gText, $utf8NoBomG)

        $gWav = Join-Path $AudioDir 'C6-gguf.wav'
        $gHdr = Join-Path $AudioDir 'C6-gguf.headers.txt'
        $gArgs = @(
            '-s','-S','-o',$gWav,'-D',$gHdr,'-w','%{http_code};%{time_total}',
            '--max-time','1800','-X','POST',"$BaseUrl/generate",
            '-F',"text=<$gTxtFile",'-F','language=pt','-F','seed=42',
            '-F','engine=omnivoice-gguf'
        )
        $gRes = (& $curl @gArgs 2>$null | Out-String).Trim()
        $gParts = $gRes -split ';'
        $ggufInfo.http = $gParts[0]
        if ($gParts.Length -gt 1) { $ggufInfo.wall_s = $gParts[1] }

        if ($ggufInfo.http -eq '200') {
            $ggufInfo.generated = $true
            $hdrTxt = ''
            if (Test-Path $gHdr) { $hdrTxt = Get-Content -Path $gHdr -Raw -Encoding UTF8 }
            foreach ($line in ($hdrTxt -split "`n")) {
                $l = $line.Trim()
                if ($l -match '^(?i)x-gen-time:\s*(.+)$')  { $ggufInfo.gen_s   = [double]$Matches[1] }
                if ($l -match '^(?i)x-audio-duration:\s*(.+)$') { $ggufInfo.audio_s = [double]$Matches[1] }
            }
            if ($ggufInfo.gen_s -and $ggufInfo.audio_s -and $ggufInfo.audio_s -gt 0) {
                $ggufInfo.rtf = [math]::Round($ggufInfo.gen_s / $ggufInfo.audio_s, 3)
                Write-Ok "GGUF: gen=$($ggufInfo.gen_s)s audio=$($ggufInfo.audio_s)s RTF=$($ggufInfo.rtf)"
            } else {
                Write-Ok 'GGUF: HTTP 200, mas sem X-Gen-Time/X-Audio-Duration'
            }
        } else {
            Write-Warn2 "GGUF: HTTP $($ggufInfo.http) - veja C6-gguf.error.txt"
            if (Test-Path $gWav) {
                Move-Item -LiteralPath $gWav -Destination (Join-Path $AudioDir 'C6-gguf.error.txt') -Force
            }
        }
    } elseif (-not $ggufInfo.engine_available) {
        Write-Info 'geracao com GGUF pulada: o motor nao esta disponivel'
    }

    # O log do backend guarda o stderr do omnivoice-tts, que e onde o runtime
    # anuncia qual dispositivo escolheu.
    if ($apiStatus.reachable) {
        $logs = Invoke-Api -Path '/system/logs?tail=800' -SaveAs 'backend-logs.json' -TimeoutSec 20 -Tolerant
        if ($logs -and $logs.lines) {
            $ggufInfo.vulkan_lines = @($logs.lines | Where-Object { $_ -match '(?i)vulkan|ggml|offload|device|backend' } | Select-Object -Last 40)
            if ($ggufInfo.vulkan_lines.Count -gt 0) {
                Write-Info "linhas do log sobre dispositivo/backend: $($ggufInfo.vulkan_lines.Count)"
            }
        }
    }

    if ($ggufInfo.rtf) {
        $ggufInfo.verdict = "GGUF rodou. RTF=$($ggufInfo.rtf). Confira gguf.vulkan_lines para o dispositivo escolhido."
    } elseif ($ggufInfo.engine_available) {
        $ggufInfo.verdict = 'Motor disponivel, mas nao houve geracao concluida.'
    } else {
        $ggufInfo.verdict = "Motor indisponivel: $($ggufInfo.engine_reason)"
    }
    Write-Info "veredito: $($ggufInfo.verdict)"

    $ggufInfo | ConvertTo-Json -Depth 6 |
        Out-File -FilePath (Join-Path $OutDir 'gguf.json') -Encoding UTF8
}

# ----------------------------------------------- [7c] GPU real (Vulkan/audio.cpp)
# Por que este passo existe: o modo padrao prova que o caminho PyTorch e CPU.
# Mas a maquina tem uma RX 580 com 8 GB (o WMI reporta 4 GB e mente). O unico
# runtime do app que fala Vulkan de verdade e o audio.cpp, cujo binario do
# Windows e publicado como audio-v0.7.4-bin-windows-x64-vulkan.zip. Este passo
# mede a placa com ele. O modelo dele e en/zh: o RTF aqui mede a PLACA, nao o
# portugues - nao confunda os dois.
$gpuTest = $null
if ($Gpu) {
    Write-Step '7c' 'GPU real e Vulkan (audio.cpp)'

    $gpuTest = [ordered]@{
        vram_reportada_gb = $null
        adapters          = @()
        runtime_supported = $null
        runtime_installed = $false
        runtime_version   = $null
        server_exe        = $null
        devices_raw       = @()
        vulkan_gpu        = $false
        vram_real_gb      = $null
        model_installed   = $false
        model_path        = $null
        engine_available  = $null
        engine_routing    = $null
        engine_reason     = $null
        generated         = $false
        http              = $null
        gen_s             = $null
        audio_s           = $null
        rtf               = $null
        verdict           = ''
    }

    # --- VRAM real: o WMI (Win32_VideoController.AdapterRAM) satura em
    # 4.294.967.295 e reporta 4 GB em placas de 8. O registro guarda o valor
    # verdadeiro em HardwareInformation.qwMemorySize.
    $adapterKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    try {
        $subs = Get-ChildItem -Path $adapterKey -ErrorAction SilentlyContinue
        foreach ($s in $subs) {
            $pr = Get-ItemProperty -Path $s.PSPath -ErrorAction SilentlyContinue
            if (-not $pr -or -not $pr.DriverDesc) { continue }
            $raw = $pr.PSObject.Properties['HardwareInformation.qwMemorySize']
            $bytes = $null
            if ($raw -and $null -ne $raw.Value) {
                $v = $raw.Value
                if ($v -is [byte[]]) {
                    # algumas versoes do PowerShell devolvem REG_QWORD como byte[]
                    $acc = [uint64]0
                    for ($bi = $v.Length - 1; $bi -ge 0; $bi--) { $acc = ($acc * 256) + [uint64]$v[$bi] }
                    $bytes = $acc
                } else {
                    $bytes = [uint64]$v
                }
            }
            $gb = $null
            if ($bytes -and $bytes -gt 0) { $gb = [math]::Round([double]$bytes / 1GB, 2) }
            $gpuTest.adapters += [ordered]@{ name = $pr.DriverDesc; vram_gb = $gb; vram_bytes = $bytes }
            if ($pr.DriverDesc -match 'Radeon|GeForce|Arc') {
                if ($gb -and (-not $gpuTest.vram_real_gb -or $gb -gt $gpuTest.vram_real_gb)) {
                    $gpuTest.vram_real_gb = $gb
                }
            }
        }
    } catch {
        Write-Warn2 "nao consegui ler o registro de video: $($_.Exception.Message)"
    }

    foreach ($a in $gpuTest.adapters) {
        if ($a.vram_gb) { Write-Info "$($a.name): $($a.vram_gb) GB de VRAM (registro)" }
        else { Write-Info "$($a.name): VRAM nao informada pelo driver" }
    }
    if ($gpuTest.vram_real_gb) {
        Write-Ok "VRAM real detectada: $($gpuTest.vram_real_gb) GB"
        Write-Info 'o valor de 4 GB que o WMI devolve e saturacao do campo AdapterRAM, nao a placa'
    }

    # --- runtime do audio.cpp (binario Vulkan, ~57 MB)
    $ac = Invoke-Api -Path '/engines/audiocpp/runtime/install/status' -SaveAs 'audiocpp-status.json' -TimeoutSec 20 -Tolerant
    if ($ac) {
        $gpuTest.runtime_supported = [bool]$ac.supported
        $gpuTest.runtime_installed = [bool]$ac.installed
        Write-Info "runtime audio.cpp: suportado=$($ac.supported) instalado=$($ac.installed) plataforma=$($ac.platform)"
    } else {
        Write-Warn2 'endpoint do runtime audio.cpp indisponivel'
    }

    if ($gpuTest.runtime_supported -and -not $gpuTest.runtime_installed) {
        Write-Info 'baixando o runtime nativo (audio-v0.7.4-bin-windows-x64-vulkan.zip, ~57 MB)'
        $startAc = Invoke-Post -Path '/engines/audiocpp/runtime/install' -Body @{} -SaveAs 'audiocpp-install.json' -TimeoutSec 60
        if ($startAc) {
            $acDeadline = (Get-Date).AddSeconds(900)
            $acLast = -1
            while ((Get-Date) -lt $acDeadline) {
                Start-Sleep -Seconds 4
                $st2 = Invoke-Api -Path '/engines/audiocpp/runtime/install/status' -SaveAs 'audiocpp-status.json' -TimeoutSec 20 -Tolerant
                if (-not $st2) { continue }
                $job = $st2.job
                if ($job -and $null -ne $job.progress) {
                    $pc = [int]([double]$job.progress * 100)
                    if ($pc -ge $acLast + 20) { Write-Info "runtime: $pc%"; $acLast = $pc }
                }
                if ($st2.installed) { $gpuTest.runtime_installed = $true; break }
                if ($job -and $job.state -eq 'error') {
                    Write-Fail "instalacao do runtime falhou: $($job.error)"
                    break
                }
            }
        } else {
            Write-Warn2 'nao consegui iniciar a instalacao do runtime (veja audiocpp-install.json)'
        }
    }

    if ($gpuTest.runtime_installed) {
        $st3 = Invoke-Api -Path '/engines/audiocpp/runtime/install/status' -SaveAs 'audiocpp-status.json' -TimeoutSec 20 -Tolerant
        if ($st3) { $gpuTest.runtime_version = $st3.version }
        Write-Ok "runtime audio.cpp pronto (versao $($gpuTest.runtime_version))"
    }

    # --- o binario e procurado NO DISCO, nao na API.
    # Motivo: numa execucao em que a API nao subiu, o runtime ja instalado
    # continua no disco - e e justamente ele que permite medir a placa sem
    # depender do app. Procurar so dentro do "if instalado pela API" tornava a
    # medicao refem de um endpoint que estava fora do ar.
    if (-not $gpuTest.server_exe) {
        $acDirs = @(
            (Join-Path $env:APPDATA 'OmniVoice\engines\audio-cpp'),
            (Join-Path $env:APPDATA 'omnivoice\engines\audio-cpp'),
            (Join-Path $env:LOCALAPPDATA 'OmniVoice\engines\audio-cpp'),
            (Join-Path $env:LOCALAPPDATA 'omnivoice\engines\audio-cpp')
        )
        foreach ($d in $acDirs) {
            if (-not (Test-Path $d)) { continue }
            $hit = Get-ChildItem -Path $d -Recurse -Filter 'audiocpp_server.exe' -ErrorAction SilentlyContinue |
                   Select-Object -First 1
            if ($hit) { $gpuTest.server_exe = $hit.FullName; break }
        }
        if ($gpuTest.server_exe) {
            $gpuTest.runtime_installed = $true
            if (-not $gpuTest.runtime_version) {
                $verDir = Split-Path (Split-Path $gpuTest.server_exe -Parent) -Parent
                $gpuTest.runtime_version = (Split-Path $verDir -Leaf) + ' (do disco)'
            }
            Write-Info "runtime encontrado no disco, sem passar pela API"
        }
    }

    if ($gpuTest.server_exe) {
        Write-Info "binario: $($gpuTest.server_exe)"
        Write-Info 'executando --list-devices (o runtime enumera os backends)'
        try {
            # o binario escreve a lista no stderr; sem cmd /c o PowerShell
            # transforma isso em NativeCommandError e polui a evidencia
            $devOut = (& cmd /c "`"$($gpuTest.server_exe)`" --list-devices 2>&1" | Out-String)
            $gpuTest.devices_raw = @($devOut -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
            foreach ($l in $gpuTest.devices_raw) { Write-Info "  $($l.Trim())" }
            $vkLines = @($gpuTest.devices_raw | Where-Object { $_ -match '(?i)^\s*Vulkan\s*:' })
            if ($vkLines.Count -gt 0) {
                $gpuTest.vulkan_gpu = $true
                Write-Ok "Vulkan enumerou $($vkLines.Count) dispositivo(s) nesta maquina"
            } else {
                Write-Warn2 'nenhum dispositivo Vulkan na lista - a GPU nao esta exposta ao runtime'
            }
        } catch {
            Write-Warn2 "falha ao executar --list-devices: $($_.Exception.Message)"
        }
    } else {
        Write-Warn2 'audiocpp_server.exe nao encontrado no disco - rode sem /nomodel e com a API no ar'
    }

    # --- modelo e geracao: so paga os 4,98 GB se houver Vulkan de verdade
    if ($gpuTest.vulkan_gpu -and -not $NoModel -and -not $apiStatus.reachable) {
        Write-Info 'API fora do ar: o download do modelo so pode ser disparado por ela'
        Write-Info 'mas o passo [7d] procura no disco o GGUF ja instalado e mede sem a API'
    } elseif ($gpuTest.vulkan_gpu -and -not $NoModel) {
        Write-Info 'baixando o bundle Breeze-TTS-2 + Sortformer (4,98 GB, en/zh)'
        $mStart = Invoke-Post -Path '/models/install' -Body @{ repo_id = 'audio-cpp/audio.cpp-gguf'; target = 'local' } -SaveAs 'audiocpp-model-start.json' -TimeoutSec 30
        if ($mStart) {
            $mDeadline = (Get-Date).AddSeconds(3600)
            $mLast = -1; $mSeen = $false; $mAbsent = 0; $mStartAt = Get-Date
            while ((Get-Date) -lt $mDeadline) {
                Start-Sleep -Seconds 10
                $ms = Invoke-Api -Path '/models/install/status' -SaveAs 'audiocpp-model-status.json' -TimeoutSec 20 -Tolerant
                if (-not $ms) { continue }
                $mj = $null
                if ($ms.jobs) { $mj = @($ms.jobs | Where-Object { $_.repo_id -eq 'audio-cpp/audio.cpp-gguf' }) | Select-Object -First 1 }
                if ($mj) {
                    $mSeen = $true; $mAbsent = 0
                    if ($mj.total_bytes -and ($null -ne $mj.bytes_done)) {
                        $mb = [math]::Round([double]$mj.bytes_done / 1MB, 0)
                        $tb = [math]::Round([double]$mj.total_bytes / 1MB, 0)
                        $pc2 = [int](100 * [double]$mj.bytes_done / [double]$mj.total_bytes)
                        if ($pc2 -ge $mLast + 10) { Write-Info "modelo: $mb/$tb MB ($pc2%)"; $mLast = $pc2 }
                    }
                    if ($mj.state -eq 'failed') { Write-Fail "download falhou: $($mj.error)"; break }
                } else {
                    # o job sai da lista quando termina - quem diz se instalou
                    # de verdade e o catalogo, nao a ausencia do job
                    $mAbsent++
                    $el = ((Get-Date) - $mStartAt).TotalSeconds
                    if (($el -gt 20 -and $mAbsent -ge 2) -or (-not $mSeen -and $el -gt 120)) { break }
                }
            }
            # verificacao independente: o catalogo lista o que esta no disco
            $cat = Invoke-Api -Path '/models' -SaveAs 'audiocpp-models.json' -TimeoutSec 60 -Tolerant
            if ($cat -and $cat.models) {
                $mine = @($cat.models | Where-Object { $_.repo_id -eq 'audio-cpp/audio.cpp-gguf' }) | Select-Object -First 1
                if ($mine) {
                    $gpuTest.model_installed = [bool]($mine.installed -and -not $mine.incomplete)
                    $gbOnDisk = [math]::Round([double]$mine.size_on_disk_bytes / 1GB, 2)
                    if ($gpuTest.model_installed) {
                        Write-Ok "modelo instalado: $gbOnDisk GB no disco"
                    } else {
                        Write-Warn2 "modelo NAO esta completo ($gbOnDisk GB no disco, incomplete=$($mine.incomplete))"
                    }
                }
            }
            if (-not $gpuTest.model_installed) { Write-Warn2 'sem modelo completo, a geracao Vulkan sera pulada' }

            # o engine so passa a existir quando runtime E modelo estao no lugar;
            # a lista de motores foi lida antes disso, entao reconsulta
            $eng2 = Invoke-Api -Path '/engines/tts' -SaveAs 'engines-after-audiocpp.json' -TimeoutSec 60 -Tolerant
            if ($eng2 -and $eng2.backends) {
                $acEng = @($eng2.backends | Where-Object { $_.id -eq 'audiocpp' }) | Select-Object -First 1
                if ($acEng) {
                    $gpuTest.engine_available = [bool]$acEng.available
                    $gpuTest.engine_routing = $acEng.routing_status
                    $gpuTest.engine_reason = $acEng.reason
                    if ($acEng.available) { Write-Ok "engine audiocpp agora disponivel (device $($acEng.effective_device), routing $($acEng.routing_status))" }
                    else { Write-Warn2 "engine audiocpp AINDA indisponivel: $($acEng.reason)" }
                }
            }
        }
    } elseif (-not $gpuTest.vulkan_gpu) {
        Write-Info 'modelo de 4,98 GB NAO sera baixado: sem Vulkan enumerado, nao ha o que medir'
    }

    if ($gpuTest.model_installed -and $apiStatus.reachable -and $curl) {
        $enText = 'The quick brown fox jumps over the lazy dog. Today is October 23, 2026, and the temperature is 21 degrees.'
        $enFile = Join-Path $AudioDir 'gpu-test.text.txt'
        $utf8NoBomG2 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($enFile, $enText, $utf8NoBomG2)
        $gWav2 = Join-Path $AudioDir 'gpu-vulkan.wav'
        $gHdr2 = Join-Path $AudioDir 'gpu-vulkan.headers.txt'
        Write-Info 'gerando com engine=audiocpp (texto em ingles) e medindo o RTF'
        $a2 = @(
            '-s','-S','-o',$gWav2,'-D',$gHdr2,'-w','%{http_code};%{time_total}',
            '--max-time','3600','-X','POST',"$BaseUrl/generate",
            '-F',"text=<$enFile",'-F','language=en','-F','seed=42','-F','engine=audiocpp'
        )
        $r2 = (& $curl @a2 2>$null | Out-String).Trim()
        $p2 = $r2 -split ';'
        $gpuTest.http = $p2[0]
        if ($gpuTest.http -eq '200') {
            $gpuTest.generated = $true
            if (Test-Path $gHdr2) {
                foreach ($line in ((Get-Content -Path $gHdr2 -Raw -Encoding UTF8) -split "`n")) {
                    $l2 = $line.Trim()
                    if ($l2 -match '^(?i)x-gen-time:\s*(.+)$') { $gpuTest.gen_s = [double]$Matches[1] }
                    if ($l2 -match '^(?i)x-audio-duration:\s*(.+)$') { $gpuTest.audio_s = [double]$Matches[1] }
                }
            }
            if ($gpuTest.gen_s -and $gpuTest.audio_s -and $gpuTest.audio_s -gt 0) {
                $gpuTest.rtf = [math]::Round($gpuTest.gen_s / $gpuTest.audio_s, 3)
                Write-Ok "Vulkan: gen=$($gpuTest.gen_s)s audio=$($gpuTest.audio_s)s RTF=$($gpuTest.rtf)"
            } else {
                Write-Ok 'Vulkan: HTTP 200, mas sem X-Gen-Time/X-Audio-Duration'
            }
        } else {
            Write-Warn2 "geracao Vulkan falhou: HTTP $($gpuTest.http)"
            if (Test-Path $gWav2) { Move-Item -LiteralPath $gWav2 -Destination (Join-Path $AudioDir 'gpu-vulkan.error.txt') -Force }
        }
    }

    if ($gpuTest.rtf) {
        $gpuTest.verdict = "HTTP 200 com RTF=$($gpuTest.rtf). ATENCAO: esta requisicao passa pela API do app e a resposta nao diz qual motor a atendeu - se o engine audiocpp estivesse indisponivel, o app teria caido no motor ativo. Numero NAO atribuivel sem o passo [7d]."
    } elseif ($gpuTest.vulkan_gpu) {
        $gpuTest.verdict = 'Vulkan enumerou a placa, mas nao houve geracao concluida.'
    } elseif ($gpuTest.runtime_installed) {
        $gpuTest.verdict = 'Runtime instalado, porem nenhum dispositivo Vulkan enumerado.'
    } else {
        $gpuTest.verdict = 'Runtime audio.cpp nao instalado.'
    }
    Write-Info "veredito: $($gpuTest.verdict)"

    $gpuTest | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $OutDir 'gpu.json') -Encoding UTF8
}

# ------------------------------------- [7d] Vulkan vs CPU (medicao pareada)
# Por que este passo existe: o RTF do [7c] passa pela API do app, inclui a
# carga do modelo e a compilacao de shaders dentro da mesma requisicao, e -
# pior - nao diz qual motor atendeu. Para responder "a placa e mais rapida que
# o Ryzen?" e preciso o mesmo binario, o mesmo modelo, o mesmo texto, o mesmo
# seed, primeiro pedido descartado. Este passo sobe o audiocpp_server duas
# vezes (--backend vulkan e --backend cpu) e mede os dois.
$gpuPair = $null
if ($Gpu -and $gpuTest -and $gpuTest.server_exe) {
    Write-Step '7d' 'Vulkan vs CPU (medicao pareada)'

    function Get-WavInfo {
        param([byte[]]$Bytes)
        if (-not $Bytes -or $Bytes.Length -lt 44) { return $null }
        $ch   = [int]$Bytes[22] + ([int]$Bytes[23] -shl 8)
        $sr   = [int]$Bytes[24] + ([int]$Bytes[25] -shl 8) + ([int]$Bytes[26] -shl 16) + ([int]$Bytes[27] -shl 24)
        $bits = [int]$Bytes[34] + ([int]$Bytes[35] -shl 8)
        $i = 12
        while ($i + 8 -le $Bytes.Length) {
            $id = -join @([char]$Bytes[$i], [char]$Bytes[$i+1], [char]$Bytes[$i+2], [char]$Bytes[$i+3])
            $sz = [int]$Bytes[$i+4] + ([int]$Bytes[$i+5] -shl 8) + ([int]$Bytes[$i+6] -shl 16) + ([int]$Bytes[$i+7] -shl 24)
            if ($id -eq 'data') {
                $frame = $ch * ($bits / 8)
                if ($sr -gt 0 -and $frame -gt 0) {
                    return [ordered]@{ sr = $sr; ch = $ch; bits = $bits; seconds = [math]::Round($sz / ($sr * $frame), 2) }
                }
                return $null
            }
            $i += 8 + $sz + ($sz % 2)
        }
        return $null
    }

    # --- localizar o GGUF instalado (o mesmo arquivo que o app baixou)
    # O app usa DATA_DIR/hf_cache; o padrao do huggingface_hub e ~/.cache.
    # Procura nos dois, aceita qualquer quantizacao e fica com o maior arquivo.
    $ggufPath = $null
    $ggufCandidates = @()
    $hubRoots = @(
        (Join-Path $env:LOCALAPPDATA 'OmniVoice\hf_cache'),
        (Join-Path $env:LOCALAPPDATA 'omnivoice\hf_cache'),
        (Join-Path $env:APPDATA 'OmniVoice\hf_cache'),
        (Join-Path $env:USERPROFILE '.cache\huggingface\hub')
    )
    foreach ($root in $hubRoots) {
        if (-not (Test-Path $root)) { continue }
        $hits = Get-ChildItem -Path $root -Recurse -Filter 'breeze-tts-2-*.gguf' -ErrorAction SilentlyContinue
        if ($hits) { $ggufCandidates += $hits }
    }
    if ($ggufCandidates.Count -gt 0) {
        $best = $ggufCandidates | Sort-Object Length -Descending | Select-Object -First 1
        $ggufPath = $best.FullName
        Write-Info ("GGUF encontrado: {0} ({1} GB)" -f $best.Name, [math]::Round($best.Length / 1GB, 2))
    }

    if (-not $ggufPath) {
        Write-Warn2 'GGUF do Breeze nao encontrado em cache - medicao pareada pulada'
    } else {
        Write-Info "modelo: $ggufPath"
        # achado no disco: vale como "instalado", independente da API
        $gpuTest.model_installed = $true
        $gpuTest.model_path = $ggufPath

        $pairText = 'The quick brown fox jumps over the lazy dog. Today is October 23, 2026, and the temperature is 21 degrees.'
        $pairSha = [System.Security.Cryptography.SHA256]::Create()
        $pairHash = ($pairSha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($pairText)) |
                     ForEach-Object { $_.ToString('x2') }) -join ''
        $pairFile = Join-Path $AudioDir 'gpu-paired.text.txt'
        $utf8NoBomP = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($pairFile, $pairText, $utf8NoBomP)

        $gpuPair = [ordered]@{
            model_path    = $ggufPath
            text_sha256   = $pairHash
            seed          = 42
            runs_measured = 3
            warmup_runs   = 1
            backends      = [ordered]@{}
            speedup_cpu_over_vulkan = $null
            verdict       = ''
        }

        $portOffset = 0
        foreach ($bk in @('vulkan', 'cpu')) {
            $port = 17871 + $portOffset
            $portOffset++
            $rec = [ordered]@{
                backend = $bk; port = $port; started = $false; pid = $null
                requests = @(); rtf_median = $null; rtf_min = $null; rtf_max = $null
                error = $null
            }
            $proc = $null
            try {
                $cfgPath = Join-Path $OutDir ("audiocpp-{0}.json" -f $bk)
                $threads = 1
                if ($bk -eq 'cpu') { $threads = 8 }
                $cfg = [ordered]@{
                    host = '127.0.0.1'; port = $port; backend = $bk; device = 0
                    threads = $threads; lazy_load = $true; max_loaded_models = 1
                    models = @([ordered]@{
                        id = 'breeze-tts-2'; family = 'breeze_tts'; path = $ggufPath
                        task = 'tts'; mode = 'offline'
                    })
                }
                $cfg | ConvertTo-Json -Depth 8 | Out-File -FilePath $cfgPath -Encoding ASCII
                $soLog = Join-Path $OutDir ("audiocpp-{0}.out.log" -f $bk)
                $seLog = Join-Path $OutDir ("audiocpp-{0}.err.log" -f $bk)

                $proc = Start-Process -FilePath $gpuTest.server_exe `
                    -ArgumentList @('--config', "`"$cfgPath`"") -PassThru -WindowStyle Hidden `
                    -RedirectStandardOutput $soLog -RedirectStandardError $seLog
                $rec.pid = $proc.Id
                Write-Info "[$bk] audiocpp_server na porta $port (pid $($proc.Id))"

                $base = "http://127.0.0.1:$port"
                $ready = $false
                $deadline = (Get-Date).AddSeconds(180)
                while ((Get-Date) -lt $deadline) {
                    if ($proc.HasExited) { break }
                    try {
                        $null = Invoke-RestMethod -Uri "$base/health" -TimeoutSec 3 -UseBasicParsing
                        $ready = $true; break
                    } catch { Start-Sleep -Seconds 2 }
                }

                if (-not $ready) {
                    $tail = ''
                    if (Test-Path $seLog) { $tail = ((Get-Content -Path $seLog -Raw -ErrorAction SilentlyContinue) -split "`n" | Select-Object -Last 3) -join ' ' }
                    $rec.error = "servidor nao respondeu em /health. $tail"
                    Write-Warn2 "[$bk] $($rec.error)"
                } else {
                    $rec.started = $true
                    $body = ([ordered]@{ model = 'breeze-tts-2'; input = $pairText; response_format = 'json'; seed = 42 } | ConvertTo-Json -Compress)
                    # 1 aquecimento (carga dos 4,7 GB + shaders) + 3 medicoes
                    for ($rn = 1; $rn -le 4; $rn++) {
                        $sw = [Diagnostics.Stopwatch]::StartNew()
                        try {
                            $resp = Invoke-RestMethod -Uri "$base/v1/audio/speech" -Method Post -Body $body `
                                    -ContentType 'application/json' -TimeoutSec 1800
                        } catch {
                            $sw.Stop()
                            $rec.error = "requisicao $rn falhou: $($_.Exception.Message)"
                            Write-Warn2 "[$bk] $($rec.error)"
                            break
                        }
                        $sw.Stop()
                        $wavB = [Convert]::FromBase64String($resp.audio)
                        $wi = Get-WavInfo -Bytes $wavB
                        $item = [ordered]@{
                            run = $rn; warmup = ($rn -eq 1)
                            wall_s = [math]::Round($sw.Elapsed.TotalSeconds, 2)
                            audio_s = $null; sample_rate = $null; rtf = $null
                        }
                        if ($wi) { $item.audio_s = $wi.seconds; $item.sample_rate = $wi.sr }
                        if ($item.audio_s -and $item.audio_s -gt 0) {
                            $item.rtf = [math]::Round($item.wall_s / $item.audio_s, 3)
                        }
                        $rec.requests += $item
                        if ($rn -ge 2) {
                            [System.IO.File]::WriteAllBytes((Join-Path $AudioDir ("gpu-paired-{0}-r{1}.wav" -f $bk, $rn)), $wavB)
                        }
                        Write-Info ("[{0}] r{1}: parede {2}s / audio {3}s / RTF {4}" -f $bk, $rn, $item.wall_s, $item.audio_s, $item.rtf)
                    }
                    $meas = @($rec.requests | Where-Object { (-not $_.warmup) -and $_.rtf })
                    if ($meas.Count -gt 0) {
                        $rtfs = @($meas | ForEach-Object { [double]$_.rtf } | Sort-Object)
                        $rec.rtf_median = [math]::Round($rtfs[[int][math]::Floor($rtfs.Count / 2)], 3)
                        $rec.rtf_min = $rtfs[0]
                        $rec.rtf_max = $rtfs[$rtfs.Count - 1]
                        Write-Ok "[$bk] RTF mediano $($rec.rtf_median) (min $($rec.rtf_min), max $($rec.rtf_max))"
                    }
                }
            } catch {
                $rec.error = $_.Exception.Message
                Write-Warn2 "[$bk] $($rec.error)"
            } finally {
                if ($proc -and (-not $proc.HasExited)) {
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                }
            }
            $gpuPair.backends[$bk] = $rec
        }

        $vRec = $gpuPair.backends['vulkan']
        $cRec = $gpuPair.backends['cpu']
        if ($vRec.rtf_median -and $cRec.rtf_median -and $vRec.rtf_median -gt 0) {
            $gpuPair.speedup_cpu_over_vulkan = [math]::Round($cRec.rtf_median / $vRec.rtf_median, 2)
            $gpuPair.verdict = "Mesmo binario e modelo: Vulkan RTF $($vRec.rtf_median), CPU RTF $($cRec.rtf_median). A placa e $($gpuPair.speedup_cpu_over_vulkan)x mais rapida em ingles."
            Write-Ok $gpuPair.verdict
        } elseif ($vRec.rtf_median) {
            $gpuPair.verdict = "Vulkan mediu RTF $($vRec.rtf_median), mas o lado CPU nao completou - sem comparacao."
            Write-Warn2 $gpuPair.verdict
        } else {
            $gpuPair.verdict = 'Nao houve medicao pareada valida.'
            Write-Warn2 $gpuPair.verdict
        }
        $gpuPair | ConvertTo-Json -Depth 8 | Out-File -FilePath (Join-Path $OutDir 'gpu-paired.json') -Encoding UTF8
    }
}

# ------------------------------------------------------------- [8/10] geracao
Write-Step '8/10' 'Geracao de voz (corpus pt-BR)'

$corpusDir = Join-Path $RepoRoot 'lab\reports\corpus'
$corpusFiles = @()
if (Test-Path $corpusDir) {
    $corpusFiles = Get-ChildItem -Path $corpusDir -Filter 'C*.txt' | Sort-Object {
        [int]($_.BaseName -replace 'C','')
    }
}

if (-not $corpusFiles) {
    Write-Warn2 "corpus nao encontrado em $corpusDir"
} elseif (-not $apiStatus.reachable) {
    Write-Warn2 'API indisponivel - geracao pulada'
} elseif (-not $curl) {
    Write-Warn2 'curl ausente - geracao pulada'
} else {
    $plan = @()
    if ($Full) {
        foreach ($f in $corpusFiles) { $plan += @{ file = $f; rep = 1 } }
        $c7 = $corpusFiles | Where-Object { $_.BaseName -eq 'C7' }
        if ($c7) { foreach ($i in 2..4) { $plan += @{ file = $c7; rep = $i } } }
    } elseif ($Voice) {
        foreach ($f in $corpusFiles) { $plan += @{ file = $f; rep = 1 } }
    } else {
        # Duas execucoes: a primeira e descartada como aquecimento. Medir so a
        # primeira mede o carregamento dos pesos (2,4 GB), nao o motor - tres
        # coletas com a mesma frase deram 40 s, 173 s e 39 s justamente por isso.
        $c6 = $corpusFiles | Where-Object { $_.BaseName -eq 'C6' }
        $pick = if ($c6) { $c6 } else { $corpusFiles[0] }
        $plan += @{ file = $pick; rep = 1 }
        $plan += @{ file = $pick; rep = 2 }
    }

    Write-Info "$($plan.Count) geracao(oes) planejada(s)"
    if (-not $Engine) { Write-Info 'motor: o que estiver ativo no app' } else { Write-Info "motor: $Engine" }

    $n = 0
    foreach ($item in $plan) {
        $n++
        $f      = $item.file
        $text   = (Get-Content -Path $f.FullName -Raw -Encoding UTF8).Trim()
        $tag    = "$($f.BaseName)-r$($item.rep)"
        $wav    = Join-Path $AudioDir "$tag.wav"
        $hdr    = Join-Path $AudioDir "$tag.headers.txt"
        $bodyTxt= Join-Path $AudioDir "$tag.error.txt"

        if (Test-Path $wav)     { Remove-Item $wav -Force -ErrorAction SilentlyContinue }
        if (Test-Path $hdr)     { Remove-Item $hdr -Force -ErrorAction SilentlyContinue }
        if (Test-Path $bodyTxt) { Remove-Item $bodyTxt -Force -ErrorAction SilentlyContinue }

        # Texto vai por ARQUIVO, nao como argumento: no PowerShell 5.1 um
        # argumento com acento pode ser reencodado pela code page do console
        # e chegar corrompido ao servidor. curl -F "campo=<arquivo" le os
        # bytes crus. UTF-8 SEM BOM (Out-File do 5.1 grava BOM).
        $textFile = Join-Path $AudioDir "$tag.text.txt"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($textFile, $text, $utf8NoBom)

        $curlArgs = @(
            '-s','-S','-o',$wav,'-D',$hdr,
            '-w','%{http_code};%{time_total}',
            '-X','POST',"$BaseUrl/generate",
            "-F","text=<$textFile",'-F','language=pt','-F','seed=42','-F','wav_bits=16'
        )
        if ($Engine) { $curlArgs += @('-F',"engine=$Engine") }

        Write-Host "     [$n/$($plan.Count)] $tag ... " -NoNewline -ForegroundColor Gray
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $res = (& $curl @curlArgs 2>$null | Out-String).Trim()
        $sw.Stop()

        $code = ''; $tsec = ''
        if ($res -match '^(\d+);([\d\.,]+)$') {
            $code = $matches[1]
            $tsec = [double](($matches[2]) -replace ',','.')
        }
        $bytes = 0; if (Test-Path $wav) { $bytes = (Get-Item $wav).Length }

        # Se nao for 200, o corpo e um erro JSON: renomeia para .txt
        if ($code -and $code -ne '200' -and (Test-Path $wav)) {
            Move-Item -Path $wav -Destination $bodyTxt -Force -ErrorAction SilentlyContinue
            $bytes = 0
        }

        $dur = ''; $genTime = ''; $routing = ''; $routingReason = ''
        if (Test-Path $hdr) {
            foreach ($line in (Get-Content $hdr -Encoding UTF8)) {
                if ($line -match '^X-Audio-Duration:\s*(.+)$')      { $dur = $matches[1].Trim() }
                if ($line -match '^X-Gen-Time:\s*(.+)$')            { $genTime = $matches[1].Trim() }
                if ($line -match '^X-OmniVoice-Routing:\s*(.+)$')   { $routing = $matches[1].Trim() }
                if ($line -match '^X-OmniVoice-Routing-Reason:\s*(.+)$') { $routingReason = $matches[1].Trim() }
            }
        }

        $rtf = ''
        if ($genTime -and $dur -and [double]$dur -gt 0) {
            $rtf = [math]::Round([double]$genTime / [double]$dur, 3)
        }

        if ($code -eq '200' -and $bytes -gt 0) {
            Write-Host "OK  ${tsec}s  audio=${dur}s  gen=${genTime}s  rtf=$rtf" -ForegroundColor Green
            if ($routing) { Write-Info "     routing: $routing $routingReason" }
        } else {
            Write-Host "HTTP $code (sem audio)" -ForegroundColor Yellow
            if (Test-Path $bodyTxt) {
                $errText = (Get-Content $bodyTxt -Raw -Encoding UTF8)
                Write-Info "     $($errText.Substring(0, [Math]::Min(220, $errText.Length)))"
                if ($errText -match 'model_licence_required') {
                    Write-Warn2 "Licenca nao aceita. Abra o VoiceStudio > Model Catalogue, aceite a licenca do motor e rode de novo."
                }
                if ($errText -match 'HF_AUTH_FAILED|couldn') {
                    Write-Warn2 "Falha ao baixar pesos (rede/proxy/Hugging Face). Verifique a conexao do app."
                }
            }
        }

        $engineLabel = 'active'
        if ($Engine) { $engineLabel = $Engine }
        $fileName = "$tag.error.txt"
        if ($bytes -gt 0) { $fileName = "$tag.wav" }
        [void]$script:Rows.Add([pscustomobject]@{
            run             = $n
            corpus          = $f.BaseName
            repetition      = $item.rep
            engine          = $engineLabel
            http            = $code
            wall_time_s     = $tsec
            audio_duration_s= $dur
            server_gen_s    = $genTime
            rtf             = $rtf
            routing         = $routing
            routing_reason  = $routingReason
            wav_bytes       = $bytes
            file            = $fileName
        })
    }

    $script:Rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Ok "medicoes salvas em measurements.csv"
}

# ------------------------------------------------------------- [9/10] resumo
Write-Step '9/10' 'Escrevendo o resumo'

$sum = New-Object System.Text.StringBuilder
function Add-Line { param([string]$t = '') [void]$sum.AppendLine($t) }

Add-Line "# Coleta do laboratorio - $env:COMPUTERNAME"
Add-Line ""
Add-Line "Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') pelo coletor v$ScriptVersion."
Add-Line ""
Add-Line "## Ambiente"
Add-Line ""
Add-Line '```'
foreach ($l in $hwLines) { Add-Line $l }
Add-Line '```'
Add-Line ""
Add-Line "## VoiceStudio"
Add-Line ""
Add-Line "- App instalado: **$appState**"
if ($appExe) { Add-Line "- Executavel: ``$appExe``" }
Add-Line "- Modelo TTS: **$modelState**"
Add-Line "- API respondeu: **$($apiStatus.reachable)**"
if ($apiStatus.reachable) {
    Add-Line "- Versao: ``$($apiStatus.version)``"
    Add-Line "- Dispositivo efetivo: ``$($apiStatus.device)``"
}
if ($Gpu -and $gpuTest) {
    Add-Line ""
    Add-Line "## GPU real (Vulkan / audio.cpp)"
    Add-Line ""
    Add-Line "- VRAM real pelo registro: **$($gpuTest.vram_real_gb) GB** (WMI reporta 4 GB por saturacao)"
    foreach ($ad in $gpuTest.adapters) {
        if ($ad.vram_gb) { Add-Line "  - $($ad.name): $($ad.vram_gb) GB" }
        else { Add-Line "  - $($ad.name): VRAM nao informada pelo driver" }
    }
    Add-Line "- Runtime audio.cpp instalado: **$($gpuTest.runtime_installed)** (versao $($gpuTest.runtime_version))"
    Add-Line "- Vulkan enumerou GPU: **$($gpuTest.vulkan_gpu)**"
    if ($gpuTest.devices_raw.Count -gt 0) {
        Add-Line ""
        Add-Line "Dispositivos vistos pelo runtime:"
        Add-Line ""
        Add-Line '```'
        foreach ($l in $gpuTest.devices_raw) { Add-Line $l.Trim() }
        Add-Line '```'
    }
    Add-Line "- Modelo Breeze-TTS-2 instalado: $($gpuTest.model_installed)"
    if ($gpuTest.model_path) { Add-Line "  - arquivo: ``$($gpuTest.model_path)``" }
    Add-Line "- Geracao de teste: $($gpuTest.generated) (HTTP $($gpuTest.http))"
    if ($gpuTest.rtf) { Add-Line "- **RTF em Vulkan: $($gpuTest.rtf)** (gen $($gpuTest.gen_s)s / audio $($gpuTest.audio_s)s)" }
    Add-Line "- Engine audiocpp disponivel depois da instalacao: $($gpuTest.engine_available) (routing $($gpuTest.engine_routing))"
    Add-Line "- Veredito: $($gpuTest.verdict)"
}
if ($Gpu -and $gpuPair) {
    Add-Line ""
    Add-Line "## Vulkan vs CPU (mesma placa, mesmo binario, mesmo GGUF)"
    Add-Line ""
    Add-Line "Texto unico em ingles, seed 42, 1 aquecimento descartado + 3 medicoes por backend."
    Add-Line ""
    Add-Line "| backend | RTF mediano | min | max |"
    Add-Line "|---|---|---|---|"
    foreach ($bk in @('vulkan', 'cpu')) {
        $r = $gpuPair.backends[$bk]
        if ($r) { Add-Line "| $bk | $($r.rtf_median) | $($r.rtf_min) | $($r.rtf_max) |" }
    }
    Add-Line ""
    if ($gpuPair.speedup_cpu_over_vulkan) { Add-Line "- **Ganho da placa: $($gpuPair.speedup_cpu_over_vulkan)x** (CPU/Vulkan, mesmo modelo)" }
    Add-Line "- Veredito: $($gpuPair.verdict)"
    Add-Line "- `gpu-paired.json` - medicoes por requisicao; WAVs em ``audio/gpu-paired-*``"
}
if ($Gguf -and $ggufInfo) {
    Add-Line ""
    Add-Line "## Motor GGUF (caminho Vulkan)"
    Add-Line ""
    Add-Line "- Binario \`omnivoice-tts\`: **$(if ($ggufInfo.binary_found) { 'presente' } else { 'ausente/inutilizavel' })**"
    if ($ggufInfo.binary) { Add-Line "- Caminho: \`$($ggufInfo.binary)\` ($($ggufInfo.binary_bytes) bytes)" }
    Add-Line "- Bibliotecas ggml: $($ggufInfo.vulkan_hint)"
    Add-Line "- Motor disponivel no app: **$($ggufInfo.engine_available)**"
    if ($ggufInfo.engine_reason) { Add-Line "- Motivo: $($ggufInfo.engine_reason)" }
    Add-Line "- Geracao de teste: $($ggufInfo.generated) (HTTP $($ggufInfo.http))"
    if ($ggufInfo.rtf) { Add-Line "- RTF GGUF: **$($ggufInfo.rtf)** (gen $($ggufInfo.gen_s)s / audio $($ggufInfo.audio_s)s)" }
    Add-Line "- Veredito: $($ggufInfo.verdict)"
    if ($ggufInfo.vulkan_lines.Count -gt 0) {
        Add-Line ""
        Add-Line '```'
        foreach ($l in $ggufInfo.vulkan_lines) { Add-Line $l }
        Add-Line '```'
    }
}
if ($appInfo.data_dirs_found.Count -gt 0) {
    Add-Line "- Diretorios encontrados:"
    foreach ($d in $appInfo.data_dirs_found) { Add-Line "  - ``$d``" }
}
if ($appInfo.port_3900.Count -gt 0) {
    foreach ($p in $appInfo.port_3900) {
        Add-Line "- Porta 3900 em ``$($p.local_address)`` (loopback: $($p.loopback_only))"
    }
}
Add-Line ""
if ($engines -and $engines.backends) {
    Add-Line "## Motores"
    Add-Line ""
    Add-Line "| id | disponivel | device | clone | design | gpu_compat |"
    Add-Line "|---|---|---|---|---|---|"
    foreach ($e in $engines.backends) {
        Add-Line "| $($e.id) | $($e.available) | $($e.effective_device) | $($e.supports_cloning) | $($e.supports_voice_design) | $($e.gpu_compat -join ',') |"
    }
    Add-Line ""
}
if ($script:Rows.Count -gt 0) {
    Add-Line "## Geracao de audio"
    Add-Line ""
    Add-Line "| run | corpus | rep | engine | HTTP | parede (s) | audio (s) | gen (s) | RTF | routing |"
    Add-Line "|---|---|---|---|---|---|---|---|---|---|"
    foreach ($r in $script:Rows) {
        Add-Line "| $($r.run) | $($r.corpus) | $($r.repetition) | $($r.engine) | $($r.http) | $($r.wall_time_s) | $($r.audio_duration_s) | $($r.server_gen_s) | $($r.rtf) | $($r.routing) |"
    }
    Add-Line ""
    Add-Line "RTF = tempo de sintese / duracao do audio (do servidor). < 1 = mais rapido que tempo real."
    Add-Line "A execucao 1 inclui carga de modelo: compare a partir da 2."
    Add-Line ""
}
Add-Line "## Problemas encontrados"
Add-Line ""
if ($script:Problems.Count -eq 0) {
    Add-Line "Nenhum."
} else {
    foreach ($p in $script:Problems) { Add-Line "- $p" }
}
Add-Line ""
Add-Line "## Arquivos"
Add-Line ""
Add-Line "- ``machine.json`` - hardware completo"
Add-Line "- ``hardware.txt`` - resumo legivel do hardware"
Add-Line "- ``app.json`` - processos, porta, diretorios"
Add-Line "- ``api/`` - respostas cruas de cada endpoint"
Add-Line "- ``audio/`` - WAVs gerados + headers + erros"
Add-Line "- ``measurements.csv`` - tabela de medicoes"
Add-Line "- ``run.log`` - transcript da execucao"

$sum.ToString() | Out-File -FilePath (Join-Path $OutDir 'summary.md') -Encoding UTF8
Write-Ok 'summary.md escrito'

try { Stop-Transcript | Out-Null } catch { }

# ------------------------------------------------------------- [10/10] git
Write-Step '10/10' 'Enviando para o git'

if ($NoGit -or -not $isRepo) {
    Write-Info 'Commit/push pulado por opcao ou por nao ser repositorio git.'
} else {
    Push-Location $RepoRoot
    try {
        $branch = (& git rev-parse --abbrev-ref HEAD 2>$null)
        Write-Info "branch: $branch"

        # atualiza antes, para o push nao ser rejeitado
        Write-Info 'git pull --rebase --autostash ...'
        $pullOut = (& git pull --rebase --autostash 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) {
            Write-Warn2 "pull falhou (seguindo mesmo assim). Detalhe: $($pullOut.Trim())"
        } else { Write-Ok 'pull ok' }

        & git add 'lab/reports' 2>&1 | Out-Null

        $staged = (& git diff --cached --name-only 2>$null)
        if (-not $staged) {
            Write-Info 'nada novo para commitar'
        } else {
            $msg = "lab: coleta windows $Stamp"
            & git -c 'user.name=VoiceStudio Lab' -c 'user.email=lab@local' commit -m $msg 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Ok "commit criado: $msg" }
            else { Write-Warn2 'commit falhou' }

            Write-Info 'git push ...'
            $pushOut = (& git push origin HEAD 2>&1 | Out-String)
            if ($LASTEXITCODE -eq 0) { Write-Ok 'push concluido - os dados chegaram ao remoto' }
            else { Write-Fail "push falhou. Detalhe: $($pushOut.Trim())" }
        }
    } catch {
        Write-Fail "erro no git: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------- final
Write-Host ""
Write-Host "================================================================" -ForegroundColor White
Write-Host " Concluido em $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White
Write-Host " Pasta: $OutDir" -ForegroundColor White
if ($script:Problems.Count -gt 0) {
    Write-Host " $($script:Problems.Count) aviso(s)/falha(s) - veja summary.md" -ForegroundColor Yellow
} else {
    Write-Host " Sem avisos." -ForegroundColor Green
}
Write-Host "================================================================" -ForegroundColor White
Write-Host ""
Write-Host "Proximo passo: abra lab\reports\evidence\windows\$Stamp\summary.md"
Write-Host ""
