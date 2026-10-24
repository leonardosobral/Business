#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RR_HIGHLIGHT_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
RR_REFERENCE_ROOT="${2:-/Users/Shared/Projects/RunnerHub/RoadRunners}"
RR_TEST_ROOT="$(mktemp -d /private/tmp/rr-circuit-highlight.XXXXXX)"
mkdir -p "$RR_TEST_ROOT/circuito" "$RR_TEST_ROOT/includes" "$RR_TEST_ROOT/assets/css" "$RR_TEST_ROOT/assets/js"
cp "$RR_HIGHLIGHT_ROOT/_codex/tests/circuit-live-highlight.cfm" "$RR_TEST_ROOT/test.cfm"
cp "$RR_HIGHLIGHT_ROOT/includes/card_evento_live.cfm" "$RR_TEST_ROOT/includes/card_evento_live.cfm"
cp "$RR_HIGHLIGHT_ROOT/assets/js/rr-live-funnel-ui.js" "$RR_TEST_ROOT/assets/js/rr-live-funnel-ui.js"
cp "$RR_REFERENCE_ROOT/assets/css/mdb.min.css" "$RR_TEST_ROOT/assets/css/mdb.min.css"
if [[ -f "$RR_HIGHLIGHT_ROOT/circuito/live_highlight.cfm" ]]; then
    cp "$RR_HIGHLIGHT_ROOT/circuito/live_highlight.cfm" "$RR_TEST_ROOT/circuito/live_highlight.cfm"
else
    # RED baseline: render the current list with the real shared card.
    sed 's@template="card_evento_live.cfm"@template="../includes/card_evento_live.cfm"@' "$RR_REFERENCE_ROOT/includes/lista_de_eventos_live.cfm" > "$RR_TEST_ROOT/circuito/live_highlight.cfm"
fi
RR_COMMAND_BOX_HOME="${RR_COMMAND_BOX_HOME:-/private/tmp/runnerhub-live-funnel-commandbox}"
mkdir -p "$RR_COMMAND_BOX_HOME"
cd "$RR_TEST_ROOT"
RUNNERHUB_OFFLINE_CFML_TESTS=1 /usr/bin/java -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -cp '/Users/Shared/Projects/ColdFusion Certification/box' cliloader.LoaderCLIMain "-CommandBox_home=$RR_COMMAND_BOX_HOME" execute test.cfm
printf '\nRendered fixtures: %s\n' "$RR_TEST_ROOT"
