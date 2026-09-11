# RunnerHub Business

Área de administração, BI e operações do ecossistema `roadrunners.run` / `runnerhub.run`.

Este repositório hoje funciona como um monólito em Adobe ColdFusion/CFML, com renderização server-side em `*.cfm`, componentes `*.cfc`, PostgreSQL como base principal e interface apoiada em MDBootstrap.

## Resumo rápido

- Stack principal: Adobe ColdFusion + CFML + PostgreSQL + MDBootstrap.
- Estilo de arquitetura: monólito orientado a páginas, com muita regra de negócio em `include` e `backend/*.cfm`.
- Entrada principal: [`Application.cfc`](/Users/leonardosobral/Git/RunnerHub/Business/Application.cfc).
- Datasource padrão da aplicação: `runner_dba`.
- Autenticação: Google Sign-In verificado no servidor, sessão com 24 horas de inatividade e credencial persistente de 30 dias (requer a migration de dispositivos). Cookies legados de ID não autenticam.
- Áreas principais: `eventos`, `bi`, `crm`, `emailmkt`, `leaderboard`, `inscricoes` e módulos satélite para operação.

## Como o projeto está organizado

### Audiência e inventário (07–08/09/2026)

O módulo administrativo [`portal/audiencia/`](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/index.cfm) reúne acessos, inventário de posições, exposição visível, regiões, conteúdo e aquisição UTM. A medição é produzida pelo RoadRunners, sem depender da interface do Google Analytics e sem debitar créditos Ads. O painel usa o datasource explícito `runnerhub` para leitura do schema `audience`.

Painel publicado no Business em 07/09/2026, com SQLs protegidos contra download e autenticação existente preservada. Após a instalação dos objetos de audiência pelo operador, a revalidação autenticada reconheceu a instalação e mostrou **“Aguardando os primeiros eventos”**; a retenção aparecia instalada, ainda sem execução. O recorte SC/30 dias/contexto comercial passou em desktop1460px e mobile390px. Esse registro descreve o estado anterior à ativação, não métricas reais.

O runtime RoadRunners de audiência também foi publicado nessa data: 30 arquivos, sendo18 substituídos e12 novos. `includes/ads_v1/viewability.cfm`, que controla beacon Ads independente, ficou fora do pacote e foi preservado. Verificação independente confirmou os30 hashes/metadados,18 backups, seis guards e ausência dos três overrides locais. No momento da publicação, o coletor permaneceu desligado (`503`, corpo `disabled`) e as páginas testadas não carregaram tracker; 104/104 verificações HTTP passaram em cinco rotas públicas/origin e três assets. Apache PID1780160 e ColdFusion PID1780425 permaneceram sem restart.

A coleta foi ativada em 08/09/2026 às 23:53:19.083536 UTC (20:53 em Brasília), por override local protegido em `/var/www/roadrunners.com.br/config/audience.local.cfm` (`0600`, UID/GID65534), com backup privado em `/var/backups/roadrunners-audience-activation-20260908.az0scvhm`. Às20:56, o painel Business sem incluir acessos internos mostrou2 visitantes,2 páginas/aberturas,2 sessões,7 posições,2 posições visíveis e2 anúncios visíveis. O recorte contém uma visita anônima de validação e, por isso, não deve ser descrito como tráfego orgânico. O proxy confiável já havia sido aplicado e verificado às16:34:43 UTC. A role de runtime e a identidade `rr_audience_retention_job` foram validadas; somente senha, conexão privada e agenda de retenção ainda serão providenciadas pelo DBA, sem bloquear a coleta, e a retenção segue sem execução comprovada. Consulte o [recibo da ativação](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-08_audience_activation_receipt.json), [publicação e gates operacionais](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-07_audiencia_publicacao.md), [publicação RoadRunners](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-07_audiencia_publicacao_roadrunners.md) e [testes da implementação](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-07_audiencia_painel_finalizacao.md). Senha/conexão privada/agenda de retenção e homologação operacional final continuam pendentes. O restante deste README preserva o diagnóstico inicial do repositório; para autenticação, prevalecem o código e os registros específicos de segurança mais recentes.

