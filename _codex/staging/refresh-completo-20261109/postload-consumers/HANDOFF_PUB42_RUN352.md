# Handoff real — consumidores42/352 e corte DataGrip

Preparado e verificado em 09/11/2026, sem deploy nem execução do corte.

## IDs e estado real

| Origem | Alvo aprovado |
|---|---|
| Publicação privada imutável | 42, saída251 rev42/run351, contrato18 |
| Narrativa pública | célula420 rev7/run352 |
| Pareamento | célula387 rev3/run329; 615 pares |
| Anual interno | célula418 rev3/run353, último válido |

Hash PostgreSQL `jsonb::text` da publicação42, igual ao recibo privado e à saída do
validador18:
`a04b8ac9649bb5a230c0c3e36b07fcd5be75add96a474d0aa842632f19d45a85`.
Leitura real confirmou **0 referências ativas à publicação42**; destinos/produto
e view continuam no estado antigo. A publicação privada isolada não é resolvida
pelos consumidores ativos e não avançou ponteiros. O anual353 já é visível ao
rascunho interno por seu contrato de último congelamento; isso não ativa o produto.

`target-evidence.json` e `target-snapshot.json` registram as leituras reais. Os
27 hashes de produção/local foram reconferidos nessa captura e permaneceram iguais
ao baseline preservado. Revalidar novamente antes de qualquer transferência.

## Runtime compatível pronto para compilação do controlador

Pasta:
`candidates-42-352/compatible/candidate/`.

Allowlist dos oito arquivos em `compatible/manifest.json`:

- Business `estudos/includes/StudyAccess.cfc`;
- Business `estudos/leitor/{parcial.js,index.cfm}`;
- Business `estudo/anual/index.cfm`;
- Portal `brasilquecorreprovas/imprensa/principal/{index.cfm,dados.cfm,parcial-2026.js,estudo-2026.css}`.

SQL do CFC admite exatamente **41→239/rev5** e **42→352/rev7** com junção pela
publicação. Não há cruzamento entre narrativas, nem mudança de métricas/auth/fallback.
Ambas as guardas de fonte congelada e conciliação de taxa são mantidas. As cópias
de imprensa vêm da projeção e dos assets canônicos compatíveis. O anual continua
latest-frozen; só muda versão de cache de apresentação.

Não transferir os sete arquivos de suporte de validação listados como
`validation_only_files`. Gates/perfil/menu/filtro são suporte ao hold Teams e não
alterações autorizadas de runtime. Transferências RR exigem a `.rsync-filter` raiz
(`-F`) e allowlist delimitada. Hold passou no checkout e no candidato final.

## Arquivo SQL DataGrip final

Arquivo revisável: **`CORTE_FINAL_PUB42_RUN352.sql`**, 7.994 bytes.

SHA256:
`ca65e36836a8292823862f6de36632b5703cf118d59d8717363b8e5af845dd8f`.

Uma transação executará, somente quando autorizada/aplicada no DataGrip:

1. Lock/guard dos destinos2025/2026; 2026 precisa continuar em publicação41,
   célula251, versão22. 2025 precisa permanecer37/célula249/versão19.
2. Guard do produto1/publicação41, contrato17 anterior, definição/hash e barreira
   da view; publicação42 tem de continuar sem referências ativas.
3. Guard de runs congelados, revisões, hashes, contrato18, validação da saída351,
   fonte387/329 declarada na publicação, janela e taxas2,2/38,7 conciliadas,
   seis indicadores públicos limitados e anual353 mais recente.
4. `web_destinos2026`: **41/vers22 → 42/vers23**, exatamente uma linha.
5. ProdutoQ3: **41 → 42**, exatamente uma linha.
6. View pública: **run239 → run352/rev7**, preservando `security_barrier=true`.
7. Pós-check de destino2026/produto/view e destino2025 inalterado; COMMIT.

Não usa `publicar_web` nesse momento: a função avançaria o destino técnico fora
do corte coordenado. A publicação42 já está registrada privadamente e validada;
a transação final reponta os três consumidores juntos. Não executa recarga BI,
mudança de permissões/roles/owner, edição de runs nem produto anual.

O datasource tem DML permitido e DDL bloqueado na configuração registrada;
privilégios PostgreSQL do owner não eliminam esse bloqueio. Executar pelo canal
DataGrip/DBA, sem contornar ou ampliar acessos da aplicação.

