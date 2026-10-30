# LiaVoiceStudio — instruções para agentes

Este repositório é um laboratório de avaliação de tecnologia de voz para a Lia. Consulte `docs/BRAND-STANDARDS.md` para os princípios comuns de marca e preserve o caráter de pesquisa independente.

## Limites de execução e consentimento

- **Não execute `run-lab.bat` automaticamente.** O script pode instalar VoiceStudio, instalar dependências, baixar modelos, gerar áudio, gravar evidências, fazer commit e push.
- Antes de executar, apresentar comandos/efeitos, versões e URLs, volume dos downloads, licenças, recursos de hardware, chamadas externas, custos/cotas possíveis e exatamente o que será enviado ao GitHub.
- Exigir autorização explícita para cada operação com custo, instalação, download grande, geração de áudio, gravação de dados ou push. A autorização para uma ação não autoriza as demais.
- Não aceitar licenças nem enviar gravações, amostras humanas, prompts privados ou dados pessoais para fora sem autorização específica e proveniência aprovada.
- Não transformar resultado acústico em nota de naturalidade. Qualidade subjetiva exige audição humana documentada. Separar CPU, GPU, Vulkan, runtime real e inferência simulada.
- Preservar evidências sanitizadas e o estado `PENDENTE/NOT-TESTED` quando o teste não ocorreu. Não editar resultados para fazer o relatório parecer verde.

## Relatórios e reprodutibilidade

Fixe versão/revision do upstream e hashes dos binários/modelos. Registre ambiente, hardware, comandos, custo e limitações. Não inclua tokens, chaves, áudio privado ou dados identificáveis em relatórios versionados.
