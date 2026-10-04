<cfscript>
VARIABLES.eventDescriptionLocaleService = new services.EventDescriptionLocaleService();
VARIABLES.eventDescriptionSchemaReady = false;
if (structKeyExists(REQUEST, "lang") AND listFind("en,es", lCase(REQUEST.lang))) {
    VARIABLES.eventDescriptionSchemaReady = VARIABLES.eventDescriptionLocaleService.isSchemaReady();
}
VARIABLES.eventDescriptionSelection = VARIABLES.eventDescriptionLocaleService.selectionFor(
    structKeyExists(REQUEST, "lang") ? REQUEST.lang : "pt-BR", VARIABLES.eventDescriptionSchemaReady
);
</cfscript>
<cfquery name="qEvento" result="qEventoMeta">
    SELECT
        evt.id_evento,
        evt.nome_evento,
        evt.cidade,
        evt.estado,
        evt.tag,
        evt.homologado,
        evt.url_resultado,
        evt.url_wiclax,
        evt.cod_cidade,
        evt.id_agrega_evento,
        evt.pais,
        evt.data_inicial,
        evt.data_final,
        #preserveSingleQuotes(VARIABLES.eventDescriptionSelection.descriptionSql)# AS descricao,
        #preserveSingleQuotes(VARIABLES.eventDescriptionSelection.languageSql)# AS descricao_idioma,
        evt.endereco,
        evt.coordenadas,
        evt.imagem,
        evt.destaque,
        evt.categorias,
        evt.url_inscricao,
        to_jsonb(evt)->>'inscricao_disponibilidade' AS inscricao_disponibilidade,
        evt.info_duplicado,
        evt.nome_simplificado,
        evt.organizador,
        evt.obs,
        evt.tipo_corrida,
        evt.ranking,
        evt.id_tema,
        evt.data_processamento,
        evt.resumo,
        evt.tag_301,
        evt.ativo,
        evt.data_inclusao,
        evt.nome_evento_full_text,
        evt.obs_resultado,
        evt.status_evento,
        evt.resultado_completo,
        evt.url_hotsite,
        evt.url_imagem,
        evt.id_fornecedor,
        evt.url_imagem_listagem,
        evt.obs_homologacao,
        evt.cronometragem,
        evt.realizacao,
        evt.cobertura,
        evt.url_regulamento,
        evt.valor_inscricao,
        evt.precos,
        '' as id_foco_radical,
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
        json_agg(json_build_object(
            'id_evento_percurso', pcr.id_evento_percurso,
            'percurso', pcr.percurso_evento,
            'unidade', pcr.unidade_de_medida,
            'tipo_corrida', pcr.tipo_corrida,
            'arquivo_percurso',
            <cfif structKeyExists(APPLICATION, "eventRouteMapbox") AND APPLICATION.eventRouteMapbox.enabled>
                CASE
                    WHEN percurso_repositorio.status = 'publicado'
                     AND arquivo_percurso.id_percurso_arquivo IS NOT NULL
                     AND (
                        (
                            NULLIF(to_jsonb(arquivo_percurso)->>'web_geojson_storage_key', '') IS NOT NULL
                            AND COALESCE(to_jsonb(arquivo_percurso)->>'web_sha256', '') ~ '^[0-9A-Fa-f]{64}$'
                        )
                        OR (
                            NULLIF(arquivo_percurso.geojson_storage_key, '') IS NOT NULL
                            AND arquivo_percurso.sha256 ~ '^[0-9A-Fa-f]{64}$'
                            AND arquivo_percurso.quantidade_pontos BETWEEN 2 AND 20000
                        )
                     )
                    THEN json_build_object(
                        'disponivel', true,
                        'id_percurso', percurso_repositorio.id_percurso,
                        'id_percurso_arquivo', arquivo_percurso.id_percurso_arquivo,
                        'versao', arquivo_percurso.versao,
                        'geometria_url',
                            '/evento/' || evt.tag || '/?route_geometry=1&id_evento_percurso='
                            || pcr.id_evento_percurso::text
                            || '&arquivo=' || arquivo_percurso.id_percurso_arquivo::text
                            || '&rev=' || left(
                                CASE
                                    WHEN NULLIF(to_jsonb(arquivo_percurso)->>'web_geojson_storage_key', '') IS NOT NULL
                                     AND COALESCE(to_jsonb(arquivo_percurso)->>'web_sha256', '') ~ '^[0-9A-Fa-f]{64}$'
                                    THEN to_jsonb(arquivo_percurso)->>'web_sha256'
                                    ELSE arquivo_percurso.sha256
                                END,
                                12
                            ),
                        'distancia_m', arquivo_percurso.distancia_gpx_m,
                        'pontos',
                            CASE
                                WHEN COALESCE(to_jsonb(arquivo_percurso)->>'web_quantidade_pontos', '') ~ '^[0-9]+$'
                                THEN (to_jsonb(arquivo_percurso)->>'web_quantidade_pontos')::integer
                                ELSE arquivo_percurso.quantidade_pontos
                            END,
                        'elevacao_min_m', arquivo_percurso.elevacao_min_m,
                        'elevacao_max_m', arquivo_percurso.elevacao_max_m,
                        'ganho_elevacao_m', arquivo_percurso.ganho_elevacao_m,
                        'bbox', json_build_array(
                            arquivo_percurso.bbox_min_lng,
                            arquivo_percurso.bbox_min_lat,
                            arquivo_percurso.bbox_max_lng,
                            arquivo_percurso.bbox_max_lat
                        )
                    )
                    ELSE NULL
                END,
            <cfelse>
                NULL,
            </cfif>
            'badges',(select json_agg(row_to_json(linha_2))
            from
                (select
                    bd.badge, bd.percurso, bd.badge, bd.valor_badge, bd.complemento_badge, bd.flag_badge,
                    tip.badge_tooltip,
                    tip.ordem
                from tb_badges bd
                inner join tb_badges_tipos tip on tip.badge = bd.badge
                where bd.id_evento = evt.id_evento
                and tip.ativo = true
                and bd.percurso = pcr.percurso_evento
                order by tip.ordem
                 ) as linha_2)
        ) ORDER BY pcr.percurso_evento, pcr.id_evento_percurso)
        from
        tb_evento_corridas_percursos pcr
        <cfif structKeyExists(APPLICATION, "eventRouteMapbox") AND APPLICATION.eventRouteMapbox.enabled>
            LEFT JOIN tb_evento_percursos_gpx vinculo_percurso
                ON vinculo_percurso.id_evento_percurso = pcr.id_evento_percurso
               AND vinculo_percurso.id_evento = pcr.id_evento
            LEFT JOIN tb_percursos percurso_repositorio
                ON percurso_repositorio.id_percurso = vinculo_percurso.id_percurso
            LEFT JOIN LATERAL (
                SELECT arquivo.*
                FROM tb_percurso_arquivos arquivo
                WHERE arquivo.id_percurso = percurso_repositorio.id_percurso
                  AND arquivo.ativo = true
                ORDER BY arquivo.versao DESC
                LIMIT 1
            ) arquivo_percurso ON true
        </cfif>
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
    ) as is_maratona
    from tb_evento_corridas evt
    #preserveSingleQuotes(VARIABLES.eventDescriptionSelection.joinSql)#
    WHERE evt.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
    order by data_final desc;
