import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _items = const [
    _OnboardingData(
      title: 'QUÉT HÓA ĐƠN AI',
      desc: 'Quét hóa đơn bằng camera để tự động\nnhận diện danh mục và số tiền.',
      type: _OnboardingType.ocr,
    ),
    _OnboardingData(
      title: 'CHIA TIỀN NHÓM',
      desc: 'Dễ dàng tạo nhóm, thêm thành viên\nvà quản lý việc chia tiền.',
      type: _OnboardingType.group,
    ),
    _OnboardingData(
      title: 'THANH TOÁN VIETQR',
      desc: 'Thanh toán tức thì và chính xác qua\nmã VietQR một chạm.',
      type: _OnboardingType.vietqr,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : const Color(0xFF0F766E);
    final bg = isDark ? AppColors.darkPaper : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Soft Organic Curved Background
          Positioned.fill(
            child: CustomPaint(
              painter: _CurvedBackgroundPainter(isDark: isDark),
            ),
          ),

          // 2. Main Page Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Carousel Section
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Title (Bold Uppercase Deep Teal)
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F766E),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Description (Centered 2-line gray text)
                            Text(
                              item.desc,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Center Hero Mockup (FittedBox prevents overflow on small devices)
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: switch (item.type) {
                                    _OnboardingType.ocr => _buildOcrMockup(isDark),
                                    _OnboardingType.group => _buildGroupMockup(isDark),
                                    _OnboardingType.vietqr => _buildVietQrMockup(isDark),
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation: Dots Indicator + Circular Arrow Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 36, top: 8),
                  child: Column(
                    children: [
                      // 3 Pagination Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_items.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? primary : const Color(0xFFCBD5E1),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),

                      // Circular Action Arrow Button (Gradient Teal/Emerald)
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.38),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 1: Phone with Camera scanning Starbucks receipt (Quét hóa đơn AI)
  // ===========================================================================
  Widget _buildOcrMockup(bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Soft mint rounded background card behind phone
        Container(
          width: 270,
          height: 250,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF182823) : const Color(0xFFD7F4ED),
            borderRadius: BorderRadius.circular(32),
          ),
        ),

        // Smartphone Frame
        Container(
          width: 178,
          height: 330,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFF374151), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dynamic island / top pill notch
              Container(
                width: 44,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Camera viewfinder screen with Starbucks receipt
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // White Starbucks receipt inside viewfinder
                      Container(
                        width: 126,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Starbucks Mermaid Logo
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF006241),
                              ),
                              child: const Center(
                                child: Icon(Icons.star, size: 14, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'STARBUCKS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(height: 2, width: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 2),
                            Container(height: 2, width: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 6),
                            // Localized total
                            Text(
                              'Tổng cộng: 450.200đ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Barcode lines
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(14, (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: i % 3 == 0 ? 2.5 : 1.5,
                                height: 10,
                                color: Colors.black87,
                              )),
                            ),
                          ],
                        ),
                      ),

                      // Green OCR corner scan brackets around receipt
                      Positioned(
                        top: 16,
                        left: 14,
                        child: _buildCornerBracket(top: true, left: true),
                      ),
                      Positioned(
                        top: 16,
                        right: 14,
                        child: _buildCornerBracket(top: true, left: false),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 14,
                        child: _buildCornerBracket(top: false, left: true),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 14,
                        child: _buildCornerBracket(top: false, left: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Camera shutter & controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ẢNH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.cached, size: 16, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        // Floating Localized Pill Badge horizontally crossing the phone
        Positioned(
          bottom: 75,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Starbucks | Tổng: 450.000đ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F766E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF10B981), width: 2.5) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF10B981), width: 2.5) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF10B981), width: 2.5) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF10B981), width: 2.5) : BorderSide.none,
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 2: Group member split tiles (Chia tiền nhóm)
  // ===========================================================================
  Widget _buildGroupMockup(bool isDark) {
    return Center(
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMemberTile(
                    name: 'Tuấn',
                    amount: '40.000đ',
                    statusText: 'Đã trả',
                    bottomLabel: 'Đã thanh toán',
                    isPaid: true,
                    avatarLetter: 'T',
                    avatarColor: const Color(0xFF10B981),
                    progress: 1.0,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMemberTile(
                    name: 'Linh',
                    amount: '20.000đ',
                    statusText: 'Chờ trả',
                    bottomLabel: 'Chờ thanh toán',
                    isPaid: false,
                    avatarLetter: 'L',
                    avatarColor: const Color(0xFF818CF8),
                    progress: 0.5,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMemberTile(
                    name: 'Minh',
                    amount: '10.000đ',
                    statusText: 'Chờ trả',
                    bottomLabel: 'Chờ thanh toán',
                    isPaid: false,
                    avatarLetter: 'M',
                    avatarColor: const Color(0xFF38BDF8),
                    progress: 0.25,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMemberTile(
                    name: 'Trang',
                    amount: '30.000đ',
                    statusText: 'Chờ trả',
                    bottomLabel: 'Chờ thanh toán',
                    isPaid: false,
                    avatarLetter: 'T',
                    avatarColor: const Color(0xFFC084FC),
                    progress: 0.75,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile({
    required String name,
    required String amount,
    required String statusText,
    required String bottomLabel,
    required bool isPaid,
    required String avatarLetter,
    required Color avatarColor,
    required double progress,
    required bool isDark,
  }) {
    final bgColor = isPaid
        ? (isDark ? const Color(0xFF183329) : const Color(0xFFE6F8F3))
        : (isDark ? AppColors.darkSurface : Colors.white);

    final borderColor = isPaid
        ? const Color(0xFFA7F3D0)
        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Avatar + Name/Status + Badge
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: avatarColor.withValues(alpha: 0.2),
                child: Text(
                  avatarLetter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: avatarColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Name and status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMain : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      statusText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPaid ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark badge for paid
              if (isPaid)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Info: Label + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bottomLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: isPaid ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMain : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF2C352D) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 3: VietQR Dynamic Code + Hoàn Tất Button (Thanh toán VietQR)
  // ===========================================================================
  Widget _buildVietQrMockup(bool isDark) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // VietQR Header Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Red swoosh logo mark
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDC2626),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_forward, size: 9, color: Colors.white),
                ),
              ),
              Text(
                'VIET',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFDC2626),
                ),
              ),
              Text(
                'QR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // QR Code with green scan corners & PaySplit P icon in center
          Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 4 Green Corner Scan Brackets
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildQrCornerBracket(top: true, left: true),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildQrCornerBracket(top: true, left: false),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildQrCornerBracket(top: false, left: true),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildQrCornerBracket(top: false, left: false),
                ),

                // QR Matrix
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 110,
                  color: Color(0xFF0F172A),
                ),

                // Center PaySplit App Logo
                Container(
                  width: 26,
                  height: 26,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payee Info (Localized to Vietnamese)
          Text(
            'Thông tin người nhận',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Nhóm Liên Hoan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMain : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '450.000đ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 14),

          // Hoàn tất Action Pill Button
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Hoàn tất',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCornerBracket({required bool top, required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF059669), width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF059669), width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF059669), width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF059669), width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painter for Organic Curved Background
// -----------------------------------------------------------------------------
class _CurvedBackgroundPainter extends CustomPainter {
  final bool isDark;
  _CurvedBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = isDark ? const Color(0xFF14221D) : const Color(0xFFF2FBF8)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.44);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.36,
      size.width,
      size.height * 0.42,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = isDark
          ? const Color(0xFF192A24).withValues(alpha: 0.6)
          : const Color(0xFFE8F7F3).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.54);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.48,
      size.width,
      size.height * 0.56,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _OnboardingType { ocr, group, vietqr }

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.desc,
    required this.type,
  });

  final String title;
  final String desc;
  final _OnboardingType type;
}
