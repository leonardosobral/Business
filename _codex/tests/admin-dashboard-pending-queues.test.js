'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const dashboard = fs.readFileSync(path.join(root, 'includes/estrutura/home_admin_dashboard.cfm'), 'utf8');
const css = fs.readFileSync(path.join(root, 'assets/css/admin-dashboard.css'), 'utf8');

test('centralizes every current human-action queue with a direct destination', () => {
  const expected = [
    ['Help Desk', '/helpdesk/?ordem=prioridade'],
    ['Conteúdos editoriais', '/portal/conteudos/?status=pendentes'],
    ['Cadastros de conta', '/administracao/contas/'],
    ['Vínculos de eventos', '/eventos/'],
    ['Anúncios', '/ads/?view=admin'],
    ['Brasil Gigante', '/desafios/circuitobrasilgigante/?tela=validacoes'],
    ['Foco Radical', '/administracao/foco-revisao/'],
    ['Agregadores', '/administracao/agrega-revisao/'],
    ['Importações de resultados', '/administracao/importacoes-resultados/?periodo=0'],
    ['Vínculos do CRM', '/crm/'],
    ['Migração Strava', '/percursos/migracao-strava.cfm'],
    ['Fila de Push', '/notificacoes/envio/?view=push'],
    ['E-mail marketing', '/emailmkt/'],
    ['Entregas da Vicky', '/administracao/vicky/?secao=interacoes'],
    ['Base da Vicky', '/administracao/vicky/?secao=conhecimento']
  ];

  for (const [label, href] of expected) {
    assert.ok(dashboard.includes(`label="${label}"`), `missing queue label: ${label}`);
    assert.ok(dashboard.includes(`href="${href}"`), `missing direct link: ${href}`);
  }
});

test('uses the same actionable definitions as each source workspace', () => {
  assert.match(dashboard, /status IN \('aberto', 'cliente_respondeu'\)/);
  assert.match(dashboard, /status NOT IN \('resolvido', 'fechado'\)[\s\S]*updated_at < now\(\) - interval '48 hours'/);
  assert.match(dashboard, /AS pendentes/);
  assert.match(dashboard, /lower\(coalesce\(editorial_status, ''\)\) = 'review'/);
  assert.match(dashboard, /status = 'PENDING_REVIEW'/);
  assert.match(dashboard, /status_analise.*'pendente'/s);
  assert.match(dashboard, /status_processamento = 'falhou'/);
  assert.match(dashboard, /data_recebimento < now\(\) - interval '15 minutes'/);
  assert.match(dashboard, /FROM crm\.tb_crm_participacoes[\s\S]*id_evento IS NULL/);
  assert.match(dashboard, /FROM public\.tb_percurso_migracoes_strava/);
  assert.match(dashboard, /FROM public\.tb_push_delivery_queue/);
  assert.match(dashboard, /FROM public\.tb_mailing/);
  assert.match(dashboard, /FROM public\.tb_vicky_notificacao_fila/);
  assert.match(dashboard, /FROM public\.tb_vicky_documento/);
  assert.match(dashboard, /FROM public\.tb_ai_mail_threads[\s\S]*analyzed_at IS NOT NULL[\s\S]*last_inbound_ms > \(SELECT monitor_since_ms FROM public\.tb_ai_mail_config WHERE id=1\)/);
});

test('counts only operational exceptions that no longer look transient', () => {
  assert.match(dashboard, /status = 'processando'[\s\S]*data_atualizacao < now\(\) - interval '15 minutes'/);
  assert.match(dashboard, /status = 'pending'[\s\S]*updated_at < now\(\) - interval '15 minutes'/);
  assert.match(dashboard, /status IN \('failed', 'dead_letter'\)[\s\S]*created_at >= now\(\) - interval '30 days'/);
});

test('keeps optional verified-athlete requests out until their schema exists', () => {
  assert.match(dashboard, /businessAdminHomeHasAthleteReviewTable/);
  assert.match(dashboard, /<cfif VARIABLES\.businessAdminHomeHasAthleteReviewTable>/);
  assert.match(dashboard, /label="Atletas verificados"/);
});

test('distinguishes unavailable sources from zero and computes one aggregate', () => {
  assert.match(dashboard, /businessAdminHomeDecisionLoaded = true/);
  assert.match(dashboard, /businessAdminHomeDecisionTotal \+= VARIABLES\.businessAdminHomeQueueItem\.value/);
  assert.match(dashboard, /businessAdminHomeDecisionLoaded = false/);
  assert.match(dashboard, /cada item é contado em uma única fila/);
  assert.match(dashboard, /Total indisponível: uma das filas não pôde ser consultada/);
});

test('renders the expanded queue responsively without affecting account dashboards', () => {
  assert.match(css, /\.business-global-dashboard \.gd-queue \{[^}]*grid-template-columns: repeat\(2,minmax\(0,1fr\)\)/s);
  assert.match(css, /@media \(max-width: 991\.98px\)[\s\S]*\.business-global-dashboard \.gd-queue \{ grid-template-columns: minmax\(0,1fr\); \}/);
  assert.doesNotMatch(css, /(^|\n)\.gd-queue\b/);
});
