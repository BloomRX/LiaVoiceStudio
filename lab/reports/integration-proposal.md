# integration-proposal.md — Proposta futura para a Lia (sem implementação)

**Status:** análise arquitetural. **Nada foi implementado.** Nenhum arquivo,
dependência ou configuração da Lia ou do AIRI foi aberto, copiado ou alterado.
Este documento é insumo para uma tarefa futura, separada e revisável.

---

## 1. Princípio orientador

A missão pede uma solução **reversível, local e opcional**, que **não substitua
automaticamente** o motor de voz atual da Lia (Kokoro).

A arquitetura que satisfaz esses três requisitos ao mesmo tempo é:

> **VoiceStudio como provedor TTS opcional, em processo separado, falado por
> HTTP em loopback, atrás de uma interface de provedor que já exista na Lia —
> com fallback automático para Kokoro em qualquer falha.**

Isso é possível porque o VoiceStudio já expõe uma API **compatível com OpenAI**
(`POST /v1/audio/speech`), que é o formato mais fácil de embrulhar: qualquer
cliente existente que fale OpenAI passa a falar VoiceStudio trocando só a
`base_url`.

---

## 2. Antes de tudo: uma decisão de produto, não de engenharia

O laboratório não pode decidir isto, mas precisa registrá-lo em letras grandes,
porque muda a arquitetura inteira:

| Motor | pt-BR | Clonagem | Design | Licença dos pesos | GPU AMD no Windows |
|---|---|---|---|---|---|
| **OmniVoice** (padrão do VoiceStudio) | ✅ | ✅ | ✅ | **CC-BY-NC** | ❌ CPU |
| **VoxCPM2 / CosyVoice** | ✅ | ✅ / ❌ | ✅ / ❌ | Apache-2.0 | ❌ CPU |
| **Breeze-TTS-2** (Vulkan/AMD) | ❌ | ✅ | ✅ | Research/NC | ✅ |

Se a Lia for **pessoal e local**, o motor padrão serve e a proposta abaixo se
aplica direto.

Se a Lia for **distribuída ou comercial**, o motor padrão está fora por licença,
e o provedor precisa ser configurável para um motor Apache-2.0. Ver
`licensing.md` §6.

**Recomendação:** a integração deve ser **agnóstica de motor** desde o início —
receber o `engine` como configuração, não hardcodar `omnivoice`.

---

## 3. Como detectar uma instalação existente

Três sinais, do mais barato ao mais caro. Nenhum exige privilégio.

```
1. Porta     TCP connect em 127.0.0.1:3900  (timeout curto, ~300 ms)
2. Saúde     GET /health  -> 200 {"status":"ok","device":...,"version":...}
3. Identidade GET /engines/tts -> confirma que é VoiceStudio e lista motores
```

Um `GET /health` respondendo 200 com `{"status":"ok"}` já identifica o serviço.
O campo `version` permite rejeitar versões fora da faixa suportada — importante
porque a API evolui rápido (v0.5.x → v0.5.7 em semanas).

**Não** procurar por caminho de instalação. O app é instalado por usuário, em
local escolhido na instalação, e pode estar em qualquer drive. Porta + `/health`
é o teste robusto.

**Detecção negativa é o caso comum.** Na maioria das máquinas o VoiceStudio não
está instalado. Isso deve ser um caminho normal e silencioso, não um erro.

---

## 4. Verificação de saúde — em dois níveis

A distinção importa porque o boot é lento (carregamento de modelo ~8 s, mais
download na primeira vez).

| Nível | Verificação | Custo | Quando usar |
|---|---|---|---|
| **Liveness** | `GET /health` | ~ms | antes de cada lote |
| **Readiness de motor** | `GET /engines/{id}/health` | ~ms–s | antes do primeiro uso de um motor |
| **Profundidade** | `POST /engines/{id}/selftest` | segundos | diagnóstico sob demanda, nunca no caminho quente |

Estados a tratar explicitamente:

- `200 {"status":"ok"}` → pronto.
- **`503 {"status":"starting","step":N,"label":"..."}`** → subindo. Não é erro.
  Respeitar `Retry-After: 2`. O `label` pode ser mostrado ao usuário
  ("carregando modelo…").
- Conexão recusada → app fechado. Não tentar de novo em laço.
- Timeout → tratar como indisponível.

### 4.1 Um detalhe valioso: detectar queda silenciosa para CPU

O VoiceStudio devolve o header **`X-OmniVoice-Routing`** em cada geração, e
`/health` devolve `device`. Isso permite detectar o cenário em que o usuário
acha que tem GPU mas está rodando em CPU — que é **o cenário padrão numa Radeon
no Windows**.

