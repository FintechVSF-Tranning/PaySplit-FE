# 🎨 PaySplit Mobile App UI/UX Context & Design System

> **Style Reference**: Modern FinTech / Neo-Bank (Revolut, Monzo, Wise, Timo-inspired) với Fluid Organic Top Waves, Subtle Gradients, Micro-animations và Elevated Soft Cards  
> **UI Framework**: Flutter 3.x + Material 3 Custom Component Architecture (Riverpod State Management, GoRouter, Freezed, Custom Wave Painters & Floating Input Cards)  
> **Typography**: `Plus Jakarta Sans` (Tiêu đề, nội dung & nhãn giao diện chuẩn FinTech hiện đại) + `JetBrains Mono` (Dữ liệu số tài chính, mã OTP, số tài khoản VietQR)  
> **Icon Library**: `Hugeicons` (`hugeicons: ^0.0.8` nét Stroke 1.5px / 2.0px hiện đại)  
> **Color Atmosphere**: Neo-Bank Paper (`#F8FAF9` / `#FFFFFF`), Deep Teal Gradient (`#0F766E` → `#115E59` → `#042F2E`), Emerald Green (`#10B981`), Amber Orange (`#F59E0B`), Obsidian Dark (`#0B1120` / `#0F172A`)  
> **Corner Radius**: Smooth Modern Curves (`12px – 20px` cho Card, `14px – 16px` cho Input, `24px` cho Bottom Sheet, `9999px` cho Pill Actions)  
> **Target Platforms**: iOS & Android (Cross-platform Mobile-First)

---

## 1. Triết lý Thiết kế (Design Philosophy)

PaySplit theo đuổi phong cách **Modern FinTech / Neo-Bank**:
1. **Hiện đại, Tươi mới & Chuẩn FinTech (Modern Neo-Bank Aesthetics)**: Lấy cảm hứng từ các ứng dụng ngân hàng số thế hệ mới (Revolut, Monzo, Wise, Timo). Giao diện trẻ trung, tinh tế, sử dụng nền sáng sạch sẽ (`#F8FAF9` / `#FFFFFF`), tạo điểm nhấn bằng dải chuyển màu **Deep Teal Gradient** (`#0F766E` → `#115E59` → `#042F2E`) cùng các đường lượn sóng Organic Wave mềm mại ở header.
2. **Cấu trúc Thẻ Nổi & Đổ bóng Mềm (Elevated Soft Cards & Layering)**: Sử dụng các khối thẻ bo góc mềm mại (`12px – 20px`), kết hợp viền mỏng tinh tế (`#E2E8F0` / `#E5E7EB`) và hiệu ứng đổ bóng mờ nhẹ (`blurRadius: 10px`, độ mờ `alpha: 0.02 – 0.04`), giúp phân tầng thị giác rõ ràng, hiện đại và không bị nặng nề.
3. **Hệ thống Nhận diện Typography & Iconography Đồng nhất (Clean & Technical Harmony)**:
   - **`Plus Jakarta Sans`**: Kiểu chữ Sans-Serif hình học hiện đại, sắc nét, tối ưu trải nghiệm đọc trên thiết bị di động cho toàn bộ Tiêu đề (Headings), Nội dung (Body), Nhãn Form và Nút bấm.
   - **`JetBrains Mono`**: Kiểu chữ đơn cách (Monospace) cao cấp dành riêng cho các con số tài chính, số dư tài khoản, số tiền hóa đơn, mã OTP 6 số và số tài khoản ngân hàng VietQR NAPAS 247.
   - **`Hugeicons`**: Bộ icon vector chuẩn stroke 1.5px / 2.0px thanh mảnh, hiện đại, mang lại vẻ ngoài cao cấp và nhất quán trên toàn bộ ứng dụng.
4. **Tương tác Phản hồi Trực quan & Vi mô (Micro-interactions & Tactile Feedback)**:
   - Tích hợp **Haptic Feedback** (rung nhẹ khi chạm nút, chọn tab, xác nhận thanh toán).
   - Hiệu ứng **Press-Scale Micro-animation** (thu nhỏ nhẹ 0.97x khi chạm vào nút `AppButton` hoặc thẻ tương tác).
   - Hiệu ứng chuyển động mượt mà với `flutter_animate` (Fade In, Slide Y, Scale) khi chuyển trang hoặc hiển thị kết quả OCR.
   - Kỷ luật 8 trạng thái trực quan (8-state discipline): Default, Hover/Focus, Active/Pressed, Loading, Success, Warning, Error, Disabled.

---

## 2. Hệ Thống Design Tokens (Tokens & Theme Specification)

### 2.1. Bảng màu (Color Palette)

Hệ thống màu sắc hỗ trợ đầy đủ 2 chế độ **Light Mode (Clean Neo-Bank)** và **Dark Mode (Obsidian Slate)** theo lớp `AppColors`:

#### Bảng màu Light Mode (Mặc định)

