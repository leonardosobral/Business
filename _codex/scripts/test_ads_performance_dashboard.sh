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
performance="ads/includes/workspace_performance.cfm"
campaigns="ads/includes/workspace_campaigns.cfm"
admin="ads/includes/workspace_admin.cfm"

require_pattern "$backend" 'qAdsV1AccountPerformanceDaily' "backend carrega serie diaria da conta"
require_pattern "$backend" '(?s)qAdsV1AccountPerformanceDaily.*?FROM[[:space:]]+ads\.daily_metrics[[:space:]]+metric.*?metric\.account_id[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1AccountId' "serie do cliente fica isolada pela conta efetiva"
require_pattern "$backend" '(?s)qAdsV1AccountPerformanceComparison.*?metric_date.*?current_date' "cliente compara o periodo atual ao anterior"
require_pattern "$backend" 'URL\.ads_campaign' "backend recebe filtro opcional de campanha"
require_pattern "$backend" '(?s)qAdsV1AccountPerformanceDaily.*?metric\.campaign_id[[:space:]]*=.*?adsV1PerformanceCampaignId' "serie da conta aplica campanha selecionada"
require_pattern "$backend" '(?s)qAdsV1AccountPerformanceComparison.*?metric\.campaign_id[[:space:]]*=.*?adsV1PerformanceCampaignId' "comparativo aplica a mesma campanha selecionada"
require_pattern "$backend" 'qAdsV1AdminPerformanceDaily' "admin carrega serie global"
require_pattern "$backend" '(?s)qAdsV1AdminPerformanceDaily.*?FROM[[:space:]]+ads\.daily_metrics' "serie administrativa usa metricas canonicas"
require_pattern "$performance" 'Impressões' "painel mostra impressoes"
require_pattern "$performance" 'Taxa de cliques|CTR' "painel mostra CTR"
require_pattern "$performance" 'CPC médio|CPC real' "painel mostra CPC realizado"
require_pattern "$performance" 'Investimento' "painel mostra investimento"
require_pattern "$performance" 'data-ads-performance-chart' "painel possui grafico temporal"
require_pattern "$performance" 'Últimos 7 dias' "painel permite periodo de 7 dias"
require_pattern "$performance" 'Últimos 30 dias' "painel permite periodo de 30 dias"
require_pattern "$performance" 'Todas as campanhas' "visao geral permite voltar ao consolidado"
require_pattern "$performance" 'name="ads_campaign"' "visao geral oferece seletor de campanha"
require_pattern "$performance" '(?s)adsV1PerformanceCampaignQuery.*?ads_campaign=.*?ads_period=7<cfoutput>#VARIABLES\.adsV1PerformanceCampaignQuery#' "troca de periodo preserva campanha selecionada"
require_pattern "$home" '(?s)adsV1WorkspaceView[[:space:]]+EQ[[:space:]]+"overview".*?workspace_performance\.cfm' "visao geral da conta inclui performance"
require_pattern "$admin" 'workspace_performance\.cfm' "visao global do admin inclui performance"
require_pattern "$campaigns" 'CTR' "lista de campanhas mostra CTR"
require_pattern "$campaigns" 'CPC médio|CPC real' "lista de campanhas mostra CPC realizado"
require_pattern "$admin" 'CTR' "lista operacional do admin mostra CTR"
require_pattern "$admin" 'CPC médio|CPC real' "lista operacional do admin mostra CPC realizado"

if (( failures > 0 )); then
    printf '\nADS PERFORMANCE DASHBOARD: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PERFORMANCE DASHBOARD: PASS\n'