Se `device == "cpu"` e a latência estiver ruim, a Lia pode avisar o usuário com
uma explicação real em vez de "está lento".

---

## 5. Enviar texto e receber áudio sem bloquear a interface

Este é o requisito mais importante e o que mais muda a arquitetura.

### 5.1 O problema

`POST /generate` é **síncrono**: a resposta só chega depois de todo o áudio
pronto. Um parágrafo longo em CPU pode levar **dezenas de segundos**. No contexto
de uma conversa com a Lia, isso é inaceitável como bloqueio de UI.

### 5.2 Duas rotas, com papéis diferentes

| Rota | Forma | Latência até primeiro áudio | Usar para |
|---|---|---|---|
| `WS /ws/tts` | WebSocket, streaming | **baixa** — mede e reporta `ttfa_ms` | conversa em tempo real |
| `POST /v1/audio/speech` | JSON → arquivo completo | alta | pré-geração, narração, cache |
| `POST /generate` | multipart → arquivo + metadados | alta | quando precisa de controle fino (seed, wav_bits, chunking) |

Para conversação, **`/ws/tts` é a rota correta**. O frame final `done` traz três
métricas prontas — `ttfa_ms`, `gen_time_s`, `rtf` — que permitem decidir, em
tempo de execução, se aquele hardware/idioma é adequado ou se deve cair para
Kokoro.

Para narração longa (audiobook, resposta extensa), `POST /generate` com
`stream=false` e `max_chunk_chars` é mais simples e o bloqueio importa menos.

### 5.3 Regra de não-bloqueio

```
fila de fala  ──> worker dedicado  ──> HTTP/WS VoiceStudio
     ^                                        │
     └──────── eventos de progresso ──────────┘
```

A UI **nunca** espera a síntese. Ela enfileira um pedido, recebe eventos
(`queued` → `synthesizing` → `first_audio` → `done` / `failed`) e continua
responsiva. Se a síntese falhar, a fila segue para o Kokoro.

O VoiceStudio também aceita `stream=true` em `/generate`, que devolve
`application/x-ndjson` com um evento `start`, N eventos `chunk` (PCM16 base64
por trecho de texto) e um `done`. É uma alternativa viável ao WebSocket quando
já existe um cliente HTTP.

---

## 6. Timeout, falhas e reinicialização

### 6.1 Orçamentos de tempo

O próprio backend gerencia orçamentos e os expõe em **`GET /generate/budget`**:
300 s em hardware acelerado, **600 s em CPU**. Isso é importante — um timeout
fixo de 30 s no cliente cortaria gerações que o servidor considera normais.

Configurar o cliente **acima** do orçamento do servidor, e o orçamento por
classe de hardware:

| Classe | Timeout cliente sugerido | Justificativa |
|---|---|---|
| CPU | ~660 s | orçamento do servidor 600 s + folga |
| GPU | ~360 s | orçamento do servidor 300 s + folga |
| Primeira geração após boot | +120 s | carga de modelo + possível download |

Sempre ler `/generate/budget` em vez de chutar.

### 6.2 Matriz de falhas

| Sintoma | Causa provável | Ação |
|---|---|---|
| `ECONNREFUSED` | app fechado | marcar provedor indisponível, usar Kokoro, não repetir em laço |
| `503` + `Retry-After` | boot em andamento | aguardar e repetir uma vez |
| `429` | GPU saturada / throttle | respeitar `Retry-After`; enfileirar, não paralelizar |
| `400` | motor desconhecido / parâmetro inválido | não repetir; é erro de programação |
| `403` | licença de modelo não aceita | orientar o usuário a aceitar no app; **não** tentar contornar |
| `422` | referência incompatível com o motor | corrigir a requisição |
| Timeout | texto longo em CPU | reduzir `max_chunk_chars`, cair para Kokoro |
| Stream cortado | app encerrado no meio | tratar como falha e reenviar o trecho |

### 6.3 Reinicialização

**Fato arquitetural:** o backend é filho do Electron. Se o usuário fecha o app,
a API morre. A Lia **não pode** reiniciar o app sozinha — isso seria assumir
controle de um aplicativo de terceiro, com efeitos colaterais na sessão do
usuário.

O comportamento correto é:

1. Marcar o provedor como `unavailable`.
2. Cair para Kokoro **imediatamente**, sem degradar a experiência.
3. Reavaliar de tempos em tempos (ex.: a cada abertura de conversa, não em
   polling agressivo).
4. Se voltar, reabilitar sozinho.

