<nav class="admin-suite-nav" aria-label="Ferramentas administrativas">
    <a class="admin-suite-nav-link<cfif VARIABLES.template EQ "/administracao/kanban/"> is-active</cfif>"
       href="/administracao/kanban/"
       <cfif VARIABLES.template EQ "/administracao/kanban/">aria-current="page"</cfif>>
        <span class="admin-suite-nav-icon" aria-hidden="true"><i class="fa-brands fa-trello"></i></span>
        <span class="admin-suite-nav-copy"><strong>Kanban</strong><small>Tarefas</small></span>
    </a>
    <a class="admin-suite-nav-link<cfif VARIABLES.template EQ "/administracao/agenda/"> is-active</cfif>"
       href="/administracao/agenda/"
       <cfif VARIABLES.template EQ "/administracao/agenda/">aria-current="page"</cfif>>
        <span class="admin-suite-nav-icon" aria-hidden="true"><i class="fa-regular fa-calendar"></i></span>
        <span class="admin-suite-nav-copy"><strong>Agenda</strong><small>Compromissos</small></span>
    </a>
    <a class="admin-suite-nav-link<cfif VARIABLES.template EQ "/administracao/drive/"> is-active</cfif>"
       href="/administracao/drive/"
       <cfif VARIABLES.template EQ "/administracao/drive/">aria-current="page"</cfif>>
        <span class="admin-suite-nav-icon" aria-hidden="true"><i class="fa-brands fa-google-drive"></i></span>
        <span class="admin-suite-nav-copy"><strong>Documentos</strong><small>Arquivos</small></span>
    </a>
</nav>
