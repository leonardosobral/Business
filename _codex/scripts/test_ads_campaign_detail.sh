#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

require_pattern() {
    local path="$1" pattern="$2" description="$3"
    if [[ -f "$path" ]] && rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

backend="ads/includes/backend.cfm"
home="ads/home.cfm"
campaigns="ads/includes/workspace_campaigns.cfm"
detail="ads/includes/workspace_campaign_detail.cfm"
performance="ads/includes/workspace_performance.cfm"

require_pattern "$home" 'overview,campaigns,campaign-detail,payments' "rota individual faz parte das visoes permitidas"
require_pattern "$home" '(?s)adsV1WorkspaceView[[:space:]]+EQ[[:space:]]+"campaign-detail".*?workspace_campaign_detail\.cfm' "home renderiza o detalhe individual"
require_pattern "$campaigns" 'view=campaign-detail&amp;campaign=' "cada campanha oferece acesso ao proprio desempenho"
require_pattern "$backend" 'qAdsV1CampaignPerformanceDaily' "backend carrega serie diaria individual"
require_pattern "$backend" '(?s)qAdsV1CampaignPerformanceDaily.*?FROM[[:space:]]+ads\.daily_metrics[[:space:]]+metric.*?metric\.campaign_id[[:space:]]*=.*?adsV1SelectedCampaignId.*?metric\.account_id[[:space:]]*=.*?adsV1AccountId' "serie individual exige campanha e conta ativa"
require_pattern "$backend" 'qAdsV1CampaignPerformanceComparison' "backend compara o periodo individual ao anterior"
require_pattern "$backend" '(?s)qAdsV1CampaignStatusHistory.*?history\.campaign_id[[:space:]]*=.*?adsV1SelectedCampaignId.*?history\.account_id[[:space:]]*=.*?adsV1AccountId' "historico individual exige campanha e conta ativa"
require_pattern "$performance" 'adsV1PerformanceContext EQ "campaign"' "painel compartilhado reconhece campanha individual"
require_pattern "$performance" 'view=campaign-detail.*?campaign=' "filtro de periodo preserva a campanha"
require_pattern "$performance" 'Desempenho da campanha' "detalhe identifica claramente o relatorio"
require_pattern "$detail" 'Orçamento restante' "detalhe mostra quanto ainda pode ser investido"
require_pattern "$detail" 'Segmentação' "detalhe mostra o publico configurado"
require_pattern "$detail" 'Locais de exibição' "detalhe mostra onde o anuncio aparece"
require_pattern "$detail" 'Histórico da campanha' "detalhe mostra mudancas operacionais"

if (( failures > 0 )); then
    printf '\nADS CAMPAIGN DETAIL: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS CAMPAIGN DETAIL: PASS\n'
