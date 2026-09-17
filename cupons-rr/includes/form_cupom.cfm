<cfif NOT structKeyExists(VARIABLES,'cpAccess') OR NOT (cpNew AND cuponsRrCanOperate OR cpCanEdit)><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<form method="post" action="./<cfif cpSelected>?cupom_id=#cpSelected#<cfelse>?novo=1</cfif>##cp-editor" data-cp-form>
<input type="hidden" name="coupon_action" value="#cpNew ? 'criar' : 'editar'#"/><input type="hidden" name="csrf" value="#encodeForHTMLAttribute(SESSION.couponManagerCsrf)#"/><input type="hidden" name="id_cupom" value="#cpSelected#"/><input type="hidden" name="revision" value="#encodeForHTMLAttribute(cpValues.revision)#"/>
<div class="cp-fields">
<div><label for="cp-code">Código do cupom *</label><input class="form-control" id="cp-code" name="cupom" maxlength="32" required autocomplete="off" value="#encodeForHTMLAttribute(cpValues.cupom)#" placeholder="Ex.: CORRIDA10"/></div>
<div><label for="cp-partner">Parceiro / organizador *</label><input class="form-control" id="cp-partner" name="parceiro" maxlength="256" required value="#encodeForHTMLAttribute(cpValues.parceiro)#"/></div>
<div class="cp-full"><label for="cp-conditions">Desconto e condições *</label><input class="form-control" id="cp-conditions" name="condicoes" maxlength="256" required value="#encodeForHTMLAttribute(cpValues.condicoes)#" placeholder="Ex.: 10% de desconto na inscrição, exceto taxas"/></div>
<div class="cp-full"><label for="cp-description">Descrição complementar</label><textarea class="form-control" id="cp-description" name="descricao" maxlength="256" rows="2">#encodeForHTML(cpValues.descricao)#</textarea></div>
<div class="cp-full"><label for="cp-url">Link de inscrição / resgate</label><input class="form-control" type="url" id="cp-url" name="url" maxlength="2048" value="#encodeForHTMLAttribute(cpValues.url)#" placeholder="https://"/></div>
<div><label for="cp-expiry">Expiração do cupom</label><input class="form-control" id="cp-expiry" type="date" name="data_expiracao" value="#encodeForHTMLAttribute(cpValues.data_expiracao)#"/><small>Último dia de validade, inclusive. Em branco: sem expiração geral.</small></div>
<div><label for="cp-active">Disponibilidade</label><select class="form-select" name="ativo" id="cp-active"><option value="true" <cfif cpValues.ativo EQ true>selected</cfif>>Ativo</option><option value="false" <cfif cpValues.ativo NEQ true>selected</cfif>>Inativo</option></select><small>Afeta todos os vínculos deste cupom.</small></div>
</div>
<cfif cpNew><fieldset class="cp-link-fields"><legend>Primeiro evento</legend><cfset cpPickerPrefix='new'/><cfinclude template="event-fields.cfm"/></fieldset></cfif>
<p class="cp-help mt-3">As condições são informativas. Confirme que o código está configurado na plataforma de inscrição antes de divulgá-lo.</p>
<div class="cp-actions"><button class="btn btn-warning" type="submit" <cfif cpConflict>disabled</cfif>><cfif cpNew>Cadastrar cupom<cfelse>Salvar alterações</cfif></button><a href="./">Cancelar</a></div><p class="cp-help" data-cp-feedback role="status"></p>
</form>
</cfoutput>
