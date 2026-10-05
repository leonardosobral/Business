component output=false hint='Read-only Runner Apps catalog contract owned by Business.' {
    public any function init(string datasource='runner_dba', string schema='public') {
        if (!reFind('^[a-z][a-z0-9_]*$',arguments.schema)) throw(type='RunnerApps.InvalidSchema');
        variables.datasource=arguments.datasource;
        variables.schema=arguments.schema;
        return this;
    }

    public struct function read(string line='') {
        if (len(arguments.line) && arguments.line NEQ 'principal') throw(type='RunnerApps.InvalidLine');
        var rows=queryExecute(
            'SELECT grp.id_group, grp.nome AS grupo_nome, grp.descricao AS grupo_descricao,
             grp.ordem AS grupo_ordem, grp.itens_por_linha AS grupo_itens_por_linha,
             app.id_app, app.nome, app.url, app.imagem_url, app.alt_text,
             app.abrir_nova_aba, app.rel, app.ordem
             FROM ' & variables.schema & '.tb_portal_runner_app_groups grp
             LEFT JOIN ' & variables.schema & '.tb_portal_runner_apps app
                 ON app.id_group=grp.id_group AND app.ativo=true
             WHERE grp.ativo=true' & (arguments.line EQ 'principal' ? ' AND grp.id_group=1' : '') & '
             ORDER BY grp.ordem, grp.id_group, app.ordem NULLS LAST, app.id_app',
            {},{datasource=variables.datasource,timeout=3});
        var groups=[];var items=[];var positions={};
        for (var row in rows) {
            var groupKey=row.id_group & '';
            if (!structKeyExists(positions,groupKey)) {
                arrayAppend(groups,{
                    'id'=row.id_group,'name'=row.grupo_nome,'description'=row.grupo_descricao,
                    'order'=row.grupo_ordem,'itemsPerRow'=row.grupo_itens_por_linha,'active'=true,'items'=[]
                });
                positions[groupKey]=arrayLen(groups);
            }
            if (len(trim(row.id_app & ''))) {
                var item={
                    'id'=row.id_app,'groupId'=row.id_group,'groupName'=row.grupo_nome,
                    'name'=row.nome,'href'=row.url,'target'=row.abrir_nova_aba ? '_blank' : '',
                    'rel'=trim(row.rel),'imgSrc'=assetUrl(row.imagem_url),
                    'imgAlt'=len(trim(row.alt_text)) ? row.alt_text : row.nome,
                    'label'=row.nome,'labelHtml'=row.nome,'order'=row.ordem,'active'=true
                };
                arrayAppend(groups[positions[groupKey]].items,item);arrayAppend(items,item);
            }
        }
        return {'success'=true,'status'='ok','groups'=groups,'items'=items,
            'poweredBy'={'label'='powered by','href'='https://runnerhub.run/','name'='RunnerHub'}};
    }

    private string function assetUrl(required string path) {
        var value=trim(arguments.path);
        if (!len(value) || reFindNoCase('^(https?:)?//',value) || left(value,5) EQ 'data:') return value;
        return 'https://business.roadrunners.run' & (left(value,1) EQ '/' ? '' : '/') & value;
    }
}
