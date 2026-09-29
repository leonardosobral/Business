# CRM interno — públicos e campanhas revisadas

Data: 24/09/2026. Status: especificação aprovada pelo usuário com “prossiga”, após apresentação do documento. Implementação ainda não iniciada.

## 1. Objetivo e decisões aprovadas

Criar uma tela interna sobre os usuários da plataforma para encontrar oportunidades de venda de produtos e serviços com base em interesses e comportamento observado. O operador deve entender quem está no público, por qual motivo, quais canais estão disponíveis e o resultado de cada campanha.

O usuário escolheu **públicos salvos e campanhas revisadas antes do envio**. Em 24/09, autorizou prosseguir com o desenho apresentado: públicos, ficha do corredor, campanhas e card contextual na lateral do mini perfil. A primeira versão não dispara campanhas automaticamente quando alguém passa a satisfazer uma regra.

Critério de sucesso: um operador autorizado consegue salvar um público, revisar os usuários e motivos, preparar uma campanha, confirmar sua execução e acompanhar resultados reais por canal. A revisão não pode disparar mensagens. A publicação do software não pode ativar uma campanha.

## 2. Evidências e componentes existentes

As constatações abaixo vêm do código local e não comprovam cobertura, atualização ou instalação do banco de produção.

| Área | Evidência existente | Consequência para o projeto |
|---|---|---|
| Usuários | `administracao/usuarios/`, `docs/gerenciador-usuarios.md` | Reaproveitar identificação e estados administrativos; acesso interno separado de contas de parceiros. |
| CRM atual | `crm/includes/backend.cfm` usa o schema `crm` e relacionamentos de pessoas, pedidos e participações de eventos | Criar `/crm-interno/`, preservando o CRM de eventos e seus escopos. |
| Notificações | `notificacoes/includes/send_backend.cfm`, `docs/notifications-platform.md` | Business já chama dispatch assinado do Road Runners. Reutilizar a entrega central, validando idempotência e retorno por destinatário. |
| E-mail | `emailmkt/fila.cfm`, `emailmkt/EmailSenderService.cfc` | Existe transporte e fila `tb_mailing`; o código lido não comprova uma operação com reserva concorrente, deduplicação e supressão suficientes para o CRM. |
| Banners | `portal/banners/`, `docs/portal-banners.md`; Road Runners `services/AdsV1BannerDeliveryService.cfc` | Reaproveitar criativos e medição onde compatíveis, acrescentando elegibilidade por campanha sem mudar regras das campanhas existentes. |
| Regras | Business `administracao/chat/grupos-especiais/`; Road Runners `includes/backend/backend_chat_special_groups.cfm` | Existe precedente de catálogo fechado de critérios, prévia e API assinada. Reutilizar contratos e regras canônicas pertinentes, sem acoplar CRM a membros do chat. |
| Agenda | `tb_evento_corridas_checkin` possui usuário, evento, tipo e data; não possui modalidade escolhida | Distinguir evento salvo, inscrição registrada e distância efetivamente confirmada. |
| Audiência | Road Runners `_codex/sql/2026-09-07_audience_inventory.sql` identifica visitantes e sessões, sem vínculo de conta nesse contrato | Não inferir identidade por cookie de visitante. Criar medição própria de uso autenticado, com cobertura explícita. |
| Atividades | Schema de referência de `tb_strava_activities` contém `activity_source`; usuários têm `strava_full_shoes` | Nome de tabela ou presença do campo não prova origem permitida. Treinos e tênis exigem verificação da proveniência antes de entrar no catálogo comercial. |

## 3. Escopo e responsabilidades

**Business:** nova entrada “CRM interno”, telas de públicos, ficha e campanhas, revisão da audiência, conteúdo, operação e histórico. Mantém o padrão CFML/MDBootstrap do projeto e consome contratos autenticados; não replica interpretações esportivas.

**Road Runners:** avaliação canônica dos sinais e da elegibilidade, API administrativa assinada, medição de uso autenticado, entrega de notificações e card contextual ao usuário autenticado. O navegador nunca escolhe o usuário a ser segmentado enviando um ID livre.

**Persistência:** schema aditivo `crm_interno`, independente do schema `crm` existente. Serviços do domínio expõem as operações necessárias ao Business. A implementação escolherá os nomes físicos finais das tabelas no plano, preservando as entidades e invariantes desta especificação.

**Fora da primeira versão:** jornadas automáticas por gatilho, modelos preditivos/IA, exportação de listas de contatos, aquisição de dados externos e alteração dos fluxos comerciais de outros módulos. Não executar campanhas reais como parte de testes ou deploy.

## 4. Telas e fluxo do operador

### Públicos

