# Agrupamento por assinatura técnica — 04/10/2026

## Causa e correção

O normalizador legado exigia mensagem técnica reconhecida e caminho sem entidades HTML. Logs atuais do ErrorReporter trazem mensagem genérica, TEMPLATE codificado e FINGERPRINT estável. O fallback usava o ID do log, criando um problema por ocorrência apesar da assinatura original igual. Os IDs 20672/20673/20674 compartilham fingerprint, tipo, ambiente e template; 20675/19856/14656 também compartilham outro fingerprint.

ErrorNormalizer agora usa identidade reporter-v1 quando FINGERPRINT é hexadecimal de 64 caracteres e ambiente, tipo e template são válidos. Identidade inclui site, ambiente, tipo, caminho completo decodificado e fingerprint. Mensagem genérica e HTML codificado não impedem agrupamento. Falhas distintas no mesmo arquivo permanecem separadas. O algoritmo legado permanece para logs sem fingerprint válido; dados ambíguos continuam individuais.

## Consolidação dos dados existentes

ErrorTriage.regroupFingerprints oferece prévia e aplicação vinculada ao hash da prévia, sob transação com bloqueio do coletor e dos problemas. Consolida somente grupos com assinatura inequívoca em todas as ocorrências e sem trabalho humano: status novo, sem responsável, publicação, notas, título personalizado ou ações manuais no histórico. Grupos com membro protegido são preservados integralmente.

Destino é o menor ID elegível, ou o proprietário existente da assinatura. IDs de duplicatas continuam existindo: ficam sem ocorrências, com status ignorado e histórico indicando o destino. Nenhum problema, histórico ou log foi apagado. A fila omite somente IDs vazios com ação regrouped_out; a consulta direta por ID permanece disponível. Datas históricas dos IDs de origem são preservadas; o destino é recontado pelas ocorrências. Próximas coletas usam a mesma assinatura do destino.

Resultado aplicado: 365 ocorrências em 365 IDs foram normalizadas para 18 grupos; 347 duplicatas saíram da fila. Outros 21 problemas ficaram separados. Total padrão confirmado: 386 → 39. Exemplos: #11077 collect.cfm, 80 ocorrências; #14353 evento/index.cfm, 10; #14670 timer/index.cfm, 174. Nenhum desses grupos foi marcado como corrigido por esta operação.

## Validação e publicação

- Reproduzida falha de agrupamento antes da correção em fixture com mensagem genérica, TEMPLATE codificado e fingerprint.
- 93 assertivas CFML e 6 guardas de acesso passaram em aplicação temporária e schema isolado, removidos ao final.
- Testes cobrem separação por assinatura/site/ambiente, fingerprint inválido, prévia sem escrita, plano obsoleto, retenção de IDs/histórico/logs, trabalho humano preservado, idempotência e próxima coleta no grupo consolidado.
- Dois componentes compilados e hashes verificados em produção.
- Verificação após operação confirmou as 365 ocorrências, seus logs originais e os 365 IDs; nenhuma consolidação elegível restante.
- Conferência no Chrome confirmou 39 problemas e contagens dos três exemplos.

Arquivos runtime: portal/erros/includes/ErrorNormalizer.cfc e ErrorTriage.cfc. Sem alteração no RoadRunners/OpenResults nesta rodada; sem commit/push.

## Backup e recuperação

Servidor: /var/backups/business-error-grouping-20261004/ contém baseline dos componentes, manifest, prévia completa, resultado aplicado e triage-before-regroup.json (snapshot consistente das quatro tabelas, permissão 0600). Snapshot não inclui o conteúdo dos logs originais, que não foram alterados.

Ferramentas: deploy_error_grouping.py business {verify,rollback}; regroup_error_fingerprints.py {preview,apply,verify}. A aplicação recusa sobrescrever o snapshot ou repetir uma operação aplicada. Recibos locais: _codex/staging/error-grouping-20261004/.

Rollback de arquivos não desfaz os vínculos de dados. Para desfazer dados, usar exclusivamente os IDs e id_log do plano aplicado e os valores originais do snapshot, conferir versões e ocorrências posteriores antes de restaurar os vínculos, recompor contagens e registrar a reversão no histórico. Não restaurar tabelas inteiras sobre alterações posteriores nem remover os logs originais.
