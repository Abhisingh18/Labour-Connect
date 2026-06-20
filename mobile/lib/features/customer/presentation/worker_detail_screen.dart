import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/states.dart';
import '../../shared/models/worker_model.dart';
import 'customer_providers.dart';

class WorkerDetailScreen extends ConsumerWidget {
  final int workerId;
  const WorkerDetailScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(workerDetailProvider(workerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Worker profile')),
      body: worker.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
        ),
        data: (w) => _Content(worker: w),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Worker worker;
  const _Content({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _HeaderCard(worker: worker),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.star_rounded,
                        value: worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'New',
                        label: '${worker.ratingCount} reviews',
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.work_history_rounded,
                        value: '${worker.experience}y',
                        label: 'Experience',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: worker.isAvailable
                            ? Icons.bolt_rounded
                            : Icons.do_not_disturb_on_rounded,
                        value: worker.isAvailable ? 'Online' : 'Offline',
                        label: 'Status',
                        color: worker.isAvailable ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (worker.bio != null && worker.bio!.isNotEmpty) ...[
                  _Section(
                    title: 'About',
                    child: Text(worker.bio!, style: AppText.body),
                  ),
                  const SizedBox(height: 16),
                ],
                _Section(
                  title: 'Service details',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.home_repair_service_rounded,
                        label: 'Service',
                        value: worker.category?.name ?? '—',
                      ),
                      if (worker.serviceArea != null && worker.serviceArea!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.map_rounded,
                          label: 'Service area',
                          value: worker.serviceArea!,
                        ),
                      _InfoRow(
                        icon: Icons.verified_user_rounded,
                        label: 'Verification',
                        value: 'KYC verified',
                        valueColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(worker: worker),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Worker worker;
  const _HeaderCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Avatar(name: worker.name, imageUrl: worker.profileImage, size: 84),
          const SizedBox(height: 14),
          Text(worker.name,
              style: AppText.h1.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            worker.category?.name ?? 'Service worker',
            style: AppText.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: RatingStars(
              rating: worker.rating,
              count: worker.ratingCount,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppText.h3),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppText.label),
          const Spacer(),
          Text(value,
              style: AppText.bodyStrong.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Worker worker;
  const _BottomBar({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: PrimaryButton(
        label: worker.isAvailable ? 'Book this worker' : 'Currently unavailable',
        icon: Icons.calendar_month_rounded,
        onPressed: worker.isAvailable
            ? () => context.push('${Routes.createBooking}/${worker.userId}', extra: worker)
            : () => showSnack(context, 'This worker is offline right now', error: true),
      ),
    );
  }
}
