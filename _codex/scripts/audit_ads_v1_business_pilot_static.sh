#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

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
  if [[ -f "$path" ]]; then
    pass "arquivo presente: $path"
  else
    fail "arquivo ausente: $path"
  fi
}

require_pattern() {
  local pattern="$1"
  local path="$2"
  local description="$3"
  if [[ -e "$path" ]] && rg -q -U --pcre2 "$pattern" "$path"; then
    pass "$description"
  else
    fail "$description"
  fi
}

reject_pattern() {
  local pattern="$1"
  local path="$2"
  local description="$3"
  if [[ ! -e "$path" ]] || ! rg -n -U --pcre2 "$pattern" "$path" >/dev/null; then
    pass "$description"
  else
    fail "$description"
    rg -n -U --pcre2 "$pattern" "$path" >&2 || true
  fi
}

require_file "ads/canonical/index.cfm"
require_file "ads/canonical/includes/backend.cfm"
require_file "ads/canonical/includes/home.cfm"

reject_pattern 'datasource\s*=\s*"runner_dba"' \
  "ads/canonical" \
  "piloto nao usa o datasource runner_dba"
require_pattern 'datasource\s*=\s*"runnerhub"' \
  "ads/canonical/includes/backend.cfm" \
  "backend usa o datasource runnerhub"

for function_name in \
  save_event_campaign \
  activate_campaign \
  change_campaign_status \
  credit_account \
  reverse_click_debit
do
  require_pattern "SELECT[[:space:]]+\\*[[:space:]]+FROM[[:space:]]+ads\\.${function_name}" \
    "ads/canonical/includes/backend.cfm" \
    "backend chama ads.${function_name}"
done

reject_pattern '(?i)(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' \
  "ads/canonical" \
  "piloto nao executa DML direto em tabelas canonicas"
reject_pattern '(?i)URL\.(ads_v1_action|acao)' \
  "ads/canonical" \
  "piloto nao aceita mutacao por URL/GET"

require_pattern 'FORM\.ads_v1_action' \
  "ads/canonical/includes/backend.cfm" \
  "backend despacha somente acoes POST"
require_pattern 'FORM\.ads_v1_csrf' \
  "ads/canonical/includes/backend.cfm" \
  "backend valida token CSRF"
require_pattern 'compare\(trim\(FORM\.ads_v1_csrf' \
  "ads/canonical/includes/backend.cfm" \
  "backend compara CSRF da sessao"

require_pattern '(?s)function[[:space:]]+adsV1NewIdempotencyToken\([^)]*\)[[:space:]]*\{.*?replace\(createUUID\(\),[[:space:]]*"-",[[:space:]]*"",[[:space:]]*"all"\)' \
  "ads/canonical/includes/backend.cfm" \
  "tokens de idempotencia removem os separadores do UUID do ColdFusion"
require_pattern '(?s)function[[:space:]]+adsV1IsIdempotencyToken\([^)]*\)[[:space:]]*\{.*?\{32\}' \
  "ads/canonical/includes/backend.cfm" \
  "tokens de idempotencia exigem 32 caracteres hexadecimais"
require_pattern 'adsV1CreditPrefix\)[[:space:]]*\+[[:space:]]*32' \
  "ads/canonical/includes/backend.cfm" \
  "credito valida o tamanho do token normalizado"
require_pattern 'adsV1ReversalPrefix\)[[:space:]]*\+[[:space:]]*32' \
  "ads/canonical/includes/backend.cfm" \
  "estorno valida o tamanho do token normalizado"
require_pattern 'business:click-reversal:.*adsV1NewIdempotencyToken\(\)' \
  "ads/canonical/includes/home.cfm" \
  "estorno gera token de idempotencia normalizado"
reject_pattern 'business:(manual-credit|click-reversal):[^\r\n]*createUUID\(\)' \
  "ads/canonical" \
  "formularios nao concatenam createUUID sem normalizacao"

require_pattern 'c\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/canonical/includes/backend.cfm" \
  "campanhas sao filtradas pela conta efetiva"
require_pattern 'ledger\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/canonical/includes/backend.cfm" \
  "ledger e filtrado pela conta efetiva"
require_pattern 'ce\.id_conta[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/canonical/includes/backend.cfm" \
  "eventos sao filtrados pela conta efetiva"

require_pattern 'method\s*=\s*"post"' \
  "ads/canonical/includes/home.cfm" \
  "interface possui formularios POST"
require_pattern 'name\s*=\s*"ads_v1_csrf"' \
  "ads/canonical/includes/home.cfm" \
  "formularios enviam token CSRF"
require_pattern 'htmlEditFormat' \
  "ads/canonical/includes/home.cfm" \
  "interface escapa conteudo dinamico"

if [[ -f "ads/canonical/includes/home.cfm" ]]; then
  post_form_count="$(rg -io 'method\s*=\s*"post"' ads/canonical/includes/home.cfm | wc -l | tr -d ' ')"
  csrf_field_count="$(rg -io 'name\s*=\s*"ads_v1_csrf"' ads/canonical/includes/home.cfm | wc -l | tr -d ' ')"
  if [[ "$post_form_count" -gt 0 && "$post_form_count" -eq "$csrf_field_count" ]]; then
    pass "cada formulario POST possui um campo CSRF"
  else
    fail "formularios POST=$post_form_count e campos CSRF=$csrf_field_count"
  fi
fi

if [[ -f "ads/canonical/includes/backend.cfm" ]]; then
  query_count="$(rg -io '<cfquery\b' ads/canonical/includes/backend.cfm | wc -l | tr -d ' ')"
  runnerhub_query_count="$(rg -io '<cfquery\b[^>]*datasource\s*=\s*"runnerhub"' ads/canonical/includes/backend.cfm | wc -l | tr -d ' ')"
  if [[ "$query_count" -gt 0 && "$query_count" -eq "$runnerhub_query_count" ]]; then
    pass "todas as queries do piloto usam runnerhub"
  else
    fail "queries totais=$query_count e queries runnerhub=$runnerhub_query_count"
  fi
fi

reject_pattern '(?i)public\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' \
  "ads/canonical" \
  "objetos canonicos nao dependem do schema public"
reject_pattern '(?i)(FROM|JOIN|INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)\b' \
  "ads/canonical" \
  "objetos canonicos nao aparecem sem schema"
reject_pattern '(?i)current_schema[[:space:]]*\(' \
  "ads/canonical" \
  "piloto nao usa current_schema para descobrir objetos"
require_pattern '/ads/canonical/' \
  "ads/home.cfm" \
  "Turbinado legado oferece acesso ao piloto"

if (( failures > 0 )); then
  printf '\nADS V1 BUSINESS PILOT STATIC AUDIT: FAIL (%d)\n' "$failures" >&2
  exit 1
fi

printf '\nADS V1 BUSINESS PILOT STATIC AUDIT: PASS\n'
