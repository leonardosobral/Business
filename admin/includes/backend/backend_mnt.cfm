<cfquery name="qEventosBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 5)#">
    select imp.*, usr.name, usr.email
    from tb_evento_corridas_importacao imp
    inner join public.tb_usuarios usr on imp.id_usuario = usr.id
    where imp.id_usuario is not null
    order by id_evento desc
</cfquery>

<cfquery name="qEventos" dbtype="query">
    SELECT *
    FROM qEventosBase
</cfquery>