O modelo mental é **"provedor oportunista"**, não **"dependência"**.

### 6.4 Circuit breaker

Após N falhas consecutivas (sugestão: 3), abrir o circuito por um período
(sugestão: 5 min), evitando que cada fala pague um timeout completo antes de
cair para o Kokoro. Sem isso, a degradação é pior que a indisponibilidade.

---

## 7. Manter o serviço restrito a localhost

Já é o padrão do produto, e a integração **não deve alterar isso**.

| Aspecto | Situação | Ação da Lia |
|---|---|---|
| Bind | Loopback por padrão | **não** alterar |
| Auth em loopback | Nenhuma | **não** definir `OMNIVOICE_API_KEY` |
| PIN / compartilhamento LAN | Desligado | **não** ligar |
| Tailscale | Desligado | **não** ligar |
| `OMNIVOICE_ALLOWED_HOSTS` | só loopback | **não** usar `*` |

**Regra dura:** a Lia chama exclusivamente `http://127.0.0.1:3900`. Nunca
`0.0.0.0`, nunca o IP da máquina, nunca `host.docker.internal`. Se o
VoiceStudio precisar estar em outro host, isso **não é** esta integração — é
outro cenário, com API key e TLS, e exige decisão separada.

Corolário: não habilitar CORS amplo. Um cliente Python/Node local não envia
`Origin` e não é afetado pela allow-list — **não há motivo** para mexer em
`OMNIVOICE_ALLOWED_ORIGINS`.

---

## 8. Devolver o áudio ao sistema de reprodução

O VoiceStudio devolve **bytes de áudio**, não um stream de dispositivo. A Lia
continua dona da reprodução.

```
VoiceStudio ──(wav/pcm/mp3)──> Provedor da Lia ──> buffer ──> pipeline de fala atual
```

Pontos práticos:

- **Formato:** preferir `wav` (16-bit) ou `pcm`. `pcm` evita decodificação e
  reduz latência; `mp3`/`opus`/`aac`/`flac` dependem de **ffmpeg** instalado e
  falham sem ele.
- **Sample rate:** o OmniVoice emite **24 kHz mono**. O Kokoro pode emitir outra
  taxa. **A Lia precisa reamostrar** se o pipeline de reprodução assumir uma
  taxa fixa. Isto é uma fonte real de bug (voz fina/grave, velocidade errada).
- **Masterização:** o VoiceStudio aplica uma cadeia própria (highpass +
  compressor, `effect_preset` padrão `broadcast`). O volume e o timbre vão
  diferir do Kokoro. Para alternar entre os dois sem solavanco, comparar
  loudness e normalizar no lado da Lia — ou usar `effect_preset` consistente.
- **Streaming:** no `/ws/tts`, os chunks já são PCM16 tocáveis. O buffer de
  reprodução deve aceitar escrita incremental, senão o ganho de latência se
  perde.

---

## 9. Opções compatíveis com o hardware

O provedor deve **descobrir**, não **assumir**. O VoiceStudio já entrega os
dados necessários:

```
GET /engines/tts        -> motor disponível? qual? qual device?
GET /api/settings/gpu-report -> por motor: usa GPU? se não, por quê?
GET /system/diagnose    -> veredito de hardware
```

Lógica sugerida, em ordem:

1. `GET /engines/tts` → filtrar por `available == true` **e** idioma compatível
   com pt-BR.
2. Se houver mais de um, preferir o que tem `device != "cpu"`.
3. **Se só houver motor em CPU:** oferecer mesmo assim, mas com expectativa
   calibrada — e considerar que, para fala curta, a diferença pode ser
   aceitável; para texto longo, não.
4. Expor a escolha ao usuário. Não decidir silenciosamente.

**No hardware-alvo desta missão (Windows + Radeon), o passo 2 vai sempre
falhar:** todo motor que fala português está em CPU. A Lia deve saber disso e
não prometer aceleração que não existe.

---

## 10. Manter Kokoro (e outras vozes) funcionando se o VoiceStudio falhar

Requisito não-negociável da missão. Três camadas de proteção:

### 10.1 Isolamento por interface

O VoiceStudio entra como **mais uma implementação** da interface de provedor TTS
que a Lia já usa. Não substitui, não envolve, não intercepta o Kokoro.

```
        ┌──────────────────────────────┐
        │   Interface TTSProvider      │  (já existe na Lia)
        └───────────┬──────────────────┘
        ┌───────────┴───────────┐
   ┌────▼─────┐          ┌──────▼────────┐
   │  Kokoro  │          │  VoiceStudio  │
   │ (padrão) │          │  (opcional)   │
   └──────────┘          └───────────────┘
```

