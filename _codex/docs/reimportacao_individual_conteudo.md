# Reimportação individual de conteúdo no Business

Em `/portal/conteudos/`, administradores veem a ação **Reimportar** em conteúdos vinculados a importadores compatíveis do News. Conteúdos manuais ou com importador sem suporte exibem a ação desabilitada.

O formulário envia ao backend do Business somente o `content_id` e o token CSRF da sessão. O backend assina `timestamp.corpo` com a credencial `APPLICATION.cronJobs.secrets.conteudo_internal` e chama `POST /api/admin/importers/reimport.cfm` no `APPLICATION.contentAdmin.baseUrl`.

O News é responsável por resolver e validar o importador. O retorno é mostrado como alerta na própria listagem. A reimportação atualiza os campos oriundos da fonte sem alterar publicação, estado editorial ou destaque.
