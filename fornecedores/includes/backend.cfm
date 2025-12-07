<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAdsBase">
    SELECT * from tb_fornecedores
</cfquery>

<cfquery name="qEventosAds" dbtype="query">
    select * from qEventosAdsBase
    where status < 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsPausados" dbtype="query">
    select * from qEventosAdsBase
    where status = 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsFinalizados" dbtype="query">
    select * from qEventosAdsBase
    where status = 4
    order by clicks desc, views desc
</cfquery>
