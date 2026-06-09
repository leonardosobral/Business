# Mapa de Integrações

## Banco principal

- datasource: `runner_dba`
- tipo inferido: PostgreSQL

## Banco editorial externo

- schema `news`
- tabela usada no Business: `news.tb_content_types`

## Google

- Google Sign-In
- Google Maps Geocoding

## SMTP

- Mandrill para CRM e Email Marketing
- Gmail SMTP apareceu em trecho legado comentado de erro

## Providers / APIs externas

- Runking transmission JSON
- RaceTag JSON
- endpoints Road Runners e RunnerHub

## Integracoes internas do ecossistema

- Road Runners
- RunnerHub
- Open Results
- News

## Endpoints internos relevantes

- [leaderboard/api/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/index.cfm)
- [api/portal/banners](/Users/Shared/Projects/RunnerHub/Business/api/portal/banners)
- [api/portal/runner-apps](/Users/Shared/Projects/RunnerHub/Business/api/portal/runner-apps)

Nota:

- `/admin/api/` nao existe mais na arvore ativa; referencias antigas a chat, importacao e processamento devem ser tratadas como legado removido.

## Riscos para integracoes futuras

- credenciais no codigo
- formatos mistos de resposta
- ausencia de contrato formal para varias APIs
- dependencia de side effects em banco
