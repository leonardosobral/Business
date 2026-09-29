# Plataforma ordenada e Desafios e treinos no primeiro nível

Publicado somente `includes/estrutura/sidenav.cfm`: CRM interno e Vicky Pacer movidos para Plataforma; todos os itens dessa seção em ordem alfabética. Desafios e treinos promovido de subgrupo de Eventos e resultados para seção principal independente.

Links, ícones, aliases, badges e permissões preservados, incluindo a condição `businessCanShowUserManagementNavigation` do CRM interno. Bloco do menu cliente preservado integralmente.

## Verificação e recuperação

- Baseline produção/local: `212660ccee163f407e9c3b1bb5fc4a1b963fd1fd12115256c4cad35c93e11f49`.
- Hash publicado e verificado: `733384de4aa0bfe5870fb32bb7f9a213081440a58991f6ab70d43c0531a136e0`.
- Backup: `/var/backups/business-menu-plataforma-ordem-20260928/baseline`.
- Release pelo script `deploy_menu_experiencia.py`, argumento adicional `plataforma-ordem`.
- Quatro testes novos falharam antes da edição e passaram depois. 19 testes focados passaram no total; diff sem erros de whitespace.
- Adobe ColdFusion compilou 1/1 arquivo, retorno zero.
- Chrome autenticado: seção Plataforma ordenada, CRM e Vicky na seção correta; Desafios e treinos abre por Enter e mostra todos os links. Conferência visual desktop e mobile 390 px; viewport restaurado.
- Evidência: `_codex/staging/menu-plataforma-20260928/ordem-publicado.png`.

Sem alterações em banco, contratos ou lógica de notificações. Sem commit ou push.
