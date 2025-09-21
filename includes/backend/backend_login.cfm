<!--- DADOS DO USUARIO LOGADO --->
<cfif isDefined("COOKIE.id")>
    <cfquery name="qPerfil">
        SELECT * FROM tb_usuarios
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND (is_admin = true or is_partner = true)
    </cfquery>
    <cfif Len(trim(qPerfil.is_admin)) and qPerfil.is_admin>
        <cfquery name="qPermissoes">
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.bi_nome, 'Todas as Provas - Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_bi agr on agr.bi_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            UNION
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.agregador_nome, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agregadores agr on agr.agregador_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            UNION
            SELECT perm.*, agr.tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.nome_evento_agregado, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agrega_eventos agr on agr.tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            ORDER BY tipo, ordem
        </cfquery>
    <cfelse>
        <cfquery name="qPermissoes">
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.bi_nome, 'Todas as Provas - Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_bi agr on agr.bi_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            UNION
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.agregador_nome, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agregadores agr on agr.agregador_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            UNION
            SELECT perm.*, agr.tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.nome_evento_agregado, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agrega_eventos agr on agr.tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            ORDER BY tipo, ordem
        </cfquery>
    </cfif>
</cfif>

<!--- GOOGLE SIGN OUT --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cftry>
        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            ('googlesignout',<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#COOKIE.name#,#COOKIE.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
        </cfquery>
    <cfcatch type="any"></cfcatch>
    </cftry>
    <cfset delSession = StructDelete(COOKIE, "id", true)/>
    <cfset delSession = StructDelete(COOKIE, "name", true)/>
    <cfset delSession = StructDelete(COOKIE, "email", true)/>
    <cfset delSession = StructDelete(COOKIE, "imagem_usuario", true)/>
    <cflocation addtoken="false" url="/"/>
</cfif>

<!--- GOOGLE SIGN IN --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignin" AND isDefined("URL.credential")>

    <cfdump var="#URL.credential#">
    <br/>
    <cfset id_token = listToArray(URL.credential, ".")/>
    <cfset fb_str = replacelist(id_token[2], "-,_", "+,/")>
    <cfset padding = repeatstring("=",4-len(fb_str) mod 4)>
    <cfset user_data = deserializeJSON(toString(BinaryDecode(fb_str & padding,"base64")))>
    <cfdump var="#user_data#"/>

    <cfset token = Replace(Replace(ListGetAt(URL.credential, 2, "."), "-", "+", "ALL"), "_", "/", "ALL")>
    <cfset jstr = JavaCast("string", token)>
    <cfset decoder = CreateObject("java", "org.apache.commons.codec.binary.Base64")>
    <cfset user_data = deserializeJSON(toString(decoder.decodeBase64(jstr.getBytes())))>
    <cfdump var="#user_data#"/>

    <cfquery>
        INSERT INTO tb_usuarios
        (name, email, imagem_usuario, password,
        verification_key, is_email_verified, optin_usuario)
        VALUES
        (
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(user_data.name)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>,
        <cfif isDefined("user_data.picture")>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.picture#"/>,
        <cfelse>
           null,
        </cfif>
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        )
        ON CONFLICT (email)
        DO UPDATE SET
        data_alteracao  = now(),
        imagem_usuario  = excluded.imagem_usuario,
        verification_key = excluded.verification_key
        RETURNING *;
    </cfquery>

    <cfquery name="qPerfil">
        select * from tb_usuarios
        where email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>
    </cfquery>

    <cfcookie name="id" secure="yes" encodevalue="yes" value="#qPerfil.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="name" secure="yes" encodevalue="yes" value="#qPerfil.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="email" secure="yes" encodevalue="yes" value="#qPerfil.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="imagem_usuario" secure="yes" encodevalue="yes" value="#qPerfil.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        ('googlesignin',<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#COOKIE.name#,#COOKIE.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
    </cfquery>

    <cflocation addtoken="false" url="#URL.redirect#"/>

</cfif>
