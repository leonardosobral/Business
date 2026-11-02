# Pós-prova nas fichas e páginas permanentes — 30/10/2026

## Entrega

Primeiro recorte pós-prova do plano de páginas regionais/pace. O runtime pertence ao RoadRunners; Business mantém o plano e as evidências. Publicado em 30/10/2026 às **15:12:29 (Brasília)**. Nenhuma escrita no banco, migração ou operação no DataGrip. Sem commit/push.

### Ficha de evento

Novo bloco `#pos-prova` após o card principal, somente depois do último dia inteiro da prova, com fallback para a data inicial. Provas futuras, de hoje, em andamento, canceladas e adiadas não recebem o bloco.

- Resultados: link para a página da prova no OpenResults quando existe ao menos um registro `origem_resultado='oficial'`, homologado, concluinte (ou nulo) e status final zero (ou nulo). Uma consulta parametrizada retorna somente booleano, com cache de um minuto e timeout de cinco segundos; não carrega nomes ou URLs de resultados pessoais.
- Fonte cadastrada: `url_resultado` com protocolo HTTP/HTTPS. Mantém query string/fragmento e escapa o atributo. Não usa `url_wiclax`, que pode ser um arquivo de importação. Não atribui verificação oficial a todos os links legados; os estados vazios distinguem ausência de fonte/importação.
- Fotos: reutiliza `eventFocoGalleries`, originado dos vínculos ativos ou fallback legado existente. No novo bloco, deduplica URLs e aceita somente galerias específicas no domínio exato da Foco (`/prova/` ou busca por `competition_id`). Não apresenta a home genérica como galeria. Disponibilidade independe dos resultados importados. Preserva o modal/cupom existente e oferece links HTML em uma seção recolhida, com `rel=sponsored noopener`.
- Próxima edição: reutiliza `qEventoEdicoes`, ativo pelo contrato da view existente. Somente quando o agrupador é de maratona e a edição pertence ao mesmo `id_agrega_evento`; seleciona a mais próxima não passada, excluindo canceladas/adiadas e linhas sem tag. Mostra intervalo de datas. Um circuito não gera “próxima edição” a partir de outra cidade/etapa. Sem cadastro futuro, não infere data anual.
- Calendário: ligação para a cidade apenas em prova com país BR, UF e slug válidos. Destino regional permanece em português.
- Conteúdo PT/EN/ES, inclusive caminho da próxima edição. Descrição SEO da ficha realizada passa a comunicar a data passada e a consulta dos materiais. Título/canonical/schema não foram alterados.

A barra antiga deixa de repetir os botões de resultados/fotos quando o novo bloco está ativo. Sugestões pessoais de reconhecimento de resultados, informações do organizador, inscrição/cupom, mapas e histórico existente continuam no fluxo anterior. Sem mudança nas regras de indexação/privacidade dos resultados pessoais.

### Páginas permanentes

Template de maratonas e os dois circuitos piloto (LIVE! e Estações) recebem seção recolhida com até três provas realizadas recentes e links para `#pos-prova`. Reutiliza as consultas já carregadas, sem nova consulta ao banco; exclui canceladas/adiadas dos novos atalhos. Cada link abre a ficha e sua disponibilidade real, sem garantir material para todas as edições. Mantidas as abas próximas/realizadas, informações editoriais, destaques e cupons.

## Arquivos do pacote

1. `evento/index.cfm`: inclui modelo/view de pós-prova; CSS somente no evento elegível; descrição SEO passada; suprime duplicação dos botões antigos.
2. `evento/parts/post_race_data.cfm` (novo): modelo localizado, consulta booleana de disponibilidade, normalização de links e próxima edição.
3. `evento/parts/post_race.cfm` (novo): HTML acessível e ações do bloco; acesso direto protegido com 403.
4. `includes/backend/backend_permanent_race.cfm`: constrói as três edições/etapas recentes.
5. `includes/permanent_race_overview.cfm`: seção de atalhos pós-prova.
6. `assets/css/runnerhub-race-guides.css`: espaçamento das ações, âncora e foco visível do botão.
7. `maratona/index.cfm`: versão do CSS.
8. `circuito/index.cfm`: versão do CSS.

## Verificações

- Baseline: seis arquivos existentes coincidiam entre produção e local; dois novos includes. Mudanças anteriores nas páginas permanentes/circuitos foram preservadas.
- **7 templates compilados**, fontes candidatas sem reescrita, no Adobe ColdFusion.
- **15 cenários** com bootstrap real em diretório temporário localhost+token: Floripa/Porto Alegre realizadas, Teresina com fotos/fonte sem importação, São Luís com fotos sem fonte/importação, Porto Seguro sem materiais, Curitiba futura, Floripa EN/ES, quatro páginas permanentes e dois circuitos; inclui modelo sintético.
- **19 asserções de modelo**: último dia, evento de vários dias, cancelamento/adiamento, ausência de resultados, rejeição de URL insegura, domínio falso e galeria genérica, deduplicação, próxima edição da família correta/mais próxima, circuito, país estrangeiro, intervalo, textos/URLs localizados, escape HTML e ausência de edição futura.
- Respostas do candidato Floripa: 0,441/0,403/0,398 s; baseline: 0,405/0,430/0,446 s, amostras do ensaio, sem inferir Core Web Vitals.
- **17 verificações públicas**: 14 páginas anônimas com 200, H1/canonical/conteúdo/idiomas; dois novos includes diretos retornando 403; CSS publicado idêntico por SHA-256.
- Chrome desktop e celular 390 px: Floripa com duas galerias no modal e cupom; atalhos de histórico acessíveis por teclado, salto `#pos-prova`; próxima edição 28–29/08/2027; São Luís com fotos acessíveis sem resultados importados. Sem overflow horizontal. Viewport restaurado.
- Destino OpenResults de Floripa aberto no navegador: nome da prova, 12.936 concluintes e modalidades presentes. Não houve alteração no OpenResults.

## Publicação e recuperação

Staging de trabalho: `Business/_codex/staging/seo-pos-prova-20261030/`.

- `baseline.json` e `baseline/`: hashes e cópias da produção antes desta rodada.
- `candidate/`, `candidate-verified.json` e `candidate-*.html`: pacote e resultados do ensaio.
- `release-prepare.json`, `release-publish.json`, `release-verify.json`: backup, publicação e oito hashes finais verificados; cinco dependências compartilhadas intactas (`Application.cfc`, variáveis, head, header e `.htaccess`).
- `public-verified.json` e `public-*.html`: conferências anônimas.
- `browser-verified.json` e screenshots: prova da UI publicada.
- `local-sync-verified.json`: sincronização local protegida por hashes.

Backup de produção: `/var/backups/seo-pos-prova-20261030/baseline`. `release.py rollback` confere o estado publicado antes de restaurar seis arquivos anteriores e remover somente os dois includes novos. Não restaurar cópias às cegas após novas alterações de produção. A publicação não envolve alterações no banco, credenciais ou permissões.

## Continuidade

Retorno pós-prova entregue neste recorte; confirmação de informações por organizadores, atualização dos vínculos quando publicados e medição de impacto seguem no plano central `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`. A rodada não executou nova auditoria Semrush nem comprova aumento de ranking, Site Health ou tráfego. Imperatriz continua sem confirmação suficiente; kits ainda não anunciados não foram inferidos.
