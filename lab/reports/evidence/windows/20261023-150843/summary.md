# Coleta do laboratorio - LUCASPC

Gerado em 2026-10-23 15:47:27 pelo coletor v1.0.0.

## Ambiente

```
Sistema : Microsoft Windows 11 Home build 26200 (64 bits)
CPU     : AMD Ryzen 5 5500                                - 6C/12T
RAM     : 15.89 GB total, 1.89 GB livre
GPU     : Parsec Virtual Display Adapter - driver 0.45.0.0
GPU     : AMD Radeon RX 580 2048SP - driver 31.0.21925.1001
Disco   : C: 190.27 GB livres de 475.95 GB
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
| 1 | C1 | 1 | active | 200 | 161.108288 | 6.01 | 160.7 | 26.739 |  |
| 2 | C2 | 1 | active | 200 | 174.742807 | 6.92 | 174.35 | 25.195 |  |
| 3 | C3 | 1 | active | 200 | 302.463004 | 11.76 | 302.07 | 25.686 |  |
| 4 | C4 | 1 | active | 200 | 229.446291 | 8.68 | 229.05 | 26.388 |  |
| 5 | C5 | 1 | active | 200 | 237.590412 | 9.48 | 237.2 | 25.021 |  |
| 6 | C6 | 1 | active | 200 | 39.891859 | 1.01 | 39.51 | 39.119 |  |
| 7 | C7 | 1 | active | 200 | 584.019431 | 22.43 | 583.62 | 26.02 |  |
| 8 | C8 | 1 | active | 200 | 169.936608 | 6.68 | 169.4 | 25.359 |  |
| 9 | C9 | 1 | active | 200 | 180.239623 | 7.04 | 179.85 | 25.547 |  |
| 10 | C10 | 1 | active | 200 | 207.472762 | 8.04 | 207.07 | 25.755 |  |

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

