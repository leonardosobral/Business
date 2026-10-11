from pathlib import Path
B=Path('/Users/Shared/Projects/RunnerHub/Business');R=B.parent/'RoadRunners';S=Path(__file__).resolve().parent
SOURCES=['assets/js/rr-audience.js','assets/css/runnerhub-home.css','assets/css/runnerhub-estado-cidades.css','assets/js/runnerhub-state-filter.js','assets/js/runnerhub-estado-cidades.js']
GENERATED=[x.rsplit('.',1)[0]+'.min.'+x.rsplit('.',1)[1] for x in SOURCES]
TEMPLATES=['index.cfm','estado/index.cfm','includes/filtros.cfm','includes/analytics/bootstrap.cfm']
WATCH=['Application.cfc','.htaccess','atleta/.htaccess','evento/index.cfm','includes/estrutura/head.cfm','includes/estrutura/header_tema.cfm','includes/estrutura/home_hero_busca.cfm','includes/backend/backend_estado_cidades.cfm','services/AudienceMeasurementService.cfc','services/AudienceRequestControlService.cfc','api/analytics/collect.cfm','includes/analytics/privacy_controls.cfm','includes/backend/backend_login.cfm']+SOURCES
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
VERSION='20261008seo2'
