#!/usr/bin/env bash
set -euo pipefail

rr_root="${1:-/Users/Shared/Projects/RunnerHub/RoadRunners}"
ads_test_root="$(mktemp -d /private/tmp/rr-ads-request-test.XXXXXX)"
mkdir -p "$ads_test_root/services" "$ads_test_root/includes/ads_v1" "$ads_test_root/config"
mkdir -p "$ads_test_root/production/services" "$ads_test_root/production/config" "$ads_test_root/beta/services" "$ads_test_root/beta/config"
cp "$rr_root/services/AdsV1ConfigService.cfc" "$ads_test_root/services/"
cp "$rr_root/services/AdsV1ConfigService.cfc" "$ads_test_root/production/services/"
cp "$rr_root/services/AdsV1ConfigService.cfc" "$ads_test_root/beta/services/"
cp "$rr_root/includes/ads_v1/runtime_config.cfm" "$ads_test_root/includes/ads_v1/"
cp "$rr_root/_codex/tests/ads-request-config-contract.cfm" "$ads_test_root/"
cp -R "$rr_root/_codex/tests/ads-request-config-fixtures" "$ads_test_root/fixtures"
cp "$ads_test_root/fixtures/request-site.cfm" "$ads_test_root/config/ads.local.cfm"
cp "$ads_test_root/fixtures/production.cfm" "$ads_test_root/production/config/ads.local.cfm"
cd "$ads_test_root"
RUNNERHUB_OFFLINE_CFML_TESTS=1 /usr/bin/java \
    -cp '/Users/Shared/Projects/ColdFusion Certification/box' \
    cliloader.LoaderCLIMain \
    -CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox \
    execute ads-request-config-contract.cfm
