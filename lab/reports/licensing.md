# licensing.md — Licenças e restrições

**Data:** 2026-10-23 · **Versão:** `main` @ `48e85106` · **Base:** inspeção de
`LICENSE`, `LICENSE-NOTICE.md`, `backend/config/model_licenses.json`,
`docs/licensing/`, e dos cards oficiais dos modelos.

> **Aviso:** este documento é uma **análise técnica de engenharia**, não parecer
> jurídico. Onde há ambiguidade, ele diz "requer revisão jurídica" em vez de
> concluir. Nenhuma garantia legal é emitida.

---

## 1. Resumo executivo

| Camada | Licença | Uso local pessoal | Uso comercial | Redistribuição |
|---|---|---|---|---|
| **Aplicativo VoiceStudio** | **AGPL-3.0-only** | Livre | Permitido, **com copyleft** | Permitido, sob AGPL |
| Pacote `omnivoice/` (código do modelo) | Apache-2.0 | Livre | Sim | Sim |
| **Pesos `k2-fsa/OmniVoice`** (motor **padrão**) | **CC-BY-NC** | Sim | **NÃO** | **NÃO** |
| Tokenizador de áudio do OmniVoice | Boson Higgs Audio 2 + Meta Llama (termos próprios) | Verificar | **Requer revisão** | **Requer revisão** |
| Runtime `audio.cpp` (código) | Apache-2.0 | Livre | Sim | Sim |
| **Pesos Breeze-TTS-2** | **Research & Non-Commercial** | Sim | **NÃO** | **NÃO** |
| Maioria dos demais modelos | Apache-2.0 / MIT / CC-BY-4.0 | Sim | Provavelmente sim | Provavelmente sim |

**O ponto que decide tudo:** o motor padrão do VoiceStudio entrega **clone e
design de voz em português** — e é exatamente o único com pesos
**não comerciais**. A aceleração AMD (Breeze-TTS-2 via Vulkan) também é
não comercial **e** não fala português.

---

## 2. Licença do aplicativo

**AGPL-3.0-only.** Confirmado em `package.json` (`"license": "AGPL-3.0-only"`),
`LICENSE` (texto canônico) e `LICENSE-NOTICE.md`.

O que a AGPL permite e exige, segundo o próprio projeto:

