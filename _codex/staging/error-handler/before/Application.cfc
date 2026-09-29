<cfcomponent
        displayname="Application"
        output="true"
        hint="Handle the application.">


    <!--- APPLICATION SETUP --->
    <cfset THIS.Name = "RoadRunners" />
    <cfset THIS.ApplicationTimeout = CreateTimeSpan( 2, 0, 0, 0 ) />
    <cfset THIS.SessionManagement = true />
    <cfset THIS.SetClientCookies = true />
    <cfset THIS.SearchImplicitScopes = true />
    <cfset THIS.SessionTimeout = createTimeSpan( 0, 0, 50, 0 ) />
    <cfset THIS.datasource = "runnerhub"/>
    <cfset THIS.serialization.preservecaseforstructkey = true/>
    <cfset oldlocale = SetLocale("Portuguese (Brazilian)")>


    <!--- Define the page request properties. --->
    <cfsetting
            requesttimeout="20"
            showdebugoutput="false"
            enablecfoutputonly="false"
            />


    <cffunction
            name="OnApplicationStart"
            access="public"
            returntype="boolean"
            output="false"
            hint="Fires when the application is first created.">

        <!--- APPLICATION VARIABLES --->
        <cfset APPLICATION.codSite = "RR"/>
        <cfset APPLICATION.nomeSite = "Road Runners"/>
        <cfset APPLICATION.dominio = "roadrunners.run"/>
        <cfset APPLICATION.baseCanonica = "https://roadrunners.run"/>
        <cfset APPLICATION.ga = "G-7MYGVTEDZV"/>
        <cfset ensureAppSettings()/>
        <cfset ensureI18nCatalog()/>

        <!--- Return out. --->
        <cfreturn true />
    </cffunction>


    <cffunction
            name="OnSessionStart"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the session is first created.">

        <cfset initSessionUsuarioCache() />

        <!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnRequestStart"
            access="public"
            returntype="boolean"
            output="false"
            hint="Fires at first part of page processing.">

        <!--- Define arguments. --->
        <cfargument
                name="TargetPage"
                type="string"
                required="true"
                />

        <cfif IsDefined("url.resetApp")>
          <cfset ApplicationStop()>
          <cfabort><!--- or, if you like, <cflocation url="index.cfm"> --->
        </cfif>

        <cfset ensureAppSettings()/>
        <cfset ensureI18nCatalog()/>
        <cfset REQUEST.requestId = lCase(createUUID())/>
        <cfset initSessionUsuarioCache()/>
        <cfset REQUEST.Usuario = buildRequestUsuario()/>
        <cfset REQUEST.currentEnvironment = getCurrentEnvironment()/>
        <cfset REQUEST.currentBaseUrl = getEnvironmentBaseUrl(REQUEST.currentEnvironment)/>
        <cfset REQUEST.apiIntegration = buildEmptyApiIntegration()/>
        <cfif isApiBearerCandidateRequest()>
            <cfset REQUEST.apiIntegration = buildRequestApiIntegration()/>
        </cfif>
        <cfset hydrateRequestUsuarioFromApiIntegration()/>
        <cfset hydrateRequestI18n()/>
        <cfset applyRequestLocale()/>
        <cfset processEnvironmentHandoff()/>
        <cfset enforceApiBearerAccess()/>
        <cfset enforceAuthenticatedJsonApiAccess()/>
        <cfset enforceBetaAccess()/>

        <!--- Reuse known location on every request, without external lookup or cookies. --->
        <cftry>
            <cfset LOCAL.availableLocation = new services.LocationResolver().resolveAvailable() />
            <!--- Leave cold misses absent so route-specific full resolvers still run. --->
            <cfif NOT LOCAL.availableLocation.isFallback>
                <cfset REQUEST.LocationContext = LOCAL.availableLocation />
            </cfif>
            <cfcatch type="any">
                <!--- Location is optional; never interrupt the request on a cache failure. --->
            </cfcatch>
        </cftry>

        <!---cftry>
            <cfquery>
                INSERT INTO webtumtum.logs
                (texto, tag, tipo, session_id, user_id)
                VALUES
                (<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.script_name#"/>,
                <cfif isDefined("URL.tag")>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')##URL.tag#"/>,
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')#"/>,
                </cfif>
                'acesso',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#SESSION.SESSIONID#"/>,
                <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND structKeyExists(REQUEST.Usuario, "logado") AND REQUEST.Usuario.logado>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.Usuario.id#"/>
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value=""/>
                </cfif>)
            </cfquery>
        <cfcatch type="any">
            <cfquery>
                INSERT INTO webtumtum.logs
                (texto, tipo)
                VALUES
                (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.TargetPage#"/>,
                'erro'
                )
            </cfquery>
        </cfcatch>
        </cftry--->

        <!--- Return out. --->
        <cfreturn true />
    </cffunction>

    <cffunction name="ensureAppSettings" access="public" returntype="void" output="false">
        <cfif NOT structKeyExists(APPLICATION, "aiSearch")
            OR NOT isStruct(APPLICATION.aiSearch)
            OR NOT structKeyExists(APPLICATION.aiSearch, "endpoint")
            OR NOT structKeyExists(APPLICATION.aiSearch, "configVersion")
            OR APPLICATION.aiSearch.configVersion NEQ "2026-09-11-3"
            OR NOT structKeyExists(APPLICATION, "seoVerification")
            OR NOT isStruct(APPLICATION.seoVerification)
            OR NOT structKeyExists(APPLICATION, "vickyAgent")
            OR NOT isStruct(APPLICATION.vickyAgent)
            OR NOT structKeyExists(APPLICATION.vickyAgent, "knowledgeApiKey")
            OR (
                (
                    NOT structKeyExists(APPLICATION.vickyAgent, "apiKey")
                    OR NOT len(trim(APPLICATION.vickyAgent.apiKey & ""))
                )
                AND (
                    NOT structKeyExists(APPLICATION, "vickyAgentConfigRetryAfter")
                    OR dateCompare(now(), APPLICATION.vickyAgentConfigRetryAfter, "s") GTE 0
                )
            )
            OR NOT structKeyExists(APPLICATION, "vickyProactive")
            OR NOT isStruct(APPLICATION.vickyProactive)
            OR NOT structKeyExists(APPLICATION.vickyProactive, "whatsappProvider")
            OR NOT structKeyExists(APPLICATION, "metaWhatsappVicky")
            OR NOT isStruct(APPLICATION.metaWhatsappVicky)
            OR NOT structKeyExists(APPLICATION, "handoff")
            OR NOT isStruct(APPLICATION.handoff)
            OR NOT structKeyExists(APPLICATION.handoff, "secret")
            OR NOT structKeyExists(APPLICATION, "specialGroups")
            OR NOT isStruct(APPLICATION.specialGroups)
            OR NOT structKeyExists(APPLICATION.specialGroups, "secret")
            OR NOT structKeyExists(APPLICATION, "stravaIntegration")
            OR NOT isStruct(APPLICATION.stravaIntegration)
            OR NOT structKeyExists(APPLICATION.stravaIntegration, "gorunnersAudienceEnabled")
            OR NOT structKeyExists(APPLICATION.stravaIntegration, "streamsEnabled")
            OR NOT structKeyExists(APPLICATION, "apiIntegrations")
            OR NOT isStruct(APPLICATION.apiIntegrations)
            OR NOT structKeyExists(APPLICATION, "mobileAuth")
            OR NOT isStruct(APPLICATION.mobileAuth)
            OR NOT structKeyExists(APPLICATION, "audienceMeasurement")
            OR NOT isStruct(APPLICATION.audienceMeasurement)
            OR NOT structKeyExists(APPLICATION.audienceMeasurement, "hosts")
            OR NOT isStruct(APPLICATION.audienceMeasurement.hosts)
            OR NOT structKeyExists(APPLICATION, "audienceMeasurementRateLimits")
            OR NOT isStruct(APPLICATION.audienceMeasurementRateLimits)>
            <cfinclude template="/config/settings.cfm"/>
            <cfif NOT structKeyExists(APPLICATION.vickyAgent, "apiKey") OR NOT len(trim(APPLICATION.vickyAgent.apiKey & ""))>
                <cfset APPLICATION.vickyAgentConfigRetryAfter = dateAdd("n", 1, now()) />
            <cfelse>
                <cfset structDelete(APPLICATION, "vickyAgentConfigRetryAfter", false) />
            </cfif>
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="ensureI18nCatalog" access="private" returntype="void" output="false">
        <cfset var langCode = "" />
        <cfset var languageFiles = ["pt-BR", "en", "es"] />
        <cfset var loadedCatalog = {} />
        <cfset var localesCatalog = {} />
        <cfset var currentCatalogSignature = getI18nCatalogSignature() />

        <cfif isI18nCatalogReady(currentCatalogSignature)>
            <cfreturn />
        </cfif>

        <cflock scope="application" type="exclusive" timeout="10">
            <cfset currentCatalogSignature = getI18nCatalogSignature() />

            <cfif isI18nCatalogReady(currentCatalogSignature)>
                <cfreturn />
            </cfif>

            <cfset loadedCatalog = {} />

            <cfloop array="#languageFiles#" index="langCode">
                <cfset localesCatalog = {} />
                <cfinclude template="/i18n/#langCode#.cfm" />
                <cfset loadedCatalog[langCode] = duplicate(localesCatalog) />
            </cfloop>

            <cfset APPLICATION.i18nCatalog = loadedCatalog />
            <cfset APPLICATION.i18nCatalogSignature = currentCatalogSignature />
            <cfset APPLICATION.i18nConfig = {
                "defaultLanguage" = "pt-BR",
                "availableLanguages" = [
                    { "code" = "pt-BR", "pathCode" = "", "label" = "Portugues (Brasil)", "shortLabel" = "PT", "hreflang" = "pt-BR" },
                    { "code" = "en", "pathCode" = "en", "label" = "English", "shortLabel" = "EN", "hreflang" = "en" },
                    { "code" = "es", "pathCode" = "es", "label" = "Espanol", "shortLabel" = "ES", "hreflang" = "es" }
                ]
            } />
            <cfset APPLICATION.i18nRoutes = getI18nRouteDefinitions() />
        </cflock>

        <cfreturn />
    </cffunction>

    <cffunction name="isI18nCatalogReady" access="private" returntype="boolean" output="false">
        <cfargument name="expectedSignature" type="string" required="false" default="" />
        <cfset var requiredLanguages = ["pt-BR", "en", "es"] />
        <cfset var requiredSections = ["common", "home", "notFound", "search", "news", "videos", "event", "agenda", "challenges", "results", "athlete", "support", "help", "about", "privacy", "notifications"] />
        <cfset var requiredCommonSections = ["header", "slimHeader", "footer", "languages", "cookie", "loginModal", "stravaConnectModal", "betaModal", "shareModal", "eventSuggestionModal", "eventEditModal", "paymentModal", "companyRegistrationModal", "certificatePage", "healthCard", "retrospectivePage", "appsMenu", "activitySidebar", "themeHeader", "permits", "weekdays", "pwa"] />
        <cfset var requiredCommonRootKeys = ["languageSwitcherLabel", "mapTitle"] />
        <cfset var requiredCommonWeekdayShortKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] />
        <cfset var requiredCommonHeaderKeys = ["login", "notifications", "noNotifications", "markAllNotificationsRead", "markAllNotificationsReadError", "myProfile", "myAccount", "about", "privacy", "help", "support", "logout", "whatsappChannel", "store", "home", "search", "activities", "events", "installApp", "toggleSearch", "eventSearchPlaceholder"] />
        <cfset var requiredCommonPwaKeys = ["updateTitle", "updateText", "updateAction", "dismiss", "installPromptTitle", "installPromptText", "installPromptAction", "installPromptDismiss", "iosInstallTitle", "iosInstallText", "iosInstallStepShare", "iosInstallStepHome", "close"] />
        <cfset var requiredCommonSlimHeaderKeys = ["openResultsLink", "legacyChallengeLink", "runNewsLink", "adminTitle", "rhAdmin", "devEnvironment", "backToUser", "editEvent", "importWiclax", "importExcel", "importNewsFeed", "importYoutubeFeed"] />
        <cfset var requiredCommonFooterKeys = ["tagline", "description", "explore", "athletes", "institutional", "events", "activities", "results", "news", "videos", "profile", "agenda", "challenges", "settings", "about", "help", "support", "privacy", "ecosystem", "ecosystemLabel", "follow", "rights", "navigationLabel", "socialLabel", "top", "madeInBrazil", "companyDocument", "backToTop", "instagramLink", "stravaLink", "whatsappLink", "betaLink"] />
        <cfset var requiredCommonCookieKeys = ["message", "accept", "learnMore"] />
        <cfset var requiredCommonLoginModalKeys = ["closeAria", "logoAlt", "betaKicker", "betaTitle", "betaCopy", "publicIntro", "webviewCopy"] />
        <cfset var requiredCommonStravaConnectModalKeys = ["logoAlt", "title", "copy", "connect", "dismiss", "dontShowAgain", "initError"] />
        <cfset var requiredCommonBetaModalKeys = ["kicker", "title", "copy", "newsTitle", "featureLayout", "featureSearch", "featureNews", "dismiss", "goToBeta", "initError"] />
        <cfset var requiredCommonShareModalKeys = ["title", "copyLink", "cancelledTag"] />
        <cfset var requiredCommonEventSuggestionModalKeys = ["title", "fields", "distanceHelp", "submit", "success", "closeWindow"] />
        <cfset var requiredCommonEventEditModalKeys = ["title", "fields", "distanceHelp", "submit"] />
        <cfset var requiredCommonEventModalFieldKeys = ["eventName", "startDate", "endDate", "city", "state", "registrationLink", "distances"] />
        <cfset var requiredCommonPaymentModalKeys = ["title", "fields", "paymentMethod", "pix", "creditCard", "submit", "unavailable", "countryBrazil"] />
        <cfset var requiredCommonPaymentModalFieldKeys = ["fullName", "ddi", "ddd", "phone", "cpf", "cardName", "cardNumber", "month", "year", "cvv", "address", "zipCode", "city", "state", "country"] />
        <cfset var requiredCommonCompanyRegistrationModalKeys = ["title", "closeAria", "fields", "categories", "summaryPlaceholder", "submit"] />
        <cfset var requiredCommonCompanyRegistrationFieldKeys = ["name", "category", "document", "website", "summary"] />
        <cfset var requiredCommonCompanyRegistrationCategoryKeys = ["placeholder", "organizer", "timer", "coaching"] />
        <cfset var requiredCommonCertificatePageKeys = ["documentTitle", "invalidInfo", "pageTitle", "prompt", "namePlaceholder", "dateTime", "yourIp", "system", "submit"] />
        <cfset var requiredCommonHealthCardKeys = ["pageTitle", "metaTitle", "metaDescription", "kicker", "edit", "emergencyCall", "identificationTitle", "fullName", "document", "phoneWhatsapp", "birthDate", "sex", "sexMale", "sexFemale", "bloodType", "medicalTitle", "weight", "height", "chronicDiseases", "allergies", "medications", "surgeries", "emergencyContactTitle", "contactName", "relationship", "careInsuranceTitle", "insurancePlan", "insuranceId", "reportIncident", "eventMedicalTeam", "ofEvent", "emergencyContactButton", "ofEmergency", "updatedAt", "restrictedNotice"] />
        <cfset var requiredCommonRetrospectivePageKeys = ["pageTitle", "metaTitle", "metaDescription", "kicker", "customize", "howFarTitle", "howFarIntro", "racesLabel", "whichAddUp", "distanceLabel", "andDurationOf", "durationLabel", "howFarEquivalent", "marathonsLabel", "sameAs", "tripsToSpaceLabel", "karmanFootnote", "share", "marksTitle", "overall", "category", "pace", "route", "personalRecord", "average", "officialResultsFootnote", "whereTitle", "location", "time", "kilometers", "outsideStatePrefix", "trainingTitle", "type", "trainingFootnote", "ranWithMeTitle", "companionPhoto", "companionRaces", "companionDistance", "challengedMyselfTitle", "challengeDaysRunning", "challengeBestStreak", "challengeDistance", "challengeElevation", "challengeTime", "rememberRaceTitle", "rememberRaceCopy", "achievementsTitle", "summaryTitle", "updatedAt"] />
        <cfset var requiredCommonAppsMenuKeys = ["title", "roadRunners", "roadRunnersAlt", "openResults", "openResultsAlt", "runnersStore", "runnersStoreAlt", "desafioSupra", "desafioSupraAlt", "circuitoCatarinense", "circuitoCatarinenseAlt", "todoSantoDia", "todoSantoDiaAlt", "poweredBy"] />
        <cfset var requiredCommonActivitySidebarKeys = ["title", "viewAll", "suggestionsKicker", "suggestionsTitle", "suggestionsCopy", "mutualContact", "mutualContacts", "post", "agenda", "video", "activity", "todoSantoDia", "result", "empty", "marathonsBrazilAlt", "brazilGiantAlt", "stravaConnectAlt"] />
        <cfset var requiredCommonThemeHeaderKeys = ["website", "instagram", "appStore", "playStore", "logoAltOrganizer", "logoAltEvent"] />
        <cfset var requiredCommonPermitKeys = ["cbatGold", "cbatSilver", "cbatBronze", "worldAthletics"] />
        <cfset var requiredHomeKeys = ["meta", "featured", "spotlight", "upcoming", "recentResults"] />
        <cfset var requiredHomeMetaKeys = ["title", "description", "keywords"] />
        <cfset var requiredHomeFeaturedKeys = ["kicker"] />
        <cfset var requiredHomeSpotlightKeys = ["kicker", "title", "copy", "futureTag", "pastTag", "editionsLabel", "finishersLabel", "algorithmNote", "ctaFuture", "ctaPast", "prevAria", "nextAria"] />
        <cfset var requiredHomeUpcomingKeys = ["title", "copy", "cta", "emptyTitle", "emptyCopy"] />
        <cfset var requiredHomeRecentResultsKeys = ["title", "copy", "cta", "emptyTitle", "emptyCopy"] />
        <cfset var requiredNotFoundKeys = ["meta", "kicker", "title", "copy", "searchCta", "homeCta", "calendarCta", "resultsCta"] />
        <cfset var requiredNotFoundMetaKeys = ["title", "description", "keywords"] />
        <cfset var requiredAgendaKeys = ["meta", "hero", "loginCta", "emptyOwn", "emptyOther"] />
        <cfset var requiredSearchKeys = ["meta", "hero", "legacy", "form", "debug", "loading", "tabs", "sections", "filters", "eventList"] />
        <cfset var requiredSearchLegacyKeys = ["heroKicker", "heroTitle", "heroCopy", "futureTab", "pastTab"] />
        <cfset var requiredSearchFilterKeys = ["toggle", "toggleExpanded", "toggleCollapsed", "stateTitle", "statePlaceholder", "currentState", "stateShowing", "statePrompt", "distanceKm", "periodMonths", "modality", "street", "trail", "territory", "brazil", "international", "extras", "couponOnly", "ultra", "apply"] />
        <cfset var requiredSearchEventListKeys = ["results", "photos", "wantToGo", "registered", "challenge", "leaveChallenge", "cancelledTag", "finishersCount", "coupon", "roadRace", "training", "trailRun", "confirmedPresence", "inAgenda", "resultOptions", "unlinkRace", "completedRace", "remove", "save", "googleCalendar", "registeredAthlete", "overall", "categoryShort", "pace", "time", "bib", "sponsored"] />
        <cfset var requiredChallengesKeys = ["meta", "hero", "sections", "labels", "actions", "status", "period", "counts", "details", "detailPage", "calendar", "empty"] />
        <cfset var requiredChallengeSectionKeys = ["athlete", "mine", "calendar", "new", "soon", "ended"] />
        <cfset var requiredChallengeDetailsKeys = ["day", "distance", "activities", "time", "detailsToggle", "activeDays", "distanceCovered", "activeDaysValue", "totalDistanceValue", "daysSummary", "totalWithKm", "monthDistanceWithKm", "waitingStrava", "organizer", "backing", "help", "rules", "support", "store", "hotsite", "vipGroup", "waived"] />
        <cfset var requiredChallengeDetailPageKeys = ["activeKicker", "participatingSince", "refresh", "refreshedToday", "refreshDailyHint", "refreshing", "beVip", "partnerStore", "newChallengeKicker", "newChallengeTitle", "currentStreak", "daySingular", "dayPlural", "runningSince", "bestStreak", "countingSince", "challengeYear", "challengeHeadline365", "eligibilityCopy365", "accessHotsite", "enrollmentPendingAlert", "confirmRegistration", "askSupport", "shirtImageAlt", "coverImageAlt", "presentationKicker", "followWithLogin"] />
        <cfset var requiredChallengeCalendarKeys = ["waiverOn", "noActivityOn", "activitiesOn", "statusWaived", "statusNotValidated", "statusValidatedWithRemark", "statusValidated"] />
        <cfset var requiredActivitiesKeys = ["meta", "hero", "filtersAria", "filters", "emptyTitle", "emptyText", "previous", "next", "loadMore", "loginCard"] />
        <cfset var requiredResultsKeys = ["meta", "hero", "loginCard", "optimizer", "suggestions", "recognized", "emptyOwn", "emptyOther", "suggestionCard"] />
        <cfset var requiredNewsKeys = ["meta", "routes", "hero", "search", "filters", "detail", "channel", "list", "pagination", "gallery", "sidebar"] />
        <cfset var requiredVideosKeys = ["meta", "routes", "hero", "search", "filters", "detail", "list", "pagination", "sidebar"] />
        <cfset var requiredEditorialHeroKeys = ["title", "aggregatorLabel", "aggregatorCopy"] />
        <cfset var requiredEventKeys = ["meta", "actions", "sections", "description", "suppliers", "ticketSports", "participants", "editions", "weather"] />
        <cfset var requiredAthleteKeys = ["meta", "photo", "actions", "stats", "tabs", "alerts", "social", "feed", "followersModal", "sidebar", "settings", "badgesModal", "legacyEditModal", "coupons", "profileMini", "stravaTable"] />
        <cfset var requiredAthletePhotoKeys = ["changeAria", "expandAria", "imageAlt", "verifiedAlt", "verifiedTitle", "verifyTitle", "editorTitleOwn", "editorTitleView", "editorIntro", "editorPreviewAlt", "editorPreviewLabel", "editorChoose", "editorSave", "editorZoomOutAria", "editorZoomInAria", "editorReset", "editorNote", "editorViewerAlt", "editorInvalidImage", "editorChooseBeforeSave", "editorPrepareError", "editorSaveSuccess", "editorSaveError"] />
        <cfset var requiredNotificationsKeys = ["api", "push", "social", "support"] />
        <cfset var requiredNotificationsApiKeys = ["notAuthenticated", "invalidNotificationOrAll", "handoffExpired", "invalidHandoffSignature", "invalidDispatchPayload"] />
        <cfset var requiredNotificationsPushKeys = ["defaultTitle", "defaultFallbackBody", "noPending", "notEnabled", "browserUnsupported", "permissionDenied", "activationUnavailable", "siteBlocked", "alreadyActive", "activationFailed", "noDeviceSubscription", "subscriptionPayloadMissing", "subscriptionPayloadInvalid", "subscriptionFieldsMissing", "subscriptionEndpointRequired", "subscriptionActivated", "subscriptionDeactivated", "subscriptionReset", "testAdminOnly", "noActiveSubscription", "menuActivate", "menuEnable", "menuActive", "menuReactivate", "preferencesMenu", "preferencesTitle", "preferencesText", "preferenceGeneral", "preferenceResults", "preferenceChallenges", "preferenceSupport", "preferenceSystem", "preferencesSave", "preferencesSaved", "preferencesError", "promptApp", "promptActivateTitle", "promptReactivateTitle", "promptActivateText", "promptReactivateText", "promptDismiss", "promptActivating", "promptReactivating", "promptRetry", "promptRetryReactivate", "promptSource", "invalidHandoffSignature", "invalidNotificationIdsPayload", "noValidNotificationIds", "noActiveSubscriptionOptIn", "deliveryAccepted", "noDeliveryAccepted", "testUnavailable", "testSent", "testSentWithCount", "testRejected", "testFailed"] />
        <cfset var requiredNotificationsSocialKeys = ["followStarted", "followRequested"] />
        <cfset var requiredNotificationsSupportKeys = ["newTicketForAdmin"] />
        <cfset var requiredAthleteFeedKeys = ["minutesShort", "hour", "hours", "day", "days", "empty", "onboardingFriendsTitle", "onboardingFriendsText", "onboardingFriendsCta", "onboardingAgendaTitle", "onboardingAgendaText", "onboardingAgendaCta", "onboardingResultsTitle", "onboardingResultsText", "onboardingResultsCta", "filterFollowing", "filterMine", "filterTeam", "agendaLabel", "viewAgenda", "viewEvent", "resultLabel", "otherResults", "eventResults", "videoLabel", "youtubeTitle", "stravaLabel", "viewHistory", "challengeWith", "challengeDescription", "badgeUnlockedLabel", "badgeDescription", "newsExcerpt", "textPostCopy", "linkPostIntro", "linkExcerpt", "photoPostCopy", "avatarAlt", "photoAlt", "linkPreviewAlt", "linkSourceLabel", "friendsAtEvent"] />
        <cfset var requiredAthleteSocialKeys = ["website", "strava", "instagram", "youtube", "tiktok", "whatsapp"] />
        <cfset var requiredAthleteFollowersModalKeys = ["menuAria", "followers", "following", "closeAria", "fetchError", "approve", "requested", "follow", "actionAria", "orderingAria", "suggestedContacts", "suggestionsLoading", "suggestionsEmpty"] />
        <cfset var requiredAthleteSidebarKeys = ["badgesKicker", "badgesTitle", "badgesUnlocked", "badgesDistances", "badgesSpecial", "badgesChallenges", "badgesChallengesEmpty", "performanceKicker", "performanceTitle", "performanceSummary", "performanceCompare", "performanceOverall", "performanceCategory", "performancePace", "performanceFooter", "commonKicker", "commonContactsTitle", "commonContactsSummary", "commonContactsCopy", "commonEventsTitle", "commonEventsSummary", "commonEventsCopy", "subscribeMore", "bestPace", "historyKicker", "historyTitle", "historySummary", "historyByDistance", "historyByDistanceCopy", "historyByDistanceEmpty", "historyByYear", "historyByYearCopy", "historyByYearEmpty", "historyChartTitle"] />
        <cfset var requiredAthleteSettingsKeys = ["pageTitle", "pageDescription", "backToProfile", "saved", "invalidRequest", "securityError", "profileTitle", "integrationsTitle", "linksTitle", "privacyTitle", "navProfile", "navIntegrations", "navLinks", "navPrivacy", "accountRemovalTitle", "profileRunTitle", "profileRunText", "profileRunOpen", "profileRunVerifiedOnly", "profileRunSettingsTitle", "profileRunCoverTitle", "profileRunCoverText", "profileRunCoverCurrentAlt", "profileRunCoverChange", "profileRunCoverUnavailable", "profileRunCoverModalTitle", "profileRunCoverModalText", "profileRunCoverLoading", "profileRunCoverError", "profileRunCoverRetry", "profileRunCoverSelectAria", "profileRunCoverSaveHint", "profileRunCoverCloseAria", "profileRunThemeTitle", "profileRunThemeText", "profileRunThemeDark", "profileRunThemeLight", "profileRunLinkEnable", "profileRunLinkDisable", "profileRunLinkInactive", "profileRunEmailContact", "profileRunEmailContactText", "profileRunWhatsappContact", "profileRunWhatsappContactText", "profileRunWhatsappMissing", "profileRunSave", "profileRunUnavailable", "profileName", "accountId", "googleEmail", "username", "usernameInvalid", "city", "statePlaceholder", "countryPlaceholder", "bio", "saveProfile", "connectedGoogle", "connectedStrava", "connectStrava", "connectFocoRadical", "instagram", "instagramPlaceholder", "youtube", "youtubePlaceholder", "tiktok", "tiktokPlaceholder", "urlPlaceholder", "countryBrazil", "onlineStore", "whatsapp", "whatsappPlaceholder", "saveLinks", "privacyPublicTitle", "privacyPublicText", "privacyFollowersTitle", "privacyFollowersText", "savePrivacy", "removeWarning", "removeAccount"] />
        <cfset var requiredAthleteBadgesModalKeys = ["closeAria", "learnChallenge", "viewStravaProfile", "connectStravaAccount", "visitStrava", "searchCbat", "cbatEliteAlt", "brasilGiganteTitle", "brasilGiganteDescription", "brasilGiganteCta", "goRunnersTitle", "goRunnersDescription", "goRunnersCta", "badges"] />
        <cfset var requiredAthleteLegacyEditModalKeys = ["title", "profileName", "profileNameHelp", "aka", "akaHelp", "coaching", "coachingHelp", "city", "state", "submit"] />
        <cfset var requiredAthleteCouponsKeys = ["promoBanner", "promoBannerCta", "discountSuffix", "terms", "activate", "empty", "newModal", "editModal", "linkModal", "focusModal"] />
        <cfset var requiredAthleteCouponNewModalKeys = ["title", "brand", "description", "conditions", "purchaseLink", "couponCode", "submit"] />
        <cfset var requiredAthleteCouponEditModalKeys = ["title", "submit", "remove"] />
        <cfset var requiredAthleteCouponLinkModalKeys = ["title", "couponLabel", "copy", "copied", "useCoupon", "expired"] />
        <cfset var requiredAthleteCouponFocusModalKeys = ["title", "closeAria", "logoAlt", "discountCopy", "couponLabel", "copy", "copied", "viewPhotos"] />
        <cfset var requiredAthleteProfileMiniKeys = ["profileKicker", "avatarAlt", "resultsLabel", "followersLabel", "followingLabel", "nextEventTitle", "daysUntil", "tomorrow", "today", "viewFullAgenda", "noChallengeYet", "findRace", "lastResultTitle", "daysAgo", "general", "category", "time", "allResults", "noHistoryYet", "findResults", "photos", "createFreeProfile", "createProfileBannerAlt"] />
        <cfset var requiredAthleteStravaTableKeys = ["activity", "dateTime", "distance", "time", "type"] />
        <cfset var agendaKey = "" />
        <cfset var homeKey = "" />
        <cfset var homeMetaKey = "" />
        <cfset var homeFeaturedKey = "" />
        <cfset var homeSpotlightKey = "" />
        <cfset var homeUpcomingKey = "" />
        <cfset var homeRecentResultsKey = "" />
        <cfset var notFoundKey = "" />
        <cfset var notFoundMetaKey = "" />
        <cfset var searchKey = "" />
        <cfset var searchLegacyKey = "" />
        <cfset var challengeKey = "" />
        <cfset var challengeSectionKey = "" />
        <cfset var challengeDetailsKey = "" />
        <cfset var challengeDetailPageKey = "" />
        <cfset var challengeCalendarKey = "" />
        <cfset var resultsKey = "" />
        <cfset var newsKey = "" />
        <cfset var videosKey = "" />
        <cfset var editorialHeroKey = "" />
        <cfset var eventKey = "" />
        <cfset var athleteKey = "" />
        <cfset var athletePhotoKey = "" />
        <cfset var athleteSocialKey = "" />
        <cfset var athleteFeedKey = "" />
        <cfset var athleteFollowersModalKey = "" />
        <cfset var athleteSidebarKey = "" />
        <cfset var athleteSettingsKey = "" />
        <cfset var athleteBadgesModalKey = "" />
        <cfset var athleteLegacyEditModalKey = "" />
        <cfset var athleteCouponsKey = "" />
        <cfset var athleteCouponNewModalKey = "" />
        <cfset var athleteCouponEditModalKey = "" />
        <cfset var athleteCouponLinkModalKey = "" />
        <cfset var athleteProfileMiniKey = "" />
        <cfset var athleteStravaTableKey = "" />
        <cfset var notificationKey = "" />
        <cfset var notificationApiKey = "" />
        <cfset var notificationPushKey = "" />
        <cfset var notificationSocialKey = "" />
        <cfset var notificationSupportKey = "" />
        <cfset var langCode = "" />
        <cfset var sectionKey = "" />
        <cfset var commonSectionKey = "" />
        <cfset var commonRootKey = "" />
        <cfset var commonWeekdayShortKey = "" />
        <cfset var commonHeaderKey = "" />
        <cfset var commonPwaKey = "" />
        <cfset var commonFooterKey = "" />
        <cfset var commonCookieKey = "" />
        <cfset var commonLoginModalKey = "" />
        <cfset var commonStravaConnectModalKey = "" />
        <cfset var commonBetaModalKey = "" />
        <cfset var commonShareModalKey = "" />
        <cfset var commonEventSuggestionModalKey = "" />
        <cfset var commonEventEditModalKey = "" />
        <cfset var commonEventModalFieldKey = "" />
        <cfset var commonPaymentModalKey = "" />
        <cfset var commonPaymentModalFieldKey = "" />
        <cfset var commonCertificatePageKey = "" />
        <cfset var commonHealthCardKey = "" />
        <cfset var commonRetrospectivePageKey = "" />
        <cfset var commonAppsMenuKey = "" />
        <cfset var commonActivitySidebarKey = "" />
        <cfset var commonThemeHeaderKey = "" />
        <cfset var commonPermitKey = "" />
        <cfset var routeKey = "" />

        <cfif NOT structKeyExists(APPLICATION, "i18nCatalog") OR NOT isStruct(APPLICATION.i18nCatalog)>
            <cfreturn false />
        </cfif>

        <cfif len(trim(arguments.expectedSignature)) AND (
            NOT structKeyExists(APPLICATION, "i18nCatalogSignature")
            OR trim(APPLICATION.i18nCatalogSignature & "") NEQ trim(arguments.expectedSignature)
        )>
            <cfreturn false />
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "i18nConfig") OR NOT isStruct(APPLICATION.i18nConfig)>
            <cfreturn false />
        </cfif>

        <cfif NOT structKeyExists(APPLICATION.i18nConfig, "defaultLanguage")>
            <cfreturn false />
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "i18nRoutes") OR NOT isStruct(APPLICATION.i18nRoutes)>
            <cfreturn false />
        </cfif>

        <cfloop array="#requiredLanguages#" index="langCode">
            <cfif NOT structKeyExists(APPLICATION.i18nCatalog, langCode) OR NOT isStruct(APPLICATION.i18nCatalog[langCode])>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredSections#" index="sectionKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode], sectionKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonSections#" index="commonSectionKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common, commonSectionKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonRootKeys#" index="commonRootKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common, commonRootKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.weekdays) OR NOT isStruct(APPLICATION.i18nCatalog[langCode].common.weekdays.short)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredCommonWeekdayShortKeys#" index="commonWeekdayShortKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.weekdays.short, commonWeekdayShortKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonHeaderKeys#" index="commonHeaderKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.header) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.header, commonHeaderKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonPwaKeys#" index="commonPwaKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.pwa) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.pwa, commonPwaKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonSlimHeaderKeys#" index="commonSlimHeaderKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.slimHeader) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.slimHeader, commonSlimHeaderKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonFooterKeys#" index="commonFooterKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.footer) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.footer, commonFooterKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonCookieKeys#" index="commonCookieKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.cookie) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.cookie, commonCookieKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonLoginModalKeys#" index="commonLoginModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.loginModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.loginModal, commonLoginModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonStravaConnectModalKeys#" index="commonStravaConnectModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.stravaConnectModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.stravaConnectModal, commonStravaConnectModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonBetaModalKeys#" index="commonBetaModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.betaModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.betaModal, commonBetaModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonShareModalKeys#" index="commonShareModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.shareModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.shareModal, commonShareModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.eventSuggestionModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredCommonEventSuggestionModalKeys#" index="commonEventSuggestionModalKey">
                <cfif commonEventSuggestionModalKey EQ "fields">
                    <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.eventSuggestionModal.fields)>
                        <cfreturn false />
                    </cfif>
                <cfelseif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.eventSuggestionModal, commonEventSuggestionModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonEventModalFieldKeys#" index="commonEventModalFieldKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.eventSuggestionModal.fields, commonEventModalFieldKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.eventEditModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredCommonEventEditModalKeys#" index="commonEventEditModalKey">
                <cfif commonEventEditModalKey EQ "fields">
                    <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.eventEditModal.fields)>
                        <cfreturn false />
                    </cfif>
                <cfelseif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.eventEditModal, commonEventEditModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonEventModalFieldKeys#" index="commonEventModalFieldKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.eventEditModal.fields, commonEventModalFieldKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.paymentModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredCommonPaymentModalKeys#" index="commonPaymentModalKey">
                <cfif commonPaymentModalKey EQ "fields">
                    <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.paymentModal.fields)>
                        <cfreturn false />
                    </cfif>
                <cfelseif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.paymentModal, commonPaymentModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonPaymentModalFieldKeys#" index="commonPaymentModalFieldKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.paymentModal.fields, commonPaymentModalFieldKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonCompanyRegistrationModalKeys#" index="commonCompanyRegistrationModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.companyRegistrationModal)>
                    <cfreturn false />
                <cfelseif listFindNoCase("fields,categories", commonCompanyRegistrationModalKey)>
                    <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.companyRegistrationModal[commonCompanyRegistrationModalKey])>
                        <cfreturn false />
                    </cfif>
                <cfelseif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.companyRegistrationModal, commonCompanyRegistrationModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonCompanyRegistrationFieldKeys#" index="commonCompanyRegistrationFieldKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.companyRegistrationModal.fields, commonCompanyRegistrationFieldKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonCompanyRegistrationCategoryKeys#" index="commonCompanyRegistrationCategoryKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.companyRegistrationModal.categories, commonCompanyRegistrationCategoryKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonCertificatePageKeys#" index="commonCertificatePageKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.certificatePage) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.certificatePage, commonCertificatePageKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonHealthCardKeys#" index="commonHealthCardKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.healthCard) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.healthCard, commonHealthCardKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonRetrospectivePageKeys#" index="commonRetrospectivePageKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.retrospectivePage) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.retrospectivePage, commonRetrospectivePageKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonAppsMenuKeys#" index="commonAppsMenuKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.appsMenu) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.appsMenu, commonAppsMenuKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonActivitySidebarKeys#" index="commonActivitySidebarKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.activitySidebar) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.activitySidebar, commonActivitySidebarKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonThemeHeaderKeys#" index="commonThemeHeaderKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.themeHeader) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.themeHeader, commonThemeHeaderKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredCommonPermitKeys#" index="commonPermitKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].common.permits) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].common.permits, commonPermitKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredHomeKeys#" index="homeKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home, homeKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredHomeMetaKeys#" index="homeMetaKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home.meta) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home.meta, homeMetaKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredHomeFeaturedKeys#" index="homeFeaturedKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home.featured) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home.featured, homeFeaturedKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredHomeSpotlightKeys#" index="homeSpotlightKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home.spotlight) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home.spotlight, homeSpotlightKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredHomeUpcomingKeys#" index="homeUpcomingKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home.upcoming) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home.upcoming, homeUpcomingKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredHomeRecentResultsKeys#" index="homeRecentResultsKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].home.recentResults) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].home.recentResults, homeRecentResultsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notFound)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotFoundKeys#" index="notFoundKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notFound, notFoundKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredNotFoundMetaKeys#" index="notFoundMetaKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notFound.meta) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notFound.meta, notFoundMetaKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].agenda)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAgendaKeys#" index="agendaKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].agenda, agendaKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].search)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredSearchKeys#" index="searchKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].search, searchKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredSearchLegacyKeys#" index="searchLegacyKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].search.legacy) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].search.legacy, searchLegacyKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredSearchFilterKeys#" index="searchFilterKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].search.filters) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].search.filters, searchFilterKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredSearchEventListKeys#" index="searchEventListKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].search.eventList) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].search.eventList, searchEventListKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].challenges)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredChallengesKeys#" index="challengeKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].challenges, challengeKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredChallengeSectionKeys#" index="challengeSectionKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].challenges.sections) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].challenges.sections, challengeSectionKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredChallengeDetailsKeys#" index="challengeDetailsKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].challenges.details) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].challenges.details, challengeDetailsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredChallengeDetailPageKeys#" index="challengeDetailPageKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].challenges.detailPage) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].challenges.detailPage, challengeDetailPageKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredChallengeCalendarKeys#" index="challengeCalendarKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].challenges.calendar) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].challenges.calendar, challengeCalendarKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].news)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNewsKeys#" index="newsKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].news, newsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredEditorialHeroKeys#" index="editorialHeroKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].news.hero) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].news.hero, editorialHeroKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].videos)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredVideosKeys#" index="videosKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].videos, videosKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
            <cfloop array="#requiredEditorialHeroKeys#" index="editorialHeroKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].videos.hero) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].videos.hero, editorialHeroKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].event)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredEventKeys#" index="eventKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].event, eventKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notifications)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotificationsKeys#" index="notificationKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notifications, notificationKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notifications.api)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotificationsApiKeys#" index="notificationApiKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notifications.api, notificationApiKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notifications.push)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotificationsPushKeys#" index="notificationPushKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notifications.push, notificationPushKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notifications.social)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotificationsSocialKeys#" index="notificationSocialKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notifications.social, notificationSocialKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].notifications.support)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredNotificationsSupportKeys#" index="notificationSupportKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].notifications.support, notificationSupportKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].results)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredResultsKeys#" index="resultsKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].results, resultsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].activities)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredActivitiesKeys#" index="activitiesKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].activities, activitiesKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteKeys#" index="athleteKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete, athleteKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.photo)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthletePhotoKeys#" index="athletePhotoKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.photo, athletePhotoKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.social)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteSocialKeys#" index="athleteSocialKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.social, athleteSocialKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.feed)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteFeedKeys#" index="athleteFeedKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.feed, athleteFeedKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.followersModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteFollowersModalKeys#" index="athleteFollowersModalKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.followersModal, athleteFollowersModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.sidebar)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteSidebarKeys#" index="athleteSidebarKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.sidebar, athleteSidebarKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.settings)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteSettingsKeys#" index="athleteSettingsKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.settings, athleteSettingsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.badgesModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteBadgesModalKeys#" index="athleteBadgesModalKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.badgesModal, athleteBadgesModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.legacyEditModal)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteLegacyEditModalKeys#" index="athleteLegacyEditModalKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.legacyEditModal, athleteLegacyEditModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.coupons)>
                <cfreturn false />
            </cfif>

            <cfloop array="#requiredAthleteCouponsKeys#" index="athleteCouponsKey">
                <cfif NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.coupons, athleteCouponsKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteCouponNewModalKeys#" index="athleteCouponNewModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.coupons.newModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.coupons.newModal, athleteCouponNewModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteCouponEditModalKeys#" index="athleteCouponEditModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.coupons.editModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.coupons.editModal, athleteCouponEditModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteCouponLinkModalKeys#" index="athleteCouponLinkModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.coupons.linkModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.coupons.linkModal, athleteCouponLinkModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteCouponFocusModalKeys#" index="athleteCouponFocusModalKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.coupons.focusModal) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.coupons.focusModal, athleteCouponFocusModalKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteProfileMiniKeys#" index="athleteProfileMiniKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.profileMini) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.profileMini, athleteProfileMiniKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>

            <cfloop array="#requiredAthleteStravaTableKeys#" index="athleteStravaTableKey">
                <cfif NOT isStruct(APPLICATION.i18nCatalog[langCode].athlete.stravaTable) OR NOT structKeyExists(APPLICATION.i18nCatalog[langCode].athlete.stravaTable, athleteStravaTableKey)>
                    <cfreturn false />
                </cfif>
            </cfloop>
        </cfloop>

        <cfloop list="home,notFound,search,news,videos,event,agenda,challenges,results,athlete,profileSettings,profileSettingsIntegrations,profileSettingsLinks,profileSettingsPrivacy,profileSettingsPerfilRun,feed,messages,support,help,about,creator,privacy" index="routeKey">
            <cfif NOT structKeyExists(APPLICATION.i18nRoutes, routeKey)>
                <cfreturn false />
            </cfif>
        </cfloop>

        <cfreturn true />
    </cffunction>

    <cffunction name="getI18nCatalogSignature" access="private" returntype="string" output="false">
        <cfset var languageFiles = ["pt-BR", "en", "es"] />
        <cfset var langCode = "" />
        <cfset var signatureParts = [] />
        <cfset var filePath = "" />
        <cfset var fileInfo = {} />

        <cfloop array="#languageFiles#" index="langCode">
            <cfset filePath = expandPath("/i18n/#langCode#.cfm") />
            <cfif fileExists(filePath)>
                <cfset fileInfo = getFileInfo(filePath) />
                <cfset arrayAppend(signatureParts, "#langCode#:#dateTimeFormat(fileInfo.lastModified, 'yyyymmddHHnnsslll')#:#fileInfo.size#") />
            <cfelse>
                <cfset arrayAppend(signatureParts, "#langCode#:missing") />
            </cfif>
        </cfloop>

        <cfreturn arrayToList(signatureParts, "|") />
    </cffunction>

    <cffunction name="getI18nRouteDefinitions" access="private" returntype="struct" output="false">
        <cfreturn {
            "home" = {
                "pt-BR" = "/",
                "en" = "/en/",
                "es" = "/es/"
            },
            "notFound" = {
                "pt-BR" = "/404/",
                "en" = "/en/404/",
                "es" = "/es/404/"
            },
            "search" = {
                "pt-BR" = "/busca/",
                "en" = "/en/search/",
                "es" = "/es/busqueda/"
            },
            "news" = {
                "pt-BR" = "/noticias/",
                "en" = "/en/news/",
                "es" = "/es/noticias/"
            },
            "newsDetail" = {
                "pt-BR" = "/noticias/{tag}/",
                "en" = "/en/news/{tag}/",
                "es" = "/es/noticias/{tag}/"
            },
            "newsChannel" = {
                "pt-BR" = "/noticias/canal/{canal}/",
                "en" = "/en/news/channel/{canal}/",
                "es" = "/es/noticias/canal/{canal}/"
            },
            "videos" = {
                "pt-BR" = "/videos/",
                "en" = "/en/videos/",
                "es" = "/es/videos/"
            },
            "videosChannel" = {
                "pt-BR" = "/videos/canal/{canal}/",
                "en" = "/en/videos/channel/{canal}/",
                "es" = "/es/videos/canal/{canal}/"
            },
            "event" = {
                "pt-BR" = "/evento/{tag}/",
                "en" = "/en/event/{tag}/",
                "es" = "/es/evento/{tag}/"
            },
            "agenda" = {
                "pt-BR" = "/agenda/",
                "en" = "/en/calendar/",
                "es" = "/es/agenda/"
            },
            "challenges" = {
                "pt-BR" = "/desafios/",
                "en" = "/en/challenges/",
                "es" = "/es/desafios/"
            },
            "results" = {
                "pt-BR" = "/resultados/",
                "en" = "/en/results/",
                "es" = "/es/resultados/"
            },
            "feed" = {
                "pt-BR" = "/atividades/",
                "en" = "/en/activities/",
                "es" = "/es/actividades/"
            },
            "messages" = {
                "pt-BR" = "/mensagens/",
                "en" = "/en/messages/",
                "es" = "/es/mensajes/"
            },
            "athlete" = {
                "pt-BR" = "/atleta/{tag}/",
                "en" = "/en/athlete/{tag}/",
                "es" = "/es/atleta/{tag}/"
            },
            "profileSettings" = {
                "pt-BR" = "/configuracoes/perfil/",
                "en" = "/en/settings/profile/",
                "es" = "/es/configuracion/perfil/"
            },
            "profileSettingsIntegrations" = {
                "pt-BR" = "/configuracoes/integracoes/",
                "en" = "/en/settings/integrations/",
                "es" = "/es/configuracion/integraciones/"
            },
            "profileSettingsLinks" = {
                "pt-BR" = "/configuracoes/links/",
                "en" = "/en/settings/links/",
                "es" = "/es/configuracion/enlaces/"
            },
            "profileSettingsPrivacy" = {
                "pt-BR" = "/configuracoes/privacidade/",
                "en" = "/en/settings/privacy/",
                "es" = "/es/configuracion/privacidad/"
            },
            "profileSettingsPerfilRun" = {
                "pt-BR" = "/configuracoes/perfilrun/",
                "en" = "/en/settings/perfilrun/",
                "es" = "/es/configuracion/perfilrun/"
            },
            "athleteHealth" = {
                "pt-BR" = "/atleta/{tag}/saude/",
                "en" = "/en/athlete/{tag}/health/",
                "es" = "/es/atleta/{tag}/salud/"
            },
            "athleteRetrospective" = {
                "pt-BR" = "/atleta/{tag}/retrospectiva/",
                "en" = "/en/athlete/{tag}/retrospective/",
                "es" = "/es/atleta/{tag}/retrospectiva/"
            },
            "support" = {
                "pt-BR" = "/atendimento/",
                "en" = "/en/support/",
                "es" = "/es/soporte/"
            },
            "about" = {
                "pt-BR" = "/sobre/",
                "en" = "/en/about/",
                "es" = "/es/sobre/"
            },
            "creator" = {
                "pt-BR" = "/creator/",
                "en" = "/en/creator/",
                "es" = "/es/creador/"
            },
            "help" = {
                "pt-BR" = "/ajuda/",
                "en" = "/en/help/",
                "es" = "/es/ayuda/"
            },
            "privacy" = {
                "pt-BR" = "/privacidade/",
                "en" = "/en/privacy/",
                "es" = "/es/privacidad/"
            },
            "betaLanding" = {
                "pt-BR" = "/beta/",
                "en" = "/en/beta/",
                "es" = "/es/beta/"
            }
        } />
    </cffunction>

    <cffunction name="hydrateRequestI18n" access="private" returntype="void" output="false">
        <cfset var resolvedLanguage = resolveRequestLanguage() />
        <cfset var explicitLanguage = getExplicitLanguageFromPath(getRequestUriPath()) />
        <cfset var availableLanguages = duplicate(APPLICATION.i18nConfig.availableLanguages) />
        <cfset var currentRouteKey = structKeyExists(URL, "i18n_route") ? trim(URL.i18n_route) : detectCurrentI18nRouteKey(getRequestUriPath()) />

        <cfset REQUEST.availableLanguages = availableLanguages />
        <cfset REQUEST.lang = resolvedLanguage />
        <cfset REQUEST.langPrefix = getI18nLanguagePrefix(resolvedLanguage) />
        <cfset REQUEST.langPathKey = getI18nLanguagePathKey(resolvedLanguage) />
        <cfset REQUEST.htmlLang = getI18nHtmlLang(resolvedLanguage) />
        <cfset REQUEST.i18n = getI18nCatalogForLanguage(resolvedLanguage) />
        <cfset REQUEST.currentRouteKey = currentRouteKey />
        <cfset REQUEST.currentRouteParams = {} />
        <cfif structKeyExists(URL, "tag") AND len(trim(URL.tag))>
            <cfset REQUEST.currentRouteParams["tag"] = trim(URL.tag) />
        </cfif>
        <cfif structKeyExists(URL, "canal") AND len(trim(URL.canal))>
            <cfset REQUEST.currentRouteParams["canal"] = trim(URL.canal) />
        </cfif>
        <cfset REQUEST.hasExplicitLanguagePrefix = len(explicitLanguage) GT 0 />
        <cfset REQUEST.t = function(required string key, struct replacements = {}) {
            return translateI18nValue(arguments.key, REQUEST.lang, arguments.replacements);
        } />
        <cfset REQUEST.i18nBuildPath = function(required string routeKey, string languageCode = "") {
            var targetLanguageCode = len(trim(arguments.languageCode)) ? trim(arguments.languageCode) : REQUEST.lang;
            return buildLocalizedRoutePath(arguments.routeKey, targetLanguageCode);
        } />
        <cfset REQUEST.i18nBuildAbsoluteUrl = function(required string routeKey, string languageCode = "") {
            var targetLanguageCode = len(trim(arguments.languageCode)) ? trim(arguments.languageCode) : REQUEST.lang;
            return REQUEST.currentBaseUrl & buildLocalizedRoutePath(arguments.routeKey, targetLanguageCode);
        } />
        <cfset REQUEST.formatDisplayTitle = function(required string value) {
            return formatDisplayTitle(arguments.value);
        } />
        <cfset REQUEST.formatDisplayPersonName = function(required string fullName) {
            return formatDisplayTitle(arguments.fullName);
        } />
        <cfset REQUEST.formatDisplayCity = function(required string cityName) {
            return formatDisplayTitle(arguments.cityName);
        } />
        <cfset REQUEST.normalizeDisplayQuery = function(required any sourceQuery, string personColumns = "", string cityColumns = "") {
            var rowIndex = 0;
            var columnName = "";
            var availableColumns = "";

            if (!isQuery(arguments.sourceQuery)) {
                return arguments.sourceQuery;
            }

            availableColumns = arguments.sourceQuery.columnList;

            for (columnName in listToArray(arguments.personColumns)) {
                columnName = trim(columnName);
                if (!len(columnName) || !listFindNoCase(availableColumns, columnName)) {
                    continue;
                }
                for (rowIndex = 1; rowIndex <= arguments.sourceQuery.recordCount; rowIndex += 1) {
                    querySetCell(arguments.sourceQuery, columnName, formatDisplayTitle(arguments.sourceQuery[columnName][rowIndex] & ""), rowIndex);
                }
            }

            for (columnName in listToArray(arguments.cityColumns)) {
                columnName = trim(columnName);
                if (!len(columnName) || !listFindNoCase(availableColumns, columnName)) {
                    continue;
                }
                for (rowIndex = 1; rowIndex <= arguments.sourceQuery.recordCount; rowIndex += 1) {
                    querySetCell(arguments.sourceQuery, columnName, formatDisplayTitle(arguments.sourceQuery[columnName][rowIndex] & ""), rowIndex);
                }
            }

            return arguments.sourceQuery;
        } />

        <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario)>
            <cfif structKeyExists(REQUEST.Usuario, "name")>
                <cfset REQUEST.Usuario.name = formatDisplayTitle(REQUEST.Usuario.name & "") />
            </cfif>
            <cfif structKeyExists(REQUEST.Usuario, "nome")>
                <cfset REQUEST.Usuario.nome = formatDisplayTitle(REQUEST.Usuario.nome & "") />
            </cfif>
            <cfif structKeyExists(REQUEST.Usuario, "aka")>
                <cfset REQUEST.Usuario.aka = formatDisplayTitle(REQUEST.Usuario.aka & "") />
            </cfif>
            <cfif structKeyExists(REQUEST.Usuario, "cidade")>
                <cfset REQUEST.Usuario.cidade = formatDisplayTitle(REQUEST.Usuario.cidade & "") />
            </cfif>
        </cfif>

        <cfcookie
            name="rr_lang"
            secure="yes"
            encodevalue="yes"
            value="#REQUEST.lang#"
            expires="#createTimeSpan(30, 0, 0, 0)#" />

        <cfreturn />
    </cffunction>

    <cffunction name="formatDisplayTitle" access="private" returntype="string" output="false">
        <cfargument name="value" type="string" required="true" />
        <cfset var loweredWords = "a,à,ao,aos,as,às,o,os,da,das,de,do,dos,e,em,na,nas,no,nos,ou,por,del,el,la,las,los,y,and,of,the" />
        <cfset var normalizedValue = trim(reReplace(arguments.value, "\s+", " ", "all")) />
        <cfset var formattedWords = [] />
        <cfset var word = "" />
        <cfset var loweredWord = "" />

        <cfif NOT len(normalizedValue)>
            <cfreturn "" />
        </cfif>

        <cfloop array="#listToArray(normalizedValue, ' ')#" index="word">
            <cfset loweredWord = lCase(trim(word)) />
            <cfif NOT len(loweredWord)>
                <cfcontinue />
            </cfif>

            <cfif listFindNoCase(loweredWords, loweredWord)>
                <cfset arrayAppend(formattedWords, loweredWord) />
            <cfelseif reFindNoCase("^d['’].+", loweredWord)>
                <cfset arrayAppend(formattedWords, left(loweredWord, 2) & uCase(mid(loweredWord, 3, 1)) & mid(loweredWord, 4, len(loweredWord))) />
            <cfelse>
                <cfset arrayAppend(formattedWords, uCase(left(loweredWord, 1)) & mid(loweredWord, 2, len(loweredWord))) />
            </cfif>
        </cfloop>

        <cfreturn arrayToList(formattedWords, " ") />
    </cffunction>

    <cffunction name="getRequestUriPath" access="private" returntype="string" output="false">
        <cfset var requestUri = structKeyExists(CGI, "REQUEST_URI") ? CGI.REQUEST_URI : "/" />
        <cfset var normalizedPath = listFirst(trim(requestUri), "?") />
        <cfset var redirectedPath = structKeyExists(CGI, "REDIRECT_URL") ? trim(CGI.REDIRECT_URL) : "" />

        <cfif (normalizedPath EQ "/404" OR normalizedPath EQ "/404/") AND len(redirectedPath)>
            <cfset normalizedPath = listFirst(redirectedPath, "?") />
        </cfif>

        <cfif NOT len(normalizedPath)>
            <cfreturn "/" />
        </cfif>

        <cfif left(normalizedPath, 1) NEQ "/">
            <cfset normalizedPath = "/" & normalizedPath />
        </cfif>

        <cfreturn normalizedPath />
    </cffunction>

    <cffunction name="getExplicitLanguageFromPath" access="private" returntype="string" output="false">
        <cfargument name="requestPath" type="string" required="true" />
        <cfset var normalizedPath = lCase(trim(arguments.requestPath)) />

        <cfif normalizedPath EQ "/en" OR left(normalizedPath, 4) EQ "/en/">
            <cfreturn "en" />
        </cfif>

        <cfif normalizedPath EQ "/es" OR left(normalizedPath, 4) EQ "/es/">
            <cfreturn "es" />
        </cfif>

        <cfreturn "" />
    </cffunction>

    <cffunction name="resolveRequestLanguage" access="private" returntype="string" output="false">
        <cfset var requestPath = getRequestUriPath() />
        <cfset var rewrittenLanguage = structKeyExists(URL, "i18n_lang") ? trim(URL.i18n_lang) : "" />
        <cfset var routeLanguage = detectLanguageByLocalizedRoutePath(requestPath) />
        <cfset var explicitLanguage = getExplicitLanguageFromPath(requestPath) />
        <cfset var cookieLanguage = structKeyExists(COOKIE, "rr_lang") ? trim(COOKIE.rr_lang) : "" />
        <cfset var acceptLanguage = structKeyExists(CGI, "HTTP_ACCEPT_LANGUAGE") ? lCase(CGI.HTTP_ACCEPT_LANGUAGE) : "" />

        <cfif isSupportedLanguage(rewrittenLanguage)>
            <cfreturn rewrittenLanguage />
        </cfif>

        <cfif isSupportedLanguage(routeLanguage)>
            <cfreturn routeLanguage />
        </cfif>

        <cfif isSupportedLanguage(explicitLanguage)>
            <cfreturn explicitLanguage />
        </cfif>

        <cfif left(requestPath, 4) NEQ "/en/" AND requestPath NEQ "/en" AND left(requestPath, 4) NEQ "/es/" AND requestPath NEQ "/es">
            <cfreturn APPLICATION.i18nConfig.defaultLanguage />
        </cfif>

        <cfif isSupportedLanguage(cookieLanguage)>
            <cfreturn cookieLanguage />
        </cfif>

        <cfif acceptLanguage CONTAINS "es">
            <cfreturn "es" />
        </cfif>

        <cfif acceptLanguage CONTAINS "en">
            <cfreturn "en" />
        </cfif>

        <cfreturn APPLICATION.i18nConfig.defaultLanguage />
    </cffunction>

    <cffunction name="isSupportedLanguage" access="private" returntype="boolean" output="false">
        <cfargument name="languageCode" type="string" required="true" />
        <cfset var normalizedCode = trim(arguments.languageCode) />

        <cfreturn listFindNoCase("pt-BR,en,es", normalizedCode) GT 0 />
    </cffunction>

    <cffunction name="getI18nLanguagePrefix" access="private" returntype="string" output="false">
        <cfargument name="languageCode" type="string" required="true" />

        <cfswitch expression="#trim(arguments.languageCode)#">
            <cfcase value="en">
                <cfreturn "/en" />
            </cfcase>
            <cfcase value="es">
                <cfreturn "/es" />
            </cfcase>
            <cfdefaultcase>
                <cfreturn "" />
            </cfdefaultcase>
        </cfswitch>
    </cffunction>

    <cffunction name="getI18nLanguagePathKey" access="private" returntype="string" output="false">
        <cfargument name="languageCode" type="string" required="true" />

        <cfswitch expression="#trim(arguments.languageCode)#">
            <cfcase value="en">
                <cfreturn "en" />
            </cfcase>
            <cfcase value="es">
                <cfreturn "es" />
            </cfcase>
            <cfdefaultcase>
                <cfreturn "" />
            </cfdefaultcase>
        </cfswitch>
    </cffunction>

    <cffunction name="getI18nHtmlLang" access="private" returntype="string" output="false">
        <cfargument name="languageCode" type="string" required="true" />

        <cfif trim(arguments.languageCode) EQ "pt-BR">
            <cfreturn "pt-BR" />
        </cfif>

        <cfreturn trim(arguments.languageCode) />
    </cffunction>

    <cffunction name="applyRequestLocale" access="private" returntype="void" output="false">
        <cfset var targetLanguage = structKeyExists(REQUEST, "lang") ? trim(REQUEST.lang) : APPLICATION.i18nConfig.defaultLanguage />

        <cfswitch expression="#targetLanguage#">
            <cfcase value="en">
                <cfset applySupportedLocale([
                    "English (US)",
                    "English (United States)",
                    "English"
                ], "Portuguese (Brazilian)") />
            </cfcase>
            <cfcase value="es">
                <cfset applySupportedLocale([
                    "Spanish (Modern Sort)",
                    "Spanish (Standard)",
                    "Spanish",
                    "es_ES"
                ], "Portuguese (Brazilian)") />
            </cfcase>
            <cfdefaultcase>
                <cfset applySupportedLocale([
                    "Portuguese (Brazilian)",
                    "Portuguese (Brazil)",
                    "Portuguese",
                    "pt_BR"
                ], "") />
            </cfdefaultcase>
        </cfswitch>

        <cfreturn />
    </cffunction>

    <cffunction name="applySupportedLocale" access="private" returntype="void" output="false">
        <cfargument name="candidateLocales" type="array" required="true" />
        <cfargument name="fallbackLocale" type="string" required="false" default="" />
        <cfset var localeCandidate = "" />

        <cfloop array="#arguments.candidateLocales#" index="localeCandidate">
            <cftry>
                <cfset setLocale(localeCandidate) />
                <cfreturn />
            <cfcatch></cfcatch>
            </cftry>
        </cfloop>

        <cfif len(trim(arguments.fallbackLocale))>
            <cftry>
                <cfset setLocale(arguments.fallbackLocale) />
            <cfcatch></cfcatch>
            </cftry>
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="getI18nCatalogForLanguage" access="private" returntype="struct" output="false">
        <cfargument name="languageCode" type="string" required="true" />
        <cfset var targetLanguageCode = isSupportedLanguage(arguments.languageCode) ? trim(arguments.languageCode) : APPLICATION.i18nConfig.defaultLanguage />

        <cfif structKeyExists(APPLICATION.i18nCatalog, targetLanguageCode)>
            <cfreturn duplicate(APPLICATION.i18nCatalog[targetLanguageCode]) />
        </cfif>

        <cfreturn duplicate(APPLICATION.i18nCatalog[APPLICATION.i18nConfig.defaultLanguage]) />
    </cffunction>

    <cffunction name="detectLanguageByLocalizedRoutePath" access="private" returntype="string" output="false">
        <cfargument name="requestPath" type="string" required="true" />
        <cfset var routeKey = "" />
        <cfset var routeDefinition = {} />
        <cfset var langCode = "" />

        <cfloop collection="#APPLICATION.i18nRoutes#" item="routeKey">
            <cfset routeDefinition = APPLICATION.i18nRoutes[routeKey] />

            <cfloop collection="#routeDefinition#" item="langCode">
                <cfif normalizeI18nPath(arguments.requestPath) EQ normalizeI18nPath(routeDefinition[langCode])>
                    <cfreturn langCode />
                </cfif>
            </cfloop>
        </cfloop>

        <cfreturn "" />
    </cffunction>

    <cffunction name="detectCurrentI18nRouteKey" access="private" returntype="string" output="false">
        <cfargument name="requestPath" type="string" required="true" />
        <cfset var routeKey = "" />
        <cfset var routeDefinition = {} />
        <cfset var langCode = "" />

        <cfloop collection="#APPLICATION.i18nRoutes#" item="routeKey">
            <cfset routeDefinition = APPLICATION.i18nRoutes[routeKey] />

            <cfloop collection="#routeDefinition#" item="langCode">
                <cfif normalizeI18nPath(arguments.requestPath) EQ normalizeI18nPath(routeDefinition[langCode])>
                    <cfreturn routeKey />
                </cfif>
            </cfloop>
        </cfloop>

        <cfreturn "" />
    </cffunction>

    <cffunction name="normalizeI18nPath" access="private" returntype="string" output="false">
        <cfargument name="pathValue" type="string" required="true" />
        <cfset var normalizedPath = trim(arguments.pathValue) />

        <cfif NOT len(normalizedPath)>
            <cfreturn "/" />
        </cfif>

        <cfif left(normalizedPath, 1) NEQ "/">
            <cfset normalizedPath = "/" & normalizedPath />
        </cfif>

        <cfif len(normalizedPath) GT 1 AND right(normalizedPath, 1) EQ "/">
            <cfset normalizedPath = left(normalizedPath, len(normalizedPath) - 1) />
        </cfif>

        <cfreturn lCase(normalizedPath) />
    </cffunction>

    <cffunction name="buildLocalizedRoutePath" access="private" returntype="string" output="false">
        <cfargument name="routeKey" type="string" required="true" />
        <cfargument name="languageCode" type="string" required="true" />
        <cfset var resolvedPath = "" />
        <cfset var routeParamKey = "" />

        <cfif NOT structKeyExists(APPLICATION.i18nRoutes, arguments.routeKey)>
            <cfreturn "/" />
        </cfif>

        <cfif structKeyExists(APPLICATION.i18nRoutes[arguments.routeKey], arguments.languageCode)>
            <cfset resolvedPath = APPLICATION.i18nRoutes[arguments.routeKey][arguments.languageCode] />
        <cfelse>
            <cfset resolvedPath = APPLICATION.i18nRoutes[arguments.routeKey][APPLICATION.i18nConfig.defaultLanguage] />
        </cfif>

        <cfif structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams)>
            <cfloop collection="#REQUEST.currentRouteParams#" item="routeParamKey">
                <cfset resolvedPath = replaceNoCase(resolvedPath, "{" & routeParamKey & "}", lCase(trim(REQUEST.currentRouteParams[routeParamKey])), "all") />
            </cfloop>
        </cfif>

        <cfreturn resolvedPath />
    </cffunction>

    <cffunction name="translateI18nValue" access="private" returntype="string" output="false">
        <cfargument name="key" type="string" required="true" />
        <cfargument name="languageCode" type="string" required="true" />
        <cfargument name="replacements" type="struct" required="false" default="#structNew()#" />
        <cfset var resolvedValue = getI18nValueByKey(arguments.languageCode, arguments.key) />
        <cfset var replacementKey = "" />

        <cfif NOT len(resolvedValue)>
            <cfset resolvedValue = getI18nValueByKey(APPLICATION.i18nConfig.defaultLanguage, arguments.key) />
        </cfif>

        <cfif NOT len(resolvedValue)>
            <cfreturn arguments.key />
        </cfif>

        <cfloop collection="#arguments.replacements#" item="replacementKey">
            <cfset resolvedValue = replace(resolvedValue, "{" & replacementKey & "}", arguments.replacements[replacementKey], "all") />
        </cfloop>

        <cfreturn resolvedValue />
    </cffunction>

    <cffunction name="getI18nValueByKey" access="private" returntype="string" output="false">
        <cfargument name="languageCode" type="string" required="true" />
        <cfargument name="key" type="string" required="true" />
        <cfset var keyParts = listToArray(arguments.key, ".") />
        <cfset var currentNode = structKeyExists(APPLICATION.i18nCatalog, arguments.languageCode) ? APPLICATION.i18nCatalog[arguments.languageCode] : {} />
        <cfset var keyPart = "" />

        <cfloop array="#keyParts#" index="keyPart">
            <cfif isStruct(currentNode) AND structKeyExists(currentNode, keyPart)>
                <cfset currentNode = currentNode[keyPart] />
            <cfelse>
                <cfreturn "" />
            </cfif>
        </cfloop>

        <cfif isSimpleValue(currentNode)>
            <cfreturn currentNode />
        </cfif>

        <cfreturn "" />
    </cffunction>

    <cffunction name="initSessionUsuarioCache" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(SESSION, "UsuarioCache") OR NOT isStruct(SESSION.UsuarioCache)>
            <cfset SESSION.UsuarioCache = structNew() />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="buildEmptyUsuario" access="private" returntype="any" output="false">
        <cfset var usuario = createObject("component", "includes.models.Usuario") />

        <cfreturn usuario />
    </cffunction>

    <cffunction name="getCurrentEnvironment" access="private" returntype="string" output="false">
        <cfset var host = lCase(trim(CGI.HTTP_HOST)) />

        <cfif host CONTAINS "dev.">
            <cfreturn "dev" />
        </cfif>

        <cfif host CONTAINS "beta.">
            <cfreturn "beta" />
        </cfif>

        <cfreturn "prod" />
    </cffunction>

    <cffunction name="getEnvironmentBaseUrl" access="private" returntype="string" output="false">
        <cfargument name="environment" type="string" required="true" />

        <cfswitch expression="#lCase(trim(arguments.environment))#">
            <cfcase value="dev">
                <cfreturn "https://dev.#APPLICATION.dominio#" />
            </cfcase>
            <cfcase value="beta">
                <cfreturn "https://beta.#APPLICATION.dominio#" />
            </cfcase>
            <cfdefaultcase>
                <cfreturn APPLICATION.baseCanonica />
            </cfdefaultcase>
        </cfswitch>
    </cffunction>

    <cffunction name="buildEmptyApiIntegration" access="private" returntype="struct" output="false">
        <cfreturn {
            "authenticated" = false,
            "clientId" = "",
            "source" = "",
            "userId" = 0,
            "scopes" = [],
            "tokenHash" = ""
        } />
    </cffunction>

    <cffunction name="buildRequestApiIntegration" access="private" returntype="struct" output="false">
        <cfset var apiIntegration = buildEmptyApiIntegration() />
        <cfset var authorizationHeader = getAuthorizationHeaderValue() />
        <cfset var bearerToken = "" />
        <cfset var bearerTokenHash = "" />
        <cfset var tokenConfig = {} />
        <cfset var configuredTokens = [] />

        <cfif left(lCase(authorizationHeader), 7) NEQ "bearer ">
            <cfreturn apiIntegration />
        </cfif>

        <cfset bearerToken = trim(mid(authorizationHeader, 8, len(authorizationHeader))) />

        <cfif NOT len(bearerToken)>
            <cfreturn apiIntegration />
        </cfif>

        <cfset bearerTokenHash = lCase(hash(bearerToken, "SHA-256")) />

        <cfif structKeyExists(APPLICATION, "apiIntegrations")
            AND isStruct(APPLICATION.apiIntegrations)
            AND structKeyExists(APPLICATION.apiIntegrations, "tokens")
            AND isArray(APPLICATION.apiIntegrations.tokens)>
            <cfset configuredTokens = APPLICATION.apiIntegrations.tokens />

            <cfloop array="#configuredTokens#" index="tokenConfig">
                <cfif isStruct(tokenConfig)
                    AND structKeyExists(tokenConfig, "tokenHash")
                    AND lCase(trim(tokenConfig.tokenHash & "")) EQ bearerTokenHash>
                    <cfset apiIntegration.authenticated = true />
                    <cfset apiIntegration.clientId = structKeyExists(tokenConfig, "clientId") ? trim(tokenConfig.clientId & "") : "integration" />
                    <cfset apiIntegration.source = "config" />
                    <cfset apiIntegration.scopes = structKeyExists(tokenConfig, "scopes") AND isArray(tokenConfig.scopes) ? duplicate(tokenConfig.scopes) : [] />
                    <cfset apiIntegration.tokenHash = bearerTokenHash />
                    <cfreturn apiIntegration />
                </cfif>
            </cfloop>
        </cfif>

        <cfset apiIntegration = buildUserApiIntegration(bearerTokenHash) />

        <cfif NOT apiIntegration.authenticated>
            <cfset apiIntegration = buildMobileApiIntegration(bearerTokenHash) />
        </cfif>

        <cfreturn apiIntegration />
    </cffunction>

    <cffunction name="buildMobileApiIntegration" access="private" returntype="struct" output="false">
        <cfargument name="tokenHash" type="string" required="true" />
        <cfset var apiIntegration = buildEmptyApiIntegration() />
        <cfset var tokenRecord = {} />
        <cfset var repository = "" />
        <cfset var remoteAddress = structKeyExists(CGI, "REMOTE_ADDR") ? trim(CGI.REMOTE_ADDR & "") : "" />
        <cfset var userAgent = structKeyExists(CGI, "HTTP_USER_AGENT") ? trim(CGI.HTTP_USER_AGENT & "") : "" />

        <cftry>
            <cfset repository = createObject("component", "repositories.MobileAuthRepository").init("runnerhub") />
            <cfset tokenRecord = repository.findActiveAccessToken(arguments.tokenHash) />
            <cfif tokenRecord.found>
                <cfset apiIntegration.authenticated = true />
                <cfset apiIntegration.clientId = tokenRecord.clientId />
                <cfset apiIntegration.source = "mobile" />
                <cfset apiIntegration.userId = tokenRecord.userId />
                <cfset apiIntegration.scopes = tokenRecord.scopes />
                <cfset apiIntegration.tokenHash = arguments.tokenHash />
                <cfset apiIntegration.mobileSessionId = tokenRecord.sessionId />
                <cfset apiIntegration.oauthScope = tokenRecord.oauthScope />
                <cfset repository.markAccessTokenUsed(tokenRecord.id, remoteAddress, userAgent) />
            </cfif>
            <cfcatch type="any"><cfreturn buildEmptyApiIntegration() /></cfcatch>
        </cftry>

        <cfreturn apiIntegration />
    </cffunction>

    <cffunction name="buildUserApiIntegration" access="private" returntype="struct" output="false">
        <cfargument name="tokenHash" type="string" required="true" />
        <cfset var apiIntegration = buildEmptyApiIntegration() />
        <cfset var tokenRecord = {} />
        <cfset var repository = "" />
        <cfset var remoteAddress = structKeyExists(CGI, "REMOTE_ADDR") ? trim(CGI.REMOTE_ADDR & "") : "" />
        <cfset var userAgent = structKeyExists(CGI, "HTTP_USER_AGENT") ? trim(CGI.HTTP_USER_AGENT & "") : "" />

        <cfif NOT len(trim(arguments.tokenHash))>
            <cfreturn apiIntegration />
        </cfif>

        <cftry>
            <cfset repository = createObject("component", "repositories.ApiTokenRepository").init("runnerhub") />
            <cfset tokenRecord = repository.findActiveByTokenHash(arguments.tokenHash) />

            <cfif isStruct(tokenRecord)
                AND structKeyExists(tokenRecord, "found")
                AND tokenRecord.found>
                <cfset apiIntegration.authenticated = true />
                <cfset apiIntegration.clientId = tokenRecord.clientId />
                <cfset apiIntegration.source = "user" />
                <cfset apiIntegration.userId = tokenRecord.userId />
                <cfset apiIntegration.scopes = tokenRecord.scopes />
                <cfset apiIntegration.tokenHash = arguments.tokenHash />
                <cfset repository.markUsed(tokenRecord.id, remoteAddress, userAgent) />
            </cfif>

            <cfcatch type="any">
                <cfreturn buildEmptyApiIntegration() />
            </cfcatch>
        </cftry>

        <cfreturn apiIntegration />
    </cffunction>

    <cffunction name="hydrateRequestUsuarioFromApiIntegration" access="private" returntype="void" output="false">
        <cfset var qUsuarioCore = "" />
        <cfset var requiredScope = getAuthenticatedJsonApiRequiredScope() />

        <cfif NOT len(requiredScope)>
            <cfreturn />
        </cfif>

        <cfif NOT structKeyExists(REQUEST, "apiIntegration")
            OR NOT isStruct(REQUEST.apiIntegration)
            OR NOT structKeyExists(REQUEST.apiIntegration, "source")
            OR NOT listFindNoCase("user,mobile", REQUEST.apiIntegration.source)
            OR NOT apiIntegrationHasScope(REQUEST.apiIntegration, requiredScope)
            OR NOT structKeyExists(REQUEST.apiIntegration, "userId")
            OR val(REQUEST.apiIntegration.userId) LTE 0>
            <cfreturn />
        </cfif>

        <cfif structKeyExists(REQUEST, "Usuario")
            AND isObject(REQUEST.Usuario)
            AND structKeyExists(REQUEST.Usuario, "logado")
            AND REQUEST.Usuario.logado>
            <cfreturn />
        </cfif>

        <cftry>
            <cfset qUsuarioCore = getUsuarioCoreById(val(REQUEST.apiIntegration.userId)) />

            <cfif qUsuarioCore.recordcount>
                <cfset REQUEST.Usuario = createObject("component", "includes.models.Usuario").init(QueryGetRow(qUsuarioCore, 1)) />
                <cfset REQUEST.Usuario.logado = true />
            </cfif>

            <cfcatch type="any">
                <cfreturn />
            </cfcatch>
        </cftry>

        <cfreturn />
    </cffunction>

    <cffunction name="getAuthorizationHeaderValue" access="private" returntype="string" output="false">
        <cfset var requestData = {} />
        <cfset var headerName = "" />

        <cfif structKeyExists(CGI, "HTTP_AUTHORIZATION") AND len(trim(CGI.HTTP_AUTHORIZATION))>
            <cfreturn trim(CGI.HTTP_AUTHORIZATION) />
        </cfif>

        <cfif structKeyExists(CGI, "REDIRECT_HTTP_AUTHORIZATION") AND len(trim(CGI.REDIRECT_HTTP_AUTHORIZATION))>
            <cfreturn trim(CGI.REDIRECT_HTTP_AUTHORIZATION) />
        </cfif>

        <cftry>
            <cfset requestData = getHttpRequestData() />
            <cfcatch type="any">
                <cfset requestData = {} />
            </cfcatch>
        </cftry>

        <cfif isStruct(requestData) AND structKeyExists(requestData, "headers") AND isStruct(requestData.headers)>
            <cfloop collection="#requestData.headers#" item="headerName">
                <cfif lCase(trim(headerName)) EQ "authorization">
                    <cfreturn trim(requestData.headers[headerName] & "") />
                </cfif>
            </cfloop>
        </cfif>

        <cfreturn "" />
    </cffunction>

    <cffunction name="apiIntegrationHasScope" access="private" returntype="boolean" output="false">
        <cfargument name="apiIntegration" type="struct" required="true" />
        <cfargument name="scope" type="string" required="true" />
        <cfset var scopeValue = "" />

        <cfif NOT structKeyExists(arguments.apiIntegration, "authenticated") OR NOT arguments.apiIntegration.authenticated>
            <cfreturn false />
        </cfif>

        <cfif NOT structKeyExists(arguments.apiIntegration, "scopes") OR NOT isArray(arguments.apiIntegration.scopes)>
            <cfreturn false />
        </cfif>

        <cfloop array="#arguments.apiIntegration.scopes#" index="scopeValue">
            <cfif trim(scopeValue & "") EQ "*" OR lCase(trim(scopeValue & "")) EQ lCase(trim(arguments.scope))>
                <cfreturn true />
            </cfif>
        </cfloop>

        <cfreturn false />
    </cffunction>

    <cffunction name="isApiSubdomainRequest" access="private" returntype="boolean" output="false">
        <cfset var hostName = structKeyExists(CGI, "HTTP_HOST") ? lCase(trim(listFirst(CGI.HTTP_HOST, ":"))) : "" />

        <cfreturn hostName EQ "api.roadrunners.run" />
    </cffunction>

    <cffunction name="isApiRouteRequest" access="private" returntype="boolean" output="false">
        <cfargument name="directory" type="string" required="true" />
        <cfset var scriptName = lCase(trim(CGI.SCRIPT_NAME)) />
        <cfset var directoryPath = "/" & lCase(trim(arguments.directory)) & "/" />
        <cfset var apiDirectoryPath = "/api" & directoryPath />

        <cfreturn scriptName CONTAINS apiDirectoryPath
            OR (isApiSubdomainRequest() AND scriptName CONTAINS directoryPath) />
    </cffunction>

    <cffunction name="isApiRouteFileRequest" access="private" returntype="boolean" output="false">
        <cfargument name="directory" type="string" required="true" />
        <cfargument name="fileName" type="string" required="true" />
        <cfset var scriptName = lCase(trim(CGI.SCRIPT_NAME)) />
        <cfset var routePath = "/" & lCase(trim(arguments.directory)) & "/" & lCase(trim(arguments.fileName)) />
        <cfset var apiRoutePath = "/api" & routePath />

        <cfreturn scriptName EQ apiRoutePath
            OR (isApiSubdomainRequest() AND scriptName EQ routePath) />
    </cffunction>

    <cffunction name="isApiDeveloperDocsRequest" access="private" returntype="boolean" output="false">
        <cfset var scriptName = lCase(trim(CGI.SCRIPT_NAME)) />

        <cfreturn scriptName EQ "/api/index.cfm"
            OR (isApiSubdomainRequest() AND listFindNoCase("/index.cfm,/api/index.cfm", scriptName)) />
    </cffunction>

    <cffunction name="isAthletesApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("athletes") />
    </cffunction>

    <cffunction name="isEventsApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("events") />
    </cffunction>

    <cffunction name="isResultsApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("results") />
    </cffunction>

    <cffunction name="isDiscoveryApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("discovery") />
    </cffunction>

    <cffunction name="isEditorialApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("editorial") />
    </cffunction>

    <cffunction name="isFeedApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("feed") AND NOT isApiRouteFileRequest("feed", "me.cfm") />
    </cffunction>

    <cffunction name="isChallengesApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("challenges") />
    </cffunction>

    <cffunction name="isTrainingApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("training") />
    </cffunction>

    <cffunction name="isCouponsApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("coupons") />
    </cffunction>

    <cffunction name="isSessionApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("session") />
    </cffunction>

    <cffunction name="isCurrentUserApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isApiRouteRequest("me") />
    </cffunction>

    <cffunction name="isAuthenticatedJsonApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isSessionApiRequest() OR isCurrentUserApiRequest() OR isApiRouteFileRequest("feed", "me.cfm") />
    </cffunction>

    <cffunction name="isPublicReadApiRequest" access="private" returntype="boolean" output="false">
        <cfreturn isAthletesApiRequest() OR isEventsApiRequest() OR isResultsApiRequest() OR isDiscoveryApiRequest() OR isEditorialApiRequest() OR isFeedApiRequest() OR isChallengesApiRequest() OR isTrainingApiRequest() OR isCouponsApiRequest() />
    </cffunction>

    <cffunction name="isApiBearerCandidateRequest" access="private" returntype="boolean" output="false">
        <cfreturn isPublicReadApiRequest() OR isAuthenticatedJsonApiRequest() />
    </cffunction>

    <cffunction name="getPublicReadApiRequiredScope" access="private" returntype="string" output="false">
        <cfif isAthletesApiRequest()>
            <cfreturn "athletes:read_public" />
        </cfif>

        <cfif isEventsApiRequest()>
            <cfreturn "events:read_public" />
        </cfif>

        <cfif isResultsApiRequest()>
            <cfreturn "results:read_public" />
        </cfif>

        <cfif isDiscoveryApiRequest()>
            <cfreturn "discovery:read_public" />
        </cfif>

        <cfif isEditorialApiRequest()>
            <cfreturn "editorial:read_public" />
        </cfif>

        <cfif isFeedApiRequest()>
            <cfreturn "feed:read_public" />
        </cfif>

        <cfif isChallengesApiRequest()>
            <cfreturn "challenges:read_public" />
        </cfif>

        <cfif isTrainingApiRequest()>
            <cfreturn "training:read_public" />
        </cfif>

        <cfif isCouponsApiRequest()>
            <cfreturn "coupons:read_public" />
        </cfif>

        <cfreturn "" />
    </cffunction>

    <cffunction name="getAuthenticatedJsonApiRequiredScope" access="private" returntype="string" output="false">
        <cfif NOT isAuthenticatedJsonApiRequest() OR isApiRouteFileRequest("me", "developer-token.cfm")>
            <cfreturn "" />
        </cfif>

        <cfif isSessionApiRequest()>
            <cfreturn "session:read" />
        </cfif>

        <cfreturn "me:read" />
    </cffunction>

    <cffunction name="getPublicReadApiScopeLabel" access="private" returntype="string" output="false">
        <cfargument name="scope" type="string" required="true" />

        <cfswitch expression="#lCase(trim(arguments.scope))#">
            <cfcase value="athletes:read_public">
                <cfreturn "atletas" />
            </cfcase>
            <cfcase value="events:read_public">
                <cfreturn "eventos" />
            </cfcase>
            <cfcase value="results:read_public">
                <cfreturn "resultados" />
            </cfcase>
            <cfcase value="discovery:read_public">
                <cfreturn "busca publica" />
            </cfcase>
            <cfcase value="editorial:read_public">
                <cfreturn "editorial" />
            </cfcase>
            <cfcase value="feed:read_public">
                <cfreturn "feed" />
            </cfcase>
            <cfcase value="challenges:read_public">
                <cfreturn "desafios" />
            </cfcase>
            <cfcase value="training:read_public">
                <cfreturn "treinos" />
            </cfcase>
            <cfcase value="coupons:read_public">
                <cfreturn "cupons" />
            </cfcase>
        </cfswitch>

        <cfreturn "API publica" />
    </cffunction>

    <cffunction name="abortApiIntegrationJson" access="private" returntype="void" output="false">
        <cfargument name="statusCode" type="numeric" required="true" />
        <cfargument name="status" type="string" required="true" />
        <cfargument name="message" type="string" required="true" />

        <cfcontent type="application/json; charset=utf-8" reset="true" />
        <cfheader statuscode="#arguments.statusCode#" statustext="" />
        <cfheader name="Cache-Control" value="no-store" />
        <cfheader name="X-Request-Id" value="#REQUEST.requestId#" />
        <cfoutput>#serializeJSON({
            "success" = false,
            "status" = arguments.status,
            "message" = arguments.message,
            "requestId" = REQUEST.requestId
        })#</cfoutput>
        <cfabort />
    </cffunction>

    <cffunction name="buildDefaultHandoffRedirect" access="private" returntype="string" output="false">
        <cfargument name="environment" type="string" required="true" />

        <cfif lCase(trim(arguments.environment)) EQ "dev">
            <cfreturn "/atleta/" />
        </cfif>

        <cfreturn "/" />
    </cffunction>

    <cffunction name="hasUsuarioColumn" access="private" returntype="boolean" output="false">
        <cfargument name="columnName" type="string" required="true" />
        <cfset var normalizedColumnName = lCase(trim(arguments.columnName)) />

        <cfif NOT len(normalizedColumnName)>
            <cfreturn false />
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "tbUsuariosColumnSupport") OR NOT isStruct(APPLICATION.tbUsuariosColumnSupport)>
            <cfset APPLICATION.tbUsuariosColumnSupport = {} />
        </cfif>

        <cfif NOT structKeyExists(APPLICATION.tbUsuariosColumnSupport, normalizedColumnName)>
            <cfquery name="qUsuarioColumnCheck">
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema = 'public'
                AND table_name = 'tb_usuarios'
                AND column_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#normalizedColumnName#"/>
                LIMIT 1
            </cfquery>
            <cfset APPLICATION.tbUsuariosColumnSupport[normalizedColumnName] = qUsuarioColumnCheck.recordcount GT 0 />
        </cfif>

        <cfreturn APPLICATION.tbUsuariosColumnSupport[normalizedColumnName] />
    </cffunction>

    <cffunction name="hasUserManagementStatusSchema" access="private" returntype="boolean" output="false">
        <cfset var qUserManagementSchema = "" />

        <cfif structKeyExists(APPLICATION, "userManagementStatusSchemaReady")
            AND APPLICATION.userManagementStatusSchemaReady>
            <cfreturn true />
        </cfif>

        <cftry>
            <cfquery name="qUserManagementSchema">
                SELECT
                    to_regclass('public.tb_usuarios_gestao') IS NOT NULL AS has_user_state,
                    to_regclass('public.tb_paginas_gestao') IS NOT NULL AS has_page_state
            </cfquery>
            <cfset APPLICATION.userManagementStatusSchemaReady = (
                isBoolean(qUserManagementSchema.has_user_state)
                    ? qUserManagementSchema.has_user_state
                    : listFindNoCase("1,true,yes,on", trim(qUserManagementSchema.has_user_state & "")) GT 0
                ) AND (
                isBoolean(qUserManagementSchema.has_page_state)
                    ? qUserManagementSchema.has_page_state
                    : listFindNoCase("1,true,yes,on", trim(qUserManagementSchema.has_page_state & "")) GT 0
                ) />
            <cfcatch type="any">
                <cfset APPLICATION.userManagementStatusSchemaReady = false />
            </cfcatch>
        </cftry>

        <cfreturn APPLICATION.userManagementStatusSchemaReady />
    </cffunction>

    <cffunction name="isUserManagementSessionActive" access="private" returntype="boolean" output="false">
        <cfargument name="userId" type="numeric" required="true" />
        <cfset var qUserManagementState = "" />

        <cfif NOT hasUserManagementStatusSchema()>
            <cfreturn true />
        </cfif>

        <cfquery name="qUserManagementState">
            SELECT
                coalesce(usrgest.ativo, true)
                AND NOT coalesce(usrgest.excluido, false)
                AND EXISTS (
                    SELECT 1
                    FROM tb_paginas_usuarios session_pgusr
                    INNER JOIN tb_paginas session_pag ON session_pag.id_pagina = session_pgusr.id_pagina
                    LEFT JOIN tb_paginas_gestao session_paggest ON session_paggest.id_pagina = session_pag.id_pagina
                    WHERE session_pgusr.id_usuario = usr.id
                      AND coalesce(session_paggest.ativo, true) = true
                      AND coalesce(session_paggest.excluido, false) = false
                ) AS session_active,
                usr.data_alteracao
            FROM tb_usuarios usr
            LEFT JOIN tb_usuarios_gestao usrgest ON usrgest.id_usuario = usr.id
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userId#"/>
        </cfquery>

        <cfif NOT qUserManagementState.recordcount>
            <cfreturn false />
        </cfif>

        <cfset REQUEST.userManagementAccountVersion = isDate(qUserManagementState.data_alteracao)
            ? dateTimeFormat(qUserManagementState.data_alteracao, "yyyy-mm-dd HH:nn:ss.l")
            : "" />

        <cfreturn isBoolean(qUserManagementState.session_active)
            ? qUserManagementState.session_active
            : listFindNoCase("1,true,yes,on", trim(qUserManagementState.session_active & "")) GT 0 />
    </cffunction>

    <cffunction name="normalizeLocalRedirectPath" access="private" returntype="string" output="false">
        <cfargument name="pathValue" type="string" required="false" default="" />
        <cfset var normalized = trim(arguments.pathValue) />

        <cfif NOT len(normalized)>
            <cfreturn "/" />
        </cfif>

        <cfif left(normalized, 1) NEQ "/" OR normalized CONTAINS "://" OR left(normalized, 2) EQ "//">
            <cfreturn "/" />
        </cfif>

        <cfreturn normalized />
    </cffunction>

    <cffunction name="getUsuarioCoreById" access="private" returntype="query" output="false">
        <cfargument name="userId" type="numeric" required="true" />
        <cfset var currentAssetsBaseUrl = "https://roadrunners.run/assets/paginas/" />

        <cfquery name="qUsuarioCore">
            SELECT
                usr.id,
                usr.email,
                usr.is_admin,
                usr.is_partner,
                usr.is_dev,
                usr.strava_id,
                (
                    coalesce(usr.strava_id, 0) > 0
                    AND nullif(trim(usr.strava_access_token), '') IS NOT NULL
                    AND nullif(trim(usr.strava_refresh_token), '') IS NOT NULL
                ) AS strava_connected,
                usr.name,
                usr.aka,
                usr.fonte_lead,
                usr.ano_nascimento,
                usr.assessoria,
                coalesce(<cfqueryparam cfsqltype="cf_sql_varchar" value="#currentAssetsBaseUrl#"/> || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                pag.tag,
                pag.id_pagina,
                coalesce(pag.nome, usr.name) as nome,
                pag.verificado,
                EXISTS (
                    SELECT 1
                    FROM tb_paginas_usuarios beta_pgusr
                    INNER JOIN tb_paginas beta_pag ON beta_pag.id_pagina = beta_pgusr.id_pagina
                    <cfif hasUserManagementStatusSchema()>
                        LEFT JOIN tb_paginas_gestao beta_paggest ON beta_paggest.id_pagina = beta_pag.id_pagina
                    </cfif>
                    WHERE beta_pgusr.id_usuario = usr.id
                    AND beta_pag.verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                    <cfif hasUserManagementStatusSchema()>
                        AND coalesce(beta_paggest.ativo, true) = true
                        AND coalesce(beta_paggest.excluido, false) = false
                    </cfif>
                ) as beta_verificado,
                pag.cidade,
                pag.uf,
                <cfif hasUsuarioColumn("partner_info")>
                    coalesce(usr.partner_info ->> 'location_region', usr.estado) as estado,
                <cfelse>
                    usr.estado,
                </cfif>
                usr.pais,
                pag.perfil_publico,
                pag.instagram,
                pag.instagram_publico,
                pag.youtube,
                pag.youtube_publico,
                pag.tiktok,
                pag.tiktok_publico,
                pag.website,
                pag.website_publico,
                pag.loja,
                pag.loja_publico,
                pag.whatsapp,
                pag.whatsapp_publico,
                pag.descricao,
                usr.inscricao_366,
                (
                    select produto
                    from desafios
                    where desafio = 'desafio365'
                    and id_usuario = usr.id
                    and status = 'C'
                ) as inscricao_365
            FROM tb_usuarios usr
            inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
            inner join tb_paginas pag on pag.id_pagina = pgusr.id_pagina
            <cfif hasUserManagementStatusSchema()>
                LEFT JOIN tb_usuarios_gestao usrgest ON usrgest.id_usuario = usr.id
                LEFT JOIN tb_paginas_gestao paggest ON paggest.id_pagina = pag.id_pagina
            </cfif>
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userId#"/>
            <cfif hasUserManagementStatusSchema()>
                AND coalesce(usrgest.ativo, true) = true
                AND coalesce(usrgest.excluido, false) = false
                AND coalesce(paggest.ativo, true) = true
                AND coalesce(paggest.excluido, false) = false
            </cfif>
        </cfquery>

        <cfreturn qUsuarioCore />
    </cffunction>

    <cffunction name="getUsuarioCoreByEmail" access="private" returntype="query" output="false">
        <cfargument name="email" type="string" required="true" />

        <cfquery name="qUsuarioCore">
            SELECT
                usr.id,
                usr.email,
                usr.is_admin,
                usr.is_partner,
                usr.is_dev,
                usr.strava_id,
                (
                    coalesce(usr.strava_id, 0) > 0
                    AND nullif(trim(usr.strava_access_token), '') IS NOT NULL
                    AND nullif(trim(usr.strava_refresh_token), '') IS NOT NULL
                ) AS strava_connected,
                usr.name,
                usr.aka,
                usr.fonte_lead,
                usr.ano_nascimento,
                usr.assessoria,
                coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                pag.tag,
                pag.id_pagina,
                coalesce(pag.nome, usr.name) as nome,
                pag.verificado,
                EXISTS (
                    SELECT 1
                    FROM tb_paginas_usuarios beta_pgusr
                    INNER JOIN tb_paginas beta_pag ON beta_pag.id_pagina = beta_pgusr.id_pagina
                    <cfif hasUserManagementStatusSchema()>
                        LEFT JOIN tb_paginas_gestao beta_paggest ON beta_paggest.id_pagina = beta_pag.id_pagina
                    </cfif>
                    WHERE beta_pgusr.id_usuario = usr.id
                    AND beta_pag.verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                    <cfif hasUserManagementStatusSchema()>
                        AND coalesce(beta_paggest.ativo, true) = true
                        AND coalesce(beta_paggest.excluido, false) = false
                    </cfif>
                ) as beta_verificado,
                pag.cidade,
                pag.uf,
                <cfif hasUsuarioColumn("partner_info")>
                    coalesce(usr.partner_info ->> 'location_region', usr.estado) as estado,
                <cfelse>
                    usr.estado,
                </cfif>
                usr.pais,
                pag.perfil_publico,
                pag.instagram,
                pag.instagram_publico,
                pag.youtube,
                pag.youtube_publico,
                pag.tiktok,
                pag.tiktok_publico,
                pag.website,
                pag.website_publico,
                pag.loja,
                pag.loja_publico,
                pag.whatsapp,
                pag.whatsapp_publico,
                pag.descricao,
                usr.inscricao_366,
                (
                    select produto
                    from desafios
                    where desafio = 'desafio365'
                    and id_usuario = usr.id
                    and status = 'C'
                ) as inscricao_365
            FROM tb_usuarios usr
            inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
            inner join tb_paginas pag on pag.id_pagina = pgusr.id_pagina
            <cfif hasUserManagementStatusSchema()>
                LEFT JOIN tb_usuarios_gestao usrgest ON usrgest.id_usuario = usr.id
                LEFT JOIN tb_paginas_gestao paggest ON paggest.id_pagina = pag.id_pagina
            </cfif>
            WHERE lower(usr.email) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.email)#"/>)
            <cfif hasUserManagementStatusSchema()>
                AND coalesce(usrgest.ativo, true) = true
                AND coalesce(usrgest.excluido, false) = false
                AND coalesce(paggest.ativo, true) = true
                AND coalesce(paggest.excluido, false) = false
            </cfif>
        </cfquery>

        <cfreturn qUsuarioCore />
    </cffunction>

    <cffunction name="setAuthCookiesFromUsuarioRow" access="private" returntype="void" output="false">
        <cfargument name="usuarioRow" type="struct" required="true" />
        <cfset var authCookieDomain = listFirst(CGI.HTTP_HOST, ":") />

        <cfcookie domain="#authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="#arguments.usuarioRow.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#arguments.usuarioRow.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="#arguments.usuarioRow.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="#arguments.usuarioRow.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#arguments.usuarioRow.tag#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>

        <cfreturn />
    </cffunction>

    <cffunction name="seedDevAuthSession" access="private" returntype="void" output="false">
        <cfargument name="originalUsuarioRow" type="struct" required="true" />
        <cfargument name="impersonatedUsuarioRow" type="struct" required="false" default="#structNew()#" />
        <cfargument name="isImpersonating" type="boolean" required="false" default="false" />

        <cfset SESSION.devAuth = {
            originalUsuarioId = arguments.originalUsuarioRow.id,
            originalEmail = arguments.originalUsuarioRow.email,
            isImpersonating = arguments.isImpersonating
        } />

        <cfif arguments.isImpersonating AND structKeyExists(arguments.impersonatedUsuarioRow, "id")>
            <cfset SESSION.devAuth.impersonatedUsuarioId = arguments.impersonatedUsuarioRow.id />
            <cfset SESSION.devAuth.impersonatedEmail = arguments.impersonatedUsuarioRow.email />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="canUsuarioAccessBeta" access="private" returntype="boolean" output="false">
        <cfargument name="usuario" type="any" required="true" />
        <cfset var verificadoValor = "" />
        <cfset var betaVerificadoValor = "" />

        <cfif NOT isObject(arguments.usuario) OR NOT arguments.usuario.logado>
            <cfreturn false />
        </cfif>

        <cfif arguments.usuario.is_admin OR arguments.usuario.is_dev>
            <cfreturn true />
        </cfif>

        <cfif isDefined("arguments.usuario.verificado")>
            <cfset verificadoValor = arguments.usuario.verificado />
        </cfif>

        <cfif (isBoolean(verificadoValor) AND verificadoValor)
            OR listFindNoCase("true,yes,1", lCase(trim(verificadoValor)))>
            <cfreturn true />
        </cfif>

        <cfif isDefined("arguments.usuario.beta_verificado")>
            <cfset betaVerificadoValor = arguments.usuario.beta_verificado />
        </cfif>

        <cfif (isBoolean(betaVerificadoValor) AND betaVerificadoValor)
            OR listFindNoCase("true,yes,1", lCase(trim(betaVerificadoValor)))>
            <cfreturn true />
        </cfif>

        <cfreturn false />
    </cffunction>

    <cffunction name="isBetaAccessBypassRequest" access="private" returntype="boolean" output="false">
        <cfset var scriptName = lCase(trim(CGI.SCRIPT_NAME)) />
        <cfset var actionName = isDefined("URL.action") ? lCase(trim(URL.action)) : "" />
        <cfset var requiredApiScope = getPublicReadApiRequiredScope() />

        <cfif scriptName CONTAINS "/login/">
            <cfreturn true />
        </cfif>

        <cfif listFindNoCase("handoff_start,handoff_consume", actionName)>
            <cfreturn true />
        </cfif>

        <cfif isApiDeveloperDocsRequest()>
            <cfreturn true />
        </cfif>

        <!--- Endpoints maquina-a-maquina de mensageria possuem autenticacao
              propria e precisam funcionar sem sessao web no host Beta. --->
        <cfif listFindNoCase(
            "/api/integrations/manychat/inbound.cfm,/api/integrations/manychat/link-token.cfm,/api/integrations/manychat/worker.cfm,/api/integrations/meta-whatsapp/webhook.cfm,/api/integrations/meta-whatsapp/worker.cfm,/api/integrations/meta-whatsapp/health.cfm",
            scriptName
        )>
            <cfreturn true />
        </cfif>

        <cfif len(requiredApiScope)
            AND structKeyExists(REQUEST, "apiIntegration")
            AND apiIntegrationHasScope(REQUEST.apiIntegration, requiredApiScope)>
            <cfreturn true />
        </cfif>

        <cfreturn false />
    </cffunction>

    <cffunction name="enforceApiBearerAccess" access="private" returntype="void" output="false">
        <cfset var authorizationHeader = "" />
        <cfset var requiredApiScope = getPublicReadApiRequiredScope() />
        <cfset var requiredApiScopeLabel = getPublicReadApiScopeLabel(requiredApiScope) />

        <cfif NOT len(requiredApiScope)>
            <cfreturn />
        </cfif>

        <cfset authorizationHeader = getAuthorizationHeaderValue() />

        <cfif NOT len(authorizationHeader)>
            <cfset abortApiIntegrationJson(401, "missing_token", "Authorization Bearer obrigatorio para acessar a API de #requiredApiScopeLabel#.") />
        </cfif>

        <cfif NOT structKeyExists(REQUEST, "apiIntegration") OR NOT REQUEST.apiIntegration.authenticated>
            <cfset abortApiIntegrationJson(401, "invalid_token", "Credencial Bearer invalida ou expirada.") />
        </cfif>

        <cfif NOT apiIntegrationHasScope(REQUEST.apiIntegration, requiredApiScope)>
            <cfset abortApiIntegrationJson(403, "insufficient_scope", "Credencial sem escopo para leitura de #requiredApiScopeLabel#.") />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="enforceAuthenticatedJsonApiAccess" access="private" returntype="void" output="false">
        <cfset var usuario = structKeyExists(REQUEST, "Usuario") ? REQUEST.Usuario : buildEmptyUsuario() />
        <cfset var requiredScope = getAuthenticatedJsonApiRequiredScope() />

        <cfif NOT isAuthenticatedJsonApiRequest() OR NOT len(requiredScope)>
            <cfreturn />
        </cfif>

        <cfif isObject(usuario) AND structKeyExists(usuario, "logado") AND usuario.logado>
            <cfreturn />
        </cfif>

        <cfif structKeyExists(REQUEST, "apiIntegration")
            AND isStruct(REQUEST.apiIntegration)
            AND apiIntegrationHasScope(REQUEST.apiIntegration, requiredScope)
            AND structKeyExists(REQUEST.apiIntegration, "source")
            AND listFindNoCase("user,mobile", REQUEST.apiIntegration.source)>
            <cfset abortApiIntegrationJson(401, "not_authenticated", "Token de usuario invalido ou sem usuario ativo.") />
        </cfif>

        <cfset abortApiIntegrationJson(401, "not_authenticated", "Sessao nao autenticada.") />

        <cfreturn />
    </cffunction>

    <cffunction name="enforceBetaAccess" access="private" returntype="void" output="false">
        <cfset var usuario = structKeyExists(REQUEST, "Usuario") ? REQUEST.Usuario : buildEmptyUsuario() />
        <cfset var authorizationHeader = "" />
        <cfset var requiredApiScope = getPublicReadApiRequiredScope() />
        <cfset var requiredApiScopeLabel = getPublicReadApiScopeLabel(requiredApiScope) />

        <cfif REQUEST.currentEnvironment NEQ "beta">
            <cfreturn />
        </cfif>

        <cfif isBetaAccessBypassRequest()>
            <cfreturn />
        </cfif>

        <cfif len(requiredApiScope)>
            <cfset authorizationHeader = getAuthorizationHeaderValue() />

            <cfif len(authorizationHeader)>
                <cfif NOT structKeyExists(REQUEST, "apiIntegration") OR NOT REQUEST.apiIntegration.authenticated>
                    <cfset abortApiIntegrationJson(401, "invalid_token", "Credencial Bearer invalida ou expirada.") />
                </cfif>

                <cfif NOT apiIntegrationHasScope(REQUEST.apiIntegration, requiredApiScope)>
                    <cfset abortApiIntegrationJson(403, "insufficient_scope", "Credencial sem escopo para leitura publica de #requiredApiScopeLabel#.") />
                </cfif>
            </cfif>
        </cfif>

        <cfif isAuthenticatedJsonApiRequest()>
            <cfif NOT usuario.logado>
                <cfset abortApiIntegrationJson(401, "not_authenticated", "Sessao nao autenticada.") />
            </cfif>

            <cfif NOT canUsuarioAccessBeta(usuario)>
                <cfset abortApiIntegrationJson(403, "beta_access_denied", "Usuario sem acesso ao beta.") />
            </cfif>
        </cfif>

        <cfif NOT usuario.logado>
            <cflocation addtoken="false" url="/login/" />
        </cfif>

        <cfif NOT canUsuarioAccessBeta(usuario)>
            <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="createHandoffToken" access="private" returntype="string" output="false">
        <cfargument name="payload" type="struct" required="true" />
        <cfset var payloadEncoded = toBase64(serializeJSON(arguments.payload)) />
        <cfset var signature = lCase(hmac(payloadEncoded, APPLICATION.handoff.secret, "HmacSHA256")) />

        <cfreturn payloadEncoded & "." & signature />
    </cffunction>

    <cffunction name="validateHandoffToken" access="private" returntype="struct" output="false">
        <cfargument name="token" type="string" required="true" />
        <cfargument name="expectedTarget" type="string" required="true" />
        <cfset var result = { success = false, error = "invalid_token", payload = structNew() } />
        <cfset var parts = [] />
        <cfset var expectedSignature = "" />
        <cfset var decodedPayload = "" />
        <cfset var parsedExpiresAt = "" />

        <cfif NOT len(trim(arguments.token))>
            <cfreturn result />
        </cfif>

        <cfset parts = listToArray(arguments.token, ".") />

        <cfif arrayLen(parts) NEQ 2>
            <cfreturn result />
        </cfif>

        <cfset expectedSignature = lCase(hmac(parts[1], APPLICATION.handoff.secret, "HmacSHA256")) />

        <cfif expectedSignature NEQ lCase(parts[2])>
            <cfset result.error = "invalid_signature" />
            <cfreturn result />
        </cfif>

        <cftry>
            <cfset decodedPayload = toString(binaryDecode(parts[1], "base64")) />
            <cfset result.payload = deserializeJSON(decodedPayload) />
            <cfcatch type="any">
                <cfset result.error = "invalid_payload" />
                <cfreturn result />
            </cfcatch>
        </cftry>

        <cfif NOT isStruct(result.payload)
            OR NOT structKeyExists(result.payload, "target")
            OR lCase(trim(result.payload.target)) NEQ lCase(trim(arguments.expectedTarget))>
            <cfset result.error = "invalid_target" />
            <cfreturn result />
        </cfif>

        <cfif structKeyExists(result.payload, "expiresAt") AND NOT isDate(result.payload.expiresAt) AND isSimpleValue(result.payload.expiresAt) AND len(trim(result.payload.expiresAt))>
            <cftry>
                <cfset parsedExpiresAt = parseDateTime(result.payload.expiresAt) />
                <cfset result.payload.expiresAt = parsedExpiresAt />
                <cfcatch type="any"></cfcatch>
            </cftry>
        </cfif>

        <cfif NOT structKeyExists(result.payload, "expiresAt")
            OR NOT isDate(result.payload.expiresAt)
            OR result.payload.expiresAt LTE now()>
            <cfset result.error = "token_expired" />
            <cfreturn result />
        </cfif>

        <cfset result.success = true />
        <cfset result.error = "" />

        <cfreturn result />
    </cffunction>

    <cffunction name="processEnvironmentHandoff" access="private" returntype="void" output="false">
        <cfset var currentEnvironment = REQUEST.currentEnvironment />
        <cfset var targetEnvironment = "" />
        <cfset var redirectPath = "/" />
        <cfset var handoffPayload = structNew() />
        <cfset var handoffToken = "" />
        <cfset var validation = structNew() />
        <cfset var originalUsuarioRow = structNew() />
        <cfset var targetUsuarioRow = structNew() />
        <cfset var qOriginalUsuario = "" />
        <cfset var qTargetUsuario = "" />
        <cfset var impersonateEmail = "" />

        <cfif NOT isDefined("URL.action")>
            <cfreturn />
        </cfif>

        <cfif URL.action EQ "handoff_start">
            <cfif NOT REQUEST.Usuario.logado>
                <cflocation addtoken="false" url="/" />
            </cfif>

            <cfparam name="URL.target" default="" />
            <cfparam name="URL.dev_auth" default="" />
            <cfparam name="URL.redirect_to" default="" />

            <cfset targetEnvironment = lCase(trim(URL.target)) />

            <cfif NOT listFindNoCase("beta,dev", targetEnvironment)>
                <cflocation addtoken="false" url="/" />
            </cfif>

            <cfif currentEnvironment EQ targetEnvironment>
                <cfset redirectPath = len(trim(URL.redirect_to)) ? normalizeLocalRedirectPath(URL.redirect_to) : buildDefaultHandoffRedirect(targetEnvironment) />
                <cflocation addtoken="false" url="#redirectPath#" />
            </cfif>

            <cfif targetEnvironment EQ "beta" AND NOT canUsuarioAccessBeta(REQUEST.Usuario)>
                <cflocation addtoken="false" url="/" />
            </cfif>

            <cfset handoffPayload = {
                issuedAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
                expiresAt = dateTimeFormat(dateAdd("s", APPLICATION.handoff.ttlSeconds, now()), "yyyy-mm-dd HH:nn:ss"),
                origin = currentEnvironment,
                target = targetEnvironment,
                originalUsuarioId = REQUEST.Usuario.id,
                redirectPath = len(trim(URL.redirect_to)) ? normalizeLocalRedirectPath(URL.redirect_to) : buildDefaultHandoffRedirect(targetEnvironment)
            } />

            <cfif targetEnvironment EQ "dev" AND len(trim(URL.dev_auth))>
                <cfif NOT (REQUEST.Usuario.is_admin OR REQUEST.Usuario.is_dev)>
                    <cflocation addtoken="false" url="/" />
                </cfif>
                <cfset handoffPayload.impersonateEmail = trim(URL.dev_auth) />
            </cfif>

            <cfset handoffToken = createHandoffToken(handoffPayload) />
            <cflocation addtoken="false" url="#getEnvironmentBaseUrl(targetEnvironment)#/?action=handoff_consume&token=#urlEncodedFormat(handoffToken)#" />
        </cfif>

        <cfif URL.action EQ "handoff_consume">
            <cfif currentEnvironment EQ "prod">
                <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
            </cfif>

            <cfparam name="URL.token" default="" />
            <cfset validation = validateHandoffToken(URL.token, currentEnvironment) />

            <cfif NOT validation.success>
                <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
            </cfif>

            <cfset qOriginalUsuario = getUsuarioCoreById(val(validation.payload.originalUsuarioId)) />

            <cfif NOT qOriginalUsuario.recordcount>
                <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
            </cfif>

            <cfset originalUsuarioRow = QueryGetRow(qOriginalUsuario, 1) />

            <cfif currentEnvironment EQ "beta">
                <cfset targetUsuarioRow = duplicate(originalUsuarioRow) />
                <cfset REQUEST._handoffUsuarioBeta = createObject("component", "includes.models.Usuario").init(targetUsuarioRow) />
                <cfset REQUEST._handoffUsuarioBeta.logado = true />
                <cfif NOT canUsuarioAccessBeta(REQUEST._handoffUsuarioBeta)>
                    <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
                </cfif>
                <cfset setAuthCookiesFromUsuarioRow(targetUsuarioRow) />
                <cfif structKeyExists(SESSION, "UsuarioCache")>
                    <cfset StructClear(SESSION.UsuarioCache) />
                </cfif>
                <cfif structKeyExists(REQUEST, "_handoffUsuarioBeta")>
                    <cfset StructDelete(REQUEST, "_handoffUsuarioBeta", false) />
                </cfif>
            </cfif>

            <cfif currentEnvironment EQ "dev">
                <cfif NOT (originalUsuarioRow.is_admin OR originalUsuarioRow.is_dev)>
                    <cfset StructDelete(SESSION, "devAuth", false) />
                    <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
                </cfif>

                <cfset impersonateEmail = structKeyExists(validation.payload, "impersonateEmail") ? trim(validation.payload.impersonateEmail) : "" />

                <cfif len(impersonateEmail)>
                    <cfset qTargetUsuario = getUsuarioCoreByEmail(impersonateEmail) />
                    <cfif NOT qTargetUsuario.recordcount>
                        <cflocation addtoken="false" url="#APPLICATION.baseCanonica#/" />
                    </cfif>
                    <cfset targetUsuarioRow = QueryGetRow(qTargetUsuario, 1) />
                    <cfset setAuthCookiesFromUsuarioRow(targetUsuarioRow) />
                    <cfset seedDevAuthSession(originalUsuarioRow=originalUsuarioRow, impersonatedUsuarioRow=targetUsuarioRow, isImpersonating=(targetUsuarioRow.id NEQ originalUsuarioRow.id)) />
                <cfelse>
                    <cfset targetUsuarioRow = duplicate(originalUsuarioRow) />
                    <cfset setAuthCookiesFromUsuarioRow(targetUsuarioRow) />
                    <cfset seedDevAuthSession(originalUsuarioRow=originalUsuarioRow, isImpersonating=false) />
                </cfif>

                <cfif structKeyExists(SESSION, "UsuarioCache")>
                    <cfset StructClear(SESSION.UsuarioCache) />
                </cfif>
            </cfif>

            <cflocation addtoken="false" url="#normalizeLocalRedirectPath(validation.payload.redirectPath)#" />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="buildRequestUsuario" access="private" returntype="any" output="false">
        <cfset var usuario = buildEmptyUsuario() />
        <cfset var cookieId = "" />
        <cfset var cacheCore = structNew() />
        <cfset var qUsuarioCore = "" />

        <cfif NOT structKeyExists(COOKIE, "id") OR NOT len(trim(COOKIE.id))>
            <cfreturn usuario />
        </cfif>

        <cfset cookieId = trim(COOKIE.id) />

        <cfif NOT isValid("integer", cookieId)>
            <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                <cfset structDelete(SESSION.UsuarioCache, "core", false) />
            </cfif>

            <cfreturn usuario />
        </cfif>

        <cfif NOT isUserManagementSessionActive(val(cookieId))>
            <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                <cfset structDelete(SESSION.UsuarioCache, "core", false) />
            </cfif>

            <cfreturn usuario />
        </cfif>

        <cfif structKeyExists(SESSION.UsuarioCache, "core")
            AND isStruct(SESSION.UsuarioCache.core)
            AND structKeyExists(SESSION.UsuarioCache.core, "id")
            AND structKeyExists(SESSION.UsuarioCache.core, "data")
            AND isStruct(SESSION.UsuarioCache.core.data)
            AND structKeyExists(SESSION.UsuarioCache.core.data, "beta_verificado")
            AND structKeyExists(SESSION.UsuarioCache.core.data, "strava_connected")
            AND structKeyExists(SESSION.UsuarioCache.core, "accountVersion")
            AND SESSION.UsuarioCache.core.accountVersion EQ (
                structKeyExists(REQUEST, "userManagementAccountVersion")
                    ? REQUEST.userManagementAccountVersion
                    : ""
            )
            AND structKeyExists(SESSION.UsuarioCache.core, "expiresAt")
            AND isDate(SESSION.UsuarioCache.core.expiresAt)
            AND SESSION.UsuarioCache.core.id EQ val(cookieId)
            AND SESSION.UsuarioCache.core.expiresAt GT now()>

            <cfset cacheCore = duplicate(SESSION.UsuarioCache.core.data) />
            <cfset usuario = createObject("component", "includes.models.Usuario").init(cacheCore) />
            <cfset usuario.logado = true />

            <cfreturn usuario />
        </cfif>

        <cfset qUsuarioCore = getUsuarioCoreById(val(cookieId)) />

        <cfif qUsuarioCore.recordcount>
            <cfset usuario = createObject("component", "includes.models.Usuario").init(QueryGetRow(qUsuarioCore, 1)) />
            <cfset usuario.logado = true />
            <cfset SESSION.UsuarioCache.core = {
                id = usuario.id,
                data = usuario.toStruct(),
                accountVersion = (
                    structKeyExists(REQUEST, "userManagementAccountVersion")
                        ? REQUEST.userManagementAccountVersion
                        : ""
                ),
                loadedAt = now(),
                expiresAt = dateAdd("n", 15, now())
            } />
        <cfelse>
            <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                <cfset structDelete(SESSION.UsuarioCache, "core", false) />
            </cfif>
        </cfif>

        <cfreturn usuario />
    </cffunction>


    <cffunction
            name="OnRequest"
            access="public"
            returntype="void"
            output="true"
            hint="Fires after pre page processing is complete.">

        <!--- Define arguments. --->
        <cfargument
                name="TargetPage"
                type="string"
                required="true"
                />

        <!--- Include the requested page. --->
        <cfinclude template="#ARGUMENTS.TargetPage#" />

        <!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnRequestEnd"
            access="public"
            returntype="void"
            output="true"
            hint="Fires after the page processing is complete.">

        <!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnSessionEnd"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the session is terminated.">

        <!--- Define arguments. --->
        <cfargument
                name="SessionScope"
                type="struct"
                required="true"
                />

        <cfargument
                name="ApplicationScope"
                type="struct"
                required="false"
                default="#StructNew()#"
                />

        <!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnApplicationEnd"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the application is terminated.">

        <!--- Define arguments. --->
        <cfargument
                name="ApplicationScope"
                type="struct"
                required="false"
                default="#StructNew()#"
                />

        <!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnError"
            access="public"
            returntype="void"
            output="true"
            hint="Fires when an exception occures that is not caught by a try/catch.">

        <!--- Define arguments. --->
        <cfargument name="exception" required="true">
        <cfargument name="eventname" type="string" required="true">
        <cfset var errortext = "">
        <cfset var usuarioLogId = "" />

        <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND structKeyExists(REQUEST.Usuario, "logado") AND REQUEST.Usuario.logado>
            <cfset usuarioLogId = REQUEST.Usuario.id />
        <cfelseif structKeyExists(COOKIE, "id") AND len(trim(COOKIE.id))>
            <cfset usuarioLogId = trim(COOKIE.id) />
        </cfif>

        <cfif NOT isDefined("URL.debug") AND CGI.HTTP_HOST DOES NOT CONTAIN 'dev.'>

            <cfsavecontent variable="errortext">
                <cfoutput>
                    An error occurred: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#
                Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#

                    <cfdump var="#arguments.exception#" label="Error">
                    <cfdump var="#form#" label="Form">
                    <cfdump var="#url#" label="URL">

                </cfoutput>
            </cfsavecontent>

            <cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                    subject="Erro de código: #arguments.exception.message#" usetls="true"
                    server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                    charset="utf-8" type="html" port="587">
                #errortext#
            </cfmail>

            <cfquery>
                INSERT INTO tb_log
                (log_item, log_item_id, log_user, site)
                VALUES
                (
                'erro',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#errortext#"/>,
                <cfif len(trim(usuarioLogId))>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#usuarioLogId#"/>,
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#SESSION.SESSIONID#"/>,
                </cfif>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>
                )
            </cfquery>

            <cflocation url="/404/" addtoken="false"/>

        <cfelse>

            <cfthrow object="#arguments.exception#">

        </cfif>

        <cfreturn/>

    </cffunction>

    <cffunction name="removerAcentos" access="public" returntype="string">
        <cfargument name="texto" type="string" required="true">
        <cfreturn ReplaceList(arguments.texto,
            "á,à,ã,â,ä,Á,À,Ã,Â,Ä,é,è,ê,ë,É,È,Ê,Ë,í,ì,î,ï,Í,Ì,Î,Ï,ó,ò,õ,ô,ö,Ó,Ò,Õ,Ô,Ö,ú,ù,û,ü,Ú,Ù,Û,Ü,ç,Ç",
            "a,a,a,a,a,A,A,A,A,A,e,e,e,e,E,E,E,E,i,i,i,i,I,I,I,I,o,o,o,o,o,O,O,O,O,O,u,u,u,u,U,U,U,U,c,C"
        )>
    </cffunction>

</cfcomponent>
