#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
migration="$root_dir/_codex/sql/2026-08-24_ads_global_vouchers.sql"
pending_migration="$root_dir/_codex/sql/2026-08-24_ads_pending_onboarding.sql"
permission_fix="$root_dir/_codex/sql/2026-08-24_ads_voucher_reservation_permission_fix.sql"
backend="$root_dir/ads/includes/backend.cfm"
access="$root_dir/ads/includes/access.cfm"
workspace="$root_dir/ads/includes/workspace_admin_vouchers.cfm"
admin_workspace="$root_dir/ads/includes/workspace_admin.cfm"
home="$root_dir/ads/home.cfm"
account_home="$root_dir/administracao/contas/home.cfm"

failures=0

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if [[ ! -f "$file" ]] || ! grep -Eiq "$pattern" "$file"; then
    printf 'FAIL: %s\n' "$label"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

require_pattern "$migration" 'ADD COLUMN IF NOT EXISTS voucher_scope' 'migration adiciona escopo persistente'
require_pattern "$migration" "voucher_scope IN \('PROMOTIONAL', 'ACCOUNT'\)" 'escopo aceita apenas promocional ou conta'
require_pattern "$migration" "voucher_scope <> 'ACCOUNT' OR id_conta IS NOT NULL" 'voucher de conta exige conta'
require_pattern "$migration" 'p_scope_type text' 'API explicita recebe o tipo do voucher'
require_pattern "$migration" "normalized_scope = 'PROMOTIONAL'.*p_account_id IS NOT NULL|p_account_id IS NOT NULL.*normalized_scope = 'PROMOTIONAL'" 'promocional nasce sem conta'
require_pattern "$migration" "voucher\.voucher_scope = 'ACCOUNT'.*voucher\.id_conta IS DISTINCT FROM p_account_id|voucher\.id_conta IS DISTINCT FROM p_account_id.*voucher\.voucher_scope = 'ACCOUNT'" 'reserva rejeita voucher de outra conta'
require_pattern "$migration" "voucher\.voucher_scope = 'PROMOTIONAL'.*voucher\.id_conta IS NULL|voucher\.id_conta IS NULL.*voucher\.voucher_scope = 'PROMOTIONAL'" 'promocional e vinculado atomicamente no primeiro uso'
require_pattern "$pending_migration" 'uq_ads_voucher_reservations_open_voucher' 'reserva concorrente continua exclusiva'
require_pattern "$pending_migration" 'SET id_conta = reservation\.original_account_id' 'liberacao devolve promocional ao estado sem conta'
require_pattern "$migration" 'REVOKE ALL ON FUNCTION ads\.create_voucher' 'nova API nao fica publica'
require_pattern "$migration" 'GRANT EXECUTE ON FUNCTION ads\.create_voucher' 'aplicacao recebe apenas execucao controlada'
require_pattern "$migration" 'GRANT SELECT, UPDATE ON TABLE[[:space:]]+public\.tb_conta_cadastro_solicitacoes[[:space:]]+TO ads_owner' 'owner da API pode ler e atualizar a solicitacao pendente'
require_pattern "$migration" 'GRANT SELECT ON TABLE[[:space:]]+public\.tb_conta_usuarios[[:space:]]+TO ads_owner' 'owner da API pode validar o OWNER provisorio'
require_pattern "$permission_fix" 'GRANT SELECT ON TABLE[[:space:]]+public\.tb_conta_evento_solicitacoes[[:space:]]+TO ads_owner' 'owner da API pode validar a solicitacao pendente do evento'

require_pattern "$access" 'adsAccessCanAdminVouchers' 'acesso possui capacidade global de vouchers'
require_pattern "$backend" 'create_admin_voucher' 'backend possui acao global de criacao'
require_pattern "$backend" 'adsAccessCanAdminVouchers' 'backend exige administrador real'
require_pattern "$backend" 'value="#VARIABLES\.adsV1AdminVoucherScope#"' 'backend chama API com escopo explicito'
require_pattern "$backend" 'qAdsV1AdminVouchers' 'backend carrega lista global de vouchers'
require_pattern "$backend" 'qAdsV1AdminVoucherAccounts' 'backend carrega contas para voucher restrito'

require_pattern "$workspace" 'Voucher promocional' 'tela global oferece voucher promocional'
require_pattern "$workspace" 'Voucher de conta' 'tela global oferece voucher de conta'
require_pattern "$workspace" 'name="voucher_scope"' 'formulario envia escopo explicito'
require_pattern "$workspace" 'name="voucher_account_id"' 'formulario permite escolher a conta restrita'
require_pattern "$workspace" 'create_admin_voucher' 'formulario usa a acao administrativa'
require_pattern "$workspace" 'qAdsV1AdminVouchers' 'tela exibe a lista global'
require_pattern "$home" 'listFindNoCase\("[^"]*,vouchers", VARIABLES\.adsV1WorkspaceView\)' 'vouchers possuem rota propria na lista de rotas aceitas'
require_pattern "$home" 'view=vouchers' 'navegacao abre a tela global de vouchers'
require_pattern "$home" 'workspace_admin_vouchers\.cfm' 'rota de vouchers carrega seu componente'
if grep -Eiq 'workspace_admin_vouchers\.cfm' "$admin_workspace"; then
  printf 'FAIL: vouchers nao ficam misturados com revisao de anuncios\n'
  failures=$((failures + 1))
else
  printf 'PASS: vouchers nao ficam misturados com revisao de anuncios\n'
fi

require_pattern "$account_home" 'Voucher restrito a esta conta' 'tela antiga explica o escopo restrito'

if (( failures > 0 )); then
  printf '\nADS GLOBAL VOUCHERS: %d falha(s)\n' "$failures"
  exit 1
fi

printf '\nADS GLOBAL VOUCHERS: PASS\n'
