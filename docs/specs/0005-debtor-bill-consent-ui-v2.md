<!-- Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 -->
# 0005. Debtor Bill Consent UI v2

**Date**: 2026-08-24
**Status**: Proposed
**Target release**: V2
**V1 contract**: [`0006-group-bill-close-ui-v1.md`](0006-group-bill-close-ui-v1.md)
**Platform**: Flutter 3.x, iOS và Android
**Feature Area**: `PaySplit-FE/lib/features/bills/`
**Style System**: Tally x Hallmark, utilitarian warm editorial
**Design Tokens**: [`PaySplit-UI/ui-context.md`](../../../PaySplit-UI/ui-context.md)
**Current Mock**: [`PaySplit-UI/index.html`](../../../PaySplit-UI/index.html)
**Backend Contract**: [`PaySplit-BE/docs/specs/0007-debtor-bill-consent/index.md`](../../../PaySplit-BE/docs/specs/0007-debtor-bill-consent/index.md)
**End to End Flow**: [`PaySplit-BE/docs/specs/0007-debtor-bill-consent/end-to-end-flow.md`](../../../PaySplit-BE/docs/specs/0007-debtor-bill-consent/end-to-end-flow.md)

## 1. Tóm tắt

V2 sẽ thêm màn hình `Yêu cầu xác nhận chia tiền` để một debtor xem chính xác phần tiền của mình trước khi debt được tạo. Người dùng sẽ có thể accept hoặc reject từng bill hay nhiều bill cùng lúc. V1 không có consent và không dùng spec này để gate finalize.

Khi V2 được triển khai, spec này sẽ sửa luồng trên ba màn hiện có:

1. Home có điểm vào `Chờ bạn xử lý` và pending badge.
2. Group Hub hiển thị trạng thái consent của bill.
3. Bill Detail không còn finalize trực tiếp từ draft. Creditor hoặc Captain phải review, chờ đủ consent, sau đó Captain mới finalize.

Luồng VietQR, nộp proof và Creditor duyệt proof sau finalize được giữ nguyên.

## 2. Mục tiêu trải nghiệm

1. Debtor hiểu bill nào đang yêu cầu mình đồng ý và tổng tiền phải chịu trước khi thao tác.
2. Debtor xem được từng item, giá ban đầu, giá sau giảm, VAT, phí dịch vụ, voucher và rounding.
3. Batch action tiết kiệm thao tác nhưng không che giấu lỗi của từng bill.
4. Creditor và Captain thấy ai đang pending mà không được quyền accept thay.
5. Consent và settlement được trình bày thành hai giai đoạn khác nhau, tránh hiểu accept là đã trả tiền.

## 3. Ngoài phạm vi

1. Không thiết kế lại toàn bộ Home, Group Hub hoặc Bill Detail.
2. Không thay đổi thuật toán phân bổ tiền trên client.
3. Không tự động accept, không cho rút accept và không thêm timeout.
4. Không cho Captain override request pending.
5. Không thay đổi UI VietQR, proof upload hoặc proof review ngoài việc nối đúng từ debt đã finalize.

## 4. Kiểm kê mock hiện tại và điểm tích hợp

Mock đã được kiểm tra trực tiếp ở kích thước mobile. Bảng sau là nguồn đối chiếu khi triển khai.

