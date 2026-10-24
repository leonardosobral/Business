# Revisão dos preços dos feeds Awin — 17/10/2026

Publicado no Business em **17/10/2026 às 17:50 BRT**; importação concluída às **17:51 BRT**. A revisão corrige o uso do preço original em feeds cujo mapeamento da origem difere do nome padrão da coluna. Cada adaptação exige o par exato de anunciante e feed auditado.

## Resultado em produção

- **95 ofertas em 64 produtos**, com os seis feeds importados sem erro.
- **20 preços corrigidos:** 10 ASICS e 10 Olympikus. Os outros 75 valores da publicação imediatamente anterior foram preservados, incluindo as 55 ofertas de Centauro e Mizuno.
- As **26 ofertas de campanhas** foram preservadas.
- Apenas `Business/services/ComparadorAwinFeedService.cfc` foi publicado. O código do Comparador permaneceu igual; ele já consome os preços e a condição de pagamento do contrato V1.

Exemplos após a correção, para as variantes escolhidas pelo importador:

| Loja / produto | Antes | Publicado |
|---|---:|---:|
| ASICS Novablast 5 | R$ 999,99 | R$ 699,99 |
| ASICS Superblast 2 | R$ 1.599,99 | R$ 1.119,99 |
| Olympikus Corre 4 | R$ 599,99 | R$ 449,99 |
| Olympikus Corre Grafeno 3 | R$ 799,99 | R$ 549,99 |

## Campos auditados e política aplicada

| Anunciante / feed | Campo do total | Condição publicada | Observação |
|---|---|---|---|
| Nike `17652 / 93360` | `base_price`, decimal seguido de ` BRL` | `cash` | Mapeamento do total à vista confirmado nas variantes da loja. |
| Nike `17652 / 44669` | `search_price` | `cash` | Feed mais recente, selecionado na atualização desta revisão; o campo já contém o total Pix. `base_price` veio vazio nas 6.485 linhas. |
| ASICS `23659 / 116576` | `product_price_old`, decimal seguido de ` BRL` | `standard` | Apesar do nome do campo, este feed envia nele o total de venda atual. |
| Olympikus `17698 / 51837` | `base_price`, prefixo exato `installament months: R$ ` e total em formato brasileiro | `standard` | `base_price_amount` contém uma parcela e não pode ser usado como total. |
| Mizuno `51271 / 85451` | `search_price` | `standard` | Total promocional já correto. `base_price` é referência superior e `base_price_amount` é parcela. |
| Centauro `17806 / 91869` | `base_price`, decimal seguido de ` BRL` | `cash` | Política da correção anterior preservada, inclusive a exceção restrita de validade. |
| Samsung `25539 / 114866` | `search_price` | `standard` | `rrp_price` é referência superior ou igual. Nenhum produto foi vinculado ao catálogo atual. |

A descoberta automática escolhe o feed aprovado mais recente por loja. Assim, a regra de Nike `93360` continua coberta por teste, mas a importação publicada usou `44669`. Não se deve aplicar a regra de uma dessas versões à outra.

Os formatos adicionais são estritos: total ausente, moeda inesperada, formato incorreto, valor não positivo ou total superior ao preço de referência rejeitam a linha. Não há fallback silencioso para o preço original nos três mapeamentos corrigidos. Estoque, identidade da loja/feed, validade, modelo/geração e link de afiliado continuam obrigatórios. Não se escolhe o menor valor entre colunas de semânticas diferentes e não se calcula o preço total a partir de parcelas.

O contrato continua com `schemaVersion: 1`; `priceSource` passa também a registrar `product_price_old`. `priceType` segue `cash` ou `standard`, permitindo que a apresentação atual identifique preço à vista sem mudança no consumidor.

## Conferência de compra e limites

O fluxo **Ver ofertas → Ver produto na loja** foi conferido no Comparador. No Nike Pegasus 41, o clique abriu a variante `www.nike.com.br/tenis-nike-pegasus-41-feminino-028661.html?cor=ID`, com atribuição `aw_affid=1455398`, e a loja exibiu **R$ 581,39 no Pix**, correspondente à oferta publicada.

Olympikus e Mizuno podem oferecer desconto Pix adicional na própria loja. Esse total adicional não está disponível nos campos auditados do feed; o Comparador publica o total promocional explícito e não estima esse desconto. Preço e disponibilidade continuam sujeitos à variante e à atualização do lojista.

## Validação

- **241 verificações unitárias:** 139 na nova revisão de preços, 40 na suíte geral e 62 na regressão de Centauro/datas. As duas suítes anteriores receberam fixtures compatíveis com a seleção explícita de preço.
- **267 verificações SQL:** consulta, ordenação por preço, filtro de preço e fallback sem feed.
- **7 arquivos CFML compilados** em ambiente isolado com o runtime de produção.
- **6 downloads novos**, todos com os cabeçalhos exigidos pelo importador.
- **7 verificações HTTP** após o deploy, incluindo autenticação, métodos não remotos e página pública.
- As **95 combinações produto/loja** foram verificadas em páginas públicas com HTTP 200, preço esperado e botão de afiliado.
- Permissões privadas preservadas: configuração `0640`, proprietário `root`, grupo `988`; publicação do feed `0600`. Credenciais não foram incluídas nas evidências.

## Release e reversão

Release: `20261017T205036Z-7e9edb21`.

Backup do único arquivo de runtime alterado:
`/var/backups/awin-price-correction-20261017/20261017T205036Z-7e9edb21`.

SHA-256 de `services/ComparadorAwinFeedService.cfc`:

- Antes: `9ed4234b7b5ae11e15812a6699da1aef20cb97b01ac7cbe0617b578a468430e1`.
- Publicado: `b129aef253c0ff4670bb8c85b266f484d07b58dd213119f6c1544565b6d1778f`.

Antes de reverter, conferir o recibo e o hash atual para não sobrescrever uma alteração posterior. A reversão normal restaura somente o serviço do backup, conservando proprietário, grupo e permissões, e revalida o hash e os HTTP checks. **Não restaurar cegamente `feed-publication.json`: esse arquivo inclui bloqueios e histórico que podem ter mudado depois do deploy.** A cópia de diagnóstico anterior está em `/var/backups/awin-price-correction-20261017/state-before/20261017T205036Z-7e9edb21-feed.json`; seu uso exige preservar os bloqueios atuais e a janela de validade das ofertas. Depois de qualquer reversão, executar uma sincronização autorizada e conferir preços, bloqueios e campanhas.

O harness e os downloads privados foram removidos; o hash publicado e os hashes intactos do consumidor foram novamente conferidos. Desktop de 1280 px e celular de 390 px validados, sem transbordamento horizontal. A atualização automática existente permanece a cada 30 minutos; a execução comprovada desta publicação foi a importação autenticada no Business às 17:51.

## Recibos de validação

Os fatos deste registro foram conferidos em `download-result.json`, `tests/result-live.json`, `tests/result-awin-feed-price-review.json`, `tests/result-awin-feed.json`, `tests/result-awin-feed-centauro-dates.json`, `tests/result-query.json`, `tests/compile.json`, `release-result.json` e `verified.json`, preparados durante a revisão. Os recibos sanitizados estão salvos junto desta documentação; feeds brutos, configurações privadas e chaves não foram copiados para o repositório.

[Recibo de publicação e validação](2026-10-17_awin-precos-promocionais_recibo.json).
