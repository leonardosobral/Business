# CRM interno — fase 4 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task; superpowers:subagent-driven-development é alternativa apenas se escolhida pelo usuário. Steps use checkbox (`- [ ]`) syntax for tracking. Manter execução direta, já adotada nesta tarefa. Não recriar gates de aprovação já resolvidos.

**Goal:** Medir conversões e valores comprovados por campanha, com origem, deduplicação e estornos explícitos.

**Architecture:** Primeiro validar o produtor comercial existente; depois normalizar eventos de negócio e atribuí-los a uma campanha por regra determinística. O CRM de pedidos preserva sua propriedade e as fronteiras de conta.

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

- Uma compra com vários participantes não multiplica o valor do pedido (4.1/4.2).
- Pagamento importado, pessoa com vínculo aproximado e ausência de moeda não comprovam receita atribuível (4.1).
- Repetição, evento atrasado e estorno não duplicam conversões nem saldo (4.2).
- Clique pode vir de scanner e não comprova compra ou causalidade (4.2).
- Token/usuário/conta divergentes devem falhar sem atribuir a campanha alheia (4.2).

---
## Tarefa 4.1 — Contrato da primeira fonte comercial

**Arquivos:** ler `B/crm/includes/backend.cfm`, `R/_codex/sql/schema.sql` e os produtores apontados pelas funções/importadores desse schema; criar `B/docs/crm-interno-conversoes-fonte.md`. Não modificar checkout, credenciais ou permissões nesta tarefa.

**Interfaces:** documento define uma fonte habilitável com `{source,account_scope,order_key,event_key,occurred_at,source_version,user_id,status,amount_minor,currency,match_basis}`. Estados normalizados: confirmed/refunded/cancelled. `user_id` precisa de vínculo inequívoco; ausência ou conflito permanece unmatched. Primeira candidata: pedidos/participações do CRM existente, não atividade ou calendário do atleta.

- [x] Inventariar com metadados as tabelas `crm.tb_crm_pedidos`, `tb_crm_participacoes`, `tb_crm_pessoas`, índices únicos e rotinas que preenchem status/data_pagamento/valor/vínculo de usuário. Não exportar linhas pessoais nem payloads brutos.

```sql
SELECT table_name,column_name,data_type
FROM information_schema.columns
WHERE table_schema='crm' AND table_name IN
 ('tb_crm_pedidos','tb_crm_participacoes','tb_crm_pessoas')
ORDER BY table_name,ordinal_position;
```

- [x] Escrever fixture: um pedido pago com dois participantes, importação duplicada, pagamento sem data, pessoa sem vínculo certo, pedido reembolsado e valor sem moeda. Definir mapeamento baseado no código produtor, não apenas no texto “Pago”.
- [x] Documentar qual parte do valor é da RunnerHub. Se só existir valor bruto do pedido, a métrica chama “Valor de pedidos atribuídos”; não chamar de receita da RunnerHub nem calcular ROI sem fonte de custos.
- [x] Registrar chaves exatas, regra de moeda, ordem de eventos, devoluções, escopo de conta e atraso da fonte. Importação de terceiro não equivale a autorização para campanha global. Reutilizar somente eventos e vínculos permitidos para o CRM interno.
- [x] Resultado explícito: fonte apta com mapeamento e casos comprovados, ou fonte não apta com requisito ausente. Se faltarem confirmação transacional, vínculo inequívoco ou tratamento de devolução, concluir esta auditoria e bloquear apenas a tarefa 4.2. As fases anteriores seguem publicáveis; não inventar callback ou receita para marcar R6 concluído.

**Conclusão:** contrato comprovado da primeira fonte ou impedimento técnico documentado. O executor só escolhe e modifica produtor após essa evidência; nenhum caminho de checkout foi presumido neste plano.

## Tarefa 4.2 — Eventos, atribuição e relatório

**Arquivos:** criar `R/services/crm/CrmConversionService.cfc`, `R/_codex/sql/migrations/2026-09-24_crm_conversions.sql`, `B/services/CrmOrderEventAdapter.cfc`, `B/api/crm-interno-conversions.cfm`, `B/crm-interno/crm-conversions.js`; modificar `CrmTrackingService.cfc`, `CrmAdminService.cfc`, `R/api/crm-interno/worker.cfm`, `B/administracao/cron-jobs/crm_interno_jobs.sql`, UI/testes/runner/manifesto. O adaptador só é implementado com o mapeamento concluído em 4.1.

