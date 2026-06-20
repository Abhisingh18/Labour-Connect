import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../data/customer_repository.dart';
import 'customer_providers.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  final int? initialCategoryId;
  const PostJobScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _address = TextEditingController();
  final _notes = TextEditingController();
  int? _categoryId;
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

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
    if (_categoryId == null) {
      showSnack(context, 'Kaunsi service chahiye, choose karo', error: true);
      return;
    }
    if (_date == null) {
      showSnack(context, 'Date select karo', error: true);
      return;
    }
    if (_address.text.trim().isEmpty) {
      showSnack(context, 'Address daalo', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final time = _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00';
      await ref.read(customerRepositoryProvider).postJob(
            categoryId: _categoryId!,
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
              child: const Icon(Icons.send_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Kaam post ho gaya!', style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Hamari team aapko call karke price confirm karegi, fir aapka kaam workers ko dikhne lagega.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'My bookings dekho',
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
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Post your job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Worker chunne ki zarurat nahi. Kaam batao — hum call karke price tay karenge, fir workers accept karenge.',
                      style: AppText.caption.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Kaunsi service?', style: AppText.h3),
            const SizedBox(height: 12),
            categories.when(
              loading: () => const ShimmerBox(height: 48, radius: 16),
              error: (e, _) => Text(e.toString(), style: AppText.body),
              data: (cats) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cats.map((c) {
                  final selected = c.id == _categoryId;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: AppText.label.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Kab chahiye?', style: AppText.h3),
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
              label: 'Address',
              hint: 'Ghar/flat, street, area, landmark',
              prefixIcon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notes,
              label: 'Kaam ka detail (optional)',
              hint: 'e.g. 2 BHK deep cleaning, 3 ghante ka kaam',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Post job',
              icon: Icons.send_rounded,
              loading: _loading,
              onPressed: _submit,
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