</cfquery>
<cfset logQueryDebug("qEvento", qEventoMeta, "backend_evento/base", "sem cache", qEvento)/>

<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario)>
    <cfset Usuario = REQUEST.Usuario>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario")>
</cfif>

<cfset qEventoSeguidosParticiparam = queryNew("id_usuario,id_pagina,nome,tag,tag_prefix,imagem_usuario,ano_participacao,prioridade_usuario,percurso_resultado,modalidade_resultado")/>
<cfset qEventoSeguidosVaoParticipar = queryNew("id_usuario,id_pagina,nome,tag,tag_prefix,imagem_usuario,ano_participacao,prioridade_usuario")/>
<cfset VARIABLES.eventFollowTotalParticiparam = 0/>
<cfset VARIABLES.eventFollowTotalVaoParticipar = 0/>
<cfset VARIABLES.eventFollowVerifiedAccess = Usuario.logado AND (isBoolean(Usuario.verificado) ? javacast("boolean", Usuario.verificado) : listFindNoCase("1,true,yes,sim,s", trim(Usuario.verificado & "")) GT 0)/>
<!--- Reativar quando a assinatura estiver disponível. --->
<cfset VARIABLES.eventFollowRestrictionEnabled = false/>
<cfset VARIABLES.eventFollowViewerVerified = NOT VARIABLES.eventFollowRestrictionEnabled OR VARIABLES.eventFollowVerifiedAccess/>


<!--- REDIRECIONA PARA BUSCA --->

<cfif NOT qEvento.recordcount>
    <cfset VARIABLES.eventFallbackSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/"/>
    <cflocation statuscode="301" addtoken="false" url="#VARIABLES.eventFallbackSearchPath#?termo=#replace(URL.tag, '-', ' ', 'ALL')#&redirect=true"/>
</cfif>

<!--- A API editorial filtra a listagem pelo id_evento canônico. --->
<cfset VARIABLES.eventoNoticiasRelacionadas = []/>
<cfset VARIABLES.eventoNoticiasRelacionadasCandidatas = []/>
<cfset VARIABLES.eventoNoticiasRelacionadasSlugs = {}/>
<cfset VARIABLES.eventoNoticiasRelacionadasApiBase = "https://conteudo.roadrunners.run"/>
<cfset VARIABLES.eventoNoticiasRelacionadasCacheKey = "rr_event_related_news_v4_" & qEvento.id_evento/>
<cfset VARIABLES.eventoNoticiasRelacionadasCacheTtlMinutes = 5/>
<cfset VARIABLES.eventoNoticiasRelacionadasMaxPages = 1/>
<cfset VARIABLES.eventoNoticiasRelacionadasApiAvailable = true/>

<cfif NOT structKeyExists(APPLICATION, "externalHttpCache") OR NOT isStruct(APPLICATION.externalHttpCache)>
    <cfset APPLICATION.externalHttpCache = {}/>
</cfif>

<cfif structKeyExists(APPLICATION.externalHttpCache, VARIABLES.eventoNoticiasRelacionadasCacheKey)
    AND isStruct(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey])
    AND structKeyExists(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey], "expiresAt")
    AND isDate(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey].expiresAt)
    AND APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey].expiresAt GT now()
    AND structKeyExists(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey], "payload")
    AND isArray(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey].payload)>
    <cfset VARIABLES.eventoNoticiasRelacionadas = duplicate(APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey].payload)/>
