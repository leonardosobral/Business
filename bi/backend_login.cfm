<!--- DADOS DO USUARIO LOGADO --->
<cfif isDefined("REQUEST.businessIdentity.id")>
    <cfquery name="qPerfil">
        SELECT * FROM tb_usuarios
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
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
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
            UNION
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.agregador_nome, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agregadores agr on agr.agregador_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
            UNION
            SELECT perm.*, agr.tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.nome_evento_agregado, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agrega_eventos agr on agr.tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
            ORDER BY tipo, ordem
        </cfquery>
    </cfif>
</cfif>

<!--- GOOGLE SIGN OUT --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>

<!--- Authentication handled exclusively by the verified request boundary. --->
