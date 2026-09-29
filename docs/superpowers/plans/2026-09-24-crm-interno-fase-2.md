# CRM interno — fase 2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task; superpowers:subagent-driven-development é alternativa apenas se escolhida pelo usuário. Steps use checkbox (`- [ ]`) syntax for tracking. Manter execução direta, já adotada nesta tarefa. Não recriar gates de aprovação já resolvidos.

**Goal:** Organizar oportunidades e próximas ações por pessoa, com sugestões comerciais revisáveis.

**Architecture:** Novas entidades comerciais ficam em crm_interno e usam o mesmo guard administrativo. Business oferece uma lista operacional e a ficha lateral; sugestões apenas preenchem rascunhos existentes.

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

- Duplo clique/repetição não cria oportunidades duplicadas (2.1).
- Dois operadores não sobrescrevem responsável/estágio silenciosamente (2.1).
- Responsável inativo ou sem papel administrativo não pode receber oportunidade (2.1).
- Público combinado com OU não sustenta recomendação como se todos tivessem o mesmo sinal (2.2).
- Sugestão/registro de interesse não concede opt-in nem dispara contato (2.1/2.2).

---
## Tarefa 2.1 — Oportunidade, responsável e próxima ação

**Arquivos:** criar `R/services/crm/CrmOpportunityService.cfc`, `R/_codex/sql/migrations/2026-09-24_crm_opportunities.sql`, `B/crm-interno/crm-opportunities.js`; modificar `CrmAdminService.cfc`, `B/crm-interno/{index.cfm,crm.js,crm.css,crm-profile.js}`, runner/fixtures e manifesto citados no plano mestre.

**Interfaces:** `list(filters,page=1)`, `get(id)`, `save(actorId,input)`, `transition(actorId,id,expectedRevision,stage,requestId)`, `addNote(actorId,id,expectedRevision,text,requestId)`. Ações `opportunities.list/get/save/transition/note`. `save` aceita `{user_id,interest,owner_id,next_action,due_at,note,request_id}` e, em edição, `{id,expected_revision}`; retorna `{id,revision}`. UI exporta `initOpportunities({api,escape,date,openProfile})`.

**Dados:** tabela `opportunities`: id UUID, user_id/owner_id/created_by inteiros com FK de usuário, interest/stage/next_action texto, due_at timestamptz opcional, revision inteiro positivo, created_at/updated_at timestamptz. Interesses iniciais: `shoes,coaching,race,service,other`; ações são texto simples até 500 caracteres; observações até 2.000. Estágios persistidos: `new,contacting,interested,converted,closed`. Tabela `opportunity_events`: id UUID, opportunity_id UUID com FK, actor_id inteiro, request_id UUID, request_fingerprint texto, kind texto, previous_revision/next_revision inteiros, body JSONB e created_at timestamptz. `body` guarda somente campos alterados permitidos e a observação como texto, nunca HTML executável ou payload de requisição completo. Usuário precisa continuar ativo para novas mutações comerciais.

- [ ] Escrever testes de transição, repetição do mesmo request e conflito de revisão. Fixtures adicionais são usuários sintéticos locais; nenhum destinatário real.

```cfml
ops=new services.crm.CrmOpportunityService().init('crm_test');
requestId='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
input={user_id=102,interest='coaching',owner_id=101,
 next_action='Revisar interesse informado',note='',request_id=requestId};
first=ops.save(101,input);again=ops.save(101,input);
check(first.id==again.id,'same request creates one opportunity');
reject(function(){ops.transition(101,first.id,0,'contacting',
 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');},'revision_conflict');
```

- [ ] Criar migration aditiva com CHECK dos enums e `revision>0`. Uma oportunidade aberta por `(user_id,interest)`; encerradas/concluídas conservam histórico. Repetição com mesmo request e payload diferente falha `request_conflict`.

```sql
CREATE UNIQUE INDEX IF NOT EXISTS crm_opportunity_open_once
ON crm_interno.opportunities(user_id,interest)
WHERE stage IN ('new','contacting','interested');
CREATE UNIQUE INDEX IF NOT EXISTS crm_opportunity_request_once
ON crm_interno.opportunity_events(actor_id,request_id);
```

