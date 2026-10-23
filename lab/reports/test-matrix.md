# test-matrix.md — Configurações, procedimentos e resultados

**Data:** 2026-10-23 · **Commit inspecionado:** `48e85106` · **Versão estável
de referência:** v0.5.6

## Legenda de status

| Marca | Significado |
|---|---|
| **INSPECIONADO** | Lido no código/documentação da versão fixada. Não executado. |
| **TESTADO (estático)** | Verificação automatizada sobre o código (parsing, contagem, consistência doc↔código). |
| **TESTADO (runtime)** | Executado de verdade, com resultado observável. |
| **NÃO TESTADO** | Não executado. Motivo registrado. Procedimento de validação incluído. |

> **Regra deste documento:** nada é marcado como TESTADO (runtime) sem log ou
> arquivo de saída correspondente em `evidence/`. Toda célula de medição de
> desempenho vazia está vazia **porque não foi medida**.

---

## 1. Corpus fixo em português brasileiro

Texto canônico para **todas** as configurações comparáveis. Deve ser usado
byte-a-byte idêntico entre motores, senão a comparação não vale.

Arquivo: `corpus/pt-br-corpus.txt` (criado junto com este relatório).

| ID | Categoria | Texto |
|---|---|---|
| C1 | Conversação cotidiana | `Oi, tudo bem? Faz tempo que a gente não se fala. Senta aí, pega um café e me conta como estão as coisas.` |
| C2 | Pergunta e resposta | `Você já terminou aquele relatório? — Ainda não, mas falta pouco. Preciso revisar a última seção antes de enviar.` |
| C3 | Números, data, hora | `A reunião ficou marcada para 14 de março de 2027, às 9h30, na sala 1204, com 3 participantes e duração prevista de 45 minutos.` |
| C4 | Siglas e pontuação | `O IBGE divulgou os dados do PIB; segundo a ANATEL, a cobertura 5G chegou a 87% dos municípios — um avanço e tanto, não é?` |
| C5 | Nomes próprios e estrangeirismos | `A Gioconda trabalha na Uber desde o ano passado; ela mora em São Paulo, mas cresceu em Belo Horizonte. Ontem assistiu a um webinar sobre machine learning.` |
| C6 | Frase curta | `Tudo certo.` |
| C7 | Parágrafo longo | `Quando o assunto é tecnologia de voz, a naturalidade depende de muitos fatores ao mesmo tempo: a prosódia precisa acompanhar o sentido da frase, as pausas têm de cair nos lugares certos, e a entonação deve mudar quando o texto faz uma pergunta ou expressa surpresa. Se qualquer um desses elementos falhar, o ouvinte percebe imediatamente que está diante de uma máquina.` |
| C8 | Pausas e entonação | `Espera... você está me dizendo que o prazo era ontem? Ontem?! Mas ninguém me avisou nada — absolutamente nada.` |
| C9 | Marcadores brasileiros | `A gente vai fazer o seguinte: cê pega o carro, passa no mercado, e depois a gente se encontra lá no posto. Combinado?` |
| C10 | Números falados | `O valor total ficou em R$ 1.847,90, dividido em 12 parcelas de R$ 153,99. Ah, e o frete saiu de graça.` |

**Por que estas categorias:** cobrem exatamente os pontos onde TTS em pt-BR
costuma falhar — números por extenso, siglas pronunciadas como palavra vs.
letra, nomes próprios (`Gioconda`, `Uber`), estrangeirismos (`webinar`,
`machine learning`), e o registro coloquial brasileiro (`cê`, `a gente`), que é
onde modelos treinados majoritariamente em inglês costumam escorregar para um
português artificial.

---

## 2. Matriz de capacidade — inspeção estática

Status: **INSPECIONADO / TESTADO (estático)**. Nenhuma linha foi executada.

