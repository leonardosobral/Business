#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

require_pattern() {
    local path="$1" pattern="$2" description="$3"
    if [[ -f "$path" ]] && rg -q -i -U --pcre2 -- "$pattern" "$path"; then pass "$description"; else fail "$description"; fi
}

reject_pattern() {
    local path="$1" pattern="$2" description="$3"
    if [[ ! -f "$path" ]] || ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then pass "$description"; else fail "$description"; rg -n -i -U --pcre2 -- "$pattern" "$path" >&2 || true; fi
}

backend="ads/includes/backend.cfm"
form="ads/includes/workspace_campaign_form.cfm"
campaigns="ads/includes/workspace_campaigns.cfm"
access="ads/includes/access.cfm"
admin_home="ads/includes/workspace_admin.cfm"

require_pattern "$backend" 'adsV1CampaignActions[[:space:]]*=[[:space:]]*"save_campaign,submit_campaign_review,change_campaign_status"' "cliente possui salvar, enviar e alterar status operacional"
reject_pattern "$backend" '<cfcase[[:space:]]+value="activate_campaign">' "cliente nao possui endpoint de ativacao"
reject_pattern "$campaigns" 'name="ads_v1_action"[[:space:]]+value="activate_campaign"' "cliente nao possui botao de ativacao"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="submit_campaign_review">.*?FROM[[:space:]]+ads\.submit_campaign_review' "envio chama API de revisao"
require_pattern "$backend" 'FROM[[:space:]]+ads\.save_pending_event_campaign' "conta pendente usa API de salvamento restrita"
require_pattern "$backend" '(?s)ce\.status::text[[:space:]]+IN[[:space:]]*\([^)]*\x27ATIVO\x27.*?\x27PENDENTE\x27' "eventos ativos e pendentes entram na selecao"
require_pattern "$backend" 'req\.id_usuario_solicitante[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1ActorId' "evento pendente pertence ao ator"
require_pattern "$backend" 'review\.status[[:space:]]+AS[[:space:]]+review_status' "campanhas carregam status da revisao"
require_pattern "$backend" 'review\.review_reason' "campanhas carregam motivo da revisao"
require_pattern "$backend" '(?s)qAdsV1CampaignSaveTarget.*?review_status.*?PENDING_REVIEW.*?APPROVED.*?Somente campanhas.*podem ser editadas' "backend impede edicao durante ou depois da aprovacao"
require_pattern "$form" 'Salvar rascunho' "formulario salva rascunho"
require_pattern "$campaigns" 'name="ads_v1_action"[[:space:]]+value="submit_campaign_review"' "lista envia rascunho para analise"
require_pattern "$campaigns" 'WAITING_PREREQUISITES|Aguardando pré-requisitos' "lista mostra pre-requisitos"
require_pattern "$campaigns" 'PENDING_REVIEW|Em análise pela RunnerHub' "lista mostra fila RunnerHub"
require_pattern "$campaigns" 'CHANGES_REQUESTED|Ajustes solicitados' "lista mostra ajustes"
require_pattern "$campaigns" 'review_reason' "lista mostra motivo de ajustes"
require_pattern "$access" '(?s)adsAccessCanReviewCampaign.*?adsAccessRealIsAdmin' "revisao continua restrita a admin real"
require_pattern "$backend" 'adsV1ReviewActions[[:space:]]*=[[:space:]]*"approve_campaign_review,request_campaign_changes,cancel_campaign_review"' "acoes administrativas de revisao sao explicitas"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="approve_campaign_review,request_campaign_changes,cancel_campaign_review">.*?FROM[[:space:]]+ads\.review_campaign' "decisao administrativa usa API canonica"
require_pattern "$backend" 'FROM[[:space:]]+ads\.campaign_review_requests' "fila global carrega solicitacoes de revisao"
require_pattern "$backend" '(?s)adsV1ReviewActions.*?NOT[[:space:]]+VARIABLES\.adsAccessCanReviewCampaign.*?statuscode="403"' "backend bloqueia revisao sem admin real"
require_pattern "$admin_home" 'Campanhas aguardando análise' "admin mostra fila de campanhas"
require_pattern "$admin_home" 'name="review_reason"[^>]*required' "pedido de ajustes exige motivo"
require_pattern "$admin_home" 'value="approve_campaign_review"' "admin pode aprovar campanha"
require_pattern "$admin_home" 'value="request_campaign_changes"' "admin pode solicitar ajustes"
require_pattern "$admin_home" 'value="cancel_campaign_review"' "admin pode cancelar analise"
require_pattern "ads/home.cfm" '(?s)adsAccessCanReviewCampaign.*?view=admin.*?Revisão de anúncios' "admin acessa revisao sem depender de conta selecionada"

if (( failures > 0 )); then
    printf '\nADS PENDING ONBOARDING CAMPAIGNS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PENDING ONBOARDING CAMPAIGNS: PASS\n'
