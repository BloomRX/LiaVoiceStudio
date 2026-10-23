# installation-plan.md — Plano de instalação mínimo

**Status: AUTORIZADA e AUTOMATIZADA.** A instalação é feita pelo `run-lab.bat` na
máquina-alvo; o laboratório em si não instala nada. As estimativas de tamanho
abaixo foram trocadas por números de release quando existiam.

Conforme a seção 3 da missão, cada ação proposta vem com motivo, tamanho,
espaço estimado, riscos e forma de desfazer.

---

## Estado atual do laboratório

| Item | Situação |
|---|---|
| Diretório | `lab/` no checkout desta sessão (**não** `J:\VoiceStudio-Lab`) |
| Conteúdo | apenas o clone do VoiceStudio + `reports/` |
| Repositório VoiceStudio | clonado, histórico preservado, **sem commits ou modificações** |
| Instalações feitas | **nenhuma** |
| Downloads de modelo | **nenhum** |
| Alterações de sistema | **nenhuma** |
| Arquivos copiados da Lia | **nenhum** |

O clone está em: `lab/VoiceStudio` (225 MB, `main` @ `48e85106`).

---

## Opção A — Instalação na máquina real (Windows + AMD)

**Esta é a opção correta para a missão.** Continua sendo executada por você, na
sua máquina — mas agora **sem passos manuais de instalação**: quem baixa, confere
o hash, instala, abre o app e baixa o modelo é o `run-lab.bat`.

```bat
git clone -b arena/e6163ffc-liavoicestudio https://github.com/BloomRX/LiaVoiceStudio.git
cd LiaVoiceStudio
run-lab.bat
```

### A.1 O que o script faz

1. Baixa o instalador oficial **v0.5.6** (`VoiceStudio-Electron-0.5.6-win-x64.exe`,
   214 447 484 bytes) do GitHub Releases.
2. Confere o **SHA-256 fixo no script** —
   `3d7ac1d6b54e7854ca7fff4dda838e402d1c5d31acc9656b1838432e29a97624`.
   Divergiu? O arquivo é apagado e **nada é executado**.
3. Roda o instalador em modo silencioso (`/S`). É uma instalação **por usuário**
   (`nsis.perMachine: false`): **não pede administrador** e o destino padrão é
   `%LOCALAPPDATA%\Programs\VoiceStudio`.
4. Abre o app e espera `GET /health` responder em `127.0.0.1:3900`.
5. Pede o modelo padrão por `POST /models/install` com
   `{"repo_id":"k2-fsa/OmniVoice","target":"local"}` e acompanha
   `GET /models/install/status` até concluir. **Um** modelo, o padrão. Nada de
   `audio.cpp`, sidecars ou modelos de ASR.

O `installation-plan.md` anterior dizia "destino `J:\VoiceStudio-Lab\app`".
**Isso não é possível sem clicar**: o instalador do electron-builder não aceita
diretório por parâmetro fora do `/D=` do NSIS, e o diretório de dados/ambiente do
app é escolhido dentro da interface. O script usa o padrão do instalador e registra
onde caiu.

### A.1.1 O único passo que continua manual

Na primeira execução o app mostra a tela **"Instalar ambiente local"**
(`backend.setup_required`) e exige **~9 GiB livres** na unidade do app. Esse
download (Python + dependências, vários GB) é disparado por um `ipcMain.handle`
(`backend:setupRuntime`) que **só aceita chamadas do renderer confiável** — não há
endpoint HTTP, argumento de linha de comando ou variável de ambiente equivalente.
Portanto é o único clique inevitável.

Consequência prática: o `.bat` espera até 30 min pela API e **retoma sozinho**
quando você clica. Modelo, geração, medições, relatórios e push seguem
automáticos. Se o prazo estourar, o script não perde nada: rode de novo depois do
clique e o que já foi baixado é reaproveitado.

### A.2 Motivo

É a única forma de responder às três perguntas que a inspeção estática não
responde: qualidade em pt-BR, latência real e comportamento no hardware AMD.

### A.3 Tamanho aproximado

