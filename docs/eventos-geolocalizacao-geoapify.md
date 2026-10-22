# Configurar Geoapify para a geolocalização de eventos

Módulo publicado em 17/10/2026. Configuração atualizada em 19/10/2026: cron **25 a cada minuto**, até cinco eventos por lote, teto compartilhado **3.000 consultas/dia UTC** e **uma por segundo**. Lease tokenizado no banco impede lotes concorrentes; timeout e tentativas permanecem limitados. Não é necessário deixar o painel aberto. A elevação do teto preserva o contador já consumido no dia, sem reiniciá-lo.

O cache v2 não confunde pontuações distintas de endereços e permite concluir resultados já conhecidos durante pausas do fornecedor. Entradas antigas v1 deixam de ser reutilizadas porque não comprovam a correspondência exata entre consulta e resposta; não são apagadas. O cache de fontes oficiais e robots permanece válido. Uma cidade não é consultada novamente quando já existe um candidato específico para revisão. Todos os resultados ainda passam por verificação de fonte, região, precisão e integridade do cadastro.

Falhas temporárias retornam JSON com status explícito e HTTP 202 enquanto há tentativa agendada; isso não significa que o local foi identificado. Erros terminais/internos continuam visíveis como falha e problemas de configuração retornam 503. Os 502 anteriores coincidiam com consultas não concluídas no timeout de 8s; agora o cliente aguarda até 15s, dentro do orçamento de 45s por lote.

## Situação da sua configuração

- Projeto **Business — Geolocalização de eventos** conferido no navegador interno.
- Chave exclusiva instalada no arquivo privado do servidor, preservando as demais integrações; sem reinício do ColdFusion.
- Restrição autorizada: IP de saída **172.233.2.76**. Referrers e origins de navegador removidos, pois esta integração faz chamadas no servidor.
- Nenhuma chave no HTML, JavaScript, Git ou históricos. O primeiro lote real gerou cinco sugestões municipais, sem publicar coordenadas aproximadas.
- A migração foi detectada e validada após sua escolha de aplicá-la pela ferramenta PostgreSQL. O agente não executou DDL nem alterou a proteção do datasource.
- Teste real: Parque Ibirapuera identificado como local específico; São Paulo identificado apenas como município. As duas consultas não modificaram eventos.
- Execução manual do cron 25: HTTP 200, sucesso em aproximadamente 7,5 segundos. Recorrência ativada somente após esta verificação.

## Pesquisa autônoma de fontes (publicada e validada, 17/10/2026)

O processamento ampliado lê automaticamente as páginas oficiais e de inscrição vinculadas ao evento e segue links explícitos de regulamento/site oficial. Interpreta HTML, dados estruturados Event/JSON-LD e até 12 páginas de PDFs textuais. Confere nome e data da edição antes de usar uma localização externa. Retirada de kits, edição diferente, locais conflitantes e resultados só municipais não são publicados.

O extrator é limitado em tempo, tamanho e profundidade. Respeita bloqueios de coleta e autenticação; não contorna captcha/antibot. Não usa busca genérica paga nem instala OCR. Para eventos sem fonte vinculada, páginas inacessíveis, cartazes ou PDFs sem texto legível, mantém a cidade ou a situação de dados insuficientes e continua o restante do acervo. Não é garantia de que todo local da internet será descoberto.

