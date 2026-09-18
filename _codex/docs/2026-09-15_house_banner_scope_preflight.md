# HOUSE banner scope — preflight

- DataGrip: separate `console_6 [RunnerHub]`, existing authenticated connection, database `runnerhub`, role `runner_dba`; read-only queries only so far. No credential read or changes.
- Canonical Avaí HOUSE banner: `28c3eb44-60ec-4745-9128-25969c4172ba`, name `Avai`, account 1, ACTIVE; `target_region_code` NULL and no `banner_scope_v1`. Existing image sizes 1200×1200 / 720×350; weight/priority 1; dates 01/09/2026 17:26 → 20/09/2026 17:26; destination `https://www.movnow.com.br/eventos/371-avai-run-2026`. User authorized only SC scope change; preserve remaining properties.
- All six banners currently have no region/scope restriction. Four active, two paused. Do not activate paused banners or change their periods.
- Production differs from checkout in `RoadRunners/api/home_sidebar.cfm` and `includes/estrutura/home_sidebar_async_slot.cfm` due to a separately published sidebar layout. Preserve production layout by applying only this task's context hunks to private production baselines; do not publish stale local file wholesale. Private baseline copies are in this plan's SDD workspace.

## Production SHA-256 before task

| Site | Path | SHA-256 |
|---|---|---|
| Business | portal/includes/banner_management_backend.cfm | 56350db9e69a3693f03baf6db98541f3874a3c601ad4a0033b22c95f456901a3 |
| Business | portal/banners/home.cfm | 7ab20bacc1f83332ed12a247fcc7f6c4e59071efa8ae0073569638abc7a4280e |
| RoadRunners | services/AdsV1BannerDeliveryService.cfc | 47f1fde5e214c5c3946b4863a1b526e803ecc031f278313af32cd443c775ddaf |
| RoadRunners | includes/ads_v1/banner_delivery.cfm | 4bc928f0af817aa2824dd5f8fee06e26fbd48cb011361effed39693d07e194d1 |
| RoadRunners | includes/eventos_ads.cfm | b6f1083272fbb9d8455f273ccffad9ef2f427524fce804ecd52bd73786e6de35 |
| RoadRunners | includes/estrutura/home_sidebar_promos.cfm | 9fa1278a8eafe860c1c819d0bc22bbd0f453e255ea68deef7e6735a3f710a106 |
| RoadRunners | includes/estrutura/home_sidebar_mobile_banner.cfm | e71cff9658e5dc83fb1cf2e593f1f62083ffb06974c84e590bcd9260f1127f0f |
| RoadRunners | includes/estrutura/home_sidebar_async_slot.cfm | 5e0ca76ec06ad2c83b15e786c8c86c6603b7f9128cc32b321a620b455ac319f3 |
| RoadRunners | includes/estrutura/home_sidebar_mobile_banner_slot.cfm | 5bc8888d6b8ef3cc0b51225b551f1d8aafcc1d6c8d933057614a4dba3d1e86d3 |
| RoadRunners | includes/estrutura/feed_lateral.cfm | cde83cc3f9fb7e1eaca47fa3026fb6df2943b77f83638309b0f3af0e1c720bfa |
| RoadRunners | api/home_sidebar.cfm | ad545f13888bfd3452b574a7bd32e920b2a5361edb4ea115ea3d0efce1ed5e97 |
| RoadRunners | api/home_mobile_banner.cfm | f487b2c73c6306d58f4af597f05439fa013a2bb402cc468ecce5f49c8dadedf8 |

Local baseline matches except the two sidebar files above. No runtime publication or database write performed during preflight.

Production `pg_proc.prosrc` MD5 (read in DataGrip) matches migration preconditions exactly:

- `save_house_banner_campaign`: `70a058f54d9578b0d23531ad1576c443`, owner ads_owner, EXECUTE ads_business.
- `select_delivery_candidate_v2`: `dd39e4b47d95cf64fcef6034a48b6f64`, owner ads_owner, EXECUTE ads_delivery.
- `serve_delivery`: `ff5432fde3cacf729a7a79673c8dbe9e`, owner ads_owner, EXECUTE ads_delivery.