| Token Name | Hex Code | Ý nghĩa / Vị trí sử dụng |
| :--- | :--- | :--- |
| `paper` / `background` | `#F8FAF9` / `#FFFFFF` | Nền chính toàn màn hình (Clean Soft Paper) |
| `surface` | `#FFFFFF` | Nền thẻ Card nổi, Bottom Sheet, Dialog, Floating Input |
| `surfaceSubtle` | `#F9FAFB` | Nền phụ, hàng chẵn lẻ, danh sách item hover |
| `surfaceMuted` | `#F3F4F6` | Nền badge nhạt, search input box |
| `border` | `#E2E8F0` / `#E5E7EB` | Viền 1px mỏng cho thẻ card & input field |
| `borderStrong` | `#CBD5E1` / `#D1D5DB` | Viền active, divider phân chia section |
| `borderFocus` | `#0F766E` | Viền khi input đang được focus (Teal 700) |
| `textMain` / `textPrimary` | `#0F172A` / `#1C2118` | Chữ chính, tiêu đề, họ tên, số tiền tổng |
| `textMuted` / `textSecondary` | `#64748B` / `#676E5F` | Chữ phụ, thời gian, chú thích, placeholder |
| `primary` | `#0F766E` | Màu thương hiệu chủ đạo (Deep Teal 700) cho CTA chính, toggle, brand mark |
| `primaryHover` / `primaryActive` | `#115E59` / `#134E4A` | Trạng thái nhấn giữ/hover của nút primary |
| `primarySubtle` | `#F0FDFA` | Nền nhạt (Teal 50) cho selection active |
| `primaryGradient` | `#0F766E` → `#115E59` | Dải màu gradient chủ đạo cho Hero Card, Nút CTA Gradient |
| `success` | `#10B981` | Đã thanh toán (Settled), số dư dương (+), xác nhận thành công |
| `warning` | `#F59E0B` | Đang chờ duyệt (Pending proof), đang quét OCR, chú ý |
| `danger` / `error` | `#EF4444` | Đang nợ cần trả (-), từ chối thanh toán, lỗi form |
| `info` | `#3B82F6` | Thông tin hướng dẫn, liên kết |
| `balancePositiveBg` / `Text` | `#ECFDF5` / `#059669` | Nền và chữ số dư dương (Emerald 50/600) |
| `balanceNegativeBg` / `Text` | `#FEF2F2` / `#DC2626` | Nền và chữ số dư âm (Red 50/600) |

#### Bảng màu Dark Mode

| Token Name | Hex Code | Ý nghĩa / Vị trí sử dụng |
| :--- | :--- | :--- |
| `darkPaper` / `darkBackground` | `#0B1120` / `#121512` | Nền chính chế độ tối (Obsidian Slate) |
| `darkSurface` | `#1E293B` / `#1B2019` | Nền thẻ Card, Input, Modal trong Dark Mode |
| `darkSurfaceSubtle` | `#0F766E` (alpha) / `#0F172A` | Nền phụ, container lồng trong thẻ |
| `darkBorder` | `#334155` / `#2D3528` | Viền thẻ và ô nhập liệu Dark Mode |
| `darkTextMain` | `#F1F5F9` / `#E8EDE4` | Chữ chính Dark Mode sắc nét |
| `darkTextMuted` | `#94A3B8` / `#A2ABA0` | Chữ phụ, placeholder Dark Mode |
| `darkPrimary` | `#14B8A6` | Màu Teal sáng (Teal 500) nổi bật trên nền tối |

---

### 2.2. Hệ thống Typography (`Plus Jakarta Sans` x `JetBrains Mono`)

- **Kiểu chữ giao diện chính (`Plus Jakarta Sans`)**: Được sử dụng cho toàn bộ Brand Wordmark, Tiêu đề trang, Nhãn Form, Nút bấm và Văn bản hiển thị, tạo cảm giác hình học hiện đại, mượt mà chuẩn FinTech.
- **Kiểu chữ số liệu tài chính (`JetBrains Mono`)**: Được sử dụng cho Số dư tài khoản, Số tiền hóa đơn, Mã PIN OTP 6 số, Số tài khoản ngân hàng VietQR NAPAS 247 để đảm bảo độ thẳng hàng tuyệt đối của các con số.

```text
Display 1 (Số dư Hero)        : JetBrains Mono Bold 700 / 30px–32px / tracking -0.5px
Title Large (Tiêu đề trang)   : Plus Jakarta Sans ExtraBold 800 / 26px–28px / tracking -0.3px
Title Medium (Tiêu đề thẻ)    : Plus Jakarta Sans Bold 700 / 17px–18px
Heading (Tiêu đề mục con)     : Plus Jakarta Sans SemiBold 600 / 15px–16px
Body (Nội dung chính)         : Plus Jakarta Sans Regular/Medium 400-500 / 14px / height 1.45
Body Small (Dòng phụ/Ghi chú) : Plus Jakarta Sans Regular/Medium 400-500 / 12px–13px
Label / Button CTA            : Plus Jakarta Sans Bold 700 / 14.5px–15px / tracking +0.2px
Financial Mono (STK / OTP)    : JetBrains Mono SemiBold/Bold 600-700 / 14.5px–18px
```

---

### 2.3. Quy chuẩn Icon (`Hugeicons`)

- **Bộ icon thư viện**: `Hugeicons` (`hugeicons: ^0.0.8`) chế độ Stroke Rounded 1.5px / 2.0px.
- **Kích thước tiêu chuẩn**:
  - `14px – 16px`: Icon phụ cạnh chữ, tick checklist, icon trong badge/tag.
  - `18px – 20px`: Icon trong ô `FloatingInputCard`, Action buttons, List item prefix/suffix.
  - `22px – 24px`: Icon thanh điều hướng (`AppBottomNavBar`), Header Action buttons, Back arrow.
  - `28px – 32px`: Icon thẻ Hero container, QR scanner icon lớn, biểu tượng trạng thái modal.