**O arquivo de corte não foi executado.** Somente os predicados SELECT das guardas
foram extraídos e consultados em transação READ ONLY:
`delivery-qa/atomic-preflight.readonly.sql` / `atomic-preflight.json`. Resultado:
contrato/taxas=true, destinos antigos=true, contrato18=true, view antiga=true,
referências ativas42=0. Uma precedência de operadores JSONB foi corrigida nessa
prova antes da entrega; os artefatos finais acima contêm as expressões
parentesizadas. O bloco DO/UPDATE/CREATE/COMMIT nunca foi submetido nesta subtarefa.

## QA real do leitor sem identidade forjada

SQLs `delivery-qa/compatible-publication-41.sql` e `-42.sql` substituem somente
a relação `authorized` por uma relação virtual de QA com `w.id` explícito. Não
alteram produto/destino e não criam `REQUEST.businessIdentity` ou sessão de usuário.
Foram executados em transação READ ONLY. O JSON retornou em base64 para preservar
bytes/números do PostgreSQL durante o transporte CF/Python.

Resultados em `delivery-qa/vm-verification.json`:

- publicação41: fonte231/narrativa239, 608 pares, 37 páginas; render idêntico ao
  renderer atual, preservando o estado antigo durante a transição;
- publicação42: fonte329/narrativa352, **615 pares**, 37 páginas, **+2,2% / +38,7%**;
- CSV mantém **`2.220995142779458018777672200`** sem arredondar;
- 13 casos ausentes/inválidos mantêm calendário38,7% legível e pareado em revisão,
  `??`, sem transformar falta de fonte em zero;
- vínculo SQL de cada publicação à narrativa correspondente conferido;
- oito testes dos helpers passaram; checks sintáticos Node e Teams aprovados.

Compilação CFML e HTTP real autenticado/público do pacote ainda ficam com o
controlador antes/depois da publicação. Não se afirmou validação visual nova do
leitor em browser nesta subtarefa.

## Kit real e central

`../postload-media/candidate/portal/brasilquecorreprovas/2026/kit/` contém os
**17 arquivos**. `../postload-media/verification.json` e manifesto de QA registram
hashes17/17, links, dimensões, PDF7 páginas, dez artes e dois aliases. PDF e cinco
portraits foram inspecionados, sem cortes/sobreposição. Fonte: run352/pub42/run351,
coleta09/11, lançamento13/11. Status `reviewed` significa revisado e ainda não
publicado; não equivale à ativação dos ponteiros.

Novos destaques: 2,2%,38,7%,29,3%, mulheres52,5→53,8%, distâncias61,4%, interior48,0%.
Os números antigos não permanecem nos materiais gerados. Seis testes do gerador
passaram com fixtures alteradas e geração completa.

Central candidata:
`../postload-media/candidate/business/estudos/lancamento/index.cfm`.
Somente `copy-release` e `copy-convite` foram substituídos. Diferença fora das duas
textareas: **zero bytes**, preservando checklist/owners09Nov. O cartão-resumo do
kit fora dessas duas textareas ainda tem a chamada antiga e precisa de diff
separado do controlador se for publicado junto. Não foi modificado silenciosamente.
Guia/PDF execução v7 não foram produzidos; a prioridade foi kit e corte. Nenhum
PDF de Maratonas foi gerado ou substituído.

## Remoção dos pins antigos após confirmação

`candidates-42-352/final-only/` contém o pacote só42/352. Seu diff e hashes
`before_sha256` usam os bytes esperados do pacote compatível, não o baseline antigo.
Confirmar esses hashes reais e o resultado DataGrip antes da transferência final.
Os oito hashes candidatos de cada fase foram reconferidos no disco.

Backups/manifestos dos arquivos e a definição antiga em `database-baseline.json`
permitem preparar rollback guardado. Não reexecutar o corte sem nova leitura se
algum guard falhar. Não sobrescrever mudanças concorrentes.

## Limpeza

Cada leitura usou prefixo de bridge exclusivo e `finally`; as capturas bem-sucedidas
registram `temporary_directories_left: []`. SSH/curl e verificadores Node terminaram.
Nenhum navegador, servidor de teste ou worker persistente foi iniciado. Não houve
deploy, commit ou execução do SQL final nesta subtarefa.
