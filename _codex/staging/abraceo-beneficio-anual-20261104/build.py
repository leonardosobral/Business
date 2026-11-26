from pathlib import Path
W=Path(__file__).resolve().parent

def read(n):return(W/'baseline'/n).read_text()
def out(n,s):
 p=W/'runtime'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
s=read('estudos/includes/StudyAccess.cfc')
helper='''    public struct function ensureAnnualBenefit(required any actorId,required any accessId) {
        actor(actorId);idp(accessId);
        var result={"benefit":{}};
        transaction {
            // Match redemption/revocation lock order: voucher, then access/campaign.
            var voucher=db("SELECT v.id FROM estudo.vouchers v JOIN estudo.acessos a ON a.voucher_id=v.id
                WHERE a.id=:a AND a.usuario_id=:u FOR UPDATE OF v",{a=idp(accessId),u=idp(actorId)});
            if(!voucher.recordCount) throw(type="StudyAccess.Access",message="Este acesso não está disponível para esta conta.");
            var source=db("SELECT a.id,a.voucher_id,c.id AS campaign_id,c.codigo AS campaign_code,c.beneficio_percentual,c.beneficio_produto_id,
                preview.ano AS preview_year,annual.tipo AS annual_type,annual.ano AS annual_year
                FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id
                JOIN estudo.campanhas c ON c.id=v.campanha_id AND c.produto_id=a.produto_id
                JOIN estudo.produtos preview ON preview.id=a.produto_id
                LEFT JOIN estudo.produtos annual ON annual.id=c.beneficio_produto_id
                WHERE a.id=:a AND a.usuario_id=:u AND a.status='ACTIVE' AND v.status='REDEEMED' AND v.resgatado_por=:u
                  AND preview.tipo='PREVIA' FOR SHARE OF a,c",{a=idp(accessId),u=idp(actorId)});
            if(!source.recordCount) throw(type="StudyAccess.Access",message="O resgate deste convite não está ativo para esta conta.");
            var origin=one(source);
            if(origin.beneficio_percentual==50 && (origin.annual_type!='ANUAL' || origin.annual_year!=origin.preview_year))
                throw(type="StudyAccess.Conflict",message="O benefício anual precisa ser conferido pela equipe do Business.");
            var current=db("SELECT b.id,b.usuario_id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status
                FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.acesso_id=:a",{a=idp(accessId)});
            if(current.recordCount) {
                var existing=one(current);
                if(existing.usuario_id!=toString(actorId) || (origin.beneficio_percentual==50 && existing.produto_id!=origin.beneficio_produto_id))
                    throw(type="StudyAccess.Conflict",message="O benefício deste convite precisa ser conferido pela equipe do Business.");
                // A repeated redemption must never reactivate a revoked benefit.
                result["benefit"]=existing;
            } else if(origin.beneficio_percentual==50) {
                var inserted=db("INSERT INTO estudo.beneficios(usuario_id,produto_id,acesso_id,percentual)
                    VALUES(:u,:p,:a,50) ON CONFLICT(acesso_id) DO NOTHING RETURNING id",
                    {u=idp(actorId),p=idp(origin.beneficio_produto_id),a=idp(accessId)});
                if(inserted.recordCount) audit(actorId,"ANNUAL_EARLY_PURCHASE_BENEFIT","benefit",inserted.id[1],
                    {"access_id":toString(accessId),"voucher_id":origin.voucher_id,"campaign":origin.campaign_code,"percent":50,"kind":"EARLY_PURCHASE"});
                result["benefit"]=one(db("SELECT b.id,b.usuario_id,b.produto_id,p.codigo AS produto_codigo,b.percentual,b.status
                    FROM estudo.beneficios b JOIN estudo.produtos p ON p.id=b.produto_id WHERE b.acesso_id=:a",{a=idp(accessId)}));
            }
        }
        return result;
    }
'''
needle='    public struct function redeem('
assert s.count(needle)==1;s=s.replace(needle,helper+needle)
needle='''                if(result.access.status!="ACTIVE") throw(type="StudyAccess.Access",message="O acesso deste convite foi revogado.");'''
assert s.count(needle)==1;s=s.replace(needle,needle+'\n                ensureAnnualBenefit(actorId,result.access.id);\n                result=accessResult(voucher.id);')
needle='''                if(campaign.beneficio_percentual==50) db("INSERT INTO estudo.beneficios(usuario_id,produto_id,acesso_id,percentual) VALUES(:u,:p,:a,50)",
                    {u=idp(actorId),p=idp(campaign.beneficio_produto_id),a=idp(grant.id)});'''
assert s.count(needle)==1;s=s.replace(needle,'                ensureAnnualBenefit(actorId,grant.id);')
out('estudos/includes/StudyAccess.cfc',s)

s=read('estudos/includes/FirstAccess.cfc')
assert s.count("c.beneficio_percentual=0")==1;s=s.replace("c.beneficio_percentual=0","c.beneficio_percentual IN (0,50)")
needle="            var access=uCase(mode)=='VOUCHER'?variables.study.redeem(actorId,value).access:cnpjGrant(u);"
assert s.count(needle)==1;s=s.replace(needle,"""            var access={};var annualBenefit={};
            if(uCase(mode)=='VOUCHER') {
                var redemption=variables.study.redeem(actorId,value);
                access=redemption.access;annualBenefit=redemption.benefit;
            } else {
                access=cnpjGrant(u);
                annualBenefit=variables.study.ensureAnnualBenefit(actorId,access.id).benefit;
            }""")
needle="'reader_url':'/estudos/leitor/?ano=2026','operational_access_granted':false"
assert s.count(needle)==1;s=s.replace(needle,"'reader_url':'/estudos/leitor/?ano=2026','benefit':annualBenefit,'operational_access_granted':false")
out('estudos/includes/FirstAccess.cfc',s)

s=read('estudos/primeiro-acesso/index.cfm').replace('primeiro-acesso.js?v=20261011-3','primeiro-acesso.js?v=20261104-beneficio50')
needle='<cfif NOT studyActor>'
card='''<section class="card benefit" aria-labelledby="annual-benefit-title"><span class="tag">BENEFÍCIO DO PRIMEIRO ACESSO</span><h2 id="annual-benefit-title">50% na compra antecipada do anual.</h2><p>Ao resgatar seu convite ou confirmar o primeiro acesso por CNPJ, o direito à compra antecipada da edição anual de 2026 com 50% de desconto fica registrado na sua conta pessoal.</p><p class="muted">A edição anual será comprada separadamente. Datas, preço e prazo de uso do benefício serão informados quando a oferta estiver confirmada.</p></section>
'''
assert s.count(needle)==1;s=s.replace(needle,card+needle,1)
needle='<p id="success-message"></p>'
assert s.count(needle)==1;s=s.replace(needle,needle+'<p id="annual-benefit-message" class="benefit" hidden><strong>Seu benefício de 50% na compra antecipada do anual de 2026 está registrado.</strong> <a href="/estudos/#anual">Consultar meu benefício →</a></p>')
out('estudos/primeiro-acesso/index.cfm',s)

s=read('estudos/primeiro-acesso/primeiro-acesso.js')
needle="$('success-message').textContent=`Representante registrado para ${data.company}. A leitura está disponível na sua conta pessoal.`;"
assert s.count(needle)==1;s=s.replace(needle,needle+"$('annual-benefit-message').hidden=!(data.benefit && data.benefit.status==='ELIGIBLE' && Number(data.benefit.percentual)===50);")
out('estudos/primeiro-acesso/primeiro-acesso.js',s)
print('Built 4 files: shared annual eligibility, CNPJ/voucher parity and user confirmation.')
