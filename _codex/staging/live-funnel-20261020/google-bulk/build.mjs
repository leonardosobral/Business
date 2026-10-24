import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { Workbook } from '@oai/artifact-tool';

const dir = new URL('./', import.meta.url);
const full = process.argv.includes('--full');
const output = full ? new URL('full-11/',dir) : dir;
await fs.mkdir(output,{recursive:true});
const campaign = 'RR | LIVE 2026 | Pesquisa por cidade | Cupom 15%';
const matrix = JSON.parse(await fs.readFile(new URL('../city-matrix.json', dir), 'utf8'));
const templates = JSON.parse(await fs.readFile(new URL('template-cells.json', dir), 'utf8'));
const selected = matrix.events.filter(e => e.selected);
assert.equal(selected.length, 11);
const slug = s => s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const copy = e => {
  const url = new URL(e.road_runners_url);
  url.search = new URLSearchParams({
    utm_source: 'google', utm_medium: 'cpc',
    utm_campaign: 'live_pesquisa_cidades_202610',
    utm_content: `${slug(e.city)}-${e.uf.toLowerCase()}`,
  }).toString();
  const headlines = [
    `LIVE! Run ${e.city}`,
    'Cupom LIVE! com 15% OFF',
    'Use o código ROADRUNNERS',
    `Corrida em ${e.city}`,
    'Inscrição LIVE! 2026',
    'Veja a prova e o cupom',
    'Corra com 15% de desconto',
    'Cupom para sua inscrição',
  ];
  const descriptions = [
    `LIVE! Run em ${e.city}: veja a prova e use ROADRUNNERS para 15% de desconto.`,
    'Confira data e distâncias no Road Runners. Copie o cupom e siga para a LIVE!.',
    'Acesse o cupom de 15% para esta etapa. Confira o desconto antes de pagar.',
    'Escolha sua distância e confira as condições da inscrição no site da LIVE!.',
  ];
  for (const h of headlines) assert.ok([...h].length <= 30, `Headline >30: ${h}`);
  for (const d of descriptions) assert.ok([...d].length <= 90, `Description >90: ${d}`);
  assert.equal(new Set(headlines).size, headlines.length);
  const city = slug(e.city).replaceAll('-', ' ');
  const keywords = [
    [`live run ${city}`, 'Phrase match'],
    [`live run ${city}`, 'Exact match'],
    [`cupom live run ${city}`, 'Phrase match'],
    [`cupom live run ${city}`, 'Exact match'],
    [`inscricao live run ${city}`, 'Phrase match'],
  ];
  assert.ok(e.canonical_circuit && e.coupon_active && e.coupon_in_html);
  assert.equal(e.coupon, 'ROADRUNNERS');
  assert.equal(e.discount, '15%');
  assert.equal(e.http_status, 200);
  return {eventId: e.id, city: e.city, uf: e.uf, group: full && e.id===40833 ? 'LIVE | Rio de Janeiro RJ' : `LIVE - ${e.city} - ${e.uf}`, url: url.href, headlines, descriptions, keywords};
};
const all = selected.map(copy);
const rio = all.find(e => e.eventId === 40833);
assert.ok(rio);
const added = full ? all : all.filter(e => e.eventId !== 40833);
assert.equal(added.length, full ? 11 : 10);
assert.ok(!all.some(e => [48557,45366].includes(e.eventId)));
const tables = [
  {
    name: '01-ad-groups.csv', template: 'ad-groups-official-template',
    headers: ['Action','Campaign','Ad group','Status'],
    rows: added.map(e => ['Add',campaign,e.group,'Paused']),
  },
  {
    name: '02-responsive-search-ads.csv', template: 'rsa-official-template',
    headers: ['Action','Ad status','Campaign','Ad group','Ad type', ...Array.from({length: 8}, (_,i) => `Headline ${i+1}`), 'Description','Description 2','Description 3','Description 4','Final URL'],
    rows: added.map(e => ['Add','Paused',campaign,e.group,'Responsive search ad',...e.headlines,...e.descriptions,e.url]),
  },
  {
    name: '03-keywords.csv', template: 'keywords-official-template',
    headers: ['Action','Campaign','Ad group','Keyword','Match Type','Keyword status'],
    rows: added.flatMap(e => e.keywords.map(([k,m]) => ['Add',campaign,e.group,k,m,'Paused'])),
  },
];
if (full) {
  const geo = JSON.parse(await fs.readFile(new URL('geo-candidates.json',dir),'utf8'));
  const state = {MS:'State of Mato Grosso do Sul',RJ:'State of Rio de Janeiro',CE:'Ceara',PE:'State of Pernambuco',MG:'State of Minas Gerais',RS:'State of Rio Grande do Sul',SP:'State of Sao Paulo',DF:'Federal District',PR:'State of Parana',BA:'State of Bahia'};
  const locations = all.map(e => {
    const matches=geo.rows.filter(r => slug(r.Name)===slug(e.city) && r['Canonical Name'].split(',').length===3 && r['Canonical Name'].split(',')[1]===state[e.uf] && r.Status==='Active');
    assert.equal(matches.length,1,`Ambiguous geo ${e.city}/${e.uf}`);
    return {city:e.city, uf:e.uf,...matches[0]};
  });
  await fs.writeFile(new URL('geo-selected.json',output),JSON.stringify({source:geo.source,rows:locations},null,2)+'\n');
  const campaignCells=JSON.parse(await fs.readFile(new URL('campaign-official-template-cells.json',dir),'utf8'));
  templates['campaign-official-template']={sheet:[campaignCells['xl/worksheets/sheet1.xml'].filter(c=>/^[A-Z]+2$/.test(c[0]))]};
  tables.unshift({
    name:'00-create-campaign.csv',template:'campaign-official-template',
    headers:['Action','Campaign status','Campaign','Campaign type','Networks','Budget','Budget type','Bid strategy type','Campaign end date','Language','Location'],
    rows:[['Add','Paused',campaign,'Search','Google search','20.00','Daily','Manual CPC','2026-12-19','pt',locations.map(r=>r['Canonical Name']).join(' ; ')]],
  });
}
const wb = Workbook.create();
const csvCell = value => {
  const s = String(value ?? '');
  return /[",\r\n]/.test(s) ? `"${s.replaceAll('"','""')}"` : s;
};
const validation = {campaign, totalSelectedCities: all.length, newGroups: added.length, rioExcludedFromAdds: !full, status: 'Paused', files: [], maxHeadlineLength: Math.max(...all.flatMap(e => e.headlines.map(h => [...h].length))), maxDescriptionLength: Math.max(...all.flatMap(e => e.descriptions.map(d => [...d].length)))};
for (const t of tables) {
  const officialRows = Object.values(templates[t.template]).flat();
  const officialHeader = officialRows.filter(row => row.some(cell => cell[1] === 'Action') && row.some(cell => cell[1] === 'Campaign')).sort((a,b) => b.length-a.length)[0];
  assert.ok(officialHeader, `Missing official header: ${t.template}`);
  const allowed = new Set(officialHeader.map(cell => cell[1]));
  for (const h of t.headers) assert.ok(allowed.has(h), `Header absent from official template: ${h}`);
  const values = [t.headers,...t.rows];
  assert.ok(values.every(r => r.length === t.headers.length));
  const sh = wb.worksheets.add(t.name.replace('.csv',''));
  const range = sh.getRangeByIndexes(0,0,values.length,t.headers.length);
  range.values = values;
  const actual = range.values;
  assert.deepEqual(actual, values);
  const serialized = actual.map(row => row.map(csvCell).join(',')).join('\r\n')+'\r\n';
  await fs.writeFile(new URL(t.name,output), '\uFEFF'+serialized, 'utf8');
  validation.files.push({name:t.name, rows:t.rows.length, columns:t.headers.length, headersCheckedAgainst:t.template});
}
if (!full) await fs.writeFile(new URL('rio-review.json',output), JSON.stringify({
  instruction: 'Review only. Existing group Grupo de anúncios1 already has an ad and 5 keywords. Do not upload Add rows for Rio. Compare/edit existing items in the UI; IDs required for reliable bulk edits are not supplied.',
  existingGroup: 'Grupo de anúncios1', campaign, ...rio,
},null,2)+'\n');
await fs.writeFile(new URL('validation.json',output),JSON.stringify(validation,null,2)+'\n');
console.log(JSON.stringify(validation,null,2));
