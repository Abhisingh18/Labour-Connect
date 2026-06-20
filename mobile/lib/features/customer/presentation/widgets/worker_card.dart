import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../shared/models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;

  const WorkerCard({super.key, required this.worker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Avatar(name: worker.name, imageUrl: worker.profileImage, size: 60),
                  if (worker.isAvailable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: AppText.h3, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      worker.category?.name ?? 'Service worker',
                      style: AppText.label.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingStars(rating: worker.rating, count: worker.ratingCount, size: 14),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 12, color: AppColors.border),
                        const SizedBox(width: 10),
                        const Icon(Icons.work_history_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${worker.experience}y', style: AppText.caption),
                        if (worker.distanceKm != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text('${worker.distanceKm} km', style: AppText.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
