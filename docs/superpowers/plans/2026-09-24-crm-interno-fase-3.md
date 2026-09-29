# CRM interno — fase 3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task; superpowers:subagent-driven-development é alternativa apenas se escolhida pelo usuário. Steps use checkbox (`- [ ]`) syntax for tracking. Manter execução direta, já adotada nesta tarefa. Não recriar gates de aprovação já resolvidos.

**Goal:** Mostrar evolução dos públicos e planejar campanhas evitando excesso de contato.

**Architecture:** Fotografias diárias completas alimentam comparações; calendário lê campanhas existentes. Job usa o agendador Business e worker assinado já adotados, sem nova automação pessoal nem serviço de calendário externo.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, JavaScript nativo e MDBootstrap existentes. Sem novo framework ou fornecedor.

**Spec:** [Especificação de evolução](../specs/2026-09-24-crm-interno-evolucao-design.md).

## Global Constraints

- Business opera a interface; RoadRunners mantém identidade, públicos, elegibilidade, campanhas e histórico central em `crm_interno`.
- Preservar ADMIN/DEV, contexto real, assinatura HMAC, CSRF, auditoria e preferências comerciais existentes.
- Permanecem revisão manual, fotografia de destinatários e revalidação antes da entrega; não ampliar uma campanha já confirmada.
- Não usar dados do Strava nem indicadores derivados na segmentação ou em sugestões comerciais deste plano.
- Mudanças de banco são aditivas; nenhuma migração destrutiva, credencial, permissão, commit, branch, push ou PR está autorizada por este plano.
- Não enviar campanhas reais para validar desenvolvimento. Testes usam dados sintéticos; verificações de produção são de leitura.

As demais restrições da especificação também se aplicam. B = `/Users/Shared/Projects/RunnerHub/Business`; R = `/Users/Shared/Projects/RunnerHub/RoadRunners`. Caminhos B/R abaixo identificam o repositório dono, não uma nova pasta.

## Review Focus

- Job interrompido não publica fotografia parcial (3.1).
- Regra ou fonte alterada não vira suposta entrada/saída de usuário (3.1).
- Públicos sobrepostos não são somados como pessoas únicas (3.2).
- Campanha pausada/cancelada e timezone não geram previsão falsa (3.2).
- Conflito planejado é estimativa; envio continua bloqueado atomicamente em execução (3.2).

---
## Tarefa 3.1 — Histórico diário e entradas/saídas

**Arquivos:** criar `R/services/crm/CrmAudienceHistoryService.cfc`, `R/_codex/sql/migrations/2026-09-24_crm_audience_history.sql`, `B/api/crm-interno-history.cfm`, `B/crm-interno/crm-audience-history.js`; modificar `CrmAdminService.cfc`, `R/api/crm-interno/worker.cfm`, `B/administracao/cron-jobs/crm_interno_jobs.sql`, `B/crm-interno/{crm.js,index.cfm,crm.css}`, testes/runner/manifesto.

**Interfaces:** `capture(audienceId,version,asOf) -> {snapshot_id,status,total}`; `history(audienceId,days=30) -> {items}`; `difference(currentSnapshotId,previousSnapshotId,page=1) -> {status,entered,left,total_entered,total_left}`. Ações administrativas `audiences.history/difference`; worker `audiences.capture` recebe cursor/lote máximo 5 e só calcula públicos ativos. Endpoint cron valida escopo `crm.history.worker` via CrmJobSecurity existente e chama worker central, sem inventar ator administrativo.

**Dados:** `audience_snapshots`: id UUID, audience_id, version, captured_day (São Paulo), as_of, status building/complete/failed, total, source_signature, error_code. Unique `(audience_id,version,captured_day)`. `audience_snapshot_members`: snapshot_id/user_id PK; índices por snapshot e user. Assinatura das fontes inclui capacidade e revisão da regra, não segredos nem dados pessoais.

- [ ] Testar repetição do job, falha no meio e troca de versão. Usar duas fotografias sintéticas `{101,102}` e `{102,104}`: entrada 104, saída 101, total 2; não confundir novo usuário com conta excluída por mudança de regra.

```sql
SELECT user_id FROM crm_interno.audience_snapshot_members WHERE snapshot_id=:current
EXCEPT
SELECT user_id FROM crm_interno.audience_snapshot_members WHERE snapshot_id=:previous;
```

