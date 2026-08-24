#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cadastro_backend="$project_root/cadastro/includes/backend.cfm"
cadastro_form="$project_root/cadastro/includes/form.cfm"
accounts_backend="$project_root/administracao/contas/includes/backend.cfm"
accounts_view="$project_root/administracao/contas/home.cfm"
events_backend="$project_root/eventos/includes/backend/backend_evento_solicitacoes.cfm"
pending_home="$project_root/includes/estrutura/home_pending_account.cfm"
sidenav="$project_root/includes/estrutura/sidenav.cfm"

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    printf 'FAIL: %s is missing: %s\n' "${file#$project_root/}" "$expected" >&2
    exit 1
  fi
}

assert_absent() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq "$unexpected" "$file"; then
    printf 'FAIL: %s still contains: %s\n' "${file#$project_root/}" "$unexpected" >&2
    exit 1
  fi
}

assert_contains "$cadastro_backend" 'cadastroExistingAccountConfirmed'
assert_contains "$cadastro_backend" '<cfset VARIABLES.cadastroSolicitacaoNomeEmpresa = qCadastroContaDocumentoExistente.nome_conta/>'
assert_contains "$cadastro_form" 'Solicitar acesso a esta conta'
assert_contains "$accounts_backend" 'accountRegistrationRequestedRole'
assert_contains "$accounts_backend" 'ADMIN,OPERADOR,VISUALIZADOR'
assert_contains "$accounts_backend" 'businessAccountsCanReviewExistingRequests'
assert_contains "$accounts_backend" "cu.papel = 'OWNER'::papel_usuario_conta"
assert_contains "$accounts_view" '<option value="OPERADOR" selected>Operador</option>'
assert_contains "$accounts_view" 'Pedido de acesso à conta existente'
assert_absent "$events_backend" '<cfset VARIABLES.eventoSolicitacaoEffectiveAccountIds = trim(VARIABLES.businessPendingRequestAccountId)/>'
assert_absent "$pending_home" '<cfset VARIABLES.businessPendingWorkspaceTargetAccountId = VARIABLES.businessPendingRequestAccountId/>'
assert_contains "$sidenav" 'VARIABLES.businessPendingExistingAccountRequest'
assert_contains "$sidenav" 'Aguardando acesso'

printf 'PASS: existing-account applicants stay permissionless until owner/admin approval.\n'
