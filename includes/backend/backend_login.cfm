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

<!--- ATUALIZAR CADASTRO POCKET --->

<cfif isDefined("FORM.action") AND FORM.action EQ "atualizar_cadastro_pocket">
    <cfquery name="qCheckTagPagina">
        SELECT tag FROM tb_paginas
        WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(FORM.tag))#"/>
        AND id_pagina <> <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_pagina#"/>
    </cfquery>
    <cfquery datasource="runner_dba" name="qUpdatePagina">
        UPDATE tb_paginas
        SET
        nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome#"/>,
        tag_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tag_prefix#"/>,
        <cfif NOT qCheckTagPagina.recordcount>
            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(FORM.tag))#"/>,
        </cfif>
        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.cidade#"/>,
        uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.uf#"/>,
        <!---pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.pais#"/>,--->
        descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.descricao#"/>,
        id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_pagina#"/>
    </cfquery>
    <cfquery datasource="runner_dba" name="qUpdateUsuario">
        UPDATE tb_usuarios
        SET
        name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome#"/>,
        <cfif isDefined("FORM.assessoria")>
            assessoria = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.assessoria#"/>,
        </cfif>
        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.cidade#"/>,
        estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.uf#"/>,
        pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.pais#"/>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>
    <cfif qCheckTagPagina.recordcount>
        <cflocation addtoken="false" url="#FORM.template#inscricao/?info=tag&tag=#FORM.tag#"/>
    </cfif>
</cfif>

<!--- CONFIRMAR INSCRICAO BUSINESS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "confirmar_business">
    <cfset VARIABLES.postback = {}/>
    <cfif isDefined("FORM.documento")>
        <cfset VARIABLES.postback["documento"] = FORM.documento/>
    </cfif>
    <cfif isDefined("FORM.celular")>
        <cfset VARIABLES.postback["celular"] = FORM.celular/>
    </cfif>
    <cfif isDefined("FORM.nascimento")>
        <cfset VARIABLES.postback["nome_comercial"] = FORM.nome_comercial/>
    </cfif>
    <cfif isDefined("FORM.assessoria")>
        <cfset VARIABLES.postback["perfil"] = FORM.perfil/>
    </cfif>
    <cfquery datasource="runner_dba" name="qInsertIncricaoTreino">
        UPDATE tb_usuarios
        set partner_info = <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.postback)#"/>::jsonb
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>
    <cfmail from="Road Runners <contato@roadrunners.run>" to="#FORM.email#" bcc="contato@roadrunners.run"
            subject="[ROADRUNNERS] Cadastro concluído no RoadRunners Business" usetls="true"
            server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
            charset="utf-8" type="html" port="587">
        <!---cfinclude template="../../mif/treinao/email_template.cfm"/--->
    </cfmail>
</cfif>

