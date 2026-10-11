import fs from 'node:fs/promises';
import path from 'node:path';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';
const root=path.resolve(import.meta.dirname,'..');
const data=JSON.parse(await fs.readFile(path.join(root,'research/prepared.json'),'utf8'));
const wb=Workbook.create();
const summary=wb.worksheets.add('Resumo');
const members=wb.worksheets.add('Filiados');
const legal=wb.worksheets.add('Pessoas jurídicas');
const logos=wb.worksheets.add('Logotipos');
const mapping=wb.worksheets.add('Cadastro Business');
const reviewed=wb.worksheets.add('Revisão de CNPJs');
const drafts=wb.worksheets.add('Pré-cadastro');
const business=wb.worksheets.add('Cruzamento Business');
const accounts=wb.worksheets.add('Contas existentes');
const events=wb.worksheets.add('Eventos');
const external=wb.worksheets.add('Eventos externos');
const ink='#183449', muted='#596B7A', pale='#EDF3F7', amber='#FFF0CC';
function col(n){let s='';for(n++;n;n=Math.floor((n-1)/26))s=String.fromCharCode(65+(n-1)%26)+s;return s;}
function setup(sh,title,note,lastCol,lastRow){
  sh.showGridLines=false;
  const area=sh.getRange(`A1:${lastCol}${lastRow}`);
  area.format.font={name:'Arial',size:10,color:ink};
  area.format.verticalAlignment='center';
  area.format.rowHeight=30;
  sh.getRange('A2').values=[[title]];
  sh.getRange('A2').format.font={name:'Arial',size:16,bold:true,color:ink};
  sh.getRange('A3').values=[[note]];
  sh.getRange('A3').format.font={name:'Arial',size:10,color:muted};
}
function table(sh,columns,rows,name){
  let last=col(columns.length-1),end=5+rows.length;
  const displayValue=(r,c)=>{
    let v=r[c[0]];
    if(v===''||v==null)return null;
    if(['data_inicial','data_final','data'].includes(c[0]))return (Date.parse(v+'T00:00:00Z')-Date.UTC(1899,11,30))/86400000;
    if(['cnpj_pesquisado','cnpj_conta','cnpj','documento_para_revisao','cnpj_anterior','cnpj_revisado','documento'].includes(c[0]))
      return String(v).replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
    if(c[0]==='cep')return String(v).replace(/^(\d{5})(\d{3})$/, '$1-$2');
    if(c[0]==='cnae_principal')return String(v).replace(/^(\d{4})(\d)(\d{2})$/, '$1-$2/$3');
    return v;
  };
  sh.getRange(`A5:${last}${end}`).values=[columns.map(c=>c[1]),...rows.map(r=>columns.map(c=>displayValue(r,c)))];
  sh.tables.add(`A5:${last}${end}`,true,name);
  sh.getRange(`A5:${last}5`).format={fill:ink,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},wrapText:true,horizontalAlignment:'center',verticalAlignment:'center',rowHeight:42};
  sh.getRange(`A6:${last}${end}`).format.wrapText=true;
  sh.getRange(`A6:${last}${end}`).format.rowHeight=78;
  columns.forEach((c,i)=>{sh.getRange(`${col(i)}5:${col(i)}${end}`).format.columnWidth=c[2]||24;if(c[3])sh.getRange(`${col(i)}6:${col(i)}${end}`).setNumberFormat(c[3]);});
  columns.forEach((c,i)=>{if(c[0].startsWith('fonte')||c[0]==='site_abraceo')sh.getRange(`${col(i)}6:${col(i)}${end}`).format.font={name:'Arial',size:9,color:'#175A87'};});
  sh.freezePanes.freezeRows(5);sh.freezePanes.freezeColumns(2);
}
const mc=[['id_filiado','ID filiado',28],['nome_abraceo','Nome na ABRACEO',32],['status_vinculo_cnpj','Situação da pesquisa do CNPJ',28],['cnpj_pesquisado','CNPJ pesquisado',22,'@'],['razao_social_pesquisada','Razão social pesquisada',46],['situacao_cadastral_consultada','Situação cadastral consultada',20],['segmento','Atuação pesquisada',34],['tipo_prestador_sugerido','Tipo Business sugerido',22],['evidencia_atuacao','Base da classificação',28],['contato_publico','Contato divulgado',34],['email_publico','E-mail público',42],['telefone_publico','Telefone publicado',36,'@'],['cidade_abraceo','Cidade ABRACEO',25],['uf_abraceo','UF',8],['site_abraceo','Site / link ABRACEO',46],['instagram_publicado','Instagram publicado',38],['documento_para_revisao','Documento para revisão de pré-cadastro',25,'@'],['pendencias','Próxima revisão necessária',65],['observacoes','Divergências e observações',72],['fonte_abraceo','Fonte dos contatos e filiação',60],['fonte_vinculo_cnpj','Fonte do vínculo marca / CNPJ',65],['fonte_atuacao','Fonte da atuação',60],['logo_arquivo','Arquivo do logotipo',48]];
mc[2]=['status_pre_cadastro','Situação do pré-cadastro',28];
mc.push(['revisado_em','Revisado em',16]);
mc.push(['conta_business','Conta no Business',34],['id_conta_business','ID conta existente',18,'@'],['acao_business','Ação no Business',35],['eventos_relacionados','Eventos com indícios',20,'0']);
setup(members,'Filiados ABRACEO','Base inicial de 10/10/2026; revisão concluída em 11/10/2026. Rascunhos exigem confirmação no primeiro acesso.',col(mc.length-1),101);
table(members,mc,data.filiados,'FiliadosTabela');
members.getRange('C6:C101').conditionalFormats.add('containsText',{text:'AGUARDA',format:{fill:amber,font:{color:'#805600'}}});
members.getRange('F6:F101').conditionalFormats.add('containsText',{text:'BAIXADA',format:{fill:'#FDE3E1',font:{color:'#9F2724',bold:true}}});
members.getRange('F6:F101').conditionalFormats.add('containsText',{text:'INAPTA',format:{fill:'#FDE3E1',font:{color:'#9F2724',bold:true}}});
members.getRange('H6:H101').dataValidation={rule:{type:'list',values:['Organizador','Cronometragem','Assessoria','Marca/Patrocinador','Midia/Criador','Fornecedor','Agencia','Outro']}};
const lc=[['id_filiado','ID filiado',28],['nome_abraceo','Nome na ABRACEO',32],['cnpj','CNPJ',22,'@'],['papel_na_pesquisa','Papel na pesquisa',27],['digitos_verificadores','Dígitos verificadores',19],['razao_social','Razão social',48],['nome_fantasia','Nome fantasia cadastral',38],['situacao','Situação consultada',18],['endereco','Endereço cadastral',58],['bairro','Bairro',30],['cep','CEP',13,'@'],['municipio','Município cadastral',29],['uf','UF cadastral',11],['cnae_principal','CNAE principal',17,'@'],['cnae_descricao','Descrição do CNAE principal',65],['natureza_juridica','Natureza jurídica',35],['porte','Porte',24],['abertura','Abertura (como publicada)',23],['fonte','Fonte cadastral',70],['observacao','Observação',75]];
lc.push(['fonte_papel','Fonte da decisão de uso',65],['revisado_em','Revisado em',16]);
setup(legal,'Pessoas jurídicas encontradas','Histórico preservado: CNPJs selecionados, candidatos, matrizes, filiais e registros que não devem ser usados.',col(lc.length-1),5+data.juridicas.length);
table(legal,lc,data.juridicas,'PessoasJuridicasTabela');
legal.getRange(`H6:H${5+data.juridicas.length}`).conditionalFormats.add('containsText',{text:'BAIXADA',format:{fill:'#FDE3E1'}});
setup(logos,'Logotipos dos filiados','96 imagens publicadas nas fichas da ABRACEO. Os arquivos originais estão no pacote, na pasta logotipos.', 'D',101);
logos.getRange('A5:D5').values=[['ID filiado','Nome na ABRACEO','Logotipo','Fonte da imagem']];
logos.getRange('A5:D5').format={fill:ink,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:28};
logos.getRange('A6:D101').format.rowHeight=74;
logos.getRange('A6:D101').format.wrapText=true;
logos.getRange('A5:A101').format.columnWidth=30;
logos.getRange('B5:B101').format.columnWidth=36;
logos.getRange('C5:C101').format.columnWidth=22;
logos.getRange('D5:D101').format.columnWidth=65;
logos.getRange('A6:D101').values=data.filiados.map(r=>[r.id_filiado,r.nome_abraceo,'',r.logo_url]);
for(let i=0;i<data.filiados.length;i++){
 const r=data.filiados[i], bytes=await fs.readFile(path.join(root,r.logo_arquivo));
 const ext=path.extname(r.logo_arquivo).toLowerCase(),mime=ext==='.png'?'image/png':'image/jpeg';
 const scale=Math.min(130/r.logo_width,80/r.logo_height);
 logos.images.add({dataUrl:`data:${mime};base64,${bytes.toString('base64')}`,anchor:{from:{row:i+5,col:2,rowOffsetPx:8,colOffsetPx:8},extent:{widthPx:Math.round(r.logo_width*scale),heightPx:Math.round(r.logo_height*scale)}}});
}
logos.freezePanes.freezeRows(5);

