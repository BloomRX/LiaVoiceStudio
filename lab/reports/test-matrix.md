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

**Status: PARCIALMENTE TESTADO.** As 10 frases do corpus foram geradas na
máquina-alvo (`evidence/windows/20261023-150843/`, 24 kHz mono) e analisadas por
sinal (§4.4). O que falta é **o ouvinte**.

**Motivo da lacuna:** avaliação subjetiva de naturalidade exige um ser humano.
O agente não pode ouvir nem julgar naturalidade, prosódia ou sotaque — e a
análise de sinal, por mais útil que seja, não substitui isso.

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

### 4.4 Análise acústica objetiva das 10 amostras (sem ouvinte humano)

**Status: MEDIDO — mas isto NÃO substitui a audição.** O operador não ouviu os
arquivos, então a grade subjetiva de §4.2 continua **não preenchida**. Para não
deixar a Fase C sem nenhuma evidência, rodei uma análise de sinal sobre os 10
WAVs de `evidence/windows/20261023-150843/` (24 kHz, mono, 16 bits, voz pronta
`omnivoice`, pt, seed 42). Ferramentas: `numpy` + estimador **YIN** próprio
(60–500 Hz) para F0 e centroide espectral.

| Arquivo | dur (s) | silêncio | F0 mediano | F0 p10–p90 | saltos de oitava | centroide |
|---|---|---|---|---|---|---|
| C1 | 6,01 | 26,5% | **315,8 Hz** | 253–407 | 3,1% | 2015 Hz |
| C2 | 6,92 | 28,1% | 138,3 | 106–206 | 1,7% | 1643 Hz |
| C3 | 11,76 | 21,6% | 119,4 | 90–144 | 1,8% | 1528 Hz |
| C4 | 8,68 | 18,7% | 129,0 | 105–166 | 3,6% | 1483 Hz |
| C5 | 9,48 | 18,0% | 135,6 | 106–209 | 4,7% | 1499 Hz |
| C6 | 1,01 | 38,4% | 138,7 | 114–178 | 11,1% | 1958 Hz |
| C7 | 22,43 | 23,5% | 134,8 | 109–183 | 3,4% | 1636 Hz |
| C8 | 6,68 | 29,6% | **255,3** | 171–375 | 1,5% | 1914 Hz |
| C9 | 7,04 | 31,1% | 171,4 | 137–211 | 4,5% | 1647 Hz |
| C10 | 8,04 | 15,5% | **195,1** | 150–233 | 5,8% | 2015 Hz |

**O que isso prova:**

1. **Nível e higiene do sinal estão corretos.** Pico entre 0,78 e 0,80 (≈ −2 dBFS),
   **zero amostras em clipping**, nenhum trecho de silêncio anômalo (15–38%, e o
   maior valor é o C6, que tem 1 segundo). Não há estouro nem arquivo mudo — os
   defeitos mais comuns de TTS estão ausentes.
2. **A voz NÃO é estável entre frases.** Todos os 10 arquivos usam a **mesma voz,
   o mesmo seed e o mesmo motor**. O F0 mediano deveria ficar na mesma faixa.
   Variou de **119,4 Hz a 315,8 Hz — 2,64×**, ou seja, mais de uma oitava.
   C1 está uma oitava acima da mediana (315,8 vs ~135 Hz); C8 (255) e C10 (195)
   ficam no meio; C2–C7 formam o grupo coerente (~120–140 Hz).
3. **Não é falha do estimador.** A taxa de saltos de oitava ficou entre 1,5% e
   11,1% — baixa. Se o algoritmo estivesse travando na oitava errada, o p10–p90
   estaria deslocado inteiro, não apenas alguns quadros. A variação acompanha o
   arquivo inteiro, o que indica **deriva de locutor entre frases** (a identidade
   vocal "escorrega" conforme o texto), não ruído de medição.
4. **O timbre acompanha**: o centroide espectral sobe de ~1.480 Hz (C4) para
   ~2.015 Hz (C1/C10) — coerente com a percepção esperada de "voz mais fina".

**O que isso NÃO prova:** se soa natural, inteligível, sotaqueado ou agradável.
F0 alto não é defeito por si: pode ser prosódia correta de uma pergunta. A
hipótese mais informativa a testar com ouvido humano é se **C1 e C8 parecem
outra pessoa**. Se parecerem, é o defeito mais grave encontrado no laboratório,
porque quebraria continuidade de personagem em uso conversacional.

