<cfinclude template="../includes/backend/backend_login.cfm">
<cfinclude template="../includes/backend/require_admin_dev.cfm">
<cfinclude template="../includes/backend/require_real_platform_context.cfm">
<cfsetting showdebugoutput="false" requesttimeout="30">
<cfscript>
result={success=false,error='service_unavailable'};
statusCode=200;
try{
 if(CGI.REQUEST_METHOD!='POST')throw(type='CRM.Timeline',message='method_not_allowed');
 if(!structKeyExists(SESSION,'crmInternalCsrf')||!structKeyExists(FORM,'csrf')||compare(FORM.csrf,SESSION.crmInternalCsrf)!=0)throw(type='CRM.Timeline',message='forbidden');
 fromDay=structKeyExists(FORM,'from')?trim(FORM.from):'';
 toDay=structKeyExists(FORM,'to')?trim(FORM.to):'';
 if(!reFind('^\d{4}-\d{2}-\d{2}$',fromDay)||!reFind('^\d{4}-\d{2}-\d{2}$',toDay)||!isDate(fromDay)||!isDate(toDay)||dateDiff('d',fromDay,toDay)<0||dateDiff('d',fromDay,toDay)>93)throw(type='CRM.Timeline',message='invalid_payload');
 campaigns=queryExecute("SELECT campaign.campaign_id::text AS id,campaign.name,campaign.status,CASE WHEN EXISTS(SELECT 1 FROM ads.advertisements advertisement WHERE advertisement.campaign_id=campaign.campaign_id AND advertisement.ad_type='BANNER') THEN 'banner' ELSE 'ads' END AS kind,((campaign.starts_at AT TIME ZONE 'America/Sao_Paulo')::date)::text AS starts_day,(((campaign.ends_at - interval '1 microsecond') AT TIME ZONE 'America/Sao_Paulo')::date)::text AS ends_day FROM ads.campaigns campaign WHERE campaign.starts_at < (CAST(CAST(:to_day AS date)+1 AS timestamp) AT TIME ZONE 'America/Sao_Paulo') AND campaign.ends_at >= (CAST(CAST(:from_day AS date) AS timestamp) AT TIME ZONE 'America/Sao_Paulo') ORDER BY campaign.starts_at,campaign.campaign_id LIMIT 501",{from_day={value=fromDay,cfsqltype='cf_sql_varchar'},to_day={value=toDay,cfsqltype='cf_sql_varchar'}},{datasource='runnerhub'});
 items=[];
 for(index=1;index<=min(campaigns.recordCount,500);index++)arrayAppend(items,{id=campaigns.id[index],name=campaigns.name[index],status=campaigns.status[index],kind=campaigns.kind[index],starts_day=campaigns.starts_day[index],ends_day=campaigns.ends_day[index]});
 result={success=true,data={items=items,truncated=campaigns.recordCount>500}};
}catch(any error){
 known=listFind('method_not_allowed,forbidden,invalid_payload',error.message);
 result={success=false,error=known?error.message:'service_unavailable'};
 statusCode=error.message=='forbidden'?403:error.message=='method_not_allowed'?405:known?422:503;
}
cfcontent(type='application/json; charset=utf-8',reset=true);
cfheader(statuscode=statusCode);
cfheader(name='Cache-Control',value='no-store');
writeOutput(serializeJSON(result));
</cfscript>
