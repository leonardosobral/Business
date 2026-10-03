# Cobertura cadastral e auditoria 14+ — 01/10/2026

Publicada às 15h53 BRT: [2025 v13, congelamento 120, publicação 23](https://roadrunners.run/brasilquecorreprovas/web/?ano=2025&fonte=atual#coleta) e [2026 v11, congelamento 122, publicação 24](https://roadrunners.run/brasilquecorreprovas/web/?ano=2026#coleta). Duas páginas compartilhadas: coleta dentro do cadastro e corte de 14 anos. O [caderno único 6 no Business](https://business.roadrunners.run/estudo/?caderno=6) continua sendo o lugar de autoria e revisão com o DBA. Este diretório registra a entrega.

## Definições e resultado

A [nota metodológica](nota-notebook.md), também na célula 316 do notebook, documenta regras, fontes, universos e limites. Eventos BR pela data final, incluindo inativos. Coleta significa ao menos uma linha bruta, sem certificar captura completa. Com conclusão registrada exige ao menos um resultado status 0, homologado e concluinte=true.

Todas as modalidades, até 26/09: 2025 tem 5.575 cadastradas e 3.067 coletadas (55,0%); 2026 tem 7.588 cadastradas e 4.602 coletadas (60,6%). A razão mede somente o calendário conhecido do portal. Não estima cobertura nacional nem crescimento real e não substitui os 84,1% históricos do PDF. Universos todas as modalidades/rua-trail e períodos completo/parcial são sobrepostos; não somar linhas.

Idade em 31/12 do ano da prova, nascimento plausível prioritário e faixa inteira da categoria como alternativa. Faixa ampla inteiramente 14+ permite o corte mínimo mesmo sem caber em grupo de cinco anos. Faltantes, faixas cruzando 14 e inválidos continuam sem decisão; não recebem estimativa ou inclusão automática. O denominador inclui todas as participações com conclusão registrada do período, em todas as modalidades.

| Situação | 2025 completo | 2026 até 26/09 |
| --- | ---: | ---: |
| 14+ identificados | 4.330.048 | 3.846.948 |
| Menos de 14 | 9.676 | 9.419 |
| Faixa cruza 14 | 98.282 | 75.566 |
| Sem idade informada | 841.202 | 369.386 |
| Dado inválido | 4 | 80 |
| Total com conclusão registrada | 5.279.212 | 4.301.399 |

Os 14+ identificados são subconjuntos conhecidos, sem inferência para pendências; não são novos totais nacionais completos. Uma linha conta participação, não pessoa única. Flags falsa/NULL são exibidas separadamente: 8/0 em 2025 e 237/0 em 2026. A definição vigente de vw_resultados não filtra conclusão nem idade.

## Fontes e preservação

Cobertura: célula 312 rev3, execução 117. Idade: células 314/315 rev1, execuções 118/119. Fixture: célula 313 rev1, execução 116. Consultas finais concluíram em 8,1/11,8/11,2 segundos sob a proteção existente de 45 segundos. A consulta conjunta excedeu o limite; separar e pré-agregar resolveu sem ampliar proteção. Fontes agregadas, sem exportar registros individuais.

As seis combinações de período/universo reconciliam flags, idade e totais. [Validação reproduzível dos candidatos](validate_candidates.py) e [conferência final das fontes](integrity-final.json).

Das 156 células originais, 154 ficaram intactas. Apenas as duas saídas autorais foram revisadas: 249 rev24/251 rev20. Queries do DBA e demais células preservadas, com cinco novas células incluindo a nota. Todos os 101 indicadores/665 comparações de 2025 e 98 indicadores/671 comparações de 2026 permaneceram iguais. Cada pacote acrescenta sete séries e 29 comparações. Totais, coortes e comparativos antigos mantêm suas próprias coletas.

Contratos aditivos 2025/7 e 2026/7, com validação oficial antes do COMMIT. Pacotes antigos 108/112/109 também aceitos. Baselines anteriores e validador genérico intactos. Rejeições intermediárias fizeram ROLLBACK. Novas referências históricas são NULL; “Publicado no PDF” de 2025 não mostra esta auditoria. Nenhuma mudança de autenticação, permissão, guarda SQL, runtime Business ou tabelas operacionais.

## Verificação e recuperação

89 testes Node passaram, com cinco novos testes de renderização, preservação, conservação, percentuais/denominadores/conteúdo CSV e 23 expectativas sintéticas executadas no PostgreSQL. Sintaxe dos dois JavaScripts conferida. Revisão independente sem impedimentos; dispatcher de rollback corrigido antes do deploy.

Produção e prévia conferidas no navegador integrado: desktop 1280×720 e celular 390×844. Sem transbordamento horizontal da página ou erros de console. Conteúdo CSV testado; não houve novo teste de download pela UI. Capturas neste diretório. JSON HTTP200 de ambos os anos idêntico aos candidatos, exceto metadado de publicação. Cabeçalhos `private, no-store` e `noindex, nofollow` conferidos. A rota permanece por link direto, sem divulgação adicionada à landing, menu ou sitemap. Visitas leem congelamentos.

Dois arquivos gerados de previa e publicados: estudo.js/parcial.js. Hashes anteriores corresponderam à entrega precedente; backup e hashes novos conferidos. Nenhum outro runtime mudou.

Backup de runtime: `/var/backups/roadrunners-estudo-cobertura-20261001/runtime/RoadRunners/baseline`. Backup de banco anterior à migração válida: `/var/backups/business-estudo-web-20260928/database/cobertura-idades-20261001-v3-before.json`. Para recuperar dados, republicar 108/2025 e 112/2026 pelo serviço oficial com os IDs vigentes como revisão esperada. Não forçar revisão nem remover histórico. A interface foi testada com ambos os pacotes antigos. Antes de restaurar assets, conferir hashes atuais para não sobrescrever entrega posterior. O wrapper release.py tem rollback explícito e rejeita modos desconhecidos.

O aceite integral do plano continua aberto: denominador histórico de 84,1%, volume histórico exato, rótulos regionais ausentes, fonte ou decisão para pendências do corte 14+, fonte de 42 km de Floripa e regras históricas/provisórias do perfil.
