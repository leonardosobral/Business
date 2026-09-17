<!--- Load before output; identity and account scope come only from backend_login. --->
<cfif NOT isDefined("REQUEST.businessIdentity.id") OR NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
  <cflocation url="/" addtoken="false"/>
</cfif>
<cfset VARIABLES.cuponsRrRestrictByConta = true/>
<cfset VARIABLES.cuponsRrEventosContaIds = "0"/>
<cfset VARIABLES.cuponsRrEventosOperacaoIds = "0"/>
<cfset VARIABLES.cuponsRrPaginaIds = "0"/>
<cfset VARIABLES.cuponsRrEffectiveIsAdmin = false/>
<cfset VARIABLES.cuponsRrCanOperate = false/>

<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfset VARIABLES.cuponsRrEffectiveIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.cuponsRrEffectiveIsAdmin = true/>
</cfif>

<cfif VARIABLES.cuponsRrEffectiveIsAdmin>
    <cfset VARIABLES.cuponsRrRestrictByConta = false/>
    <cfset VARIABLES.cuponsRrCanOperate = true/>
</cfif>

<cfif isDefined("qEventosConta") AND qEventosConta.recordcount AND len(trim(ValueList(qEventosConta.id_evento)))>
    <cfset VARIABLES.cuponsRrEventosContaIds = ValueList(qEventosConta.id_evento)/>
</cfif>

<cfif isDefined("qEventosContaOperacao") AND qEventosContaOperacao.recordcount AND len(trim(ValueList(qEventosContaOperacao.id_evento)))>
    <cfset VARIABLES.cuponsRrEventosOperacaoIds = ValueList(qEventosContaOperacao.id_evento)/>
    <cfset VARIABLES.cuponsRrCanOperate = true/>
</cfif>

<cfif isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive AND isDefined("VARIABLES.businessEffectivePaginaIds") AND len(trim(VARIABLES.businessEffectivePaginaIds))>
    <cfset VARIABLES.cuponsRrPaginaIds = VARIABLES.businessEffectivePaginaIds/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.id_pagina") AND len(trim(ValueList(qPerfil.id_pagina)))>
    <cfset VARIABLES.cuponsRrPaginaIds = ValueList(qPerfil.id_pagina)/>
</cfif>


<cfscript>
cpService=createObject('component','cupons-rr.includes.CouponService');
cpAccess=cpService.scope(cuponsRrEffectiveIsAdmin,cuponsRrEventosContaIds,cuponsRrEventosOperacaoIds,cuponsRrPaginaIds);
if (!structKeyExists(SESSION,'couponManagerCsrf')) SESSION.couponManagerCsrf=lCase(hash(generateSecretKey('AES',256),'SHA-256'));
cpError='';cpConflict=false;cpSelected=cpService.id(URL.cupom_id ?: (URL.campanha ?: ''));
cpNew=(URL.novo ?: '') EQ '1';cpSaved=0;
if (structKeyExists(FORM,'coupon_action')) {
  if (CGI.request_method NEQ 'POST' OR compare(FORM.csrf ?: '',SESSION.couponManagerCsrf) NEQ 0) {
    cfheader(statuscode=403,statustext='Forbidden');writeOutput('Sessão expirada. Recarregue a página e tente novamente.');abort;
  }
  try {
    cpSaved=cpService.save(FORM.coupon_action,FORM,cpAccess);
  } catch (Coupon.Conflict ex) {cpError=ex.message;cpConflict=true;}
    catch (Coupon.Validation ex) {cpError=ex.message;}
    catch (Coupon.Forbidden ex) {cpError=ex.message;cfheader(statuscode=403,statustext='Forbidden');}
    catch (any ex) {cpError='Não foi possível salvar o cupom. Revise os dados e tente novamente.';writeLog(file='application',type='error',text='Coupon manager: ' & ex.type & ' ' & ex.message);}
  cpSelected=cpService.id(FORM.id_cupom ?: '');cpNew=FORM.coupon_action EQ 'criar';
}
if (cpSaved) location(url='./?cupom_id=' & cpSaved & '&salvo=1',addtoken=false);
if ((URL.modo ?: '') EQ 'eventos') {
  cfheader(name='Cache-Control',value='no-store');
  cpFound=cpService.events(cpAccess,URL.busca_evento ?: '');
  cpItems=[];
  for (cpRow in cpFound) arrayAppend(cpItems,{id=cpRow.id_evento,label=cpRow.nome_evento & (isDate(cpRow.data_inicial) ? ' · ' & dateFormat(cpRow.data_inicial,'dd/mm/yyyy') : '') & ' · ##' & cpRow.id_evento});
  cfcontent(type='application/json; charset=utf-8',reset=true);
  writeOutput(serializeJSON({items=cpItems}));abort;
}
cpData=cpService.listing(cpAccess,URL);
cpCoupon=cpService.get(cpSelected,cpAccess);
cpCanEdit=cpCoupon.recordcount AND cpService.canEdit(cpSelected,cpAccess);
cpLinks=queryNew('id_evento_cupom');cpOthers=queryNew('tipo,nome');
if (cpCoupon.recordcount) {cpLinks=cpService.links(cpSelected,cpAccess);cpOthers=cpService.otherLinks(cpSelected,cpAccess);}
cpValues={id_cupom=0,cupom='',parceiro='',descricao='',condicoes='',url='',data_expiracao='',ativo=true,revision=''};
if (cpCoupon.recordcount) {
  cpValues=queryGetRow(cpCoupon,1);
  cpValues.data_expiracao=isDate(cpCoupon.data_expiracao[1]) ? dateFormat(cpCoupon.data_expiracao[1],'yyyy-mm-dd') : '';
}
if (len(cpError) AND listFind('criar,editar',FORM.coupon_action ?: '')) {
  for (cpKey in ['cupom','parceiro','descricao','condicoes','url','data_expiracao','ativo']) cpValues[cpKey]=FORM[cpKey] ?: '';
  // Keep the stale revision on a conflict; require an explicit reload before overwriting.
  if (cpConflict) cpValues.revision=FORM.revision ?: '';
}
function cpListUrl(numeric page=1) {
  return './?busca=' & encodeForURL(VARIABLES.cpData.filters.search) & '&status=' & encodeForURL(VARIABLES.cpData.filters.status) & '&pagina=' & arguments.page;
}
function cpDate(any value='') {return isDate(arguments.value) ? dateFormat(arguments.value,'dd/mm/yyyy') : 'Sem prazo';}
</cfscript>
