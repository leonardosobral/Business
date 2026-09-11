#!/usr/bin/env bash
set -euo pipefail
business_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
auth_test_root="$(mktemp -d /private/tmp/business-remember-test.XXXXXX)"
auth_pg_bin="${BUSINESS_AUTH_PG_BIN:-/opt/homebrew/opt/postgresql@16/bin}"
auth_box="${BUSINESS_AUTH_BOX:-/Users/Shared/Projects/ColdFusion Certification/box}"
auth_box_home="${BUSINESS_AUTH_BOX_HOME:-/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox}"
auth_port="${BUSINESS_AUTH_TEST_PORT:-55439}"
cleanup() {
    "$auth_pg_bin/pg_ctl" -D "$auth_test_root/db" -m fast stop >/dev/null 2>&1 || true
}
trap cleanup EXIT
"$auth_pg_bin/initdb" -D "$auth_test_root/db" -U business_auth_test -A trust --no-locale >/dev/null
"$auth_pg_bin/pg_ctl" -D "$auth_test_root/db" -l "$auth_test_root/postgres.log" -o "-h 127.0.0.1 -p $auth_port -k $auth_test_root" start >/dev/null
"$auth_pg_bin/createdb" -h 127.0.0.1 -p "$auth_port" -U business_auth_test business_auth_test
mkdir -p "$auth_test_root/app/_codex/tests" "$auth_test_root/app/_codex/sql" "$auth_test_root/app/services"
cp "$business_root/_codex/tests/business-remember-device.cfm" "$auth_test_root/app/_codex/tests/"
cp "$business_root/_codex/tests/business-auth-boundary.cfm" "$business_root/_codex/tests/business-auth-security.cfm" "$auth_test_root/app/_codex/tests/"
mkdir -p "$auth_test_root/app/bi" "$auth_test_root/app/includes/backend" "$auth_test_root/app/cadastro/includes"
cp "$business_root/Application.cfc" "$business_root/logout.cfm" "$auth_test_root/app/"
cp "$business_root/bi/Application.cfc" "$auth_test_root/app/bi/"
cp "$business_root/cadastro/includes/backend.cfm" "$auth_test_root/app/cadastro/includes/"
cp "$business_root/services/BusinessAuthSession.cfc" "$business_root/services/GoogleIdentityVerifier.cfc" "$auth_test_root/app/services/"
cp "$business_root/includes/backend/business_request_identity.cfm" "$business_root/includes/backend/business_google_callback.cfm" "$auth_test_root/app/includes/backend/"
cp "$business_root/includes/backend/"business_remember_*.cfm "$auth_test_root/app/includes/backend/"
if [[ -f "$business_root/services/BusinessRememberDevice.cfc" ]]; then
    cp "$business_root/services/BusinessRememberDevice.cfc" "$auth_test_root/app/services/"
    cp "$business_root/_codex/sql/2026-09-09_business_remember_devices.sql" "$auth_test_root/app/_codex/sql/"
fi
cd "$auth_test_root/app"
RUNNERHUB_OFFLINE_CFML_TESTS=1 BUSINESS_AUTH_TEST_PORT="$auth_port" /usr/bin/java \
    -cp "$auth_box" cliloader.LoaderCLIMain "-CommandBox_home=$auth_box_home" \
    execute _codex/tests/business-remember-device.cfm
for auth_test in business-auth-boundary business-auth-security; do
    RUNNERHUB_OFFLINE_CFML_TESTS=1 BUSINESS_AUTH_TEST_PORT="$auth_port" JOSE4J_TEST_JAR="${JOSE4J_TEST_JAR:?Set JOSE4J_TEST_JAR to the installed jose4j jar}" /usr/bin/java \
        -cp "$auth_box" cliloader.LoaderCLIMain "-CommandBox_home=$auth_box_home" \
        execute "_codex/tests/$auth_test.cfm"
done
