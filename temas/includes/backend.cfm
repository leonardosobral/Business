<cfscript>
function themesDirectoryWritable(required string directoryPath) {
    var directoryFile = createObject("java", "java.io.File").init(arguments.directoryPath);
    return directoryFile.exists() AND directoryFile.canWrite();
}
</cfscript>

<cfparam name="URL.tema_id" default=""/>
<cfparam name="URL.tema_novo" default=""/>
<cfparam name="FORM.acao" default=""/>

<cfset VARIABLES.themesAlert = { type = "", message = "" }/>
<cfset VARIABLES.themesLogoDiskPath = expandPath("/assets/logos/")/>
<cfset VARIABLES.themesBannerDiskPath = expandPath("/assets/img/temas/")/>
<cfset VARIABLES.themesBannerWebPath = "/assets/img/temas/"/>

<cfif NOT directoryExists(VARIABLES.themesBannerDiskPath)>
    <cftry>
        <cfdirectory action="create" directory="#VARIABLES.themesBannerDiskPath#"/>
    <cfcatch type="any">
        <cfset VARIABLES.themesAlert = { type = "danger", message = "Nao foi possivel preparar a pasta de banners dos temas." }/>
    </cfcatch>
    </cftry>
</cfif>

<cfif isDefined("qPerfil") AND qPerfil.recordcount GT 0 AND qPerfil.is_admin AND FORM.acao EQ "salvar_tema">
    <cfset VARIABLES.themeSaveErrors = []/>
    <cfset VARIABLES.themeId = isDefined("FORM.id_tema") ? trim(FORM.id_tema) : ""/>
    <cfset VARIABLES.themeLogo = isDefined("FORM.logo") ? trim(FORM.logo) : ""/>
    <cfset VARIABLES.themeTag = isDefined("FORM.tag") ? trim(FORM.tag) : ""/>
    <cfset VARIABLES.themeWebsite = isDefined("FORM.website") ? trim(FORM.website) : ""/>
    <cfset VARIABLES.themeInstagram = isDefined("FORM.instagram") ? trim(FORM.instagram) : ""/>
    <cfset VARIABLES.themeYoutube = isDefined("FORM.youtube") ? trim(FORM.youtube) : ""/>
    <cfset VARIABLES.themeAppIos = isDefined("FORM.app_ios") ? trim(FORM.app_ios) : ""/>
    <cfset VARIABLES.themeAppAndroid = isDefined("FORM.app_android") ? trim(FORM.app_android) : ""/>
    <cfset VARIABLES.themeCorFundo = isDefined("FORM.cor_fundo") ? trim(FORM.cor_fundo) : ""/>
    <cfset VARIABLES.themeCorFonte = isDefined("FORM.cor_fonte") ? trim(FORM.cor_fonte) : ""/>
    <cfset VARIABLES.themeCorBotoes = isDefined("FORM.cor_botoes") ? trim(FORM.cor_botoes) : ""/>
    <cfset VARIABLES.themeBanner = isDefined("FORM.banner") ? trim(FORM.banner) : ""/>
    <cfset VARIABLES.themeHasLogoUpload = isDefined("FORM.logo_arquivo") AND len(trim(FORM.logo_arquivo & "")) GT 0/>
    <cfset VARIABLES.themeHasBannerUpload = isDefined("FORM.banner_arquivo") AND len(trim(FORM.banner_arquivo & "")) GT 0/>

    <cfif VARIABLES.themeHasLogoUpload AND NOT themesDirectoryWritable(VARIABLES.themesLogoDiskPath)>
        <cfset arrayAppend(VARIABLES.themeSaveErrors, "A pasta de logos nao esta gravavel pelo servidor: " & VARIABLES.themesLogoDiskPath)/>
    </cfif>

    <cfif VARIABLES.themeHasBannerUpload AND NOT themesDirectoryWritable(VARIABLES.themesBannerDiskPath)>
        <cfset arrayAppend(VARIABLES.themeSaveErrors, "A pasta de banners nao esta gravavel pelo servidor: " & VARIABLES.themesBannerDiskPath)/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.themeSaveErrors) AND VARIABLES.themeHasLogoUpload>
        <cftry>
            <cffile action="upload"
                    filefield="logo_arquivo"
                    destination="#VARIABLES.themesLogoDiskPath#"
                    nameconflict="makeunique"
                    result="themeLogoUploadResult"/>

            <cfset VARIABLES.themeLogoExtension = lCase(themeLogoUploadResult.serverFileExt)/>
            <cfif VARIABLES.themeLogoExtension NEQ "png">
                <cfif fileExists(VARIABLES.themesLogoDiskPath & themeLogoUploadResult.serverFile)>
                    <cffile action="delete" file="#VARIABLES.themesLogoDiskPath##themeLogoUploadResult.serverFile#"/>
                </cfif>
                <cfset arrayAppend(VARIABLES.themeSaveErrors, "Envie o logo em PNG. O Road Runners usa /assets/logos/{logo}.png para estes temas.")/>
            <cfelse>
                <cfset VARIABLES.themeLogo = reReplace(themeLogoUploadResult.serverFile, "\.png$", "", "one")/>
            </cfif>
        <cfcatch type="any">
            <cfset arrayAppend(VARIABLES.themeSaveErrors, "Nao foi possivel enviar o logo: " & cfcatch.message)/>
        </cfcatch>
        </cftry>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.themeSaveErrors) AND VARIABLES.themeHasBannerUpload>
        <cftry>
            <cffile action="upload"
                    filefield="banner_arquivo"
                    destination="#VARIABLES.themesBannerDiskPath#"
                    nameconflict="makeunique"
                    result="themeBannerUploadResult"/>

            <cfset VARIABLES.themeBannerExtension = lCase(themeBannerUploadResult.serverFileExt)/>
            <cfif NOT listFindNoCase("jpg,jpeg,png,gif", VARIABLES.themeBannerExtension)>
                <cfif fileExists(VARIABLES.themesBannerDiskPath & themeBannerUploadResult.serverFile)>
                    <cffile action="delete" file="#VARIABLES.themesBannerDiskPath##themeBannerUploadResult.serverFile#"/>
                </cfif>
                <cfset arrayAppend(VARIABLES.themeSaveErrors, "Envie o banner em JPG, PNG ou GIF.")/>
            <cfelse>
                <cfset VARIABLES.themeBanner = VARIABLES.themesBannerWebPath & themeBannerUploadResult.serverFile/>
            </cfif>
        <cfcatch type="any">
            <cfset arrayAppend(VARIABLES.themeSaveErrors, "Nao foi possivel enviar o banner: " & cfcatch.message)/>
        </cfcatch>
        </cftry>
    </cfif>

    <cfif arrayLen(VARIABLES.themeSaveErrors)>
        <cfset VARIABLES.themesAlert = { type = "warning", message = arrayToList(VARIABLES.themeSaveErrors, " ") }/>
    <cfelseif len(VARIABLES.themeId) AND isNumeric(VARIABLES.themeId)>
        <cfquery>
            UPDATE tb_temas
            SET logo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeLogo#" null="#NOT len(VARIABLES.themeLogo)#"/>,
                app_ios = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeAppIos#" null="#NOT len(VARIABLES.themeAppIos)#"/>,
                app_android = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeAppAndroid#" null="#NOT len(VARIABLES.themeAppAndroid)#"/>,
                cor_fundo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorFundo#" null="#NOT len(VARIABLES.themeCorFundo)#"/>,
                cor_fonte = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorFonte#" null="#NOT len(VARIABLES.themeCorFonte)#"/>,
                cor_botoes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorBotoes#" null="#NOT len(VARIABLES.themeCorBotoes)#"/>,
                website = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeWebsite#" null="#NOT len(VARIABLES.themeWebsite)#"/>,
                instagram = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeInstagram#" null="#NOT len(VARIABLES.themeInstagram)#"/>,
                banner = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeBanner#" null="#NOT len(VARIABLES.themeBanner)#"/>,
                youtube = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeYoutube#" null="#NOT len(VARIABLES.themeYoutube)#"/>,
                tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeTag#" null="#NOT len(VARIABLES.themeTag)#"/>
            WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.themeId)#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?tema_id=#val(VARIABLES.themeId)#&sucesso=atualizado"/>
    <cfelse>
        <cfquery name="qThemeInsert">
            INSERT INTO tb_temas
                (logo, app_ios, app_android, cor_fundo, cor_fonte, cor_botoes, website, instagram, banner, youtube, tag)
            VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeLogo#" null="#NOT len(VARIABLES.themeLogo)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeAppIos#" null="#NOT len(VARIABLES.themeAppIos)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeAppAndroid#" null="#NOT len(VARIABLES.themeAppAndroid)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorFundo#" null="#NOT len(VARIABLES.themeCorFundo)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorFonte#" null="#NOT len(VARIABLES.themeCorFonte)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeCorBotoes#" null="#NOT len(VARIABLES.themeCorBotoes)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeWebsite#" null="#NOT len(VARIABLES.themeWebsite)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeInstagram#" null="#NOT len(VARIABLES.themeInstagram)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeBanner#" null="#NOT len(VARIABLES.themeBanner)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeYoutube#" null="#NOT len(VARIABLES.themeYoutube)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.themeTag#" null="#NOT len(VARIABLES.themeTag)#"/>
                )
            RETURNING id_tema
        </cfquery>
        <cflocation addtoken="false" url="./?tema_id=#qThemeInsert.id_tema#&sucesso=criado"/>
    </cfif>
</cfif>

<cfquery name="qThemesList">
    SELECT tm.*,
           (
               SELECT count(*)
               FROM tb_evento_corridas evt
               WHERE evt.id_tema = tm.id_tema
           ) as total_eventos,
           (
               SELECT count(*)
               FROM tb_agregadores agr
               WHERE agr.id_tema = tm.id_tema
           ) as total_agregadores
    FROM tb_temas tm
    ORDER BY coalesce(nullif(tm.logo, ''), tm.tag, tm.id_tema::varchar)
</cfquery>

<cfquery name="qThemeEdit">
    SELECT *
    FROM tb_temas
    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.tema_id) ? val(URL.tema_id) : 0#"/>
</cfquery>

<cfif isDefined("URL.sucesso") AND URL.sucesso EQ "criado">
    <cfset VARIABLES.themesAlert = { type = "success", message = "Tema criado com sucesso." }/>
<cfelseif isDefined("URL.sucesso") AND URL.sucesso EQ "atualizado">
    <cfset VARIABLES.themesAlert = { type = "success", message = "Tema atualizado com sucesso." }/>
</cfif>
