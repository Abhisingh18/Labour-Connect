import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/status_badge.dart';
import '../../shared/models/booking_model.dart';
import '../data/customer_repository.dart';
import 'customer_providers.dart';

class CustomerBookingDetailScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const CustomerBookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<CustomerBookingDetailScreen> createState() => _State();
}

class _State extends ConsumerState<CustomerBookingDetailScreen> {
  late Booking _booking = widget.booking;
  bool _busy = false;

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel booking?', style: AppText.h3),
        content: Text('This will notify the worker. You can\'t undo this.',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(customerRepositoryProvider).cancelBooking(_booking.id);
      ref.invalidate(customerBookingsProvider);
      if (mounted) {
        showSnack(context, 'Booking cancelled');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(bookingId: _booking.id),
    );
    if (result == true) {
      ref.invalidate(customerBookingsProvider);
      if (mounted) {
        showSnack(context, 'Thanks for your review!');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Status', style: AppText.h3),
                const Spacer(),
                StatusBadge.forBooking(b.status),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              child: Row(
                children: [
                  Avatar(
                    name: b.worker?.name ?? 'Worker',
                    imageUrl: b.worker?.profileImage,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.worker?.name ?? 'Worker', style: AppText.h3),
                        const SizedBox(height: 2),
                        Text(b.category?.name ?? 'Service',
                            style: AppText.label.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  if (b.worker?.phone != null)
                    IconButton.filledTonal(
                      onPressed: () =>
                          showSnack(context, 'Call ${b.worker!.phone}'),
                      icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              child: Column(
                children: [
                  _Row(icon: Icons.tag_rounded, label: 'Booking ID', value: '#${b.id}'),
                  _Row(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: Formatters.dateFull(b.bookingDate),
                  ),
                  _Row(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: Formatters.time(b.bookingTime),
                  ),
                  _Row(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: b.address,
                  ),
                  if (b.notes != null && b.notes!.isNotEmpty)
                    _Row(icon: Icons.notes_rounded, label: 'Notes', value: b.notes!),
                  if (b.amount > 0)
                    _Row(
                      icon: Icons.payments_rounded,
                      label: 'Amount',
                      value: Formatters.money(b.amount),
                      valueColor: AppColors.success,
                      last: true,
                    ),
                ],
              ),
            ),
            if (b.review != null) ...[
              const SizedBox(height: 16),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Your review', style: AppText.h3),
                        const Spacer(),
                        RatingStars(
                          rating: b.review!.rating.toDouble(),
                          showCount: false,
                        ),
                      ],
                    ),
                    if (b.review!.comment != null && b.review!.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(b.review!.comment!, style: AppText.body),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (b.isActive)
              PrimaryButton(
                label: 'Cancel booking',
                icon: Icons.close_rounded,
                loading: _busy,
                onPressed: _cancel,
              ).withDangerStyle(),
            if (b.canReview)
              PrimaryButton(
                label: 'Rate & review',
                icon: Icons.star_rounded,
                onPressed: _review,
              ),
          ],
        ),
      ),
    );
  }
}

extension on PrimaryButton {
  Widget withDangerStyle() => Theme(
        data: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        child: this,
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppText.label),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.bodyStrong.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final int bookingId;
  const _ReviewSheet({required this.bookingId});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(customerRepositoryProvider).addReview(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _comment.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString(), error: true);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How was the service?', style: AppText.h2),
          const SizedBox(height: 4),
          Text('Your feedback helps others choose', style: AppText.body),
          const SizedBox(height: 12),
          RatingPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share a few words (optional)',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Submit review',
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
