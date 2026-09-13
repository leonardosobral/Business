#!/usr/bin/env node
// Real PostgreSQL on an isolated Unix socket; never reads application or production DB settings.
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-occupancy-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const asOf = '2026-09-12T15:00:00Z';
const ids = { delivery_id: '10000000-0000-4000-8000-000000000001', campaign_id: '20000000-0000-4000-8000-000000000001' };
const formats = ['all', 'ads', 'banners', 'other'];
const metrics = ['registered', 'potential', 'filled', 'empty', 'unclassified'];
let checks = 0;
let extensionChecks = 0;
let sequence = 0;
let started = false;
const equal = (actual, expected, message) => { assert.deepEqual(actual, expected, message); checks++; };
const extensionEqual = (actual, expected, message) => { assert.deepEqual(actual, expected, message); extensionChecks++; };
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
  visitor_uf: 'SP', profile_uf: 'RJ', context_uf: 'SC', market_uf: 'SC',
  page_family: 'home', page_path: '/', device_class: 'DESKTOP', slot_key: 'rr-home-upcoming-native',
  placement_key: '', slot_state: 'empty', delivery_id: null, campaign_id: null, ...overrides
});
const opportunity = (overrides = {}, { view = true, ad = false } = {}) => {
  const pageId = page();
  return [event(pageId, 'slot_opportunity', overrides),
    ...(view ? [event(pageId, 'slot_viewable', overrides)] : []),
    ...(ad ? [event(pageId, 'ad_viewable', { ...overrides, ...ids, slot_state: 'filled' })] : [])];
};
const seed = events => {
  sql('TRUNCATE audience.events;');
  if (!events.length) return;
  const columns = Object.keys(events[0]);
  sql(`INSERT INTO audience.events (${columns.join(',')}) VALUES ${events.map(row =>
    `(${columns.map(column => literal(row[column] ?? null)).join(',')})`).join(',')};`);
};
const executeReport = (name, overrides = {}) => {
  const params = { days: 30, environment: 'prod', include_internal: false,
    region_dimension: 'market', uf: '', page_family: '', device_class: '', ...overrides };
  let statement = readFileSync(resolve(root, `portal/audiencia/queries/${name}.sql`), 'utf8');
  for (const [marker, fragment] of [['/* AUDIENCE_OCCUPANCY_BASE */', 'occupancy_base'], ['/* AUDIENCE_FILTER */', 'filter']]) {
    if (statement.includes(marker)) statement = statement.replace(marker,
      readFileSync(resolve(root, `portal/audiencia/queries/${fragment}.sql`), 'utf8'));
  }
  // Fixed test clock is substituted only here; the production query has no test clock parameter.
  statement = statement.replace(/\bnow\(\)/g, `${literal(asOf)}::timestamptz`);
  for (const [key, value] of Object.entries(params)) {
    statement = statement.replace(new RegExp(`(?<!:):${key}\\b`, 'g'), literal(value));
  }
  return JSON.parse(sql(`BEGIN READ ONLY;
    SELECT coalesce(json_agg(r),'[]'::json) FROM (${statement.trim().replace(/;$/, '')}) r;
    COMMIT;`, 'occupancy_reader'));
};
const query = (overrides = {}) => {
  const rows = executeReport('occupancy', overrides);
  equal(rows.map(row => row.format), formats, 'all selections return four ordered format rows');
  for (const row of rows) {
    assert.ok(metrics.every(key => Number.isSafeInteger(row[key]) && row[key] >= 0), 'counts are nonnegative integers');
    assert.equal(row.potential, row.filled + row.empty + row.unclassified, `${row.format}: occupancy reconciles`);
    assert.ok(row.registered >= row.potential, `${row.format}: opportunities need a registered physical position`);
  }
  for (const key of metrics) assert.equal(rows[0][key], rows.slice(1).reduce((sum, row) => sum + row[key], 0), `${key}: categories partition total`);
  checks += 17;
  verifyRegions(overrides);
  return rows;
};
const verifyRegions = (overrides = {}) => {
  const rows = executeReport('occupancy_regions', overrides);
  const regions = [...new Set(rows.map(row => row.audience_uf))];
  extensionEqual(regions, [...regions].sort(), 'regional report orders observed UFs deterministically');
  const selected = executeReport('occupancy', overrides)[0];
  extensionEqual(rows.length > 0, selected.registered > 0, 'regional output cannot silently omit all registered observations');
  if (overrides.uf) extensionEqual(regions, selected.registered > 0 ? [overrides.uf] : [],
    'UF selection returns exactly its observed region or no region');
  for (const audienceUf of regions) {
    const regional = rows.filter(row => row.audience_uf === audienceUf)
      .map(({ audience_uf, ...counts }) => counts);
    extensionEqual(regional.map(row => row.format), formats, `${audienceUf}: four format rows including explicit zero counts`);
    extensionEqual(regional, executeReport('occupancy', { ...overrides, uf: audienceUf }),
      `${audienceUf}: one regional query equals the original selected-UF semantics`);
  }
  return rows;
};
const count = (rows, format = 'all') => metrics.map(key => rows.find(row => row.format === format)[key]);
const compareCapacity = (overrides = {}) => {
  const occupancy = query(overrides)[0];
  const capacity = executeReport('capacity', overrides).find(row => row.row_type === 'total');
  equal(occupancy.registered, capacity.opportunities,
    'commercial selection agrees with capacity physical registered totals');
};

