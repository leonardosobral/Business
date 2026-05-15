<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.notificationSendPage = max(1, int(URL.pagina))/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif NOT structKeyExists(REQUEST, "notificationPushHelpersLoaded")>
    <cfscript>
        function notificationPushBase64UrlEncode(required binary valueBytes) {
            return replace(replace(replace(toBase64(arguments.valueBytes), "+", "-", "all"), "/", "_", "all"), "=", "", "all");
        }

        function notificationPushStringToBinary(required string value) {
            return charsetDecode(arguments.value, "utf-8");
        }

        function notificationPushBase64UrlDecodeToBinary(required string value) {
            var normalized = trim(arguments.value);
            var padding = "";

            normalized = replace(normalized, "-", "+", "all");
            normalized = replace(normalized, "_", "/", "all");

            switch (len(normalized) mod 4) {
                case 2:
                    padding = "==";
                    break;
                case 3:
                    padding = "=";
                    break;
                default:
                    padding = "";
            }

            return binaryDecode(normalized & padding, "base64");
        }

        function notificationPushDerSignatureToJose(required binary derSignature, numeric joseLength = 64) {
            var bytesHex = binaryEncode(arguments.derSignature, "hex");
            var bytes = [];
            var index = 0;
            var rLength = 0;
            var sLength = 0;
            var rBytes = [];
            var sBytes = [];
            var outputHex = "";
            var componentLength = arguments.joseLength / 2;
            var i = 0;
            var totalBytes = len(bytesHex) / 2;
            var derLengthInfo = {};
            var rLengthInfo = {};
            var sLengthInfo = {};

            for (i = 1; i LTE totalBytes; i += 1) {
                arrayAppend(bytes, inputBaseN(mid(bytesHex, ((i - 1) * 2) + 1, 2), 16));
            }

            function readLength(required array sourceBytes, required numeric startIndex) {
                var lengthByte = sourceBytes[startIndex];
                var lengthValue = 0;
                var byteCount = 0;
                var j = 0;

                if (lengthByte LT 128) {
                    return {
                        value = lengthByte,
                        nextIndex = startIndex + 1
                    };
                }

                byteCount = bitAnd(lengthByte, 127);

                for (j = 1; j LTE byteCount; j += 1) {
                    lengthValue = bitOr(bitSHLN(lengthValue, 8), sourceBytes[startIndex + j]);
                }

                return {
                    value = lengthValue,
                    nextIndex = startIndex + byteCount + 1
                };
            }

            if (bytes[index + 1] NEQ 48) {
                throw(message="Assinatura DER inválida.");
            }

            index += 2;
            derLengthInfo = readLength(bytes, index);
            index = derLengthInfo.nextIndex;

            if (bytes[index] NEQ 2) {
                throw(message="Assinatura DER inválida.");
            }

            index += 1;
            rLengthInfo = readLength(bytes, index);
            rLength = rLengthInfo.value;
            index = rLengthInfo.nextIndex;

            for (i = 1; i LTE rLength; i += 1) {
                arrayAppend(rBytes, bytes[index]);
                index += 1;
            }

            if (bytes[index] NEQ 2) {
                throw(message="Assinatura DER inválida.");
            }

            index += 1;
            sLengthInfo = readLength(bytes, index);
            sLength = sLengthInfo.value;
            index = sLengthInfo.nextIndex;

            for (i = 1; i LTE sLength; i += 1) {
                arrayAppend(sBytes, bytes[index]);
                index += 1;
            }

            while (arrayLen(rBytes) GT componentLength) {
                arrayDeleteAt(rBytes, 1);
            }

            while (arrayLen(sBytes) GT componentLength) {
                arrayDeleteAt(sBytes, 1);
            }

            while (arrayLen(rBytes) LT componentLength) {
                arrayPrepend(rBytes, 0);
            }

            while (arrayLen(sBytes) LT componentLength) {
                arrayPrepend(sBytes, 0);
            }

            for (i = 1; i LTE componentLength; i += 1) {
                outputHex &= right("0" & lCase(formatBaseN(rBytes[i], 16)), 2);
            }

            for (i = 1; i LTE componentLength; i += 1) {
                outputHex &= right("0" & lCase(formatBaseN(sBytes[i], 16)), 2);
            }

            return binaryDecode(outputHex, "hex");
        }

        function notificationPushGenerateVapidJwt(required string audience, required string subject, required string privateKey) {
            var algorithmParameters = createObject("java", "java.security.AlgorithmParameters").getInstance("EC");
            var ecGenParameterSpec = createObject("java", "java.security.spec.ECGenParameterSpec").init("secp256r1");
            var ecParameterSpecClass = createObject("java", "java.lang.Class").forName("java.security.spec.ECParameterSpec");
            var ecParameterSpec = "";
            var keyFactory = createObject("java", "java.security.KeyFactory").getInstance("EC");
            var bigIntegerClass = createObject("java", "java.math.BigInteger");
            var privateKeyBytes = notificationPushBase64UrlDecodeToBinary(arguments.privateKey);
            var privateKeyHex = lCase(binaryEncode(privateKeyBytes, "hex"));
            var privateKeySpec = "";
            var privateKeyObject = "";
            var jwtHeader = notificationPushBase64UrlEncode(notificationPushStringToBinary(serializeJSON({ alg = "ES256", typ = "JWT" })));
            var jwtPayload = "";
            var signingInput = "";
            var signer = createObject("java", "java.security.Signature").getInstance("SHA256withECDSA");
            var derSignature = "";
            var joseSignature = "";

            jwtPayload = notificationPushBase64UrlEncode(notificationPushStringToBinary(serializeJSON({
                aud = arguments.audience,
                exp = int(dateDiff("s", createDateTime(1970, 1, 1, 0, 0, 0), dateAdd("h", 12, now()))),
                sub = arguments.subject
            })));
            signingInput = jwtHeader & "." & jwtPayload;

            algorithmParameters.init(ecGenParameterSpec);
            ecParameterSpec = algorithmParameters.getParameterSpec(ecParameterSpecClass);
            privateKeySpec = createObject("java", "java.security.spec.ECPrivateKeySpec").init(bigIntegerClass.init(privateKeyHex, 16), ecParameterSpec);
            privateKeyObject = keyFactory.generatePrivate(privateKeySpec);

            signer.initSign(privateKeyObject);
            signer.update(notificationPushStringToBinary(signingInput));
            derSignature = signer.sign();
            joseSignature = notificationPushDerSignatureToJose(derSignature);

            return signingInput & "." & notificationPushBase64UrlEncode(joseSignature);
        }

        function notificationPushExtractAudience(required string endpoint) {
            var urlObject = createObject("java", "java.net.URL").init(arguments.endpoint);
            var portValue = urlObject.getPort();
            var audience = urlObject.getProtocol() & "://" & urlObject.getHost();

            if (portValue GT 0) {
                audience &= ":" & portValue;
            }

            return audience;
        }
    </cfscript>
    <cfset REQUEST.notificationPushHelpersLoaded = true/>
</cfif>

<cfif structKeyExists(APPLICATION, "pushDispatch")
    AND isStruct(APPLICATION.pushDispatch)
    AND structKeyExists(APPLICATION.pushDispatch, "url")
    AND structKeyExists(APPLICATION.pushDispatch, "secret")>
    <cfset VARIABLES.notificationPushDispatchConfig = duplicate(APPLICATION.pushDispatch)/>
<cfelse>
    <cfset VARIABLES.notificationPushDispatchEnvironment = createObject("java", "java.lang.System").getenv()/>
    <cfset VARIABLES.notificationPushDispatchSecret = structKeyExists(VARIABLES.notificationPushDispatchEnvironment, "RR_HANDOFF_SECRET") ? trim(VARIABLES.notificationPushDispatchEnvironment["RR_HANDOFF_SECRET"]) : ""/>
    <cfset VARIABLES.notificationPushDispatchUrl = structKeyExists(VARIABLES.notificationPushDispatchEnvironment, "RR_PUSH_DISPATCH_URL") ? trim(VARIABLES.notificationPushDispatchEnvironment["RR_PUSH_DISPATCH_URL"]) : "https://roadrunners.run/api/push/send.cfm"/>
    <cfset VARIABLES.notificationPushDispatchTimeoutSeconds = structKeyExists(VARIABLES.notificationPushDispatchEnvironment, "RR_PUSH_DISPATCH_TIMEOUT_SECONDS") ? val(VARIABLES.notificationPushDispatchEnvironment["RR_PUSH_DISPATCH_TIMEOUT_SECONDS"]) : 20/>
    <cfset VARIABLES.notificationPushDispatchConfig = {
        url = len(VARIABLES.notificationPushDispatchUrl) ? VARIABLES.notificationPushDispatchUrl : "https://roadrunners.run/api/push/send.cfm",
        secret = len(VARIABLES.notificationPushDispatchSecret) ? VARIABLES.notificationPushDispatchSecret : hash("RoadRunners::handoff::roadrunners.run::v1", "SHA-256"),
        timeoutSeconds = VARIABLES.notificationPushDispatchTimeoutSeconds GT 0 ? VARIABLES.notificationPushDispatchTimeoutSeconds : 20
    }/>
