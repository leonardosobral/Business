#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root" || exit 1

backend="ads/includes/backend.cfm"
home="ads/home.cfm"
campaign_form="ads/includes/workspace_campaign_form.cfm"
failures=0

require_pattern() {
  local label="$1"
  local pattern="$2"
  shift 2

  if rg --quiet --ignore-case --multiline --multiline-dotall --regexp "$pattern" "$@"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

reject_pattern() {
  local label="$1"
  local pattern="$2"
  shift 2

  if rg --quiet --ignore-case --multiline --multiline-dotall --regexp "$pattern" "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  else
    echo "PASS: $label"
  fi
}

require_pattern \
  "readiness exige replace_campaign_placements" \
  'ads\.replace_campaign_placements\(uuid,text\[\],integer,text\)' \
  "$backend"

require_pattern \
  "catalogo limita EVENT aos cinco placements nativos" \
  'rr-home-upcoming-native-secondary.*rr-search-events-native.*rr-state-events-native.*rr-sidebar-event-native' \
  "$backend"

require_pattern \
  "catalogo valida formato NATIVE_EVENT" \
  "format_key[[:space:]]*=[[:space:]]*'NATIVE_EVENT'" \
  "$backend"

require_pattern \
  "leitura agrega todos os placements da campanha" \
  '(string_agg|array_agg)\([[:space:]]*(DISTINCT[[:space:]]+)?pl\.placement_key' \
  "$backend"

require_pattern \
  "backend recebe a lista de placements" \
  'FORM\.placement_keys' \
  "$backend"

require_pattern \
  "backend valida a lista recebida contra a allowlist EVENT" \
  'adsV1SelectableEventPlacementKeys.*listFindNoCase' \
  "$backend"

require_pattern \
  "pagina inicial expande para os dois placements tecnicos" \
  'rr-home-upcoming-native.*arrayAppend\([^)]*rr-home-upcoming-native-secondary' \
  "$backend"

reject_pattern \
  "formulario nao vende primeira e segunda posicao separadamente" \
  'segunda posi[cç][aã]o' \
  "$home" "$campaign_form"

require_pattern \
  "passo quatro explica ranking por regiao e lance" \
  'regi[aã]o.*lance|lance.*regi[aã]o' \
  "$campaign_form"

require_pattern \
  "backend aplica piso de CPC do leilao" \
  'adsV1FormCpc[[:space:]]+LT[[:space:]]+0\.51' \
  "$backend"

reject_pattern \
  "formulario EVENT nao oferece placement de banner" \
  'rr-sidebar-banner-300x250' \
  "$backend" "$home"

require_pattern \
  "save e replace executam na mesma transacao" \
  '<cftransaction>.*ads\.save_event_campaign.*ads\.replace_campaign_placements.*</cftransaction>' \
  "$backend"

require_pattern \
  "replace recebe array PostgreSQL parametrizado" \
  'CAST\([^)]*adsV1FormPlacementArrayLiteral[^)]*AS text\[\]\)' \
  "$backend"

require_pattern \
  "formulario oferece checkboxes de placement" \
  'name="placement_keys"' \
  "$campaign_form"

require_pattern \
  "interface traduz placements atuais para o anunciante" \
  'adsV1Placement(Label|Summary).*placement_keys' \
  "$home" "$campaign_form"

reject_pattern \
  "interface nao anuncia placement fixo" \
  'Placement fixo' \
  "$home" "$campaign_form"

require_pattern \
  "mutacoes permanecem no datasource runnerhub" \
  'datasource="runnerhub"' \
  "$backend"

if (( failures > 0 )); then
  echo "ADS V1 BUSINESS MULTI-PLACEMENT CONTRACT: FAILED ($failures gates)" >&2
  exit 1
fi

echo "ADS V1 BUSINESS MULTI-PLACEMENT CONTRACT: PASSED"
