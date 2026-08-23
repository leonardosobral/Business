# Ads advertiser workspace — design QA

- Source visual truth: `/Users/leonardosobral/.codex/generated_images/019f56ee-6381-7890-9447-62ba9d45c07d/exec-a11f557f-456b-4a4d-a5e6-4351e473511b.png`
- Source pixels: `1487 x 1058`
- Implementation screenshot: browser capture of `https://business.roadrunners.run/ads/` after the first publication (`1318` CSS px viewport; full-page browser artifact captured on 2026-08-23)
- Implementation URL: `https://business.roadrunners.run/ads/`
- Intended desktop viewport: reference `1487 x 1058`; implementation inspected at `1318` CSS px, density `1`
- State: authenticated advertiser overview with campaigns, balance, next steps and recent activity

## Full-view comparison evidence

The reference and the first published implementation were opened together in one comparison input. The overall hierarchy matches the selected direction: compact account health strip, campaign-first body, next steps and recent activity. The first implementation had a horizontally overflowing overview table (`850px` table inside a `725px` container), duplicated `##` anchors and unaccented advertiser copy.

## Focused region comparison evidence

The header/health strip, campaign table, next-steps panel, navigation tabs and recent-activity region were readable in the combined comparison. Campaign management, campaign form, payments, current/legacy history and internal administration were also inspected through their published routes.

## Findings

- P1 — corrected files still need a second publication and capture.
  - Location: `/ads/`, desktop authenticated advertiser state.
  - Evidence: the first published capture exposed issues; fixes now exist only in the local workspace.
  - Impact: the corrected table fit, anchors, accents and payment labels cannot be accepted until rendered.
  - Fix: publish the second correction set, recapture the overview and payments routes, and repeat the combined comparison.

## Required fidelity surfaces

- Fonts and typography: first render uses the existing Business typography consistently; accents were missing and have been corrected locally.
- Spacing and layout rhythm: main hierarchy is aligned with the reference; the overview table overflow was measured and corrected locally by removing management actions from the summary and lowering its minimum width.
- Colors and visual tokens: existing Business dark tokens and cyan action color are consistent with the selected direction.
- Image quality and asset fidelity: no new raster assets are used; existing Font Awesome icons rendered correctly.
- Copy and content: raw placement keys and UUIDs are absent; payment statuses now have friendly Portuguese labels locally.

## Primary interactions pending browser verification

- Passed: routes for overview, campaigns, campaign form, balance/payments, current history, legacy history and administration.
- Passed: campaign form remains closed by default and opens through `mode=new`.
- Passed: campaign management menu opens and exposes the expected non-destructive controls without submitting them.
- Passed: paid payment and R$ 50,00 credit appear correctly for Grupo STC.
- Passed: no document-level overflow at `1318px`; the first overview table overflow was isolated to its responsive container and corrected locally.
- Pending: second published capture and a narrow mobile viewport capture.

## Comparison history

1. First published comparison: found duplicated `##` anchors, missing Portuguese accents and an `850px` overview table inside a `725px` container.
2. Local fixes: single anchors for static links/forms; accented advertiser copy; friendly payment statuses; overview table reduced to five columns and `720px`, with detailed management retained on the campaigns tab.
3. Post-fix visual evidence: pending second publication.

final result: blocked
