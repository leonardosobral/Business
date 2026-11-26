<cfprocessingdirective pageencoding="utf-8"/>
<!--- Teams is not released to athletes. Stop before authentication or any service call. --->
<cfheader statuscode="404"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfoutput>{"success":false,"error":{"code":"not_available","message":"Recurso indisponível."}}</cfoutput>
<cfabort/>
