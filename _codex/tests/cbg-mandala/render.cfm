<cfscript>
VARIABLES.challengeCircuitEvents=[];VARIABLES.challengeCircuitTotalEvents=8;VARIABLES.challengeMedalCsrf='fixture';VARIABLES.challengeMandalaError='';
columns='id,nome,imagem_usuario,email,ddi_usuario,ddd_usuario,telefone_usuario,instagram,whatsapp,tag,cidade,estado,equipe,mandala_status,mandala_entregue_em,mandala_numero,nodesafio';for(i=1;i<=8;i++)columns&=',participou_'&i&',ano_'&i;
qBrasilGiganteRanking=queryNew(columns);
for(i=1;i<=3;i++){
 row={};for(key in listToArray(columns))row[key]='';row.id=i;row.nome='Atleta sintético '&i;row.imagem_usuario='/assets/user.png';row.nodesafio=8;row.mandala_status=i EQ 1?'imediata':'entregue';row.mandala_numero=i EQ 3?'000123':'';
 for(j=1;j<=8;j++){row['participou_'&j]=1;row['ano_'&j]=2026;}
 queryAddRow(qBrasilGiganteRanking,row);
}
savecontent variable='page'{include '../desafios/includes/brasil_gigante_table.cfm';}
if(!find('Mandala nº 000123',page) OR !find('Número não informado',page) OR !find('Informar número',page) OR !find('confirmar_mandala',page) OR !find('pattern="[0-9]{1,12}"',page))throw(message='Render de número e confirmação obrigatória falhou');
VARIABLES.challengeMandalaError='Inválido';FORM.id_usuario=1;FORM.mandala_numero='"<script>';
savecontent variable='page'{include '../desafios/includes/brasil_gigante_table.cfm';}
if(!find('open',page) OR find('value=""<script>',page))throw(message='Falha na preservação segura do formulário');
sheet=spreadsheetNew('Mandalas',true);spreadsheetSetCellValue(sheet,'000123',1,1,'String');if(compare(spreadsheetGetCellValue(sheet,1,1),'000123') NEQ 0)throw(message='Excel perdeu zeros à esquerda');
writeOutput('CBG_MANDALA_RENDER_PASSED');
</cfscript>