### Bootstrap da aplicação

- [`Application.cfc`](/Users/leonardosobral/Git/RunnerHub/Business/Application.cfc): configura nome da aplicação, session, datasource padrão, locale e ciclo de request.
- [`index.cfm`](/Users/leonardosobral/Git/RunnerHub/Business/index.cfm): decide se o usuário cai na home pública ou no template logado.
- [`template.cfm`](/Users/leonardosobral/Git/RunnerHub/Business/template.cfm): template base da área logada principal.

### Estrutura compartilhada

- [`includes/backend`](/Users/leonardosobral/Git/RunnerHub/Business/includes/backend): regras reutilizáveis de autenticação, parceiros, inscritos, saúde e treinos.
- [`includes/estrutura`](/Users/leonardosobral/Git/RunnerHub/Business/includes/estrutura): head, header, navbar, sidenav, footer e variáveis globais da interface.
- [`includes/parts`](/Users/leonardosobral/Git/RunnerHub/Business/includes/parts): componentes parciais para listagens e filtros.

### Módulos mais relevantes

- [`eventos`](/Users/Shared/Projects/RunnerHub/Business/eventos): manutenção e edição operacional de eventos, resultados, homologação e solicitações de vínculo entre conta e evento.
- [`admin`](/Users/Shared/Projects/RunnerHub/Business/admin): rota de compatibilidade que redireciona para `eventos`.
- [`bi`](/Users/leonardosobral/Git/RunnerHub/Business/bi): portal de BI por permissões, com acessos por tema/agregador/evento.
- [`leaderboard`](/Users/leonardosobral/Git/RunnerHub/Business/leaderboard): páginas, APIs e assets voltados a rankings, startlists, parciais e transmissão.
- [`crm`](/Users/leonardosobral/Git/RunnerHub/Business/crm): fila e disparo de comunicação.
- [`emailmkt`](/Users/leonardosobral/Git/RunnerHub/Business/emailmkt): composição e envio de e-mail marketing.
- [`inscricoes`](/Users/leonardosobral/Git/RunnerHub/Business/inscricoes) e [`ads`](/Users/leonardosobral/Git/RunnerHub/Business/ads): inscrições, campanhas e peças comerciais.
- [`fornecedores`](/Users/leonardosobral/Git/RunnerHub/Business/fornecedores): gestão operacional ligada a fornecedores.
- [`usuarios`](/Users/leonardosobral/Git/RunnerHub/Business/usuarios), [`faq`](/Users/leonardosobral/Git/RunnerHub/Business/faq), [`helpdesk`](/Users/leonardosobral/Git/RunnerHub/Business/helpdesk), [`notificacoes`](/Users/leonardosobral/Git/RunnerHub/Business/notificacoes): áreas de suporte e operação interna.

## Fluxo técnico observado

### 1. Inicialização

A aplicação nasce em [`Application.cfc`](/Users/leonardosobral/Git/RunnerHub/Business/Application.cfc), com `SessionManagement = true`, timeout configurado e `THIS.datasource = "runner_dba"`.

### 2. Controle de acesso

Grande parte das páginas protegidas inclui [`includes/backend/backend_login.cfm`](/Users/leonardosobral/Git/RunnerHub/Business/includes/backend/backend_login.cfm), que:

- carrega o perfil do usuário a partir de `REQUEST.businessIdentity`, estabelecida pela sessão verificada
- resolve permissões
- carrega vínculos com contas, usuários, páginas e eventos
- trata login/logout com Google
- faz redirects com `cflocation` quando o contexto não está válido

O fluxo de permanência do login, a migration necessária e o procedimento de publicação estão documentados em [Login persistente do Business](_codex/docs/2026-09-09_business_login_persistente.md).

### 3. Composição das telas

O padrão mais recorrente é:

1. definir `VARIABLES.template`
2. incluir backend(s)
3. incluir template estrutural (`head`, `header`, `footer`)
4. renderizar `home.cfm` ou alguma view principal do módulo

