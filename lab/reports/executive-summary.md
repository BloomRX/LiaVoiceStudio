# executive-summary.md — Conclusão e recomendação

**Missão:** avaliar o VoiceStudio como solução local de geração de voz para a Lia,
antes de qualquer integração.
**Data:** 2026-10-23 · **Versão avaliada:** `main` @ `48e85106` (estável de
referência: **v0.5.6**)

---

## 1. O que foi possível fazer — e o que não foi

Preciso começar pelo limite, porque ele condiciona tudo o que vem depois.

**A missão pressupunha uma máquina Windows com GPU AMD e disco `J:`. Esse
ambiente não existe *dentro* do laboratório do agente.** O agente roda em um
contêiner Linux headless, sem `J:`, sem GPU, sem saída de áudio, com 3.8 GiB de
RAM e 2 vCPU. A solução adotada foi inverter o fluxo: em vez de eu testar de
fora, um único `run-lab.bat` **roda na máquina do operador** e traz as medições
de volta. É por isso que a coluna abaixo já não diz "não testado" na maioria
das fases.

Consequência direta:

| Fase | Status real |
|---|---|
| A — investigação estática | ✅ **Executada** — leitura de README, 100+ documentos e do código da versão fixada |
| B — instalação | ✅ **Testada na máquina real** — o `run-lab.bat` instalou (SHA-256 conferido, `/S`), baixou o modelo e gerou WAV. Falta o ciclo fechar/reabrir |
| C — qualidade de voz | 🟡 **Áudio gerado (10 frases) + análise acústica objetiva** (§2.4.2); audição humana pendente — é o único juiz possível |
| D — AMD / Vulkan | ✅ **Medido: RTF 25,9 em regime** (10 frases, CPU). GGUF testado e ausente; `/gpu` (audio.cpp/Vulkan) **pendente** |
| E — API local | ✅ **TESTADA em runtime** — backend real exercitado por HTTP (ver §2.6) |
| F — licenças | ✅ **Executada** com fontes primárias, confirmada em runtime |
| G — integração | ✅ **Análise arquitetural**, sem implementação |

**Nenhuma nota de naturalidade é apresentada neste relatório. Não houve
comparação com ElevenLabs nem audição humana.** Os números de tempo que aparecem
foram medidos pelo `run-lab.bat` na máquina-alvo e estão em
`evidence/windows/20261023-150843/`; o que não foi medido está marcado como
**pendente**, com o procedimento ao lado.

Uma ressalva sobre a Fase E: o backend **subiu e respondeu** (Linux, CPU), mas
**nenhum áudio foi gerado ali**, porque os pesos vêm do Hugging Face e esse
domínio não é alcançável deste sandbox. "API validada" no ambiente do agente
significa contrato, códigos de erro e isolamento — a geração de áudio foi
validada depois, na máquina do operador.

---

## 2. As três descobertas que decidem a questão

### 2.1 O caminho Vulkan/AMD existe — mas não fala português

Este é o achado mais importante e ele contraria a expectativa implícita da missão.

A missão pede para investigar "`audio.cpp` e Breeze-TTS-2 para Vulkan e Radeon".
A investigação confirmou que **o suporte é real**:

- `docs/engines/audio-cpp.md`: `Windows x64 | CPU, Vulkan, CUDA`.
- `backend/engines/audiocpp/bootstrap.py` fixa o binário
  `audio-v0.7.4-bin-windows-x64-vulkan.zip` com SHA-256.
- O upstream `0xShug0/audio.cpp` publica assets Vulkan para Windows (verificado
  na API do GitHub, release v0.9.2).
- O código faz descoberta real de dispositivo (`--list-devices`,
  `--list-devices` com timeout, filtro de adaptador de software/llvmpipe,
  preferência CUDA→ROCm→Metal→Vulkan discreto→CPU).

**Mas:** `backend/engines/audiocpp/__init__.py` retorna
`supported_languages = ["en", "zh"]`. O card oficial do Breeze-TTS-2 confirma:
*"Bilingual Support — Generates natural English and Chinese speech."*

