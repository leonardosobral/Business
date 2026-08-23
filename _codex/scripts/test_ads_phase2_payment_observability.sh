#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROADRUNNERS_ROOT="$(cd "$REPO_ROOT/../RoadRunners" && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }
require_pattern() {
    if [[ -f "$1" ]] && rg -q -i -U --pcre2 -- "$2" "$1"; then pass "$3"; else fail "$3"; fi
}
reject_pattern() {
    if [[ -f "$1" ]] && rg -q -i -U --pcre2 -- "$2" "$1"; then fail "$3"; else pass "$3"; fi
}

config_check="administracao/config-check/index.cfm"
dashboard="includes/estrutura/home_admin_dashboard.cfm"
client="ads/components/PagarMeClient.cfc"
example="config/pagarme.local.example.cfm"
business_doc="_codex/docs/publicidade_ads_phase2_business.md"
master_plan="$ROADRUNNERS_ROOT/_codex/docs/publicidade_ads_plano_mestre.md"

require_pattern "$client" 'webhookRegistered' "cliente expoe somente flag de cadastro do webhook"
require_pattern "$client" 'endpointAllowed' "cliente informa allowlist de endpoint"
require_pattern "$client" '(?s)function[[:space:]]+logProviderNetworkError.*?sanitizeProviderLogValue.*?business_ads_payments.*?stage=provider_http' "cliente registra falha HTTP sanitizada no log de pagamentos"
require_pattern "$client" '(?s)function[[:space:]]+logProviderRejection.*?summarizeProviderError.*?business_ads_payments.*?stage=provider_rejected' "cliente registra rejeicao estruturada sem resposta bruta"
reject_pattern "$client" '(?s)(cflog|writeLog)[[:space:]]*\([^;]{0,700}text[[:space:]]*=[[:space:]]*"[^"]*(secretKey|Authorization|serializedBody|arguments[.]body|responseBody)' "log HTTP nao contem credencial, payload ou resposta bruta"
require_pattern "$example" 'webhookRegistered[[:space:]]*=[[:space:]]*false' "exemplo exige confirmacao operacional do webhook"

require_pattern "$config_check" 'PagarMeClient' "config-check usa diagnostico sanitizado do cliente"
for label in 'Configuracao presente' 'Modo Pagar.me' 'Endpoint permitido' 'Checkout habilitado' 'Webhook registrado' 'Job de reconciliacao'; do
    require_pattern "$config_check" "$label" "config-check mostra $label"
done
require_pattern "$config_check" 'ads\.list_payment_intents_for_reconciliation' "config-check valida funcoes SQL de pagamento"
require_pattern "$config_check" 'has_function_privilege' "config-check valida EXECUTE efetivo"
require_pattern "$config_check" 'has_table_privilege' "config-check valida ausencia de DML direto"
require_pattern "$config_check" 'datasource="runnerhub"|datasource[[:space:]]*=[[:space:]]*"runnerhub"' "diagnostico Ads usa runnerhub"
reject_pattern "$config_check" '(secretKey[[:space:]]*[#)]|pagarMeLocalConfig\.secretKey|writeOutput\([^\n]*secret)' "config-check nao imprime chave Pagar.me"

for signal in businessAdminHomeAdsPendingOld businessAdminHomeAdsReview businessAdminHomeAdsOpenHolds businessAdminHomeAdsPaidWithoutLedger businessAdminHomeAdsLedgerWithoutIntent businessAdminHomeAdsReconcileLastDuration; do
    require_pattern "$dashboard" "$signal" "dashboard calcula $signal"
done
require_pattern "$dashboard" 'ads\.payment_intents' "dashboard le intents canonicas"
require_pattern "$dashboard" 'ads\.account_financial_holds' "dashboard le holds canonicos"
require_pattern "$dashboard" 'ads\.credit_ledger' "dashboard reconcilia ledger canonico"
require_pattern "$dashboard" 'api/ads/payments/reconcile\.cfm' "dashboard acompanha o job correto"
require_pattern "$dashboard" 'datasource="runnerhub"|datasource[[:space:]]*=[[:space:]]*"runnerhub"' "dashboard Ads usa runnerhub"

require_pattern "$business_doc" '## Estado implementado' "runbook registra estado real"
require_pattern "$business_doc" '(?s)migration.*contract tests.*auditoria' "runbook documenta ordem do banco"
require_pattern "$business_doc" 'webhook' "runbook documenta cadastro do webhook"
require_pattern "$business_doc" 'rollback|recuo' "runbook documenta rollback"
require_pattern "$business_doc" 'R\$ 50' "runbook documenta compra minima"
require_pattern "$business_doc" 'PIX.*cart[aã]o|cart[aã]o.*PIX' "runbook documenta meios de pagamento"
require_pattern "$master_plan" 'Fase 2 comercial.*implementa' "plano mestre registra implementacao da Fase 2"
require_pattern "$master_plan" 'PostgreSQL principal|schema `ads`' "plano mantem banco no schema principal"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 PAYMENT OBSERVABILITY: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi
printf '\nADS PHASE 2 PAYMENT OBSERVABILITY: PASS\n'
