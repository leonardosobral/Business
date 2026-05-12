# Help Desk Public Contract

Contrato funcional sugerido para o projeto `roadrunners.run` implementar a interface publica de chamados.

Este arquivo nao obriga um formato especifico de rota ou framework. Ele descreve o comportamento minimo necessario para conversar com o mesmo banco e permanecer compativel com o painel administrativo do `Business`.

## Fluxos obrigatorios

### 1. Abrir chamado

Entrada:

- usuario autenticado
- `id_setor`
- `assunto`
- `mensagem`

Efeito esperado:

1. inserir em `tb_helpdesk_chamados`
2. inserir a primeira mensagem em `tb_helpdesk_mensagens`
3. redirecionar para o detalhe do chamado criado

Regras:

- `id_usuario` vem da sessao autenticada, nunca do cliente
- `status = 'aberto'`
- gerar `protocolo` unico

## 2. Listar chamados do usuario

Filtro obrigatorio:

- `id_usuario = usuario_logado`

Colunas minimas:

- `id_chamado`
- `protocolo`
- `assunto`
- `status`
- `updated_at`
- `nome_setor`

## 3. Abrir detalhe de chamado

Filtro obrigatorio:

- `id_chamado = ?`
- `id_usuario = usuario_logado`

Retornar:

- dados do chamado
- mensagens do chamado

## 4. Responder chamado

Entrada:

- `id_chamado`
- `mensagem`

Validações:

- chamado pertence ao usuario logado
- mensagem nao vazia

Efeito esperado:

1. inserir em `tb_helpdesk_mensagens`
2. atualizar `tb_helpdesk_chamados.updated_at = now()`
3. atualizar `tb_helpdesk_chamados.status = 'cliente_respondeu'`

## SQL mental model

### Criar chamado

Inserir em:

- `tb_helpdesk_chamados`
- `tb_helpdesk_mensagens`

### Buscar lista

Base:

```sql
select cham.id_chamado,
       cham.protocolo,
       cham.assunto,
       cham.status,
       cham.updated_at,
       setr.nome_setor
from tb_helpdesk_chamados cham
inner join tb_helpdesk_setores setr on setr.id_setor = cham.id_setor
where cham.id_usuario = :usuario_logado
order by cham.updated_at desc, cham.id_chamado desc
```

### Buscar detalhe

```sql
select *
from tb_helpdesk_chamados
where id_chamado = :id_chamado
  and id_usuario = :usuario_logado
```

### Buscar mensagens

```sql
select msg.*,
       usr.name,
       usr.email,
       usr.is_admin
from tb_helpdesk_mensagens msg
inner join tb_usuarios usr on usr.id = msg.id_usuario
where msg.id_chamado = :id_chamado
order by msg.created_at asc, msg.id_mensagem asc
```

## Campos que o frontend deve traduzir

### Status

Mapear visualmente:

- `aberto`
- `em_atendimento`
- `aguardando_cliente`
- `cliente_respondeu`
- `resolvido`
- `fechado`

## Regras de exibicao sugeridas

### Badge de status

- `aberto`: warning
- `em_atendimento`: primary
- `aguardando_cliente`: info
- `cliente_respondeu`: warning
- `resolvido`: success
- `fechado`: secondary

### Mensagens

Mensagens enviadas por admin podem receber destaque visual quando:

- `tb_usuarios.is_admin = true`

## Escopo fora deste contrato

Este contrato nao cobre:

- anexos
- SLA
- prioridade
- macro respostas
- notificacoes por email
- automacoes por WhatsApp

Esses itens podem ser adicionados depois sem invalidar a estrutura base do chamado.