| Surface hiện tại | Mock đang có | Quan hệ với luồng mới | Thay đổi bắt buộc |
|---|---|---|---|
| Prototype navigation | Chỉ có Home, Group Hub và Bill Detail cho phần bill | Chưa có trang consent | Thêm route và screen `bill-acceptance-requests`; không đưa control demo vào production |
| Home header | Chuông notification có unread badge tại `index.html:525` | Có thể deep link đến request cụ thể | Notification consent mở đúng route và tự expand accordion theo `request_id` |
| Notification sheet | Danh sách notification hiện tại tại `index.html:1519` có proof, finalized bill và member join | Có sẵn surface để nhận consent event | Thêm request, reminder, rejected, invalidated và approved rows với deep link; không đưa rejection reason vào preview |
| Home actionable debts | `Khoản nợ cần xử lý`, tab `Cần trả` và `Cần thu` tại `index.html:585` | Đây là debt sau finalize, không phải consent | Giữ nguyên widget settlement. Thêm card riêng `Chờ bạn xử lý` phía trên nó, không trộn consent vào tab debt |
| Home VietQR và proof actions | `Trả QR`, `Duyệt proof`, `Nhắc nợ` tại `index.html:612`, `647`, `663` | Là giai đoạn sau finalize | Giữ nguyên hành vi và copy hiện tại |
| Group Hub bill tab | Bill card, filter `Đang xử lý`, `Đã chốt`, `Đã hủy` tại `index.html:885` | Có vị trí tự nhiên để hiện bill lifecycle | Thêm badge `Chờ xác nhận`, `Sẵn sàng chốt`, tiến độ `x/y đã đồng ý` và action `Nhắc tất cả` cho Creditor hoặc Captain |
| Group Hub activity tab | Timeline OCR, finalized và proof tại `index.html:943` | Có sẵn audit feed theo nhóm | Render các event consent requested, accepted, rejected, approved và invalidated với quyền xem reason đúng role |
| Group Hub debt tab | `Trả QR` và `Duyệt proof` | Settlement sau finalize | Giữ nguyên |
| Bill Detail receipt và OCR | Header bill, ảnh, OCR candidate, item editor | Tái sử dụng cho Creditor và Captain trước review | Giữ cấu trúc, thêm UI trạng thái theo lifecycle |
| Bill Detail item assignment | Item card, giá gốc, giá sau giảm, assignee, VAT, phí, voucher và đối soát | Là nguồn nội dung của snapshot consent | Debtor không đọc live draft tại trang consent. Trang consent chỉ đọc snapshot bất biến do backend trả |
| Bill Detail sticky actions | `Lưu nháp` và `Chốt sổ` tại `index.html:1254` | Xung đột trực tiếp với consent | Draft hiển thị `Lưu nháp` và `Gửi yêu cầu xác nhận`. Awaiting hiển thị tiến độ và `Nhắc tất cả`. Reviewed chỉ Captain thấy `Chốt sổ` |
| Mock finalize handler | `handleFinalizeBillPrompt()` tại `js/app.js:2128` kiểm tra draft rồi tạo debt ngay | Bỏ qua consent round | Không dùng hành vi này cho production. Luồng mới gọi review trước, finalize chỉ sau approved round |
| VietQR sheet | Có QR, thông tin nhận và proof submission từ `index.html:1272` | Bắt đầu sau finalize | Giữ nguyên |
| Proof review sheet | Creditor xác nhận hoặc reject proof | Hoàn tất settlement | Giữ nguyên |
| Select debt sheet | Chọn nhiều debt để tạo QR tại `index.html:1581` | Batch settlement cùng Creditor | Giữ nguyên, không dùng lại cho batch consent vì ngữ nghĩa khác |
| `ui-context.md` | V1 mô tả draft review, Captain finalize và finalized read only | Đây là contract đúng cho V1 | Khi V2 bật consent, spec 0005 mới thay thế phần review và finalize gate |

## 5. Điều hướng

### 5.1. Route

```text
/bill-acceptance-requests
/bill-acceptance-requests?tab=pending&request_id={requestId}
/bill-acceptance-requests?tab=responded&request_id={requestId}
```

`request_id` là tùy chọn. Khi có giá trị, app mở đúng tab, tải cho đến khi tìm thấy request theo API detail, cuộn đến card và expand card đó. Nếu request đã đổi trạng thái từ lúc notification được gửi, app chuyển sang tab phù hợp và hiển thị toast ngắn.

### 5.2. Điểm vào

1. Home card `Chờ bạn xử lý` với số pending.
2. Notification in app và push notification.
3. Bill card trong Group Hub khi caller có request của bill đó.
4. Bill Detail với debtor đang xem bill `awaiting_acceptance` có action `Xem yêu cầu của bạn`.

