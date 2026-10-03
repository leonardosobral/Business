# Modal de membros — correção do timeout CFQUERY

## Causa e mudança

O canal 3 possui 5.768 membros ativos. A consulta anterior reutilizava um CTE
inline com `EXISTS` correlacionados para relações sociais e uma busca lateral
de perfil por membro. O PostgreSQL 17 repetia esses subplanos ao filtrar,
ordenar e paginar; o plano do canal grande incluía 128 funções JIT. A consulta
real não terminou dentro do limite diagnóstico de 5 segundos (5.114 ms).
O teste de regressão com `statement_timeout` local de 3 segundos também
falhou no código anterior (3.006 ms).

Em `rrChatGroupMembersPage`, relações do leitor agora são calculadas uma vez
em CTEs materializados. Canais filtram candidatos pelo vínculo confirmado
de **seguindo** antes de buscar seus perfis. Perfis são selecionados em lote,
com `DISTINCT ON`, preservando o perfil de atleta de menor ID e evitando
duplicações de associações legadas. Nos grupos, seguindo e seguidores
continuam recebendo prioridade.

Não houve aumento de timeout de runtime, alteração de JIT/configuração,
índice, migração, credencial, permissões ou inscrição real para testar.
O limite de 30, cursor composto, elegibilidade, bloqueio de moderação,
permissões de leitura e privacidade de canais inclusive para admins globais
permanecem. Apenas um arquivo runtime foi publicado:
`includes/backend/backend_chat_groups.cfm`.

## Verificação

- Teste de desempenho real após publicação: produção 22 ms; dev 19 ms.
  Ambos devolveram os 16 membros seguidos esperados do canal com 5.768
  membros. 4/4 checks em cada ambiente, usando conjunto de referência
  independente da consulta implementada. Transações de teste revertidas.
- 23/23 checks CF/SQL de paginação/privacidade em produção e dev, com
  65 membros temporários: associação repetida, múltiplos perfis/vínculos,
  seleção do primeiro perfil, paginação, alterações de seguir entre lotes,
  cursores inválidos, membro removido e autorização. Fixtures revertidos.
- 49/49 checks CF/SQL de governança em produção e dev, também revertidos.
- Compilador Adobe: 2/2 templates (helper e dependência) no candidato.
- 22/22 testes JS do pager/modal e comunidades. Suíte ampliada RR: 160/160.
- Suíte ampliada Business: 344/349, com as mesmas cinco falhas externas
  ao escopo: `google-agenda-browser.test.js` requer `jsdom` ausente;
  `google-agenda-schema.test.js` e `google-drive-schema.test.js` requerem
  `@electric-sql/pglite` ausente; dois checks de
  `mif-report-deployment-contract.test.js` usam um Python inexistente
  de outro usuário e o commit antigo `87ccfa7`. Não modificados.
- Revisão independente sem problemas críticos/importantes. Sugestões
  menores de cobertura de perfis duplicados e conjunto esperado incorporadas.
- UI de produção: sessão existente Victoria Coelho, canal Road Runners
  (3 membros), modal abre sem timeout e lista somente Geraldo Protta, o
  único seguido. Essa sessão não tem acesso ao canal 3; o desempenho do
  canal grande foi validado diretamente com o helper real e um admin
  global em transação, sem mudar sessão ou inscrições do navegador.
- `git diff --check` nos dois projetos e hashes local/prod/dev conferidos.

## Publicação e recuperação

Baseline prod/dev:
`875454dd3b7175a6ae10c3de0acfb02082b5daf0c5eb03a2c560e10aa2f96bb7`.
Publicado local/prod/dev:
`dd5d61c75df9cb70f5cd0cd1bcc667fa3f92eaac32c381ff73315b42fe5e1130`.

Backup recuperável:
`/var/backups/rr-chat-members-timeout-20261002-lRwDYoIk`, com cópia original
do único arquivo em `prod` e `dev`, manifests `baseline.sha256` e
`published.sha256`. Para rollback, conferir mudanças posteriores e restaurar
somente esse arquivo, preservando seus metadados numéricos.

Beta não foi sobrescrito por estar divergente no baseline da tarefa anterior.
Mudanças existentes de outras frentes foram preservadas. Sem commit/push/PR.
Sondas temporárias restritas a loopback transferidas do webroot para
`test-probes` no backup ao concluir; não são endpoints de produto.