#### Danh sách ánh xạ Icon chức năng chính:
- **Điều hướng & Trang chủ**: `HugeIcons.strokeRoundedHome01`, `HugeIcons.strokeRoundedUserGroup`, `HugeIcons.strokeRoundedInvoice01`, `HugeIcons.strokeRoundedSettings01`, `HugeIcons.strokeRoundedArrowLeft01`, `HugeIcons.strokeRoundedArrowRight01`.
- **Hóa đơn, OCR & Chia tiền**: `HugeIcons.strokeRoundedInvoice01`, `HugeIcons.strokeRoundedInvoice02`, `HugeIcons.strokeRoundedReceiptDollar`, `HugeIcons.strokeRoundedCamera01`, `HugeIcons.strokeRoundedCalculate`, `HugeIcons.strokeRoundedSplitHorizontal`.
- **Thanh toán & VietQR**: `HugeIcons.strokeRoundedQrCode`, `HugeIcons.strokeRoundedWallet01`, `HugeIcons.strokeRoundedCheckmarkCircle02`, `HugeIcons.strokeRoundedAlertCircle`.
- **Form Xác thực & Bảo mật**: `HugeIcons.strokeRoundedMail01`, `HugeIcons.strokeRoundedMailAtSign01`, `HugeIcons.strokeRoundedLockPassword`, `HugeIcons.strokeRoundedUser`, `HugeIcons.strokeRoundedCall`, `HugeIcons.strokeRoundedDialpadCircle01`, `HugeIcons.strokeRoundedView`, `HugeIcons.strokeRoundedViewOffSlash`.
- **Thông báo & Thao tác**: `HugeIcons.strokeRoundedNotification01`, `HugeIcons.strokeRoundedNotification03`, `HugeIcons.strokeRoundedReload`, `HugeIcons.strokeRoundedLogout01`, `HugeIcons.strokeRoundedSearch01`, `HugeIcons.strokeRoundedCancel01`.

---

### 2.4. Bo góc, Đổ bóng & Khoảng cách (Radius, Shadows & Spacing)

- **Thang Bo góc (Corner Radius Scale)**:
  - `Radius Small (6px – 8px)`: Badge, Tag trạng thái, Checkbox.
  - `Radius Medium (12px – 14px)`: Ô nhập liệu `FloatingInputCard`, Item danh sách con.
  - `Radius Large (18px – 20px)`: Thẻ chứa `NetBalanceHeroCard`, Thẻ nhóm, Khung Form Card.
  - `Radius Modal (24px)`: Bottom Sheet, Dialog xác nhận.
  - `Radius Full (9999px)`: Nút bấm `AppButton`, Action Pill, Floating Chip, Avatar.
- **Hệ thống Đổ bóng (Soft Elevation Shadows)**:
  - `Shadow Card`: `BoxShadow(color: Colors.black.withValues(alpha: 0.02 - 0.04), blurRadius: 10, offset: Offset(0, 4))`
  - `Shadow Gradient Hero`: `BoxShadow(color: Color(0xFF0F766E).withValues(alpha: 0.25 - 0.3), blurRadius: 18, offset: Offset(0, 8))`
- **Khoảng cách (Spacing Scale 4-pt/8-pt)**:
  - `4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`.
  - Lề ngang toàn màn hình (Horizontal Page Padding): `padding: EdgeInsets.symmetric(horizontal: 16px - 20px)`.

---

## 3. Bản Đồ Ánh Xạ UI Component Architecture (Flutter Custom Component Suite)

Ứng dụng sử dụng hệ thống component Material 3 Custom tinh gọn, hiện đại và chuẩn hóa theo kiến trúc Clean Architecture:

