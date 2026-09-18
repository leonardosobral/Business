# Cron 15 — lote de descrições

## Escopo e comportamento

Autorização: usuário aprovou processar até três etapas por execução, mantendo modelo e validações. Apenas Business alterado, sem migração ou alteração de credenciais.

Runtime publicado:
- `api/eventos/jobs/rewrite-descriptions.cfm`: aceita `limit` de 1 a 3, padrão 1; cada etapa tem seleção atualizada e transação própria; falhas não apagam resultados anteriores; pares evento/idioma não se repetem dentro do lote; prévia continua unitária; duração de cada etapa na resposta.
- `services/EventDescriptionRewriteService.cfc`: deadline opcional repassado às duas chamadas de IA, mantendo limite de 45 segundos por chamada. Lote com orçamento de 85 segundos, sem iniciar etapa quando restam menos de 10 segundos. Orçamento esgotado reverte apenas a etapa atual, sem consumir tentativa de retry.

Cadastro do job 15 salvo e confirmado na interface em 17/09/2026: body anterior `{"limit":1,"dryRun":false}`, novo `{"limit":3,"dryRun":false}`. Mantidos ativo, intervalo 1 minuto, timeout 120 segundos, retry 0 e máximo runtime 150 segundos. Agenda global não alterada.

## Validação

- Guardas do endpoint: 29 verificações aprovadas; o novo limite 3 foi observado falhando antes da implementação.
- Serviço CFML: 158 verificações aprovadas, incluindo recusa de chamada com deadline expirado, integridade factual e idiomas.
- Integração real Lucee + PostgreSQL 14: fluxos de reescrita, tradução, concorrência, rollback e lote aprovados. Novo lote validou três idiomas, rejeição intermediária sem bloquear o seguinte, rollback parcial sem perda do primeiro commit, interrupção por budget, prévia unitária e processamento de mais de uma prova.
- PostgreSQL local não iniciou por esgotamento de IDs de memória compartilhada do macOS. Alternativa: pacotes oficiais Ubuntu apenas extraídos em `/var/tmp/business-description-batch-test-20260917`, servidor temporário sem privilégios e restrito ao loopback, com dados sintéticos. Nenhum banco real foi acessado. Runtime/banco temporários e túnel removidos após testes.
- Compilação nativa Adobe ColdFusion: 2/2 aprovados fora do webroot.
- Revisão independente do diff sem problemas concretos.
- `git diff --check` aprovado no escopo.

## Publicação e rollback

Backup: `/var/backups/business-description-batch.747aefd63653`.
Recibos: `2026-09-17_event_description_batch.json`, `-publish.json`, `-verify.json`.
Publicação confirmou hashes/metadados de ambos os arquivos e 126 guardas de arquivos fora do escopo.

Rollback: primeiro retornar body do job 15 para `{"limit":1,"dryRun":false}` pela interface; depois executar `python3 _codex/scripts/deploy_event_description_batch.py rollback`. O rollback restaura apenas código e exige baseline compatível. Não reverte descrições já validadas e publicadas pelo fluxo normal.

## Verificação funcional pós-publicação

Histórico autenticado do cron 15, execução iniciada em **17/09/2026 09:07:12 BRT**, duração **25.461 ms**:
- evento 46530, espanhol: atualizado, 9.437 ms;
- evento 46532, português: atualizado, 8.282 ms;
- evento 46532, inglês: rejeitado por `validation_rejected`, 7.701 ms.

Resposta real: `selected=3`, `processed=3`, `updated=2`, `errors=1`, `skipped=0`. O status `failed` preserva a rejeição factual em um lote misto e não significa rollback das duas etapas já publicadas. Nenhum `execution_error` ou `provider_error` foi observado nessa execução. Confirmação via resposta completa do histórico; sem execução manual adicional.