<cfelse>
    <cfloop from="1" to="#VARIABLES.eventoNoticiasRelacionadasMaxPages#" index="VARIABLES.eventoNoticiasRelacionadasPagina">
        <cfif NOT VARIABLES.eventoNoticiasRelacionadasApiAvailable OR arrayLen(VARIABLES.eventoNoticiasRelacionadasCandidatas) GTE 3>
            <cfbreak>
        </cfif>

        <cftry>
            <cfhttp
                url="#VARIABLES.eventoNoticiasRelacionadasApiBase#/rest/cmscf_api/v1/content?id_evento=#qEvento.id_evento#&per_page=10&page=#VARIABLES.eventoNoticiasRelacionadasPagina#&sort=published_at&dir=desc"
                method="get"
                timeout="6"
                throwOnError="false"
                result="rEventoNoticiasRelacionadas"/>

            <cfif isJSON(rEventoNoticiasRelacionadas.fileContent)>
                <cfset VARIABLES.eventoNoticiasRelacionadasResposta = deserializeJSON(rEventoNoticiasRelacionadas.fileContent)/>
                <cfif isStruct(VARIABLES.eventoNoticiasRelacionadasResposta)
                    AND structKeyExists(VARIABLES.eventoNoticiasRelacionadasResposta, "items")
                    AND isArray(VARIABLES.eventoNoticiasRelacionadasResposta.items)>
                    <cfset VARIABLES.eventoNoticiasRelacionadasPageItemCount = arrayLen(VARIABLES.eventoNoticiasRelacionadasResposta.items)/>
                    <cfloop array="#VARIABLES.eventoNoticiasRelacionadasResposta.items#" index="VARIABLES.eventoNoticiaRelacionada">
                        <cfif arrayLen(VARIABLES.eventoNoticiasRelacionadasCandidatas) GTE 3>
                            <cfbreak>
                        </cfif>
                        <cfif isStruct(VARIABLES.eventoNoticiaRelacionada)
                            AND structKeyExists(VARIABLES.eventoNoticiaRelacionada, "id_evento")
                            AND isNumeric(VARIABLES.eventoNoticiaRelacionada.id_evento)
                            AND val(VARIABLES.eventoNoticiaRelacionada.id_evento) EQ val(qEvento.id_evento)
                            AND structKeyExists(VARIABLES.eventoNoticiaRelacionada, "slug")
                            AND len(trim(VARIABLES.eventoNoticiaRelacionada.slug & ""))
                            AND structKeyExists(VARIABLES.eventoNoticiaRelacionada, "title")
                            AND len(trim(VARIABLES.eventoNoticiaRelacionada.title & ""))>
                            <cfset VARIABLES.eventoNoticiasRelacionadasSlugKey = lCase(trim(VARIABLES.eventoNoticiaRelacionada.slug & ""))/>
                            <cfif NOT structKeyExists(VARIABLES.eventoNoticiasRelacionadasSlugs, VARIABLES.eventoNoticiasRelacionadasSlugKey)>
                                <cfset VARIABLES.eventoNoticiasRelacionadasSlugs[VARIABLES.eventoNoticiasRelacionadasSlugKey] = true/>
                                <cfset arrayAppend(VARIABLES.eventoNoticiasRelacionadasCandidatas, duplicate(VARIABLES.eventoNoticiaRelacionada))/>
                            </cfif>
                        </cfif>
                    </cfloop>
                <cfelse>
                    <cfset VARIABLES.eventoNoticiasRelacionadasApiAvailable = false/>
                    <cfbreak>
                </cfif>

                <cfif NOT VARIABLES.eventoNoticiasRelacionadasPageItemCount
                    OR (structKeyExists(VARIABLES.eventoNoticiasRelacionadasResposta, "pagination")
                    AND isStruct(VARIABLES.eventoNoticiasRelacionadasResposta.pagination)
                    AND structKeyExists(VARIABLES.eventoNoticiasRelacionadasResposta.pagination, "total_pages")
                    AND isNumeric(VARIABLES.eventoNoticiasRelacionadasResposta.pagination.total_pages)
                    AND VARIABLES.eventoNoticiasRelacionadasPagina GTE val(VARIABLES.eventoNoticiasRelacionadasResposta.pagination.total_pages))>
                    <cfbreak>
                </cfif>
            <cfelse>
                <cfset VARIABLES.eventoNoticiasRelacionadasApiAvailable = false/>
                <cfbreak>
            </cfif>
        <cfcatch type="any">
            <cfset VARIABLES.eventoNoticiasRelacionadasApiAvailable = false/>
            <cfbreak>
        </cfcatch>
        </cftry>
    </cfloop>

    <cfif arrayLen(VARIABLES.eventoNoticiasRelacionadasCandidatas) GT 1>
        <cfset arraySort(VARIABLES.eventoNoticiasRelacionadasCandidatas, function(leftItem, rightItem) {
            var leftPublishedAt = structKeyExists(leftItem, "published_at") ? trim(leftItem.published_at & "") : "";
            var rightPublishedAt = structKeyExists(rightItem, "published_at") ? trim(rightItem.published_at & "") : "";
            var publishedComparison = compare(rightPublishedAt, leftPublishedAt);
            if (publishedComparison NEQ 0) {
                return publishedComparison;
            }
            return compare(lCase(trim(leftItem.slug & "")), lCase(trim(rightItem.slug & "")));
        })/>
    </cfif>

    <cfif arrayLen(VARIABLES.eventoNoticiasRelacionadasCandidatas)>
        <cfloop from="1" to="#min(3, arrayLen(VARIABLES.eventoNoticiasRelacionadasCandidatas))#" index="VARIABLES.eventoNoticiaRelacionadaIndex">
            <cfset arrayAppend(VARIABLES.eventoNoticiasRelacionadas, duplicate(VARIABLES.eventoNoticiasRelacionadasCandidatas[VARIABLES.eventoNoticiaRelacionadaIndex]))/>
        </cfloop>
    </cfif>

    <cfset APPLICATION.externalHttpCache[VARIABLES.eventoNoticiasRelacionadasCacheKey] = {
        payload = duplicate(VARIABLES.eventoNoticiasRelacionadas),
        expiresAt = dateAdd("n", VARIABLES.eventoNoticiasRelacionadasCacheTtlMinutes, now())
    }/>
