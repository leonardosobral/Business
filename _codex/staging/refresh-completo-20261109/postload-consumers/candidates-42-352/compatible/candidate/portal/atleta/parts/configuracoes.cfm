<!--- CONFIGURACOES --->
<cfparam name="VARIABLES.profileSettingsSection" default="perfil"/>
<cfparam name="VARIABLES.profileSettingsRouteKey" default="profileSettings"/>
<cfset VARIABLES.settingsProfilePath = REQUEST.i18nBuildPath(VARIABLES.profileSettingsRouteKey)/>
<cfset VARIABLES.settingsAthletePrefix = REQUEST.lang EQ "en" ? "/athlete" : "/atleta"/>
<cfset VARIABLES.locationSavedCountry = len(trim(qMeuPerfil.pais)) ? uCase(trim(qMeuPerfil.pais)) : ""/>
<cfif VARIABLES.locationSavedCountry EQ "BR">
    <cfset VARIABLES.locationSavedRegion = len(trim(qMeuPerfil.uf)) ? trim(qMeuPerfil.uf) : trim(qMeuPerfil.estado)/>
<cfelse>
    <cfset VARIABLES.locationSavedRegion = len(trim(qMeuPerfil.estado)) ? trim(qMeuPerfil.estado) : trim(qMeuPerfil.uf)/>
</cfif>
<cfset VARIABLES.locationSuggestedCountry = structKeyExists(REQUEST, "LocationContext") AND isStruct(REQUEST.LocationContext) ? uCase(trim(REQUEST.LocationContext.pais ?: "")) : ""/>
<cfset VARIABLES.locationSuggestedRegion = ""/>
<cfif structKeyExists(REQUEST, "LocationContext") AND isStruct(REQUEST.LocationContext)>
    <cfif VARIABLES.locationSuggestedCountry EQ "BR" AND len(trim(REQUEST.LocationContext.uf ?: ""))>
        <cfset VARIABLES.locationSuggestedRegion = uCase(trim(REQUEST.LocationContext.uf))/>
    <cfelse>
        <cfset VARIABLES.locationSuggestedRegion = trim(REQUEST.LocationContext.estado ?: "")/>
    </cfif>
</cfif>
<cfset VARIABLES.locationSuggestedPrefix = REQUEST.lang EQ "en" ? "Suggested" : "Sugerido"/>
<cfset VARIABLES.locationRegionInputPlaceholder = REQUEST.lang EQ "en" ? "Type your state, province or region" : (REQUEST.lang EQ "es" ? "Escribe tu estado, provincia o region" : "Digite seu estado, província ou região")/>
<cfset VARIABLES.locationRegionSelectPlaceholder = REQUEST.lang EQ "en" ? "Select state or province" : (REQUEST.lang EQ "es" ? "Selecciona estado o provincia" : "Selecione estado ou província")/>
<cfset VARIABLES.locationCountryPlaceholder = REQUEST.lang EQ "en" ? "Select country" : (REQUEST.lang EQ "es" ? "Selecciona pais" : "Selecione país")/>
<cfset VARIABLES.canManageApiDeveloperToken = Usuario.logado AND (BooleanFormat(qMeuPerfil.is_admin) OR BooleanFormat(qMeuPerfil.is_dev) OR BooleanFormat(qMeuPerfil.is_partner))/>

