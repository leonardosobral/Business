component output=false {
    public any function init(required any api, string datasource="runnerhub") {
        variables.api = arguments.api;
        variables.dsn = arguments.datasource;
        return this;
    }
    private query function db(required string sql, struct params={}) {
        var bindings={};
        for (var name in arguments.params) {
            bindings[name]={value=arguments.params[name],cfsqltype=listFindNoCase("account,actor,id,cents,hexes",name) ? "cf_sql_bigint" : "cf_sql_varchar"};
        }
        return queryExecute(arguments.sql,bindings,{datasource=variables.dsn,timeout=8});
    }
    private void function requireInput(required boolean valid, required string message) {
        if (!arguments.valid) throw(type="Zones.Input",message=arguments.message);
    }
    public query function recent(required numeric accountId) {
        return db("SELECT reference,order_id,sponsor_name,amount_cents,hex_count,starts_on,ends_on,
            received_at,activated_at,game_status,checkout_state,expires_at FROM public.business_gorunners_zone_sales
            WHERE account_id=:account AND (order_id IS NOT NULL OR expires_at > now())
            ORDER BY created_at DESC LIMIT 100",{account=arguments.accountId});
    }
    public struct function sale(required numeric accountId, required string reference) {
        var rows=db("SELECT * FROM public.business_gorunners_zone_sales WHERE account_id=:account AND reference=:ref",
            {account=arguments.accountId,ref=arguments.reference});
        if (!rows.recordCount) throw(type="Zones.Missing",message="Pedido não encontrado nesta conta.");
        return queryGetRow(rows,1);
    }
    private struct function area(required string raw) {
        requireInput(len(arguments.raw) <= 12000 && isJSON(arguments.raw),"Selecione a área no mapa.");
        var points=deserializeJSON(arguments.raw);
        requireInput(isArray(points) && arrayLen(points)>=3 && arrayLen(points)<=100,"Marque de 3 a 100 pontos no mapa.");
        var west=180; var east=-180; var south=90; var north=-90;
        var ring=[];
        for (var point in points) {
            requireInput(isArray(point) && arrayLen(point)==2 && isNumeric(point[1]) && isNumeric(point[2]),"Coordenadas inválidas.");
            var x=val(point[1]); var y=val(point[2]);
            requireInput(abs(x)<=180 && abs(y)<=85,"Coordenadas fora do mapa.");
            west=min(west,x); east=max(east,x); south=min(south,y); north=max(north,y);
            arrayAppend(ring,[x,y]);
        }
        // Bound work before the provider converts the polygon into H3 cells.
        requireInput((east-west)*(north-south) <= 0.1,"A seleção é muito extensa. Aproxime o mapa e reduza a área.");
        arrayAppend(ring,ring[1]);
        return {"type":"Polygon","coordinates":[ring]};
    }
    public string function quote(required numeric accountId,required numeric actorId,required struct fields) {
        var start=fields.zone_start ?: ""; var finish=fields.zone_end ?: "";
        requireInput(reFind("^\d{4}-\d{2}-\d{2}$",start) && reFind("^\d{4}-\d{2}-\d{2}$",finish)
            && compare(finish,start)>0,"Confira as datas de início e término.");
        var quote=variables.api.call("POST","/quotes",{"product":"sponsor_zone","starts_on":start,"ends_on":finish,
            "geojson":area(fields.zone_area ?: "")});
        requireInput(isArray(quote.conflicts) && !arrayLen(quote.conflicts),"Há áreas ocupadas nesse período. Altere o desenho ou as datas.");
        var cents=round(quote.total_brl*100);
        requireInput(quote.product=="sponsor_zone" && isValid("guid",quote.quote_id) && cents>0 && cents<=2147483647
            && quote.hex_count>0 && quote.hex_count<=2500,"Cotação inválida.");
        var ref="RHGR-" & lCase(replace(createObject("java","java.util.UUID").randomUUID().toString(),"-","","all"));
        db("INSERT INTO public.business_gorunners_zone_sales(reference,account_id,actor_id,quote_id,amount_cents,hex_count,starts_on,ends_on,expires_at)
            VALUES(:ref,:account,:actor,cast(:quote as uuid),:cents,:hexes,cast(:start as date),cast(:finish as date),cast(:expiry as timestamptz))",
            {ref=ref,account=accountId,actor=actorId,quote=quote.quote_id,cents=cents,hexes=quote.hex_count,
            start=start,finish=finish,expiry=quote.expires_at});
        return ref;
    }
    public void function reserve(required struct row) {
        if (val(row.order_id ?: 0)) return;
        var hold=variables.api.call("POST","/holds",{"quote_id":row.quote_id & ""});
        requireInput(compareNoCase(hold.quote_id,row.quote_id)==0,"A reserva não corresponde à cotação.");
        db("UPDATE public.business_gorunners_zone_sales SET expires_at=cast(:expiry as timestamptz),game_status='held'
            WHERE reference=:ref AND order_id IS NULL",{expiry=hold.expires_at,ref=row.reference});
    }
    private boolean function matches(required struct row,required struct order) {
        return (order.product ?: "")=="sponsor_zone" && (order.source ?: "")=="api"
            && compare(order.external_reference ?: "",row.reference)==0
            && isNumeric(order.id ?: "") && int(order.id)>0
            && (!val(row.order_id ?: 0) || val(row.order_id)==val(order.id))
            && isNumeric(order.total_brl ?: "") && round(order.total_brl*100)==row.amount_cents;
    }
    public void function order(required struct row,required struct fields) {
        if (val(row.order_id ?: 0)) return;
        requireInput((row.game_status ?: "")=="held","Reserve a cotação antes de fechar o pedido.");
        var brand=trim(fields.zone_brand ?: ""); var customer=trim(fields.zone_customer ?: "");
        var email=trim(fields.zone_email ?: ""); var document=trim(fields.zone_document ?: "");
        var logo=trim(fields.zone_logo ?: "");
        requireInput(len(brand)>=2 && len(brand)<=80 && len(customer)>0 && len(customer)<=200
            && len(email)<=200 && isValid("email",email),"Confira marca, nome e e-mail do cliente.");
        requireInput(!len(logo) || (len(logo)<=1000 && reFindNoCase("^https://",logo) && isValid("url",logo)),"Informe uma URL HTTPS para a logo.");
        var data=variables.api.call("POST","/orders",{"quote_id":row.quote_id & "",
            "customer":{"name":customer,"email":email,"document":document},
            "sponsor":{"display_name":brand,"logo_url":logo},
            "payment":{"mode":"external","external_reference":row.reference}});
        requireInput(matches(row,data),"O pedido recebido não corresponde à cotação.");
        db("UPDATE public.business_gorunners_zone_sales SET order_id=:id,sponsor_name=:brand,game_status=:status
            WHERE reference=:ref AND order_id IS NULL",{id=data.id,brand=data.sponsor_name,status=data.status,ref=row.reference});
    }
    public void function checkout(required struct row) {
        requireInput(val(row.order_id ?: 0)>0 && listFind("draft,pending_payment",row.game_status ?: ""),
            "Este pedido não está aguardando pagamento.");
        var claim=db("UPDATE public.business_gorunners_zone_sales SET checkout_state='creating'
            WHERE reference=:ref AND checkout_state='new' AND received_at IS NULL AND game_status IN ('draft','pending_payment')
            RETURNING reference",{ref=row.reference});
        if (!claim.recordCount) return;
        // Claim is committed before contacting the provider. Ambiguous timeouts must never issue a second link.
        try {
            var result=variables.api.payments().createPaymentLink(row.reference,row.amount_cents,"Zona patrocinada GoRunners");
            if (!result.success) throw(type="Zones.Unavailable",message="O provedor não confirmou a criação da cobrança.");
            db("UPDATE public.business_gorunners_zone_sales SET checkout_state='ready',checkout_url=:url
                WHERE reference=:ref AND checkout_state='creating'",{url=result.paymentLink.url,ref=row.reference});
        } catch (any failure) {
            db("UPDATE public.business_gorunners_zone_sales SET checkout_state='review' WHERE reference=:ref AND checkout_state='creating'",{ref=row.reference});
            rethrow;
        }
    }
    // A webhook is only a wake-up. Verify the payment with the sandbox merchant before marking the game order paid.
    public void function reconcile(required struct row) {
        requireInput(val(row.order_id ?: 0)>0,"Crie o pedido antes de consultar o pagamento.");
        var payments=variables.api.payments().listOrdersByCode(row.reference);
        if (!payments.success) throw(type="Zones.Unavailable",message="Não foi possível consultar o pagamento.");
        var payment={};
        for (var item in payments.orders) {
            if (compare(item.code,row.reference)!=0) continue;
            if (listFindNoCase("refunded,chargedback,partial_canceled",item.chargeStatus) ||
                (item.status=="paid" && (item.chargeStatus!="paid" || item.chargeCount!=1 || item.currency!="BRL"
                || item.amountCents!=row.amount_cents || item.chargePaidCents!=row.amount_cents || !len(item.paidAt) || !structIsEmpty(payment)))) {
                db("UPDATE public.business_gorunners_zone_sales SET checkout_state='review' WHERE reference=:ref",{ref=row.reference});
                return;
            }
            if (item.status=="paid" && item.chargeStatus=="paid") payment=item;
        }
        if (structIsEmpty(payment)) return;
        var acknowledged=db("UPDATE public.business_gorunners_zone_sales SET provider_order=:provider,received_at=cast(:paid as timestamptz),
            checkout_state=CASE WHEN checkout_state='review' AND checkout_url IS NOT NULL THEN 'ready' ELSE checkout_state END
            WHERE reference=:ref AND (provider_order IS NULL OR provider_order=:provider) RETURNING game_status",
            {provider=payment.id,paid=payment.paidAt,ref=row.reference});
        if (!acknowledged.recordCount || !listFind("draft,pending_payment",acknowledged.game_status[1])) return;
        var confirmed=variables.api.call("POST","/orders/" & int(row.order_id) & "/mark-paid",
            {"paid_at":payment.paidAt,"amount_brl":row.amount_cents/100,"external_reference":row.reference});
        requireInput(matches(row,confirmed) && confirmed.status=="active","O jogo ainda não confirmou o pagamento.");
        db("UPDATE public.business_gorunners_zone_sales SET game_status='active'
            WHERE reference=:ref AND game_status IN ('draft','pending_payment')",{ref=row.reference});
    }
    public struct function report(required struct row) {
        requireInput(val(row.order_id ?: 0)>0,"Pedido sem relatório.");
        var report=variables.api.call("GET","/analytics/orders/" & int(row.order_id));
        requireInput(val(report.order_id ?: 0)==row.order_id && isStruct(report.summary ?: ""),"Relatório indisponível.");
        return report.summary;
    }
    public void function paymentEvent(required string ref) {
        var rows=db("SELECT * FROM public.business_gorunners_zone_sales WHERE reference=:ref AND order_id IS NOT NULL",{ref=arguments.ref});
        if (rows.recordCount && variables.api.allows(rows.account_id[1])) reconcile(queryGetRow(rows,1));
    }
    public void function gameEvent(required struct event) {
        var order=event.data.order;
        var ref=order.external_reference ?: "";
        if (!reFind("^RHGR-[0-9a-f]{32}$",ref) || (order.product ?: "")!="sponsor_zone") return;
        var rows=db("SELECT * FROM public.business_gorunners_zone_sales WHERE reference=:ref",{ref=ref});
        if (!rows.recordCount || !variables.api.allows(rows.account_id[1]) || !matches(queryGetRow(rows,1),order)) return;
        requireInput(listFind("draft,pending_payment,active,expired,cancelled,refunded",order.status)>0,"Estado de pedido inválido.");
        // Creation can arrive before the POST returns. Later/repeated deliveries must not rewind a terminal order.
        db("UPDATE public.business_gorunners_zone_sales SET order_id=:id,sponsor_name=:brand,game_status=:status,
            last_game_event=cast(:stamp as timestamptz),
            activated_at=CASE WHEN :kind='order.activated' THEN coalesce(activated_at,cast(:stamp as timestamptz)) ELSE activated_at END
            WHERE reference=:ref AND (order_id IS NULL OR order_id=:id)
            AND (last_game_event IS NULL OR last_game_event <= cast(:stamp as timestamptz))
            AND (coalesce(game_status,'') NOT IN ('active','expired','cancelled','refunded') OR :status NOT IN ('pending_payment','draft'))
            AND (coalesce(game_status,'') NOT IN ('expired','cancelled','refunded') OR :status IN ('expired','cancelled','refunded'))",
            {id=order.id,brand=order.sponsor_name,status=order.status,stamp=event.created_at,kind=event.event,ref=ref});
    }
}
