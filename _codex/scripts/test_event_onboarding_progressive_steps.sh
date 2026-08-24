#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
template="$project_root/eventos/onboarding_eventos.cfm"

assert_contains() {
  local expected="$1"
  if ! grep -Fq "$expected" "$template"; then
    printf 'FAIL: onboarding template is missing: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_contains '.events-onboarding-step.is-locked'
assert_contains 'VARIABLES.eventosOnboardingStep2Locked'
assert_contains 'VARIABLES.eventosOnboardingStep3Locked'
assert_contains 'aria-disabled="true"'
assert_contains 'NOT len(trim(VARIABLES.eventoSolicitacaoReferencia))'
assert_contains 'VARIABLES.eventoMinhasSolicitacoesPendentes EQ 0'

step_1_line="$(grep -B1 -F '<span class="events-onboarding-number">1</span>' "$template" | head -1)"
step_2_line="$(grep -B1 -F '<span class="events-onboarding-number">2</span>' "$template" | head -1)"
step_3_line="$(grep -B1 -F '<span class="events-onboarding-number">3</span>' "$template" | head -1)"

[[ "$step_1_line" == *'<div class="events-onboarding-step">'* ]] || {
  printf 'FAIL: step 1 must remain active.\n' >&2
  exit 1
}
[[ "$step_2_line" == *'VARIABLES.eventosOnboardingStep2Locked'* ]] || {
  printf 'FAIL: step 2 must use its progressive lock state.\n' >&2
  exit 1
}
[[ "$step_3_line" == *'VARIABLES.eventosOnboardingStep3Locked'* ]] || {
  printf 'FAIL: step 3 must use its progressive lock state.\n' >&2
  exit 1
}

printf 'PASS: event onboarding steps unlock progressively.\n'