| # | Configuração | pt-BR? | Voz pronta | Clonagem | Voz por descrição | Windows | GPU AMD no Windows | Licença pesos |
|---|---|---|---|---|---|---|---|---|
| M1 | `omnivoice` (**padrão**) | ✅ `pt` na lista | — (clona) | ✅ | ✅ | ✅ | ❌ CPU only | **CC-BY-NC** |
| M2 | `omnivoice-gguf` | ✅ (mesmo modelo) | — | ✅ | ✅ | ✅ | ❌ CPU only | **CC-BY-NC** |
| M3 | `omnivoice-subprocess` | ✅ (mesmo modelo) | — | ✅ | ✅ | ✅ | ❌ CPU only | **CC-BY-NC** |
| M4 | `audiocpp` (Breeze-TTS-2) | ❌ **en+zh** | — | ✅ | ✅ | ✅ (Vulkan) | ✅ **Vulkan** | **Research/NC** |
| M5 | `voxcpm2` | ✅ (30 idiomas) | — | ✅ | ✅ | ✅ | ❌ CPU only | Apache-2.0 |
| M6 | `cosyvoice` | ✅ | — | ✅ | ❌ | ✅ | ❌ CPU only | Apache-2.0 |
| M7 | `kittentts` | ❌ en | ✅ (8) | ❌ | ❌ | ✅ | CPU (por design) | Apache-2.0 |
| M8 | `supertonic3` | ✅ (31 idiomas) | ✅ (7) | ❌ | ❌ | ✅ | CPU (por design) | OpenRAIL-M |
| M9 | `pockettts` | a verificar | — | ✅ | ❌ | ✅ | CPU (por design) | CC-BY-4.0 |
| M10 | `confucius4-tts` | provável | — | ✅ | ❌ | ✅ | ❌ CPU only | Apache-2.0 |
| M11 | `indextts2` | a verificar | — | ✅ | ❌ | ✅ | ❌ CPU only | "other"/não revisado |
| M12 | `dots-tts` | a verificar | — | ✅ | ❌ | ❌ **Linux/macOS only** | — | Apache-2.0 |
| M13 | `moss-tts-v15` | a verificar | — | ✅ | ❌ | ✅ | ❌ CPU only | Apache-2.0 |
| M14 | `mlx-audio` (Kokoro etc.) | ✅ (Kokoro) | ✅ | ❌ | ❌ | ❌ **Apple Silicon only** | — | Apache-2.0 |
| M15 | `gpt-sovits` | a verificar | — | ✅ | ❌ | ✅ (servidor externo) | — | MIT |
| M16 | `sherpa-onnx` | a verificar | ✅ | ❌ | ❌ | ✅ | CPU | Apache-2.0 |

Evidência da extração: `evidence/a3-engines-languages.txt`,
`evidence/a5-licensing.txt`.

**Cruzamento com o runtime (Fase E):** `GET /engines/tts` foi executado de fato e
listou **17 motores**, confirmando a coluna "disponível" para a instalação crua
(só `omnivoice` e `omnivoice-subprocess`) e devolvendo `effective_device = cpu`
para todos. O payload **não** expõe idiomas — a coluna "pt-BR?" desta tabela vem
de código e documentação, não da API. Ver `evidence/runtime/e2-engines.txt`.

### 2.1 Conclusão da matriz

**No alvo Windows + AMD + português brasileiro, a matriz deixa uma única
configuração com GPU:** M4 — que não fala português.

Tudo o que fala português roda em **CPU** nessa máquina. Isso não é um bug nem
uma limitação contornável por configuração; é uma consequência de
(a) PyTorch não ter ROCm para Windows e (b) o único runtime nativo com Vulkan
servir apenas inglês e chinês.

---

## 3. Fase B — instalação controlada

**Status: NÃO TESTADO.**

**Motivo:** ambiente de laboratório é Linux headless, sem `J:`, sem saída de
áudio, com 3.8 GiB de RAM e nenhuma GPU. Os instaladores oficiais são `.exe`
(NSIS) / `.dmg` / `.AppImage`. Instalar o app Electron e seus motores não é
possível nem representativo neste ambiente.