</cfif>

<cfset qEventoFocoVinculos = queryNew("competition_id,competition_name,competition_date,place,uf,competition_path,identification_type,score,match_mode,status,payload,source", "varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar")/>
<cftry>
    <cfquery name="qEventoFocoVinculos" result="qEventoFocoVinculosMeta">
        SELECT
            competition_id::varchar as competition_id,
            competition_name,
            competition_date::varchar as competition_date,
            place,
            uf,
            competition_path,
            identification_type,
            score::varchar as score,
            match_mode,
            status,
            payload::varchar as payload,
            'vinculo' as source
        FROM tb_evento_foco_vinculos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        AND status = <cfqueryparam cfsqltype="cf_sql_varchar" value="active"/>
        ORDER BY competition_date NULLS LAST, competition_name NULLS LAST
    </cfquery>
    <cfset logQueryDebug("qEventoFocoVinculos", qEventoFocoVinculosMeta, "backend_evento/foco_vinculos", "sem cache", qEventoFocoVinculos)/>
    <cfcatch type="any">
        <cfset qEventoFocoVinculos = queryNew("competition_id,competition_name,competition_date,place,uf,competition_path,identification_type,score,match_mode,status,payload,source", "varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar")/>
    </cfcatch>
</cftry>

<cfset qEventoVideo = queryNew("id_media,media_titulo,media_url,media_canal_nome,data_publicacao")/>
<cftry>
    <cfquery name="qEventoVideo" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#" result="qEventoVideoMeta">
        SELECT media.id_media,
               media.media_titulo,
               media.media_url,
               media.media_canal_nome,
               media.data_publicacao
        FROM tb_media media
        WHERE media.pub_status = true
        AND media.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        AND coalesce(trim(media.media_url), '') <> ''
        ORDER BY media.data_publicacao DESC NULLS LAST,
                 media.id_media DESC
        LIMIT 1
    </cfquery>
    <cfset logQueryDebug("qEventoVideo", qEventoVideoMeta, "backend_evento/video_vinculado", "1min", qEventoVideo)/>
    <cfcatch type="any">
        <cfset qEventoVideo = queryNew("id_media,media_titulo,media_url,media_canal_nome,data_publicacao")/>
    </cfcatch>
</cftry>

<!--- CODIGO DA PAGINA NO RODAPE --->

<cfset VARIABLES.codPagina = "EVT" & qEvento.id_evento/>

<cfquery name="qFornecedores" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#" result="qFornecedoresMeta">
    select descricao_tipo, cfo.id_fornecedor, cfo.id_fornecedor_tipo, nome_fornecedor, site_fornecedor, cor.tag_tipo, tag_fornecedor
    from tb_evento_corridas_fornecedores cfo
    inner join tb_fornecedores_tipos tip on cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
    inner join tb_fornecedores cor on cfo.id_fornecedor = cor.id_fornecedor and cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
    where cfo.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    ORDER BY tip.id_fornecedor_tipo
</cfquery>
<cfset logQueryDebug("qFornecedores", qFornecedoresMeta, "backend_evento/fornecedores", "1min", qFornecedores)/>

<cfquery name="qFornecedor" result="qFornecedorMeta">
    SELECT fr.*, tag_fornecedor as tag, 'timer' as tipo_agregacao
    FROM tb_fornecedores fr
    WHERE tag_fornecedor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>
<cfset logQueryDebug("qFornecedor", qFornecedorMeta, "backend_evento/fornecedor", "sem cache", qFornecedor)/>

<cfquery name="qProcessamentoResultado" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#" result="qProcessamentoResultadoMeta">
    select max(data_processamento_final) as data_processamento_final
    from tb_resultados_processa
    where id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
</cfquery>
<cfset logQueryDebug("qProcessamentoResultado", qProcessamentoResultadoMeta, "backend_evento/processamento_resultado", "10min", qProcessamentoResultado)/>

<cfquery name="qAgrega" result="qAgregaMeta">
    SELECT * FROM tb_agrega_eventos
    <cfif len(trim(qEvento.id_agrega_evento))>
        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_agrega_evento#"/>
    <cfelse>
        WHERE id_agrega_evento = 0
    </cfif>
</cfquery>
<cfset logQueryDebug("qAgrega", qAgregaMeta, "backend_evento/agrega", "sem cache", qAgrega)/>

<!--- O tema pode pertencer a um circuito, independente do grupo de edicoes. --->
<cfif val(qEvento.id_tema) GT 1>
    <cfquery name="qEventoCircuito" result="qEventoCircuitoMeta">
        SELECT g.id_agrega_evento_legado AS id_agrega_evento,
               g.agregador_tag AS tag,
               g.agregador_nome AS nome_evento_agregado,
               g.agregador_tipo AS tipo_agregacao,
               g.id_tema, g.ordem
        FROM tb_agregadores g
        WHERE g.agregador_tipo = 'circuito'
          AND g.id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_tema#"/>
          AND coalesce(trim(g.agregador_tag), '') <> ''
          AND EXISTS (
              SELECT 1 FROM tb_agregadores_eventos ge
              WHERE ge.agregador_tag = g.agregador_tag
                AND ge.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
          )
        ORDER BY g.ordem NULLS LAST, g.agregador_tag
        LIMIT 1
    </cfquery>
    <cfset logQueryDebug("qEventoCircuito", qEventoCircuitoMeta, "backend_evento/circuito_tema", "sem cache", qEventoCircuito)/>
    <cfif qEventoCircuito.recordcount>
        <cfset qAgrega = qEventoCircuito/>
    </cfif>
