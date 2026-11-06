# CBAt — falha de extração no job 5

O job 5 recebia HTTP 500 com 20 erros por execução. O retorno completo mostrava “Falha ao carregar a notícia na CBAt: 200 OK”. A origem retornava a notícia, mas a extração por regex no HTML Next.js de 353.899 caracteres não encontrava o corpo e os metadados. A expressão também dependia da ordem exata das classes e dos contêineres posteriores ao artigo.

A correção usa o Jsoup já disponível no ColdFusion para ler exclusivamente `div.noticia-corpo.content`, preservando blocos aninhados. Extrai descrição, categoria, imagem e data por elementos/atributos, independentemente da ordem dos atributos. Páginas sem corpo continuam rejeitadas com uma mensagem que explica a falha de extração. Erros HTTP continuam sendo erros.

Regressão reproduzida antes da alteração; 14 verificações nativas de parser/HTTP aprovadas. A simulação usa o fetch real com somente o HTTP substituído pelo HTML público salvo, sem banco ou rede. O agendamento, credenciais, deduplicação e decisões de curadoria permanecem no código existente.

Publicação restrita a `conteudo.roadrunners.run/admin/importer_cbat_corridaderua.cfm`, com baseline comparado, substituição atômica e backup `/var/backups/business-cbat-jzl0j9ic`. Evidência de publicação e importação real: `_codex/deploy/cbat-extraction-20261105.json`. Nenhuma operação Git executada.