</cfif>

<cfset VARIABLES.notificationLocalPushFileConfig = {
    publicKey = "",
    privateKey = "",
    subject = "mailto:contato@runnerhub.run"
}/>

<cfif fileExists(expandPath("/config/pwa_push.local.cfm"))>
    <cfinclude template="/config/pwa_push.local.cfm"/>
    <cfif isDefined("localPushConfig") AND isStruct(localPushConfig)>
        <cfif structKeyExists(localPushConfig, "publicKey")>
            <cfset VARIABLES.notificationLocalPushFileConfig.publicKey = trim(localPushConfig.publicKey)/>
        </cfif>
        <cfif structKeyExists(localPushConfig, "privateKey")>
            <cfset VARIABLES.notificationLocalPushFileConfig.privateKey = trim(localPushConfig.privateKey)/>
        </cfif>
        <cfif structKeyExists(localPushConfig, "subject") AND len(trim(localPushConfig.subject))>
            <cfset VARIABLES.notificationLocalPushFileConfig.subject = trim(localPushConfig.subject)/>
        </cfif>
    </cfif>
</cfif>

<cfset VARIABLES.notificationLocalPushEnvironment = createObject("java", "java.lang.System").getenv()/>
<cfset VARIABLES.notificationLocalPushPublicKey = structKeyExists(VARIABLES.notificationLocalPushEnvironment, "RR_PUSH_PUBLIC_KEY") ? trim(VARIABLES.notificationLocalPushEnvironment["RR_PUSH_PUBLIC_KEY"]) : ""/>
<cfset VARIABLES.notificationLocalPushPrivateKey = structKeyExists(VARIABLES.notificationLocalPushEnvironment, "RR_PUSH_PRIVATE_KEY") ? trim(VARIABLES.notificationLocalPushEnvironment["RR_PUSH_PRIVATE_KEY"]) : ""/>
<cfset VARIABLES.notificationLocalPushSubject = structKeyExists(VARIABLES.notificationLocalPushEnvironment, "RR_PUSH_SUBJECT") ? trim(VARIABLES.notificationLocalPushEnvironment["RR_PUSH_SUBJECT"]) : "mailto:contato@runnerhub.run"/>

<cfif structKeyExists(APPLICATION, "pwaPush")
    AND isStruct(APPLICATION.pwaPush)>
    <cfif NOT len(VARIABLES.notificationLocalPushPublicKey)
        AND structKeyExists(APPLICATION.pwaPush, "publicKey")
        AND len(trim(APPLICATION.pwaPush.publicKey))>
        <cfset VARIABLES.notificationLocalPushPublicKey = trim(APPLICATION.pwaPush.publicKey)/>
    </cfif>
    <cfif NOT len(VARIABLES.notificationLocalPushPrivateKey)
        AND structKeyExists(APPLICATION.pwaPush, "privateKey")
        AND len(trim(APPLICATION.pwaPush.privateKey))>
        <cfset VARIABLES.notificationLocalPushPrivateKey = trim(APPLICATION.pwaPush.privateKey)/>
    </cfif>
    <cfif (
        NOT len(VARIABLES.notificationLocalPushSubject)
        OR VARIABLES.notificationLocalPushSubject EQ "mailto:contato@runnerhub.run"
    ) AND structKeyExists(APPLICATION.pwaPush, "subject")
        AND len(trim(APPLICATION.pwaPush.subject))>
        <cfset VARIABLES.notificationLocalPushSubject = trim(APPLICATION.pwaPush.subject)/>
    </cfif>
</cfif>

<cfif len(VARIABLES.notificationLocalPushFileConfig.publicKey)>
    <cfset VARIABLES.notificationLocalPushPublicKey = VARIABLES.notificationLocalPushFileConfig.publicKey/>
</cfif>
<cfif len(VARIABLES.notificationLocalPushFileConfig.privateKey)>
    <cfset VARIABLES.notificationLocalPushPrivateKey = VARIABLES.notificationLocalPushFileConfig.privateKey/>
</cfif>
<cfif len(VARIABLES.notificationLocalPushFileConfig.subject)>
    <cfset VARIABLES.notificationLocalPushSubject = VARIABLES.notificationLocalPushFileConfig.subject/>
</cfif>

<cfset VARIABLES.notificationLocalPushConfig = {
    enabled = (len(VARIABLES.notificationLocalPushPublicKey) GT 0 AND len(VARIABLES.notificationLocalPushPrivateKey) GT 0),
    publicKey = VARIABLES.notificationLocalPushPublicKey,
    privateKey = VARIABLES.notificationLocalPushPrivateKey,
    subject = len(VARIABLES.notificationLocalPushSubject) ? VARIABLES.notificationLocalPushSubject : "mailto:contato@runnerhub.run"
}/>

<cfquery name="qNotificationSendTemplateColumns">
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_notifica_template'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.notificationSendTemplateColumns = ValueList(qNotificationSendTemplateColumns.column_name)/>
<cfset VARIABLES.notificationSendTemplatePk = ""/>
<cfset VARIABLES.notificationSendTemplateSelectColumns = ""/>

<cfloop list="id_notifica_template,id_template,id" item="notificationSendTemplatePkCandidate">
    <cfif NOT len(trim(VARIABLES.notificationSendTemplatePk)) AND ListFindNoCase(VARIABLES.notificationSendTemplateColumns, notificationSendTemplatePkCandidate)>
        <cfset VARIABLES.notificationSendTemplatePk = notificationSendTemplatePkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.notificationSendTemplatePk)) AND qNotificationSendTemplateColumns.recordcount>
    <cfset VARIABLES.notificationSendTemplatePk = qNotificationSendTemplateColumns.column_name/>
</cfif>

<cfloop query="qNotificationSendTemplateColumns">
    <cfset VARIABLES.notificationSendTemplateSelectColumns = ListAppend(VARIABLES.notificationSendTemplateSelectColumns, '"' & Replace(qNotificationSendTemplateColumns.column_name, '"', '""', 'all') & '"')/>
</cfloop>

<cfset VARIABLES.notificationSendTemplateCampaignColumn = ""/>
<cfset VARIABLES.notificationSendTemplateContentColumn = ""/>
<cfset VARIABLES.notificationSendTemplateIconColumn = ""/>
<cfset VARIABLES.notificationSendTemplateLinkColumn = ""/>

<cfloop list="campanha,nome,name,titulo,title,assunto,subject" item="notificationSendTemplateCampaignCandidate">
    <cfif NOT len(trim(VARIABLES.notificationSendTemplateCampaignColumn)) AND ListFindNoCase(VARIABLES.notificationSendTemplateColumns, notificationSendTemplateCampaignCandidate)>
        <cfset VARIABLES.notificationSendTemplateCampaignColumn = notificationSendTemplateCampaignCandidate/>
    </cfif>
</cfloop>

<cfloop list="conteudo_template,conteudo,content,body,mensagem" item="notificationSendTemplateContentCandidate">
    <cfif NOT len(trim(VARIABLES.notificationSendTemplateContentColumn)) AND ListFindNoCase(VARIABLES.notificationSendTemplateColumns, notificationSendTemplateContentCandidate)>
        <cfset VARIABLES.notificationSendTemplateContentColumn = notificationSendTemplateContentCandidate/>
    </cfif>
</cfloop>

<cfloop list="icone,icona,icon,icon_class,icone_class" item="notificationSendTemplateIconCandidate">
    <cfif NOT len(trim(VARIABLES.notificationSendTemplateIconColumn)) AND ListFindNoCase(VARIABLES.notificationSendTemplateColumns, notificationSendTemplateIconCandidate)>
        <cfset VARIABLES.notificationSendTemplateIconColumn = notificationSendTemplateIconCandidate/>
    </cfif>
</cfloop>

<cfloop list="link,url" item="notificationSendTemplateLinkCandidate">
    <cfif NOT len(trim(VARIABLES.notificationSendTemplateLinkColumn)) AND ListFindNoCase(VARIABLES.notificationSendTemplateColumns, notificationSendTemplateLinkCandidate)>
        <cfset VARIABLES.notificationSendTemplateLinkColumn = notificationSendTemplateLinkCandidate/>
    </cfif>
