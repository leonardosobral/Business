# Lote de SEO: reciprocidade entre idiomas e nova auditoria

Escopo autorizado: continuar o plano de SEO e SEO para IA, publicar runtime do Business após validação. Preservar outras frentes, dados pessoais e políticas de treinamento.

1. Acrescentar um check informativo de reciprocidade hreflang no relatório para IA. Usar somente observações da mesma auditoria; nenhum request adicional. Destino fora da amostra fica não medido. Destino inspecionado com falha, redirecionamento, canonical diferente ou conjunto de idiomas divergente pede atenção. Sem alternates ou com apenas a própria página, não há evidência de reciprocidade.
2. Incluir os conjuntos de home, busca, evento e notícia nos três idiomas nas URLs estratégicas do Road Runners. Rodar as duas auditorias com o orçamento existente: 100 páginas por site, 1 request/s, concorrência 2, timeout 15 s e descoberta limitada. Guardar relatórios privados.
3. Gerar o snapshot técnico e para IA; atualizar datas, contagens e evidências da fila. Separar tradução de reciprocidade, sem inferir tradução a partir dos metadados. Preservar histórico técnico e sinalizar amostra diferente.
4. Validar testes Node e renderização CFML; uma revisão final Astra do lote. Conferir baseline de produção, preparar backup recuperável, compilar e publicar somente snapshots e a view para IA se alterada. Verificar runtime e a renderização real no servidor.

Referência: [Google — versões localizadas](https://developers.google.com/search/docs/specialty/international/localized-versions), consultada em 03/10/2026. O conjunto de alternates deve listar a própria página e as demais versões; os links devem ser bidirecionais. Este check não valida a tradução, a identificação automática do idioma pelo Google ou indexação.

Ruling: trabalhar em staging próprio, sem branch ou commit — a instrução do repositório exige solicitação específica para essas operações e o checkout contém alterações de outras frentes.

Ruling: a pontuação técnica e seus pesos permanecem iguais — reciprocidade e tradução são informações adicionais, sem equivalência com chance de citação por IA.

Ruling: permitir conjuntos entre domínios na análise, mas não buscar destinos adicionais — hreflang aceita outros domínios; fora da amostra, o resultado permanece não medido.

Pre-flight: o coletor já fornece hreflang e canonical. A nova avaliação consome esse contrato sem mudar coleta, regras ou orçamento. Os snapshots são consumidos pela view genérica existente.

## Ledger

- Task 1: complete — 10 testes de idioma, precedidos por falhas observadas; primeira suíte integrada com 50 testes aprovada.
- Task 2: complete — auditorias de 03/10/2026, 100 páginas por site; descoberta completa de 103.049 e 34.321 URLs.
- Task 3: complete — snapshots datados, exemplos priorizados e fila com 14 itens (10 concluídos, 4 pendentes).
- Task 4: complete — revisão Astra, correções de proteção com RED→GREEN, 53 testes Node, 9 cenários CFML, compilação Adobe e três hashes de runtime confirmados; painel Adobe e prévia desktop/celular verificados.

Ruling: a auditoria revelou ausência de hreflang na busca em português — incluir uma linha que identifica a rota no próprio template, sem alterar Application.cfc. O baseline de produção difere do checkout; preservar cada versão e aplicar somente essa linha. Teste CFML falhou com 0 alternates em português antes da correção. Repetir auditoria Road Runners após publicação para datar o snapshot corretamente.

Ruling: no check novo, comparar escapes percentuais sem distinguir maiúsculas/minúsculas, sem decodificar segmentos — %3F e %3f representam o mesmo caractere; preservar diferenças reais de caminho. A regra e a nota técnicas legadas continuam com sua semântica atual.

Revisão final: nenhum Critical. Important (watch antes de publish) e Minor (resultado da busca no próprio run) corrigidos e testados. Exemplos priorizam avisos; fila registra novas pendências institucionais e editoriais. Evidências completas em `2026-10-03_seo_idiomas.md`.
