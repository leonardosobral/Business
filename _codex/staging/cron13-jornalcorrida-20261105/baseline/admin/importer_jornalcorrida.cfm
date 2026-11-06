<cfscript>
request.feedImporterConfig = {
    execution_mode_key = "jornalCorridaImporterExecutionMode",
    response_key = "jornalCorridaImporterResponse",
    importer_key = "jornalcorrida_feed",
    source_name = "Jornal da Corrida",
    content_type_name = "Jornal da Corrida",
    feed_url = "https://www.jornalcorrida.com.br/blog-feed.xml",
    base_url = "https://www.jornalcorrida.com.br/",
    admin_path = "/admin/importer_jornalcorrida",
    page_title = "Importador Jornal da Corrida",
    source_kind = "wix",
    sitemap_url = "https://www.jornalcorrida.com.br/blog-posts-sitemap.xml",
    sitemap_items_per_page = 10,
    default_responsible_editor_id = 28,
    author_email_domain = "jornalcorrida.import.runnerhub.local",
    audit_suffix = "jornalcorrida",
    media_repair_url_fragment = "static.wixstatic.com/media/",
    use_persisted_session = false,
    mapping_description = "Canal local fixo: <strong>Jornal da Corrida</strong>. O autor é identificado notícia a notícia pelo feed ou pelos metadados da página original. Quando o autor não existir localmente, o sistema cria um usuário do tipo <strong>autor</strong> vinculado à responsável padrão <strong>Roberta Palma</strong> (ID 28). A primeira categoria entra como categoria principal e todas as categorias entram também como tags. O feed Wix fornece título, resumo, data, autor e capa; o corpo completo é extraído da página da matéria. A varredura retroativa usa o sitemap oficial de posts. Todo conteúdo entra por padrão como <strong>Pendente de curadoria</strong>, oculto no portal e disponível na fila editorial do Business."
};
</cfscript>

<cfinclude template="/admin/importer_contrarelogio.cfm">
