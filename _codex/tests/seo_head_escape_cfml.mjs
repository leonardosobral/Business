import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {parseHtml} from '/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo/html.mjs';
const source=process.argv[2]||'/Users/Shared/Projects/RunnerHub/RoadRunners';
const head=readFileSync(path.join(source,'includes/estrutura/head.cfm'),'utf8');
const block=(head.match(/<cfparam name="VARIABLES.includeHreflang"[^>]*>/)?.[0]||'')+head.slice(head.indexOf('    <link rel="canonical"'),head.indexOf('    <!--- SOCIAL MEDIA METADATA --->'))+head.match(/    <cfif len\(trim\(VARIABLES[.]structuredDataJsonLd\)\)>[\s\S]*?<\/cfif>/)[0];
assert.match(block,/canonical/);
const scratch=mkdtempSync('/private/tmp/seo-head-test-');
try{
 writeFileSync(path.join(scratch,'head.cfm'),block);
 writeFileSync(path.join(scratch,'fixture.cfm'),`<cfscript>
VARIABLES.structuredDataJsonLd=serializeJSON({'@type'='SportsEvent',name='Prova </script><script>unsafe()</script>'});
VARIABLES.canonical='https://roadrunners.run/evento/a"b&c/';
REQUEST.currentRouteKey="event";REQUEST.availableLanguages=[{hreflang="pt-BR",code="pt-BR"},{hreflang="en",code="en"}];
REQUEST.i18nBuildAbsoluteUrl=function(route,lang){return 'https://roadrunners.run/' & (lang EQ "en" ? "en/event/" : "evento/") & 'a"b&c/';};
</cfscript><cfsavecontent variable="html"><cfinclude template="head.cfm"></cfsavecontent><cfoutput>SEO_HEAD_RESULT:#toBase64(html,"utf-8")#</cfoutput>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain',`-CommandBox_home=${process.env.SEO_CONTENT_CFML_HOME}`,'execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:2*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 const output=r.stdout+'\n'+r.stderr;assert.equal(r.status,0,output);const match=output.match(/SEO_HEAD_RESULT:([A-Za-z0-9+/=]+)/);assert.ok(match,output);
 const html=Buffer.from(match[1],'base64').toString('utf8'),raw='https://roadrunners.run/evento/a"b&c/';
 const parsed=parseHtml('<head>'+html+'</head>',raw);assert.equal(parsed.canonical_raw,raw);assert.equal(parsed.hreflang.length,3);assert.equal(parsed.hreflang[0].url,new URL(raw).href);assert.equal(parsed.hreflang[1].url,new URL('https://roadrunners.run/en/event/a"b&c/').href);assert.match(html,/&quot;/);assert.match(html,/&amp;/);const script=html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)[1];assert.equal(JSON.parse(script).name??JSON.parse(script).NAME,'Prova </script><script>unsafe()</script>');assert.doesNotMatch(script,/<\/script/i);
 console.log('CFML head: quoted canonical and all alternate attributes preserve their complete URLs');
}finally{rmSync(scratch,{recursive:true,force:true});}
