import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/booking_model.dart';

/// Booking summary card used in both customer & worker lists.
/// [counterpartyName] is the other party (worker for a customer, vice versa).
class BookingCard extends StatelessWidget {
  final Booking booking;
  final String counterpartyName;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.counterpartyName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon(booking.category?.icon ?? booking.category?.name),
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.category?.name ?? 'Service',
                          style: AppText.h3.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(counterpartyName, style: AppText.label),
                      ],
                    ),
                  ),
                  StatusBadge.forBooking(booking.status),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(Formatters.date(booking.bookingDate), style: AppText.caption),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(Formatters.time(booking.bookingTime), style: AppText.caption),
                  const Spacer(),
                  if (booking.amount > 0)
                    Text(
                      Formatters.money(booking.amount),
                      style: AppText.bodyStrong.copyWith(color: AppColors.success),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
