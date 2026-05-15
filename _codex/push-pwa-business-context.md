# Contexto Push PWA no Business

## Resumo rapido

O modulo de envio de notificacoes do `Business` grava notificacoes em `tb_notifica` e tenta disparar Push da PWA do `Road Runners`.

Ordem atual de tentativa:

1. ponte HTTP para `Road Runners`
2. fallback local no proprio `Business`

## Dependencias de ambiente

Para o fallback local funcionar no `Business`, o processo do ColdFusion precisa enxergar:

- `RR_PUSH_PUBLIC_KEY`
- `RR_PUSH_PRIVATE_KEY`
- `RR_PUSH_SUBJECT`

Alternativamente, sem restart, o projeto aceita:

- `config/pwa_push.local.cfm`

Para a ponte HTTP funcionar com autenticacao consistente:

- `RR_HANDOFF_SECRET`
- `RR_PUSH_DISPATCH_URL`

## Arquivos chave

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [send_backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/includes/send_backend.cfm)
- [home.cfm](/Users/geraldoprotta/IdeaProjects/Business/notificacoes/envio/home.cfm)
- [pwa_push.local.example.cfm](/Users/geraldoprotta/IdeaProjects/Business/config/pwa_push.local.example.cfm)

## Sinais de diagnostico

- `local_push_unconfigured`
  - chaves VAPID ausentes no ambiente do `Business`
- `http_404`
  - endpoint remoto errado ou host errado
- `invalid_signature`
  - segredo de handoff divergente entre `Business` e `Road Runners`
- `no_active_subscriptions`
  - usuario alvo sem subscription ativa no ambiente
- `local_dispatch_failed`
  - o fallback local tentou disparar, mas o servico de push nao aceitou

## Causa comum em beta

Quando o teste esta sendo feito em `beta.roadrunners.run`, o `Business` precisa apontar explicitamente para o host beta:

```env
RR_PUSH_DISPATCH_URL=https://beta.roadrunners.run/api/push/send.cfm
```

Sem isso, a ponte pode tentar `roadrunners.run` por padrao.

## Expectativa funcional

- notificacao web deve aparecer no dropdown do portal
- Push deve acordar o service worker
- o PWA busca a notificacao pendente em `/api/push/pending.cfm`

## Nota importante

Se a mensagem no `Business` continuar em `dispatch_failed`, mas nao houver `local_push_unconfigured`, o proximo suspeito deixa de ser configuracao basica e passa a ser:

- subscriptions invalidas
- servico de push recusando o POST
- diferenca de ambiente `prod/beta/dev` nas subscriptions