**O único caminho de GPU que funciona numa Radeon no Windows serve apenas
inglês e chinês.** Para o caso de uso da Lia — português brasileiro — ele é
inútil.

### 2.2 Tudo o que fala português roda em CPU nesse hardware

O projeto é explícito, e a documentação confere com o código:

> "**PyTorch GPU acceleration on Windows is NVIDIA/CUDA-only.** (...) **AMD GPUs
> — including Ryzen / Ryzen AI integrated Radeon graphics — do not accelerate
> PyTorch engines on Windows.**" — `docs/install/windows.md`

A opção ROCm do VoiceStudio (`OMNIVOICE_TORCH_VARIANT=rocm`) é **Linux-only** e
é ignorada no Windows. DirectML não é viável (exige PyTorch 2.4). A NPU Ryzen AI
não é usada.

O código tem suporte AMD sofisticado — `ROCM_GFX_OVERRIDES` remapeia
`HSA_OVERRIDE_GFX_VERSION` para RDNA 2/3/3.5 e Vega — mas **isso é ROCm, e ROCm
no Windows não é suportado**.

**Resultado líquido:** numa máquina Windows + Radeon, o VoiceStudio com
português brasileiro é inferência em **CPU**. Sem exceção entre os motores que
falam português.

### 2.3 Confirmado no hardware real: a RX 580 piora o quadro

A primeira coleta do `run-lab.bat` identificou a máquina: **Ryzen 5 5500,
15,89 GB de RAM, Windows 11 build 26200, e uma Radeon RX 580 2048SP**.

A RX 580 é **Polaris 20, `gfx803`**. Isso fecha três portas de uma vez:

- **ROCm não suporta `gfx803`** — nem no Linux. O conselho "instale Linux para
  ter ROCm" da documentação **não** salva esta placa.
- **A tabela `ROCM_GFX_OVERRIDES` do projeto não tem entrada para Polaris**
  (cobre gfx900/906, 1030, 1100, 1150/1151). Não existe nem o contorno por
  `HSA_OVERRIDE_GFX_VERSION`.
- ~~~4 GB de VRAM ficam abaixo do piso de 6 GB~~ **— retirado.** A placa tem
  **8 GB**; os 4 GB vinham do `AdapterRAM` do WMI, que satura em `2³²−1`.
  Com 8 GB, o Q4_K_M do OmniVoice-GGUF (~659 MB) cabe com folga. **Capacidade
  não é o obstáculo** — o obstáculo é que o runtime GGML não vem no build do
  Windows.

**Vulkan funciona** nesta placa (loader 1.3.250 respondeu). Mas o único motor que
o app expõe por Vulkan — `audio.cpp` rodando Breeze-TTS-2 — só fala inglês e
chinês. *(Existe uma exceção que eu não testei; ver a ressalva ao fim desta
seção.)*

O app **confirmou isso na própria tela de verificação**, depois de instalado:

```
GPU acceleration    ⚠ No compatible GPU detected — running CPU-only.
Active engine routing  ✅ omnivoice — cpu (no accelerator on this host)
```

Não é inferência da análise estática: é o `gpu_routing_verdict()` do app sobre
esta máquina. Captura e transcrição em
[`evidence/install/README.md`](evidence/install/README.md).

Para *esta* máquina, no motor **padrão**, o caminho em português é o Ryzen em
CPU. Detalhe em `environment.md` §4.

> **Ressalva — agora resolvida por teste.** A porta do `omnivoice-gguf` (runtime
> `omnivoice.cpp`, GGML, que faria *dlopen* de `ggml-vulkan`) foi testada na
> máquina-alvo e **não existe neste build**: `binary_found=false`,
> `ggml_libs=[]`. Ver §4.2. A VRAM (8 GB) deixa de ser argumento: o obstáculo é
> o binário ausente, não a placa.

### 2.4 A primeira geração real: RTF ≈ 40 em CPU

Em 2026-10-23 14:44 a máquina-alvo gerou áudio pela primeira vez
(`evidence/windows/20261023-144336/`). Corpus C6 ("Tudo certo."), `device=cpu`:

