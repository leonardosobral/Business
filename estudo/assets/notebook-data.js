(function(root){
'use strict';
function parse(raw){
 // Quote numeric tokens outside JSON strings before parsing, retaining decimal and bigint precision.
 let out='',i=0;
 while(i<raw.length){
  const c=raw[i];
  if(c==='"'){const start=i++;while(i<raw.length){if(raw[i]==='\\'){i+=2;continue;}if(raw[i++]==='"')break;}out+=raw.slice(start,i);continue;}
  if(c==='-'||(c>='0'&&c<='9')){const token=raw.slice(i).match(/^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/);if(!token)throw new Error('Resultado JSON inválido.');out+=JSON.stringify(token[0]);i+=token[0].length;continue;}
  out+=c;i++;
 }
 return JSON.parse(out);
}
function csv(raw){
 const result=parse(raw),field=v=>{
  if(v===null||v===undefined)return '';
  let text=typeof v==='object'?JSON.stringify(v):String(v);
  // Text formulas must not execute when the CSV is opened in a spreadsheet.
  if(/^[=+@\t\r]/.test(text)||(/^-/.test(text)&&!/^-[0-9]/.test(text)))text="'"+text;
  return '"'+text.replace(/"/g,'""')+'"';
 };
 return [result.columns.map(field).join(','),...result.rows.map(row=>result.columns.map(name=>field(row[Object.keys(row).find(k=>k.toLowerCase()===name.toLowerCase())])).join(','))].join('\r\n');
}
const api={parse,csv};if(typeof module==='object'&&module.exports)module.exports=api;else root.StudyData=api;
})(typeof globalThis==='object'?globalThis:this);
