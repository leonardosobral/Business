# Publicidade: chaveamento do Business para o schema `ads`

Atualizado em: 2026-07-12

Status: código e SQL locais preparados. A migration da Fase 1 do RoadRunners ainda não foi executada; este chaveamento não foi publicado e não deve ser publicado antes dela.

## 1. Escopo

O Business passou a acessar diretamente os objetos canônicos `ads.*` no PostgreSQL principal. As views temporárias homônimas em `public` continuam sendo responsabilidade da migration da Fase 1 e não são removidas por este projeto.

Banco dedicado, fila assíncrona e FDW permanecem adiados para a Fase 2.

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
- `api/ads/conversion-click.cfm`
- `administracao/contas/includes/backend.cfm`
- `cupons-rr/includes/backend.cfm`
- `inscricoes/includes/backend.cfm`
- `includes/estrutura/home_admin_dashboard.cfm`
- `includes/estrutura/home_conta_dashboard.cfm`
- `portal/includes/banner_management_backend.cfm`
- `api/portal/banners/index.cfm`
- `api/portal/banners/click.cfm`
- `_legado/usuarios/includes/backend.cfm`

### DDL e incrementais

- `_codex/sql/2026-06-14_tb_ad_vouchers_contas.sql`
- `_codex/sql/2026-06-27_tb_ad_evento_metricas_dia.sql`
- `_codex/sql/2026-06-27_tb_ad_conversion_log.sql`
- `_codex/sql/ddl.sql`
- `portal/banners/portal_banner_schema.sql`

Uma alteração local preexistente em `administracao/contas/home.cfm` foi mantida intacta e não pertence a este chaveamento.

## 4. Alterações realizadas

- `SELECT`, `JOIN`, `INSERT`, `UPDATE` e `DELETE` dos objetos de publicidade agora usam `ads.*`.
- Não foi localizado SQL dinâmico de publicidade no runtime do Business; a função SQL de agregação encontrada foi qualificada no schema `ads`.
- Relações cruzadas relevantes foram mantidas em `public`, com qualificação explícita nos pontos alterados, incluindo eventos, contas, vínculos de conta e usuários.
- A FK inversa permanece definida como `public.tb_conta_cadastro_solicitacoes.id_ad_voucher -> ads.tb_ad_vouchers.id_ad_voucher`.
- Referências diretas a sequences passaram a usar `ads.*`.
- A fotografia `_codex/sql/ddl.sql` cria o schema `ads`, concede `USAGE` a `runner` e cria as tabelas de publicidade no schema correto.
- O SQL standalone de banners cria tabelas e índices em `ads`.
- Nenhuma view de compatibilidade em `public` foi removida ou redefinida.

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

- O datasource padrão do Business continua sendo `runner_dba`, definido em `Application.cfc`; os consumidores alterados não sobrescrevem o datasource em `<cfquery>`.
- A migration do RoadRunners cria `ads` com owner `runner_dba`. Portanto, o datasource do Business mantém acesso direto como owner.
- A migration também concede `USAGE ON SCHEMA ads` e privilégios explícitos históricos ao papel `runner`, necessário aos consumidores do RoadRunners.
- Owners, ACLs adicionais e roles reais ainda precisam ser conferidos no banco pela auditoria da migration antes de produção; nenhuma permissão foi testada contra o banco nesta tarefa.

## 8. Validações estáticas

- busca completa, case-insensitive, pelos 14 nomes de tabela em CFML, SQL, documentação e legado;
- auditoria por contexto SQL para `FROM`, `JOIN`, `INSERT INTO`, `UPDATE`, `DELETE FROM`, `CREATE TABLE`, `ALTER TABLE` e `REFERENCES` sem `ads.`;
- auditoria separada de sequences, casts `regclass`, `information_schema` e `current_schema()`;
- revisão manual das ocorrências de `clicks` para separar tabela de coluna, alias e label;
- `git diff --check` sem erros de whitespace;
- revisão do datasource padrão e de overrides nos consumidores alterados.

O repositório não oferece linter ou suíte automatizada de CFML. Não houve conexão com PostgreSQL, execução de migration, smoke test em ambiente ou deploy.

## 9. Dependências e consumidores ainda não resolvidos

- A migration da Fase 1 e o código qualificado do RoadRunners estão preparados, mas ainda não executados/publicados.
- Jobs, BI, integrações, funções do banco e scripts manuais externos aos dois repositórios precisam ser observados com a auditoria SQL e `pg_stat_statements` após o deploy.
- A atividade da rota `_legado/usuarios/` continua incerta; seu SQL foi qualificado para evitar regressão caso volte a ser chamado.
- As views temporárias `public.*` devem permanecer durante uma janela que cubra tráfego, rotinas diárias, semanais e mensais.
- A remoção das views, do wrapper temporário de função e qualquer alteração de banco dedicado/FDW/fila são trabalhos futuros.

## 10. Riscos e ordem coordenada de deploy

O principal risco é publicar este Business antes da migration: `ads.*` ainda não existe e as consultas falharão. Também é arriscado remover as views antes de observar consumidores externos ou executar um incremental antigo não qualificado depois da limpeza.

Ordem obrigatória:

1. backup, inventário real e migration do banco em dev, beta e depois produção;
2. deploy do RoadRunners já qualificado;
3. deploy do Business já qualificado;
4. observação de tráfego, jobs, BI, integrações, ACLs e `pg_stat_statements`;
5. remoção futura das views de compatibilidade somente por migration separada e após evidência de ausência de consumidores.