| Métrica | Valor |
|---|---|
| duração do áudio | 1,01 s |
| `X-Gen-Time` no servidor | 40,32 s |
| tempo de parede | 40,67 s |
| **RTF** | **39,9** |

À primeira vista, **40 segundos de processamento por segundo de fala**. Uma fala
de 10 s levaria uns 6,6 min.

Repetida duas vezes mais, mesma frase, mesma máquina, mesmo app reaberto:

| Coleta | `X-Gen-Time` | RTF |
|---|---|---|
| 14:44 | 40,32 s | 39,9 |
| 14:50 | **172,74 s** | **158,5** |
| 14:57 | 39,45 s | 39,1 |

**Nenhuma das três é o RTF do sistema** — são primeiras gerações, com o
carregamento de 2,4 GB de pesos embutido.

O regime veio em seguida, com o corpus inteiro (`/voice`, 10 frases, uma sessão).

### 2.4.1 O número que decide: RTF 25,9

| # | Corpus | áudio (s) | geração (s) | RTF |
|---|---|---|---|---|
| 1 | C1 | 6,01 | 160,70 | 26,7 |
| 2 | C2 | 6,92 | 174,35 | 25,2 |
| 3 | C3 | 11,76 | 302,07 | 25,7 |
| 4 | C4 | 8,68 | 229,05 | 26,4 |
| 5 | C5 | 9,48 | 237,20 | 25,0 |
| 6 | C6 | 1,01 | 39,51 | 39,1 |
| 7 | C7 | 22,43 | 583,62 | 26,0 |
| 8 | C8 | 6,68 | 169,40 | 25,4 |
| 9 | C9 | 7,04 | 179,85 | 25,5 |
| 10 | C10 | 8,04 | 207,07 | 25,8 |

**38 minutos de CPU para 88 segundos de áudio.** A relação é linear:

```
gen_s ≈ 2,6 + 25,63 × audio_s      (erro 0,6–3,5 % nas frases > 1 s)
```

A medição é **reprodutível**: a mesma C6 gerada duas vezes seguidas deu 40,31 s
e 39,96 s (0,9 % de diferença), e o outlier de 173 s não reapareceu em 8
execuções. Ele foi um incidente daquela sessão, não variância do motor.

**O que isso significa na prática:** o VoiceStudio leva ~26 s de processamento
para cada segundo de fala nesta máquina.

| Fala da Lia | Tempo de geração |
|---|---|
| 3 s (frase curta) | ~1,3 min |
| 10 s (parágrafo) | ~4,3 min |
| 30 s (explicação) | ~13 min |

**Uso conversacional está descartado** — não por impressão, por medição. O que
sobra, e é real: geração assíncrona (audiolivro, narração em lote, mensagens
pré-renderizadas).

O que já se pode afirmar com segurança: **não há GPU no caminho**
(`omnivoice — cpu (no accelerator on this host)`, dito pelo próprio app), então o
teto de desempenho é o Ryzen 5 5500, sem margem para "ligar a placa depois".

### 2.4.2 A qualidade: o que o sinal já diz sem ninguém ouvir

Os 10 WAVs acima foram analisados por sinal (YIN para F0, ver `test-matrix.md`
§4.4). O **nível está correto**: pico 0,78–0,80, zero clipping, nenhum silêncio
anômalo. Mas a **identidade vocal não se mantém**: com a mesma voz, o mesmo seed
e o mesmo motor, o F0 mediano por frase variou de **119 Hz a 316 Hz — 2,64×**.
C1 soa (pelo menos no papel) uma oitava acima de C3; C8 e C10 ficam no meio.

Os saltos de oitava do estimador ficaram baixos (1,5–11%), então **não é erro de
medição**: é a voz derivando entre frases. Em uso conversacional isso apareceria
como "a Lia trocou de pessoa no meio da conversa".

