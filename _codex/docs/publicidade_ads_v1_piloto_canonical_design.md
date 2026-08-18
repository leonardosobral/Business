# Ads V1 — desenho do piloto canônico no Business

Data: 2026-08-18  
Status: aprovado e em implementação

## 1. Contexto e decisão

A Fase 1 já moveu os objetos legados de publicidade para o schema `ads` no PostgreSQL principal. As views temporárias em `public` continuam disponíveis para compatibilidade, mas o Business e o RoadRunners já foram ajustados para usar os objetos qualificados.

A fundação canônica Ads V1 e sua API administrativa SQL também já estão aplicadas no banco de produção `runnerhub`. Os contratos SQL e a auditoria compacta passaram. A operação continuará no schema `ads` do banco principal; banco dedicado, FDW e AWS não fazem parte deste ciclo e só voltam a ser considerados se o volume justificar.

O próximo incremento será um painel administrativo canônico no Business, separado do Turbinado legado. Ele permitirá validar o ciclo comercial e operacional da Ads V1 sem alterar a entrega atual de anúncios no RoadRunners e sem manter duas fontes de verdade por dual-write.

## 2. Objetivos

- Permitir que administradores operem campanhas Ads V1 pela interface do Business.
- Consumir exclusivamente a API SQL aprovada para mutações canônicas.
- Isolar o piloto do fluxo legado em `/ads/`.
- Validar criação, edição, crédito, ativação e mudança de status antes de ligar a entrega canônica no RoadRunners.
- Manter o Turbinado legado funcionando mesmo se a Ads V1 estiver indisponível.
- Deixar auditoria suficiente para identificar conta, operador e resultado de cada ação.

## 3. Fora de escopo

- Alterar a escolha ou a entrega de anúncios no RoadRunners.
- Fazer dual-write entre tabelas legadas e canônicas.
- Migrar campanhas, saldo ou histórico legado para a Ads V1.
- Remover views de compatibilidade em `public`.
- Criar banco dedicado, FDW, fila assíncrona ou infraestrutura AWS.
- Otimizar agora para cenários de alta concorrência. Esses testes ficam como gate futuro de escala, sem bloquear o piloto atual.
- Criar autosserviço para anunciantes. O primeiro corte é administrativo.

## 4. Limites de responsabilidade

### RoadRunners

O RoadRunners continua dono do schema, do DDL, das regras financeiras e dos contratos SQL de publicidade. As funções canônicas são a fachada estável consumida por outros sistemas.

### Business

O Business fornece a interface administrativa, resolve o contexto de conta e chama a fachada SQL. Ele não replica regras financeiras em CFML e não executa `INSERT`, `UPDATE` ou `DELETE` diretamente nas tabelas canônicas.

### Banco

O datasource utilizado será `runnerhub`, que conecta como `runner`. A role `runner` já possui, por meio das roles funcionais, os privilégios necessários para leitura, entrega e execução das funções permitidas. Nenhuma página do piloto utilizará o datasource `runner_dba`.

## 5. Estrutura do módulo

O piloto ficará em uma rota própria:

- `ads/canonical/index.cfm`: entrada do módulo, contexto global e composição da página.
- `ads/canonical/includes/backend.cfm`: autorização, readiness, leitura, validação e despacho das ações POST.
- `ads/canonical/includes/home.cfm`: interface do painel, formulários e mensagens.
- `ads/home.cfm`: inclusão de um acesso identificado como **Ads V1 Piloto**, sem substituir o fluxo legado.
- `_codex/scripts/audit_ads_v1_business_pilot_static.sh`: validações estáticas específicas do piloto.

O módulo seguirá os padrões atuais de layout, sessão, cabeçalho e contexto efetivo de conta do Business. A rota legada `/ads/` permanecerá com o comportamento atual.

## 6. Autorização e contexto de conta

O painel será restrito à identidade administrativa real indicada por `VARIABLES.businessRealIsAdmin`. O guard será local à rota canônica: `includes/backend/require_admin.cfm` usa `businessEffectiveIsAdmin`, que fica falso durante a simulação de conta e bloquearia incorretamente o administrador depois de ele escolher a conta. O guard compartilhado não será alterado.

Todas as leituras e ações exigem exatamente uma conta efetiva. O módulo usará `VARIABLES.businessEffectiveAccountIds` como fonte do escopo:

- com exatamente um ID válido, o painel opera essa conta;
- com nenhuma conta ou com o contexto global de todas as contas, o painel não executa leitura detalhada nem mutação e orienta o administrador a escolher/simular uma conta no seletor já existente;
- IDs recebidos por formulário ou URL nunca ampliam o escopo efetivo da sessão.

Antes de qualquer mutação, o backend confirma no banco que campanha, evento ou lançamento pertence à conta efetiva. A validação de escopo no Business complementa, mas não substitui, as validações das funções SQL.

## 7. Readiness da API SQL

Antes de oferecer ações, o painel verifica no PostgreSQL a existência e o direito de execução das funções:

