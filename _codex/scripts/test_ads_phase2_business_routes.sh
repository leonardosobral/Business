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

is_candidate_file() {
    local path="$1"
    [[ -f "$path" ]]
}

require_file() {
    local path="$1"
    local description="$2"

    if [[ -f "$path" ]] && is_candidate_file "$path"; then
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

reject_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ ! -e "$path" ]] || ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
        rg -n -i -U --pcre2 -- "$pattern" "$path" >&2 || true
    fi
}

reject_pattern_many() {
    local pattern="$1"
    local description="$2"
    shift 2

    if ! rg -q -i -U --pcre2 -- "$pattern" "$@"; then
        pass "$description"
    else
        fail "$description"
        rg -n -i -U --pcre2 -- "$pattern" "$@" >&2 || true
    fi
}

require_file "ads/index.cfm" "painel principal existe em /ads/"
require_file "ads/includes/backend.cfm" "backend principal de publicidade existe"
require_file "ads/home.cfm" "home principal de publicidade existe"
require_file "ads/canonical/index.cfm" "rota canonical de compatibilidade existe"
require_file "ads/legacy/index.cfm" "rota legacy existe"
require_file "ads/legacy/includes/backend.cfm" "backend legacy existe"
require_file "ads/legacy/includes/home.cfm" "home legacy existe"

require_pattern \
    "ads/index.cfm" \
    '<cfset[[:space:]]+VARIABLES\.template[[:space:]]*=[[:space:]]*"/ads/"' \
    "painel principal usa o template /ads/"
require_pattern \
    "ads/index.cfm" \
    '<cfinclude[[:space:]]+template="includes/backend\.cfm"' \
    "painel principal carrega o backend promovido"
require_pattern \
    "ads/index.cfm" \
    '<cfinclude[[:space:]]+template="home\.cfm"' \
    "painel principal carrega a home promovida"
for function_name in \
    save_event_campaign \
    replace_campaign_placements \
    submit_campaign_review \
    change_campaign_status \
    credit_account \
    reverse_click_debit
do
    require_pattern \
        "ads/includes/backend.cfm" \
        "FROM[[:space:]]+ads\\.${function_name}[[:space:]]*\\(" \
        "backend principal preserva ads.${function_name}"
done
reject_pattern \
    "ads/includes/backend.cfm" \
    'FROM[[:space:]]+ads\.activate_campaign[[:space:]]*\(' \
    "backend principal nao permite ativacao direta pelo cliente"
