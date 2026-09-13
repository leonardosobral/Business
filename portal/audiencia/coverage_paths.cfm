<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
audCoveragePathsReady = structKeyExists(VARIABLES,"audienceCoveragePathsStatus")
    AND VARIABLES.audienceCoveragePathsStatus EQ "ready"
    AND structKeyExists(VARIABLES,"audienceCoveragePathsQuery") AND isQuery(VARIABLES.audienceCoveragePathsQuery);
if (audCoveragePathsReady) {
    for (audCoveragePathColumn in listToArray("page_folder,pageviews,pages_with_slots,opportunities,slot_views,last_received")) {
        if (NOT listFindNoCase(VARIABLES.audienceCoveragePathsQuery.columnList,audCoveragePathColumn)) audCoveragePathsReady = false;
    }
}
</cfscript>
<section class="audience-coverage-paths" id="cobertura-pastas" aria-labelledby="audience-coverage-paths-title">
    <h3 id="audience-coverage-paths-title" class="audience-section-title">Outras páginas · por primeira pasta</h3>
    <p class="audience-meta">Detalha a família “Outras páginas” pela primeira pasta dos caminhos de templates registrados na medição. Esses caminhos não representam necessariamente todas as URLs exibidas no navegador. Pastas ausentes ficam como “Pasta não identificada”.</p>
    <cfif NOT audCoveragePathsReady>
        <p class="audience-meta" role="status">O detalhamento por pastas está indisponível nesta consulta. Isso não significa ausência de acessos em “Outras páginas”.</p>
    <cfelseif NOT VARIABLES.audienceCoveragePathsQuery.recordcount>
        <p class="audience-meta" role="status">Nenhuma pasta de “Outras páginas” observada neste recorte.</p>
    <cfelse>
        <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Outras páginas por pasta; role horizontalmente para todas as métricas"><table class="table table-sm audience-coverage-paths-table"><thead><tr><th scope="col">Primeira pasta</th><th scope="col">Páginas vistas</th><th scope="col">Páginas com posições</th><th scope="col">Posições</th><th scope="col">Visíveis</th><th scope="col">Última recepção</th></tr></thead><tbody>
            <cfset audCoveragePaths = VARIABLES.audienceCoveragePathsQuery/>
            <cfoutput query="audCoveragePaths"><tr data-coverage-folder="#encodeForHtmlAttribute(page_folder)#">
                <th scope="row" class="audience-text"><cfif len(trim(page_folder))>#encodeForHtml(page_folder)#<cfelse>Pasta não identificada</cfif></th>
                <cfloop list="pageviews,pages_with_slots,opportunities,slot_views" index="audCoveragePathColumn"><td><cfif isNumeric(audCoveragePaths[audCoveragePathColumn][audCoveragePaths.currentRow])>#audienceCount(audCoveragePaths[audCoveragePathColumn][audCoveragePaths.currentRow])#<cfelse>—</cfif></td></cfloop>
                <td>#audienceDate(last_received)#</td>
            </tr></cfoutput>
        </tbody></table></div>
    </cfif>
</section>
