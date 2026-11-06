"""Read-only, localhost CF regression checks using the production Wix page fixture."""
import ast,json,pathlib,re,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
STAGE=ROOT/'_codex/staging/cron13-jornalcorrida-20261105'
mode=sys.argv[1] if len(sys.argv)>1 else 'baseline'
news=(STAGE/('baseline' if mode=='baseline' else 'candidate')/'admin/importer_contrarelogio.cfm').read_text(encoding='utf-8-sig')
service=(STAGE/'business-service-baseline.txt').read_text().split('\n',1)[1] if mode=='baseline' else (ROOT/'includes/backend/cron_jobs_service.cfm').read_text(encoding='utf-8-sig')
def function(source,name):
 return re.search(r'^function '+name+r'\([^\n]*[\s\S]*?^}',source,re.M).group()
functions='\n'.join(function(news,n) for n in ['extractWixArticleBody','cleanupImportedBodyHtml','decodeHtmlEntities'])+'\n'+function(service,'cronJobsResponsePreview')
checks=r'''
failures=[];checks=0;
function expect(ok,message){checks++;if(!ok)arrayAppend(failures,message);}
html=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'article.html','utf-8');
body=extractWixArticleBody(html);
expect(len(body) GT 1000,'Real 982KB Wix page must yield complete article');
expect(findNoCase('Under Armour',body) GT 0,'Real article text retained');
fixture='<header>OUTSIDE_HEADER</header><section data-hook="post-description"><p>START_TEXT</p><section><p>NESTED_TEXT</p></section><p>END_TEXT</p><script>BAD_SCRIPT</script><button>BAD_BUTTON</button><p onclick="bad()">Texto</p><img src="https://example.org/small.jpg" data-pin-media="https://example.org/full.jpg"></section><footer>OUTSIDE_FOOTER</footer>';
b=extractWixArticleBody(fixture);
expect(find('START_TEXT',b) AND find('NESTED_TEXT',b) AND find('END_TEXT',b),'Nested sections must not truncate the article');
expect(!find('OUTSIDE_HEADER',b) AND !find('OUTSIDE_FOOTER',b),'Only post-description is imported');
expect(!find('BAD_SCRIPT',b) AND !find('BAD_BUTTON',b) AND !findNoCase('onclick=',b),'Existing executable markup cleanup retained');
expect(find('https://example.org/full.jpg',b) GT 0,'Full resolution image retained');
expect(!len(extractWixArticleBody('<html><header>Not an article</header></html>')),'Missing article remains empty');
expect(!len(extractWixArticleBody('<section data-hook="post-description"></section>')),'Empty article remains empty');
small='{"success":true,"updated":2}';expect(cronJobsResponsePreview(small) EQ small,'Short responses unchanged');
rows=[];for(i=1;i LTE 20;i++)arrayAppend(rows,{action='Erro',title='Notícia ' & i,message='Item ignorado por não ter título ou corpo útil. ' & repeatString('detail ',80),source_url='https://example.org/' & i});
preview=cronJobsResponsePreview(serializeJSON({success=false,erros=20,processed=20,results=rows}));
expect(len(preview) LTE 4000 AND isJSON(preview),'Compacted history is valid bounded JSON');
compact=deserializeJSON(preview);
expect(structKeyExists(compact,'error_samples') AND arrayLen(compact.error_samples) GT 0,'Compaction retains actionable error samples');
if(arrayLen(failures))throw(message=arrayToList(failures,' | '));
writeOutput('USER_ACQUISITION_SOURCE_PASSED ' & serializeJSON({checks=checks,body_length=len(body),preview_length=len(preview)}));
'''
test='<cfscript>\n'+functions+'\n'+checks.replace('\\"','"')+'\n</cfscript>'
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace('business-user-acquisition-test-','business-jornalcorrida-test-')
p={'mode':'source','tests/source.cfm':test,'tests/article.html':(STAGE/'article.html').read_text()}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(p).encode(),capture_output=True,timeout=65)
print(run.stdout.decode() or run.stderr.decode());
try:ok=json.loads(run.stdout).get('ok',False)
except ValueError:ok=False
raise SystemExit(0 if ok else 1)
