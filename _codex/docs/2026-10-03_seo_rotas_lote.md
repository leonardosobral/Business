# SEO — lote de rotas públicas, 03/10/2026

Pedido: prosseguir com o plano SEO e SEO para IA. Primeiro lote: RR-01 (eventos com caracteres especiais) e RR-05 (notícia histórica com 404).

## Responsabilidades e limites

- RoadRunners mantém as rotas e os metadados públicos dos eventos e notícias.
- Business mantém a posição curada da fila, sem apresentar esta rechecagem focal como uma nova auditoria completa.
- Investigar o cadastro e as camadas HTTP antes de corrigir. Não reduzir proteções, inventar conteúdo equivalente, mudar silenciosamente identificadores ou incluir alterações de outras frentes.
- Preparação isolada em `_codex/staging/seo-routes-20261003/`, a partir do runtime de produção. A preferência do usuário proíbe operações Git sem solicitação; não criar worktree/branch/commit.

## Etapas e aceite

1. Reproduzir os quatro casos de eventos e a notícia, conferir cadastro, rotas, logs e baseline de produção.
2. Corrigir somente a causa comprovada. Testar caracteres especiais e variantes de idioma; preservar a identidade dos eventos e explicitar compatibilidade quando necessária.
3. Conferir o conteúdo da notícia e referências. Só usar redirecionamento permanente se houver equivalência comprovada.
4. Atualizar a fila com evidências datadas, preservando contagens da auditoria de 29/09.
5. Validar, fazer revisão independente, preparar backup recuperável, publicar o escopo restrito e conferir URLs e hashes reais.

## Registro de execução

- Iniciado: estados Git de Business e RoadRunners consultados; alterações de outras frentes preservadas.
- Fontes: fila `portal/includes/seo_queue_data.cfm`, plano de 13/09 e plano SEO para IA de 29/09.
- Diagnóstico em andamento; nenhuma correção de runtime publicada nesta etapa.

- Diagnóstico: quatro tags confirmadas no cadastro; erro Apache AH10411 e truncamento em # reproduzidos na origem e no domínio público.
- Teste RED/GREEN: Apache real, 27 combinações de tag/idioma e quatro caminhos protegidos; baseline com 21 falhas, candidato com dois testes aprovados.
- Business: quatro cenários CFML aprovados (contrato de filtros, resoluções e renderização). Números, scores e datas de auditoria de 29/09 preservados.
- RR-05: CMS id 2380, rejeitado e não publicado; zero referências no corpo/resumo de conteúdo publicado. Nenhuma alteração editorial ou redirect.
- Revisão Astra: sem Critical/Important no código; publicação da fila condicionada a HTTP/identidade/canonical em 12 casos e ausência da notícia no sitemap.
- Ruling: rótulo do link 403 seria incoerente com o estado resolvido; atualizado para identificar o caso rechecado. A nota é editorial e a renderização não teve comportamento alterado.
- Ruling: o CGI de teste cobre o rewrite, não substitui o conector CFML. A versão Apache 2.4.52 e os metadados reais serão verificados na produção após publicar as duas regras de rota, antes de publicar a fila.

- Verificação real após as regras de rota: 12/12 páginas HTTP 200 e identidade correta; canonical/alternates ainda incorretos, por interpolação literal em `REQUEST.currentRouteParams`. A fila não foi publicada nesse estado.
- Fix: codificar `currentRouteParams.tag` no template de evento, preservando `URL.tag` para consulta e as demais diferenças locais/produção. Nenhuma alteração no Application.cfc.
- RED de metadados: teste CFML com o builder real falhou por controles na URL. O primeiro GREEN ficou impedido pela configuração ESAPI do runtime local; resolvido isolando `java.io.tmpdir` no diretório de teste.
- Ruling: a conversão para minúsculas do builder é preexistente; o teste de escapes literais usa tags normalizadas em minúsculas e não amplia esta tarefa para alterar esse contrato global.
- Compilação Adobe: template de evento e versão final da fila aprovados (um arquivo em cada compilação), antes da publicação.


## Resultado publicado

Lote concluído em 03/10/2026. RoadRunners: `.htaccess`, `evento/.htaccess` e somente a preparação dos parâmetros de URL em `evento/index.cfm`. Business: `portal/includes/seo_queue_data.cfm`. Publicações feitas a partir de produção; os diffs locais de organizador/header e inscrições foram preservados e não republicados como parte deste lote.

- 12/12 páginas reais: HTTP 200, identidade correta, canonical equivalente à URL e alternates dos três idiomas; JSON-LD analisável. Conferência pública às 17:23:39 UTC.
- Quatro caminhos sensíveis mantêm HTTP 403.
- Notícia rejeitada mantém 404 e está ausente do sitemap editorial válido.
- Teste Apache final: 66 combinações de tag/idioma/barra, incluindo escapes literais, e quatro caminhos protegidos; três testes aprovados.
- Teste CFML de metadados: 24 combinações de idioma/tag, builder real e identificador bruto preservado para consulta.
- Business: quatro cenários CFML locais aprovados e duas versões da fila compiladas no Adobe; versão final do evento compilada no Adobe.
- Após publicação, renderização Adobe dos includes reais do painel em fixture temporária GET, isolada e restrita a loopback, confirmou 11 itens, 8 concluídos e 3 pendentes. Essa fixture não testa a sessão autenticada do usuário.
- Hashes dos quatro arquivos publicados conferidos; seis arquivos de outras frentes monitorados permaneceram inalterados. `git diff --check` nos arquivos do escopo aprovado nos dois projetos. Nenhuma operação Git de criação realizada.

O painel mantém as métricas e notas da auditoria completa de 29/09. Esta entrega é uma rechecagem focal, não uma nova auditoria global. Restam SH-01 (hierarquia de títulos), OR-02 (política robots) e SH-02 (completude factual); acompanhamento automático, traduções/hreflang e medição de IA continuam no plano.

### Recuperação

Backups: `/var/backups/seo-routes-rr-20261003/baseline`, `/var/backups/seo-routes-rr-metadata-20261003/baseline` e `/var/backups/seo-routes-business-20261003/baseline`. Manifestos preservam hashes anteriores e publicados. O operador `release.py rollback` confere mudanças concorrentes antes de restaurar; não é autorização para executar rollback futuro. Nenhum dado de banco foi modificado.

Evidências consolidadas: `_codex/docs/2026-10-03_seo_rotas_release.json`. Rulings: a publicação não incluiu diferenças locais alheias; a codificação preserva a política existente de minúsculas do builder; o rótulo histórico de 403 foi corrigido para evitar incoerência com o estado resolvido. A validação operacional final cobre os pontos deixados fora da revisão Astra (conector CFML, Apache de produção, metadados e sitemap). Não restam ressalvas menores abertas da revisão deste lote.
