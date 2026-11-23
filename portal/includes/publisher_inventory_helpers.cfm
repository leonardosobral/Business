<cfif NOT structKeyExists(REQUEST,'publisherInventoryHelpers')>
<cfset REQUEST.publisherInventoryHelpers=true/>
<cfscript>
function publisherBannerChoices() {
 if(structKeyExists(REQUEST,'publisherBannerChoices')) return REQUEST.publisherBannerChoices;
 var choices=[{key='rr-sidebar-banner-300x250',label='RoadRunners — Banner lateral / celular',active=true,page='',region=''}];
 var ready=queryExecute("SELECT to_regclass('ads.publisher_spots') IS NOT NULL AS ready",{},{datasource='runnerhub'});
 if(ready.ready[1]) {
  var rows=queryExecute("SELECT p.placement_key,si.name AS site_name,sp.name,sp.width,sp.height,sp.page_key,sp.region_code,(si.status='ACTIVE' AND sp.status='ACTIVE' AND p.status='ACTIVE') AS active FROM ads.publisher_spots sp JOIN ads.publisher_sites si USING(site_id) JOIN ads.placements p USING(placement_id) ORDER BY si.name,sp.name",{},{datasource='runnerhub'});
  for(var r in rows) arrayAppend(choices,{key=r.placement_key,label=r.site_name & ' — ' & r.name & ' (' & r.width & ' × ' & r.height & ')' & (r.active ? '' : ' · Inativo'),active=r.active,page=r.page_key,region=r.region_code});
 }
 REQUEST.publisherBannerChoices=choices;
 return choices;
}
function publisherBannerLabel(required string key) {
 for(var choice in publisherBannerChoices()) if(choice.key==key) return choice.label;
 return 'Spot indisponível';
}
function publisherAssertPlacement(required string key) {
 for(var choice in publisherBannerChoices()) if(choice.key==key AND choice.active) return;
 throw(type='AdsV1.Validation',message='Selecione um site e spot ativo para o banner.');
}
</cfscript>
</cfif>
