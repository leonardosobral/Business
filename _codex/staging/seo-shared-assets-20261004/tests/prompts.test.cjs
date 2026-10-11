const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('/Users/Shared/Projects/RunnerHub/Business/_codex/staging/seo-shared-assets-20261004/candidate/assets/js/runnerhub-entry-prompts.min.js', 'utf8');
function fixture(seen = false) {
  let now = 0, pending = [], blocking = false, editing = false;
  const events = {}, storage = new Map(seen ? [['rr.entry.optionalPrompt.v1', '1']] : []);
  const document = {hidden:false,body:{classList:{contains:()=>false}},activeElement:{matches:()=>editing},querySelector:()=>blocking ? {} : null,addEventListener:(n,f)=>events[n]=f};
  const window = {sessionStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},setTimeout:f=>{pending.push(f);return pending.length;},addEventListener:(n,f)=>events[n]=f};
  vm.runInNewContext(source,{window,document,Date:{now:()=>now}});
  return {api:window.RREntryPrompts,storage,document,engage:()=>events.pointerdown({isTrusted:true}),block:v=>blocking=v,edit:v=>editing=v,advance:async(ms)=>{now+=ms;const jobs=pending;pending=[];for(const f of jobs)await f();}};
}
test('waits for interaction and at least 20 seconds', async()=>{
  const f=fixture();let calls=0;f.api.enqueue('a',()=>++calls);
  await f.advance(25000);assert.equal(calls,0);
  f.engage();await f.advance(1000);assert.equal(calls,1);
});
test('does not interrupt early interaction', async()=>{
  const f=fixture();let calls=0;f.api.enqueue('a',()=>++calls);f.engage();
  await f.advance(1000);assert.equal(calls,0);
  await f.advance(19000);assert.equal(calls,1);
});
test('privacy dialogs, cookies and focused fields postpone prompts', async()=>{
  const f=fixture();let calls=0;f.api.enqueue('a',()=>++calls);f.engage();f.block(true);
  await f.advance(25000);assert.equal(calls,0);
  f.block(false);f.edit(true);await f.advance(1000);assert.equal(calls,0);
  f.edit(false);await f.advance(1000);assert.equal(calls,1);
});
test('priority and at most one optional prompt per session', async()=>{
  const f=fixture(),shown=[];f.api.enqueue('install',()=>shown.push('install'),10);f.api.enqueue('strava',()=>shown.push('strava'),30);
  f.engage();await f.advance(21000);await f.advance(21000);assert.deepEqual(shown,['strava']);
  assert.equal(f.storage.get('rr.entry.optionalPrompt.v1'),'1');
  const next=fixture(true);let called=false;next.api.enqueue('a',()=>called=true);next.engage();await next.advance(21000);assert.equal(called,false);
});
test('ineligible prompt does not consume the session allowance', async()=>{
  const f=fixture();let calls=0;f.api.enqueue('skip',()=>false,30);f.api.enqueue('next',()=>++calls,10);f.engage();
  await f.advance(21000);assert.equal(calls,0);await f.advance(1000);assert.equal(calls,1);
});
test('home limits count cards instead of style or context elements',()=>{
  const css=fs.readFileSync('assets/css/runnerhub-home.css','utf8');
  assert.match(css,/a\.home-compact-event-link:nth-of-type\(n\+5\)/);
  const home=fs.readFileSync('index.cfm','utf8');
  assert(home.indexOf('home-discovery-lists')<home.indexOf('<section data-home-async="news"'));
  assert(!home.includes('.home-compact-event-link:nth-child(n+5)'));
});
test('all home copy is available in every supported language',()=>{
  for(const lang of ['pt-BR','en','es']){
    const raw=fs.readFileSync('i18n/'+lang+'.cfm','utf8');
    const catalog=JSON.parse(raw.slice(raw.indexOf('{'),raw.indexOf('</cfsavecontent>')).trim());
    assert(catalog.home.discovery.headline);assert(catalog.home.discovery.cookieNotice);
  }
});
test('new home labels have a request-local fallback for stale catalogs',()=>{
  const helper=fs.readFileSync('includes/estrutura/home_discovery_copy.cfm','utf8');
  assert.match(helper,/duplicate\(VARIABLES\.localesCatalog\.home\.discovery\)/);
  for(const file of ['index.cfm','includes/estrutura/home_hero_busca.cfm','includes/estrutura/home_sidebar_guest_placeholder.cfm','includes/estrutura/entry_cookie_notice.cfm']){
    assert(!fs.readFileSync(file,'utf8').match(/REQUEST\.t\(["']home\.discovery\./),file);
  }
});
test('privacy controls are rendered only once and the notice can open them independently',()=>{
  const controls=fs.readFileSync('includes/analytics/privacy_controls.cfm','utf8');
  const notice=fs.readFileSync('includes/estrutura/entry_cookie_notice.cfm','utf8');
  assert.match(controls,/NOT structKeyExists\(REQUEST, "audiencePrivacyControlsRendered"\)/);
  assert.match(notice,/RoadRunnersAudiencePrivacy\.open\(event\)/);
});
test('home review keeps the original menu and reserves space around the state select',()=>{
  const home=fs.readFileSync('index.cfm','utf8');
  const css=fs.readFileSync('assets/css/runnerhub-home.css','utf8');
  assert(!home.includes('rr-desktop-nav-label'));
  assert(!css.includes('rr-desktop-nav-label'));
  assert.match(css,/\.home-hero-chip:not\(\.home-hero-chip-select\)\{padding:/);
  assert(!css.match(/\.rr-home \.home-hero-chip\{padding:/));
});
test('desktop news uses a balanced row while the mobile summary stays hidden',()=>{
  const css=fs.readFileSync('assets/css/runnerhub-home.css','utf8');
  assert.match(css,/\.rr-home \.home-news-stack-summary\{display:none\}/);
  const desktop=css.slice(css.indexOf('@media(min-width:992px)'),css.indexOf('@media(max-width:991.98px)'));
  assert.match(desktop,/grid-template-columns:repeat\(3,minmax\(0,1fr\)\)/);
  assert.match(desktop,/\.home-news-top-stack\{display:contents\}/);
  assert.match(css,/\.home-news-top-stack \.home-content-card\{display:grid;grid-template-columns:104px minmax\(0,1fr\)/);
});
test('the sponsor group owns the bottom divider, not each ad',()=>{
  const css=fs.readFileSync('assets/css/runnerhub-home.css','utf8');
  const card=fs.readFileSync('includes/estrutura/home_event_compact_card.cfm','utf8');
  assert.match(css,/\.home-dual-section-header:has\(\.home-sponsored-slot\)\{border-bottom:/);
  assert(!/\.home-sponsored-slot\s*\{[^}]*border-bottom/.test(card));
});
test('the two original group images are included in the deployment source',()=>{
  for(const name of ['icon-512.png','icon-5121.png']){
    const data=fs.readFileSync('assets/chat/groups/'+name);
    assert.equal(data.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  }
});
test('guest sidebar styles are shared by the home and reused pages',()=>{
  const shared=fs.readFileSync('includes/estrutura/home_sidebar_shared_styles.cfm','utf8');
  const slot=fs.readFileSync('includes/estrutura/home_sidebar_async_slot.cfm','utf8');
  const home=fs.readFileSync('index.cfm','utf8');
  const homeCss=fs.readFileSync('assets/css/runnerhub-home.css','utf8');
  assert.match(shared,/\.home-join-card\s*\{/);
  assert.match(shared,/\.home-side-banner\s*\{/);
  assert.match(shared,/\.home-side-banner img\s*\{/);
  assert.match(slot,/home_sidebar_shared_styles\.cfm/);
  assert.match(home,/home_sidebar_shared_styles\.cfm/);
  assert(!/\.home-join-card\{border:/.test(homeCss));
});