<div class="row g-4">

    <cfif VARIABLES.profileSettingsSection EQ "perfil">
    <!--- MEU PERFIL --->

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.profileTitle")#</cfoutput></div>
        <a id="perfil" class="mt-n100"></a>

        <div class="card p-2">

            <form class="needs-validation mt-0"
                  novalidate
                  method="post"
                  action="<cfoutput>#VARIABLES.settingsProfilePath#</cfoutput>#perfil"
                  data-athlete-location-form
                  data-saved-country="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSavedCountry)#</cfoutput>"
                  data-saved-region="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSavedRegion)#</cfoutput>"
                  data-suggested-country="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSuggestedCountry)#</cfoutput>"
                  data-suggested-region="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSuggestedRegion)#</cfoutput>"
                  data-country-placeholder="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationCountryPlaceholder)#</cfoutput>"
                  data-region-select-placeholder="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationRegionSelectPlaceholder)#</cfoutput>"
                  data-region-input-placeholder="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationRegionInputPlaceholder)#</cfoutput>"
                  data-suggested-prefix="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSuggestedPrefix)#</cfoutput>">

                <div class="row g-2">
                    <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>

                    <div class="col-12">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputNome" maxlength="128" name="nome"
                                value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.nome & "")#</cfoutput>" onblur="getTag()" required/>
                            <label for="inputNome" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.profileName")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="form-outline" data-mdb-input-init>
                                <input type="text" class="form-control disabled" id="inputID" maxlength="6" name="id" disabled value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.id & "")#</cfoutput>" onblur="getTag()" required/>
                            <label for="inputID" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.accountId")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="form-outline" data-mdb-input-init>
                                <input type="text" class="form-control disabled" id="inputMail" maxlength="6" name="id" disabled value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.email & "")#</cfoutput>" onblur="getTag()" required/>
                            <label for="inputMail" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.googleEmail")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="form-outline">
                            <select id="inputTagPrefix" name="tag_prefix" class="form-select" data-mdb-select-init data-mdb-placeholder="<cfoutput>#REQUEST.t('athlete.settings.statePlaceholder')#</cfoutput>" required readonly="true">
                                <option value="atleta"><cfoutput>#VARIABLES.settingsAthletePrefix#</cfoutput></option>
                                <!---option value="canal">/canal</option>
                                <option value="clube">/clube</option>
                                <option value="perfil">/perfil</option--->
                            </select>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="input-group form-outline" data-mdb-input-init>
                          <span class="input-group-text" id="inputGroupPrepend">@</span>
                          <input type="text" class="form-control <cfif isDefined("URL.status") AND URL.status EQ "tag-taken">is-invalid</cfif>" id="inputTag" maxlength="128" name="tag"
                                 aria-describedby="inputGroupPrepend"
                                 value="<cfif isDefined("URL.status") AND URL.status EQ "tag-taken" AND isDefined("URL.tag_value")><cfoutput>#encodeForHTMLAttribute(URL.tag_value)#</cfoutput><cfelse><cfoutput>#encodeForHTMLAttribute(qMeuPerfil.tag)#</cfoutput></cfif>"
                                 onblur="getTag(this.value)" required />
                          <label for="inputTag" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.username")#</cfoutput></label>
                          <div class="invalid-feedback"><cfoutput>#REQUEST.t("athlete.settings.usernameInvalid")#</cfoutput></div>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputCidade" maxlength="128" name="cidade" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.cidade & "")#</cfoutput>" required/>
                            <label for="inputCidade" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.city")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-12 col-md-6">
                        <div class="form-outline">
                            <input type="hidden" name="uf" data-location-region-hidden value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.locationSavedRegion)#</cfoutput>"/>
                            <div data-location-region-select-wrapper>
                                <select id="inputUFSelect" class="form-select" data-location-region-select></select>
                            </div>
                            <div class="form-outline" data-mdb-input-init data-location-region-input-wrapper style="display:none;">
                                <input type="text" class="form-control" id="inputUFText" maxlength="128" data-location-region-input />
                                <label for="inputUFText" class="form-label"><cfoutput>#REQUEST.t("athlete.settings.statePlaceholder")#</cfoutput></label>
                            </div>
                        </div>
                    </div>

                    <div class="col-12 col-md-6">
                        <div class="form-outline">
                            <select id="inputPais" class="form-select" name="pais" data-location-country-select required>
                                <option value="<cfoutput>#encodeForHTMLAttribute(len(VARIABLES.locationSavedCountry) ? VARIABLES.locationSavedCountry : "BR")#</cfoutput>"><cfoutput>#len(VARIABLES.locationSavedCountry) ? VARIABLES.locationSavedCountry : REQUEST.t("athlete.settings.countryBrazil")#</cfoutput></option>
                            </select>
                        </div>
                    </div>

                    <div class="col-12">
                        <div class="form-outline" data-mdb-input-init>
                          <textarea class="form-control" name="descricao" id="inputDescricao" maxlength="150" rows="2"><cfoutput>#encodeForHTML(qMeuPerfil.descricao & "")#</cfoutput></textarea>
                          <label class="form-label" for="inputDescricao"><cfoutput>#REQUEST.t("athlete.settings.bio")#</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-12">
                        <input type="hidden" name="action" value="editar_configuracoes"/>
                        <button type="submit" class="btn btn-secondary w-100" data-mdb-ripple-init><cfoutput>#REQUEST.t("athlete.settings.saveProfile")#</cfoutput></button>
                    </div>

                </div>

            </form>

        </div>

    </div>

    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "integracoes">
    <!--- INTEGRAÇÕES --->

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.integrationsTitle")#</cfoutput></div>
        <a id="integracoes" class="mt-n100"></a>

        <div class="card p-2 gap-2">

            <cfset VARIABLES.vickyWhatsappLabels = REQUEST.lang EQ "en"
                ? {
                    title="Vicky on WhatsApp",
                    connected="Connected WhatsApp",
                    connectedCopy="This number can ask Vicky for information from your authenticated Road Runners account.",
                    disconnect="Disconnect WhatsApp",
                    noConnection="No WhatsApp is connected to Vicky.",
                    active="Active",
                    confirmDisconnect="Disconnect this WhatsApp from your Road Runners account?",
                    disconnected="WhatsApp disconnected successfully.",
                    unavailable="WhatsApp connection management is temporarily unavailable."
                }
                : (REQUEST.lang EQ "es"
                    ? {
                        title="Vicky en WhatsApp",
                        connected="WhatsApp conectado",
                        connectedCopy="Este número puede consultar con Vicky información de tu cuenta autenticada de Road Runners.",
                        disconnect="Desconectar WhatsApp",
                        noConnection="No hay ningún WhatsApp conectado a Vicky.",
                        active="Activo",
                        confirmDisconnect="¿Desconectar este WhatsApp de tu cuenta de Road Runners?",
                        disconnected="WhatsApp desconectado correctamente.",
                        unavailable="La gestión de la conexión de WhatsApp no está disponible temporalmente."
                    }
                    : {
                        title="Vicky no WhatsApp",
                        connected="WhatsApp conectado",
                        connectedCopy="Este número pode consultar com a Vicky informações da sua conta autenticada do Road Runners.",
                        disconnect="Desconectar WhatsApp",
                        noConnection="Nenhum WhatsApp conectado à Vicky.",
                        active="Ativo",
                        confirmDisconnect="Desconectar este WhatsApp da sua conta do Road Runners?",
                        disconnected="WhatsApp desconectado com sucesso.",
                        unavailable="O gerenciamento da conexão do WhatsApp está temporariamente indisponível."
                    })/>

            <cfset VARIABLES.vickyInstagramLabels = REQUEST.lang EQ "en"
                ? {
                    title="Vicky on Instagram",
                    connected="Connected Instagram",
                    connectedCopy="This Instagram account can ask Vicky for information from your authenticated Road Runners account.",
                    disconnect="Disconnect Instagram",
                    noConnection="No Instagram account is connected to Vicky.",
                    active="Active",
                    confirmDisconnect="Disconnect this Instagram account from your Road Runners account?",
                    disconnected="Instagram disconnected successfully.",
                    unavailable="Instagram connection management is temporarily unavailable."
                }
                : (REQUEST.lang EQ "es"
                    ? {
                        title="Vicky en Instagram",
                        connected="Instagram conectado",
                        connectedCopy="Esta cuenta de Instagram puede consultar con Vicky información de tu cuenta autenticada de Road Runners.",
                        disconnect="Desconectar Instagram",
                        noConnection="No hay ninguna cuenta de Instagram conectada a Vicky.",
                        active="Activo",
                        confirmDisconnect="¿Desconectar esta cuenta de Instagram de tu cuenta de Road Runners?",
                        disconnected="Instagram desconectado correctamente.",
                        unavailable="La gestión de la conexión de Instagram no está disponible temporalmente."
                    }
                    : {
                        title="Vicky no Instagram",
                        connected="Instagram conectado",
                        connectedCopy="Esta conta do Instagram pode consultar com a Vicky informações da sua conta autenticada do Road Runners.",
                        disconnect="Desconectar Instagram",
                        noConnection="Nenhuma conta do Instagram conectada à Vicky.",
                        active="Ativo",
                        confirmDisconnect="Desconectar esta conta do Instagram da sua conta do Road Runners?",
                        disconnected="Instagram desconectado com sucesso.",
                        unavailable="O gerenciamento da conexão do Instagram está temporariamente indisponível."
                    })/>

            <cfif VARIABLES.profileSettingsStatus EQ "whatsapp-disconnected">
                <div class="alert alert-success py-2 px-3 mb-0 small"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.disconnected)#</cfoutput></div>
            </cfif>

            <div class="border rounded-3 p-3">
                <div class="d-flex align-items-start justify-content-between gap-3">
                    <div>
                        <div class="fw-bold"><i class="fa-brands fa-whatsapp text-success me-2" aria-hidden="true"></i><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.title)#</cfoutput></div>
                        <cfif VARIABLES.profileSettingsVickyWhatsappSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyWhatsappLinks)>
                            <cfset VARIABLES.vickyWhatsappLink = VARIABLES.profileSettingsVickyWhatsappLinks[1]/>
                            <div class="small mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.connected)# · final #encodeForHTML(VARIABLES.vickyWhatsappLink.contact_suffix & "")#</cfoutput></div>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.connectedCopy)#</cfoutput></div>
                        <cfelseif NOT VARIABLES.profileSettingsVickyWhatsappSchemaReady>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.unavailable)#</cfoutput></div>
                        <cfelse>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.noConnection)#</cfoutput></div>
                        </cfif>
                    </div>
                    <cfif VARIABLES.profileSettingsVickyWhatsappSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyWhatsappLinks)>
                        <span class="badge text-bg-success"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.active)#</cfoutput></span>
                    </cfif>
                </div>
                <cfif VARIABLES.profileSettingsVickyWhatsappSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyWhatsappLinks)>
                    <form method="post" action="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPath)#</cfoutput>" class="mt-3" onsubmit="return confirm('<cfoutput>#encodeForJavaScript(VARIABLES.vickyWhatsappLabels.confirmDisconnect)#</cfoutput>');">
                        <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>
                        <input type="hidden" name="action" value="gerenciar_integracoes"/>
                        <input type="hidden" name="integration_operation" value="disconnect_vicky_whatsapp"/>
                        <button type="submit" class="btn btn-outline-danger btn-sm w-100"><cfoutput>#encodeForHTML(VARIABLES.vickyWhatsappLabels.disconnect)#</cfoutput></button>
                    </form>
                </cfif>
            </div>

            <cfif VARIABLES.profileSettingsStatus EQ "instagram-disconnected">
                <div class="alert alert-success py-2 px-3 mb-0 small"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.disconnected)#</cfoutput></div>
            </cfif>

            <div class="border rounded-3 p-3">
                <div class="d-flex align-items-start justify-content-between gap-3">
                    <div>
                        <div class="fw-bold"><i class="fa-brands fa-instagram me-2" aria-hidden="true"></i><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.title)#</cfoutput></div>
                        <cfif VARIABLES.profileSettingsVickyInstagramSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyInstagramLinks)>
                            <cfset VARIABLES.vickyInstagramLink = VARIABLES.profileSettingsVickyInstagramLinks[1]/>
                            <div class="small mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.connected)# · ID final #encodeForHTML(VARIABLES.vickyInstagramLink.contact_suffix & "")#</cfoutput></div>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.connectedCopy)#</cfoutput></div>
                        <cfelseif NOT VARIABLES.profileSettingsVickyInstagramSchemaReady>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.unavailable)#</cfoutput></div>
                        <cfelse>
                            <div class="small text-muted mt-1"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.noConnection)#</cfoutput></div>
                        </cfif>
                    </div>
                    <cfif VARIABLES.profileSettingsVickyInstagramSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyInstagramLinks)>
                        <span class="badge text-bg-success"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.active)#</cfoutput></span>
                    </cfif>
                </div>
                <cfif VARIABLES.profileSettingsVickyInstagramSchemaReady AND arrayLen(VARIABLES.profileSettingsVickyInstagramLinks)>
                    <form method="post" action="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPath)#</cfoutput>" class="mt-3" onsubmit="return confirm('<cfoutput>#encodeForJavaScript(VARIABLES.vickyInstagramLabels.confirmDisconnect)#</cfoutput>');">
                        <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>
                        <input type="hidden" name="action" value="gerenciar_integracoes"/>
                        <input type="hidden" name="integration_operation" value="disconnect_vicky_instagram"/>
                        <button type="submit" class="btn btn-outline-danger btn-sm w-100"><cfoutput>#encodeForHTML(VARIABLES.vickyInstagramLabels.disconnect)#</cfoutput></button>
                    </form>
                </cfif>
            </div>

            <!--- STRAVA --->
            <a style="width:100%;text-align: center;display:inline-block;background-color:#76a7fa;color:#fff;padding:6px 10px 6px 30px;font-size:12px;font-family:Helvetica, Arial, sans-serif;white-space:nowrap;text-decoration:none;background-repeat:no-repeat;background-position:10px center;border-radius:3px;background-image:url('/assets/white-google-logo.png'); background-size: 18px;" href='https://myaccount.google.com/' target="_blank">
                <cfoutput>#REQUEST.t("athlete.settings.connectedGoogle")#</cfoutput>
            </a>
            <cfif len(trim(qMeuPerfil.strava_id))>
                    <a style="width:100%;text-align: center;display:inline-block;background-color:#FC5200;color:#fff;padding:6px 10px 6px 30px;font-size:12px;font-family:Helvetica, Arial, sans-serif;white-space:nowrap;text-decoration:none;background-repeat:no-repeat;background-position:12px center;border-radius:3px;background-image:url('/assets/strava_mark_mono.svg');background-size: 12px;" href="https://strava.com/athletes/<cfoutput>#encodeForURL(qMeuPerfil.strava_id & "")#</cfoutput>" target="_blank" rel="noopener noreferrer">
                    <cfoutput>#REQUEST.t("athlete.settings.connectedStrava")#</cfoutput> <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160.68 31.87" style='margin-left:2px;vertical-align:text-bottom' height="13" width="51"><defs><style>.strava{fill:#FFFFFF;fill-rule:evenodd;}</style></defs><title>strava</title><g id="Camada_2" data-name="Camada 2"><g id="Camada_1-2" data-name="Camada 1"><path id="Fill-1" class="strava" d="M15.39,30.62a29.74,29.74,0,0,1-8.55-1.19A19.23,19.23,0,0,1,0,25.85l5.36-6a16.25,16.25,0,0,0,5.14,2.55,19.63,19.63,0,0,0,5.37.77,4.51,4.51,0,0,0,2-.32,1,1,0,0,0,.6-.89v-.08c0-.41-.3-.75-.88-1A15.61,15.61,0,0,0,14.28,20q-2.53-.49-4.83-1.14a17.06,17.06,0,0,1-4-1.66,8.17,8.17,0,0,1-2.76-2.55,6.57,6.57,0,0,1-1-3.76V10.8A8.45,8.45,0,0,1,4.91,4a11.89,11.89,0,0,1,4-2,18.83,18.83,0,0,1,5.47-.72,27,27,0,0,1,7.65,1,18.7,18.7,0,0,1,5.9,2.91L23,11.52A15.32,15.32,0,0,0,18.5,9.4,16.45,16.45,0,0,0,14,8.73a3.36,3.36,0,0,0-1.65.32,1,1,0,0,0-.53.85V10c0,.38.26.71.81,1a14.53,14.53,0,0,0,3.17.85A45.56,45.56,0,0,1,21.06,13a15.74,15.74,0,0,1,4.05,1.76,7.92,7.92,0,0,1,2.61,2.57A6.77,6.77,0,0,1,28.65,21V21a8.45,8.45,0,0,1-.95,4,8.59,8.59,0,0,1-2.66,3A12.77,12.77,0,0,1,20.88,30a20.64,20.64,0,0,1-5.49.67"/><path id="Fill-2" class="strava" d="M36.92,9.78H28.09v-8h27.7v8H47V30.09h-10V9.78"/><path id="Fill-3" class="strava" d="M57.2,1.78H71.87a21.22,21.22,0,0,1,6.63.87A11.14,11.14,0,0,1,82.68,5a8.62,8.62,0,0,1,2.06,2.91,9.84,9.84,0,0,1,.69,3.8v.09a8.6,8.6,0,0,1-1.59,5.26,10.88,10.88,0,0,1-4.34,3.4l7,9.62H75.05L69.38,22H67.24v8.09h-10V1.78ZM71.57,15.25a4.78,4.78,0,0,0,2.83-.73,2.34,2.34,0,0,0,1-2v-.08a2.26,2.26,0,0,0-1-2,5.08,5.08,0,0,0-2.78-.66H67.24v5.54Z"/><path id="Fill-4" class="strava" d="M144.52,17.91l6.55,12.18h9.61L144.52,0,128.37,30.09H138l6.53-12.18"/><path id="Fill-5" class="strava" d="M99.56,17.91l6.54,12.18h9.61L99.56,0,83.41,30.09H93l6.54-12.18"/><path id="Fill-6" class="strava" d="M122.05,14,115.5,1.78h-9.61l16.16,30.09L138.2,1.78h-9.61L122.05,14"/></g></g></svg>
                </a>
            <cfelse>
                    <a href="https://www.strava.com/oauth/authorize?client_id=110999&response_type=code&redirect_uri=<cfoutput>#urlEncodedFormat(APPLICATION.baseCanonica & VARIABLES.settingsProfilePath)#</cfoutput>&approval_prompt=force&scope=read,activity:read,profile:read_all"><button style="width:100%;text-align: center;display:inline-block;background-color:#666;color:#fff;padding:6px 10px 6px 30px;font-size:12px;font-family:Helvetica, Arial, sans-serif;white-space:nowrap;text-decoration:none;background-repeat:no-repeat;background-position:10px center;border-radius:3px;background-image:url('https://badges.strava.com/logo-strava-echelon.png');border-width: 0;"><cfoutput>#REQUEST.t("athlete.settings.connectStrava")#</cfoutput></button></a>
            </cfif>
            <cfif Usuario.logado AND BooleanFormat(qMeuPerfil.is_admin)>
                <!---<a style="width:100%;text-align: center;display:inline-block;background-color:#f9f100;color:#000;padding:6px 10px 6px 30px;font-size:12px;font-family:Helvetica, Arial, sans-serif;white-space:nowrap;text-decoration:none;background-repeat:no-repeat;background-position:10px center;border-radius:3px;background-image:url('/assets/icons/focoradical.svg'); background-size: 18px;" href='https://www.focoradical.com.br/site/login' target="_blank" class="">
                    Conectar à Foco Radical
                </a>--->
                <a class="disabled opacity-50" disabled style="width:100%;text-align: center;display:inline-block;background-color:#feee01;color:#000000;padding:6px 10px 6px 30px;font-size:12px;font-family:Helvetica, Arial, sans-serif;white-space:nowrap;text-decoration:none;background-repeat:no-repeat;background-position:10px center;border-radius:3px;background-image:url('/assets/icons/focoradical.svg'); background-size: 18px; cursor: pointer;filter: grayscale(100)">
                    <cfoutput>#REQUEST.t("athlete.settings.connectFocoRadical")#</cfoutput>
                </a>
            </cfif>

            <cfif VARIABLES.canManageApiDeveloperToken>
                <div
                    class="border rounded-3 p-3 mt-2"
                    data-api-token-panel
                    data-api-token-csrf="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>">
                    <div class="d-flex align-items-start justify-content-between gap-2">
                        <div>
                            <div class="fw-bold">Road Runners API</div>
                            <div class="small text-muted">Use um Bearer token em todas as chamadas da API.</div>
                        </div>
                        <i class="fa-solid fa-key text-muted mt-1"></i>
                    </div>

                    <div class="small mt-2" data-api-token-status>Carregando token...</div>

                    <div class="input-group input-group-sm mt-2 d-none" data-api-token-value-wrapper>
                        <input type="text" class="form-control" readonly data-api-token-value/>
                        <button type="button" class="btn btn-outline-secondary" data-api-token-copy>Copiar</button>
                    </div>

                    <div class="d-grid gap-2 mt-2">
                        <button type="button" class="btn btn-outline-secondary btn-sm" data-api-token-generate>Gerar ou rotacionar token</button>
                        <button type="button" class="btn btn-outline-danger btn-sm" data-api-token-revoke>Revogar token</button>
                    </div>

                    <div class="small text-muted mt-2">O token completo aparece apenas uma vez. Depois, o perfil mostra só o prefixo e o último uso.</div>
                </div>
            </cfif>

            <!---

            <!-- Power-Up 1 -->
            <div class="form-check form-switch small lh-1 myz-4">
                <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchCheckDefault" checked />
                <label class="form-check-label px-2" for="flexSwitchCheckDefault">Power-Up 1</label>
            </div>

            <!-- Power-Up 2 -->
            <div class="form-check form-switch small lh-1 my-4">
                <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchCheckDefault" />
                <label class="form-check-label px-2" for="flexSwitchCheckDefault">Power-Up 2</label>
            </div>

            <!-- Power-Up 3 -->
            <div class="form-check form-switch small lh-1 my-4">
                <input class="form-check-input" type="checkbox" role="switch" id="flexSwitchCheckDefault" />
                <label class="form-check-label px-2" for="flexSwitchCheckDefault">Power-Up 3</label>
            </div>

            --->

        </div>

    </div>

    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "links">
    <!--- MEUS LINKS --->

    <style>
        .btn-visibility:has(.form-check-input[type=checkbox]):before {
            content: "\f070";
            color: #cccccc;
            cursor: pointer;
        }
        .btn-visibility:has(.form-check-input[type=checkbox]:checked):before {
            content: "\f06e";
            color: #666666;
        }
    </style>

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.linksTitle")#</cfoutput></div>
        <a id="links" class="mt-n100"></a>

        <div class="card p-2">

            <form class="needs-validation mt-0" novalidate method="post" action="<cfoutput>#VARIABLES.settingsProfilePath#</cfoutput>#links">

                <div class="row g-2">
                    <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>

                    <cfif VARIABLES.profileSettingsStravaConnected AND VARIABLES.profileSettingsStravaId GT 0>
                        <div class="col-10">
                            <div class="form-outline" data-mdb-input-init>
                                <input type="url"
                                       class="form-control"
                                       id="inputStrava"
                                       value="https://www.strava.com/athletes/<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsStravaId)#</cfoutput>"
                                       readonly
                                       aria-readonly="true"/>
                                <label for="inputStrava" class="form-label"><i class="fa-brands fa-strava"></i> <cfoutput>#REQUEST.t("athlete.social.strava")#:</cfoutput></label>
                            </div>
                        </div>

                        <div class="col-2 align-content-center">
                            <div class="form-outline" data-mdb-input-init>
                                <div class="text-center small">
                                    <label class="btn-visibility fa-solid fs-4" for="strava_publico">
                                        <input class="form-check-input d-none" type="checkbox" name="strava_publico" id="strava_publico" <cfif VARIABLES.profileSettingsStravaPublic>checked</cfif>>
                                    </label>
                                </div>
                            </div>
                        </div>
                    <cfelse>
                        <div class="col-12">
                            <a class="btn btn-sm w-100 text-white shadow-0"
                               style="background-color: #FC5200;"
                               href="https://www.strava.com/oauth/authorize?client_id=110999&response_type=code&redirect_uri=<cfoutput>#urlEncodedFormat(APPLICATION.baseCanonica & VARIABLES.settingsProfilePath)#</cfoutput>&approval_prompt=force&scope=read,activity:read,profile:read_all">
                                <i class="fa-brands fa-strava me-2" aria-hidden="true"></i><cfoutput>#REQUEST.t("athlete.settings.connectStrava")#</cfoutput>
                            </a>
                        </div>
                    </cfif>

                    <!---<div class="col-10">
                    </div>

                    <div class="col-2 text-center small">
                        <small>Visibilidade</small>
                    </div>--->

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputInstagram" maxlength="128" name="instagram" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.instagramPlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.instagram & "")#</cfoutput>"/>
                            <label for="inputInstagram" class="form-label"><i class="fa-brands fa-instagram"></i> <cfoutput>#REQUEST.t("athlete.settings.instagram")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="instagram_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="instagram_publico" id="instagram_publico" <cfif qMeuPerfil.instagram_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputYoutube" maxlength="128" name="youtube" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.youtubePlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.youtube & "")#</cfoutput>"/>
                            <label for="inputYoutube" class="form-label"><i class="fa-brands fa-youtube"></i> <cfoutput>#REQUEST.t("athlete.settings.youtube")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="youtube_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="youtube_publico" id="youtube_publico" <cfif qMeuPerfil.youtube_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputTiktok" maxlength="128" name="tiktok" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.tiktokPlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.tiktok & "")#</cfoutput>"/>
                            <label for="inputTiktok" class="form-label"><i class="fa-brands fa-tiktok"></i> <cfoutput>#REQUEST.t("athlete.settings.tiktok")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="tiktok_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="tiktok_publico" id="tiktok_publico" <cfif qMeuPerfil.tiktok_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputWebsite" maxlength="128" name="website" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.urlPlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.website & "")#</cfoutput>"/>
                            <label for="inputWebsite" class="form-label"><i class="fa-solid fa-globe"></i> <cfoutput>#REQUEST.t("athlete.social.website")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="website_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="website_publico" id="website_publico" <cfif qMeuPerfil.website_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputLoja" maxlength="128" name="loja" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.urlPlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.loja & "")#</cfoutput>"/>
                            <label for="inputLoja" class="form-label"><i class="fa-solid fa-bag-shopping"></i> <cfoutput>#REQUEST.t("athlete.settings.onlineStore")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="loja_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="loja_publico" id="loja_publico" <cfif qMeuPerfil.loja_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-10">
                        <div class="form-outline" data-mdb-input-init>
                            <input type="text" class="form-control" id="inputWhatsapp" maxlength="128" name="whatsapp" placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.whatsappPlaceholder'))#</cfoutput>" value="<cfoutput>#encodeForHTMLAttribute(qMeuPerfil.whatsapp & "")#</cfoutput>"/>
                            <label for="inputWhatsapp" class="form-label"><i class="fa-brands fa-whatsapp"></i> <cfoutput>#REQUEST.t("athlete.settings.whatsapp")#:</cfoutput></label>
                        </div>
                    </div>

                    <div class="col-2 align-content-center">
                        <div class="form-outline" data-mdb-input-init>
                            <div class="text-center small">
                                <label class="btn-visibility fa-solid fs-4" for="whatsapp_publico">
                                    <input class="form-check-input d-none" type="checkbox" name="whatsapp_publico" id="whatsapp_publico" <cfif qMeuPerfil.whatsapp_publico>checked</cfif>>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-12">
                        <input type="hidden" name="action" value="editar_redes_sociais"/>
                        <button type="submit" class="btn btn-secondary w-100" data-mdb-ripple-init><cfoutput>#REQUEST.t("athlete.settings.saveLinks")#</cfoutput></button>
                    </div>

                </div>

            </form>

        </div>

    </div>

    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "privacidade">
    <!--- PRIVACIDADE --->

    <style>
        .profile-privacy-toggle {
            align-items: center;
            background: #f5f5f5;
            border: 1px solid #dedede;
            border-radius: 50%;
            color: #666666;
            cursor: pointer;
            display: inline-flex;
            height: 2.5rem;
            justify-content: center;
            transition: background-color 0.15s ease, border-color 0.15s ease, color 0.15s ease;
            width: 2.5rem;
        }

        .profile-privacy-toggle:hover {
            background: #eeeeee;
            border-color: #cccccc;
            color: #333333;
        }

        .profile-privacy-toggle .profile-privacy-icon-public {
            display: none;
        }

        .profile-privacy-toggle input:checked ~ .profile-privacy-icon-followers {
            display: none;
        }

        .profile-privacy-toggle input:checked ~ .profile-privacy-icon-public {
            display: inline-block;
        }

        .profile-privacy-toggle input:focus-visible ~ i {
            outline: 2px solid #fab120;
            outline-offset: 6px;
            border-radius: 50%;
        }
    </style>

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.privacyTitle")#</cfoutput></div>
        <a id="privacidade" class="mt-n100"></a>

        <div class="card p-2">

            <form class="needs-validation mt-0" novalidate method="post" action="<cfoutput>#VARIABLES.settingsProfilePath#</cfoutput>#privacidade">
                <div class="row g-2">
                    <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>

                    <div class="col-10 small p-2 border-end">
                        <i class="fa-solid fa-globe"></i> <strong><cfoutput>#REQUEST.t("athlete.settings.privacyPublicTitle")#:</cfoutput></strong> <cfoutput>#REQUEST.t("athlete.settings.privacyPublicText")#</cfoutput>
                        <br><br>
                        <i class="fa-solid fa-users"></i> <strong><cfoutput>#REQUEST.t("athlete.settings.privacyFollowersTitle")#:</cfoutput></strong> <cfoutput>#REQUEST.t("athlete.settings.privacyFollowersText")#</cfoutput>
                    </div>

                    <div class="col-2 d-flex align-items-center justify-content-center">
                        <div class="text-center small">
                            <label class="profile-privacy-toggle fs-4" for="perfil_fechado" title="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.privacyTitle'))#</cfoutput>">
                                <input class="visually-hidden" type="checkbox" role="switch" name="perfil_publico" id="perfil_fechado" <cfif qMeuPerfil.perfil_publico>checked</cfif>>
                                <i class="fa-solid fa-users profile-privacy-icon-followers" aria-hidden="true"></i>
                                <i class="fa-solid fa-globe profile-privacy-icon-public" aria-hidden="true"></i>
                                <span class="visually-hidden"><cfoutput>#REQUEST.t("athlete.settings.privacyTitle")#</cfoutput></span>
                            </label>
                        </div>
                    </div>

                    <div class="col-12">

                    </div>

                    <div class="col-12">
                        <input type="hidden" name="action" value="editar_privacidade"/>
                        <button type="submit" class="btn btn-secondary w-100" data-mdb-ripple-init><cfoutput>#REQUEST.t("athlete.settings.savePrivacy")#</cfoutput></button>
                    </div>

                </div>
            </form>

        </div>

    </div>

    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "privacidade">
    <!--- REMOÇÃO DE CONTA --->

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.accountRemovalTitle")#</cfoutput></div>

        <div class="card p-2">

            <div class="needs-validation mt-0">
                <div class="row g-2">
                    <div class="col text-center small">

                        <!---SOLICITAR--->
                        <div class="p-2">
                            <cfoutput>#REQUEST.t("athlete.settings.removeWarning")#</cfoutput>
                        </div>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('support')#</cfoutput>" class="btn btn-danger w-100 shadow-0"><cfoutput>#REQUEST.t("athlete.settings.removeAccount")#</cfoutput></a>

                        <!---EM ANALISE--->
                        <!---<b>Aviso:</b> Por questões de segurança, sua solicitação está em análise e será atendida em até 48 horas.--->
                        <!---<button type="submit" class="btn btn-warning w-100 shadow-0">CANCELAR SOLICITAÇÃO DE REMOÇÃO</button>--->
                    </div>
                </div>
            </div>

        </div>

    </div>
    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "perfilrun">
    <!--- PERFIL.RUN --->

    <cfset VARIABLES.profileSettingsPerfilRunLinkIcons = [
        {key="link", className="fa-solid fa-link", labelKey="profileRunLinkIconLink"},
        {key="store", className="fa-solid fa-store", labelKey="profileRunLinkIconStore"},
        {key="clothing", className="fa-solid fa-shirt", labelKey="profileRunLinkIconClothing"},
        {key="shoes", className="fa-solid fa-shoe-prints", labelKey="profileRunLinkIconShoes"},
        {key="running", className="fa-solid fa-person-running", labelKey="profileRunLinkIconRunning"},
        {key="watch", className="fa-solid fa-stopwatch", labelKey="profileRunLinkIconWatch"},
        {key="food", className="fa-solid fa-apple-whole", labelKey="profileRunLinkIconFood"},
        {key="coupon", className="fa-solid fa-ticket", labelKey="profileRunLinkIconCoupon"},
        {key="app", className="fa-solid fa-mobile-screen-button", labelKey="profileRunLinkIconApp"},
        {key="people", className="fa-solid fa-user-group", labelKey="profileRunLinkIconPeople"},
        {key="video", className="fa-solid fa-play", labelKey="profileRunLinkIconVideo"},
        {key="photo", className="fa-solid fa-camera", labelKey="profileRunLinkIconPhoto"},
        {key="music", className="fa-solid fa-music", labelKey="profileRunLinkIconMusic"},
        {key="book", className="fa-solid fa-book-open", labelKey="profileRunLinkIconBook"},
        {key="podcast", className="fa-solid fa-microphone", labelKey="profileRunLinkIconPodcast"},
        {key="calendar", className="fa-solid fa-calendar-days", labelKey="profileRunLinkIconCalendar"},
        {key="website", className="fa-solid fa-globe", labelKey="profileRunLinkIconWebsite"},
        {key="heart", className="fa-solid fa-heart", labelKey="profileRunLinkIconHeart"},
        {key="gift", className="fa-solid fa-gift", labelKey="profileRunLinkIconGift"},
        {key="course", className="fa-solid fa-graduation-cap", labelKey="profileRunLinkIconCourse"},
        {key="newsletter", className="fa-solid fa-envelope-open-text", labelKey="profileRunLinkIconNewsletter"},
        {key="download", className="fa-solid fa-download", labelKey="profileRunLinkIconDownload"},
        {key="location", className="fa-solid fa-location-dot", labelKey="profileRunLinkIconLocation"},
        {key="fitness", className="fa-solid fa-dumbbell", labelKey="profileRunLinkIconFitness"},
        {key="coffee", className="fa-solid fa-mug-hot", labelKey="profileRunLinkIconCoffee"},
        {key="work", className="fa-solid fa-briefcase", labelKey="profileRunLinkIconWork"}
    ]/>

    <div class="col-12">

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.profileRunTitle")#</cfoutput></div>

        <div class="card p-3">
            <div class="d-flex align-items-center justify-content-between gap-3">
                <div class="profile-settings-perfilrun-copy">
                    <div class="fw-bold text-break"><cfoutput>#encodeForHTML(VARIABLES.profileSettingsPerfilRunLabel)#</cfoutput></div>
                    <div class="small text-muted"><cfoutput>#REQUEST.t("athlete.settings.profileRunText")#</cfoutput></div>
                </div>
                <cfif VARIABLES.profileSettingsPerfilRunVerified>
                    <a
                        class="btn btn-sm profile-settings-perfilrun-button shadow-0"
                        href="<cfoutput>#VARIABLES.profileSettingsPerfilRunUrl#</cfoutput>"
                        target="_blank"
                        rel="noopener noreferrer">
                        <cfoutput>#REQUEST.t("athlete.settings.profileRunOpen")#</cfoutput>
                    </a>
                <cfelse>
                    <button
                        type="button"
                        class="btn btn-sm profile-settings-perfilrun-button shadow-0 disabled opacity-50"
                        disabled
                        aria-disabled="true">
                        <cfoutput>#REQUEST.t("athlete.settings.profileRunOpen")#</cfoutput>
                    </button>
                </cfif>
            </div>
        </div>

        <div class="text-divider"><cfoutput>#REQUEST.t("athlete.settings.profileRunSettingsTitle")#</cfoutput></div>

        <form method="post" action="<cfoutput>#VARIABLES.profileSettingsPath#</cfoutput>" class="card p-3">
            <fieldset<cfif NOT VARIABLES.profileSettingsPerfilRunVerified OR NOT VARIABLES.profileSettingsPerfilRunSchemaReady> disabled</cfif>>
                <input type="hidden" name="csrf_token" value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"/>
                <input type="hidden" name="action" value="editar_perfilrun"/>
                <input
                    type="hidden"
                    id="perfilrun_capa_url"
                    name="perfilrun_capa_url"
                    value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunCoverUrl)#</cfoutput>"/>

                <div class="profile-settings-control-row mb-2">
                    <div class="profile-settings-cover-preview">
                        <img
                            id="profileSettingsCoverPreview"
                            src="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunCoverDisplayUrl)#</cfoutput>"
                            alt="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunCoverCurrentAlt'))#</cfoutput>"/>
                    </div>
                    <div class="profile-settings-control-copy">
                        <div class="fw-bold"><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverTitle")#</cfoutput></div>
                        <button
                            type="button"
                            class="btn btn-sm profile-settings-cover-button shadow-0 mt-1"
                            data-bs-toggle="modal"
                            data-bs-target="#profileSettingsCoverModal"
                            <cfif NOT VARIABLES.profileSettingsPerfilRunCoverSchemaReady>disabled</cfif>>
                            <i class="bi bi-images me-1" aria-hidden="true"></i>
                            <cfoutput>#REQUEST.t("athlete.settings.profileRunCoverChange")#</cfoutput>
                        </button>
                        <cfif NOT VARIABLES.profileSettingsPerfilRunCoverSchemaReady>
                            <div class="small text-warning-emphasis mt-1"><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverUnavailable")#</cfoutput></div>
                        </cfif>
                    </div>
                </div>

                <div class="profile-settings-control-row border-top py-2 mb-2">
                    <div class="profile-settings-control-copy">
                        <div class="fw-bold"><cfoutput>#REQUEST.t("athlete.settings.profileRunThemeTitle")#</cfoutput></div>
                        <div class="small text-muted"><cfoutput>#REQUEST.t("athlete.settings.profileRunThemeText")#</cfoutput></div>
                    </div>
                    <div class="profile-settings-theme-options" role="radiogroup" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunThemeTitle'))#</cfoutput>">
                        <label class="profile-settings-theme-option">
                            <input
                                type="radio"
                                name="perfilrun_tema"
                                value="dark"
                                <cfif VARIABLES.profileSettingsPerfilRunTheme EQ "dark">checked</cfif>/>
                            <span><i class="bi bi-moon-stars-fill" aria-hidden="true"></i><cfoutput>#REQUEST.t("athlete.settings.profileRunThemeDark")#</cfoutput></span>
                        </label>
                        <label class="profile-settings-theme-option">
                            <input
                                type="radio"
                                name="perfilrun_tema"
                                value="light"
                                <cfif VARIABLES.profileSettingsPerfilRunTheme EQ "light">checked</cfif>/>
                            <span><i class="bi bi-sun-fill" aria-hidden="true"></i><cfoutput>#REQUEST.t("athlete.settings.profileRunThemeLight")#</cfoutput></span>
                        </label>
                    </div>
                </div>

                <div
                    class="profile-settings-links-manager border-top py-3"
                    data-profile-links
                    data-endpoint="/api/perfilrun/links.cfm"
                    data-csrf="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsCsrfToken)#</cfoutput>"
                    data-loading="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinksLoading'))#</cfoutput>"
                    data-empty="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinksEmpty'))#</cfoutput>"
                    data-limit-reached="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinksLimitReached'))#</cfoutput>"
                    data-load-error="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinksLoadError'))#</cfoutput>"
                    data-save-error="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinksSaveError'))#</cfoutput>"
                    data-invalid="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkInvalid'))#</cfoutput>"
                    data-click-singular="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkClick'))#</cfoutput>"
                    data-click-plural="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkClicks'))#</cfoutput>"
                    data-edit-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkEdit'))#</cfoutput>"
                    data-enable-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkEnable'))#</cfoutput>"
                    data-disable-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkDisable'))#</cfoutput>"
                    data-inactive-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkInactive'))#</cfoutput>"
                    data-delete-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkDelete'))#</cfoutput>"
                    data-delete-confirm="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkDeleteConfirm'))#</cfoutput>"
                    data-save-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkSave'))#</cfoutput>"
                    data-cancel-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkCancel'))#</cfoutput>">
                    <div class="d-flex align-items-start justify-content-between gap-2 mb-2">
                        <div>
                            <div class="fw-bold"><cfoutput>#REQUEST.t("athlete.settings.profileRunLinksTitle")#</cfoutput></div>
                        </div>
                        <span class="badge rounded-pill text-bg-light border" data-profile-links-count>0/30</span>
                    </div>

                    <div class="small text-muted py-2" role="status" aria-live="polite" data-profile-links-status>
                        <cfoutput>#REQUEST.t("athlete.settings.profileRunLinksLoading")#</cfoutput>
                    </div>
                    <div class="profile-settings-links-list" data-profile-links-list></div>

                    <div class="profile-settings-link-editor mt-2" data-profile-links-add>
                        <div class="profile-settings-link-field profile-settings-link-field-text">
                            <label class="form-label small mb-1" for="profileRunLinkText"><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkTextLabel")#</cfoutput></label>
                            <input
                                class="form-control form-control-sm"
                                id="profileRunLinkText"
                                type="text"
                                maxlength="80"
                                autocomplete="off"
                                placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkTextPlaceholder'))#</cfoutput>"
                                data-profile-link-text/>
                        </div>
                        <div class="profile-settings-link-field profile-settings-link-field-url">
                            <label class="form-label small mb-1" for="profileRunLinkUrl"><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkUrlLabel")#</cfoutput></label>
                            <input
                                class="form-control form-control-sm"
                                id="profileRunLinkUrl"
                                type="url"
                                inputmode="url"
                                maxlength="2048"
                                autocomplete="url"
                                placeholder="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkUrlPlaceholder'))#</cfoutput>"
                                data-profile-link-url/>
                        </div>
                        <div class="profile-settings-link-editor-footer">
                            <div class="profile-settings-link-field profile-settings-link-field-icon">
                                <div class="form-label small mb-1"><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkIconLabel")#</cfoutput></div>
                                <button
                                    type="button"
                                    class="profile-settings-link-icon-trigger"
                                    aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkIconLabel'))#</cfoutput>"
                                    data-profile-link-icon-trigger>
                                    <span class="profile-settings-link-icon-preview" aria-hidden="true" data-profile-link-icon-preview><i class="fa-solid fa-link"></i></span>
                                    <span data-profile-link-icon-label><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkIconLink")#</cfoutput></span>
                                    <i class="fa-solid fa-chevron-down profile-settings-link-icon-chevron" aria-hidden="true"></i>
                                </button>
                                <select class="visually-hidden" id="profileRunLinkIcon" tabindex="-1" aria-hidden="true" data-profile-link-icon>
                                    <cfloop array="#VARIABLES.profileSettingsPerfilRunLinkIcons#" index="VARIABLES.profileSettingsPerfilRunLinkIcon">
                                        <option
                                            value="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunLinkIcon.key)#</cfoutput>"
                                            data-icon-class="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunLinkIcon.className)#</cfoutput>">
                                            <cfoutput>#REQUEST.t("athlete.settings." & VARIABLES.profileSettingsPerfilRunLinkIcon.labelKey)#</cfoutput>
                                        </option>
                                    </cfloop>
                                </select>
                            </div>
                            <button
                                type="button"
                                class="btn btn-dark shadow-0 profile-settings-link-add"
                                title="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkAdd'))#</cfoutput>"
                                aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkAdd'))#</cfoutput>"
                                data-profile-link-add>
                                <i class="fa-solid fa-plus me-1" aria-hidden="true"></i>
                                <span><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkAdd")#</cfoutput></span>
                            </button>
                        </div>
                    </div>

                    <div class="profile-settings-links-responsibility mt-2" role="note">
                        <i class="fa-solid fa-circle-info" aria-hidden="true"></i>
                        <span><cfoutput>#REQUEST.t("athlete.settings.profileRunLinksResponsibility")#</cfoutput></span>
                    </div>
                </div>

                <div class="profile-settings-perfilrun-switch border-top pt-3">
                    <div>
                        <label class="fw-bold" for="perfilrun_contato_email"><cfoutput>#REQUEST.t("athlete.settings.profileRunEmailContact")#</cfoutput></label>
                        <div class="small text-muted">
                            <cfif VARIABLES.profileSettingsIsAdmin>
                                <cfoutput>#REQUEST.t("athlete.settings.profileRunEmailContactAdminText")#</cfoutput>
                            <cfelse>
                                <cfoutput>#REQUEST.t("athlete.settings.profileRunEmailContactText")#</cfoutput>
                            </cfif>
                        </div>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input
                            class="form-check-input"
                            type="checkbox"
                            role="switch"
                            id="perfilrun_contato_email"
                            name="perfilrun_contato_email"
                            <cfif VARIABLES.profileSettingsPerfilRunShowEmail OR VARIABLES.profileSettingsIsAdmin> checked="checked"</cfif><cfif VARIABLES.profileSettingsIsAdmin> disabled="disabled" aria-disabled="true"</cfif>/>
                    </div>
                </div>

                <div class="profile-settings-perfilrun-switch border-top pt-3 mt-3">
                    <div>
                        <label class="fw-bold" for="perfilrun_contato_whatsapp"><cfoutput>#REQUEST.t("athlete.settings.profileRunWhatsappContact")#</cfoutput></label>
                        <div class="small text-muted"><cfoutput>#REQUEST.t("athlete.settings.profileRunWhatsappContactText")#</cfoutput></div>
                        <cfif NOT VARIABLES.profileSettingsPerfilRunWhatsappEligible>
                            <div class="small text-warning-emphasis mt-1">
                                <cfoutput>#REQUEST.t("athlete.settings.profileRunWhatsappMissing")#</cfoutput>
                                <a href="<cfoutput>#REQUEST.i18nBuildPath('profileSettingsLinks')#</cfoutput>"><cfoutput>#REQUEST.t("athlete.settings.navLinks")#</cfoutput></a>.
                            </div>
                        </cfif>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input
                            class="form-check-input"
                            type="checkbox"
                            role="switch"
                            id="perfilrun_contato_whatsapp"
                            name="perfilrun_contato_whatsapp"
                            <cfif VARIABLES.profileSettingsPerfilRunShowWhatsapp>checked</cfif>
                            <cfif NOT VARIABLES.profileSettingsPerfilRunWhatsappEligible>disabled</cfif>/>
                    </div>
                </div>

                <button type="submit" class="btn btn-secondary w-100 shadow-0 mt-3">
                    <cfoutput>#REQUEST.t("athlete.settings.profileRunSave")#</cfoutput>
                </button>
            </fieldset>
        </form>

        <div
            class="modal fade"
            id="profileSettingsCoverModal"
            tabindex="-1"
            aria-labelledby="profileSettingsCoverModalLabel"
            aria-hidden="true"
            data-cover-api="https://picsum.photos/v2/list?page=2&amp;limit=100"
            data-current-cover="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunCoverUrl)#</cfoutput>"
            data-select-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunCoverSelectAria'))#</cfoutput>">
            <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <div>
                            <h5 class="modal-title" id="profileSettingsCoverModalLabel"><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverModalTitle")#</cfoutput></h5>
                            <div class="small text-muted"><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverModalText")#</cfoutput></div>
                        </div>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunCoverCloseAria'))#</cfoutput>"></button>
                    </div>
                    <div class="modal-body">
                        <div class="profile-settings-cover-loading py-5 text-center" data-cover-loading>
                            <div class="spinner-border spinner-border-sm text-secondary" role="status"></div>
                            <div class="small text-muted mt-2"><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverLoading")#</cfoutput></div>
                        </div>
                        <div class="alert alert-warning d-none" role="alert" data-cover-error>
                            <span><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverError")#</cfoutput></span>
                            <button type="button" class="btn btn-sm btn-outline-dark ms-2" data-cover-retry><cfoutput>#REQUEST.t("athlete.settings.profileRunCoverRetry")#</cfoutput></button>
                        </div>
                        <div class="profile-settings-cover-grid d-none" data-cover-grid></div>
                    </div>
                    <div class="modal-footer justify-content-start small text-muted">
                        <cfoutput>#REQUEST.t("athlete.settings.profileRunCoverSaveHint")#</cfoutput>
                    </div>
                </div>
            </div>
        </div>

        <div
            class="modal fade"
            id="profileSettingsLinkIconModal"
            tabindex="-1"
            aria-labelledby="profileSettingsLinkIconModalLabel"
            aria-hidden="true"
            data-profile-link-icon-modal>
            <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="profileSettingsLinkIconModalLabel"><cfoutput>#REQUEST.t("athlete.settings.profileRunLinkIconLabel")#</cfoutput></h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.profileRunLinkCancel'))#</cfoutput>"></button>
                    </div>
                    <div class="modal-body">
                        <div class="profile-settings-link-icon-grid" role="listbox">
                            <cfloop array="#VARIABLES.profileSettingsPerfilRunLinkIcons#" index="VARIABLES.profileSettingsPerfilRunLinkIcon">
                                <button
                                    type="button"
                                    class="profile-settings-link-icon-option"
                                    role="option"
                                    data-profile-link-icon-option
                                    data-icon-key="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunLinkIcon.key)#</cfoutput>"
                                    data-icon-class="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunLinkIcon.className)#</cfoutput>"
                                    data-icon-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.' & VARIABLES.profileSettingsPerfilRunLinkIcon.labelKey))#</cfoutput>">
                                    <i class="<cfoutput>#encodeForHTMLAttribute(VARIABLES.profileSettingsPerfilRunLinkIcon.className)#</cfoutput>" aria-hidden="true"></i>
                                    <span><cfoutput>#REQUEST.t("athlete.settings." & VARIABLES.profileSettingsPerfilRunLinkIcon.labelKey)#</cfoutput></span>
                                </button>
                            </cfloop>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <cfif NOT VARIABLES.profileSettingsPerfilRunVerified>
            <div class="alert alert-warning small mt-2 mb-0 shadow-0" role="note">
                <i class="bi bi-patch-check-fill me-2" aria-hidden="true"></i><cfoutput>#REQUEST.t("athlete.settings.profileRunVerifiedOnly")#</cfoutput>
            </div>
        <cfelseif NOT VARIABLES.profileSettingsPerfilRunSchemaReady>
            <div class="alert alert-warning small mt-2 mb-0 shadow-0" role="alert">
                <i class="bi bi-exclamation-triangle me-2" aria-hidden="true"></i><cfoutput>#REQUEST.t("athlete.settings.profileRunUnavailable")#</cfoutput>
            </div>
        </cfif>

    </div>
    </cfif>

