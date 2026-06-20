import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../shared/models/worker_model.dart';
import '../data/customer_repository.dart';
import 'customer_providers.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final Worker worker;
  const CreateBookingScreen({super.key, required this.worker});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null) {
      showSnack(context, 'Please pick a date', error: true);
      return;
    }
    if (_address.text.trim().isEmpty) {
      showSnack(context, 'Please enter the service address', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final time = _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00';
      await ref.read(customerRepositoryProvider).createBooking(
            workerId: widget.worker.userId,
            categoryId: widget.worker.category?.id,
            date: _date!,
            time: time,
            address: _address.text.trim(),
            notes: _notes.text.trim(),
          );
      ref.invalidate(customerBookingsProvider);
      if (!mounted) return;
      await _showSuccess();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSuccess() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Booking requested!', style: AppText.h2),
            const SizedBox(height: 8),
            Text(
              '${widget.worker.name} will be notified and can accept your request shortly.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View my bookings',
              onPressed: () {
                Navigator.pop(context);
                context.go(Routes.customerBookings);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    return Scaffold(
      appBar: AppBar(title: const Text('Book service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Avatar(name: w.name, imageUrl: w.profileImage, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: AppText.h3),
                        const SizedBox(height: 2),
                        Text(w.category?.name ?? 'Service worker',
                            style: AppText.label.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('When do you need it?', style: AppText.h3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _date == null ? 'Select' : Formatters.date(_date!),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _time == null ? 'Any time' : _time!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _address,
              label: 'Service address',
              hint: 'House / flat, street, area, landmark',
              prefixIcon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notes,
              label: 'Notes (optional)',
              hint: 'Describe the work, e.g. "Leaking kitchen tap"',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Confirm booking',
              icon: Icons.check_circle_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('No payment now — pay after the job is done',
                  style: AppText.caption),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption),
                const SizedBox(height: 2),
                Text(value, style: AppText.bodyStrong),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
