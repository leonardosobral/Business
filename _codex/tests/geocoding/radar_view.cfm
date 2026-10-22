<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.geoCanAdmin=true;
VARIABLES.geoRadarReady=true;
VARIABLES.geoRadarStats={total=200,mapped=145,coveragePercent=72.50,confirmed=45,legacy=95,suspicious=5,absent=55,next30=30,next90=70,later=100,measuredAt="20/10/2026 13:45:00"};
VARIABLES.geoRadarStates=queryNew("state_code,eligible_total,mapped_total,coverage_percent,confirmed_total,legacy_total,suspicious_total,absent_total","varchar,integer,integer,double,integer,integer,integer,integer",[{state_code="SC",eligible_total=100,mapped_total=80,coverage_percent=80,confirmed_total=30,legacy_total=48,suspicious_total=2,absent_total=20}]);
VARIABLES.geoRadarRows=queryNew("id_evento,nome_evento,starts,ends,cidade,estado,quality,review_reason,geocoding_status,changed_at","integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar",[{id_evento=100,nome_evento="<script>alert(1)</script>",starts="21/10/2026",ends="21/10/2026",cidade="Florianópolis",estado="SC",quality="suspicious",review_reason="provenance_coordinate_mismatch",geocoding_status="needs_review",changed_at="20/10/2026 13:40:00"}]);
VARIABLES.geoRadarPage=1;VARIABLES.geoRadarSearch="Maratona";VARIABLES.geoRadarQuality="suspicious";VARIABLES.geoRadarHorizon="90";VARIABLES.geoRadarUf="SC";VARIABLES.geoRadarHasNext=true;
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/radar_view.cfm";}
check(find("Cobertura do Radar",rendered) AND find("Confirmadas",rendered) AND find("Legadas",rendered) AND find("Suspeitas",rendered) AND find("Ausentes",rendered),"Coverage view names all quality classes");
check(!find("<script>alert",rendered) AND find("&lt;script&gt;alert",rendered),"Event names are escaped");
check(find("72",rendered),"Coverage percentage is visible");
check(find(encodeForHTML("20/10/2026 13:45:00"),rendered),"Coverage measurement time is visible");
check(find('name="qualidade"',rendered) AND find('value="suspicious" selected',rendered) AND find('name="horizonte"',rendered) AND find('value="90" selected',rendered),"Quality and horizon filters preserve selection");
check(find("Próxima",rendered) AND find("pagina=2",rendered),"Bounded rows expose next-page navigation");
check(!findNoCase("geoapify",rendered) AND !findNoCase("apikey",rendered) AND !reFindNoCase('<form[^>]+method="post"',rendered),"Coverage view has no provider detail or mutation form");
VARIABLES.geoRadarRows=queryNew("id_evento,nome_evento,starts,ends,cidade,estado,quality,review_reason,geocoding_status,changed_at");VARIABLES.geoRadarHasNext=false;
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/radar_view.cfm";}
check(find("Nenhum evento encontrado",rendered),"Coverage view has a useful empty state");
VARIABLES.geoRadarReady=false;savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/radar_view.cfm";}
check(find("Cobertura indisponível",rendered),"Missing shared schema is reported without breaking the module");
writeOutput("GEO_RADAR_VIEW_PASSED");
</cfscript>
