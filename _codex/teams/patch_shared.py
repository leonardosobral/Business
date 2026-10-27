"""Only the exact Teams integration patches; reusable against preserved live sources."""
def once(text,old,new):
 if text.count(old)!=1:raise ValueError('Integration anchor missing or ambiguous: '+old[:80])
 return text.replace(old,new,1)
def patch(rel,text):
 if rel=='business/index.cfm':
  return once(text,'<cfinclude template="includes/backend/backend_login.cfm"/>','<cfinclude template="teams/includes/home_return.cfm"/>\n<cfinclude template="includes/backend/backend_login.cfm"/>')
 if rel=='business/includes/backend/business_google_callback.cfm':
  return once(text,'    <cfif VARIABLES.googleInviteReturn EQ "/convites/">','''    <cfif VARIABLES.googleSignInValidRedirect AND reFind("^/teams/(cadastro/|convites/)?(\\?.*)?$",VARIABLES.googleSignInRequestedRedirect)>
        <cfset VARIABLES.googleSignInRedirect = VARIABLES.googleSignInRequestedRedirect/>
    <cfelseif VARIABLES.googleInviteReturn EQ "/convites/">''')
 if rel=='business/services/accountDelegation/RequestBoundary.cfc':
  old="        // Personal library: never resolve or inherit the selected organization's permissions."
  new='''        // Teams is a personal-identity domain; membership is revalidated by its own service.
        if(listFind('/teams/,/teams/index.cfm,/teams/cadastro/,/teams/cadastro/index.cfm,/teams/convites/,/teams/convites/index.cfm,/teams/mail-worker.cfm',targetPath)) {
            var allowedQuery='team,tab,q,page,saved,accepted,token';
            var allowedForm='csrf,operation,team,athlete,member,invite,version,name,type,document,ownerName,technicalName,cref,crefUf,email,phone,whatsapp,city,uf,attendance,description,website,confirm,role,decision,note,evidence,cref_active,token';
            var valid=!len(pathInfo) && multipartValid && variables.policy.uniqueParameters(rawQuery) && variables.policy.uniqueParameters(rawBody) && listFind('GET,POST',uCase(method));
            for(var key in arguments.query)if(!listFindNoCase(allowedQuery,key)||!isSimpleValue(arguments.query[key]))valid=false;
            for(var key in arguments.form)if(key!='FIELDNAMES' && (!listFindNoCase(allowedForm,key)||!isSimpleValue(arguments.form[key])))valid=false;
            if(targetPath=='/teams/mail-worker.cfm' && (structCount(arguments.query)||structCount(arguments.form)))valid=false;
            if(!valid)result.status=403;
            return result;
        }
'''+old
  return once(text,old,new)
 if rel=='business/includes/estrutura/sidenav.cfm':
  old='<i class="fa-solid fa-building-user fa-fw me-3"></i><span>Contas</span>'
  text=once(text,old,'<i class="fa-solid fa-building-user fa-fw me-3"></i><span>Empresas</span>')
  anchor='            <!--- CONTAS E PARCEIROS --->'
  team='''            <li class="sidenav-item"><a class="sidenav-link" href="/teams/" data-menu-aliases="times assessorias clubes corrida"><i class="fa-solid fa-people-group fa-fw me-3"></i><span>Teams</span></a></li>

'''
  text=once(text,anchor,team+anchor)
  normal='            <!--- AJUDA --->'
  if normal not in text:raise ValueError('Normal navigation anchor missing')
  head,tail=text.rsplit(normal,1);text=head+team+normal+tail
  delegated='<a href="/">Início</a> · <a href="/gestao-clientes/">Gestão de clientes</a>'
  return once(text,delegated,delegated+' · <a href="/teams/">Meus Teams</a>')
 if rel=='rr/atleta/index.cfm':
  return once(text,'                    <div class="p-0">','                    <div class="p-0">\n                        <cfinclude template="../teams/includes/profile.cfm"/>')
 if rel=='rr/includes/estrutura/header.cfm':
  anchor='<!---<li><a class="dropdown-item" href="/clube/"><i class="fa fa-flag me-2"></i>Meu clube</a></li>--->'
  return once(text,anchor,'<li><a class="dropdown-item" href="/teams/meu-team/"><i class="fa-solid fa-people-group me-2"></i><cfif REQUEST.lang EQ "en">My Team<cfelseif REQUEST.lang EQ "es">Mi Team<cfelse>Meu Team</cfif></a></li>')
 raise ValueError('Unknown integration file: '+rel)
