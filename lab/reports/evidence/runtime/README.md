# Evidence — testes de API em runtime (sandbox Linux, CPU)

**Data:** 2026-10-23 · **Ambiente:** Debian 12, 2 vCPU Intel Xeon, 3.8 GiB RAM, **sem GPU**
**Versão:** `0.5.7-beta.1` (commit `48e85106`) · **Python:** 3.11.2 · **torch:** 2.14.1 · **transformers:** 5.20.2

Este diretório existe porque, ao contrário das fases B/C/D, a **Fase E pôde ser
executada de verdade**. O backend Python do VoiceStudio sobe sozinho, sem o
shell Electron, e respondeu a requisições HTTP reais.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `e1-health.txt` | `/health`, `/startup/progress`, `/system/info`, `/generate/budget` |
| `e2-engines.txt` | `GET /engines/tts` — 17 motores, disponibilidade, device, capacidades |
| `e3-errors.txt` | `/v1/audio/voices`, códigos de erro, gate de licença |
| `e4-licence-binding.txt` | detalhes de licença, binding de rede |
| `e5-licence-generation.txt` | aceite headless + tentativas de geração |
| `e6-server-log.txt` | log do backend na falha de carregamento de pesos |

---

## O que foi provado

**1. O backend sobe headless.** `uvicorn main:app` partiu em **5,6 s** (o
`/startup/progress` detalha: `ml_imports` 2,93 s, `api_routes` 1,70 s,
`db_migrate` 0,78 s). Não precisa do Electron para servir a API — o Electron é
só o supervisor.

**2. `/health` responde exatamente como documentado.**
`{"status":"ok","device":"cpu","version":"0.5.7-beta.1"}` — o campo `device`
denuncia CPU, como previsto.

**3. `/startup/progress` distingue "subindo" de "morto".** Devolve a lista de
etapas com estado e tempo. É o endpoint certo para a Lia não confundir boot
lento com serviço ausente.

**4. `/system/info` entrega o inventário de hardware pronto.** Inclui
`cpu_model`, `cpu_count`, `ram_total_gb`, `gpu_name` (vazio), `vram_total_gb`
(0.0), `disk_free_gb`, `ffmpeg_ok`, e os dois timeouts. Para a Fase D na máquina
real, é aqui que se confirma o hardware sem olhar a UI.

**5. `GET /engines/tts` lista 17 motores** com `available`, `effective_device`,
`gpu_compat`, `supports_cloning`, `supports_voice_design`, `preset_voices`,
`max_ref_seconds`, `ref_strategy`, `isolation_mode` e `reason` (motivo em texto
claro quando indisponível). Numa instalação crua, só `omnivoice` e
`omnivoice-subprocess` estão disponíveis — os demais exigem instalação.

**6. O gate de licença é real e granular.** `POST /generate` devolve
**403** `model_licence_required` com `repo_id`, `license`, `category`
(`noncommercial`, `conditions`, `unknown`) e um `fingerprint` versionado.

**7. O aceite headless funciona.** `POST /models/licenses/accept` com
`{repo_id, fingerprint, accepted:true}` → **200**, grava `accepted_at` e
`last_action` com a versão do app. Provisionamento automatizado é viável — mas
exige primeiro provocar o 403 para obter o fingerprint (ou ler
`/models/licenses/details/{repo}`).

**8. O OmniVoice exige DUAS licenças distintas** — confirmado em runtime:
`k2-fsa/OmniVoice` (CC-BY-NC, `noncommercial`) **e**
`eustlb/higgs-audio-v2-tokenizer` (`NOASSERTION`, `unknown`). A camada do
tokenizador não é teórica: é um segundo portão efetivo.

**9. Isolamento de rede confirmado.** `ss -lntp` mostra o processo Python preso
a `127.0.0.1:3900` (sem `0.0.0.0`). *(A entrada `169.254.0.21:3900` sem PID é o
proxy do sandbox, não o backend.)*

**10. A superfície OpenAI é fiel.** `/v1/audio/speech` com modelo inválido devolve
`{"error":{"type":"invalid_request_error","param":"model","code":"model_not_found"}}`
— o formato que SDKs OpenAI já sabem interpretar.

---

## O que NÃO foi provado — e por quê

**Nenhum áudio foi gerado.** `huggingface.co` não é alcançável a partir deste
sandbox (HTTP 000), e todos os pesos vêm de lá. A tentativa de geração após o
aceite das licenças falhou com:

```
HTTP 500
{"detail":"VoiceStudio hit an internal error; check the backend log for details.",
 "error_class":"HF_AUTH_FAILED","error_type":"OSError"}
OSError: We couldn't connect to 'https://huggingface.co' to load the files
```

Isso **não** é um defeito do VoiceStudio — é o comportamento esperado sem rede.
Mas é um achado relevante para a integração: **falha de rede ao carregar pesos
retorna 500, não um 4xx limpo.** A Lia precisa mapear isso para "provedor
indisponível", não para "erro fatal".

Também **não** foram instalados motores alternativos (`supertonic3` exige
`pip install` + pesos do HF, ambos bloqueados).

---

## Consequências para o relatório

Duas afirmações anteriores foram **corrigidas** por este runtime:

1. **`/generate/budget` não é o timeout total.** Devolve
   `{modelLoad:1200, queueWait:1800, executionBase:600, progressExtensionCap:1800, cpuAutoCeiling:7200}`.
   O "600 s" é só a base de execução; com extensão por progresso e teto automático
   de CPU, uma requisição pode durar bem mais. Sugerir "timeout de 660 s" era
   simplista — corrigido em `test-matrix.md` e `integration-proposal.md`.

2. **A API não informa os idiomas suportados.** `supported_languages` **não**
   aparece no payload de `/engines/tts`. Logo, a Lia **não pode** perguntar ao
   serviço "este motor fala pt-BR?" — precisa de um mapa estático próprio.
   Corrigido em `integration-proposal.md` §9.

## Reprodução

```bash
uv venv --python 3.11 lab/venv
uv pip install --python lab/venv/bin/python -r lab/requirements-core.txt
cd lab/VoiceStudio/backend && ../../venv/bin/python -m uvicorn main:app \
  --host 127.0.0.1 --port 3900
```

Duas dependências declaradas **não** puderam ser instaladas por bloqueio de rede
(`kittentts` e `en-core-web-sm`, ambas hospedadas em
`objects.githubusercontent.com`). O backend subiu mesmo assim — elas não são
críticas para a importação, apenas para os motores que as usam.
