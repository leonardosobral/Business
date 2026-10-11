import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';

const dir=path.dirname(fileURLToPath(import.meta.url)),out=path.dirname(dir);
const contacts=JSON.parse(await fs.readFile(path.join(dir,'contacts.json'),'utf8'));
const verified=JSON.parse(await fs.readFile(path.join(dir,'verify.json'),'utf8'));
const prepared=JSON.parse(await fs.readFile(path.join(dir,'prepare.json'),'utf8'));
const byId=new Map(contacts.map(r=>[String(r.id_conta),r]));
const link='https://business.roadrunners.run/estudos/primeiro-acesso/';
const rows=verified.codes.map(v=>({...byId.get(String(v.id_conta)),...v}));
if(rows.length!==40 || new Set(rows.map(r=>r.voucher)).size!==40 || new Set(rows.map(r=>r.email)).size!==40)throw Error('Lote inconsistente');
for(const r of rows)if(!/^BQ26-[A-F0-9]{32}$/.test(r.voucher))throw Error('Voucher inválido');
const wb=Workbook.create();const s=wb.worksheets.add('Vouchers'),pending=wb.worksheets.add('Pendências');
const ink='#252525',amber='#FFCC08';
function base(sheet,end,widths){
 sheet.showGridLines=false;sheet.getRange(end).format.font={name:'Arial',size:11,color:ink};
 sheet.getRange(end).format.verticalAlignment='center';sheet.getRange(end).format.rowHeight=28;
 for(const [col,width] of Object.entries(widths))sheet.getRange(`${col}:${col}`).format.columnWidthPx=width;
 sheet.getRange('A2').format.font={name:'Arial',size:16,bold:true,color:ink};
}
base(s,'A1:L46',{A:250,B:320,C:340,D:475,E:140,F:165,G:280,H:120,I:150,J:100,K:475,L:310});
s.tabColor=ink;s.getRange('A2').values=[['Vouchers ABRACEO']];
s.getRange('A3').values=[['Emitidos em 11/10/2026. Resgate até 10/11/2026, às 23h59 (Brasília).']];
s.getRange('A4').values=[['E-mails reconferidos nos perfis públicos da ABRACEO; entrega não testada. Envio individual.']];
s.getRange('A6:L6').values=[['Empresa','E-mail','Voucher','Link de acesso','Resgatar até','CNPJ','Contato publicado','Envio','Data do envio','ID do voucher','Fonte do contato','Seleção do e-mail']];
s.getRange(`A7:L${6+rows.length}`).values=rows.map(r=>[r.empresa,r.email,r.voucher,link,new Date('2026-11-10T00:00:00Z'),r.cnpj,r.contato,'Não enviado',null,String(r.voucher_id),r.fonte,r.id_conta===39?'HL: principal autorizado':r.email!==r.email_business?'Contato ABRACEO; conta preservada':'Contato ABRACEO reconferido']);
s.getRange('A6:L46').format.wrapText=false;
s.getRange('A7:A46').format.wrapText=true;s.getRange('A7:L46').format.rowHeight=42;
s.getRange('C7:D46').setNumberFormat('@');s.getRange('F7:F46').setNumberFormat('@');s.getRange('J7:J46').setNumberFormat('@');
s.getRange('E7:E46').setNumberFormat('dd/mm/yyyy');s.getRange('I7:I46').setNumberFormat('dd/mm/yyyy');
s.getRange('G7:G46').format.wrapText=true;
const table=s.tables.add('A6:L46',true,'VouchersABRACEO');table.showFilterButton=true;
s.getRange('A6:L6').format={fill:ink,font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},horizontalAlignment:'center',rowHeight:34};
s.getRange('H7:I46').format.fill='#FFF6CE';s.getRange('H7:H46').dataValidation={rule:{type:'list',values:['Não enviado','Enviado','Revisar']}};
s.freezePanes.freezeRows(6);s.freezePanes.freezeColumns(1);
base(pending,'A1:F9',{A:220,B:310,C:480,D:470,E:200,F:230});
pending.getRange('A2').values=[['Contato a confirmar']];pending.getRange('A4').values=[['Nenhum voucher foi emitido para esta empresa.']];
pending.getRange('A6:F6').values=[['Empresa','E-mail publicado','Pendência','Fonte','CNPJ','Ação da ABRACEO']];
pending.getRange('A7:F7').values=prepared.pending.map(r=>[r.empresa,r.email,r.motivo,r.fonte,r.cnpj,'Confirmar grafia do e-mail']);
pending.getRange('A6:F6').format={fill:ink,font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},horizontalAlignment:'center',rowHeight:34};
pending.getRange('A7:F7').format.rowHeight=62;pending.getRange('C7').format.wrapText=true;pending.getRange('E7').setNumberFormat('@');pending.getRange('F7').format.fill='#FFF6CE';
wb.recalculate();
const inspection=await wb.inspect({kind:'table',range:'Vouchers!A6:L9',include:'values',tableMaxRows:4,tableMaxCols:12});
await fs.writeFile(path.join(dir,'inspection.ndjson'),inspection.ndjson,{mode:0o600});
const errorScan=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!',options:{useRegex:true,maxResults:30}});
await fs.writeFile(path.join(dir,'errors.ndjson'),errorScan.ndjson,{mode:0o600});
for(const [sheet,range,file] of [['Vouchers','A1:E11','preview-vouchers.png'],['Pendências','A1:C8','preview-pendencias.png']]){
 const blob=await wb.render({sheetName:sheet,range,scale:1,format:'png'});await fs.writeFile(path.join(dir,file),new Uint8Array(await blob.arrayBuffer()),{mode:0o600});
}
const xlsx=await SpreadsheetFile.exportXlsx(wb);const dest=path.join(out,'vouchers_abraceo.xlsx');await xlsx.save(dest);await fs.chmod(dest,0o600);
const template=`Assunto: ABRACEO | Acesso à prévia Brasil que Corre Provas 2026

Olá, equipe da {{empresa}}!

A ABRACEO convida sua empresa a conhecer a prévia profissional do estudo Brasil que Corre Provas 2026, desenvolvido pelo Road Runners Business, com dados de janeiro a setembro.

O cadastro da {{empresa}} já está preparado, com os dados disponíveis e o logotipo, para facilitar seu primeiro acesso.

Acesse: {{link_de_acesso}}
E-mail do convite: {{email}}
Seu voucher: {{voucher}}
Prazo para resgatar: 10/11/2026, até 23h59 (horário de Brasília).

Entre com o Google usando o e-mail do convite, escolha “Com voucher” e informe o código. Confira os dados da empresa e, na aba “Confirmar representante”, informe sua função e confirme a declaração para liberar a leitura.

Se o e-mail convidado não estiver associado a uma conta Google, você também pode entrar com sua própria conta Google e escolher “Com CNPJ”, informando {{cnpj}}. Depois, confirme sua representação da empresa.

Encontrou algo a corrigir no cadastro? Informe a correção durante o primeiro acesso.

A confirmação libera a leitura pessoal da prévia. As permissões de gestão da conta empresarial seguem o processo de aprovação do Business.

Boa leitura!
Equipe ABRACEO
`;
await fs.writeFile(path.join(out,'convite_abraceo.txt'),template,'utf8');
await fs.writeFile(path.join(dir,'validation.json'),JSON.stringify({rows:rows.length,pending:prepared.pending.length,unique_codes:true,unique_emails:true,verified_in_business:verified.verified,sheets:['Vouchers','Pendências'],sent:0},null,2));
console.log(JSON.stringify({xlsx:dest,vouchers:rows.length,pending:prepared.pending.length,invitation:path.join(out,'convite_abraceo.txt')}));
