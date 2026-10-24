# LiaVoiceStudio — laboratório de avaliação do VoiceStudio

Avaliação técnica independente do [VoiceStudio](https://github.com/debpalash/VoiceStudio)
como possível provedor local de voz para a Lia, em **português brasileiro**.

**Nada aqui integra o VoiceStudio à Lia.** Este repositório contém o laboratório
e seus relatórios. A integração é uma tarefa futura, separada.

---

## Comece por aqui

Se você quer **rodar a coleta na sua máquina Windows + AMD**:

```
run-lab.bat          (ou: run-lab.bat /gpu  para medir a placa)
```

Ele **instala o VoiceStudio** (instalador oficial v0.5.6, SHA-256 conferido),
**baixa o modelo OmniVoice**, gera uma frase de teste, escreve o resumo e faz
commit + push. Depois leia
`lab/reports/evidence/windows/<timestamp>/summary.md`.

> Um clique é inevitável: na primeira execução o app pede **"Instalar ambiente
> local"** (Python + dependências). Clique uma vez — o `.bat` espera e continua
> sozinho. Explicação em [`lab/tools/README.md`](lab/tools/README.md).

Detalhes e modos: [`lab/tools/README.md`](lab/tools/README.md)

Se você quer **entender as conclusões**:

Leia [`lab/reports/executive-summary.md`](lab/reports/executive-summary.md).

---

## Estrutura

```
LiaVoiceStudio/
├─ run-lab.bat                 ARQUIVO ÚNICO: instala + coleta + relatórios + git
│
├─ lab/
│  ├─ reports/                 RELATÓRIOS (o entregável)
│  │  ├─ README.md             índice e regras de leitura
│  │  ├─ executive-summary.md  conclusão e recomendação
│  │  ├─ environment.md        hardware, versões, limitações
│  │  ├─ test-matrix.md        16 configurações + procedimentos
│  │  ├─ licensing.md          AGPL, CC-BY-NC, dúvidas jurídicas
│  │  ├─ integration-proposal.md   arquitetura futura (sem implementação)
│  │  ├─ installation-plan.md  plano com custos e rollback
│  │  ├─ corpus/               10 frases pt-BR + SHA-256
│  │  └─ evidence/
│  │     ├─ a1..a6-*.txt       inspeção estática (Linux)
│  │     ├─ runtime/           Fase E executada (backend real)
│  │     ├─ install/           primeira instalacao real (preflight)
│  │     └─ windows/           <- o que run-lab.bat produz
│  │
│  ├─ tools/
│  │  └─ README.md             guia do run-lab.bat
│  │
│  └─ requirements-core.txt    dependências usadas no teste de API
│
└─ README.md                   este arquivo
```

Pasta de trabalho que **não** é versionada: `lab/VoiceStudio/` (clone de
terceiros) e `lab/venv/` (ambiente Python). Ambas são reproduzíveis.

---

## Estado da avaliação

| Fase | Status |
|---|---|
| A — investigação estática | ✅ executada |
| B — instalação | ✅ app + modelo + 1 WAV gerado (falta fechar/reabrir) |
| C — qualidade de voz | 🟡 10 amostras geradas + análise acústica objetiva; falta ouvinte humano |
| D — AMD / Vulkan | ✅ **RTF 25,9** em CPU (OmniVoice). Vulkan funciona na RX 580, mas medido pareado é **22% mais lento** que a CPU |
| E — API local | ✅ testada em runtime (Linux/CPU) |
| F — licenças | ✅ executada |
| G — integração | ✅ análise, sem implementação |

---

## Os três achados que decidem a questão

1. **O caminho Vulkan/AMD funciona, não fala português e é mais lento que a
   CPU.** `audio.cpp` + Breeze-TTS-2 tem build Vulkan para Windows, o app o fixa
   com SHA-256 e a RX 580 é enumerada (`Vulkan:0`). Mas `supported_languages ==
   ["en","zh"]` e, medido no mesmo modelo, o RTF é 7,74 na GPU contra 6,33 na
   CPU — **22% mais devagar**.

2. **No Windows com Radeon, tudo que fala português roda em CPU.** PyTorch no
   Windows é CUDA-only; ROCm é Linux-only; DirectML não é viável.

3. **O motor com melhor português tem a licença mais restritiva.** OmniVoice traz
   clone e design em pt-BR, com pesos **CC-BY-NC** — e um segundo portão de
   licença no tokenizador (`NOASSERTION`).

---

## Regras deste repositório

- Nenhum commit no repositório oficial do VoiceStudio.
- Nenhuma gravação pessoal enviada a serviço externo.
- Nenhuma voz de terceiro sem consentimento.
- Números ausentes nos relatórios estão ausentes **porque não foram medidos**.
  Onde não há medição, está escrito **NÃO TESTADO**.
