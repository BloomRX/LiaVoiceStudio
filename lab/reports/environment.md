# environment.md — Sistema, hardware e versões

**Data da avaliação:** 2026-10-23
**Versão do VoiceStudio avaliada:** `main` @ `48e85106eb00a69c9beea3bdbf0a23692c7aa8ca` (última tag estável: **v0.5.6**, 2026-09-23)

---

## 1. Aviso metodológico crítico — o ambiente não é o ambiente-alvo

A missão foi escrita para uma máquina **Windows com GPU AMD e disco `J:`**.
O laboratório **não** foi executado nesse ambiente. O agente roda em um contêiner
Linux isolado. Isso é registrado aqui antes de qualquer conclusão, porque muda o
que pode e o que não pode ser afirmado.

| Requisito da missão | Situação real | Impacto |
|---|---|---|
| `J:\VoiceStudio-Lab` | **Inexistente.** Não há unidade `J:`, nem Windows, nem acesso ao host do usuário. | Diretório do laboratório foi recriado em `lab/` dentro do checkout da sessão. **Não é equivalente.** |
| Windows 10/11 x64 | **Não.** Debian GNU/Linux 12 (bookworm), kernel 6.1.158 | Instalador `.exe`, MSI, Electron shell e paths `%APPDATA%` **não testáveis** |
| CPU AMD (Ryzen) | **Não.** Intel Xeon @ 2.60 GHz, 2 vCPU | Detecção de CPU AMD não testável |
| GPU AMD (Radeon) + driver | **Não.** Nenhum dispositivo de vídeo enumerável (`lspci` ausente) | Vulkan, ROCm, HIP, CUDA: **todos não testáveis** |
| Vulkan runtime | **Não instalado** (`vulkaninfo` ausente) | Caminho `audio.cpp` + Vulkan **não testável** |
| RAM | 3.8 GiB, **sem swap** | Abaixo do mínimo prático para os motores de TTS principais |
| Disco livre | 20 GB | Suficiente para um motor pequeno, insuficiente para app completo + sidecars |
| Saída de áudio | Nenhuma | **Avaliação subjetiva de qualidade de voz é impossível** |

**Consequência direta:** as fases **B (instalação), C (qualidade de voz) e D
(AMD/Vulkan)** não puderam ser executadas conforme especificado. Elas estão
marcadas como **NÃO TESTADAS** em `test-matrix.md`, com o procedimento exato de
validação para a máquina real.

Este relatório **não inventa** medições de desempenho, notas de naturalidade ou
comparações com ElevenLabs.

---

## 2. Ambiente efetivamente usado (para reprodutibilidade da inspeção estática)

```
SO            Debian GNU/Linux 12 (bookworm), kernel 6.1.158+ x86_64
CPU           2 vCPU — Intel(R) Xeon(R) Processor @ 2.60GHz
RAM           3.8 GiB total, 0 B swap
Disco         21 GB, 20 GB livres
GPU           nenhuma (sem lspci, sem Vulkan, sem ROCm)
Python        3.11.2  (VoiceStudio exige 3.11 — .python-version)
Node.js       22.22.3 (VoiceStudio exige 22+)
git           2.39.5
gh            2.23.0
```

Evidência bruta: `evidence/a1-environment.txt`.

---

## 3. Identidade exata da versão avaliada

Fonte: `evidence/a2-version.txt`.

| Campo | Valor |
|---|---|
| URL de origem | `https://github.com/debpalash/VoiceStudio.git` |
| Branch clonada | `main` |
| Commit SHA | `48e85106eb00a69c9beea3bdbf0a23692c7aa8ca` |
| Data do commit | 2026-10-23T19:34:19+05:30 |
| `git describe` | `v0.5.7-beta.1-5-g48e85106` |
| Última **tag estável** publicada | **v0.5.6** (2026-09-23) |
| Versão em `package.json` | `0.5.7-beta.1` |
| Licença declarada | `AGPL-3.0-only` |
| Python exigido | 3.11 |
| Tamanho do checkout (com histórico) | 225 MB |
| Código | ~126.700 linhas Python + ~128.300 linhas TS/TSX |
| Submódulo | `omnivoice-gallery` → `debpalash/omnivoice-gallery.git` |

