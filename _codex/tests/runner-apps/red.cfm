<cfscript>
catalog={};for(key in listToArray('roadRunnersAlt,roadRunners,openResultsAlt,openResults,runnersStoreAlt,runnersStore,desafioSupraAlt,desafioSupra,circuitoCatarinenseAlt,circuitoCatarinense,todoSantoDiaAlt,todoSantoDia,poweredBy'))catalog[key]=key;
REQUEST.i18n={common={appsMenu=catalog}};REQUEST.currentBaseUrl='https://roadrunners.run';REQUEST.i18nBuildPath=function(string p){return '/';};
APPLICATION.runnerAppsMenuCache={expiresAt=dateAdd('n',-1,now()),payload={success=true,items=[{label='last-known',href='/'}]}};
started=getTickCount();
include 'menu.cfm';
cfcontent(type='application/json',reset=true);
writeOutput(serializeJSON({stale_preserved=REQUEST.runnerAppsMenuItems[1].label=='last-known',elapsed_ms=getTickCount()-started}));
</cfscript>
