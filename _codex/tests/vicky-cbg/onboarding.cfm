<cfscript>
// Read-only aggregate funnel. Never return identities, telephone numbers or tokens.
q=queryExecute("WITH enrolled AS (
 SELECT DISTINCT u.id,u.telefone_usuario
 FROM desafios d JOIN tb_usuarios u ON u.id=d.id_usuario
 LEFT JOIN tb_usuarios_gestao g ON g.id_usuario=u.id
 WHERE (d.produto='circuitobrasilgigante' OR d.desafio='circuitobrasilgigante') AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false)
), flags AS (
 SELECT e.id,length(trim(coalesce(e.telefone_usuario,'')))>0 AS phone_in_account,
 EXISTS(SELECT 1 FROM tb_paginas_usuarios pu JOIN tb_paginas p ON p.id_pagina=pu.id_pagina WHERE pu.id_usuario=e.id AND length(trim(coalesce(p.whatsapp,'')))>0) AS whatsapp_in_profile,
 EXISTS(SELECT 1 FROM tb_vicky_channel_link l WHERE l.id_usuario=e.id AND l.provider='meta_cloud' AND l.channel='whatsapp' AND l.status='active') AS linked,
 p.id_usuario IS NOT NULL AS has_preferences,
 coalesce(p.whatsapp_enabled,false) AS notifications_enabled,
 p.whatsapp_consented_at IS NOT NULL AS has_optin_date,
 p.revoked_at IS NOT NULL AS revoked,
 coalesce(p.whatsapp_consent_source,'') AS source
 FROM enrolled e LEFT JOIN tb_vicky_notificacao_preferencia p ON p.id_usuario=e.id
)
SELECT count(*) AS enrolled,
count(*) FILTER(WHERE phone_in_account) AS account_phone_present,
count(*) FILTER(WHERE whatsapp_in_profile) AS profile_whatsapp_present,
count(*) FILTER(WHERE linked) AS linked,
count(*) FILTER(WHERE has_preferences) AS has_preferences,
count(*) FILTER(WHERE notifications_enabled AND has_optin_date AND NOT revoked) AS opted_in,
count(*) FILTER(WHERE linked AND notifications_enabled AND has_optin_date AND NOT revoked) AS eligible,
count(*) FILTER(WHERE NOT linked) AS missing_link,
count(*) FILTER(WHERE linked AND NOT (notifications_enabled AND has_optin_date AND NOT revoked)) AS linked_without_reminder_optin,
string_agg(DISTINCT source,',') FILTER(WHERE linked AND notifications_enabled AND has_optin_date AND NOT revoked) AS eligible_optin_sources
FROM flags",{},{datasource='runner_dba',timeout=15});writeOutput(serializeJSON(q));
q=queryExecute("SELECT enabled,pilot_only FROM tb_vicky_channel_config WHERE provider='meta_cloud' AND channel='whatsapp'",{},{datasource='runner_dba'});writeOutput('CHANNEL ' & serializeJSON(q));
writeOutput('VICKY_CBG_ONBOARDING_PASSED');
</cfscript>
