<cfscript>
fixtureRoot=getDirectoryFromPath(getCurrentTemplatePath());
fixtureMappings=duplicate(getApplicationSettings().mappings);
fixtureMappings['/services']=fixtureRoot & 'services';
application action='update' mappings=fixtureMappings datasources={locale_test={
    class='org.postgresql.Driver',bundleName='org.postgresql.jdbc',bundleVersion='42.2.20',
    connectionString='jdbc:postgresql://127.0.0.1:' & createObject('java','java.lang.System').getenv('RR_DESCRIPTION_LOCALES_TEST_PG_PORT') & '/postgres',
    username='locale_test',password=''
},locale_reader={
    class='org.postgresql.Driver',bundleName='org.postgresql.jdbc',bundleVersion='42.2.20',
    connectionString='jdbc:postgresql://127.0.0.1:' & createObject('java','java.lang.System').getenv('RR_DESCRIPTION_LOCALES_TEST_PG_PORT') & '/postgres',
    username='locale_reader',password=''
}};
checks=0;
fixtureReadDatasource="locale_test";
function check(required boolean condition,required string label) {
    if(!arguments.condition)throw(type='AssertionFailed',message=arguments.label);
    VARIABLES.checks++;
}
function sql(required string statement,struct params={}) {return queryExecute(arguments.statement,arguments.params,{datasource='locale_test'});}
service=new services.EventDescriptionLocaleService();
sql('CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,descricao text)');
sql("INSERT INTO public.tb_evento_corridas VALUES(1,'Texto português 5 km às 07:00.')");
check(!service.isSchemaReady('locale_test'),'Missing migration is detected without accessing missing columns');
function selectDescription(required string language,boolean schemaReady=true) {
    VARIABLES.eventDescriptionSelection=VARIABLES.service.selectionFor(arguments.language,arguments.schemaReady);
    include 'fixture_query.cfm';
    return VARIABLES.fixtureLocaleQuery;
}
function want(required string language,required string expectedText,required string expectedLanguage,boolean schemaReady=true) {
    var row=selectDescription(arguments.language,arguments.schemaReady);
    check(row.descricao[1] EQ arguments.expectedText AND row.descricao_idioma[1] EQ arguments.expectedLanguage,arguments.language & ': correct text and language');
    check(listLen(row.columnList) EQ 2,'No extra language/source texts are fetched');
}
want('en','Texto português 5 km às 07:00.','pt-BR',false);
want('pt-BR','Texto português 5 km às 07:00.','pt-BR');
want("en';DROP TABLE tb_evento_corridas;--",'Texto português 5 km às 07:00.','pt-BR');
sql('ALTER TABLE public.tb_evento_corridas ADD descricao_en text,ADD descricao_es text');
check(!service.isSchemaReady('locale_test'),'Text columns alone do not enable metadata validation');
sql('ALTER TABLE public.tb_evento_corridas ADD descricao_traducoes_meta jsonb');
check(service.isSchemaReady('locale_test'),'Three columns enable translations without audit access');
want('en','Texto português 5 km às 07:00.','pt-BR');
sql("UPDATE public.tb_evento_corridas SET descricao_en='English 5 km at 07:00.',descricao_es='Español 5 km a las 07:00.'");
want('en','English 5 km at 07:00.','en');
want('es','Español 5 km a las 07:00.','es');
sql("UPDATE public.tb_evento_corridas SET descricao_traducoes_meta=jsonb_build_object('en',jsonb_build_object('source_hash',md5(descricao),'description_hash',md5(descricao_en)))");
want('en','English 5 km at 07:00.','en');
sql("UPDATE public.tb_evento_corridas SET descricao='Texto português 10 km às 08:00.'");
want('en','Texto português 10 km às 08:00.','pt-BR');
want('es','Español 5 km a las 07:00.','es');
sql("UPDATE public.tb_evento_corridas SET descricao_en='Manual English 10 km at 08:00.'");
want('en','Manual English 10 km at 08:00.','en');
sql("UPDATE public.tb_evento_corridas SET descricao_en='English 5 km at 07:00.'");
want('en','Texto português 10 km às 08:00.','pt-BR');
sql("UPDATE public.tb_evento_corridas SET descricao_en='Updated English 10 km at 08:00.'");
sql("UPDATE public.tb_evento_corridas SET descricao_traducoes_meta=jsonb_build_object('en',jsonb_build_object('source_hash',md5(descricao),'description_hash',md5(descricao_en)))");
want('en','Updated English 10 km at 08:00.','en');
// A reader has only SELECT on the event table and no audit table even exists.
sql('CREATE ROLE locale_reader LOGIN');
sql('GRANT SELECT ON public.tb_evento_corridas TO locale_reader');
fixtureReadDatasource='locale_reader';
check(service.isSchemaReady('locale_reader'),'Portal reader can inspect readiness with existing SELECT access');
want('en','Updated English 10 km at 08:00.','en');
want('es','Español 5 km a las 07:00.','es');
for(badMeta in ['[]','null','"unknown"','{"en":null}','{"en":[]}','{"en":{}}','{"en":{"source_hash":"bad","description_hash":"bad"}}','{"en":{"source_hash":"00000000000000000000000000000000","description_hash":12345678901234567890123456789012}}']) {
    sql('UPDATE public.tb_evento_corridas SET descricao_traducoes_meta=CAST(:meta AS jsonb)',{meta={value=badMeta,cfsqltype='cf_sql_longvarchar'}});
    want('en','Texto português 10 km às 08:00.','pt-BR');
}
sql("UPDATE public.tb_evento_corridas SET descricao_traducoes_meta=jsonb_build_object('es',false)");
want('en','Updated English 10 km at 08:00.','en');
want('es','Texto português 10 km às 08:00.','pt-BR');
sql("UPDATE public.tb_evento_corridas SET descricao_traducoes_meta=jsonb_build_object('en',jsonb_build_object('source_hash',md5(descricao),'description_hash',md5(descricao_en)))");
sql("UPDATE public.tb_evento_corridas SET descricao=NULL");
want('en','','pt-BR');
sql("UPDATE public.tb_evento_corridas SET descricao='Texto português 10 km às 08:00.',descricao_en='   '");
want('en','Texto português 10 km às 08:00.','pt-BR');
function rendered(required string language,required string text,required string textLanguage) {
    REQUEST.lang=arguments.language;
    var localesCatalog={};
    include 'i18n/' & arguments.language & '.cfm';
    VARIABLES.eventDescriptionCatalog=localesCatalog.event.description;
    VARIABLES.qEvento=queryNew('descricao,descricao_idioma','varchar,varchar',[{descricao=arguments.text,descricao_idioma=arguments.textLanguage}]);
    var output='';
    savecontent variable='output' {include 'evento/parts/descricao_localizada.cfm';}
    return output;
}
html=rendered('en','Texto português<br>5 km às 07:00.','pt-BR');
check(find('lang="pt-BR"',html) GT 0 AND find('Portuguese',html) GT 0,'English fallback identifies Portuguese text');
check(find('Texto português<br>5 km às 07:00.',html) GT 0,'Original HTML and facts remain unchanged');
html=rendered('es','Texto português','pt-BR');
check(find(encodeForHTML('portugués'),html) GT 0,'Spanish fallback identifies Portuguese text');
html=rendered('en','English 5 km at 07:00.','en');
check(find('lang="en"',html) GT 0 AND !find('Portuguese',html),'Translated body has correct lang without fallback warning');
html=rendered('pt-BR','Texto português','pt-BR');
check(!find('event-description-fallback',html),'PT body does not show a fallback warning');
html=rendered('en','','pt-BR');
check(!len(trim(html)),'Missing description leaves existing localized generic fallback alone');
writeOutput('RR_DESCRIPTION_LOCALES_PASSED:' & checks);
</cfscript>
