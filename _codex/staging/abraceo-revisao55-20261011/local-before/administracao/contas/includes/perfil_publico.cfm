<!--- Research is shown only to internal administrators, after the scoped account lookup. --->
<cfif VARIABLES.businessAccountsCanAdminAll AND qBusinessAccountEdit.recordcount>
    <cfquery name="qAccountPublicProfileReady">
        SELECT to_regclass('public.tb_conta_perfis_publicos') IS NOT NULL AS ready
    </cfquery>
    <cfif qAccountPublicProfileReady.ready>
        <cfquery name="qAccountPublicProfile">
            SELECT logo_path, dados::text AS dados, data_pesquisa
            FROM public.tb_conta_perfis_publicos
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountEdit.id_conta#"/>
        </cfquery>
        <cfif qAccountPublicProfile.recordcount>
            <cfset VARIABLES.accountPublicProfile = deserializeJSON(qAccountPublicProfile.dados)/>
            <cfset VARIABLES.accountPublicProfileFields = [
                {key="razao_social_pesquisada", label="Razão social"},
                {key="nome_fantasia_cadastral", label="Nome fantasia"},
                {key="cnpj_pesquisado", label="CNPJ pesquisado"},
                {key="situacao_cadastral_consultada", label="Situação cadastral consultada"},
                {key="contato_publico", label="Contato público"},
                {key="email_publico", label="E-mail público"},
                {key="telefone_publico", label="Telefone público"},
                {key="site_revisado", label="Site"},
                {key="endereco_cadastral", label="Endereço"},
                {key="bairro_cadastral", label="Bairro"},
                {key="municipio_cadastral", label="Município"},
                {key="uf_cadastral", label="UF"},
                {key="cep_cadastral", label="CEP"},
                {key="tipo_prestador_sugerido", label="Atuação"},
                {key="fonte_abraceo", label="Fonte ABRACEO"},
                {key="fonte_vinculo_cnpj", label="Fonte do vínculo com CNPJ"},
                {key="fonte_cadastro", label="Fonte cadastral"}
            ]/>
            <cfoutput>
                <div class="accounts-panel p-3">
                    <h5>Dados pesquisados · ABRACEO</h5>
                    <p class="small text-muted">Pesquisa de #dateFormat(qAccountPublicProfile.data_pesquisa, "dd/mm/yyyy")#. Contatos públicos não confirmam representação da empresa. A liberação de acesso continua sujeita ao fluxo de aprovação do Business.</p>
                    <cfif reFind("^/assets/contas/abraceo/[a-z0-9-]+\.(png|jpg)$", qAccountPublicProfile.logo_path)>
                        <img src="#encodeForHTMLAttribute(qAccountPublicProfile.logo_path)#" alt="Logotipo de #encodeForHTMLAttribute(qBusinessAccountEdit.nome_conta)#" width="120" height="120" style="object-fit:contain;background:white;border-radius:8px" class="mb-3"/>
                    </cfif>
                    <dl class="row small" style="overflow-wrap:anywhere">
                        <cfloop array="#VARIABLES.accountPublicProfileFields#" item="profileField">
                            <cfif structKeyExists(VARIABLES.accountPublicProfile, profileField.key) AND len(trim(VARIABLES.accountPublicProfile[profileField.key]))>
                                <dt class="col-sm-4">#encodeForHTML(profileField.label)#</dt>
                                <dd class="col-sm-8">#encodeForHTML(VARIABLES.accountPublicProfile[profileField.key])#</dd>
                            </cfif>
                        </cfloop>
                    </dl>
                </div>
            </cfoutput>
        <cfelse>
            <p class="text-muted">Nenhum complemento de pré-cadastro importado para esta conta.</p>
        </cfif>
    <cfelse>
        <p class="text-muted">Complemento de pré-cadastro ainda não disponível.</p>
    </cfif>
</cfif>
