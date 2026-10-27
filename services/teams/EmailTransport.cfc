component output=false {
    private struct function settings() {
        var environment=createObject('java','java.lang.System').getenv();
        var businessLocalConfig={};
        if(fileExists(expandPath('/config/business.local.cfm')))include '/config/business.local.cfm';
        if(structKeyExists(VARIABLES,'businessLocalConfig')&&isStruct(VARIABLES.businessLocalConfig))structAppend(businessLocalConfig,VARIABLES.businessLocalConfig,true);
        return {
            username=structKeyExists(environment,'RR_MANDRILL_USERNAME')?trim(environment['RR_MANDRILL_USERNAME']):(structKeyExists(businessLocalConfig,'mandrillUsername')?trim(businessLocalConfig.mandrillUsername):''),
            password=structKeyExists(environment,'RR_MANDRILL_PASSWORD')?trim(environment['RR_MANDRILL_PASSWORD']):(structKeyExists(businessLocalConfig,'mandrillPassword')?trim(businessLocalConfig.mandrillPassword):'')
        };
    }
    public boolean function configured() {var config=settings();return len(config.username)>0&&len(config.password)>0;}
    public string function enviarEmail(required string assunto,required string conteudo,required string emailDestinatario,required string nomeDestinatario) {
        var address=trim(emailDestinatario);
        if(!isValid('email',address)||reFind('[,;<>\r\n]',address))return 'ERRO';
        var config=settings();if(!len(config.username)||!len(config.password))return 'ERRO';
        var safeSubject=left(reReplace(assunto,'[\r\n]',' ','all'),200);
        try {
            cfmail(server='smtp.mandrillapp.com',port=587,username=config.username,password=config.password,from='Road Runners <contato@roadrunners.run>',to=address,subject=safeSubject,charset='utf-8',type='html',useTLS=true,spoolenable=false,timeout=20) {
                writeOutput(conteudo);
            }
            return 'OK';
        }catch(any failed){writeLog(file='teams-mail',type='error',text='smtp_failed type=' & failed.type);return 'ERRO';}
    }
}
