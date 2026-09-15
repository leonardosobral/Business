import javax.script.ScriptEngine;
import java.nio.file.*;
/** Offline synthetic fixture only. Does not bootstrap Business or connect to databases. */
public class HelpdeskWorkspaceCheck {
  public static void main(String[] args) throws Exception {
    Path root=Path.of(args[0]).toAbsolutePath(), work=Path.of(args[1]).toAbsolutePath();
    Files.createDirectories(work);
    for(String file:new String[]{"HelpdeskWorkspace.cfc","workspace-init.cfm","workspace.cfm","workspace-sectors.cfm","ai-editor.cfm"}) {
      Path dest=work.resolve("helpdesk/includes/"+file); Files.createDirectories(dest.getParent());
      Files.copy(root.resolve("helpdesk/includes/"+file),dest,StandardCopyOption.REPLACE_EXISTING);
    }
    System.setProperty("lucee.cli.contextRoot",work.toString());
    System.setProperty("lucee.base.dir",work.resolve("engine").toString());
    ScriptEngine engine=new lucee.runtime.script.CFMLTagEngineFactoryImpl().getScriptEngine();
    try {
      String fixture=Files.readString(root.resolve("_codex/tests/helpdesk-workspace-fixture.cfm"))
        .replace("template=\"helpdesk/","template=\"/helpdesk/");
      engine.eval("<cfsavecontent variable=\"hdFixtureHtml\">"+fixture+"</cfsavecontent>");
      String html=String.valueOf(engine.get("hdFixtureHtml"));
      if(!html.contains("Central de atendimento")||!html.contains("Enviar resposta")||html.contains("<script>alert")) throw new Exception("Rendered fixture assertions failed");
      Files.writeString(work.resolve("preview.html"),html);
      System.out.println("PASS: CFML filter contracts and actual workspace render. Fixture: "+work.resolve("preview.html"));
      System.exit(0);
    } catch(Exception e) { e.printStackTrace();System.exit(1); }
  }
}
