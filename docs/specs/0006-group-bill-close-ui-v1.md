# 0006. Group Bill Close UI v1

**Date**: 2026-08-24
**Status**: In Progress
**Target release**: V1
**Platform**: Flutter 3.x, iOS và Android
**Feature areas**: `features/groups/`, `features/bills/`, `features/home/`
**Design source**: [`PaySplit-UI/ui-context.md`](../../../PaySplit-UI/ui-context.md)
**Current mock**: [`PaySplit-UI/index.html`](../../../PaySplit-UI/index.html)
**Backend contract**: [`PaySplit-BE/docs/specs/0008-group-bill-close-v1/index.md`](../../../PaySplit-BE/docs/specs/0008-group-bill-close-v1/index.md)
**Deferred V2**: [`0005-debtor-bill-consent-ui-v2.md`](0005-debtor-bill-consent-ui-v2.md)

## 1. Tóm tắt

V1 thêm hai quyền cho Captain tại Group Hub. Captain có thể khóa mọi thành viên khỏi việc tạo bill mới, hoặc bấm `Chốt toàn bộ` để khóa ngay và xử lý mọi bill `draft`. Draft đã review được finalize trực tiếp. Draft chưa review được backend kiểm tra, review và finalize nếu hợp lệ. Chỉ current Captain được finalize bill đơn hoặc chốt toàn bộ. Creditor có thể review bill của mình nhưng không được finalize nếu không đồng thời là current Captain. Bill chưa hợp lệ được giữ lại để sửa. Consent của debtor không có trong V1.

Bill đã `finalized` luôn ở chế độ chỉ đọc. Các draft tồn tại trước lúc khóa vẫn được sửa, review và finalize.

## 2. Mục tiêu trải nghiệm

1. Mọi thành viên nhìn thấy ngay nhóm đã ngừng nhận bill mới.
2. Captain hiểu `Chốt toàn bộ` sẽ khóa nhóm trước khi xử lý bill.
3. Một bill thất bại không che kết quả của bill khác.
4. Captain có đường dẫn rõ ràng để sửa bill chưa sẵn sàng rồi finalize lại.
5. UI không nhắc đến accept hoặc reject trong V1.

## 3. Ngoài phạm vi V1

1. Không có debtor consent.
2. UI không gọi review từng draft trước bulk. Backend tự review và finalize draft hợp lệ trong transaction của bill đó.
3. Không sửa thuật toán phân bổ hoặc settlement.
4. Không thay đổi quyền sửa draft hiện tại.
5. Không chỉnh lại visual language của app.

## 4. Kiểm kê mock hiện tại

| Surface | Mock đang có | Thay đổi V1 |
|---|---|---|
| Home header | `Quét bill` tại `index.html:531` | Mở group picker. Group bị khóa xuất hiện disabled với nhãn `Đã khóa nhận bill` |
| Home quick action | `Quét bill OCR` tại `index.html:573` | Áp dụng cùng group picker và không cho chọn group bị khóa |
| Group Hub settings | Nút settings tại `index.html:868` | Thêm Switch On/Off Captain only `Khóa nhận hóa đơn` (bật để khóa, gạt tắt để mở khóa lại) |
| Group Hub bill tab | Header và filter tại `index.html:885` | Thêm lock banner, trạng thái intake và nút Captain `Chốt toàn bộ` |
| Group bill cards | Draft OCR và finalized cards tại `index.html:894` | Giữ status hiện tại. Bill thất bại trong batch có error và CTA mở Bill Detail |
| Group create bill sheet | `Tạo hóa đơn mới` tại `index.html:1719` | Không mở khi locked. Hiển thị reason và không cho chọn nhập tay hoặc OCR |
| Bill Detail | Draft editor và sticky actions tại `index.html:974` và `index.html:1253` | Draft vẫn sửa được. Reviewed vẫn finalize được. Finalized chuyển hoàn toàn sang read only |
| Current finalize handler | `handleFinalizeBillPrompt()` tại `js/app.js:2128` | Giữ cho finalize một bill. Bulk finalize dùng API batch, không loop handler trên client |
| Group activity | Timeline tại `index.html:943` | Thêm event khóa/mở khóa, bắt đầu batch và hoàn tất batch |

