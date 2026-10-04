<!--- DEV SIGN IN / IMPERSONATION --->

<cfset VARIABLES.authCookieDomain = listFirst(CGI.HTTP_HOST, ":")/>

<cfif isDefined("URL.action") AND URL.action EQ "dev_auth_back">
    <cfset VARIABLES.devAuthOriginalId = 0/>

    <cfif structKeyExists(SESSION, "devAuth")
        AND isStruct(SESSION.devAuth)
        AND structKeyExists(SESSION.devAuth, "originalUsuarioId")
        AND isValid("integer", SESSION.devAuth.originalUsuarioId)>
        <cfset VARIABLES.devAuthOriginalId = val(SESSION.devAuth.originalUsuarioId)/>
    </cfif>

    <cfif VARIABLES.devAuthOriginalId LTE 0>
        <cfset StructDelete(SESSION, "devAuth", false)/>
        <cflocation addtoken="false" url="#APPLICATION.baseCanonica#"/>
    </cfif>

    <cfquery name="qDevAuthBackPerfil" result="qDevAuthBackPerfilMeta">
        select usr.id, usr.name, usr.email, usr.imagem_usuario,
        usr.is_admin, usr.is_dev,
        pag.tag
        from tb_usuarios usr
        inner join tb_paginas_usuarios pagusr on usr.id = pagusr.id_usuario
        inner join tb_paginas pag on pag.id_pagina = pagusr.id_pagina
        where usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.devAuthOriginalId#"/>
    </cfquery>
    <cfset logQueryDebug("qDevAuthBackPerfil", qDevAuthBackPerfilMeta, "backend/dev_auth_back_perfil", "sem cache", qDevAuthBackPerfil)/>

    <cfif NOT qDevAuthBackPerfil.recordcount
        OR NOT (qDevAuthBackPerfil.is_admin OR qDevAuthBackPerfil.is_dev)>
        <cfset StructDelete(SESSION, "devAuth", false)/>
        <cflocation addtoken="false" url="#APPLICATION.baseCanonica#"/>
    </cfif>

    <cfcookie domain="#VARIABLES.authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="#qDevAuthBackPerfil.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#qDevAuthBackPerfil.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="#qDevAuthBackPerfil.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="#qDevAuthBackPerfil.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#qDevAuthBackPerfil.tag#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfset SESSION.devAuth = {
        originalUsuarioId = qDevAuthBackPerfil.id,
        originalEmail = qDevAuthBackPerfil.email,
        isImpersonating = false
    }/>
    <cfif structKeyExists(SESSION, "UsuarioCache")>
        <cfset StructClear(SESSION.UsuarioCache)/>
    </cfif>

    <cflocation addtoken="false" url="/perfil/"/>
</cfif>

<cfif isDefined("URL.action") AND URL.action EQ "dev_auth" AND isDefined("URL.dev_auth")>
    <cfset VARIABLES.devAuthOriginalId = 0/>

    <cfif structKeyExists(SESSION, "devAuth")
        AND isStruct(SESSION.devAuth)
        AND structKeyExists(SESSION.devAuth, "originalUsuarioId")
        AND isValid("integer", SESSION.devAuth.originalUsuarioId)>
        <cfset VARIABLES.devAuthOriginalId = val(SESSION.devAuth.originalUsuarioId)/>
    <cfelseif structKeyExists(REQUEST, "Usuario")
        AND isObject(REQUEST.Usuario)
        AND REQUEST.Usuario.logado
        AND REQUEST.Usuario.id GT 0>
        <cfset VARIABLES.devAuthOriginalId = REQUEST.Usuario.id/>
    </cfif>

    <cfif VARIABLES.devAuthOriginalId LTE 0>
        <cflocation addtoken="false" url="#APPLICATION.baseCanonica#"/>
    </cfif>

    <cfquery name="qDevAuthOriginalUsuario" result="qDevAuthOriginalUsuarioMeta">
        select id, email, is_admin, is_dev
        from tb_usuarios
        where id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.devAuthOriginalId#"/>
    </cfquery>
    <cfset logQueryDebug("qDevAuthOriginalUsuario", qDevAuthOriginalUsuarioMeta, "backend/dev_auth_original_usuario", "sem cache", qDevAuthOriginalUsuario)/>

    <cfif NOT qDevAuthOriginalUsuario.recordcount
        OR NOT (qDevAuthOriginalUsuario.is_admin OR qDevAuthOriginalUsuario.is_dev)>
        <cfset StructDelete(SESSION, "devAuth", false)/>
        <cflocation addtoken="false" url="#APPLICATION.baseCanonica#"/>
    </cfif>

    <cfquery name="qDevAuthPerfil" result="qDevAuthPerfilMeta">
        select usr.id, usr.name, usr.email, usr.imagem_usuario, usr.name,
        usr.is_admin, usr.is_dev,
        pag.tag
        from tb_usuarios usr
        inner join tb_paginas_usuarios pagusr on usr.id = pagusr.id_usuario
        inner join tb_paginas pag on pag.id_pagina = pagusr.id_pagina
        where email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.dev_auth#"/>
    </cfquery>
    <cfset logQueryDebug("qDevAuthPerfil", qDevAuthPerfilMeta, "backend/dev_auth_perfil", "sem cache", qDevAuthPerfil)/>

    <cfcookie domain="#VARIABLES.authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="#qDevAuthPerfil.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#qDevAuthPerfil.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="#qDevAuthPerfil.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="#qDevAuthPerfil.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#qDevAuthPerfil.tag#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfset SESSION.devAuth = {
        originalUsuarioId = qDevAuthOriginalUsuario.id,
        originalEmail = qDevAuthOriginalUsuario.email,
        isImpersonating = (qDevAuthOriginalUsuario.id NEQ qDevAuthPerfil.id),
        impersonatedUsuarioId = qDevAuthPerfil.id,
        impersonatedEmail = qDevAuthPerfil.email
    }/>
    <cfif structKeyExists(SESSION, "UsuarioCache")>
        <cfset StructClear(SESSION.UsuarioCache)/>
    </cfif>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="original_id" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfset StructDelete(COOKIE, "original_id", true)/>

    <cflocation addtoken="false" url="/perfil/"/>

