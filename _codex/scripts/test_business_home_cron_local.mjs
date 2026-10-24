#!/usr/bin/env node
// Run the dashboard's exact cron aggregate against a disposable PostgreSQL 16 cluster.
import assert from 'node:assert/strict';
import {mkdtempSync, readFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const source = readFileSync(resolve(root, 'includes/estrutura/home_admin_dashboard.cfm'), 'utf8');
const match = source.match(/<cfquery name="qBusinessAdminHomeCronStats"[^>]*>([\s\S]*?)<\/cfquery>/);
assert.ok(match, 'The dashboard must expose its cron aggregate query');
const statement = match[1].replaceAll('now()', "TIMESTAMPTZ '2026-10-24 15:00:00+00'");
const scratch = mkdtempSync(resolve(tmpdir(), 'business-home-cron-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const run = (name, args, input) => {
    const result = spawnSync(resolve(bin, name), args, {
        input, encoding: 'utf8', env: {PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir()}
    });
    if (result.status !== 0) throw Error(`${name}: ${result.stdout || ''}${result.stderr || ''}`);
    return result.stdout.trim();
};
const sql = input => run('psql', ['-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', 'postgres', '-d', 'postgres'], input);
const literal = value => value === null ? 'NULL' : typeof value === 'boolean' ? String(value) : `'${String(value).replaceAll("'", "''")}'`;
const query = (zone = 'UTC') => JSON.parse(sql(`SET TIME ZONE ${literal(zone)}; SELECT row_to_json(r) FROM (${statement}) r;`));
const seed = rows => sql('TRUNCATE tb_cron_jobs;' + rows.map(row => `INSERT INTO tb_cron_jobs VALUES (${row.map(literal).join(',')});`).join('\n'));
let checks = 0;
const eq = (actual, expected, message) => { assert.deepEqual(actual, expected, message); checks++; };
let started = false;

try {
    run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
    run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'), '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
    started = true;
    sql('CREATE TABLE tb_cron_jobs(ativo boolean, next_run_at timestamp without time zone, last_status text);');
    eq(query(), {total_jobs: 0, ativos: 0, vencidos: 0, atrasados: 0, erros: 0}, 'An empty loaded source measures zero for each cron signal');

    for (const [name, row, expected] of [
        ['just due', [true, '2026-10-24 15:00:00', 'success'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 0, erros: 0}],
        ['due for ten minutes', [true, '2026-10-24 14:50:00', 'success'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 0, erros: 0}],
        ['one second below threshold', [true, '2026-10-24 14:45:01', 'success'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 0, erros: 0}],
        ['exact fifteen-minute boundary', [true, '2026-10-24 14:45:00', 'success'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 1, erros: 0}],
        ['sixteen minutes after a successful last run', [true, '2026-10-24 14:44:00', 'success'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 1, erros: 0}],
        ['already running', [true, '2026-10-24 14:00:00', ' RUNNING '], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 0, erros: 0}],
        ['inactive job', [false, '2026-10-24 14:00:00', 'success'], {total_jobs: 1, ativos: 0, vencidos: 0, atrasados: 0, erros: 0}],
        ['no last status', [true, '2026-10-24 14:00:00', null], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 1, erros: 0}],
        ['future schedule', [true, '2026-10-24 15:00:01', 'success'], {total_jobs: 1, ativos: 1, vencidos: 0, atrasados: 0, erros: 0}],
        ['no next schedule', [true, null, 'success'], {total_jobs: 1, ativos: 1, vencidos: 0, atrasados: 0, erros: 0}],
        ['late and failed', [true, '2026-10-24 14:00:00', 'failed'], {total_jobs: 1, ativos: 1, vencidos: 1, atrasados: 1, erros: 1}],
        ['inactive failure remains a separate error', [false, '2026-10-24 14:00:00', 'error'], {total_jobs: 1, ativos: 0, vencidos: 0, atrasados: 0, erros: 1}]
    ]) {
        seed([row]);
        eq(query(), expected, name);
        eq(query('Pacific/Honolulu'), expected, `${name}: UTC schedule comparisons must not depend on the session timezone`);
    }

    for (const status of [' ERROR ', 'http_error', 'FAILED', 'timeout']) {
        seed([[true, '2026-10-24 16:00:00', status]]);
        eq(query(), {total_jobs: 1, ativos: 1, vencidos: 0, atrasados: 0, erros: 1}, `${status} remains an error without becoming overdue`);
    }
    seed([
        [true, '2026-10-24 15:00:00', 'success'],
        [true, '2026-10-24 14:50:00', 'success'],
        [true, '2026-10-24 14:44:00', 'success'],
        [true, '2026-10-24 14:00:00', ' running '],
        [false, '2026-10-24 14:00:00', 'success'],
        [true, '2026-10-24 16:00:00', 'error']
    ]);
    eq(query(), {total_jobs: 6, ativos: 5, vencidos: 4, atrasados: 1, erros: 1}, 'The overdue and failed queues remain independently measurable in a mixed source');
    console.log(`Business home cron SQL: ${checks} behavioral assertions passed against isolated PostgreSQL 16.`);
} finally {
    if (started) run('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'immediate', '-w', 'stop']);
    rmSync(scratch, {recursive: true, force: true});
}
