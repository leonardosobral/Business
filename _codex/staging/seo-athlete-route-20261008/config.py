from pathlib import Path
R=Path("/Users/Shared/Projects/RunnerHub/RoadRunners")
B=R.parent/"Business"
S=Path(__file__).resolve().parent
SSH=["ssh","-o","BatchMode=yes","-o","ConnectTimeout=10","-o","StrictHostKeyChecking=yes","-i","/Users/leonardosobral/.ssh/webs","root@ssh.runnerhub.run"]
