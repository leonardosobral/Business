<cfif isDefined("qEventoEdicoes") AND qEventoEdicoes.recordcount>

    <!--- CARREGA OS ESTILOS DO BOX DE EDICOES APENAS UMA VEZ POR REQUISICAO --->
    <cfif NOT isDefined("REQUEST.eventEditionsCssLoaded")>
        <cfset REQUEST.eventEditionsCssLoaded = true/>
        <style>
            .event-editions-list {
                display: flex;
                flex-direction: column;
            }

            .event-edition-link {
                display: grid;
                grid-template-columns: 58px minmax(0, 1fr) auto;
                gap: 0.75rem;
                align-items: center;
                color: #333333;
                text-decoration: none;
                padding: 0.85rem 1rem;
            }

            .event-edition-link + .event-edition-link {
                border-top: 1px solid rgba(51, 51, 51, 0.08);
            }

            .event-edition-link:hover {
                color: #111111;
                background-color: rgba(250, 177, 32, 0.08);
            }

            .event-edition-link.is-current {
                background-color: #fff8e6;
            }

            .event-edition-link.has-action {
                box-shadow: inset 4px 0 0 #fab120;
            }

            .event-edition-date {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .event-edition-date .day {
                display: block;
                font-size: 1.2rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.45rem 0.15rem 0.1rem;
            }

            .event-edition-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.66rem;
                font-weight: 700;
                letter-spacing: 0.06em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .event-edition-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.68rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .event-edition-title {
                font-size: 0.95rem;
                font-weight: 700;
                line-height: 1.2;
                margin-bottom: 0.18rem;
            }

            .event-edition-meta {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.78rem;
                line-height: 1.3;
            }

            .event-edition-meta i {
                color: #fab120;
            }

            .event-edition-info {
                align-self: start;
            }

            .event-edition-tags {
                align-self: start;
                display: flex;
                flex-direction: column;
                align-items: flex-end;
                gap: 0.24rem;
            }

            .event-edition-tag {
                display: inline-flex;
                align-items: center;
                border-radius: 999px;
                background-color: #efefef;
                color: rgba(51, 51, 51, 0.82);
                font-size: 0.68rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.35rem 0.5rem;
                white-space: nowrap;
            }

            .event-edition-tag.is-current {
                background-color: #fab120;
                color: #333333;
            }

            .event-edition-tag.is-action {
                background-color: #333333;
                color: #ffffff;
                line-height: 1.15;
                text-align: center;
                white-space: normal;
            }

            .event-edition-tag.is-finishers {
                gap: 0.24rem;
                padding: 0.32rem 0.52rem;
                border-radius: 7px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.7rem;
                font-weight: 600;
            }

            .event-edition-tag.is-finishers i {
                color: #fab120;
                font-size: 0.68rem;
            }

            .event-edition-tag.is-winner {
                gap: 0.22rem;
                justify-content: flex-start;
                padding: 0.32rem 0.5rem;
                border-radius: 7px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.68rem;
                font-weight: 700;
            }

            .event-edition-tag.is-winner .rr-gender-icon {
                --rr-gender-icon-size: 0.68rem;
                color: #fab120;
            }

            .event-edition-link:hover .event-edition-tag.is-action {
                background-color: #111111;
            }

            .event-editions-more {
                border-top: 1px solid rgba(51, 51, 51, 0.08);
                padding: 0.75rem 1rem;
            }

            .event-editions-more .btn {
                border-radius: 8px;
                box-shadow: none;
                font-size: 0.78rem;
                font-weight: 700;
            }

            .event-editions-chart-more {
                border-top: 1px solid rgba(51, 51, 51, 0.08);
                margin-top: 0.75rem;
                padding-top: 0.75rem;
            }

            .event-editions-chart-more .btn {
                border-radius: 8px;
                box-shadow: none;
                font-size: 0.78rem;
                font-weight: 700;
            }

            .event-editions-chart {
                display: grid;
                gap: 0.68rem;
            }

            .event-editions-chart-row {
                display: grid;
                grid-template-columns: 48px minmax(0, 1fr) auto;
                gap: 0.62rem;
                align-items: center;
            }

            .event-editions-chart-year {
                color: #333333;
                font-size: 0.76rem;
                font-weight: 700;
                line-height: 1;
            }

            .event-editions-chart-track {
                height: 12px;
                border-radius: 999px;
                background-color: #efefef;
                overflow: hidden;
            }

            .event-editions-chart-bar {
                display: block;
                min-width: 4px;
                height: 100%;
                border-radius: 999px;
                background: linear-gradient(90deg, #d9d9d9 0%, #fab120 100%);
            }

            .event-editions-chart-value {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.76rem;
                font-weight: 700;
                line-height: 1;
                white-space: nowrap;
            }

            .event-editions-chart-row.is-unknown .event-editions-chart-year,
            .event-editions-chart-row.is-unknown .event-editions-chart-value {
                opacity: 0.5;
            }

            .event-editions-chart-caption {
                color: rgba(51, 51, 51, 0.62);
                font-size: 0.76rem;
                line-height: 1.35;
                margin: 0.65rem 0 0;
            }

            .event-best-marks-chart {
                display: grid;
                gap: 0.78rem;
            }

            .event-record-holders-shell .event-page-card-body {
                padding: 0;
            }

            .event-record-holders-list {
                display: grid;
                grid-template-columns: 1fr;
                gap: 0;
            }

            .event-record-holder-card {
                display: grid;
                grid-template-columns: 64px minmax(0, 1fr);
                align-items: center;
                gap: 0.72rem;
                min-width: 0;
                padding: 0.82rem 1rem;
                border: 0;
                border-radius: 0;
                background-color: #ffffff;
                color: #333333;
                text-decoration: none;
                transition: box-shadow 0.2s ease;
            }

            .event-record-holder-card:not(:last-child) {
                border-bottom: 1px solid rgba(51, 51, 51, 0.08);
            }

            .event-record-holder-card.is-clickable:hover {
                box-shadow: inset 0 0 0 1px rgba(250, 177, 32, 0.78);
            }

            .event-record-holder-card.is-clickable:hover .event-record-holder-athlete {
                color: #9a6a00;
            }

            .event-record-holder-avatar {
                width: 64px;
                height: 64px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 999px;
                background-color: #efefef;
                object-fit: cover;
            }

            .event-record-holder-avatar.is-muted {
                opacity: 0.32;
                filter: grayscale(1);
            }

            .event-record-holder-body {
                display: grid;
                gap: 0.2rem;
                min-width: 0;
            }

            .event-record-holder-head {
                display: flex;
                align-items: center;
                gap: 0.38rem;
                min-width: 0;
            }

            .event-record-holder-icon {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                width: 1.28rem;
                height: 1.28rem;
                border-radius: 999px;
                background-color: #efefef;
                color: #333333;
                flex: 0 0 auto;
            }

            .event-record-holder-icon .rr-gender-icon {
                --rr-gender-icon-size: 0.74rem;
            }

            .event-record-holder-card.is-women .event-record-holder-icon {
                background-color: #fff8e6;
                color: #9a6a00;
            }

            .event-record-holder-label {
                color: rgba(51, 51, 51, 0.62);
                font-size: 0.66rem;
                font-weight: 800;
                letter-spacing: 0.06em;
                line-height: 1;
                text-transform: uppercase;
            }

            .event-record-holder-time {
                color: #333333;
                font-size: 1.16rem;
                font-weight: 900;
                line-height: 1;
            }

            .event-record-holder-athlete {
                display: block;
                color: #333333;
                font-size: 0.84rem;
                font-weight: 800;
                line-height: 1.15;
                overflow: hidden;
                text-decoration: none;
                text-overflow: ellipsis;
                white-space: nowrap;
            }

            .event-record-holder-meta {
                color: rgba(51, 51, 51, 0.58);
                font-size: 0.72rem;
                font-weight: 800;
                line-height: 1.2;
            }

            .event-best-marks-caption {
                color: rgba(51, 51, 51, 0.62);
                font-size: 0.76rem;
                line-height: 1.35;
                margin: 0;
            }

            .event-best-marks-history {
                display: grid;
                gap: 0.45rem;
            }

            .event-best-marks-history-row {
                display: grid;
                grid-template-columns: 46px minmax(0, 1fr);
                gap: 0.58rem;
                align-items: stretch;
                padding: 0.56rem;
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #ffffff;
                color: #333333;
                text-decoration: none;
                transition: border-color 0.2s ease;
            }

            .event-best-marks-history-row.is-clickable:hover {
                border-color: rgba(250, 177, 32, 0.72);
                color: #333333;
            }

            .event-best-marks-history-row.is-current {
                border-color: rgba(250, 177, 32, 0.8);
                background-color: #fff8e6;
                box-shadow: inset 3px 0 0 #fab120;
            }

            .event-best-marks-year {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                border-radius: 8px;
                background-color: #efefef;
                color: rgba(51, 51, 51, 0.78);
                font-size: 0.72rem;
                font-weight: 900;
                line-height: 1;
            }

            .event-best-marks-history-row.is-current .event-best-marks-year {
                background-color: #fab120;
                color: #333333;
            }

            .event-best-marks-lines {
                display: grid;
                gap: 0.42rem;
                min-width: 0;
            }

            .event-best-marks-line-item {
                display: grid;
                grid-template-columns: 20px 68px minmax(0, 1fr);
                gap: 0.38rem;
                align-items: center;
                min-width: 0;
            }

            .event-best-marks-gender-icon {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                width: 1.15rem;
                height: 1.15rem;
                border-radius: 999px;
                background-color: #efefef;
                color: #333333;
                font-size: 0.65rem;
            }

            .event-best-marks-gender-icon .rr-gender-icon {
                --rr-gender-icon-size: 0.72rem;
            }

            .event-best-marks-line-item.is-women .event-best-marks-gender-icon {
                background-color: #fff8e6;
                color: #9a6a00;
            }

            .event-best-marks-time {
                display: inline-flex;
                align-items: center;
                gap: 0.22rem;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 900;
                line-height: 1;
                white-space: nowrap;
            }

            .event-best-marks-record-trophy {
                color: #fab120;
                font-size: 0.62rem;
                line-height: 1;
            }

            .event-best-marks-line-item.is-empty {
                opacity: 0.42;
            }

            .event-best-marks-track {
                height: 8px;
                border-radius: 999px;
                background-color: #efefef;
                overflow: hidden;
                min-width: 0;
            }

            .event-best-marks-bar {
                display: block;
                height: 100%;
                min-width: 4px;
                border-radius: 999px;
                background: linear-gradient(90deg, #d9d9d9 0%, #333333 100%);
            }

            .event-best-marks-line-item.is-women .event-best-marks-bar {
                background: linear-gradient(90deg, #ffe7a8 0%, #fab120 100%);
            }

            .event-best-marks-line-item.is-record .event-best-marks-time {
                color: #9a6a00;
            }

            .event-best-marks-line-item.is-record .event-best-marks-bar {
                background: linear-gradient(90deg, #fab120 0%, #333333 100%);
            }

            .event-best-marks-line-item.is-women.is-record .event-best-marks-bar {
                background: linear-gradient(90deg, #ffe7a8 0%, #fab120 100%);
            }

            .event-best-marks-more {
                border-top: 1px solid rgba(51, 51, 51, 0.08);
                margin-top: 0.1rem;
                padding-top: 0.75rem;
            }

            .event-best-marks-more .btn {
                border-radius: 8px;
                box-shadow: none;
                font-size: 0.78rem;
                font-weight: 700;
            }

            @media (max-width: 575.98px) {
                .event-editions-chart-row {
                    grid-template-columns: 42px minmax(0, 1fr) auto;
                    gap: 0.5rem;
                }

                .event-record-holder-card {
                    grid-template-columns: 58px minmax(0, 1fr);
                    gap: 0.62rem;
                    padding: 0.72rem 0.85rem;
                }

                .event-record-holder-avatar {
                    width: 58px;
                    height: 58px;
                }

                .event-best-marks-history-row {
                    grid-template-columns: 42px minmax(0, 1fr);
                    gap: 0.5rem;
                }

                .event-best-marks-line-item {
                    grid-template-columns: 18px 64px minmax(0, 1fr);
                    gap: 0.32rem;
                }
            }

            @media (min-width: 768px) {
                .event-record-holders-list {
                    grid-template-columns: repeat(2, minmax(0, 1fr));
                }

                .event-record-holder-card:only-child {
                    grid-column: 1 / -1;
                }

                .event-record-holder-card:not(:last-child) {
                    border-right: 1px solid rgba(51, 51, 51, 0.08);
                    border-bottom: 0;
                }
            }

            @media (max-width: 575.98px) {
                .event-edition-link {
                    grid-template-columns: 54px minmax(0, 1fr);
                }

                .event-edition-tags {
                    grid-column: 1 / -1;
                    width: 100%;
                    flex-direction: row;
                    align-items: center;
                    gap: 0.18rem;
                    overflow-x: auto;
                    scrollbar-width: none;
                }

                .event-edition-tags .event-edition-tag {
                    flex: 0 0 auto;
                }

                .event-edition-tags .event-edition-tag.is-action {
                    white-space: nowrap;
                }

                .event-edition-tags::-webkit-scrollbar {
                    display: none;
                }
            }
        </style>
    </cfif>

    <!--- TITULO GENERICO PARA EVITAR REPETIR O NOME DO EVENTO/AGREGADOR NO CARD --->
    <cfset VARIABLES.eventEditionsTitle = "Edições do evento"/>

    <cfset VARIABLES.eventEditionsCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew()/>
    <cfset VARIABLES.eventEditionsCurrentEventId = val(qEvento.id_evento)/>
    <cfset VARIABLES.eventEditionsVisibleLimit = 5/>
    <cfset VARIABLES.eventEditionsIndex = 0/>
    <cfset VARIABLES.eventEditionsChartByYear = structNew()/>
    <cfset VARIABLES.eventEditionsChartYears = []/>
    <cfset VARIABLES.eventEditionsChartVisibleYears = []/>
    <cfset VARIABLES.eventEditionsChartVisibleLimit = 10/>
    <cfset VARIABLES.eventEditionsChartMax = 0/>
    <cfset VARIABLES.eventEditionsChartCurrentCity = lCase(trim(qEvento.cidade & ""))/>
    <cfset VARIABLES.eventEditionsSameCityCount = 0/>
    <cfset VARIABLES.eventBestMarksByYear = structNew()/>
    <cfset VARIABLES.eventBestMarksYears = []/>
    <cfset VARIABLES.eventBestMarksRows = []/>
    <cfset VARIABLES.eventBestMarksMinSeconds = 0/>
    <cfset VARIABLES.eventBestMarksMaxSeconds = 0/>
    <cfset VARIABLES.eventBestMarksVisibleLimit = 6/>
    <cfset VARIABLES.eventBestMarksMenRecordSeconds = 0/>
    <cfset VARIABLES.eventBestMarksMenRecordLabel = ""/>
    <cfset VARIABLES.eventBestMarksMenRecordName = ""/>
    <cfset VARIABLES.eventBestMarksMenRecordUserId = 0/>
    <cfset VARIABLES.eventBestMarksMenRecordTag = ""/>
    <cfset VARIABLES.eventBestMarksMenRecordTagPrefix = "atleta"/>
    <cfset VARIABLES.eventBestMarksMenRecordProfilePath = ""/>
    <cfset VARIABLES.eventBestMarksMenRecordImage = "/assets/user.png"/>
    <cfset VARIABLES.eventBestMarksMenRecordYear = ""/>
    <cfset VARIABLES.eventBestMarksMenSlowestSeconds = 0/>
    <cfset VARIABLES.eventBestMarksWomenRecordSeconds = 0/>
    <cfset VARIABLES.eventBestMarksWomenRecordLabel = ""/>
    <cfset VARIABLES.eventBestMarksWomenRecordName = ""/>
    <cfset VARIABLES.eventBestMarksWomenRecordUserId = 0/>
    <cfset VARIABLES.eventBestMarksWomenRecordTag = ""/>
    <cfset VARIABLES.eventBestMarksWomenRecordTagPrefix = "atleta"/>
    <cfset VARIABLES.eventBestMarksWomenRecordProfilePath = ""/>
    <cfset VARIABLES.eventBestMarksWomenRecordImage = "/assets/user.png"/>
    <cfset VARIABLES.eventBestMarksWomenRecordYear = ""/>
    <cfset VARIABLES.eventBestMarksWomenSlowestSeconds = 0/>

    <cfloop query="qEventoEdicoes">
        <cfif isDate(qEventoEdicoes.data_final) AND lCase(trim(qEventoEdicoes.cidade & "")) EQ VARIABLES.eventEditionsChartCurrentCity>
            <cfset VARIABLES.eventEditionsSameCityCount = VARIABLES.eventEditionsSameCityCount + 1/>
            <cfset VARIABLES.eventEditionsChartYear = year(qEventoEdicoes.data_final) & ""/>
            <cfif NOT structKeyExists(VARIABLES.eventEditionsChartByYear, VARIABLES.eventEditionsChartYear)>
                <cfset VARIABLES.eventEditionsChartByYear[VARIABLES.eventEditionsChartYear] = 0/>
            </cfif>
            <cfset VARIABLES.eventEditionsChartByYear[VARIABLES.eventEditionsChartYear] = VARIABLES.eventEditionsChartByYear[VARIABLES.eventEditionsChartYear] + val(qEventoEdicoes.concluintes)/>

            <cfif NOT structKeyExists(VARIABLES.eventBestMarksByYear, VARIABLES.eventEditionsChartYear)>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear] = {
                    "year" = VARIABLES.eventEditionsChartYear,
                    "eventTag" = trim(qEventoEdicoes.tag & ""),
                    "eventName" = trim(qEventoEdicoes.nome_evento & ""),
                    "menSeconds" = 0,
                    "menLabel" = "",
                    "menName" = "",
                    "menUserId" = 0,
                    "menTag" = "",
                    "menTagPrefix" = "atleta",
                    "menImage" = "/assets/user.png",
                    "womenSeconds" = 0,
                    "womenLabel" = "",
                    "womenName" = "",
                    "womenUserId" = 0,
                    "womenTag" = "",
                    "womenTagPrefix" = "atleta",
                    "womenImage" = "/assets/user.png",
                    "isCurrent" = false
                }/>
            </cfif>
            <cfif NOT len(trim(VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['eventTag'] & "")) AND len(trim(qEventoEdicoes.tag & ""))>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['eventTag'] = trim(qEventoEdicoes.tag & "")/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['eventName'] = trim(qEventoEdicoes.nome_evento & "")/>
            </cfif>

            <cfif val(qEventoEdicoes.id_evento) EQ VARIABLES.eventEditionsCurrentEventId>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['isCurrent'] = true/>
            </cfif>

            <cfset VARIABLES.eventBestMarksMenLabel = trim(qEventoEdicoes.tempo_campeao_masculino & "")/>
            <cfset VARIABLES.eventBestMarksMenSeconds = 0/>
            <cfset VARIABLES.eventBestMarksMenIsRecognized = val(qEventoEdicoes.id_usuario_campeao_masculino) GT 0 AND (compareNoCase(trim(qEventoEdicoes.vinculo_reconhecido_campeao_masculino & ""), "true") EQ 0 OR val(qEventoEdicoes.vinculo_reconhecido_campeao_masculino) EQ 1)/>
            <cfif listLen(VARIABLES.eventBestMarksMenLabel, ":") GTE 3>
                <cfset VARIABLES.eventBestMarksMenSeconds = (val(listGetAt(VARIABLES.eventBestMarksMenLabel, 1, ":")) * 3600) + (val(listGetAt(VARIABLES.eventBestMarksMenLabel, 2, ":")) * 60) + val(listGetAt(VARIABLES.eventBestMarksMenLabel, 3, ":"))/>
            </cfif>
            <cfif VARIABLES.eventBestMarksMenSeconds GT 0 AND (val(VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menSeconds']) EQ 0 OR VARIABLES.eventBestMarksMenSeconds LT val(VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menSeconds']))>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menSeconds'] = VARIABLES.eventBestMarksMenSeconds/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menLabel'] = VARIABLES.eventBestMarksMenLabel/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menName'] = trim(qEventoEdicoes.nome_campeao_masculino & "")/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menUserId'] = VARIABLES.eventBestMarksMenIsRecognized ? val(qEventoEdicoes.id_usuario_campeao_masculino) : 0/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menTag'] = VARIABLES.eventBestMarksMenIsRecognized ? trim(qEventoEdicoes.tag_campeao_masculino & "") : ""/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menTagPrefix'] = (VARIABLES.eventBestMarksMenIsRecognized AND len(trim(qEventoEdicoes.tag_prefix_campeao_masculino & ""))) ? trim(qEventoEdicoes.tag_prefix_campeao_masculino & "") : "atleta"/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['menImage'] = (VARIABLES.eventBestMarksMenIsRecognized AND len(trim(qEventoEdicoes.tag_campeao_masculino & "")) AND len(trim(qEventoEdicoes.imagem_campeao_masculino & ""))) ? trim(qEventoEdicoes.imagem_campeao_masculino & "") : "/assets/user.png"/>
            </cfif>

            <cfset VARIABLES.eventBestMarksWomenLabel = trim(qEventoEdicoes.tempo_campea_feminina & "")/>
            <cfset VARIABLES.eventBestMarksWomenSeconds = 0/>
            <cfset VARIABLES.eventBestMarksWomenIsRecognized = val(qEventoEdicoes.id_usuario_campea_feminina) GT 0 AND (compareNoCase(trim(qEventoEdicoes.vinculo_reconhecido_campea_feminina & ""), "true") EQ 0 OR val(qEventoEdicoes.vinculo_reconhecido_campea_feminina) EQ 1)/>
            <cfif listLen(VARIABLES.eventBestMarksWomenLabel, ":") GTE 3>
                <cfset VARIABLES.eventBestMarksWomenSeconds = (val(listGetAt(VARIABLES.eventBestMarksWomenLabel, 1, ":")) * 3600) + (val(listGetAt(VARIABLES.eventBestMarksWomenLabel, 2, ":")) * 60) + val(listGetAt(VARIABLES.eventBestMarksWomenLabel, 3, ":"))/>
            </cfif>
            <cfif VARIABLES.eventBestMarksWomenSeconds GT 0 AND (val(VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenSeconds']) EQ 0 OR VARIABLES.eventBestMarksWomenSeconds LT val(VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenSeconds']))>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenSeconds'] = VARIABLES.eventBestMarksWomenSeconds/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenLabel'] = VARIABLES.eventBestMarksWomenLabel/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenName'] = trim(qEventoEdicoes.nome_campea_feminina & "")/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenUserId'] = VARIABLES.eventBestMarksWomenIsRecognized ? val(qEventoEdicoes.id_usuario_campea_feminina) : 0/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenTag'] = VARIABLES.eventBestMarksWomenIsRecognized ? trim(qEventoEdicoes.tag_campea_feminina & "") : ""/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenTagPrefix'] = (VARIABLES.eventBestMarksWomenIsRecognized AND len(trim(qEventoEdicoes.tag_prefix_campea_feminina & ""))) ? trim(qEventoEdicoes.tag_prefix_campea_feminina & "") : "atleta"/>
                <cfset VARIABLES.eventBestMarksByYear[VARIABLES.eventEditionsChartYear]['womenImage'] = (VARIABLES.eventBestMarksWomenIsRecognized AND len(trim(qEventoEdicoes.tag_campea_feminina & "")) AND len(trim(qEventoEdicoes.imagem_campea_feminina & ""))) ? trim(qEventoEdicoes.imagem_campea_feminina & "") : "/assets/user.png"/>
            </cfif>
        </cfif>
    </cfloop>

    <cfset VARIABLES.eventEditionsChartYears = structKeyArray(VARIABLES.eventEditionsChartByYear)/>
    <cfset arraySort(VARIABLES.eventEditionsChartYears, "numeric", "desc")/>
    <cfset VARIABLES.eventEditionsChartYearIndex = 0/>
    <cfloop array="#VARIABLES.eventEditionsChartYears#" index="eventEditionsChartYear">
        <cfset VARIABLES.eventEditionsChartYearIndex = VARIABLES.eventEditionsChartYearIndex + 1/>
        <cfset VARIABLES.eventEditionsChartYearValue = val(VARIABLES.eventEditionsChartByYear[eventEditionsChartYear])/>
        <cfif VARIABLES.eventEditionsChartYearValue GT 0 OR VARIABLES.eventEditionsChartYearIndex GT 1>
            <cfset arrayAppend(VARIABLES.eventEditionsChartVisibleYears, eventEditionsChartYear)/>
            <cfif val(VARIABLES.eventEditionsChartByYear[eventEditionsChartYear]) GT VARIABLES.eventEditionsChartMax>
                <cfset VARIABLES.eventEditionsChartMax = val(VARIABLES.eventEditionsChartByYear[eventEditionsChartYear])/>
            </cfif>
        </cfif>
    </cfloop>
    <cfset VARIABLES.eventEditionsChartYears = VARIABLES.eventEditionsChartVisibleYears/>

    <cfset VARIABLES.eventBestMarksYears = structKeyArray(VARIABLES.eventBestMarksByYear)/>
    <cfset arraySort(VARIABLES.eventBestMarksYears, "numeric", "asc")/>
    <cfloop array="#VARIABLES.eventBestMarksYears#" index="eventBestMarksYear">
        <cfset VARIABLES.eventBestMarksRow = VARIABLES.eventBestMarksByYear[eventBestMarksYear]/>
        <cfif val(VARIABLES.eventBestMarksRow['menSeconds']) GT 0 OR val(VARIABLES.eventBestMarksRow['womenSeconds']) GT 0>
            <cfset arrayAppend(VARIABLES.eventBestMarksRows, VARIABLES.eventBestMarksRow)/>
            <cfif val(VARIABLES.eventBestMarksRow['menSeconds']) GT 0>
                <cfif VARIABLES.eventBestMarksMinSeconds EQ 0 OR val(VARIABLES.eventBestMarksRow['menSeconds']) LT VARIABLES.eventBestMarksMinSeconds>
                    <cfset VARIABLES.eventBestMarksMinSeconds = val(VARIABLES.eventBestMarksRow['menSeconds'])/>
                </cfif>
                <cfif VARIABLES.eventBestMarksMenRecordSeconds EQ 0 OR val(VARIABLES.eventBestMarksRow['menSeconds']) LT VARIABLES.eventBestMarksMenRecordSeconds>
                    <cfset VARIABLES.eventBestMarksMenRecordSeconds = val(VARIABLES.eventBestMarksRow['menSeconds'])/>
                    <cfset VARIABLES.eventBestMarksMenRecordLabel = trim(VARIABLES.eventBestMarksRow['menLabel'] & "")/>
                    <cfset VARIABLES.eventBestMarksMenRecordName = trim(VARIABLES.eventBestMarksRow['menName'] & "")/>
                    <cfset VARIABLES.eventBestMarksMenRecordUserId = val(VARIABLES.eventBestMarksRow['menUserId'])/>
                    <cfset VARIABLES.eventBestMarksMenRecordTag = trim(VARIABLES.eventBestMarksRow['menTag'] & "")/>
                    <cfset VARIABLES.eventBestMarksMenRecordTagPrefix = len(trim(VARIABLES.eventBestMarksRow['menTagPrefix'] & "")) ? trim(VARIABLES.eventBestMarksRow['menTagPrefix'] & "") : "atleta"/>
                    <cfset VARIABLES.eventBestMarksMenRecordImage = len(trim(VARIABLES.eventBestMarksRow['menImage'] & "")) ? trim(VARIABLES.eventBestMarksRow['menImage'] & "") : "/assets/user.png"/>
                    <cfset VARIABLES.eventBestMarksMenRecordYear = VARIABLES.eventBestMarksRow['year']/>
                    <cfif VARIABLES.eventBestMarksMenRecordUserId LTE 0 OR NOT len(VARIABLES.eventBestMarksMenRecordTag)>
                        <cfset VARIABLES.eventBestMarksMenRecordImage = "/assets/user.png"/>
                    </cfif>
                </cfif>
                <cfif val(VARIABLES.eventBestMarksRow['menSeconds']) GT VARIABLES.eventBestMarksMenSlowestSeconds>
                    <cfset VARIABLES.eventBestMarksMenSlowestSeconds = val(VARIABLES.eventBestMarksRow['menSeconds'])/>
                </cfif>
                <cfif val(VARIABLES.eventBestMarksRow['menSeconds']) GT VARIABLES.eventBestMarksMaxSeconds>
                    <cfset VARIABLES.eventBestMarksMaxSeconds = val(VARIABLES.eventBestMarksRow['menSeconds'])/>
                </cfif>
            </cfif>
            <cfif val(VARIABLES.eventBestMarksRow['womenSeconds']) GT 0>
                <cfif VARIABLES.eventBestMarksMinSeconds EQ 0 OR val(VARIABLES.eventBestMarksRow['womenSeconds']) LT VARIABLES.eventBestMarksMinSeconds>
                    <cfset VARIABLES.eventBestMarksMinSeconds = val(VARIABLES.eventBestMarksRow['womenSeconds'])/>
                </cfif>
                <cfif VARIABLES.eventBestMarksWomenRecordSeconds EQ 0 OR val(VARIABLES.eventBestMarksRow['womenSeconds']) LT VARIABLES.eventBestMarksWomenRecordSeconds>
                    <cfset VARIABLES.eventBestMarksWomenRecordSeconds = val(VARIABLES.eventBestMarksRow['womenSeconds'])/>
                    <cfset VARIABLES.eventBestMarksWomenRecordLabel = trim(VARIABLES.eventBestMarksRow['womenLabel'] & "")/>
                    <cfset VARIABLES.eventBestMarksWomenRecordName = trim(VARIABLES.eventBestMarksRow['womenName'] & "")/>
                    <cfset VARIABLES.eventBestMarksWomenRecordUserId = val(VARIABLES.eventBestMarksRow['womenUserId'])/>
                    <cfset VARIABLES.eventBestMarksWomenRecordTag = trim(VARIABLES.eventBestMarksRow['womenTag'] & "")/>
                    <cfset VARIABLES.eventBestMarksWomenRecordTagPrefix = len(trim(VARIABLES.eventBestMarksRow['womenTagPrefix'] & "")) ? trim(VARIABLES.eventBestMarksRow['womenTagPrefix'] & "") : "atleta"/>
                    <cfset VARIABLES.eventBestMarksWomenRecordImage = len(trim(VARIABLES.eventBestMarksRow['womenImage'] & "")) ? trim(VARIABLES.eventBestMarksRow['womenImage'] & "") : "/assets/user.png"/>
                    <cfset VARIABLES.eventBestMarksWomenRecordYear = VARIABLES.eventBestMarksRow['year']/>
                    <cfif VARIABLES.eventBestMarksWomenRecordUserId LTE 0 OR NOT len(VARIABLES.eventBestMarksWomenRecordTag)>
                        <cfset VARIABLES.eventBestMarksWomenRecordImage = "/assets/user.png"/>
                    </cfif>
                </cfif>
                <cfif val(VARIABLES.eventBestMarksRow['womenSeconds']) GT VARIABLES.eventBestMarksWomenSlowestSeconds>
                    <cfset VARIABLES.eventBestMarksWomenSlowestSeconds = val(VARIABLES.eventBestMarksRow['womenSeconds'])/>
                </cfif>
                <cfif val(VARIABLES.eventBestMarksRow['womenSeconds']) GT VARIABLES.eventBestMarksMaxSeconds>
                    <cfset VARIABLES.eventBestMarksMaxSeconds = val(VARIABLES.eventBestMarksRow['womenSeconds'])/>
                </cfif>
            </cfif>
        </cfif>
    </cfloop>

    <cfif VARIABLES.eventBestMarksMenRecordUserId GT 0 AND len(VARIABLES.eventBestMarksMenRecordTag)>
        <cfset VARIABLES.eventBestMarksMenRecordProfilePath = "/#VARIABLES.eventBestMarksMenRecordTagPrefix#/#VARIABLES.eventBestMarksMenRecordTag#/"/>
        <cfif structKeyExists(REQUEST, "i18nBuildPath")>
            <cfset VARIABLES.eventBestMarksMenRecordRouteParams = duplicate(VARIABLES.eventEditionsCurrentRouteParams)/>
            <cfset VARIABLES.eventBestMarksMenRecordRouteParams["tag"] = VARIABLES.eventBestMarksMenRecordTag/>
            <cfset REQUEST.currentRouteParams = VARIABLES.eventBestMarksMenRecordRouteParams/>
            <cfset VARIABLES.eventBestMarksMenRecordProfilePath = REQUEST.i18nBuildPath("athlete")/>
            <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionsCurrentRouteParams/>
        </cfif>
    </cfif>

    <cfif VARIABLES.eventBestMarksWomenRecordUserId GT 0 AND len(VARIABLES.eventBestMarksWomenRecordTag)>
        <cfset VARIABLES.eventBestMarksWomenRecordProfilePath = "/#VARIABLES.eventBestMarksWomenRecordTagPrefix#/#VARIABLES.eventBestMarksWomenRecordTag#/"/>
        <cfif structKeyExists(REQUEST, "i18nBuildPath")>
            <cfset VARIABLES.eventBestMarksWomenRecordRouteParams = duplicate(VARIABLES.eventEditionsCurrentRouteParams)/>
            <cfset VARIABLES.eventBestMarksWomenRecordRouteParams["tag"] = VARIABLES.eventBestMarksWomenRecordTag/>
            <cfset REQUEST.currentRouteParams = VARIABLES.eventBestMarksWomenRecordRouteParams/>
            <cfset VARIABLES.eventBestMarksWomenRecordProfilePath = REQUEST.i18nBuildPath("athlete")/>
            <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionsCurrentRouteParams/>
        </cfif>
    </cfif>

    <div class="event-page-card mt-2">
        <div class="event-page-card-head">
            <h6 class="event-page-card-title"><i class="fa-solid fa-calendar-days me-1"></i><cfoutput>#VARIABLES.eventEditionsTitle#</cfoutput></h6>
        </div>
        <div class="event-editions-list">
            <cfloop query="qEventoEdicoes">
                <cfif lCase(trim(qEventoEdicoes.cidade & "")) EQ VARIABLES.eventEditionsChartCurrentCity>
                    <cfset VARIABLES.eventEditionsIndex = VARIABLES.eventEditionsIndex + 1/>
                    <cfset VARIABLES.eventEditionIsCurrent = val(qEventoEdicoes.id_evento) EQ VARIABLES.eventEditionsCurrentEventId/>
                    <cfset VARIABLES.eventEditionIsHidden = VARIABLES.eventEditionsIndex GT VARIABLES.eventEditionsVisibleLimit AND NOT VARIABLES.eventEditionIsCurrent/>
                    <cfset VARIABLES.eventEditionTag = trim(qEventoEdicoes.tag)/>
                    <cfset VARIABLES.eventEditionRegistrationUrl = ""/>

                    <cfif VARIABLES.eventEditionIsCurrent>
                        <cfset VARIABLES.eventEditionRegistrationUrl = len(trim(qEvento.url_inscricao & "")) ? trim(qEvento.url_inscricao & "") : trim(qEvento.url_hotsite & "")/>
                    </cfif>

                    <cfset VARIABLES.eventEditionIsOpenForRegistration = VARIABLES.eventEditionIsCurrent AND len(VARIABLES.eventEditionRegistrationUrl) AND dateCompare(qEventoEdicoes.data_inicial, now(), "d") GT 0 AND lCase(trim(qEventoEdicoes.status_evento & "")) NEQ "cancelado"/>
                    <cfset VARIABLES.eventEditionHasCoupon = VARIABLES.eventEditionIsOpenForRegistration AND isDefined("qCupom.recordcount") AND qCupom.recordcount/>
                    <cfset VARIABLES.eventEditionRegistrationLabel = VARIABLES.eventEditionHasCoupon ? "Inscreva-se com cupom de desconto" : "Inscreva-se"/>
                    <cfset VARIABLES.eventEditionAnchorAttrs = ""/>

                    <!--- MONTA A URL LOCALIZADA DA EDICAO USANDO A TAG DO EVENTO --->
                    <cfif len(VARIABLES.eventEditionTag) AND structKeyExists(REQUEST, "i18nBuildPath")>
                        <cfset VARIABLES.eventEditionRouteParams = duplicate(VARIABLES.eventEditionsCurrentRouteParams)/>
                        <cfset VARIABLES.eventEditionRouteParams["tag"] = VARIABLES.eventEditionTag/>
                        <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionRouteParams/>
                        <cfset VARIABLES.eventEditionPath = REQUEST.i18nBuildPath("event")/>
                        <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionsCurrentRouteParams/>
                    <cfelseif len(VARIABLES.eventEditionTag)>
                        <cfset VARIABLES.eventEditionPath = "/evento/#VARIABLES.eventEditionTag#/"/>
                    <cfelse>
                        <cfset VARIABLES.eventEditionPath = "/evento/"/>
                    </cfif>

                    <cfif VARIABLES.eventEditionIsOpenForRegistration>
                        <cfset VARIABLES.eventEditionPath = VARIABLES.eventEditionRegistrationUrl/>
                        <cfset VARIABLES.eventEditionAnchorAttrs = ' target="_blank" rel="noopener"'/>
                    </cfif>

                    <!--- MONTA A LINHA DA EDICAO COM INDICADORES DE STATUS E RESULTADOS --->
                    <cfoutput>
                        <a class="event-edition-link<cfif VARIABLES.eventEditionIsCurrent> is-current</cfif><cfif VARIABLES.eventEditionIsOpenForRegistration> has-action</cfif><cfif VARIABLES.eventEditionIsHidden> d-none</cfif>"
                           href="#VARIABLES.eventEditionPath#"
                           #VARIABLES.eventEditionAnchorAttrs#
                           <cfif VARIABLES.eventEditionIsOpenForRegistration>data-audience-live-registration="#HTMLEditFormat(qEventoEdicoes.id_evento)#"</cfif>
                           <cfif VARIABLES.eventEditionIsHidden>data-event-edition-extra="true"</cfif>>
                            <span class="event-edition-date">
                                <span class="day">#lsDateFormat(qEventoEdicoes.data_final, "dd")#</span>
                                <span class="month">#lsDateFormat(qEventoEdicoes.data_final, "mmm")#</span>
                                <span class="year">#lsDateFormat(qEventoEdicoes.data_final, "yyyy")#</span>
                            </span>
                            <span class="event-edition-info">
                                <span class="event-edition-title d-block">#qEventoEdicoes.nome_evento#</span>
                                <span class="event-edition-meta d-block">
                                    <i class="fa-solid fa-location-dot me-1"></i>#qEventoEdicoes.cidade#<cfif len(trim(qEventoEdicoes.estado))> - #qEventoEdicoes.estado#</cfif>
                                </span>
                                <cfif VARIABLES.eventEditionIsCurrent>
                                    <span class="event-edition-tag is-current mt-1">#REQUEST.t('event.editions.viewingCurrent')#</span>
                                </cfif>
                            </span>
                            <span class="event-edition-tags">
                                <cfif VARIABLES.eventEditionIsOpenForRegistration>
                                    <span class="event-edition-tag is-action">#VARIABLES.eventEditionRegistrationLabel#</span>
                                </cfif>
                                <cfif val(qEventoEdicoes.concluintes) GT 0>
                                    <span class="event-edition-tag is-finishers"><i class="fa-solid fa-person-running"></i>#REQUEST.t("search.eventList.finishersCount", { "count" = lsNumberFormat(qEventoEdicoes.concluintes) })#</span>
                                </cfif>
                                <cfif len(trim(qEventoEdicoes.tempo_campeao_masculino & ""))>
                                    <span class="event-edition-tag is-winner" title="#encodeForHTMLAttribute(REQUEST.t('event.editions.maleChampionTitle'))#"><span class="rr-gender-icon is-male" aria-hidden="true"></span>#qEventoEdicoes.tempo_campeao_masculino#</span>
                                </cfif>
                                <cfif len(trim(qEventoEdicoes.tempo_campea_feminina & ""))>
                                    <span class="event-edition-tag is-winner" title="#encodeForHTMLAttribute(REQUEST.t('event.editions.femaleChampionTitle'))#"><span class="rr-gender-icon is-female" aria-hidden="true"></span>#qEventoEdicoes.tempo_campea_feminina#</span>
                                </cfif>
                            </span>
                        </a>
                    </cfoutput>
                </cfif>
            </cfloop>
        </div>

        <cfif VARIABLES.eventEditionsSameCityCount GT VARIABLES.eventEditionsVisibleLimit>
            <div class="event-editions-more">
                <button type="button" class="btn btn-light w-100" data-event-editions-expand>
                    <cfoutput>#REQUEST.t('event.editions.moreEditions')#</cfoutput>
                </button>
            </div>
        </cfif>
    </div>

    <cfif arrayLen(VARIABLES.eventEditionsChartYears) AND VARIABLES.eventEditionsChartMax GT 0>
        <div class="event-page-card mt-2">
            <div class="event-page-card-head">
                <h6 class="event-page-card-title"><i class="fa-solid fa-chart-bar me-1"></i><cfoutput>#REQUEST.t('event.editions.finishersVariation')#</cfoutput></h6>
            </div>
            <div class="event-page-card-body">
                <div class="event-editions-chart">
                    <cfset VARIABLES.eventEditionsChartIndex = 0/>
                    <cfloop array="#VARIABLES.eventEditionsChartYears#" index="eventEditionsChartYear">
                        <cfset VARIABLES.eventEditionsChartIndex = VARIABLES.eventEditionsChartIndex + 1/>
                        <cfset VARIABLES.eventEditionsChartValue = val(VARIABLES.eventEditionsChartByYear[eventEditionsChartYear])/>
                        <cfset VARIABLES.eventEditionsChartIsUnknown = VARIABLES.eventEditionsChartValue LTE 0/>
                        <cfset VARIABLES.eventEditionsChartPercent = VARIABLES.eventEditionsChartIsUnknown ? 0 : max(4, round((VARIABLES.eventEditionsChartValue / VARIABLES.eventEditionsChartMax) * 100))/>
                        <cfoutput>
                            <div class="event-editions-chart-row<cfif VARIABLES.eventEditionsChartIsUnknown> is-unknown</cfif><cfif VARIABLES.eventEditionsChartIndex GT VARIABLES.eventEditionsChartVisibleLimit> d-none</cfif>"<cfif VARIABLES.eventEditionsChartIndex GT VARIABLES.eventEditionsChartVisibleLimit> data-event-editions-chart-extra="true"</cfif>>
                                <span class="event-editions-chart-year">#eventEditionsChartYear#</span>
                                <span class="event-editions-chart-track" title="<cfif VARIABLES.eventEditionsChartIsUnknown>#HTMLEditFormat(REQUEST.t('event.editions.unknownFinishers'))#<cfelse>#HTMLEditFormat(REQUEST.t('event.editions.finishersTitle', { 'year' = eventEditionsChartYear, 'count' = lsNumberFormat(VARIABLES.eventEditionsChartValue) }))#</cfif>">
                                    <cfif NOT VARIABLES.eventEditionsChartIsUnknown>
                                        <span class="event-editions-chart-bar" style="width:#VARIABLES.eventEditionsChartPercent#%"></span>
                                    </cfif>
                                </span>
                                <span class="event-editions-chart-value"><cfif VARIABLES.eventEditionsChartIsUnknown>#REQUEST.t('event.editions.unknownFinishers')#<cfelse>#lsNumberFormat(VARIABLES.eventEditionsChartValue)#</cfif></span>
                            </div>
                        </cfoutput>
                    </cfloop>
                </div>
                <cfif arrayLen(VARIABLES.eventEditionsChartYears) GT VARIABLES.eventEditionsChartVisibleLimit>
                    <div class="event-editions-chart-more">
                        <button type="button" class="btn btn-light w-100" data-event-editions-chart-expand>
                            <cfoutput>#REQUEST.t('event.editions.allYears')#</cfoutput>
                        </button>
                    </div>
                </cfif>
                <p class="event-editions-chart-caption"><cfoutput>#REQUEST.t('event.editions.finishersCaption')#</cfoutput></p>
            </div>
        </div>
    </cfif>

    <cfif arrayLen(VARIABLES.eventBestMarksRows) AND (VARIABLES.eventBestMarksMenRecordSeconds GT 0 OR VARIABLES.eventBestMarksWomenRecordSeconds GT 0)>
        <div class="event-page-card event-record-holders-shell mt-2">
            <div class="event-page-card-head">
                <h6 class="event-page-card-title"><i class="fa-solid fa-trophy me-1"></i><cfoutput>#REQUEST.t('event.editions.recordHolders')#</cfoutput></h6>
            </div>
            <div class="event-page-card-body">
                <div class="event-record-holders-list" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('event.editions.recordHoldersAria'))#</cfoutput>">
                    <cfoutput>
                        <cfif VARIABLES.eventBestMarksMenRecordSeconds GT 0>
                            <cfif len(VARIABLES.eventBestMarksMenRecordProfilePath)>
                                <a class="event-record-holder-card is-men is-clickable" href="#HTMLEditFormat(VARIABLES.eventBestMarksMenRecordProfilePath)#" title="#HTMLEditFormat(VARIABLES.eventBestMarksMenRecordName)#">
                            <cfelse>
                                <article class="event-record-holder-card is-men" title="#HTMLEditFormat(VARIABLES.eventBestMarksMenRecordName)#">
                            </cfif>
                                <img class="event-record-holder-avatar<cfif VARIABLES.eventBestMarksMenRecordUserId LTE 0> is-muted</cfif>"
                                     src="#HTMLEditFormat(VARIABLES.eventBestMarksMenRecordImage)#"
                                     alt=""
                                     loading="lazy"
                                     onerror="this.onerror=null; this.src='/assets/user.png';"/>
                                <div class="event-record-holder-body">
                                    <div class="event-record-holder-head">
                                        <span class="event-record-holder-icon"><span class="rr-gender-icon is-male" aria-hidden="true"></span></span>
                                        <span class="event-record-holder-label">#REQUEST.t('event.editions.maleRecord')#</span>
                                    </div>
                                    <div class="event-record-holder-time">#VARIABLES.eventBestMarksMenRecordLabel#</div>
                                    <cfif len(VARIABLES.eventBestMarksMenRecordName)>
                                        <div class="event-record-holder-athlete">#HTMLEditFormat(VARIABLES.eventBestMarksMenRecordName)#</div>
                                    <cfelse>
                                        <div class="event-record-holder-athlete">#REQUEST.t('event.editions.unknownRecordHolder')#</div>
                                    </cfif>
                                    <div class="event-record-holder-meta">#VARIABLES.eventBestMarksMenRecordYear#</div>
                                </div>
                            <cfif len(VARIABLES.eventBestMarksMenRecordProfilePath)>
                                </a>
                            <cfelse>
                                </article>
                            </cfif>
                        </cfif>
                        <cfif VARIABLES.eventBestMarksWomenRecordSeconds GT 0>
                            <cfif len(VARIABLES.eventBestMarksWomenRecordProfilePath)>
                                <a class="event-record-holder-card is-women is-clickable" href="#HTMLEditFormat(VARIABLES.eventBestMarksWomenRecordProfilePath)#" title="#HTMLEditFormat(VARIABLES.eventBestMarksWomenRecordName)#">
                            <cfelse>
                                <article class="event-record-holder-card is-women" title="#HTMLEditFormat(VARIABLES.eventBestMarksWomenRecordName)#">
                            </cfif>
                                <img class="event-record-holder-avatar<cfif VARIABLES.eventBestMarksWomenRecordUserId LTE 0> is-muted</cfif>"
                                     src="#HTMLEditFormat(VARIABLES.eventBestMarksWomenRecordImage)#"
                                     alt=""
                                     loading="lazy"
                                     onerror="this.onerror=null; this.src='/assets/user.png';"/>
                                <div class="event-record-holder-body">
                                    <div class="event-record-holder-head">
                                        <span class="event-record-holder-icon"><span class="rr-gender-icon is-female" aria-hidden="true"></span></span>
                                        <span class="event-record-holder-label">#REQUEST.t('event.editions.femaleRecord')#</span>
                                    </div>
                                    <div class="event-record-holder-time">#VARIABLES.eventBestMarksWomenRecordLabel#</div>
                                    <cfif len(VARIABLES.eventBestMarksWomenRecordName)>
                                        <div class="event-record-holder-athlete">#HTMLEditFormat(VARIABLES.eventBestMarksWomenRecordName)#</div>
                                    <cfelse>
                                        <div class="event-record-holder-athlete">#REQUEST.t('event.editions.unknownRecordHolder')#</div>
                                    </cfif>
                                    <div class="event-record-holder-meta">#VARIABLES.eventBestMarksWomenRecordYear#</div>
                                </div>
                            <cfif len(VARIABLES.eventBestMarksWomenRecordProfilePath)>
                                </a>
                            <cfelse>
                                </article>
                            </cfif>
                        </cfif>
                    </cfoutput>
                </div>
            </div>
        </div>
    </cfif>

    <cfif arrayLen(VARIABLES.eventBestMarksRows) AND VARIABLES.eventBestMarksMinSeconds GT 0 AND VARIABLES.eventBestMarksMaxSeconds GT 0>
        <div class="event-page-card mt-2">
            <div class="event-page-card-head">
                <h6 class="event-page-card-title"><i class="fa-solid fa-stopwatch me-1"></i><cfoutput>#REQUEST.t('event.editions.bestMarksVariation')#</cfoutput></h6>
            </div>
            <div class="event-page-card-body">
                <div class="event-best-marks-chart">
                    <div class="event-best-marks-history" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('event.editions.bestMarksAria'))#</cfoutput>">
                        <cfoutput>
                            <cfset VARIABLES.eventBestMarksVisibleIndex = 0/>
                            <cfloop from="#arrayLen(VARIABLES.eventBestMarksRows)#" to="1" step="-1" index="eventBestMarksTableIndex">
                                <cfset VARIABLES.eventBestMarksVisibleIndex = VARIABLES.eventBestMarksVisibleIndex + 1/>
                                <cfset eventBestMarksRow = VARIABLES.eventBestMarksRows[eventBestMarksTableIndex]/>
                                <cfset VARIABLES.eventBestMarksMenIsRecord = val(eventBestMarksRow['menSeconds']) GT 0 AND VARIABLES.eventBestMarksMenRecordSeconds GT 0 AND val(eventBestMarksRow['menSeconds']) EQ VARIABLES.eventBestMarksMenRecordSeconds/>
                                <cfset VARIABLES.eventBestMarksWomenIsRecord = val(eventBestMarksRow['womenSeconds']) GT 0 AND VARIABLES.eventBestMarksWomenRecordSeconds GT 0 AND val(eventBestMarksRow['womenSeconds']) EQ VARIABLES.eventBestMarksWomenRecordSeconds/>
                                <cfset VARIABLES.eventBestMarksMenRange = VARIABLES.eventBestMarksMenSlowestSeconds - VARIABLES.eventBestMarksMenRecordSeconds/>
                                <cfset VARIABLES.eventBestMarksWomenRange = VARIABLES.eventBestMarksWomenSlowestSeconds - VARIABLES.eventBestMarksWomenRecordSeconds/>
                                <cfset VARIABLES.eventBestMarksMenPercent = val(eventBestMarksRow['menSeconds']) GT 0 ? (VARIABLES.eventBestMarksMenRange GT 0 ? max(28, round(100 - (((val(eventBestMarksRow['menSeconds']) - VARIABLES.eventBestMarksMenRecordSeconds) / VARIABLES.eventBestMarksMenRange) * 72))) : 100) : 0/>
                                <cfset VARIABLES.eventBestMarksWomenPercent = val(eventBestMarksRow['womenSeconds']) GT 0 ? (VARIABLES.eventBestMarksWomenRange GT 0 ? max(28, round(100 - (((val(eventBestMarksRow['womenSeconds']) - VARIABLES.eventBestMarksWomenRecordSeconds) / VARIABLES.eventBestMarksWomenRange) * 72))) : 100) : 0/>
                                <cfset VARIABLES.eventBestMarksRowIsHidden = VARIABLES.eventBestMarksVisibleIndex GT VARIABLES.eventBestMarksVisibleLimit AND NOT eventBestMarksRow['isCurrent']/>
                                <cfset VARIABLES.eventBestMarksRowTag = structKeyExists(eventBestMarksRow, "eventTag") ? trim(eventBestMarksRow['eventTag'] & "") : ""/>
                                <cfset VARIABLES.eventBestMarksRowPath = ""/>
                                <cfif len(VARIABLES.eventBestMarksRowTag)>
                                    <cfif structKeyExists(REQUEST, "i18nBuildPath")>
                                        <cfset VARIABLES.eventBestMarksRowRouteParams = duplicate(VARIABLES.eventEditionsCurrentRouteParams)/>
                                        <cfset VARIABLES.eventBestMarksRowRouteParams["tag"] = VARIABLES.eventBestMarksRowTag/>
                                        <cfset REQUEST.currentRouteParams = VARIABLES.eventBestMarksRowRouteParams/>
                                        <cfset VARIABLES.eventBestMarksRowPath = REQUEST.i18nBuildPath("event")/>
                                        <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionsCurrentRouteParams/>
                                    <cfelse>
                                        <cfset VARIABLES.eventBestMarksRowPath = "/evento/#VARIABLES.eventBestMarksRowTag#/"/>
                                    </cfif>
                                </cfif>
                                <cfif len(VARIABLES.eventBestMarksRowPath)>
                                    <a class="event-best-marks-history-row is-clickable<cfif eventBestMarksRow['isCurrent']> is-current</cfif><cfif VARIABLES.eventBestMarksRowIsHidden> d-none</cfif>"
                                       href="#HTMLEditFormat(VARIABLES.eventBestMarksRowPath)#"
                                       title="<cfif eventBestMarksRow['isCurrent']>#encodeForHTMLAttribute(REQUEST.t('event.editions.currentYearTitle'))#<cfelse>#encodeForHTMLAttribute(REQUEST.t('event.editions.viewYearTitle', { 'year' = eventBestMarksRow['year'] }))#</cfif>"
                                       <cfif VARIABLES.eventBestMarksRowIsHidden>data-event-best-marks-extra="true"</cfif>>
                                <cfelse>
                                    <div class="event-best-marks-history-row<cfif eventBestMarksRow['isCurrent']> is-current</cfif><cfif VARIABLES.eventBestMarksRowIsHidden> d-none</cfif>"
                                         <cfif eventBestMarksRow['isCurrent']>title="#encodeForHTMLAttribute(REQUEST.t('event.editions.currentYearTitle'))#"</cfif>
                                         <cfif VARIABLES.eventBestMarksRowIsHidden>data-event-best-marks-extra="true"</cfif>>
                                </cfif>
                                    <span class="event-best-marks-year">#eventBestMarksRow['year']#</span>
                                    <span class="event-best-marks-lines">
                                        <span class="event-best-marks-line-item is-men<cfif VARIABLES.eventBestMarksMenIsRecord> is-record</cfif><cfif NOT len(trim(eventBestMarksRow['menLabel'] & ""))> is-empty</cfif>">
                                            <span class="event-best-marks-gender-icon"><span class="rr-gender-icon is-male" aria-hidden="true"></span></span>
                                            <span class="event-best-marks-time"><cfif len(trim(eventBestMarksRow['menLabel'] & ""))>#eventBestMarksRow['menLabel']#<cfif VARIABLES.eventBestMarksMenIsRecord><i class="fa-solid fa-trophy event-best-marks-record-trophy" aria-hidden="true"></i></cfif><cfelse>-</cfif></span>
                                            <span class="event-best-marks-track" title="#encodeForHTMLAttribute(REQUEST.t('event.editions.maleTimeTitle', { 'year' = eventBestMarksRow['year'], 'time' = eventBestMarksRow['menLabel'] }))#">
                                                <cfif VARIABLES.eventBestMarksMenPercent GT 0><span class="event-best-marks-bar" style="width:#VARIABLES.eventBestMarksMenPercent#%"></span></cfif>
                                            </span>
                                        </span>
                                        <span class="event-best-marks-line-item is-women<cfif VARIABLES.eventBestMarksWomenIsRecord> is-record</cfif><cfif NOT len(trim(eventBestMarksRow['womenLabel'] & ""))> is-empty</cfif>">
                                            <span class="event-best-marks-gender-icon"><span class="rr-gender-icon is-female" aria-hidden="true"></span></span>
                                            <span class="event-best-marks-time"><cfif len(trim(eventBestMarksRow['womenLabel'] & ""))>#eventBestMarksRow['womenLabel']#<cfif VARIABLES.eventBestMarksWomenIsRecord><i class="fa-solid fa-trophy event-best-marks-record-trophy" aria-hidden="true"></i></cfif><cfelse>-</cfif></span>
                                            <span class="event-best-marks-track" title="#encodeForHTMLAttribute(REQUEST.t('event.editions.femaleTimeTitle', { 'year' = eventBestMarksRow['year'], 'time' = eventBestMarksRow['womenLabel'] }))#">
                                                <cfif VARIABLES.eventBestMarksWomenPercent GT 0><span class="event-best-marks-bar" style="width:#VARIABLES.eventBestMarksWomenPercent#%"></span></cfif>
                                            </span>
                                        </span>
                                    </span>
                                <cfif len(VARIABLES.eventBestMarksRowPath)>
                                    </a>
                                <cfelse>
                                    </div>
                                </cfif>
                            </cfloop>
                        </cfoutput>
                    </div>

                    <cfif arrayLen(VARIABLES.eventBestMarksRows) GT VARIABLES.eventBestMarksVisibleLimit>
                        <div class="event-best-marks-more">
                            <button type="button" class="btn btn-light w-100" data-event-best-marks-expand>
                                <cfoutput>#REQUEST.t('event.editions.allYears')#</cfoutput>
                            </button>
                        </div>
                    </cfif>

                    <p class="event-best-marks-caption"><cfoutput>#REQUEST.t('event.editions.bestMarksCaption')#</cfoutput></p>
                </div>
            </div>
        </div>
    </cfif>

    <cfset REQUEST.currentRouteParams = VARIABLES.eventEditionsCurrentRouteParams/>

    <cfif (VARIABLES.eventEditionsSameCityCount GT VARIABLES.eventEditionsVisibleLimit OR arrayLen(VARIABLES.eventEditionsChartYears) GT VARIABLES.eventEditionsChartVisibleLimit OR arrayLen(VARIABLES.eventBestMarksRows) GT VARIABLES.eventBestMarksVisibleLimit) AND NOT isDefined("REQUEST.eventEditionsJsLoaded")>
        <cfset REQUEST.eventEditionsJsLoaded = true/>
        <script>
            document.addEventListener('click', (event) => {
                const trigger = event.target.closest('[data-event-editions-expand]');
                const chartTrigger = event.target.closest('[data-event-editions-chart-expand]');
                const bestMarksTrigger = event.target.closest('[data-event-best-marks-expand]');

                if (!trigger && !chartTrigger && !bestMarksTrigger) {
                    return;
                }

                if (trigger) {
                    document.querySelectorAll('[data-event-edition-extra="true"]').forEach((item) => {
                        item.classList.remove('d-none');
                    });

                    trigger.closest('.event-editions-more').classList.add('d-none');
                }

                if (chartTrigger) {
                    document.querySelectorAll('[data-event-editions-chart-extra="true"]').forEach((item) => {
                        item.classList.remove('d-none');
                    });

                    chartTrigger.closest('.event-editions-chart-more').classList.add('d-none');
                }

                if (bestMarksTrigger) {
                    document.querySelectorAll('[data-event-best-marks-extra="true"]').forEach((item) => {
                        item.classList.remove('d-none');
                    });

                    bestMarksTrigger.closest('.event-best-marks-more').classList.add('d-none');
                }
            });
        </script>
    </cfif>
</cfif>
