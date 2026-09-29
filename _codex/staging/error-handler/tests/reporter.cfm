<cfscript>
checks=[];
function check(ok,label){if(!ok)throw(type="TestFailure",message=label);arrayAppend(checks,label);}
r=new services.ErrorReporter();
e={type="expression",message="Variable CART is undefined.",detail="token=private-test-value",tagContext=[{template="/var/www/roadrunners.com.br/busca/index.cfm",line=17}]};
a=r.describe(e,"onRequest","roadrunners.run","/busca/index.cfm?token=private-test-value","test-id");
b=r.describe(e,"onRequest","roadrunners.run","/busca/index.cfm?x=2","another-id");
check(a.fingerprint==b.fingerprint,"Same error ignores query and request ID");
check(!find("private-test-value",serializeJSON(a)),"Private request and exception detail never retained");
check(a.status==500 && a.message=="Variable CART is undefined.","Internal failure retains safe diagnosis and status 500");
e.message="Variable ORDER is undefined.";
check(a.fingerprint!=r.describe(e,"onRequest","roadrunners.run","/busca/index.cfm","x").fingerprint,"Different code errors remain distinct");
db={type="database",message="Error Executing Database Query.",sqlstate="23505",detail="Key (email)=(first@example.test) already exists.",tagContext=[{template="/var/www/roadrunners.com.br/inscricao/index.cfm",line=5}]};
da=r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","one");db.detail="Key (email)=(second@example.test) already exists.";
check(da.fingerprint==r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","two").fingerprint,"Same SQL failure deduplicates changing input values");
db.sqlstate="23502";db.detail='null value in column "email" of relation "users" violates not-null constraint';
da=r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","one");db.detail='null value in column "name" of relation "users" violates not-null constraint';
check(da.fingerprint!=r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","two").fingerprint,"Different SQL columns remain separate failures");
db.sqlstate="22P02";db.detail='invalid input syntax for type integer: "malicious-one"';
da=r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","one");db.detail='invalid input syntax for type integer: "malicious-two"';
check(da.fingerprint==r.describe(db,"onRequest","roadrunners.run","/inscricao/index.cfm","two").fingerprint,"Invalid SQL input deduplicates quoted payloads");
s={};q=r.reserve(s,a.fingerprint,1000);check(q.allowed,"First alert allowed");
check(!r.reserve(s,a.fingerprint,1001).allowed,"Repeated alert suppressed");
check(!r.reserve(s,a.fingerprint,1899).allowed,"Silence covers full 15 minutes");
q=r.reserve(s,a.fingerprint,1900);check(q.allowed && q.occurrences==3,"Next allowed alert reports suppressed occurrences");
s={};allowed=0;for(i=1;i<=50;i++){if(r.reserve(s,hash(i),1000).allowed)allowed++;}
check(allowed==15,"Global cap counts two recipients per alert");
check(!r.reserve(s,"new",4599).allowed,"Rolling hour cap holds across clock hour boundaries");
check(r.reserve(s,"new",4601).allowed,"Global budget recovers after rolling hour");
s={};for(i=1;i<=1100;i++)r.reserve(s,hash(i),1000);
check(structCount(s.signatures)<=1000,"Untrusted distinct failures cannot grow limiter indefinitely");
check(!r.describe(e,"onRequest","dev.roadrunners.run","/x","x").notify,"Development errors do not send production alerts");
check(!r.describe(e,"onRequest","untrusted.example","/x","x").notify,"Unknown host cannot create alert stream");
check(r.describe({message="secret injected <script>"},"OnApplicationStart","roadrunners.run","/","x").message=="Erro interno ao processar a solicitação.","Incomplete bootstrap exception uses safe generic message");
writeOutput(serializeJSON({ok=true,checks=checks}));
</cfscript>
