<cfscript>
checks=[];
scopes={"pt-BR"="não foram verificados",en="were not verified",es="no se verificaron"};
function check(required string name,required boolean passed){arrayAppend(checks,{name=name,passed=passed});}
</cfscript>
<cfinclude template="fact_review_data.cfm"/>
<cfset originalReviews=duplicate(VARIABLES.eventFactReviews)/>
<cfloop list="pt-BR,en,es" index="testLang">
 <cfloop list="valid,unknown,changed-start,changed-end,future-review,invalid-url,userinfo,backslash,escape,missing-field" index="testCase">
  <cfset REQUEST.lang=testLang/>
  <cfset VARIABLES.eventFactReviews=duplicate(originalReviews)/>
  <cfset qEvento=queryNew("id_evento,data_inicial,data_final","integer,date,date",[{id_evento=40833,data_inicial=createDate(2026,11,2),data_final=createDate(2026,11,2)}])/>
  <cfif testCase EQ "unknown"><cfset querySetCell(qEvento,"id_evento",999999)/></cfif>
  <cfif testCase EQ "changed-start"><cfset querySetCell(qEvento,"data_inicial",createDate(2026,11,1))/></cfif>
  <cfif testCase EQ "changed-end"><cfset querySetCell(qEvento,"data_final",createDate(2026,11,3))/></cfif>
  <cfif testCase EQ "future-review"><cfset VARIABLES.eventFactReviews["40833"].checkedAt="2099-01-01"/></cfif>
  <cfif testCase EQ "invalid-url"><cfset VARIABLES.eventFactReviews["40833"].sourceUrl="javascript:alert(1)"/></cfif>
  <cfif testCase EQ "userinfo"><cfset VARIABLES.eventFactReviews["40833"].sourceUrl="https://user@example.com/"/></cfif>
  <cfif testCase EQ "backslash"><cfset VARIABLES.eventFactReviews["40833"].sourceUrl="https://example.com/" & chr(92) & "test"/></cfif>
  <cfif testCase EQ "escape"><cfset VARIABLES.eventFactReviews["40833"].sourceLabel='<img src=x onerror="alert(1)">'/></cfif>
  <cfif testCase EQ "missing-field"><cfset structDelete(VARIABLES.eventFactReviews["40833"],"checkedAt")/></cfif>
  <cfsavecontent variable="rendered"><cfinclude template="fact_review.cfm"/></cfsavecontent>
  <cfset prefix=testLang & "/" & testCase/>
  <cfset shouldShow=listFind("valid,escape",testCase) GT 0/>
  <cfset check(prefix & "/visibility",(find('data-event-source="date-review"',rendered) GT 0) EQ shouldShow)/>
  <cfif shouldShow>
   <cfset check(prefix & "/date",find('datetime="2026-10-04"',rendered) GT 0 AND find('datetime="2026-11-02"',rendered) GT 0)/>
   <cfset check(prefix & "/scope",find(encodeForHTML(scopes[testLang]),rendered) GT 0)/>
   <cfset check(prefix & "/source",find(encodeForHTMLAttribute('https://www.liverun.com.br/etapa/live21k-rio-de-janeiro-2026'),rendered) GT 0)/>
   <cfset check(prefix & "/escape",find('<img',rendered) EQ 0)/>
  </cfif>
 </cfloop>
