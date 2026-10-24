# Road Runners — meta acima de 80% no Semrush, 22/10/2026

## Escopo e referência

Objetivo solicitado: superar 80% de Site Health com melhorias reais. Campanha 26661911, limite de 5.000 páginas, rastreador móvel e renderização JavaScript desativada. Nenhuma exclusão de verificações/URLs, mudança da amostra configurada ou flexibilização de privacidade, autenticação ou Cloudflare.

A última coleta concluída consultada no início do trabalho era de 21/10: 71% de Site Health, 79% no estado de pesquisa IA, 63 erros e 33.179 advertências. Antecede as correções de títulos e dependência do menu de 21/10. Nova auditoria iniciada após publicar o rodapé em 22/10; a nota ainda está pendente. Não interpretar os números anteriores que permanecem visíveis durante o rastreamento como resultado desta execução.

## Publicado

### Atalhos pessoais no rodapé

Visitantes recebiam links para seis áreas que exigem autenticação e redirecionavam ao login. O rodapé agora aponta diretamente ao contrato existente `/login/?redirect=<rota local codificada>`; o destino após entrar permanece o mesmo. Pessoas já autenticadas mantêm os links diretos, incluindo a própria tag de perfil. Os destinos públicos não mudaram. Nenhum backend ou controle de autenticação foi alterado.

Arquivo: `includes/estrutura/footer.cfm`. Produção continha adições de Radar ausentes no checkout; foram preservadas no candidato publicado e não importadas ao código local. Publicação às 14:29 UTC. Recuperação: `/var/backups/seo-rr-80-20261022-nav/footer-before.cfm` e manifesto no mesmo diretório.

Verificações: 90 cenários Adobe ColdFusion (PT/EN/ES, visitante e autenticado), compilação de um template, 36 links em seis páginas reais e sete respostas HTTP 200, incluindo login com retorno. Oito dependências preservadas por hash. A primeira verificação de login usou HTTP local e encontrou o redirecionamento HTTPS; foi corrigida para HTTPS com resolução local, preservando o certificado e as proteções.

### Descrições de notícias e títulos por função

Quando faltam resumo e descrição editorial, a notícia usa seu título real como alternativa à descrição genérica compartilhada. Resumos e descrições cadastrados mantêm a prioridade. Apenas o valor final do atributo HTML é codificado; o texto do Article JSON-LD permanece simples.

As páginas de organizador e cronometragem conservam o nome cadastrado e acrescentam o contexto da função ao título. Nenhuma URL/cadastro foi unida, removida ou marcada como não indexável. A distinção de títulos não demonstra por si só a resolução de um eventual alerta de conteúdo duplicado.

Arquivos: `noticias/index.cfm`, `org/index.cfm`, `timer/index.cfm`. Publicação às 14:49 UTC, durante o rastreamento; parte das páginas pode ter sido lida antes dessa entrega. Recuperação: `/var/backups/seo-rr-80-20261022-metadata/baseline`, com manifesto e guardas de concorrência.

Verificações: 23 cenários Adobe, incluindo prioridade de resumo/descrição e nomes com aspas/HTML; três templates compilados. Onze páginas reais HTTP 200, com oito descrições de notícias distintas do texto genérico e dois títulos de função diferentes. Canonical, robots e núcleo dos dados estruturados (incluindo datas e identidade) preservados. Quatro dependências preservadas por hash.

Suite Node relacionada: 16 de 17 passaram. A falha é preexistente no contrato de contagem de marcadores de notícias em `api/home_news.cfm`, confirmado idêntico ao HEAD e fora do lote. O teste espera dois marcadores onde há um; não foi alterado para satisfazer a verificação. As verificações específicas das mudanças passaram. `git diff --check` sem problemas.

## Diagnóstico complementar

As oito URLs classificadas como lentas na coleta de 21/10 receberam duas medições sequenciais na origem, todas HTTP 200, entre 0,048 s e 2,809 s. Isso não reproduziu a lentidão acima de três segundos nessa janela, nem comprova disponibilidade contínua, desempenho da borda, Core Web Vitals ou resolução no fornecedor. Não houve alteração de cache, consultas ou infraestrutura por esse achado.

HTML das páginas públicas contém blocos estáticos repetidos significativos. Externalização e cache são possibilidades posteriores caso o resultado da nova coleta justifique outro lote; não foram publicados apenas para mudar a nota.

## Controle

Staging e recibos: `Business/_codex/staging/seo-rr-80-20261022/`. Nenhuma migração, atualização de datas/cadastros, alteração de acesso ou operação de escrita Git. O arquivo de trail run e mudanças de outras frentes foram preservados. O painel só deve receber uma nova nota após confirmação da auditoria concluída; a coleta orgânica mantém sua data própria.
