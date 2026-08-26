# 0004. Bill Detail, OCR Parsing & Line Item Assignment UI v1

**Date**: 2026-08-20  
**Status**: Proposed  
**Platform**: Flutter 3.x (iOS & Android)  
**Feature Area**: `PaySplit-FE/lib/features/bills/`  
**Design System**: Tally x Hallmark (Editorial Warm Olive `#F5F6F1`, Deep Teal `#0F766E`, 1px Hairline `#DBE0CE`, Typography: `Newsreader` + `Roboto Slab` + `JetBrains Mono`)

> **V1 group close amendment**: [`0006-group-bill-close-ui-v1.md`](0006-group-bill-close-ui-v1.md) làm rõ rằng khóa nhóm chỉ chặn bill mới. Draft hiện có vẫn chỉnh sửa và review được, nhưng chỉ current Captain được finalize. Creditor không phải Captain không có quyền finalize bill của mình. Finalized bill luôn read only. Debtor consent trong spec 0005 được để sang V2.

---

## 1. Summary & User Experience Goals

Màn hình **Chi Tiết OCR Hóa Đơn & Gán Món Ăn (Smart OCR & Item Assignment)** là màn hình tương tác trọng tâm của PaySplit. Tại đây, người dùng (Creditor hoặc Captain) xem kết quả bóc tách tự động từ máy quét hóa đơn (LlamaExtract), đối chiếu với ảnh gốc, điều chỉnh danh sách món/thuế phí, và phân bổ từng món cho các thành viên trong nhóm một cách trực quan, minh bạch và chính xác tuyệt đối (không lệch dù chỉ 1 đồng VND).

---

## 2. Requirements & Acceptance Criteria

### 2.1. Acceptance Criteria (AC-UI)

- **AC-UI-1 (Receipt Header & Original Asset Preview)**:
  - Hiển thị thẻ phiếu thu (`Receipt Card`) viền răng cưa nhẹ, chứa Tên quán/Merchant (`Newsreader Medium 18px`), Ngày hóa đơn, Người trả trước (Creditor Monogram + Tên), và Tổng tiền hóa đơn (`Newsreader Bold 24px`).
  - Thumbnail ảnh hóa đơn gốc (tải từ Cloudinary Signed URL 5 phút) có nút phóng to mở `ImageViewerDialog` hỗ trợ pinch to zoom, xoay ảnh 90° và xem nhiều trang ảnh biên lai (1-5 ảnh).

- **AC-UI-2 (Realtime OCR Status & Candidate Review / Edit & Item-Specific Discount Preprocessing)**:
  - Khi hóa đơn ở trạng thái OCR (`queued` hoặc `processing`), màn hình hiển thị banner hiệu ứng quét động (Shimmer Pulse Amber `#FEF3C7`), kết nối Server-Sent Events (SSE) `GET /api/v1/bills/{id}/events`.
  - Khi SSE phát sự kiện `ocr.updated` (`status = succeeded`):
    - Hiển thị thông báo Toast và Card duyệt kết quả OCR (`OCRCandidateReviewCard`).
    - **Tiền xử lý khuyến mãi từng món (Item-Specific Discount Preprocessing)**:
      - Tự động quét mảng items từ LlamaExtract: Nếu gặp dòng khuyến mãi có tên chứa `"KM"`, `"Khuyen mai"`, `"Chiet khau"`, `"Giam gia"` hoặc `line_total < 0` (quantity `null`/0), giá trị khuyến mãi (chuyển số dương) sẽ gộp dồn vào `discount_amount` của món ngay trước đó, và tính `final_price = line_total - discount_amount`. Dòng "KM" bị loại bỏ khỏi danh sách món chính thức.
      - Nếu dòng KM đứng trước không có món (Orphan KM line), chuyển giá trị vào `general_discount` kèm cảnh báo `OCR_ORPHAN_ITEM_DISCOUNT`.
    - Cho phép người dùng kiểm tra danh sách món sạch do AI trích xuất song song với ảnh biên lai gốc.
    - **Cho phép chỉnh sửa, thêm hoặc xóa các món trong kết quả OCR trước khi áp dụng** (sửa tên, số lượng, đơn giá, chiết khấu riêng món `discount_amount`, giá thực `final_price`, xóa món AI đọc rác/thừa).
    - Nút `[ Áp dụng kết quả OCR vào bản nháp ]` gọi `POST /api/v1/bills/{id}/apply-candidate` kèm `version`.
  - Nếu OCR thất bại (`failed`): Hiển thị thông báo thân thiện kèm nút `[ 🔄 Quét lại OCR ]` (`POST /api/v1/bills/{id}/ocr-retry`) và nút chuyển sang nhập tay hoàn toàn.

