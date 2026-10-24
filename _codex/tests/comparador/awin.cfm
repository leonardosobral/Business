<cfscript>
if(!listFind('127.0.0.1,::1',CGI.remote_addr)){cfheader(statuscode=403);abort;}
s=new services.ComparadorAwinService().init('/var/tmp/business-awin-validation-20261017/fixture');
c={actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};passed=[];
function check(required boolean ok,required string label){if(!ok)throw(message=label);arrayAppend(passed,label);}
function forbidden(required struct context,required string action){var caught=false;try{if(action=='refresh')s.refresh(context);else s.dashboard(context);}catch(Comparador.Forbidden e){caught=true;}check(caught,'Permissão: ' & action & ' / ' & serializeJSON(context));}
forbidden({actorId=99,isAdmin=false,delegated=false},'dashboard');
forbidden({actorId=99,isAdmin=true,delegated=true},'dashboard');
forbidden({actorId=0,isAdmin=true,delegated=false},'dashboard');
forbidden({actorId=99,isAdmin=true,delegated=false,isPost=false,csrfVerified=true},'refresh');
forbidden({actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=false},'refresh');
check(s.safeUrl('javascript:alert(1)')=='','Esquema inseguro recusado');
check(s.safeUrl('https://user:password@example.com')=='','Credenciais no link recusadas');
check(s.safeUrl('https://evil.invalid/track',true)=='','Rastreamento fora da Awin recusado');
check(s.safeUrl('https://www.awin1.com/cread.php?awinmid=1&awinaffid=2',true)!='','Link Awin preservado');
check(s.safeUrl('https://www.awin1.com.evil.invalid/track',true)=='','Domínio parecido recusado');
check(s.localTime('2026-10-19T02:59:59+00:00')=='18/10/2026 23:59','Validade convertida para Brasília');
joined={'17652'={name='Nike BR'}};
raw={promotionId=1,advertiser={id=17652,name='Nike BR',joined=true},regions={all=false,list=[{countryCode='BR'}]},type='voucher',title='<script>alert(1)</script>',description='Descrição',terms='Condições',voucher={code='CORRE10'},startDate='2026-10-17T03:00:00+00:00',endDate='2026-10-19T02:59:59+00:00',url='https://www.nike.com.br/',urlTracking='https://www.awin1.com/cread.php?awinmid=17652&awinaffid=1455398'};
instant=createObject('java','java.time.Instant');
active=s.normalizePromotion(raw,joined,instant.parse('2026-10-18T12:00:00Z').toEpochMilli());
check(active.state=='active' AND active.code=='CORRE10','Cupom vigente preservado');
check(s.normalizePromotion(raw,joined,instant.parse('2026-10-17T02:59:59Z').toEpochMilli()).state=='upcoming','Oferta futura identificada');
check(s.normalizePromotion(raw,joined,instant.parse('2026-10-19T03:00:00Z').toEpochMilli()).state=='expired','Vencimento exato respeitado');
check(structIsEmpty(s.normalizePromotion(raw,{},instant.parse('2026-10-18T12:00:00Z').toEpochMilli())),'Anunciante sem associação recusado');
foreign=duplicate(raw);foreign.regions.list=[{countryCode='US'}];
check(structIsEmpty(s.normalizePromotion(foreign,joined)),'Região estrangeira recusada');
foreign.regions={all=true};check(!structIsEmpty(s.normalizePromotion(foreign,joined)),'Região global aceita');
foreign.advertiser.joined=false;check(structIsEmpty(s.normalizePromotion(foreign,joined)),'Associação suspensa recusada');
data=s.dashboard(c);
check(data.publisherId=='1455398','Conta conferida');
check(arrayLen(data.programmes)==10,'Dez programas lidos do snapshot real');
check(!structKeyExists(data,'token') AND !find('fixture-secret',serializeJSON(data)),'Credencial ausente da resposta');
before=hash(fileRead('/var/tmp/business-awin-validation-20261017/fixture/cache/snapshot.json'));
caught=false;try{s.refresh(c);}catch(Comparador.Awin e){caught=true;}
check(caught,'Falha da API tratada');
check(before==hash(fileRead('/var/tmp/business-awin-validation-20261017/fixture/cache/snapshot.json')),'Falha preserva consulta anterior');
temporary='/var/tmp/business-awin-validation-20261017/fixture/cache/atomic-test';
fileWrite(temporary,'old');fileWrite(temporary & '.new','new');
renamed=createObject('java','java.io.File').init(temporary & '.new').renameTo(createObject('java','java.io.File').init(temporary));
check(renamed AND trim(fileRead(temporary))=='new','Substituição atômica suportada');
fileDelete(temporary);
cfcontent(type='application/json');writeOutput(serializeJSON({passed=arrayLen(passed),checks=passed}));
</cfscript>
