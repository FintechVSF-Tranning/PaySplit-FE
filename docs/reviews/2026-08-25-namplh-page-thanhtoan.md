# Review, namplh/page-thanhtoan, 2026-08-25

**Reviewed by**: gpt-5 (fresh review agent)
**Scope**: 12 backend files and 42 frontend files, uncommitted changes in `PaySplit-BE` and `PaySplit-FE`
**Verdict**: Approve with nits

## Summary
The backend `GET /api/v1/bills` addition is compatible with the existing response shape. `BillListItem` keeps the old bill fields at the top level, sqlc output was regenerated, and the new query computes `payer_display_name`, `paid_member_count`, and `member_count` in one database round trip. The two previous blocking Flutter issues are fixed: `/bills` now defaults to the all bills tab, and pending confirmation receivables no longer appear in the normal reminder list.

## Major
None.

## Fixed from prior review
### ✅ Hóa đơn bottom navigation now opens the bills tab
`/bills` defaults to `SettlementTab.bills`, while `/settlement` still defaults to `SettlementTab.payable` at `lib/app/router/app_router.dart:151`. The new router regression test taps the real bottom nav Hóa đơn item and expects `AllBillsTab` at `test/app/app_router_navigation_test.dart:97`.

### ✅ Pending confirmation receivables are no longer duplicated as reminder rows
The repository keeps `activeReceivable` for balance totals at `lib/features/settlement/data/repositories/settlement_repository_impl.dart:23`, but only adds awaiting receivables to `receivableDebts` at `lib/features/settlement/data/repositories/settlement_repository_impl.dart:38`. `ReceivableProofsTab` also defensively filters reminder rows to `DebtStatus.awaiting` at `lib/features/settlement/presentation/widgets/receivable_proofs_tab.dart:40`. Regression coverage asserts pending confirmation debt is shown only as a proof and never shows `Nhắc nợ` at `test/features/settlement/settlement_page_widget_test.dart:377`.

## Minor
### 🟡 The direct confirmation button does not confirm directly, `lib/features/settlement/presentation/pages/settlement_page.dart:456`
**Problem**: The card button text says `Xác nhận đã nhận tiền`, and AC 5 says that tap calls the confirm endpoint. The page wires `onConfirmProof` to `_refreshAndOpenProof`, so tapping the button opens the proof sheet and requires a second confirmation tap instead.

**Why it matters**: This is not data unsafe, and the extra proof view can be a sensible guardrail before confirming money received. It still disagrees with the written acceptance criterion and with the button wording, so the behavior should be made explicit after merge.

**Suggested fix**: Either wire the card action to `confirmPendingPayment` as specified, or rename the card button to make it clear that it opens review first. Cover the chosen behavior in a widget test.

### 🟡 The all bills CTA is still a dead end, `lib/features/settlement/presentation/pages/settlement_page.dart:479`
**Problem**: `AllBillsTab` renders a Quét bill action, but the page handler only shows `Mở máy quét OCR hóa đơn` as a snackbar. AC 7 expects the bills feed to continue bill work from this hub, including draft navigation.

**Why it matters**: The feed now displays payer and progress data correctly, but it still cannot start or continue a real bill workflow. Users can see the right summary and then hit a placeholder action. This is acceptable as a non-blocking follow-up if OCR/draft routing is intentionally outside this merge.

**Suggested fix**: Route scan and draft bill taps to the existing bill OCR flow, or remove the CTA until that flow is wired.

## Strengths
The backend list contract is additive and well covered by handler, usecase, and repository tests. The SQL avoids an application level N plus one query, uses existing indexes on `bills(group_id, created_at, id)`, `bill_shares(bill_id)`, and the unique debt pair, and keeps authorization in the existing usecase membership check.

The Flutter settlement repository now reads the real backend envelopes, maps integer VND strings safely, sends idempotency keys on mutating settlement calls, and paginates groups, debts, and bills. The persistent navigation shell keeps branch state and honors reduced motion. The proof image modal fix avoids build time `setState`, and no lightning glyph remains in product code.

## Test coverage
Configured tests exist in both repos. The current test set covers the new backend bill list fields, sqlc mapping through repository integration coverage when Postgres is available, settlement JSON mapping, idempotency headers, proof upload behavior, multiple pending proof cards, shell persistence, smooth branch switching, reduced motion, `/bills` route tab selection, and pending confirmation filtering.

Fresh targeted run: `flutter test test/app/app_router_navigation_test.dart test/features/settlement/settlement_repository_impl_test.dart test/features/settlement/settlement_page_widget_test.dart` passes 15/15. Known proof gaps remain acceptable for this merge: the PostgreSQL integration test is skipped while `localhost:5433` is down, and the Cloudinary live integration was intentionally not run because it uploads externally.

Scope: no matching frontend `docs/scope/` row was present to tick. Backend scope already marks split and settlement review complete.