| Item | Download | Em disco |
|---|---|---|
| Instalador Electron | **204 MiB** (214 447 484 B) | ~700 MiB |
| Ambiente Python do app (`uv` + deps, baixado pelo próprio app) | vários GB | vários GB |
| Pesos OmniVoice | 2,4 GiB | 2,4 GiB |
| **Total** | **~5–8 GB** | **~10–12 GB** |

O tamanho do ambiente Python não está publicado em lugar nenhum: é resolvido em
tempo de execução pelo `uv sync` a partir do `uv.lock` do app. A única medida real
disponível é a do laboratório (Opção B): **6,7 GB** de venv para o mesmo
`pyproject.toml`, com duas dependências faltando.

### A.4 Onde isso cai no disco

Por padrão, **tudo vai para `C:`**:

| O quê | Onde |
|---|---|
| App | `%LOCALAPPDATA%\Programs\VoiceStudio` |
| Ambiente Python + dados | raiz de runtime padrão do app (`%LOCALAPPDATA%`) |
| Cache do Hugging Face (pesos) | `%USERPROFILE%\.cache\huggingface` |

A tela de setup permite escolher outra pasta para o runtime, mas **só pela
interface** (`setRuntimeLocation` é IPC do renderer). O script usa o padrão e
registra os caminhos em `app.json`.

Na máquina-alvo, `C:` tem 203,66 GB livres — folga suficiente. A exigência mínima
que o próprio app impõe é de **~9 GiB** na unidade escolhida.

### A.5 Riscos e efeitos colaterais

| Risco | Gravidade | Mitigação |
|---|---|---|
| Modelo baixa automaticamente na 1ª geração | Médio | O script chama `POST /models/install` explicitamente e acompanha `/models/install/status` |
| PyTorch CPU **substitui** um PyTorch CUDA existente (se houver) | **Alto** se você usa CUDA para outra coisa | O instalador escolhe a variante na 1ª execução; verificar antes com `python -c "import torch;print(torch.version.cuda)"` |
| `uv`/HF gravam cache no disco `C:` | Baixo | Previsto; `C:` tem 203 GB livres. Mover exige a interface do app |
| ~10 GB a menos em `C:` | Baixo | Registrado antes/depois pelo script |
| App roda em CPU e parece "travado" | Médio | Esperado; ver `test-matrix.md` §5.3 |
| Script `irm ... \| iex` recomendado pelo README | **Médio** | **Não usar.** O script baixa o `.exe` e confere o SHA-256 antes de executar |
| Nenhuma alteração de driver ou variável global é necessária | — | O instalador é por usuário, sem admin |

### A.6 Como desfazer

1. **Configurações → Manutenção → Desinstalar** dentro do app. Ele oferece a
   opção de remover também os modelos. Pelo Painel de Controle o desinstalador
   remove o app e **deixa** dados e modelos.
2. O que sobrar, conferir antes de apagar:

```powershell
$appData = "$env:APPDATA\omnivoice"              # dados/configuracoes
$models  = "$env:USERPROFILE\.cache\huggingface"  # pesos (compartilhado!)
$runtime = "$env:LOCALAPPDATA\VoiceStudio"         # ambiente Python
foreach ($p in $appData, $models, $runtime) {
    if (Test-Path $p) { "{0}  {1:N1} GB" -f $p, ((Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1GB) }
}
```

3. Atenção: `%USERPROFILE%\.cache\huggingface` é **compartilhado** com outros
   apps que usam Hugging Face. Apagar inteiro pode afetar outra coisa.
4. Conferir o espaço:

```powershell
Get-PSDrive C | Select @{n='GB_livre';e={[math]::Round($_.Free/1GB,1)}}
```

O guia oficial de desinstalação (`docs/install/uninstall.md`) separa "remover o
app, mantendo seus dados" de "remover tudo" — vale ler antes.

### A.7 Critérios de aceite da instalação

- `GET http://127.0.0.1:3900/health` → `200 {"status":"ok","device":...}`
  (antes disso ele responde **503** `{"status":"starting","step":...}` — o
  script usa `/startup/progress` para mostrar em que etapa está)
