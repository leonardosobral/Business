# Administração do Comparador no Business — 16/10/2026

## Entrega

Implementação revisada, reconciliada e publicada. Os cinco arquivos de runtime do Business foram instalados em 17/10/2026 às01:47UTC (16/10 às22:47 em Brasília), com baseline conferido, backup recuperável, hashes finais verificados e quatro testes anônimos aprovados. Não houve commit, branch, push, edição de produto real ou criação de oferta de produção. O coordenador concluiu a inspeção autenticada somente de leitura na sessão existente do usuário no Chrome: lista de 508 produtos, edição do produto 4251, quatro abas e novo cadastro, sem erro e sem POST de produção.

A rota `/administracao/comparador/` usa o login existente (`REQUEST.businessIdentity`), `backend_login.cfm` e `require_admin.cfm`. O serviço exige administrador global efetivo, identidade do servidor e ausência de delegação. Administradores de conta, usuários comuns e administradores em conta simulada não acessam a seção. O menu aparece dentro do bloco administrativo existente.

Há lista paginada (25 por página), busca por nome/endereço/ID, filtros por tipo/estado/pendência, cadastro de todos os tipos existentes e abas de dados, características/variantes, ofertas e histórico. O catálogo continua pertencendo ao Comparador; o serviço do Business controla as alterações administrativas.

## Escrita e publicação

- Serviço `services.ComparadorAdminService.cfc`, datasource explícito `runner_dba` no banco compartilhado runnerhub. O leitor público usa seu datasource existente `comparador` (role runner).
- Todas as mutações exigem POST e token CSRF nativo do ColdFusion. Parâmetros SQL tipados; conteúdo de interface escapado. Includes internos respondem 403 quando acessados diretamente.
- Produto novo recebe estado `rascunho` na mesma transação. Ausência de linha editorial significa `publicado` legado. Publicação é explícita; arquivar oculta, sem apagar o acervo.
- Publicar ou salvar um produto já publicado exige marca e categoria válidas e compatíveis com o tipo. Para revisar um registro legado incompleto, o operador pode primeiro movê-lo para rascunho. Preço desconhecido pode ficar vazio; nunca é inventado.
- Slug usa letras minúsculas, números e hífens; `zerar` e `-vs-` são reservados. Colisão de slug verificada sob lock transacional. Alterar slug muda o endereço público; não há criação de aliases nesta entrega.
- Números aceitam ponto ou vírgula decimal, sem milhar ou notação exponencial. Preço deve ser positivo; medidas permitem zero. Características por tipo mantêm unidade; variantes M/F/U preservam desconhecido como NULL. Novos booleanos/alterações são normalizados em `true`/`false`; valores legados exatamente inalterados permanecem intactos.
- Ofertas são registros novos, com histórico preservado. URL HTTP(S) precisa satisfazer o contrato do leitor, sem credenciais, IPv6 literal ou caracteres rejeitados pelo público. A data de expiração inclui todo o dia informado em America/Sao_Paulo. O maior id_cupom é a candidata, inclusive se vencida, sem ressuscitar outra anterior.
- Lock da linha do produto, hash do estado real (produto, características, variantes, ofertas e editorial) e revisão detectam formulários obsoletos. HTTP409 omite formulários e exige recarregar. Histórico antes/depois e ID do administrador são gravados na mesma transação; falha não deixa escrita parcial.
- Upload não está disponível; mídias existentes são preservadas. Não há exclusão física de produto/característica/variante/oferta nesta interface; valor vazio expressa desconhecido quando permitido.

## Estado operacional na reconciliação

A primeira tentativa via ColdFusion foi bloqueada pelas opções DDL da conexão e não alterou o banco. O coordenador concluiu a migração pelo DataGrip nativo, usando a conexão RunnerHub já configurada e a role runner_dba. A verificação independente pelo ColdFusion confirmou508produtos e hash `b7da581cbd6bb2f86d7ba98de802922c` iguais antes/depois, tabelas editorial/auditoria vazias, leitura de508produtos pela view com role runner e ausência de INSERT dessa role nas tabelas novas. O contador foi realinhado com RESTART4252.

O leitor público T6 foi publicado em três templates, com23/23smokes aprovados e backup `/root/codex-backups/comparador/20261017T014342Z-t6` (confirmação do coordenador). Em seguida, o Business publicou exatamente os cinco arquivos do manifesto; backup `/var/backups/business-comparador-admin-20261016/20261017T014659Z-3a4a2992`. Recibo local: `2026-10-16_comparador_publicacao.json`.

Os smokes Business confirmaram página administrativa anônima302para `/`, backend/view diretos403 e recusa de método não remoto do CFC500. A mensagem confirmou: `The method 'offerUrl' ... cannot be accessed remotely.` Não houve execução da função nem leitura de catálogo por esse teste. Nenhum SQL, harness, fixture ou suporte de autenticação foi publicado no webroot. O uso do harness/túneis privados terminou e o navegador sintético foi fechado; o coordenador pode limpar os recursos temporários desta tarefa.

## Migração e contrato público

`_codex/sql/2026-10-16_comparador_admin.sql` adiciona `comparador.tb_produto_editorial`, `comparador.tb_admin_auditoria`, índice do histórico e `comparador.vw_produto_publico`:

```sql
SELECT p.* FROM comparador.tb_produto p
WHERE NOT EXISTS (
  SELECT 1 FROM comparador.tb_produto_editorial e
  WHERE e.id_produto=p.id_produto AND e.estado<>'publicado'
)
```

