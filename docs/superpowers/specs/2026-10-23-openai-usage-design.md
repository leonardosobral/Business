# Consumo OpenAI por módulo

Pedido autorizado: implementar, testar e publicar o painel, mantendo todas as chaves atuais. Restrito a admins globais efetivos, sem contexto delegado/conta cliente.

## Resultado

`/administracao/consumo-openai/`, com abas Visão geral, Histórico e Cobertura e custos. Filtros de período, módulo, modelo e resultado; tokens de entrada/saída, leituras e escritas de cache, custo estimado em USD, evolução diária, cobertura de medição e histórico paginado. Links para os módulos de origem e para a cobrança oficial. Não exibir prompts, respostas, emails, nomes de usuários, credenciais ou cabeçalhos.

## Abordagem e decisões de implementação

- Somente consolidar tabelas antigas deixaria resumos, reescritas e falhas sem medição. Importar o faturamento oficial exigiria credencial administrativa nova, incompatível com manter apenas as chaves atuais, e continuaria sem separar chamadas que compartilham chave.
- Escolha técnica: observar as respostas HTTP de cada módulo sem modificar solicitações, modelos, credenciais, tentativas ou políticas. Guardar eventos mínimos em diário JSONL privado, fora das raízes web, com trava compartilhada e limite de tamanho por evento. Nenhuma migração ou concessão de banco é necessária. Falha da telemetria não pode interromper o processo monitorado.
- Recuperar o histórico disponível em AI-mails, Vicky, cache de geolocalização e auditorias de descrições/resumos. Identificar claramente origem e cobertura parcial; não tratar registros legados como quantidade exata de chamadas nem inventar tokens/custos ausentes. Separar legado e diário a partir da ativação para evitar duplicação.
- Tarifa versionada, documentada em 23/10/2026, com modelo, tier, faixa de contexto, cache read, write 30m/12h e output. Reasoning já faz parte do output e não será somado novamente. Tokens de cache já fazem parte do input. Modelo/tier/uso desconhecido tem custo desconhecido, nunca zero. Valores são estimativas de tokens, não fatura; armazenamento, áudio e ferramentas sem informações tarifáveis ficam explicitamente fora da soma.
- Manter o projeto existente, sem branch, commit, push, nova credencial, migração ou alteração de permissões existentes. Arquivos de outras frentes não entram na publicação. O menu compartilhado usa o baseline real de produção.

## Cobertura

Business: geolocalização/enriquecimento, reescritas/traduções, AI-mails e lote, Help Desk. Serviços vinculados: Vicky no RR; resumos, resumo semanal e áudio no News. Busca RAG e armazenamento têm cobertura declarada: pedidos sem contagem de tokens não são cobrados como geração nem apresentados como custo zero.

## Verificação e publicação

Testar cálculo, cache, ausência de uso, erros 429/timeout, privacidade, concorrência, filtros/datas, deduplicação, agregação e acesso. Fixtures nativas ColdFusion e consultas legadas somente leitura; sem geração paga. Conferir hashes do servidor, manter backup recuperável, aplicar somente escopo com comparação antes de cada troca, validar rotas e interface autenticada e preservar hashes de guardas. Não declarar coleta de um módulo publicada sem verificar o wrapper real desse módulo.
