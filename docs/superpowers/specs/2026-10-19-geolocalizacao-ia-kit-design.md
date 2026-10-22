# Interpretação OpenAI e localização independente de kits

Solicitação: interpretar fontes oficiais com a integração OpenAI existente, distinguir largada/prova de kit/expo e registrar ambos os locais no evento. Testar e publicar. A dispensa prévia de novas aprovações de planejamento permanece; não inclui contornar a proteção DDL do datasource. Execução inline, preservando os arquivos de outras frentes e sem operações Git.

## Contrato

- OpenAI extrai fatos, nunca inventa coordenadas. Reutilizar a integração `application.vickyKnowledge` explicitamente indicada pelo usuário; nenhuma chave nova ou alteração de credencial. Modelo de extração do módulo: `gpt-4.1-mini`, sujeito a validação real; não altera o modelo da Vicky. Mostrar modelo/consumo no painel.
- Documentos são dados não confiáveis, sem ferramentas ou instruções executáveis. Somente fontes oficiais/de inscrição/regulamento vinculadas ao evento, obtidas pelo leitor público já protegido contra SSRF, redirects e robots. Incluir `url_regulamento`, além dos dois links existentes. HTML e PDF com texto; sem bypass, OCR ou busca genérica paga.
- Resposta estruturada estrita: identificação da edição (nome/data), locais classificados como `evento` ou `kit`, cidade, UF, país, nome do local, endereço, trechos literais e índice de documento. Data/identidade, existência literal da evidência e finalidade são conferidas pelo servidor. Não aceitar URL/fato livre produzido pelo modelo.
- Retirada de kit/expo NÃO implica largada. Só coincidem quando a fonte informa expressamente os dois usos. Local indefinido, edições antigas, conflitos, múltiplos locais sem identificação clara e fatos sem evidência não são aplicados automaticamente.
- Geoapify valida cada local separadamente, com os mesmos critérios de precisão/confiança atuais. Kit pode estar em outra cidade/UF, mas sua região deve estar comprovada na fonte e ser confirmada pelo fornecedor. Cidade isolada continua sugestão privada, nunca coordenada canônica do evento/kit.

## Persistência e concorrência

- Coluna aditiva `tb_evento_corridas.localizacoes` JSONB, com chaves `evento` e `kit` (lista de locais quando confirmados separadamente), campos `nome_local`, `cidade`, `uf`, `pais`, `endereco`, `coordenadas`, fonte/evidência e timestamp. Não reaproveitar preços/observações para armazenar dados geográficos.
- `coordenadas` legado continua representando exclusivamente a prova; nunca recebe o ponto do kit. Dados existentes não são sobrescritos. Fatos de endereço confirmados podem ser armazenados sem coordenadas, com estado explícito; pontos aproximados ficam só na proposta.
- Fila v3 na tabela existente: fingerprint dos insumos externos, snapshot dos destinos, checkpoints para análise e consultas parciais, token e revisão. Lock do evento, fonte atual, lease e snapshot dos destinos conferidos antes de qualquer gravação; auditoria permanente dos dois locais.
- A automação alcança eventos já geolocalizados, pois podem faltar dados do kit. Mantém próximos eventos como prioridade e prossegue pelo histórico. Alteração dos insumos gera nova versão; aplicação automática não cria loop de reprocessamento.
- Reutilizar as travas e reservas compartilhadas: cron 25 por minuto, lote limitado a 45s, até 2.000 consultas Geoapify/dia e 1/s, somando prova e kit. Cache por fonte/modelo/prompt e checkpoint evita repetir chamadas após adiamento.
- Limite OpenAI próprio, padrão 1.000 análises/dia UTC, com contagem antes da chamada, limite de entrada/saída e pausas em 429/5xx. Erro de IA não deve transformar ausência de resposta em ausência de local; preservar fila/checkpoint. Sem aumento automático de limites.

## Interface

- Painel mantém abas, filtros e revisão rápida sem justificativa obrigatória. Detalhes v3 apresentam Prova e Kit separadamente, evidências e estado por local, sem permitir aprovar cidade. Revisão é por alvo e revisão da proposta, com CSRF/admin global.
- Cadastro do evento exibe os locais gravados e sua proveniência separadamente; não altera permissões dos demais recursos. Nenhuma mudança no portal público nesta tarefa.
- Se a migração ainda não foi aplicada, preservar o módulo anterior em produção. Não publicar substituição que interrompa o cron existente.

## Aceite

Fixtures com largada/kit distintos, mesma localização explicitamente declarada, kit em outra cidade, fonte antiga, prompt injection, citações inventadas, conflitos e resultado municipal. Integração transacional prova gravação correta, não sobrescrita, CAS e auditoria; falha/quota/adiamento não repete chamadas concluídas. Teste OpenAI real limitado, Geoapify contado e exemplo de fonte real antes da ativação. Backup, baseline e verificação pós-publicação.
