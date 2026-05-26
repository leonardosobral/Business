# Contexto Geral do Projeto

## O que este projeto e

`Business` e o backoffice operacional do ecossistema Road Runners / RunnerHub.

Ele nao e apenas um admin simples. O repositorio concentra:

- gestao administrativa
- BI
- operacao de eventos
- leaderboard e transmissao
- CRM e email marketing
- inscricoes
- modulos de suporte
- governanca de conteudo e portal

## Stack real

- Adobe ColdFusion / CFML
- PostgreSQL
- datasource principal `runner_dba`
- renderizacao server-side
- interface moderna com MDBootstrap em boa parte da area logada
- partes legadas usando assets de `lib/`

## Entradas principais

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [index.cfm](/Users/geraldoprotta/IdeaProjects/Business/index.cfm)
- [template.cfm](/Users/geraldoprotta/IdeaProjects/Business/template.cfm)

## Convencoes reais

Padrao dominante de modulo:

1. `index.cfm`
2. `home.cfm`
3. `includes/backend.cfm` ou backend especifico
4. `VARIABLES.template` para destacar menu

Padrao dominante de seguranca:

- leitura de `COOKIE.id`
- carga de `qPerfil` via [`includes/backend/backend_login.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- checks locais de `qPerfil.is_admin`

## O que lembrar sempre

- o sistema e muito sensivel a variaveis em escopo global
- varios modulos usam `URL.acao` e `FORM.action`
- telas novas costumam seguir o shell visual dos modulos existentes
- reflection por `information_schema` ja e um padrao aceito em algumas areas
- ha codigo novo e legado convivendo lado a lado

## Areas mais sensiveis

- auth e cookies
- CRM / email marketing
- leaderboard APIs
- inscricao e pagamento
- BI por permissoes
- modulos dinamicos que montam telas a partir de metadata de coluna

## Areas alteradas recentemente

Dentro da secao Portal, existem hoje tres modulos:

- [portal/videos](/Users/geraldoprotta/IdeaProjects/Business/portal/videos)
- [portal/canais](/Users/geraldoprotta/IdeaProjects/Business/portal/canais)
- [portal/conteudo-canais](/Users/geraldoprotta/IdeaProjects/Business/portal/conteudo-canais)

O modulo `portal/conteudo-canais` depende de `news.tb_content_types` e dos campos:

- `rr_portal_enabled`
- `rr_home_featured_enabled`
- `rr_news_featured_enabled`

## Abordagem recomendada para futuras mudancas

- entender o backend incluido antes de mexer na view
- procurar por `VARIABLES.template` para saber como a rota entra no menu
- validar se o modulo usa tabela fixa ou reflection
- preservar redirects e checks de admin
- revisar responsividade, porque varias telas sao densas em tabela
