# Evidências completas para administradores — 28/09/2026

Pedido explícito: não omitir caminhos ou conteúdo na área de erros restrita a administradores.

## Alterações

- O resumo de ocorrências preserva o caminho real e a mensagem disponível. Limites de armazenamento (320/500) continuam evitando falhas de lote; não há alteração de schema.
- O detalhe faz LEFT JOIN das 25 ocorrências da página com tb_log por chave primária. Reconstrói caminho/mensagem dos registros originais na leitura, incluindo ocorrências antigas com /{omitido}. Sem regravar assinaturas, agrupamentos, status ou histórico.
- A aba Ocorrências oferece Log original como texto com HTML escapado. Nenhum conteúdo do log é executado como HTML.
- Exportação format_version=2 preserva título, análise, proposta, evidências e mensagem. Cada amostra inclui original_log e original_available. Mantém até 20 problemas e 25 amostras por problema.
- Quando o original já não existe, mantém o resumo antigo e informa sua indisponibilidade. Não é possível reconstruir informações que o produtor nunca gravou; o campo original_log contém exatamente o disponível em tb_log.
- A função de reconhecimento de mensagens continua servindo apenas à identidade de agrupamento, sem limitar a evidência administrativa.
- Login, require_admin, CSRF, attachment JSON e Cache-Control no-store permanecem no endpoint de exportação.

## Verificações e operação

Regressão RED/GREEN para mensagem não reconhecida, caminhos reais, notas e título preservados, recuperação de caminho previamente omitido, original com mais de 320 caracteres, HTML escapado e ausência do original. Suíte CFML isolada passou, incluindo verificações de acesso direto e CSRF. Compilação antes da publicação; conferência de hashes e problema #33 no runtime após publicar.

Backup seletivo: /var/backups/business-error-triage-admin-evidence-20260928/baseline. Publicador: _codex/scripts/deploy_error_triage_admin_evidence.py. Sem migração ou alteração destrutiva dos dados; a recuperação na leitura se aplica imediatamente às ocorrências já processadas. O rollback restaura os três arquivos com conferência de concorrência.
