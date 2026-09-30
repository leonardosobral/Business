# Recursos na fila e limpeza única — 29/09/2026

Pedido: identificar o recurso na coluna Problema, principalmente para 404, e reduzir o histórico antigo. O usuário confirmou limpar somente o acompanhamento, mantendo os logs originais, com corte em 26/09/2026 00:00 America/Sao_Paulo.

## Listagem publicada

ErrorTriage.list busca a ocorrência mais recente de cada um dos até 25 problemas da página, com LEFT JOIN LATERAL usando o índice por problema/data. Recupera o caminho original por ErrorNormalizer.evidence, preservando o resumo armazenado quando não há original. workspace.cfm exibe Recurso abaixo do título; caminhos maiores que 180 caracteres mostram o final, com caminho completo no atributo title. Todo conteúdo e atributo passa por encodeForHTML. Títulos, assinaturas, categorias, estados e agrupamentos não mudam.

Baseline dos dois arquivos igual entre local e produção. Backup em /var/backups/business-error-triage-resources-20260929/baseline. Compilação 2/2, 74 asserções CFML e seis verificações de autorização/CSRF passaram. Hashes publicados conferidos. Navegador autenticado confirmou caminhos de imagens e sondagens na fila real. Capturas em _codex/staging/error-triage-resources. Teste em 390px encontrou sobreposição do menu global; validação visual móvel ficou limitada por esse comportamento do shell, que não foi alterado nesta tarefa. Override de viewport restaurado.

## Limpeza executada uma única vez

Removidos 3.998 problemas com last_seen anterior ao corte, suas 4.921 ocorrências vinculadas e 3.998 registros de histórico. Permaneceram 1.070 problemas, incluindo seus históricos completos. Nenhum UPDATE/DELETE foi executado em tb_log. Problemas com recorrências recentes não foram removidos nem marcados como resolvidos.

Backup completo JSON, manifesto e restore.sql em /var/backups/business-error-triage-cleanup-20260929 (diretório restrito). Reconstrução dos registros com os tipos reais das tabelas validada antes de aplicar. Transação com lock_timeout, bloqueio do coletor/tabelas de acompanhamento, checksum estável da seleção e verificação adicional de ausência de ocorrências recentes nos candidatos. Abortaria diante de alteração concorrente. Confirmação posterior: zero problemas anteriores ao corte e 1.070 mantidos. Os 4.921 IDs de logs originais continuam presentes.

O corte do coletor permanece 26/09/2026 22:39:58, posterior ao da limpeza; os itens removidos não serão reimportados pelo coletor atual. Por isso a redução afeta Todo o histórico já processado; o recorte padrão já excluía esses problemas. A limpeza não é recorrente. Na conferência da interface havia 628 logs recentes aguardando coleta; não foram coletados nesta tarefa.

## Recuperação

Arquivos: deploy_error_triage_resources.py rollback, com proteção de hash contra mudanças posteriores. Dados: revisar concorrência antes de executar o restore.sql transacional; insere problemas, ocorrências e histórico por IDs originais, falhando em caso de conflito, sem alterar os logs e sem retroceder sequências. Não restaurar todo o banco nem substituir problemas atuais. cleanup_error_triage_once.py apply recusa segunda aplicação e verify é somente leitura.