| Thành phần UI | Tên Widget & Vị trí | Mô tả cấu hình, Biến thể & Hành vi |
| :--- | :--- | :--- |
| **Nút bấm tương tác** | [`AppButton`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/core/widgets/app_button.dart) | Nút chuẩn hệ thống: Haptic Feedback + Press Scale `0.97x`. Các biến thể: `.primary` (Teal), `.gradient` (Hero CTA), `.outline`, `.ghost`, `.danger`. Tích hợp `isLoading`, `icon`, `trailingIcon`. |
| **Thẻ nhập liệu Form** | [`FloatingInputCard`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/core/widgets/floating_input_card.dart) | Card nhập liệu nổi Neo-Bank: Nhãn label nhỏ bên trên, Text input lớn, Prefix Icon Hugeicons, Focus teal border, Error message animated. Hỗ trợ password toggle, OTP formatters. |
| **Thẻ Số Dư Ròng Hero** | [`NetBalanceHeroCard`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/features/home/presentation/widgets/net_balance_hero_card.dart) | Thẻ trung tâm nổi bật, số tiền `JetBrains Mono 30px`, 3 trạng thái màu (dương xanh, âm đỏ, cân bằng), tích hợp Quick Action Bar (Trả QR, Quét bill OCR, Tạo nhóm). |
| **Dải sóng Header nghệ thuật** | [`FluidTopWave`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/core/widgets/fluid_top_wave.dart) | Custom Painter vẽ dải sóng organic wave màu Teal Gradient ở góc trên các màn hình Auth (Login, Register, Forgot Password, Reset Password, Profile). |
| **Checklist Mật khẩu Live** | [`PasswordChecklist`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/core/widgets/password_checklist.dart) | Danh sách kiểm tra trực tiếp độ mạnh mật khẩu thời gian thực với icon tick xanh `HugeIcons.strokeRoundedTick01`. |
| **Thanh Điều Hướng Đáy** | [`AppBottomNavBar`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/features/home/presentation/widgets/app_bottom_nav_bar.dart) | Thanh Bottom Nav bo góc nổi `24px` với 4 tab (Tổng quan, Nhóm, Hóa đơn, Cài đặt) dùng icon `Hugeicons` stroke 1.5px/2.0px. |
| **Huy hiệu trạng thái / Pill** | `Container (Pill / Badge)` | Bo tròn `9999px` hoặc `6px – 8px`. Phối màu ngữ cảnh tài chính: Success (`#ECFDF5`/`#059669`), Warning (`#FFFBEB`/`#B45309`), Danger (`#FEF2F2`/`#DC2626`). |
| **Modal / Bottom Sheet** | `showModalBottomSheet` | Bo góc trên `24px`, thanh kéo Drag Handle (`40x4px`), Header tiêu đề kèm nút đóng `HugeIcons.strokeRoundedCancel01`, animation trượt mượt mà. |
| **Avatar người dùng** | `CircleAvatar` + `CachedNetworkImage` | Hình tròn viền `1.5px – 2.0px` trắng/teal, icon camera overlay khi tải ảnh đại diện lên Cloudinary. |
| **Thông báo phản hồi nhanh** | [`ui_feedback.dart`](file:///home/vsf-tinnt32-u/Documents/code/PaySplit-FE/lib/core/utils/ui_feedback.dart) | Bộ SnackBar phản hồi người dùng: `showSuccessSnackBar` (xanh), `showErrorSnackBar` (đỏ), `showComingSoonSnackBar`. |

---

## 4. Đặc Tả Chi Tiết 5 Màn Hình Cốt Lõi (Screen Specifications)

```text
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  [1. HOME]      [2. GROUP HUB]   [3. OCR SPLIT]   [4. VIETQR]   │
│  Dashboard      Summary/Bills    Receipt Parsing  Settlement    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Màn hình 1: Trang Chủ & Tổng Quan Số Dư (Home & Group Dashboard)

> **Spec chi tiết**: [`PaySplit-FE/docs/specs/0002-home-balance-ui-v1.md`](PaySplit-FE/docs/specs/0002-home-balance-ui-v1.md)

* **Mục tiêu**: Người dùng nắm ngay tức thì số tiền đang nợ / cần thu và danh sách các nhóm chi tiêu chỉ trong **2 giây đầu tiên**.
* **Bố cục giao diện**:
  1. **Top Header Bar**:
     - Avatar tròn `40px` viền `1.5px solid #E2E8F0` (trái, bấm vào mở Profile/Settings & STK VietQR) + Lời chào: *"Xin chào,"* (`Plus Jakarta Sans Regular 13px, #64748B`), Tên người dùng (`Plus Jakarta Sans Bold 17px, #0F172A`).
     - Action Icons (phải): Chuông thông báo (`HugeIcons.strokeRoundedNotification01` 20px, badge đỏ unread) + Nút Quét bill (`HugeIcons.strokeRoundedCamera01` 18px + *"Quét bill"*).
  2. **Thẻ Số Dư Ròng Trung Tâm (Net Balance Hero Card - `NetBalanceHeroCard`)**:
     - Thẻ bo góc `18px – 20px`, viền `1px solid #E2E8F0`, đổ bóng mềm `blurRadius: 10px`.
     - Số dư ròng (`JetBrains Mono Bold 30px–32px`) với 3 trạng thái màu:
       - **Dương (+)**: Nền `#ECFDF5`, chữ `#059669` (Emerald 600), badge Pill *"Bạn được nhận"*.
       - **Âm (-)**: Nền `#FEF2F2`, chữ `#DC2626` (Red 600), badge Pill *"Bạn cần trả"*.
       - **Bằng 0**: Nền `#F8FAF9`, chữ `#0F172A`, badge Pill *"Đã cân bằng"*.
     - Dải chi tiết 2 chiều: `Đang cho nợ: +X đ` (xanh `#059669`) | `Đang nợ: -X đ` (đỏ `#DC2626`).
     - Quick Action Bar 3 nút dạng Pill: `⚡ Trả nợ VietQR` (`HugeIcons.strokeRoundedQrCode`) | `📸 Quét bill OCR` (`HugeIcons.strokeRoundedCamera01`) | `👥 Tạo nhóm` (`HugeIcons.strokeRoundedUserGroup`).
  3. **Danh Sách Nợ Cần Xử Lý (Actionable Debts Widget)**:
     - Tab lọc Segmented Pill: `Cần trả (X)` | `Cần thu (Y)`.
     - Mỗi dòng: Avatar tròn + Tên đối tác + Tên nhóm + Số tiền (`JetBrains Mono Bold 14px`) + Nút hành động `AppButton` (`[ Trả QR ⚡ ]` / `[ Duyệt proof ]` / `[ 🔔 Nhắc nợ ]` dùng `HugeIcons.strokeRoundedQrCode`, `strokeRoundedInvoice02`, `strokeRoundedNotification03`).
     - `[ Duyệt proof ]`: Mở Bottom Sheet xem ảnh biên lai ngân hàng điện tử chi tiết (mã FT, STK nguồn, STK nhận, thời gian, số tiền, lời nhắn từ người nợ theo `payments.note` và 1 nút tick xác nhận).
  4. **Carousel Nhóm Của Tôi (Horizontal Groups Carousel)**:
     - Tiêu đề: `Nhóm của tôi` (`Plus Jakarta Sans Bold 17px`) + `Xem tất cả`.
     - Thẻ nhóm `180x115px` bo góc `16px`, viền `1px solid #E2E8F0`, trượt ngang: Emoji + Tên nhóm + Số TV + Số dư riêng trong nhóm.
     - Thẻ cuối `+ Tạo nhóm mới` (viền nét đứt `1px #CBD5E1`, icon `HugeIcons.strokeRoundedAdd01`).
  5. **Dòng Hoạt Động Gần Đây (Recent Activity Timeline)**:
     - Tiêu đề: `Hoạt động gần đây` (`Plus Jakarta Sans Bold 17px`).
     - Danh sách sự kiện: Icon thể loại + Mô tả tự nhiên (`Plus Jakarta Sans 13.5px`) + Thời gian tương đối.
  6. **Zero-State Onboarding & Tham Gia Nhóm**:
     - Khi chưa có nhóm: Card hướng dẫn 3 bước + nút `+ Tạo nhóm đầu tiên` và `Nhập mã mời nhóm` (Mở sheet 2 bước: Nhập code 6-8 ký tự $\rightarrow$ Preview nhóm $\rightarrow$ Xác nhận tham gia).
  7. **Bottom Navigation Dock (4 Tab - `AppBottomNavBar`)**:
     - `🏠 Tổng quan` (`strokeRoundedHome01`) | `👥 Nhóm` (`strokeRoundedUserGroup`) | `🧾 Hóa đơn` (`strokeRoundedInvoice01`) | `⚙️ Cài đặt` (`strokeRoundedSettings01`) — Nền trắng, bo góc trên `20px – 24px`, viền trên `1px solid #E2E8F0`.

---

### Màn hình 2: Chi Tiết Nhóm & Lịch Sử Hóa Đơn (Group Hub)

* **Mục tiêu**: Xem tình trạng nhóm, mã mời, thành viên và các hóa đơn đang xử lý.
* **Bố cục giao diện**:
  1. **Group Header Bar**:
     - Monogram Avatar nhóm, Tên nhóm (`Plus Jakarta Sans Bold 18px`), Huy hiệu Captain (nếu là Trưởng nhóm), nút Back (`HugeIcons.strokeRoundedArrowLeft01`), nút Cài đặt nhóm (`HugeIcons.strokeRoundedSettings01` mở `GroupSettingsBottomSheet`).
     - **Invite Code Chip**: `Mã: DALAT2026` + Icon copy 1 chạm (`HugeIcons.strokeRoundedCopy01`).
  2. **Thanh Tab Phân Loại (Segmented Pill Tabs)**:
     - `[ Hóa đơn (3) ]` | `[ Bảng công nợ ]` | `[ Thành viên (5) ]` | `[ Hoạt động ]`.
     - Trong Tab Thành viên: Nút `[ + Thêm thành viên ]` mở `InviteCodeBottomSheet` để quản lý, sao chép và thu hồi mã mời.
  3. **Danh sách Hóa đơn (`Bill Feed`)**:
     - Thẻ Hóa đơn thiết kế như **Vé/Receipt Card** bo góc `16px`, viền mỏng `#E2E8F0`:
       - Icon hóa đơn (`HugeIcons.strokeRoundedInvoice01`) + Tên hóa đơn (*"Lẩu gà lá é Tao Ngộ"*).
       - Người trả trước: Avatar + *"Nam đã trả trước 850.000 đ"*.
       - Trạng thái Pill Badge:
         - `Đang quét OCR` (Màu hổ phách `#F59E0B`).
         - `Chờ phân bổ món` (Màu xanh dương `#3B82F6`).
         - `Đã chốt sổ` (Màu xám `#64748B`).
       - Tỷ lệ hoàn thành thanh toán: Progress bar mỏng 3px (`3/5 người đã trả`).

---

### Màn hình 3: Chi Tiết OCR Hóa Đơn & Gán Món Ăn (Smart OCR & Item Assignment)
*(Màn hình tương tác trọng tâm của ứng dụng)*

* **Mục tiêu**: Người dùng kiểm tra các món máy quét bóc tách được, chỉnh sửa món khi cần, gán người ăn và đối soát chính xác con số sai lệch.
* **Bố cục giao diện**:
  1. **Receipt Header Card**:
     - Thẻ bo góc `18px`, viền `1px solid #E2E8F0`:
     - Tên quán (`Plus Jakarta Sans Bold 17px`), ngày giờ quét, ảnh hóa đơn thu nhỏ (bấm vào xem ảnh gốc full-screen kèm tính năng xoay ảnh 90° và zoom).
     - Tổng tiền hóa đơn: `1.240.000 đ` (`JetBrains Mono Bold 22px`).
  2. **Banner Duyệt & Chỉnh Sửa OCR Candidate (`OCRCandidateReviewCard`)**:
     - Hiển thị kết quả trích xuất của AI LlamaExtract sau khi đã qua **Tiền xử lý Khuyến mãi món (Item Discount Normalizer)**.
     - Dòng có chữ `"KM"` hoặc `line_total < 0` được gộp dồn vào `discount_amount` của món đứng ngay trước đó và tính `final_price = line_total - discount_amount`. Dòng "KM" rác bị loại bỏ khỏi danh sách.
     - Cho phép kiểm tra và chỉnh sửa trực tiếp các món (Tên, Số lượng, Đơn giá, Giá gốc `line_total`, Giảm giá món `discount_amount`, Giá thực `final_price`) trước khi bấm `[ Áp dụng vào bản nháp ]`.
  3. **Chế độ chia (Segmented Toggle)**:
     - `[ Chia theo từng món ]`  |  `[ Chia đều cả bàn ]`
  4. **Quản Lý & Phân Bổ Món Ăn (Line Items Management & Smart Multi-Member Avatar Bar)**:
     Mỗi món là một khối card con bo góc `14px`, viền `#E2E8F0`:
     - Hàng 1: Tên món (`Plus Jakarta Sans SemiBold 14.5px`) + Số lượng (`x1`) + Giá gốc (`149.625 đ` - `JetBrains Mono`) + Badge KM (`[KM -64.125 đ]`) + Giá thực (`85.500 đ`) + Nút `[ ✏️ Sửa ]` (`HugeIcons.strokeRoundedEdit02`) và `[ 🗑️ Xóa ]` (`HugeIcons.strokeRoundedDelete02`).
     - Hàng 2: **Smart Avatar Assignment Bar**:
       - **Sắp xếp ưu tiên (Smart Sort)**: Tự động đưa những người **đang được gán món** lên đầu danh sách hiển thị.
       - **Hiển thị tối đa 4 avatar + badge `+N`**: Khi nhóm đông thành viên ($> 4$), hiển thị 4 avatar đầu và avatar thứ 5 là badge `+N` (bấm vào mở Modal Chỉnh sửa để chọn trong danh sách đầy đủ).
       - Khi bấm chọn avatar: Avatar sáng lên, có vòng viền đậm Deep Teal `#0F766E` + hiển thị số tiền mỗi người đã chọn gánh dựa trên **Giá thực `final_price`** (`42.750 đ / người` nếu chọn 2 người). Người ăn món hưởng trọn 100% ưu đãi của món đó.
     - **Modal Chỉnh Sửa Món**: Cho phép nhập `Giảm giá riêng món (VND)` (`discount_amount`), tự động cập nhật `final_price` và khu vực **"Người tham gia chia món này"** với danh sách tick chọn đầy đủ kèm nút `[ Chọn tất cả ]` / `[ Bỏ chọn ]`.
     - Nút `[ + Thêm món thủ công ]`: Mở modal thêm món mới phát sinh (`HugeIcons.strokeRoundedAdd01`).
  5. **Phụ phí, Thuế & Giảm giá (VAT / Service Charge / Discount Section)**:
     - Nút `[ ✏️ Chỉnh sửa ]` hoặc chạm vào thẻ mở Modal Chỉnh Sửa Phụ Phí & Khuyến Mãi (`EditAdjustmentsDialog`).
     - Tách biệt rõ 2 loại khuyến mãi:
       - `Tổng KM các món` (`total_item_discount = Σ item.discount_amount`): Đã trừ thẳng vào từng món tương ứng.
       - `KM Voucher chung hóa đơn` (`general_discount = max(0, payload.discount - total_item_discount)`): Được phân bổ tự động theo tỷ trọng % tiền món ăn thực tế của từng người (`user_net_item_subtotal / net_items_total`).
     - Cho phép sửa: Phí dịch vụ (`serviceCharge`), Thuế VAT (`vat`), Giảm giá Voucher chung (`generalDiscount`) kèm các chip tính nhanh (`0đ`, `5%`, `8%`, `10%`, `50k`).
  6. **Thanh Đối Soát & Hiển Thị Số Tiền Sai Lệch Cụ Thể (Mismatch & Exact Delta Display)**:
     - Icon tròn biểu thị trạng thái (Check xanh, Alert đỏ, Warning vàng) không kèm chữ dài dòng.
     - **Khớp 100% (Xanh Emerald `#10B981`)**: *"Tổng tính toán: 1.240.000 đ · Khớp 100% với hóa đơn"*.
     - **Lệch Thiếu (Đỏ Crimson `#EF4444`)**: *"⚠️ Tổng tính toán (1.190.000 đ) THIẾU 50.000 đ so với hóa đơn gốc (1.240.000 đ)"* kèm nút `[ + Bù phụ thu 50.000 đ ]` hoặc `[ Cập nhật Tổng bill ]`.
     - **Lệch Thừa (Amber `#F59E0B`)**: *"⚠️ Tổng tính toán (1.300.000 đ) DƯ 60.000 đ so với hóa đơn gốc (1.240.000 đ)"* kèm nút `[ Cập nhật Tổng bill ]` hoặc `[ Trừ vào Voucher ]`.
     - **Cảnh báo Món Chưa Gán (`ITEM_UNASSIGNED`)**: Viền cảnh báo quanh món chưa có ai gánh kèm thông báo.
  7. **Sticky Bottom Bar**:
     - Tóm tắt phần cá nhân: `Phần của bạn: 349.500 đ` (`JetBrains Mono Bold 16px`, cập nhật live) + Nút `[ Xem bảng phân bổ ▾ ]`.
     - Nút Thao tác: `AppButton` `[ Lưu nháp ]` (Outline) và `[ Xác nhận & Chốt hóa đơn ⚡ ]` (`AppButton.gradient` kèm `HugeIcons.strokeRoundedArrowRight01`).
---

### Màn hình 4: Danh Sách Nợ & Thanh Toán Dynamic VietQR (Settlement Hub)

* **Mục tiêu**: Gom nợ thông minh (Settlement algorithm) và thanh toán 1-chạm qua VietQR.
* **Bố cục giao diện**:
  1. **Debt Summary Matrix ("Ai nợ ai")**:
     - Nhóm nợ thông minh: Gom nhiều bill thành 1 khoản duy nhất giữa 2 người.
     - Ví dụ: `Bạn nợ Trần Lâm` $\rightarrow$ Số tiền: `340.000 đ` (`JetBrains Mono Bold 18px`).
  2. **Nút Hành động 1-Click Pay**:
     - Bấm `[ Thanh toán qua VietQR ]` $\rightarrow$ Mở **Dynamic VietQR Modal Sheet** (bo góc `24px`):
       - Ảnh mã QR chuẩn VietQR (NAPAS 247) tự động sinh số tiền chính xác `340.000 đ`.
       - Thông tin người nhận: Ngân hàng (Logo Vietcombank), Tên chủ tài khoản, Số tài khoản (`JetBrains Mono Bold 16px`).
       - Nội dung chuyển khoản tự động: `PAYSPLIT NHOM1 NAM TRA LAM`.
       - Nút phụ trợ `AppButton`: `[ Mở App Ngân hàng ]`, `[ Lưu ảnh QR ]`, `[ Sao chép STK ]`.
  3. **Quy trình nộp minh chứng (Submit Proof)**:
     - Sau khi chuyển khoản, bấm `[ Tải ảnh biên lai đã chuyển ]` (`HugeIcons.strokeRoundedCamera01`).
     - Trạng thái nợ đổi thành `Chờ chủ nợ xác nhận` kèm ảnh đính kèm.

---

### Màn hình 5: Đối Soát & Chốt Sổ Công Nợ (Proof Review & Final Settlement)

* **Mục tiêu**: Chủ nợ kiểm tra minh chứng và hoàn tất thanh toán.
* **Bố cục giao diện**:
  1. **Thẻ Chờ Duyệt (Pending Confirmation Card)**:
     - Thông báo: *"Trần Lâm vừa nộp minh chứng thanh toán 340.000 đ"* (`Plus Jakarta Sans SemiBold 14.5px`).
     - Ảnh chụp màn hình banking (nhấn để phóng to kiểm tra mã giao dịch).
  2. **Thao tác phê duyệt (`AppButton` Action Buttons)**:
     - Nút Xanh (`AppButton.primary` - `#10B981`): `[ ✓ Xác nhận đã nhận tiền ]` (`HugeIcons.strokeRoundedCheckmarkCircle02`) $\rightarrow$ Đổi nợ sang trạng thái `Settled`, phát hiệu ứng confetti/haptic feedback nhẹ.
     - Nút Đỏ (`AppButton.outline` - `#EF4444`): `[ ✕ Chưa nhận được tiền ]` (`HugeIcons.strokeRoundedCancel01`) $\rightarrow$ Mở dialog nhập lý do từ chối.

---

## 5. Quy Chuẩn Trạng Thái Tương Tác (8-State Discipline)

Mọi widget tương tác trong ứng dụng (Nút bấm `AppButton`, Ô nhập `FloatingInputCard`, Thẻ chọn món, Checklist...) bắt buộc phải tuân thủ và thể hiện rõ ràng 8 trạng thái tương tác sau:

| # | Trạng thái (State) | Biểu hiện Thị giác & Hành vi (Visual & Behavior) | Chi tiết Triển khai trong Code (`PaySplit-FE`) |
| :--- | :--- | :--- | :--- |
| **1** | **Default** *(Mặc định)* | Nền trắng `#FFFFFF` (Dark: `#1E293B`), viền mỏng 1.2px `#E2E8F0` (Dark: `#334155`), chữ chính `#0F172A`, placeholder `#64748B`. | Thuộc tính mặc định của widget khi không có tương tác. |
| **2** | **Hover / Pressed (Tap)** | Kích hoạt **Haptic Feedback** rung nhẹ (`HapticFeedback.lightImpact()`), co giãn **Scale Animation co lại `0.97x`** trong 100ms. | `_handleTapDown` / `_scaleAnimation` trong `AppButton`. |
| **3** | **Focus-visible** *(Đang trỏ)* | Viền chuyển sang màu thương hiệu **Deep Teal `#0F766E`** (độ dày 1.5px), icon prefix sáng màu Teal, bóng đổ mở rộng `blurRadius: 14px`. | Bắt sự kiện `Focus(onFocusChange: ...)` trong `FloatingInputCard`. |
| **4** | **Active / Selected** *(Đang chọn)* | Viền đậm `#0F766E` (dày 2px), nền phủ màu Teal nhạt `#F0FDFA`, Avatar sáng viền nổi bật. | Thuộc tính `isSelected: true` trong Avatar Assignment Bar & Pill Tabs. |
| **5** | **Disabled** *(Bị khóa)* | Giảm độ đậm `alpha: 0.5 – 0.6`, mất bóng đổ (`shadows: null`), con trỏ khóa và chặn toàn bộ tương tác tap. | Khi `onPressed == null` hoặc `isLoading == true` hoặc `readOnly: true`. |
| **6** | **Loading** *(Đang tải/xử lý)* | Nút tự ẩn nhãn và hiển thị vòng xoay `CircularProgressIndicator` (stroke 2px), danh sách hiển thị Shimmer loader. | Khi `isLoading: true` trong `AppButton` hoặc `AsyncValue.loading()` trong Riverpod. |
| **7** | **Error** *(Lỗi / Validate fail)* | Viền đổi sang màu đỏ **`#EF4444`**, icon cảnh báo xuất hiện, dòng text báo lỗi `Plus Jakarta Sans 12px` màu đỏ hiện bên dưới. | Khi `_errorText != null` trong Form Field Validator. |
| **8** | **Success** *(Thành công)* | Viền/nền chuyển sang **Emerald Green `#10B981`** (`#ECFDF5`), hiển thị icon tick tròn `HugeIcons.strokeRoundedTick01`, phát SnackBar xanh. | `PasswordChecklist` khi đạt tiêu chí hoặc `showSuccessSnackBar`. |

---

## 6. Cấu Hình Flutter Theme & Code Mẫu (`AppTheme` + `Plus Jakarta Sans` + `Hugeicons`)

Để tích hợp và phát triển chuẩn bộ UI context này vào dự án Flutter `PaySplit-FE`:

### 6.1. Khai báo Dependencies (`pubspec.yaml`):
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1       # Quản lý State Feature-First
  google_fonts: ^6.2.1           # Cung cấp Plus Jakarta Sans & JetBrains Mono
  hugeicons: ^0.0.8              # Bộ icon Hugeicons chính thức (Stroke Rounded)
  flutter_animate: ^4.5.2        # Micro-animations mượt mà (Fade, Slide, Scale)
  go_router: ^14.6.2             # Điều hướng màn hình chuẩn Declarative
```

### 6.2. Cấu hình Theme trong `lib/app/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final background = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final textMain = isDark ? AppColors.darkTextMain : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.darkTextMuted : const Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: const Color(0xFF10B981),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textMain,
        error: AppColors.danger,
        onError: Colors.white,
        outline: border,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
    );
  }
}
```

### 6.3. Mẫu Sử Dụng Component Chuẩn trong Màn Hình:
```dart
// 1. Ô nhập liệu nổi với Hugeicons
FloatingInputCard(
  controller: _emailController,
  label: 'Email tài khoản',
  hintText: 'user@example.com',
  icon: HugeIcons.strokeRoundedMail01,
  keyboardType: TextInputType.emailAddress,
  validator: (val) => val == null || !val.contains('@') ? 'Email không hợp lệ' : null,
)

