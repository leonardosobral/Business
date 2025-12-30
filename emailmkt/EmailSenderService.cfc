component
{
  public function enviarEmail(assunto, conteudo, emailDestinatario, nomeDestinatario)
  {
    var nome = nomeDestinatario;

    conteudo = ReReplace(conteudo,'\[nome_candidato\]', REReplace(LCase(nome), "(^|\s)([á-úÁ-Úa-zA-ZçÇ])", "\1\U\2", "all"), "all");

    var header = getHTTPRequestData().headers;

    if (isDefined('header.origin')) {
      conteudo = ReReplace(conteudo,'\[host_sistema\]', header.origin, "all");
    } else {
      conteudo = ReReplace(conteudo,'\[host_sistema\]', "*", "all");
    }

    try{
      // Set up the mail server settings
      var mailServer = "smtp.mandrillapp.com";
      var mailPort = 587;
      var mailUsername = "RunnerHub";
      var mailPassword = "md-kHpL53XqZM3olhBw2z1t1w";
      var emailBody = conteudo;
      // Define the email variables
      var from = "Road Runners <contato@roadrunners.run>";
      var to = "#nome# <#emailDestinatario#>";
      var subject = "#assunto#";
      var charset = "utf-8";
      var type = "html";
      var mailContent = emailBody;
      // Create the mail object and set properties
      mail = new mail();
      mail.setFrom(from);
      mail.setTo(to);
      mail.setSubject(subject);
      mail.setCharset(charset);
      mail.setType(type);
      mail.setBody(mailContent);
      // Set mail server settings
      mail.setServer(mailServer);
      mail.setPort(mailPort);
      mail.setUsername(mailUsername);
      mail.setPassword(mailPassword);
      // Send the email
      mail.send();
      return "OK";

    } catch(any e){
        return "ERRO";
    }
  }
}
