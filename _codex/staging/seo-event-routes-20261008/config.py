from pathlib import Path
B=Path('/Users/Shared/Projects/RunnerHub/Business');R=B.parent/'RoadRunners';S=Path(__file__).resolve().parent
TEMPLATES=['includes/card_evento_individual.cfm','includes/estrutura/event_title_date.cfm']
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
