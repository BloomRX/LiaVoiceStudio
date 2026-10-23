# Coleta do laboratorio - LUCASPC

Gerado em 2026-10-23 14:54:19 pelo coletor v1.0.0.

## Ambiente

```
Sistema : Microsoft Windows 11 Home build 26200 (64 bits)
CPU     : AMD Ryzen 5 5500                                - 6C/12T
RAM     : 15.89 GB total, 6.19 GB livre
GPU     : Parsec Virtual Display Adapter - driver 0.45.0.0
GPU     : AMD Radeon RX 580 2048SP - driver 31.0.21925.1001
Disco   : C: 190.21 GB livres de 475.95 GB
Disco   : D: 153.14 GB livres de 465.76 GB
Disco   : F: 29.04 GB livres de 83.84 GB
Disco   : G: 5.25 GB livres de 15 GB
Disco   : J: 112.12 GB livres de 447.12 GB
Admin   : False
```

## VoiceStudio

- App instalado: **ja instalado**
- Executavel: `C:\Users\lucas\AppData\Local\Programs\VoiceStudio\VoiceStudio.exe`
- Modelo TTS: **concluido**
- API respondeu: **True**
- Versao: `0.5.6`
- Dispositivo efetivo: `cpu`
- Diretorios encontrados:
  - `C:\Users\lucas\AppData\Local\Programs\VoiceStudio`
  - `C:\Users\lucas\AppData\Roaming\omnivoice`
  - `C:\Users\lucas\AppData\Local\omnivoice`

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
| 1 | C6 | 1 | active | 200 | 173.354788 | 1.09 | 172.74 | 158.477 |  |

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

