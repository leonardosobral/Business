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

require_count() {
    local path="$1" pattern="$2" minimum="$3" description="$4" count
    count=$(rg -o -i -U --pcre2 -- "$pattern" "$path" 2>/dev/null | wc -l | tr -d ' ')
    if (( count >= minimum )); then pass "$description"; else fail "$description (encontrado $count, esperado ao menos $minimum)"; fi
}

accounts_backend="administracao/contas/includes/backend.cfm"
accounts_home="administracao/contas/home.cfm"
events_backend="eventos/includes/backend/backend_evento_solicitacoes.cfm"
existing_account_reassignment="_codex/sql/2026-08-25_business_registration_existing_account_reassignment.sql"

require_pattern "$accounts_backend" '(?s)accountRegistrationAction[[:space:]]+EQ[[:space:]]+"aprovar".*?NOT[[:space:]]+VARIABLES\.accountRegistrationIsExistingAccessRequest.*?FROM[[:space:]]+ads\.apply_voucher_reservation' "aprovacao de conta nova aplica a reserva"
require_pattern "$accounts_backend" '(?s)accountRegistrationAction[[:space:]]+EQ[[:space:]]+"recusar".*?accountRegistrationIsProvisionalAccount.*?FROM[[:space:]]+ads\.release_voucher_reservation' "recusa de conta nova libera a reserva"
require_pattern "$accounts_backend" '(?s)accountRegistrationAction[[:space:]]+EQ[[:space:]]+"recusar".*?accountRegistrationIsProvisionalAccount.*?SELECT[[:space:]]+ads\.cancel_open_campaign_reviews' "recusa de conta nova cancela revisoes abertas"
require_pattern "$accounts_backend" 'SELECT[[:space:]]+ads\.refresh_campaign_review_prerequisites' "aprovacao da conta reavalia campanhas"
require_pattern "$accounts_backend" '(?s)NOT[[:space:]]+VARIABLES\.accountRegistrationIsExistingAccessRequest.*?accountRegistrationTargetAccountId[[:space:]]*=[[:space:]]*qBusinessAccountRegistrationReview\.id_conta' "conta nova usa a conta provisoria da solicitacao"
require_pattern "$accounts_backend" '(?s)accountRegistrationIsProvisionalAccount.*?len\(VARIABLES\.accountRegistrationExistingAccountId\).*?FROM[[:space:]]+public\.reassign_business_pending_registration.*?accountRegistrationTargetAccountId[[:space:]]*=[[:space:]]*VARIABLES\.accountRegistrationExistingAccountId' "selecao administrativa substitui a conta provisoria"
reject_pattern "$accounts_backend" 'len\(VARIABLES\.accountRegistrationExistingAccountId\)[[:space:]]+AND[[:space:]]+NOT[[:space:]]+len\(VARIABLES\.accountRegistrationTargetAccountId\)' "conta provisoria nao bloqueia a selecao administrativa"
require_pattern "$accounts_backend" '(?s)accountRegistrationUsesExistingAccount.*?accountRegistrationMembershipRole[[:space:]]*=[[:space:]]*VARIABLES\.accountRegistrationRequestedRole' "usuario recebe papel de acesso na conta escolhida"
require_pattern "$accounts_backend" '(?s)NOT[[:space:]]+VARIABLES\.accountRegistrationUsesExistingAccount.*?UPDATE[[:space:]]+tb_contas.*?SET[[:space:]]+status[[:space:]]*=[[:space:]]*\x27ATIVA\x27' "somente conta nova e ativada pela aprovacao"
require_pattern "$accounts_backend" '(?s)qBusinessAccountRegistrationAccountOptions(?:(?!</cfquery>).)*?FROM[[:space:]]+tb_contas(?:(?!</cfquery>).)*?WHERE[[:space:]]+status[[:space:]]*=[[:space:]]*\x27ATIVA\x27::status_conta' "seletor oferece somente contas ativas"
require_pattern "$accounts_home" 'Papel se associar à conta existente' "administrador escolhe o papel na conta existente"
reject_pattern "$accounts_backend" 'accountRegistrationTargetAccountId[[:space:]]*=[[:space:]]*qBusinessAccountRegistrationVoucher\.id_conta' "voucher nunca escolhe a conta de destino"
require_pattern "$accounts_backend" '(?s)<cfif[[:space:]]+NOT[[:space:]]+VARIABLES\.accountRegistrationIsExistingAccessRequest>.*?FROM[[:space:]]+ads\.apply_voucher_reservation.*?</cfif>' "acesso a conta existente nao aplica voucher"

require_pattern "$existing_account_reassignment" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+public\.reassign_business_pending_registration' "migration cria transferencia transacional da solicitacao"
require_pattern "$existing_account_reassignment" '(?s)actor\.is_admin[[:space:]]+IS[[:space:]]+NOT[[:space:]]+TRUE.*?RAISE[[:space:]]+EXCEPTION' "transferencia exige administrador RunnerHub"
require_pattern "$existing_account_reassignment" '(?s)source_account\.status::text[[:space:]]+<>[[:space:]]+\x27PENDENTE\x27.*?target_account\.status::text[[:space:]]+<>[[:space:]]+\x27ATIVA\x27' "transferencia valida origem provisoria e destino ativo"
require_pattern "$existing_account_reassignment" '(?s)UPDATE[[:space:]]+ads\.voucher_reservations.*?SET[[:space:]]+id_conta[[:space:]]*=[[:space:]]*p_target_account_id' "voucher reservado acompanha a conta escolhida"
require_pattern "$existing_account_reassignment" '(?s)UPDATE[[:space:]]+ads\.campaigns.*?SET[[:space:]]+account_id[[:space:]]*=[[:space:]]*p_target_account_id' "rascunhos de publicidade acompanham a conta escolhida"
require_pattern "$existing_account_reassignment" '(?s)UPDATE[[:space:]]+public\.tb_conta_evento_solicitacoes.*?SET[[:space:]]+id_conta[[:space:]]*=[[:space:]]*p_target_account_id' "solicitacoes de evento acompanham a conta escolhida"
require_pattern "$existing_account_reassignment" '(?s)DELETE[[:space:]]+FROM[[:space:]]+public\.tb_contas.*?id_conta[[:space:]]*=[[:space:]]*source_account\.id_conta' "conta provisoria e eliminada depois da transferencia"
require_pattern "$existing_account_reassignment" '(?s)GRANT[[:space:]]+EXECUTE.*?public\.reassign_business_pending_registration.*?TO[[:space:]]+runner' "aplicacao executa somente a API protegida"

require_count "$events_backend" 'SELECT[[:space:]]+ads\.refresh_campaign_review_prerequisites' 2 "aprovacao e recusa do evento reavaliam campanhas"
require_pattern "$events_backend" '(?s)evento_solicitacao_action[[:space:]]+EQ[[:space:]]+"aprovar".*?ads\.refresh_campaign_review_prerequisites' "evento aprovado avanca a revisao"
require_pattern "$events_backend" '(?s)status[[:space:]]*=[[:space:]]*\x27INATIVO\x27::status_conta_evento.*?ads\.refresh_campaign_review_prerequisites' "evento negado devolve a revisao"

if (( failures > 0 )); then
    printf '\nADS PENDING ONBOARDING APPROVALS: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PENDING ONBOARDING APPROVALS: PASS\n'
