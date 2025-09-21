<cfparam name="URL.id_evento" type="numeric" default="22792"/>
<cfparam name="URL.percurso" type="numeric" default="42"/>
<cfparam name="URL.id_usuario" type="numeric" default="0"/>

<!--- PERFIL PROFISSIONAL OU ABERTO --->

<cfquery name="qPagina" datasource="runner_dba">
    select pag.*,
    usr.id as id_usuario, usr.cbat, usr.assessoria,
    usr.inscricao_366, (select produto from desafio_cna where id_usuario = usr.id and status = 'C') as inscricao_365,
    usr.strava_id, usr.data_nascimento, usr.pais, usr.strava_bio, coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem,
    pag.tag, pag.instagram, usr.strava_profile, usr.cbat, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario
    from tb_paginas pag
    inner join tb_paginas_usuarios pgusr on pag.id_pagina = pgusr.id_pagina
    inner join tb_usuarios usr on usr.id = pgusr.id_usuario
    where pag.id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_numeric" value="#URL.id_usuario#"/>
</cfquery>

<!--- RESULTADOS DO ATLETA --->

<cfquery name="qCorridasAtleta" datasource="runner_dba">
    SELECT id_resultado, id_usuario, num_peito, UPPER(nome) as nome, nome_categoria, res.id_evento, evt.nome_evento, evt.tag, modalidade, pace, percurso, equipe,
    sexo, tempo_bruto, tempo_total, classificacao_categoria, classificacao_sexo, nacionalidade, evt.data_inicial, evt.data_final, evt.tipo_corrida, posicao_ranking,
    '' as id_foco_radical, evt.status_evento,
    evt.cidade, evt.estado, evt.pais,
    DATE_PART('week', evt.data_final) AS week,
    DATE_PART('month', evt.data_final) AS month,
    DATE_PART('year', evt.data_final) AS year,
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
            where pcr.id_evento = evt.id_evento AND percurso_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
            limit 1
        ) as is_maratona,
        null as tipo_checkin
    FROM tb_resultados res
    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
    AND res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
    AND res.status_final < 3
    AND evt.id_evento <> 22792
    ORDER BY evt.data_final DESC
    LIMIT 100
</cfquery>

<!--- PERCURSOS/BADGES DO ATLETA --->

<cfquery name="qPercursos" dbtype="query">
    SELECT DISTINCT percurso FROM qCorridasAtleta
    WHERE id_usuario is not null and id_usuario <> 0
</cfquery>

<!--- CALENDARIO DO ATLETA --->

<cfquery name="qEventosCheckin" datasource="runner_dba">
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
            AND chk.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
            ORDER BY chk.tipo_checkin DESC
            LIMIT 1)
        as tipo_checkin
    FROM vw_evento_corridas evt
    WHERE evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
    AND id_evento IN (SELECT chk.id_evento FROM tb_evento_corridas_checkin chk
                        WHERE chk.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
                        AND chk.tipo_checkin = 'inscricao'
                        AND chk.id_fornecedor is null)
    ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema desc, evt.id_agrega_evento desc, max_percurso desc NULLS LAST, id_foco_radical NULLS LAST, evt.tipo_corrida
</cfquery>


<div class="big-darkbar w-100 text-center align-content-center">
    <button class="btn btn-sm btn-dark px-2 me-2 float-end" onclick="descarregarAthlete()">_</button>
    <h5 class="text-light text-uppercase fw-bold m-0">Athlete Profile</h5>
</div>

