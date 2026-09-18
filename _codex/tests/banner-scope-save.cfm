<cfscript>
if(createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS')!='1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok,required string label){if(!ok)throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
include root & 'portal/includes/banner_form_helpers.cfm';
scratch=getTempDirectory() & 'banner-save-' & createUUID();directoryCreate(scratch);directoryCreate(scratch & '/public');
source=fileRead(root & 'portal/includes/banner_management_backend.cfm');
REQUEST.testCgi={https='on',http_host='business.example.org'};
functions=replace(left(source,find('</cfscript>',source)+10),'CGI','REQUEST.testCgi','all'); fileWrite(scratch & '/functions.cfm',functions); include scratch & '/functions.cfm';
start=find('<cfif len(trim(FORM.acao & ""))>',source); finish=find('<cfif VARIABLES.bannerManagementApiReady>',source,start);
action=mid(source,start,finish-start);
// Only database/upload/redirect boundaries are replaced. All production validation,
// decoding, staging, move, authorized edit restoration and finally cleanup execute.
action=reReplace(action,'(?s)<cfquery name="qBannerManagementCurrentAssets".*?</cfquery>','<cfset qBannerManagementCurrentAssets=REQUEST.savedCreative/>');
action=reReplace(action,'(?s)<cfquery name="qBannerManagementSave".*?</cfquery>','<cfif REQUEST.failDatabase><cfthrow message="fixture database failure"/><cfelse><cfset REQUEST.savedScope=serializeJSON(VARIABLES.bannerScope)/><cfset REQUEST.savedDimensions=[VARIABLES.bannerLargura,VARIABLES.bannerAltura,VARIABLES.bannerMobileLargura,VARIABLES.bannerMobileAltura]/></cfif>');
action=reReplace(action,'(?s)<cffile action="upload".*?result="bannerUploadResult"/>','<cfset fileCopy(REQUEST.uploadFixtures[bannerUploadKind], VARIABLES.bannerStagingDirectory & bannerUploadKind & ".upload")/><cfset bannerUploadResult={serverFile=bannerUploadKind & ".upload"}/>');
action=replace(action,'<cflocation addtoken="false" url="/portal/banners/?sucesso=salvo"/>','<cfset REQUEST.saveReached=true/>');
action=replace(action,'message = "Nao foi possivel concluir a operacao do banner."','message = cfcatch.message & " " & cfcatch.detail');
fileWrite(scratch & '/action.cfm',action);
img=createObject('java','java.awt.image.BufferedImage').init(7,9,1);createObject('java','javax.imageio.ImageIO').write(img,'png',createObject('java','java.io.File').init(scratch & '/real.png'));fileWrite(scratch & '/fake.png','fake');
try {
 for(testCase in ['edit','new','bad-mobile','database-failure','csrf','admin']) {
  structClear(FORM); REQUEST.failDatabase=testCase=='database-failure'; REQUEST.saveReached=false;
  FORM.acao='salvar_banner';FORM.banner_csrf=testCase=='csrf'?'wrong':'token';FORM.banner_id=testCase=='edit'?'11111111-1111-4111-8111-111111111111':'';
  FORM.banner_nome='Test banner';FORM.banner_alt_text='Corrida de exemplo';FORM.banner_link_destino='/evento/exemplo/';FORM.banner_peso_exibicao='2';FORM.banner_prioridade='3';FORM.banner_inicio_exibicao='2026-09-15T12:00';FORM.banner_fim_exibicao='2026-10-15T12:00';
  FORM.banner_regions_mode='SELECTED';FORM.banner_regions='sc,PR';FORM.banner_pages_mode='SELECTED';FORM.banner_pages='event';FORM.banner_largura='99999';FORM.banner_arquivo_desktop_atual='https://evil.test/image.png';
  VARIABLES.bannerManagementIsAdmin=testCase!='admin';VARIABLES.bannerManagementActorId=123;VARIABLES.bannerManagementApiReady=true;VARIABLES.bannerManagementCsrf='token';VARIABLES.bannerUploadDiskPath=scratch & '/public/';VARIABLES.bannerUploadWebRoot='/portal/banners/assets/';VARIABLES.bannerOwnerAccountId=1;VARIABLES.bannerPlacementKey='rr-sidebar-banner-300x250';VARIABLES.bannerManagementAlert={type='',message=''};
  if(testCase!='edit') {FORM.banner_arquivo_desktop='posted';FORM.banner_arquivo_mobile='posted';}
  REQUEST.uploadFixtures={desktop=scratch & '/real.png',mobile=scratch & (testCase=='bad-mobile'?'/fake.png':'/real.png')};
  REQUEST.savedCreative=queryNew('desktop_image_url,mobile_image_url,width,height,mobile_width,mobile_height,open_in_new_tab,status','varchar,varchar,integer,integer,integer,integer,varchar,varchar',[{desktop_image_url='https://example.org/old.png',mobile_image_url='https://example.org/old-mobile.png',width=300,height=250,mobile_width=600,mobile_height=500,open_in_new_tab='true',status='PAUSED'}]);
  savecontent variable='ignoredOutput' {include scratch & '/action.cfm';}
  if(listFind('edit,new',testCase)) {
   check(REQUEST.saveReached,'valid ' & testCase & ' reaches canonical save: ' & VARIABLES.bannerManagementAlert.message);
   check(find('"regions_mode":"SELECTED"',REQUEST.savedScope)>0 AND find('"pages":["event"]',REQUEST.savedScope)>0,'canonical lowercase specific JSON');
   if(testCase=='edit')check(serializeJSON(REQUEST.savedDimensions)=='[300,250,600,500]' AND VARIABLES.bannerDesktopAssetPath=='https://example.org/old.png' AND VARIABLES.bannerAbrirNovaAba,'edit ignores posted image/dimensions and preserves database values');
   else check(serializeJSON(REQUEST.savedDimensions)=='[7,9,7,9]','save uses decoded dimensions');
  } else check(!REQUEST.saveReached AND VARIABLES.bannerManagementAlert.type=='danger','reject ' & testCase);
  if(structKeyExists(VARIABLES,'bannerStagingDirectory') AND len(VARIABLES.bannerStagingDirectory))check(!directoryExists(VARIABLES.bannerStagingDirectory),'staging removed after ' & testCase);
  if(listFind('bad-mobile,database-failure',testCase))check(arrayLen(directoryList(scratch & '/public',false,'path'))==0,'new uploads removed after ' & testCase);
  for(published in directoryList(scratch & '/public',false,'path'))fileDelete(published);
 }
} finally {directoryDelete(scratch,true);}
</cfscript>
