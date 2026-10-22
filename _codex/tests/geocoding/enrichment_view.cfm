<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.geoCanAdmin=true;VARIABLES.geoSelected={id=123,id_evento=456,status="needs_review",proposal_revision=7};
VARIABLES.geoDecision={enrichment={version=1,published=true,fields=[{field="organizador",label="Organizador",status="needs_review",trusted=true,current="Manual",value="<script>teste</script>",evidence={url="https://example.com/regulamento",excerpt="Organizador: <script>teste</script>."},reasons=[]},{field="pais",label="País",status="equivalent",trusted=true,current="BR",value="BR",evidence={},reasons=[]}]}};
savecontent variable="fixtureHtml" {include "../administracao/geolocalizacao/includes/enrichment_view.cfm";}
check(find("Organizador",fixtureHtml) AND find("Manual",fixtureHtml),"Review presents the current value alongside the extracted proposal");
check(!find("<script>",fixtureHtml) AND find("&lt;script&gt;",fixtureHtml),"All extracted values and evidence are escaped");
check(find('value="approve_field"',fixtureHtml) AND find('value="reject_field"',fixtureHtml) AND find('name="revision" value="7"',fixtureHtml),"Field review has explicit approval, preservation and revision control");
check(find("Equivalente",fixtureHtml) AND !find('name="attribute" value="2"',fixtureHtml),"Equivalent facts are informational, not another review task");
fixtureIndex=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../administracao/geolocalizacao/index.cfm");
check(find('geocoding.js?v=20261019-enrichment',fixtureIndex),"New tab behavior has a new asset version instead of reusing the old cached script");
writeOutput("GEO_ENRICHMENT_VIEW_PASSED");
</cfscript>
