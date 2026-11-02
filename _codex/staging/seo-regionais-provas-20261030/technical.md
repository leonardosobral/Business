# Regionais e páginas permanentes — 30/10/2026

Publicação do template compartilhado de regionais e maratonas. RoadRunners é dono do runtime; Business guarda plano e evidências. Seis arquivos, sem alterações de banco, permissões, API ou serviços externos.

## Comportamento

- Estados e cidades exibem um bloco recolhido de histórico de maratonas, antes dos filtros. Até seis famílias com pelo menos duas edições ativas na região, priorizando próximas datas. Usa os vínculos existentes, nunca associa eventos por similaridade de nome. O bloco é independente dos filtros e aparece apenas na primeira página; não participa da substituição AJAX da lista.
- Páginas `/maratona/{tag}/` têm destaque da próxima edição cadastrada ou em andamento, intervalo de datas, última edição realizada, acesso aos calendários de cidade/UF e instruções sobre inscrição, resultados e pace. Reutiliza as queries das abas, movidas para antes do head; nenhuma query extra nessa rota.
- Título/descrição específicos, canonical permanente e `CollectionPage` com `ItemList` de até 25 edições presentes no HTML. Não representa o conjunto como um único `Event` nem inventa data de uma edição futura.
- Eventos continuam em Próximos até a data final. Quando não há término, usa início. O Adobe QoQ exige proteção `IS NOT NULL` antes da comparação: sem ela, um término nulo pode satisfazer `< hoje` e duplicar o item nas abas.
- Aba ativa declara `aria-selected=true`; painéis usam tabindex 0. Includes novos não aceitam acesso direto.
- CSS próprio compacto, servido diretamente, sem JavaScript novo. Layout respeita componentes e colunas existentes.

## Alcance e pendências

PR/Curitiba e DF/Brasília são prioritários; SC/RS foram conferidos como expansão. O template atende outras regionais e maratonas já existentes, quando há acervo. Não foram criadas rotas ou páginas combinatórias, nem alterados filtros, sitemap, autenticação ou datas no banco.

A Maratona de Curitiba possui uma ficha futura no calendário que ainda não está vinculada ao histórico permanente. O estado vazio diz que não há próxima edição **neste histórico**, sem afirmar que a prova não acontecerá. Revisão de vínculos, distâncias e demais fatos nas fontes oficiais continua pendente. Floripa recebe as melhorias do template, mas a curadoria editorial específica, dois circuitos e expansão pós-prova não estão concluídos.

## Validação e operação

- 5 templates compilados no Adobe ColdFusion.
- 14 cenários: PR/Curitiba/DF/Brasília/SC/RS/AC, filtro de cupom, página 2, Floripa, Monumental, Curitiba e Porto Alegre, além da fixture de modelo.
- 13 asserções de modelo: evento em andamento, futuro/passado sem término, ordenação, vazio, deduplicação de cidade, escape de texto, JSON-LD, país estrangeiro e slug inválido.
- Verificação HTTP anônima de 12 páginas, CSS por hash e 403 dos três includes; recibo em `public-verified.json`.
- Conferência no Chrome autenticado: Floripa desktop/mobile 390 px, abas Próximos/Realizados e regional Curitiba; largura do documento 390 px sem overflow.
- Medições locais de PR na última rodada: candidato 0,263/0,305/0,272 s; baseline 0,242/0,241/0,266 s. São amostras pontuais de resposta, não Core Web Vitals.
- Publicação inicial 30/10 às 12:55:51 (Brasília), com ajuste das contagens para incluir somente registros ativos e revisão de texto na conferência final.
- Backup: `/var/backups/seo-regionais-provas-20261030/baseline`; complementos em `active-catalog-fix/baseline` e `update-155954/baseline`. Manifesto principal contém hashes finais; `release.py rollback` restaura o baseline inicial com guarda contra alterações concorrentes.
- Seis hashes publicados e cinco dependências protegidas (Application, variáveis, head, header, .htaccess). Não há commit/push.

Fontes de runtime: `estado/index.cfm`, `maratona/index.cfm`, `includes/backend/backend_permanent_race.cfm`, `includes/permanent_race_overview.cfm`, `includes/regional_races.cfm`, `assets/css/runnerhub-race-guides.css`.

Scripts da rodada estão no Business em `_codex/staging/seo-regionais-provas-20261030/`. `verify_candidate.py` usa arquivos candidatos e `model-test.cfm` em fixture temporária, restrita ao localhost/token e removida ao final. Não publicar a fixture nem os scripts de operação. As fontes finais são os arquivos de runtime; `build.py` registra apenas a transformação inicial e não deve ser usado para regenerar a versão final.

Plano: `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`. Entrega técnica não comprova aumento de posições ou tráfego; avaliar GSC em janelas equivalentes e considerar a sazonalidade das provas.
