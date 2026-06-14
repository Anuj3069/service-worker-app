/// Snapshot of bank details at the time of settlement request.
class BankSnapshot {
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? upiId;

  BankSnapshot({
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.upiId,
  });

  factory BankSnapshot.fromJson(Map<String, dynamic> json) {
    return BankSnapshot(
      accountHolderName: json['accountHolderName'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
      bankName: json['bankName'],
      upiId: json['upiId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        'upiId': upiId,
      };

  /// Returns a masked version of the account number for display (e.g. ****9012)
  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4) return accountNumber ?? '';
    return '****${accountNumber!.substring(accountNumber!.length - 4)}';
  }
}

/// A booking included in a settlement batch.
class SettlementBooking {
  final String id;
  final double price;
  final double payout;
  final String status;
  final String paymentStatus;
  final String? completedAt;

  SettlementBooking({
    required this.id,
    required this.price,
    required this.payout,
    required this.status,
    required this.paymentStatus,
    this.completedAt,
  });

  factory SettlementBooking.fromJson(Map<String, dynamic> json) {
    return SettlementBooking(
      id: json['_id'] ?? json['id'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      payout: (json['payout'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      completedAt: json['completedAt'],
    );
  }
}

/// A settlement/payout request record.
class Settlement {
  final String id;
  final String providerId;
  final List<dynamic> bookingIds; // Can be strings or SettlementBooking objects
  final double totalAmount;
  final String status; // pending | processing | settled | rejected
  final BankSnapshot? bankSnapshot;
  final String? adminNote;
  final String? requestedAt;
  final String? settledAt;
  final String? createdAt;

  Settlement({
    required this.id,
    required this.providerId,
    required this.bookingIds,
    required this.totalAmount,
    required this.status,
    this.bankSnapshot,
    this.adminNote,
    this.requestedAt,
    this.settledAt,
    this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    // Parse bookingIds — can be list of strings or list of populated objects
    final rawBookings = json['bookingIds'] as List? ?? [];
    final parsedBookings = rawBookings.map((b) {
      if (b is Map<String, dynamic>) {
        return SettlementBooking.fromJson(b);
      }
      return b.toString(); // plain ObjectId string
    }).toList();

    return Settlement(
      id: json['_id'] ?? json['id'] ?? '',
      providerId: json['providerId'] is Map
          ? json['providerId']['_id'] ?? ''
          : json['providerId'] ?? '',
      bookingIds: parsedBookings,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      bankSnapshot: json['bankSnapshot'] != null
          ? BankSnapshot.fromJson(json['bankSnapshot'])
          : null,
      adminNote: json['adminNote'],
      requestedAt: json['requestedAt'],
      settledAt: json['settledAt'],
      createdAt: json['createdAt'],
    );
  }

  int get bookingCount => bookingIds.length;

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isSettled => status == 'settled';
  bool get isRejected => status == 'rejected';
  bool get isTerminal => isSettled || isRejected;
}
