import javax.script.ScriptEngine;
import java.nio.file.*;
/** Synthetic local rendering; never boots Business or opens a database connection. */
public class CouponManagerCheck {
  public static void main(String[] args) throws Exception {
    Path root=Path.of(args[0]).toAbsolutePath(),work=Path.of(args[1]).toAbsolutePath();
    for(String name:new String[]{"CouponService.cfc","backend.cfm","form_cupom.cfm","event-fields.cfm","links.cfm"}) {
      Path dest=work.resolve("cupons-rr/includes/"+name);Files.createDirectories(dest.getParent());
      String source=Files.readString(root.resolve("cupons-rr/includes/"+name));
      if(!name.equals("CouponService.cfc") && !name.equals("backend.cfm")) source=source.replace("SESSION.couponManagerCsrf","cpTestCsrf");
      if(name.equals("CouponService.cfc")) {
        source=source.replace("queryExecute(","fixtureQuery(");
        source=source.substring(0,source.lastIndexOf("}"))+Files.readString(root.resolve("_codex/tests/coupon-query-fixture.cfm"))+"\n}";
      }
      Files.writeString(dest,source);
    }
    Files.copy(root.resolve("cupons-rr/home.cfm"),work.resolve("cupons-rr/home.cfm"),StandardCopyOption.REPLACE_EXISTING);
    System.setProperty("lucee.cli.contextRoot",work.toString());System.setProperty("lucee.base.dir",work.resolve("engine").toString());
    try {
      ScriptEngine engine=new lucee.runtime.script.CFMLTagEngineFactoryImpl().getScriptEngine();
      String fixture=Files.readString(root.resolve("_codex/tests/coupon-manager-fixture.cfm"));
      engine.eval("<cfsavecontent variable=\"couponFixtureHtml\">"+fixture+"</cfsavecontent>");
      String html=String.valueOf(engine.get("couponFixtureHtml"));
      if(!html.contains("Cadastrar cupom")||!html.contains("Eventos vinculados")||html.contains("<script>alert"))throw new Exception("Render assertions failed");
      String[] parts=html.split("<!--CP-NEW-->");
      Files.writeString(work.resolve("preview.html"),parts[0]+"</body></html>");
      Files.writeString(work.resolve("new.html"),html.substring(0,html.indexOf("<section class=\"cp-manager\">"))+parts[1]);
      ScriptEngine controller=new lucee.runtime.script.CFMLTagEngineFactoryImpl().getScriptEngine();
      controller.eval("<cfapplication name=\"coupon_controller_fixture\" sessionmanagement=\"true\"/><cfscript>REQUEST.businessIdentity={id=42};qPerfil=queryNew('id,is_admin','integer,bit',[[42,true]]);VARIABLES.businessEffectiveIsAdmin=true;</cfscript><cfinclude template=\"/cupons-rr/includes/backend.cfm\"/><cfif cpData.total NEQ 2><cfthrow message=\"Controller failed\"/></cfif>");
      System.out.println("PASS: coupon validation, permission/query contracts, create/edit/link/status flows with mock database, and actual CFML rendering. Preview: "+work.resolve("preview.html"));
      System.exit(0);
    }catch(Exception e){e.printStackTrace();System.exit(1);}
  }
}