- [ ] Implementar transação com lock da oportunidade, validação de expected_revision e evento/auditoria no mesmo commit de banco. Validar responsável com o mesmo `CrmSecurity.requireActor(owner_id,false)`; não conceder permissão nem criar papel novo. Reabrir converted/closed só por comando explícito e sujeito à restrição de oportunidade aberta.
- [ ] Acrescentar aba Oportunidades com filtros responsável, estágio e prazo; ordenação vencidas primeiro, prazo ASC, id ASC, 25 por página. A ficha lateral mostra oportunidades da pessoa e permite criar/editar. Movimentação usa botões acessíveis, sem depender de arrastar.
- [ ] Mostrar próximos retornos como lista interna. Não criar notificações, e-mails, WhatsApp ou eventos Google por salvar uma ação. Converter manualmente apenas registra resultado operacional; não soma receita comprovada.
- [ ] Validar concorrência com duas requisições na mesma revisão, responsável excluído, texto com HTML, reabertura duplicada, datas sem timezone e operação após opt-out. Opt-out permite registrar histórico interno, mas não contatar; todos os envios continuam no fluxo de campanha revisada.

**Conclusão:** pessoa tem responsável, interesse, próxima ação e histórico rastreável, sem duplicações ou perda silenciosa de alterações.

## Tarefa 2.2 — Sugestões explicáveis e preparação de rascunhos

**Arquivos:** criar `R/services/crm/CrmRecommendationService.cfc`, `B/crm-interno/crm-recommendations.js`; modificar `CrmAdminService.cfc`, `B/crm-interno/crm.js`, `crm-profile.js`, `crm.css`, testes e manifesto.

**Interfaces:** `forAudience(audienceId,version) -> {audience_id,version,items:[{key,title,reason,template}],reason}`; ação `audiences.recommendations`. `reason` do envelope é vazio quando há sugestões ou informa por que nenhuma está disponível. `template` contém somente título/corpo/botão/canal sugerido; destino é escolhido pelo operador entre os destinos já autorizados. Exportar `renderRecommendations({container,items,onPrepareDraft})`.

- [ ] Testar regras com política AND, política OR, sinal indisponível e ausência de consentimento. Não escrever em campaigns ou deliveries ao consultar sugestões.

```cfml
recommendations=new services.crm.CrmRecommendationService().init('crm_test');
store=new services.crm.CrmStore().init('crm_test');
audience=new services.crm.CrmAudienceService().init('crm_test');
suggestedAudience=audience.saveAudience(101,{name='Sugestão de próxima prova',
 policy={operator='all',criteria=[{type='recent_result',days=30,distance='half'}]}});
before=store.q('SELECT count(*) n FROM crm_interno.deliveries').n;
recommendations.forAudience(suggestedAudience.id,suggestedAudience.current_version);
check(store.q('SELECT count(*) n FROM crm_interno.deliveries').n==before,
 'recommendation never sends or reserves delivery');
```

- [ ] Começar com quatro modelos determinísticos: cadastro até 30 dias → apresentação dos serviços; evento até 90 dias → preparação/logística; resultado reconhecido até 90 dias → próxima prova; inscrição Brasil Gigante → conteúdo/oferta relacionada ao circuito. Texto usa sinal observado e evita afirmar treino/compra/interesse declarado.
- [ ] Nesta versão, só sugerir quando `operator='all'` e existir o critério correspondente disponível. Para OR não homogêneo, retornar lista vazia e explicar que é preciso refinar o público; não mudar silenciosamente quem receberá a campanha.

```cfml
if(policy.operator!='all')return {audience_id=audienceId,version=version,
 items=[],reason='audience_needs_refinement'};
```

- [ ] Botão “Preparar campanha” abre editor existente com texto sugerido e público/versão visíveis. Continua necessário salvar, revisar destinatários e confirmar. Destino inválido, público sem opt-in ou fonte retirada continua sujeito aos serviços existentes.
- [ ] Mostrar no máximo quatro sugestões, com motivo e opção de ignorar. Sem score de propensão ou promessa de conversão. Validar que cancelar o rascunho não altera oportunidade, público ou fila.

**Conclusão da fase:** R3/R4 entregues. Operação consegue organizar atendimento e preparar campanhas sem perder a revisão humana. Executar publicação/recibo do plano mestre.