Mock chưa có lock state, bulk progress, batch result hoặc disabled group picker. Đây là surface mới, không phải hành vi đã có sẵn.

## 5. Acceptance criteria

### AC UI 1. Hiển thị trạng thái khóa

Group Hub hiển thị banner ngay dưới header khi `bill_submission_locked` là true:

```text
Nhóm đã khóa nhận hóa đơn mới
Bạn vẫn có thể hoàn thiện các bản nháp đã tồn tại.
```

Banner hiển thị cho mọi active member. Captain thấy thêm thời gian khóa.

### AC UI 2. Khóa và mở khóa dạng Switch On/Off

Group Settings có Switch toggle Captain only `Khóa nhận hóa đơn`:

- **Gạt sang Bật (ON)**: Mở dialog xác nhận:
  1. Mọi thành viên, kể cả Captain, không thể tạo bill mới.
  2. Các hóa đơn hiện có vẫn được chỉnh sửa và chốt bình thường.
  3. Captain có thể mở khóa lại bất cứ lúc nào trong Cài đặt nhóm.
  Nhấn `Khóa nhận hóa đơn` để xác nhận. Sau khi thành công, Switch chuyển sang ON, UI cập nhật banner locked.

- **Gạt sang Tắt (OFF)**: Gọi API `POST /api/v1/groups/{groupId}/bills/unlock-submissions` để mở khóa ngay lập tức, tắt banner locked và hiển thị SnackBar thông báo thành công. Mọi thành viên có thể tiếp tục tạo/quét bill mới bình thường.

### AC UI 3. Create bill gate

Mọi entry tạo bill phải dùng cùng group policy từ domain state:

1. FAB hoặc CTA trong Group Hub.
2. Home `Quét bill`.
3. Home `Quét bill OCR`.
4. Group create bill sheet.
5. Deep link mở create bill nếu có.

Group locked bị disabled trong picker. Nếu API trả `BILL_SUBMISSION_LOCKED` sau khi UI đã mở camera hoặc file picker, app không tạo local draft thành công, đóng luồng upload và refresh group state. UI không suy đoán rằng server đã nhận bill.

### AC UI 4. Nút Chốt toàn bộ

Captain thấy `Chốt toàn bộ` trong header của tab Hóa đơn. Member thường không thấy action. Button enabled khi group active và không có batch `queued` hoặc `processing`. Nếu có active batch, vị trí này đổi thành `Xem tiến trình`. Group đã locked vẫn cho Captain chạy batch mới sau khi batch trước completed để xử lý các draft đã được sửa.

### AC UI 5. Confirmation trước bulk finalize

Tap `Chốt toàn bộ` mở bottom sheet. Sheet hiển thị số bill theo dữ liệu hiện có:

1. `Đã review`, bill có status `draft` và `reviewed_at` của version hiện tại, backend sẽ finalize trực tiếp.
2. `Sẽ kiểm tra`, bill có status `draft` và chưa có review hợp lệ, backend sẽ review và finalize nếu dữ liệu hợp lệ.
3. `Đã chốt hoặc đã hủy`, không phải target mới.

Copy bắt buộc:

> Nhóm sẽ khóa nhận bill mới ngay khi bạn xác nhận. Mỗi bill sẽ được kiểm tra và chốt độc lập. Bill chưa hợp lệ sẽ được giữ lại để bạn sửa.

Nút cuối là `Khóa nhóm và chốt toàn bộ`.

### AC UI 6. Progress và kết quả

API trả `202` thì app mở `BulkFinalizeProgressSheet` và poll batch detail khi app foreground. Sheet hiển thị:

