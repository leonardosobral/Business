<cfinclude template="_admin.cfm"/>
<cfscript>
centralDocuments={
    'resumo':'brasil-que-corre-provas-guia-rapido-q3.pdf',
    'execucao-v3':'brasil-que-corre-provas-lancamento-q3-execucao-v3.pdf',
    'conselho-v2':'brasil-que-corre-provas-proposta-visual-conselho-v2.pdf',
    'conselho-v1':'brasil-que-corre-provas-proposta-visual-conselho-v1.pdf',
    'estrategia-inicial':'brasil-que-corre-provas-estrategia-comercial-2026.pdf'
};
centralDocument=structKeyExists(URL,'doc')?URL.doc:'';
if(!structKeyExists(centralDocuments,centralDocument)) {cfheader(statuscode=404);writeOutput('Documento não encontrado.');abort;}
centralFilename=centralDocuments[centralDocument];
centralPath=expandPath('./arquivos/' & centralFilename);
if(!fileExists(centralPath)) {cfheader(statuscode=404);writeOutput('Documento indisponível.');abort;}
</cfscript>
<cfheader name="Content-Disposition" value='inline; filename="#centralFilename#"'/>
<cfcontent type="application/pdf" file="#centralPath#" reset="true"/>
<cfabort/>
