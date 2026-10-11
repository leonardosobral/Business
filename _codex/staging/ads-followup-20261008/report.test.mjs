import assert from 'node:assert/strict';
import {readFileSync,mkdtempSync,rmSync,writeFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {tmpdir} from 'node:os';
const p=new URL('.',import.meta.url),bin='/opt/homebrew/opt/postgresql@16/bin/',scratch=mkdtempSync(tmpdir()+'/advertiser-report-');
const run=(name,args,input)=>{let r=spawnSync(bin+name,args,{input,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return r.stdout.trim()};
const sql=s=>run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'],s);
let started=false;
try {
run('initdb',['-D',scratch+'/data','-U','postgres','-A','trust','--no-locale']);run('pg_ctl',['-D',scratch+'/data','-l',scratch+'/log','-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);started=true;
sql(`CREATE SCHEMA ads; CREATE TABLE ads.events(delivery_id text,campaign_id text,event_type text,valid boolean,received_at timestamptz DEFAULT now()); CREATE TABLE ads.campaigns(campaign_id text,name text); INSERT INTO ads.campaigns VALUES('ad1','Race');
INSERT INTO ads.events VALUES('d1','ad1','CLICK',true,now()),('d1','ad1','CLICK',true,now()),('d2','ad1','CLICK',false,now()),('d3','ad1','CLICK',true,now()-interval '15 days'),('d4','ad1','CLICK',true,now()),('d2','wrong','CLICK',true,now());`);
const fixture=`WITH filtered(source,medium,campaign,campaign_id,delivery_id,event_kind,slot_state,session_id) AS (VALUES
('google','cpc','test','ad1','d1','ad_render','filled','s1'),
('google','cpc','test','ad1','d1','ad_viewable','filled','s1'),
('google','cpc','test','ad1','d1','ad_viewable','filled','s1'),
('google','cpc','test','ad1','d2','ad_viewable','filled','s1'),
('google','cpc','test','ad1','d3','ad_viewable','filled','s2'),
('google','cpc','test','ad1','d4','ad_render','filled','s3'),
('google','cpc','test','ad1','house','ad_viewable','house','s4'),
('direct','none','','ad1','direct','ad_viewable','filled','s5'),
('google','display','other','ad1','other','ad_viewable','filled','s6'))`;
let q=readFileSync(new URL('candidate/Business/portal/audiencia/queries/advertiser_acquisition.sql',p),'utf8').replace('/* AUDIENCE_FILTER */',fixture).replaceAll(':days','7');
let rows=JSON.parse(sql(`SELECT json_agg(x) FROM (${q}) x;`)),r=rows.find(x=>x.campaign==='test');
assert.equal(rows.length,2);assert.equal(r.rendered_deliveries,2);assert.equal(r.viewed_deliveries,3);assert.equal(r.view_sessions,2);assert.equal(r.clicked_deliveries,2);assert.equal(r.viewed_clicked_deliveries,1);
assert.equal(rows.find(x=>x.campaign==='other').view_sessions,1);
writeFileSync(new URL('sql-tests.json',p),JSON.stringify({passed:7,checks:['repeated beacons','repeated clicks','invalid clicks','wrong campaign','out-of-period clicks','house and untagged excluded','unique reach']}));
console.log('7 report SQL checks passed');
}finally{if(started)run('pg_ctl',['-D',scratch+'/data','-m','fast','-w','stop']);rmSync(scratch,{recursive:true,force:true});}
