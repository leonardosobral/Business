# SEO — reauditoria, recursos e links de eventos (08/10/2026)

Auditoria Semrush da campanha Road Runners 26661911 concluída em 08/10 às 20:20 (Brasília), conferida pela interface autenticada do Chrome. Mesmos 5.000/5.000, rastreador móvel e JavaScript sem renderização da coleta de 06/10; as URLs da amostra mudaram. Site Health permanece **75%** e IA **78%**. Erros **27 → 39**, advertências **45.495 → 35.227**, observações **2.328 → 5.846**. Minificação **11.995 → 2.088**. O comparativo do fornecedor informa 10 erros corrigidos e 22 novos; 14.714 advertências corrigidas e 4.446 novas. Não representa indexação ou ganho de ranking. Fonte estruturada: `staging/seo-links-assets-20261008/source-20261008.json`.

## RR-37 — recursos menores

Publicados cinco novos assets minificados e quatro referências: home, filtros de estado/cidade e bootstrap de audiência. Total 52.779 → 40.104 bytes (24,0%), antes da compressão HTTP. Gerador passou de 13 para 18 fontes. Fontes e lógica preservadas; as outras 13 saídas regeneradas na preparação não foram republicadas. Cinco comparações de programa normalizado, 98 testes contra os arquivos gerados e quatro templates compilados. Público: 18 páginas, cinco hashes/MIME e 38 referências, preservando atributos, status e metadados. Geometria da home e dos seletores igual no desktop 1280 e celular 390, sem overflow; busca de Salvador conferida. Dezoito dependências preservadas. A diferença local prévia de Application.cfc foi preservada e nunca publicada.

## RR-38 — novos títulos e links quebrados

A auditoria encontrou quatro títulos duplicados: Jurerê Night Run 2025/2026 e Meia Maratona de Florianópolis Oakberry 2025/2027. O corte do nome apagava o ano, enquanto diferenças de caixa impediam a detecção do prefixo. A consulta passou a agrupar prefixos sem distinguir caixa e a contar nomes distintos sem distinguir caixa, preservando títulos já distintos por data. Data e local dos cadastros são incluídos apenas onde o prefixo colide.

Três URLs 404 vinham de tags com aspas, fragmento `#038;` e quebra de linha. O card agora codifica a tag inteira para URL. As três alterações de codificação já existiam no arquivo local e não estavam na produção; candidato foi reconstruído do baseline de produção e comprovado idêntico somente a esse ajuste local. Nenhuma alteração alheia foi incluída.

Testes Adobe: baseline de títulos falhou em 21 de 91 cenários; candidato passou nos 91, incluindo 64 controles anteriores. O SQL das fixtures temporárias recebeu identificadores exclusivos para impedir reutilização de planos preparados ligados à tabela de produção. Baseline dos links falhou em 16 de 40; candidato passou nos 40. Dois templates compilados. Após publicação, 28 páginas: 12 títulos distintos nos três idiomas, nove destinos codificados 200 e sete origens com links completos. Canonical, hreflang, descrição, H1 e JSON-LD preservados; tags confirmadas em consulta somente leitura ao catálogo. Nenhuma data, nome, tag, cadastro ou resultado alterado no banco. URLs truncadas antigas e ambíguas continuam sem redirecionamento inventado.

## Painel e limites

Três arquivos Business publicados com a coleta real de 08/10, comparação 06/10 → 08/10 e RR-37/RR-38 aguardando confirmação na próxima auditoria. Coleta orgânica de 04/10, 51 palavras-chave e seis oportunidades preservadas. Dezenove cenários de renderização/acesso antes e após publicação; três templates compilados e dez dependências preservadas. Includes originais confirmam os novos itens e métricas.

Os 39 erros medidos antecedem estes dois lotes. Quatro títulos e seis descrições da loja externa continuam em RR-36; proteção de e-mail preservada. Quatro páginas de São Silvestre apresentaram lentidão no rastreamento e exigem acompanhamento. O Mac foi bloqueado antes de iniciar outra auditoria; **nenhuma nova rodada foi iniciada e nenhuma elevação de Site Health foi confirmada**. A meta continua pendente de uma medição maior que 75%.

Backups recuperáveis:
- `/var/backups/seo-links-assets-20261008-rr/baseline`
- `/var/backups/seo-event-routes-20261008-rr/baseline`
- `/var/backups/seo-links-assets-20261008-business/baseline`

Receitas em `staging/seo-links-assets-20261008/final-verified.json`, `original-runtime-check.json` e `staging/seo-event-routes-20261008/public-passed.json`. Sem commit, branch ou push.