**Reprodutibilidade do corpus:** C6 foi gerado duas vezes (40,31 s e 39,96 s) —
0,9% de diferença em tempo de geração. Isso mostra que a **duração da síntese** é
estável; a instabilidade acima é de **conteúdo acústico**, não de desempenho.

**Procedimento para fechar a lacuna:**

```powershell
# ouvir em ordem, com fones, marcando 1-5 para cada critério de §4.2
explorer reports\evidence\windows\20261023-150843
# ou testar a hipótese especifica (C1 e C3 devem soar como a mesma pessoa?)
ffplay -autoexit C1.wav   # apenas C1, C3, C8, C10
```

> **Nota de honestidade:** a análise acima é um **substituto parcial**, não uma
> aprovação de qualidade. Ela detecta instabilidade, clipping e silêncio; não
> detecta pronúncia errada de "IPTU", "WhatsApp" ou entonação de pergunta.

---

## 5. Fase D — AMD, CPU e Vulkan

**Status: MEDIDO — 10 frases do corpus na máquina real.** RTF ≈ 25,6 em regime.

A máquina-alvo foi identificada pela coleta de 2026-10-23
(`evidence/windows/20261023-140732/`):

| Item | Valor |
|---|---|
| CPU | AMD Ryzen 5 5500 — 6C/12T |
| GPU | AMD Radeon RX 580 2048SP (Polaris 20, `gfx803`), driver 31.0.21925.1001 |
| VRAM | **8 GB** (informado pelo operador). CIM reporta 4 GB por saturação do `AdapterRAM` |
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

Repetida duas vezes mais, mesma frase, app reaberto a cada vez:

| Coleta | `X-Gen-Time` | áudio | RTF |
|---|---|---|---|
| 20261023-144336 | 40,32 s | 1,01 s | 39,9 |
| 20261023-145020 | **172,74 s** | 1,09 s | **158,5** |
| 20261023-145757 | 39,45 s | 1,01 s | 39,1 |

**Como ler isso:** RTF entre 40 e 158 significa **40 a 158 s de processamento
por segundo de áudio**. Uma frase de 10 s levaria de 6,6 a 26 min.

### 5.0.1 Regime medido: 10 frases, uma sessão

`evidence/windows/20261023-150843/` — modo `/voice`, app aberto uma vez, as 10
frases do corpus em sequência, motor `omnivoice`, `language=pt`, seed 42:

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

**Total: 38 min de processamento para 88 s de áudio. RTF agregado 25,9.**

O comportamento é linear e previsível:

```
gen_s ≈ 2,6 + 25,63 × audio_s        (R² > 0,99 nas 9 frases > 1 s)
```

O erro do ajuste fica entre 0,6 % e 3,5 % nas frases longas. **Só a C6 escapa**
(28 s previstos, 39 s reais): com 1 s de áudio, sobra uma parcela fixa por
requisição — inicialização do motor, pré-processamento, escrita do WAV — que o
modelo linear não captura. Ou seja: **frases curtas têm RTF pior, não melhor**.

**Dispersão entre execuções: desprezível.** O modo padrão rodou a mesma C6 duas
vezes seguidas (`20261023-150602`): 40,31 s e 39,96 s — 0,9 % de diferença. O
outlier de 173 s da coleta `145020` **não se repetiu em 8 execuções** e deve ser
tratado como incidente isolado daquela sessão, não como variância do motor.

**Instabilidade observada — três mortes não limpas em sequência.** O log do
backend, ao subir, acusa a execução anterior:

```
15:06:14 WARNING [run_sentinel] Previous backend run (pid 19144) ended uncleanly
15:52:09 WARNING [run_sentinel] Previous backend run (pid 18792) ended uncleanly
15:59:36 WARNING [run_sentinel] Previous backend run (pid 15820) ended uncleanly
```

As três com **`last activity: generate`**. Não são desligamentos normais: o
sentinel existe justamente para detectar processo morto sem despedida. E o app
avisa, em cada carga de modelo, que está no limite:

```
WARNING [memory_budget] TTS load (omnivoice): Low memory: 1.2–1.9 GB free.
        Loading a large model here risks the backend being killed by the OS
```

**Hipótese mais provável: OOM-kill pelo Windows depois da geração**, com os
pesos ainda residentes. Não está provado — o `last_run_crash.json` não foi
coletado. Fica como risco aberto para a Lia: um processo que morre sozinho
depois de gerar áudio precisa de supervisão e retry no lado de quem consome.

