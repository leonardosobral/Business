#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROADRUNNERS_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
COMMANDBOX_HOME="${2:-${AUDIENCE_CFML_COMMANDBOX_HOME:-/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox}}"
BOX_RUNTIME="${3:-${AUDIENCE_CFML_BOX_RUNTIME:-/Users/Shared/Projects/ColdFusion Certification/box}}"
JAVA_RUNTIME="${AUDIENCE_CFML_JAVA_RUNTIME:-/usr/bin/java}"
TEST_FILE="${ROADRUNNERS_ROOT}/_codex/tests/audience-live-contract.cfm"
SERVICE_FILE="${ROADRUNNERS_ROOT}/services/AudienceMeasurementService.cfc"

for required_file in "${TEST_FILE}" "${SERVICE_FILE}" "${BOX_RUNTIME}" "${JAVA_RUNTIME}" "${COMMANDBOX_HOME}/lib/lucee-5.3.10.120.jar"; do
    [[ -f "${required_file}" ]] || { echo "ERRO: arquivo necessario ausente: ${required_file}" >&2; exit 2; }
done

TEST_ROOT="$(mktemp -d /private/tmp/runnerhub-audience-live-cfml.XXXXXX)"
cleanup_test_root() {
    case "${TEST_ROOT}" in /private/tmp/runnerhub-audience-live-cfml.*) rm -rf -- "${TEST_ROOT}" ;; esac
}
trap cleanup_test_root EXIT HUP INT TERM
mkdir -p "${TEST_ROOT}/services"
cp "${TEST_FILE}" "${TEST_ROOT}/audience-live-contract.cfm"
cp "${SERVICE_FILE}" "${TEST_ROOT}/services/AudienceMeasurementService.cfc"
cd "${TEST_ROOT}"
RUNNERHUB_OFFLINE_CFML_TESTS=1 "${JAVA_RUNTIME}" -cp "${BOX_RUNTIME}" cliloader.LoaderCLIMain "-CommandBox_home=${COMMANDBOX_HOME}" execute audience-live-contract.cfm
