<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfoutput>
<h1 class="h3">Comparador · Filtros e cadastros</h1>
</cfoutput>
<cfinclude template="../includes/navigation.cfm">
<cfoutput>
<cfif NOT ready><div class="alert alert-warning">Esta área aguarda a atualização dos cadastros no banco. Os produtos continuam disponíveis na aba Produtos.</div>
<cfelse>
<nav class="nav nav-tabs mb-4" aria-label="Cadastros do catálogo"><cfloop array="#catalog.entities()#" index="kind"><a class="nav-link <cfif kind EQ entity>active</cfif>" href="./?cadastro=#kind#" <cfif kind EQ entity>aria-current="page"</cfif>>#encodeForHTML(catalog.definition(kind).title)#</a></cfloop></nav>
<cfif len(error)><div class="alert alert-danger" role="alert">#encodeForHTML(error)#</div></cfif>
<cfif guard.field(URL,'salvo',1) EQ '1'><div class="alert alert-success" role="status">Cadastro salvo com histórico.</div></cfif>
<cfif conflict><p><a href="./?#encodeForHTMLAttribute(returnQuery)#&chave=#urlEncodedFormat(key)#">Reabrir cadastro atualizado</a></p>
<cfelseif len(key) OR newRecord>
<a href="./?#encodeForHTMLAttribute(returnQuery)#" class="d-inline-block mb-3">← Voltar à lista</a>
<div class="card card-body mb-4"><h2 class="h4">#len(key)?'Editar':'Novo registro'# · #encodeForHTML(def.title)#</h2>
<form method="post"><input type="hidden" name="acao" value="salvar"><input type="hidden" name="csrf_token" value="#csrf#"><input type="hidden" name="chave" value="#encodeForHTMLAttribute(key)#"><input type="hidden" name="token" value="#token#">
<div class="row g-3"><cfloop array="#def.fields#" index="field"><cfset fieldValue=value(field.name)><cfset fixedKey=len(key) AND arrayFind(def.keys,field.name)><div class="col-12 <cfif field.kind NEQ 'textarea'>col-md-6</cfif>"><label class="form-label" for="#field.name#">#encodeForHTML(field.label)#</label>
<cfif fixedKey><input class="form-control" id="#field.name#" name="#field.name#" value="#encodeForHTMLAttribute(fieldValue)#" readonly>
<cfelseif field.kind EQ 'textarea'><textarea class="form-control" rows="4" id="#field.name#" name="#field.name#" maxlength="#field.maximum#" <cfif field.requiredValue>required</cfif>>#encodeForHTML(fieldValue)#</textarea>
<cfelseif listFind('tipos,caracteristicas,filtros,format,filter,boolean',field.kind)>
<select class="form-select" id="#field.name#" name="#field.name#" required><option value="">Selecione</option>
<cfif listFind('tipos,caracteristicas,filtros',field.kind)>
 <cfset optionDef=catalog.definition(field.kind)><cfset optionsQuery=choices[field.kind]><cfloop query="optionsQuery"><cfset optionKey=optionsQuery[optionDef.keys[1]][optionsQuery.currentRow]><cfset optionLabel=optionsQuery[field.kind EQ 'tipos'?'nome_tipo_produto':(field.kind EQ 'caracteristicas'?'nome_caracteristica':'rotulo')][optionsQuery.currentRow]><option value="#encodeForHTMLAttribute(optionKey)#" <cfif fieldValue EQ optionKey>selected</cfif>>#encodeForHTML(optionLabel)# (#encodeForHTML(optionKey)#)</option></cfloop>
<cfelse>
 <cfset optionValues=field.kind EQ 'format'?'string,number,boolean':(field.kind EQ 'boolean'?'true,false':'marca,categoria,nome_produto,genero,placa,nivel_amortecimento,tamanho_drop,peso,preco_promocional')>
 <cfloop list="#optionValues#" index="optionKey"><option value="#optionKey#" <cfif fieldValue EQ optionKey OR (field.kind EQ 'boolean' AND isBoolean(fieldValue) AND ((fieldValue AND optionKey EQ 'true') OR (NOT fieldValue AND optionKey EQ 'false')))>selected</cfif>>#field.kind EQ 'boolean'?(optionKey EQ 'true'?'Sim':'Não'):optionKey#</option></cfloop>
