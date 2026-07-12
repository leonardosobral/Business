<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfparam name="URL.id_ad_evento" default="0"/>
<cfparam name="URL.id_evento" default="0"/>
<cfparam name="URL.tipo" default="INSCRICAO_CLICK"/>
<cfparam name="URL.origem" default=""/>

<cfscript>
function adsConversionClickBuildEventUrl(required string eventTag) {
    if (!len(trim(arguments.eventTag))) {
        return "https://roadrunners.run/";
    }

    return "https://roadrunners.run/evento/" & urlEncodedFormat(trim(arguments.eventTag)) & "/";
}

function adsConversionClickValidType(required string conversionType) {
    var allowedTypes = "EVENTO_VIEW,INSCRICAO_CLICK,INSCRICAO_CONFIRMADA";
    return listFindNoCase(allowedTypes, trim(arguments.conversionType)) > 0;
}

function adsConversionClickNormalizeDestination(required string destination) {
    var redirectUrl = trim(arguments.destination);

    if (!len(redirectUrl)) {
        return "";
    }

    if (left(redirectUrl, 1) == "/") {
        return "https://roadrunners.run" & redirectUrl;
    }

    if (!reFindNoCase("^https?://", redirectUrl)) {
        return "https://" & redirectUrl;
    }

    return redirectUrl;
}
</cfscript>

<cfset VARIABLES.adsConversionType = uCase(trim(URL.tipo))/>
<cfif NOT adsConversionClickValidType(VARIABLES.adsConversionType)>
    <cfset VARIABLES.adsConversionType = "INSCRICAO_CLICK"/>
</cfif>

<cfquery name="qAdsConversionClickTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE (
            table_schema = 'ads'
            AND table_name IN ('tb_ad_eventos', 'tb_ad_conversion_log')
          )
       OR (
            table_schema = 'public'
            AND table_name IN ('tb_conta_eventos', 'tb_evento_corridas')
          )
</cfquery>

<cfset VARIABLES.adsConversionClickTables = ValueList(qAdsConversionClickTables.table_name)/>

<cfif NOT ListFindNoCase(VARIABLES.adsConversionClickTables, "tb_ad_eventos")
    OR NOT ListFindNoCase(VARIABLES.adsConversionClickTables, "tb_evento_corridas")>
    <cflocation addtoken="false" url="https://roadrunners.run/"/>
</cfif>

<cfquery name="qAdsConversionClick" maxrows="1">
    SELECT ad.id_ad_evento,
           ad.id_evento,
           evt.nome_evento,
           evt.tag,
           evt.url_inscricao,
           evt.url_hotsite,
           ce.id_conta
    FROM ads.tb_ad_eventos ad
    INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ad.id_evento
    LEFT JOIN public.tb_conta_eventos ce
           ON ce.id_evento = ad.id_evento
          AND ce.status::text = 'ATIVO'
    WHERE ad.status = 2
      AND (ad.inicio_ad IS NULL OR ad.inicio_ad <= now())
      AND (ad.final_ad IS NULL OR ad.final_ad >= now())
    <cfif isNumeric(URL.id_ad_evento) AND val(URL.id_ad_evento) GT 0>
      AND ad.id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.id_ad_evento)#"/>
    <cfelseif isNumeric(URL.id_evento) AND val(URL.id_evento) GT 0>
      AND ad.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.id_evento)#"/>
    <cfelse>
      AND 1 = 0
    </cfif>
    ORDER BY ad.inicio_ad DESC NULLS LAST,
             ad.id_ad_evento DESC
</cfquery>

<cfif NOT qAdsConversionClick.recordcount>
    <cfif isNumeric(URL.id_evento) AND val(URL.id_evento) GT 0>
        <cfquery name="qAdsConversionFallbackEvent" maxrows="1">
            SELECT tag, url_inscricao, url_hotsite
            FROM public.tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.id_evento)#"/>
        </cfquery>

        <cfif qAdsConversionFallbackEvent.recordcount>
            <cfset VARIABLES.adsConversionDestination = trim(qAdsConversionFallbackEvent.url_inscricao)/>
            <cfif NOT len(VARIABLES.adsConversionDestination)>
                <cfset VARIABLES.adsConversionDestination = trim(qAdsConversionFallbackEvent.url_hotsite)/>
            </cfif>
            <cfset VARIABLES.adsConversionDestination = adsConversionClickNormalizeDestination(VARIABLES.adsConversionDestination)/>
            <cfif NOT len(VARIABLES.adsConversionDestination)>
                <cfset VARIABLES.adsConversionDestination = adsConversionClickBuildEventUrl(qAdsConversionFallbackEvent.tag)/>
            </cfif>
            <cflocation addtoken="false" url="#VARIABLES.adsConversionDestination#"/>
        </cfif>
    </cfif>

    <cflocation addtoken="false" url="https://roadrunners.run/"/>
</cfif>

<cfset VARIABLES.adsConversionDestination = trim(qAdsConversionClick.url_inscricao)/>
<cfif NOT len(VARIABLES.adsConversionDestination)>
    <cfset VARIABLES.adsConversionDestination = trim(qAdsConversionClick.url_hotsite)/>
</cfif>
<cfset VARIABLES.adsConversionDestination = adsConversionClickNormalizeDestination(VARIABLES.adsConversionDestination)/>
<cfif NOT len(VARIABLES.adsConversionDestination)>
    <cfset VARIABLES.adsConversionDestination = adsConversionClickBuildEventUrl(qAdsConversionClick.tag)/>
</cfif>

<cfif ListFindNoCase(VARIABLES.adsConversionClickTables, "tb_ad_conversion_log")>
    <cfquery>
        INSERT INTO ads.tb_ad_conversion_log
        (
            id_ad_evento,
            id_evento,
            id_conta,
            id_usuario,
            tipo_conversion,
            valor,
            metadata
        )
        VALUES
        (
            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAdsConversionClick.id_ad_evento#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qAdsConversionClick.id_evento#"/>,
            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAdsConversionClick.id_conta#" null="#NOT len(trim(qAdsConversionClick.id_conta))#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#isDefined('COOKIE.id') AND isNumeric(COOKIE.id) ? val(COOKIE.id) : 0#" null="#NOT isDefined('COOKIE.id') OR NOT isNumeric(COOKIE.id)#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsConversionType#"/>,
            <cfqueryparam cfsqltype="cf_sql_numeric" value="0"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON({
                origem = trim(URL.origem),
                referer = structKeyExists(CGI, 'http_referer') ? CGI.http_referer : '',
                userAgent = structKeyExists(CGI, 'http_user_agent') ? CGI.http_user_agent : '',
                ip = structKeyExists(CGI, 'remote_addr') ? CGI.remote_addr : ''
            })#"/>::jsonb
        )
    </cfquery>
</cfif>

<cflocation addtoken="false" url="#VARIABLES.adsConversionDestination#"/>
