class AvailabilitySlot {
  final String dayOfWeek;
  final List<String> slots;

  AvailabilitySlot({required this.dayOfWeek, required this.slots});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      dayOfWeek: json['dayOfWeek'] ?? '',
      slots: List<String>.from(json['slots'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'slots': slots};
}

/// Represents the KYC verification state for a provider.
class KycInfo {
  final String? documentType;
  final String? documentUrl;
  final String status; // not_submitted | pending | approved | rejected
  final String? rejectionReason;
  final String? submittedAt;
  final String? reviewedAt;

  KycInfo({
    this.documentType,
    this.documentUrl,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  factory KycInfo.fromJson(Map<String, dynamic> json) {
    return KycInfo(
      documentType: json['documentType'],
      documentUrl: json['documentUrl'],
      status: json['status'] ?? 'not_submitted',
      rejectionReason: json['rejectionReason'],
      submittedAt: json['submittedAt'],
      reviewedAt: json['reviewedAt'],
    );
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isNotSubmitted => status == 'not_submitted';
}

class ProviderProfile {
  final String id;
  final String userId;
  final List<String> skills;
  final String? address;
  final List<AvailabilitySlot> availability;
  final double rating;
  final int totalReviews;
  final int totalJobs;
  final bool isVerified;
  final bool isAvailable;
  final KycInfo kyc;

  ProviderProfile({
    required this.id,
    required this.userId,
    required this.skills,
    this.address,
    required this.availability,
    required this.rating,
    required this.totalReviews,
    required this.totalJobs,
    required this.isVerified,
    required this.isAvailable,
    required this.kyc,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      address: json['location']?['address'],
      availability: (json['availability'] as List?)
              ?.map((a) => AvailabilitySlot.fromJson(a))
              .toList() ??
          [],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalJobs: json['totalJobs'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
      kyc: json['kyc'] != null
          ? KycInfo.fromJson(json['kyc'])
          : KycInfo(status: 'not_submitted'),
    );
  }
}
