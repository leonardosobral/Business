# SEO — reauditoria e continuação em 30/10/2026

## Estado atual

A rodada anterior de pós-prova foi **progresso**: runtime publicado e verificado. Nesta continuação, a evidência externa mudou a prioridade: a campanha Semrush 26661911 terminou em 29/10 às 09:32 de Brasília com 73% de Site Health, 84% de IA, 64 erros, 8.388 advertências e 1.643 observações, em 5.000 páginas/móvel/JS desativado. O comparativo anterior real é 24/10 às 23:40: 79%, 20 erros, 10.079 advertências e 2.102 observações. Fonte reconciliada em 38 tipos de erro, 34 de advertência e 25 de observação.

O painel foi atualizado em 30/10 às 15:33:52, com a coleta orgânica antiga de 04/10 preservada e as correções de hoje identificadas separadamente. Não afirmar melhora do Site Health antes da nova auditoria.

## Publicado e conferido

- **RoadRunners:** `estado/index.cfm` com descrições específicas para cada continuação do calendário. As 30 URLs regionais reportadas têm descrições distintas; calendários de uma página preservados.
- **Dados:** 48501 → 49606 (ADC ZF) e 48554 → 48918 (Outubro Rosa de Chupinguaia) com 301 PT/EN/ES e inativação das duplicatas, sem apagar registros. Identidade e fatos confirmados na Ticket Sports 88536 e Sympla 3594186. Dois resumos PT/EN/ES corrigidos. Datas gerais e seis percursos intactos; 46 grupos dependentes preservados. Fontes duplicadas sem resultados/agenda/contas/inscrições/ads/CRM a migrar.
- **Business:** `portal/includes/seo_semrush_data.cfm` e `portal/conteudo/seo_semrush.cfm`. 73%/84% e contadores corretos, comparação com 24/10 e notas de correções posteriores. Dados orgânicos mantêm sua data de 04/10.

Verificações: ensaio transacional com rollback, inversão e guardas de drift; um template regional/seis cenários Adobe; 44 verificações públicas, incluindo 34 URLs reportadas e seis 301 localizados; quatro verificações adicionais dos textos EN/ES. Painel com seis testes Python, dois templates compilados e 19 cenários antes/depois, oito controles de acesso. Hashes e dependências de produção conferidos. Código local sincronizado com guardas; sem commit/push. Nada para executar no DataGrip.

Backups: `/var/backups/seo-duplicidades-20261030-data/`, `/var/backups/seo-duplicidades-20261030-runtime/baseline` e `/var/backups/seo-reaudit-20261030-panel/baseline`. Rollbacks com comparação exata do estado publicado; não restaurar por cima de alterações posteriores. Detalhes: `RoadRunners/_codex/docs/2026-10-30_duplicidades_regionais.md`.

## Auditoria nova em andamento — NÃO REINICIAR

Após as publicações foi iniciada uma nova execução da campanha **26661911**, sem alterar configurações. A interface confirmou preparação e depois **“Rastreando páginas”, 2.359/5.000 na última observação**, com controle de interromper presente. A última conclusão exibida continua sendo 29/10; isso não indica que o processo novo parou.

- Browser Chrome ID **3**; binding `postBrowser`.
- Aba em andamento **283505491**, binding `seoContinueTab`.
- URL: `https://pt.semrush.com/siteaudit/campaign/26661911/review/compare`.
- Aba do painel publicado: **283505525**, binding `seoPanelNow`, marcada como entrega.
- Evidência do processo: `_codex/staging/seo-reaudit-20261030/crawl-latest.txt`, `crawl-started.png` e `continuation.json`.

A aba da campanha foi mantida para a continuação. Primeiro observar o **mesmo handle/processo**, ou obter uma aba nova no mesmo Chrome se o handle tiver expirado e consultar a campanha; nunca reexecutar por timeout de observação. Após compaction, ler `cua.rewriteDocumentation()` antes de continuar o navegador. Confirmar status terminal na interface e obter data/hora real, 5.000 páginas, dispositivo/JS, notas e contadores. Fazer nova importação em staging/backup novos: o baseline do painel desta rodada antecede a publicação de 73% e não serve para sobrescrevê-lo de novo.

