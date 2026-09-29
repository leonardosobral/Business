# Evolução do CRM interno — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task; superpowers:subagent-driven-development é alternativa apenas se escolhida pelo usuário. Steps use checkbox (`- [ ]`) syntax for tracking. Manter execução direta, já adotada nesta tarefa. Não recriar gates de aprovação já resolvidos.

**Goal:** Entregar as oito melhorias em quatro fases publicáveis, começando pela visão do usuário e a rotina comercial.

**Architecture:** Reutilizar a API assinada e os serviços existentes. Cada fase adiciona contratos compatíveis e módulos pequenos; a integração de pedidos só entra depois de comprovar origem e vínculo.

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

1. Divergência entre contagem, revisão e entrega: fase 1 compara os três caminhos com a mesma fixture.
2. Dados ausentes ou revogação posterior: fases 1/2 mostram indisponibilidade e mantêm revalidação de contato.
3. Edição e repetição concorrentes: fase 2 exige revisão otimista e idempotência nas oportunidades.
4. Fotografias incompletas ou regras alteradas: fase 3 não apresenta falsas entradas/saídas.
5. Compra duplicada, vínculo ambíguo ou estorno: fase 4 não infla conversões/receita.

---
## Sequência de execução

| Fase | Resultado para operação | Dependência | Porte relativo |
|---|---|---|---|
| [1 — Usuário e elegibilidade](2026-09-24-crm-interno-fase-1.md) | Quantidades por canal, ficha lateral e cobertura dos dados | CRM publicado | Médio |
| [2 — Rotina comercial](2026-09-24-crm-interno-fase-2.md) | Oportunidades, responsáveis, próximas ações e sugestões | Fase 1 | Grande |
| [3 — Públicos e campanhas no tempo](2026-09-24-crm-interno-fase-3.md) | Evolução, sobreposição e calendário de campanhas | Fase 1; fase 2 não é requisito técnico | Grande |
| [4 — Conversões e valores](2026-09-24-crm-interno-fase-4.md) | Resultados comprovados e atribuição por campanha | Fases 1/2 e produtor comercial validado | Grande, dependente da integração |

Porte é comparação de complexidade, não prazo prometido. Confirmar duração de cada fase após medir consultas, revisar schema real e identificar o produtor da fase 4. Não bloquear a fase 1 por decisões da fase 4.

## Base existente a reutilizar

| Responsabilidade | Arquivos atuais |
|---|---|
| Tela e editor modal | `B/crm-interno/index.cfm`, `crm.js`, `crm.css` |
| Proxy administrativo | `B/crm-interno/api.cfm`, `B/services/CrmClient.cfc`, `R/api/crm-interno/admin.cfm`, `R/services/crm/CrmAdminService.cfc` |
| Públicos e regras | `R/services/crm/CrmAudienceService.cfc`, `CrmRules.cfc` |
| Preferências e elegibilidade | `R/services/crm/CrmPreferenceService.cfc`, `CrmCampaignService.cfc`, `CrmDeliveryService.cfc`, `CrmCardService.cfc` |
| Eventos e resultados | `R/services/crm/CrmTrackingService.cfc`, `R/api/crm-interno/click.cfm` |
| Jobs existentes | `B/administracao/cron-jobs/crm_interno_jobs.sql`, `B/services/CrmJobSecurity.cfc`, `R/api/crm-interno/worker.cfm` |
| CRM de inscrições/pedidos | `B/crm/includes/backend.cfm`; schema de referência `R/_codex/sql/schema.sql`, tabelas `crm.tb_crm_pedidos/pessoas/participacoes` |
| Teste isolado | `B/_codex/scripts/test_crm_interno.py`; `R/_codex/tests/crm-interno/{fixtures.sql,schema.sql,run.cfm}` |
| Publicação | `B/_codex/scripts/deploy_crm_interno.py`, `crm_release_database.py`, `crm_http_guards.py` |

### Achados que mudam a implementação

A prévia usa SQL com `email LIKE '%@%'`, enquanto a autorização usa `isValid('email', ...)`; não duplicar essa diferença no novo resumo por canal. A frequência é tratada também fora de `CrmPreferenceService`. A tarefa 1.1 consolida a classificação e conserva a trava transacional da entrega.

O histórico de acessos começou nesta implantação e é parcial. A idade depende de nascimento preenchido. Mostrar cobertura evita confundir ausência de dado com ausência de interesse.

O CRM `/crm/` já possui pessoas, participações e pedidos, com fronteiras de conta próprias. O CRM interno não deve copiar esse universo nem assumir que toda pessoa importada tem consentimento para campanha global.

## Protocolo de execução e publicação por fase

- [ ] Ler especificação, plano da fase, AGENTS/README dos dois repositórios e situação Git. Preservar o trabalho existente; não criar branch/commit.
- [ ] Registrar inventário somente de metadados e contagens agregadas. Confirmar permissões existentes sem alterá-las.
- [ ] Para regra de domínio, acrescentar a fixture sintética e executar o teste antes da implementação. UI simples deve ser verificada por comportamento, sem teste que apenas replique markup.
- [ ] Acrescentar os testes da fase ao runner existente, mantendo a guarda `current_database() == 'crm_test'`. Quando houver migration nova, executar duas vezes somente nesse banco. Os testes não usam `runner_dba` de produção.

