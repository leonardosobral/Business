<cfquery name="qFilaEmail">
    SELECT * FROM tb_mailing
    WHERE data_disparo < now()
    AND enviado = false
    limit 10
</cfquery>
<cfif qFilaEmail.recordcount>
    <cfobject name="mailSender" component="emailmkt.EmailSenderService"/>
    <cfloop query="qFilaEmail">
        <cfinvoke component="#mailSender#" method="enviarEmail"
                assunto="#qFilaEmail.assunto#"
                conteudo="#qFilaEmail.conteudo#"
                emailDestinatario="#qFilaEmail.email#"
                nomeDestinatario="#qFilaEmail.nome#"
                returnVariable="res">
        <cfif res EQ "OK">
            <cfquery name="qUpdateFilaEmail">
                UPDATE tb_mailing
                SET data_envio = now()
                WHERE id_mailing = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFilaEmail.id_mailing#"/>
            </cfquery>
            <cfoutput>#res#</cfoutput>
        <cfelse>
            <cfquery name="qUpdateFilaEmail">
                UPDATE tb_mailing
                SET bounce = 'erro ao enviar'
                WHERE id_mailing = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFilaEmail.id_mailing#"/>
            </cfquery>
            <cfoutput>#res#</cfoutput>
        </cfif>
    </cfloop>
<cfelse>
    <p>Fila zerada</p>
</cfif>
