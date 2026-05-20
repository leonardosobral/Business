# Contexto Push PWA no Business

## Resumo rapido

O modulo de envio de notificacoes do `Business` nao deve mais ser entendido como gravacao local em `tb_notifica`.

Estado atual:

1. o `Business` monta o dispatch
2. chama a API central de notificacoes do `Road Runners`
3. o `Road Runners` materializa `tb_notifica`
4. o proprio `Road Runners` tenta o push quando aplicavel

## Dependencias de ambiente

Para o fallback local funcionar no `Business`, o processo do ColdFusion precisa enxergar:

- `RR_PUSH_PUBLIC_KEY`
- `RR_PUSH_PRIVATE_KEY`
- `RR_PUSH_SUBJECT`

Alternativamente, sem restart, o projeto aceita:

- `config/pwa_push.local.cfm`

Para a ponte HTTP funcionar com autenticacao consistente:

- `RR_HANDOFF_SECRET`
- `RR_NOTIFICATION_DISPATCH_URL`
- `RR_PUSH_DISPATCH_URL`

## Arquivos chave

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [send_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/send_backend.cfm)
- [home.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/envio/home.cfm)
- [pwa_push.local.example.cfm](/Users/geraldoprotta/IdeaProjects/Business/config/pwa_push.local.example.cfm)

## Sinais de diagnostico

- `http_404`
  - endpoint remoto errado ou host errado
- `invalid_signature`
  - segredo de handoff divergente entre `Business` e `Road Runners`
- `no_active_subscriptions`
  - usuario alvo sem subscription ativa no ambiente
- `internal_error`
  - a API central ou a camada de push do `Road Runners` falhou

## Causa comum em beta

Quando o teste esta sendo feito em `beta.roadrunners.run`, o `Business` precisa apontar explicitamente para o host beta:

```env
RR_NOTIFICATION_DISPATCH_URL=https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm
```

Sem isso, a ponte pode tentar `roadrunners.run` por padrao.

## Expectativa funcional

- notificacao web deve ser materializada pela API central
- notificacao web deve aparecer no dropdown do portal
- Push deve acordar o service worker quando o ambiente tiver subscription valida

## Nota importante

Se a mensagem no `Business` vier com `internal_error` ou conflito de unicidade, o foco do diagnostico deve sair do `Business` e ir para o `Road Runners`, especialmente em:

- materializacao central com conflito de unicidade
- configuracao do push no ambiente alvo
- subscriptions invalidas no ambiente correto
