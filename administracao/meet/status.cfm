<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfinclude template="includes/service.cfm"/>
<cfscript>
function meetRoomReply(required struct payload, numeric status=200) {
    cfheader(statuscode=arguments.status);
    cfheader(name="Cache-Control", value="no-store");
    cfheader(name="X-Content-Type-Options", value="nosniff");
    cfcontent(type="application/json; charset=utf-8", reset=true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

statusMeetingUri = "";
try {
    if (CGI.request_method != "GET") {
        cfheader(name="Allow", value="GET");
        meetRoomReply({"success"=false, "message"="Método não permitido."}, 405);
    }

    config = meetRoomConfig();
    statusMeetingUri = config.meetingUri;
    if (!config.configured) {
        meetRoomReply({
            "success"=true,
            "configured"=false,
            "connected"=false,
            "active"=false,
            "participantCount"=0,
            "participants"=[],
            "meetingUri"="",
            "message"="Configure RR_GOOGLE_MEET_ROOM no servidor."
        });
    }

    if (!agendaReady()) {
        meetRoomReply({
            "success"=true,
            "configured"=true,
            "connected"=false,
            "active"=false,
            "participantCount"=0,
            "participants"=[],
            "meetingUri"=config.meetingUri,
            "message"="Aplique o schema da Agenda Google e conecte a conta."
        });
    }

    connection = agendaDb("SELECT email FROM public.tb_google_agenda_conexao WHERE id=1");
    if (!connection.recordCount) {
        meetRoomReply({
            "success"=true,
            "configured"=true,
            "connected"=false,
            "active"=false,
            "participantCount"=0,
            "participants"=[],
            "meetingUri"=config.meetingUri,
            "message"="Conecte a conta em Agenda Google."
        });
    }

    result = meetRoomCachedStatus();
    result["success"] = true;
    meetRoomReply(result);
} catch (any error) {
    knownError = listFindNoCase("Agenda.Validation,MeetRoom.Validation", error.type) GT 0;
    meetRoomReply({
        "success"=false,
        "meetingUri"=statusMeetingUri,
        "message"=knownError ? error.message : "Não foi possível atualizar a presença no Google Meet."
    }, knownError ? 400 : 502);
}
</cfscript>