### 5.3. Back và lưu trạng thái

Back quay về surface đã mở trang. Hai tab giữ scroll position, cursor, item đã tải và accordion đang mở trong cùng page session. Rời hẳn route sẽ xóa selection và cache detail phiên đó.

## 6. Bố cục trang chính

```text
┌──────────────────────────────────────────┐
│ ←  Yêu cầu xác nhận             [ 3 ]   │
│ Bạn chỉ đồng ý với đúng số tiền hiển thị │
├──────────────────────────────────────────┤
│ [ Chờ xác nhận 3 ] [ Đã phản hồi ]       │
│ [ Tất cả nhóm ▾ ]                        │
├──────────────────────────────────────────┤
│ [✓] Lẩu gà lá é                    v4    │
│     Nam đề nghị · Phòng Dev              │
│     20 phút trước          212.500 đ  [⌄]│
│ ┌──────────────────────────────────────┐ │
│ │ Lẩu gà · Gốc 350.000 đ              │ │
│ │ Sau KM 320.000 đ · Bạn trả 80.000 đ │ │
│ │ ...                                  │ │
│ │ Tiền món                    180.000 đ│ │
│ │ Phí dịch vụ                  12.500 đ│ │
│ │ VAT                          20.000 đ│ │
│ │ Voucher                     -10.000 đ│ │
│ │ Làm tròn                     10.000 đ│ │
│ │ Bạn đồng ý trả              212.500 đ│ │
│ └──────────────────────────────────────┘ │
│                                          │
│ [ ] Cafe Túi Mơ To                95.000 đ│
├──────────────────────────────────────────┤
│ 1 bill · 212.500 đ  [Từ chối] [Chấp nhận]│
└──────────────────────────────────────────┘
```

## 7. Acceptance criteria

### AC UI 1. Home pending entry

Home gọi pending count độc lập với debt summary. Khi count lớn hơn 0, hiển thị card `Chờ bạn xử lý`, số request và CTA `Xem yêu cầu`. Khi count bằng 0, ẩn card để Home không tăng chiều dài không cần thiết. Count không cộng vào `Cần trả` vì debt chưa tồn tại.

### AC UI 2. Hai tab và phân trang

Trang có `Chờ xác nhận` và `Đã phản hồi`. Mỗi tab dùng cursor riêng, sắp xếp mới nhất trước theo server, tự tải thêm khi còn cách đáy 300 logical pixels và không chạy hai request load more đồng thời. Pull to refresh chỉ refresh tab hiện tại.

### AC UI 3. Bộ lọc nhóm

Mặc định hiển thị request từ mọi nhóm active. Dropdown nhóm là tùy chọn client gửi `group_id`. Group archived hoặc caller inactive không xuất hiện trong filter và request liên quan bị loại khỏi cache sau refresh hoặc lỗi not found.

### AC UI 4. Accordion summary

Mỗi bill là một accordion. Header luôn hiển thị selection control, merchant hoặc fallback `Hóa đơn chưa đặt tên`, group, Creditor, thời gian yêu cầu, bill version và `proposed_amount`. Tiền dùng JetBrains Mono với tabular figures. Chỉ request pending còn hiệu lực mới selectable.

### AC UI 5. Lazy immutable detail

Mở accordion lần đầu gọi detail API theo `request_id`. Detail được cache đến khi rời page session. Mỗi item hiển thị tên, quantity, unit price, line total ban đầu, item discount, final price, assignment ratio và phần item caller phải trả. Cuối danh sách có allocation summary gồm item subtotal, service charge share, VAT share, general discount share, rounding adjustment và final amount.

Client không tính lại proposed amount từ các item và không trộn dữ liệu live từ Bill Detail. Nếu tổng dòng hiển thị không khớp `proposed_amount`, vẫn hiển thị số server trả và gửi metric contract mismatch.

### AC UI 6. Selection

