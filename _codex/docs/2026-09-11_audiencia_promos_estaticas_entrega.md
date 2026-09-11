# Audiência — promoções estáticas, 11/09/2026

## Estado

**Publicado em 11/09/2026 às 00:28:43 de Brasília e validado no Business. Não há SQL adicional.** São seis arquivos de execução e dois de teste/suporte, todos com hashes idênticos ao candidato revisado; somente os seis de execução foram publicados. Nenhum arquivo de execução do Business foi alterado: a tabela existente **Audiência → Posições** já mostra institucionais, montagem e exposição por posição, família, região e dispositivo. Evidência, backup e limites da validação ao vivo: [recibo de publicação](2026-09-11_audience_static_promos_publicado.md). As validações locais abaixo descrevem a etapa anterior à publicação.

Manifesto: [arquivos e hashes](2026-09-11_audience_static_promos_manifest.json). Pacote pronto, somente runtime: [seis arquivos](../releases/2026-09-11_audience_static_promos_linux.tar.gz), SHA-256 `c4ee24969fcef97482aa9fe4acdceee64c2c4b39dbbb5977b13baa01162fd3f7`.

## Cobertura adicionada

| Posição física | Peça existente | Aplicabilidade preservada |
|---|---|---|
| `rr-profile-sidebar-promo` | Maratonas ou Strava | Sidebar desktop do atleta e caller compartilhado de configurações; a condição atual de perfil continua decidindo qual peça existe. |
| `rr-legacy-sidebar-promo` | Catarinense ou Todo Santo Dia | Bloco lateral legado em telas de pelo menos 992 px. |
| `rr-legacy-sidebar-marathons` | Maratonas | Depende do caller: também mobile em Maratonas, a partir de 768 px no Calendário. |
| `rr-channel-sidebar-promo` | Maratonas ou Strava | Sidebar do entrypoint legado Canal, a partir de 768 px. Não foi comprovado tráfego nem navegação interna para essa rota. |
| `rr-challenge-detail-promo` | Todo Santo Dia | Promoção no conteúdo do desafio 365 confirmado, sem restrição de viewport adicional. |

Os oito ramos de imagem representam cinco posições, não oito. Alternar uma peça no mesmo lugar não cria outra posição. As quatro laterais usam placement `rr-sidebar-static-promo`; a chamada no conteúdo usa `rr-content-static-promo`. Não há dimensão nova para comparar os criativos entre si, nem reaproveitamento do campo UTM `creative` para essa finalidade.

São posições `house`, sem campanha, delivery, pedido ou entrega Ads. Geram oportunidade, montagem e exposição da posição, **não impressão faturável nem consumo de créditos**. O criativo precisa carregar e atingir pelo menos 50% de área visível durante um segundo contínuo, com documento visível. Uma imagem quebrada ainda pode registrar a oportunidade, mas não montagem/exposição. A checagem passou a incluir a própria imagem-raiz; antes ela verificava somente imagens descendentes.

Nenhuma classe, dimensão, link, condição ou parâmetro OAuth foi alterado. Não se reservou área para slots colapsados, nem se ativaram mocks comentados. Os banners de `profile_mini.cfm` sem caller encontrado continuam fora. CTAs de cadastro e o modal de conexão Strava são interfaces de produto separadas deste lote de posições de banner.

## Arquivos

RoadRunners runtime: `assets/js/rr-audience.js`, `includes/analytics/bootstrap.cfm`, `atleta/parts/sidebar_desktop.cfm`, `includes/estrutura/barra_lateral.cfm`, `canal/index.cfm`, `desafios/desafio_confirmado.cfm`.

Teste: `_codex/tests/audience-static-promos.test.js`. Fixture reprodutível: `_codex/scripts/render_audience_static_promos_fixture.mjs`. Não publicar esses dois arquivos no webroot. O bootstrap referencia tracker `27dd026e4ad8`.

Business: somente plano, manifesto e documentação de entrega/publicação; consultas e telas atuais foram preservadas.

## Validações