- Buscar por nome e abrir públicos salvos.
- Montar uma regra usando catálogo fechado de filtros; combinar todos ou qualquer um, com até 12 critérios e sem grupos aninhados na primeira versão.
- Mostrar contagem distinta de usuários, prévia paginada, data de avaliação, cobertura das fontes e motivos por pessoa.
- Separar total do público de elegíveis por canal e excluídos, com motivos de exclusão.
- Salvar nome, descrição e versão da regra. Alterações criam nova versão, sem reescrever campanhas já revisadas.

### Ficha do corredor

Identidade e link para a gestão já existente; sinais próprios observados; datas, fontes e motivos; agenda e resultados pertinentes; canais disponíveis; histórico do CRM. Informações não disponíveis aparecem como tal, nunca como zero ou inatividade comprovada. Histórico legado só aparece quando a origem puder ser vinculada com segurança.

### Campanhas

1. Selecionar público e um canal: notificação, e-mail ou card no mini perfil.
2. Preencher nome interno, conteúdo, destino e período. Selecionar produto, serviço ou prova quando existir referência correspondente.
3. Gerar uma prévia com conteúdo renderizado, versão da regra, quantidade e lista de destinatários elegíveis, exclusões e data de corte.
4. Confirmar explicitamente o envio, agendamento ou ativação dentro do produto.
5. Consultar execução, falhas, exclusões, entregas aceitas, cliques e conversões efetivamente identificadas.

Editar conteúdo, canal, regra ou período invalida a prévia. Uma prévia vale por 30 minutos; depois é necessário recalcular e revisar. O registro da confirmação vincula operador, versão, conteúdo e fotografia dos destinatários. Não acrescentar novos usuários silenciosamente após essa confirmação.

Públicos salvos são dinâmicos quando consultados; campanhas confirmadas usam a fotografia revisada. No momento da entrega, revalidar conta, preferências, limites e critérios que deixaram de ser verdadeiros, removendo inelegíveis. A atualização não pode ampliar o conjunto aprovado.

## 5. Catálogo inicial de sinais

| Sinal | Definição para a primeira versão |
|---|---|
| Localidade | Cidade/UF do perfil com origem explícita. Não substituir por IP ou localização estimada sem distinguir o campo. |
| Acesso recente/recorrente | Último acesso autenticado e quantidade de dias distintos com acesso em 7, 30 ou 90 dias. “Recorrente” começa como preset editável de 3 dias nos últimos 30 dias. |
| Prova recente | Resultado vinculado e reconhecido conforme regra canônica, data da prova, distância e status. Não confundir tempo de importação com data da corrida. |
| Evento na agenda | Registro `calendario`, evento futuro e janela escolhida. Indica intenção sobre o evento. |
| Inscrição registrada | Registro `inscricao` ou fonte transacional confirmada, identificado pelo nome da fonte; presença na agenda não confirma compra. |
| Distância na agenda | Modalidade pessoal confirmada quando houver fonte. Caso contrário, oferecer filtro separado “evento oferece meia/maratona”, com essa limitação visível. |
| Desafios | Inscrição e participação recente são critérios distintos. Participação exige ocorrência própria datada e origem verificada; inscrição isolada não comprova treino. |
| Treinos | Frequência, última atividade e distância apenas de fontes próprias cuja origem e vínculo estejam comprovados. Não misturar treino com resultado de prova. |
| Tênis | Modelo, quilometragem registrada, data de atualização e fonte própria confirmada. O limite de seleção é configurável; não afirmar desgaste ou necessidade de troca apenas pela quilometragem. |
| Contatos anteriores | Campanha/canal, data e status do histórico integrado ao CRM. Ausência de histórico não significa ausência de contato fora dele. |

Datas são armazenadas com referência temporal inequívoca; a interface e os dias de recorrência usam `America/Sao_Paulo`. Distâncias são normalizadas antes da comparação; meia/maratona usam a classificação canônica dos percursos/resultados, sem presumir que igualdade textual de 21 e 21,0975 seja suficiente.

Cada adaptador declara disponibilidade, fonte, atualização e início da cobertura. Critério sem fonte confiável fica indisponível e não pode ser salvo como se funcionasse. Falha de fonte invalida a avaliação, inclusive em regras “qualquer um”; não ampliar audiência removendo silenciosamente um filtro.

### Medição autenticada

Registrar um agregado diário por usuário e ambiente no Road Runners, a partir de navegação autenticada e identidade resolvida no servidor. Deduplicar atualizações, excluir tráfego técnico, simulação e ambientes de desenvolvimento. Preservar escolhas de medição existentes; não associar retroativamente visitas anônimas às contas.

Reter os agregados por 90 dias e informar a cobertura efetiva. O primeiro mês de coleta não permite afirmar que alguém ficou 30 dias sem acessar. Durante indisponibilidade do banco ou do coletor, a navegação continua funcionando e o CRM sinaliza a lacuna.

