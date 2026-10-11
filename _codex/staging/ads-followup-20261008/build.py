from pathlib import Path
p=Path(__file__).parent;b=p/'baseline';c=p/'candidate/Business'
def put(n,s):
 t=c/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s)
put('portal/audiencia/queries/advertiser_acquisition.sql', '''/* AUDIENCE_FILTER */
, deliveries AS (
 SELECT source, medium, campaign, campaign_id, delivery_id,
        bool_or(event_kind='ad_render') AS rendered,
        bool_or(event_kind='ad_viewable') AS viewed,
        count(DISTINCT session_id) FILTER (WHERE event_kind='ad_viewable') AS view_sessions
 FROM filtered
 WHERE campaign <> '' AND campaign_id IS NOT NULL AND delivery_id IS NOT NULL
   AND event_kind IN ('ad_render','ad_viewable') AND slot_state='filled'
 GROUP BY source,medium,campaign,campaign_id,delivery_id
), clicks AS (
 SELECT DISTINCT e.delivery_id, e.campaign_id
 FROM ads.events e
 JOIN (SELECT DISTINCT delivery_id,campaign_id FROM deliveries) d USING(delivery_id,campaign_id)
 WHERE e.event_type='CLICK' AND e.valid
   AND e.received_at >= (date_trunc('day',now() AT TIME ZONE 'America/Sao_Paulo')
       - (CAST(:days AS integer)-1)*interval '1 day') AT TIME ZONE 'America/Sao_Paulo'
   AND e.received_at <= now()
), reach AS (
 SELECT source,medium,campaign,campaign_id,count(DISTINCT session_id) AS view_sessions
 FROM filtered WHERE campaign<>'' AND campaign_id IS NOT NULL AND delivery_id IS NOT NULL
   AND event_kind='ad_viewable' AND slot_state='filled'
 GROUP BY source,medium,campaign,campaign_id
)
SELECT d.source,d.medium,d.campaign,d.campaign_id::text AS advertiser_id,
       coalesce(nullif(c.name,''),d.campaign_id::text) AS advertiser_name,
       count(*) FILTER(WHERE d.rendered) AS rendered_deliveries,
       count(*) FILTER(WHERE d.viewed) AS viewed_deliveries,
       coalesce(max(r.view_sessions),0) AS view_sessions,
       count(*) FILTER(WHERE k.delivery_id IS NOT NULL) AS clicked_deliveries,
       count(*) FILTER(WHERE k.delivery_id IS NOT NULL AND d.viewed) AS viewed_clicked_deliveries
FROM deliveries d
LEFT JOIN ads.campaigns c ON c.campaign_id=d.campaign_id
LEFT JOIN clicks k ON k.delivery_id=d.delivery_id AND k.campaign_id=d.campaign_id
LEFT JOIN reach r ON r.source=d.source AND r.medium=d.medium AND r.campaign=d.campaign AND r.campaign_id=d.campaign_id
GROUP BY d.source,d.medium,d.campaign,d.campaign_id,c.name
ORDER BY view_sessions DESC,viewed_deliveries DESC,d.campaign,advertiser_name
LIMIT 101
''')
s=b.joinpath('audience_backend.cfm').read_text();anchor='        // Optional operational state must never make the audience report unavailable.'
assert anchor in s
s=s.replace(anchor,'''        // Read-only linkage by delivery UUID; never writes Ads/billing or estimates missing attribution.
        VARIABLES.audienceAdvertiserUnavailable = false;
        try {
            VARIABLES.audienceAdvertiserSql = replace(fileRead(VARIABLES.audienceQueryDirectory & "advertiser_acquisition.sql","UTF-8"),"/* AUDIENCE_FILTER */",VARIABLES.audienceFilterSql);
            VARIABLES.audienceAdvertiserQuery = queryExecute(VARIABLES.audienceAdvertiserSql,VARIABLES.audienceParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
        } catch(any advertiserReadError) {
            VARIABLES.audienceAdvertiserUnavailable = true;
            writeLog(file="audience_measurement",type="error",text="Business advertiser acquisition report unavailable: " & left(advertiserReadError.type & "",100));
        }
'''+anchor)
put('portal/includes/audience_backend.cfm',s)
s=b.joinpath('home.cfm').read_text();s=s.replace('<a href="#audience-coverage">Cobertura</a>','<a href="#audience-advertisers">Retorno aos anunciantes</a><a href="#audience-coverage">Cobertura</a>')
anchor='        <div class="audience-tab-panel" data-audience-panel id="audience-coverage">';assert anchor in s
s=s.replace(anchor,'''        <div class="audience-tab-panel" data-audience-panel id="audience-advertisers">
            <cfinclude template="advertiser_acquisition.cfm"/>
        </div>

'''+anchor);put('portal/audiencia/home.cfm',s)
put('portal/audiencia/advertiser_acquisition.cfm','''<cfinclude template="../../includes/backend/require_admin.cfm"/>
<section class="audience-panel">
<h2 class="h5">Da campanha de aquisição ao anunciante</h2>
<p class="audience-meta">Veja quais anúncios comerciais receberam exposição e cliques do público trazido por cada campanha UTM. O recorte segue os filtros gerais; a origem é a do início da sessão, não o último clique pago.</p>
<cfif NOT structKeyExists(VARIABLES,"audienceAdvertiserUnavailable") OR VARIABLES.audienceAdvertiserUnavailable>
    <p class="audience-note" role="status">Relatório indisponível no momento. Isso não significa ausência de exposição ou cliques.</p>
<cfelse>
<cfset audAdvertisers=VARIABLES.audienceAdvertiserQuery/>
<div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Exposição e cliques por origem e anunciante">
<table class="table table-sm"><thead><tr><th scope="col">Campanha de aquisição</th><th scope="col">Anúncio no portal</th><th scope="col">Entregas renderizadas</th><th scope="col">Entregas vistas</th><th scope="col">Sessões com exposição</th><th scope="col">Entregas com clique válido</th><th scope="col">Vistas com clique</th></tr></thead><tbody>
<cfoutput query="audAdvertisers" maxrows="100"><tr>
<td class="audience-text">#encodeForHtml(campaign)#<div class="audience-meta">#encodeForHtml(source)# / #encodeForHtml(medium)#</div></td>
<td class="audience-text">#encodeForHtml(advertiser_name)#</td>
<td>#audienceCount(rendered_deliveries)#</td><td>#audienceCount(viewed_deliveries)#</td><td>#audienceCount(view_sessions)#</td><td>#audienceCount(clicked_deliveries)#</td>
<td>#audienceCount(viewed_clicked_deliveries)#<div class="audience-meta">#audienceRate(viewed_clicked_deliveries,viewed_deliveries)# das vistas</div></td>
</tr></cfoutput>
<cfif NOT audAdvertisers.recordcount><tr><td colspan="7">Nenhuma entrega comercial vinculada a uma campanha UTM neste recorte.</td></tr></cfif>
</tbody></table></div>
<cfif audAdvertisers.recordcount GT 100><p class="audience-meta">Exibindo as 100 combinações com mais sessões expostas.</p></cfif>
</cfif>
<p class="audience-meta">Exposição: ao menos 50% da peça visível por 1 segundo. Cada entrega e cada sessão são contadas uma vez por combinação de origem, campanha de aquisição e anúncio. Uma sessão pode ver vários anunciantes; não some as linhas como pessoas distintas.</p>
<p class="audience-meta mb-0">Cliques válidos vêm do sistema Ads, vinculados pelo identificador da entrega e limitados ao período. Uma entrega com clique pode não ter exposição confirmada. Banners sem identificador de entrega, peças institucionais e visitas sem UTM ficam fora deste relatório. Bloqueios e falhas de coleta limitam a cobertura. Estes números não representam inscrições, receita ou créditos faturáveis.</p>
</section>
''')
print('4 Business candidates ready')
