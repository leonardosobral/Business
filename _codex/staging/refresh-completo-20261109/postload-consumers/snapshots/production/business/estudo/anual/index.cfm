<cfinclude template="_guard.cfm"/>
<cfif NOT structKeyExists(URL,'ano')><cflocation url="/estudo/anual/?ano=2026" addtoken="false"/></cfif>
<cfscript>
html=fileRead(expandPath('../../estudos/leitor/pagina.html'),'utf-8');
html=replace(html,'<body data-endpoint="dados.cfm">','<body data-endpoint="/estudo/anual/dados.cfm" data-annual-draft="true"><aside class="annual-draft-banner"><strong>ANUAL 2026 · RASCUNHO INTERNO</strong><span>Base disponível: Jan–Set. Temas em revisão; não divulgar como fechamento anual.</span><a href="/estudo/">Notebook e fontes →</a></aside>');
html=replace(html,'<option value="2025">Edição 2025 · prévia</option>','');
html=replace(html,'<a href="##edicao-anual">Edição anual</a>','<a href="##plano-anual">Pendências</a><a href="##inscricoes-geral">Inscrições</a><a href="##faixas">CNA</a>');
for(asset in ['estudo.css','parcial.js','estudo.js']) html=replace(html,'"' & asset & '"','"' & asset & '?v=edicoes-20261010-1"','all');
for(asset in ['estudo.css','dados.js','graficos.js','parcial.js','estudo.js','navegacao.js']) html=replace(html,'"' & asset,'"/estudos/leitor/' & asset,'all');
html=replace(html,'"assets/','"/estudos/leitor/assets/','all');
writeOutput(html);
</cfscript>