component output=false {
    public struct function rewrite(required string source, required string apiKey, string model='gpt-4.1-mini') {
        REQUEST.fixtureProviderCalls++;
        if (REQUEST.fixtureProviderMode EQ 'reject') throw(type='EventDescriptionRewrite.Validation', message='Fixture source rejected');
        if (REQUEST.fixtureProviderMode EQ 'provider-error') throw(type='EventDescriptionRewrite.Provider', message='DO_NOT_EXPOSE_PROVIDER_SECRET');
        if (REQUEST.fixtureProviderMode EQ 'unexpected-error') throw(type='FixtureUnexpected', message='DO_NOT_EXPOSE_SOURCE_OR_SQL');
        if (REQUEST.fixtureProviderMode EQ 'changed-source') {
            queryExecute("UPDATE public.tb_evento_corridas SET descricao_original = descricao_original || ' Fonte alterada.' WHERE id_evento=1", [], {datasource='runner_dba'});
        }
        if (REQUEST.fixtureProviderMode EQ 'manual-description') {
            queryExecute("UPDATE public.tb_evento_corridas SET descricao = 'Descrição manual.' WHERE id_evento=1", [], {datasource='runner_dba'});
        }
        return {text='Corrida de 5 km, largada às 07:00.', html='<p>Corrida de 5 km, largada às 07:00.</p>', model=arguments.model};
    }
}
