# VoiceStudio Lab — relatórios

Avaliação técnica independente do [VoiceStudio](https://github.com/debpalash/VoiceStudio)
como possível provedor local de voz para a Lia, em português brasileiro.

**Versão avaliada:** `main` @ `48e85106eb00a69c9beea3bdbf0a23692c7aa8ca`
(estável de referência: **v0.5.6**) · **Data:** 2026-10-23

---

## Leia nesta ordem

| # | Arquivo | O que responde |
|---|---|---|
| 1 | [`executive-summary.md`](executive-summary.md) | Conclusão, classificação e recomendação |
| 2 | [`environment.md`](environment.md) | Hardware, versões e **por que o ambiente não é o alvo** |
| 3 | [`test-matrix.md`](test-matrix.md) | 16 configurações, corpus, procedimentos, status de cada fase |
| 4 | [`licensing.md`](licensing.md) | AGPL, CC-BY-NC, e as dúvidas que exigem advogado |
| 5 | [`integration-proposal.md`](integration-proposal.md) | Arquitetura futura — **sem implementação** |
| 6 | [`installation-plan.md`](installation-plan.md) | Plano de instalação **aguardando autorização** |

## Pastas

- **`corpus/`** — 10 frases fixas em pt-BR + SHA-256 de cada texto, para que
  toda comparação futura use exatamente o mesmo insumo.
- **`evidence/`** — extrações brutas e reprodutíveis que sustentam as
  afirmações: ambiente, versão, motores/idiomas, superfície de API, licenças,
  verificação do `audio.cpp`/Vulkan.

---

## Três regras que valem para tudo aqui

**1. Houve áudio; não houve escuta.** O `run-lab.bat` gerou 10 frases em
português na máquina-alvo, e elas foram analisadas por sinal (F0, silêncio,
clipping — ver `test-matrix.md` §4.4). O que **não** houve foi **ouvido humano**:
nenhuma nota de naturalidade, sotaque ou pronúncia é dada aqui. Todo número
ausente está marcado como **NÃO TESTADO**, com o procedimento de validação.

**2. O agente e a máquina-alvo são lugares diferentes.** O laboratório do
agente é Linux headless, sem GPU e sem `J:`. Por isso a coleta foi invertida: um
único `run-lab.bat` roda na máquina Windows do operador e traz as medições de
volta. O que é **medido** está em `evidence/windows/`; o que vem de documentação
e código-fonte está marcado como **inspecionado**.

**3. A API foi testada duas vezes, em dois lugares.** No agente (Linux/CPU) o
backend subiu e respondeu por HTTP — contrato, códigos de erro, gate de licença e
isolamento de rede. Na máquina do operador a mesma API **gerou os WAVs**. Os
detalhes estão em [`evidence/runtime/`](evidence/runtime/README.md) e em
`evidence/windows/`.

---

## Os três achados que decidem a questão

1. **O caminho Vulkan/AMD funciona — mas só fala inglês e chinês.**
   `audio.cpp` + Breeze-TTS-2 tem build Vulkan para Windows, e o VoiceStudio o
   fixa com SHA-256. Mas `supported_languages == ["en","zh"]`.

2. **No Windows com Radeon, tudo que fala português roda em CPU.**
   PyTorch no Windows é CUDA-only ou CPU-only; ROCm é Linux-only; DirectML não
   é viável. Não há configuração que contorne isso.

3. **O motor com melhor português é o de licença mais restritiva.**
   OmniVoice traz clone e design em pt-BR, mas os pesos são **CC-BY-NC** e o
   projeto registra `commercial_outputs: unknown`.

---

## O que fazer a seguir

Executar as Fases B–D na máquina real e ouvir o corpus.

Na raiz do repositório existe **`run-lab.bat`**: ele instala o app, baixa o
modelo, coleta hardware, API e áudio do corpus, escreve o resumo e envia ao git. Instruções em
[`../tools/README.md`](../tools/README.md).

Depois de ouvir as amostras, preencha a grade de avaliação de
`test-matrix.md` §4.2.

Só depois disso faz sentido escrever qualquer código de integração.
