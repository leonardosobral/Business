-- P12: cadastro e coleta são recortes separados; uma unidade = id_evento distinto.
-- Base revisada: eventos ativos BR/rua, ranking nulo ou diferente de false;
-- data_final em 2025 completo / 2026 até30/09. Inclui cancelados cadastrados.
-- Cadastro: percurso de rua em km entre42 e42.2; não usa nome da prova.
-- Bloqueio do percurso não apaga cadastro; informa-se separadamente.
-- Coleta: ao menos uma linha bruta42–42.2km, sem certificar completude.
-- Elegível: status0, homologado, concluinte, tempo positivo, pcd=false,
-- modalidade convencional com exclusão por palavra/tokens, igual regra revisada2026.
-- Resultados sem percurso cadastrado são auditados, não acrescentados ao cadastro.
WITH periodos AS(SELECT column1 AS ano,column2 AS inicio,column3 AS fim FROM(VALUES
 (2025,DATE '2025-01-01',DATE '2025-12-31'),
 (2026,DATE '2026-01-01',DATE '2026-09-30'))t),
eventos AS MATERIALIZED(
 SELECT p.ano,p.fim AS corte,e.id_evento,e.nome_evento,e.data_final,
 EXISTS(SELECT 1 FROM public.tb_evento_corridas_percursos d WHERE d.id_evento=e.id_evento AND lower(trim(d.unidade_de_medida))='km' AND d.tipo_corrida='rua' AND d.percurso_evento BETWEEN 42 AND 42.2) AS cadastrado,
 EXISTS(SELECT 1 FROM public.tb_evento_corridas_percursos d WHERE d.id_evento=e.id_evento AND lower(trim(d.unidade_de_medida))='km' AND d.tipo_corrida='rua' AND d.percurso_evento BETWEEN 42 AND 42.2 AND d.percurso_bloqueado) AS bloqueado,
 EXISTS(SELECT 1 FROM public.tb_evento_corridas_percursos d WHERE d.id_evento=e.id_evento AND lower(trim(d.unidade_de_medida))='km' AND d.percurso_evento>0) AS distancia_informada
 FROM public.tb_evento_corridas e JOIN periodos p ON e.data_final BETWEEN p.inicio AND p.fim
 WHERE e.ativo IS TRUE AND e.pais='BR' AND e.tipo_corrida='rua' AND(e.ranking IS NULL OR e.ranking<>'false')
), resultados AS MATERIALIZED(
 SELECT r.id_evento,count(*) AS linhas_brutas,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE AND r.tempo_total>TIME '00:00:00' AND r.pcd IS FALSE AND NOT(coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))')) AS elegiveis
 FROM public.tb_resultados r JOIN eventos e USING(id_evento)
 WHERE r.percurso BETWEEN 42 AND 42.2 GROUP BY r.id_evento
), resumo AS(
 SELECT e.ano,e.corte,count(*) AS calendario,
 count(*) FILTER(WHERE distancia_informada) AS distancia_informada,
 count(*) FILTER(WHERE cadastrado) AS cadastradas,
 count(*) FILTER(WHERE cadastrado AND bloqueado) AS com_percurso_bloqueado,
 count(*) FILTER(WHERE cadastrado AND coalesce(r.linhas_brutas,0)>0) AS cadastradas_coletadas,
 count(*) FILTER(WHERE cadastrado AND coalesce(r.elegiveis,0)>0) AS cadastradas_elegiveis,
 count(*) FILTER(WHERE coalesce(r.linhas_brutas,0)>0) AS coletadas_total,
 count(*) FILTER(WHERE coalesce(r.elegiveis,0)>0) AS elegiveis_total,
 count(*) FILTER(WHERE NOT cadastrado AND coalesce(r.linhas_brutas,0)>0) AS coletadas_sem_cadastro,
 count(*) FILTER(WHERE NOT cadastrado AND coalesce(r.elegiveis,0)>0) AS elegiveis_sem_cadastro,
 coalesce(sum(r.elegiveis),0) AS participacoes_elegiveis,
 (count(*) FILTER(WHERE cadastrado)*100.0/NULLIF(count(*),0))::text AS fracao_percentual
 FROM eventos e LEFT JOIN resultados r USING(id_evento) GROUP BY e.ano,e.corte
)
SELECT jsonb_build_object('coletado_em',current_timestamp,'regra','Eventos ativos BR/rua; ranking nulo ou diferente de false; data_final dentro do período. Cadastro = percurso rua/km de42 a42.2. Coleta = linha bruta da mesma distância. Elegíveis = regra revisada convencional de2026; não certifica realização ou completude. Contagem por id_evento, sem inferir maratona pelo nome; percursos bloqueados continuam cadastrados. Fração divide cadastradas por todos os eventos da mesma base; cadastro de distâncias incompleto pode subestimar.',
 'linhas',(SELECT jsonb_agg(to_jsonb(resumo) ORDER BY ano) FROM resumo),
 'auditoria',(SELECT jsonb_agg(jsonb_build_object('ano',e.ano,'id_evento',e.id_evento,'nome_evento',e.nome_evento,'data_final',e.data_final,'cadastrado',e.cadastrado,'bloqueado',e.bloqueado,'linhas_brutas',coalesce(r.linhas_brutas,0),'elegiveis',coalesce(r.elegiveis,0)) ORDER BY e.ano,e.id_evento) FROM eventos e LEFT JOIN resultados r USING(id_evento) WHERE e.cadastrado OR coalesce(r.linhas_brutas,0)>0)) AS payload