Durante o rastreamento, evitar benchmarks/compilações pesados e nova rodada de alterações que dificulte interpretar a medição. É possível analisar os relatórios históricos restantes sem mudar produção. Os 18 links foram individualizados: 16 para proteção de e-mail da Cloudflare e dois para a mesma notícia, atualmente 200 no site e na API. Os dois destinos 4xx são os mesmos. Preservados, sem atribuir causa ao erro histórico. Hreflang e página lenta continuam para revalidação; preservar login, robots/noindex e configurações da campanha.

## Outras pendências

GA4 voltou a negar leitura em 30/10; a tela aponta permissões/APIs da conexão existente. Nenhuma permissão/credencial foi alterada, e o erro não foi interpretado como audiência zero. Recebimento da calculadora permanece sem comprovação. Imperatriz continua sem fonte suficiente; kits não anunciados e colaboração com organizadores permanecem no plano. A meta de Site Health **acima de 80%** continua aberta.

Plano central: [páginas regionais e pace](2026-10-25_plano_seo_regionais_pace.md). Stagings: `_codex/staging/seo-duplicidades-20261030/` e `_codex/staging/seo-reaudit-20261030/`. Nenhuma operação Git ou nova configuração de auditoria/Cloudflare foi executada.

## Continuação de 30/10: Google atualizado no painel

Progresso independente enquanto o mesmo crawl continua: leitura manual GSC publicada em **16:09:42 BRT**, dois arquivos Business. Sitemap principal processado com 107.352 URLs, sete lotes e static.xml com 990. Indexação da **propriedade de domínio incluindo subdomínios**, atualizada em 22/10: 21.335 indexadas e 116.687 não indexadas (13 motivos reconciliados). Não confundir com o recorte de desempenho.

Pesquisa Web somente HTTPS de roadrunners.run/www, todos os países/dispositivos, 01/10–28/10 versus 28 dias anteriores: **10.026 vs 3.220 cliques**, 461.935 vs 125.907 impressões, CTR 2,2% vs 2,6%, posição 7,4 vs 8,0. O crescimento não comprova impacto das entregas de 25/10 e 30/10. Dados podem ser parciais por filtro Google. Não inclui Direct/referências IA. Baseline anterior PR/DF (316 cliques) intacto.

CWV atualizado em 28/10: móvel 1.317 URLs precisam melhorar/173 boas, desktop 1.490 boas. Grupo INP 926 URLs/293 ms (exemplo Maratona de Aracaju); LCP 391 URLs/2,5 s arredondados (home). Próxima implementação deve partir de diagnóstico confirmado. Mapas iniciados abaixo da dobra são apenas uma hipótese ainda não publicada. Não declarar correção CWV com uma medição sintética.

Validação: dois templates compilados, 15 cenários antes/depois, oito controles de acesso; duas versões publicadas/14 dependências preservadas; três controles HTTP públicos (302 da tela e 403 dos includes), Chrome desktop/mobile390 e teclado, sem overflow da página. Backup `/var/backups/seo-gsc-20261030-panel/baseline`; fontes/recibos em `_codex/staging/seo-gsc-20261030/`. Código local confere com publicado. Sem banco, credenciais, permissões ou Git. OpenResults intacto. GA4 continua negado.

Aba da entrega Google: **283505569**, binding `seoGscPanel`; não substituir a aba do crawl. A campanha continua na **283505491**, binding `seoContinueTab`, marcada para continuação. A última nota concluída permanece 73%; meta >80 aberta. Plano central atualizado com essa sequência.

## Continuação de 30/10: mapas sob demanda publicados

Progresso: três arquivos de runtime RoadRunners publicados às 16:24:42 BRT e verificados, com dez dependências preservadas. `evento/index.cfm` carrega o novo `event-maps-lazy.min.js` (fonte presente), que adia biblioteca e componentes até a seção estar próxima ou receber interação. Scripts dos widgets e embed intactos. Fonte/gerador/teste/doc sincronizados no checkout com guardas. Backup `/var/backups/seo-mobile-maps-20261030/baseline`; 14 testes Node, um template compilado, cinco cenários Adobe, oito verificações públicas e navegador desktop/mobile390/teclado. Nenhum banco/permissão/credencial/Git.

