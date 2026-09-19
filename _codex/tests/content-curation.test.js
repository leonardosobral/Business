const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');
const read = p => fs.readFileSync(path.resolve(__dirname, '../..', p), 'utf8');
const sql = read('_codex/sql/2026-09-18_content_starts_in_review.sql');
test('new content enters review, never public or featured', () => {
  assert.match(sql, /editorial_status SET DEFAULT 'review'/);
  assert.match(sql, /NEW\.editorial_status := 'review'/);
  assert.match(sql, /NEW\.published := false/);
  assert.match(sql, /NEW\.is_featured := false/);
  assert.match(sql, /NEW\.published_at := NULL/);
  assert.doesNotMatch(sql, /DROP TRIGGER/);
});
test('backfill is limited to untouched imported drafts without publication', () => {
  for (const rule of ['c.published = false', "c.editorial_status = 'draft'", 'c.published_at IS NULL', 'c.created_at = c.updated_at', 'i.content_id = c.id']) assert.ok(sql.includes(rule));
  assert.doesNotMatch(sql, /SET[\s\S]*updated_at\s*=/);
});
test('list, preview, and global dashboard agree on review status', () => {
  assert.match(read('portal/includes/content_backend.cfm'), /AS total_pendentes/);
  assert.match(read('portal/conteudos/home.cfm'), /qContentStats\.total_pendentes/);
  assert.match(read('portal/conteudos/home.cfm'), /Não publicados \(todos\)/);
  assert.match(read('portal/conteudos/preview.cfm'), /EQ "review">Pendente de curadoria/);
  assert.match(read('includes/estrutura/home_admin_dashboard.cfm'), /lower\(coalesce\(editorial_status, ''\)\) = 'review'/);
});
