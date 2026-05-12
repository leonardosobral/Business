# Help Desk

Documentacao funcional e tecnica do modulo de Help Desk implementado no projeto `Business`, com foco especial no consumo pelo projeto principal do site `roadrunners.run`.

## Objetivo

O Help Desk foi separado em dois contextos:

- `Business`: painel administrativo de atendimento, visivel apenas para usuarios com `tb_usuarios.is_admin = true`
- `roadrunners.run`: interface publica autenticada onde o usuario comum abre e acompanha seus chamados

O `Business` nao e o canal de abertura principal para o usuario final. Ele funciona como backoffice operacional para tratar, responder, classificar e encerrar os chamados enviados pelo site.

## Arquivos do modulo no Business

- [helpdesk/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/index.cfm)
- [helpdesk/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/home.cfm)
- [helpdesk/includes/backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/includes/backend.cfm)
- [helpdesk/helpdesk_schema.sql](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/helpdesk_schema.sql)

## Tabelas previstas

### `tb_helpdesk_setores`

Representa as filas ou areas de atendimento.

Campos principais:

- `id_setor`
- `nome_setor`
- `descricao_setor`
- `id_usuario_responsavel`
- `ativo`
- `created_at`
- `updated_at`

### `tb_helpdesk_chamados`

Representa o ticket principal.

Campos principais:

- `id_chamado`
- `protocolo`
- `id_usuario`
- `id_setor`
- `assunto`
- `status`
- `created_at`
- `updated_at`

### `tb_helpdesk_mensagens`

Representa a conversa do chamado.

Campos principais:

- `id_mensagem`
- `id_chamado`
- `id_usuario`
- `mensagem`
- `interno`
- `created_at`

## Regra de acesso

### No Business

Somente usuario com `is_admin = true` pode acessar `/helpdesk/`.

### No Road Runners

O usuario deve:

- estar autenticado
- abrir chamados apenas em seu proprio contexto
- visualizar apenas os chamados em que `tb_helpdesk_chamados.id_usuario = usuario_logado`

## Regra de propriedade

O identificador do solicitante e sempre `tb_usuarios.id`.

Ou seja:

- o site `roadrunners.run` deve gravar o usuario autenticado em `tb_helpdesk_chamados.id_usuario`
- o `Business` usa esse vinculo para identificar quem abriu o chamado

## Estados recomendados de chamado

Estados atualmente considerados pelo painel:

- `aberto`
- `em_atendimento`
- `aguardando_cliente`
- `cliente_respondeu`
- `resolvido`
- `fechado`

O projeto `roadrunners.run` deve respeitar esse conjunto para manter consistencia com o painel administrativo.

## Comportamento esperado da interface publica

O site principal deve permitir:

1. abrir novo chamado
2. escolher setor
3. informar assunto
4. enviar mensagem inicial
5. listar os chamados do usuario autenticado
6. abrir o detalhe de um chamado
7. acompanhar o historico de mensagens
8. enviar novas mensagens no mesmo chamado

O usuario final nao deve:

- trocar setor manualmente depois da abertura
- reatribuir responsavel
- encerrar chamados de forma administrativa sem regra de negocio especifica

## Comportamento esperado do painel Business

O painel administrativo deve permitir:

- ver todos os chamados
- filtrar ou organizar por setor e status
- responder chamados
- mover chamado de setor
- alterar status
- manter setores ativos/inativos
- definir usuario admin responsavel por setor

## Observacoes importantes

- O modulo atual do `Business` ja esta preparado para operar sobre essas tabelas.
- A interface publica do `roadrunners.run` ainda precisa ser implementada.
- O schema do banco esta descrito em [helpdesk/helpdesk_schema.sql](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/helpdesk_schema.sql).