</cfloop>

<cfset VARIABLES.notificationSendTemplateId = trim(isDefined("FORM.notification_send_template_id") ? FORM.notification_send_template_id : (isDefined("URL.template_id") ? URL.template_id : ""))/>
<cfset VARIABLES.notificationSendUserId = trim(isDefined("FORM.notification_send_user_id") ? FORM.notification_send_user_id : (isDefined("URL.user_id") ? URL.user_id : ""))/>
<cfset VARIABLES.notificationSendAdmin = trim(isDefined("FORM.notification_send_admin") ? FORM.notification_send_admin : (isDefined("URL.admin") ? URL.admin : ""))/>
<cfset VARIABLES.notificationSendStrava = trim(isDefined("FORM.notification_send_strava") ? FORM.notification_send_strava : (isDefined("URL.strava") ? URL.strava : ""))/>
<cfset VARIABLES.notificationSendDesafio = trim(isDefined("FORM.notification_send_desafio") ? FORM.notification_send_desafio : (isDefined("URL.desafio") ? URL.desafio : ""))/>
<cfset VARIABLES.notificationSendAssessoria = trim(isDefined("FORM.notification_send_assessoria") ? FORM.notification_send_assessoria : (isDefined("URL.assessoria") ? URL.assessoria : ""))/>
<cfset VARIABLES.notificationSendDev = trim(isDefined("FORM.notification_send_dev") ? FORM.notification_send_dev : (isDefined("URL.dev") ? URL.dev : ""))/>
<cfset VARIABLES.notificationSendPartner = trim(isDefined("FORM.notification_send_partner") ? FORM.notification_send_partner : (isDefined("URL.partner") ? URL.partner : ""))/>
<cfset VARIABLES.notificationSendGenero = uCase(trim(isDefined("FORM.notification_send_genero") ? FORM.notification_send_genero : (isDefined("URL.genero") ? URL.genero : "")))/>
<cfset VARIABLES.notificationSendCBAT = trim(isDefined("FORM.notification_send_cbat") ? FORM.notification_send_cbat : (isDefined("URL.cbat") ? URL.cbat : ""))/>
<cfset VARIABLES.notificationSendPais = trim(isDefined("FORM.notification_send_pais") ? FORM.notification_send_pais : (isDefined("URL.pais") ? URL.pais : ""))/>
<cfset VARIABLES.notificationSendEstado = uCase(trim(isDefined("FORM.notification_send_estado") ? FORM.notification_send_estado : (isDefined("URL.estado") ? URL.estado : "")))/>
<cfset VARIABLES.notificationSendVerificado = trim(isDefined("FORM.notification_send_verificado") ? FORM.notification_send_verificado : (isDefined("URL.verificado") ? URL.verificado : ""))/>
<cfset VARIABLES.notificationSendPublicacao = trim(isDefined("FORM.notification_send_data_publicacao") ? FORM.notification_send_data_publicacao : (isDefined("URL.data_publicacao") ? URL.data_publicacao : ""))/>
<cfset VARIABLES.notificationSendDiasExpiracao = trim(isDefined("FORM.notification_send_dias_expiracao") ? FORM.notification_send_dias_expiracao : (isDefined("URL.dias_expiracao") ? URL.dias_expiracao : "3"))/>

<cfif NOT len(trim(VARIABLES.notificationSendPublicacao))>
    <cfset VARIABLES.notificationSendPublicacao = DateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn")/>
</cfif>

<cfset VARIABLES.notificationSendPublicationValue = Replace(VARIABLES.notificationSendPublicacao, "T", " ", "one")/>
<cfif reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", VARIABLES.notificationSendPublicationValue)>
    <cfset VARIABLES.notificationSendPublicationValue &= ":00"/>
</cfif>
<cfset VARIABLES.notificationSendPublicationIsValid = isDate(VARIABLES.notificationSendPublicationValue)/>
<cfset VARIABLES.notificationSendPublicationDate = VARIABLES.notificationSendPublicationIsValid ? parseDateTime(VARIABLES.notificationSendPublicationValue) : ""/>

<cfif NOT len(trim(VARIABLES.notificationSendDiasExpiracao)) OR NOT isNumeric(VARIABLES.notificationSendDiasExpiracao)>
    <cfset VARIABLES.notificationSendDiasExpiracao = "3"/>
</cfif>
<cfset VARIABLES.notificationSendDiasExpiracaoValor = int(VARIABLES.notificationSendDiasExpiracao)/>
<cfset VARIABLES.notificationSendExpirationIsValid = VARIABLES.notificationSendDiasExpiracaoValor GTE 0/>
<cfset VARIABLES.notificationSendExpirationHasValue = VARIABLES.notificationSendPublicationIsValid AND VARIABLES.notificationSendExpirationIsValid/>
<cfset VARIABLES.notificationSendExpirationDate = VARIABLES.notificationSendExpirationHasValue ? dateAdd("d", VARIABLES.notificationSendDiasExpiracaoValor, VARIABLES.notificationSendPublicationDate) : ""/>

<cfset VARIABLES.notificationSendStatus = trim(isDefined("URL.envio_status") ? URL.envio_status : "")/>
<cfset VARIABLES.notificationSendTotalSent = (isDefined("URL.envio_total") AND isNumeric(URL.envio_total)) ? int(URL.envio_total) : 0/>
<cfset VARIABLES.notificationSendPushStatus = trim(isDefined("URL.envio_push_status") ? URL.envio_push_status : "")/>
<cfset VARIABLES.notificationSendPushNotifications = (isDefined("URL.envio_push_notifications") AND isNumeric(URL.envio_push_notifications)) ? int(URL.envio_push_notifications) : 0/>
<cfset VARIABLES.notificationSendPushDeliveries = (isDefined("URL.envio_push_deliveries") AND isNumeric(URL.envio_push_deliveries)) ? int(URL.envio_push_deliveries) : 0/>
<cfset VARIABLES.notificationSendPushSubscriptions = (isDefined("URL.envio_push_subscriptions") AND isNumeric(URL.envio_push_subscriptions)) ? int(URL.envio_push_subscriptions) : 0/>

<cfset VARIABLES.notificationSendRedirectUrl = "./?pagina=" & VARIABLES.notificationSendPage/>
<cfif len(trim(VARIABLES.notificationSendTemplateId))><cfset VARIABLES.notificationSendRedirectUrl &= "&template_id=" & urlEncodedFormat(VARIABLES.notificationSendTemplateId)/></cfif>
<cfif len(trim(VARIABLES.notificationSendUserId))><cfset VARIABLES.notificationSendRedirectUrl &= "&user_id=" & urlEncodedFormat(VARIABLES.notificationSendUserId)/></cfif>
<cfif len(trim(VARIABLES.notificationSendAdmin))><cfset VARIABLES.notificationSendRedirectUrl &= "&admin=" & urlEncodedFormat(VARIABLES.notificationSendAdmin)/></cfif>
<cfif len(trim(VARIABLES.notificationSendStrava))><cfset VARIABLES.notificationSendRedirectUrl &= "&strava=" & urlEncodedFormat(VARIABLES.notificationSendStrava)/></cfif>
<cfif len(trim(VARIABLES.notificationSendDesafio))><cfset VARIABLES.notificationSendRedirectUrl &= "&desafio=" & urlEncodedFormat(VARIABLES.notificationSendDesafio)/></cfif>
<cfif len(trim(VARIABLES.notificationSendAssessoria))><cfset VARIABLES.notificationSendRedirectUrl &= "&assessoria=" & urlEncodedFormat(VARIABLES.notificationSendAssessoria)/></cfif>
<cfif len(trim(VARIABLES.notificationSendDev))><cfset VARIABLES.notificationSendRedirectUrl &= "&dev=" & urlEncodedFormat(VARIABLES.notificationSendDev)/></cfif>
<cfif len(trim(VARIABLES.notificationSendPartner))><cfset VARIABLES.notificationSendRedirectUrl &= "&partner=" & urlEncodedFormat(VARIABLES.notificationSendPartner)/></cfif>
<cfif len(trim(VARIABLES.notificationSendGenero))><cfset VARIABLES.notificationSendRedirectUrl &= "&genero=" & urlEncodedFormat(VARIABLES.notificationSendGenero)/></cfif>
<cfif len(trim(VARIABLES.notificationSendCBAT))><cfset VARIABLES.notificationSendRedirectUrl &= "&cbat=" & urlEncodedFormat(VARIABLES.notificationSendCBAT)/></cfif>
<cfif len(trim(VARIABLES.notificationSendPais))><cfset VARIABLES.notificationSendRedirectUrl &= "&pais=" & urlEncodedFormat(VARIABLES.notificationSendPais)/></cfif>
<cfif len(trim(VARIABLES.notificationSendEstado))><cfset VARIABLES.notificationSendRedirectUrl &= "&estado=" & urlEncodedFormat(VARIABLES.notificationSendEstado)/></cfif>
<cfif len(trim(VARIABLES.notificationSendVerificado))><cfset VARIABLES.notificationSendRedirectUrl &= "&verificado=" & urlEncodedFormat(VARIABLES.notificationSendVerificado)/></cfif>
<cfif len(trim(VARIABLES.notificationSendPublicacao))><cfset VARIABLES.notificationSendRedirectUrl &= "&data_publicacao=" & urlEncodedFormat(VARIABLES.notificationSendPublicacao)/></cfif>
<cfif len(trim(VARIABLES.notificationSendDiasExpiracao))><cfset VARIABLES.notificationSendRedirectUrl &= "&dias_expiracao=" & urlEncodedFormat(VARIABLES.notificationSendDiasExpiracao)/></cfif>

