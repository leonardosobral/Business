# Central de Geolocalização dos Eventos

Data: 17/10/2026. Estado: plano e implementação aprovados no chat; código implementado e revisado. Migração administrativa a ser aplicada pelo usuário; processamento pausado até validação. Limites da entrega registrados no guia operacional.

## Objetivo aprovado

Preencher automaticamente latitude/longitude ausentes apenas quando houver evidência confiável do local da prova. Resultados limitados à cidade são sugestões privadas para revisão, nunca coordenadas publicadas automaticamente. Preservar coordenadas existentes e todas as mudanças de outras frentes.

O campo público atual é `public.tb_evento_corridas.coordenadas`, texto no formato `latitude,longitude`. Manter esse contrato; não alterar consumidores do Road Runners nesta entrega. Latitude e longitude ficam também separadas, como números, nos novos registros internos de proposta/auditoria.

Levantamento somente de leitura de 17/10: 34.734 eventos, 29.618 coordenadas vazias, 7.720 vazios com endereço, 12.167 vazios com código de cidade e um valor não vazio com formato/faixa inválidos. O diagnóstico foi arquivado fora do webroot em `/var/backups/business-geo-study-vawggdpg`; as contagens são um retrato, não valores fixos da interface.

## Escolha técnica e alternativas

Adotar Geoapify Forward Geocoding, com requisições exclusivamente no servidor. A API informa endereço estruturado, `result_type`, `rank.confidence` e confiança por nível. O fornecedor declara permitir armazenamento dos resultados. Não utilizar OpenAI para criar coordenadas nem consumir seus créditos.

Alternativas consideradas: base municipal isolada é barata mas insuficiente para a largada; Mapbox Permanent permite persistência, porém a API v6 não pesquisa POIs e exige habilitação comercial apropriada; o Nominatim público não é adequado como dependência desta rotina recorrente em volume. Não haverá fallback silencioso para outro fornecedor.

Referências consultadas:

- https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- https://www.geoapify.com/geocoding-api/
- https://myprojects.geoapify.com/help/api-keys/
- https://www.geoapify.com/pricing/
- https://docs.mapbox.com/api/search/geocoding/
- https://operations.osmfoundation.org/policies/nominatim/

## Fontes e consultas

1. Ler cidade/UF/país, `cod_cidade`, endereço, descrição original e descrição publicada do próprio evento. A cidade catalogada por `cod_cidade` auxilia a validação; divergências entre ela e o texto do evento exigem revisão.
2. Usar primeiro o endereço cadastrado. Extrair da descrição somente trechos explicitamente identificados como local de largada, concentração ou endereço da prova. Retirada de kits, sede de organizador, patrocinador e locais de outras edições não são candidatos automáticos. Múltiplos locais conflitantes exigem revisão.
3. Consultar endereço/local com cidade, UF e país. O nome da prova sozinho não estabelece um local. No máximo duas consultas específicas e uma consulta municipal por tentativa.
4. Quando houver coordenadas ou links de mapa explicitamente vinculados à largada, tratá-los como candidatos, não como autoridade: validar o par e conferir o contexto geográfico pelo fornecedor. Não seguir links encurtados nem buscar páginas arbitrárias nesta primeira versão.
5. Consultar a cidade separadamente quando não houver correspondência específica confiável. Reaproveitar o cache municipal para todos os eventos da mesma localidade.

Enviar ao fornecedor apenas os trechos públicos necessários à localização. Não enviar fichas médicas, perfis, contatos, tokens internos, HTML completo ou descrições integrais. Textos têm tamanho limitado; não executar instruções contidas neles.

## Política de confiança

Uma resposta só pode gerar `auto_applied` se satisfizer **todos** os critérios:

- Par numérico finito; latitude entre -90 e 90, longitude entre -180 e 180; rejeitar o par 0,0. Serializar com ponto decimal, ordem lat/lng e no máximo sete casas.
- País exato; UF brasileira equivalente e cidade identificável, normalizadas sem acentos e com aliases administrativos explícitos. A falta de cidade/UF no resultado, homônimos e conflitos não autorizam aplicação automática. País não é inferido pelo IP do servidor.
- `result_type` igual a `building` ou `amenity`; rua, CEP, bairro, distrito, município, estado e país não representam precisão suficiente.
- Confiança global >= 0,95 e confiança municipal >= 0,95. Para `building`, confiança de edifício >= 0,95 e número informado preservado. Para `amenity`, o nome deve corresponder integralmente ao local explícito, após normalização de pontuação/artigos, e não somente à cidade.
- Não haver outro candidato de pontuação próxima (diferença de confiança <= 0,05) que represente local diferente a mais de 100 metros. Empates não são decididos pelo primeiro item da API.
- A fonte não dizer “local a definir”, “em breve”, conter destinos incompatíveis ou ser insuficiente para estabelecer o local. Campos de confiança ausentes não recebem valor presumido.
- Fonte e coordenadas permanecem exatamente iguais ao snapshot utilizado. O campo de coordenadas ainda precisa estar nulo, vazio ou conter apenas espaços.

