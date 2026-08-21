#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root" || exit 1

backend="ads/canonical/includes/backend.cfm"
home="ads/canonical/includes/home.cfm"
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
  'adsV1AllowedEventPlacementKeys.*listFindNoCase' \
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
  "$home"

require_pattern \
  "listagem mostra placements atuais" \
  'placement_keys' \
  "$home"

reject_pattern \
  "interface nao anuncia placement fixo" \
  'Placement fixo' \
  "$home"

require_pattern \
  "mutacoes permanecem no datasource runnerhub" \
  'datasource="runnerhub"' \
  "$backend"

if (( failures > 0 )); then
  echo "ADS V1 BUSINESS MULTI-PLACEMENT CONTRACT: FAILED ($failures gates)" >&2
  exit 1
fi

echo "ADS V1 BUSINESS MULTI-PLACEMENT CONTRACT: PASSED"