1. Trạng thái `Đang chốt` hoặc `Đã hoàn tất`.
2. `finalized_count / target_count`.
3. Số bill thất bại.
4. Danh sách item cursor paginated.
5. Action `Đóng` và `Xem bill cần sửa` khi đã terminal.

Rời sheet không hủy batch. Khi quay lại hoặc khởi động lại Group Hub, app lấy `active_bill_finalize_batch_id` hoặc `latest_bill_finalize_batch_id` từ Group Detail rồi tải đúng batch. Push hoặc in app notification hoàn tất mở lại đúng sheet.

### AC UI 7. Partial failure

Mỗi bill có một kết quả riêng:

| Error | Copy | Action |
|---|---|---|
| `VERSION_CONFLICT` | `Bill đã thay đổi sau khi bắt đầu` | `Tải lại bill` |
| `BILL_NOT_READY` | `Bill còn dữ liệu chưa hợp lệ để review và chốt` | `Mở và sửa bill` |
| `BANK_ACCOUNT_REQUIRED` | `Chủ nợ chưa có tài khoản nhận tiền hợp lệ` | `Xem bill` |
| `BILL_DELETED` | `Hóa đơn đã được xóa trước khi chốt` | Không có action |
| `BILL_IMMUTABLE` | Refresh và coi là thành công nếu detail cho biết bill đã finalized đúng version | Không retry mù |
| Lỗi tạm thời | `Chưa thể xử lý bill này` | `Thử lại sau` |

Bill thành công đổi badge sang `Đã chốt`. Bill thất bại giữ trạng thái hiện tại. Nếu batch item không còn bill tương ứng, UI dùng nhãn `Hóa đơn đã xóa` và không giữ merchant name từ cache. Không rollback item thành công trên client.

### AC UI 8. Draft tồn tại sau khi khóa

Draft đã có vẫn mở Bill Detail và dùng các action hiện tại:

1. Sửa và lưu draft.
2. Apply hoặc retry OCR.
3. Review.
4. Xóa draft nếu hợp đồng hiện tại cho phép.
5. Finalize khi draft version hiện tại đã review và caller là current Captain.

Creditor không phải Captain không thấy action finalize trên bill của mình, kể cả sau khi review thành công. Khi role state cũ khiến client vẫn gọi finalize và backend trả `403 FORBIDDEN`, app refresh Bill Detail cùng group role rồi giữ bill ở trạng thái `draft`.

UI không hiển thị create bill CTA trong locked group, nhưng không biến draft editor thành read only.

### AC UI 9. Finalized bill read only

Khi `status` là `finalized`, Bill Detail:

1. Hiển thị immutable breakdown và settlement progress.
2. Ẩn edit item, assignment, adjustment, apply OCR, retry OCR, delete draft, save draft và review.
3. Không hiển thị finalize lần nữa.
4. Captain chỉ thấy void action khi hợp đồng hiện tại cho phép.
5. Một stale mutation trả `BILL_IMMUTABLE` làm app reload detail và chuyển sang read only.

### AC UI 10. Empty, loading, offline và authorization

1. Zero target vẫn khóa group và hiển thị `Không có bill cần chốt`.
2. Loading lock hoặc bulk start dùng button spinner và chống double tap.
3. Offline disable Captain mutation nhưng vẫn hiển thị cache kèm banner offline.
4. Ordinary member không thấy Captain action. Nếu gọi qua stale UI và nhận `CAPTAIN_REQUIRED`, app refresh role.
5. Archived group đóng page theo contract hiện tại và không giữ batch detail trên visible tree.
6. Batch polling dùng backoff khi lỗi mạng và dừng khi terminal hoặc app background.
7. `BULK_FINALIZE_IN_PROGRESS` mở batch ID do server trả về thay vì tạo retry với key mới.
8. Nếu Captain archive nhóm khi batch còn active, cùng error này giữ Group Settings mở và có CTA `Xem tiến trình`. Archive chỉ được thử lại sau khi batch completed.