// 2. Nút bấm CTA Gradient có Haptic Feedback & Loading state
AppButton(
  label: 'Đăng nhập',
  variant: AppButtonVariant.gradient,
  isLoading: _isLoading,
  trailingIcon: const Icon(HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 18),
  onPressed: _submit,
)
```

---

## 7. Mẫu Animation Nâng Cao (Optional): Animated Receipt & Right-to-Left Text Scramble

> **Ghi chú**: Đây là hiệu ứng hoạt họa nâng cao (Optional / Nice-to-have) dành cho trải nghiệm bóc tách số tiền sau khi quét OCR thành công, giúp tăng tính sinh động và thẩm mỹ công nghệ cho ứng dụng.

### 7.1. Đặc tả Nhịp điệu (Animation Timeline & Stagger Cadence)
- **Stagger Interval**: `0.3s (300ms)` giữa các dòng hóa đơn.
- **Scramble Duration**: `550ms` (cho các món lẻ) và `650ms` (cho hàng tổng cộng).
- **Quy tắc giải mã**: Giải mã các con số từ **Phải sang Trái (Right-to-Left)**, cố định dần từ ký tự cuối `...đ` ngược về đầu `35...`.
- **Chu kỳ lặp**: Chờ `5.0s` sau khi hoàn thành toàn bộ hóa đơn rồi tự động phát lại.

### 7.2. Flutter Widget Mẫu (`ScramblePriceText`):
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScramblePriceText extends StatefulWidget {
  final String targetText;
  final Duration duration;
  final bool isRevealed;
  final TextStyle? style;

  const ScramblePriceText({
    super.key,
    required this.targetText,
    this.duration = const Duration(milliseconds: 550),
    required this.isRevealed,
    this.style,
  });

  @override
  State<ScramblePriceText> createState() => _ScramblePriceTextState();
}

class _ScramblePriceTextState extends State<ScramblePriceText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  String _displayText = '------ đ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onAnimate);
    if (widget.isRevealed) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(ScramblePriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _controller.forward(from: 0);
    } else if (!widget.isRevealed) {
      _controller.reset();
      setState(() => _displayText = '------ đ');
    }
  }

  void _onAnimate() {
    final progress = _controller.value;
    final target = widget.targetText;
    final len = target.length;
    final resolvedCount = (progress * (len + 1)).floor();
    final cutoffIndex = len - resolvedCount; // Right to Left resolution

    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      final char = target[i];
      if (char == ' ' || char == '.' || char == 'đ') {
        buffer.write(char);
      } else if (i >= cutoffIndex) {
        buffer.write(char); // Locked char
      } else {
        buffer.write(_random.nextInt(10).toString()); // Scrambling digit
      }
    }
    setState(() => _displayText = buffer.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style ?? GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
```