Tap vùng checkbox chọn hoặc bỏ chọn mà không mở accordion. Tap phần còn lại của header mở accordion. Có `Chọn tất cả đã tải` cho tab pending, tối đa 50 request. Khi đã đủ 50, các request chưa chọn bị disabled kèm copy `Tối đa 50 bill mỗi lần`.

Selection giữ nguyên qua load more và qua mở đóng accordion. Đổi group filter hoặc pull to refresh xóa selection sau một thông báo ngắn.

### AC UI 7. Sticky batch actions

Khi có selection, sticky action bar nằm trên safe area và hiển thị số bill, tổng proposed amount, `Từ chối` và `Chấp nhận`. Khi không chọn gì, bar ẩn. Nhãn không wrap ở 320 logical pixels.

### AC UI 8. Accept confirmation

Tap `Chấp nhận` mở bottom sheet cuối cùng với danh sách bill đã chọn, số lượng, tổng tiền và copy:

> Bạn đồng ý với cách chia và số tiền của các bill trên. Sau khi mọi người đồng ý, Captain có thể chốt để tạo công nợ. Đây chưa phải xác nhận đã thanh toán.

Nút cuối `Xác nhận chấp nhận` tạo một idempotency key mới và gửi batch. Sheet không đóng bằng tap nền trong lúc request đang chạy.

### AC UI 9. Reject reasons

Tap `Từ chối` mở bottom sheet có một textarea cho mỗi bill được chọn. Mỗi lý do là bắt buộc sau trim, dài từ 1 đến 500 ký tự, có counter và error inline riêng. Không có một lý do dùng chung ngầm cho nhiều bill.

Nút cuối chỉ enabled khi mọi field hợp lệ. Copy cảnh báo rằng reject một bill sẽ đưa bill đó về draft và mọi accept cũ của version trở thành không hiệu lực.

### AC UI 10. Batch partial response

Khi API trả `200`, mọi success chuyển sang tab history và selection được xóa. Khi trả `207`, app áp kết quả theo từng `request_id`:

1. Item success rời tab pending và xuất hiện trong history cache.
2. Item failure ở lại pending, tiếp tục được chọn và có error inline.
3. Sticky bar tính lại count và total chỉ từ item thất bại.
4. Banner tóm tắt số thành công và thất bại.
5. Retry tạo idempotency key mới và chỉ gửi item thất bại.

Không rollback local item thành công vì một item khác lỗi.

### AC UI 11. Responded history

Tab history là read only. Card có badge `Đã chấp nhận`, `Đã từ chối` hoặc `Không còn hiệu lực`. Card vẫn đọc snapshot version cũ khi group active. Rejector thấy lý do mình đã gửi. Hiệu lực round và lý do invalidation được hiển thị bằng copy rõ ràng, không dùng chỉ màu sắc.

### AC UI 12. Deep link

Notification consent request, reminder, rejected round và invalidated round đều deep link đúng request hoặc bill. Nếu request không còn được phép đọc do group archived, route đóng detail và hiển thị thông báo `Bạn không còn quyền truy cập nhóm này`, không giữ nội dung snapshot cũ trên màn hình.

### AC UI 13. Bill Detail lifecycle

Bill Detail đổi sticky actions theo role và trạng thái:

| Trạng thái | Creditor hoặc Captain | Debtor thường |
|---|---|---|
| `draft` | Sửa, lưu draft, `Gửi yêu cầu xác nhận` | Xem bill theo quyền hiện tại, không có consent action |
| `awaiting_acceptance` | Xem `x/y đã đồng ý`, pending members và `Nhắc tất cả`; action sửa phải cảnh báo vô hiệu consent cũ | Nếu có request, `Xem yêu cầu của bạn` |
| `reviewed` | Creditor thấy sẵn sàng; Captain thấy `Chốt sổ`; sửa phải cảnh báo tạo version mới | Xem trạng thái mọi người đã đồng ý, không có debt cho đến finalize |
| `finalized` | Dùng read only breakdown và settlement hiện tại | Dùng debt, VietQR và proof hiện tại |

