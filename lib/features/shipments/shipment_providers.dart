import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/constants/build_flags.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final shipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  if (BuildFlags.ciSmokeHome) {
    final now = DateTime.now();
    return List<Shipment>.generate(
      8,
      (index) => Shipment(
        id: 9101 + index,
        number: 'SHP-${9101 + index}',
        orderId: 50101 + index,
        driverId: 77,
        customerId: 301 + index,
        status: ShipmentStatus.delivered,
        deliveryFee: 42.75,
        transportCost: 7,
        netProfit: 35.75,
        createdAt: now,
        storeLocation: const GeoPoint(24.7242, 46.6680),
        customerLocation: const GeoPoint(24.7048, 46.6835),
        driverLocation: const GeoPoint(24.7136, 46.6753),
        distanceKm: 4.8,
        etaMinutes: 14,
      ),
    );
  }
  return ref.watch(driverApiProvider).getShipments();
});

final shipmentDetailsProvider = FutureProvider.autoDispose
    .family<Shipment, int>((ref, id) async {
      return ref.watch(driverApiProvider).getShipment(id);
    });

final shipmentTrackingProvider = FutureProvider.autoDispose
    .family<Shipment, int>((ref, id) async {
      return ref.watch(driverApiProvider).getTracking(id);
    });
