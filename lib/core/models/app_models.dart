import 'dart:convert';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.email = '',
    this.role = '',
    this.roles = const [],
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: (json['token'] ?? json['accessToken'] ?? '').toString(),
    refreshToken: (json['refreshToken'] ?? '').toString(),
    userId: _asInt(json['userId']),
    email: (json['email'] ?? '').toString(),
    role: (json['role'] ?? '').toString(),
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    accessTokenExpiresAt: _asDate(json['accessTokenExpiresAt']),
    refreshTokenExpiresAt: _asDate(json['refreshTokenExpiresAt']),
  );

  final String accessToken;
  final String refreshToken;
  final int userId;
  final String email;
  final String role;
  final List<String> roles;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  bool get isUsable =>
      accessToken.isNotEmpty && refreshToken.isNotEmpty && userId > 0;

  Map<String, dynamic> toJson() => {
    'token': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'email': email,
    'role': role,
    'roles': roles,
    'accessTokenExpiresAt': accessTokenExpiresAt?.toIso8601String(),
    'refreshTokenExpiresAt': refreshTokenExpiresAt?.toIso8601String(),
  };

  String encode() => jsonEncode(toJson());
}

class DriverProfile {
  const DriverProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.approvalStatus,
    required this.operationalStatus,
    required this.isAcceptingOrders,
    required this.isVerified,
    required this.ratingAverage,
    required this.ratingCount,
    this.driverCode,
    this.profileImageUrl,
    this.currentLatitude,
    this.currentLongitude,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    userId: _asInt(json['userId']),
    driverCode: json['driverCode']?.toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    vehicleType: _enumLabel(json['vehicleType'], const [
      'Car',
      'Bike',
      'Van',
      'Truck',
    ]),
    approvalStatus: _oneBasedEnumLabel(json['approvalStatus'], const [
      'Pending',
      'Approved',
      'Rejected',
      'Suspended',
    ]),
    operationalStatus: _oneBasedEnumLabel(json['operationalStatus'], const [
      'Offline',
      'Online',
      'Available',
      'Busy',
    ]),
    isAcceptingOrders: json['isAcceptingOrders'] == true,
    isVerified: json['isVerified'] == true,
    ratingAverage: _asDouble(json['ratingAverage']),
    ratingCount: _asInt(json['ratingCount']),
    profileImageUrl: json['profileImageUrl']?.toString(),
    currentLatitude: _asNullableDouble(json['currentLatitude']),
    currentLongitude: _asNullableDouble(json['currentLongitude']),
  );

  final int userId;
  final String? driverCode;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String approvalStatus;
  final String operationalStatus;
  final bool isAcceptingOrders;
  final bool isVerified;
  final double ratingAverage;
  final int ratingCount;
  final String? profileImageUrl;
  final double? currentLatitude;
  final double? currentLongitude;

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
}

enum ShipmentStatus {
  pending,
  inTransit,
  delivered,
  cancelled,
  assigned,
  accepted,
  pickedUp,
  nearCustomer,
  failed,
  unknown,
}

extension ShipmentStatusX on ShipmentStatus {
  bool get isClosed =>
      this == ShipmentStatus.delivered ||
      this == ShipmentStatus.cancelled ||
      this == ShipmentStatus.failed;

  bool get isActive =>
      this == ShipmentStatus.assigned ||
      this == ShipmentStatus.accepted ||
      this == ShipmentStatus.pickedUp ||
      this == ShipmentStatus.inTransit ||
      this == ShipmentStatus.nearCustomer;

  String label(bool arabic) {
    if (!arabic) {
      return switch (this) {
        ShipmentStatus.pending => 'Pending',
        ShipmentStatus.assigned => 'Assigned',
        ShipmentStatus.accepted => 'Accepted',
        ShipmentStatus.pickedUp => 'Picked up',
        ShipmentStatus.inTransit => 'In transit',
        ShipmentStatus.nearCustomer => 'Near customer',
        ShipmentStatus.delivered => 'Delivered',
        ShipmentStatus.cancelled => 'Cancelled',
        ShipmentStatus.failed => 'Failed',
        ShipmentStatus.unknown => 'Unknown',
      };
    }
    return switch (this) {
      ShipmentStatus.pending => 'قيد الانتظار',
      ShipmentStatus.assigned => 'مسندة إليك',
      ShipmentStatus.accepted => 'تم القبول',
      ShipmentStatus.pickedUp => 'تم الاستلام',
      ShipmentStatus.inTransit => 'في الطريق',
      ShipmentStatus.nearCustomer => 'قريب من العميل',
      ShipmentStatus.delivered => 'تم التسليم',
      ShipmentStatus.cancelled => 'ملغاة',
      ShipmentStatus.failed => 'تعذر التسليم',
      ShipmentStatus.unknown => 'غير معروفة',
    };
  }
}

ShipmentStatus parseShipmentStatus(Object? value) {
  const byIndex = [
    ShipmentStatus.pending,
    ShipmentStatus.inTransit,
    ShipmentStatus.delivered,
    ShipmentStatus.cancelled,
    ShipmentStatus.assigned,
    ShipmentStatus.accepted,
    ShipmentStatus.pickedUp,
    ShipmentStatus.nearCustomer,
    ShipmentStatus.failed,
  ];
  if (value is num) {
    final index = value.toInt();
    return index >= 0 && index < byIndex.length
        ? byIndex[index]
        : ShipmentStatus.unknown;
  }
  final normalized = value.toString().replaceAll('_', '').toLowerCase();
  return switch (normalized) {
    'pending' || '0' => ShipmentStatus.pending,
    'intransit' || '1' => ShipmentStatus.inTransit,
    'delivered' || '2' => ShipmentStatus.delivered,
    'cancelled' || 'canceled' || '3' => ShipmentStatus.cancelled,
    'assigned' || '4' => ShipmentStatus.assigned,
    'accepted' || '5' => ShipmentStatus.accepted,
    'pickedup' || '6' => ShipmentStatus.pickedUp,
    'nearcustomer' || '7' => ShipmentStatus.nearCustomer,
    'failed' || '8' => ShipmentStatus.failed,
    _ => ShipmentStatus.unknown,
  };
}

