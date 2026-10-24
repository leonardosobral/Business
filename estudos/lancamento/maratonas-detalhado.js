(()=>{'use strict';
const D=JSON.parse(document.getElementById('study-data').textContent),root=document.getElementById('report');let year=new URLSearchParams(window.location.search).get('ano')==='2025'?2025:2026,charts=[];
const pc2=x=>Number(x).toLocaleString('pt-BR',{minimumFractionDigits:2,maximumFractionDigits:2})+'%';
const period=y=>y===2025?'2025 · janeiro a dezembro':'2026 · janeiro a setembro';
const topRaces=y=>[...D.years[y].races].sort((a,b)=>b.total-a.total||a.id_evento-b.id_evento).slice(0,10);
const pairedRaces=[...D.pairs.pares].sort((a,b)=>b.n2026-a.n2026||b.n2025-a.n2025);
const pairsToPlot=pairedRaces.slice(0,10);
const signed=x=>(x>0?'+':'')+pc(x);
const details=(title,body)=>`<details><summary>${e(title)}</summary>${body}</details>`;
const e=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const n=x=>x==null?'—':Number(x).toLocaleString('pt-BR',{maximumFractionDigits:0});const pc=x=>Number(x).toLocaleString('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1})+'%';
const time=x=>x==null?'—':[Math.floor(Math.round(x)/3600),Math.floor(Math.round(x)%3600/60),Math.round(x)%60].map(v=>String(v).padStart(2,'0')).join(':');
const s=id=>D.years[year].series.find(x=>x.id===id);const value=v=>v.value==null?'—':v.unit==='percentual'?pc(v.value):['participacoes','provas','numero'].includes(v.unit)?n(v.value):e(v.value);
const section=(id,k,t,body)=>`<section id="${id}"><p class="eyebrow">${k}</p><h2>${t}</h2>${body}</section>`;
const card=(v,t,p='')=>`<article class="metric"><strong>${v}</strong><h3>${t}</h3>${p?'<p>'+p+'</p>':''}</article>`;
const table=(heads,rows)=>`<div class="scroll" tabindex="0"><table><thead><tr>${heads.map(x=>'<th>'+e(x)+'</th>').join('')}</tr></thead><tbody>${rows.map(r=>'<tr>'+r.map(x=>'<td>'+e(x??'—')+'</td>').join('')+'</tr>').join('')}</tbody></table></div>`;
const defs={maratonas_concluintes:'Conclusões',maratonas_feminino:'Mulheres (%)',maratonas_masculino:'Homens (%)',maratonas_tempo_menor:'Menor tempo',maratonas_tempo_medio:'Tempo médio',maratonas_tempo_mediano:'Tempo mediano',maratonas_sub4_contagem:'Sub4h · quantidade',maratonas_sub4_percentual:'Sub4h (%)',maratonas_sub3_contagem:'Sub3h · quantidade',maratonas_sub3_percentual:'Sub3h (%)',maratonas_sub2h30_contagem:'Sub2h30 · quantidade',maratonas_sub2h30_percentual:'Sub2h30 (%)',maratonas_top10:'10 mais rápidos',maratonas_top100:'100 mais rápidos',maratonas_top5pct:'5% mais rápidos',maratonas_top10pct:'10% mais rápidos',maratonas_top50pct:'50% mais rápidos',maratonas_medalhas_ouro:'Ouro',maratonas_medalhas_prata:'Prata',maratonas_medalhas_bronze:'Bronze',performance_42k_geral:'42 km · geral',performance_42k_F:'42 km · mulheres',performance_42k_M:'42 km · homens',cna_42k:'Faixas CNA · 42 km',maratonas_cadastro:'Cadastro e resultados',maratonas_destaques:'Destaques do capítulo',maratonas_revisao_eventos:'Provas a revisar',maratonas_revisao_situacoes:'Situações de revisão'};
const sourceDetails=ids=>`<details><summary>Fontes, critérios e valores completos</summary>${ids.filter(id=>s(id)).map(id=>{const z=s(id);return `<h3>${defs[id]||id}</h3><p class="note">${e(z.note)}</p>`+table(['Categoria','Valor','Contagem / base','Fonte'],z.values.map(v=>[v.label,v.value==null?'Indisponível':(v.unit==='percentual'?pc(v.value):v.value),v.denominator?`${n(v.count)} / ${n(v.denominator)}`:'—',v.source||'Não informada']))}).join('')}</details>`;
function matrix(ids){const labels=[...new Set(ids.flatMap(id=>s(id)?.values.map(v=>v.label)||[]))].slice(0,10);return table(['Prova',...ids.map(id=>defs[id])],labels.map(label=>[label,...ids.map(id=>{const v=s(id)?.values.find(v=>v.label===label);return v?value(v):'—'})]));}
function plot(id,title){return `<div class="plot"><h3>${title}</h3><div class="chart"><canvas id="${id}" role="img" aria-label="${e(title)}"></canvas></div></div>`;}
function chart(id,labels,sets,opts={}){const el=document.getElementById(id);if(!el||!window.Chart)return;charts.push(new Chart(el,{type:'bar',data:{labels,datasets:sets},options:{indexAxis:opts.vertical?'x':'y',responsive:true,maintainAspectRatio:false,plugins:{legend:{display:sets.length>1,labels:{font:{size:15},color:'#242424'}},tooltip:{callbacks:{label:c=>`${c.dataset.label}: ${opts.time?time(c.raw):opts.percent?pc(c.raw):n(c.raw)}`}}},scales:{x:{beginAtZero:true,max:opts.percent&&opts.stacked?100:undefined,stacked:opts.stacked,ticks:{font:{size:14},callback:v=>opts.time?time(v):opts.percent?v+'%':n(v)}},y:{stacked:opts.stacked,ticks:{font:{size:14},color:'#242424'}}}}}));}
const short=x=>{
 const label=String(x).replace(/202[456]/g,'').replace(/ · \d\d\/\d\d/,'').trim();
 const normalized=label.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase();
 const names=[['NEW BALANCE','NB Porto Alegre'],['RIO DE JANEIRO','Rio de Janeiro'],['MARATONA DO RIO','Rio de Janeiro'],['PORTO ALEGRE','Porto Alegre'],['SP CITY','SP City'],['SAO PAULO','São Paulo'],['FLORIPA','Floripa'],['BELO HORIZONTE','Belo Horizonte'],['PARANA','Paraná'],['FORTALEZA','Fortaleza'],['MACEIO','Maceió'],['MONUMENTAL','Monumental · Brasília']];
 const match=names.find(([needle])=>normalized.includes(needle));
 return match?match[1]:label.replace(/Maratona Internacional d[eo] /ig,'').replace(/Maratona (de |do )?/ig,'').trim();
};
function ageAudit(){
 const A=D.age_audit[year],T=A.totals,classified=T.total-T.sem_informacao-T.fora_faixa_padrao;
 const priority=A.provas.filter(r=>r.sem_informacao>0).slice(0,year===2025?7:5);
 const samples=(r,motive)=>A.exemplos.filter(x=>x.id_evento===r.id_evento&&x.motivo===motive).slice(0,2).map(x=>(x.categoria_origem||'Categoria vazia')+' ('+n(x.total)+')').join('; ')||'—';
 const source=r=>/^https?:\/\//i.test(r.url_resultado||'')?`<a href="${e(r.url_resultado)}" target="_blank" rel="noopener">Resultado cadastrado ↗</a>`:'Sem link de resultado';
 const rows=items=>`<div class="scroll" tabindex="0"><table><thead><tr><th>Prova</th><th>Sem nascimento/faixa</th><th>Faixa incompatível</th><th>Exemplo capturado sem idade</th><th>Referência</th></tr></thead><tbody>${items.map(r=>`<tr><td>${e(r.nome_evento)}<small>${e(r.cidade)}/${e(r.estado)} · ID ${r.id_evento}</small></td><td>${n(r.sem_informacao)} / ${n(r.total)}<small>${pc(r.sem_informacao/r.total*100)}</small></td><td>${n(r.fora_faixa_padrao)}</td><td>${e(samples(r,'Sem informação'))}</td><td>${source(r)}</td></tr>`).join('')}</tbody></table></div>`;
 return `<div class="reading-note"><h3>Faixas de dez anos aproveitam a informação disponível.</h3><p>Até 29 anos; depois 30–39, 40–49, 50–59, 60–69 e 70+. Categorias como 30–39 e 40–49 entram inteiras, sem inventar idades individuais. O grupo inicial reúne também faixas como 18–24 e 20–29.</p></div><div class="grid smallmetrics">${card(pc(classified/T.total*100),'Idade classificada',n(classified)+' de '+n(T.total)+' participações nos grupos do gráfico.')}${card(pc(T.sem_informacao/T.total*100),'Sem informação utilizável',n(T.sem_informacao)+' participações sem nascimento plausível nem faixa.')}${card(pc(T.fora_faixa_padrao/T.total*100),'Faixa incompatível',n(T.fora_faixa_padrao)+' participações com informação ampla ou que cruza os limites dos grupos.')}</div><p class="note">Os percentuais são de participações, não de provas. Idade não informada continua no denominador. ${year===2026?'SP City tem somente 53 participações sem informação. As categorias de dez anos, como M3039 e M4049, agora entram no gráfico.':'As principais lacunas de 2025 são ausência de nascimento e categoria utilizável na base, detalhadas abaixo.'}</p><details id="idades-recuperar"><summary>Quais provas revisar? Ver prioridades e exemplos</summary><h3>Onde se concentra a ausência de informação.</h3><p>Primeiro, conferir se a cronometragem oferece idade ou categoria mais precisa. Categoria vazia, M/F e nomes de modalidade não informam a idade. Recarregar a mesma fonte sem dados adicionais não resolve.</p>${rows(priority)}${details('Todas as provas com alguma lacuna na edição',rows(A.provas.filter(r=>r.sem_informacao||r.fora_faixa_padrao)))}${details('Faixas que ainda cruzam os grupos',table(['Prova','Participações afetadas','Exemplos de categoria'],[...A.provas].filter(r=>r.fora_faixa_padrao).sort((a,b)=>b.fora_faixa_padrao-a.fora_faixa_padrao).map(r=>[r.nome_evento,n(r.fora_faixa_padrao)+' / '+n(r.total),samples(r,'Fora da faixa padrão')])))}<p><a href="arquivo.cfm?doc=maratonas-idades">Baixar auditoria de idades · CSV · 2025 e 2026</a></p><p class="note">Auditoria de 19/10/2026 · congelamento ${A.run_id}. Links do cadastro, ainda sujeitos à conferência. Nenhuma recarga foi realizada. 2025 usa resultados operacionais; 2026 usa o BI tratado. A diferença entre anos não mede apenas melhora de coleta. Não encontramos divergências entre os ranges do BI e os operacionais nesta seleção.</p></details>`;
}

function annualPairs(){return [...D.pairs2025.pares].sort((a,b)=>b.n2025-a.n2025||b.n2024-a.n2024);}
function annualComparison(selectionTotal){
 const A=D.pairs2025,P=A.coorte,rows=annualPairs(),growth=(P.n2025/P.n2024-1)*100;
 return section('pares','2024 × 2025 · JANEIRO A DEZEMBRO NOS DOIS ANOS','Como as mesmas maratonas mudaram em 2025.',`<div class="grid">${card(signed(growth),'Conclusões nas mesmas provas',n(P.n2024)+' em 2024 → '+n(P.n2025)+' em 2025.')}${card(n(P.pares),'Provas pareadas','Uma edição em 2024 e outra em 2025; ano completo dos dois lados.')}${card(pc(P.cobertura_volume2025),'Do volume selecionado de 2025',n(P.n2025)+' de '+n(selectionTotal)+' conclusões da seleção de 2025.')}</div><p>O comparativo reúne <b>${n(P.pares)} maratonas com resultados registrados nos dois anos</b>, conciliadas por prova e conferidas na lista individual da Contra-Relógio. Os volumes das barras vêm da base Road Runners. Somamos as conclusões de cada ano antes de calcular a variação; não é a média das porcentagens por prova.</p>${plot('pairs','Os dez maiores pares por volume em 2025 · conclusões registradas')}<p class="note">Cada dupla de barras representa a mesma maratona em 2024 e 2025, considerando janeiro a dezembro. O gráfico destaca os dez maiores pares; os indicadores acima incluem todos os ${n(P.pares)}.</p>${details('Abrir os '+n(P.pares)+' pares e suas variações',table(['Prova','2024 · anual','2025 · anual','Variação'],rows.map(r=>[short(r.nome_evento),n(r.n2024),n(r.n2025),signed((r.n2025/r.n2024-1)*100)])))}<p class="note">Variação descritiva de conclusões registradas. Diferenças na coleta podem influenciar o resultado; o comparativo não isola crescimento real e não representa o mercado nacional. Fonte: notebook, congelamento ${n(A.run)}. A conciliação com a referência CR está detalhada em Fontes.</p>`);
}
function annualPairSources(){
 const A=D.pairs2025;
 return details('Fontes e conciliação do comparativo 2024 × 2025',`<p>Notebook · congelamento ${n(A.run)}. A <a href="${e(A.reference_url)}" target="_blank" rel="noopener">lista individual da Contra-Relógio para 2024</a> foi usada para conferir as provas. Os indicadores publicados usam os resultados registrados na base Road Runners em ambos os anos, sem misturar os volumes de fontes diferentes.</p>${table(['Prova','Road Runners · 2024','Referência CR · 2024','Diferença RR − CR'],annualPairs().map(r=>[short(r.nome_evento),n(r.n2024),n(r.cr2024),(Number(r.delta_cr)>0?'+':'')+n(r.delta_cr)]))}<p class="note">O total de 39.358 informado no artigo diverge da soma de 41.280 dos valores individuais da lista. Essa divergência está registrada no notebook; nenhum desses dois totais foi usado como denominador do comparativo.</p>`);
}

function bostonInsert(){
 const b=D.boston;
 const recorte=label=>label==='Total corrida a pé'?'Total de concluintes':label;
 const sexo=label=>label==='F'?'Mulheres':label==='M'?'Homens':label;
 return `<section id="boston" class="boston-insert">
 <p class="eyebrow">ENCARTE ESPECIAL · DOIS ESTUDOS DE CASO · 2026</p>
 <h2>Encarte · Boston</h2>
 <p class="boston-lead">Duas perguntas específicas, duas conferências de resultados oficiais.</p>
 <div class="boston-context"><h3>Por que Floripa e NB Porto Alegre?</h3><p>Essas provas entraram porque recapturamos suas fontes oficiais para responder a duas demandas: <b>quantos concluintes de Floripa atingiram os índices</b> e <b>se os 908 divulgados pela NB Porto Alegre poderiam ser confirmados</b>.</p><p>A escolha não foi feita por desempenho ou preferência. São estudos de caso; não formam uma amostra, um ranking ou um recorte das dez maiores. As populações e a precisão das idades diferem entre as fontes, por isso os dois resultados não devem ser comparados diretamente.</p></div>
 <p>Atingir um índice de referência não garante inscrição nem vaga em Boston. Os recortes PCD/DV estão separados nas tabelas; aplicar a tabela geral de tempos não confirma enquadramento nem elegibilidade pelas regras específicas de paratletismo.</p>
 <details class="boston-case">
 <summary><span class="boston-number" aria-hidden="true">01</span><span class="boston-case-title"><strong>Floripa 2026</strong><span>Quantos concluintes atingiram a tabela geral de Boston?</span></span></summary>
 <div class="boston-case-content"><div class="boston-result"><strong>264</strong><div><h3>Atingiram a tabela geral</h3><p>186 homens e 78 mulheres, entre 3.603 concluintes.</p></div></div>
 <p>São 262 de geral/elite e 2 de PCD/DV. A análise usa tempo líquido e a idade em <b>19/04/2027</b>. Desses, 189 também ficam abaixo do corte adicional de 5min17s, sem confirmar inscrição ou aceitação.</p>
 <p class="note">As linhas “Total de concluintes” são subtotais por sexo de geral/elite e PCD/DV; não são um grupo adicional para somar. Excluem cadeirantes. O recorte de desempenho convencional das outras seções tem população própria.</p>
 ${table(['Floripa · recorte','Sexo','Concluintes','Atingiram o índice','Taxa'],b.floripa.map(r=>[recorte(r.recorte),sexo(r.sexo),n(r.concluintes),n(r.atingiram_bq),pc(r.percentual_bq)]))}
 <h3>Gerações entre os concluintes com índice</h3>
 ${table(['Geração','Concluintes','Atingiram o índice','Taxa de índice','Parcela dos índices'],b.curiosidades.geracoes.map(r=>[r.geracao,n(r.concluintes),n(r.bq),pc(r.taxa_bq),pc(r.percentual_dos_bq)]))}
 <p>169 dos 264 concluintes com índice tinham 40 anos ou mais; 34 tinham 60 ou mais. Houve 17 sub3h sem índice: um tempo absoluto isolado não determina a qualificação. Entre os concluintes com índice, as idades vão de 19 a 64 entre mulheres e de 22 a 75 entre homens, na referência de Boston.</p>
 <p class="note">Gerações por nascimento individual, sem usar a idade no dia de Boston para atribuir a geração. <a href="https://resultados.racetag.com.br/mycrono/#/maratona-de-floripa-2026" target="_blank" rel="noopener">Consultar resultado oficial de Floripa</a>.</p></div>
 </details>
 <details class="boston-case">
 <summary><span class="boston-number" aria-hidden="true">02</span><span class="boston-case-title"><strong>NB Porto Alegre 2026</strong><span>Foi possível confirmar os 908 índices divulgados?</span></span></summary>
 <div class="boston-case-content"><div class="boston-result"><strong>887</strong><div><h3>Mínimo verificável na tabela geral</h3><p>670 homens e 217 mulheres de geral/elite.</p></div></div>
 <p>Os 908 divulgados são compatíveis com as faixas disponíveis, mas não foram confirmados. Sem nascimento individual, o intervalo teórico vai até 1.259. <b>Esse teto não é uma estimativa</b>; indica o limite da incerteza das idades. PCD permanece separado.</p>
 <h3>Conferência por sexo e recorte</h3>
 ${table(['Recorte','Sexo','Classificados','Mínimo verificável','Teto teórico','Divulgado no post'],b.nb.map(r=>[recorte(r.recorte),sexo(r.sexo),n(r.classificados),n(r.minimo_pelo_indice_geral),n(r.teto_teorico_nao_estimativa),n(r.publicado_no_post)]))}
 <p class="note">A confirmação exige idade individual adequada à referência de Boston. Os limites aplicam a tabela geral e não substituem os critérios específicos de paratletismo. <a href="https://nb42kportoalegre.runking.com.br/results" target="_blank" rel="noopener">Consultar resultado oficial da NB Porto Alegre</a>.</p></div>
 </details>
 <p class="note boston-sources">Fontes oficiais recapturadas em 05/10/2026 · <a href="/estudo/?caderno=6&amp;secao=66">Notebook · congelamentos 207–210 e nota editorial 448</a> · <a href="https://www.baa.org/races/boston-marathon/qualify/" target="_blank" rel="noopener">Critérios da B.A.A.</a>. Próximo aprofundamento: verificar fontes e critérios comparáveis para avaliar uma análise das dez maiores; estes dois casos não antecipam esse ranking.</p>
 </section>`;
}

function brasilGiganteInsert(){
 const G=D.brasil_gigante;if(year!==2026||!G)return '';
 const C=G.cohort,T=G.subtotal,A=G.adoption,B=G.benchmark,F=G.sensitivity.without_floripa;
 const day=x=>x?x.slice(8,10)+'/'+x.slice(5,7):'—';
 const fullDate=x=>x?day(x)+'/'+x.slice(0,4):'—';
 const growth=r=>r.pending?'Fora do corte':r.new?'Estreia':signed(r.delta.percent);
 const rows=G.stages.map(r=>`<tr><th scope="row">${e(r.label)}<small>${day(r.official_date_2026)}/2026${r.id==='joao-pessoa'?' · prova de agosto':''}</small></th><td>${r.metrics2025?n(r.metrics2025.total):'—'}${r.pending?'<small>outubro · fora do corte</small>':''}</td><td>${r.metrics2026?n(r.metrics2026.total):'—'}${r.pending?'<small>prevista para novembro</small>':''}</td><td>${growth(r)}</td></tr>`).join('');
 const quality=G.stages.filter(r=>r.quality_notes.length).map(r=>`<h4>${e(r.label)}</h4><ul>${r.quality_notes.map(x=>'<li>'+e(x)+'</li>').join('')}</ul>`).join('');
 const notebook=`<a href="/estudo/?caderno=6&amp;secao=${Number(G.meta.notebook_section)}">Notebook · encarte Brasil Gigante</a>`;
 return `<section id="brasil-gigante" class="gigante-insert">
 <div class="gigante-heading"><div><p class="eyebrow">ENCARTE ESPECIAL · CIRCUITO BRASIL GIGANTE · 2026</p><h2>Oito maratonas.<br>Como o circuito está evoluindo?</h2></div><div class="gigante-eight" aria-label="Oito etapas no circuito"><strong>8</strong><span>etapas<br>pelo Brasil</span></div></div>
 <p class="gigante-lead">Sete etapas até setembro, uma estreia e seis provas com edições comparáveis. O volume registrado ainda mostra movimentos diferentes entre as cidades.</p>
 <div class="gigante-scope"><b>O ponto de partida importa.</b> O circuito foi anunciado em abril de 2026. Os resultados de 2025 são uma referência anterior ao projeto. Aracaju, prevista para 1º de novembro, está fora deste recorte.</div>
 <div class="grid gigante-kpis">${card(n(T.total2026),'Conclusões nas sete etapas','42 km · janeiro a setembro de 2026. Uma pessoa pode concluir várias etapas.')}${card(signed(C.percent),'Nas seis provas comparáveis',n(C.base_total)+' em 2025 → '+n(C.total)+' em 2026.')}${card(n(T.new2026),'Conclusões na estreia do Paraná','Volume novo no conjunto de etapas; sem base de 2025 para calcular crescimento.')}</div>
 <p class="gigante-equation"><span><b>${n(C.base_total)}</b> nas seis em 2025</span><span aria-hidden="true">${C.absolute<0?'−':'+'}</span><span><b>${n(Math.abs(C.absolute))}</b> nessas provas</span><span aria-hidden="true">+</span><span><b>${n(T.new2026)}</b> na estreia</span><span aria-hidden="true">=</span><span><b>${n(T.total2026)}</b> em sete etapas</span></p>
 <div class="gigante-block"><p class="eyebrow">01 · EVOLUÇÃO DOS 42 KM</p><h3 class="gigante-title">${n(C.growing)} etapas cresceram. ${n(C.declining)} recuaram.</h3>
 ${plot('gigante-pairs','As seis mesmas maratonas · conclusões em cada edição')}
 <p class="note">Todos os pares são de janeiro a setembro nos dois anos. O percentual consolidado divide a soma de 2026 pela soma de 2025; não é a média das variações individuais. Os números medem conclusões registradas, sujeitos à cobertura da coleta.</p>
 <h3>As oito etapas, sem perder nenhuma de vista.</h3><p class="note">A coluna de 2025 mostra a edição de referência de cada prova. Aracaju aparece para completar o circuito, mas não entra nas somas nem nas variações do período.</p>
 <div class="scroll gigante-table-scroll" tabindex="0"><table class="gigante-table"><caption>Concluintes dos 42 km · datas de 2026 do calendário oficial</caption><thead><tr><th scope="col">Etapa</th><th scope="col">Edição 2025</th><th scope="col">2026 · até setembro</th><th scope="col">Variação</th></tr></thead><tbody>${rows}</tbody><tfoot><tr><th scope="row">Mesmas seis provas</th><td>${n(C.base_total)}</td><td>${n(C.total)}</td><td>${signed(C.percent)}</td></tr><tr><th scope="row">Sete etapas de 2026<small>inclui a estreia do Paraná</small></th><td>—</td><td>${n(T.total2026)}</td><td>Base ampliada</td></tr></tfoot></table></div>
 <p class="note"><b>João Pessoa:</b> a Internacional de agosto tem ${n(G.stages.find(r=>r.id==='joao-pessoa').metrics2026.total)} concluintes na base e 332 no balanço oficial. A diferença de três segue em conferência. É uma prova distinta da Maratona de João Pessoa de abril.</p>
 ${details('Perfil e desempenho nas sete etapas de 2026',`<div class="grid smallmetrics">${card(pc(T.female2026/T.total2026*100),'Participação feminina',n(T.female2026)+' conclusões femininas.')}${card(pc(T.sub4_2026/T.total2026*100),'Abaixo de quatro horas',n(T.sub4_2026)+' conclusões sub4h; corte estrito.')}${card(n(T.stages2026),'Etapas no período','Aracaju fica para a edição anual.')}</div>${table(['Etapa','Mulheres','% feminino','Mediana','Sub4h','% sub4h'],G.stages.filter(r=>r.metrics2026).map(r=>{const m=r.metrics2026;return[r.label,n(m.female),pc(m.female/m.total*100),time(m.median_seconds),n(m.sub4),pc(m.sub4/m.total*100)]}))}<p class="note">A mediana é o tempo que divide o pelotão em duas metades. Tempos, percurso, clima e composição do público diferem entre as provas; este quadro não avalia a qualidade da organização.</p>`)}
 </div>
 <div class="gigante-block"><p class="eyebrow">02 · O PESO DE CADA PROVA</p><h3 class="gigante-title">A conclusão muda quando mudam as provas.</h3>
 <div class="twocol gigante-context"><article><strong>${signed(F.percent)}</strong><h4>No circuito, sem Floripa</h4><p>As outras ${n(F.pairs)} provas passam de ${n(F.base_total)} para ${n(F.total)} conclusões. Floripa registra ${n(G.stages.find(r=>r.id==='floripa').metrics2025.total)} → ${n(G.stages.find(r=>r.id==='floripa').metrics2026.total)} e influencia o saldo das seis.</p></article><article><strong>${signed(B.all.percent)}</strong><h4>Nas ${n(B.all.pairs)} comparáveis fora do circuito</h4><p>${n(B.all.base_total)} → ${n(B.all.total)} conclusões. Ao retirar a NB Porto Alegre, o crescimento das outras ${n(B.without_nb.pairs)} fica em ${signed(B.without_nb.percent)}.</p></article></div>
 <p class="note">As exclusões acima mostram a sensibilidade do agregado; não substituem os conjuntos completos. As outras maratonas servem como referência descritiva, com tamanhos e características diferentes. Não constituem um grupo de controle para medir o efeito do circuito.</p>
 ${details('Ver as maratonas usadas como referência externa',table(['Prova fora do circuito','Jan–Set 2025','Jan–Set 2026','Variação'],B.all.events.map(r=>[short(r.label),n(r.base_total),n(r.total),signed((r.total/r.base_total-1)*100)])))}
 </div>
 <div class="gigante-block"><p class="eyebrow">03 · ADESÃO E PARTICIPAÇÃO EM MAIS DE UMA ETAPA</p><h3 class="gigante-title">O circuito já tem uma base de corredores.</h3>
 <p>Agora contamos <b>contas cadastradas no Brasil Gigante</b>, uma vez cada. Esse universo é diferente das conclusões de todos os corredores das provas.</p>
 <div class="grid">${card(n(A.registered),'Cadastros no circuito','Contas inscritas até 30 de setembro de 2026.')}${card(n(A.with_result),'Com resultado em alguma etapa','Ao menos um resultado de 42 km de 2026 associado à conta.')}${card(n(A.two_or_more),'Com resultados em duas ou mais','Contas distintas, considerando as etapas até setembro.')}</div>
 <p class="note">Resultados associados na consulta de ${fullDate(A.queried_at)}, inclusive vínculos feitos depois das provas. O circuito aceita validações retroativas. Não ter resultado associado não significa não ter corrido, e ter duas etapas não prova que o circuito motivou a segunda participação.</p>
 ${details('Distribuição de etapas por conta e critérios de adesão',table(['Etapas de 2026 com resultado associado','Contas'],A.distribution.map(r=>[r.stages===0?'Nenhuma associada':n(r.stages),n(r.accounts)]))+'<p class="note">Cadastro e data das provas limitados a 30/09/2026. Cada conta é contada uma vez por etapa; não são somadas linhas duplicadas de resultado. A apuração operacional usa o BI tratado e vínculos atuais. Em Floripa, ele contém 3.594 registros; o volume editorial acima usa 3.592 de Geral/Elite da fonte oficial. Os denominadores não são misturados.</p>')}
 </div>
 <div class="gigante-verdict"><p class="eyebrow">O QUE PODEMOS CONCLUIR ATÉ AQUI</p><h3>Há adesão. O aumento causado pelo circuito ainda precisa ser demonstrado.</h3><p>O saldo das mesmas seis provas foi de <b>${n(Math.abs(C.absolute))} conclusões ${C.absolute<0?'a menos':'a mais'}</b>. A estreia do Paraná amplia o volume do conjunto, e há corredores com resultados em várias etapas. Esses sinais não bastam para atribuir ao projeto novas inscrições nos 42 km.</p><p>Para medir esse efeito, o próximo acompanhamento deve separar inscrição feita antes da prova, participação posterior em outra etapa e motivação declarada pelo corredor, além de conferir a cobertura dos resultados entre anos.</p></div>
 ${details('Fontes, conciliação e regras deste encarte',`<p>${notebook}. Corte: 30/09/2026. Resultados e metodologia congelados em ${e(G.meta.frozen_date||'23/10/2026')}. Consultas anteriores do estudo foram preservadas.</p>${quality}<p>Calendário e contexto: <a href="https://circuitobrasilgigante.com.br/" target="_blank" rel="noopener">site oficial do Brasil Gigante</a> · <a href="https://circuitobrasilgigante.com.br/noticias/circuito-de-oito-maratonas-brasil-gigante-e-lancado-para-democratizar-as-provas-de-42-km-no-pais-2/?lang=pt-br" target="_blank" rel="noopener">anúncio de abril de 2026</a> · <a href="https://circuitobrasilgigante.com.br/sobre/" target="_blank" rel="noopener">funcionamento e validação de etapas</a> · <a href="https://circuitobrasilgigante.com.br/noticias/joao-pessoa-marca-a-quinta-etapa-do-brasil-gigante-que-reune-corredores-em-jornada-pelas-oito-maratonas/" target="_blank" rel="noopener">balanço de João Pessoa</a> · <a href="https://www.maratonainternacionalpr.com.br/_files/ugd/4113c7_bb907a07911d44439d2933c673860efe.pdf" target="_blank" rel="noopener">regulamento do Paraná</a>.</p><p class="note">Congelamento deste encarte: ${n(G.meta.publication_run)}; consulta ${n(G.meta.publication_cell)}, seção ${n(G.meta.notebook_section)}. Congelamentos de origem: ${G.meta.source_runs.map(n).join(', ')}. O encarte agrega suas etapas e inclui João Pessoa Internacional pelo inventário; não altera os totais da seleção geral de 39 maratonas.</p>`)}
 </section>`;
}
function brasilGiganteCharts(){
 if(year!==2026||!D.brasil_gigante)return;
 const rows=D.brasil_gigante.stages.filter(r=>r.comparable).sort((a,b)=>b.metrics2026.total-a.metrics2026.total);
 chart('gigante-pairs',rows.map(r=>r.id==='joao-pessoa'?['João Pessoa','Internacional']:r.label),[2025,2026].map((y,i)=>({label:String(y)+' · Jan–Set',data:rows.map(r=>r['metrics'+y].total),backgroundColor:i?'#F7BC28':'#b4a0d9',borderRadius:4})));
}

function marketContext(){
 const C=D.context.years[year],R=C.registered;
 return section('contexto','ESCALA DA MARATONA · '+period(year),'Quanto os 42 km representam na corrida brasileira?',`<div class="grid">${card(pc2(C.share),'Das conclusões são de 42 km','Participação na base geral de corrida de rua.')}${card(n(C.marathon),'Conclusões nos 42 km','Percursos de 42 a 42,2 km, no período desta edição.')}${card(n(C.total),'Conclusões com distância válida','Base de corrida de rua usada no comparativo abaixo.')}</div><p>Os 42 km são uma parte do conjunto das corridas de rua. Aqui entram os resultados da base geral, com os mesmos critérios entre as distâncias; o recorte é mais amplo que as ${n(D.years[year].races.length)} maratonas selecionadas para este estudo. Registros com modalidade ou distância pendente de revisão permanecem nesta base geral.</p><div class="twocol">${plot('market-distances','Como as conclusões se distribuem entre as distâncias')}${plot('market-female','Participação feminina dentro de cada distância')}</div><p class="note">Cada barra de participação feminina usa o total da própria distância como denominador. Distâncias: 5 e 10 km exatos; 21 a 21,2 km; 42 a 42,2 km; demais distâncias agrupadas em “Outras”. Conclusões não são pessoas únicas: um corredor pode aparecer em mais de uma prova. A edição de 2025 cobre o ano completo; a de 2026, janeiro a setembro. A troca de edição não constitui uma comparação de crescimento entre períodos equivalentes.</p>${details('Ver valores e fontes do contexto',table(['Distância','Conclusões','Parcela do volume','Mulheres','Participação feminina'],C.distances.map(r=>[r.label,n(r.total),pc2(r.share),n(r.female),r.female_share==null?'—':pc(r.female_share)]))+'<p class="note">Notebook · congelamento '+n(D.context.run)+'. Derivação da base congelada '+n(C.source_run)+', no período indicado nesta edição. Não dividir o volume da seleção de maratonas pelo total geral para calcular esta participação.</p>')}<div class="market-registry"><p class="eyebrow">OUTRA MEDIDA · O CALENDÁRIO CADASTRADO</p><h3>Quantas provas oferecem uma maratona?</h3><div class="grid smallmetrics">${card(n(R.events),'Provas com 42 km cadastrados','Percurso de rua de 42 a 42,2 km informado no cadastro.')}${card(pc(R.share),'Do calendário de corrida de rua',n(R.events)+' de '+n(R.denominator)+' provas no mesmo período.')}${card(n(R.with_results),'Com resultados de 42 km coletados','A presença de resultados não confirma uma coleta completa.')}</div><p class="note">Cadastro, coleta e seleção editorial são medidas diferentes. Prova cadastrada não confirma realização. Estes números não são o tamanho da seleção de ${n(D.years[year].races.length)} maratonas, e não representam uma contagem de atletas. Fonte do cadastro: ${year===2025?'congelamento 137, coleta de 03/10/2026':'congelamento 174, coleta de 05/10/2026'}; período ${year===2025?'janeiro a dezembro de 2025':'janeiro a setembro de 2026'}.</p></div>`);
}
function internationalScale(){
 const N=D.context.nyc,ratio=N.brazil_top10/N.finishers*100;
 return section('nova-york','REFERÊNCIA INTERNACIONAL · ANO COMPLETO DE '+N.year,'Dez maratonas brasileiras e uma edição de Nova York.',`<p>Em ${N.year}, <b>Nova York reuniu ${n(N.finishers-N.brazil_top10)} concluintes a mais</b> que a soma das dez maratonas brasileiras desta seleção. É uma referência para discutir escala e oportunidades no país.</p><div class="grid">${card(n(N.brazil_top10),'Top 10 Brasil · '+N.year,'Soma das conclusões das dez provas selecionadas.')}${card(n(N.finishers),'Nova York · '+N.year,'Concluintes de uma edição, segundo os resultados da NYRR.')}${card(pc(ratio),'É a proporção Brasil Top 10 / NY','Referência de escala entre esses dois volumes.')}</div>${plot('nyc-scale','Conclusões em 2025 · dez provas brasileiras e uma edição de Nova York')}<div class="reading-note"><h3>O mesmo ano, com populações diferentes.</h3><p>Nova York reúne participantes internacionais; seu número não representa os Estados Unidos. A soma brasileira reúne dez eventos e pode contar a mesma pessoa mais de uma vez. Os critérios das fontes também diferem.</p><p>Este quadro não estima crescimento nem o tamanho do mercado nacional. ${year===2026?'Na edição parcial de 2026, mantemos a referência anual de 2025 explicitamente identificada. Nova York 2026 fica fora do corte de janeiro a setembro; não atribuímos a ela o resultado de 2025.':''}</p></div><p class="note">Fonte: <a href="${e(N.url)}" target="_blank" rel="noopener">resultados oficiais da NYRR · edição ${N.year}</a> · consulta em ${e(N.captured)} · notebook, congelamento ${n(D.context.run)}.</p>${details('Conferência da referência de Nova York','<p>O resultado consultado informa '+n(N.finishers)+' concluintes. O número anunciado anteriormente era '+n(N.previous_announced)+', uma diferença de '+n(Math.abs(N.previous_announced-N.finishers))+'. A causa dessa diferença não foi estabelecida. Este quadro usa o total da página de resultados consultada, com fonte e data registradas.</p>')}`);
}

// Integrar dentro da IIFE de report.js. Usa apenas os congelamentos já carregados.
// CNA: mesmos limites de 42 km e cores do estudo principal (consultas 274/351).
const cna42Definitions = [
  { label: 'Branca', color: '#ffffff', interval: '4h ou mais' },
  { label: 'Laranja', color: '#ff771c', interval: '3h45 até menos de 4h' },
  { label: 'Amarela', color: '#f5b21b', interval: '3h30 até menos de 3h45' },
  { label: 'Azul', color: '#4886c2', interval: '3h15 até menos de 3h30' },
  { label: 'Vermelha', color: '#f44346', interval: '3h até menos de 3h15' },
  { label: 'Marrom', color: '#895e29', interval: '2h45 até menos de 3h' },
  { label: 'Preta', color: '#111111', interval: '2h30 até menos de 2h45' },
  { label: 'Mestre', color: '#c6c6c6', interval: 'Tempo positivo abaixo de 2h30' }
];

function cna42Rows() {
  const values = s('cna_42k')?.values || [];
  return cna42Definitions.map(definition => ({
    ...definition,
    value: values.find(value => value.label === definition.label)
  }));
}

function cnaLegend() {
  const rows = cna42Rows();
  if (!rows.some(row => row.value?.value != null)) return '';
  const bases = [...new Set(rows.map(row => row.value?.denominator).filter(value => value != null))];
  const baseNote = bases.length === 1
    ? `Base CNA: ${n(bases[0])} participações de 42–42,2 km.`
    : 'Os denominadores de cada faixa estão registrados na tabela de fontes.';
  const renderedRows = rows.map(row => `<tr>
    <th scope="row"><span aria-hidden="true" style="display:inline-block;width:1rem;height:1rem;margin-right:.5rem;vertical-align:middle;background:${row.color};border:1px solid #242424;border-radius:2px"></span>${e(row.label)}</th>
    <td>${e(row.interval)}</td>
    <td>${row.value?.value == null ? '—' : pc(row.value.value)}</td>
    <td>${n(row.value?.count)}</td>
  </tr>`).join('');
  return `<div class="cna-legend">
    <p><b>Faixas de Sérgio Rocha, do canal Corrida no Ar.</b> A cor acompanha um intervalo de tempo; nomes e limites permitem ler o gráfico sem depender da cor.</p>
    <div class="scroll" tabindex="0"><table>
      <caption>Legenda e valores das faixas CNA · 42 km · ${e(period(year))}</caption>
      <thead><tr><th scope="col">Faixa</th><th scope="col">Tempo de conclusão</th><th scope="col">Participações (%)</th><th scope="col">Participações</th></tr></thead>
      <tbody>${renderedRows}</tbody>
    </table></div>
    <p class="note">Cada participação ocupa uma única faixa. O limite inicial entra e o final pertence à faixa seguinte: exatamente 4h é Branca; exatamente 2h30 é Preta. Tempos nulos e zero ficam fora.</p>
    <p class="note">${e(baseNote)} Este recorte não se restringe a corridas de rua e usa PCD=false e ranking elegível. Não equivale à seleção de maratonas revisadas nem a pessoas únicas. As pendências de modalidade e cadastro permanecem documentadas nas fontes.</p>
  </div>`;
}

// Chamar depois de inserir plot('cna', ...) no DOM; substitui seriesChart('cna', ...).
function cnaChart() {
  const rows = cna42Rows();
  if (!rows.some(row => row.value?.value != null)) return;
  chart('cna', rows.map(row => [row.label, row.interval]), [{
    label: 'Participações (%)',
    data: rows.map(row => row.value?.value == null ? null : Number(row.value.value)),
    backgroundColor: rows.map(row => row.color),
    borderColor: '#242424',
    borderWidth: 1,
    borderSkipped: false,
    borderRadius: 3
  }], { percent: true });
}

function registryReviewDetails() {
  if (year !== 2026) return '';
  const meta = D.years[year].meta?.maratonas_revisao;
  const source = s('maratonas_revisao_eventos');
  const safeLink = (url, label) => /^https?:\/\//i.test(String(url || '').trim())
    ? `<a href="${e(String(url).trim())}" target="_blank" rel="noopener noreferrer">${e(label)}</a>`
    : '';
  const dateLabel = value => /^\d{4}-\d{2}-\d{2}/.test(String(value || ''))
    ? String(value).slice(0, 10).split('-').reverse().join('/')
    : String(value || 'Data não informada');
  const cases = Array.isArray(meta?.casos) ? meta.casos : [];
  if (!cases.length) {
    if (!source?.values?.length) return '';
    return `<details class="registry-review"><summary>Revisão de cadastro · evidências registradas por prova</summary>
      <p class="note">${e(source.note || '')}</p>
      ${source.values.map(value => `<details><summary>${e(value.label)} · ${e(value.value)}</summary><p>${e(value.note || 'Evidência não informada neste congelamento.')}</p><p class="note">${e(value.source || '')}</p></details>`).join('')}
    </details>`;
  }
  const summary = Array.isArray(meta.resumo) && meta.resumo.length
    ? table(['Situação na revisão', 'Eventos'], meta.resumo.map(item => [item.situacao, n(item.eventos)]))
    : '';
  const entries = cases.map(item => {
    const links = (Array.isArray(item.referencias) ? item.referencias : [])
      .map((url, index) => safeLink(url, `Fonte ${index + 1}`)).filter(Boolean);
    if (item.tag) links.push(safeLink(`https://roadrunners.run/evento/${encodeURIComponent(item.tag)}/`, 'Cadastro no portal'));
    return `<details class="registry-review-case">
      <summary>#${e(item.id_evento)} · ${e(item.nome_evento)} — ${e(item.situacao)}</summary>
      <p class="note">${e(dateLabel(item.data_final))} · ${e(item.cidade)}/${e(item.estado)}</p>
      <p><b>${n(item.elegiveis)} linhas pela regra da auditoria</b>, entre ${n(item.linhas_brutas)} linhas brutas. Essas quantidades não são novos concluintes validados de maratona.</p>
      <h4>Evidência registrada</h4><p>${e(item.evidencia || 'Sem evidência descritiva neste congelamento.')}</p>
      <h4>Próximo passo</h4><p>${e(item.proximo_passo || 'Ação ainda não registrada.')}</p>
      ${links.length ? `<p>${links.join(' · ')}</p>` : ''}
    </details>`;
  }).join('');
  return `<details class="registry-review">
    <summary>${n(cases.length)} eventos com cadastro a revisar · evidências, ações e fontes</summary>
    <p>Esta é a revisão congelada de ${e(dateLabel(meta.verificado_em))}, sobre resultados marcados como 42 km sem percurso de rua correspondente no cadastro. Não representa o andamento atual de cada correção.</p>
    ${summary}
    <p class="note">Confirmar 42 km na fonte não comprova terreno de rua, conclusão individual, homologação ou coleta completa. A regra de triagem também admitia revezamentos e eventos de outro esporte. Os casos abaixo não são acrescentados automaticamente à seleção do estudo.</p>
    ${entries}
    <p class="note">Auditoria: congelamento ${n(meta.fonte_auditoria)}, célula ${n(meta.celula_auditoria)}. Decisões e referências: congelamento ${n(meta.execucao)}, célula ${n(meta.celula)}. Esta apresentação recupera as evidências já publicadas; não modifica cadastros, resultados ou indicadores.</p>
  </details>`;
}

const crossingDistanceBands = [
  { key: 'Até 5 km', label: 'Menos de 6 km' },
  { key: '6 a 10 km', label: '6 a menos de 11 km' },
  { key: '11 a 29 km', label: '11 a menos de 30 km' },
  { key: '+30 km', label: '30 km ou mais' }
];

function principalContextSeries(id) {
  return D.context?.years?.[year]?.principal_series?.find(item => item.id === id);
}

function crossingRows() {
  const assigned = ['Alfa', 'Menos de 14', 'Geração Z', 'Millennials', 'Geração X', 'Boomers', 'Anteriores a 1946'];
  return crossingDistanceBands.map(band => {
    const generations = principalContextSeries('geracao_dentro_distancia_' + band.key);
    const values = generations?.values || [];
    const percent = labels => {
      const selected = values.filter(value => labels.includes(value.label));
      return selected.length ? selected.reduce((total, value) => total + Number(value.value), 0) : null;
    };
    return {
      ...band,
      generations,
      millennials: percent(['Millennials']),
      generationX: percent(['Geração X']),
      generationZ: percent(['Geração Z']),
      alfa: percent(['Alfa', 'Menos de 14']),
      boomers: percent(['Boomers']),
      earlier: percent(['Anteriores a 1946']),
      otherGenerations: percent(['Alfa', 'Menos de 14', 'Boomers', 'Anteriores a 1946']),
      unassigned: percent(values.filter(value => !assigned.includes(value.label)).map(value => value.label)),
      generationBase: values[0]?.denominator
    };
  });
}

function crossingContext() {
  const rows = crossingRows();
  if (!rows.some(row => row.generations)) return '';
  const fmt = value => value == null ? '—' : pc(value);
  const sources = [...new Set(rows.flatMap(row => [
    ...(row.generations?.values || [])
  ]).map(value => value.source).filter(Boolean))];
  const unassigned = rows.find(row => row.key === '+30 km')?.unassigned;
  return section('perfil-distancias', 'CONTEXTO DO ESTUDO PRINCIPAL · ' + period(year), 'Quem aparece em cada faixa de distância?', `
    <p>Esta leitura coloca as distâncias longas ao lado das mais curtas. <b>30 km ou mais inclui maratonas e outras distâncias</b>; não é um recorte exclusivo dos 42 km nem da seleção de maratonas deste estudo.</p>
    ${plot('crossing-generations', 'Gerações dentro de cada faixa de distância')}
    <p class="note">São percentuais de participações, não de pessoas únicas. As faixas são: distância positiva abaixo de 6 km; 6 a menos de 11 km; 11 a menos de 30 km; 30 km ou mais. O gráfico de gerações mantém toda a base, inclusive os casos sem classificação.</p>
    <p class="note">Cada faixa de distância usa seu próprio total de participações como denominador.${unassigned == null ? '' : ' Nos 30 km ou mais, ' + pc(unassigned) + ' da base permanece sem geração atribuída.'} A troca de edição não mede mudança de perfil: 2025 é anual e 2026 cobre janeiro a setembro, com coberturas de idade diferentes.</p>
    <details><summary>Valores, composição das gerações e fontes</summary>
      ${table(['Faixa de distância', 'Alfa', 'Geração Z', 'Millennials', 'Geração X', 'Boomers', 'Anteriores a 1946', 'Sem geração atribuída', 'Base'], rows.map(row => [
        row.label, fmt(row.alfa), fmt(row.generationZ), fmt(row.millennials), fmt(row.generationX), fmt(row.boomers), fmt(row.earlier), fmt(row.unassigned), n(row.generationBase)
      ]))}
      <p>“Outras gerações” reúne Alfa, Boomers e nascidos antes de 1946. “Sem geração atribuída” mantém os registros sem idade informada ou com geração indeterminada. As categorias infantis da fonte foram reunidas em Alfa, por serem compatíveis com nascimento a partir de 2010 nas duas edições; trata-se de uma aproximação pela categoria, sem imputar idade individual.</p>
      <p>Gerações seguem a referência de idade em 31/12: nascimento plausível tem prioridade; quando necessário, usa-se a faixa etária, com aproximação pela idade central conforme a regra documentada no notebook. A informação disponível e o grupo atribuído não equivalem a uma idade individual conhecida.</p>
      <ul>${sources.map(source => '<li>' + e(source) + '</li>').join('')}</ul>
      <p class="note">Contexto reunido no congelamento ${n(D.context.run)}. Os valores preservam os congelamentos das séries do estudo principal; não foram recalculados a partir da seleção de maratonas.</p>
    </details>${crossingInverseDetails()}`);
}

// Chamar depois de inserir crossingContext() no DOM.
function crossingCharts() {
  const rows = crossingRows();
  if (!rows.some(row => row.generations)) return;
  const labels = rows.map(row => row.label);
  const groups = [
    ['Millennials', 'millennials', '#F7BC28'],
    ['Geração X', 'generationX', '#b4a0d9'],
    ['Geração Z', 'generationZ', '#7fb7a6'],
    ['Outras gerações', 'otherGenerations', '#8a99ad'],
    ['Sem geração atribuída', 'unassigned', '#d6d6d6']
  ];
  chart('crossing-generations', labels, groups.map(([label, key, color]) => ({
    label, data: rows.map(row => row[key]), backgroundColor: color
  })), { percent: true, stacked: true });
}

function cnaDistanceComparison() {
  // Matriz das consultas CNA 274 e 351; a nota de 2026 não contém os limites individuais.
  const thresholds = {
    cna_5k: [1800, 1620, 1500, 1320, 1200, 1020, 900, 0],
    cna_10k: [3600, 3300, 3000, 2700, 2520, 2400, 2100, 0],
    cna_21k: [7200, 6600, 6300, 6000, 5400, 5100, 4800, 0],
    cna_42k: [14400, 13500, 12600, 11700, 10800, 9900, 9000, 0]
  };
  const duration = seconds => [Math.floor(seconds / 3600), Math.floor(seconds % 3600 / 60), seconds % 60].map(value => String(value).padStart(2, '0')).join(':');
  const interval = (id, index) => {
    const limits = thresholds[id];
    return (index === 7 ? '> ' : '≥ ') + duration(limits[index]) + (index ? ' e < ' + duration(limits[index - 1]) : '');
  };
  const distances = [
    { id: 'cna_5k', label: '5 km exatos' },
    { id: 'cna_10k', label: '10 km exatos' },
    { id: 'cna_21k', label: '21 a 21,1 km' },
    { id: 'cna_42k', label: '42 a 42,2 km' }
  ].map(distance => ({ ...distance, series: principalContextSeries(distance.id) }));
  if (!distances.some(distance => distance.series?.values?.length)) return '';
  const bandValue = (distance, label) => distance.series?.values?.find(value => value.label === label);
  const sources = [...new Set(distances.flatMap(distance => distance.series?.values || []).map(value => value.source).filter(Boolean))];
  return `<details class="cna-distance-comparison"><summary>Como as faixas CNA se distribuem nos 5, 10, 21 e 42 km?</summary>
    <p>A mesma cor tem <b>limites de tempo próprios em cada distância</b>. Estes quadros mostram a proporção dentro de cada base CNA; não são um ranking de atletas nem uma equivalência direta de desempenho entre distâncias.</p>
    ${table(['Faixa CNA', ...distances.map(distance => distance.label)], cna42Definitions.map(definition => [definition.label, ...distances.map(distance => {
      const value = bandValue(distance, definition.label);
      return value?.value == null ? '—' : pc(value.value);
    })]))}
    <h4>Limites de tempo por distância</h4>
    ${table(['Faixa CNA', ...distances.map(distance => distance.label)], cna42Definitions.map((definition, index) => [definition.label, ...distances.map(distance => interval(distance.id, index))]))}
    <p class="note">“≥” inclui o tempo indicado e “&lt;” exclui o limite seguinte. Tempos nulos ou zero ficam fora. Cada distância tem um denominador próprio e suas oito faixas somam 100%, antes do arredondamento.</p>
    ${table(['Distância', 'Base de participações'], distances.map(distance => [distance.label, n(distance.series?.values?.[0]?.denominator)]))}
    <p class="note">Faixas de Sérgio Rocha / Corrida no Ar. Recorte com resultado homologado, concluinte, status 0, tempo positivo, PCD=false e ranking nulo ou diferente de false, sem restringir a modalidade a corrida de rua. Os limites de tempo seguem a matriz SQL das consultas 274/351. Os intervalos de distância da CNA podem diferir dos de outras seções. Não equivalem à seleção revisada de maratonas.</p>
    <ul>${sources.map(source => '<li>' + e(source) + '</li>').join('')}</ul>
    <p class="note">${e(period(year))} · contexto reunido no congelamento ${n(D.context.run)}. Comparação entre distâncias na mesma edição, sem inferir crescimento de 2025 anual para 2026 parcial.</p>
  </details>`;
}

function crossingInverseDetails() {
  const groups = [
    ['Mulheres', 'distancia_dentro_sexo_F'],
    ['Homens', 'distancia_dentro_sexo_M'],
    ['Millennials', 'distancia_dentro_geracao_Millennials'],
    ['Geração X', 'distancia_dentro_geracao_Geração X'],
    ['Geração Z', 'distancia_dentro_geracao_Geração Z']
  ].map(([label, id]) => ({ label, series: principalContextSeries(id) })).filter(group => group.series?.values?.length);
  if (!groups.length) return '';
  const sources = [...new Set(groups.flatMap(group => group.series.values).map(value => value.source).filter(Boolean))];
  return `<details class="crossing-inverse"><summary>Outra leitura: como as distâncias se distribuem dentro de cada grupo?</summary>
    <p>A pergunta muda: entre todas as participações de mulheres, homens ou de uma das gerações abaixo, qual parcela está em cada faixa de distância? <b>O denominador agora é o total daquele grupo</b>, com percurso positivo de rua; não é mais o total da faixa de distância.</p>
    ${table(['Grupo', 'Base própria', ...crossingDistanceBands.map(band => band.label)], groups.map(group => [group.label, n(group.series.values[0]?.denominator), ...crossingDistanceBands.map(band => {
      const value = group.series.values.find(value => value.label === band.key);
      return value?.value == null ? '—' : pc(value.value);
    })]))}
    <p class="note">Quadro de mulheres, homens, Millennials, geração X e geração Z. Não reúne todos os grupos da população. Cada linha se distribui entre as quatro faixas e soma 100% antes do arredondamento. A mesma participação aparece na leitura por sexo e por geração; não somar linhas de grupos diferentes. A faixa de 30 km ou mais inclui outras distâncias além da maratona.</p>
    <ul>${sources.map(source => '<li>' + e(source) + '</li>').join('')}</ul>
  </details>`;
}

function seriesChart(target,ids,options={}){const labels=s(ids[0]).values.map(v=>v.label);chart(target,labels.map(label=>target==='performance'?({'<3:00':'Até 3h','Até 3:00':'Até 3h','3:00–3:30':['Mais de 3h','até 3h30'],'<4:00':['Mais de 3h30','até 4h'],'3:30–4:00':['Mais de 3h30','até 4h'],'4:00–4:30':['Mais de 4h','até 4h30'],'4:30+':'Acima de 4h30'}[label]||label):short(label)),ids.map((id,i)=>({label:defs[id],data:labels.map(l=>{let v=s(id).values.find(v=>v.label===l)?.value;if(v==null)return null;if(options.time)return String(v).split(':').reduce((a,b)=>a*60+Number(b),0);return Number(v)}),backgroundColor:['#F7BC28','#b4a0d9','#7fb7a6'][i%3],borderRadius:4})),options);}
function allRacesSection(){
 const races=[...D.years[year].races].sort((a,b)=>b.total-a.total||a.id_evento-b.id_evento);
 const total=races.reduce((sum,r)=>sum+r.total,0),female=races.reduce((sum,r)=>sum+r.feminino,0),male=races.reduce((sum,r)=>sum+r.masculino,0);
 const date=value=>String(value).slice(0,10).replace(/^(\d{4})-(\d{2})-(\d{2})$/,'$3/$2/$1');
 return section('todas-maratonas','SELEÇÃO COMPLETA · '+period(year),'Todas as '+n(races.length)+' maratonas desta edição.',`<p>Esta é a relação completa das provas incluídas no estudo: <b>${n(races.length)} maratonas e ${n(total)} conclusões registradas</b>. Os gráficos e as fichas de desempenho destacam as dez maiores; esta tabela permite consultar cada prova da seleção.</p><p class="all-races-mobile-note note">Deslize a tabela para o lado para ver todas as colunas.</p><div class="scroll all-races-scroll" role="region" aria-label="Todas as maratonas da seleção de ${year}" tabindex="0"><table class="all-races-table"><caption>Ordem por número de concluintes · ${period(year)}</caption><thead><tr><th scope="col">Maratona · data e local</th><th scope="col">Concluintes</th><th scope="col">Mulheres</th><th scope="col">Homens</th></tr></thead><tbody>${races.map((r,i)=>`<tr data-event-id="${e(r.id_evento)}"><th scope="row"><span class="all-races-position">${n(i+1)}.</span> ${e(r.nome)}<small>${e(date(r.data))} · ${e(r.cidade)}/${e(r.uf)}</small></th><td>${n(r.total)}</td><td>${n(r.feminino)}</td><td>${n(r.masculino)}</td></tr>`).join('')}</tbody><tfoot><tr><th scope="row">Total · ${n(races.length)} maratonas</th><td>${n(total)}</td><td>${n(female)}</td><td>${n(male)}</td></tr></tfoot></table></div><p class="note">Concluintes representam conclusões registradas: a mesma pessoa pode participar de mais de uma prova. Esta seleção não é um censo de todas as maratonas realizadas no Brasil. As candidatas ainda não incluídas estão na seção <a href="#cobertura">Cobertura</a>.</p><p class="note">Fonte: <a href="/estudo/?caderno=6&amp;secao=66">notebook · congelamento ${year===2025?'252':'253, com a captura oficial de Floripa no congelamento 210'}</a>. Mesma seleção e mesmos totais do resumo desta edição; datas e localidades conforme o cadastro.</p>`);
}
function render(){charts.forEach(c=>c.destroy());charts=[];const Y=D.years[year],rs=Y.races,total=rs.reduce((a,r)=>a+r.total,0),female=rs.reduce((a,r)=>a+r.feminino,0);const top=topRaces(year),topTotal=top.reduce((a,r)=>a+r.total,0),topFemale=top.reduce((a,r)=>a+r.feminino,0);let html='';
html+=section('resumo',period(year),year===2026?'O retrato das maratonas até setembro de 2026.':'A referência de 2025: o ano completo.',`<div class="grid">${card(n(rs.length),'Maratonas na seleção',year===2026?'Provas de janeiro a setembro com resultados selecionados.':'Provas de janeiro a dezembro com resultados selecionados.')}${card(n(total),'Conclusões registradas','Uma pessoa pode concluir mais de uma maratona.')}${card(pc(female/total*100),'Participação feminina',n(female)+' conclusões na seleção.')}</div><div class="reading-note"><h3>Como ler este estudo</h3><p><b>Os gráficos e as fichas abaixo estão em ${year}.</b> O seletor fixo troca toda a edição.</p>${year===2026?'<p>O quadro de evolução compara apenas as mesmas provas, de janeiro a setembro nos dois anos. Os totais de 2025 anual e 2026 parcial têm períodos e seleções diferentes; eles não são usados para calcular crescimento.</p>':'<p>Esta edição reúne as provas selecionadas de janeiro a dezembro de 2025. O quadro de evolução compara as mesmas maratonas em 2024 e 2025, com o ano completo dos dois lados. Os gráficos de desempenho comparam as dez maiores dentro de 2025; perfil, calendário e território abrangem toda a seleção.</p>'}</div><p class="note">Seleção conciliada com a referência CR; não é um censo nacional. As dez maiores concentram as fichas de desempenho. Todas as provas estão na <a href="#todas-maratonas">relação completa das ${n(rs.length)} maratonas</a> e nos consolidados de perfil, calendário e território.</p>`);
html+=marketContext();
html+=crossingContext();
html+=internationalScale();
if(year===2026){
const P=D.pairs.coorte,nb=pairedRaces.find(r=>r.id2026===34235),growth=(P.n2026/P.n2025-1)*100,withoutNb=((P.n2026-nb.n2026)/(P.n2025-nb.n2025)-1)*100,nbContribution=(nb.n2026-nb.n2025)/(P.n2026-P.n2025)*100;
html+=section('pares','2025 × 2026 · JANEIRO A SETEMBRO NOS DOIS ANOS','Nas mesmas provas, o volume registrado aumentou.',`<div class="grid">${card(signed(growth),'Conclusões nos 17 pares',n(P.n2025)+' em 2025 → '+n(P.n2026)+' em 2026.')}${card(signed(withoutNb),'Ao retirar a NB Porto Alegre','Os outros 16 pares, nos mesmos nove meses.')}${card(pc(nbContribution),'Do aumento vem da NB',n(nb.n2025)+' → '+n(nb.n2026)+' conclusões registradas.')}</div><p>A comparação reúne <b>17 provas com uma edição em cada ano</b>, ligadas pelo mesmo agregador. Somamos as conclusões de cada lado antes de calcular a variação; não é a média das porcentagens individuais.</p>${plot('pairs','As dez maiores provas entre os 17 pares · conclusões registradas')}<p class="note">Cada dupla de barras representa a mesma prova em 2025 e 2026. O gráfico destaca os dez maiores pares por volume em 2026; os indicadores acima incluem todos os 17.</p>${details('Abrir os 17 pares e suas variações',table(['Prova','Jan–Set 2025','Jan–Set 2026','Variação'],pairedRaces.map(r=>[short(r.nome_evento),n(r.n2025),n(r.n2026),signed((r.n2026/r.n2025-1)*100)])))}<p class="note">Variação de resultados registrados. Diferenças na coleta ainda podem influenciar os números; este comparativo não isola crescimento real de melhora de cobertura. A coorte usa 5.210 resultados da NB; a análise específica de Boston usa uma captura oficial de 5.215.</p>`);
}else{html+=annualComparison(total);}
html+=section('top10','CAPÍTULO PRINCIPAL · MESMOS CONGELAMENTOS','As dez maiores, vistas por dentro.',`<p><b>${period(year)}.</b> As dez maiores maratonas da seleção, ordenadas por conclusões. Estes gráficos comparam provas dentro de ${year}.${year===2026?' A evolução entre anos está no quadro dos 17 pares acima.':' A evolução em relação a 2024 está no quadro dos '+n(D.pairs2025.coorte.pares)+' pares acima.'}</p><div class="grid">${card(n(topTotal),'Conclusões nas dez maiores','Soma das mesmas dez provas do quadro abaixo.')}${card(pc(topFemale/topTotal*100),'Participação feminina nas dez',n(topFemale)+' conclusões femininas na mesma seleção.')}${card(pc(topTotal/total*100),'Do volume da seleção ampliada',n(topTotal)+' de '+n(total)+' conclusões nas '+n(rs.length)+' maratonas selecionadas.')}</div><div class="twocol">${plot('volume','Participações por prova')}${plot('sex','Composição por sexo')}</div>${details('Ver os números das dez maiores',matrix(['maratonas_concluintes','maratonas_feminino','maratonas_masculino']))}${sourceDetails(['maratonas_concluintes','maratonas_feminino','maratonas_masculino','maratonas_destaques'])}`);
html+=allRacesSection();
html+=section('tempos','DESEMPENHO · DEZ MAIORES','O vencedor não conta a história toda.',`<p>A mediana divide os concluintes em duas metades. A média descreve o conjunto; o menor tempo mostra a ponta. Percurso, clima e composição dos participantes também influenciam o resultado.</p>${plot('times','Mínimo, média e mediana por prova')}${details('Comparar os tempos das dez maiores',matrix(['maratonas_tempo_menor','maratonas_tempo_medio','maratonas_tempo_mediano']))}${sourceDetails(['maratonas_tempo_menor','maratonas_tempo_medio','maratonas_tempo_mediano'])}`);
html+=section('cortes','DESEMPENHO · DEZ MAIORES','Quantos chegam antes das marcas de referência?',`<p>Sub4h, sub3h e sub2h30 são cortes cumulativos e estritos: quem corre abaixo de 2h30 também está nos outros dois. A quantidade revela volume; a porcentagem permite comparar tamanhos diferentes.</p>${plot('cuts','Proporção de concluintes por corte')}${details('Ver quantidades e porcentagens por prova',matrix(['maratonas_sub4_contagem','maratonas_sub4_percentual','maratonas_sub3_contagem','maratonas_sub3_percentual','maratonas_sub2h30_contagem','maratonas_sub2h30_percentual']))}${sourceDetails(['maratonas_sub4_contagem','maratonas_sub4_percentual','maratonas_sub3_contagem','maratonas_sub3_percentual','maratonas_sub2h30_contagem','maratonas_sub2h30_percentual'])}`);
html+=section('grupos','DESEMPENHO · DEZ MAIORES','Da elite à metade mais rápida.',`<p>Médias dos menores tempos: os 10 e 100 mais rápidos, depois os melhores 5%, 10% e 50%. Os grupos percentuais usam arredondamento para cima; empates de tempo são ordenados pelo identificador do resultado.</p>${plot('groups','Tempo médio dos grupos proporcionais')}${details('Comparar os cinco grupos das dez maiores',matrix(['maratonas_top10','maratonas_top100','maratonas_top5pct','maratonas_top10pct','maratonas_top50pct']))}${sourceDetails(['maratonas_top10','maratonas_top100','maratonas_top5pct','maratonas_top10pct','maratonas_top50pct'])}`);
html+=section('podios','COMPARAÇÃO ENTRE AS DEZ MAIORES','Onze indicadores. Um quadro de pódios.',`<p>Três contagens (sub4h, sub3h, sub2h30) e oito tempos (mínimo, médio, mediano e cinco grupos), com peso igual. Valores empatados compartilham posição. Este quadro compara o desempenho observado; não certifica a qualidade da organização ou do percurso.</p>${plot('medals','Ouros, pratas e bronzes')}${details('Ver o quadro de pódios das dez maiores',matrix(['maratonas_medalhas_ouro','maratonas_medalhas_prata','maratonas_medalhas_bronze']))}${sourceDetails(['maratonas_medalhas_ouro','maratonas_medalhas_prata','maratonas_medalhas_bronze'])}`);
html+=section('perfil','PERFIL · SELEÇÃO AMPLIADA','Quem está correndo essas maratonas?',`<p>Idades em 31/12 do ano da prova; nascimento plausível tem prioridade. Faixas inteiras que cruzam duas gerações seguem a idade central, sem repartir participantes. Idade e geração desconhecidas continuam no denominador.</p><div id="age-audit"></div><div class="twocol">${plot('ages','Faixas de dez anos · todas as participações')}${plot('generations','Gerações · todas as participações')}</div><div class="twocol">${plot('origins','Origem da informação de idade')}${plot('genSex','Gerações por sexo (%)')}</div><p class="note">População de perfil: ${n(D.notes[year].profile_total)}. ${year===2026?'Floripa: perfil/histograma usa BI 3594; desempenho usa fonte oficial 3592. Diferença total de dois registros, explicitada sem imputação de idade.':''} Alfa ≥2010; Z 1997–2009; Millennials 1981–1996; X 1965–1980; Boomers 1946–1964. Faixas abertas/indeterminadas não recebem geração por palpite.</p><details><summary>Todas as idades, gerações e critérios, por sexo</summary>${table(['Recorte','Sexo','Categoria','Participações','Base','%'],Y.profile.filter(r=>['idade','geracao','criterio','origem'].includes(r.bloco)).map(r=>[r.bloco,r.sexo,r.categoria,n(r.total),n(r.denominador),pc(r.percentual)]))}</details>`);
html+=section('territorio','CALENDÁRIO E TERRITÓRIO · SELEÇÃO AMPLIADA','Onde e quando o volume se concentra.',`<div class="twocol">${plot('uf','Participações por UF da prova')}${plot('months','Participações por mês da prova')}</div><p class="note">Localização do evento, não residência do atleta. Data final cadastrada. Paraná 2026 está em 28/04 no portal e 03/05 na referência CR; sua atribuição mensal é provisória. O total de janeiro a setembro não muda. Cadastro atual consultado em 19/10/2026.</p>`);
html+=section('catalogo','FICHAS · AS DEZ MAIORES DA EDIÇÃO','Uma prova por vez, com contexto.',`<p>As fichas se concentram nas dez maiores por conclusões em ${year}. Escolha uma prova para entender os tempos, os cortes de desempenho e a distribuição dos resultados. Consulte também a <a href="#todas-maratonas">relação completa das maratonas e seus concluintes</a>.</p><label for="race">Qual das dez maiores você quer explorar?</label><select id="race">${top.map((r,i)=>`<option value="${r.id_evento}">${i+1}. ${e(short(r.nome))} · ${n(r.total)} conclusões</option>`).join('')}</select><div id="race-detail"></div>`);
html+=section('base42','CONTEXTO · POPULAÇÕES DA BASE GERAL','Os 42 km além da seleção de provas.',`<p>Estes são os recortes de ritmo e faixas CNA do estudo principal. Eles têm filtros próprios e podem incluir registros em provas ainda não conciliadas. CNA não se restringe a corridas de rua. Não interpretar seus denominadores como total de maratonistas das seleções 41/39.</p><div class="twocol">${plot('performance','Distribuição de tempo, por sexo')}${plot('cna','Faixas CNA de 42 km')}</div>${cnaLegend()}${cnaDistanceComparison()}<p class="note">Performance: classes disjuntas, com limite superior inclusivo. Os rótulos do gráfico mostram os intervalos completos; por exemplo, acima de 3h30 até 4h não é o sub4h cumulativo. Os rótulos históricos ficam preservados na tabela de fontes. CNA: limite inferior inclusivo e superior exclusivo; critérios completos abaixo.</p>${sourceDetails(['performance_42k_geral','performance_42k_F','performance_42k_M','cna_42k'])}`);
if(year===2026)html+=bostonInsert();
if(year===2026)html+=brasilGiganteInsert();
html+=section('cobertura','CADASTRO, RESULTADOS E VALIDAÇÃO','Uma prova cadastrada não é uma prova auditada.',`<p>O inventário contém todas as candidatas com percurso cadastrado ou resultados de 42 km na base. Ausência de resultado, distância incorreta, revezamento e importações alternativas exigem revisão antes de somar.</p>${sourceDetails(['maratonas_cadastro','maratonas_revisao_situacoes','maratonas_revisao_eventos'])}${registryReviewDetails()}<details><summary>Inventário completo: ${Y.inventory.length} candidatas de ${year}</summary>${table(['ID','Prova','Data','UF','Percurso 42 cadastrado','Registros 42','Elegíveis','Sub2h a revisar','Modalidades excluídas'],Y.inventory.map(r=>[r.id_evento,r.nome_evento,r.data_final,r.estado,r.percurso_cadastrado?'Sim':'Não',n(r.linhas42),n(r.participacoes),n(r.sub2_auditar),n(r.modalidade_excluida)]))}</details><p><a href="https://contrarelogio.com.br/ranking-cr/">Ranking CR</a> · <a href="https://contrarelogio.com.br/veja-as-maratonas-que-devem-ter-percurso-aferido-e-serem-validas-para-o-ranking-cr-2026/">Candidatas 2026</a> · <a href="https://contrarelogio.com.br/atualizado-o-ranking-brasileiro-de-maratonistas-2025-acrescido-com-os-selecionados-em-manaus-joao-pessoa-brasilia-e-nb-porto-alegre/">Atualização parcial 2025</a>. Candidatas e atletas ranqueados não equivalem ao censo nacional.</p>`);
if(year===2026)html+=section('cenarios','APOIO INTERNO · NÃO É PROJEÇÃO NACIONAL','Um cenário para acompanhar até dezembro.',`<div class="grid">${card('61.452','Jan–Set observado')}${card('70.219','Q4 repetindo a referência')}${card('71.396','Q4 acompanhando a coorte')}</div><p>61.452 + 8.767 × fator. Fator 1 ou 1,1342215. Cauda: sete provas de Q4/2025 (Curitiba, Monumental, Sorocaba, Aracaju, Pomerode, Jurerê e Santa Cruz). Supõe repetição e cobertura equivalente; não é intervalo de confiança e não inclui todas as maratonas brasileiras.</p>`);
html+=section('fontes','NOTEBOOK COMO FONTE ÚNICA','Publicado a partir de resultados congelados.',`<p><a href="/estudo/?caderno=6&secao=66">Caderno 6 · seção 66</a>. Consultas novas e metodologia registradas; nenhuma query anterior do DBA foi substituída. Congelamentos 248–253 incorporam capítulo, casos especiais e desempenho. Os novos resultados por década e a auditoria de idades estão identificados na seção de perfil e no notebook. Seleção e comparação preservam 240–246. O contexto das distâncias, os cruzamentos e a referência de Nova York estão no congelamento ${n(D.context.run)}, com metodologia na célula 450.${year===2025?' O comparativo anual de 2024 × 2025 está no congelamento '+n(D.pairs2025.run)+'.':''}</p>${year===2025?annualPairSources():''}<p>A revisão atual é feita nesta versão web. Os PDFs anteriores permanecem apenas como arquivo e ainda não refletem esta organização; uma nova versão será gerada depois da validação.</p><details><summary>PDFs da versão anterior · não atualizados</summary><p><a href="arquivo.cfm?doc=maratonas-completo">PDF detalhado anterior · 82 páginas</a> · <a href="arquivo.cfm?doc=maratonas-piloto">Resumo executivo anterior · 7 páginas</a></p></details><p class="note">Pendências de dados: cobertura final CR; lacunas em 2025; distância/importação de FILA, Foz e Piracicaba 2026; conciliação de Floripa e nascimento para NB. Preço, licença e acesso comercial do vertical ainda serão definidos.</p><details><summary>${Y.series.length} séries do capítulo de maratonas</summary>${table(['Série','Conteúdo','Linhas'],Y.series.map(z=>[z.id,defs[z.id]||z.id,z.values.length]))}</details>${details('Séries auxiliares preservadas no congelamento '+n(D.context.run),table(['Série','Linhas'],D.context.years[year].principal_series.map(z=>[z.id,z.values.length])))}`);
root.innerHTML=html;document.getElementById('age-audit').innerHTML=ageAudit();
brasilGiganteCharts();
const C=D.context.years[year],N=D.context.nyc;
chart('market-distances',C.distances.map(r=>r.label),[{label:'Parcela das conclusões',data:C.distances.map(r=>Number(r.share)),backgroundColor:C.distances.map(r=>/^42/.test(String(r.label).trim())?'#F7BC28':'#7fb7a6'),borderRadius:4}],{percent:true});
chart('market-female',C.distances.map(r=>r.label),[{label:'Participação feminina',data:C.distances.map(r=>r.female_share==null?null:Number(r.female_share)),backgroundColor:'#b4a0d9',borderRadius:4}],{percent:true});
chart('nyc-scale',['Top 10 Brasil · '+N.year,'Nova York · '+N.year],[{label:'Conclusões',data:[Number(N.brazil_top10),Number(N.finishers)],backgroundColor:['#F7BC28','#b4a0d9'],borderRadius:5}]);
seriesChart('volume',['maratonas_concluintes']);seriesChart('sex',['maratonas_feminino','maratonas_masculino'],{percent:true,stacked:true});seriesChart('times',['maratonas_tempo_menor','maratonas_tempo_medio','maratonas_tempo_mediano'],{time:true});seriesChart('cuts',['maratonas_sub4_percentual','maratonas_sub3_percentual','maratonas_sub2h30_percentual'],{percent:true});seriesChart('groups',['maratonas_top5pct','maratonas_top10pct','maratonas_top50pct'],{time:true});seriesChart('medals',['maratonas_medalhas_ouro','maratonas_medalhas_prata','maratonas_medalhas_bronze']);
for(const [id,bl]of[['ages','idade'],['generations','geracao'],['origins','origem']]){const r=Y.profile.filter(r=>r.bloco===bl&&r.sexo==='geral'&&r.total>0).sort((a,b)=>a.ordem-b.ordem);chart(id,r.map(x=>id==='ages'&&x.categoria==='Idade indeterminada'?['Faixa','incompatível']:x.categoria),[{label:'Participações',data:r.map(x=>x.total),backgroundColor:'#b4a0d9',borderRadius:4}]);}
const gen=Y.profile.filter(r=>r.bloco==='geracao'&&r.sexo==='geral'&&r.total>0);chart('genSex',gen.map(r=>r.categoria),['F','M'].map((sex,i)=>({label:sex==='F'?'Mulheres':'Homens',backgroundColor:i?'#7fb7a6':'#b4a0d9',data:gen.map(r=>Number(Y.profile.find(x=>x.bloco==='geracao'&&x.sexo===sex&&x.categoria===r.categoria)?.percentual||0))})),{percent:true});
for(const [id,key]of[['uf','uf'],['months','data']]){let m={};rs.forEach(r=>{let k=key==='data'?r.data.slice(5,7):r.uf||'Não informada';m[k]=(m[k]||0)+r.total});let keys=Object.keys(m).sort(id==='uf'?(a,b)=>m[b]-m[a]:undefined);chart(id,keys,[{label:'Participações',data:keys.map(k=>m[k]),backgroundColor:'#F7BC28'}]);}
seriesChart('performance',['performance_42k_geral','performance_42k_F','performance_42k_M'],{percent:true});cnaChart();crossingCharts();
if(year===2026)chart('pairs',pairsToPlot.map(r=>short(r.nome_evento)),[2025,2026].map((y,i)=>({label:y+' · Jan–Set',data:pairsToPlot.map(r=>r['n'+y]),backgroundColor:i?'#F7BC28':'#b4a0d9'})));
else{const rows=annualPairs().slice(0,10);chart('pairs',rows.map(r=>short(r.nome_evento)),[2024,2025].map((y,i)=>({label:y+' · ano completo',data:rows.map(r=>r['n'+y]),backgroundColor:i?'#F7BC28':'#b4a0d9'})));}
document.getElementById('race').addEventListener('change',raceDetail);raceDetail();document.getElementById('year-heading').textContent='Você está lendo '+period(year)+'.';document.getElementById('hero-intro').textContent=year===2026?'A prévia de 2026 já está aqui: conclusões, perfil e desempenho até setembro. Veja todas as maratonas da seleção, os destaques das dez maiores e o que mudou nas mesmas provas em relação a 2025.':'A referência de 2025 reúne conclusões, perfil e desempenho do ano completo. Veja todas as maratonas da seleção, os destaques das dez maiores e a comparação com suas edições de 2024.';document.getElementById('year').value=String(year);document.getElementById('comparison-nav').textContent=year===2026?'2025 × 2026':'2024 × 2025';document.title='Maratonas do Brasil · '+period(year);document.querySelectorAll('[data-year]').forEach(el=>{const active=Number(el.dataset.year)===year;el.classList.toggle('active',active);el.setAttribute('aria-pressed',String(active));});document.querySelectorAll('[data-year-only]').forEach(el=>el.hidden=Number(el.dataset.yearOnly)!==year);}
function raceDetail(){let id=Number(document.getElementById('race').value),Y=D.years[year],r=topRaces(year).find(x=>x.id_evento===id);if(!r)return;const box=document.getElementById('race-detail');const known=r.feminino+r.masculino;
box.innerHTML=`<h3>${e(r.nome)}</h3><p>${e(r.cidade)} / ${e(r.uf)} · ${e(r.data)} · ID ${r.id_evento}</p><div class="grid">${card(n(r.total),'Conclusões')}${card(pc(r.feminino/r.total*100),'Mulheres',n(r.feminino)+' mulheres · '+n(r.masculino)+' homens · '+n(r.total-known)+' sem classificação F/M')}${card(time(r.mediana),'Tempo mediano')}</div><div class="grid smallmetrics">${card(time(r.minimo),'Menor tempo')}${card(time(r.media),'Tempo médio')}${card(pc(r.sub4/r.total*100),'Sub4h',n(r.sub4)+' conclusões')}</div>${table(['Sub2h30','Sub3h','Sub4h'],[[n(r.sub2h30)+' · '+pc(r.sub2h30/r.total*100),n(r.sub3)+' · '+pc(r.sub3/r.total*100),n(r.sub4)+' · '+pc(r.sub4/r.total*100)]])}<h3>Os menores tempos, em cinco grupos</h3><p class="note">Cada número é a média dos tempos do grupo nesta prova. Os grupos de 10 e 100 mostram a ponta; os percentuais permitem ler uma parcela proporcional do pelotão. ${year===2026?'Eles não representam variação em relação a 2025.':'Eles descrevem o desempenho desta edição de 2025, sem comparação com outro ano.'}</p>${table(['10 mais rápidos','100 mais rápidos','Melhores 5%','Melhores 10%','Melhores 50%'],[[time(r.top10),time(r.top100),time(r.top5pct),time(r.top10pct),time(r.top50pct)]])}${plot('race-bins','Distribuição dos tempos por sexo')}<p class="note">Fonte de desempenho: ${e(r.source)}. Histograma: congelamento ${year===2025?252:253}, intervalos com limite inferior inclusivo e superior exclusivo. ${r.bi_total?'Base do histograma BI: '+n(r.bi_total)+'; ficha oficial: '+n(r.total)+'.':''}</p>`;
const bins=Y.bins.filter(b=>b.id_evento===id);const labels=[...new Set(bins.map(b=>b.faixa))].sort();const old=charts.find(c=>c.canvas?.id==='race-bins');if(old)old.destroy();chart('race-bins',labels,['F','M','N/A'].map((sex,i)=>({label:sex==='N/A'?'Não informado':sex==='F'?'Mulheres':'Homens',backgroundColor:['#b4a0d9','#7fb7a6','#999'][i],data:labels.map(l=>bins.filter(b=>b.faixa===l&&b.sexo===sex).reduce((a,b)=>a+b.total,0))})),{stacked:true});}
function changeYear(next){year=next===2025?2025:2026;const url=new URL(window.location.href);url.searchParams.set('ano',String(year));window.history.replaceState(null,'',url);render();}
document.getElementById('year').addEventListener('change',ev=>changeYear(Number(ev.target.value)));document.querySelectorAll('[data-year]').forEach(button=>button.addEventListener('click',()=>changeYear(Number(button.dataset.year))));render();
})();
