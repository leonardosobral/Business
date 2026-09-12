# Campanhas em operação: resumo e expansão

Publicado em 11/09/2026, 20:12:03 UTC, com autorização do usuário.

## Alteração

- Resumo compacto por campanha: nome e conta, status, investimento, impressões/cliques e término.
- Ver detalhes/Recolher abre cada campanha independentemente, sem recarregar, usando details/summary nativos.
- Detalhamento preserva evento, público, todos os locais de exibição, lance, orçamento, limite diário, CTR, CPC médio, entregas, período, aprovação e ID.
- Layout responsivo com regras para 1100px e 600px; nenhuma alteração nas consultas ou regras de veiculação.
- Sem migration, reinício de serviço ou novo JavaScript.

## Verificação

- Teste offline `_codex/tests/ads-operational-summary.cfm`: falhou com a tabela anterior e passou após a implementação. Renderiza o bloco CFML real com duas campanhas sintéticas; verifica isolamento, detalhes inicialmente fechados, escaping, métricas e denominadores zero.
- `bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh`: passou.
- `git diff --check`: passou.
- Compilação ColdFusion em produção de `ads/includes`: 14/14 arquivos, exit 0.
- Chrome em produção, Todas as contas: 15 campanhas exibidas. Primeira campanha expandida e recolhida; outras permaneceram fechadas. Árvore de acessibilidade confirmou estados expanded/collapsed e conteúdo correto. Screenshot conferido visualmente.
- Não houve envio, aprovação ou edição de campanhas reais. Viewport móvel não testado no navegador.

## Publicação

Único arquivo de runtime publicado: `ads/includes/workspace_admin.cfm`.

- SHA-256 anterior: `29de5e4cd3dc6b4b56e8e41a0049c1086de7ba42697827f83422c06d5a5f3292`
- SHA-256 publicado: `85b0a3136633290061194f3ce741121738143ca603e4bb122c08bb0621813eae`
- Backup: `/var/backups/business-operation-summary-20260911.89ohQ2/workspace_admin.cfm.before`
- Destino: `/var/www/business.roadrunners.run/ads/includes/workspace_admin.cfm`
- Troca atômica com validação dos hashes anterior e novo; modo 0644, uid 501, gid 50.

Rollback: primeiro confirmar que o destino ainda tem o hash publicado acima, para não sobrescrever alterações posteriores. Restaurar somente este arquivo a partir do backup e recompilar o diretório de includes.
