<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qFornecedoresBase">
    SELECT * from tb_fornecedores
</cfquery>

<cfquery name="qFornecedoresOrg" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo = 'org'
    order by nome_fornecedor
</cfquery>

<cfquery name="qFornecedoresTimer" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo = 'timer'
    order by nome_fornecedor
</cfquery>

<cfquery name="qEventosAdsOutros" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo <> 'org' and tag_tipo <> 'timer'
    order by nome_fornecedor
</cfquery>