> **Nota importante:** a inspeção foi feita sobre `main`, que é **5 commits à
> frente** de `v0.5.7-beta.1` e não é uma versão estável. Onde a diferença
> importa, o relatório diz explicitamente. Para a fase de teste real, recomenda-se
> fixar **v0.5.6** (a última release estável) ou `v0.5.7-beta.1`, nunca `main`.

O histórico Git foi preservado integralmente (`git clone` completo, sem
`--depth`). Nenhum commit ou push foi feito no repositório oficial.

---

## 4. Requisitos de hardware e disco declarados pelo projeto

Estes números vêm da documentação oficial, **não de medição**:

| Item | Valor declarado | Fonte |
|---|---|---|
| Disco, Windows, com GPU NVIDIA | ~10 GB (app + ambiente Python + pesos) | `docs/install/windows.md` |
| Disco, Windows, **sem** GPU NVIDIA | ~5 GiB (build CPU do PyTorch) | `docs/install/windows.md` |
| VRAM recomendada, OmniVoice | **6 GB** (único piso medido do projeto) | `docs/engines/omnivoice.md` |
| VRAM, audio.cpp (CUDA/HIP/Vulkan discreto) | ~6 GB; iGPU usa memória unificada | `docs/engines/audio-cpp.md` |
| Pesos OmniVoice (padrão) | 2.4 GiB | `backend/config/models.yaml` |
| Pesos Breeze-TTS-2 Q8_0 (GGUF) | ~4.73 GiB (+ Sortformer) | `docs/engines/audio-cpp.md` |
| Runtime exigido | Python 3.11 (gerenciado por `uv`), Node 22+ | `.python-version`, README |

Sidecars (IndexTTS, MOSS-TTS-v1.5, dots.tts) podem **duplicar o torch** e somar
vários GB cada. Ver `docs/engines/disk-usage.md`.

---

## 5. Suporte a Windows + AMD — o que a documentação e o código dizem

Esta é a pergunta central da Fase D. O projeto é incomumente explícito, e a
documentação **confere** com o código:

> "**PyTorch GPU acceleration on Windows is NVIDIA/CUDA-only.** (...) **AMD GPUs
> — including Ryzen / Ryzen AI integrated Radeon graphics — do not accelerate
> PyTorch engines on Windows.**"
> — `docs/install/windows.md`

> "Note: **PyTorch GPU acceleration on Windows is NVIDIA/CUDA-only** — AMD and
> Intel GPUs run PyTorch engines on the CPU there (audio.cpp can still use a
> Radeon through Vulkan (...))."
> — `docs/performance.md`

Consequências verificadas no código:

- `OMNIVOICE_TORCH_VARIANT=rocm` é **ignorado no Windows** (Linux-only), por
  declaração explícita da doc de instalação.
- O backend detecta e **relata** AMD corretamente: `backend/core/device_caps.py`
  define `DeviceFamily = Literal["cuda","rocm","mps","xpu","npu","cpu"]`,
  distingue ROCm de CUDA, e tem uma tabela `ROCM_GFX_OVERRIDES` com remapeamento
  `HSA_OVERRIDE_GFX_VERSION` para RDNA 2 (`gfx1031/1032/1034 → gfx1030`),
  RDNA 3 (`gfx1101/1102/1103 → gfx1100`), RDNA 3.5 (`gfx1150/1151 → gfx1100`)
  e Vega (`gfx902/906`). Ou seja: **o suporte AMD existe, mas é Linux/ROCm.**
- `GET /api/settings/gpu-report` existe e devolve, por motor, se usa GPU e por
  quê não — inclusive o caso "sua Radeon foi encontrada, mas este build do
  PyTorch é NVIDIA-only".

**Portanto, no alvo Windows + AMD:** todos os motores PyTorch (incluindo o
padrão OmniVoice) rodam em **CPU**. A única exceção é o `audio.cpp`.

