from pathlib import Path
p=Path(__file__).resolve().parent/'candidate'
def change(name,old,new):
 f=p/name;s=f.read_text();assert s.count(old)==1,(name,s.count(old));f.write_text(s.replace(old,new))
change('includes/estrutura/head.cfm','    <!--- REQUIRED META TAGS --->','''    <!--- Only editorial lists opt into page-aware language alternates. --->
    <cfparam name="VARIABLES.hreflangPage" type="integer" default="1"/>
    <cfset VARIABLES.hreflangQuery = VARIABLES.hreflangPage GT 1 ? "?page=" & VARIABLES.hreflangPage : ""/>

    <!--- REQUIRED META TAGS --->''')
f=p/'includes/estrutura/head.cfm';s=f.read_text();s=s.replace('REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, languageOption.code))','REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, languageOption.code) & VARIABLES.hreflangQuery)').replace("REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, 'pt-BR'))","REQUEST.i18nBuildAbsoluteUrl(REQUEST.currentRouteKey, 'pt-BR') & VARIABLES.hreflangQuery)");f.write_text(s)
change('videos/index.cfm',"<cfset VARIABLES.keywords = REQUEST.t('videos.meta.keywords')/>",'''<cfset VARIABLES.hreflangPage = URL.page/>
<cfif len(trim(VARIABLES.canalVideoSelecionadoNome))>
    <cfset VARIABLES.title = "#REQUEST.t('videos.meta.title')# - #HTMLEditFormat(VARIABLES.canalVideoSelecionadoNome)# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = HTMLEditFormat(VARIABLES.canalVideoSelecionadoNome) & ": " & VARIABLES.description/>
</cfif>
<cfif URL.page GT 1>
    <cfset VARIABLES.editorialPageLabel = REQUEST.t("videos.list.pageOf", {"page" = URL.page, "total" = VARIABLES.totalPaginasVideos})/>
    <cfset VARIABLES.title = VARIABLES.title & " - " & VARIABLES.editorialPageLabel/>
    <cfset VARIABLES.description = VARIABLES.editorialPageLabel & ". " & VARIABLES.description/>
</cfif>
<cfset VARIABLES.keywords = REQUEST.t('videos.meta.keywords')/>''')
change('noticias/index.cfm',"<cfset VARIABLES.keywords = REQUEST.t('news.meta.keywords')/>",'''<cfif NOT VARIABLES.isNoticiaDetalhe>
    <cfset VARIABLES.hreflangPage = URL.page/>
    <cfif len(trim(URL.canal)) AND structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "name")>
        <cfset VARIABLES.editorialChannelLabel = HTMLEditFormat(VARIABLES.canalNoticiasAtivoConfig.name)/>
        <cfset VARIABLES.title = "#REQUEST.t('news.meta.title')# - #VARIABLES.editorialChannelLabel# - #APPLICATION.nomeSite#"/>
        <cfset VARIABLES.description = VARIABLES.editorialChannelLabel & ": " & VARIABLES.description/>
    </cfif>
    <cfif URL.page GT 1>
        <cfset VARIABLES.editorialPageLabel = REQUEST.t("news.list.pageOf", {"page" = URL.page, "total" = VARIABLES.totalPaginasNoticias})/>
        <cfset VARIABLES.title = VARIABLES.title & " - " & VARIABLES.editorialPageLabel/>
        <cfset VARIABLES.description = VARIABLES.editorialPageLabel & ". " & VARIABLES.description/>
    </cfif>
</cfif>
<cfset VARIABLES.keywords = REQUEST.t('news.meta.keywords')/>''')
change('sitemaps/index.cfm','function renderUrlSet(required array items) output="false" {','''// Match the canonical/publication policy of noticias/index.cfm.
function newsHasLocalCanonical(required struct item, required string localUrl) output="false" {
    var mode = "";
    var sourceUrl = structKeyExists(arguments.item, "originalUrl") ? trim(arguments.item.originalUrl & "") : "";
    if (structKeyExists(arguments.item, "channel") && isStruct(arguments.item.channel)
        && structKeyExists(arguments.item.channel, "publicationMode")) {
        mode = lCase(trim(arguments.item.channel.publicationMode & ""));
    }
    if (mode EQ "external_only") return false;
    if (mode EQ "licensed_full" && reFindNoCase("^https?://", sourceUrl)) {
        return compare(sourceUrl, arguments.localUrl) EQ 0;
    }
    return true;
}

function renderUrlSet(required array items) output="false" {''')
change('sitemaps/index.cfm','''                    && (!structKeyExists(newsItem, "channel") || !isStruct(newsItem.channel)
                        || !structKeyExists(newsItem.channel, "publicationMode") || newsItem.channel.publicationMode NEQ "external_only")) {''','''                    && newsHasLocalCanonical(newsItem, baseUrl & "/noticias/" & trim(newsItem.slug & "") & "/")) {''')