- `device` registrado (esperado: `"cpu"` na sua máquina)
- Uma geração curta (corpus `C6`) produz um WAV audível
- Fechar o app encerra o backend (nenhum `python.exe` órfão na porta 3900)
- Reabrir e gerar de novo funciona

---

## Opção B — Validação da API no laboratório — ✅ JÁ EXECUTADA

**Status: concluída.** Não substitui a Opção A e não responde nada sobre AMD,
Vulkan, Windows ou qualidade de voz. Provou o **contrato da API**, que era o
objetivo.

### B.1 O que foi realmente feito

O plano original era instalar só o motor `supertonic3` (~1,7 GB). Na prática
isso não foi possível, por dois motivos que só apareceram na execução:

1. O backend importa `torch` no módulo raiz (`services/tts_backend.py`), então
   **não existe instalação "leve"** — o ambiente completo é obrigatório.
2. `supertonic3` exige `pip install` do pacote + pesos do Hugging Face, e
   **`huggingface.co` não é alcançável deste sandbox**.

Então instalou-se o backend completo e exercitou-se a API com o motor padrão
(OmniVoice), **sem** conseguir gerar áudio.

### B.2 Números reais (medidos, substituem a estimativa)

| Item | Estimado antes | Real |
|---|---|---|
| Ambiente Python (venv) | ~4 GB | **6,7 GB** |
| Download total | ~1,7 GB | ~2,5 GB |
| Tempo até a API responder | — | **5,6 s** (`/startup/progress` detalha as etapas) |
| Áudio gerado | esperado | **nenhum** — pesos vêm do HF, inacessível |

Duas dependências declaradas não puderam ser instaladas (bloqueio de rede a
`objects.githubusercontent.com`): `kittentts` e `en-core-web-sm`. O backend
subiu mesmo assim — elas só afetam os motores que as usam.

### B.3 O que ficou provado

- `/health`, `/startup/progress`, `/system/info`, `/generate/budget` respondem
  como documentado.
- `GET /engines/tts` lista **17 motores**, com `available`, `effective_device`,
  `supports_cloning`, `supports_voice_design`, `gpu_compat` e `reason`.
- O gate de licença devolve **403** com `fingerprint`; o OmniVoice exige **duas**
  aceitações (modelo CC-BY-NC + tokenizador Higgs `NOASSERTION`).
- Aceite headless via `POST /models/licenses/accept` funciona (200).
- Isolamento: processo preso a `127.0.0.1:3900`.
- Erros no formato OpenAI em `/v1/audio/speech`.

### B.4 O que NÃO ficou provado

- **Nenhum áudio.** Falha de rede ao carregar pesos devolve
  `500 {"error_class":"HF_AUTH_FAILED"}`, não um 4xx limpo.
- Nada sobre AMD, Vulkan, Windows, naturalidade em pt-BR ou latência na sua
  máquina.

Evidência completa: `evidence/runtime/`.

### B.5 Como desfazer

```bash
rm -rf lab/venv lab/data
# nada foi instalado fora do diretório do laboratório; nenhum pacote de sistema
```

### B.6 O que isso muda no plano

**Nada na Opção A.** A pergunta central — qualidade em pt-BR e comportamento no
hardware AMD — continua dependendo de você rodar `run-lab.bat` na máquina real.

Em compensação, a Opção B já entregou o contrato exato que a Lia vai consumir, e
corrigiu duas suposições minhas (timeout e descoberta de idioma). Ver
`evidence/runtime/README.md`.

---

## Opção C — Não instalar nada

Válida. Os relatórios continuam corretos e completos como **avaliação estática**,
e você executa a Opção A quando quiser. Nenhuma conclusão deste laboratório
depende de instalação.

---

## Recomendação do laboratório

**Opção A**, executada por você na máquina real — é a única que responde à
pergunta central.

**Opção B já foi executada** (ver acima): a API funciona como os relatórios
descrevem. Ela respondeu uma pergunta secundária e não precisa ser repetida.

**Nunca A + B ao mesmo tempo** sem motivo: são ambientes diferentes e os
resultados não se somam.
