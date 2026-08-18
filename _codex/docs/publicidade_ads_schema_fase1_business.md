# Publicidade: chaveamento do Business para o schema `ads`

Atualizado em: 2026-08-17

Status: migration da Fase 1 aplicada em produção em 2026-07-12 e Business
chaveado para `ads.*`. O refresh e o job estão ativos. Em 2026-08-17 foi
preparado o chaveamento explícito de todos os fluxos Ads para o datasource CFML
`runnerhub`, autenticado no PostgreSQL como `runner`; o script idempotente de
grants deve ser executado antes desse deploy.

O roadmap único do domínio está em
[publicidade_ads_plano_mestre.md](../../../RoadRunners/_codex/docs/publicidade_ads_plano_mestre.md). Este documento mantém
somente o inventário e o registro operacional do Business.

## 1. Escopo

O Business passou a acessar diretamente os objetos canônicos `ads.*` no PostgreSQL principal. As views temporárias homônimas em `public` continuam sendo responsabilidade da migration da Fase 1 e não são removidas por este projeto.

Banco dedicado, AWS separada, fila assíncrona e FDW não fazem parte do rollout
atual. Só serão considerados se volume, latência ou operação justificarem sair
do schema `ads` no PostgreSQL principal.

## 2. Inventário final

| Objetos | Consumidores ou definições encontrados no Business |
| --- | --- |
| `ads.tb_ad_eventos` | `ads/includes/backend.cfm`, `api/ads/conversion-click.cfm`, `cupons-rr/includes/backend.cfm`, `inscricoes/includes/backend.cfm`, `includes/estrutura/home_admin_dashboard.cfm`, `includes/estrutura/home_conta_dashboard.cfm`, `_legado/usuarios/includes/backend.cfm`, incremental de métricas e `_codex/sql/ddl.sql` |
| `ads.tb_ad_vouchers` | `ads/includes/backend.cfm`, `administracao/contas/includes/backend.cfm`, `includes/estrutura/home_conta_dashboard.cfm`, incremental de vouchers e `_codex/sql/ddl.sql` |
| `ads.tb_ad_log` | `ads/includes/backend.cfm`, incremental de métricas e `_codex/sql/ddl.sql` |
| `ads.tb_ad_evento_metricas_dia` | `ads/includes/backend.cfm` e `_codex/sql/2026-06-27_tb_ad_evento_metricas_dia.sql` |
| `ads.tb_ad_conversion_log` | `ads/includes/backend.cfm`, `api/ads/conversion-click.cfm` e `_codex/sql/2026-06-27_tb_ad_conversion_log.sql` |
| `ads.click_nonce`, `ads.click_rate_limit`, `ads.clicks`, `ads.pings`, `ads.ping_nonce`, `ads.click_audit`, `ads.impressions` | somente a fotografia `_codex/sql/ddl.sql`; não foi localizado consumidor de runtime dessas tabelas no Business |
| `ads.tb_portal_banners`, `ads.tb_portal_banners_log` | `portal/includes/banner_management_backend.cfm`, `api/portal/banners/index.cfm`, `api/portal/banners/click.cfm`, `portal/banners/portal_banner_schema.sql` e `_codex/sql/ddl.sql` |

Ocorrências de `clicks` em templates, aliases, CTEs, colunas de métricas e labels são métricas, não referências à tabela técnica `ads.clicks`, e foram preservadas.

Documentos antigos que citam nomes lógicos sem schema são descritivos e não contêm SQL executável.

## 3. Arquivos alterados

### Runtime e legado

- `ads/includes/backend.cfm`
- `ads/includes/form_campanha.cfm`
- `api/ads/conversion-click.cfm`
- `api/ads/refresh-metrics.cfm`
- `administracao/contas/includes/backend.cfm`
- `cupons-rr/includes/backend.cfm`
- `inscricoes/includes/backend.cfm`
- `includes/estrutura/home_admin_dashboard.cfm`
- `includes/estrutura/home_conta_dashboard.cfm`
- `portal/includes/banner_management_backend.cfm`
- `api/portal/banners/index.cfm`
- `api/portal/banners/click.cfm`
- `portal/banners/home.cfm`
- `_legado/usuarios/includes/backend.cfm`

### DDL e incrementais

- `_codex/sql/2026-06-14_tb_ad_vouchers_contas.sql`
- `_codex/sql/2026-06-27_tb_ad_evento_metricas_dia.sql`
- `_codex/sql/2026-06-27_tb_ad_conversion_log.sql`
- `_codex/sql/ddl.sql`
- `portal/banners/portal_banner_schema.sql`
- `administracao/cron-jobs/ads_metrics_refresh_job.sql`

Uma alteração local preexistente em `administracao/contas/home.cfm` foi mantida intacta e não pertence a este chaveamento.

## 4. Alterações realizadas

