# CRM interno — fase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task; superpowers:subagent-driven-development é alternativa apenas se escolhida pelo usuário. Steps use checkbox (`- [ ]`) syntax for tracking. Manter execução direta, já adotada nesta tarefa. Não recriar gates de aprovação já resolvidos.

**Goal:** Mostrar quem pode ser contatado e oferecer uma ficha lateral confiável, com cobertura explícita dos dados.

**Architecture:** Consolidar elegibilidade no RoadRunners sem remover travas de entrega. Business recebe resumos agregados e ficha paginada; o modal de público e a lista permanecem intactos.

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

- E-mail malformado confirmado: resumo, revisão e entrega devem concordar (1.1).
- Opt-out ou contato após o resumo: revalidação continua bloqueando entrega (1.1).
- Falta de nascimento/estado não significa zero anos ou inatividade (1.2).
- Duas fichas abertas rapidamente não podem mostrar a resposta da primeira na segunda (1.3).
- Falha de fonte deve aparecer como indisponível, sem apagar a seleção principal (1.2/1.3).

---
## Tarefa 1.1 — Classificação comum e resumo por canal

**Arquivos:** criar `R/services/crm/CrmEligibilityService.cfc`; modificar `CrmPreferenceService.cfc`, `CrmCampaignService.cfc`, `CrmDeliveryService.cfc`, `CrmAdminService.cfc`; modificar `B/crm-interno/{index.cfm,crm.js,crm.css}`; testes em `R/_codex/tests/crm-interno/{fixtures.sql,run.cfm}`.

**Interfaces:** `CrmEligibilityService.classify(userState, channel, asOf) -> {allowed,reason}`; `summary(policy, asOf) -> {total,as_of,channels:{email,notification,card}}`, com cada canal `{eligible,excluded,reasons:[{code,total}]}`. Nova ação `audiences.eligibility` aceita `{id,version}`; resolve a política dessa versão no servidor. Card significa aptidão geral para campanhas; dispensa e quota de uma campanha específica continuam no `CrmCardService`.

- [ ] Acrescentar fixtures: opt-in ausente, canal bloqueado, e-mail confirmado porém inválido, bounce, contato recente e reserva com resultado desconhecido. Escrever a comparação dos mesmos usuários nos três caminhos antes de extrair regras.

```cfml
eligibility=new services.crm.CrmEligibilityService().init('crm_test');
result=eligibility.classify({active=true,optin=true,channel_blocked=false,
 email='invalid',email_verified=true,email_suppressed=false,
 recent_contact=false,contact_reserved=false},'email',now());
check(!result.allowed && result.reason=='email_unverified','invalid email excluded');
```

- [ ] Executar o runner comum; esperar falha pela ausência do novo serviço. Implementar precedência de motivos: conta inativa → sem opt-in → canal bloqueado → e-mail inválido/não verificado → bounce → frequência/reserva. Em `card`, ignorar a janela de e-mail/notificação, mantendo os controles próprios existentes.
- [ ] Obter preferências, bounce e janela por JOIN/EXISTS em lote; validar formato com a mesma função CFML usada na autorização. Não executar uma consulta por usuário. Percorrer lotes de 1.000 no servidor, agregando só contagens na resposta; limite e timeout devem encerrar como indisponível, nunca retornar subtotal como total.

```cfml
// O mesmo classificador é usado no resumo e na materialização da prévia.
for (var candidate in candidates) {
 var decision=eligibility.classify(candidate,channel,asOf);
 if(decision.allowed) eligibleCount++; else excludedCount++;
}
```

- [ ] Fazer `CrmPreferenceService.eligibility` delegar a parte estática: informar `recent_contact=false` e `contact_reserved=false` somente nesse wrapper, que não decide a frequência. Preview e resumo carregam esses estados do banco; autorização conserva `FOR UPDATE` em `contact_windows` e reclassifica sob a trava. Nenhuma contagem reserva envio ou escreve preferências.
- [ ] Mostrar três blocos de contagem apenas para o público selecionado, com versão/horário e motivos expansíveis. Carregar em segundo plano, depois da lista de usuários; ao trocar público descartar resposta antiga. Se ultrapassar o timeout, oferecer recalcular sem travar a navegação.
- [ ] Executar a suíte incluindo opt-out após resumo, limite simultâneo entre canais e igualdade `eligible + excluded == total` por canal. Medir com 60 mil usuários sintéticos e registrar duração/memória; não prometer resposta instantânea antes da medição.

**Conclusão:** totais por canal confiáveis, nenhum envio e nenhuma divergência nova entre resumo, prévia e autorização.

## Tarefa 1.2 — Cobertura e qualidade dos dados

**Arquivos:** criar `R/services/crm/CrmDataQualityService.cfc`; modificar `CrmAdminService.cfc`, `B/crm-interno/{index.cfm,crm.js,crm.css}`, testes `fixtures.sql/run.cfm`.

