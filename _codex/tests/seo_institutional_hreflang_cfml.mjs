import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {parseHtml} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/html.mjs';
const source=process.argv[2]||'_codex/staging/seo-institutional-20261003/baseline/RoadRunners';
const paths={about:['/sobre/','/en/about/','/es/sobre/'],help:['/ajuda/','/en/help/','/es/ayuda/'],privacy:['/privacidade/','/en/privacy/','/es/privacidad/']};
const langs=['pt-BR','en','es'];
const head=readFileSync(source+'/includes/estrutura/head.cfm','utf8');
const headParams=head.match(/<cfparam name="VARIABLES.includeHreflang"[^>]*>/)?.[0]||'';
const metadata=head.slice(head.indexOf('<!--- META SEO --->'),head.indexOf('<!--- SOCIAL MEDIA METADATA --->'));
const news=readFileSync(source+'/noticias/index.cfm','utf8');
const newsMeta=news.slice(news.indexOf('<cfif VARIABLES.isNoticiaDetalhe>\n    <cfset REQUEST.currentRouteParams'),news.indexOf('<cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>\n    <cfset VARIABLES.noticiaMetaImage'));
assert.ok(newsMeta.length>800,'Extract the actual route/canonical block');
const scratch=mkdtempSync('/private/tmp/seo-institutional-hreflang-');
try{
 writeFileSync(scratch+'/head.cfm',headParams+metadata);writeFileSync(scratch+'/news.cfm',newsMeta);
 for(const [page,route] of [['sobre','about'],['ajuda','help'],['privacidade','privacy']]){
  const text=readFileSync(source+'/'+page+'/index.cfm','utf8');
  writeFileSync(scratch+'/'+route+'.cfm',text.slice(text.indexOf('<!--- TEMPLATE --->'),text.indexOf('<!--- TAG PARAM TREAT --->'))+text.slice(text.indexOf('<!--- META INFO --->'),text.indexOf('<!--- HEAD --->')));
 }
 const cases=['licensed_full','external_only','summary_link','native','missing_mode','missing_source','invalid_source','local_source','listing','channel'];
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
paths=${JSON.stringify(paths)};
REQUEST.availableLanguages=[{code='pt-BR',hreflang='pt-BR'},{code='en',hreflang='en'},{code='es',hreflang='es'}];
REQUEST.currentRouteParams={};
REQUEST.i18nBuildAbsoluteUrl=function(route,lang=REQUEST.lang){var n=arrayFind(['pt-BR','en','es'],lang);if(structKeyExists(paths,route))return 'https://roadrunners.run' & paths[route][n];var base=['/noticias/','/en/news/','/es/noticias/'][n];return 'https://roadrunners.run' & base & (route EQ 'newsDetail' ? 'test/' : route EQ 'newsChannel' ? 'canal/' : '');};
REQUEST.t=function(key){return key;};
VARIABLES.title='Test';VARIABLES.description='Description';VARIABLES.keywords='Test';rows=[];
</cfscript>
<cfloop array="#['pt-BR','en','es']#" index="lang"><cfset REQUEST.lang=lang>
 <cfloop array="#['about','help','privacy']#" index="route">
  <cfset structDelete(VARIABLES,'includeHreflang')><cfset VARIABLES.metaRobots=''><cfset REQUEST.currentRouteKey=lang EQ 'pt-BR' ? '' : route>
  <cfinclude template="#route#.cfm"><cfsavecontent variable="html"><head><cfinclude template="head.cfm"></head></cfsavecontent>
  <cfset arrayAppend(rows,{kind='institutional',route=route,lang=lang,url=VARIABLES.canonical,key=REQUEST.currentRouteKey,html=toBase64(html,'utf-8')})>
 </cfloop>
 <cfloop array="#${JSON.stringify(cases)}#" index="mode">
  <cfset structDelete(VARIABLES,'includeHreflang')><cfset VARIABLES.metaRobots=''><cfset URL.tag='test'><cfset URL.canal=mode EQ 'channel' ? 'canal' : ''><cfset URL.page=1>
  <cfset VARIABLES.isNoticiaDetalhe=NOT listFind('listing,channel',mode)><cfset VARIABLES.noticiaEncontrada=VARIABLES.isNoticiaDetalhe>
  <cfset VARIABLES.noticia={original_url='https://source.example/article/',content_type={publication_mode=mode EQ 'local_source' ? 'licensed_full' : mode}}>
  <cfif mode EQ 'missing_mode'><cfset structDelete(VARIABLES.noticia.content_type,'publication_mode')></cfif>
  <cfif mode EQ 'missing_source'><cfset structDelete(VARIABLES.noticia,'original_url')></cfif>
  <cfif mode EQ 'invalid_source'><cfset VARIABLES.noticia.original_url='javascript:invalid'></cfif>
  <cfif mode EQ 'local_source'><cfset VARIABLES.noticia.original_url=REQUEST.i18nBuildAbsoluteUrl('newsDetail')></cfif>
  <cfinclude template="news.cfm"><cfsavecontent variable="html"><head><cfinclude template="head.cfm"></head></cfsavecontent>
  <cfset arrayAppend(rows,{kind='news',mode=mode,lang=lang,url=REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey),key=REQUEST.currentRouteKey,html=toBase64(html,'utf-8')})>
 </cfloop>
</cfloop><cfoutput>INSTITUTIONAL_HREFLANG:#serializeJSON(rows)#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8',`-Djava.io.tmpdir=${scratch}`,'-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);const match=r.stdout.match(/INSTITUTIONAL_HREFLANG:(\[[^\n]*\])/);assert.ok(match,r.stdout);
 const rows=JSON.parse(match[1]);const failures=[];
 for(const raw of rows){
  const row=Object.fromEntries(Object.entries(raw).map(([k,v])=>[k.toLowerCase(),v]));
  const p=parseHtml(Buffer.from(row.html,'base64').toString('utf8'),row.url);
  try{
   const external=row.kind==='news'&&['licensed_full','external_only'].includes(row.mode);
   assert.equal(p.canonical_count,1,'one canonical');
   assert.equal(p.canonical_url,external?'https://source.example/article/':row.url,'canonical policy');
   assert.equal(p.hreflang.length,external?0:4,'alternate count');
   if(!external)assert.ok(p.hreflang.some(a=>a.url===row.url),'self alternate');
   if(row.kind==='institutional'){
    assert.equal(row.key,row.route,'route identity');
    const expected=Object.fromEntries(langs.map((l,i)=>[l,'https://roadrunners.run'+paths[row.route][i]]));expected['x-default']=expected['pt-BR'];
    assert.deepEqual(Object.fromEntries(p.hreflang.map(a=>[a.lang,a.url])),expected);
   }else{
    assert.equal(row.key,row.mode==='listing'?'news':row.mode==='channel'?'newsChannel':'newsDetail','language navigation route retained');
    const html=Buffer.from(row.html,'base64').toString('utf8');
    assert.equal(/name="robots" content="noindex,follow"/.test(html),row.mode==='external_only','existing noindex policy');
   }
  }catch(e){failures.push(`${row.kind}/${row.route||row.mode}/${row.lang}: ${e.message}`);}
 }
 console.log(JSON.stringify({cases:rows.length,failures},null,2));assert.deepEqual(failures,[]);
 console.log('CFML: nine institutional destinations and thirty news mode/language cases pass.');
}finally{rmSync(scratch,{recursive:true,force:true});}
