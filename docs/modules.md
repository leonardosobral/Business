# Mapa de Módulos

## Visao geral

Os modulos abaixo foram identificados por estrutura de pastas, rotas e menu lateral.

## Nucleo administrativo

### `admin`

Pasta:

- [admin](/Users/geraldoprotta/IdeaProjects/Business/admin)

Responsabilidade:

- manutencao operacional de eventos
- formularios de edicao
- homologacao
- resultados
- stats e dashboards administrativos

Arquivos relevantes:

- [admin/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/index.cfm)
- [admin/includes/backend](/Users/geraldoprotta/IdeaProjects/Business/admin/includes/backend)

### `configuracoes`

- [configuracoes](/Users/geraldoprotta/IdeaProjects/Business/configuracoes)

Responsavel por configuracoes administrativas da plataforma.

### `usuarios`

- [usuarios](/Users/geraldoprotta/IdeaProjects/Business/usuarios)

Gestao de usuarios administrativos e operacionais.

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

### `evento`

- [evento](/Users/geraldoprotta/IdeaProjects/Business/evento)

Visoes por evento, incluindo:

- inscritos
- saude
- treinao
- tabelas auxiliares

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

Fluxo de cadastro e inscricao com:

- criacao de conta
- perfil
- pagamento
- suporte via WhatsApp

O codigo sugere uso em contextos como `runpro` e desafios especificos.

## Suporte e operacao interna

### `faq`

- [faq](/Users/geraldoprotta/IdeaProjects/Business/faq)

### `helpdesk`

- [helpdesk](/Users/geraldoprotta/IdeaProjects/Business/helpdesk)

### `documentacao`

- [documentacao](/Users/geraldoprotta/IdeaProjects/Business/documentacao)

### `chat`

- [chat](/Users/geraldoprotta/IdeaProjects/Business/chat)
- [admin/api/chat/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/api/chat/index.cfm)

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
4. [admin/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/admin/index.cfm)
5. [bi/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/bi/index.cfm)
6. [leaderboard/api/transmissao.cfc](/Users/geraldoprotta/IdeaProjects/Business/leaderboard/api/transmissao.cfc)
7. [portal/videos/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/portal/videos/home.cfm)