</div>

<cfif VARIABLES.profileSettingsSection EQ "perfil">
<script src="/assets/js/runnerhub-athlete-location.js?version=2026-05-22"></script>
</cfif>

<script type="text/javascript" defer>

    <cfif VARIABLES.profileSettingsSection EQ "perfil">
    function getTag(tag) {
        if (tag) {
            $.getJSON("/api/Util.cfc?method=getUserTag&id_pagina=" + <cfoutput>#qMeuPerfil.id_pagina#</cfoutput> + "&texto=" + encodeURIComponent(tag) + "&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23", function(result) {
                if (result.status.mensagem !== 'OK') {
                    inputTag.classList.add('is-invalid');
                    inputTag.classList.remove('is-valid');
                    inputTag.setCustomValidity('patternMismatch');
                } else {
                    inputTag.classList.add('is-valid');
                    inputTag.classList.remove('is-invalid');
                    inputTag.setCustomValidity('');
                }
                $("#inputTag").val(result.data);
            });
        }
    }
    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "integracoes">
    (function () {
        const panel = document.querySelector('[data-api-token-panel]');

        if (!panel || !window.fetch) {
            return;
        }

        const statusEl = panel.querySelector('[data-api-token-status]');
        const valueWrapper = panel.querySelector('[data-api-token-value-wrapper]');
        const valueInput = panel.querySelector('[data-api-token-value]');
        const generateButton = panel.querySelector('[data-api-token-generate]');
        const revokeButton = panel.querySelector('[data-api-token-revoke]');
        const copyButton = panel.querySelector('[data-api-token-copy]');
        const csrfToken = panel.getAttribute('data-api-token-csrf') || '';

        function renderStatus(payload) {
            const items = payload && Array.isArray(payload.items) ? payload.items : [];

            valueWrapper.classList.add('d-none');
            valueInput.value = '';

            if (!payload || payload.success !== true) {
                statusEl.textContent = payload && payload.message
                    ? payload.message
                    : 'Não foi possível carregar o token.';
                generateButton.disabled = true;
                revokeButton.disabled = true;
                return;
            }

            if (!items.length) {
                statusEl.textContent = 'Nenhum token ativo.';
                generateButton.disabled = false;
                revokeButton.disabled = true;
                return;
            }

            const currentToken = items[0];
            const lastUsed = currentToken.lastUsedAt ? ' Último uso: ' + currentToken.lastUsedAt + '.' : ' Ainda não usado.';

            statusEl.textContent = 'Token ativo: ' + currentToken.tokenPrefix + '...' + lastUsed;
            generateButton.disabled = false;
            revokeButton.disabled = false;
        }

        function requestToken(actionName) {
            return fetch('/api/me/developer-token.cfm', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify({
                    action: actionName,
                    clientId: 'profile-developer'
                })
            }).then(function (response) {
                return response.json();
            });
        }

        function loadToken() {
            return fetch('/api/me/developer-token.cfm', {
                credentials: 'same-origin'
            })
                .then(function (response) {
                    return response.json();
                })
                .then(renderStatus)
                .catch(function () {
                    statusEl.textContent = 'Não foi possível carregar o token.';
                });
        }

        generateButton.addEventListener('click', function () {
            generateButton.disabled = true;
            statusEl.textContent = 'Gerando token...';

            requestToken('generate')
                .then(function (payload) {
                    if (!payload || !payload.success || !payload.token) {
                        throw new Error(payload && payload.message
                            ? payload.message
                            : 'Não foi possível gerar o token.');
                    }

                    renderStatus({ success: true, items: [payload.item] });
                    valueInput.value = payload.token;
                    valueWrapper.classList.remove('d-none');
                })
                .catch(function (error) {
                    statusEl.textContent = error && error.message
                        ? error.message
                        : 'Não foi possível gerar o token.';
                })
                .finally(function () {
                    generateButton.disabled = false;
                });
        });

        revokeButton.addEventListener('click', function () {
            if (!window.confirm('Revogar o token ativo da API?')) {
                return;
            }

            revokeButton.disabled = true;
            statusEl.textContent = 'Revogando token...';

            requestToken('revoke')
                .then(renderStatus)
                .catch(function () {
                    statusEl.textContent = 'Não foi possível revogar o token.';
                });
        });

        copyButton.addEventListener('click', function () {
            if (!valueInput.value) {
                return;
            }

            valueInput.select();
            document.execCommand('copy');
            copyButton.textContent = 'Copiado';
            window.setTimeout(function () {
                copyButton.textContent = 'Copiar';
            }, 1800);
        });

        loadToken();
    }());
    </cfif>

    <cfif VARIABLES.profileSettingsSection EQ "perfilrun">
    (function initializePerfilRunCoverPicker() {
        const modalElement = document.getElementById('profileSettingsCoverModal');
        const coverInput = document.getElementById('perfilrun_capa_url');
        const coverPreview = document.getElementById('profileSettingsCoverPreview');

        if (!modalElement || !coverInput || !coverPreview || !window.fetch) {
            return;
        }

        const apiUrl = modalElement.getAttribute('data-cover-api');
        const selectLabel = modalElement.getAttribute('data-select-label') || 'Selecionar imagem';
        const loadingElement = modalElement.querySelector('[data-cover-loading]');
        const errorElement = modalElement.querySelector('[data-cover-error]');
        const retryButton = modalElement.querySelector('[data-cover-retry]');
        const gridElement = modalElement.querySelector('[data-cover-grid]');
        let loaded = false;
        let loading = false;

        function normalizeDownloadUrl(value) {
            const normalized = String(value || '').trim().split('?')[0];
            return /^https:\/\/picsum[.]photos\/id\/[0-9]+\/[1-9][0-9]{0,5}\/[1-9][0-9]{0,5}$/i.test(normalized)
                ? normalized
                : '';
        }

        function thumbnailUrl(downloadUrl) {
            return downloadUrl.replace(/\/[0-9]+\/[0-9]+$/, '/320/180') + '?grayscale';
        }

        function selectCover(downloadUrl) {
            const normalized = normalizeDownloadUrl(downloadUrl);
            if (!normalized) {
                return;
            }

            coverInput.value = normalized;
            coverPreview.src = normalized + '?grayscale';
            modalElement.setAttribute('data-current-cover', normalized);

            gridElement.querySelectorAll('[data-cover-url]').forEach(function (button) {
                button.classList.toggle('is-selected', button.getAttribute('data-cover-url') === normalized);
            });

            if (window.bootstrap && window.bootstrap.Modal) {
                window.bootstrap.Modal.getOrCreateInstance(modalElement).hide();
            }
        }

        function renderItems(items) {
            const currentCover = normalizeDownloadUrl(modalElement.getAttribute('data-current-cover'));
            const fragment = document.createDocumentFragment();

            gridElement.replaceChildren();
            items.forEach(function (item) {
                const downloadUrl = normalizeDownloadUrl(item && item.download_url);
                if (!downloadUrl) {
                    return;
                }

                const author = String(item.author || '').trim();
                const button = document.createElement('button');
                const image = document.createElement('img');
                const caption = document.createElement('span');

                button.type = 'button';
                button.className = 'profile-settings-cover-option';
                button.setAttribute('data-cover-url', downloadUrl);
                button.setAttribute('aria-label', selectLabel + (author ? ': ' + author : ''));
                button.classList.toggle('is-selected', downloadUrl === currentCover);
                button.addEventListener('click', function () {
                    selectCover(downloadUrl);
                });

                image.src = thumbnailUrl(downloadUrl);
                image.alt = author;
                image.loading = 'lazy';
                image.decoding = 'async';

                caption.textContent = author;
                button.append(image, caption);
                fragment.appendChild(button);
            });

            gridElement.appendChild(fragment);
        }

        function loadCovers() {
            if (loaded || loading) {
                return;
            }

            loading = true;
            loadingElement.classList.remove('d-none');
            errorElement.classList.add('d-none');
            gridElement.classList.add('d-none');

            fetch(apiUrl, { headers: { Accept: 'application/json' } })
                .then(function (response) {
                    if (!response.ok) {
                        throw new Error('Picsum API: ' + response.status);
                    }
                    return response.json();
                })
                .then(function (items) {
                    if (!Array.isArray(items)) {
                        throw new Error('Invalid Picsum response');
                    }
                    renderItems(items);
                    loaded = true;
                    gridElement.classList.remove('d-none');
                })
                .catch(function () {
                    errorElement.classList.remove('d-none');
                })
                .finally(function () {
                    loading = false;
                    loadingElement.classList.add('d-none');
                });
        }

        modalElement.addEventListener('show.bs.modal', loadCovers);
        retryButton.addEventListener('click', loadCovers);
    }());

    (function initializePerfilRunLinksManager() {
        const manager = document.querySelector('[data-profile-links]');

        if (!manager || !window.fetch) {
            return;
        }

        const endpoint = manager.getAttribute('data-endpoint') || '';
        const csrfToken = manager.getAttribute('data-csrf') || '';
        const statusElement = manager.querySelector('[data-profile-links-status]');
        const listElement = manager.querySelector('[data-profile-links-list]');
        const countElement = manager.querySelector('[data-profile-links-count]');
        const addEditor = manager.querySelector('[data-profile-links-add]');
        const addText = addEditor.querySelector('[data-profile-link-text]');
        const addUrl = addEditor.querySelector('[data-profile-link-url]');
        const addIcon = addEditor.querySelector('[data-profile-link-icon]');
        const addIconPreview = addEditor.querySelector('[data-profile-link-icon-preview]');
        const addIconLabel = addEditor.querySelector('[data-profile-link-icon-label]');
        const addIconTrigger = addEditor.querySelector('[data-profile-link-icon-trigger]');
        const addButton = addEditor.querySelector('[data-profile-link-add]');
        const iconModalElement = document.querySelector('[data-profile-link-icon-modal]');
        const iconModalOptions = iconModalElement
            ? Array.from(iconModalElement.querySelectorAll('[data-profile-link-icon-option]'))
            : [];
        const labels = {
            loading: manager.getAttribute('data-loading') || '',
            empty: manager.getAttribute('data-empty') || '',
            limitReached: manager.getAttribute('data-limit-reached') || '',
            loadError: manager.getAttribute('data-load-error') || '',
            saveError: manager.getAttribute('data-save-error') || '',
            invalid: manager.getAttribute('data-invalid') || '',
            click: manager.getAttribute('data-click-singular') || 'clique',
            clicks: manager.getAttribute('data-click-plural') || 'cliques',
            edit: manager.getAttribute('data-edit-label') || 'Editar',
            enable: manager.getAttribute('data-enable-label') || 'Ativar link',
            disable: manager.getAttribute('data-disable-label') || 'Desativar link',
            inactive: manager.getAttribute('data-inactive-label') || 'Inativo',
            remove: manager.getAttribute('data-delete-label') || 'Remover',
            removeConfirm: manager.getAttribute('data-delete-confirm') || '',
            save: manager.getAttribute('data-save-label') || 'Salvar',
            cancel: manager.getAttribute('data-cancel-label') || 'Cancelar'
        };
        let currentItems = [];
        let currentLimit = 30;
        let busy = false;
        let activeIconPicker = null;

        function readValue(source, key, fallback) {
            if (!source || typeof source !== 'object') {
                return fallback;
            }
            if (Object.prototype.hasOwnProperty.call(source, key)) {
                return source[key];
            }
            const upperKey = key.toUpperCase();
            return Object.prototype.hasOwnProperty.call(source, upperKey) ? source[upperKey] : fallback;
        }

        function selectedIconClass(selectElement) {
            const selectedOption = selectElement.options[selectElement.selectedIndex];
            return selectedOption ? selectedOption.getAttribute('data-icon-class') || 'fa-solid fa-link' : 'fa-solid fa-link';
        }

        function selectedIconLabel(selectElement) {
            const selectedOption = selectElement.options[selectElement.selectedIndex];
            return selectedOption ? selectedOption.textContent.trim() : '';
        }

        function iconClassFor(iconKey) {
            const option = Array.from(addIcon.options).find(function (candidate) {
                return candidate.value === iconKey;
            });
            return option ? option.getAttribute('data-icon-class') || 'fa-solid fa-link' : 'fa-solid fa-link';
        }

        function updateIconPreview(selectElement, previewElement, labelElement) {
            const icon = document.createElement('i');
            icon.className = selectedIconClass(selectElement);
            previewElement.replaceChildren(icon);
            if (labelElement) {
                labelElement.textContent = selectedIconLabel(selectElement);
            }
        }

        function synchronizeIconModal(selectedKey) {
            iconModalOptions.forEach(function (option) {
                const isSelected = option.getAttribute('data-icon-key') === selectedKey;
                option.classList.toggle('is-selected', isSelected);
                option.setAttribute('aria-selected', isSelected ? 'true' : 'false');
            });
        }

        function bindIconPicker(triggerElement, selectElement, previewElement, labelElement) {
            if (!triggerElement || !iconModalElement) {
                return;
            }
            triggerElement.addEventListener('click', function () {
                activeIconPicker = {
                    select: selectElement,
                    preview: previewElement,
                    label: labelElement
                };
                synchronizeIconModal(selectElement.value);
                if (window.bootstrap && window.bootstrap.Modal) {
                    window.bootstrap.Modal.getOrCreateInstance(iconModalElement).show();
                }
            });
        }

        function setStatus(message, isError) {
            statusElement.textContent = message || '';
            statusElement.classList.toggle('text-danger', Boolean(isError));
            statusElement.classList.toggle('d-none', !message);
        }

        function setBusy(nextBusy) {
            busy = nextBusy;
            addText.disabled = nextBusy || currentItems.length >= currentLimit;
            addUrl.disabled = nextBusy || currentItems.length >= currentLimit;
            addIcon.disabled = nextBusy || currentItems.length >= currentLimit;
            addIconTrigger.disabled = nextBusy || currentItems.length >= currentLimit;
            addButton.disabled = nextBusy || currentItems.length >= currentLimit;
            listElement.querySelectorAll('button, input, select').forEach(function (control) {
                control.disabled = nextBusy;
            });
        }

        function validLink(text, url) {
            let parsedUrl;
            if (!String(text || '').trim() || String(text || '').trim().length > 80 || String(url || '').length > 2048) {
                return false;
            }
            try {
                parsedUrl = new URL(String(url || '').trim());
            } catch (error) {
                return false;
            }
            return (parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:')
                && Boolean(parsedUrl.hostname)
                && !parsedUrl.username
                && !parsedUrl.password;
        }

        function request(actionName, item) {
            const payload = Object.assign({ action: actionName }, item || {});
            return fetch(endpoint, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify(payload)
            }).then(function (response) {
                return response.json().catch(function () {
                    return {};
                }).then(function (data) {
                    if (!response.ok || readValue(data, 'success', false) !== true) {
                        throw new Error(readValue(data, 'message', labels.saveError));
                    }
                    return data;
                });
            });
        }

        function normalizeItem(item) {
            const rawActive = readValue(item, 'active', true);
            return {
                id: Number(readValue(item, 'id', 0)) || 0,
                text: String(readValue(item, 'text', '') || ''),
                url: String(readValue(item, 'url', '') || ''),
                icon: String(readValue(item, 'icon', 'link') || 'link'),
                order: Number(readValue(item, 'order', 0)) || 0,
                active: rawActive === true
                    || rawActive === 1
                    || ['true', '1', 'yes', 'on'].includes(String(rawActive).toLowerCase()),
                clicks: Number(readValue(item, 'clicks', 0)) || 0
            };
        }

        function createIcon(iconKey, className) {
            const wrapper = document.createElement('span');
            const icon = document.createElement('i');
            wrapper.className = className;
            wrapper.setAttribute('aria-hidden', 'true');
            icon.className = iconClassFor(iconKey);
            wrapper.appendChild(icon);
            return wrapper;
        }

        function createActionButton(label, iconClass, extraClass) {
            const button = document.createElement('button');
            const icon = document.createElement('i');
            button.type = 'button';
            button.className = 'profile-settings-link-action ' + (extraClass || '');
            button.setAttribute('aria-label', label);
            button.title = label;
            icon.className = iconClass;
            icon.setAttribute('aria-hidden', 'true');
            button.appendChild(icon);
            return button;
        }

        function createEditEditor(item, rowElement) {
            const editor = document.createElement('div');
            const textInput = addText.cloneNode(false);
            const urlInput = addUrl.cloneNode(false);
            const iconSelect = addIcon.cloneNode(true);
            const footer = document.createElement('div');
            const iconField = document.createElement('div');
            const iconTrigger = addIconTrigger.cloneNode(true);
            const iconPreview = createIcon(item.icon, 'profile-settings-link-icon-preview');
            const iconLabel = document.createElement('span');
            const iconChevron = document.createElement('i');
            const saveButton = document.createElement('button');
            const cancelButton = document.createElement('button');
            const actions = document.createElement('div');

            editor.className = 'profile-settings-link-editor is-inline-edit';
            textInput.removeAttribute('id');
            urlInput.removeAttribute('id');
            textInput.value = item.text;
            urlInput.value = item.url;
            iconSelect.removeAttribute('id');
            iconSelect.value = item.icon;
            iconTrigger.replaceChildren();
            iconTrigger.removeAttribute('id');
            iconTrigger.setAttribute('data-profile-link-icon-trigger', '');
            iconLabel.setAttribute('data-profile-link-icon-label', '');
            iconChevron.className = 'fa-solid fa-chevron-down profile-settings-link-icon-chevron';
            iconChevron.setAttribute('aria-hidden', 'true');
            iconTrigger.append(iconPreview, iconLabel, iconChevron);
            iconField.className = 'profile-settings-link-field profile-settings-link-field-icon';
            iconField.append(iconTrigger, iconSelect);
            footer.className = 'profile-settings-link-editor-footer';

            saveButton.type = 'button';
            saveButton.className = 'btn btn-sm btn-dark shadow-0';
            saveButton.textContent = labels.save;
            cancelButton.type = 'button';
            cancelButton.className = 'btn btn-sm btn-light border shadow-0';
            cancelButton.textContent = labels.cancel;
            actions.className = 'd-flex gap-1';
            actions.append(saveButton, cancelButton);
            footer.append(iconField, actions);
            editor.append(textInput, urlInput, footer);

            iconSelect.addEventListener('change', function () {
                updateIconPreview(iconSelect, iconPreview, iconLabel);
            });
            updateIconPreview(iconSelect, iconPreview, iconLabel);
            bindIconPicker(iconTrigger, iconSelect, iconPreview, iconLabel);
            cancelButton.addEventListener('click', function () {
                editor.remove();
                rowElement.classList.remove('d-none');
            });
            saveButton.addEventListener('click', function () {
                const text = textInput.value.trim();
                const url = urlInput.value.trim();
                if (!validLink(text, url)) {
                    setStatus(labels.invalid, true);
                    return;
                }
                setBusy(true);
                request('update', { id: item.id, text: text, url: url, icon: iconSelect.value })
                    .then(renderState)
                    .catch(function (error) {
                        setStatus(error.message || labels.saveError, true);
                    })
                    .finally(function () {
                        setBusy(false);
                    });
            });

            [textInput, urlInput].forEach(function (input) {
                input.addEventListener('keydown', function (event) {
                    if (event.key === 'Enter') {
                        event.preventDefault();
                        saveButton.click();
                    }
                });
            });

            return editor;
        }

        function createRow(item) {
            const row = document.createElement('div');
            const copy = document.createElement('div');
            const title = document.createElement('div');
            const url = document.createElement('div');
            const clicks = document.createElement('span');
            const actions = document.createElement('div');
            const editButton = createActionButton(labels.edit, 'fa-solid fa-pen', '');
            const visibilityButton = createActionButton(
                item.active ? labels.disable : labels.enable,
                item.active ? 'fa-solid fa-eye' : 'fa-solid fa-eye-slash',
                'profile-settings-link-action-visibility'
            );
            const deleteButton = createActionButton(labels.remove, 'fa-solid fa-trash-can', 'profile-settings-link-action-delete');

            row.className = 'profile-settings-link-row' + (item.active ? '' : ' is-inactive');
            copy.className = 'profile-settings-link-row-copy';
            title.className = 'profile-settings-link-row-title';
            url.className = 'profile-settings-link-row-url';
            clicks.className = 'profile-settings-link-clicks';
            actions.className = 'profile-settings-link-actions';
            title.textContent = item.text;
            url.textContent = item.url;
            url.title = item.url;
            clicks.textContent = item.clicks + ' ' + (item.clicks === 1 ? labels.click : labels.clicks);
            if (!item.active) {
                clicks.textContent += ' · ' + labels.inactive;
            }
            copy.append(title, url);
            visibilityButton.setAttribute('role', 'switch');
            visibilityButton.setAttribute('aria-checked', item.active ? 'true' : 'false');
            actions.append(visibilityButton, editButton, deleteButton);
            row.append(createIcon(item.icon, 'profile-settings-link-row-icon'), copy, clicks, actions);

            visibilityButton.addEventListener('click', function () {
                setBusy(true);
                request('set_active', { id: item.id, active: !item.active })
                    .then(renderState)
                    .catch(function (error) {
                        setStatus(error.message || labels.saveError, true);
                    })
                    .finally(function () {
                        setBusy(false);
                    });
            });
            editButton.addEventListener('click', function () {
                listElement.querySelectorAll('.is-inline-edit').forEach(function (openEditor) {
                    const hiddenRow = openEditor.previousElementSibling;
                    openEditor.remove();
                    if (hiddenRow) {
                        hiddenRow.classList.remove('d-none');
                    }
                });
                row.classList.add('d-none');
                row.after(createEditEditor(item, row));
            });
            deleteButton.addEventListener('click', function () {
                if (labels.removeConfirm && !window.confirm(labels.removeConfirm)) {
                    return;
                }
                setBusy(true);
                request('delete', { id: item.id })
                    .then(renderState)
                    .catch(function (error) {
                        setStatus(error.message || labels.saveError, true);
                    })
                    .finally(function () {
                        setBusy(false);
                    });
            });

            return row;
        }

        function renderState(payload) {
            const rawItems = readValue(payload, 'items', []);
            currentItems = Array.isArray(rawItems) ? rawItems.map(normalizeItem) : [];
            currentLimit = Number(readValue(payload, 'limit', 30)) || 30;
            listElement.replaceChildren();
            currentItems.forEach(function (item) {
                listElement.appendChild(createRow(item));
            });
            countElement.textContent = currentItems.length + '/' + currentLimit;
            setStatus(currentItems.length ? '' : labels.empty, false);
            if (currentItems.length >= currentLimit) {
                setStatus(labels.limitReached, false);
            }
            setBusy(false);
        }

        function addLink() {
            const text = addText.value.trim();
            const url = addUrl.value.trim();
            if (!validLink(text, url)) {
                setStatus(labels.invalid, true);
                return;
            }
            setBusy(true);
            request('create', { text: text, url: url, icon: addIcon.value })
                .then(function (payload) {
                    addText.value = '';
                    addUrl.value = '';
                    addIcon.selectedIndex = 0;
                    updateIconPreview(addIcon, addIconPreview, addIconLabel);
                    renderState(payload);
                })
                .catch(function (error) {
                    setStatus(error.message || labels.saveError, true);
                })
                .finally(function () {
                    setBusy(false);
                });
        }

        addIcon.addEventListener('change', function () {
            updateIconPreview(addIcon, addIconPreview, addIconLabel);
        });
        bindIconPicker(addIconTrigger, addIcon, addIconPreview, addIconLabel);
        iconModalOptions.forEach(function (option) {
            option.addEventListener('click', function () {
                const iconKey = option.getAttribute('data-icon-key') || 'link';
                if (!activeIconPicker) {
                    return;
                }
                activeIconPicker.select.value = iconKey;
                updateIconPreview(
                    activeIconPicker.select,
                    activeIconPicker.preview,
                    activeIconPicker.label
                );
                synchronizeIconModal(iconKey);
                if (window.bootstrap && window.bootstrap.Modal) {
                    window.bootstrap.Modal.getOrCreateInstance(iconModalElement).hide();
                }
            });
        });
        if (iconModalElement) {
            iconModalElement.addEventListener('hidden.bs.modal', function () {
                activeIconPicker = null;
            });
        }
        addButton.addEventListener('click', addLink);
        [addText, addUrl].forEach(function (input) {
            input.addEventListener('keydown', function (event) {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    addLink();
                }
            });
        });

        setStatus(labels.loading, false);
        fetch(endpoint, { credentials: 'same-origin', headers: { Accept: 'application/json' } })
            .then(function (response) {
                return response.json().catch(function () {
                    return {};
                }).then(function (payload) {
                    if (!response.ok || readValue(payload, 'success', false) !== true) {
                        throw new Error(readValue(payload, 'message', labels.loadError));
                    }
                    return payload;
                });
            })
            .then(renderState)
            .catch(function (error) {
                setStatus(error.message || labels.loadError, true);
                setBusy(true);
            });
    }());
    </cfif>

</script>
