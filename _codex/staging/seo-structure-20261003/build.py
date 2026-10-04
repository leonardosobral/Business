from pathlib import Path
import shutil

STAGE=Path(__file__).resolve().parent
def replace_once(text,old,new):
    assert text.count(old)==1,repr(old[:90])
    return text.replace(old,new,1)
def save(project,name,text):
    path=STAGE/'candidate'/project/name
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(text)

name='includes/estrutura/home_hero_busca.cfm'
text=(STAGE/'baseline/RoadRunners'/name).read_text()
assert text.count('.home-hero-copy h1')==2
text=text.replace('.home-hero-copy h1','.home-hero-copy .home-hero-headline')
text=replace_once(text,'        line-height: 0.98;','        font-weight: 500;\n        line-height: 0.98;')
old='''            <cfif NOT (isDefined("VARIABLES.template") AND VARIABLES.template EQ "/busca/")>
                <h1 class="mb-2">
                    <cfoutput>#HTMLEditFormat(VARIABLES.homeHeroHeadline)#</cfoutput>
                </h1>
            </cfif>'''
new='''            <cfif isDefined("VARIABLES.template") AND VARIABLES.template EQ "/">
                <h1 class="home-hero-headline mb-2">
                    <cfoutput>#HTMLEditFormat(VARIABLES.homeHeroHeadline)#</cfoutput>
                </h1>
            <cfelseif isDefined("VARIABLES.template") AND VARIABLES.template EQ "/busca/">
                <h1 class="h4 mb-2"><cfoutput>#HTMLEditFormat(REQUEST.t("search.legacy.heroTitle"))#</cfoutput></h1>
            <cfelse>
                <p class="home-hero-headline mb-2">
                    <cfoutput>#HTMLEditFormat(VARIABLES.homeHeroHeadline)#</cfoutput>
                </p>
            </cfif>'''
save('RoadRunners',name,replace_once(text,old,new))

name='evento/index.cfm'
text=(STAGE/'baseline/RoadRunners'/name).read_text()
local=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
current=(local/name).read_text()
old='''    if (qFornecedores.recordcount) {
        VARIABLES.eventSchema.organizer = structNew("ordered");
        VARIABLES.eventSchema.organizer["@type"] = "Organization";
        VARIABLES.eventSchema.organizer.name = qFornecedores.nome_fornecedor & "";
        if (len(trim(qFornecedores.site_fornecedor & ""))) {
            VARIABLES.eventSchema.organizer.url = trim(qFornecedores.site_fornecedor & "");
        }
    }'''
start=current.index('    for (eventSchemaSupplierRow = 1;')
end=current.index('\n\n    VARIABLES.structuredDataJsonLd',start)
save('RoadRunners',name,replace_once(text,old,current[start:end]))
for group in ['baseline','candidate']:
    path=STAGE/group/'RoadRunners/services/EventRegistrationAvailability.cfc'
    path.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(local/'services/EventRegistrationAvailability.cfc',path)

name='index.cfm'
text=(STAGE/'baseline/OpenResults'/name).read_text()
text=replace_once(text,'        .home-search-icon {\n            display: none;',
'''        .home-search-heading {
            font-size: 1rem;
            font-weight: 400;
            line-height: 1.6;
        }

        .home-search-icon {
            display: none;''')
text=replace_once(text,'<p class="text-gray-light mb-4"><span class="home-search-intro">Pesquise em</span><i class="fa-solid fa-magnifying-glass home-search-icon me-1" role="img" aria-label="Pesquise em"></i> <cfoutput><strong>#lsNumberFormat(qTotalResultados.total)#</strong> de resultados oficiais.</cfoutput></p>',
 '<h1 class="home-search-heading text-gray-light mb-4"><span class="home-search-intro">Pesquise entre</span><i class="fa-solid fa-magnifying-glass home-search-icon me-1" role="img" aria-label="Pesquise entre"></i> <cfoutput><strong>#lsNumberFormat(qTotalResultados.total)#</strong> resultados oficiais.</cfoutput></h1>')
save('OpenResults',name,text)
name='robots.txt'
text=(STAGE/'baseline/OpenResults'/name).read_text()
text=replace_once(text,'Disallow: /nogooglebot/','Disallow: /nogooglebot/\nDisallow: /perfil\nDisallow: /resultados')
save('OpenResults',name,text)
print('Four runtime candidates prepared from production; schema dependency copied only for tests.')
