import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/constants/build_flags.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

final currentPositionProvider = FutureProvider<Position>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('خدمة الموقع متوقفة على الجهاز.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('لم يتم منح إذن الموقع.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _statusBusy = false;
  bool _locationBusy = false;

  Future<void> _refresh() async {
    ref.invalidate(shipmentsProvider);
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(unreadNotificationsProvider);
    await ref.read(authControllerProvider).refreshProfile();
    await Future.wait([
      ref.read(shipmentsProvider.future),
      ref.read(walletSummaryProvider.future),
      ref.read(unreadNotificationsProvider.future),
    ]);
  }

  Future<void> _toggleAvailability(DriverProfile profile) async {
    if (_statusBusy) return;
    setState(() => _statusBusy = true);
    try {
      Position? position;
      try {
        position = await ref.read(currentPositionProvider.future);
      } catch (_) {
        // Coordinates are optional for a status change.
      }
      final nextAccepting = !profile.isAcceptingOrders;
      await ref.read(driverApiProvider).updateDriverStatus(
            operationalStatus: nextAccepting ? 3 : 1,
            isAcceptingOrders: nextAccepting,
            latitude: position?.latitude,
            longitude: position?.longitude,
          );
      await ref.read(authControllerProvider).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextAccepting
                  ? 'أصبحت متاحًا لاستقبال الطلبات.'
                  : 'تم إيقاف استقبال الطلبات.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _syncCurrentLocation(
    DriverProfile? profile,
    Shipment? shipment,
  ) async {
    if (_locationBusy || profile == null) return;
    setState(() => _locationBusy = true);
    try {
      ref.invalidate(currentPositionProvider);
      final position = await ref.read(currentPositionProvider.future);
      await ref.read(driverApiProvider).updateDriverStatus(
            operationalStatus: _operationalStatusCode(profile.operationalStatus),
            isAcceptingOrders: profile.isAcceptingOrders,
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (shipment != null) {
        await ref.read(driverApiProvider).updateLocation(
              shipment.id,
              latitude: position.latitude,
              longitude: position.longitude,
              heading: position.heading.isFinite ? position.heading : null,
              speedKph: position.speed.isFinite ? position.speed * 3.6 : null,
              accuracyMeters:
                  position.accuracy.isFinite ? position.accuracy : null,
            );
      }
      await ref.read(authControllerProvider).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shipment == null
                  ? 'تم تحديث موقعك على السيرفر.'
                  : 'تم تحديث موقعك وموقع الشحنة على السيرفر.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final auth = ref.watch(authControllerProvider);
    final shipmentsAsync = ref.watch(shipmentsProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final profile = auth.profile;
    final shipments = shipmentsAsync.valueOrNull ?? const <Shipment>[];
    final active = shipments.where((item) => item.status.isActive).toList();
    final activeShipment = active.isEmpty ? null : active.first;
    final now = DateTime.now();
    final today = shipments.where((item) {
      final date = item.createdAt.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
    final todayIncome = today
        .where((item) => item.status == ShipmentStatus.delivered)
        .fold<double>(0, (sum, item) => sum + item.netProfit);
    final currency = walletAsync.valueOrNull?.currency ?? '';
    final name = _firstName(profile?.name, ar: ar);
    final accepting = profile?.isAcceptingOrders == true;
    final operationalAvailable = BuildFlags.ciSmokeHome
        ? true
        : _isOperationallyAvailable(profile);
    final rating = profile?.ratingAverage ?? 0;
    final unread = unreadAsync.valueOrNull ?? 0;
    final locationLabel = BuildFlags.ciSmokeHome
        ? (ar ? 'الرياض' : 'Riyadh')
        : (ar ? 'موقعي' : 'My location');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            children: [
              _ReferenceHeader(
                unread: unread,
                locationLabel: locationLabel,
                locating: _locationBusy,
                onLocation: () => _syncCurrentLocation(profile, activeShipment),
                onNotifications: () => context.go('/notifications'),
              ),
              const SizedBox(height: 4),
              Text(
                ar ? 'صباح الخير، $name' : 'Good morning, $name',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF073C28),
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.center,
                child: _AvailabilityPill(available: operationalAvailable),
              ),
              const SizedBox(height: 11),
              Text(
                ar ? 'جاهز لطلبك التالي؟' : 'Ready for your next order?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF073C28),
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: MazraaColors.orange,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              _ReferenceMapCard(
                locationLabel: locationLabel,
                shipment: activeShipment,
                locating: _locationBusy,
                onLocate: () => _syncCurrentLocation(profile, activeShipment),
                onDirections: () {
                  if (activeShipment == null) {
                    context.go('/shipments');
                  } else {
                    context.push('/shipments/${activeShipment.id}');
                  }
                },
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: MazraaColors.orange,
                      label: ar ? 'طلبات اليوم' : "Today's orders",
                      value: '${today.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.toll_rounded,
                      iconColor: const Color(0xFF075C3D),
                      label: ar ? 'الدخل' : 'Income',
                      value: _incomeLabel(todayIncome, currency, ar: ar),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.star_rounded,
                      iconColor: MazraaColors.orange,
                      label: ar ? 'التقييم' : 'Rating',
                      value: rating <= 0 ? '—' : rating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: profile == null || _statusBusy
                      ? null
                      : () => _toggleAvailability(profile),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF075A35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 2,
                  ),
                  icon: _statusBusy
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.near_me_rounded, size: 24),
                  label: Text(
                    accepting
                        ? (ar ? 'إيقاف استقبال الطلبات' : 'Stop receiving orders')
                        : (ar ? 'ابدأ استقبال الطلبات' : 'Start receiving orders'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceHeader extends StatelessWidget {
  const _ReferenceHeader({
    required this.unread,
    required this.locationLabel,
    required this.locating,
    required this.onLocation,
    required this.onNotifications,
  });

  final int unread;
  final String locationLabel;
  final bool locating;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: locating ? null : onLocation,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      locating ? Icons.sync_rounded : Icons.location_on_rounded,
                      color: const Color(0xFF075A35),
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      locationLabel,
                      style: const TextStyle(
                        color: Color(0xFF174D39),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 1),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF075A35),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/branding/mazraa_mark.svg',
            width: 48,
            height: 55,
            fit: BoxFit.contain,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: ar ? 'الإشعارات' : 'Notifications',
                      onPressed: onNotifications,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF075A35),
                        size: 28,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: MazraaColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE7E6DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x13000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          ReferenceAssets.driverAvatar,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.48),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14C975),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F6E4) : const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available
                  ? const Color(0xFF11B965)
                  : const Color(0xFF8E948F),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            available
                ? (ar ? 'متاح لاستلام الطلبات' : 'Available for orders')
                : (ar ? 'غير متاح لاستلام الطلبات' : 'Unavailable for orders'),
            style: const TextStyle(
              color: Color(0xFF145439),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceMapCard extends StatelessWidget {
  const _ReferenceMapCard({
    required this.locationLabel,
    required this.shipment,
    required this.locating,
    required this.onLocate,
    required this.onDirections,
  });

  final String locationLabel;
  final Shipment? shipment;
  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return AspectRatio(
      aspectRatio: 1.72,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFE2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7E3D5)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _ReferenceRoadBackdrop(),
            Opacity(
              opacity: .34,
              child: Image.asset(
                'refrinces/assets_primary/by_screen/03/01_asset_home_route_dashboard.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _MapActionButton(
                label: ar ? 'توجيه' : 'Directions',
                onPressed: onDirections,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _SquareMapButton(
                icon: locating ? Icons.sync_rounded : Icons.my_location_rounded,
                onPressed: locating ? null : onLocate,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A673F),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    locationLabel,
                    style: const TextStyle(
                      color: Color(0xFF5C5C58),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (shipment != null)
              Positioned(
                left: 24,
                bottom: 18,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Image.asset(
                    ReferenceAssets.deliveryScooter,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceRoadBackdrop extends StatelessWidget {
  const _ReferenceRoadBackdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RoadPainter());
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final park = Paint()..color = const Color(0xFFDCEACC);
    final street = Paint()
      ..color = Colors.white.withValues(alpha: .88)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final artery = Paint()
      ..color = const Color(0xFFFFD878)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final rect in <Rect>[
      Rect.fromLTWH(size.width * .07, size.height * .10, size.width * .22,
          size.height * .24),
      Rect.fromLTWH(size.width * .59, size.height * .08, size.width * .25,
          size.height * .28),
      Rect.fromLTWH(size.width * .12, size.height * .65, size.width * .28,
          size.height * .24),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        park,
      );
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x * .88, size.height), artery);
    }
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y * .92), artery);
    }
    final route = Path()
      ..moveTo(-10, size.height * .73)
      ..cubicTo(size.width * .28, size.height * .56, size.width * .62,
          size.height * .72, size.width + 10, size.height * .37);
    canvas.drawPath(route, street);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.near_me_rounded,
                  color: Color(0xFF075A35), size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF174D39),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareMapButton extends StatelessWidget {
  const _SquareMapButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      elevation: 4,
      child: SizedBox(
        width: 43,
        height: 43,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, color: const Color(0xFF075A35), size: 23),
        ),
      ),
    );
  }
}

class _ReferenceMetricCard extends StatelessWidget {
  const _ReferenceMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 23),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF265B48),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF071B13),
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isOperationallyAvailable(DriverProfile? profile) {
  final status = profile?.operationalStatus.trim().toLowerCase() ?? '';
  return status == 'available' || status == 'online';
}

int _operationalStatusCode(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'online' => 2,
    'available' => 3,
    'busy' => 4,
    _ => 1,
  };
}

String _firstName(String? raw, {required bool ar}) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return ar ? 'سائق مزرعتي' : 'Mazraa driver';
  return value.split(RegExp(r'\s+')).first;
}

String _incomeLabel(double amount, String currency, {required bool ar}) {
  final rounded = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  final normalized = currency.trim().toUpperCase();
  final unit = switch (normalized) {
    'SAR' => ar ? 'ر.س' : 'SAR',
    'YER' => ar ? 'ر.ي' : 'YER',
    'USD' => r'$',
    _ => normalized,
  };
  return unit.isEmpty ? rounded : '$rounded $unit';
}
