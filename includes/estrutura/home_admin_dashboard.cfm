<cfset qBusinessAdminHomeStats = QueryNew("contas_ativas,contas_pendentes,usuarios_ativos,eventos_ativos,solicitacoes_cadastro,solicitacoes_eventos,campanhas_ativas")/>
<cfset qBusinessAdminHomeRegistrations = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,email_responsavel,data_criacao")/>
<cfset qBusinessAdminHomeEventRequests = QueryNew("id_solicitacao,nome_conta,nome_evento,data_criacao")/>
<cfset qBusinessAdminHomeLegacyPartners = QueryNew("id,name,email,perfil,nome_comercial")/>
<cfset VARIABLES.businessAdminHomeReady = true/>
<cfset VARIABLES.businessAdminHomeError = ""/>
<cfset VARIABLES.businessAdminHomeTablesReady = false/>

<cftry>
    <cfquery name="qBusinessAdminHomeTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_usuarios"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_evento_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_eventos"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_corridas"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_usuarios"/>
          )
    </cfquery>

    <cfset VARIABLES.businessAdminHomeTableNames = ValueList(qBusinessAdminHomeTableCheck.table_name)/>
    <cfset VARIABLES.businessAdminHomeTablesReady = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_contas")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_usuarios")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_eventos")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_cadastro_solicitacoes")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_evento_solicitacoes")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_ad_eventos")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_evento_corridas")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_usuarios")/>

    <cfif NOT VARIABLES.businessAdminHomeTablesReady>
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeError = "Estrutura de contas Business incompleta no banco."/>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeTablesReady = false/>
        <cfset VARIABLES.businessAdminHomeError = cfcatch.message/>
    </cfcatch>
</cftry>

