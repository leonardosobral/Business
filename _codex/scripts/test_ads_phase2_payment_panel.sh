#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

require_file() {
    [[ -f "$1" ]] && pass "$2" || fail "$2"
}

require_pattern() {
    local file="$1" pattern="$2" description="$3"
    if [[ -f "$file" ]] && rg -q -i -U --pcre2 -- "$pattern" "$file"; then
        pass "$description"
    else
        fail "$description"
    fi
}

reject_pattern() {
    local file="$1" pattern="$2" description="$3"
    if [[ -f "$file" ]] && rg -q -i -U --pcre2 -- "$pattern" "$file"; then
        fail "$description"
    else
        pass "$description"
    fi
}

backend="ads/includes/payments_backend.cfm"
home="ads/includes/payments_home.cfm"
root_backend="ads/includes/backend.cfm"
root_home="ads/home.cfm"
admin_home="ads/includes/workspace_admin.cfm"

require_file "$backend" "backend de pagamentos existe"
require_file "$home" "home de pagamentos existe"
require_pattern "$root_backend" '<cfinclude[[:space:]]+template="payments_backend\.cfm"' "backend principal inclui pagamentos"
require_pattern "$root_home" '<cfinclude[[:space:]]+template="includes/payments_home\.cfm"' "painel principal inclui pagamentos"

require_pattern "$backend" 'adsV1PaymentCsrf' "pagamentos usam CSRF exclusivo"
require_pattern "$backend" '(?s)compare\([^)]*FORM\.ads_payment_csrf.*?adsPaymentCsrf\)' "backend valida o CSRF de pagamentos"
require_pattern "$backend" 'adsAccessCanPurchaseCredit' "backend exige capacidade de comprar credito"
require_pattern "$backend" 'adsAccessCanViewPayments' "backend exige capacidade de ver pagamentos"
require_pattern "$backend" 'AdsPaymentService' "backend usa AdsPaymentService"
require_pattern "$backend" 'createCheckout[[:space:]]*\(' "backend cria checkout pelo servico"
require_pattern "$backend" 'business:payment:' "tentativa usa chave idempotente com namespace"
require_pattern "$backend" '(5000|50\.00)' "backend preserva compra minima de R$ 50"
require_pattern "$backend" 'payment_intents' "backend lista intencoes de pagamento"
require_pattern "$backend" '(?s)payment_intents.*?account_id[[:space:]]*=[[:space:]]*<cfqueryparam' "historico e filtrado pela conta efetiva"
reject_pattern "$backend" '\b(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+ads\.|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(payment_intents|credit_ledger|account_balances)' "backend nao faz DML financeiro direto"
reject_pattern "$backend" 'runner_dba' "backend usa apenas datasource operacional"

require_pattern "$home" 'R\$[[:space:]]*100' "formulario oferece atalho R$ 100"
require_pattern "$home" 'R\$[[:space:]]*250' "formulario oferece atalho R$ 250"
require_pattern "$home" 'R\$[[:space:]]*500' "formulario oferece atalho R$ 500"
require_pattern "$home" 'min="50"' "valor personalizado inicia em R$ 50"
require_pattern "$home" 'PIX' "painel informa PIX"
require_pattern "$home" 'cart[aã]o[^<]*(1x|uma vez)' "painel informa cartao em 1x"
require_pattern "$home" '(taxas[^<]*(RunnerHub|nossa conta)|sem desconto)' "painel informa taxas absorvidas"
require_pattern "$home" 'valor pago[^<]*credito|R\$ X pagos' "painel informa paridade entre pagamento e credito"
require_pattern "$home" 'Ir para o pagamento' "estado pendente oferece CTA do checkout"
require_pattern "$home" 'Atualizar status' "estado pendente oferece atualizacao manual"
require_pattern "$home" 'Aguardando|Confirmando' "estado pendente possui rotulo claro"
require_pattern "$home" '/api/ads/payments/status\.cfm' "painel prepara polling autenticado"
require_pattern "$home" '(setTimeout|backoff)' "polling usa espera progressiva"
require_pattern "$home" '(disabled[[:space:]]*=[[:space:]]*true|data-submitting)' "submit possui protecao de duplo clique"
require_pattern "$home" '(?s)<form[^>]+method="post"[^>]+action="\./\?view=payments#payment-credit"[^>]+id="ads-voucher-form"' "resgate de voucher preserva a area de pagamentos"
require_pattern "$home" '(?s)<form[^>]+method="post"[^>]+action="\./\?view=payments#payment-credit"[^>]+id="ads-payment-form"' "checkout preserva a area de pagamentos"
require_pattern "$home" 'Hist[oó]rico de pagamentos' "painel lista historico de pagamentos"
require_pattern "$home" 'Refer[eê]ncia' "historico mostra referencia curta"
require_pattern "$admin_home" 'Administra[cç][aã]o financeira' "financeiro interno e rotulado como administracao"
reject_pattern "$home" '(card_number|numero do cartao|CVV|CVC|validade do cartao)' "painel nao captura dados de cartao"
reject_pattern "$home" '(provider_order_id|provider_charge_id|provider_payment_link_id|provider_payload)' "painel nao exibe identificadores ou payload do provedor"
require_pattern "$root_home" '(?s)<cfif[[:space:]]+VARIABLES\.adsV1WorkspaceView[[:space:]]+EQ[[:space:]]+"admin"[[:space:]]+AND[[:space:]]+VARIABLES\.adsAccessCanAdminFinance>.*?workspace_admin\.cfm.*?</cfif>' "administracao financeira permanece restrita ao admin interno"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 PAYMENT PANEL: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PHASE 2 PAYMENT PANEL: PASS\n'
