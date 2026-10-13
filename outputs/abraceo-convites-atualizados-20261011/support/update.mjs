import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const support=new URL('./',import.meta.url),out=new URL('../',support),old=new URL('../../abraceo-vouchers-20261011/',support);
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',old).pathname));
const s=wb.worksheets.getItem('Vouchers'),pending=wb.worksheets.getItem('Pendências');
if(process.argv[2]==='inspect'){
 console.log((await wb.inspect({kind:'workbook,sheet,table',maxChars:1800,tableMaxRows:0,tableMaxCols:0})).ndjson);
 const rows=s.getRange('A7:L46').values;
 console.log(JSON.stringify({oldRows:rows.length,sent:rows.filter(r=>r[7]!=='Não enviado').length,pendingRows:pending.getRange('A7:F7').values.length}));
 for(const [sheet,range,file] of [['Vouchers','A1:B10','before-vouchers.png'],['Pendências','A1:C8','before-pending.png']]){
  const blob=await wb.render({sheetName:sheet,range,scale:1,format:'png'});await fs.writeFile(new URL(file,support),new Uint8Array(await blob.arrayBuffer()));
 }
}
if(process.argv[2]==='edit'){
 const verified=JSON.parse(await fs.readFile(new URL('verify.json',support),'utf8'));
 const contacts=JSON.parse(await fs.readFile(new URL('contacts.json',support),'utf8'));
 const prepared=JSON.parse(await fs.readFile(new URL('prepare.json',support),'utf8'));
 const byId=new Map(contacts.map(r=>[String(r.id_conta),r]));
 const before=s.getRange('A7:L46').values;
 const rows=verified.codes.map(v=>({...byId.get(String(v.id_conta)),...v}));
 if(rows.length!==46 || new Set(rows.map(r=>r.voucher)).size!==46)throw Error('Lote inconsistente');
 const allCodes=[...before.map(r=>r[2]),...rows.map(r=>r.voucher)];
 if(new Set(allCodes).size!==86 || allCodes.some(v=>!/^BQ26-[A-F0-9]{32}$/.test(v)))throw Error('Vouchers inválidos ou duplicados');
 const allEmails=[...before.map(r=>r[1]),...rows.map(r=>r.email)];
 if(new Set(allEmails).size!==86)throw Error('Destinatários repetidos');
 const values=rows.map(r=>[r.empresa,r.email,r.voucher,'https://business.roadrunners.run/estudos/primeiro-acesso/',new Date('2026-11-10T00:00:00Z'),'Pendente',r.contato,'Não enviado',null,String(r.voucher_id),r.fonte,'Novo: CNPJ pendente; contato ABRACEO reconferido']);
 s.tables.items.find(t=>t.name==='VouchersABRACEO').rows.add(null,values);
 for(let i=47;i<=92;i++)s.getRange(`A${i}:L${i}`).copyFrom(s.getRange('A46:L46'),'all');
 s.getRange('A47:L92').values=values;
 s.getRange('A2').values=[['Vouchers ABRACEO — 86 convites']];
 s.getRange('A4').values=[['40 convites anteriores preservados e 46 novos. E-mails reconferidos em fontes públicas; entrega não testada. Envio individual.']];
 s.getRange('F6').values=[['CNPJ / situação']];
 s.getRange('A47:L92').format.rowHeight=58;s.getRange('L47:L92').format.wrapText=true;
 s.getRange('H47:H92').dataValidation={rule:{type:'list',values:['Não enviado','Enviado','Revisar']}};
 pending.getRange('A4').values=[['Nenhum voucher emitido para as empresas abaixo.']];
 pending.getRange('A8:F8').copyFrom(pending.getRange('A7:F7'),'all');
 pending.getRange('A8:F8').values=prepared.pending.map(r=>[r.empresa,r.email,r.motivo,r.fonte,'Pendente','Confirmar e-mail de quem receberá o convite']);
 pending.getRange('F8').format.wrapText=true;
 if(JSON.stringify(before)!==JSON.stringify(s.getRange('A7:L46').values))throw Error('Linhas anteriores alteradas');
 s.getRange('F7:F46').setNumberFormat('00000000000000');s.getRange('F47:F92').setNumberFormat('@');pending.getRange('E7').setNumberFormat('00000000000000');pending.getRange('E8').setNumberFormat('@');
 wb.recalculate();
 const inspection=await wb.inspect({kind:'table',range:'Vouchers!A47:L49',include:'values',tableMaxRows:3,tableMaxCols:12,maxChars:4500});
 await fs.writeFile(new URL('inspection.ndjson',support),inspection.ndjson,{mode:0o600});
 const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:30},maxChars:1000});
 console.log(errors.ndjson);
 for(const [sheet,range,file] of [['Vouchers','A44:F49','preview-new.png'],['Pendências','A1:F8','preview-pending.png']]){
  const blob=await wb.render({sheetName:sheet,range,scale:1,format:'png'});await fs.writeFile(new URL(file,support),new Uint8Array(await blob.arrayBuffer()),{mode:0o600});
 }
 const target=new URL('vouchers_abraceo.xlsx',out).pathname;await (await SpreadsheetFile.exportXlsx(wb)).save(target);await fs.chmod(target,0o600);
 await fs.writeFile(new URL('validation.json',support),JSON.stringify({vouchers:86,old_preserved:40,new_verified:46,pending:2,unique_codes:true,unique_emails:true,new_sent:0,old_send_status_preserved:true},null,2));
 console.log(JSON.stringify({vouchers:86,new_vouchers:46,pending:2,old_rows_preserved:true}));
}
if(process.argv[2]==='verify-saved'){
 const {createHash}=await import('node:crypto');
 const v=JSON.parse(await fs.readFile(new URL('verify.json',support),'utf8'));
 const previous=new Map(v.previous_vouchers.map(r=>[String(r.id),r]));
 const newer=new Map(v.codes.map(r=>[String(r.voucher_id),r]));
 const saved=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',out).pathname));
 const rows=saved.worksheets.getItem('Vouchers').getRange('A7:L92').values;
 for(const r of rows){
  const old=previous.get(String(r[9])),n=newer.get(String(r[9]));
  if(old){if(createHash('sha256').update(r[2]).digest('hex')!==old.hash || r[1]!==old.email || old.status!=='READY')throw Error('Convite anterior divergente');}
  else if(!n || n.voucher!==r[2] || n.email!==r[1])throw Error('Novo convite divergente');
 }
 if(JSON.stringify(saved.worksheets.getItem('Vouchers').getRange('A7:L46').values)!==JSON.stringify(s.getRange('A7:L46').values))throw Error('Export alterou convites antigos');
 console.log(JSON.stringify({saved_rows:rows.length,matched_live_vouchers:86,old_rows_preserved_after_export:true,sheets:saved.worksheets.items.length}));
}
