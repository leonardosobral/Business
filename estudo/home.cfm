<cfoutput><div id="study-app" class="business-page study-page" data-csrf="#encodeForHTMLAttribute(SESSION.estudoCsrf)#">
<div class="business-page-card">
  <div class="business-page-header">
    <div><div class="study-eyebrow">ADMINISTRAÇÃO · PESQUISA E DADOS</div><h1 class="business-page-title">Estudo</h1><p class="text-muted mb-0">Queries, análises e resultados congelados, no mesmo caderno.</p></div>
    <div class="study-actions"><button type="button" class="btn btn-link btn-sm" id="rename-book">Renomear caderno</button><button type="button" class="btn btn-outline-warning btn-sm" id="new-book">Novo caderno</button></div>
  </div>
  <div class="study-selectors">
    <label>Caderno<select id="study-book" class="form-select" aria-label="Caderno"></select></label>
    <label>Seção<select id="study-section" class="form-select" aria-label="Seção"></select></label>
    <button type="button" id="new-section" class="btn btn-outline-light btn-sm">Nova seção</button>
  </div>
  <div id="study-notice" class="study-notice" role="status" aria-live="polite">Carregando o acervo…</div>
  <div id="study-composer" hidden></div>
  <div class="study-tabs" role="tablist" aria-label="Visualização do caderno">
    <button type="button" class="active" id="tab-notebook" data-tab="notebook" role="tab" aria-selected="true" aria-controls="panel-notebook">Caderno</button>
    <button type="button" id="tab-runs" data-tab="runs" role="tab" aria-selected="false" aria-controls="panel-runs">Execuções e congelados</button>
    <button type="button" id="tab-guide" data-tab="guide" role="tab" aria-selected="false" aria-controls="panel-guide">Como usar</button>
  </div>
</div>
<section id="panel-notebook" role="tabpanel" aria-labelledby="tab-notebook">
  <div class="study-toolbar"><h2 id="section-title" class="h5 mb-0"></h2><div class="study-actions">
    <button type="button" id="archived-cells" class="btn btn-link btn-sm">Células arquivadas</button>
    <button type="button" id="rename-section" class="btn btn-link btn-sm">Renomear</button>
    <button type="button" id="discard" class="btn btn-outline-light btn-sm" hidden>Descartar alterações locais</button>
    <button type="button" id="add-sql" class="btn btn-warning btn-sm">+ SQL</button>
    <button type="button" id="add-text" class="btn btn-outline-light btn-sm">+ Texto</button>
    <button type="button" id="add-html" class="btn btn-outline-light btn-sm">+ HTML</button>
  </div></div>
  <div id="study-cells"></div>
</section>
<section id="panel-runs" role="tabpanel" aria-labelledby="tab-runs" hidden>
  <div class="study-toolbar"><h2 class="h5 mb-0">Histórico desta seção</h2><button type="button" id="refresh-runs" class="btn btn-outline-light btn-sm">Atualizar</button></div>
  <div id="study-runs"></div><div id="study-run-detail"></div>
</section>
<section id="panel-guide" role="tabpanel" aria-labelledby="tab-guide" hidden>
  <div class="study-card study-guide">
    <h2 class="h5">Da consulta ao resultado preservado</h2>
    <ol><li>Escolha um caderno e uma seção. Use células SQL para consultas e Texto para metodologia e observações.</li><li>Salve suas alterações. Cada salvamento cria uma revisão com data e autor. Se outra pessoa salvar antes, seu texto permanece no editor para comparação.</li><li>Execute a célula SQL inteira ou selecione uma única consulta. O botão salva a revisão antes de executar.</li><li>Confira a tabela e clique em <strong>Congelar resultado</strong>. Dê um título e registre o recorte e as ressalvas. O resultado exibido será preservado, sem nova consulta.</li></ol>
    <p>Consultas de leitura: até 45 segundos, 1.000 linhas, 100 colunas e 5 MB por execução. Resultados incompletos ficam identificados e precisam ser refinados antes do congelamento. Funções administrativas ou não habilitadas são recusadas.</p>
    <h3 class="h6">Acervo de 2025</h3><p>As células do editor antigo foram preservadas. Seus blocos HTML são resultados colados manualmente e podem corresponder a uma versão anterior da query. Eles não equivalem a um congelamento verificado.</p>
    <p>O caderno de fontes reúne os arquivos do DBA e do DataGrip e as observações de conciliação. Scripts de manutenção ficam registrados para consulta; a execução aqui aceita apenas SELECT e WITH de leitura.</p>
    <p class="mb-0">Esta área é exclusiva de administradores. A versão web do estudo será integrada em uma próxima etapa.</p>
  </div>
</section>
<dialog id="revision-dialog" class="study-dialog"><div class="study-toolbar"><h2 id="revision-title" class="h5 mb-0">Revisões da célula</h2><button type="button" id="close-revisions" class="btn btn-outline-light btn-sm">Fechar</button></div><div id="revision-list"></div></dialog>
</div></cfoutput>