# Banners HOUSE — cadastro simplificado e escopo regional

Data: 15/09/2026. Desenho funcional aprovado na conversa; especificação técnica
preparada para revisão antes da implementação. Nenhum runtime ou banco alterado.

## Objetivo e limites

Simplificar `/portal/banners/` e permitir selecionar páginas e UFs nas quais um
banner HOUSE pode participar. Business administra; RoadRunners é dono da seleção,
entrega e contratos SQL do schema `ads`. Continuam sem cobrança, separados dos
anúncios EVENT/CPC. Salvar um banner novo continua criando rascunho; ativar é uma
ação explícita. Banners existentes mantêm o alcance atual até edição deliberada.

Não criar novos espaços visuais, alterar o leilão CPC, billing, autenticação,
geolocalização física, retenção, permissões administrativas ou métricas históricas.
Não executar commit, branch, push ou PR. Não publicar mudanças de outras frentes.

## Evidência no código atual

- `portal/banners/home.cfm` expõe canal e placement fixos, dimensões manuais,
  tamanho nomeado, tipo de link, peso e prioridade.
- `portal/includes/banner_management_backend.cfm` grava pela função canônica
  `ads.save_house_banner_campaign`; valida dimensões antes do upload e ainda não
  extrai largura/altura do arquivo. Canal e tamanho exibidos na listagem são
  constantes. Editar exige campanha DRAFT/PAUSED no contrato SQL atual.
- Existe um placement BANNER suportado: `rr-sidebar-banner-300x250`. É reutilizado
  em diferentes páginas e versões desktop/mobile; não equivale a uma página.
- `AdsV1BannerDeliveryService.cfc` usa `select_delivery_candidate_v2` e depois
  `serve_delivery`. A seleção conhece UF única, mas não páginas nem múltiplas UFs.
- `banner_delivery.cfm` usa `route` também para a identidade dos slots de audiência.
  Alterar esse identificador para filtrar páginas quebraria a série histórica.
- Evento, perfil, busca e estado incluem `home_sidebar_async_slot.cfm`, mas o
  endpoint `api/home_sidebar.cfm` fixa contexto de home. O pedido assíncrono precisa
  levar separadamente a página de origem e seu contexto regional.
- O banner mobile da home passa UF vazia. Há ainda um include de feed com UF vazia;
  não disponibilizar uma página no cadastro apenas porque existe um include sem
  comprovar um caminho de renderização ativo.

## Cadastro proposto

Três grupos, sem assistente obrigatório:

1. **Conteúdo:** nome interno, imagem desktop, imagem mobile, descrição da imagem
   para acessibilidade e link de destino.
2. **Onde exibir:** posição, páginas e estados.
3. **Período:** início e fim, com opções avançadas recolhidas abaixo.

Regras dos campos:

- Canal `roadrunners` e tamanho técnico são definidos no servidor, não campos.
- Posição tem nome legível: **Banner responsivo — lateral no desktop / área de
  banner no mobile**. Enquanto houver apenas um placement, mostrar selecionado
  como informação, sem simular opções inexistentes. Sua identidade permanece
  validada no servidor. Novos slots dependem de consumidores reais futuros.
- Dimensões são extraídas e validadas no servidor a partir do arquivo decodificado;
  o navegador fornece apenas prévia e informação das dimensões. Não aceitar medidas
  arbitrárias enviadas por POST nem baixar URLs fornecidas para descobrir medidas.
- JPG/PNG/GIF continuam aceitos; conferir conteúdo real, limites de bytes e pixels,
  e rejeitar arquivo inválido com erro junto ao campo. Não converter GIF animado.
  Processar uploads em staging não executável, publicar somente arquivos validados
  e limpar arquivos novos da tentativa quando ela falhar, sem excluir peças antigas.
- Na edição, preservar imagens e dimensões persistidas quando não houver upload;
  resolver os dados pelo ID autorizado, não pelos caminhos hidden enviados.
- Descrição da imagem continua visível e obrigatória, com exemplo legível. Não
  substituir automaticamente por nome interno, que pode não descrever a peça.
- Tipo de link é inferido de URL relativa/host permitido; preservar validação HTTPS
  e destino seguro. Para banner novo: relativo/interno abre na mesma aba, externo
  em nova aba. Opção avançada permite mudar; edição preserva a escolha existente.
- Peso/prioridade começam em 1 e ficam em **Opções avançadas**, sem mudança na regra
  de seleção existente. Preservar valores atuais na edição.
- Início de banner novo começa no horário atual, editável. Fim é explícito e
  posterior ao início; não inventar vencimento nem ativar automaticamente.
- Erros mantêm campos e escopo selecionados; navegador pode exigir reenvio do arquivo.
- Listagem mostra resumo de páginas e UFs sem criar linhas duplicadas por estado.

## Páginas, UFs e elegibilidade

Páginas selecionáveis nesta etapa: **Página inicial**, **Busca**, **Eventos por
estado**, **Página de evento** e **Perfil do atleta**. São famílias, não URLs livres.
Idiomas e aliases pertencem à mesma família. Exibir apenas famílias cuja combinação
com o placement tenha sido confirmada nos testes de renderização.

Padrões para novos banners: **Todas as páginas compatíveis** e **Todo o Brasil**.
Seleção específica exige pelo menos uma página/UF. UF aceita somente as 27 siglas
brasileiras, normalizadas e sem duplicatas. Nunca interpretar seleção específica
vazia ou inválida como nacional.

Um banner participa somente se **posição E página E UF E período E status** forem
compatíveis. Dentro do conjunto elegível, manter prioridade/peso existentes;
regionalização não cria um leilão HOUSE nem prioridade regional nova.

