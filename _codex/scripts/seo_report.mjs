import { constants } from 'node:fs';
import { lstat, mkdir, mkdtemp, open, chmod, rename, rm, rmdir } from 'node:fs/promises';
import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';

const PAYLOADS = ['observations.jsonl', 'inventory.csv', 'findings.json', 'summary.md', 'comparison.json'];
const CSV_COLUMNS = ['source_url', 'status', 'final_url', 'redirected', 'content_type', 'x_robots_tag', 'canonical_url', 'meta_robots', 'duration_ms', 'error'];
const COMPATIBILITY_FIELDS = ['site_id', 'mode', 'rules_version', 'schema_version', 'config_hash'];
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const isHash = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const json = value => JSON.stringify(value, null, 2) + '\n';
const findingKey = finding => JSON.stringify([finding.site_id, finding.source_url, finding.rule_id]);
const uniqueFindings = findings => [...new Map((findings || []).map(finding => [findingKey(finding), finding])).values()];

/** Absence from a sample or a failed observation never demonstrates a repair. */
export function compareRuns(previous, current) {
  const result = { new: [], resolved: [], persistent: [], not_rechecked: [], comparable: false };
  const currentFindings = uniqueFindings(current.findings);
  if (!previous) {
    return { ...result, new: currentFindings, reason: 'Sem execução completa anterior para comparação.' };
  }
  const previousFindings = uniqueFindings(previous.findings);
  const incompatible = COMPATIBILITY_FIELDS.filter(field => previous[field] == null || current[field] == null || previous[field] !== current[field]);
  if (incompatible.length) {
    return { ...result, new: currentFindings, not_rechecked: previousFindings,
      reason: `Execuções incompatíveis: ${incompatible.join(', ')}.` };
  }
  result.comparable = true;
  const oldKeys = new Set(previousFindings.map(findingKey));
  const newKeys = new Set(currentFindings.map(findingKey));
  for (const finding of currentFindings) {
    result[oldKeys.has(findingKey(finding)) ? 'persistent' : 'new'].push(finding);
  }
  const checked = new Set();
  if (current.completion === 'complete' && current.mode !== 'head') {
    for (const observation of current.observations || []) {
      if (observation.html_evaluation === 'evaluated' && !observation.error && !observation.error_code && !observation.skip_reason
          && observation.status >= 200 && observation.status < 300
          && /^(text\/html|application\/xhtml\+xml)(?:\s*;|\s*$)/i.test(observation.content_type || '')) {
        checked.add(observation.source_url);
      }
    }
  }
  for (const finding of previousFindings) {
    if (!newKeys.has(findingKey(finding))) {
      result[checked.has(finding.source_url) ? 'resolved' : 'not_rechecked'].push(finding);
    }
  }
  return result;
}

function validateId(value, name) {
  const pattern = name === 'site_id' ? /^[a-z0-9][a-z0-9-]{0,62}$/ : /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/;
  if (typeof value !== 'string' || !pattern.test(value) || value.includes('..') || (name === 'run_id' && value === 'latest-complete.json')) {
    throw new Error(`Identificador ${name} inválido.`);
  }
}

function validateRun(run) {
  if (!isObject(run)) throw new Error('Manifesto de execução inválido.');
  validateId(run.site_id, 'site_id');
  validateId(run.run_id, 'run_id');
  if (run.schema_version !== 1 || typeof run.rules_version !== 'string' || !run.rules_version
      || typeof run.collector_version !== 'string' || !run.collector_version
      || !['head', 'deep', 'audit'].includes(run.mode) || !['full', 'sample'].includes(run.scope)
      || !['complete', 'partial', 'failed'].includes(run.completion)
      || ![0, 1, 2].includes(run.exit_code) || typeof run.discovery_complete !== 'boolean'
      || !isHash(run.config_hash) || !isHash(run.collector_hash) || !isHash(run.selection_hash)
      || !isObject(run.counts) || !isObject(run.limits)) {
    throw new Error('Contrato do manifesto de execução inválido.');
  }
  for (const name of ['started_at', 'finished_at']) {
    if (typeof run[name] !== 'string' || !Number.isFinite(Date.parse(run[name]))) throw new Error(`Manifesto: ${name} inválido.`);
  }
  for (const name of ['observations', 'findings', 'selected_urls', 'sitemaps', 'errors']) {
    if (!Array.isArray(run[name])) throw new Error(`Manifesto: ${name} deve ser uma lista.`);
  }
  for (const observation of run.observations) {
    if (!isObject(observation) || typeof observation.source_url !== 'string') throw new Error('Observação inválida.');
  }
  for (const finding of run.findings) {
    if (!isObject(finding) || finding.site_id !== run.site_id || typeof finding.source_url !== 'string'
        || typeof finding.rule_id !== 'string' || !finding.rule_id
        || !['error', 'warning', 'info'].includes(finding.severity)) throw new Error('Achado inválido ou de outro site.');
  }
}

