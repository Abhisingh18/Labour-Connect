import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../../shared/models/booking_model.dart';
import '../data/worker_repository.dart';
import 'worker_providers.dart';

class AvailableJobsScreen extends ConsumerWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(openJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Available jobs')),
      body: jobs.when(
        loading: () => const ListSkeleton(itemHeight: 150),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(openJobsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'Abhi koi job nahi',
              message:
                  'Aapki category ke admin-approved jobs yahan dikhenge. Thodi der baad check karo.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(openJobsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _JobCard(job: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends ConsumerStatefulWidget {
  final Booking job;
  const _JobCard({required this.job});

  @override
  ConsumerState<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<_JobCard> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      await ref.read(workerRepositoryProvider).claimJob(widget.job.id);
      ref.invalidate(openJobsProvider);
      ref.invalidate(workerBookingsProvider);
      if (mounted) {
        showSnack(context, 'Job mil gaya! "Bookings" mein dekho.');
      }
    } catch (e) {
      ref.invalidate(openJobsProvider); // someone may have taken it
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                child: Icon(categoryIcon(j.category?.icon ?? j.category?.name),
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(j.category?.name ?? 'Service', style: AppText.h3.copyWith(fontSize: 16)),
              ),
              if (j.amount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(Formatters.money(j.amount),
                      style: AppText.bodyStrong.copyWith(color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _line(Icons.calendar_today_rounded, Formatters.dateFull(j.bookingDate)),
          _line(Icons.access_time_rounded, Formatters.time(j.bookingTime)),
          _line(Icons.location_on_rounded, j.address),
          if (j.notes != null && j.notes!.isNotEmpty) _line(Icons.notes_rounded, j.notes!),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Accept this job',
            icon: Icons.check_circle_rounded,
            loading: _busy,
            onPressed: _claim,
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppText.label)),
          ],
        ),
      );
}
