# Quinto lote factual de datas — 04/10/2026

Publicado no RoadRunners. Seleção por proximidade: quatro provas de 10–11/10 com divergência entre datas gerais e percursos, confirmadas em fontes oficiais. Não foi usada uma estimativa de receita nem alegada prioridade por tráfego neste lote.

| Evento | Data confirmada | Percursos corrigidos | Fonte consultada |
|---|---|---|---|
| 4ª Prime Night Run — 45211 | 10/10/2026 | 62952, 5 km, antes 10/11 | [Cronochip: página e regulamento HTML](https://inscricaodecorrida.com.br/evento/4a-prime-night-run) |
| Track&Field ParkShoppingBarigüi — 37728 | 11/10/2026 | 64763/64764, 10/5 km, antes 01/11 | [TFSports: descrição e cronograma](https://www.tfsports.com.br/run-series/park-shopping-barigui-2026/) |
| Central Gym Run — 46069 | 11/10/2026 | 65892/65893, caminhada 3 km/corrida 5 km, antes 18/10 | [Página do organizador no Sympla](https://www.sympla.com.br/evento/central-gym-run-2026/3527972) |
| Corrida por Patas — 46080 | 11/10/2026 | 65919/65920, corrida 6 km/cãominhada 3 km, antes 04/10 | [Página e programação no Sympla](https://www.sympla.com.br/evento/corrida-por-patas-2026-corrida-beneficente/3527067) |

As datas gerais estavam corretas e foram preservadas. Sete registros de percurso receberam a data correta e percurso_bloqueado=true, usando a proteção já existente contra sobrescrita automática. IDs, horários, distâncias, modalidades, locais, inscrições e resultados foram preservados.

A descrição Track&Field ainda indicava novembro: corrigida somente a data para 11 de outubro em português e espanhol, mantendo o restante do texto e atualizando source_hash/description_hash do espanhol. Descrição inglesa permaneceu NULL, com fallback existente. Prime recebeu URL de regulamento apontando à página que efetivamente contém o regulamento HTML. Não houve inferência de disponibilidade de inscrição.

## Evidência e limites

Fontes abertas na ferramenta web e consultadas diretamente. A página TF retornou shell via curl; esse arquivo NÃO comprova o texto. A conferência factual veio da página efetivamente renderizada no navegador, que exibiu 11 de outubro e cronograma das duas distâncias, concordando com a leitura web. Os outros três HTMLs diretos retornaram 200 e contêm as datas e modalidades indicadas. Hashes/capturas locais constam dos artefatos.

Três candidatos adicionais tiveram baseline lido, mas não foram alterados: Corre pela Formatura, Nossa Senhora do Rosário e Comerciário Manacapuru. As respectivas páginas não forneceram texto suficiente pela primeira leitura; regulamentos e leitura visual permanecem para uma próxima conferência. Isso não equivale a conflito de fonte confirmado.

## Validação e publicação

- Baseline integral dos quatro eventos e sete percursos, locks e guards contra alterações concorrentes.
- Aplicação com rollback, inversão e rejeição deliberada de drift aprovadas antes da publicação.
- Revisão independente sem bloqueadores; SQL limitado ao escopo documentado.
- Commit transacional com comparação do estado esperado antes de confirmar. Quatro eventos, sete IDs e 13 tabelas dependentes verificados após publicação, incluindo único badge existente.
- Doze URLs públicas PT/EN/ES retornaram 200 antes/depois. Canonical e alternates preservados; dados estruturados mantidos salvo a correção esperada da descrição TF. Texto correto conferido nos três idiomas, incluindo espanhol e fallback inglês.
- Histórico privado capturou oito registros: sete datas de percurso e um link de regulamento. Descrições não pertencem aos campos acompanhados pelo trigger atual; seu antes/depois está no baseline/changes/backup deste lote.
- Recontagem passou de 148 percursos/77 eventos para 141 percursos/73 eventos futuros ativos. São divergências a verificar, não quantidade de erros factuais já confirmados.

Backup recuperável: `/var/backups/seo-date-fifth-20261004`. SQL inverso ensaiado, com guards do estado após publicação. Uma eventual reversão preserva a trilha de auditoria e cria novas entradas correspondentes; não apagar histórico para simular que a alteração não ocorreu. Artefatos: `_codex/staging/seo-date-fifth-20261004/`.

Painel Business registra o lote em SH-02, que permanece parcial. Auditorias técnicas, evidências históricas do Google, privacidade do OpenResults e cron pago não foram alterados. Nenhum commit, mensagem externa ou alteração de configuração de infraestrutura.

Painel publicado e verificado nas abas relatório/fila: um template compilado, hash e cinco dependências preservados; 24 itens, 18 concluídos e seis pendentes. Backup `/var/backups/seo-date-fifth-panel-20261004/baseline`.
