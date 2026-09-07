# Audiência e inventário — entrega da primeira etapa

## Situação

Implementação aplicada e verificada nos projetos locais, com coleta desligada por padrão. Nenhum deploy de site, migração de produção, ativação de coleta ou investimento em mídia foi executado. O compilador ColdFusion foi usado somente sobre cópias em uma pasta temporária fora dos sites publicados; compilação não executa a aplicação.

Foram aplicados 13 arquivos no Business e 32 no RoadRunners, conforme `2026-09-07_audience_business_files.txt` e `2026-09-07_audience_roadrunners_files.txt`. Correspondência byte a byte e verificações de whitespace passaram. Alterações preexistentes foram preservadas. Backups temporários dos arquivos substituídos ficam em `/private/tmp/rr-audience-before-PnTQsl`; não substituem versionamento. Nenhum commit ou branch criado.

Esta entrega é a base de mensuração e o painel administrativo. Não significa que já exista histórico confiável, previsão comercial validada ou a estratégia inteira de crescimento implementada.

## Regra regional aprovada

Uma pessoa com origem SP que consulta SC participa da audiência comercial de SC. São preservadas, separadamente, UF do acesso, UF do perfil do visitante e UF do contexto. A prioridade comercial é contexto, perfil e acesso; desconhecido permanece explícito.

Na busca assíncrona, o servidor revalida e reassina o contexto dos slots retornados. O identificador da página continua o mesmo. A abertura inicial não é reescrita nem repetida por partial. Por isso o Business distingue **páginas com atividade no recorte** de **aberturas nesse contexto**. Visitantes, sessões e páginas gerais são deduplicados; os totais regionais não devem ser somados.

O contexto é regional, não uma promessa de seleção. Login, posição, dispositivo, orçamento, concorrência e demais regras existentes continuam determinando elegibilidade. Não foi alterado o leilão para forçar uma campanha a consumir créditos.

## Entregue nesta etapa

- Nova área administrativa `/portal/audiencia/` no Business, com filtros de período, dimensão regional, UF, família de página, dispositivo, ambiente e acessos internos.
- Indicadores e tabelas de audiência, inventário por posição/família, regiões, conteúdo individual, aquisição por UTM, evolução diária e cobertura observada. Consultas consideram o período inteiro; limites de detalhamento são declarados.
- Coletor próprio com contexto assinado, IDs pseudônimos, lote limitado e ingestão idempotente. O schema `audience` é separado de Ads e não debita saldo.
- Eventos distintos de posição prevista, requisição, entrega, montagem, anúncio renderizado e exposição visível. Posição colapsada não é apresentada como impressão.
- Estados comercial, institucional, vazio, pendente, oculto, desativado, não aplicável e erro. Pendente não é vazio confirmado.
- Visibilidade geométrica de pelo menos 50% durante 1 segundo contínuo, documento visível e imagem carregada. Reentrada e reenvio não criam novas impressões. Durações são atualizadas monotonamente.
- Notícias e perfis identificados por conteúdo; abertura de vídeo separada de reprodução. Eventos HTML5 usam sinais reais do player.
- Falta de schema, indisponibilidade da consulta e ausência de tráfego são estados distintos no Business.

## Verificação

- Consultas do Business: **37 assertivas** em PostgreSQL 16 local descartável, incluindo SP→SC, totais deduplicados, campos desconhecidos, conteúdo, paid/HOUSE e pendente versus vazio.
- Migração/ingestão: contrato PostgreSQL 16 passou, com reaplicação, idempotência, duração monotônica, rejeição de lote inválido, validação de UFs/atribuição e isolamento financeiro.
- Integração RoadRunners→Business: **27 assertivas** passaram com migração e ingestão reais, executando as sete consultas reais do painel por `runner_dba` em transações somente leitura. Inclui SP→SC e pending→empty com reenvio atrasado.
- Compilação Adobe ColdFusion isolada: **20/20 arquivos RoadRunners e 4/4 arquivos Business** compilaram. Nenhuma aplicação ou consulta foi executada pelo compilador.
- Tracker: **25/25 testes Node** passaram, incluindo cruzamento abaixo de 50% entre amostras, rotação de sessão, slots vazios/pendentes, imagem quebrada, aba oculta e troca regional assíncrona. Regressão Ads DOM-ready e sintaxe JS passaram.
- Chrome real: passaram os cenários 1280px, 390px, troca SP→SC com deduplicação, SC sem resultados e controlador real de filtros/paginação (`callAPI`/`loadImages`). O último confirma headers, adoção do contexto somente nos novos resultados, preservação das regiões anteriores e abertura global única. Essa suíte, os 25 testes Node e as 27 assertivas de integração foram repetidos nos checkouts finais.
- Revisão independente encontrou e motivou correções no preenchimento paid/HOUSE, dispositivo desconhecido, estado sem resultados e rejeição de CPF formatado em UTM.