### AC UI 11. Accessibility và responsive

Mọi action có touch target ít nhất 44 x 44 logical pixels. Lock banner có semantic label không phụ thuộc màu. Confirmation focus đi qua title, consequences, cancel và destructive confirm. Progress update được announce có giới hạn, không announce mỗi poll không đổi.

Kiểm tra ở 320, 375, 414 và 768 logical pixels. Button `Chốt toàn bộ` không wrap. Tablet giữ content max width theo Group Hub hiện tại.

## 6. Bố cục Group Hub V1

```text
┌──────────────────────────────────────────┐
│ ←  PD  Phòng Dev Cty              [⚙]   │
├──────────────────────────────────────────┤
│ NHÓM ĐÃ KHÓA NHẬN HÓA ĐƠN MỚI           │
│ Draft hiện có vẫn có thể hoàn thiện.     │
├──────────────────────────────────────────┤
│ Hóa đơn  Công nợ  Thành viên  Hoạt động │
├──────────────────────────────────────────┤
│ Hóa đơn trong nhóm     [Chốt toàn bộ]    │
│ Tất cả  Đang xử lý  Đã chốt  Đã hủy     │
│                                          │
│ Cafe planning              Cần sửa       │
│ Lẩu gà lá é                Đã chốt       │
└──────────────────────────────────────────┘
```

Khi group còn open, banner đổi thành status gọn `Đang nhận hóa đơn mới`. Chỉ Captain thấy action khóa trong Group Settings.

## 7. Visual design

1. Dùng Newsreader cho title, Roboto Slab cho body và control, JetBrains Mono cho count và money.
2. Nền `#F5F6F1`, card trắng, hairline `#DBE0CE`, primary `#0F766E`.
3. Lock banner dùng amber nhạt và icon khóa Hugeicons. Không dùng màu đỏ vì locked là policy, không phải lỗi.
4. `Khóa gửi hóa đơn mới` và confirm bulk là destructive governance action, dùng warning treatment và copy cụ thể.
5. Progress dùng text và count. Không thêm biểu đồ tròn hoặc animation trang trí.
6. Result row có icon, bill name, captured version, status và CTA. Error không chỉ biểu đạt bằng màu.

## 8. API mapping

| UI action | Endpoint | Client behavior |
|---|---|---|
| Load Group Hub | `GET /api/v1/groups/{groupId}` | Cache lock state, active batch ID và latest batch ID cùng group detail |
| Lock submissions | `POST /api/v1/groups/{groupId}/bills/lock-submissions` | Gửi `Idempotency-Key`, cập nhật mọi group cache khi success |
| Start bulk | `POST /api/v1/groups/{groupId}/bills/finalize-all` | Gửi key mới, giữ cùng key khi outcome chưa biết |
| Poll result | `GET /api/v1/groups/{groupId}/bill-finalize-batches/{batchId}` | Cursor riêng cho item list, dừng khi completed |
| Create bill | Existing `POST /api/v1/bills` với `group_id` | Map `BILL_SUBMISSION_LOCKED` sang locked state |
| Fix draft | Existing edit, OCR và review APIs | Không bị chặn bởi submission lock |
| Finalize one | Existing finalize API | Chỉ hiển thị và gọi khi caller là current Captain. Non Captain `403 FORBIDDEN` thì refresh role và Bill Detail |

## 9. Domain và state architecture

```text
lib/features/groups/
├── domain/entities/group_bill_policy_entity.dart
├── domain/entities/bulk_finalize_batch_entity.dart
├── domain/entities/bulk_finalize_item_entity.dart
├── domain/repositories/group_bill_close_repository.dart
├── domain/usecases/lock_bill_submissions_usecase.dart
├── domain/usecases/start_bulk_finalize_usecase.dart
├── domain/usecases/get_bulk_finalize_batch_usecase.dart
├── data/models/
├── data/datasources/group_bill_close_remote_data_source.dart
├── data/repositories/group_bill_close_repository_impl.dart
└── presentation/
    ├── notifiers/group_bill_close_notifier.dart
    └── widgets/
        ├── group_bill_lock_banner.dart
        ├── lock_bill_submissions_sheet.dart
        ├── bulk_finalize_confirm_sheet.dart
        ├── bulk_finalize_progress_sheet.dart
        └── bulk_finalize_result_row.dart
```

