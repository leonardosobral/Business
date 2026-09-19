'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const businessRoot = path.resolve(__dirname, '../..');
const newsRoot = path.resolve(businessRoot, '../News');
const read = (root, relative) => fs.readFileSync(path.join(root, relative), 'utf8');

const backend = read(businessRoot, 'portal/includes/content_backend.cfm');
const page = read(businessRoot, 'portal/conteudos/home.cfm');
const endpoint = read(newsRoot, 'api/admin/jobs/article_summary.cfm');
const service = read(newsRoot, 'inc/article_summary_service.cfc');
const provider = read(newsRoot, 'inc/article_summary_provider.cfc');
const config = read(newsRoot, 'inc/article_summary_config.cfc');

assert.match(backend, /FORM\.process_summary_id/);
assert.match(backend, /content_summary_csrf/);
assert.match(backend, /X-API-Key/);
assert.match(backend, /article_summary\.cfm\?content_id=/);
assert.match(page, /data-summary-action/);
assert.match(page, /name="process_summary_id"[^>]*formnovalidate[^>]*data-summary-action/s);
assert.match(page, /Reprocessar resumo/);
assert.match(page, /O resumo atual só será substituído se a nova versão for validada/);
assert.doesNotMatch(page, /summaryButton\.disabled\s*=\s*true/);
assert.match(page, /summaryButton\.setAttribute\('aria-disabled', 'true'\)/);

assert.match(endpoint, /service\.processContent\(contentId\)/);
assert.match(endpoint, /targeted=contentId GT 0/);
assert.match(service, /public struct function processContent/);
assert.match(service, /\(:target=0 OR j\.content_id=:target\)/);
assert.match(service, /source_description_html/);
assert.match(service, /arguments\.targetContentId LTE 0 AND job\.attempts/);
assert.match(service, /arguments\.targetContentId LTE 0 AND sourceArchived\) \{/);
assert.match(service, /archiveSource\(db,contentId,sourceText\)/);
assert.match(service, /source_archived_at/);
assert.match(provider, /omita o detalhe divergente/);
assert.match(config, /promptVersion = "2"/);

console.log('Individual content summary checks: OK');
