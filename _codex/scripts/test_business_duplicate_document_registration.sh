#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
backend="$project_root/cadastro/includes/backend.cfm"

assert_contains() {
  local expected="$1"
  if ! grep -Fq "$expected" "$backend"; then
    printf 'FAIL: cadastro backend is missing: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_absent() {
  local unexpected="$1"
  if grep -Fq "$unexpected" "$backend"; then
    printf 'FAIL: cadastro backend still contains: %s\n' "$unexpected" >&2
    exit 1
  fi
}

assert_contains 'qCadastroContaDocumentoExistente'
assert_contains 'cadastroExistingAccountConfirmationRequired'
assert_contains 'confirmar_conta_existente'
assert_contains 'cadastroExistingAccountName'
assert_contains '<cfset VARIABLES.cadastroContaId = qCadastroContaDocumentoExistente.id_conta/>'
assert_absent 'Use outro documento para criar uma nova conta'

printf 'PASS: duplicate documents require explicit confirmation before requesting access.\n'