- [ ] Resolver a política da versão solicitada, sem trocar pela versão mais recente durante o job. Inserir membros em transação repeatable_read: compilar com `CrmRules.compile`, executar INSERT SELECT parametrizado sobre `public.tb_usuarios u` e contar membros. Marcar complete no mesmo commit dos membros. Após rollback, registrar failed em transação separada sem substituir fotografia completa existente. Mesmo dia/versão é idempotente; erro pode ser reprocessado sob lock. Fonte necessária indisponível falha a captura; não produzir público vazio artificial.
- [ ] Comparar apenas complete com mesma versão e assinatura de fonte. Se mudou versão/fonte, retornar `status='not_comparable'`; primeiro snapshot retorna `insufficient_history`. Contagens agregadas ficam por 365 dias; IDs membros por 30 dias. Após expirar membros, difference retorna `not_available`; comparações antigas mostram apenas série de tamanho, sem nomes inferidos.
- [ ] Antes de ativar job diário, medir o produto públicos × membros × 30 no banco sintético, tempo e tamanho dos índices. Processar públicos em lotes retomáveis, um snapshot por transação. Cadência inicial: uma captura por dia às 03h de São Paulo, retomadas pelo agendador existente sem sobreposição. Nunca executar nova captura ao abrir a página.
- [ ] Mostrar gráfico simples/tabular acessível de tamanho e entradas/saídas desde fotografia comparável. Listas de pessoas paginadas; usuário agora inativo não tem ficha aberta. Mostrar início real do histórico, ausência de cobertura e edição da regra.

```cfml
historyService=new services.crm.CrmAudienceHistoryService().init('crm_test');
audience=new services.crm.CrmAudienceService().init('crm_test');
historicalAudience=audience.saveAudience(101,{name='Histórico de SC',
 policy={operator='all',criteria=[{type='profile_state',state='SC'}]}});
first=historyService.capture(historicalAudience.id,historicalAudience.current_version,now());
again=historyService.capture(historicalAudience.id,historicalAudience.current_version,now());
check(first.snapshot_id==again.snapshot_id,'same daily snapshot is idempotent');
```

**Conclusão:** R5 tem histórico verdadeiro a partir da ativação, sem preencher passado ou exibir gravação incompleta.

## Tarefa 3.2 — Sobreposição, calendário e pressão de contato

**Arquivos:** criar `R/services/crm/CrmPlanningService.cfc`, `B/crm-interno/crm-calendar.js`; modificar `CrmAdminService.cfc`, `B/crm-interno/{index.cfm,crm.js,crm.css}`, testes e manifesto.

**Interfaces:** `overlap(audienceIds,asOf) -> {as_of,total_unique,pairs:[{left_id,right_id,intersection}]}` com 2–5 IDs ativos; `calendar(from,to,channel,page=1) -> {items,total}` com janela máxima 93 dias e 50 itens/página; `pressure(campaignId,revision) -> {as_of,estimated,conflicts:[{campaign_id,users,reason}]}`. Ações `audiences.overlap`, `campaigns.calendar/pressure`.

- [ ] Testar conjuntos A={101,102}, B={102,104}: interseção 1, únicos 3. SQL usa EXISTS/UNION deduplicados com parâmetros isolados por política; não somar tamanhos individuais.

```cfml
planning=new services.crm.CrmPlanningService().init('crm_test');
audience=new services.crm.CrmAudienceService().init('crm_test');
audienceA=audience.saveAudience(101,{name='Sobreposição SC',
 policy={operator='all',criteria=[{type='profile_state',state='SC'}]}});
audienceB=audience.saveAudience(101,{name='Sobreposição SP ou masculino',
 policy={operator='any',criteria=[{type='profile_state',state='SP'},
 {type='profile_gender',gender='masculino'}]}});
r=planning.overlap([audienceA.id,audienceB.id],now());
check(r.total_unique==3 && r.pairs[1].intersection==1,'overlap is deduplicated');
```

- [ ] Reutilizar `campaign_revisions.starts_at/ends_at/channel`, estado atual da campanha e fotografia confirmada em deliveries. Rascunho/revisão aparecem como planejamento; cancelada não entra em conflitos, pausada aparece identificada mas não como envio ativo.
- [ ] Calendário interno com lista por dia e visão semanal; filtros por canal/estado. Não escrever em `tb_google_agenda_*` nem sincronizar agenda externa. Datas são armazenadas com timezone e apresentadas em America/Sao_Paulo.
- [ ] Pressão compara e-mail/notificação com entregas confirmadas e intervalo de 7 dias; campanhas não confirmadas são estimativas pelas políticas atuais. Card aparece em seção própria de concorrência, sem fingir usar a mesma janela. Limitar consulta a uma campanha selecionada e vizinhas do período; não comparar todos os pares em toda abertura.
- [ ] Exibir quantidade de pessoas potencialmente coincidentes e campanha envolvida, sem remanejar agenda automaticamente. O serviço de entrega continua sendo a autoridade final.
- [ ] Testar mudança de horário perto de meia-noite, campanha pausada depois de carregar, limite máximo de janela e públicos iguais. Aviso de conflito não cancela nem confirma campanha.

**Conclusão da fase:** R5/R8 entregues. Executar publicação/recibo do plano mestre; ativar somente o job de histórico novo, sem ativar campanhas.
