import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const fixture=`WITH page_metrics(source,medium,campaign,creative,page_view_id,visitor_id,session_id,page_path,page_content_type,page_content_id,has_view,active_ms) AS (VALUES
 ('openresults','referral','a','link-a','p1','v1','s1','/a','event','1',true,20000),
 ('openresults','banner','b','link-b','p1','v1','s1','/a','event','1',true,20000),
 ('openresults','banner','b','link-c','p2','v1','s1','/b','event','2',true,20000),
 ('openresults','referral','c','link-d','p3','v2','s2','/c','event','3',true,15000),
 ('google','organic','','','p4','v1','s3','/d','event','4',true,45000)
)`;
const query=readFileSync(new URL('../../portal/audiencia/queries/origins.sql',import.meta.url),'utf8').replace('/* AUDIENCE_FILTER */',fixture);
const result=spawnSync('/opt/homebrew/opt/postgresql@16/bin/psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h','127.0.0.1','-p',process.env.AUDIENCE_FIXTURE_PORT||'55586','-U','postgres','-d','origin_test'],{input:`SELECT json_agg(r) FROM (${query.trim().replace(/;$/,'')}) r;`,encoding:'utf8'});
assert.equal(result.status,0,result.stderr);
const rows=JSON.parse(result.stdout);
assert.deepEqual(rows.find(r=>r.source==='openresults'),{source:'openresults',pageviews:3,active_pages:3,visitors:2,sessions:2,active_ms:55000,engaged_sessions:1},'same source consolidates media, campaigns and creatives without double counting pages, people, sessions or active time');
assert.equal(rows.length,2,'different origins remain separate');
console.log('Audience origin consolidation SQL passed');
