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

status_endpoint="api/ads/payments/status.cfm"
webhook="api/ads/payments/webhook.cfm"
service="ads/components/AdsPaymentService.cfc"
migration="$ROADRUNNERS_ROOT/_codex/sql/2026-08-21_ads_phase2_payments.sql"
contract_tests="$ROADRUNNERS_ROOT/_codex/sql/2026-08-21_ads_phase2_payments_contract_tests.sql"

require_file "$status_endpoint" "endpoint autenticado de status existe"
require_file "$webhook" "webhook publico existe"

require_pattern "$status_endpoint" 'request_method[^\n]*GET' "status aceita somente GET"
require_pattern "$status_endpoint" 'Cache-Control[^\n]*no-store' "status desabilita cache"
require_pattern "$status_endpoint" 'backend_login\.cfm' "status usa autenticacao Business"
require_pattern "$status_endpoint" 'ads/includes/access\.cfm' "status usa matriz central de acesso"
require_pattern "$status_endpoint" 'adsAccessCanViewPayments' "status exige acesso a pagamentos"
require_pattern "$status_endpoint" 'getIntentStatus[[:space:]]*\(' "status usa DTO estreito do servico"
require_pattern "$status_endpoint" 'account_balances' "status devolve saldo atualizado"
require_pattern "$status_endpoint" '(?s)account_balances.*?account\.id_conta[[:space:]]*=[[:space:]]*<cfqueryparam' "saldo e filtrado pela conta efetiva"
reject_pattern "$status_endpoint" '(provider_order_id|provider_charge_id|provider_payment_link_id|provider_payload|secretKey)' "status nao vaza dados internos do provedor"

require_pattern "$webhook" 'request_method[^\n]*POST' "webhook aceita somente POST"
require_pattern "$webhook" 'application/json' "webhook exige JSON"
require_pattern "$webhook" '(content_length|arrayLen\([^)]*content|len\([^)]*body)[^\n]*(262144|256[[:space:]]*\*[[:space:]]*1024)' "webhook limita o corpo"
reject_pattern "$webhook" '(SESSION\.|COOKIE\.|backend_login\.cfm)' "webhook nao depende de sessao ou cookie"
require_pattern "$webhook" 'recordPaymentEvent[[:space:]]*\(' "webhook registra recibo pelo servico controlado"
require_pattern "$webhook" 'completePaymentEvent|ads\.complete_payment_event' "webhook conclui recibo por operacao controlada"
require_pattern "$webhook" 'hash\([^\n]*SHA-256' "webhook guarda somente hash do corpo"
reject_pattern "$webhook" '(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+ads\.|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(payment_events|payment_intents|credit_ledger|account_balances)' "webhook nao faz DML financeiro direto"
reject_pattern "$webhook" '(provider_payload|raw_payload|body_json[[:space:]]*=)' "webhook nao persiste payload bruto"

for event in order.paid order.payment_failed order.canceled charge.pending charge.refunded chargeback.received charge.partial_canceled; do
    require_pattern "$webhook" "${event//./\\.}" "webhook trata $event"
done
require_pattern "$webhook" '(ignored|IGNORED)' "eventos fora do contrato recebem resposta neutra"
require_pattern "$webhook" 'processWebhookEvent[[:space:]]*\(' "processamento sensivel fica no servico"
require_pattern "$service" 'correlatePaymentIntent[[:space:]]*\(' "servico correlaciona somente por referencias"
require_pattern "$service" 'recordPaymentEvent[[:space:]]*\(' "servico registra recibo idempotente"
require_pattern "$service" 'completePaymentEvent[[:space:]]*\(' "servico conclui recibo idempotente"
require_pattern "$service" 'processWebhookEvent[[:space:]]*\(' "servico revalida evento no provedor"
require_pattern "$service" '(?s)processWebhookEvent.*?(getOrder|listOrdersByCode).*?(confirmPayment|reversePayment|transitionIntent)' "evento reconsulta o provedor antes da operacao financeira"
require_pattern "$service" 'chargeStatus' "servico valida estado da cobranca em estorno/chargeback"

require_pattern "$migration" 'CREATE OR REPLACE FUNCTION ads\.complete_payment_event' "migration cria conclusao controlada do recibo"
require_pattern "$migration" 'GRANT EXECUTE ON FUNCTION[\s\S]*?ads\.complete_payment_event' "runner recebe EXECUTE via ads_business"
require_pattern "$contract_tests" 'ads\.complete_payment_event' "contract tests cobrem conclusao do recibo"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 PAYMENT ENDPOINTS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi
printf '\nADS PHASE 2 PAYMENT ENDPOINTS: PASS\n'
