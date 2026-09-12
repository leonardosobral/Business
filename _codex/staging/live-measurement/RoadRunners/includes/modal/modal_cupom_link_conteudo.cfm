<cfparam name="URL.id_cupom" default="0"/>

<cfquery name="qCupom" result="qCupomMeta">
    SELECT * FROM vw_cupom cp
    WHERE cp.ativo = true
    <cfif isDefined("URL.id_cupom") AND len(trim(URL.id_cupom))>
        AND cp.id_cupom = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_cupom#"/>
    </cfif>
    <cfif isDefined("URL.id_evento") AND len(trim(URL.id_evento))>
        AND cp.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfif>
</cfquery>
<cfset couponLinkModal = REQUEST.i18n.athlete.coupons.linkModal />


<cfif qCupom.recordcount>

    <cfset urlCompleta = qCupom.curl>
    <!-- host = tudo entre esquema e a primeira / -->
    <cfset host = rereplace(urlCompleta, "^[a-zA-Z][a-zA-Z0-9+.-]*://([^/:?##]+).*", "\1", "one")>
    <cfif NOT len(host)>
          <!-- tenta sem esquema -->
          <cfset host = rereplace("http://" & urlCompleta, "^[a-zA-Z][a-zA-Z0-9+.-]*://([^/:?##]+).*", "\1", "one")>
    </cfif>

    <cfset parts = listToArray(lCase(host), ".")>
    <cfset n = arrayLen(parts)>
    <cfset br2 = "com,org,gov,net,edu,mil,blog,art,eco,dev,rec,slg,esp,agr,adm,adv,eng,imb,ind,inf,med,pro,psi,tec,tur,vet">
    <cfif n GTE 3 AND parts[n] EQ "br" AND listFindNoCase(br2, parts[n-1])>
        <cfset dominio = parts[n-2]>
    <cfelse>
        <cfset dominio = (n GTE 2 ? parts[n-1] : host)>
    </cfif>
    <cfset logoSvgPath = "/assets/logos/#dominio#.svg">
    <cfset logoPngPath = "/assets/logos/#dominio#.png">
    <cfset logoAssetPath = "">
    <cfset logoElementId = "logo_" & qCupom.id_cupom>
    <cfset titleElementId = "titulo_" & qCupom.id_cupom>
    <cfif fileExists(expandPath(logoSvgPath))>
        <cfset logoAssetPath = logoSvgPath>
    <cfelseif fileExists(expandPath(logoPngPath))>
        <cfset logoAssetPath = logoPngPath>
    </cfif>

    <cfoutput>
        <!---<div class="card p-3">
            <h1 class="text-center">#qCupom.condicoes#</h1>
            <p class="card-text">#qCupom.descricao#</p>
            <p class="card-text small">Cupom:&nbsp;<input type="text" class="form-text" style="width: calc(100% - 90px)" value="#qCupom.cupom#" id="copiaCupom">&nbsp;<button class="btn btn-light px-2 py-1" onclick="copiaCupom()"><icon onclick="copiaCupom()" class="fa fa-copy"></icon><span class="small d-none" id="copiaMsg">&nbsp;Copiar</span></button></p>
            <a type="button" href="#qCupom.curl#" target="_blank" class="btn w-100 btn-success shadow-0">Utilize este Cupom&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></a>
        </div>--->

        <div class="card p-3">
            <div class="row g-3">
                <div class="col-12 col-md-6 text-center text-md-start">
                    <cfif len(trim(logoAssetPath))>
                        <img src="#logoAssetPath#" id="#logoElementId#" width="75%" class="w-75" onerror="this.style.display = 'none';document.getElementById('#titleElementId#').style.display = 'block'; return true;">
                    </cfif>
                    <span id="#titleElementId#" class="text-capitalize fw-bold"<cfif len(trim(logoAssetPath))> style="display: none"</cfif>>#dominio#</span>
                </div>
                <div class="col-12 col-md-6 small lh-1 text-center">#qCupom.descricao#</div>
                <div class="col-12 d-flex">
                    <div class="form-outline" data-mdb-input-init="" data-mdb-input-initialized="true">
                        <input type="text" class="form-control" disabled value="#qCupom.cupom#" id="copiaCupom">
                        <label class="form-label" for="copiaCupom" style="margin-left: 0px;">#couponLinkModal.couponLabel#</label>
                    </div>
                    <button class="btn btn-secondary px-1 ms-1 w-100px shadow-0" onclick="copiaCupom()">
                        <icon onclick="copiaCupom()" class="fa fa-copy"></icon>&nbsp;<span class="" id="copiaMsg">#couponLinkModal.copy#</span>
                    </button>
                </div>
                <div class="col-12">
                    <a id="linkInscricao" type="button" href="#qCupom.curl#" target="_blank" class="btn w-100 btn-success shadow-0"
                        <cfif NOT isNull(qCupom.id_evento) AND reFind("^[1-9][0-9]{0,9}$",trim(qCupom.id_evento & ""))>data-audience-live-registration="#HTMLEditFormat(qCupom.id_evento)#"</cfif>>
                        #couponLinkModal.useCoupon#&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon>
                    </a>
                </div>
            </div>
        </div>
    </cfoutput>

<cfelse>

    <div class="card p-3">
        <p class="card-text"><cfoutput>#couponLinkModal.expired#</cfoutput></p>
        <cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                subject="CUPOM INEXISTENTE" usetls="true"
                server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                charset="utf-8" type="html" port="587">
            <cfif isDefined("URL.id_evento") AND len(trim(URL.id_evento))>
                <p>id_evento = #URL.id_evento#</p>
            </cfif>
        </cfmail>
    </div>

</cfif>
