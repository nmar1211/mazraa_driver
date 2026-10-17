import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/home/home_screen.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/shared/widgets/map_panel.dart';

class DriverMapOverviewScreen extends ConsumerWidget {
  const DriverMapOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipments = ref.watch(shipmentsProvider);
    final position = ref.watch(currentPositionProvider);
    final active = shipments.asData?.value
        .where((shipment) => shipment.status.isActive)
        .toList(growable: false);
    final shipment = active == null || active.isEmpty ? null : active.first;
    final driver = position.asData?.value;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      appBar: AppBar(
        title: const Text('الخريطة'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(currentPositionProvider);
              ref.invalidate(shipmentsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPositionProvider);
          ref.invalidate(shipmentsProvider);
          await Future.wait([
            ref.read(currentPositionProvider.future),
            ref.read(shipmentsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            MapPanel(
              height: 440,
              driver: driver == null
                  ? null
                  : GeoPoint(driver.latitude, driver.longitude),
              store: shipment?.storeLocation,
              customer: shipment?.customerLocation,
              onLocate: () => ref.invalidate(currentPositionProvider),
            ),
            const SizedBox(height: 14),
            Text(
              shipment == null
                  ? 'تُعرض هنا إحداثيات السائق الحقيقية من الجهاز. لا توجد شحنة نشطة لعرض مسارها الآن.'
                  : 'الخريطة تعرض موقع السائق ونقطتي الاستلام والتسليم للشحنة ${shipment.number} من بيانات السيرفر.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
