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

reject_pattern() {
    local path="$1" pattern="$2" description="$3"
    if [[ -f "$path" ]] && ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

campaigns="ads/includes/workspace_campaigns.cfm"
home="ads/home.cfm"

require_pattern "$campaigns" '<div class="col-12">' "visao geral usa toda a largura disponivel"
reject_pattern "$campaigns" 'col-xl-9' "visao geral nao volta a dividir espaco com uma lateral"
reject_pattern "$campaigns" 'Próximos passos' "acoes redundantes nao comprimem mais a tabela"
require_pattern "$campaigns" 'ads-campaign-table--overview' "tabela resumida tem identidade visual propria"
require_pattern "$campaigns" '(?s)adsV1WorkspaceView EQ "overview".*?<th>Campanha</th>.*?<th>Status</th>.*?<th>Investimento</th>.*?<th>Resultados</th>' "resumo apresenta quatro grupos legiveis"
require_pattern "$campaigns" 'ads-campaign-result-grid' "impressoes cliques CTR e CPC ficam agrupados em resultados"
require_pattern "$campaigns" 'ads-campaign-performance-link' "resumo oferece acesso explicito ao desempenho individual"
require_pattern "$campaigns" '(?s)<cfelseif VARIABLES\.adsV1WorkspaceView EQ "campaigns">[[:space:]]*<tr><th>Campanha</th><th>Status</th><th>Investimento</th><th>Resultados</th><th class="text-end">Ações</th></tr>' "gerenciamento aproxima os dados em cinco grupos"
require_pattern "$campaigns" 'ads-campaign-result-grid--management' "gerenciamento agrupa impressoes cliques CTR e CPC"
require_pattern "$campaigns" 'ads-campaign-actions' "acoes da campanha ficam juntas e sem quebra"
require_pattern "$campaigns" '(?s)adsV1PlacementCountSummary\(qAdsV1Campaigns\.placement_keys\).*?Ver desempenho' "linha resume os locais e mantem acesso ao detalhe"
reject_pattern "$campaigns" 'adsV1PlacementSummary\(qAdsV1Campaigns\.placement_keys\)' "gerenciamento nao alonga a linha com todos os nomes dos locais"
require_pattern "$home" 'ads-campaign-title' "titulos longos recebem tratamento responsivo"
require_pattern "$home" '-webkit-line-clamp:[[:space:]]*2' "titulo fica limitado a duas linhas no resumo"
require_pattern "$home" '(?s)ads-campaign-table--management.*?table-layout:[[:space:]]*fixed.*?th:nth-child\(1\).*?width:[[:space:]]*30%' "gerenciamento reserva largura suficiente para a campanha"
require_pattern "$home" 'ads-campaign-actions[^}]*white-space:[[:space:]]*nowrap' "botoes de acao nao quebram em varias linhas"

if (( failures > 0 )); then
    printf '\nADS OVERVIEW COMPACT CAMPAIGNS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS OVERVIEW COMPACT CAMPAIGNS: PASS\n'
