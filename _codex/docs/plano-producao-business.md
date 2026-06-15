# Plano de Producao - Road Runners Business

Este plano consolida o caminho para levar o Business a producao com foco inicial no cadastro externo de empresas, aprovacao administrativa, contas, usuarios e operacao basica de ads/cupons.

## Objetivo do primeiro corte

Permitir que uma empresa solicite acesso pela area nao logada, entre em uma fila de aprovacao para o admin, seja associada a uma conta Business e passe a operar com dados restritos a essa conta.

O primeiro corte nao deve resolver todo o BI. O BI deve continuar controlado por permissoes manuais ate a decisao de permissao por conta ficar madura.

## Estado atual

- O modelo novo de contas esta em `tb_contas`, `tb_conta_usuarios`, `tb_conta_eventos` e `tb_conta_evento_solicitacoes`.
- O vinculo conta-evento ja tem fluxo de solicitacao em `/eventos/`.
- Admin consegue simular uma conta pelo seletor do topo.
- `ads`, `inscricoes` e `cupons-rr` ja possuem restricoes por eventos da conta.
- O `/cadastro` foi recriado como fluxo publico de solicitacao Business, gravando em `tb_conta_cadastro_solicitacoes`.
- O `/usuarios` foi aposentado como modulo ativo e redireciona para `/administracao/contas/`.
- A area `/administracao/contas` e o ponto mais adequado para evoluir a gestao de contas, usuarios e solicitacoes.

## Fluxo alvo

1. Usuario acessa `/cadastro/` sem estar logado.
2. Preenche dados da empresa, responsavel, email, telefone, tipo de prestador e mensagem.
3. Sistema grava uma solicitacao pendente em `tb_conta_cadastro_solicitacoes`.
4. Admin acessa `/administracao/contas/` e ve solicitacoes pendentes.
5. Admin aprova ou recusa.
6. Ao aprovar, admin cria uma nova `tb_contas` ou associa a uma conta existente.
7. Sistema vincula o responsavel como `OWNER` em `tb_conta_usuarios`.
8. Usuario faz login pelo Google e passa a acessar a area logada como usuario da conta.
9. `OWNER` ou `ADMIN` da conta pode convidar/gerenciar usuarios da propria conta.
10. Operacoes de ads e cupons usam apenas eventos ativos em `tb_conta_eventos`.
11. Se a conta precisar de um evento que ainda nao esta vinculado, usa a solicitacao em `/eventos/`.

## Permissoes por papel

- `OWNER`: gerencia usuarios da conta, solicita eventos, cria ads/cupons, visualiza dados da conta.
- `ADMIN`: gerencia usuarios da conta, solicita eventos, cria ads/cupons, visualiza dados da conta.
- `OPERADOR`: cria/edita operacoes permitidas, mas nao gerencia usuarios.
- `VISUALIZADOR`: somente leitura.
- `is_admin` interno continua podendo ver tudo, mas quando simula uma conta deve ser tratado como usuario efetivo daquela conta.

## Fases de implementacao

### Fase 1 - Base de cadastro externo

- Criar DDL de `tb_conta_cadastro_solicitacoes`.
- Recriar `/cadastro/` como pagina publica de solicitacao.
- Remover dependencia de `tb_fornecedores` no cadastro externo.
- Validar campos obrigatorios e duplicidade simples por documento/email pendente.

### Fase 2 - Aprovacao admin

- Adicionar bloco de solicitacoes em `/administracao/contas/`.
- Permitir aprovar criando uma conta nova.
- Permitir aprovar associando a uma conta existente.
- Vincular o responsavel como `OWNER`.
- Permitir recusar com observacao.

### Fase 3 - Gestao de usuarios da conta

- Adicionar flags de papel efetivo em `business_account_context.cfm`.
- Restringir gestao de usuarios a `OWNER`, `ADMIN` e admin interno real.
- Aposentar `/usuarios/` como modulo ativo e manter apenas redirect para a gestao de contas.
- Criar fluxo de convite por email se necessario.

Status em 2026-06-09:

- `business_account_context.cfm` calcula contas efetivas de leitura, operacao e gestao por papel.
- `/administracao/contas/` permite que `OWNER`/`ADMIN` da conta adicionem usuarios por nome/e-mail e papel.
- O vinculo criado por esse fluxo fica `ATIVO` no MVP, pois ainda nao ha tela de aceite de convite.
- Usuarios de conta sem papel de gestao consultam os vinculos, mas nao alteram usuarios.
- Alterar/remover `OWNER` continua reservado ao admin interno.
- `/usuarios/` ficou apenas como redirect de compatibilidade para `/administracao/contas/`; a implementacao antiga foi arquivada em `_legado/usuarios/`.
- `/admin/` ficou apenas como redirect de compatibilidade para `/eventos/`; a implementacao antiga foi arquivada em `_legado/admin/`.
- `/inscricao/` ficou apenas como redirect de compatibilidade para `/cadastro/`; a implementacao antiga foi arquivada em `_legado/inscricao/`.

