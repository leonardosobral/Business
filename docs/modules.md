# Mapa de Módulos

## Visao geral

Os modulos abaixo foram identificados por estrutura de pastas, rotas e menu lateral.

## Nucleo administrativo

### `eventos`

Pasta:

- [eventos](/Users/Shared/Projects/RunnerHub/Business/eventos)

Responsabilidade:

- manutencao operacional de eventos
- formularios de edicao
- solicitacao de vinculo entre conta e evento

Observacao:

- a rota principal de eventos agora e `/eventos/`
- `/admin/` fica como compatibilidade e redireciona para `/eventos/`
- usuarios de conta podem solicitar vinculo de evento por URL/tag/texto; o vinculo entra como `PENDENTE` em `tb_conta_eventos`
- a revisao administrativa usa `tb_conta_evento_solicitacoes`
- telas antigas que nao participam desse fluxo foram arquivadas em `_legado/admin/`

Arquivos relevantes:

- [eventos/index.cfm](/Users/Shared/Projects/RunnerHub/Business/eventos/index.cfm)
- [eventos/includes/backend](/Users/Shared/Projects/RunnerHub/Business/eventos/includes/backend)

### `configuracoes`

- [_legado/configuracoes](/Users/Shared/Projects/RunnerHub/Business/_legado/configuracoes)

Modulo removido da arvore ativa e arquivado como legado.

### `usuarios`

- [administracao/contas](/Users/Shared/Projects/RunnerHub/Business/administracao/contas)

Gestao de usuarios por conta Business. A rota `/usuarios/` ficou apenas como redirect de compatibilidade para `/administracao/contas/`; o codigo antigo esta em `_legado/usuarios/`.

## BI e operacao de eventos

### `bi`

Pasta:

- [bi](/Users/geraldoprotta/IdeaProjects/Business/bi)

Responsabilidade:

- BI geral
- dashboards por agregador, tema e evento
- areas de desafios
- fila operacional
- modulos especializados como `elite-supra`

Subareas observadas:

- [bi/desafio](/Users/geraldoprotta/IdeaProjects/Business/bi/desafio)
- [bi/elite-supra](/Users/geraldoprotta/IdeaProjects/Business/bi/elite-supra)
- [bi/stats](/Users/geraldoprotta/IdeaProjects/Business/bi/stats)
- [bi/assessorias](/Users/geraldoprotta/IdeaProjects/Business/bi/assessorias)

### `stats`

- [stats](/Users/geraldoprotta/IdeaProjects/Business/stats)

Area de estatisticas complementares fora da arvore principal de BI.

## Portal e conteudo

### `portal/videos`

- [portal/videos](/Users/geraldoprotta/IdeaProjects/Business/portal/videos)

Controle de videos importados em `tb_media`, com:

- listagem
- paginacao
- exibir / ocultar
- remocao

### `portal/canais`

- [portal/canais](/Users/geraldoprotta/IdeaProjects/Business/portal/canais)

Gerenciamento dos canais do YouTube cadastrados em `tb_youtube_canais`.

### `portal/conteudo-canais`

- [portal/conteudo-canais](/Users/geraldoprotta/IdeaProjects/Business/portal/conteudo-canais)

Novo controle de canais editoriais do repositório News, baseado em `news.tb_content_types`, para governar:

- exibicao no portal
- destaque na home
- destaque na sessao Noticias

### `portal/banners`

- [portal/banners](/Users/geraldoprotta/IdeaProjects/Business/portal/banners)
- [api/portal/banners](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners)

Gerenciador de banners visuais da plataforma, com:

- upload de criativos `jpg`, `png` e `gif`
- segmentacao por `canal` e `local_layout`
- API publica para entrega de banner elegivel
- tracking de impressoes e cliques

### `portal/runner-apps`

- [portal/runner-apps](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps)
- [api/portal/runner-apps](/Users/geraldoprotta/IdeaProjects/Business/api/portal/runner-apps)

Gerenciador dinamico do menu `Runner Apps` consumido pelo `Road Runners` e outros sites da plataforma, com:

- grupos/linhas ordenaveis
- apps com nome, icone, URL, target e rel
- ocultacao e remocao de itens
- API publica de catalogo

