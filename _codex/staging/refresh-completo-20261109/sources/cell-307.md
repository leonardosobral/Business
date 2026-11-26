### P15 — Perfil reconstruído · 01/10/2026

P15: reconstrução v1, decisão do responsável em 01/10/2026. O sinal + no PDF significa mais de esse percentual. População: todas as contas existentes cadastradas até o corte, sem excluir país, gênero, administradores ou ausência de Strava. Cada conta uma vez. Atributos atuais não reconstruem o perfil histórico; contagens cumulativas não medem crescimento anual. Premium e médias usam amostras informadas, com bases explícitas; NULL não vira zero. Consulta 305 rev4, congelamento 104; teste da mesma consulta com dados sintéticos 306 rev2, congelamento 105. Valores históricos e comparativos anteriores preservados.

1. Vínculo atual (id_usuario) com ao menos um resultado de prova encerrada até o corte. Não restringe modalidade, país ou status do resultado: mede uso do perfil, não a população nacional de concluintes. Não recupera a data de associação nem pessoas excluídas da base.

2. Mesmo critério da agenda pessoal do portal: registro em tb_evento_corridas_checkin, id_fornecedor NULL, data_checkin até o corte. Inclui inscrição/perfil/calendario e planejamento de eventos futuros. Duplicações de eventos não multiplicam usuários; contagem cumulativa, não somente do ano.

3. Campo assessoria atual preenchido após trim; não confirma vínculo formal ou histórico. Espaços em branco não contam como equipe.

4. Ao menos uma inscrição atualmente confirmada (status C) em desafios, data_inscricao até o corte; conta cada usuário uma vez, cumulativamente. Não é participação comprovada em atividades nem retrato da data de confirmação.

5. strava_id positivo atualmente presente na conta; não testa token, uso ou frequência. Vínculo histórico na data de corte não recuperado.

6. strava_premium=true entre contas com strava_id positivo e campo premium informado. Premium NULL não é tratado como falso; não é percentual de todas as contas nem indicador do mercado.

7. Média aritmética de strava_full_follower_count não negativo, com strava_id positivo. Seguidores no Strava, não seguidores no Road Runners. Zero conhecido entra na média; campo ausente fica fora.

8. Regra provisória: strava_weight entre 20 e 300 kg, com strava_id positivo. Um peso positivo de 740 kg excluído; zeros e ausências fora da média. Não corrige o cadastro nem calibra a média para coincidir com o PDF. As duas alternativas de peso permanecem no congelamento.

9. Média de pares com retired=false por conta Strava com lista JSON em formato array. Lista vazia conhecida conta como zero; lista ausente não conta. Pares aposentados e estado desconhecido não entram no numerador.

10. Soma de distance/1000 dos pares ativos com distância numérica não negativa, dividida pelo número desses pares. Unidade original em metros. É km por par ativo; não média de médias por usuário nem quilometragem anual.

Bases: 46.690 contas/2025 (até 31/12) e 56.185/2026 (até 26/09). Perfil atual de contas existentes, sem histórico de exclusões. Não estima crescimento anual nem usa a amostra dos resultados nacionais.
