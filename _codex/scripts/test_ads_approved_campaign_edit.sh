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
campaigns="ads/includes/workspace_campaigns.cfm"
migration="_codex/sql/2026-09-02_ads_prepare_approved_campaign_edit.sql"

require_pattern "$backend" 'adsV1CampaignActions[[:space:]]*=[[:space:]]*"[^"]*prepare_campaign_edit' "preparacao para edicao pertence as acoes protegidas de campanha"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="prepare_campaign_edit">.*?FROM[[:space:]]+ads\.prepare_campaign_for_edit' "backend usa a transicao canonica para preparar a edicao"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="prepare_campaign_edit">.*?<cflocation[^>]+url="\./\?view=campaigns&status=draft&campaign=#[^#]+#&success=campaign-edit-ready##campaign-form"' "pausar e editar abre o rascunho selecionado diretamente no formulario"
require_pattern "$backend" "ads\.prepare_campaign_for_edit\(uuid,bigint,integer\)" "readiness exige a API de preparacao da edicao"
require_pattern "$campaigns" '(?s)adsV1RowReviewStatus[[:space:]]+EQ[[:space:]]+"APPROVED".*?name="ads_v1_action"[[:space:]]+value="prepare_campaign_edit".*?Pausar e editar' "campanha aprovada oferece pausar e editar"
require_pattern "$campaigns" 'ficará fora do ar até uma nova aprovação' "interface explica a consequencia antes da edicao"

require_pattern "$migration" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.prepare_campaign_for_edit' "migration cria transicao atomica de edicao"
require_pattern "$migration" '(?s)FROM[[:space:]]+public\.tb_conta_usuarios.*?OWNER.*?ADMIN.*?OPERADOR.*?FROM[[:space:]]+public\.tb_usuarios.*?is_admin.*?is_dev' "transicao autoriza membro gestor ou admin real"
require_pattern "$migration" "campaign\.status[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\('ACTIVE',[[:space:]]*'PAUSED'\)" "somente campanha ativa ou pausada pode iniciar nova edicao"
require_pattern "$migration" "review\.status[[:space:]]*<>[[:space:]]*'APPROVED'" "somente aprovacao concluida pode ser reaberta"
require_pattern "$migration" "SET[[:space:]]+status[[:space:]]*=[[:space:]]*'DRAFT'" "campanha volta para rascunho antes da edicao"
require_pattern "$migration" '(?s)UPDATE[[:space:]]+ads\.campaign_review_requests.*?SET[[:space:]]+status[[:space:]]*=[[:space:]]*\x27CANCELED\x27' "aprovacao anterior e encerrada"
require_pattern "$migration" 'INSERT[[:space:]]+INTO[[:space:]]+ads\.campaign_status_history' "mudanca de veiculacao fica auditada"
require_pattern "$migration" 'INSERT[[:space:]]+INTO[[:space:]]+ads\.campaign_review_history' "mudanca de revisao fica auditada"
require_pattern "$migration" '(?s)GRANT[[:space:]]+EXECUTE[[:space:]]+ON[[:space:]]+FUNCTION[[:space:]]+ads\.prepare_campaign_for_edit\([^)]+\)[[:space:]]+TO[[:space:]]+ads_business' "datasource pode executar a transicao protegida"

if (( failures > 0 )); then
    printf '\nADS APPROVED CAMPAIGN EDIT: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS APPROVED CAMPAIGN EDIT: PASS\n'
