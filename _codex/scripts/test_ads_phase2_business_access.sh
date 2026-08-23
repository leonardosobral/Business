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

require_file() {
    local path="$1"
    local description="$2"

    if [[ -f "$path" ]]; then
        pass "$description"
    else
        fail "$description"
    fi
}

require_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ -e "$path" ]] && rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

extract_list() {
    local variable_name="$1"

    rg -o -i --pcre2 \
        "${variable_name}[[:space:]]*=[[:space:]]*\"[A-Z,]+\"" \
        ads/includes/access.cfm 2>/dev/null \
        | head -n 1 \
        | sed -E 's/^[^=]+=[[:space:]]*"([A-Z,]+)"$/\1/I'
}

role_in_list() {
    local role="$1"
    local roles="$2"
    [[ ",${roles}," == *",${role},"* ]]
}

assert_capabilities() {
    local label="$1"
    local role="$2"
    local real_admin="$3"
    local has_account="$4"
    local has_actor="$5"
    local expected="$6"
    local can_view=0
    local can_manage=0
    local can_purchase=0
    local can_view_payments=0
    local can_admin_finance=0

    if (( has_account == 1 && has_actor == 1 )) \
        && { (( real_admin == 1 )) || role_in_list "$role" "$view_roles"; }; then
        can_view=1
    fi
    if (( can_view == 1 )) \
        && { (( real_admin == 1 )) || role_in_list "$role" "$campaign_roles"; }; then
        can_manage=1
    fi
    if (( can_view == 1 )) \
        && { (( real_admin == 1 )) || role_in_list "$role" "$purchase_roles"; }; then
        can_purchase=1
    fi
    if (( can_view == 1 )) \
        && { (( real_admin == 1 )) || role_in_list "$role" "$payment_roles"; }; then
        can_view_payments=1
    fi
    if (( has_account == 1 && has_actor == 1 && real_admin == 1 )); then
        can_admin_finance=1
    fi

    local actual="${can_view}${can_manage}${can_purchase}${can_view_payments}${can_admin_finance}"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (esperado=$expected obtido=$actual)"
    fi
}

require_file "ads/includes/access.cfm" "include central de acesso existe"

view_roles="$(extract_list adsAccessViewRoles)"
campaign_roles="$(extract_list adsAccessCampaignRoles)"
purchase_roles="$(extract_list adsAccessPurchaseRoles)"
payment_roles="$(extract_list adsAccessPaymentRoles)"

[[ "$view_roles" == "OWNER,ADMIN,OPERADOR,VISUALIZADOR" ]] \
    && pass "papeis de visualizacao estao completos" \
    || fail "papeis de visualizacao estao completos"
[[ "$campaign_roles" == "OWNER,ADMIN,OPERADOR" ]] \
    && pass "papeis de campanha estao corretos" \
    || fail "papeis de campanha estao corretos"
[[ "$purchase_roles" == "OWNER,ADMIN" ]] \
    && pass "papeis de compra estao corretos" \
    || fail "papeis de compra estao corretos"
[[ "$payment_roles" == "OWNER,ADMIN" ]] \
    && pass "papeis de visualizacao de pagamentos estao corretos" \
    || fail "papeis de visualizacao de pagamentos estao corretos"

assert_capabilities "OWNER: view/manage/purchase/payments, sem admin financeiro" "OWNER" 0 1 1 "11110"
assert_capabilities "ADMIN: view/manage/purchase/payments, sem admin financeiro" "ADMIN" 0 1 1 "11110"
assert_capabilities "OPERADOR: view/manage apenas" "OPERADOR" 0 1 1 "11000"
assert_capabilities "VISUALIZADOR: somente view" "VISUALIZADOR" 0 1 1 "10000"
assert_capabilities "admin interno real com conta: todas as capacidades" "OWNER" 1 1 1 "11111"
assert_capabilities "admin interno real sem conta: nenhuma capacidade" "" 1 0 1 "00000"
assert_capabilities "papel sem ator real: nenhuma capacidade" "OWNER" 0 1 0 "00000"

require_pattern \
    "ads/includes/access.cfm" \
    '(?s)adsAccessAccountId[[:space:]]*=.*?businessActiveAccountId.*?adsAccessActorId[[:space:]]*=.*?qPerfil\.id.*?adsAccessRole[[:space:]]*=.*?businessCurrentAccountRole.*?adsAccessRealIsAdmin[[:space:]]*=.*?businessRealIsAdmin' \
    "capacidades derivam somente da conta, papel e ator confiaveis"
if rg -q -i -- '\b(FORM|URL|COOKIE)\.' ads/includes/access.cfm; then
    fail "include de acesso nao confia em FORM, URL ou COOKIE"
else
    pass "include de acesso nao confia em FORM, URL ou COOKIE"