- **AC-UI-3 (Splitting Mode Switcher)**:
  - Segmented Switcher gồm 2 chế độ:
    1. **`Chia theo từng món`** (`item_ratio`): Mặc định. Phân bổ chi tiết từng món cho người tham gia ăn.
    2. **`Chia đều cả bàn`** (`even`): Tự động gán toàn bộ món cho tất cả thành viên trong nhóm với tỷ lệ bằng nhau (`weight = 1/N`).

- **AC-UI-4 (Line Items Management & Multi-Member Avatar Assignment Bar)**:
  - Danh sách tối đa 100 món ăn/dịch vụ trong bản nháp (`draft`):
    - **Quản lý & Chỉnh sửa Món (CRUD Items in Draft)**:
      - **Tương tác Thẻ Món Ăn (`BillItemCard`)**: Bấm vào bất kỳ vị trí nào trên thẻ món ăn để mở `EditItemDialog`/`EditItemBottomSheet`. Các phần tử tương tác bên trong (nút avatar, nút chọn tất cả) gọi `event.stopPropagation()` để tránh mở nhầm Modal.
      - **Bố cục Hiển thị Giá Xếp Chồng (Stacked Price Layout)**: Dòng góc trên bên phải thẻ món ăn hiển thị giá thực tế sau giảm giá (`final_price`) chữ màu xanh lục đậm nổi bật ở dòng trên, giá gốc có gạch ngang (`line_total`) chữ xám nhỏ xếp ngay bên dưới.
      - **Thanh Tiêu Đề Thẻ Tinh Gọn**: Loại bỏ nút sửa rườm rà trên dòng tiêu đề; giữ lại nút xóa món màu đỏ (`.line-item-btn--danger`) sử dụng icon Hugeicons `delete-02` vát nét 1.8px (nền hồng nhạt `#FEF2F2`, viền đỏ `#FECACA`, icon đỏ `#DC2626`).
      - Cho phép chỉnh sửa trong Modal: Tên món (`name`), Số lượng (`quantity`), Đơn giá (`unit_price`), Thành tiền gốc (`line_total`), Khuyến mãi riêng món (`discount_amount`), và Giá thực sau giảm (`final_price = line_total - discount_amount`).
      - **Nút Xóa Món Nổi Bật Trong Modal (Destructive Full Button)**: Trong Modal Chỉnh sửa món ăn, nút `[ 🗑️ Xóa món này khỏi hóa đơn ]` được thiết kế dạng nút bấm rộng toàn chiều ngang (full-width button) nổi bật với viền đỏ, nền hồng nhạt và icon Hugeicons `delete-02`.
      - **Phần Chọn Thành Viên Tham Gia (Member Assignment Section in Modal)**:
        - Hiển thị danh sách đầy đủ tất cả thành viên trong nhóm kèm avatar, tên, checkbox chọn.
        - Nút tiện ích: `[ Chọn tất cả ]` / `[ Bỏ chọn ]`.
        - Tự động hiển thị số tiền tạm tính mỗi người gánh dựa trên **Giá thực `final_price`** (`Tạm tính: final_price / N đ / người`). Người ăn món nhận 100% ưu đãi khuyến mãi riêng của món đó.
      - Nút `[ + Thêm món thủ công ]` cho phép thêm món ăn mới phát sinh.
    - **Thanh Gán Người Ăn Thông Minh (Smart Avatar Assignment Bar on Item Card)**:
      - **Sắp xếp ưu tiên (Smart Sort)**: Tự động sắp xếp các thành viên **đã được chọn (assigned)** lên đầu hàng avatar.
      - **Giới hạn hiển thị 4 avatar + badge `+N`**:
        - Nếu nhóm có $> 4$ thành viên: Hiển thị tối đa 4 avatar đầu tiên.
        - Avatar thứ 5 hiển thị dạng badge tràn `+N` (với $N = \text{tổng thành viên} - 4$).
        - Chạm vào badge `+N` sẽ mở ngay Modal Chỉnh sửa món để người dùng chọn/bỏ chọn thành viên trong danh sách mở rộng.
      - Thành viên được chọn: Viền đậm Deep Teal `#0F766E`, nền nhạt, hiển thị số tiền mỗi người gánh dưới tên dựa trên `final_price` (ví dụ: `42.750 đ / người`).
      - Thành viên chưa chọn: Mờ nhạt (`opacity 0.45`), viền xám hairline `1px`.
      - Nút `[ Tất cả ]`: Chọn nhanh toàn bộ thành viên cho món dùng chung.

