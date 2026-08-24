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
    if [[ ! -f "$path" ]] || ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
        rg -n -i -U --pcre2 -- "$pattern" "$path" >&2 || true
    fi
}

login="includes/backend/backend_login.cfm"
context="includes/backend/business_account_context.cfm"
access="ads/includes/access.cfm"
backend="ads/includes/backend.cfm"
home="ads/home.cfm"

require_pattern "$login" 'businessPendingExistingAccountRequest[[:space:]]*\?[[:space:]]*"/,/faq/,/suporte/"[[:space:]]*:[[:space:]]*"/,/eventos/,/ads/,/faq/,/suporte/"' "somente conta nova pendente recebe a rota ads"
require_pattern "$context" 'businessPendingAccountId' "contexto preserva id da conta provisoria"
require_pattern "$context" 'businessPendingRegistrationId' "contexto preserva id da solicitacao"
require_pattern "$context" 'cont\.status[[:space:]]*=[[:space:]]*\x27PENDENTE\x27::status_conta' "contexto pendente nao vira conta ativa"
require_pattern "$access" 'adsAccessIsPendingNewAccount' "acesso distingue conta nova pendente"
require_pattern "$access" 'businessPendingExistingAccountRequest' "pedido em conta existente participa do gate"
require_pattern "$access" 'adsAccessRegistrationId' "acesso transporta solicitacao server-side"
require_pattern "$access" 'adsAccessCanReserveVoucher' "reserva possui capacidade propria"
require_pattern "$access" 'adsAccessCanPrepareCampaign' "campanha pendente possui capacidade propria"
require_pattern "$access" 'adsAccessCanReviewCampaign[[:space:]]*=[[:space:]]*VARIABLES\.adsAccessHasActor[[:space:]]+AND[[:space:]]+VARIABLES\.adsAccessRealIsAdmin' "revisao exige admin RunnerHub real"
reject_pattern "$access" 'adsAccessCanActivateCampaign[[:space:]]*=[^;]*(adsAccessIsPendingNewAccount|businessPendingWorkspace)' "conta pendente nunca recebe ativacao"
require_pattern "$backend" 'qAdsV1PendingAuthorization' "backend revalida autorizacao provisoria"
require_pattern "$backend" 'registration\.id_solicitacao[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsAccessRegistrationId' "revalidacao usa solicitacao derivada"
require_pattern "$backend" 'registration\.id_usuario[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsV1ActorId' "revalidacao usa ator autenticado"
require_pattern "$backend" 'membership\.papel[[:space:]]*=[[:space:]]*\x27OWNER\x27::papel_usuario_conta' "revalidacao exige OWNER"
require_pattern "$backend" 'account\.status[[:space:]]*=[[:space:]]*\x27PENDENTE\x27::status_conta' "revalidacao exige conta pendente"
require_pattern "$backend" '<cfheader[[:space:]]+statuscode="403"' "falha de escopo retorna 403"
require_pattern "$backend" 'adsV1VoucherActions[[:space:]]*=[[:space:]]*"redeem_voucher,reserve_voucher"' "resgate e reserva possuem actions separadas"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="reserve_voucher">.*?FROM[[:space:]]+ads\.reserve_voucher' "reserva chama API transacional"
require_pattern "$backend" 'qAdsV1VoucherReservation' "backend carrega reserva da solicitacao"
require_pattern "$backend" '(?s)<cfcase[[:space:]]+value="save_campaign">.*?<cflocation[^>]+url="\./\?view=campaigns&amp;status=draft&amp;success=campaign-saved"' "salvar campanha abre imediatamente a lista de rascunhos"
require_pattern "$home" '<cfparam[[:space:]]+name="URL\.status"[[:space:]]+default=""' "ausencia de filtro pode escolher a categoria mais util"
require_pattern "$home" '(?s)adsV1CampaignFilter[[:space:]]*=[[:space:]]*VARIABLES\.adsV1OngoingCount[[:space:]]+EQ[[:space:]]+0[[:space:]]+AND[[:space:]]+VARIABLES\.adsV1DraftCount[[:space:]]+GT[[:space:]]+0[[:space:]]*\?[[:space:]]*"draft"' "sem campanha em andamento a tela destaca rascunhos existentes"
require_pattern "$backend" 'reservation\.id_solicitacao_cadastro[[:space:]]*=[[:space:]]*<cfqueryparam[^>]+adsAccessRegistrationId' "leitura da reserva usa solicitacao derivada"
reject_pattern "$backend" '<cfcase[[:space:]]+value="reserve_voucher">.*?ads\.(credit_account|redeem_voucher)' "reserva nao credita saldo"
require_pattern "ads/includes/payments_home.cfm" 'name="ads_v1_action"[[:space:]]+value="reserve_voucher"' "formulario pendente envia reserva"
require_pattern "ads/includes/payments_home.cfm" 'Voucher reservado' "painel mostra voucher reservado"
require_pattern "ads/includes/payments_home.cfm" 'O crédito será aplicado automaticamente quando a conta for aprovada' "painel explica quando o credito entra"

if (( failures > 0 )); then
    printf '\nADS PENDING ONBOARDING ACCESS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PENDING ONBOARDING ACCESS: PASS\n'