Dialog trước edit ở `awaiting_acceptance` hoặc `reviewed` phải nói rõ mọi accept và reject cũ sẽ thành lịch sử, bill về draft và tất cả debtor của version mới phải xác nhận lại.

Ở hai trạng thái này, form bắt đầu ở read only. Creditor hoặc Captain phải bấm `Chỉnh sửa và tạo version mới`, xác nhận dialog rồi mới vào edit mode. Nếu bill vừa quay về draft do reject, Creditor và Captain thấy reason cùng actor và thời gian; member khác chỉ thấy thông báo chung rằng version cần chỉnh sửa.

### AC UI 14. Group Hub lifecycle

Bill card thêm status:

1. `Chờ phân bổ` cho `draft`.
2. `Chờ xác nhận` cho `awaiting_acceptance`, kèm `accepted_count/required_count`.
3. `Sẵn sàng chốt` cho `reviewed`.
4. `Đã chốt` cho `finalized`.
5. `Đã hủy` cho `voided`.

Filter `Đang xử lý` bao gồm draft, OCR processing, awaiting acceptance và reviewed. Nếu caller là Creditor hoặc Captain và bill awaiting, card cho `Nhắc tất cả`; API tự bỏ qua người đã accept.

Tab Hoạt động render các event `bill_consent_requested`, `bill_consent_accepted`, `bill_consent_rejected`, `bill_consent_approved` và `bill_consent_invalidated`. Lý do reject chỉ xuất hiện khi caller là rejector, Creditor hoặc Captain. Event của member khác dùng copy chung và không suy ra nội dung reason.

### AC UI 15. Không nhầm consent với settlement

Không dùng từ `đã trả`, `thanh toán` hoặc `đã nhận tiền` cho consent. Home balance và debt list chỉ thay đổi sau finalize. Accept thành công dùng copy `Đã đồng ý phần chia`, không dùng `Đã thanh toán`.

### AC UI 16. Loading, error và empty states

Trang hỗ trợ:

1. Skeleton cho app bar, tab và accordion header.
2. Spinner riêng trong accordion khi lazy load.
3. Error toàn trang khi list đầu thất bại với `Thử lại`.
4. Error inline khi detail thất bại với retry cho đúng card.
5. Offline banner giữ dữ liệu cache nhưng disable mutation.
6. Empty pending với copy `Bạn không có yêu cầu nào cần xác nhận`.
7. Empty history với copy `Bạn chưa phản hồi yêu cầu nào`.
8. Request stale hoặc already responded được refresh sang trạng thái server thay vì giữ lỗi vĩnh viễn.

### AC UI 17. Accessibility và responsive

Mọi touch target tối thiểu 44 x 44 logical pixels. Checkbox có semantic label gồm bill và amount. Accordion công bố expanded state. Error được announce qua live region. Focus order đi từ app bar, tab, filter, card header, detail đến sticky actions.

Kiểm tra ở 320, 375, 414 và 768 logical pixels. Ở tablet, content có max width 680 và sticky bar cùng trục với content. Không tạo desktop sidebar cho feature này.

## 8. Visual design

### 8.1. Token bắt buộc

1. Nền page `#F5F6F1`.
2. Surface card `#FFFFFF`.
3. Hairline border `#DBE0CE`.
4. Primary Deep Teal `#0F766E`.
5. Title dùng Newsreader.
6. Body, label và button dùng Roboto Slab.
7. Mọi số tiền, version và counter dùng JetBrains Mono.
8. Icon dùng Hugeicons stroke rounded.
9. Radius card từ 8 đến 12 logical pixels.
10. Spacing theo hệ 4 và 8.

Không thêm gradient, glassmorphism, emoji trang trí trong card tài chính hoặc một bảng màu mới. Trạng thái dùng badge, icon và text kết hợp, không dựa riêng vào màu.

### 8.2. Hierarchy

Amount là điểm nhìn mạnh nhất trong accordion header. Bill name đứng thứ hai. Creditor, group và thời gian là metadata. Detail dùng hàng tài chính gọn, đường kẻ hairline và khoảng trắng, không bọc từng dòng trong card lồng nhau.

