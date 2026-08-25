# 0007. Debt Settlement and Proof Review Hub UI Specification

**Date**: 2026-08-25  
**Status**: Proposed  
**Target release**: V1  
**Platform**: Flutter 3.x, iOS and Android  
**Feature areas**: `features/bills/`, `features/home/`, `features/groups/`  
**Design source**: [`PaySplit-UI/index.html`](../../../PaySplit-UI/index.html), [`PaySplit-FE/docs/specs/ui-context.md`](ui-context.md)  
**Companion Backend Specs**:
- [`PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md`](../../../PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md) (Debt state machine, Single Creditor VietQR generation, proof submission and confirmation)
- [`PaySplit-BE/docs/specs/0002-group-management-v1/index.md`](../../../PaySplit-BE/docs/specs/0002-group-management-v1/index.md) (Group member profiles and bank account management)
- [`PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md`](../../../PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md) (Bill feed and receipt data)

---

## Summary

The Debt Settlement and Proof Review Hub serves as the central control surface for managing peer to peer debts, generating dynamic VietQR codes, and reviewing electronic bank transfer proofs. Users can access the hub directly from the bottom navigation bar or through the debt overview on the home screen. The interface groups unsettled debts by creditor to enable single creditor batch payments and provides immediate actions to approve or reject submitted transfer proofs.

---

## Context

Managing shared expenses across multiple groups often leads to scattered debt records. A user may owe money to the same friend in two different groups, such as a lunch bill in a work group and a hotel bill in a travel group. Without a unified interface, tracking obligations requires navigating through every individual group.

VietQR transfers require transferring money directly to a single destination bank account. Combining debts owed to different people into one payment is physically impossible in the banking network. The hub solves this by grouping payable debts by creditor, allowing one click batch payment generation for all bills owed to the same person.

Creditors also need a clear workflow to verify incoming bank transfers without manually matching transaction logs. When debtors submit a screenshot of their banking application, the creditor receives a notification and can review the transaction reference code, source account, timestamp, and debtor note before updating the debt to settled status.

---

## Requirements

**User stories**:
- As a Debtor, I want to see all my payable debts grouped by creditor so that I can settle multiple expenses in one VietQR transfer.
- As a Debtor, I want to submit a screenshot of my bank transfer proof and an optional note so that my creditor can quickly verify and approve the payment.
- As a Creditor, I want to receive transfer proofs and confirm or reject them with a clear reason so that debt balances stay accurate.
- As a Creditor, I want to send friendly reminders to debtors with an anti spam cooldown so that overdue debts get resolved without awkward confrontation.
- As a Group Member, I want to browse past settled transactions and view historic proof receipts so that any future dispute can be verified with audit evidence.

**Acceptance criteria**:

- **AC-1 (Entry Triggers and Navigation)**:
  - Users can open the hub by tapping the `🧾 Hóa đơn` tab in the bottom navigation bar from any screen.
  - Users can open the hub by tapping the `[ Xem tất cả ]` button in the Actionable Debts card on the Home screen, which automatically selects the appropriate tab (`Cần trả` or `Cần thu`).
  - The top bar displays a back button returning to the previous screen, a screen title, a subtitle, a search icon button, and a bank account settings shortcut.

- **AC-2 (Summary Header and Quick Actions)**:
  - The top summary card displays the total payable balance in red (`#DC2626`) and the total receivable balance in green (`#059669`) across all active groups.
  - When there are pending proofs awaiting caller confirmation, a warning banner `1 proof đang chờ duyệt` appears with a pulsing dot. Tapping it switches to the `Cần thu` tab immediately.
  - The `[ Trả nợ ⚡ ]` button opens the `sheet-select-debt` modal for single creditor debt batching.

- **AC-3 (Tab 1: Payable Debts and Single Creditor Batching)**:
  - Displays all unsettled debts where the caller is the debtor, showing creditor avatar, name, group context, bill title, and amount in Monospace font.
  - Tapping `[ Trả QR ⚡ ]` on an individual debt opens the `sheet-vietqr` modal preloaded with the exact debt amount, recipient bank, account number, account holder, and reference code.
  - The `sheet-select-debt` modal groups debts by creditor. Debts belonging to the same creditor can be checked or unchecked with reactive total updates. Tapping pay generates one VietQR code for the selected subset through `POST /api/v1/groups/{groupId}/payments/qr`.

