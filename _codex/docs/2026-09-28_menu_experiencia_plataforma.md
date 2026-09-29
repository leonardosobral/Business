# Runner Apps, Notificações e Temas em Plataforma

Movidos os três links do menu administrativo de Conteúdo e portal para o início de Plataforma. Removido o subtítulo Experiência do portal, que ficaria vazio. Links, aliases de busca, ícones, condições de item ativo e permissões preservados; menu cliente não alterado.

## Escopo e publicação

- Runtime: `includes/estrutura/sidenav.cfm` somente.
- Baseline local e produção idênticos: `9ebf363c67f8f823f9d6735ba46396e255b313a97a0e47cc5a81ba19d97a9399`.
- Publicado: `212660ccee163f407e9c3b1bb5fc4a1b963fd1fd12115256c4cad35c93e11f49`.
- Backup recuperável: `/var/backups/business-menu-experiencia-20260928/baseline`.
- Alterações anteriores no menu preservadas, sem publicação de outros arquivos ou alteração de banco.
- Script de release: `_codex/scripts/deploy_menu_experiencia.py`; modos prepare, compile, publish, verify e rollback.

## Verificação

- Três testes novos falharam antes da movimentação e passaram depois.
- 15 testes focados de navegação e pendências passaram.
- `git diff --check` sem erros.
- Adobe ColdFusion: successful 1, total 1, retorno 0.
- Hash remoto verificado após publicação.
- Chrome autenticado: Plataforma expandida automaticamente em `/notificacoes/`, contendo os três links; verificação visual desktop e menu aberto em 390 px, viewport restaurado.
- Evidência: `_codex/staging/menu-plataforma-20260928/experiencia-publicado.png`.

A proposta anterior de separar estatísticas de notificações por destinatários admin não faz parte desta publicação.
