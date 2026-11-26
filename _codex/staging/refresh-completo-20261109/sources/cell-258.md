## Conciliação das maratonas — 30/09/2026

Diagnóstico congelado na execução #40 (célula #257). A view public.vw_resultados filtra apenas status_final=0 e homologado=true; consulta a base viva, sem congelamento próprio.

- Curitiba: a seleção por pcd=false inclui 6 registros da modalidade “42k CADEIRANTE”, inclusive o tempo 01:56:00. O filtro textual da query recebida os exclui e recupera 02:15:13, igual ao PDF. Isso explica o menor tempo, não todas as diferenças de contagem.
- São Paulo: 7 registros “42k DMS” e 6 “42k DMAI” também estão com pcd=false. Os filtros de texto e o campo booleano não são equivalentes.
- As dez provas não tinham tempos nulos/zero nem falta do sinalizador concluinte dentro do recorte de contagem. A diferença identificada não é causada por esses dois filtros.

A próxima célula usa uma única população para contagem, F/M, tempos e sub-4/3/2h30: rua/BR/2025, ranking elegível, 42–42,2 km, status 0, homologado, concluinte, tempo positivo, pcd=false e exclusões textuais do SQL recebido. É um recálculo candidato explicitamente revisado, não reprodução da base histórica. O filtro amplo “%DI%” é legado e não deve ser generalizado automaticamente para novos eventos. Os cadastros não são alterados.

Top 10/100, percentis e medalhas continuam separados: o SQL recebido usa classificações cadastradas e percentuais dos inscritos, não uma nova ordenação por tempo. Precisamos conciliar essa regra antes de publicar esses novos cálculos.
