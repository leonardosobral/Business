<cfinclude template="_admin.cfm"/>
<cfscript>
centralDocuments={
    'maratonas-idades':'maratonas-auditoria-idades.csv',
    'maratonas-completo':'maratonas-brasil-estudo-detalhado-2025-2026.pdf',
    'maratonas-indicadores':'maratonas-indicadores-completos.csv',
    'maratonas-2025':'maratonas-selecao-2025.csv',
    'maratonas-2026':'maratonas-selecao-2026.csv',
    'maratonas-pares':'maratonas-pares-2025-2026.csv',
    'distancias-2025':'corridas-distancias-2025.csv',

    'maratonas-piloto':'maratonas-brasil-gigante-2025-previa-2026.pdf',
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
<cfif listLast(centralFilename,".") EQ "csv"><cfcontent type="text/csv; charset=utf-8" file="#centralPath#" reset="true"/><cfelse><cfcontent type="application/pdf" file="#centralPath#" reset="true"/></cfif>
<cfabort/>
