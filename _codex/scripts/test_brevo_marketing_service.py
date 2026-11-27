"""Run the Brevo contract fixture with CommandBox and no provider credentials."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BOX = os.environ.get("COMMANDBOX_JAR", "/Users/Shared/Projects/ColdFusion Certification/box")
JAVA = os.environ.get("JAVA", "java")
FILES = {
    "services/BrevoMarketingService.cfc": "services/BrevoMarketingService.cfc",
    "services/EmailAddress.cfc": "services/EmailAddress.cfc",
    "docs/campanhas/selo-atleta-2026-11-27-brevo.html": "docs/campanhas/selo-atleta-2026-11-27-brevo.html",
    "_codex/tests/brevo-marketing-service.cfm": "tests.cfm",
}
with tempfile.TemporaryDirectory(prefix="rr-brevo-contract-") as workspace:
    scratch = Path(workspace)
    for source, dest in FILES.items():
        target = scratch / dest
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(ROOT / source, target)
    config = scratch / "config" / "business.local.cfm"
    config.parent.mkdir()
    config.write_text("""<cfscript>
variables.businessLocalConfig.brevoApiKey = "fixture-only";
variables.businessLocalConfig.brevoWebhookToken = repeatString("x",32);
businessLocalConfig.brevoFolderId = "5";
businessLocalConfig.brevoSenderId = "8";
</cfscript>""", encoding="utf-8")
    opens = ("sun.nio.ch", "java.util", "java.io", "java.nio", "java.lang", "java.net", "java.lang.reflect")
    command = [JAVA, *(f"--add-opens=java.base/{package}=ALL-UNNAMED" for package in opens),
               "-Dfile.encoding=UTF-8", "-Djava.awt.headless=true", "-cp", BOX, "cliloader.LoaderCLIMain",
               f"-CommandBox_home={scratch / 'commandbox'}", "execute", "tests.cfm"]
    env = {"PATH": os.environ["PATH"], "LC_ALL": "en_US.UTF-8", "HOME": workspace,
           "RR_BREVO_SENDER_ID": "3", "RUNNERHUB_OFFLINE_CFML_TESTS": "1", "TMPDIR": workspace}
    proc = subprocess.Popen(command, cwd=scratch, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    try:
        output, _ = proc.communicate(timeout=100)
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
    if proc.returncode or "BREVO_MARKETING_SERVICE_OK" not in output:
        raise SystemExit(output)
    print(output.strip().splitlines()[-1])
