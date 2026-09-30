# SEO para IA — conteúdo e nova medição

Entrega concluída em 29/09/2026 (horário de Brasília). Runtime público publicado às 21:10; snapshots Business às 21:22. Recibos de compilação, hashes e verificação em [publicação](2026-09-29_seo_ia_conteudo_publicacao.json). Não houve commit, branch, push ou PR.

## Comportamento por projeto

**Road Runners:** `includes/estrutura/head.cfm` escapa atributos canonical, alternates e URLs sociais. Uma tag com aspas preserva a URL completa. JSON-LD escapa `<` para evitar fechamento literal do script por conteúdo do cadastro. `evento/index.cfm` usa o fornecedor relacionado ao evento no papel `id_fornecedor_tipo=1` como organizador. Remove a disponibilidade de inscrições inferida somente pela data; a URL de inscrição existente permanece. Alterações anteriores de circuitos foram preservadas e coincidiam com o baseline publicado.

**Open Results:** novo `includes/seo_event_schema.cfm`, consumido por `evento/index.cfm` e `includes/head.cfm`, entrega SportsEvent com canonical, nome, datas, local e organizador quando relacionado nesse papel. Usa data sem horário quando não existe hora confirmada. Cancelamento vem do status cadastrado. Não inventa preço, disponibilidade, imagem ou horário. Eventos com período válido de mais de um dia passam a mostrar o intervalo também no texto visível. Acesso direto ao include retorna 403. Resultados, consultas, autenticação e ações de salvar não foram alterados.

**Coletor operacional:** `RoadRunners/_codex/scripts/seo/html.mjs` registra metadados usando parse5 existente. A versão adicional é `metadata_version: 1`; campos: idioma, descrições, alternates, contagem de JSON-LD/erros/tipos e resumos de eventos. Reconhece objetos, arrays e `@graph` com limites de processamento. Não guarda texto integral, HTML ou linhas de resultados. O pacote Node continua fora da publicação no webroot.

**Business:** `seo_scorecard.mjs` passou a medir os campos adicionais e gerou `portal/includes/seo_score_data.cfm`. Fila curada em `portal/includes/seo_queue_data.cfm`: RR-06 e OR-03 concluídos, SH-02 pendente. Total: 11 frentes, 6 concluídas, 5 pendentes, incluindo uma de prioridade alta. A aba de IA mostra medição parcial quando há casos avaliados e casos sem evidência. Os pesos técnicos não mudaram; descrição, hreflang e sintaxe JSON-LD continuam fora da nota.

## Nova amostra após publicação

| Indicador | Road Runners | Open Results |
| --- | ---: | ---: |
| URLs descobertas nos sitemaps | 102.509 | 34.144 |
| Páginas inspecionadas | 100 | 100 |
| Falhas operacionais | 0 | 0 |
| Erros nas páginas | 2 | 0 |
| Avisos nas regras existentes | 99 | 1 |
| Nota técnica interna | 70,0 | 95,0 |
| HTML disponível | 98 | 100 |
| Meta description aprovada | 98 | 100 |
| Hreflang básico aprovado | 77 | 0 |
| JSON-LD presente e analisável | 53 | 99 |
| JSON-LD com sintaxe inválida | 0 | 0 |
| Eventos SportsEvent encontrados | 42 | 99 |
| Eventos sem organizador marcado | 40 | 96 |

Execuções: Road Runners `2026-09-30T00-13-25-201Z-355c9c21`; Open Results `2026-09-30T00-13-19-583Z-33417e9a`. Embora os IDs usem UTC de 30/09, correspondem a 29/09 às 21:13 em Brasília. Relatórios íntegros permanecem privados em `/Users/Shared/RunnerHubReports/seo`.

Zero hreflang aprovado no Open Results significa ausência de declarações na amostra; não é automaticamente um defeito em páginas de idioma único. JSON-LD ausente em outros tipos de página permanece sem evidência conclusiva. “JSON-LD analisável” não comprova conformidade completa, rich results ou exatidão dos fatos. Nome e cidade coincidem com o texto nos eventos encontrados; ainda falta revisão factual ampla. O organizador ausente não foi preenchido com o cronometrador.

Descoberta completa significa que os sitemaps planejados foram processados. Apenas 100 páginas de cada inventário tiveram conteúdo inspecionado. Houve também coleta anterior à publicação nesta entrega, para identificar defeitos e conferir o efeito dos ajustes. O novo hash do coletor quebra a comparação de progresso com a coorte anterior; as notas permaneceram iguais porque os critérios novos têm peso zero e as falhas técnicas restantes não foram corrigidas nesta etapa.

