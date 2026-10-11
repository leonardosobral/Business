/* Stable presentation adapter. Data-source changes belong here, not in the charts. */
(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.EstudoData = api;
})(typeof window === 'undefined' ? globalThis : window, function () {
  'use strict';
  const cache = new WeakMap();
  // These reference caveats are independent of later query revisions.
  function referenceNote(id,definition) {
    if(id==='destaques')return 'Números arredondados no PDF. O denominador dos 84,1% não foi recuperado; não equivale à cobertura do cadastro atual.';
    if(id==='variacoes_a_z')return 'O PDF rotula as variações com %. O algoritmo original não foi recuperado; não interpretar automaticamente como crescimento relativo.';
    if(id==='volume_anual'&&definition?.valores.some(v=>v.valor===null))return '??: contagens históricas exatas da página 3 pendentes; pedido ao DBA registrado no notebook. Não substituir por contagens atuais.';
    if(/^regioes_(feminino|masculino)_rotulos_visiveis$/.test(id)&&(!definition?.valores.some(v=>v.rotulo==='Norte')||definition.valores.some(v=>v.rotulo==='Norte'&&v.valor===null)))return 'Norte: ??, referência pendente com o DBA no notebook. Ausências não foram deduzidas por diferença nem os demais percentuais normalizados para 100%.';
    if(id==='perfil_cards')return 'O sinal + do PDF significa mais de esse percentual dos usuários, conforme confirmado pelo responsável; não indica crescimento.';
    return null;
  }
  function index(data) {
    if (!cache.has(data)) {
      const bySeries=new Map();
      data.comparacoes.forEach(c=>{if(!bySeries.has(c.serie))bySeries.set(c.serie,[]);bySeries.get(c.serie).push(c);});
      cache.set(data, {series:new Map(data.series.map(s=>[s.id,s])), comparison:new Map(data.comparacoes.map(c=>[JSON.stringify([c.serie,c.categoria]),c])),bySeries});
    }
    return cache.get(data);
  }
  function series(data, id, source) {
    if (!['publicado','atual'].includes(source)) throw new Error('Fonte desconhecida');
    if(data.meta?.ano===2026 && source==='publicado')throw new Error('Não existe PDF publicado de 2026');
    const idx=index(data), definition=idx.series.get(id);
    if (!definition) throw new Error('Série indisponível: '+id);
    // New calculated categories do not become historical PDF values.
    const labels=new Set(definition.valores.map(row=>row.rotulo));
    const rows=source==='atual'?definition.valores.concat((idx.bySeries.get(id)||[]).filter(c=>!labels.has(c.categoria)&&c.atual?.valor!==undefined&&c.atual?.valor!==null).map(c=>({rotulo:c.categoria}))):definition.valores;
    const values=rows.map(row=>{
      const comparison=idx.comparison.get(JSON.stringify([id,row.rotulo]));
      const current=comparison?.atual;
      const raw=source==='publicado' ? row.valor : current?.valor;
      const exact=raw===undefined || raw===null || (typeof raw==='string' && !raw.trim()) ? null : String(raw);
      if (exact!==null && ['percentual','participacoes','provas'].includes(definition.unidade) && !['number','string'].includes(typeof raw)) throw new Error('Tipo numérico inválido');
      // These cards mix units; each recalculated metric carries its own unit and precision.
      const mixed=['perfil_cards','maratonas_destaques'].includes(id);
      const unit=source==='atual'&&mixed&&current?.unidade ? current.unidade : definition.unidade;
      const decimals=source==='atual'&&mixed ? current?.casas_decimais??definition.casas_decimais??1 : definition.casas_decimais??1;
      const value=exact===null ? null : ['percentual','participacoes','provas','numero','kg','pares','km','reais'].includes(unit) ? Number(raw) : raw;
      if (typeof value==='number' && !Number.isFinite(value)) throw new Error('Valor numérico inválido');
      // A reference value cannot inherit the query or rules of its later recalculation.
      const provenance=source==='atual'?current?.fonte??null:exact===null?null:'PDF '+(data.meta?.ano||2025)+(data.meta?.pdf_versao?' · v'+data.meta.pdf_versao:'')+(definition.pagina_pdf?' · página '+definition.pagina_pdf:'');
      const note=source==='atual'?current?.nota??null:exact===null?null:'Valor transcrito do PDF; não é um recálculo.';
      const placeholder=source==='publicado'&&exact===null&&(id==='volume_anual'||(/^regioes_(feminino|masculino)_rotulos_visiveis$/.test(id)&&row.rotulo==='Norte'))?'??':undefined;
      return {label:row.rotulo,value,exact,unit,decimals,placeholder,baseLabel:source==='atual'?current?.base_rotulo:null,population:source==='atual'?current?.populacao:null,provenance,note,seriesNote:source==='atual'?definition.ressalva??null:referenceNote(id,definition),status:comparison?.status || 'nao_recalculado',count:source==='atual'?current?.contagem:null,denominator:source==='atual'?current?.denominador:null};
    });
    return {id,source,unit:definition.unidade,decimals:definition.casas_decimais??1,page:definition.pagina_pdf,note:source==='atual'?definition.ressalva:referenceNote(id,definition),values,available:values.some(v=>v.value!==null),partial:values.some(v=>v.value===null)};
  }
  const escape = value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function csv(rows) {
    const cell=value=>{let s=value===null||value===undefined?'':String(value);if(typeof value!=='number'&&/^[\s]*[=+@-]/.test(s))s="'"+s;return '"'+s.replace(/"/g,'""')+'"';};
    return '\uFEFF'+[['Série','Categoria','Valor','Unidade','Contagem','Denominador','Fonte','Leitura','Nota','Ressalva','Base','População'],...rows.map(r=>[r.series,r.label,r.exact??r.value,r.unit,r.count,r.denominator,r.provenance??(r.exact!=null||r.value!=null?'Fonte não informada por indicador':''),({atual:'Recálculo atual',publicado:'Publicado no PDF'})[r.source]??r.source,r.note,r.seriesNote,r.baseLabel,r.population])].map(r=>r.map(cell).join(';')).join('\r\n');
  }
  function format(value,unit='percentual',decimals=1) {
    if (value===null||value===undefined) return '??';
    if (typeof value!=='number') return String(value).replace(/(\d)\.(\d)(?=.*%|Mi|mil)/g,'$1,$2');
    if (unit==='reais') return new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL',minimumFractionDigits:2,maximumFractionDigits:2}).format(value);
    return new Intl.NumberFormat('pt-BR',{maximumFractionDigits:['participacoes','provas'].includes(unit)?0:decimals,minimumFractionDigits:0}).format(value)+({percentual:'%',kg:' kg',km:' km',pares:' pares'}[unit]||'');
  }
  function donutSegments(values) {
    let start=0;
    return values.map(value=>{const length=typeof value==='number'&&Number.isFinite(value)?Math.max(0,Math.min(value,100-start)):0;const arc={start,length};start+=length;return arc;});
  }
  function highlights(data,source) {
    const published=series(data,'destaques',source);
    if (source==='publicado') return published.values.map((v,i)=>({...v,series:'destaques',source,unit:'texto_publicado',display:format(v.value,'texto_publicado').replace('Mi',' mi').replace('mil',' mil'),context:['Participações consolidadas no estudo.','Total publicado na edição 2025.','Cobertura informada no PDF.'][i]}));
    const mapped=data.meta?.mapeamento&&idxMapping(data);
    return [
      {label:data.meta?.ano===2025&&data.meta?.totais_fontes?.resultados?'Resultados':'Resultados concluintes',value:data.totais_atuais?.resultados??null,unit:'participacoes',context:data.meta?.totais_fontes?.resultados||'Status 0, homologados e filtro de conclusão.'},
      {label:'Eventos cadastrados',value:data.totais_atuais?.eventos??null,unit:'eventos',context:data.meta?.totais_fontes?.eventos||(data.meta?.ano===2026?'Eventos no Brasil até 26/09/2026.':'Eventos no Brasil com encerramento em 2025.')},
      {label:'Provas mapeadas',value:null,unit:'percentual',...mapped,context:mapped?format(mapped.count,'provas')+' de '+format(mapped.denominator,'provas')+' provas ativas no calendário; cada prova uma vez.':'Cobertura ainda sem denominador validado.'}
    ].map((v,i)=>({...v,series:i===2&&mapped?'mapeamento_real':'destaques',source,provenance:i<2?data.meta?.totais_fontes?.[i===0?'resultados':'eventos']??null:v.provenance??null,note:v.context,display:v.value===null?'??':i===0?format(v.value/1e6,'numero',2)+' mi':format(v.value,i===2?'percentual':'participacoes')}));
  }
  function idxMapping(data){
    if(!index(data).series.has('mapeamento_real'))return null;
    return series(data,'mapeamento_real','atual').values.find(v=>v.label===data.meta.mapeamento.destaque_categoria&&v.value!==null)||null;
  }
  function exportAll(data,source) {
    // Mapping already has its own complete series; the headline must not duplicate it.
    return data.series.flatMap(s=>s.id==='destaques'?highlights(data,source).filter(v=>v.series!=='mapeamento_real'):series(data,s.id,source).values.map(v=>({...v,series:s.id,unit:v.unit,source})));
  }
  return {series,escape,csv,format,donutSegments,highlights,exportAll};
});
