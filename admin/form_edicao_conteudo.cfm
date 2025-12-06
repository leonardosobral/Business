<div class="tab-pane fade <cfif URL.sessao EQ "conteudo">show active</cfif>" id="ex1-tabs-3" role="tabpanel" aria-labelledby="ex1-tab-3" tabindex="2">

    <form class="form" method="post">

        <div class="form-outline mb-3" data-mdb-input-init>
          <textarea class="form-control pt-3" rows="3" maxlength="150" id="txtResumo" name="resumo"><cfoutput>#qEvento.resumo#</cfoutput></textarea>
          <label class="form-label" for="txtResumo">Meta Description (entre 70 e 150 caracteres)</label>
        </div>

        <div class="input-group mb-3">
              <div data-mdb-input-init class="form-outline">
                <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlImagem" name="url_imagem" value="<cfoutput>#qEvento.url_imagem#</cfoutput>"/>
                <label class="form-label" for="txtUrlImagem">Imagem de Cabeçalho</label>
            </div>
            <cfif len(trim(qEvento.url_imagem))>
                <a target="_blank" href="<cfoutput>#qEvento.url_imagem#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                    Abrir Link
                </a>
            </cfif>
        </div>

        <div class="input-group mb-3">
              <div data-mdb-input-init class="form-outline">
                <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlImagemListagem" name="url_imagem_listagem" value="<cfoutput>#qEvento.url_imagem_listagem#</cfoutput>"/>
                <label class="form-label" for="txtUrlImagemListagem">Imagem de Listagem</label>
            </div>
            <cfif len(trim(qEvento.url_imagem_listagem))>
                <a target="_blank" href="<cfoutput>#qEvento.url_imagem_listagem#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                    Abrir Link
                </a>
            </cfif>
        </div>

        <div class="form-outline mb-3" data-mdb-input-init>
          <textarea class="form-control pt-3" rows="12" id="txtDescricao" name="descricao"><cfoutput>#qEvento.descricao#</cfoutput></textarea>
          <label class="form-label" for="txtDescricao">Descrição</label>
        </div>

        <div class="form-outline mb-3" data-mdb-input-init>
          <textarea class="form-control pt-3" rows="12" id="txtDescricaoOriginal" name="descricao_original"><cfoutput>#qEvento.descricao_original#</cfoutput></textarea>
          <label class="form-label" for="txtDescricaoOriginal">Descrição Original</label>
        </div>

        <div class="row">

            <div class="col-md-12">
                <input type="hidden" name="action" value="editar_evento_descricao"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100">Salvar Descrição</button>
            </div>

        </div>

    </form>

</div>
