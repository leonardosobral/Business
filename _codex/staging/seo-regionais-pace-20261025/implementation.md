# Regionais e calculadora de pace — 25/10/2026

## Entrega

A primeira etapa das melhorias regionais e a calculadora foram publicadas em 25/10/2026. O template regional é compartilhado: a alteração visual atende todos os estados/cidades existentes; PR/Curitiba e DF/Brasília são o grupo prioritário de conferência, não um experimento isolado.

- `estado/index.cfm` e `api/eventos.cfm` incluem `includes/regional_summary.cfm`. Contagem vem da query filtrada completa, não das primeiras 50 linhas nem dos anúncios. O resumo acompanha a substituição da lista por AJAX e não se repete na continuação.
- Atalhos de 5, 10, 21 e 42 km aparecem quando essas distâncias em quilômetros existem nas provas da seleção. Links preservam os demais filtros. “Limpar filtros” mantém a localidade.
- Cidades com provas ficam em uma seção expansível visível também no celular. O componente existente continua atualizando contagens e links.
- Seleções vazias explicam a ausência de provas e oferecem retorno ao calendário do estado.
- O breadcrumb das provas brasileiras agora inclui a cidade, tanto no HTML quanto no JSON-LD. Reutiliza `tag_cidade` da consulta existente, com normalização de espaços alinhada à rota regional; não cria outra consulta.
- `/calculadora-de-pace/` calcula pace, tempo ou distância no navegador. Tem presets 5/10/21,0975/42,195 km, parciais, velocidade, validação de entradas e exemplos HTML disponíveis sem JavaScript. Não usa IA ou banco para calcular.
- A ligação ao calendário preserva a UF ou define `context_uf=BR` explicitamente em “Todo o Brasil”, evitando o contexto regional automático da busca. Meia/maratona usam as categorias inteiras 21/42 km do catálogo; o cálculo conserva as distâncias exatas.
- Canonical única, link no rodapé e nas regionais, entrada no sitemap estático. Conteúdo em português sem alternates para traduções inexistentes.

## Medição e limites

Emite `rr_pace_calculate` e `rr_pace_calendar_click` no `dataLayer`, apenas com `calculator_mode`. Recebimento no GA4/GTM ainda não confirmado. A emissão não equivale a coleta e clique não equivale a venda.

O período regional ainda segue os intervalos legados de 30 dias e a data final cadastrada. Datas exatas e paginação rastreável são outro lote. Não houve alteração de datas de provas, cadastro, schema ou dados no banco.

Revisão editorial das fichas prioritárias, baseline de consultas/cliques no GSC, expansão editorial, circuitos e pós-prova permanecem no plano. A publicação não comprova aumento de tráfego, posição ou Site Health.

## Validação

- 10 testes Node nas versões fonte e minificada: cálculos conhecidos, limites, decimais, durações >24h, arredondamento, parciais e contratos de URL.
- 8 templates ColdFusion compilados; calculadora recompilada após o ajuste de contexto nacional.
- 9 cenários executados no Adobe com bootstrap real, incluindo 15 asserções de filtros/contagens/breadcrumb, páginas PR/Curitiba/DF, API, vazio, continuação e sitemap. Fixtures temporárias restritas ao localhost e removidas ao final.
- Conferência pública de calculadora, quatro regionais, API, sitemap e três assets. HTTP 200, conteúdo e hashes de assets conferidos.
- Navegador desktop/mobile (390 px): três modos, erro/recuperação, parcial final da maratona, link ao calendário, ausência de overflow, cidades e resumo sincronizado. Em Curitiba: 16 provas sem filtros; 11 para 5 km; 0 com cupom. Inventário pode mudar.
- Acesso anônimo conferido via HTTP e autenticado no navegador. Não foram alterados os fluxos de autenticação.

## Manutenção

Fontes: `assets/js/runnerhub-pace.js`, `assets/css/runnerhub-pace.css` e `assets/css/runnerhub-regionais.css`. Arquivos `.min` são gerados, não editados diretamente.

```sh
node _codex/scripts/build_regionais_pace.mjs . /caminho/node_modules/esbuild
node --test _codex/tests/seo_regionais_pace.test.cjs
```

Minificador fixado: esbuild 0.28.2. Somente whitespace; sem alteração de identificadores/sintaxe. O teste CFML `_codex/tests/seo_regionais_pace.cfm` é uma fixture de validação restrita, não uma rota para publicação.

Backup recuperável no servidor: `/var/backups/seo-regionais-pace-20261025/baseline`, com atualização complementar em `updates/national-context`. Pacote: 14 arquivos de runtime; dependências compartilhadas conferidas por hash. Evidências operacionais estão no Business em `_codex/staging/seo-regionais-pace-20261025/`.

Sem commit/push. Plano de execução: `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`.
