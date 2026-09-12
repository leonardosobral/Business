#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RR_HIGHLIGHT_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
RR_REFERENCE_ROOT="${2:-/Users/Shared/Projects/RunnerHub/RoadRunners}"
RR_TEST_ROOT="$(mktemp -d /private/tmp/rr-circuit-highlight.XXXXXX)"
mkdir -p "$RR_TEST_ROOT/circuito" "$RR_TEST_ROOT/includes" "$RR_TEST_ROOT/assets/css"
cp "$RR_HIGHLIGHT_ROOT/_codex/tests/circuit-live-highlight.cfm" "$RR_TEST_ROOT/test.cfm"
cp "$RR_REFERENCE_ROOT/includes/card_evento_live.cfm" "$RR_TEST_ROOT/includes/card_evento_live.cfm"
cp "$RR_REFERENCE_ROOT/assets/css/mdb.min.css" "$RR_TEST_ROOT/assets/css/mdb.min.css"
if [[ -f "$RR_HIGHLIGHT_ROOT/circuito/live_highlight.cfm" ]]; then
    cp "$RR_HIGHLIGHT_ROOT/circuito/live_highlight.cfm" "$RR_TEST_ROOT/circuito/live_highlight.cfm"
else
    # RED baseline: render the current list with the real shared card.
    sed 's@template="card_evento_live.cfm"@template="../includes/card_evento_live.cfm"@' "$RR_REFERENCE_ROOT/includes/lista_de_eventos_live.cfm" > "$RR_TEST_ROOT/circuito/live_highlight.cfm"
fi
cd "$RR_TEST_ROOT"
RUNNERHUB_OFFLINE_CFML_TESTS=1 /usr/bin/java -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -cp '/Users/Shared/Projects/ColdFusion Certification/box' cliloader.LoaderCLIMain '-CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox' execute test.cfm
printf '\nRendered fixtures: %s\n' "$RR_TEST_ROOT"
