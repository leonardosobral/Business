<cfinclude template="includes/backend.cfm"/>

<cfset VARIABLES.themeShowForm = qThemeEdit.recordcount GT 0 OR (isDefined("URL.tema_novo") AND len(trim(URL.tema_novo)) GT 0 AND val(URL.tema_novo) EQ 1) OR FORM.acao EQ "salvar_tema"/>
<cfset VARIABLES.themeLogoTotal = 0/>
<cfset VARIABLES.themeTagTotal = 0/>
<cfloop query="qThemesList">
  <cfif len(trim(qThemesList.logo))>
    <cfset VARIABLES.themeLogoTotal = VARIABLES.themeLogoTotal + 1/>
  </cfif>
  <cfif len(trim(qThemesList.tag))>
    <cfset VARIABLES.themeTagTotal = VARIABLES.themeTagTotal + 1/>
  </cfif>
</cfloop>

<style>
  .themes-table td,
  .themes-table th {
    vertical-align: middle;
  }

  .theme-logo-preview {
    max-width: 150px;
    max-height: 56px;
    object-fit: contain;
  }

  .theme-preview-card {
    min-height: 120px;
    border: 1px solid rgba(255,255,255,.14);
  }

  .theme-color-chip {
    width: 1.2rem;
    height: 1.2rem;
    border-radius: 999px;
    display: inline-block;
    border: 1px solid rgba(255,255,255,.35);
    vertical-align: middle;
  }

  .theme-actions {
    width: 110px;
    white-space: nowrap;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Temas visuais</h3>
              <p class="text-muted mb-0">Gerencie logos, cores e links usados nas paginas de agregadores de eventos no Road Runners.</p>
            </div>
            <cfif isDefined("qPerfil") AND qPerfil.recordcount GT 0 AND qPerfil.is_admin>
              <div>
                <a class="btn btn-warning" href="./?tema_novo=1">Novo tema</a>
              </div>
            </cfif>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR qPerfil.recordcount EQ 0 OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">Voce nao tem permissao para gerenciar temas.</div>
          <cfelse>
            <cfif len(trim(VARIABLES.themesAlert.type)) AND len(trim(VARIABLES.themesAlert.message))>
              <cfoutput><div class="alert alert-#VARIABLES.themesAlert.type#">#htmlEditFormat(VARIABLES.themesAlert.message)#</div></cfoutput>
            </cfif>

            <div class="row gx-xl-3 mb-4">
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Temas</div>
                    <div class="h4 mb-0"><cfoutput>#qThemesList.recordcount#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Com logo</div>
                    <div class="h4 mb-0"><cfoutput>#VARIABLES.themeLogoTotal#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Com tag</div>
                    <div class="h4 mb-0"><cfoutput>#VARIABLES.themeTagTotal#</cfoutput></div>
                  </div>
                </div>
              </div>
            </div>

            <cfif VARIABLES.themeShowForm>
              <cfset VARIABLES.themeFormId = qThemeEdit.recordcount GT 0 ? qThemeEdit.id_tema[1] : (isDefined("FORM.id_tema") ? FORM.id_tema : "")/>
              <cfset VARIABLES.themeFormLogo = qThemeEdit.recordcount GT 0 ? qThemeEdit.logo[1] : (isDefined("FORM.logo") ? FORM.logo : "")/>
              <cfset VARIABLES.themeFormTag = qThemeEdit.recordcount GT 0 ? qThemeEdit.tag[1] : (isDefined("FORM.tag") ? FORM.tag : "")/>
              <cfset VARIABLES.themeFormWebsite = qThemeEdit.recordcount GT 0 ? qThemeEdit.website[1] : (isDefined("FORM.website") ? FORM.website : "")/>
              <cfset VARIABLES.themeFormInstagram = qThemeEdit.recordcount GT 0 ? qThemeEdit.instagram[1] : (isDefined("FORM.instagram") ? FORM.instagram : "")/>
              <cfset VARIABLES.themeFormYoutube = qThemeEdit.recordcount GT 0 ? qThemeEdit.youtube[1] : (isDefined("FORM.youtube") ? FORM.youtube : "")/>
              <cfset VARIABLES.themeFormAppIos = qThemeEdit.recordcount GT 0 ? qThemeEdit.app_ios[1] : (isDefined("FORM.app_ios") ? FORM.app_ios : "")/>
              <cfset VARIABLES.themeFormAppAndroid = qThemeEdit.recordcount GT 0 ? qThemeEdit.app_android[1] : (isDefined("FORM.app_android") ? FORM.app_android : "")/>
              <cfset VARIABLES.themeFormCorFundo = qThemeEdit.recordcount GT 0 ? qThemeEdit.cor_fundo[1] : (isDefined("FORM.cor_fundo") ? FORM.cor_fundo : "")/>
              <cfset VARIABLES.themeFormCorFonte = qThemeEdit.recordcount GT 0 ? qThemeEdit.cor_fonte[1] : (isDefined("FORM.cor_fonte") ? FORM.cor_fonte : "")/>
              <cfset VARIABLES.themeFormCorBotoes = qThemeEdit.recordcount GT 0 ? qThemeEdit.cor_botoes[1] : (isDefined("FORM.cor_botoes") ? FORM.cor_botoes : "")/>
              <cfset VARIABLES.themeFormBanner = qThemeEdit.recordcount GT 0 ? qThemeEdit.banner[1] : (isDefined("FORM.banner") ? FORM.banner : "")/>
              <cfset VARIABLES.themePreviewBg = len(trim(VARIABLES.themeFormCorFundo)) ? VARIABLES.themeFormCorFundo : "##222222"/>
              <cfset VARIABLES.themePreviewColor = len(trim(VARIABLES.themeFormCorFonte)) ? VARIABLES.themeFormCorFonte : "##ffffff"/>
              <cfset VARIABLES.themePreviewButton = len(trim(VARIABLES.themeFormCorBotoes)) ? VARIABLES.themeFormCorBotoes : "##f4b120"/>

              <div class="card shadow-0 border border-white border-opacity-10 mb-4">
                <div class="card-body">
                  <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                      <h5 class="mb-1"><cfif qThemeEdit.recordcount GT 0>Editar tema<cfelse>Novo tema</cfif></h5>
                      <p class="text-muted small mb-0">O campo logo deve conter o nome usado em <code>/assets/logos/{logo}.png</code>.</p>
                    </div>
                    <a class="btn btn-sm btn-outline-light" href="./">Fechar</a>
                  </div>

                  <hr/>

                  <form method="post" action="./" enctype="multipart/form-data">
                    <input type="hidden" name="acao" value="salvar_tema"/>
                    <input type="hidden" name="id_tema" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormId)#</cfoutput>"/>

                    <div class="row g-3">
                      <div class="col-lg-8">
                        <div class="row g-3">
                          <div class="col-md-3">
                            <label class="form-label">ID</label>
                            <input class="form-control" type="text" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormId)#</cfoutput>" disabled/>
                          </div>
                          <div class="col-md-5">
                            <label class="form-label">Logo</label>
                            <input class="form-control" type="text" name="logo" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormLogo)#</cfoutput>" placeholder="runnerhub"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Upload logo PNG</label>
                            <input class="form-control" type="file" name="logo_arquivo" accept=".png"/>
                          </div>

                          <div class="col-md-4">
                            <label class="form-label">Tag</label>
                            <input class="form-control" type="text" name="tag" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormTag)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Cor de fundo</label>
                            <input class="form-control" type="text" name="cor_fundo" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormCorFundo)#</cfoutput>" placeholder="##111111"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Cor da fonte</label>
                            <input class="form-control" type="text" name="cor_fonte" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormCorFonte)#</cfoutput>" placeholder="##ffffff"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Cor dos botoes</label>
                            <input class="form-control" type="text" name="cor_botoes" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormCorBotoes)#</cfoutput>" placeholder="##f4b120"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Website</label>
                            <input class="form-control" type="text" name="website" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormWebsite)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Instagram</label>
                            <input class="form-control" type="text" name="instagram" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormInstagram)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">YouTube</label>
                            <input class="form-control" type="text" name="youtube" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormYoutube)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">App iOS</label>
                            <input class="form-control" type="text" name="app_ios" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormAppIos)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">App Android</label>
                            <input class="form-control" type="text" name="app_android" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormAppAndroid)#</cfoutput>"/>
                          </div>
                          <div class="col-md-8">
                            <label class="form-label">Banner</label>
                            <input class="form-control" type="text" name="banner" value="<cfoutput>#htmlEditFormat(VARIABLES.themeFormBanner)#</cfoutput>"/>
                          </div>
                          <div class="col-md-4">
                            <label class="form-label">Upload banner</label>
                            <input class="form-control" type="file" name="banner_arquivo" accept=".jpg,.jpeg,.png,.gif"/>
                          </div>
                        </div>
                      </div>

                      <div class="col-lg-4">
                        <div class="theme-preview-card rounded p-3 h-100" style="<cfoutput>background:#htmlEditFormat(VARIABLES.themePreviewBg)#;color:#htmlEditFormat(VARIABLES.themePreviewColor)#;</cfoutput>">
                          <div class="small text-uppercase mb-3">Previa</div>
                          <cfif len(trim(VARIABLES.themeFormLogo))>
                            <cfoutput><img class="theme-logo-preview mb-3" src="/assets/logos/#htmlEditFormat(VARIABLES.themeFormLogo)#.png" onerror="this.style.display='none';"/></cfoutput>
                          </cfif>
                          <div class="h5 mb-2"><cfoutput>#htmlEditFormat(len(trim(VARIABLES.themeFormTag)) ? VARIABLES.themeFormTag : "Tema visual")#</cfoutput></div>
                          <p class="small mb-3">Cores e informacoes usadas nas paginas de agregadores.</p>
                          <button type="button" class="btn btn-sm" style="<cfoutput>background:#htmlEditFormat(VARIABLES.themePreviewButton)#;color:#htmlEditFormat(VARIABLES.themePreviewColor)#;</cfoutput>">Botao do tema</button>
                        </div>
                      </div>

                      <div class="col-12 text-end">
                        <button type="submit" class="btn btn-warning">Salvar tema</button>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover themes-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Tema</th>
                    <th>Cores</th>
                    <th>Links</th>
                    <th class="text-end">Uso</th>
                    <th class="theme-actions text-end">Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  <cfoutput query="qThemesList">
                    <tr>
                      <td class="text-nowrap">#qThemesList.id_tema#</td>
                      <td>
                        <div class="d-flex align-items-center gap-3">
                          <cfif len(trim(qThemesList.logo))>
                            <img class="theme-logo-preview" src="/assets/logos/#htmlEditFormat(qThemesList.logo)#.png" onerror="this.src='/assets/logos/runnerhub.png';"/>
                          <cfelse>
                            <div class="badge bg-secondary">sem logo</div>
                          </cfif>
                          <div>
                            <div class="fw-semibold">#htmlEditFormat(len(trim(qThemesList.tag)) ? qThemesList.tag : qThemesList.logo)#</div>
                            <div class="small text-muted">logo: #htmlEditFormat(qThemesList.logo)#</div>
                            <cfif len(trim(qThemesList.banner))><div class="small text-muted">banner: #htmlEditFormat(qThemesList.banner)#</div></cfif>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div class="small mb-1"><span class="theme-color-chip" style="background:#htmlEditFormat(qThemesList.cor_fundo)#"></span> Fundo: #htmlEditFormat(qThemesList.cor_fundo)#</div>
                        <div class="small mb-1"><span class="theme-color-chip" style="background:#htmlEditFormat(qThemesList.cor_fonte)#"></span> Fonte: #htmlEditFormat(qThemesList.cor_fonte)#</div>
                        <div class="small"><span class="theme-color-chip" style="background:#htmlEditFormat(qThemesList.cor_botoes)#"></span> Botoes: #htmlEditFormat(qThemesList.cor_botoes)#</div>
                      </td>
                      <td class="small">
                        <cfif len(trim(qThemesList.website))><div><a href="#htmlEditFormat(qThemesList.website)#" target="_blank" rel="noopener">Website</a></div></cfif>
                        <cfif len(trim(qThemesList.instagram))><div><a href="#htmlEditFormat(qThemesList.instagram)#" target="_blank" rel="noopener">Instagram</a></div></cfif>
                        <cfif len(trim(qThemesList.youtube))><div><a href="#htmlEditFormat(qThemesList.youtube)#" target="_blank" rel="noopener">YouTube</a></div></cfif>
                        <cfif len(trim(qThemesList.app_ios))><div><a href="#htmlEditFormat(qThemesList.app_ios)#" target="_blank" rel="noopener">iOS</a></div></cfif>
                        <cfif len(trim(qThemesList.app_android))><div><a href="#htmlEditFormat(qThemesList.app_android)#" target="_blank" rel="noopener">Android</a></div></cfif>
                      </td>
                      <td class="text-end small">
                        <div>#qThemesList.total_eventos# eventos</div>
                        <div>#qThemesList.total_agregadores# agregadores</div>
                      </td>
                      <td class="text-end">
                        <a class="btn btn-sm btn-outline-primary" href="./?tema_id=#qThemesList.id_tema#"><i class="fa-solid fa-pen-to-square"></i></a>
                      </td>
                    </tr>
                  </cfoutput>
                </tbody>
              </table>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
