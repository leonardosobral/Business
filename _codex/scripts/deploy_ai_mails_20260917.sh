#!/bin/sh
# Scoped publication. Execute only after candidate compilation; no git actions.
set -eu
stage=/tmp/business-ai-mails-7CIbOpSX/candidate
root=/var/www/business.roadrunners.run
cd "$root"
test "$(sha256sum administracao/agenda/api.cfm | cut -d ' ' -f 1)" = 6385a46974abd355b31d19c7097e58d2f3957867462a300a2002d5d572510c68
test "$(sha256sum administracao/agenda/oauth/callback.cfm | cut -d ' ' -f 1)" = 8bbdf6ea5a3c4e409fbc2c43f30ad6b84857e62b638915f89ce293837b9f5fec
test "$(sha256sum includes/backend/cron_jobs_service.cfm | cut -d ' ' -f 1)" = 54edaaec254c03ccd5c7e2f50d2ca2f4c388823f34695cbe625a4f95e612db38
test "$(sha256sum includes/estrutura/admin_suite_nav.cfm | cut -d ' ' -f 1)" = 5090cd59c6d3e6aae2510fb6c6f1cc438685708fcab702a2cada06bdefc58fe3
test "$(sha256sum assets/css/admin-suite.css | cut -d ' ' -f 1)" = b702b21f562c33e6ffcb79dfe91bb3e785be095922afe1756a73b644640483fc
test "$(sha256sum includes/estrutura/sidenav.cfm | cut -d ' ' -f 1)" = 0befc1e7f789d8400635ee5ee9f3643151a49927a83bec2fa66d5eaf7b99eea7
test "$(sha256sum includes/estrutura/home_admin_dashboard.cfm | cut -d ' ' -f 1)" = 85f284da500d5510b7a1f938488e59d8cd59bea602102c4ebcc4c55f141504e7
test ! -e "$root/administracao/ai-mails"
backup=$(mktemp -d /var/backups/business-ai-mails-20260917-XXXXXXXX)
tar -czf "$backup/runtime-before.tgz" administracao/agenda/api.cfm administracao/agenda/oauth/callback.cfm includes/backend/cron_jobs_service.cfm includes/estrutura/admin_suite_nav.cfm assets/css/admin-suite.css includes/estrutura/sidenav.cfm includes/estrutura/home_admin_dashboard.cfm
cp /tmp/business-ai-mails-7CIbOpSX/candidate.tgz "$backup/candidate.tgz"
echo "Backup recuperável: $backup"
publish() {
    relative=$1
    mkdir -p "$(dirname "$root/$relative")"
    cp "$stage/$relative" "$root/$relative.ai-mails-new"
    chown --reference="$root/administracao/agenda/api.cfm" "$root/$relative.ai-mails-new"
    chmod --reference="$root/administracao/agenda/api.cfm" "$root/$relative.ai-mails-new"
    mv "$root/$relative.ai-mails-new" "$root/$relative"
    cmp "$stage/$relative" "$root/$relative"
}
for relative in administracao/ai-mails/ai_mails_schema.sql administracao/ai-mails/index.cfm administracao/ai-mails/api.cfm administracao/ai-mails/includes/service.cfm administracao/ai-mails/includes/sync.cfm administracao/ai-mails/includes/ai.cfm administracao/ai-mails/jobs/auth.cfm administracao/ai-mails/jobs/collect.cfm administracao/ai-mails/jobs/process.cfm administracao/ai-mails/assets/ai-mails.css administracao/ai-mails/assets/ai-mails.js _codex/tests/ai-mails-service.cfm _codex/ai-mails-verify.cfm; do publish "$relative"; done
curl --fail-with-body -sS -X POST --resolve business.roadrunners.run:443:127.0.0.1 'https://business.roadrunners.run/_codex/ai-mails-verify.cfm?migrate=1'
for relative in administracao/agenda/api.cfm administracao/agenda/oauth/callback.cfm includes/backend/cron_jobs_service.cfm assets/css/admin-suite.css includes/estrutura/admin_suite_nav.cfm includes/estrutura/sidenav.cfm includes/estrutura/home_admin_dashboard.cfm; do publish "$relative"; done
curl --fail-with-body -sS -X POST --resolve business.roadrunners.run:443:127.0.0.1 'https://business.roadrunners.run/_codex/ai-mails-verify.cfm?activate_jobs=1'
echo 'Runtime publicado e testes de banco executados. Validar interface e remover probes.'
