# Audiência editorial — publicação de 10/09/2026

## Resultado

Publicado em **10/09/2026 às 23:34:17 de Brasília** (`2026-09-11T02:34:17Z`, relógio do servidor), após o usuário informar a execução do SQL editorial. Validação pelo navegador em produção confirmou os novos sinais chegando ao **Business → Audiência e inventário → Conteúdo individual**. Não houve conexão direta ao banco de produção nem execução de SQL pelo agente nesta publicação.

O SQL informado pelo usuário é `_codex/sql/2026-09-10_audience_editorial.sql` do RoadRunners, SHA-256 `987ad749076e6535e58108c82cb9c47e83c2e00e409ee73b88d754377eff9ee9`. A aceitação dos novos eventos em produção confirma funcionalmente o contrato necessário; não representa auditoria independente da execução completa da migração pelo DBA.

## Escopo e backup

Publicados somente estes 13 arquivos, nesta ordem:

1. RoadRunners `services/AudienceMeasurementService.cfc`
2. RoadRunners `assets/js/rr-audience.js`
3. RoadRunners `api/home_news.cfm`
4. RoadRunners `api/noticias_busca.cfm`
5. RoadRunners `api/videos_busca.cfm`
6. RoadRunners `includes/estrutura/conteudo_lateral_api.cfm`
7. RoadRunners `includes/estrutura/noticias_lista_cards.cfm`
8. RoadRunners `includes/estrutura/videos_lista_cards.cfm`
9. RoadRunners `index.cfm`
10. RoadRunners `noticias/index.cfm`
11. RoadRunners `includes/analytics/bootstrap.cfm`
12. Business `portal/audiencia/queries/content.sql`
13. Business `portal/audiencia/home.cfm`

Não foram enviados testes, migrações, configurações ou checkouts completos. O `content.sql` publicado é a consulta privada do relatório, não uma migração. Não houve reinício de serviço.

- Manifesto dos hashes: [manifesto editorial](2026-09-10_audience_editorial_manifest.json).
- Pacote local: [runtime Linux](../releases/2026-09-10_audience_editorial_linux.tar.gz), SHA-256 `1a6c8f8345fc1424558635fcf211d1e3d6026883e423661ade9e561cc130cdbc`.
- Backup no host `ssh.runnerhub.run`: `/var/backups/rr-audience-editorial.w1RcDs`.
- O backup contém `before/road`, `before/business`, `before.sha256`, `before.metadata`, `guards.sha256`, `runtime.tsv`, `publish.sh`, o pacote e `published.log`.
- Raízes publicadas: `/var/www/roadrunners.com.br` e `/var/www/business.roadrunners.run`.

Os 13 arquivos remotos primeiro coincidiram com os hashes anteriores esperados; os backups foram conferidos antes de substituir cada destino, preservando proprietário, grupo e modo. A verificação final, repetida após os testes no navegador, retornou `Verified 13 published hashes/metadata and 28 unchanged guards.` Os 28 guardas incluem autenticação, configurações, Ads/cobrança, backend de eventos, coleta pública e backend do painel. O pacote de staging gerou aviso de timestamp futuro devido à diferença de aproximadamente 47 segundos entre os relógios; conteúdo, hashes e metadados finais foram validados, sem ajuste de relógio.

## Evidência de produção

Chrome autenticado, navegação real, identificada como **interna** no contexto da coleta. Nenhum evento foi injetado manualmente. O Business foi consultado temporariamente com acessos internos incluídos e famílias de página específicas, respeitando seu cache de até um minuto.

| Fluxo | Resultado observado no Business |
|---|---|
| Lista de notícias, primeiro card visível | Notícia `por-que-ele-trocou-de-camiseta-tantas-vezes-no-podio`: **1 cartão exposto**, **1 navegador exposto**, **0 aberturas** na família `news`. |
| Abrir a notícia e percorrer seu corpo até o último parágrafo visível | Na família `news_detail`: **1 página**, **1 abertura**, **1 visitante da abertura** e **1 ocorrência em cada marco de 25%, 50%, 75% e 100%**. O corpo estava inicialmente abaixo da tela; a medição de profundidade foi conferida após trazê-lo à área visível. |
| Vídeos da lateral no detalhe da notícia | IDs `nmLeBM_7ndM`, `u0pjXoZMC2I` e `yzLS9WIQfTM`: **1 exposição e 1 navegador por conteúdo**, sem abertura ou reprodução nessa família. |
| Lista de vídeos, card destacado visível | ID `u0pjXoZMC2I`: **1 exposição e 1 navegador** na família `videos`. Não foi aberto ou reproduzido um vídeo neste teste; essa linha já continha abertura/reprodução de validação anterior e não foi atribuída ao novo lote. |

O tracker servido nas listas/detalhe estava versionado como `rr-audience.js?v=9c78e93c98d7`. As novas colunas renderizaram sem erro de consulta e o Business continuou autenticado, sem pedir novo login. Última recepção observada durante os testes: **10/09 23:40, Brasília**.

Ao terminar, os filtros originais foram restaurados: 7 dias, contexto comercial, todas as UFs/páginas/dispositivos, produção e **acessos internos desmarcados**. A notícia usada no teste deixou de aparecer no resultado padrão. A aba temporária do RoadRunners foi fechada; abas do usuário foram preservadas. Não se alterou o viewport nesta validação de produção.

## Verificação local e limites

Antes da publicação, uma verificação independente repetiu os **83 testes Node do RoadRunners**, **5 testes JavaScript do Business**, sintaxe do tracker e comparação dos 13 hashes contra o manifesto aprovado, todos sem falha. Não houve alteração dos bytes de runtime já revisados. Os ensaios SQL/CFML e testes desktop/mobile locais estão registrados na [entrega técnica](2026-09-10_audiencia_editorial_entrega.md); não foram confundidos com execução no PostgreSQL/Adobe ColdFusion de produção.

A validação ao vivo cobriu fluxos representativos de lista, detalhe, lateral e lista de vídeos. A cobertura dos oito renderizadores e dos casos extremos de continuidade/deduplicação também depende dos testes locais registrados. Profundidade é posição alcançada na tela, não prova de leitura. Os novos sinais não têm histórico retroativo e os acessos de QA não entram na audiência comercial padrão.

## Reversão e continuidade

Se necessária, reverter somente os 13 destinos a partir dos respectivos arquivos em `before/`, conferindo `before.sha256` e preservando `before.metadata`. Não restaurar diretórios inteiros. A migração aditiva pode permanecer e os eventos aceitos não devem ser apagados. O backup foi criado, mas uma reversão não foi executada nesta entrega.

Sem alterações em login, cobrança, `tb_log`, DSN `runner`, permissões de `runner_dba`, escolha opt-out/GPC ou política de 90 dias. Retenção operacional permanece independente dos contadores. O plano maior ainda inclui promoções estáticas restantes, potencial visual de posições colapsadas, UF física confiável, retenção do DBA, projeção comercial com semanas completas e piloto de aquisição com verba aprovada. A retirada exclusiva do writer de view de evento em `tb_log` permanece para o final, após comprovar a substituição.
