component output=false {
 public struct function annual() {
  var q=queryExecute("SELECT r.id,r.cell_id,r.cell_version,c.notebook_id,c.version AS current_version,r.frozen_at,CAST(r.result->'rows'->0->'payload' AS text) AS payload FROM estudo.notebook_cells c JOIN estudo.notebook_runs r ON r.cell_id=c.id WHERE c.source_key='bqc-2026-anual-output' AND NOT c.archived AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1 AND r.result->'columns'='[""payload""]'::jsonb AND jsonb_array_length(r.result->'rows')=1 ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1",{},{datasource="runner_dba",timeout=10});
  if(!q.recordCount)throw(type="Study.Missing",message="Congele a saída anual no notebook para abrir o rascunho.");
  var payload=deserializeJSON(q.payload[1]);
  if(!isStruct(payload) || !structKeyExists(payload,'meta') || payload.meta.ano!=2026 || !structKeyExists(payload.meta,'edicao_trabalho') || payload.meta.edicao_trabalho.edicao!='anual-2026' || !structKeyExists(payload,'series') || !isArray(payload.series) || !structKeyExists(payload,'comparacoes') || !isArray(payload.comparacoes) || !structKeyExists(payload,'comparativo') || !structKeyExists(payload,'totais_atuais'))throw(type="Study.Validation",message="O congelamento anual não corresponde ao contrato de 2026.");
  return {payload_json=q.payload[1],run_id=q.id[1],cell_id=q.cell_id[1],section_id=q.notebook_id[1],cell_version=q.cell_version[1],current_version=q.current_version[1]};
 }
 public any function catalog() {
  var q=queryExecute("SELECT jsonb_build_object('publicacao_q3',p.publicacao_id,'run_q3',w.run_id,'caderno_id',6,'mapa',(SELECT notebook_id FROM estudo.notebooks WHERE source_key='bqc-2026-edicoes'),'anual_secao',(SELECT notebook_id FROM estudo.notebooks WHERE source_key='bqc-2026-anual'),'anual_celula',(SELECT id FROM estudo.notebook_cells WHERE source_key='bqc-2026-anual-output'),'anual_run',(SELECT r.id FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id WHERE c.source_key='bqc-2026-anual-output' AND r.frozen AND r.status='ok' AND NOT r.truncated ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1))::text AS payload FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id WHERE p.codigo='previa-2026-q3'",{},{datasource="runner_dba",timeout=10});
  return deserializeJSON(q.payload[1]);
 }
}