# Ads — auditoria de edição/pausa e orçamento esgotado

## Diagnóstico e alteração

O ColdFusion 2025 rejeitava o retorno do INSERT executado por
`services/accountDelegation/Store.cfc::audit`, pois `execute` declara retorno
`query`. Isso revertia a transação de `prepare_campaign_edit` e
`change_campaign_status`. O INSERT agora usa `RETURNING 1 AS recorded`, mantendo
o contrato tipado, a auditoria obrigatória e as verificações de autorização.

Em `ads/home.cfm`, o indicador de orçamento usa a mesma condição financeira do
leilão: `spent_total + cpc_bid > budget_total`. O cálculo decimal evita marcar
como esgotada uma campanha cujo restante seja exatamente igual ao lance.
É apenas uma indicação visual para campanhas ACTIVE/PAUSED; não altera status,
saldo, orçamento, entrega ou aprovação. Rascunhos, finalizadas e lance zero não
recebem esse indicador.

O aviso aparece na visão geral, listagem da conta, detalhe e operação global
(`workspace_campaigns.cfm`, `workspace_campaign_detail.cfm`, `workspace_admin.cfm`).
O widget de campanhas ativas informa quantas estão sem exibição por orçamento.
Campanhas pausadas mantêm seu status, com explicação de orçamento no detalhe.
Saldo da conta e limite da campanha permanecem conceitos separados.

## Validação e publicação

- 17 verificações no ColdFusion 2025.0.13: limites decimais, reprodução do erro
  original, auditoria corrigida, rejeição de contexto inválido e rollback integral.
- O teste escreve exclusivamente auditoria dentro de uma transação revertida;
  nenhum status de campanha, saldo ou limite foi alterado para testar.
- Os testes foram repetidos contra o componente publicado. Não foi executado
  um POST de pausa/edição em campanha de cliente pelo navegador.
- Cinco templates/componentes compilados no compilador do servidor.
- Conferência autenticada real: operação global; visão geral/listagem e detalhe
  do Grupo STC; menu Gerenciar com Pausar/Pausar e editar. As três campanhas
  identificadas no diagnóstico exibem o novo aviso. Seleção de conta restaurada
  para Todas as contas após a conferência.
- Conferência desktop concluída. A tentativa visual a 390px ficou prejudicada
  pelo menu lateral sobreposto da estrutura existente; não houve alteração
  dessa estrutura nesta tarefa. Viewport restaurado.
- Baseline dos cinco arquivos coincidia com a versão original local. Publicação
  em 24/10/2026 às 20:54 BRT, com hashes e dependências preservadas.
- Backup: `/var/backups/ads-budget-edit-20261024-rqi3gkb1/baseline`.
- Evidências e scripts: `_codex/staging/ads-budget-edit-20261024/`.

Sem migration, mudanças no RoadRunners ou operações Git. Para voltar a concorrer,
o responsável deve revisar o orçamento/lance e seguir o fluxo de nova aprovação.
