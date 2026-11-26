<cfprocessingdirective pageencoding="utf-8"/>
<!--- Included only after the normal authenticated administrator gate. --->
<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed OR NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cfheader statuscode="403"/><cfabort/>
</cfif>
<cfinclude template="../../includes/backend/require_real_platform_context.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfscript>
verifiedService=new services.VerifiedAdmin();
verifiedCategories=verifiedService.categories();
verifiedOrigins={manual="Concessão permanente",vip="Todo Santo Dia · VIP",upgrade="Todo Santo Dia · Upgrade VIP",annual="Compra anual do selo",refunded="Com estorno no histórico",registered_vip="Todo Santo Dia · VIP/upgrade confirmado no cadastro"};
verifiedStates={active="Ativo",paid="Pagamento confirmado",refunded="Estornado",pending="Aguardando pagamento",creating="Checkout em criação",failed="Pagamento falhou",expired="Expirado",review="Em conferência"};
verifiedReviewReasons={failed_only="Somente tentativas VIP recusadas",basic_only="Pagamento confirmado somente da Básica",refunded_only="Pedido estornado; upgrade no cadastro requer revisão",no_order_found="Nenhum pedido Todo Santo Dia localizado pelos vínculos consultados"};
verifiedFilters={status=lcase(trim(URL.filter_status ?: "active")),origin=lcase(trim(URL.filter_origin ?: "")),search=left(trim(URL.user_busca ?: ""),120),page=max(1,int(val(URL.pagina ?: 1))),logic=lcase(trim(URL.filter_logic ?: "any")),desafio=trim(URL.filter_desafio ?: ""),produto=trim(URL.filter_produto ?: ""),admin=(URL.filter_admin ?: "") == "true",dev=(URL.filter_dev ?: "") == "true",partner=(URL.filter_partner ?: "") == "true"};
if(!listFind("active,inactive,all,unclassified,reconcile,divergent",verifiedFilters.status))verifiedFilters.status="active";
if(len(verifiedFilters.origin) AND !structKeyExists(verifiedOrigins,verifiedFilters.origin) AND !structKeyExists(verifiedCategories,verifiedFilters.origin))verifiedFilters.origin="";
if(!listFind("any,all",verifiedFilters.logic))verifiedFilters.logic="any";
verifiedDetailId=max(0,int(val(URL.page_id ?: 0)));
verifiedError="";
verifiedSaved=false;
verifiedQuickCount=min(40,max(0,int(val(URL.classified ?: 0))));
verifiedQuickCategory=trim(FORM.category ?: "");
verifiedQuickNote=left(trim(FORM.note ?: ""),1800);
function verifiedUrl(struct changes={}) {
    var values={filter_status=verifiedFilters.status,filter_origin=verifiedFilters.origin,user_busca=verifiedFilters.search,pagina=verifiedFilters.page,filter_logic=verifiedFilters.logic,filter_desafio=verifiedFilters.desafio,filter_produto=verifiedFilters.produto};
    for(var flag in ["admin","dev","partner"])if(verifiedFilters[flag])values["filter_" & flag]="true";
    structAppend(values,arguments.changes,true);
    var parts=[];
    for(var key in values)if(len(values[key] & ""))arrayAppend(parts,urlEncodedFormat(key)&"="&urlEncodedFormat(values[key] & ""));
    return "/portal/verificados/?" & arrayToList(parts,"&");
}
function verifiedProfileUrl(required struct profile) {
    return len(arguments.profile.tag) ? "https://roadrunners.run/atleta/" & urlEncodedFormat(arguments.profile.tag) & "/" : "https://roadrunners.run/atleta/?id=" & arguments.profile.profile_id;
}
</cfscript>
<cflock scope="session" type="exclusive" timeout="5">
    <cfif NOT structKeyExists(SESSION,"verifiedAdminCsrfSeed")><cfset SESSION.verifiedAdminCsrfSeed=generateSecretKey("AES",256)/></cfif>
    <cfset verifiedCsrf=hmac(qPerfil.id & ":verified-origins",SESSION.verifiedAdminCsrfSeed,"HmacSHA256")/>
</cflock>
<cfif CGI.request_method EQ "POST">
    <cfif NOT listFind("classify,quick",FORM.verified_action ?: "")>
        <cfset verifiedError="Esta tela agora registra os motivos dos selos. Ativação e validade seguem as concessões e os pagamentos de cada perfil."/>
        <cfheader statuscode="409"/>
    <cfelseif compare(FORM.verified_csrf ?: "",verifiedCsrf) NEQ 0>
        <cfset verifiedError="Sua sessão mudou. Reabra o perfil e tente novamente."/><cfheader statuscode="403"/>
    <cfelseif NOT verifiedService.classificationReady()>
        <cfset verifiedError="O cadastro de motivos ainda aguarda a preparação do banco."/><cfheader statuscode="409"/>
    <cfelseif (FORM.verified_action ?: "") EQ "quick">
        <cftry>
            <cfset verifiedQuickCount=verifiedService.classifyQuick(selection=(FORM.selection ?: ""),category=trim(FORM.category ?: ""),note=trim(FORM.note ?: ""),actorId=qPerfil.id)/>
            <cflocation addtoken="false" url="#verifiedUrl({classified=verifiedQuickCount,page_id=''})###lista-motivos"/>
            <cfcatch type="VerifiedAdmin.Validation">
                <cfset verifiedError=cfcatch.message/><cfset verifiedQuickCount=0/><cfheader statuscode="400"/>
            </cfcatch>
            <cfcatch>
                <cfset verifiedError="Nenhuma classificação deste envio foi salva. Um dos perfis mudou ou não possui concessão permanente. Confira a lista atualizada e selecione novamente."/>
                <cfset verifiedQuickCount=0/><cfheader statuscode="409"/>
            </cfcatch>
        </cftry>
    <cfelseif NOT reFind("^[1-9][0-9]{0,8}$",FORM.profile_id ?: "") OR NOT reFind("^[0-9]{1,18}$",FORM.revision ?: "")>
        <cfset verifiedError="Perfil ou versão inválidos. Reabra o perfil."/><cfheader statuscode="400"/>
    <cfelse>
        <cfset verifiedDetailId=int(FORM.profile_id)/>
        <cftry>
            <cfset verifiedService.classify(verifiedDetailId,trim(FORM.category ?: ""),trim(FORM.reason ?: ""),qPerfil.id,val(FORM.revision))/>
            <cflocation addtoken="false" url="#verifiedUrl({page_id=verifiedDetailId,saved=1})#"/>
            <cfcatch>
                <cfset verifiedError="Não foi possível salvar. Confira o motivo e reabra o perfil se ele foi alterado em outra sessão."/>
                <cfheader statuscode="409"/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>
<cfset verifiedData=verifiedService.overview(verifiedFilters)/>
<cfset verifiedFilters.page=verifiedData.page/>
<cfset verifiedDetail=verifiedDetailId GT 0 ? verifiedService.detail(verifiedDetailId) : {}/>
<cfset verifiedSaved=(URL.saved ?: "") EQ "1" AND structKeyExists(verifiedDetail,"profile")/>
<cfquery name="qVerifiedChallengeProducts">
    SELECT des.desafio,des.produto,coalesce(nullif(min(dp.nome_produto),''),des.produto) AS nome_produto
    FROM desafios des LEFT JOIN desafios_produtos dp ON dp.codigo_produto=des.produto
    WHERE trim(coalesce(des.produto,''))<>'' GROUP BY des.desafio,des.produto ORDER BY des.desafio,nome_produto
</cfquery>
