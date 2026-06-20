import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small pill used for booking / KYC statuses.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  factory StatusBadge.forBooking(String status) {
    switch (status) {
      case 'pending_approval':
        return const StatusBadge(
          label: 'Awaiting admin',
          color: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.hourglass_top_rounded,
        );
      case 'open':
        return const StatusBadge(
          label: 'Finding worker',
          color: AppColors.info,
          background: AppColors.infoLight,
          icon: Icons.travel_explore_rounded,
        );
      case 'pending':
        return const StatusBadge(
          label: 'Pending',
          color: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.schedule_rounded,
        );
      case 'accepted':
        return const StatusBadge(
          label: 'Accepted',
          color: AppColors.info,
          background: AppColors.infoLight,
          icon: Icons.handshake_rounded,
        );
      case 'completed':
        return const StatusBadge(
          label: 'Completed',
          color: AppColors.success,
          background: AppColors.successLight,
          icon: Icons.check_circle_rounded,
        );
      case 'rejected':
        return const StatusBadge(
          label: 'Rejected',
          color: AppColors.danger,
          background: AppColors.dangerLight,
          icon: Icons.cancel_rounded,
        );
      case 'cancelled':
        return const StatusBadge(
          label: 'Cancelled',
          color: AppColors.textSecondary,
          background: AppColors.divider,
          icon: Icons.block_rounded,
        );
      default:
        return StatusBadge(
          label: status,
          color: AppColors.textSecondary,
          background: AppColors.divider,
        );
    }
  }

  factory StatusBadge.forKyc(String status) {
    switch (status) {
      case 'verified':
        return const StatusBadge(
          label: 'Verified',
          color: AppColors.success,
          background: AppColors.successLight,
          icon: Icons.verified_rounded,
        );
      case 'pending':
        return const StatusBadge(
          label: 'Under review',
          color: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.hourglass_top_rounded,
        );
      case 'rejected':
        return const StatusBadge(
          label: 'Rejected',
          color: AppColors.danger,
          background: AppColors.dangerLight,
          icon: Icons.error_rounded,
        );
      default:
        return const StatusBadge(
          label: 'Not submitted',
          color: AppColors.textSecondary,
          background: AppColors.divider,
          icon: Icons.upload_file_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
