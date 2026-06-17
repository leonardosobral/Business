# Operação e Setup

## Setup minimo inferido

Nao existe receita completa de setup local no repositorio. Pela leitura do codigo, o minimo necessario e:

1. Adobe ColdFusion configurado
2. datasource `runner_dba` criado e apontando para o banco principal
3. acesso de leitura e escrita nas tabelas de operacao
4. acesso de saida para SMTP e APIs externas
5. virtual host / roteamento para servir o projeto como aplicacao web

## Pontos de entrada

### Entrada raiz

- [index.cfm](/Users/geraldoprotta/IdeaProjects/Business/index.cfm)

Comportamento:

- se existir `COOKIE.id`, consulta perfil
- se o usuario tiver acesso aprovado, cai na area logada
- se existir uma solicitacao pendente de cadastro Business, mostra o status em `/cadastro/status.cfm`
- se nao houver acesso aprovado nem solicitacao relacionada, mostra a home publica e orienta o cadastro em `/cadastro/`
- sem cookie, mostra a landing publica

### Entrada da area logada principal

- [template.cfm](/Users/geraldoprotta/IdeaProjects/Business/template.cfm)

## Navegacao principal

Definida em:

- [includes/estrutura/sidenav.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/sidenav.cfm)

Grupos observados:

- Portal
- Ferramentas
- Marketing
- Desafios
- Empresa
- Suporte

## Padrao de modulo

Ao criar um modulo novo, o projeto hoje espera algo proximo disto:

1. pasta do modulo com `index.cfm`
2. `home.cfm` como view
3. `includes/backend.cfm` ou backend especifico
4. definicao de `VARIABLES.template` para destacar o menu
5. inclusao de `backend_login.cfm` se for area protegida

## Como o controle de permissao costuma funcionar

O padrao mais comum e:

- verificar `COOKIE.id`
- carregar `qPerfil`
- checar `qPerfil.is_admin` ou permissoes derivadas
- aplicar `cflocation` se o usuario nao puder acessar

Esse estilo aparece em varios modulos, inclusive Portal e BI.

## Fluxos criticos de operacao

### Login

- Google Sign-In
- criacao/atualizacao de usuario
- escrita de cookies

### Acesso administrativo

- paginas protegidas dependem de `backend_login.cfm`
- varios controles assumem perfil admin

### Email

- CRM e Email Marketing usam servico SMTP dedicado

### Leaderboard

- endpoints remotos e views de TV dependem de tabelas e dados transacionais de prova

### Portal

- modulo gerencia videos, canais de YouTube e canais editoriais integrados ao News

### Uptime Server Status

O dashboard logado do Business pode exibir um painel de status operacional para usuarios admin, usando a API read-only do UptimeRobot.

Arquivos:

- [includes/backend/uptime_status.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/uptime_status.cfm)
- [includes/estrutura/uptime_status.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/uptime_status.cfm)
- [home_logado.cfm](/Users/geraldoprotta/IdeaProjects/Business/home_logado.cfm)

Configuracao:

- Preferencial: variavel de ambiente `UPTIMEROBOT_API_KEY`
- Alternativa sem reiniciar ColdFusion inteiro: criar/editar `config/business.local.cfm` com `businessLocalConfig.uptimeRobotApiKey`
- Exemplo versionado: [config/business.local.example.cfm](/Users/geraldoprotta/IdeaProjects/Business/config/business.local.example.cfm)

Variaveis opcionais:

- `UPTIMEROBOT_API_URL`, padrao `https://api.uptimerobot.com/v2/getMonitors`
- `UPTIMEROBOT_TIMEOUT_SECONDS`, padrao `15`
- `UPTIMEROBOT_CACHE_SECONDS`, padrao `120`

Depois de alterar a configuracao local, acesse `/?resetApp` para recarregar `APPLICATION.uptimeRobot`.

## Semantica de arquivos

- `index.cfm`: casca da pagina
- `home.cfm`: tela principal
- `backend.cfm`: CRUD, queries e acoes
- `form_*.cfm`: formularios auxiliares
- `api/*.cfm`: endpoint procedural
- `api/*.cfc`: endpoint remoto baseado em componente

## O que testar apos mudancas

Em manutencoes futuras, vale sempre validar pelo menos:

1. acesso com usuario admin
2. acesso com usuario sem permissao
3. comportamento do menu lateral
4. acoes baseadas em `URL.acao` ou `FORM.action`
5. consultas dinamicas em tabelas refletidas pelo `information_schema`
6. responsividade das telas novas

## O que nao foi encontrado

- pipeline formal de build
- testes automatizados
- docker / compose
- package manager de app
- checklist oficial de deploy
