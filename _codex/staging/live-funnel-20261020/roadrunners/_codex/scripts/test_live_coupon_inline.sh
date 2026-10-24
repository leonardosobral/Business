#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RR_INLINE_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
RR_REFERENCE_ROOT="${2:-/Users/Shared/Projects/RunnerHub/RoadRunners}"
RR_TEST_ROOT="$(mktemp -d /private/tmp/rr-live-coupon.XXXXXX)"
mkdir -p "$RR_TEST_ROOT/evento/parts" "$RR_TEST_ROOT/assets/css" "$RR_TEST_ROOT/assets/js"
cp "$RR_INLINE_ROOT/_codex/tests/live-coupon-inline.cfm" "$RR_TEST_ROOT/test.cfm"
cp "$RR_INLINE_ROOT/evento/parts/live_coupon.cfm" "$RR_TEST_ROOT/evento/parts/live_coupon.cfm"
cp "$RR_INLINE_ROOT/assets/js/rr-live-funnel-ui.js" "$RR_TEST_ROOT/assets/js/rr-live-funnel-ui.js"
cp "$RR_REFERENCE_ROOT/assets/css/mdb.min.css" "$RR_TEST_ROOT/assets/css/mdb.min.css"
RR_COMMAND_BOX_HOME="${RR_COMMAND_BOX_HOME:-/private/tmp/runnerhub-live-funnel-commandbox}"
mkdir -p "$RR_COMMAND_BOX_HOME"
cd "$RR_TEST_ROOT"
RUNNERHUB_OFFLINE_CFML_TESTS=1 /usr/bin/java -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -cp '/Users/Shared/Projects/ColdFusion Certification/box' cliloader.LoaderCLIMain "-CommandBox_home=$RR_COMMAND_BOX_HOME" execute test.cfm
printf '\nRendered fixture: %s\n' "$RR_TEST_ROOT"
