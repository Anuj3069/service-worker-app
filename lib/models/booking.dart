class Booking {
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String date;
  final String slot;
  final String status;
  final double price;
  final double payout;
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
  final String bookingType; // BOOK_LATER, BOOK_INSTANT, BOOK_FOR_MONTH
  final String? durationType; // HALF_DAY or FULL_DAY
  final int? durationHours; // 9 or 16
  final String? parentBookingId;
  final int? bookingSequence;
  final Map<String, dynamic>? monthContract; // startDate, endDate, totalDays, dailyPrice
  final String? expiresAt;

  Booking({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    required this.date,
    required this.slot,
    required this.status,
    required this.price,
    required this.payout,
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
    this.bookingType = 'BOOK_LATER',
    this.durationType,
    this.durationHours,
    this.parentBookingId,
    this.bookingSequence,
    this.monthContract,
    this.expiresAt,
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
      payout: (json['payout'] ?? (json['price'] ?? 0) * 0.9).toDouble(),
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
      bookingType: json['bookingType'] ?? 'BOOK_LATER',
      durationType: json['durationType'],
      durationHours: json['durationHours'] != null ? (json['durationHours'] as num).toInt() : null,
      parentBookingId: json['parentBookingId'] is Map
          ? json['parentBookingId']['_id']
          : json['parentBookingId'],
      bookingSequence: json['bookingSequence'] != null ? (json['bookingSequence'] as num).toInt() : null,
      monthContract: json['monthContract'] is Map ? Map<String, dynamic>.from(json['monthContract']) : null,
      expiresAt: json['expiresAt']?.toString(),
    );
  }

  bool get isMonthBooking => bookingType == 'BOOK_FOR_MONTH';
  bool get isMonthMaster => isMonthBooking && parentBookingId == null;

  /// Whether the worker can start "En Route" tracking for this booking yet.
  bool get canGoEnRoute {
    if (date.isEmpty) return true;
    try {
      final bookingDate = DateTime.parse(date);
      if (bookingType == 'BOOK_FOR_MONTH') {
        final dayStart = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
        return !DateTime.now().isBefore(dayStart);
      }
      if (bookingType == 'BOOK_LATER') {
        return !DateTime.now().isBefore(bookingDate.subtract(const Duration(hours: 1)));
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  String get serviceName => serviceDetails?['name'] ?? 'Service';
  String get customerName => userDetails?['name'] ?? 'Customer';
  String get customerEmail => userDetails?['email'] ?? '';

  /// Returns customer latitude (GeoJSON stores [lng, lat])
  double? get customerLatitude => customerCoordinates?[1];
  /// Returns customer longitude
  double? get customerLongitude => customerCoordinates?[0];
}