</cfif>


<!--- QUERIES DO USUARIO LOGADO --->

<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario)>
    <cfset Usuario = REQUEST.Usuario>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario")>
    <cfset REQUEST.Usuario = Usuario>
</cfif>

<cfif NOT structKeyExists(REQUEST, "invalidateUsuarioCacheBlocksHelperLoaded")>
    <cfscript>
        function invalidateUsuarioCacheBlocks(required string blocks) {
            var blockName = "";
            if (!structKeyExists(SESSION, "UsuarioCache") || !isStruct(SESSION.UsuarioCache)) {
                return;
            }

            for (blockName in listToArray(arguments.blocks)) {
                blockName = trim(blockName);
                if (len(blockName) && structKeyExists(SESSION.UsuarioCache, blockName)) {
                    structDelete(SESSION.UsuarioCache, blockName);
                }
            }
        }
    </cfscript>
    <cfset REQUEST.invalidateUsuarioCacheBlocksHelperLoaded = true/>
</cfif>

<cfif Usuario.logado>

    <cfset VARIABLES.cacheNow = now()/>

    <!--- FAILOVER DE COOKIE DE AUTENTICACAO --->

    <cfcookie domain="#VARIABLES.authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="#Usuario.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#Usuario.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="#Usuario.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="#Usuario.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#Usuario.tag#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>

    <!--- ACHOU PERFIL --->

    <cfif Usuario.id GT 0 AND Usuario.id_pagina GT 0>

        <cfset Usuario.logado = true/>
        <cfset REQUEST.Usuario = Usuario />
        <cfset VARIABLES.usuarioCompatData = Usuario.toStruct()/>
        <cfset VARIABLES.qMeuPerfilColumns = "id,id_pagina,name,nome,tag,email,imagem_usuario,is_admin,is_dev,is_partner,verificado,perfil_publico,cidade,estado,uf,pais,aka,assessoria,ano_nascimento,data_nascimento,genero,cbat,strava_id,fonte_lead,instagram,instagram_publico,youtube,youtube_publico,tiktok,tiktok_publico,website,website_publico,loja,loja_publico,whatsapp,whatsapp_publico,descricao,inscricao_365,inscricao_366,pedido_366,manychat_subscriber_id,tag_usuario,url_usuario,cep,endereco,ddd_usuario,ddi_usuario,telefone_usuario"/>
        <cfset qMeuPerfil = queryNew(VARIABLES.qMeuPerfilColumns)/>
        <cfset queryAddRow(qMeuPerfil, 1)/>
        <cfloop list="#VARIABLES.qMeuPerfilColumns#" index="VARIABLES.qMeuPerfilColumn">
            <cfif structKeyExists(VARIABLES.usuarioCompatData, VARIABLES.qMeuPerfilColumn)>
                <cfset querySetCell(qMeuPerfil, VARIABLES.qMeuPerfilColumn, VARIABLES.usuarioCompatData[VARIABLES.qMeuPerfilColumn], 1)/>
            </cfif>
        </cfloop>
        <cfset REQUEST.qMeuPerfil = qMeuPerfil />

        <!--- VINCULOS (SEGUIDORES E SEGUINDO) --->

        <cfif NOT structKeyExists(REQUEST, "userManagementPageStatusSchemaReady")>
            <cfset REQUEST.userManagementPageStatusSchemaReady = false/>
            <cfif structKeyExists(APPLICATION, "userManagementStatusSchemaReady") AND APPLICATION.userManagementStatusSchemaReady>
                <cfset REQUEST.userManagementPageStatusSchemaReady = true/>
            <cfelse>
                <cftry>
                    <cfquery name="qUserLinksManagementSchema" datasource="runner_dba">
                        SELECT
                            to_regclass('public.tb_usuarios_gestao') IS NOT NULL
                            AND to_regclass('public.tb_paginas_gestao') IS NOT NULL AS ready
                    </cfquery>
                    <cfset REQUEST.userManagementPageStatusSchemaReady = isBoolean(qUserLinksManagementSchema.ready)
                        ? qUserLinksManagementSchema.ready
                        : listFindNoCase("1,true,yes,on", trim(qUserLinksManagementSchema.ready & "")) GT 0/>
                    <cfif REQUEST.userManagementPageStatusSchemaReady>
                        <cfset APPLICATION.userManagementStatusSchemaReady = true/>
                    </cfif>
                    <cfcatch type="any">
                        <cfset REQUEST.userManagementPageStatusSchemaReady = false/>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfif>

        <cfset VARIABLES.cacheVinculosVersion = 2/>

        <cfset VARIABLES.cacheVinculosValid =
            NOT REQUEST.userManagementPageStatusSchemaReady
            AND
            structKeyExists(SESSION.UsuarioCache, "vinculos")
            AND isStruct(SESSION.UsuarioCache.vinculos)
            AND structKeyExists(SESSION.UsuarioCache.vinculos, "id")
            AND SESSION.UsuarioCache.vinculos.id EQ Usuario.id
            AND structKeyExists(SESSION.UsuarioCache.vinculos, "version")
            AND SESSION.UsuarioCache.vinculos.version EQ VARIABLES.cacheVinculosVersion
            AND structKeyExists(SESSION.UsuarioCache.vinculos, "data")
            AND isStruct(SESSION.UsuarioCache.vinculos.data)
            AND structKeyExists(SESSION.UsuarioCache.vinculos, "expiresAt")
            AND isDate(SESSION.UsuarioCache.vinculos.expiresAt)
            AND SESSION.UsuarioCache.vinculos.expiresAt GT VARIABLES.cacheNow
        />

        <cfif VARIABLES.cacheVinculosValid>
            <cfset qPerfilSeguindo = duplicate(SESSION.UsuarioCache.vinculos.data.seguindo)/>
            <cfset qPerfilAguardandoSeguindo = duplicate(SESSION.UsuarioCache.vinculos.data.seguindo_aguardando)/>
            <cfset qPerfilSeguidores = duplicate(SESSION.UsuarioCache.vinculos.data.seguidores)/>
            <cfset qPerfilAguardandoSeguidores = duplicate(SESSION.UsuarioCache.vinculos.data.seguidores_aguardando)/>
        <cfelse>
            <cfquery name="qPerfilVinculos" result="qPerfilVinculosMeta">
                select vin.id_pagina_destino, vin.id_pagina_origem, vin.vinculo_validado
                from tb_paginas_vinculos vin
                inner join public.tb_paginas origin_pag on origin_pag.id_pagina = vin.id_pagina_origem
                <cfif REQUEST.userManagementPageStatusSchemaReady>
                    inner join public.tb_paginas connected_pag on connected_pag.id_pagina = case
                        when vin.id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/> then vin.id_pagina_destino
                        else vin.id_pagina_origem
                    end
                    inner join public.tb_usuarios connected_usr on connected_usr.id = connected_pag.id_usuario_cadastro
                    left join public.tb_paginas_gestao connected_paggest on connected_paggest.id_pagina = connected_pag.id_pagina
                    left join public.tb_usuarios_gestao connected_usrgest on connected_usrgest.id_usuario = connected_usr.id
                </cfif>
                where origin_pag.tag_prefix = 'atleta'
                and vin.tipo_vinculo = 1
                and (
                    id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                    OR
                    id_pagina_destino = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                    )
                <cfif REQUEST.userManagementPageStatusSchemaReady>
                    and coalesce(connected_paggest.ativo, true) = true
                    and coalesce(connected_paggest.excluido, false) = false
                    and coalesce(connected_usrgest.ativo, true) = true
                    and coalesce(connected_usrgest.excluido, false) = false
                </cfif>
            </cfquery>
            <cfset logQueryDebug("qPerfilVinculos", qPerfilVinculosMeta, "backend/qmeuperfil_vinculos", "sem cache", qPerfilVinculos)/>

            <cfquery name="qPerfilSeguindo" dbtype="query" result="qPerfilSeguindoMeta">
                select id_pagina_destino as id_pagina
                from qPerfilVinculos
                where id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                and vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
            </cfquery>
            <cfset logQueryDebug("qPerfilSeguindo", qPerfilSeguindoMeta, "backend/qmeuperfil_seguindo", "dbtype=query", qPerfilSeguindo)/>

            <cfquery name="qPerfilAguardandoSeguindo" dbtype="query" result="qPerfilAguardandoSeguindoMeta">
                select id_pagina_destino as id_pagina
                from qPerfilVinculos
                where id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                and vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
            </cfquery>
            <cfset logQueryDebug("qPerfilAguardandoSeguindo", qPerfilAguardandoSeguindoMeta, "backend/qmeuperfil_aguardando_seguindo", "dbtype=query", qPerfilAguardandoSeguindo)/>

            <cfquery name="qPerfilSeguidores" dbtype="query" result="qPerfilSeguidoresMeta">
                select id_pagina_origem as id_pagina
                from qPerfilVinculos
                where id_pagina_destino = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                and vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
            </cfquery>
            <cfset logQueryDebug("qPerfilSeguidores", qPerfilSeguidoresMeta, "backend/qmeuperfil_seguidores", "dbtype=query", qPerfilSeguidores)/>

            <cfquery name="qPerfilAguardandoSeguidores" dbtype="query" result="qPerfilAguardandoSeguidoresMeta">
                select id_pagina_origem as id_pagina
                from qPerfilVinculos
                where id_pagina_destino = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                and vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
            </cfquery>
            <cfset logQueryDebug("qPerfilAguardandoSeguidores", qPerfilAguardandoSeguidoresMeta, "backend/qmeuperfil_aguardando_seguidores", "dbtype=query", qPerfilAguardandoSeguidores)/>

            <cfset SESSION.UsuarioCache.vinculos = {
                id = Usuario.id,
                version = VARIABLES.cacheVinculosVersion,
                data = {
                    seguindo = duplicate(qPerfilSeguindo),
                    seguindo_aguardando = duplicate(qPerfilAguardandoSeguindo),
                    seguidores = duplicate(qPerfilSeguidores),
                    seguidores_aguardando = duplicate(qPerfilAguardandoSeguidores)
                },
                loadedAt = VARIABLES.cacheNow,
                expiresAt = dateAdd("n", 10, VARIABLES.cacheNow)
            }/>
        </cfif>

        <cfset Usuario.seguindo = qPerfilSeguindo>
        <cfset Usuario.seguindo_aguardando = qPerfilAguardandoSeguindo>
        <cfset Usuario.seguidores = qPerfilSeguidores>
        <cfset Usuario.seguidores_aguardando = qPerfilAguardandoSeguidores>


        <!--- AGENDA DO ATLETA --->

        <!--- Invalida agendas de sessão criadas antes da sincronização das inscrições do Treinão MIF. --->
        <cfset VARIABLES.cacheAgendaVersion = 2/>
        <cfset VARIABLES.cacheAgendaValid =
            structKeyExists(SESSION.UsuarioCache, "agenda")
            AND isStruct(SESSION.UsuarioCache.agenda)
            AND structKeyExists(SESSION.UsuarioCache.agenda, "id")
            AND SESSION.UsuarioCache.agenda.id EQ Usuario.id
            AND structKeyExists(SESSION.UsuarioCache.agenda, "version")
            AND SESSION.UsuarioCache.agenda.version EQ VARIABLES.cacheAgendaVersion
            AND structKeyExists(SESSION.UsuarioCache.agenda, "data")
            AND isQuery(SESSION.UsuarioCache.agenda.data)
            AND structKeyExists(SESSION.UsuarioCache.agenda, "expiresAt")
            AND isDate(SESSION.UsuarioCache.agenda.expiresAt)
            AND SESSION.UsuarioCache.agenda.expiresAt GT VARIABLES.cacheNow
        />

        <cfif VARIABLES.cacheAgendaValid>
            <cfset qPerfilEventosCheckin = duplicate(SESSION.UsuarioCache.agenda.data)/>
        <cfelse>
        <cfquery name="qPerfilEventosCheckin" result="qPerfilEventosCheckinMeta">
            SELECT
            evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
            evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
            evt.url_inscricao, evt.url_resultado,
            '' as id_foco_radical, evt.status_evento,
            DATE_PART('week', evt.data_inicial) AS week,
            DATE_PART('month', evt.data_inicial) AS month,
            DATE_PART('year', evt.data_inicial) AS year,
            translate(lower( cidade ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') as tag_cidade,
            (select json_agg(row_to_json(linha))
                from
                    (select
                        distinct
                        bd.badge,
                        bd.valor_badge,
                        bd.percurso,
                        tip.badge_tooltip,
                        tip.ordem
                    from tb_badges bd
                    inner join tb_badges_tipos tip on tip.badge = bd.badge
                    where bd.id_evento = evt.id_evento
                    and tip.ativo = true
                    order by tip.ordem
                     ) as linha
            ) as badges,
            (SELECT sum(res.concluintes)
                FROM tb_resultados_resumo res
                WHERE res.id_evento = evt.id_evento) as concluintes,
            (SELECT
                json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
                from
                tb_evento_corridas_percursos pcr
                where pcr.id_evento = evt.id_evento
            ) as lista_percursos,
            (SELECT
                max(percurso_evento)
                from
                tb_evento_corridas_percursos pcr
                where pcr.id_evento = evt.id_evento
            ) as max_percurso,
            (SELECT condicoes FROM vw_evento_corridas_cupom
                WHERE ((id_evento_agrega = evt.id_evento
                AND tipo_evento = 1)
                OR (id_evento_agrega = evt.id_agrega_evento
                AND tipo_evento = 2))
                AND current_date between data_validade_inicio and data_validade_fim
            ) as cupom,
            (SELECT chk.tipo_checkin FROM tb_evento_corridas_checkin chk WHERE chk.id_evento = evt.id_evento
                AND chk.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                ORDER BY chk.tipo_checkin DESC
                LIMIT 1)
            as tipo_checkin
            FROM vw_evento_corridas evt
            WHERE evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
            AND id_evento IN (SELECT chk.id_evento FROM tb_evento_corridas_checkin chk
                            WHERE chk.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                            AND chk.tipo_checkin IS NOT NULL
                            AND chk.id_fornecedor is null)
            ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema desc, evt.id_agrega_evento desc, max_percurso desc NULLS LAST, id_foco_radical NULLS LAST, evt.tipo_corrida
        </cfquery>
        <cfset logQueryDebug("qPerfilEventosCheckin", qPerfilEventosCheckinMeta, "backend/qmeuperfil_agenda", "sem cache", qPerfilEventosCheckin)/>

        <cfset SESSION.UsuarioCache.agenda = {
            id = Usuario.id,
            version = VARIABLES.cacheAgendaVersion,
            data = duplicate(qPerfilEventosCheckin),
            loadedAt = VARIABLES.cacheNow,
            expiresAt = dateAdd("n", 10, VARIABLES.cacheNow)
        }/>
        </cfif>

        <cfset Usuario.agenda = qPerfilEventosCheckin>


        <!--- RESULTADOS DO ATLETA --->

        <cfset VARIABLES.resultsCacheVersion = 3/>
        <cfset VARIABLES.cacheResultadosValid =
            structKeyExists(SESSION.UsuarioCache, "resultados")
            AND isStruct(SESSION.UsuarioCache.resultados)
            AND structKeyExists(SESSION.UsuarioCache.resultados, "id")
            AND SESSION.UsuarioCache.resultados.id EQ Usuario.id
            AND structKeyExists(SESSION.UsuarioCache.resultados, "version")
            AND SESSION.UsuarioCache.resultados.version EQ VARIABLES.resultsCacheVersion
            AND structKeyExists(SESSION.UsuarioCache.resultados, "data")
            AND isQuery(SESSION.UsuarioCache.resultados.data)
            AND structKeyExists(SESSION.UsuarioCache.resultados, "expiresAt")
            AND isDate(SESSION.UsuarioCache.resultados.expiresAt)
            AND SESSION.UsuarioCache.resultados.expiresAt GT VARIABLES.cacheNow
        />

        <cfif VARIABLES.cacheResultadosValid>
            <cfset qPerfilCorridasAtleta = duplicate(SESSION.UsuarioCache.resultados.data)/>
        <cfelse>
        <cfquery name="qPerfilCorridasAtleta" result="qPerfilCorridasAtletaMeta">
            SELECT id_resultado, id_usuario, num_peito, UPPER(nome) as nome, nome_categoria, res.id_evento, evt.nome_evento, evt.tag, modalidade, pace, percurso, equipe,
            sexo, tempo_bruto, tempo_total, classificacao_categoria, classificacao_sexo, res.origem_resultado, evt.data_inicial, evt.data_final,
            coalesce(percurso_info.data_percurso, evt.data_final) as data_resultado,
            evt.tipo_corrida, posicao_ranking,
            '' as id_foco_radical, evt.status_evento,
            evt.cidade, evt.estado, evt.pais,
            DATE_PART('week', coalesce(percurso_info.data_percurso, evt.data_final)) AS week,
            DATE_PART('month', coalesce(percurso_info.data_percurso, evt.data_final)) AS month,
            DATE_PART('year', coalesce(percurso_info.data_percurso, evt.data_final)) AS year,
            translate(lower( cidade ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') as tag_cidade,
                (select json_agg(row_to_json(linha))
                    from
                        (select
                            distinct
                            bd.badge,
                            bd.valor_badge,
                            bd.complemento_badge,
                            bd.percurso,
                            tip.badge_tooltip,
                            tip.ordem
                        from tb_badges bd
                        inner join tb_badges_tipos tip on tip.badge = bd.badge
                        where bd.id_evento = evt.id_evento
                        and tip.ativo = true
                        order by tip.ordem
                         ) as linha
                ) as badges,
                (SELECT sum(res.concluintes)
                    FROM tb_resultados_resumo res
                    WHERE res.id_evento = evt.id_evento) as concluintes,
                (SELECT
                    json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
                    from
                    tb_evento_corridas_percursos pcr
                    where pcr.id_evento = evt.id_evento
                ) as lista_percursos,
                (SELECT
                    max(percurso_evento)
                    from
                    tb_evento_corridas_percursos pcr
                    where pcr.id_evento = evt.id_evento
                ) as max_percurso,
                (SELECT condicoes FROM vw_evento_corridas_cupom
                    WHERE ((id_evento_agrega = evt.id_evento
                    AND tipo_evento = 1)
                    OR (id_evento_agrega = evt.id_agrega_evento
                    AND tipo_evento = 2))
                    AND current_date between data_validade_inicio and data_validade_fim
                ) as cupom,
                (SELECT
                    json_agg(json_build_object('percurso',percurso,'modalidade',modalidade,'concluintes',concluintes) order by percurso)
                    from
                    tb_resultados_resumo pcr
                    where pcr.id_evento = evt.id_evento
                ) as lista_percursos_resultado,
                (SELECT percurso_evento from tb_evento_corridas_percursos pcr
                    where pcr.id_evento = evt.id_evento AND percurso_evento = 42
                    limit 1
                ) as is_maratona,
                (SELECT chk.tipo_checkin FROM tb_evento_corridas_checkin chk WHERE chk.id_evento = evt.id_evento
                    AND chk.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                    ORDER BY chk.tipo_checkin DESC
                    LIMIT 1)
                as tipo_checkin
            FROM tb_resultados res
            INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
            LEFT JOIN LATERAL (
                SELECT pcr.data_percurso
                FROM tb_evento_corridas_percursos pcr
                WHERE pcr.id_evento = res.id_evento
                AND (
                    pcr.percurso_evento = res.percurso
                    OR floor(pcr.percurso_evento) = floor(res.percurso)
                )
                ORDER BY CASE WHEN pcr.percurso_evento = res.percurso THEN 0 ELSE 1 END, pcr.percurso_evento DESC
                LIMIT 1
            ) percurso_info ON true
            WHERE res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            AND res.status_final < 3
            ORDER BY coalesce(percurso_info.data_percurso, evt.data_final) DESC, evt.data_final DESC
        </cfquery>
        <cfset logQueryDebug("qPerfilCorridasAtleta", qPerfilCorridasAtletaMeta, "backend/qmeuperfil_resultados", "sem cache", qPerfilCorridasAtleta)/>

        <cfset SESSION.UsuarioCache.resultados = {
            id = Usuario.id,
            version = VARIABLES.resultsCacheVersion,
            data = duplicate(qPerfilCorridasAtleta),
            loadedAt = VARIABLES.cacheNow,
            expiresAt = dateAdd("n", 15, VARIABLES.cacheNow)
        }/>
        </cfif>

        <cfset Usuario.resultados = qPerfilCorridasAtleta>


        <!--- VERIFICA INSCRICAO NO DESAFIO 365 --->  

        <cfset VARIABLES.cacheDesafiosValid =
            structKeyExists(SESSION.UsuarioCache, "desafios")
            AND isStruct(SESSION.UsuarioCache.desafios)
            AND structKeyExists(SESSION.UsuarioCache.desafios, "id")
            AND SESSION.UsuarioCache.desafios.id EQ Usuario.id
            AND structKeyExists(SESSION.UsuarioCache.desafios, "data")
            AND isStruct(SESSION.UsuarioCache.desafios.data)
            AND structKeyExists(SESSION.UsuarioCache.desafios, "expiresAt")
            AND isDate(SESSION.UsuarioCache.desafios.expiresAt)
            AND SESSION.UsuarioCache.desafios.expiresAt GT VARIABLES.cacheNow
        />

        <cfif VARIABLES.cacheDesafiosValid>
            <cfset qCheck365Inscrito = duplicate(SESSION.UsuarioCache.desafios.data.inscricoes)/>
            <cfset qCheckDesafios = duplicate(SESSION.UsuarioCache.desafios.data.desafios)/>
            <cfset qCheckProdutos = duplicate(SESSION.UsuarioCache.desafios.data.produtos)/>
        <cfelse>
            <cfquery name="qCheck365Inscrito" result="qCheck365InscritoMeta">
                SELECT * FROM desafios
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                AND status = 'C'
            </cfquery>
            <cfset logQueryDebug("qCheck365Inscrito", qCheck365InscritoMeta, "backend/qmeuperfil_check_365_inscrito", "sem cache", qCheck365Inscrito)/>

            <cfquery name="qCheckDesafios" result="qCheckDesafiosMeta">
                SELECT DISTINCT desafio FROM desafios
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            </cfquery>
            <cfset logQueryDebug("qCheckDesafios", qCheckDesafiosMeta, "backend/qmeuperfil_check_desafios", "sem cache", qCheckDesafios)/>

            <cfquery name="qCheckProdutos" result="qCheckProdutosMeta">
                SELECT DISTINCT produto FROM desafios
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            </cfquery>
            <cfset logQueryDebug("qCheckProdutos", qCheckProdutosMeta, "backend/qmeuperfil_check_produtos", "sem cache", qCheckProdutos)/>

            <cfset SESSION.UsuarioCache.desafios = {
                id = Usuario.id,
                data = {
                    inscricoes = duplicate(qCheck365Inscrito),
                    desafios = duplicate(qCheckDesafios),
                    produtos = duplicate(qCheckProdutos)
                },
                loadedAt = VARIABLES.cacheNow,
                expiresAt = dateAdd("n", 10, VARIABLES.cacheNow)
            }/>
        </cfif>

        <cfset Usuario.desafio365 = yesNoFormat(qCheck365Inscrito.recordcount)>
        <cfset Usuario.desafios = ValueList(qCheckDesafios.desafio)>
        <cfset Usuario.produtos = ValueList(qCheckProdutos.produto)>




        <!--- NOTIFICACOES --->

        <cfinclude template="backend_notifications.cfm"/>

        <cfif isDefined("URL.notificacao")>
            <cfif isDefined("URL.id_notifica") AND isNumeric(URL.id_notifica)>
                <cfset rrNotificationsMarkRead(Usuario.id, int(URL.id_notifica), false)/>
            <cfelse>
                <cfset rrNotificationsMarkRead(Usuario.id, 0, true)/>
            </cfif>
        </cfif>

        <cfif structKeyExists(SESSION.UsuarioCache, "notificacoes")>
            <cfset structDelete(SESSION.UsuarioCache, "notificacoes", false)/>
        </cfif>
        <cfset qNotificacoes = rrNotificationsGetInbox(Usuario.id, 12)/>
        <cfset qNotificacoesNaoLidas = rrNotificationsGetUnreadCount(Usuario.id)/>

        <cfset Usuario.notificacoes = qNotificacoes>

        <!--- MENSAGENS: falha fechada para não afetar o restante do portal antes da migration. --->
        <cfset qChatHeader = queryNew("id_chat_conversa,other_name,imagem_usuario,tag,is_request,verificado,is_admin,tipo,conteudo,ultima_interacao_em,nao_lida")/>
        <cfset qChatNaoLidas = queryNew("total_nao_lidas", "integer", [[0]])/>
        <cftry>
            <cfinclude template="backend_chat.cfm"/>
            <cfset qChatHeader = rrChatList(Usuario.id, 8)/>
            <cfset REQUEST.normalizeDisplayQuery(qChatHeader, "other_name")/>
            <cfset qChatNaoLidas = rrChatUnreadCount(Usuario.id)/>
            <cfcatch></cfcatch>
        </cftry>


    <!--- NAO ACHOU PERFIL, LOG E ENVIO DO ERRO --->

    <cfelse>

        <cfquery name="qLogResultadoTeste" result="qLogResultadoTesteMeta">
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (<cfqueryparam cfsqltype="cf_sql_varchar" value="ERRO DE NAO ACHAR PERFIL"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="id_usuario: #Usuario.id#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
        </cfquery>
        <cfset logQueryDebug("qLogResultadoTeste", qLogResultadoTesteMeta, "backend/log_resultado_teste", "sem cache", qLogResultadoTeste)/>
        <cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                subject="ERRO DE NAO ACHAR PERFIL" usetls="true"
                server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                charset="utf-8" type="html" port="587">
            <p>id_usuario: #Usuario.id#</p>
        </cfmail>
        <cflocation addtoken="false" url="/?action=googlesignout"/>

    </cfif>

</cfif>


<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosBase" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qEventosResult">
    SELECT * FROM vw_evento_corridas evt
    WHERE data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
    <cfif isDefined("URL.distancia") and Len(trim(URL.distancia)) and URL.distancia NEQ "1,42">
        AND exists
        (
            select prc.id_evento from tb_evento_corridas_percursos prc
            where prc.id_evento = evt.id_evento
            and percurso_evento between <cfqueryparam cfsqltype="cf_sql_integer" value="#ListFirst(URL.distancia)#"/>
            and <cfqueryparam cfsqltype="cf_sql_integer" value="#ListLast(URL.distancia)#"/>
        )
    </cfif>
    <cfif len(trim(URL.badges))>
        AND evt.id_evento IN ( select id_evento FROM tb_badges WHERE badge IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="yes" value="#URL.badges#"/>))
    </cfif>
    <cfif VARIABLES.template EQ "/estado/">
        ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema desc, evt.id_agrega_evento NULLS LAST, cupom NULLS LAST, is_maratona NULLS LAST, max_percurso desc NULLS LAST, id_foco_radical NULLS LAST, evt.tipo_corrida
    <cfelse>
        ORDER BY year, month, week, evt.destaque NULLS LAST, evt.id_tema desc, evt.id_agrega_evento NULLS LAST, cupom NULLS LAST, is_maratona NULLS LAST, max_percurso desc NULLS LAST, id_foco_radical NULLS LAST, evt.tipo_corrida
    </cfif>
</cfquery>
<cfset logQueryDebug("qEventosBase", qEventosResult, "backend_eventos/base", "5min", qEventosBase)/>


<!--- FILTROS DA QUERY BASE DE EVENTOS --->

<cfquery name="qEventos" dbtype="query" result="qEventosMeta">
    SELECT * FROM qEventosBase
    WHERE 1 = 1
    <cfif Len(trim(URL.tempo))>
        AND
        (
            data_final between <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            and <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+ListLast(URL.tempo)*30, 'yyyy-mm-dd')#"/>
        )
    </cfif>
    <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
        <cfif VARIABLES.template EQ "/estado/">
            AND tag_cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        <cfelse>
            AND cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif URL.cupom>
        AND cupom is not null
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    <cfif isDefined("URL.context_uf") AND len(trim(URL.context_uf)) AND URL.context_uf NEQ "BR" AND VARIABLES.template EQ "/">
        AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.context_uf)#"/>
    <cfelseif VARIABLES.template EQ "/estado/">
        AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
    <cfelseif Len(trim(VARIABLES.uf))>
        AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uf#"/>
    </cfif>
</cfquery>
<cfset logQueryDebug("qEventos", qEventosMeta, "backend_eventos/filtros", "dbtype=query", qEventos)/>


<!--- LISTA DE BADGES --->

<cfquery name="qBadges" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#" result="qBadgesResult">
    SELECT * from tb_badges_tipos
    where ativo = true AND site ilike '%RR%'
    order by ordem
</cfquery>
<cfset logQueryDebug("qBadges", qBadgesResult, "backend_eventos/badges", "1min", qBadges)/>


<!--- LISTA DE DESAFIOS --->

<cfquery name="qDesafios" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#" result="qDesafiosResult">
    SELECT * from desafios_eventos
    where now() between data_inicio and data_fim
    order by data_inicio desc
</cfquery>
<cfset logQueryDebug("qDesafios", qDesafiosResult, "backend_eventos/desafios", "1min", qDesafios)/>
