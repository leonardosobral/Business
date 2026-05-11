# Integrações e Dependências

## Banco de dados

Datasource principal identificado:

- `runner_dba`

Definicao principal:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)

Schemas e tabelas relevantes observadas:

- schema `public`
- schema `news`
- `tb_usuarios`
- `tb_paginas`
- `tb_permissoes`
- `tb_bi`
- `tb_agregadores`
- `tb_agrega_eventos`
- `tb_media`
- `tb_youtube_canais`
- `tb_evento_treinos_config`
- `news.tb_content_types`

## Autenticacao Google

Fluxo observado:

- frontend carrega Google Sign-In
- backend decodifica `credential`
- usuario e criado ou atualizado em `tb_usuarios`
- cookies de sessao sao escritos no browser

Pontos de entrada:

- [home.cfm](/Users/geraldoprotta/IdeaProjects/Business/home.cfm)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- [includes/estrutura/head.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/head.cfm)

## Email / SMTP

Servicos identificados:

- [crm/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/crm/EmailSenderService.cfc)
- [emailmkt/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/emailmkt/EmailSenderService.cfc)

Servidor SMTP observado no codigo:

- `smtp.mandrillapp.com`

Uso adicional de `cfmail` tambem aparece em:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)

## Integracoes HTTP externas

### Resultados / transmissao

- `https://resultadoseventosapi.runking.com.br/...`

Arquivos:

- [leaderboard/api/crono.cfm](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/crono.cfm)
- [leaderboard/api/cronof.cfm](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/cronof.cfm)

### RaceTag

Uso de `cfhttp` para consumir JSON de eventos e resultados:

- [racetag/form.cfm](/Users/geraldoprotta/IdeaProjects/Business/racetag/form.cfm)
- [racetag/parse.cfm](/Users/geraldoprotta/IdeaProjects/Business/racetag/parse.cfm)

### Google Maps Geocoding

Uso observado em:

- [admin/api/processar/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/api/processar/index.cfm)

### Endpoints Road Runners / RunnerHub

Ha consumo e links diretos para endpoints externos ou paralelos, por exemplo:

- atualizacao de Strava em `roadrunners.run`
- endpoints publicos `runnerhub.run/leaderboard/api/...`

## APIs internas e remotas

### APIs baseadas em CFC

Exemplos:

- [leaderboard/api/transmissao.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/transmissao.cfc)
- [leaderboard/api/leaderboard.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/leaderboard.cfc)

Padrao:

- `access="remote"`
- retorno em `xml` ou `string`

### APIs baseadas em CFM

Exemplos:

- [admin/api/chat/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/api/chat/index.cfm)
- [admin/api/importacao/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/api/importacao/index.cfm)
- [admin/api/processar/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/api/processar/index.cfm)

## Frontend e assets

### Area logada moderna

- `assets/css/mdb.min.css`
- `assets/js/mdb.umd.min.js`
- `assets/css/style.css`
- `assets/css/cores_admin.css`

### Area publica / legado

- `lib/css/*`
- `lib/js/*`

## Dependencias implicitas de ambiente

Para a aplicacao funcionar fora do repositorio, o ambiente precisa oferecer:

- Adobe ColdFusion compativel com o codigo atual
- datasource `runner_dba`
- acesso a SMTP externo
- acesso HTTP de saida para APIs remotas
- assets estaticos servidos na mesma app

## Integracao com o projeto News

Ha integracao conceitual e agora tambem operacional com o repositorio News:

- a area [`portal/conteudo-canais`](/Users/geraldoprotta/IdeaProjects/Business/portal/conteudo-canais) governa a exibicao de canais vindos de `news.tb_content_types`

Campos esperados:

- `rr_portal_enabled`
- `rr_home_featured_enabled`
- `rr_news_featured_enabled`

Script auxiliar:

- [portal/conteudo-canais/news_tb_content_types_portal_flags.sql](/Users/geraldoprotta/IdeaProjects/Business/portal/conteudo-canais/news_tb_content_types_portal_flags.sql)