```sh
# Executar a partir de B; os runtimes/serviços locais precisam estar disponíveis.
python3 _codex/scripts/test_crm_interno.py
node --check crm-interno/crm.js
```

- [ ] Verificar também cada novo módulo JS e os fluxos em desktop e 390px: público selecionado, ficha, modal, cancelar, voltar, erro e navegação por teclado.
- [ ] Revisar o manifesto de deploy antes de incluir novos arquivos: o publisher atual enumera explicitamente arquivos Business. Registrar hash anterior, backup e mudanças de schema da fase.
- [ ] Atualizar o runner/probe de migrations: o modo `migrate` atual é de instalação inicial e recusa schema CRM existente; não reutilizá-lo para evoluções. Criar `B/_codex/scripts/crm_evolution_database.py` com allowlist de migrations da fase, modo somente verificação e aplicação aditiva versionada. Documentar cada aplicação no recibo, sem executar DDL arbitrário vindo do cliente.
- [ ] Aplicar DDL aditiva antes dos consumidores; publicar serviço RoadRunners antes da UI Business. Novos jobs permanecem desativados até smoke de leitura e confirmação de idempotência; sua ativação faz parte da entrega da fase autorizada, não dispara campanhas.

```sh
python3 _codex/scripts/deploy_crm_interno.py prepare
# Continuar somente após baseline, backup e compilação nativa aprovados.
python3 _codex/scripts/deploy_crm_interno.py publish
python3 _codex/scripts/deploy_crm_interno.py verify
python3 _codex/scripts/crm_http_guards.py
```

- [ ] Não desligar o CRM inteiro por conveniência. Em falha, desativar apenas a capacidade/job novo e restaurar os arquivos da release; conservar schema aditivo e histórico.
- [ ] Atualizar `B/docs/crm-interno-operacao.md` e gravar recibo de fase com testes, tempos medidos, migration, arquivos, backup e verificação real. Nenhuma campanha é enviada como teste.

## Primeiro incremento a executar

Fase 1, tarefa 1.1: resumo de elegibilidade do público selecionado, apoiado em uma classificação comum para contagem, revisão e entrega. Depois, ficha lateral e cobertura. Isso entrega uma melhora útil antes de introduzir novas tabelas de oportunidades.

## Estado deste plano

Fases 1, 2 e 3 implementadas e publicadas com testes, backups e verificação real; recibos em `.superpowers/sdd/2026-09-24-crm-interno-evolucao/progress.md`. Tarefa 4.1 concluída: os pedidos importados do CRM não atendem aos pré-requisitos de atribuição. A trilha legada Pagar.me contém pagamento, moeda e estorno em JSON bruto, mas ainda não comprova origem/autenticidade nem vínculo inequívoco do comprador. Uma consulta autenticada ao provedor confirmou dez pedidos existentes; um deles já estava integralmente cancelado sem reversão armazenada, demonstrando a necessidade de conciliar o saldo atual. O preparo financeiro local reconhece somente pagamento e cancelamento integral e ainda não tem fonte real habilitada. Em resposta à oferta atual, R6 mede primeiro o início autenticado de inscrição no Todo Santo Dia; a especificação acima foi ajustada e a implementação publicada em 25/09/2026. A suíte `crm_test` passou com 233 verificações, o schema foi verificado em produção e o formulário autenticado exibe o objetivo. A fonte ainda não captou uma inscrição natural, e não há campanhas criadas para apurar atribuição real. Auditoria em `docs/crm-interno-conversoes-fonte.md`. Pagamento, valor e estorno continuam fora do relatório de campanhas até fonte comprovada.

### Fechamento revisado da R6

- [x] Instrumentar localmente o primeiro início autenticado de inscrição no Todo Santo Dia com evento imutável, deduplicação e cobertura a partir da ativação. O fluxo legado mantém fallback sem impedir inscrição se a captura falhar.
- [x] Fixar o objetivo `todosantodia_signup` na revisão da campanha, restringir o destino à página do desafio e atribuir somente último clique registrado elegível em sete dias. Sem clique, manter sem atribuição; nunca inferir receita.
- [x] Acrescentar ao relatório da campanha a contagem de inícios atribuídos com descrição explícita do que ela não confirma; validar no banco sintético e na UI local.
- [x] Aplicar a migração aditiva no RoadRunners, publicar serviço/fluxo/API e só depois a interface Business, com baseline, backup, compilação e verificação real. Nenhuma campanha de teste enviada.
- [ ] Conferir em produção a captação de uma inscrição natural após a ativação e o relatório autenticado. Se ainda não houver campanha com objetivo e clique real, o valor atribuído ficará zero até ocorrer; não fabricar evento.
