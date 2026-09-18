<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok, required string label) { if (!ok) throw(message='FAIL: ' & label); writeOutput('PASS: ' & label & chr(10)); }
check(fileExists(root & 'portal/includes/banner_form_helpers.cfm'), 'scope form helper is available');
include root & 'portal/includes/banner_form_helpers.cfm';
s=bannerScopeNormalize({regions_mode='SELECTED',regions=['sc','PR','SC'],pages_mode='SELECTED',pages=['event']});
check(serializeJSON(s.regions)=='["SC","PR"]' AND s.pages[1]=='event','specific scope normalizes and deduplicates');
for (bad in [{regions_mode='SELECTED',regions=[],pages_mode='ALL',pages=[]},{regions_mode='ALL',regions=[],pages_mode='SELECTED',pages=['sidebar']},{regions_mode='ALL',regions=[],pages_mode='SELECTED',pages=[]}]) {
 rejected=false; try { bannerScopeNormalize(bad); } catch(any e) { rejected=true; } check(rejected,'invalid explicit selection fails closed');
}
check(bannerScopeFromMetadata('{}').regions_mode=='ALL','absent legacy metadata is unrestricted');
rejected=false; try { bannerScopeFromMetadata('{"banner_scope_v1":null}'); } catch(any e) { rejected=true; } check(rejected,'explicit malformed metadata rejected');
rejected=false; try {bannerScopeFromMetadata('{"banner_scope_v1":{"regions_mode":"ALL","regions":["SC"],"pages_mode":"ALL","pages":[]}}');} catch(any e) {rejected=true;} check(rejected,'persisted ALL with nonempty array is malformed, never nationwide');
check(arrayLen(bannerScopeFromForm({banner_regions_mode='ALL',banner_regions='SC',banner_pages_mode='ALL',banner_pages='event'}).regions)==0,'POST ALL clears stale browser checkbox selection');
saved={id_banner='123',nome='Saved',arquivo_path='https://example.com/old.png',arquivo_mobile_path='https://example.com/mobile.png',largura=300,altura=250,largura_mobile=600,altura_mobile=500,abrir_nova_aba=true,peso_exibicao=3,prioridade=4,banner_metadata=serializeJSON({banner_scope_v1=s})};
v=bannerFormValues({},saved); check(v.banner_regions_mode=='SELECTED' AND v.banner_regions=='SC,PR' AND v.banner_prioridade==4 AND v.banner_abrir_nova_aba=='1','edit scope and advanced fields preserved');
v=bannerFormValues({acao='salvar_banner',banner_nome='Failed post',banner_regions_mode='SELECTED',banner_regions='SP',banner_pages_mode='SELECTED',banner_pages='search',banner_arquivo_desktop_atual='https://evil.test/no.png'},saved);
check(v.banner_nome=='Failed post' AND v.banner_regions=='SP' AND v.desktop_path=='https://example.com/old.png','failed POST retained but hidden image path ignored');
check(bannerDestination('/evento/test/').external==false AND bannerDestination('https://roadrunners.run/evento/test/').external==false AND bannerDestination('https://example.org').external,'destination inference');
for (badUrl in ['//evil.test','javascript:alert(1)','http://example.org','https://user:pass@example.org','https://example.org\evil']) { rejected=false; try { bannerDestination(badUrl); } catch(any e) { rejected=true; } check(rejected,'unsafe destination rejected'); }
scratch=getTempDirectory() & 'banner-image-' & createUUID(); directoryCreate(scratch);
try {
 img=createObject('java','java.awt.image.BufferedImage').init(7,9,1);
 createObject('java','javax.imageio.ImageIO').write(img,'png',createObject('java','java.io.File').init(scratch & '/actual.png'));
 m=bannerImageMetadata(scratch & '/actual.png'); check(m.width==7 AND m.height==9 AND m.extension=='png','dimensions extracted from decoded file');
 fileWrite(scratch & '/fake.png','not an image'); rejected=false; try { bannerImageMetadata(scratch & '/fake.png'); } catch(any e) { rejected=true; } check(rejected,'fake image rejected');
 fileWrite(scratch & '/one.gif',binaryDecode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==','base64')); oldHash=hash(fileReadBinary(scratch & '/one.gif')); m=bannerImageMetadata(scratch & '/one.gif'); check(m.width==1 AND m.extension=='gif' AND oldHash==hash(fileReadBinary(scratch & '/one.gif')),'GIF bytes unchanged');
 originalHex=binaryEncode(fileReadBinary(scratch & '/one.gif'),'hex');
 canvasHex=left(originalHex,12) & '2c01fa00' & mid(originalHex,21,len(originalHex)); fileWrite(scratch & '/canvas.gif',binaryDecode(canvasHex,'hex')); canvasHash=hash(fileReadBinary(scratch & '/canvas.gif'));
 canvasInfo=bannerImageMetadata(scratch & '/canvas.gif');
 hugeCanvasHex=left(originalHex,12) & '10271027' & mid(originalHex,21,len(originalHex)); fileWrite(scratch & '/huge-canvas.gif',binaryDecode(hugeCanvasHex,'hex'));
 rejected=false; try {bannerImageMetadata(scratch & '/huge-canvas.gif');} catch(any e) {rejected=find('40 megapixels',e.message)>0;}
 writeOutput('GIF canvas reproduction: legitimate=' & canvasInfo.width & 'x' & canvasInfo.height & '; hugeRejected=' & rejected & chr(10));
 check(canvasInfo.width==300 AND canvasInfo.height==250 AND canvasHash==hash(fileReadBinary(scratch & '/canvas.gif')),'GIF reports logical canvas, not its 1x1 first frame, preserving bytes (got ' & canvasInfo.width & 'x' & canvasInfo.height & '; hugeRejected=' & rejected & ')');
 check(rejected,'huge GIF logical canvas rejected despite its 1x1 first frame');
 imageBlock=mid(originalHex,39,len(originalHex)-40);
 animatedHex=left(canvasHex,len(canvasHex)-2) & imageBlock & '3b'; fileWrite(scratch & '/animated.gif',binaryDecode(animatedHex,'hex')); animatedHash=hash(fileReadBinary(scratch & '/animated.gif'));
 m=bannerImageMetadata(scratch & '/animated.gif'); check(m.width==300 AND m.height==250 AND animatedHash==hash(fileReadBinary(scratch & '/animated.gif')),'multi-frame GIF canvas measured without conversion');
 badFrameHex=left(canvasHex,len(canvasHex)-2) & replace(imageBlock,'01000100','10271027') & '3b'; fileWrite(scratch & '/bad-frame.gif',binaryDecode(badFrameHex,'hex'));
 rejected=false; try {bannerImageMetadata(scratch & '/bad-frame.gif');} catch(any e) {rejected=true;} check(rejected,'oversized later GIF frame rejected before decoding');
 hugeHex=binaryEncode(fileReadBinary(scratch & '/one.gif'),'hex'); hugeHex=replace(hugeHex,'01000100','10271027','all'); fileWrite(scratch & '/huge.gif',binaryDecode(hugeHex,'hex'));
 rejected=false; try {bannerImageMetadata(scratch & '/huge.gif');} catch(any e) {rejected=find('40 megapixels',e.message)>0;} check(rejected,'pixel cap checked before allocating decoded frame');
 oversized=createObject('java','java.io.RandomAccessFile').init(scratch & '/oversize.png','rw'); oversized.setLength(10485761); oversized.close();
 rejected=false; try {bannerImageMetadata(scratch & '/oversize.png');} catch(any e) {rejected=find('10 MiB',e.message)>0;} check(rejected,'byte cap enforced');
} finally { directoryDelete(scratch,true); }
writeOutput('BANNER SCOPE FORM PASS' & chr(10));
// Render the real form, preserving submitted values and accessible controls.
qBannerManagementEdit=queryNew('id_banner'); VARIABLES.bannerManagementCsrf='safe-token';
function bannerManagementBuildAssetUrl(required string value) {return value;}
FORM.acao='salvar_banner'; FORM.banner_nome='A "quoted" <name>'; FORM.banner_regions_mode='SELECTED'; FORM.banner_regions='SC,PR'; FORM.banner_pages_mode='SELECTED'; FORM.banner_pages='event';
savecontent variable='html' { include root & 'portal/includes/banner_form.cfm'; }
check(find('value="A &quot;quoted&quot; &lt;name&gt;"',html)>0,'real form escapes submitted values');
check(find('value="SC" checked',html)>0 AND find('value="event" checked',html)>0,'real form keeps selected scope');
check(find('name="banner_largura"',html)==0 AND find('name="banner_link_tipo"',html)==0,'manual technical fields removed');
check(find('for="banner_alt_text"',html)>0 AND find('data-banner-preview="mobile"',html)>0 AND find('<details',html)>0,'real form accessibility preview and advanced options render');
</cfscript>
