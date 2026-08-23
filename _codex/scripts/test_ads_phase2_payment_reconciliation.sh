#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROADRUNNERS_ROOT="$(cd "$REPO_ROOT/../RoadRunners" && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }
require_file() { [[ -f "$1" ]] && pass "$2" || fail "$2"; }
require_pattern() {
    if [[ -f "$1" ]] && rg -q -i -U --pcre2 -- "$2" "$1"; then pass "$3"; else fail "$3"; fi
}
reject_pattern() {
    if [[ -f "$1" ]] && rg -q -i -U --pcre2 -- "$2" "$1"; then fail "$3"; else pass "$3"; fi
}

endpoint="api/ads/payments/reconcile.cfm"
job="administracao/cron-jobs/ads_payments_reconcile_job.sql"
client="ads/components/PagarMeClient.cfc"
service="ads/components/AdsPaymentService.cfc"
migration="$ROADRUNNERS_ROOT/_codex/sql/2026-08-21_ads_phase2_payments.sql"
contract_tests="$ROADRUNNERS_ROOT/_codex/sql/2026-08-21_ads_phase2_payments_contract_tests.sql"
audit="$ROADRUNNERS_ROOT/_codex/sql/2026-08-21_ads_phase2_payments_audit.sql"

require_file "$endpoint" "endpoint de reconciliacao existe"
require_file "$job" "incremental do job de reconciliacao existe"

require_pattern "$endpoint" 'request_method[^\n]*POST' "reconciliacao aceita somente POST"
require_pattern "$endpoint" 'cronJobs[^\n]*secrets|cronJobs[\s\S]{0,300}business_internal' "reconciliacao usa segredo interno do cron"
require_pattern "$endpoint" 'Bearer[[:space:]]+' "reconciliacao exige Bearer"
reject_pattern "$endpoint" '(SESSION\.|COOKIE\.|backend_login\.cfm)' "reconciliacao nao depende de sessao"
require_pattern "$endpoint" 'pg_try_advisory_xact_lock' "reconciliacao usa advisory lock"
require_pattern "$endpoint" 'getReconcileBatchSize[[:space:]]*\(' "batch vem da configuracao local"
require_pattern "$endpoint" 'listReconciliationCandidates[[:space:]]*\(' "endpoint usa seletor controlado"
require_pattern "$endpoint" 'reconcileIntent[[:space:]]*\(' "endpoint reutiliza o servico idempotente"
reject_pattern "$endpoint" '(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+ads\.|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(payment_intents|credit_ledger|account_balances)' "endpoint nao faz DML financeiro direto"
for key in examined credited alreadyProcessed pending failed review durationMs lastProviderTimestamp; do
    require_pattern "$endpoint" "$key" "resposta inclui $key"
done
reject_pattern "$endpoint" '(provider_payload|provider_order_id|provider_charge_id|secretKey)' "resposta nao expoe payload ou IDs do provedor"

require_pattern "$client" 'getReconcileBatchSize[[:space:]]*\(' "cliente expoe batch sanitizado"
require_pattern "$service" 'listReconciliationCandidates[[:space:]]*\(' "servico lista candidatos controlados"
require_pattern "$service" 'ads\.list_payment_intents_for_reconciliation' "servico chama funcao de selecao"
require_pattern "$service" 'providerUpdatedAt' "servico devolve timestamp sanitizado do provedor"

require_pattern "$migration" 'CREATE OR REPLACE FUNCTION ads\.list_payment_intents_for_reconciliation' "migration cria seletor de reconciliacao"
require_pattern "$migration" '(?s)list_payment_intents_for_reconciliation.*?SECURITY DEFINER.*?SET search_path = pg_catalog' "seletor usa security definer e search_path seguro"
require_pattern "$migration" "status[[:space:]]+IN[[:space:]]*\([[:space:]]*'CREATED'[[:space:]]*,[[:space:]]*'CHECKOUT_READY'[[:space:]]*,[[:space:]]*'PENDING'" "seletor limita estados nao terminais"
require_pattern "$migration" 'LEAST\([^\n]*30|BETWEEN[[:space:]]+1[[:space:]]+AND[[:space:]]+30' "seletor limita batch a 30"
require_pattern "$migration" 'GRANT EXECUTE ON FUNCTION[\s\S]*?ads\.list_payment_intents_for_reconciliation' "ads_business recebe apenas EXECUTE"
require_pattern "$contract_tests" 'ads\.list_payment_intents_for_reconciliation' "contract tests cobrem seletor"
require_pattern "$audit" 'ads\.list_payment_intents_for_reconciliation' "auditoria exige seletor"

require_pattern "$job" "Business - Reconciliacao de pagamentos Ads" "job possui nome operacional"
require_pattern "$job" 'https://business\.roadrunners\.run/api/ads/payments/reconcile\.cfm' "job aponta ao endpoint correto"
require_pattern "$job" "'POST'" "job usa POST"
require_pattern "$job" "'bearer'[[:space:]]*,[[:space:]]*'business_internal'" "job usa Bearer interno"
require_pattern "$job" 'interval_minutes[\s\S]{0,500}5' "job roda a cada cinco minutos"
require_pattern "$job" 'retry_limit[\s\S]{0,600}1' "job tem retry limitado"
require_pattern "$job" 'false' "job nasce inativo"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 PAYMENT RECONCILIATION: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi
printf '\nADS PHASE 2 PAYMENT RECONCILIATION: PASS\n'
