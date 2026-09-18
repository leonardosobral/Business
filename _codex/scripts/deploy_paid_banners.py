"""Publish the reviewed paid-banner runtime with guarded backups and CF compile.

Reuses the established publisher. SQL and private environment flags are excluded.
Usage: python3 _codex/scripts/deploy_paid_banners.py prepare|publish|verify|rollback manifest.json receipt.json
"""
import deploy_house_banner_scope as release

release.ALLOWED = {
    'Business': {
        'portal/banners/index.cfm', 'portal/banners/home.cfm',
        'portal/includes/paid_banner_helpers.cfm',
        'portal/includes/paid_banner_actions.cfm',
        'portal/includes/paid_banner_queries.cfm',
        'portal/includes/paid_banner_backend.cfm',
        'portal/includes/paid_banner_form.cfm',
        'portal/includes/paid_banner_list.cfm',
        'portal/includes/paid_banner_home.cfm',
        'assets/css/paid-banner-workspace.css',
        'portal/includes/banner_management_backend.cfm',
        'portal/includes/banner_form.cfm',
        'portal/includes/banner_dashboard_list.cfm',
        'includes/backend/backend_login.cfm',
        'includes/backend/business_pending_access.cfm',
        'includes/estrutura/sidenav.cfm',
        'ads/includes/backend.cfm', 'ads/includes/workspace_admin.cfm',
        'ads/includes/workspace_history.cfm', 'ads/includes/workspace_payments_home.cfm',
    },
    'RoadRunners': {
        'services/AdsV1BannerDeliveryService.cfc',
        'services/AdsV1ConfigService.cfc',
        'includes/ads_v1/banner_delivery.cfm',
        'includes/ads_v1/banner_slot.cfm',
        'includes/ads_v1/runtime_config.cfm',
        'api/ads/v1/cpc-click.cfm',
    },
}

if __name__ == '__main__':
    release.main()