require_pattern \
    "ads/includes/backend.cfm" \
    'datasource[[:space:]]*=[[:space:]]*"runnerhub"' \
    "backend principal preserva datasource runnerhub"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)<cfinclude[[:space:]]+template="access\.cfm".*?adsV1AccountId[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessAccountId' \
    "backend principal usa a conta efetiva derivada pelo include de acesso"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)if[[:space:]]+compare\(trim\(FORM\.ads_v1_csrf.*?VARIABLES\.adsV1Csrf\)[[:space:]]+NEQ[[:space:]]+0.*?<cfthrow.*?</cfif>.*?<cfswitch' \
    "backend principal rejeita CSRF invalido"
require_pattern \
    "ads/includes/backend.cfm" \
    '(?s)<cfif[[:space:]]+NOT[[:space:]]+VARIABLES\.adsV1CanMutate.*?adsV1ReviewActions.*?adsV1CanReviewMutate.*?<cfthrow' \
    "backend principal aplica o gate de mutacao com excecao administrativa explicita"
require_pattern \
    "ads/includes/backend.cfm" \
    'c\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' \
    "queries de campanha aplicam a conta ativa"
require_pattern \
    "ads/includes/backend.cfm" \
    "(?s)cont\.id_conta[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId.*?cont\.status::text[[:space:]]*=[[:space:]]*'ATIVA'.*?<cfif[[:space:]]+NOT[[:space:]]+qAdsV1Account\.recordcount>.*?adsV1HasAccount[[:space:]]*=[[:space:]]*false.*?adsV1CanMutate[[:space:]]*=[[:space:]]*false" \
    "conta inativa desliga o gate de mutacao"

backend_query_count="$(rg -i -o '<cfquery\b' ads/includes/backend.cfm | wc -l | tr -d ' ')"
backend_runnerhub_query_count="$(rg -i -o '<cfquery\b[^>]*datasource[[:space:]]*=[[:space:]]*"runnerhub"' ads/includes/backend.cfm | wc -l | tr -d ' ')"
if [[ "$backend_query_count" -gt 0 && "$backend_query_count" -eq "$backend_runnerhub_query_count" ]]; then
    pass "todas as queries do backend principal usam runnerhub"
else
    fail "todas as queries do backend principal usam runnerhub (queries=$backend_query_count runnerhub=$backend_runnerhub_query_count)"
fi
reject_pattern \
    "ads/includes/backend.cfm" \
    'adsV1CanMutate[[:space:]]*=[^;]*(businessRealIsAdmin|qPerfil\.is_admin)' \
    "painel principal nao exige administrador interno para operar"

common_ui=(
    "ads/index.cfm"
    "ads/home.cfm"
    "ads/includes/backend.cfm"
    "includes/estrutura/sidenav.cfm"
    "includes/estrutura/home_conta_dashboard.cfm"
    "includes/estrutura/home_admin_dashboard.cfm"
)

reject_pattern_many \
    '/ads/canonical/' \
    "experiencia comum nao aponta para /ads/canonical/" \
    "${common_ui[@]}"
reject_pattern \
    "ads/home.cfm" \
    "[\"'][^\"']*(Ads[[:space:]]+V1|piloto|can[oô]nic[oa]s?|Turbinad[oa]s?)[^\"']*[\"']|>[^<]*(Ads[[:space:]]+V1|piloto|can[oô]nic[oa]s?|Turbinad[oa]s?)[^<]*<" \
    "home comum nao exibe rotulos aposentados"
reject_pattern \
    "ads/includes/backend.cfm" \
    "[\"'][^\"']*(Ads[[:space:]]+V1|piloto|Turbinad[oa]s?|[[:space:]]can[oô]nic[oa]s?)[^\"']*[\"']" \
    "mensagens do backend comum nao exibem rotulos aposentados"
require_pattern \
    "ads/home.cfm" \
    '<h1[^>]*>Publicidade</h1>|<h[1-6][^>]*>Publicidade</h[1-6]>' \
    "painel principal tem titulo Publicidade"
require_pattern \
    "ads/home.cfm" \
    'href="\./\?view=campaigns(?:&amp;mode=new)?#campaign-form"[^>]*>[^<]*(Nova campanha|Criar campanha)' \
    "painel principal oferece CTA de nova campanha"

require_pattern \
    "ads/canonical/index.cfm" \
    '<cflocation[^>]+url="/ads/"' \
    "canonical redireciona para /ads/"
reject_pattern \
    "ads/canonical/index.cfm" \
    '<!DOCTYPE|<html|<body|<cfinclude|<form|<cfquery' \
    "canonical contem somente redirect"
if find ads/canonical/includes -type f -print -quit 2>/dev/null | rg -q '.'; then
    fail "canonical nao conserva uma segunda implementacao"
else
    pass "canonical nao conserva uma segunda implementacao"
fi

require_pattern \
    "ads/legacy/index.cfm" \
    '(?s)<cfif[[:space:]]+NOT[[:space:]]+isDefined\("VARIABLES\.businessRealIsAdmin"\)[[:space:]]+OR[[:space:]]+NOT[[:space:]]+VARIABLES\.businessRealIsAdmin>.*?<cfheader[[:space:]]+statuscode="403".*?<cfabort.*?</cfif>.*?<cfinclude[[:space:]]+template="includes/backend\.cfm"' \
    "legacy nega e aborta acesso sem administrador interno real"
require_pattern \
    "ads/legacy/includes/backend.cfm" \
    '(?s)isDefined\("qPerfil\.id"\).*?adsLegacyRealUserId[[:space:]]*=[[:space:]]*val\(qPerfil\.id\)' \
    "legacy deriva o usuario real autenticado"
require_pattern \
    "ads/legacy/includes/backend.cfm" \
    'datasource[[:space:]]*=[[:space:]]*"runnerhub"' \
    "legacy consulta o datasource runnerhub"
require_pattern \
    "ads/legacy/includes/backend.cfm" \
    '(FROM|JOIN)[[:space:]]+ads\.' \
    "legacy consulta dados historicos de ads"
reject_pattern \
    "ads/legacy" \
    "<form\\b|method[[:space:]]*=[[:space:]]*[\"']?(post|put|patch|delete)|\\bFORM\\.|URL\\.(acao|action|status|campanha)|<cftransaction\\b" \
    "legacy nao contem forms nem acoes mutaveis"
reject_pattern \
    "ads/legacy" \
    '\b(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM|MERGE[[:space:]]+INTO|TRUNCATE[[:space:]]+TABLE)\b' \
    "legacy nao contem DML"
reject_pattern \
    "ads/legacy" \
    'ads\.(save_event_campaign|activate_campaign|change_campaign_status|credit_account|reverse_click_debit|replace_campaign_placements)[[:space:]]*\(' \
    "legacy nao chama funcoes mutaveis"
reject_pattern \
    "ads/legacy/includes/home.cfm" \
    "href[[:space:]]*=[[:space:]]*[\"'][^\"']*\\?(acao|action|status|campanha|voucher|credito)=" \
    "legacy nao oferece links GET de acao"

require_pattern \
    "includes/estrutura/sidenav.cfm" \
    'href="/ads/"[^>]*>[[:space:]]*(?:<i[^>]*></i>)?[[:space:]]*<span>Publicidade</span>' \
    "sidenav aponta para /ads/ com rotulo Publicidade"
require_pattern \
    "includes/estrutura/home_conta_dashboard.cfm" \
    'href="/ads/"[^>]*>[^<]*(Publicidade|Nova campanha)' \
    "dashboard da conta usa CTA Publicidade/Nova campanha para /ads/"
require_pattern \
    "includes/estrutura/home_admin_dashboard.cfm" \
    'href="/ads/"[^>]*>[^<]*Publicidade' \
    "dashboard admin aponta para /ads/ com rotulo Publicidade"
reject_pattern_many \
    'href="/ads/"[^>]*>[^<]*(Ads|Turbinad)' \
    "navegacao e dashboards nao destacam nomes antigos" \
    "includes/estrutura/sidenav.cfm" \
    "includes/estrutura/home_conta_dashboard.cfm" \
    "includes/estrutura/home_admin_dashboard.cfm"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 BUSINESS ROUTES: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PHASE 2 BUSINESS ROUTES: PASS\n'
