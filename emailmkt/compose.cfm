<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="row">
            <div class="col">
                <h3>Email Marketing</h3>
            </div>
            <div class="col text-end">
                <a href="fila.cfm" target="_blank"><button class="btn btn-outline-danger">Enviar Fila</button></a>
            </div>
          </div>

          <hr/>

            <cfhttp result="templateHTML" url="https://roadrunners.run/mail/20251227_todosantodia_pagamento.html"></cfhttp>
  
          <form>
              <label>Conteúdo (HTML)
                <textarea class="form-control" name="body_html" rows="12"><cfoutput>#htmlEditFormat(isDefined('templateHTML.filecontent') ? templateHTML.filecontent : '')#</cfoutput></textarea>
              </label>
          </form>

        </div>

      </div>

    </div>

  </div>

</section>

<script src="https://cdn.tiny.cloud/1/qyhsll57zrdqocv3z0c6z92ge88db2wygo5toc6fon8wtkd1/tinymce/7/tinymce.min.js" referrerpolicy="origin"></script>
<script>
document.addEventListener("DOMContentLoaded", function(){
  tinymce.init({
    selector: "textarea[name=\"body_html\"]",
    plugins: "link lists code image table",
    toolbar: "undo redo | bold italic underline | alignleft aligncenter alignright | bullist numlist | link image table | code",
    menubar: false,
    height: 420
  });
});
</script>

