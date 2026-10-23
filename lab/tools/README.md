# run-lab.bat — arquivo único

O coletor é **um arquivo só**, na raiz do repositório: `run-lab.bat`. Não há
script auxiliar para instalar, copiar ou esquecer.

Duplo-clique, ou pelo terminal:

```
run-lab.bat
```

Ele **instala o VoiceStudio, baixa um modelo, coleta, escreve o resumo, commita e
faz push** — nessa ordem, sozinho.

---

## Por que um único arquivo com PowerShell dentro

O `.bat` contém duas partes:

1. **Bloco Batch** (topo) — traduz argumentos, valida pré-requisitos, extrai a
   parte 2 para um temporário em `%TEMP%`, executa e apaga.
2. **Bloco PowerShell** (a partir da linha `#<PS_BEGIN>`) — toda a lógica de
   coleta.

Você só vê e só executa **um arquivo**. A linguagem interna é PowerShell por um
motivo prático: Batch puro não lê JSON, não consulta CIM/WMI com segurança e não
monta `multipart/form-data`. Reescrever a coleta em Batch significaria parsing de
JSON com `findstr` e geração de JSON por concatenação — frágil de um jeito que
só apareceria no meio de uma coleta sua.

O arquivo é **ASCII puro** e CRLF, para não depender de code page.

---

## Modos

| Comando | O que faz | Tempo aprox. |
|---|---|---|
| `run-lab.bat` | Instala o app, baixa o modelo, gera **1 frase curta** (C6) | 20–60 min |
| `run-lab.bat /voice` | Corpus completo C1..C10, uma vez cada | +5–20 min |
| `run-lab.bat /full` | Corpus + **4 repetições de C7** | +15–45 min |
| `run-lab.bat /noinstall` | não baixa nem instala o app | — |
| `run-lab.bat /nomodel` | não baixa o modelo OmniVoice | — |
| `run-lab.bat /nogit` | Coleta, sem commit/push | — |
| `run-lab.bat /engine:audiocpp` | força um motor específico | — |
| `run-lab.bat /nopause` | não espera tecla no final | — |

O tempo do modo padrão é dominado por três downloads que só acontecem na
primeira vez: instalador (~204 MB), ambiente Python do app (vários GB) e pesos do
OmniVoice (~2,4 GB). Nas execuções seguintes tudo é reaproveitado.

Já existe uma coleta feita com sucesso em
`../reports/evidence/windows/20261023-140732/`, que identificou a máquina
(Ryzen 5 5500, RX 580 2048SP, Windows 11 build 26200).

---

## O que o script faz, passo a passo

| Etapa | Ação |
|---|---|
| 1 | Confere Windows, PowerShell, espaço em disco e se está na raiz do repo |
| 2 | Coleta hardware e sistema (`machine.json`) |
| 3 | Procura instalação existente, processos e a porta 3900 |
| 4 | **Instala**: baixa `VoiceStudio-Electron-0.5.6-win-x64.exe`, confere o SHA-256 e roda com `/S` |
| 5 | Abre o app e espera a API responder em `127.0.0.1:3900` |
| 6 | Sonda `/health`, `/engines/tts`, `/system/info`, `/gpu-report`, `/generate/budget` |
| 7 | **Modelo**: `POST /models/install` com `k2-fsa/OmniVoice` e acompanha o status |
| 8 | Gera o corpus pt-BR e mede tempo, duração e RTF |
| 9 | Escreve `summary.md` e os relatórios |
| 10 | Commit e push na branch do fork |

### O único clique que não dá para automatizar

Na **primeira** execução o VoiceStudio abre uma tela **"Instalar ambiente local"**
(Python + dependências, vários GB, exige ~9 GiB livres). Esse passo é uma chamada
IPC do renderer para o processo principal do Electron e **só pode ser disparado
pela janela do app** — não existe endpoint HTTP nem argumento de linha de comando.

Então: clique nesse botão uma vez. O `.bat` fica esperando até 30 minutos
(`/AppWaitSeconds` muda isso) e **retoma sozinho** assim que a API subir. Todo o
resto — modelo, geração, medições, relatórios, push — é automático.

## Segurança

O coletor baixa **um** binário, e só o executa se o SHA-256 bater com o valor
fixo no script:

```
3d7ac1d6b54e7854ca7fff4dda838e402d1c5d31acc9656b1838432e29a97624
```

Se o hash não conferir, o arquivo é apagado e nada é executado. O instalador é
por usuário (`perMachine: false`), **não pede administrador** e instala em
`%LOCALAPPDATA%\Programs\VoiceStudio`.

---

## O que é coletado

