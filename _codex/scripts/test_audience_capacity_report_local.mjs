#!/usr/bin/env node
// Real PostgreSQL on an isolated Unix socket. No application/production connection settings are read.
// --baseline-inventory exercises the previous real query to demonstrate the missing capacity contract.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-capacity-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const baseline = process.argv.includes('--baseline-inventory');
const asOf = '2026-09-12T15:00:00Z'; // Noon in Sao Paulo; all fixture dates are deliberately fixed.
let checks = 0;
let sequence = 0;
let started = false;
const equal = (actual, expected, message) => { assert.deepEqual(actual, expected, message); checks++; };
const run = (name, args, input) => {
  const result = spawnSync(resolve(bin, name), args, {
    input, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() }
  });
  if (result.status !== 0) throw new Error(`${name}: ${result.stdout || ''}${result.stderr || ''}`);
  return result.stdout.trim();
};
const sql = (input, role = 'postgres') => run('psql', [
  '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', role, '-d', 'postgres'
], input);
const literal = value => value === null ? 'NULL' : typeof value === 'number' || typeof value === 'boolean'
  ? String(value) : `'${String(value).replaceAll("'", "''")}'`;
const date = (offset, time = '12:00:00') => {
  const day = new Date('2026-09-12T12:00:00Z');
  day.setUTCDate(day.getUTCDate() + offset);
  return `${day.toISOString().slice(0, 10)}T${time}-03:00`;
};
const page = () => `00000000-0000-4000-8000-${String(++sequence).padStart(12, '0')}`;
const event = (pageId, kind, overrides = {}) => ({
  page_view_id: pageId, event_key: `event-${++sequence}`, event_kind: kind,
  occurred_at: date(-1), received_at: date(-1), environment: 'prod', is_internal: false,
  visitor_uf: 'SP', profile_uf: 'SP', context_uf: 'SC', market_uf: 'SC',
  page_family: 'home', device_class: 'DESKTOP', slot_key: 'home-one',
  placement_key: 'campaign-placement-one', slot_state: 'empty', ...overrides
});
const opportunity = (overrides = {}, { render = false, view = false } = {}) => {
  const pageId = page();
  return [event(pageId, 'slot_opportunity', overrides),
    ...(render ? [event(pageId, 'slot_render', overrides)] : []),
    ...(view ? [event(pageId, 'slot_viewable', overrides)] : [])];
};
const seed = events => {
  sql('TRUNCATE audience.events;');
  if (!events.length) return;
  const columns = Object.keys(events[0]);
  sql(`INSERT INTO audience.events (${columns.join(',')}) VALUES ${events.map(row =>
    `(${columns.map(column => literal(row[column] ?? null)).join(',')})`).join(',')};`);
};
const query = (overrides = {}) => {
  const params = { days: 30, environment: 'prod', include_internal: false,
    region_dimension: 'market', uf: '', page_family: '', device_class: '', ...overrides };
  let statement = readFileSync(resolve(root, 'portal/audiencia/queries', baseline ? 'inventory.sql' : 'capacity.sql'), 'utf8');
  if (baseline) statement = statement.replace('/* AUDIENCE_FILTER */',
    readFileSync(resolve(root, 'portal/audiencia/queries/filter.sql'), 'utf8'));
  // Owner-only test substitution; production has no clock parameter or test branch.
  statement = statement.replace(/\bnow\(\)/g, `${literal(asOf)}::timestamptz`);
  for (const [key, value] of Object.entries(params)) {
    statement = statement.replace(new RegExp(`(?<!:):${key}\\b`, 'g'), literal(value));
  }
  return JSON.parse(sql(`BEGIN READ ONLY;
    SELECT coalesce(json_agg(r),'[]'::json) FROM (${statement.trim().replace(/;$/, '')}) r;
    COMMIT;`, 'capacity_reader'));
};
const total = rows => rows.find(row => row.row_type === 'total');
const details = rows => rows.filter(row => row.row_type === 'detail');
const metric = (row, ...keys) => keys.map(key => row[key] === null ? null : Number(row[key]));
const history = ({ days, slot = 'history', weekly = [1], missing = [], zeroDays = [],
  install = true, todayViews = 0, market_uf = 'SC', device_class = 'DESKTOP' }) => {
  const events = [];
  const addDay = (offset, views) => {
    // A day with opportunities and no views is measured zero; no event is emitted for a missing day.
    for (let item = 0; item < Math.max(1, views); item++) events.push(...opportunity({
      slot_key: slot, market_uf, device_class, occurred_at: date(offset), received_at: date(offset)
    }, { render: views > 0, view: views > 0 }));
  };
  if (install) addDay(-days - 1, 100);
  for (let index = 0; index < days; index++) {
    const offset = index - days;
    if (!missing.includes(offset)) addDay(offset, zeroDays.includes(offset) ? 0 : weekly[Math.min(Math.floor(index / 7), weekly.length - 1)]);
  }
  if (todayViews) addDay(0, todayViews);
  return events;
};