- **AC-4 (Dynamic VietQR Generation and Proof Upload Modal)**:
  - Displays a high contrast VietQR code containing the NAPAS 247 payload, recipient bank name, account number with a copy button, account holder name, and unique reference code (`PAY...`) with a copy button.
  - Provides an optional text area for debtor note (`payments.note`, max 500 characters).
  - Tapping `[ Tải ảnh biên lai đã chuyển ]` opens the device image picker (JPEG, PNG, HEIC up to 10 MB), uploads the image, and submits the proof through `POST /api/v1/groups/{groupId}/payments/{paymentId}/proof`. Upon success, the payment and covered debts transition to `pending_confirmation`.

- **AC-5 (Tab 2: Receivable Debts and Pending Proof Priority Card)**:
  - When incoming payments are in `pending_confirmation` status, they are pinned at the top in a priority proof review card.
  - The card displays debtor name, avatar, timestamp, amount, debtor message note, and a summary of bank details (recipient bank, source account, transaction code FT).
  - Tapping the mini slip preview opens the full `sheet-proof-review` bottom sheet.
  - Tapping `[ ✓ Xác nhận đã nhận tiền ]` calls `POST /api/v1/groups/{groupId}/payments/{paymentId}/confirm`, transitions all covered debts to `settled`, plays a light haptic feedback vibration, and updates net balances immediately.
  - Tapping `[ ✕ Từ chối ]` opens a rejection dialog requiring a reason text (1 to 500 characters), then calls `POST /api/v1/groups/{groupId}/payments/{paymentId}/reject`, returning all debts to `awaiting`.

- **AC-6 (Anti Spam Debt Reminder Action)**:
  - For debts in `awaiting` status where the caller is creditor, a `[ 🔔 Nhắc nợ ]` button is visible.
  - Tapping the button calls `POST /api/v1/groups/{groupId}/debts/{debtId}/remind`.
  - The UI starts a 60 second local countdown timer and disables the button to prevent rapid repeated taps. Backend enforces a limit of 3 reminders per debt with at least 24 hours between sends.

- **AC-7 (Tab 3: All Bills Feed Across Groups)**:
  - Lists all finalized and draft bills from all groups the caller belongs to.
  - Each item displays restaurant name, group context, payer name, status pill (`Đang quét OCR`, `Bản nháp`, `Đã chốt sổ`), and payment completion progress bar (e.g. `3/5 người đã trả`).
  - Tapping a draft bill navigates to the Bill Detail and OCR Item Assignment screen (`Màn hình 3`).

- **AC-8 (Tab 4: Settled History and Historic Proof Inspection)**:
  - Displays a chronological list of completed debt settlements.
  - Tapping any historic settlement row opens `sheet-proof-review` in read only settled mode.
  - The settled proof sheet displays the full electronic banking receipt (source account, destination bank, transaction code FT, amount, timestamp, note) and a green badge `Giao dịch đã được đối soát và ghi nhận số dư`.

---

## Options Considered

### Option 1: Unified Four Tab Settlement Hub with Single Creditor Batching (Recommended)

Combines payable debts, receivable proof review, multi group bill feeds, and historic settlements into a single top level destination with four segmented tabs. Single creditor batching ensures bank transfer constraints are respected while minimizing payment steps.

**Pros**:
- Single entry point eliminates confusion between viewing bills and paying debts.
- Single creditor batching guarantees that VietQR codes always map to exactly one destination account.
- Direct proof confirmation on cards allows fast review without opening deep subpages.

**Cons**:
- Requires managing state across four distinct list streams in one screen view model.

### Option 2: Separate Dedicated Screens for Debts and Proof Review

Splits debt payment into one screen and proof approval into another separate screen accessible only through notifications.

**Pros**:
- Slightly smaller individual view model files.

**Cons**:
- Poor navigation ergonomics: users must switch between multiple screens to check what they owe versus what they are owed.
- Breaks consistency with the standard bottom navigation dock structure.