- **AC-UI-5 (Taxes, Surcharges & Discounts Management - `EditAdjustmentsDialog`)**:
  - Thẻ Phụ phí & Thuế có nhãn hiển thị gọn gàng: `Tổng KM từng món`, `Voucher giảm giá chung`, và dòng tổng kết `= Tổng cộng thanh toán`. Chạm trực tiếp vào thẻ hoặc nút `[ ✏️ Chỉnh sửa ]` để mở Modal `EditAdjustmentsDialog`:
    - **Phí dịch vụ** (`service_charge`): Nhập số tiền trực tiếp (VND) hoặc chọn nhanh chip `0đ`, `5%`, `10%` theo tiền món gốc.
    - **Thuế VAT** (`vat`): Nhập số tiền trực tiếp hoặc chọn nhanh chip `0%`, `8%`, `10%`.
    - **Tách bạch 2 trường Khuyến mãi (Separated Discount Fields)**:
      1. **`Tổng KM từng món (VND)`**: Ô chỉ đọc (`readonly`/`disabled`, nền xám nhạt `#F5F6F1`) tự động gộp tổng `discount_amount` từ tất cả các món ăn (`total_item_discount = Σ item.discount_amount`).
      2. **`Voucher giảm giá chung (VND)`**: Ô cho phép người dùng tự điền giảm giá Voucher toàn bill (`general_discount`). Các chip chọn nhanh `0đ`, `50k`, `10%` áp dụng riêng cho ô này.
    - **Khung xem trước trực tiếp (Live Preview)**: Hiển thị minh bạch từng bước tính toán: Tổng tiền món gốc (`gross_subtotal`), Trừ tổng KM từng món (`total_item_discount`), Tiền món thực tế (`net_items_total`), Phí dịch vụ, VAT, Voucher giảm giá chung (`general_discount`) và `= Tổng cộng thanh toán` trước khi nhấn `[ Lưu áp dụng ]`.
  - **Công thức phân bổ tỷ lệ**: `general_discount` (Voucher chung) được phân bổ tự động theo tỷ trọng % tiền món ăn thực tế của từng người (`user_net_subtotal / net_items_total`). Khuyến mãi riêng từng món (`discount_amount`) đã được trừ trực tiếp vào món đó và không bị phân bổ lại.

- **AC-UI-6 (Explicit Mismatch Calculation & Exact Delta Display)**:
  - Hệ thống tự động tính toán tổng các món và đối chiếu liên tục với số liệu hóa đơn:
    - `computed_gross_subtotal = Σ line_total`
    - `total_item_discount = Σ discount_amount`
    - `net_items_total = computed_gross_subtotal - total_item_discount = Σ final_price`
    - `computed_total = net_items_total + service_charge + vat - general_discount`
    - `delta_total = computed_total - reported_total`
  - **Hiển thị rõ ràng số tiền chênh lệch (Exact Delta)**:
    - **Trường hợp Khớp 100% (Xanh Emerald `#ECFDF5`)**:
      - *"Tổng tính toán: 1.240.000 đ · Khớp 100% với hóa đơn"*
    - **Trường hợp Lệch Thiếu (Đỏ Crimson `#FEF2F2` - `delta_total < 0`)**:
      - *"⚠️ Tổng tính toán (1.190.000 đ) THIẾU 50.000 đ so với hóa đơn gốc (1.240.000 đ)"*
      - Nút xử lý nhanh 1: `[ + Thêm phụ thu 50.000 đ ]` (Tạo 1 line item bù phần thiếu).
      - Nút xử lý nhanh 2: `[ Cập nhật Tổng bill thành 1.190.000 đ ]` (`reported_total = computed_total`).
    - **Trường hợp Lệch Thừa (Amber `#FEF3C7` - `delta_total > 0`)**:
      - *"⚠️ Tổng tính toán (1.300.000 đ) DƯ 60.000 đ so với hóa đơn gốc (1.240.000 đ)"*
      - Nút xử lý nhanh: `[ Cập nhật Tổng bill thành 1.300.000 đ ]` hoặc `[ Bù vào Voucher 60.000 đ ]`.
    - **Trường hợp có món chưa gán (`ITEM_UNASSIGNED`)**:
      - Thẻ món chưa có người gánh hiển thị viền cảnh báo Amber/Đỏ kèm badge *"Chưa gán người ăn"*.
      - Cảnh báo trên thanh đối soát: *"Còn 1 món (Bò nhúng dấm - 400.000 đ) chưa phân bổ cho ai."*