try {
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'),
    '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
  started = true;
  sql(`CREATE SCHEMA audience;
    CREATE TABLE audience.events (
      page_view_id uuid NOT NULL, event_key text NOT NULL, event_kind text NOT NULL,
      occurred_at timestamptz NOT NULL, received_at timestamptz NOT NULL,
      visitor_id uuid, session_id uuid, environment text, is_internal boolean,
      visitor_uf text, profile_uf text, context_uf text, market_uf text,
      page_family text, device_class text, slot_key text, placement_key text, slot_state text,
      page_path text DEFAULT '/', content_type text DEFAULT '', content_id text DEFAULT '',
      source text DEFAULT 'direct', medium text DEFAULT '(none)', campaign text DEFAULT '', creative text DEFAULT '',
      active_ms integer DEFAULT 0, PRIMARY KEY (page_view_id,event_key));
    CREATE ROLE capacity_reader LOGIN;
    GRANT USAGE ON SCHEMA audience TO capacity_reader;
    GRANT SELECT ON audience.events TO capacity_reader;`);

  // A missing report row must not silently become evidence that an unmeasured site has zero capacity.
  const empty = query();
  equal(empty.length, 1, 'capacity query always returns one total row, including an unmeasured selection');
  equal(empty[0].row_type, 'total', 'empty selection is an explicit total result');
  equal(metric(empty[0], 'opportunities', 'renders', 'slot_views', 'total_rows'), [0, 0, 0, 0], 'empty selection has observed zeros and zero detail groups');
  equal([empty[0].first_day, empty[0].last_received, empty[0].low_30, empty[0].base_30], ['', null, null, null], 'empty selection has no history or forecast');

  // Logical resends, campaign placement changes and contextual UF overlap must not inflate physical capacity.
  const shared = page();
  const midnight = page();
  const rows = [
    event(shared, 'slot_opportunity', { occurred_at: date(-2), received_at: date(-2) }),
    event(shared, 'slot_opportunity', { occurred_at: date(-1), placement_key: 'changed-placement', page_family: 'search', device_class: 'MOBILE' }),
    event(shared, 'slot_render', { placement_key: 'changed-placement', page_family: 'search', device_class: 'MOBILE' }),
    event(shared, 'slot_viewable', { placement_key: 'changed-placement', page_family: 'search', device_class: 'MOBILE' }),
    event(shared, 'slot_viewable'),
    event(shared, 'slot_opportunity', { market_uf: 'SP' }),
    event(shared, 'slot_viewable', { market_uf: 'SP' }),
    ...opportunity({ slot_key: 'home-two' }),
    ...opportunity({ slot_key: 'unknown', market_uf: null }, { render: true, view: true }),
    ...opportunity({ slot_key: 'ad-only' }),
    event(midnight, 'slot_opportunity', { slot_key: 'midnight', occurred_at: date(-2, '23:59:00'), received_at: date(-2, '23:59:00') }),
    event(midnight, 'slot_viewable', { slot_key: 'midnight', occurred_at: date(-1, '00:01:00'), received_at: date(-1, '00:02:00') }),
    event(page(), 'slot_viewable', { slot_key: 'orphan' }),
    ...opportunity({ slot_key: '' }, { view: true }),
    ...opportunity({ slot_key: 'internal', is_internal: true }, { view: true }),
    ...opportunity({ slot_key: 'dev', environment: 'dev' }, { view: true }),
    ...opportunity({ slot_key: 'future', occurred_at: date(1) }, { view: true }),
    ...opportunity({ slot_key: 'old', occurred_at: date(-40) }, { view: true }),
    ...['hidden', 'not_applicable', 'disabled'].flatMap(slot_state => opportunity({ slot_key: slot_state, slot_state }))
  ];
  const adPage = rows.find(row => row.slot_key === 'ad-only').page_view_id;
  rows.push(event(adPage, 'ad_viewable', { slot_key: 'ad-only' }));
  seed(rows);
  let result = query();
  equal(metric(total(result), 'opportunities', 'renders', 'slot_views', 'total_rows'), [8, 2, 3, 9], 'physical total deduplicates SC/SP overlap and retains registered positions without inferring exposure');
  equal(details(result).reduce((sum, row) => sum + Number(row.opportunities), 0), 9, 'regional observations overlap while physical totals remain independent');
  equal(metric(details(result).find(row => row.slot_key === 'hidden'), 'opportunities', 'renders', 'slot_views'), [1, 0, 0], 'hidden positions remain registered but provide no inferred render or exposure');
  const sc = details(result).find(row => row.slot_key === 'home-one' && row.audience_uf === 'SC');
  equal(metric(sc, 'opportunities', 'renders', 'slot_views'), [1, 1, 1], 'distinct event keys and changed placement do not create additional positions or exposures');
  equal([sc.page_family, sc.device_class, sc.first_day], ['home', 'DESKTOP', '2026-09-10'], 'first opportunity anchors group metadata and day');
  const night = details(result).find(row => row.slot_key === 'midnight');
  equal([night.first_day, ...metric(night, 'opportunities', 'slot_views', 'days_observed')], ['2026-09-10', 1, 1, 0], 'view after midnight is attributed to its opportunity day only');
  equal(new Date(night.last_received).toISOString(), '2026-09-11T03:02:00.000Z', 'history includes latest received real matched slot event');
  equal(metric(details(result).find(row => row.slot_key === 'ad-only'), 'slot_views'), [0], 'an ad view cannot substitute for measured physical slot viewability');
  equal(metric(total(query({ uf: '--' })), 'opportunities', 'slot_views'), [1, 1], 'unknown UF is explicitly selectable without allocating to a state');
  equal(metric(total(query({ uf: 'SP' })), 'opportunities', 'slot_views'), [1, 1], 'commercial filtering follows contextual market UF, not visitor residence');
  equal(metric(total(query({ page_family: 'search' })), 'opportunities', 'slot_views'), [0, 0], 'later event metadata cannot move an opportunity to another page family');
  equal(metric(total(query({ device_class: 'MOBILE' })), 'opportunities'), [0], 'later signal device cannot move the original opportunity');
  for (const [key, value] of [['uf', "SC' OR true --"], ['page_family', "home' OR true --"], ['device_class', "DESKTOP' OR true --"]]) {
    equal(metric(total(query({ [key]: value })), 'opportunities'), [0], `${key} injection-shaped input remains a literal value`);
  }
  for (const overrides of [{ environment: 'dev' }, { environment: "prod' OR true --" },
    { include_internal: true }, { region_dimension: 'visitor' }, { region_dimension: 'profile' }, { region_dimension: 'context' }]) {
    equal(metric(total(query(overrides)), 'opportunities', 'total_rows'), [0, 0], 'commercial capacity is unavailable outside external production market context');
  }
  equal([total(result).low_30, total(result).base_30], [null, null], 'overlapping regional scenarios are never summed into a national forecast');

  const futureSignalPage = page();
  const oldSignalPage = page();
  seed([
    event(futureSignalPage, 'slot_opportunity', { slot_key: 'future-signal' }),
    event(futureSignalPage, 'slot_viewable', { slot_key: 'future-signal', occurred_at: date(0, '12:00:01'), received_at: date(1) }),
    event(oldSignalPage, 'slot_opportunity', { slot_key: 'old-signal' }),
    event(oldSignalPage, 'slot_render', { slot_key: 'old-signal', occurred_at: date(-30) }),
    event(oldSignalPage, 'slot_viewable', { slot_key: 'old-signal', occurred_at: date(-30) }),
    ...opportunity({ slot_key: 'hidden-measured', slot_state: 'hidden' }, { view: true })
  ]);
  equal(metric(total(query()), 'opportunities', 'renders', 'slot_views'), [3, 0, 1], 'every matched signal respects the occurred-at window; real viewability is not inferred from state');
  equal(new Date(details(query()).find(row => row.slot_key === 'future-signal').last_received).toISOString(),
    '2026-09-11T15:00:00.000Z', 'future events cannot change the last-received history of an in-window opportunity');

  // Complete calendar-day evidence is required; partial installation/today cannot fill a missing baseline day.
  for (const fixture of [
    { days: 13, todayViews: 100, want: [13, 1, 0, 0, null, null] },
    { days: 14, weekly: [10, 20], todayViews: 100, want: [14, 0, 14, 210, 300, 450] },
    { days: 28, weekly: [5, 10, 20, 30], todayViews: 100, want: [28, 0, 28, 455, 150, 487] },
    { days: 14, install: false, want: [13, 1, 0, 0, null, null] },
    { days: 14, missing: [-4], want: [13, 1, 0, 0, null, null] },
    { days: 28, missing: [-20], weekly: [5, 10, 20, 30], want: [27, 0, 14, 350, 600, 750] },
    { days: 14, weekly: [0], want: [14, 0, 14, 0, null, null] },
    { days: 14, weekly: [1], zeroDays: [-1], want: [14, 0, 14, 13, 25, 27] },
    { days: 14, weekly: [0, 2], want: [14, 0, 14, 14, 0, 30] }
  ]) {
    seed(history(fixture));
    const detail = details(query())[0];
    equal(metric(detail, 'days_observed', 'missing_days_14', 'baseline_days', 'baseline_views', 'low_30', 'base_30'), fixture.want,
      `baseline evidence and hand-calculated scenarios: ${JSON.stringify(fixture)}`);
    equal([total(query()).low_30, total(query()).base_30], [null, null], 'even a single full-baseline group does not create a combined forecast');
  }

  seed(history({ days: 14, weekly: [10, 20], market_uf: null }));
  const unknown = details(query({ uf: '--' }))[0];
  equal([unknown.audience_uf, ...metric(unknown, 'baseline_days', 'base_30')], ['--', 14, 450], 'unknown regional observations retain their own qualified history without state assignment');
  const recentOnly = details(query({ days: 7 }))[0];
  equal(metric(recentOnly, 'days_observed', 'baseline_days', 'base_30'), [5, 0, null], 'seven-day selection cannot borrow an unseen installation day or history');

  // Different devices must individually establish their daily history; combined activity is insufficient.
  seed([...history({ days: 14, weekly: [1], missing: [-2], device_class: 'DESKTOP' }),
    ...history({ days: 14, weekly: [1], missing: [-3], device_class: 'MOBILE' })]);
  equal(details(query()).map(row => Number(row.baseline_days)), [0, 0], 'coverage from another device does not repair a group history gap');

  // Window starts at midnight in Sao Paulo and ends at now, not at midnight tomorrow.
  seed([-90, -89, -30, -29, -7, -6, -1, 0, 1].flatMap(offset => opportunity({
    occurred_at: date(offset), received_at: date(offset)
  }, { view: true })));
  equal(metric(total(query({ days: 7 })), 'opportunities'), [3], 'seven days includes today and six prior calendar days');
  equal(metric(total(query({ days: 30 })), 'opportunities'), [5], 'thirty days excludes the thirtieth prior date');
  equal(metric(total(query({ days: 90 })), 'opportunities'), [7], 'ninety days excludes older dates and future events');
  seed([...opportunity({ occurred_at: '2026-09-06T02:59:59Z' }, { view: true }),
    ...opportunity({ occurred_at: '2026-09-06T03:00:00Z' }, { view: true }),
    ...opportunity({ occurred_at: '2026-09-12T15:00:00Z' }, { view: true }),
    ...opportunity({ occurred_at: '2026-09-12T15:00:01Z' }, { view: true })]);
  equal(metric(total(query({ days: 7 })), 'opportunities'), [2], 'exact Sao Paulo midnight and current-time boundaries are inclusive');

  // Detail truncation is a presentation bound only; totals must use every physical observation.
  seed(Array.from({ length: 205 }, (_, index) => opportunity({ slot_key: `slot-${String(index).padStart(3, '0')}` }, { view: true })).flat());
  result = query();
  equal(details(result).length, 201, 'detail is bounded at 201 rows');
  equal(metric(total(result), 'opportunities', 'slot_views', 'total_rows'), [205, 205, 205], 'full physical totals and group count are computed before the detail bound');
  equal(details(result)[0].slot_key, 'slot-000', 'equal-volume detail rows have stable ordering');
  equal(details(result).at(-1).slot_key, 'slot-200', 'stable ordering keeps the same bounded slice');

  equal(sql("SELECT has_schema_privilege(current_user,'audience','USAGE') AND has_table_privilege(current_user,'audience.events','SELECT') AND NOT has_table_privilege(current_user,'audience.events','INSERT,UPDATE,DELETE,TRUNCATE');", 'capacity_reader'), 't', 'all report executions use a schema/table SELECT-only role');
  console.log(`Audience capacity SQL: ${checks} assertions passed against isolated PostgreSQL as SELECT-only role.`);
} finally {
  if (started) run('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'immediate', '-w', 'stop']);
  rmSync(scratch, { recursive: true, force: true });
}
