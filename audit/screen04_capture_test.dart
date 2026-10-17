import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/shell/app_shell.dart';
import 'package:mazraa_driver/features/shipments/available_orders_screen.dart';
import 'package:mazraa_driver/features/shipments/driver_offer_feed.dart';

DriverOfferCard _offer({
  required int id,
  required String farm,
  required String district,
  required double pickupKm,
  required double routeKm,
  required int eta,
  required double earning,
  required bool isNew,
}) {
  return DriverOfferCard(
    offerId: id,
    shipmentId: 400 + id,
    shipmentNumber: 'SHP-$id',
    storeId: id,
    pickupName: farm,
    pickupAddress: 'الرياض',
    destinationDistrict: district,
    destinationCity: 'الرياض',
    destinationStreet: null,
    distanceToPickupKm: pickupKm,
    routeDistanceKm: routeKm,
    estimatedMinutes: eta,
    deliveryEarnings: earning,
    currency: 'SAR',
    offeredAt: DateTime(2026, 10, 17, 10),
    expiresAt: DateTime(2026, 10, 17, 10, 5),
    secondsRemaining: 240,
    round: 1,
    isNew: isNew,
  );
}

void main() {
  testWidgets('capture production screen 04 at reference aspect ratio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final feed = DriverOfferFeed(
      locationLabel: 'الرياض',
      offers: [
        _offer(
          id: 1,
          farm: 'مزرعة الوادي',
          district: 'حي النرجس',
          pickupKm: 2.4,
          routeKm: 8.2,
          eta: 45,
          earning: 35,
          isNew: true,
        ),
        _offer(
          id: 2,
          farm: 'مزرعة النخيل',
          district: 'حي الربيع',
          pickupKm: 3.1,
          routeKm: 10.5,
          eta: 50,
          earning: 42,
          isNew: true,
        ),
        _offer(
          id: 3,
          farm: 'مزرعة الخير',
          district: 'حي الياسمين',
          pickupKm: 4.3,
          routeKm: 12,
          eta: 55,
          earning: 48,
          isNew: false,
        ),
        _offer(
          id: 4,
          farm: 'مشتل الرياض',
          district: 'حي الصحافة',
          pickupKm: 5.2,
          routeKm: 14.1,
          eta: 60,
          earning: 55,
          isNew: false,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverOfferFeedProvider.overrideWith((ref) async => feed),
          unreadNotificationsProvider.overrideWith((ref) async => 3),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          home: Scaffold(
            body: const AvailableOrdersScreen(),
            bottomNavigationBar: ReferenceBottomNavigation(
              currentBranch: 1,
              offerCount: feed.offers.length,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screen04_actual.png'),
    );
  });
}