### 3.1 O que a inspeção estática estabeleceu sobre a instalação

| Item | Achado | Status |
|---|---|---|
| Instalador Windows oficial | `VoiceStudio-Electron-<versão>-win-x64.exe` (NSIS, por usuário, sem admin) | INSPECIONADO |
| Verificação de integridade | Releases publicam `SHA256SUMS.txt`; a release v0.5.6 publica `electron-stable-win-x64.yml` com `sha512` e `size` por asset | INSPECIONADO |
| Script de instalação remoto | `irm https://voicestudio.sh/install \| iex` — **não inspecionado, não executado** | NÃO TESTADO |
| Espaço em disco | ~10 GB (com NVIDIA) / ~5 GiB (CPU) | declarado pelo projeto |
| Diretório de motores | `<app data>\engines`; realocável com `OMNIVOICE_ENGINES_DIR` | INSPECIONADO |
| Diretório de dados | `OMNIVOICE_DATA_DIR` | INSPECIONADO |
| Python/uv gerenciados | bootstrap automático na primeira execução | INSPECIONADO |

> **Observação de segurança:** o README recomenda `irm ... | iex` no PowerShell.
> A missão proíbe executar isso sem inspecionar. O script existe no repositório
> (`scripts/install.sh`) e há um guia (`docs/install/script.md`). Preferir o
> **instalador `.exe` baixado do GitHub Releases com SHA-256 conferido**.

### 3.2 Procedimento de validação na máquina real

```powershell
# 1. Antes: registrar espaço
Get-PSDrive C,J | Select Name,@{n='GB_livre';e={[math]::Round($_.Free/1GB,1)}}

# 2. Baixar o instalador e o checksum oficiais da MESMA tag
$ver = '0.5.6'
gh release download "v$ver" --repo debpalash/VoiceStudio `
  --pattern "VoiceStudio-Electron-$ver-win-x64.exe" --pattern "*SHA256SUMS*"

# 3. Conferir o hash ANTES de executar
Get-FileHash ".\VoiceStudio-Electron-$ver-win-x64.exe" -Algorithm SHA256
# comparar manualmente com o valor publicado na release

# 4. Instalar (escopo do usuário), escolhendo J:\VoiceStudio-Lab\app como destino
.\VoiceStudio-Electron-$ver-win-x64.exe