### Fase 4 - Operacao Business

- Revisar `/ads/` para garantir criacao apenas em eventos ativos da conta.
- Separar `/cupons-rr/` da logica antiga de campanhas de ads.
- Revisar `/inscricoes/`, removendo evento TicketSports hardcoded.
- Garantir mensagens claras quando a conta nao tem eventos aprovados.

Status em 2026-06-09:

- `backend_login.cfm` entrega `qEventosConta` para leitura e `qEventosContaOperacao` para escrita por papel.
- `/ads/`, `/inscricoes/` e `/cupons-rr/` bloqueiam POST/URL de escrita para quem nao e admin efetivo nem possui papel `OWNER`, `ADMIN` ou `OPERADOR` na conta.
- `/ads/` lista no seletor de criacao apenas eventos ativos de contas operaveis.
- Usuarios `VISUALIZADOR` continuam podendo consultar dados da conta, mas nao veem formularios/acoes de edicao nessas telas.
- `/inscricoes/` ainda usa `cod_evento` TicketSports hardcoded (`72611`) por decisao consciente do MVP. Esse modulo deve ser refatorado inteiro em etapa futura para mapear evento Road Runners -> evento TicketSports e virar multi-evento.
- `/cupons-rr/` ainda conserva partes de formulario/backend reaproveitadas de campanha de ads; precisa ser separado em CRUD proprio de cupom antes de producao ampla.

### Fase 5 - BI

- Manter `tb_permissoes` por usuario no MVP.
- Definir depois se BI sera liberado por conta, usuario ou ambos.
- Se for por conta, criar uma tabela propria de permissao por conta e derivar permissoes efetivas.

### Fase 6 - Producao

- Remover dumps/debugs visiveis do login.
- Tirar credenciais hardcoded do codigo.
- Garantir que todos os arquivos novos estejam versionados.
- Validar protecao por URL direta nas rotas admin.
- Executar smoke test:
  - cadastro publico;
  - aprovacao admin;
  - login do owner;
  - convite/vinculo de usuario;
  - solicitacao de evento;
  - criacao de ad/cupom;
  - tentativa de acessar dados de outra conta.

Status em 2026-06-14:

- SQL de grants complementares rodado: `_codex/sql/2026-06-09_tb_contas_business_grants.sql`.
- Teste manual de cadastro, aprovacao e vinculacao de conta passou no ambiente.
- `/inscricoes/` permanece intencionalmente com `cod_evento = 72611` ate a refatoracao completa do componente.
- Dumps/debugs visiveis dos fluxos centrais de login/eventos foram removidos.
- Credenciais hardcoded removidas dos pontos centrais encontrados:
  - `RR_EVENTO_API_TOKEN` passa a alimentar chamadas antigas de `/api/Evento.cfc` e links de Strava/Desafios.
  - `RR_MANDRILL_USERNAME` e `RR_MANDRILL_PASSWORD` passam a alimentar `crm/EmailSenderService.cfc` e `emailmkt/EmailSenderService.cfc`.
  - `RR_PUSH_PUBLIC_KEY` e `RR_PUSH_PRIVATE_KEY` devem alimentar PWA push em producao.
  - Enquanto o ambiente de teste nao tiver variaveis de ambiente, `config/business.local.cfm` fornece fallback local para esses valores. O arquivo segue ignorado por `config/*.local.cfm`.
- Modulos isolados sem link no menu Business foram arquivados em `_legado/`: `elite-supra/` da raiz e `racetag/`.
- Ainda existe `debug=true` em links legados de BI/Desafios/Strava, mas sem token literal no codigo. Nao bloquear o primeiro corte por isso; revisar quando a parte de desafios/BI for redesenhada.

## Corte recomendado para ir ao ar

O primeiro deploy publico deve conter apenas:

- solicitacao externa de cadastro;
- aprovacao admin;
- conta ativa;
- responsavel como `OWNER`;
- gestao basica de usuarios da conta;
- ads/cupons restritos a eventos da conta;
- BI ainda manual.

Esse corte entrega valor real sem forcar a migracao completa de BI e fornecedores no mesmo movimento.
