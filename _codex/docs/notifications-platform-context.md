# Contexto Plataforma de Notificações

## Resumo rapido

O modulo `/notificacoes` do `Business` nao deve mais ser tratado como dono da entrega.

Estado atual:

- `Business` = painel operacional
- `Road Runners` = nucleo da plataforma de notificacoes

O envio administrativo do `Business` ja foi migrado para:

- `/api/notifications/integrations/dispatch.cfm`

## Arquivos mais importantes

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [notificacoes/includes/send_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/send_backend.cfm)
- [notificacoes/envio/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/envio/home.cfm)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- [includes/estrutura/header.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/header.cfm)
- [includes/estrutura/navbar.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/navbar.cfm)

## Regras atuais

### Envio

O `Business`:

- filtra os usuarios localmente
- le templates localmente
- monta payload
- assina handoff com HMAC
- chama a API central do `Road Runners`

Ele nao deve mais:

- inserir notificacoes operacionais em `tb_notifica` como fluxo principal
- tentar decidir sozinho a entrega push como regra de negocio primaria

### Topo do Business

O sino do topo precisa funcionar em qualquer pagina que renderize:

- [includes/estrutura/header.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/header.cfm)

Por isso o proprio header agora inclui `backend_login.cfm` quando a inbox ainda nao foi carregada.

### Help Desk

Os helpers do `Business` agora usam dispatch central:

- `helpdeskNotifyResponsibleAdmin(...)`
- `helpdeskNotifyTicketOwner(...)`

Eles nao devem mais fazer `INSERT INTO tb_notifica`.

## Contrato tecnico atual

Campos usados pelo `Business` no dispatch:

- `origin`
- `category`
- `id_notifica_template`
- `conteudo_notifica`
- `icone`
- `link`
- `data_publicacao`
- `data_expiracao`
- `userIds`
- `options.sendPush`

## Fallback de ambiente

Durante a transicao:

- o envio administrativo tenta a URL configurada
- se receber `404`
- tenta automaticamente a mesma rota em `dev.roadrunners.run`

Esse comportamento vale hoje para:

- painel `/notificacoes`
- helpers de notificacao do `/helpdesk`

## Cuidado importante

Se o dispatch central retornar erro como:

- `duplicate key value violates unique constraint "tb_notifica_id_usuario_id_notifica_template_uindex"`

o problema nao esta mais no `Business`.

Isso significa:

- a API central do `Road Runners` materializou com `INSERT`
- mas ja existia uma notificacao para o mesmo `id_usuario + id_notifica_template`

Nesses casos, a correcao esperada esta no `Road Runners`, provavelmente com `upsert`.

## Direcao futura

O caminho recomendado para futuras manutencoes e:

1. manter o `Business` como painel
2. centralizar cada vez mais a logica de notificacao no `Road Runners`
3. reduzir gradualmente leitura e escrita locais onde a API central ja cobrir o caso