- `ads.save_event_campaign`
- `ads.activate_campaign`
- `ads.change_campaign_status`
- `ads.credit_account`
- `ads.reverse_click_debit`

A verificação usa assinaturas resolvidas pelo PostgreSQL e `has_function_privilege(current_user, ..., 'EXECUTE')`; ela não depende de `search_path` nem de objetos em `public`.

Se uma função ou permissão estiver ausente:

- o painel canônico fica bloqueado para mutações;
- uma mensagem operacional informa que a API Ads V1 não está pronta;
- detalhes técnicos ficam apenas no log do servidor;
- o Turbinado legado continua acessível e inalterado.

## 8. Fluxos de dados

### 8.1 Visão da conta

O painel mostra, sempre filtrado pela conta efetiva:

- saldo canônico;
- campanhas por status;
- evento, anúncio e placement relacionados;
- orçamento total e diário, CPC e período;
- métricas diárias já agregadas;
- histórico financeiro e administrativo relevante.

Os números canônicos serão identificados explicitamente como Ads V1 e não serão somados aos números do Turbinado legado.

### 8.2 Criar ou editar campanha

O formulário permite selecionar somente eventos ativos vinculados à conta efetiva por `public.tb_conta_eventos` e `public.tb_evento_corridas`.

Campos do primeiro corte:

- evento;
- nome da campanha;
- CPC;
- orçamento total;
- orçamento diário;
- início e fim;
- dispositivo (`ALL`, `DESKTOP` ou `MOBILE`);
- país em código ISO de duas letras, inicialmente `BR`;
- região opcional.

O placement será fixo em `rr-home-upcoming-native`. O destino será derivado no servidor a partir do evento e da URL oficial do RoadRunners; não será aceito um destino arbitrário enviado pelo navegador.

A persistência usa somente `ads.save_event_campaign`. Edição será permitida apenas nos estados aceitos pelo contrato, inicialmente `DRAFT` e `PAUSED`.

### 8.3 Crédito manual

O administrador informa valor e justificativa. O Business chama `ads.credit_account` com:

- conta efetiva;
- moeda BRL;
- origem manual;
- operador autenticado;
- metadados com módulo, justificativa e identificador da requisição;
- chave idempotente única gerada no servidor para o formulário.

Reenvio do mesmo formulário preserva a mesma chave idempotente e não duplica crédito. Um novo crédito exige uma nova chave.

### 8.4 Ativação e mudança de status

- Ativar uma campanha `DRAFT` ou retomar uma campanha `PAUSED`: `ads.activate_campaign`.
- Pausar uma campanha `ACTIVE` ou finalizar uma campanha `DRAFT`, `ACTIVE` ou `PAUSED`: `ads.change_campaign_status`.

O Business não altera status diretamente. A interface exibe somente transições compatíveis com o estado atual; o banco continua sendo a autoridade final.

### 8.5 Estorno de débito CPC

O painel lista débitos elegíveis da conta que ainda não tenham estorno correspondente. O administrador informa o motivo e o Business chama `ads.reverse_click_debit` com uma chave idempotente gerada no servidor.

Não existe exclusão física de lançamentos ou campanhas pelo painel. Encerramento e correções são representados por status e lançamentos compensatórios.

## 9. Segurança e consistência

- Toda mutação usa `POST`; ações por `GET` não serão aceitas.
- Cada formulário mutável contém token CSRF mantido em sessão e validado antes do acesso ao banco.
- Toda entrada dinâmica em consulta usa `cfqueryparam`.
- O datasource é sempre `runnerhub`.
- O ID do operador vem da sessão autenticada, nunca do formulário.
- O ID da conta vem do contexto efetivo, nunca do formulário.
- Valores monetários são validados como positivos e normalizados para a escala esperada antes da chamada SQL.
- Datas são validadas no servidor, incluindo ordem do período.
- As funções SQL são chamadas com nomes e casts qualificados para evitar ambiguidade de assinatura.
- Após uma ação bem-sucedida, o fluxo usa Post/Redirect/Get para impedir reenvio acidental.
- Mensagens ao usuário não expõem SQL, stack trace, nomes de roles ou detalhes internos do banco.
- Falhas são registradas com ação, conta, campanha quando houver, operador e identificador de correlação, sem gravar segredos.

## 10. Interface

O acesso no Turbinado legado será um link secundário e claramente marcado como **Ads V1 Piloto**. Dentro do piloto haverá indicação persistente de que os dados são canônicos e separados dos dados legados.

A tela terá:

- resumo de saldo e campanhas;
- lista de campanhas com ações permitidas pelo estado;
- formulário de criação/edição;
- formulário de crédito manual;
- histórico financeiro e opção de estorno elegível;
- mensagens de sucesso, validação e indisponibilidade.

O layout seguirá os componentes e breakpoints existentes no Business. A primeira versão prioriza operação segura e clareza, sem redesenhar o módulo inteiro.

## 11. Tratamento de falhas e fallback

