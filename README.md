<h1 align="center">Lia Voice Studio · Laboratório</h1>

<p align="center">
  <strong>Pesquisa prática de síntese de voz para a Lia.</strong><br>
  Testes de qualidade, desempenho, idiomas e licenças antes de decidir quais motores de voz merecem integração ao ecossistema.
</p>

> **Repositório de laboratório, não aplicativo final.** Aqui ficam scripts de ensaio, resultados e análises do [VoiceStudio](https://github.com/debpalash/VoiceStudio). Nenhuma integração com o Lia Desktop é fornecida por este projeto.

## Por que existe

Uma voz convincente precisa funcionar na máquina de destino, falar o idioma desejado, responder em tempo útil e permitir o uso pretendido pela licença. O Lia Voice Studio organiza essa verificação com evidências, em vez de escolher um motor somente por demonstrações ou promessas.

## O que foi avaliado

| Frente | Resultado do laboratório |
| --- | --- |
| **Português brasileiro** | Amostras de voz e análise acústica; a aprovação perceptiva por ouvinte humano permanece pendente. |
| **Processamento local** | Testes de CPU e análise de caminhos AMD/Vulkan. |
| **API** | Ensaio de backend local em Linux/CPU, separado de integração com a Lia. |
| **Licenciamento** | Matriz de dependências, pesos e condições de uso, incluindo restrições não comerciais. |
| **Windows** | Coletas com logs e resumos, sem transformar um ensaio em garantia de compatibilidade geral. |

Um resultado importante foi que, **na medição pareada do laboratório**, a RX 580 usando Vulkan ficou cerca de **22% mais lenta** que a CPU para o motor testado, e o caminho Vulkan em questão não oferecia português. Esse número pertence ao conjunto, versão e máquina ensaiados; não é uma afirmação geral sobre toda GPU AMD.

## Leia os resultados

- [Resumo executivo](lab/reports/executive-summary.md)
- [Matriz de ensaios](lab/reports/test-matrix.md)
- [Ambiente e limitações](lab/reports/environment.md)
- [Licenças e direitos](lab/reports/licensing.md)
- [Proposta de integração, ainda não implementada](lab/reports/integration-proposal.md)
- [Índice de evidências](lab/reports/README.md)

## Reproduzir no Windows

O script de laboratório está disponível:

```bat
run-lab.bat
```

**Não execute sem revisar o procedimento.** Ele pode instalar software, baixar modelos, gerar áudio e publicar um relatório resumido no GitHub após autorização. O modo `/gpu` mede o caminho de GPU quando configurado. Consulte antes o [guia do script](lab/tools/README.md), as licenças e as condições de cada modelo.

Não use gravações pessoais nem a voz de terceiros sem autorização. O laboratório não concede licença para distribuir pesos de terceiros dentro da Lia.

## Relação com a Lia

Este trabalho informa decisões sobre voz para a [Lia Desktop](https://github.com/BloomRX/Lia-Project), mas não substitui os motores já implementados nem instala um provedor no aplicativo. Pesquisa, implementação e aprovação de distribuição são etapas distintas.

Contribuidores e agentes devem seguir [`AGENTS.md`](AGENTS.md) e os [padrões de marca](docs/BRAND-STANDARDS.md). Os números e limites devem ser lidos diretamente das evidências originais.
