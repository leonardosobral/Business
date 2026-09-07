# Revisão Ads e banners — gate de rollout

Data: 04/09/2026, noite, America/Sao_Paulo. Consultas no servidor já registram 05/09 em UTC.

## Decisão

**Não liberar a expansão comercial ainda.** Há cinco bloqueadores de prioridade P1: identidade autenticada controlável por cookie, revisão que pode aprovar um evento e entregar outro, ativação SQL sem aprovação, saída HTML insegura no formulário de banners e cobrança CPC sem proteção contra acessos automatizados ao link.

Isso não significa que a entrega esteja parada ou que o histórico financeiro esteja perdido. A campanha do Avaí está sendo veiculada; a amostra reconciliada fecha entre eventos, métricas e débitos. O trabalho antes do rollout deve proteger esse funcionamento e completar os cenários de aprovação e responsividade.

Esta revisão foi **somente leitura do runtime e do banco**. Não houve aprovação, pausa, edição de campanha, resgate, compra, clique cobrado, migração ou deploy. Foram adicionados apenas este documento e a consulta de diagnóstico. As navegações públicas normais podem gerar entregas/impressões, mas não cliques pagos.

## Escopo e força da evidência

- Business: autenticação e contexto de conta; onboarding pendente; eventos vinculados; vouchers; criação, edição e revisão de campanha; painel, detalhe e métricas; pagamentos; administração de banners HOUSE.
- RoadRunners: consumidores e placements; leilão e segmentação; render nativo e banners responsivos; impressão visível e clique; funções SQL, locks, idempotência e permissões.
- Quatro frentes independentes de revisão, com conferência dos caminhos críticos na consolidação.
- Código analisado é o estado atual dos dois diretórios, incluindo alterações preexistentes. Não foi criada outra branch/worktree.
- Evidência estática não equivale a exploração ou E2E. Cada achado abaixo distingue código, reprodução local e observação em produção.
- Não houve teste de invasão, simulação de identidade administrativa ou payload XSS em produção.

## 1. Bloqueadores antes de ampliar clientes

### R01 — P1: cookie numérico é tratado como identidade autenticada

**Business.** `includes/backend/backend_login.cfm:70–114` consulta o usuário, incluindo `is_admin`, usando `COOKIE.id`. O contexto de conta e `ads/includes/access.cfm:36–44` passam a confiar nesse perfil. O ID literal é gravado no login, em `backend_login.cfm:470`; não há verificação de sessão autenticada ou assinatura nesse caminho. `Application.cfc:155–226` não acrescenta esse controle.

Impacto: se um cliente enviar o ID de outro usuário elegível, o código pode assumir seu contexto; com um ID administrativo, afeta revisão global, vouchers e HOUSE. A autorização dentro de Ads não compensa uma identidade de entrada falsificável.

**Evidência:** caminho completo no código; arquivos de login/contexto têm o mesmo SHA-256 local e em produção. O `Application.cfc` de produção também foi lido e não contém gate adicional de autenticação nesse caminho. Não foi verificado um eventual controle externo de infraestrutura, nem executada impersonação.

**Gate:** vincular o ator a uma sessão autenticada no servidor ou credencial verificável, invalidável e não baseada em ID fornecido pelo cliente. Em homologação, cookie `id` isolado deve resultar em login/401; trocar o ID não pode mudar usuário ou privilégios. Cobrir sessão Google nova, existente, expirada, revogada e usuário de outra conta.

### R02 — P1: evento da revisão pode divergir do evento veiculado

**Business + SQL canônico.** `ads/includes/backend.cfm:1558` permite editar `WAITING_PREREQUISITES`. `save_pending_event_campaign`, em `_codex/sql/2026-08-24_ads_pending_onboarding.sql:821`, troca `advertisements.core_event_id` sem atualizar/cancelar a revisão já enviada. O refresh e a decisão consultam o `core_event_id` antigo da revisão, enquanto a entrega usa o evento atual do anúncio.

Sequência reproduzível pelo fluxo normal:

1. Conta pendente solicita os eventos A e B.
2. Cria campanha de A e envia; fica aguardando pré-requisitos.
3. Edita o rascunho para B, sem novo envio.
4. A equipe aprova conta e vínculo A.
5. A fila apresenta A, mas a aprovação pode ativar o anúncio de B, cujo vínculo segue pendente.