Esses limiares são política conservadora inicial, não garantia matemática da precisão nem percentual de probabilidade. Não são editáveis pelo operador nesta primeira entrega.

Resultados municipais ficam em `city_suggestion` com aviso “Localização aproximada da cidade — não é a largada”. Resultados específicos insuficientes/ambíguos ficam em `needs_review`. Falta total de informação fica em `insufficient_data`.

Nenhum resultado apenas municipal é gravado em `tb_evento_corridas.coordenadas`, nem por ação em lote. O administrador pode rejeitar a sugestão ou corrigir os dados do evento e reprocessar. Não haverá botão de aprovação de cidade como local da prova nesta versão.

Valores não vazios inválidos são listados como `existing_invalid`, sem correção automática. Coordenada existente válida sempre tem precedência, inclusive quando adicionada por outro processo após a consulta.

## Persistência e concorrência

Adicionar somente tabelas novas, por migração SQL versionada, sem remover estruturas ou alterar permissões existentes:

- `tb_evento_geocoding`: estado por evento/versão da fonte, snapshot, hash SHA-256, candidatos internos, precisão, motivos, tentativas, lease de processamento, próximo retry e timestamps.
- `tb_evento_geocoding_audit`: cronologia imutável de propostas, aplicação, revisão, rejeição, conflito e falha; valores antes/depois, método, fonte, ator humano ou job, timestamps com fuso.
- `tb_geocoding_cache`: consultas normalizadas e respostas mínimas necessárias, com fornecedor/versão, atribuição, validade e resultados negativos.
- `tb_geocoding_usage_daily`: reservas de chamadas por dia UTC e fornecedor; orçamento compartilhado entre cron, ações manuais e teste de conexão.

Não executar DDL na abertura de páginas ou em cada cron. Se o datasource não permitir a migração, manter a proteção e informar a etapa administrativa necessária; não trocar credenciais nem afrouxar o datasource para contornar a restrição.

Hash da fonte inclui ID, cidade, código da cidade, UF, país, endereço, descrição original/publicada e coordenada original, preservando distinção entre NULL e vazio. Uma proposta obsoleta não pode ser aprovada. Nova versão da fonte cria trabalho novo; uma versão concluída não é consultada repetidamente sem ação explícita.

Realizar HTTP fora de transações que bloqueiem eventos. A gravação final usa comparação exata do snapshot e atualiza apenas `coordenadas`, com auditoria na mesma transação. Se a condição falhar, registrar conflito e não alterar o evento. Lease com token impede dois workers de confirmar o mesmo trabalho; recuperação após dez minutos não permite que o worker anterior ainda aplique dados.

Cache positivo: 90 dias; negativo: 7 dias. Cache não modifica fontes manuais. Manter atribuições exigidas por cada resposta e exibi-las junto da proposta/mapa. Não persistir chave nem URL completa contendo chave em cache, auditoria, histórico do cron ou logs da aplicação.

## Rotina automática e limites

- Endpoint interno `POST /api/eventos/geolocalizar.cfm`, autenticado pelo padrão HMAC `business_internal` do cron existente; sem mutações por GET.
- Job cadastrado inicialmente pausado, sem outro agendador concorrente. Cadência planejada: cinco minutos; até cinco eventos por execução; orçamento total de 45 segundos; timeout individual de oito segundos e início de nova chamada apenas com margem suficiente.
- Padrão de 1.000 chamadas/dia UTC, teto configurável até 2.000. Reservar cada chamada atomicamente antes de enviá-la, inclusive retries e testes; orçamento zerado não chama o provedor. Requisições seriais, no máximo uma por segundo. Não consumir deliberadamente o limite inteiro do plano gratuito.
- Priorizar eventos ativos com início hoje ou no futuro; depois ativos em andamento pelo intervalo cadastrado; finalmente o acervo histórico. Inativos não entram automaticamente. Permitir simular a fila e informar quantos itens são de cada período.
- HTTP 401/403 interrompe novas consultas e informa configuração; HTTP 429 aplica cooldown e respeita `Retry-After`, com máximo de 24 horas; 5xx/timeout têm no máximo três tentativas, com intervalos de 5 e 30 minutos. Não repetir indefinidamente nem tratar erro do fornecedor como localização ausente.
- Resultado parcial mantém itens já confirmados e informa contadores de aplicados, sugestões, revisão, falhas e chamadas. Históricos não incluem segredos nem texto integral das fontes.
- Falta de chave/schema/desativação gera estado explícito no painel e impede processamento, sem registrar milhares de erros de eventos.

