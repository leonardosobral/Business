# SEO — Night Run Vitória e Costa Esmeralda — 06/10/2026

Entrega registrada em RR-32 no Business. Fonte: auditoria Semrush de 5.000 páginas concluída em 06/10 às 17:20 (Brasília), campanha 26661911, consultada pela interface autenticada do Chrome.

## Diagnóstico e escopo

- Night Run Vitória: cadastros ativos 33178 e 47673, nomes equivalentes com diferença de maiúsculas/minúsculas, datas cadastradas 25/10/2025 e 20/11/2026. A comparação exata anterior não reconhecia essas edições. Consulta somente por leitura; não houve alteração de data, nome, tag ou cadastro.
- O helper reconhece equivalência de nomes curtos quando a data distingue a edição. Nomes longos, prefixos e títulos já diferentes conservam suas regras anteriores. Os títulos da Night mantêm nome completo, termo de corrida localizado, data e marca, dentro de 70 caracteres.
- Costa Esmeralda: a variante sem barra final respondia 200, mas canonical e alternates indicavam a versão com barra. Semrush apontava ausência de hreflang autorreferente nessa variante. Alias confirmado da tag 2026-costa-esmeralda-trail-2026 consolidado em PT/EN/ES; GET/HEAD com query vazia. Outras tags, formas de escrita, ações, POST e queries permanecem fora da regra.
- A conferência pública inicial detectou que /evento/.htaccess sobrepõe as regras da raiz. A fixture Apache final reproduz essa hierarquia; a regra também foi publicada no arquivo da pasta. Não foi adicionada herança geral de regras nem alterado virtual host.
- Os 12 links quebrados do relatório foram classificados pela origem: 11 apontam à proteção de e-mail Cloudflare e um ao perfil com acesso protegido. O novo link encontrado nesta rodada também aponta à proteção de e-mail. Essas ocorrências continuam nos totais históricos; proteção, autenticação e regras Cloudflare foram preservadas.

## Arquivos publicados

| Projeto | Arquivo | Mudança |
|---|---|---|
| RoadRunners | includes/estrutura/event_title_date.cfm | Equivalência de nomes e título da edição com nome completo/data |
| RoadRunners | .htaccess | Alias sem barra de Costa Esmeralda nas rotas localizadas |
| RoadRunners | evento/.htaccess | Mesmo alias na rota portuguesa com configuração própria |
| Business | portal/includes/seo_queue_data.cfm | RR-32 concluído e classificação dos links em RR-20 |
| Business | portal/conteudo/seo_semrush.cfm | Correções posteriores à coleta, mantendo contadores e notas |

Nenhum commit, branch, push ou PR. Mudanças de outras frentes preservadas, inclusive a diferença local preexistente em evento/index.cfm. Dados Semrush e Analytics não foram regravados.

## Validação

- Adobe/PostgreSQL: baseline reproduziu nove falhas da Night em 91 verificações; candidato final passou 91. Inclui nome completo, termos localizados, títulos de prefixos já corrigidos, empate de local/data, datas ausentes e escaping. Fixtures temporárias transacionais, removidas ao final.
- Apache: 27 cenários na hierarquia raiz/pasta, incluindo seis GET/HEAD positivos, query, métodos, outros slugs, barra existente e arquivo real. Redirect automático de diretório comparado normalizando apenas o nome da pasta da fixture.
- Compilação Adobe dos templates publicados e apache2ctl -t aprovados. Backup e guardas de hash antes de cada publicação. Dependências preservadas: 16 no lote inicial RoadRunners e 18 nos complementos; dez no Business.
- Produção pública: 27 requests finais, seis títulos distintos por data e idioma, seis aliases GET/HEAD com 301 e três cadeias com exatamente um salto até 200. H1, descrição, canonical, alternates e JSON-LD das seis páginas Night preservados. Outros 12 controles de metadados preservados.
- Business: 19 cenários de renderização antes e depois da publicação, incluindo oito verificações de acesso/método/template direto. Dados orgânicos, notas e datas históricos preservados.
- Conferência visual autenticada no Chrome indisponível ao final: Mac bloqueado. Não houve tentativa de contornar o bloqueio. Publicação conferida por hashes e renderização do código real publicado em fixture localhost com os guards reais.

## Medição e pendências

A nota técnica continua 75%, pesquisa IA 78% e 27 ocorrências de erro, conforme a coleta de 17:20; não foram recalculadas após as correções. A coleta orgânica de 04/10 permanece intacta. RR-32 aguarda nova auditoria de 5.000 páginas; essas verificações não comprovam indexação ou ganho de posição no Google.

A loja store.roadrunners.run ainda tem quatro páginas com títulos repetidos e seis com descrições repetidas; depende da plataforma que serve a loja. Normalização geral de eventos sem barra e revisão dos demais avisos seguem fora deste lote. Perfis protegidos e proteção de e-mail não foram declarados corrigidos.

## Recuperação

Backups publicados em /var/backups/:

- seo-next-20261006-rr-publish/baseline — helper e .htaccess da raiz;
- seo-next-20261006-rr-child/baseline — .htaccess de eventos;
- seo-next-20261006-rr-title-final/baseline — refinamento final dos títulos;
- seo-next-20261006-business-final/baseline — dois arquivos do painel.

Scripts e recibos em _codex/staging/seo-next-20261006/. Para recuperação integral do RoadRunners, reverter o refinamento dos títulos, a regra da pasta e então o lote inicial, respeitando as guardas de conflito dos scripts. Revisões preparadas que não foram publicadas permanecem como artefatos privados de validação; não são releases de produção.