function absolutePath(value) {
  if (typeof value !== 'string' || !path.isAbsolute(value)) throw new Error('O caminho deve ser absoluto.');
  if (value.includes('\0') || value.includes('\\') || value.split('/').some(part => part === '.' || part === '..')) {
    throw new Error('Caminho com traversal não permitido.');
  }
  return path.normalize(value);
}

async function statIfPresent(filePath) {
  try { return await lstat(filePath); }
  catch (error) { if (error.code === 'ENOENT') return null; throw error; }
}

/** Every directory is checked separately; recursive mkdir must not follow a link. */
async function directories(directory, create = false) {
  const absolute = absolutePath(directory);
  let cursor = path.parse(absolute).root;
  for (const component of absolute.slice(cursor.length).split('/').filter(Boolean)) {
    cursor = path.join(cursor, component);
    let stat = await statIfPresent(cursor);
    if (!stat && create) {
      try { await mkdir(cursor, { mode: 0o700 }); }
      catch (error) { if (error.code !== 'EEXIST') throw error; }
      stat = await lstat(cursor);
    }
    if (!stat) throw Object.assign(new Error('Diretório de relatório ausente.'), { code: 'ENOENT' });
    if (stat.isSymbolicLink()) throw new Error('Link simbólico (symlink) não permitido no caminho.');
    if (!stat.isDirectory()) throw new Error('Caminho de relatório não é um diretório.');
  }
  return absolute;
}

async function readRegular(filePath) {
  const stat = await lstat(filePath);
  if (stat.isSymbolicLink()) throw new Error('Link simbólico (symlink) não permitido em artefato.');
  if (!stat.isFile()) throw new Error('Artefato não é um arquivo regular.');
  let handle;
  try {
    handle = await open(filePath, constants.O_RDONLY | constants.O_NOFOLLOW);
    const opened = await handle.stat();
    if (!opened.isFile() || opened.ino !== stat.ino || opened.dev !== stat.dev) throw new Error('Artefato mudou durante a leitura.');
    return await handle.readFile();
  } catch (error) {
    if (error.code === 'ELOOP') throw new Error('Link simbólico (symlink) não permitido em artefato.');
    throw error;
  } finally { await handle?.close(); }
}

async function writePrivate(filePath, data) {
  const handle = await open(filePath, 'wx', 0o600);
  try { await handle.writeFile(data); await handle.sync(); }
  finally { await handle.close(); }
}

async function syncDirectory(directory) {
  const handle = await open(directory, constants.O_RDONLY | constants.O_DIRECTORY | constants.O_NOFOLLOW);
  try { await handle.sync(); } finally { await handle.close(); }
}

function parseJson(data, label) {
  try { return JSON.parse(data.toString('utf8')); }
  catch { throw new Error(`Integridade: JSON inválido em ${label}.`); }
}

/** Payload hashes detect corruption; authenticity relies on the private directory. */
async function readReportBundle(runDir) {
  const directory = await directories(runDir);
  const manifest = parseJson(await readRegular(path.join(directory, 'manifest.json')), 'manifesto');
  if (!isObject(manifest) || !isObject(manifest.files)
      || Object.keys(manifest.files).sort().join('\0') !== [...PAYLOADS].sort().join('\0')
      || Object.hasOwn(manifest, 'observations') || Object.hasOwn(manifest, 'findings')) {
    throw new Error('Manifesto contém mapa de arquivos inválido.');
  }
  validateId(manifest.site_id, 'site_id');
  validateId(manifest.run_id, 'run_id');
  if (path.basename(directory) !== manifest.run_id || path.basename(path.dirname(directory)) !== manifest.site_id) {
    throw new Error('Manifesto não corresponde ao caminho da execução.');
  }
  const payloads = {};
  for (const name of PAYLOADS) {
    const receipt = manifest.files[name];
    if (!isObject(receipt) || !isHash(receipt.sha256) || !Number.isSafeInteger(receipt.bytes) || receipt.bytes < 0) {
      throw new Error('Manifesto contém integridade de arquivo inválida.');
    }
    const bytes = await readRegular(path.join(directory, name));
    if (bytes.length !== receipt.bytes || hash(bytes) !== receipt.sha256) throw new Error(`Integridade: hash ou tamanho divergente em ${name}.`);
    payloads[name] = bytes;
  }
  const { files, ...metadata } = manifest;
  const observations = payloads['observations.jsonl'].toString('utf8').split('\n').filter(line => line.trim()).map(line => parseJson(Buffer.from(line), 'observação'));
  const findings = parseJson(payloads['findings.json'], 'achados');
  const reconstructed = { ...metadata, observations, findings };
  validateRun(reconstructed);
  const comparison = parseJson(payloads['comparison.json'], 'comparação');
  if (!isObject(comparison) || typeof comparison.comparable !== 'boolean'
      || ['new', 'resolved', 'persistent', 'not_rechecked'].some(name => !Array.isArray(comparison[name]))) {
    throw new Error('Integridade: comparação inválida.');
  }
  return { run: reconstructed, comparison };
}

