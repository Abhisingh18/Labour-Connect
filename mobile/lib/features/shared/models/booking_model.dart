import 'category_model.dart';

class BookingParty {
  final int id;
  final String name;
  final String? phone;
  final String? profileImage;

  const BookingParty({
    required this.id,
    required this.name,
    this.phone,
    this.profileImage,
  });

  factory BookingParty.fromJson(Map<String, dynamic> json) => BookingParty(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        profileImage: json['profile_image'] as String?,
      );
}

class Review {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Booking {
  final int id;
  final int customerId;
  final int? workerId;
  final String status; // pending|accepted|rejected|completed|cancelled
  final DateTime bookingDate;
  final String? bookingTime;
  final String address;
  final String? notes;
  final double amount;
  final bool isOpenRequest;
  final DateTime createdAt;
  final BookingParty? customer;
  final BookingParty? worker;
  final Category? category;
  final Review? review;

  const Booking({
    required this.id,
    required this.customerId,
    this.workerId,
    required this.status,
    required this.bookingDate,
    this.bookingTime,
    required this.address,
    this.notes,
    required this.amount,
    this.isOpenRequest = false,
    required this.createdAt,
    this.customer,
    this.worker,
    this.category,
    this.review,
  });

  bool get isActive =>
      status == 'pending' || status == 'accepted' || status == 'pending_approval' || status == 'open';
  bool get canReview => status == 'completed' && review == null;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        customerId: json['customer_id'] as int,
        workerId: json['worker_id'] as int?,
        status: json['status'] as String,
        bookingDate: DateTime.parse(json['booking_date'] as String),
        bookingTime: json['booking_time'] as String?,
        address: json['address'] as String? ?? '',
        notes: json['notes'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        isOpenRequest: json['is_open_request'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        customer: json['customer'] == null
            ? null
            : BookingParty.fromJson(json['customer'] as Map<String, dynamic>),
        worker: json['worker'] == null
            ? null
            : BookingParty.fromJson(json['worker'] as Map<String, dynamic>),
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category'] as Map<String, dynamic>),
        review: json['review'] == null
            ? null
            : Review.fromJson(json['review'] as Map<String, dynamic>),
      );
}