---

## Decision

**Chosen option**: Option 1: Unified Four Tab Settlement Hub with Single Creditor Batching.

This structure provides a unified, transparent view of all financial obligations across groups, streamlines VietQR generation, and offers a robust review workflow for incoming bank proofs.

**Implementation skills**: `supabase-postgres-best-practices` (`supabase/agent-skills`, `.agents/skills/supabase-postgres-best-practices/`)

---

## Rationale

Peer to peer expense splitting relies on mutual trust and fast verification. When a user opens their expense app, they want immediate clarity on what needs payment and what requires approval. Consolidating all four views into a single hub with persistent bottom navigation ensures that no payment proof gets overlooked and no debt is forgotten.

---

## Feature Design

### Data Model Sketch

```text
Debts:
- id: UUID (Primary Key)
- group_id: UUID
- bill_id: UUID
- debtor_member_id: UUID
- creditor_member_id: UUID
- amount: BigInt (VND)
- status: Enum (awaiting, pending_confirmation, settled, voided)
- reminder_count: Integer (0 to 3)
- last_reminded_at: Timestamp (Nullable)
- payment_id: UUID (Nullable, foreign key to Payments)

Payments:
- id: UUID (Primary Key)
- group_id: UUID
- debtor_member_id: UUID
- creditor_member_id: UUID
- amount: BigInt (VND)
- reference_code: Text (Unique, format PAYXXXXXXXX)
- status: Enum (pending_proof, pending_confirmation, confirmed, rejected, superseded)
- recipient_bank_code: Text
- recipient_bank_name: Text
- recipient_account_number: Text
- recipient_account_holder: Text
- image_object_key: Text (Private Cloudinary key)
- note: Text (Nullable, max 500 chars)
- rejection_reason: Text (Nullable, max 500 chars)
- submitted_at: Timestamp (Nullable)
- confirmed_at: Timestamp (Nullable)
- rejected_at: Timestamp (Nullable)
```

### State Transitions

```text
Debt Lifecycle:
[ awaiting ] ──────────(Submit Proof)──────────> [ pending_confirmation ]
     │                                                   │
     │                                     ┌─────────────┴─────────────┐
     │                                     │                           │
(Void Bill)                           (Confirm)                    (Reject)
     │                                     │                           │
     ▼                                     ▼                           ▼
[ voided ]                            [ settled ]                 [ awaiting ]

Payment Lifecycle:
[ pending_proof ] ────(Upload Proof)────> [ pending_confirmation ]
     │                                           │
     │ (New QR generated                         ├──(Confirm)──> [ confirmed ]
     │  or bill voided)                          │
     ▼                                           └──(Reject)───> [ rejected ]
[ superseded ]
```

### API Surface

| Endpoint | Method | Key Inputs | Key Outputs | Auth | Key Errors |
|---|---|---|---|---|---|
| `/api/v1/groups/{groupId}/debts` | GET | `status`, `debtor_member_id`, `creditor_member_id`, `cursor`, `limit` | `debts[]`, `next_cursor`, `summary` | Bearer Token | 401 Unauthorized, 403 Forbidden |
| `/api/v1/groups/{groupId}/payments/qr` | POST | `debt_ids[]` (UUIDs, 1 to 100), `creditor_member_id` | `payment_id`, `reference_code`, `qr_payload`, `qr_image_url`, `amount`, `recipient` | Bearer Token | 400 Bad Request, 404 Creditor Not Found, 409 Debts Not Awaiting, 422 Bank Account Required |
| `/api/v1/groups/{groupId}/payments/{paymentId}/proof` | POST | `image` (Multipart file, max 10MB), `note` (string, max 500) | `payment_id`, `status: pending_confirmation`, `submitted_at` | Bearer Token | 400 Invalid Image, 409 Payment Already Submitted, 413 File Too Large, 422 Bank Account Invalid |
| `/api/v1/groups/{groupId}/payments/{paymentId}/confirm` | POST | None | `payment_id`, `status: confirmed`, `confirmed_at`, `settled_debt_ids[]` | Bearer Token | 403 Not Creditor, 409 Not Pending Confirmation |
| `/api/v1/groups/{groupId}/payments/{paymentId}/reject` | POST | `reason` (string, 1 to 500 chars) | `payment_id`, `status: rejected`, `rejected_at`, `reopened_debt_ids[]` | Bearer Token | 400 Missing Reason, 403 Not Creditor, 409 Not Pending Confirmation |
| `/api/v1/groups/{groupId}/debts/{debtId}/remind` | POST | None | `debt_id`, `reminder_count`, `last_reminded_at` | Bearer Token | 403 Forbidden, 409 Reminder Limit Reached, 409 Cooldown Active |

