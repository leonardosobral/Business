<cfscript>
checks=0;
function check(required boolean value,required string label){if(!value)throw(type='YoutubeTest.Failed',message=label);checks++;}
actor=queryExecute('SELECT min(id) AS id FROM tb_usuarios WHERE is_admin=true',{},{datasource='runner_dba'}).id[1];
manager=new services.YoutubeChannelManager(actor);
p=manager.parseSource('https://www.youtube.com/@RunTVBrasil','channel');
check(p.channel_handle EQ '@RunTVBrasil' AND p.source_type EQ 'channel','Cole um link para identificar o canal');
p=manager.parseSource('UCxmZoyAOr6HkyAkW2c2YSog','channel');check(len(p.channel_id) EQ 24,'Aceita canal por ID técnico legado');
p=manager.parseSource('https://www.youtube.com/playlist?list=PL1234567890123','playlist');check(p.playlist_id EQ 'PL1234567890123','Identifica playlist');
for(value in ['https://evil.example/@RunTVBrasil','https://www.youtube.com.evil.example/@RunTVBrasil','http://127.0.0.1/@RunTVBrasil','https://youtube.com/watch?v=12345678901']){
 denied=false;try{manager.parseSource(value,'channel');}catch(YoutubeChannel.Validation e){denied=true;}
 check(denied,'Rejeita fonte inválida: '&value);
}
check(arrayLen(manager.search('page','a')) EQ 0,'Busca exige pelo menos dois caracteres');
check(arrayLen(manager.search('user','zzzzcodex-sem-usuario-zzzz')) EQ 0,'Busca de usuários sem resultado');
nonAdmin=queryExecute('SELECT min(id) AS id FROM tb_usuarios WHERE NOT coalesce(is_admin,false)',{},{datasource='runner_dba'}).id[1];
denied=false;try{new services.YoutubeChannelManager(nonAdmin);}catch(YoutubeChannel.Forbidden e){denied=true;}
check(denied,'Gerenciador bloqueia usuário sem administração global');
marker='codex-yt-'&left(replace(createUUID(),'-','','all'),12);
fields={name='Teste de canal '&marker,source_type='channel',source='@'&marker,max_results='5',sort_order='80',min_duration_seconds='',max_duration_seconds='',id_pagina='',id_usuario='',descricao='',instagram_url='',enabled='1'};
transaction {
 id=manager.save(fields);
 saved=manager.get(id);check(saved.recordCount EQ 1 AND saved.enabled AND saved.max_results EQ 5,'Cria canal com parâmetros explícitos');
 check(saved.channel_handle EQ fields.source,'Salva handle normalizado');
 originalCode=saved.code;
 links=queryExecute('SELECT pu.id_pagina,pu.id_usuario FROM tb_paginas_usuarios pu JOIN tb_paginas p ON p.id_pagina=pu.id_pagina JOIN tb_usuarios u ON u.id=pu.id_usuario WHERE pu.id_pagina>0 AND pu.id_usuario>0 ORDER BY pu.id_usuario,pu.id_pagina LIMIT 1',{},{datasource='runner_dba'});
 fields.id_pagina=numberFormat(links.id_pagina,'0');fields.id_usuario=numberFormat(links.id_usuario,'0');
 revision=saved.revision;fields.id_youtube_canal=id&'';fields.revision=revision;fields.name='Canal renomeado';
 manager.save(fields);saved=manager.get(id);check(saved.code EQ originalCode,'Mantém código usado pelos vídeos existentes');
 check(saved.id_pagina EQ links.id_pagina AND saved.id_usuario EQ links.id_usuario AND len(saved.user_name),'Vínculos e nomes preservados no servidor');
 manager.toggle(id,saved.revision);saved=manager.get(id);check(!saved.enabled,'Desativa canal');
 manager.remove(id,saved.revision);check(manager.get(id).recordCount EQ 0,'Remove somente fonte cadastrada');
 transaction action='rollback';
}
fields.id_youtube_canal='0';
transaction {
 duplicateDenied=false;manager.save(fields);try{manager.save(fields);}catch(YoutubeChannel.Validation e){duplicateDenied=true;}
 transaction action='rollback';
}
check(duplicateDenied,'Não cadastra a mesma fonte duas vezes');
transaction {
 fields.id_youtube_canal='0';fresh=manager.save(fields);fields.id_youtube_canal=fresh&'';fields.revision='antiga';
 conflict=false;try{manager.save(fields);}catch(YoutubeChannel.Conflict e){conflict=true;}
 transaction action='rollback';
}
check(conflict,'Impede sobrescrever uma edição concorrente');
check(queryExecute('SELECT count(*) AS n FROM tb_youtube_canais WHERE channel_handle=:handle',{handle={value=fields.source,cfsqltype='cf_sql_varchar'}},{datasource='runner_dba'}).n EQ 0,'Fixtures revertidas');
users=manager.search('user','ge');check(arrayLen(users) LTE 12,'Busca de usuários limitada');
pages=manager.search('page','corr');check(arrayLen(pages) LTE 12,'Busca de páginas limitada');
structClear(FORM);structClear(URL);qPerfil=queryNew('id,is_admin','integer,bit',[{id=actor,is_admin=true}]);URL.canal_novo='1';
savecontent variable='screen' {include '../portal/canais/home.cfm';}
check(find('Página no Road Runners',screen) AND find('Usuário responsável / autor',screen),'Formulário renderiza vínculos por nome');
check(find('data-name-picker="page"',screen) AND find('data-name-picker="user"',screen),'Campos de busca e seleção disponíveis');
check(!find('cf_sql_boolean',screen),'Renderização sem erro de SQL');
writeOutput('YOUTUBE_MANAGER_SOURCE_PASSED '&checks);
</cfscript>
