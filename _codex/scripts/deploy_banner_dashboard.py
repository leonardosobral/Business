"""Publish only the Business banner dashboard with guarded backups and native CF compile.

Uses the established HOUSE publisher; no SQL, service restart or git writes.
Usage: python3 _codex/scripts/deploy_banner_dashboard.py prepare|publish|verify|rollback manifest.json receipt.json
"""
import deploy_house_banner_scope as release

release.ALLOWED = {
    'Business': {
        'portal/includes/banner_dashboard_helpers.cfm',
        'portal/includes/banner_dashboard_backend.cfm',
        'portal/includes/banner_dashboard_list.cfm',
        'assets/css/portal-banner-dashboard.css',
        'assets/js/portal-banner-dashboard.js',
        'portal/banners/home.cfm',
    }
}

if __name__ == '__main__':
    release.main()
