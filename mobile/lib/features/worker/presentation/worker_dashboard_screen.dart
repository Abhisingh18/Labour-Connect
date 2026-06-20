import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/worker_model.dart';
import '../data/worker_repository.dart';
import 'worker_providers.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = ref.watch(workerProfileProvider);
    final earnings = ref.watch(workerEarningsProvider);
    final pending = ref.watch(workerBookingsProvider('pending'));
    final openJobs = ref.watch(openJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name ?? 'Worker'}'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(workerProfileProvider);
          ref.invalidate(workerEarningsProvider);
          ref.invalidate(workerBookingsProvider);
          ref.invalidate(openJobsProvider);
        },
        child: profile.when(
          loading: () => const ListSkeleton(itemHeight: 120),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(workerProfileProvider),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _AvailabilityCard(profile: p),
              const SizedBox(height: 16),
              if (!p.isVerified) _KycPrompt(profile: p),
              if (!p.isVerified) const SizedBox(height: 16),
              if (p.isVerified) ...[
                _AvailableJobsCard(
                  count: openJobs.maybeWhen(data: (l) => l.length, orElse: () => 0),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Total earnings',
                      value: earnings.maybeWhen(
                        data: (e) => '₹${e.totalEarnings.toStringAsFixed(0)}',
                        orElse: () => '—',
                      ),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.task_alt_rounded,
                      label: 'Jobs done',
                      value: earnings.maybeWhen(
                        data: (e) => '${e.completedJobs}',
                        orElse: () => '—',
                      ),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_rounded,
                      label: 'Rating',
                      value: p.rating > 0 ? p.rating.toStringAsFixed(1) : 'New',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.notifications_active_rounded,
                      label: 'New requests',
                      value: pending.maybeWhen(
                        data: (list) => '${list.length}',
                        orElse: () => '—',
                      ),
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('New requests', style: AppText.h2),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(Routes.workerRequests),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              pending.when(
                loading: () => const ShimmerBox(height: 90, radius: 20),
                error: (e, _) => Text(e.toString(), style: AppText.body),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No new requests',
                      message: 'Stay online to receive booking requests.',
                    );
                  }
                  return Column(
                    children: list
                        .take(3)
                        .map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RequestPreview(
                                customerName: b.customer?.name ?? 'Customer',
                                service: b.category?.name ?? 'Service',
                                onTap: () => context.go(Routes.workerRequests),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends ConsumerStatefulWidget {
  final WorkerProfile profile;
  const _AvailabilityCard({required this.profile});

  @override
  ConsumerState<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends ConsumerState<_AvailabilityCard> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (!widget.profile.isVerified) {
      showSnack(context, 'Complete KYC verification to go online', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(workerRepositoryProvider).setAvailability(value);
      ref.invalidate(workerProfileProvider);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.profile.isAvailable;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: online
            ? const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online ? 'You\'re online' : 'You\'re offline',
                  style: AppText.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  online
                      ? 'Receiving booking requests'
                      : 'Go online to get new jobs',
                  style: AppText.label.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Switch(
                  value: online,
                  onChanged: _toggle,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                ),
        ],
      ),
    );
  }
}

class _KycPrompt extends StatelessWidget {
  final WorkerProfile profile;
  const _KycPrompt({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.warning, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Verification', style: AppText.h3),
                    const SizedBox(width: 8),
                    StatusBadge.forKyc(profile.kycStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.kycStatus == 'pending'
                      ? 'Your documents are under review.'
                      : 'Upload your documents to start getting jobs.',
                  style: AppText.label,
                ),
              ],
            ),
          ),
          if (profile.kycStatus != 'pending')
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => context.push(Routes.workerKyc),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _AvailableJobsCard extends StatelessWidget {
  final int count;
  const _AvailableJobsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(Routes.workerAvailableJobs),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available jobs',
                        style: AppText.h3.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      count > 0 ? '$count naye kaam aapke liye' : 'Naye kaam yahan dikhenge',
                      style: AppText.label.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text('$count',
                      style: AppText.bodyStrong.copyWith(color: AppColors.info)),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppText.h1.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _RequestPreview extends StatelessWidget {
  final String customerName;
  final String service;
  final VoidCallback onTap;

  const _RequestPreview({
    required this.customerName,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: AppText.bodyStrong),
                    Text(service, style: AppText.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
