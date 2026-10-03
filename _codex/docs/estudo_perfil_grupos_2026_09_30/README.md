# Estudo — grupos de maratonas e atividades, 30/09/2026

Publicado às 23h11 BRT pelo caderno único 6. Fontes lidas antes de editar e imediatamente antes de publicar. Somente células anteriores 249/251 alteradas, com revisão esperada; SQLs originais do DBA/DataGrip e reprodução legada preservados. Queries anexas são recibos, não fonte concorrente de autoria: editar e executar no notebook.

| Fonte | Célula/revisão | Congelamento |
| --- | --- | --- |
| Atividades 2026 bruto/delete | 280/1 | 65 |
| Grupos por menores tempos 2025 | 281/2 | 67 |
| Atividades 2025 bruto/delete | 282/2 | 69 |
| Grupos PDF/legado/revisão | 283/1 | 70 |
| Mapeamento e percentual atividades | 284/1 | 71 |
| Saída web 2025 | 249/11 | 72 — publicação 10/web v6 |
| Saída web 2026 | 251/8 | 74 — publicação 11/web v5 |

Notas 285/P15 e 286/P13; conteúdo completo em notes.md. A saída 73 ficou no histórico; sua contagem de estados foi corrigida em 74, que é a publicação selecionada. As tentativas com timeout também permanecem como histórico de execução.

Top 10/100 global seleciona min(n,10/100); percentuais ceil(n*p) de conclusões elegíveis, média ao segundo e ordenação por tempo/ID. Não reproduz a classificação cadastrada e inscritos do legado 264/48. As dez populações são iguais à execução 41 (43.395); referência PDF/34 preservada. Aracaju: legado inclui 20 no Top 10/média 03:00:03; revisão inclui 10/média 02:38:51. Comparação 70 torna a mudança de regra auditável. Menores 5% podem conter menos de 100 resultados nas provas menores: conferir quantidades.

Atividades: denominador de todos os tipos preenchidos, incluindo Run, com indicação Strava delete fora. As contagens brutas 2025 conferem exatamente com o legado 223/29. Removidas 17.588 entre 1.157.156 com tipo; três sem tipo fora. Base revisada 1.139.568. 2026 até 26/09: 313.818 brutos, 5.398 excluídos e base 308.420. Coleta própria em 30/09; não são atletas únicos, mercado de provas ou volumes anuais comparáveis. Hike=Trilha; nenhuma junção com TrailRun.

Somente 61 comparações de 2025 e 11 de 2026 alteradas. PDF, totais, corridas, comparativos e coortes preservados. Contratos oficiais 2/2025 e 1/2026 conferidos; 47 testes passam. UI Chrome desktop/celular, headers e JSON de produção verificados; 26 páginas/28 gráficos em 2025 atual, 24 páginas/32 gráficos em 2026. Não certificamos download completo do CSV pelo navegador; exportação/adaptador testados.

Sem mudança de runtime Business. RoadRunners publica apenas estudo.js, parcial.js e estudo.css, com backup /var/backups/roadrunners-estudo-perfil-grupos-20260930/runtime/RoadRunners. Reversão de dados pelo serviço oficial para 63/64 com a publicação vigente; preservar congelamentos. Registro e evidências em RoadRunners/_codex/docs/brasil_que_corre_provas/perfil_grupos_2026_09_30/README.md.

Plano integral ainda aberto: dez métricas de perfil sem queries/denominadores, sinal + a confirmar, idade de referência/gerações, estações e medalhas. Scripts DBA chamados perfil são de participações em provas. Maratonas 2026 continuam com auditoria cadastral/tempos suspeitos antes de derivar grupos do ano. Nenhum número histórico foi usado para preencher 2026.
