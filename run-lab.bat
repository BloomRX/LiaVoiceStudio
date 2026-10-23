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
 "$l = Get-Content -LiteralPath '%~f0'; $i = -1; for ($k = 0; $k -lt $l.Count; $k++) { if ($l[$k].Trim() -eq '#<PS_BEGIN>') { $i = $k; break } }; if ($i -lt 0) { exit 2 }; $l[$i..($l.Count - 1)] | Set-Content -LiteralPath '%VS_TEMP_PS%' -Encoding UTF8"

if errorlevel 1 (
    echo.
    echo  ERRO: nao foi possivel extrair o script interno deste .bat.
    echo        O arquivo pode estar corrompido ou ter sido editado.
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
    [int]$AppWaitSeconds = 1800,
    [string]$Model = 'k2-fsa/OmniVoice',
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
    <# GET com timeout curto; devolve objeto ou $null e grava o erro. #>
    param([string]$Path, [string]$SaveAs, [int]$TimeoutSec = 10)
    $url = "$BaseUrl$Path"
    try {
        $r = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $TimeoutSec -ErrorAction Stop
        if ($SaveAs) { $r | ConvertTo-Json -Depth 8 | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8 }
        return $r
    } catch {
        $msg = $_.Exception.Message
        if ($SaveAs) {
            @{ path = $Path; error = $msg; at = (Get-Date).ToString('o') } |
                ConvertTo-Json | Out-File -FilePath (Join-Path $ApiDir $SaveAs) -Encoding UTF8
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
Write-Host " VoiceStudio Lab - coleta para Windows + AMD" -ForegroundColor White
Write-Host " Versao do coletor: $ScriptVersion" -ForegroundColor DarkGray
Write-Host " Inicio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host " Saida:  $OutDir" -ForegroundColor DarkGray
Write-Host "================================================================" -ForegroundColor White
if ($Full) { Write-Host " Modo: COMPLETO (corpus + repeticoes)" -ForegroundColor Magenta }
elseif ($Voice) { Write-Host " Modo: VOZ (corpus completo)" -ForegroundColor Magenta }
else { Write-Host " Modo: RAPIDO (ambiente + API + 1 frase)" -ForegroundColor Magenta }

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
            & curl.exe -L --fail --retry 2 --connect-timeout 30 -o $exePath $url 2>$null
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

    Write-Info "esperando /health responder (ate $AppWaitSeconds s)..."
    Write-Info ''
    Write-Info 'ATENCAO - existe UM passo que so pode ser feito na janela do app:'
    Write-Info '  1. na primeira execucao o VoiceStudio mostra "Instalar ambiente local"'
    Write-Info '     (Python + dependencias, varios GB). Clique nesse botao.'
    Write-Info '  2. quando a API subir, este script continua sozinho.'
    Write-Info '  Nao feche esta janela do cmd.'
    Write-Info ''

    $deadline = (Get-Date).AddSeconds($AppWaitSeconds)
    $lastLabel = ''
    $waited    = 0
    while ((Get-Date) -lt $deadline) {
        try {
            $h = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
            if ($h -and $h.status -eq 'ok') { $apiReady = $true; break }
        } catch { }

        # /health devolve 503 enquanto o backend sobe; /startup/progress
        # responde sempre e diz em que etapa ele esta.
        try {
            $sp = Invoke-RestMethod -Uri "$BaseUrl/startup/progress" -Method Get -TimeoutSec 3 -ErrorAction Stop
            $lbl = "$($sp.step) $($sp.label)"
            if ($lbl -ne $lastLabel) { Write-Info "backend subindo: $lbl"; $lastLabel = $lbl }
        } catch { }

        Start-Sleep -Seconds 5
        $waited += 5
        if ($waited % 60 -eq 0) {
            Write-Info "aguardando a API... ${waited}s. Se a janela do app pedir, clique em 'Instalar ambiente local'."
        }
    }

    if ($apiReady) {
        Write-Ok 'API respondeu: o app esta pronto'
    } else {
        Write-Warn2 'timeout esperando a API. Motivos comuns:'
        Write-Info '  - ninguem clicou em "Instalar ambiente local" na janela do app'
        Write-Info '  - o download do ambiente Python ainda esta em andamento'
        Write-Info '  - o app abriu e fechou por algum erro (veja o log dele)'
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
    [void](Invoke-Api -Path '/api/settings/gpu-report' -SaveAs 'gpu-report.json' -TimeoutSec 20)
    [void](Invoke-Api -Path '/generate/budget'  -SaveAs 'budget.json')
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
    $lic = Invoke-Api -Path '/models/licenses/acceptance/k2-fsa/OmniVoice' -SaveAs 'licence-state.json' -TimeoutSec 10
    if ($null -eq $lic) {
        Write-Info 'sem gate de licenca nesta versao (esperado na v0.5.6)'
    } elseif ($lic.state -eq 'accepted') {
        Write-Ok 'licenca do modelo ja aceita'
    } else {
        $fp = $lic.fingerprint
        if ($fp) {
            $acc = Invoke-Post -Path '/models/licenses/accept' -Body @{ repo_id = $Model; fingerprint = $fp; accepted = $true } -SaveAs 'licence-accept.json' -TimeoutSec 20
            if ($acc) { Write-Ok 'aceite de licenca registrado' }
            else { Write-Warn2 'aceite falhou; aceite manualmente no Model Catalogue' }
        } else {
            Write-Info 'fingerprint nao retornado; siga pelo app se for pedido'
        }
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
        $c6 = $corpusFiles | Where-Object { $_.BaseName -eq 'C6' }
        $pick = if ($c6) { $c6 } else { $corpusFiles[0] }
        $plan += @{ file = $pick; rep = 1 }
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
