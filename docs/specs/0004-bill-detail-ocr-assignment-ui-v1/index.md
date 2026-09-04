# 0004. Bill Detail, OCR Parsing & Line Item Assignment UI v1

**Date**: 2026-08-20  
**Updated**: 2026-09-04
**Status**: In Progress
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
      - Ô giảm giá món có bộ chọn `VND | %`. Chế độ phần trăm tính trên đơn giá của một phần. Giao diện quy đổi ngay về mức giảm VND cho một phần, sau đó tiếp tục lưu `discount_amount` là tổng số nguyên VND của cả dòng món như contract hiện tại.
      - Các ô nhập tiền trong modal hiển thị dấu chấm phân cách hàng nghìn khi người dùng nhập, ví dụ `1850000` thành `1.850.000`. Dữ liệu tính toán và dữ liệu lưu không chứa ký tự định dạng.
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
  - Thẻ `Thuế, Phí & Khuyến mãi` luôn hiển thị đủ chuỗi tính tiền theo thứ tự: `Tổng tiền món gốc`, `Tổng KM từng món`, `= Tiền món thực tế`, `Phí dịch vụ`, `Thuế VAT`, `Voucher giảm giá chung`, và `= Tổng cộng thanh toán`. Dòng tổng cộng dùng `computed_total`, không dùng `reported_total` của hóa đơn gốc.
  - Chạm trực tiếp vào thẻ hoặc nút `[ ✏️ Chỉnh sửa ]` mở Modal `EditAdjustmentsDialog`:
    - **Phí dịch vụ** (`service_charge`): Nhập số tiền trực tiếp (VND) hoặc chọn nhanh chip `0đ`, `5%`, `10%`.
    - **Thuế VAT** (`vat`): Nhập số tiền trực tiếp hoặc chọn nhanh chip `0%`, `8%`, `10%`.
    - **Tách bạch 2 trường Khuyến mãi (Separated Discount Fields)**:
      1. **`Tổng KM từng món (VND)`**: Ô chỉ đọc (`readonly`/`disabled`, nền xám nhạt `#F5F6F1`) tự động gộp tổng `discount_amount` từ tất cả các món ăn (`total_item_discount = Σ item.discount_amount`).
      2. **`Voucher giảm giá chung (VND)`**: Ô cho phép người dùng tự điền giảm giá Voucher toàn bill (`general_discount`). Các chip chọn nhanh `0đ`, `50k`, `10%` áp dụng riêng cho ô này.
    - Các chip phần trăm tính trên `net_items_total` và làm tròn tới VND gần nhất. Chip chỉ điền ô tương ứng, sau đó người dùng vẫn có thể sửa tay.
    - Mỗi ô Phí dịch vụ, Thuế VAT và Voucher chung có bộ chọn `VND | %`. Khi nhập phần trăm, giá trị được tính trên `net_items_total`, làm tròn tới VND gần nhất và cập nhật preview bằng VND. Phần trăm chỉ là trạng thái nhập tạm trong modal. Callback lưu, state, API payload và dữ liệu persisted tiếp tục dùng số nguyên VND.
    - Khi đổi giữa `VND` và `%`, giá trị VND hiện tại được giữ nguyên. Chế độ VND tự thêm dấu chấm phân cách hàng nghìn. Chế độ phần trăm chấp nhận dấu phẩy hoặc dấu chấm cho tối đa hai chữ số thập phân, hiển thị dấu phẩy và giới hạn từ 0 đến 100 phần trăm.
    - Trên màn hình từ 320 px ở cỡ chữ mặc định, label ngắn gọn và ba chip chọn nhanh nằm cùng một hàng. Bỏ `(VND)` khỏi label nhìn thấy vì ô nhập đã có hậu tố `đ`. Khi cỡ chữ accessibility từ 1.4 trở lên, nhóm chip được phép xuống hàng để giữ nguyên kích thước chữ và vùng chạm.
    - Các label nhìn thấy dùng `Phí dịch vụ`, `Thuế VAT`, `Voucher chung`, `Khuyến mãi món`, `Tiền món thực tế` và `Tổng thanh toán`. Semantic label vẫn dùng tên đầy đủ để trình đọc màn hình không mất ngữ cảnh.
    - **Khung xem trước trực tiếp (Live Preview)**: Hiển thị minh bạch từng bước tính toán: Tổng tiền món gốc (`gross_subtotal`), Trừ tổng KM từng món (`total_item_discount`), Tiền món thực tế (`net_items_total`), Phí dịch vụ, VAT, Voucher giảm giá chung (`general_discount`) và `= Tổng cộng thanh toán` trước khi nhấn `[ Lưu áp dụng ]`. Mỗi lần sửa ô hoặc chọn chip phải tự tính lại preview ngay.
    - `computed_total` là giá trị chỉ đọc. Không hiển thị ô nhập tổng tiền và không yêu cầu người dùng tự tính hoặc tự gõ tổng tiền ở bất kỳ bước nào trong modal.
    - `reported_total` là mốc đối soát lấy từ dữ liệu hóa đơn hoặc kết quả OCR. Modal không cho sửa giá trị này. Nếu cần chấp nhận tổng tự tính làm tổng hóa đơn mới, người dùng dùng hành động một chạm trên cảnh báo đối soát.
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
      - Nút xử lý nhanh 1: `[ + Thêm phụ thu 50.000 đ ]` tăng `service_charge` thêm đúng `abs(delta_total)`. Cách này giữ cơ chế phân bổ phụ thu theo tỷ trọng và không tạo món chưa gán.
      - Nút xử lý nhanh 2: `[ Cập nhật Tổng bill thành 1.190.000 đ ]` (`reported_total = computed_total`).
    - **Trường hợp Lệch Thừa (Amber `#FEF3C7` - `delta_total > 0`)**:
      - *"⚠️ Tổng tính toán (1.300.000 đ) DƯ 60.000 đ so với hóa đơn gốc (1.240.000 đ)"*
      - Nút xử lý nhanh 1: `[ Cập nhật Tổng bill thành 1.300.000 đ ]` đặt `reported_total = computed_total`.
      - Nút xử lý nhanh 2: `[ Bù vào Voucher 60.000 đ ]` tăng `general_discount` thêm đúng `delta_total`.
    - **Trường hợp có món chưa gán (`ITEM_UNASSIGNED`)**:
      - Thẻ món chưa có người gánh hiển thị viền cảnh báo Amber/Đỏ kèm badge *"Chưa gán người ăn"*.
      - Cảnh báo trên thanh đối soát: *"Còn 1 món (Bò nhúng dấm - 400.000 đ) chưa phân bổ cho ai."*
  - `ReconciliationWarningBar` nằm ngay sau `BillAdjustmentsSection`, cập nhật tức thì khi món, giảm giá món, phí, VAT, voucher hoặc tổng hóa đơn thay đổi.
  - Các nút xử lý nhanh chỉ xuất hiện khi bill còn được sửa. Mỗi nút chỉ đổi state local và đánh dấu `isDirty`; dữ liệu được gửi cùng `version` khi người dùng lưu nháp.
  - Khi vừa có chênh lệch tổng vừa có món chưa gán, cùng một thẻ cảnh báo phải hiển thị cả hai vấn đề. Chốt hoặc review vẫn bị chặn cho tới khi cả hai được xử lý.

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

