<cfscript>
guard=new estudo.includes.SqlReadGuard();
checks=0;
function check(required boolean yes,required string label){if(!yes)throw(message="FAIL: "&label);checks++;}
for(sql in ["SELECT 1;", "SELECT public.extrair_faixa_etaria('20-29')", "/* nota */ WITH x AS (SELECT 1 AS n) SELECT * FROM x", "SELECT 'delete; --' AS texto", "SELECT $$; update $$ AS texto", "SELECT E'aspas\\'';' AS texto", "SELECT ""cidade"" FROM public.tb_evento", "SELECT 1 /* a /* b */ c */; -- fim"]){
 check(len(guard.validate(sql))>0,"aceita "&sql);
}
for(sql in ["DELETE FROM t","SELECT 1; SELECT 2","WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x","SELECT pg_sleep(1)","SELECT ""set_config""('role','runner_dba',false)","SELECT pg_catalog.set_config('role','runner_dba',true)","SELECT * INTO x FROM t","SELECT dblink('a','b')","SELECT U&""set_config""('x','y',true)","SELECT 1 /* aberto","SELECT 'aberto","SELECT nextval('x')","SELECT lo_import('/etc/passwd')","SELECT my_write_function()"]){
 rejected=false;try{guard.validate(sql);}catch(Study.Validation e){rejected=true;}
 check(rejected,"rejeita "&sql);
}
writeOutput("GUARD_PASS "&checks&chr(10));
</cfscript>