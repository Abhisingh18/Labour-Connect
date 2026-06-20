import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../shared/models/booking_model.dart';
import '../data/worker_repository.dart';
import 'worker_providers.dart';

class WorkerRequestsScreen extends ConsumerStatefulWidget {
  const WorkerRequestsScreen({super.key});

  @override
  ConsumerState<WorkerRequestsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RequestsTab(group: 'new'),
          _RequestsTab(group: 'active'),
          _RequestsTab(group: 'history'),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final String group;
  const _RequestsTab({required this.group});

  bool _matches(Booking b) {
    switch (group) {
      case 'new':
        return b.status == 'pending';
      case 'active':
        return b.status == 'accepted';
      case 'history':
        return b.status == 'completed' ||
            b.status == 'rejected' ||
            b.status == 'cancelled';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(workerBookingsProvider(null));

    return bookings.when(
      loading: () => const ListSkeleton(itemHeight: 150),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(workerBookingsProvider(null)),
      ),
      data: (all) {
        final list = all.where(_matches).toList();
        if (list.isEmpty) {
          return EmptyState(
            icon: group == 'new' ? Icons.inbox_rounded : Icons.history_rounded,
            title: group == 'new' ? 'No new requests' : 'Nothing here',
            message: group == 'new'
                ? 'New booking requests will show up here.'
                : 'No $group bookings yet.',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(workerBookingsProvider(null)),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _RequestCard(booking: list[i]),
          ),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final Booking booking;
  const _RequestCard({required this.booking});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(workerBookingsProvider);
      ref.invalidate(workerEarningsProvider);
      if (mounted) showSnack(context, done);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mark as completed', style: AppText.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the amount you charged for this job.', style: AppText.body),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text.trim()) ?? 0),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await _run(
      () => ref.read(workerRepositoryProvider).complete(widget.booking.id, amount),
      'Job completed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
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
              Avatar(
                name: b.customer?.name ?? 'Customer',
                imageUrl: b.customer?.profileImage,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.customer?.name ?? 'Customer', style: AppText.h3.copyWith(fontSize: 15)),
                    Text(b.category?.name ?? 'Service',
                        style: AppText.label.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              StatusBadge.forBooking(b.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoLine(icon: Icons.calendar_today_rounded, text: Formatters.dateFull(b.bookingDate)),
          _InfoLine(icon: Icons.access_time_rounded, text: Formatters.time(b.bookingTime)),
          _InfoLine(icon: Icons.location_on_rounded, text: b.address),
          if (b.notes != null && b.notes!.isNotEmpty)
            _InfoLine(icon: Icons.notes_rounded, text: b.notes!),
          if (b.amount > 0)
            _InfoLine(
              icon: Icons.payments_rounded,
              text: Formatters.money(b.amount),
              color: AppColors.success,
            ),
          if (b.status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Reject',
                    color: AppColors.danger,
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => ref.read(workerRepositoryProvider).reject(b.id),
                            'Request rejected'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    loading: _busy,
                    onPressed: () => _run(
                        () => ref.read(workerRepositoryProvider).accept(b.id),
                        'Request accepted'),
                  ),
                ),
              ],
            ),
          ],
          if (b.status == 'accepted') ...[
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Mark as completed',
              icon: Icons.check_circle_rounded,
              loading: _busy,
              onPressed: _complete,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoLine({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.label.copyWith(
                color: color ?? AppColors.textSecondary,
                fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