<cfif qPagina.recordcount>

    <cfoutput>

        <div class="row m-0 atleteprofile">
            <div class="col-10 lh-sm">
                <img src="https://roadrunners.run/assets/paginas/#qPagina.path_imagem#" class="rounded-3 bg-light m-2 border border-1 p-1 border-dark float-start" style="width: 100px;height:120px; object-fit: cover; object-position: top center;" alt="imagem do atleta" onerror="this.src='https://roadrunners.run/assets/user.png';">
                <h5 class="mt-2">#qPagina.nome#</h5>
                <h6 class="mb-1"><img src="https://roadrunners.run/assets/flags/svg/#lCase(qPagina.pais)#.svg" style="width:22px" title="#uCase(qCorridasAtleta.nacionalidade)#"> #uCase(qCorridasAtleta.nacionalidade)#<cfif len(trim(qPagina.cidade))>#qPagina.cidade#</cfif><cfif len(trim(qPagina.uf))>/#qPagina.uf#</cfif></h6>
                <h6 class="mb-1 small"><span class="small opacity-50 me-1">Equipe:</span>#qPagina.assessoria#</h6>
                <h6 class="mb-1 small"><span class="small opacity-50 me-1">Idade:</span><cfif len(trim(qPagina.data_nascimento))>#dateDiff("yyyy",qPagina.data_nascimento, now())# anos (#dateformat(qPagina.data_nascimento, "dd/mm/yyyy")#)</cfif></h6>
                <h6 class="mb-1 small"><span class="small opacity-50 me-1">Obs.:</span><cfif len(trim(qPagina.descricao))>#qPagina.descricao#</cfif></h6>
            </div>
            <div class="col-2 p-2 text-center">
                <a href="//roadrunners.run/atleta/#qPagina.tag#" target="_blank" class="btn btn-sm btn-outline-dark w-100">RR Profile</a>
                <a <cfif len(trim(qPagina.cbat))>href="https://cbat.org.br/atletas/#qPagina.cbat#/perfil"<cfelse> disabled</cfif> target="_blank" class="btn btn-sm btn-outline-dark w-100 <cfif len(trim(qPagina.cbat))><cfelse>disabled</cfif>">CBAt Profile</a>
                <a <cfif len(trim(qPagina.instagram))>href="https://instagram.com/#qPagina.instagram#"<cfelse> disabled</cfif> target="_blank" class="btn btn-sm btn-outline-dark w-100 <cfif len(trim(qPagina.instagram))><cfelse>disabled</cfif>">Instagram</a>
                <a <cfif len(trim(qPagina.strava_id))>href="https://strava.com/athlete/#qPagina.strava_id#"<cfelse> disabled</cfif> target="_blank" class="btn btn-sm btn-outline-dark w-100 <cfif len(trim(qPagina.strava_id))><cfelse>disabled</cfif>">Strava</a>
                <span class="small text-opacity-25" style="font-size:8px;">PG#qPagina.id_pagina#|USR#qPagina.id_usuario#</span>
            </div>
        </div>

    </cfoutput>

    <div class="row m-0 lastraces">
        <div class="col-7 list-left border-end border-1 border-warning">
            <div class="listtitle w-100 text-center align-content-center">
                <h6 class="text-light m-0">Last Races</h6>
            </div>
            <div class="flex-grow-1 w-100 overflow-auto">
                <table class="table table-sm table-striped table-hover">
                    <thead class="thead-dark">
                        <tr>
                            <th scope="col" style="width:30px">POS</th>
                            <th scope="col">EVENT</th>
                            <th scope="col" style="width:60px" class="text-center">TIME</th>
                        </tr>
                    </thead>
                    <tbody id="">
                        <cfoutput query="qCorridasAtleta">
                            <tr class="fw-bold">
                                <td class="text-center text-warning fw-bold">#qCorridasAtleta.classificacao_sexo#º</td> <!---DATA--->
                                <td>#qCorridasAtleta.nome_evento#</td> <!---EVENTO--->
                                <td class="text-end text-center">#qCorridasAtleta.tempo_total#</td> <!---RESULTADO PESSOAL--->
                            </tr>
                        </cfoutput>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="col-5 list-right">
            <div class="listtitle w-100 text-center align-content-center">
                <h6 class="text-light m-0">Race Result</h6>
            </div>
            <div class="flex-grow-1 w-100 overflow-auto">
                <table class="table table-sm table-striped table-hover">
                    <thead class="thead-dark">
                        <tr>
                            <th scope="col" style="width:30px">POS</th>
                            <th scope="col">ATHLETE</th>
                            <th scope="col" style="width:40px"></th>
                            <th scope="col" style="width:60px" class="text-center">TIME</th>
                        </tr>
                    </thead>
                    <tbody id="">
<!---                        <tr>
                            <td class="text-center text-warning fw-bold">1º</td> <!---BIBERO DE PEITO--->
                            <td>Name Lastname</td> <!---NOME--->
                            <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/br.svg" title="BRASIL"></td> <!---NACIONALIDADE--->
                            <td class="text-end text-center">02:34:45</td> <!---RECORDE PESSOAL--->
                        </tr>
                        <tr class="fw-bold">
                            <td class="text-center text-warning fw-bold">2º</td> <!---BIBERO DE PEITO--->
                            <td>Name Lastname</td> <!---NOME--->
                            <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/br.svg" title="BRASIL"></td> <!---NACIONALIDADE--->
                            <td class="text-end text-center">02:34:45</td> <!---RECORDE PESSOAL--->
                        </tr>
                        <tr>
                            <td class="text-center text-warning fw-bold">3º</td> <!---BIBERO DE PEITO--->
                            <td>Name Lastname</td> <!---NOME--->
                            <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/br.svg" title="BRASIL"></td> <!---NACIONALIDADE--->
                            <td class="text-end text-center">02:34:45</td> <!---RECORDE PESSOAL--->
                        </tr>
                        <tr>
                            <td class="text-center text-warning fw-bold">4º</td> <!---BIBERO DE PEITO--->
                            <td>Name Lastname</td> <!---NOME--->
                            <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/br.svg" title="BRASIL"></td> <!---NACIONALIDADE--->
                            <td class="text-end text-center">02:34:45</td> <!---RECORDE PESSOAL--->
                        </tr>
                        <tr>
                            <td class="text-center text-warning fw-bold">5º</td> <!---BIBERO DE PEITO--->
                            <td>Name Lastname</td> <!---NOME--->
                            <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/br.svg" title="BRASIL"></td> <!---NACIONALIDADE--->
                            <td class="text-end text-center">02:34:45</td> <!---RECORDE PESSOAL--->
                        </tr>--->
                    </tbody>
                </table>
            </div>
        </div>
    </div>

<cfelse>

    <p>Perfil não encontrado.</p>

</cfif>
