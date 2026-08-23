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

history_file="ads/includes/legacy_history.cfm"

[[ -f "$history_file" ]] \
    && pass "include do historico anterior existe" \
    || fail "include do historico anterior existe"

require_pattern \
    "ads/home.cfm" \
    '<cfinclude[[:space:]]+template="includes/legacy_history\.cfm"' \
    "painel principal incorpora o historico anterior"
reject_pattern \
    "ads/home.cfm" \
    "href[[:space:]]*=[[:space:]]*['\"]/ads/legacy/" \
    "painel principal nao encaminha o usuario para um segundo painel"

for table_name in tb_ad_eventos tb_ad_evento_metricas_dia tb_ad_conversion_log tb_ad_vouchers; do
    require_pattern \
        "$history_file" \
        "(FROM|JOIN)[[:space:]]+ads\\.${table_name}\\b" \
        "historico consulta ads.${table_name}"
done

require_pattern \
    "$history_file" \
    '(FROM|JOIN)[[:space:]]+public\.tb_conta_eventos\b' \
    "escopo das campanhas usa public.tb_conta_eventos"
require_pattern \
    "$history_file" \
    '(FROM|JOIN)[[:space:]]+public\.tb_evento_corridas\b' \
    "dados do evento usam public.tb_evento_corridas"
require_pattern \
    "$history_file" \
    '(?s)public\.tb_conta_eventos.*?id_conta[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' \
    "campanhas anteriores ficam restritas a conta efetiva"
require_pattern \
    "$history_file" \
    '(?s)ads\.tb_ad_evento_metricas_dia.*?id_conta[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' \
    "metricas anteriores ficam restritas a conta efetiva"
require_pattern \
    "$history_file" \
    '(?s)ads\.tb_ad_conversion_log.*?id_conta[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' \
    "conversoes anteriores ficam restritas a conta efetiva"
require_pattern \
    "$history_file" \
    '(?s)ads\.tb_ad_vouchers.*?id_conta[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' \
    "vouchers anteriores ficam restritos a conta efetiva"

query_count="$(rg -i -o '<cfquery\b' "$history_file" 2>/dev/null | wc -l | tr -d ' ')"
runnerhub_query_count="$(rg -i -o '<cfquery\b[^>]*datasource[[:space:]]*=[[:space:]]*"runnerhub"' "$history_file" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$query_count" -gt 0 && "$query_count" -eq "$runnerhub_query_count" ]]; then
    pass "todas as consultas do historico usam runnerhub"
else
    fail "todas as consultas do historico usam runnerhub (queries=$query_count runnerhub=$runnerhub_query_count)"
fi

require_pattern "$history_file" 'Sistema anterior' "historico recebe badge Sistema anterior"
require_pattern "$history_file" 'Campanhas anteriores' "historico identifica campanhas anteriores"
require_pattern "$history_file" 'Vouchers anteriores' "historico identifica vouchers anteriores"
require_pattern "$history_file" 'convers' "historico apresenta conversoes"
require_pattern "$history_file" 'nova (veiculacao|campanha)' "texto orienta criar campanha atual para nova veiculacao"
require_pattern "$history_file" 'somente leitura' "historico deixa claro que e somente leitura"

reject_pattern \
    "$history_file" \
    '<form\b|\bFORM\.|URL\.(acao|action|status|campanha)|<cftransaction\b' \
    "historico incorporado nao contem formularios nem acoes"
reject_pattern \
    "$history_file" \
    '\b(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+ads\.|DELETE[[:space:]]+FROM|MERGE[[:space:]]+INTO|TRUNCATE[[:space:]]+TABLE)\b' \
    "historico incorporado nao executa DML"
reject_pattern \
    "$history_file" \
    'ads\.(account_balances|credit_ledger)|ads\.(credit_account|confirm_payment_credit|reverse_payment_credit)[[:space:]]*\(' \
    "historico nao faz backfill nem converte saldo legado"
reject_pattern \
    "$history_file" \
    'ads\.(save_event_campaign|activate_campaign|change_campaign_status|reverse_click_debit|replace_campaign_placements)[[:space:]]*\(' \
    "historico nao chama funcoes mutaveis de campanha"
reject_pattern \
    "$history_file" \
    '&lt;|&gt;' \
    "SQL do historico nao usa operadores codificados como entidade HTML"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 LEGACY HISTORY: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PHASE 2 LEGACY HISTORY: PASS\n'