- TDD: antes de implementar, 3 falhas esperadas em 4 testes (marcadores ausentes, 0/5 posições e imagem-raiz quebrada contabilizada). Após implementar, 4/4 passaram.
- Controlador: **87/87 testes Node RoadRunners** e sintaxe passaram no candidato e novamente nos oito arquivos aplicados. `git diff --check` passou nos dois projetos; todos os hashes aplicados conferem com o manifesto.
- Business: **5 testes JavaScript e 51 assertivas SQL** passaram; SQL executado somente em PostgreSQL descartável. O sandbox bloqueou memória compartilhada na primeira tentativa; a execução local autorizada passou. Nenhum banco de produção foi acessado.
- CFML: o runner extrai e executa os oito ramos reais dos quatro templates em Lucee/CommandBox local, substituindo catálogos/usuário/rotas de domínio na fronteira. O controlador repetiu o comando e confirmou a mesma saída portátil, SHA-256 `dc80fba90fd3eb525fdb5c17ec4d8921157c1513146d1d664a88f1f6146c738f`. Não são páginas completas com seus backends, nem Adobe ColdFusion de produção.
- Navegador, fixture comportamental sintética com tracker/imagens reais: 1360 px → 5 posições; 390 px → 2; 768/991 px → 3; 992 px → 5. Trocas dos três pares não duplicaram oportunidades; sem eventos Ads/request/served, overflow ou erros de console.
- Navegador, saída dos trechos CFML reais: desktop 1360×900 → 5 oportunidades, montagens e exposições; alternar perfil/canal manteve 5. Mobile 390×844 → 2 oportunidades e 1 exposição confirmada na área então visível. Sem eventos pagos, overflow ou erros. O wrapper de demonstração usa CSS simplificado; não equivale a uma homologação visual de páginas inteiras em produção.
- Revisão de conformidade/qualidade e revisão integrada independente aprovadas, sem achados acionáveis. A versão final do runner preserva o breakpoint do topo legado e embute os JPEGs locais, corrigindo dois problemas do artefato de teste antes do fechamento. Runtime permaneceu congelado durante esse ajuste.

Todas as requisições de coleta dos testes de navegador foram interceptadas localmente. Abas temporárias fechadas, viewport restaurado e servidores de teste encerrados. Abas/filtros do Business e demais abas do usuário não foram alterados nesta entrega.

## Publicação e reversão

1. Comparar os seis destinos com os hashes `before` do manifesto; se houver divergência, revisar antes de sobrescrever. Não sincronizar checkouts inteiros.
2. Criar backup privado no servidor e registrar hashes, owner, group e mode dos seis arquivos existentes.
3. Publicar primeiro tracker, depois os quatro templates e por último o bootstrap. Não enviar SQLs, testes, configs ou arquivos adjacentes. O tracker antigo não verifica a imagem-raiz quebrada, portanto os novos markers não devem preceder o tracker.
4. Conferir hashes/metadados e validar posição aplicável em acesso interno real; confirmar no Business → Posições com o filtro de internos, considerando cache de até um minuto. Restaurar o filtro comercial ao terminar.
5. Se necessário, reverter somente os seis arquivos do backup. Não há reversão SQL ou exclusão de eventos. A contagem não é retroativa. A validação posterior confirmou as duas posições legadas no desktop e a inferior no mobile em produção; os demais ramos têm a cobertura local descrita acima.

Backup local pré-aplicação: `/private/tmp/rr-static-promos.QP552l/before`. Registros de revisão preservados em `.superpowers/sdd/2026-09-11-audiencia-promos-estaticas/`; nenhum commit/branch foi criado.

## Continuidade

Preservados login, configurações, Ads/cobrança, DSN `runner`, `runner_dba`, opt-out/GPC, retenção de 90 dias e `tb_log`. Não se executou retenção nem se alterou o provedor de UF.

Com este lote publicado, permanecem no plano: desenho para potencial visual de espaços hoje colapsados, UF física confiável, rotina operacional de retenção do DBA, projeção comercial após semanas completas de base e piloto SC A/B com verba aprovada. A aposentadoria exclusiva do writer de visualização de evento em `tb_log` continua para o final; demais logs e histórico ficam preservados.
