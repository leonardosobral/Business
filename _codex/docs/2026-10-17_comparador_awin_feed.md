# Feed Awin de produtos e preços

Publicado em 17/10/2026. [Gestão no Business](https://business.roadrunners.run/administracao/comparador/awin/?aba=feed): **PLATAFORMA → Comparador → Integração Awin → Produtos e preços**.

Atualização de 17/10 às 17:51: Nike, ASICS e Olympikus passaram a usar as políticas de preço auditadas; a Nike atual usa o feed 44669 com preço Pix em `search_price`. Ver [preços promocionais](2026-10-17_awin-precos-promocionais.md). Os registros anteriores abaixo descrevem o estado das entregas iniciais.

## Resultado da entrega inicial (antes da correção Centauro)

O endereço recebido retornava HTTP 404 (`Feed not found`), sem seleção de `fid`. A chave funcionou na lista autenticada oficial. O Business descobre os feeds dos programas já aprovados, região BR/Português, escolhendo o feed com verificação mais recente de cada loja. Acrescenta os campos estruturados de marca, estoque, condição e validade. A URL original permanece somente na configuração privada.

Foram processados **92.932 registros** de seis feeds; **1.672 SKUs** com correspondência segura produziram **49 preços em 49 produtos**. Por loja: Nike 13, Olympikus 14, ASICS 13 e Mizuno 9. Os 26 vínculos de quatro campanhas anteriores foram preservados, com 34 campanhas pendentes. Nenhum produto foi criado e nenhuma linha de `tb_cupom` foi alterada.

- Centauro: inicialmente excluída por validade malformada. Em 17/10, a investigação confirmou o mapeamento incorreto de validade e preço; foi publicada uma adaptação específica e auditável, com 46 ofertas à vista. Ver [correção Centauro](2026-10-17_awin_centauro.md).
- ASICS: preços inválidos e estoque negativo excluídos; `stock_status=out_of_stock` prevalece sobre `in_stock=1`.
- Samsung: nenhum vínculo elegível. A identificação automática atual abrange tênis com geração informada; não cria monitores/acessórios ou vínculos por aproximação.
- Under Armour, Decathlon, Authentic Feet e PUMA: a lista autenticada não apresentou feeds destes programas na consulta. Aprovação de programa não garante feed disponível.

Estado atual após a correção: **95 ofertas em 64 produtos**, das quais 46 Centauro. O restante desta página registra a entrega inicial; regras específicas e evidências atuais estão na documentação Centauro.

## Responsabilidades e contrato

Business é o proprietário da configuração, importação, identificação, bloqueios e histórico. `services/ComparadorAwinFeedService.cfc` consulta a lista e baixa CSV gzip dos IDs retornados; utiliza o cliente HTTP nativo do ColdFusion e Apache Commons CSV já incluído no runtime. Os endereços são construídos para `productdata.awin.com`, sem redirects; timeout de 20 s por chamada, limites de resposta de 20 MiB e conteúdo descompactado de 80 MiB, até 250 mil registros por feed. A conferência real de importação/identificação levou aproximadamente 9 s; o job completo terminou em 17 s. Não houve instalação de dependências ou migração de banco.

Credenciais: `/var/lib/runnerhub/business-awin/config.json`, campo adicional `feedUrl`, modo **0640 root:coldfusion**, grupo 988. O token da API é preservado. Não imprimir URL completa, respostas de erro da Awin ou configuração. O grupo incorreto aplicado inicialmente ao arquivo foi corrigido para o grupo original do diretório; a conexão e uma importação autenticada foram revalidadas. Em manutenção, preservar UID/GID/modo originais em vez de assumir que UID e GID coincidem.

Contrato adicional v1: `/var/lib/runnerhub/business-awin/cache/feed-publication.json`, **0600**, propriedade do runtime, substituição atômica. Envelope: `schemaVersion=1`, `publisherId=1455398`, `updatedAt`, `offers`, `feeds`, `blocked`, `history`. Oferta: `key=merchantId:productId`, IDs do anunciante/feed/SKU, identidade atual do produto (`productSlug`, `productBrand`, `productName`, `productVersion`), `productLabel`, `shop`, título original da variante, `price`, `currency=BRL`, `url`, `fetchedAt`, `expiresAt`, `variants`. Bloqueios usam a chave loja/produto; histórico limitado a 100 eventos. O contrato anterior de campanhas (`publication.json`) permanece separado e compatível.

A identificação exige marca, nome e geração, com normalização Unicode por Java. Aceita somente palavras de apresentação, gênero, tamanho e cor ao redor do modelo completo. Nomes ambíguos, novas variantes/sufixos, infantil/casual/roupas ficam sem vínculo; Nike ZoomX tem um alias explícito da tecnologia, mantendo o restante do nome e geração. O catálogo utilizado exclui protótipos, compra bloqueada e produtos não públicos. Preços precisam ser positivos e em BRL; estoque deve ser positivo e não contradito pelo status, sem pré-venda ou indicação de usado. Datas preenchidas inválidas/futuras/vencidas impedem publicação, exceto a anomalia numérica identificada exclusivamente no feed Centauro 91869, documentada na correção acima. O link deve ser `pclick.php` HTTPS da Awin, com SKU, anunciante e afiliado 1455398 coerentes.

A cada importação, o menor preço elegível de cada loja/produto é publicado com o título e link da variante exata. Outras variantes não são prometidas pelo preço mínimo. A oferta expira em até 24 h, limitada também à última verificação da origem e à validade informada. Falha individual preserva somente as ofertas anteriores daquela loja ainda válidas e sinaliza importação parcial; retirada de itens/lojas ou fonte velha retira preços na próxima publicação. O consumidor também aplica vencimento em cada requisição.

## Gestão e apresentação

No Business, a aba permite importar sob demanda, buscar por produto/loja, paginar em 30 vínculos, consultar exclusões por loja e histórico, bloquear/restaurar a publicação de uma loja para um produto. Escritas exigem administrador global não delegado, POST e CSRF. Token otimista protege mudanças concorrentes de bloqueios. A importação preserva bloqueios existentes.

No Comparador, `services/AwinFeedReader.cfc` lê o arquivo privado uma vez por requisição, valida conta/versão/frescor/URL/valor e identidade do produto e exclui bloqueados. O site não acessa credenciais nem chama a Awin. Uma projeção JSON pequena e parametrizada é associada à consulta pública por ID e identidade; o menor preço entre oferta manual e feed serve para **card, filtro e ordenação**, com fallback ao preço de referência. Gráficos continuam mostrando preço de referência, conforme seu rótulo.

O card exibe “A partir de” e orienta a conferir a variante. O modal mostra nome original (incluindo gênero/tamanho quando presentes), preço, loja e link patrocinado. Frete e pagamento são conferidos na loja. Não há cálculo de desconto a partir de preço antigo, campanha ou cupom; campanhas aparecem separadamente.

## Rotina e verificação

O job existente **24 — Comparador - Campanhas e ofertas Awin** continua a cada 30 minutos. `POST /api/comparador/awin-sync.cfm` agora reconcilia campanhas e importa preços. Usa o segredo interno já existente; 405 para GET, 401 sem autenticação e 503 quando a importação falha/parcial. Serviços não têm métodos `remote`. Nenhum cron de sistema ou automação Codex foi criado.

Execução automática **211211**, origem `scheduled`, às **17:03 de Brasília**, sucesso HTTP 200: 4 campanhas, 26 ofertas de campanhas, 34 pendências, seis feeds e 49 preços, zero falhas de download. Próxima execução registrada para 17:33.

Validação: 40 verificações CFML focadas (CSV com aspas/vírgulas/múltiplas linhas, gerações/variantes/ambiguidade, moeda/preço, estoque, validade, conta/URL, autenticação/CSRF, identidade, expiração e bloqueios); 258 asserções de consulta/ordenação/filtro/fallback no snapshot de 17/10; compilação CF2025 de nove arquivos Business e quatro Comparador, incluindo suportes; sete checks HTTP de publicação. **As 49 fichas públicas** foram conferidas contra título, preço e URL importados. Desktop e celular a 390 px nos dois projetos, sem transbordamento horizontal.

Testes unitários em `Business/_codex/tests/comparador/awin-feed.cfm`; o smoke datado `awin-feed-query-smoke-20261017.cfm` depende do snapshot real de 49 ofertas e do catálogo desta data, e não deve ser interpretado como uma contagem invariável. Executar em harness privado acessível somente por loopback, mapeando `/services` e `/publicservices` para os candidatos, `/candidate` para a área de validação e datasource `comparador`; fixture `/var/tmp/runnerhub-awin-feed-validation/fixture`, com `cache/` gravável pelo runtime e config fictícia (`publisherId`, token fictício). O teste unitário nunca usa credenciais reais. Os testes de download foram isolados da publicação. Harness e credenciais temporárias removidos ao concluir.

## Publicação e recuperação

Oito arquivos de runtime: Business `services/ComparadorAwinFeedService.cfc`, `administracao/comparador/awin/{backend,home,feed}.cfm`, `api/comparador/awin-sync.cfm`; Comparador `services/AwinFeedReader.cfc`, `includes/{consulta_produtos,produto_card}.cfm`. Baselines locais/produção e hashes conferidos, arquivos de outras frentes preservados. Sem commit, branch ou push.

Entrega inicial `20261017T195841Z-a4c4be9d`; ajuste visual do card `20261017T200422Z-2b48749c`. Backups em `/var/backups/awin-feed-20261017/{business,comparador}/<release>`, além do backup privado da configuração no mesmo diretório pai. Para rollback completo, conferir hashes/alterações posteriores e reverter primeiro o ajuste visual e depois a entrega inicial com os respectivos manifests; preservar o estado privado e o token. O endpoint anterior mantém a sincronização de campanhas. O arquivo adicional de feed pode permanecer inerte após retirada do leitor. A publicação é Business primeiro, Comparador depois; falha de smoke reverte ambos.

Fontes oficiais: [Create-a-Feed](https://help.awin.com/developers/docs/downloading-feeds-using-create-a-feed) e [lista autenticada de feeds](https://help.awin.com/developers/docs/product-feed-list-download).

[Evidências e recibos](2026-10-17_comparador_awin_feed_recibo.json).
