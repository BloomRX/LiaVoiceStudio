# Evidência de instalação — primeira execução real

**Arquivo:** `20261023-preflight.png` — captura de tela enviada pelo operador.
Máquina `LUCASPC`, 2026-10-23.

Primeira prova de que a Opção A do `installation-plan.md` funciona de ponta a
ponta até a tela de verificação do sistema: o app instalou, o ambiente Python foi
provisionado e **o backend está respondendo** (essa tela lê `/setup/status` e
`/setup/preflight` pela API local — sem backend, ela não renderiza).

---

## Transcrição da tela (texto, para busca e diff)

Tela **"Verificação do sistema"** — etapa 1 de 4 do assistente de primeira
execução:

| Item | Resultado exibido | Leitura |
|---|---|---|
| Operating system | ✅ `Windows-10 (AMD64)` | **Rótulo, não o SO real.** O preflight imprime `platform.platform(terse=True)` (`setup/wizard.py`, check `os`), e o Python rotula a família NT 10.x como `Windows-10` mesmo em build 26200. O SO medido é Windows 11 Home build 26200 |
| Python runtime | ✅ `Python 3.11.6` | O `uv` provisionou o ambiente sozinho; não foi preciso Python no sistema |
| System RAM | ✅ `15.9 GB total` | Confere com `machine.json` (15,89 GB) |
| Disk space | ✅ `190.2 GB free at C:\Users\lucas\AppData\Local\OmniVoice\hf_cache` | **Correção importante:** o cache do Hugging Face fica em `%LOCALAPPDATA%\OmniVoice\hf_cache`, **não** em `%USERPROFILE%\.cache\huggingface`. Medido antes: 203,68 GB → **~13,5 GB já consumidos** por app + ambiente Python |
| HuggingFace cache writable | ✅ mesmo caminho | idem |
| **GPU acceleration** | ⚠️ `No compatible GPU detected — running CPU-only` | **Confirma empiricamente** a conclusão da Fase D |
| Active engine routing | ✅ `omnivoice — cpu (no accelerator on this host)` | O roteador escolheu CPU sozinho |
| Network (huggingface.co) | ✅ `Reachable (78 ms)` | Rede OK — o download de pesos é viável |

---

## O que isso fecha

### 1. Fase B — instalação: **executada**

- Instalador v0.5.6 instalado por usuário, sem administrador.
- Ambiente Python 3.11.6 provisionado pelo próprio app.
- Diretório de dados: `C:\Users\lucas\AppData\Local\OmniVoice\`.
- Backend já respondendo na porta local (pré-requisito desta tela).

O que ainda falta da Fase B: `/health` documentado em evidência, geração de um
WAV, e o ciclo fechar/reabrir (o `run-lab.bat` cobre os três).

### 2. Fase D — GPU: **confirmada por medição do próprio app**

`No compatible GPU detected` + `omnivoice — cpu` não é opinião nem inferência: é
o veredito do próprio app (`/setup/preflight`, check `gpu`, e
`gpu_routing_verdict()` para o motor ativo) sobre esta máquina, e coincide
exatamente com a análise estática da §2.3 do `executive-summary.md`:

- RX 580 2048SP = Polaris 20 = **`gfx803`** → fora do suporte do ROCm moderno.
- `ROCM_GFX_OVERRIDES` do projeto não tem entrada para Polaris.
- ~4 GB de VRAM < piso de 6 GB do OmniVoice.

**Consequência medida:** todo TTS em pt-BR nesta máquina roda no Ryzen 5 5500, em
CPU. O aviso do app ("~10x slower than GPU") é a expectativa do próprio
fornecedor — o número real sai das medições de RTF do `run-lab.bat`, não daqui.

### 3. Correção de documentação

O `installation-plan.md` afirmava que os pesos cairiam em
`%USERPROFILE%\.cache\huggingface` e que esse cache é compartilhado com outros
apps. **Está errado para esta instalação**: o cache usado é
`%LOCALAPPDATA%\OmniVoice\hf_cache`.

Mecanismo: `hf_cache_dir()` (`setup/models.py`) lê `HF_HUB_CACHE`,
`HUGGINGFACE_HUB_CACHE` ou `HF_HOME` e só cai no padrão de plataforma se nenhuma
existir — ou seja, o app fixa uma dessas variáveis no processo do backend. Não
localizei o ponto exato em `v0.5.6`; o **efeito** está medido na tela.

Isso **simplifica a remoção**: apagar `%LOCALAPPDATA%\OmniVoice` não afeta
nenhum outro aplicativo que use Hugging Face.

### 4. Antes/depois de espaço em disco

| Momento | `C:` livre |
|---|---|
| Coleta `20261023-141256`, antes de instalar | 203,68 GB |
| Preflight, app + ambiente Python instalados | **190,2 GB** |
| Diferença | **~13,5 GB** (sem os pesos do modelo) |

Fecha parte do requisito "espaço antes/depois" da Fase B. O número final, com o
OmniVoice, sai da coleta do `run-lab.bat`.

---

## O que ainda não está provado

- Nenhum áudio gerado por esta tela.
- Nenhuma medição de tempo, RTF ou uso de RAM em geração.
- Nenhuma licença aceita (a v0.5.6 não exige).
- O assistente ainda tem 3 etapas (pacotes de modelos, privacidade, entrar no
  estúdio); a captura é da etapa 1.
