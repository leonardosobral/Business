"""CF regression tests for the actual CBAt fetch parser; HTTP replaced by a saved public fixture."""
import ast,json,pathlib,re,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/cron5-cbat-20261105'
mode=sys.argv[1] if len(sys.argv)>1 else 'baseline';news=(STAGE/('baseline' if mode=='baseline' else 'candidate')/'admin/importer_cbat_corridaderua.cfm').read_text(encoding='utf-8-sig')
def function(name):return re.search(r'^function '+name+r'\([^\n]*[\s\S]*?^}',news,re.M).group()
names=['textOrFallback','decodeHtmlEntities','stripHtmlTags','cleanupImportedBodyHtml','buildExcerptFromDescription','extractFirstMatch','parseBrazilianDate','stripTrackingParams']
if 'function parseCbatArticleDetail(' in news:names.append('parseCbatArticleDetail')
functions='\n'.join(function(n) for n in names)
fetch=re.search(r'<cffunction name="fetchArticleDetail"[\s\S]*?</cffunction>',news).group();fetch,count=re.subn(r'<cfhttp\b[^>]+/>','<cfset httpResult = {statusCode=fixtureStatus,fileContent=fixtureHtml}>',fetch,count=1);assert count==1
checks='''<cfscript>
checks=0;failures=[];function expect(ok,message){checks++;if(!ok)arrayAppend(failures,message);}
fixtureStatus='200 OK';fixtureHtml=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'article.html','utf-8');r=fetchArticleDetail('https://cbat.org.br/noticia/107514/teste');
expect(r.success AND len(r.body_html) GT 1000,'Real CBAt article must be extracted from full 353KB page');
expect(findNoCase('Loterias Caixa',r.body_html) GT 0,'End of real article retained');
expect(r.updated_at_raw EQ '27/10/2026' AND isDate(r.updated_at),'Modification date extracted regardless of metadata position');
expect(find('/107514.jpg',r.media_url) GT 0,'Real cover metadata extracted');
expect(r.categories[1] EQ 'Corrida de Rua','Real category retained');
fixtureHtml='<html><header>OUTSIDE_HEADER<p>categoria</p><p>Corrida de Rua</p></header><div class="mt-6"><p class="text-lg">EXCERPT_TEXT</p></div><div class="extra content noticia-corpo"><p>START_TEXT</p><div><p>NESTED_TEXT</p></div><p>END_TEXT</p><script>BAD_SCRIPT</script></div><aside>OUTSIDE_RELATED</aside><meta content="28/10/2026" property="article:modified_time"><meta content="https://example.org/cover.jpg" property="og:image"></html>';
r=fetchArticleDetail('https://cbat.org.br/noticia/1/teste');
expect(r.success AND find('START_TEXT',r.body_html) AND find('NESTED_TEXT',r.body_html) AND find('END_TEXT',r.body_html),'Class order and nested containers must preserve all text');
expect(!find('OUTSIDE_HEADER',r.body_html) AND !find('OUTSIDE_RELATED',r.body_html) AND !find('BAD_SCRIPT',r.body_html),'Only article body is imported');
expect(r.excerpt_text EQ 'EXCERPT_TEXT','Excerpt retained');
expect(r.updated_at_raw EQ '28/10/2026' AND r.media_url EQ 'https://example.org/cover.jpg','Metadata attribute order is irrelevant');
fixtureHtml='<html><main>Page without article</main></html>';r=fetchArticleDetail('https://cbat.org.br/noticia/1/teste','Fallback category','https://example.org/fallback.jpg');
expect(!r.success AND !len(r.body_html),'Missing body is rejected rather than importing entire page');
expect(r.categories[1] EQ 'Fallback category' AND r.media_url EQ 'https://example.org/fallback.jpg','Fallback metadata retained');
expect(findNoCase('corpo',r.error_message) GT 0 AND r.error_message NEQ '200 OK','HTTP 200 with missing body reports extraction failure');
fixtureHtml='<div class="noticia-corpo content"></div>';r=fetchArticleDetail('https://cbat.org.br/noticia/1/teste');expect(!r.success,'Empty body rejected');
fixtureStatus='503 Service Unavailable';fixtureHtml='<div class="noticia-corpo content"><p>Error text</p></div>';r=fetchArticleDetail('https://cbat.org.br/noticia/1/teste');expect(!r.success AND r.status_code EQ 503,'HTTP failures remain failures');
if(arrayLen(failures))throw(message=arrayToList(failures,' | '));writeOutput('USER_ACQUISITION_SOURCE_PASSED ' & serializeJSON({checks=checks}));
</cfscript>'''
test='<cfscript>\n'+functions+'\n</cfscript>\n'+fetch+'\n'+checks
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text());remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets));remote=remote.replace('business-user-acquisition-test-','business-cbat-test-')
p={'mode':'source','tests/source.cfm':test,'tests/article.html':(STAGE/'article.html').read_text()}
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(p).encode(),capture_output=True,timeout=65);print(run.stdout.decode() or run.stderr.decode())
try:ok=json.loads(run.stdout).get('ok',False)
except ValueError:ok=False
raise SystemExit(0 if ok else 1)
