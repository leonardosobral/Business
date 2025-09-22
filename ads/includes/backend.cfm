<!--- WIDGETS --->

<cfquery name="qAdValorTotal">
    SELECT sum(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    AND log.status = 2
</cfquery>

<cfquery name="qAdValorMedio">
    SELECT avg(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    AND log.status = 2
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
</cfquery>

<cfquery name="qAdCountClicks">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    AND log.status = 2
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    AND ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
</cfquery>

<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAds">
    SELECT evt.*, ad.id_ad_evento,
    ad.cpc_max, ad.qualidade,
    (SELECT count(*) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento) as views,
    (SELECT count(*) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as clicks,
    (SELECT avg(valor_ad) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as cpc_medio,
    (SELECT sum(valor_ad) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as custo_total,
    (ad.qualidade * ad.cpc_max) as ad_rank
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    AND ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    ORDER BY ad_rank DESC
</cfquery>
