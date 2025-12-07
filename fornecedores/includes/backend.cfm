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

<cfquery name="qFornecedoresAssessorias" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo = 'assessoria'
    order by nome_fornecedor
</cfquery>

<cfquery name="qFornecedoresCreator" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo = 'creator'
    order by nome_fornecedor
</cfquery>

<cfquery name="qFornecedoresOutros" dbtype="query">
    select * from qFornecedoresBase
    where tag_tipo <> 'org' and tag_tipo <> 'timer' and tag_tipo <> 'assessoria' and tag_tipo <> 'creator'
    order by nome_fornecedor
</cfquery>
