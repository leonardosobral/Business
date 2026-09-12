# Publicação CPC e estorno do incidente

## Publicado

Somente `/var/www/roadrunners.com.br/api/ads/v1/cpc-click.cfm` foi substituído,
com autorização do usuário, em 12/09/2026 às 08:37:54 (São Paulo).

- SHA publicado: `ff67e92dd0950e18970a38906b2c0c894fd1d5311e5bba0bd46f800283ffb2ab`.
- SHA anterior: `846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82`.
- Backup: `/var/backups/ads-click-containment-20260912.02tysi0p/cpc-click.cfm.before`.
- Substituição atômica, guardas de hash antes da cópia e antes da troca, owner
  0:0 e modo 0644 preservados. Compilação Adobe CF após publicação: 4/4.
- Nenhum runtime Business, schema ou registro financeiro foi alterado.

## SQL executado pelo usuário e conciliado

Em 12/09/2026, o usuário informou a execução e forneceu a nova consulta de
conferência. As 11 linhas estão em `DEBITO_JA_ESTORNADO`, cada estorno é igual
ao débito original e o débito líquido de cada linha é zero. Total do lote:
BRL 6,90 debitados, BRL 6,90 estornados, BRL 0,00 líquidos. Live! recebeu
BRL 5,96 e Grupo STC/Avaí BRL 0,94. Os totais repetidos nas linhas são totais
de janela SQL, não valores a somar novamente.

Fechamento financeiro destes 11 recibos confirmado pelo resultado fornecido;
não foi realizada uma nova consulta direta ao banco pelo assistente. Não é
necessário reexecutar o reparo. As instruções abaixo ficam como registro de
operação. A contenção publicada não equivale a proteção universal contra
tráfego automatizado que imita outros navegadores.

Arquivo: `_codex/sql/2026-09-12_ads_click_incident_reversal.sql`.

Executar o arquivo inteiro em sessão dedicada no banco operacional. É reparo
financeiro, NÃO migration de schema. Usa SELECT nas tabelas ads e EXECUTE na
função existente `ads.reverse_click_debit(uuid,text,integer,text)`, além de
tabelas temporárias de sessão. Não altera public e não concede permissões.

Alvos exclusivos: 11 recibos DEBIT/CLICK fornecidos pelo usuário na conciliação,
BRL 6,90: conta 2 Live! = 5,96; conta 1 Grupo STC/Avaí = 0,94.

O lote valida IDs de recibo/evento/entrega/campanha/conta, produto EVENT/CPC,
moeda, preço e valor antes da primeira reversão. Uma divergência cancela tudo.
Chave de idempotência por recibo e a função canônica impedem crédito duplicado.
Estornos completos já existentes são reconhecidos; parciais/inconsistentes
interrompem o lote para revisão. A razão registra o incidente e session_user;
não foi inventado um ID de usuário do Business.

O COMMIT só acontece ao final sem erro. Em erro, a transação fica abortada:
executar ROLLBACK na sessão se o cliente não a encerrou. Não executar trechos
isolados nem retirar as verificações. Os 11 resultados mostram recibos de
estorno e status; `creditado_nesta_execucao_brl` é o total do lote repetido em
cada linha, NÃO deve ser somado novamente. Em retry completo, o total é zero.

A função canônica corrige saldo disponível, gasto da campanha, custo diário e
contadores de reversão. Mantém os recibos originais e os registros/contagens de
clique. Não fabrica impressões nem reclassifica automaticamente eventos como
inválidos. Uma reversão pode devolver orçamento disponível para campanhas ainda
ativas, conforme as regras normais existentes.

## Verificação do reparo

`_codex/scripts/test_ads_click_incident_reversal.mjs` passou em PostgreSQL 16
local isolado, sem rede TCP ou credenciais de produção. Executou o SQL do lote
contra o corpo real de `reverse_click_debit` e `business_date` da foundation,
com fixtures sintéticas de tabelas.

Casos: crédito exato por conta; custo/orçamento reduzidos; 11 cliques históricos
preservados; reexecução sem crédito extra; estorno prévio reconhecido; recibo
divergente rejeitado; erro na métrica durante uma reversão cancela também as
anteriores do lote. Fixtures não reproduzem todos os triggers/ACLs de produção;
as verificações internas e permissões reais continuam sendo pré-requisitos.

Comando executado:
`node _codex/scripts/test_ads_click_incident_reversal.mjs`

O processo usou o Node bundled e PostgreSQL Homebrew 16. O cluster de teste foi
encerrado; fixtures locais ficaram no diretório temporário informado no output.
Nenhum estorno de produção foi executado pelo assistente.
