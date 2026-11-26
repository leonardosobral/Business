(function () {
  'use strict';
  const A=window.EstudoData, G=window.EstudoCharts, esc=A.escape, fmt=A.format;
  const year=new URL(location.href).searchParams.get('ano')==='2026'?2026:2025;
  const PDF='https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf';
  const palette=['#f5b21b','#666666','#999999','#c6c6c6','#eeeeee'];
  const monthColors=['#adb979','#9eb457','#74ac52','#43a367','#14a18b','#209a9e','#3584a0','#3e769c','#595b9a','#79609a','#a36e9c','#b685ac'];
  const sexColors=['#df4663','#3c73cc','#999999'];
  const distanceColors=G.colors.distance;
  const sportColors=['#427fc2','#26b69e','#f6b719','#269961','#e34949',...Array(6).fill('#a9aca1')];
  const ageColors=['#334d64','#25728e','#178d9e','#11a8ac','#24b9a1','#60c493','#8cce7f','#b3ca68','#d0b659','#e6a153','#e98466','#dc6d73'];
  const faixaColors=['#ffffff','#ff771c','#f5b21b','#4886c2','#f44346','#895e29','#111111','#c6c6c6'];
  const state={source:year===2026||new URL(location.href).searchParams.get('fonte')==='atual'?'atual':'publicado',age:'geral',generation:'geral',performance:'geral',region:'Sudeste'};
  let data,exportRows=new Map(),cardId=0;
  const label = value=>({F:'Feminino',M:'Masculino',X:'Outros / não informado','1':'1º trimestre','2':'2º trimestre','3':'3º trimestre','4':'4º trimestre'}[value]||value);
  const get=id=>A.series(data,id,state.source);
  const empty=()=>'<div class="empty-state">'+(year===2026?'<strong>??</strong><br>Valor em revisão. Este indicador será preenchido após a validação da fonte.':'Ainda não recalculado.<br>Este recorte está disponível na opção “Publicado no PDF”.')+'</div>';
  const note=text=>'<p class="chapter-note">'+esc(text)+'</p>';
  function segments(key,values){return '<div class="segmented" role="group" aria-label="'+esc({age:'Gênero nas faixas etárias',generation:'Gênero nas gerações',performance:'Gênero no ritmo'}[key])+'">'+values.map(([v,l])=>'<button type="button" data-control="'+key+'" data-value="'+v+'" aria-pressed="'+(state[key]===v)+'">'+l+'</button>').join('')+'</div>';}
  const genderOptions=[['geral','Todos'],['F','Feminino'],['M','Masculino']];
  // A chapter may span several reading pages; its first page keeps the navigation anchor.
  function section(id,num,title,description,content,dark=false,control='') {
    const pages=Array.isArray(content)?content:[{content}];
    return pages.map((page,index)=>{
      const pageId=id+(index?'-'+(index+1):''),heading=page.title||title;
      return '<section class="chapter report-page '+(dark?'section-dark':'')+'" id="'+pageId+'" aria-labelledby="'+pageId+'-title"><div class="wrap"><div class="chapter-heading"><div><span class="section-number">CAPÍTULO '+num+(index?' · CONTINUAÇÃO':'')+'</span><h2 id="'+pageId+'-title">'+heading+'</h2>'+((page.description||description)?'<p>'+esc(page.description||description)+'</p>':'')+'</div>'+(index?'':control)+'</div><div class="page-content">'+page.content+'</div></div></section>';
    }).join('');
  }
  function numberPages(){
    const pages=document.querySelectorAll('#content > section');
    pages.forEach((page,index)=>{
      page.classList.add('report-page');
      const header=document.createElement('div');header.className='page-running-head';
      header.innerHTML='<span>O BRASIL QUE CORRE <b>PROVAS</b></span><span>'+year+(year===2026?(document.body.dataset.annualDraft==='true'?' · ANUAL EM PREPARAÇÃO':' · PARCIAL'):' · ESTUDO')+'</span>';
      page.prepend(header);
      const footer=document.createElement('footer');footer.className='page-footer';
      footer.innerHTML='<span>ROAD RUNNERS <span class="page-source">/ '+(year===2026?'BASE CONGELADA':state.source==='publicado'?'PUBLICADO NO PDF':'RECÁLCULO ATUAL')+'</span></span><span>PÁGINA '+String(index+1).padStart(2,'0')+' <span class="page-total">/ '+pages.length+'</span></span>';
      page.append(footer);
    });
  }
  function seriesCaption(id){
    const named={maratonas_concluintes:'Concluintes',maratonas_feminino:'Feminino',maratonas_masculino:'Masculino',maratonas_top10:'Top 10',maratonas_top100:'Top 100',maratonas_top5pct:'Melhores 5%',maratonas_top10pct:'Melhores 10%',maratonas_top50pct:'Melhores 50%',maratonas_medalhas_ouro:'Ouro',maratonas_medalhas_prata:'Prata',maratonas_medalhas_bronze:'Bronze',maratonas_tempo_menor:'Menor tempo',maratonas_tempo_medio:'Tempo médio',maratonas_tempo_mediano:'Mediana',regioes_feminino_rotulos_visiveis:'Feminino',regioes_masculino_rotulos_visiveis:'Masculino',volume_anual:'Resultados',eventos_anuais_cadastrados:'Provas cadastradas',eventos_anuais_coletados:'Com resultado coletado',eventos_anuais_elegiveis:'Com resultado elegível',variacao_volume_anual:'Variação dos resultados'};
    if(named[id])return named[id];
    const marathon=id.match(/^maratonas_(sub4|sub3|sub2h30)_(percentual|contagem)$/);
    if(marathon)return {sub4:'Sub 4h',sub3:'Sub 3h',sub2h30:'Sub 2h30'}[marathon[1]]+' · '+(marathon[2]==='contagem'?'Concluintes':'Percentual');
    if(id.startsWith('comparativo_mensal_'))return id.slice(-4);
    const p=id.match(/^comparativo_provas_(resumo|cadastradas|coletadas)_(2025|2026)$/);if(p)return p[2]+({resumo:'',cadastradas:' · Cadastradas',coletadas:' · Com resultado coletado'}[p[1]]);
    const m=id.match(/^(?:geracoes|sexo|regioes)_(20\d\d)(?:_(.*))?$/);if(m)return m[1]+(!m[2]||m[2]==='geral'?'':' · '+label(m[2]));
    return label(id.replace(/^(sexo_dentro_distancia_|geracao_dentro_distancia_|distancia_dentro_geracao_|distancia_dentro_sexo_)/,''));
  }
  const namedSeries=id=>({...get(id),caption:seriesCaption(id)});
  function valueTable(sets,headings,first='Categoria'){
    if(!sets.some(s=>s.available||s.values.some(v=>v.placeholder)))return empty();
    const labels=[...new Set(sets.flatMap(s=>s.values.map(v=>v.label)))];
    return '<div class="table-scroll" tabindex="0" role="region" aria-label="Tabela de '+esc(first.toLowerCase())+'"><table class="data-table parity-table"><thead><tr><th scope="col">'+esc(first)+'</th>'+headings.map(h=>'<th scope="col">'+esc(h)+'</th>').join('')+'</tr></thead><tbody>'+labels.map(l=>'<tr><th scope="row">'+esc(label(l))+'</th>'+sets.map(s=>'<td>'+esc(s.values.find(v=>v.label===l)?.placeholder||fmt(s.values.find(v=>v.label===l)?.value??null,s.unit,s.decimals))+'</td>').join('')+'</tr>').join('')+'</tbody></table></div>';
  }
  function timeIntervals(series){
    const rows=series.values.filter(v=>v.value!==null&&v.note);
    if(state.source!=='atual'||!rows.length)return '';
    return '<details class="data-details time-intervals"><summary>Intervalos usados no cálculo</summary><div class="table-scroll"><table class="data-table"><thead><tr><th scope="col">Faixa</th><th scope="col">Tempo de conclusão</th></tr></thead><tbody>'+rows.map(v=>'<tr><th scope="row">'+esc(v.label)+'</th><td>'+esc(v.note)+'</td></tr>').join('')+'</tbody></table></div></details>';
  }
  function fact(value,title,text){return '<aside class="report-fact"><strong>'+esc(value)+'</strong><h3>'+esc(title)+'</h3><p>'+esc(text)+'</p></aside>';}
  // Presentation derives only from the selected frozen series. Missing values stay missing.
  function tableDetails(content,title='Comparar todos os valores na tabela'){
    return '<details class="data-details comparison-details"><summary>'+esc(title)+'</summary>'+content+'</details>';
  }
  function seriesTiles(sets,headings,{primary=0,context=''}={}){
    const labels=[...new Set(sets.flatMap(s=>s.values.map(v=>v.label)))];
    if(!sets.some(s=>s.available))return empty();
    const display=(s,name)=>{const v=s.values.find(v=>v.label===name);return v?.placeholder||fmt(v?.value??null,s.unit,s.decimals);};
    return '<div class="reading-tiles">'+labels.map(name=>'<article class="reading-tile"><h4>'+esc(label(name))+'</h4><div class="tile-primary"><span>'+esc(headings[primary])+'</span><strong>'+esc(display(sets[primary],name))+'</strong></div>'+(context?'<p>'+esc(context)+'</p>':'')+'<dl>'+sets.map((s,i)=>i===primary?'':'<div><dt>'+esc(headings[i])+'</dt><dd>'+esc(display(s,name))+'</dd></div>').join('')+'</dl></article>').join('')+'</div>';
  }
  function timeSeconds(value){
    const m=typeof value==='string'&&value.match(/^(\d+):([0-5]\d):([0-5]\d(?:\.\d+)?)$/);
    if(!m)return null;
    const seconds=Number(m[1])*3600+Number(m[2])*60+Number(m[3]);
    return seconds>0?seconds:null;
  }
  function timeBoard(sets,headings,primary=2){
    if(!sets.some(s=>s.available))return empty();
    const featured=sets.length===3?[0,1,2]:[0,1,4];
    const leaders=featured.map(i=>{
      const rows=sets[i].values.map(v=>({...v,seconds:timeSeconds(v.value)})).filter(v=>v.seconds!==null);
      if(!rows.length)return '';
      const minimum=Math.min(...rows.map(v=>v.seconds)),winners=rows.filter(v=>v.seconds===minimum);
      return fact(fmt(winners[0].value,sets[i].unit,sets[i].decimals),(sets.length===3?['Menor tempo da seleção','Menor tempo médio','Menor mediana'][i]:headings[i]+' · menor média'),winners.map(v=>v.label).join(' / ')+(winners.length>1?' · empate':''));
    }).join('');
    return '<div class="time-leaders">'+leaders+'</div>'+seriesTiles(sets,headings,{primary})+tableDetails(valueTable(sets,headings,'Prova'));
  }
  function rankedDistribution(series){
    if(!series.available)return empty();
    const sorted={...series,values:[...series.values].sort((a,b)=>(b.value??-Infinity)-(a.value??-Infinity))};
    const known=sorted.values.filter(v=>typeof v.value==='number'&&Number.isFinite(v.value));
    const winners=known.length?known.filter(v=>v.value===known[0].value):[];
    return (winners.length?fact(fmt(winners[0].value,series.unit,series.decimals),'Maior participação na distribuição',winners.map(v=>v.label).join(' / ')+(winners.length>1?' · empate':'')):'')+bars(sorted,[palette[0]],{wide:true})+tableDetails(valueTable([series],['Participação'],'UF'));
  }
  function generalCosts(){
    const meta=data.meta.inscricoes_geral;
    if(year!==2026||!meta||!['inscricoes_geral_resumo','inscricoes_geral_cobertura','inscricoes_geral_faixas'].every(id=>data.series.some(s=>s.id===id)))return '';
    const summary=get('inscricoes_geral_resumo'),coverage=get('inscricoes_geral_cobertura'),bands=get('inscricoes_geral_faixas');
    const stats=summary.values.map(v=>'<div class="metric"><span>'+esc(v.label)+' · categoria geral</span><strong>'+esc(fmt(v.value,'reais',2))+'</strong><small>Menor preço capturado por prova · '+fmt(meta.analisadas,'provas')+' provas</small></div>').join('');
    const known=coverage.values.find(v=>v.label==='Categoria geral identificada');
    const cut=(key,title)=>{if(!['mediana','media','amostra'].every(x=>data.series.some(s=>s.id==='inscricoes_geral_'+key+'_'+x)))return '<article class="chart-card"><h3>'+esc(title)+'</h3><div class="empty-state">Sem preços gerais analisáveis neste recorte.</div></article>';const sets=['mediana','media','amostra'].map(x=>get('inscricoes_geral_'+key+'_'+x));return card(title,'Menor preço de cada prova dentro do rótulo identificado',sets,bars(sets[0],[palette[0]],{wide:true})+valueTable(sets,['Mediana','Média','Provas'],'Rótulo capturado'));};
    return section('inscricoes-geral','08','O preço da categoria geral.','Calendário de rua no Brasil · 01/01 a '+(data.meta.escopo_trimestres===3?'30/09/2026':'31/12/2026, incluindo futuras')+'.',[
      {content:'<div class="metrics">'+stats+'<div class="metric"><span>Categoria geral identificada</span><strong>'+esc(fmt(known?.value??null))+'</strong><small>'+fmt(meta.analisadas,'provas')+' de '+fmt(meta.calendario,'provas')+' provas cadastradas</small></div></div>'+note('Cada prova tem o mesmo peso: seu menor preço acima de R$ 0,01 entre opções explicitamente gerais ou adultas. A classificação exclui descontos, PCD, idosos, kids, restrições não interpretadas, contrapartidas em alimentos e indisponibilidade explícita. É uma amostra conservadora de ofertas capturadas; preços baixos válidos continuam na análise.')+'<div class="grid grid-2">'+card('Preço geral por faixa','Uma referência por prova',bands,meta.analisadas?bars(bands,['#43bd9a','#4886c2','#f5b21b','#e98466','#666666'],{wide:true}):'<div class="empty-state">Sem preços gerais analisáveis.</div>')+card('A amostra identificada','Opções ambíguas permanecem pendentes',coverage,donut(coverage,[palette[0],'#666666','#c6c6c6'],'2026','PREÇOS'))+'</div>'+note('A referência ainda reúne diferentes distâncias, kits e lotes. Não é o valor de um kit padronizado, nem o ticket médio das vendas. Taxas adicionais não foram somadas; disponibilidade atual não foi confirmada. Coleta: '+window.EstudoParcial.date(meta.coletado_em)+'. O preço resumido anterior fica na página seguinte a estes recortes, para auditoria.')},
      {title:'Kits e lotes, com bases próprias.',description:'Recortes da mesma amostra de categoria geral identificada.',content:'<div class="grid grid-2">'+cut('kit','Preços por rótulo de kit')+cut('lote','Preços por lote capturado')+'</div>'+note('Uma prova pode oferecer mais de um kit ou lote e aparecer em várias linhas: os recortes não devem ser somados. Cada linha usa seu próprio conjunto de provas e seu menor preço dentro daquele rótulo. As diferenças entre lotes não medem reajuste, porque as amostras podem ser diferentes.')+note('“Básico”, “completo” e “premium” são rótulos, sem garantia de conteúdo equivalente. Camiseta e só chip exigem indicação explícita. Ausências ficam como “Kit não identificado” ou “Lote não informado”; não são tratadas como kit completo ou primeiro lote. As regras e as opções classificadas estão congeladas no notebook.')}
    ]);
  }
  function raceSizeAvailable(){return state.source==='atual'&&!!data.meta.porte&&['porte_resumo','porte_provas','porte_participacoes','porte_concentracao'].every(id=>data.series.some(s=>s.id===id));}
  function raceSize(){
    if(!raceSizeAvailable())return '';
    const meta=data.meta.porte,summary=get('porte_resumo'),events=get('porte_provas'),volume=get('porte_participacoes'),concentration=get('porte_concentracao');
    const top=concentration.values.find(v=>v.label==='10% maiores provas');
    const stats=summary.values.map(v=>'<div class="metric"><span>'+esc(v.label)+' por prova</span><strong>'+esc(fmt(v.value,'numero',1))+'</strong><small>Conclusões registradas · '+fmt(meta.provas,'provas')+' provas</small></div>').join('');
    return section('porte',year===2026&&(data.meta.inscricoes||data.meta.inscricoes_geral)?'09':'08','Qual é o tamanho das provas?','Rua no Brasil · '+(year===2025?'ano completo de 2025':'parcial de 01/01 a '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026')+' · todas as distâncias juntas.',[
      {content:'<div class="metrics">'+stats+'<div class="metric"><span>Participações na amostra</span><strong>'+fmt(meta.participacoes,'participacoes')+'</strong><small>'+fmt(meta.provas,'provas')+' provas com ao menos uma conclusão</small></div></div>'+note('Uma prova é um id_evento: 5 km e 10 km do mesmo evento são somados. Contamos conclusões homologadas, com status 0 e flag de conclusão verdadeira, de todas as idades. São participações, não atletas únicos ou inscrições vendidas. Uma captura incompleta pode reduzir o porte observado.')+'<div class="grid grid-2">'+card('As provas por tamanho','Percentual das provas com conclusões registradas',events,meta.provas?bars(events,['#43bd9a','#4886c2','#f5b21b','#e98466','#666666'],{wide:true}):'<div class="empty-state">Sem provas com conclusões registradas.</div>')+card('Onde estão as participações','As mesmas faixas, ponderadas pelo volume de conclusões',volume,bars(volume,['#43bd9a','#4886c2','#f5b21b','#e98466','#666666'],{wide:true}))+'</div>'+note('Provas sem conclusão registrada ficam fora da média, mediana e distribuição; ausência não é uma prova de tamanho zero. Rua BR ativa, ranking elegível, pela data final. Coleta: '+window.EstudoParcial.date(meta.coletado_em)+'. Este recorte tem fonte própria e conserva os indicadores anteriores.')},
      {title:'Quanto as maiores provas concentram.',description:'Concentração das participações registradas na mesma amostra.',content:fact(fmt(top?.value??null),'Das participações estão nas 10% maiores provas.',fmt(meta.maiores_provas,'provas')+' provas reúnem '+fmt(meta.maiores_participacoes,'participacoes')+' conclusões. A base tem '+fmt(meta.provas,'provas')+' provas.')+'<div class="grid grid-2">'+card('Maiores provas e demais','Percentual das conclusões registradas',concentration,donut(concentration,[palette[0],'#666666'],String(year),'VOLUME'))+card('Quantidades e bases','As faixas somam toda a amostra',[events,volume],valueTable([events,volume],['Provas (%)','Participações (%)'],'Conclusões por prova'))+'</div>'+note('Selecionamos 10% do número de provas, arredondando para cima; ordem por volume decrescente e id_evento para desempate. Empates no limite não ampliam a seleção. O ano completo de 2025 e o parcial de 2026 têm períodos diferentes: estas telas não medem crescimento entre anos.')}
    ]);
  }
  function registrationCosts(){
    if(year!==2026||!data.meta.inscricoes||!['inscricoes_resumo','inscricoes_cobertura','inscricoes_faixas'].every(id=>data.series.some(s=>s.id===id)))return generalCosts();
    const meta=data.meta.inscricoes,summary=get('inscricoes_resumo'),coverage=get('inscricoes_cobertura'),bands=get('inscricoes_faixas');
    const known=coverage.values.find(v=>v.label==='Com valor informado'),missing=coverage.values.find(v=>v.label==='Sem valor informado');
    const metric=(title,value,context)=>'<div class="metric"><span>'+esc(title)+'</span><strong>'+esc(value)+'</strong><small>'+esc(context)+'</small></div>';
    const statistics=['Mediana','Média'].map(title=>metric(title+' de entrada',fmt(summary.values.find(v=>v.label===title)?.value??null,'reais',2),fmt(meta.analisadas,'provas')+' provas com valor acima de R$ 0,01')).join('');
    return generalCosts()+section('inscricoes','08','Preços de entrada no cadastro.','Preço resumido das provas de rua do Brasil, ainda sem separar categorias, kits e lotes · calendário de 01/01 a '+(data.meta.escopo_trimestres===3?'30/09/2026':'31/12/2026, incluindo futuras')+'.',
      '<div class="metrics">'+statistics+metric('Com valor informado',fmt(known?.value??null,'percentual',1),fmt(known?.count??null,'provas')+' de '+fmt(known?.denominator??null,'provas')+' · '+fmt(missing?.count??null,'provas')+' sem valor')+'</div>'+
      note('Cada prova tem o mesmo peso. A mediana reduz a influência de preços extremos, mas não elimina descontos ou diferenças de kit e lote. Estes valores não estimam o ticket médio de vendas nem o preço da categoria geral adulta.')+
      '<div class="grid grid-2">'+card('Preços de entrada por faixa','Percentual das '+fmt(meta.analisadas,'provas')+' provas com valor acima de R$ 0,01',[bands,summary],meta.analisadas?bars(bands,['#43bd9a','#4886c2','#f5b21b','#e98466','#666666'],{wide:true}):'<div class="empty-state">Sem preços pagos analisáveis.</div>')+
      card('O quanto conhecemos dos preços','Cobertura do calendário cadastrado, incluindo valores simbólicos',coverage,donut(coverage,[palette[0],'#c6c6c6'],'2026','INSCRIÇÕES'))+'</div>'+
      note('Fora da média, mediana e faixas: '+fmt(meta.simbolicas,'provas')+' valores de R$ 0,01; '+fmt(meta.zeradas,'provas')+' zeros; '+fmt(meta.negativas,'provas')+' valores negativos. Ausências não viram zero. Não identifica automaticamente PCD ou gratuidade; categorias especiais exigem revisão da fonte.')+
      note('Análise preliminar do preço resumido no cadastro, descrito como menor valor positivo publicado. Excluir R$ 0,01 não exclui outros preços PCD, de idosos, kids, com meia-entrada ou cupons. Kits só com chip, kits completos, distâncias e lotes também podem ter preços diferentes; essas opções ainda precisam ser classificadas. Taxas adicionais não foram somadas. '+fmt(meta.divergencias_json,'provas')+' preços resumidos diferem do menor positivo nas opções capturadas e ficaram registrados para revisão no notebook.')+
      note('Coleta própria em '+window.EstudoParcial.date(meta.coletado_em)+'. Cadastro não confirma realização; a amostra com preço pode diferir das provas sem informação. A fonte de preços é independente dos resultados e comparativos até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026. Os 67,6% do Business eram a cobertura das provas futuras, um recorte diferente.'));
  }
  function introduction(){return section('metodologia','00','Como ler este estudo.','Objetivos, população e fontes da edição de 2025.',
    '<div class="grid grid-2"><article class="chart-card prose-card"><h3>Um retrato das participações</h3><p>O estudo descreve quem conclui provas, as distâncias escolhidas, os tempos de chegada e a distribuição das participações pelo Brasil.</p><p>A edição de 2025 reúne participações em provas no Brasil e comparações com anos anteriores. Uma pessoa pode aparecer em várias provas: participações não são atletas únicos.</p></article><article class="chart-card prose-card"><h3>Duas fontes, duas populações</h3><p>Os resultados vêm do Open Results. Os indicadores de hábitos e uso da plataforma vêm de informações anonimizadas de usuários Road Runners e representam uma amostra diferente.</p><p>O PDF informa 5,3 milhões de conclusões em 2025 e 84,1% de cobertura. A parcela restante inclui provas sem resultados disponíveis, sem confirmação de realização ou sem cronometragem competitiva.</p></article></div>'+note('Referência: PDF p. 2. “Publicado no PDF” preserva os valores históricos. “Recálculo atual” usa a base disponível e informa a origem em cada tabela; populações, cobertura e regras ainda estão em conciliação.'));}
  function card(title,sub,sets,body,extra='') {
    sets=Array.isArray(sets)?sets:[sets];
    const id='chart-'+(++cardId),rows=sets.flatMap(s=>s.values.map(v=>({...v,series:s.id,unit:v.unit??s.unit,decimals:v.decimals??s.decimals,source:state.source})));
    exportRows.set(id,rows);
    const pages=[...new Set(sets.map(s=>s.page))].join(', ');
    const detailScope=sets.every(s=>s.id.startsWith('porte_'))?'Porte observado: todas as idades e modalidades de cada evento de rua; fonte própria, sem modificar os totais e comparativos anteriores.':year===2026&&sets.every(s=>s.id.startsWith('inscricoes_'))?'Inscrições: calendário de 01/01 a '+(data.meta.escopo_trimestres===3?'30/09/2026':'31/12/2026, incluindo futuras')+'; coleta própria indicada acima. Não usa os resultados das provas até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'.':year===2026?(sets.some(s=>s.id==='outros_esportes')?'Atividades até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026, conhecidas na coleta identificada acima. Não representam resultados de provas nem atletas únicos.':'Edição parcial: eventos até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026, resultados conhecidos na coleta. Denominadores e população estão descritos acima.'):'Resultados congelados; veja a origem de cada valor. Categorias e populações ainda em conciliação; coincidência no arredondamento não confirma equivalência.';
    const details='<details class="data-details"><summary>Ver valores e fonte</summary><div class="table-scroll"><table class="data-table"><thead><tr><th>Categoria</th><th>Valor</th>'+(state.source==='atual'?'<th>Quantidade</th><th>Base</th><th>Fonte / ressalva</th>':'')+'</tr></thead><tbody>'+rows.map(v=>'<tr><td>'+esc(label(v.label))+(sets.length>1?'<small> · '+esc(seriesCaption(v.series))+'</small>':'')+'</td><td title="'+esc(v.exact??'Sem recálculo')+'">'+esc(v.placeholder||fmt(v.value,v.unit,v.decimals))+'</td>'+(state.source==='atual'?'<td>'+esc(fmt(v.count??null,'participacoes'))+'</td><td>'+esc(v.denominator?fmt(v.denominator,'participacoes'):'—')+'</td><td>'+esc(v.provenance||(year===2026&&sets.find(s=>s.id===v.series)?.note?'Fonte detalhada abaixo.':data.meta.origem||'Snapshot inicial'))+(v.note?'<small>'+esc(v.note)+'</small>':'')+'</td>':'')+'</tr>').join('')+'</tbody></table></div>'+[...new Set(sets.map(s=>s.note).filter(Boolean))].map(n=>'<p class="detail-note">'+esc(n)+'</p>').join('')+(state.source==='atual'?'<p class="detail-note">'+detailScope+'</p>':'')+'</details>';
    return '<article class="chart-card '+extra+'" data-series="'+esc(sets.map(s=>s.id).join('|'))+'" aria-labelledby="'+id+'"><h3 id="'+id+'">'+title+'</h3><p class="chart-subtitle">'+esc(sub)+'</p>'+body+'<div class="card-source"><span>'+(year===2026?'Parcial 2026 · base congelada':(sets.every(s=>s.page==null)?'Recálculo · notebook':(state.source==='publicado'?'Publicado · PDF p. ':'Recálculo · referência p. ')+pages))+'</span><div class="card-actions">'+(year===2026||sets[0].page==null?'':'<a href="'+PDF+'#page='+sets[0].page+'" target="_blank" rel="noopener" aria-label="Abrir página '+sets[0].page+' do PDF">PDF ↗</a>')+'<button class="mini-button" data-export="'+id+'" type="button" aria-label="Exportar '+esc(title.replace(/<[^>]*>/g,''))+'">CSV ↓</button></div></div>'+details+'</article>';
  }
  function bars(s,colors=palette,options={}) {return s.available?G.bars(s,colors,options):empty();}
  function donut(s,colors=palette,center='2025',caption='PARTICIPAÇÕES') {return s.available?G.donut(s,colors,center,caption):empty();}
  function grouped(sets,colors,options={}) {return sets.some(s=>s.available)?G.grouped(sets,colors,options):empty();}
  function stacks(sets,horizontal=false) {return sets.some(s=>s.available)?G.stacks(sets,sexColors,horizontal):empty();}
  function mappingPages(){
    if(state.source!=='atual'||!data.meta.mapeamento||!data.series.some(s=>s.id==='mapeamento_real'))return '';
    const all=get('mapeamento_real'),mapped=all.values.find(v=>v.label==='Provas mapeadas');
    if(!mapped||mapped.value===null)return '';
    const parts={...all,values:all.values.filter(v=>v.label!=='Provas mapeadas')},gray=parts.values.find(v=>v.label==='Sem resultado, link ou situação conhecida');
    return section('mapeamento','01','Quanto do calendário já mapeamos.','Provas ativas no Brasil, com UF reconhecida. '+(year===2026?'01/01–'+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026.':'Ano completo de 2025.'),
      fact(fmt(mapped.value),'Provas mapeadas',fmt(mapped.count,'provas')+' de '+fmt(mapped.denominator,'provas')+' provas. Cada prova entra uma única vez.')+
      '<div class="grid grid-2">'+card('A composição do mapeamento','Categorias sem sobreposição',parts,donut(parts,['#10a65a','#55b4d1','#dc4a68','#a4aab6'],String(year),'PROVAS'))+card('O que sabemos de cada prova','100% menos as provas sem informação suficiente',all,valueTable([all],['Percentual'],'Situação'))+'</div>'+
      note('Cinza: '+fmt(gray?.count,'provas')+' provas ('+fmt(gray?.value)+') sem resultado coletado, link de resultado ou situação conhecida. “Não encontrado” e códigos ainda não interpretados continuam pendentes. Uma nota de busca não comprova que o evento foi mapeado.')+
      note('Coletado = ao menos uma linha bruta, sem certificar captura completa. Links: url_resultado ou url_wiclax, sem espaços vazios. Situações reconhecidas: Sem Resultado, Kids, Treino, Cancelado, Adiado, Repetido e Adiado/Cancelado, sem diferença de maiúsculas. Prioridade: coleta, link, situação conhecida, pendente. Os resumos zerados também ficam na base. É cobertura do calendário conhecido do portal; não estima o total nacional nem confirma realização. Data e execução constam em “Ver valores e fonte”.')+
      note('A soma da barra antiga do Stats contava '+fmt(data.meta.mapeamento.sobreposicao_azul_vermelho,'provas')+' provas em azul e vermelho. O cálculo antigo está preservado para auditoria no notebook; o destaque usa provas distintas. Os 84,1% do PDF permanecem como referência histórica.'));
  }
  function collectionPages(){
    if(state.source!=='atual'||!data.series.some(s=>s.id==='coleta_eventos_cadastrados')||!get('coleta_eventos_cadastrados').available)return '';
    const coverage=['coleta_eventos_cadastrados','coleta_eventos_coletados','coleta_eventos_concluintes','coleta_cobertura_cadastral'].map(get);
    return section('coleta','01','A coleta dentro do cadastro.','Coleta própria: eventos no Brasil, pela data final, nos períodos indicados.',[
      {content:card('Provas cadastradas e coleta','A presença de resultados no portal; não estima cobertura nacional',coverage,seriesTiles(coverage,['Cadastradas','Com coleta','Com conclusão registrada','Coletadas / cadastradas'],{primary:3})+tableDetails(valueTable(coverage,['Cadastradas','Com coleta','Com conclusão registrada','Coletadas / cadastradas'],'Período / modalidade')))+note('Com coleta significa pelo menos uma linha de resultado, sem certificar captura completa. Com conclusão registrada exige status 0, homologação e flag de conclusão verdadeira. Cadastradas inclui eventos inativos e não comprova realização.')+note('Todas as modalidades e rua/trail são recortes sobrepostos: não some suas linhas. Ano completo e até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+' também se sobrepõem. As coletas têm data e origem próprias em “Ver valores e fonte”. A razão dentro do cadastro não substitui os 84,1% históricos do PDF.')},
    ]);
  }
  function annualVolumePage(){
    const ids=['volume_anual','variacao_volume_anual','eventos_anuais_cadastrados','eventos_anuais_coletados','eventos_anuais_elegiveis'];
    const current=state.source==='atual',available=ids.every(id=>data.series.some(s=>s.id===id));
    let content;
    if(current&&available){
      const sets=ids.map(get),volume=sets[0];
      content='<div class="grid grid-2">'+card('Volume de participações','Anos completos · mesma regra · base atual',volume,bars(volume,[palette[2],palette[1],palette[0]],{horizontal:false}))+card('Cadastro, coleta e resultados','Variação em relação ao ano anterior na mesma coleta',sets,valueTable(sets,['Resultados','Variação','Cadastradas','Com coleta','Com elegíveis'],'Ano'))+'</div>'
        +note('São contagens da base conhecida, com coleta própria identificada nas fontes. Mais resultados podem refletir mais participações nas provas, melhor coleta, importações tardias ou revisões. Esta variação não estima o crescimento do mercado.')
        +note('Cadastradas inclui eventos inativos ou cancelados; cadastro não garante realização. Com coleta significa ao menos um resultado bruto; com elegíveis significa ao menos um resultado status 0 e homologado. Isso não certifica captura completa nem reproduz os 84,1% de cobertura do PDF. Os totais dos outros blocos mantêm suas coletas anteriores.');
    }else{
      content=(current?'':card('Contagens históricas do PDF','Pedido ao DBA: recuperar os três valores originais',get('volume_anual'),valueTable([get('volume_anual')],['Participações'],'Ano'))+note('?? indica referência ainda não recuperada. Pedido registrado no notebook com o DBA; os CSVs preservam a ausência, sem zero ou estimativa.'))+'<article class="chart-card prose-card"><h3>O volume histórico ainda precisa de conciliação.</h3><p>O PDF apresenta um gráfico de 2023 a 2025 e o destaque de 5,3 milhões em 2025. Ainda não recuperamos as contagens exatas usadas nas três barras.</p><p>'+(current?'Esta versão do congelamento ainda não contém o recálculo anual.':'A opção “Recálculo atual” apresenta contagens da base disponível, com uma mesma regra para os três anos e coleta própria. Esses valores não substituem as contagens históricas do PDF.')+'</p><a href="'+PDF+'#page=3" target="_blank" rel="noopener">Consultar a página 3 do PDF ↗</a></article>';
    }
    return {title:'O volume, ano após ano.',description:current?'Participações registradas e abrangência da coleta de 2023 a 2025.':'A série histórica da página 3 do estudo.',content};
  }
  function panorama(){
    const current=state.source==='atual',sex=get('sexo_2025'),dist=get('distancias_faixas'),gen=revisedAgesAvailable()?ordered(get('geracoes_2025_geral'),cohortOrder):get('geracoes_2025_geral');
    const metrics=A.highlights(data,state.source);
    return section('panorama','01','Resultados no Open Results','As participações em provas revelam perfis, escolhas e distâncias. Um atleta pode aparecer em vários resultados.',
      [{content:'<div class="metrics">'+metrics.map(m=>'<div class="metric"><span>'+esc(m.label)+'</span><strong>'+esc(m.display)+'</strong><small>'+esc(current?({'Resultados':'Participações registradas em provas de 2025.','Resultados concluintes':'Participações registradas em provas de 2025.','Eventos cadastrados':'Provas de 2025 cadastradas no portal.'}[m.label]||m.context):m.context)+'</small></div>').join('')+'</div><div class="panorama-intro">QUEM CORRE · PERFIS · DISTÂNCIAS</div><div class="grid panorama-charts">'+card('Quem está na largada','Participações por gênero',sex,donut(sex,[palette[0],'#333333',palette[2]],'GÊNEROS','PARTICIPAÇÕES'))+card('Uma geração em destaque','Participações por geração',gen,donut(gen,[palette[3],'#111111',palette[0],palette[1],palette[2]],'GERAÇÕES','PARTICIPAÇÕES'))+card('As distâncias escolhidas','Distribuição em quatro faixas',dist,donut(dist,[palette[0],'#333333',palette[1],palette[3]],'DISTÂNCIAS','PARTICIPAÇÕES'))+'</div>'+note(current?'Recortes candidatos da base atual. Os resultados e os eventos usam populações diferentes. A auditoria de coleta, quando disponível abaixo, mede somente o cadastro do portal.':'Destaques arredondados como no PDF. A cobertura de 84,1% e seu denominador ainda serão conciliados com os scripts originais.')}, {title:'Mulheres e homens nas provas.',description:'A composição por gênero em 2024 e 2025.',content:card('Participação por gênero','Percentual das participações de cada ano',[namedSeries('sexo_2024'),namedSeries('sexo_2025')],grouped([namedSeries('sexo_2024'),namedSeries('sexo_2025')],[palette[2],palette[0]]))+(current?note('Confira as populações e os filtros de cada ano nas fontes.'):fact('52,9%','Mulheres são maioria em 2025.','Em 2024 eram 50,7%: aumento de 2,2 pontos percentuais na participação feminina, conforme os valores publicados.'))},annualVolumePage()]);
  }
  function ages(){
    if(revisedAgesAvailable())return revisedAges();
    const s=get('idades_'+state.age),generations=get('geracoes_2025_'+state.age);
    const summaries=[['Geração Z','16 a 28 anos'],['Millennials','29 a 44 anos'],['Geração X','45 a 60 anos']].map(([name,range])=>fact(fmt(generations.values.find(v=>v.label===name)?.value??null),name,range+' na referência de 2025.')).join('');
    return section('idades','02','Faixas etárias','Da primeira prova à experiência acumulada: a distribuição das participações por idade.',
      '<div class="grid age-layout">'+card('O perfil por idade','Participações (%) · '+(state.age==='geral'?'todos os gêneros':label(state.age)),s,bars(s,ageColors))+'<div class="grid generation-facts">'+summaries+'</div></div>'+note(state.source==='atual'?'No cálculo legado, intervalos de idade podem incluir um resultado em mais de uma categoria. A normalização será revista antes da publicação final.':'Faixas e classificações preservadas do estudo. A base das idades será confirmada com os scripts originais.'),false,segments('age',genderOptions));
  }

  function generations(){
    if(revisedAgesAvailable())return revisedGenerations();
    const years=state.generation==='geral'?[2023,2024,2025]:[2024,2025],sets=years.map(y=>get('geracoes_'+y+'_'+state.generation));
    return section('geracoes','03','Gerações na corrida','Um olhar para a composição das provas ao longo das edições.',
      card('Participação de cada geração','Percentual das participações · '+(state.source==='publicado'?years.join(' / '):'2025; anos anteriores sem recálculo'),sets,grouped(sets,state.source==='atual'?[state.generation==='F'?sexColors[0]:state.generation==='M'?sexColors[1]:palette[0]]:years.length===3?[palette[3],palette[2],palette[0]]:[palette[2],state.generation==='F'?sexColors[0]:sexColors[1]]))+'<p class="generation-key">Alfa: 14–15 anos · Z: 16–28 · Millennials: 29–44 · X: 45–60 · Boomers: acima de 60. Faixas apresentadas no PDF de 2025.</p>'+'<div class="mt">'+card('Variações de Alfa e Geração Z','Destaques transcritos da página 5',get('variacoes_a_z'),valueTable([get('variacoes_a_z')],['Variação publicada'],'Comparação'))+'</div>'+note('Os destaques de variação preservam a notação do PDF. A distinção entre percentual relativo e pontos percentuais ainda será conciliada com os cálculos originais.')+note('As gerações dependem da regra de idade de cada edição. O gráfico compara participações; variações não indicam, por si só, crescimento do número de atletas.'),false,segments('generation',genderOptions));
  }
  const cohortColors=['#bcbcbc','#25728e','#11a8ac','#f5b21b','#666666','#c6c6c6','#8a8a8a','#e98466','#eeeeee'];
  const cohortOrder=['Menos de 14','Alfa','Geração Z','Millennials','Geração X','Boomers','Anteriores a 1946','Geração indeterminada','Sem idade informada'];
  function revisedAgesAvailable(){return state.source==='atual'&&data.series.some(s=>s.id==='qualidade_idades_geral')&&get('qualidade_idades_geral').available;}
  function ordered(series,labels){return {...series,values:[...series.values].sort((a,b)=>labels.indexOf(a.label)-labels.indexOf(b.label))};}
  function revisedAges(){
    const age=ordered(get('idades_'+state.age),['Menos de 14','14–19','20–24','25–29','30–34','35–39','40–44','45–49','50–54','55–59','60–64','65–69','70+','Idade indeterminada','Sem idade informada']);
    const quality=ordered(get('qualidade_idades_'+state.age),['Nascimento plausível','Faixa da categoria','Sem idade informada','Dado inválido']),uncertain=age.values.filter(v=>['Idade indeterminada','Sem idade informada'].includes(v.label)).reduce((n,v)=>n+(v.value||0),0);
    return section('idades','02','Faixas etárias','Idade em 31 de dezembro do ano da prova. Uma participação, uma categoria.',[
      {content:'<div class="grid age-layout">'+card('Idades identificadas e pendências','Percentual de todas as participações do gênero selecionado',age,bars(age,['#bcbcbc',...ageColors,'#e98466','#dddddd'],{wide:true}))+'<aside class="editorial-aside"><span class="aside-label">IDADE A CONFIRMAR</span><strong>'+esc(fmt(uncertain))+'</strong><h3>Sem classificação segura.</h3><p>Faixas amplas e idades ausentes continuam no denominador. Menores de 14 aparecem separados.</p></aside></div>'+note('O nascimento plausível tem prioridade. Na falta dele, a faixa inteira da categoria precisa caber em um único grupo. Nenhum resultado é duplicado ou repartido por estimativa.')},
      {title:'De onde vem a idade.',description:'A cobertura dos dados ajuda a interpretar a distribuição.',content:card('Nascimento e faixa da categoria','Mesma base e gênero do gráfico de idades',quality,bars(quality,[palette[0],'#11a8ac','#dddddd','#e98466'],{wide:true}))+note('Nascimento plausível significa data não futura e idade de 0 a 120 anos; isso não certifica o cadastro. A carga extrai a faixa do texto da categoria e não registra a referência da idade. Interpretá-la em 31/12 é uma regra revisada, confirmada para este estudo. Os totais e comparativos das outras páginas mantêm suas próprias coletas.')}
    ],false,segments('age',genderOptions));
  }
  function cohortKey(){return 'Alfa: nascimento a partir de 2010, somente 14+ · Z: 1997–2009 · Millennials: 1981–1996 · X: 1965–1980 · Boomers: 1946–1964 · Anteriores a 1946 em grupo próprio. A idade é referenciada em 31/12; as coortes ficam fixas entre anos.';}
  function revisedGenerations(){
    const proximity=data.meta.geracoes_metodo==='proximidade_v2';
    const years=year===2026?[2026]:state.generation==='geral'?[2023,2024,2025]:[2024,2025];
    const sets=years.map(y=>({...ordered(get('geracoes_'+y+'_'+state.generation),cohortOrder),caption:String(y)}));
    const approximate=proximity?get('geracao_criterio_'+year+'_'+state.generation):null;
    const difference=proximity?get('alfa_z_variacao_pp_'+state.generation):null;
    return section('geracoes','03','Gerações na corrida','Grupos fixos por ano de nascimento, com ausentes e ambiguidades visíveis.',[
      {content:card('Participação de cada geração','Todas as participações do gênero selecionado · '+years.join(' / '),sets,years.length===1?bars(sets[0],cohortColors,{wide:true}):grouped(sets,years.length===3?[palette[3],palette[1],palette[0]]:[palette[2],palette[0]],{horizontal:true}))+'<p class="generation-key">'+esc(cohortKey())+'</p>'+note(proximity?'Nascimento plausível tem prioridade, com idade em 31/12. Sem nascimento, uma faixa que cruza duas gerações é atribuída inteira à geração da idade central. No empate entre duas idades centrais, usamos a menor. Essa atribuição é aproximada; não representa a idade individual. Faixas abertas que cruzam grupos, que incluem menores de 14 ou atravessam mais de duas gerações permanecem indeterminadas.':'Cada faixa textual só entra quando couber inteira na geração.')+note('Menores de 14, indeterminados e ausentes permanecem no denominador. Alfa: 14–15 em 2025 e 14–16 em 2026; Z: 16–28 e 17–29; Millennials: 29–44 e 30–45; X: 45–60 e 46–61; Boomers: 61–79 e 62–80. Os limites avançam com o ano, mantendo as coortes de nascimento.')},
      ...(approximate?.available?[{title:'Como atribuímos as gerações.',description:'Nascimento individual, faixa contida, aproximação e ausência aparecem separados.',content:card('Critério de classificação','Mesma base e gênero da distribuição',approximate,bars(approximate,[palette[0],palette[1],'#e98466','#dddddd'],{wide:true}))+note('GERAL F SOCIO e outras categorias sem idade não recebem idade ou geração inventada. A correção dos ranges pelo DBA está incorporada nesta coleta; ausências legítimas continuam explícitas.')}]:[]),
      ...(difference?.available?[{title:'Alfa e Z ao longo dos anos.',description:year===2026?'Jan–Set nos dois anos, com os mesmos filtros de conclusão.':'Anos completos, usando a mesma regra de classificação.',content:card('Variação da participação de Alfa + Z','Diferença em pontos percentuais (p.p.)',difference,seriesTiles([difference],['Diferença (p.p.)'],{context:'Participação de Alfa + Z em '+year+', menos a do ano indicado no cartão.'}))+note('Fórmula: percentual de participações Alfa + Z com 14+ no ano, menos o percentual no ano base. O denominador inclui todas as participações do gênero, inclusive menores de 14 e idades desconhecidas. Por exemplo, de 16% para 17% = +1 ponto percentual. Não é crescimento de quantidade nem de atletas únicos; diferenças na cobertura de idade também afetam o resultado. A fórmula revisada não reconstrói os destaques históricos do PDF.')}]:[])
    ],false,segments('generation',genderOptions));
  }
  function generationDistancePages(){
    const bands=['Até 5 km','6 a 10 km','11 a 29 km','+30 km'];
    const inDistance=bands.map(x=>({...ordered(namedSeries('geracao_dentro_distancia_'+x),cohortOrder)}));
    const generations=['Alfa','Geração Z','Millennials','Geração X','Boomers','Anteriores a 1946'];
    return [
      {title:'Gerações em cada distância.',description:'Todas as participações de rua com distância positiva em cada faixa.',content:card('Composição das distâncias por geração','Inclui menores de 14, idades ambíguas e ausentes',inDistance,G.stacks(inDistance,cohortColors,true))+note('Cada distância tem seu próprio denominador. As categorias somam 100%, sem excluir participações cuja geração não pode ser determinada. Regra de idade em 31/12; coleta própria identificada na fonte.')},
      {title:'As distâncias de cada geração.',description:'Somente participações de rua com percurso positivo e geração determinada.',content:'<div class="grid grid-2">'+generations.map(name=>{const s=namedSeries('distancia_dentro_geracao_'+name);return card('As escolhas · '+esc(name),'Quatro faixas · base própria da geração',s,bars(s,distanceColors));}).join('')+'</div>'+note('Aqui o denominador é o total de participações daquela geração em rua com percurso positivo. As quatro faixas somam 100% dentro da geração. Distâncias ausentes ou inválidas ficam fora deste recorte. Menores de 14 e gerações indeterminadas não integram estes seis grupos. Faixas: >0 a <6 km; 6 a <11; 11 a <30; 30 km ou mais.')}
    ];
  }
  function distances(){
    const detail=get('distancias_detalhe'),bands=['Até 5 km','6 a 10 km','11 a 29 km','+30 km'];
    const pairs=bands.map(d=>get('sexo_dentro_distancia_'+d)),bySex=['F','M'].map(x=>namedSeries('distancia_dentro_sexo_'+x));
    const generations=['Geração Z','Millennials','Geração X','Boomers'],byGeneration=generations.map(x=>namedSeries('distancia_dentro_geracao_'+x));
    const inDistance=bands.map(x=>namedSeries('geracao_dentro_distancia_'+x)),five=get('eventos_com_5km');
    return section('distancias','04','Cada corredor, uma distância.','As provas curtas, as longas e as escolhas de cada perfil.',[
      {content:'<div class="grid grid-2">'+card('As distâncias mais frequentes','Participações por distância',detail,bars(detail,distanceColors))+card('Gênero dentro de cada distância','Entre os concluintes de cada faixa, quantos são mulheres e homens?',pairs,stacks(pairs))+'</div>'},
      {title:'As escolhas de mulheres e homens.',description:'Agora o denominador é o total de participações de cada gênero.',content:card('Distâncias dentro de cada gênero','Como se distribuem os resultados femininos e masculinos?',bySex,grouped(bySex,sexColors))+'<div class="mt">'+card('Presença dos 5 km','Percentual de eventos com essa distância',five,fact(fmt(five.values[0]?.value??null),'Dos eventos analisados oferecem 5 km.',state.source==='publicado'?'Destaque publicado na página 6 do estudo.':'O recálculo considera eventos de rua com resultados tratados; veja o denominador na fonte.'))+'</div>'},
      ...(revisedAgesAvailable()?generationDistancePages():[
      {title:'Gerações em cada distância.',description:'Entre os concluintes de cada faixa, quais gerações estão presentes?',content:card('Composição das distâncias por geração','Percentual dentro de cada faixa de distância',inDistance,(inDistance.some(x=>x.available)?G.matrix(inDistance,['#008ba7','#1eb9c4','#24aca0','#48d5b6']):empty()))+note('O recorte publicado apresenta Z, Millennials, X e Boomers. Alfa não aparece nesta distribuição; as regras estão em revisão.')},
      {title:'As distâncias de cada geração.',description:'Dentro de cada geração, quais distâncias concentram as participações?',content:'<div class="grid grid-2">'+byGeneration.map(x=>card('As escolhas · '+esc(x.caption),'Percentual das participações da geração',x,bars(x,distanceColors))).join('')+'</div>'+note('As duas leituras usam denominadores diferentes. Os limites das distâncias e as regras de geração permanecem em conciliação.')}
      ])
    ]);
  }
  function performance(){
    const cards=['5k','10k','21k','42k'].map((d,i)=>{const s=get('performance_'+d+'_'+state.performance);return card(['5 km','10 km','Meia maratona','Maratona'][i],'Distribuição por tempo de conclusão',s,bars(s,[distanceColors[i]],{compact:true})+timeIntervals(s));});
    return section('ritmo','05','Ritmo e performance','Quanto tempo levamos para cruzar a linha de chegada?',
      '<div class="grid grid-4 small-cards">'+cards.join('')+'</div>'+note(state.source==='atual'?'Recálculo de rua com conclusão e tempo positivo. Cada faixa inclui o limite superior e começa acima do anterior. Na maratona, “<4:00” é a faixa entre mais de 3h30 e até 4h, sem acumular as anteriores. Consulte os intervalos exatos em cada card.':'Rótulos preservados como no PDF. Na maratona, “<4:00” corresponde somente à terceira faixa, entre 3h30 e 4h; não é um percentual acumulado.'),false,segments('performance',genderOptions));
  }
  function capitalChart(series){
    if(state.source==='publicado')return donut(series,[palette[0],palette[1]],'2025','LOCALIZAÇÃO');
    // An incomplete geographic classification must not be rescaled to a whole donut.
    return bars(series,[palette[0],palette[1]],{maximum:100})+(series.available?note(series.note):'');
  }
  function regionalGenderPage(){
    const sets=[namedSeries('regioes_feminino_rotulos_visiveis'),namedSeries('regioes_masculino_rotulos_visiveis')];
    const historical=state.source==='publicado';
    return {title:'Onde correm mulheres e homens.',description:'Distribuição das participações de cada gênero entre as regiões.',content:card('Regiões dentro de cada gênero',historical?'Recorte dos quatro rótulos legíveis no PDF':'Cada gênero tem seu próprio denominador nacional',sets,grouped(sets,sexColors,{horizontal:true})+(historical?valueTable(sets,['Feminino','Masculino'],'Região'):''))+note(historical?'Norte: ?? nos dois gráficos do PDF; pedido ao DBA registrado no notebook. Não foi preenchido por diferença; esta exibição é incompleta e não foi normalizada para 100%.':'Aqui a pergunta é: de todas as participações femininas (ou masculinas) do país, quanto está em cada região? As categorias somam 100% dentro de cada gênero, incluindo a região não informada quando existe. O gráfico de composição regional usa outro denominador: todas as participações daquela região.')};
  }
  function geography(){
    const regions=get('regioes_2025'),ufs=get('ufs_top_grafico'),cities=get('cidades'),capital=get('capital_interior_Brasil');
    const sex=get('sexo_por_regiao_'+state.region),local=get('capital_interior_'+state.region);
    const control='<label class="region-select">Explorar a região <select id="region" aria-label="Região para gênero e capital ou interior">'+['Norte','Nordeste','Centro-Oeste','Sudeste','Sul'].map(r=>'<option'+(state.region===r?' selected':'')+'>'+r+'</option>').join('')+'</select></label>';
    return section('geografia','06','Onde o Brasil corre','A presença das provas nas regiões, estados e cidades.',
      [{content:'<div class="grid grid-2">'+card('Participações por região','Distribuição nacional',regions,donut(regions,palette,'BRASIL','REGIÕES'))+card('Capital ou interior?','Distribuição nacional',capital,capitalChart(capital))+'</div>'}, {title:'Estados e cidades.',description:'A distribuição das participações pelo território.',content:'<div class="grid grid-2">'+card('Estados em destaque','Nove UFs destacadas no PDF e demais agrupadas',ufs,bars(ufs,['#159bcc','#14a5b3','#18ac99','#50b983','#86c26f','#aac765','#cecc6e','#b3b98b','#b7bd9c','#eb9361'],{compact:true}))+card('Cidades em destaque',state.source==='atual'?'Cidades do PDF · cidade/UF validada · base nacional':'Percentual do total nacional',cities,bars(cities,['#159bcc','#11a7b0','#2eb698','#75c878'],{wide:true}))+'</div>'}, {title:'Dentro de cada região.',description:'Gêneros e localização das provas na região selecionada.',content:'<div class="chapter-heading">'+control+'</div><div class="grid grid-2">'+card('Gêneros · '+esc(state.region),'Composição na região selecionada',sex,donut(sex,sexColors,'2025','GÊNEROS'))+card('Capital e interior · '+esc(state.region),'Composição na região selecionada',local,capitalChart(local))+'</div>'+note(state.source==='atual'?'Capital/interior usa o recorte de rua e a localidade validada do evento. As participações não classificadas permanecem no denominador. Os outros gráficos mantêm suas populações, descritas nas fontes.':'Percentuais das cidades usam o universo nacional. O conjunto de cidades exibidas não soma 100%.')},
      {title:'As regiões ao longo dos anos.',description:'Participação regional em 2024 e 2025.',content:card('Distribuição regional por ano','Percentual das participações nacionais',[namedSeries('regioes_2024'),namedSeries('regioes_2025')],grouped([namedSeries('regioes_2024'),namedSeries('regioes_2025')],[palette[2],palette[0]]))+note('Mudança de participação regional não equivale, sozinha, a crescimento ou queda do número de resultados.')},
      regionalGenderPage(),
      {title:'Todos os estados.',description:'A distribuição completa pelas 27 unidades da federação.',content:card('Participações por UF','Percentual do total nacional',get('ufs'),rankedDistribution(get('ufs')))}
    ],true);
  }
  function seasonPages(){
    if(!data.series.some(s=>s.id==='estacoes'))return [];
    const seasons=get('estacoes');
    if(!seasons.available)return [];
    return [{title:'As estações no recorte de '+year+'.',description:'Distribuição pelos meses de cada estação, dentro do ano civil.',content:'<div class="grid grid-2">'+card('Participações por estação','Percentual do período coletado',seasons,donut(seasons,palette,String(year),'ESTAÇÕES'))+card('Meses considerados','Verão: jan/fev · outono: mar–mai · inverno: jun–ago · primavera: '+(data.meta.escopo_trimestres===3?'setembro':'setembro parcial')+'',seasons,valueTable([seasons],['Participação'],'Estação'))+'</div>'+note('Usamos meses inteiros: verão dez–fev, outono mar–mai, inverno jun–ago e primavera set–nov. Em 2026 até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+', o verão contém apenas janeiro e fevereiro; a primavera contém apenas '+(data.meta.escopo_trimestres===3?'setembro':'setembro parcial')+'. Outubro, novembro e dezembro estão fora do corte. Estas são parcelas do ano civil, não estações completas nem uma comparação de crescimento. Contagens mensais já congeladas; os comparativos anteriores permanecem iguais.')}];
  }
  function medalTable(sets){
    if(!sets.some(s=>s.available))return empty();
    const labels=[...new Set(sets.flatMap(s=>s.values.map(v=>v.label)))];
    const score=(name,index)=>Number(sets[index].values.find(v=>v.label===name)?.value)||0;
    labels.sort((a,b)=>score(b,0)-score(a,0)||score(b,1)-score(a,1)||score(b,2)-score(a,2)||a.localeCompare(b,'pt-BR'));
    const ordered=sets.map(s=>({...s,values:labels.map(name=>s.values.find(v=>v.label===name)).filter(Boolean)}));
    const gold=sets[0].values.filter(v=>typeof v.value==='number'&&Number.isFinite(v.value));
    const most=gold.length?Math.max(...gold.map(v=>v.value)):0;
    const leaders=gold.filter(v=>v.value===most);
    return (most>0?fact(fmt(most,'numero'),'Maior número de ouros na seleção',leaders.map(v=>v.label).join(' / ')+(leaders.length>1?' · empate':'')):'')+'<div class="medal-table">'+valueTable(ordered,['Ouro','Prata','Bronze'],'Prova')+'</div>';
  }
  function calendar(){
    const month=get('meses'),quarter=get('trimestres'),season=get('estacoes');
    return section('calendario','07','O ano, prova após prova.','Como as participações se distribuem pelo calendário.',
      '<div class="grid grid-2">'+card('Um calendário em movimento','Participações em cada mês',month,bars(month,monthColors,{compact:true}))+ '<div class="grid">'+card('Trimestres','Distribuição ao longo de 2025',quarter,donut(quarter,palette,'2025','TRIMESTRES'))+card('Estações do ano',state.source==='atual'?'Meses inteiros · parcelas do ano civil':'Classificação publicada no PDF',season,donut(season,palette,'2025','ESTAÇÕES'))+'</div></div>'+note(state.source==='atual'?'Estações: verão dez–fev, outono mar–mai, inverno jun–ago e primavera set–nov, conforme as notas do DBA e a regra confirmada. São meses do ano civil: janeiro, fevereiro e dezembro de 2025 formam o verão neste gráfico. Derivamos contagens mensais já congeladas; não somamos percentuais arredondados. A divisão difere da referência histórica do PDF, preservada na outra fonte.':'Os percentuais das estações são os publicados no PDF. Eles não correspondem à soma de meses inteiros descrita nas notas do DBA; a visão recalculada usa essa regra revisada e mantém a diferença explícita.'),true);
  }
  function marathonHighlights(){
    const headline=get('maratonas_destaques'),current=state.source==='atual';
    if(year===2026&&!headline.available)return '';
    const values=current?headline.values.filter(v=>v.value!==null).concat(headline.values.filter(v=>v.value===null)):headline.values;
    const titles={'Top 10 soma':'Participações nas dez provas','Mulheres':'Mulheres nas dez provas','Provas no ano':'Maratonas cadastradas','Provas que são maratonas':'Parcela do calendário de rua','New York':'New York · '+year};
    const context=v=>!current?'Referência da página 12; confira fonte e critérios antes de comparar universos.':v.value===null?({
      'Provas no ano':'Pendente: definir o universo das maratonas cadastradas e com resultados.',
      'Provas que são maratonas':'Pendente: definir quais provas entram no numerador e no denominador.',
      'New York':v.note&&year===2026?'Prova prevista para 01/11/2026; ainda não realizada no corte do estudo. Total de concluintes indisponível.':v.note||'Referência externa pendente de fonte e edição.'
    }[v.label]||'Fonte pendente.') : ({
      'Mulheres':'Participações femininas / total das mesmas dez provas; outros gêneros permanecem na base.',
      'Provas no ano':'Eventos com percurso de rua de 42 a 42,2 km cadastrado, no mesmo período do calendário.',
      'Provas que são maratonas':'Maratonas cadastradas / '+fmt(v.denominator,'provas')+' eventos ativos BR/rua elegíveis ao ranking. Cadastro de distâncias incompleto pode subestimar.',
      'New York':'Referência externa: concluintes da edição '+year+'. Não usa os filtros da seleção brasileira.'
    }[v.label]||'Soma dos concluintes elegíveis das mesmas dez provas do quadro.');
    const catalog=current&&data.series.some(s=>s.id==='maratonas_cadastro')?get('maratonas_cadastro'):null;
    if(catalog){const order=['Maratonas cadastradas','Cadastradas com resultados de 42 km','Cadastradas com concluintes elegíveis','Resultados de 42 km sem percurso cadastrado','Concluintes elegíveis sem percurso cadastrado'];catalog.values.sort((a,b)=>order.indexOf(a.label)-order.indexOf(b.label));}
    const registry=catalog?.available?'<div class="mt">'+card('Cadastro e coleta de maratonas','Uma prova é contada uma vez em cada recorte, mesmo com vários percursos.',catalog,valueTable([catalog],['Provas'],'Recorte'))+note(catalog.note)+'</div>':'';
    const nyrr=current&&headline.values.some(v=>v.label==='New York'&&v.provenance&&v.note)?'<p class="chart-note"><a href="https://www.nyrr.org/tcsnycmarathon" target="_blank" rel="noopener noreferrer">Fonte: NYRR</a> · referência externa da edição '+year+'.</p>':'';
    return '<div class="mt">'+card('O retrato das maratonas',current?'Destaques das dez provas · '+(year===2026?'até '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026':'ano de 2025'):'Destaques e universo apresentados no PDF',headline,headline.available?'<div class="grid grid-2">'+values.map(v=>fact(fmt(v.value,v.unit,v.decimals),current?(titles[v.label]||v.label):v.label,context(v))).join('')+'</div>'+nyrr:empty())+'</div>'+registry+(current&&headline.available?note('2025 mantém as dez provas da seleção histórica; 2026 seleciona as dez maiores no período coletado. Participações não são atletas únicos. A composição usa as quantidades, sem média simples dos percentuais. As seleções e os períodos diferem; estes destaques não medem crescimento. '+(year===2026?(data.meta.maratonas?.floripa?.status==='restaurado'?'Floripa usa a fonte correta da RaceTag, com a mesma base para volume, composição e desempenho. As outras nove provas mantêm seus congelamentos.':'Floripa 2026 permanece no volume e na composição, aguardando recoleta para desempenho.'):'')):'');
  }
  function marathonRegistryReview(){
    const meta=data.meta.maratonas_revisao;
    if(year!==2026||!meta)return '';
    const summary=get('maratonas_revisao_situacoes'),cases=get('maratonas_revisao_eventos');
    const link=(url,title)=>/^https?:\/\//i.test(String(url||''))?'<a href="'+esc(url)+'" target="_blank" rel="noopener noreferrer">'+esc(title)+' ↗</a>':'';
    const table='<div class="review-cards">'+meta.casos.map(v=>'<article class="review-card"><span class="review-status">'+esc(v.situacao)+'</span><h4>'+esc(v.nome_evento)+'</h4><p class="review-location">'+esc(window.EstudoParcial.date(v.data_final))+' · '+esc(v.cidade)+'/'+esc(v.estado)+' · #'+esc(v.id_evento)+'</p><div class="review-count"><strong>'+esc(fmt(v.elegiveis,'participacoes'))+'</strong><span>Linhas pela regra atual<small>'+esc(fmt(v.linhas_brutas,'participacoes'))+' linhas brutas</small></span></div><details class="data-details"><summary>Ver evidência e ação</summary><p>'+esc(v.evidencia)+'</p><p><b>Próximo passo:</b> '+esc(v.proximo_passo)+'</p><p>'+v.referencias.map((url,i)=>link(url,'Fonte '+(i+1))).filter(Boolean).join(' · ')+(v.tag?' · '+link('https://roadrunners.run/evento/'+encodeURIComponent(v.tag)+'/','Cadastro no portal'):'')+'</p></details></article>').join('')+'</div>';
    return section('maratonas-revisao',raceSizeAvailable()?'10':'09','42 km: o que precisa de revisão.','16 eventos com resultados marcados como 42 km, sem percurso de rua correspondente no cadastro · janeiro a setembro de 2026.',[
      {content:'<div class="metrics marathon-review-metrics">'+meta.resumo.map(v=>'<div class="metric"><span>'+esc(v.situacao)+'</span><strong>'+esc(fmt(v.eventos,'provas'))+'</strong><small>Provas nesta lista de revisão</small></div>').join('')+'</div>'+note('Confirmar 42 km na fonte não confirma terreno de rua, homologação, conclusão individual ou coleta completa. A regra anterior também admitiu revezamentos e provas de outro esporte; as quantidades abaixo são linhas para auditoria, não novos concluintes de maratona.')+card('Revisão por prova','Abra a evidência para conferir a fonte e o próximo passo. Os CSVs também registram essas decisões.',[summary,cases],table)+note('Revisão de '+window.EstudoParcial.date(meta.verificado_em)+'. Auditoria congelada '+meta.fonte_auditoria+'; decisões e fontes no congelamento '+meta.execucao+', célula '+meta.celula+'. Nenhum cadastro ou resultado operacional foi alterado. Os indicadores de participação e desempenho apresentados nas páginas anteriores conservam suas fontes e valores.')}
    ]);
  }
  function marathons(){
    const count=get('maratonas_concluintes'),female=get('maratonas_feminino'),male=get('maratonas_masculino');
    const composition=count.values.map(v=>({id:v.label,caption:v.label,values:[{label:'F',value:female.values.find(x=>x.label===v.label)?.value??null},{label:'M',value:male.values.find(x=>x.label===v.label)?.value??null}]}));
    const times=['menor','medio','mediano'].map(x=>get('maratonas_tempo_'+x));
    const cutoffs=['sub4','sub3','sub2h30'].map(x=>[get('maratonas_'+x+'_percentual'),get('maratonas_'+x+'_contagem')]);
    const extended=data.series.some(x=>x.id==='maratonas_top10');
    const best=extended?['top10','top100','top5pct','top10pct','top50pct'].map(x=>get('maratonas_'+x)):[];
    const medals=extended?['ouro','prata','bronze'].map(x=>get('maratonas_medalhas_'+x)):[];
    const extension=extended?[
      {title:'Os melhores grupos de cada prova.',description:state.source==='atual'?'Média dos menores tempos de conclusão em cada prova.':'Os tempos apresentados na página 13, lado a lado.',content:card('Top 10, Top 100 e grupos percentuais',state.source==='atual'?'Seleção global pelo tempo; mesma população de concluintes em todos os grupos.':'Referência histórica; classificação cadastrada legada em conciliação.',best,timeBoard(best,['Top 10','Top 100','Melhores 5%','Melhores 10%','Melhores 50%'],0))+note(state.source==='atual'?'Top 10 e Top 100 usam os 10 e 100 menores tempos da prova. Os grupos percentuais usam 5%, 10% e 50% dos concluintes elegíveis, com quantidade arredondada para cima. Empates seguem uma ordem fixa para manter a quantidade de cada grupo. É uma regra revisada: difere da classificação e dos inscritos usados no SQL legado. Quantidades e fontes aparecem em “Ver valores e fonte”.':'Estes tempos são médias, não limites de classificação. O SQL legado usa posições cadastradas e inscritos, que podem misturar categorias e tamanhos de grupos. A transcrição original foi preservada; diferenças permanecem em conciliação.')},
      {title:'Pódio das maratonas.',description:state.source==='atual'?'Medalhas calculadas a partir de 11 indicadores, com o mesmo peso.':'O quadro de medalhas da edição publicada.',content:card('Medalhas no estudo',state.source==='atual'?'Zero significa nenhuma medalha atribuída neste cálculo.':'Traço indica célula vazia no PDF, não um zero calculado.',medals,medalTable(medals))+note(state.source==='atual'?'Regra revisada a partir dos destaques do PDF: cada indicador distribui ouro, prata e bronze para as posições 1, 2 e 3. Valem as maiores quantidades sub 4h, sub 3h e sub 2h30; e os menores tempos mínimo, médio, mediano, Top 10, Top 100, melhores 5%, 10% e 50%. Percentuais não pontuam. Empates nos valores exibidos compartilham a posição e pulam a seguinte: dois ouros levam a um bronze, sem prata. Derivação dos indicadores congelados, sem nova coleta.':'A referência histórica foi preservada. A composição por 11 indicadores é uma inferência dos destaques do PDF; a visão atual aplica uma regra revisada, com empates explícitos.')+note('Conciliação do PDF: o bronze nos melhores 5% está destacado em Curitiba (03:16:17), embora Floripa tenha média menor (03:14:23). Pelos números publicados, Floripa teria 7 bronzes e Curitiba 1; o quadro mostra 6 e 2. Essa diferença não foi corrigida na referência histórica. A edição 2026 tem fontes e pendências próprias, descritas no seu quadro de maratonas.')}
    ]:[{title:'Melhores grupos e pódio.',content:note('A referência ampliada da página 13 ainda não está disponível neste congelamento.')}];

    return section('maratonas',raceSizeAvailable()?'09':'08','Os 42 km em perspectiva.','Dez maratonas selecionadas no estudo: participação, perfil e desempenho.',[
      {content:card('As dez maratonas do estudo','A seleção de provas permanece a mesma nas duas fontes.',[count,female,male],'<div class="grid grid-2"><div>'+(female.available||male.available?G.stacks(composition,sexColors,true):empty())+'</div>'+valueTable([count,female,male],['Concluintes','Feminino','Masculino'],'Prova')+'</div>')+marathonHighlights()},
      {title:'As maratonas mais rápidas.',description:'Menor tempo, média e mediana dos concluintes.',content:card('Tempos de conclusão','O menor tempo, a média e a mediana contam histórias diferentes.',times,timeBoard(times,['Menor tempo','Tempo médio','Mediana']))+note(state.source==='atual'?'A população do recálculo e as exclusões por modalidade estão descritas em “Ver valores e fonte”. Contagens e tempos devem ser comparados usando os mesmos filtros. Diferenças restantes com o PDF continuam em conciliação.':'A mediana divide os concluintes em duas metades. O menor tempo e a média dependem dos resultados considerados válidos e da população de cada prova.')},
      {title:'Maratonas e desempenho.',description:'Percentuais e quantidades de concluintes abaixo de quatro, três e duas horas e meia.',content:'<div class="grid">'+cutoffs.map((sets,i)=>card(['Abaixo de 4 horas','Abaixo de 3 horas','Abaixo de 2h30'][i],'Percentual e número de concluintes por prova',sets,'<div class="grid grid-2">'+bars(sets[0],[palette[0]],{wide:true})+valueTable(sets,['Participação','Concluintes'],'Prova')+'</div>')).join('')+'</div>'+note('Os cortes são acumulados: quem conclui abaixo de 2h30 também integra os grupos sub 3h e sub 4h. Os critérios de seleção das provas e os limites de tempo permanecem documentados nas fontes.')}
    ].concat(extension));
  }
  function faixas(){
    const limits={ '5k':['>30 min','<30 min','<27 min','<25 min','<22 min','<20 min','<17 min','<15 min'],'10k':['>60 min','<60 min','<55 min','<50 min','<45 min','<42 min','<40 min','<35 min'],'21k':['>2h','<2h','<1h50','<1h45','<1h40','<1h30','<1h25','<1h20'],'42k':['>4h','<4h','<3h45','<3h30','<3h15','<3h','<2h45','<2h30']};
    const cards=['5k','10k','21k','42k'].map((d,i)=>{const s=get('cna_'+d),visual=state.source==='publicado'?{...s,values:s.values.map((v,j)=>({...v,label:v.label+' · '+limits[d][j]}))}:s;return card('<span class="cna-distance cna-'+d+'">'+d.toUpperCase()+'</span>','Participações por faixa de tempo',s,bars(visual,faixaColors)+timeIntervals(s));});
    return section('faixas',raceSizeAvailable()?'10':'09','Faixas de tempo','Classificação de Sérgio Rocha, do canal Corrida no Ar.',
      '<div class="grid grid-4 small-cards">'+cards.join('')+'</div>'+note(state.source==='atual'?'Limites recuperados das consultas: cada tempo pertence a uma única faixa. O limite inferior entra e o superior vai para a próxima faixa; nos 5 km, 15min é Preta e 30min é Branca. Tempos nulos e zero foram excluídos. CNA usa PCD=false e ranking elegível, sem limitar a corrida a rua. Há pendências nos cadastros PCD, registradas na fonte.':'Os rótulos reproduzem o PDF; cada resultado pertence a uma faixa de cor, sem percentuais acumulados. As queries usam limites estritos: exatamente 30min nos 5 km entra na Branca, embora o PDF use o rótulo “>30min”. Os valores históricos foram preservados.'),true);
  }
  function sportsContent(){
    const sports=get('outros_esportes');
    const denominator=sports.values.find(v=>v.denominator)?.denominator;
    const base=state.source==='atual'&&denominator?' · '+fmt(denominator,'participacoes')+' atividades na base':'';
    return card('O que fazemos além de correr','Percentual de todas as atividades registradas'+base,sports,bars(sports,sportColors,{wide:true}))
      +note('A base inclui corrida e todos os tipos de atividade. O gráfico mostra os onze tipos destacados no PDF, sem ajustar seus percentuais para somar 100%. São atividades importadas da plataforma, não atletas únicos nem participações em provas.')
      +(state.source==='atual'?note('Atividades sinalizadas como excluídas pelo Strava ficam fora do recálculo. Período, coleta e exclusões estão em “Ver valores e fonte”. O volume parcial de 2026 não deve ser comparado diretamente com o ano inteiro de 2025.'): '');
  }
  function profileContent(){
    const cards=get('perfil_cards');
    const explanations={'Associaram resultados':'Uso da plataforma como histórico de participações.','Incluíram provas ao calendário':'Planejamento das próximas provas.','Com equipe/assessoria':'Vínculo informado com grupos de corrida.','Desafios virtuais':'Participação nos desafios da plataforma.','Vincularam ao Strava':'Conexão para acompanhar as atividades.','Strava Premium':'Assinatura informada entre usuários da amostra.','Média seguidores':'Conexões entre os usuários da plataforma.','Peso médio':'Média dos registros considerados no estudo.','Pares tênis ativos':'Quantidade de pares em uso por usuário.','Rodagem por par':'Quilometragem registrada nos calçados.'};
    const current=state.source==='atual',revised=current&&cards.values.some(v=>v.population);
    const cohort=cards.values.find(v=>v.population)?.population,meta=data.meta.perfil||{};
    const profileDate=value=>String(value||'').slice(0,10).split('-').reverse().join('/');
    const metrics=cards.available?'<div class="profile-metrics">'+cards.values.map(v=>'<div class="profile-metric"><span>'+esc(v.label==='Média seguidores'&&revised?'Seguidores no Strava':v.label)+'</span><strong>'+esc(current?fmt(v.value,v.unit,v.decimals):v.value===null?'—':String(v.value).replace(/\.(?=\d)/g,','))+'</strong><p>'+esc(revised&&v.label==='Média seguidores'?'Seguidores informados pelo Strava.':revised&&v.label==='Desafios virtuais'?'Inscrições confirmadas nos desafios da plataforma.':explanations[v.label]||'')+'</p>'+(v.denominator?'<small class="profile-base">'+esc((v.unit==='percentual'?fmt(v.count,'participacoes')+' / ':'Base: ')+fmt(v.denominator,'participacoes')+' '+(v.baseLabel||'contas'))+'</small>':'')+'</div>').join('')+'</div>':empty();
    const sources=revised?card('Bases e fontes dos indicadores','Percentuais e médias usam as bases identificadas em cada linha',cards,'','profile-source-table'):'';
    return (revised?note('Base: '+fmt(cohort,'participacoes')+' contas cadastradas até '+profileDate(meta.corte||(year===2026?'2026-09-26':'2025-12-31'))+'. Cada conta é contada uma vez. Equipe, conexão e atributos Strava são os dados atuais dessas contas, observados na coleta de '+profileDate(meta.coletado_em)+'; não são uma cópia do perfil na data de corte. Não interpretar as diferenças entre edições como crescimento.'):'')+metrics+note(revised?'O sinal “+” do PDF significa “mais de esse percentual”, conforme confirmado pelo responsável. O recálculo mostra percentuais medidos, sem o sinal. Premium considera apenas perfis vinculados com assinatura informada; as médias usam informações disponíveis. Ausência não vira zero. '+(meta.regra_peso||'Confira a regra de peso na fonte de cada indicador.')+'':'Os cards históricos preservam os valores do PDF. O “+” significa “mais de esse percentual”. '+(current?'O pacote selecionado ainda não contém o recálculo de perfil.':'As bases reconstruídas ficam na opção “Recálculo atual”.'))+sources;
  }
  function profile(){
    return section('perfil',raceSizeAvailable()?'11':'10','Além da linha de chegada.','Um recorte específico dos usuários da plataforma Road Runners.',[
      {content:profileContent()},
      {title:'O que fazemos além de correr.',description:'Hábitos registrados nas atividades da plataforma.',content:sportsContent()}
    ],true);
  }
  function methods(){
    const c=data.conciliacao,has=id=>data.series.some(s=>s.id===id)&&A.series(data,id,'atual').available;
    const ages=has('qualidade_idades_geral'),profile=has('perfil_cards');
    return '<section class="method-section" id="fontes"><div class="wrap method-grid"><div><span class="section-number">SOBRE AS FONTES</span><h2>O mesmo estudo.<br>Fontes e critérios explícitos.</h2></div><div>'+
      '<h3>Publicado e recalculado são duas leituras distintas.</h3><p>A opção “Publicado no PDF” reproduz a transcrição da edição 2025, versão '+esc(data.meta.pdf_versao)+', atualizada em 9 de março de 2026. “Recálculo atual” usa a versão selecionada no Estudo do Business, com congelamentos do notebook e fontes anteriores identificadas nas tabelas. Uma participação não equivale a uma pessoa; os perfis Road Runners são uma população separada dos resultados de provas.</p>'+
      '<h3>Uma edição, várias coletas.</h3><p>Os temas mantêm as datas, populações e regras de suas próprias fontes. Uma consulta mais recente em um bloco não atualiza automaticamente o panorama nem os comparativos. A versão web identifica o pacote publicado; ela não indica que todos os dados foram coletados ao mesmo tempo.</p><p>O CSV do gráfico e a exportação geral preservam os valores sem arredondamento e incluem fonte, leitura, contagem, denominador e ressalvas. Na leitura histórica, a fonte é a página do PDF. Quando a origem por indicador não está registrada, a ausência é declarada no CSV.</p>'+
      (ages?'<p>Idades e gerações: regra revisada em 31/12, com casos sem classificação visíveis e data própria em Ver valores e fonte. Localidades usam cidade/UF e códigos validados; as participações sem classificação continuam nas bases informadas. Estações usam meses inteiros, conforme a regra confirmada pelo responsável.</p>':'')+
      '<h3>O que ainda precisa ser fechado</h3><ul><li>?? na leitura Publicado no PDF: volumes exatos de 2023, 2024 e 2025 (página 3), e percentual do Norte entre mulheres e entre homens (página 9). O recálculo atual possui valores; esses cinco pedidos ao DBA são referências históricas.</li><li>Denominador dos 84,1% do PDF. A razão de provas coletadas sobre cadastradas mede apenas o calendário conhecido do portal; não estima cobertura nacional.</li><li>'+(ages?(data.meta.geracoes_metodo==='proximidade_v2'?'A correção dos ranges pelo DBA já foi incorporada; categorias sem idade continuam desconhecidas.':'Intervalos de idade e categorias sem classificação continuam em revisão.'):'Intervalos de idade e denominadores dos recortes etários.')+'</li><li>'+(profile?'Perfil: atributos atuais das contas até o corte não reconstruem o perfil histórico; peso de 20 a 300 kg, inclusive, confirmado pelo responsável.':'Perfil: fontes e bases das dez métricas.')+' A qualidade cadastral e dos resultados permanece em revisão.</li><li>Floripa 2026: desempenho recuperado na edição 2026 do estudo; correção da importação operacional continua pendente.</li><li>'+(data.meta.geracoes_metodo==='proximidade_v2'?'Variação revisada de Alfa/Z calculada em pontos percentuais; fórmula histórica do PDF segue desconhecida.':'Variações de Alfa/Z: recuperar a fórmula histórica.')+' '+(has('maratonas_cadastro')?'Maratonas: os destaques estão disponíveis, com recortes de cadastro, coleta e elegibilidade separados. Cadastro de distâncias incompleto e universo dos destaques históricos continuam em conciliação. New York tem referência externa verificada por edição.':'Maratonas: soma e participação feminina das dez provas já disponíveis no recálculo; definir provas no ano, fração de maratonas e referência de New York.')+'</li></ul>'+
      '<div class="status-line"><span><strong>'+esc((c.compativel_no_arredondamento||0)+(c.compativel_no_valor||0))+'</strong>valores compatíveis*</span><span><strong>'+esc(c.divergente||0)+'</strong>diferenças em revisão</span><span><strong>'+esc(c.nao_recalculado||0)+'</strong>ainda sem recálculo</span><span><strong>'+esc(c.notebook_em_conciliacao||0)+'</strong>recalculados no notebook*</span></div><p style="margin-top:16px">* Inclui coincidências por arredondamento; não certifica uma população idêntica. Esta prévia não é o fechamento editorial do estudo. Novas consultas e correções geram outra versão, preservando os congelamentos anteriores. Nenhuma visita dispara as consultas de coleta.</p></div></div></section>';
  }
  function render(){
    G.begin();exportRows=new Map();cardId=0;
    document.getElementById('content').innerHTML=year===2026?window.EstudoParcial.render({A,data,state,get,card,bars,donut,stacks,grouped,valueTable,section,note,capitalChart,segments,genderOptions,label,empty,palette,sexColors,distanceColors,ageColors,faixaColors,monthColors,sportsContent,profileContent,timeBoard,rankedDistribution,tableDetails,seriesTiles,regionalGenderPage,revisedAgesAvailable,revisedAges,revisedGenerations,generationDistancePages,seasonPages,medalTable,collectionPages,mappingPages,marathonHighlights,marathonRegistryReview,registrationCosts,raceSize,monthly:G.monthly}):[introduction(),panorama(),mappingPages(),collectionPages(),ages(),generations(),distances(),performance(),geography(),calendar(),raceSize(),marathons(),faixas(),profile(),methods()].join('');
    const sizeLink=document.querySelector('.chapter-nav a[href="#porte"]');
    if(!raceSizeAvailable())sizeLink?.remove?.();
    else if(!document.querySelector('.chapter-nav a[href="#porte"]'))document.querySelector('.chapter-nav a[href="#calendario"]')?.insertAdjacentHTML?.('afterend','<a href="#porte">Porte</a>');
    numberPages();G.mount();
    document.getElementById('content').setAttribute('aria-busy','false');
    document.querySelectorAll('input[name=fonte]').forEach(i=>i.checked=i.value===state.source);
    document.getElementById('source-description').textContent=year===2026?'Parcial de 01/01 a '+(data.meta.escopo_trimestres===3?'30/09':'26/09')+'/2026. Última prova com resultados: '+window.EstudoParcial.date(data.meta.ultima_data_evento)+'. Comparações usam a base atual; setembro tem importações pendentes.':state.source==='publicado'?'Valores transcritos do PDF de 2025. Use “Recálculo atual” para explorar os resultados congelados no notebook; as diferenças continuam em revisão.':'Recálculo de 2025 selecionado no notebook Business. Consulte a origem de cada valor; fontes e denominadores continuam em conciliação.';
    if(data.publicacao)document.getElementById('source-description').textContent+=' · Web v'+data.publicacao.versao+' · congelamento #'+data.publicacao.execucao+'. '+data.publicacao.nota;
    if(document.body.dataset.annualDraft==='true'){
      document.getElementById('source-description').textContent='Rascunho anual interno. Corte efetivo da base: '+window.EstudoParcial.date(data.meta.corte)+'. As seções em revisão e seus CSVs não são conteúdo liberado. Fontes congeladas no notebook.';
    }
    document.getElementById('export-all').disabled=false;
  }
  function download(rows,name){
    const blob=new Blob([A.csv(rows)],{type:'text/csv;charset=utf-8;'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='brasil-que-corre-'+year+'-'+state.source+'-'+name+'.csv';document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
  document.addEventListener('click',event=>{
    const button=event.target.closest('button');if(!button||!data)return;
    if(button.dataset.control){const k=button.dataset.control,v=button.dataset.value;if(['age','generation','performance'].includes(k)&&['geral','F','M'].includes(v)){state[k]=v;render();document.querySelector('[data-control="'+k+'"][data-value="'+v+'"]').focus({preventScroll:true});}}
    if(button.dataset.export)download(exportRows.get(button.dataset.export),'grafico-'+button.dataset.export);
    if(button.id==='export-all')download(A.exportAll(data,state.source),'todas-as-series');
  });
  document.addEventListener('change',event=>{
    if(!data)return;
    if(event.target.id==='edition'){const u=new URL(location.href);u.searchParams.set('ano',event.target.value);u.searchParams.delete('fonte');u.hash='estudo';location.assign(u);return;}
    if(year===2025&&event.target.name==='fonte'&&['publicado','atual'].includes(event.target.value)){state.source=event.target.value;const u=new URL(location.href);u.searchParams.set('fonte',state.source);history.replaceState({},'',u);render();}
    if(event.target.id==='region'){state.region=event.target.value;render();document.getElementById('region').focus({preventScroll:true});}
  });
  async function load(){
    try {
      const endpoint=document.body.dataset.endpoint;
      const response=await fetch(endpoint.endsWith('.json')?(year===2026?'dados-2026.json':endpoint):endpoint+'?ano='+year,{credentials:'same-origin',cache:'no-store'});
      if(!response.ok)throw new Error('Dados indisponíveis');
      const payload=await response.json();
      if(!payload.meta||payload.meta.ano!==year||!Array.isArray(payload.series)||!Array.isArray(payload.comparacoes))throw new Error('Edição incompatível');
      data=payload;document.getElementById('edition').value=String(year);if(year===2026)window.EstudoParcial.shell(data);render();
      const anchor=document.getElementById(location.hash.slice(1));
      if(anchor&&anchor.matches('.chapter,#estudo,#fontes'))anchor.scrollIntoView({behavior:'instant',block:'start'});
    }catch(error){
      data=null;document.getElementById('content').setAttribute('aria-busy','false');document.getElementById('source-description').textContent='Não foi possível carregar os dados desta edição.';
      document.getElementById('content').innerHTML='<div class="wrap error-state"><h2>A edição está indisponível.</h2><p>Os gráficos precisam dos dados congelados para serem exibidos.</p><button type="button" id="retry">Tentar novamente</button></div>';document.getElementById('retry').onclick=load;
    }
  }
  load();
})();
