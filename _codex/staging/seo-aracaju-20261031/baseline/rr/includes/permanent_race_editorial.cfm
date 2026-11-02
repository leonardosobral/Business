<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
// Edition-specific facts expire when the selected edition/date changes.
VARIABLES.raceEditorials={
 "maratona-internacional-de-floripa"={tag="2027-maratona-internacional-de-floripa-fibra-2027",start="2027-08-28",finish="2027-08-29",year="2027",source="https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88278/981d4d32a3fa41f499ed30cd8878329c639251782889640084.pdf",items=["A meia maratona está programada para 28/08; a maratona e os 5 km, para 29/08.","A base de largada e chegada fica na Praça Sesquicentenário, na Avenida Beira-Mar Norte, em Florianópolis.","A inscrição e a participação nos desafios têm condições próprias. Confira a modalidade escolhida e as atualizações do organizador."]},
 "maratona-de-curitiba"={tag="2026-maratona-de-curitiba-santander-2026",start="2026-11-15",finish="2026-11-15",year="2026",source="https://maratonadecuritiba.com.br/",items=["A edição de 15/11 oferece 5 km, 10 km, meia maratona e maratona, com largada na Praça Nossa Senhora de Salete.","A Expo e a retirada de kits estão previstas para 12 a 14/11, no Museu Oscar Niemeyer.","Horários, disponibilidade de vagas e condições de inscrição devem ser conferidos na página oficial e no regulamento da edição."]},
 "maratona-monumental-de-brasilia"={tag="2026-maratona-monumental-de-brasilia-2026",start="2026-11-21",finish="2026-11-22",year="2026",source="https://maratonamonumentalbsb.com.br/wp-content/uploads/2026/07/v6-REGULAMENTO-MARATONA-MONUMENTAL-2026.pdf",items=["Os 5 km e 10 km estão programados para 21/11 às 17h; a maratona para 22/11 às 5h e a meia maratona às 6h.","A base da prova fica na Esplanada dos Ministérios, em Brasília.","A retirada de kits é separada da programação de largadas. Consulte o regulamento para locais, horários, pelotões e atividades infantis."]}
};
VARIABLES.raceEditorialKey=qAgrega.tag & "";
VARIABLES.raceEditorialShow=false;
if (structKeyExists(VARIABLES.raceEditorials,VARIABLES.raceEditorialKey) && !structIsEmpty(VARIABLES.permanentNext)) {
    VARIABLES.raceEditorial=VARIABLES.raceEditorials[VARIABLES.raceEditorialKey];
    VARIABLES.raceEditorialShow=VARIABLES.permanentNext.tag==VARIABLES.raceEditorial.tag
        && dateFormat(VARIABLES.permanentNext.start,"yyyy-mm-dd")==VARIABLES.raceEditorial.start
        && isDate(VARIABLES.permanentNext.finish) && dateFormat(VARIABLES.permanentNext.finish,"yyyy-mm-dd")==VARIABLES.raceEditorial.finish;
}
</cfscript>
<cfif VARIABLES.raceEditorialShow><cfoutput>
<details class="rr-race-details" data-race-editorial>
    <summary>Informações para correr a edição #VARIABLES.raceEditorial.year#</summary>
    <ul class="rr-race-links"><cfloop array="#VARIABLES.raceEditorial.items#" index="raceEditorialItem"><li>#encodeForHTML(raceEditorialItem)#</li></cfloop></ul>
    <p class="rr-race-note">Fonte: <a href="#encodeForHTMLAttribute(VARIABLES.raceEditorial.source)#" target="_blank" rel="noopener">organizador / regulamento oficial</a>. Conferido em 30/10/2026. A programação pode ser atualizada pela organização.</p>
</details>
</cfoutput></cfif>
