<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
VARIABLES.postRace={enabled=false,results=false,resultSource="",galleries=[],nextEdition={},calendar="",dateLabel=""};
VARIABLES.postRaceEnd=isDate(qEvento.data_final[1]) ? qEvento.data_final[1] : qEvento.data_inicial[1];
// Wait for the whole event's last calendar day, including multi-day races.
VARIABLES.postRace.enabled=isDate(VARIABLES.postRaceEnd) && dateCompare(VARIABLES.postRaceEnd,now(),"d") LT 0
    && !listFindNoCase("cancelado,adiado",trim(qEvento.status_evento[1] & ""));
VARIABLES.postRaceLabels={
 "pt-br"={heading="Pós-prova: resultados e fotos",results="Ver resultados no OpenResults",source="Consultar fonte de resultados cadastrada",missing="Ainda não há resultados importados nem link de resultados cadastrado para esta prova.",photos="Ver fotos da prova",photosMissing="Não há galeria de fotos vinculada a esta prova.",next="Próxima edição cadastrada",details="Ver a próxima edição",noNext="Ainda não há próxima edição neste histórico.",calendar="Encontrar outras corridas na cidade",note="A disponibilidade e eventuais atualizações dos materiais dependem dos responsáveis pela publicação.",intro="Prova de",meta="Consulte os resultados e as fotos disponíveis nesta ficha."},
 en={heading="After the race: results and photos",results="View results on OpenResults",source="View the registered results source",missing="No imported results or results link is registered for this race yet.",photos="View race photos",photosMissing="No photo gallery is linked to this race.",next="Next registered edition",details="View the next edition",noNext="No next edition is registered in this history yet.",calendar="Find more races in this city",note="Availability and updates depend on the publishers responsible for these materials.",intro="Race dated",meta="Check the results and photos available on this event page."},
 es={heading="Después de la carrera: resultados y fotos",results="Ver resultados en OpenResults",source="Consultar la fuente de resultados registrada",missing="Todavía no hay resultados importados ni un enlace de resultados registrado para esta carrera.",photos="Ver fotos de la carrera",photosMissing="No hay una galería de fotos vinculada a esta carrera.",next="Próxima edición registrada",details="Ver la próxima edición",noNext="Todavía no hay una próxima edición en este historial.",calendar="Encontrar otras carreras en esta ciudad",note="La disponibilidad y las actualizaciones dependen de los responsables de publicar estos materiales.",intro="Carrera del",meta="Consulte los resultados y las fotos disponibles en esta ficha."}
};
VARIABLES.postRaceLang=structKeyExists(REQUEST,"lang") ? lCase(REQUEST.lang) : "pt-br";
if (!structKeyExists(VARIABLES.postRaceLabels,VARIABLES.postRaceLang)) VARIABLES.postRaceLang="pt-br";
VARIABLES.postRaceText=VARIABLES.postRaceLabels[VARIABLES.postRaceLang];
</cfscript>
<cfif VARIABLES.postRace.enabled>
    <!--- Boolean only: never load names or individual result URLs for SEO. --->
    <cfquery name="qPostRacePublicResults" cachedwithin="#createTimeSpan(0,0,1,0)#" timeout="5">
        SELECT EXISTS(SELECT 1 FROM tb_resultados
            WHERE id_evento=<cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento[1]#"/>
              AND origem_resultado='oficial' AND homologado=true
              AND coalesce(concluinte,true)=true AND coalesce(status_final,0)=0) AS available
    </cfquery>
    <cfscript>
    VARIABLES.postRace.results=qPostRacePublicResults.available[1];
    // Only the public source URL; url_wiclax can point to a raw import file.
    VARIABLES.postRaceSource=trim(qEvento.url_resultado[1] & "");
    if (reFindNoCase('^https?://[^\s<>"' & chr(39) & ']+$',VARIABLES.postRaceSource)) VARIABLES.postRace.resultSource=VARIABLES.postRaceSource;
    VARIABLES.postRace.dateLabel=dateFormat(qEvento.data_inicial[1],"dd/mm/yyyy");
    if (dateCompare(VARIABLES.postRaceEnd,qEvento.data_inicial[1],"d") GT 0) VARIABLES.postRace.dateLabel &= " – " & dateFormat(VARIABLES.postRaceEnd,"dd/mm/yyyy");
    VARIABLES.postRaceSeen={};
    for (VARIABLES.postRaceGallery in VARIABLES.eventFocoGalleries) {
        VARIABLES.postRaceGalleryUrl=trim(VARIABLES.postRaceGallery.url & "");
        if (!reFindNoCase('^https://(www\.)?focoradical\.com\.br/(prova/[^\s<>"' & chr(39) & ']+|busca-numero\?[^\s<>"' & chr(39) & ']*competition_id=[^\s<>"' & chr(39) & ']+)$',VARIABLES.postRaceGalleryUrl)) continue;
        if (structKeyExists(VARIABLES.postRaceSeen,VARIABLES.postRaceGalleryUrl)) continue;
        VARIABLES.postRaceSeen[VARIABLES.postRaceGalleryUrl]=true;
        arrayAppend(VARIABLES.postRace.galleries,VARIABLES.postRaceGallery);
    }
    VARIABLES.postRacePrefix=VARIABLES.postRaceLang=="en" ? "/en/event/" : (VARIABLES.postRaceLang=="es" ? "/es/evento/" : "/evento/");
    // A circuit's next stop is not the next edition of this race.
    if (qAgrega.recordCount && qAgrega.tipo_agregacao[1]=="maratona" && val(qEvento.id_agrega_evento[1]) GT 0) {
        for (VARIABLES.postRaceEdition in qEventoEdicoes) {
            if (val(VARIABLES.postRaceEdition.id_agrega_evento)!=val(qEvento.id_agrega_evento[1])
                || !isDate(VARIABLES.postRaceEdition.data_inicial) || dateCompare(VARIABLES.postRaceEdition.data_inicial,now(),"d") LT 0
                || listFindNoCase("cancelado,adiado",trim(VARIABLES.postRaceEdition.status_evento & ""))
                || !len(trim(VARIABLES.postRaceEdition.tag & ""))) continue;
            if (structIsEmpty(VARIABLES.postRace.nextEdition) || dateCompare(VARIABLES.postRaceEdition.data_inicial,VARIABLES.postRace.nextEdition.start) LT 0) {
                VARIABLES.postRace.nextEdition={name=VARIABLES.postRaceEdition.nome_evento & "",start=VARIABLES.postRaceEdition.data_inicial,
                    dateLabel=dateFormat(VARIABLES.postRaceEdition.data_inicial,"dd/mm/yyyy"),
                    path=VARIABLES.postRacePrefix & replace(encodeForURL(VARIABLES.postRaceEdition.tag),"+","%20","all") & "/"};
                if (isDate(VARIABLES.postRaceEdition.data_final) && dateCompare(VARIABLES.postRaceEdition.data_final,VARIABLES.postRaceEdition.data_inicial,"d") GT 0)
                    VARIABLES.postRace.nextEdition.dateLabel &= " – " & dateFormat(VARIABLES.postRaceEdition.data_final,"dd/mm/yyyy");
            }
        }
    }
    if (compareNoCase(trim(qEvento.pais[1] & ""),"BR")==0
        && listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",qEvento.estado[1] & "")
        && reFind("^[a-z0-9-]+$",qEvento.tag_cidade[1] & "")) VARIABLES.postRace.calendar="/estado/" & lCase(qEvento.estado[1]) & "/" & qEvento.tag_cidade[1] & "/";
    </cfscript>
</cfif>
