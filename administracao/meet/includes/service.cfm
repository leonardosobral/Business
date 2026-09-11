<cfscript>
function meetRoomFail(required string message) {
    throw(type="MeetRoom.Validation", message=arguments.message);
}

function meetRoomConfig() {
    if (!structKeyExists(application, "googleMeet") || !isStruct(application.googleMeet)) {
        return {"configured"=false, "meetingCode"="", "meetingUri"="", "cacheSeconds"=15};
    }

    var configuredRoom = structKeyExists(application.googleMeet, "room")
        ? trim(application.googleMeet.room & "")
        : "";
    var cacheSeconds = structKeyExists(application.googleMeet, "cacheSeconds")
        ? min(60, max(5, int(val(application.googleMeet.cacheSeconds))))
        : 15;
    if (!len(configuredRoom)) {
        return {"configured"=false, "meetingCode"="", "meetingUri"="", "cacheSeconds"=cacheSeconds};
    }

    configuredRoom = reReplaceNoCase(configuredRoom, "^https://meet\.google\.com/", "", "one");
    configuredRoom = listFirst(configuredRoom, "?##");
    configuredRoom = reReplace(configuredRoom, "/+$", "", "one");
    configuredRoom = lCase(trim(configuredRoom));
    if (len(configuredRoom) GT 128 || !reFind("^[a-z]+-[a-z]+-[a-z]+$", configuredRoom)) {
        meetRoomFail("Configure RR_GOOGLE_MEET_ROOM com um link https://meet.google.com válido.");
    }

    return {
        "configured"=true,
        "meetingCode"=configuredRoom,
        "meetingUri"="https://meet.google.com/" & configuredRoom,
        "cacheSeconds"=cacheSeconds
    };
}

function meetRoomGoogle(required string path, struct params={}) {
    if (!reFind("^/(spaces/[a-z-]+|conferenceRecords/[A-Za-z0-9_-]+/participants)$", arguments.path)) {
        meetRoomFail("Recurso do Google Meet inválido.");
    }

    var endpoint = "https://meet.googleapis.com/v2" & arguments.path;
    var response = agendaHttp(endpoint, "GET", arguments.params, {}, agendaAccessToken());
    if (response.status == 401) {
        response = agendaHttp(endpoint, "GET", arguments.params, {}, agendaAccessToken(true));
    }
    var googleDetail = "";
    if (isStruct(response.data) && structKeyExists(response.data, "error") && isStruct(response.data.error)
        && structKeyExists(response.data.error, "message") && len(trim(response.data.error.message & ""))) {
        googleDetail = trim(reReplace(response.data.error.message & "", "[\r\n\t]+", " ", "all"));
        if (len(googleDetail) GT 300) googleDetail = left(googleDetail, 300);
        googleDetail = " Detalhe do Google: " & googleDetail;
    }
    if (response.status == 400 && left(arguments.path, 8) == "/spaces/") meetRoomFail("O Google Meet recusou o código da sala configurada." & googleDetail);
    if (response.status == 400) meetRoomFail("O Google Meet recusou a consulta dos participantes." & googleDetail);
    if (response.status == 401) meetRoomFail("A conexão Google expirou. Reconecte a conta em Agenda Google.");
    if (response.status == 403) meetRoomFail("O Google não autorizou a leitura da sala. Reconecte a Agenda Google com a permissão do Meet e confirme que contato@runnerhub.run é proprietário da sala.");
    if (response.status == 404) meetRoomFail("A sala configurada não foi encontrada ou não está acessível para contato@runnerhub.run.");
    if (response.status == 429 || response.status >= 500 || response.status == 0) meetRoomFail("O Google Meet está temporariamente indisponível ou limitou as consultas.");
    if (response.status < 200 || response.status >= 300) meetRoomFail("Não foi possível consultar a sala no Google Meet.");
    return response.data;
}

