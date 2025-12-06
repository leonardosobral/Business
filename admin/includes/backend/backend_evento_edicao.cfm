<!--- EDITAR DADOS DO EVENTO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_basico" AND isDefined("FORM.nome_evento") AND Len(trim(FORM.nome_evento))>

    <cfquery name="qCidade">
        SELECT cod_cidade, nome_cidade
        FROM tb_cidades
        where cod_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.cidade#"/>
        order by nome_cidade
    </cfquery>

    <cfif FORM.id_evento EQ 0>

        <cfquery name="qInsert">
            INSERT INTO tb_evento_corridas
            (nome_evento, cidade, cod_cidade, estado, data_inicial, data_final, tag,
                tipo_corrida, endereco, coordenadas, url_inscricao, url_hotsite)
            VALUES
            (
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome_evento#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.nome_cidade#"/>,
             <cfqueryparam cfsqltype="cf_sql_integer" value="#qCidade.cod_cidade#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.estado#"/>,
             <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_inicial#"/>,
             <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_final#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tag#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.endereco#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.coordenadas#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_inscricao#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_hotsite#"/>
            ) RETURNING id_evento
        </cfquery>

        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.nome_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
        </cfquery>

        <cflocation addtoken="false" url="/admin/?id_evento=#qInsert.id_evento#"/>

    <cfelse>

        <cfquery>
            UPDATE tb_evento_corridas
            SET
            nome_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome_evento#"/>,
            cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.nome_cidade#"/>,
            cod_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCidade.cod_cidade#"/>,
            estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.estado#"/>,
            data_inicial = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_inicial#"/>,
            data_final = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_final#"/>,
            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tag#"/>,
            tipo_corrida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
            endereco = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.endereco#"/>,
            coordenadas = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.coordenadas#"/>,
            url_inscricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_inscricao#"/>,
            url_hotsite = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_hotsite#"/>
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.nome_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
        </cfquery>

    </cfif>

</cfif>


<!--- EDITAR CONFIGURACOES DO EVENTO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_configuracoes" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET
        destaque = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.destaque#" null="#NOT len(trim(FORM.destaque))#"/>,
        info_duplicado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.info_duplicado#" null="#NOT len(trim(FORM.info_duplicado))#"/>,
        status_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.status_evento#" null="#NOT len(trim(FORM.status_evento))#"/>,
        ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.ativo#"/>,
        id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_tema#"/>,
        id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_agrega_evento#" null="#NOT len(trim(FORM.id_agrega_evento))#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR CONFIGURACOES DO OR (RESULTADOS) --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_or" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET
        obs_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs_resultado#" null="#NOT len(trim(FORM.obs_resultado))#"/>,
        obs_homologacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs_homologacao#" null="#NOT len(trim(FORM.obs_homologacao))#"/>,
        ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.ranking#" null="#NOT len(trim(FORM.ranking))#"/>,
        homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.homologado#" null="#NOT len(trim(FORM.homologado))#"/>,
        url_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_resultado#"/>,
        url_wiclax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_wiclax#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR FORNECEDORES --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_fornecedores" AND isDefined("FORM.id_fornecedor") AND Len(trim(FORM.id_fornecedor))>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_fornecedores
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfloop list="#FORM.id_fornecedor#" item="item" index="index" delimiters=",">
        <cfquery>
            INSERT INTO tb_evento_corridas_fornecedores
            (id_fornecedor, id_fornecedor_tipo, id_evento)
            VALUES
            (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#listToArray(FORM.id_fornecedor, ',')[index]#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#listToArray(FORM.id_fornecedor_tipo, ',')[index]#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
            )
        </cfquery>
    </cfloop>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_fornecedor#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR AGRAGADORES --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_agregadores" AND isDefined("FORM.agregador_tag") AND Len(trim(FORM.agregador_tag))>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_agregadores_eventos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfloop list="#FORM.agregador_tag#" item="item" index="index" delimiters=",">
        <cfquery>
            INSERT INTO tb_agregadores_eventos
            (agregador_tag, id_evento)
            VALUES
            (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#listToArray(FORM.agregador_tag, ',')[index]#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
            )
        </cfquery>
    </cfloop>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.agregador_tag#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

    <cflocation addtoken="false" url="./?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#FORM.id_evento#&sessao=configuracoes"/>

</cfif>



