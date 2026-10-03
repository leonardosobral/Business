// Browser fixture: real modal template/CSS/JS; only CF labels and API transport
// are substituted. Bind loopback and serve only this small allowlist.
const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const root=process.env.RR_MEMBERS_RUNTIME||path.resolve(__dirname,'../../../RoadRunners');
const pager=path.resolve(__dirname,'../../../RoadRunners/assets/js/runnerhub-chat-members-pager.js');
const labels={loading:'Carregando membros…',more:'Carregar mais',retry:'Tentar novamente',loaded:'{count} membro(s) carregado(s)',other:'e outros {count} membros',empty:'Nenhum membro para exibir.',privateEmpty:'Você ainda não segue nenhum membro deste canal.',privacy:'Por privacidade, são exibidos apenas os membros do canal que você segue.',close:'Fechar',invalidPage:'Não foi possível continuar a lista.',error:'Não foi possível carregar os membros.'};
function fixture(channel){
  const source=fs.readFileSync(path.join(root,'mensagens/_group_thread.cfm'),'utf8');
  const start=source.indexOf('<div class="rr-group-modal" data-group-modal="members"');
  let markup=source.slice(start,source.indexOf('\n    </cfif>',start));
  markup=markup.replace(/<cfif VARIABLES.currentIsChannel>([\s\S]*?)<\/cfif>/g,(_,body)=>channel?body:'');
  markup=markup.replace(/<cfoutput>([\s\S]*?)<\/cfoutput>/g,(_,expression)=>{
    if(expression.includes("? 'channel' : 'chat'"))return channel?'channel':'chat';
    if(expression.includes('? VARIABLES.memberPagingLabels.privateEmpty'))return channel?labels.privateEmpty:labels.empty;
    if(expression.includes("REQUEST.i18nBuildPath('athlete')"))return '/atleta/{tag}/';
    const paging=expression.match(/VARIABLES\.memberPagingLabels\.(\w+)/);if(paging)return labels[paging[1]];
    const group=expression.match(/VARIABLES\.groupLabels\.(\w+)/);if(group)return group[1]==='members'?'Membros':group[1];
    throw new Error('Unrecognized CF output in fixture: '+expression);
  });
  return '<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Teste de rolagem — membros</title><link rel="stylesheet" href="/assets/css/runnerhub-chat.css"><style>body{font-family:Arial;margin:24px;background:#eef0f2}h2{font-size:18px}.rr-chat-avatar{display:block}button{cursor:pointer}</style><main data-chat-shell><div data-chat-thread data-group-id="42"></div><h1>Fixture: '+(channel?'Canal':'Grupo')+'</h1><button data-group-modal-open="members">Membros</button>'+markup+'</main><script src="/assets/js/runnerhub-chat-members-pager.js"></script><script src="/assets/js/runnerhub-chat-groups.js"></script></html>';
}
http.createServer((request,response)=>{
  const url=new URL(request.url,'http://127.0.0.1');
  response.setHeader('Cache-Control','no-store');
  if(url.pathname==='/'){response.setHeader('Content-Type','text/html; charset=utf-8');response.end(fixture(url.searchParams.get('mode')!=='group'));return;}
  if(url.pathname==='/api/chat/groups/members.cfm'){
    const from=Number((url.searchParams.get('cursor')||'0').replace('next_','')),count=45;
    const items=Array.from({length:Math.min(30,count-from)},(_,i)=>({id_usuario:from+i+1,nome:'Atleta de teste '+String(from+i+1).padStart(2,'0'),tag:'fixture'+(from+i+1),status:'active',papel:'member',is_admin:false,verificado:false}));
    const more=from+items.length<count;
    response.setHeader('Content-Type','application/json');response.end(JSON.stringify({success:true,can_manage:false,viewer_role:'member',items,has_more:more,next_cursor:more?'next_'+(from+items.length):'',other_members:55}));return;
  }
  const assets={'/assets/css/runnerhub-chat.css':'text/css','/assets/js/runnerhub-chat-groups.js':'text/javascript','/assets/js/runnerhub-chat-members-pager.js':'text/javascript'};
  if(assets[url.pathname]){response.setHeader('Content-Type',assets[url.pathname]);response.end(fs.readFileSync(url.pathname.endsWith('members-pager.js')?pager:path.join(root,url.pathname)));return;}
  response.statusCode=404;response.end();
}).listen(33437,'127.0.0.1',()=>process.stdout.write('Members fixture http://127.0.0.1:33437\n'));
