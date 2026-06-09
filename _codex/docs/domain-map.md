# Mapa de Domínios

## Dominio: autenticacao e perfil

Arquivos chave:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)

Entidades principais:

- `tb_usuarios`
- `tb_paginas`
- `tb_paginas_usuarios`
- `tb_contas`
- `tb_conta_usuarios`
- `tb_conta_eventos`
- `tb_conta_evento_solicitacoes`

## Dominio: eventos e manutencao

Arquivos chave:

- [eventos/index.cfm](/Users/Shared/Projects/RunnerHub/Business/eventos/index.cfm)
- [eventos/includes/backend](/Users/Shared/Projects/RunnerHub/Business/eventos/includes/backend)
- [administracao/contas/index.cfm](/Users/Shared/Projects/RunnerHub/Business/administracao/contas/index.cfm)

Notas:

- o fluxo ativo de edicao de eventos fica em `/eventos/`, a partir de `eventos/index.cfm` e `eventos/home.cfm`
- `/admin/` existe como redirect de compatibilidade para `/eventos/`
- paginas antigas sem ligacao direta com esse fluxo ficam em `_legado/admin/`
- `/administracao/contas/` e o CRUD admin da estrutura nova de contas empresariais em `tb_contas`, vinculos de usuarios em `tb_conta_usuarios` e vinculos de eventos em `tb_conta_eventos`
- usuarios de conta solicitam vinculo de eventos em `/eventos/`; o pedido fica em `tb_conta_evento_solicitacoes` e o vinculo fica `PENDENTE` em `tb_conta_eventos` ate revisao admin

## Dominio: BI

Arquivos chave:

- [bi/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/bi/index.cfm)
- [includes/parts](/Users/geraldoprotta/IdeaProjects/Business/includes/parts)

Entidades frequentes:

- `tb_permissoes`
- `tb_bi`
- `tb_agregadores`
- `tb_agrega_eventos`
- `tb_temas`

## Dominio: leaderboard e transmissao

Arquivos chave:

- [leaderboard/api/transmissao.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/transmissao.cfc)
- [leaderboard/api/leaderboard.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/leaderboard.cfc)

Entidades frequentes:

- `tb_resultados_temp`
- `tb_leaderboard_marca`
- `tb_leaderboard_pc`
- `tb_leaderboard_evento`

## Dominio: CRM e email

Arquivos chave:

- [crm/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/crm/EmailSenderService.cfc)
- [emailmkt/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/emailmkt/EmailSenderService.cfc)

## Dominio: inscricao

Arquivos chave:

- [inscricao/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/inscricao/index.cfm)

Notas:

- `/inscricao/` ficou como redirect de compatibilidade para `/cadastro/`
- o fluxo antigo de inscricao/cadastro/pagamento foi arquivado em `_legado/inscricao/`
- o cadastro externo Business ativo fica em `/cadastro/`, com solicitacoes em `tb_conta_cadastro_solicitacoes`

## Dominio: portal

Arquivos chave:

- [portal/videos/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/videos/home.cfm)
- [portal/includes/media_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/media_backend.cfm)
- [portal/canais/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/canais/home.cfm)
- [portal/includes/channels_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/channels_backend.cfm)
- [portal/conteudo-canais/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/conteudo-canais/home.cfm)
- [portal/includes/content_channels_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/content_channels_backend.cfm)
- [portal/banners/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/home.cfm)
- [portal/includes/banner_management_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/banner_management_backend.cfm)
- [api/portal/banners/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/index.cfm)
- [api/portal/banners/click.cfm](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm)

## Dominio: treinos

Arquivos chave:

- [treinos-config/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/treinos-config/home.cfm)
- [treinos-config/includes/backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/treinos-config/includes/backend.cfm)

## Dominio: desafios

Arquivos chave:

- [desafios/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/desafios/index.cfm)
- [bi/desafio](/Users/geraldoprotta/IdeaProjects/Business/bi/desafio)

## Dominio: integracoes externas

Arquivos chave:

- [racetag/form.cfm](/Users/geraldoprotta/IdeaProjects/Business/racetag/form.cfm)
- [racetag/parse.cfm](/Users/geraldoprotta/IdeaProjects/Business/racetag/parse.cfm)

Nota:

- `admin/api/processar` nao existe mais na arvore ativa; referencias antigas devem ser tratadas como legado removido.