</cfloop>
<cfinclude template="fact_history_data.cfm"/>
<cfset originalHistory=duplicate(VARIABLES.eventFactHistory)/>
<cfloop list="pt-BR,en,es" index="testLang">
 <cfloop list="valid,unknown,changed-current,invalid-url,userinfo,backslash,future,invalid-date,unknown-field,missing-field,complex-field,scalar-row,scalar-list,equal-values,empty-detail,escape,fragment" index="testCase">
  <cfset REQUEST.lang=testLang/>
  <cfset VARIABLES.eventFactReviews=duplicate(originalReviews)/>
  <cfset VARIABLES.eventFactHistory=duplicate(originalHistory)/>
  <cfset qEvento=queryNew("id_evento,data_inicial,data_final","integer,date,date",[{id_evento=40833,data_inicial=createDate(2026,11,2),data_final=createDate(2026,11,2)}])/>
  <cfset h=VARIABLES.eventFactHistory["40833"][1]/>
  <cfif testCase EQ "unknown"><cfset querySetCell(qEvento,"id_evento",999999)/></cfif>
  <cfif testCase EQ "changed-current"><cfset querySetCell(qEvento,"data_inicial",createDate(2026,11,3))/></cfif>
  <cfif testCase EQ "invalid-url"><cfset h.sourceUrl="javascript:alert(1)"/></cfif>
  <cfif testCase EQ "userinfo"><cfset h.sourceUrl="https://user@example.com/"/></cfif>
  <cfif testCase EQ "backslash"><cfset h.sourceUrl="https://example.com/" & chr(92) & "test"/></cfif>
  <cfif testCase EQ "future"><cfset h.recordedAt="2099-01-01"/></cfif>
  <cfif testCase EQ "invalid-date"><cfset h.before="2026-02-30"/></cfif>
  <cfif testCase EQ "unknown-field"><cfset h.field="status"/></cfif>
  <cfif testCase EQ "missing-field"><cfset structDelete(h,"recordedAt")/></cfif>
  <cfif testCase EQ "complex-field"><cfset h.detail={invalid=true}/></cfif>
  <cfif testCase EQ "scalar-row"><cfset VARIABLES.eventFactHistory["40833"][1]="broken"/></cfif>
  <cfif testCase EQ "scalar-list"><cfset VARIABLES.eventFactHistory["40833"]="broken"/></cfif>
  <cfif testCase EQ "equal-values"><cfset h.before=h.after/></cfif>
  <cfif testCase EQ "empty-detail"><cfset h.detail=""/></cfif>
  <cfif testCase EQ "escape"><cfset h.detail='<img src=x onerror="alert(1)">'/><cfset h.sourceLabel='<script>alert(1)</script>'/></cfif>
  <cfif testCase EQ "fragment"><cfset h.sourceUrl="https://brasilcorrida.com.br/##/evento/tgs-run-2026"/></cfif>
  <cfsavecontent variable="rendered"><cfinclude template="fact_review.cfm"/></cfsavecontent>
  <cfset prefix=testLang & "/history/" & testCase/>
  <cfset shouldShow=listFind("valid,changed-current,escape,fragment",testCase) GT 0/>
  <cfset check(prefix & "/visibility",(find('data-event-source="correction-history"',rendered) GT 0) EQ shouldShow)/>
  <cfif shouldShow>
   <cfset check(prefix & "/collapsed",find('<details>',rendered) GT 0 AND reFindNoCase('<details[^>]+open',rendered) EQ 0)/>
   <cfset check(prefix & "/escape",find('<img',rendered) EQ 0 AND find('<script',rendered) EQ 0)/>
   <cfset check(prefix & "/dates",find('datetime="' & h.before & '"',rendered) GT 0 AND find('datetime="' & h.after & '"',rendered) GT 0)/>
   <cfset check(prefix & "/link",find(encodeForHTMLAttribute(h.sourceUrl),rendered) GT 0)/>
  </cfif>
  <cfif testCase EQ "changed-current"><cfset check(prefix & "/no-stale-verification",find('data-event-source="date-review"',rendered) EQ 0)/></cfif>
 </cfloop>
 <!--- Real curated entries must all render in each language; uncertain cases stay absent. --->
 <cfset VARIABLES.eventFactReviews=duplicate(originalReviews)/>
 <cfset VARIABLES.eventFactHistory=duplicate(originalHistory)/>
 <cfloop collection="#originalReviews#" item="eid">
  <cfset receipt=originalReviews[eid]/>
  <cfset qEvento=queryNew("id_evento,data_inicial,data_final","integer,date,date",[{id_evento=val(eid),data_inicial=parseDateTime(receipt.startDate),data_final=parseDateTime(receipt.endDate)}])/>
  <cfsavecontent variable="rendered"><cfinclude template="fact_review.cfm"/></cfsavecontent>
  <cfset check(testLang & "/curated/" & eid,find('data-event-source="date-review"',rendered) GT 0 AND find('data-event-source="correction-history"',rendered) GT 0 AND arrayLen(VARIABLES.eventHistoryRows) EQ arrayLen(originalHistory[eid]))/>
 </cfloop>