try {
  // Expected RED before implementation: explicit missing-query assertion, not a connection failure.
  equal(existsSync(resolve(root, 'portal/audiencia/queries/occupancy.sql')), true, 'occupancy query must exist');
  for (const name of ['occupancy_base', 'occupancy_regions', 'coverage_paths']) {
    extensionEqual(existsSync(resolve(root, `portal/audiencia/queries/${name}.sql`)), true, `${name} query must exist`);
  }
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'),
    '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
  started = true;
  sql(`CREATE SCHEMA audience;
    CREATE TABLE audience.events (
      page_view_id uuid NOT NULL, event_key text NOT NULL, event_kind text NOT NULL,
      occurred_at timestamptz NOT NULL, received_at timestamptz NOT NULL,
      environment text, is_internal boolean, visitor_uf text, profile_uf text, context_uf text, market_uf text,
      page_family text, page_path text, device_class text, slot_key text, placement_key text, slot_state text,
      visitor_id uuid, session_id uuid, content_type text DEFAULT '', content_id text DEFAULT '',
      source text DEFAULT 'direct', medium text DEFAULT '(none)', campaign text DEFAULT '', creative text DEFAULT '',
      active_ms integer DEFAULT 0,
      delivery_id uuid, campaign_id uuid, PRIMARY KEY (page_view_id,event_key));
    CREATE ROLE occupancy_reader LOGIN;
    GRANT USAGE ON SCHEMA audience TO occupancy_reader;
    GRANT SELECT ON audience.events TO occupancy_reader;`);

  equal(query().map(row => count([row], row.format)), Array(4).fill([0, 0, 0, 0, 0]), 'empty evidence has four explicit zero rows');
  compareCapacity();

  // Regression: empty no-candidate markers are collapsed and never produce render or view events.
  seed(Array.from({ length: 200 }, () => opportunity({ market_uf: 'AC' }, { view: false })).flat());
  equal(count(query({ uf: 'AC' })), [200, 200, 0, 200, 0], '200 Acre opportunities without a candidate remain 200 empty delivery opportunities');
  equal(executeReport('capacity', { uf: 'AC' }).find(row => row.row_type === 'total').slot_views, 0,
    'delivery opportunities do not fabricate one-second visibility');

  for (const kind of ['slot_opportunity', 'slot_served', 'slot_render', 'slot_viewable', 'ad_render', 'ad_viewable']) {
    const p = page();
    seed([event(p, 'slot_opportunity', { slot_state: kind === 'slot_opportunity' ? 'filled' : 'pending' }),
      ...(kind === 'slot_opportunity' ? [] : [event(p, kind, { slot_state: 'filled', ...(kind.startsWith('ad_') ? ids : {}) })])]);
    equal(count(query()), [1, 1, 1, 0, 0], `${kind} filled evidence occupies a registered position without any other view signal`);
    if (!kind.includes('viewable')) equal(executeReport('capacity').find(row => row.row_type === 'total').slot_views, 0,
      `${kind} delivery outside the viewport never fabricates a one-second slot view`);
  }

  for (const [states, want] of [
    [['pending', 'empty'], [1, 1, 0, 1, 0]],
    [['empty', 'pending'], [1, 1, 0, 0, 1]],
    [['pending', 'not_applicable'], [1, 0, 0, 0, 0]],
    [['not_applicable'], [1, 0, 0, 0, 0]],
    [['hidden'], [1, 0, 0, 0, 0]],
    [['pending'], [1, 1, 0, 0, 1]],
    [['error', 'empty'], [1, 1, 0, 0, 1]],
    [['empty', 'error'], [1, 1, 0, 0, 1]],
    [['disabled', 'empty'], [1, 1, 0, 0, 1]],
    [['', 'empty'], [1, 1, 0, 0, 1]],
    [[null, 'empty'], [1, 1, 0, 0, 1]],
    [['not_applicable', 'empty'], [1, 1, 0, 0, 1]],
    [['disabled', 'filled'], [1, 1, 1, 0, 0]],
    [['hidden', 'house'], [1, 1, 1, 0, 0]]
  ]) {
    const p = page();
    seed(states.map((slot_state, index) => event(p, index === 0 ? 'slot_opportunity' : 'slot_render', {
      slot_state, occurred_at: date(-1, `12:00:0${index}`), received_at: date(-1, `12:00:0${index}`)
    })));
    equal(count(query()), want, `${states.join(' then ')} respects terminal evidence and operational uncertainty`);
  }

  for (const [scState, spState, want] of [
    ['not_applicable', 'hidden', [1, 0, 0, 0, 0]],
    ['not_applicable', 'empty', [1, 1, 0, 1, 0]],
    ['not_applicable', 'pending', [1, 1, 0, 0, 1]],
    ['empty', 'pending', [1, 1, 0, 0, 1]],
    ['empty', 'filled', [1, 1, 1, 0, 0]]
  ]) {
    const p = page();
    seed([event(p, 'slot_opportunity', { slot_state: scState }),
      event(p, 'slot_opportunity', { slot_state: spState, market_uf: 'SP' })]);
    equal(count(query()), want, `selected UFs ${scState}/${spState} reconcile one physical opportunity`);
  }

  const simultaneous = page();
  seed([event(simultaneous, 'slot_opportunity', { slot_state: 'pending', event_key: 'z-pending' }),
    event(simultaneous, 'slot_render', { slot_state: 'empty', event_key: 'a-empty' })]);
  equal(count(query()), [1, 1, 0, 1, 0], 'terminal evidence at the same timestamp resolves pending regardless of opaque event-key order');

  // Eight opportunities: four filled (one house), two empty, two unresolved.
  const basic = [
    ...opportunity({ slot_state: 'filled' }),
    ...opportunity({ slot_key: 'rr-sidebar-banner-desktop', slot_state: 'house' }),
    ...opportunity({ slot_state: 'disabled' }, { ad: true }),
    ...opportunity(),
    ...opportunity({ slot_key: 'rr-home-banner-mobile' }),
    ...opportunity({ slot_key: 'rr-sidebar-banner-mobile', slot_state: 'disabled' }),
    ...opportunity({ slot_state: 'pending' }, { view: false }),
    ...opportunity({}, { view: false, ad: true }),
    event(page(), 'ad_viewable', { ...ids, slot_state: 'filled' })
  ];
  seed(basic);
  equal(count(query()), [8, 8, 4, 2, 2], 'delivery evidence fills a registered position without requiring visibility; orphan ads create no position');
  equal(count(query(), 'ads'), [5, 5, 3, 1, 1], 'Ads counts include their nonvisible physical opportunities');
  equal(count(query(), 'banners'), [3, 3, 1, 1, 1], 'house banner counts as occupied and disabled is unclassified');
  compareCapacity();

  const shared = page();
  const crossUf = page();
  const uncertainUf = page();
  const allEmpty = page();
  const mixed = [
    event(shared, 'slot_opportunity', { occurred_at: date(-2) }),
    event(shared, 'slot_opportunity', { page_family: 'search', device_class: 'MOBILE', placement_key: 'rr-sidebar-banner-300x250' }),
    event(shared, 'slot_viewable', { page_family: 'search', device_class: 'MOBILE', slot_state: 'empty' }),
    event(shared, 'ad_viewable', { ...ids, slot_state: 'filled' }),
    event(shared, 'ad_viewable', { ...ids, delivery_id: page(), slot_state: 'house' }),
    event(shared, 'slot_opportunity', { market_uf: 'SP' }),
    event(shared, 'slot_viewable', { market_uf: 'SP', slot_state: 'empty' }),
    event(crossUf, 'slot_opportunity'), event(crossUf, 'slot_viewable'),
    event(crossUf, 'slot_opportunity', { market_uf: 'SP' }),
    event(crossUf, 'ad_viewable', { market_uf: 'SP', ...ids, slot_state: 'filled' }),
    event(uncertainUf, 'slot_opportunity'), event(uncertainUf, 'slot_viewable'),
    event(uncertainUf, 'slot_opportunity', { market_uf: 'SP' }),
    event(uncertainUf, 'slot_viewable', { market_uf: 'SP', slot_state: 'disabled' }),
    event(allEmpty, 'slot_opportunity'), event(allEmpty, 'slot_viewable'),
    event(allEmpty, 'slot_opportunity', { market_uf: 'SP' }),
    event(allEmpty, 'slot_viewable', { market_uf: 'SP' })
  ];
  seed(mixed);
  equal(count(query()), [4, 4, 2, 1, 1], 'rotation and multiple UFs collapse physically, after regional fill evidence is established');
  equal(count(query({ uf: 'SC' })), [4, 4, 1, 3, 0], 'SC cannot borrow an SP ad view for filling');
  equal(count(query({ uf: 'SP' })), [4, 4, 1, 2, 1], 'SP registered context can use its own ad delivery without slot visibility');
  equal(count(query({ page_family: 'search' })), [0, 0, 0, 0, 0], 'later opportunity and view metadata cannot move first opportunity family');
  equal(count(query({ device_class: 'MOBILE' })), [0, 0, 0, 0, 0], 'later signals cannot move first opportunity device');
  equal(count(query(), 'other'), [0, 0, 0, 0, 0], 'later placement does not change first opportunity format');
  for (const overrides of [{}, { uf: 'SC' }, { uf: 'SP' }, { page_family: 'search' }, { device_class: 'MOBILE' }]) compareCapacity(overrides);

  // Partial IDs and unknown states cannot manufacture occupied or confirmed-empty space.
  const invalidAds = [];
  for (const [slotState, adOverrides] of [
    ['empty', { delivery_id: null }], ['empty', { campaign_id: null }],
    ['empty', { slot_state: 'disabled' }], ['disabled', { slot_state: 'empty' }],
    ['empty', { slot_state: 'empty' }], ['filled', { delivery_id: null }]
  ]) {
    const p = page();
    invalidAds.push(event(p, 'slot_opportunity'), event(p, 'slot_viewable', { slot_state: slotState }),
      event(p, 'ad_viewable', { ...ids, slot_state: 'filled', ...adOverrides }));
  }
  const conflicting = page();
  seed([...invalidAds,
    ...['pending', 'hidden', 'not_applicable', 'error', '', null].flatMap(slot_state => opportunity({ slot_state })),
    event(conflicting, 'slot_opportunity'), event(conflicting, 'slot_viewable'),
    event(conflicting, 'slot_viewable', { slot_state: null }),
    ...opportunity({ slot_state: 'filled' }, { view: false }),
    event(page(), 'slot_render', { slot_state: 'filled' })
  ]);
  equal(count(query()), [14, 12, 2, 0, 10], 'only affirmative hidden/inapplicable positions are excluded; malformed evidence is unresolved and valid fill wins');
  compareCapacity();

  // Keys and placements are explicit allowlists; similar spelling never implies a format.
  const adKeys = ['rr-home-upcoming-native', 'rr-home-upcoming-native-secondary', 'rr-search-events-native', 'rr-state-events-native', 'rr-sidebar-event-native'];
  const bannerKeys = ['rr-sidebar-banner-desktop', 'rr-sidebar-banner-mobile', 'rr-home-banner-mobile', 'rr-search-banner-mobile', 'rr-state-banner-mobile', 'rr-feed-banner-desktop', 'rr-legacy-sidebar-promo', 'rr-legacy-sidebar-marathons', 'rr-channel-sidebar-promo', 'rr-challenge-detail-promo', 'rr-profile-sidebar-promo'];
  const bannerPlacements = ['rr-sidebar-banner-300x250', 'rr-sidebar-static-promo', 'rr-content-static-promo'];
  seed([
    ...adKeys.flatMap(slot_key => opportunity({ slot_key })),
    ...adKeys.flatMap(placement_key => opportunity({ slot_key: 'dynamic-position', placement_key })),
    ...bannerKeys.flatMap(slot_key => opportunity({ slot_key })),
    ...bannerPlacements.flatMap(placement_key => opportunity({ slot_key: 'dynamic-position', placement_key })),
    ...['unknown', 'looks-banner', 'rr-home-upcoming-native-extra', 'rr-sidebar-banner-desktop-extra'].flatMap(slot_key => opportunity({ slot_key })),
    ...opportunity({ placement_key: 'rr-sidebar-banner-300x250' }),
    ...opportunity({ slot_key: 'rr-home-banner-mobile', placement_key: 'rr-home-upcoming-native' })
  ]);
  equal(count(query()), [30, 30, 0, 30, 0], 'recognized and unknown formats all contribute to physical total');
  equal(count(query(), 'ads'), [10, 10, 0, 10, 0], 'all five Ads keys and placements are classified');
  equal(count(query(), 'banners'), [14, 14, 0, 14, 0], 'all eleven banner keys and three placements are classified');
  equal(count(query(), 'other'), [6, 6, 0, 6, 0], 'unknown and contradictory metadata is preserved under other');
  compareCapacity();

  const categoryOverlap = page();
  seed([
    event(categoryOverlap, 'slot_opportunity', { slot_key: 'dynamic', placement_key: 'rr-home-upcoming-native' }),
    event(categoryOverlap, 'slot_viewable', { slot_key: 'dynamic' }),
    event(categoryOverlap, 'slot_opportunity', { slot_key: 'dynamic', market_uf: 'SP', page_family: 'search', device_class: 'MOBILE', placement_key: 'rr-sidebar-banner-300x250' }),
    event(categoryOverlap, 'slot_viewable', { slot_key: 'dynamic', market_uf: 'SP' })
  ]);
  equal(count(query(), 'other'), [1, 1, 0, 1, 0], 'conflicting regional formats cannot double-allocate a physical position');
  equal(count(query({ uf: 'SC' }), 'ads'), [1, 1, 0, 1, 0], 'UF selection occurs before physical category reconciliation');
  equal(count(query({ page_family: 'search', device_class: 'MOBILE' }), 'banners'), [1, 1, 0, 1, 0], 'filters retain first metadata for each regional observation');

  seed([
    ...opportunity(), ...opportunity({ market_uf: '', visitor_uf: '', profile_uf: '', context_uf: '' }),
    ...opportunity({ is_internal: true, slot_state: 'house' }),
    ...opportunity({ environment: 'dev', slot_state: 'filled' }),
    ...opportunity({ environment: 'beta', slot_state: 'disabled' }),
    ...opportunity({ environment: 'local', slot_state: 'empty' })
  ]);
  equal(count(query({ uf: 'SC' })), [1, 1, 0, 1, 0], 'SP resident consuming SC content contributes to SC commercial observation');
  equal(count(query({ uf: 'SP' })), [0, 0, 0, 0, 0], 'visitor residence does not override commercial region');
  equal(count(query({ region_dimension: 'visitor', uf: 'SP' })), [1, 1, 0, 1, 0], 'visitor diagnostic uses visitor UF');
  equal(count(query({ region_dimension: 'profile', uf: 'RJ' })), [1, 1, 0, 1, 0], 'profile diagnostic uses profile UF');
  equal(count(query({ region_dimension: 'context', uf: 'SC' })), [1, 1, 0, 1, 0], 'context diagnostic uses context UF');
  equal(count(query({ uf: '--' })), [1, 1, 0, 1, 0], 'unknown UF stays explicitly selectable');
  equal(count(query({ include_internal: true })), [3, 3, 1, 2, 0], 'internal diagnostic includes internal and external observations');
  equal(count(query({ environment: 'dev' })), [1, 1, 1, 0, 0], 'development remains available for diagnosis');
  equal(count(query({ environment: 'beta' })), [1, 1, 0, 0, 1], 'beta remains available for diagnosis');
  equal(count(query({ environment: 'local' })), [1, 1, 0, 1, 0], 'local remains available for diagnosis');
  for (const [key, value] of [['uf', "SC' OR true --"], ['page_family', "home' OR true --"],
    ['device_class', "DESKTOP' OR true --"], ['environment', "prod' OR true --"]]) {
    equal(count(query({ [key]: value })), [0, 0, 0, 0, 0], `${key} injection-shaped values remain literals`);
  }
  compareCapacity();

  const futureSignal = page();
  const oldSignal = page();
  const midnight = page();
  const outsideOpportunity = page();
  seed([
    event(futureSignal, 'slot_opportunity'),
    event(futureSignal, 'slot_viewable', { occurred_at: date(0, '12:00:01') }),
    event(oldSignal, 'slot_opportunity'),
    event(oldSignal, 'slot_viewable', { occurred_at: date(-30) }),
    event(midnight, 'slot_opportunity', { occurred_at: date(-2, '23:59:00') }),
    event(midnight, 'slot_viewable', { occurred_at: date(-1, '00:01:00') }),
    event(midnight, 'ad_viewable', { ...ids, slot_state: 'filled', occurred_at: date(0, '12:00:01') }),
    event(outsideOpportunity, 'slot_opportunity', { occurred_at: date(-30) }),
    event(outsideOpportunity, 'slot_viewable'),
    event(page(), 'slot_viewable'),
    ...opportunity({ slot_key: '' }),
    ...opportunity({ occurred_at: date(1) }),
    ...opportunity({ occurred_at: date(-40) })
  ]);
  equal(count(query()), [3, 3, 0, 3, 0], 'orphan, old and future signals never leak across the inclusive occurred-at selection');
  compareCapacity();
  seed([-90, -89, -30, -29, -7, -6, -1, 0, 1].flatMap(offset => opportunity({ occurred_at: date(offset) })));
  for (const [days, want] of [[7, 3], [30, 5], [90, 7]]) {
    equal(count(query({ days })), [want, want, 0, want, 0], `${days} days includes today and prior calendar days only`);
    compareCapacity({ days });
  }
  seed(['2026-09-06T02:59:59Z', '2026-09-06T03:00:00Z', '2026-09-12T15:00:00Z', '2026-09-12T15:00:01Z']
    .flatMap(occurred_at => opportunity({ occurred_at })));
  equal(count(query({ days: 7 })), [2, 2, 0, 2, 0], 'Brasilia midnight and now are inclusive, adjacent seconds are excluded');
  compareCapacity({ days: 7 });

  seed(Array.from({ length: 205 }, (_, index) => opportunity({ slot_key: `slot-${index}` })).flat());
  equal(count(query()), [205, 205, 0, 205, 0], 'totals use all 205 physical positions and never a bounded detail list');
  equal(count(query(), 'other'), [205, 205, 0, 205, 0], 'unknown positions remain reconciled in other');
  compareCapacity();
  equal(sql("SELECT has_schema_privilege(current_user,'audience','USAGE') AND has_table_privilege(current_user,'audience.events','SELECT') AND NOT has_table_privilege(current_user,'audience.events','INSERT,UPDATE,DELETE,TRUNCATE');", 'occupancy_reader'), 't', 'every report execution uses SELECT-only role');
  extensionEqual(checks, 1565, 'all 1565 original occupancy assertions remain executed');

  seed([]);
  extensionEqual(verifyRegions(), [], 'no opportunity evidence means no observed UF rows');
  seed(Array.from({ length: 200 }, () => opportunity({ market_uf: 'AC' }, { view: false })).flat());
  extensionEqual(count(verifyRegions().filter(row => row.audience_uf === 'AC')), [200, 200, 0, 200, 0],
    'regional Acre reports all 200 empty opportunities without requiring visibility');
  extensionEqual(verifyRegions({ uf: 'SP' }), [], 'a selected UF without opportunities creates no regional rows');

  const sharedAcre = page();
  seed([event(sharedAcre, 'slot_opportunity', { market_uf: 'AC' }),
    event(sharedAcre, 'slot_opportunity', { market_uf: 'SP', slot_state: 'filled' })]);
  const acreOverlap = verifyRegions();
  extensionEqual(count(acreOverlap.filter(row => row.audience_uf === 'AC')), [1, 1, 0, 1, 0], 'SP fill never fills Acre on the same page');
  extensionEqual(count(acreOverlap.filter(row => row.audience_uf === 'SP')), [1, 1, 1, 0, 0], 'SP keeps its own fill evidence on the same page');
  extensionEqual(count(executeReport('occupancy')), [1, 1, 1, 0, 0], 'global physical opportunity remains one despite two regional observations');
  extensionEqual(acreOverlap.filter(row => row.format === 'all').reduce((sum, row) => sum + row.potential, 0), 2,
    'regional potential can overlap and is not a global physical total');

  seed([
    ...opportunity({ market_uf: 'AC', slot_state: 'hidden' }, { view: false }),
    ...opportunity({ market_uf: 'SP', slot_state: 'not_applicable' }, { view: false }),
    ...opportunity({ market_uf: 'RJ', slot_state: 'pending' }, { view: false }),
    ...opportunity({ market_uf: 'BA', slot_state: 'house', slot_key: 'rr-home-banner-mobile' }, { view: false }),
    ...opportunity({ market_uf: '', visitor_uf: '', profile_uf: '', context_uf: '', slot_key: 'legacy_unknown' }, { view: false }),
    event(page(), 'page_view', { market_uf: 'AM' }),
    event(page(), 'slot_viewable', { market_uf: 'AP' }),
    event(page(), 'slot_opportunity', { market_uf: 'ES', slot_key: '' })
  ]);
  const regionalStates = verifyRegions();
  extensionEqual([...new Set(regionalStates.map(row => row.audience_uf))], ['--', 'AC', 'BA', 'RJ', 'SP'],
    'observed UFs require nonempty-slot opportunities, not page views or orphan visibility');
  extensionEqual(count(regionalStates.filter(row => row.audience_uf === 'AC')), [1, 0, 0, 0, 0], 'inactive Acre remains registered with zero potential');
  extensionEqual(count(regionalStates.filter(row => row.audience_uf === 'SP')), [1, 0, 0, 0, 0], 'inapplicable SP remains registered with zero potential');
  extensionEqual(count(regionalStates.filter(row => row.audience_uf === 'RJ')), [1, 1, 0, 0, 1], 'pending region remains explicitly unclassified');
  extensionEqual(count(regionalStates.filter(row => row.audience_uf === 'BA'), 'banners'), [1, 1, 1, 0, 0], 'house banners fill the correct regional format');
  extensionEqual(count(regionalStates.filter(row => row.audience_uf === '--'), 'other'), [1, 1, 0, 1, 0], 'unknown UF and format remain represented');

  const coverageCounts = rows => ['pageviews', 'pages_with_slots', 'opportunities', 'slot_views']
    .map(key => rows.reduce((sum, row) => sum + row[key], 0));
  const verifyCoverage = (overrides = {}) => {
    const rows = executeReport('coverage_paths', overrides);
    const family = executeReport('coverage', overrides).filter(row => row.page_family === 'other');
    extensionEqual(coverageCounts(rows), coverageCounts(family), 'folder breakdown reconciles with coverage for one persisted folder per page');
    extensionEqual(rows.every(row => row.page_folder === '' || /^\/[A-Za-z0-9_-]+\/$/.test(row.page_folder)), true,
      'folder output is always a canonical safe first segment or the unidentified bucket');
    return rows;
  };
  seed([]);
  extensionEqual(verifyCoverage(), [], 'empty coverage has no invented folder rows');
  const routePage = page();
  seed([
    event(routePage, 'page_view', { page_family: 'other', page_path: '/arena/legacy/item/' }),
    event(routePage, 'slot_opportunity', { page_family: 'other', page_path: '/arena/legacy/item/' }),
    event(routePage, 'slot_opportunity', { page_family: 'other', page_path: '/arena/legacy/item/' }),
    event(routePage, 'slot_viewable', { page_family: 'other', page_path: '/arena/legacy/item/' }),
    event(routePage, 'slot_viewable', { page_family: 'other', page_path: '/arena/legacy/item/' }),
    event(routePage, 'slot_render', { page_family: 'other', page_path: '/arena/legacy/item/', received_at: date(0) }),
    event(page(), 'page_view', { page_family: 'other', page_path: '/arena/' }),
    ...opportunity({ page_family: 'other', page_path: '/legacy_Route-2020/template/' }, { view: false }),
    event(page(), 'page_view', { page_family: 'home', page_path: '/arena/' })
  ]);
  const paths = verifyCoverage();
  extensionEqual(paths.map(row => row.page_folder), ['/arena/', '/legacy_Route-2020/'], 'valid historical templates group by their first persisted segment');
  extensionEqual(coverageCounts(paths.filter(row => row.page_folder === '/arena/')), [2, 1, 2, 2], 'coverage retains raw signals and distinct pages within each folder');
  extensionEqual(new Date(paths[0].last_received).getTime(), new Date(asOf).getTime(), 'latest reception includes non-counted signals as in coverage');
  extensionEqual(executeReport('coverage_paths', { page_family: 'home' }), [], 'only other is broken down even when another family is selected');

  seed(['/arena', '/Arena/', '/OLD_Route-2020/deep/template/', `/${'a'.repeat(255)}`]
    .map(page_path => event(page(), 'page_view', { page_family: 'other', page_path })));
  extensionEqual(verifyCoverage().map(row => row.page_folder), ['/Arena/', '/OLD_Route-2020/', `/${'a'.repeat(255)}/`, '/arena/'],
    'case, historical segments and maximal safe segment survive normalization; a trailing slash is added');

  const unsafePaths = ['', '/', null, '//arena/', '/arena//leaf/', '/arena/../admin/', '/./arena/', '/../arena/',
    '/arena?token=secret', '/arena/#fragment', 'https://example.invalid/arena/', 'arena/path', '/arena/%2e%2e/',
    '/arena/with space/', '/arena/with\\slash/', '/arena/<script>/', '/arena/\nleaf/', `/${'a'.repeat(256)}`];
  seed(unsafePaths.map(page_path => event(page(), 'page_view', { page_family: 'other', page_path })));
  const unsafe = verifyCoverage();
  extensionEqual(unsafe.length, 1, 'unsafe, missing and root paths collapse into one unidentified bucket');
  extensionEqual(unsafe[0].page_folder, '', 'unidentified folder is an empty data value for the UI label');
  extensionEqual(unsafe[0].pageviews, unsafePaths.length, 'unsafe paths remain counted without exposing their strings');

  seed(Array.from({ length: 205 }, (_, index) => event(page(), 'page_view', {
    page_family: 'other', page_path: `/historical_${index}/template/`
  })));
  extensionEqual(verifyCoverage().length, 205, 'all 205 distinct folders are grouped without top-N truncation');

  seed([
    ...opportunity({ page_family: 'other', page_path: '/arena/', market_uf: 'AC' }, { view: false }),
    ...opportunity({ page_family: 'other', page_path: '/old/', market_uf: '', visitor_uf: '', profile_uf: '', context_uf: '', device_class: 'MOBILE' }),
    ...opportunity({ page_family: 'other', page_path: '/internal/', is_internal: true }),
    ...opportunity({ page_family: 'other', page_path: '/development/', environment: 'dev' }),
    ...opportunity({ page_family: 'other', page_path: '/old-period/', occurred_at: date(-40) }),
    ...opportunity({ page_family: 'other', page_path: '/future/', occurred_at: date(1) }),
    ...opportunity({ page_family: 'other', page_path: '/boundary/', occurred_at: '2026-09-06T03:00:00Z' })
  ]);
  for (const overrides of [{}, { uf: 'AC' }, { uf: '--' }, { uf: 'SP' }, { region_dimension: 'visitor', uf: 'SP' },
    { region_dimension: 'profile', uf: 'RJ' }, { region_dimension: 'context', uf: 'SC' }, { include_internal: true },
    { environment: 'dev' }, { days: 7 }, { days: 90 }, { device_class: 'MOBILE' }, { page_family: 'other' },
    { uf: "SC' OR true --" }, { page_family: "other' OR true --" }, { device_class: "MOBILE' OR true --" },
    { environment: "prod' OR true --" }]) verifyCoverage(overrides);
  extensionEqual(verifyCoverage({ uf: 'AC' }).map(row => row.page_folder), ['/arena/'], 'commercial UF filters the folder evidence');
  extensionEqual(verifyCoverage({ environment: 'dev' }).map(row => row.page_folder), ['/development/'], 'environment filter applies to folder evidence');
  console.log(`Audience occupancy SQL: ${checks} original assertions plus ${extensionChecks} regional/coverage assertions passed against isolated PostgreSQL as SELECT-only role.`);
} finally {
  if (started) run('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'immediate', '-w', 'stop']);
  rmSync(scratch, { recursive: true, force: true });
}
