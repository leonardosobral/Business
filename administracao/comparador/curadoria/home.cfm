<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<h1 class="h3">Comparador · Curadoria</h1>
<cfinclude template="../includes/navigation.cfm">
<cfoutput>
<cfif NOT ready>
 <div class="alert alert-warning" role="status">A curadoria aguarda a atualização das configurações no banco.</div>
<cfelse>
 <nav class="nav nav-tabs flex-nowrap overflow-auto mb-4" aria-label="Configurações da curadoria">
  <a class="nav-link flex-shrink-0 text-nowrap <cfif tab EQ 'marcas'>active</cfif>" href="./?aba=marcas" <cfif tab EQ 'marcas'>aria-current="page"</cfif>>Marcas</a>
  <a class="nav-link flex-shrink-0 text-nowrap <cfif tab EQ 'home'>active</cfif>" href="./?aba=home" <cfif tab EQ 'home'>aria-current="page"</cfif>>Página inicial</a>
  <a class="nav-link flex-shrink-0 text-nowrap <cfif tab EQ 'historico'>active</cfif>" href="./?aba=historico" <cfif tab EQ 'historico'>aria-current="page"</cfif>>Histórico</a>
 </nav>
 <cfif len(error)><div class="alert alert-danger" role="alert">#encodeForHTML(error)#</div></cfif>
 <cfif guard.field(URL,'salvo',1) EQ '1'><div class="alert alert-success" role="status">Curadoria salva com histórico.</div></cfif>
 <cfif conflict>
  <p><a href="./?aba=#tab#<cfif tab EQ 'marcas'>&pagina=#requestedBrandPage#</cfif>">Reabrir configuração atualizada</a></p>
 <cfelseif tab EQ 'marcas'>
  <div class="card card-body mb-4">
   <h2 class="h4">Marcas em destaque e presença no Brasil</h2>
   <p>Escolha as marcas que aparecem primeiro no filtro e identifique as que estão presentes no Brasil. As escolhas são independentes.</p>
   <p class="small text-muted">Todas as marcas do cadastro aparecem nesta lista. O site mostra no filtro apenas as que têm produtos disponíveis; as demais ficam em “Mostrar mais”, em ordem alfabética. A presença no Brasil também ajuda a priorizar os modelos da página inicial.</p>
   <p class="small">Página #brandPage# de #brandPages# · #arrayLen(brandRows)# marcas. Salve as alterações desta página antes de mudar para outra.</p>
   <form method="post" action="./?aba=marcas&pagina=#brandPage#">
    <input type="hidden" name="acao" value="marcas"><input type="hidden" name="csrf_token" value="#encodeForHTMLAttribute(csrf)#"><input type="hidden" name="token" value="#current.token#"><input type="hidden" name="escopo_tags" value="#encodeForHTMLAttribute(brandScope)#">
    <div class="table-responsive"><table class="table align-middle"><caption class="visually-hidden">Configuração das marcas do Comparador</caption><thead><tr><th scope="col">Marca</th><th scope="col">Em destaque</th><th scope="col">Presente no Brasil</th></tr></thead><tbody>
     <cfloop array="#brandPageRows#" index="brand"><tr>
      <th scope="row">#encodeForHTML(brand.marca)#</th>
      <td><div class="form-check"><input type="checkbox" class="form-check-input" id="destaque_#encodeForHTMLAttribute(brand.tag_marca)#" name="destaque_#encodeForHTMLAttribute(brand.tag_marca)#" value="true" <cfif curadoriaChecked(brand,'destaque_','destaque')>checked</cfif>><label class="form-check-label visually-hidden" for="destaque_#encodeForHTMLAttribute(brand.tag_marca)#">Destacar #encodeForHTML(brand.marca)#</label></div></td>
      <td><div class="form-check"><input type="checkbox" class="form-check-input" id="brasil_#encodeForHTMLAttribute(brand.tag_marca)#" name="brasil_#encodeForHTMLAttribute(brand.tag_marca)#" value="true" <cfif curadoriaChecked(brand,'brasil_','presente_brasil')>checked</cfif>><label class="form-check-label visually-hidden" for="brasil_#encodeForHTMLAttribute(brand.tag_marca)#">#encodeForHTML(brand.marca)# presente no Brasil</label></div></td>
     </tr></cfloop>
     <cfif NOT arrayLen(current.data.marcas)><tr><td colspan="3">Nenhuma marca cadastrada.</td></tr></cfif>
    </tbody></table></div>
    <input type="hidden" name="formulario_completo" value="curadoria">
    <cfif arrayLen(brandPageRows)><button class="btn btn-warning" type="submit">Salvar marcas desta página</button></cfif>
   </form>
   <cfif brandPages GT 1><nav class="d-flex flex-wrap align-items-center gap-3 mt-3" aria-label="Páginas de marcas">
    <cfif brandPage GT 1><a class="btn btn-outline-light" href="./?aba=marcas&pagina=#brandPage-1#" aria-label="Página anterior de marcas">Anterior</a></cfif>
    <span>Página #brandPage# de #brandPages#</span>
    <cfif brandPage LT brandPages><a class="btn btn-outline-light" href="./?aba=marcas&pagina=#brandPage+1#" aria-label="Próxima página de marcas">Próxima</a></cfif>
   </nav></cfif>
  </div>
 <cfelseif tab EQ 'home'>
  <div class="card card-body mb-4">
   <h2 class="h4">Proporção da página inicial</h2>
   <p>Ajuste a proporção de lançamentos e ofertas na seleção “Destaques”.</p>
   <details class="small text-muted mb-3"><summary>Como a seleção é formada</summary><p class="mt-2 mb-0">Entre os produtos sem oferta, a seleção prioriza lançamentos dos últimos 12 meses e completa com modelos anteriores quando necessário. Produtos com oferta válida entram apenas no grupo de ofertas. Marcas presentes no Brasil têm prioridade; protótipos e lançamentos futuros continuam fora da entrada. Quando faltam produtos em um grupo, a seleção aproveita os disponíveis no outro.</p></details>
   <form method="post" action="./?aba=home">
    <input type="hidden" name="acao" value="home"><input type="hidden" name="csrf_token" value="#encodeForHTMLAttribute(csrf)#"><input type="hidden" name="token" value="#current.token#">
    <div class="row g-3 mb-3">
     <div class="col-12 col-md-6"><label class="form-label" for="lancamentos_por_ciclo">Lançamentos por ciclo</label><input class="form-control" type="number" min="1" max="10" step="1" required id="lancamentos_por_ciclo" name="lancamentos_por_ciclo" value="#encodeForHTMLAttribute(curadoriaCount('lancamentos_por_ciclo'))#" aria-describedby="curadoria-proporcao"></div>
     <div class="col-12 col-md-6"><label class="form-label" for="ofertas_por_ciclo">Produtos com oferta por ciclo</label><input class="form-control" type="number" min="1" max="10" step="1" required id="ofertas_por_ciclo" name="ofertas_por_ciclo" value="#encodeForHTMLAttribute(curadoriaCount('ofertas_por_ciclo'))#" aria-describedby="curadoria-proporcao"></div>
    </div>
    <p id="curadoria-proporcao" role="status" aria-live="polite">Proporção salva: #current.data.home.lancamentos_por_ciclo# #current.data.home.lancamentos_por_ciclo EQ 1?'lançamento':'lançamentos'# para #current.data.home.ofertas_por_ciclo# #current.data.home.ofertas_por_ciclo EQ 1?'produto':'produtos'# com oferta por ciclo.</p>
    <p class="small text-muted">Use quantidades inteiras de 1 a 10. A proporção orienta a ordem; o mesmo produto aparece uma vez.</p>
    <input type="hidden" name="formulario_completo" value="curadoria">
    <button class="btn btn-warning" type="submit">Salvar proporção</button>
   </form>
  </div>
  <script>
  (function(){
   const launches=document.getElementById('lancamentos_por_ciclo');
   const offers=document.getElementById('ofertas_por_ciclo');
   const preview=document.getElementById('curadoria-proporcao');
   function update(){
    if(!launches.validity.valid||!offers.validity.valid){preview.textContent='Informe quantidades inteiras de 1 a 10 para visualizar a proporção.';return;}
    const launchCount=Number(launches.value);const offerCount=Number(offers.value);
    preview.textContent='Prévia: '+launchCount+' '+(launchCount===1?'lançamento':'lançamentos')+' para '+offerCount+' '+(offerCount===1?'produto':'produtos')+' com oferta por ciclo ('+(launchCount+offerCount)+' posições).';
   }
   launches.addEventListener('input',update);offers.addEventListener('input',update);update();
  })();
  </script>
 <cfelse>
  <div class="card card-body mb-4"><h2 class="h4">Histórico da curadoria</h2>
   <cfloop query="history"><cfset change=curadoriaHistoryItem(antes,depois)><details class="border-bottom py-3"><summary>#encodeForHTML(registrado)# · administrador ## #ator_id#</summary>
    <cfif change.available>
     <cfif change.ratioChanged><p class="mt-3">Proporção: #change.launchBefore# lançamentos / #change.offerBefore# ofertas → #change.launchAfter# lançamentos / #change.offerAfter# ofertas por ciclo.</p></cfif>
     <cfif arrayLen(change.brands)><div class="table-responsive mt-3"><table class="table"><thead><tr><th scope="col">Marca</th><th scope="col">Destaque antes → depois</th><th scope="col">Brasil antes → depois</th></tr></thead><tbody>
      <cfloop array="#change.brands#" index="changedBrand"><tr><th scope="row">#encodeForHTML(changedBrand.name)#</th><td>#changedBrand.featuredBefore?'Sim':'Não'# → #changedBrand.featuredAfter?'Sim':'Não'#</td><td>#changedBrand.brazilBefore?'Sim':'Não'# → #changedBrand.brazilAfter?'Sim':'Não'#</td></tr></cfloop>
     </tbody></table></div></cfif>
     <cfif NOT change.ratioChanged AND NOT arrayLen(change.brands)><p class="mt-3 mb-0">Configuração salva sem mudanças na proporção ou nas marcas.</p></cfif>
    <cfelse><p class="mt-3 mb-0">O resumo desta alteração não está disponível.</p></cfif>
   </details></cfloop>
   <cfif NOT history.recordCount><p class="mb-0">Sem alterações registradas nesta área.</p></cfif>
  </div>
 </cfif>
</cfif>
</cfoutput>
