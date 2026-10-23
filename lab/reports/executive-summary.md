# executive-summary.md — Conclusão e recomendação

**Missão:** avaliar o VoiceStudio como solução local de geração de voz para a Lia,
antes de qualquer integração.
**Data:** 2026-10-23 · **Versão avaliada:** `main` @ `48e85106` (estável de
referência: **v0.5.6**)

---

## 1. O que foi possível fazer — e o que não foi

Preciso começar pelo limite, porque ele condiciona tudo o que vem depois.

**A missão pressupunha uma máquina Windows com GPU AMD e disco `J:`. Esse
ambiente não existe neste laboratório.** O agente roda em um contêiner Linux
headless, sem `J:`, sem GPU, sem saída de áudio, com 3.8 GiB de RAM e 2 vCPU.

Consequência direta:

| Fase | Status real |
|---|---|
| A — investigação estática | ✅ **Executada** — leitura de README, 100+ documentos e do código da versão fixada |
| B — instalação | ✅ **Testada na máquina real** — o `run-lab.bat` instalou (SHA-256 conferido, `/S`), baixou o modelo e gerou WAV. Falta o ciclo fechar/reabrir |
| C — qualidade de voz | ❌ **Não testada** — sem áudio, sem GPU, e avaliar naturalidade exige ouvinte humano |
| D — AMD / Vulkan | 🟡 **`CPU-only` confirmado + 1ª medição (RTF 39,9, fria)** — regime permanente pendente |
| E — API local | ✅ **TESTADA em runtime** — backend real exercitado por HTTP (ver §2.6) |
| F — licenças | ✅ **Executada** com fontes primárias, confirmada em runtime |
| G — integração | ✅ **Análise arquitetural**, sem implementação |

**Nenhuma medição de latência, RTF, uso de CPU/GPU ou nota de naturalidade é
apresentada neste relatório.** Isso não é omissão: é a regra da missão, e
inventar esses números seria pior do que não tê-los.

Uma ressalva sobre a Fase E: o backend **subiu e respondeu** (Linux, CPU), mas
**nenhum áudio foi gerado**, porque os pesos vêm do Hugging Face e esse domínio
não é alcançável deste sandbox. "API validada" aqui significa contrato, códigos
de erro e isolamento — não qualidade de áudio.

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
- **~4 GB de VRAM** ficam abaixo do piso de 6 GB do OmniVoice.

**Vulkan funciona** nesta placa (loader 1.3.250 respondeu). Mas o único motor
Vulkan só fala inglês e chinês.

O app **confirmou isso na própria tela de verificação**, depois de instalado:

```
GPU acceleration    ⚠ No compatible GPU detected — running CPU-only.
Active engine routing  ✅ omnivoice — cpu (no accelerator on this host)
```

Não é inferência da análise estática: é o `gpu_routing_verdict()` do app sobre
esta máquina. Captura e transcrição em
[`evidence/install/README.md`](evidence/install/README.md).

Portanto, para *esta* máquina, a pergunta "Vulkan é mais rápido?" é irrelevante
para português: o único caminho que fala pt-BR é o **Ryzen em CPU**. Detalhe em
`environment.md` §4.

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

**Não trate esse número como o RTF do sistema.** É a primeira geração do
processo e inclui carregar 2,4 GB de pesos na RAM. O protocolo do laboratório
sempre separa a primeira execução exatamente por isso. O regime permanente sai
das execuções 2+ de `/voice` — e é esse número que decide se o VoiceStudio serve
para conversa ou apenas para geração assíncrona.

O que já se pode afirmar com segurança: **não há GPU no caminho**
(`omnivoice — cpu (no accelerator on this host)`, dito pelo próprio app), então o
teto de desempenho é o Ryzen 5 5500, sem margem para "ligar a placa depois".

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

> ### 🟡 **PRECISA DE MAIS EVIDÊNCIAS**

**Por quê não "recomendado":** é a única configuração com português + clonagem +
design, e a API é excelente. Mas **não há uma única medição de qualidade ou
latência em pt-BR** — nem neste laboratório, nem no projeto (a tabela de
benchmarks oficial está literalmente vazia: *"No verified rows yet"*).

**O que falta:** executar a Fase C na máquina real, com o corpus fixo, e um
humano ouvir. Sem isso, recomendar seria adivinhação.

**Risco a registrar:** licença CC-BY-NC + `commercial_outputs: unknown`.

### 4.2 Caminho Vulkan / `audio.cpp` / Breeze-TTS-2 no Windows + AMD

> ### 🔴 **NÃO RECOMENDADO**

**Por quê:** dois motivos independentes, cada um suficiente.

1. **Não fala português.** `supported_languages == ["en","zh"]`, confirmado no
   código e no card do modelo.
2. **Licença Research/Non-Commercial cobrindo explicitamente os outputs
   self-hosted** — sem a zona cinzenta que o OmniVoice tem.

Some-se: o VoiceStudio fixa `audio.cpp` **v0.7.4** enquanto o upstream está em
**v0.9.2** — defasagem relevante para um runtime que evolui rápido.

**Conclusão da Fase D:** a pergunta "Vulkan é mais rápido?" **não chega a ser
respondida** porque a pergunta anterior — "Vulkan serve para o nosso caso?" —
tem resposta negativa. Medir seria desperdício de tempo.

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

**Não integrar agora. Executar as Fases B–D na máquina real primeiro.**

O caminho de menor risco, na ordem:

1. **Validar a qualidade em pt-BR antes de qualquer código.** É o único dado que
   falta e o único que não pode ser obtido por inspeção. Para isso existe
   **`run-lab.bat`** na raiz: ele instala o app, baixa o modelo, coleta hardware,
   API e áudio do corpus, escreve o resumo e envia ao git. Depois ouça as amostras e preencha a grade de
   `test-matrix.md` §4.2.
2. **Se a qualidade for boa e o uso for pessoal/local:** implementar o adaptador
   descrito em `integration-proposal.md`, com Kokoro como padrão e VoiceStudio
   opt-in. Reversível em um passo.
3. **Se houver intenção comercial:** resolver a §2 antes de escrever código.
   Provavelmente significa VoxCPM2/CosyVoice em vez de OmniVoice — o que exige
   nova rodada de teste de qualidade.
4. **Descartar o caminho Vulkan/AMD** para português. Ele não atende.

**Expectativa calibrada sobre desempenho:** no hardware-alvo, a inferência será
em **CPU**. Isso é mais lento que GPU, e a missão deve ser planejada sabendo
disso. O VoiceStudio mitiga parcialmente com chunking, streaming e orçamentos de
tempo — mas não elimina o custo.

---

## 6. Limitações deste relatório

Declaradas para que ninguém as descubra depois:

1. **Nenhuma geração de áudio foi produzida.** Todo julgamento de qualidade está
   ausente por impossibilidade, não por escolha.
2. **Nenhuma medição de desempenho.** Nem latência, nem RTF, nem CPU/RAM/GPU.
3. **O hardware AMD foi identificado, mas não exercitado.** A coleta do
   `run-lab.bat` descreveu a máquina (RX 580 / Ryzen 5 5500); nenhuma inferência
   rodou nela, porque o VoiceStudio **não está instalado**.
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