```
lab/reports/evidence/windows/<timestamp>/
├─ summary.md          <- LEIA PRIMEIRO: resumo legível de tudo
├─ run.log             <- transcript completo da execução
├─ machine.json        <- hardware detalhado
├─ hardware.txt        <- hardware em texto
├─ app.json            <- processos, porta 3900, diretórios achados
├─ measurements.csv    <- tabela de medições (run, RTF, tempos)
├─ api/
│  ├─ health.json
│  ├─ engines.json         <- 17 motores, disponibilidade, device
│  ├─ compute-device.json  <- device/override que o app escolheu
│  ├─ model-status.json    <- pesos carregados em memoria?
│  ├─ diagnose.json
│  ├─ system-info.json
│  ├─ budget.json          <- 404 na v0.5.6 (endpoint de versao nova)
│  ├─ model-install-start.json   <- resposta do POST /models/install
│  ├─ model-install-status.json  <- estado do download do modelo
│  ├─ engines-after-install.json <- motores depois de baixar os pesos
│  ├─ licence-state.json         <- 404 = versão sem gate de licença
│  └─ error-*.txt          <- códigos HTTP de falha esperada
└─ audio/
   ├─ C6-r1.wav            <- o áudio gerado
   ├─ C6-r1.headers.txt    <- X-Gen-Time, X-Audio-Duration, X-OmniVoice-Routing
   ├─ C6-r1.text.txt       <- texto exato enviado (UTF-8 sem BOM)
   └─ C6-r1.error.txt      <- se falhou, o corpo do erro
```

### Como saber se rodou em GPU

A v0.5.6 **não** emite o header `X-OmniVoice-Routing` (medição de 2026-10-23: os
headers do WAV trazem só `X-Audio-Id`, `X-Gen-Time`, `X-Audio-Path`, `X-Seed`,
`X-Audio-Duration`). A coluna `routing` do `measurements.csv` fica vazia.

O device efetivo então vem de dois lugares, ambos coletados:

- `/health` → `device` (`cpu`, `cuda (…)`, `mps`);
- `/engines/tts` → `effective_device` de cada motor.

Em versões mais novas existe também `X-OmniVoice-Routing`; o script já o captura
se aparecer. Na máquina-alvo os dois caminhos dizem `cpu`.

### Por que o texto vai por arquivo

No PowerShell 5.1, texto com acento passado como argumento pode ser reencodado
pela code page do console e chegar corrompido ao servidor — e então o teste de
pt-BR mede a coisa errada sem ninguém perceber. O coletor grava o texto em
UTF-8 **sem BOM** e envia por `curl -F "text=<arquivo"`.

### RTF

Calculado como `X-Gen-Time / X-Audio-Duration`, ambos vindos do servidor — não é
estimativa. RTF < 1 significa mais rápido que tempo real.

**A execução 1 inclui carga de modelo.** Compare a partir da 2. Por isso o modo
`/full` repete C7 quatro vezes.

**Cuidado com timeout:** `GET /generate/budget` devolve `executionBase` 600 s
(CPU) **mais** `progressExtensionCap` 1800 e `cpuAutoCeiling` 7200. Um cliente
com timeout fixo de 660 s cortaria gerações legítimas.

---

## Segurança


- **não abre portas** — só fala com `127.0.0.1:3900`
- **não altera variáveis de ambiente** do sistema nem instala driver
- **não envia dados para fora** além do `git push` para a branch do seu fork

Tudo que ele lê é hardware, processos locais e a API local.

---

## Se algo der errado

1. Abra `summary.md` — a seção **"Problemas encontrados"** lista o que falhou.
2. Abra `run.log` — transcript completo, com as mensagens exatas.
3. Se a API não respondeu, deixe o VoiceStudio aberto e rode de novo — ele
   reaproveita o instalador, o ambiente e o modelo já baixados.

### "timeout esperando a API"

Quase sempre é a tela **"Instalar ambiente local"** esperando um clique, ou o
download do ambiente Python ainda em andamento. Abra o app, conclua essa tela e
rode o `.bat` de novo: o que já foi baixado não é baixado outra vez.

### "SHA-256 não confere"

O download veio corrompido, ou o release mudou. O script apaga o arquivo e não
executa nada. Baixe de novo (rode outra vez) ou confira manualmente contra o
`SHA256SUMS.txt` da release.

O script **não para no primeiro erro**: continua, registra e segue. Uma coleta
parcial ainda é útil.

### "ERRO: não foi possível extrair o script interno"

O `.bat` foi editado ou corrompido (mais comum: salvo com quebra de linha LF em
vez de CRLF). Reclone o arquivo:

```
git checkout -- run-lab.bat
```

### Push falhou?

Os arquivos continuam no disco. Rode:

```
git status
git push origin HEAD
```

Ou rode de novo com `/nogit` e faça o push manualmente.
