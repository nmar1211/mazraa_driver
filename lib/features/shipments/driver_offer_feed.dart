import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';

class DriverOfferFeed {
  const DriverOfferFeed({required this.locationLabel, required this.offers});

  final String? locationLabel;
  final List<DriverOfferCard> offers;

  factory DriverOfferFeed.fromJson(Map<String, dynamic> json) {
    final raw = json['offers'];
    return DriverOfferFeed(
      locationLabel: _text(json['locationLabel']),
      offers: raw is List
          ? raw
                .whereType<Map>()
                .map((item) => DriverOfferCard.fromJson(
                      item.map((key, value) => MapEntry(key.toString(), value)),
                    ))
                .toList(growable: false)
          : const <DriverOfferCard>[],
    );
  }
}

class DriverOfferCard {
  const DriverOfferCard({
    required this.offerId,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.storeId,
    required this.pickupName,
    required this.pickupAddress,
    required this.destinationDistrict,
    required this.destinationCity,
    required this.destinationStreet,
    required this.distanceToPickupKm,
    required this.routeDistanceKm,
    required this.estimatedMinutes,
    required this.deliveryEarnings,
    required this.currency,
    required this.offeredAt,
    required this.expiresAt,
    required this.secondsRemaining,
    required this.round,
    required this.isNew,
  });

  final int offerId;
  final int shipmentId;
  final String shipmentNumber;
  final int? storeId;
  final String pickupName;
  final String? pickupAddress;
  final String? destinationDistrict;
  final String? destinationCity;
  final String? destinationStreet;
  final double? distanceToPickupKm;
  final double? routeDistanceKm;
  final int? estimatedMinutes;
  final double deliveryEarnings;
  final String? currency;
  final DateTime? offeredAt;
  final DateTime? expiresAt;
  final int secondsRemaining;
  final int round;
  final bool isNew;

  factory DriverOfferCard.fromJson(Map<String, dynamic> json) {
    return DriverOfferCard(
      offerId: _integer(json['offerId']),
      shipmentId: _integer(json['shipmentId']),
      shipmentNumber: _text(json['shipmentNumber']) ?? '',
      storeId: _nullableInteger(json['storeId']),
      pickupName: _text(json['pickupName']) ?? '',
      pickupAddress: _text(json['pickupAddress']),
      destinationDistrict: _text(json['destinationDistrict']),
      destinationCity: _text(json['destinationCity']),
      destinationStreet: _text(json['destinationStreet']),
      distanceToPickupKm: _number(json['distanceToPickupKm']),
      routeDistanceKm: _number(json['routeDistanceKm']),
      estimatedMinutes: _nullableInteger(json['estimatedMinutes']),
      deliveryEarnings: _number(json['deliveryEarnings']) ?? 0,
      currency: _text(json['currency']),
      offeredAt: _date(json['offeredAt']),
      expiresAt: _date(json['expiresAt']),
      secondsRemaining: _integer(json['secondsRemaining']),
      round: _integer(json['round']),
      isNew: json['isNew'] == true,
    );
  }

  String get destinationLabel {
    final parts = <String>[
      if (destinationDistrict?.trim().isNotEmpty == true)
        destinationDistrict!.trim(),
      if (destinationCity?.trim().isNotEmpty == true) destinationCity!.trim(),
    ];
    return parts.join('، ');
  }
}

final driverOfferFeedProvider = FutureProvider<DriverOfferFeed>((ref) async {
  final json = await ref
      .read(apiClientProvider)
      .get<Map<String, dynamic>>('api/driver-journey/offer-cards');
  return DriverOfferFeed.fromJson(json);
});

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(dynamic value) => _nullableInteger(value) ?? 0;

int? _nullableInteger(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