fi
require_pattern \
    "ads/includes/access.cfm" \
    '(?s)adsAccessCanView[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessHasAccount[[:space:]]+AND[[:space:]]+VARIABLES\.adsAccessHasActor[[:space:]]+AND[[:space:]]*\([[:space:]]*VARIABLES\.adsAccessRealIsAdmin[[:space:]]+OR[[:space:]]+listFindNoCase\(VARIABLES\.adsAccessViewRoles,[[:space:]]*VARIABLES\.adsAccessRole\)[[:space:]]+GT[[:space:]]+0[[:space:]]*\)' \
    "canView exige conta, ator e papel de leitura ou admin real"
require_pattern \
    "ads/includes/access.cfm" \
    '(?s)adsAccessCanManageCampaign[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessCanView[[:space:]]+AND[[:space:]]*\([[:space:]]*VARIABLES\.adsAccessRealIsAdmin[[:space:]]+OR[[:space:]]+listFindNoCase\(VARIABLES\.adsAccessCampaignRoles,[[:space:]]*VARIABLES\.adsAccessRole\)[[:space:]]+GT[[:space:]]+0[[:space:]]*\)' \
    "canManageCampaign usa a lista de papeis de campanha"
require_pattern \
    "ads/includes/access.cfm" \
    '(?s)adsAccessCanPurchaseCredit[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessCanView[[:space:]]+AND[[:space:]]*\([[:space:]]*VARIABLES\.adsAccessRealIsAdmin[[:space:]]+OR[[:space:]]+listFindNoCase\(VARIABLES\.adsAccessPurchaseRoles,[[:space:]]*VARIABLES\.adsAccessRole\)[[:space:]]+GT[[:space:]]+0[[:space:]]*\)' \
    "canPurchaseCredit usa a lista OWNER/ADMIN"
require_pattern \
    "ads/includes/access.cfm" \
    '(?s)adsAccessCanViewPayments[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessCanView[[:space:]]+AND[[:space:]]*\([[:space:]]*VARIABLES\.adsAccessRealIsAdmin[[:space:]]+OR[[:space:]]+listFindNoCase\(VARIABLES\.adsAccessPaymentRoles,[[:space:]]*VARIABLES\.adsAccessRole\)[[:space:]]+GT[[:space:]]+0[[:space:]]*\)' \
    "canViewPayments usa a lista OWNER/ADMIN"
require_pattern \
    "ads/includes/access.cfm" \
    'adsAccessCanAdminFinance[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessHasAccount[[:space:]]+AND[[:space:]]+VARIABLES\.adsAccessHasActor[[:space:]]+AND[[:space:]]+VARIABLES\.adsAccessRealIsAdmin' \
    "financeiro interno exige conta, ator e admin reais"

require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)<cfinclude[[:space:]]+template="access\.cfm"[^>]*>.*?<cfif[[:space:]]+len\(trim\(FORM\.ads_v1_action' \
    "backend inclui acesso antes do dispatch"
require_pattern \
    "ads/includes/backend.cfm" \
    'adsV1CampaignActions[[:space:]]*=[[:space:]]*"save_campaign,activate_campaign,change_campaign_status"' \
    "acoes de campanha usam grupo explicito"
require_pattern \
    "ads/includes/backend.cfm" \
    'adsV1FinanceActions[[:space:]]*=[[:space:]]*"credit_account,reverse_click_debit"' \
    "acoes financeiras usam grupo explicito"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)listFindNoCase\(VARIABLES\.adsV1CampaignActions,[[:space:]]*VARIABLES\.adsV1Action\).*?NOT[[:space:]]+VARIABLES\.adsAccessCanManageCampaign.*?<cfheader[[:space:]]+statuscode="403".*?<cfthrow.*?</cfif>' \
    "backend bloqueia campanha sem canManageCampaign"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)listFindNoCase\(VARIABLES\.adsV1FinanceActions,[[:space:]]*VARIABLES\.adsV1Action\).*?NOT[[:space:]]+VARIABLES\.adsAccessCanAdminFinance.*?<cfheader[[:space:]]+statuscode="403".*?<cfthrow.*?</cfif>' \
    "backend bloqueia financeiro sem canAdminFinance"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)adsAccessCanAdminFinance.*?<cfquery[[:space:]]+name="qAdsV1Ledger".*?<cfquery[[:space:]]+name="qAdsV1ReversibleDebits"' \
    "backend so carrega historico financeiro administrativo para admin financeiro"

require_pattern \
    "ads/home.cfm" \
    '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanManageCampaign.*?>.*?href="\./#campaign-form"[^>]*>Nova campanha.*?</cfif>' \
    "CTA de campanha acompanha canManageCampaign"
require_pattern \
    "ads/home.cfm" \
    '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanManageCampaign>.*?<section[^>]+id="campaign-form".*?ads_v1_action"[[:space:]]+value="save_campaign".*?</section>.*?</cfif>' \
    "formulario de campanha acompanha canManageCampaign"
require_pattern \
    "ads/home.cfm" \
    '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanAdminFinance>.*?value="credit_account".*?value="reverse_click_debit".*?</cfif>' \
    "controles financeiros acompanham canAdminFinance"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 BUSINESS ACCESS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PHASE 2 BUSINESS ACCESS: PASS\n'
