import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const support=new URL('./',import.meta.url),out=new URL('../',support),old=new URL('../../abraceo-convites-completos-20261011/',support);
const read=async name=>JSON.parse(await fs.readFile(new URL(name,support),'utf8'));
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',old).pathname));
const s=wb.worksheets.getItem('Vouchers'),pending=wb.worksheets.getItem('Pendências');
const before=s.getRange('A7:L94').values,oldPending=pending.getRange('A7:F8').values;
const verified=await read('verify.json'),contacts=await read('contacts.json'),base=await read('../empresas_96.json');
const byId=new Map(contacts.map(r=>[String(r.id_conta),r]));
const rows=verified.codes.map(v=>({...v,...byId.get(String(v.id_conta))}));
if(rows.length!==7 || verified.verified!==7 || base.length!==96)throw Error('Lote inconsistente');
if(process.argv[2]==='edit'){
 const allCodes=[...before.map(r=>r[2]),...rows.map(r=>r.voucher)];
 if(new Set(allCodes).size!==95 || allCodes.some(v=>!/^BQ26-[A-F0-9]{32}$/.test(v)))throw Error('Voucher inválido ou duplicado');
 const values=rows.map(r=>[r.empresa,r.email,r.voucher,'https://business.roadrunners.run/estudos/primeiro-acesso/',new Date('2026-11-10T00:00:00Z'),'Pendente',r.contato,'Não enviado',null,String(r.voucher_id),r.fonte,r.motivo]);
 s.tables.items.find(t=>t.name==='VouchersABRACEO').rows.add(null,values);
 for(let i=95;i<=101;i++)s.getRange(`A${i}:L${i}`).copyFrom(s.getRange('A94:L94'),'all');
 s.getRange('A95:L101').values=values;
 s.getRange('A2').values=[['Vouchers ABRACEO — 95 convites']];
 s.getRange('A4').values=[['88 convites anteriores preservados e 7 novos. E-mails publicados; entrega não testada. MP3 separada na aba Pendências.']];
 s.getRange('A95:L101').format.rowHeight=62;s.getRange('L95:L101').format.wrapText=true;s.getRange('F95:F101').setNumberFormat('@');
 s.getRange('H95:H101').dataValidation={rule:{type:'list',values:['Não enviado','Enviado','Revisar']}};
 pending.getRange('A2').values=[['Pendências e resoluções — revisão de 11/10/2026']];
 pending.getRange('A4').values=[['1 filiado sem convite e 3 vínculos de eventos aguardam confirmação. Abaixo, também o histórico de 2 contatos resolvidos.']];
 pending.getRange('A6:F6').values=[['Empresa / evento','E-mail publicado','Decisão e próxima ação','Fonte','CNPJ / situação','Resultado']];
 const unresolved=[
 ['MP3 SOLUÇÕES','douglas@mp3promocoes.com.br','Conta 5 tem o mesmo contato, mas usa CNPJ 28434613000156; filiado pesquisado: 11194903000177. Confirmar com Douglas qual PJ/conta representa o filiado. Sem duplicar nem fundir.','https://abraceo.com.br/filiado/mp3-solucoes/','Duas PJs — confirmar','Sem novo cadastro ou voucher'],
 ['MMB — Maratona Monumental 2026','elias.sousa@gmail.com','Conta 113 e voucher preparados. Prova de 21–22/11 não vinculada: Ticket Sports indica MMB; regulamento atribui organização ao Instituto Meninos do Pôr do Sol e realização à MMB.','https://www.ticketsports.com.br/e/maratona-monumental-de-brasilia-2026-74828','Pendente','Vínculo do evento pendente'],
 ['Soul+ — Assaí Teresina 2026','fabio@soulmaisesportes.com.br','Conta 116 e voucher preparados. Prova de 22/11 não vinculada: regulamento confirma realização Soul+, enquanto o catálogo indica Instituto Novos Talentos como organizador. Confirmar papel operacional.','https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88118/bcbeec1049b84b6da8588720d963c4e3639263470646879556.pdf','Pendente','Vínculo do evento pendente'],
 ['Soul+ — Assaí Vitória 2026','fabio@soulmaisesportes.com.br','Prova de 08/11 não vinculada pela mesma divergência entre realização e organização. Confirmar papel da Soul+ nesta edição.','https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88119/04eaf22feeda40e292e43b1ac881ea89639263469096967453.pdf','Pendente','Vínculo do evento pendente']];
 for(let i=9;i<=12;i++)pending.getRange(`A${i}:F${i}`).copyFrom(pending.getRange('A8:F8'),'all');
 pending.getRange('A9:F12').values=unresolved;
 pending.getRange('A9:F12').format.rowHeight=124;pending.getRange('A9:F12').format.wrapText=true;pending.getRange('F9:F12').format.fill='#FFF0CC';pending.getRange('E9:E12').setNumberFormat('@');
 const e=wb.worksheets.add('Empresas');e.showGridLines=false;e.getRange('A1:O102').format.font={name:'Arial',size:11,color:'#183B40'};
 e.getRange('A2:F2').merge();e.getRange('A2').values=[['Base ABRACEO — 96 filiados revisados']];e.getRange('A2').format.font={name:'Arial',size:18,bold:true,color:'#183B40'};
 e.getRange('A3:F3').merge();e.getRange('A3').values=[['95 contas com vouchers • 1 filiado separado • revisão em 11/10/2026']];
 e.getRange('A4:F4').merge();e.getRange('A4').values=[['CNPJ pesquisado e endereço de referência não comprovam o titular atual. Novos cadastros aguardam CNPJ e representante; convites liberam apenas a prévia.']];e.getRange('A4').format.font={name:'Arial',size:11,color:'#626B70'};
 e.getRange('A2:F2').format.rowHeight=28;e.getRange('A3:F3').format.rowHeight=22;e.getRange('A4:F4').format.wrapText=true;e.getRange('A4:F4').format.rowHeight=38;
 const headers=['Empresa','ID Business','Situação do cadastro','CNPJ titular','CNPJ pesquisado — referência','E-mail do convite','Contato publicado','Telefone publicado','Cidade / UF','Endereço pesquisado — referência','Logo publicado','Fonte do contato','Atuação revisada','Fonte da organização','Decisão / pendências'];
 e.getRange('A6:O6').values=[headers];
 e.getRange('A7:O102').values=base.map(r=>[r.nome_abraceo,r.id_conta_business||null,r.status_pre_cadastro,r.cnpj_titular_business||(r.id_conta_business?'Pendente':'Não definido'),r.cnpj_pesquisado||'',r.email_convite||r.email_publico,r.contato_publico,r.telefone_publico,[r.cidade_abraceo,r.uf_abraceo].filter(Boolean).join(' / '),[r.endereco_cadastral,r.bairro_cadastral,r.cep_cadastral].filter(Boolean).join(' — '),r.logo_business||r.logo_url,r.fonte_abraceo,r.status_organizacao||'Confirmado no lote inicial',r.fonte_organizacao||r.fonte_atuacao||r.fonte_abraceo,[r.evidencia_organizacao||r.evidencia_vinculo,r.pendencias].filter(Boolean).join(' | ')]);
 e.getRange('A7:O102').format.rowHeight=94;e.getRange('A6:O102').format.wrapText=true;e.getRange('A6:O102').format.verticalAlignment='top';
 for(const [col,width] of Object.entries({A:230,B:90,C:225,D:150,E:180,F:260,G:220,H:230,I:170,J:340,K:380,L:350,M:190,N:380,O:660}))e.getRange(`${col}:${col}`).format.columnWidthPx=width;
 e.getRange('D7:E102').setNumberFormat('00000000000000');e.getRange('B7:B102').setNumberFormat('0');
 e.tables.add('A6:O102',true,'EmpresasABRACEO');e.getRange('A6:O6').format={fill:'#183B40',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},rowHeight:44,wrapText:true};
 e.freezePanes.freezeRows(6);e.freezePanes.freezeColumns(1);
 const mp3row=base.findIndex(r=>r.id_filiado==='mp3-solucoes')+7;e.getRange(`A${mp3row}:E${mp3row}`).format.fill='#FFF0CC';e.getRange(`D${mp3row}`).setNumberFormat('@');
 if(JSON.stringify(before)!==JSON.stringify(s.getRange('A7:L94').values)||JSON.stringify(oldPending)!==JSON.stringify(pending.getRange('A7:F8').values))throw Error('Linhas anteriores alteradas');
 wb.recalculate();
 console.log((await wb.inspect({kind:'table',range:'Empresas!A7:C10',include:'values',tableMaxRows:4,tableMaxCols:3,maxChars:1600})).ndjson);
 console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:30},maxChars:600})).ndjson);
 for(const [sheet,range,file] of [['Empresas','A1:F10','preview-companies.png']]){
  const blob=await wb.render({sheetName:sheet,range,scale:1,format:'png'});await fs.writeFile(new URL(file,support),new Uint8Array(await blob.arrayBuffer()),{mode:0o600});
 }
 const target=new URL('vouchers_abraceo.xlsx',out).pathname;await (await SpreadsheetFile.exportXlsx(wb)).save(target);await fs.chmod(target,0o600);
 console.log(JSON.stringify({vouchers:95,new_vouchers:7,companies:96,pending_company:1,old_rows_preserved:true}));
}
if(process.argv[2]==='verify-saved'){
 const previous=new Map(verified.previous_vouchers.map(r=>[String(r.id),r]));const newer=new Map(verified.codes.map(r=>[String(r.voucher_id),r]));
 const saved=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',out).pathname));const rows=saved.worksheets.getItem('Vouchers').getRange('A7:L101').values;
 if(new Set(rows.map(r=>r[1])).size!==95)throw Error('E-mails duplicados');
 for(const r of rows){const old=previous.get(String(r[9])),n=newer.get(String(r[9]));if(old){if(createHash('sha256').update(r[2]).digest('hex')!==old.hash || r[1]!==old.email)throw Error('Convite anterior divergente');}else if(!n || n.voucher!==r[2] || n.email!==r[1])throw Error('Novo convite divergente');}
 if(JSON.stringify(saved.worksheets.getItem('Vouchers').getRange('A7:L94').values)!==JSON.stringify(before))throw Error('Export alterou convites antigos');
 const master=saved.worksheets.getItem('Empresas').getRange('A7:O102').values;
 const emailByAccount=new Map([...verified.previous_vouchers.map(v=>[String(v.company),v.email]),...verified.codes.map(v=>[String(v.id_conta),v.email])]);
 for(const r of master){if(r[1]!==null && emailByAccount.get(String(r[1]))!==r[5])throw Error('E-mail do convite divergente na base');}
 if(master.length!==96 || master.filter(r=>r[1]!==null).length!==95)throw Error('Base incompleta');
 const result={saved_rows:95,matched_live_vouchers:95,old_rows_preserved:88,companies:96,pending_company:1,sheets:saved.worksheets.items.length};await fs.writeFile(new URL('workbook-verified.json',support),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}
