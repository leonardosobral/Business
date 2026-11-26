// Isolated CFML contract fixture. No network or real payment methods.
component output=false {
    public any function init() {
        this.quoteId=createObject("java","java.util.UUID").randomUUID().toString();
        this.ref=""; this.paymentOrders=[]; this.marks=0; this.links=0; this.failure="";
        return this;
    }
    public boolean function allows(required numeric accountId) {return accountId==21;}
    public any function payments() {return this;}
    public struct function createPaymentLink(required string code,required numeric cents,required string title) {
        if (compare(code,this.ref) || cents!=10991) throw(message="checkout contract");
        this.links++;
        return {success=true,paymentLink={url="https://payment-link-v3-sdx.pagar.me/test-only"}};
    }
    public struct function listOrdersByCode(required string code) {return {success=true,orders=this.paymentOrders};}
    public struct function call(required string method,required string path,struct payload={}) {
        if (this.failure=="unavailable") throw(type="Zones.Unavailable",message="Simulated outage");
        switch(path) {
            case "/quotes":
                if (payload.product!="sponsor_zone" || payload.geojson.type!="Polygon"
                    || arrayLen(payload.geojson.coordinates[1])!=4) throw(message="quote contract");
                return {product="sponsor_zone",quote_id=this.quoteId,total_brl=109.91,hex_count=3,
                    expires_at="2027-02-01T15:30:00Z",conflicts=this.failure=="conflict" ? [{}] : []};
            case "/holds":
                if (this.failure=="expired") throw(type="Zones.Input",message="A cotação venceu.");
                if (payload.quote_id!=this.quoteId) throw(message="hold contract");
                return {quote_id=this.quoteId,expires_at="2027-02-01T15:35:00Z"};
            case "/orders":
                if (payload.quote_id!=this.quoteId || payload.payment.mode!="external" || payload.sponsor.display_name!="Marca piloto") throw(message="order contract");
                this.ref=payload.payment.external_reference;
                return snapshot("pending_payment");
            case "/orders/501/mark-paid":
                if (payload.amount_brl!=109.91 || compare(payload.external_reference,this.ref)) throw(message="paid contract");
                this.marks++; return snapshot("active");
            case "/analytics/orders/501":
                return {order_id=501,summary={passes=10,unique_runners="<5"}};
        }
        throw(message="Unexpected fixture path");
    }
    public struct function snapshot(required string status) {
        return {product="sponsor_zone",source="api",id=501,total_brl=109.91,external_reference=this.ref,status=arguments.status,sponsor_name="Marca piloto"};
    }
}
