<cfscript>
// Catches missing transaction context, substituted actor, wrong datasource and pooled context leaks.
adsDsn='business_delegation_runtime';
adsRole=queryExecute("SELECT current_user AS role,has_table_privilege(current_user,'ads.campaigns','UPDATE') AS can_write, (SELECT rolsuper FROM pg_roles WHERE rolname=current_user) AS is_super",{},{datasource=adsDsn});
assertEqual(adsRole.role[1],'runnerhub','real constrained runtime login');assertEqual(adsRole.can_write[1],false,'runtime cannot write canonical campaign table');assertEqual(adsRole.is_super[1],false,'runtime is not superuser');
adsService=createObject('component','services.BusinessAccountDelegation').init(adsDsn,true);
adsContext=adsService.resolve({id=902},{accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001});
adsPayload={"name"='CF delegated actual actor',"placement_key"='rr-sidebar-banner-300x250',"image_url_desktop"='https://example.test/d.png',"width_desktop"=300,"height_desktop"=250,"image_url_mobile"='https://example.test/m.png',"width_mobile"=300,"height_mobile"=250,"alt_text"='Fixture',"destination_url"='https://example.test/brand',"open_new_tab"=false,"starts_at"=dateTimeFormat(dateAdd('h',-1,now()),"yyyy-mm-dd'T'HH:nn:ssXXX"),"ends_at"=dateTimeFormat(dateAdd('d',1,now()),"yyyy-mm-dd'T'HH:nn:ssXXX"),"cpc_bid"=1,"budget_total"=10,"budget_daily"=5,"target_device"='ALL',"banner_scope_v1"={"regions_mode"='ALL',"regions"=[],"pages_mode"='ALL',"pages"=[]}};
// JSON keys supplied to canonical SQL are lower case independent of CFML serialization settings.
adsPayloadJSON=serializeJSON(adsPayload);
adsWork=function(fresh){
 var saved=queryExecute('SELECT * FROM ads.save_paid_banner_campaign(NULL,:account,:actor,CAST(:payload AS jsonb),true)',{account={value=fresh.accountId,cfsqltype='cf_sql_bigint'},actor={value=fresh.actorId,cfsqltype='cf_sql_integer'},payload={value=adsPayloadJSON,cfsqltype='cf_sql_varchar'}},{datasource=fresh.datasource});
 var connection=queryExecute("SELECT pg_backend_pid() AS pid,current_setting('business.delegation_context',true) AS context",{},{datasource=fresh.datasource});
 assertEqual(deserializeJSON(connection.context[1]).actorId & '', '902','context uses actual actor');
 return {id=saved.campaign_id[1],pid=connection.pid[1]};
};
adsSaved=adsService.withMutation(adsContext,'ads.campaigns.manage',adsContext,{type='ACCOUNT',id=102},adsWork);
adsRow=queryExecute('SELECT created_by,updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=adsSaved.id,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
assertEqual(adsRow.created_by[1],902,'CF created_by actual actor');assertEqual(adsRow.updated_by[1],902,'CF updated_by actual actor');
adsConnection=queryExecute("SELECT pg_backend_pid() AS pid,coalesce(current_setting('business.delegation_context',true),'') AS context",{},{datasource=adsDsn});
assertEqual(adsConnection.pid[1],adsSaved.pid,'same pooled connection after commit');assertEqual(adsConnection.context[1],'','commit clears context');
adsCount=queryExecute('SELECT count(*) AS n FROM ads.campaigns',{},{datasource='business_delegation_test'}).n[1];
adsFailedWork=function(fresh){adsWork(fresh);throw(type='AdsIntentionalRollback',message='after canonical mutation');};
assertThrowsType(function(){adsService.withMutation(adsContext,'ads.campaigns.manage',adsContext,{type='ACCOUNT',id=102},adsFailedWork);},'AdsIntentionalRollback','callback failure rolls back');
assertEqual(queryExecute('SELECT count(*) AS n FROM ads.campaigns',{},{datasource='business_delegation_test'}).n[1],adsCount,'failed callback leaves no campaign');
adsConnection=queryExecute("SELECT pg_backend_pid() AS pid,coalesce(current_setting('business.delegation_context',true),'') AS context",{},{datasource=adsDsn});
assertEqual(adsConnection.pid[1],adsSaved.pid,'same pooled connection after rollback');assertEqual(adsConnection.context[1],'','rollback clears context');
assertThrowsType(function(){createObject('component','services.BusinessAccountDelegation').init(adsDsn,false).withMutation(adsContext,'ads.campaigns.manage',adsContext,{type='ACCOUNT',id=102},adsWork);},'BusinessDelegation.Unavailable','disabled facade refuses mutation');
assertEqual(queryExecute('SELECT count(*) AS n FROM ads.campaigns',{},{datasource='business_delegation_test'}).n[1],adsCount,'disabled service leaves no campaign');
assertThrowsType(function(){createObject('component','services.BusinessAccountDelegation').init('business_delegation_unconfigured',false).withMutation(adsContext,'ads.campaigns.manage',adsContext,{type='ACCOUNT',id=102},adsWork);},'BusinessDelegation.Unavailable','disabled service refuses before opening any datasource');
writeOutput('PASS ads-db constrained runtime role CFML canonical save/submit, disabled facade and same pooled connection commit/rollback' & chr(10));
</cfscript>