</cfloop>
<cfset check("conflicts-excluded",NOT structKeyExists(originalReviews,"46585") AND NOT structKeyExists(originalReviews,"45549") AND NOT structKeyExists(originalHistory,"46585") AND NOT structKeyExists(originalHistory,"45549"))/>
<cfloop list="pt-BR,en,es" index="testLang">
 <cfloop list="published,withdrawn,changed-start,changed-end,future,invalid-json,array,scalar,version,missing,complex,url,credentials,newline,escape,legacy-empty" index="testCase">
  <cfset REQUEST.lang=testLang/>
  <cfset VARIABLES.eventFactReviews=duplicate(originalReviews)/>
  <cfset VARIABLES.eventFactHistory=duplicate(originalHistory)/>
  <cfset receipt={version=1,state="published",reviewId="15",startDate="2026-11-02",endDate="2026-11-02",checkedAt="2026-10-04",sourceUrl="https://official.example.org/race?x=1&y=2"}/>
  <cfif testCase EQ 'withdrawn'><cfset receipt.state="withdrawn"/></cfif>
  <cfif testCase EQ 'future'><cfset receipt.checkedAt="2099-01-01"/></cfif>
  <cfif testCase EQ 'version'><cfset receipt.version=2/></cfif>
  <cfif testCase EQ 'missing'><cfset structDelete(receipt,'checkedAt')/></cfif>
  <cfif testCase EQ 'complex'><cfset receipt.sourceUrl={bad=1}/></cfif>
  <cfif testCase EQ 'url'><cfset receipt.sourceUrl='javascript:alert(1)'/></cfif>
  <cfif testCase EQ 'credentials'><cfset receipt.sourceUrl='https://user@official.example.org/'/></cfif>
  <cfif testCase EQ 'newline'><cfset receipt.sourceUrl='https://official.example.org/' & chr(10)/></cfif>
  <cfif testCase EQ 'escape'><cfset receipt.sourceUrl='https://official.example.org/?q=%3Cscript%3E&amp=1'/></cfif>
  <cfset publicJson=serializeJSON(receipt)/>
  <cfif testCase EQ 'invalid-json'><cfset publicJson='{'/></cfif>
  <cfif testCase EQ 'array'><cfset publicJson='[]'/></cfif>
  <cfif testCase EQ 'scalar'><cfset publicJson='1'/></cfif>
  <cfif testCase EQ 'legacy-empty'><cfset publicJson=''/></cfif>
  <cfset qEvento=queryNew("id_evento,data_inicial,data_final,conferencia_datas_publica","integer,date,date,varchar",[{id_evento=40833,data_inicial=createDate(2026,11,2),data_final=createDate(2026,11,2),conferencia_datas_publica=publicJson}])/>
  <cfif testCase EQ 'changed-start'><cfset querySetCell(qEvento,'data_inicial',createDate(2026,11,1))/></cfif>
  <cfif testCase EQ 'changed-end'><cfset querySetCell(qEvento,'data_final',createDate(2026,11,3))/></cfif>
  <cfsavecontent variable="rendered"><cfinclude template="fact_review.cfm"/></cfsavecontent>
  <cfset shouldShow=listFind('published,escape,legacy-empty',testCase) GT 0/>
  <cfset check('public/' & testLang & '/' & testCase,(find('data-event-source="date-review"',rendered) GT 0) EQ shouldShow)/>
  <cfset check('history preserved/' & testLang & '/' & testCase,find('data-event-source="correction-history"',rendered) GT 0)/>
  <cfif listFind('published,escape',testCase)><cfset check('new source/' & testLang & '/' & testCase,find('official.example.org',rendered) GT 0 AND find('<script',rendered) EQ 0)/></cfif>
 </cfloop>
</cfloop>
<cfoutput>#serializeJSON({checks=checks})#</cfoutput>
