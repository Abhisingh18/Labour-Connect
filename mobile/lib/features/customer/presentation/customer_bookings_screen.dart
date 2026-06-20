import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/widgets/booking_card.dart';
import 'customer_providers.dart';

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends ConsumerState<CustomerBookingsScreen>
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
        title: const Text('My bookings'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _BookingsTab(group: 'active'),
          _BookingsTab(group: 'completed'),
          _BookingsTab(group: 'cancelled'),
        ],
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  final String group;
  const _BookingsTab({required this.group});

  bool _matches(Booking b) {
    switch (group) {
      case 'active':
        return b.status == 'pending' || b.status == 'accepted';
      case 'completed':
        return b.status == 'completed';
      case 'cancelled':
        return b.status == 'cancelled' || b.status == 'rejected';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(customerBookingsProvider(null));

    return bookings.when(
      loading: () => const ListSkeleton(itemHeight: 120),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(customerBookingsProvider(null)),
      ),
      data: (all) {
        final list = all.where(_matches).toList();
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.event_note_rounded,
            title: 'Nothing here yet',
            message: group == 'active'
                ? 'Your upcoming bookings will appear here.'
                : 'No $group bookings.',
            actionLabel: group == 'active' ? 'Find a worker' : null,
            onAction: group == 'active'
                ? () => context.go(Routes.customerHome)
                : null,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(customerBookingsProvider(null)),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => BookingCard(
              booking: list[i],
              counterpartyName: list[i].worker?.name ?? 'Worker',
              onTap: () => context.push('${Routes.bookingDetail}/${list[i].id}', extra: list[i]),
            ),
          ),
        );
      },
    );
  }
}