Evidências complementares: `_codex/sql/2026-08-25_ads_refresh_campaign_review_permission.sql:63`; fila em `ads/includes/backend.cfm:381`; revisão em `2026-08-24_ads_pending_onboarding.sql:1311`; `RoadRunners/_codex/sql/2026-07-26_ads_v1_canonical_foundation.sql:1516`, onde ativar valida o evento no catálogo, não a igualdade com a revisão nem seu vínculo com a conta.

**Evidência:** trace estático concordante entre as revisões Business e financeira. Migrações relevantes constam no registro de produção; a sequência não foi executada no banco real.

**Gate:** edição material deve invalidar/sincronizar a revisão atomicamente. Aprovação e ativação precisam confirmar conta, evento atual do anúncio, vínculo e versão efetivamente analisada. Teste de regressão A→B obrigatório, em ambas as ordens de aprovação.

### R03 — P1: aprovação global não é invariável da API SQL

**RoadRunners, contrato compartilhado com Business.** `ads.activate_campaign(uuid,integer,text)` aceita DRAFT/PAUSED elegível sem conferir revisão global nem autoridade do ator. O grant em `_codex/sql/2026-08-18_ads_v1_admin_api.sql:659` permanece disponível ao papel de runtime. O guard de status não resolve: a própria função habilita a transição.

**Evidência adicional em produção:** SELECT de `has_function_privilege('runner', ... , 'EXECUTE')` retornou `true`; a definição implantada não referencia `campaign_review_requests`. A UI atual usa `review_campaign`; **não foi demonstrado bypass HTTP direto**. O problema está no contrato disponível às integrações/runtime.

**Gate:** tornar a ativação interna ao caminho autorizado ou exigir os mesmos invariantes de revisão/ator na função. Teste com papel `runner`: chamada direta não pode ativar rascunho sem aprovação; revisão global legítima deve continuar funcionando; retomada e HOUSE devem ter regras explícitas.

### R04 — P1: formulário HOUSE reflete entrada sem escape após erro

**Business.** `portal/banners/home.cfm:216,220,230,234,269,273,277,281` imprime valores de `FORM.*` sem escape em atributos HTML. Token inválido gera exceção de validação em `portal/includes/banner_management_backend.cfm:209`, mas o catch na linha 530 retorna ao formulário, que ecoa esses valores.

Impacto: conteúdo que feche o atributo pode injetar HTML/JavaScript na página administrativa. Um token CSRF inválido não elimina o risco porque a saída de erro ainda é renderizada. A entrega do POST a uma vítima e execução concreta dependem também das políticas de navegador/CSP.

**Evidência:** código e paridade de arquivos em produção; nenhum payload foi enviado. Campos de texto já usam escape, mas os numéricos/datas não.

**Gate:** escape contextual em toda saída, inclusive erro; validação de tipo no servidor não substitui escape. Testar valores malformados com token válido e inválido e comprovar que aparecem apenas como texto/valor inerte.

### R05 — P1: scanner/prefetch pode gerar clique faturável

**RoadRunners.** O filtro recente de bots está na criação da delivery. `api/ads/v1/cpc-click.cfm:44–65` aceita GET com IDs/token válidos e chama cobrança sem filtro de bot/prefetch. O SQL valida token, tempo, saldo, orçamento e duplicidade, mas não diferencia esse acesso automatizado de interação do usuário.

Impacto: scanner que receba um link válido de uma entrega humana pode consumir o primeiro clique daquela delivery. Não é prova de que os seis cliques atuais sejam bots. A idempotência limita a cobrança a uma vez por delivery, mas não valida a qualidade do primeiro acesso.

**Evidência:** endpoint implantado igual ao local e trace SQL; não foram disparados cliques/scanners reais.

**Gate:** excluir acessos automatizados conhecidos e prefetch antes do débito, preservar redirect seguro, registrar motivo de rejeição e cobrir link scanner, retry e clique humano. Não exigir cegamente impressão de 1s para todo clique: um usuário legítimo pode clicar antes disso. A política de qualidade precisa ser explícita.

## 2. Ajustes P2 antes do rollout pleno

