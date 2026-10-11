/* Chart.js presentation only. Series, denominators and exports remain in dados.js. */
(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./dados.js'));
  else root.EstudoCharts=factory(root.EstudoData);
})(typeof window==='undefined'?globalThis:window,function(A){
  'use strict';
  const esc=A.escape,fmt=A.format,font='Poppins, Arial, sans-serif',headingFont='Libre Franklin, Arial, sans-serif';
  const colors={yellow:'#f5b21b',ink:'#333333',gray:'#666666',mid:'#999999',light:'#c6c6c6',paper:'#eeeeee',female:'#df4663',male:'#3c73cc',distance:['#4886c2','#43bd9a','#ffdf62','#f44346']};
  let pending=[],instances=[];
  const number=v=>typeof v==='number'&&Number.isFinite(v)?v:null;
  const caption=s=>s.caption||s.id.match(/20\d\d/)?.[0]||s.id;
  const sexLabel=s=>({F:'Feminino',M:'Masculino',X:'Outros / não informado','1':'1º trimestre','2':'2º trimestre','3':'3º trimestre','4':'4º trimestre'}[s]||s);
  function distanceColor(label){
    const km=Number.parseFloat(String(label).replace(',','.').replace(/^[^\d]+/,''));
    return !Number.isFinite(km)?colors.gray:km<6?colors.distance[0]:km<11?colors.distance[1]:km<30?colors.distance[2]:colors.distance[3];
  }
  function begin(){instances.forEach(chart=>chart.destroy());instances=[];pending=[];}
  function frame(spec,height,className=''){
    const id='plot-'+(pending.length+1);pending.push({id,spec});
    const description=spec.labels.map((label,i)=>label+': '+spec.datasets.map(d=>(d.label?d.label+' ':'')+fmt(d.data[i],spec.unit,spec.decimals)).join(', ')).join('; ');
    return '<div class="study-chart '+className+'" style="--plot-height:'+height+'px"><canvas id="'+id+'" role="img" aria-label="'+esc(description)+'">'+esc(description)+'</canvas></div>';
  }
  function legend(labels,palette,values,unit,decimals){
    return '<ul class="chart-legend">'+labels.map((label,i)=>'<li><i style="background:'+palette[i%palette.length]+'" aria-hidden="true"></i><span>'+esc(sexLabel(label))+'</span>'+(values?'<strong>'+esc(fmt(values[i],unit,decimals))+'</strong>':'')+'</li>').join('')+'</ul>';
  }
  function bars(series,palette,{compact=false,wide=false,maximum=null,horizontal=true}={}){
    const data=series.values.map(v=>number(v.value));
    const mapped=series.id==='distancias_detalhe'?series.values.map(v=>distanceColor(v.label)):series.values.map((v,i)=>palette[i%palette.length]);
    const rowHeight=wide?Math.max(...series.values.map(v=>String(v.label).length))>27?72:46:compact?42:46;
    return frame({kind:horizontal?'bars':'columns',maximum,labels:series.values.map(v=>sexLabel(v.label)),datasets:[{data,backgroundColor:mapped}],unit:series.unit,decimals:series.decimals,wide},horizontal?Math.max(300,data.length*rowHeight+50):380);
  }
  function donut(series,palette,center,captionText){
    const labels=series.values.map(v=>sexLabel(v.label)),values=series.values.map(v=>number(v.value));
    return '<div class="study-donut">'+frame({kind:'donut',labels,datasets:[{data:values,backgroundColor:palette}],unit:series.unit,decimals:series.decimals,center,caption:captionText},280,'study-ring')+legend(labels,palette,values,series.unit,series.decimals)+'</div>';
  }
  function grouped(sets,palette,{horizontal=false,unit='percentual',decimals=1}={}){
    const available=sets.filter(s=>s.available),labels=[...new Set(available.flatMap(s=>s.values.map(v=>v.label)))];
    const datasets=available.map((s,i)=>({label:caption(s),data:labels.map(l=>number(s.values.find(v=>v.label===l)?.value)),backgroundColor:palette[i%palette.length]}));
    return frame({kind:horizontal?'hgroups':'grouped',labels,datasets,unit,decimals},horizontal?Math.max(300,labels.length*84+50):380)+legend(datasets.map(d=>d.label),palette);
  }
  function matrix(sets,palette){
    const categories=[...new Set(sets.flatMap(s=>s.values.map(v=>v.label)))];
    const datasets=categories.map((c,i)=>({label:c,data:sets.map(s=>number(s.values.find(v=>v.label===c)?.value)),backgroundColor:palette[i%palette.length]}));
    return frame({kind:'grouped',labels:sets.map(caption),datasets,unit:'percentual',decimals:1},420)+legend(categories,palette);
  }
  function stacks(sets,palette,horizontal=false){
    const genders=[...new Set(sets.flatMap(s=>s.values.map(v=>v.label)))];
    const datasets=genders.map((gender,i)=>({label:sexLabel(gender),data:sets.map(s=>number(s.values.find(v=>v.label===gender)?.value)),backgroundColor:palette[i%palette.length]}));
    return frame({kind:horizontal?'hstack':'stacks',labels:sets.map(s=>s.caption||s.id.replace('sexo_dentro_distancia_','')),datasets,unit:'percentual',decimals:1,wide:horizontal},horizontal?sets.length*76+50:400)+legend(datasets.map(d=>d.label),palette);
  }
  function monthly(rows){
    return frame({kind:'monthly',labels:rows.map(r=>r.rotulo+(r.parcial?' *':'')),datasets:[2025,2026].map((year,i)=>({label:String(year),data:rows.map(r=>number(r['resultados_'+year])),backgroundColor:[colors.mid,colors.yellow][i]})),unit:'participacoes',decimals:0},rows.length*76+50)+legend(['2025','2026'],[colors.mid,colors.yellow]);
  }
  function configuration(spec,{dark=false,narrow=false}={}){
    const ink=dark?'#ffffff':colors.ink,grid=dark?'#ffffff15':'#33333312';
    const horizontal=['bars','monthly','hstack','hgroups'].includes(spec.kind),stacked=['stacks','hstack'].includes(spec.kind);
    const options={responsive:true,maintainAspectRatio:false,animation:false,locale:'pt-BR',color:ink,
      interaction:{mode:'nearest',intersect:true},
      plugins:{legend:{display:false},tooltip:{backgroundColor:'#222222',titleFont:{family:font,size:14},bodyFont:{family:font,size:14},padding:12,callbacks:{label:ctx=>(ctx.dataset.label?ctx.dataset.label+': ':'')+fmt(ctx.raw,spec.unit,spec.decimals)}}}};
    const datasets=spec.datasets.map(d=>({...d,data:d.data.map(number),borderWidth:0}));
    if(spec.kind==='donut'){
      options.cutout='54%';options.layout={padding:5};
      return {type:'doughnut',data:{labels:spec.labels,datasets},options};
    }
    datasets.forEach(d=>Object.assign(d,{borderRadius:2,borderSkipped:false,maxBarThickness:horizontal?27:70,categoryPercentage:stacked?.65:.8,barPercentage:.92}));
    options.indexAxis=horizontal?'y':'x';
    options.layout={padding:horizontal?{right:spec.unit==='participacoes'||spec.unit==='provas'?90:76,top:8,bottom:0}:{top:35,right:6}};
    const numericAxis={beginAtZero:true,stacked,grid:{color:grid,drawTicks:false},border:{display:false},ticks:{color:ink,font:{family:font,size:12},maxTicksLimit:horizontal?5:6,padding:8}};
    const categoryAxis={stacked,grid:{display:false},border:{display:false},ticks:{color:ink,font:ctx=>({family:font,size:(ctx.chart?ctx.chart.width<400:narrow)?12:14,weight:600}),padding:8,autoSkip:false,maxRotation:0,minRotation:0,callback:function(value){
      const compact=this.chart?this.chart.width<400:narrow;
      const text=this.getLabelForValue(value),limit=horizontal?(compact?14:spec.wide?25:22):compact?9:16;
      if(text.length<=limit)return text;
      const words=text.split(' '),lines=[''];
      words.forEach(word=>{const last=lines.length-1;if(lines[last]&&(lines[last]+' '+word).length>limit)lines.push(word);else lines[last]+=(lines[last]?' ':'')+word;});
      // Full event names stay in the tooltip, accessible description and values table.
      return lines.length>3?[...lines.slice(0,2),lines[2].slice(0,limit-1)+'…']:lines;
    }}};
    if(typeof spec.maximum==='number'&&Number.isFinite(spec.maximum))numericAxis.max=spec.maximum;
    if(stacked){numericAxis.max=Math.max(100,...spec.labels.map((_,i)=>datasets.reduce((n,d)=>n+(d.data[i]??0),0)));numericAxis.ticks.callback=v=>v+'%';}
    options.scales=horizontal?{x:numericAxis,y:categoryAxis}:{x:categoryAxis,y:numericAxis};
    return {type:'bar',data:{labels:spec.labels,datasets},options};
  }
  // Values stay visible without hover. Small segments retain their exact value in the legend/table.
  function annotations(spec,dark){return {id:'studyLabels',afterDatasetsDraw(chart){
    const ctx=chart.ctx,ink=dark?'#ffffff':colors.ink;ctx.save();
    if(spec.kind==='donut'){
      const arc=chart.getDatasetMeta(0).data[0];if(!arc){ctx.restore();return;}
      const limit=arc.innerRadius*1.75;
      let size=spec.center.length>5?20:30;ctx.font='800 '+size+'px '+headingFont;
      while(ctx.measureText(spec.center).width>limit&&size>10){size--;ctx.font='800 '+size+'px '+headingFont;}
      ctx.fillStyle=ink;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(spec.center,arc.x,arc.y-5);
      ctx.font='600 10px '+font;ctx.fillText(spec.caption,arc.x,arc.y+15);ctx.restore();return;
    }
    const horizontal=['bars','monthly','hstack','hgroups'].includes(spec.kind);
    chart.data.datasets.forEach((dataset,di)=>{
      if(!chart.isDatasetVisible(di))return;
      chart.getDatasetMeta(di).data.forEach((bar,i)=>{
        const value=dataset.data[i];if(value===null)return;
        ctx.font='700 '+(chart.width<400?12:14)+'px '+font;ctx.textBaseline='middle';ctx.fillStyle=ink;
        const text=fmt(value,spec.unit,spec.decimals);
        if(spec.kind==='hstack'){
          if(Math.abs(bar.base-bar.x)<ctx.measureText(text).width+8)return;
          ctx.textAlign='center';ctx.fillStyle=di<2?'#ffffff':ink;ctx.fillText(text,(bar.x+bar.base)/2,bar.y);
        }else if(spec.kind==='stacks'){
          if(Math.abs(bar.base-bar.y)<17||ctx.measureText(text).width>bar.width-4)return;
          ctx.textAlign='center';ctx.fillStyle=di<2?'#ffffff':ink;ctx.fillText(text,bar.x,(bar.y+bar.base)/2);
        }else if(horizontal){ctx.textAlign='left';ctx.fillText(text,bar.x+6,bar.y);}
        else{
          if(bar.width<ctx.measureText(text).width+3)return;
          ctx.textAlign='center';ctx.fillText(text,bar.x,bar.y-10);
        }
      });
    });ctx.restore();
  }};}
  function mount(){
    pending.forEach(({id,spec})=>{
      const canvas=document.getElementById(id);if(!canvas)return;
      const dark=!!canvas.closest('.section-dark'),config=configuration(spec,{dark,narrow:canvas.parentElement.clientWidth<400});
      config.plugins=[annotations(spec,dark)];
      try{
        if(typeof window.Chart!=='function')throw new Error('Chart.js indisponível');
        const chart=new window.Chart(canvas,config);instances.push(chart);canvas.dataset.chartRendered='true';
      }catch(error){
        canvas.parentElement.innerHTML='<p class="chart-fallback">Gráfico indisponível. Consulte os valores e a fonte na tabela abaixo.</p>';
        console.error('Não foi possível desenhar o gráfico',error);
      }
    });
  }
  function redraw(){instances.forEach(chart=>{chart.resize();chart.update('none');});}
  if(typeof window!=='undefined'){
    document.fonts?.ready.then(redraw);
    window.addEventListener('beforeprint',redraw);window.addEventListener('afterprint',redraw);
  }
  return {colors,distanceColor,begin,bars,donut,grouped,matrix,stacks,monthly,configuration,mount};
});
