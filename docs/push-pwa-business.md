# Push PWA no Business

Atualizado em: 2026-05-19

## Objetivo

Documentar como o projeto `Business` precisa ser configurado para conseguir disparar Push notifications da PWA do `Road Runners` quando uma notificacao for enviada pela area:

- `/notificacoes/envio/`

Hoje o fluxo principal mudou:

1. o `Business` monta um dispatch administrativo
2. chama `/api/notifications/integrations/dispatch.cfm`
3. o `Road Runners` materializa a notificacao
4. o proprio `Road Runners` decide o envio push

O fallback local de push no `Business` deixou de ser o caminho principal e deve ser tratado como legado/contingencia.

## Configuracao mais importante hoje

O ponto principal agora e a configuracao do dispatch central:

```env
RR_NOTIFICATION_DISPATCH_URL=https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm
RR_PUSH_DISPATCH_TIMEOUT_SECONDS=20
RR_HANDOFF_SECRET=mesmo_segredo_usado_no_RoadRunners
```

Se `RR_NOTIFICATION_DISPATCH_URL` nao existir, o `Business` tenta derivar a URL nova a partir da configuracao antiga de push.

## Chaves VAPID

As chaves VAPID continuam relevantes para cenarios legados ou de contingencia, mas nao sao mais o centro do fluxo novo.

## Duas formas de configurar

O `Business` agora aceita dois modos:

1. variaveis de ambiente
2. arquivo local `config/pwa_push.local.cfm`

O arquivo local segue a mesma ideia usada no `Road Runners` e e lido em tempo de execucao pelo envio de notificacoes, sem depender de restart do ColdFusion.

## Opcao 1: variaveis obrigatorias

No servidor do `Business`, configurar:

```env
RR_PUSH_PUBLIC_KEY=...
RR_PUSH_PRIVATE_KEY=...
RR_PUSH_SUBJECT=mailto:contato@runnerhub.run
```

## Opcao 2: arquivo local sem restart

Criar:

- [config/pwa_push.local.cfm](/Users/geraldoprotta/IdeaProjects/Business/config/pwa_push.local.example.cfm)

Use este modelo:

```cfml
<cfscript>
localPushConfig = {
    "publicKey" = "SUA_CHAVE_PUBLICA_VAPID",
    "privateKey" = "SUA_CHAVE_PRIVADA_VAPID",
    "subject" = "mailto:contato@runnerhub.run"
};
</cfscript>
```

No repositório, o exemplo esta em:

- [config/pwa_push.local.example.cfm](/Users/geraldoprotta/IdeaProjects/Business/config/pwa_push.local.example.cfm)

## Variaveis opcionais

Essas variaveis ajudam a controlar a ponte HTTP entre `Business` e `Road Runners`:

```env
RR_NOTIFICATION_DISPATCH_URL=https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm
RR_PUSH_DISPATCH_URL=https://beta.roadrunners.run/api/push/send.cfm
RR_PUSH_DISPATCH_TIMEOUT_SECONDS=20
RR_HANDOFF_SECRET=mesmo_segredo_usado_no_RoadRunners
```

## Regras importantes

- `RR_PUSH_PUBLIC_KEY` e `RR_PUSH_PRIVATE_KEY` devem ser as mesmas usadas no `Road Runners`
- `RR_HANDOFF_SECRET` deve ser o mesmo segredo do `Road Runners` se a ponte HTTP for usada
- `RR_NOTIFICATION_DISPATCH_URL` e a variavel preferencial para o fluxo novo
- se o teste estiver em `beta.roadrunners.run`, o ideal e apontar explicitamente `RR_PUSH_DISPATCH_URL` para o host beta
- sem `RR_PUSH_PUBLIC_KEY` e `RR_PUSH_PRIVATE_KEY`, o `Business` nao consegue usar o fallback local

## Exemplo completo

```env
RR_PUSH_PUBLIC_KEY=CHAVE_PUBLICA_VAPID_AQUI
RR_PUSH_PRIVATE_KEY=CHAVE_PRIVADA_VAPID_AQUI
RR_PUSH_SUBJECT=mailto:contato@runnerhub.run
RR_NOTIFICATION_DISPATCH_URL=https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm
RR_PUSH_DISPATCH_URL=https://beta.roadrunners.run/api/push/send.cfm
RR_PUSH_DISPATCH_TIMEOUT_SECONDS=20
RR_HANDOFF_SECRET=SEGREDO_COMPARTILHADO_AQUI
```

## Onde o codigo usa isso

- configuracao inicial:
  - [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- envio de notificacoes e dispatch central:
  - [send_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/send_backend.cfm)

## Checklist de configuracao

1. Configurar as variaveis de ambiente no servico do ColdFusion do `Business`
2. Garantir que `RR_PUSH_DISPATCH_URL` aponte para o ambiente correto
3. Garantir que `RR_HANDOFF_SECRET` seja o mesmo do `Road Runners`
4. Recarregar o ambiente do ColdFusion
5. Enviar uma notificacao de teste para um usuario com subscription ativa
6. Validar se a notificacao web apareceu no portal
7. Validar se o Push foi recebido no PWA

## Ordem de precedencia

No envio do `Business`, a leitura fica assim:

1. variaveis de ambiente
2. arquivo `config/pwa_push.local.cfm`

Se a variavel de ambiente existir, ela prevalece.

## Como validar no Business

Na tela `/notificacoes/envio/`, os retornos mais relevantes agora sao:

- `sent`
  - o Push foi aceito
- `dispatch_requested`
  - o dispatch foi aceito e o push foi encaminhado ao `Road Runners`
- `no_active_subscriptions`
  - nao havia subscriptions ativas para os usuarios alvo
- `invalid_signature`
  - o handoff da API central falhou por segredo divergente
- `http_404`
  - endpoint remoto nao encontrado
- `internal_error`
  - a API central ou a camada de push do `Road Runners` falhou

## Observacao operacional

Se o endpoint central ainda nao estiver publicado em `prod` ou `beta`, o envio do `Business` tenta fallback automatico para `dev.roadrunners.run` quando recebe `404`. Mesmo assim, o ideal e explicitar a URL correta por ambiente:

```env
RR_NOTIFICATION_DISPATCH_URL=https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm
```
