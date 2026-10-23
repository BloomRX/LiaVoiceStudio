# installation-plan.md — Plano de instalação mínimo

**Status: AGUARDANDO AUTORIZAÇÃO EXPLÍCITA.** Nada foi instalado, baixado ou
executado.

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

**Esta é a opção correta para a missão.** Só pode ser executada por você, na sua
máquina. O laboratório não tem acesso a ela.

### A.1 Ação proposta

1. Baixar o instalador oficial **v0.5.6** (`VoiceStudio-Electron-0.5.6-win-x64.exe`)
   do GitHub Releases.
2. Conferir o SHA-256 contra o `SHA256SUMS` publicado na mesma release.
3. Instalar no escopo do usuário, destino `J:\VoiceStudio-Lab\app`.
4. Na primeira execução, aceitar **apenas** o motor padrão (OmniVoice, 2.4 GiB).
   Não instalar `audio.cpp`, nem sidecars, nem modelos de ASR.

### A.2 Motivo

É a única forma de responder às três perguntas que a inspeção estática não
responde: qualidade em pt-BR, latência real e comportamento no hardware AMD.

### A.3 Tamanho aproximado

| Item | Download | Em disco |
|---|---|---|
| Instalador Electron | ~150–250 MB | ~600 MB |
| Build CPU do PyTorch + deps | ~1.5 GB | ~5 GiB |
| Pesos OmniVoice | 2.4 GiB | 2.4 GiB |
| **Total** | **~4.3 GB** | **~8–10 GB** |

### A.4 Espaço total estimado necessário

**~12 GB livres em `J:`** (10 GB de uso + folga para o cache de download do `uv`
e do Hugging Face durante a instalação).

### A.5 Riscos e efeitos colaterais

| Risco | Gravidade | Mitigação |
|---|---|---|
| Modelo baixa automaticamente na 1ª geração | Médio | Usar `POST /models/install` explicitamente e acompanhar `/setup/download-stream` |
| PyTorch CPU **substitui** um PyTorch CUDA existente (se houver) | **Alto** se você usa CUDA para outra coisa | O instalador escolhe a variante na 1ª execução; verificar antes com `python -c "import torch;print(torch.version.cuda)"` |
| `uv`/HF gravam cache no disco `C:` | Baixo | Definir `OMNIVOICE_ENGINES_DIR` e `UV_CACHE_DIR` em `J:` antes de instalar |
| ~10 GB a menos em `J:` | Baixo | Registrar espaço antes/depois |
| App roda em CPU e parece "travado" | Médio | Esperado; ver `test-matrix.md` §5.3 |
| Script `irm ... \| iex` recomendado pelo README | **Médio** | **Não usar.** Preferir o `.exe` com hash conferido |
| Nenhuma alteração de driver ou variável global é necessária | — | O instalador é por usuário, sem admin |

### A.6 Como desfazer

```powershell
# 1. Desinstalar pelo Painel de Controle > Programas (VoiceStudio)
#    ou:  & "$env:LOCALAPPDATA\Programs\VoiceStudio\Uninstall VoiceStudio.exe"

# 2. Remover dados, modelos e ambientes (NÃO é feito pelo desinstalador)
#    ATENÇÃO: apaga vozes, projetos e configurações.
$appData = "$env:APPDATA\omnivoice"          # ajuste conforme a instalação
Remove-Item -Recurse -Force "$appData"
Remove-Item -Recurse -Force "J:\VoiceStudio-Lab\app"

# 3. Conferir que o espaço voltou
Get-PSDrive J | Select @{n='GB_livre';e={[math]::Round($_.Free/1GB,1)}}
```

O guia oficial de desinstalação (`docs/install/uninstall.md`) separa "remover o
app, mantendo seus dados" de "remover tudo" — vale ler antes.

### A.7 Critérios de aceite da instalação

- `GET http://127.0.0.1:3900/health` → `200 {"status":"ok","device":...}`
- `device` registrado (esperado: `"cpu"` na sua máquina)
- Uma geração curta (corpus `C6`) produz um WAV audível
- Fechar o app encerra o backend (nenhum `python.exe` órfão na porta 3900)
- Reabrir e gerar de novo funciona

---

## Opção B — Validação da API no laboratório (Linux, CPU, motor pequeno)

**Não substitui a Opção A.** Não responde nada sobre AMD, Vulkan ou Windows.
Serve para uma coisa só: **provar que a API se comporta como o código diz** —
descoberta, health, geração, formatos, erros, e o contrato que a Lia usaria.

### B.1 Ação proposta

Instalar no sandbox Linux **apenas o backend Python + o motor `supertonic3`**
(ONNX, CPU-only, ~400 MB, 31 idiomas incluindo português, 7 vozes preset), e
exercitar os endpoints por HTTP.

### B.2 Por que `supertonic3` e não o motor padrão

| Critério | OmniVoice (padrão) | Supertonic-3 |
|---|---|---|
| Pesos | 2.4 GiB | ~400 MB |
| RAM necessária | > 3.8 GiB disponíveis (risco de OOM) | cabe |
| pt-BR | sim | sim (31 idiomas) |
| Clonagem | sim | não (7 vozes preset) |

Com 3.8 GiB sem swap, o OmniVoice provavelmente falha por memória. O
Supertonic-3 valida o mesmo **contrato de API** com uma fração do risco.

### B.3 Tamanho aproximado

| Item | Download | Em disco |
|---|---|---|
| Backend Python + deps (torch CPU etc.) | ~1.2 GB | ~4 GB |
| Motor supertonic3 + pesos | ~450 MB | ~500 MB |
| **Total** | **~1.7 GB** | **~5 GB** (de 20 GB livres) |

### B.4 Riscos

| Risco | Gravidade | Mitigação |
|---|---|---|
| OOM durante a inferência (3.8 GiB, sem swap) | Médio | Usar apenas frases curtas (`C6`, `C1`); abortar se necessário |
| Download puxar `torch` CUDA por engano (~2.5 GB extra) | Baixo | Forçar variante CPU |
| Nenhum risco de rede: bind em `127.0.0.1` | — | Confirmar com `ss -lntp` |
| **O resultado não se aplica ao hardware-alvo** | **Alto (de interpretação)** | Marcado como tal em todos os relatórios |

### B.5 Como desfazer

```bash
rm -rf lab/VoiceStudio/.venv lab/venv ~/.cache/huggingface ~/.cache/uv
# nada foi instalado fora do diretório do laboratório; nenhum pacote de sistema
```

### B.6 O que isso provaria — e o que não provaria

**Provaria:** a API responde como documentado; `/health` transita 503→200;
`/engines/tts` lista motores com `available`/`device`; `/v1/audio/speech`
devolve áudio no formato pedido; erros retornam os códigos previstos; o serviço
fica restrito ao loopback.

**Não provaria:** nada sobre AMD, Vulkan, Windows, naturalidade em pt-BR, ou
latência na sua máquina.

---

## Opção C — Não instalar nada

Válida. Os relatórios continuam corretos e completos como **avaliação estática**,
e você executa a Opção A quando quiser. Nenhuma conclusão deste laboratório
depende de instalação.

---

## Recomendação do laboratório

**Opção A**, executada por você na máquina real — é a única que responde à
pergunta central.

**Opção B** é útil se você quiser, antes disso, confirmar que a API funciona
como os relatórios descrevem, sem gastar 10 GB na sua máquina. Mas ela responde
uma pergunta secundária.

**Nunca A + B ao mesmo tempo** sem motivo: são ambientes diferentes e os
resultados não se somam.