### 5.2. Khoảng cách giữa code hiện tại và thiết kế đích

Tại ngày 2026-09-04, công thức live math đã có trong `BillDetailState`. `BillAdjustmentsSection` và `ReconciliationWarningBar` cũng đã tồn tại. Phần thay đổi này được triển khai theo hướng sửa tại chỗ vì domain model và API lưu draft đã có đủ `subtotal`, `service_charge`, `vat`, `discount`, `total`, `items` và `version`.

1. `BillAdjustmentsSection` hiện chỉ hiển thị phí, VAT, giảm giá khác và `bill.total`. Nó chưa hiển thị chuỗi tính tiền đầy đủ và đang dùng sai nguồn cho dòng tổng cộng.
2. Modal hiện cho sửa cả `total`, chưa có chip tính nhanh, chưa có trường chỉ đọc cho tổng KM từng món và chưa có live preview đầy đủ.
3. `ReconciliationWarningBar` đã render các trạng thái cơ bản nhưng chưa được đặt trong `BillDetailPage`. Trạng thái dư chưa có hành động bù vào voucher.
4. Hành động thêm phụ thu hiện tạo line item mới. Trong chế độ `item_ratio`, item này chưa được gán cho ai và sinh thêm lỗi đối soát. Hành động đích phải cộng vào `service_charge`.
5. Test hiện mới kiểm công thức trong notifier. Chưa có widget test cho card, modal, ba trạng thái đối soát, quyền sửa và các hành động xử lý nhanh.

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