setup(summary,'ABRACEO — contas e eventos para pré-cadastro','Versão 3. Cruzamento com produção em 11/10/2026. 96 filiados publicados; 98 informados na reunião.', 'H',46);
summary.tabColor=ink;
summary.getRange('A5:C5').values=[['Cobertura','Quantidade','Leitura']];
summary.getRange('A5:C5').format={fill:ink,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:28};
const metrics=[
 ['Membros informados na reunião',98,'Referência fornecida pelo usuário'],
 ['Fichas distintas publicadas',null,'Não equivale a comprovação de quadro ativo'],
 ['Diferença a conciliar',null,'Diferença numérica; depende de conciliar as duas listas'],
 ['Filiados com CNPJ pesquisado',null,'Inclui candidatos e casos com divergências'],
 ['Com razão social localizada',null,'Razão social corresponde ao CNPJ pesquisado'],
 ['Com e-mail divulgado',null,'E-mail público não é identidade autenticada'],
 ['Com telefone divulgado',null,'Formato original preservado'],
 ['Com contato nominal',null,'Nome divulgado na ficha ABRACEO'],
 ['Com endereço cadastral',data.resumo.com_endereco,'Endereço da PJ pesquisada; veja divergências'],
 ['Logotipos em imagem',96,'Arquivos originais também incluídos no pacote'],
 ['Vínculo em fonte primária',data.resumo.cnpj_fonte_primaria,'Site, regulamento ou documento de órgão público'],
 ['Aptos para rascunho de pré-cadastro',null,'CNPJ ativo, vínculo selecionado e tipo preenchido; confirmar no acesso'],
 ['Filiados com múltiplas PJs',data.resumo.multiplas_pjs,'Selecionar titular antes de qualquer importação'],
 ['CNPJ principal baixado ou inapto',data.resumo.cnpj_principal_nao_ativo,'Consultar CNPJ atual com a empresa'],
 ['Registros de pessoas jurídicas',data.resumo.pessoas_juridicas,'Inclui alternativas, matrizes e filiais']
];
summary.getRange('A6:C20').values=metrics;
const formulas={B7:"=COUNTA('Filiados'!A6:A101)",B8:'=B6-B7',B9:"=ROWS('Filiados'!D6:D101)-COUNTBLANK('Filiados'!D6:D101)",B10:"=ROWS('Filiados'!E6:E101)-COUNTBLANK('Filiados'!E6:E101)",B11:"=ROWS('Filiados'!K6:K101)-COUNTBLANK('Filiados'!K6:K101)",B12:"=ROWS('Filiados'!L6:L101)-COUNTBLANK('Filiados'!L6:L101)",B13:"=ROWS('Filiados'!J6:J101)-COUNTBLANK('Filiados'!J6:J101)",B17:"=ROWS('Filiados'!Q6:Q101)-COUNTBLANK('Filiados'!Q6:Q101)"};
for(const [a,f] of Object.entries(formulas))summary.getRange(a).formulas=[[f]];
summary.getRange('B17').formulas=[["=COUNTIF('Filiados'!C6:C101,\"APTO PARA RASCUNHO\")"]];
summary.getRange('A5:A30').format.columnWidth=41;
summary.getRange('B5:B30').format.columnWidth=13;
summary.getRange('C5:C30').format.columnWidth=72;
summary.getRange('A6:C20').format.rowHeight=30;
summary.getRange('B6:B20').setNumberFormat('0');
summary.getRange('A8:C8').format.fill=amber;
summary.getRange('A22:C24').values=[['Casos prioritários revisados',data.resumo.revisados,'Múltiplos CNPJs, inativos e documentos antes não localizados'],['Revisados incluídos no lote',data.resumo.revisados_aptos,'Demais casos têm decisão e pergunta pendente na aba Revisão de CNPJs'],['Aguardam confirmação na base',data.resumo.aguarda_confirmacao,'Excluídos do CSV e JSON de rascunhos']];
summary.getRange('A24:C24').format.fill=amber;
summary.getRange('A26:C26').values=[['Cruzamento Business','Quantidade','Leitura']];
summary.getRange('A26:C26').format={fill:ink,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:28};
const bs=data.business_resumo;
summary.getRange('A27:C36').values=[['Contas com CNPJ exato',bs.contas_exatas,'CORPA, Grupo STC, TR Crono, Voa Esportes e Yescom'],['Conta relacionada com outro CNPJ',bs.contas_outro_cnpj,'MP3 Marketing: confirmar pessoa jurídica e representante'],['Novos rascunhos selecionados',bs.novos_rascunhos,'Quatro contas existentes retiradas do lote anterior de 40'],['Filiados com indícios no catálogo',bs.filiados_com_eventos,'Veja o papel, a evidência e as ressalvas na aba Eventos'],['Eventos distintos no catálogo',bs.eventos_distintos,'Um evento pode se relacionar a mais de um filiado'],['Relações filiado / evento',bs.relacoes,'Uma linha por par de filiado e evento'],['Vínculos ativos nas contas exatas',bs.vinculos_existentes,'Relações já registradas; nenhum vínculo novo foi gravado'],['Relações só por site',bs.relacoes_por_classe['SITE RELACIONADO; PAPEL A CONFIRMAR'],'Domínio pode ser plataforma; não comprova organização'],['Fornecedores identificados',data.fornecedores.length,'Fornecedor cadastrado não equivale a conta Business'],['Relações em fontes externas',data.eventos_externos.length,'Inclui fontes primárias e secundárias, com status separado']];
summary.getRange('A27:C36').format.rowHeight=32;
summary.getRange('B27:B36').setNumberFormat('0');
summary.getRange('A38').values=[['Uso desta base']];summary.getRange('A38').format.font.bold=true;
summary.getRange('A39').values=[['1. Consultar Cruzamento Business para reaproveitar contas e usar o lote de 36 novos rascunhos.']];
summary.getRange('A40').values=[['2. Confirmar representante, pessoa jurídica e papel no evento antes de conceder acesso.']];
summary.getRange('A41').values=[['3. Filtrar Eventos por filiado, período e evidência. Fonte externa não significa vínculo gravado.']];
summary.getRange('A42').values=[['CNPJ não é senha. Contatos públicos não substituem a identidade do responsável autenticado.']];
summary.getRange('A43').values=[['Consulta de produção somente leitura. Nenhuma conta, voucher ou associação foi criada.']];
summary.getRange('A44').values=[['96 logotipos baixados e validados; manifesto com fonte, dimensão e hash no pacote.']];
summary.getRange('A45').values=[['A relação nominal dos 98 membros ainda é necessária para conciliar o quadro da associação.']];