## 9. API mapping

| UI action | Endpoint | Ghi chú client |
|---|---|---|
| Home pending badge | `GET /api/v1/bill-acceptance-requests/pending-count` | Refresh khi app resume, notification received hoặc batch hoàn tất |
| Load tab | `GET /api/v1/bill-acceptance-requests` | `state`, optional `group_id`, cursor và limit |
| Expand accordion | `GET /api/v1/bill-acceptance-requests/{requestId}` | Cache immutable detail trong page session |
| Accept hoặc reject | `POST /api/v1/bill-acceptance-requests/responses:batch` | Tối đa 50, header `Idempotency-Key` |
| Creditor hoặc Captain xem round | `GET /api/v1/bills/{billId}/acceptance-round?group_id={groupId}` | Không gọi cho member thường |
| Nhắc pending | `POST /api/v1/bills/{billId}/acceptance-reminders?group_id={groupId}` | Hiển thị sent và skipped summary |
| Review draft | `POST /api/v1/bills/{billId}/review?group_id={groupId}` | Gửi version và idempotency key |
| Sửa draft | `PUT /api/v1/bills/{billId}` | Version conflict reload bill |
| Finalize | `POST /api/v1/bills/{billId}/finalize?group_id={groupId}` | Captain only, xử lý `CONSENT_REQUIRED` |

Mọi tiền từ API là chuỗi base 10 VND. Model parse sang integer an toàn hoặc money value object, không qua `double`.

## 10. Domain và state architecture

```text
lib/features/bills/
├── domain/
│   ├── entities/
│   │   ├── bill_acceptance_request_summary_entity.dart
│   │   ├── bill_acceptance_request_detail_entity.dart
│   │   ├── bill_acceptance_item_entity.dart
│   │   ├── bill_acceptance_allocation_entity.dart
│   │   ├── bill_acceptance_batch_result_entity.dart
│   │   └── bill_acceptance_round_entity.dart
│   ├── repositories/
│   │   └── bill_acceptance_repository.dart
│   └── usecases/
│       ├── get_acceptance_requests_usecase.dart
│       ├── get_acceptance_request_detail_usecase.dart
│       ├── get_pending_acceptance_count_usecase.dart
│       ├── respond_to_acceptance_requests_usecase.dart
│       ├── get_bill_acceptance_round_usecase.dart
│       └── remind_pending_acceptances_usecase.dart
├── data/
│   ├── datasources/bill_acceptance_remote_data_source.dart
│   ├── models/
│   └── repositories/bill_acceptance_repository_impl.dart
└── presentation/
    ├── pages/bill_acceptance_requests_page.dart
    ├── notifiers/
    │   ├── bill_acceptance_tab_notifier.dart
    │   ├── bill_acceptance_selection_notifier.dart
    │   └── pending_acceptance_count_notifier.dart
    └── widgets/
        ├── acceptance_request_accordion.dart
        ├── acceptance_breakdown.dart
        ├── acceptance_batch_action_bar.dart
        ├── acceptance_confirm_sheet.dart
        ├── acceptance_reject_sheet.dart
        └── acceptance_inline_error.dart
```

Presentation chỉ phụ thuộc entity và use case. Dio model không đi vào notifier hoặc widget. Mỗi tab có state riêng gồm items, cursor, `hasMore`, loading state, scroll restoration key và detail cache. Selection state dùng `request_id` làm key và lấy amount từ summary server.

## 11. Error mapping

