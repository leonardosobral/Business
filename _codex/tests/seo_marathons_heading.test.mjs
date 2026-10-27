import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import {JSDOM} from 'jsdom';
test('public marathon listing has one main heading with the existing appearance',()=>{
const source=process.env.RR_SEO_SOURCE ? path.join(process.env.RR_SEO_SOURCE,'maratonas/index.cfm') : new URL('../../../RoadRunners/maratonas/index.cfm',import.meta.url);
const text=readFileSync(source,'utf8');
const fragment=text.slice(text.indexOf('<!--- TITULO --->'),text.indexOf('<!--- LISTA DE MARATONAS --->'));
const dom=new JSDOM('<main>'+fragment+'</main>');
try {
  const headings=dom.window.document.querySelectorAll('main h1');
  assert.equal(headings.length,1,'The public marathon listing must identify its main heading');
  assert.equal(headings[0].classList.contains('h3'),true,'Keep the existing h3 appearance');
  assert.match(headings[0].textContent,/Maratonas do Brasil/);
} finally {dom.window.close();}
});
