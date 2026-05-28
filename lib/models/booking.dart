class Booking {
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String date;
  final String slot;
  final String status;
  final double price;
  final String? acceptedAt;
  final String? completedAt;
  final String? rejectedAt;
  final String createdAt;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paidAt;
  final Map<String, dynamic>? serviceDetails;
  final Map<String, dynamic>? userDetails;
  /// [longitude, latitude] — GeoJSON order from backend
  final List<double>? customerCoordinates;
  final String? customerAddress;

  Booking({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    required this.date,
    required this.slot,
    required this.status,
    required this.price,
    this.acceptedAt,
    this.completedAt,
    this.rejectedAt,
    required this.createdAt,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paidAt,
    this.serviceDetails,
    this.userDetails,
    this.customerCoordinates,
    this.customerAddress,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse customerLocation: { coordinates: [lng, lat], address: "..." }
    List<double>? coords;
    String? address;
    final loc = json['customerLocation'];
    if (loc is Map) {
      final rawCoords = loc['coordinates'];
      if (rawCoords is List && rawCoords.length >= 2) {
        coords = [
          (rawCoords[0] as num).toDouble(),
          (rawCoords[1] as num).toDouble(),
        ];
      }
      address = loc['address']?.toString();
    }

    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      providerId: json['providerId'] is Map ? json['providerId']['_id'] ?? '' : json['providerId'] ?? '',
      serviceId: json['serviceId'] is Map ? json['serviceId']['_id'] ?? '' : json['serviceId'] ?? '',
      date: json['date'] ?? '',
      slot: json['slot'] ?? '',
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      acceptedAt: json['acceptedAt'],
      completedAt: json['completedAt'],
      rejectedAt: json['rejectedAt'],
      createdAt: json['createdAt'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentMethod: json['paymentMethod'],
      paidAt: json['paidAt'],
      serviceDetails: json['serviceId'] is Map ? json['serviceId'] : null,
      userDetails: json['userId'] is Map ? json['userId'] : null,
      customerCoordinates: coords,
      customerAddress: address,
    );
  }

  String get serviceName => serviceDetails?['name'] ?? 'Service';
  String get customerName => userDetails?['name'] ?? 'Customer';
  String get customerEmail => userDetails?['email'] ?? '';

  /// Returns customer latitude (GeoJSON stores [lng, lat])
  double? get customerLatitude => customerCoordinates?[1];
  /// Returns customer longitude
  double? get customerLongitude => customerCoordinates?[0];
}
