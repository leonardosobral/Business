component output=false {
    public struct function translate(required string source, required string language, required string apiKey, string model='gpt-4.1-mini') {
        REQUEST.fixtureProviderCalls++;
        if (REQUEST.fixtureProviderMode EQ 'reject' OR (REQUEST.fixtureProviderMode EQ 'reject-en' AND arguments.language EQ 'en')) throw(type='EventDescriptionRewrite.Validation', message='Fixture translation rejected');
        if (REQUEST.fixtureProviderMode EQ 'provider-error') throw(type='EventDescriptionRewrite.Provider', message='DO_NOT_EXPOSE_PROVIDER_SECRET');
        if (REQUEST.fixtureProviderMode EQ 'unexpected-error') throw(type='FixtureUnexpected', message='DO_NOT_EXPOSE_SOURCE_OR_SQL');
        if (REQUEST.fixtureProviderMode EQ 'changed-source') {
            queryExecute("UPDATE public.tb_evento_corridas SET descricao = descricao || ' Fonte alterada.' WHERE id_evento=1", [], {datasource='runner_dba'});
        }
        if (REQUEST.fixtureProviderMode EQ 'manual-description') {
            queryExecute("UPDATE public.tb_evento_corridas SET descricao_en = 'Tradução manual.' WHERE id_evento=1", [], {datasource='runner_dba'});
        }
        if (REQUEST.fixtureProviderMode EQ 'null-to-empty') {
            queryExecute("UPDATE public.tb_evento_corridas SET descricao_en = '' WHERE id_evento=1", [], {datasource='runner_dba'});
        }
        var output = arguments.language & ' translation ' & lCase(hash(arguments.source, 'MD5', 'UTF-8'));
        return {text=output, html=output, model=arguments.model, language=arguments.language};
    }
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
