# Coleta recente de erros — 28/09/2026

## Diagnóstico confirmado

A coleta partia de 19/09/2026 21:40:47 e consumia IDs crescentes. Já havia 9.800 ocorrências vinculadas a 4.561 problemas, mas a última data alcançada era 22/09. Um novo clique reproduziu o erro genérico sem progresso. A normalização somente leitura do próximo lote identificou o log 45308546: o caminho sanitizado crescia para 560 caracteres, excedendo varchar(320) de tb_error_occurrence.path e desfazendo o lote inteiro. Teste sintético com segmentos curtos reproduziu a falha antes da correção.

## Correção

O caminho exibido é limitado a 320 caracteres após sanitização; a assinatura continua usando a identidade completa, sem juntar problemas por truncamento. A coleta busca ocorrências por log_timestamp DESC e id_log DESC, mantendo limite de 200, bloqueio transacional, idempotência e reconciliação de commits tardios. O painel mostra a quantidade de logs aguardando coleta no recorte. O filtro padrão restringe problemas por última ocorrência a partir do marcador do coletor; Todo o histórico já processado mantém acesso aos problemas antigos, inclusive por URL direta. Contagens por problema continuam incluindo ocorrências históricas; isso está explicado na interface.

O marcador foi avançado para 26/09/2026 22:39:58, America/Sao_Paulo, imediatamente após o recibo do deploy real do handler (27/09/2026 01:39:57.720 UTC). Nenhum log, ocorrência, problema ou histórico foi apagado ou marcado como resolvido. Não há alteração de schema.

## Publicação e validação

Quatro arquivos: ErrorNormalizer.cfc, ErrorTriage.cfc, init.cfm, workspace.cfm. Baseline de produção conferido; backup em /var/backups/business-error-triage-recent-20260928/baseline. Backup do marcador em collector-before.json no mesmo diretório pai; cutoff-applied.json registra aplicação. Runtime compilado (4/4), testes CFML com regressão de caminho, prioridade por data, filtro de histórico, pendências e exclusão do período anterior. Recibos em _codex/staging/error-triage-recent.

A coleta real foi executada pela interface autenticada, em 12 lotes: 2.279 ocorrências processadas; zero pendências na leitura final. Houve uma ocorrência nova durante a execução. O recorte resultou em 832 problemas, com histórico anterior acessível (4.918 problemas no total). Importação concluída não significa correção dos problemas. Novos logs continuam chegando e podem aumentar o contador após essa conferência.

## Recuperação

O publicador deploy_error_triage_recent.py rollback restaura apenas os quatro arquivos quando seus hashes não sofreram alterações posteriores. Para voltar ao recorte antigo, restaurar somente started_at com o valor de collector-before.json, verificando antes que o marcador ainda seja 2026-09-26 22:39:58. Não restaurar last_id/upper_id nem apagar ocorrências coletadas: são idempotentes e devem permanecer. O backup do marcador contém precisão de microssegundos.
