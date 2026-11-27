component output=false {
    public boolean function configured() {
        return new services.TransactionalMail().configured();
    }

    public string function enviarEmail(required string assunto,required string conteudo,required string emailDestinatario,required string nomeDestinatario) {
        var address=trim(emailDestinatario);
        if(!isValid('email',address)||reFind('[,;<>\r\n]',address))return 'ERRO';
        var safeSubject=left(reReplace(assunto,'[\r\n]',' ','all'),200);
        try {
            var config=new services.TransactionalMail().attributes();
            cfmail(attributeCollection=config,to=address,subject=safeSubject,charset='utf-8',type='html',spoolenable=false,timeout=20) {
                writeOutput(conteudo);
            }
            return 'OK';
        }catch(any failed){writeLog(file='teams-mail',type='error',text='smtp_failed type=' & failed.type);return 'ERRO';}
    }
}
