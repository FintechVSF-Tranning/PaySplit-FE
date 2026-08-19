# 0002. Home & Balance Overview UI Specification (Mobile Flutter)

**Date**: 2026-08-19  
**Status**: In Progress  
**Style System**: Tally x Hallmark (Utilitarian Warm Editorial, Notion & Claude-inspired)  
**UI Framework**: Flutter 3.x + [Forui](https://forui.dev) + Riverpod 2.x  
**Design Tokens**: [`PaySplit-UI/ui-context.md`](../../../PaySplit-UI/ui-context.md) (`Newsreader`, `Roboto Slab`, `JetBrains Mono`, `Hugeicons`, Warm Olive Palette `#F5F6F1`, Deep Teal `#0F766E`, Medium Radius 10px)  
**Companion Backend Specs**:
- [`PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md`](../../../PaySplit-BE/docs/specs/0004-split-settlement-v1/index.md) (Số dư, ma trận công nợ, sinh mã VietQR)
- [`PaySplit-BE/docs/specs/0002-group-management-v1/index.md`](../../../PaySplit-BE/docs/specs/0002-group-management-v1/index.md) (Danh sách nhóm, thành viên)
- [`PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md`](../../../PaySplit-BE/docs/specs/0003-bill-ocr-v1/index.md) (Hóa đơn gần đây, OCR)

---

## 1. Executive Summary & Goals

**Màn hình Trang Chủ & Tổng Quan Số Dư (Home Page / Dashboard)** là trung tâm điều khiển tài chính nhóm của ứng dụng PaySplit. Màn hình giúp người dùng trả lời 3 câu hỏi quan trọng nhất chỉ trong **2 giây đầu tiên**:
1. *Tổng cộng mình đang nợ bao nhiêu hoặc người khác đang nợ mình bao nhiêu?* (**Net Balance Hero Card**)
2. *Mình cần thanh toán cho ai ngay lúc này hoặc ai cần duyệt chuyển khoản?* (**Actionable Debt Matrix & Quick VietQR**)
3. *Các nhóm và hóa đơn gần đây đang có hoạt động gì mới?* (**Active Groups Carousel & Activity Feed**)

Thiết kế loại bỏ hoàn toàn các biểu đồ trang trí phức tạp (anti-AI-slop), thay vào đó tập trung vào tính trung thực số liệu (honest finance), kiểu chữ biên tập sang trọng (`Newsreader` x `Roboto Slab`), các con số monospace rõ ràng (`JetBrains Mono`), và khả năng thanh toán 1-chạm qua VietQR.

---

## 2. UI Acceptance Criteria (AC-UI)

- **AC-UI-1 (Typography & Token Purity)**:
  - Tiêu đề chào mừng, tiêu đề mục (`Section Heading`) sử dụng font **`Newsreader`** (Editorial Serif).
  - Nội dung, nhãn thẻ, nút bấm sử dụng font **`Roboto Slab`**.
  - Toàn bộ số tiền (VND), mã thanh toán, mã tham chiếu dùng font **`JetBrains Mono`** (`tabular-nums`).
  - Màu nền trang là **`Warm Olive Paper (#F5F6F1)`**, thẻ `FCard` màu trắng (`#FFFFFF`) có viền `1px solid #DBE0CE`.
  - Icon sử dụng độc quyền bộ **`Hugeicons`** với độ dày nét chuẩn `1.5px`.

- **AC-UI-2 (Net Balance 3-State Visual Hero)**:
  - **Dương (+) - Bạn được nhận**: Nền số dư màu xanh ngọc nhạt (`#ECFDF5`), chữ xanh đậm (`#059669` — Emerald 600), số tiền hiển thị `+X.XXX.XXX đ` kèm nhãn *"Bạn được nhận lại"*.
  - **Âm (-) - Bạn cần trả**: Nền số dư màu đỏ nhạt (`#FEF2F2`), chữ đỏ đậm (`#DC2626` — Red 600), số tiền hiển thị `-X.XXX.XXX đ` kèm nút nổi bật `[ Trả nợ ngay ⚡ ]`.
  - **Bằng 0 (0 đ) - Sạch nợ**: Nền số dư màu Olive nhạt (`#EDF0E6`), chữ xám đậm (`#1C2118`), hiển thị *"Đã thanh toán hết công nợ • Không có nợ đọng"*.

- **AC-UI-3 (P2P Quick Settlement Hub)**:
  - Nhóm các khoản nợ theo từng **Chủ nợ (Creditor)** hoặc **Con nợ (Debtor)** thay vì hiển thị rời rạc từng bill.
  - Khi bấm `[ Trả nợ qua VietQR ]`, hệ thống mở trực tiếp Bottom Sheet hiển thị mã QR động chuẩn NAPAS kèm STK, tên chủ tài khoản và cú pháp `PAY...` để quét trên App ngân hàng.
  - Có tab/nút bấm chuyển nhanh giữa `Cần trả (Debts)` và `Cần thu (Receivables)`.

- **AC-UI-4 (Active Groups Carousel & Badge Summary)**:
  - Hiển thị danh sách nhóm mà người dùng đang tham gia dưới dạng card nằm ngang hoặc danh sách dọc tinh gọn.
  - Mỗi thẻ nhóm hiển thị: Tên nhóm, Emoji đại diện, Số lượng thành viên, và Số dư riêng trong nhóm đó (Ví dụ: `Nợ 120.000 đ` hoặc `Được nhận 350.000 đ`).

- **AC-UI-5 (Recent Activity Stream & Live Status)**:
  - Hiển thị dòng thời gian các hoạt động gần nhất (hóa đơn mới tạo, thanh toán đã duyệt, nhắc nợ).
  - Trạng thái hóa đơn hiển thị badge Forui rõ ràng (`FBadge.success` cho *Đã chia*, `FBadge.warning` cho *Chờ duyệt*, `FBadge.outline` cho *Đang quét*).

- **AC-UI-6 (Zero-State Onboarding for New Users & Join Group Flow)**:
  - Khi người dùng mới chưa có nhóm và chưa có số dư (Số dư = 0đ, Groups = 0): Hiển thị Card hướng dẫn 3 bước thực dụng kèm nút bấm `[ + Tạo nhóm đầu tiên ]` và `[ Nhập mã mời nhóm ]`.
  - Khi bấm `[ Nhập mã mời nhóm ]`: Mở Bottom Sheet 2 bước:
    1. *Bước 1*: Nhập mã mời 6-8 ký tự viết hoa (Mono font) $\rightarrow$ gọi `GET /api/v1/groups/invites/{code}` để kiểm tra và xem trước thông tin nhóm (Tên nhóm, Emoji, Captain, số lượng TV, thời hạn mã).
    2. *Bước 2*: Hiển thị Preview Card $\rightarrow$ bấm `[ Xác nhận tham gia nhóm ]` (`POST /api/v1/groups/join`) để gia nhập và chuyển sang trạng thái Home chính thức.

- **AC-UI-7 (Pull-to-Refresh & Optimistic Microinteractions)**:
  - Hỗ trợ thao tác kéo để làm mới (`RefreshIndicator`) đồng bộ số dư từ backend (`GET /api/v1/groups` kèm `GET /api/v1/groups/{groupId}/debts` per-group fan-out).
  - Nút bấm có hiệu ứng tactile nhẹ (`scale: 0.98` khi bấm), không giật lag.

- **AC-UI-8 (8-State Widget Completeness)**:
  - Mọi nút bấm, thẻ nhóm, dòng nợ và tab đều có đầy đủ 8 trạng thái tương tác theo chuẩn `ui-context.md §5`: Default, Pressed (`scale: 0.98`), Focus-visible (viền `1.5px #1C2118`), Active/Selected, Disabled (`opacity: 0.4`), Loading (Skeleton shimmer hoặc Forui spinner), Error (`FAlert.destructive` inline), Success (tick xanh `#10B981`).

---

## 3. Screen Structure & Information Architecture

```text
┌──────────────────────────────────────────────────────────────────┐
│  STATUS BAR (Minimalist, No notch island)                        │
├──────────────────────────────────────────────────────────────────┤
│  [TOP HEADER BAR]                                                │
│  Avatar + "Chào Nam 👋"            [🔔 Badge]  [🔍 Scan Bill FAB]│
├──────────────────────────────────────────────────────────────────┤
│  [HERO BALANCE CARD]                                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  TỔNG SỐ DƯ CÔNG NỢ (NET BALANCE)                          │  │
│  │  +850.000 đ  (Bạn được nhận lại)                           │  │
│  │  ────────────────────────────────────────────────────────  │  │
│  │  [⚡ Trả nợ VietQR]   [📸 Quét hóa đơn]   [👥 Tạo nhóm]    │  │
│  └────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  [ACTIONABLE DEBTS & SETTLEMENTS]                                │
│  Tab: Cần trả (2) | Cần thu (3)                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  🍕 Minh Tran · Cơm trưa Dev             -120.000 đ [Trả QR│  │
│  │  🏖 Hoàng Nam · Tiền xe Đà Lạt           -300.000 đ [Trả QR│  │
│  └────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  [MY GROUPS (HORIZONTAL CAROUSEL)]                               │
│  ┌──────────────────────┐ ┌──────────────────────┐               │
│  │ 🍜 Phòng Dev Cty     │ │ 🏖 Du lịch Đà Lạt    │ [ + Thêm ]    │
│  │ 5 TV · +350.000 đ    │ │ 8 TV · -120.000 đ    │               │
│  └──────────────────────┘ └──────────────────────┘               │
├──────────────────────────────────────────────────────────────────┤
│  [RECENT ACTIVITY TIMELINE]                                      │
│  • 10:30 - Minh Tran đã chuyển 120.000 đ (Chờ bạn duyệt)         │
│  • Hôm qua - Hóa đơn "Lẩu gà lá é" đã chốt (529.200 đ)           │
├──────────────────────────────────────────────────────────────────┤
│  [BOTTOM NAVIGATION BAR - 4 TABS]                                │
│  [ 🏠 Tổng quan ]   [ 👥 Nhóm ]   [ 🧾 Hóa đơn ]   [ ⚙️ Cài đặt ] │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Component-by-Component Specifications

### 4.1. Top Header Bar (`HomeHeader.dart`)
- **Avatar & Greeting**:
  - Avatar tròn `40px` viền `1.5px solid #DBE0CE`, nếu chưa có ảnh đại diện thì hiển thị 2 chữ cái đầu trên nền Teal nhạt (`#F0FDFA`).
  - *Tương tác Avatar*: Bấm vào Avatar mở màn hình **Chỉnh sửa thông tin cá nhân & Quản lý STK ngân hàng VietQR thụ hưởng** (thuộc module Profile/Settings).
  - Lời chào: `"Xin chào,"` (`Roboto Slab Regular 13px, #676E5F`), Tên người dùng: `user.fullName` (`Newsreader Medium 18px, #1C2118`).
- **Action Icons**:
  - `Notification Bell` (`HugeIcons.strokeRoundedNotification01` 22px): Có chấm đỏ nhỏ nếu có thông báo chưa đọc. Bấm vào mở Bottom Sheet / màn hình Thông báo.
  - `Scan Bill Action Pill` (`HugeIcons.strokeRoundedCamera01` 18px + chữ *"Quét bill"*): Nút tắt mở camera quét OCR ngay lập tức.

---

### 4.2. Hero Balance Card (`NetBalanceCard.dart`)
Thẻ trung tâm đặt trên nền trắng `FCard` bo góc `10px`, viền `1px solid #DBE0CE`:
- **Header Thẻ**:
  - Dòng tiêu đề nhỏ: `TỔNG SỐ DƯ CÔNG NỢ` (`Roboto Slab SemiBold 11px`, tracking `+0.5px`, màu xám `#676E5F`).
  - Icon thông tin `HugeIcons.strokeRoundedInformationCircle` giải thích công thức (Tổng tiền người khác nợ bạn - Tổng tiền bạn nợ người khác).
- **Con số tài chính chính (`Big Number Display`)**:
  - Sử dụng font **`JetBrains Mono Bold 32px`** kèm ký hiệu tiền tệ `đ`.
  - Nếu `net_balance > 0`: Màu `#059669` (Emerald 600) + Badge `"Bạn được nhận"`.
  - Nếu `net_balance < 0`: Màu `#DC2626` (Red 600) + Badge `"Bạn cần trả"`.
  - Nếu `net_balance == 0`: Màu `#1C2118` + Badge `"Đã cân bằng"`.
- **Dải phân cách & Chi tiết 2 chiều**:
  - `Đang cho nợ (Receivable)`: `+1.250.000 đ` (`JetBrains Mono Medium 13px, #059669`).
  - `Đang nợ (Payable)`: `-400.000 đ` (`JetBrains Mono Medium 13px, #DC2626`).
- **Quick Action Bar (3 nút bấm nhanh dạng Pill)**:
  1. `⚡ Trả nợ VietQR`: Mở Bottom Sheet chọn khoản nợ cần thanh toán (`Select Debt Sheet`) nếu người dùng có nhiều khoản nợ từ các chủ nợ khác nhau. Cho phép chọn 1 hoặc nhiều khoản nợ để tạo mã VietQR tương ứng. *(Lưu ý: Cơ chế gom nợ nâng cao & thanh toán đa chủ nợ được đặc tả chi tiết trong spec `0004-split-settlement-v1`)*.
  2. `📸 Quét bill OCR`: Mở luồng chụp/chọn ảnh hóa đơn.
  3. `👥 Tạo nhóm`: Mở modal đặt tên và thêm thành viên nhóm mới.

---

### 4.3. Actionable Debts Widget (`ActionableDebtsList.dart`)
Khu vực hiển thị danh sách các khoản nợ cần thanh toán hoặc cần duyệt ngay:
- **Bộ lọc dạng Segmented Tab (`FTabs` hoặc Custom Pill Tabs)**:
  - `Cần trả (X)`: Các khoản bạn nợ thành viên khác trong nhóm.
  - `Cần thu (Y)`: Các khoản bạn bè nợ bạn kèm trạng thái proof đã nộp.
- **Cấu trúc mỗi dòng nợ (Debt Item Row)**:
  - **Bên trái**: Avatar đối tác + Tên đối tác (`Roboto Slab Medium 14px`) + Tên hóa đơn/nhóm (`Roboto Slab Regular 12px, #676E5F`).
  - **Bên phải**: Số tiền nợ (`JetBrains Mono Bold 14px`) + Nút hành động tương ứng:
    - Nếu là khoản cần trả: Nút `[ Trả QR ⚡ ]` (`FButton.outline`, kích thước nhỏ, màu Teal `#0F766E`). Bấm vào sinh ngay VietQR thanh toán cho chủ nợ đó.
    - Nếu là khoản cần thu mà đối tác đã chuyển: Nút `[ Duyệt proof ]` (`FButton.primary`, màu Xanh lá `#059669`). Bấm vào mở Bottom Sheet xem ảnh biên lai ngân hàng điện tử (mô phỏng phiếu chuyển khoản ngân hàng chuẩn với đầy đủ mã FT, STK nguồn, STK nhận, thời gian, số tiền, **lời nhắn từ người nợ** theo Spec 0004 AC-6 `payments.note` và 1 nút tick xác nhận duy nhất).
    - Nếu là khoản cần thu quá 24h: Nút `[ 🔔 Nhắc nợ ]` (`FButton.ghost`). Bấm vào gửi thông báo nhắc nợ tự động (áp dụng rate-limit 1 lần/24h).

---

### 4.4. My Groups Carousel (`MyGroupsSection.dart`)
- **Tiêu đề mục**: `Nhóm của tôi` (`Newsreader SemiBold 18px`) + Nút `Xem tất cả` (`Roboto Slab Regular 13px, #0F766E`).
- **Thẻ nhóm (Group Card)**:
  - Kích thước cố định `180px x 115px`, trượt ngang mượt mà (`ListView.separated` horizontal).
  - Emoji đại diện nhóm + Tên nhóm (`Roboto Slab SemiBold 14px`, 1 dòng cắt ngắn ellipsis).
  - Số lượng thành viên (`HugeIcons.strokeRoundedUserGroup` 12px + `"5 người"`).
  - Dòng trạng thái số dư riêng trong nhóm:
    - `+350.000 đ` (Màu xanh nếu nhóm đó mình đang có dư).
    - `-120.000 đ` (Màu đỏ nếu nhóm đó mình đang nợ).
    - `0 đ` (Màu xám nhạt nếu đã xong).
- **Thẻ thêm nhóm nhanh (`+ Tạo nhóm mới`)**: Thẻ nét đứt `dashed border 1px #DBE0CE` giúp người dùng dễ dàng tạo nhóm mới bất kỳ lúc nào.

---

### 4.5. Recent Activity Timeline (`RecentActivityList.dart`)
- **Tiêu đề mục**: `Hoạt động gần đây` (`Newsreader SemiBold 18px`).
- **Danh sách sự kiện (`group_activities`)**:
  - Icon thể loại sự kiện (Tạo bill mới `strokeRoundedInvoice01`, Đã thanh toán `strokeRoundedCheckmarkCircle02`, Nhắc nợ `strokeRoundedNotification01`).
  - Mô tả tự nhiên do backend sinh (Ví dụ: *"Minh đã nộp bằng chứng chuyển khoản 120.000 đ cho hóa đơn Cơm trưa"*).
  - Thời gian tương đối: *"5 phút trước"*, *"2 giờ trước"*, *"Hôm qua"*.

---

### 4.6. Bottom Navigation Dock (`AppBottomNavBar.dart`)
Thanh điều hướng cố định dưới đáy màn hình với nền trắng, viền trên `1px solid #DBE0CE`:
1. `🏠 Tổng quan` (`HugeIcons.strokeRoundedHome01`) - Tab hiện tại.
2. `👥 Nhóm` (`HugeIcons.strokeRoundedUserGroup`) - Danh sách tất cả nhóm và số dư chi tiết.
3. `🧾 Hóa đơn` (`HugeIcons.strokeRoundedInvoice01`) - Lịch sử hóa đơn, bộ lọc OCR.
4. `⚙️ Cài đặt` (`HugeIcons.strokeRoundedSettings01`) - Tài khoản, Quản lý tài khoản ngân hàng thụ hưởng (VietQR bank profile).

---

## 5. Data Flow & API Contracts Mapping

### 5.1. Các Endpoint Backend Sử Dụng

> **Chiến lược Fan-out Aggregation**: Backend hiện tại không có endpoint dashboard toàn cục. FE sẽ gọi song song các endpoint per-group và tổng hợp phía client thông qua `HomeDashboardNotifier`. Nếu số lượng nhóm > 5, cân nhắc tạo BE endpoint `GET /api/v1/dashboard` tổng hợp ở giai đoạn tối ưu sau.

| Endpoint BE (Thực tế) | Phương thức | Mục đích trên Home Screen | Spec BE |
| :--- | :--- | :--- | :--- |
| `/api/v1/groups` | `GET` | Lấy danh sách nhóm hoạt động kèm emoji, member_count. | `0002-group-management-v1` |
| `/api/v1/groups/{groupId}/debts` | `GET` | Lấy danh sách nợ per-group (`caller_payable`, `caller_receivable`, `net_matrix`). FE fan-out tất cả groups → aggregate thành tổng `net_balance`. | `0004-split-settlement-v1` AC-2 |
| `/api/v1/groups/{groupId}/payments/qr` | `POST` | Sinh mã VietQR động 1-chạm khi bấm nút `[ Trả QR ]`. | `0004-split-settlement-v1` AC-3 |
| `/api/v1/notifications/unread-count` | `GET` | Lấy số lượng thông báo chưa đọc cho chuông thông báo. | `0006-notification-queue-v1` AC-6 |

> **Lưu ý**: `group_activities` hiện chỉ có endpoint per-group (chưa có endpoint global). Section "Hoạt động gần đây" sẽ hiển thị activities từ các nhóm gần nhất (fan-out top 3 nhóm active) hoặc tạm ẩn cho đến khi BE bổ sung `GET /api/v1/activities/recent`.

### 5.2. Chiến Lược Tổng Hợp Số Dư (Client-side Aggregation)

FE gọi `GET /api/v1/groups` lấy danh sách nhóm → gọi song song `GET /api/v1/groups/{id}/debts` cho mỗi nhóm → tổng hợp:

```text
net_balance = Σ(caller_receivable[i]) - Σ(caller_payable[i])   ∀ group i
total_receivable = Σ(caller_receivable[i])                      ∀ group i
total_payable = Σ(caller_payable[i])                            ∀ group i
actionable_debts = flatten(debts[i] where status == 'awaiting') grouped by creditor/debtor
```

### 5.3. Cấu trúc Entity Mẫu (FE Domain — `HomeSummaryEntity`)

```dart
// lib/features/home/domain/entities/home_summary_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_summary_entity.freezed.dart';

@freezed
class HomeSummaryEntity with _$HomeSummaryEntity {
  const factory HomeSummaryEntity({
    required String userId,
    required String fullName,
    String? avatarUrl,
    required int netBalance,         // Aggregated: tổng receivable - tổng payable (VND)
    required int totalReceivable,     // Σ caller_receivable across groups
    required int totalPayable,        // Σ caller_payable across groups
    required List<ActionableDebtEntity> actionableDebts,
    required List<GroupBalanceEntity> groups,
    required int unreadNotificationCount,
  }) = _HomeSummaryEntity;
}

@freezed
class ActionableDebtEntity with _$ActionableDebtEntity {
  const factory ActionableDebtEntity({
    required String debtId,           // Matches BE debt_item.id
    required String groupId,
    required String groupName,
    required String counterpartMemberId,
    required String counterpartDisplayName,
    String? counterpartAvatarUrl,
    required int amount,              // Parsed from BE string "120000" → int
    required String status,           // 'awaiting' | 'pending_confirmation'
    required bool isPayable,          // true = I owe them, false = they owe me
  }) = _ActionableDebtEntity;
}

@freezed
class GroupBalanceEntity with _$GroupBalanceEntity {
  const factory GroupBalanceEntity({
    required String groupId,
    required String name,
    required String emoji,
    required int memberCount,
    required int myNetBalance,        // From v_member_balances view via debts endpoint
  }) = _GroupBalanceEntity;
}
```

### 5.4. Ánh Xạ BE Response → FE Entity

| BE Response Field | Kiểu BE | FE Entity Field | Kiểu FE | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| `debts[].amount` | `string` ("120000") | `ActionableDebtEntity.amount` | `int` | Parse `int.parse(value)` |
| `caller_payable` | `string` | `totalPayable` | `int` | Tổng hợp across groups |
| `caller_receivable` | `string` | `totalReceivable` | `int` | Tổng hợp across groups |
| `debts[].debtor_display_name` | `string` | `counterpartDisplayName` | `string` | Map theo hướng nợ |
| `unread_count` | `int` | `unreadNotificationCount` | `int` | Direct mapping |

---

## 6. Architecture & State Management (Flutter + Riverpod)

### 6.1. Layered Feature Structure
```text
lib/features/home/
├── data/
│   ├── datasources/home_remote_datasource.dart    # Retrofit API calls
│   ├── models/home_summary_dto.dart              # Freezed JSON parsing
│   └── repositories/home_repository_impl.dart    # Repository Implementation
├── domain/
│   ├── entities/home_summary_entity.dart         # Pure Domain Entity
│   ├── repositories/home_repository.dart         # Interface
│   └── usecases/get_home_summary_usecase.dart    # Business Logic UseCase
└── presentation/
    ├── providers/home_dashboard_provider.dart    # AsyncNotifier Riverpod
    ├── pages/home_page.dart                      # Main Scaffold & ScrollView
    └── widgets/
        ├── home_header.dart                      # User avatar & Quick scan
        ├── net_balance_hero_card.dart            # 3-State Net Balance Card
        ├── quick_action_bar.dart                 # 3 Quick action pills
        ├── actionable_debts_card.dart            # P2P Debts list + Pay button
        ├── my_groups_carousel.dart               # Horizontal group slider
        ├── recent_activity_timeline.dart         # Recent activity feed
        └── quick_settle_qr_sheet.dart            # Dynamic VietQR Modal Sheet
```

### 6.2. Riverpod Controller Blueprint (`HomeDashboardNotifier`)

```dart
// lib/features/home/presentation/providers/home_dashboard_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/home_summary_entity.dart';
import '../../domain/usecases/get_home_summary_usecase.dart';

part 'home_dashboard_provider.g.dart';

@riverpod
class HomeDashboardNotifier extends _$HomeDashboardNotifier {
  @override
  FutureOr<HomeSummaryEntity> build() async {
    return _fetchHomeSummary();
  }

  Future<HomeSummaryEntity> _fetchHomeSummary() async {
    final useCase = ref.read(getHomeSummaryUseCaseProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }

  Future<void> refreshDashboard() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHomeSummary());
  }
}
```

---

## 7. Edge Cases & Error Handling Matrix

| Trường hợp (Edge Case) | Hành vi UI & Xử lý người dùng |
| :--- | :--- |
| **Người dùng mới chưa có nhóm (Zero-State)** | Thay vì hiển thị số 0đ trống rỗng, ẩn danh sách nợ và hiển thị Card Welcome Onboarding 3 bước hướng dẫn: *1. Tạo nhóm $\rightarrow$ 2. Thêm bạn $\rightarrow$ 3. Quét bill*. |
| **Mất kết nối mạng (Offline)** | Hiển thị Banner mỏng màu vàng nhẹ đầu trang: *"Đang hiển thị dữ liệu đã lưu trữ gần nhất"*. Vẫn cho phép xem danh sách nhóm và mở QR offline nếu đã cache. |
| **Chủ nợ chưa cài đặt tài khoản ngân hàng** | Khi bấm `[ Trả QR ]`, nếu đối tác chưa có STK ngân hàng trong profile, hiển thị Bottom Sheet cảnh báo thân thiện: *"Bạn này chưa thêm tài khoản ngân hàng. Hãy nhắn bạn cập nhật STK hoặc thanh toán tiền mặt."* |
| **Lỗi tải dữ liệu (500 / Network Timeout)** | Hiển thị `FAlert.destructive` kèm nút `[ Thử lại ]` ngay tại vị trí widget bị lỗi, không làm crash toàn màn hình. |
| **Số dư lớn hàng tỷ đồng** | Font size tự động co giãn (`FittedBox` / `AutoResizeText`) để không bị tràn dòng (`RenderFlex overflowed`). |

---

## 8. Verification & Test Plan

### 8.1. Automated Unit & Widget Tests
- **Unit Test UseCase & Notifier**:
  - `get_home_summary_usecase_test.dart`: Đảm bảo map đúng `HomeSummaryDTO` sang `HomeSummaryEntity`.
  - `home_dashboard_provider_test.dart`: Kiểm tra luồng `AsyncValue.loading` $\rightarrow$ `AsyncValue.data` và xử lý `refreshDashboard()`.
- **Widget Test**:
  - `net_balance_hero_card_test.dart`: Kiểm tra hiển thị màu xanh khi số dư dương, màu đỏ khi số dư âm và màu trung tính khi bằng 0đ.
  - `actionable_debts_test.dart`: Kiểm tra hiển thị danh sách nợ và sự kiện bấm nút `[ Trả QR ]`.

### 8.2. Manual Visual Verification
- Kiểm tra giao diện trên 3 độ phân giải màn hình mobile chuẩn:
  - **iPhone SE (375px)**: Đảm bảo không tràn viền, card nhóm trượt mượt mà.
  - **iPhone 15 / 16 (393px - 414px)**: Khoảng cách lề 16px chuẩn, tỷ lệ chữ hài hòa.
  - **Android Large Screen (430px+)**: Bố cục co giãn linh hoạt, không vỡ layout.
