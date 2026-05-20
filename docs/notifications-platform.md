# Plataforma de Notificações

Atualizado em: 2026-05-19

## Objetivo

Documentar o estado atual do modulo `/notificacoes` no projeto `Business` depois da migracao para a API central do `Road Runners`.

Hoje o `Business` continua sendo o painel operacional de notificacoes, mas deixou de ser a fonte principal da logica de entrega. O papel dele agora e:

- gerenciar templates
- montar filtros de audiencia
- disparar envios administrativos
- exibir o historico operacional
- consumir a API central do `Road Runners`

## Arquivos principais

- [notificacoes/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/index.cfm)
- [notificacoes/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/home.cfm)
- [notificacoes/envio/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/envio/home.cfm)
- [notificacoes/includes/backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/backend.cfm)
- [notificacoes/includes/send_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/send_backend.cfm)
- [notificacoes/includes/templates_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/templates_backend.cfm)
- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)

## O que mudou

### Antes

O fluxo de envio do `Business`:

- selecionava os destinatarios
- gravava ou atualizava `tb_notifica` localmente
- tentava resolver o push a partir do proprio `Business`

### Agora

O fluxo principal de envio:

1. operador monta a audiencia e escolhe o template
2. `Business` monta o payload de dispatch
3. `Business` assina o handoff com HMAC
4. `Business` chama `/api/notifications/integrations/dispatch.cfm`
5. `Road Runners` materializa `tb_notifica`
6. `Road Runners` tenta disparar push quando `sendPush = true`

O `Business` passa a exibir o retorno consolidado da API central.

## Configuracao compartilhada

O `Business` usa:

- `APPLICATION.notificationDispatch.url`
- `APPLICATION.notificationDispatch.secret`
- `APPLICATION.notificationDispatch.timeoutSeconds`

Esses valores sao preparados em:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)

O fallback atual da URL do dispatch:

- tenta a URL configurada
- se ela ainda estiver apontando para o modelo antigo `/api/push/...`, converte automaticamente para `/api/notifications/integrations/dispatch.cfm`
- se a tentativa principal responder `404`, o envio tenta o mesmo endpoint em `dev.roadrunners.run`

Esse fallback existe para a fase de transicao em que a API central ainda nao esteja publicada em todos os ambientes.

## Payload atual do envio administrativo

O painel monta um payload neste formato:

```json
{
  "origin": "business",
  "category": "painel_operacional",
  "id_notifica_template": 8,
  "conteudo_notifica": "<html do template>",
  "icone": "fa-solid fa-bell",
  "link": "/alguma-rota/",
  "data_publicacao": "2026-05-19 10:30:00",
  "data_expiracao": "2026-05-22 10:30:00",
  "userIds": [142, 16468],
  "options": {
    "sendPush": true
  }
}
```

Observacoes:

- `sendPush = true` apenas quando a publicacao e imediata
- para publicacoes futuras, o `Business` envia sem push imediato
- o template ainda e lido localmente em `tb_notifica_template`

## Status operacionais relevantes

Na tela `/notificacoes/envio/`, os retornos mais importantes agora sao:

- `enviado`
  - o dispatch foi aceito e as notificacoes foram materializadas
- `dispatch_requested`
  - a API central recebeu o dispatch e encaminhou o push para processamento
- `sent`
  - o endpoint de push confirmou entregas aceitas
- `no_active_subscriptions`
  - nenhum destinatario tinha push ativo no ambiente atual
- `push_disabled`
  - o push nao esta habilitado no ambiente do `Road Runners`
- `scheduled`
  - a notificacao foi agendada e nao tentou push agora
- `invalid_signature`
  - o handoff foi recusado
- `invalid_payload`
  - o payload enviado foi recusado
- `internal_error`
  - a API central ou a camada de push retornou falha interna
- `api_http_401`, `api_http_404`, `api_http_500`
  - falhas HTTP da API central

## Historico e templates

Os submodulos abaixo continuam locais no `Business`:

- templates em `tb_notifica_template`
- historico operacional baseado em `tb_notifica`

Isso foi mantido porque os endpoints administrativos dedicados da nova API ainda nao substituem integralmente essas telas.

## Inbox no topo do Business

O sino do topo no `Business` passou a carregar a inbox sempre que o header e renderizado.

Arquivos envolvidos:

- [includes/estrutura/header.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/header.cfm)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- [includes/estrutura/navbar.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/estrutura/navbar.cfm)

Comportamento:

- se `qNotificacoes`, `qNotificacoesNaoLidas`, `qPerfil` ou `roadRunnersBaseUrl` nao estiverem disponiveis
- o `header` inclui automaticamente `backend_login.cfm`
- assim o topo deixa de depender do bootstrap especifico de cada pagina

## Risco atual conhecido

O dispatch central ainda herda a restricao de unicidade do banco em:

- `tb_notifica_id_usuario_id_notifica_template_uindex`

Na pratica, isso significa que a API central pode falhar se tentar inserir uma notificacao para o mesmo:

- `id_usuario`
- `id_notifica_template`

quando a camada de materializacao do `Road Runners` ainda estiver usando `INSERT` simples em vez de `upsert`.

## Recomendacao operacional

Para estabilizar totalmente a plataforma:

1. o `Road Runners` deve aplicar `upsert` na materializacao central quando a regra de negocio for reutilizacao por template
2. os endpoints administrativos da nova API devem amadurecer para substituir gradualmente o historico local do `Business`
3. o fallback legado de push no `Business` deve permanecer apenas como contingencia, nao como fluxo principal
