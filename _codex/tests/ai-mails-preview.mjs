// Local-only UI fixture. Never loads credentials, mail, or production endpoints.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
let items=[{id:1,version:1,thread_id:'fixture1',subject:'Fornecedor solicita confirmação dos kits',sender:'Produção <fornecedor@example.com>',last_message_at:'2026-09-17T13:12:00Z',priority:'high',category:'operacao',state:'pending',summary:'A produção dos kits depende da confirmação da quantidade final. O fornecedor solicita retorno para liberar o material.',reason:'A liberação da produção depende de uma decisão da equipe.',actions:[{text:'Confirmar a quantidade final e responder ao fornecedor.',source_message_id:'msg1'}],needs_response:true,needs_review:false,source_available:true,in_inbox:true,relevant:true,deadline_at:'2026-09-18T15:00:00Z',deadline_text:'até 18/09 às 12h',source_message_id:'msg1',rfc_message_id:'<fixture@example.com>',assignee_id:null,assignee_name:'',note:'',warnings:['Há anexos não analisados. Confira os arquivos no Gmail.'],sources:[],analyzed_at:'2026-09-17T13:15:00Z',analysis_model:'gpt-4.1-mini'}, {id:2,version:1,thread_id:'fixture2',subject:'Informativo semanal — novidades da comunidade',sender:'Boletim <boletim@example.com>',last_message_at:'2026-09-17T10:00:00Z',priority:'low',category:'outros',state:'pending',summary:'Boletim informativo sem solicitações para a equipe.',reason:'Não contém ação necessária.',actions:[],needs_response:false,needs_review:false,source_available:true,in_inbox:true,relevant:false,assignee_name:'',warnings:[],sources:[]}];
const server=http.createServer(async(req,res)=>{
  const url=new URL(req.url,'http://localhost');
  if(url.pathname.endsWith('/api.cfm')) {
    let body='';for await(const c of req) body+=c;const p=Object.fromEntries(new URLSearchParams(body));let result={success:true};
    if(p.action==='status') Object.assign(result,{connected:true,ai_configured:true,config:{enabled:true,email:'contato@runnerhub.run',model:'gpt-4.1-mini',initial_days:30,daily_limit:100,retention_days:90,initial_complete:true,collected:2,last_sync_at:'2026-09-17T13:15:00Z',last_error:''},metrics:{pending:items.filter(x=>x.state!=='resolved'&&x.relevant).length,urgent:items.filter(x=>x.state!=='resolved'&&x.priority==='high').length,response:items.filter(x=>x.state!=='resolved'&&x.needs_response).length,overdue:0},queue:{total:0,errors:0},usage:{total:2,input_tokens:1700,output_tokens:600,limited:false},actors:[{id:1,name:'Atendente de teste'}],jobs:[{active:true},{active:true}]});
    else if(p.action==='list') {let rows=items.filter(i=>p.view==='review'?(!i.relevant||i.needs_review):p.view==='resolved'?i.state==='resolved':p.view==='in_progress'?i.state==='in_progress':i.state!=='resolved'&&i.relevant);if(p.search) rows=rows.filter(i=>(i.subject+' '+i.sender+' '+i.summary).toLowerCase().includes(p.search.toLowerCase()));if(p.priority)rows=rows.filter(i=>i.priority===p.priority);if(p.category)rows=rows.filter(i=>i.category===p.category);Object.assign(result,{items:rows,total:rows.length});}
    else if(p.action==='detail') Object.assign(result,{item:items.find(i=>i.id===Number(p.id)),history:[{action:'analyzed',actor_name:'',created_at:'2026-09-17T13:15:00Z'}]});
    else if(['resolve','reopen','note','assign','classify','reanalyze'].includes(p.action)){const i=items.find(i=>i.id===Number(p.id));if(i.version!==Number(p.version)){res.statusCode=409;result={success:false,message:'Conflito de versão de teste.'};}else{if(p.action==='resolve')i.state='resolved';if(p.action==='reopen')i.state='pending';if(p.action==='note')i.note=p.note;if(p.action==='assign'){i.state='in_progress';i.assignee_name='Atendente de teste';i.assignee_id=1;}if(p.action==='classify'){i.priority=p.priority;i.relevant=p.priority!=='low';}i.version++;result.message='Conversa atualizada (dados fictícios).';}}
    else result.message='Solicitação registrada (fixture).';
    res.setHeader('Content-Type','application/json');res.end(JSON.stringify(result));return;
  }
  if(url.pathname==='/') {
    let html=fs.readFileSync(path.join(root,'administracao/ai-mails/index.cfm'),'utf8');
    html=html.slice(html.indexOf('<!doctype html>'));
    const nav='<nav class="admin-suite-nav" aria-label="Ferramentas administrativas">'+['Kanban','Agenda','Documentos','AI-mails'].map(n=>`<a class="admin-suite-nav-link ${n==='AI-mails'?'is-active':''}" href="#"><span class="admin-suite-nav-copy"><strong>${n}</strong><small>${n==='AI-mails'?'Atenção':'Ferramenta'}</small></span></a>`).join('')+'</nav>';
    html=html.replace(/<cfinclude template="..\/..\/includes\/estrutura\/admin_suite_nav.cfm"\/>/,nav).replace(/<cfif structKeyExists\(session,"aiMailMessage"\)>[\s\S]*?<\/cfif>/,'').replace(/<cfoutput>[\s\S]*?<\/cfoutput>/g,'fixture').replace(/<cfinclude[^>]+>/g,'');
    html=html.replace('<html lang="pt-br">','<html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AI-mails · teste local</title><link rel="stylesheet" href="/assets/css/mdb.min.css"><style>body{padding:20px;background:#18191c}.admin-suite-main{margin-top:0}</style></head>');
    res.setHeader('Content-Type','text/html;charset=utf-8');res.end(html);return;
  }
  const relative=decodeURIComponent(url.pathname).replace(/^\//,'');const file=path.resolve(root,relative);
  if(!file.startsWith(root+path.sep)||!['.css','.js','.woff','.woff2'].includes(path.extname(file))||!fs.existsSync(file)){res.statusCode=404;res.end('Not found');return;}
  res.setHeader('Content-Type',file.endsWith('.css')?'text/css':file.endsWith('.js')?'text/javascript':'application/octet-stream');fs.createReadStream(file).pipe(res);
});
server.listen(8917,'127.0.0.1',()=>console.log('AI-mails UI fixture: http://127.0.0.1:8917'));
