<cfinclude template="../../includes/backend/require_admin.cfm"/>
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
