<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
// Reuse the editions rendered by the page; never infer an edition or a date.
VARIABLES.permanentNext = {};
VARIABLES.permanentLast = {};
VARIABLES.permanentPlaces = [];
VARIABLES.permanentSeen = {};
VARIABLES.permanentItems = [];
for (VARIABLES.permanentSource in [qEventosAba2,qEventosAba7]) {
    for (VARIABLES.permanentRow=1; VARIABLES.permanentRow LTE VARIABLES.permanentSource.recordCount; VARIABLES.permanentRow++) {
        VARIABLES.permanentEvent = {name=VARIABLES.permanentSource.nome_evento[VARIABLES.permanentRow] & "",
            tag=VARIABLES.permanentSource.tag[VARIABLES.permanentRow] & "",
            city=trim(VARIABLES.permanentSource.cidade[VARIABLES.permanentRow] & ""),
            uf=uCase(trim(VARIABLES.permanentSource.estado[VARIABLES.permanentRow] & "")),
            cityTag=VARIABLES.permanentSource.tag_cidade[VARIABLES.permanentRow] & "",
            start=VARIABLES.permanentSource.data_inicial[VARIABLES.permanentRow],
            finish=VARIABLES.permanentSource.data_final[VARIABLES.permanentRow]};
        if (!len(trim(VARIABLES.permanentEvent.tag)) || !isDate(VARIABLES.permanentEvent.start)) continue;
        VARIABLES.permanentEvent.path="/evento/" & replace(encodeForURL(VARIABLES.permanentEvent.tag),"+","%20","all") & "/";
        VARIABLES.permanentEvent.dateLabel=dateFormat(VARIABLES.permanentEvent.start,"dd/mm/yyyy");
        if (isDate(VARIABLES.permanentEvent.finish) && dateCompare(VARIABLES.permanentEvent.finish,VARIABLES.permanentEvent.start,"d") GT 0)
            VARIABLES.permanentEvent.dateLabel &= " a " & dateFormat(VARIABLES.permanentEvent.finish,"dd/mm/yyyy");
        VARIABLES.permanentEnd=isDate(VARIABLES.permanentEvent.finish) ? VARIABLES.permanentEvent.finish : VARIABLES.permanentEvent.start;
        if (dateCompare(VARIABLES.permanentEnd,now(),"d") GTE 0 && structIsEmpty(VARIABLES.permanentNext)) VARIABLES.permanentNext=duplicate(VARIABLES.permanentEvent);
        if (dateCompare(VARIABLES.permanentEnd,now(),"d") LT 0 && structIsEmpty(VARIABLES.permanentLast)) VARIABLES.permanentLast=duplicate(VARIABLES.permanentEvent);
        if (arrayLen(VARIABLES.permanentItems) LT 25) arrayAppend(VARIABLES.permanentItems,{"@type"="ListItem",position=arrayLen(VARIABLES.permanentItems)+1,name=VARIABLES.permanentEvent.name,url=APPLICATION.baseCanonica & VARIABLES.permanentEvent.path});
        if (listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",VARIABLES.permanentEvent.uf)
            && compareNoCase(trim(VARIABLES.permanentSource.pais[VARIABLES.permanentRow] & ""),"BR") EQ 0
            && reFind("^[a-z0-9-]+$",VARIABLES.permanentEvent.cityTag) && len(VARIABLES.permanentEvent.city)) {
            VARIABLES.permanentPlaceKey=VARIABLES.permanentEvent.uf & "/" & VARIABLES.permanentEvent.cityTag;
            if (!structKeyExists(VARIABLES.permanentSeen,VARIABLES.permanentPlaceKey) && arrayLen(VARIABLES.permanentPlaces) LT 8) {
                VARIABLES.permanentSeen[VARIABLES.permanentPlaceKey]=true;
                arrayAppend(VARIABLES.permanentPlaces,{name=VARIABLES.permanentEvent.city & " (" & VARIABLES.permanentEvent.uf & ")",path="/estado/" & lCase(VARIABLES.permanentPlaceKey) & "/",statePath="/estado/" & lCase(VARIABLES.permanentEvent.uf) & "/",stateName=VARIABLES.permanentEvent.uf});
            }
        }
    }
}
VARIABLES.permanentDescription=qAgrega.nome_evento_agregado & ": consulte próximas edições, datas, informações de inscrição e histórico de resultados no Road Runners.";
if (!structIsEmpty(VARIABLES.permanentNext)) VARIABLES.permanentDescription=qAgrega.nome_evento_agregado & ": próxima edição cadastrada em " & VARIABLES.permanentNext.dateLabel & ". Confira informações de inscrição e edições anteriores.";
VARIABLES.permanentJson=serializeJSON({"@context"="https://schema.org","@type"="CollectionPage",name=qAgrega.nome_evento_agregado & " — edições e resultados",url=APPLICATION.baseCanonica & "/maratona/" & URL.tag & "/",description=VARIABLES.permanentDescription,mainEntity={"@type"="ItemList",itemListElement=VARIABLES.permanentItems}});
</cfscript>
