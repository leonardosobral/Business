# Fila por evento — publicação 14/09/2026

Publicado no Business, sem alteração do contrato público da API e sem migração.

## Pacote

- `services/queries/.htaccess`
- `services/queries/result_import_context.sql`
- `services/queries/result_import_archive.sql`
- `services/ResultImportQueueService.cfc`
- `racetag/includes/backend.cfm`
- `racetag/form.cfm`
- `assets/js/result-import-queue.js`
- `administracao/importacoes-resultados/includes/backend.cfm`
- `administracao/importacoes-resultados/home.cfm`

Backup recuperável e pacote imutável:
`/var/backups/business-result-import-groups.fcbeb8a78e44`.

Recibos de preparação, instalação e verificação:
`2026-09-14_result_import_groups_release_v2{,-publish,-verify}.json`.
O pacote inicial `business-result-import-groups.b36d4d4d3a20` foi somente preparado,
nunca instalado. A publicação final usa exclusivamente a versão v2 revisada.

## Verificações executadas

- PostgreSQL temporário: identidade por cliente/timer/conta, chamada de 10:44
  versus 10:46, desempate por ID, arquivo idempotente, URLs genéricas com IDs
  externos diferentes, ambiguidade de catálogo e isolamento do backlog.
- CFML/Lucee + PostgreSQL: serviço real, filtros após seleção da última chamada,
  paginação, integração inativa, intenção false, pré-seleção no backend real,
  bloqueio de chamada antiga, mesma fonte e rollback do arquivamento.
- Regressão Node: **24/24** testes da fila/intenção RaceTag.
- Adobe ColdFusion no servidor: **5/5** fontes CFML compiladas.
- Render com dados controlados em navegador: desktop 1440 e mobile 390, sem
  overflow horizontal da página; tabela mantém seu scroll interno no mobile.
- Pós-publicação: hashes/metadados dos nove arquivos e backups conferidos;
  118 arquivos/inventários protegidos preservados pelo publicador.
- JavaScript servido por HTTPS coincide com o arquivo validado.
- SQL via HTTPS responde **403**; fila e importador anônimos respondem **302**
  para a entrada do Business, mantendo a exigência de autenticação.

A sessão disponível no navegador estava deslogada. Não foi possível conferir
as contagens reais autenticadas; nenhum resultado real foi processado nem
submissão real descartada para a validação. A classificação do backlog ocorre
somente na leitura; alterações persistentes futuras usam o POST autorizado.

## Recuperação

`python3 _codex/scripts/deploy_result_import_groups.py rollback 2026-09-14_result_import_groups_release_v2.json`

O rollback verifica hashes antes de restaurar. Restaura somente os arquivos;
não desfaz importações executadas por operadores nem seus arquivamentos futuros.