**Interfaces:** `CrmOrderEventAdapter.read(afterCursor,limit=100) -> {events,next_cursor,source_health}`; `CrmConversionService.ingest(event) -> {id,status,duplicate}`; `attribute(conversionId) -> {campaign_id,delivery_id,method,status}`; `report(campaignId) -> {conversions,refunded,net_amount_minor,currency,method,coverage}`. Worker assinado aceita `conversions.ingest` apenas para fonte interna allowlisted; wrapper Business usa CrmJobSecurity no escopo `crm.conversions.worker`. Sem endpoint público de ingestão e sem segredo novo implícito.

**Dados:** `conversion_events` mantém source, account_scope, order_key, event_key, source_version, user_id, occurred_at, status, amount_minor, currency, received_at e UNIQUE(source,account_scope,event_key). `conversion_attributions` liga order_key/usuário ao delivery/campaign quando comprovado; método e janela ficam gravados. Um pedido tem uma atribuição monetária ativa; participações não multiplicam valor. Eventos sem vínculo ficam registrados como unmatched e não são distribuídos entre campanhas.

- [ ] Escrever testes antes do serviço: duas importações do mesmo evento, payload conflitante com mesma chave, dois participantes, estorno parcial/total e eventos fora de ordem. Implementar hash do payload normalizado; repetição idêntica é idempotente e repetição conflitante falha sem sobrescrever.

```cfml
service=new services.crm.CrmConversionService().init('crm_test');
event={source='fixture_orders',account_scope='fixture',order_key='order-1',
 event_key='paid-1',source_version=1,user_id=102,status='confirmed',
 amount_minor=10000,currency='BRL',occurred_at=now()};
one=service.ingest(event);two=service.ingest(event);
check(one.id==two.id && two.duplicate,'purchase event is idempotent');
```

- [ ] Usar inteiros em centavos e moeda explícita; não somar moedas. Validar limite/tamanho/enum e evento futuro. Reconciliar estado corrente pela versão/ordem comprovada da fonte; evento velho fica auditado e não desfaz estorno novo. Não aceitar fonte/teste como produtor de produção.
- [ ] Regra inicial de atribuição: último clique registrado da mesma pessoa nos 7 dias anteriores à confirmação comercial, somente com vínculo inequívoco do pedido e clique dentro de starts_at/ends_at da revisão imutável da campanha. Não usar o estado atual da campanha para rejeitar um clique histórico válido. Desempatar por timestamp e ID. Estorno mantém a atribuição da confirmação original, sem procurar outro clique. Sem clique elegível, deixar não atribuído. Registrar método `last_recorded_click_7d`; nunca chamar de efeito causal ou de clique humano comprovado.
- [ ] Adaptador pagina por chave estável e versão da fonte, preservando eventos com o mesmo instante. Persistir next_cursor somente após confirmação do lote inteiro; repetição após falha é segura pela chave do evento. Testar queda antes e depois do aceite, atraso da fonte e registro inválido. Uma rejeição não pode avançar silenciosamente o cursor e perder o evento.
- [ ] Para fontes sem user_id inequívoco, não resolver por nome/e-mail aproximado. Integração de token de checkout externo fica fora desta primeira fonte, exigindo contrato e implementação próprios antes de habilitar outra fonte.
- [ ] Registrar conversão manual da oportunidade como métrica distinta, sem somá-la a eventos transacionais. No relatório mostrar origem, cobertura, atraso, conversões confirmadas, devoluções e valor líquido conforme contrato 4.1. Entrega e abertura continuam indisponíveis se não houver recibo externo.
- [ ] Validar camada assinada contra fonte não habilitada, assinatura ausente, usuário divergente e replay; testes de adaptador não acessam transportes externos. Job de leitura entra desativado e é ativado somente após reconciliação sintética e smoke de leitura autorizado.
- [ ] Demonstrar em fonte real validada uma transação deduplicada/estorno correlacionável sem criar compra ou envio artificial. Se não existir evento adequado, registrar integração instalada e verificação real pendente; não declarar conversão comprovada só por fixture.

**Conclusão da fase:** R6 só se completa com produtor real e atribuição auditável. Executar publicação/recibo do plano mestre; apresentar valores comerciais com rótulos compatíveis com a fonte.
