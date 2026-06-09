# Codex Context

Esta pasta existe para dar contexto operacional rapido a futuras execucoes, manutencoes e integracoes no projeto `Business`.

## Arquivos

- [Contexto Geral](context.md)
- [Mapa de Domínios](domain-map.md)
- [Guia de Edição](editing-guidelines.md)
- [Contexto Help Desk para Road Runners](helpdesk-roadrunners-context.md)
- [Contrato Público do Help Desk](helpdesk-public-contract.md)
- [Mapa de Integrações](integration-map.md)
- [Contexto Plataforma de Notificações](notifications-platform-context.md)
- [Contexto Portal Banners](portal-banners-context.md)
- [Contexto Runner Apps API](runner-apps-api-context.md)
- [Contexto Push PWA no Business](push-pwa-business-context.md)
- [Checklist para Novas Features](feature-checklist.md)
- [Plano de Producao Business](plano-producao-business.md)

## SQL auxiliar

- [DDL do banco](../sql/ddl.sql): snapshot auxiliar do schema para consulta estatica. Antes de aplicar mudancas, validar sempre contra o banco do ambiente alvo.
- [Cadastro externo Business](../sql/2026-06-09_tb_conta_cadastro_solicitacoes.sql): migration incremental para a fila de solicitacoes de contas.

## Uso esperado

Esta pasta nao substitui `/docs`. Ela resume:

- como o sistema realmente se comporta
- onde editar com menos risco
- o que validar antes de tocar em modulos criticos
- quais dependencias externas devem ser consideradas
