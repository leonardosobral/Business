<cfoutput><div id="study-app" class="business-page study-page" data-csrf="#encodeForHTMLAttribute(SESSION.estudoCsrf)#">
<div class="business-page-card">
  <div class="business-page-header">
    <div><div class="study-eyebrow">ADMINISTRAÇÃO · PESQUISA E DADOS</div><h1 class="business-page-title">Estudo</h1><p class="text-muted mb-0">Consultas de 2025 e 2026, resultados congelados e publicação web no mesmo caderno.</p></div>
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
    <button type="button" id="tab-web" data-tab="web" role="tab" aria-selected="false" aria-controls="panel-web">Versão web</button>
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
<section id="panel-web" role="tabpanel" aria-labelledby="tab-web" hidden>
 <div class="study-card">
  <h2 class="h5">Versão web do estudo</h2>
  <p>Executar e congelar preserva os dados. Somente <strong>Usar na versão web</strong> troca a edição disponível no link público. Esta é uma prévia em conciliação, sem divulgação na página do PDF.</p>
  <p>Cada edição combina resultados congelados identificados nas fontes. Um indicador pode ter população e data de coleta próprias; atualizar um recorte não recalcula automaticamente os totais ou comparativos. Confira as fontes antes de substituir uma versão.</p>
  <div class="study-selectors"><label>Edição<select id="web-year" class="form-select" aria-label="Edição para web"></select></label><label>Resultado congelado<select id="web-run" class="form-select" aria-label="Congelamento para web"></select></label><button type="button" id="web-refresh" class="btn btn-outline-light btn-sm">Atualizar versões</button></div>
  <p id="web-current" class="study-meta"></p><div class="study-actions"><a id="web-notebook" class="btn btn-outline-light btn-sm">Abrir query de saída</a><a id="web-live" class="btn btn-outline-light btn-sm" target="_blank" rel="noopener">Abrir versão no ar</a><button type="button" id="web-preview" class="btn btn-warning btn-sm">Conferir pacote</button></div>
  <div id="web-preview-content" class="mt-3"></div>
  <div id="web-publish-area" hidden><label class="d-block my-3">Nota pública desta versão<textarea id="web-note" class="form-control" maxlength="2000" placeholder="Origem dos resultados, recorte e ressalvas mantidas nesta versão"></textarea></label><button type="button" id="web-publish" class="btn btn-warning btn-sm">Usar na versão web</button></div>
 </div>
</section>

<section id="panel-guide" role="tabpanel" aria-labelledby="tab-guide" hidden>
  <div class="study-card study-guide">
    <h2 class="h5">Da consulta ao resultado preservado</h2><p>Use o caderno <strong>Brasil que Corre Provas — Estudo e publicação</strong>. As seções de 2025 reúnem as consultas por página do PDF e a saída para web; 2026 tem sua própria seção de saída. Fontes e legado ficam como referências históricas.</p><p>Depois de corrigir uma consulta e congelar o resultado, atualize a execução usada na seção <strong>Saída para web</strong> do mesmo caderno. Execute, congele e confira o pacote na aba <strong>Versão web</strong> antes de ativá-lo.</p>
    <ol><li>Escolha um caderno e uma seção. Use células SQL para consultas e Texto para metodologia e observações.</li><li>Salve suas alterações. Cada salvamento cria uma revisão com data e autor. Se outra pessoa salvar antes, seu texto permanece no editor para comparação.</li><li>Execute a célula SQL inteira ou selecione uma única consulta. O botão salva a revisão antes de executar.</li><li>Confira a tabela e clique em <strong>Congelar resultado</strong>. Dê um título e registre o recorte e as ressalvas. O resultado exibido será preservado, sem nova consulta.</li></ol>
    <p>Consultas de leitura: até 45 segundos, 1.000 linhas, 100 colunas e 5 MB por execução. Resultados incompletos ficam identificados e precisam ser refinados antes do congelamento. Funções administrativas ou não habilitadas são recusadas.</p>
    <h3 class="h6">Acervo de 2025</h3><p>As células do editor antigo foram preservadas. Seus blocos HTML são resultados colados manualmente e podem corresponder a uma versão anterior da query. Eles não equivalem a um congelamento verificado.</p>
    <p>O caderno de fontes reúne os arquivos do DBA e do DataGrip e as observações de conciliação. Scripts de manutenção ficam registrados para consulta; a execução aqui aceita apenas SELECT e WITH de leitura.</p>
    <p class="mb-0">Esta área é exclusiva de administradores. Na aba Versão web, confira um congelamento das células de saída e use-o na prévia pública. Salvar, executar ou congelar uma query não muda automaticamente a web.</p>
  </div>
</section>
<dialog id="revision-dialog" class="study-dialog"><div class="study-toolbar"><h2 id="revision-title" class="h5 mb-0">Revisões da célula</h2><button type="button" id="close-revisions" class="btn btn-outline-light btn-sm">Fechar</button></div><div id="revision-list"></div></dialog>
</div></cfoutput>