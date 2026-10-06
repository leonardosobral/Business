# Agrupamento de exceções antigas do OpenResults — 05/10/2026

## Causa e alteração

Os problemas 26292–26296 continham a mesma exceção CFML, mensagem de componente services.RunnerAppsMenuCache ausente, template menu_apps_data.cfm e linha 200. O formato antigo do OnError não possui FINGERPRINT. A regra anterior só reconhecia uma lista curta de mensagens/tipos e, quando não reconhecia, usava o ID do log como identidade. Assim cada ocorrência se tornava um problema.

ErrorNormalizer.cfc agora dispõe de identidade legacy-exception-v1 para exceções estruturadas completas sem fingerprint: site, tipo, caminho completo incluindo host, linha positiva, mensagem decodificada e normalizada em espaços, SQLSTATE quando presente e hash do detalhe. Diferenças de componente, linha, site, host ou detalhe permanecem separadas. Mensagem desconhecida não é executada nem interpretada como instrução. Título gerado contém categoria e nome do arquivo; evidência original continua disponível ao administrador. Fingerprints atuais e assinaturas técnicas anteriores mantêm o contrato. Evidências insuficientes e fingerprints malformados continuam individuais.

ErrorTriage.cfc permite consolidar também legacy_exception. A rotina exige uma prévia com hash, serializa com o coletor, preserva os logs e mantém os IDs antigos como registros de auditoria. Grupos com tratamento humano ou identidades divergentes não são consolidados automaticamente. Não foi feita migração de schema.

## Verificação e publicação

- Regressão reproduzida antes da implementação.
- 109 verificações CFML em esquema sintético isolado, mais seis proteções de acesso/CSRF, passaram. Incluem idempotência, plano desatualizado, histórico humano, logs originais e futuras coletas entrando no mesmo problema.
- Compilação e hashes publicados: dois arquivos conferidos.
- Produção: 842 ocorrências do menu consolidadas no problema 26292; outras duas em lista_de_eventos_simple.cfm consolidadas no problema 16040.
- Total de 844 ocorrências e seus logs originais preservados, 844 IDs de acompanhamento retidos para auditoria; 842 cartões duplicados saíram da fila.
- Fila padrão após operação: 44 problemas. Prévia posterior: zero grupos elegíveis restantes. 23 problemas não elegíveis foram preservados.
- Consulta dos logs originais encontrou a última ocorrência do componente ausente em 04/10/2026 às 23:31:29. A coleta estava trazendo ocorrências antigas. Logs ainda não coletados não foram apagados nem importados em massa; as próximas coletas usam a identidade corrigida.

Backup remoto: /var/backups/business-error-grouping-20261005/. Além do baseline de runtime, contém triage-before-regroup.json com o acompanhamento anterior e os planos aplicados. Dados de backup restritos ao servidor. Reversão de dados exige conferir alterações posteriores e restaurar os vínculos seletivamente; não restaurar snapshot completo sobre trabalho novo.

Artefatos locais: _codex/staging/error-grouping-20261005/. Ferramentas: deploy_error_grouping_legacy.py e regroup_legacy_errors.py. Nenhum commit/push executado.
