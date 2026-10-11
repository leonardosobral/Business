# Continuação SEO — duplicações restantes, 05/10/2026

- Escopo: RoadRunners runtime e evidências do painel Business. Publicar escopo após backups/checks, sem operações Git.
- Fonte: relatório detalhado de 62 páginas salvo em 05/10 do snapshot 6ac31bf647d73ceec1b0b861. Plugin Semrush encontrado disponível porém não instalado nesta sessão; nenhum dado novo foi atribuído ao fornecedor.
- Ruling: usar candidatos isolados em staging e guardar hashes/baselines — worktree/branch/commit não solicitado e árvores com mudanças de outras frentes. Preservar todo runtime fora do lote.
- Ordem: verificar páginas atuais; confirmar identidade/fatos somente por SELECT; corrigir causa comprovada; testes e revisão; backup/compilação/publicação; conferir páginas públicas; atualizar evidência sem alterar scores históricos.

- Verificação atual: 62URLs, 61HTTP200 e aliasFCA301; quatro grupos restantes abrangem noveURLs e cinco eventos. LIVE Rio tem três datas diferentes; não unir nem redirecionar.
- Causa: título de evento corta nome em50caracteres, removendo etapas/cidades diferentes. Cinco cadastros Correr é Massa/Track&Field possuem nomes completos, cidades e datas distintos; SELECT confirmou sem escrita.
- Ruling/design dentro do plano já autorizado de corrigir títulos duplicados: ampliar somente event_title_date.cfm. Detectar nomes diferentes com o mesmo prefixo50; mostrar prefixo sem palavra cortada, cidade/UF e data existentes. Para colisões também no mesmo local/data, preservar nome completo. Manter lógica anterior de nomes iguais em datas diferentes e títulos únicos. Sem novas páginas, canonicals, redirects ou dados. Testes com cinco eventosPT/EN/ES e regressão de títulos anteriores; revisão e publicação limitada. Preferir clareza/local/data à meta interna arbitrária de70caracteres nos casos de prefixo colidente; Google não foi consultado nem declara esse corte obrigatório.

- Custo: consulta por evento testada levava35–38ms adicionais. Ruling: substituir por SQL fixo compartilhado em cache10min, somente para nomes>=50; consulta fria57,4ms e100grupos retornados. Mantida consulta anterior de nomes repetidos. Sem criação de índices ou migração.
- Fixture: instruções de SELECT no bloco transacional temporário receberam comentário exclusivo da execução para isolar statements de leituras anteriores do catálogo real. Cache de consulta desabilitado somente nas cópias de teste. O helper real mantém cache10min; conferência pública verificará cache/runtime completos.
- Gates locais: baseline60checks38falhas; candidato60checks0falhas. Painel candidato19cenários8acessos aprovados. Um arquivo RR e doisBusiness candidatos; snapshotSemrush não modificado.


## Complemento final em 06/10

- Primeira publicação removeu títulos repetidos na amostra, mas o gate público bloqueou a evidência Business porque 46596/46597 também mudaram. Refinamento: excluir nomes com várias datas do mapa, mantendo regra anterior. A revisão Astra identificou que excluir do SQL não bastava quando outros dois nomes ainda compartilham o prefixo; o bloco novo foi protegido também com `NOT qEventTitleDate.repeated_name`.
- Regressões: versão publicada inicial falhou em duas preservações, candidato intermediário falhou em duas combinações de nome/data/prefixo, e candidato final passou 64 verificações. Fixtures usam somente tabelas temporárias transacionais, removidas ao concluir; nenhum cadastro persistente alterado. Astra verificou fonte e recibos e não encontrou impedimentos restantes.
- Custo final por EXPLAIN em transação READ ONLY: 74,164 ms de execução fria, 95 grupos retornados. Cache compartilhado10min e consulta anterior mantidos; nenhum novo bloco de prefixos para nomes já diferenciados por datas. Esse valor é medição pontual, não SLA.
- Backup e compilação do complemento RR em `/var/backups/seo-title-cities-followup-20261006-rr`. Publicação/verify de um include e 14 dependências aprovadas.
- Gate público final: `public-passed.json`, 2026-10-06T11:37:49.579971+00:00. 62URLs com statuses/canonicals/descrições/H1/robots preservados; 61HTTP200 com títulos únicos e aliasFCA301. 15versõesPT/EN/ES: cidades/datas corretas nos títulos, social titles sincronizados e canonical/alternates/H1/descrições/JSON-LD preservados. Include direto404. Páginas fora dos cinco eventos conservaram seus títulos anteriores.
- Notas do Semrush e contadores do snapshot não alterados; indexação, ranking e tráfego não foram medidos por esta correção.

- Business final: RR-30 e continuidade RR-20 publicados em dois templates; backup `/var/backups/seo-title-cities-final-20261006-business`. 19cenários aprovados antes/depois, oito acessos conferidos, dez dependências preservadas e snapshotSemrush byte a byte intacto. Os prepares Business anteriores não foram publicados.
