# Lote: evidências de tradução, acesso e audiência de IA

Continuação autorizada do plano SEO/SEO para IA. O fluxo existente do painel será ampliado com medições complementares datadas; pesos e histórico técnico permanecem iguais. Implementação no Business; Road Runners e Open Results são fontes de leitura nesta etapa. Publicar somente os snapshots e o texto do relatório afetados, com baseline, backup, compilação e conferência real. Sem Git ou alterações de credenciais, WAF, logging ou políticas de treinamento.

## Escopo aprovado e critérios

1. Conferir seis descrições de eventos futuros e históricos Road Runners em PT/EN/ES. Medir as doze versões EN/ES contra as respectivas fontes PT usando a região efetiva da descrição e sua anotação de idioma; não confundir template traduzido com descrição traduzida. Guardar somente URL, idiomas, tamanhos, hashes e status. Qualidade/fidelidade permanece separada e não medida.
2. Ler logs HTTP existentes e faixas IP oficiais atuais dos provedores. Não atribuir tráfego a um site sem hostname confiável; não inferir que a ausência de logs na origem significa ausência de bloqueios na CDN. Exibir limitações observadas, preservando proteções.
3. Usar a audiência própria já existente para referências de assistentes, com agregados de sete dias, somente produção, sem tráfego interno, por hostname e referrer_host exato. Identificar cobertura ausente Open Results e distinguir origem declarada de citação/conversão.
4. Encerrar OR-02 somente após robots público e noindex efetivos. Atualizar painel/filas, revisar o lote com Astra, testar, compilar/publicar o escopo e verificar HTML e snapshots entregues.

## Decisões e evidências iniciais

Ruling: staging independente, sem worktree Git — o usuário proíbe criar branch/commit sem pedido; preservar arquivos de outras frentes.

Ruling: preservar o cron pausado enquanto se esclarece a intenção — a leitura do cadastro mostrou job15 inativo desde 25/09, intervalo10min e último http_error. A autorização para continuar SEO não deve desfazer uma possível pausa deliberada de outra frente. Pergunta assíncrona enviada; diagnóstico continua em leitura.

Ruling: logs compartilhados não comprovam acesso por site — ambos os vhosts TLS escrevem access.log/combined sem hostname; o log vhost_combined global está vazio. Road Runners tem CF-Connecting-IP com22 proxies confiáveis; Open Results não tem normalização equivalente. Nenhuma configuração será alterada neste lote.

- Baseline Business: oito arquivos recuperados; dois snapshots coincidem com o checkout. O staging inicial teve NameError apenas ao imprimir a contagem, depois de salvar baselines e evidência; arquivos preservados.
- Open Results: em03/10 o cache expirou; robots público coincide com o candidato da origem. Verificação existente confirmou dois caminhos individuais com noindex e home/evento sem noindex, hashes2 e seis dependências preservadas.
- Cadastro: 34.320 eventos ativos; 5.465 descrições PT, 2.327 EN e 4.559 ES armazenadas. Esses números não comprovam publicação, frescor nem qualidade.
- Audiência: fonte própria existe e contém referências de IA; consulta inicial retorna apenas agregados. Confirmar page_view e sessões distintas antes de publicar a medição.

## Registro de execução

- Tarefa1: pendente (coleta pública e testes).
- Tarefa2: pendente (faixas oficiais e limites dos logs).
- Tarefa3: pendente (agregados finais e interpretação).
- Tarefa4: pendente (painel, revisão, publicação e verificação).

- Tarefa1: complete — parser limitado à região event-info-copy com lang; metadados sem corpo; oito testes Python RED→GREEN. Coleta18URLs em seis eventos, doze versões alvo:5pass,1warning (fallback PT),6unknown (fonte sem descrição marcada). Amostra dirigida, não representativa; fidelidade separada.
- Tarefa2: complete no escopo de leitura — nove logs,3.013.612 linhas, cinco faixas oficiais atuais; só agregados. Logs combined sem host impedem atribuição por site; normalização IP desigual preservada. Acesso real por domínio permanece não medido. Bloqueios na borda não observáveis na origem.
- Tarefa3: complete — produção, não interno,7dias exatos:17.329 page_view_id e6.981 sessões distintos Road Runners;66 pageviews e36 sessões com referrer_host exato ChatGPT. Open Results sem cobertura na fonte, não zero. Conver­sões e citações separadas e não medidas.
- Diagnóstico adicional: cinco últimas execuções25/09 retornam424/provider_quota_exhausted, extraído sem resposta bruta. Cron15inativo atualizado21:20; saldo atual não consultado. Fila:654EN/655ES prontas;2.497EN/257ES rejeitadas;1.535PT prontas. Não reativar, consumir créditos ou reprocessar rejeitados neste lote.
- Ruling: conservar a amostra dirigida com três fontes sem descrição marcada — registrar seis versões inconclusivas, sem escolher somente páginas favoráveis. Custo se errado: reduzir cobertura útil; não atribuir êxito a páginas sem evidência.
- Interface: versão schema1, datas/escopos próprios; leitura padrão de evidence/latest.json conserva as medições nas próximas gerações. Metadados inválidos abortam a geração; score técnico e histórico intactos.65 testes Node e9 cenários CFML verdes.
- Tarefa4: implementação concluída; revisão final Astra, compilação, publicação e conferência real pendentes. Candidato16/13/3; nota70RR/100OR; ORauditnovo19:14BRT.

- Final: fixed Important de Astra — idioma divergente aninhado poderia ser aprovado. Regressões Python/Node observadas RED→GREEN;67Node/10Python verdes. Campo booleano obrigatório invalida evidências antigas; recolher mesma amostra antes de publicar. Nenhum minor apontado. Fonte ou destino com conflito fica inconclusivo; mesmo idioma e elementos ocultos preservados.

- Tarefa4: complete — candidato revisado/corrigido, coleta repetida19:28BRT,67Node/10Python/9CFML verdes;3templates Adobe compilados e publicados com backup,3hashes/5dependências conferidos. Render real16/13/3,32checks com notas/datas exatas; fixture loopback removida. Previewdesktop1280/mobile390 sem overflow, viewport/tab/servidor encerrados. Runtime local sincronizado somente nos3arquivos após checar baseline/candidato.
- Pendências preservadas no produto: SH-02 fatos/organizadores, RR-08 política editorial e RR-11 cron/descrições. Pergunta sobre intenção da pausa sem resposta até a conclusão; cron preservado. Saldo atual não medido. Logs sem host, cobertura OR de audiência, fidelidade, citações e conversões continuam não medidos nos respectivos checks.