| Backend code | UI behavior |
|---|---|
| `ACCEPTANCE_VERSION_STALE` | Giữ row, bỏ selection sau refresh, hiển thị `Bill đã có phiên bản mới` |
| `ALREADY_RESPONDED` | Refresh request và chuyển sang history nếu owner đã phản hồi |
| `BILL_NOT_AWAITING_ACCEPTANCE` | Refresh row, không cho retry mutation cũ |
| `REJECTION_REASON_REQUIRED` | Focus field tương ứng và hiện error inline |
| `ACCEPTANCE_REQUEST_NOT_FOUND` | Xóa dữ liệu cache của request, dùng copy không tiết lộ quyền |
| `VERSION_CONFLICT` | Reload Bill Detail và yêu cầu người sửa kiểm tra version mới |
| `CONSENT_REQUIRED` | Captain thấy progress mới nhất và CTA quay về status round |
| `REMINDER_COOLDOWN` | Hiển thị thời điểm có thể nhắc lại nếu response cung cấp |
| `REMINDER_LIMIT_REACHED` | Disable nhắc cho member đó trong round |
| Network hoặc timeout | Không suy đoán thành công. Cho retry với cùng idempotency key khi outcome chưa biết |

## 12. Analytics và privacy

Ghi metric hoặc analytics với event name ổn định và label giới hạn:

1. `acceptance_page_opened`
2. `acceptance_detail_opened`
3. `acceptance_batch_submitted`
4. `acceptance_batch_completed`
5. `acceptance_deep_link_opened`
6. `acceptance_reminder_triggered`

Không gửi merchant, item name, rejection reason, proposed amount, bank data hoặc snapshot trong analytics, crash logs hay push payload.

## 13. Test plan

### 13.1. Unit

1. Parse money string chính xác và không dùng double.
2. Cursor state độc lập giữa hai tab.
3. Selection tối đa 50 và total chính xác.
4. Reject validation trim từ 1 đến 500 ký tự cho từng bill.
5. Map `207` thành success và failure riêng.
6. Stable error mapping và retry idempotency behavior.

### 13.2. Widget

1. Accordion lazy load đúng một lần trong page session.
2. Tap checkbox không toggle accordion.
3. Accept sheet hiển thị bill count, total và consent copy.
4. Reject sheet giữ lý do riêng khi scroll.
5. Partial result chuyển success sang history và giữ failure selected.
6. Archived group error xóa snapshot khỏi visible tree.
7. Semantics, focus order và 44 pixel targets.

### 13.3. Navigation và integration

1. Home badge mở pending tab.
2. Notification mở và expand đúng request.
3. Notification cũ chuyển đúng sang history.
4. Bill Detail draft gọi review thay vì finalize.
5. Awaiting Bill Detail hiển thị progress và reminder cho đúng role.
6. Captain chỉ thấy finalize khi bill reviewed.
7. Sau finalize, Home debt và VietQR tiếp tục hoạt động như spec 0002 và settlement spec.

### 13.4. Visual verification

Chụp và so sánh Pending loading, Pending populated, accordion expanded, selection bar, accept sheet, reject sheet validation, `207` partial result, Responded history và empty state ở 320, 375, 414 và 768 logical pixels.

## 14. Build plan

1. Bổ sung domain entity, repository contract, API model và tests cho list, detail, count và batch result.
2. Làm route, hai tab, cursor state và accordion lazy detail bằng dữ liệu fixture.
3. Nối Home pending count và notification deep link.
4. Làm selection, accept sheet, reject sheet và `207` reconciliation.
5. Nối Bill Detail review, awaiting progress, edit invalidation warning và Captain finalize gate.
6. Nối Group Hub status, progress và reminder action.
7. Hoàn thiện offline, empty, error, accessibility, analytics redaction và responsive verification.
8. Chạy code generation cho Freezed, Retrofit, Injectable và Riverpod, sau đó chạy analyze, unit, widget và integration tests.

## 15. Quan hệ với các FE spec hiện có

1. Trong V2, spec này bổ sung Home spec 0002. Widget debt vẫn chỉ đại diện debt sau finalize.
2. Trong V2, spec này bổ sung status và action cho Group Hub spec 0003.
3. Trong V2, spec này thay thế lifecycle action trong Bill Detail spec 0004 AC UI 7. Mọi nội dung OCR, item assignment và reconciliation khác của 0004 tiếp tục có hiệu lực.

Trong V1, spec 0006 và Bill Detail spec 0004 là nguồn đúng. Khi V2 được bật, spec 0005 trở thành nguồn đúng cho consent, review và finalize gate.
