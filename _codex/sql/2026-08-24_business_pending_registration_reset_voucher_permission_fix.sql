-- Hotfix para instalacoes que aplicaram a migration de reset antes da
-- permissao minima de exclusao de voucher legado.

BEGIN;

GRANT DELETE ON TABLE ads.tb_ad_vouchers TO ads_owner;

COMMIT;
