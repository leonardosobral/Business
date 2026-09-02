#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ -f "$path" ]] && rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

reject_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ ! -f "$path" ]] || ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
        rg -n -i -U --pcre2 -- "$pattern" "$path" >&2 || true
    fi
}

backend="ads/includes/backend.cfm"
payments_home="ads/includes/payments_home.cfm"
accounts_backend="administracao/contas/includes/backend.cfm"
home="ads/home.cfm"
campaigns_home="ads/includes/workspace_campaigns.cfm"

require_pattern \
    "$backend" \
    "'ads\.redeem_voucher\(bigint,text,integer\)'" \
    "readiness exige a funcao atomica de resgate"
require_pattern \
    "$backend" \
    '(?s)adsV1ApiReady[[:space:]]*=[[:space:]]*val\([^)]*expected_count[^)]*\)[[:space:]]+EQ[[:space:]]+10.*?resolved_count[^\n]*EQ[[:space:]]+10' \
    "readiness exige as dez funcoes do Business"
require_pattern \
    "$backend" \
    'adsV1VoucherActions[[:space:]]*=[[:space:]]*"redeem_voucher,reserve_voucher"' \
    "resgate e reserva possuem classe de autorizacao separada"
require_pattern \
    "$backend" \
    '(?s)adsV1Action[[:space:]]+EQ[[:space:]]+"redeem_voucher".*?NOT[[:space:]]+VARIABLES\.adsAccessCanPurchaseCredit.*?<cfheader[[:space:]]+statuscode="403"' \
    "somente OWNER, ADMIN da conta ou admin real resgata voucher"
require_pattern \
    "$backend" \
    '(?s)<cfcase[[:space:]]+value="redeem_voucher">.*?<cfquery[^>]+datasource="runnerhub"[^>]*>.*?FROM[[:space:]]+ads\.redeem_voucher[[:space:]]*\(' \
    "backend usa a funcao atomica pelo datasource runnerhub"
require_pattern \
    "$backend" \
    'success=voucher-redeemed' \
    "resgate concluido usa retorno explicito"

require_pattern \
    "$payments_home" \
    '<form[^>]+method="post"[^>]+id="ads-voucher-form"' \
    "painel de credito oferece formulario de voucher"
require_pattern \
    "$payments_home" \
    'name="ads_v1_action"[[:space:]]+value="redeem_voucher"' \
    "formulario envia a acao de resgate"
require_pattern \
    "$payments_home" \
    'name="ads_v1_csrf"[^\n]*adsV1Csrf' \
    "formulario de voucher usa o CSRF principal"
require_pattern \
    "$payments_home" \
    '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanPurchaseCredit>.*?id="ads-voucher-form"' \
    "formulario respeita a capacidade de compra da conta"
require_pattern \
    "$home" \
    '(?s)adsV1Summary\.active[[:space:]]+GT[[:space:]]+0.*?adsV1Summary\.balance[[:space:]]+LTE[[:space:]]+0.*?sem saldo.*?#payment-credit' \
    "painel explica quando campanha ativa nao veicula por falta de saldo"
require_pattern \
    "$campaigns_home" \
    '(?s)adsV1RowStatus[[:space:]]+EQ[[:space:]]+"ACTIVE"[[:space:]]+AND[[:space:]]+VARIABLES\.adsV1Summary\.balance[[:space:]]+LT[[:space:]]+qAdsV1Campaigns\.cpc_bid.*?Saldo insuficiente' \
    "linha da campanha ativa identifica saldo abaixo do CPC"

require_pattern \
    "$accounts_backend" \
    '(?s)<cfif[[:space:]]+NOT[[:space:]]+VARIABLES\.accountRegistrationIsExistingAccessRequest>.*?FROM[[:space:]]+ads\.apply_voucher_reservation[[:space:]]*\(' \
    "aprovacao de cadastro aplica a reserva pela funcao atomica"
reject_pattern \
    "$accounts_backend" \
    'accountRegistrationTargetAccountId[[:space:]]*=[[:space:]]*qBusinessAccountRegistrationVoucher\.id_conta' \
    "voucher reservado nao escolhe a conta de destino"
require_pattern \
    "$accounts_backend" \
    'FROM[[:space:]]+ads\.create_voucher[[:space:]]*\(' \
    "criacao administrativa usa funcao controlada"
require_pattern \
    "$accounts_backend" \
    'FROM[[:space:]]+ads\.change_voucher_status[[:space:]]*\(' \
    "cancelamento e reativacao usam funcao controlada"
reject_pattern \
    "$accounts_backend" \
    '(?s)UPDATE[[:space:]]+ads\.tb_ad_vouchers[[:space:]]+SET[[:space:]]+status[[:space:]]*=.*?id_usuario_resgate[[:space:]]*=' \
    "aprovacao nao marca voucher como resgatado sem creditar ledger"
reject_pattern \
    "$accounts_backend" \
    '(INSERT[[:space:]]+INTO|UPDATE)[[:space:]]+ads\.tb_ad_vouchers' \
    "Business nao executa DML direto na tabela financeira de vouchers"

if (( failures > 0 )); then
    printf '\nADS VOUCHER BALANCE BRIDGE: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS VOUCHER BALANCE BRIDGE: PASS\n'
