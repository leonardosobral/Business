import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const support=new URL('./',import.meta.url),out=new URL('../',support),old=new URL('../../abraceo-convites-atualizados-20261011/',support);
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',old).pathname));
const s=wb.worksheets.getItem('Vouchers'),pending=wb.worksheets.getItem('Pendências');
if(process.argv[2]==='inspect'){
 console.log(JSON.stringify({existingRows:s.getRange('A7:L92').values.length,pending:pending.getRange('A7:F8').values.map(r=>[r[0],r[1],r[2]])}));
 const blob=await wb.render({sheetName:'Pendências',range:'A1:F8',scale:1,format:'png'});await fs.writeFile(new URL('before.png',support),new Uint8Array(await blob.arrayBuffer()));
}
if(process.argv[2]==='edit'){
 const verified=JSON.parse(await fs.readFile(new URL('verify.json',support),'utf8'));
 const contacts=JSON.parse(await fs.readFile(new URL('contacts.json',support),'utf8'));
 const byId=new Map(contacts.map(r=>[String(r.id_conta),r]));
 const before=s.getRange('A7:L92').values;
 const rows=verified.codes.map(v=>({...v,...byId.get(String(v.id_conta))}));
 if(rows.length!==2 || verified.verified!==2)throw Error('Lote inconsistente');
 const allCodes=[...before.map(r=>r[2]),...rows.map(r=>r.voucher)];
 if(new Set(allCodes).size!==88 || allCodes.some(v=>!/^BQ26-[A-F0-9]{32}$/.test(v)))throw Error('Voucher inválido ou duplicado');
 const values=rows.map(r=>[r.empresa,r.email,r.voucher,'https://business.roadrunners.run/estudos/primeiro-acesso/',new Date('2026-11-10T00:00:00Z'),r.cnpj||'Pendente',r.contato,'Não enviado',null,String(r.voucher_id),r.fonte,r.motivo]);
 s.tables.items.find(t=>t.name==='VouchersABRACEO').rows.add(null,values);
 for(let i=93;i<=94;i++)s.getRange(`A${i}:L${i}`).copyFrom(s.getRange('A92:L92'),'all');
 s.getRange('A93:L94').values=values;
 s.getRange('A2').values=[['Vouchers ABRACEO — 88 convites']];
 s.getRange('A4').values=[['86 convites anteriores preservados e 2 novos. E-mails confirmados em fontes públicas; entrega não testada. Envio individual.']];
 s.getRange('A93:L94').format.rowHeight=62;s.getRange('L93:L94').format.wrapText=true;
 s.getRange('F93').setNumberFormat('@');s.getRange('F94').setNumberFormat('00000000000000');
 s.getRange('H93:H94').dataValidation={rule:{type:'list',values:['Não enviado','Enviado','Revisar']}};
 pending.getRange('A2').values=[['Pendências de contato resolvidas']];
 pending.getRange('A4').values=[['Sem pendências de contato neste lote: 88 empresas pré-cadastradas com vouchers emitidos.']];
 pending.getRange('A6:F6').values=[['Empresa','E-mail confirmado','Resolução','Fonte da confirmação','CNPJ / situação','Resultado']];
 const resolved=[...rows].sort((a,b)=>a.empresa.localeCompare(b.empresa,'pt-BR'));
 pending.getRange('A7:F8').values=resolved.map(r=>[r.empresa,r.email,r.motivo,r.fonte,r.cnpj||'Pendente','Resolvido — voucher emitido']);
 pending.getRange('F7:F8').format.fill='#E8F1E8';pending.getRange('C7:F8').format.wrapText=true;
 pending.getRange('A7:F8').format.rowHeight=72;
 if(JSON.stringify(before)!==JSON.stringify(s.getRange('A7:L92').values))throw Error('Linhas anteriores alteradas');
 wb.recalculate();
 console.log((await wb.inspect({kind:'table',range:'Pendências!A7:C8',include:'values',tableMaxRows:2,tableMaxCols:3,maxChars:1400})).ndjson);
 const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:30},maxChars:800});console.log(errors.ndjson);
 for(const [sheet,range,file] of [['Vouchers','A91:F94','preview-new.png'],['Pendências','A1:F8','preview-resolved.png']]){
  const blob=await wb.render({sheetName:sheet,range,scale:1,format:'png'});await fs.writeFile(new URL(file,support),new Uint8Array(await blob.arrayBuffer()),{mode:0o600});
 }
 const target=new URL('vouchers_abraceo.xlsx',out).pathname;await (await SpreadsheetFile.exportXlsx(wb)).save(target);await fs.chmod(target,0o600);
 await fs.writeFile(new URL('validation.json',support),JSON.stringify({vouchers:88,old_preserved:86,new_verified:2,pending_contacts:0,unique_codes:true,new_sent:0,old_send_status_preserved:true},null,2));
 console.log(JSON.stringify({vouchers:88,new_vouchers:2,pending_contacts:0,old_rows_preserved:true}));
}
if(process.argv[2]==='verify-saved'){
 const v=JSON.parse(await fs.readFile(new URL('verify.json',support),'utf8'));
 const previous=new Map(v.previous_vouchers.map(r=>[String(r.id),r]));
 const newer=new Map(v.codes.map(r=>[String(r.voucher_id),r]));
 const saved=await SpreadsheetFile.importXlsx(await FileBlob.load(new URL('vouchers_abraceo.xlsx',out).pathname));
 const rows=saved.worksheets.getItem('Vouchers').getRange('A7:L94').values;
 if(new Set(rows.map(r=>r[1])).size!==88)throw Error('E-mails duplicados');
 for(const r of rows){
  const old=previous.get(String(r[9])),n=newer.get(String(r[9]));
  if(old){if(createHash('sha256').update(r[2]).digest('hex')!==old.hash || r[1]!==old.email)throw Error('Convite anterior divergente');}
  else if(!n || n.voucher!==r[2] || n.email!==r[1])throw Error('Novo convite divergente');
 }
 if(JSON.stringify(saved.worksheets.getItem('Vouchers').getRange('A7:L92').values)!==JSON.stringify(s.getRange('A7:L92').values))throw Error('Export alterou convites antigos');
 console.log(JSON.stringify({saved_rows:rows.length,matched_live_vouchers:88,old_rows_preserved_after_export:true,sheets:saved.worksheets.items.length}));
}