- Falha de readiness: nenhuma mutação fica disponível; o legado continua funcionando.
- Falha de validação: nenhuma função é chamada e o formulário retorna mensagens específicas.
- Falha SQL: a função mantém a atomicidade, o Business registra o erro e apresenta uma mensagem genérica.
- Resultado idempotente: a interface trata a repetição como sucesso já processado, sem criar um segundo efeito.
- Falha parcial de renderização: nenhuma ação POST é repetida automaticamente.
- Não há fallback por dual-write. O fallback operacional é continuar usando o módulo legado até o RoadRunners entrar em shadow mode e o piloto canônico ser aprovado.

## 12. Validação

### 12.1 Validação estática

O script de auditoria deverá confirmar:

- ausência de `runner_dba` nos arquivos do piloto;
- uso do datasource `runnerhub`;
- chamadas às cinco funções com schema `ads`;
- ausência de DML direto nas tabelas canônicas;
- ausência de mutações acionadas por `URL`/`GET`;
- presença de validação CSRF nas ações POST;
- parametrização das entradas dinâmicas;
- ausência de dependência das views temporárias em `public`.

Também serão executadas as verificações estáticas já disponíveis no Business e `git diff --check`.

### 12.2 Smoke test manual

Em produção, usando uma conta controlada e sem cliente pagante:

1. Confirmar que administrador global sem conta selecionada recebe orientação e não consegue mutar dados.
2. Selecionar uma conta e conferir saldo, campanhas e histórico.
3. Criar uma campanha em `DRAFT` para um evento da conta.
4. Editar a campanha em `DRAFT`.
5. Creditar um valor mínimo controlado e repetir a mesma submissão para validar idempotência.
6. Ativar a campanha, pausar e finalizar conforme as transições permitidas.
7. Se houver débito CPC de teste, estorná-lo e confirmar que o segundo envio não duplica o estorno.
8. Conferir no banco e no audit canônico que conta, saldo, ledger, campanha e histórico permanecem reconciliados.
9. Confirmar que `/ads/` e a publicidade legada do site continuam operando.

O piloto administrativo não implica que a campanha canônica será entregue no site; isso só ocorrerá na etapa posterior do RoadRunners.

## 13. Deploy e rollback

Pré-condições já atendidas:

- foundation canônica aplicada em `runnerhub`;
- API administrativa aplicada;
- contract tests aprovados;
- auditoria compacta com `PASS`;
- `runner` com `ads_reader`, `ads_delivery` e `ads_business`.

Pré-condição identificada durante a implementação:

- aplicar `RoadRunners/_codex/sql/2026-08-18_ads_v1_business_read_grants.sql` para conceder à role `ads_business` somente `SELECT` em `ads.account_balances`, `ads.campaign_budget_state` e `ads.credit_ledger`. Sem esse incremental, o painel permanece bloqueado pelo readiness e o legado não é afetado.

Ordem deste incremento:

1. Implementar e validar localmente o painel no Business.
2. Aplicar e conferir o incremental mínimo de leitura financeira.
3. Publicar os arquivos do Business.
4. Executar o smoke test com conta controlada.
5. Observar logs e reconciliação canônica.
6. Só depois elaborar e executar o incremento separado de shadow mode no RoadRunners.

Rollback do painel:

- ocultar/remover o link **Ads V1 Piloto** e retirar a rota publicada;
- preservar todos os dados canônicos já criados;
- finalizar campanhas de teste pela função de status, se necessário;
- não reverter a foundation nem a API SQL, pois elas permanecem aditivas e não interferem no legado.

## 14. Etapa seguinte: RoadRunners shadow mode

O shadow mode será um incremento independente. Ele deverá ler campanhas canônicas elegíveis e comparar a seleção canônica com a escolha legada, sem exibir a canônica ao usuário e sem cobrar CPC. House ads serão o primeiro tráfego exibido quando a observação do shadow mode estiver estável.

Concorrência pesada, banco dedicado e infraestrutura AWS permanecem gates futuros de escala, não requisitos para iniciar o piloto com o volume atual.

## 15. Alternativas descartadas

### Substituir imediatamente o Turbinado legado

Descartado porque mistura validação administrativa, entrega, cobrança e migração de dados em um único corte, ampliando desnecessariamente o risco.

### Fazer dual-write legado/canônico

Descartado porque cria duas fontes de verdade, exige reconciliação contínua e pode duplicar saldo, campanha ou cobrança.

### Integrar primeiro a entrega no RoadRunners

Descartado porque o painel administrativo oferece um caminho mais controlado para validar os contratos canônicos antes de servir tráfego real.

## 16. Critério de conclusão

Este incremento estará concluído quando:

- o painel canônico estiver acessível somente a administradores e sempre limitado a uma conta efetiva;
- as cinco operações SQL aprovadas forem consumidas sem DML canônico direto;
- criação, edição, crédito, ativação, status e estorno passarem nos testes aplicáveis;
- idempotência, CSRF e Post/Redirect/Get estiverem validados;
- o audit estático passar;
- a reconciliação canônica permanecer válida após o smoke test;
- o módulo legado continuar operando sem alteração funcional.
