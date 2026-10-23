# Coleta do laboratorio - LUCASPC

Gerado em 2026-10-23 19:31:44 pelo coletor v1.0.0.

## Ambiente

```
Sistema : Microsoft Windows 11 Home build 26200 (64 bits)
CPU     : AMD Ryzen 5 5500                                - 6C/12T
RAM     : 15.89 GB total, 0.92 GB livre
GPU     : Parsec Virtual Display Adapter - driver 0.45.0.0
GPU     : AMD Radeon RX 580 2048SP - driver 31.0.21925.1001
Disco   : C: 184.62 GB livres de 475.95 GB
Disco   : D: 153.02 GB livres de 465.76 GB
Disco   : F: 29.04 GB livres de 83.84 GB
Disco   : G: 5.25 GB livres de 15 GB
Disco   : J: 112.11 GB livres de 447.12 GB
Admin   : False
```

## VoiceStudio

- App instalado: **ja instalado**
- Executavel: `C:\Users\lucas\AppData\Local\Programs\VoiceStudio\VoiceStudio.exe`
- Modelo TTS: **api indisponivel**
- API respondeu: **False**

## GPU real (Vulkan / audio.cpp)

- VRAM real pelo registro: **8 GB** (WMI reporta 4 GB por saturacao)
  - AMD Radeon RX 580 2048SP: 8 GB
  - Parsec Virtual Display Adapter: VRAM nao informada pelo driver
- Runtime audio.cpp instalado: **False** (versao )
- Vulkan enumerou GPU: **False**
- Modelo Breeze-TTS-2 baixado: False
- Geracao de teste: False (HTTP )
- Engine audiocpp disponivel depois da instalacao:  (routing )
- Veredito: Runtime audio.cpp nao instalado.
- Diretorios encontrados:
  - `C:\Users\lucas\AppData\Local\Programs\VoiceStudio`
  - `C:\Users\lucas\AppData\Roaming\omnivoice`
  - `C:\Users\lucas\AppData\Local\omnivoice`

## Problemas encontrados

- timeout esperando a API. Motivos comuns:
- API nao respondeu em http://127.0.0.1:3900. Abra o VoiceStudio e rode de novo para as fases C/D.
- API indisponivel - modelo nao pode ser garantido
- endpoint do runtime audio.cpp indisponivel
- API indisponivel - geracao pulada

## Arquivos

- `machine.json` - hardware completo
- `hardware.txt` - resumo legivel do hardware
- `app.json` - processos, porta, diretorios
- `api/` - respostas cruas de cada endpoint
- `audio/` - WAVs gerados + headers + erros
- `measurements.csv` - tabela de medicoes
- `run.log` - transcript da execucao

