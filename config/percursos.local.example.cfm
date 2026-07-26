<cfscript>
// Copie para config/percursos.local.cfm e informe um caminho absoluto,
// persistente, fora da raiz publica do Business.
percursoLocalConfig = {
    "storagePath" = "/caminho/privado/business-percursos",
    // Chave de servidor com a Elevation API habilitada e restrita por IP.
    "googleElevationApiKey" = "",
    // Máximo de pontos consultados; os demais recebem interpolação.
    "elevationMaxSamples" = 2000
};
</cfscript>