**A ressalva é obrigatória:** nenhum humano ouviu esses arquivos ainda. A análise
detecta instabilidade, clipping e silêncio; **não** detecta pronúncia errada de
"IPTU", "WhatsApp" ou entonação de pergunta. A Fase C continua **parcialmente
testada**, e o teste que falta custa 10 minutos de fone de ouvido — comece por
C1, C8 e C10.

### 2.5 O melhor motor em português é o de licença mais restritiva

| Motor | pt-BR | Clone | Design | Licença dos pesos |
|---|---|---|---|---|
| **OmniVoice** (padrão) | ✅ | ✅ | ✅ | **CC-BY-NC** |
| **Breeze-TTS-2** (Vulkan/AMD) | ❌ | ✅ | ✅ | **Research/NC** (inclui outputs self-hosted) |
| VoxCPM2 / CosyVoice | ✅ | ✅ / ❌ | ✅ / ❌ | Apache-2.0 |

O card do OmniVoice: *"The pre-trained model is licensed under the **CC-BY-NC**
due to constraints from its training data (e.g., Emilia)."*

O `model_licenses.json` do próprio projeto registra `commercial_inference:
restricted` e **`commercial_outputs: unknown`**.

Tradução prática: **uso pessoal e local, livre. Uso comercial, bloqueado no
motor padrão e juridicamente incerto quanto ao áudio gerado.**

Para a Lia, isso significa que a decisão de motor **não é técnica, é de produto**
— e precisa ser tomada antes de escrever código.

### 2.6 O que o teste real da API acrescentou

O backend Python sobe sozinho, sem o Electron, e foi exercitado por HTTP neste
sandbox. Detalhes em `evidence/runtime/`. Quatro achados que só o runtime daria:

**a) O gate de licença é granular e auditável.** `POST /generate` devolve
**403** com `repo_id`, `license`, `category` e um `fingerprint` versionado. E o
OmniVoice exige **duas** licenças distintas — a do modelo (CC-BY-NC) **e** a do
tokenizador (`eustlb/higgs-audio-v2-tokenizer`, `NOASSERTION`). A camada do
tokenizador que eu havia sinalizado por leitura de documento **é um segundo
portão efetivo**, não uma nota de rodapé.

**b) O aceite pode ser feito por API.** `POST /models/licenses/accept` com
`{repo_id, fingerprint, accepted:true}` → `200`. Provisionamento automatizado
funciona — mas o fingerprint só aparece no 403 ou em `/models/licenses/details`.

**c) A API não diz quais idiomas cada motor fala.** `supported_languages` **não**
está no payload de `/engines/tts`. A Lia não pode perguntar "este motor fala
pt-BR?" — precisa de um mapa estático próprio. Isso corrigiu a proposta de
integração.

**d) Falha de rede ao carregar pesos devolve `500`, não 4xx.**
`{"error_class":"HF_AUTH_FAILED"}`. A Lia precisa mapear isso para "provedor
indisponível", nunca para "erro fatal" — senão uma queda de rede vira incidente.

Também corrigi um número que eu havia inferido errado: `GET /generate/budget`
devolve `executionBase: 600` **mais** `progressExtensionCap: 1800` e
`cpuAutoCeiling: 7200`. "600 s" é a base, não o teto — um cliente com timeout de
660 s cortaria gerações legítimas.

---

## 3. O que é genuinamente bom no VoiceStudio

Seria injusto resumir o projeto às suas limitações. A inspeção mostrou engenharia
séria:

- **API local muito bem feita.** Loopback-only por padrão, **sem autenticação
  em loopback**, admin separado do consumo, proteção contra DNS rebinding, CORS
  fechado. É exatamente o modelo certo para um processo local consumido por
  outro processo local.
- **Compatibilidade com OpenAI** em `/v1/audio/speech` — o formato mais fácil de
  integrar que existe hoje.
- **Métricas de streaming prontas.** `/ws/tts` devolve `ttfa_ms`, `gen_time_s` e
  `rtf` no frame final. Isso é raro e resolve o problema de medir latência real
  de conversação.
