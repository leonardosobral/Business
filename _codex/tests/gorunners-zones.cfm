<!--- Run only inside the isolated ColdFusion test application with its transaction-local test table. --->
<cfscript>
function check(required boolean condition,required string label) {
    if (!condition) throw(type="Zones.Test",message=label);
    arrayAppend(passed,label);
}
function delivery(required string kind,required string stamp,required struct snapshot) {
    return {event=arguments.kind,created_at=arguments.stamp,data={order=arguments.snapshot}};
}
if (!(request.gorunnersTestFixture ?: false)) abort;
passed=[]; fake=new GoRunnersZoneFake(); svc=new ads.gorunners.ZoneSales(fake,"runner_dba");
fields={zone_start="2027-02-10",zone_end="2027-03-12",zone_area="[[-46.66,-23.58],[-46.65,-23.58],[-46.65,-23.59]]"};
buyer={zone_brand="Marca piloto",zone_customer="Cliente de teste",zone_email="teste@example.org"};
transaction {
    try {
        fake.failure="conflict";
        try {svc.quote(21,132,fields);throw(message="expected conflict");} catch (Zones.Input expected) {}
        check(svc.recent(21).recordCount==0,"conflito sem cotação local");
        fake.failure="";
        ref=svc.quote(21,132,fields); row=svc.sale(21,ref);
        check(row.amount_cents==10991 && svc.recent(22).recordCount==0,"total em centavos e lista por conta");
        try {svc.sale(22,ref);throw(message="expected missing");} catch (Zones.Missing expected) {}
        check(true,"acesso direto bloqueado para outra conta");
        fake.failure="expired";
        try {svc.reserve(row);throw(message="expected expiry");} catch (Zones.Input expected) {}
        check(!len(svc.sale(21,ref).game_status ?: ""),"reserva vencida não fecha venda");
        fake.failure=""; svc.reserve(row);row=svc.sale(21,ref);
        svc.order(row,buyer);row=svc.sale(21,ref);svc.order(row,buyer);
        check(row.order_id==501 && svc.recent(21).recordCount==1,"reserva e pedido único");
        svc.checkout(row);svc.checkout(row);
        check(fake.links==1 && svc.sale(21,ref).checkout_state=="ready","checkout único mesmo com repetição");
        p={id="or_fixture",code=ref,status="paid",chargeStatus="paid",currency="BRL",amountCents=10991,
           chargePaidCents=1,chargeCount=1,paidAt="2027-02-01T15:10:00Z"};
        fake.paymentOrders=[p];svc.paymentEvent(ref);
        check(fake.marks==0 && svc.sale(21,ref).checkout_state=="review","divergência bloqueia confirmação");
        p.chargePaidCents=10991;fake.paymentOrders=[p];fake.failure="unavailable";
        try {svc.paymentEvent(ref);throw(message="expected outage");} catch (Zones.Unavailable expected) {}
        check(len(svc.sale(21,ref).received_at) && svc.sale(21,ref).game_status=="pending_payment","recebimento preservado após falha no jogo");
        fake.failure="";svc.paymentEvent(ref);svc.paymentEvent(ref);
        check(fake.marks==1 && svc.sale(21,ref).game_status=="active","retentativa confirma uma única vez");
        ev=delivery("order.activated","2027-02-10T04:00:00Z",fake.snapshot("active"));
        svc.gameEvent(ev);svc.gameEvent(ev);
        svc.gameEvent(delivery("order.created","2027-02-01T15:00:00Z",fake.snapshot("pending_payment")));
        check(len(svc.sale(21,ref).activated_at) && svc.sale(21,ref).game_status=="active","entregas repetidas e fora de ordem");
        check(svc.report(row).unique_runners=="<5","relatório agregado");
        svc.gameEvent(delivery("order.expired","2027-03-12T03:00:00Z",fake.snapshot("expired")));
        check(svc.sale(21,ref).game_status=="expired","fim da veiculação");
    } finally {transaction action="rollback";}
}
writeOutput(serializeJSON(passed));
</cfscript>