# 5. Depois: registrar espaço consumido
Get-PSDrive C,J | Select Name,@{n='GB_livre';e={[math]::Round($_.Free/1GB,1)}}
```

Critérios de aceite: app inicia · backend responde em `/health` · gera áudio
com o corpus C6 · encerra sem processo órfão · reinicia e ainda funciona.

---

## 4. Fase C — teste de qualidade de voz

**Status: NÃO TESTADO (nenhuma geração de áudio foi produzida).**

**Motivo:** sem saída de áudio, sem GPU, RAM insuficiente para o modelo padrão
(2.4 GiB de pesos + PyTorch em 3.8 GiB sem swap), e — decisivo — **avaliação
subjetiva de naturalidade exige um ouvinte humano**. O agente não pode ouvir
nem julgar naturalidade, prosódia ou sotaque.

Isto é uma limitação real, não uma formalidade. **Nenhuma nota de qualidade,
nenhuma comparação com ElevenLabs e nenhuma afirmação sobre sotaque brasileiro
é feita neste relatório.**

### 4.1 O que precisa ser testado, em que ordem

Ordem de prioridade, dado que cada configuração exige download próprio:

| Prioridade | Configuração | Por quê | Download estimado |
|---|---|---|---|
| 1 | M1 `omnivoice` + voz pronta | É o padrão; responde "dá para usar hoje?" | 2.4 GiB |
| 2 | M1 + clonagem autorizada | Caso de uso central da Lia | 0 (mesmo modelo) |
| 3 | M1 + voz por descrição | Diferencial competitivo | 0 (mesmo modelo) |
| 4 | M5 `voxcpm2` | Melhor alternativa Apache-2.0 com pt | ~4–8 GiB |
| 5 | M8 `supertonic3` | CPU puro, rápido, pt, mas sem clone | ~400 MB |
| 6 | M4 `audiocpp` | **só** para responder à pergunta Vulkan/AMD | ~4.73 GiB + runtime |

### 4.2 Grade de avaliação (a ser preenchida por um humano ouvindo)

Para cada par (configuração × item do corpus), registrar:

| Campo | Escala |
|---|---|
| Pronúncia | 1–5 (1 = ininteligível, 5 = perfeita) |
| Naturalidade / prosódia | 1–5 |
| Sotaque percebido | pt-BR / pt-PT / neutro / estrangeiro / inaudível |
| Artefatos | nenhum / leve / moderado / grave (descrever: chiado, corte, robótico, clipping) |
| Números e datas (C3, C10) | corretos / parcialmente / errados (transcrever o que foi falado) |
| Siglas (C4) | corretas / erradas |
| Estrangeirismos (C5) | corretos / abrasileirados / errados |
| Pausas (C8) | naturais / mecânicas / ausentes |
| Consistência entre gerações | estável / varia timbre / varia ritmo |
| Adequação a conversação em tempo real | sim / não / com ressalvas |

**Semântica de áudio — abordagem objetiva recomendada.** Para complementar (não
substituir) a escuta humana, rode ASR sobre a saída e compare com o texto de
entrada. O próprio VoiceStudio expõe `POST /v1/audio/transcriptions`, então a
verificação pode ser feita com a mesma instalação. Divergência em C3/C4/C10 é
o sinal mais confiável de erro de pronúncia de números e siglas.

### 4.3 Onde salvar as amostras

```
reports/evidence/audio/<config>/<corpus-id>.wav
reports/evidence/audio/<config>/<corpus-id>.json   # métricas + parâmetros
```

Parâmetros exatos a registrar por arquivo: `engine`, `model`, `language=pt`,
`num_step`, `guidance_scale`, `speed`, `seed`, `postprocess_output`,
`effect_preset`, `wav_bits`, e o **hash SHA-256 do texto de entrada**.

---

## 5. Fase D — AMD, CPU e Vulkan

**Status: hardware instalado e primeira geração medida (fria). Demais medições
pendentes.**

A máquina-alvo foi identificada pela coleta de 2026-10-23
(`evidence/windows/20261023-140732/`):

| Item | Valor |
|---|---|
| CPU | AMD Ryzen 5 5500 — 6C/12T |
| GPU | AMD Radeon RX 580 2048SP (Polaris 20, `gfx803`), driver 31.0.21925.1001 |
| VRAM | ~4 GB reportados (CIM satura em 4 GB; confirmar via `gpu-report`) |
| RAM | 15,89 GB (6,65 GB livres na coleta) |
| Vulkan | loader 1.3.250 funcional |
| VoiceStudio | instalado em 2026-10-23 14:22 (`v0.5.6`), `/health` = `ok`, `device = cpu` |

`gfx803` fica fora do suporte do ROCm moderno **e** fora da tabela
`ROCM_GFX_OVERRIDES` do projeto. Para esta placa, não existe caminho de GPU para
PyTorch — nem no Windows, nem no Linux.

### 5.0 Primeira medição real (2026-10-23 14:44)

`evidence/windows/20261023-144336/`, corpus **C6** ("Tudo certo."), motor
`omnivoice` ativo, `device=cpu`, seed 42:

| Métrica | Valor |
|---|---|
| HTTP | 200 |
| tempo de parede | 40,67 s |
| duração do áudio | 1,01 s |
| `X-Gen-Time` (servidor) | 40,32 s |
| **RTF** | **39,9** |

**Como ler isso:** RTF ≈ 40 significa **40 s de processamento por segundo de
áudio**. Uma frase de 10 s levaria ~6,6 min. Isso torna inviável qualquer uso
conversacional nesta máquina.

**Ressalva obrigatória:** é a **primeira** geração do processo e inclui a carga
dos pesos do OmniVoice (2,4 GB). O protocolo exige a primeira execução separada
justamente por isso — este número **não** é o RTF de regime. A medição válida
sai das execuções 2+ do modo `/voice` (10 frases) ou `/full` (4× C7).

O app confirma o que a análise estática previa: `gpu_routing` = `omnivoice — cpu
(no accelerator on this host)`. Não há GPU no caminho.

O que falta: rodar `run-lab.bat /voice` (ou `/full`) com o app já aberto e o
modelo em cache, e comparar a execução 1 com as seguintes.

### 5.1 O que foi estabelecido por inspeção (com evidência)

| Questão | Resposta | Base |
|---|---|---|
| PyTorch acelera Radeon no Windows? | **Não.** Build CUDA-only ou CPU-only | `docs/install/windows.md` |
| Existe opção ROCm no Windows? | **Não** (`OMNIVOICE_TORCH_VARIANT=rocm` é Linux-only, ignorado no Windows) | `docs/install/windows.md` |
| O VoiceStudio detecta AMD? | **Sim**, e relata corretamente em `gpu-report` / `diagnose` | `backend/core/device_caps.py` |
| Há remapeamento GFX para Radeon? | **Sim**, para RDNA 2/3/3.5 e Vega — mas em ROCm/Linux | `ROCM_GFX_OVERRIDES` |
| `audio.cpp` tem build Windows Vulkan? | **Sim**, com SHA-256 fixado no código | `bootstrap.py` |
| `audio.cpp` fala português? | **Não.** `supported_languages == ["en","zh"]` | `audiocpp/__init__.py` |
| `audio.cpp` usa a GPU automaticamente? | Não cegamente: roda `--list-devices`, prefere CUDA→ROCm→Metal→Vulkan discreto→CPU, e **descarta adaptadores de software (llvmpipe)** | `bootstrap.py` |
| DirectML? | **Não é opção** — `torch-directml` exige PyTorch 2.4 | `docs/install/windows.md` |
| NPU Ryzen AI? | **Não é usada** | `docs/install/windows.md` |

### 5.2 O que ainda não se sabe (e só a máquina real responde)

- **OmniVoice GGUF em Vulkan** — a hipótese mais promissora e ainda não testada.
  O motor `omnivoice-gguf` roda `omnivoice.cpp` (GGML), e o docstring do próprio
  backend diz que o binário *"statically links GGML/GGML-cpu and dlopens
  GGML-cuda / GGML-vulkan when present"*. Ou seja: o mesmo truque que faz Qwen
  rodar em Vulkan **poderia** valer para português aqui. O que falta:
  1. o motor declara `gpu_compat = ("cuda", "mps", "cpu")` — **Vulkan não está
     declarado**;
  2. o wrapper nunca passa `-ngl`/device nenhum no argv;
  3. o binário Windows é distribuído sem `bin/` no repositório (placeholders de
     zero byte), então **não se sabe** se ele inclui o backend Vulkan;
  4. o `quant_map` escolhe Q4_K_M (~659 MB no total) em host sem CUDA/MPS — o
     que **cabe** nos ~4 GB da RX 580, ao contrário do piso de 6 GB do modelo em
     PyTorch.
  Teste: `run-lab.bat /gguf` — procura o executável em
  `<app>\resources\bin\`, lista as DLL `ggml*`, lê o `reason` de
  `/engines/tts`, gera uma frase com `engine=omnivoice-gguf` (se disponível) e
  captura `/system/logs`, onde o `omnivoice-tts` anuncia o dispositivo
  escolhido. Saída em `gguf.json`.
  **Se o binário não existir no build do Windows**, o teste vira diagnóstico e a
  medição só é possível compilando `omnivoice.cpp` (`buildvulkan.sh`), o que
  exigiria MSVC + Vulkan SDK — outra escala de esforço, a autorizar à parte.
- Se a Radeon específica do usuário expõe um dispositivo Vulkan discreto que o
  `audiocpp_server` reconhece.
- Se o Vulkan do Windows nessa máquina é mais rápido que CPU — **não pode ser
  afirmado sem medição pareada**.
- Qual o overhead real de primeira execução (compilação de shaders/grafo).

### 5.3 Protocolo de medição (3+ gerações, primeira separada)

Use **exatamente** o mesmo texto (C7, parágrafo longo, é o mais estável) e o
mesmo seed. Repita para CPU e para Vulkan, nessa ordem e depois invertida, para
reduzir viés térmico.

```powershell
$body = @{ text = (Get-Content .\corpus\C7.txt -Raw); language = 'pt' }
foreach ($i in 1..4) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  curl.exe -s -o "out_$i.wav" -w "%{http_code}" `
    -X POST http://127.0.0.1:3900/generate `
    -F "text=$($body.text)" -F "language=pt" -F "seed=42" `
    -D "headers_$i.txt"
  $sw.Stop()
  "{0},{1},{2}" -f $i, $sw.Elapsed.TotalSeconds, (Get-Content "headers_$i.txt" | Select-String 'X-OmniVoice-Routing')
}
```