**Nota sobre memória (coleta `20261023-155155`).** Durante a geração o próprio
app emitiu:

```
WARNING [omnivoice.memory_budget] TTS load (omnivoice): Low memory: 1.3 GB free.
        Loading a large model here risks the backend being killed by the OS
INFO   Capture ASR preload skipped: <4GB free RAM
```

Com 15,89 GB totais e o modelo carregado, sobravam **1,3 GB livres**. Isso importa
para a Lia: rodar o VoiceStudio **junto** com outros modelos (o Kokoro dela, por
exemplo) compete por RAM. O backend avisa que pode ser morto pelo SO — não é
teórico, é o orçamento de memória do próprio app calculando.

**Consequência para a Lia:** RTF 25,9 significa que o VoiceStudio leva **26
segundos de CPU para produzir 1 segundo de fala**.

| Fala da Lia | Tempo de geração |
|---|---|
| 3 s (uma frase curta) | ~1,3 min |
| 10 s (um parágrafo) | ~4,3 min |
| 30 s (uma explicação) | ~13 min |

Isso **elimina uso conversacional** nesta máquina. Serve para geração
assíncrona: pré-renderizar saudações, mensagens fixas, audiolivro, narração em
lote.

**Ressalva obrigatória:** as três são a **primeira** geração de um processo
recém-aberto e incluem a carga dos pesos (2,4 GB). O protocolo manda separar a
primeira execução por isso.

**A dispersão não é ruído de medição — é a carga.** Duas das três rodadas caem em
~39–40 s; uma deu 173 s. O que mudou nela não foi o motor, foi o ambiente:
leitura de 2,4 GB do disco, possível varredura do antivírus sobre arquivos
recém-gravados, ou contenção com outro processo. **A causa exata desse outlier
não está determinada** — com três amostras não dá para separar as hipóteses, e eu
não vou escolher a mais conveniente.

O que isso obriga: **cada execução do `.bat` com o app fechado paga um
carregamento frio**, e esse custo domina o número. Por isso o modo padrão passou
a gerar a frase **duas vezes** (a primeira é aquecimento, descartada), e a
medição válida é a execução 2+ dentro da mesma sessão — `/voice` (10 frases) ou
`/full` (4× C7).

O app confirma o que a análise estática previa: `gpu_routing` = `omnivoice — cpu
(no accelerator on this host)`. Não há GPU no caminho.

O que ainda falta da Fase D:

- **Vulkan/GGUF** — ✅ executado em 2026-10-23 15:59: **ausente neste build**
  (`binary_found=false`). Ver §5.2.
- **Vulkan de verdade (audio.cpp)** — o modo `/gpu` foi escrito para medir a
  placa pelo único caminho nativo que o app oferece (runtime Vulkan do
  `audio.cpp`). Execução `PENDENTE` — precisa de `run-lab.bat /gpu`.
- **CPU/RAM durante a geração** — o script mede tempo, não amostra consumo.
- **RTF com voz clonada** vs. voz padrão.
- **TTFA** (tempo até o primeiro áudio) só existe no caminho de streaming, que o
  coletor não exercita.

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

