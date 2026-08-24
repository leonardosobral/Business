#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ -f "$path" ]] && rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

reject_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if [[ ! -f "$path" ]] || ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
        rg -n -i -U --pcre2 -- "$pattern" "$path" >&2 || true
    fi
}

schema="_codex/sql/2026-08-24_ads_pending_onboarding.sql"

require_pattern "$schema" 'CREATE[[:space:]]+TABLE[[:space:]]+IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+ads\.voucher_reservations' "reservas possuem tabela propria"
require_pattern "$schema" 'CHECK[[:space:]]*\([^)]*RESERVED[^)]*APPLIED[^)]*RELEASED[^)]*EXPIRED' "status de reserva e fechado"
require_pattern "$schema" 'CREATE[[:space:]]+UNIQUE[[:space:]]+INDEX[^;]*id_ad_voucher[^;]*WHERE[^;]*status[[:space:]]*=[[:space:]]*\x27RESERVED\x27' "voucher tem uma reserva ativa"
require_pattern "$schema" 'CREATE[[:space:]]+UNIQUE[[:space:]]+INDEX[^;]*id_solicitacao_cadastro[^;]*WHERE[^;]*status[[:space:]]*=[[:space:]]*\x27RESERVED\x27' "solicitacao tem uma reserva ativa"
require_pattern "$schema" 'CREATE[[:space:]]+TABLE[[:space:]]+IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+ads\.campaign_review_requests' "revisoes possuem tabela propria"
require_pattern "$schema" 'CHECK[[:space:]]*\([^)]*WAITING_PREREQUISITES[^)]*PENDING_REVIEW[^)]*CHANGES_REQUESTED[^)]*APPROVED[^)]*CANCELED' "status de revisao e fechado"
require_pattern "$schema" 'CREATE[[:space:]]+TABLE[[:space:]]+IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+ads\.campaign_review_history' "historico de revisao existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.reserve_voucher\([^)]*p_account_id[[:space:]]+bigint[^)]*p_registration_id[[:space:]]+bigint[^)]*p_code[[:space:]]+text[^)]*p_actor_id[[:space:]]+integer' "reserva atomica existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.apply_voucher_reservation\([^)]*p_registration_id[[:space:]]+bigint[^)]*p_actor_id[[:space:]]+integer' "aplicacao idempotente existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.release_voucher_reservation\([^)]*p_registration_id[[:space:]]+bigint[^)]*p_actor_id[[:space:]]+integer[^)]*p_reason[[:space:]]+text' "liberacao auditavel existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.save_pending_event_campaign\(' "salvamento pendente possui API restrita"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.submit_campaign_review\([^)]*p_campaign_id[[:space:]]+uuid[^)]*p_account_id[[:space:]]+bigint[^)]*p_actor_id[[:space:]]+integer[^)]*p_core_event_id[[:space:]]+integer' "envio de revisao existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.refresh_campaign_review_prerequisites\([^)]*p_account_id[[:space:]]+bigint[^)]*p_core_event_id[[:space:]]+integer[^)]*p_actor_id[[:space:]]+integer' "reavaliacao auditavel de pre-requisitos existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.cancel_open_campaign_reviews\([^)]*p_account_id[[:space:]]+bigint[^)]*p_actor_id[[:space:]]+integer[^)]*p_reason[[:space:]]+text' "cancelamento em lote existe"
require_pattern "$schema" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.review_campaign\([^)]*p_campaign_id[[:space:]]+uuid[^)]*p_action[[:space:]]+text[^)]*p_actor_id[[:space:]]+integer[^)]*p_reason[[:space:]]+text[^)]*p_idempotency_key[[:space:]]+text' "decisao administrativa existe"
require_pattern "$schema" 'FOR[[:space:]]+UPDATE' "funcoes bloqueiam linhas concorrentes"
require_pattern "$schema" 'ads\.redeem_voucher[[:space:]]*\(' "aplicacao reutiliza o ledger canonico"
require_pattern "$schema" 'ads\.activate_campaign[[:space:]]*\(' "aprovacao reutiliza ativacao canonica"
require_pattern "$schema" 'GRANT[[:space:]]+SELECT,[[:space:]]*INSERT[^;]*campaign_review_history' "historico permite apenas leitura e append"
reject_pattern "$schema" 'UPDATE[[:space:]]+ads\.campaign_review_history' "historico nao e alterado"
reject_pattern "$schema" 'DELETE[[:space:]]+FROM[[:space:]]+ads\.campaign_review_history' "historico nao e apagado"
reject_pattern "$schema" 'GRANT[^;]*(UPDATE|DELETE)[^;]*campaign_review_history' "historico nao concede alteracao"

if (( failures > 0 )); then
    printf '\nADS PENDING ONBOARDING SCHEMA: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PENDING ONBOARDING SCHEMA: PASS\n'