</cfif></select>
<cfelse><input class="form-control" id="#field.name#" name="#field.name#" value="#encodeForHTMLAttribute(fieldValue)#" maxlength="#field.maximum#" <cfif field.kind EQ 'integer'>type="number" min="0" max="2147483647" step="1"<cfelse>type="text"</cfif> <cfif field.requiredValue>required</cfif>></cfif>
</div></cfloop></div>
<p class="small text-muted mt-3">Códigos identificam vínculos e permanecem fixos após a criação. Cadastros em uso precisam ter seus vínculos preservados.</p>
<button class="btn btn-warning" type="submit">Salvar cadastro</button></form></div>
<cfif len(key)>
<details class="card card-body mb-4"><summary>Histórico do cadastro</summary><cfloop query="history"><details class="border-bottom py-3"><summary>#encodeForHTML(registrado)# · #encodeForHTML(acao)# · administrador ## #ator_id#</summary><h3 class="h6 mt-3">Antes</h3><pre class="text-break">#encodeForHTML(antes)#</pre><h3 class="h6">Depois</h3><pre class="text-break">#encodeForHTML(depois)#</pre></details></cfloop><cfif NOT history.recordCount><p class="mt-3">Sem alterações registradas nesta área.</p></cfif></details>
<details class="card card-body"><summary>Excluir cadastro sem vínculos</summary><p class="mt-3">A exclusão será recusada se houver produtos ou outros cadastros vinculados. Excluir uma configuração de filtro restaura a apresentação padrão.</p>
<form method="post"><input type="hidden" name="acao" value="excluir"><input type="hidden" name="csrf_token" value="#csrf#"><input type="hidden" name="chave" value="#encodeForHTMLAttribute(key)#"><input type="hidden" name="token" value="#token#"><div class="form-check mb-3"><input class="form-check-input" type="checkbox" id="confirmar" name="confirmar" value="sim" required><label class="form-check-label" for="confirmar">Confirmo a exclusão deste cadastro</label></div><button class="btn btn-outline-danger" type="submit">Excluir cadastro</button></form></details>
</cfif>
<cfelse>
<div class="d-flex justify-content-between align-items-center gap-3 mb-3"><h2 class="h4 mb-0">#encodeForHTML(def.title)#</h2><a class="btn btn-warning" href="./?#encodeForHTMLAttribute(returnQuery)#&novo=1">Novo registro</a></div>
<cfif entity EQ 'filtros'><div class="alert alert-info">Defina rótulo, ordem e exibição por tipo de produto. Sem configuração, o site usa o padrão. Filtros já aplicados por URL permanecem visíveis para que possam ser removidos.</div></cfif>
<cfif entity EQ 'opcoes'><div class="alert alert-info">Marcas, categorias e modelos vêm do catálogo publicado. Os demais filtros aceitam valores exatos e faixas disponíveis: peso LT200, LT225, LT250, GTE250; drop LT8, GTE8; preço LT300, LT500, LT800, LT1000, GTE1000. Gênero: M/F/U; placa: com-placa/sem-placa; amortecimento: 1 a 6.</div></cfif>
<form method="get" class="d-flex gap-2 mb-3"><input type="hidden" name="cadastro" value="#entity#"><label class="visually-hidden" for="busca-cadastro">Buscar cadastro</label><input class="form-control" id="busca-cadastro" name="busca" value="#encodeForHTMLAttribute(search)#" placeholder="Buscar cadastro" maxlength="160"><button class="btn btn-outline-light" type="submit">Buscar</button></form>
<div class="card card-body"><p class="text-muted">#records.recordCount# registros</p><div class="table-responsive"><table class="table align-middle"><thead><tr><cfloop array="#def.fields#" index="field"><cfif field.kind NEQ 'textarea'><th>#encodeForHTML(field.label)#</th></cfif></cfloop><th>Ação</th></tr></thead><tbody>
<cfloop query="records"><cfset rowData={} ><cfloop array="#def.keys#" index="keyName"><cfset rowData[keyName]=records[keyName][records.currentRow]></cfloop><tr><cfloop array="#def.fields#" index="field"><cfif field.kind NEQ 'textarea'><td>#encodeForHTML(records[field.name][records.currentRow] & '')#</td></cfif></cfloop><td><a class="btn btn-sm btn-outline-light" href="./?#encodeForHTMLAttribute(returnQuery)#&chave=#urlEncodedFormat(catalog.recordKey(def,rowData))#">Editar</a></td></tr></cfloop>
<cfif NOT records.recordCount><tr><td colspan="#arrayLen(def.fields)+1#">Nenhum cadastro encontrado.</td></tr></cfif></tbody></table></div></div>
</cfif></cfif>
</cfoutput>
