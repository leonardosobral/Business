'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const backend = fs.readFileSync(path.join(root, 'administracao/vicky/includes/backend.cfm'), 'utf8');
const page = fs.readFileSync(path.join(root, 'administracao/vicky/home.cfm'), 'utf8');
const upload = fs.readFileSync(path.join(root, 'administracao/vicky/includes/knowledge_batch.cfm'), 'utf8');
const repair = fs.readFileSync(path.join(root, 'administracao/vicky/includes/knowledge_rebuild.cfm'), 'utf8');

test('exposes a CSRF-protected repair action only when documents failed', () => {
  assert.match(backend, /FORM\.action EQ "rebuild_knowledge_index"[\s\S]*knowledge_rebuild\.cfm/);
  assert.match(page, /qVickyDocumentSummary\.failed GT 0[\s\S]*name="action" value="rebuild_knowledge_index"/);
  assert.match(page, /name="csrf_token"/);
  assert.match(page, /data-vicky-repair-form[\s\S]*button\.disabled=true/);
  assert.match(repair, /compare\(FORM\.csrf_token&"",VARIABLES\.vickyAdminCsrfToken\)/);
});

test('reuses a healthy index and recreates only a missing index', () => {
  assert.match(repair, /method="get" url="https:\/\/api\.openai\.com\/v1\/vector_stores\/#urlEncodedFormat\(VARIABLES\.previousVectorStoreId\)#"/);
  assert.match(repair, /VARIABLES\.storeHttp NEQ 404[\s\S]*Nenhuma configuração foi alterada/);
  assert.match(repair, /<cfif NOT VARIABLES\.vectorStoreAvailable>[\s\S]*method="post" url="https:\/\/api\.openai\.com\/v1\/vector_stores"/);
  assert.match(repair, /SET openai_vector_store_id=<cfqueryparam/);
});

test('rebuilds the missing index and recovers changed OpenAI file ids', () => {
  assert.match(repair, /status IN \(<cfif VARIABLES\.vectorStoreCreated>'active','processing','failed'/);
  assert.match(repair, /v1\/files\?purpose=assistants&limit=100/);
  assert.match(repair, /val\(rebuildCandidateFile\.bytes\) EQ val\(qVickyRebuildDocuments\.tamanho_bytes\)/);
  assert.match(repair, /arrayLen\(VARIABLES\.rebuildExactMatches\) EQ 1/);
  assert.match(repair, /SET openai_file_id=<cfqueryparam/);
  assert.match(repair, /VARIABLES\.rebuildAttachPayload\["file_id"\]=VARIABLES\.rebuildFileId/);
  assert.match(repair, /vector_stores\/#urlEncodedFormat\(VARIABLES\.targetVectorStoreId\)#\/files/);
  assert.match(repair, /status='processing'/);
  assert.match(repair, /O arquivo não existe mais na OpenAI; reenvie o PDF/);
});

test('validates the index before uploading and preserves a file when attachment fails', () => {
  const validation = upload.indexOf('result="vickyKnowledgeStoreResponse"');
  const localUpload = upload.indexOf('<cffile action="uploadAll"');
  const persist = upload.indexOf('<cfset VARIABLES.documentPersisted=true/>');
  const attach = upload.indexOf('result="vickyAttachResponse"');
  assert.ok(validation >= 0 && validation < localUpload, 'vector store must be validated before receiving files');
  assert.ok(persist >= 0 && persist < attach, 'the uploaded OpenAI file must be recorded before attachment');
  assert.match(upload, /status='failed'[\s\S]*RETURNING id_vicky_documento/);
  assert.match(upload, /len\(VARIABLES\.openAiFileId\) AND NOT VARIABLES\.documentPersisted/);
  assert.match(upload, /Use “Reparar índice” para tentar novamente sem reenviar o arquivo/);
});
