# Contenção dos cliques do coletor — 11/09/2026

## Resultado

Correção no RoadRunners publicada em 12/09/2026 às 08:37:54 em São Paulo. O User-Agent observado e
suas variantes de placeholder passam pelo redirecionamento somente leitura,
sem chamar o procedimento de cobrança. Não se exige impressão anterior para
cliques humanos. É contenção de assinatura conhecida, não antifraude universal.

RoadRunners alterado:

- `api/ads/v1/cpc-click.cfm`: reconhecimento de Firefox/x.x e rv:x.x.x.
- `_codex/tests/ads-cpc-click-traffic.cfm`: regressão e controles legítimos.
- `_codex/docs/2026-09-04_ads_cpc_click_traffic.md`: contrato e publicação.

Business: somente ferramentas de diagnóstico, consulta e testes em `_codex`;
nenhum runtime da interface foi alterado nesta etapa. A reprodução antiga foi
convertida em teste de regressão no mesmo arquivo.

## Validação

- RED: assinatura exata e três variações invocavam cobrança antes do patch.
- GREEN: suite RoadRunners com 324 verificações passou, preservando Firefox
  numérico atual/antigo, Chrome, UA vazio, clique imediato e retry.
- Regressão Business: 281 verificações; `CONTAINED`, sem chamada financeira.
- `bash _codex/scripts/audit_ads_v1_cpc_cfml_static.sh`: passou.
- Revisão independente não encontrou bypass introduzido ou regressão concreta
  no escopo de contenção da assinatura. UA spoofing continua sendo limitação.
- Compilação Adobe ColdFusion: 1/1 em `/tmp/ads-click-compile.JsSAPD`, fora do
  webroot do site. Não executou endpoint nem acessou datasource.
- Consulta de conciliação executada em PostgreSQL 16 temporário local: 11 linhas,
  IDs exatos, sem multiplicação por joins, estorno parcial/total, registros
  ausentes/rejeitados e ledger sem alterações. Primeiro sandbox bloqueou memória
  compartilhada; execução autorizada fora dele passou. Cluster encerrado ao fim.

## Conciliação recebida e reparo preparado

Executar integralmente `_codex/sql/2026-09-11_ads_click_incident_readonly.sql`
no banco operacional. É uma transação READ ONLY com SELECT sobre o schema ads,
timeout e ROLLBACK; não é migration, não consulta public e não altera dados.

Os IDs de evento e entrega vêm dos logs coletados, preservados em
`_codex/docs/2026-09-11_ads_click_incident_event_ids.json`. A consulta associa
o clique exato a DEBIT/CLICK e soma REVERSAL pelo reference_entry_id, evitando
confundir outro clique na mesma entrega. Expõe diferença de horário e campanhas
divergentes; os resultados são candidatos à revisão, não autorização de estorno.

O usuário forneceu o resultado das 11 linhas: todos os recibos correspondem
ao evento/entrega e possuem um débito, sem estorno, com diferença de horário
inferior a um segundo. Total confirmado pelo resultado fornecido: BRL 6,90;
conta 2 (Live!) BRL 5,96; conta 1 (Grupo STC/Avaí) BRL 0,94. Não houve consulta
direta ao ledger pela ferramenta nesta sessão.

O SQL `_codex/sql/2026-09-12_ads_click_incident_reversal.sql` foi executado
pelo usuário, que forneceu a conciliação posterior: 11 débitos já estornados,
BRL 6,90 devolvidos e BRL 0,00 líquidos. Instruções, validações e limites estão em
`_codex/docs/2026-09-12_ads_click_deploy_and_reversal.md`.

## Publicação

Somente RoadRunners `api/ads/v1/cpc-click.cfm`; sem migration ou deploy Business.
SHA candidato: `ff67e92dd0950e18970a38906b2c0c894fd1d5311e5bba0bd46f800283ffb2ab`.
SHA publicado observado na investigação:
`846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82`.
Antes de publicar, confirmar estado atual, preservar backup, substituir somente
esse arquivo e verificar hash. Rollback deve restaurar apenas esse arquivo,
com guarda para não sobrescrever alterações posteriores. Testes não devem ser
publicados. Nenhum clique real deve ser gerado para validação.

Publicação concluída em 2026-09-12T11:37:54.362921Z. Backup confirmado:
`/var/backups/ads-click-containment-20260912.02tysi0p/cpc-click.cfm.before`.
Hash de produção igual ao candidato; backup igual ao hash anterior. Mantidos
owner 0:0 e modo 0644. Compilação Adobe ColdFusion após publicação: 4/4 endpoints
Ads, exit 0. Nenhum clique ou débito de teste foi executado em produção.