A UF é contexto comercial, não garantia de localização física: usar o contexto
explícito da página/busca/evento, depois perfil do visitante autenticado e localização
resolvida do acesso quando válida. Não usar a UF do atleta visitado como se fosse
a do visitante. Respeitar o fallback nacional já resolvido na home; `BR`/vazio/UF
inválida são desconhecidos. Na busca multi-UF, preservar a regra de contexto único
dos ads existentes, sem ampliar silenciosamente para todas as UFs da pesquisa.

- Banner SC com contexto SC: elegível.
- Banner SC com contexto SP ou desconhecido: inelegível.
- Banner SC/PR com contexto PR: elegível.
- Banner nacional com UF desconhecida: elegível quanto à região.
- Banner exclusivo de evento não aparece na home, inclusive na sidebar AJAX.
- Página desconhecida não recebe banner restrito a páginas; legado sem restrição
  mantém o comportamento anterior.

O contexto da família será separado do `route`/slot físico já usado pela audiência.
Parâmetros assíncronos terão allowlist e normalização, sem SQL/URL livre nem uso de
`Referer` como única fonte. A UF é contexto de seleção, não autorização de acesso.

## Contrato de dados e seleção

Usar `ads.campaigns.metadata.banner_scope_v1` para escopo HOUSE/BANNER versionado,
com modos explícitos `ALL`/`SELECTED` e arrays de páginas/UFs. Ausência da chave
significa legado irrestrito; chave presente malformada falha fechada. Preservar
outras chaves de metadata. O filtro `target_region_code`, se existir em uma campanha
antiga, continua respeitado; não limpar restrição legada implicitamente.

A migration incremental no RoadRunners altera somente contratos do schema `ads`,
sem DDL/DML em `public`, sem refazer foundation ou modificar campanhas existentes.
Leituras atuais de conta/usuário em `public` para autorização continuam permitidas.

- Contrato de salvamento versionado recebe o escopo junto da peça e grava tudo na
  mesma transação, com validação de admin, owner institucional e estado editável.
  Chamada antiga não pode apagar restrições de banner já segmentado.
- A seleção aplica o filtro **antes** de ordenar/sortear e limitar o candidato.
  Selecionar um banner incompatível e descartá-lo em CFML seria incorreto, pois
  esconderia outros banners elegíveis.
- Usar um predicado canônico de escopo, compartilhado pela seleção e pela validação
  imediatamente anterior ao registro da entrega. Revalidar campanha sob o mesmo
  lock utilizado por `serve_delivery` para evitar edição concorrente entre seleção
  e entrega. Entrada sem família não pode contornar restrição de páginas.
- Manter compatibilidade das funções existentes e dos callers CPC. Novo contrato
  fornece família explicitamente; caminhos antigos recebem comportamento seguro:
  legado irrestrito continua e banner restrito sem contexto suficiente não entrega.
- HOUSE continua sem débito; não mudar VIEWABLE, CLICK, token, prioridade/peso,
  idempotência, consentimento ou marcadores de audiência.
- Persistir família/contexto mínimo no recibo de entrega para diagnóstico, sem IP,
  coordenadas ou identificadores pessoais novos.

## Abordagens consideradas

1. **Recomendada:** escopo versionado no metadata e predicado canônico no banco.
   Reutiliza o modelo atual e cobre seleção/entrega sem duplicar regra em CFML.
2. Apenas UF única em `target_region_code`: menor alteração, mas não atende
   múltiplas UFs/páginas solicitadas.
3. Filtrar após selecionar no template: simples na aparência, mas pode gerar
   espaço vazio apesar de haver candidato elegível e não protege caminhos antigos.

## Verificação necessária

- SQL em PostgreSQL isolado: nacional, UF específica/múltipla, UF desconhecida,
  famílias diferentes, entrada inválida, legado, seleção anterior ao LIMIT,
  edição concorrente, transação de salvamento e permissões; aplicar migration duas
  vezes e garantir que contratos CPC e financeiro continuam passando.
- CFML offline: admin/CSRF, defaults, round-trip de edição, inferência do destino,
  arquivos válidos/inválidos, dimensões reais, manutenção de imagem antiga e erros.
- JS/render: prévia, opções avançadas, campos acessíveis, preservação de valores,
  resumo de escopo e layout em 390/820/1280px.
- Integração de contexto: cinco famílias, idiomas, AJAX desktop/mobile, anônimo/
  logado e UF desconhecida; não confundir `sidebar` físico com família `home`.
- Adobe ColdFusion: compilar e validar render real após publicação, com backup e
  hashes. Não criar/ativar banner real, clicar anúncio ou fabricar beacon para testar.

## Ordem de publicação e recuperação

1. Entregar migration e contratos ao operador; aguardar aplicação confirmada quando
   não houver conexão/autorização adequada. Não procurar credenciais nem usar DBA
   para contornar permissões de runtime.
2. Publicar consumidores RoadRunners e contexto de páginas, preservando escopo antigo.
3. Publicar formulário/backend Business por último; bloquear salvamento de escopo
   novo com mensagem clara se o contrato SQL não estiver instalado.
4. Conferir baselines de produção, backups recuperáveis, hashes, compilação e fluxo
   real. Publicar automaticamente o runtime da tarefa após os gates, conforme
   preferência do usuário; não incluir alterações alheias.
5. Em recuperação, não devolver banners regionais à entrega irrestrita. Manter
   contratos SQL protetores e bloquear edição/entrega incompatível; não remover a
   metadata nem restaurar seletor permissivo por cima de restrições já cadastradas.

Não incluir no pacote a correção geral da faixa tablet, novas páginas sem slots,
antifraude ou reconciliação de pagamentos: são frentes separadas. A interface deve
descrever o alcance real dos espaços e não prometer cobertura de todo viewport.
