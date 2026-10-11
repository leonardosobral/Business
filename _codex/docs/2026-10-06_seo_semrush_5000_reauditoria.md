# Reauditoria Semrush de 5.000 páginas — 06/10/2026

Nova execução confirmada na interface autenticada do Semrush no Chrome. Campanha
26661911, domínio `roadrunners.run`. A tela de comparação informa conclusão em
06/10/2026 às 17:20 (Brasília), com precisão de minuto. Foram lidas as abas Visão
geral, Problemas, Estatísticas e Comparar rastreamentos; os detalhes de títulos,
descrições duplicadas e HTTP 4xx também foram consultados. Esta coleta não veio
pelo MCP; a conexão Semrush não estava instalada nesta sessão.

Fontes:

- [Visão geral da campanha](https://pt.semrush.com/siteaudit/campaign/26661911/review/overview?fid=8614846).
- [Comparativo das execuções](https://pt.semrush.com/siteaudit/campaign/26661911/review/compare?fid=8614846).
- [Títulos duplicados](https://pt.semrush.com/siteaudit/campaign/26661911/review/issue/detail/6?fid=8614846).
- [Descrições duplicadas](https://pt.semrush.com/siteaudit/campaign/26661911/review/issue/detail/15?fid=8614846).
- [Páginas HTTP 4xx](https://pt.semrush.com/siteaudit/campaign/26661911/review/issue/detail/2?fid=8614846).

## Resultado

| Indicador | 05/10, 01:37 | 06/10, 17:20 |
| --- | ---: | ---: |
| Páginas rastreadas / limite | 5.000/5.000 | 5.000/5.000 |
| Site Health | 69% | 75% |
| Estado da pesquisa IA | 81% | 78% |
| Erros | 126 | 27 |
| Advertências | 37.581 | 45.495 |
| Observações | 3.455 | 2.328 |
| Páginas com título duplicado | 62 | 6 |
| Páginas com conteúdo duplicado | 8 | 0 |
| Links internos quebrados | 35 | 12 |
| Páginas HTTP 4xx | 14 | 2 |
| Páginas com descrição duplicada | 4 | 6 |
| Páginas não rastreadas | 1 | 0 |
| Conflitos hreflang | 1 | 1 |
| Páginas lentas | 1 | 0 |
| Redirecionamentos temporários | 26.249 | 27.850 |
| Recursos sem minificação | 6.394 | 11.995 |

O comparativo classifica 112 ocorrências anteriores de erro como corrigidas e
13 como novas: saldo de 99 a menos. Os 62 títulos anteriores foram marcados como
corrigidos; os seis atuais são novos casos. O mesmo ocorre com as quatro
descrições anteriores, substituídas por seis casos novos. Não interpretar o
aumento de quatro para seis como recorrência das mesmas páginas.

Limite, dispositivo móvel e ausência de renderização JavaScript coincidem nas
duas telas. O conjunto de URLs mudou e inclui novas páginas da loja. Não houve
conferência de todos os parâmetros históricos de configuração; não declarar
identidade integral de população/configuração. A comparação é a oferecida pelo
fornecedor. Zero em um grupo se refere à amostra; não comprova saúde integral,
indexação, ranking, audiência ou presença em respostas de IA.

## Revisão dos casos atuais

- Títulos: Night Run Vitória Airport 2025/2026; quatro URLs da loja (`inactive`,
  `products`, `products?page=2`, `store_sessions/new`). São seis páginas em dois
  conjuntos, não seis conjuntos.
- Descrições: seis URLs de `store.roadrunners.run`, incluindo política de
  privacidade e termos de uso.
- HTTP 4xx: perfil de atleta protegido (403) e endpoint de proteção de e-mail
  Cloudflare (404). Proteções foram preservadas.
- Hreflang: um caso continua no relatório; a URL desta execução ainda requer
  leitura detalhada. Não atribuir sua causa a um endereço por suposição.
- Os 12 links quebrados precisam de revisão das origens, incluindo o caso novo.
  Não declarar os quatro URLs incompletos da rodada anterior recuperados apenas
  porque deixaram de aparecer na amostra.

Próximo lote: metadados da Night Run Vitória, investigação do conflito hreflang
e das origens dos links quebrados; revisão da plataforma responsável pela loja.
Recursos repetidos sem minificação e redirecionamentos concentram advertências,
mas exigem inspeção por recurso/URL antes de definir a correção. Não transformar
redirects, noindex ou bloqueios de páginas privadas em erros sem revisar intenção.

## Painel Business e publicação

Três arquivos de runtime atualizados:

- `portal/includes/seo_semrush_data.cfm`: snapshot produzido pelo gerador
  existente a partir do JSON revisado da interface. Auditoria anterior preservada
  em `audit.previous`, comparativo por grupo e fonte explícita.
- `portal/conteudo/seo_semrush.cfm`: nova auditoria, comparação com cores/textos,
  grupos zerados com check, histórico das entregas recolhido. Mantidas as abas,
  filtros, busca, escape de texto e links diretos.
- `portal/includes/seo_queue_data.cfm`: RR-20 atualizado com nova evidência,
  classificação e prioridades. Demais entregas históricas preservadas.

Nenhum dado de cadastro ou de eventos foi alterado. Dados orgânicos, suas datas,
51 pares palavra-chave/URL, seis oportunidades, concorrentes e tracking mantidos
exatamente como no snapshot anterior de 04/10/2026 às 14:15. A auditoria técnica
não atualiza essas métricas.

Validação: seis testes Python do gerador, reconciliação dos totais dos grupos,
compilação Adobe dos três templates; 19 cenários de renderização, incluindo oito
verificações de acesso, antes e depois da publicação. Conferência visual da
prévia renderizada pelo Adobe em 1440×1000 e 390×844; tabela limitada à sua região
de rolagem, sem overflow da página no celular.

Backup recuperável:
`/var/backups/seo-semrush-5000-20261006-business/baseline`.
Publicação limitada aos três arquivos, com baseline local/produção coincidente,
gates de drift e de hashes testados. Três hashes publicados conferidos e dez
dependências preservadas, incluindo GA4, autenticação e relatórios técnicos.
Renderização verificada novamente lendo os arquivos publicados numa fixture
temporária restrita ao localhost, removida ao terminar. Sem commit, push ou PR.

Scripts e recibos: `_codex/staging/seo-semrush-5000-20261006/`.
O JSON revisado de origem foi salvo em `/private/tmp/seo-semrush-20261006-source.json`,
fora do Git; a coleta revisada, a auditoria anterior e a comparação também estão
preservadas no snapshot de runtime e no backup da publicação.
