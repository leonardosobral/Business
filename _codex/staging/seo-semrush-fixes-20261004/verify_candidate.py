from pathlib import Path
import json,subprocess,shlex,hashlib
from check_public import Meta
stage=Path(__file__).resolve().parent
names=list(json.loads((stage/'before.json').read_text()))
files={}
for route in ['videos','noticias']:
 s=(stage/'candidate'/route/'index.cfm').read_text();files[route+'.cfm']=s.split('<!--- META INFO --->')[1].split('<!--- HEAD --->')[0]
files['head.cfm']=(stage/'candidate/includes/estrutura/head.cfm').read_text().split('<!--- SOCIAL MEDIA METADATA --->')[0]+'</head>'
s=(stage/'candidate/sitemaps/index.cfm').read_text();files['sitemap.cfm']=s[s.index('<cfscript>'):s.index('</cfscript>')+11]
for lang in ['pt-BR','en','es']:files[lang+'.cfm']=(Path('/Users/Shared/Projects/RunnerHub/RoadRunners/i18n')/(lang+'.cfm')).read_text()
files['run.cfm']='''<cfsetting showdebugoutput="false"/><cfparam name="URL.section" default="index"/><cfparam name="URL.page" default="1"/><cfinclude template="sitemap.cfm"/>
<cfscript>
report={pages=[],sitemap=[]};APPLICATION.nomeSite="Road Runners";
REQUEST.availableLanguages=[{code="pt-BR",hreflang="pt-BR"},{code="en",hreflang="en"},{code="es",hreflang="es"}];
REQUEST.t=function(required string key,struct replacements={}){var v=localesCatalog;for(var k in listToArray(key,".")){v=v[k];}for(var k in replacements){v=replace(v,"{"&k&"}",replacements[k],"all");}return v;};
REQUEST.i18nBuildAbsoluteUrl=function(required string routeKey,string languageCode="") {
 var lang=len(languageCode)?languageCode:REQUEST.lang;
 var path=findNoCase("videos",routeKey)?"/videos/":(lang=="en"?"/news/":"/noticias/");
 if(lang!="pt-BR")path="/"&lang&path;
 if(findNoCase("Channel",routeKey))path&=(lang=="en"?"channel/":"canal/")&"test-channel/";
 return "https://roadrunners.run"&path;
};
</cfscript>
<cfloop list="pt-BR,en,es" index="lang">
 <cfinclude template="#lang#.cfm"/><cfset REQUEST.lang=lang/>
 <cfloop list="videos,noticias" index="route">
  <cfloop list="1,3" index="pg">
   <cfloop from="0" to="1" index="channel">
    <cfscript>
    structDelete(VARIABLES,"hreflangPage");includeHreflang=true;
    URL.page=val(pg);URL.canal=channel?"test-channel":"";
    isNoticiaDetalhe=false;noticiaEncontrada=false;totalPaginasNoticias=209;totalPaginasVideos=250;
    canalVideoSelecionadoNome=channel?'Canal "A" & <B>':"";
    canalNoticiasAtivoConfig=channel?{name='Canal "A" & <B>'}:{};
    REQUEST.currentRouteKey=(route=="videos"?"videos":"news")&(channel?"Channel":"");
    </cfscript>
    <cfsavecontent variable="rendered"><cfinclude template="#route#.cfm"/><cfinclude template="head.cfm"/></cfsavecontent>
    <cfset arrayAppend(report.pages,{lang=lang,route=route,page=val(pg),channel=channel,html=rendered})/>
   </cfloop>
  </cfloop>
 </cfloop>
</cfloop>
<cfscript>
localUrl="https://roadrunners.run/noticias/local/";
cases=[{mode="summary_link",original="https://source.test/story",want=true},{mode="licensed_full",original="https://source.test/story",want=false},{mode="licensed_full",original=localUrl,want=true},{mode="licensed_full",original="",want=true},{mode="external_only",original="https://source.test/story",want=false},{mode=" EXTERNAL_ONLY ",original="",want=false},{mode=" LICENSED_FULL ",original="https://source.test/story",want=false}];
for(c in cases){actual=newsHasLocalCanonical({channel={publicationMode=c.mode},originalUrl=c.original},localUrl);arrayAppend(report.sitemap,{want=c.want,actual=actual});}
arrayAppend(report.sitemap,{want=true,actual=newsHasLocalCanonical({},localUrl)});
</cfscript>
<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON(report)#</cfoutput>'''
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-editorial-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;this.serialization.preservecaseforstructkey=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,s in p.items():(work/n).write_text(s)
 cp=subprocess.run(['curl','-sS','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError(cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=70)
if cp.returncode:raise RuntimeError(cp.stderr[-1500:])
try:r=json.loads(cp.stdout)
except:raise RuntimeError(cp.stdout[:4000])
for x in r['pages']:
 m=Meta();m.feed(x['html']);expected='?page=3' if x['page']==3 else ''
 assert len(m.alternates)==4,x
 assert all(a.endswith(expected) and ('?page=' in a)==bool(expected) for a in m.alternates.values()),x
 assert m.canonical==[m.alternates[x['lang']]],x
 if x['page']==3:
  assert ('Page 3 of' if x['lang']=='en' else 'Página 3 de') in m.title,x
 if x['channel']:
  assert 'Canal "A" & <B>' in m.title and 'Canal "A" & <B>' in m.description[0],x
  assert '<B>' not in x['html'],x
for x in r['sitemap']:assert x['actual']==x['want'],x
receipt={'scenarios':len(r['pages'])+len(r['sitemap']),'hashes':{n:hashlib.sha256((stage/'candidate'/n).read_bytes()).hexdigest() for n in names},'watch':json.loads((stage/'watch.json').read_text())}
(stage/'candidate-render-passed.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps({'adobe_scenarios_passed':receipt['scenarios'],'editorial':len(r['pages']),'sitemap':len(r['sitemap'])}))