| ID | Problema e impacto | Evidência / gate |
|---|---|---|
| R06 | Aprovar o evento antes da conta interrompe salvar/enviar campanhas, mesmo que a UI mostre o evento disponível. | `save_pending_event_campaign` exige vínculo e solicitação PENDENTE (`2026-08-24_ads_pending_onboarding.sql:639`); aprovação os transforma em ATIVO/APROVADA. Corrigir e testar ambas as ordens de aprovação. |
| R07 | Aprovação/recusa de cadastro não valida CSRF. | `administracao/contas/includes/backend.cfm:294` autoriza owner/admin, mas não confere token/origem. Testar POST sem token e de origem irmã; cookies/SameSite influenciam exploração. |
| R08 | Impressão visível pode contar tempo com a aba oculta. | `RoadRunners/includes/ads_v1/viewability.cfm:88–105`. Reprodução Node/VM com o JS real emitiu beacon após ocultar documento. Pausar/reiniciar temporizador por visibilidade; confirmar em navegador real. Sem cobrança por impressão. |
| R09 | “Página do evento” não corresponde ao alcance real do placement lateral. | `Business/ads/home.cfm:13,24` versus sidebar comum de home, busca, estado e evento. Renomear como lateral do site ou restringir rotas; documentar que hoje é apenas para logados. |
| R10 | Há combinações de campanha/layout sem possibilidade de exibição. | MOBILE + somente `rr-sidebar-event-native` é aceito, mas sidebar fica oculta abaixo de 992px. HOUSE móvel termina em 767,98px, deixando 768–991px sem as duas versões. `home_sidebar_mobile_banner_slot.cfm:42,57`; `home_sidebar_async_slot.cfm:121`; `evento/index.cfm:622`. Corrigir breakpoints/eligibilidade e testar 390, 820, 1280 e 1440px. |
| R11 | Reconciliação pode repetir o mesmo lote antigo e represar pagamentos posteriores. | `RoadRunners/2026-08-21_ads_phase2_payments.sql:1733` ordena por `updated_at`, LIMIT25/30; `AdsPaymentService.cfc:600` e transição SQL PENDING repetida não avançam o timestamp. Usar agendamento justo/cursor/next-check; testar mais que um lote e webhook perdido. Não há backlog atual observado. |

Outras limitações para registrar no produto:

- Home impede repetir a mesma **campanha**, não o mesmo **evento**. Duas campanhas do mesmo evento podem ocupar 1º e 2º spots. Decidir se a deduplicação deve ser por evento antes de incentivar múltiplas campanhas do mesmo organizador.
- Frequency cap não é exposto no Business; se configurado diretamente, identidade NULL na seleção CPC torna a campanha inelegível. Não prometer controle de frequência nesta versão.
- A sidebar ainda depende de `cpcCampaignIds` não vazio, embora o conteúdo desse array não restrinja os candidatos. O ID legado de piloto está presente em produção; limpar essa configuração isoladamente pode desligar o CPC lateral.
- Upload HOUSE confere extensão/URL, mas não ficou demonstrada validação do conteúdo binário como imagem. Incluir arquivo inválido/corrompido na homologação.
- Documentos antigos, como `docs/portal-banners.md`, descrevem tabelas/contadores legados; não devem ser usados como manual comercial da versão canônica.

## 3. Spots e condições reais

| Opção comercial | Placement técnico | Comportamento atual |
|---|---|---|
| Página inicial | `rr-home-upcoming-native` + `rr-home-upcoming-native-secondary` | Dois espaços nativos; seleção ordenada por leilão. A mesma campanha não repete na segunda posição. |
| Busca de eventos | `rr-search-events-native` | Resultado patrocinado na busca, com contexto de UF disponível. |
| Eventos por estado | `rr-state-events-native` | Patrocinado da lista estadual; filtro regional participa da elegibilidade. |
| Hoje chamada “Página do evento” | `rr-sidebar-event-native` | Sidebar compartilhada entre rotas, somente logados e visível em desktop; ver R09/R10. |
| Banner HOUSE | `rr-sidebar-banner-300x250` | Criativo próprio da plataforma, desktop/mobile; não é EVENT/CPC e não consome saldo por clique. Ver faixa de tablet em R10. |

Os cinco placements CPC e o HOUSE acima estão habilitados no arquivo operacional de produção. Isso não ativa toda campanha: ainda dependem de status, período, placement/vínculos elegíveis, criativo/evento ativo, segmentação, saldo, orçamento e ausência de bloqueio financeiro.

O contrato de negócio exige ainda conta, vínculo e anúncio aprovados. R02/R03 mostram por que esses requisitos precisam ser garantidos no caminho SQL final, não somente no formulário.