## Marketing e relacionamento

### `crm`

- [crm](/Users/geraldoprotta/IdeaProjects/Business/crm)

Fila e processos de comunicacao. Usa componente:

- [crm/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/crm/EmailSenderService.cfc)

### `emailmkt`

- [emailmkt](/Users/geraldoprotta/IdeaProjects/Business/emailmkt)

Composicao e envio de email marketing. Tambem possui:

- [emailmkt/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/emailmkt/EmailSenderService.cfc)

### `ads`

- [ads](/Users/geraldoprotta/IdeaProjects/Business/ads)

Campanhas / turbinados.

### `cupons` e `cupons-rr`

- [cupons](/Users/geraldoprotta/IdeaProjects/Business/cupons)
- [cupons-rr](/Users/geraldoprotta/IdeaProjects/Business/cupons-rr)

Gestao de campanhas e descontos.

### `notificacoes`

- [notificacoes](/Users/geraldoprotta/IdeaProjects/Business/notificacoes)

Operacao de notificacoes.

Estado atual:

- templates e historico ainda operam localmente
- o envio administrativo ja usa a API central do `Road Runners`
- o topo do `Business` possui inbox propria baseada em `tb_notifica`

## Lideranca, tempo real e dados de prova

### `leaderboard`

- [leaderboard](/Users/geraldoprotta/IdeaProjects/Business/leaderboard)

Um dos dominios tecnicos mais importantes do projeto.

Abrange:

- APIs XML / string para ranking e parciais
- fetches de atletas, startlist e leaderboard
- paginas de TV e ranking
- widgets e mapas

Arquivos chave:

- [leaderboard/api/transmissao.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/transmissao.cfc)
- [leaderboard/api/leaderboard.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/leaderboard.cfc)
- [leaderboard/api/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/index.cfm)

## Inscricao e onboarding

### `inscricao`

- [inscricao](/Users/geraldoprotta/IdeaProjects/Business/inscricao)

Rota de compatibilidade para `/cadastro/`.

O fluxo antigo de cadastro, inscricao e pagamento foi arquivado em `_legado/inscricao/`. O cadastro externo Business ativo fica em `/cadastro/` e grava solicitacoes para aprovacao administrativa.

## Suporte e operacao interna

### `faq`

- [faq](/Users/geraldoprotta/IdeaProjects/Business/faq)

### `helpdesk`

- [helpdesk](/Users/geraldoprotta/IdeaProjects/Business/helpdesk)

Estado atual:

- painel administrativo do atendimento
- respostas e aberturas preservam o fluxo principal mesmo se a notificacao falhar
- notificacoes operacionais foram migradas para a API central do `Road Runners`

### `documentacao`

- [documentacao](/Users/geraldoprotta/IdeaProjects/Business/documentacao)

### `chat`

Nao existe mais na arvore ativa. Referencias antigas a `chat` e `admin/api/chat` devem ser tratadas como legado removido.

## Dominios especializados

### `desafios`

- [desafios](/Users/geraldoprotta/IdeaProjects/Business/desafios)

### `treinos-config`

- [treinos-config](/Users/geraldoprotta/IdeaProjects/Business/treinos-config)

Configuracao de treinos por evento, com backend dinamico baseado em tabela.

### `fornecedores`

- [fornecedores](/Users/geraldoprotta/IdeaProjects/Business/fornecedores)

### `racetag`

- [racetag](/Users/geraldoprotta/IdeaProjects/Business/racetag)

Integra integracoes de resultados com `cfhttp`.

### `assinaturas`

- [assinaturas](/Users/geraldoprotta/IdeaProjects/Business/assinaturas)

### `manutencao`

- [manutencao](/Users/geraldoprotta/IdeaProjects/Business/manutencao)

## Leitura recomendada por ordem

Para entender o sistema mais rapido, a ordem sugerida e:

1. [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
2. [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
3. [includes/estrutura/sidenav.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/sidenav.cfm)
4. [eventos/index.cfm](/Users/Shared/Projects/RunnerHub/Business/eventos/index.cfm)
5. [bi/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/bi/index.cfm)
6. [leaderboard/api/transmissao.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/transmissao.cfc)
7. [portal/videos/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/videos/home.cfm)
