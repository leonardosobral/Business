# Diagnóstico: cliques sem impressões

Investigação somente leitura em produção. Captura dos logs: 2026-09-12 01:09:32 UTC.

## Conclusão e limites

Há forte evidência de um coletor automatizado seguindo links de anúncio e escapando do filtro de tráfego do endpoint CPC. O defeito de classificação foi reproduzido offline. A atribuição de cada débito financeiro ainda depende de conciliação no banco; HTTP 302 sozinho não confirma cobrança. Não foram alterados código publicado, campanhas, métricas ou saldo.

## Evidência observada

- Um User-Agent anômalo, terminado em `Gecko/20041107 Firefox/x.x`, fez 1.054 requisições entre 23:05:59 e 23:24:11 UTC de 11/09/2026 (20:05:59–20:24:11 em São Paulo).
- Foram 1.042 páginas de evento, 11 acessos GET a links CPC e uma outra requisição. Não houve chamada de impressão desse agente nas rotações inspecionadas.
- Os 11 delivery IDs correspondem a entregas válidas nos logs, todas no placement `rr-state-events-native`. Logo após cada acesso ao link, aparece uma requisição para a página do evento correspondente.
- Entre elas estão todas as sete campanhas identificadas no painel com zero impressões e um clique: Rio de Janeiro, Recife, Salvador, Brasília, Porto Alegre, Fortaleza e Bonito.
- As outras quatro correspondem a Juiz de Fora, Itaipu, Campinas e Avaí. Ter impressões de outros visitantes não exclui o acesso suspeito nessas campanhas.
- Endereços e tokens foram excluídos do resultado preservado. Um único endereço registrado não prova identidade, especialmente atrás de proxy.

## Mecanismo técnico

A impressão depende de rastreamento de visibilidade no navegador. O clique entra por um GET ao endpoint `api/ads/v1/cpc-click.cfm`. Seu filtro cobre bots conhecidos e cabeçalhos de prefetch, mas não reconhece o User-Agent observado. Com token válido, a requisição pode chegar a `ads.charge_cpc_click_token` sem impressão anterior. O wrapper SQL inspecionado valida token, entrega e horário; não exige uma impressão antes de chamar o procedimento canônico.

Um clique humano rápido também pode ocorrer antes da impressão de um segundo. Porém isso não explica adequadamente a sequência de mais de mil páginas pelo mesmo User-Agent anômalo, sem nenhum envio de impressão. A hipótese de automação é sustentada pelo comportamento, não apenas pelo nome do navegador.

Os demais cabeçalhos do acesso original não constam do access log. A reprodução usa o User-Agent exato, token sintético e ausência de cabeçalhos de prefetch. Ela confirma a brecha do endpoint, não reproduz uma transação financeira real.

## Reprodução

Teste: `_codex/tests/ads-click-incident-characterization.cfm`.
Executa o endpoint local cujo SHA-256 coincide com o publicado (`846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82`), substituindo HTTP, banco e logs por adaptadores locais.

Resultado observado:

```text
REPRODUCED: incident User-Agent reaches the canonical charge adapter without a viewable impression.
PASS: 275 CPC click traffic checks; no datasource or financial call executed.
```

O teste é de caracterização do defeito: esperar uma chamada de cobrança aqui documenta o comportamento inseguro atual, não um contrato desejado para a correção.

## Fontes e pendências

- Script reproduzível: `_codex/scripts/diagnose_ads_click_impression_logs.py`.
- Resultado sanitizado: `_codex/docs/2026-09-11_ads_click_impression_evidence.json`, incluindo os 11 delivery IDs para conciliação.
- Logs lidos: access.log e access.log.1 do Apache; ads_v1_cpc.log e ads_v1_cpc.1.log do ColdFusion.
- Métricas operacionais do Business somam `ads.daily_metrics` por campanha/conta; investimento vem também do estado de orçamento. Não foi feita consulta independente aos eventos/ledger.
- HTTP 204 do endpoint de impressão não garante persistência: o endpoint pode ocultar erro. A investigação não exclui perdas adicionais de tracking em outros visitantes.

Próximo passo recomendado: reconciliar esses IDs com eventos de clique e ledger, tratar a aceitação de automação antes de cobrança e revisar observabilidade. Qualquer estorno deve ser rastreável e baseado nos débitos confirmados. Não fabricar impressões para ajustar CTR e não exigir um segundo de exposição para todo clique humano sem avaliar essa mudança de regra.