- **AC-UI-7 (Live Personal Share Summary & Action Buttons)**:
  - Sticky Bottom Bar gắn cố định ở đáy màn hình:
    - **Tóm tắt cá nhân**: Hiển thị phần tiền của người đang đăng nhập (`Phần của bạn: 349.500 đ`). Bấm vào mở Bottom Sheet xem bảng phân bổ chi tiết toàn nhóm (`BreakdownBottomSheet`).
    - **Nút Thao tác**:
      - Nếu là Creditor/Captain & Trạng thái Draft: Nút `[ Lưu nháp ]` (`PUT /api/v1/bills/{id}`) và `[ Xét duyệt (Review) ]` (`POST /api/v1/bills/{id}/review`).
      - Nếu là Captain và bill vẫn là `draft` nhưng version hiện tại đã review: Nút `[ Xác nhận & Chốt hóa đơn (Finalize) ]` (`POST /api/v1/bills/{id}/finalize`).
      - Nếu là Creditor nhưng không phải current Captain: Không hiển thị nút Finalize, kể cả với bill do chính họ tạo và đã review.
      - Nếu bill `finalized`: Chỉ hiển thị immutable breakdown và settlement progress. Mọi edit, OCR, save, review, delete và finalize action đều bị ẩn.
      - Nếu là Member thường: Nút `[ Xem chi tiết phần chia ]`.

- **AC-UI-8 (Optimistic Locking & Conflict Resolution)**:
  - Mọi thao tác lưu nháp/áp dụng OCR/review/finalize đều gửi kèm `version`.
  - Nếu xảy ra xung đột `409 VERSION_CONFLICT` (người khác đã sửa hoặc chốt trước): Hiển thị Dialog cảnh báo và tự động tải lại dữ liệu mới nhất từ server.

---

## 3. UI/UX Specifications & Visual Design Tokens

```
┌────────────────────────────────────────────────────────┐
│  ← Hóa đơn: Lẩu gà lá é Tao Ngộ               [ ⚙️ ]   │
├────────────────────────────────────────────────────────┤
│  🧾 RECEIPT CARD                                       │
│  Lẩu gà lá é Tao Ngộ                                  │
│  19/08/2026 19:30 · Người trả: Nam (Creditor)          │
│  Tổng tiền: 1.240.000 đ                                │
│  [ 🖼️ 2 ảnh biên lai - Chạm để phóng to & xoay ]       │
├────────────────────────────────────────────────────────┤
│  CHẾ ĐỘ CHIA:                                          │
│  (•) Chia theo từng món       ( ) Chia đều cả bàn      │
├────────────────────────────────────────────────────────┤
│  DANH SÁCH MÓN ĂN (4 món)              [ + Thêm món ]  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Lẩu gà lá é lớn (x1)               350.000 đ  │  │
│  │ [ ✏️ Sửa ] [ 🗑️ Xóa ]                             │  │
│  │ Gánh món: [NL] [ĐL] [TH] [TK]  [ + Tất cả (4) ]  │  │
│  │ -> 87.500 đ / người                              │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 2. Bò nhúng dấm đặc biệt (x2)         400.000 đ  │  │
│  │ [ ✏️ Sửa ] [ 🗑️ Xóa ]                             │  │
│  │ Gánh món: [NL] [TH]            [ + Tất cả (2) ]  │  │
│  │ -> 200.000 đ / người                             │  │
│  └──────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────┤
│  THUẾ, PHÍ & GIẢM GIÁ                                  │
│  • Phí dịch vụ: 50.000 đ                               │
│  • VAT (8%): 50.000 đ                                  │
│  • Giảm giá Voucher: - 50.000 đ                        │
├────────────────────────────────────────────────────────┤
│  ⚠️ CẢNH BÁO ĐỐI SOÁT & SAI LỆCH CỤ THỂ                │
│  ( ! ) Tổng tính toán: 1.190.000 đ (THIẾU 50.000 đ)    │
│  [ + Bù phụ thu 50.000 đ ] [ Cập nhật Tổng bill ]      │
├────────────────────────────────────────────────────────┤
│  STICKY BOTTOM BAR:                                    │
│  Phần của bạn: 349.500 đ     [ Xem bảng phân bổ ▾ ]   │
│  [ Lưu nháp ]         [ Xét duyệt hóa đơn ]            │
└────────────────────────────────────────────────────────┘
```