Registrar por execução:

| Campo | Como obter |
|---|---|
| Tempo total | `curl -w "%{time_total}"` |
| **Tempo até o primeiro áudio** | só via `WS /ws/tts` — o frame `done` traz `ttfa_ms` |
| Duração do áudio | `(Get-Item out.wav)` + duração via ffprobe/ffmpeg |
| **RTF** | tempo de geração ÷ duração do áudio. Via WS vem pronto no campo `rtf` |
| Dispositivo efetivo | header `X-OmniVoice-Routing` + `GET /health` campo `device` |
| CPU / RAM | `Get-Counter '\Process(python*)\% Processor Time'`; pico de RAM do processo |
| GPU | Gerenciador de Tarefas → GPU dedicada, ou `Get-Counter '\GPU Engine(*)\Utilization Percentage'` |
| Sucesso/falha | código HTTP + mensagem |

**Regra:** descartar a execução 1 do cálculo de RTF (é carga de modelo), e
reportar as execuções 2–4 separadamente. É o que a própria doc do projeto
recomenda.

---

## 6. Fase E — API local e comportamento operacional

**Status: INSPECIONADO (código) + ✅ TESTADO (runtime).**

O backend sobe sem o Electron (`uvicorn main:app`) e foi exercitado por HTTP
real neste sandbox Linux/CPU. Resultados completos em
`evidence/runtime/README.md` e `evidence/runtime/e1…e6`.

