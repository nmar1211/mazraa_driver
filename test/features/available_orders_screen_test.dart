import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/shipments/available_orders_screen.dart';
import 'package:mazraa_driver/features/shipments/driver_offer_feed.dart';

Widget _screen(DriverOfferFeed feed) {
  return ProviderScope(
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
      home: const AvailableOrdersScreen(),
    ),
  );
}

DriverOfferCard _offer({
  required int offerId,
  required String pickupName,
  required double pickupDistance,
  required double routeDistance,
  required double earning,
  required bool isNew,
}) {
  return DriverOfferCard(
    offerId: offerId,
    shipmentId: 100 + offerId,
    shipmentNumber: 'SHP-$offerId',
    storeId: offerId,
    pickupName: pickupName,
    pickupAddress: 'طريق المزرعة، الرياض',
    destinationDistrict: 'حي النرجس',
    destinationCity: 'الرياض',
    destinationStreet: 'شارع الاختبار',
    distanceToPickupKm: pickupDistance,
    routeDistanceKm: routeDistance,
    estimatedMinutes: 45 + offerId,
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
  final feed = DriverOfferFeed(
    locationLabel: 'الرياض',
    offers: [
      _offer(
        offerId: 1,
        pickupName: 'مزرعة الوادي',
        pickupDistance: 5.2,
        routeDistance: 12.4,
        earning: 35,
        isNew: true,
      ),
      _offer(
        offerId: 2,
        pickupName: 'مزرعة النخيل',
        pickupDistance: 1.1,
        routeDistance: 8.2,
        earning: 21,
        isNew: true,
      ),
      _offer(
        offerId: 3,
        pickupName: 'مزرعة الخير',
        pickupDistance: 3.0,
        routeDistance: 10,
        earning: 52,
        isNew: false,
      ),
    ],
  );

  testWidgets('screen 04 renders server offer feed and reference controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen(feed));
    await tester.pumpAndSettle();

    expect(find.text('الطلبات المتاحة'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('قريبة مني'), findsOneWidget);
    expect(find.text('الأعلى ربحاً'), findsOneWidget);
    expect(find.text('الرياض'), findsWidgets);
    expect(find.text('مزرعة الوادي'), findsOneWidget);
    expect(find.text('مزرعة النخيل'), findsOneWidget);
    expect(find.text('35 ر.س'), findsOneWidget);
    expect(find.text('52 ر.س'), findsOneWidget);
    expect(find.textContaining('لا توجد واجهة عروض متاحة'), findsNothing);
  });

  testWidgets('nearby and earning filters reorder real server offers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen(feed));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قريبة مني'));
    await tester.pumpAndSettle();
    final nearTop = tester.getTopLeft(find.text('مزرعة النخيل')).dy;
    final farTop = tester.getTopLeft(find.text('مزرعة الوادي')).dy;
    expect(nearTop, lessThan(farTop));

    await tester.tap(find.text('الأعلى ربحاً'));
    await tester.pumpAndSettle();
    final highTop = tester.getTopLeft(find.text('مزرعة الخير')).dy;
    final lowerTop = tester.getTopLeft(find.text('مزرعة الوادي')).dy;
    expect(highTop, lessThan(lowerTop));
  });

  testWidgets('view order opens details from the same server model', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen(feed));
    await tester.pumpAndSettle();

    await tester.tap(find.text('عرض الطلب').first);
    await tester.pumpAndSettle();

    expect(find.text('SHP-1'), findsOneWidget);
    expect(find.text('مزرعة الوادي'), findsWidgets);
    expect(find.text('حي النرجس، الرياض'), findsWidgets);
    expect(find.text('12.4 كم'), findsOneWidget);
    expect(find.text('35 ر.س'), findsWidgets);
    expect(find.text('قبول الطلب'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
  });
}
