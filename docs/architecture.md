# Arquitetura Geral

## Visao de alto nivel

O projeto `Business` funciona como um monolito operacional para o ecossistema Road Runners / RunnerHub. A aplicacao mistura:

- area administrativa
- BI e dashboards
- operacao de eventos
- CRM e email marketing
- APIs de leaderboard e transmissao
- fluxos de inscricao e autoatendimento
- ferramentas satelite para Portal, desafios, notificacoes e suporte

## Stack observada

- Adobe ColdFusion / CFML
- PostgreSQL
- renderizacao server-side em `*.cfm`
- alguns componentes `*.cfc`
- MDBootstrap na area logada atual
- layout legado em partes publicas e antigas

## Bootstrap da aplicacao

Arquivo principal:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)

Responsabilidades principais:

- define `THIS.Name = "RunnerHubBusiness"`
- liga `SessionManagement`
- define `THIS.datasource = "runner_dba"`
- ajusta locale para `Portuguese (Brazilian)`
- centraliza `OnApplicationStart`, `OnRequestStart` e `OnRequest`

## Modelo de request

O padrao dominante do projeto e:

1. `index.cfm` do modulo define `VARIABLES.theme` e `VARIABLES.template`
2. o modulo inclui [`includes/backend/backend_login.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm) ou backend local
3. a estrutura visual comum e montada por [`includes/estrutura/head.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/head.cfm), [`includes/estrutura/header.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/header.cfm) e [`includes/estrutura/footer.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/footer.cfm)
4. o conteudo principal do modulo fica em `home.cfm`

Exemplos claros:

- [admin/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/index.cfm)
- [bi/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/bi/index.cfm)
- [portal/videos/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/videos/index.cfm)

## Estrutura logada principal

Area logada padrao:

- [template.cfm](/Users/geraldoprotta/IdeaProjects/Business/template.cfm)
- [home_logado.cfm](/Users/geraldoprotta/IdeaProjects/Business/home_logado.cfm)

Landing / pagina publica:

- [index.cfm](/Users/geraldoprotta/IdeaProjects/Business/index.cfm)
- [home.cfm](/Users/geraldoprotta/IdeaProjects/Business/home.cfm)

## Modelo arquitetural real

Embora existam pastas por dominio, a arquitetura pratica e fortemente acoplada:

- SQL embutido em views e backends
- regras de negocio em includes `backend.cfm`
- dependencia intensa de `URL`, `FORM`, `COOKIE` e `VARIABLES`
- pouca separacao formal entre controller, service e view

Na pratica, o projeto segue uma convencao funcional:

- `index.cfm`: shell da pagina
- `home.cfm`: view principal
- `includes/backend.cfm` ou `backend/*.cfm`: queries e acoes do modulo
- `form_*.cfm`: formularios auxiliares
- `api/*.cfm` e `api/*.cfc`: endpoints e processamento remoto

## Camadas compartilhadas

### Estrutura visual

- [includes/estrutura](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura)

Conteudos relevantes:

- `head.cfm`
- `header.cfm`
- `navbar.cfm`
- `sidenav.cfm`
- `footer.cfm`
- `variaveis.cfm`

### Backends reutilizaveis

- [includes/backend](/Users/geraldoprotta/IdeaProjects/Business/includes/backend)

Ali vivem fluxos compartilhados como:

- login e sessao
- parceiros
- inscritos
- saude
- treinao

### Partials

- [includes/parts](/Users/geraldoprotta/IdeaProjects/Business/includes/parts)

Usado para listagens e elementos reutilizados de BI e operacao.

## Frontend

### Area logada atual

Carregada principalmente por:

- [includes/estrutura/head.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/head.cfm)

Dependencias observadas:

- Font Awesome via CDN
- Google Fonts Roboto
- `assets/css/mdb.min.css`
- `assets/plugins/css/all.min.css`
- `assets/css/style.css`
- `assets/css/cores_admin.css`

### Areas legadas

Partes como [home.cfm](/Users/geraldoprotta/IdeaProjects/Business/home.cfm) usam outro conjunto de assets em `lib/`, com cara de landing mais antiga.

## Autenticacao e sessao

O projeto nao usa uma camada moderna de auth centralizada. O fluxo atual depende de:

- cookies como `COOKIE.id`, `COOKIE.name`, `COOKIE.email`, `COOKIE.imagem_usuario`
- leitura de perfil por [`includes/backend/backend_login.cfm`](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- Google Sign-In no frontend e persistencia de usuario em `tb_usuarios`

Perfis principais inferidos do codigo:

- `is_admin`
- `is_partner`
- `is_dev`

## Conclusao

Arquiteturalmente, o projeto e melhor entendido como um monolito operacional por modulos, guiado por convencoes de pastas e includes, nao por camadas formais. Qualquer evolucao futura deve respeitar esse fato para evitar refactors grandes demais logo de inicio.