</cfif>

<!--- BUSCA AS EDICOES DO MESMO AGREGADOR PARA EXIBIR NO CONTEUDO DO EVENTO --->
<cfset VARIABLES.eventRecordAssetsBaseUrl = "https://roadrunners.run/assets/paginas/"/>
<cfset qEventoEdicoes = queryNew("id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,tag,status_evento,id_agrega_evento,concluintes,tempo_campeao_masculino,nome_campeao_masculino,id_usuario_campeao_masculino,vinculo_reconhecido_campeao_masculino,tag_campeao_masculino,tag_prefix_campeao_masculino,imagem_campeao_masculino,tempo_campea_feminina,nome_campea_feminina,id_usuario_campea_feminina,vinculo_reconhecido_campea_feminina,tag_campea_feminina,tag_prefix_campea_feminina,imagem_campea_feminina")/>

<cfif val(qEvento.id_agrega_evento) GT 0>
    <cfquery name="qEventoEdicoes" result="qEventoEdicoesMeta">
        SELECT
            evt.id_evento,
            evt.nome_evento,
            evt.cidade,
            evt.estado,
            evt.pais,
            evt.data_inicial,
            evt.data_final,
            evt.tag,
            evt.status_evento,
            evt.id_agrega_evento,
            evt.concluintes,
            to_char(evento_campeao_masculino.tempo_total, 'HH24:MI:SS') as tempo_campeao_masculino,
            trim(evento_campeao_masculino.nome) as nome_campeao_masculino,
            evento_campeao_masculino.id_usuario as id_usuario_campeao_masculino,
            evento_campeao_masculino.resultado_reconhecido as vinculo_reconhecido_campeao_masculino,
            evento_campeao_masculino.tag as tag_campeao_masculino,
            evento_campeao_masculino.tag_prefix as tag_prefix_campeao_masculino,
            evento_campeao_masculino.imagem_usuario as imagem_campeao_masculino,
            to_char(evento_campea_feminina.tempo_total, 'HH24:MI:SS') as tempo_campea_feminina,
            trim(evento_campea_feminina.nome) as nome_campea_feminina,
            evento_campea_feminina.id_usuario as id_usuario_campea_feminina,
            evento_campea_feminina.resultado_reconhecido as vinculo_reconhecido_campea_feminina,
            evento_campea_feminina.tag as tag_campea_feminina,
            evento_campea_feminina.tag_prefix as tag_prefix_campea_feminina,
            evento_campea_feminina.imagem_usuario as imagem_campea_feminina
        FROM vw_evento_corridas evt
        LEFT JOIN LATERAL (
            SELECT coalesce(
                (
                    SELECT max(floor(resumo.percurso::numeric))
                    FROM tb_resultados_resumo resumo
                    WHERE resumo.id_evento = evt.id_evento
                    AND strpos(upper(concat_ws(' ', resumo.percurso, resumo.modalidade)), 'PCD') = 0
                ),
                (
                    SELECT max(floor(res_distancia.percurso))
                    FROM tb_resultados res_distancia
                    WHERE res_distancia.id_evento = evt.id_evento
                    AND res_distancia.percurso IS NOT NULL
                    AND res_distancia.tempo_total IS NOT NULL
                    AND res_distancia.tempo_total > time '00:00:00'
                    AND coalesce(res_distancia.concluinte, true) = true
                    AND coalesce(res_distancia.homologado, true) = true
                    AND coalesce(res_distancia.status_final, 0) < 3
                    AND coalesce(res_distancia.pcd, false) = false
                    AND strpos(upper(concat_ws(' ', res_distancia.nome_categoria, res_distancia.percurso, res_distancia.modalidade)), 'PCD') = 0
                )
            ) as percurso
        ) evento_distancia_principal ON true
        LEFT JOIN LATERAL (
            SELECT
                res.tempo_total,
                res.nome,
                res.id_usuario,
                CASE
                    -- Some imported rows retain the importer user ID. Only expose a profile
                    -- when the recorded athlete name also identifies that user.
                    WHEN res.id_usuario IS NOT NULL
                        AND res.id_usuario > 0
                        AND length(trim(coalesce(res.nome, ''))) > 0
                        AND (
                            (
                                length(trim(coalesce(usr.name, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(usr.name))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(usr.aka, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(usr.aka))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(pag.nome, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(pag.nome))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(pag.apelido, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(pag.apelido))), '\s+', ' ', 'g')
                            )
                        )
                    THEN true
                    ELSE false
                END as resultado_reconhecido,
                pag.tag,
                pag.tag_prefix,
                CASE
                    -- Only use the linked account after the name validation above confirms
                    -- that this result belongs to the athlete rather than to an importer.
                    WHEN res.id_usuario IS NOT NULL
                        AND res.id_usuario > 0
                        AND length(trim(coalesce(res.nome, ''))) > 0
                        AND (
                            regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(usr.name, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(usr.aka, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(pag.nome, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(pag.apelido, '')))), '\s+', ' ', 'g')
                        )
                    THEN coalesce(
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventRecordAssetsBaseUrl#"/> || nullif(trim(pag.path_imagem), ''),
                        nullif(trim(usr.strava_profile), ''),
                        nullif(trim(usr.imagem_usuario), ''),
                        '/assets/user.png'
                    )
                    ELSE '/assets/user.png'
                END as imagem_usuario
            FROM tb_resultados res
            LEFT JOIN tb_usuarios usr ON usr.id = res.id_usuario
            LEFT JOIN tb_paginas_usuarios tpu ON tpu.id_usuario = res.id_usuario
            LEFT JOIN tb_paginas pag ON pag.id_pagina = tpu.id_pagina
                AND pag.tag_prefix = 'atleta'
                AND pag.perfil_publico = true
            WHERE res.id_evento = evt.id_evento
            AND evento_distancia_principal.percurso IS NOT NULL
            AND floor(res.percurso) = evento_distancia_principal.percurso
            AND upper(trim(res.sexo)) IN ('M', 'MASC', 'MASCULINO', 'MASCULINA')
            AND res.tempo_total IS NOT NULL
            AND res.tempo_total > time '00:00:00'
            AND coalesce(res.concluinte, true) = true
            AND coalesce(res.homologado, true) = true
            AND coalesce(res.status_final, 0) < 3
            AND coalesce(res.pcd, false) = false
            AND strpos(upper(concat_ws(' ', res.nome_categoria, res.percurso, res.modalidade)), 'PCD') = 0
            ORDER BY
                CASE
                    WHEN res.classificacao_sexo = 1 THEN 0
                    WHEN res.classificacao_sexo > 1 THEN 1
                    ELSE 2
                END,
                res.classificacao_sexo ASC NULLS LAST,
                res.tempo_total ASC,
                pag.id_pagina ASC NULLS LAST
            LIMIT 1
        ) evento_campeao_masculino ON true
        LEFT JOIN LATERAL (
            SELECT
                res.tempo_total,
                res.nome,
                res.id_usuario,
                CASE
                    -- See the masculine query above: importing ownership is not an athlete link.
                    WHEN res.id_usuario IS NOT NULL
                        AND res.id_usuario > 0
                        AND length(trim(coalesce(res.nome, ''))) > 0
                        AND (
                            (
                                length(trim(coalesce(usr.name, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(usr.name))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(usr.aka, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(usr.aka))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(pag.nome, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(pag.nome))), '\s+', ' ', 'g')
                            )
                            OR (
                                length(trim(coalesce(pag.apelido, ''))) > 0
                                AND regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(pag.apelido))), '\s+', ' ', 'g')
                            )
                        )
                    THEN true
                    ELSE false
                END as resultado_reconhecido,
                pag.tag,
                pag.tag_prefix,
                CASE
                    WHEN res.id_usuario IS NOT NULL
                        AND res.id_usuario > 0
                        AND length(trim(coalesce(res.nome, ''))) > 0
                        AND (
                            regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(usr.name, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(usr.aka, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(pag.nome, '')))), '\s+', ' ', 'g')
                            OR regexp_replace(lower(unaccent(trim(res.nome))), '\s+', ' ', 'g') = regexp_replace(lower(unaccent(trim(coalesce(pag.apelido, '')))), '\s+', ' ', 'g')
                        )
                    THEN coalesce(
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventRecordAssetsBaseUrl#"/> || nullif(trim(pag.path_imagem), ''),
                        nullif(trim(usr.strava_profile), ''),
                        nullif(trim(usr.imagem_usuario), ''),
                        '/assets/user.png'
                    )
                    ELSE '/assets/user.png'
                END as imagem_usuario
            FROM tb_resultados res
            LEFT JOIN tb_usuarios usr ON usr.id = res.id_usuario
            LEFT JOIN tb_paginas_usuarios tpu ON tpu.id_usuario = res.id_usuario
            LEFT JOIN tb_paginas pag ON pag.id_pagina = tpu.id_pagina
                AND pag.tag_prefix = 'atleta'
                AND pag.perfil_publico = true
            WHERE res.id_evento = evt.id_evento
            AND evento_distancia_principal.percurso IS NOT NULL
            AND floor(res.percurso) = evento_distancia_principal.percurso
            AND upper(trim(res.sexo)) IN ('F', 'FEM', 'FEMININO', 'FEMININA')
            AND res.tempo_total IS NOT NULL
            AND res.tempo_total > time '00:00:00'
            AND coalesce(res.concluinte, true) = true
            AND coalesce(res.homologado, true) = true
            AND coalesce(res.status_final, 0) < 3
            AND coalesce(res.pcd, false) = false
            AND strpos(upper(concat_ws(' ', res.nome_categoria, res.percurso, res.modalidade)), 'PCD') = 0
            ORDER BY
                CASE
                    WHEN res.classificacao_sexo = 1 THEN 0
                    WHEN res.classificacao_sexo > 1 THEN 1
                    ELSE 2
                END,
                res.classificacao_sexo ASC NULLS LAST,
                res.tempo_total ASC,
                pag.id_pagina ASC NULLS LAST
            LIMIT 1
        ) evento_campea_feminina ON true
        WHERE evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_agrega_evento#"/>
        ORDER BY evt.data_final DESC, evt.data_inicial DESC, evt.id_evento DESC
    </cfquery>
    <cfset logQueryDebug("qEventoEdicoes", qEventoEdicoesMeta, "backend_evento/edicoes_agregador", "sem cache", qEventoEdicoes)/>