function meetRoomParticipant(required struct participant) {
    var displayName = "Participante";
    var participantType = "unknown";

    if (structKeyExists(arguments.participant, "signedinUser") && isStruct(arguments.participant.signedinUser)) {
        participantType = "signed_in";
        if (structKeyExists(arguments.participant.signedinUser, "displayName") && len(trim(arguments.participant.signedinUser.displayName & ""))) {
            displayName = trim(arguments.participant.signedinUser.displayName & "");
        }
    } else if (structKeyExists(arguments.participant, "anonymousUser") && isStruct(arguments.participant.anonymousUser)) {
        participantType = "anonymous";
        if (structKeyExists(arguments.participant.anonymousUser, "displayName") && len(trim(arguments.participant.anonymousUser.displayName & ""))) {
            displayName = trim(arguments.participant.anonymousUser.displayName & "");
        }
    } else if (structKeyExists(arguments.participant, "phoneUser") && isStruct(arguments.participant.phoneUser)) {
        participantType = "phone";
        if (structKeyExists(arguments.participant.phoneUser, "displayName") && len(trim(arguments.participant.phoneUser.displayName & ""))) {
            displayName = trim(arguments.participant.phoneUser.displayName & "");
        }
    }

    if (len(displayName) GT 160) displayName = left(displayName, 160);
    var resourceName = structKeyExists(arguments.participant, "name") ? arguments.participant.name & "" : createUUID();
    return {"id"=lCase(hash(resourceName, "SHA-256")), "displayName"=displayName, "type"=participantType};
}

function meetRoomParticipantIsActive(required struct participant) {
    if (!structKeyExists(arguments.participant, "latestEndTime")) return true;
    try {
        return !len(trim(arguments.participant.latestEndTime & ""));
    } catch (any ignored) {
        return true;
    }
}

function meetRoomLiveStatus() {
    var config = meetRoomConfig();
    if (!config.configured) {
        return {"configured"=false, "connected"=true, "active"=false, "participantCount"=0, "participants"=[], "meetingUri"=""};
    }

    var space = meetRoomGoogle("/spaces/" & config.meetingCode);
    var meetingUri = structKeyExists(space, "meetingUri") && reFindNoCase("^https://meet\.google\.com/[a-z-]+$", space.meetingUri & "")
        ? space.meetingUri & ""
        : config.meetingUri;
    var result = {
        "configured"=true,
        "connected"=true,
        "active"=false,
        "participantCount"=0,
        "participants"=[],
        "meetingUri"=meetingUri
    };

    if (!structKeyExists(space, "activeConference") || !isStruct(space.activeConference)
        || !structKeyExists(space.activeConference, "conferenceRecord")
        || !reFind("^conferenceRecords/[A-Za-z0-9_-]+$", space.activeConference.conferenceRecord & "")) {
        return result;
    }

    var conferenceRecord = space.activeConference.conferenceRecord & "";
    var pageToken = "";
    var scannedParticipants = 0;
    do {
        var params = {"pageSize"=250};
        if (len(pageToken)) params["pageToken"] = pageToken;
        var response = meetRoomGoogle("/" & conferenceRecord & "/participants", params);
        if (structKeyExists(response, "participants") && isArray(response.participants)) {
            for (var participant in response.participants) {
                scannedParticipants++;
                if (meetRoomParticipantIsActive(participant)) {
                    arrayAppend(result.participants, meetRoomParticipant(participant));
                }
            }
        }
        pageToken = structKeyExists(response, "nextPageToken") ? response.nextPageToken & "" : "";
        if (scannedParticipants GT 5000) meetRoomFail("A conferência retornou participantes demais para o painel.");
    } while (len(pageToken));

    result.active = true;
    result.participantCount = arrayLen(result.participants);
    return result;
}

function meetRoomCachedStatus() {
    var config = meetRoomConfig();
    if (!config.configured) return meetRoomLiveStatus();

    if (structKeyExists(application, "googleMeetRoomStatusCache")
        && isStruct(application.googleMeetRoomStatusCache)
        && structKeyExists(application.googleMeetRoomStatusCache, "expiresAt")
        && isDate(application.googleMeetRoomStatusCache.expiresAt)
        && dateCompare(application.googleMeetRoomStatusCache.expiresAt, now()) GT 0
        && structKeyExists(application.googleMeetRoomStatusCache, "value")) {
        return duplicate(application.googleMeetRoomStatusCache.value);
    }

    lock name="RunnerHubBusiness.GoogleMeetRoom" type="exclusive" timeout="20" {
        if (structKeyExists(application, "googleMeetRoomStatusCache")
            && isStruct(application.googleMeetRoomStatusCache)
            && structKeyExists(application.googleMeetRoomStatusCache, "expiresAt")
            && isDate(application.googleMeetRoomStatusCache.expiresAt)
            && dateCompare(application.googleMeetRoomStatusCache.expiresAt, now()) GT 0
            && structKeyExists(application.googleMeetRoomStatusCache, "value")) {
            return duplicate(application.googleMeetRoomStatusCache.value);
        }

        var currentStatus = meetRoomLiveStatus();
        application.googleMeetRoomStatusCache = {
            "expiresAt"=dateAdd("s", config.cacheSeconds, now()),
            "value"=duplicate(currentStatus)
        };
        return currentStatus;
    }
}
</cfscript>