Ainda **NÃO TESTADO**: geração real de áudio (pesos vêm do Hugging Face, que
não é alcançável deste sandbox) e comportamento no Windows.

### 6.1 Superfície relevante (extraída do código)

340 rotas no total. As que importam para uma integração externa:

| Endpoint | Método | Uso |
|---|---|---|
| `/health` | GET | Liveness. **503** com `{status:"starting", step, label}` durante o boot; **200** `{status:"ok", device, version}` quando pronto |
| `/startup/progress` | GET | Fase do boot; sempre 200 |
| `/engines` | GET | `{tts:[...], asr:[...], llm:[...]}` com disponibilidade e device resolvido |
| `/engines/tts` | GET | Só TTS, mesma forma |
| `/engines/{id}/health` | GET | Saúde de um motor específico |
| `/engines/select` | POST | Trocar motor (admin) |
| `/generate` | POST | **multipart/form-data** — geração completa |
| `/generate/budget` | GET | Orçamentos de tempo ativos |
| `/v1/audio/speech` | POST | **JSON, compatível com OpenAI** |
| `/v1/audio/voices` | GET | Vozes: aliases OpenAI + perfis do banco |
| `/ws/tts` | WS | Streaming com métricas (`ttfa_ms`, `gen_time_s`, `rtf`) |
| `/profiles` | GET/POST | Perfis de voz (clonagem) |
| `/model/loaded` | GET | O que está residente em memória |
| `/system/flush-memory` | POST | Liberar VRAM/RAM |
| `/system/diagnose` | GET | Autodiagnóstico de hardware |
| `/system/info` | GET | Info do sistema |