- **OmniVoice GGUF em Vulkan** — ❌ **TESTADO E ENCERRADO (2026-10-23 15:59).**
  Resultado em `evidence/windows/20261023-155921/gguf.json`: `binary_found=false`,
  `ggml_libs=[]`, `engine_available=false`. O build Windows da v0.5.6 não traz o
  runtime `omnivoice-tts` nem as DLL `ggml*`. Hipótese original abaixo, mantida
  para registro histórico:
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
     que **cabe** nos **8 GB** da RX 580.
  Teste: `run-lab.bat /gguf` — procura o executável em
  `<app>\resources\bin\`, lista as DLL `ggml*`, lê o `reason` de
  `/engines/tts`, gera uma frase com `engine=omnivoice-gguf` (se disponível) e
  captura `/system/logs`, onde o `omnivoice-tts` anuncia o dispositivo
  escolhido. Saída em `gguf.json`.
  Foi exatamente o que aconteceu: o teste virou diagnóstico. Medir Vulkan
  exigiria compilar `omnivoice.cpp` (`buildvulkan.sh`) com MSVC + Vulkan SDK —
  outra escala de esforço, e sem retorno esperado (ver §5.4).
- Se a Radeon específica do usuário expõe um dispositivo Vulkan discreto que o
  `audiocpp_server` reconhece.
- Se o Vulkan do Windows nessa máquina é mais rápido que CPU — **não pode ser
  afirmado sem medição pareada**.
- Qual o overhead real de primeira execução (compilação de shaders/grafo).

### 5.2.1 Medir a placa pelo caminho que existe: `run-lab.bat /gpu`

Como o GGUF não vem no build (§5.2), sobrou um caminho **nativo** para fazer a
RX 580 trabalhar: o `audio.cpp`. O próprio app publica o binário Windows com
Vulkan (`audio-v0.7.4-bin-windows-x64-vulkan.zip`, 56.818.905 B, com SHA-256
fixado em `bootstrap.py`) e um modelo que aceita Vulkan — o Breeze-TTS-2.

O passo `[7c]` do `run-lab.bat` (switch `/gpu`) faz isto sozinho:

1. lê a **VRAM real** no registro (`HardwareInformation.qwMemorySize`, tratando
   o caso `byte[]` de `REG_QWORD` que o PowerShell entrega em `Get-ItemProperty`);
2. instala o runtime nativo do `audio.cpp` pelo próprio serviço do app
   (`audiocpp_runtime_install.status()/start_install()` → `installed`, `version`);
3. roda `audiocpp_server.exe --list-devices` e guarda a saída bruta — é o **único
   juiz** de se a placa é vista pelo Vulkan (`REGISTRY: idx name`);
4. **só se** a saída contiver `Vulkan:` baixa o Breeze-TTS-2 (4,98 GB). Se não
   contiver, não baixa nada — evita 5 GB de disco para um teste fadado a rodar em
   CPU via llvmpipe (que o bootstrap **descarta** de propósito);
5. gera frases **em inglês** (o Breeze só fala en/zh — este teste mede a
   **placa**, não o português) e calcula o RTF por frase;
6. grava `gpu.json` (hardware, dispositivos, versões, tempos) e uma seção
   "GPU real (Vulkan / audio.cpp)" no `summary.md`.

**O que este teste NÃO vai responder:** se o português fica mais rápido. Ele
responde uma pergunta diferente e igualmente necessária à Fase D: *"a RX 580 é
utilizável por algum motor deste app, hoje, sem compilar nada?"* Se o RTF do
Breeze em Vulkan ficar próximo do RTF em CPU, o ganho de GPU nesta placa é
pequeno e a conta de §5.4 (26×) fica definitivamente fechada. Se ficar muito
menor, existe uma placa utilizável — mas sem modelo em português para colocá-la.

### 5.4 Por que não vale insistir no Vulkan

Mesmo se o binário GGML fosse compilado com backend Vulkan, a conta não fecha:

| Cenário | RTF estimado | Fala de 10 s |
|---|---|---|
| CPU (medido) | 25,9 | 4,3 min |
| Vulkan, ganho típico 3–5× nesta placa | 5–9 | 50–90 s |
| Necessário para conversa | **< 1** | < 10 s |

Para uso conversacional seria preciso **~26×** de ganho. Nenhuma GPU Polaris
entrega isso em decode de TTS — e a RX 580 é de 2017, com **8 GB** (a VRAM não é
o limite aqui; 8 GB comportam o modelo com folga).

Vulkan mudaria "4,3 min" para "1 min". É uma melhora real para **geração em
lote**, e irrelevante para **conversa**. Como o caso de uso da Lia é
conversacional, o investimento (compilar toolchain C++ no Windows) não se paga.

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
| B — instalação | **Alta** | ✅ TESTADO na máquina real (v0.5.6, 214.447.484 B, sha256 fixado) |
| C — qualidade de voz | **Média** | 10 frases geradas + análise acústica (§4.4); **audição humana PENDENTE** |
| D — AMD/Vulkan | **Alta para o que foi testado** | ✅ RTF 25,9 medido em CPU · GGUF testado e ausente · `/gpu` (audio.cpp/Vulkan) **PENDENTE** |
| E — API | **Alta** (código **e** runtime) | ✅ TESTADO — backend exercitado por HTTP |
| F — licenças | **Alta** | ✅ INSPECIONADO + confirmado em runtime |
| G — integração | **Análise** | — |

Onde o runtime corrigiu a inspeção: orçamento de tempo (não é 600 s) e ausência
de `supported_languages` na API. Ambos registrados acima e em
`evidence/runtime/README.md`.