- **Orçamentos de tempo por classe de hardware**, expostos em
  `/generate/budget` (base de 300 s acelerado / 600 s CPU, com extensão por
  progresso) em vez de constantes mágicas.
- **Consentimento de voz como cidadão de primeira classe**: endpoints de
  `consent`, `attestation` e `lock` por perfil de voz.
- **Transparência incomum sobre o próprio estado**: `gpu-report` por motor com
  o motivo de cada fallback; `diagnose`; licenças por modelo com
  `review_status` explícito, incluindo 54 modelos marcados `unreviewed` em vez
  de fingir que estão resolvidos.
- **Pin de SHA-256 por artefato binário** e verificação de tamanho no instalador
  de runtime.

O projeto **não mente sobre si mesmo** — e isso é o que tornou esta avaliação
possível sem instalar nada.

---

## 4. Classificação das alternativas

### 4.1 Motor padrão (OmniVoice) — com clonagem e design em pt-BR

> ### 🟡 **PRECISA DE MAIS EVIDÊNCIAS** — com uma ressalva de desempenho já medida

**O que já está medido:** funciona em pt-BR, gera áudio correto (24 kHz mono,
HTTP 200 em 10/10 frases) e a API é estável. **RTF 25,9** — 26 s de CPU por
segundo de fala.

**O que isso elimina:** conversa em tempo real nesta máquina. Não há ajuste de
configuração que compense 26×.

**O que continua em aberto:** a **qualidade** do áudio em pt-BR. Nenhum humano
ouviu as 10 amostras ainda, e não existe benchmark publicado pelo projeto
(*"No verified rows yet"*). Latência não diz nada sobre naturalidade.

**O que falta:** ouvir `evidence/windows/20261023-150843/audio/C1..C10` e
preencher a grade de `test-matrix.md` §4.2.

**Risco a registrar:** licença CC-BY-NC + `commercial_outputs: unknown`.

### 4.2 Caminho Vulkan / `audio.cpp` / Breeze-TTS-2 no Windows + AMD

> ### 🔴 **NÃO RECOMENDADO**

**Por quê:** três motivos independentes, cada um suficiente.

1. **Não fala português.** `supported_languages == ["en","zh"]`, confirmado no
   código e no card do modelo.
2. **Licença Research/Non-Commercial cobrindo explicitamente os outputs
   self-hosted** — sem a zona cinzenta que o OmniVoice tem.
3. **É mais lento que a CPU nesta máquina** — medido, não estimado: RTF 7,740 no
   Vulkan contra 6,333 na CPU, mesmo binário e mesmo modelo (§ acima,
   `test-matrix.md` §5.3.1).

Some-se: o VoiceStudio fixa `audio.cpp` **v0.7.4** enquanto o upstream está em
**v0.9.2** — defasagem relevante para um runtime que evolui rápido.

**Conclusão da Fase D:** a pergunta "Vulkan serve para o nosso caso?" tem
resposta negativa por **três** motivos independentes, todos medidos ou
verificados: **(1)** idioma (só en/zh); **(2)** licença research/non-commercial
cobrindo outputs; **(3)** desempenho — a placa é **22% mais lenta** que o Ryzen
no mesmo modelo (`test-matrix.md` §5.3.1).

**O "não recomendado" precisa ser exato sobre o que foi medido.** Em
2026-10-23 o `/gpu` rodou e o resultado foi afirmativo onde todos esperavam
negativo — **a placa funciona**:

```
Vulkan:0 "AMD Radeon RX 580 2048SP" [GPU]
CPU:0    "AMD Ryzen 5 5500" [CPU]
available_devices=2
```

**A RX 580 funciona em Vulkan com o binário do app**, sem compilar nada, com o
runtime `audio.cpp` v0.7.4 instalado pelo próprio serviço do app e 4,89 GiB de
pesos instalados. O que ainda não existe é **medição pareada** Vulkan × CPU
(passo `[7d]`, escrito e não executado) e **modelo em português** nesse runtime.

Duas armadilhas registradas na ocasião:

