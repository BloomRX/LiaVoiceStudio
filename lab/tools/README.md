# run-lab.bat — arquivo único

O coletor é **um arquivo só**, na raiz do repositório: `run-lab.bat`. Não há
script auxiliar para instalar, copiar ou esquecer.

Duplo-clique, ou pelo terminal:

```
run-lab.bat
```

Ele coleta, escreve o resumo, commita e faz push.

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
| `run-lab.bat` | Ambiente + API + **1 frase curta** (C6) | 1–3 min |
| `run-lab.bat /voice` | Corpus completo C1..C10, uma vez cada | 5–20 min |
| `run-lab.bat /full` | Corpus + **4 repetições de C7** | 15–45 min |
| `run-lab.bat /nogit` | Coleta, sem commit/push | — |
| `run-lab.bat /engine:audiocpp` | força um motor específico | — |
| `run-lab.bat /nopause` | não espera tecla no final | — |

Já existe uma coleta feita com sucesso em
`../reports/evidence/windows/20261023-140732/`, que identificou a máquina
(Ryzen 5 5500, RX 580 2048SP, Windows 11 build 26200).

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
│  ├─ gpu-report.json      <- o mais importante para AMD
│  ├─ diagnose.json
│  ├─ system-info.json
│  ├─ budget.json
│  └─ error-*.txt          <- códigos HTTP de falha esperada
└─ audio/
   ├─ C6-r1.wav            <- o áudio gerado
   ├─ C6-r1.headers.txt    <- X-Gen-Time, X-Audio-Duration, X-OmniVoice-Routing
   ├─ C6-r1.text.txt       <- texto exato enviado (UTF-8 sem BOM)
   └─ C6-r1.error.txt      <- se falhou, o corpo do erro
```

### Por que `X-OmniVoice-Routing` importa

É o header que **denuncia se a geração usou GPU ou caiu para CPU**. A interface
do app pode mostrar "GPU ativa" enquanto o motor roda em CPU. O coletor copia
esse header para cada WAV.

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

O coletor:

- **não instala nada**
- **não altera variáveis de ambiente** do sistema
- **não abre portas** — só fala com `127.0.0.1:3900`
- **não muda configuração do sistema**
- **não envia dados para fora** além do `git push` para a branch do seu fork

Tudo que ele lê é hardware, processos locais e a API local.

---

## Se algo der errado

1. Abra `summary.md` — a seção **"Problemas encontrados"** lista o que falhou.
2. Abra `run.log` — transcript completo, com as mensagens exatas.
3. Se a API não respondeu, abra o VoiceStudio e rode de novo.

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