---

## 4. Component Structure & Architecture

```text
lib/features/bills/
├── domain/
│   ├── entities/
│   │   ├── bill_detail_entity.dart        # Thông tin chi tiết hóa đơn (subtotal, total_item_discount, general_discount, total, version)
│   │   ├── bill_item_entity.dart          # Dòng món ăn (id, name, qty, price, line_total, discount_amount, final_price)
│   │   ├── item_assignment_entity.dart    # Gán món (member_id, weight)
│   │   ├── bill_image_entity.dart         # Ảnh biên lai (id, position, signed_url)
│   │   ├── ocr_candidate_entity.dart      # Dữ liệu candidate từ LlamaExtract (đã gộp dòng KM vào preceding item)
│   │   └── bill_share_breakdown_entity.dart # Số tiền phân bổ từng người (tính dựa trên item final_price + general_discount share)
│   └── usecases/
│       ├── get_bill_detail_usecase.dart
│       ├── update_bill_draft_usecase.dart
│       ├── apply_ocr_candidate_usecase.dart
│       ├── retry_ocr_usecase.dart
│       ├── review_bill_usecase.dart
│       ├── finalize_bill_usecase.dart
│       └── delete_bill_draft_usecase.dart
├── data/
│   ├── models/
│   │   ├── bill_detail_model.dart
│   │   ├── bill_item_model.dart
│   │   └── bill_share_model.dart
│   ├── datasources/
│   │   ├── bill_remote_data_source.dart   # Retrofit client (/api/v1/bills/...)
│   │   └── bill_sse_client.dart           # SSE stream handler (/api/v1/bills/{id}/events)
│   └── repositories/
│       └── bill_repository_impl.dart
└── presentation/
    ├── notifiers/
    │   ├── bill_detail_notifier.dart      # Quản lý State chi tiết hóa đơn, live math & normalization
    │   └── bill_sse_notifier.dart         # Quản lý luồng SSE OCR status
    ├── pages/
    │   └── bill_detail_page.dart          # Màn hình chính
    └── widgets/
        ├── receipt_header_card.dart       # Header phiếu thu + ảnh thumbnail
        ├── split_mode_selector.dart       # Toggle Chia theo món vs Chia đều
        ├── bill_item_card.dart            # Thẻ từng món ăn kèm badge KM, giá gốc line_total vs final_price và thanh Avatar
        ├── edit_item_dialog.dart          # Modal thêm/sửa món ăn (Tên, Qty, UnitPrice, LineTotal, DiscountAmount, FinalPrice)
        ├── ocr_candidate_review_card.dart # Card xem và chỉnh sửa kết quả OCR trước khi apply (đã tiền xử lý KM)
        ├── avatar_assignment_bar.dart     # Danh sách avatar tròn bấm chọn người ăn
        ├── bill_adjustments_section.dart  # Mục Phí dịch vụ, VAT, Khuyến mãi (phân tách TotalItemDiscount vs GeneralDiscount)
        ├── reconciliation_warning_bar.dart# Thanh cảnh báo và hiển thị chi tiết số tiền sai lệch
        ├── bill_sticky_bottom_bar.dart    # Thanh chốt sổ dưới đáy màn hình
        ├── image_viewer_dialog.dart       # Modal zoom ảnh hóa đơn full size kèm xoay 90°
        └── bill_breakdown_bottom_sheet.dart # Modal xem chi tiết phân bổ toàn nhóm
```

---

## 5. State Management & Live Mathematical Calculations

