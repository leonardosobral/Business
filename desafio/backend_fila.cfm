<cfif isDefined("URL.reprocessar")>
    <cfquery>
        update tb_strava_activities set processed = false where type is null;
    </cfquery>
</cfif>

<cfquery name="qStatsEvento">
    select act.athlete_id, MAX(activity_id) as activity_id, act.athlete_id,
    usr.id, usr.strava_code, usr.strava_id, to_timestamp(usr.strava_expires_at) as strava_expires_at, usr.estado, usr.name,
    pag.tag,
    MAX(act.start_date) as start_date
    from tb_strava_activities act
    inner join tb_usuarios usr ON usr.strava_id = act.athlete_id
    inner join public.desafio_cna dc on usr.id = dc.id_usuario
    --LEFT join public.desafio_366_inscritos d366i on dc.id_usuario = d366i.id_usuario
    LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id
    where act.processed = false and act.start_date::date >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()-2#"/>
    --and act.type is null
    group by act.athlete_id, act.athlete_id,
    usr.id, usr.strava_code, usr.strava_id, to_timestamp(usr.strava_expires_at), usr.estado, usr.name,
    pag.tag
    order by start_date #URL.order#;
</cfquery>
