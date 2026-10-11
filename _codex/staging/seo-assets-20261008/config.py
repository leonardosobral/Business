from pathlib import Path
R = Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
B = R.parent / 'Business'
S = Path(__file__).resolve().parent
SOURCES = ['assets/js/runner-apps-menu-lazy.js', 'assets/js/runnerhub-event-filters.js',
           'assets/js/runnerhub-busca-page.js', 'assets/js/event-location-mapbox.js',
           'assets/js/event-route-mapbox.js', 'assets/css/runnerhub-institutional.css',
           'assets/css/event-location-mapbox.css', 'assets/css/event-route-mapbox.css']
TEMPLATES = ['includes/estrutura/menu_apps.cfm', 'includes/estrutura/header_slim.cfm',
             'includes/estrutura/head.cfm', 'busca/index.cfm', 'estado/index.cfm',
             'ajuda/index.cfm', 'sobre/index.cfm', 'privacidade/index.cfm',
             'atendimento/index.cfm', 'evento/index.cfm', 'embed/percursos/index.cfm']
GENERATED = [n.rsplit('.', 1)[0] + '.min.' + n.rsplit('.', 1)[1] for n in SOURCES]
OLD_SOURCES = ['assets/css/cores.css', 'assets/css/rr-audience-privacy.css',
               'assets/css/runnerhub-footer.css', 'assets/js/rr-audience-privacy.js',
               'assets/js/runnerhub-entry-prompts.js']
WATCH = ['Application.cfc', '.htaccess', 'evento/.htaccess', 'includes/estrutura/event_title_date.cfm',
         'includes/estrutura/seo-web-tools-head.cfm', 'includes/estrutura/seo-web-tools-body-end.cfm',
         'includes/estrutura/menu_apps_data.cfm', 'api/runner_apps_menu.cfm',
         'api/eventos_busca.cfm', 'api/search.cfm'] + SOURCES + OLD_SOURCES
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes',
       '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
