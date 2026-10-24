<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
guard=new services.ComparadorAdminService();
curadoria=new services.ComparadorCuradoriaService().init();
context={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED',isPost=compareNoCase(CGI.request_method,'POST')==0,csrfVerified=false};
guard.authorize(context);
csrf=csrfGenerateToken('comparador-curadoria');
ready=curadoria.ready(context);error='';conflict=false;
tab=guard.field(URL,'aba',20);if(!listFind('marcas,home,historico',tab))tab='marcas';
requestedBrandPage=guard.field(URL,'pagina',7);if(!reFind('^[1-9][0-9]{0,6}$',requestedBrandPage))requestedBrandPage=1;else requestedBrandPage=val(requestedBrandPage);
action=guard.field(FORM,'acao',16);current={};history=queryNew('');
if(listFind('marcas,home',action))tab=action;
if(ready AND len(action)) {
 try {
  context.csrfVerified=csrfVerifyToken(guard.field(FORM,'csrf_token',256),'comparador-curadoria');
  guard.authorize(context,true);
  if(action=='home') {curadoria.saveHome(context,FORM);tab='home';}
  else if(action=='marcas') {curadoria.saveMarcas(context,FORM);tab='marcas';}
  else throw(type='Comparador.Validation',message='Ação inválida.');
  location(url='./?aba=' & tab & (tab=='marcas'?'&pagina=' & requestedBrandPage:'') & '&salvo=1',addtoken=false);
 }catch(Comparador.Conflict e){error=e.message;conflict=true;cfheader(statuscode=409);}
 catch(Comparador.Validation e){error=e.message;cfheader(statuscode=422);}
 catch(Comparador.Forbidden e){error=e.message;cfheader(statuscode=403);}
 catch(any e){error='Não foi possível salvar. Nenhuma alteração desta operação foi aplicada. Reabra a configuração e tente novamente.';cfheader(statuscode=500);writeLog(file='comparador-admin',type='error',text='Falha na curadoria; referencia=' & createUUID());}
}
if(ready) {
 current=curadoria.load(context);
 if(len(error)) {
  // Reuse posted values only with the exact snapshot and a fully received form.
  postedToken=structKeyExists(FORM,'token') AND isSimpleValue(FORM.token)?trim(FORM.token & ''):'';
  completeForm=structKeyExists(FORM,'formulario_completo') AND isSimpleValue(FORM.formulario_completo) AND compare(trim(FORM.formulario_completo & ''),'curadoria')==0;
  if(!reFind('^[a-f0-9]{64}$',postedToken))conflict=true;
  else if(compare(postedToken,current.token)!=0) {
   conflict=true;error='A curadoria mudou desde a abertura desta página. Reabra a configuração e confira os dados antes de salvar.';cfheader(statuscode=409);
  } else if(!completeForm)conflict=true;
 }
 brandRows=duplicate(current.data.marcas);
 arraySort(brandRows,function(a,b){var byName=compareNoCase(a.marca,b.marca);return byName!=0?byName:compare(a.tag_marca,b.tag_marca);});
 brandPages=max(1,ceiling(arrayLen(brandRows)/30));brandPage=min(requestedBrandPage,brandPages);
 brandPageRows=[];brandScopeTags=[];
 for(brandIndex=(brandPage-1)*30+1;brandIndex<=min(brandPage*30,arrayLen(brandRows));brandIndex++){arrayAppend(brandPageRows,brandRows[brandIndex]);arrayAppend(brandScopeTags,brandRows[brandIndex].tag_marca);}
 brandScope=arrayToList(brandScopeTags,',');
 if(tab=='historico')history=curadoria.history(context);
}
function curadoriaCount(required string key) {
 if(len(error) AND !conflict AND action=='home' AND structKeyExists(FORM,key) AND isSimpleValue(FORM[key])) return FORM[key] & '';
 return current.data.home[key] & '';
}
function curadoriaChecked(required struct brand,required string prefix,required string flag) {
 if(len(error) AND !conflict AND action=='marcas')return structKeyExists(FORM,prefix & brand.tag_marca) AND isSimpleValue(FORM[prefix & brand.tag_marca]) AND compare(FORM[prefix & brand.tag_marca] & '','true')==0;
 return brand[flag];
}
function curadoriaHistoryItem(required string beforeJson,required string afterJson) {
 var summary={available=false,brands=[]};
 try {
  var previous=deserializeJSON(beforeJson);var next=deserializeJSON(afterJson);
  summary.launchBefore=previous.home.lancamentos_por_ciclo;summary.offerBefore=previous.home.ofertas_por_ciclo;
  summary.launchAfter=next.home.lancamentos_por_ciclo;summary.offerAfter=next.home.ofertas_por_ciclo;
  summary.ratioChanged=summary.launchBefore!=summary.launchAfter OR summary.offerBefore!=summary.offerAfter;
  var oldBrands={};var newBrands={};var tags={};
  for(var item in previous.marcas){oldBrands[item.tag_marca]=item;tags[item.tag_marca]=true;}
  for(var item in next.marcas){newBrands[item.tag_marca]=item;tags[item.tag_marca]=true;}
  for(var tag in tags) {
   var oldItem=structKeyExists(oldBrands,tag)?oldBrands[tag]:{destaque=false,presente_brasil=false};
   var newItem=structKeyExists(newBrands,tag)?newBrands[tag]:{destaque=false,presente_brasil=false};
   if(oldItem.destaque!=newItem.destaque OR oldItem.presente_brasil!=newItem.presente_brasil)
    arrayAppend(summary.brands,{name=structKeyExists(newItem,'marca')?newItem.marca:oldItem.marca,featuredBefore=oldItem.destaque,featuredAfter=newItem.destaque,brazilBefore=oldItem.presente_brasil,brazilAfter=newItem.presente_brasil});
  }
  arraySort(summary.brands,function(a,b){return compareNoCase(a.name,b.name);});
  summary.available=true;
 }catch(any ignored){}
 return summary;
}
</cfscript>
