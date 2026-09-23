from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_account_menu_exposes_both_catarinense_challenges_only_with_access():
    menu = (ROOT / "includes/estrutura/sidenav.cfm").read_text(encoding="utf-8")

    guarded_links = menu.rsplit(
        '<cfif VARIABLES.businessCanManageCatarinenseChallenges>', 1
    )[1].split("<!--- DIVULGAÇÃO --->", 1)[0]

    assert 'href="/desafios/catarinensecorridaderua/"' in guarded_links
    assert 'href="/desafios/catarinensetrailrun/"' in guarded_links
    assert guarded_links.rstrip().endswith("</cfif>")