- `SELECT`, `JOIN`, `INSERT`, `UPDATE` e `DELETE` dos objetos de publicidade agora usam `ads.*`.
- Não foi localizado SQL dinâmico de publicidade no runtime do Business; a função SQL de agregação encontrada foi qualificada no schema `ads`.
- Relações cruzadas relevantes foram mantidas em `public`, com qualificação explícita nos pontos alterados, incluindo eventos, contas, vínculos de conta e usuários.
- A FK inversa permanece definida como `public.tb_conta_cadastro_solicitacoes.id_ad_voucher -> ads.tb_ad_vouchers.id_ad_voucher`.
- Referências diretas a sequences passaram a usar `ads.*`.
- A fotografia `_codex/sql/ddl.sql`, atualizada a partir do banco em 2026-07-26, confirma as 14 tabelas em `ads`, as 14 views em `public`, a FK de voucher e a função de refresh. Ela é snapshot de auditoria, não migration executável.
- O SQL standalone de banners cria tabelas e índices em `ads`.
- Nenhuma view de compatibilidade em `public` foi removida ou redefinida.
- Todas as queries de Ads do Business usam explicitamente o datasource
  `runnerhub`; blocos `cftransaction` que incluem uma tabela Ads usam o mesmo
  datasource em todas as queries da transação.
- A exclusão física de banner foi substituída por arquivamento (`status = 4`),
  preservando o registro, os logs e os arquivos associados.
- O endpoint `/api/ads/refresh-metrics.cfm` executa uma janela móvel limitada, exige credencial interna e usa advisory lock transacional.
- O cadastro do cron cria o job inativo, a cada 60 minutos, para teste manual antes da ativação.
- A migration do RoadRunners que cria o índice concorrente em `ads.tb_ad_log(data_insercao)` e torna o filtro da função indexável foi aplicada e auditada em 2026-07-26.

## 5. `information_schema` corrigido

- `ads/includes/backend.cfm`: métricas diárias, conversões e colunas de vouchers são procuradas em `table_schema = 'ads'`.
- `api/ads/conversion-click.cfm`: objetos de ads são procurados em `ads`, enquanto eventos e vínculos continuam em `public`.
- `administracao/contas/includes/backend.cfm`: vouchers são procurados em `ads`; contas e solicitações continuam em `public`.
- `includes/estrutura/home_admin_dashboard.cfm`: `tb_ad_eventos` é procurada em `ads`; as demais tabelas do dashboard continuam em `public`.
- `includes/estrutura/home_conta_dashboard.cfm`: colunas de vouchers são procuradas em `ads`.
- Backend e APIs de banners procuram as duas tabelas em `ads`.

`current_schema()` não é mais usado para descobrir qualquer objeto de publicidade. Usos restantes no repositório pertencem a módulos não relacionados a ads.

## 6. Incrementais corrigidos

- O incremental de vouchers altera somente `ads.tb_ad_vouchers`, qualifica sua sequence e mantém as FKs para `public.tb_contas` e `public.tb_usuarios`.
- O mesmo incremental mantém a tabela de solicitações em `public` e sua FK apontando para `ads.tb_ad_vouchers`.
- O incremental de métricas cria e alimenta `ads.tb_ad_evento_metricas_dia`, lê `ads.tb_ad_log` e `ads.tb_ad_eventos`, junta `public.tb_conta_eventos` e define `ads.refresh_tb_ad_evento_metricas_dia`.
- O incremental de conversões cria tabela, índices e sequence em `ads`.
- Nenhum desses incrementais cria novamente uma tabela de publicidade em `public`. Se a migration do schema ainda não tiver sido aplicada, eles devem falhar em vez de criar um objeto paralelo no schema errado.

## 7. Datasource e permissões

- O datasource padrão histórico do Business continua com o nome
  `runner_dba`, mas nenhum fluxo Ads depende mais dele.
- As queries Ads usam explicitamente o datasource `runnerhub`, cuja credencial
  PostgreSQL operacional é `runner`.
- Antes do deploy, executar como DBA o script idempotente
  `RoadRunners/_codex/sql/2026-08-17_ads_runner_runtime_grants.sql`.
- O script concede `USAGE` no schema, privilégios mínimos por tabela,
  sequences owned pelas tabelas legadas, execução do refresh e, quando a V1 já
  existir, memberships `ads_reader` e `ads_delivery`.
- O script não concede `CREATE`, ownership, administração/finanças V1 nem
  `DELETE`. Banners são arquivados por `UPDATE status = 4`.
- `runner_dba` e `ads_dba` permanecem DBAs administrativos fora das
  credenciais PostgreSQL usadas pelo CFML.

## 8. Validações estáticas

