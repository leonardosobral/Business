<div class="col-12 mb-1">

    <cfset VARIABLES.liveEventType = isDefined("tipo_corrida") ? lCase(trim(tipo_corrida & "")) : "" />

    <cfif isDefined("tag") AND len(trim(tag)) AND structKeyExists(REQUEST, "i18nBuildPath")>
        <cfset VARIABLES.liveEventCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
        <cfset VARIABLES.liveEventRouteParams = duplicate(VARIABLES.liveEventCurrentRouteParams) />
        <cfset VARIABLES.liveEventRouteParams["tag"] = trim(tag) />
        <cfset REQUEST.currentRouteParams = VARIABLES.liveEventRouteParams />
        <cfset VARIABLES.liveEventPath = REQUEST.i18nBuildPath("event") />
        <cfset REQUEST.currentRouteParams = VARIABLES.liveEventCurrentRouteParams />
    <cfelse>
        <cfset VARIABLES.liveEventPath = "/evento/#tag#/" />
    </cfif>

    <cfif NOT isDefined("REQUEST.liveEventCardCssLoaded")>
        <cfset REQUEST.liveEventCardCssLoaded = true/>
        <style>
            .live-event-card {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #ffffff;
                overflow: hidden;
            }

            .live-event-card-link {
                display: block;
                color: #333333;
                text-decoration: none;
            }

            .live-event-card-body {
                padding: 0.95rem;
            }

            .live-event-card-top {
                display: grid;
                grid-template-columns: 62px minmax(0, 1fr);
                gap: 0.85rem;
                align-items: start;
            }

            .live-event-card-date {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .live-event-card-date .day {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.75rem 0.2rem 0.2rem;
            }

            .live-event-card-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.08em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .live-event-card-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .live-event-card-title {
                color: #333333;
                font-size: 1rem;
                font-weight: 700;
                line-height: 1.25;
                margin-bottom: 0.4rem;
            }

            .live-event-card-meta {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.82rem;
                line-height: 1.35;
            }

            .live-event-card-meta i {
                color: #fab120;
            }

            .live-event-card-flags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.4rem;
                margin-top: 0.65rem;
            }

            .live-event-flag {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 0.38rem 0.65rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.1);
                background-color: #efefef;
                color: #333333;
                font-size: 0.74rem;
                font-weight: 700;
                line-height: 1;
            }

            .live-event-flag.is-coupon {
                background-color: #fab120;
                border-color: #fab120;
                color: #333333;
                font-weight: 800;
            }

            .live-event-card-distances {
                display: flex;
                flex-wrap: wrap;
                gap: 0.45rem;
                margin-top: 0.8rem;
            }

            .live-event-distance {
                display: inline-flex;
                align-items: center;
                gap: 0.35rem;
                padding: 0.42rem 0.68rem;
                border-radius: 8px;
                border: 1px solid rgba(250, 177, 32, 0.5);
                background-color: #fff8e6;
                color: #333333;
                font-size: 0.8rem;
                font-weight: 700;
                line-height: 1;
            }

            .live-event-card-badges {
                display: flex;
                flex-wrap: wrap;
                gap: 0.35rem;
                margin-top: 0.8rem;
                padding-top: 0.8rem;
                border-top: 1px solid rgba(51, 51, 51, 0.08);
            }
        </style>
    </cfif>

    <cfoutput>
        <a href="#VARIABLES.liveEventPath#" class="live-event-card-link">
            <div class="live-event-card" id="#tag#">
                <div class="live-event-card-body">
                    <div class="live-event-card-top">
                        <div class="live-event-card-date">
                            <span class="day">#lsDateFormat(data_final,"dd")#</span>
                            <span class="month">#lsDateFormat(data_final,"mmm")#</span>
                            <span class="year">#lsDateFormat(data_final,"y")#</span>
                        </div>

                        <div class="min-w-0">
                            <div class="live-event-card-title <cfif status_evento EQ "cancelado">text-gray-light</cfif>">
                                #nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif>
                            </div>

                            <div class="live-event-card-meta">
                                <i class="fa-solid fa-location-dot me-1"></i>#cidade#<cfif len(estado)>&nbsp;-&nbsp;#estado#</cfif>
                            </div>

                            <div class="live-event-card-flags">
                                <cfif len(trim(cupom)) AND data_final GTE now()>
                                    <span class="live-event-flag is-coupon"><i class="fa-solid fa-ticket me-1"></i>Cupom #cupom#</span>
                                </cfif>
                                <cfif VARIABLES.liveEventType EQ "rua">
                                    <span class="live-event-flag">#REQUEST.t("search.eventList.roadRace")#</span>
                                <cfelseif VARIABLES.liveEventType EQ "treino">
                                    <span class="live-event-flag">#REQUEST.t("search.eventList.training")#</span>
                                <cfelseif len(VARIABLES.liveEventType)>
                                    <span class="live-event-flag">#REQUEST.t("search.eventList.trailRun")#</span>
                                </cfif>
                            </div>

                            <cfif VARIABLES.liveEventType NEQ "treino">
                                <div class="live-event-card-distances">
                                    <cfloop list="#categorias#" delimiters="," index="distancia">
                                        <span class="live-event-distance">
                                            <i class="fa-solid <cfif VARIABLES.liveEventType EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif>"></i>
                                            #trim(REReplace(distancia,"[^0-9.]", "","ALL"))#km
                                        </span>
                                    </cfloop>
                                </div>
                            </cfif>

                            <cfif isDefined("VARIABLES.liveCircuitCouponCards") AND VARIABLES.liveCircuitCouponCards>
                                <span class="live-event-card-cta"><cfif len(trim(cupom)) AND data_final GTE now() AND status_evento NEQ "cancelado">Ver prova e cupom<cfelse>Ver prova</cfif><i class="fa-solid fa-arrow-right ms-1" aria-hidden="true"></i></span>
                            </cfif>

                            <cfif Len(badges) AND arraylen(deserializeJSON(badges))>
                                <div class="live-event-card-badges">
                                    <cfset VARIABLES.ultimoBadge = ""/>
                                    <cfloop array="#deserializeJSON(badges)#" index="badge">
                                        <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                            <img src="/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#badge.badge_tooltip#" title="#badge.badge_tooltip#" class="d-inline rounded" width="24px" height="24px" data-mdb-tooltip-init>
                                        </cfif>
                                        <cfset VARIABLES.ultimoBadge = badge.badge/>
                                    </cfloop>
                                </div>
                            </cfif>
                        </div>
                    </div>
                </div>
            </div>
        </a>
    </cfoutput>
</div>
