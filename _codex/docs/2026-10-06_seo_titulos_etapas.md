# Títulos de etapas e evidência RR-30 — 06/10/2026

## Entrega publicada

RoadRunners: `includes/estrutura/event_title_date.cfm`.
Business: `portal/includes/seo_queue_data.cfm` e `portal/conteudo/seo_semrush.cfm`.

Cinco eventos (Correr é Massa em Curitiba, Apucarana e Santa Terezinha de Itaipu; Track&Field Motiva Aeroportos em Curitiba e Londrina) possuíam nomes completos distintos, mas o corte do nome em 50 caracteres retirava o trecho que os distinguia. O include compartilhado agora apresenta cidade, UF e data cadastradas quando nomes diferentes colidem nesse prefixo. Em empate de local/data, conserva o nome completo. Foram conferidas as versões em português, inglês e espanhol.

A regra anterior de nomes iguais em datas diferentes é preservada. Nomes já diferenciados por datas não executam o bloco novo de prefixos. Títulos únicos fora dos cinco eventos conservaram seu conteúdo anterior. Não houve alteração de nomes, cidades, datas ou outros campos de cadastro, nem de canonical, H1, descrição, alternates ou JSON-LD.

A consulta compartilhada utiliza SQL fixo e cache de dez minutos. EXPLAIN em transação READ ONLY mediu 74,164 ms de execução fria e 95 grupos. É uma medição pontual, sem promessa de desempenho contínuo. Nenhum índice ou migração foi criado.

## Validação e revisão

- 64 verificações Adobe ColdFusion aprovadas no candidato final. O baseline inicial reproduziu 38 falhas em 60 verificações; casos adicionais passaram a proteger títulos já distintos e a combinação de nomes repetidos por data com outros nomes de prefixo igual.
- A primeira publicação retirou duplicações, mas o gate público encontrou alterações extras nos eventos 46596/46597. A publicação do painel foi bloqueada internamente até a correção. Astra encontrou ainda um caso de combinação de nomes/datas/prefixos; a fixture reproduziu as duas falhas e o guard final as corrigiu. Revisão final sem impedimentos.
- Tabelas temporárias transacionais usadas somente em fixtures, com limpeza ao concluir. Nenhum cadastro persistente foi alterado. Cache desativado somente nas cópias de teste; páginas públicas usam o cache real.
- Compilação Adobe antes de cada publicação; backups recuperáveis; hashes de um runtime RoadRunners e 14 dependências, e dois runtimes Business e dez dependências conferidos.
- 62 URLs originais conferidas após a publicação: 61 HTTP200 com títulos únicos e alias FCA HTTP301. Status, canonical, descrição, H1 e robots preservados. Títulos fora dos cinco eventos não mudaram.
- 15 versões PT/EN/ES dos cinco eventos: títulos distintos e com local/data cadastrados; `og:title` e `twitter:title` alinhados. Canonical, alternates, H1, descrição e JSON-LD preservados. Include direto HTTP404.
- 19 cenários do painel aprovados antes/depois da publicação, incluindo oito controles de acesso, escaping e separação OpenResults. Layout/CSS não alterados.

Gate público final: `2026-10-06T11:37:49.579971+00:00`. Fontes e recibos no staging Business `_codex/staging/seo-duplicacoes-20261005/`.

## Painel e limites

RR-30 documenta o lote publicado e a conferência direta. RR-20 segue parcial, pois há outros tipos de problema na auditoria. Os totais, notas e datas Semrush e o snapshot orgânico foram preservados: snapshot `6ac31bf647d73ceec1b0b861`, coleta concluída em 05/10/2026 às 01:37 (Brasília), 5.000 páginas.

A conexão Semrush não está exposta nesta sessão (catálogo informa plugin disponível, mas não instalado). Não foi atribuída nova coleta ao fornecedor. Esta validação não mede indexação Google, posições, CTR ou audiência, nem confirma resultado global em URLs fora da amostra. Efeitos devem ser conferidos em nova auditoria comparável e no Search Console.

Sem alteração de autenticação, GA4, Cloudflare, cadastros, redirects, sitemap ou operações Git.

## Recuperação

Backups efetivamente publicados:

- `/var/backups/seo-title-cities-20261005-rr/baseline` — include antes da primeira publicação.
- `/var/backups/seo-title-cities-followup-20261006-rr/baseline` — primeira versão antes do complemento final.
- `/var/backups/seo-title-cities-final-20261006-business/baseline` — dois templates Business antes do lote.

Se necessária reversão total, executar no staging `release_followup.py business rollback`, depois `release_followup.py rr rollback`, e por último `release.py rr rollback`. Os scripts recusam drift; conciliar alterações posteriores antes de qualquer reversão. Os outros prepares Business de 05/10 e 06/10 não foram publicados. Os recibos finais são `rr-followup-publish.json`, `rr-followup-verify.json`, `business-followup-publish.json`, `business-followup-verify.json`, `public-passed.json`, `tests-green.json` e `published-render-passed.json`.
