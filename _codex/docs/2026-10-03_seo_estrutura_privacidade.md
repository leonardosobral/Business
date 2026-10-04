# SEO — títulos, organização e históricos individuais

Lote de 03/10/2026, continuando o plano SEO e preparação para IA.

## Resultado técnico

- Road Runners: a home mantém seu H1; a busca tem título principal localizado em PT/EN/ES. O slogan promocional do hero compartilhado é parágrafo nas páginas internas, preservando fonte e peso. Os títulos reais dos eventos e notícias mantêm o papel principal.
- OpenResults: a introdução da home passa a H1 com a mesma tipografia de 16 px, peso 400 e altura de linha de 25,6 px. Apresentação conferida no desktop e celular.
- Road Runners publicado: o organizador passa a exigir papel `id_fornecedor_tipo=1` na relação com o evento. Cronometragem não é promovida a organização. O checkout já tinha essa seleção; o candidato foi montado a partir da produção para preservar diferenças de outras frentes.
- OpenResults: histórico pessoal `/resultados/` recebe `noindex, follow` no head. As demais páginas não recebem essa instrução. O robots permite ler `/resultados`; `/perfil` permanece bloqueado nos dois grupos, e `/nogooglebot/` permanece no Googlebot. A tag foi publicada e conferida antes de alterar robots.

## Decisão de privacidade

O responsável explicou que páginas `/resultados/nome_da_pessoa/` provocavam pedidos de remoção de nomes, apesar da origem pública dos resultados. Depois de esclarecer o alcance do robots, autorizou explicitamente seguir com noindex. A estratégia preserva a indexação das páginas de provas e evita indexação do histórico pessoal nos buscadores que respeitam essa regra.

Google precisa acessar a página para ler noindex. Bloquear o caminho no robots pode impedir essa leitura e não garante a retirada da própria URL. A implementação não remove nomes dos resultados das provas, não elimina dados e não comprova desindexação já efetivada. Pedidos individuais precisam de atendimento separado; para urgências, Remoções do Search Console é complemento temporário à regra permanente.

Referências: [Google — noindex](https://developers.google.com/search/docs/crawling-indexing/block-indexing), [limites do robots](https://developers.google.com/search/docs/crawling-indexing/robots/intro).

No código de `/perfil`, o destino já é Road Runners. Conferência com agente identificado retornou HTTP 302 para esse destino. A consulta anterior com agente genérico recebeu 403; esse resultado isolado não foi tratado como ausência da rota. Nenhuma mudança de autenticação ou perfil foi realizada.

## Verificação

- CFML real: 12 combinações de hero/template/idioma; seleção de organizador; 15 casos de disponibilidade; 7 casos de noindex por template. Os testes de regressão falharam contra os respectivos baselines e passaram contra os candidatos.
- Adobe: compilação dos templates de runtime antes de publicar; marcador persistido vincula compilação ao manifest. Revisão independente Astra não encontrou Critical/Important nos candidatos finais.
- HTML público: 13 páginas com título principal correto; 4 páginas de eventos nos dois sites conferiram presença de organizador cadastrado e ausência quando há somente cronometragem. Noindex conferido na rota pessoal e no acesso direto ao template, sem afetar home/evento.
- Sitemaps OpenResults: quatro lotes válidos, 34.321 URLs, nenhum histórico pessoal ou perfil. Essa descoberta focal não substitui a auditoria de 100 páginas de 29/09.
- Robots: 60 casos do interpretador local. Esse teste mede política declarada e não prova visita de bot real, nem aplicação de noindex pelo índice Google.
- Business: quatro cenários CFML do contrato, estados resolvidos e renderização com filtros. A verificação final do painel usa fixture GET isolada e restrita ao loopback, não uma sessão real do administrador.

## Pendências e limites

O cadastro compartilhado tem 34.320 eventos ativos, dos quais 1.332 possuem vínculo de organização com nome preenchido. Esse total é do banco em 03/10, não uma inspeção de todas as páginas. SH-02 permanece aberto: completar fatos, fonte, edição, unidade, cancelamento e traduções somente com evidência. Não foi feita escrita no cadastro.

As notas e amostras gerais mantêm data de 29/09; a fila registra correções focais e sua data, sem recalcular pontuação a partir de alguns casos. Preparação para IA segue exigindo fatos coerentes e identificação de visitas reais; noindex aqui se refere à indexação dos históricos por buscadores.

## Publicação e recuperação

Somente arquivos do escopo, substituição atômica, baseline e hashes, com preservação de arquivos monitorados. Sem commit, branch, push ou PR.

- `/var/backups/seo-structure-roadrunners-20261003/baseline`: hero e evento.
- `/var/backups/seo-structure-openresults-20261003/baseline`: home e robots da etapa inicial.
- `/var/backups/seo-noindex-openresults-20261003/baseline`: head e robots antes da decisão noindex.
- `/var/backups/seo-structure-business-20261003/baseline`: snapshot curado da fila.

Manifestos e evidências locais ficam nos diretórios `_codex/staging/seo-structure-20261003` e `_codex/staging/seo-privacy-20261003`. Runtime e documentação locais preservam mudanças preexistentes; as versões publicadas foram derivadas dos baselines remotos.

**Estado da borda:** o head com noindex foi confirmado publicamente. Na última conferência, a Cloudflare ainda servia a versão anterior de `/robots.txt` em cache (`HIT`, TTL 3600 s); o painel já foi publicado e conferido com 9 itens concluídos e 2 pendentes, mantendo OR-02 aberto até essa entrega corresponder à política nova. Não considerar este ponto concluído pelo hash da origem.