<cfif qNotificationSendTemplateColumns.recordcount AND len(trim(VARIABLES.notificationSendTemplatePk))>
    <cfquery name="qNotificationSendTemplates">
        SELECT #PreserveSingleQuotes(VARIABLES.notificationSendTemplateSelectColumns)#
        FROM tb_notifica_template
        ORDER BY "#Replace(VARIABLES.notificationSendTemplatePk, '"', '""', 'all')#" DESC
    </cfquery>
<cfelse>
    <cfset qNotificationSendTemplates = QueryNew("")/>
</cfif>

<cfset qNotificationSendTemplateCurrent = QueryNew("")/>

<cfif qNotificationSendTemplateColumns.recordcount
    AND len(trim(VARIABLES.notificationSendTemplatePk))
    AND len(trim(VARIABLES.notificationSendTemplateId))>
    <cfquery name="qNotificationSendTemplateCurrent">
        SELECT #PreserveSingleQuotes(VARIABLES.notificationSendTemplateSelectColumns)#
        FROM tb_notifica_template
        WHERE "#Replace(VARIABLES.notificationSendTemplatePk, '"', '""', 'all')#" =
        <cfif isNumeric(VARIABLES.notificationSendTemplateId)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationSendTemplateId#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendTemplateId#"/>
        </cfif>
        LIMIT 1
    </cfquery>
</cfif>