### 10.2 Fallback explícito e rápido

- Kokoro é **sempre** o padrão. VoiceStudio é opt-in por configuração.
- Qualquer falha → Kokoro, **sem perguntar ao usuário** e sem travar a fala.
- O usuário pode perceber a troca (voz muda), então vale registrar em log e,
  opcionalmente, indicar discretamente na UI.

### 10.3 Falha na inicialização, não na fala

Se o VoiceStudio não responde na descoberta, o provedor nem entra na lista. O
usuário nunca chega a escolher uma voz que vai falhar.

**Anti-padrão a evitar:** fazer do VoiceStudio o provedor padrão por ser "melhor
qualidade", e cair para Kokoro só no erro. Isso combina o pior dos dois: latência
de falha + experiência inconsistente.

---

## 11. Instalar, atualizar e remover o provedor

### 11.1 Instalação

A instalação do **VoiceStudio** é responsabilidade do usuário, não da Lia.
Motivos: é um app Electron com instalador próprio, ~10 GB, licença AGPL, e
requer aceite de licenças de modelo dentro do app. A Lia **não deve** baixar e
instalar silenciosamente.

O que a Lia instala é só o **adaptador** (código próprio, pequeno, sem
dependências pesadas): cliente HTTP + WebSocket, mapeamento de erros, testes.

Fluxo recomendado:

```
1. Lia detecta VoiceStudio (porta + /health)
2. Não encontrado  -> oferecer link para a página oficial de download
3. Encontrado      -> testar /engines/tts; rodar um /generate curto
4. Sucesso         -> habilitar como opção
5. Falha           -> explicar o motivo real (device=cpu? licença? motor?)
```

### 11.2 Atualização

Não automatizar. A API mudou de forma relevante entre versões menores
(v0.5.x → v0.5.7), e o pin de versão do `audio.cpp` mudou de v0.7.4 para além.
Registrar a faixa de versões **testada** e avisar — não bloquear — quando a
versão instalada estiver fora dela. Ler `/health` → `version`.

### 11.3 Remoção

Deve ser **completa e sem resíduo**:

- Remover o adaptador e a configuração do provedor.
- Reverter o padrão para Kokoro.
- **Não** desinstalar o VoiceStudio (não é nosso), apenas parar de usá-lo.
- **Não** apagar dados do usuário em `OMNIVOICE_DATA_DIR`.

Teste de aceite da remoção: com o adaptador removido, a Lia funciona
exatamente como antes, e nenhuma chamada de rede para `:3900` acontece.

---

## 12. Licenças a verificar antes de distribuir

Resumo operacional (detalhe em `licensing.md`):

| Item | Verificar antes de distribuir |
|---|---|
| Código do VoiceStudio | AGPL-3.0. Se a Lia **redistribuir** ou **modificar**, há obrigações de fonte |
| Adaptador da Lia | Código próprio — licença da Lia, sem contaminação |
| Pesos OmniVoice | **CC-BY-NC** — bloqueia uso comercial |
| Outputs do OmniVoice | `commercial_outputs: unknown` — **não assumir** que podem ser monetizados |
| Breeze-TTS-2 | Research/NC, incluindo outputs self-hosted |
| Alternativas Apache-2.0 | VoxCPM2, CosyVoice — verificar `commercial_outputs` individualmente |

**Regra prática:** enquanto a Lia for pessoal e local, nada bloqueia. No momento
em que houver distribuição ou cobrança, a escolha do motor precisa ser reavaliada
antes do código.

---

## 13. O que esta proposta deliberadamente não faz

- Não define nomes de arquivos, classes ou assinaturas — isso pertence ao
  repositório da Lia.
- Não escolhe o motor padrão — depende da decisão de produto da §2.
- Não propõe embutir o VoiceStudio, nem empacotá-lo.
- Não altera, lê ou copia código da Lia ou do AIRI.
- Não afirma que a qualidade em pt-BR é boa. **Isso ainda não foi medido.**

---

## 14. Pré-requisitos antes de implementar

Esta proposta só deve virar código depois que:

1. A Fase C for executada na máquina real e a qualidade em pt-BR for julgada
   aceitável por um humano ouvindo o corpus de `corpus/`.
2. A Fase D medir CPU vs. Vulkan com pelo menos 3 gerações pareadas.
3. A §2 (motor × licença) estiver decidida.
4. A §6 do `licensing.md` tiver parecer, se houver intenção comercial.

Até lá, a classificação honesta é **"precisa de mais evidências"**.
