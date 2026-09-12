# CTR e CPC médio no resumo operacional

## Implementação local

- `ads/includes/workspace_admin.cfm`: CTR e CPC médio substituem término no resumo; período completo permanece nos detalhes.
- CTR sem impressões aparece como travessão, com explicação no título, tanto no resumo quanto no detalhamento.
- CPC médio continua sendo custo dividido por cliques cobráveis; nenhuma mudança em contagem, cobrança, SQL ou banco.
- Coluna ampliada para acomodar as métricas.

## Validação

- Teste CFML real `_codex/tests/ads-operational-summary.cfm`: RED antes da mudança; GREEN depois.
- Casos: 17 impressões/3 cliques/custo 1,53 = CTR 17,65% e CPC 0,51; zero impressões/zero cliques; zero impressões/um clique cobrável/custo 0,94 = CTR indefinido e CPC 0,94.
- Datas preservadas no detalhamento e isolamento entre campanhas verificados.
- `bash _codex/scripts/test_ads_performance_dashboard.sh`: PASS.
- `git diff --check`: PASS.
- Após publicação: compilação Adobe ColdFusion dos includes passou (14/14, exit 0). Chrome confirmou CTR/CPC no resumo e datas no detalhe expandido; screenshot desktop conferido. Viewport móvel não validado nesta rodada. Renderização offline usa CommandBox.

## Publicação concluída

O usuário aprovou aplicar/publicar em resposta à proposta. A revisão automática exigiu confirmação adicional do host específico; o usuário confirmou em novo turno. Publicação concluída em 12/09/2026 às 01:04:33 UTC (11/09 às 22:04:33 em São Paulo), somente deste template.

- SHA local candidato: `4047a859ffba4367d049897d681880a37d8e5eea0fbf64444c090cbfeadb30cc`
- SHA anterior preservado no backup: `85b0a3136633290061194f3ce741121738143ca603e4bb122c08bb0621813eae`
- Destino: `/var/www/business.roadrunners.run/ads/includes/workspace_admin.cfm`
- Backup: `/var/backups/business-summary-ctr-20260911.MAjYDP/workspace_admin.cfm.before`.
- Hash publicado confirmado igual ao candidato. Substituição atômica com guardas de hash, modo 0644 e uid/gid 501:50. Sem migration ou alteração de campanhas.
- Rollback: confirmar que produção ainda tem o hash candidato, restaurar somente o template a partir do backup e recompilar. Não sobrescrever mudanças posteriores.

## Investigação separada: cliques sem impressões

Confirmado no código: impressão visível requer 50% de interseção por 1 segundo; o endpoint de clique é independente e não exige uma impressão anterior no fluxo consultado. Isso permite o sintoma, mas não estabelece a origem dos casos específicos. O painel soma as métricas canônicas por campanha/conta.

Diferença identificada entre código local e produção no RoadRunners:

- `includes/ads_v1/viewability.cfm` local: `505d148a965e653c8b1ad0370f0a81eacdad80ab558d26dcbe1959741c130af0`.
- Produção: `6824fabb64fc6715d6e48464113560636e78ded7f1004b6a2c1557c1eb37bc20`.
- Produção tem DOMContentLoaded/IntersectionObserver, mas não tem as verificações locais de aba visível e imagem carregada. Essa diferença não prova a causa da subcontagem (as verificações ausentes podem supercontar).
- Endpoint cpc-click local e produção coincidem: `846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82`.
- cpc-viewable local suprime exceções; sendBeacon enfileirado não confirma gravação. Necessário correlacionar eventos/entregas e respostas para determinar a causa; não houve consulta aos eventos de produção nesta investigação.
- Não foi alterado RoadRunners, nem criado clique de teste, corrigida métrica histórica ou modificada cobrança.
