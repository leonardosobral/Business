import fs from 'node:fs/promises';
import {Workbook, SpreadsheetFile} from '@oai/artifact-tool';
const out = new URL('../', import.meta.url);
const members = JSON.parse(await fs.readFile(new URL('revisao_empresas.json',out),'utf8'));
const events = JSON.parse(await fs.readFile(new URL('revisao_eventos.json',out),'utf8'));
let result = null;
try { result=JSON.parse(await fs.readFile(new URL('release-commit.json',import.meta.url),'utf8')); } catch {}
const imported = new Map((result?.ACCOUNTS ?? result?.accounts ?? []).map(r=>[r.id_filiado,r]));
const wb = Workbook.create();
const date = x => new Date(x+'T12:00:00Z');
function table(name,title,headers,rows,widths,summary){
  const s=wb.worksheets.add(name); s.showGridLines=false; s.tabColor='#253C59';
  s.getRangeByIndexes(0,0,rows.length+7,headers.length).format.font={name:'Arial',size:10,color:'#243246'};
  s.getRange('A2').values=[[title]];s.getRange('A2').format.font={name:'Arial',size:15,bold:true};
  s.getRange('A3').values=[[summary]];
  const all=s.getRangeByIndexes(5,0,rows.length+1,headers.length);all.values=[headers,...rows];
  all.format.verticalAlignment='center';all.format.wrapText=true;
  for(let i=0;i<widths.length;i++)s.getRangeByIndexes(5,i,rows.length+1,1).format.columnWidth=widths[i];
  s.getRangeByIndexes(5,0,1,headers.length).format={fill:'#253C59',font:{name:'Arial',size:10,color:'#FFFFFF',bold:true},horizontalAlignment:'center',wrapText:true,rowHeight:32};
  s.getRangeByIndexes(6,0,rows.length,headers.length).format.rowHeight=88;
  s.tables.add('A6:'+String.fromCharCode(64+headers.length)+(rows.length+6),true,name.replace(/[^a-zA-Z]/g,'')+'Table');
  s.freezePanes.freezeRows(6);s.freezePanes.freezeColumns(1);
  return s;
}
const yes=members.filter(r=>r.status_organizacao==='CONFIRMADO');
const no=members.filter(r=>r.status_organizacao!=='CONFIRMADO');
const a=table('Pre-cadastros','ABRACEO — revisão dos 55 restantes',
 ['Empresa','ID Business','Importação','CNPJ titular','E-mail público','Contato público','Telefone público','CNPJ pesquisado','Situação pesquisada','Razão social pesquisada','Endereço pesquisado','Cidade / UF','Evidência de organização','Fonte de organização','Fonte ABRACEO','Logotipo','Conta Business'],
 yes.map(r=>{const c=imported.get(r.id_filiado);return [r.nome_abraceo,c?String(c.id_conta):'',c?'Criado':'Preparado; aguarda migração','Pendente',r.email_publico,r.contato_publico,r.telefone_publico,r.cnpj_pesquisado,r.situacao_cadastral_consultada,r.razao_social_pesquisada,r.endereco_cadastral,[r.cidade_abraceo,r.uf_abraceo].filter(Boolean).join(' / '),r.evidencia_organizacao,r.fonte_organizacao,r.fonte_abraceo,c?'https://business.roadrunners.run'+c.logo_path:r.logo_url,c?'https://business.roadrunners.run/administracao/contas/?conta_id='+c.id_conta+'&tab=precadastro':''];}),
 [32,12,28,17,35,28,28,22,20,42,45,28,70,78,60,78,78],
 'Revisão em 11/10/2026. Dados pesquisados do titular ainda dependem de confirmação.');
a.getRange('A4').values=[['Organizadores confirmados']];a.getRange('B4').formulas=[['=COUNTA(A7:A53)']];
a.getRange('D4').values=[['Criados no Business']];a.getRange('E4').formulas=[['=COUNTIFS(C7:C53,"Criado")']];
a.getRange('F4').values=[['Não importados']];a.getRange('G4').formulas=[['=COUNTIFS(C7:C53,"Preparado; aguarda migração")']];
a.getRange('H7:H53').setNumberFormat('@');
for(const r of ['B4','E4','G4']) {a.getRange(r).format.horizontalAlignment='center';a.getRange(r).format.font.bold=true;}
const b=table('Pendencias','Empresas separadas para confirmação',
 ['Empresa','Motivo / próxima confirmação','Contato público','E-mail público','CNPJ pesquisado','Situação pesquisada','Fonte consultada','Fonte ABRACEO'],
 no.map(r=>[r.nome_abraceo,r.evidencia_organizacao,r.contato_publico,r.email_publico,r.cnpj_pesquisado,r.situacao_cadastral_consultada,r.fonte_organizacao,r.fonte_abraceo]),
 [34,80,30,36,22,23,84,67],
 'Nenhuma conta criada neste lote para estas empresas. MP3 Soluções pode ter relação com a conta MP3 Marketing #5.');
b.getRange('A4').values=[['Empresas pendentes']];b.getRange('B4').formulas=[['=COUNTA(A7:A14)']];b.getRange('E7:E14').setNumberFormat('@');
const c=table('Eventos futuros','Eventos futuros revisados',
 ['Empresa','Evento','Data inicial','ID evento','Revisão','Vínculo no Business','Motivo','Fonte de confirmação','Evento Business'],
 events.map(e=>[e.nome_abraceo,e.nome_evento,date(e.data_inicial),e.id_evento,e.status_revisao,e.status_revisao==='CONFIRMADO'?(imported.has(e.id_filiado)?'Relacionado':'Preparado; aguarda importação'):'Não relacionado',e.motivo_revisao,e.fonte_confirmacao,e.url_business]),
 [30,46,16,12,19,30,78,92,78],
 'Corte: início após 11/10/2026. Datas e vínculos existentes conferidos no Business. Casos duvidosos permanecem sem associação.');
c.getRange('A4').values=[['Vínculos confirmados']];c.getRange('B4').formulas=[['=COUNTIFS(E7:E90,"CONFIRMADO")']];
c.getRange('D4').values=[['Pendentes']];c.getRange('E4').formulas=[['=COUNTIFS(E7:E90,"PENDENTE")']];c.getRange('C7:C90').setNumberFormat('dd/mm/yyyy');
c.getRange('E7:E90').conditionalFormats.add('containsText',{text:'PENDENTE',format:{fill:'#FFF2D0',font:{color:'#785000'}}});
c.getRange('C7:D90').format.horizontalAlignment='center';
wb.recalculate();
for(const s of [a,b,c]){
  console.log((await wb.inspect({kind:'table',range:s.name+'!A4:G4',include:'values,formulas',tableMaxRows:1,tableMaxCols:7,maxChars:1600})).ndjson);
  const preview=await wb.render({sheetName:s.name,range:s.name==='Pendencias'?'A1:D9':'A1:G9',scale:1,format:'png'});
  await fs.writeFile(new URL(s.name+'.png',import.meta.url),new Uint8Array(await preview.arrayBuffer()));
}
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!|#NULL!',options:{useRegex:true,maxResults:20},maxChars:1000})).ndjson);
await (await SpreadsheetFile.exportXlsx(wb)).save(new URL('abraceo_revisao_55.xlsx',out).pathname);
console.log(JSON.stringify({companies:yes.length,pending:no.length,events:events.length,imported:imported.size}));
