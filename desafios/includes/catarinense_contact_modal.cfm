<link rel="stylesheet" href="/desafios/assets/catarinense-contact.css?v=20261013-1"/>
<dialog id="catarinenseContactDialog" class="catarinense-contact-dialog" aria-labelledby="catarinenseContactTitle">
  <header class="catarinense-contact-header">
    <div><span class="catarinense-contact-eyebrow">CONTATO DO ATLETA</span><h2 id="catarinenseContactTitle" class="h5 mb-0">Dados e canais de contato</h2></div>
    <button type="button" class="btn btn-sm btn-outline-secondary shadow-0" data-contact-close aria-label="Fechar contato" autofocus><i class="fa-solid fa-xmark" aria-hidden="true"></i></button>
  </header>
  <div class="catarinense-contact-body">
    <div class="catarinense-contact-identity">
      <img data-contact-avatar class="catarinense-contact-avatar" src="/assets/user.png" alt="" width="112" height="112"/>
      <div><h3 data-contact-name class="h4 mb-1"></h3><div data-contact-id class="small text-muted mb-2"></div><div data-contact-location class="small"></div><div data-contact-team class="small text-muted mt-1"></div></div>
    </div>
    <div class="catarinense-contact-fields">
      <div class="catarinense-contact-field">
        <span class="catarinense-contact-label"><i class="fa-regular fa-envelope" aria-hidden="true"></i>E-mail</span>
        <div class="catarinense-contact-value"><a data-contact-value="email"></a><a data-contact-action="email" class="catarinense-contact-action" aria-label="Enviar e-mail" title="Enviar e-mail" hidden><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></div>
      </div>
      <div class="catarinense-contact-field">
        <span class="catarinense-contact-label"><i class="fa-solid fa-phone" aria-hidden="true"></i>Telefone</span>
        <div class="catarinense-contact-value"><a data-contact-value="phone"></a><a data-contact-action="phone" class="catarinense-contact-action" aria-label="Ligar para o atleta" title="Ligar" hidden><i class="fa-solid fa-phone" aria-hidden="true"></i></a></div>
      </div>
      <div class="catarinense-contact-field">
        <span class="catarinense-contact-label"><i class="fa-brands fa-whatsapp" aria-hidden="true"></i>WhatsApp</span>
        <div class="catarinense-contact-value"><a data-contact-value="whatsapp" target="_blank" rel="noopener noreferrer"></a><a data-contact-action="whatsapp" class="catarinense-contact-action is-whatsapp" target="_blank" rel="noopener noreferrer" aria-label="Chamar no WhatsApp" title="Chamar no WhatsApp" hidden><i class="fa-brands fa-whatsapp" aria-hidden="true"></i></a></div>
        <small data-contact-whatsapp-source class="text-muted"></small>
      </div>
      <div class="catarinense-contact-field">
        <span class="catarinense-contact-label"><i class="fa-brands fa-instagram" aria-hidden="true"></i>Instagram</span>
        <div class="catarinense-contact-value"><a data-contact-value="instagram" target="_blank" rel="noopener noreferrer"></a><a data-contact-action="instagram" class="catarinense-contact-action" target="_blank" rel="noopener noreferrer" aria-label="Abrir Instagram" title="Abrir Instagram" hidden><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></div>
      </div>
    </div>
    <p class="small text-muted mb-0 mt-3">Dados cadastrados pelo atleta. O WhatsApp usa o contato do perfil ou, na ausência dele, o telefone informado.</p>
  </div>
  <footer class="catarinense-contact-footer">
    <a data-contact-action="profile" class="btn btn-sm btn-outline-secondary" target="_blank" rel="noopener noreferrer" hidden><i class="fa-regular fa-user me-1" aria-hidden="true"></i>Perfil no RR</a>
    <a data-contact-action="chat" class="btn btn-sm btn-warning" target="_blank" rel="noopener noreferrer" hidden><i class="fa-regular fa-comments me-1" aria-hidden="true"></i>Chat no Road Runners</a>
    <button type="button" class="btn btn-sm btn-outline-secondary ms-auto" data-contact-close>Fechar</button>
  </footer>
</dialog>
<script src="/desafios/assets/catarinense-contact.js?v=20261013-1" defer></script>
