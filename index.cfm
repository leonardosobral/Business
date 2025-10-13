<cfif isDefined("COOKIE.id")>

    <cfquery name="qPerfil">
        SELECT usr.id, usr.name, usr.email, usr.is_admin, usr.is_partner, usr.is_dev, usr.strava_id, usr.aka, usr.fonte_lead,
        coalesce('/assets/paginas/' || pg.path_imagem, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
        pg.tag, pg.tag_prefix, pg.id_pagina, coalesce(pg.nome, usr.name) as nome, pg.verificado, pg.cidade, pg.uf,
        pg.instagram, pg.youtube, pg.tiktok, pg.website, pg.loja, pg.whatsapp, pg.whatsapp_publico, pg.descricao
        FROM tb_usuarios usr
        inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
        inner join tb_paginas pg on pg.id_pagina = pgusr.id_pagina
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>

    <cfif qPerfil.recordcount AND qPerfil.is_partner>

        <cfinclude template="home_logado.cfm"/>

    <cfelse>

        <cflocation url="/inscricao/" addtoken="false"/>

    </cfif>

<cfelse>

    <cfinclude template="home.cfm"/>

</cfif>
