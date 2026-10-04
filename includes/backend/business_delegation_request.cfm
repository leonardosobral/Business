<!--- Shared early HTTP boundary. Never accept a target, identity, mode or authority from FORM/URL. --->
<cfif NOT structKeyExists(REQUEST,"businessAccessBoundaryLoaded")>
    <cfset REQUEST.businessAccessBoundaryLoaded=true/>
    <cfset REQUEST.businessDelegationEnabled=structKeyExists(APPLICATION,"businessAccountDelegationEnabled") AND APPLICATION.businessAccountDelegationEnabled/>
    <cfset REQUEST.businessDelegationIdentity=createObject("component","services.BusinessAuthSession").delegationIdentity(SESSION)/>
    <cfset REQUEST.businessAccessInvalid=structKeyExists(SESSION,"businessAccessSelectionInvalid") AND SESSION.businessAccessSelectionInvalid/>
    <cfif REQUEST.businessDelegationEnabled OR REQUEST.businessAccessInvalid OR structKeyExists(SESSION,"businessAccessSelection") OR structKeyExists(FORM,"business_access_token")>
        <cfset REQUEST.businessDelegationService=createObject("component","services.BusinessAccountDelegation").init("runnerhub",REQUEST.businessDelegationEnabled)/>
        <cfset REQUEST.businessRequestBoundary=createObject("component","services.accountDelegation.RequestBoundary").init("runnerhub",REQUEST.businessDelegationEnabled)/>
        <cfset REQUEST.businessDelegationRawBody=""/>
        <cfif CGI.request_method EQ "POST" AND findNoCase("application/x-www-form-urlencoded",CGI.content_type)>
            <cfset REQUEST.businessDelegationRawBody=getHttpRequestData().content/>
            <cfif NOT isSimpleValue(REQUEST.businessDelegationRawBody)><cfset REQUEST.businessDelegationRawBody=toString(REQUEST.businessDelegationRawBody)/></cfif>
        </cfif>
        <cfif NOT structKeyExists(REQUEST,"businessTargetPath")><cfset REQUEST.businessTargetPath=CGI.script_name/></cfif>
        <cfset REQUEST.businessDelegationMultipartValid=true/>
        <cfif CGI.request_method EQ "POST" AND findNoCase("multipart/form-data",CGI.content_type)>
            <!--- Read native part metadata, never parse/copy upload bytes or change FORM behavior.
                  Adobe RequestFacade loses multipart parameters; its FORM parts retain occurrences.
                  Lucee's HTTPServletRequestWrap preserves each original value. Unknown APIs fail closed. --->
            <cfset REQUEST.businessDelegationMultipartValid=false/>
            <cfset REQUEST.businessDelegationParts=[]/>
            <cftry>
                <cfif findNoCase("Lucee",SERVER.coldfusion.productname)>
                    <cfset REQUEST.businessDelegationServlet=getPageContext().getRequest()/>
                    <cfif REQUEST.businessDelegationServlet.getClass().getName() NEQ "lucee.runtime.net.http.HTTPServletRequestWrap">
                        <cfthrow type="BusinessDelegation.Unavailable" message="Multipart metadata unavailable"/>
                    </cfif>
                    <cfset REQUEST.businessDelegationParameterNames=REQUEST.businessDelegationServlet.getParameterNames()/>
                    <cfloop condition="REQUEST.businessDelegationParameterNames.hasMoreElements()">
                        <cfset REQUEST.businessDelegationParameterName=REQUEST.businessDelegationParameterNames.nextElement()/>
                        <cfset REQUEST.businessDelegationParameterValues=REQUEST.businessDelegationServlet.getParameterValues(REQUEST.businessDelegationParameterName)/>
                        <cfif isNull(REQUEST.businessDelegationParameterValues)><cfthrow type="BusinessDelegation.Unavailable" message="Multipart values unavailable"/></cfif>
                        <cfloop array="#REQUEST.businessDelegationParameterValues#" index="businessDelegationParameterValue">
                            <cfset arrayAppend(REQUEST.businessDelegationParts,{name=REQUEST.businessDelegationParameterName,isFile=false})/>
                        </cfloop>
                    </cfloop>
                <cfelse>
                    <cfset REQUEST.businessDelegationNativeParts=FORM.getPartsArray()/>
                    <cfscript>
                    for(businessDelegationNativePart in REQUEST.businessDelegationNativeParts) {
                        arrayAppend(REQUEST.businessDelegationParts,{name=businessDelegationNativePart.getName(),isFile=businessDelegationNativePart.isFile()});
                    }
                    </cfscript>
                </cfif>
                <cfset REQUEST.businessDelegationMultipartValid=createObject("component","services.accountDelegation.Policy").multipartFieldsValid(
                    REQUEST.businessTargetPath,CGI.request_method,FORM,REQUEST.businessDelegationParts)/>
                <cfcatch type="any"><cfset REQUEST.businessDelegationMultipartValid=false/></cfcatch>
            </cftry>
        </cfif>
        <!--- Compare-and-select and invalidation must be atomic across concurrent tabs. --->
        <cflock scope="session" type="exclusive" timeout="10">
        <cfset REQUEST.businessBoundaryResult=REQUEST.businessRequestBoundary.handle(
            REQUEST.businessDelegationIdentity,SESSION,REQUEST.businessTargetPath,CGI.request_method,URL,FORM,
            CGI.path_info,CGI.query_string,REQUEST.businessDelegationRawBody,REQUEST.businessDelegationMultipartValid)/>
        </cflock>
        <cfset REQUEST.businessAccessInvalid=REQUEST.businessBoundaryResult.invalid/>
        <cfif NOT structIsEmpty(REQUEST.businessBoundaryResult.context)>
            <cfset REQUEST.businessAccessContext=REQUEST.businessBoundaryResult.context/>
            <cfset REQUEST.businessDelegationIdentity.accessMode=REQUEST.businessAccessContext.accessMode/>
        </cfif>
        <cfif REQUEST.businessBoundaryResult.status NEQ 200>
            <cfheader statuscode="#REQUEST.businessBoundaryResult.status#" statustext="Access denied"/>
            <cfheader name="Cache-Control" value="no-store, private"/>
            <cfcontent type="text/html; charset=utf-8" reset="true"/>
            <cfoutput><p>Este acesso não está disponível. <a href="/selecionar-conta/">Escolher conta</a></p></cfoutput>
            <cfabort/>
        </cfif>
        <cfif REQUEST.businessBoundaryResult.selectionRequired AND NOT listFind("/selecionar-conta/,/selecionar-conta/index.cfm,/logout.cfm,/convites/,/convites/index.cfm",REQUEST.businessTargetPath)>
            <cflocation url="/selecionar-conta/" addtoken="false"/>
        </cfif>
        <cfif REQUEST.businessBoundaryResult.selectionChanged>
            <cflocation url="/" addtoken="false"/>
        </cfif>
    </cfif>
</cfif>
