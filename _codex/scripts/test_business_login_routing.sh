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

    if rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

reject_pattern() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if ! rg -q -i -U --pcre2 -- "$pattern" "$path"; then
        pass "$description"
    else
        fail "$description"
    fi
}

backend="includes/backend/business_google_callback.cfm"

require_pattern \
    "$backend" \
    '(?s)AS[[:space:]]+has_business_access.*?AS[[:space:]]+has_pending_registration' \
    "callback resolve acesso Business e solicitacao pendente"

require_pattern \
    "$backend" \
    '(?s)googleSignInHasBusinessAccess.*?googleSignInHasPendingRegistration.*?googleSignInRedirect[[:space:]]*=[[:space:]]*"/cadastro/"' \
    "usuario sem conta e sem solicitacao segue para cadastro"

require_pattern \
    "$backend" \
    "sol\.status[[:space:]]*=[[:space:]]*'PENDENTE'::status_conta_cadastro_solicitacao" \
    "somente solicitacao pendente bloqueia a entrada"

reject_pattern \
    "includes/backend/backend_login.cfm" \
    'usr\.is_partner[[:space:]]*=[[:space:]]*true[[:space:]]+OR[[:space:]]+EXISTS' \
    "is_partner nao autoriza acesso Business"

reject_pattern \
    "home.cfm" \
    'action=googlesignin&redirect=' \
    "modal da home nao escolhe o destino do login"

reject_pattern \
    "cadastro/home.cfm" \
    'action=googlesignin&redirect=' \
    "cadastro deixa o backend resolver o destino"

if [[ "$failures" -gt 0 ]]; then
    printf '\n%d verificacao(oes) falharam.\n' "$failures" >&2
    exit 1
fi

printf '\nTodas as verificacoes de roteamento do login passaram.\n'
