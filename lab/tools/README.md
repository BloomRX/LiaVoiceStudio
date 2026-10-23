# lab/tools — coletor para a máquina real

O laboratório até aqui roda em Linux headless. **Este diretório existe para
coletar os dados que só a sua máquina Windows + AMD pode produzir** — qualidade
de voz em pt-BR, latência real e comportamento do Vulkan/Radeon.

---

## Como usar

Na raiz do repositório clonado, com duplo-clique ou pelo terminal:

```
run-lab.bat
```

Pronto. Ele faz tudo: coleta, escreve o resumo, commita e faz push.

### Modos

| Comando | O que faz | Tempo aprox. |
|---|---|---|
| `run-lab.bat` | Ambiente + API + **1 frase curta** (C6) | 1–3 min |
| `run-lab.bat /voice` | Corpus completo C1..C10, uma vez cada | 5–20 min |
| `run-lab.bat /full` | Corpus + **4 repetições de C7** (mede CPU vs Vulkan) | 15–45 min |
| `run-lab.bat /nogit` | Coleta, sem commit/push | — |
| `run-lab.bat /engine:audiocpp` | força um motor específico | — |

Combinação que responde à pergunta do Vulkan:

```
run-lab.bat /full /engine:omnivoice     -> salva pasta A (CPU)
run-lab.bat /full /engine:audiocpp      -> salva pasta B (Vulkan, se instalado)
```

Cada execução cria **uma pasta com timestamp**. Compare os RTF das duas.

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
   └─ C6-r1.error.txt      <- se falhou, o corpo do erro
```

### Por que `X-OmniVoice-Routing` importa

É o header que **denuncia se a geração usou GPU ou caiu para CPU**. É a única
prova confiável: a interface do app pode mostrar "GPU ativa" enquanto o motor
roda em CPU. O coletor copia esse header para cada WAV.

### RTF

Calculado como `X-Gen-Time / X-Audio-Duration`, ambos vindos do servidor — não é
estimativa. RTF < 1 significa mais rápido que tempo real.

**A execução 1 inclui carga de modelo.** Compare a partir da 2. Por isso o modo
`/full` repete C7 quatro vezes.

---

## Segurança

O coletor:

- **não instala nada**
- **não altera variáveis de ambiente**
- **não abre portas** — só fala com `127.0.0.1:3900`
- **não muda configuração do sistema**
- **não envia dados para fora** além do `git push` para a branch do seu fork

Tudo que ele lê é hardware, processos locais e a API local.

---

## Se algo der errado

1. Abra `summary.md` — a seção **"Problemas encontrados"** lista o que falhou.
2. Abra `run.log` — transcript completo, com as mensagens exatas.
3. Se a API não respondeu, abra o VoiceStudio e rode de novo.

O script **não para no primeiro erro**: ele continua, registra e segue. Uma
coleta parcial ainda é útil.

### Push falhou?

Se o `git push` falhar (credencial, rede, branch), os arquivos continuam no
disco. Rode:

```
cd <repo>
git status
git push origin HEAD
```

Ou rode de novo com `/nogit` e faça o push manualmente.

---

## Detalhe técnico: por que `.ps1` e não só `.bat`

Batch puro não lida bem com JSON, HTTP multipart e CIM (leitura de hardware).
A lógica fica no `.ps1`, que é auditável linha a linha, e o `.bat` é só o
disparador com tradução de argumentos. Se preferir não usar o `.bat`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File lab\tools\collect-windows.ps1 -Voice
```
