#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
backend="$project_root/eventos/includes/backend/backend_evento_solicitacoes.cfm"
view="$project_root/eventos/solicitacoes_eventos.cfm"

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    printf 'FAIL: missing accented copy: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_contains "$backend" 'Solicitação enviada. O vínculo ficará pendente até a aprovação.'
assert_contains "$backend" 'Seu usuário não possui uma conta disponível para solicitar vínculos de eventos.'
assert_contains "$backend" 'Solicitação aprovada e evento liberado para a conta.'
assert_contains "$view" 'Solicitar vínculo de evento'
assert_contains "$view" 'Minhas solicitações'
assert_contains "$view" 'Solicitações pendentes'
assert_contains "$view" 'Aprovação libera o evento para a conta.'

printf 'PASS: event request copy uses Portuguese accents.\n'
