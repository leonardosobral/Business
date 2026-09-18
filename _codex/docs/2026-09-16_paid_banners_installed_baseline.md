# Banners CPC — base instalada informada pelo operador

Origem: resultados das consultas somente leitura enviados pelo usuário nesta tarefa em 16/09/2026. Não representam uma aplicação da nova migration nem uma consulta direta deste agente ao banco de produção.

## Migrations registradas

- 2026-08-21_ads_phase2_payments
- 2026-09-02_ads_event_auction_ranking
- 2026-09-04_ads_review_activation_invariants
- 2026-09-11_ads_prepare_pending_campaign_edit
- 2026-09-15_ads_house_banner_scope

## Funções

Todas as dez funções retornaram proprietário `ads_owner`, `security_definer=true` e `search_path=pg_catalog`. Os hashes coincidem com as fontes canônicas usadas no banco de testes.

| Função | MD5 de prosrc |
| --- | --- |
| activate_campaign(uuid,integer,text) | 2580712cab80fc2877c84567dc218dbf |
| change_campaign_status(uuid,text,integer,text) | 17dd5425cd5718382aac7840a5423cc6 |
| charge_cpc_click(uuid,uuid,timestamptz,integer,text,text,text,jsonb,timestamptz) | 0ed38e5098c4bdbd8229bb2725572d79 |
| charge_cpc_click_token(uuid,uuid,text,timestamptz,integer,text,text,text,jsonb) | 88c711904e4ccbab884b3a15911c1c5b |
| invalidate_campaign_review_on_edit() | 018f38ccb1e4c72dc8f54f5fdb41d418 |
| prepare_campaign_for_edit(uuid,bigint,integer) | e037a39405020b7103c761d8837ed1da |
| record_cpc_viewable(uuid,uuid,text,timestamptz,integer,numeric,text,text,jsonb) | 478c36b9200bac29a90b8e3f15655560 |
| replace_campaign_placements(uuid,text[],integer,text) | 397c306642cb15fca4eada73de0b62e7 |
| serve_delivery(uuid,uuid,uuid,uuid,uuid,text,timestamptz,timestamptz,smallint,integer,text,text,text,character,text,text,jsonb,timestamptz) | ebccb7993c50822d5946e7c930039eb4 |
| refresh_campaign_review_prerequisites(bigint,integer,integer) | cfc75fe1d17d722efe9989eb39ce39df |

## Constraints informadas

- `ads.advertisements.ck_ads_advertisements_product` e `ads.deliveries.ck_ads_deliveries_product`: BANNER permitido somente como HOUSE na base anterior.
- `ads.advertisements.ck_ads_advertisements_reference`: EVENT exige core_event_id; BANNER exige core_event_id nulo.
- `ads.credit_ledger.ck_ads_credit_ledger_click`: débito de clique CPC somente EVENT, preço positivo, valor negativo igual ao preço e referências obrigatórias completas.
- Nenhuma `ck_ads_review_product` foi retornada, como esperado antes desta migration.

Esta conferência não substitui as guardas transacionais de instalação/reexecução da migration nem os testes finais do artefato corrigido. Alteração posterior da base deve abortar a instalação até revisão da divergência.