Executar via conexão existente `runner_dba`. Na produção, o coordenador concedeu apenas `SELECT ON comparador.vw_produto_publico TO runner`; o SQL portátil de teste não pressupõe essa role. As tabelas novas não precisam ser expostas à role pública.

Preflight do coordenador encontrou sequência de produtos em 56 e maior ID4251. O coordenador realinhou o contador sob lock com RESTART4252, sem alterar produtos nem reduzir a sequência. Características já estavam alinhadas e ofertas vazias.

Ordem executada: backup e baseline → migração aditiva + SELECT da view + realinhamento de sequência → leitor público consumindo view em todas as consultas/opções/seleções → cinco arquivos de runtime do Business → verificação pública e bloqueio administrativo anônimo.

Rollback de runtime deve preservar tabelas, view, dados e auditoria. Depois do primeiro rascunho/arquivo, não restaurar um leitor que consulte diretamente `tb_produto` sem filtrar o estado, pois isso exporia produtos ocultos. A nova seção pode ser retirada do menu e seu runtime revertido sem remover schema. A migração foi validada transacionalmente em um schema descartável no banco de teste: instalada dentro da transação e inteiramente ausente após ROLLBACK.

## Publicador e rollback

`_codex/scripts/deploy_comparador_admin.py` publica exclusivamente os cinco caminhos revisados, validando o manifesto local e baseline remoto. Cria backup privado, troca arquivos atomicamente (includes antes do index, menu por último), verifica todos os hashes e executa os quatro smokes anônimos. Falha dispara rollback; rollback recusa sobrescrever arquivo alterado depois da publicação. Cinco testes em diretórios descartáveis cobrem publicação, backup, rollback, conflito de baseline, preservação de alteração posterior e interrupção após troca de arquivo.

O QA real encontrou um link inválido no produto legado 4251, sem slug/categoria. O patch publicado em seguida altera somente `administracao/comparador/home.cfm`: o link exige estado publicado, endereço aceito pelo roteador e tipo/marca/categoria válidos; cadastros incompletos recebem uma orientação breve. O href usa os dados efetivamente salvos. Nenhum dado foi corrigido automaticamente.

Quatro regressões HTTP reais passaram: slug vazio, categoria ausente e marca ausente ocultam o link; um produto completo publicado mantém seu endereço. O patch confirmou o hash previamente publicado, guardou backup em `/var/backups/business-comparador-admin-link-20261016/20261017T015348Z-5ab71eb5` e passou nos quatro smokes anônimos. Os cinco hashes do conjunto integrado foram conferidos contra o manifesto. Evidências: `2026-10-16_comparador_public_link_evidence.json` e `2026-10-16_comparador_public_link_publicacao.json`.

Para conferir o patch atual:

```sh
python3 _codex/scripts/deploy_comparador_public_link.py verify --release 20261017T015348Z-5ab71eb5
```

Para rollback do Business, somente se operacionalmente necessário, reverta primeiro o patch e depois o lote inicial. A conferência do lote inicial isolado recusa o novo hash de home.cfm enquanto o patch estiver presente:

```sh
python3 _codex/scripts/deploy_comparador_public_link.py rollback --release 20261017T015348Z-5ab71eb5
python3 _codex/scripts/deploy_comparador_admin.py rollback --release 20261017T014659Z-3a4a2992
```

O rollback do Business preserva o banco e o leitor T6, que deve continuar filtrando estados editoriais.

## Verificação executada

- Adobe ColdFusion2025 real, PostgreSQL16.15 exclusivo `comparador_codex_test` por túnel privado. Produção é PG17.6; SQL usado é compatível com ambos.
- 45 asserções reais do serviço, zero falhas: autorização, POST/CSRF, decimal, URL, criação rascunho, NULL, publicação, auditoria, slug, vínculos, conflito, alteração externa, rollback parcial, variantes, oferta e booleanos. Evidência em `2026-10-16_comparador_service_evidence.json`.
- 29 cenários HTTP, zero falhas: login/sessão/admin reais, anônimo, cookie legado forjado, comum, conta admin, delegado, simulado, acesso direto a includes, páginas/abas/filtros/paginação, CSRF inválido, GET sem mutação, escape e POST completo de cadastro/publicação/características/oferta/histórico. Evidência em `2026-10-16_comparador_http_evidence.json`.
- Testes antes da implementação e regressões RED/GREEN: serviço ausente; booleano não canônico; slug reservado; URL fora do contrato; perda de marca em publicado.
- Playwright visual com MDB real: cadastro desktop1440px e mobile390px; formulário legível, sem sobreposição ou rolagem horizontal global (scrollWidth390). Capturas em `output/playwright/comparador-20261016/`. O harness usa cabeçalho/rodapé mínimos. O coordenador também validou o cadastro real autenticado em 390px, com a navegação global após sua animação: documento de 390px, sem rolagem horizontal, e captura legível; o viewport foi restaurado.

Os testes usam apenas dados sintéticos. Harness e cópias de dependências de autenticação são auxiliares, fora do manifesto de runtime. O único arquivo existente alterado é sidenav.cfm; hash baseline local/produção `4342580dca5cb9311c9507ba8542db2c5ceac14d2f639ba0ceec22f2f7b64a0e`. Os demais quatro arquivos de runtime não existiam na produção no preflight.

O Business não tem comando central de suíte documentado no README. Foram executados testes focados reais da área e seus gates; suítes de outros módulos não foram executadas. As pendências editoriais do acervo real e envio seguro de imagens permanecem fora desta publicação.