<cfif VARIABLES.businessAdminHomeTablesReady>
    <cftry>
    <cfquery name="qBusinessAdminHomeStats">
        SELECT
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'ATIVA') AS contas_ativas,
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'PENDENTE') AS contas_pendentes,
            (SELECT count(*)::integer FROM tb_conta_usuarios WHERE status::text = 'ATIVO') AS usuarios_ativos,
            (SELECT count(*)::integer FROM tb_conta_eventos WHERE status::text = 'ATIVO') AS eventos_ativos,
            (SELECT count(*)::integer FROM tb_conta_cadastro_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_cadastro,
            (SELECT count(*)::integer FROM tb_conta_evento_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_eventos,
            (
                SELECT count(*)::integer
                FROM tb_ad_eventos
                WHERE status = 1
                  AND (inicio_ad IS NULL OR inicio_ad <= now())
                  AND (final_ad IS NULL OR final_ad >= now())
            ) AS campanhas_ativas
    </cfquery>

    <cfquery name="qBusinessAdminHomeRegistrations">
        SELECT id_solicitacao,
               nome_empresa,
               tipo_prestador,
               email_responsavel,
               data_criacao
        FROM tb_conta_cadastro_solicitacoes
        WHERE status::text = 'PENDENTE'
        ORDER BY data_criacao DESC
        LIMIT 5
    </cfquery>

    <cfquery name="qBusinessAdminHomeEventRequests">
        SELECT sol.id_solicitacao,
               cont.nome_conta,
               evt.nome_evento,
               sol.data_criacao
        FROM tb_conta_evento_solicitacoes sol
        INNER JOIN tb_contas cont ON cont.id_conta = sol.id_conta
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = sol.id_evento
        WHERE sol.status::text = 'PENDENTE'
        ORDER BY sol.data_criacao DESC
        LIMIT 5
    </cfquery>

    <cfquery name="qBusinessAdminHomeLegacyPartners">
        SELECT id,
               name,
               email,
               partner_info ->> 'perfil' AS perfil,
               partner_info ->> 'nome_comercial' AS nome_comercial
        FROM tb_usuarios
        WHERE partner_info IS NOT NULL
        ORDER BY id DESC
        LIMIT 5
    </cfquery>

    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeError = cfcatch.message/>
        <cfset qBusinessAdminHomeStats = QueryNew("contas_ativas,contas_pendentes,usuarios_ativos,eventos_ativos,solicitacoes_cadastro,solicitacoes_eventos,campanhas_ativas")/>
        <cfset qBusinessAdminHomeRegistrations = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,email_responsavel,data_criacao")/>
        <cfset qBusinessAdminHomeEventRequests = QueryNew("id_solicitacao,nome_conta,nome_evento,data_criacao")/>
        <cfset qBusinessAdminHomeLegacyPartners = QueryNew("id,name,email,perfil,nome_comercial")/>
    </cfcatch>
</cftry>
</cfif>

<section class="col-12">
    <div class="card">
        <div class="card-body p-3">
            <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-3 mb-3">
                <div>
                    <div class="text-warning fw-bold text-uppercase small">Admin interno</div>
                    <h3 class="mb-1">Painel Business</h3>
                    <p class="text-muted mb-0">Resumo operacional das contas, solicitacoes e campanhas.</p>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <a class="btn btn-sm btn-warning" href="/administracao/contas/">Contas</a>
                    <a class="btn btn-sm btn-outline-warning" href="/eventos/">Eventos</a>
                    <a class="btn btn-sm btn-outline-warning" href="/ads/">Ads</a>
                    <a class="btn btn-sm btn-outline-warning" href="/portal/conteudo/">Conteudo</a>
                </div>
            </div>

            <cfif VARIABLES.businessAdminHomeReady AND qBusinessAdminHomeStats.recordcount>
                <div class="row g-3">
                    <div class="col-6 col-xl">
                        <div class="border rounded p-3 h-100">
                            <div class="text-muted small">Contas ativas</div>
                            <div class="fs-3 fw-bold"><cfoutput>#numberFormat(qBusinessAdminHomeStats.contas_ativas, "9,999")#</cfoutput></div>
                            <div class="small text-muted"><cfoutput>#numberFormat(qBusinessAdminHomeStats.contas_pendentes, "9,999")# pendentes</cfoutput></div>
                        </div>
                    </div>
                    <div class="col-6 col-xl">
                        <div class="border rounded p-3 h-100">
                            <div class="text-muted small">Usuarios ativos</div>
                            <div class="fs-3 fw-bold"><cfoutput>#numberFormat(qBusinessAdminHomeStats.usuarios_ativos, "9,999")#</cfoutput></div>
                            <div class="small text-muted">vinculados a contas</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl">
                        <div class="border rounded p-3 h-100">
                            <div class="text-muted small">Eventos ativos</div>
                            <div class="fs-3 fw-bold"><cfoutput>#numberFormat(qBusinessAdminHomeStats.eventos_ativos, "9,999")#</cfoutput></div>
                            <div class="small text-muted">em contas</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl">
                        <div class="border rounded p-3 h-100">
                            <div class="text-muted small">Solicitacoes</div>
                            <div class="fs-3 fw-bold"><cfoutput>#numberFormat(qBusinessAdminHomeStats.solicitacoes_cadastro + qBusinessAdminHomeStats.solicitacoes_eventos, "9,999")#</cfoutput></div>
                            <div class="small text-muted">cadastro e eventos</div>
                        </div>
                    </div>
                    <div class="col-12 col-xl">
                        <div class="border rounded p-3 h-100">
                            <div class="text-muted small">Campanhas ativas</div>
                            <div class="fs-3 fw-bold"><cfoutput>#numberFormat(qBusinessAdminHomeStats.campanhas_ativas, "9,999")#</cfoutput></div>
                            <div class="small text-muted">ads em veiculacao</div>
                        </div>
                    </div>
                </div>
            <cfelse>
                <div class="alert alert-warning mb-0">
                    Nao foi possivel carregar o resumo administrativo agora.
                    <cfif len(trim(VARIABLES.businessAdminHomeError))>
                        <span class="d-block small mt-1"><cfoutput>#htmlEditFormat(VARIABLES.businessAdminHomeError)#</cfoutput></span>
                    </cfif>
                </div>
            </cfif>
        </div>
    </div>
</section>

<cfif VARIABLES.businessAdminHomeReady>
    <section class="col-xl-6">
        <div class="card h-100">
            <div class="card-body p-3">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="mb-0">Cadastros pendentes</h5>
                    <a class="btn btn-sm btn-outline-warning" href="/administracao/contas/">Revisar</a>
                </div>

                <cfif qBusinessAdminHomeRegistrations.recordcount>
                    <div class="list-group list-group-light">
                        <cfoutput query="qBusinessAdminHomeRegistrations">
                            <a class="list-group-item list-group-item-action bg-transparent text-reset px-0" href="/administracao/contas/">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAdminHomeRegistrations.nome_empresa)#</div>
                                <div class="small text-muted">#htmlEditFormat(qBusinessAdminHomeRegistrations.tipo_prestador)# - #htmlEditFormat(qBusinessAdminHomeRegistrations.email_responsavel)#</div>
                                <div class="small text-muted">#lsDateFormat(qBusinessAdminHomeRegistrations.data_criacao, "dd/mm/yyyy")# #lsTimeFormat(qBusinessAdminHomeRegistrations.data_criacao, "HH:mm")#</div>
                            </a>
                        </cfoutput>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhuma solicitacao de cadastro pendente.</p>
                </cfif>
            </div>
        </div>
    </section>

    <section class="col-xl-6">
        <div class="card h-100">
            <div class="card-body p-3">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="mb-0">Eventos solicitados</h5>
                    <a class="btn btn-sm btn-outline-warning" href="/eventos/">Revisar</a>
                </div>

                <cfif qBusinessAdminHomeEventRequests.recordcount>
                    <div class="list-group list-group-light">
                        <cfoutput query="qBusinessAdminHomeEventRequests">
                            <a class="list-group-item list-group-item-action bg-transparent text-reset px-0" href="/eventos/">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAdminHomeEventRequests.nome_evento)#</div>
                                <div class="small text-muted">#htmlEditFormat(qBusinessAdminHomeEventRequests.nome_conta)#</div>
                                <div class="small text-muted">#lsDateFormat(qBusinessAdminHomeEventRequests.data_criacao, "dd/mm/yyyy")# #lsTimeFormat(qBusinessAdminHomeEventRequests.data_criacao, "HH:mm")#</div>
                            </a>
                        </cfoutput>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhuma solicitacao de evento pendente.</p>
                </cfif>
            </div>
        </div>
    </section>

    <cfif qBusinessAdminHomeLegacyPartners.recordcount>
        <section class="col-12">
            <div class="card">
                <div class="card-body p-3">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h5 class="mb-1">Usuarios legados com partner_info</h5>
                            <div class="text-muted small">Amostra para migracao ou limpeza gradual.</div>
                        </div>
                        <a class="btn btn-sm btn-outline-warning" href="/administracao/contas/">Gerenciar contas</a>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle mb-0">
                            <thead>
                                <tr>
                                    <th>Usuario</th>
                                    <th>E-mail</th>
                                    <th>Perfil</th>
                                    <th>Nome comercial</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qBusinessAdminHomeLegacyPartners">
                                    <tr>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.name)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.email)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.perfil)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.nome_comercial)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    </cfif>
</cfif>