Isso aparece claramente em módulos como [`bi/index.cfm`](/Users/leonardosobral/Git/RunnerHub/Business/bi/index.cfm), [`administracao/contas/index.cfm`](/Users/Shared/Projects/RunnerHub/Business/administracao/contas/index.cfm) e [`crm/index.cfm`](/Users/leonardosobral/Git/RunnerHub/Business/crm/index.cfm).

## Convenções que já existem na prática

- `index.cfm`: shell da página do módulo.
- `home.cfm`: conteúdo principal do módulo.
- `includes/backend.cfm` ou `backend/*.cfm`: consultas e ações do módulo.
- `form_*.cfm`: formulários de edição/manutenção.
- `api/*.cfm` e `api/*.cfc`: endpoints ou rotinas auxiliares.

Em outras palavras: a convenção do projeto hoje é mais importante do que qualquer camada formal de arquitetura.

## Dependências implícitas

Hoje o repositório não traz uma receita completa de setup local, mas pelo código é possível afirmar que ele depende de:

- Adobe ColdFusion com suporte a CFML
- datasource `runner_dba` configurado no servidor
- banco PostgreSQL com tabelas de operação, BI, usuários, eventos, permissões e logs
- servidor SMTP para fluxos de e-mail
- assets estáticos locais em [`assets`](/Users/leonardosobral/Git/RunnerHub/Business/assets), [`lib`](/Users/leonardosobral/Git/RunnerHub/Business/lib) e módulos específicos como [`leaderboard/assets`](/Users/leonardosobral/Git/RunnerHub/Business/leaderboard/assets)

## Pontos de atenção técnicos

Durante a leitura inicial apareceram alguns riscos importantes:

- Segredos e credenciais estão hardcoded em arquivos CFML/CFC.
- Há mistura forte de view, controller e acesso a dados no mesmo arquivo.
- O projeto depende bastante de `COOKIE`, `URL` e `FORM` em escopo global.
- Existem consultas SQL longas embutidas em páginas e includes.
- Parte da UI parece conter trechos de template/demo ainda não conectados ao domínio do produto.
- O setup local não está documentado.

## Melhorias prioritárias

### Curto prazo

- Remover segredos hardcoded e migrar para variáveis de ambiente ou configuração segura do servidor.
- Documentar setup local mínimo: versão do ColdFusion, criação do datasource, hostnames e variáveis obrigatórias.
- Mapear módulos críticos e responsáveis de negócio.
- Criar um `docs/` com fluxos centrais: login, permissões, BI, eventos, leaderboard e e-mail.

### Médio prazo

- Separar melhor leitura/escrita de dados das views.
- Centralizar autenticação/autorização em uma camada única.
- Padronizar nomes e responsabilidades de `backend.cfm`.
- Reduzir duplicação entre raiz, `bi/`, `stats/` e módulos parecidos.

### Longo prazo

- Evoluir de includes soltos para serviços/componentes mais previsíveis.
- Extrair APIs mais claras para operações críticas.
- Criar cobertura mínima de teste, nem que seja primeiro em smoke tests e queries mais sensíveis.
- Avaliar uma estratégia de modularização por domínio.

## Sugestão de mapa funcional inicial

Se a ideia for continuar organizando o projeto, eu seguiria este inventário:

1. autenticação e sessão
2. permissões e perfis
3. cadastro e gestão de eventos
4. BI e agregadores
5. leaderboard e transmissões
6. CRM/e-mail marketing
7. campanhas, cupons e anúncios

## Estado atual do repositório

- `git status`: limpo no momento desta análise.
- `README` original: praticamente vazio.
- Esta documentação foi escrita a partir de leitura estática do código, sem subir a aplicação localmente.

## Próximos passos recomendados

Se a gente continuar evoluindo essa base, o melhor próximo passo é escolher uma destas frentes:

1. documentar setup local e dependências reais do ambiente
2. mapear módulos e fluxos em mais detalhe
3. atacar débitos técnicos de segurança e configuração
4. começar uma limpeza estrutural em um módulo específico, como `admin` ou `bi`
