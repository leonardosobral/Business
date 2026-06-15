<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- VARIAVEIS --->
<cfparam name="URL.periodo" default=""/>
<cfparam name="URL.preset" default="2025"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.percurso" default=""/>
<cfparam name="URL.prova" default=""/>

<!--- BACKEND --->
<cfinclude template="../backend_login.cfm"/>


<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Elite Supra</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.17.0/xlsx.full.min.js"></script>

    <script>
    /*    async function getH1Cbat(atletaId, callback) {
            const url = `https://cbat.org.br/atletas/${atletaId}/atleta`;
            try {
                const response = await fetch(`/bi/includes/getH1.cfm?external=${encodeURIComponent(url)}`);
                const data = await response.json();

                if (data) {
                    console.log("H1 da CBAt:", data);
                    if (typeof callback === "function") callback(data);
                    return data;
                } else {
                    console.warn("H1 não encontrado na página da CBAt.");
                    return null;
                }
            } catch (err) {
                console.error("Erro ao buscar H1:", err);
                return null;
            }
        }*/
    </script>

    <style>
        .table-active {
            background-color: #F4B120; !important;
        }
        .table-wrapper {
            max-height: 240px;
            min-height: 240px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-lg {
            max-height: 360px;
            min-height: 360px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-sm {
            max-height: 160px;
            min-height: 160px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-3 {
            max-height: 121px;
            min-height: 121px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-5 {
            max-height: 200px;
            min-height: 200px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        a {
            color:initial;
            text-decoration: none;
        }

        a:hover {
            color:initial;
        }
    </style>

</head>

<body>

    <cfif NOT isDefined("COOKIE.id")>

        <cflocation addtoken="false" url="/"/>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="../includes/header_parceiro.cfm"/>


            <!--- ESTATISTICAS DE INSCRICOES --->

            <cfinclude template="backend_treinao.cfm"/>
            <cfinclude template="treinao.cfm"/>

        </div>

    </cfif>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>


<script>
    $(document).ready(function() {
        $('#exporta-relatorio').click(function() {
            // Get the HTML table element
            var table = document.getElementById('relatorioSupra');

            // Convert the HTML table to a workbook
            var workbook = XLSX.utils.table_to_book(table, {sheet: "Elite Supra"});

            // Generate an Excel file and trigger the download
            XLSX.writeFile(workbook, 'elitesupra.xlsx');
        });
    });
</script>

</html>