- **O app não usa a placa sozinho.** `gpu_compat = ("cpu",)` no motor
  `audiocpp`: o roteamento o trata como CPU-only mesmo com Vulkan enumerado.
  Usar a GPU exige `OMNIVOICE_AUDIOCPP_BACKEND=vulkan`.
- **A placa não tem fp16.** O backend reporta `fp16: 0 | bf16: 0 | matrix cores:
  none | warp size: 64` — tudo roda em fp32, sem tensor cores.
- **"Funciona" não é "ajuda".** Medida contra o próprio processador, no mesmo
  modelo, a placa é **22% mais lenta** (§ acima). O app **usa** o Vulkan sozinho
  quando o runtime está instalado (`effective_device=vulkan`,
  `routing_status=accelerated`) — eu havia dito o contrário lendo só o atributo
  de classe `gpu_compat`, e essa conclusão foi corrigida em
  `test-matrix.md` §5.3.2.

**E a medição pareada existe — ela desmente a expectativa.** Execução
`20261023-195256`, mesmo binário, mesmo GGUF Q8_0, mesmo texto, mesmo seed, 1
aquecimento descartado e 3 medições por backend:

| backend | RTF mediano | faixa |
|---|---|---|
| **Vulkan** — RX 580 | **7,740** | 7,425 – 7,908 |
| **CPU** — Ryzen 5 5500, 8 threads | **6,333** | 6,286 – 6,383 |

**A RX 580 é 22% mais lenta que o processador.** As três medições da GPU ficam
inteiramente acima das três da CPU — não há sobreposição, não é ruído.

Eu havia estimado "Vulkan típico 3–5× de ganho nesta placa". **A estimativa
estava errada, e o erro era meu.** O ganho medido é **0,82×**: uma regressão.
O próprio binário declara o motivo ao subir:

```
audio.cpp is optimized for CUDA. The vulkan server backend is intended for
portability and testing, but performance and model coverage may be lower
than CUDA.
```

Somado ao que a enumeração já mostrava — `fp16: 0`, `bf16: 0`, `matrix cores:
none`, `warp size: 64` — e ao fato de os pesos serem Q8_0 (desquantização por
multiplicação, sem dot-product inteiro), o resultado deixa de ser surpresa: é o
esperado para uma GCN de 2017 rodando um backend declaradamente de
portabilidade.

**Ressalva registrada:** o mesmo texto e o mesmo seed produziram áudios de
durações diferentes — 8,16 s no Vulkan, 9,92 s na CPU. O seed **não reproduz
entre backends**. O RTF continua válido (é normalizado por segundo de áudio),
mas os dois WAVs não podem ser tratados como "o mesmo áudio" num teste de
qualidade.

**Consequência:** o caminho Vulkan/AMD não está fechado só por idioma. Ele está
fechado por idioma **e** por desempenho — e a segunda razão é um número, não um
argumento.

**Correção de fato (operador, 2026-10-23):** a RX 580 tem **8 GB de VRAM**, não
4. O valor de 4 GB era saturação do `AdapterRAM` do WMI. Isso derruba o
argumento de capacidade — com 8 GB, até o modelo em FP16 caberia. **Não derruba
os outros dois**: `gfx803` continua fora do ROCm, e PyTorch continua sem Vulkan.
Por isso existe o modo `/gpu`, que mede a placa pelo único caminho nativo que o
app oferece (audio.cpp/Vulkan).

**E a segunda porta também fechou, agora com fato.** Eu havia levantado a
hipótese de que o `omnivoice-gguf` (runtime `omnivoice.cpp`, GGML, que faz
*dlopen* de `ggml-vulkan`) abriria um caminho Vulkan **para português**. O teste
`/gguf` na máquina-alvo respondeu:

```
binary_found:     false
binary:           (nenhum)
ggml_libs:        []
engine_available: false
engine_reason:    A file this engine needs is missing or unreadable.
```

O build Windows da v0.5.6 **não distribui o binário `omnivoice-tts`, nem as
bibliotecas `ggml*`**. Não é questão de configuração: o código que ligaria o
Vulkan não está no pacote. Testar Vulkan exigiria compilar o `omnivoice.cpp`
(MSVC + Vulkan SDK) — outro projeto, não um ajuste.