</cfif>

<cfquery name="qCupom" result="qCupomMeta">
    SELECT * FROM vw_evento_corridas_cupom
    WHERE (
        (id_evento_agrega = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/> AND tipo_evento = 1)
    <cfif len(trim(qEvento.id_agrega_evento))>
        OR (id_evento_agrega = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_agrega_evento#"/> AND tipo_evento = 2)
    </cfif>
    )
    AND current_date between data_validade_inicio and data_validade_fim
</cfquery>
<cfset logQueryDebug("qCupom", qCupomMeta, "backend_evento/cupom", "sem cache", qCupom)/>

<cfquery name="qTema" result="qTemaMeta">
    SELECT * FROM tb_temas
    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_tema#"/>
</cfquery>
<cfset logQueryDebug("qTema", qTemaMeta, "backend_evento/tema", "sem cache", qTema)/>

<!--- INSCRICAO INTERNA DO USUARIO --->

<cfset VARIABLES.eventoUsuarioInscritoInternamente = false/>
<cfif Usuario.logado>
    <cfquery name="qEventoInscricaoInternaUsuario" result="qEventoInscricaoInternaUsuarioMeta">
        SELECT 1 AS inscrito
        FROM tb_inscricoes
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        LIMIT 1
    </cfquery>
    <cfset VARIABLES.eventoUsuarioInscritoInternamente = qEventoInscricaoInternaUsuario.recordCount GT 0/>
    <cfset logQueryDebug("qEventoInscricaoInternaUsuario", qEventoInscricaoInternaUsuarioMeta, "backend_evento/inscricao_interna_usuario", "sem cache", qEventoInscricaoInternaUsuario)/>
</cfif>


<!--- CHECKIN --->

<cfif Usuario.logado>

    <cfif isDefined("URL.acao")>
        <cfif URL.acao EQ "remover">
             <cfquery datasource="runner_dba">
                DELETE FROM tb_evento_corridas_checkin
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            </cfquery>
            <cfset invalidateUsuarioCacheBlocks("agenda")/>
        <cfelse>
            <cfquery datasource="runner_dba">
                DELETE FROM tb_evento_corridas_checkin
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                AND tipo_checkin = 'inscricao'
            </cfquery>
            <cfquery datasource="runner_dba">
                INSERT INTO tb_evento_corridas_checkin
                (id_usuario, tipo_checkin, id_evento, id_usuario_checkin)
                VALUES
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.acao#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                )
                ON CONFLICT (id_evento, id_usuario, tipo_checkin)
                DO UPDATE SET
                tipo_checkin  = excluded.tipo_checkin
                RETURNING *;
            </cfquery>
            <cfset invalidateUsuarioCacheBlocks("agenda")/>
        </cfif>
        <cfif isDefined("URL.perfil")>
            <cflocation addtoken="false" url="/perfil/"/>
        </cfif>
        <cfif isDefined("URL.redirecionar")>
            <cflocation addtoken="false" url="#URL.redirecionar#"/>
        </cfif>
    </cfif>

    <cfquery name="qCheckingCalendario" result="qCheckingCalendarioMeta">
        SELECT * FROM tb_evento_corridas_checkin
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        AND tipo_checkin = 'calendario'
    </cfquery>
    <cfset logQueryDebug("qCheckingCalendario", qCheckingCalendarioMeta, "backend_evento/checking_calendario", "sem cache", qCheckingCalendario)/>

    <cfquery name="qCheckingInscricao" result="qCheckingInscricaoMeta">
        SELECT * FROM tb_evento_corridas_checkin
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        AND tipo_checkin = 'inscricao'
    </cfquery>
    <cfset logQueryDebug("qCheckingInscricao", qCheckingInscricaoMeta, "backend_evento/checking_inscricao", "sem cache", qCheckingInscricao)/>

    <cfif val(Usuario.id_pagina) GT 0>
        <cfset VARIABLES.eventFollowersAssetsBaseUrl = "https://roadrunners.run/assets/paginas/"/>

        <cfif VARIABLES.eventFollowViewerVerified>
            <cfquery name="qEventoTotalParticiparam" result="qEventoTotalParticiparamMeta">
                SELECT COUNT(DISTINCT usr.id) as total
                FROM tb_paginas pag
                INNER JOIN tb_paginas_usuarios tpu ON tpu.id_pagina = pag.id_pagina
                INNER JOIN tb_usuarios usr ON usr.id = tpu.id_usuario
                INNER JOIN tb_resultados res ON res.id_usuario = usr.id
                WHERE pag.tag_prefix = 'atleta'
                AND res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                AND res.concluinte = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                AND res.homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                AND COALESCE(res.status_final, 0) = 0
            </cfquery>
            <cfset VARIABLES.eventFollowTotalParticiparam = val(qEventoTotalParticiparam.total)/>
            <cfset logQueryDebug("qEventoTotalParticiparam", qEventoTotalParticiparamMeta, "backend_evento/total_participaram", "sem cache", qEventoTotalParticiparam)/>

            <cfquery name="qEventoTotalVaoParticipar" result="qEventoTotalVaoParticiparMeta">
                SELECT COUNT(DISTINCT usr.id) as total
                FROM tb_paginas pag
                INNER JOIN tb_paginas_usuarios tpu ON tpu.id_pagina = pag.id_pagina
                INNER JOIN tb_usuarios usr ON usr.id = tpu.id_usuario
                INNER JOIN tb_evento_corridas_checkin chk ON chk.id_usuario = usr.id
                WHERE pag.tag_prefix = 'atleta'
                AND chk.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                AND chk.tipo_checkin = <cfqueryparam cfsqltype="cf_sql_varchar" value="inscricao"/>
            </cfquery>
            <cfset VARIABLES.eventFollowTotalVaoParticipar = val(qEventoTotalVaoParticipar.total)/>
            <cfset logQueryDebug("qEventoTotalVaoParticipar", qEventoTotalVaoParticiparMeta, "backend_evento/total_vao_participar", "sem cache", qEventoTotalVaoParticipar)/>
        </cfif>

        <cfquery name="qEventoSeguidosParticiparam" result="qEventoSeguidosParticiparamMeta">
            SELECT
                linha.id_usuario,
                linha.id_pagina,
                linha.nome,
                linha.tag,
                linha.tag_prefix,
                linha.imagem_usuario,
                linha.ano_participacao,
                linha.prioridade_usuario,
                linha.percurso_resultado,
                linha.modalidade_resultado
            FROM (
                SELECT
                    usr.id as id_usuario,
                    pag.id_pagina,
                    pag.nome,
                    pag.tag,
                    pag.tag_prefix,
                    coalesce(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventFollowersAssetsBaseUrl#"/> || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                    DATE_PART('year', evt.data_inicial) as ano_participacao,
                    CASE WHEN usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/> THEN 0 ELSE 1 END as prioridade_usuario,
                    res.percurso as percurso_resultado,
                    res.modalidade as modalidade_resultado,
                    ROW_NUMBER() OVER (PARTITION BY usr.id ORDER BY res.percurso DESC NULLS LAST, res.id_resultado) as ordenacao_resultado
                FROM tb_paginas pag
                INNER JOIN tb_paginas_usuarios tpu ON tpu.id_pagina = pag.id_pagina
                INNER JOIN tb_usuarios usr ON usr.id = tpu.id_usuario
                INNER JOIN tb_resultados res ON res.id_usuario = usr.id
                INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                WHERE pag.tag_prefix = 'atleta'
                AND (
                    usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                    <cfif VARIABLES.eventFollowViewerVerified>
                    OR EXISTS (
                        SELECT 1
                        FROM tb_paginas_vinculos vin
                        WHERE vin.id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                        AND vin.id_pagina_destino = pag.id_pagina
                        AND vin.tipo_vinculo = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                        AND vin.vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                    )
                    </cfif>
                )
                AND res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                AND res.concluinte = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                AND res.homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                AND COALESCE(res.status_final, 0) = 0
            ) linha
            WHERE linha.ordenacao_resultado = 1
            ORDER BY linha.prioridade_usuario, linha.nome
        </cfquery>
        <cfset logQueryDebug("qEventoSeguidosParticiparam", qEventoSeguidosParticiparamMeta, "backend_evento/seguidos_participaram", "sem cache", qEventoSeguidosParticiparam)/>
        <cfset REQUEST.normalizeDisplayQuery(qEventoSeguidosParticiparam, "nome")/>

        <cfquery name="qEventoSeguidosVaoParticipar" result="qEventoSeguidosVaoParticiparMeta">
            SELECT DISTINCT
                usr.id as id_usuario,
                pag.id_pagina,
                pag.nome,
                pag.tag,
                pag.tag_prefix,
                coalesce(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventFollowersAssetsBaseUrl#"/> || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                DATE_PART('year', evt.data_inicial) as ano_participacao,
                CASE WHEN usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/> THEN 0 ELSE 1 END as prioridade_usuario
            FROM tb_paginas pag
            INNER JOIN tb_paginas_usuarios tpu ON tpu.id_pagina = pag.id_pagina
            INNER JOIN tb_usuarios usr ON usr.id = tpu.id_usuario
            INNER JOIN tb_evento_corridas_checkin chk ON chk.id_usuario = usr.id
            INNER JOIN tb_evento_corridas evt ON evt.id_evento = chk.id_evento
            WHERE pag.tag_prefix = 'atleta'
            AND (
                usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                <cfif VARIABLES.eventFollowViewerVerified>
                OR EXISTS (
                    SELECT 1
                    FROM tb_paginas_vinculos vin
                    WHERE vin.id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                    AND vin.id_pagina_destino = pag.id_pagina
                    AND vin.tipo_vinculo = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                    AND vin.vinculo_validado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                )
                </cfif>
            )
            AND chk.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            AND chk.tipo_checkin = <cfqueryparam cfsqltype="cf_sql_varchar" value="inscricao"/>
            ORDER BY prioridade_usuario, pag.nome
        </cfquery>
        <cfset logQueryDebug("qEventoSeguidosVaoParticipar", qEventoSeguidosVaoParticiparMeta, "backend_evento/seguidos_vao_participar", "sem cache", qEventoSeguidosVaoParticipar)/>
        <cfset REQUEST.normalizeDisplayQuery(qEventoSeguidosVaoParticipar, "nome")/>
    </cfif>

</cfif>


<!--- LOG --->

<cfif APPLICATION.codSite EQ "RR" AND structKeyExists(VARIABLES, "template") AND VARIABLES.template EQ "/evento/">
    <!--- A pagina de evento RR usa audience.events, inclusive nas rotas localizadas.
          Nao reativar o log por recusa/GPC ou falha de coleta. Hotsites mantem o legado. --->
<cfelseif Usuario.logado AND BooleanFormat(Usuario.is_admin)>
    <!--- USER EH ADMIM --->
<cfelse>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, log_user_agent, site)
        VALUES
        ('evento',<cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.HTTP_USER_AGENT#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
    </cfquery>

</cfif>
