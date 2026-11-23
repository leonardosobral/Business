<cfscript>
if(!VARIABLES.adsAccessCanReviewCampaign OR VARIABLES.adsAccessDelegated) {cfheader(statuscode=403);writeOutput('Acesso exclusivo da administração.');abort;}
function inventoryText(required struct values,required string key,string fallback='') {
 if(!structKeyExists(values,key)) return fallback;
 if(!isSimpleValue(values[key])) throw(type='Publisher.Validation',message='Campo inválido.');
 return trim(values[key] & '');
}
function inventoryUuid(string value='') {return reFindNoCase('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',value)==1;}
function inventoryRows(required query q) {var rows=[];for(var i=1;i<=q.recordCount;i++){var item={};for(var col in listToArray(q.columnList)) item[lCase(col)]=isNull(q[col][i]) ? '' : q[col][i];arrayAppend(rows,item);}return rows;}
if(!structKeyExists(SESSION,'publisherInventoryCsrf')) SESSION.publisherInventoryCsrf=hash(createUUID() & createUUID(),'SHA-256');
invCsrf=hmac('inventory:' & VARIABLES.adsAccessActorId,SESSION.publisherInventoryCsrf,'HmacSHA256');
invReady=queryExecute("SELECT coalesce(has_function_privilege(current_user,to_regprocedure('ads.save_publisher_site(uuid,integer,bigint,text,text,text[],text)'),'EXECUTE'),false) AND coalesce(has_function_privilege(current_user,to_regprocedure('ads.save_publisher_spot(uuid,integer,bigint,uuid,text,text,text,text,integer,integer,text)'),'EXECUTE'),false) AND to_regprocedure('ads.publisher_deliver(text,text,text,text)') IS NOT NULL AS ready",{},{datasource='runnerhub'}).ready[1];
invTab=inventoryText(URL,'tab','sites');if(!listFind('sites,spots,install',invTab)) invTab='sites';
invError='';invSites=[];invSpots=[];invEdit={};
if(invReady AND cgi.request_method=='POST') {
 try {
  if(compare(inventoryText(FORM,'csrf'),invCsrf)!=0) throw(type='Publisher.Validation',message='Sessão expirada. Recarregue a página.');
  invAction=inventoryText(FORM,'action');
  invId=inventoryText(FORM,'id');invVersion=inventoryText(FORM,'version','0');
  if((len(invId) AND !inventoryUuid(invId)) OR !reFind('^[0-9]{1,12}$',invVersion)) throw(type='Publisher.Validation',message='Registro inválido.');
  invKey=inventoryText(FORM,'key'); invName=inventoryText(FORM,'name');invStatus=inventoryText(FORM,'status');
  if(!reFind('^[a-z][a-z0-9-]{1,49}$',invKey) OR len(invName)<2 OR len(invName)>120 OR !listFind('ACTIVE,INACTIVE',invStatus)) throw(type='Publisher.Validation',message='Informe nome, identificador (letras minúsculas, números e hífen) e status válidos.');
  invParams={id={value=invId,null=!len(invId),cfsqltype='cf_sql_varchar'},actor={value=VARIABLES.adsAccessActorId,cfsqltype='cf_sql_integer'},version={value=invVersion,cfsqltype='cf_sql_bigint'},key={value=invKey,cfsqltype='cf_sql_varchar'},name={value=invName,cfsqltype='cf_sql_varchar'},status={value=invStatus,cfsqltype='cf_sql_varchar'}};
  if(invAction=='site') {
   invOrigins=[];
   for(invOrigin in listToArray(reReplace(inventoryText(FORM,'origins'),'[\r\n,]+',',','all'),',')) {
    invOrigin=lCase(trim(invOrigin));
    if(!reFind('^https://([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',invOrigin) OR len(invOrigin)>255) throw(type='Publisher.Validation',message='Use um domínio HTTPS por linha, sem barra final, caminho ou porta. Cadastre www separadamente.');
    if(!arrayFind(invOrigins,invOrigin)) arrayAppend(invOrigins,invOrigin);
   }
   if(!arrayLen(invOrigins) OR arrayLen(invOrigins)>10) throw(type='Publisher.Validation',message='Cadastre de 1 a 10 domínios por site.');
   invParams.origins={value=serializeJSON(invOrigins),cfsqltype='cf_sql_longvarchar'};
   queryExecute("SELECT ads.save_publisher_site(CAST(:id AS uuid),:actor,:version,:key,:name,ARRAY(SELECT jsonb_array_elements_text(CAST(:origins AS jsonb))),:status)",invParams,{datasource='runnerhub'});
   invTab='sites';
  } else if(invAction=='spot') {
   invSite=inventoryText(FORM,'site_id');invPage=inventoryText(FORM,'page_key');invRegion=inventoryText(FORM,'region_code');
   invWidth=inventoryText(FORM,'width');invHeight=inventoryText(FORM,'height');
   if(!inventoryUuid(invSite) OR (len(invPage) AND !listFind('home,search,state,event,athlete',invPage)) OR (len(invRegion) AND !listFind('AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO',invRegion)) OR !reFind('^[0-9]{2,4}$',invWidth) OR !reFind('^[0-9]{2,4}$',invHeight) OR val(invWidth)<50 OR val(invWidth)>2400 OR val(invHeight)<50 OR val(invHeight)>2400) throw(type='Publisher.Validation',message='Confira site, página, UF e dimensões (50 a 2400 px).');
   invParams.site={value=invSite,cfsqltype='cf_sql_varchar'};invParams.page={value=invPage,cfsqltype='cf_sql_varchar'};invParams.region={value=invRegion,cfsqltype='cf_sql_varchar'};
   invParams.width={value=invWidth,cfsqltype='cf_sql_integer'};invParams.height={value=invHeight,cfsqltype='cf_sql_integer'};
   queryExecute('SELECT ads.save_publisher_spot(CAST(:id AS uuid),:actor,:version,CAST(:site AS uuid),:key,:name,:page,:region,:width,:height,:status)',invParams,{datasource='runnerhub'});invTab='spots';
  } else throw(type='Publisher.Validation',message='Ação inválida.');
  location(url='/portal/banners/sites/?tab=' & invTab & '&saved=1',addtoken=false,statuscode=303);
 } catch(Publisher.Validation e) {invError=e.message;}
 catch(any e) {invError='Não foi possível salvar. Confira se o identificador já existe ou se outro administrador alterou este registro. Recarregue para tentar novamente.';writeLog(file='ads_publisher_inventory',type='error',text='Inventory save failed: ' & e.type);}
}
if(invReady) {
 invSites=inventoryRows(queryExecute('SELECT CAST(site_id AS text),site_key,name,array_to_string(origins,chr(10)) AS origins,status,version FROM ads.publisher_sites ORDER BY name,site_key',{},{datasource='runnerhub'}));
 invSpots=inventoryRows(queryExecute('SELECT CAST(sp.spot_id AS text),CAST(sp.site_id AS text),sp.spot_key,sp.name,sp.page_key,sp.region_code,sp.width,sp.height,sp.status,sp.version,si.site_key,si.name AS site_name,si.status AS site_status,p.placement_key FROM ads.publisher_spots sp JOIN ads.publisher_sites si USING(site_id) JOIN ads.placements p USING(placement_id) ORDER BY si.name,sp.name',{},{datasource='runnerhub'}));
 invEditId=inventoryText(URL,'edit');
 for(invRow in (invTab=='sites' ? invSites : invSpots)) if(inventoryText(invRow,invTab=='sites' ? 'site_id' : 'spot_id')==invEditId) invEdit=duplicate(invRow);
 if(len(invError)) {invEdit=duplicate(FORM);invEdit[invTab=='sites' ? 'site_key' : 'spot_key']=inventoryText(FORM,'key');invEdit[invTab=='sites' ? 'site_id' : 'spot_id']=inventoryText(FORM,'id');}
}
</cfscript>