## Interface e autorização

Rota `/administracao/geolocalizacao/`, no menu de gestão de eventos, exclusiva de admins globais reais. Negar contexto delegado e usuários de contas; verificar autorização no servidor para leitura e escrita, não só no menu.

Abas com URLs diretas e navegação por teclado:

- **Fila:** contadores, busca por evento/cidade, filtros de período/UF/estado do processamento, seleção de até 20 IDs e ação de enfileirar. Enfileirar não faz lote de HTTP na requisição do navegador.
- **Revisão:** fonte utilizada, localização retornada, precisão, confiança, motivo, coordenadas separadas, atribuição, link/mapa de conferência e acesso ao cadastro do evento. Aprovar candidato específico exige confirmação e fonte atual; rejeitar exige motivo.
- **Histórico:** filtros por evento, ação, período e ator, com valores antes/depois e paginação no servidor. Não expor textos integrais em listagens.
- **Configurações:** ativação/pausa, limite diário dentro do teto, estado do cron e da credencial, consumo, explicação da política fixa e teste explícito de conexão (uma chamada contabilizada). Nunca mostrar/editar chave pelo formulário.

Todas as ações usam POST, CSRF da sessão e revalidação de privilégio. IDs e filtros são parametrizados; ordenações usam allowlist. Saídas do fornecedor/fontes são escapadas. Includes não são rotas públicas de consulta.

Usar recursos cartográficos já configurados no projeto sem reutilizar o token Geoapify no navegador. Se não houver mapa disponível, a revisão continua funcional com coordenadas e link externo de conferência. Nenhuma navegação do painel deve criar chamadas pagas de geocodificação.

## Configuração e entrega

Contrato planejado: variável `RR_GEOAPIFY_API_KEY`, com fallback privado `businessLocalConfig.geoapifyApiKey`. Não usar chave Google, OpenAI ou Mapbox como fallback. Ler configuração no servidor, sem exigir reset global desnecessário.

Usuário cria projeto Geoapify exclusivo, restringe chave ao IP real de saída do servidor e disponibiliza a chave por arquivo privado ou mecanismo de segredos. Não solicitar chave em mensagem nem gravá-la no Git. Configuração e validação da chave não autorizam contratação paga.

Até a chave ser configurada e validada, publicar o módulo como “Configuração pendente”, com o novo cron pausado. Após teste unitário explícito e inspeção das propostas, ativar apenas este job; não reativar/modificar outros jobs.

Preferência do repositório: publicar apenas runtime deste escopo após baseline, backup recuperável, testes e conferência real. Preservar toda a árvore suja. Não fazer commit/push sem solicitação específica. Backup de dados deve permitir desfazer somente coordenadas aplicadas por este job, e apenas se ainda coincidirem com o valor da auditoria e com a fonte usada.

## Verificação e aceite

Testes com fornecedor simulado precedem código: cidade/UF homônimas, número divergente, resultado só de rua/cidade, confiança ausente/baixa, múltiplos candidatos, fonte “a definir”, kit confundido com largada, campos estrangeiros, par fora da faixa/0,0, resposta malformada/HTML e segredos em exceções.

Integração: preservar coordenada manual/concorrente; invalidar proposta após editar endereço; aplicação e auditoria atômicas; lease expirado sem confirmação antiga; limite diário e cooldown compartilhados; cache; idempotência; negativa 403/CSRF; GET sem escrita; lote paginado limitado e acessibilidade das abas.

Antes de afirmar publicação: conferir hashes e baseline; backup; migração não destrutiva no papel autorizado; teste no ColdFusion efetivo; página autenticada global; acesso anônimo e usuário de conta negados; cron pendente de credencial quando aplicável; nenhum evento preenchido com centro de cidade. Registrar separadamente o que foi testado com simulação e o que foi validado com fornecedor real.

## Fora do escopo

Alterar coordenadas já preenchidas, corrigir cidades/datas dos eventos, rastrear usuários, usar dados médicos, raspar sites/fontes arbitrárias, publicar sugestões municipais, autocompletar endereços no RR, reformular mapas públicos, autoaprovar locais de baixa confiança, trocar credenciais/permissões existentes ou contratar plano pago.