- busca completa, case-insensitive, pelos 14 nomes de tabela em CFML, SQL, documentação e legado;
- auditoria por contexto SQL para `FROM`, `JOIN`, `INSERT INTO`, `UPDATE`, `DELETE FROM`, `CREATE TABLE`, `ALTER TABLE` e `REFERENCES` sem `ads.`;
- auditoria separada de sequences, casts `regclass`, `information_schema` e `current_schema()`;
- revisão manual das ocorrências de `clicks` para separar tabela de coluna, alias e label;
- `git diff --check` dos arquivos desta entrega sem erros de whitespace; o diff
  global continua apontando apenas uma linha vazia no fim do snapshot
  `_codex/sql/ddl.sql` atualizado pelo usuário;
- revisão do datasource padrão e de overrides nos consumidores alterados.
- revisão estática do endpoint e do cadastro idempotente do cron;
- conferência do snapshot atualizado do banco para tabelas, views, FK e funções.
- auditoria do hardening em produção: índice válido e pronto com owner
  `runner_dba`; função com owner `runner_dba`, execução de `runner`, advisory
  lock e limites de timestamp confirmados;
- `EXPLAIN` confirmando `Index Scan` por
  `ads.idx_tb_ad_log_data_insercao`;
- checkpoint antes do refresh manual: origem em
  `2026-07-26 22:07:04.015491`, agregado até `2026-07-25`, atualizado em
  `2026-07-26 02:13:23.860406`;
- `RoadRunners/_codex/scripts/audit_ads_phase1_static.sh` executado com resultado
  `APROVADA` para os dois repositórios;
- o scanner de blocos `cfquery` confirmou `runnerhub` em todas as queries Ads e
  ausência de `runner_dba` no runtime do domínio;
- chamada sem token ao runner de produção retornou HTTP 401, confirmando que o
  endpoint está ativo e protegido sem disparar jobs.
- smoke test externo do endpoint publicado: `GET` retornou HTTP 405 com
  `Allow: POST` e `POST` sem credencial retornou HTTP 401, sem executar refresh.
- cadastro idempotente executado em produção: job `9`,
  `Business - Metricas de publicidade`, inativo, intervalo de 60 minutos.
- execução manual em `2026-07-26 22:29:24`: status `success`, HTTP 200, duração
  total de 88 ms e resposta `status = refreshed`;
- janela recalculada de `2026-07-24` a `2026-07-26`: 3 linhas, 21.554 views,
  141 clicks e custo 141;
- freshness após o refresh: origem em `2026-07-26 22:29:04`, agregado até
  `2026-07-26`, atualizado em `2026-07-26 22:29:24`.

O repositório não oferece linter ou suíte automatizada de CFML. O endpoint e o
job preparados em 2026-07-26 foram executados de forma autenticada contra
PostgreSQL com sucesso; o job está ativo.

## 9. Dependências e consumidores ainda não resolvidos

- A primeira execução com trigger `scheduled` ainda precisa ser conferida no
  histórico.
- Jobs, BI, integrações, funções do banco e scripts manuais externos aos dois repositórios precisam ser observados com a auditoria SQL e `pg_stat_statements` após o deploy.
- A atividade da rota `_legado/usuarios/` continua incerta; seu SQL foi qualificado para evitar regressão caso volte a ser chamado.
- As views temporárias `public.*` devem permanecer durante uma janela que cubra tráfego, rotinas diárias, semanais e mensais.
- A remoção das views e do wrapper temporário de função é trabalho futuro.
  Banco dedicado, AWS separada, FDW ou fila só serão considerados mediante
  evidência de capacidade insuficiente no banco principal.

## 10. Riscos e ordem coordenada de deploy

O principal risco atual é deixar o agregado diário sem agendamento ou remover as
views enquanto elas ainda mascaram consumidores regressivos. A Ads V1 canônica
continua em `NO-GO` e não faz parte deste deploy.

Ordem histórica concluída:

1. ~~deploy da correção do RoadRunners~~ — concluído em 2026-07-26;
2. ~~migration e auditoria de endurecimento do refresh~~ — concluídas em
   2026-07-26;
3. ~~deploy do endpoint do Business~~ — concluído e validado em 2026-07-26;
4. ~~execução do SQL de cadastro do job~~ — job `9` cadastrado inativo em
   2026-07-26;
5. ~~smoke test manual no gerenciador de cron~~ — HTTP 200 e
   `status = refreshed` em 2026-07-26;
6. ativação concluída; confirmação da primeira execução agendada pendente;
7. observação de tráfego, jobs, BI, integrações, ACLs e `pg_stat_statements`;
8. remoção futura das views somente por migration separada.

Ordem do chaveamento de datasource preparado em 2026-08-17:

1. executar em `dev`/ambiente alvo
   `2026-08-17_ads_runner_runtime_grants.sql` como DBA;
2. conferir `grants_report.status = PASS`;
3. publicar os arquivos Ads do RoadRunners;
4. publicar os arquivos Ads do Business;
5. reciclar as aplicações/pools CFML se necessário;
6. executar smoke tests de seleção, render, view, click, ping, conversão,
   voucher, dashboard, refresh e banners;
7. observar erros de permissão e métricas antes de avançar com a V1 canônica.