Group policy là một phần của Group Detail entity, không phải cờ riêng trong widget. Presentation chỉ dùng entity và use case. Dio model ở data layer. Batch notifier giữ `batch_id`, summary, item cursor, polling state và lần refresh cuối.

## 10. State reconciliation

1. Lock success cập nhật Group Detail, Home group picker và create bill controls trong cùng cache invalidation.
2. `BILL_SUBMISSION_LOCKED` luôn thắng local open state và kích hoạt refresh.
3. Poll response là nguồn đúng cho batch counts. Client không tự tăng count từ animation.
4. Per bill finalize notification hoặc refreshed bill list có thể đến trước batch poll. UI merge theo bill status nhưng vẫn giữ server batch outcome.
5. App restart lấy active hoặc latest batch ID từ Group Detail. Notification deep link chỉ là đường tắt. Không cần lưu toàn bộ item list vào secure storage.
6. `BULK_FINALIZE_IN_PROGRESS` và active batch ID từ Group Detail cùng hội tụ về một progress state.

## 11. Test plan

### Unit

1. Group lock state mapping từ nullable time.
2. Batch count và terminal state mapping.
3. Stable error copy và CTA mapping.
4. Poll backoff, background pause và terminal stop.
5. Unknown outcome retry giữ cùng idempotency key.
6. Active batch conflict mở lại batch hiện có.

### Widget

1. Captain thấy finalize đơn, lock và bulk action. Creditor không phải Captain vẫn thấy draft edit và review nhưng không thấy finalize.
2. One way lock confirmation hiển thị đủ ba consequence.
3. Locked banner và disabled create controls.
4. Bulk confirmation counts và copy.
5. Progress, completed, partial failure và zero target.
6. Draft locked group vẫn editable.
7. Finalized detail không còn mutation control.
8. Accessibility và target size.

### Integration

1. Home scan không cho chọn locked group.
2. Race UI open state với server lock maps sang banner mà không tạo duplicate local bill.
3. Start bulk, đóng sheet, quay lại và resume progress.
4. Sửa một bill thất bại vì `BILL_NOT_READY` rồi bulk lại khi group vẫn locked.
5. Deep link batch completion mở đúng Group Hub.

## 12. Build plan

1. Mở rộng Group Detail entity và mọi create bill entry với locked state, sau đó làm lock confirmation và API mapping, satisfies **AC UI 1** through **AC UI 3**, **AC UI 10**, and **AC UI 11**.
2. Thêm batch entities, repository, use cases, notifier, confirm sheet và progress sheet cho một draft bill hợp lệ, satisfies **AC UI 4** through **AC UI 6**.
3. Thêm cursor results, partial failure mapping, recovery CTA và resume polling, satisfies **AC UI 6**, **AC UI 7**, and **AC UI 10**.
4. Hoàn thiện draft versus finalized Bill Detail gates, Home picker, notification deep link, responsive và accessibility tests, satisfies **AC UI 3**, **AC UI 8** through **AC UI 11**.
5. Chạy code generation, `flutter analyze`, unit, widget và integration tests.

## 13. Quan hệ với các spec khác

1. Spec này bổ sung Group Hub spec 0003 cho V1.
2. Spec này làm rõ trạng thái read only của Bill Detail spec 0004.
3. Debtor consent spec 0005 là V2 và không được dùng để gate V1.
4. Settlement sau finalize vẫn theo Home spec 0002 và backend settlement spec 0004.