Diagnóstico e resultado guardados em `_codex/staging/seo-mobile-maps-20261030/`: Mapbox era 14.797 ms de CPU no teste da abertura da ficha; duas simulações móveis comparáveis passaram de 33 para64, TBT8.030 para250ms, LCP8,3 para7,1s, CLS0,038 mantido. Isso não comprova INP real ou Site Health. GSC de 28/10 e CrUX da origem no PageSpeed são escopos diferentes. Mapas reais, 42km, marcações, elevação, abas e localização conferidos após carregar; sem canvases/script Mapbox na abertura em desktop e390px.

**Nova última observação do mesmo crawl: 3.879/5.000**, evidência `crawl-maps-published.txt`; nota concluída73 ainda vigente. A aba283505491 foi revalidada e marcada para continuação. Não reiniciar. O crawl tem JSdesativado e não mede a melhora de abertura dos mapas.

**Próximo trabalho seguro:** LCP da home. PageSpeed separado mostrou60/LCP 8,9s/TBT 320ms e destacou a imagem `home-spotlight-media`, sem prioridade alta. Fonte em `RoadRunners/index.cfm` por volta de1469, dentro de `cfoutput query="qEventosDestaqueHome"`. Examinar primeira imagem visível e demais do carrossel antes de editar; preparar baseline/backup novos. A home permanece intacta nesta publicação. Fontes da home já em `psi-home-baseline.txt`/`psi-home-url.txt`; não repetir a coleta sem necessidade. Depois, importar a auditoria quando concluída e continuar pendências reais.

## Continuação de 30/10: prioridade da home publicada, auditoria na análise final

Progresso: **`RoadRunners/index.cfm` publicado às 16:38:27 BRT**. Um único elemento do loop mudou: primeira imagem eager/high, onze seguintes lazy/low/async. Consulta, URLs, resolução, CSS, carrossel, filtros e conteúdo intactos. Um template compilado e seis cenários Adobe; três verificações públicas PT/EN/ES com canonicals; Chrome desktop/mobile390, avanço e retorno do carrossel e ausência de overflow. Um hash e seis dependências preservadas. Backup `/var/backups/seo-home-images-20261030/baseline`. Fonte e doc sincronizadas com guarda; nenhum dado de prova alterado. Evidências em `_codex/staging/seo-home-images-20261030/`, doc RoadRunners `_codex/docs/2026-10-30_home_imagens_prioridade.md`.

**LCP não melhorou no teste pontual:** desempenho 60→56, LCP 8,9→10,8s, TBT 320→450ms, payload 8.330→6.324KiB, CLS 0,073 mantido. Prioridade aplicada corretamente, mas o peso dos arquivos continua alto; não declarar otimização completa. Diagnóstico detalhado salvo. Consulta em transação READONLY confirmou a mesma URL grande nos dois campos de Aracaju; Curitiba tem thumb diferente, ainda sem revisão visual. Não trocar por chute nem construir proxy aberto. Próximo recorte: variantes menores/formatos modernos com rastreabilidade e fallback.

**Semrush: o mesmo job passou de 4.988/5.000 para `Analisando recursos e links`.** Continua vivo, não é resultado concluído. Última nota válida 73%. Aba 283505491, binding `seoContinueTab`, Chrome 3, preservada. Fonte atual `phase-after-home.txt`. Não reiniciar. Não interpretar os 5.000/5.000 do bloco de auditoria anterior como novo resultado.

Foi capturado baseline NOVO dos dois arquivos Semrush atuais em `_codex/staging/seo-semrush-20261030-final/panel/baseline.json`, com produção/local iguais, preservando Google e domínios. Nenhum candidato de dados criado ou publicado ali. Quando terminar: fonte final completa real, data/hora pela UI, 5k/móvel/JSdesativado, SiteHealth/IA/contadores/tipos/comparação; construir em cima desse baseline só se as guardas continuarem válidas. Adaptar o builder antigo para comparação com 29/10, não 24/10. Não usar novamente o baseline pré-publicação de 73%.

Sessão Chrome da tarefa `🔎 SEO home e auditoria`; home publicada marcada como entrega; aba de diagnóstico PSI concluída foi fechada. Viewport móvel foi restaurado. Plano central atualizado. Sem commit/push/branch, permissões, credenciais ou configuração Cloudflare. A meta geral permanece ativa; não foi concluída.
