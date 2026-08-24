# 0003. Group Hub & Bill History UI Specification (Mobile Flutter)

**Date**: 2026-08-19  
**Status**: Proposed / Ready for Review  
**Style System**: Tally x Hallmark (Utilitarian Warm Editorial, Notion & Claude-inspired)  
**UI Framework**: Flutter 3.x + [Forui](https://forui.dev) + Riverpod 2.x  
**Design Tokens**: [`PaySplit-UI/ui-context.md`](../../../PaySplit-UI/ui-context.md) (`Newsreader`, `Roboto Slab`, `JetBrains Mono`, `Hugeicons`, Warm Olive Palette `#F5F6F1`, Deep Teal `#0F766E`, Medium Radius 10px)  
**Companion Backend Specs**:
- [`PaySplit-BE/docs/specs/0002-group-management-v1/index.md`](../../../PaySplit-BE/docs/specs/0002-group-management-v1/index.md) (Chi tiết nhóm, thành viên, mã mời, phân quyền Captain)
- [`PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md`](../../../PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md) (Danh sách hóa đơn, trạng thái OCR, chốt & hủy hóa đơn)
- [`PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md`](../../../PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md) (Bảng công nợ nhóm, sinh mã VietQR, nộp & duyệt proof)
- [`PaySplit-BE/docs/specs/0006-notification-queue-v1/index.md`](../../../PaySplit-BE/docs/specs/0006-notification-queue-v1/index.md) (Nhắc nợ tự động, thông báo hoạt động)
**Related UI Specs**:
- [`PaySplit-FE/docs/specs/0001-auth-ui-v1.md`](0001-auth-ui-v1.md) (Xác thực, đăng ký, đăng nhập ngầm & deep link)
- [`PaySplit-FE/docs/specs/0002-home-balance-ui-v1.md`](0002-home-balance-ui-v1.md) (Trang chủ, tổng quan số dư, danh sách nhóm, nộp/duyệt proof)

> **V1 group close amendment**: [`0006-group-bill-close-ui-v1.md`](0006-group-bill-close-ui-v1.md) bổ sung trạng thái khóa nhận bill, action Captain `Khóa gửi hóa đơn mới`, `Chốt toàn bộ` và batch progress. Debtor consent trong spec 0005 được để sang V2.

---

## 1. Executive Summary & Goals

**Màn hình Chi Tiết Nhóm & Lịch Sử Hóa Đơn (Group Hub & Bill History)** là trung tâm điều phối mọi hoạt động tài chính nội bộ của một nhóm chi tiêu. Màn hình phục vụ 4 mục tiêu nghiệp vụ cốt lõi:
1. **Nắm bắt số dư cá nhân trong nhóm**: Biết ngay mình đang nợ ai hoặc ai nợ mình trong riêng nhóm này (**Group Net Balance Banner**).
2. **Theo dõi vòng đời hóa đơn (Bill Lifecycle Feed)**: Xem danh sách hóa đơn từ lúc bản nháp (`draft`), phân bổ món, đến khi chốt sổ (`finalized`) hoặc hủy (`voided`), kèm trạng thái bóc tách OCR theo thời gian thực.
3. **Quản lý công nợ & thanh toán tức thì (Group Settlement Matrix)**: Xem ma trận nợ ai trả cho ai, sinh mã Dynamic VietQR 1-chạm để trả nợ hoặc duyệt ảnh chuyển khoản kèm lời nhắn.
4. **Quản trị thành viên & liên kết mời (Members & Invites)**: Quản lý danh sách thành viên tối đa 50 người, tạo mã mời gồm đúng 8 ký tự chữ và số, dùng chung cho nhập tay, Deep Link và QR, kèm thời hạn, chuyển giao vai trò Captain hoặc rời nhóm an toàn (không còn nợ đọng).

Thiết kế tuân thủ nghiêm ngặt tinh thần **Tally x Hallmark**: bố cục thẻ biên lai rõ ràng, kiểu chữ biên tập sang trọng (`Newsreader` x `Roboto Slab`), con số `JetBrains Mono` chuẩn xác từng đồng, sử dụng Monogram đại diện nhóm tinh tế thay vì emoji trang trí, và tối ưu cảm ứng một tay trên di động.

---

## 2. UI Acceptance Criteria (AC-UI)

- **AC-UI-1 (Typography & Token Compliance)**:
  - Tên nhóm, tiêu đề các mục sử dụng font **`Newsreader`** (Editorial Serif, Roman upright).
  - Nhãn nút, thông tin thành viên, văn bản hướng dẫn sử dụng font **`Roboto Slab`**.
  - Toàn bộ số tiền (VND), mã mời (`4AHRjDTj`), mã giao dịch (`FT...`), mã tham chiếu (`PAY...`) sử dụng font **`JetBrains Mono`** (`tabular-nums`).
  - Màu nền trang là **`Warm Olive Paper (#F5F6F1)`**, thẻ `FCard` nền trắng (`#FFFFFF`) viền `1px solid #DBE0CE`, bo góc `10px`.
  - Icon sử dụng độc quyền bộ **`Hugeicons`** nét mảnh `1.5px`.

- **AC-UI-2 (Group Header & Governance Integration)**:
  - Header hiển thị nút Back, Monogram Avatar đại diện nhóm (2 chữ cái đầu, ví dụ `ĐL` trên nền Teal `#F0FDFA`), Tên nhóm, và số lượng thành viên (`"8 thành viên"`).
  - Có huy hiệu vương miện 👑 nếu người dùng hiện tại là **Captain** (Trưởng nhóm).
  - Nút bánh răng Cài đặt nhóm (Settings) mở Modal Bottom Sheet **`GroupSettingsBottomSheet`** quản trị thông tin nhóm, phân quyền thành viên, chuyển Trưởng nhóm, và vùng nguy hiểm (Rời nhóm / Giải tán nhóm).
  - Toàn bộ tính năng xem, tạo, sao chép và thu hồi mã mời được chuyển vào Modal Bottom Sheet **`InviteCodeBottomSheet`** được kích hoạt từ nút `[ + Thêm thành viên ]` trong Tab Thành viên.

- **AC-UI-3 (Group Balance Banner)**:
  - Hiển thị số dư riêng của người dùng trong nhóm với 3 trạng thái màu:
    - **Dương (+)**: Nền `#ECFDF5`, chữ `#059669` (`+350.000 đ` — Bạn được nhận lại).
    - **Âm (-)**: Nền `#FEF2F2`, chữ `#DC2626` (`-120.000 đ` — Bạn cần trả nợ) kèm nút nhanh `[ Trả QR ⚡ ]`.
    - **Bằng 0 (0 đ)**: Nền `#EDF0E6`, chữ `#1C2118` (`0 đ` — Sạch nợ trong nhóm).

- **AC-UI-4 (4-Tab Segregation - FTabs)**:
  - Phân tách giao diện thành 4 tab rõ ràng:
    1. `🧾 Hóa đơn (Bills)`: Danh sách hóa đơn của nhóm kèm bộ lọc trạng thái.
    2. `📊 Công nợ (Debts)`: Bảng nợ cá nhân và ma trận nợ toàn nhóm.
    3. `👥 Thành viên (Members)`: Danh sách thành viên, vai trò và quản lý mã mời.
    4. `⏱ Hoạt động (Timeline)`: Dòng thời gian sự kiện nhóm theo phân trang cursor.

- **AC-UI-5 (Bill Receipt Card Presentation & Statuses)**:
  - Mỗi hóa đơn hiển thị dưới dạng **Vé thu tiền (Receipt Card)**:
    - Tên quán/địa điểm, ngày hóa đơn (`billDate` format `dd/MM/yyyy`, fallback ngày xử lý OCR / ngày tạo nếu hóa đơn chưa nhận diện được ngày), badge số ảnh chụp (`📸 2`).
    - Tên và avatar người đã trả tiền trước (`creditorName`).
    - Tổng tiền hóa đơn (Mono) + Số tiền phân bổ riêng của caller (`"Phần của bạn: 212.500 đ"`).
    - Huy hiệu trạng thái Forui (`FBadge`):
      - `Đang quét OCR`: Màu hổ phách `#D97706` / `#FFFBEB` kèm hiệu ứng shimmer / loading spinner khi `ocrState == processing`.
      - `Chờ phân bổ món`: Màu xanh dương `#2563EB` / `#EFF6FF` khi bill ở trạng thái `draft`.
      - `Đã chốt sổ`: Màu xanh ngọc `#059669` / `#ECFDF5` khi bill ở trạng thái `finalized`.
      - `Đã hủy (Voided)`: Màu xám `#676E5F` / `#F3F4F6` kèm lý do hủy khi bill ở trạng thái `voided`.
    - Thanh tiến độ thu hồi nợ (Progress bar mỏng 3px: `3/5 người đã trả`).
    - Bản nháp bị xóa (`draft deleted`) sẽ tự động biến mất khỏi danh sách sau khi refresh mà không gây lỗi.

- **AC-UI-6 (Debt Settlement Matrix & VietQR Integration)**:
  - Nhóm các khoản nợ theo Chủ nợ trong nhóm.
  - Bấm `[ Trả QR ⚡ ]` mở Bottom Sheet VietQR động chứa đúng số tiền nợ và cú pháp `PAY...`.
  - Chủ nợ bấm `[ Duyệt proof ]` xem ảnh biên lai ngân hàng kèm lời nhắn (`payments.note` theo BE Spec 0004 AC-6).

- **AC-UI-7 (Member & Captain Governance Safety Rules)**:
  - Captain có thể chuyển vai trò Captain cho thành viên active khác qua `PUT /api/v1/groups/{id}/members/{memberId}/role`.
  - Nút `[ Rời nhóm ]` bị khóa nếu thành viên còn nợ chưa tất toán (`409 GROUP_MEMBER_HAS_OPEN_DEBTS`).
  - Captain không được tự ý rời nhóm nếu chưa chuyển giao quyền Captain (`409 CAPTAIN_TRANSFER_REQUIRED`).

- **AC-UI-8 (8-State Widget Completeness & Tactile Feedback)**:
  - Mọi thành phần tương tác (Tab, Button, Card, Context Menu) có đủ 8 trạng thái: Default, Hover/Pressed (`scale: 0.98`), Focus-visible (`1.5px #0F766E`), Disabled (`opacity: 0.4`), Loading (Skeleton/Spinner), Error (Forui Alert inline), Success (Tick xanh).

---

## 3. Screen Structure & Navigation Integration

### 3.1. Sơ Đồ Điều Hướng Đa Màn Hình (Navigation Map)

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                 │
│  [0001. Auth / Welcome] ──> [0002. Home / Dashboard] ──────────┐                               │
│                                  │ (Bấm Thẻ Nhóm)               │ (Deep Link Mã Mời)            │
│                                  ▼                              ▼                               │
│                     [0003. Group Hub (Trang Này)] <───── [Join Group Modal]                     │
│                        │       │         │        │                                             │
│       ┌────────────────┘       │         │        └────────────────┐                            │
│       ▼                        ▼         ▼                         ▼                            │
│  [Tab 1: Hóa đơn]      [Tab 2: Nợ]   [Tab 3: Thành viên]   [Tab 4: Hoạt động]                   │
│       │                        │         │                         │                            │
│       ├─> [+ Quét OCR] ──┐     ├─> [Trả QR] (VietQR Sheet)         └─> [Cursor Stream]          │
│       ├─> [+ Nhập tay] ──┼─> [Chi Tiết Hóa Đơn / Review OCR]                                   │
│       └─> [Xem Bill] ────┘     └─> [Duyệt Proof] (Proof Sheet)                                  │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2. Bố Cục Màn Hình (Screen Layout)

```text
┌──────────────────────────────────────────────────────────────────┐
│  STATUS BAR (Minimalist 44px)                                    │
├──────────────────────────────────────────────────────────────────┤
│  [TOP APP BAR]                                                   │
│  [← Back]  [ĐL] Du lịch Đà Lạt 2026  👑  (8 TV)    [⚙️ Settings] │
├──────────────────────────────────────────────────────────────────┤
│  [GROUP NET BALANCE BANNER]                                      │
│  Số dư của bạn trong nhóm:  +350.000 đ    [ Bạn được nhận lại ]  │
│  (Đang cho nợ: +470.000 đ  │  Đang nợ: -120.000 đ)               │
├──────────────────────────────────────────────────────────────────┤
│  [4-TAB SEGMENTED BAR - FTabs]                                   │
│  [ 🧾 Hóa đơn (4) ] [ 📊 Công nợ ] [ 👥 Thành viên (8) ] [ ⏱ ]  │
├──────────────────────────────────────────────────────────────────┤
│  [TAB 1: BILLS FEED (Default View)]                              │
│  Filter Pills: [ Tất cả ]  [ Đang xử lý (1) ]  [ Đã chốt (3) ]   │
│                                                                  │
│  ┌─ RECEIPT CARD 1 (Finalized) ────────────────────────────────┐ │
│  │ 🧾 Lẩu gà lá é Tao Ngộ                       📸 2 ảnh        │ │
│  │ 19/08/2026 • Trả bởi: Hoàng Nam                              │ │
│  │ Tổng bill: 850.000 đ          Phần bạn: 212.500 đ           │ │
│  │ [✓ Đã chốt sổ]                Tiến độ: 3/4 đã trả (75%)     │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─ RECEIPT CARD 2 (Processing OCR) ───────────────────────────┐ │
│  │ 🧾 Cafe Túi Mơ To                            📸 1 ảnh        │ │
│  │ 19/08/2026 • Đang trích xuất AI LlamaExtract...              │ │
│  │ [⏳ Đang quét OCR (80%)]      [ Hủy bản nháp ]              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  [+ FAB: QUÉT / TẠO HÓA ĐƠN MỚI]                                 │
├──────────────────────────────────────────────────────────────────┤
│  [BOTTOM NAVIGATION DOCK (4 Tabs)]                               │
│  [ 🏠 Tổng quan ]   [ 👥 Nhóm • ]   [ 🧾 Hóa đơn ]   [ ⚙️ Cài đặt ] │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Component-by-Component Specifications

### 4.1. Group Header & Navigation Bar (`GroupHeader.dart`)
- **Left Action**: Nút Back (`HugeIcons.strokeRoundedArrowLeft01` 22px) quay về màn hình trước đó (`HomePage`).
- **Center Title**:
  - Monogram Avatar: Khung tròn `32px` viền `1px solid #DBE0CE`, nền `#F0FDFA`, chữ viết tắt tên nhóm (ví dụ `ĐL` cho `Du lịch Đà Lạt`) theo font `Roboto Slab SemiBold 13px, #0F766E`.
  - Tên nhóm (`Newsreader Medium 18px, #1C2118`).
  - Huy hiệu Trưởng nhóm: Icon Crown nhỏ màu vàng `#F59E0B` nếu caller là Captain.
  - Phụ đề nhỏ: `"8 thành viên • Tạo ngày 15/08"` (`Roboto Slab Regular 11px, #676E5F`).
- **Right Action**:
  - Nút Cài đặt (`HugeIcons.strokeRoundedSettings02` 20px) mở Modal Quản trị nhóm.

---

### 4.2. Modal Quản Lý Mã Mời (`InviteCodeBottomSheet.dart`)
- **Khởi chạy**: Mở khi người dùng bấm nút `[ + Thêm thành viên ]` ở góc trên của **Tab 3: Thành viên** (`showModalBottomSheet` với `isScrollControlled: true` và `StatefulBuilder`).
- **Cấu trúc giao diện**:
  1. **Header**:
     - Tiêu đề `"Quản lý mã mời"` được căn giữa (`Newsreader SemiBold 18px, #1C2118`).
     - Nút IconButton đóng `"X"` ở góc phải (`Navigator.pop(context)`).
  2. **Mô tả hướng dẫn**:
     - `"Chia sẻ mã mời hoặc liên kết để thêm bạn bè vào nhóm."` (`Roboto Slab Regular 12px, #676E5F`, căn giữa).
  3. **Danh sách mã mời đang hoạt động (`Active Invites List`)**:
     - Hiển thị danh sách mã mời từ `GET /api/v1/groups/{id}/invites`.
     - Mỗi card item gồm:
       - Chuỗi mã mời được highlight nổi bật: `4AHRjDTj` (`JetBrains Mono Bold 15px`, nền `#F0FDFA`, viền `1px solid #CCFBF1`, chữ `#0F766E`).
       - Dòng phụ hiển thị trạng thái: `"Còn 23 giờ • 12/50 lượt"` (hoặc `"Không giới hạn"`).
       - Hàng 2 nút thao tác nhanh (Action Row):
         - Nút `[ 📋 Sao chép ]`: Sao chép link `https://paysplit.app/join/{code}` qua `Clipboard.setData` kèm thông báo Toast/SnackBar.
         - Nút `[ 🗑 Thu hồi ]`: Nút viền đỏ outline cảnh báo (`#EF4444` / `#DC2626`), bấm gửi request `DELETE /api/v1/groups/{id}/invites/{inviteId}` và cập nhật trực tiếp danh sách trong Modal qua `StatefulBuilder`.
  4. **Nút tạo mã mới (Bottom Action)**:
     - Nút `[ + Tạo mã mời mới ]` chiếm trọn 100% chiều ngang (Full-width `ElevatedButton` / `FButton.primary`) đặt ở đáy sheet. Bấm gọi `POST /api/v1/groups/{id}/invites` và tự động bổ sung mã mới vào danh sách.

#### Deep Link Delivery Note

`https://paysplit.app/join/{code}` chỉ là URL mời. Để URL mở ứng dụng Flutter khi ứng dụng đã được cài, iOS phải cấu hình Universal Links và Android phải cấu hình Android App Links cho domain `paysplit.app`. Cả hai nền tảng chuyển đường dẫn `/join/{code}` vào router, router lưu code trong bộ nhớ điều hướng khi người dùng cần đăng nhập, rồi tiếp tục preview và xác nhận tham gia.

Khi ứng dụng chưa được cài, URL mở trang web fallback tại cùng đường dẫn. Deferred deep link sau khi cài ứng dụng là một quyết định tích hợp riêng. V1 có thể yêu cầu người dùng mở lại link sau khi cài. Chỉ bổ sung dịch vụ deferred deep link khi sản phẩm chọn nhà cung cấp và xác định yêu cầu đo lường cài đặt.

---

### 4.3. Group Net Balance Banner (`GroupBalanceBanner.dart`)
- Thẻ bo tròn viền mỏng hiển thị số dư của người dùng riêng trong nhóm:
  - Nếu `net_balance > 0`: Nền xanh ngọc nhạt `#ECFDF5`, chữ số `#059669`, nhãn *"Bạn được nhận lại"*.
  - Nếu `net_balance < 0`: Nền đỏ nhạt `#FEF2F2`, chữ số `#DC2626`, nhãn *"Bạn cần trả nợ"* kèm nút bấm `[ Trả QR ⚡ ]`.
  - Nếu `net_balance == 0`: Nền xám `#EDF0E6`, chữ `#1C2118`, nhãn *"Đã cân bằng sạch nợ"*.

---

### 4.4. Tab 1: Danh Sách Hóa Đơn (`GroupBillsTab.dart`)
- **Thanh lọc trạng thái (Filter Chips)**:
  - `Tất cả (4)` | `Đang xử lý (1)` | `Đã chốt (3)` | `Đã hủy (0)`.
- **Thẻ Hóa Đơn Biên Lai (`BillReceiptCard.dart`)**:
  - **Header Vé**: Tên quán (`Roboto Slab SemiBold 15px`), ngày hóa đơn (`billDate` format `dd/MM/yyyy`, fallback ngày xử lý OCR / ngày tạo nếu hóa đơn chưa nhận diện được ngày), badge số ảnh chụp (`📸 2`).
  - **Payer Info**: Avatar + Tên người đã trả tiền trước (`creditorName`).
  - **Financials**:
    - Tổng tiền hóa đơn (`JetBrains Mono Bold 15px`).
    - Số tiền phân bổ riêng của caller (`"Phần của bạn: 212.500 đ"`).
  - **Trạng thái & Tiến độ**:
    - Badge trạng thái Forui (`FBadge.success` cho Đã chốt, `FBadge.warning` cho Đang quét OCR, `FBadge.outline` cho Chờ phân bổ món, `FBadge.destructive` cho Đã hủy).
    - Thanh tiến độ thanh toán (`ProgressBar` 3px màu Teal: `settledMemberCount / totalMemberCount`).
- **Nút Tạo Hóa Đơn (`CreateBillSpeedDialFAB` / `ExpandableBillFab`)**:
  - Dạng nút tròn (Circular FAB tiêu chuẩn) đặt tại `FloatingActionButtonLocation.endFloat`, nằm ngay sát trên thanh Bottom Navigation Dock.
  - Khi bấm, icon dấu `+` xoay mượt 45 độ thành dấu `×` kết hợp lớp phủ mờ (backdrop overlay), bung ra menu 2 nút con (Speed Dial) với hiệu ứng Scale + Slide:
    1. `[ 📸 Quét hóa đơn AI OCR ]`: Mở camera/thư viện chọn tối đa 5 ảnh $\rightarrow$ gọi `POST /bills` (multipart) $\rightarrow$ chuyển đến màn hình Review OCR theo dõi qua SSE stream.
    2. `[ ✍️ Nhập tay ]`: Mở form nhập thủ công món ăn và số tiền $\rightarrow$ gọi `POST /bills` (JSON).

---

### 4.5. Tab 2: Bảng Công Nợ & Ma Trận Thanh Toán (`GroupDebtsTab.dart`)
- **Khoản nợ cá nhân cần xử lý**:
  - Danh sách người bạn cần trả trong nhóm kèm nút `[ Trả QR ⚡ ]`.
  - Danh sách người đang nợ bạn trong nhóm kèm nút `[ Duyệt proof ]` (kèm lời nhắn `payments.note` nếu đã nộp proof) hoặc `[ 🔔 Nhắc nợ ]` (rate limit 1 lần/24h).
- **Ma trận công nợ cả nhóm (Debt Matrix)**:
  - Bảng thu gọn hiển thị các cặp nợ trong nhóm: `A → B: 120.000 đ`, `C → B: 150.000 đ`.
  - Tổng số tiền cần thanh toán để cả nhóm sạch nợ (Tối ưu hóa số lần chuyển tiền).

---

### 4.6. Tab 3: Quản Lý Thành Viên & Phân Quyền (`GroupMembersTab.dart`)
- **Header Tab & Nút Hành Động**:
  - Tiêu đề mục: `"Thành viên (5)"` (`Roboto Slab SemiBold 16px`).
  - Nút **`[ + Thêm thành viên ]`**: Nút bo tròn nhỏ (`FButton.outline` hoặc `group-state-toggle`), khi ấn gọi `showModalBottomSheet` mở **`InviteCodeBottomSheet`**.
- **Danh sách thành viên (Active Members)**:
  - Mỗi dòng: Avatar tròn, Tên hiển thị, Vai trò (`Captain 👑` hoặc `Thành viên`), Số dư riêng của thành viên đó trong nhóm (được ghép từ `balances[]`).
  - **Menu thao tác của Captain**:
    - `Chuyển quyền Trưởng nhóm (Transfer Captain)`: Mở hộp thoại xác nhận $\rightarrow$ gọi `PUT /members/{memberId}/role`.
    - `Mời ra khỏi nhóm (Kick Member)`: Kiểm tra ràng buộc không còn nợ trước khi xóa $\rightarrow$ gọi `DELETE /members/{memberId}`.
- **Nút Rời Nhóm (`LeaveGroupButton`)**:
  - Đặt dưới đáy màn hình, màu đỏ outline. Hiển thị cảnh báo và bị khóa nếu còn nợ chưa thanh toán (`409 GROUP_MEMBER_HAS_OPEN_DEBTS`).

---

### 4.7. Tab 4: Dòng Thời Gian Hoạt Động (`GroupActivityTab.dart`)
- Dòng thời gian phân trang bằng Cursor (`GET /api/v1/groups/{id}/activities`):
  - Sự kiện: Tạo hóa đơn mới, Duyệt OCR, Chốt chia tiền, Nộp biên lai, Xác nhận nhận tiền, Chuyển quyền Captain, Gia nhập nhóm...
  - Mỗi dòng gồm Icon loại hoạt động, mô tả tiếng Việt tự nhiên do BE sinh và thời gian tương đối (`"5 phút trước"`).

---

### 4.8. Modal Cài Đặt Nhóm (`GroupSettingsBottomSheet.dart`)
Modal Bottom Sheet trượt lên khi bấm nút bánh răng `⚙️` trên Header của Group Hub:
- **Header**: Tiêu đề `"Cài đặt nhóm"` căn giữa kèm nút icon `'X'` đóng modal.
- **Section 1: Thông tin nhóm**:
  - Avatar Monogram 2 chữ cái, Tên nhóm, Tiền tệ VND, Ngày tạo và Tên Captain.
  - Nút `[ Đổi tên ]` (Chỉ hiển thị cho Captain, gọi `PATCH /api/v1/groups/{id}`).
- **Section 2: Quản trị thành viên & Vai trò**:
  - Nút `[ Chuyển Trưởng nhóm ]`: Mở popup chọn thành viên mới $\rightarrow$ gọi `PUT /members/{memberId}/role`.
  - Danh sách thành viên: Hiển thị avatar, tên, huy hiệu vai trò và nút `[ Xóa ]` (Chỉ Captain thấy).
- **Section 3: Vùng nguy hiểm (Danger Zone)**:
  - Nút `[ Rời nhóm ]`: Kiểm tra số dư nợ `currentUserNetBalance == 0` và vai trò `!isCaptain` trước khi cho phép rời (`DELETE /members/{memberId}`). Nếu còn nợ, hiển thị dialog cảnh báo nợ dở dang.
  - Nút `[ Giải tán nhóm ]` (Chỉ Captain): Xác nhận giải tán toàn bộ nhóm khi sạch 100% công nợ (`DELETE /groups/{id}`).

---

## 5. Data Flow & API Contracts Mapping

### 5.1. Danh Sách Endpoint Backend Sử Dụng

| Endpoint BE | Method | Mục đích trên Group Hub | Companion BE Spec |
| :--- | :--- | :--- | :--- |
| `/api/v1/groups/{id}` | `GET` | Lấy chi tiết nhóm, vai trò caller, danh sách thành viên active và mảng `balances[]`. | `0002-group-management-v1` AC-2 |
| `/api/v1/groups/{id}/debts` | `GET` | Lấy danh sách nợ nội bộ nhóm, `caller_payable`, `caller_receivable`, và `net_matrix`. | `0004-split-settlement-v1` AC-2 |
| `/api/v1/groups/{id}/bills` | `GET` | Lấy danh sách hóa đơn theo phân trang cursor và lọc theo trạng thái (`status`). | `0003-bill-ocr-v1` AC-8, AC-12 |
| `/api/v1/groups/{id}/activities` | `GET` | Lấy dòng thời gian hoạt động của nhóm theo cursor pagination. | `0002-group-management-v1` AC-8 |
| `/api/v1/groups/{id}/invites` | `GET` | Thành viên active lấy danh sách mã mời còn hiệu lực để hiển thị, copy và mở QR. **API cần bổ sung ở BE.** | `api-change-request-member-invites.md` |
| `/api/v1/groups/{id}/invites` | `POST` | Thành viên active tạo hoặc lấy lại mã mời theo mặc định. Captain có thể gửi cấu hình tái tạo. **Phân quyền cần đổi ở BE.** | `api-change-request-member-invites.md` |
| `/api/v1/groups/{id}/invites/{inviteId}` | `DELETE` | Captain thu hồi mã mời. | `0002-group-management-v1` AC-3 |
| `/api/v1/groups/{id}/members/{memberId}` | `DELETE` | Thành viên tự rời nhóm hoặc Captain xóa thành viên (chỉ khi sạch nợ). | `0002-group-management-v1` AC-6 |
| `/api/v1/groups/{id}/members/{memberId}/role` | `PUT` | Captain chuyển giao quyền Trưởng nhóm cho thành viên khác. | `0002-group-management-v1` AC-7 |
| `/api/v1/groups/{id}/payments/qr` | `POST` | Sinh mã VietQR động 1-chạm thanh toán nợ cho Chủ nợ trong nhóm. | `0004-split-settlement-v1` AC-3, AC-4 |
| `/api/v1/groups/{id}/payments/{paymentId}/confirm` | `POST` | Chủ nợ xác nhận đã nhận tiền, chốt sổ công nợ. | `0004-split-settlement-v1` AC-7 |
| `/api/v1/groups/{id}/payments/{paymentId}/reject` | `POST` | Chủ nợ từ chối bằng chứng chuyển khoản kèm lý do. | `0004-split-settlement-v1` AC-8 |
| `/api/v1/groups/{id}/debts/{debtId}/remind` | `POST` | Gửi thông báo nhắc nợ (rate limit 1 lần/24h). | `0004-split-settlement-v1` AC-9 |

### 5.2. Chiến Lược Nạp Dữ Liệu Theo Vùng (Independent Data Loading)

Khi người dùng mở màn hình Chi Tiết Nhóm, `GroupHubController` nạp độc lập từng vùng dữ liệu để lỗi ở một vùng không che các vùng còn lại:
1. `GET /groups/{id}`: Trả về thông tin nhóm + `members[]` + `balances[]`. Controller thực hiện ghép `balances[i].net_balance` vào từng `GroupMemberEntity.netBalance`.
2. `GET /groups/{id}/debts`: Lấy tổng `caller_payable`, `caller_receivable`, và tính `netBalance = totalReceivable - totalPayable`.
3. `GET /groups/{id}/bills`: Nạp trang hóa đơn đầu tiên.
4. `GET /groups/{id}/invites`: Nạp các mã mời còn hiệu lực.
5. `GET /groups/{id}/activities`: Nạp trang hoạt động đầu tiên.

---

## 6. Domain Entities & State Management (Riverpod)

### 6.1. Freezed Domain Entities

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_hub_entities.freezed.dart';

enum MemberRole { captain, member }
enum MemberStatus { active, inactive }
enum BillStatus { draft, finalized, voided }
enum OcrState { none, queued, processing, succeeded, failed }
enum DebtStatus { awaiting, pendingConfirmation, settled, voided }

@freezed
class GroupDetailEntity with _$GroupDetailEntity {
  const factory GroupDetailEntity({
    required String id,
    required String name,
    required String currency,
    required MemberRole callerRole,
    required int payableAmount,
    required int receivableAmount,
    required int netBalance,
    required List<GroupMemberEntity> activeMembers,
    required DateTime createdAt,
  }) = _GroupDetailEntity;
}

@freezed
class GroupMemberEntity with _$GroupMemberEntity {
  const factory GroupMemberEntity({
    required String id,
    required String userId,
    required String displayName,
    String? avatarUrl,
    required MemberRole role,
    required MemberStatus status,
    required int netBalance,
  }) = _GroupMemberEntity;
}

@freezed
class GroupBillSummaryEntity with _$GroupBillSummaryEntity {
  const factory GroupBillSummaryEntity({
    required String id,
    required String merchantName,
    required DateTime billDate, // fallback = createdAt / ocrProcessedAt nếu receipt date không rõ
    required int totalAmount,
    required int callerShareAmount,
    required BillStatus status,
    required OcrState ocrState,
    required String creditorMemberId,
    required String creditorName,
    required int imageCount,
    required int settledMemberCount,
    required int totalMemberCount,
    String? voidReason,
  }) = _GroupBillSummaryEntity;
}

@freezed
class GroupDebtEntity with _$GroupDebtEntity {
  const factory GroupDebtEntity({
    required String id,
    required String billId,
    required String billMerchantName,
    DateTime? billDate,
    required String debtorMemberId,
    required String debtorName,
    String? debtorAvatarUrl,
    required String creditorMemberId,
    required String creditorName,
    String? creditorAvatarUrl,
    required int amount,
    required DebtStatus status,
    required int reminderCount,
    String? paymentId,
    String? proofImageUrl,
    String? note, // Lời nhắn từ người nợ theo BE Spec 0004 AC-6
    DateTime? settledAt,
  }) = _GroupDebtEntity;
}

@freezed
class GroupInviteEntity with _$GroupInviteEntity {
  const factory GroupInviteEntity({
    required String id,
    required String code,
    required String inviteUrl,
    required DateTime expiresAt,
    int? maxUses, // Nullable nếu không giới hạn lượt dùng
    required int useCount,
  }) = _GroupInviteEntity;
}

@freezed
class GroupActivityEntity with _$GroupActivityEntity {
  const factory GroupActivityEntity({
    required String id,
    required String actionType,
    required String description,
    required String actorMemberId,
    required String actorDisplayName,
    String? actorAvatarUrl,
    required Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _GroupActivityEntity;
}
```

---

### 6.2. Riverpod State & Controller Definition

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/group_hub_entities.dart';

part 'group_hub_controller.g.dart';

@freezed
class GroupHubState with _$GroupHubState {
  const factory GroupHubState({
    required AsyncValue<GroupDetailEntity> groupDetail,
    required AsyncValue<List<GroupBillSummaryEntity>> bills,
    required AsyncValue<List<GroupDebtEntity>> debts,
    required AsyncValue<List<GroupInviteEntity>> activeInvites,
    required AsyncValue<List<GroupActivityEntity>> activities,
    @Default(0) int selectedTabIndex,
    @Default('all') String billFilterStatus,
  }) = _GroupHubState;
}

@riverpod
class GroupHubController extends _$GroupHubController {
  @override
  GroupHubState build(String groupId) {
    _fetchGroupData(groupId);
    return const GroupHubState(
      groupDetail: AsyncValue.loading(),
      bills: AsyncValue.loading(),
      debts: AsyncValue.loading(),
      activeInvites: AsyncValue.loading(),
      activities: AsyncValue.loading(),
    );
  }

  Future<void> _fetchGroupData(String groupId) async {
    // 1. Fetch Group Details, Members & Balances
    state = state.copyWith(groupDetail: const AsyncValue.loading());
    final detailResult = await ref.read(getGroupDetailUseCaseProvider).call(groupId);
    state = state.copyWith(groupDetail: detailResult.toAsyncValue());

    // 2. Fetch Group Bills
    state = state.copyWith(bills: const AsyncValue.loading());
    final billsResult = await ref.read(getGroupBillsUseCaseProvider).call(groupId);
    state = state.copyWith(bills: billsResult.toAsyncValue());

    // 3. Fetch Group Debts & Matrix
    state = state.copyWith(debts: const AsyncValue.loading());
    final debtsResult = await ref.read(getGroupDebtsUseCaseProvider).call(groupId);
    state = state.copyWith(debts: debtsResult.toAsyncValue());

    // 4. Fetch Group Activities
    state = state.copyWith(activeInvites: const AsyncValue.loading());
    final invitesResult = await ref.read(getGroupInvitesUseCaseProvider).call(groupId);
    state = state.copyWith(activeInvites: invitesResult.toAsyncValue());

    // 5. Fetch Group Activities
    state = state.copyWith(activities: const AsyncValue.loading());
    final activitiesResult = await ref.read(getGroupActivitiesUseCaseProvider).call(groupId);
    state = state.copyWith(activities: activitiesResult.toAsyncValue());
  }

  void setTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void setBillFilter(String filter) {
    state = state.copyWith(billFilterStatus: filter);
  }

  Future<void> refresh() async {
    final currentGroupId = state.groupDetail.value?.id;
    if (currentGroupId != null) {
      await _fetchGroupData(currentGroupId);
    }
  }
}
```

---

## 7. Build Plan & Implementation Slices

### Slice 1: Domain Entities, Data Sources & Repositories
- [ ] Define Freezed Entities (`GroupDetailEntity`, `GroupBillSummaryEntity`, `GroupDebtEntity`, `GroupInviteEntity`, `GroupActivityEntity`).
- [ ] Implement Retrofit DataSource for Group Hub endpoints (`GET /groups/{id}`, `GET /groups/{id}/bills`, `GET /groups/{id}/debts`, `GET /groups/{id}/invites`, `POST /groups/{id}/invites`, `GET /groups/{id}/activities`).
- [ ] Implement Repository & UseCases with comprehensive Unit Tests.

### Slice 2: Group Header, Net Balance Banner & FTabs Navigation
- [ ] Implement `GroupHeaderWidget` with Back button, Monogram Avatar, Name, Member count, and Settings icon.
- [ ] Implement `GroupBalanceBannerWidget` with 3 color states (+, -, 0đ).
- [ ] Setup `FTabs` navigation with smooth swipe and state persistence.

### Slice 3: Tab 1 (Bills Feed & Receipt Card)
- [ ] Build `BillReceiptCardWidget` with Forui status badges, payer avatar, mono financials, OCR status shimmer, and progress bar.
- [ ] Implement Filter Chip row (`Tất cả`, `Đang xử lý`, `Đã chốt`, `Đã hủy`).
- [ ] Add empty state graphic when group has no bills.
- [ ] Wire FAB button to Open Bill Creation / OCR Camera vs Manual Entry Form.

### Slice 4: Tab 2 (Debts Matrix & Quick VietQR)
- [ ] Implement Personal Debts list (Payable with `[ Trả QR ⚡ ]`, Receivable with `[ Duyệt proof ]` kèm `payments.note` và `[ 🔔 Nhắc nợ ]`).
- [ ] Implement Full Group Debt Matrix breakdown.
- [ ] Wire VietQR Bottom Sheet and Proof Review Bottom Sheet.

### Slice 5: Tab 3 (Members & Invites), Governance & Tab 4 (Activity Stream)
- [ ] Implement Member list with Captain Crown and Net Balance per member.
- [ ] Implement `InviteCodeBottomSheet` (`showModalBottomSheet` with `StatefulBuilder`, copy & revoke actions, 100% width create button).
- [ ] Implement `GroupSettingsBottomSheet` (Thông tin nhóm + Đổi tên, Quản trị thành viên + Chuyển Trưởng nhóm + Xóa thành viên, Vùng nguy hiểm Rời nhóm với kiểm tra nợ + Giải tán nhóm cho Captain).
- [ ] Implement Activity Timeline with Cursor Pagination.

---

## 8. Verification & Quality Checklist

1. **Visual & Token Audit**:
   - [ ] Nền trang đạt chuẩn Warm Olive `#F5F6F1`.
   - [ ] Thẻ `FCard` nền trắng viền `1px solid #DBE0CE`, bo góc `10px`.
   - [ ] Tiêu đề dùng `Newsreader`, nội dung `Roboto Slab`, số tiền `JetBrains Mono`.
   - [ ] Dùng Monogram Avatar chữ hoa thay cho Emoji.
2. **Acceptance Criteria Verification**:
   - [ ] AC-UI-1 đến AC-UI-8 được đáp ứng 100%.
   - [ ] Rời nhóm khi còn nợ hiển thị thông báo lỗi `409` rõ ràng và hướng dẫn tất toán.
   - [ ] Captain chuyển giao quyền thành công trước khi rời nhóm.
   - [ ] Duyệt proof hiển thị đầy đủ hình ảnh và lời nhắn từ người nợ (`payments.note`).
3. **8-State Coverage**:
   - [ ] Toàn bộ nút bấm, thẻ bill và tab có đủ 8 trạng thái (Default, Hover/Pressed, Focus, Active, Disabled, Loading, Error, Success).
