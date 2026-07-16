<cfset VARIABLES.userManagerPageFormIsEdit = isDefined("VARIABLES.userManagerPageRow") AND isStruct(VARIABLES.userManagerPageRow) AND structKeyExists(VARIABLES.userManagerPageRow, "id_pagina")/>
<cfset VARIABLES.userManagerPageFormId = VARIABLES.userManagerPageFormIsEdit ? val(VARIABLES.userManagerPageRow.id_pagina) : 0/>

<form method="post" action="./">
  <input type="hidden" name="user_manager_action" value="salvar_pagina"/>
  <input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/>
  <input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/>
  <input type="hidden" name="page_id" value="<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>"/>
  <input type="hidden" name="return_tab" value="paginas"/>

  <div class="row g-3">
    <div class="col-12 col-lg-6"><label class="form-label">Nome *</label><input class="form-control" name="nome" required maxlength="128" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(VARIABLES.userManagerPageRow.nome)#</cfoutput></cfif>"/></div>
    <div class="col-12 col-lg-6"><label class="form-label">Apelido</label><input class="form-control" name="apelido" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow.apelido, ''))#</cfoutput></cfif>"/></div>
    <div class="col-8 col-lg-6"><label class="form-label">Slug *</label><input class="form-control" name="tag" required value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(VARIABLES.userManagerPageRow.tag)#</cfoutput></cfif>" placeholder="nome-do-atleta"/></div>
    <div class="col-4 col-lg-2"><label class="form-label">Prefixo</label><input class="form-control" name="tag_prefix" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(VARIABLES.userManagerPageRow.tag_prefix)#</cfoutput><cfelse>atleta</cfif>"/></div>
    <div class="col-6 col-lg-2"><label class="form-label">Cidade</label><input class="form-control" name="pagina_cidade" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow.cidade, ''))#</cfoutput></cfif>"/></div>
    <div class="col-3 col-lg-1"><label class="form-label">UF</label><input class="form-control" name="pagina_uf" maxlength="2" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow.uf, ''))#</cfoutput></cfif>"/></div>
    <div class="col-3 col-lg-1"><label class="form-label">ID cidade</label><input class="form-control" type="number" name="id_cidade" value="<cfif VARIABLES.userManagerPageFormIsEdit AND val(VARIABLES.userManagerPageRow.id_cidade) GT 0><cfoutput>#VARIABLES.userManagerPageRow.id_cidade#</cfoutput></cfif>"/></div>
    <div class="col-12"><label class="form-label">Descrição</label><textarea class="form-control" name="descricao" rows="3"><cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow.descricao, ''))#</cfoutput></cfif></textarea></div>
    <div class="col-12"><label class="form-label">Arquivo da imagem</label><input class="form-control" name="path_imagem" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow.path_imagem, ''))#</cfoutput></cfif>" placeholder="nome-do-arquivo.jpg"/></div>

    <div class="col-12 d-flex flex-wrap gap-4 py-2 border-top border-bottom border-secondary-subtle">
      <div class="form-check"><input class="form-check-input" type="checkbox" name="verificado" value="true" id="um-page-verified-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>"<cfif VARIABLES.userManagerPageFormIsEdit AND userManagerBoolean(VARIABLES.userManagerPageRow.verificado)> checked</cfif>/><label class="form-check-label" for="um-page-verified-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>">Verificada</label></div>
      <div class="form-check"><input class="form-check-input" type="checkbox" name="profissional" value="true" id="um-page-pro-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>"<cfif VARIABLES.userManagerPageFormIsEdit AND userManagerBoolean(VARIABLES.userManagerPageRow.profissional)> checked</cfif>/><label class="form-check-label" for="um-page-pro-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>">Profissional</label></div>
      <div class="form-check"><input class="form-check-input" type="checkbox" name="perfil_publico" value="true" id="um-page-public-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>"<cfif !VARIABLES.userManagerPageFormIsEdit OR userManagerBoolean(VARIABLES.userManagerPageRow.perfil_publico)> checked</cfif>/><label class="form-check-label" for="um-page-public-<cfoutput>#VARIABLES.userManagerPageFormId#</cfoutput>">Perfil público</label></div>
    </div>

    <cfloop list="instagram,facebook,whatsapp,website,youtube,tiktok,loja" index="VARIABLES.userManagerSocialField">
      <cfset VARIABLES.userManagerSocialLabels = {instagram="Instagram",facebook="Facebook",whatsapp="WhatsApp",website="Website",youtube="YouTube",tiktok="TikTok",loja="Loja"}/>
      <cfset VARIABLES.userManagerSocialDefaultPublic = listFindNoCase("instagram,facebook,website,youtube,tiktok,loja", VARIABLES.userManagerSocialField) GT 0/>
      <div class="col-12 col-lg-6">
        <label class="form-label"><cfoutput>#VARIABLES.userManagerSocialLabels[VARIABLES.userManagerSocialField]#</cfoutput></label>
        <div class="input-group">
          <input class="form-control" name="<cfoutput>#VARIABLES.userManagerSocialField#</cfoutput>" value="<cfif VARIABLES.userManagerPageFormIsEdit><cfoutput>#htmlEditFormat(userManagerDisplayValue(VARIABLES.userManagerPageRow[VARIABLES.userManagerSocialField], ''))#</cfoutput></cfif>"/>
          <span class="input-group-text"><input class="form-check-input mt-0" type="checkbox" name="<cfoutput>#VARIABLES.userManagerSocialField#_publico</cfoutput>" value="true" title="Exibir publicamente"<cfif (VARIABLES.userManagerPageFormIsEdit AND userManagerBoolean(VARIABLES.userManagerPageRow[VARIABLES.userManagerSocialField & "_publico"])) OR (!VARIABLES.userManagerPageFormIsEdit AND VARIABLES.userManagerSocialDefaultPublic)> checked</cfif>/></span>
        </div>
      </div>
    </cfloop>
  </div>

  <div class="d-flex justify-content-end mt-3"><button class="btn btn-sm btn-warning" type="submit"><i class="fa-solid fa-check me-2"></i>Salvar página</button></div>
</form>
