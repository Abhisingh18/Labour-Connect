import 'category_model.dart';

/// Public-facing worker card (customer listings & detail).
class Worker {
  final int userId;
  final String name;
  final String? profileImage;
  final Category? category;
  final int experience;
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final String? serviceArea;
  final double? distanceKm;
  final String? bio;
  final String? phone;

  const Worker({
    required this.userId,
    required this.name,
    this.profileImage,
    this.category,
    required this.experience,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    this.serviceArea,
    this.distanceKm,
    this.bio,
    this.phone,
  });

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        userId: json['user_id'] as int,
        name: json['name'] as String? ?? 'Worker',
        profileImage: json['profile_image'] as String?,
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category'] as Map<String, dynamic>),
        experience: json['experience'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: json['rating_count'] as int? ?? 0,
        isAvailable: json['is_available'] as bool? ?? false,
        serviceArea: json['service_area'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        bio: json['bio'] as String?,
        phone: json['phone'] as String?,
      );
}

/// The signed-in worker's own profile (with KYC + verification fields).
class WorkerProfile {
  final int id;
  final int userId;
  final int? categoryId;
  final int experience;
  final String? bio;
  final String? serviceArea;
  final String kycStatus;
  final bool isVerified;
  final bool isAvailable;
  final bool isSuspended;
  final double rating;
  final int ratingCount;
  final Category? category;

  const WorkerProfile({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.experience,
    this.bio,
    this.serviceArea,
    required this.kycStatus,
    required this.isVerified,
    required this.isAvailable,
    required this.isSuspended,
    required this.rating,
    required this.ratingCount,
    this.category,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) => WorkerProfile(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        categoryId: json['category_id'] as int?,
        experience: json['experience'] as int? ?? 0,
        bio: json['bio'] as String?,
        serviceArea: json['service_area'] as String?,
        kycStatus: json['kyc_status'] as String? ?? 'not_submitted',
        isVerified: json['is_verified'] as bool? ?? false,
        isAvailable: json['is_available'] as bool? ?? false,
        isSuspended: json['is_suspended'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: json['rating_count'] as int? ?? 0,
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category'] as Map<String, dynamic>),
      );
}

class Earnings {
  final double totalEarnings;
  final int completedJobs;
  final List<MonthlyEarning> monthly;

  const Earnings({
    required this.totalEarnings,
    required this.completedJobs,
    required this.monthly,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) => Earnings(
        totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
        completedJobs: json['completed_jobs'] as int? ?? 0,
        monthly: (json['monthly'] as List<dynamic>? ?? [])
            .map((e) => MonthlyEarning.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MonthlyEarning {
  final String month; // YYYY-MM
  final double amount;

  const MonthlyEarning({required this.month, required this.amount});

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) => MonthlyEarning(
        month: json['month'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}