### 5.1. Client-Side Live Reconciliation (Tính toán tức thì trên Client)
Để mang lại trải nghiệm mượt mà không có độ trễ:
1. Khi người dùng bấm chọn avatar gán món:
   - Cập nhật danh sách `assignments` của `item` đó.
   - Tính lại `weight = 1 / số_người_chọn`.
   - Tính lại `user_net_item_subtotal` của từng người tham gia dựa trên giá thực của từng món:
     $$\text{user\_net\_item\_subtotal} = \sum \lfloor \text{item.final\_price} \times \text{weight} \rfloor$$
2. Phân bổ Phụ phí, VAT, Giảm giá Voucher chung theo tỷ trọng:
   - `net_items_total = Σ item.final_price = gross_subtotal - total_item_discount`
   - `service_share = floor(service_charge * (user_net_item_subtotal / net_items_total))`
   - `vat_share = floor(vat * (user_net_item_subtotal / net_items_total))`
   - `general_discount_share = floor(general_discount * (user_net_item_subtotal / net_items_total))`
   - `user_final_amount = user_net_item_subtotal + service_share + vat_share - general_discount_share`
   - Phần dư lẻ số nguyên VND được cộng dồn cho Creditor (khớp 100% với thuật toán `CalculateFloorAllocation` ở Backend).
3. Tính toán chênh lệch (Delta calculation):
   - `total_item_discount = Σ item.discount_amount`
   - `general_discount = max(0, reported_discount - total_item_discount)`
   - `computed_total = net_items_total + service_charge + vat - general_discount`
   - `delta_total = computed_total - reported_total`
   - Cập nhật màu sắc và nút hành động của `ReconciliationWarningBar` ngay trong milliseconds.

---

## 6. Build Plan & Implementation Slices

### Slice 1: Domain Models, Entities & Retrofit Data Source
- [ ] Định nghĩa các Entity Freezed bất biến (`BillDetailEntity`, `BillItemEntity`, `ItemAssignmentEntity`, `BillShareEntity`).
- [ ] Khởi tạo `BillRemoteDataSource` kết nối các endpoint `/api/v1/bills/...`.
- [ ] Cài đặt `BillSSEClient` xử lý kết nối Server-Sent Events tự động reconnect và heartbeat.

### Slice 2: StateNotifier & Local Calculation Engine
- [ ] Xây dựng `BillDetailNotifier` với các hàm: `toggleMemberAssignment`, `setSplitMode`, `updateItem`, `addItem`, `removeItem`, `setAdjustments`, `resolveMismatch`.
- [ ] Viết Unit Test kiểm thử thuật toán chia sàn VND và tính delta sai lệch trên client.

### Slice 3: Receipt Header, Image Viewer & Split Mode Selector
- [ ] Cài đặt `ReceiptHeaderCard` với thiết kế phiếu thu viền răng cưa.
- [ ] Cài đặt `ImageViewerDialog` hỗ trợ phóng to / xoay ảnh hóa đơn gốc 90°.
- [ ] Cài đặt `SplitModeSelector` chuyển đổi mượt mà giữa Chia theo món và Chia đều.

### Slice 4: Line Item Card, Edit Item Dialog & Interactive Avatar Assignment Bar
- [ ] Cài đặt `BillItemCard` với nút Sửa/Xóa và animation khi chọn avatar.
- [ ] Cài đặt `EditItemDialog` hỗ trợ thêm món mới hoặc sửa chi tiết món hiện tại.
- [ ] Cài đặt `OCRCandidateReviewCard` cho phép duyệt và sửa kết quả OCR trước khi apply.
- [ ] Cài đặt `AvatarAssignmentBar` với avatar Monogram, nút `[ + Tất cả ]` và label số tiền mỗi người gánh.

### Slice 5: Adjustments Section, Warning Bar & Sticky Action Bar
- [ ] Cài đặt `BillAdjustmentsSection` (Phí dịch vụ, VAT, Giảm giá).
- [ ] Cài đặt `ReconciliationWarningBar` hiển thị chi tiết số tiền lệch (Thiếu -X đ / Dư +Y đ) kèm nút cân bằng nhanh.
- [ ] Cài đặt `BillStickyBottomBar` hiển thị phần tiền cá nhân và các nút Chốt hóa đơn / Lưu nháp.
- [ ] Cài đặt `BillBreakdownBottomSheet` xem bảng phân bổ chi tiết.
