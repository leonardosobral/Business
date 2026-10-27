<cfscript>
teamTitle='Crew & Companhia';teamError='';teamSuccess='';teamReady=true;teamCsrf=repeatString('a',64);teamUser={id=142,is_admin=true};teamId=1;teamCanWrite=true;
teamTypeLabels={TREINADOR='Treinador',ASSESSORIA='Assessoria',CLUBE='Clube',ACADEMIA='Academia',GRUPO='Grupo / running crew',EMPRESA='Empresa'};
tt={id_team=1,name='Crew <script>alert(1)</script>',type='GRUPO',document='52998224725',owner_name='Titular',technical_name='Responsável técnico',cref='123456-G',cref_uf='SC',email='contato@example.org',phone='48999998888',whatsapp='48999998888',city='Florianópolis',uf='SC',attendance='AMBOS',description='Corrida para todas as pessoas.',website='https://example.org',version=2};
teamMembersAction='/teams/?team=1&tab=equipe';teamMemberBase='/teams/';teamMemberFilters={team=1,tab='equipe'};teamPostOperation='';teamExistingSearch='';teamCandidateRows=queryNew('id,name,email');
tw={role='OWNER',adminPolicy={roles='ADMIN,VIEWER',canEdit=true,canRemove=true},admins=queryNew('user_id,name,email,role','', [{user_id=142,name='Titular',email='titular@example.org',role='OWNER'}]),invites=queryNew('id_invite,email,role,expires_at,accepted_at,revoked_at')};
savecontent variable='html' {include '../teams/includes/header.cfm';writeOutput('<section class="teams-hero"><span class="teams-eyebrow">Road Runners Teams</span><h1>Seu time tem lugar aqui.</h1><p>Reúna atletas e acompanhe seus resultados no RR.</p></section>');include '../teams/includes/registration.cfm';include '../teams/includes/admins.cfm';include '../teams/includes/footer.cfm';}
if(!find('&lt;script&gt;',html)||find('<script>alert(1)</script>',html))throw(type='Teams.Test',message='Dados do cadastro não escapados.');
if(!find('name="version" value="2"',html)||!find('name="csrf"',html)||!find('name="cref"',html))throw(type='Teams.Test',message='Formulários completos com versão e CSRF.');
writeOutput('TEAMS_RENDER_PASSED ' & toBase64(charsetDecode(html,'UTF-8')));
</cfscript>
