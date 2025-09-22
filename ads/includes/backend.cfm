<!--- WIDGETS --->

<cfquery name="qAdValorTotal">
    (select sum(valor_ad) as total from tb_ad_log log where status = 2)
</cfquery>

<cfquery name="qAdValorMedio">
    (select avg(valor_ad) as total from tb_ad_log log where status = 2)
</cfquery>

<cfquery name="qAdCountViews">
    (select count(*) as total from tb_ad_log log)
</cfquery>

<cfquery name="qAdCountClicks">
    (select count(*) as total from tb_ad_log log where status = 2)
</cfquery>

<cfquery name="qAdCountAds">
    select count(*) as total
    from tb_ad_eventos
    where status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
</cfquery>

<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAds">
    select evt.*, ad.id_ad_evento,
    ad.cpc_max, ad.qualidade,
    (select count(*) from tb_ad_log log where log.id_ad = ad.id_ad_evento) as views,
    (select count(*) from tb_ad_log log where log.id_ad = ad.id_ad_evento and status = 2) as clicks,
    (select avg(valor_ad) from tb_ad_log log where log.id_ad = ad.id_ad_evento and status = 2) as cpc_medio,
    (select sum(valor_ad) from tb_ad_log log where log.id_ad = ad.id_ad_evento and status = 2) as custo_total,
    (ad.qualidade * ad.cpc_max) as ad_rank
    from tb_ad_eventos ad
    inner join vw_evento_corridas evt on ad.id_evento = evt.id_evento
    where status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    order by ad_rank desc
</cfquery>