---

## 6. O caminho `audio.cpp` / Breeze-TTS-2 / Vulkan — verificação

### 6.1 O suporte a Vulkan existe de fato?

**Sim, no nível de distribuição binária e de código de descoberta.** Três
confirmações independentes:

1. `docs/engines/audio-cpp.md` lista `Windows x64 | CPU, Vulkan, CUDA 12.4/13.3
   prebuilts`.
2. `backend/engines/audiocpp/bootstrap.py` fixa o artefato
   `audio-v0.7.4-bin-windows-x64-vulkan.zip` com SHA-256
   `057332f9e3fb37706a8ecb5075ac1797efcd85fdccd739f7b65761a5920f2828`.
3. O upstream `0xShug0/audio.cpp` publica, na release **v0.9.2**, o asset
   `audio-v0.9.2-bin-windows-x64-vulkan.zip` (confirmado via API do GitHub).

O código faz descoberta real de dispositivos: executa `audiocpp_server
--list-devices` uma vez por binário, com timeout de 10 s, e faz parsing de um
contrato de stdout com registries `CUDA`, `MUSA`, `HIP`, `ROCm`, `Vulkan`,
`Metal`. Há tratamento explícito para **filtrar adaptadores de software**
(llvmpipe), o que é um detalhe de qualidade relevante: evita "achar" GPU onde só
existe rasterizador por software.

### 6.2 Mas o Vulkan serve para português?

**Não.** Este é o achado decisivo da Fase D e ele contradiz a expectativa
implícita na missão.

- Código: `backend/engines/audiocpp/__init__.py` → `supported_languages` retorna
  literalmente `["en", "zh"]`.
- Doc: "Breeze-TTS-2 (BreezeBlue, 3B params, **English + Chinese**, ...)".
- Card oficial do modelo (HF `BreezeBlue/Breeze-TTS-2`): "**Bilingual Support**
  — Generates natural English and Chinese speech with a single model."

O `audio.cpp` tem uma **família v1 = `breeze_tts`** apenas. Não há modelo
português nesse caminho.

**Conclusão:** a única rota de aceleração por GPU que funciona numa Radeon no
Windows **não atende ao caso de uso da Lia**, que é português brasileiro.

### 6.3 Defasagem de versão

O VoiceStudio fixa `audio.cpp` **v0.7.4**. O upstream está em **v0.9.2**
(2026-10-15) e já publicou `v0.9.2-drama3-base-small` (2026-10-19), com novas
famílias de modelo. O pin é uma prática de segurança correta, mas significa que
o laboratório testaria um runtime com ~2 versões de atraso.

---

## 7. Limitações deste documento

- Nenhuma medição de tempo, memória ou GPU foi feita. Os números da seção 4 são
  **declarados pelo projeto**, não medidos aqui.
- Não foi possível verificar se a GPU AMD do usuário está na lista de GFX
  suportados pelo ROCm do Windows (que a própria doc classifica como
  "avançado/não suportado").
- A versão de driver gráfico do usuário é desconhecida.

## 8. Como validar de verdade (para a máquina Windows + AMD)

```powershell
# 1. Identidade do hardware
Get-CimInstance Win32_Processor | Select Name,NumberOfCores
Get-CimInstance Win32_VideoController | Select Name,DriverVersion,AdapterRAM
Get-CimInstance Win32_OperatingSystem | Select Caption,Version,OSArchitecture
Get-PSDrive J | Select Used,Free

# 2. Versão do app efetivamente instalada
#    Settings → About (e confira contra a tag esperada)

# 3. O que o próprio app acha do hardware
curl.exe http://127.0.0.1:3900/api/settings/gpu-report
curl.exe http://127.0.0.1:3900/system/diagnose
curl.exe http://127.0.0.1:3900/system/info
```

O campo `device` em `GET /health` e o header `X-OmniVoice-Routing` em cada
geração dizem qual dispositivo foi realmente usado — é assim que se prova (ou se
refuta) aceleração por GPU, sem confiar na UI.