setup(mapping,'Campos do cadastro Business','Mapeamento do formulário atual e orientações para a futura integração. Levantamento de código em 10/10/2026.', 'D',30);
const maps=[
['nome_empresa','Sim','nome_abraceo; confirmar como nome da conta','Máximo 160 caracteres. Razão social é preservada separadamente na pesquisa.'],
['tipo_titular','Sim','PJ quando o CNPJ da empresa for confirmado','Valores atuais PF e PJ. Não presumir PJ apenas pela marca.'],
['documento','Sim','CNPJ validado após revisão do vínculo','A aplicação remove pontuação. Documento com 14 dígitos, como texto.'],
['tipo_prestador','Sim','tipo_prestador_sugerido, confirmado pela empresa','Organizador, Cronometragem, Assessoria, Marca/Patrocinador, Midia/Criador, Fornecedor, Agencia, Outro.'],
['nome_responsavel','Sim','Identidade Google autenticada','É preenchido pelo servidor com a identidade confirmada, não pelo contato público.'],
['email_responsavel','Sim','E-mail Google autenticado','E-mail da pesquisa é contato comercial; não concede propriedade da conta.'],
['telefone_responsavel','Opcional','Telefone confirmado pelo representante','Máximo 30 caracteres; separar os múltiplos telefones da pesquisa antes de importar.'],
['site','Opcional','Site oficial revisado','Máximo 256 caracteres. Algumas fichas apontam apenas Instagram ou Facebook.'],
['cidade / estado','Opcional','Localização escolhida e confirmada','Cidade até 128 caracteres e UF com 2. Há diferença entre operação e sede cadastral.'],
['mensagem','Opcional','Descrição da atuação confirmada','Não inserir observações internas de pesquisa no texto enviado pelo usuário.'],
['Razão social / nome fantasia','Sem campos separados no formulário','Colunas próprias na base de pesquisa','Definir armazenamento na futura integração sem usar nome_titular como razão social automaticamente.'],
['Endereço / CEP / logotipo','Não presentes no formulário externo','Pessoas jurídicas e arquivos de imagem','São dados complementares coletados; a integração precisará definir os destinos.'],
['Voucher do estudo','Fluxo separado','Convite nominal associado ao e-mail','O fluxo do estudo libera leitura; não atribui propriedade da organização por si só.'],
['CNPJ no primeiro acesso','Proposta a implementar','Buscar pré-cadastro e mostrar dados para confirmação','Não usar CNPJ público como senha. Preservar login, revisão de vínculo e deduplicação.'],
['Importação dos CSVs','Preparação de dados','UTF-8 com BOM; separador ponto e vírgula','Importar CNPJ, CEP e telefone como TEXTO para preservar zeros à esquerda.'],
['Membros ausentes do site','Pendente de lista nominal','Conciliar 98 informados com 96 fichas','A diferença de 2 não prova que sejam exatamente dois ausentes: podem existir desatualizações.']
];
mapping.getRange('A5:D21').values=[['Campo / etapa','Exigência atual','Origem / tratamento','Regra e limite'],...maps];
mapping.getRange('A5:D5').format={fill:ink,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:32};
mapping.getRange('A6:D21').format.wrapText=true;mapping.getRange('A6:D21').format.rowHeight=62;
mapping.getRange('A5:A29').format.columnWidth=32;mapping.getRange('B5:B29').format.columnWidth=26;mapping.getRange('C5:C29').format.columnWidth=57;mapping.getRange('D5:D29').format.columnWidth=82;
mapping.getRange('A23').values=[['Fontes do mapeamento no repositório Business']];mapping.getRange('A23').format.font.bold=true;
mapping.getRange('A24').values=[['cadastro/includes/form.cfm:26–144; cadastro/includes/backend.cfm:10–25 e 101–154']];
mapping.getRange('A25').values=[['_codex/sql/2026-06-09_tb_conta_cadastro_solicitacoes.sql:18–42']];
mapping.getRange('A26').values=[['estudos/index.cfm:20–22; fluxo de convite nominal do estudo']];
mapping.getRange('A28').values=[['Pesquisa inicial: os dados cadastrais vêm da BrasilAPI e de diretórios públicos citados por registro.']];
mapping.getRange('A29').values=[['A situação cadastral é a retornada pela fonte consultada; confirmar novamente antes de criar a conta.']];
mapping.freezePanes.freezeRows(5);