### Dados Strava

A política consultada em 24/09/2026, vigente desde 01/06/2026, restringe cruzamento para perfis comerciais (§ 5.4), publicidade direcionada (§ 5.9) e exibição de dados de outros atletas (§ 2.3): https://www.strava.com/legal/api_policy.

Dados obtidos via Strava e seus derivados ficam fora da segmentação comercial desta implementação. Conectar a conta não equivale a autorizar esse uso. Uma exceção dependeria de acordo específico verificável e de alteração deliberada do catálogo. Dados próprios não podem ser apenas cópias ou derivados de uma importação do Strava.

## 6. Contratos e entidades

API administrativa do Road Runners, sob rota dedicada a CRM interno, seguindo o padrão de assinatura existente. Toda ação valida operador real, permissão e ambiente no servidor. Leituras de ficha e audiência são igualmente protegidas.

Operações: consultar capacidades/catálogo; listar/salvar/arquivar público; avaliar público; consultar ficha; criar/editar campanha; gerar prévia; confirmar; consultar execução; pausar/cancelar pendências. Escritas são POST, protegidas por CSRF no Business e autenticação entre serviços. Não aceitar SQL, nomes de coluna ou identidades de operador arbitrários.

Entidades persistentes mínimas:

- **Público e versões:** nome, descrição, regra validada, versão, autor e timestamps.
- **Campanha e revisão:** canal, público/versão, conteúdo, destino, período, estado, revisão e operador que confirmou.
- **Prévia:** revisão, instante de corte, validade, contagens e conjunto de usuários revisados; limite/paginação não pode truncar silenciosamente a audiência.
- **Destinatário/entrega:** campanha, revisão, usuário, canal, estado, motivo de exclusão/erro, chave idempotente, tentativas e identificador no canal.
- **Eventos de campanha:** aceite pelo canal, exibição visível, clique, dispensa e conversão identificada, com deduplicação e referência à entrega.
- **Preferências/supressões:** estado por usuário/canal e motivo; reutilizar a fonte canônica quando existente, sem sobrescrever preferências de outros módulos.
- **Uso autenticado diário:** usuário, dia, ambiente, primeiro/último acesso e metadados mínimos de cobertura.
- **Auditoria:** operador, ação, entidade/revisão e data; sem credenciais ou cópias desnecessárias do corpo de dados pessoais.

Estado de campanha: rascunho → revisada → agendada/em execução → concluída, com pausa, cancelamento e falha quando aplicáveis. Cards ficam ativos durante sua janela. Edição só ocorre em rascunho; uma nova versão é necessária depois da confirmação. Cancelar não desfaz mensagens já aceitas pelo canal.

Restrição única de entrega por campanha/revisão/usuário/canal. Reserva atômica dos itens da fila impede concorrência. Em timeout com resultado desconhecido, reconciliar pelo identificador antes de reenviar; o CRM não deve prometer entrega exatamente uma vez quando o provedor não oferecer esse contrato.

## 7. Comportamento por canal

### Notificação

Reutilizar materialização e entrega central do Road Runners. Distinguir criação na inbox, aceite do push e leitura. Push exige assinatura ativa. Para agendamento, executar o envio no horário pelo mecanismo de jobs existente; não assumir que uma notificação futura já produz push automaticamente. Tratar a unicidade de template/usuário existente antes de habilitar a integração.

### E-mail

Reaproveitar o transporte existente por um adaptador com reserva, deduplicação e retorno rastreável. Verificar preferências de comunicação, descadastro e supressões do provedor imediatamente antes do envio. A entrega comercial exige um mecanismo funcional de descadastro; sua ausência mantém o canal indisponível com explicação, sem enviar pela fila legada como alternativa.

“Aceito pelo provedor”, “entregue”, “aberto” e “clicado” são estados distintos e só aparecem quando há evidência correspondente. Não tratar abertura como conversão. Reaproveitar webhooks já disponíveis, com correlação de campanha validada.

### Card no mini perfil

Exibir no máximo um card por vez, junto à lateral esquerda do mini perfil no desktop e em posição equivalente no fluxo mobile. Resolver a conta na sessão e revalidar a elegibilidade no servidor; respostas personalizadas não usam cache público compartilhado.

Respeitar janela, status, prioridade e dispensa. Empates usam ordem determinística. A dispensa vale para a campanha inteira para aquele usuário. Limite inicial: uma impressão contabilizada por sessão e no máximo três sessões por dia/campanha/usuário. Impressionar significa exposição visível, não apenas resposta da API. Não interferir em créditos, leilão ou contadores de anúncios existentes.

Card suporta título, texto curto, imagem opcional e um destino validado. Conteúdo vazio, erro do serviço ou falta de elegíveis remove o bloco sem prejudicar o mini perfil. Oferta comercial deve ser identificável como tal.

