<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
guard=new services.ComparadorAdminService();
catalog=new services.ComparadorCatalogService().init();
context={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED',isPost=CGI.request_method=='POST',csrfVerified=false};
guard.authorize(context);
csrf=csrfGenerateToken('comparador-admin');ready=catalog.ready(context);error='';conflict=false;
entity=guard.field(URL,'cadastro',32);if(!listFind(arrayToList(catalog.entities()),entity)) entity='marcas';
def=catalog.definition(entity);key=guard.field(URL,'chave',200);search=guard.field(URL,'busca',160);
newRecord=guard.field(URL,'novo',1)=='1';formData={};token='';
returnQuery='cadastro=' & urlEncodedFormat(entity) & '&busca=' & urlEncodedFormat(search);
action=guard.field(FORM,'acao',16);
if(ready AND len(action)) {
 try {
  context.csrfVerified=csrfVerifyToken(guard.field(FORM,'csrf_token',256),'comparador-admin');guard.authorize(context,true);
  if(action=='salvar') key=catalog.saveRecord(context,entity,FORM);
  else if(action=='excluir') {
   if(guard.field(FORM,'confirmar',3)!='sim') throw(type='Comparador.Validation',message='Marque a confirmação para excluir o cadastro sem vínculos.');
   catalog.deleteRecord(context,entity,guard.field(FORM,'chave',200),guard.field(FORM,'token',64));key='';
  }else throw(type='Comparador.Validation',message='Ação inválida.');
  location(url='./?' & returnQuery & '&salvo=1' & (len(key)?'&chave=' & urlEncodedFormat(key):''),addtoken=false);
 }catch(Comparador.Conflict e){error=e.message;conflict=true;cfheader(statuscode=409);}
 catch(Comparador.Validation e){error=e.message;cfheader(statuscode=422);}
 catch(Comparador.Forbidden e){error=e.message;cfheader(statuscode=403);}
 catch(any e){error='Não foi possível salvar. A operação foi desfeita. Reabra o cadastro e tente novamente.';cfheader(statuscode=500);writeLog(file='comparador-admin',type='error',text='Falha em cadastro; referencia=' & createUUID());}
}
if(ready) {
 records=catalog.listRecords(context,entity,search);
 if(len(key)) {
  try {item=catalog.loadRecord(context,entity,key);formData=item.data;token=item.token;history=catalog.history(context,entity,key);}
  catch(Comparador.Validation e){error=e.message;key='';cfheader(statuscode=404);}
 }
 if(len(error) AND action=='salvar' AND !conflict) {for(field in def.fields) if(structKeyExists(FORM,field.name) AND isSimpleValue(FORM[field.name])) formData[field.name]=FORM[field.name];}
 choices={};for(kind in ['tipos','caracteristicas','filtros']) choices[kind]=catalog.listRecords(context,kind);
}
function value(name) {return structKeyExists(formData,name) AND !isNull(formData[name])?formData[name] & '':'';}
</cfscript>
