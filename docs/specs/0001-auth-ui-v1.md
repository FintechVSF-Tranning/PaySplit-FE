# 0001. Auth UI & User Flow Specification (Mobile Flutter)

**Date**: 2026-08-18  
**Status**: Approved / In Development  
**Style System**: Tally x Hallmark (Utilitarian Warm Editorial, Claude & Notion-inspired)  
**UI Library**: Flutter + [Forui](https://forui.dev)  
**Design Tokens**: [`PaySplit-UI/ui-context.md`](../../../PaySplit-UI/ui-context.md) (`Newsreader`, `Roboto Slab`, `JetBrains Mono`, `Hugeicons`, Warm Olive Palette `#F5F6F1`, Deep Teal `#0F766E`, Medium Radius 10px)  
**Companion Backend Spec**: [`PaySplit-BE/docs/specs/0001-auth-account-v1/index.md`](../../../PaySplit-BE/docs/specs/0001-auth-account-v1/index.md)

---

## 1. Summary

Tài liệu đặc tả toàn bộ giao diện, trạng thái tương tác và luồng trải nghiệm người dùng (UI/UX) cho **Module Xác Thực & Quản Lý Phiên (Auth Module)** của PaySplit Mobile App trên nền tảng Flutter.

Bao gồm 6 màn hình:
1. **Welcome / Onboarding Page**: Giới thiệu giá trị sản phẩm, định hướng người dùng mới và cũ qua hóa đơn mẫu giải mã số tiền sinh động.
2. **Sign In Page**: Đăng nhập qua Email/Mật khẩu, quản lý session 1 thiết bị, đếm ngược khóa tài khoản (429).
3. **Sign Up Page**: Đăng ký với Họ tên, Email, Số điện thoại Việt Nam (E.164) và Mật khẩu chuẩn bảo mật.
4. **Email OTP Verification Page**: Nhập mã OTP 6 số kích hoạt tài khoản. **Đặc biệt: Sau khi xác thực thành công trong luồng Đăng ký, ứng dụng tự động đăng nhập ngầm và chuyển thẳng vào Trang chủ (Home Page)** để mang lại trải nghiệm liền mạch tối đa.
5. **Forgot Password Page**: Nhập Email gửi yêu cầu khôi phục mật khẩu (chống enumeration).
6. **Reset Password Page**: Nhập OTP 6 số và thiết lập mật khẩu mới, thu hồi toàn bộ session cũ và chuyển về Đăng nhập (kèm banner xanh thành công & focus mật khẩu).

---

### UI Acceptance Criteria (AC)
- **AC-UI-1 (Typography & Brand)**: Tiêu đề trang và headline nghệ thuật sử dụng font **`Newsreader`** (Editorial Serif). Nhãn nút, input và nội dung dùng font **`Roboto Slab`** đồng bộ. Số tiền, mã OTP và mã VietQR dùng **`JetBrains Mono`**. Icon dùng **`Hugeicons`** với độ dày nét `1.5px`.
- **AC-UI-2 (Tally x Olive Aesthetic)**: Màu nền trang `Warm Olive Paper (#F5F6F1)`, thẻ `FCard` nền trắng (`#FFFFFF`), đường viền sắc nét `1px solid #DBE0CE`, bo góc `Medium (10px)`. Nút hành động chính màu `Deep Teal (#0F766E)`.
- **AC-UI-3 (Input Validation UX)**:
  - Email: Validate format tức thời khi rời ô input (`onBlur`) hoặc khi submit.
  - Số điện thoại: Tự động chuẩn hóa đầu số `0x` hoặc `+84` sang E.164.
  - Mật khẩu: Checklist trực quan (8–72 ký tự, chữ hoa, chữ thường, chữ số) đổi màu xanh khi đạt.
- **AC-UI-4 (OTP Input Widget)**: Hỗ trợ 6 ô nhập rời tự động focus ô kế tiếp, cho phép dán (paste) 6 số từ clipboard, tự động ẩn bàn phím khi đủ 6 ký tự.
- **AC-UI-5 (Rate Limit & Blocking Countdown)**: Khi nhận HTTP 429 hoặc đếm ngược resend OTP, UI hiển thị đồng hồ đếm lùi từng giây (`Retry-After`) và vô hiệu hóa nút gửi.
- **AC-UI-6 (Seamless Sign-Up to Home)**: Khi người dùng đăng ký tài khoản và nhập đúng mã OTP xác thực, ứng dụng tự động đăng nhập ngầm bằng phiên đăng ký và chuyển thẳng vào Trang chủ (`/home`), không bắt người dùng nhập lại mật khẩu.
- **AC-UI-7 (8-State Completeness)**: Mọi nút bấm và ô nhập liệu đều có đầy đủ 8 trạng thái (Default, Pressed, Focus, Disabled, Loading spinner, Error message, Success).

---

## 3. Screen-by-Screen Detailed Specifications

```text
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                         │
│  [1. Welcome] ──┬──> [2. Sign In] <─────────────────────── [6. Reset Password]          │
│                 │        │                                        ▲                     │
│                 │        │ (Chưa verify email)                    │                     │
│                 │        ▼                                        │ (Nhập OTP & Pass)   │
│                 │   [4. Verify OTP (Old)]                         │                     │
│                 │                                                 │                     │
│                 │ (Quên pass)                                     │                     │
│                 ├───────────────────> [5. Forgot Password] ───────┤                     │
│                 │                                                                       │
│                 │ (Đăng ký mới)                                                         │
│                 └──> [3. Sign Up] ──> [4. Verify OTP] ──(Tự động Sign-In)──> [🏠 HOME]  │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 3.1. Welcome / Onboarding Screen (`welcome_page.dart`)

* **Mục đích**: Chào đón người dùng, tạo ấn tượng cao cấp theo phong cách Tally editorial kết hợp hóa đơn giải mã số tiền sinh động.
* **Thành phần giao diện**:
  1. **Top Brand Bar**:
     - Wordmark: `PaySplit` (`Newsreader SemiBold 600 28px`, `#1C2118`).
     - Subtle Badge: `v1.0 • FinTech` (`FBadge.outline`, viền `#DBE0CE`, kèm pulse dot xanh).
  2. **Hero Statement**:
     - Tiêu đề: `Chia tiền nhóm thông minh` (`Newsreader Regular 500 29px`, `#1C2118`).
     - Phụ đề: `Quét hóa đơn AI và thanh toán 1-chạm qua VietQR.` (`Roboto Slab Regular 13px`, `#676E5F`).
  3. **Hero Illustration / Visual Motif (Hóa đơn mẫu - Animated Receipt Card)**:
     - Thẻ mô phỏng biên lai Tally (`Receipt Card`) viền 1px `#DBE0CE`, nền `#FFFFFF`:
       - Header: `🍕 Cơm trưa phòng Dev` + Badge `Đang quét AI OCR...`.
       - **Kịch bản Staggered Reveal + Right-to-Left Text Scramble**:
         - **0.25s (250ms)**: Món 1 (*Lẩu gà lá é*) xuất hiện trượt lên (`opacity 0.35s`, `translateY 8px -> 0`) $\rightarrow$ Kích hoạt Text Scramble số tiền đồng thời (chạy 550ms) $\rightarrow$ Chốt cố định từ phải sang trái thành `350.000 đ`.
         - **0.55s (550ms)**: Món 2 (*Trà đào cam sả*) xuất hiện trượt lên (+0.3s) $\rightarrow$ Kích hoạt Text Scramble đồng thời (chạy 550ms) $\rightarrow$ `120.000 đ`.
         - **0.85s (850ms)**: Món 3 (*Khăn lạnh & nước suối*) xuất hiện trượt lên (+0.3s) $\rightarrow$ Kích hoạt Text Scramble đồng thời (chạy 550ms) $\rightarrow$ `20.000 đ`.
         - **1.20s (1200ms)**: Hàng **Tổng cộng (VAT 8%)** xuất hiện $\rightarrow$ Kích hoạt Text Scramble đồng thời (chạy 650ms) $\rightarrow$ `529.200 đ` (Màu Teal `#0F766E`, Bold) + Cập nhật badge thành `Đã bóc tách AI (3 món)`.
         - **1.90s (1900ms)**: Khối **VietQR Dynamic Settlement • 1-Click Pay** xuất hiện hoàn tất.
         - **5.0s sau khi hoàn thành**: Tự động reset và phát lại toàn bộ chu kỳ nếu người dùng vẫn ở màn hình Welcome.
  4. **Value Proposition Bullets (2 điểm chạm tinh gọn)**:
     - 📸 **Bóc tách hóa đơn AI**: Tự động nhận diện từng món và thuế phí.
     - **Thanh toán VietQR 1-chạm**: Trả đúng số tiền nợ, không cần nhập STK.
  5. **Action Buttons**:
     - Nút Chính (`FButton.primary` - Nền Teal `#0F766E`): `Tạo tài khoản mới` $\rightarrow$ Điều hướng tới `SignUpPage`.
     - Nút Phụ (`FButton.outline` - Viền 1px `#DBE0CE`): `Đã có tài khoản? Đăng nhập` $\rightarrow$ Điều hướng tới `SignInPage`.

---

#### 💡 Hướng dẫn chuyển đổi Animation sang Flutter (`ReceiptPreviewCard.dart`):

Trong Flutter, hiệu ứng được triển khai bằng `AnimationController` kết hợp `Timer` chu kỳ 5 giây:

```dart
// lib/features/auth/presentation/widgets/scramble_price_text.dart
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
    final cutoffIndex = len - resolvedCount; // Giải mã từ Phải sang Trái (RTL)

    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      final char = target[i];
      if (char == ' ' || char == '.' || char == 'đ') {
        buffer.write(char);
      } else if (i >= cutoffIndex) {
        buffer.write(char); // Đã chốt số cố định
      } else {
        buffer.write(_random.nextInt(10).toString()); // Số ngẫu nhiên đang đảo
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

---

### 3.2. Sign In Screen (`sign_in_page.dart`)

* **Mục đích**: Đăng nhập an toàn với email và mật khẩu, xử lý khóa tài khoản (429) và chuyển hướng email chưa kích hoạt.
* **Bố cục giao diện**:
  1. **Header Navigation**:
     - Nút Back (`HugeIcons.strokeRoundedArrowLeft01`).
     - Tiêu đề: `Đăng nhập` (`Newsreader Medium 500 27px`, `#1C2118`).
     - Phụ đề: `Chào mừng bạn quay trở lại với PaySplit` (`Roboto Slab Regular 13px, #676E5F`).
  2. **Form Nhập Liệu (`FCard` bao quanh form hoặc phẳng)**:
     - **Email Input (`FTextField`)**:
       - Label: `Email đăng nhập`
       - Prefix Icon: `HugeIcons.strokeRoundedMail01`
       - Placeholder: `name@example.com`
       - Keyboard: `TextInputType.emailAddress`
     - **Mật khẩu Input (`FTextField`)**:
       - Label: `Mật khẩu`
       - Prefix Icon: `HugeIcons.strokeRoundedLockPassword`
       - Suffix Action: Nút ẩn/hiện mật khẩu (`HugeIcons.strokeRoundedView` / `ViewOffSlash`)
     - **Quên mật khẩu**:
       - Nút text canh phải: `Quên mật khẩu?` (`Roboto Slab Medium 13px, #18181B`) $\rightarrow$ Điều hướng `ForgotPasswordPage`.
  3. **Hành động & Trạng thái lỗi**:
     - Nút `Đăng nhập` (`FButton.primary`, full width, height 48px):
       - Trạng thái bình thường: `Đăng nhập`
       - Trạng thái loading: Spinner Forui trắng mờ, vô hiệu hóa touch.
     - **Xử lý mã lỗi từ Backend**:
       - `INVALID_CREDENTIALS` (401): Hiển thị thông báo *"Email hoặc mật khẩu không chính xác"*.
       - `EMAIL_NOT_VERIFIED` (403): Hiển thị banner cảnh báo kèm nút `[ Kích hoạt ngay ]` $\rightarrow$ Chuyển sang `VerifyEmailOtpPage` kèm email đã điền.
       - `RATE_LIMITED` (429): Hiển thị Banner đỏ cảnh báo *"Tài khoản tạm khóa do nhập sai 5 lần. Vui lòng thử lại sau: 14:59s"* kèm đồng hồ đếm ngược real-time.
  4. **Footer**:
     - Dòng chuyển đổi: `Chưa có tài khoản? ` + **`Đăng ký ngay`** (Bold link).

---

### 3.3. Sign Up Screen (`sign_up_page.dart`)

* **Mục đích**: Thu thập thông tin đăng ký bắt buộc: Họ tên, Email, Số điện thoại Việt Nam và Mật khẩu.
* **Bố cục giao diện**:
  1. **Header**:
     - Nút Back.
     - Tiêu đề: `Tạo tài khoản` (`Roboto Slab Bold 22px`).
     - Phụ đề: `Bắt đầu chia tiền thông minh và quản lý chi tiêu nhóm` (`13px, #71717A`).
  2. **Form Nhập Liệu**:
     - **Họ và tên (`FTextField`)**:
       - Prefix: `HugeIcons.strokeRoundedUser`
       - Placeholder: `Nguyễn Văn A` (Tối đa 100 ký tự).
     - **Email (`FTextField`)**:
       - Prefix: `HugeIcons.strokeRoundedMail01`
       - Placeholder: `nguyenvana@gmail.com`
     - **Số điện thoại (`FTextField`)**:
       - Prefix: `+84` badge cố định hoặc icon `HugeIcons.strokeRoundedSmartPhone01`.
       - Placeholder: `0912 345 678`
       - Helper text: `Dùng để nhận diện thành viên trong nhóm chi tiêu`.
     - **Mật khẩu (`FTextField`)**:
       - Prefix: `HugeIcons.strokeRoundedLockPassword`
       - Suffix: Ẩn/Hiện mật khẩu.
     - **Hộp kiểm tra độ mạnh mật khẩu (Live Password Checklist Card)**:
       - Thẻ `FCard.subtle` hiển thị 4 tiêu chí:
         - [ ] Ít nhất 8 ký tự (tối đa 72)
         - [ ] Có ít nhất 1 chữ cái in hoa (A-Z)
         - [ ] Có ít nhất 1 chữ cái in thường (a-z)
         - [ ] Có ít nhất 1 chữ số (0-9)
       *(Mỗi tiêu chí tự đổi sang icon tick xanh khi người dùng gõ đạt)*.
  3. **Điều khoản sử dụng**:
     - Checkbox: `Tôi đồng ý với Điều khoản dịch vụ & Chính sách bảo mật của PaySplit`.
  4. **Nút Hành động**:
     - Nút `Tiếp tục & Nhận mã OTP` (`FButton.primary`):
       - Bị `disabled` nếu chưa điền đủ hoặc mật khẩu chưa đạt checklist.
       - Khi gọi `POST /api/v1/auth/sign-up` thành công (201) $\rightarrow$ Tự động chuyển sang `VerifyEmailOtpPage`.
     - **Lỗi Backend**:
       - `EMAIL_EXISTS` (409): *"Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác"*.
       - `PHONE_EXISTS` (409): *"Số điện thoại này đã được đăng ký"*.

---

### 3.4. Email OTP Verification Screen (`verify_email_otp_page.dart`)

* **Mục đích**: Nhập mã OTP 6 số được gửi qua Gmail SMTP để kích hoạt tài khoản.
* **Bố cục giao diện**:
  1. **Header & Hướng dẫn**:
     - Icon minh họa: `HugeIcons.strokeRoundedMailValidation01` (Kích thước 48px, viền tròn zinc).
     - Tiêu đề: `Xác thực Email` (`Roboto Slab Bold 22px`).
     - Đoạn văn: `Mã xác thực 6 chữ số đã được gửi tới email:`  
       👉 **`hoangnam@gmail.com`** (`Roboto Slab SemiBold 14px, #18181B`).
  2. **Widget Nhập OTP 6 Số (6-Box PIN Input)**:
     - 6 ô vuông kích thước `48x54px`, bo góc `8px`, viền `1px solid #E4E4E7`.
     - Trạng thái Focus: Viền đậm `#18181B` dày 1.5px.
     - Tự động nhận diện OTP từ tin nhắn / email clipboard (Paste 1 chạm).
     - Khi gõ đủ 6 số $\rightarrow$ Tự động kích hoạt gọi API `POST /api/v1/auth/verify-email`.
  3. **Bộ đếm gửi lại & Cảnh báo số lần thử**:
     - **Cảnh báo lượt thử còn lại**:
       - *"Mã OTP có hiệu lực trong 10 phút. Tối đa 5 lần nhập sai."*
       - Khi nhập sai: Hiển thị dòng đỏ *"Mã OTP không chính xác. Bạn còn 3 lần thử."*.
     - **Đếm ngược gửi lại mã (Resend Timer)**:
       - Khi vừa vào: `Gửi lại mã sau (58s)` (Nút màu xám nhạt disabled).
       - Khi hết 60s: Nút đổi thành `[ Gửi lại mã OTP ]` (Active link).
       - Khi bấm gửi lại: Gọi `POST /api/v1/auth/resend-verification` $\rightarrow$ Reset đồng hồ về 60s.
  4. **Nút Xác nhận & Luồng điều hướng hoàn tất**:
     - Nút `Xác nhận tài khoản` (`FButton.primary`).
     - **Khi xác thực OTP thành công (HTTP 200)**:
       - **Trường hợp từ luồng Đăng ký (Sign Up Flow)**: Ứng dụng tự động lấy thông tin đăng ký (email, mật khẩu) đã lưu tạm trong bộ nhớ phiên đăng ký để kích hoạt ngầm `POST /api/v1/auth/sign-in` $\rightarrow$ Nhận và lưu trữ cặp Access Token / Refresh Token vào `TokenStorage` $\rightarrow$ Hiển thị Toast thông báo *"Chào mừng bạn đến với PaySplit!"* và **chuyển thẳng vào Trang chủ (`HomePage` - `/home`)**, người dùng bắt đầu sử dụng app ngay mà không phải gõ lại mật khẩu.
       - **Trường hợp từ luồng kích hoạt tài khoản cũ (Pending User)**: Hiển thị Dialog chúc mừng và chuyển về màn hình `SignInPage` với email được điền sẵn.

---

### 3.5. Forgot Password Screen (`forgot_password_page.dart`)

* **Mục đích**: Nhập email để yêu cầu cấp mã OTP khôi phục mật khẩu.
* **Bố cục giao diện**:
  1. **Header**:
     - Nút Back.
     - Tiêu đề: `Quên mật khẩu` (`Roboto Slab Bold 22px`).
     - Phụ đề: `Nhập địa chỉ email tài khoản của bạn. Chúng tôi sẽ gửi mã OTP 6 số để đặt lại mật khẩu.`
  2. **Form Nhập Email**:
     - `FTextField` Email có prefix `HugeIcons.strokeRoundedMail01`.
  3. **Nút Gửi yêu cầu**:
     - Nút `Gửi mã khôi phục` (`FButton.primary`).
     - Gọi `POST /api/v1/auth/forgot-password` (Backend trả về 202 Accepted chung cho mọi email để bảo mật).
     - Thành công $\rightarrow$ Chuyển thẳng sang `ResetPasswordPage` kèm email đã nhập sẵn.

---

### 3.6. Reset Password Screen (`reset_password_page.dart`)

* **Mục đích**: Nhập mã OTP nhận được từ email và nhập mật khẩu mới.
* **Bố cục giao diện**:
  1. **Header**:
     - Tiêu đề: `Đặt lại mật khẩu mới` (`Roboto Slab Bold 22px`).
     - Subtext: `Nhập mã OTP 6 số gửi về email và thiết lập mật khẩu mới cho tài khoản.`
  2. **Form Đặt Lại Mật Khẩu**:
     - **Email hiển thị**: Ô email readonly có badge khóa (`Locked`).
     - **Mã OTP 6 số**: Widget 6 ô vuông OTP hoặc 1 ô `FTextField` chuyên biệt.
     - **Mật khẩu mới (`FTextField`)**: Kèm checklist độ mạnh mật khẩu (như màn Sign Up).
     - **Xác nhận mật khẩu mới (`FTextField`)**: Báo lỗi ngay nếu không khớp với mật khẩu mới.
  3. **Nút Cập nhật & Xử lý phản hồi**:
     - Nút `Lưu mật khẩu mới` (`FButton.primary`).
     - Khi bấm: Gọi `POST /api/v1/auth/reset-password` (body: `email`, `otp`, `new_password`).
     - Trạng thái loading: Spinner Forui trắng mờ, vô hiệu hóa touch.
     - Lỗi `INVALID_OR_EXPIRED_TOKEN` (400): Hiển thị thông báo đỏ *"Mã OTP không đúng hoặc đã hết hạn"*.

  4. **Màn hình tiếp theo sau khi Đặt lại Mật khẩu thành công (Next Screen Handoff)**:
     - **Màn hình đích**: Điều hướng về **Màn hình Đăng nhập (`SignInPage` - route `/sign-in`)**, đồng thời xóa sạch ngăn xếp điều hướng (clear backstack) để người dùng không bấm Back quay lại màn reset password được.
     - **Trạng thái truyền theo (Navigation Arguments / State)**:
       - `email`: Tự động điền sẵn email vừa đặt lại mật khẩu vào ô Email của `SignInPage`.
       - `resetSuccess: true`: Kích hoạt hiển thị **Banner Thông Báo Xanh Ngọc** (`FBadge.success` / Banner Forui) nổi bật phía trên form:
         > *"🎉 Đặt lại mật khẩu thành công! Vui lòng đăng nhập với mật khẩu mới."*
       - **Auto-focus**: Con trỏ tự động nhảy vào ô `Mật khẩu` và bàn phím mở sẵn để người dùng gõ mật khẩu mới vừa tạo và bấm `Đăng nhập` ngay.
     - **Lý do thiết kế**: API `POST /api/v1/auth/reset-password` trả về HTTP `204 No Content` và thu hồi toàn bộ session token cũ trên toàn bộ thiết bị. Việc điều hướng về `SignInPage` với email điền sẵn và focus vào ô mật khẩu giúp người dùng thiết lập phiên làm việc mới an toàn và chuẩn xác nhất.

---

## 4. Bảng Ánh Xạ Mã Lỗi Backend Sang Thông Điệp UI

Để đảm bảo trải nghiệm người dùng tự nhiên và không lộ lỗi kỹ thuật (Anti-AI-slop), toàn bộ mã lỗi từ backend được dịch sang tiếng Việt chuẩn:

| Mã lỗi Backend (`code`) | HTTP Status | Thông báo hiển thị trên giao diện người dùng |
| :--- | :--- | :--- |
| `VALIDATION_FAILED` | 400 | "Dữ liệu nhập chưa đúng định dạng. Vui lòng kiểm tra lại." |
| `INVALID_OR_EXPIRED_TOKEN` | 400 | "Mã OTP không đúng hoặc đã hết hạn. Vui lòng thử lại hoặc gửi lại mã mới." |
| `INVALID_CREDENTIALS` | 401 | "Email hoặc mật khẩu không chính xác." |
| `EMAIL_NOT_VERIFIED` | 403 | "Tài khoản của bạn chưa được kích hoạt. Hãy xác thực email để tiếp tục." |
| `ACCOUNT_UNAVAILABLE` | 403 | "Tài khoản đang bị tạm khóa hoặc đình chỉ. Vui lòng liên hệ quản trị viên." |
| `EMAIL_EXISTS` | 409 | "Email này đã được đăng ký. Bạn có muốn đăng nhập không?" |
| `PHONE_EXISTS` | 409 | "Số điện thoại này đã gắn với một tài khoản khác." |
| `RATE_LIMITED` | 429 | "Bạn đã thực hiện thao tác quá nhiều lần. Vui lòng đợi {giây}s trước khi thử lại." |
| `NETWORK_ERROR` | 503 / 0 | "Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng của bạn." |

---

## 5. Cấu Trúc Thư Mục Triển Khai (Frontend Architecture)

Các file sẽ được xây dựng theo kiến trúc Feature-First Clean Architecture trong thư mục `PaySplit-FE/lib/features/auth/`:

```text
PaySplit-FE/lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_data_source.dart      # Retrofit client gọi API backend
│   ├── models/
│   │   ├── sign_in_request_dto.dart          # Freezed DTOs
│   │   ├── sign_up_request_dto.dart
│   │   └── auth_response_dto.dart
│   └── repositories/
│       └── auth_repository_impl.dart         # Triển khai AuthRepository & lưu Token
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart                  # Entity người dùng thuần Dart
│   │   └── session_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart              # Interface cổng giao tiếp
│   └── usecases/
│       ├── sign_in_usecase.dart
│       ├── sign_up_usecase.dart
│       ├── verify_email_usecase.dart
│       ├── resend_otp_usecase.dart
│       └── reset_password_usecase.dart
└── presentation/
    ├── providers/
    │   ├── auth_notifier.dart                # Riverpod StateNotifier quản lý trạng thái
    │   └── auth_state.dart                   # Sealed class trạng thái (Initial, Loading, Authenticated, Unverified...)
    ├── pages/
    │   ├── welcome_page.dart                 # Màn hình chào mừng
    │   ├── sign_in_page.dart                 # Màn hình đăng nhập
    │   ├── sign_up_page.dart                 # Màn hình đăng ký
    │   ├── verify_email_otp_page.dart        # Màn hình nhập OTP xác thực
    │   ├── forgot_password_page.dart         # Màn hình quên mật khẩu
    │   └── reset_password_page.dart          # Màn hình đặt lại mật khẩu
    └── widgets/
        ├── otp_pin_input_widget.dart         # Widget 6 ô vuông OTP
        ├── password_strength_checklist.dart  # Widget checklist độ mạnh mật khẩu
        └── rate_limit_countdown_badge.dart   # Widget đếm lùi thời gian khóa/gửi lại
```

---

## 6. Kế Hoạch Kiểm Thử Giao Diện (UI Verification Plan)

1. **Unit & Widget Test**:
   - `test/features/auth/widgets/otp_pin_input_test.dart`: Kiểm tra nhận đủ 6 số, paste từ clipboard.
   - `test/features/auth/widgets/password_checklist_test.dart`: Kiểm tra đổi màu tick khi gõ đúng điều kiện.
   - `test/features/auth/pages/sign_in_page_test.dart`: Kiểm tra hiển thị countdown khi gặp lỗi 429 Rate Limited.
2. **Manual UX Walkthrough**:
   - Đi toàn bộ luồng: Welcome $\rightarrow$ Sign Up $\rightarrow$ Nhập OTP $\rightarrow$ Kích hoạt thành công $\rightarrow$ Sign In $\rightarrow$ Lưu Session $\rightarrow$ Mở Trang chủ.
   - Kiểm tra thử sai: Nhập sai OTP 5 lần $\rightarrow$ Kiểm tra thông báo mã hết hạn.
