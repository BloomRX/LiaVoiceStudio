# Coleta do laboratorio - LUCASPC

Gerado em 2026-10-23 17:20:52 pelo coletor v1.0.0.

## Ambiente

```
Sistema : Microsoft Windows 11 Home build 26200 (64 bits)
CPU     : AMD Ryzen 5 5500                                - 6C/12T
RAM     : 15.89 GB total, 5.83 GB livre
GPU     : Parsec Virtual Display Adapter - driver 0.45.0.0
GPU     : AMD Radeon RX 580 2048SP - driver 31.0.21925.1001
Disco   : C: 189.99 GB livres de 475.95 GB
Disco   : D: 153.02 GB livres de 465.76 GB
Disco   : F: 29.04 GB livres de 83.84 GB
Disco   : G: 5.25 GB livres de 15 GB
Disco   : J: 112.11 GB livres de 447.12 GB
Admin   : False
```

## VoiceStudio

- App instalado: **ja instalado**
- Executavel: `C:\Users\lucas\AppData\Local\Programs\VoiceStudio\VoiceStudio.exe`
- Modelo TTS: **concluido**
- API respondeu: **True**
- Versao: `0.5.6`
- Dispositivo efetivo: `cpu`

## GPU real (Vulkan / audio.cpp)

- VRAM real pelo registro: **8 GB** (WMI reporta 4 GB por saturacao)
  - AMD Radeon RX 580 2048SP: 8 GB
  - Parsec Virtual Display Adapter:  GB
- Runtime audio.cpp instalado: **True** (versao v0.7.4)
- Vulkan enumerou GPU: **True**

Dispositivos vistos pelo runtime:

```
audiocpp_server.exe : ggml_vulkan: Found 1 Vulkan devices:
No C:\Users\lucas\AppData\Local\Temp\voicestudio-lab.ps1:1093 caractere:28
+                 $devOut = (& $exe --list-devices 2>&1 | Out-String)
+                            ~~~~~~~~~~~~~~~~~~~~~~~~~~
+ CategoryInfo          : NotSpecified: (ggml_vulkan: Found 1 Vulkan devices::String) [], RemoteException
+ FullyQualifiedErrorId : NativeCommandError
ggml_vulkan: 0 = AMD Radeon RX 580 2048SP (AMD proprietary driver) | uma: 0 | fp16: 0 | bf16: 0 | warp size: 64 |
shared memory: 32768 | int dot: 0 | matrix cores: none
available_devices=2
Vulkan:0 "AMD Radeon RX 580 2048SP" [GPU]
CPU:0 "AMD Ryzen 5 5500                               " [CPU]
select with: --backend <cuda|hip|vulkan|metal|cpu> --device <index>
```
- Modelo Breeze-TTS-2 baixado: True
- Geracao de teste: True (HTTP 200)
- **RTF em Vulkan: 11.642** (gen 96.86s / audio 8.32s)
- Veredito: Vulkan rodou na placa. RTF=11.642 com Breeze-TTS-2 (en). Compare com o RTF 25,9 do OmniVoice em CPU.
- Diretorios encontrados:
  - `C:\Users\lucas\AppData\Local\Programs\VoiceStudio`
  - `C:\Users\lucas\AppData\Roaming\omnivoice`
  - `C:\Users\lucas\AppData\Local\omnivoice`
- Porta 3900 em `127.0.0.1` (loopback: True)

## Motores

| id | disponivel | device | clone | design | gpu_compat |
|---|---|---|---|---|---|
| omnivoice | True | cpu | True |  | cuda,rocm,mps,cpu |
| cosyvoice | False | cpu | True |  | cuda,cpu |
| kittentts | True | cpu | False |  | cpu |
| mlx-audio | False | cpu |  |  | mps,cpu |
| voxcpm2 | False | cpu | True |  | cuda,mps,cpu |
| moss-tts-nano | False | cpu | True |  | cuda,cpu |
| gpt-sovits | False | cpu | True |  | cuda,cpu |
| sherpa-onnx | False | cpu | False |  | cuda,cpu |
| indextts2 | False | cpu | True |  | cuda,cpu |
| omnivoice-gguf | False | cpu | True |  | cuda,mps,cpu |
| supertonic3 | False | cpu | False |  | cpu |
| moss-tts-v15 | False | cpu | True |  | cuda,rocm,xpu,npu,cpu |
| dots-tts | False | cpu | True |  | cuda,cpu |
| omnivoice-subprocess | True | cpu | True |  | cuda,rocm,mps,cpu |
| pockettts | False | cpu | True |  | cpu |
| confucius4-tts | False | cpu | True |  | cuda,rocm,xpu,npu,cpu |
| audiocpp | False | cpu | True |  | cpu |

## Geracao de audio

| run | corpus | rep | engine | HTTP | parede (s) | audio (s) | gen (s) | RTF | routing |
|---|---|---|---|---|---|---|---|---|---|
| 1 | C6 | 1 | active | 200 | 48.074083 | 1.01 | 41.84 | 41.426 |  |
| 2 | C6 | 2 | active | 200 | 41.149742 | 1.01 | 40.65 | 40.248 |  |

RTF = tempo de sintese / duracao do audio (do servidor). < 1 = mais rapido que tempo real.
A execucao 1 inclui carga de modelo: compare a partir da 2.

## Problemas encontrados

Nenhum.

## Arquivos

- `machine.json` - hardware completo
- `hardware.txt` - resumo legivel do hardware
- `app.json` - processos, porta, diretorios
- `api/` - respostas cruas de cada endpoint
- `audio/` - WAVs gerados + headers + erros
- `measurements.csv` - tabela de medicoes
- `run.log` - transcript da execucao

