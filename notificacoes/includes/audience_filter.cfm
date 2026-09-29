<!--- Used inside queries with recipient alias usr. Unknown recipients belong only to Todos. --->
<cfif VARIABLES.notificaPublico EQ "usuarios">
    AND usr.id IS NOT NULL AND coalesce(usr.is_admin, false) = false
<cfelseif VARIABLES.notificaPublico EQ "admins">
    AND usr.is_admin = true
</cfif>
