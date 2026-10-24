function stravaBatchUpsertActivity(
    required struct activity,
    required numeric fallbackAthleteId,
    boolean requestStreams = false
) {
    var activityId = structKeyExists(arguments.activity, "id") ? val(arguments.activity.id) : 0;
    var athleteId = arguments.fallbackAthleteId;
    var startDate = structKeyExists(arguments.activity, "start_date") ? trim(arguments.activity.start_date & "") : "";
    var localStartDate = structKeyExists(arguments.activity, "start_date_local") ? trim(arguments.activity.start_date_local & "") : startDate;
    var activityType = structKeyExists(arguments.activity, "type") ? trim(arguments.activity.type & "") : "";

    if (structKeyExists(arguments.activity,"athlete") AND isStruct(arguments.activity.athlete)
        AND structKeyExists(arguments.activity.athlete,"id") AND isNumeric(arguments.activity.athlete.id)) {
        athleteId = val(arguments.activity.athlete.id);
    }
    if (!activityId OR !athleteId OR !len(startDate)) {
        return false;
    }
    if (!len(activityType) AND structKeyExists(arguments.activity,"sport_type")) {
        activityType = trim(arguments.activity.sport_type & "");
    }

    // start_date stores Sao Paulo wall time; bind the Strava ISO instant as text
    // so JVM/JDBC/session timezones cannot reinterpret it. activity_date is the athlete local day.
    captureBatchQuery(
        "INSERT INTO tb_strava_activities
         (activity_id,athlete_id,distance,moving_time,type,start_date,activity_date,title,resource_state,
          total_elevation_gain,strava_raw,processed,elapsed_time,strava_streams_status)
         VALUES (:activity_id,:athlete_id,:distance,:moving_time,:activity_type,
                 (CAST(:start_date AS timestamp with time zone) AT TIME ZONE 'America/Sao_Paulo'),
                 CAST(:activity_date AS date),:title,
                 :resource_state,:elevation,CAST(:raw_json AS jsonb),true,:elapsed_time,:streams_status)
         ON CONFLICT (activity_id) DO UPDATE SET athlete_id=excluded.athlete_id,distance=excluded.distance,
         moving_time=excluded.moving_time,type=excluded.type,start_date=excluded.start_date,activity_date=excluded.activity_date,
         title=excluded.title,resource_state=excluded.resource_state,total_elevation_gain=excluded.total_elevation_gain,
         strava_raw=excluded.strava_raw,processed=true,
         elapsed_time=coalesce(excluded.elapsed_time,tb_strava_activities.elapsed_time),
         strava_streams_status=CASE
             WHEN excluded.strava_streams_status='pending'
              AND tb_strava_activities.strava_streams_status='not_requested' THEN 'pending'
             ELSE tb_strava_activities.strava_streams_status
         END,
         updated=now()",
        {
            activity_id={value=activityId,cfsqltype="cf_sql_bigint"}, athlete_id={value=athleteId,cfsqltype="cf_sql_bigint"},
            distance={value=structKeyExists(arguments.activity,"distance") ? val(arguments.activity.distance) : 0,cfsqltype="cf_sql_float"},
            moving_time={value=structKeyExists(arguments.activity,"moving_time") ? val(arguments.activity.moving_time) : 0,cfsqltype="cf_sql_integer"},
            activity_type={value=activityType,cfsqltype="cf_sql_varchar",null=!len(activityType)},
            start_date={value=startDate,cfsqltype="cf_sql_varchar"}, activity_date={value=left(localStartDate,10),cfsqltype="cf_sql_varchar"},
            title={value=structKeyExists(arguments.activity,"name") ? arguments.activity.name : "",cfsqltype="cf_sql_varchar"},
            resource_state={value=structKeyExists(arguments.activity,"resource_state") ? val(arguments.activity.resource_state) : 0,cfsqltype="cf_sql_integer"},
            elevation={value=structKeyExists(arguments.activity,"total_elevation_gain") ? val(arguments.activity.total_elevation_gain) : 0,cfsqltype="cf_sql_float"},
            raw_json={value=serializeJSON(arguments.activity),cfsqltype="cf_sql_longvarchar"},
            elapsed_time={
                value=structKeyExists(arguments.activity,"elapsed_time") ? val(arguments.activity.elapsed_time) : 0,
                cfsqltype="cf_sql_integer",
                null=!structKeyExists(arguments.activity,"elapsed_time")
            },
            streams_status={
                value=arguments.requestStreams ? "pending" : "not_requested",
                cfsqltype="cf_sql_varchar"
            }
        },
        {datasource="runner_dba"}
    );
    return true;
}


function captureBatchQuery(required string sql,required struct params,required struct options){
 var valuesStart=findNoCase("VALUES (",sql)+8;
 var valuesEnd=findNoCase(")\n         ON CONFLICT",sql);
 var valuesText=mid(sql,valuesStart,valuesEnd-valuesStart);
 var projection="SELECT jsonb_build_object('start_date',start_date,'activity_date',activity_date)::text AS payload FROM (VALUES (" & valuesText & ")) AS v(activity_id,athlete_id,distance,moving_time,type,start_date,activity_date,title,resource_state,total_elevation_gain,strava_raw,processed,elapsed_time,strava_streams_status)";
 variables.boundDates=deserializeJSON(queryExecute(projection,params,{datasource="runner_dba",timeout=10}).payload[1]);
}
cases=[
 {utc="2026-10-12T00:26:33Z",local="2026-10-11T21:26:33Z",expected="2026-10-11T21:26:33",day="2026-10-11"},
 {utc="2026-10-12T03:00:00Z",local="2026-10-12T00:00:00Z",expected="2026-10-12T00:00:00",day="2026-10-12"},
 {utc="2026-01-01T01:00:00Z",local="2025-12-31T22:00:00Z",expected="2025-12-31T22:00:00",day="2025-12-31"},
 {utc="2026-10-12T00:26:33+00:00",local="2026-10-11T21:26:33Z",expected="2026-10-11T21:26:33",day="2026-10-11"},
 {utc="2026-10-12T03:30:00Z",local="2026-10-11T23:30:00Z",expected="2026-10-12T00:30:00",day="2026-10-11"}
];
results=[];
transaction {
 queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});
 for (tz in ["UTC","America/Sao_Paulo","Asia/Tokyo"]){
  queryExecute("SELECT set_config('TimeZone',:tz,true)",{tz={value=tz,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
  for(c in cases){
   result=stravaBatchUpsertActivity({id=1,athlete={id=1},type="Run",start_date=c.utc,start_date_local=c.local},1,false);
   if(!result OR boundDates.start_date NEQ c.expected OR boundDates.activity_date NEQ c.day){throw(message="Explicit timezone contract failed",detail=serializeJSON({zone=tz,actual=boundDates,expected=c}));}
   arrayAppend(results,{zone=tz,start=boundDates.start_date,day=boundDates.activity_date,passed=true});
  }
 }
}
writeOutput(serializeJSON({passed=arrayLen(results),cases=results,jvmZone=createObject("java","java.util.TimeZone").getDefault().getID()}));
