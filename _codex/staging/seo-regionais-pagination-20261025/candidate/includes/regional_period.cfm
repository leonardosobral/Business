<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
VARIABLES.regionalPeriodUrl=function(required date startDate,required date endDate){
    var parts=[];
    for(var part in VARIABLES.regionalFilterParts) if(!listFindNoCase("tempo,periodo_inicio,periodo_fim",listFirst(part,"=")))arrayAppend(parts,part);
    arrayAppend(parts,"periodo_inicio=" & dateFormat(arguments.startDate,"yyyy-mm-dd"));arrayAppend(parts,"periodo_fim=" & dateFormat(arguments.endDate,"yyyy-mm-dd"));
    return VARIABLES.regionalPath & "?" & arrayToList(parts,"&");
};
VARIABLES.regionalWeekend = dateAdd("d",dayOfWeek(VARIABLES.regionalToday) EQ 1 ? 0 : 7-dayOfWeek(VARIABLES.regionalToday),VARIABLES.regionalToday);
VARIABLES.regionalWeekendEnd = dateAdd("d",dayOfWeek(VARIABLES.regionalToday) EQ 1 ? 0 : 1,VARIABLES.regionalWeekend);
VARIABLES.regionalNextMonth = dateAdd("m",1,createDate(year(VARIABLES.regionalToday),month(VARIABLES.regionalToday),1));
VARIABLES.regionalPresets = [
    {label="Neste fim de semana",first=VARIABLES.regionalWeekend,last=VARIABLES.regionalWeekendEnd},
    {label="Até o fim do mês",first=VARIABLES.regionalToday,last=createDate(year(VARIABLES.regionalToday),month(VARIABLES.regionalToday),daysInMonth(VARIABLES.regionalToday))},
    {label="Próximo mês",first=VARIABLES.regionalNextMonth,last=dateAdd("d",-1,dateAdd("m",1,VARIABLES.regionalNextMonth))},
    {label=toString(year(VARIABLES.regionalToday)+1),first=createDate(year(VARIABLES.regionalToday)+1,1,1),last=createDate(year(VARIABLES.regionalToday)+1,12,31)}
];
</cfscript>
<cfoutput>
<details class="rr-regional-period-picker"><summary>Escolher período</summary>
    <nav class="rr-regional-shortcuts" aria-label="Períodos do calendário">
    <cfloop array="#VARIABLES.regionalPresets#" index="regionalPreset"><a data-regional-period-link href="#encodeForHTMLAttribute(VARIABLES.regionalPeriodUrl(regionalPreset.first,regionalPreset.last))#">#encodeForHTML(regionalPreset.label)#</a></cfloop>
    </nav>
    <form action="#encodeForHTMLAttribute(VARIABLES.regionalPath)#" method="get" data-regional-period-form>
        <cfloop list="distancia,rua,trail,nacional,internacional,cupom,badges" index="regionalFormKey"><input type="hidden" name="#regionalFormKey#" value="#encodeForHTMLAttribute(URL[regionalFormKey])#"/></cfloop>
        <div class="rr-regional-date-fields">
            <div><label for="regional-date-from">De</label><input id="regional-date-from" type="date" name="periodo_inicio" min="#dateFormat(VARIABLES.regionalToday,'yyyy-mm-dd')#" value="#dateFormat(VARIABLES.regionalFrom,'yyyy-mm-dd')#" required/></div>
            <div><label for="regional-date-to">Até</label><input id="regional-date-to" type="date" name="periodo_fim" min="#dateFormat(VARIABLES.regionalToday,'yyyy-mm-dd')#" value="#dateFormat(VARIABLES.regionalTo,'yyyy-mm-dd')#" required/></div>
        </div>
        <p>Datas inclusivas, no horário de Brasília. Mostra provas que acontecem no período, inclusive eventos de mais de um dia.</p>
        <button type="submit">Aplicar período</button>
    </form>
</details>
</cfoutput>