Validação real: evento **49279 — Corre Cidade + Movimente-se: Edição Especial Outubro Rosa**. O worker identificou a edição de 17/10/2026 na Sympla, extraiu **Shopping Cidade, Rua dos Tupis, 337**, validou amenity/endereço/município com confiança 1,00 e aplicou **-19.9220057,-43.9400589**. Uma chamada Geoapify; coordenadas não foram digitadas pelo agente. [Evidência e mapa no painel](https://business.roadrunners.run/administracao/geolocalizacao/?aba=revisao&id=293&periodo=todos). Trata-se da localização do estabelecimento informado, não de medição de um tapete de largada/portão.

Propostas da versão anterior ficam fora da revisão rápida enquanto aguardam a reanálise automática com fontes. Sugestões municipais continuam privadas e separadas. Não há nova etapa obrigatória de configuração, SQL ou credenciais para esta ampliação.

Na versão inicial, a pesquisa de fontes não usava IA. A versão atual usa Astra para interpretar prova, kit e atributos, com até 1.000 análises OpenAI/dia e 3.000 consultas Geoapify/dia. O cron executa a cada minuto e o acervo é gradual, não instantâneo. Não é necessário selecionar todos os eventos nem manter o navegador aberto. Históricos entram após próximos/em andamento, inativos por último. A nova versão reanalisa automaticamente versões antigas; nunca substitui automaticamente campos ou coordenadas já preenchidos.

## Como usar agora

1. Abra [Geolocalização](https://business.roadrunners.run/administracao/geolocalizacao/) em **Gestão do evento**, no contexto global.
2. **Cobertura do Radar:** acompanhe os eventos futuros ativos e públicos classificados como confirmados, legados, suspeitos ou sem coordenadas. O painel mostra cobertura total, horizontes de 30 e 90 dias, distribuição por UF e uma listagem filtrável para diagnóstico. Ele é somente leitura: não publica, não reprocessa e não chama fornecedores.
3. **Fila:** filtre por evento, cidade, UF, período ou situação. Selecione até 20 itens para enfileirar/reprocessar; a ação não consome consultas imediatamente. A seleção automática prioriza eventos ativos sem coordenadas nos próximos 30 dias, depois os de 31 a 90 dias, os posteriores, itens em processamento, demais ativos e, por último, inativos. Cada execução continua limitada a cinco eventos.
4. **Revisão rápida:** abra Detalhes para conferir fonte, precisão, confiança e mapa. Use **Aprovar e próxima**, **Descartar e próxima** ou **Pular para próxima**. Há confirmação; a observação é opcional. Autor, horário e ação são sempre auditados.
5. **Sugestões de cidade:** ficam separadas, sem revisão obrigatória. Uma cidade nunca pode ser aprovada como largada nem preencher coordenadas públicas. Se surgir uma fonte/local melhor, atualizar o cadastro gera nova versão na automação; também é possível enfileirar explicitamente para reprocessar.
6. **Histórico:** acompanhe aplicações, revisões e conflitos. **Configurações:** acompanhe consumo e pause o preenchimento se necessário.

## Contrato com o Radar público

Business e Road Runners leem e escrevem o mesmo evento em
`public.tb_evento_corridas`. A Central publica uma localização canônica em
`localizacoes.evento` e no campo legado `coordenadas`; a trigger compartilhada
do Road Runners normaliza esse par para `latitude` e `longitude`. Não há webhook,
segunda fila nem cópia de coordenadas entre os dois produtos.

O diagnóstico do painel usa quatro classes administrativas:

- **Confirmado:** coordenada válida que corresponde à localização canônica com
  precisão `local_confirmado`;
- **Legado:** coordenada válida sem proveniência estruturada suficiente;
- **Suspeito:** `0,0`, divergência entre representações, divergência da
  localização confirmada ou compartilhamento por eventos de cidades/UFs
  diferentes;
- **Sem coordenadas:** par ausente, incompleto ou fora das faixas geográficas.

Essas classificações não são enviadas aos visitantes. O Radar público aceita
confirmados e legados válidos, exclui explicitamente `0,0` e nunca usa uma
sugestão municipal como ponto de largada. Coordenadas suspeitas permanecem
visíveis apenas no diagnóstico administrativo para correção editorial.

Em 20/10/2026, o contrato foi validado em transações com rollback: evento sem
coordenadas permaneceu ausente, sugestão municipal continuou privada, a trigger
preencheu as colunas numéricas e uma localização canônica passou a ser
classificada como confirmada. Nenhum fornecedor foi chamado e nenhum evento
real foi alterado. A suíte completa do módulo também passou sem regressões.

[Histórico do cron 25](https://business.roadrunners.run/administracao/cron-jobs/?aba=historico&historico_job_id=25#historico-recente).

Não há nova etapa obrigatória de configuração do Geoapify neste ambiente. As instruções abaixo ficam como referência de instalação e recuperação.

## Referência: migração do banco de dados

Conecte sua ferramenta PostgreSQL ao banco **runnerhub** de produção. Execute os arquivos completos, nesta ordem:

1. [schema.sql](/Users/geraldoprotta/IdeaProjects/Business/administracao/geolocalizacao/schema.sql): cria somente as quatro tabelas deste módulo e seus índices. O script usa uma transação e o papel já existente `runner_dba` para que os novos objetos pertençam à aplicação; não muda grants, senhas ou configurações existentes. Se sua conexão não puder assumir esse papel, pare e informe o erro, sem criar permissões novas.
2. [geocoding_job.sql](/Users/geraldoprotta/IdeaProjects/Business/administracao/geolocalizacao/geocoding_job.sql): cadastra apenas o novo cron, **pausado**, a cada cinco minutos. Não altera jobs existentes.

Em outra instalação, execute os testes transacionais de integração, o teste real da chave e confira propostas antes de ativar. No ambiente atual, esses testes já passaram; o cron foi cadastrado e ativado pelo fluxo normal, sem necessidade de executar novamente estes SQLs.

Painel: [Geolocalização no Business](https://business.roadrunners.run/administracao/geolocalizacao/). Acesso exclusivo de admins globais reais, não de contas nem contexto delegado.

## Sua parte: conta e chave

1. Abra [Geoapify MyProjects](https://myprojects.geoapify.com/) e crie/acesse uma conta da empresa. Confirme o email, se solicitado. Não é a conta OpenAI e não utiliza seus créditos.
2. Clique em **Create a project** e dê o nome **Business — Geolocalização de eventos**. A criação gera a primeira chave; mantenha uma credencial exclusiva deste uso. [Guia oficial](https://www.geoapify.com/get-started-with-maps-api/).
3. O plano gratuito anuncia **3.000 créditos/dia**, sem cartão. Começar por ele não exige contratar plano pago. Acompanhe o consumo em **Statistics**; confirme o plano em **Billing**. As condições são do fornecedor e podem mudar. [Planos atuais](https://www.geoapify.com/pricing/).
4. Na área **API keys**, configure a restrição de **IP de saída do servidor**. Esse IP precisa ser confirmado no ambiente de produção antes de salvar a restrição. Não use o IP do Cloudflare, seu IP residencial ou restrição de domínio/HTTP referrer própria de chamadas de navegador. [Ajuda oficial de segurança da chave](https://myprojects.geoapify.com/help/api-keys/).
5. Guarde a chave em um arquivo privado local, por exemplo `BusinessGeoapify.txt`, fora do repositório. Para instalação assistida, informe somente o caminho do arquivo, não cole o conteúdo na conversa. O arquivo não deve ser anexado a tickets nem incluído em commit.

Não é necessário criar chaves OpenAI, habilitar APIs Google ou informar cartão para a preparação inicial.

## Configuração privada no servidor

Configurações aceitas pelo módulo:

- Preferência: variável de ambiente `RR_GEOAPIFY_API_KEY` disponível ao processo ColdFusion.
- Alternativa: propriedade `geoapifyApiKey` no objeto já existente de `config/business.local.cfm`, arquivo privado e não versionado.
- A chave será usada apenas pelo servidor, nunca por JavaScript/HTML público.

Não substitua o arquivo inteiro de configuração: ele contém as demais integrações. Não altere o ambiente do ColdFusion nem reinicie o serviço sem verificar a necessidade. A alternativa por arquivo privado será lida por requisição pelo novo módulo.

Sequência de ativação, após a migração:

1. Instalar a chave pelo mecanismo privado escolhido.
2. Abrir `/administracao/geolocalizacao/?aba=configuracoes` como admin global.
3. Executar **Testar conexão**: uma consulta real, contada no limite diário.
4. Conferir uma proposta específica e uma sugestão municipal; esta última não deve preencher coordenadas.
5. Habilitar o preenchimento nas Configurações e ativar somente o novo job após esses testes. Limite inicial: 1.000 chamadas/dia, até cinco eventos por execução a cada cinco minutos.

Sem chave ou antes da validação, o módulo deve permanecer em **Configuração pendente**, com o cron pausado. Não haverá cobrança causada por apenas abrir a tela.

## Limites desta entrega

- Sugestões de cidade não têm botão de aprovação como largada e não são tarefas obrigatórias da revisão rápida.
- Coordenadas já existentes, mesmo inválidas, não são substituídas automaticamente.
- Endereços de largada indefinidos ou conflitantes não são aplicados automaticamente. Revisão aceita observação opcional e não exige texto para aprovar/descartar.
- Links de mapa e pares de coordenadas no texto ainda não recebem extração geográfica dedicada. Nenhum link é seguido automaticamente; nesses casos informe um endereço/local explícito.
- O histórico tem busca por evento/cidade e UF; filtros por autor, ação e intervalo de auditoria ficam pendentes. O filtro Período se refere às datas do evento.