Ou seja: **"sem caminho de GPU para português nesta máquina" está confirmado
duas vezes** — uma por análise (PyTorch não tem Vulkan; o motor GGML não está
no build) e uma por medição (`device=cpu`, `gpu_routing` em CPU).

**O que mudou com o `/gpu`, e o que não mudou.** Mudou o veredito sobre *a
placa*: ela é acessível por Vulkan com o runtime que o app instala, e isso está
medido (`Vulkan:0 ... [GPU]`). Não mudou o veredito sobre *o português*: o único
motor Vulkan do app fala inglês e chinês. A frase correta agora é **"há GPU
utilizável, e ela não fala a nossa língua"**, não "não há GPU".

### 4.3 VoxCPM2 / CosyVoice (Apache-2.0, com português)

> ### 🟡 **PRECISA DE MAIS EVIDÊNCIAS** — e é o plano B mais promissor

**Por quê:** resolvem o problema de licença do motor padrão mantendo português.
VoxCPM2 tem clone **e** design; CosyVoice tem clone. Ambos rodam em CPU no
hardware-alvo.

**O que falta:** qualidade em pt-BR é desconhecida. Nenhum dos dois tem número
publicado. Precisam do mesmo teste de escuta que o motor padrão.

### 4.4 VoiceStudio como plataforma / arquitetura de integração

> ### 🟢 **RECOMENDADO COMO OPÇÃO FUTURA**

**Por quê:** independentemente de qual motor vencer a Fase C, a **forma** de
integrar proposta em `integration-proposal.md` é sólida e satisfaz os três
critérios da missão:

- **Reversível** — adaptador removível, sem resíduo, Kokoro intacto.
- **Local** — `127.0.0.1:3900`, sem exposição de rede, sem API key.
- **Opcional** — Kokoro continua padrão; VoiceStudio é opt-in; falha cai para
  Kokoro automaticamente.

E é barata: o VoiceStudio já fala OpenAI, então o adaptador é um cliente HTTP
com mapeamento de erros.

### 4.5 Substituir o motor de voz da Lia

> ### 🔴 **NÃO RECOMENDADO** — e não foi pedido

A missão é explícita: não substituir automaticamente o motor existente. O
relatório concorda por mérito próprio: sem medição de qualidade em pt-BR,
substituir seria trocar um motor conhecido por um desconhecido, com licença pior.

---

## 5. Recomendação

**Não integrar agora. Fechar as duas lacunas que sobraram na máquina real.**

O caminho de menor risco, na ordem:

0. **`run-lab.bat /gpu`** — 1 comando, ~15 min + download de 5 GB *só se* o
   Vulkan enxergar a placa. Responde a última pergunta aberta da Fase D: *"a RX
   580 é utilizável por algum motor deste app, hoje, sem compilar nada?"* Se o
   RTF do Breeze em Vulkan não for muito menor que o de CPU, o caminho GPU está
   encerrado com número, não com argumento. **Não** promete português: o Breeze
   só fala inglês e chinês.
1. **Validar a qualidade em pt-BR com ouvido humano.** É o único dado que não
   pode ser obtido por inspeção nem por análise de sinal. Os 10 WAVs já existem
   (`reports/evidence/windows/20261023-150843/`); basta ouvir **C1, C3, C8 e C10**
   e preencher a grade de `test-matrix.md` §4.2. A hipótese a testar, levantada
   pela análise acústica (§2.4.2): **C1 e C8 soam como outra pessoa?**
2. **Se a qualidade for boa e o uso for pessoal/local:** implementar o adaptador
   descrito em `integration-proposal.md`, com Kokoro como padrão e VoiceStudio
   opt-in. Reversível em um passo.
3. **Se houver intenção comercial:** resolver a §2 antes de escrever código.
   Provavelmente significa VoxCPM2/CosyVoice em vez de OmniVoice — o que exige
   nova rodada de teste de qualidade.
