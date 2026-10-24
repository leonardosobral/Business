<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
resumoContext={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED'};
resumoService=new services.ComparadorResumoService().init();resumoError='';resumoData={};
try {
 if(!resumoService.ready(resumoContext))throw(type='Comparador.Validation',message='O resumo depende da instalação do catálogo e da World Athletics neste ambiente.');
 resumoData=resumoService.load(resumoContext,URL);
}catch(Comparador.Validation e){resumoError=e.message;cfheader(statuscode=422);}
catch(Comparador.Forbidden e){resumoError=e.message;cfheader(statuscode=403);}
catch(any e){resumoError='Não foi possível consultar o resumo agora. Tente novamente.';cfheader(statuscode=503);writeLog(file='comparador-admin',type='error',text='Falha na consulta do resumo; referencia=' & createUUID());}
function resumoLink(struct changes={}) {
 var values=duplicate(resumoData.filters);values.pagina=1;structAppend(values,changes,true);var parts=[];
 for(var key in ['aba','escopo','tipo','mercado','marca','busca','falta','pagina'])if(structKeyExists(values,key))arrayAppend(parts,key & '=' & urlEncodedFormat(values[key] & ''));
 return './?' & arrayToList(parts,'&');
}
function resumoNumber(required numeric n){return lsNumberFormat(n,'9,999,999');}
</cfscript>