<!--- EDITAR INTEGRACOES --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_competition_id" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_relaciona
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        AND id_parceiro = 1
        AND nome_variavel = 'competition_id'
    </cfquery>

    <cfquery>
        INSERT INTO tb_evento_corridas_relaciona
        (id_evento_parceiro, id_parceiro, nome_variavel, id_evento)
        VALUES
        (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento_parceiro#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="competition_id"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        )
    </cfquery>

    <!---

    <cfdump var="#FORM#"/>

    <cfloop list="#FORM.fieldnames#" item="item" index="index" delimiters=",">

        <cfif item NEQ "ACTION" AND item NEQ "ID_EVENTO">

            <cfif item EQ "id_rr" AND len(trim(FORM.id_rr))>
                <cfquery>
                    INSERT INTO tb_evento_corridas_relaciona
                    (id_evento_parceiro, id_parceiro, percurso, id_evento)
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_rr#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>,
                        null,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                    )
                </cfquery>
            <cfelseif item EQ "id_fr" AND len(trim(FORM.id_rr))>
                <cfquery>
                    INSERT INTO tb_evento_corridas_relaciona
                    (id_evento_parceiro, id_parceiro, percurso, id_evento)
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_fr#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>,
                        null,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                    )
                </cfquery>
            <cfelse>
                <cfif len(trim(form[item]))>
                    <cfquery>
                        INSERT INTO tb_evento_corridas_relaciona
                        (id_evento_parceiro, id_parceiro, percurso, id_evento)
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#form[item]#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#replace(item, 'ID_FR_', '')#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                        )
                        ON CONFLICT (id_evento, id_parceiro, id_evento_parceiro, percurso)
                        DO UPDATE SET
                        data_cadastro  = now(),
                        id_evento_parceiro  = excluded.id_evento_parceiro
                        RETURNING *;
                    </cfquery>
                </cfif>
            </cfif>

        </cfif>

    </cfloop>

    <cfabort/>

    <cflocation addtoken="false" url="/evento/#qEvento.tag#/"/>

    --->

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento_parceiro#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EXCLUIR EVENTO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "excluir_evento" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_fornecedores
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_percursos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_relaciona
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfif isDefined("FORM.aceite")>

         <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados_resumo
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

    </cfif>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

    <cflocation url="./?periodo=#URL.periodo#&busca=#urlEncodedFormat(URL.busca)#&estado=#URL.estado#" addtoken="false"/>

</cfif>


<!--- EXCLUIR RESULTADOS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "excluir_resultados" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfif isDefined("FORM.aceite")>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados_resumo
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

    </cfif>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR DESCRICAO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_descricao" AND isDefined("FORM.descricao")>

    <cfquery>
        UPDATE tb_evento_corridas
        SET descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.descricao#"/>,
        url_imagem = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_imagem#"/>,
        resumo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.resumo#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.resumo#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR PERCURSOS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_percursos" AND isDefined("FORM.categorias")>

    <cfquery>
        UPDATE tb_evento_corridas
        SET categorias = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.categorias#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.categorias#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- SALVAR PERCURSOS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "salvar_evento_percurso" AND isDefined("FORM.id_evento_percurso") AND Len(trim(FORM.id_evento_percurso))>

    <cfquery>
        UPDATE tb_evento_corridas_percursos
        SET percurso_evento = <cfqueryparam cfsqltype="cf_sql_numeric" value="#FORM.percurso_evento#"/>,
        unidade_de_medida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.unidade_de_medida#"/>,
        data_percurso = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_percurso#"/>,
        hora_largada = <cfqueryparam cfsqltype="cf_sql_time" value="#FORM.hora_largada#" null="#NOT len(trim(FORM.hora_largada))#"/>,
        tipo_corrida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
        percurso_bloqueado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        WHERE id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento_percurso#"/>
    </cfquery>

    <cfquery name="qBadges">
        SELECT tip.image_path, tip.badge, bg.valor_badge, bg.percurso, bg.complemento_badge from tb_badges_tipos tip
        left join tb_badges bg on bg.badge = tip.badge
            and bg.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
            and bg.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>
        where tip.tipo_badge = 'percurso'
        and tip.min_km <= <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>
        order by ordem
    </cfquery>

    <cfloop query="qBadges">

        <cfif isDefined("FORM.#qBadges.badge#")>
            <cfquery>
                INSERT INTO tb_badges
                (id_evento, percurso, badge, valor_badge, complemento_badge, flag_badge)
                values
                (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBadges.badge#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM[qBadges.badge&'_valor_badge']#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM[qBadges.badge&'_complemento_badge']#"/>,
                true
                )
                ON CONFLICT (id_evento, percurso, badge)
                    DO UPDATE SET
                    valor_badge  = excluded.valor_badge,
                    complemento_badge  = excluded.complemento_badge
                    RETURNING *;
            </cfquery>
        </cfif>

    </cfloop>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#FORM.id_evento_percurso#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- DADOS DO EVENTO EDITADO --->

<cfif Len(trim(URL.id_evento))>
    <cfquery name="qEvento">
        SELECT evt.*
        FROM tb_evento_corridas evt
        WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>
<cfelse>
    <cfquery name="qEvento">
        SELECT evt.*
        FROM tb_evento_corridas evt
        WHERE evt.id_evento = 0
    </cfquery>
</cfif>