### Frequência e mensuração

Notificação e e-mail compartilham limite inicial de um contato comercial por usuário a cada sete dias dentro das entregas integradas ao CRM. Mostrar na prévia as exclusões por limite; não oferecer bypass silencioso. Comunicações transacionais continuam fora desse limite. O histórico de outros sistemas não é presumido completo.

Medir cliques por entrega com destinos validados. Conversão só é registrada por evento transacional ou callback confiável que identifique a campanha; cliques externos sem retorno permanecem cliques. Não apresentar receita atribuída sem evidência. Testes internos são identificados e excluídos dos resultados operacionais.

## 8. Acesso, erros e desempenho

- Acesso inicial para ADMIN/DEV com identidade real autorizada; negar durante impersonação. Parceiros e operadores do CRM de eventos não herdam acesso global.
- Contas desativadas ou excluídas não entram na audiência de entrega. Ausência de schema de gestão obrigatório impede ativação de campanhas.
- Escapar conteúdo e validar destinos, parâmetros, limites e HTML dos criativos conforme os recursos usados.
- Reutilizar segredo e configuração do mecanismo de integração existente, sem copiar valores para código, documentação ou navegador.
- Indisponibilidade de API, schema ou canal gera estado explicativo. Não mostrar “enviado” ou audiência vazia para mascarar erro.
- Usar paginação, agregações limitadas por janela e índices adequados. Não consultar o Strava ao carregar a tela e não executar uma consulta adicional por usuário da lista.
- Prévia extensa e entrega funcionam em lotes com progresso; falhas parciais preservam os itens já confirmados e permitem retomar os restantes.

## 9. Critérios de aceitação e verificação

1. Conta comum, parceiro e sessão em simulação não acessam públicos ou fichas globais por URL/API direta.
2. Filtros de agenda, inscrição, resultado e desafio produzem conjuntos distintos nos casos em que os fatos diferem.
3. Evento com várias distâncias não classifica indevidamente um usuário como inscrito na meia/maratona.
4. Duplicidade de resultado, páginas do usuário ou registros de participação não duplica destinatário.
5. Fonte indisponível, dado ausente e janela sem cobertura não viram zero/inatividade.
6. Dados Strava e derivados não participam de filtros ou motivos comerciais.
7. Prévia/salvamento não envia; mudanças invalidam a revisão; novos elegíveis não entram em campanha já confirmada.
8. Confirmação repetida, concorrência, falha parcial e retomada não geram duplicações evitáveis.
9. Desativação, descadastro, dispensa e limite de frequência são revalidados antes da entrega/exibição.
10. Conteúdo e fluxo funcionam no desktop e no mobile, com navegação por teclado, labels e estados vazios/erro.
11. Card de uma conta não é servido a outra por cache. Cliques, impressões e conversões não são confundidos.
12. Publicação não dispara campanha; verificações externas de entrega usam somente destinatário de teste explicitamente autorizado.

Testar regras/consultas com cenários de domínio, contratos entre aplicações e transições da fila; compilar CFML com ferramenta disponível e verificar páginas reais autenticadas em desktop/mobile. Não declarar runtime validado somente por testes de texto sobre arquivos.

## 10. Implantação e reversão

Antes da alteração, conferir Git e baseline de produção por arquivo dos dois projetos. Preservar mudanças alheias. A preferência do Business autoriza publicação ao concluir runtime verificado, sem nova confirmação de deploy; não autoriza commits, branches, push, mudanças de credenciais ou migrações destrutivas.

Ordem: migrações aditivas revisadas → serviços/API e consumidor Road Runners inicialmente desativados → painel Business → verificações autenticadas → habilitação do módulo e capacidades aprovadas. Campanhas permanecem rascunhos até ação explícita no produto. Configurações ausentes que exijam credenciais/permissões são bloqueios específicos a relatar.

Preparar backup recuperável e manifesto apenas dos arquivos do escopo, incluindo hashes e metadados anteriores. Abortá-lo diante de divergência não conciliada. Após publicação, verificar hashes, HTTP, permissões e comportamento real, preservando recibo. Reverter runtime pelo backup e desativar o módulo se necessário; não apagar histórico ou tabelas para reverter uma implantação.

## 11. Estado da revisão

Especificação revisada quanto a escopo, proveniência, identidade, confirmação manual, falhas parciais, limites e compatibilidade. As dependências de fontes e canais têm comportamento definido quando indisponíveis; sua instalação/cobertura em produção será verificada antes de habilitá-las.

Próximo marco: revisão do plano de implementação com arquivos, contratos, testes e sequência executável. Não houve alteração de runtime, migração, envio, commit ou publicação nesta etapa.
