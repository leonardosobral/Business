component output=false {
 private query function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource="runner_dba",timeout=10});}
 private struct function p(required any v,string type="cf_sql_bigint"){return {value=v,cfsqltype=type};}
 private void function valid(required any year,any runId=0){
  if(!listFind("2025,2026",toString(year)) || !reFind("^[0-9]{1,18}$",toString(runId)))throw(type="Study.Validation",message="Edição ou congelamento inválido.");
 }
 public any function catalog(){
  var q=db("SELECT coalesce(jsonb_agg(jsonb_build_object('ano',d.ano,'cell_id',d.cell_id,'notebook_id',c.notebook_id,'caderno_id',n.caderno_id,'publicacao_id',coalesce(d.publicacao_id,0),'versao',d.versao,'run_atual',p.run_id,'publicado_em',p.publicado_em,'nota',p.nota,'runs',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'cell_version',r.cell_version,'started_at',r.started_at,'frozen_at',r.frozen_at) ORDER BY r.id DESC),'[]') FROM estudo.notebook_runs r WHERE r.cell_id=d.cell_id AND r.frozen AND r.status='ok' AND NOT r.truncated)) ORDER BY d.ano),'[]')::text AS document FROM estudo.web_destinos d JOIN estudo.notebook_cells c ON c.id=d.cell_id JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id LEFT JOIN estudo.web_publicacoes p ON p.id=d.publicacao_id");
  return deserializeJSON(q.document[1]);
 }
 public struct function preview(required any year,required any runId){
  valid(year,runId);
  try{
   var q=db("SELECT estudo.web_payload_conferido(CAST(:y AS integer),:r)::text AS payload",{y=p(year),r=p(runId)});
   return {ano=val(year),run_id=toString(runId),payload_json=q.payload[1]};
  }catch(database e){throw(type="Study.Validation",message="Pacote recusado: confira a célula de saída, o congelamento completo, o ano e o contrato de campos da web.");}
 }
 public struct function publish(required any year,required any runId,required any expected,required string note,required any actor){
  valid(year,runId);
  if(!reFind("^[0-9]{1,18}$",toString(expected)) || !len(trim(note)) || len(note)>2000)throw(type="Study.Validation",message="Informe uma nota de publicação de até 2.000 caracteres.");
  var q=queryNew("id");
  transaction {
   var current=db("SELECT coalesce(publicacao_id,0) AS id FROM estudo.web_destinos WHERE ano=:y FOR UPDATE",{y=p(year)});
   if(!current.recordCount || current.id[1]!=expected)throw(type="Study.Conflict",message="A versão no ar mudou. Atualize a aba antes de publicar.");
   try{q=db("SELECT estudo.publicar_web(CAST(:y AS integer),:r,:e,:a,:n) AS id",{y=p(year),r=p(runId),e=p(expected),a=p(actor),n=p(trim(note),"cf_sql_varchar")});}
   catch(database e){throw(type="Study.Validation",message="Publicação recusada. Confira o congelamento e use Conferir pacote antes de tentar novamente.");}
  }
  return {id=toString(q.id[1]),ano=val(year)};
 }
}
