# Local da prova, retirada de kit e enriquecimento do evento

O cron 25 mantém execução a cada minuto, até cinco trabalhos e 45 segundos por lote. A fila v3 também pesquisa eventos que já têm coordenadas, para descobrir o local do kit. Não é necessário manter a página aberta.

## Interpretação

- Usa a chave da integração OpenAI já existente, sem outra credencial. Desde 19/10/2026, modelo próprio `gpt-6-astra`, com `reasoning.effort=low`; não muda o modelo da Vicky nem dos demais módulos. A mesma resposta estruturada pesquisa prova, kit e atributos do evento, com cache separado por modelo e versão do contrato. Análises antigas sem atributos passam uma vez pelo contrato novo; checkpoints completos de enriquecimento são retomados sem repetir a chamada paga.
- Lê páginas oficiais, de inscrição e `url_regulamento` cadastradas, além de regulamentos vinculados nessas páginas. Respeita robots, limita documentos/bytes/tempo e bloqueia endereços privados/credenciais nas URLs. Não pesquisa qualquer página da internet nem faz OCR de PDFs escaneados.
- IA retorna apenas fatos e trechos literais. O servidor confere edição, finalidade, endereço, cidade/UF e evidência. Kit/expo não implica largada.
- Geoapify confirma cada local em sua própria cidade/UF. Apenas pontos específicos confiáveis são gravados; a cidade fica como sugestão privada. Locais indefinidos, conflitantes ou sem confirmação não são presumidos.

## Dados e segurança

`tb_evento_corridas.localizacoes` armazena `evento` e a lista `kit`, com `nome_local`, `endereco`, `cidade`, `uf`, `pais`, `coordenadas`, `fonte` (URL, trecho, hash da fonte, edição), `confirmado_em`, `autor` e `precisao`. O campo legado `coordenadas` continua sendo só o da prova. Campos existentes não são sobrescritos.

Aplica-se a migração aditiva `administracao/geolocalizacao/migration_ai_locais.sql` pela ferramenta administrativa de banco; não há DDL runtime. Fonte, destinos e token são conferidos em transação antes da aplicação. Cada ação gera auditoria. Alteração concorrente invalida a proposta.

Etapas concluídas ficam em checkpoint e cache para evitar nova análise paga ao retomar. OpenAI: até 1.000 análises/dia UTC, entrada limitada e saída até 6.000 tokens para comportar os atributos; requisições com `store=false`, sem ferramentas. Geoapify: teto compartilhado de até 3.000 consultas/dia UTC, uma por segundo, somando prova e kit (aumento solicitado em 19/10/2026). Falhas e quotas preservam a fila; não há aumento automático de limites. Atributos confiáveis são persistidos antes da geocodificação, mesmo durante a espera pela cota do Geoapify. O contador diário não é zerado ao aumentar o teto; consultas adicionais só são reservadas até o novo saldo disponível.

## Enriquecimento

Campos nativos permitidos: cidade, UF, país, endereço da prova, datas inicial/final, organizador, tipo de corrida e URLs de inscrição, site oficial e regulamento. Dados complementares em `localizacoes.enriquecimento.fields`: horários de largada, modalidades/distâncias, programação do kit, período/plataforma de inscrição, preços/lotes com validade explícita, regras de participação, contatos públicos, redes sociais e estrutura/acessibilidade. Preços informativos não substituem a tabela comercial existente. Não há nova migração SQL.

Somente vazios são preenchidos automaticamente. Cada fato exige citação literal, contexto adequado e identidade da edição; confiança declarada pela IA não basta. Estado por extenso e UF, país por extenso em português/inglês/espanhol e código ISO são comparados por equivalência segura. Siglas não são extraídas de preposições e nomes curtos não se confundem com regiões maiores. Valores equivalentes não geram revisão nem sobrescrita.

Divergências reais preservam o cadastro. Em **Dados do evento**, a revisão mostra atual, proposto e fonte, com **Aceitar fonte** ou **Manter cadastro**, sem justificativa obrigatória. Aceite exige fato confiável e confirmação explícita; fatos ambíguos não podem ser promovidos. Aprovar alteração geográfica, data ou fonte invalida a análise de localização antiga antes de retomar. Edição concorrente ou revisão vencida bloqueia a aplicação. Cada campo preenchido guarda fonte, trecho, hash, edição, autor e timestamp. A chave original do trabalho é imutável; o snapshot pós-aplicação permite retomada sem conflito nem duplicação de auditoria.

## Operação

Em `/administracao/geolocalizacao/`, as abas **Prova e kit** e **Dados do evento** separam as tarefas. Conferir a fonte e o mapa, aprovar ou descartar o local, sem justificativa obrigatória. A revisão exige admin global, CSRF, confirmação e revisão atual. Uma cidade não pode ser promovida a largada. O cadastro do evento mostra os locais e dados complementares confirmados com suas fontes. Conteúdo antigo, de patrocinador ou da retirada de kit não autentica dados da prova.

Se não houver local confiável nas fontes, não há preenchimento automático. É possível atualizar os links/dados do evento e reenfileirar até 20 selecionados. Erros de OpenAI são exibidos de forma sanitizada, sem chave ou conteúdo bruto do fornecedor.
