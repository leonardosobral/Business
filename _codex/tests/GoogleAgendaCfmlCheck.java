import javax.script.ScriptEngine;
import java.nio.file.*;
/** Offline CFML regression runner. Supply Lucee + servlet + JSP jars on the classpath. */
public class GoogleAgendaCfmlCheck {
    public static void main(String[] args) throws Exception {
        Path root=Path.of(args[0]).toAbsolutePath();
        Path runtime=Path.of(args[1]).toAbsolutePath();
        Files.createDirectories(runtime);
        System.setProperty("lucee.cli.contextRoot",runtime.toString());
        System.setProperty("lucee.base.dir",runtime.resolve("engine").toString());
        ScriptEngine engine=new lucee.runtime.script.CFMLScriptEngineFactory().getScriptEngine();
        try {
            String service=Files.readString(root.resolve("administracao/agenda/includes/service.cfm"));
            engine.eval(service.replace("<cfscript>","").replace("</cfscript>",""));
            String api=Files.readString(root.resolve("administracao/agenda/api.cfm"));
            api=api.substring(api.indexOf("<cfscript>")+10,api.lastIndexOf("\ntry {"));
            engine.eval(api);
            String callback=Files.readString(root.resolve("administracao/agenda/oauth/callback.cfm"));
            callback=callback.substring(callback.indexOf("<cfscript>")+10,callback.indexOf("</cfscript>"));
            engine.eval("function compileCallbackOnly() {"+callback+"}");
            engine.eval(Files.readString(root.resolve("_codex/tests/google-agenda-service.cfscript")));
            System.out.println("PASS: service/API/OAuth compile and offline backend regressions");
            System.exit(0);
        } catch(Exception ex) { ex.printStackTrace();System.exit(1); }
    }
}
