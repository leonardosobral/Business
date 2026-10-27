# Instalação manual do banco Teams

O datasource ColdFusion atual recusa DDL. Os scripts abaixo devem ser executados num cliente administrativo PostgreSQL, conectado ao banco do RR como `runner_dba`. Não é necessário alterar credenciais, permissões ou configuração do datasource.

1. Execute `_codex/sql/2026-10-26_rr_teams.sql` inteiro. Ele cria o esquema `rr_teams`, 12 tabelas com índices/restrições e um job de email em `tb_cron_jobs`, **desativado**. Todas as instruções estão na mesma transação. Erros interrompem e revertem a instalação; se o cliente mantiver a conexão em estado de erro, execute `ROLLBACK`.
2. Execute `_codex/sql/2026-10-26_rr_teams_test_fixture.sql` para criar o esquema isolado de testes. Ele não cria job e não copia ou modifica dados existentes. A suíte nativa usa identidades já existentes apenas como referência, grava dados somente nas tabelas da fixture e reverte suas transações.
3. Informe a execução para que os testes de banco, a publicação e a ativação controlada do job possam ser concluídos.

O script principal não publica código, não ativa envios, não cria contas de usuários e não muda tabelas de eventos ou contas empresariais. O job só deve ser ativado após publicação e validação autenticada em modo dry-run.

Confira após a instalação:

```sql
SELECT version, installed_at FROM rr_teams.schema_version;
SELECT count(*) AS teams FROM rr_teams.team;
SELECT nome, ativo FROM public.tb_cron_jobs
WHERE endpoint_url = 'https://business.roadrunners.run/teams/mail-worker.cfm';
```

Resultados esperados na instalação inicial: versão 1, zero Teams e job desativado.