**Interfaces:** `coverage(policy, asOf) -> {total,fields:[{key,filled,missing,invalid}],sources:[{key,status,from,to}]}`; ação `audiences.coverage` aceita `{id,version}`. Inicialmente: estado, cidade, nascimento e gênero; fontes resultados/agenda/desafios/acessos.

- [ ] Criar fixture com nascimento ausente, nascimento futuro, cidade vazia e gênero informado. Testar que missing e invalid são distintos e que não há inferência de idade/gênero.

```cfml
// Dentro de coverage(policy, asOf), usando os serviços existentes.
var audience=new CrmAudienceService().init(variables.dsn);
var rules=new CrmRules();
var compiled=rules.compile(policy,audience.capabilities(),asOf);
var params=duplicate(compiled.params);
params.quality_as_of=p(asOf,'cf_sql_timestamp');
var counts=q("SELECT count(*) AS total, " &
 "count(*) FILTER(WHERE u.data_nascimento IS NULL) AS missing_birth, " &
 "count(*) FILTER(WHERE u.data_nascimento > CAST(:quality_as_of AS date) " &
 "OR u.data_nascimento <= CAST(:quality_as_of AS date) - interval '121 years') AS invalid_birth " &
 "FROM public.tb_usuarios u WHERE " & compiled.sql,params);
```

- [ ] Implementar agregações somente sobre IDs da política compilada, com parâmetros. Para estado, invalid significa preenchido fora das 27 UFs; cidade/gênero vazios após trim são missing. Nascimento futuro ou idade completa superior a 120 é invalid; testar também o dia em que completa 121 anos. `filled` significa preenchido e válido, de modo que `filled + missing + invalid == total`. Não modificar os cadastros.
- [ ] Usar `coverage_daily/access_daily` para início da coleta; manter `partial` quando a coleta respeita opt-out e usuários não autenticados. Sem registro não afirmar que o usuário não acessou.
- [ ] Exibir cobertura em seção recolhida na ficha do público; valores indisponíveis usam estado textual distinto de 0. Validar denominador idêntico ao total da mesma política/versão.

```cfml
quality=new services.crm.CrmDataQualityService().init('crm_test');
r=quality.coverage({operator='all',criteria=[{type='profile_state',state='SC'}]},now());
check(r.total==2,'coverage denominator follows the same audience');
```

**Conclusão:** operador entende por que filtros de idade ou localidade deixam parte da base de fora.

## Tarefa 1.3 — Ficha lateral e linha do tempo

**Arquivos:** criar `R/services/crm/CrmProfileService.cfc`, `B/crm-interno/crm-profile.js`; modificar `CrmAdminService.cfc`, `CrmAudienceService.cfc`, `B/crm-interno/{index.cfm,crm.js,crm.css}`, manifesto `B/_codex/scripts/deploy_crm_interno.py`; testes `fixtures.sql/run.cfm`.

**Interfaces:** `CrmProfileService.get(userId) -> {user,registrations,results,access_summary,channels}` e `timeline(userId,cursor,limit=25) -> {items,next_cursor}`, itens `{kind,at,id,label,status,source}`. Ações `users.profile` mantém campos legados e acrescenta dados; `users.timeline` é nova. `crm-profile.js` exporta `createProfilePanel({api,escape,date}) -> {open(userId),close()}`.

- [ ] Testar usuário excluído/sem fonte, mesmo instante em dois eventos e paginação sem repetição. Ordenar `(at DESC,kind DESC,id DESC)` e validar cursor opaco limitado a usuário/filtros; não incluir e-mail/token no cursor.

```cfml
profiles=new services.crm.CrmProfileService().init('crm_test');
reject(function(){profiles.get(103);},'not_found');
page1=profiles.timeline(102,'',25);
check(arrayLen(page1.items)<=25,'timeline is bounded');
```

- [ ] Montar leitura de inscrições próprias, resultados reconhecidos, acessos próprios, entregas e eventos impression/click/dismiss. Usar origem/rótulos explícitos; aceite do transporte não vira leitura. Preferências comerciais são leitura, sem atalho para conceder consentimento.
- [ ] Abrir `<dialog>` lateral acessível, com foco contido e retorno ao botão de origem; mobile ocupa a largura disponível. Troca rápida A/B usa contador de requisição; preservar scroll/página da tabela ao fechar.

```javascript
// No ponto atual de abertura de perfil em crm.js; sem global de estado.
const {createProfilePanel}=await import('/crm-interno/crm-profile.js?v=1');
const panel=createProfilePanel({api,escape,date});
await panel.open(userId);
```

- [ ] Validar ficha com fontes vazias, erro parcial, histórico longo, teclado e 390px. Incluir módulo no manifesto fechado de deploy antes de publicar a fase.

**Conclusão da fase:** R1/R2/R7 entregues; ficha não perde seleção, canais mostram motivos e cobertura é explícita. Executar publicação/recibo do plano mestre.