### 6.2 Contratos exatos

**`POST /generate`** — `multipart/form-data`. Campos principais:
`text` (obrigatório), `language`, `ref_audio` (arquivo), `ref_text`, `instruct`,
`profile_id`, `engine`, `seed`, `num_step`, `guidance_scale`, `speed`,
`postprocess_output`, `effect_preset`, `wav_bits` (`16|24|32`),
`max_chunk_chars` (default 800), `crossfade_ms` (default 50), `pronounce`,
`stream` (boolean).

O texto passa por normalização **NFC** antes da síntese — detalhe relevante para
texto pt-BR com acentos decompostos vindos de macOS ou de certos editores.

**`POST /v1/audio/speech`** — `application/json`, espelha
`CreateSpeechRequest` da OpenAI. Campos: `model`, `input`, `voice`, `instructions`,
`response_format`, `speed`, `stream_format` (`audio|sse`), `language`, `instruct`,
`seed`, `denoise`, `num_step`, `guidance_scale`, `duration`.

Formatos de resposta (`SpeechFormat`): **`mp3`, `opus`, `aac`, `flac`, `wav`,
`pcm`**. Os comprimidos exigem **ffmpeg** e falham rápido se ausente.

**`WS /ws/tts`** — o frame final `done` devolve `ttfa_ms` (request→primeiro
áudio), `gen_time_s` (wall clock) e `rtf` (tempo de síntese ÷ duração do áudio).
É a **única** forma de obter tempo-até-primeiro-áudio. Para conversação em tempo
real, este é o endpoint que importa — não o `/generate`.

### 6.3 Autenticação e isolamento

Fonte: `docs/api-auth.md`.

| Contexto | Comportamento |
|---|---|
| **Loopback** (`127.0.0.1`, `::1`, `localhost`) | **Nunca autenticado.** Nenhuma chave, nenhum header |
| Fora do loopback, sem configuração | Bloqueado por padrão |
| `OMNIVOICE_API_KEY` definida | Exige `Authorization: Bearer <key>` em HTTP **e** WebSocket; loopback continua isento |
| PIN de compartilhamento | 6 dígitos, só LAN casual, **não** protege admin |
| Admin (`/system/*`, `/api/settings/*`) | Só loopback ou API key; PIN nunca serve |
| CORS | Allow-list fechada: loopback + `app://voicestudio` |
| DNS rebinding | Bloqueado: `Host` precisa ser IP, localhost, hostname local ou allow-list |

**Para a Lia, isto é ideal:** um processo local chamando `127.0.0.1:3900` não
precisa de chave alguma, e o serviço **não fica exposto à rede** por padrão.

### 6.4 Comportamento quando o app fecha

**Status: INSPECIONADO.** O backend FastAPI é **filho do processo Electron**,
que o supervisiona e o encerra junto. Não é um serviço do Windows. Evidência:
`docs/production-private-api.md` diz explicitamente para usar a **imagem Docker**
quando se quer um serviço independente; e o README descreve o Electron como
"starts and supervises the backend".

**Implicação para a Lia:** se a dependência for o app desktop, **fechar o app
derruba a API**. A integração precisa tratar isso como estado normal, não como
erro — e a Fase G propõe exatamente isso.