### Slice 5: Thuế, Phí, Khuyến mãi và Đối soát

#### Slice 5.1: Hoàn thiện nguồn tính toán và hành động local

1. Giữ `reported_total` là `bill.total`, giữ `computed_total` là giá trị suy ra từ món và adjustments. Không tự đồng bộ hai giá trị khi sửa món hoặc adjustments. Đáp ứng **AC-UI-5**, **AC-UI-6**.
2. Đổi hành động thiếu tiền từ tạo item sang cộng `abs(delta_total)` vào `service_charge`. Thêm hành động dư tiền bằng cách cộng `delta_total` vào `general_discount`. Giữ `balanceTotalToComputed()` cho hành động cập nhật tổng bill. Mọi hành động đặt `isDirty = true`. Đáp ứng **AC-UI-6**.
3. Giới hạn mọi giá trị tiền nhập tay ở số nguyên VND không âm. `general_discount` không được làm `computed_total` nhỏ hơn `0`. Đáp ứng **AC-UI-5**, **AC-UI-6**.
4. Không tạo controller, field hoặc validation cho tổng thanh toán trong modal. Mọi nơi hiển thị tổng thanh toán đều đọc từ `computedTotal`. Đáp ứng **AC-UI-5**.

#### Slice 5.2: Đồng bộ thẻ tóm tắt với PaySplit UI

1. Sửa `bill_adjustments_section.dart` để hiển thị đủ bảy dòng theo AC UI 5. Dùng `computedTotal` cho dòng tổng cộng và giữ `bill.total` riêng cho đối soát. Đáp ứng **AC-UI-5**.
2. Giữ toàn bộ thẻ có thể chạm khi `isEditable = true`. Ẩn nút chỉnh sửa và vô hiệu thao tác mở modal khi bill là read only. Đáp ứng **AC-UI-5**, **AC-UI-7**.
3. Dùng màu Teal cho `net_items_total` và `computed_total`, màu Emerald cho các khoản giảm, đường phân cách nét đứt trước phần phí và đường phân cách rõ trước tổng cộng. Hỗ trợ light theme, dark theme và text scale lớn mà không tràn ngang. Đáp ứng **AC-UI-5**.

#### Slice 5.3: Xây lại modal adjustments

1. Đổi tiêu đề modal thành `Phụ phí, Thuế & Khuyến mãi`. Xóa hoàn toàn ô nhập, controller và tham số save cho `Tổng cộng`. Thêm trường chỉ đọc `Tổng KM từng món`. Đổi `Giảm giá khác` thành `Voucher giảm giá chung`. Đáp ứng **AC-UI-5**.
2. Thêm chip phí `0đ`, `5%`, `10%`, chip VAT `0%`, `8%`, `10%`, chip voucher `0đ`, `50k`, `10%`. Chip phần trăm tính từ `computedNetItemsTotal` và làm tròn tới VND gần nhất. Đáp ứng **AC-UI-5**.
3. Cập nhật live preview sau mọi thay đổi. Preview hiển thị gross subtotal, tổng KM món, net items total, phí, VAT, voucher và computed total chỉ đọc. Nút `Hủy` không đổi state. Nút `Lưu áp dụng` chỉ gửi `serviceCharge`, `vat` và `generalDiscount` vào `setAdjustments`, rồi đóng modal. Đáp ứng **AC-UI-5**.
4. Khi bàn phím mở hoặc text scale tăng, modal vẫn cuộn được và hai nút cuối vẫn truy cập được. Mỗi field có label và semantic rõ ràng cho screen reader. Đáp ứng **AC-UI-5**.
5. Ở cỡ chữ mặc định, đặt label và nhóm chip trên cùng một hàng, hỗ trợ từ chiều rộng 320 px. Dùng label hiển thị ngắn và giữ tên đầy đủ trong semantics. Từ text scale 1.4 trở lên, cho phép chip xuống hàng thay vì thu nhỏ chữ hoặc vùng chạm. Rút gọn label trong live preview và thẻ tóm tắt, đồng thời giữ giá trị tiền căn phải và không bị cắt. Đáp ứng **AC-UI-5**.