- **Permite** uso comercial e interno do aplicativo ("That **includes
  commercial and internal business use** of the application itself").
- **Exige** que, se você **modificar** o VoiceStudio e oferecer essa versão
  modificada **por rede**, você ofereça o código-fonte correspondente sob
  AGPL-3.0 aos usuários da rede (cláusula Affero).

### O que isso significa para a Lia — e o que não significa

Este é o ponto onde é fácil errar para os dois lados.

**Não é verdade** que "usar a API local do VoiceStudio a partir da Lia obrigue a
Lia a ser AGPL". Chamar um processo separado via HTTP é, em regra, uso de
software, não incorporação. O próprio projeto vende exatamente isso: uma
*commercial license* para quem quer "embed VoiceStudio in a closed-source or
proprietary product ... without the AGPL-3.0 copyleft obligations"
(`LICENSE-NOTICE.md`).

**Também não é verdade** que seja irrelevante. Os cenários que **exigem revisão
jurídica** antes de qualquer decisão são:

1. **Distribuir o VoiceStudio junto com a Lia.** Se o instalador da Lia baixar e
   instalar o VoiceStudio, isso é redistribuição de binário AGPL. A AGPL permite,
   mas impõe fornecer o código-fonte correspondente e os avisos.
2. **Modificar o VoiceStudio** (por exemplo, para expor um endpoint específico
   da Lia) e entregá-lo a terceiros. Nesse caso o copyleft morde de verdade.
3. **Oferecer o VoiceStudio como serviço de rede** para usuários finais. A
   cláusula Affero foi escrita para este caso; se a Lia for um produto hospedado
   que embrulha o VoiceStudio, o risco é concreto.
4. **Rebranding** — a licença permite, mas marcas e o `LICENSE-NOTICE.md` devem
   ser preservados.

**Cenário de menor risco** (e o que este relatório recomenda): VoiceStudio
instalado **pelo próprio usuário**, como aplicativo separado, e a Lia apenas
conversando com `http://127.0.0.1:3900` como *cliente*. Sem redistribuição, sem
modificação, sem hospedagem. Nesse formato a obrigação AGPL praticamente não
muda nada para a Lia.

---

## 3. Licenças dos modelos — a parte que realmente limita

Fonte primária: `backend/config/model_licenses.json` (schema 2, `checked_at`
2026-10-03, `registry_version` 2026-10-09.draft1). Evidência: `evidence/a5-licensing.txt`.

### 3.1 OmniVoice — o motor padrão

| Componente | Licença | Efeito prático |
|---|---|---|
| Código (`omnivoice/`) | Apache-2.0 | Livre |
| **Pesos pré-treinados** | **CC-BY-NC** | **Sem uso comercial** |
| Tokenizador de áudio | Boson Higgs Audio 2 + Meta Llama | Termos próprios, sobrepostos |

O card oficial do modelo é explícito:

> "Our code is released under the Apache 2.0 License. The pre-trained model is
> licensed under the **CC-BY-NC** due to constraints from its training data
> (e.g., Emilia)."

O próprio `model_licenses.json` registra, para `k2-fsa/OmniVoice`:
`review_status: noncommercial`, `commercial_inference: restricted`,
`commercial_outputs: unknown`.

**Confirmado em runtime (não apenas em documento):** ao tentar gerar áudio, a
API recusa e exige **duas** aceitações separadas:

```json
HTTP 403  {"code":"model_licence_required","models":[
  {"repo_id":"k2-fsa/OmniVoice","license":"CC-BY-NC (version unspecified); Higgs Audio 2; Meta Llama 3",
   "category":"noncommercial","fingerprint":"v2:d938ea92…"},
  {"repo_id":"eustlb/higgs-audio-v2-tokenizer","license":"NOASSERTION",
   "category":"unknown","fingerprint":"v2:6b442e43…"}]}
```

Ou seja: o tokenizador **não** é uma nota de rodapé jurídica — é um segundo
portão técnico que bloqueia a geração até ser aceito. E ele está classificado
como `unknown`, não como permissivo.

**`commercial_outputs: unknown` é o dado mais desconfortável.** A CC-BY-NC
restringe o uso do *modelo*; se o áudio gerado herda a restrição é uma questão
jurídica em aberto, e o próprio projeto não a resolve ("unknown"). Para a Lia,
isso significa: **não dá para assumir que áudio gerado pelo motor padrão pode
ser usado comercialmente.**

### 3.2 Breeze-TTS-2 (audio.cpp) — o caminho Vulkan/AMD

> "Model weights, checkpoints, adapters, derivative models, and **self-hosted
> outputs** are governed separately by the BreezeBlue Research and
> Non-Commercial License. (...) A paid subscription does not grant commercial
> rights to the open-weight model or **self-hosted outputs**."
> — card oficial `BreezeBlue/Breeze-TTS-2`

Aqui a restrição é ainda mais explícita que no OmniVoice: os **outputs
self-hosted** estão declaradamente cobertos pela licença não comercial. Não há
zona cinzenta.

Somando ao fato de que o modelo só fala inglês e chinês, o caminho `audio.cpp`
está descartado para a Lia por **dois** motivos independentes.

### 3.3 Modelos com licença permissiva que suportam português

Estes são os candidatos com licença mais limpa. Todos constam do catálogo:

| Modelo | Licença | pt-BR | Observação |
|---|---|---|---|
| `openbmb/VoxCPM2` | Apache-2.0 | sim (30 idiomas) | clone + voice design; CUDA/CPU |
| `FunAudioLLM/Fun-CosyVoice3-0.5B-2512` | Apache-2.0 | sim | clone; CUDA/CPU |
| `netease-youdao/Confucius4-TTS` | Apache-2.0 | provável (14 idiomas) | clone zero-shot |
| `mlx-community/Kokoro-82M-bf16` | Apache-2.0 | sim | **só Apple Silicon** (MLX) |
| `KittenML/kitten-tts-mini-0.8` | Apache-2.0 | **não** (inglês) | CPU, 8 vozes |
| `Supertone/supertonic-3` | **OpenRAIL-M** | sim (31 idiomas) | CPU-only, 7 vozes preset; OpenRAIL tem restrições de uso |
| `kyutai/pocket-tts` | CC-BY-4.0 (pesos) | a verificar | CPU; HF-gated |

**Nuance importante e frequentemente mal interpretada:** em
`model_licenses.json`, **todos** os 58 modelos aparecem com
`commercial_use: false` — inclusive os Apache-2.0. Isso **não** significa que
todos proíbem uso comercial. O `LICENSE-NOTICE.md` explica:

> "A false commercial-use flag includes unresolved review; it is not a claim
> that every listed model forbids commercial use."

O inventário é **conservador por padrão**: `false` inclui "ainda não revisado".
Dos 58 registros, **54 estão `unreviewed`** e apenas 4 têm status
`noncommercial`. Ou seja: o projeto honestamente declara que **não sabe** a
situação comercial da maioria dos modelos.

### 3.4 O que isso significa na prática

Para uso **pessoal e local** da Lia (o cenário da missão): nenhuma das licenças
acima bloqueia nada. CC-BY-NC e Research/Non-Commercial permitem uso pessoal.

Para **distribuir ou monetizar** a Lia com voz clonada em português: o motor
padrão está bloqueado, e os substitutos Apache-2.0 precisam de verificação
individual de (a) qualidade em pt-BR e (b) `commercial_outputs`.

---

## 4. Tokenizadores e dependências relevantes

- **Tokenizador de áudio do OmniVoice:** `audio_tokenizer/LICENSE` contém termos
  separados de **Boson Higgs Audio 2** e **Meta Llama**. O app exibe os textos de
  atribuição obrigatórios no painel *About*. Isto é uma camada de licença
  **além** da CC-BY-NC e é frequentemente esquecida.
- **PyAV 15.1.0:** os wheels empacotam FFmpeg e x264/x265. A licença do código
  PyAV não descreve os binários embutidos. Existe auditoria interna
  (`docs/licensing/pyav-15.1.0-audit.md`) que registra hashes e
  "unresolved redistribution requirements". Relevante **só se a Lia redistribuir
  o VoiceStudio**.
- **Restante das dependências:** resolvido em `bun.lock`, `uv.lock`,
  `native/desktop-bridge/Cargo.lock`. Não auditado nesta missão (fora do escopo).

---

## 5. Consentimento de voz — o VoiceStudio já tem a maquinaria

Relevante para "clonagem autorizada" da missão. O backend expõe, por perfil de
voz:

```
POST   /profiles/{profile_id}/consent
DELETE /profiles/{profile_id}/consent
POST   /profiles/{profile_id}/attestation
DELETE /profiles/{profile_id}/attestation
POST   /profiles/{profile_id}/lock
```

Isto é um diferencial real frente a serviços que não registram consentimento.
Ainda assim: **o registro técnico de consentimento não substitui base legal.**
Para clonar a voz de uma pessoa, é necessário consentimento documentado dela,
independentemente do que o app armazena.

---

## 6. Dúvidas que exigem revisão jurídica

Listadas explicitamente, sem tentativa de resolvê-las:

1. **Outputs do motor padrão (CC-BY-NC) podem ser usados comercialmente?**
   `commercial_outputs: unknown`. Não assumir que sim.
2. **Chamar a API local do VoiceStudio a partir de um produto proprietário
   configura "conveying" sob AGPL-3.0?** A posição do projeto (vender licença
   comercial para *embed*) sugere que sim em alguns formatos. Precisa de
   análise caso a caso.
3. **Se a Lia for oferecida como serviço de rede** que usa o VoiceStudio
   instalado no servidor, a cláusula Affero se aplica à Lia ou apenas ao
   VoiceStudio? Ambíguo.
4. **Redistribuir o instalador do VoiceStudio com a Lia** — quais obrigações de
   fonte e aviso se aplicam na prática.
5. **Termos do tokenizador Boson Higgs Audio 2 / Meta Llama** combinados com
   CC-BY-NC: qual prevalece em cada uso.
6. **OpenRAIL-M** (Supertonic-3) tem restrições de uso por finalidade, não só
   comerciais. Verificar antes de considerar esse motor.

**Nenhuma dessas perguntas é respondida por este relatório.** Elas são o escopo
de uma consulta jurídica, não de um laboratório técnico.

---

## 7. Recomendação de licenciamento

Para o cenário imediato — **laboratório pessoal, local, sem distribuição** —
nada bloqueia. Use o motor padrão e teste à vontade.

Antes de **qualquer** distribuição da Lia com voz do VoiceStudio:

1. Fixar a decisão sobre o motor: CC-BY-NC (padrão, melhor pt-BR) **ou**
   Apache-2.0 (VoxCPM2/CosyVoice, qualidade pt-BR a validar).
2. Obter parecer sobre os itens 1, 2 e 3 da seção 6.
3. Manter o VoiceStudio como **processo separado instalado pelo usuário** —
   minimiza superfície AGPL e elimina redistribuição.
4. Se redistribuição for necessária, orçar a *commercial license* do projeto
   (`hi@voicestudio.sh`) como alternativa à conformidade AGPL.