Ranking atual: lance CPC multiplicado por fator regional; contexto regional e lance influenciam a ordem. Quando há concorrente, o preço considera o próximo score e o fator do vencedor, respeitando piso/teto. Sem concorrente, o piso observado no código é R$ 0,51. Lance de R$ 0,94 não significa que todo clique custará R$ 0,94, nem garante a primeira posição em qualquer contexto.

## 4. Evidência em produção nesta revisão

### Campanha Avaí

ID: `31512d2e-f0bb-40e3-9600-dd1ddfcaca37` — Grupo STC.

- Painel administrativo: ativa, aprovada, segmentação SC, todos os dispositivos, lance R$ 0,94, orçamento R$ 100,00.
- Navegação real em `/estado/sc/`: card nativo “Patrocinado” do Avaí presente e apontando ao endpoint CPC. Banner HOUSE Avaí também apareceu na sidebar, com endpoint separado; não foram confundidos.
- Consulta posterior ao painel: **392 entregas, 64 impressões visíveis, 6 cliques** tanto em `daily_metrics` quanto nos eventos brutos.
- Ledger: **6 débitos, R$ 3,06, zero estornos**. CPC médio R$ 0,51; CTR 9,375% (9,38% arredondado).
- O painel tinha 391 entregas antes da consulta; ocorreu uma nova entrega entre leituras. Não há evidência atual de agregado travado.

Entrega é o recibo do servidor; impressão requer medição visível. Portanto a diferença 392/64, por si só, não é contagem financeira perdida. Não foi feito backfill de impressões históricas e R08 ainda precisa ser corrigido.

### Invariantes financeiros consultados

- Divergências entre saldo canônico e soma do ledger: **0**.
- Deliveries com mais de um débito CLICK: **0**.
- Payment intents PAID sem referência de ledger: **0**.
- Intenções de pagamento: **1 PAID e 15 EXPIRED** no momento da leitura.
- Job 12 de reconciliação: ativo, intervalo de 5min, último status `success`.
- Job 9 de métricas: ativo, intervalo de 60min, último status `success`. Esse job é do agregado **legado**; métricas canônicas são atualizadas pelo caminho transacional (`apply_metric_delta`), não dependem desse refresh.

Essas verificações são uma amostra de integridade, não teste de carga/concurrency nem prova de que nenhum acesso inválido foi classificado como clique legítimo.

### Logs de delivery de 04/09, até a coleta noturna

| Família | Amostra | Resultado |
|---|---:|---|
| CPC | 7.770 registros | 4.613 `filtered_traffic`, 3.030 `no_candidate`, 127 `served`; nenhum `errorStage` preenchido |
| HOUSE banner | 2.437 registros | 2.437 `served`; nenhum `errorStage` preenchido |

Das 127 entregas CPC: 46 home principal, 80 estado e 1 busca. P95 registrado das chamadas servidas: 19ms CPC e 14ms banner. São tempos do serviço no log, **não** tempo total da página nem teste de capacidade. Não houve entrega da segunda posição/sidebar nessa amostra; isso não prova falha, pois a elegibilidade e concorrência podem deixá-las sem candidato.

### Paridade de publicação

- **25 arquivos comparados com SHA-256 coincidem**: 15 Business (incluindo login/contexto, Ads, JS, pagamentos e HOUSE) e 10 RoadRunners (serviços, render, tracking e settings).
- `Business/Application.cfc` diverge; leitura do servidor mostrou configuração adicional de Trello, mas o mesmo caminho de request sem gate de identidade. Preservar essa diferença: **não substituir o arquivo inteiro por uma cópia local no rollout**.
- Migrações de onboarding, refresh de revisão, edição aprovada, revisão/admin e ranking constam no registro do banco. Não foi usado o registro de migrations como substituto de validar todas as funções/ACLs.

## 5. Testes executados e limites

Passaram os contratos estáticos de:

- Business: pending onboarding access/campaigns/approvals/schema; acesso Ads; conta existente; edição aprovada; serviços, endpoints, observabilidade e reconciliação de pagamentos; performance; detalhe individual; layout compacto da visão geral/campanhas.
- RoadRunners: CPC CFML; native service/render; HOUSE/banner render; financial canary; webhook legado; datasource runtime (`runnerhub`, sem `runner_dba` no Ads).
- Business JS: wizard, símbolos ColdFusion e HTTPS de banner (**16 testes**) + dashboard de performance (**5 testes**).
- RoadRunners JS: regressão DOM-ready do viewability. Reprodução adicional confirmou o problema de aba oculta.