const rc=[['id_filiado','ID filiado',27],['nome_abraceo','Filiado',31],['cnpj_anterior','CNPJ anterior',22,'@'],['cnpj_revisado','CNPJ revisado',22,'@'],['situacao','Situação cadastral',17],['resultado','Resultado da revisão',27],['decisao','Decisão e evidência',78],['pendencia','Confirmação ainda necessária',64],['fonte_decisao','Fonte da decisão',70],['fonte_auxiliar','Fonte complementar',65],['fonte_cadastral','Fonte cadastral',60],['revisado_em','Revisado em',16]];
setup(reviewed,'Revisão dos CNPJs prioritários','20 casos revisados. Alternativas preservadas na aba Pessoas jurídicas; cada seleção tem fonte e ressalva.',col(rc.length-1),5+data.revisoes.length);
table(reviewed,rc,data.revisoes,'RevisaoCnpjTabela');
reviewed.getRange(`F6:F${5+data.revisoes.length}`).conditionalFormats.add('containsText',{text:'AGUARDA',format:{fill:amber,font:{color:'#805600'}}});
const dc=[['id_filiado','ID filiado',28],['nome_empresa','Nome da conta sugerido',32],['documento','CNPJ para pré-preenchimento',22,'@'],['tipo_titular','Tipo titular',13],['tipo_prestador','Tipo Business sugerido',21],['razao_social','Razão social',48],['nome_fantasia','Nome fantasia cadastral',35],['cidade','Cidade operacional',26],['estado','UF',8],['site','Site / perfil',48],['contato_publico','Contato público',32],['email_publico','E-mail comercial público',43],['telefone_publico','Telefone público normalizado',24,'@'],['logo_arquivo','Arquivo do logo',46],['fonte_cnpj','Fonte do CNPJ',70],['status_importacao','Estado da importação',32]];
setup(drafts,'Lote de novos rascunhos para pré-cadastro',`${data.pre_cadastro.length} registros após cruzamento com produção. Reconferir duplicidade ao criar; responsável virá do login.`,col(dc.length-1),5+data.pre_cadastro.length);
table(drafts,dc,data.pre_cadastro,'PreCadastroTabela');

