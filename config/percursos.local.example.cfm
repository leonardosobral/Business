<cfscript>
// Copie para config/percursos.local.cfm e informe um caminho absoluto,
// persistente, fora da raiz publica do Business.
percursoLocalConfig = {
    "storagePath" = "/caminho/privado/business-percursos",
    // Credencial usada pelos projetos internos para consultar /api/percursos/.
    // Gere um segredo longo e diferente das demais chaves do ambiente.
    "apiKey" = "",
    // URL pública deste Business, usada para montar links absolutos na resposta.
    "apiBaseUrl" = "https://business.roadrunners.run",
    // Origens web autorizadas a chamar a API diretamente pelo navegador.
    // Chamadas servidor-a-servidor não enviam Origin e continuam permitidas.
    "apiAllowedOrigins" = [
        "https://roadrunners.run"
    ],
    // Chave de servidor com a Elevation API habilitada e restrita por IP.
    "googleElevationApiKey" = "",
    // Máximo de pontos consultados; os demais recebem interpolação.
    "elevationMaxSamples" = 2000
};
</cfscript>