### Value Sourcing

| Action | Value Produced or Displayed | Source |
|---|---|---|
| Load Hub Header | Total Payable & Receivable | Sum of caller debts from `GET /api/v1/groups/{groupId}/debts` across active groups |
| Load Hub Header | Pending Proof Alert Count | Count of payments where caller is creditor and status is `pending_confirmation` |
| Render Debt Card | Debtor / Creditor display name | `group_members.nickname` or `users.display_name` |
| Render VietQR Sheet | Bank name, account number, account holder | Creditor profile bank snapshot from `GET /api/v1/groups/{groupId}/payments/qr` |
| Render VietQR Sheet | Reference transfer code | Unique unguessable string `PAYXXXXXXXX` generated by backend |
| Submit Proof | Private image URL preview | Temporary local file path, then 5 minute signed Cloudinary URL from backend |
| Proof Card Note | Message text from debtor | `payments.note` column returned from backend |
| Proof Card Slip | Transaction code FT | Parsed or entered reference code in `payments.reference_code` |

### Key Invariants

1. **Single Creditor Constraint**: Every payment record links to exactly one debtor and one creditor. Multiple debts can only be combined if they belong to the exact same debtor and creditor pair.
2. **All or Nothing Settlement**: Confirming a payment transitions 100% of linked debts to `settled` status simultaneously in a single transaction. Partial settlements are not supported in V1.
3. **Immutable Banking Snapshot**: Once a proof is submitted, the creditor bank account information is snapshotted into the payment record. Subsequent bank profile updates by the creditor do not alter historical proof details.
4. **Idempotency on Payment Operations**: QR creation, proof submission, confirmation, and rejection must pass an `Idempotency-Key` header to prevent double payments or duplicate confirmations on network retries.

### Security Model

- Only active group members can view debt lists, expenses, and payments in that group.
- Cloudinary proof images are stored in a private bucket and served strictly through short lived 5 minute signed URLs generated on demand.
- Sensitive information including full bank account numbers and transfer notes are redacted in application logs.
- Payment confirmation and rejection actions are strictly authorized: only the assigned creditor member can invoke these endpoints.

### Configuration Required

- `API_BASE_URL`: Base URL of the PaySplit Backend REST API.
- No client side secrets: VietQR generation uses server coordinated NAPAS strings and public QR rendering endpoints.

---

## Critical Test Scenarios

- **Happy path (Single Creditor Batch Settlement)**:
  - Debtor opens `sheet-select-debt`, selects two debts owed to Minh Tran (120.000 VND and 80.000 VND).
  - Taps `[ Trả nợ ]`, opens `sheet-vietqr` showing total 200.000 VND, transfers money on bank app, uploads proof with note.
  - Creditor opens `sheet-proof-review`, verifies the receipt, taps `[ Xác nhận đã nhận tiền ]`.
  - Both debts change to `settled`, and net balances update on both devices. Verifies **AC-3**, **AC-4**, **AC-5**.

- **Failure case (Creditor has no Bank Account)**:
  - Debtor attempts to generate QR for a creditor who has not configured their bank account.
  - System returns `422 BANK_ACCOUNT_REQUIRED`. UI displays a helpful prompt to notify the creditor to set up their VietQR account. Verifies **AC-4**.

- **Failure case (Payment Rejection Workflow)**:
  - Creditor inspects proof, notices wrong transfer amount, taps `[ ✕ Từ chối ]`, enters reason `"Chuyển thiếu 50k"`.
  - Payment transitions to `rejected`, debts return to `awaiting`, and debtor receives push notification with the reason. Verifies **AC-5**.