class Shipment {
  const Shipment({
    required this.id,
    required this.number,
    required this.orderId,
    required this.status,
    required this.deliveryFee,
    required this.transportCost,
    required this.netProfit,
    required this.createdAt,
    this.driverId,
    this.customerId,
    this.customerLocation,
    this.storeLocation,
    this.driverLocation,
    this.distanceKm,
    this.etaMinutes,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final shipmentJson = json['shipment'] is Map<String, dynamic>
        ? json['shipment'] as Map<String, dynamic>
        : json;
    return Shipment(
      id: _asInt(shipmentJson['id']),
      number:
          (shipmentJson['shipmentNumber'] ??
                  shipmentJson['number'] ??
                  '#${shipmentJson['id'] ?? ''}')
              .toString(),
      orderId: _asInt(shipmentJson['orderId'] ?? shipmentJson['salesOrderId']),
      driverId: _asNullableInt(shipmentJson['driverId']),
      customerId: _asNullableInt(shipmentJson['customerId']),
      status: parseShipmentStatus(shipmentJson['status']),
      deliveryFee: _asDouble(shipmentJson['deliveryFee']),
      transportCost: _asDouble(shipmentJson['transportCost']),
      netProfit: _asDouble(shipmentJson['netProfit']),
      createdAt: _asDate(shipmentJson['createdAt']) ?? DateTime.now(),
      customerLocation: GeoPoint.fromDynamic(
        shipmentJson['customerLocation'],
        latitude: shipmentJson['customerLatitude'],
        longitude: shipmentJson['customerLongitude'],
      ),
      storeLocation: GeoPoint.fromDynamic(
        shipmentJson['storeLocation'],
        latitude: shipmentJson['storeLatitude'],
        longitude: shipmentJson['storeLongitude'],
      ),
      driverLocation: GeoPoint.fromDynamic(
        json['driverLocation'] ?? shipmentJson['driverLocation'],
      ),
      distanceKm: _asNullableDouble(json['distanceKm']),
      etaMinutes: _asNullableInt(json['etaMinutes']),
    );
  }

  final int id;
  final String number;
  final int orderId;
  final int? driverId;
  final int? customerId;
  final ShipmentStatus status;
  final double deliveryFee;
  final double transportCost;
  final double netProfit;
  final DateTime createdAt;
  final GeoPoint? customerLocation;
  final GeoPoint? storeLocation;
  final GeoPoint? driverLocation;
  final double? distanceKm;
  final int? etaMinutes;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  static GeoPoint? fromDynamic(
    Object? value, {
    Object? latitude,
    Object? longitude,
  }) {
    final map = value is Map<String, dynamic> ? value : null;
    final lat = _asNullableDouble(map?['latitude'] ?? latitude);
    final lng = _asNullableDouble(map?['longitude'] ?? longitude);
    return lat == null || lng == null ? null : GeoPoint(lat, lng);
  }

  final double latitude;
  final double longitude;
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.currency,
    required this.accountNumber,
    required this.monthlyCredits,
    required this.monthlyDebits,
    required this.pendingTopUpBalance,
    required this.canTransfer,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
    balance: _asDouble(json['balance']),
    currency: (json['currency'] ?? 'SAR').toString(),
    accountNumber: (json['accountNumber'] ?? '').toString(),
    monthlyCredits: _asDouble(json['monthlyCredits']),
    monthlyDebits: _asDouble(json['monthlyDebits']),
    pendingTopUpBalance: _asDouble(json['pendingTopUpBalance']),
    canTransfer:
        (json['capabilities'] as Map<String, dynamic>?)?['canTransfer'] == true,
  );

  final double balance;
  final String currency;
  final String accountNumber;
  final double monthlyCredits;
  final double monthlyDebits;
  final double pendingTopUpBalance;
  final bool canTransfer;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: _asInt(json['id']),
        type: (json['type'] ?? '').toString(),
        amount: _asDouble(json['amount']),
        description: (json['description'] ?? '').toString(),
        createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      );

  final int id;
  final String type;
  final double amount;
  final String description;
  final DateTime createdAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.eventType,
    this.shipmentId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _asInt(json['id']),
        title: (json['title'] ?? 'إشعار').toString(),
        message: (json['message'] ?? json['body'] ?? '').toString(),
        isRead: json['isRead'] == true,
        createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
        eventType: json['eventType']?.toString(),
        shipmentId: _asNullableInt(
          json['shipmentId'] ??
              (json['data'] is Map<String, dynamic>
                  ? (json['data'] as Map<String, dynamic>)['shipmentId']
                  : null),
        ),
      );

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? eventType;
  final int? shipmentId;
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _asNullableInt(Object? value) => value == null ? null : _asInt(value);
double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
double? _asNullableDouble(Object? value) => value == null
    ? null
    : (value is num ? value.toDouble() : double.tryParse('$value'));
DateTime? _asDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
String _enumLabel(Object? value, List<String> labels) {
  if (value is num && value.toInt() >= 0 && value.toInt() < labels.length) {
    return labels[value.toInt()];
  }
  return value?.toString() ?? labels.first;
}

String _oneBasedEnumLabel(Object? value, List<String> labels) {
  if (value is num) {
    final index = value.toInt() - 1;
    if (index >= 0 && index < labels.length) return labels[index];
  }
  return value?.toString() ?? labels.first;
}
