# SEO — correções prioritárias, 21/10/2026

Escopo autorizado: corrigir os problemas de maior impacto das auditorias de 5.000 páginas dos dois sites. Não alterar dados de provas, autenticação ou política de privacidade.

1. OpenResults: rastrear a referência ao script ausente, comparar origem/checkout/Git, corrigir a dependência no dono correto e provar ausência do 404 e funcionamento do menu.
2. OpenResults: reproduzir os canonicals estaduais inacessíveis, corrigir somente a causa comprovada, verificar estados/cidades/filtros e preservar noindex individual.
3. RoadRunners: corrigir títulos/descrições ambíguos somente com dados existentes; manter URLs e edições distintas. Tratar duplicação de entidade apenas se a origem for comprovada.
4. Verificar os arquivos afetados, revisar o lote, publicar somente runtime autorizado com recuperação e comparação de baseline, conferir o site real e documentar o resultado. A nota do Semrush só muda após outra auditoria.

## Progresso

- Início: OpenResults limpo no Git; RoadRunners somente diretórios __pycache__ não rastreados; Business contém alterações alheias preservadas.
- Ruling: usar candidatos isolados nesta pasta antes de sincronizar os arquivos exatos dos projetos — AGENTS proíbe criar branch/commit sem pedido específico; não haverá operações Git de escrita.
- Ruling: nenhum cache de página, regra Cloudflare, banco ou política de resultados individuais será alterado para melhorar artificialmente a nota.

- Task 1: markup do menu RED com quatro falhas esperadas → GREEN 13/13. Proxy real e compilação em validação.
- Task 2: canonicals estaduais retornam 200 na origem; nenhum ajuste sem reprodução do erro.
- Task 3: novos cenários de títulos RED → GREEN; revisão independente identificou corte de identidade, teste específico falhou antes do ajuste e foi corrigido.
- Ruling: fixture antiga CREATE TEMP foi bloqueada pelo datasource; não contornar a proteção. Executar controles de leitura, decodificando entidades HTML no assert devido ao encoder atual.

- Final: revisão independente concluída; achado de identidade corrigido RED→GREEN. 105 verificações de títulos + 82 controles de leitura + 13 verificações do menu = 200 aprovadas.
- Final: três templates compilados no ColdFusion 2025; smoke GET/GET/POST do catálogo aprovado.
- Final: publicados três arquivos com hashes e onze dependências preservados; 21 páginas 200 com metadados preservados, 15 títulos distintos e seis referências corretas. Navegador público confirmou oito apps e título com nome completo/cidade/data.
- Final: documentação nos dois projetos e deploy OpenResults atualizados localmente. Diff --check aprovado nos dois repositórios. Nenhuma nota nova do Semrush afirmada.
