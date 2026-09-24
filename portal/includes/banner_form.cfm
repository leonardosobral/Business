<cfscript>
VARIABLES.bannerSavedRow={};
if(qBannerManagementEdit.recordCount) for(VARIABLES.bannerColumn in listToArray(qBannerManagementEdit.columnList)) VARIABLES.bannerSavedRow[VARIABLES.bannerColumn]=qBannerManagementEdit[VARIABLES.bannerColumn][1];
VARIABLES.bannerForm=bannerFormValues(FORM,VARIABLES.bannerSavedRow);
VARIABLES.bannerPageLabels={home='Página inicial',search='Busca',state='Eventos por estado',event='Página de evento',athlete='Perfil do atleta'};
</cfscript>
<cfoutput>
<div class="card shadow-0 border border-white border-opacity-10 mb-4"><div class="card-body">
  <h5><cfif len(VARIABLES.bannerForm.banner_id)>Editar banner<cfelse>Novo banner</cfif></h5>
  <p class="text-muted">O banner novo será salvo como rascunho. Ative-o quando estiver pronto.</p>
  <cfif len(VARIABLES.bannerForm.scope_error)><div class="alert alert-warning">#htmlEditFormat(VARIABLES.bannerForm.scope_error)#</div></cfif>
  <form action="./?view=house" method="post" enctype="multipart/form-data" data-banner-form>
    <input type="hidden" name="acao" value="salvar_banner"/>
    <input type="hidden" name="banner_csrf" value="#htmlEditFormat(VARIABLES.bannerManagementCsrf)#"/>
    <input type="hidden" name="banner_id" value="#htmlEditFormat(VARIABLES.bannerForm.banner_id)#"/>
    <fieldset class="mb-4"><legend class="h6">Conteúdo</legend><div class="row g-3">
      <div class="col-12"><label for="banner_nome" class="form-label">Nome interno</label>
        <input id="banner_nome" type="text" class="form-control" name="banner_nome" required minlength="3" maxlength="160" value="#htmlEditFormat(VARIABLES.bannerForm.banner_nome)#"/>
      </div>
      <cfloop list="desktop,mobile" index="bannerKind">
        <div class="col-md-6"><label for="banner_arquivo_#bannerKind#" class="form-label">Imagem #bannerKind#</label>
          <input id="banner_arquivo_#bannerKind#" type="file" class="form-control" name="banner_arquivo_#bannerKind#" accept="image/jpeg,image/png,image/gif" data-banner-upload="#bannerKind#" aria-describedby="banner_file_help_#bannerKind# banner_file_info_#bannerKind#"<cfif !len(VARIABLES.bannerForm[bannerKind & '_path'])> required</cfif>/>
          <div id="banner_file_help_#bannerKind#" class="form-text">JPG, PNG ou GIF, até 10 MiB e 40 megapixels. As dimensões são identificadas automaticamente. Na edição, deixe vazio para manter a imagem.</div>
          <div id="banner_file_info_#bannerKind#" class="form-text" data-banner-info="#bannerKind#" aria-live="polite"><cfif structKeyExists(VARIABLES,'bannerFieldErrors') AND structKeyExists(VARIABLES.bannerFieldErrors,bannerKind)>#htmlEditFormat(VARIABLES.bannerFieldErrors[bannerKind])#</cfif></div>
          <img data-banner-preview="#bannerKind#" alt="Prévia da imagem #bannerKind#" style="max-width:100%;max-height:220px;width:auto;height:auto;margin-top:0.75rem"<cfif len(VARIABLES.bannerForm[bannerKind & '_path'])> src="#htmlEditFormat(bannerManagementBuildAssetUrl(VARIABLES.bannerForm[bannerKind & '_path']))#"<cfelse> hidden</cfif>/>
        </div>
      </cfloop>
      <div class="col-12"><label for="banner_alt_text" class="form-label">Descrição da imagem para acessibilidade</label>
        <input id="banner_alt_text" type="text" class="form-control" name="banner_alt_text" required minlength="3" maxlength="300" aria-describedby="banner_alt_help" value="#htmlEditFormat(VARIABLES.bannerForm.banner_alt_text)#"/>
        <div id="banner_alt_help" class="form-text">Exemplo: Inscrições abertas para a corrida de Florianópolis, em 20 de outubro.</div>
      </div>
      <div class="col-12"><label for="banner_link_destino" class="form-label">Link de destino</label>
        <input id="banner_link_destino" type="text" class="form-control" name="banner_link_destino" required placeholder="/evento/nome/ ou https://exemplo.com" value="#htmlEditFormat(VARIABLES.bannerForm.banner_link_destino)#"/>
      </div>
    </div></fieldset>
    <fieldset class="mb-4"><legend class="h6">Onde exibir</legend>
      <p class="mb-3">Banner responsivo — lateral no desktop / área de banner no mobile</p>
      <div class="row g-3">
      <cfloop list="pages,regions" index="bannerScopeKind">
        <div class="col-md-6"><label class="form-label" for="banner_#bannerScopeKind#_mode"><cfif bannerScopeKind EQ 'pages'>Páginas<cfelse>Estados</cfif></label>
          <select id="banner_#bannerScopeKind#_mode" name="banner_#bannerScopeKind#_mode" class="form-select">
            <option value="ALL"<cfif VARIABLES.bannerForm['banner_' & bannerScopeKind & '_mode'] EQ 'ALL'> selected</cfif>><cfif bannerScopeKind EQ 'pages'>Todas as páginas compatíveis<cfelse>Todo o Brasil</cfif></option>
            <option value="SELECTED"<cfif VARIABLES.bannerForm['banner_' & bannerScopeKind & '_mode'] NEQ 'ALL'> selected</cfif>>Selecionar <cfif bannerScopeKind EQ 'pages'>páginas<cfelse>estados</cfif></option>
          </select>
          <div data-banner-choices="#bannerScopeKind#" class="mt-2 d-flex flex-wrap gap-3" style="max-width:100%">
            <cfloop list="#bannerScopeKind EQ 'pages' ? 'home,search,state,event,athlete' : 'AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO'#" index="bannerOption">
              <label class="form-check-label"><input class="form-check-input me-1" type="checkbox" name="banner_#bannerScopeKind#" value="#bannerOption#"<cfif listFindNoCase(VARIABLES.bannerForm['banner_' & bannerScopeKind],bannerOption)> checked</cfif>/>#bannerScopeKind EQ 'pages' ? VARIABLES.bannerPageLabels[bannerOption] : bannerOption#</label>
            </cfloop>
          </div>
        </div>
      </cfloop>
      </div>
      <p class="form-text mt-3">A região usa o contexto da página ou do visitante. Não representa sua localização física. A posição aparece nas páginas e formatos compatíveis.</p>
    </fieldset>
    <fieldset class="mb-4"><legend class="h6">Período</legend><div class="row g-3">
      <div class="col-md-6"><label for="banner_inicio_exibicao" class="form-label">Início</label>
        <input id="banner_inicio_exibicao" type="datetime-local" class="form-control" name="banner_inicio_exibicao" required value="#htmlEditFormat(VARIABLES.bannerForm.banner_inicio_exibicao)#"/>
      </div>
      <div class="col-md-6"><label for="banner_fim_exibicao" class="form-label">Fim</label>
        <input id="banner_fim_exibicao" type="datetime-local" class="form-control" name="banner_fim_exibicao" required value="#htmlEditFormat(VARIABLES.bannerForm.banner_fim_exibicao)#"/>
      </div>
    </div></fieldset>
    <details class="mb-4"><summary>Opções avançadas</summary><div class="row g-3 mt-1">
      <div class="col-md-4"><label for="banner_peso_exibicao" class="form-label">Peso de exibição</label>
        <input id="banner_peso_exibicao" type="number" min="1" step="1" class="form-control" name="banner_peso_exibicao" required value="#htmlEditFormat(VARIABLES.bannerForm.banner_peso_exibicao)#"/>
      </div>
      <div class="col-md-4"><label for="banner_prioridade" class="form-label">Prioridade</label>
        <input id="banner_prioridade" type="number" min="1" step="1" class="form-control" name="banner_prioridade" required value="#htmlEditFormat(VARIABLES.bannerForm.banner_prioridade)#"/>
      </div>
      <div class="col-md-4"><label for="banner_abrir_nova_aba" class="form-label">Abrir destino</label>
        <select id="banner_abrir_nova_aba" class="form-select" name="banner_abrir_nova_aba">
          <option value="auto"<cfif VARIABLES.bannerForm.banner_abrir_nova_aba EQ 'auto'> selected</cfif>>Automático: externo em nova aba</option>
          <option value="0"<cfif VARIABLES.bannerForm.banner_abrir_nova_aba EQ '0'> selected</cfif>>Mesma aba</option>
          <option value="1"<cfif VARIABLES.bannerForm.banner_abrir_nova_aba EQ '1'> selected</cfif>>Nova aba</option>
        </select>
      </div>
    </div></details>
    <div class="d-flex flex-wrap gap-2"><button type="submit" class="btn btn-warning">Salvar banner</button><a class="btn btn-outline-light" href="./?view=house">Cancelar</a></div>
  </form>
</div></div>
</cfoutput>
<style>[data-banner-choices][hidden]{display:none!important}</style>
<script src="/assets/js/portal-banners.js" defer></script>
