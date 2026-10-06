# Histórico público de correções de eventos — 04/10/2026

Publicado no RoadRunners e registrado no Business, SH-02 parcial.

## Comportamento

Oito eventos possuem uma seção recolhida de histórico em PT/EN/ES: LIVE Rio, LIVE Niterói, Night Run Curitiba, Night Run Maceió, LIVE Fortaleza, Primavera Campo Grande, TGS Run e Reis Magos. São nove registros: oito grupos de datas de percursos e a correção da data na descrição TGS. Cada registro informa o campo, distâncias quando aplicável, valor anterior no cadastro, valor corrigido, data de registro e fonte consultada.

Os valores vêm dos baselines e alterações efetivamente publicadas nos lotes seo-date-priority-20261004 e seo-date-next-20261004. Não se afirma que todo erro cadastral represente adiamento da prova. A correção TGS é sustentada pelo aviso explícito do organizador, mas o histórico descreve a edição feita no RoadRunners. Não são exibidos dados de atletas, operadores ou resultados.

O histórico permanece como registro passado se as datas atuais mudarem. O bloco separado de conferência das datas continua condicionado à igualdade exata com o cadastro atual. Esse bloco foi ampliado de quatro para oito eventos. IZ1 e 5º BEC permanecem fora por conflito de fonte. Fontes não são consultadas automaticamente em cada acesso.

## Runtime e contrato

RoadRunners/evento/parts/fact_review_data.cfm: oito recibos manuais.
RoadRunners/evento/parts/fact_history_data.cfm: nove registros manuais.
RoadRunners/evento/parts/fact_history.cfm: validação e apresentação.
RoadRunners/evento/parts/fact_review.cfm: inclui o histórico fora do gate da conferência atual.

Campos do registro: recordedAt,field,detail,before,after,sourceUrl,sourceLabel. field aceita routeDate/descriptionDate; before/after são datas ISO válidas e diferentes. recordedAt não pode ser futuro. sourceUrl exige HTTP(S), sem userinfo, barra invertida ou quebra de linha. Todos os valores saem escapados. Entrada inválida é omitida. Links com fragmento legítimo são preservados. Novos includes diretos retornam 403. Nenhuma query, tabela, metadata, autenticação ou política de privacidade nova.

Publicar dados e renderer antes do include consumidor; rollback na ordem inversa. Antes de acrescentar registro: conferir fonte primária atual, guardar baseline e patch, provar publicação, conferir campos/valores e não reconstruir histórico por inferência. Não remover registros passados só porque o cadastro atual mudou. Corrigir eventual erro do próprio histórico mediante nova revisão documentada.

## Evidência

- Adobe ColdFusion: 181 verificações aprovadas; baseline teve 66 falhas esperadas de ausência do histórico. Inclui validade, tipos inválidos, URLs perigosas, escape, campos permitidos, datas, idioma e alteração da data atual.
- Quatro templates compilados; hashes vinculados à compilação e aos testes. Revisão independente sem bloqueios, com reconciliação dos nove registros aos lotes publicados.
- 27 URLs públicas antes/depois: 24 dos eventos e três controles, todas 200; canonical, alternates e JSON-LD idênticos. Histórico e conferências somente nos eventos selecionados.
- Dois novos includes diretamente acessados retornam 403.
- TGS desktop 1280×800 e celular 390×844: sem overflow, dois registros visíveis, abertura/fechamento por Enter e abertura por clique confirmados; viewport restaurado e aba temporária fechada.
- Backup /var/backups/seo-event-history-20261004/baseline; quatro hashes e seis dependências confirmados após publicação.
- Business: um template de evidência; compilação, renders reais de relatório/fila antes/depois, hash e cinco dependências verificados. 24 itens, 18 resolvidos, 6 pendentes; notas técnicas e evidência Google preservadas. Backup /var/backups/seo-event-history-panel-20261004/baseline.

## Limites e próxima implementação

Este histórico é curado, não captura automaticamente novas edições. O backend do Business grava logs da ação em tb_log, mas não conserva o par antes/depois com a fonte em um contrato de proveniência. Gestão das fontes no cadastro, captura de futuras edições e histórico de local/status seguem pendentes. Não apresentar esses requisitos como concluídos nem criar histórico retroativo sem prova. O lote não comprova indexação ou citação por IA e não altera OpenResults.

Artefatos privados: Business/_codex/staging/seo-event-history-20261004 e seo-event-history-panel-20261004.
