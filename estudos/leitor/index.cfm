<cfinclude template="../_context.cfm"/>
<cfif NOT studyActor><cflocation url="/estudos/" addtoken="false"/></cfif>
<cftry>
    <cfset studyAccess=studyService.read(studyActor,'previa-2026-q3')/>
    <cfcatch><cflocation url="/estudos/" addtoken="false"/></cfcatch>
</cftry>
<cfif NOT structKeyExists(URL,'ano') OR URL.ano NEQ '2026'><cflocation url="/estudos/leitor/?ano=2026" addtoken="false"/></cfif>
<cfscript>
html=fileRead(expandPath('./pagina.html'),'utf-8');
html=replace(html,'<title>O Brasil que Corre Provas · Estudo</title>','<title>Brasil que Corre Provas · Jan–Set 2026 · Business</title>');
html=replace(html,'<option value="2025">Edição 2025 · prévia</option>','');
html=replace(html,'<body data-endpoint="dados.cfm">','<body data-endpoint="dados.cfm"><div class="reader-access"><a href="/estudos/">← Minha biblioteca</a><span>Prévia profissional · Janeiro–setembro de 2026 · Acesso pessoal</span></div>');
html=replace(html,'<div class="hero-footnote">EDIÇÃO DIGITAL <span>•</span> PRÉVIA EM CONSTRUÇÃO</div>','<div class="hero-footnote">EDIÇÃO DIGITAL <span>•</span> PRÉVIA PROFISSIONAL POR CONVITE</div>');
// Version presentation files together with the curated JSON contract.
for(asset in ['estudo.css','dados.js','parcial.js','estudo.js']) html=replace(html,'"' & asset & '"','"' & asset & '?v=q3-20261010-fechamento2"','all');
html=replace(html,'</head>','<style>.reader-access{background:##ffcb05;color:##242424;padding:12px 5%;display:flex;gap:20px;justify-content:space-between;font:600 14px Poppins,sans-serif}.reader-access a{color:inherit} .hero-footnote{font-size:13px} @media(max-width:600px){.reader-access{flex-wrap:wrap;font-size:12px}}</style></head>');
writeOutput(html);
</cfscript>