**Uma falha da suíte:** `test_ads_global_vouchers.sh` espera uma lista literal antiga de views. `campaign-detail` foi acrescentado e `vouchers` continua permitido. É teste obsoleto, não prova de que o voucher parou. Atualizar a expectativa sem remover a cobertura.

Não executados nesta revisão:

- Contracts SQL com fixtures, testes de concorrência e criação de campanhas de teste.
- Pagamentos reais, chargeback/reembolso e teste de webhook perdido em lote.
- Exploração de auth/CSRF/XSS em produção.
- Matriz visual completa desktop/tablet/mobile, guest/logado e isolamento entre contas.
- Novo cadastro completo com Google, aprovação em todas as ordens e uso de voucher até anúncio aprovado.

Os testes shell em grande parte procuram padrões; podem passar enquanto o fluxo integrado está errado. O exemplo concreto é verificar que `access.cfm` não lê cookies e deixar passar o perfil vindo de `backend_login.cfm`.

## 6. Ordem proposta para preparar a próxima semana

### Gate A — segurança e autoridade

1. R01: autenticação real e testes de isolamento por ator/conta.
2. R04 e R07: saída segura e CSRF também nos caminhos administrativos de cadastro.
3. R02/R03: uma única verdade entre anúncio, revisão, vínculo e ativação; testes de API SQL e UI.

### Gate B — dinheiro e conclusão da jornada

4. R05: classificação de clique automatizado antes do débito; retry humano idempotente.
5. R06/R11: aprovação em qualquer ordem e reconciliação justa de mais de um lote.
6. E2E em homologação: cadastro novo e CNPJ existente → pedido de evento → reserva R$100 → draft → aprovações → aplicação única do voucher → revisão global → entrega → um clique controlado → reconciliação → pausa/edição/nova revisão.

### Gate C — alcance e confiança na medição

7. R08–R10: aba oculta, escopo lateral, combinações de dispositivo/placement e faixa tablet.
8. Matriz obrigatória: 390/820/1280/1440px; guest/logado; SC/RJ/sem UF; home1/home2/busca/estado/lateral/HOUSE; orçamento esgotado, período futuro/encerrado, saldo insuficiente e conta/evento bloqueados.
9. Confirmar as informações canônicas do evento usado na campanha, inclusive data, imagem e destino. O anúncio nativo herda esses dados.

### Gate D — publicação e operação assistida

10. Gerar manifesto fechado dos arquivos e migrations de correção. Ordem: SQL compatível + grants/contratos; Business; consumidores RoadRunners; smoke test e logs. Não reaplicar toda a foundation canônica.
11. Reexecutar contratos, negativos de autorização, concorrência e a consulta read-only anexa. Validar funções efetivas, não só nomes das migrations.
12. Liberar um lote pequeno de organizadores e campanhas com orçamento limitado, depois ampliar com evidência. Definir responsável pela fila de aprovação, atendimento e reconciliação.
13. Transformar o fluxo homologado em manual do comercial: “preparar agora, efetivar após aprovação”; explicar reserva versus saldo, revisão do anúncio, prazo da campanha, lance versus CPC efetivo, impressões versus entregas e onde acompanhar resultados. Não prometer alcance/posição garantida.

### Rollback e sinais para interromper a expansão

- Qualquer acesso cruzado, ativação sem revisão, saldo divergente, débito duplicado ou clique automatizado faturado bloqueia o gate.
- Para interrupção da entrega: usar as flags operacionais e/ou pausa das campanhas autorizadas. Preservar deliveries, eventos, métricas e ledger para diagnóstico.
- Para incidente em compras: impedir novas compras sem desligar webhooks/reconciliação de pagamentos já iniciados.
- Não apagar dados, desfazer ledger manualmente ou reverter migrations financeiras como primeiro mecanismo de rollback.
- Validar esse procedimento em homologação antes da liberação. Nenhuma dessas ações foi executada nesta revisão.

## Arquivos entregues

- Este relatório, com findings, cobertura e gates.
- `_codex/sql/2026-09-04_ads_rollout_readiness_audit.sql`: SELECT de diagnóstico reutilizável, correspondente à consulta executada. **Não é migration.**

Nenhum código de aplicação foi modificado. Nenhum commit ou deploy foi feito.
