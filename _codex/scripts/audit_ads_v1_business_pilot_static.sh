#!/usr/bin/env bash

# Nome preservado para compatibilidade com checklists antigos. O antigo piloto
# foi promovido ao painel unico /ads/ e nao possui mais implementacao propria em
# /ads/canonical/.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }
require_file() { [[ -f "$1" ]] && pass "arquivo presente: $1" || fail "arquivo ausente: $1"; }
require_pattern() {
  if [[ -e "$2" ]] && rg -q -i -U --pcre2 -- "$1" "$2"; then pass "$3"; else fail "$3"; fi
}
reject_pattern() {
  if [[ ! -e "$2" ]] || ! rg -q -i -U --pcre2 -- "$1" "$2"; then pass "$3"; else fail "$3"; fi
}

require_file "ads/index.cfm"
require_file "ads/home.cfm"
require_file "ads/includes/backend.cfm"
require_file "ads/canonical/index.cfm"
require_file "ads/includes/access.cfm"

require_pattern 'cflocation[^\n]*url="/ads/' \
  "ads/canonical/index.cfm" \
  "rota canonica antiga redireciona ao painel unico"
reject_pattern 'canonical/includes/(backend|home)\.cfm' \
  "ads" \
  "nao existe segunda implementacao canonica"
reject_pattern 'datasource[[:space:]]*=[[:space:]]*"runner_dba"' \
  "ads" \
  "Publicidade nao usa o datasource runner_dba"
require_pattern 'datasource[[:space:]]*=[[:space:]]*"runnerhub"' \
  "ads/includes/backend.cfm" \
  "backend unico usa o datasource runnerhub"

for function_name in \
  save_event_campaign \
  activate_campaign \
  change_campaign_status \
  credit_account \
  reverse_click_debit
do
  require_pattern "ads\\.${function_name}" \
    "ads/includes/backend.cfm" \
    "backend chama ads.${function_name}"
done

reject_pattern '(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' \
  "ads" \
  "painel nao executa DML direto em tabelas canonicas"
reject_pattern 'URL\.(ads_v1_action|acao)' \
  "ads/includes/backend.cfm" \
  "painel nao aceita mutacao por URL/GET"
require_pattern 'FORM\.ads_v1_action' \
  "ads/includes/backend.cfm" \
  "backend despacha acoes POST"
require_pattern 'FORM\.ads_v1_csrf' \
  "ads/includes/backend.cfm" \
  "backend valida CSRF"
require_pattern 'method[[:space:]]*=[[:space:]]*"post"' \
  "ads/home.cfm" \
  "interface possui formularios POST"
require_pattern 'name[[:space:]]*=[[:space:]]*"ads_v1_csrf"' \
  "ads/home.cfm" \
  "formularios enviam CSRF"
require_pattern 'htmlEditFormat' \
  "ads/home.cfm" \
  "interface escapa conteudo dinamico"

require_pattern 'campaign\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam|c\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/includes/backend.cfm" \
  "campanhas sao filtradas pela conta efetiva"
require_pattern 'ledger\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/includes/backend.cfm" \
  "ledger e filtrado pela conta efetiva"
require_pattern 'event_account\.id_conta[[:space:]]*=[[:space:]]*<cfqueryparam|ce\.id_conta[[:space:]]*=[[:space:]]*<cfqueryparam' \
  "ads/includes/backend.cfm" \
  "eventos sao filtrados pela conta efetiva"

reject_pattern 'public\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' \
  "ads" \
  "objetos canonicos nao dependem do schema public"
reject_pattern '(FROM|JOIN|INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)\b' \
  "ads" \
  "objetos canonicos nao aparecem sem schema"
reject_pattern 'current_schema[[:space:]]*\(' \
  "ads" \
  "painel nao usa current_schema para objetos Ads"

for suite in \
  "_codex/scripts/test_ads_phase2_business_routes.sh" \
  "_codex/scripts/test_ads_phase2_business_access.sh"
do
  if bash "$suite" >/dev/null 2>&1; then
    pass "suite consolidada aprovada: $(basename "$suite")"
  else
    fail "suite consolidada falhou: $(basename "$suite")"
  fi
done

if (( failures > 0 )); then
  printf '\nADS V1 BUSINESS CONSOLIDATED STATIC AUDIT: FAIL (%d)\n' "$failures" >&2
  exit 1
fi

printf '\nADS V1 BUSINESS CONSOLIDATED STATIC AUDIT: PASS\n'
