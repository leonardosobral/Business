from pathlib import Path
import ast,json,subprocess,shlex,hashlib,sys
stage=Path(__file__).resolve().parent;root=Path('/Users/Shared/Projects/RunnerHub/RoadRunners');mode=sys.argv[1] if len(sys.argv)>1 else 'candidate'
sys.path.insert(0,str(stage.parent/'seo-semrush-fixes-20261004'));from check_public import Meta
prior=ast.parse((stage.parent/'seo-semrush-fixes-20261004/verify_candidate.py').read_text());remote=next(ast.literal_eval(n.value) for n in prior.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
s=(stage/mode/'busca/index.cfm').read_text()
start=s.index('<!--- NORMALIZA A TAG RECEBIDA')
early=s[:start].split('<cfset REQUEST.currentRouteKey = "search"/>')[1].replace('CGI.','testCgi.').replace('#URL#','#testQuery#')
block=early+s.split('<!--- MONTA METADADOS SEO DA PAGINA DE BUSCA --->')[1].split('<!--- RENDERIZA O HEAD COMPARTILHADO --->')[0]

files={'meta.cfm':block,'head.cfm':(root/'includes/estrutura/head.cfm').read_text().split('<!--- SOCIAL MEDIA METADATA --->')[0]+'</head>'}
for lang in ['pt-BR','en','es']:files[lang+'.cfm']=(root/'i18n'/(lang+'.cfm')).read_text()
files['run.cfm']='''<cfsetting showdebugoutput="false"/><cfscript>
report={pages=[]};APPLICATION.nomeSite="Road Runners";
REQUEST.availableLanguages=[{code="pt-BR",hreflang="pt-BR"},{code="en",hreflang="en"},{code="es",hreflang="es"}];
REQUEST.t=function(required string key,struct replacements={}){var v=localesCatalog;for(var k in listToArray(key,".")){v=v[k];}for(var k in replacements){v=replace(v,"{"&k&"}",replacements[k],"all");}return v;};
REQUEST.i18nBuildAbsoluteUrl=function(required string routeKey,string languageCode=""){var lang=len(languageCode)?languageCode:REQUEST.lang;return REQUEST.currentBaseUrl&(lang=="en"?"/en/search/":(lang=="es"?"/es/busqueda/":"/busca/"));};
REQUEST.currentRouteKey="search";
</cfscript>
<cfloop list="pt-BR,en,es" index="lang"><cfinclude template="#lang#.cfm"/><cfset REQUEST.lang=lang/>
<cfloop list="https://roadrunners.run,https://beta.roadrunners.run,https://dev.roadrunners.run" index="base">
<cfset REQUEST.currentBaseUrl=base/>
<cfloop list="root,distance,type,term,tracking,internal,route-only,post,unknown,blanktag,blanksearch" index="kind">
<cfscript>
structDelete(VARIABLES,"includeHreflang");localizedSearchPath=lang=="en"?"/en/search/":(lang=="es"?"/es/busqueda/":"/busca/");
termoBuscaDisplay=kind=="term"?"maratona":"";
testCgi={request_method="GET"};testQuery=lang=="pt-BR"?{}:{i18n_lang=lang,i18n_route="search"};
if(kind=="distance"){testQuery.distancia_inicio=5;testQuery.distancia_fim=5;}
if(kind=="type")testQuery.busca_tipo="resultados";
if(kind=="term")testQuery.busca="maratona";
if(kind=="tracking")testQuery.utm_source="test";
if(kind=="internal")testQuery={I18N_LANG=lang,I18N_ROUTE="search"};
if(kind=="route-only")testQuery={i18n_route="search"};
if(kind=="post")testCgi.request_method="POST";
if(kind=="unknown")testQuery.unknown="x";
if(kind=="blanktag")testQuery.tag="";
if(kind=="blanksearch")testQuery.busca="";
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="meta.cfm"/><cfinclude template="head.cfm"/></cfsavecontent>
<cfset arrayAppend(report.pages,{lang=lang,base=base,kind=kind,path=localizedSearchPath,html=rendered})/>
</cfloop></cfloop></cfloop>
<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON(report)#</cfoutput>'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=75)
if cp.returncode:raise RuntimeError(cp.stderr[-1500:])
try:r=json.loads(cp.stdout)
except:raise RuntimeError(cp.stdout[:4500])
failures=[]
for x in r['pages']:
 m=Meta();m.feed(x['html'])
 if len(m.alternates)!=(4 if x['kind'] in ['root','internal','route-only'] else 0):failures.append([x['lang'],x['base'],x['kind'],'alternates'])
 assert m.canonical==[x['base']+x['path']],x
 assert not m.robots,x
 if x['kind']=='term':assert 'maratona' in m.title,x
print(json.dumps({'mode':mode,'scenarios':len(r['pages']),'failures':len(failures)}))
assert not failures,failures[:3]
if mode=='candidate':
 receipt={'scenarios':len(r['pages']),'hashes':{'busca/index.cfm':hashlib.sha256((stage/'candidate/busca/index.cfm').read_bytes()).hexdigest()},'watch':json.loads((stage/'watch.json').read_text())}
 (stage/'candidate-render-passed.json').write_text(json.dumps(receipt,indent=2))
