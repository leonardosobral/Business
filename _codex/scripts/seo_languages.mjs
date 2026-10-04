// Offline evaluation: alternate targets outside this audit remain unknown.
function htmlUsable(o){
 return o.html_evaluation==='evaluated'&&!o.error&&!o.error_code&&!o.skip_reason&&o.status>=200&&o.status<300&&/^(text\/html|application\/xhtml\+xml)(?:\s*;|\s*$)/i.test(o.content_type||'');
}
export function comparableHttpUrl(value){
 if(typeof value!=='string')return null;
 try{const u=new URL(value);return ['https:','http:'].includes(u.protocol)&&!u.username&&!u.password?u.href.replace(/%[0-9a-f]{2}/gi,escape=>escape.toUpperCase()):null;}catch{return null;}
}
function alternates(o){
 if(o.metadata_version!==1||!Array.isArray(o.hreflang))return null;
 const map=new Map();
 for(const a of o.hreflang){
  if(!a||typeof a.lang!=='string'||!/^([a-z]{2,3}(?:-[a-z0-9]{2,8})*|x-default)$/i.test(a.lang))return false;
  const lang=a.lang.toLowerCase(),url=comparableHttpUrl(a.url);
  if(!url||map.has(lang))return false;
  map.set(lang,url);
 }
 return map;
}
function directCanonical(o){
 return !o.redirected&&o.canonical_count===1&&o.canonical_invalid===false&&comparableHttpUrl(o.canonical_url)===comparableHttpUrl(o.final_url);
}
function sameSet(a,b){return a.size===b.size&&[...a].every(([lang,url])=>b.get(lang)===url);}

/** One status per input row; no HTTP, language inference or translation claims. */
export function hreflangReciprocity(rows){
 const observed=new Map();
 for(const o of rows){
  const source=comparableHttpUrl(o.source_url);if(!source)continue;
  const matches=observed.get(source)||[];matches.push(o);observed.set(source,matches);
 }
 return rows.map(o=>{
  if(!htmlUsable(o))return 'unknown';
  const links=alternates(o);if(links===null)return 'unknown';if(links===false)return 'warning';if(!links.size)return 'unknown';
  const self=comparableHttpUrl(o.final_url);
  if(!self||![...links.values()].includes(self)||!directCanonical(o))return 'warning';
  const targets=[...new Set(links.values())].filter(url=>url!==self);
  if(!targets.length)return 'unknown';
  let missing=false;
  for(const url of targets){
   const matches=observed.get(url);
   if(!matches||matches.length!==1){missing=true;continue;}
   const target=matches[0];
   if(!htmlUsable(target)||!directCanonical(target)||comparableHttpUrl(target.final_url)!==url)return 'warning';
   const back=alternates(target);
   if(back===null){missing=true;continue;}
   if(back===false||!sameSet(links,back))return 'warning';
  }
  return missing?'unknown':'pass';
 });
}