## Verificação

- 83 testes Node do coletor e 42 testes Business de relatório, runner e scorecard passaram.
- Três fixtures CFML executaram o código real: SportsEvent Open Results, organizador/disponibilidade Road Runners e escape do head. Casos de borda: papéis de fornecedor cruzados, somente cronometrador, datas inválidas/cancelamento/intervalo invertido e conteúdo com `</script>`. Falhas de comportamento foram observadas antes das correções e os mesmos cenários passaram depois.
- Seis cenários CFML do painel passaram: contrato da fila, resolvidos, score/filtros independentes, render completo, aba IA e filtro de erros. Fixtures de estado da fila usam conjunto sintético fixo; o teste de independência compara a fila filtrada inicial com a mesma fila após os filtros do relatório.
- Adobe ColdFusion compilou os cinco arquivos públicos e os dois snapshots Business. Publicação por arquivo atômico; hashes, permissões e arquivos protegidos conferidos após o envio.
- GET público: evento Road Runners com aspas retornou 200, canonical completo, quatro alternates e SportsEvent analisável; Salvador e Atleta de Cristo Open Results retornaram 200 com canonical e JSON-LD válidos; include novo retornou 403.
- Navegador real: conferidos Salvador com resultados, evento futuro Colina Park (12/10/2026) e período do Movimente. Nome, cidade e data do futuro coincidiram com o card e JSON-LD. O intervalo de Movimente aparece no texto; a correção do cadastro em fonte oficial ainda integra SH-02.
- Business autenticado: notas 70/95, inventários, 99 JSON-LD Open Results, 3/99 eventos com organizador, data atual e fila 11/6/5. Abas e filtro Open Results/P3 preservam parâmetros e exibem SH-01 e SH-02. Desktop em 1516 px; celular em 390 px; sem transbordamento horizontal nas páginas verificadas. Menu móvel recolhido após inicialização.

Imagens locais em `output/seo-content-20260929/`: desktop-ai.png, desktop-report.png, mobile-ai.png, mobile-queue-filtered.png e openresults-period-mobile.png.

## Recuperação

- Road Runners: backup recuperável dos dois arquivos no servidor em `/var/backups/seo-content-rr-74spiu76`; comparar recibo antes de restaurar somente o escopo.
- Business: backup dos dois snapshots em `/var/backups/seo-content-Business-fyyef_vo`; arquivos de layout e autorização protegidos não foram publicados.
- Open Results: sem backup de deploy, conforme preferência do projeto. Reconstruir somente `includes/head.cfm` e `evento/index.cfm` a partir de `e769528c34b23beb6fc3a16ea615184849ce5e5c` e aplicar [patch preexistente de canonical](seo_ia_conteudo_2026_09_29/openresults_baseline.patch). A reconstrução foi executada em diretório temporário e seus hashes coincidiram com produção antes da entrega. Hash SHA-256 do patch: `9ffb1194fa6ee37579f09fdcd42bea1f16006d32a5b693a8b7d700b1eec4f227`. Na reversão deste escopo, retirar também o include novo depois de restaurar seus consumidores. Não reverter alterações alheias do workspace.

## Pendências e limites

A URL `https://roadrunners.run/es/evento/2026-operario%0D%0Anight%0D%0Arun/` continua 403 após o usuário informar que desligou Bot Fight Mode. O identificador contém CRLF, mas a origem do bloqueio ainda não foi identificada. Não atribuir a uma regra Cloudflare específica nem contornar a proteção. A notícia antiga RR-05 permanece 404. Outros casos de RR-01 fora desta amostra não foram encerrados.

SH-02 cobre fontes oficiais, vínculo de organizador, períodos/horários/fusos, distâncias e edição. Hreflang atual só valida a declaração básica; traduções e reciprocidade permanecem pendentes. Nenhuma política robots, proteção Cloudflare, permissão ou credencial foi alterada pelo Codex.

A permissão declarada de OAI-SearchBot e PerplexityBot foi observada nas 100 URLs de cada site. Nosso coletor tem identidade própria. Acesso real dos provedores, citações, tráfego e conversões continuam não medidos. Não foi criada nota de recomendação ou histórico específico de IA.

Referências oficiais usadas para orientar a implementação: [Google — eventos](https://developers.google.com/search/docs/appearance/structured-data/event) e [idiomas](https://developers.google.com/search/docs/specialty/international/localized-versions). O plano geral e as fontes dos bots estão em [SEO para IA](2026-09-29_seo_para_ia_plano.md).