<cfif isDefined("FORM.notification_send_action") AND FORM.notification_send_action EQ "enviar">
    <cfif NOT qNotificationSendTemplateCurrent.recordcount>
        <cflocation addtoken="false" url="#VARIABLES.notificationSendRedirectUrl#&envio_status=template_invalido"/>
    </cfif>

    <cfif NOT VARIABLES.notificationSendPublicationIsValid>
        <cflocation addtoken="false" url="#VARIABLES.notificationSendRedirectUrl#&envio_status=publicacao_invalida"/>
    </cfif>

    <cfif NOT VARIABLES.notificationSendExpirationIsValid>
        <cflocation addtoken="false" url="#VARIABLES.notificationSendRedirectUrl#&envio_status=expiracao_invalida"/>
    </cfif>

    <cfquery name="qNotificationSendCount">
        SELECT count(*) AS total
        FROM (
            SELECT DISTINCT usr.id
            FROM tb_usuarios usr
            LEFT JOIN LATERAL (
                SELECT pg.id_pagina,
                       pg.nome,
                       pg.tag,
                       pg.verificado,
                       pg.uf
                FROM tb_paginas pg
                WHERE pg.id_usuario_cadastro = usr.id
                  AND pg.tag_prefix = 'atleta'
                ORDER BY pg.verificado DESC, pg.id_pagina DESC
                LIMIT 1
            ) pag ON true
            WHERE 1 = 1
            <cfif len(trim(VARIABLES.notificationSendUserId)) AND isNumeric(VARIABLES.notificationSendUserId)>
                AND usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationSendUserId#"/>
            </cfif>
            <cfif VARIABLES.notificationSendAdmin EQ "true">
                AND usr.is_admin = true
            <cfelseif VARIABLES.notificationSendAdmin EQ "false">
                AND coalesce(usr.is_admin, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendStrava EQ "true">
                AND (usr.strava_id IS NOT NULL OR (usr.strava_code IS NOT NULL AND trim(usr.strava_code) <> ''))
            <cfelseif VARIABLES.notificationSendStrava EQ "false">
                AND usr.strava_id IS NULL
                AND (usr.strava_code IS NULL OR trim(usr.strava_code) = '')
            </cfif>
            <cfif VARIABLES.notificationSendDesafio EQ "true">
                AND EXISTS (
                    SELECT 1
                    FROM desafios des
                    WHERE des.id_usuario = usr.id
                )
            <cfelseif VARIABLES.notificationSendDesafio EQ "false">
                AND NOT EXISTS (
                    SELECT 1
                    FROM desafios des
                    WHERE des.id_usuario = usr.id
                )
            </cfif>
            <cfif VARIABLES.notificationSendAssessoria EQ "true">
                AND trim(coalesce(usr.assessoria, '')) <> ''
            <cfelseif VARIABLES.notificationSendAssessoria EQ "false">
                AND trim(coalesce(usr.assessoria, '')) = ''
            </cfif>
            <cfif VARIABLES.notificationSendDev EQ "true">
                AND usr.is_dev = true
            <cfelseif VARIABLES.notificationSendDev EQ "false">
                AND coalesce(usr.is_dev, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendPartner EQ "true">
                AND usr.is_partner = true
            <cfelseif VARIABLES.notificationSendPartner EQ "false">
                AND coalesce(usr.is_partner, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendGenero EQ "M" OR VARIABLES.notificationSendGenero EQ "F">
                AND upper(left(coalesce(usr.genero, usr.strava_sex, ''), 1)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendGenero#"/>
            </cfif>
            <cfif VARIABLES.notificationSendCBAT EQ "true">
                AND trim(coalesce(usr.cbat, '')) <> ''
            <cfelseif VARIABLES.notificationSendCBAT EQ "false">
                AND trim(coalesce(usr.cbat, '')) = ''
            </cfif>
            <cfif len(trim(VARIABLES.notificationSendPais))>
                AND usr.pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendPais#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificationSendEstado))>
                AND coalesce(usr.estado, pag.uf) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendEstado#"/>
            </cfif>
            <cfif VARIABLES.notificationSendVerificado EQ "true">
                AND coalesce(pag.verificado, false) = true
            <cfelseif VARIABLES.notificationSendVerificado EQ "false">
                AND coalesce(pag.verificado, false) = false
            </cfif>
        ) notification_send_recipients
    </cfquery>

    <cfif NOT qNotificationSendCount.total>
        <cflocation addtoken="false" url="#VARIABLES.notificationSendRedirectUrl#&envio_status=sem_destinatarios"/>
    </cfif>

    <cfset VARIABLES.notificationSendTemplateContentValue = len(trim(VARIABLES.notificationSendTemplateContentColumn)) ? qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateContentColumn][1] : ""/>
    <cfset VARIABLES.notificationSendTemplateIconValue = len(trim(VARIABLES.notificationSendTemplateIconColumn)) ? qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateIconColumn][1] : ""/>
    <cfset VARIABLES.notificationSendTemplateLinkValue = len(trim(VARIABLES.notificationSendTemplateLinkColumn)) ? qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateLinkColumn][1] : ""/>

    <cfquery name="qNotificationSendInsert">
        INSERT INTO tb_notifica (
            id_usuario,
            data_publicacao,
            data_expiracao,
            id_notifica_template,
            link,
            icone,
            conteudo_notifica,
            data_leitura
        )
        SELECT recipients.id_usuario,
               <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificationSendPublicationDate#"/>,
               <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificationSendExpirationDate#" null="#NOT VARIABLES.notificationSendExpirationHasValue#"/>,
               <cfqueryparam cfsqltype="cf_sql_integer" value="#qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplatePk][1]#"/>,
               <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendTemplateLinkValue#" null="#NOT len(trim(VARIABLES.notificationSendTemplateLinkValue))#"/>,
               <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendTemplateIconValue#" null="#NOT len(trim(VARIABLES.notificationSendTemplateIconValue))#"/>,
               <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendTemplateContentValue#" null="#NOT len(trim(VARIABLES.notificationSendTemplateContentValue))#"/>,
               null
        FROM (
            SELECT DISTINCT usr.id AS id_usuario
            FROM tb_usuarios usr
            LEFT JOIN LATERAL (
                SELECT pg.id_pagina,
                       pg.verificado,
                       pg.uf
                FROM tb_paginas pg
                WHERE pg.id_usuario_cadastro = usr.id
                  AND pg.tag_prefix = 'atleta'
                ORDER BY pg.verificado DESC, pg.id_pagina DESC
                LIMIT 1
            ) pag ON true
            WHERE 1 = 1
            <cfif len(trim(VARIABLES.notificationSendUserId)) AND isNumeric(VARIABLES.notificationSendUserId)>
                AND usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationSendUserId#"/>
            </cfif>
            <cfif VARIABLES.notificationSendAdmin EQ "true">
                AND usr.is_admin = true
            <cfelseif VARIABLES.notificationSendAdmin EQ "false">
                AND coalesce(usr.is_admin, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendStrava EQ "true">
                AND (usr.strava_id IS NOT NULL OR (usr.strava_code IS NOT NULL AND trim(usr.strava_code) <> ''))
            <cfelseif VARIABLES.notificationSendStrava EQ "false">
                AND usr.strava_id IS NULL
                AND (usr.strava_code IS NULL OR trim(usr.strava_code) = '')
            </cfif>
            <cfif VARIABLES.notificationSendDesafio EQ "true">
                AND EXISTS (
                    SELECT 1
                    FROM desafios des
                    WHERE des.id_usuario = usr.id
                )
            <cfelseif VARIABLES.notificationSendDesafio EQ "false">
                AND NOT EXISTS (
                    SELECT 1
                    FROM desafios des
                    WHERE des.id_usuario = usr.id
                )
            </cfif>
            <cfif VARIABLES.notificationSendAssessoria EQ "true">
                AND trim(coalesce(usr.assessoria, '')) <> ''
            <cfelseif VARIABLES.notificationSendAssessoria EQ "false">
                AND trim(coalesce(usr.assessoria, '')) = ''
            </cfif>
            <cfif VARIABLES.notificationSendDev EQ "true">
                AND usr.is_dev = true
            <cfelseif VARIABLES.notificationSendDev EQ "false">
                AND coalesce(usr.is_dev, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendPartner EQ "true">
                AND usr.is_partner = true
            <cfelseif VARIABLES.notificationSendPartner EQ "false">
                AND coalesce(usr.is_partner, false) = false
            </cfif>
            <cfif VARIABLES.notificationSendGenero EQ "M" OR VARIABLES.notificationSendGenero EQ "F">
                AND upper(left(coalesce(usr.genero, usr.strava_sex, ''), 1)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendGenero#"/>
            </cfif>
            <cfif VARIABLES.notificationSendCBAT EQ "true">
                AND trim(coalesce(usr.cbat, '')) <> ''
            <cfelseif VARIABLES.notificationSendCBAT EQ "false">
                AND trim(coalesce(usr.cbat, '')) = ''
            </cfif>
            <cfif len(trim(VARIABLES.notificationSendPais))>
                AND usr.pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendPais#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificationSendEstado))>
                AND coalesce(usr.estado, pag.uf) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendEstado#"/>
            </cfif>
            <cfif VARIABLES.notificationSendVerificado EQ "true">
                AND coalesce(pag.verificado, false) = true
            <cfelseif VARIABLES.notificationSendVerificado EQ "false">
                AND coalesce(pag.verificado, false) = false
            </cfif>
        ) recipients
        ON CONFLICT (id_usuario, id_notifica_template)
        DO UPDATE SET
            data_publicacao = excluded.data_publicacao,
            data_expiracao = excluded.data_expiracao,
            link = excluded.link,
            icone = excluded.icone,
            conteudo_notifica = excluded.conteudo_notifica,
            data_leitura = excluded.data_leitura
        RETURNING id_notifica, id_usuario
    </cfquery>

    <cfset VARIABLES.notificationSendPushRedirectSuffix = "&envio_push_status=not_configured"/>

    <cfif VARIABLES.notificationSendPublicationDate GT now()>
        <cfset VARIABLES.notificationSendPushRedirectSuffix = "&envio_push_status=scheduled"/>
    <cfelseif qNotificationSendInsert.recordcount
        AND isStruct(VARIABLES.notificationPushDispatchConfig)
        AND structKeyExists(VARIABLES.notificationPushDispatchConfig, "url")
        AND len(trim(VARIABLES.notificationPushDispatchConfig.url))
        AND structKeyExists(VARIABLES.notificationPushDispatchConfig, "secret")
        AND len(trim(VARIABLES.notificationPushDispatchConfig.secret))>
        <cfscript>
            VARIABLES.notificationPushDispatchIds = [];

            for (VARIABLES.notificationPushDispatchRowIndex = 1; VARIABLES.notificationPushDispatchRowIndex LTE qNotificationSendInsert.recordcount; VARIABLES.notificationPushDispatchRowIndex += 1) {
                arrayAppend(VARIABLES.notificationPushDispatchIds, qNotificationSendInsert.id_notifica[VARIABLES.notificationPushDispatchRowIndex]);
            }

            VARIABLES.notificationPushDispatchRawBody = serializeJSON({
                notificationIds = VARIABLES.notificationPushDispatchIds
            });
            VARIABLES.notificationPushDispatchTimestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
            VARIABLES.notificationPushDispatchSignature = lCase(hmac(
                VARIABLES.notificationPushDispatchTimestamp & "." & VARIABLES.notificationPushDispatchRawBody,
                VARIABLES.notificationPushDispatchConfig.secret,
                "HmacSHA256"
            ));
            VARIABLES.notificationPushDispatchTimeoutValue = int(VARIABLES.notificationPushDispatchConfig.timeoutSeconds);
            VARIABLES.notificationPushDirectPreferredEnvironment = "prod";
            VARIABLES.notificationPushDispatchUrlPrimary = trim(VARIABLES.notificationPushDispatchConfig.url);

            if (VARIABLES.notificationPushDispatchTimeoutValue LTE 0) {
                VARIABLES.notificationPushDispatchTimeoutValue = 20;
            }

            if (findNoCase("://beta.roadrunners.run/", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDirectPreferredEnvironment = "beta";
            } else if (findNoCase("://dev.roadrunners.run/", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDirectPreferredEnvironment = "dev";
            }

            VARIABLES.notificationPushDispatchUrls = [];
            VARIABLES.notificationPushDispatchUrlAlternatePath = "";
            VARIABLES.notificationPushDispatchUrlBetaPrimary = "";
            VARIABLES.notificationPushDispatchUrlBetaAlternatePath = "";

            if (findNoCase("/api/push/send.cfm", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDispatchUrlAlternatePath = replaceNoCase(
                    VARIABLES.notificationPushDispatchUrlPrimary,
                    "/api/push/send.cfm",
                    "/api/push/send-notifications.cfm",
                    "one"
                );
            } else if (findNoCase("/api/push/send-notifications.cfm", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDispatchUrlAlternatePath = replaceNoCase(
                    VARIABLES.notificationPushDispatchUrlPrimary,
                    "/api/push/send-notifications.cfm",
                    "/api/push/send.cfm",
                    "one"
                );
            }

            if (findNoCase("://roadrunners.run/", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDispatchUrlBetaPrimary = replaceNoCase(
                    VARIABLES.notificationPushDispatchUrlPrimary,
                    "://roadrunners.run/",
                    "://beta.roadrunners.run/",
                    "one"
                );
            } else if (findNoCase("://beta.roadrunners.run/", VARIABLES.notificationPushDispatchUrlPrimary)) {
                VARIABLES.notificationPushDispatchUrlBetaPrimary = replaceNoCase(
                    VARIABLES.notificationPushDispatchUrlPrimary,
                    "://beta.roadrunners.run/",
                    "://roadrunners.run/",
                    "one"
                );
            }

            if (len(VARIABLES.notificationPushDispatchUrlBetaPrimary)) {
                if (findNoCase("/api/push/send.cfm", VARIABLES.notificationPushDispatchUrlBetaPrimary)) {
                    VARIABLES.notificationPushDispatchUrlBetaAlternatePath = replaceNoCase(
                        VARIABLES.notificationPushDispatchUrlBetaPrimary,
                        "/api/push/send.cfm",
                        "/api/push/send-notifications.cfm",
                        "one"
                    );
                } else if (findNoCase("/api/push/send-notifications.cfm", VARIABLES.notificationPushDispatchUrlBetaPrimary)) {
                    VARIABLES.notificationPushDispatchUrlBetaAlternatePath = replaceNoCase(
                        VARIABLES.notificationPushDispatchUrlBetaPrimary,
                        "/api/push/send-notifications.cfm",
                        "/api/push/send.cfm",
                        "one"
                    );
                }
            }

            for (VARIABLES.notificationPushDispatchUrlCandidate in [
                VARIABLES.notificationPushDispatchUrlPrimary,
                VARIABLES.notificationPushDispatchUrlAlternatePath,
                VARIABLES.notificationPushDispatchUrlBetaPrimary,
                VARIABLES.notificationPushDispatchUrlBetaAlternatePath
            ]) {
                if (
                    len(trim(VARIABLES.notificationPushDispatchUrlCandidate))
                    AND arrayFindNoCase(VARIABLES.notificationPushDispatchUrls, VARIABLES.notificationPushDispatchUrlCandidate) EQ 0
                ) {
                    arrayAppend(VARIABLES.notificationPushDispatchUrls, VARIABLES.notificationPushDispatchUrlCandidate);
                }
            }
        </cfscript>

        <cfscript>
            VARIABLES.notificationPushDispatchHttpStatusCode = "";
            VARIABLES.notificationPushDispatchHttpStatusPrefix = "";
        </cfscript>

        <cfloop array="#VARIABLES.notificationPushDispatchUrls#" item="VARIABLES.notificationPushDispatchUrlAttempt">
            <cfhttp
                url="#VARIABLES.notificationPushDispatchUrlAttempt#"
                method="post"
                result="notificationPushDispatchHttpResult"
                timeout="#VARIABLES.notificationPushDispatchTimeoutValue#"
                throwOnError="false">
                <cfhttpparam type="header" name="Content-Type" value="application/json; charset=utf-8"/>
                <cfhttpparam type="header" name="X-RR-Handoff-Timestamp" value="#VARIABLES.notificationPushDispatchTimestamp#"/>
                <cfhttpparam type="header" name="X-RR-Handoff-Signature" value="#VARIABLES.notificationPushDispatchSignature#"/>
                <cfhttpparam type="body" value="#VARIABLES.notificationPushDispatchRawBody#"/>
            </cfhttp>

            VARIABLES.notificationPushDispatchHttpStatusCode = structKeyExists(notificationPushDispatchHttpResult, "statusCode") ? trim(notificationPushDispatchHttpResult.statusCode) : "";
            VARIABLES.notificationPushDispatchHttpStatusPrefix = len(VARIABLES.notificationPushDispatchHttpStatusCode) GTE 3 ? left(VARIABLES.notificationPushDispatchHttpStatusCode, 3) : "";

            if (VARIABLES.notificationPushDispatchHttpStatusPrefix NEQ "404") {
                break;
            }
        </cfloop>

        <cfscript>
            VARIABLES.notificationPushDispatchResponse = {};

            if (structKeyExists(notificationPushDispatchHttpResult, "fileContent") AND isJSON(toString(notificationPushDispatchHttpResult.fileContent))) {
                VARIABLES.notificationPushDispatchResponse = deserializeJSON(toString(notificationPushDispatchHttpResult.fileContent));
            }

            VARIABLES.notificationPushDispatchStatusValue = structKeyExists(VARIABLES.notificationPushDispatchResponse, "status")
                ? trim(VARIABLES.notificationPushDispatchResponse.status)
                : "";
            VARIABLES.notificationPushDispatchNotificationsValue = structKeyExists(VARIABLES.notificationPushDispatchResponse, "notificationsProcessed")
                AND isNumeric(VARIABLES.notificationPushDispatchResponse.notificationsProcessed)
                ? int(VARIABLES.notificationPushDispatchResponse.notificationsProcessed)
                : 0;
            VARIABLES.notificationPushDispatchDeliveriesValue = structKeyExists(VARIABLES.notificationPushDispatchResponse, "deliveriesAccepted")
                AND isNumeric(VARIABLES.notificationPushDispatchResponse.deliveriesAccepted)
                ? int(VARIABLES.notificationPushDispatchResponse.deliveriesAccepted)
                : 0;
            VARIABLES.notificationPushDispatchSubscriptionsValue = structKeyExists(VARIABLES.notificationPushDispatchResponse, "subscriptionsTargeted")
                AND isNumeric(VARIABLES.notificationPushDispatchResponse.subscriptionsTargeted)
                ? int(VARIABLES.notificationPushDispatchResponse.subscriptionsTargeted)
                : 0;

            VARIABLES.notificationPushAllowLocalFallback = (
                NOT findNoCase("://beta.roadrunners.run/", VARIABLES.notificationPushDispatchUrlPrimary)
            );

            if (
                NOT len(VARIABLES.notificationPushDispatchStatusValue)
                AND VARIABLES.notificationPushAllowLocalFallback
                AND isStruct(VARIABLES.notificationLocalPushConfig)
                AND structKeyExists(VARIABLES.notificationLocalPushConfig, "enabled")
                AND VARIABLES.notificationLocalPushConfig.enabled
                AND len(trim(VARIABLES.notificationLocalPushConfig.publicKey))
                AND len(trim(VARIABLES.notificationLocalPushConfig.privateKey))
            ) {
                VARIABLES.notificationPushDirectEnvironment = "prod";
                VARIABLES.notificationPushDispatchIdsList = arrayToList(VARIABLES.notificationPushDispatchIds);
            }
        </cfscript>

        <cfif NOT len(VARIABLES.notificationPushDispatchStatusValue)
            AND VARIABLES.notificationPushAllowLocalFallback
            AND isStruct(VARIABLES.notificationLocalPushConfig)
            AND structKeyExists(VARIABLES.notificationLocalPushConfig, "enabled")
            AND VARIABLES.notificationLocalPushConfig.enabled
            AND len(trim(VARIABLES.notificationLocalPushConfig.publicKey))
            AND len(trim(VARIABLES.notificationLocalPushConfig.privateKey))>
            <cfquery name="qNotificationPushDirectEnvironmentCounts">
                SELECT sub.ambiente, count(*) AS total
                FROM tb_push_subscription sub
                LEFT JOIN tb_push_preference pref
                    ON pref.id_usuario = sub.id_usuario
                WHERE sub.id_usuario IN (
                    SELECT DISTINCT ntf.id_usuario
                    FROM tb_notifica ntf
                    WHERE ntf.id_notifica IN (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationPushDispatchIdsList#" list="true"/>
                    )
                )
                  AND sub.ativo = true
                  AND coalesce(pref.receber_push, true) = true
                GROUP BY sub.ambiente
                ORDER BY count(*) DESC, sub.ambiente
            </cfquery>

            <cfset VARIABLES.notificationPushDirectEnvironment = VARIABLES.notificationPushDirectPreferredEnvironment/>
            <cfset VARIABLES.notificationPushDirectHasPreferredEnvironment = false/>

            <cfif qNotificationPushDirectEnvironmentCounts.recordcount>
                <cfquery name="qNotificationPushDirectPreferredEnvironment" dbtype="query">
                    SELECT total
                    FROM qNotificationPushDirectEnvironmentCounts
                    WHERE ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationPushDirectPreferredEnvironment#"/>
                </cfquery>

                <cfset VARIABLES.notificationPushDirectHasPreferredEnvironment = qNotificationPushDirectPreferredEnvironment.recordcount GT 0/>

                <cfif NOT qNotificationPushDirectPreferredEnvironment.recordcount
                    AND VARIABLES.notificationPushDirectPreferredEnvironment EQ "prod">
                    <cfset VARIABLES.notificationPushDirectEnvironment = qNotificationPushDirectEnvironmentCounts.ambiente[1]/>
                </cfif>
            </cfif>

            <cfquery name="qNotificationPushDirectTargets">
                SELECT DISTINCT sub.id_push_subscription, sub.endpoint
                FROM tb_push_subscription sub
                LEFT JOIN tb_push_preference pref
                    ON pref.id_usuario = sub.id_usuario
                WHERE sub.id_usuario IN (
                    SELECT DISTINCT ntf.id_usuario
                    FROM tb_notifica ntf
                    WHERE ntf.id_notifica IN (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationPushDispatchIdsList#" list="true"/>
                    )
                )
                  AND sub.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationPushDirectEnvironment#"/>
                  AND sub.ativo = true
                  AND coalesce(pref.receber_push, true) = true
            </cfquery>

            <cfset VARIABLES.notificationPushDirectDeliveriesAccepted = 0/>
            <cfset VARIABLES.notificationPushDirectRejected401 = 0/>
            <cfset VARIABLES.notificationPushDirectRejected403 = 0/>
            <cfset VARIABLES.notificationPushDirectRejected404 = 0/>
            <cfset VARIABLES.notificationPushDirectRejected410 = 0/>
            <cfset VARIABLES.notificationPushDirectRejectedOther = 0/>

            <cfoutput query="qNotificationPushDirectTargets">
                <cfset VARIABLES.notificationPushDirectAudience = notificationPushExtractAudience(qNotificationPushDirectTargets.endpoint)/>
                <cfset VARIABLES.notificationPushDirectJwt = notificationPushGenerateVapidJwt(
                    VARIABLES.notificationPushDirectAudience,
                    VARIABLES.notificationLocalPushConfig.subject,
                    VARIABLES.notificationLocalPushConfig.privateKey
                )/>

                <cfhttp url="#qNotificationPushDirectTargets.endpoint#" method="post" result="notificationPushDirectHttpResult" timeout="15" throwOnError="false">
                    <cfhttpparam type="header" name="TTL" value="300">
                    <cfhttpparam type="header" name="Urgency" value="normal">
                    <cfhttpparam type="header" name="Authorization" value="vapid t=#VARIABLES.notificationPushDirectJwt#, k=#VARIABLES.notificationLocalPushConfig.publicKey#">
                </cfhttp>

                <cfset VARIABLES.notificationPushDirectStatusCode = structKeyExists(notificationPushDirectHttpResult, "statusCode") ? trim(notificationPushDirectHttpResult.statusCode) : ""/>
                <cfset VARIABLES.notificationPushDirectStatusPrefix = len(VARIABLES.notificationPushDirectStatusCode) GTE 3 ? left(VARIABLES.notificationPushDirectStatusCode, 3) : ""/>

                <cfif VARIABLES.notificationPushDirectStatusPrefix EQ "403"
                    OR VARIABLES.notificationPushDirectStatusPrefix EQ "404"
                    OR VARIABLES.notificationPushDirectStatusPrefix EQ "410">
                    <cfquery>
                        UPDATE tb_push_subscription
                        SET
                            ativo = false,
                            revoked_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>,
                            updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                        WHERE id_push_subscription = <cfqueryparam cfsqltype="cf_sql_integer" value="#qNotificationPushDirectTargets.id_push_subscription#"/>
                    </cfquery>
                </cfif>

                <cfif VARIABLES.notificationPushDirectStatusPrefix EQ "201"
                    OR VARIABLES.notificationPushDirectStatusPrefix EQ "202"
                    OR VARIABLES.notificationPushDirectStatusPrefix EQ "204">
                    <cfset VARIABLES.notificationPushDirectDeliveriesAccepted += 1/>
                <cfelseif VARIABLES.notificationPushDirectStatusPrefix EQ "401">
                    <cfset VARIABLES.notificationPushDirectRejected401 += 1/>
                <cfelseif VARIABLES.notificationPushDirectStatusPrefix EQ "403">
                    <cfset VARIABLES.notificationPushDirectRejected403 += 1/>
                <cfelseif VARIABLES.notificationPushDirectStatusPrefix EQ "404">
                    <cfset VARIABLES.notificationPushDirectRejected404 += 1/>
                <cfelseif VARIABLES.notificationPushDirectStatusPrefix EQ "410">
                    <cfset VARIABLES.notificationPushDirectRejected410 += 1/>
                <cfelse>
                    <cfset VARIABLES.notificationPushDirectRejectedOther += 1/>
                </cfif>
            </cfoutput>

            <cfif VARIABLES.notificationPushDirectDeliveriesAccepted GT 0>
                <cfset VARIABLES.notificationPushDispatchStatusValue = "sent"/>
                <cfset VARIABLES.notificationPushDispatchNotificationsValue = arrayLen(VARIABLES.notificationPushDispatchIds)/>
                <cfset VARIABLES.notificationPushDispatchDeliveriesValue = VARIABLES.notificationPushDirectDeliveriesAccepted/>
                <cfset VARIABLES.notificationPushDispatchSubscriptionsValue = qNotificationPushDirectTargets.recordcount/>
            <cfelseif qNotificationPushDirectTargets.recordcount>
                <cfif VARIABLES.notificationPushDirectRejected401 GT 0>
                    <cfset VARIABLES.notificationPushDispatchStatusValue = "local_vapid_401"/>
                <cfelseif VARIABLES.notificationPushDirectRejected403 GT 0>
                    <cfset VARIABLES.notificationPushDispatchStatusValue = "local_vapid_403"/>
                <cfelseif VARIABLES.notificationPushDirectRejected404 GT 0>
                    <cfset VARIABLES.notificationPushDispatchStatusValue = "local_subscription_404"/>
                <cfelseif VARIABLES.notificationPushDirectRejected410 GT 0>
                    <cfset VARIABLES.notificationPushDispatchStatusValue = "local_subscription_410"/>
                <cfelse>
                    <cfset VARIABLES.notificationPushDispatchStatusValue = "local_dispatch_failed"/>
                </cfif>
            <cfelseif qNotificationPushDirectEnvironmentCounts.recordcount
                AND (
                    VARIABLES.notificationPushDirectPreferredEnvironment EQ "prod"
                    OR VARIABLES.notificationPushDirectHasPreferredEnvironment
                )>
                <cfset VARIABLES.notificationPushDispatchStatusValue = "no_active_subscriptions"/>
            <cfelseif qNotificationPushDirectEnvironmentCounts.recordcount>
                <cfset VARIABLES.notificationPushDispatchStatusValue = "no_active_subscriptions"/>
            <cfelse>
                <cfset VARIABLES.notificationPushDispatchStatusValue = "no_active_subscriptions"/>
            </cfif>
        </cfif>

        <cfscript>
            if (
                NOT len(VARIABLES.notificationPushDispatchStatusValue)
                AND NOT len(VARIABLES.notificationPushDispatchHttpStatusPrefix)
                AND VARIABLES.notificationPushAllowLocalFallback
                AND (
                    NOT isStruct(VARIABLES.notificationLocalPushConfig)
                    OR NOT structKeyExists(VARIABLES.notificationLocalPushConfig, "enabled")
                    OR NOT VARIABLES.notificationLocalPushConfig.enabled
                    OR NOT len(trim(VARIABLES.notificationLocalPushConfig.publicKey))
                    OR NOT len(trim(VARIABLES.notificationLocalPushConfig.privateKey))
                )
            ) {
                VARIABLES.notificationPushDispatchStatusValue = "local_push_unconfigured";
            }

            if (
                len(VARIABLES.notificationPushDispatchStatusValue)
                AND (
                    VARIABLES.notificationPushDispatchHttpStatusPrefix EQ "200"
                    OR VARIABLES.notificationPushDispatchHttpStatusPrefix EQ "201"
                    OR VARIABLES.notificationPushDispatchHttpStatusPrefix EQ "202"
                )
            ) {
                VARIABLES.notificationSendPushRedirectSuffix =
                    "&envio_push_status=" & urlEncodedFormat(VARIABLES.notificationPushDispatchStatusValue) &
                    "&envio_push_notifications=" & VARIABLES.notificationPushDispatchNotificationsValue &
                    "&envio_push_deliveries=" & VARIABLES.notificationPushDispatchDeliveriesValue &
                    "&envio_push_subscriptions=" & VARIABLES.notificationPushDispatchSubscriptionsValue;
            } else if (len(VARIABLES.notificationPushDispatchStatusValue)) {
                VARIABLES.notificationSendPushRedirectSuffix =
                    "&envio_push_status=" & urlEncodedFormat(VARIABLES.notificationPushDispatchStatusValue);
            } else if (len(VARIABLES.notificationPushDispatchHttpStatusPrefix)) {
                VARIABLES.notificationSendPushRedirectSuffix =
                    "&envio_push_status=" & urlEncodedFormat("http_" & VARIABLES.notificationPushDispatchHttpStatusPrefix);
            } else {
                VARIABLES.notificationSendPushRedirectSuffix = "&envio_push_status=dispatch_failed";
            }
        </cfscript>
    </cfif>

    <cflocation addtoken="false" url="#VARIABLES.notificationSendRedirectUrl#&envio_status=enviado&envio_total=#qNotificationSendInsert.recordcount##VARIABLES.notificationSendPushRedirectSuffix#"/>
</cfif>

<cfquery name="qNotificationSendCountries">
    SELECT DISTINCT usr.pais,
           COALESCE(iso.nome_pais_br, iso.nome_pais, usr.pais) AS nome_pais
    FROM tb_usuarios usr
    LEFT JOIN tb_paises_iso3166 iso ON iso.cod_alpha2 = usr.pais
    WHERE usr.pais IS NOT NULL
      AND trim(usr.pais) <> ''
    ORDER BY COALESCE(iso.nome_pais_br, iso.nome_pais, usr.pais)
</cfquery>

<cfquery name="qNotificationSendStates">
    SELECT DISTINCT coalesce(usr.estado, pag.uf) AS estado
    FROM tb_usuarios usr
    LEFT JOIN LATERAL (
        SELECT pg.uf
        FROM tb_paginas pg
        WHERE pg.id_usuario_cadastro = usr.id
          AND pg.tag_prefix = 'atleta'
        ORDER BY pg.verificado DESC, pg.id_pagina DESC
        LIMIT 1
    ) pag ON true
    WHERE coalesce(usr.estado, pag.uf) IS NOT NULL
      AND trim(coalesce(usr.estado, pag.uf)) <> ''
    ORDER BY coalesce(usr.estado, pag.uf)
</cfquery>

<cfquery name="qNotificationSendRecipientsCount">
    SELECT count(*) AS total
    FROM (
        SELECT DISTINCT usr.id
        FROM tb_usuarios usr
        LEFT JOIN LATERAL (
            SELECT pg.id_pagina,
                   pg.verificado,
                   pg.uf
            FROM tb_paginas pg
            WHERE pg.id_usuario_cadastro = usr.id
              AND pg.tag_prefix = 'atleta'
            ORDER BY pg.verificado DESC, pg.id_pagina DESC
            LIMIT 1
        ) pag ON true
        WHERE 1 = 1
        <cfif len(trim(VARIABLES.notificationSendUserId)) AND isNumeric(VARIABLES.notificationSendUserId)>
            AND usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationSendUserId#"/>
        </cfif>
        <cfif VARIABLES.notificationSendAdmin EQ "true">
            AND usr.is_admin = true
        <cfelseif VARIABLES.notificationSendAdmin EQ "false">
            AND coalesce(usr.is_admin, false) = false
        </cfif>
        <cfif VARIABLES.notificationSendStrava EQ "true">
            AND (usr.strava_id IS NOT NULL OR (usr.strava_code IS NOT NULL AND trim(usr.strava_code) <> ''))
        <cfelseif VARIABLES.notificationSendStrava EQ "false">
            AND usr.strava_id IS NULL
            AND (usr.strava_code IS NULL OR trim(usr.strava_code) = '')
        </cfif>
        <cfif VARIABLES.notificationSendDesafio EQ "true">
            AND EXISTS (
                SELECT 1
                FROM desafios des
                WHERE des.id_usuario = usr.id
            )
        <cfelseif VARIABLES.notificationSendDesafio EQ "false">
            AND NOT EXISTS (
                SELECT 1
                FROM desafios des
                WHERE des.id_usuario = usr.id
            )
        </cfif>
        <cfif VARIABLES.notificationSendAssessoria EQ "true">
            AND trim(coalesce(usr.assessoria, '')) <> ''
        <cfelseif VARIABLES.notificationSendAssessoria EQ "false">
            AND trim(coalesce(usr.assessoria, '')) = ''
        </cfif>
        <cfif VARIABLES.notificationSendDev EQ "true">
            AND usr.is_dev = true
        <cfelseif VARIABLES.notificationSendDev EQ "false">
            AND coalesce(usr.is_dev, false) = false
        </cfif>
        <cfif VARIABLES.notificationSendPartner EQ "true">
            AND usr.is_partner = true
        <cfelseif VARIABLES.notificationSendPartner EQ "false">
            AND coalesce(usr.is_partner, false) = false
        </cfif>
        <cfif VARIABLES.notificationSendGenero EQ "M" OR VARIABLES.notificationSendGenero EQ "F">
            AND upper(left(coalesce(usr.genero, usr.strava_sex, ''), 1)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendGenero#"/>
        </cfif>
        <cfif VARIABLES.notificationSendCBAT EQ "true">
            AND trim(coalesce(usr.cbat, '')) <> ''
        <cfelseif VARIABLES.notificationSendCBAT EQ "false">
            AND trim(coalesce(usr.cbat, '')) = ''
        </cfif>
        <cfif len(trim(VARIABLES.notificationSendPais))>
            AND usr.pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendPais#"/>
        </cfif>
        <cfif len(trim(VARIABLES.notificationSendEstado))>
            AND coalesce(usr.estado, pag.uf) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendEstado#"/>
        </cfif>
        <cfif VARIABLES.notificationSendVerificado EQ "true">
            AND coalesce(pag.verificado, false) = true
        <cfelseif VARIABLES.notificationSendVerificado EQ "false">
            AND coalesce(pag.verificado, false) = false
        </cfif>
    ) notification_send_preview
</cfquery>

<cfquery name="qNotificationSendRecipientsPreview">
    SELECT DISTINCT ON (usr.id)
           usr.id,
           usr.name,
           usr.email,
           usr.is_admin,
           usr.is_dev,
           usr.is_partner,
           usr.strava_id,
           usr.strava_code,
           usr.assessoria,
           usr.cbat,
           usr.pais,
           coalesce(usr.estado, pag.uf) AS estado,
           upper(left(coalesce(usr.genero, usr.strava_sex, ''), 1)) AS genero,
           pag.id_pagina,
           coalesce(pag.nome, usr.name) AS pagina_nome,
           pag.tag,
           coalesce(pag.verificado, false) AS verificado,
           EXISTS (
               SELECT 1
               FROM desafios des
               WHERE des.id_usuario = usr.id
           ) AS inscrito_desafio
    FROM tb_usuarios usr
    LEFT JOIN LATERAL (
        SELECT pg.id_pagina,
               pg.nome,
               pg.tag,
               pg.verificado,
               pg.uf
        FROM tb_paginas pg
        WHERE pg.id_usuario_cadastro = usr.id
          AND pg.tag_prefix = 'atleta'
        ORDER BY pg.verificado DESC, pg.id_pagina DESC
        LIMIT 1
    ) pag ON true
    WHERE 1 = 1
    <cfif len(trim(VARIABLES.notificationSendUserId)) AND isNumeric(VARIABLES.notificationSendUserId)>
        AND usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationSendUserId#"/>
    </cfif>
    <cfif VARIABLES.notificationSendAdmin EQ "true">
        AND usr.is_admin = true
    <cfelseif VARIABLES.notificationSendAdmin EQ "false">
        AND coalesce(usr.is_admin, false) = false
    </cfif>
    <cfif VARIABLES.notificationSendStrava EQ "true">
        AND (usr.strava_id IS NOT NULL OR (usr.strava_code IS NOT NULL AND trim(usr.strava_code) <> ''))
    <cfelseif VARIABLES.notificationSendStrava EQ "false">
        AND usr.strava_id IS NULL
        AND (usr.strava_code IS NULL OR trim(usr.strava_code) = '')
    </cfif>
    <cfif VARIABLES.notificationSendDesafio EQ "true">
        AND EXISTS (
            SELECT 1
            FROM desafios des
            WHERE des.id_usuario = usr.id
        )
    <cfelseif VARIABLES.notificationSendDesafio EQ "false">
        AND NOT EXISTS (
            SELECT 1
            FROM desafios des
            WHERE des.id_usuario = usr.id
        )
    </cfif>
    <cfif VARIABLES.notificationSendAssessoria EQ "true">
        AND trim(coalesce(usr.assessoria, '')) <> ''
    <cfelseif VARIABLES.notificationSendAssessoria EQ "false">
        AND trim(coalesce(usr.assessoria, '')) = ''
    </cfif>
    <cfif VARIABLES.notificationSendDev EQ "true">
        AND usr.is_dev = true
    <cfelseif VARIABLES.notificationSendDev EQ "false">
        AND coalesce(usr.is_dev, false) = false
    </cfif>
    <cfif VARIABLES.notificationSendPartner EQ "true">
        AND usr.is_partner = true
    <cfelseif VARIABLES.notificationSendPartner EQ "false">
        AND coalesce(usr.is_partner, false) = false
    </cfif>
    <cfif VARIABLES.notificationSendGenero EQ "M" OR VARIABLES.notificationSendGenero EQ "F">
        AND upper(left(coalesce(usr.genero, usr.strava_sex, ''), 1)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendGenero#"/>
    </cfif>
    <cfif VARIABLES.notificationSendCBAT EQ "true">
        AND trim(coalesce(usr.cbat, '')) <> ''
    <cfelseif VARIABLES.notificationSendCBAT EQ "false">
        AND trim(coalesce(usr.cbat, '')) = ''
    </cfif>
    <cfif len(trim(VARIABLES.notificationSendPais))>
        AND usr.pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendPais#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificationSendEstado))>
        AND coalesce(usr.estado, pag.uf) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationSendEstado#"/>
    </cfif>
    <cfif VARIABLES.notificationSendVerificado EQ "true">
        AND coalesce(pag.verificado, false) = true
    <cfelseif VARIABLES.notificationSendVerificado EQ "false">
        AND coalesce(pag.verificado, false) = false
    </cfif>
    ORDER BY usr.id, pag.verificado DESC, pag.id_pagina DESC
    LIMIT 100
</cfquery>
