// Complementary measurements have their own dates and scopes; technical scoring is untouched.
const HOSTS={roadrunners:'roadrunners.run',openresults:'openresults.run'};
const STATES={pass:['Verificado','✓'],warning:['Atenção','!'],error:['Erro','×'],unknown:['Não medido','—']};
const PROVIDERS=new Set(['ChatGPT','Perplexity','Claude','Copilot','Gemini']);
const integer=(n)=>Number.isSafeInteger(n)&&n>=0;
function requireValue(ok,message){if(!ok)throw new Error('Evidência de IA inválida: '+message);}
function timestamp(value){
 requireValue(typeof value==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(value),'data');
 const ms=Date.parse(value),day=Date.parse(value.slice(0,10));
 requireValue(Number.isFinite(ms)&&new Date(day).toISOString().slice(0,10)===value.slice(0,10)&&ms<=Date.now()+300000,'data');return ms;
}
const date=(value)=>new Intl.DateTimeFormat('pt-BR',{timeZone:'America/Sao_Paulo',dateStyle:'short',timeStyle:'short'}).format(new Date(value))+' (Brasília)';
function publicUrl(value){
 try{const u=new URL(value);return u.protocol==='https:'&&u.hostname==='roadrunners.run'&&!u.username&&!u.password&&!u.port&&!u.search&&!u.hash&&!/[\s\\\u0000-\u001f\u007f]/u.test(value)&&!/%(?:0[0-9a-f]|1[0-9a-f]|7f|5c)/i.test(value);}catch{return false;}
}
function observation(o,url){
 requireValue(o&&o.url===url&&publicUrl(o.url)&&publicUrl(o.final_url),'URL de descrição');
 requireValue(integer(o.status)&&o.status<=599&&integer(o.description_regions)&&integer(o.description_chars),'metadados de descrição');
 requireValue(o.description_lang===null||['pt-BR','en','es'].includes(o.description_lang),'idioma de descrição');
 requireValue(typeof o.description_lang_conflict==='boolean','conferência de idioma aninhado');
 requireValue(o.description_chars===0?o.description_hash===null:typeof o.description_hash==='string'&&/^[a-f0-9]{64}$/.test(o.description_hash),'hash de descrição');
}
function translationStatus(original,target,lang){
 if([original,target].some(o=>o.status<200||o.status>=300||o.final_url!==o.url))return 'error';
 if([original,target].some(o=>o.description_regions!==1||o.description_lang_conflict||!o.description_chars||!o.description_hash)||original.description_lang!=='pt-BR')return 'unknown';
 return target.description_lang!==lang||target.description_hash===original.description_hash?'warning':'pass';
}
function check(id,label,note,status='unknown',counts={pass:0,warning:0,error:0,unknown:0},cases=[]){return {id,label,note,status,statusLabel:STATES[status][0],icon:STATES[status][1],...counts,total:Object.values(counts).reduce((n,v)=>n+v,0),partial:counts.unknown>0&&counts.pass+counts.warning+counts.error>0,cases};}
export function withAiEvidence(base,site,evidence){
 if(!evidence)return base;
 requireValue(HOSTS[site]&&evidence.schemaVersion===1,'site ou versão');
 const replacements=new Map();
 if(evidence.descriptions){
  const data=evidence.descriptions;timestamp(data.measured_at);
  requireValue(Array.isArray(data.events)&&data.events.length>0&&data.events.length<=50,'amostra de descrições');
  const tags=new Set(),counts={pass:0,warning:0,error:0,unknown:0},cases={error:[],warning:[],unknown:[]};let past=0,future=0;
  for(const event of data.events){
   requireValue(event&&typeof event.tag==='string'&&/^[a-zA-Z0-9-]{1,180}$/.test(event.tag)&&!tags.has(event.tag)&&['past','future'].includes(event.cohort),'evento duplicado ou inválido');tags.add(event.tag);event.cohort==='past'?past++:future++;
   for(const [lang,prefix]of [['pt-BR','evento'],['en','en/event'],['es','es/evento']])observation(event.pages?.[lang],`https://roadrunners.run/${prefix}/${event.tag}/`);
   for(const lang of ['en','es']){const status=translationStatus(event.pages['pt-BR'],event.pages[lang],lang);counts[status]++;if(status!=='pass')cases[status].push(event.pages[lang].url);}
  }
  if(site==='roadrunners'){
   const status=counts.error?'error':counts.warning?'warning':counts.unknown?'unknown':'pass';
   replacements.set('translations',check('translations','Tradução do conteúdo principal',`Conferência complementar em ${date(data.measured_at)}: ${data.events.length} eventos selecionados (${past} históricos e ${future} futuros), ${data.events.length} páginas PT de referência e ${data.events.length*2} versões EN/ES. Verifica a região visível da descrição, a anotação de idioma e se o texto difere da fonte; fallback para português pede atenção. Ausência de descrição marcada na fonte ou no destino fica não medida. Não mede todas as páginas, detecção automática do idioma nem fidelidade da tradução.`,status,counts,[...cases.error,...cases.warning,...cases.unknown].slice(0,3)));
  }
 }
 if(evidence.audience){
  const data=evidence.audience;timestamp(data.measured_at);const start=timestamp(data.start_at),end=timestamp(data.end_at);
  requireValue(Math.abs(end-start-7*86400000)<1000&&end<=timestamp(data.measured_at),'janela de audiência');
  requireValue(Array.isArray(data.sites)&&Array.isArray(data.providers),'agregados de audiência');const hosts=new Set(),identities=new Set();
  for(const row of data.sites){requireValue(row&&Object.values(HOSTS).includes(row.site_host)&&!hosts.has(row.site_host),'host de audiência');hosts.add(row.site_host);
   requireValue(['pageviews','sessions','ai_pageviews','ai_sessions'].every(k=>integer(row[k]))&&row.ai_pageviews<=row.pageviews&&row.ai_sessions<=row.sessions&&row.sessions<=row.pageviews&&row.ai_sessions<=row.ai_pageviews,'contagens de audiência');}
  for(const row of data.providers){const identity=row.site_host+'/'+row.provider,owner=data.sites.find(s=>s.site_host===row.site_host);
   requireValue(owner&&PROVIDERS.has(row.provider)&&!identities.has(identity)&&integer(row.pageviews)&&integer(row.sessions)&&row.sessions<=row.pageviews&&row.pageviews<=owner.ai_pageviews&&row.sessions<=owner.ai_sessions,'provedor de audiência');identities.add(identity);}
  const row=data.sites.find(s=>s.site_host===HOSTS[site]),window=`Fonte própria, produção e sem tráfego interno, de ${date(data.start_at)} a ${date(data.end_at)}; consulta em ${date(data.measured_at)}.`;
  if(row&&row.pageviews>0){
   const providers=data.providers.filter(p=>p.site_host===row.site_host).map(p=>`${p.provider}: ${p.pageviews} visualizações e ${p.sessions} sessões`).join('; ');
   replacements.set('referrals',check('referrals','Origem de visitas por referências de IA',`${window} ${row.ai_pageviews} visualizações distintas em ${row.ai_sessions} sessões distintas com referrer_host da lista exata de assistentes, entre ${row.pageviews} visualizações e ${row.sessions} sessões medidas. ${providers||'Nenhuma referência de assistente observada nessa cobertura.'} A referência é declarada pelo navegador; não comprova citação, recomendação ou conversão. Sessões podem aparecer em mais de um provedor; o total é deduplicado.`, 'pass'));
  }else replacements.set('referrals',check('referrals','Origem de visitas por referências de IA',`${window} A fonte consultada não contém cobertura de visualizações deste site no período. Ausência de dados não significa zero visitas; é necessário conferir sua instrumentação.`));
 }
 if(evidence.access){
  const data=evidence.access;timestamp(data.measured_at);
  requireValue(data.site_attribution===false&&integer(data.files_scanned)&&data.files_scanned>0&&data.vhosts?.[HOSTS[site]]?.shared_combined_log===true,'logs compartilhados');
  replacements.set('provider-access',check('provider-access','Acesso real pelos provedores',`Logs existentes conferidos em ${date(data.measured_at)} (${data.files_scanned} arquivos, sem exportar IPs ou caminhos pessoais). Road Runners e Open Results escrevem em log compartilhado sem hostname; os registros não permitem atribuir visitas a cada site. As faixas oficiais atuais foram consultadas, mas user-agent ou IP compatível nesse log não comprovam acesso a este domínio. A normalização de IP também difere entre os vhosts. Bloqueios anteriores à origem, na CDN/WAF, não aparecem nesses logs.`));
 }
 return [...base.map(c=>replacements.get(c.id)||c),
  check('translation-quality','Fidelidade das traduções','Conferir fatos, números, nomes e adequação do idioma contra as fontes. Texto diferente e anotação de idioma não comprovam uma tradução fiel.'),
  check('conversions','Conversões vindas de IA','As referências de audiência medem visitas. Atribuição de inscrições ou outras conversões a assistentes ainda não foi medida nesta avaliação.')];
}