#### Slice 5.4: Gắn cảnh báo đối soát vào Bill Detail

1. Đặt `ReconciliationWarningBar` ngay dưới `BillAdjustmentsSection` trong `bill_detail_page.dart`. Truyền trực tiếp `computedTotal`, `bill.total`, `deltaTotal` và danh sách item chưa gán từ state hiện tại. Đáp ứng **AC-UI-6**.
2. Hoàn thiện bốn trạng thái: khớp, thiếu, dư, và có item chưa gán. Nếu có cả delta và item chưa gán, hiển thị cả hai trong cùng card. Đáp ứng **AC-UI-6**.
3. Trạng thái thiếu có hành động thêm phụ thu và cập nhật tổng bill. Trạng thái dư có hành động bù vào voucher và cập nhật tổng bill. Bill read only chỉ hiển thị thông tin, không hiển thị hành động sửa. Đáp ứng **AC-UI-6**, **AC-UI-7**.
4. Sau mỗi hành động, card phải chuyển ngay về trạng thái mới từ cùng một nguồn state. Không gọi API riêng. Thao tác được lưu qua flow `saveDraft` hiện tại với `version`. Đáp ứng **AC-UI-6**, **AC-UI-8**.

#### Slice 5.5: Kiểm thử và xác nhận

1. Bổ sung unit test cho chip phần trăm, cộng phụ thu, cộng voucher, cập nhật reported total, clamp giá trị và `isDirty`. Đáp ứng **AC-UI-5**, **AC-UI-6**.
2. Bổ sung widget test cho bảy dòng summary, modal chỉ đọc tổng KM món, không tồn tại ô nhập tổng tiền, tổng tự cập nhật trong live preview, Hủy, Lưu áp dụng, light theme, dark theme và text scale lớn. Đáp ứng **AC-UI-5**.
3. Bổ sung widget test cho trạng thái khớp, thiếu, dư, chưa gán, trạng thái kết hợp, và bill read only. Xác nhận các nút đúng xuất hiện và thay đổi đúng state. Đáp ứng **AC-UI-6**, **AC-UI-7**.
4. Chạy `dart format .`, `flutter analyze` và các test bills liên quan. Sau đó chạy `flutter test` toàn bộ trước khi bàn giao. Đáp ứng **AC-UI-5** đến **AC-UI-8**.
5. Kiểm tra modal ở chiều rộng 320 px và 360 px với text scale mặc định, xác nhận label cùng hàng với chip và không tràn ngang. Kiểm tra thêm text scale 1.6, xác nhận chip có thể xuống hàng và hai nút cuối vẫn truy cập được. Đáp ứng **AC-UI-5**.

#### Slice 5.6: Nhập VND hoặc phần trăm

1. Thêm formatter VND dùng chung, tự chèn dấu chấm phân cách hàng nghìn nhưng parse về số nguyên VND. Áp dụng cho đơn giá, giảm giá món, phí dịch vụ, VAT và voucher chung. Đáp ứng **AC-UI-4**, **AC-UI-5**.
2. Thêm bộ chọn `VND | %` cho giảm giá món. Phần trăm dùng đơn giá mỗi phần làm cơ sở, quy đổi sang VND mỗi phần và giữ `discount_amount` là tổng VND của dòng món. Đáp ứng **AC-UI-4**.
3. Thêm bộ chọn `VND | %` cho phí dịch vụ, VAT và voucher chung. Phần trăm dùng `computedNetItemsTotal` làm cơ sở. Preview và callback lưu luôn nhận số nguyên VND. Đáp ứng **AC-UI-5**.
4. Bổ sung test cho định dạng hàng nghìn, phần trăm thập phân, chuyển chế độ không đổi giá trị VND, preview và payload lưu VND. Đáp ứng **AC-UI-4**, **AC-UI-5**.

Phần này không cần migration, endpoint mới, package mới hoặc thay đổi code sinh tự động. Nếu Backend thay đổi quy tắc phân bổ adjustments, FE phải tiếp tục coi breakdown do Backend trả sau khi lưu là nguồn đúng cuối cùng.
