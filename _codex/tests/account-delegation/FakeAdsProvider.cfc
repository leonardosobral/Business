component {
    this.calls=0;
    this.uncertain=false;
    this.revoke=false;
    public struct function getStatus(){return {ready=true,enabled=true,errorCode=''};}
    public numeric function getMinimumAmountCents(){return 5000;}
    public numeric function getPaymentLinkExpiresMinutes(){return 30;}
    public boolean function isCheckoutUrlAllowed(required string url){return left(arguments.url,len('https://checkout.example.test/'))=='https://checkout.example.test/';}
    public struct function createPaymentLink(required string code,required numeric amount){
        this.calls++;
        // Different real connection proves the service released its account locks before HTTP.
        transaction {
            queryExecute('SELECT id_conta FROM tb_contas WHERE id_conta IN(101,102) FOR UPDATE NOWAIT',{},{datasource='business_delegation_test'});
            if(this.revoke) queryExecute("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001",{},{datasource='business_delegation_test'});
        }
        if(this.uncertain){this.uncertain=false;return {success=false,errorCode='provider_unavailable',message='Unknown provider result'};}
        return {success=true,paymentLink={id='pl_' & replace(code,'RHADS-',''),url='https://checkout.example.test/' & code}};
    }
}
