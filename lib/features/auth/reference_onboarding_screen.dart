import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

/// Screen 01 rebuilt against refrinces/screens/01_onboarding.png.
///
/// The reference screenshot is only used as the source for the decorative hero
/// and foliage crops. Text, cards and all interactive controls remain real
/// Flutter widgets so navigation and accessibility are not flattened into an
/// image.
class ReferenceOnboardingScreen extends StatefulWidget {
  const ReferenceOnboardingScreen({super.key});

  @override
  State<ReferenceOnboardingScreen> createState() =>
      _ReferenceOnboardingScreenState();
}

class _ReferenceOnboardingScreenState extends State<ReferenceOnboardingScreen> {
  static const _reference = 'refrinces/screens/01_onboarding.png';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboardingScreen'),
      backgroundColor: const Color(0xFFFDFCF4),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              height: 640,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFFDFCF4)),
                  ),
                  // Exact decorative pieces cropped from the canonical visual.
                  const Positioned(
                    left: 0,
                    top: 155,
                    width: 360,
                    height: 258,
                    child: _ReferenceCrop(
                      asset: _reference,
                      sourceLeft: 0,
                      sourceTop: 620,
                      sourceWidth: 1440,
                      sourceHeight: 1030,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 555,
                    width: 130,
                    height: 85,
                    child: _ReferenceCrop(
                      asset: _reference,
                      sourceLeft: 0,
                      sourceTop: 2220,
                      sourceWidth: 520,
                      sourceHeight: 340,
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 545,
                    width: 122.5,
                    height: 95,
                    child: _ReferenceCrop(
                      asset: _reference,
                      sourceLeft: 950,
                      sourceTop: 2180,
                      sourceWidth: 490,
                      sourceHeight: 380,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: TextButton.icon(
                      key: const Key('onboardingSkipButton'),
                      onPressed: _goLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0B5B3A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      label: const Text(
                        'تخطي',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 153,
                    top: 26,
                    width: 54,
                    height: 54,
                    child: Image.asset(
                      ReferenceAssets.brandLeaf,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    right: 18,
                    top: 94,
                    child: Text(
                      'خلك شريك التوصيل الأفضل',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0xFF0B5435),
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    right: 18,
                    top: 137,
                    child: Text(
                      'وصل الخير... واربح أكثر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF71776C),
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 14,
                    right: 14,
                    top: 389,
                    height: 116,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: _BenefitCard(
                            icon: Icons.location_on_rounded,
                            iconColor: Color(0xFF075B3A),
                            iconBackground: Color(0xFFEAF3E8),
                            title: 'مرونة في العمل',
                            subtitle: 'اختر الأوقات\nالمناسبة لك',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _BenefitCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: Color(0xFFD9632C),
                            iconBackground: Color(0xFFFBE8DD),
                            title: 'تربح أكثر',
                            subtitle: 'مكافآت ومزايا\nمجزية',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _BenefitCard(
                            icon: Icons.spa_rounded,
                            iconColor: Color(0xFF075B3A),
                            iconBackground: Color(0xFFEAF3E8),
                            title: 'توصل منتجات\nمحلية طازجة',
                            subtitle: 'تساهم في دعم\nالمزارعين المحليين',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 518,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Color(0xFF0E6A3F), Color(0xFF07512F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          key: const Key('onboardingStartButton'),
                          onTap: _goLogin,
                          borderRadius: BorderRadius.circular(16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ابدأ الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 14),
                              Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 95,
                    right: 95,
                    top: 574,
                    height: 30,
                    child: TextButton(
                      key: const Key('onboardingExistingAccountButton'),
                      onPressed: _goLogin,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF0B5B3A),
                      ),
                      child: const Text(
                        'لدي حساب بالفعل',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 613,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        _PageDot(active: true),
                        SizedBox(width: 8),
                        _PageDot(),
                        SizedBox(width: 8),
                        _PageDot(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF8).withValues(alpha: .97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B5435),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF0B5435),
              fontSize: 12.2,
              height: 1.08,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF777B72),
              fontSize: 9.8,
              height: 1.12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF0A6A3D) : const Color(0xFFD8D9D0),
      ),
    );
  }
}

/// Shows a rectangular crop of a 1440x2560 canonical screenshot while keeping
/// the rest of the screen as live Flutter UI.
class _ReferenceCrop extends StatelessWidget {
  const _ReferenceCrop({
    required this.asset,
    required this.sourceLeft,
    required this.sourceTop,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final String asset;
  final double sourceLeft;
  final double sourceTop;
  final double sourceWidth;
  final double sourceHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / sourceWidth;
        final scaleY = constraints.maxHeight / sourceHeight;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 1440 * scaleX,
            maxWidth: 1440 * scaleX,
            minHeight: 2560 * scaleY,
            maxHeight: 2560 * scaleY,
            child: Transform.translate(
              offset: Offset(-sourceLeft * scaleX, -sourceTop * scaleY),
              child: Image.asset(
                asset,
                width: 1440 * scaleX,
                height: 2560 * scaleY,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );
      },
    );
  }
}
