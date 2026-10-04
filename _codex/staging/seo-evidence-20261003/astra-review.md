# Revisão Astra — lote de evidências

Important: seo_live_evidence.py não respeitava lang divergente em descendentes da descrição. Caso reproduzido: divlang=en contendo divlang=pt-BR com conteúdo português podia receberpass se o hash fosse diferente da fonte. Registrar conflito e manter inconclusivo.

Nenhum outro Critical/Important. Snapshots coerentes, notas técnicas preservadas, logs sem host inconclusivos, referências não viram citações/conversões, OR-02 separa entrega de desindexação. Publicação limitada a três arquivos e cinco dependências.

Limites: revisão somente leitura com reprodução local; publicação e verificação real pertencem ao executor.

Correção do executor: testePython de conflito visível e fonte ambígua RED (campo inexistente), testeNode RED (aprovava e aceitaria metadados antigos). Agora o parser registra description_lang_conflict e tradutorclassifica unknown na fonte ou destino; ocultos e mesmo idioma não conflitam. Node exige o campo booleano, rejeitando evidência antiga sem essa checagem. Suíte completa67Node e10Python verde. Nova coleta da mesmaamostra requerida antes da geração e publicação; sem segunda revisão, conforme skill.
