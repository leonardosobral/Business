import javax.script.ScriptEngine;
import java.nio.file.*;
/** Runs the actual Agenda dispatch with disposable external boundaries; no network/database writes. */
public class AgendaEditorCfmlCheck {
  public static void main(String[] args) throws Exception {
    Path root=Path.of(args[0]).toAbsolutePath(), runtime=Path.of(args[1]).toAbsolutePath();
    Files.createDirectories(runtime);
    System.setProperty("lucee.cli.contextRoot",runtime.toString());
    System.setProperty("lucee.base.dir",runtime.resolve("engine").toString());
    ScriptEngine engine=new lucee.runtime.script.CFMLScriptEngineFactory().getScriptEngine();
    try {
      String service=Files.readString(root.resolve("administracao/agenda/includes/service.cfm"));
      engine.eval(service.replace("<cfscript>","").replace("</cfscript>",""));
      String api=Files.readString(root.resolve("administracao/agenda/api.cfm"));
      engine.eval(api.substring(api.indexOf("<cfscript>")+10,api.lastIndexOf("\ntry {")));
      engine.eval(Files.readString(root.resolve("_codex/tests/google-agenda-service.cfscript")));
      System.out.println("PASS: actual Agenda dispatch, dates, conflicts, RSVP, organizer, meeting and reminders");
      System.exit(0);
    } catch(Exception ex) {ex.printStackTrace();System.exit(1);}
  }
}