- **Anti Spam Protection**:
  - Creditor taps `[ 🔔 Nhắc nợ ]`. Button enters 60 second disabled cooldown. If tapped again after cooldown within 24 hours, backend returns `409 Cooldown Active`. Verifies **AC-6**.

---

## Build Plan

1. **Data Layer Models and Freezed DTOs**: Create `DebtModel`, `PaymentModel`, `VietQrPayloadModel`, `ProofSubmissionRequest`, and `PaymentConfirmationModel` with Freezed and JsonSerializable in `lib/features/bills/data/models/`, satisfies **AC-2**, **AC-3**, **AC-4**.
2. **Retrofit Data Source and Repository**: Define Retrofit endpoints for debts, payment QR, proof upload, confirm, reject, and remind in `lib/features/bills/data/datasources/` and implement `SettlementRepository`, satisfies **AC-3**, **AC-4**, **AC-5**, **AC-6**.
3. **Domain Use Cases**: Implement `GetGroupDebtsUseCase`, `GeneratePaymentQrUseCase`, `SubmitTransferProofUseCase`, `ConfirmPaymentUseCase`, `RejectPaymentUseCase`, and `RemindDebtUseCase`, satisfies **AC-3**, **AC-5**, **AC-6**.
4. **Riverpod Settlement State Notifiers**: Create `SettlementHubNotifier` managing multi tab filters, aggregate totals, single creditor grouping, and local reminder cooldown timers in `lib/features/bills/presentation/providers/`, satisfies **AC-1**, **AC-2**, **AC-6**.
5. **Presentation Widgets: Summary Card and Tab Panels**: Build `SettlementSummaryCard`, `PayableDebtsTab`, `ReceivableProofTab`, `AllBillsFeedTab`, and `SettledHistoryTab` with Material 3 styling, satisfies **AC-1**, **AC-2**, **AC-3**, **AC-7**, **AC-8**.
6. **Bottom Sheets: Dynamic VietQR and Batch Selector**: Implement `DynamicVietQrSheet` (`sheet-vietqr`) and `SelectDebtBatchSheet` (`sheet-select-debt`) with one touch clipboard copy and file upload triggers, satisfies **AC-3**, **AC-4**.
7. **Bottom Sheet: Proof Review and Full Screen Receipt**: Implement `ProofReviewSheet` (`sheet-proof-review`) supporting pending review mode and historic read only mode, satisfies **AC-5**, **AC-8**.
8. **Navigation Routing and Integration**: Register `/settlement` route in `go_router`, wire `[ Xem tất cả ]` on Home, and link bottom navigation bar `🧾 Hóa đơn` tab, satisfies **AC-1**.
9. **Unit and Widget Tests**: Write comprehensive Riverpod notifier tests and widget tests verifying tab switching, batch calculation, and proof approval feedback, satisfies **AC-1**, **AC-3**, **AC-5**.

---

## Consequences

**Positive**:
- Eliminates manual math and multiple individual QR scans when paying friends back.
- Clean separation between debts awaiting payment and proofs awaiting confirmation.
- Transparent audit trail for all settled peer to peer transactions.

**Negative / tradeoffs**:
- Creditors must manually confirm proofs; automatic banking webhook settlement is out of scope for V1.
- Combining debts from different creditors into one QR transfer is not possible due to banking network rules.

**Neutral**:
- Image storage consumes Cloudinary quota; signed URLs expire after 5 minutes to prevent unauthorized hotlinking.

---

## Follow-up

- [ ] Verify signed URL delivery and cache headers on Cloudinary private image uploads.
- [ ] Connect Firebase Cloud Messaging push handlers to auto navigate to `sheet-proof-review` when a payment proof is received.

---

## References

**Project sources**:
- [`PaySplit-FE/docs/specs/ui-context.md`](ui-context.md) (Màn hình 4 and Design Tokens)
- [`PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md`](../../../PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md) (Backend split and settlement contract)

**Practices & standards**:
- NAPAS 247 Dynamic VietQR Standard Specification
- Single Creditor Settlement Batching Pattern
- Idempotent Payment Mutation Handling
