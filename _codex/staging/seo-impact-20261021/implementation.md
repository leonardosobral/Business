# SEO — dependência compartilhada e títulos por cidade, 21/10/2026

Publicado em produção em 21/10/2026 às 15:34:13 UTC (12:34:13 de Brasília).

## Open Results e cabeçalho compartilhado

A auditoria de 5.000 URLs reportava 3.154 ocorrências de JS/CSS internos quebrados. Nas dez primeiras linhas, o recurso era `runner-apps-menu-lazy.min.js?v=20261008seo`. A origem confirmou 404 para esse caminho no Open Results. O responsável era o menu do Road Runners incluído por `OpenResults/includes/header.cfm`, com script e catálogo relativos ao domínio consumidor.

`RoadRunners/includes/estrutura/menu_apps.cfm` agora resolve o script pelo `REQUEST.currentBaseUrl` configurado. Não se copiou o JavaScript para outro projeto. Novo `OpenResults/api/runner_apps_menu.cfm` reutiliza o provedor público existente do Road Runners por include, atendendo a chamada de catálogo na mesma origem, sem mudar CORS, autenticação ou regras de cache.

O navegador público confirmou o script correto, menu com `data-runner-apps-loaded=true` e oito apps. A rota publicada retornou GET 200 com oito itens; POST 405. O script servido pelo Road Runners respondeu 200. Não se afirma que o antigo caminho ausente do Open Results passou a existir: os consumidores foram corrigidos.

## Títulos do Road Runners

`RoadRunners/includes/estrutura/event_title_date.cfm` passa a distinguir provas com nome igual, ignorando caixa, que ocorrem na mesma data em cidades/UFs diferentes. A consulta usa somente os campos cadastrados. O novo ramo preserva o nome completo e o local; quando necessário, retira primeiro a descrição opcional da modalidade em vez de cortar a identidade da prova.

Exemplos conferidos nos três idiomas: Together Run (Recife PE e Lagoa PB) e Corrida da Virada 2026 (São Paulo SP, Porto Franco MA e Florianópolis SC). Os cinco eventos produzem cinco títulos diferentes em cada idioma. Nenhum nome, data, registro, resultado ou URL de evento foi alterado.

## Validação e revisão

- 13 verificações do menu em Adobe ColdFusion: domínios prod/beta/dev, consumidor Open Results, script único por request e endpoint da mesma origem. Antes da correção, quatro falhas esperadas.
- 105 verificações dos títulos, incluindo 15 preservações de nome completo e 21 controles comparados com o baseline. A revisão independente Astra identificou truncamento excessivo no primeiro candidato; nove cenários reproduziram o achado antes da correção.
- 82 controles de leitura do catálogo da suíte anterior passaram. O teste legado integral com `CREATE TEMP TABLE` foi bloqueado pelas permissões do datasource. Não se alteraram permissões nem se executou DDL de contorno. As asserções legadas de texto foram adaptadas para decodificar as entidades produzidas pelo encoder atual.
- Três templates compilados pelo Adobe ColdFusion 2025 instalado, usando o usuário do runtime. Duas chamadas GET do catálogo e uma POST verificadas na ponte privada temporária, removida ao terminar.
- 21 páginas reais responderam 200 após publicar: 15 páginas de eventos localizados e seis páginas Open Results. Canonical, hreflang, descrições e hashes de JSON-LD iguais ao baseline; 15 títulos distintos e seis referências de script corretas.
- Navegador público confirmou o menu Open Results e o título completo da Corrida da Virada de São Paulo.

## Publicação e recuperação

Somente três arquivos de runtime: os dois includes Road Runners e o novo endpoint Open Results. Baselines conferidos antes do envio, troca atômica preservando dono/permissões, três hashes finais e onze dependências preservadas.

Road Runners: baseline recuperável em `/var/backups/seo-impact-20261021-rr`, com manifesto. Open Results: nenhuma substituição de arquivo existente e nenhum backup avulso; numa reversão, restaurar primeiro o consumidor compartilhado e retirar somente o novo endpoint, conferindo hashes contra mudanças concorrentes. Referências Git de consulta: RoadRunners `a1df1978d3af7ebea9ad8e9e37a542c83121bffb`, OpenResults `969a73ae9e510a1e4c2936592dba4663aa991808`. Sem commit, branch, tag ou push.

Documentação, testes e evidências permanecem locais. Recibos no staging Business `seo-impact-20261021`: `published.json`, `preflight-passed.json`, `pages-before.json`, `pages-after.json`, `published-resources.json` e os três relatórios de teste green.

## Pendências preservadas

Os canonicals estaduais `/estado/RJ/` e `/estado/rj/` responderam 200 na origem e foram mantidos até reprodução de uma falha. Não se alterou a política de privacidade dos resultados individuais. Os dois cadastros da Corrida das Cores da Amazônia têm data 28/03/2027 e não foram unidos nem corrigidos por suposição a partir do slug.

Este lote corrige causas verificadas. A redução das ocorrências e a nova nota dependem de uma auditoria posterior do Semrush; não houve afirmação de indexação ou ranking.