Os testes SQL não substituem a execução CFML via HTTP. O teste de navegador usa o JS real e HTML representativo em loopback, não páginas de produção nem entregas reais de anúncios.

## Ordem de homologação e ativação — ainda não executada

1. Aplicar a migração aditiva RoadRunners `_codex/sql/2026-09-07_audience_inventory.sql` como proprietário do schema no ambiente de homologação. Confirmar grants do datasource real: ingestão pela aplicação; leitura pelo Business. Não executar fixtures em produção.
2. Publicar os arquivos de aplicação do manifesto aprovado em homologação. Manter `APPLICATION.audienceMeasurementEnabled` ausente ou `false` até o schema estar disponível.
3. Fornecer segredo aleatório de pelo menos 32 caracteres pelo gerenciador operacional: `APPLICATION.audienceMeasurementSecret` ou variável de ambiente `RR_AUDIENCE_MEASUREMENT_SECRET`. Não incluir segredo em arquivos versionados ou documentação. A flag de habilitação é de aplicação, não uma variável de ambiente automática.
4. Executar `_codex/tests/audience-service-contract.cfm` apenas em ambiente isolado. Verificar bootstrap e POST real: lote válido, assinatura adulterada/expirada, origem incorreta, tamanho acima do limite, feature desativada e falha de banco. Garantir que navegação continue funcionando.
5. Validar home, estado com/sem resultados, busca inicial e AJAX com troca de UF, evento, perfil, notícias/lista/detalhe e vídeos; desktop/mobile, anônimo/logado, slot vazio/pendente, imagem quebrada, aba oculta e repetição de eventos. Conferir que nenhuma métrica de audiência altera créditos.
6. Abrir `/portal/audiencia/` com administrador e tentar com não administrador. Verificar também acesso direto aos includes, filtros e estados de schema ausente/consulta indisponível. Renderização real e binding CFML ainda precisam dessa homologação.
7. Antes de ativar produção: definir retenção, revisar aviso/controles de privacidade e exclusões de tráfego automatizado; conferir limites de requisição e proteção operacional do endpoint. HMAC protege integridade do contexto, mas não prova que um evento cliente corresponde a uma pessoa ou impede toda fraude.
8. Só então publicar e habilitar a flag explicitamente. Acompanhar cobertura e erro de coleta; em regressão, desabilitar a flag. Isso interrompe a coleta sem apagar dados nem mudar contratos Ads.

Não foi instalado um monitor recorrente. O acompanhamento operacional acima é um procedimento para a ativação, não uma promessa de execução automática.

## Limitações e continuação

- A medição não recupera visibilidade histórica. Bloqueios, opt-out, rede, aba fechada, filas e navegadores limitam cobertura; visitantes únicos são estimados por navegador, não pessoas deduplicadas entre dispositivos.
- Geometria não comprova atenção nem detecta toda sobreposição por elementos. Posição removida do layout só tem oportunidade lógica; para observar potencial visual de espaço vazio, é necessário reservar área ou veicular peça institucional equivalente, melhoria de layout separada.
- Classe de dispositivo é inferida pela largura do viewport, não identificação exata do hardware. Sem IntersectionObserver, o fallback usa amostragem de 250 ms e pode perder cruzamentos mais rápidos; não se trata de medição certificada.
- YouTube em iframe ainda registra abertura, não início/progresso/conclusão sem integração com a API do player. Não afirmar que todo vídeo foi reproduzido. IDs compactos de mídia não substituem títulos editoriais.
- Profundidade de leitura, exposição de cards editoriais, funil de login/ativação, cliques de saída genéricos, coortes de retorno em sete dias, importação de gasto e previsão de entrega permanecem no próximo incremento. O painel desta etapa não promete custo de aquisição nem capacidade futura validada.
- A cobertura mostra famílias que enviaram eventos; ausência de linha não é prova de audiência zero. Posições só de desenvolvimento ou comentadas não viram capacidade comercial ativa.

Após homologar e ativar: formar linha de base com semanas completas, conferir capacidade observada e preparar o piloto SC. O teste proposto compara “Ache sua corrida” com “Monte seu histórico”, com público e janela equivalentes e identificação por UTM. Teto de verba segue pendente; nenhuma compra ou campanha foi criada.

Estratégia de referência: `estrategia_audiencia_inventario_e_midia_proposta.md` neste diretório.