4. **Descartar o caminho Vulkan/AMD** para português. Ele não atende por três
   razões medidas: não há modelo em português nesse runtime, a licença do que
   existe é research/non-commercial, e a placa é **22% mais lenta** que o
   processador no próprio modelo que ela roda. Não é falta de VRAM (8 GB,
   modelo de 4,73 GiB) nem de driver (Vulkan 1.3.250 enumera a placa).

**Desempenho — agora medido, não estimado:** no hardware-alvo a inferência é em
**CPU**, com **RTF 25,9** (26 s de processamento por segundo de fala). Para a
Lia, isso significa que **voz em tempo real está fora** e que o uso realista é
geração assíncrona. Chunking e streaming do VoiceStudio reduzem o tempo até o
*primeiro* trecho, não o custo total.

Se voz em tempo real for requisito, a conclusão do laboratório é que **este
caminho não atende neste hardware** — e nenhum ajuste de configuração muda um
fator de 26×.

---

## 6. Limitações deste relatório

Declaradas para que ninguém as descubra depois:

1. **A qualidade não foi julgada por um humano.** 10 frases foram geradas e
   analisadas por sinal (§2.4.2, `test-matrix.md` §4.4) — o que **não** cobre
   pronúncia, sotaque, naturalidade nem entonação. A grade subjetiva de §4.2
   está vazia.
2. **A GPU não foi exercitada.** O caminho GGUF foi testado e não existe neste
   build; o caminho `audio.cpp`/Vulkan está escrito no `/gpu` mas **não
   executado**. Nenhum número de Vulkan nesta máquina é medido.
3. **CPU/RAM durante a inferência não foram amostrados.** O script mede tempo,
   não consumo. O único dado de memória é o `memory_budget` de 1,2–1,9 GB
   reportado pelo app.
4. **Ambiente de análise não é o alvo.** A inspeção estática e a Fase E rodaram
   em Linux headless; o alvo é Windows + Radeon.
5. **`main` não é release estável.** A inspeção foi em `main` (5 commits após
   `v0.5.7-beta.1`). Para testes reais, fixar **v0.5.6**.
6. **Não houve comparação com ElevenLabs.** A missão proíbe afirmar equivalência
   sem comparação controlada; não houve comparação, logo não há afirmação.
7. **Licenciamento não é parecer jurídico.** As questões da §6 de
   `licensing.md` permanecem abertas por decisão, não por esquecimento.

---

## 7. Entregáveis

| Arquivo | Conteúdo |
|---|---|
| `executive-summary.md` | este documento |
| `environment.md` | sistema, hardware, versões, limitações, ausência do `J:` |
| `test-matrix.md` | 16 configurações, corpus, procedimentos, status por fase |
| `licensing.md` | app, pesos, tokenizadores, dependências, dúvidas jurídicas |
| `integration-proposal.md` | arquitetura futura, sem implementação |
| `installation-plan.md` | plano de instalação com custos, riscos e rollback |
| `corpus/` | corpus fixo pt-BR (10 frases) + SHA-256 de cada texto |
| `evidence/a1..a6` | inspeção estática (extrações reprodutíveis) |
| `evidence/runtime/` | Fase E executada contra backend real |
| `evidence/windows/` | onde `run-lab.bat` grava a coleta da máquina real |
| `../../run-lab.bat` | **arquivo único** na raiz: instala + coleta + relatórios + git |

---

## 8. Uma nota sobre o método

O laboratório não produziu nenhuma medição de voz porque não podia ouvir. O que
produziu foi o mapa exato do que precisa ser medido, com o corpus pronto, os
endpoints certos, os campos de métrica que o próprio app já devolve, e a lista de
armadilhas que fariam o teste dar resultado falso — primeira execução mais lenta
que as demais, queda silenciosa para CPU, `device=cpu` mascarado na UI, e um
orçamento de tempo que **não** é o "600 s" que a leitura estática sugere
(`executionBase` 600 + `progressExtensionCap` 1800 + `cpuAutoCeiling` 7200).

Isso é menos do que a missão pedia. É mais do que uma opinião.