### 6.5 Testes de falha — status após execução em runtime

| Cenário | Ação | Resultado observado | Status |
|---|---|---|---|
| Serviço no ar | `GET /health` | `200 {"status":"ok","device":"cpu","version":"0.5.7-beta.1"}` | ✅ TESTADO |
| Boot em andamento | `GET /startup/progress` | etapa a etapa com tempo; `status:"ready"` ao fim | ✅ TESTADO |
| Inventário de hardware | `GET /system/info` | cpu_model, ram, gpu_name vazio, timeouts 300/600 | ✅ TESTADO |
| Listar motores | `GET /engines/tts` | 17 motores, 2 disponíveis, `reason` em texto claro | ✅ TESTADO |
| Motor inexistente | `/generate`, `engine=nao-existe` | `400` + lista de ids válidos | ✅ TESTADO |
| Modelo inexistente (OpenAI) | `/v1/audio/speech` | `400`, `error.code=model_not_found` | ✅ TESTADO |
| Licença não aceita | `/generate` em modelo gated | `403 model_licence_required` + `fingerprint` | ✅ TESTADO |
| Aceite headless | `POST /models/licenses/accept` | `200`, grava `accepted_at` | ✅ TESTADO |
| Pesos inacessíveis | `/generate` após aceite, sem rede | **`500 HF_AUTH_FAILED`** (não é 4xx) | ✅ TESTADO |
| Isolamento de rede | `ss -lntp` | processo preso a `127.0.0.1:3900` | ✅ TESTADO |
| Serviço indisponível | requisição com o app fechado | — | NÃO TESTADO (sem Electron) |
| Motor não instalado | `/generate engine=supertonic3` | `400` + "package not installed" | ✅ TESTADO |
| Referência inválida | `ref_audio` em motor que não clona | — | NÃO TESTADO |
| GPU saturada | concorrência | — | NÃO TESTADO |
| Porta ocupada | segunda instância | — | NÃO TESTADO |

#### Correção importante sobre timeouts

A leitura estática sugeria "600 s de orçamento em CPU". O runtime mostra que
`GET /generate/budget` devolve:

```json
{"modelLoad":1200, "queueWait":1800, "executionBase":600,
 "progressExtensionCap":1800, "cpuAutoCeiling":7200}
```

`executionBase` é só a base; há extensão por progresso (até 1800 s) e um teto
automático de CPU de **7200 s**. Um cliente que use timeout fixo de 660 s corta
gerações que o servidor considera legítimas. **Ler `/generate/budget` e somar as
parcelas aplicáveis**, não assumir "600 s".

---

## 7. Fase F — licenças

Ver `licensing.md` (documento dedicado). Status: **INSPECIONADO**, com fontes
primárias verificadas.

---

## 8. Fase G — proposta de integração

Ver `integration-proposal.md`. Status: **ANÁLISE ARQUITETURAL**, sem
implementação, conforme exigido.

---

## 9. Resumo de cobertura

| Fase | Cobertura | Status dominante |
|---|---|---|
| A — investigação estática | **Alta** | INSPECIONADO / TESTADO (estático) |
| B — instalação | **Nula** | NÃO TESTADO (ambiente incompatível) |
| C — qualidade de voz | **Nula** | NÃO TESTADO (sem áudio, sem ouvido, pesos inacessíveis) |
| D — AMD/Vulkan | **Parcial** (só documental) | NÃO TESTADO (sem GPU) |
| E — API | **Alta** (código **e** runtime) | ✅ TESTADO — backend exercitado por HTTP |
| F — licenças | **Alta** | ✅ INSPECIONADO + confirmado em runtime |
| G — integração | **Análise** | — |

Onde o runtime corrigiu a inspeção: orçamento de tempo (não é 600 s) e ausência
de `supported_languages` na API. Ambos registrados acima e em
`evidence/runtime/README.md`.
