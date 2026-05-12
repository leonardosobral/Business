# Help Desk Road Runners Context

Este arquivo existe para orientar a implementacao do lado publico do Help Desk no projeto do site `roadrunners.run`.

## Resumo rapido

- O banco e compartilhado com o ecossistema Road Runners / Business.
- O `Business` ja foi ajustado para ser o painel administrativo de atendimento.
- O site `roadrunners.run` ainda precisa ganhar a interface de abertura e acompanhamento de chamados.
- O solicitante deve ser sempre o usuario autenticado em `tb_usuarios.id`.

## O que o outro projeto precisa entregar

O projeto `roadrunners.run` precisa criar uma area autenticada onde o usuario consiga:

- abrir chamado
- listar seus chamados
- abrir um chamado especifico
- acompanhar a conversa
- enviar novas mensagens

## O que nao precisa existir no site publico

Nao colocar no site do usuario final:

- gestao de setores
- troca manual de responsavel
- visao de chamados de outros usuarios
- fila completa
- reclassificacao administrativa irrestrita

## Tabelas consumidas

### `tb_helpdesk_setores`

Leitura publica:

- listar apenas setores `ativo = true`

Campos minimos relevantes para o site:

- `id_setor`
- `nome_setor`
- `descricao_setor`
- `ativo`

### `tb_helpdesk_chamados`

Uso no site:

- criar chamado
- listar chamados do usuario logado
- abrir detalhe de chamado proprio

Campos minimos relevantes:

- `id_chamado`
- `protocolo`
- `id_usuario`
- `id_setor`
- `assunto`
- `status`
- `created_at`
- `updated_at`

### `tb_helpdesk_mensagens`

Uso no site:

- inserir mensagem do usuario
- listar historico do chamado

Campos minimos relevantes:

- `id_mensagem`
- `id_chamado`
- `id_usuario`
- `mensagem`
- `interno`
- `created_at`

## Regra de seguranca

Toda query no site precisa filtrar por:

- `tb_helpdesk_chamados.id_usuario = usuario_logado`

E toda insercao de mensagem precisa validar:

- o chamado pertence ao usuario autenticado

Nunca confiar apenas no `id_chamado` vindo por `URL` ou `FORM`.

## Regra de status

Ao abrir novo chamado:

- status inicial: `aberto`

Ao usuario responder um chamado existente:

- status recomendado: `cliente_respondeu`

Estados visiveis no produto:

- `aberto`
- `em_atendimento`
- `aguardando_cliente`
- `cliente_respondeu`
- `resolvido`
- `fechado`

## Regra de ordenacao

### Lista de chamados

Ordenar por:

- `updated_at desc`
- `id_chamado desc`

### Mensagens

Ordenar por:

- `created_at asc`
- `id_mensagem asc`

## Regras de UX recomendadas

### Lista

Mostrar por chamado:

- protocolo
- assunto
- setor
- status
- ultima atualizacao

### Detalhe

Mostrar:

- protocolo
- assunto
- setor
- status
- historico completo
- formulario de nova resposta

### Nova abertura

Campos minimos:

- setor
- assunto
- mensagem inicial

## Regra de notificacao futura

O schema atual nao depende de notificacao automatica, mas o ideal e prever depois:

- aviso interno quando um usuario abre chamado
- aviso ao usuario quando admin responde

## Assuncao atual importante

O painel `Business` assume que o schema abaixo existe no banco:

- [helpdesk/helpdesk_schema.sql](/Users/geraldoprotta/IdeaProjects/Business/helpdesk/helpdesk_schema.sql)

Se o projeto `roadrunners.run` usar outro datasource ou outro schema, alinhar antes de implementar a interface.
