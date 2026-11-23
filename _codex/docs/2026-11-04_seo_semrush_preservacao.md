# Preservação Semrush — auditorias de 20.000 páginas

Solicitação de 04/11/2026: preservar o máximo dos dados das auditorias Road Runners e Open Results antes do fim da assinatura, para continuar as correções no Business.

## Dados preservados

| Site | Data informada da auditoria | Configuração | Site Health | IA | Erros | Advertências | Observações |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Road Runners | 04/11/2026, precisão de dia | 20.000/20.000; móvel; JS desligado | 72% | 76% | 305 | 22.051 | 17.520 |
| Open Results | 03/11/2026, precisão de dia | 20.000/20.000; computador; JS desligado | 76% | 79% | 1.166 | 74.693 | 20.917 |

Fonte: campanhas 26661911 e 31744040 na interface autenticada do Semrush. Não havia conector Semrush disponível nesta sessão; foram usados os botões de exportação no Chrome, sem iniciar novas auditorias nem comprar recursos. O fornecedor sinaliza mudança de configuração desde a rodada anterior. Não atribuir a diferença de notas inteiramente a regressões ou comparar amostras como se fossem idênticas.

Foram preservados **62 CSVs originais (47.527.342 bytes)**: 35 Road Runners e 27 Open Results. Há, por site, inventário de 20.000 URLs com todos os problemas, resumo dos 101 tipos de verificação e inventário com 26 colunas de metadados. Os relatórios detalhados acrescentam destinos de links/redirecionamentos, duplicidades, imagens, recursos, estrutura e problemas de conteúdo. Os totais por URL reconciliam exatamente os contadores de todos os tipos no resumo.

Um relatório, incompatibilidade de idioma/hreflang do Road Runners (ID 204, 167 URLs), não ofereceu exportação CSV na interface. As URLs e indicadores estão preservados no inventário geral; a limitação aparece na lista de arquivos. Os outros 54 grupos com ocorrências tiveram CSV detalhado preservado.

Também foram exportadas todas as linhas oferecidas de posições orgânicas Brasil/desktop, base de 03/11/2026: **1.376 linhas / 1.117 termos distintos** no Road Runners e **535 linhas / 357 termos distintos** no Open Results. Posição, posição anterior, volume, dificuldade, URL, estimativa de tráfego, intenção e data própria da palavra permanecem nos originais. Valores de dificuldade ausentes continuam vazios, não zero. As linhas incluem diferentes tipos de posição; não confundir linhas com termos distintos.

## Armazenamento e acesso

- Cópia permanente local: `/Users/Shared/RunnerHubReports/seo/semrush/20261104-final-20000/`, com `raw/` e `normalized/`, fora do Git; diretórios privados e arquivos 0600.
- Cópia no Business: `/var/lib/runnerhub/seo/semrush/20261104/`, fora do docroot. 67 arquivos conferidos por SHA-256: 62 CSVs e cinco JSONs normalizados. Leitura do runtime pelo grupo do ColdFusion; sem URL pública para JSONs/CSVs brutos.
- Consulta: `/portal/seo/?aba=semrush`, seção padrão **Auditorias preservadas**, com verificações, URLs auditadas, palavras-chave e arquivos originais por site.
- Download: `/portal/seo/arquivo.cfm?arquivo=<id>`, login e administrador obrigatórios; GET, lista permitida do manifesto, validação de nome/tamanho, attachment e no-store. Parâmetros não selecionam caminhos do sistema de arquivos.

O relatório usa erro/atenção/observação e distingue zero falhas com testes executados de verificações não medidas. Road Runners: 57 tipos sem falhas e 12 não medidos; Open Results: 60 e 18. Todas as ocorrências ficam a revisar: não foram dadas baixas automáticas ou feitas correções nos sites públicos.

Quatro URLs Road Runners e 551 Open Results são malformadas no arquivo recebido. O texto original foi mantido, sem gerar âncora clicável. Não foram normalizadas silenciosamente, removidas ou alteradas no cadastro. Bloqueios do rastreador ainda precisam ser classificados; filtros intencionalmente noindex não devem ser liberados em massa.

As coletas antigas do painel e a fila curada continuam preservadas e identificadas como históricas. A consulta nova é offline e não consome Semrush. As notas são do fornecedor e da amostra técnica; não medem indexação, audiência ou citações de IA. Não há recálculo automático de Site Health após as próximas correções.

## Validação e publicação

Staging: `../staging/seo-semrush-archive-20261104/`. Quatro templates compilados. 31 cenários ColdFusion aprovados, incluindo filtros, busca, zero resultados, dados malformados, paginação até a página 400, palavras-chave, histórico, permissões, métodos e tentativa de travessia de caminho. Os 62 downloads administrativos foram confrontados individualmente com tamanho e SHA-256 dos originais. Fixtures temporárias restritas a localhost/cabeçalho aleatório e removidas em finally.

Publicado em **04/11/2026 às 13:35:43 (Brasília)**. Backup recuperável em `/var/backups/seo-semrush-archive-20261104/baseline`. Os 31 cenários e 62 downloads passaram novamente a partir dos templates publicados. Quatro hashes de runtime e cinco dependências preservadas; 67 arquivos privados conferidos. As quatro URLs públicas testadas sem autenticação responderam 403 e não entregaram o relatório nem CSV.

Conferência autenticada no Chrome: cartões dos dois sites com as datas, notas e totais; ordenação crescente (zero primeiro) e decrescente (10.005 primeiro) das verificações; palavras-chave Road Runners com 1.376 linhas/1.117 termos distintos. Revisão visual desktop e iPhone 16, 393×852: navegação, cartões e tabela legíveis. Há mensagens preexistentes da autenticação Google no console; não foi afirmado console sem erros. Recibos em `release-*.json`, `published-verified.json`, `public-access.json` e `browser-verified.json` no staging.

A janela própria “Arquivo SEO Semrush 20261104” foi encerrada e sua ausência conferida no menu de janelas, preservando duas outras janelas Chrome. A janela temporária do Finder também foi encerrada. Processos de compilação/validação concluíram; fixtures remotas removidas em finally. A cópia temporária local foi descartada somente após conferir igualdade dos 67 arquivos com a cópia permanente. Os originais em Downloads, o arquivo permanente e o backup de runtime foram preservados. Sem operações de Git ou alterações nos sites públicos/cadastros.

## Próxima rodada

Priorizar Road Runners: verificar os 165 retornos 4xx e os 66 links internos quebrados no estado atual, separar ocorrências de subdomínios/loja desativada e proteções antes de corrigir. Depois, revisar os 32 títulos duplicados, 20 ocorrências de conteúdo duplicado, 11 páginas lentas, dez descrições duplicadas e um conflito de hreflang. A origem de cada alteração factual continua exigindo confirmação oficial.

Open Results: revisar descrições (831) e títulos (173) repetidos por template/paginação/filtros, 113 ocorrências de lentidão e 42 de conteúdo duplicado. Usar os metadados e detalhes preservados, sem desfazer a política de noindex das páginas pessoais. Não executar migração, consolidação ou mudança de robots como parte desta preservação.
