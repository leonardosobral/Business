#!/bin/sh
set -eu
stage=/tmp/business-ai-mails-7CIbOpSX/candidate
root=/var/www/business.roadrunners.run
backup=/var/backups/business-ai-mails-20260917-ZLvsHtup
mkdir -p "$backup/baseline"
tar -xzf "$backup/runtime-before.tgz" -C "$backup/baseline"
for relative in administracao/agenda/api.cfm administracao/agenda/oauth/callback.cfm includes/backend/cron_jobs_service.cfm includes/estrutura/admin_suite_nav.cfm assets/css/admin-suite.css includes/estrutura/sidenav.cfm includes/estrutura/home_admin_dashboard.cfm; do cmp "$backup/baseline/$relative" "$root/$relative"; done
cp /tmp/business-ai-mails-7CIbOpSX/candidate.tgz "$backup/candidate-final.tgz"
for relative in administracao/ai-mails/ai_mails_schema.sql administracao/ai-mails/index.cfm administracao/ai-mails/api.cfm administracao/ai-mails/includes/service.cfm administracao/ai-mails/includes/sync.cfm administracao/ai-mails/includes/ai.cfm administracao/ai-mails/jobs/auth.cfm administracao/ai-mails/jobs/collect.cfm administracao/ai-mails/jobs/process.cfm administracao/ai-mails/assets/ai-mails.css administracao/ai-mails/assets/ai-mails.js administracao/agenda/api.cfm administracao/agenda/oauth/callback.cfm includes/backend/cron_jobs_service.cfm assets/css/admin-suite.css includes/estrutura/admin_suite_nav.cfm includes/estrutura/sidenav.cfm includes/estrutura/home_admin_dashboard.cfm; do
    cp "$stage/$relative" "$root/$relative.ai-mails-new"
    chown --reference="$root/administracao/agenda/api.cfm" "$root/$relative.ai-mails-new"
    chmod --reference="$root/administracao/agenda/api.cfm" "$root/$relative.ai-mails-new"
    mv "$root/$relative.ai-mails-new" "$root/$relative"
    cmp "$stage/$relative" "$root/$relative"
done
cp "$stage/_codex/ai-mails-verify.cfm" "$root/_codex/ai-mails-verify.cfm"
cp "$stage/_codex/tests/ai-mails-service.cfm" "$root/_codex/tests/ai-mails-service.cfm"
curl --fail-with-body -sS -X POST --resolve business.roadrunners.run:443:127.0.0.1 'https://business.roadrunners.run/_codex/ai-mails-verify.cfm?activate_jobs=1'
echo 'Publicação concluída com jobs registrados. Monitor permanece pausado até consentimento Gmail.'