const bc=[['id_filiado','ID filiado',28],['nome_abraceo','Filiado',31],['conta_business','Resultado da busca de conta',34],['id_conta','ID conta',16,'@'],['acao','Próxima ação',32],['eventos_total','Eventos no catálogo',18,'0'],['eventos_ja_vinculados','Já vinculados à conta',19,'0'],['eventos_por_confirmar','Relações por confirmar',20,'0'],['eventos_futuros','Futuros ou em curso',19,'0'],['eventos_fontes_externas','Relações em fontes externas',21,'0'],['fornecedores','IDs fornecedores',21,'@'],['logo','Arquivo do logo',45],['observacao','Observação',70],['consultado_em','Consulta de produção',32]];
setup(business,'Contas, eventos e logotipos por filiado','96 filiados. Não localizada significa ausência de correspondência nesta consulta, não inexistência definitiva.',col(bc.length-1),101);
table(business,bc,data.cruzamento,'CruzamentoBusinessTabela');
business.getRange('C6:C101').conditionalFormats.add('containsText',{text:'OUTRO CNPJ',format:{fill:amber,font:{color:'#805600'}}});
const ac=[['nome_abraceo','Filiado',29],['id_conta','ID conta',12,'@'],['nome_conta','Conta Business',26],['cnpj_conta','CNPJ da conta',23,'@'],['cnpj_pesquisado','CNPJ pesquisado',23,'@'],['correspondencia','Correspondência',31],['status_conta','Status conta',17],['usuarios_ativos','Usuários ativos',18,'0'],['eventos_vinculados','Vínculos ativos de eventos',21,'0'],['acao','Ação recomendada',63],['evidencia','Evidência',72],['fonte','Fonte interna',60],['fonte_publica','Fonte ABRACEO',65],['fonte_complementar','Fonte complementar',75],['consultado_em','Consultado em',32]];
setup(accounts,'Contas já existentes','Cinco correspondências por CNPJ e uma conta MP3 com outro CNPJ. Não criar duplicatas sem conferir.',col(ac.length-1),11);
table(accounts,ac,data.contas,'ContasExistentesTabela');
const ec=[['nome_abraceo','Filiado',30],['id_evento','ID evento',14,'0'],['nome_evento','Evento',55],['data_inicial','Data inicial',18,'dd/mm/yyyy'],['periodo','Período',22],['classificacao','Evidência principal',38],['papel','Papel informado',30],['cidade','Cidade',26],['uf','UF',8],['evento_ativo','Ativo no catálogo',18],['id_conta_filiado','Conta do filiado vinculada',24,'@'],['outras_contas_ativas','Outras contas ativas',23,'@'],['id_fornecedor','ID fornecedor',18,'@'],['evidencia','Detalhe da evidência',100],['ressalvas','Ressalvas',90],['acao','Próxima ação',77],['url_evento','Página pública do evento',80],['url_business','Evento no Business',70],['url_inscricao','Inscrição',80],['url_regulamento','Regulamento',80],['id_filiado','ID filiado',29],['fonte','Fonte interna',95],['consultado_em','Consultado em',32]];
setup(events,'Eventos relacionados aos filiados',`${bs.eventos_distintos} eventos distintos; ${bs.relacoes} relações. Indícios por nome/site exigem confirmação; datas preservadas do catálogo.`,col(ec.length-1),data.eventos.length+5);
table(events,ec,data.eventos,'EventosRelacionadosTabela');
events.getRange(`A6:${col(ec.length-1)}${data.eventos.length+5}`).format.rowHeight=64;
events.getRange(`F6:F${data.eventos.length+5}`).conditionalFormats.add('containsText',{text:'SITE RELACIONADO',format:{fill:amber,font:{color:'#805600'}}});
const xc=[['nome_abraceo','Filiado',29],['nome_evento','Evento',55],['data','Data',18,'dd/mm/yyyy'],['cidade','Cidade',31],['uf','UF',8],['papel','Papel',35],['id_evento_business','ID no catálogo',18,'0'],['status','Resultado',48],['evidencia','Evidência',85],['observacao','Ressalva',90],['fonte','Fonte pública',90],['consultado_em','Consultado em',20]];
setup(external,'Eventos encontrados em fontes externas','Registros complementares. Corrida do After aparece duas vezes por envolver dois filiados; a Corrida do Leão já existe no catálogo.',col(xc.length-1),15);
table(external,xc,data.eventos_externos,'EventosExternosTabela');

wb.recalculate();
const inspection=await wb.inspect({kind:'table',range:'Resumo!A6:C20',include:'values,formulas',tableMaxRows:15,tableMaxCols:3,maxChars:7000});
await fs.writeFile(path.join(root,'research/inspection.txt'),inspection.ndjson);
console.log(inspection.ndjson);
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:100},summary:'Final formula error scan'});
console.log(errors.ndjson);
for(const [sheetName,range,key] of [['Resumo','A1:C36','resumo'],['Filiados','A1:H10','filiados'],['Pré-cadastro','A1:H10','rascunhos'],['Cruzamento Business','A1:H10','business'],['Contas existentes','A1:I11','contas'],['Eventos','A1:G10','eventos'],['Eventos externos','A1:H10','externos']]){
 const blob=await wb.render({sheetName,range,scale:1.5,format:'png'});
 await fs.writeFile(path.join(root,`research/preview-${key}.png`),new Uint8Array(await blob.arrayBuffer()));
}
const xlsx=await SpreadsheetFile.exportXlsx(wb);await xlsx.save(path.join(root,'abraceo_pre_cadastro.xlsx'));
console.log('Exportado: abraceo_pre_cadastro.xlsx');