export async function readReport(runDir) {
  return (await readReportBundle(runDir)).run;
}

function csvValue(value) {
  let text = String(value ?? '');
  // Leading whitespace/control bytes do not make spreadsheet formulas safe.
  if (/^[\s\u0000-\u001f\u007f]*[=+@-]/u.test(text) || /^[\t\r\n]/.test(text)) text = "'" + text;
  return '"' + text.replaceAll('"', '""') + '"';
}

function markdownText(value) {
  return String(value ?? '').replace(/[\u0000-\u001f\u007f-\u009f]/g, ' ')
    .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
    .replace(/[\\`*_{}\[\]()#+.!|~-]/g, '\\$&');
}

function summary(run, comparison) {
  const statuses = { complete: 'completa', partial: 'parcial', failed: 'falhou' };
  const count = name => markdownText(run.counts[name] ?? 'não informado');
  const lines = [
    '# Auditoria técnica de URLs', '',
    `Site: ${markdownText(run.site_id)}. Execução: ${markdownText(run.run_id)}.`, '',
    `Estado: **${statuses[run.completion]}**. Modo: ${markdownText(run.mode)}. `
      + (run.scope === 'sample' ? 'Escopo: **amostra**, não representa todas as páginas do site.' : 'Escopo: URLs selecionadas a partir da descoberta configurada; o sitemap não é um censo do site.'), '',
    `Início: ${markdownText(run.started_at)}. Fim: ${markdownText(run.finished_at)}.`, '',
    `URLs descobertas: ${count('discovered')}; selecionadas: ${count('selected')}; inspecionadas: ${count('inspected')}; duplicadas: ${count('duplicates')}.`, '',
    `Erros SEO/página: **${count('errors')}**; avisos SEO/página: **${count('warnings')}**. Erros operacionais: **${run.errors.length}**. `
      + 'São contagens separadas: zero erros SEO/página não significa que a descoberta ou a coleta foi concluída.', '',
    `Descoberta ${run.discovery_complete ? 'concluída' : 'incompleta'}. Limites aplicados: ${markdownText(JSON.stringify(run.limits))}.`, '',
    'HTTP 200 e presença no sitemap não comprovam indexação no Google. HEAD não avalia HTML. A duração das requisições não mede Core Web Vitals.', '',
    `Comparação: ${comparison.comparable ? 'configuração compatível' : markdownText(comparison.reason)}.`, '',
    `Novos: ${comparison.new.length}; persistentes: ${comparison.persistent.length}; resolvidos: ${comparison.resolved.length}; não rechecados: ${comparison.not_rechecked.length}.`, ''
  ];
  lines.push('## Erros operacionais', '');
  if (!run.errors.length) lines.push('Nenhum erro operacional registrado.', '');
  for (const error of run.errors) lines.push(`- ${markdownText(error.code)} · ${markdownText(error.url)} · ${markdownText(error.message)}`);
  lines.push('');
  for (const [key, label] of [['new', 'Achados novos'], ['persistent', 'Achados persistentes'], ['resolved', 'Achados resolvidos'], ['not_rechecked', 'Achados não rechecados']]) {
    lines.push(`## ${label}`, '');
    if (!comparison[key].length) lines.push('Nenhum registro nesta categoria.', '');
    for (const finding of comparison[key]) {
      lines.push(`- ${markdownText(finding.severity)} · ${markdownText(finding.rule_id)} · ${markdownText(finding.source_url)} · Evidência: ${markdownText(JSON.stringify(finding.evidence))}`);
    }
    lines.push('');
  }
  lines.push('', '## Próximas ações', '',
    '- Revisar os achados com evidência no projeto responsável pelo site antes de alterar conteúdo ou regras públicas.',
    '- Rechecar URLs sem avaliação conclusiva; uma execução parcial não resolve achados anteriores.',
    '- Consultar a propriedade correta no Search Console para medir indexação e desempenho de busca.', '');
  return lines.join('\n');
}

async function previousComplete(siteDir) {
  const pointerPath = path.join(siteDir, 'latest-complete.json');
  if (!await statIfPresent(pointerPath)) return null;
  const pointer = parseJson(await readRegular(pointerPath), 'ponteiro');
  if (!isObject(pointer)) throw new Error('Ponteiro de execução inválido.');
  validateId(pointer.run_id, 'run_id');
  if (!isHash(pointer.manifest_sha256)) throw new Error('Integridade do ponteiro inválida.');
  const runDir = path.join(siteDir, pointer.run_id);
  await directories(runDir);
  const manifest = await readRegular(path.join(runDir, 'manifest.json'));
  if (hash(manifest) !== pointer.manifest_sha256) throw new Error('Integridade do manifesto referenciado pelo ponteiro inválida.');
  const { run: previous, comparison } = await readReportBundle(runDir);
  if (previous.completion !== 'complete') throw new Error('Ponteiro não referencia uma execução completa.');
  // Rotating samples carry unresolved evidence forward without rewriting the raw run.
  return comparison.comparable
    ? { ...previous, findings: uniqueFindings([...previous.findings, ...comparison.not_rechecked]) }
    : previous;
}

/** Root location outside repositories/docroots is additionally enforced by the runner. */
export async function writeReport(run, root) {
  validateRun(run);
  const reportRoot = absolutePath(root);
  if (['/', '/tmp', '/private/tmp', '/var', '/private/var'].includes(reportRoot)) throw new Error('Use um diretório de relatórios dedicado.');
  await directories(reportRoot, true);
  await chmod(reportRoot, 0o700);
  const siteDir = await directories(path.join(reportRoot, run.site_id), true);
  await chmod(siteDir, 0o700);
  const runDir = path.join(siteDir, run.run_id);
  const lockPath = path.join(siteDir, '.report-write.lock');
  try { await mkdir(lockPath, { mode: 0o700 }); }
  catch (error) {
    if (error.code === 'EEXIST') throw new Error('Outra gravação de relatório está em andamento; lock existente.');
    throw error;
  }
  let staging;
  let pointerTemp;
  try {
    if (await statIfPresent(runDir)) throw new Error('Execução já publicada: run_id existente.');
    const previous = await previousComplete(siteDir);
    const comparison = compareRuns(previous, run);
    const payloads = {
      'observations.jsonl': run.observations.map(value => JSON.stringify(value) + '\n').join(''),
      'inventory.csv': [CSV_COLUMNS.map(csvValue).join(','), ...run.observations.map(row => CSV_COLUMNS.map(name => csvValue(row[name])).join(','))].join('\n') + '\n',
      'findings.json': json(run.findings), 'summary.md': summary(run, comparison), 'comparison.json': json(comparison)
    };
    const { observations, findings, ...metadata } = run;
    const files = Object.fromEntries(PAYLOADS.map(name => [name, { bytes: Buffer.byteLength(payloads[name]), sha256: hash(payloads[name]) }]));
    const manifest = json({ ...metadata, files });
    staging = await mkdtemp(path.join(siteDir, `.${run.run_id}-`));
    await chmod(staging, 0o700);
    for (const name of PAYLOADS) await writePrivate(path.join(staging, name), payloads[name]);
    await writePrivate(path.join(staging, 'manifest.json'), manifest);
    await syncDirectory(staging);
    await directories(siteDir);
    await rename(staging, runDir);
    staging = null;
    await syncDirectory(siteDir);
    if (run.completion === 'complete') {
      const pointerPath = path.join(siteDir, 'latest-complete.json');
      const existing = await statIfPresent(pointerPath);
      if (existing?.isSymbolicLink() || (existing && !existing.isFile())) throw new Error('Ponteiro não pode ser link simbólico ou arquivo especial.');
      pointerTemp = path.join(siteDir, `.latest-${randomUUID()}.json`);
      await writePrivate(pointerTemp, json({ run_id: run.run_id, manifest_sha256: hash(manifest) }));
      await rename(pointerTemp, pointerPath);
      pointerTemp = null;
      await syncDirectory(siteDir);
    }
    return { manifest_path: path.join(runDir, 'manifest.json'), summary_path: path.join(runDir, 'summary.md'), run_dir: runDir };
  } finally {
    if (staging) await rm(staging, { recursive: true, force: true });
    if (pointerTemp) await rm(pointerTemp, { force: true });
    await rmdir(lockPath);
  }
}
