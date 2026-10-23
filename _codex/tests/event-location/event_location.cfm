<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
exists=fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & '../services/EventLocationPolicy.cfc');
check(exists,"The event editor has a country-aware location policy rather than requiring every city to be Brazilian");
p=new services.EventLocationPolicy();
pt=p.resolve({pais="PT",estado="13",regiao_internacional="Porto",cidade="Porto",endereco="Avenida da Boavista",coordenadas="41.1579,-8.6291"},{});
check(pt.pais EQ "PT" AND pt.cidade EQ "Porto" AND pt.estado EQ "13" AND pt.regionName EQ "Porto" AND pt.cod_cidade_null,"International cities do not need IBGE and preserve both the short region code and full name");
check(p.resolve({pais="SG",estado="",cidade="Singapore",endereco="",coordenadas=""},{}).estado EQ "","Foreign subdivisions are optional where they do not apply");
check(p.resolve({cidade="Porto",estado="XX",endereco="",coordenadas=""},{pais="PT"}).pais EQ "PT","Legacy submissions preserve an existing foreign country instead of silently forcing BR");
legacy=p.resolve({pais="PT",estado="XX",cidade="Porto",endereco="Endereço legado",coordenadas="local a confirmar"},{pais="PT",coordenadas="local a confirmar",endereco="Endereço legado"});
check(legacy.coordenadas EQ "local a confirmar","Unchanged legacy coordinates do not block unrelated basic edits");
longAddress=repeatString("A",513);legacy=p.resolve({pais="PT",estado="XX",cidade="Porto",endereco=longAddress,coordenadas=""},{pais="PT",endereco=longAddress});
check(legacy.endereco EQ longAddress,"An unchanged long legacy address is preserved rather than blocked or truncated");
br=p.resolve({pais="BR",estado="SC",cidade="4205407",endereco="Centro",coordenadas="-27.59,-48.54"},{});
check(br.pais EQ "BR" AND br.cidade EQ "Florianópolis" AND br.cod_cidade EQ 4205407 AND !br.cod_cidade_null,"Brazilian municipalities continue to use the authoritative city code and UF");
for(sample in [{pais="ZZ",estado="",cidade="Porto",endereco="",coordenadas=""},{pais="BR",estado="RJ",cidade="4205407",endereco="",coordenadas=""},{pais="PT",estado="Porto",cidade="",endereco="",coordenadas=""},{pais="PT",estado="Porto",cidade="Porto",endereco="",coordenadas="100,200"}]){
 denied=false;try{p.resolve(sample,{});}catch(BusinessDelegation.Validation invalid){denied=true;}check(denied,"Invalid country, municipality, city or coordinates cannot be saved");
}
denied=false;try{p.resolve({pais="PT",location_mode="br",estado="SC",cidade="4205407",endereco="",coordenadas=""},{});}catch(BusinessDelegation.Validation invalid){denied=true;}
check(denied,"A country switch without the corresponding international form cannot turn a Brazilian municipality code into a foreign city name");
countries=p.countries();found=false;for(country in countries)if(country.code EQ "PT" AND country.label EQ "Portugal")found=true;
check(found AND arrayLen(countries) GT 200,"The country selector includes Portugal and the international ISO country list");
writeOutput("GEO_EVENT_LOCATION_PASSED");
</cfscript>
