import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {evaluateRobots} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/robots.mjs';
const input=process.argv[2];assert.ok(input,'Pass a robots.txt or public-verification.json');
const text=input.endsWith('.json')?JSON.parse(readFileSync(input,'utf8')).robots.body:readFileSync(input,'utf8');
const historiesAllowed=process.argv.includes('--noindex');
const base='https://openresults.run';let cases=0;
for(const agent of ['Googlebot','Googlebot-Image','Bingbot','OAI-SearchBot','ChatGPT-User','GPTBot']) {
 for(const path of ['/perfil','/perfil/','/perfil/conta','/resultados','/resultados/','/resultados/atleta?nome=teste']) {
  const expected=path.startsWith('/resultados')&&historiesAllowed;
  assert.equal(evaluateRobots(text,base+'/robots.txt',base+path,agent).allowed,expected,agent+' policy for '+path);cases++;
 }
 for(const path of ['/','/evento/prova/','/sitemap.cfm','/assets/or_logo.svg']) {
  assert.equal(evaluateRobots(text,base+'/robots.txt',base+path,agent).allowed,true,agent+' must still crawl '+path);cases++;
 }
}
assert.equal(evaluateRobots(text,base+'/robots.txt',base+'/nogooglebot/teste','Googlebot').allowed,false);
assert.match(text,/Sitemap: https:\/\/openresults\.run\/sitemap\.cfm/);
console.log(`Robots: ${cases} local policy cases passed; existing Google-only restriction and sitemap preserved. This is not a real bot-access test.`);
