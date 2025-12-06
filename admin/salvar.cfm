<cfparam default="" name="FORM.marca"/>
<cfparam default="" name="FORM.modelo"/>
<cfparam default="" name="FORM.versao"/>
<cfparam default="1" name="FORM.num_versao"/>
<cfparam default="" name="FORM.genero"/>
<cfparam default="" name="FORM.categoria"/>
<cfparam default="0" name="FORM.nivel_amortecimento"/>
<cfparam default="0" name="FORM.tamanho_drop"/>
<cfparam default="0" name="FORM.peso"/>
<cfparam default="0" name="FORM.peso_tamanho"/>
<cfparam default="" name="FORM.entresola"/>
<cfparam default="" name="FORM.sistema"/>
<cfparam default="" name="FORM.indicacao"/>
<cfparam default="" name="FORM.tipo_tamanho"/>
<cfparam default="false" name="FORM.placa"/>
<cfparam default="" name="FORM.placa_material"/>
<cfparam default="" name="FORM.obs"/>
<cfparam default="" name="FORM.imagem"/>
<cfparam default="" name="FORM.cabedal"/>

<cfquery>
insert into tb_tenis
(
    marca, modelo, versao, num_versao,
    categoria, nivel_amortecimento, tamanho_drop, entresola,
    sistema, indicacao, tipo_tamanho, placa, placa_material, obs, imagem,
    cabedal
)
values
(
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.marca#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.modelo#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.versao#"/>,
    <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.num_versao#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.categoria#"/>,
    <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.nivel_amortecimento#"/>,
    <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.tamanho_drop#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.entresola#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.sistema#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.indicacao#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_tamanho#"/>,
    <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.placa#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.placa_material#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.imagem#"/>,
    <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.cabedal#"/>
)
</cfquery>

<cflocation url="./" addtoken="false"/>
