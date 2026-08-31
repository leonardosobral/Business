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

migration="_codex/sql/2026-08-24_business_pending_registration_reset.sql"
ended_campaign_patch="_codex/sql/2026-08-25_business_pending_registration_reset_ended_campaigns.sql"
backend="administracao/contas/includes/backend.cfm"
home="administracao/contas/home.cfm"

require_pattern "$migration" 'CREATE[[:space:]]+TABLE[[:space:]]+IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+public\.tb_business_pending_reset_audits' "migration cria auditoria persistente"
require_pattern "$migration" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+public\.reset_business_pending_registration' "migration cria API publica transacional"
require_pattern "$migration" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.purge_pending_account_data' "migration isola limpeza ADS no owner correto"
require_pattern "$migration" 'GRANT[[:space:]]+DELETE[[:space:]]+ON[[:space:]]+(TABLE[[:space:]]+)?ads\.tb_ad_vouchers[[:space:]]+TO[[:space:]]+ads_owner' "helper recebe somente o DELETE legado de voucher necessario"
require_pattern "$migration" 'SECURITY[[:space:]]+DEFINER' "funcoes usam privilegio controlado do owner"
require_pattern "$migration" 'actor\.is_admin[[:space:]]+IS[[:space:]]+NOT[[:space:]]+TRUE' "API exige administrador RunnerHub real"
require_pattern "$migration" '(?s)CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.purge_pending_account_data.*?SELECT[[:space:]]+account_info\.\*.*?WHERE[[:space:]]+account_info\.id_conta[[:space:]]*=[[:space:]]*p_account_id[[:space:]]*;' "helper ADS nao exige UPDATE na conta publica ja bloqueada"
require_pattern "$migration" 'registration\.status::text[[:space:]]*<>[[:space:]]*\x27PENDENTE\x27' "API exige solicitacao pendente"
require_pattern "$migration" 'account_record\.status::text[[:space:]]*<>[[:space:]]*\x27PENDENTE\x27' "API exige conta provisoria pendente"
require_pattern "$migration" '(?s)lower\(btrim\(p_expected_email\)\).*?lower\(btrim\(registration\.email_responsavel\)\)' "API confirma e-mail digitado"
require_pattern "$migration" 'length\(btrim\(p_reason\)\)[[:space:]]*<[[:space:]]*5' "API exige motivo util"
require_pattern "$migration" 'payment_intents|credit_ledger|account_financial_holds' "limpeza bloqueia movimentacao financeira"
require_pattern "$migration" 'deliveries|events' "limpeza bloqueia entrega de publicidade"
require_pattern "$migration" 'credit_balance|available_balance|reserved_balance' "limpeza verifica saldo antes de excluir"
require_pattern "$migration" 'campaign\.status[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\([[:space:]]*\x27DRAFT\x27[[:space:]]*,[[:space:]]*\x27ENDED\x27[[:space:]]*\)' "limpeza permite campanha finalizada sem entrega nem gasto"
reject_pattern "$migration" 'campaign\.status[[:space:]]*<>[[:space:]]*\x27DRAFT\x27' "limpeza nao bloqueia toda campanha finalizada"
require_pattern "$ended_campaign_patch" 'CREATE[[:space:]]+OR[[:space:]]+REPLACE[[:space:]]+FUNCTION[[:space:]]+ads\.purge_pending_account_data' "hotfix atualiza instalacoes que ja aplicaram o reset"
require_pattern "$ended_campaign_patch" 'campaign\.status[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\([[:space:]]*\x27DRAFT\x27[[:space:]]*,[[:space:]]*\x27ENDED\x27[[:space:]]*\)' "hotfix aceita apenas rascunho ou finalizada sem entrega"
require_pattern "$ended_campaign_patch" 'deliveries|daily_metrics' "hotfix preserva bloqueio por entrega e metricas"
require_pattern "$ended_campaign_patch" 'payment_intents|credit_ledger|account_financial_holds' "hotfix preserva bloqueio financeiro"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+ads\.campaign_review_history' "limpeza remove historico de revisao do rascunho"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+ads\.campaigns' "limpeza remove campanhas de teste"
require_pattern "$migration" '(?s)voucher\.voucher_scope[[:space:]]*=[[:space:]]*\x27ACCOUNT\x27.*?voucher\.status[[:space:]]*<>[[:space:]]*1' "voucher de conta usado bloqueia reset automatico"
require_pattern "$migration" '(?s)UPDATE[[:space:]]+ads\.tb_ad_vouchers.*?SET[[:space:]]+id_conta[[:space:]]*=[[:space:]]*reservation\.original_account_id' "voucher promocional volta a origem"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+ads\.voucher_reservations' "reserva do voucher e removida"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+public\.tb_conta_evento_solicitacoes' "solicitacoes de evento sao removidas"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+public\.tb_conta_usuarios' "vinculos Business sao removidos"
require_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+public\.tb_contas' "conta provisoria e removida"
reject_pattern "$migration" 'DELETE[[:space:]]+FROM[[:space:]]+public\.tb_usuarios' "usuario global nunca e excluido"
require_pattern "$migration" 'INSERT[[:space:]]+INTO[[:space:]]+public\.tb_business_pending_reset_audits' "resultado da limpeza e auditado"
require_pattern "$migration" '(?s)REVOKE[[:space:]]+ALL.*?reset_business_pending_registration.*?FROM[[:space:]]+PUBLIC' "API nao fica publica para qualquer role"
require_pattern "$migration" '(?s)GRANT[[:space:]]+EXECUTE.*?reset_business_pending_registration.*?TO[[:space:]]+runner' "somente app chama a API publica"

require_pattern "$backend" 'account_pending_reset_action' "backend possui action exclusiva de reset"
require_pattern "$backend" 'NOT[[:space:]]+VARIABLES\.businessAccountsCanAdminAll' "backend exige admin global fora de simulacao"
require_pattern "$backend" 'business_account_access_csrf' "backend valida CSRF existente"
require_pattern "$backend" 'FROM[[:space:]]+public\.reset_business_pending_registration' "backend chama somente a API transacional"
require_pattern "$backend" 'datasource="runnerhub"' "backend usa o datasource correto"
reject_pattern "$backend" '(?s)BEGIN BUSINESS PENDING RESET.*?DELETE[[:space:]]+FROM.*?END BUSINESS PENDING RESET' "backend nao executa limpeza parcial por DML"

require_pattern "$home" 'Eliminar solicitação e dados de teste' "admin recebe acao explicita de eliminacao"
require_pattern "$home" 'VARIABLES\.businessAccountsCanAdminAll.*status_conta[[:space:]]+EQ[[:space:]]+"PENDENTE"' "botao aparece somente para admin e conta pendente"
require_pattern "$home" 'name="account_pending_reset_email"' "confirmacao exige digitar o e-mail"
require_pattern "$home" 'name="account_pending_reset_reason"[^>]+required' "motivo e obrigatorio no formulario"
require_pattern "$home" 'name="business_account_access_csrf"' "formulario envia CSRF"

if (( failures > 0 )); then
    printf '\nBUSINESS PENDING RESET: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nBUSINESS PENDING RESET: PASS\n'
