# Mapas das fichas sob demanda — 30/10/2026

Publicado às **16:24:42 de Brasília**, após diagnóstico oficial do PageSpeed da ficha de Aracaju: a biblioteca Mapbox consumia 14.797 ms de CPU na simulação móvel, e os dois mapas eram criados mesmo abaixo da área visível. Evidência DOM anterior: canvases já presentes a 1.862 e 2.616 px do topo em viewport de 834 px.

## Comportamento

`evento/index.cfm` carrega somente `assets/js/event-maps-lazy.min.js` na abertura. O carregador usa IntersectionObserver com margem de 300 px, ou foco/toque/clique na seção. A biblioteca Mapbox é compartilhada por uma única Promise e cada script de componente é carregado uma vez. Percursos e localização são acionados separadamente, reaproveitando seus scripts atuais sem alterações. A última aba clicada durante o download é reaplicada após a inicialização. A área existente do mapa recebe o estado de carregamento enquanto aguarda.

Navegadores sem IntersectionObserver mantêm carregamento imediato. Falha da biblioteca permite os fallbacks nativos dos componentes; falha do script de componente mostra o erro já existente. Timeout de 20 s para download. As origens permitidas são o caminho oficial versionado do Mapbox e os dois assets locais esperados. Endereço, Google Maps, Waze, links, conteúdo, metadados e dados da prova continuam no HTML. Não há escrita no banco, mudança de token ou permissão.

O embed `/embed/percursos/` permanece com o carregamento próprio e foi preservado por hash e verificação HTTP.

## Validação e resultado

- 14 testes Node/jsdom cobrindo fonte e minificado, acionamento por visibilidade/teclado, concorrência, clique durante download, falta de observer, falhas, timeout e rejeição de scripts externos inesperados.
- Um template compilado; cinco cenários Adobe ColdFusion: ficha PT/EN/ES, pós-prova de Floripa e ficha com localização. O bootstrap, H1, schema e materiais de pós-prova foram conferidos.
- Oito conferências HTTP públicas: cinco fichas, embed e dois assets por hash. Três hashes de runtime publicados e dez dependências preservadas.
- Chrome desktop e celular 390 px: mapas sem canvases nem script Mapbox na abertura, abas, fallback de 10 km sem geometria, percurso de 42 km com geometria, elevação e marcações; seleção por teclado verificada e página sem overflow horizontal. Links de navegação preservados.
- Esbuild **0.28.2**, somente espaços minificados, roundtrip estável. Fonte 6.862 bytes, minificado 4.139 bytes. Registrado no gerador `_codex/scripts/minify_seo_assets.mjs`.

Comparação de duas simulações móveis do PageSpeed, mesma URL e configuração, 16:14/16:25: **desempenho 33 → 64; TBT 8.030 → 250 ms; LCP 8,3 → 7,1 s; Speed Index 12,5 → 5,4 s; CLS 0,038 nas duas**. Valores exatos da calculadora: TBT 8.033 → 247 ms, LCP 8.259 → 7.146 ms. Payload 5.741 → 4.083 KiB e tarefas longas 20 → 8. São observações pontuais de laboratório, não garantia de todas as visitas, melhoria de INP real, ranking ou Site Health. O trabalho do mapa continua necessário quando ele é acessado. LCP ainda precisa melhorar.

[Antes](https://pagespeed.web.dev/analysis/https-roadrunners-run-evento-2026-maratona-de-aracaju-2026/8h9yx3klom?form_factor=mobile) · [Depois](https://pagespeed.web.dev/analysis/https-roadrunners-run-evento-2026-maratona-de-aracaju-2026/c4zwyu0fz6?form_factor=mobile). O campo CrUX da ficha usa fallback da origem (191 ms INP), que não substitui o grupo GSC de 926 URLs/293 ms com atualização de 28/10.

A home teve diagnóstico separado: simulação 60, LCP 8,9 s, TBT 320 ms. O PageSpeed identificou a imagem do destaque como LCP e falta de prioridade alta. Esse é o próximo recorte; a home não foi alterada nesta publicação.

## Operação

Runtime: `assets/js/event-maps-lazy.js`, `assets/js/event-maps-lazy.min.js`, `evento/index.cfm`. Backup recuperável: `/var/backups/seo-mobile-maps-20261030/baseline`, com manifest e guarda de hashes. Reversão somente se o estado publicado continuar igual; não sobrescrever alterações posteriores. Evidências e scripts de operação no Business: `_codex/staging/seo-mobile-maps-20261030/`.

Teste portátil: instalar jsdom 26.1.0 no ambiente de testes e executar `node --test _codex/tests/event_maps_lazy.test.cjs`; `SEO_TEST_MODULES` pode apontar para node_modules, e `MAPS_SOURCE_ROOT` permite validar um candidato. O gerador exige esbuild 0.28.2. Não publicar ferramentas, testes, fixtures ou diretórios completos.

A auditoria Semrush 26661911 de 5.000 páginas continua na mesma execução, móvel/JS desativado. Ela não mede esse comportamento de mapas nem os tempos Lighthouse. A última nota concluída é 73%, meta >80 ainda aberta. Nenhum commit/push/branch e nada para executar no DataGrip.
